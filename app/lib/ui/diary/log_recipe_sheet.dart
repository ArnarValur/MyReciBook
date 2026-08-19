// The recipe log sheet — the food log sheet's shape for a recipe: say how
// many servings, watch the numbers move, log it. The snapshot is made here
// (entryFromRecipe) and handed to the model whole.
//
// The honesty rule travels with the numbers: the sheet always states what
// the estimate covers ("from N of M ingredients"), and a recipe that never
// says how many it serves logs as the whole recipe — never divided by an
// invented 4 (recipe_nutrition.dart's rule).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/diary.dart';
import '../../domain/nutrient_display.dart';
import '../../domain/product.dart';
import '../../domain/recipe.dart';
import '../../domain/recipe_nutrition.dart';
import '../theme.dart';
import '../widgets/skin.dart';
import 'diary_model.dart';
import 'diary_tab.dart' show parseAmount;

/// Returns true when something was logged.
Future<bool?> showLogRecipeSheet(
  BuildContext context, {
  required Recipe recipe,
  required RecipeNutrition nutrition,
  required String meal,
}) {
  final diary = context.read<DiaryModel>();
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ChangeNotifierProvider<DiaryModel>.value(
      value: diary,
      child: _LogRecipeSheet(recipe: recipe, nutrition: nutrition, meal: meal),
    ),
  );
}

class _LogRecipeSheet extends StatefulWidget {
  const _LogRecipeSheet(
      {required this.recipe, required this.nutrition, required this.meal});

  final Recipe recipe;
  final RecipeNutrition nutrition;
  final String meal;

  @override
  State<_LogRecipeSheet> createState() => _LogRecipeSheetState();
}

class _LogRecipeSheetState extends State<_LogRecipeSheet> {
  late String _meal;
  final _amount = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _meal = widget.meal;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double get _quantity => parseAmount(_amount.text) ?? 0;

  bool get _canLog => _quantity > 0;

  /// Per serving when the recipe declares servings, the whole recipe
  /// otherwise — the same unit entryFromRecipe snapshots.
  Nutriments get _perUnit =>
      widget.nutrition.perServing ?? widget.nutrition.total;

  /// What the estimate actually rests on, said out loud.
  String get _basis {
    final n = widget.nutrition;
    if (n.isEmpty) {
      return 'No ingredients are linked to pantry foods yet, so there are '
          'no numbers to estimate from.';
    }
    final from = 'Estimated from ${n.covered} of ${n.ingredientCount} '
        'ingredient${n.ingredientCount == 1 ? '' : 's'}';
    if (n.perServing == null) {
      return '$from. The recipe never says how many it serves, so this '
          'logs the whole recipe.';
    }
    return '$from, split over ${formatQuantity(n.servings!.toDouble())} '
        'servings.';
  }

  Future<void> _log() async {
    if (_quantity <= 0) return;
    final entry = entryFromRecipe(
      recipe: widget.recipe,
      nutrition: widget.nutrition,
      quantity: _quantity,
      // Placeholder identity: DiaryModel.logEntry stamps the real id and
      // logged-at, the same way every other log path does.
      id: '',
    );
    await context.read<DiaryModel>().logEntry(entry, meal: _meal);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final diary = context.watch<DiaryModel>();
    final nutrition = widget.nutrition;
    final wholeRecipe = nutrition.perServing == null;
    final logged = _perUnit.scaled(_quantity);
    final media = MediaQuery.of(context);
    final insets = media.viewInsets.bottom;
    // Same gesture-bar rule as the food log sheet: a modal sheet gets no
    // SafeArea of its own, and the pinned CTA must clear the S21's bar.
    // When the keyboard is up, viewInsets already covers it — never both.
    final systemBar = insets > 0 ? 0.0 : media.viewPadding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        // Pinned CTA, the food sheet's reasoning: a button you have to find
        // by scrolling is a button people miss.
        builder: (_, controller) => Column(children: [
          Expanded(
              child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              Text(widget.recipe.title,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontSize: 22, letterSpacing: -0.3)),
              const SizedBox(height: 6),
              Text(_basis,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5)),
              const SizedBox(height: 18),

              TextField(
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                    labelText: 'How many servings',
                    helperText:
                        wholeRecipe ? '× whole recipe' : '× serving'),
              ),
              const SizedBox(height: 20),

              const SectionLabel('Meal'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final name in diary.mealNames)
                    _Choice(
                      label: name,
                      selected: name == _meal,
                      onTap: () => setState(() => _meal = name),
                    ),
                ],
              ),
              const SizedBox(height: 22),

              TokenCard(
                radius: 16,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text((logged.kcal ?? 0).round().toString(),
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(fontSize: 30, letterSpacing: -0.8)),
                      const SizedBox(width: 5),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('kcal',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant)),
                      ),
                    ]),
                    if (nutrition.isEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'This will log as servings with no numbers behind '
                        'them. Link ingredients to pantry foods to get an '
                        'estimate.',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant, height: 1.5),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        for (final key in const ['fat', 'carbs', 'protein'])
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    key == 'carbs'
                                        ? 'Carbs'
                                        : nutrientLabel(key),
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(
                                            color: scheme.onSurfaceVariant)),
                                const SizedBox(height: 2),
                                Text('${(logged[key] ?? 0).round()} g',
                                    style: theme.textTheme.titleSmall),
                              ],
                            ),
                          ),
                      ]),
                    ],
                  ],
                ),
              ),
            ],
          )),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + systemBar),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _canLog ? _log : null,
                icon: const Icon(Icons.add_rounded),
                label: Text('Add to $_meal'),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// The food log sheet's selectable pill, duplicated for now — two private
/// copies is still cheaper than a shared widget for a chip this small
/// (Arnar, 2026-08-19: lift to skin.dart when a third sheet wants one).
class _Choice extends StatelessWidget {
  const _Choice(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? scheme.onPrimary : scheme.onSurface),
        ),
      ),
    );
  }
}
