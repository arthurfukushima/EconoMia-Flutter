import 'package:flutter/material.dart';

import '../core/categoria.dart';

/// The category emoji tag for a receipt/product description — an accessible
/// label, not an emoji-only one. Shared by the receipt, produto and mercado
/// screens.
class CatChip extends StatelessWidget {
  const CatChip({super.key, this.description, this.ncm});

  final String? description;
  final String? ncm;

  @override
  Widget build(BuildContext context) {
    final cat = classify(description: description, ncm: ncm);
    return Semantics(
      label: cat.label,
      excludeSemantics: true,
      child: Icon(_categoryIcon(cat), size: 17),
    );
  }
}

IconData _categoryIcon(Categoria cat) => switch (cat) {
  Categoria.frutas => Icons.apple_rounded,
  Categoria.verduras => Icons.eco_rounded,
  Categoria.carnes => Icons.restaurant_rounded,
  Categoria.laticinios => Icons.icecream_rounded,
  Categoria.padaria => Icons.bakery_dining_rounded,
  Categoria.bebidas => Icons.local_drink_rounded,
  Categoria.doces => Icons.cookie_rounded,
  Categoria.limpeza => Icons.cleaning_services_rounded,
  Categoria.outros => Icons.category_rounded,
};
