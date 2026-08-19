// Manual entry — the 5b promise "Typing recipes in yourself is always
// unlimited": no AI, no cap, no images. Builds a source.type "manual" recipe
// file (schema-additive — old files unaffected) and saves through the same
// LibraryModel seam as imports, so grocery/storage integration rides along.
//
// Born parsed (Arnar, 2026-08-19): each ingredient line runs through the
// deterministic parseIngredientLine at save, and a live "From your pantry"
// section lets lines be hand-linked to pantry products — so a typed-in
// recipe is calorie-computable from its first save. Manual save only; this
// rule never rewrites imported files.
//
// DEVIATION (for Arnar to ratify): no hi-fi mockup exists for this screen —
// 5b names the promise, 4c/4d name the door. Assembled from the 3c review
// patterns: title card, section-labeled cards with one line per
// ingredient/step, pill inputs for servings/time, stadium CTA.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../data/saf_store.dart';
import '../domain/ingredient_parse.dart';
import '../domain/recipe.dart';
import '../domain/validate.dart';
import '../features.dart';
import 'library_model.dart';
import 'pantry/pantry_model.dart';
import 'theme.dart';
import 'widgets/product_row.dart';
import 'widgets/skin.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _title = TextEditingController();
  final _ingredients = TextEditingController();
  final _steps = TextEditingController();
  final _servings = TextEditingController();
  final _times = TextEditingController();
  bool _saving = false;

  /// Pantry links, keyed by the TRIMMED line text → product id. Text is the
  /// identity on purpose (Arnar, 2026-08-19): editing a line simply loses its
  /// link — honest and simple, no index bookkeeping across field edits.
  final Map<String, String> _links = {};

  @override
  void initState() {
    super.initState();
    // The "From your pantry" section mirrors the field live, line by line.
    _ingredients.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _ingredients.dispose();
    _steps.dispose();
    _servings.dispose();
    _times.dispose();
    super.dispose();
  }

  static List<String> _lines(TextEditingController c) => [
        for (final l in c.text.split('\n'))
          if (l.trim().isNotEmpty) l.trim()
      ];

  Ingredient _ingredientFromLine(String line) {
    final parsed = parseIngredientLine(line);
    return Ingredient(
      raw: line,
      qty: parsed.qty,
      unit: parsed.unit,
      item: parsed.item.isEmpty ? null : parsed.item,
      productRef: _links[line],
    );
  }

  /// Pantry the screen can reach, or null: flag off, or no model above
  /// (bare harness) — either way the section degrades to nothing.
  PantryModel? _pantry() {
    if (!kPantryEnabled) return null;
    try {
      return context.read<PantryModel>();
    } catch (_) {
      return null;
    }
  }

  /// "2 dl" / "2" — the parsed quantity as a muted prefix; null when the
  /// line has no leading number.
  static String? _qtyPrefix(ParsedQty parsed) {
    final qty = parsed.qty;
    if (qty == null) return null;
    final n = qty == qty.roundToDouble() ? qty.round().toString() : qty.toString();
    return parsed.unit == null ? n : '$n ${parsed.unit}';
  }

  /// MetaChip's label has no ellipsis of its own; a long product name would
  /// overflow the row, so trim it here.
  static String _chipLabel(String name) =>
      name.length <= 20 ? name : '${name.substring(0, 19).trimRight()}…';

  Future<void> _pickLink(String line, PantryModel pantry) async {
    await pantry.ensureLoaded();
    if (!mounted) return;
    final parsed = parseIngredientLine(line);
    final choice = await showModalBottomSheet<_LinkChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      // Separate route: the model must be handed down explicitly, same as
      // the add-food sheet does.
      builder: (_) => ChangeNotifierProvider<PantryModel>.value(
        value: pantry,
        child: _LinkPickerSheet(item: parsed.item.isEmpty ? line : parsed.item),
      ),
    );
    if (choice == null || !mounted) return; // dismissed — no change
    setState(() {
      final id = choice.productId;
      if (id == null) {
        _links.remove(line);
      } else {
        _links[line] = id;
      }
    });
  }

  Widget _pantryLineRow(String line, PantryModel pantry) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final parsed = parseIngredientLine(line);
    final ref = _links[line];
    // A product deleted mid-session resolves to null → the chip honestly
    // falls back to 'Link' (dangling refs are display noise, never errors).
    final linked = ref == null ? null : pantry.byId(ref);
    final prefix = _qtyPrefix(parsed);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          if (prefix != null) ...[
            Text(prefix,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(parsed.item.isEmpty ? line : parsed.item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium),
          ),
          const SizedBox(width: 8),
          MetaChip(
            icon: linked == null ? Icons.link_rounded : null,
            label: linked == null ? 'Link' : _chipLabel(linked.name),
            onTap: () => _pickLink(line, pantry),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final servings = _servings.text.trim();
    final times = _times.text.trim();
    final recipe = Recipe(
      schemaVersion: Recipe.currentSchemaVersion,
      id: const Uuid().v4(),
      title: _title.text.trim(),
      // No extraction envelope, no images: nothing was extracted (rule 2 —
      // metadata is stamped by our code only when it is true).
      source: RecipeSource(
          type: 'manual', importedAt: DateTime.now().toIso8601String()),
      servings: servings.isEmpty ? null : Servings(raw: servings),
      times: times.isEmpty ? null : RecipeTimes(raw: times),
      // Born parsed (Arnar, 2026-08-19: recipes calorie-computable from
      // birth): the deterministic parse and any hand-picked pantry link are
      // stored on manual save only — imported files stay untouched by this.
      ingredients: [
        for (final l in _lines(_ingredients)) _ingredientFromLine(l)
      ],
      steps: [for (final l in _lines(_steps)) RecipeStep(raw: l)],
    );

    final blocking =
        fileProblems(recipe.toJson()).where(isSaveBlocking).toList();
    if (blocking.isNotEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(blocking.join(' · '))));
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<LibraryModel>().saveImported(recipe, const []);
    } on GrantLostException {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Folder access was lost — your recipe is kept here. '
              'Try again, or go back and re-pick your folder.')));
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Widget _pillInput(
      {required Key key,
      required TextEditingController controller,
      required IconData icon,
      required String hint}) {
    final scheme = context.scheme;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        border: Border.all(color: context.rb.hairline),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              key: key,
              controller: controller,
              style: Theme.of(context).textTheme.labelMedium,
              decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: hint),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final pantry = _pantry();
    final ingredientLines = _lines(_ingredients);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const AppBackButton(),
                  Text('Type it in yourself', style: theme.textTheme.titleLarge),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: [
                  TokenCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('manual-title'),
                            controller: _title,
                            style: theme.textTheme.titleLarge,
                            decoration: const InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                                hintText: 'Recipe title'),
                          ),
                        ),
                        Icon(Icons.edit_rounded,
                            size: 19, color: scheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _pillInput(
                            key: const Key('manual-servings'),
                            controller: _servings,
                            icon: Icons.restaurant_rounded,
                            hint: '4 servings'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _pillInput(
                            key: const Key('manual-times'),
                            controller: _times,
                            icon: Icons.schedule_rounded,
                            hint: '25 min'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const SectionLabel('Ingredients'),
                  const SizedBox(height: 8),
                  TokenCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: TextField(
                      key: const Key('manual-ingredients'),
                      controller: _ingredients,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                      maxLines: null,
                      minLines: 4,
                      decoration: const InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: 'One ingredient per line'),
                    ),
                  ),
                  // Live pantry mirror of the field above: one compact row
                  // per line, link chip to a pantry product. Linked lines are
                  // what makes the saved recipe's calories countable.
                  if (pantry != null && ingredientLines.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const SectionLabel('From your pantry'),
                    const SizedBox(height: 6),
                    for (final line in ingredientLines)
                      _pantryLineRow(line, pantry),
                  ],
                  const SizedBox(height: 14),
                  const SectionLabel('Steps'),
                  const SizedBox(height: 8),
                  TokenCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: TextField(
                      key: const Key('manual-steps'),
                      controller: _steps,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                      maxLines: null,
                      minLines: 4,
                      decoration: const InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: 'One step per line'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Typed-in recipes are always unlimited — no AI involved.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: const Text('Save to cookbook'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet result: a product id, or null for the 'No product' unlink row —
/// distinct from dismissing the sheet (no _LinkChoice at all, no change).
class _LinkChoice {
  const _LinkChoice(this.productId);
  final String? productId;
}

class _LinkPickerSheet extends StatelessWidget {
  const _LinkPickerSheet({required this.item});

  /// The parsed item of the line being linked — names the question.
  final String item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final pantry = context.watch<PantryModel>();
    final media = MediaQuery.of(context);
    final insets = media.viewInsets.bottom;
    // Add-food's gesture-bar rule: the last row must clear the system bar.
    final systemBar = insets > 0 ? 0.0 : media.viewPadding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + systemBar),
          children: [
            SectionLabel('Which product is "$item"?'),
            const SizedBox(height: 8),
            // Plain unlink row on top — always available, so a wrong link is
            // one tap from gone.
            InkWell(
              key: const Key('link-no-product'),
              onTap: () =>
                  Navigator.of(context).pop(const _LinkChoice(null)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(children: [
                  Icon(Icons.link_off_rounded,
                      size: 20, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Text('No product', style: theme.textTheme.bodyLarge),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            if (pantry.products.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'Your pantry is empty. Scan a barcode or create a food on '
                  'the Pantry tab first, then link it here.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
                ),
              )
            else
              // The same card the Pantry tab shows, photo included.
              // ProductRow carries its own bottom gap, so no spacer here.
              for (final product in pantry.products)
                ProductRow(
                  product: product,
                  imageFile: pantry.imageFileOf(product),
                  onTap: () =>
                      Navigator.of(context).pop(_LinkChoice(product.id)),
                ),
          ],
        ),
      ),
    );
  }
}
