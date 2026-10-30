/**
 * Shared test setup: isolated environment + in-memory MongoDB.
 * Never touches the production database, S3 bucket or paid AI providers.
 */
const fs = require('fs');
const os = require('os');
const path = require('path');

for (const k of ['MONGODB_URI', 'GROQ_API_KEY', 'ELEVENLABS_API_KEY', 'GEMINI_API_KEY', 'AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY', 'S3_BUCKET_NAME', 'PEXELS_API_KEY', 'PIXABAY_API_KEY', 'YOUTUBE_DATA_API_V3_KEY', 'YOUTUBE_API_KEY']) {
  delete process.env[k];
}
const TMP = fs.mkdtempSync(path.join(os.tmpdir(), 'ech-test-'));
Object.assign(process.env, {
  NODE_ENV: 'test',
  MEDIA_STORAGE_DRIVER: 'local',
  MEDIA_LOCAL_DIR: path.join(TMP, 'media'),
  VIDEO_TTS_PROVIDER: 'silent',
  VIDEO_ALLOW_SILENT: 'true',
  FIGURE_WAIT_SECONDS: '0',
  VIDEO_STOCK_MEDIA: 'false', // no network in tests; stock media is tested with mocked providers
  VIDEO_STOCK_USER_AGENT: 'ECH-tests',
  VIDEO_STOCK_MIN_INTERVAL_MS: '0',
  VIDEO_STOCK_BUSY_RETRY_MS: '0',
  JOB_BACKOFF_BASE_MS: '50',
  JOB_BACKOFF_MAX_MS: '200',
});
const venvPython = path.join(__dirname, '..', '..', 'python', '.venv', process.platform === 'win32' ? 'Scripts/python.exe' : 'bin/python');
if (!process.env.PYTHON_BIN && fs.existsSync(venvPython)) process.env.PYTHON_BIN = venvPython;

const mongoose = require('mongoose');
let server = null;

async function startDb() {
  const { MongoMemoryServer } = require('mongodb-memory-server');
  server = await MongoMemoryServer.create();
  await mongoose.connect(server.getUri(), { dbName: 'ech_test' });
  // Unique indexes must exist for duplicate-prevention tests.
  for (const name of ['GenerationJob', 'FigureAsset', 'FigureExtraction']) {
    await require(`../../src/models/${name}`).syncIndexes();
  }
}

async function stopDb() {
  await mongoose.disconnect();
  if (server) await server.stop();
  fs.rmSync(TMP, { recursive: true, force: true });
}

async function clearDb() {
  const cols = await mongoose.connection.db.collections();
  await Promise.all(cols.map(c => c.deleteMany({})));
}

function oid() {
  return new mongoose.Types.ObjectId();
}

function silenceLogs() {
  const orig = { log: console.log, info: console.info, warn: console.warn };
  console.log = () => {};
  console.info = () => {};
  console.warn = () => {};
  return () => Object.assign(console, orig);
}

module.exports = { startDb, stopDb, clearDb, oid, TMP, silenceLogs, mongoose };
