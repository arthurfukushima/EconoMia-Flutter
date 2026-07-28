// Read path for raw_prices (Layer 1) — first reader of the append-only log persisted
// by api/lib/rawprices.js on every /api/precos call. Unlike the other api/lib/*
// helpers (best-effort, swallow-on-failure — a lookup that quietly returns nothing),
// this one is the screen's actual data source: a query failure propagates so the
// handler can 502 instead of silently rendering "mercado vazio".
import { neon } from '@neondatabase/serverless';
import { databaseUrl } from './db.js';

// How far back a price still counts as "current" for browsing/comparison. Longer
// than price_query_cache's 1-day TTL on purpose — a market's shelf doesn't turn
// over daily, and a tighter window would starve low-traffic markets of any catalog.
const FRESHNESS_DAYS = 45;

// One product's latest cached price at `marketCodigo`, plus how it stacks up against
// the same product's latest price at every other market in the same município/UF:
// { gtin, description, ncm, priceCents, fetchedAt, minCents, maxCents, nStores, rank }.
// "Same product" = same GTIN when present, else normalized (src/lib/text.js norm())
// store-reported description — no cross-store fuzzy matching here, that's
// api/precos.js's job for a single scanned item.
export async function getMarketCatalog(marketCodigo) {
  if (!marketCodigo) return [];
  const url = databaseUrl();
  if (!url) return [];
  const sql = neon(url);
  const rows = await sql`
    WITH mkt AS (
      SELECT municipio, uf FROM raw_prices
      WHERE market_codigo = ${marketCodigo}
      ORDER BY fetched_at DESC LIMIT 1
    ),
    latest AS (
      SELECT DISTINCT ON (COALESCE(rp.gtin, rp.description_norm, rp.description), rp.market_codigo)
        rp.gtin, rp.description, COALESCE(rp.gtin, rp.description_norm, rp.description) AS key,
        rp.ncm, rp.price_cents, rp.market_codigo, rp.fetched_at
      FROM raw_prices rp, mkt
      WHERE rp.uf = mkt.uf AND rp.municipio = mkt.municipio
        AND rp.fetched_at > now() - make_interval(days => ${FRESHNESS_DAYS})
      ORDER BY COALESCE(rp.gtin, rp.description_norm, rp.description), rp.market_codigo, rp.fetched_at DESC
    ),
    region AS (
      SELECT key, MIN(price_cents) AS min_cents, MAX(price_cents) AS max_cents,
             COUNT(DISTINCT market_codigo) AS n_stores
      FROM latest GROUP BY key
    ),
    ranked AS (
      SELECT key, market_codigo,
             RANK() OVER (PARTITION BY key ORDER BY price_cents ASC) AS rnk
      FROM latest
    )
    SELECT l.gtin, l.description, l.ncm, l.price_cents, l.fetched_at,
           r.min_cents, r.max_cents, r.n_stores, k.rnk
    FROM latest l
    JOIN region r ON r.key = l.key
    JOIN ranked k ON k.key = l.key AND k.market_codigo = l.market_codigo
    WHERE l.market_codigo = ${marketCodigo}
    ORDER BY l.description
  `;
  return rows.map((r) => ({
    gtin: r.gtin,
    description: r.description,
    ncm: r.ncm,
    priceCents: r.price_cents,
    fetchedAt: r.fetched_at,
    minCents: r.min_cents,
    maxCents: r.max_cents,
    nStores: Number(r.n_stores), // Postgres COUNT/RANK come back as strings over the http driver
    rank: Number(r.rnk),
  }));
}
