// Canonical-product lookup, scoped to categories that are commonly sold loose/by
// weight with no GTIN: meat, produce, bakery-counter, deli-counter cheese. Packaged
// goods (bebidas/doces/limpeza/packaged laticinios) almost always carry a real
// barcode already — GTIN handles those, canonical lookup never needs to fire for
// them. See db/schema.sql, db/seed.mjs.
// Server-only: lives under api/ so Vite never bundles it into the client PWA, and the
// DB connection string never leaves this process. Degrades to null on any failure —
// this is a matching enhancement, not a hard dependency (same posture as Menor Preço).
import { neon } from '@neondatabase/serverless';
import { norm } from '../../src/lib/text.js';
import { databaseUrl } from './db.js';

const SCOPED_CATEGORIES = new Set(['carnes', 'frutas', 'verduras', 'padaria', 'laticinios']);

let cache = null; // alias rows: tiny (~90), cached module-wide across warm invocations
async function allAliases(sql) {
  if (!cache) {
    const rows = await sql`
      SELECT a.raw_description, cp.name, cp.unit_basis, cp.category
      FROM aliases a JOIN canonical_products cp ON cp.id = a.canonical_product_id
    `;
    cache = rows.map((r) => ({ tokens: r.raw_description.split(' '), name: r.name, unit_basis: r.unit_basis, category: r.category }));
  }
  return cache;
}

// Most-specific alias (most tokens) whose full token set is contained in the
// description — token-set containment, not substring, so e.g. "COXA" never
// false-matches "COXAO" (distinct whole-word tokens).
export async function lookupCanonical(description, category) {
  if (!SCOPED_CATEGORIES.has(category)) return null;
  const url = databaseUrl();
  if (!url) return null;
  try {
    const sql = neon(url);
    const toks = new Set(norm(description).split(' '));
    const rows = await allAliases(sql);
    let best = null;
    for (const r of rows) {
      if (r.category !== category) continue;
      if (r.tokens.every((t) => toks.has(t)) && (!best || r.tokens.length > best.tokens.length)) best = r;
    }
    return best ? { name: best.name, unit_basis: best.unit_basis, tokens: best.tokens } : null;
  } catch {
    return null;
  }
}
