import 'package:flutter/material.dart';

import 'router.dart';
import 'theme/theme.dart';

class EconoMiaApp extends StatelessWidget {
  const EconoMiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EconoMia',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // Light only for now. The dark palette is worked out in SaColors.dark but
      // deliberately unwired — see the note there.
      routerConfig: router,
    );
  }
}
