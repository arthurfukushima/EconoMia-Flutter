// Classify a receipt item into a promo-relevant category, so we can spot which
// categories a store discounts on which weekday. Prefers a fiscal NCM code when
// present (deterministic); falls back to keyword matching on the description.
//
// NCM source: the SEFAZ consulta we scrape has none (see api/nfce.js), but the
// Menor Preço offers DO carry it — enrichReceipt stamps item.ncm from the matched
// product, so this path is live for priced items. Keyword is the fallback for
// pre-pricing display and items whose NCM chapter we don't map.
import { norm } from './text.js';
import { singular } from './match.js';

// One shared visual vocabulary — used by the planner, the receipt nudge, and the
// per-item chips. Emoji always travels with a text label (never emoji-only).
export const CATEGORIES = {
  frutas:     { emoji: '🍎', label: 'Frutas' },
  verduras:   { emoji: '🥬', label: 'Verduras' },
  carnes:     { emoji: '🥩', label: 'Carnes' },
  laticinios: { emoji: '🥛', label: 'Laticínios' },
  padaria:    { emoji: '🍞', label: 'Padaria' },
  bebidas:    { emoji: '🥤', label: 'Bebidas' },
  doces:      { emoji: '🍬', label: 'Doces' },
  limpeza:    { emoji: '🧴', label: 'Limpeza' },
  outros:     { emoji: '❓', label: 'Outros' },
  // legacy alias: offers stored before the frutas/verduras split still carry
  // 'hortifruti'; keep it resolvable in catInfo (classify never returns it now).
  hortifruti: { emoji: '🥬', label: 'Hortifruti' },
};
export const catInfo = (cat) => CATEGORIES[cat] || CATEGORIES.outros;

// Keyword tokens per category (norm form: uppercase, no accents). Descriptions in
// pt-BR lead with the head noun ("BANANA NANICA", "ALCATRA BOV"), so the first
// token that maps wins. Plurals handled by stripping a trailing S at lookup.
const KEYWORDS = {
  frutas: ['BANANA', 'MACA', 'LARANJA', 'MAMAO', 'ABACAXI', 'MELANCIA', 'MELAO', 'UVA', 'MANGA', 'LIMAO', 'MORANGO', 'ABACATE', 'PERA', 'KIWI', 'TANGERINA', 'MEXERICA', 'PONKAN', 'GOIABA', 'MARACUJA', 'CAQUI', 'AMEIXA', 'PESSEGO', 'COCO', 'CEREJA', 'FIGO', 'FRUTA'],
  verduras: ['TOMATE', 'ALFACE', 'CEBOLA', 'BATATA', 'CENOURA', 'ALHO', 'PIMENTAO', 'PEPINO', 'ABOBRINHA', 'ABOBORA', 'BROCOLIS', 'BROCOLI', 'COUVE', 'REPOLHO', 'MANDIOCA', 'AIPIM', 'MACAXEIRA', 'BETERRABA', 'CHUCHU', 'VAGEM', 'QUIABO', 'BERINJELA', 'RABANETE', 'RUCULA', 'ESPINAFRE', 'ACELGA', 'AGRIAO', 'SALSA', 'SALSINHA', 'CEBOLINHA', 'COENTRO', 'GENGIBRE', 'MILHO', 'INHAME', 'HORTIFRUTI', 'HORTIFRUT', 'HORTFG', 'LEGUME', 'VERDURA'],
  carnes: ['CARNE', 'BOVINA', 'BOVIN', 'BOV', 'SUINA', 'SUINO', 'SUIN', 'FRANGO', 'FGO', 'FRGO', 'GALINHA', 'PEITO', 'COXA', 'SOBRECOXA', 'ASA', 'ASINHA', 'ALCATRA', 'PATINHO', 'ACEM', 'COXAO', 'MUSCULO', 'LAGARTO', 'FILE', 'FILEZINHO', 'CONTRAFILE', 'COSTELA', 'COSTELINHA', 'PICANHA', 'MAMINHA', 'FRALDINHA', 'CUPIM', 'PERNIL', 'LOMBO', 'PANCETA', 'CARRE', 'MOIDA', 'MOIDO', 'HAMBURGUER', 'HAMBURGER', 'ALMONDEGA', 'LINGUICA', 'SALSICHA', 'BACON', 'MORTADELA', 'PRESUNTO', 'SALAME', 'PEIXE', 'TILAPIA', 'SALMAO', 'SARDINHA', 'MERLUZA', 'PESCADA', 'PESCADO', 'CAMARAO', 'ATUM', 'BIFE', 'FIGADO', 'CORACAO', 'MOELA'],
  laticinios: ['LEITE', 'LEITINHO', 'IOGURTE', 'IOG', 'QUEIJO', 'MUSSARELA', 'MUCARELA', 'REQUEIJAO', 'MANTEIGA', 'MARGARINA', 'NATA', 'COALHADA', 'RICOTA', 'PROVOLONE', 'PARMESAO', 'CATUPIRY', 'DANONE', 'DANONINHO'],
  padaria: ['PAO', 'PAES', 'BISNAGA', 'BAGUETE', 'FRANCES', 'CROISSANT', 'ROSCA', 'BOLO', 'BOLACHA', 'BISCOITO', 'BISC', 'TORRADA', 'SONHO', 'PANETONE', 'BROA', 'PANIFICADO', 'PADARIA', 'CUCA', 'SOVADO'],
  bebidas: ['REFRI', 'REFRIG', 'REFRIGERANTE', 'COCA', 'PEPSI', 'GUARANA', 'FANTA', 'SPRITE', 'SUCO', 'CERVEJA', 'CERV', 'CHOPP', 'VINHO', 'ENERGETICO', 'ISOTONICO', 'GATORADE', 'NECTAR', 'REFRESCO', 'TODDYNHO', 'TONICA'],
  doces: ['CHOCOLATE', 'CHOC', 'BOMBOM', 'BOMBONS', 'BALA', 'BALAS', 'CHICLETE', 'PIRULITO', 'BRIGADEIRO', 'PACOCA', 'PACOQUITA', 'GELEIA', 'MARSHMALLOW', 'JUJUBA', 'CONFEITO', 'CARAMELO', 'COCADA', 'DOCINHO', 'DOCE', 'GELATINA', 'PASTILHA'],
  limpeza: ['DETERGENTE', 'DETERG', 'SABAO', 'AMACIANTE', 'AMACIAN', 'DESINFETANTE', 'DESINF', 'SANITARIA', 'CANDIDA', 'CLORO', 'ALVEJANTE', 'LIMPADOR', 'MULTIUSO', 'VEJA', 'YPE', 'OMO', 'DESODORIZADOR', 'LUSTRA', 'ESPONJA', 'SAPOLIO', 'AJAX', 'DESENGORDURANTE', 'INSETICIDA', 'ODORIZADOR', 'LISOFORM', 'PINHOSOL'],
};

// token -> category (first category listing a token wins its ownership)
const WORD = new Map();
for (const [cat, toks] of Object.entries(KEYWORDS)) {
  for (const t of toks) if (!WORD.has(t)) WORD.set(t, cat);
}

// NCM chapter (first 2 digits) -> category. Deterministic when a fiscal NCM exists.
const NCM_CHAPTER = { '07': 'verduras', '08': 'frutas', '02': 'carnes', '03': 'carnes', '04': 'laticinios', '17': 'doces', '18': 'doces', '19': 'padaria', '22': 'bebidas', '34': 'limpeza' };
function ncmCategory(ncm) {
  const d = String(ncm || '').replace(/\D/g, ''); // chapter = first two digits, as-is (never left-padded)
  return d.length >= 4 ? (NCM_CHAPTER[d.slice(0, 2)] || null) : null;
}

// classify(item) — item may be a string (description) or { description, ncm }.
export function classify(item) {
  const it = typeof item === 'string' ? { description: item } : (item || {});
  const byNcm = ncmCategory(it.ncm);
  if (byNcm) return byNcm;
  for (const raw of norm(it.description).split(' ')) {
    const cat = WORD.get(raw) || WORD.get(singular(raw));
    if (cat) return cat;
  }
  return 'outros';
}
