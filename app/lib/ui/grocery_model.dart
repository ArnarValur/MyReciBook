// Grocery view-model (D3: ChangeNotifier + Provider, nothing more). Every
// mutation is a pure engine op → store persist → notify. A null store (test
// seam without grocery wiring) degrades to in-memory state — never crashes.

import 'package:flutter/foundation.dart';

import '../data/grocery_store.dart';
import '../domain/grocery.dart';
import '../domain/recipe.dart';

class GroceryModel extends ChangeNotifier {
  GroceryModel(GroceryStore? store)
      : _store = store,
        _items = store?.items ?? const [],
        _aliases = Map.of(store?.mergeAliases ?? const {}),
        _keepApart = Set.of(store?.keepApartPairs ?? const {});

  final GroceryStore? _store;
  List<GroceryItem> _items;
  final Map<String, String> _aliases;
  final Set<String> _keepApart;
  String? _receipt;

  List<GroceryItem> get items => List.unmodifiable(_items);

  /// Sync receipt banner text; null = no banner.
  String? get receipt => _receipt;

  int get plannedCount => plannedRecipeCount(_items);

  bool get hasStaples => _items.any((i) => i.staple);

  /// Header caption — live count + provenance ("9 items · from 3 planned
  /// recipes"); "0 items" is the empty state's honest caption.
  String get caption {
    final n = _items.length;
    if (n == 0) return '0 items';
    final base = '$n item${n == 1 ? '' : 's'}';
    final p = plannedCount;
    if (p == 0) return base;
    return '$base · from $p planned recipe${p == 1 ? '' : 's'}';
  }

  /// Suggest-and-confirm, never silent (4a annotation 1).
  List<MergeSuggestion> get suggestions =>
      mergeSuggestions(_items, keepApart: _keepApart);

  bool isOnList(String recipeId) => recipeOnList(_items, recipeId);

  Future<GroceryAddResult> addRecipe(Recipe recipe, {double scale = 1}) async {
    final res = addRecipeToList(
      items: _items,
      recipe: recipe,
      scale: scale,
      mergeAliases: _aliases,
    );
    if (!res.alreadyOnList) await _commit(res.items);
    return res;
  }

  Future<void> removeRecipe(String recipeId) =>
      _commit(removeRecipeFromList(_items, recipeId));

  /// Live re-sync (the list is a view, never a snapshot). No caller in the
  /// alpha — the servings stepper is post-alpha — but the receipt banner
  /// plumbing is here for its arrival. changedCount > 0 raises the banner.
  Future<GroceryUpdateResult> syncRecipe(Recipe recipe,
      {double scale = 1, num? servings}) async {
    final res = updateRecipeOnList(
      items: _items,
      recipe: recipe,
      scale: scale,
      mergeAliases: _aliases,
    );
    if (res.changedCount > 0) {
      final n = res.changedCount;
      final bumped =
          servings == null ? '' : ' bumped to ${formatQty(servings)} servings';
      _receipt =
          '${recipe.title}$bumped — $n amount${n == 1 ? '' : 's'} updated.';
      await _commit(res.items);
    }
    return res;
  }

  void dismissReceipt() {
    _receipt = null;
    notifyListeners();
  }

  /// Row tap: staples activate (4a "tap activates"), everything else toggles
  /// the checkbox. Both persisted.
  Future<void> toggleItem(String id) async {
    final at = _items.indexWhere((i) => i.id == id);
    if (at < 0) return;
    await _commit(_items[at].staple
        ? activateStaple(_items, id)
        : toggleChecked(_items, id));
  }

  Future<void> clearCompleted() => _commit(clearChecked(_items));

  /// Swipe-to-delete a single row. The caller snapshots [items] first for the
  /// undo bar — a mis-swipe mid-shop must cost nothing.
  Future<void> removeItem(String id) => _commit([
        for (final i in _items)
          if (i.id != id) i
      ]);

  /// Empty the list. Merge aliases deliberately SURVIVE (they live in their
  /// own file) — the memory is the product, the list is the errand.
  Future<void> clearAll() => _commit(const []);

  /// Undo door for the two destructive ops above.
  Future<void> restore(List<GroceryItem> snapshot) => _commit(snapshot);

  /// Typed entries parse a leading qty/unit ("2 lemons") so the merge key
  /// stays the bare name — qty in the key would defeat the merge engine.
  Future<void> addManual(String name) {
    final parsed = parseManualEntry(name);
    return _commit(addManualItem(
      items: _items,
      name: parsed.name,
      qty: parsed.qty,
      unit: parsed.unit,
      mergeAliases: _aliases,
    ));
  }

  /// Confirmed merges are remembered and re-applied on future adds.
  Future<void> confirmMerge(MergeSuggestion s) async {
    _aliases[s.absorb.key] = s.keep.key;
    await _guard(() =>
        _store?.confirmMerge(canonicalKey: s.keep.key, aliasKey: s.absorb.key));
    await _commit(mergeItems(_items, keepId: s.keep.id, absorbId: s.absorb.id));
  }

  Future<void> keepApart(MergeSuggestion s) async {
    _keepApart.add(s.pairKey);
    await _guard(() => _store?.recordKeepApart(s.keep.key, s.absorb.key));
    notifyListeners();
  }

  /// Plain-text export (share circle → copy): unchecked, activated rows by
  /// aisle. Dimmed staples and bought rows stay out of a shared list.
  String exportText() {
    final sections = <String, List<GroceryItem>>{};
    for (final i in _items) {
      if (i.checked || i.staple) continue;
      sections.putIfAbsent(i.category, () => []).add(i);
    }
    final order = sections.keys.toList()..sort(GroceryCategories.compare);
    final b = StringBuffer();
    for (final c in order) {
      b.writeln(c);
      for (final i in sections[c]!) {
        b.writeln(
            i.qtyLabel.isEmpty ? '- ${i.name}' : '- ${i.qtyLabel} ${i.name}');
      }
    }
    return b.toString().trimRight();
  }

  Future<void> _commit(List<GroceryItem> next) async {
    _items = List.of(next);
    notifyListeners();
    await _guard(() => _store?.saveItems(next));
  }

  Future<void> _guard(Future<void>? Function() op) async {
    try {
      await op();
    } catch (_) {} // storage best-effort — never a crash mid-shop (§7 stance)
  }
}
