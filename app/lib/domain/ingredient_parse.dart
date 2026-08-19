// Deterministic quantity parse for one ingredient line — "2 dl milk" →
// (2, 'dl', 'milk'). Local math only, never the LLM (the unit-toggle rule,
// 2026-08-18, applied to parsing): a parse we can't explain is a parse we
// can't trust in a calorie count.
//
// Used at COMPUTE time, not import time: recipe files keep their raw lines
// untouched, and lines the extractor already parsed (qty/unit/item set) are
// never re-parsed. This is the fallback that makes link imports and manual
// recipes computable without rewriting a single stored file.
//
// Pure Dart: no Flutter imports in domain/.

class ParsedQty {
  final num? qty;
  final String? unit;

  /// The line minus its quantity — what the ingredient IS.
  final String item;

  const ParsedQty({this.qty, this.unit, required this.item});
}

const _fractionChars = <String, double>{
  '½': 0.5,
  '¼': 0.25,
  '¾': 0.75,
  '⅓': 1 / 3,
  '⅔': 2 / 3,
  '⅛': 0.125,
};

/// Unit token → canonical name. Only units with a defined meaning; a word
/// not listed here is part of the item ("2 large eggs" → qty 2, no unit).
const _units = <String, String>{
  'g': 'g', 'gram': 'g', 'grams': 'g', 'gr': 'g',
  'kg': 'kg', 'kilogram': 'kg', 'kilograms': 'kg', 'kilo': 'kg',
  'mg': 'mg',
  'oz': 'oz', 'ounce': 'oz', 'ounces': 'oz',
  'lb': 'lb', 'lbs': 'lb', 'pound': 'lb', 'pounds': 'lb',
  'ml': 'ml', 'milliliter': 'ml', 'milliliters': 'ml',
  'millilitre': 'ml', 'millilitres': 'ml',
  'cl': 'cl',
  'dl': 'dl',
  'l': 'l', 'liter': 'l', 'liters': 'l', 'litre': 'l', 'litres': 'l',
  'tsp': 'tsp', 'teaspoon': 'tsp', 'teaspoons': 'tsp', 'ts': 'tsp',
  'tbsp': 'tbsp', 'tablespoon': 'tbsp', 'tablespoons': 'tbsp',
  'tbs': 'tbsp', 'ss': 'tbsp',
  'cup': 'cup', 'cups': 'cup',
  'pinch': 'pinch', 'dash': 'dash',
  'stk': 'piece', 'piece': 'piece', 'pieces': 'piece', 'pcs': 'piece',
  'can': 'can', 'cans': 'can', 'tin': 'can', 'tins': 'can',
  'clove': 'clove', 'cloves': 'clove',
  'slice': 'slice', 'slices': 'slice',
};

/// Number at the head of [text]: "2", "1.5", "1,5", "1/2", "1 1/2", "½",
/// "1½", and ranges "2-3" / "2–3" (the low end — a range in a recipe is a
/// choice, and undercounting is the honest default). Returns (value, chars
/// consumed) or null.
(num, int)? _leadNumber(String text) {
  var i = 0;
  num? value;

  num? readOne() {
    // Unicode fraction, alone or glued to a whole number ("1½").
    if (i < text.length && _fractionChars.containsKey(text[i])) {
      final f = _fractionChars[text[i]]!;
      i++;
      return f;
    }
    final m = RegExp(r'^\d+(?:[.,]\d+)?').firstMatch(text.substring(i));
    if (m == null) return null;
    i += m.end;
    final whole = num.parse(m.group(0)!.replaceAll(',', '.'));
    // "1/2" — a slash fraction.
    if (i < text.length && text[i] == '/') {
      final d = RegExp(r'^\d+').firstMatch(text.substring(i + 1));
      if (d != null) {
        i += 1 + d.end;
        final div = num.parse(d.group(0)!);
        return div == 0 ? whole : whole / div;
      }
    }
    // "1½" — glued unicode fraction.
    if (i < text.length && _fractionChars.containsKey(text[i])) {
      final f = _fractionChars[text[i]]!;
      i++;
      return whole + f;
    }
    return whole;
  }

  value = readOne();
  if (value == null) return null;

  // "1 1/2" — mixed number with a space.
  final rest = text.substring(i);
  final mixed = RegExp(r'^\s+(\d+/\d+|[½¼¾⅓⅔⅛])').firstMatch(rest);
  if (mixed != null) {
    final save = i;
    i += mixed.group(0)!.length - mixed.group(1)!.length;
    final extra = readOne();
    if (extra != null && extra < 1) {
      value = value + extra;
    } else {
      i = save; // "1 2" is not a mixed number — back off
    }
  }

  // "2-3" / "2–3" — keep the low end, skip the rest of the range.
  final range = RegExp(r'^\s*[-–]\s*\d+(?:[.,]\d+)?')
      .firstMatch(text.substring(i));
  if (range != null) i += range.group(0)!.length;

  return (value, i);
}

/// Parse one raw ingredient line. Never throws; a line with no leading
/// number comes back qty-less with the whole line as the item.
ParsedQty parseIngredientLine(String raw) {
  final text = raw.trim();
  final lead = _leadNumber(text);
  if (lead == null) return ParsedQty(item: text);
  final (qty, consumed) = lead;

  var rest = text.substring(consumed).trimLeft();
  // "2 x 400 g" / "2 × 400 g" — multiply through.
  final times = RegExp(r'^[x×]\s*').firstMatch(rest);
  if (times != null) {
    final inner = parseIngredientLine(rest.substring(times.end));
    if (inner.qty != null) {
      return ParsedQty(
          qty: qty * inner.qty!, unit: inner.unit, item: inner.item);
    }
  }

  // The unit word, if the next token is one. "400g" (glued) also splits.
  final glued = RegExp(r'^([a-zA-Z]+)\.?\s*').firstMatch(rest);
  if (glued != null) {
    final unit = _units[glued.group(1)!.toLowerCase()];
    if (unit != null) {
      var item = rest.substring(glued.end).trim();
      // "2 dl of milk" — drop the connective.
      item = item.replaceFirst(RegExp(r'^of\s+', caseSensitive: false), '');
      return ParsedQty(qty: qty, unit: unit, item: item);
    }
  }
  return ParsedQty(qty: qty, item: rest.trim());
}
