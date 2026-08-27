// The Flutter half of the icon catalog: catalog key → a real Icons constant.
//
// A CONST map on purpose. --tree-shake-icons is on in release builds, and it
// keeps only icons it can see referenced in the source. An IconData built at
// runtime from a codepoint is invisible to it, gets stripped, and renders as a
// hollow box in the release APK while looking perfect in debug. Naming every
// constant here is what makes the shake safe.
//
// Material Symbols Rounded only — brand law, and everything below already
// ships inside the binary. No font package, no asset weight.

import 'package:flutter/material.dart';

import '../../domain/tag_icons.dart';

/// Shown for a key this build does not know: a catalog that shrank, a
/// hand-edited file, a tag written by a newer version. Never a crash.
const IconData kUnknownTagIcon = Icons.label_rounded;

const Map<String, IconData> kFoodIcons = {
  // Dishes
  'pizza': Icons.local_pizza_rounded,
  'pasta': Icons.dinner_dining_rounded,
  'ramen': Icons.ramen_dining_rounded,
  'rice_bowl': Icons.rice_bowl_rounded,
  'soup': Icons.soup_kitchen_rounded,
  'burger': Icons.lunch_dining_rounded,
  'dinner': Icons.restaurant_rounded,
  'breakfast': Icons.breakfast_dining_rounded,
  'brunch': Icons.brunch_dining_rounded,
  'kebab': Icons.kebab_dining_rounded,
  'tapas': Icons.tapas_rounded,
  'seafood': Icons.set_meal_rounded,
  'bakery': Icons.bakery_dining_rounded,
  'fast_food': Icons.fastfood_rounded,
  'takeout': Icons.takeout_dining_rounded,
  'cake': Icons.cake_rounded,
  'cookie': Icons.cookie_rounded,
  'ice_cream': Icons.icecream_rounded,
  'restaurant': Icons.local_dining_rounded,
  'menu_card': Icons.restaurant_menu_rounded,
  'room_service': Icons.room_service_rounded,

  // Ingredients
  'egg': Icons.egg_rounded,
  'fried_egg': Icons.egg_alt_rounded,
  'grain': Icons.grain_rounded,
  'herb': Icons.grass_rounded,
  'flower': Icons.local_florist_rounded,
  'leaf': Icons.eco_rounded,
  'farm': Icons.agriculture_rounded,
  'forest': Icons.forest_rounded,
  'water': Icons.water_drop_rounded,
  'coffee': Icons.coffee_rounded,
  'coffee_pot': Icons.coffee_maker_rounded,
  'tea': Icons.emoji_food_beverage_rounded,
  'cafe': Icons.local_cafe_rounded,
  'drink': Icons.local_drink_rounded,
  'wine': Icons.wine_bar_rounded,
  'cocktail': Icons.local_bar_rounded,
  'beer': Icons.sports_bar_rounded,
  'spirits': Icons.liquor_rounded,

  // Kitchen & tools
  'kitchen': Icons.kitchen_rounded,
  'microwave': Icons.microwave_rounded,
  'blender': Icons.blender_rounded,
  'grill': Icons.outdoor_grill_rounded,
  'stovetop': Icons.countertops_rounded,
  'pot': Icons.soup_kitchen_rounded,
  'cutlery': Icons.flatware_rounded,
  'scale': Icons.scale_rounded,
  'ruler': Icons.straighten_rounded,
  'table': Icons.table_restaurant_rounded,
  'heat': Icons.local_fire_department_rounded,
  'freezer': Icons.ac_unit_rounded,
  'basket': Icons.shopping_basket_rounded,
  'cart': Icons.shopping_cart_rounded,

  // Occasions
  'celebration': Icons.celebration_rounded,
  'gift': Icons.card_giftcard_rounded,
  'festival': Icons.festival_rounded,
  'family': Icons.family_restroom_rounded,
  'crowd': Icons.groups_rounded,
  'sunny': Icons.wb_sunny_rounded,
  'night': Icons.nightlight_rounded,
  'picnic': Icons.beach_access_rounded,
  'camping': Icons.hiking_rounded,
  'calendar': Icons.calendar_month_rounded,

  // Dietary
  'vegan': Icons.spa_rounded,
  'vegetarian': Icons.energy_savings_leaf_rounded,
  'no_meal': Icons.no_meals_rounded,
  'healthy': Icons.monitor_heart_rounded,
  'wellness': Icons.self_improvement_rounded,
  'workout': Icons.fitness_center_rounded,
  'medical': Icons.medical_information_rounded,
  'favorite': Icons.favorite_rounded,

  // Time
  'quick': Icons.bolt_rounded,
  'timer': Icons.timer_rounded,
  'clock': Icons.schedule_rounded,
  'slow': Icons.hourglass_bottom_rounded,
  'alarm': Icons.alarm_rounded,
  'make_ahead': Icons.update_rounded,
  'speed': Icons.speed_rounded,
};

/// The icon for a catalog key, or [kUnknownTagIcon] if this build has no such
/// key. Callers that may hold an emoji must check [isTagIconKey] first.
IconData foodIcon(String key) => kFoodIcons[key] ?? kUnknownTagIcon;
