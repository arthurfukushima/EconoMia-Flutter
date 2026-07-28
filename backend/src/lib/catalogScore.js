// How cheap a market's cached price is, relative to the same product's price at every
// other market in the same município (api/lib/catalog.js's region min/max). Pure
// bucketing so it's testable without a DB and shared between the API handler and any
// client-side re-sort/re-bucket (e.g. after a category filter changes the visible set).
export function cheapnessScore(priceCents, minCents, maxCents, nStores) {
  if (!nStores || nStores < 2 || minCents == null || maxCents == null || maxCents === minCents) {
    return { bucket: 'unico', pct: null };
  }
  const pct = Math.round(((priceCents - minCents) / (maxCents - minCents)) * 100);
  const bucket = pct <= 15 ? 'otimo' : pct <= 40 ? 'ok' : 'caro';
  return { bucket, pct };
}

export const SCORE_LABEL = {
  otimo: 'Ótimo preço',
  ok: 'Preço razoável',
  caro: 'Tem mais barato perto',
  unico: 'Preço único encontrado',
};
