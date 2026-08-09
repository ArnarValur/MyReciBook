// App-private grocery persistence (design 4a). Two files in app-support,
// injectable paths per the AppSettings pattern: the list state, and the
// remembered corrections (aisle overrides + merge memory). Corrections live
// in their own file so clearing the list never forgets them.
//
// Writes are temp-file + rename (atomic enough); corrupt/missing files start
// clean, never crash (architecture §7 stance).

import 'dart:convert';
import 'dart:io';

import '../domain/grocery.dart';
import 'atomic_file.dart';

class GroceryStore {
  GroceryStore._(this._listFile, this._overridesFile, this._items,
      this._categories, this._mergeAliases, this._keepApart);

  final File _listFile;
  final File _overridesFile;
  List<GroceryItem> _items;
  final Map<String, String> _categories;
  final Map<String, String> _mergeAliases;
  final Set<String> _keepApart;

  static Future<GroceryStore> load({
    required File listFile,
    required File overridesFile,
  }) async {
    var items = <GroceryItem>[];
    try {
      if (await listFile.exists()) {
        final data =
            jsonDecode(await listFile.readAsString()) as Map<String, dynamic>;
        items = _healInvariant([
          for (final i in (data['items'] as List? ?? []))
            GroceryItem.fromJson(i as Map<String, dynamic>)
        ]);
      }
    } catch (_) {
      items = []; // corrupt list: start clean
    }
    var categories = <String, String>{};
    var aliases = <String, String>{};
    var keepApart = <String>{};
    try {
      if (await overridesFile.exists()) {
        final data = jsonDecode(await overridesFile.readAsString())
            as Map<String, dynamic>;
        categories = {
          for (final e in ((data['categories'] as Map?) ?? {}).entries)
            e.key as String: e.value as String
        };
        aliases = {
          for (final e in ((data['merge_aliases'] as Map?) ?? {}).entries)
            e.key as String: e.value as String
        };
        keepApart = {
          for (final p in (data['keep_apart'] as List? ?? [])) p as String
        };
      }
    } catch (_) {
      categories = {};
      aliases = {};
      keepApart = {}; // corrupt overrides: defaults
    }
    return GroceryStore._(
        listFile, overridesFile, items, categories, aliases, keepApart);
  }

  List<GroceryItem> get items => List.unmodifiable(_items);

  /// normalized key → aisle; precedence over the built-in map, always.
  Map<String, String> get categoryOverrides => Map.unmodifiable(_categories);

  /// alias key → canonical key; confirmed merges, re-applied on future adds.
  Map<String, String> get mergeAliases => Map.unmodifiable(_mergeAliases);

  /// mergePairKey() values the user chose to keep apart.
  Set<String> get keepApartPairs => Set.unmodifiable(_keepApart);

  Future<void> saveItems(List<GroceryItem> next) async {
    _items = List.of(next);
    await _writeJson(_listFile, {
      'version': 1,
      'items': [for (final i in _items) i.toJson()],
    });
  }

  /// Wipes the list; overrides file untouched — corrections survive.
  Future<void> clearList() => saveItems(const []);

  Future<void> setCategoryOverride(String key, String category) {
    _categories[key] = category;
    return _writeOverrides();
  }

  Future<void> removeCategoryOverride(String key) {
    _categories.remove(key);
    return _writeOverrides();
  }

  Future<void> confirmMerge(
      {required String canonicalKey, required String aliasKey}) {
    _mergeAliases[aliasKey] = canonicalKey;
    return _writeOverrides();
  }

  Future<void> recordKeepApart(String keyA, String keyB) {
    _keepApart.add(mergePairKey(keyA, keyB));
    return _writeOverrides();
  }

  Future<void> _writeOverrides() => _writeJson(_overridesFile, {
        'version': 1,
        'categories': _categories,
        'merge_aliases': _mergeAliases,
        'keep_apart': [..._keepApart],
      });

  // Per-path serialization lives in writeStringAtomic: overlapping saves
  // (rapid check-offs fire un-awaited saves through GroceryModel) queue
  // instead of interleaving on the shared tmp.
  Future<void> _writeJson(File file, Object data) =>
      writeStringAtomic(file, jsonEncode(data));

  /// Engine invariant: id == key (key derives from name). Rows written by the
  /// pre-fix alias bug can violate it or duplicate ids — heal on load: rename
  /// diverged rows to their id, fold duplicate ids into one row.
  static List<GroceryItem> _healInvariant(List<GroceryItem> raw) {
    final byId = <String, GroceryItem>{};
    final order = <String>[];
    for (var i in raw) {
      if (i.key != i.id) {
        i = GroceryItem(
          id: i.id,
          name: i.id,
          category: i.category,
          checked: i.checked,
          manual: i.manual,
          staple: i.staple,
          manualParts: i.manualParts,
          recipeParts: i.recipeParts,
        );
      }
      final prev = byId[i.id];
      if (prev == null) {
        byId[i.id] = i;
        order.add(i.id);
        continue;
      }
      final parts = Map.of(prev.recipeParts);
      for (final e in i.recipeParts.entries) {
        parts[e.key] = [...parts[e.key] ?? const <QtyPart>[], ...e.value];
      }
      byId[i.id] = prev.copyWith(
        checked: prev.checked && i.checked,
        manual: prev.manual || i.manual,
        staple: prev.staple && i.staple,
        manualParts: [...prev.manualParts, ...i.manualParts],
        recipeParts: parts,
      );
    }
    return [for (final id in order) byId[id]!];
  }
}
