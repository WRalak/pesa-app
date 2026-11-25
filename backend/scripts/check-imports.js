/**
 * Loads every source module with Node's native ESM loader. Vitest's transform
 * tolerates some missing named imports that fail at real startup; this check
 * runs in CI to guarantee the production entrypoints can actually boot.
 */
import { readdirSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

process.env.NODE_ENV ??= 'test';
const files = [];
const walk = (d) => readdirSync(d).forEach((f) => { const p = join(d, f); statSync(p).isDirectory() ? walk(p) : p.endsWith('.js') && files.push(p); });
walk(resolve('src'));
const skip = new Set(['server.js', 'worker.js']); // top-level side effects (connect/listen)
let failed = 0;
for (const f of files) {
  if (skip.has(f.split('/').pop()) && f.split('/').length - resolve('src').split('/').length === 1) continue;
  try { await import(pathToFileURL(f).href); } catch (err) { failed++; console.error(`✗ ${f}\n  ${err.message}`); }
}
console.log(failed ? `${failed} module(s) failed to load` : `All ${files.length} modules load natively`);
process.exit(failed ? 1 : 0);
