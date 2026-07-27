import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/app_config.dart';
import 'core/staples.dart';
import 'data/prefs.dart';
import 'data/receipt_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Scanning a receipt and reading it back are one-handed, portrait moments.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // All three are one-off reads. Awaiting them here costs a few milliseconds
  // under the native splash and buys every screen a synchronous handle
  // instead of an AsyncValue it would have to unwrap. Config comes first
  // because the API client is built from it.
  final config = await AppConfig.load();
  // The pt-BR grocery lexicon: what a term is *sold as*, which is what decides
  // whether the 5 in "Arroz 5kg" is five kilos or the size of one bag.
  final staples = await Staples.load();
  final prefs = Prefs(await SharedPreferences.getInstance());
  // Creates the shopping-list index (migrating a pre-multi-list user's items
  // into it) before anything reads a list — every read downstream is
  // synchronous and assumes the index exists.
  await prefs.initLists();
  final db = await openAppDatabase();

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        staplesProvider.overrideWithValue(staples),
        prefsProvider.overrideWithValue(prefs),
        receiptRepositoryProvider.overrideWithValue(ReceiptRepository(db)),
      ],
      child: const EconoMiaApp(),
    ),
  );
}
