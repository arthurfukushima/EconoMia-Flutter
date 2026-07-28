// Shared text normalization — used by the server proxy (api/precos.js) and the
// client (categoria.js, tendencias.js) so there's one copy of the rules.

export const norm = (s) =>
  (s || '').toUpperCase().normalize('NFD').replace(/\p{Diacritic}/gu, '').replace(/[^A-Z0-9 ]/g, ' ').replace(/\s+/g, ' ').trim();

// normalize any EAN-8/12/13/GTIN-14 to 14 digits so 13 vs 14 with leading zeros still match
export const g14 = (x) => {
  const d = String(x || '').replace(/\D/g, '');
  return d.length >= 8 && d.length <= 14 ? d.padStart(14, '0') : null;
};

// tokens dropped when reducing a store's razão social to its distinctive name
const STORE_STOP = new Set(['IRMAOS', 'CIA', 'LTDA', 'ME', 'EPP', 'EIRELI', 'EIRELLI', 'COMERCIO', 'COM', 'SUPERMERCADO', 'SUPERMERCADOS', 'MERCADO', 'SUPER', 'ATACADO', 'ATACAREJO', 'DISTRIBUIDORA', 'E', 'DE', 'DO', 'DA', 'DOS', 'DAS', 'SA', 'S', 'A']);

export const distinctiveStoreTokens = (name) => norm(name).split(' ').filter((t) => t.length >= 4 && !STORE_STOP.has(t));
