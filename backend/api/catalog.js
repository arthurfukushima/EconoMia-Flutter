import { getMarketCatalog } from './lib/catalog.js';
import { classify } from '../src/lib/categoria.js';
import { cheapnessScore } from '../src/lib/catalogScore.js';
import { applyCors } from './lib/cors.js';

// Browse everything cached for one market (raw_prices, Layer 1), each product scored
// against the same product's price at every other market nearby. GET
// /api/catalog?market_codigo=X[&category=carnes].
export default async function handler(req, res) {
  if (applyCors(req, res)) return;
  const marketCodigo = req.query && req.query.market_codigo;
  if (!marketCodigo) return res.status(400).json({ error: 'missing_market_codigo' });
  const wantCategory = (req.query && req.query.category) || null;
  try {
    const rows = await getMarketCatalog(marketCodigo);
    const items = rows.map((r) => ({
      ...r,
      category: classify({ description: r.description, ncm: r.ncm }),
      ...cheapnessScore(r.priceCents, r.minCents, r.maxCents, r.nStores),
    }));
    const categories = {};
    for (const it of items) categories[it.category] = (categories[it.category] || 0) + 1;
    const filtered = wantCategory ? items.filter((it) => it.category === wantCategory) : items;
    return res.status(200).json({ marketCodigo, items: filtered, categories });
  } catch (e) {
    return res.status(502).json({ error: 'catalog_failed', detail: String(e && e.message) });
  }
}
