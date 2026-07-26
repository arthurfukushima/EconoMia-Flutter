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
      child: Text(cat.emoji, style: const TextStyle(fontSize: 15)),
    );
  }
}
