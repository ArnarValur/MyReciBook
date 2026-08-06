// Grocery engine (feasibility §6.3, design 4a): duplicate merge, per-store
// aisle memory, live recipe membership. Pure Dart: no Flutter imports.
//
// Grocery is app-private working state (T3 decision), not a recipe file —
// constraint 3 (user-owned files) governs recipes only.
//
// Quantities are never lost: same normalized name + same unit sums, anything
// else is kept side by side. `name` keeps the user's original text (½ ⅓ é
// arrive from recipes — technical rule 7 heritage; display never mangles them).

import 'recipe.dart';

/// Merge key: lowercase, trim, collapse whitespace, strip trailing
/// punctuation. Unicode-safe — diacritics and vulgar fractions pass through.
String normalizeName(String raw) => raw
    .toLowerCase()
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim()
    .replaceAll(RegExp(r'[.,;:!]+$'), '')
    .trim();

String _singularWord(String w) {
  if (w.length > 3 && w.endsWith('ies')) return '${w.substring(0, w.length - 3)}y';
  if (w.length > 3 && w.endsWith('oes')) return w.substring(0, w.length - 2);
  if (w.endsWith('ss') || w.length < 2) return w;
  if (w.endsWith('s')) return w.substring(0, w.length - 1);
  return w;
}

/// "lemons" → "lemon", "cherry tomatoes" → "cherry tomato". Used for the
/// default-category lookup and for merge suggestions ("Same thing?").
String singularizeKey(String key) =>
    key.split(' ').map(_singularWord).join(' ');

// ---------------------------------------------------------------------------
// Categories (aisles)

/// Stock aisles per design 4a — only Produce and Pantry are designed; every
/// other aisle is user-created and carries the "your aisle" pin chip.
abstract final class GroceryCategories {
  static const String produce = 'Produce';
  static const String pantry = 'Pantry';
  static const List<String> stock = [produce, pantry];

  /// Unmapped ingredients land in Pantry.
  static const String fallback = pantry;

  static bool isStock(String category) => stock.contains(category);

  /// Section order per the 4a mock: Produce, user aisles, Pantry last.
  static int compare(String a, String b) {
    int rank(String c) => c == produce ? 0 : (c == pantry ? 2 : 1);
    final byRank = rank(a) - rank(b);
    return byRank != 0 ? byRank : a.compareTo(b);
  }
}

/// Processed forms ("tomato paste", "garlic powder") are Pantry even when a
/// word matches produce — matched on the singularized last word.
const Set<String> _pantryFormWords = {
  'paste', 'powder', 'sauce', 'starch', 'syrup', 'vinegar', 'flake', 'oil',
};

const Set<String> _produceWords = {
  'apple', 'avocado', 'banana', 'basil', 'beet', 'berry', 'blueberry',
  'broccoli', 'cabbage', 'carrot', 'cauliflower', 'celery', 'chili',
  'cilantro', 'coriander', 'corn', 'cucumber', 'dill', 'eggplant', 'fennel',
  'garlic', 'ginger', 'grape', 'herb', 'kale', 'leek', 'lemon', 'lemongrass',
  'lettuce', 'lime', 'mango', 'mint', 'mushroom', 'onion', 'orange',
  'parsley', 'pea', 'pear', 'pepper', 'potato', 'pumpkin', 'radish',
  'raspberry', 'rosemary', 'salad', 'scallion', 'shallot', 'spinach',
  'squash', 'strawberry', 'thyme', 'tomato', 'zucchini',
};

/// Staples auto-dim instead of nagging (4a annotation 2). Matched on the
/// singularized key; never auto-added with a quantity.
const Set<String> kStapleKeys = {
  'salt', 'pepper', 'black pepper', 'salt and pepper', 'olive oil',
  'vegetable oil', 'sunflower oil', 'cooking oil', 'oil', 'water',
};

/// Built-in mapping; anything unrecognized falls back to Pantry.
String defaultCategoryFor(String key) {
  final singular = singularizeKey(key);
  if (_produceWords.contains(singular)) return GroceryCategories.produce;
  final words = singular.split(' ');
  if (_pantryFormWords.contains(words.last)) return GroceryCategories.fallback;
  for (final word in words) {
    if (_produceWords.contains(word)) return GroceryCategories.produce;
  }
  return GroceryCategories.fallback;
}

/// User overrides (remembered corrections) ALWAYS beat the built-in map.
String categoryFor(String key, Map<String, String> overrides) =>
    overrides[key] ?? defaultCategoryFor(key);

// ---------------------------------------------------------------------------
// Quantities

class QtyPart {
  final num? qty;
  final String? unit;

  const QtyPart({this.qty, this.unit});

  factory QtyPart.fromJson(Map<String, dynamic> json) =>
      QtyPart(qty: json['qty'] as num?, unit: json['unit'] as String?);

  Map<String, dynamic> toJson() => {'qty': qty, 'unit': unit};
}

final _fractions = <double, String>{
  0.25: '¼', 1 / 3: '⅓', 0.5: '½', 2 / 3: '⅔', 0.75: '¾',
};

/// Integers render bare, common fractions as unicode (½, ⅓…), the rest as a
/// short decimal — sums of extracted fractions come back readable.
String formatQty(num n) {
  final whole = n.truncate();
  final frac = (n - whole).toDouble();
  if (frac.abs() < 0.01) return '$whole';
  for (final e in _fractions.entries) {
    if ((frac - e.key).abs() < 0.02) {
      return whole == 0 ? e.value : '$whole${e.value}';
    }
  }
  var s = n.toStringAsFixed(2);
  while (s.endsWith('0')) {
    s = s.substring(0, s.length - 1);
  }
  if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  return s;
}

// ---------------------------------------------------------------------------
// Item

class GroceryItem {
  final String id;

  /// Display name, original casing and characters intact.
  final String name;
  final String category;
  final bool checked;

  /// Survives recipe removal and list-recipe operations.
  final bool manual;

  /// Dimmed row, no quantity, never nags; tap activates (staple → false).
  final bool staple;

  final List<QtyPart> manualParts;

  /// recipeId → that recipe's quantity contributions. Membership drives
  /// idempotent re-add and per-recipe subtraction.
  final Map<String, List<QtyPart>> recipeParts;

  const GroceryItem({
    required this.id,
    required this.name,
    required this.category,
    this.checked = false,
    this.manual = false,
    this.staple = false,
    this.manualParts = const [],
    this.recipeParts = const {},
  });

  String get key => normalizeName(name);

  Set<String> get sourceRecipeIds => recipeParts.keys.toSet();

  /// Source count for the row caption ("2 recipes").
  int get sourceCount => recipeParts.length;

  /// Same-unit parts summed, different units side by side, qty-less dropped.
  List<QtyPart> get mergedParts {
    final order = <String>[];
    final displayUnit = <String, String?>{};
    final totals = <String, num>{};
    final all = [...recipeParts.values.expand((p) => p), ...manualParts];
    for (final part in all) {
      if (part.qty == null) continue;
      final unitKey = part.unit?.trim().toLowerCase() ?? '';
      if (!totals.containsKey(unitKey)) {
        order.add(unitKey);
        displayUnit[unitKey] = part.unit?.trim();
        totals[unitKey] = 0;
      }
      totals[unitKey] = totals[unitKey]! + part.qty!;
    }
    return [
      for (final u in order) QtyPart(qty: totals[u], unit: displayUnit[u])
    ];
  }

  /// "6" · "400 g" · "2 tbsp + 1 pack". Empty when quantity-less (staples,
  /// raw-only lines) — the row then shows the name alone.
  String get qtyLabel => mergedParts
      .map((p) => p.unit == null || p.unit!.isEmpty
          ? formatQty(p.qty!)
          : '${formatQty(p.qty!)} ${p.unit}')
      .join(' + ');

  GroceryItem copyWith({
    String? name,
    String? category,
    bool? checked,
    bool? manual,
    bool? staple,
    List<QtyPart>? manualParts,
    Map<String, List<QtyPart>>? recipeParts,
  }) =>
      GroceryItem(
        id: id,
        name: name ?? this.name,
        category: category ?? this.category,
        checked: checked ?? this.checked,
        manual: manual ?? this.manual,
        staple: staple ?? this.staple,
        manualParts: manualParts ?? this.manualParts,
        recipeParts: recipeParts ?? this.recipeParts,
      );

  factory GroceryItem.fromJson(Map<String, dynamic> json) => GroceryItem(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String? ?? GroceryCategories.fallback,
        checked: json['checked'] as bool? ?? false,
        manual: json['manual'] as bool? ?? false,
        staple: json['staple'] as bool? ?? false,
        manualParts: [
          for (final p in (json['manual_parts'] as List? ?? []))
            QtyPart.fromJson(p as Map<String, dynamic>)
        ],
        recipeParts: {
          for (final e
              in ((json['recipe_parts'] as Map?) ?? {}).entries)
            e.key as String: [
              for (final p in (e.value as List? ?? []))
                QtyPart.fromJson(p as Map<String, dynamic>)
            ]
        },
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'checked': checked,
        'manual': manual,
        'staple': staple,
        'manual_parts': [for (final p in manualParts) p.toJson()],
        'recipe_parts': {
          for (final e in recipeParts.entries)
            e.key: [for (final p in e.value) p.toJson()]
        },
      };
}

// ---------------------------------------------------------------------------
// List operations (pure — caller persists via GroceryStore)

class GroceryAddResult {
  final List<GroceryItem> items;

  /// Recipe was already on the list → items unchanged (re-add is a no-op).
  final bool alreadyOnList;
  final int addedCount;

  /// Checked-off lines skipped per 3e ("excluded from future adds").
  final int excludedCheckedCount;

  const GroceryAddResult(
      this.items, this.alreadyOnList, this.addedCount, this.excludedCheckedCount);
}

class GroceryUpdateResult {
  final List<GroceryItem> items;

  /// Rows whose displayed quantity changed — powers the receipt banner
  /// ("… — 3 amounts updated.").
  final int changedCount;

  const GroceryUpdateResult(this.items, this.changedCount);
}

({String name, QtyPart part})? _parseIngredient(Ingredient ing, double scale) {
  final name = (ing.item?.trim().isNotEmpty ?? false)
      ? ing.item!.trim()
      : ing.raw.trim();
  if (normalizeName(name).isEmpty) return null;
  return (
    name: name,
    part: QtyPart(
      qty: ing.qty == null ? null : ing.qty! * scale,
      unit: ing.unit?.trim(),
    ),
  );
}

bool recipeOnList(List<GroceryItem> items, String recipeId) =>
    items.any((i) => i.recipeParts.containsKey(recipeId));

/// Distinct recipes feeding the list — header caption "from N planned recipes".
int plannedRecipeCount(List<GroceryItem> items) =>
    items.expand((i) => i.recipeParts.keys).toSet().length;

/// One-tap whole-recipe add (3e footer). Same recipe twice = no-op; lines
/// matching a checked item are excluded; staples land dimmed and quantity-less;
/// remembered merges (aliases) and category corrections apply automatically.
GroceryAddResult addRecipeToList({
  required List<GroceryItem> items,
  required Recipe recipe,
  double scale = 1,
  Map<String, String> categoryOverrides = const {},
  Map<String, String> mergeAliases = const {},
}) {
  if (recipeOnList(items, recipe.id)) {
    return GroceryAddResult(items, true, 0, 0);
  }
  final next = List.of(items);
  var added = 0;
  var excluded = 0;
  for (final ing in recipe.ingredients) {
    final parsed = _parseIngredient(ing, scale);
    if (parsed == null) continue;
    var key = normalizeName(parsed.name);
    key = mergeAliases[key] ?? key;
    final isStaple = kStapleKeys.contains(key) ||
        kStapleKeys.contains(singularizeKey(key));
    final at = next.indexWhere((i) => i.key == key);
    if (at >= 0) {
      final existing = next[at];
      if (existing.checked) {
        excluded++;
        continue;
      }
      if (isStaple && !existing.staple) continue; // user activated it: hands off
      next[at] = existing.copyWith(recipeParts: {
        ...existing.recipeParts,
        recipe.id: [
          ...existing.recipeParts[recipe.id] ?? const <QtyPart>[],
          if (!isStaple) parsed.part,
        ],
      });
      added++;
    } else {
      // Invariant: id == key, and key derives from name — an alias re-apply
      // must display the canonical name the user confirmed, or lookups and
      // row ops diverge (duplicate ids, dead merge button).
      final aliased = key != normalizeName(parsed.name);
      next.add(GroceryItem(
        id: key,
        name: aliased ? key : parsed.name,
        category: categoryFor(key, categoryOverrides),
        staple: isStaple,
        recipeParts: {
          recipe.id: [if (!isStaple) parsed.part]
        },
      ));
      added++;
    }
  }
  return GroceryAddResult(next, false, added, excluded);
}

/// Subtracts one recipe's contribution. Items left with no source and no
/// manual claim disappear; manual items survive with their manual quantity.
List<GroceryItem> removeRecipeFromList(
    List<GroceryItem> items, String recipeId) {
  final next = <GroceryItem>[];
  for (final item in items) {
    if (!item.recipeParts.containsKey(recipeId)) {
      next.add(item);
      continue;
    }
    final remaining = Map.of(item.recipeParts)..remove(recipeId);
    if (remaining.isEmpty && !item.manual) continue;
    next.add(item.copyWith(recipeParts: remaining));
  }
  return next;
}

/// Live re-sync after a plan/servings change (the list is a view, never a
/// snapshot): replaces the recipe's contribution and counts changed amounts.
GroceryUpdateResult updateRecipeOnList({
  required List<GroceryItem> items,
  required Recipe recipe,
  double scale = 1,
  Map<String, String> categoryOverrides = const {},
  Map<String, String> mergeAliases = const {},
}) {
  if (!recipeOnList(items, recipe.id)) {
    return GroceryUpdateResult(items, 0);
  }
  String? labelOf(List<GroceryItem> list, String key) {
    final at = list.indexWhere((i) => i.key == key);
    return at >= 0 ? list[at].qtyLabel : null;
  }

  final touched = <String>{
    for (final i in items)
      if (i.recipeParts.containsKey(recipe.id)) i.key
  };
  final result = addRecipeToList(
    items: removeRecipeFromList(items, recipe.id),
    recipe: recipe,
    scale: scale,
    categoryOverrides: categoryOverrides,
    mergeAliases: mergeAliases,
  );
  for (final i in result.items) {
    if (i.recipeParts.containsKey(recipe.id)) touched.add(i.key);
  }
  var changed = 0;
  for (final key in touched) {
    if (labelOf(items, key) != labelOf(result.items, key)) changed++;
  }
  return GroceryUpdateResult(result.items, changed);
}

/// Manual add (undesigned on 4a — engine support only). Same-key lines fold
/// into the existing item; the item becomes manual so recipe ops never
/// delete it.
List<GroceryItem> addManualItem({
  required List<GroceryItem> items,
  required String name,
  num? qty,
  String? unit,
  String? category,
  Map<String, String> categoryOverrides = const {},
  Map<String, String> mergeAliases = const {},
}) {
  var key = normalizeName(name);
  if (key.isEmpty) return items;
  key = mergeAliases[key] ?? key;
  final part = QtyPart(qty: qty, unit: unit?.trim());
  final at = items.indexWhere((i) => i.key == key);
  if (at >= 0) {
    final next = List.of(items);
    // Re-adding a bought row unchecks it — the intent is "I need it again";
    // a fold that leaves it struck through reads as a swallowed add.
    next[at] = next[at].copyWith(
      checked: false,
      manual: true,
      staple: false,
      manualParts: [...next[at].manualParts, if (qty != null) part],
    );
    return next;
  }
  // Same id == key invariant as addRecipeToList: aliased entries display the
  // canonical name.
  final aliased = key != normalizeName(name);
  return [
    ...items,
    GroceryItem(
      id: key,
      name: aliased ? key : name.trim(),
      category: category ?? categoryFor(key, categoryOverrides),
      manual: true,
      manualParts: [if (qty != null) part],
    ),
  ];
}

/// Typed-entry parse ("2 lemons", "200 g flour", "½ cup rice"): a leading
/// quantity and a small unit set peel off so the merge key stays the bare
/// name — a typed qty in the name would silently defeat the merge engine.
({num? qty, String? unit, String name}) parseManualEntry(String raw) {
  final text = raw.trim();
  final tokens = text.split(RegExp(r'\s+'));
  if (tokens.length < 2) return (qty: null, unit: null, name: text);
  final qty = _parseQtyToken(tokens.first);
  if (qty == null) return (qty: null, unit: null, name: text);
  var rest = tokens.sublist(1);
  String? unit;
  if (rest.length >= 2 && _manualUnits.contains(rest.first.toLowerCase())) {
    unit = rest.first;
    rest = rest.sublist(1);
  }
  return (qty: qty, unit: unit, name: rest.join(' '));
}

const Set<String> _manualUnits = {
  'g', 'kg', 'mg', 'ml', 'dl', 'l', 'tsp', 'tbsp', 'cup', 'cups', 'oz',
  'lb', 'lbs', 'pack', 'packs', 'can', 'cans', 'jar', 'bag', 'box',
  'bottle', 'bunch',
};

num? _parseQtyToken(String t) {
  final direct = num.tryParse(t.replaceAll(',', '.'));
  if (direct != null) return direct;
  final frac = RegExp(r'^(\d+)?([¼⅓½⅔¾])$').firstMatch(t);
  if (frac != null) {
    final whole = num.tryParse(frac.group(1) ?? '') ?? 0;
    const map = {'¼': 0.25, '⅓': 1 / 3, '½': 0.5, '⅔': 2 / 3, '¾': 0.75};
    return whole + map[frac.group(2)]!;
  }
  final slash = RegExp(r'^(\d+)/([1-9]\d*)$').firstMatch(t);
  if (slash != null) {
    return int.parse(slash.group(1)!) / int.parse(slash.group(2)!);
  }
  return null;
}

/// Confirmed "Same thing?" merge: [absorbId] folds into [keepId]. Caller
/// records the alias (absorb.key → keep.key) so it re-applies automatically.
List<GroceryItem> mergeItems(
  List<GroceryItem> items, {
  required String keepId,
  required String absorbId,
}) {
  final keepAt = items.indexWhere((i) => i.id == keepId);
  final absorbAt = items.indexWhere((i) => i.id == absorbId);
  if (keepAt < 0 || absorbAt < 0 || keepAt == absorbAt) return items;
  final keep = items[keepAt];
  final absorb = items[absorbAt];
  final parts = Map.of(keep.recipeParts);
  for (final e in absorb.recipeParts.entries) {
    parts[e.key] = [...parts[e.key] ?? const <QtyPart>[], ...e.value];
  }
  final next = List.of(items);
  next[keepAt] = keep.copyWith(
    manual: keep.manual || absorb.manual,
    staple: keep.staple && absorb.staple,
    checked: keep.checked && absorb.checked,
    manualParts: [...keep.manualParts, ...absorb.manualParts],
    recipeParts: parts,
  );
  next.removeAt(absorbAt);
  return next;
}

/// Canonical id for a keep-apart pair — order-independent.
String mergePairKey(String keyA, String keyB) {
  final sorted = [keyA, keyB]..sort();
  return sorted.join('|');
}

class MergeSuggestion {
  /// Suggested canonical item — its name and aisle survive the merge.
  final GroceryItem keep;
  final GroceryItem absorb;

  const MergeSuggestion(this.keep, this.absorb);

  String get pairKey => mergePairKey(keep.key, absorb.key);

  /// Preview for the button label ("Merge · 6 lemons" = qty + keep.name).
  String get mergedQtyLabel =>
      mergeItems([keep, absorb], keepId: keep.id, absorbId: absorb.id)
          .first
          .qtyLabel;
}

/// Suggest-and-confirm, NEVER silent (4a annotation 1): near-duplicates
/// (singular/plural of the same key) surface as prompts; pairs the user kept
/// apart stay apart.
List<MergeSuggestion> mergeSuggestions(
  List<GroceryItem> items, {
  Set<String> keepApart = const {},
}) {
  final suggestions = <MergeSuggestion>[];
  for (var a = 0; a < items.length; a++) {
    for (var b = a + 1; b < items.length; b++) {
      final ia = items[a], ib = items[b];
      if (ia.staple || ib.staple) continue;
      if (ia.key == ib.key) continue;
      if (singularizeKey(ia.key) != singularizeKey(ib.key)) continue;
      if (keepApart.contains(mergePairKey(ia.key, ib.key))) continue;
      // Keep the plural form (mock keeps "lemons"); tie → list order.
      final keepFirst = ia.key.length >= ib.key.length;
      suggestions.add(
          keepFirst ? MergeSuggestion(ia, ib) : MergeSuggestion(ib, ia));
    }
  }
  return suggestions;
}

List<GroceryItem> toggleChecked(List<GroceryItem> items, String id) => [
      for (final i in items)
        i.id == id ? i.copyWith(checked: !i.checked) : i
    ];

/// "Clear checked": bought rows leave the list; overrides are untouched
/// (they live in a separate file — see GroceryStore).
List<GroceryItem> clearChecked(List<GroceryItem> items) =>
    [for (final i in items) if (!i.checked) i];

/// Recategorize result state ("moved here by you"): caller must also persist
/// the override (item.key → category) so the correction is remembered.
List<GroceryItem> setItemCategory(
        List<GroceryItem> items, String id, String category) =>
    [
      for (final i in items)
        i.id == id ? i.copyWith(category: category) : i
    ];

/// Staple tap-to-activate: becomes a normal (quantity-less) row.
List<GroceryItem> activateStaple(List<GroceryItem> items, String id) => [
      for (final i in items)
        i.id == id && i.staple ? i.copyWith(staple: false) : i
    ];
