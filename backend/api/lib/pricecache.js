// Daily cache for Menor Preço lookups — one upstream call per (item, area, radius) per
// calendar day. Best-effort like the other api/lib/* DB helpers: any failure here just
// falls through to a live fetch, it never breaks the price response.
import { neon } from '@neondatabase/serverless';
import { norm } from '../../src/lib/text.js';
import { databaseUrl } from './db.js';

export function cacheKeyFor(gtin, termo) {
  return gtin || norm(termo || '');
}

// ~1km precision — near-identical requests (same user, same neighborhood) share a hit
// without demanding exact float equality on GPS coordinates.
export function localBucket(local) {
  const [lat, lng] = String(local || '').split(',').map(Number);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return String(local || '');
  return `${lat.toFixed(2)},${lng.toFixed(2)}`;
}

export async function getCachedProdutos(cacheKey, local, raio) {
  if (!cacheKey) return null;
  const url = databaseUrl();
  if (!url) return null;
  try {
    const sql = neon(url);
    const rows = await sql`
      SELECT produtos FROM price_query_cache
      WHERE cache_key = ${cacheKey} AND local_bucket = ${localBucket(local)} AND raio = ${raio} AND cached_date = CURRENT_DATE
    `;
    return rows[0] ? rows[0].produtos : null;
  } catch {
    return null;
  }
}

export async function setCachedProdutos(cacheKey, local, raio, produtos) {
  if (!cacheKey) return;
  const url = databaseUrl();
  if (!url) return;
  try {
    const sql = neon(url);
    await sql`
      INSERT INTO price_query_cache (cache_key, local_bucket, raio, cached_date, produtos)
      VALUES (${cacheKey}, ${localBucket(local)}, ${raio}, CURRENT_DATE, ${JSON.stringify(produtos)}::jsonb)
      ON CONFLICT (cache_key, local_bucket, raio, cached_date)
      DO UPDATE SET produtos = EXCLUDED.produtos, fetched_at = now()
    `;
  } catch {
    // best-effort — a cache-write failure must not affect the response already sent
  }
}
