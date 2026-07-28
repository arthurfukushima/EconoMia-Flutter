# Probes that work

Connect the way `backend/tool/db/canonical-gaps.mjs` does — `neon(DATABASE_URL)` read from
`.env.local`, no extra deps. Keep throwaway probes out of the repo, or extend the
script. Never commit a probe with its output baked in.

Postgres note: `mode() WITHIN GROUP (ORDER BY x)` cannot take an `OVER` clause —
aggregate it in a `GROUP BY` subquery instead.

## Schema, in one screen

| table | rows | what it is |
|---|---|---|
| `raw_prices` | ~5k, growing | append-only offer log. One row = one price at one market at one moment. Unique on `(market_codigo, description, price_cents, observed_at)`. |
| `canonical_products` | 81 | hand-curated identity for goods sold loose. `unit_basis` is `KG` or `UN`. |
| `aliases` | 106 | normalized spellings → canonical. `raw_description` is `norm()`ed, matched by token-set containment. |
| `price_query_cache` | ~220 | one upstream call per (term, ~1km bucket, radius, day). `produtos` is the raw payload. |

Grouping keys, in the order the code tries them:

1. `gtin` — `g14()`-normalized, on ~71% of rows. Trusted absolutely.
2. `productSignature(desc)` — search-time only (`backend/src/lib/match.js`), not in SQL.
3. `description_norm` — `norm()` at insert time; the catalog's SQL fallback.
   **766 old rows are NULL here** and fall back to raw `description`.
4. `canonical_products` + `aliases` — meat, produce, bakery, deli only.

`backend/api/lib/catalog.js` groups on `COALESCE(gtin, description_norm, description)`;
`backend/api/precos.js` groups on `g14(gtin) || productSignature(desc)`. **The two do not
agree** — that divergence is the root of several findings.

## Product identity

```sql
-- One barcode, many spellings — the free labelled-synonym source
SELECT gtin, count(DISTINCT description) AS spellings,
       count(DISTINCT market_codigo) AS mkts, array_agg(DISTINCT description)
FROM raw_prices WHERE gtin IS NOT NULL
GROUP BY 1 HAVING count(DISTINCT description) > 1
ORDER BY 2 DESC;

-- One spelling, many barcodes — flavours the description never names
SELECT description_norm, count(DISTINCT gtin) AS gtins, count(*) AS rows
FROM raw_prices WHERE gtin IS NOT NULL AND description_norm IS NOT NULL
GROUP BY 1 HAVING count(DISTINCT gtin) > 1 ORDER BY 2 DESC;

-- Split risk: same text appears both with and without a barcode, so the catalog
-- keys it two ways and halves n_stores
SELECT description_norm,
       count(*) FILTER (WHERE gtin IS NOT NULL) AS with_gtin,
       count(*) FILTER (WHERE gtin IS NULL)     AS without_gtin
FROM raw_prices WHERE description_norm IS NOT NULL
GROUP BY 1 HAVING count(*) FILTER (WHERE gtin IS NOT NULL) > 0
              AND count(*) FILTER (WHERE gtin IS NULL) > 0
ORDER BY 2 + 3 DESC;
```

## Price sanity

```sql
-- Suspicious spread inside one barcode: mixed sizes, or two products sharing a code
SELECT gtin, count(*) AS n, min(price_cents), max(price_cents),
       round(max(price_cents)::numeric / nullif(min(price_cents), 0), 1) AS ratio,
       array_agg(DISTINCT description)
FROM raw_prices WHERE gtin IS NOT NULL
GROUP BY 1 HAVING count(*) >= 8 AND max(price_cents) > 3 * min(price_cents)
ORDER BY 5 DESC;
```

`trimOutliers` only drops the low tail (below 40% of median, 4+ offers). Nothing
guards the high end, and `maxCents` is the denominator of the catalog's cheapness
percentage — so one high outlier makes every store look *ótimo*.

## Categories and NCM

```sql
-- How many NCM chapters one description spans. "MEXERICA KG" spans 11 codes,
-- including 07 (lettuce) and 09 (coffee).
SELECT COALESCE(description_norm, description) AS key,
       count(DISTINCT left(ncm, 2)) AS chapters, count(*) AS rows
FROM raw_prices WHERE ncm IS NOT NULL
GROUP BY 1 HAVING count(DISTINCT left(ncm, 2)) > 1 ORDER BY 2 DESC;
```

`classify()` (`backend/src/lib/categoria.js`) takes NCM over keywords whenever the code has
4+ digits. Chapter map: 02/03 carnes · 04 laticinios · 07 verduras · 08 frutas ·
17/18 doces · 19 padaria · 22 bebidas · 34 limpeza. Category scopes the canonical
lookup, so a wrong NCM silently removes a product from the table's reach.

## Markets and freshness

```sql
SELECT market_codigo, min(market_name) AS name, municipio,
       count(*) AS offers, max(fetched_at) AS last_seen
FROM raw_prices GROUP BY 1, 3 ORDER BY 4 DESC LIMIT 30;
```

Catalog freshness window is 45 days (`backend/api/lib/catalog.js`), deliberately longer than
the 1-day query cache. A market whose newest row is older than that has no catalog at
all. Some `market_codigo`s belong to bars and lanchonetes rather than supermarkets —
their descriptions are prepared food and pollute every text-based grouping pass.

## Before believing a result

- Every row must be `uf = 'PR'`. Anything else means decoy data got past
  `isPlausiblePR` — treat the whole batch as suspect.
- `price_cents` is integer cents everywhere. Under ~50 for a packaged good is
  usually a per-unit price on a per-kg product, not a bargain.
- `observed_at` (upstream sale time) and `fetched_at` (when we pulled it) are
  different clocks. Trend work uses `observed_at`; freshness uses `fetched_at`.
