// Starter food packages — the un-barcoded produce door. Raw produce macros
// are ~global (a raw carrot is a raw carrot), so these ship as a curated
// built-in table instead of asking Open Food Facts, whose produce entries
// are contradictory regional packs (live-checked 2026-08-20). Pure Dart.
//
// Values transcribed from USDA SR Legacy / Foundation Foods averages via
// Arnar's curation session (conductor/docs/gemini-categories.md).
// UNVERIFIED against the USDA API yet — a verification agent will patch
// this file; keep values in this one place.
//
// CARBS CONVENTION: the table stores USDA "carbohydrate by difference",
// which INCLUDES fiber. European labels (and this pantry's OFF data)
// exclude it. [StarterFood.toProduct] subtracts fiber, so files land
// EU-convention — never subtract in the data itself.

import 'product.dart';

class StarterFood {
  final String name;

  /// Search aliases — Norwegian names first ("Paprika"), so recipe lines
  /// and pantry search match either language.
  final List<String> synonyms;

  /// Canonical shelf category (product_categories.dart) — becomes the tag.
  final String category;

  final double kcal;
  final double? fat;

  /// USDA total carbs per 100 g, fiber INCLUDED (see header).
  final double? carbs;
  final double? fiber;
  final double? protein;

  /// The natural portion: "1 medium" = 119 g — what OFF could never give us.
  final String servingLabel;
  final double servingGrams;

  const StarterFood(this.name, this.synonyms, this.category, this.kcal,
      this.fat, this.carbs, this.fiber, this.protein, this.servingLabel,
      this.servingGrams);

  /// A normal pantry product file: no barcode (id = name slug), source
  /// 'starter', pre-tagged, the natural serving preselected. NOT userEdited —
  /// but refreshAll never touches it anyway (no barcode to ask OFF about).
  Product toProduct({String? addedAt}) {
    final c = carbs;
    final f = fiber;
    return Product(
      schemaVersion: Product.currentSchemaVersion,
      barcode: '',
      name: name,
      source: 'starter',
      addedAt: addedAt,
      tags: [category],
      synonyms: synonyms,
      nutriments: Nutriments.fromMap({
        'kcal': kcal,
        'fat': ?fat,
        // EU convention: available carbs = USDA total carbs − fiber.
        if (c != null) 'carbs': f == null ? c : (c - f).clamp(0, c),
        'fiber': ?f,
        'protein': ?protein,
      }),
      servings: [Serving(label: servingLabel, grams: servingGrams)],
      defaultServing: 0,
    );
  }
}

/// One importable package: a name for the door, the foods behind it.
class StarterPackage {
  final String name;
  final String emoji;
  final List<StarterFood> foods;

  const StarterPackage(this.name, this.emoji, this.foods);
}

const starterPackages = [
  StarterPackage('Vegetables', '🥦', _vegetables),
  StarterPackage('Fruits & Berries', '🍎', _fruits),
  StarterPackage('Spices & Herbs', '🧂', _spices),
];

const _vegetables = [
  StarterFood('Red Bell Pepper', ['Paprika', 'Rød paprika'], 'Veggies', 31, 0.3, 6.0, 2.1, 1.0, '1 medium', 119),
  StarterFood('Green Bell Pepper', ['Grønn paprika'], 'Veggies', 20, 0.2, 4.6, 1.7, 0.9, '1 medium', 119),
  StarterFood('Yellow Bell Pepper', ['Gul paprika'], 'Veggies', 27, 0.2, 6.3, 0.9, 1.0, '1 medium', 119),
  StarterFood('Orange Bell Pepper', ['Oransje paprika'], 'Veggies', 26, 0.2, 6.3, 1.2, 1.0, '1 medium', 119),
  StarterFood('Yellow Onion', ['Løk', 'Gul løk', 'Onion'], 'Veggies', 40, 0.1, 9.3, 1.7, 1.1, '1 medium', 110),
  StarterFood('Red Onion', ['Rødløk'], 'Veggies', 40, 0.1, 9.3, 1.7, 1.1, '1 medium', 110),
  StarterFood('White Onion', ['Hvit løk'], 'Veggies', 42, 0.1, 9.8, 1.4, 1.2, '1 medium', 110),
  StarterFood('Shallot', ['Sjalottløk'], 'Veggies', 72, 0.1, 16.8, 3.2, 2.5, '1 shallot', 25),
  StarterFood('Green Onion', ['Vårløk', 'Scallion', 'Spring onion'], 'Veggies', 32, 0.2, 7.3, 2.6, 1.8, '1 stalk', 15),
  StarterFood('Leek', ['Purre', 'Purreløk'], 'Veggies', 61, 0.3, 14.2, 1.8, 1.5, '1 stalk', 89),
  StarterFood('Garlic', ['Hvitløk'], 'Veggies', 149, 0.5, 33.1, 2.1, 6.4, '1 clove', 3),
  StarterFood('Carrot', ['Gulrot'], 'Veggies', 41, 0.2, 9.6, 2.8, 0.9, '1 medium', 61),
  StarterFood('Celery', ['Stangselleri', 'Selleristang'], 'Veggies', 14, 0.2, 3.0, 1.6, 0.7, '1 stalk', 40),
  StarterFood('Celeriac', ['Sellerirot', 'Celery root'], 'Veggies', 42, 0.3, 9.2, 1.8, 1.5, '1 cup chopped', 156),
  StarterFood('Potato', ['Potet', 'Russet potato'], 'Veggies', 77, 0.1, 17.5, 2.2, 2.0, '1 medium', 173),
  StarterFood('Red Potato', ['Rød potet'], 'Veggies', 70, 0.1, 15.9, 1.7, 1.9, '1 medium', 150),
  StarterFood('Sweet Potato', ['Søtpotet'], 'Veggies', 86, 0.1, 20.1, 3.0, 1.6, '1 medium', 114),
  StarterFood('Broccoli', ['Brokkoli'], 'Veggies', 34, 0.4, 6.6, 2.6, 2.8, '1 cup florets', 91),
  StarterFood('Cauliflower', ['Blomkål'], 'Veggies', 25, 0.3, 5.0, 2.0, 1.9, '1 cup florets', 107),
  StarterFood('Brussels Sprouts', ['Rosenkål'], 'Veggies', 43, 0.3, 9.0, 3.8, 3.4, '1 sprout', 19),
  StarterFood('Green Cabbage', ['Hodekål', 'Hvitkål', 'Kål'], 'Veggies', 25, 0.1, 5.8, 2.5, 1.3, '1 cup shredded', 70),
  StarterFood('Red Cabbage', ['Rødkål'], 'Veggies', 31, 0.2, 7.4, 2.1, 1.4, '1 cup shredded', 70),
  StarterFood('Napa Cabbage', ['Kinakål', 'Chinese cabbage'], 'Veggies', 16, 0.2, 3.2, 1.2, 1.2, '1 cup shredded', 70),
  StarterFood('Spinach', ['Spinat'], 'Veggies', 23, 0.4, 3.6, 2.2, 2.9, '1 cup raw', 30),
  StarterFood('Kale', ['Grønnkål'], 'Veggies', 35, 0.9, 4.4, 4.1, 2.9, '1 cup raw', 21),
  StarterFood('Arugula', ['Ruccola', 'Rocket'], 'Veggies', 25, 0.7, 3.7, 1.6, 2.6, '1 cup raw', 20),
  StarterFood('Romaine Lettuce', ['Romanosalat', 'Hjertesalat'], 'Veggies', 17, 0.3, 3.3, 2.1, 1.2, '1 cup shredded', 47),
  StarterFood('Iceberg Lettuce', ['Isbergsalat'], 'Veggies', 14, 0.1, 3.0, 1.2, 0.9, '1 cup shredded', 72),
  StarterFood('Swiss Chard', ['Mangold'], 'Veggies', 19, 0.2, 3.7, 1.6, 1.8, '1 cup raw', 36),
  StarterFood('Zucchini', ['Squash', 'Courgette'], 'Veggies', 17, 0.3, 3.1, 1.0, 1.2, '1 medium', 196),
  StarterFood('Yellow Squash', ['Gul squash'], 'Veggies', 16, 0.2, 3.4, 1.1, 1.2, '1 medium', 196),
  StarterFood('Butternut Squash', ['Flaskegresskar'], 'Veggies', 45, 0.1, 11.7, 2.0, 1.0, '1 cup cubed', 140),
  StarterFood('Pumpkin', ['Gresskar'], 'Veggies', 26, 0.1, 6.5, 0.5, 1.0, '1 cup cubed', 116),
  StarterFood('Cucumber', ['Agurk'], 'Veggies', 15, 0.1, 3.6, 0.5, 0.7, '1 cucumber', 301),
  StarterFood('Tomato', ['Tomat'], 'Veggies', 18, 0.2, 3.9, 1.2, 0.9, '1 medium', 123),
  StarterFood('Cherry Tomato', ['Cherrytomat'], 'Veggies', 18, 0.2, 3.9, 1.2, 0.9, '1 tomato', 17),
  StarterFood('Plum Tomato', ['Romatomat', 'Roma tomato'], 'Veggies', 18, 0.2, 3.9, 1.2, 0.9, '1 tomato', 62),
  StarterFood('Eggplant', ['Aubergine'], 'Veggies', 25, 0.2, 5.9, 3.0, 1.0, '1 medium', 458),
  StarterFood('Avocado', ['Avokado'], 'Veggies', 160, 14.7, 8.5, 6.7, 2.0, '1 medium', 150),
  StarterFood('Asparagus', ['Asparges'], 'Veggies', 20, 0.1, 3.9, 2.1, 2.2, '1 spear', 12),
  StarterFood('Green Beans', ['Grønne bønner', 'Haricots verts'], 'Veggies', 31, 0.2, 7.0, 2.7, 1.8, '1 cup', 100),
  StarterFood('Green Peas', ['Erter', 'Grønne erter'], 'Veggies', 81, 0.4, 14.5, 5.7, 5.4, '1 cup', 145),
  StarterFood('Sugar Snap Peas', ['Sukkererter'], 'Veggies', 42, 0.2, 7.5, 2.6, 2.8, '1 cup', 98),
  StarterFood('Sweet Corn', ['Mais', 'Maiskolbe'], 'Veggies', 86, 1.4, 19.0, 2.0, 3.3, '1 ear', 102),
  StarterFood('White Mushroom', ['Sjampinjong', 'Champignon'], 'Veggies', 22, 0.3, 3.3, 1.0, 3.1, '1 medium', 18),
  StarterFood('Cremini Mushroom', ['Aromasopp', 'Baby bella'], 'Veggies', 22, 0.1, 4.3, 0.6, 2.5, '1 medium', 18),
  StarterFood('Shiitake Mushroom', ['Shiitake'], 'Veggies', 34, 0.5, 6.8, 2.5, 2.2, '1 mushroom', 19),
  StarterFood('Portobello Mushroom', ['Portobello'], 'Veggies', 22, 0.4, 3.9, 1.3, 2.1, '1 cap', 84),
  StarterFood('Beetroot', ['Rødbete'], 'Veggies', 43, 0.2, 9.6, 2.8, 1.6, '1 medium', 82),
  StarterFood('Radish', ['Reddik'], 'Veggies', 16, 0.1, 3.4, 1.6, 0.7, '1 medium', 4.5),
  StarterFood('Turnip', ['Nepe'], 'Veggies', 28, 0.1, 6.4, 1.8, 0.9, '1 medium', 122),
  StarterFood('Parsnip', ['Pastinakk'], 'Veggies', 75, 0.3, 18.0, 4.9, 1.2, '1 medium', 170),
  StarterFood('Fennel', ['Fennikel'], 'Veggies', 31, 0.2, 7.3, 3.1, 1.2, '1 bulb', 234),
  StarterFood('Artichoke', ['Artisjokk'], 'Veggies', 47, 0.2, 10.5, 5.4, 3.3, '1 medium', 128),
  StarterFood('Ginger', ['Ingefær'], 'Veggies', 80, 0.8, 17.8, 2.0, 1.8, '1 tbsp chopped', 6),
  StarterFood('Jalapeño', ['Jalapeño'], 'Veggies', 29, 0.4, 6.5, 2.8, 0.9, '1 pepper', 14),
  StarterFood('Red Chili', ['Rød chili'], 'Veggies', 40, 0.4, 8.8, 1.5, 1.9, '1 pepper', 45),
  StarterFood('Yam', ['Yam'], 'Veggies', 118, 0.2, 27.9, 4.1, 1.5, '1 cup cubed', 150),
  StarterFood('Kohlrabi', ['Knutekål'], 'Veggies', 27, 0.1, 6.2, 3.6, 1.7, '1 cup', 135),
  StarterFood('Radicchio', ['Radicchio'], 'Veggies', 23, 0.3, 4.5, 0.9, 1.4, '1 cup', 40),
  StarterFood('Bok Choy', ['Pak choi'], 'Veggies', 13, 0.2, 2.2, 1.0, 1.5, '1 cup shredded', 70),
  StarterFood('Okra', ['Okra'], 'Veggies', 33, 0.2, 7.5, 3.2, 1.9, '1 cup', 100),
  StarterFood('Bamboo Shoots', ['Bambusskudd'], 'Veggies', 27, 0.3, 5.2, 2.2, 2.6, '1 cup', 120),
  StarterFood('Water Chestnuts', ['Vannkastanjer'], 'Veggies', 97, 0.1, 23.9, 3.0, 1.4, '1 cup', 120),
  StarterFood('Fresh Parsley', ['Persille'], 'Veggies', 36, 0.8, 6.3, 3.3, 3.0, '1 tbsp chopped', 4),
];

const _fruits = [
  StarterFood('Red Apple', ['Eple', 'Rødt eple', 'Gala'], 'Fruit', 52, 0.2, 13.8, 2.4, 0.3, '1 medium', 182),
  StarterFood('Green Apple', ['Grønt eple', 'Granny Smith'], 'Fruit', 52, 0.2, 13.6, 2.8, 0.4, '1 medium', 182),
  StarterFood('Banana', ['Banan'], 'Fruit', 89, 0.3, 22.8, 2.6, 1.1, '1 medium', 118),
  StarterFood('Orange', ['Appelsin'], 'Fruit', 47, 0.1, 11.8, 2.4, 0.9, '1 medium', 131),
  StarterFood('Clementine', ['Klementin', 'Mandarin'], 'Fruit', 47, 0.2, 12.0, 1.7, 0.9, '1 fruit', 74),
  StarterFood('Lemon', ['Sitron'], 'Fruit', 29, 0.3, 9.3, 2.8, 1.1, '1 medium', 58),
  StarterFood('Lime', ['Lime'], 'Fruit', 30, 0.2, 10.5, 2.8, 0.7, '1 medium', 67),
  StarterFood('Grapefruit', ['Grapefrukt'], 'Fruit', 42, 0.1, 10.7, 1.6, 0.8, '1/2 medium', 123),
  StarterFood('Strawberries', ['Jordbær'], 'Berries', 32, 0.3, 7.7, 2.0, 0.7, '1 cup sliced', 166),
  StarterFood('Blueberries', ['Blåbær'], 'Berries', 57, 0.3, 14.5, 2.4, 0.7, '1 cup', 148),
  StarterFood('Raspberries', ['Bringebær'], 'Berries', 52, 0.7, 11.9, 6.5, 1.2, '1 cup', 123),
  StarterFood('Blackberries', ['Bjørnebær'], 'Berries', 43, 0.5, 9.6, 5.3, 1.4, '1 cup', 144),
  StarterFood('Lingonberries', ['Tyttebær'], 'Berries', 50, 0.5, 11.5, 2.5, 0.7, '1 cup', 110),
  StarterFood('Cloudberries', ['Multer', 'Molter'], 'Berries', 51, 0.8, 8.6, 6.3, 1.3, '1 cup', 130),
  StarterFood('Cranberries', ['Tranebær'], 'Berries', 46, 0.1, 12.2, 3.6, 0.4, '1 cup whole', 100),
  StarterFood('Red Grapes', ['Druer', 'Røde druer'], 'Fruit', 69, 0.2, 18.1, 0.9, 0.7, '1 cup', 151),
  StarterFood('Green Grapes', ['Grønne druer'], 'Fruit', 69, 0.2, 18.1, 0.9, 0.7, '1 cup', 151),
  StarterFood('Watermelon', ['Vannmelon'], 'Fruit', 30, 0.2, 7.6, 0.4, 0.6, '1 cup diced', 152),
  StarterFood('Cantaloupe', ['Cantaloupemelon', 'Nettmelon'], 'Fruit', 34, 0.2, 8.2, 0.9, 0.8, '1 cup cubed', 160),
  StarterFood('Honeydew Melon', ['Honningmelon'], 'Fruit', 36, 0.1, 9.1, 0.8, 0.5, '1 cup cubed', 170),
  StarterFood('Peach', ['Fersken'], 'Fruit', 39, 0.3, 9.5, 1.5, 0.9, '1 medium', 150),
  StarterFood('Nectarine', ['Nektarin'], 'Fruit', 44, 0.3, 10.6, 1.7, 1.1, '1 medium', 142),
  StarterFood('Plum', ['Plomme'], 'Fruit', 46, 0.2, 11.4, 1.4, 0.7, '1 medium', 66),
  StarterFood('Sweet Cherries', ['Kirsebær', 'Moreller'], 'Fruit', 63, 0.2, 16.0, 2.1, 1.1, '1 cup pitted', 138),
  StarterFood('Mango', ['Mango'], 'Fruit', 60, 0.4, 15.0, 1.6, 0.8, '1 cup cubed', 165),
  StarterFood('Pineapple', ['Ananas'], 'Fruit', 50, 0.1, 13.1, 1.4, 0.5, '1 cup chunks', 165),
  StarterFood('Kiwifruit', ['Kiwi'], 'Fruit', 61, 0.5, 14.7, 3.0, 1.1, '1 medium', 69),
  StarterFood('Pear', ['Pære'], 'Fruit', 57, 0.1, 15.2, 3.1, 0.4, '1 medium', 178),
  StarterFood('Fresh Fig', ['Fiken'], 'Fruit', 74, 0.3, 19.2, 2.9, 0.8, '1 medium', 50),
  StarterFood('Pomegranate', ['Granateple'], 'Fruit', 83, 1.2, 18.7, 4.0, 1.7, '1/2 cup arils', 87),
  StarterFood('Passion Fruit', ['Pasjonsfrukt', 'Maracuja'], 'Fruit', 97, 0.7, 23.4, 10.4, 2.2, '1 fruit', 18),
  StarterFood('Papaya', ['Papaya'], 'Fruit', 43, 0.3, 10.8, 1.7, 0.5, '1 cup cubed', 145),
  StarterFood('Apricot', ['Aprikos'], 'Fruit', 48, 0.4, 11.1, 2.0, 1.4, '1 medium', 35),
  StarterFood('Persimmon', ['Kaki', 'Sharonfrukt'], 'Fruit', 70, 0.2, 18.6, 3.6, 0.6, '1 fruit', 168),
  StarterFood('Guava', ['Guava'], 'Fruit', 68, 1.0, 14.3, 5.4, 2.6, '1 fruit', 55),
  StarterFood('Lychee', ['Litchi'], 'Fruit', 66, 0.4, 16.5, 1.3, 0.8, '1 fruit', 10),
  StarterFood('Dragon Fruit', ['Drakefrukt', 'Pitaya'], 'Fruit', 60, 0.6, 13.0, 2.9, 1.2, '1 cup cubed', 140),
  StarterFood('Star Fruit', ['Stjernefrukt', 'Carambola'], 'Fruit', 31, 0.3, 6.7, 2.8, 1.0, '1 fruit', 91),
  StarterFood('Medjool Date', ['Daddel', 'Dadler'], 'Fruit', 277, 0.2, 75.0, 6.7, 1.8, '1 date pitted', 24),
  StarterFood('Coconut Meat', ['Kokos', 'Kokoskjøtt'], 'Fruit', 354, 33.5, 15.2, 9.0, 3.3, '1 cup shredded', 80),
  StarterFood('Rhubarb', ['Rabarbra'], 'Fruit', 21, 0.2, 4.5, 1.8, 0.9, '1 cup diced', 122),
  StarterFood('Elderberries', ['Hyllebær'], 'Berries', 73, 0.5, 18.4, 7.0, 0.7, '1 cup', 145),
  StarterFood('Gooseberries', ['Stikkelsbær'], 'Berries', 44, 0.6, 10.2, 4.3, 0.9, '1 cup', 150),
  StarterFood('Red Currants', ['Rips', 'Røde rips'], 'Berries', 56, 0.2, 13.8, 4.3, 1.4, '1 cup', 112),
  StarterFood('Black Currants', ['Solbær'], 'Berries', 63, 0.4, 15.4, 4.3, 1.4, '1 cup', 112),
  StarterFood('Kumquat', ['Kumquat'], 'Fruit', 71, 0.9, 15.9, 6.5, 1.9, '1 fruit', 19),
  StarterFood('Plantain', ['Kokebanan'], 'Fruit', 122, 0.4, 31.9, 2.3, 1.3, '1 medium', 179),
  StarterFood('Jackfruit', ['Jackfruit'], 'Fruit', 95, 0.6, 23.3, 1.5, 1.7, '1 cup sliced', 165),
  StarterFood('Tamarind', ['Tamarind'], 'Fruit', 239, 0.6, 62.5, 5.1, 2.8, '1 cup', 120),
];

const _spices = [
  StarterFood('Black Pepper', ['Svart pepper', 'Pepper'], 'Spices', 251, null, null, null, null, '1 tsp', 2.3),
  StarterFood('Salt', ['Salt', 'Havsalt'], 'Spices', 0, null, null, null, null, '1 tsp', 6.0),
  StarterFood('Paprika', ['Paprikapulver'], 'Spices', 282, null, null, null, null, '1 tsp', 2.3),
  StarterFood('Smoked Paprika', ['Røkt paprika'], 'Spices', 282, null, null, null, null, '1 tsp', 2.3),
  StarterFood('Ground Cinnamon', ['Kanel'], 'Spices', 247, null, null, null, null, '1 tsp', 2.6),
  StarterFood('Ground Cumin', ['Spisskummen'], 'Spices', 375, null, null, null, null, '1 tsp', 2.1),
  StarterFood('Garlic Powder', ['Hvitløkspulver'], 'Spices', 331, null, null, null, null, '1 tsp', 3.1),
  StarterFood('Onion Powder', ['Løkpulver'], 'Spices', 341, null, null, null, null, '1 tsp', 2.4),
  StarterFood('Chili Powder', ['Chilipulver'], 'Spices', 282, null, null, null, null, '1 tsp', 2.7),
  StarterFood('Cayenne Pepper', ['Kajennepepper'], 'Spices', 318, null, null, null, null, '1 tsp', 1.8),
  StarterFood('Dried Oregano', ['Oregano'], 'Spices', 265, null, null, null, null, '1 tsp', 1.0),
  StarterFood('Dried Basil', ['Basilikum'], 'Spices', 233, null, null, null, null, '1 tsp', 0.7),
  StarterFood('Dried Thyme', ['Timian'], 'Spices', 276, null, null, null, null, '1 tsp', 1.0),
  StarterFood('Dried Rosemary', ['Rosmarin'], 'Spices', 331, null, null, null, null, '1 tsp', 1.2),
  StarterFood('Dried Parsley', ['Tørket persille'], 'Spices', 292, null, null, null, null, '1 tsp', 0.5),
  StarterFood('Ground Turmeric', ['Gurkemeie'], 'Spices', 312, null, null, null, null, '1 tsp', 3.0),
  StarterFood('Curry Powder', ['Karri', 'Karripulver'], 'Spices', 325, null, null, null, null, '1 tsp', 2.0),
  StarterFood('Ground Ginger', ['Malt ingefær'], 'Spices', 335, null, null, null, null, '1 tsp', 1.8),
  StarterFood('Ground Nutmeg', ['Muskat', 'Muskatnøtt'], 'Spices', 525, null, null, null, null, '1 tsp', 2.2),
  StarterFood('Ground Cardamom', ['Kardemomme'], 'Spices', 311, null, null, null, null, '1 tsp', 2.0),
  StarterFood('Ground Cloves', ['Nellik'], 'Spices', 274, null, null, null, null, '1 tsp', 2.1),
  StarterFood('Ground Coriander', ['Malt koriander'], 'Spices', 298, null, null, null, null, '1 tsp', 1.8),
  StarterFood('Mustard Powder', ['Sennepspulver'], 'Spices', 508, null, null, null, null, '1 tsp', 2.0),
  StarterFood('Red Pepper Flakes', ['Chiliflak'], 'Spices', 318, null, null, null, null, '1 tsp', 1.8),
  StarterFood('Bay Leaf', ['Laurbærblad'], 'Spices', 313, null, null, null, null, '1 leaf', 0.6),
  StarterFood('Dried Dill', ['Dill'], 'Spices', 253, null, null, null, null, '1 tsp', 0.6),
  StarterFood('Dried Tarragon', ['Estragon'], 'Spices', 295, null, null, null, null, '1 tsp', 0.6),
  StarterFood('Dried Sage', ['Salvie'], 'Spices', 315, null, null, null, null, '1 tsp', 0.7),
  StarterFood('Ground Allspice', ['Allehånde'], 'Spices', 263, null, null, null, null, '1 tsp', 1.9),
  StarterFood('Fennel Seeds', ['Fennikelfrø'], 'Spices', 345, null, null, null, null, '1 tsp', 2.0),
  StarterFood('Caraway Seeds', ['Karve'], 'Spices', 333, null, null, null, null, '1 tsp', 2.1),
  StarterFood('Garam Masala', ['Garam masala'], 'Spices', 378, null, null, null, null, '1 tsp', 2.0),
  StarterFood('Taco Seasoning', ['Tacokrydder'], 'Spices', 290, null, null, null, null, '1 tbsp', 8.0),
  StarterFood('Vanilla Extract', ['Vaniljeekstrakt'], 'Spices', 288, null, null, null, null, '1 tsp', 4.2),
  StarterFood('Baking Powder', ['Bakepulver'], 'Spices', 53, null, null, null, null, '1 tsp', 4.6),
];
