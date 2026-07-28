import { reaisToCents } from '../src/lib/money.js';
import { norm, distinctiveStoreTokens, g14 } from '../src/lib/text.js';
import { classify } from '../src/lib/categoria.js';
import {
  significantTokens, parseSize, sizesOverlap, hasClassBlock, hasNewVariant,
  scoreOffer, productSignature,
} from '../src/lib/match.js';
import { lookupCanonical } from './lib/canonical.js';
import { persistRawPrices } from './lib/rawprices.js';
import { cacheKeyFor, getCachedProdutos, setCachedProdutos } from './lib/pricecache.js';
import { applyCors } from './lib/cors.js';

// Menor Preço do Nota Paraná: recover the GTIN (same-store description match) and
// find the cheapest nearby price for a receipt item. One termo=<desc> search does both.
// The upstream fetch itself happens client-side (see src/lib/precos.js) — this function
// only does the matching/Neon work (GET serves a cache hit or asks the client to fetch;
// POST takes the client's already-fetched produtos and does the rest).

// norm/distinctiveStoreTokens/g14 now live in src/lib/text.js (shared with the client
// and api/lib/rawprices.js); re-exported so existing importers (tests) keep working.
export { norm, distinctiveStoreTokens, g14 };

// per-KG vs per-UN is the produce false-match trap; capture the item's unit to enforce like-for-like
export function unitToken(item) {
  const toks = new Set(norm(item.description).split(' '));
  if (toks.has('KG')) return 'KG';
  if (toks.has('UN')) return 'UN';
  const u = norm(item.unit);
  if (u === 'KG') return 'KG';
  if (u === 'UN' || u === 'UND') return 'UN';
  return null;
}

// Cut names are reused across species ("coxão mole" is both a beef and a pork cut) —
// when a canonical match narrows the search key down to just the cut name, species is
// the qualifier that got dropped. Guard it back: if the item names a species, offers
// naming a *different* one are excluded (offers silent on species are left ambiguous).
const SPECIES_GROUP = { BOI: 'BOV', BOV: 'BOV', BOVINA: 'BOV', BOVINO: 'BOV', SUINO: 'SUINO', SUINA: 'SUINO', PORCO: 'SUINO', FRANGO: 'FRANGO', GALINHA: 'FRANGO' };
export function speciesOf(desc) {
  for (const t of norm(desc).split(' ')) if (SPECIES_GROUP[t]) return SPECIES_GROUP[t];
  return null;
}

export function sameStore(estab, storeTokens, city) {
  const e = estab || {};
  if (city && norm(e.mun) !== city) return false;
  const names = `${norm(e.nm_emp)} ${norm(e.nm_fan)}`;
  return storeTokens.length ? storeTokens.some((t) => names.includes(t)) : false;
}

// Descriptions vary per store, so a description → GTIN is only unique WITHIN one store.
export function recoverGtin(itemDesc, produtos, storeTokens, city) {
  const target = norm(itemDesc);
  const hit = (produtos || []).find((p) => sameStore(p.estabelecimento, storeTokens, city) && norm(p.desc) === target && g14(p.gtin));
  return hit ? g14(hit.gtin) : null;
}

const median = (nums) => {
  const s = [...nums].sort((a, b) => a - b);
  const m = Math.floor(s.length / 2);
  return s.length % 2 ? s[m] : (s[m - 1] + s[m]) / 2;
};

// The fiscal NCM most matched offers agree on — a deterministic category signal
// (Menor Preço returns it per offer). Mode, so one mislabeled offer can't flip it.
function representativeNcm(candidates) {
  const counts = new Map();
  for (const p of candidates) {
    const n = String(p.ncm || '').replace(/\D/g, '');
    if (n.length >= 4) counts.set(n, (counts.get(n) || 0) + 1);
  }
  let best = null, bestC = 0;
  for (const [n, c] of counts) if (c > bestC) { best = n; bestC = c; }
  return best;
}

// Store descriptions for the same GTIN vary ("REF COCA COLA 350ML" vs "COCA COLA
// LATA 350 ML"); the modal description is the least-surprising label to show for a
// scanned product — a real majority beats a one-off (typo, promo text tacked onto
// one store's description, etc). But a small group (2-3 offers, common for a niche
// SKU) often has no majority at all, just a tie — plain `c > bestC` then keeps
// whichever happened to iterate first, arbitrarily. That's what silently hid real
// variants ("CERVEJA HEINEKEN LON" vs the same GTIN's "CERVEJA HEINEKEN LONG ZERO
// 330ML", both 1-of-2 offers): so only break ties in favor of the longer, more
// specific description — a genuine majority still always wins outright.
function representativeDesc(candidates) {
  const counts = new Map();
  for (const p of candidates) {
    const d = (p.desc || '').trim();
    if (d) counts.set(d, (counts.get(d) || 0) + 1);
  }
  let bestC = 0;
  for (const c of counts.values()) if (c > bestC) bestC = c;
  let best = null;
  for (const [d, c] of counts) {
    if (c === bestC && (!best || d.length > best.length)) best = d;
  }
  return best;
}

// Crowd-sourced NFC-e prices contain bad entries (same GTIN "found" at a third of its price).
// With enough offers, drop anything below 40% of the median before taking the cheapest.
function trimOutliers(offers) {
  if (offers.length < 4) return offers;
  const floor = 0.4 * median(offers.map((o) => o.priceCents));
  return offers.filter((o) => o.priceCents >= floor);
}

// "RUA TAPUIAS, 845, VILA CASONI, LONDRINA - PR" — enough for a maps search.
function storeAddress(e) {
  const street = [e.tp_logr, e.nm_logr, e.nr_logr].filter(Boolean).join(' ');
  const parts = [street, e.bairro, e.mun && `${e.mun}${e.uf ? ` - ${e.uf}` : ''}`].filter(Boolean);
  return parts.length ? parts.join(', ') : null;
}

// Which offers match this item: gtin -> exact barcode (high confidence); gtin null
// (produce/brand) -> description tokens + matching unit basis (approximate), plus three
// relevance guards layered on top (src/lib/match.js): CLASS_BLOCK (an empty returnable
// bottle is not "2L of the drink"), size agreement (a query naming a size must not match
// a different, explicitly-sized offer), and NCM-category agreement (separates "Leite"
// from "Doce de Leite" — token containment alone can't, LEITE is a legitimate substring
// of both). When a canonical product was recovered (meat/produce only, see
// api/lib/canonical.js), its alias tokens replace the raw description tokens — a
// curated, noise-free search key that also carries a fallback unit basis for items whose
// own description omits one.
export function candidatesFor(item, produtos, gtin, canonical) {
  if (gtin) return (produtos || []).filter((p) => g14(p.gtin) === gtin);
  const want = canonical ? canonical.tokens : significantTokens(item.description);
  if (!want.length) return [];
  const itemUnit = unitToken(item) || (canonical ? canonical.unit_basis : null);
  // Only load-bearing when canonical narrowed `want` below the item's own tokens —
  // the raw significantTokens(item.description) path already requires the item's
  // species word verbatim, so it can't cross-match species on its own.
  const itemSpecies = canonical ? speciesOf(item.description) : null;
  const querySize = parseSize(item.description);
  const queryHasClassBlock = hasClassBlock(item.description);
  const queryCategory = classify(item.description);
  return (produtos || []).filter((p) => {
    const rawToks = new Set(norm(p.desc).split(' ')); // KG/UN literal check needs the raw form; significantTokens strips it
    const toks = new Set(significantTokens(p.desc));
    if (!want.every((w) => toks.has(w))) return false;
    if (itemSpecies) {
      const offerSpecies = speciesOf(p.desc);
      if (offerSpecies && offerSpecies !== itemSpecies) return false; // different animal, not a match
    }
    if (itemUnit && rawToks.has('KG') !== (itemUnit === 'KG')) return false; // like-for-like basis
    if (!queryHasClassBlock && hasClassBlock(p.desc)) return false; // different product class (vasilhame, casco, ...)
    if (querySize && !sizesOverlap(querySize, parseSize(p.desc))) return false; // named size disagrees
    const offerCategory = classify({ description: p.desc, ncm: p.ncm });
    if (queryCategory !== 'outros' && offerCategory !== 'outros' && queryCategory !== offerCategory) return false;
    return true;
  });
}

// Reduce a candidate set to cheapest + best-price-per-store (nearest-first) + range.
function summarize(candidates) {
  let offers = candidates
    .map((p) => {
      const e = p.estabelecimento || {};
      return { priceCents: reaisToCents(p.valor), store: e.nm_fan || e.nm_emp || null, bairro: e.bairro || null, addr: storeAddress(e), cod: e.codigo, km: Number(p.distkm), datahora: p.datahora || null };
    })
    .filter((o) => o.priceCents > 0);
  offers = trimOutliers(offers).sort((a, b) => a.priceCents - b.priceCents);
  const best = offers[0] || null;
  // Best price per store (offers already cheapest-first) so the client can price
  // the basket at any one store without re-querying. km is per-branch, so sorting
  // by proximity gives a ~stable regional store set across items.
  const seen = new Set();
  const stores = [];
  for (const o of offers) {
    if (seen.has(o.cod)) continue;
    seen.add(o.cod);
    stores.push(o);
  }
  stores.sort((a, b) => (Number.isFinite(a.km) ? a.km : 1e9) - (Number.isFinite(b.km) ? b.km : 1e9));
  return {
    cheapest: best ? { priceCents: best.priceCents, store: best.store, bairro: best.bairro, addr: best.addr, km: best.km, datahora: best.datahora } : null,
    // one Menor Preço page is ~45 offers, so this is naturally bounded; keep them all
    // (nearest first) so every store found stays selectable in the picker.
    stores,
    // Local price spread for the product (offers already trimmed + sorted cheapest-first).
    range: offers.length ? { minCents: offers[0].priceCents, maxCents: offers[offers.length - 1].priceCents } : null,
    nOffers: offers.length,
    nStores: seen.size,
  };
}

// A vague term ("Carne", "Toddy") matches several real products; group the candidates so
// the user can pick the right one instead of the blind cheapest. Group by GTIN (branded)
// or a token/size signature (produce, or GTIN-less offers) — productSignature is more
// resilient to store-text formatting noise than norm(desc) alone, so the same product
// under differently-formatted descriptions collapses into one option instead of several
// duplicate cards. Tier 1 (the literal product) ranks above tier 2 (formulation/packaging
// variants — Zero, Retornável, ...); within a tier, most-offered product first, then score,
// then cheapest.
function buildOptions(candidates, queryText) {
  const groups = new Map();
  for (const p of candidates) {
    const key = g14(p.gtin) || productSignature(p.desc);
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key).push(p);
  }
  let opts = [];
  for (const [key, cands] of groups) {
    const s = summarize(cands);
    if (!s.cheapest) continue;
    const rep = cands[0].desc;
    opts.push({
      key, gtin: g14(cands[0].gtin), name: representativeDesc(cands),
      cheapest: s.cheapest, stores: s.stores, nStores: s.nStores, nOffers: s.nOffers,
      ncm: representativeNcm(cands),
      tier: hasNewVariant(queryText, rep) ? 2 : 1,
      score: scoreOffer(queryText, rep),
    });
  }
  // A bare category query ("Leite") can turn up nothing but variants (every offer names
  // a formulation the query didn't) — promote them all rather than show an empty list.
  if (opts.length && opts.every((o) => o.tier === 2)) for (const o of opts) o.tier = 1;
  opts.sort((a, b) => a.tier - b.tier || b.nOffers - a.nOffers || b.score - a.score || a.cheapest.priceCents - b.cheapest.priceCents);
  const tier1 = opts.filter((o) => o.tier === 1).slice(0, 8);
  const tier2 = opts.filter((o) => o.tier === 2).slice(0, 6);
  return [...tier1, ...tier2]; // bound payload; more than this is noise
}

export function selectCheapest(item, produtos, gtin) {
  const candidates = candidatesFor(item, produtos, gtin);
  return { ...summarize(candidates), name: representativeDesc(candidates), ncm: representativeNcm(candidates) };
}

export async function analyzeItem(item, produtos, storeTokens, city) {
  const gtin = recoverGtin(item.description, produtos, storeTokens, city);
  // canonical lookup only helps the no-GTIN path (produce/meat); confidence stays
  // 'approx' either way — it narrows the search key, it doesn't reach GTIN-level certainty.
  const canonical = gtin ? null : await lookupCanonical(item.description, classify(item.description));
  const candidates = candidatesFor(item, produtos, gtin, canonical);
  const options = buildOptions(candidates, item.description);
  // The collapsed "cheapest"/name shown before any option is explicitly picked must
  // reflect the literal product asked for, not a demoted variant (Zero, Retornável, ...)
  // — same tier-1 rule buildOptions ranks options by. A bare category query can turn up
  // only variants; when tier 1 is empty, fall back to every surviving candidate rather
  // than report no price at all.
  let primary = gtin ? candidates : candidates.filter((p) => !hasNewVariant(item.description, p.desc));
  if (!gtin && primary.length === 0) primary = candidates;
  return {
    gtin, basis: gtin ? 'gtin' : (canonical ? 'canonical' : 'desc'), confidence: gtin ? 'high' : 'approx',
    ...summarize(primary), name: representativeDesc(primary), ncm: representativeNcm(primary),
    options: options.length > 1 ? options : [], // only when there's a real choice to make
  };
}

// Nota Paraná covers PR stores only (see README/CLAUDE.md) — any offer naming another
// UF is not a real result. Vercel's serverless egress IP gets fed fabricated decoy data
// by menorpreco.notaparana.pr.gov.br (looks like real JSON — garbled store names, wrong
// states — instead of an outright block); this is the one invariant that reliably tells
// real offers from decoys, so treat a violation as "no data" rather than trust/cache it.
function isPlausiblePR(produtos) {
  return produtos.every((p) => (p.estabelecimento && p.estabelecimento.uf) === 'PR');
}

// Compute the price response for an already-fetched, already-validated produtos list.
// Shared by the GET cache-hit path and the POST (client-fetched) path below.
async function buildPriceResponse(produtos, { gtin, q, unit, store, city }) {
  if (gtin) {
    // Barcode scan: the GTIN is the identity — price directly, skip description recovery.
    // selectCheapest filters to g14(p.gtin)===gtin, so a barcode with no offers (Menor
    // Preço returns the baseline area list, not empty) can't leak a wrong product's price.
    const r = selectCheapest({ description: '', unit: '' }, produtos, gtin);
    return { gtin, basis: 'gtin', confidence: 'high', ...r };
  }
  const storeTokens = distinctiveStoreTokens(store || '');
  return analyzeItem({ description: q, unit }, produtos, storeTokens, norm(city || ''));
}

// Menor Preço's own CORS is wide open (access-control-allow-origin: *) and only the
// browser's own (residential/mobile) IP dodges the decoy-data problem above — so the
// live upstream fetch happens client-side (src/lib/precos.js), not here. This handler
// only ever talks to Neon: GET serves a cache hit or says "you fetch it" (needsFetch);
// POST takes what the client already fetched and does the matching/persist/cache work
// that needs the server (Neon connection lives in api/lib/*, never shipped to the client).
export default async function handler(req, res) {
  if (applyCors(req, res)) return;
  const q = (req.query && req.query.q) || (req.query && req.query.description);
  const gtin = g14(req.query && req.query.gtin); // null unless a valid 8-14 digit barcode
  const local = req.query && req.query.local; // "lat,lon"
  if (!local || (!q && !gtin)) return res.status(400).json({ error: 'missing_local_or_query' });
  const raio = Number(req.query.raio) || 25;
  try {
    const cacheKey = cacheKeyFor(gtin, q);
    if (req.method === 'POST') {
      const produtos = (req.body && req.body.produtos) || [];
      if (!Array.isArray(produtos) || !isPlausiblePR(produtos)) {
        console.warn(`menorpreco_decoy_rejected offers=${Array.isArray(produtos) ? produtos.length : 0} q=${q || ''} gtin=${gtin || ''}`);
        return res.status(502).json({ error: 'produtos_implausible' });
      }
      await persistRawPrices(produtos); // best-effort; never blocks/fails the price response
      await setCachedProdutos(cacheKey, local, raio, produtos); // best-effort; today's cache entry
      return res.status(200).json(await buildPriceResponse(produtos, { gtin, q, unit: req.body.unit, store: req.body.store, city: req.body.city }));
    }
    const produtos = await getCachedProdutos(cacheKey, local, raio);
    if (!produtos) return res.status(200).json({ needsFetch: true }); // client fetches Menor Preço itself, then POSTs here
    return res.status(200).json(await buildPriceResponse(produtos, { gtin, q, unit: req.query.unit, store: req.query.store, city: req.query.city }));
  } catch (e) {
    return res.status(502).json({ error: 'menorpreco_failed', detail: String(e && e.message) });
  }
}
