/// Classify a receipt item into a promo-relevant category, so Tendências can
/// spot which categories a store discounts on which weekday, and Resumo can
/// break spending down.
///
/// Prefers the fiscal NCM code when one is present (deterministic), falling
/// back to keyword matching on the description.
///
/// **Where the NCM comes from:** the SEFAZ consulta carries none, but the Menor
/// Preço offers do — receipt enrichment stamps the matched product's NCM onto
/// the item, so that path is live for priced items. Keyword matching covers the
/// pre-pricing display and any NCM chapter not mapped below.
library;

import 'text.dart';

/// One shared visual vocabulary — the planner, the receipt nudge and the
/// per-item chips all draw from here. The emoji never travels alone: it is
/// always rendered beside [label], never as the only thing identifying a
/// category.
enum Categoria {
  frutas('🍎', 'Frutas'),
  verduras('🥬', 'Verduras'),
  carnes('🥩', 'Carnes'),
  laticinios('🥛', 'Laticínios'),
  padaria('🍞', 'Padaria'),
  bebidas('🥤', 'Bebidas'),
  doces('🍬', 'Doces'),
  limpeza('🧴', 'Limpeza'),
  outros('❓', 'Outros');

  const Categoria(this.emoji, this.label);

  final String emoji;
  final String label;

  /// Reads a persisted category name back, tolerating anything unrecognised.
  /// A stored offer whose category we can no longer resolve is still a usable
  /// price observation; it just lands in [outros].
  static Categoria fromKey(String? key) =>
      values.firstWhere((c) => c.name == key, orElse: () => outros);
}

/// Keyword tokens per category, in [norm] form (uppercase, unaccented).
/// pt-BR descriptions lead with the head noun ("BANANA NANICA", "ALCATRA BOV"),
/// so the first token that maps wins. Plurals are handled by stripping a
/// trailing S at lookup rather than by listing both forms.
const _keywords = <Categoria, List<String>>{
  Categoria.frutas: ['BANANA', 'MACA', 'LARANJA', 'MAMAO', 'ABACAXI', 'MELANCIA', 'MELAO', 'UVA', 'MANGA', 'LIMAO', 'MORANGO', 'ABACATE', 'PERA', 'KIWI', 'TANGERINA', 'MEXERICA', 'PONKAN', 'GOIABA', 'MARACUJA', 'CAQUI', 'AMEIXA', 'PESSEGO', 'COCO', 'CEREJA', 'FIGO', 'FRUTA'],
  Categoria.verduras: ['TOMATE', 'ALFACE', 'CEBOLA', 'BATATA', 'CENOURA', 'ALHO', 'PIMENTAO', 'PEPINO', 'ABOBRINHA', 'ABOBORA', 'BROCOLIS', 'BROCOLI', 'COUVE', 'REPOLHO', 'MANDIOCA', 'AIPIM', 'MACAXEIRA', 'BETERRABA', 'CHUCHU', 'VAGEM', 'QUIABO', 'BERINJELA', 'RABANETE', 'RUCULA', 'ESPINAFRE', 'ACELGA', 'AGRIAO', 'SALSA', 'SALSINHA', 'CEBOLINHA', 'COENTRO', 'GENGIBRE', 'MILHO', 'INHAME', 'HORTIFRUTI', 'HORTIFRUT', 'HORTFG', 'LEGUME', 'VERDURA'],
  Categoria.carnes: ['CARNE', 'BOVINA', 'BOVIN', 'BOV', 'SUINA', 'SUINO', 'SUIN', 'FRANGO', 'FGO', 'FRGO', 'GALINHA', 'PEITO', 'COXA', 'SOBRECOXA', 'ASA', 'ASINHA', 'ALCATRA', 'PATINHO', 'ACEM', 'COXAO', 'MUSCULO', 'LAGARTO', 'FILE', 'FILEZINHO', 'CONTRAFILE', 'COSTELA', 'COSTELINHA', 'PICANHA', 'MAMINHA', 'FRALDINHA', 'CUPIM', 'PERNIL', 'LOMBO', 'PANCETA', 'CARRE', 'MOIDA', 'MOIDO', 'HAMBURGUER', 'HAMBURGER', 'ALMONDEGA', 'LINGUICA', 'SALSICHA', 'BACON', 'MORTADELA', 'PRESUNTO', 'SALAME', 'PEIXE', 'TILAPIA', 'SALMAO', 'SARDINHA', 'MERLUZA', 'PESCADA', 'PESCADO', 'CAMARAO', 'ATUM', 'BIFE', 'FIGADO', 'CORACAO', 'MOELA'],
  Categoria.laticinios: ['LEITE', 'LEITINHO', 'IOGURTE', 'IOG', 'QUEIJO', 'MUSSARELA', 'MUCARELA', 'REQUEIJAO', 'MANTEIGA', 'MARGARINA', 'NATA', 'COALHADA', 'RICOTA', 'PROVOLONE', 'PARMESAO', 'CATUPIRY', 'DANONE', 'DANONINHO'],
  Categoria.padaria: ['PAO', 'PAES', 'BISNAGA', 'BAGUETE', 'FRANCES', 'CROISSANT', 'ROSCA', 'BOLO', 'BOLACHA', 'BISCOITO', 'BISC', 'TORRADA', 'SONHO', 'PANETONE', 'BROA', 'PANIFICADO', 'PADARIA', 'CUCA', 'SOVADO'],
  Categoria.bebidas: ['REFRI', 'REFRIG', 'REFRIGERANTE', 'COCA', 'PEPSI', 'GUARANA', 'FANTA', 'SPRITE', 'SUCO', 'CERVEJA', 'CERV', 'CHOPP', 'VINHO', 'ENERGETICO', 'ISOTONICO', 'GATORADE', 'NECTAR', 'REFRESCO', 'TODDYNHO', 'TONICA'],
  Categoria.doces: ['CHOCOLATE', 'CHOC', 'BOMBOM', 'BOMBONS', 'BALA', 'BALAS', 'CHICLETE', 'PIRULITO', 'BRIGADEIRO', 'PACOCA', 'PACOQUITA', 'GELEIA', 'MARSHMALLOW', 'JUJUBA', 'CONFEITO', 'CARAMELO', 'COCADA', 'DOCINHO', 'DOCE', 'GELATINA', 'PASTILHA'],
  Categoria.limpeza: ['DETERGENTE', 'DETERG', 'SABAO', 'AMACIANTE', 'AMACIAN', 'DESINFETANTE', 'DESINF', 'SANITARIA', 'CANDIDA', 'CLORO', 'ALVEJANTE', 'LIMPADOR', 'MULTIUSO', 'VEJA', 'YPE', 'OMO', 'DESODORIZADOR', 'LUSTRA', 'ESPONJA', 'SAPOLIO', 'AJAX', 'DESENGORDURANTE', 'INSETICIDA', 'ODORIZADOR', 'LISOFORM', 'PINHOSOL'],
};

/// token → category. The first category listing a token owns it, so the order
/// of [_keywords] is the tie-break — hence `putIfAbsent`, not a map literal.
final _word = () {
  final map = <String, Categoria>{};
  for (final entry in _keywords.entries) {
    for (final token in entry.value) {
      map.putIfAbsent(token, () => entry.key);
    }
  }
  return map;
}();

/// NCM chapter (first two digits) → category.
const _ncmChapter = <String, Categoria>{
  '02': Categoria.carnes,
  '03': Categoria.carnes,
  '04': Categoria.laticinios,
  '07': Categoria.verduras,
  '08': Categoria.frutas,
  '17': Categoria.doces,
  '18': Categoria.doces,
  '19': Categoria.padaria,
  '22': Categoria.bebidas,
  '34': Categoria.limpeza,
};

Categoria? _fromNcm(String? ncm) {
  // The chapter is the first two digits as-is — an NCM is never left-padded.
  final digits = (ncm ?? '').replaceAll(RegExp(r'\D'), '');
  return digits.length >= 4 ? _ncmChapter[digits.substring(0, 2)] : null;
}

/// The category for an item, from its fiscal [ncm] when known, otherwise from
/// the first [description] token that maps. Never null — an unrecognised item
/// is honestly [Categoria.outros] rather than guessed into a real category.
Categoria classify({String? description, String? ncm}) {
  final byNcm = _fromNcm(ncm);
  if (byNcm != null) return byNcm;
  for (final raw in norm(description).split(' ')) {
    final singular = raw.length > 3 && raw.endsWith('S')
        ? raw.substring(0, raw.length - 1)
        : raw;
    final cat = _word[raw] ?? _word[singular];
    if (cat != null) return cat;
  }
  return Categoria.outros;
}
