// Meal diary file format v1 — one <YYYY-MM-DD>.json per day in the user's own
// storage, the recipe/pantry file stance (arch §3/§4) applied to logging.
// Pure Dart: no Flutter imports in domain/.
//
// THE SNAPSHOT RULE. An entry copies the nutrition it was logged with; it
// never resolves a product at read time. MyFitnessPal can re-resolve because
// its foods live on a server it controls — ours are files the user can edit,
// rescan or delete (the pantry's known dangling-link gap). A diary that
// silently changes last Tuesday's calories because a product was corrected
// today is a diary nobody can trust. `ref` is kept for "edit" and "log again",
// never for arithmetic.
//
// Per-SERVING is stored, not per-entry-total: changing the quantity is then
// one multiply with no rounding drift, and the row still reads exactly what
// the user picked ("2 × 1 dl").

import 'product.dart';

/// Where an entry's numbers came from. Open like Product.source — a future
/// kind must not make an old file unreadable.
abstract final class DiarySources {
  /// Logged from a pantry product; [DiaryEntry.ref] is the product id.
  static const product = 'product';

  /// Logged from a recipe by servings; [DiaryEntry.ref] is the recipe id.
  static const recipe = 'recipe';

  /// Calories (and optionally macros) typed straight in — MFP's Quick Add.
  static const quick = 'quick';
}

class DiaryEntry {
  final String id;
  final String name;
  final String? brand;

  /// One of [DiarySources]. Never validated to a closed set.
  final String source;

  /// Product id or recipe id. Null for quick adds. Display and re-log only —
  /// never read to recompute nutrition (the snapshot rule).
  final String? ref;

  /// What one serving is called: "1 dl", "1 medium (182 g)", "100 g",
  /// "1 serving". Null on a quick add.
  final String? servingLabel;

  /// Weight of ONE serving. Null when the serving has no weight (a recipe
  /// portion, a quick add) — the day can still total calories, just not grams.
  final double? servingGrams;

  /// How many servings. Fractions are normal: 0.5, 1.5, 2.
  final double quantity;

  /// Nutrition of ONE serving, frozen at log time.
  final Nutriments perServing;

  final String? loggedAt;

  const DiaryEntry({
    required this.id,
    required this.name,
    this.brand,
    required this.source,
    this.ref,
    this.servingLabel,
    this.servingGrams,
    required this.quantity,
    required this.perServing,
    this.loggedAt,
  });

  /// What this row contributes to the day.
  Nutriments get total => perServing.scaled(quantity);

  /// Weight eaten, when the serving carries one.
  double? get grams =>
      servingGrams == null ? null : servingGrams! * quantity;

  /// "2 × 1 dl" / "1 dl" / "1.5 servings" — the MFP row subtitle.
  String get servingSummary {
    final label = servingLabel ?? 'serving';
    if (quantity == 1) return label;
    return '${formatQuantity(quantity)} × $label';
  }

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        brand: json['brand'] as String?,
        source: json['source'] as String? ?? DiarySources.product,
        ref: json['ref'] as String?,
        servingLabel: json['serving_label'] as String?,
        servingGrams: (json['serving_grams'] as num?)?.toDouble(),
        quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
        perServing:
            Nutriments.fromJsonOrNull(json['per_serving']) ?? Nutriments(),
        loggedAt: json['logged_at'] as String?,
      );

  /// Absent keys stay absent, the pantry's rule: a quick add must not gain
  /// six empty fields.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (brand != null) 'brand': brand,
        'source': source,
        if (ref != null) 'ref': ref,
        if (servingLabel != null) 'serving_label': servingLabel,
        if (servingGrams != null) 'serving_grams': servingGrams,
        'quantity': quantity,
        'per_serving': perServing.toJson(),
        if (loggedAt != null) 'logged_at': loggedAt,
      };

  DiaryEntry copyWith({
    String? name,
    String? servingLabel,
    double? servingGrams,
    double? quantity,
    Nutriments? perServing,
    bool clearServingGrams = false,
  }) =>
      DiaryEntry(
        id: id,
        name: name ?? this.name,
        brand: brand,
        source: source,
        ref: ref,
        servingLabel: servingLabel ?? this.servingLabel,
        servingGrams:
            clearServingGrams ? null : (servingGrams ?? this.servingGrams),
        quantity: quantity ?? this.quantity,
        perServing: perServing ?? this.perServing,
        loggedAt: loggedAt,
      );
}

/// A named slot on the day — Breakfast, Lunch, Dinner, Snacks by default, but
/// the NAME is stored per day, not an index into a settings list. Renaming
/// "Snacks" to "Kvöldmatur" tomorrow must not rewrite what yesterday said.
class DiaryMeal {
  final String name;
  final List<DiaryEntry> entries;

  const DiaryMeal({required this.name, this.entries = const []});

  Nutriments get total => sumNutriments([for (final e in entries) e.total]);

  bool get isEmpty => entries.isEmpty;

  factory DiaryMeal.fromJson(Map<String, dynamic> json) => DiaryMeal(
        name: json['name'] as String,
        entries: [
          for (final e in (json['entries'] as List? ?? []))
            DiaryEntry.fromJson(e as Map<String, dynamic>)
        ],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'entries': [for (final e in entries) e.toJson()],
      };

  DiaryMeal withEntries(List<DiaryEntry> next) =>
      DiaryMeal(name: name, entries: next);
}

class DiaryDay {
  static const int currentSchemaVersion = 1;

  final int schemaVersion;

  /// YYYY-MM-DD. Also the filename stem — [isDiaryDate] guards both.
  final String date;

  /// Only meals that hold something. An empty slot is drawn by the UI from
  /// the user's meal-name setting, never stored — a day of four empty
  /// headings is not a fact worth a file.
  final List<DiaryMeal> meals;

  const DiaryDay({
    this.schemaVersion = currentSchemaVersion,
    required this.date,
    this.meals = const [],
  });

  DiaryDay.empty(this.date)
      : schemaVersion = currentSchemaVersion,
        meals = const [];

  Nutriments get total => sumNutriments([for (final m in meals) m.total]);

  bool get isEmpty => meals.every((m) => m.isEmpty);

  int get entryCount =>
      meals.fold(0, (sum, m) => sum + m.entries.length);

  DiaryMeal? meal(String name) {
    for (final m in meals) {
      if (m.name == name) return m;
    }
    return null;
  }

  factory DiaryDay.fromJson(Map<String, dynamic> json) => DiaryDay(
        schemaVersion: json['schema_version'] as int? ?? currentSchemaVersion,
        date: json['date'] as String,
        meals: [
          for (final m in (json['meals'] as List? ?? []))
            DiaryMeal.fromJson(m as Map<String, dynamic>)
        ],
      );

  Map<String, dynamic> toJson() => {
        'schema_version': schemaVersion,
        'date': date,
        'meals': [for (final m in meals) m.toJson()],
      };

  // --- pure ops: every one returns a new day, the GroceryModel stance
  // (pure op → store persist → notify). ---

  /// Appends to [mealName], creating the meal at the end when it is not on
  /// the day yet. Order within a meal is log order, like MFP.
  DiaryDay addEntry(String mealName, DiaryEntry entry) {
    final next = [for (final m in meals) m];
    final at = next.indexWhere((m) => m.name == mealName);
    if (at < 0) {
      next.add(DiaryMeal(name: mealName, entries: [entry]));
    } else {
      next[at] = next[at].withEntries([...next[at].entries, entry]);
    }
    return DiaryDay(schemaVersion: schemaVersion, date: date, meals: next);
  }

  /// Drops the entry wherever it sits, and drops the meal if that emptied it.
  DiaryDay removeEntry(String entryId) {
    final next = <DiaryMeal>[];
    for (final m in meals) {
      final kept = [for (final e in m.entries) if (e.id != entryId) e];
      if (kept.isNotEmpty) next.add(m.withEntries(kept));
    }
    return DiaryDay(schemaVersion: schemaVersion, date: date, meals: next);
  }

  /// Replaces an entry in place — quantity edits keep their row position.
  DiaryDay updateEntry(DiaryEntry entry) {
    final next = [
      for (final m in meals)
        m.withEntries([
          for (final e in m.entries) if (e.id == entry.id) entry else e
        ])
    ];
    return DiaryDay(schemaVersion: schemaVersion, date: date, meals: next);
  }

  /// MFP's "move to another meal": remove, then append to the target.
  DiaryDay moveEntry(String entryId, String toMeal) {
    DiaryEntry? found;
    for (final m in meals) {
      for (final e in m.entries) {
        if (e.id == entryId) found = e;
      }
    }
    if (found == null) return this;
    return removeEntry(entryId).addEntry(toMeal, found);
  }

  /// MFP's "copy to date". Ids are regenerated by [newIds] so the copy is its
  /// own row — deleting the original must not delete the copy.
  DiaryDay copyMealFrom(DiaryDay other, String mealName,
      {required String Function(int index) newIds}) {
    final from = other.meal(mealName);
    if (from == null || from.isEmpty) return this;
    var day = this;
    var i = 0;
    for (final e in from.entries) {
      day = day.addEntry(
          mealName,
          DiaryEntry(
            id: newIds(i++),
            name: e.name,
            brand: e.brand,
            source: e.source,
            ref: e.ref,
            servingLabel: e.servingLabel,
            servingGrams: e.servingGrams,
            quantity: e.quantity,
            perServing: e.perServing,
            loggedAt: e.loggedAt,
          ));
    }
    return day;
  }
}

/// The default four, MFP's own slots. Stored in settings so the user can
/// rename or add — the day file always carries the name it was logged under.
const List<String> defaultMealNames = [
  'Breakfast',
  'Lunch',
  'Dinner',
  'Snacks',
];

/// Sums nutrient maps by key. The union, not an intersection: a day of one
/// product that lists iron and one that doesn't still totals the iron it has.
/// That is honest for macros (every label prints them) and deliberately
/// optimistic for micros — the UI says "from N of M items" where it matters.
Nutriments sumNutriments(List<Nutriments> parts) {
  final totals = <String, double>{};
  for (final part in parts) {
    part.values.forEach((key, value) {
      totals[key] = (totals[key] ?? 0) + value;
    });
  }
  return Nutriments.fromMap(totals);
}

/// Log-time snapshot of a pantry product at a chosen serving.
DiaryEntry entryFromProduct(
  Product product,
  Serving serving, {
  required double quantity,
  required String id,
  String? loggedAt,
}) =>
    DiaryEntry(
      id: id,
      name: product.name,
      brand: product.brand,
      source: DiarySources.product,
      ref: product.id,
      servingLabel: serving.label,
      servingGrams: serving.grams,
      quantity: quantity,
      // Storage is per 100 g; one serving is grams/100 of that.
      perServing:
          (product.nutriments ?? Nutriments()).scaled(serving.grams / 100),
      loggedAt: loggedAt,
    );

/// MFP's Quick Add: calories now, details never. Macros optional.
DiaryEntry quickAddEntry({
  required String id,
  required double kcal,
  String name = 'Quick add',
  double? fat,
  double? carbs,
  double? protein,
  double quantity = 1,
  String? loggedAt,
}) =>
    DiaryEntry(
      id: id,
      name: name,
      source: DiarySources.quick,
      servingLabel: 'entry',
      quantity: quantity,
      perServing: Nutriments(
          kcal: kcal, fat: fat, carbs: carbs, protein: protein),
      loggedAt: loggedAt,
    );

/// YYYY-MM-DD, and a real calendar date — the filename stem is derived from
/// this, so "2026-13-45" must never reach the store (arch §7 confinement).
bool isDiaryDate(String date) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) return false;
  final parsed = DateTime.tryParse(date);
  if (parsed == null) return false;
  return diaryDate(parsed) == date;
}

/// A DateTime as the diary's day key, local time — the day you ate it.
String diaryDate(DateTime when) {
  final m = when.month.toString().padLeft(2, '0');
  final d = when.day.toString().padLeft(2, '0');
  return '${when.year.toString().padLeft(4, '0')}-$m-$d';
}

/// Quantities read like MFP's: 1, 1.5, 0.25 — never "1.0".
String formatQuantity(double q) {
  if (q == q.roundToDouble()) return q.round().toString();
  var s = q.toStringAsFixed(2);
  s = s.replaceFirst(RegExp(r'0+$'), '');
  return s.replaceFirst(RegExp(r'\.$'), '');
}

/// Problems in a complete day file — validate.dart's fileProblems pattern.
/// Never save a file that doesn't validate (architecture §7).
List<String> diaryProblems(Map<String, dynamic> json) {
  final problems = <String>[];
  for (final field in ['schema_version', 'date']) {
    if (!json.containsKey(field) || json[field] == null) {
      problems.add('missing:$field');
    }
  }
  final version = json['schema_version'];
  if (version != null && version != 1) {
    problems.add('unknown schema_version $version');
  }
  final date = json['date'];
  if (date is! String || !isDiaryDate(date)) problems.add('bad date');
  final meals = json['meals'];
  if (meals != null && meals is! List) problems.add('meals not a list');
  if (meals is List) {
    for (final meal in meals) {
      if (meal is! Map) {
        problems.add('meal not an object');
        continue;
      }
      if (meal['name'] is! String || (meal['name'] as String).isEmpty) {
        problems.add('meal without a name');
      }
      final entries = meal['entries'];
      if (entries is! List) {
        problems.add('meal entries not a list');
        continue;
      }
      for (final entry in entries) {
        if (entry is! Map) {
          problems.add('entry not an object');
          continue;
        }
        if (entry['id'] is! String || (entry['id'] as String).isEmpty) {
          problems.add('entry without an id');
        }
        if (entry['name'] is! String || (entry['name'] as String).isEmpty) {
          problems.add('entry without a name');
        }
      }
    }
  }
  return problems;
}
