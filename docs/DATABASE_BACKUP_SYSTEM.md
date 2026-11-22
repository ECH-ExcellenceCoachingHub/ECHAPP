# Database Backup System

Automated daily backups of the MongoDB database, with local + S3 storage, retention
cleanup, and a CLI restore tool.

## How it works

- **What**: every collection in the database is dumped to a single file, serialized
  with BSON `EJSON` (preserves `ObjectId`, `Date`, etc. exactly), then gzip-compressed.
  No external `mongodump`/`mongorestore` binary is required — the dump is built purely
  with the `mongodb`/`mongoose` driver already used by the app, since the production
  host (Render) isn't guaranteed to have Mongo tools installed.
- **When**: a cron job runs daily at `BACKUP_HOUR` (default `2`, i.e. 2am server time).
  Scheduled with `node-cron` on a fixed cron expression (not `setInterval`), so a
  redeploy/restart never delays or skips a day's backup — same approach used by the
  existing notification scheduler.
- **Where**: written to `backend/backups/` (gitignored) and, if `S3_BUCKET_NAME` is
  configured, also uploaded to `s3://<bucket>/backups/database/`. If the S3 upload
  fails, the local file is kept and the job doesn't fail outright.
- **Retention**: after each run, local and S3 backups older than
  `BACKUP_RETENTION_DAYS` (default `14`) are deleted.
- **Catch-up**: on every boot, `BackupService.ensureRecentBackup()` checks the most
  recent backup and runs one immediately if it's more than 24h old — a safety net for
  hosts where the process isn't guaranteed to be alive at the scheduled hour (see
  "Running on Render" below).

Core logic: [backend/src/services/backup.service.js](backend/src/services/backup.service.js)
Wired into startup: [backend/server.js](backend/server.js) (`BackupService.schedule(...)`, right after the DB connects)

## Running on Render

**The in-process `node-cron` schedule alone is not reliable on Render.** Render web
services (especially free/starter instances) spin down after a period with no HTTP
traffic and only wake back up on the next incoming request. While asleep, the whole
Node process — including any in-process cron timers — simply isn't running, so a
2am tick can be silently missed entirely, not just delayed.

Two layers handle this here:

1. **Primary: a dedicated Render Cron Job** ([render.yaml](render.yaml)). This is
   Render's own mechanism for scheduled background work — Render spins up a fresh
   instance on schedule, runs `node scripts/runBackup.js` to completion, then tears
   it down, completely independent of whether the web service is awake. To enable it:
   - Render dashboard → New → Blueprint → point it at this repo (it only manages the
     `echapp-db-backup` cron job defined in `render.yaml`; your existing web service,
     created outside of a blueprint, is untouched).
   - Fill in the env vars flagged `sync: false` (`MONGODB_URI`, AWS credentials, S3
     bucket/URLs) with the same values as the web service.
   - Adjust `region` and `schedule` in `render.yaml` if needed (default: `0 2 * * *` UTC).
2. **Fallback: the in-process scheduler + catch-up check** (`backend/server.js` /
   `BackupService.schedule()`). Useful if the web service happens to be awake at the
   scheduled hour, and as a safety net via `ensureRecentBackup()` on every boot/wake.
   Running both is harmless — duplicate backups just mean an extra file that retention
   cleanup removes on its own. To avoid the duplicate entirely once the Cron Job is
   confirmed working, set `BACKUP_ENABLED=false` on the web service's env vars.

Also note: **local disk on Render is ephemeral** — anything under `backend/backups/`
is lost on every redeploy/restart (and, for the Cron Job, on every run, since each
invocation gets a fresh throwaway filesystem). This is expected and fine: S3 is the
durable store; local files are scratch space for the current process only. Retention
cleanup and `--latest` restore both check S3 whenever `S3_BUCKET_NAME` is configured.

## Configuration

Environment variables (all optional, see [backend/.env](backend/.env)):

| Variable | Default | Purpose |
|---|---|---|
| `BACKUP_ENABLED` | `true` | Set to `false` to disable the scheduled job entirely |
| `BACKUP_HOUR` | `2` | Hour (0-23, server time) the daily backup runs |
| `BACKUP_RETENTION_DAYS` | `14` | Backups older than this are deleted after each run |
| `BACKUP_DIR` | `backend/backups` | Local directory backups are written to |
| `BACKUP_EXCLUDE_COLLECTIONS` | *(none)* | Comma-separated collection names to skip |

S3 upload reuses the existing `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` /
`AWS_REGION` / `S3_BUCKET_NAME` variables already used for uploads — no separate
credentials needed. If `S3_BUCKET_NAME` isn't set, backups stay local-only.

## Manual backup (CLI)

```bash
cd backend
node scripts/runBackup.js          # backup + upload to S3
node scripts/runBackup.js --no-s3  # local-only backup
```

## Listing backups

```bash
cd backend
node scripts/listBackups.js
```

## Admin API

For visibility/ops from the admin panel (list + trigger only — **restore is not
exposed over HTTP**, see below):

- `GET /api/admin/backups` — list local + S3 backups (admin auth required)
- `POST /api/admin/backups/run` — trigger an on-demand backup (admin auth required)

## Restoring a backup

Restore is **CLI-only**, on purpose: it's a destructive operation (default mode
empties each restored collection before repopulating it), so it shouldn't be a
one-click HTTP endpoint reachable by anyone with an admin session. Run it directly
on the server/host with access to `MONGODB_URI`.

```bash
cd backend

# 1. Always rehearse first — this only prints what would happen, writes nothing:
node scripts/restoreBackup.js --latest --dry-run

# 2. Restore the most recent backup (checks local disk first, then S3):
node scripts/restoreBackup.js --latest --yes

# Restore a specific local file:
node scripts/restoreBackup.js --file=./backups/backup-2026-07-10T02-00-00-000Z.ejson.gz --yes

# Restore a specific S3 backup (downloaded automatically):
node scripts/restoreBackup.js --s3-key=backups/database/backup-....ejson.gz --yes

# Restore only specific collections:
node scripts/restoreBackup.js --latest --collections=User,Course --yes

# Merge instead of replace (upsert by _id, leaves untouched documents alone):
node scripts/restoreBackup.js --latest --mode=merge --yes
```

Restore modes:
- `replace` (default) — for each collection present in the backup, delete all
  existing documents and insert the backed-up ones. This is a true point-in-time
  restore of those collections.
- `merge` — upsert documents by `_id`; documents that exist now but weren't in the
  backup are left alone. Useful for recovering specific records without touching
  everything else.

The script refuses to write anything unless `--yes` is passed, so accidentally
running it without flags is harmless.

## Recovery drill

Periodically verify backups are actually restorable:

```bash
# Point MONGODB_URI at a scratch/staging database, then:
node scripts/restoreBackup.js --latest --yes
# ...spot check the data...
```
