const {
  S3Client,
  PutObjectCommand,
  GetObjectCommand,
  DeleteObjectCommand,
  HeadObjectCommand
} = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const crypto = require('crypto');
const path = require('path');

class S3Service {
  constructor() {
    this.client = new S3Client({
      region: process.env.AWS_REGION,
      credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
      }
    });
    
    this.bucketName = process.env.S3_BUCKET_NAME;
    this.bucketUrl = process.env.S3_BUCKET_URL;
    this.cloudfrontUrl = process.env.CLOUDFRONT_URL || process.env.S3_BUCKET_URL;
  }

  // Generate unique key for file storage
  generateFileKey(originalName, folder = 'uploads') {
    const name = String(originalName || 'file');
    // Keep keys URL-safe: non-ASCII characters (accents, emoji, the narrow
    // no-break space in macOS screenshot names, ...) break uploads and URLs.
    const ext = path.extname(name).toLowerCase().replace(/[^a-z0-9.]/g, '');
    const basename = path.basename(name, path.extname(name))
      .normalize('NFKD')
      .replace(/[^A-Za-z0-9._-]+/g, '-')
      .replace(/-+/g, '-')
      .replace(/^[-.]+|[-.]+$/g, '')
      .slice(0, 80) || 'file';
    const timestamp = Date.now();
    const randomString = crypto.randomBytes(8).toString('hex');
    return `${folder}/${basename}-${timestamp}-${randomString}${ext}`;
  }

  // Upload file to S3
  async uploadFile(buffer, originalName, contentType, folder = 'uploads') {
    let key;
    try {
      key = this.generateFileKey(originalName, folder);

      const command = new PutObjectCommand({
        Bucket: this.bucketName,
        Key: key,
        Body: buffer,
        ContentType: contentType,
        // Remove ACL since modern S3 buckets may not allow ACLs
        // Public access is controlled via bucket policy
        Metadata: {
          // S3 metadata is sent as HTTP headers and must be ASCII
          'original-name': encodeURIComponent(String(originalName || '')).slice(0, 1024)
        }
      });

      const response = await this.client.send(command);
      
      return {
        key: key,
        url: `${this.cloudfrontUrl}/${key}`,
        bucket: this.bucketName,
        etag: response.ETag
      };
    } catch (error) {
      console.error('S3 Upload Error Details:', {
        error: error.message,
        stack: error.stack,
        bucket: this.bucketName,
        key: key,
        contentType: contentType,
        bufferLength: buffer ? buffer.length : 'undefined'
      });
      throw new Error(`Failed to upload file: ${error.message}`);
    }
  }

  // Generate signed URL for private file access
  async generateSignedUrl(key, expiresIn = 3600) { // 1 hour default
    try {
      const command = new GetObjectCommand({
        Bucket: this.bucketName,
        Key: key
      });

      const signedUrl = await getSignedUrl(this.client, command, {
        expiresIn: expiresIn
      });

      return signedUrl;
    } catch (error) {
      throw new Error(`Failed to generate signed URL: ${error.message}`);
    }
  }

  // Generate streaming URL for video content
  async generateStreamingUrl(key, expiresIn = 3600) {
    // Return CloudFront URL instead of signed S3 URL for better compatibility with all devices
    // CloudFront handles byte-range requests efficiently for video streaming
    return this.getPublicUrl(key);
  }

  // Explicitly generate signed S3 URL if needed
  async generateSignedS3Url(key, expiresIn = 3600) {
    try {
      const command = new GetObjectCommand({
        Bucket: this.bucketName,
        Key: key
      });

      const signedUrl = await getSignedUrl(this.client, command, {
        expiresIn: expiresIn
      });

      return signedUrl;
    } catch (error) {
      throw new Error(`Failed to generate signed S3 URL: ${error.message}`);
    }
  }

  // Get file metadata
  async getFileMetadata(key) {
    try {
      const command = new HeadObjectCommand({
        Bucket: this.bucketName,
        Key: key
      });

      const response = await this.client.send(command);
      
      return {
        key: key,
        size: response.ContentLength,
        contentType: response.ContentType,
        lastModified: response.LastModified,
        etag: response.ETag
      };
    } catch (error) {
      throw new Error(`Failed to get file metadata: ${error.message}`);
    }
  }

  // Delete file from S3
  async deleteFile(key) {
    try {
      const command = new DeleteObjectCommand({
        Bucket: this.bucketName,
        Key: key
      });

      await this.client.send(command);
      
      return {
        success: true,
        message: 'File deleted successfully'
      };
    } catch (error) {
      throw new Error(`Failed to delete file: ${error.message}`);
    }
  }

  // Check if file exists
  async fileExists(key) {
    try {
      await this.getFileMetadata(key);
      return true;
    } catch (error) {
      return false;
    }
  }

  // Upload image specifically
  async uploadImage(buffer, originalName, contentType = 'image/jpeg') {
    return await this.uploadFile(buffer, originalName, contentType, 'images');
  }

  // Upload video specifically
  async uploadVideo(buffer, originalName, contentType = 'video/mp4') {
    return await this.uploadFile(buffer, originalName, contentType, 'videos');
  }

  // Upload document specifically
  async uploadDocument(buffer, originalName, contentType = 'application/pdf') {
    return await this.uploadFile(buffer, originalName, contentType, 'documents');
  }

  // Get public URL (for publicly accessible files)
  getPublicUrl(key) {
    if (!key) return key;
    // Some stored records already hold a full URL rather than a bare S3 key
    // (e.g. lessons created from a client-side presigned upload). Prepending
    // the CloudFront domain again would produce a doubled, invalid URL.
    if (/^https?:\/\//i.test(key)) {
      return key;
    }
    // For public files, we can use the direct CloudFront URL
    return `${this.cloudfrontUrl}/${key}`;
  }
  
  // Generate presigned URL for direct client upload (PUT method)
  async generatePresignedUploadUrl(fileName, contentType, folder = 'uploads', expiresIn = 300) {
    try {
      const key = this.generateFileKey(fileName, folder);
      
      const command = new PutObjectCommand({
        Bucket: this.bucketName,
        Key: key,
        ContentType: contentType,
        // Remove ACL since modern S3 buckets may not allow ACLs
        // Public access is controlled via bucket policy
      });

      // Generate presigned URL for PUT request
      const uploadUrl = await getSignedUrl(this.client, command, {
        expiresIn: expiresIn
      });

      return {
        uploadUrl: uploadUrl,
        key: key,
        publicUrl: `${this.cloudfrontUrl}/${key}`
      };
    } catch (error) {
      console.error('S3 Presigned URL Generation Error Details:', {
        error: error.message,
        stack: error.stack,
        bucket: this.bucketName,
        fileName: fileName,
        contentType: contentType,
        folder: folder
      });
      throw new Error(`Failed to generate presigned upload URL: ${error.message}`);
    }
  }

  // Get signed URL for private files (alternative approach)
  async getSignedPublicUrl(key, expiresIn = 3600) {
    try {
      const command = new GetObjectCommand({
        Bucket: this.bucketName,
        Key: key
      });
      
      // Generate a signed URL that will work even for public files
      const signedUrl = await getSignedUrl(this.client, command, {
        expiresIn: expiresIn
      });
      
      return signedUrl;
    } catch (error) {
      console.error('Error generating signed URL:', error.message);
      // Return the public URL as fallback instead of throwing error
      return this.getPublicUrl(key);
    }
  }
  
  // Get file buffer from S3
  async getFileBuffer(key) {
    try {
      const command = new GetObjectCommand({
        Bucket: this.bucketName,
        Key: key
      });
      
      const response = await this.client.send(command);
      
      // Convert the response body to buffer
      const chunks = [];
      for await (const chunk of response.Body) {
        chunks.push(chunk);
      }
      
      return Buffer.concat(chunks);
    } catch (error) {
      console.error('Error fetching file from S3:', error.message);
      throw new Error(`Failed to fetch file from S3: ${error.message}`);
    }
  }
}

module.exports = new S3Service();