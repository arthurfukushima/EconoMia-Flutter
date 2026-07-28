// Layer-2 relevance helpers for shopping-list item matching (see api/precos.js
// candidatesFor/buildOptions). Pure functions over normalized description text — no DB,
// no NCM lookup — so query-vs-offer relevance is testable without a live Menor Preço
// fetch. Shared client+server like text.js/categoria.js.
import { norm } from './text.js';

// pt-BR plural -> singular on an already-norm()ed (uppercase, no-accent) token. A
// heuristic, not a full grammar: covers the plural shapes that actually show up in
// receipt/offer text (LEITES, PAES, LARANJAS, OVOS, PAPEIS) so a query and its offers
// land on the same token without a canonical-product DB lookup.
export function singular(token) {
  const t = String(token || '');
  if (t.length <= 3) return t;
  if (t.endsWith('AES')) return t.slice(0, -3) + 'AO';   // PAES -> PAO
  if (t.endsWith('OES')) return t.slice(0, -3) + 'AO';   // LIMOES -> LIMAO
  if (t.endsWith('EIS')) return t.slice(0, -3) + 'EL';   // PAPEIS -> PAPEL
  if (t.endsWith('NS')) return t.slice(0, -2) + 'M';     // ITENS -> ITEM
  if (t.endsWith('RES') || t.endsWith('SES') || t.endsWith('ZES')) return t.slice(0, -2); // MESES -> MES
  if (t.endsWith('S')) return t.slice(0, -1);              // LEITES -> LEITE, OVOS -> OVO
  return t;
}

// Packaging/quantity tokens that never carry product identity — dropped before
// containment/head/score comparisons.
export const GENERIC_TOKENS = new Set([
  'KG', 'UN', 'UND', 'HORTFG', 'CX', 'PCT', 'PC', 'C', 'L', 'ML', 'G', 'GR', 'TP', 'COL', 'LT',
  'LITRO', 'LITROS',
]);

const SIZE_TOKEN_RE = /^\d+(?:[.,]\d+)?(KG|GR|G|ML|LT|LITROS?|L)$/;
const PURE_DIGITS_RE = /^\d+$/;

// A different product CLASS entirely — never a valid price comparison for the product
// itself (an empty returnable bottle is not "2L of Coke"). Hard-excluded in
// candidatesFor unless the query itself names one.
const CLASS_BLOCK = new Set(['VASILHAME', 'CASCO', 'ENGRADADO', 'EMBALAGEM']);
const CLASS_BLOCK_PHRASES = ['GARRAFAO VAZIO'];

// Contrastive formulation/packaging markers — never rejected on these (a query for
// "Coca Cola" must still be able to reach "Coca Cola Zero"), just demoted to tier 2 so
// the literal product the user typed shows first. See buildOptions in api/precos.js.
const VARIANT_MARKERS = new Set([
  'ZERO', 'DIET', 'LIGHT', 'INTEGRAL', 'DESNATADO', 'SEMIDESNATADO',
  'RETORNAVEL', 'RET', 'VIDRO', 'LATA', 'PET',
]);
const VARIANT_PHRASES = ['SEM ACUCAR', 'MENOS ACUCAR', 'SEM LACTOSE'];

function tokensOf(text) {
  return norm(text).split(' ').filter(Boolean);
}

// Significant (non-generic, non-size, singularized) tokens — the query/offer "identity"
// set used for containment, scoring, and the option-grouping signature. Size tokens
// (2L, 500G) are stripped here and compared separately via parseSize/sizesOverlap: a
// merged token like "2L" vs a split "2 LT" would otherwise fragment this set differently
// for the same real size, which is exactly the kind of formatting noise this is meant to
// see past.
export function significantTokens(text) {
  return tokensOf(text)
    .filter((t) => t.length >= 2 && !GENERIC_TOKENS.has(t) && !PURE_DIGITS_RE.test(t) && !SIZE_TOKEN_RE.test(t))
    .map(singular);
}

// First significant token — pt-BR descriptions are head-initial ("LEITE INTEGRAL",
// "ALCATRA BOV"). Used only as a soft ranking signal (productSignature/scoreOffer), never
// as a hard reject — real offers commonly lead with the brand, not the product noun
// ("ITALAC LEITE INTEGRAL 1L"), so requiring positional agreement would reject genuine
// matches. The head-noun *containment* check that actually matters is the ordinary
// significantTokens containment already run in candidatesFor.
export function headToken(text) {
  const toks = tokensOf(text).filter((t) => !/\d/.test(t) && !GENERIC_TOKENS.has(t));
  return toks.length ? singular(toks[0]) : null;
}

// Light normalization that keeps digits/decimal separators intact — norm() itself strips
// '.'/',' (turns "1.5" into "1 5"), which would break decimal size parsing.
function forSize(text) {
  return String(text || '').toUpperCase().normalize('NFD').replace(/\p{Diacritic}/gu, '');
}

const SIZE_RE = /(\d+)\s*X\s*(\d+(?:[.,]\d+)?)\s*(KG|LITROS?|LT|ML|GR|G|L)\b|(\d+(?:[.,]\d+)?)\s*(KG|LITROS?|LT|ML|GR|G|L)\b/g;

function toBase(rawValue, unit) {
  const v = parseFloat(String(rawValue).replace(',', '.'));
  const u = unit.startsWith('LITR') ? 'L' : unit;
  if (u === 'KG') return { unit: 'G', value: v * 1000 };
  if (u === 'G' || u === 'GR') return { unit: 'G', value: v };
  if (u === 'ML') return { unit: 'ML', value: v };
  return { unit: 'ML', value: v * 1000 }; // L, LT
}

// Every size mention in the text, normalized to a common base unit (G for mass, ML for
// volume) so "2L" and "2000ML" compare equal. A multipack ("6X350ML") contributes the
// PER-UNIT size (350ml), not the total — a query for "refrigerante 2l" must not match a
// six-pack of 350ml cans just because the total volume happens to line up.
export function parseSize(text) {
  const s = forSize(text);
  const out = [];
  let m;
  SIZE_RE.lastIndex = 0;
  while ((m = SIZE_RE.exec(s))) {
    if (m[3]) out.push(toBase(m[2], m[3]));      // multipack form: NxSIZE
    else out.push(toBase(m[4], m[5]));
  }
  return out.length ? out : null;
}

// true when either side names no size (not a constraint) or the two share a size in
// common; false only on an explicit, unambiguous disagreement.
export function sizesOverlap(a, b) {
  if (!a || !b) return true;
  return a.some((x) => b.some((y) => x.unit === y.unit && Math.abs(x.value - y.value) < 0.01));
}

export function hasClassBlock(text) {
  const t = norm(text);
  const toks = new Set(tokensOf(text));
  for (const w of CLASS_BLOCK) if (toks.has(w)) return true;
  for (const p of CLASS_BLOCK_PHRASES) if (t.includes(p)) return true;
  return false;
}

function variantMarkersOf(text) {
  const t = norm(text);
  const toks = new Set(tokensOf(text));
  const found = new Set();
  for (const w of VARIANT_MARKERS) if (toks.has(w)) found.add(w);
  for (const p of VARIANT_PHRASES) if (t.includes(p)) found.add(p);
  return found;
}

// True when the offer carries a formulation/packaging marker the query itself didn't
// name — drives tier assignment in buildOptions (tier 2 = "variação", collapsed below
// the literal product the user typed).
export function hasNewVariant(queryDesc, offerDesc) {
  const q = variantMarkersOf(queryDesc);
  for (const v of variantMarkersOf(offerDesc)) if (!q.has(v)) return true;
  return false;
}

const SCORE = { HEAD: 100, TOKEN: 20, SIZE: 15, EXTRA_PENALTY: 8, EXTRA_CAP: 40 };

// Soft ranking score among candidates that already survived candidatesFor's hard
// guards (unit-basis, species, containment, class-block, size, NCM-category) — a
// tie-breaker within a tier, not a filter. Rewards head-noun/token/size agreement,
// penalizes (capped) offer tokens the query didn't ask for.
export function scoreOffer(queryDesc, offerDesc) {
  const qHead = headToken(queryDesc);
  const oHead = headToken(offerDesc);
  const qToks = new Set(significantTokens(queryDesc));
  const oToks = new Set(significantTokens(offerDesc));
  const qSize = parseSize(queryDesc);
  const oSize = parseSize(offerDesc);

  let score = 0;
  if (qHead && oHead === qHead) score += SCORE.HEAD;
  for (const t of qToks) if (t !== qHead && oToks.has(t)) score += SCORE.TOKEN;
  if (qSize && sizesOverlap(qSize, oSize)) score += SCORE.SIZE;
  let extra = 0;
  for (const t of oToks) if (!qToks.has(t)) extra++;
  score -= Math.min(extra * SCORE.EXTRA_PENALTY, SCORE.EXTRA_CAP);
  return score;
}

// Grouping key for buildOptions: same head noun + same significant tokens + same size
// bucket = the same product, regardless of which GTIN/store text produced the offer.
// Used as a fallback when the offer carries no GTIN (candidatesFor already groups
// GTIN'd offers by the barcode itself) — more resilient to store-text formatting noise
// than norm(desc) alone, e.g. "COCA COLA ZERO 2L" vs "COCA-COLA ZERO 2 LITROS".
export function productSignature(desc) {
  const head = headToken(desc) || '';
  const toks = [...new Set(significantTokens(desc))].sort();
  const sizes = (parseSize(desc) || []).map((s) => `${s.unit}${s.value}`).sort();
  return [head, ...toks, ...sizes].join('|');
}
