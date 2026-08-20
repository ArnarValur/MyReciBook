// Auto-category for pantry products — Open Food Facts' classification mapped
// to the shelf groups a human sorts by. Pure Dart: no Flutter imports.
//
// Two OFF signals, checked in order:
//   1. categories_tags — the deep taxonomy (en:berries, en:chickens, ...).
//      Checked FIRST so a chicken fillet lands in Chicken, not just Meat.
//   2. food_groups_tags — the PNNS groups (~40 fine + ~10 broad). Fine
//      entries beat broad ones because OFF lists broad first, so the LAST
//      match in the list wins there.
//
// The result is ONE tag string written into Product.tags — same free-string
// mechanism the hand picker uses, no new schema. No match → null: the UI
// renders untagged products under "Other", the file stays clean.

import 'product.dart';

/// The canonical shelf categories auto-tagging can produce. The chip row and
/// icon/colour table (phase 2) key off these exact strings. Hand-typed custom
/// tags live beside them as equals — this list is not a cage.
const List<String> productCategories = [
  'Dairy',
  'Cheese',
  'Eggs',
  'Meat',
  'Chicken',
  'Fish',
  'Veggies',
  'Fruit',
  'Berries',
  'Nuts & seeds',
  'Bread',
  'Pasta & grains',
  'Breakfast',
  'Oils',
  'Sauces',
  'Spices',
  'Sweets',
  'Snacks',
  'Drinks',
  'Coffee & tea',
  'Wine & beer',
  'Meals',
];

/// Deep-taxonomy overrides, checked against every entry of categories_tags.
/// Only the specific wins Arnar asked for by name (berries, chicken, seeds,
/// wine) plus the ones PNNS is blind to (spices) — NOT a mirror of the whole
/// OFF taxonomy. Order matters: first hit wins, most specific first.
const Map<String, String> _categoryTagOverrides = {
  'en:berries': 'Berries',
  'en:chickens': 'Chicken',
  'en:chicken': 'Chicken',
  'en:turkeys': 'Chicken',
  'en:seeds': 'Nuts & seeds',
  'en:nuts': 'Nuts & seeds',
  'en:wines': 'Wine & beer',
  'en:beers': 'Wine & beer',
  'en:spices': 'Spices',
  'en:herbs': 'Spices',
  'en:cod-liver-oils': 'Oils',
  'en:fish-oils': 'Oils',
  'en:vegetable-oils': 'Oils',
  'en:olive-oils': 'Oils',
};

/// PNNS fine groups (food_groups_tags level 2) → shelf category.
const Map<String, String> _fineGroups = {
  'en:milk-and-yogurt': 'Dairy',
  'en:dairy-desserts': 'Dairy',
  'en:ice-cream': 'Dairy',
  'en:plant-based-milk-substitutes': 'Dairy',
  'en:cheese': 'Cheese',
  'en:eggs': 'Eggs',
  'en:meat': 'Meat',
  'en:meat-other-than-poultry': 'Meat',
  'en:processed-meat': 'Meat',
  'en:offals': 'Meat',
  'en:poultry': 'Chicken',
  'en:fish-and-seafood': 'Fish',
  'en:lean-fish': 'Fish',
  'en:fatty-fish': 'Fish',
  'en:vegetables': 'Veggies',
  'en:legumes': 'Veggies',
  'en:potatoes': 'Veggies',
  'en:soups': 'Meals',
  'en:fruits': 'Fruit',
  'en:dried-fruits': 'Fruit',
  'en:nuts': 'Nuts & seeds',
  'en:bread': 'Bread',
  'en:cereals': 'Pasta & grains',
  'en:breakfast-cereals': 'Breakfast',
  'en:fats': 'Oils',
  'en:dressings-and-sauces': 'Sauces',
  'en:sweets': 'Sweets',
  'en:chocolate-products': 'Sweets',
  'en:biscuits-and-cakes': 'Sweets',
  'en:pastries': 'Sweets',
  'en:salty-and-fatty-products': 'Snacks',
  'en:appetizers': 'Snacks',
  'en:fruit-juices': 'Drinks',
  'en:fruit-nectars': 'Drinks',
  'en:sweetened-beverages': 'Drinks',
  'en:unsweetened-beverages': 'Drinks',
  'en:artificially-sweetened-beverages': 'Drinks',
  'en:waters-and-flavored-waters': 'Drinks',
  'en:teas-and-herbal-teas-and-coffees': 'Coffee & tea',
  'en:alcoholic-beverages': 'Wine & beer',
  'en:one-dish-meals': 'Meals',
  'en:pizza-pies-and-quiches': 'Meals',
  'en:sandwiches': 'Meals',
};

/// Category-taxonomy fallback, for the products that carry categories_tags
/// but NO food groups at all — common on Nordic products ("Svenske
/// kjøttboller" has en:meats-and-their-products and empty food_groups_tags).
/// Checked last, walked specific-first like the overrides.
const Map<String, String> _broadCategoryTags = {
  'en:meats-and-their-products': 'Meat',
  'en:meats': 'Meat',
  'en:meat-preparations': 'Meat',
  'en:poultries': 'Chicken',
  'en:dairies': 'Dairy',
  'en:milks': 'Dairy',
  'en:yogurts': 'Dairy',
  'en:fermented-milk-products': 'Dairy',
  'en:cheeses': 'Cheese',
  'en:eggs': 'Eggs',
  'en:seafood': 'Fish',
  'en:fishes': 'Fish',
  'en:vegetables': 'Veggies',
  'en:legumes': 'Veggies',
  'en:fruits': 'Fruit',
  'en:breads': 'Bread',
  'en:pastas': 'Pasta & grains',
  'en:rices': 'Pasta & grains',
  'en:flours': 'Pasta & grains',
  'en:cereals-and-their-products': 'Pasta & grains',
  'en:breakfast-cereals': 'Breakfast',
  'en:flakes': 'Breakfast',
  'en:fats': 'Oils',
  'en:oils': 'Oils',
  'en:sauces': 'Sauces',
  'en:condiments': 'Sauces',
  'en:sweet-spreads': 'Sweets',
  'en:jams': 'Sweets',
  'en:desserts': 'Sweets',
  'en:chocolates': 'Sweets',
  'en:candies': 'Sweets',
  'en:biscuits-and-cakes': 'Sweets',
  'en:sweet-snacks': 'Sweets',
  'en:salty-snacks': 'Snacks',
  'en:snacks': 'Snacks',
  'en:coffees': 'Coffee & tea',
  'en:teas': 'Coffee & tea',
  'en:alcoholic-beverages': 'Wine & beer',
  'en:beverages': 'Drinks',
  'en:meals': 'Meals',
  'en:soups': 'Meals',
  'en:pizzas': 'Meals',
};

/// PNNS broad groups (level 1) — the fallback when no fine group matched.
const Map<String, String> _broadGroups = {
  'en:milk-and-dairy-products': 'Dairy',
  'en:fish-meat-eggs': 'Meat',
  'en:fruits-and-vegetables': 'Veggies',
  'en:cereals-and-potatoes': 'Pasta & grains',
  'en:fat-and-sauces': 'Sauces',
  'en:sugary-snacks': 'Sweets',
  'en:salty-snacks': 'Snacks',
  'en:beverages': 'Drinks',
  'en:composite-foods': 'Meals',
};

/// The shelf category for a product, from OFF's classification. Null when
/// OFF gave nothing usable — the caller writes no tag then.
String? categoryForOff({
  List<String> categoriesTags = const [],
  List<String> foodGroupsTags = const [],
}) {
  for (final tag in categoriesTags) {
    final hit = _categoryTagOverrides[tag];
    if (hit != null) return hit;
  }
  // OFF lists food groups broad-first; walking backwards prefers the fine one.
  for (final tag in foodGroupsTags.reversed) {
    final hit = _fineGroups[tag];
    if (hit != null) return hit;
  }
  for (final tag in foodGroupsTags.reversed) {
    final hit = _broadGroups[tag];
    if (hit != null) return hit;
  }
  // Last resort: the category taxonomy alone, specific entries first —
  // OFF orders categories_tags broad → specific.
  for (final tag in categoriesTags.reversed) {
    final hit = _broadCategoryTags[tag];
    if (hit != null) return hit;
  }
  return null;
}

/// The section untagged products render under. Never written to a file —
/// a render label, not data (an empty tags list stays empty on disk).
const String otherCategory = 'Other';

/// Emoji per canonical category — rendered as text, so Android draws them
/// with its system Noto Color Emoji font (Arnar's icon call, 2026-08-20).
/// Custom tags have none and render name-only; null means "no emoji".
const Map<String, String> _categoryEmoji = {
  'Dairy': '🥛',
  'Cheese': '🧀',
  'Eggs': '🥚',
  'Meat': '🥩',
  'Chicken': '🍗',
  'Fish': '🐟',
  'Veggies': '🥦',
  'Fruit': '🍎',
  'Berries': '🫐',
  'Nuts & seeds': '🥜',
  'Bread': '🍞',
  'Pasta & grains': '🍝',
  'Breakfast': '🥣',
  'Oils': '🫒',
  'Sauces': '🥫',
  'Spices': '🧂',
  'Sweets': '🍫',
  'Snacks': '🍿',
  'Drinks': '🥤',
  'Coffee & tea': '☕',
  'Wine & beer': '🍷',
  'Meals': '🍲',
  otherCategory: '🏷️',
};

String? categoryEmoji(String category) => _categoryEmoji[category];

/// "🥛 Dairy" for canonical categories, just "Godteri" for custom tags.
String categoryLabel(String category) {
  final emoji = _categoryEmoji[category];
  return emoji == null ? category : '$emoji $category';
}

/// Shelf order for category names: canonical categories in [productCategories]
/// order, then custom tags alphabetically, [otherCategory] always last.
int compareCategories(String a, String b) {
  if (a == b) return 0;
  if (a == otherCategory) return 1;
  if (b == otherCategory) return -1;
  final ia = productCategories.indexOf(a);
  final ib = productCategories.indexOf(b);
  if (ia >= 0 && ib >= 0) return ia.compareTo(ib);
  if (ia >= 0) return -1; // canonical before custom
  if (ib >= 0) return 1;
  return a.toLowerCase().compareTo(b.toLowerCase());
}

/// The grouped shelf: products bucketed by their FIRST tag (the primary
/// category), buckets in [compareCategories] order, untagged last under
/// [otherCategory]. Alphabetical by name inside a bucket, so the view is
/// stable — never the scan sequence.
List<(String, List<Product>)> groupByCategory(List<Product> products) {
  final buckets = <String, List<Product>>{};
  for (final p in products) {
    final key = p.tags.isEmpty ? otherCategory : p.tags.first;
    (buckets[key] ??= []).add(p);
  }
  final names = buckets.keys.toList()..sort(compareCategories);
  return [
    for (final name in names)
      (
        name,
        buckets[name]!
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()))
      ),
  ];
}

/// Chip counts, membership-based: a product tagged both "Dairy" and
/// "Breakfast" counts in each chip it belongs to. Untagged products count
/// under [otherCategory]. Keys come back in [compareCategories] order.
Map<String, int> categoryCounts(List<Product> products) {
  final counts = <String, int>{};
  for (final p in products) {
    if (p.tags.isEmpty) {
      counts[otherCategory] = (counts[otherCategory] ?? 0) + 1;
      continue;
    }
    for (final tag in p.tags) {
      counts[tag] = (counts[tag] ?? 0) + 1;
    }
  }
  final names = counts.keys.toList()..sort(compareCategories);
  return {for (final n in names) n: counts[n]!};
}
