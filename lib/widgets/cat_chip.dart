import 'package:flutter/material.dart';

import '../core/categoria.dart';
import '../data/models/receipt.dart';

/// The category emoji tag for a receipt item — an accessible label, not an
/// emoji-only one. Shared by the receipt, produto and mercado screens.
class CatChip extends StatelessWidget {
  const CatChip({super.key, required this.item});

  final ReceiptItem item;

  @override
  Widget build(BuildContext context) {
    final cat = classify(description: item.description, ncm: item.ncm);
    return Semantics(
      label: cat.label,
      excludeSemantics: true,
      child: Text(cat.emoji, style: const TextStyle(fontSize: 15)),
    );
  }
}
