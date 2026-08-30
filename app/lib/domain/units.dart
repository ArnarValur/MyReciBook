// Unit display conversion (nutrition plan, decided 2026-08-18): local math at
// render time, never the LLM, and the recipe file always keeps the original
// text — this converts what a screen SHOWS, nothing it stores. Pure Dart: no
// Flutter imports in domain/.
//
// Volume→volume and weight→weight only ("2 cups" → "480 ml"). Turning cups of
// flour into grams needs a per-ingredient density table — that's the plan's
// separate open item, not this file. Unconvertible units (stick, pinch, egg)
// pass through untouched by construction: no pattern matches them.
// Teaspoons and tablespoons are universal across both systems (Arnar,
// 2026-08-19 S21 pass: "tsp → 10 ml" is noise) — metric mode leaves them
// alone; imperial mode still prints small ml AS spoons, which only adds.
//
// Kitchen-sane rounding, not lab math: 1 cup = 240 ml, °C snaps to 5,
// °F snaps to the 25s an oven dial actually has.

enum UnitSystem { asWritten, metric, imperial }

/// 'metric' / 'imperial' → the system; anything else (null, corrupt) →
/// as-written, the show-what-the-recipe-said default.
UnitSystem parseUnitSystem(String? v) => switch (v) {
      'metric' => UnitSystem.metric,
      'imperial' => UnitSystem.imperial,
      _ => UnitSystem.asWritten,
    };

String unitSystemName(UnitSystem s) => switch (s) {
      UnitSystem.metric => 'metric',
      UnitSystem.imperial => 'imperial',
      UnitSystem.asWritten => 'as_written',
    };

/// Rewrite every quantity+unit occurrence in [text] into [target]'s units.
/// As-written returns [text] untouched. Metric mode only touches US tokens,
/// imperial mode only metric tokens — already-native text passes through.
String convertUnits(String text, UnitSystem target) => switch (target) {
      UnitSystem.asWritten => text,
      UnitSystem.metric => _toMetric(text),
      UnitSystem.imperial => _toImperial(text),
    };

// ---------------------------------------------------------------------------
// Quantity parsing — "2", "2.5", "2,5", "1/2", "8 1/2", "½", "1½", "1 ½".

const _vulgar = {
  '½': 0.5,
  '⅓': 1 / 3,
  '⅔': 2 / 3,
  '¼': 0.25,
  '¾': 0.75,
  '⅛': 0.125,
  '⅜': 0.375,
  '⅝': 0.625,
  '⅞': 0.875,
};

const _numPattern = r'(?:\d+\s+\d+\s*/\s*\d+' // 8 1/2
    r'|\d+\s*/\s*\d+' // 1/2
    r'|\d+[.,]\d+' // 2.5 / 2,5
    r'|\d+\s*[½⅓⅔¼¾⅛⅜⅝⅞]' // 1½, 1 ½
    r'|[½⅓⅔¼¾⅛⅜⅝⅞]' // ½
    r'|\d+)';

double _qty(String s) {
  final t = s.trim();
  final vulgarAt = t.split('').indexWhere(_vulgar.containsKey);
  if (vulgarAt >= 0) {
    final whole = t.substring(0, vulgarAt).trim();
    return (whole.isEmpty ? 0 : double.parse(whole)) + _vulgar[t[vulgarAt]]!;
  }
  if (t.contains('/')) {
    final parts = t.split(RegExp(r'[\s/]+'));
    return parts.length == 3
        ? double.parse(parts[0]) + double.parse(parts[1]) / double.parse(parts[2])
        : double.parse(parts[0]) / double.parse(parts[1]);
  }
  return double.parse(t.replaceAll(',', '.'));
}

/// 240 → "240", 1.2 → "1.2" — whole numbers drop the decimal.
String _fmt(double v) {
  final r = (v * 10).roundToDouble() / 10;
  return r == r.roundToDouble() ? '${r.round()}' : '$r';
}

double _roundTo(double v, num step) => (v / step).round() * step.toDouble();

// ---------------------------------------------------------------------------
// The ratios themselves. One table per kind, read by the rewriting below AND
// by the numeric helpers at the foot of the file — a second table would drift
// from this one the first time a factor is corrected. Thresholds and rounding
// steps stay where they are used: those are display policy, not ratios.
//
// A couple of keys (cl, mg) have no pattern in the rewriting regexes — a pack
// printed in centilitres is reachable only through the numeric path.

/// Millilitres in one of each volume unit. Spoons are here because a spoon IS
/// a measurable amount; the "spoons stay spoons" rule at the top of the file
/// is about what an ingredient line SHOWS, not about arithmetic.
const _mlPer = <String, double>{
  'ml': 1,
  'cl': 10,
  'dl': 100,
  'l': 1000,
  'tsp': 5,
  'tbsp': 15,
  'floz': 30,
  'cup': 240,
  'pint': 475,
  'quart': 950,
  'gallon': 3800,
};

/// Grams in one of each weight unit.
const _gPer = <String, double>{
  'mg': 0.001,
  'g': 1,
  'kg': 1000,
  'oz': 28.35,
  'lb': 454, // kitchen-sane, not 453.592
};

// ---------------------------------------------------------------------------
// US → metric.

final _fahrenheit = RegExp(
    '($_numPattern)\\s*(?:°\\s*F|degrees?\\s+F(?:ahrenheit)?)(?![A-Za-z])');

// "8-inch pan", "2 inch overhang", '9 in.' — hyphen or space required before
// the word so bare "in" never matches prose.
final _inches = RegExp('($_numPattern)[-\\s](?:inch(?:es)?|in\\.)(?![A-Za-z])',
    caseSensitive: false);

final _usUnit = RegExp(
    '($_numPattern)\\s*'
    '(fl\\.?\\s*oz\\.?|fluid\\s+ounces?'
    '|cups?|pints?|quarts?|gallons?|gal\\.?'
    '|ounces?|oz\\.?|pounds?|lbs?\\.?)'
    '(?![A-Za-z])',
    caseSensitive: false);

String _toMetric(String text) => text
    .replaceAllMapped(_fahrenheit, (m) {
      final c = _roundTo((_qty(m[1]!) - 32) * 5 / 9, 5);
      return '${_fmt(c)}°C';
    })
    .replaceAllMapped(_inches, (m) {
      final cm = _qty(m[1]!) * 2.54;
      return '${_fmt(_roundTo(cm, cm < 2 ? 0.5 : 1))} cm';
    })
    .replaceAllMapped(_usUnit, (m) {
      final q = _qty(m[1]!);
      return switch (_normUs(m[2]!)) {
        'floz' => _ml(q * _mlPer['floz']!),
        'cup' => _ml(q * _mlPer['cup']!),
        'pint' => _ml(q * _mlPer['pint']!),
        'quart' => _ml(q * _mlPer['quart']!),
        'gallon' => _ml(q * _mlPer['gallon']!),
        'oz' => _g(q * _gPer['oz']!),
        'lb' => _g(_roundTo(q * _gPer['lb']!, 10)),
        _ => m[0]!, // unreachable — every pattern branch is mapped
      };
    });

String _normUs(String u) {
  final s = u.toLowerCase().replaceAll('.', '').replaceAll(RegExp(r'\s+'), '');
  if (s.startsWith('fl')) return 'floz';
  if (s.startsWith('cup')) return 'cup';
  if (s.startsWith('pin')) return 'pint';
  if (s.startsWith('quart')) return 'quart';
  if (s.startsWith('gal')) return 'gallon';
  if (s.startsWith('oun') || s == 'oz') return 'oz';
  return 'lb'; // pounds / lb / lbs
}

String _ml(double ml) =>
    ml >= 1000 ? '${_fmt(ml / 1000)} l' : '${_fmt(_roundTo(ml, 0.5))} ml';

String _g(double g) {
  final r = _roundTo(g, g < 20 ? 1 : 5);
  return r >= 1000 ? '${_fmt(r / 1000)} kg' : '${_fmt(r)} g';
}

// ---------------------------------------------------------------------------
// Metric → US.

final _celsius =
    RegExp('($_numPattern)\\s*(?:°\\s*C|degrees?\\s+C(?:elsius)?)(?![A-Za-z])');

final _metricUnit = RegExp(
    '($_numPattern)\\s*'
    '(kg|kilograms?|grams?|g'
    '|ml|milliliters?|millilitres?|dl|deciliters?|decilitres?'
    '|liters?|litres?|l'
    '|cm|centimeters?|centimetres?|mm)'
    '(?![A-Za-z])',
    caseSensitive: false);

String _toImperial(String text) => text
    .replaceAllMapped(_celsius, (m) {
      final f = _roundTo(_qty(m[1]!) * 9 / 5 + 32, 25); // oven dials count in 25s
      return '${_fmt(f)}°F';
    })
    .replaceAllMapped(_metricUnit, (m) {
      final q = _qty(m[1]!);
      return switch (_normMetric(m[2]!)) {
        'g' => _oz(q),
        'kg' => _oz(q * _gPer['kg']!),
        'ml' => _usVolume(q),
        'dl' => _usVolume(q * _mlPer['dl']!),
        'l' => _usVolume(q * _mlPer['l']!),
        // Half-inch snap: a 20 cm pan IS the 8-inch pan, not "7¾ in".
        'cm' => '${_frac(q / 2.54, 2)} in',
        'mm' => '${_frac(q / 25.4, 4)} in',
        _ => m[0]!, // unreachable — every pattern branch is mapped
      };
    });

String _normMetric(String u) {
  final s = u.toLowerCase();
  if (s.startsWith('kg') || s.startsWith('kilo')) return 'kg';
  if (s.startsWith('g')) return 'g';
  if (s.startsWith('ml') || s.startsWith('milli')) return 'ml';
  if (s.startsWith('dl') || s.startsWith('deci')) return 'dl';
  if (s.startsWith('l')) return 'l';
  if (s.startsWith('cm') || s.startsWith('centi')) return 'cm';
  return 'mm';
}

String _oz(double g) {
  final oz = g / _gPer['oz']!;
  if (oz >= 16) return '${_frac(oz / 16, 4)} lb';
  return oz < 1 ? '${_fmt(oz)} oz' : '${_frac(oz, 4)} oz';
}

String _usVolume(double ml) {
  if (ml < 15) return '${_frac(ml / _mlPer['tsp']!, 4)} tsp';
  if (ml < 60) return '${_frac(ml / _mlPer['tbsp']!, 2)} tbsp';
  final cups = ml / _mlPer['cup']!;
  final label = cups > 1.125 ? 'cups' : 'cup';
  return '${_frac(cups, 4)} $label';
}

/// Nearest kitchen fraction (quarters/halves plus thirds), printed vulgar:
/// 1.54 → "1½", 0.33 → "⅓". Rounds to a whole when the fraction lands on 0.
String _frac(double v, int denominator) {
  final fractions = [0.25, 1 / 3, 0.5, 2 / 3, 0.75];
  const glyphs = ['¼', '⅓', '½', '⅔', '¾'];
  var best = v.roundToDouble();
  var bestGlyph = '';
  for (var i = 0; i < fractions.length; i++) {
    if (denominator == 2 && fractions[i] != 0.5) continue;
    final candidate = v.floorToDouble() + fractions[i];
    if ((candidate - v).abs() < (best - v).abs()) {
      best = candidate;
      bestGlyph = glyphs[i];
    }
  }
  if (bestGlyph.isEmpty) {
    final w = best.round();
    return '${w == 0 ? 1 : w}'; // never print a bare 0 quantity
  }
  final whole = best.floor();
  return whole == 0 ? bestGlyph : '$whole$bestGlyph';
}

// ---------------------------------------------------------------------------
// Numbers instead of text — what the grocery list's package-size math needs
// (nutrition plan: "package-size math in the grocery list"). Same tables as
// the rewriting above, so a pack and a recipe line agree on what a litre is.

/// Every spelling we accept → the key the ratio tables use. Strict on
/// purpose: "package", "clove" and "pinch" are units to a cook, they simply
/// have no size, and inventing one is worse than staying quiet.
const _unitNames = <String, String>{
  'mg': 'mg', 'milligram': 'mg', 'milligrams': 'mg',
  'g': 'g', 'gram': 'g', 'grams': 'g', 'gramme': 'g', 'grammes': 'g',
  'kg': 'kg', 'kilo': 'kg', 'kilos': 'kg', 'kilogram': 'kg',
  'kilograms': 'kg', 'kilogramme': 'kg', 'kilogrammes': 'kg',
  'oz': 'oz', 'ounce': 'oz', 'ounces': 'oz',
  'lb': 'lb', 'lbs': 'lb', 'pound': 'lb', 'pounds': 'lb',
  'ml': 'ml', 'milliliter': 'ml', 'milliliters': 'ml',
  'millilitre': 'ml', 'millilitres': 'ml',
  'cl': 'cl', 'centiliter': 'cl', 'centiliters': 'cl',
  'centilitre': 'cl', 'centilitres': 'cl',
  'dl': 'dl', 'deciliter': 'dl', 'deciliters': 'dl',
  'decilitre': 'dl', 'decilitres': 'dl',
  'l': 'l', 'liter': 'l', 'liters': 'l', 'litre': 'l', 'litres': 'l',
  'fl oz': 'floz', 'floz': 'floz', 'fluid ounce': 'floz',
  'fluid ounces': 'floz',
  'cup': 'cup', 'cups': 'cup',
  'pt': 'pint', 'pint': 'pint', 'pints': 'pint',
  'qt': 'quart', 'quart': 'quart', 'quarts': 'quart',
  'gal': 'gallon', 'gallon': 'gallon', 'gallons': 'gallon',
  'tsp': 'tsp', 'teaspoon': 'tsp', 'teaspoons': 'tsp',
  'tbsp': 'tbsp', 'tbs': 'tbsp', 'tablespoon': 'tbsp',
  'tablespoons': 'tbsp',
};

/// Spelling → table key; null for anything we do not convert. Case, dots and
/// doubled spaces are noise ("Fl. Oz." is fl oz).
String? canonicalUnit(String? raw) {
  final s = (raw ?? '')
      .toLowerCase()
      .replaceAll('.', '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return s.isEmpty ? null : _unitNames[s];
}

/// [qty] of [unit] as one number in its kind's base — grams for a weight,
/// millilitres for a volume — plus which base that was, because a gram must
/// never be divided by a millilitre. Null when the unit is not one we
/// convert; the caller then does nothing rather than guessing.
({double amount, String base})? baseAmount(num qty, String? unit) {
  final key = canonicalUnit(unit);
  if (key == null) return null;
  final ml = _mlPer[key];
  if (ml != null) return (amount: qty.toDouble() * ml, base: 'ml');
  final g = _gPer[key];
  if (g != null) return (amount: qty.toDouble() * g, base: 'g');
  return null;
}

/// A pack size read off a product's printed quantity — the SIZE field, which
/// arrives from Open Food Facts as free text ("500 g", "1,5 L", "6 x 33 cl").
class PackSize {
  /// What ONE pack holds, in [unit]: a 6 × 33 cl pack holds 198 cl.
  final double amount;

  /// Table key ([canonicalUnit]'s output), never the printed spelling.
  final String unit;

  /// Items inside the pack — 1 normally, 6 for "6 x 33 cl". Display only:
  /// [amount] already covers the whole pack.
  final int units;

  const PackSize({required this.amount, required this.unit, this.units = 1});
}

// "6 x 33 cl" | "500 g" | "1,5 L" | "250ml" — an optional multipack count, a
// number, a unit, and nothing else. A size with words in it ("500 g net",
// "1 kg (2 x 500 g)") is a size we cannot read: reading it wrong would put
// the wrong number of bags in someone's trolley.
final _packSizePattern = RegExp(
    r'^(?:(\d+)\s*[x×]\s*)?(\d+(?:[.,]\d+)?)\s*([a-z][a-z. ]*)$',
    caseSensitive: false);

/// The printed size as a number we can divide by, or null — quietly — for
/// anything else. A bare "500" carries no unit and stays unread.
PackSize? parsePackSize(String? printed) {
  final text = (printed ?? '')
      .replaceAll('℮', '') // EU estimated-quantity mark: packaging, not data
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final m = _packSizePattern.firstMatch(text);
  if (m == null) return null;
  final unit = canonicalUnit(m[3]);
  final each = double.tryParse(m[2]!.replaceAll(',', '.'));
  final count = m[1] == null ? 1 : int.tryParse(m[1]!);
  if (unit == null || each == null || each <= 0) return null;
  if (count == null || count <= 0) return null;
  return PackSize(amount: each * count, unit: unit, units: count);
}
