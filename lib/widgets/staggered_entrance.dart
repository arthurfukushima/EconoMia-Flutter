import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A small shared entrance treatment for stacked content.
///
/// It is deliberately local and one-shot: screens still own their layout, while
/// the motion language stays consistent and respects the platform's reduced
/// motion setting.
class StaggeredEntrance extends StatelessWidget {
  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
    this.delay = const Duration(milliseconds: 42),
  });

  final int index;
  final Duration delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: SaMotion.normal + delay * index,
      curve: SaMotion.easeOut,
      builder: (context, value, child) {
        final delayed = ((value * (index + 1)) - index).clamp(0.0, 1.0);
        return Opacity(
          opacity: delayed,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - delayed)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
