// "Start linking" — where the Add-food sheet sends you when you tap a recipe
// that has no pantry links yet.
//
// The rule this exists to keep: a recipe with nothing linked has no numbers,
// and the diary must not log a zero dressed up as a measurement. So the tap
// that would have logged the lie opens the fix instead — every ingredient
// line in one list, each one a door to the pantry picker.
//
// Linking already lives on the recipe page as a long-press per row. That is
// the right gesture when you are READING a recipe; it is the wrong one when
// you came here to eat, so this sheet makes the same edit reachable in one
// tap and hands the caller the saved recipe back.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/product.dart';
import '../../domain/recipe.dart';
import '../library_model.dart';
import '../pantry/pantry_model.dart';
import '../theme.dart';
import '../widgets/product_picker_sheet.dart';
import '../widgets/skin.dart';

/// Returns the recipe as it now stands — the same object when nothing was
/// linked, so the caller can tell a no-op from real progress.
/// What the linking sheet came back with.
///
/// [logAnyway] is the escape hatch: design 2b routes an unlinked recipe into
/// linking instead of logging, which is right for the common case but would
/// otherwise delete "I ate this, I don't know the numbers" as a recordable
/// fact (Arnar's call 2026-08-27). The meal happened either way; a diary that
/// can only record the meals you were willing to itemise is a diary that
/// quietly under-counts.
class LinkRecipeResult {
  const LinkRecipeResult(this.recipe, {this.logAnyway = false});

  final Recipe recipe;
  final bool logAnyway;
}

Future<LinkRecipeResult?> showLinkRecipeSheet(BuildContext context,
    {required Recipe recipe}) async {
  final pantry = context.read<PantryModel>();
  final library = context.read<LibraryModel>();
  await pantry.ensureLoaded();
  if (!context.mounted) return null;
  return showModalBottomSheet<LinkRecipeResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => MultiProvider(
      providers: [
        ChangeNotifierProvider<PantryModel>.value(value: pantry),
        ChangeNotifierProvider<LibraryModel>.value(value: library),
      ],
      child: _LinkRecipeSheet(recipe: recipe),
    ),
  );
}

class _LinkRecipeSheet extends StatefulWidget {
  const _LinkRecipeSheet({required this.recipe});

  final Recipe recipe;

  @override
  State<_LinkRecipeSheet> createState() => _LinkRecipeSheetState();
}

class _LinkRecipeSheetState extends State<_LinkRecipeSheet> {
  late Recipe _recipe = widget.recipe;

  /// Recipe-detail's picker, verbatim: the USER is the matcher. "250 ml milk"
  /// means their Mellommelk and only they know that; nothing here guesses.
  Future<void> _link(int index) async {
    final pantry = context.read<PantryModel>();
    final ing = _recipe.ingredients[index];
    final pick = await showProductPickerSheet(
      context,
      pantry: pantry,
      title: 'Which product is "${ing.item ?? ing.raw}"?',
      allowUnlink: ing.productRef != null,
    );
    if (!mounted || pick == null) return;
    final next = [..._recipe.ingredients];
    final chosen = pick.product;
    next[index] = chosen == null
        ? ing.copyWith(clearProductRef: true)
        : ing.copyWith(productRef: chosen.id);
    final edited = _recipe.copyWith(ingredients: next);
    setState(() => _recipe = edited);
    // The link belongs in the recipe FILE, not in this sheet's head — it has
    // to be there the next time any screen asks what this recipe costs.
    try {
      await context.read<LibraryModel>().saveImported(edited, const []);
    } catch (_) {
      // The screen already shows the link; a save that fails surfaces through
      // the storage screen's own path, not an error banner here (§7).
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final pantry = context.watch<PantryModel>();
    final products = {for (final p in pantry.products) p.id: p};
    final linked =
        _recipe.ingredients.where((i) => i.productRef != null).length;
    final media = MediaQuery.of(context);
    final insets = media.viewInsets.bottom;
    final systemBar = insets > 0 ? 0.0 : media.viewPadding.bottom;

    // Two honest dead ends, said plainly rather than drawn as an empty list.
    final String? blocked = _recipe.ingredients.isEmpty
        ? 'This recipe has no ingredient lines, so there is nothing to link '
            'yet. Add its ingredients on the recipe page first.'
        : pantry.products.isEmpty
            ? 'Your pantry is empty — scan some products on the Pantry tab '
                'first, then link them here.'
            : null;

    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        builder: (_, controller) => Column(children: [
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                Text(_recipe.title,
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontSize: 22, letterSpacing: -0.3)),
                const SizedBox(height: 6),
                Text(
                  blocked ??
                      'Point each line at the pantry food it means. The '
                          'recipe gets real numbers from what you link — '
                          'unlinked lines are simply left out of the estimate.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
                ),
                if (blocked == null) ...[
                  const SizedBox(height: 18),
                  SectionLabel(
                      'Ingredients · $linked of ${_recipe.ingredients.length} linked'),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _recipe.ingredients.length; i++)
                    _IngredientRow(
                      ingredient: _recipe.ingredients[i],
                      product: products[_recipe.ingredients[i].productRef],
                      onTap: () => _link(i),
                    ),
                ],
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + systemBar),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context)
                        .pop(LinkRecipeResult(_recipe)),
                    child: Text(linked > 0 ? 'Done — log it' : 'Done'),
                  ),
                ),
                // Nothing linked and no appetite for linking now: the meal
                // still happened. The log sheet behind this says out loud
                // that it carries no numbers, and the entry stores ABSENT
                // values — never zeros, which would drag every average down.
                if (linked == 0 && blocked == null)
                  TextButton(
                    key: const Key('log-without-numbers'),
                    onPressed: () => Navigator.of(context)
                        .pop(LinkRecipeResult(_recipe, logAnyway: true)),
                    child: const Text('Log it without numbers'),
                  ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow(
      {required this.ingredient, required this.product, required this.onTap});

  final Ingredient ingredient;
  final Product? product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final done = product != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TokenCard(
        radius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: InkWell(
          onTap: onTap,
          child: Row(children: [
            Icon(done ? Icons.link_rounded : Icons.link_off_rounded,
                size: 18,
                color: done ? scheme.primary : scheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ingredient.raw,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall),
                  Text(product?.name ?? 'Tap to link a pantry food',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
