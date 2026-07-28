// Where the canonical_products/aliases table is missing coverage — read-only report
// over raw_prices, the log every /api/precos call already appends to.
//
// The canonical table only matters for the SEM-GTIN path (api/lib/canonical.js): meat,
// produce, bakery, deli — things sold loose, with no barcode to key on. So the question
// this answers is narrow and answerable from data we already hold: which barcode-less
// descriptions, in those categories, at how many markets, does lookupCanonical() fail to
// resolve today? That list, sorted by market reach, IS the seed backlog.
//
// Counting only. The judgment pass — which of these are the same fruit under a
// different regional name, which are a lanchonete's prepared food and never groceries —
// is `/db-review` (.claude/commands/db-review.md).
//
// Read-only: SELECT only, never writes. Run: npm run db:review -- [--json] [--limit=40]
import { neon } from '@neondatabase/serverless';
import { readFileSync } from 'fs';
import { norm } from '../../src/lib/text.js';
import { classify } from '../../src/lib/categoria.js';

// Same scope as api/lib/canonical.js — outside it, GTIN already handles identity and a
// canonical row would be dead weight.
const SCOPED = new Set(['carnes', 'frutas', 'verduras', 'padaria', 'laticinios']);
const args = process.argv.slice(2);
const asJson = args.includes('--json');
const LIMIT = Number((args.find((a) => a.startsWith('--limit=')) || '').split('=')[1]) || 30;

const env = readFileSync(new URL('../../.env.local', import.meta.url), 'utf8');
const dbUrl = (env.match(/^DATABASE_URL=(.*)$/m) || [])[1];
if (!dbUrl) {
  console.error('No DATABASE_URL in .env.local — see CLAUDE.md § Backend.');
  process.exit(1);
}
const sql = neon(dbUrl.trim().replace(/^"|"$/g, ''));

const brl = (c) => (c == null ? '—' : `R$ ${(c / 100).toFixed(2).replace('.', ',')}`);

// --- what the table knows today -------------------------------------------------
const aliasRows = await sql`
  SELECT a.raw_description, cp.id, cp.name, cp.unit_basis, cp.category
  FROM aliases a JOIN canonical_products cp ON cp.id = a.canonical_product_id`;
const aliases = aliasRows.map((r) => ({ ...r, tokens: r.raw_description.split(' ') }));

// Mirrors lookupCanonical(): token-set containment, most-specific (most tokens) wins.
function resolve(description, category) {
  if (!SCOPED.has(category)) return null;
  const toks = new Set(norm(description).split(' '));
  let best = null;
  for (const a of aliases) {
    if (a.category !== category) continue;
    if (a.tokens.every((t) => toks.has(t)) && (!best || a.tokens.length > best.tokens.length)) best = a;
  }
  return best;
}

// --- the barcode-less population the table is supposed to cover -------------------
// Modal NCM, never min(): the same description carries a different NCM at every store
// that typed it. "MEXERICA KG" alone spans 11 codes, two of them chapter 07 (lettuce)
// and one chapter 09 (coffee) — and classify() trusts NCM over keywords, so a single
// stray code flips the whole group's category and puts it outside canonical scope.
// api/precos.js already votes (representativeNcm); this has to vote too.
const rows = await sql`
  SELECT COALESCE(description_norm, description) AS key,
         min(description) AS sample,
         mode() WITHIN GROUP (ORDER BY ncm) AS ncm,
         count(DISTINCT left(ncm, 2))::int AS n_chapters,
         count(*)::int AS n_rows, count(DISTINCT market_codigo)::int AS n_markets,
         min(price_cents)::int AS min_c, max(price_cents)::int AS max_c,
         max(fetched_at) AS last_seen
  FROM raw_prices
  WHERE gtin IS NULL
  GROUP BY 1
  ORDER BY count(DISTINCT market_codigo) DESC`;

const scoped = rows
  .map((r) => ({ ...r, category: classify({ description: r.sample, ncm: r.ncm }) }))
  .filter((r) => SCOPED.has(r.category));

const uncovered = [];
const covered = new Map(); // canonical id -> what it already resolves
for (const r of scoped) {
  const hit = resolve(r.sample, r.category);
  if (hit) {
    if (!covered.has(hit.id)) covered.set(hit.id, { ...hit, rows: 0, markets: 0 });
    const c = covered.get(hit.id);
    c.rows += r.n_rows;
    c.markets += r.n_markets;
  } else {
    uncovered.push(r);
  }
}
const coverage = scoped.length ? Math.round(((scoped.length - uncovered.length) / scoped.length) * 100) : 0;

// --- over-reach: a loose-goods alias firing on a packaged product ------------------
// The canonical table exists for goods sold loose. A barcode means a package — so an
// alias resolving a GTIN-bearing description is, by construction, the wrong kind of
// match: "MOLHO TOM POMODORO 300G" contains the token TOMATE and therefore resolves to
// the canonical Tomate [KG]. candidatesFor then does `want = canonical.tokens`, so the
// search key becomes bare TOMATE and every discriminating word is thrown away.
const packaged = await sql`
  SELECT min(description) AS description, min(gtin) AS gtin,
         mode() WITHIN GROUP (ORDER BY ncm) AS ncm,
         count(DISTINCT market_codigo)::int AS n_markets
  FROM raw_prices WHERE gtin IS NOT NULL
  GROUP BY COALESCE(description_norm, description)`;

const overReach = [];
for (const p of packaged) {
  const cat = classify({ description: p.description, ncm: p.ncm });
  const hit = resolve(p.description, cat);
  if (hit) overReach.push({ canonical: hit.name, basis: hit.unit_basis, category: cat, n_markets: p.n_markets, description: p.description });
}
overReach.sort((a, b) => b.n_markets - a.n_markets);

// --- unit_basis sanity ------------------------------------------------------------
// A canonical claiming KG whose real offers are all priced per package (or vice versa)
// sends the whole search down the wrong basis — the one canonical field that can make
// matching worse rather than merely absent.
const basisCheck = [];
for (const c of covered.values()) {
  const obs = scoped.filter((r) => resolve(r.sample, r.category)?.id === c.id);
  const kg = obs.filter((r) => /\bKG\b/.test(norm(r.sample))).length;
  const un = obs.filter((r) => /\b(UN|UND|UNIDADE)\b/.test(norm(r.sample))).length;
  if (!kg && !un) continue;
  const observed = kg > un ? 'KG' : 'UN';
  if (observed !== c.unit_basis) basisCheck.push({ name: c.name, declared: c.unit_basis, observed, kg, un });
}

// --- aliases that have never fired --------------------------------------------------
const usedIds = new Set(covered.keys());
const deadCanonicals = [...new Map(aliases.map((a) => [a.id, a])).values()]
  .filter((c) => !usedIds.has(c.id))
  .map((c) => ({ id: c.id, name: c.name, category: c.category }));

// --- NCM that disagrees with the words ---------------------------------------------
// classify() prefers NCM as "deterministic". It is deterministic per row, not correct:
// these are descriptions whose modal NCM chapter and whose keyword reading point at
// different categories. Each one is a product silently outside canonical scope.
const ncmConflicts = rows
  .filter((r) => r.ncm)
  .map((r) => ({
    description: r.sample, ncm: r.ncm, n_chapters: r.n_chapters, n_markets: r.n_markets,
    byNcm: classify({ description: r.sample, ncm: r.ncm }),
    byWord: classify({ description: r.sample }),
  }))
  .filter((r) => r.byNcm !== r.byWord && (SCOPED.has(r.byWord) || SCOPED.has(r.byNcm)))
  .sort((a, b) => b.n_markets - a.n_markets);

const report = {
  snapshot: {
    coveragePct: coverage,
    scopedGroups: scoped.length,
    unresolved: uncovered.length,
    canonicals: new Set(aliases.map((a) => a.id)).size,
    aliases: aliases.length,
  },
  uncovered: uncovered.slice(0, LIMIT),
  overReach: overReach.slice(0, LIMIT),
  ncmConflicts: ncmConflicts.slice(0, LIMIT),
  basisCheck,
  deadCanonicals,
};

if (asJson) {
  console.log(JSON.stringify(report, null, 1));
} else {
  const s = report.snapshot;
  console.log(`\ncanonical coverage — ${s.coveragePct}% (${s.scopedGroups - s.unresolved}/${s.scopedGroups} barcode-less descriptions in scope)`);
  console.log(`${s.canonicals} canonical products / ${s.aliases} aliases\n`);

  console.log(`── unresolved, by reach ${'─'.repeat(46)}`);
  console.log('mkts  rows  category    price range        description');
  for (const r of report.uncovered) {
    console.log(
      `${String(r.n_markets).padStart(4)}  ${String(r.n_rows).padStart(4)}  ${r.category.padEnd(10)}  ` +
      `${(brl(r.min_c) + '–' + brl(r.max_c)).padEnd(18)}  ${r.sample}`);
  }

  if (report.overReach.length) {
    console.log(`\n── over-reach: loose-goods alias hitting a packaged product ${'─'.repeat(10)}`);
    console.log(`${overReach.length} total; a barcode means a package, so every line here is a wrong match`);
    for (const c of report.overReach) {
      console.log(`${String(c.n_markets).padStart(4)} mkts  ${(c.canonical + ' [' + c.basis + ']').padEnd(22)} ← ${c.description}`);
    }
  }
  if (report.ncmConflicts.length) {
    console.log(`\n── NCM chapter disagrees with the description ${'─'.repeat(24)}`);
    console.log(`${ncmConflicts.length} total; classify() takes the NCM, so these sit outside canonical scope`);
    for (const c of report.ncmConflicts) {
      console.log(`${String(c.n_markets).padStart(4)} mkts  ncm ${c.ncm} → ${c.byNcm.padEnd(11)} words → ${c.byWord.padEnd(11)} ${c.n_chapters > 1 ? `(${c.n_chapters} chapters seen) ` : ''}${c.description}`);
    }
  }
  if (basisCheck.length) {
    console.log(`\n── unit_basis disagrees with the offers ${'─'.repeat(30)}`);
    for (const b of basisCheck) console.log(`  ${b.name.padEnd(20)} declared ${b.declared}, offers say ${b.observed} (kg:${b.kg} un:${b.un})`);
  }
  if (deadCanonicals.length) {
    console.log(`\n── never matched anything yet (${deadCanonicals.length}) ${'─'.repeat(24)}`);
    console.log('  ' + deadCanonicals.map((c) => c.name).join(', '));
  }
  console.log('');
}
