-- Canonical product normalization for SEM-GTIN matching (meat + produce only).
-- Scope + rationale: Docs/04_Technical_Architecture.md ("Normalization layer").
-- Descriptions are matched in normalized form (src/lib/text.js norm()) before lookup.

CREATE TABLE IF NOT EXISTS canonical_products (
  id SERIAL PRIMARY KEY,
  category TEXT NOT NULL,              -- matches src/lib/categoria.js: carnes | frutas | verduras
  name TEXT NOT NULL,
  unit_basis TEXT NOT NULL CHECK (unit_basis IN ('KG', 'UN')),
  brand TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (category, name)
);

CREATE INDEX IF NOT EXISTS idx_canonical_products_category ON canonical_products (category);

CREATE TABLE IF NOT EXISTS aliases (
  id SERIAL PRIMARY KEY,
  canonical_product_id INTEGER NOT NULL REFERENCES canonical_products(id) ON DELETE CASCADE,
  raw_description TEXT NOT NULL UNIQUE,  -- normalized form (norm()), e.g. "PICANHA BOV"
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_aliases_raw_description ON aliases (raw_description);

-- Layer 1 (Source layer / RawPrice) — the cheap slice: persist what we already fetch
-- from Menor Preço on every /api/precos call instead of discarding it. Append-only log,
-- not an upsert table — the point is a price history over time. Nota Paraná (Menor
-- Preço) is the one source wired up. The `source` column exists so other sources can
-- append later without a schema change. See Docs/13_Market_Discovery.md sibling reasoning + the
-- Layer 1 sizing discussion in conversation (04_Technical_Architecture.md target schema).
CREATE TABLE IF NOT EXISTS raw_prices (
  id BIGSERIAL PRIMARY KEY,
  source TEXT NOT NULL DEFAULT 'menorpreco',
  gtin TEXT,
  description TEXT NOT NULL,
  ncm TEXT,
  price_cents INTEGER NOT NULL,
  market_codigo TEXT,
  market_name TEXT,
  municipio TEXT,
  uf TEXT,
  observed_at TIMESTAMPTZ,          -- Menor Preço's own `datahora` (when that price was captured upstream)
  fetched_at TIMESTAMPTZ NOT NULL DEFAULT now(),  -- when we pulled it
  UNIQUE (market_codigo, description, price_cents, observed_at)
);

-- description_norm (src/lib/text.js norm(), computed at insert time in
-- api/lib/rawprices.js) is the catalog grouping fallback key when gtin is absent —
-- the raw `description` column is store-reported text and varies (case, punctuation,
-- accents) enough between offers of the same product to split them into separate
-- catalog cards (api/lib/catalog.js). Nullable + backfilled lazily: added after
-- raw_prices already existed in production, old rows just fall back to raw
-- `description` in the catalog query until they age out of the 45-day freshness window.
ALTER TABLE raw_prices ADD COLUMN IF NOT EXISTS description_norm TEXT;

CREATE INDEX IF NOT EXISTS idx_raw_prices_gtin ON raw_prices (gtin);
CREATE INDEX IF NOT EXISTS idx_raw_prices_fetched_at ON raw_prices (fetched_at);
CREATE INDEX IF NOT EXISTS idx_raw_prices_description_norm ON raw_prices (description_norm);

-- Catalog browse (api/lib/catalog.js): "everything cached for market X" scans by
-- market_codigo ordered by recency; the region price-range comparison scans by
-- uf+municipio ordered by recency. Both feed a DISTINCT ON (...) ORDER BY ... fetched_at DESC.
CREATE INDEX IF NOT EXISTS idx_raw_prices_market_fetched ON raw_prices (market_codigo, fetched_at DESC);
CREATE INDEX IF NOT EXISTS idx_raw_prices_region_fetched ON raw_prices (uf, municipio, fetched_at DESC);

-- Daily query cache: one Menor Preço call per (item, area, radius) per day, so repeat
-- lookups (same receipt re-opened, same item scanned again) don't re-hit the upstream
-- API. Stores the raw `produtos` payload verbatim so it can feed analyzeItem/
-- selectCheapest exactly as a live response would. cached_date is a Postgres
-- CURRENT_DATE (server clock) so freshness isn't at the mercy of client clock skew.
CREATE TABLE IF NOT EXISTS price_query_cache (
  cache_key TEXT NOT NULL,        -- gtin, or norm(termo) for a description search
  local_bucket TEXT NOT NULL,     -- lat/lon rounded to ~1km so near-identical requests share a hit
  raio INTEGER NOT NULL,
  cached_date DATE NOT NULL,
  produtos JSONB NOT NULL,
  fetched_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (cache_key, local_bucket, raio, cached_date)
);
