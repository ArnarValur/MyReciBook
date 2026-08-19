// Per-serving nutrition for a recipe, from the user's own pantry links —
// the nutrition track's calculator (open since the plan was written, the
// piece that lets a recipe be logged in the diary like a product).
//
// The honesty rule everything here serves: NEVER present a partial sum as
// the truth. Every result carries how many ingredients it actually covered,
// and the UI must say "estimated from N of M" — a recipe with one linked
// ingredient out of nine is not "210 kcal per serving", it is a hint.
//
// Grams are the bridge, as everywhere: nutriments are per 100 g, so an
// ingredient contributes (grams / 100) × the linked product's numbers.
// Pure Dart: no Flutter imports in domain/.

import 'ingredient_parse.dart';
import 'product.dart';
import 'recipe.dart';

/// Grams per canonical mass unit.
const _massGrams = <String, double>{
  'mg': 0.001,
  'g': 1,
  'kg': 1000,
  'oz': 28.35,
  'lb': 453.6,
};

/// Millilitres per canonical volume unit (kitchen-sane, matching units.dart:
/// 1 cup = 240 ml).
const _volumeMl = <String, double>{
  'ml': 1,
  'cl': 10,
  'dl': 100,
  'l': 1000,
  'tsp': 5,
  'tbsp': 15,
  'cup': 240,
};

/// Density in g/ml for the staples people actually measure by volume — the
/// plan's density-table item, deliberately short. Matched by substring on
/// the ingredient item and the product name; no match means a volume line
/// stays uncovered rather than guessed (volume stays volume until then).
const densityTable = <String, double>{
  'water': 1.0,
  'milk': 1.03,
  'cream': 1.0,
  'yogurt': 1.03,
  'yoghurt': 1.03,
  'oil': 0.92,
  'butter': 0.91,
  'flour': 0.53,
  'sugar': 0.85,
  'honey': 1.42,
  'syrup': 1.33,
  'oat': 0.41,
  'rice': 0.85,
  'cocoa': 0.52,
  'salt': 1.22,
  'breadcrumb': 0.42,
  'ketchup': 1.14,
  'mayonnaise': 0.91,
  'soy sauce': 1.15,
  'stock': 1.0,
  'broth': 1.0,
  'wine': 0.99,
  'beer': 1.01,
  'juice': 1.05,
  // Norwegian staples — the pantry is scanned in a Norwegian shop even when
  // the recipe is English. Substring match, first hit wins, so 'melk' sits
  // before 'mel': 'mellommelk' must read as milk, never as flour ('mel'
  // still catches compounds like 'hvetemel').
  'melk': 1.03,
  'fløte': 1.0,
  'smør': 0.91,
  'mel': 0.53,
  'sukker': 0.85,
  'honning': 1.42,
};

double? _densityFor(String item, Product? product) {
  final haystacks = [
    item.toLowerCase(),
    if (product != null) product.name.toLowerCase(),
  ];
  for (final hay in haystacks) {
    for (final e in densityTable.entries) {
      if (hay.contains(e.key)) return e.value;
    }
  }
  return null;
}

/// The effective quantity of an ingredient: the extractor's parse when it
/// made one, else a local parse of the raw line (link imports and manual
/// recipes store no parse — the file is never rewritten for this).
ParsedQty effectiveQty(Ingredient ing) {
  if (ing.qty != null) {
    return ParsedQty(
        qty: ing.qty,
        unit: ing.unit?.toLowerCase(),
        item: ing.item ?? ing.raw);
  }
  return parseIngredientLine(ing.raw);
}

/// Grams of this ingredient, or null when it honestly can't be known:
/// no quantity, an unknown unit, a volume with no density match, or a
/// count of something whose product declares no per-piece weight.
double? ingredientGrams(Ingredient ing, Product? product) {
  final parsed = effectiveQty(ing);
  final qty = parsed.qty?.toDouble();
  if (qty == null || qty <= 0) return null;

  final unit = parsed.unit;
  if (unit != null) {
    final mass = _massGrams[unit];
    if (mass != null) return qty * mass;
    final ml = _volumeMl[unit];
    if (ml != null) {
      final density = _densityFor(parsed.item, product);
      return density == null ? null : qty * ml * density;
    }
    return null; // pinch, dash, can, clove… no defined weight
  }

  // Unitless count — "2 bananas". Only a product that declares what one
  // piece weighs can answer; guessing a banana is how diaries go wrong.
  final perPiece = product?.servings.isNotEmpty == true
      ? product!.servings.first.grams
      : null;
  return perPiece == null ? null : qty * perPiece;
}

class RecipeNutrition {
  /// Sum over the covered ingredients, for the whole recipe.
  final Nutriments total;

  /// Ingredients that contributed: linked to a product with nutriments AND
  /// resolvable to grams.
  final int covered;
  final int ingredientCount;

  /// Recipe servings as a number, when the file has one ("4", "Serves 4").
  final num? servings;

  const RecipeNutrition({
    required this.total,
    required this.covered,
    required this.ingredientCount,
    this.servings,
  });

  bool get isEmpty => covered == 0;
  bool get isComplete => covered == ingredientCount && ingredientCount > 0;

  /// Per-serving numbers — null when the recipe never says how many it
  /// serves. Dividing by an invented 4 would be a lie with decimals.
  Nutriments? get perServing {
    final s = servings;
    if (s == null || s <= 0) return null;
    return total.scaled(1 / s);
  }
}

/// The servings count: the parsed amount, else the first number in the raw
/// text ("Serves 4" → 4).
num? servingsAmount(Recipe recipe) {
  final s = recipe.servings;
  if (s == null) return null;
  if (s.amount != null && s.amount! > 0) return s.amount;
  final m = RegExp(r'\d+(?:[.,]\d+)?').firstMatch(s.raw ?? '');
  if (m == null) return null;
  final parsed = num.tryParse(m.group(0)!.replaceAll(',', '.'));
  return parsed != null && parsed > 0 ? parsed : null;
}

/// The whole calculation. [products] is the pantry keyed by product id —
/// exactly what an ingredient's productRef points at.
RecipeNutrition recipeNutrition(
    Recipe recipe, Map<String, Product> products) {
  var total = Nutriments();
  var covered = 0;
  for (final ing in recipe.ingredients) {
    final product = ing.productRef == null ? null : products[ing.productRef];
    if (product == null) continue;
    final nutriments = product.nutriments;
    if (nutriments == null || nutriments.isEmpty) continue;
    final grams = ingredientGrams(ing, product);
    if (grams == null) continue;
    total = total.plus(nutriments.scaled(grams / 100));
    covered++;
  }
  return RecipeNutrition(
    total: total,
    covered: covered,
    ingredientCount: recipe.ingredients.length,
    servings: servingsAmount(recipe),
  );
}
