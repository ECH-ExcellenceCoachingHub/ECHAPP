# S3 Presigned URL Configuration Fix

## Problem
S3 returns "I received your request, but something in it is invalid" error when using presigned URLs for course content uploads.

## Root Cause
This is a **configuration mismatch** between the presigned URL generation and the actual upload request. The most common causes are:

1. **Method mismatch**: URL generated for PUT but uploaded with POST
2. **Content-Type mismatch**: Different Content-Type than what was signed
3. **Extra headers**: Additional headers added by frontend that weren't signed
4. **File size differences**: File bigger than allowed in presigned URL

## Solution Implemented

### 1. Backend Changes

**New S3 Service Method** (`s3.service.js`):
```javascript
async generatePresignedUploadUrl(fileName, contentType, folder = 'uploads', expiresIn = 300) {
  try {
    const key = this.generateFileKey(fileName, folder);
    
    const command = new PutObjectCommand({
      Bucket: this.bucketName,
      Key: key,
      ContentType: contentType,  // MUST match frontend exactly
      // No ACL - using bucket policy for public access
    });

    // Generate presigned URL for PUT request
    const uploadUrl = await getSignedUrl(this.client, command, {
      expiresIn: expiresIn
    });

    return {
      uploadUrl: uploadUrl,
      key: key,
      publicUrl: `${this.bucketUrl}/${key}`
    };
  } catch (error) {
    throw new Error(`Failed to generate presigned upload URL: ${error.message}`);
  }
}
```

**New Controller Endpoint** (`upload.controller.js`):
```javascript
const generatePresignedUrl = async (req, res) => {
  try {
    const { fileName, contentType, folder = 'uploads' } = req.body;
    
    // Validate required parameters
    if (!fileName) {
      return sendError(res, 'File name is required', 400);
    }
    
    if (!contentType) {
      return sendError(res, 'Content type is required', 400);
    }
    
    // Validate content type
    if (!contentType.startsWith('image/') && !contentType.startsWith('video/')) {
      return sendError(res, 'Only image and video files are allowed', 400);
    }
    
    // Generate presigned URL (5 minutes expiration)
    const result = await s3Service.generatePresignedUploadUrl(
      fileName,
      contentType,
      folder,
      300
    );
    
    sendSuccess(res, {
      uploadUrl: result.uploadUrl,
      key: result.key,
      publicUrl: result.publicUrl,
      expiresIn: 300
    }, 'Presigned URL generated successfully');
    
  } catch (error) {
    console.error('Presigned URL generation error:', error);
    sendError(res, 'Failed to generate presigned URL', 500, error.message);
  }
};
```

**New Route** (`upload.routes.js`):
```javascript
// Generate presigned URL for direct S3 upload (admin only for course content)
router.post('/presigned-url', protect, authorize('admin'), generatePresignedUrl);
```

### 2. Correct Frontend Implementation

**✅ CORRECT WAY (PUT method):**
```javascript
// Step 1: Get presigned URL from backend
const presignResponse = await fetch('http://192.168.1.4:5000/api/upload/presigned-url', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${authToken}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    fileName: 'my-video.mp4',
    contentType: 'video/mp4',  // MUST match exactly
    folder: 'course-videos'
  })
});

const { uploadUrl, key } = await presignResponse.json();

// Step 2: Upload directly to S3 using PUT (NOT POST)
const uploadResponse = await fetch(uploadUrl, {
  method: 'PUT',
  headers: {
    'Content-Type': 'video/mp4'  // MUST match what was signed
  },
  body: file  // File object from input
});

if (uploadResponse.ok) {
  console.log('Upload successful!');
  // Save the key to your database for later retrieval
}
```

**❌ INCORRECT WAYS (will cause 400 errors):**

1. **Method mismatch:**
```javascript
// WRONG - Using POST instead of PUT
fetch(uploadUrl, {
  method: 'POST',  // ❌ Should be PUT
  body: file
});
```

2. **Content-Type mismatch:**
```javascript
// WRONG - Different Content-Type than signed
fetch(uploadUrl, {
  method: 'PUT',
  headers: {
    'Content-Type': 'application/octet-stream'  // ❌ Should match signed type
  },
  body: file
});
```

3. **Extra headers:**
```javascript
// WRONG - Adding unauthorized headers
fetch(uploadUrl, {
  method: 'PUT',
  headers: {
    'Content-Type': 'video/mp4',
    'Authorization': 'Bearer token',  // ❌ Not allowed in presigned URLs
    'Custom-Header': 'value'          // ❌ Not signed
  },
  body: file
});
```

### 3. API Endpoint Details

**Endpoint:** `POST /api/upload/presigned-url`
**Auth Required:** Yes (admin only)
**Body Parameters:**
- `fileName` (required): Original file name
- `contentType` (required): MIME type (e.g., 'video/mp4', 'image/jpeg')
- `folder` (optional): Storage folder (default: 'uploads')

**Response:**
```json
{
  "success": true,
  "message": "Presigned URL generated successfully",
  "data": {
    "uploadUrl": "https://echcoahing.s3.amazonaws.com/path/to/file?X-Amz-Algorithm=...",
    "key": "course-videos/filename-timestamp-random.ext",
    "publicUrl": "https://d3ofk5ujo941v.cloudfront.net/course-videos/filename-timestamp-random.ext",
    "expiresIn": 300
  }
}
```

### 4. Common Error Scenarios and Solutions

**Error: "The request signature we calculated does not match..."**
- **Cause**: Content-Type mismatch
- **Solution**: Ensure Content-Type in upload request exactly matches what was signed

**Error: "Method not allowed"**
- **Cause**: Using POST instead of PUT
- **Solution**: Use PUT method for S3 presigned URLs

**Error: "Request has expired"**
- **Cause**: Upload took longer than expiration time
- **Solution**: Increase expiration time or upload faster

**Error: "Access Denied"**
- **Cause**: Bucket policy or CORS misconfiguration
- **Solution**: Check S3 bucket policy and CORS settings. For mobile/web compatibility, ensure this CORS config is applied to the bucket:
```json
[
  {
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "PUT", "POST"],
    "AllowedOrigins": ["*"],
    "ExposeHeaders": []
  }
]
```

**Error: Mixed Content (HTTP vs HTTPS)**
- **Cause**: Browser blocking HTTP media on HTTPS site
- **Solution**: The system automatically uses CloudFront HTTPS URLs (`https://d3ofk5ujo941v.cloudfront.net`). Ensure your `.env` has `CLOUDFRONT_URL` set to `https`.

### 5. Testing the Fix

1. **Generate presigned URL:**
```bash
curl -X POST http://localhost:5000/api/upload/presigned-url \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "fileName": "test-video.mp4",
    "contentType": "video/mp4",
    "folder": "course-videos"
  }'
```

2. **Use the returned URL to upload:**
```bash
curl -X PUT "RETURNED_UPLOAD_URL" \
  -H "Content-Type: video/mp4" \
  --data-binary @your-video-file.mp4
```

### 6. Security Considerations

- Presigned URLs expire after 5 minutes (configurable)
- Only admin users can generate presigned URLs
- Content-Type is validated to prevent malicious uploads
- File names are sanitized and timestamped
- Bucket policies should restrict public write access

This implementation ensures exact parameter matching between presigned URL generation and actual upload, eliminating the "invalid request" errors.