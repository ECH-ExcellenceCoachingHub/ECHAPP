#!/usr/bin/env node
/**
 * Downloads CC0 (public domain) PBR texture sets from ambientCG for the ECH Labs rooms and
 * unpacks them into labs-unity/Assets/ECHLabs/Art/Downloaded/<Set>/ .
 * MaterialLibrary.ApplyDownloadedTextures() then wires them into the URP materials.
 *
 *   node tools/asset-pipeline/fetch-cc0.mjs            (1K textures — mobile friendly)
 *   node tools/asset-pipeline/fetch-cc0.mjs --res 2K   (desktop / Ultra)
 *
 * Licence: ambientCG assets are CC0 1.0 — free for commercial use, no attribution required.
 */
import { mkdir, writeFile, rm, readdir, rename } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.resolve(here, '../../labs-unity/Assets/ECHLabs/Art/Downloaded');
const res = (process.argv.includes('--res') ? process.argv[process.argv.indexOf('--res') + 1] : '1K').toUpperCase();
const UA = 'ECH-Labs-asset-pipeline/1.0';

// Set name → ambientCG search query (first good match is used).
const SETS = {
  Terrazzo: 'terrazzo',
  Plaster: 'plaster',
  Wood: 'wood light',
  Epoxy: 'plastic black',
};

async function search(q) {
  const url = `https://ambientcg.com/api/v2/full_json?type=Material&q=${encodeURIComponent(q)}&limit=5&include=downloadData&sort=Popular`;
  const r = await fetch(url, { headers: { 'User-Agent': UA } });
  if (!r.ok) throw new Error(`search ${q}: HTTP ${r.status}`);
  const j = await r.json();
  for (const asset of j.foundAssets || []) {
    const downloads = asset.downloadFolders?.default?.downloadFiletypeCategories?.zip?.downloads || [];
    const want = downloads.find((d) => d.attribute === `${res}-JPG`) || downloads.find((d) => d.attribute?.endsWith('-JPG'));
    if (want) return { id: asset.assetId, url: want.fullDownloadPath || want.downloadLink, size: want.size };
  }
  throw new Error(`no ${res} JPG download found for "${q}"`);
}

async function fetchSet(name, q) {
  const dir = path.join(OUT, name);
  if (existsSync(dir) && (await readdir(dir)).some((f) => f.endsWith('.jpg'))) {
    console.log(`✓ ${name} already present`);
    return;
  }
  const hit = await search(q);
  console.log(`↓ ${name}: ${hit.id} (${res}, ${Math.round((hit.size || 0) / 1024 / 1024)} MB)`);
  const r = await fetch(hit.url, { headers: { 'User-Agent': UA } });
  if (!r.ok) throw new Error(`download ${hit.id}: HTTP ${r.status}`);
  await mkdir(dir, { recursive: true });
  const zip = path.join(dir, `${hit.id}.zip`);
  await writeFile(zip, Buffer.from(await r.arrayBuffer()));
  // tar (bsdtar) ships with Windows 10+, macOS and Linux and extracts zip files.
  execFileSync('tar', ['-xf', zip, '-C', dir]);
  await rm(zip);
  // Keep only colour / normal / roughness / AO maps; name them predictably.
  for (const f of await readdir(dir)) {
    const lower = f.toLowerCase();
    if (!lower.endsWith('.jpg')) { await rm(path.join(dir, f), { recursive: true, force: true }); continue; }
    if (/displacement|_disp/.test(lower)) await rm(path.join(dir, f));
    else if (lower.includes('normaldx')) await rm(path.join(dir, f)); // Unity uses OpenGL normals
  }
  await writeFile(path.join(dir, 'SOURCE.txt'), `ambientCG ${hit.id} — CC0 1.0 (https://ambientcg.com/view?id=${hit.id})\n`);
}

await mkdir(OUT, { recursive: true });
let failed = 0;
for (const [name, q] of Object.entries(SETS)) {
  try { await fetchSet(name, q); } catch (e) { failed++; console.warn(`✗ ${name}: ${e.message}`); }
}
console.log(failed ? `Done with ${failed} failure(s) — rooms still build with flat PBR colours.` : 'All texture sets ready.');
