// The browsable emoji palette for tag icons.
//
// The pantry's category chips have used emoji since 2026-08-20 (🥛 Dairy,
// 🥦 Veggies) and Arnar likes them, so tags get the same vocabulary — but
// pickable, not only typeable. Android draws these with its own Noto Color
// Emoji, so they cost no asset and no dependency, and they cover exactly what
// Material Symbols cannot: named ingredients.
//
// The tag record stores the character itself. isTagIconKey() tells a catalog
// key from an emoji by shape, so nothing here needs its own field.
//
// Food and kitchen only. This is a recipe app; a full emoji keyboard belongs
// to the phone, and the user can still type any character they like.

enum TagEmojiGroup {
  fruitVeg,
  meatFish,
  dairyEggs,
  grains,
  sweets,
  drinks,
  dishes,
  kitchen,
  occasions,
}

class TagEmoji {
  const TagEmoji(this.char, this.group, this.terms);

  final String char;
  final TagEmojiGroup group;

  /// Words the picker's search should match.
  final List<String> terms;
}

const List<TagEmoji> kTagEmoji = [
  // ── Fruit & veg ──────────────────────────────────────────────────────────
  TagEmoji('🍎', TagEmojiGroup.fruitVeg, ['apple', 'fruit']),
  TagEmoji('🍌', TagEmojiGroup.fruitVeg, ['banana', 'fruit']),
  TagEmoji('🍋', TagEmojiGroup.fruitVeg, ['lemon', 'citrus', 'fruit']),
  TagEmoji('🍊', TagEmojiGroup.fruitVeg, ['orange', 'citrus', 'fruit']),
  TagEmoji('🍓', TagEmojiGroup.fruitVeg, ['strawberry', 'berry']),
  TagEmoji('🫐', TagEmojiGroup.fruitVeg, ['blueberry', 'berries']),
  TagEmoji('🍇', TagEmojiGroup.fruitVeg, ['grapes', 'fruit']),
  TagEmoji('🍑', TagEmojiGroup.fruitVeg, ['peach', 'fruit']),
  TagEmoji('🍍', TagEmojiGroup.fruitVeg, ['pineapple', 'fruit', 'tropical']),
  TagEmoji('🥭', TagEmojiGroup.fruitVeg, ['mango', 'tropical']),
  TagEmoji('🍉', TagEmojiGroup.fruitVeg, ['watermelon', 'melon', 'summer']),
  TagEmoji('🥑', TagEmojiGroup.fruitVeg, ['avocado', 'guacamole']),
  TagEmoji('🍅', TagEmojiGroup.fruitVeg, ['tomato', 'salad']),
  TagEmoji('🥦', TagEmojiGroup.fruitVeg, ['broccoli', 'veggies', 'greens']),
  TagEmoji('🥬', TagEmojiGroup.fruitVeg, ['salad', 'lettuce', 'greens']),
  TagEmoji('🥕', TagEmojiGroup.fruitVeg, ['carrot', 'root', 'veggies']),
  TagEmoji('🌽', TagEmojiGroup.fruitVeg, ['corn', 'maize']),
  TagEmoji('🥔', TagEmojiGroup.fruitVeg, ['potato', 'root']),
  TagEmoji('🍄', TagEmojiGroup.fruitVeg, ['mushroom', 'fungi']),
  TagEmoji('🧅', TagEmojiGroup.fruitVeg, ['onion']),
  TagEmoji('🧄', TagEmojiGroup.fruitVeg, ['garlic']),
  TagEmoji('🌶️', TagEmojiGroup.fruitVeg, ['chilli', 'chili', 'spicy', 'hot']),
  TagEmoji('🫑', TagEmojiGroup.fruitVeg, ['pepper', 'paprika', 'bell']),
  TagEmoji('🥒', TagEmojiGroup.fruitVeg, ['cucumber', 'pickle']),
  TagEmoji('🫒', TagEmojiGroup.fruitVeg, ['olive', 'oil']),

  // ── Meat & fish ──────────────────────────────────────────────────────────
  TagEmoji('🥩', TagEmojiGroup.meatFish, ['steak', 'beef', 'meat']),
  TagEmoji('🍖', TagEmojiGroup.meatFish, ['meat', 'bone', 'roast']),
  TagEmoji('🍗', TagEmojiGroup.meatFish, ['chicken', 'poultry', 'drumstick']),
  TagEmoji('🥓', TagEmojiGroup.meatFish, ['bacon', 'pork']),
  TagEmoji('🌭', TagEmojiGroup.meatFish, ['sausage', 'hot dog']),
  TagEmoji('🐟', TagEmojiGroup.meatFish, ['fish', 'seafood']),
  TagEmoji('🐠', TagEmojiGroup.meatFish, ['fish', 'seafood']),
  TagEmoji('🦐', TagEmojiGroup.meatFish, ['shrimp', 'prawn', 'seafood']),
  TagEmoji('🦀', TagEmojiGroup.meatFish, ['crab', 'shellfish', 'seafood']),
  TagEmoji('🦑', TagEmojiGroup.meatFish, ['squid', 'calamari', 'seafood']),
  TagEmoji('🦞', TagEmojiGroup.meatFish, ['lobster', 'shellfish']),

  // ── Dairy & eggs ─────────────────────────────────────────────────────────
  TagEmoji('🥛', TagEmojiGroup.dairyEggs, ['milk', 'dairy']),
  TagEmoji('🧀', TagEmojiGroup.dairyEggs, ['cheese', 'dairy']),
  TagEmoji('🧈', TagEmojiGroup.dairyEggs, ['butter', 'dairy']),
  TagEmoji('🥚', TagEmojiGroup.dairyEggs, ['egg', 'eggs']),
  TagEmoji('🍳', TagEmojiGroup.dairyEggs, ['fried egg', 'breakfast', 'pan']),

  // ── Grains & bread ───────────────────────────────────────────────────────
  TagEmoji('🍞', TagEmojiGroup.grains, ['bread', 'loaf', 'toast']),
  TagEmoji('🥖', TagEmojiGroup.grains, ['baguette', 'bread', 'french']),
  TagEmoji('🥐', TagEmojiGroup.grains, ['croissant', 'pastry', 'breakfast']),
  TagEmoji('🥯', TagEmojiGroup.grains, ['bagel', 'bread']),
  TagEmoji('🫓', TagEmojiGroup.grains, ['flatbread', 'pita', 'naan']),
  TagEmoji('🥨', TagEmojiGroup.grains, ['pretzel', 'baking']),
  TagEmoji('🍚', TagEmojiGroup.grains, ['rice', 'grain']),
  TagEmoji('🍝', TagEmojiGroup.grains, ['pasta', 'spaghetti', 'italian']),
  TagEmoji('🌾', TagEmojiGroup.grains, ['wheat', 'grain', 'flour']),
  TagEmoji('🥣', TagEmojiGroup.grains, ['porridge', 'cereal', 'breakfast']),

  // ── Sweets ───────────────────────────────────────────────────────────────
  TagEmoji('🍰', TagEmojiGroup.sweets, ['cake', 'slice', 'dessert']),
  TagEmoji('🎂', TagEmojiGroup.sweets, ['birthday', 'cake', 'celebration']),
  TagEmoji('🧁', TagEmojiGroup.sweets, ['cupcake', 'muffin', 'baking']),
  TagEmoji('🍪', TagEmojiGroup.sweets, ['cookie', 'biscuit', 'baking']),
  TagEmoji('🍫', TagEmojiGroup.sweets, ['chocolate', 'sweets']),
  TagEmoji('🍬', TagEmojiGroup.sweets, ['candy', 'sweets']),
  TagEmoji('🍩', TagEmojiGroup.sweets, ['doughnut', 'donut', 'sweet']),
  TagEmoji('🥧', TagEmojiGroup.sweets, ['pie', 'tart', 'baking']),
  TagEmoji('🍮', TagEmojiGroup.sweets, ['custard', 'pudding', 'flan']),
  TagEmoji('🍦', TagEmojiGroup.sweets, ['ice cream', 'dessert', 'frozen']),
  TagEmoji('🍯', TagEmojiGroup.sweets, ['honey', 'sweet', 'syrup']),

  // ── Drinks ───────────────────────────────────────────────────────────────
  TagEmoji('☕', TagEmojiGroup.drinks, ['coffee', 'hot drink']),
  TagEmoji('🍵', TagEmojiGroup.drinks, ['tea', 'hot drink', 'matcha']),
  TagEmoji('🧃', TagEmojiGroup.drinks, ['juice', 'box']),
  TagEmoji('🥤', TagEmojiGroup.drinks, ['soda', 'soft drink', 'cup']),
  TagEmoji('🧋', TagEmojiGroup.drinks, ['bubble tea', 'smoothie', 'shake']),
  TagEmoji('🍷', TagEmojiGroup.drinks, ['wine', 'red', 'glass']),
  TagEmoji('🍺', TagEmojiGroup.drinks, ['beer', 'pint']),
  TagEmoji('🍸', TagEmojiGroup.drinks, ['cocktail', 'martini', 'bar']),
  TagEmoji('🥂', TagEmojiGroup.drinks, ['champagne', 'toast', 'celebration']),
  TagEmoji('🍹', TagEmojiGroup.drinks, ['cocktail', 'tropical', 'summer']),
  TagEmoji('🫖', TagEmojiGroup.drinks, ['teapot', 'brew']),

  // ── Meals & dishes ───────────────────────────────────────────────────────
  TagEmoji('🍲', TagEmojiGroup.dishes, ['stew', 'pot', 'soup', 'one pot']),
  TagEmoji('🥘', TagEmojiGroup.dishes, ['paella', 'pan', 'sunday']),
  TagEmoji('🍜', TagEmojiGroup.dishes, ['ramen', 'noodles', 'soup']),
  TagEmoji('🍛', TagEmojiGroup.dishes, ['curry', 'rice']),
  TagEmoji('🍕', TagEmojiGroup.dishes, ['pizza', 'italian']),
  TagEmoji('🍔', TagEmojiGroup.dishes, ['burger', 'fast food']),
  TagEmoji('🌮', TagEmojiGroup.dishes, ['taco', 'mexican']),
  TagEmoji('🌯', TagEmojiGroup.dishes, ['burrito', 'wrap', 'mexican']),
  TagEmoji('🥗', TagEmojiGroup.dishes, ['salad', 'greens', 'light']),
  TagEmoji('🥪', TagEmojiGroup.dishes, ['sandwich', 'lunch']),
  TagEmoji('🍣', TagEmojiGroup.dishes, ['sushi', 'japanese']),
  TagEmoji('🍱', TagEmojiGroup.dishes, ['bento', 'lunch box', 'meal prep']),
  TagEmoji('🥟', TagEmojiGroup.dishes, ['dumpling', 'asian']),
  TagEmoji('🍟', TagEmojiGroup.dishes, ['fries', 'chips', 'fast food']),
  TagEmoji('🥞', TagEmojiGroup.dishes, ['pancakes', 'breakfast']),
  TagEmoji('🧆', TagEmojiGroup.dishes, ['falafel', 'middle eastern']),
  TagEmoji('🫕', TagEmojiGroup.dishes, ['fondue', 'sharing', 'melted']),
  TagEmoji('🍿', TagEmojiGroup.dishes, ['popcorn', 'snack', 'film night']),

  // ── Kitchen ──────────────────────────────────────────────────────────────
  TagEmoji('🔥', TagEmojiGroup.kitchen, ['hot', 'spicy', 'grill', 'fire']),
  TagEmoji('❄️', TagEmojiGroup.kitchen, ['freezer', 'frozen', 'cold']),
  TagEmoji('🧊', TagEmojiGroup.kitchen, ['ice', 'chilled', 'cold']),
  TagEmoji('🍴', TagEmojiGroup.kitchen, ['cutlery', 'eat', 'dinner']),
  TagEmoji('🥄', TagEmojiGroup.kitchen, ['spoon', 'stir']),
  TagEmoji('🔪', TagEmojiGroup.kitchen, ['knife', 'chop', 'prep']),
  TagEmoji('🧂', TagEmojiGroup.kitchen, ['salt', 'seasoning', 'spices']),
  TagEmoji('🫙', TagEmojiGroup.kitchen, ['jar', 'preserve', 'pickling']),
  TagEmoji('🥫', TagEmojiGroup.kitchen, ['tin', 'can', 'sauce', 'store cupboard']),
  TagEmoji('🧺', TagEmojiGroup.kitchen, ['basket', 'picnic', 'shopping']),
  TagEmoji('⏱️', TagEmojiGroup.kitchen, ['timer', 'quick', 'minutes']),
  TagEmoji('🏷️', TagEmojiGroup.kitchen, ['label', 'tag', 'other']),

  // ── Occasions ────────────────────────────────────────────────────────────
  TagEmoji('⭐', TagEmojiGroup.occasions, ['favourite', 'favorite', 'best']),
  TagEmoji('❤️', TagEmojiGroup.occasions, ['love', 'favourite']),
  TagEmoji('🎉', TagEmojiGroup.occasions, ['party', 'celebration']),
  TagEmoji('🎄', TagEmojiGroup.occasions, ['christmas', 'holiday', 'winter']),
  TagEmoji('🎃', TagEmojiGroup.occasions, ['halloween', 'autumn', 'pumpkin']),
  TagEmoji('👨‍👩‍👧', TagEmojiGroup.occasions, ['family', 'kids']),
  TagEmoji('👶', TagEmojiGroup.occasions, ['baby', 'kids', 'toddler']),
  TagEmoji('☀️', TagEmojiGroup.occasions, ['summer', 'sunny', 'bbq']),
  TagEmoji('🌙', TagEmojiGroup.occasions, ['evening', 'late', 'supper']),
  TagEmoji('🏕️', TagEmojiGroup.occasions, ['camping', 'outdoors']),
  TagEmoji('🌱', TagEmojiGroup.occasions, ['vegan', 'plant based', 'green']),
  TagEmoji('🥇', TagEmojiGroup.occasions, ['best', 'winner', 'top']),
  TagEmoji('💰', TagEmojiGroup.occasions, ['cheap', 'budget', 'thrifty']),
  TagEmoji('🕐', TagEmojiGroup.occasions, ['slow', 'long', 'time']),
];

List<TagEmoji> tagEmojiIn(TagEmojiGroup group) =>
    [for (final e in kTagEmoji) if (e.group == group) e];
