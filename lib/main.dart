import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/prefs.dart';
import 'data/receipt_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Scanning a receipt and reading it back are one-handed, portrait moments.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Both of these are disk reads that happen exactly once. Awaiting them here
  // costs a few milliseconds under the native splash and buys every screen a
  // synchronous handle instead of an AsyncValue it would have to unwrap.
  final prefs = Prefs(await SharedPreferences.getInstance());
  final db = await openAppDatabase();

  runApp(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        receiptRepositoryProvider.overrideWithValue(ReceiptRepository(db)),
      ],
      child: const EconoMiaApp(),
    ),
  );
}
