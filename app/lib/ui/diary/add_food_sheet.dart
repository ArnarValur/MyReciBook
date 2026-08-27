// "Add to <meal>" — the picker, redrawn as a tabbed sheet (design 2a/2b).
//
// Two intents, two tabs, because they are not the same act: PANTRY is
// hand-picking ingredients into the meal, RECIPES is logging a whole dish as
// the meal. The recipe path used to be a collapsed strip above the shelf,
// which is to say buried; it is the flow the product is built around, so it
// gets half the sheet.
//
// Both shelves open FOLDED and stay folded until asked. Flat-rendering the
// pantry is what made this sheet slow to open — 226 products, a 57-item spice
// wall, built to draw a header nobody had tapped. CollapsibleShelf never calls
// a closed section's builder, and that is the whole performance fix.
//
// Search sits above the tabs and reaches both: typing flattens the shelves
// into plain result lists, and the tab labels carry the other side's match
// count so a hit is never hidden behind a tab you are not on.
//
// Scan and "create food" are gone from here — that is pantry management, and
// it lives on the Pantry tab. This sheet only adds to the meal.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/diary.dart';
import '../../domain/product.dart';
import '../../domain/product_categories.dart';
import '../../domain/recipe.dart';
import '../../domain/recipe_nutrition.dart';
import '../../domain/recipe_tag.dart';
import '../library_model.dart';
import '../pantry/pantry_model.dart';
import '../tags_model.dart';
import '../../features.dart';
import '../theme.dart';
import '../widgets/collapsible_shelf.dart';
import '../widgets/product_row.dart';
import '../widgets/skin.dart';
import 'diary_model.dart';
import 'diary_tab.dart' show showAmountDialog;
import 'link_recipe_sheet.dart';
import 'log_food_sheet.dart';
import 'log_recipe_sheet.dart';

/// The label the tag shelf pins last — recipes nobody has filed yet.
const String _untagged = 'Untagged';

Future<void> showAddFoodSheet(BuildContext context,
    {required String meal}) async {
  final diary = context.read<DiaryModel>();
  final pantry = context.read<PantryModel>();
  // The library and the tag decorations are both optional here: the diary
  // must work in shells (and widget tests) that never mounted them. Missing
  // means no recipes to offer, and tags drawn plain — never a crash.
  final library = _maybe<LibraryModel>(context);
  final tags = _maybe<TagsModel>(context);
  await pantry.ensureLoaded();
  await diary.ensureRecents();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => MultiProvider(
      // The sheet is a separate route: it needs the shell's models handed to
      // it explicitly, the same way the pushed detail routes do.
      providers: [
        ChangeNotifierProvider<DiaryModel>.value(value: diary),
        ChangeNotifierProvider<PantryModel>.value(value: pantry),
        if (library != null)
          ChangeNotifierProvider<LibraryModel>.value(value: library),
        if (tags != null) ChangeNotifierProvider<TagsModel>.value(value: tags),
      ],
      child: _AddFoodSheet(meal: meal),
    ),
  );
}

T? _maybe<T>(BuildContext context) {
  try {
    return context.read<T>();
  } catch (_) {
    return null;
  }
}

class _AddFoodSheet extends StatefulWidget {
  const _AddFoodSheet({required this.meal});

  final String meal;

  @override
  State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<_AddFoodSheet> {
  final _search = TextEditingController();
  String _query = '';

  /// 0 = Pantry, 1 = Recipes. Pantry opens first: RECENT lives there, and the
  /// two-tap re-log is still the commonest thing anyone does here.
  int _tab = 0;

  /// Open shelf sections, per shelf so a category and a tag of the same name
  /// cannot toggle each other. Plain screen state: a modal that reopens
  /// half-unfolded is a modal that got slow again, so this is never persisted.
  final Set<String> _openCategories = {};
  final Set<String> _openTags = {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _searching => _query.trim().isNotEmpty;

  /// Everything on the shelf whose name, brand or synonym contains the
  /// query — synonyms are how "Paprika" finds Bell Pepper (starter foods
  /// carry Norwegian names there). No fuzzy matching: the user's own pantry
  /// is small enough that substring search is honest and instant.
  List<Product> _matches(List<Product> products) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return products;
    return [
      for (final p in products)
        if (p.name.toLowerCase().contains(q) ||
            (p.brand ?? '').toLowerCase().contains(q) ||
            p.synonyms.any((s) => s.toLowerCase().contains(q)))
          p
    ];
  }

  /// Recipes whose title or tag contains the query — a tag is a name the user
  /// invented for a shelf, so searching it has to reach the shelf.
  List<Recipe> _recipeMatches(List<Recipe> recipes) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return recipes;
    return [
      for (final r in recipes)
        if (r.title.toLowerCase().contains(q) ||
            r.tags.any((t) => t.toLowerCase().contains(q)))
          r
    ];
  }

  Future<void> _log(Product product) async {
    final logged = await showLogFoodSheet(context,
        product: product, meal: widget.meal);
    if (logged == true && mounted) Navigator.of(context).pop();
  }

  /// Tapping a recipe. The branch that matters: a recipe with nothing linked
  /// has no numbers, so the tap opens the LINKING sheet rather than logging a
  /// meal of zero kcal. Come back with links and it logs; back out and nothing
  /// is written.
  ///
  /// The exception is deliberate: the linking sheet offers "log it without
  /// numbers", because the meal happened whether or not anyone linked it. That
  /// entry stores ABSENT values, not zeros — the diary's own rule, and the
  /// reason a blank nutrient never drags an average down.
  Future<void> _openRecipe(Recipe recipe) async {
    final products = _productsById(context.read<PantryModel>());
    var current = recipe;
    var nutrition = recipeNutrition(current, products);
    if (nutrition.isEmpty) {
      final result = await showLinkRecipeSheet(context, recipe: current);
      if (!mounted || result == null) return;
      current = result.recipe;
      nutrition = recipeNutrition(
          current, _productsById(context.read<PantryModel>()));
      if (nutrition.isEmpty && !result.logAnyway) return;
    }
    final logged = await showLogRecipeSheet(context,
        recipe: current, nutrition: nutrition, meal: widget.meal);
    if (logged == true && mounted) Navigator.of(context).pop();
  }

  Map<String, Product> _productsById(PantryModel pantry) =>
      {for (final p in pantry.products) p.id: p};

  Future<void> _logAgain(DiaryEntry previous) async {
    await context.read<DiaryModel>().logAgain(previous, meal: widget.meal);
    if (mounted) Navigator.of(context).pop();
  }

  /// Calories with no food behind them — the meal out nobody itemises. It is
  /// the one door on the dropped chip row that was never pantry management,
  /// so it stays, demoted to a footer instead of permanent top chrome.
  Future<void> _quickAdd() async {
    final kcal = await showAmountDialog(
      context,
      title: 'Quick add',
      subtitle: 'Calories only, no food behind them — for the meal out you '
          'are never going to itemise.',
      label: 'kcal',
      confirm: 'Add',
    );
    if (kcal == null || !mounted) return;
    await context.read<DiaryModel>().logQuickAdd(meal: widget.meal, kcal: kcal);
    if (mounted) Navigator.of(context).pop();
  }

  // --- shelves -------------------------------------------------------------

  /// The pantry shelf: product_categories' own grouping and order, so this
  /// shelf and the Pantry tab's list the same food under the same heading.
  List<ShelfSection> _categorySections(PantryModel pantry) => [
        for (final (name, items) in groupByCategory(pantry.products))
          ShelfSection(
            id: name,
            label: categoryLabel(name),
            count: items.length,
            // A bundled pack, not the user's own scans — the leaf says why a
            // 60-item section is worth leaving folded.
            starterPack: items.every((p) => p.source == 'starter'),
            builder: (_) => Column(
              children: [
                for (final product in items)
                  ProductRow(
                    product: product,
                    imageFile: pantry.imageFileOf(product),
                    onTap: () => _log(product),
                  ),
              ],
            ),
          ),
      ];

  /// The recipe shelf, by the cookbook's own tags. Tags overlap by design, so
  /// a recipe appears under every tag it carries — a shelf is a view, not a
  /// filing cabinet. Untagged is pinned last.
  List<ShelfSection> _tagSections(
      List<Recipe> recipes, TagsModel? tags, LibraryModel? library) {
    final buckets = <String, List<Recipe>>{};
    final untagged = <Recipe>[];
    // Canonical keys bucket "Weeknight" and "weeknight " together; the first
    // spelling seen wins the label, the same rule TagsModel uses.
    final display = <String, String>{};
    for (final recipe in recipes) {
      if (recipe.tags.isEmpty) {
        untagged.add(recipe);
        continue;
      }
      for (final tag in recipe.tags) {
        final key = RecipeTag.canonical(tag);
        display.putIfAbsent(key, () => tag);
        (buckets[key] ??= []).add(recipe);
      }
    }
    // The user's own tag order first (Settings owns it), then anything the
    // recipe files carry that tags.json has never heard of, alphabetically.
    final ordered = <String>[];
    for (final tag in tags?.tags ?? const <RecipeTag>[]) {
      final key = RecipeTag.canonical(tag.name);
      if (buckets.containsKey(key)) ordered.add(key);
    }
    final rest = [
      for (final key in buckets.keys)
        if (!ordered.contains(key)) key
    ]..sort((a, b) => a.compareTo(b));
    ordered.addAll(rest);

    ShelfSection section(String id, String label, List<Recipe> items) =>
        ShelfSection(
          id: id,
          label: label,
          count: items.length,
          builder: (_) => Column(
            children: [
              for (final recipe in items) _recipeRow(recipe, library),
            ],
          ),
        );

    return [
      for (final key in ordered)
        section(key, _tagLabel(display[key]!, tags), buckets[key]!),
      if (untagged.isNotEmpty) section(_untagged, _untagged, untagged),
    ];
  }

  /// A tag's shelf heading. The shelf header is plain text, so only an emoji
  /// icon can travel with the name — a catalog-icon tag shows its name alone
  /// here, and wears its glyph everywhere a real TagChip is drawn.
  String _tagLabel(String name, TagsModel? tags) {
    final tag = tags?.chipFor(name);
    if (tag == null || !tag.isEmojiIcon) return name;
    return '${tag.icon} $name';
  }

  Widget _recipeRow(Recipe recipe, LibraryModel? library) => _RecipeRow(
        recipe: recipe,
        nutrition: recipeNutrition(
            recipe, _productsById(context.read<PantryModel>())),
        // Only a recipe with a cover the user actually picked pays for a file
        // lookup; the rest draw the book fallback with no IO at all.
        cover: recipe.cover == null || library == null
            ? null
            : library.coverFor(recipe),
        onTap: () => _openRecipe(recipe),
      );

  // --- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final pantry = context.watch<PantryModel>();
    final diary = context.watch<DiaryModel>();
    final library = _maybeWatch<LibraryModel>(context);
    final tags = _maybeWatch<TagsModel>(context);

    final productMatches = _matches(pantry.products);
    final recipeMatches = _recipeMatches(library?.recipes ?? const []);
    final media = MediaQuery.of(context);
    final insets = media.viewInsets.bottom;
    // Same gesture-bar rule as the log sheet: the last row must clear it.
    final systemBar = insets > 0 ? 0.0 : media.viewPadding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + systemBar),
          children: [
            Text('Add to ${widget.meal.toLowerCase()}',
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontSize: 22, letterSpacing: -0.3)),
            const SizedBox(height: 12),
            TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: library == null
                    ? 'Search your pantry'
                    : 'Search pantry and recipes',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: scheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
              ),
            ),
            // With no library there is nothing to switch to, so the tab pair
            // would be a control with one option.
            if (library != null) ...[
              const SizedBox(height: 12),
              _TabPair(
                index: _tab,
                onSelect: (i) => setState(() => _tab = i),
                // Counts only while searching — a badge that never changes is
                // noise, and one that appears mid-typing says "the hit is on
                // the other tab" without making anyone go and look.
                pantryCount: _searching ? productMatches.length : null,
                recipeCount: _searching ? recipeMatches.length : null,
              ),
            ],
            const SizedBox(height: 16),
            if (_tab == 1 && library != null)
              ..._recipesTab(theme, scheme, recipeMatches, tags, library)
            else
              ..._pantryTab(theme, scheme, pantry, diary, productMatches),
          ],
        ),
      ),
    );
  }

  T? _maybeWatch<T extends Listenable>(BuildContext context) {
    try {
      return context.watch<T>();
    } catch (_) {
      return null;
    }
  }

  List<Widget> _pantryTab(ThemeData theme, ColorScheme scheme,
      PantryModel pantry, DiaryModel diary, List<Product> matches) {
    return [
      if (_searching) ...[
        SectionLabel('Pantry · ${matches.length} match'
            '${matches.length == 1 ? '' : 'es'}'),
        const SizedBox(height: 8),
        if (matches.isEmpty)
          _note(theme, scheme,
              'Nothing on the shelf matches that. Add it on the Pantry tab — '
              'scan its barcode, or create the food by hand.')
        else
          for (final product in matches)
            ProductRow(
              product: product,
              imageFile: pantry.imageFileOf(product),
              onTap: () => _log(product),
            ),
      ] else ...[
        // RECENT stays pinned above the shelf: re-logging yesterday's oats is
        // two taps and must never become "unfold Breakfast, then tap".
        if (diary.recents.isNotEmpty) ...[
          const SectionLabel('Recent'),
          const SizedBox(height: 8),
          for (final entry in diary.recents.take(8)) ...[
            _RecentRow(entry: entry, onTap: () => _logAgain(entry)),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
        ],
        const SectionLabel('Your pantry'),
        const SizedBox(height: 8),
        if (pantry.products.isEmpty)
          _note(theme, scheme,
              'Your pantry is empty. Fill it on the Pantry tab — scan a '
              'barcode, or create a food by hand; an apple has no barcode '
              'either.')
        else
          CollapsibleShelf(
            sections: _categorySections(pantry),
            expanded: _openCategories,
            onToggle: (id) => setState(() => _openCategories.contains(id)
                ? _openCategories.remove(id)
                : _openCategories.add(id)),
          ),
      ],
      if (kQuickAddEnabled) ...[
        const SizedBox(height: 16),
        Row(children: [
          MetaChip(
              icon: Icons.bolt_rounded, label: 'Quick add', onTap: _quickAdd),
        ]),
      ],
    ];
  }

  List<Widget> _recipesTab(ThemeData theme, ColorScheme scheme,
      List<Recipe> matches, TagsModel? tags, LibraryModel library) {
    if (_searching) {
      return [
        SectionLabel('Recipes · ${matches.length} match'
            '${matches.length == 1 ? '' : 'es'}'),
        const SizedBox(height: 8),
        if (matches.isEmpty)
          _note(theme, scheme, 'No recipe in your cookbook matches that.')
        else
          for (final recipe in matches) _recipeRow(recipe, library),
      ];
    }
    if (library.recipes.isEmpty) {
      return [
        const SectionLabel('Your recipes · by tag'),
        const SizedBox(height: 8),
        _note(theme, scheme,
            'Your cookbook is empty. Import a recipe first, then it can be '
            'logged as a meal from here.'),
      ];
    }
    return [
      const SectionLabel('Your recipes · by tag'),
      const SizedBox(height: 8),
      CollapsibleShelf(
        sections: _tagSections(library.recipes, tags, library),
        expanded: _openTags,
        onToggle: (id) => setState(() =>
            _openTags.contains(id) ? _openTags.remove(id) : _openTags.add(id)),
      ),
      const SizedBox(height: 12),
      Text(
        'A recipe logs as one diary line — its numbers come from its linked '
        'ingredients.',
        style: theme.textTheme.bodySmall
            ?.copyWith(color: scheme.onSurfaceVariant, height: 1.45),
      ),
    ];
  }
}

/// The quiet explanatory paragraph the empty states share.
Widget _note(ThemeData theme, ColorScheme scheme, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Text(text,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5)),
    );

/// Pantry | Recipes — the segmented pill, the shell's own tab control at
/// sheet scale. Two intents, never a filter: switching does not narrow the
/// other side, it changes what you are doing.
class _TabPair extends StatelessWidget {
  const _TabPair({
    required this.index,
    required this.onSelect,
    this.pantryCount,
    this.recipeCount,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final int? pantryCount;
  final int? recipeCount;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(children: [
        _Segment(
          icon: Icons.kitchen_rounded,
          label: 'Pantry',
          count: pantryCount,
          selected: index == 0,
          onTap: () => onSelect(0),
        ),
        _Segment(
          icon: Icons.menu_book_rounded,
          label: 'Recipes',
          count: recipeCount,
          selected: index == 1,
          onTap: () => onSelect(1),
        ),
      ]),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final rb = context.rb;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: selected
              ? BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: rb.cardShadow,
                )
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(count == null ? label : '$label · $count',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

/// A recipe the diary can log. The row carries the linkage state, because
/// that is what decides whether tapping it logs a meal or starts linking —
/// and the kcal is always prefixed "~": it comes from pantry links, not a
/// label. A recipe with nothing linked shows no number at all rather than a 0.
class _RecipeRow extends StatelessWidget {
  const _RecipeRow({
    required this.recipe,
    required this.nutrition,
    required this.cover,
    required this.onTap,
  });

  final Recipe recipe;
  final RecipeNutrition nutrition;

  /// Null when the recipe has no cover picked — the book icon is the
  /// fallback, and screenshots are never promoted into one.
  final Future<File?>? cover;
  final VoidCallback onTap;

  String get _subtitle {
    if (nutrition.isEmpty) return 'no linked ingredients yet';
    return nutrition.perServing == null ? 'whole recipe' : 'per serving';
  }

  /// Null keeps the pill off: a covered recipe whose products carry no kcal
  /// has an honest blank, never a zero.
  double? get _kcal => (nutrition.perServing ?? nutrition.total).kcal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final kcal = nutrition.isEmpty ? null : _kcal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TokenCard(
        radius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: InkWell(
          onTap: onTap,
          child: Row(children: [
            _Cover(cover: cover),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall),
                  Text(_subtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (kcal != null) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('~${kcal.round()} kcal',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.cover});

  final Future<File?>? cover;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final fallback = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.menu_book_rounded, size: 17, color: scheme.primary),
    );
    if (cover == null) return fallback;
    return FutureBuilder<File?>(
      future: cover,
      builder: (_, snap) {
        final file = snap.data;
        if (file == null || !file.existsSync()) return fallback;
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(file,
              width: 34, height: 34, fit: BoxFit.cover, cacheWidth: 102),
        );
      },
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.entry, required this.onTap});

  final DiaryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    return TokenCard(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: InkWell(
        onTap: onTap,
        child: Row(children: [
          Icon(Icons.history_rounded, size: 18, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall),
                Text(entry.servingSummary,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          Text('${(entry.total.kcal ?? 0).round()} kcal',
              style: theme.textTheme.labelMedium),
        ]),
      ),
    );
  }
}
