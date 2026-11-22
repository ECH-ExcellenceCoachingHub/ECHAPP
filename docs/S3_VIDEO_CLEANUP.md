# S3 Video Cleanup System

A separate, independent tool for reclaiming S3 storage from videos that are no
longer referenced by any lesson (e.g. after a lesson/section/course is deleted, or
after a video is replaced). It exists because **course/lesson/section deletion does
not clean up S3** — see "Why this exists" below — and because these videos are
expensive to re-shoot/re-upload, every step here is deliberately conservative and
reversible until the very last one.

## Why this exists

Deleting a `Lesson`, `Section`, or `Course` only removes MongoDB documents:

- `Lesson` delete ([lesson.controller.js](backend/src/controllers/lesson.controller.js)) removes the lesson record only.
- `Section` delete cascades to `Lesson.deleteMany(...)` ([section.controller.js](backend/src/controllers/section.controller.js)), but that's a raw Mongo delete — no S3 calls happen for those lessons' videos.
- `Course` delete ([course.controller.js](backend/src/controllers/course.controller.js)) doesn't even cascade to sections/lessons in Mongo, let alone S3.

None of these paths call `s3Service.deleteFile()`. The video stays in the bucket
indefinitely, costing storage forever. Wiring a synchronous S3 delete into each of
those handlers was considered and rejected: it would only catch the direct-delete
case, still miss course deletion (which doesn't touch lessons at all), and would
make an admin's delete-a-lesson click also be the moment an expensive file gets
irreversibly destroyed with no review step. A separate, independent orphan-scan
tool catches every cause (lesson delete, section cascade, course delete, abandoned/
failed uploads, video replacement) in one place, on a schedule the operator
controls, with review built in before anything is removed.

## How it works — three stages, three levels of safety

1. **Scan** (`videos/` in S3 vs. every `Lesson.videoId` in MongoDB) — **read-only**.
   Lists every object under `videos/` in the bucket, lists every `videoId` any
   `Lesson` currently references (normalizing full CloudFront/S3 URLs down to a
   bare key), and reports the difference. Objects newer than `VIDEO_ORPHAN_GRACE_HOURS`
   (default 48h) are never flagged, even if unreferenced — this protects videos
   mid-upload (a presigned client upload lands in S3 before the lesson record is
   saved) from being flagged as orphaned.
2. **Quarantine** — **reversible**. Moves flagged objects from `videos/...` to
   `trash/videos/...` (copy + delete of the original). Nothing is destroyed; the
   object still exists, just out of the way. Capped at 25 videos per run by default
   (`--limit`) so a bug in the scan logic can't quarantine the whole library in one
   command.
3. **Purge** — **irreversible**. Permanently deletes objects that have been sitting
   in `trash/videos/...` for longer than `VIDEO_TRASH_RETENTION_DAYS` (default 30
   days). This is the only step in the whole system that actually destroys data,
   and it's a separate, explicit command from quarantine.

Core logic: [backend/src/services/videoCleanup.service.js](backend/src/services/videoCleanup.service.js)

Nothing here is wired into a cron job or run automatically — unlike the database
backup system, every stage requires a human to run it. That's intentional given the
cost of getting it wrong; once this has been run manually a few times without
surprises, wiring `purgeVideoTrash.js --yes` into a low-frequency Render Cron Job
(e.g. weekly) is a reasonable next step, but isn't set up by default.

## CLI usage

All commands run from `backend/`.

```bash
# 1. Scan (read-only, safe to run any time)
node scripts/findOrphanedVideos.js
node scripts/findOrphanedVideos.js --older-than=72   # override the grace period

# 2. Quarantine (reversible — moves to trash/videos/)
node scripts/quarantineOrphanedVideos.js --dry-run          # preview, changes nothing
node scripts/quarantineOrphanedVideos.js --yes               # quarantine up to 25 (default limit)
node scripts/quarantineOrphanedVideos.js --yes --limit=100   # raise the per-run cap
node scripts/quarantineOrphanedVideos.js --yes --key=videos/some-file-123-abc.mp4  # target one file

# See what's currently quarantined
node scripts/listVideoTrash.js

# Changed your mind about a quarantined file? Undo it before it's purged:
node scripts/restoreVideoFromTrash.js --key=trash/videos/some-file-123-abc.mp4

# 3. Purge (IRREVERSIBLE — only removes items past the retention window)
node scripts/purgeVideoTrash.js --dry-run
node scripts/purgeVideoTrash.js --yes
node scripts/purgeVideoTrash.js --yes --older-than=45   # override retention window
```

Recommended cadence: run the scan periodically, review the report, quarantine what
looks right, let it sit in trash for the retention window in case something needs
restoring, then purge.

## Admin API

Visibility only, matching the same philosophy as the backup system's admin API —
no destructive action is one click away:

- `GET /api/admin/video-cleanup/orphaned` — scan report (admin auth required)
- `GET /api/admin/video-cleanup/trash` — list currently quarantined videos (admin auth required)

There is no HTTP endpoint to quarantine or purge — both stay CLI-only, run by
someone with server access, same reasoning as `restoreBackup.js` in
[DATABASE_BACKUP_SYSTEM.md](DATABASE_BACKUP_SYSTEM.md).

## Configuration

Environment variables (all optional, see [backend/.env](backend/.env)):

| Variable | Default | Purpose |
|---|---|---|
| `VIDEO_ORPHAN_GRACE_HOURS` | `48` | Unreferenced videos newer than this are never flagged as orphaned |
| `VIDEO_TRASH_RETENTION_DAYS` | `30` | Quarantined videos older than this are eligible for permanent purge |

Uses the same `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `AWS_REGION` /
`S3_BUCKET_NAME` variables as the rest of the app — no separate credentials needed.

## Recovery

If a quarantine turns out to be wrong (a video should not have been flagged):

```bash
node scripts/listVideoTrash.js
node scripts/restoreVideoFromTrash.js --key=trash/videos/<file>
```

This restores the S3 object to its original `videos/...` key. It does **not**
recreate a deleted `Lesson` document — if the lesson itself was deleted (not just
orphaned), you'd separately need to restore that from a database backup (see
[DATABASE_BACKUP_SYSTEM.md](DATABASE_BACKUP_SYSTEM.md)) or re-link a new lesson to
the restored video key.

Once a video has been permanently purged, it is gone — there is no recovery path
other than the S3 bucket's own versioning/backup, if enabled.
