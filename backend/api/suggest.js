import { neon } from '@neondatabase/serverless';
import { databaseUrl } from './lib/db.js';
import { norm } from '../src/lib/text.js';
import { applyCors } from './lib/cors.js';

// Autocomplete for the scan chooser's "buscar por nome" field. Suggestions come only
// from our own persisted catalog (raw_prices, Layer 1 — the same table api/catalog.js
// browses), never straight from a live Menor Preço hit: typing "cafe" mid-keystroke
// must not fire a termo= search per keystroke against the upstream source.
const FRESHNESS_DAYS = 45; // matches api/lib/catalog.js's browsing window
const LIMIT = 8;

// GET /api/suggest?q=<prefix> -> { items: string[] }. Grouped by normalized description
// so store-text variants of the same product ("REF COCA COLA 350ML" vs "COCA COLA LATA
// 350ML") collapse into one suggestion — the most common variant's own text, ranked by
// how many stored offers back it (a real, seen product beats a rare mis-scanned one).
export default async function handler(req, res) {
  if (applyCors(req, res)) return;
  const term = norm((req.query && req.query.q) || '');
  if (term.length < 2) return res.status(200).json({ items: [] });
  const url = databaseUrl();
  if (!url) return res.status(200).json({ items: [] });
  try {
    const sql = neon(url);
    const rows = await sql`
      WITH matches AS (
        SELECT description, description_norm,
               COUNT(*) OVER (PARTITION BY description_norm) AS group_n,
               COUNT(*) OVER (PARTITION BY description_norm, description) AS desc_n
        FROM raw_prices
        -- word-boundary, not whole-string prefix: store text often leads with packaging/qty
        -- ("1KG ARROZ...", "PCT FEIJAO...") so the item name itself isn't the first token.
        WHERE description_norm ~ ${'(^|\\s)' + term}
          AND fetched_at > now() - make_interval(days => ${FRESHNESS_DAYS})
      ),
      best AS (
        SELECT DISTINCT ON (description_norm) description_norm, description, group_n
        FROM matches
        ORDER BY description_norm, desc_n DESC
      )
      SELECT description FROM best ORDER BY group_n DESC LIMIT ${LIMIT}
    `;
    return res.status(200).json({ items: rows.map((r) => r.description) });
  } catch (e) {
    return res.status(502).json({ error: 'suggest_failed', detail: String(e && e.message) });
  }
}
