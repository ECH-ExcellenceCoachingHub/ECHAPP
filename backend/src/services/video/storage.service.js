const fs = require('fs');
const fsp = require('fs/promises');
const path = require('path');

/**
 * Object storage for generated media and extracted figures.
 *
 *   MEDIA_STORAGE_DRIVER=s3     (default) — the existing S3 bucket via s3.service
 *   MEDIA_STORAGE_DRIVER=local  — a local folder (MEDIA_LOCAL_DIR); used by tests
 *                                 and local development so nothing is written
 *                                 to the production bucket.
 *
 * Keys are deterministic (callers pass the full key), so re-uploading the same
 * artefact overwrites it instead of leaving orphans behind.
 */

function driverName() {
  return (process.env.MEDIA_STORAGE_DRIVER || 's3').toLowerCase();
}

function localDir() {
  return path.resolve(process.env.MEDIA_LOCAL_DIR || path.join(process.cwd(), 'media-local'));
}

const s3Driver = {
  name: 's3',
  async put(key, body, contentType) {
    const s3 = require('../s3.service');
    const { PutObjectCommand } = require('@aws-sdk/client-s3');
    if (!s3.bucketName) throw Object.assign(new Error('S3 is not configured (S3_BUCKET_NAME missing)'), { code: 'STORAGE_NOT_CONFIGURED', retryable: false });
    const buffer = Buffer.isBuffer(body) ? body : await fsp.readFile(body);
    await s3.client.send(new PutObjectCommand({ Bucket: s3.bucketName, Key: key, Body: buffer, ContentType: contentType }));
    return { key, url: s3.getPublicUrl(key), size: buffer.length };
  },
  async get(key) {
    const s3 = require('../s3.service');
    return s3.getFileBuffer(key);
  },
  async remove(key) {
    const s3 = require('../s3.service');
    await s3.deleteFile(key);
  },
  async exists(key) {
    const s3 = require('../s3.service');
    return s3.fileExists(key);
  },
  publicUrl(key) {
    const s3 = require('../s3.service');
    return s3.getPublicUrl(key);
  },
};

const localDriver = {
  name: 'local',
  async put(key, body, _contentType) {
    const target = path.join(localDir(), key);
    await fsp.mkdir(path.dirname(target), { recursive: true });
    if (Buffer.isBuffer(body)) await fsp.writeFile(target, body);
    else await fsp.copyFile(body, target);
    const size = (await fsp.stat(target)).size;
    return { key, url: this.publicUrl(key), size };
  },
  async get(key) {
    return fsp.readFile(path.join(localDir(), key));
  },
  async remove(key) {
    await fsp.rm(path.join(localDir(), key), { force: true });
  },
  async exists(key) {
    return fs.existsSync(path.join(localDir(), key));
  },
  publicUrl(key) {
    return `file://${path.join(localDir(), key).split(path.sep).join('/')}`;
  },
};

function driver() {
  return driverName() === 'local' ? localDriver : s3Driver;
}

/** Download a stored object to a local file path. */
async function download(key, filePath) {
  const buf = await driver().get(key);
  await fsp.mkdir(path.dirname(filePath), { recursive: true });
  await fsp.writeFile(filePath, buf);
  return filePath;
}

module.exports = {
  put: (key, body, contentType) => driver().put(key, body, contentType),
  get: (key) => driver().get(key),
  remove: (key) => driver().remove(key),
  exists: (key) => driver().exists(key),
  publicUrl: (key) => driver().publicUrl(key),
  download,
  driverName,
};
