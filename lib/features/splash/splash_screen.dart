import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../theme/tokens.dart';
import '../../widgets/wordmark.dart';

/// Mia lands, the name rises, the screen hands over to Home.
///
/// Purely decorative — it waits on an animation, never on work — so it collapses
/// to a brief fade when the platform asks for reduced motion.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);

  late final Animation<double> _logo = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, 0.42, curve: SaMotion.easeBack),
  );
  late final Animation<double> _word = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.42, 0.7, curve: SaMotion.easeOut),
  );
  late final Animation<double> _exit = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.82, 1, curve: Curves.easeIn),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    _c.duration = MediaQuery.disableAnimationsOf(context)
        ? const Duration(milliseconds: 500)
        : const Duration(milliseconds: 2100);
    _c.forward().then((_) {
      if (mounted) context.go('/');
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sa = Theme.of(context).sa;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: sa.forest,
        body: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              return Opacity(
                opacity: 1 - _exit.value,
                child: Transform.scale(
                  scale: 1 + 0.05 * _exit.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: _logo.value,
                        child: Image.asset('assets/img/mia-icon.png', width: 132, height: 132),
                      ),
                      const SizedBox(height: 20),
                      Opacity(
                        opacity: _word.value.clamp(0, 1),
                        child: Transform.translate(
                          offset: Offset(0, 16 * (1 - _word.value)),
                          child: Wordmark(showLogo: false, fontSize: 32, color: sa.paper),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
