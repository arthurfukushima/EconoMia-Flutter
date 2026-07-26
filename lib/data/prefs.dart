import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/app_location.dart';

/// Overridden in `main()`, for the same reason as the repository: shared
/// preferences load asynchronously exactly once, and nothing downstream should
/// have to await that.
final prefsProvider = Provider<Prefs>(
  (ref) => throw UnimplementedError('overridden in main()'),
);

/// The handful of scalars that live outside the database.
///
/// Everything with structure — receipts, offers — is in sembast. What is here
/// is small, single-valued and read at startup: the search location now, and
/// the shopping list, Mia points, quest state and current store as the phases
/// that own them land. Keys stay `economia.*` to match the reference app's
/// storage, so nothing collides with a plugin's own preferences.
class Prefs {
  Prefs(this._prefs);

  final SharedPreferences _prefs;

  static const _locationKey = 'economia.location';
  static const _currentStoreKey = 'economia.currentStore';

  /// The saved search centre, or null when the user has never set one — which
  /// is a real state the UI has copy for, not an error.
  AppLocation? get location {
    final raw = _prefs.getString(_locationKey);
    if (raw == null) return null;
    try {
      return AppLocation.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // A location we can no longer read is the same as not having one; asking
      // for the CEP again beats crashing on every launch forever.
      return null;
    }
  }

  Future<void> setLocation(AppLocation location) =>
      _prefs.setString(_locationKey, jsonEncode(location.toJson()));

  /// The market the user last said they were standing in, so returning to
  /// Mercado remembers it across app restarts.
  String? get currentStore => _prefs.getString(_currentStoreKey);

  Future<void> setCurrentStore(String? cod) => cod == null
      ? _prefs.remove(_currentStoreKey)
      : _prefs.setString(_currentStoreKey, cod);
}
