# AI Course Builder — textbook figures & automatic lesson videos

This document covers the upgrade that lets an uploaded textbook become a multimedia course:
textbook figures are extracted and reused in lessons, and every generated lesson automatically
gets an explanatory video (plus a simulated experiment demonstration for science practicals).
It is written for engineers deploying and maintaining the system.

---

## 1. Architecture found before the upgrade

| Area | What existed |
|---|---|
| API | Node/Express 5 on Render (`server.js`), MongoDB Atlas via Mongoose, Firebase/JWT auth, S3 + CloudFront media |
| Course builder | `src/services/course-builder/*`: upload → pdfjs text extraction (Gemini OCR for scans) → Groq outline → per-lesson notes, activities, visuals, Wikimedia images, quizzes → source-quote verification → teacher review → publish to `Section` / `Lesson` / `Quiz` |
| Background work | In-process only (runner with resume-on-restart, `node-cron` schedulers). No queue, no Redis |
| Lesson video | `Lesson.videoId` = S3 key; players build a CloudFront URL or call `GET /api/videos/:lessonId/stream-url` |
| Progress | `Enrollment.completedLessons` (+ `studentProgress.utils.js`) — reused, not duplicated |
| Student UI | `professional_lesson_screen.dart` (video / notes / quiz / AI tabs), `ai_study_guide.dart` renders `aiContent` incl. images |
| Admin UI | `course_builder/*` screens (upload, outline, review items, publish) |
| Tests | No backend test runner; 4 Flutter widget tests |

## 2. What was added

```
Upload PDF ─┬─► text extraction (existing) ─► outline ─► lesson drafts ─┬─► integrity checks
            │                                                          ├─► textbook figures attached
            └─► FigureExtraction job ──► worker: PyMuPDF ──► FigureAsset library (S3)
                                                                       └─► lesson saved ─► lesson_video job(s)
                                                                                              │
 worker: storyboard (LLM) → narration (TTS) → frames (Puppeteer/KaTeX/SVG) → FFmpeg → checks → S3
                                                                                              │
                                   draft.video / Lesson.aiVideo ◄── status + result ◄─────────┘
                                   Lesson.videoId (if no teacher video) ─► existing players
```

* **Separate worker process** (`src/workers/media.worker.js`, `Dockerfile.worker`) runs all CPU-heavy work.
* **Persistent queue in MongoDB** (`GenerationJob`) — chosen over BullMQ because the platform has no Redis and jobs are few and long. Leases give crash recovery; a unique `key` gives duplicate prevention.
* **Programmatic rendering** — formulas (KaTeX), graphs (deterministic SVG from a safe expression parser), tables, ledgers, timelines, flows and textbook figures with label-anchored highlights. No text-to-video model is used for anything that must be exact.

## 3. Files

**Created (backend)**
- `python/figure_extractor.py`, `python/requirements.txt`, `python/tests/test_figure_extractor.py`
- `src/models/GenerationJob.js`, `FigureAsset.js`, `FigureExtraction.js`, `schemas/aiVideo.schema.js`
- `src/services/jobs/queue.service.js`, `worker.service.js`
- `src/services/course-builder/figures.service.js`, `figure-selection.service.js`, `integrity.service.js`
- `src/services/video/` — `pipeline.service.js`, `video-jobs.service.js`, `storyboard.service.js`, `subjects.js`, `experiment.js`, `captions.js`, `validator.js`, `cost.service.js`, `storage.service.js`, `providers/tts.js`, `providers/video.js`, `render/scene-html.js`, `render/renderer.js`, `render/assembler.js`
- `src/utils/mathExpression.js`, `src/controllers/lessonVideo.controller.js`, `src/middleware/generationLimiter.middleware.js`, `src/workers/media.worker.js`
- `scripts/createMediaIndexes.js`, `Dockerfile.worker`, `.dockerignore`, `test/*.test.js`, `test/helpers/setup.js`

**Modified (backend)**: `models/Lesson.js`, `CourseBuildItem.js`, `CourseBuildJob.js`; `services/course-builder/runner.service.js`, `publisher.service.js`, `ai.service.js` (usage callback only); `controllers/courseBuilder.controller.js`, `lesson.controller.js`, `video.controller.js`; `routes/courseBuilder.routes.js`; `package.json`; `.gitignore`; `../render.yaml`.

**Created (Flutter)**: `models/lesson_video.dart`, `presentation/widgets/ai_lesson/lesson_video_status.dart`, `presentation/screens/course_builder/widgets/lesson_video_panel.dart`, `.../widgets/build_media_card.dart`, `test/lesson_video_test.dart`.
**Modified (Flutter)**: `models/lesson.dart`, `models/course_build.dart`, `services/api/course_builder_service.dart`, `screens/learning/professional_lesson_screen.dart`, `screens/course_builder/course_build_item_screen.dart`, `course_build_job_screen.dart`, `widgets/build_options_panel.dart`.

## 4. Database changes and migration

All changes are **additive**; no migration script has to run and no existing document is rewritten.

| Collection | Change |
|---|---|
| `lessons` | `aiVideo`, `aiExperimentVideo` (default `null`), `contentVersion` (default 1) |
| `coursebuilditems` | `video`, `experimentVideo` (default `null`), `contentVersion` (default 0) |
| `coursebuildjobs` | `options.generateVideos` (default true), `options.videoLanguage`, `options.videoBudgetUsd`, `figureExtraction` |
| `generationjobs` (new) | queue + processing history (unique `key`) |
| `figureassets` (new) | one per extracted figure, unique (`bookHash`, `extractorVersion`, `figureId`) |
| `figureextractions` (new) | one per book version, unique (`bookHash`, `extractorVersion`) |

Older lessons simply have `aiVideo: null` — the API and app treat that as "no generated video".
Run `node scripts/createMediaIndexes.js` once (non-destructive) before enabling the worker.

Video metadata (`aiVideo`):
`status` (queued · generating_script · generating_audio · generating_visuals · assembling · validating · completed · failed · cancelled), `jobId`, `provider`, `s3Key`, `url`, `captionsKey`, `captionsUrl`, `durationSeconds`, `transcript`, `contentVersion`, `pendingContentVersion`, `stale`, `reviewStatus`, `disclosure`, `error`, `previous`.

## 5. Figure-extraction workflow

1. On upload the API hashes the PDF (sha256) and either links an existing completed extraction for that book version or queues one `figure_extraction` job. Non-PDF formats are marked `not_applicable`.
2. The worker runs `python/figure_extractor.py` (PyMuPDF) per page:
   embedded image boxes (icons/backgrounds filtered) → vector drawings clustered by path segments (header rules and empty grids discarded) → overlapping/nearby regions merged → short text labels around a region absorbed → captions (`Figure 2.1`, `Fig. 4.3`, `Table 2.1`) matched below/above with column awareness → captions without a figure trigger a search for drawings above them → **page region rendered at 140 DPI** (vector art and overlays included) → text inside the box extracted with label positions → OCR flag for text-less rasters → tables (`find_tables`, empty grids rejected), equation candidates, column-aware reading order → perceptual-hash duplicates and "(continued)" multi-page links.
3. Every figure gets `quality` = ok · needs_review · incomplete with warnings (`no_caption`, `touches_page_edge`, `possible_multi_page`, `reconstructed_from_caption`, `caption_without_region`, `duplicate`). A caption with no recoverable image is stored as **incomplete with no file** — never as a success.
4. PNGs and `figures.json` go to `textbook-figures/<bookHash>/<version>/` in S3; one `FigureAsset` per figure (chapter/section mapped from the outline). Rasters with baked-in labels are OCR'd with Gemini when `GEMINI_API_KEY` is set; otherwise they stay flagged.
5. Lesson generation waits up to `FIGURE_WAIT_SECONDS` for extraction, then for each lesson the AI classifies the figures on the lesson's pages as `notes` / `video_reference` / `animate` / `supplement` / `exclude`. Ids not in the candidate list are discarded. Selected figures appear in the notes (as images with "Source: <book>, page N") and are offered to the video planner.

## 6. Automatic video workflow

Trigger: the course-builder runner saves a generated lesson draft → `onLessonContentSaved` → one `explainer` job (+ an `experiment` job for physics/chemistry/biology lessons that describe a practical). The job key is `video:item:<id>:v<contentVersion>:<variant>:<configHash>`, so repeated events never duplicate work. Courses stay usable throughout.

Worker stages (each saved on the job so a retry resumes there):

| Stage | Work |
|---|---|
| generating_script | Planner (existing Groq model) gets objectives, notes, examples, formulas, figures, subject template, level, language, duration range → JSON storyboard. Validator: KaTeX compile check, graph expressions must parse in `x`, figure ids must be real, highlight labels must exist, observations may only contain numbers from the lesson, ledgers must balance, title/summary/safety scenes ensured. One automatic "explain more fully" retry when far below the target length |
| generating_audio | TTS per scene; durations measured with ffprobe; files kept in S3 (`ai-videos/work/<jobId>/`) with a text hash so paid narration is never bought twice. Budget checked **before** any paid call |
| generating_visuals | Puppeteer renders every frame (progressive reveals, graph drawing, figure highlights, auto-fit) |
| assembling | FFmpeg per-scene segments (H.264/AAC, 25 fps, fades) → stream-copied final MP4 with faststart |
| validating | ffprobe checks (readable, h264 1280×720, aac, size, duration vs plan, captions, narration) → WebVTT + transcript + poster → upload to `ai-videos/<courseId>/<target>/<variant>-v<n>-<jobId>.*` |

On success the result is mirrored onto the draft and, once published, the lesson. The previous valid video is kept in `previous` and is only replaced after the new one passes validation. `Lesson.videoId` is set to the generated key **only if the teacher has not uploaded their own video**. Experiment videos carry a "Simulated demonstration" disclosure on every frame and need review when hazards are detected (or always, with `VIDEO_REVIEW_EXPERIMENTS=true`, the default). Admins get an in-app notification on completion or final failure.

Lesson edits increment `contentVersion` and mark existing videos `stale`; with `VIDEO_REGENERATE_ON_CHANGE=manual` (default) nothing is regenerated automatically.

### 6a. Motion graphics, real-world media and in-video checks (renderer v2)

**Motion.** Each new element enters with a CSS animation (rise, write-on for formula and worked-example steps, pop for flow nodes and quiz choices, pulse for figure highlights, slide-in lower thirds). The renderer pauses the animations and screenshots them at fixed times (`VIDEO_ANIM_FPS`, default 15, for 0.6 s), then holds the final frame, so every render is identical.

**Licensed photos and clips.** The planner adds a short search phrase (`media: { query, kind, alternatives }`) to the title, to `media` scenes (full-screen photo or clip with animated key points) and to bullet and experiment scenes (photo or clip in a framed panel beside the points). When it asks for fewer than three, the scene heading is used as the phrase. The worker searches the enabled providers, ranks results by how many of the phrase's words appear in their title, tags and description, and rejects weak matches. If the phrase names a lesson topic word (from the lesson title and key terms, such as "quadrat"), the result must contain that word. Nothing is shown rather than an unrelated picture.

| Provider | Key | Licence handling |
|---|---|---|
| Wikimedia Commons | none (identify yourself with `VIDEO_STOCK_USER_AGENT`) | CC0, public domain and CC BY only; CC BY-SA only with `VIDEO_STOCK_ALLOW_SHARE_ALIKE=true`; NC/ND and unknown licences rejected |
| Pexels | `PEXELS_API_KEY` | Pexels licence (credit given anyway) |
| Pixabay | `PIXABAY_API_KEY` | Pixabay content licence; files are always downloaded to our storage (no hotlinking); searches cached 24 h |

Pinterest and similar sites are not supported: they have no API or licence for reusing other people's pins. Openverse was evaluated but its API timed out during development, so it is not included.

Chosen files are downloaded once, normalised (photos to JPEG, clips to 1280×720 H.264 without sound, at most 30 s) and stored under `stock-media/<provider>/<id>` with a credit file next to them; later videos reuse them. FFmpeg puts the photo (slow zoom or pan) or clip under the transparent animated overlay. Exact content (formulas, graphs, tables, textbook figures) never sits on stock media. Every photo carries an on-screen credit, and a 4-second "Photo and video credits" slide closes the video. Requests are paced (`VIDEO_STOCK_MIN_INTERVAL_MS`), throttling answers are retried, and a provider that keeps refusing is skipped for a minute; a failed search never fails the video. Retries of a job reuse the media already chosen.

**Interactive checks.** The planner adds 1–2 `check` scenes (question, 2–4 choices, answer, explanation). Each becomes a question scene, which ends with a 3.5 s "pause and choose" hold showing all choices, followed by an answer-reveal scene. The job output and the lesson's video record carry `interactions` (`at`, `resumeAt`, question, choices, answer, explanation) and `credits`. The app pauses at `at`, shows the question over the player, gives feedback with the explanation and continues from the answer reveal. Answer keys whose numbers do not appear in the lesson are flagged in the storyboard warnings for review.

**Experiment videos.** The apparatus, set-up, procedure and observation scenes of an experiment video always ask for a clip and are shown full screen, with the phase, heading and numbered steps on a dark card over it (the current step highlighted). Each asks for the step's action ("burette dripping into flask"), then the experiment's name ("titration", which finds real recordings on Wikimedia Commons), and finally general lab footage for that phase ("scientist doing laboratory experiment"), so a step still shows real hands-on work. Only these steps use the general fallback. Free stock libraries rarely have the exact textbook practical; the guided YouTube demonstration (6b) covers that.

### 6b. Real experiment demonstrations (YouTube)

A teacher can add a real demonstration video to a lesson from the draft's **Video** tab ("Real experiment (YouTube)"): search YouTube (`YOUTUBE_DATA_API_V3_KEY` on the **API** service), choose a video, and the AI writes the practical's steps **from the lesson** (with a short spoken explanation each and 1–2 check questions). Steps are placed in the video from its chapters when it has them; otherwise the teacher plays it and presses "Set to now" at each step (or types the time). Students see it once every step is placed: YouTube's embedded player with the steps beside it; at the start of each next step the video pauses, the explanation is read aloud (device TTS) and any check question must be answered before it continues.

The video is never downloaded or altered (YouTube terms): it plays in YouTube's own player, our content sits beside it. Only embeddable, safe-search videos of 30 s–20 min are offered. A search costs 100 of the default 10,000 daily quota units, so searches run only when a teacher asks and are cached for 7 days. On Windows/Linux desktop builds (no embedded web view) students get the steps with "watch on YouTube at 1:15" links instead.

Code: `src/services/demo/youtube.service.js`, `src/services/demo/demo.service.js`, `src/controllers/demo.controller.js`, `src/models/schemas/demo.schema.js` (`CourseBuildItem.demo`, `Lesson.demo`); Flutter `models/lesson_demo.dart`, `presentation/widgets/demo/guided_demo.dart`, `screens/course_builder/widgets/lesson_demo_card.dart`. Endpoints: `GET /items/:itemId/demo`, `POST /items/:itemId/demo/search`, `POST /items/:itemId/demo/select`, `PUT /items/:itemId/demo/steps`, `DELETE /items/:itemId/demo`.

## 7. Subject templates (`src/services/video/subjects.js`)

| Subject | Scene emphasis |
|---|---|
| Mathematics | animated graphs, step-by-step formula transformations, worked examples, figures |
| Physics / Chemistry / Biology | labelled figures with highlights, cause→effect flows, formulas with units, experiment scenes |
| Accounting / CPA | ledgers (balance-checked), statement tables, worked calculations |
| Languages | vocabulary tables, dialogues, words spoken in narration |
| Business | case-based flows and comparison tables, source-described graphs |
| Geography | maps/figures with label highlights, process flows |
| History | timelines, maps; imagined scenes labelled as reconstructions |
| General | bullets, flows, tables, figures |

## 8. Queue, retries and limits

* Atomic claim with a lease (`JOB_LEASE_MS`, default 120 s) renewed by heartbeat; expired leases are reclaimed (crash/redeploy recovery).
* Retries: exponential backoff with jitter (`JOB_BACKOFF_BASE_MS` 30 s → `JOB_BACKOFF_MAX_MS` 30 min), `VIDEO_MAX_ATTEMPTS` (3). Configuration, budget, missing-content and "lesson changed" errors are never retried.
* Timeouts: `VIDEO_JOB_TIMEOUT_MS` (30 min), `FIGURE_JOB_TIMEOUT_MS` (20 min). Cancellation: queued jobs stop at once; running jobs at the next stage.
* Graceful shutdown on SIGTERM releases unfinished jobs without counting the attempt.
* Concurrency: `MEDIA_WORKER_CONCURRENCY` (1); FFmpeg threads `VIDEO_FFMPEG_THREADS` (2).
* **Parallel videos.** One render peaks at about 0.9 GB (measured: Chromium + FFmpeg + Node), so allow ~1 GB per video: concurrency 1 on a 2 GB plan, 3 on a 4 GB plan. Alternatively keep concurrency 1 and run several worker instances; leases make sure each video is made by exactly one worker. Much of a video's time is spent waiting on the AI, narration and stock-media APIs, so parallel videos help even with few CPUs. Each video reserves its estimated cost before paying for narration, and the budget check counts other running videos' reservations, so parallel videos cannot overshoot the course budget together (near the limit one of them stops with BUDGET_EXCEEDED instead). Check the ElevenLabs plan's concurrent-request limit before running many videos at once.
* **Stuck videos.** The worker makes one video at a time, so a hung video blocks the others until `VIDEO_JOB_TIMEOUT_MS` (30 min). The build's media card warns when a video looks stuck (running with no stage change for `VIDEO_STUCK_MINUTES`, default 15; worker lease expired; or a cancel the worker has not acted on) and opens **Lesson videos in progress**: every running / waiting / failed video with its lesson, stage, time in stage and worker, and Stop, **Force stop** and Retry (failed videos grouped by error, with "Retry these"). A normal stop asks the worker to stop at its next step; a force stop marks the job cancelled at once, and the worker drops it at its next heartbeat and takes the next video. It also warns when videos are waiting but no worker has run anything for 10 minutes. API: `GET /jobs/:jobId/video-jobs`, `POST /jobs/:jobId/video-jobs/bulk` (`action`: `stop` | `force_stop` | `retry`, optional `ids`, `stuckOnly`), `POST /video-jobs/:id/cancel` with `{ "force": true }`.
* Costs: per-job and per-course USD totals from configured rates; `VIDEO_MAX_COST_PER_LESSON_USD` (1.00) and `VIDEO_MAX_COST_PER_COURSE_USD` (25.00, per-build override). A paid TTS provider without `VIDEO_TTS_COST_PER_1K_CHARS` is refused.

## 9. API (all under `/api/course-builder`, admin or assigned instructor)

| Method | Path | Purpose |
|---|---|---|
| GET | `/jobs/:jobId/media` | figure extraction status, video counts, spend vs budget, policy |
| GET | `/jobs/:jobId/figures` | figure assets (`?page=`, `?quality=`) |
| POST | `/jobs/:jobId/figures/extract` | (re)request extraction |
| GET | `/items/:itemId/videos` | latest explainer/experiment job + history + draft video state |
| POST | `/items/:itemId/videos` | `{variant, mode}` — mode `retry` · `script` · `audio` · `visuals` · `full` |
| GET / POST | `/lessons/:lessonId/videos` | same for published lessons (incl. lessons not made by the builder) |
| GET | `/video-jobs/:id` | detail incl. checks, storyboard, cost, signed preview URL |
| POST | `/video-jobs/:id/cancel` | cancel |
| POST | `/video-jobs/:id/review` | `{status: approved | rejected}` |

POST routes are rate-limited per user (`GENERATION_RATE_LIMIT`, default 30 per 10 min). Student endpoints: lesson payloads now include `aiVideo` / `aiExperimentVideo` with the file fields removed until a video is watchable; `GET /api/videos/:lessonId/stream-url?variant=experiment` signs the experiment video.

## 10. Flutter changes

* **Students** (`professional_lesson_screen.dart`): while a video is processing / under review / failed, the player area explains it and offers "Study the notes" / "Take the quiz" (notes open by default when no video is ready). Approved experiment demos get a "Lesson video | Experiment demo (simulated)" switch. Below the player: transcript (narration captions), simulated-demo disclosure, "made for an earlier version" notice. Textbook figures appear in the study guide through the existing image rendering.
* **Admins**: build screen shows a media card (figure extraction, video counts, review queue, spend vs budget, re-extract). Each lesson draft has a **Video** tab: per-variant status/stage, errors with stage, cost, quality checks, storyboard, preview, Retry, Regenerate (script / narration / visuals / everything), Cancel, Approve/Reject. Build options gain "Generate a video for every lesson" and a course video budget.

## 11. Configuration and deployment

**Worker (Render Background Worker, Docker)** — `render.yaml` now declares `echapp-media-worker` (`backend/Dockerfile.worker`: Node 22, Chromium, FFmpeg, espeak-ng, Python 3 + PyMuPDF). Apply the Blueprint or create the worker manually with the same settings. Use a plan with ~2 GB RAM.

Required on the worker: `MONGODB_URI`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `S3_BUCKET_NAME`, `S3_BUCKET_URL`, `CLOUDFRONT_URL`, `GROQ_API_KEY`.

| Variable | Default | Meaning |
|---|---|---|
| `VIDEO_TTS_PROVIDER` | `auto` | `elevenlabs` if `ELEVENLABS_API_KEY` set, else `espeak` (installed in the image); `silent` only for tests |
| `ELEVENLABS_API_KEY`, `ELEVENLABS_VOICE_ID`, `ELEVENLABS_MODEL_ID` | — / existing / `eleven_turbo_v2_5` | natural narration (existing account) |
| `VIDEO_TTS_COST_PER_1K_CHARS` | — | **required** with ElevenLabs (spending control) |
| `VIDEO_LLM_COST_PER_1K_TOKENS` | 0 | planner cost for reporting/limits |
| `VIDEO_MAX_COST_PER_LESSON_USD` / `..._PER_COURSE_USD` | 1 / 25 | spending limits |
| `VIDEO_AUTOGEN_ENABLED` / `VIDEO_AUTOGEN_TRIGGER` / `VIDEO_REGENERATE_ON_CHANGE` | true / draft / manual | generation policy (set on the **API** service) |
| `VIDEO_REQUIRE_REVIEW` / `VIDEO_REVIEW_EXPERIMENTS` | false / true | review-before-publication |
| `MEDIA_WORKER_CONCURRENCY`, `VIDEO_FFMPEG_THREADS` | 1 / 2 | resource limits |
| `FIGURE_EXTRACTION_ENABLED`, `FIGURE_EXTRACTOR_DPI`, `FIGURE_EXTRACTOR_CONFIG`, `FIGURE_WAIT_SECONDS`, `FIGURE_OCR_MAX` | true / 140 / — / 180 / 40 | figure extraction |
| `GEMINI_API_KEY` | — | optional OCR of raster labels |
| `VIDEO_STOCK_MEDIA` | true | licensed photos and clips in videos |
| `VIDEO_STOCK_PROVIDERS` | `pexels,pixabay,wikimedia` | search order; providers without a key are skipped |
| `PEXELS_API_KEY`, `PIXABAY_API_KEY` | — | free keys from pexels.com/api and pixabay.com/api/docs; strongly recommended for video clips (Pexels has paused new keys) |
| `YOUTUBE_DATA_API_V3_KEY` | — | **API service** (not the worker): YouTube search for guided experiment demonstrations (Google Cloud → YouTube Data API v3) |
| `VIDEO_STOCK_USER_AGENT` | `ECH-CourseBuilder/1.0 (educational lesson videos)` | set to include a contact email or URL (Wikimedia API etiquette) |
| `VIDEO_STOCK_ALLOW_SHARE_ALIKE` | false | also accept CC BY-SA photos from Wikimedia (check your licensing position first) |
| `VIDEO_STOCK_MIN_MATCH`, `VIDEO_STOCK_MAX_ITEMS`, `VIDEO_STOCK_MAX_VIDEO_MB`, `VIDEO_STOCK_MAX_CLIP_SECONDS`, `VIDEO_STOCK_MIN_INTERVAL_MS` | 0.5 / 12 / 60 / 30 / 1000 | relevance threshold, media per video, download and clip limits, request pacing |
| `VIDEO_ANIM_FPS` | 15 | animation sampling rate (0 disables entrance animations) |
| `GENERATION_RATE_LIMIT`, `GENERATION_RATE_WINDOW_MS` | 30 / 600000 | admin endpoint rate limit |

Deployment steps: deploy the API as usual → `node scripts/createMediaIndexes.js` → create the worker → set `VIDEO_TTS_COST_PER_1K_CHARS` if ElevenLabs is used → upload a small PDF and watch the build's media card. Without a running worker, jobs simply wait in `queued` and lessons stay fully usable.

Local development: `cd backend/python && python -m venv .venv && .venv/Scripts/pip install -r requirements.txt`; set `PYTHON_BIN` to the venv python; `MEDIA_STORAGE_DRIVER=local` keeps media out of S3; `npm run worker`.

## 12. Tests

`npm test` (backend, Node test runner + in-memory MongoDB — never touches Atlas, S3 or paid APIs) and `npm run test:python`.

| Suite | Covers |
|---|---|
| `python/tests` (18) | real-book layouts (long `FIGURE n.n:` captions, unnumbered `FIGURE (…)` captions, left-aligned captions under centred figures, paragraph tails and page markers excluded from labels, shared frames not flagged as duplicates), page numbering, vector graphs + labels + label positions, captions (figures/tables, below/above), raster callouts, OCR flag, overlapping images, decorative filtering, tables, caption-without-figure reported incomplete, duplicates, two-column reading order, CLI errors |
| `test/unit.test.js` (12) | expression parser, arithmetic/formula/calculation/hazard checks, storyboard validation (invented figures, LaTeX fallback, graph rejection, invented measurements, safety, ledger balance, length expansion), captions, subjects/experiments, figure-id validation, cost rules, deterministic plots |
| `test/queue.test.js` (10) | duplicate prevention under concurrency, exclusive claims, backoff, max attempts, non-retryable errors, lease-expiry recovery, requeue, stages/artifacts/costs, timeout, cancellation, graceful release |
| `test/builder-video.test.js` (6) | job created after lesson persistence and only once, videos off, publish sync, stale on edit without overwriting, teacher video protected, review gating + student sanitising, failure mirrored + retry |
| `test/e2e.test.js` (9) | PDF → worker extraction → asset library; book re-upload reuse; lesson with textbook figures queues explainer + experiment; real render/validate/store of both; publish → playback via `videoId`; unreviewed experiment not streamable; visuals-only regeneration reuses script; failing re-render keeps the valid video; budget stop before paid calls; invalid file detection |
| `test/media.test.js` (16) | Commons licence rules on real API data, Pexels/Pixabay parsing, relevance and topic gate, fallback queries, photo fallback for clips, provider errors, 429/overload retry and cool-down, download size/type limits, clip normalisation and storage reuse, media and check scenes in the storyboard, transparent overlays, frame timing, FFmpeg compositing (pixel-checked), full worker run with media, a check question and credits, retry reuse |
| Flutter `test/lesson_video_test.dart` (16) | parsing incl. older lessons, processing/failed/review states, notes/quiz fallback, small-phone layout, transcript/disclosure/stale card |

The real planner (Groq) was also exercised once with maths and accounting lessons: both storyboards validated without warnings and rendered to ~2:15 videos.

### Docker end-to-end test (real textbook)

The worker image (`Dockerfile.worker`) was built and run against a throwaway `mongo:7` container on a private Docker network, with `MEDIA_STORAGE_DRIVER=local` on a mounted folder, `VIDEO_TTS_PROVIDER=espeak` and only `GROQ_API_KEY` passed in (no production database, S3 or ElevenLabs). Test book: *Biology S6 Student Book* (349 pages).

| Step | Result |
|---|---|
| Figure extraction in the container | completed on attempt 1 in 47 s; 331 figures/tables, 329 `ok`, 2 `needs_review` (uncaptioned diagrams), 3 caption-only, 0 duplicates; 331 PNGs + `figures.json` stored; build job marked `completed` |
| Unit 1 spot check (pp. 8–24) | all 9 numbered figures, 8 unnumbered illustrations and Table 1.1 matched to the correct captions (the book has no Figure 1.4) |
| Explainer video (quadrats & line transects, using Figures 1.5 and 1.6) | completed in 42 s: 1280×720 H.264 + AAC, 2:26, 9 scenes, espeak narration (mean −20.6 dB), WebVTT captions and poster stored; both textbook figures shown with captions and page numbers |
| Experiment video (same lesson) | completed in 37 s: 2:09, 9 scenes (apparatus, safety, set-up, procedure, figures, calculation), "Simulated demonstration" banner on every scene |
| `docker stop` | SIGTERM handled, exit code 0 |

Renderer v2 (motion, stock media, checks) was then run the same way with the real Groq planner, live Wikimedia Commons search and espeak narration on the same Biology lesson:

| Video | Result |
|---|---|
| Explainer | completed in 136 s; 2:20, 13 scenes, 2 interactive checks with correct answer keys, 2 Commons photos with on-screen credits plus a credits slide; all quality checks passed |
| Experiment demo | completed in 125 s; 2:41, 4 Commons photos (full-screen title, framed panels), 1 check; all quality checks passed |
| Problems found and fixed during the runs | planner used media too rarely (stricter prompt plus heading fallback); Wikimedia throttling (pacing, retries, cool-down; HTTP-200 error bodies are no longer cached as "no results"); a loosely related photo ("Hand in hand" for "hand holding quadrat frame") was accepted (topic gate) |

## 13. Known limitations

* Stock media was tested live only with Wikimedia Commons. Pexels and Pixabay are built to their official documentation and tested with recorded response shapes, but have not been called live because no keys are configured.
* Wikimedia Commons has few video clips and many relevant photos are CC BY-SA (off by default), so lessons get fewer and sometimes less fitting pictures (for example underwater quadrat surveys for a grassland lesson). Its search API also throttles bursts. Adding Pexels/Pixabay keys gives more and better matches, especially clips.
* Relevance is judged from titles, tags and descriptions, not by looking at the picture. The topic gate and the threshold reject most mismatches, but an admin should still watch generated videos before relying on them.
* The in-player question overlay is shown in the inline player; when a student is in full screen, the mobile player leaves full screen to show it, and the desktop/web players pause without the overlay.
* Narration in the automated tests is silent. espeak-ng narration was verified in the Docker image; ElevenLabs was not exercised (no ElevenLabs call was made).
* The Docker image has been run locally only; it has not yet been deployed to Render with this configuration.
* Extraction has been checked on one real textbook (Biology S6). Other books may need threshold tuning (`FIGURE_EXTRACTOR_CONFIG`), especially scanned books (no embedded images to locate figures), figures split across columns/pages, and dense vector layouts.
* On the Biology book, 3 captions found no figure region (pp. 306, 322, 323) and 2 diagrams have no caption (pp. 83, 199); these are flagged for review rather than guessed. Crops can include a few pixels of the caption line below the figure (4 pt render padding).
* OCR of raster labels needs `GEMINI_API_KEY` (not configured in this environment, untested).
* No third-party text-to-video provider is implemented (none verified); the provider interface is ready in `providers/video.js`.
* Captions are delivered as a WebVTT file and an in-app transcript; the existing video players do not yet render the VTT track inline.
* Kinyarwanda narration has no espeak voice (falls back to English voice); use ElevenLabs or a dedicated voice.
* The rate limiter is in-memory (per API instance).
* Generated work audio in `ai-videos/work/` is kept for cheap re-renders; there is no automatic cleanup yet.

## 14. Recommended next improvements

1. Run the extractor on 3 real textbooks (maths, science, general) and tune thresholds; add those PDFs as private regression fixtures.
2. Render the VTT captions in `CustomVideoPlayer` / `OptimizedVideoPlayer`.
3. Add a Kinyarwanda-capable TTS voice and per-course voice selection.
4. Ken-Burns/zoom on figures and cross-fades between frames (FFmpeg `zoompan`/`xfade`).
5. Lifecycle rule or cleanup job for `ai-videos/work/` and superseded `previous` videos.
6. Admin figure browser with manual crop/merge corrections stored as derivatives.
7. Optional verified text-to-video clip provider for illustrative scenes only, behind the budget.
