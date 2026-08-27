// The curated icon catalog — pure Dart, no Flutter.
//
// This half holds what a USER FILE stores: a stable string key, the group it
// is filed under, and the words that should find it in the picker's search.
// The Flutter half (ui/icons/food_icons.dart) binds each key to an actual
// Icons.* constant.
//
// Keys, never codepoints. Three reasons, all real:
//   1. "icon": "pizza" stays readable and portable in the user's own file;
//      59567 does not, and the bet is files a human can read.
//   2. --tree-shake-icons is ON in release builds. An icon reached only
//      through a runtime-built IconData(codepoint) gets stripped and renders
//      as a hollow box — in the release APK only, never in debug. A const map
//      keeps every icon referenced, so the shake keeps them.
//   3. An unknown key falls back to a neutral default instead of crashing, so
//      a hand-edited file or a catalog that shrank never breaks the app.
//
// Honest about the size: Material Symbols is good on dishes, meals, drinks and
// kitchen gear and thin on named ingredients — there is no avocado, no
// broccoli, and no oven. That gap is why a tag's icon may also be a literal emoji
// (see RecipeTag.icon); this catalog is the brand-clean default, not a ceiling.

/// The groups the picker shows, in order.
enum TagIconGroup { dishes, ingredients, kitchen, occasions, dietary, time }

class TagIcon {
  const TagIcon(this.key, this.group, this.terms);

  /// Stored in tags.json. Lowercase and underscores only — that shape is also
  /// what tells a catalog key apart from a literal emoji.
  final String key;
  final TagIconGroup group;

  /// Extra words the picker's search should match, beyond the key itself.
  /// English here; the localized terms come from the .arb file.
  final List<String> terms;
}

/// Catalog key shape. Anything that does NOT match is treated as a literal
/// emoji the user typed, which is the whole escape hatch.
final RegExp kTagIconKeyPattern = RegExp(r'^[a-z][a-z0-9_]*$');

bool isTagIconKey(String v) => kTagIconKeyPattern.hasMatch(v);

const List<TagIcon> kTagIcons = [
  // ── Dishes ───────────────────────────────────────────────────────────────
  TagIcon('pizza', TagIconGroup.dishes, ['slice', 'italian']),
  TagIcon('pasta', TagIconGroup.dishes, ['noodles', 'spaghetti', 'italian']),
  TagIcon('ramen', TagIconGroup.dishes, ['noodles', 'asian', 'broth']),
  TagIcon('rice_bowl', TagIconGroup.dishes, ['rice', 'bowl', 'asian']),
  TagIcon('soup', TagIconGroup.dishes, ['stew', 'broth', 'pot']),
  TagIcon('burger', TagIconGroup.dishes, ['lunch', 'sandwich']),
  TagIcon('dinner', TagIconGroup.dishes, ['main', 'supper', 'evening']),
  TagIcon('breakfast', TagIconGroup.dishes, ['morning', 'toast']),
  TagIcon('brunch', TagIconGroup.dishes, ['late morning', 'weekend']),
  TagIcon('kebab', TagIconGroup.dishes, ['skewer', 'grill']),
  TagIcon('tapas', TagIconGroup.dishes, ['small plates', 'sharing', 'spanish']),
  TagIcon('seafood', TagIconGroup.dishes, ['fish', 'set meal']),
  TagIcon('bakery', TagIconGroup.dishes, ['bread', 'pastry', 'croissant']),
  TagIcon('fast_food', TagIconGroup.dishes, ['takeaway', 'fries']),
  TagIcon('takeout', TagIconGroup.dishes, ['takeaway', 'box', 'delivery']),
  TagIcon('cake', TagIconGroup.dishes, ['dessert', 'birthday', 'sweet']),
  TagIcon('cookie', TagIconGroup.dishes, ['biscuit', 'sweet', 'baking']),
  TagIcon('ice_cream', TagIconGroup.dishes, ['dessert', 'frozen', 'sweet']),
  TagIcon('restaurant', TagIconGroup.dishes, ['meal', 'dining', 'eat']),
  TagIcon('menu_card', TagIconGroup.dishes, ['menu', 'courses']),
  TagIcon('room_service', TagIconGroup.dishes, ['served', 'cloche']),

  // ── Ingredients ──────────────────────────────────────────────────────────
  TagIcon('egg', TagIconGroup.ingredients, ['eggs', 'shell']),
  TagIcon('fried_egg', TagIconGroup.ingredients, ['eggs', 'sunny side']),
  TagIcon('grain', TagIconGroup.ingredients, ['wheat', 'cereal', 'flour']),
  TagIcon('herb', TagIconGroup.ingredients, ['grass', 'green', 'leaf']),
  TagIcon('flower', TagIconGroup.ingredients, ['floral', 'edible flower']),
  TagIcon('leaf', TagIconGroup.ingredients, ['eco', 'green', 'plant']),
  TagIcon('farm', TagIconGroup.ingredients, ['agriculture', 'produce']),
  TagIcon('forest', TagIconGroup.ingredients, ['wild', 'foraged', 'mushroom']),
  TagIcon('water', TagIconGroup.ingredients, ['liquid', 'drop', 'hydrate']),
  TagIcon('coffee', TagIconGroup.ingredients, ['espresso', 'caffeine']),
  TagIcon('coffee_pot', TagIconGroup.ingredients, ['brew', 'carafe']),
  TagIcon('tea', TagIconGroup.ingredients, ['brew', 'hot drink', 'cup']),
  TagIcon('cafe', TagIconGroup.ingredients, ['hot drink', 'cup']),
  TagIcon('drink', TagIconGroup.ingredients, ['cold', 'glass', 'straw']),
  TagIcon('wine', TagIconGroup.ingredients, ['glass', 'red', 'white']),
  TagIcon('cocktail', TagIconGroup.ingredients, ['bar', 'mixed drink']),
  TagIcon('beer', TagIconGroup.ingredients, ['pint', 'ale']),
  TagIcon('spirits', TagIconGroup.ingredients, ['liquor', 'bottle']),

  // ── Kitchen & tools ──────────────────────────────────────────────────────
  TagIcon('kitchen', TagIconGroup.kitchen, ['fridge', 'appliance']),
  TagIcon('microwave', TagIconGroup.kitchen, ['reheat', 'appliance']),
  TagIcon('blender', TagIconGroup.kitchen, ['smoothie', 'puree', 'mix']),
  TagIcon('grill', TagIconGroup.kitchen, ['bbq', 'barbecue', 'outdoor']),
  TagIcon('stovetop', TagIconGroup.kitchen, ['hob', 'pan', 'counter']),
  TagIcon('pot', TagIconGroup.kitchen, ['saucepan', 'simmer', 'one pot']),
  TagIcon('cutlery', TagIconGroup.kitchen, ['fork', 'knife', 'flatware']),
  TagIcon('scale', TagIconGroup.kitchen, ['weigh', 'grams', 'measure']),
  TagIcon('ruler', TagIconGroup.kitchen, ['measure', 'size']),
  TagIcon('table', TagIconGroup.kitchen, ['dining table', 'seated']),
  TagIcon('heat', TagIconGroup.kitchen, ['fire', 'spicy', 'hot']),
  TagIcon('freezer', TagIconGroup.kitchen, ['frozen', 'cold', 'freeze']),
  TagIcon('basket', TagIconGroup.kitchen, ['shopping', 'groceries']),
  TagIcon('cart', TagIconGroup.kitchen, ['shopping', 'trolley']),

  // ── Occasions ────────────────────────────────────────────────────────────
  TagIcon('celebration', TagIconGroup.occasions, ['party', 'festive']),
  TagIcon('gift', TagIconGroup.occasions, ['present', 'holiday']),
  TagIcon('festival', TagIconGroup.occasions, ['holiday', 'seasonal']),
  TagIcon('family', TagIconGroup.occasions, ['kids', 'household']),
  TagIcon('crowd', TagIconGroup.occasions, ['guests', 'a lot of people']),
  TagIcon('sunny', TagIconGroup.occasions, ['summer', 'day', 'warm']),
  TagIcon('night', TagIconGroup.occasions, ['evening', 'late']),
  TagIcon('picnic', TagIconGroup.occasions, ['outdoors', 'beach', 'packed']),
  TagIcon('camping', TagIconGroup.occasions, ['outdoors', 'hike', 'trail']),
  TagIcon('calendar', TagIconGroup.occasions, ['planned', 'date', 'month']),

  // ── Dietary ──────────────────────────────────────────────────────────────
  TagIcon('vegan', TagIconGroup.dietary, ['plant based', 'no animal']),
  TagIcon('vegetarian', TagIconGroup.dietary, ['no meat', 'veggie', 'green']),
  TagIcon('no_meal', TagIconGroup.dietary, ['avoid', 'exclude', 'free from']),
  TagIcon('healthy', TagIconGroup.dietary, ['heart', 'light', 'wellness']),
  TagIcon('wellness', TagIconGroup.dietary, ['spa', 'calm', 'clean']),
  TagIcon('workout', TagIconGroup.dietary, ['protein', 'gym', 'fitness']),
  TagIcon('medical', TagIconGroup.dietary, ['allergy', 'intolerance']),
  TagIcon('favorite', TagIconGroup.dietary, ['heart', 'loved']),

  // ── Time ─────────────────────────────────────────────────────────────────
  TagIcon('quick', TagIconGroup.time, ['fast', 'bolt', 'weeknight']),
  TagIcon('timer', TagIconGroup.time, ['minutes', 'countdown']),
  TagIcon('clock', TagIconGroup.time, ['schedule', 'time', 'when']),
  TagIcon('slow', TagIconGroup.time, ['hourglass', 'long', 'braise']),
  TagIcon('alarm', TagIconGroup.time, ['reminder', 'wake']),
  TagIcon('make_ahead', TagIconGroup.time, ['update', 'prep', 'batch']),
  TagIcon('speed', TagIconGroup.time, ['fast', 'rush']),
];

/// Catalog keys, in catalog order.
final List<String> kTagIconKeys = [for (final i in kTagIcons) i.key];

List<TagIcon> tagIconsIn(TagIconGroup group) =>
    [for (final i in kTagIcons) if (i.group == group) i];
