// Layer 1 (Source layer / RawPrice): persist every Menor Preço offer we already fetch,
// not just the ones that end up matching a receipt item — this is the whole point,
// otherwise every call still throws away data we paid the request cost for.
// Append-only log (price history), server-only, best-effort: a failure here must
// never affect the actual price response — same posture as api/lib/canonical.js.
import { neon } from '@neondatabase/serverless';
import { reaisToCents } from '../../src/lib/money.js';
import { norm, g14 } from '../../src/lib/text.js';
import { databaseUrl } from './db.js';

export async function persistRawPrices(produtos, source = 'menorpreco') {
  if (!produtos || !produtos.length) return;
  const url = databaseUrl();
  if (!url) return;
  try {
    const sql = neon(url);
    const rows = produtos
      .map((p) => {
        const priceCents = reaisToCents(p.valor);
        if (!priceCents || priceCents <= 0) return null;
        const e = p.estabelecimento || {};
        const description = (p.desc || '').trim();
        return {
          source,
          // g14-normalized (13 vs 14 digits w/ leading zeros must key together — see
          // api/precos.js) and description_norm (src/lib/text.js norm()) so the same
          // physical product doesn't split into duplicate catalog rows when one offer
          // is missing its gtin or a store's description text has trivial noise.
          gtin: g14(p.gtin),
          description,
          descriptionNorm: norm(description) || null,
          ncm: p.ncm || null,
          priceCents,
          marketCodigo: e.codigo || null,
          marketName: e.nm_fan || e.nm_emp || null,
          municipio: e.mun || null,
          uf: e.uf || null,
          observedAt: p.datahora || null,
        };
      })
      .filter((r) => r && r.description);
    if (!rows.length) return;

    // One INSERT, multiple VALUES rows — the http driver has no multi-statement/batch
    // helper, so build placeholders by hand ($1..$9, $10..$18, ...) with a flat params array.
    const cols = ['source', 'gtin', 'description', 'description_norm', 'ncm', 'price_cents', 'market_codigo', 'market_name', 'municipio', 'uf', 'observed_at'];
    const params = [];
    const tuples = rows.map((r, i) => {
      const base = i * cols.length;
      params.push(r.source, r.gtin, r.description, r.descriptionNorm, r.ncm, r.priceCents, r.marketCodigo, r.marketName, r.municipio, r.uf, r.observedAt);
      return `(${cols.map((_, j) => `$${base + j + 1}`).join(', ')})`;
    });
    const text = `
      INSERT INTO raw_prices (${cols.join(', ')})
      VALUES ${tuples.join(', ')}
      ON CONFLICT (market_codigo, description, price_cents, observed_at) DO NOTHING
    `;
    await sql.query(text, params);
  } catch {
    // best-effort — Menor Preço being slow/flaky must never break the price response
  }
}
