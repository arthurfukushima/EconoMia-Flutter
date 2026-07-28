import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/app_location.dart';
import 'models/list_item.dart';
import 'models/shopping_list.dart';

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
  static const _productSearchHistoryKey = 'economia.productSearchHistory';
  static const _miaPointsKey = 'economia.miaPoints';
  static const _questsKey = 'economia.quests';
  static const _searchHistoryMax = 8;

  /// The list index and which one is on screen.
  static const _listsKey = 'economia.lists';
  static const _activeListKey = 'economia.activeListId';

  /// Pre-multi-list layout: one flat item array and one global store pick.
  /// Read once by `_ensureListsInitialized`, never written again.
  static const _shoppingListKey = 'economia.shoppingList';
  static const _listStoreKey = 'economia.listStore';

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

  int get miaPoints => _prefs.getInt(_miaPointsKey) ?? 0;

  Future<void> setMiaPoints(int points) => _prefs.setInt(_miaPointsKey, points < 0 ? 0 : points);

  String? get questsJson => _prefs.getString(_questsKey);

  Future<void> setQuestsJson(String value) => _prefs.setString(_questsKey, value);

  // ---------------------------------------------------------------------------
  // Shopping lists
  //
  // Several named lists ("Churrasco", "Casa"). The index lives under
  // [_listsKey]; each list's items and store pick get their own keys, so
  // editing a 40-item list rewrites one blob and switching lists reads one.
  // The two `_legacy*` keys are the pre-multi-list single-list layout, read
  // exactly once by [_ensureListsInitialized] and then left alone.
  // ---------------------------------------------------------------------------

  static String _itemsKeyFor(String id) => 'economia.shoppingList.$id';
  static String _storeKeyFor(String id) => 'economia.listStore.$id';

  /// Creates the list index, carrying a pre-multi-list user's existing items
  /// and store pick into a "Minha Lista" so an upgrade never looks like the
  /// app ate their list. A fresh install just gets one empty default. Either
  /// way there is always at least one list afterwards.
  ///
  /// **Awaited once in `main()`**, before `runApp`: every read below is
  /// synchronous, and they can only be synchronous if the index is known to
  /// exist by the time a screen builds. Idempotent, so calling it again (a
  /// test, a hot restart) is free.
  ///
  /// The legacy keys are deliberately *not* deleted — a downgrade still finds
  /// them, and they cost a few hundred bytes.
  Future<void> initLists() async {
    if (_prefs.getString(_listsKey) != null) return;

    final id = _newId();
    final legacyItems = _prefs.getString(_shoppingListKey);
    await _prefs.setString(
      _listsKey,
      jsonEncode([
        ShoppingList(id: id, name: 'Minha Lista', createdAt: DateTime.now().millisecondsSinceEpoch)
            .toJson(),
      ]),
    );
    await _prefs.setString(_itemsKeyFor(id), legacyItems ?? '[]');
    await _prefs.setString(_activeListKey, id);

    final legacyStore = _prefs.getString(_listStoreKey);
    if (legacyStore != null) await _prefs.setString(_storeKeyFor(id), legacyStore);
  }

  /// Ids only have to be unique on this device, so a timestamp plus a random
  /// suffix does it — no uuid dependency for a local key.
  static String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(4294967296).toRadixString(36)}';

  /// Every list, creation order. Never empty after [initLists].
  List<ShoppingList> get lists => _readLists();

  List<ShoppingList> _readLists() {
    final raw = _prefs.getString(_listsKey);
    if (raw == null) return const [];
    try {
      return [
        for (final e in jsonDecode(raw) as List)
          ShoppingList.fromJson(e as Map<String, dynamic>),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writeLists(List<ShoppingList> lists) =>
      _prefs.setString(_listsKey, jsonEncode([for (final l in lists) l.toJson()]));

  Future<ShoppingList> createList(String name) async {
    await initLists();
    final list = ShoppingList(
      id: _newId(),
      name: name.trim().isEmpty ? 'Nova lista' : name.trim(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _writeLists([..._readLists(), list]);
    await _prefs.setString(_itemsKeyFor(list.id), '[]');
    await setActiveListId(list.id);
    return list;
  }

  Future<void> renameList(String id, String newName) async {
    final name = newName.trim();
    if (name.isEmpty) return;
    await _writeLists([
      for (final l in _readLists()) if (l.id == id) l.copyWith(name: name) else l,
    ]);
  }

  /// Removes the list and its item/store keys. Returns the id that should now
  /// be active.
  ///
  /// Deleting the last list creates a fresh default rather than leaving the
  /// app listless — every screen downstream assumes one exists. The active id
  /// is read *before* the index shrinks: afterwards [activeListId]'s own
  /// self-heal could no longer find the deleted id and would report the wrong
  /// answer to "was this the active one?".
  Future<String> deleteList(String id) async {
    final activeBefore = activeListId;
    final remaining = [for (final l in _readLists()) if (l.id != id) l];
    await _writeLists(remaining);
    await _prefs.remove(_itemsKeyFor(id));
    await _prefs.remove(_storeKeyFor(id));

    if (activeBefore != id) return activeBefore;
    if (remaining.isNotEmpty) {
      await setActiveListId(remaining.first.id);
      return remaining.first.id;
    }
    return (await createList('Minha Lista')).id;
  }

  /// The list being shown.
  ///
  /// Falls back to the first list when the stored id points at one that no
  /// longer exists (a restored backup, a delete that raced) — reading is a
  /// hot path on every build, so it reports the healed answer rather than
  /// writing it back; the next [setActiveListId] persists it. Empty string
  /// only before [initLists], which `main()` awaits.
  String get activeListId {
    final id = _prefs.getString(_activeListKey);
    final lists = _readLists();
    if (id != null && lists.any((l) => l.id == id)) return id;
    return lists.isNotEmpty ? lists.first.id : '';
  }

  Future<void> setActiveListId(String id) => _prefs.setString(_activeListKey, id);

  /// One list's items, cached prices and all.
  ///
  /// Written on every edit, so it survives a kill mid-list. A blob that can no
  /// longer be decoded reads as an empty list rather than taking the app down
  /// on every launch — the same call the saved location makes.
  List<ListItem> itemsOf(String listId) {
    final raw = _prefs.getString(_itemsKeyFor(listId));
    if (raw == null) return const [];
    try {
      return [
        for (final e in jsonDecode(raw) as List)
          ListItem.fromJson(e as Map<String, dynamic>),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> setItemsOf(String listId, List<ListItem> items) => _prefs.setString(
        _itemsKeyFor(listId),
        jsonEncode([for (final i in items) i.toJson()]),
      );

  /// The market this list is being priced at, or null for "cheapest per item".
  /// Per list, and kept apart from [currentStore]: standing in a shop and
  /// planning a trip to one are different answers, set on different screens.
  String? listStoreOf(String listId) => _prefs.getString(_storeKeyFor(listId));

  Future<void> setListStoreOf(String listId, String? cod) => cod == null
      ? _prefs.remove(_storeKeyFor(listId))
      : _prefs.setString(_storeKeyFor(listId), cod);

  /// Recent "buscar por nome" searches, newest first — a repeat lookup
  /// ("Toddy" every week) becomes one tap instead of retyping.
  List<String> get productSearchHistory {
    final raw = _prefs.getStringList(_productSearchHistoryKey);
    return raw ?? const [];
  }

  /// Case-insensitive de-dupe: re-searching a term just moves it back to the
  /// front rather than listing it twice.
  Future<void> addProductSearchHistory(String name) {
    final term = name.trim();
    if (term.isEmpty) return Future.value();
    final rest = productSearchHistory.where((t) => t.toLowerCase() != term.toLowerCase());
    final next = [term, ...rest].take(_searchHistoryMax).toList();
    return _prefs.setStringList(_productSearchHistoryKey, next);
  }

  Future<void> removeProductSearchHistory(String name) => _prefs.setStringList(
        _productSearchHistoryKey,
        productSearchHistory.where((t) => t != name).toList(),
      );
}
