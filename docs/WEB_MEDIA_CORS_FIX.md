# Web Media CORS Fix

## Problem

The Flutter **web** app (`https://app.excellencecoachinghub.com`) renders images and videos using XHR/fetch, which is subject to the browser's Same-Origin Policy (CORS). Media files served from the CloudFront CDN (`https://d3ofk5ujo941v.cloudfront.net`) and S3 buckets do **not** return an `Access-Control-Allow-Origin` header, so the browser blocks them on the web version.

**Symptoms** in the browser console:
```
Access to image at 'https://d3ofk5ujo941v.cloudfront.net/images/...' from origin
'https://app.excellencecoachinghub.com' has been blocked by CORS policy:
No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

**Why desktop/mobile are unaffected:** Native (non-web) network stacks do not enforce CORS. Only the web build is affected.

## Solution (already implemented)

### 1. Backend media proxy
A proxy endpoint was added to the backend:

- **File:** `backend/src/routes/media.routes.js`
- **Route:** `GET /api/media/proxy?url=<fully-encoded media URL>`
- **Behavior:** Fetches the requested CloudFront/S3 media server-side (server-to-server, no CORS) and streams the bytes back to the browser **with** the correct CORS headers (`Access-Control-Allow-Origin: *`).
- **Security:** Only allows proxying of known CloudFront/S3 domains (`d3ofk5ujo941v.cloudfront.net`, `echcoahing.s3.amazonaws.com`, `excellencecoachinghub.s3.amazonaws.com`). Other hosts are rejected with `403`.
- Mounted in `backend/server.js` at `app.use('/api/media', mediaRoutes)`.

### 2. Frontend media proxy helper
- **File:** `frontend/lib/utils/media_proxy.dart`
- **Function:** `String mediaProxyUrl(String? url)`
- **Behavior:** On **web only** (`kIsWeb`), if the URL is a CloudFront/S3 URL, it returns the backend proxy URL. On desktop/mobile it returns the original URL unchanged.

### 3. Frontend media widgets now use the proxy
All CDN `Image.network`, `NetworkImage`, and `CachedNetworkImage` calls now route through `mediaProxyUrl` on web:

- `frontend/lib/widgets/network_image_widget.dart`
- `frontend/lib/presentation/widgets/video_player/custom_video_player.dart` (video URLs on web)
- `frontend/lib/presentation/screens/admin/admin_dashboard_screen.dart`
- `frontend/lib/presentation/screens/admin/course_analytics_screen.dart`
- `frontend/lib/presentation/screens/admin/admin_teachers_screen.dart`
- `frontend/lib/presentation/screens/admin/admin_books_screen.dart`
- `frontend/lib/presentation/screens/library/library_screen.dart`
- `frontend/lib/widgets/ai_chat_message_widget.dart`
- `frontend/lib/widgets/quiz/multiple_choice_question_widget.dart`
- `frontend/lib/widgets/quiz/essay_question_widget.dart`
- `frontend/lib/widgets/quiz/true_false_question_widget.dart`
- `frontend/lib/widgets/quiz/drag_drop_question_widget.dart`
- `frontend/lib/widgets/main_layout.dart`
- `frontend/lib/widgets/responsive_navigation_drawer.dart`

## Large Video Playback Fix (streaming / 50MB limit removed)

The original proxy buffered the entire file in memory with a hard **50 MB** limit. Any video larger than 50 MB failed with `maxContentLength size of 52428800 exceeded`, and the browser reported `MEDIA_ERR_SRC_NOT_SUPPORTED`.

The current proxy **streams** the upstream response (no in-memory buffer, no size limit) and forwards the client's HTTP `Range` header, returning `206 Partial Content` with `Content-Range`/`Accept-Ranges`. This lets large videos play and seek correctly in the browser.

> Note: This addresses the 50 MB + Range/seek issue. H.265/HEVC videos are a separate codec-compatibility concern and are not converted by this proxy.

## Recommended: Configure CloudFront CORS (proper long-term fix)

The proxy is a **workaround**. For a proper fix, configure CORS directly on the CloudFront distribution so the CDN itself returns the `Access-Control-Allow-Origin` header. This removes the proxy round-trip and improves performance.

### Steps in AWS CloudFront console

1. Open the **CloudFront console** → select your distribution (`d3ofk5ujo941v.cloudfront.net`).
2. Go to the **Origins** tab → select your S3 origin → **Edit**.
   - Ensure **"Origin access"** is set appropriately (Origin Access Control or Public) and **"Add CORS headers" / "Allow cross-origin requests"** is enabled.
3. Go to the **Behaviors** tab → select the behavior (e.g. `Default (*)`) → **Edit**.
4. Under **"Cache key and origin requests"**, ensure **"Origin request policy"** includes the `Origin` header (or use a policy that forwards `Origin`).
5. Under **"Response headers policy"**, add a policy that includes `Access-Control-Allow-Origin` (or create a **CORS custom policy**):
   - `Access-Control-Allow-Origin`: `*` (or restrict to `https://app.excellencecoachinghub.com`)
   - `Access-Control-Allow-Methods`: `GET, HEAD, OPTIONS`
   - `Access-Control-Allow-Headers`: `Content-Type, Authorization`
   - `Access-Control-Max-Age`: `86400`
6. **Save changes** and wait for the distribution to deploy (5–15 minutes).

### Alternative: Configure CORS on the S3 bucket

If you prefer direct S3 access (bypassing CloudFront), add a CORS policy on the S3 bucket:

```json
[
  {
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "HEAD"],
    "AllowedOrigins": ["*"],
    "ExposeHeaders": [],
    "MaxAgeSeconds": 86400
  }
]
```

> Note: The proxy already handles this, so the CORS console setup is optional but recommended for performance.

## Verification

After deploying both the backend and the updated web build:

1. Open the web app (`https://app.excellencecoachinghub.com`).
2. Navigate to a course with images/thumbnails and a lesson with a video.
3. Open browser DevTools → **Network** tab.
4. Confirm image/video requests go to `https://echappbackend.onrender.com/api/media/proxy?url=...` and return status `200` (not blocked by CORS).
5. Confirm no `Access to image/video ... blocked by CORS policy` errors in the console.
