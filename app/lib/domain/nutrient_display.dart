// How a stored nutrient becomes a line on screen. Pure Dart — no Flutter — so
// the unit maths is testable on its own.
//
// Storage keeps Open Food Facts' own units: kilocalories for `kcal`,
// kilojoules for `energy_kj`, GRAMS for everything else. That means calcium
// arrives as 0.118 and vitamin D as 0.0000008, which are unreadable as
// written. Only the display converts, and only downward: g -> mg -> µg.

/// English names for the nutrients Open Food Facts sends most often. A key
/// that isn't here still shows — [nutrientLabel] makes a readable name out of
/// the key itself, so a new OFF field or a hand-typed one is never hidden.
const _labels = <String, String>{
  'kcal': 'Energy',
  'energy_kj': 'Energy',
  'fat': 'Fat',
  'saturated_fat': '— of which saturated',
  'monounsaturated_fat': '— monounsaturated',
  'polyunsaturated_fat': '— polyunsaturated',
  'trans_fat': '— trans fat',
  'cholesterol': 'Cholesterol',
  'carbs': 'Carbohydrates',
  'sugars': '— of which sugars',
  'added_sugars': '— added sugars',
  'starch': '— starch',
  'polyols': '— polyols',
  'fiber': 'Fibre',
  'protein': 'Protein',
  'salt': 'Salt',
  'sodium': 'Sodium',
  'alcohol': 'Alcohol',
  'caffeine': 'Caffeine',
  'calcium': 'Calcium',
  'iron': 'Iron',
  'magnesium': 'Magnesium',
  'phosphorus': 'Phosphorus',
  'potassium': 'Potassium',
  'zinc': 'Zinc',
  'copper': 'Copper',
  'manganese': 'Manganese',
  'selenium': 'Selenium',
  'iodine': 'Iodine',
  'chloride': 'Chloride',
  'fluoride': 'Fluoride',
  'chromium': 'Chromium',
  'molybdenum': 'Molybdenum',
  'vitamin_a': 'Vitamin A',
  'beta_carotene': 'Beta-carotene',
  'vitamin_d': 'Vitamin D',
  'vitamin_e': 'Vitamin E',
  'vitamin_k': 'Vitamin K',
  'vitamin_c': 'Vitamin C',
  'vitamin_b1': 'Vitamin B1 (thiamin)',
  'vitamin_b2': 'Vitamin B2 (riboflavin)',
  'vitamin_b6': 'Vitamin B6',
  'vitamin_b9': 'Vitamin B9 (folate)',
  'vitamin_b12': 'Vitamin B12',
  'vitamin_pp': 'Niacin',
  'biotin': 'Biotin',
  'pantothenic_acid': 'Pantothenic acid',
  'folates': 'Folate',
  'choline': 'Choline',
  'omega_3_fat': 'Omega-3',
  'omega_6_fat': 'Omega-6',
};

/// A readable name for any stored key, known or not.
String nutrientLabel(String key) {
  final known = _labels[key];
  if (known != null) return known;
  final words = key.replaceAll('_', ' ').trim();
  if (words.isEmpty) return key;
  return words[0].toUpperCase() + words.substring(1);
}

/// Keys that are not measured in grams.
const _ownUnit = <String, String>{
  'kcal': 'kcal',
  'energy_kj': 'kJ',
};

/// The value and its unit as they should read on screen, e.g. (118, 'mg') for
/// calcium stored as 0.118 g. Small amounts step down to milligrams and then
/// micrograms so nobody has to count leading zeros.
(String, String) formatNutrient(String key, double grams) {
  final fixedUnit = _ownUnit[key];
  if (fixedUnit != null) return (_trim(grams), fixedUnit);
  if (grams == 0) return ('0', 'g');
  final magnitude = grams.abs();
  if (magnitude >= 1) return (_trim(grams), 'g');
  if (magnitude >= 0.001) return (_trim(grams * 1000), 'mg');
  return (_trim(grams * 1000000), 'µg');
}

/// Up to two decimals, with trailing zeros removed: 118, 1.5, 0.83.
String _trim(double v) {
  if (v == v.roundToDouble()) return v.round().toString();
  var s = v.toStringAsFixed(2);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '');
    s = s.replaceFirst(RegExp(r'\.$'), '');
  }
  return s;
}
