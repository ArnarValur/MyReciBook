// Manual entry — the 5b promise "Typing recipes in yourself is always
// unlimited": no AI, no cap, no images. Builds a source.type "manual" recipe
// file (schema-additive — old files unaffected) and saves through the same
// LibraryModel seam as imports, so grocery/storage integration rides along.
//
// Row editor (Arnar's turn, 2026-08-19, replacing the free-text v1): one row
// per ingredient that structures itself as you type — the deterministic
// parse shows as chips under the line, tappable to correct, with a pantry
// link chip per row — and numbered step rows. A typed-in recipe is
// calorie-computable from its first save. Manual save only; this rule never
// rewrites imported files.
//
// DEVIATION (for Arnar to ratify on the S21): no hi-fi mockup exists for
// this screen — the row design was picked from ASCII options 2026-08-19.

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

/// One editable row — an ingredient or a step. Ingredients also carry their
/// pantry link and, when the user corrected a bad parse, the override.
class _EntryRow {
  _EntryRow([String initial = ''])
      : text = TextEditingController(text: initial);

  final TextEditingController text;
  final FocusNode focus = FocusNode();
  String? productRef;

  /// Hand-corrected parse. Cleared the moment the line's text changes —
  /// a correction belongs to the text it corrected, never to new text.
  ParsedQty? override;

  ParsedQty get parsed => override ?? parseIngredientLine(text.text);

  void dispose() {
    text.dispose();
    focus.dispose();
  }
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _title = TextEditingController();
  final _servings = TextEditingController();
  final _times = TextEditingController();
  final List<_EntryRow> _ings = [_EntryRow()];
  final List<_EntryRow> _steps = [_EntryRow()];
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _servings.dispose();
    _times.dispose();
    for (final r in [..._ings, ..._steps]) {
      r.dispose();
    }
    super.dispose();
  }

  /// Pantry the screen can reach, or null: flag off, or no model above
  /// (bare harness) — either way the link chips degrade to nothing.
  PantryModel? _pantry() {
    if (!kPantryEnabled) return null;
    try {
      return context.read<PantryModel>();
    } catch (_) {
      return null;
    }
  }

  // --- row plumbing, shared by both lists ---

  void _addRow(List<_EntryRow> rows) {
    setState(() => rows.add(_EntryRow()));
    // Focus the new row on the next frame — it has no element yet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) rows.last.focus.requestFocus();
    });
  }

  void _removeRow(List<_EntryRow> rows, int i) {
    setState(() {
      final gone = rows.removeAt(i);
      // Dispose after the frame — the field may still be unmounting.
      WidgetsBinding.instance.addPostFrameCallback((_) => gone.dispose());
      if (rows.isEmpty) rows.add(_EntryRow());
    });
  }

  /// Enter on a row: hop to the next one, growing the list from the last.
  void _submitRow(List<_EntryRow> rows, int i) {
    if (i == rows.length - 1) {
      _addRow(rows);
    } else {
      rows[i + 1].focus.requestFocus();
    }
  }

  // --- ingredient rows ---

  Future<void> _pickLink(_EntryRow row, PantryModel pantry) async {
    await pantry.ensureLoaded();
    if (!mounted) return;
    final item = row.parsed.item;
    final choice = await showModalBottomSheet<_LinkChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      // Separate route: the model must be handed down explicitly, same as
      // the add-food sheet does.
      builder: (_) => ChangeNotifierProvider<PantryModel>.value(
        value: pantry,
        child: _LinkPickerSheet(
            item: item.isEmpty ? row.text.text : item, allowUnlink: true),
      ),
    );
    if (choice == null || !mounted) return; // dismissed — no change
    setState(() => row.productRef = choice.productId);
  }

  /// "+ Add from pantry": pick first, then the row arrives pre-linked with
  /// the product's name as its text — type the amount in front of it.
  Future<void> _addFromPantry(PantryModel pantry) async {
    await pantry.ensureLoaded();
    if (!mounted) return;
    final choice = await showModalBottomSheet<_LinkChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ChangeNotifierProvider<PantryModel>.value(
        value: pantry,
        child: const _LinkPickerSheet(item: null, allowUnlink: false),
      ),
    );
    final id = choice?.productId;
    if (id == null || !mounted) return;
    final product = pantry.byId(id);
    if (product == null) return;
    setState(() {
      // Reuse a trailing empty row instead of stranding it above the new one.
      final row = _ings.last.text.text.trim().isEmpty ? _ings.last : null;
      final target = row ?? _EntryRow();
      if (row == null) _ings.add(target);
      target.text.text = product.name;
      target.productRef = id;
      target.override = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final f = _ings.last.focus;
      f.requestFocus();
      // Caret at the front — the amount goes before the name.
      _ings.last.text.selection = const TextSelection.collapsed(offset: 0);
    });
  }

  /// Tap a parse chip: correct the three parts by hand. The raw line is
  /// untouched — the correction rides beside it, exactly like extraction
  /// parses ride beside raw in the file.
  Future<void> _correctParse(_EntryRow row) async {
    final parsed = row.parsed;
    final qty = TextEditingController(
        text: parsed.qty == null ? '' : _trimNum(parsed.qty!));
    final unit = TextEditingController(text: parsed.unit ?? '');
    final item = TextEditingController(text: parsed.item);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Fix the reading'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: qty,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: unit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            TextField(
              controller: item,
              decoration: const InputDecoration(labelText: 'Ingredient'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(() {
        row.override = ParsedQty(
          qty: num.tryParse(qty.text.trim().replaceAll(',', '.')),
          unit: unit.text.trim().isEmpty ? null : unit.text.trim().toLowerCase(),
          item: item.text.trim(),
        );
      });
    }
    qty.dispose();
    unit.dispose();
    item.dispose();
  }

  static String _trimNum(num v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  // --- save ---

  static List<_EntryRow> _filled(List<_EntryRow> rows) =>
      [for (final r in rows) if (r.text.text.trim().isNotEmpty) r];

  Ingredient _ingredientOf(_EntryRow row) {
    final parsed = row.parsed;
    return Ingredient(
      raw: row.text.text.trim(),
      qty: parsed.qty,
      unit: parsed.unit,
      item: parsed.item.isEmpty ? null : parsed.item,
      productRef: row.productRef,
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
      // Born parsed (Arnar, 2026-08-19): the parse — or the user's
      // correction of it — and the pantry link are stored on manual save
      // only; imported files stay untouched by this.
      ingredients: [for (final r in _filled(_ings)) _ingredientOf(r)],
      steps: [
        for (final r in _filled(_steps)) RecipeStep(raw: r.text.text.trim())
      ],
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

  // --- widgets ---

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

  /// A tiny muted parse chip — the structure the line was read as.
  Widget _parseChip(String label, VoidCallback onTap) {
    final scheme = context.scheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: scheme.onSurfaceVariant)),
      ),
    );
  }

  /// MetaChip's label has no ellipsis of its own; a long product name would
  /// overflow the row, so trim it here.
  static String _chipLabel(String name) =>
      name.length <= 20 ? name : '${name.substring(0, 19).trimRight()}…';

  Widget _ingredientRow(int i, PantryModel? pantry) {
    final row = _ings[i];
    final hasText = row.text.text.trim().isNotEmpty;
    final parsed = row.parsed;
    // A product deleted mid-session resolves to null → the chip honestly
    // falls back to 'Link' (dangling refs are display noise, never errors).
    final linked =
        row.productRef == null ? null : pantry?.byId(row.productRef!);
    final onlyEmptyRow = _ings.length == 1 && !hasText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TokenCard(
        padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: TextField(
                  key: Key('manual-ing-$i'),
                  controller: row.text,
                  focusNode: row.focus,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _submitRow(_ings, i),
                  onChanged: (_) => setState(() => row.override = null),
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'e.g. 2 dl melk'),
                ),
              ),
              if (!onlyEmptyRow)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded,
                      size: 17, color: context.scheme.onSurfaceVariant),
                  onPressed: () => _removeRow(_ings, i),
                  tooltip: 'Remove',
                ),
            ]),
            if (hasText) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _parseChip(
                      parsed.qty == null ? '?' : _trimNum(parsed.qty!),
                      () => _correctParse(row)),
                  if (parsed.unit != null)
                    _parseChip(parsed.unit!, () => _correctParse(row)),
                  if (parsed.item.isNotEmpty)
                    _parseChip(parsed.item, () => _correctParse(row)),
                  if (pantry != null)
                    MetaChip(
                      icon: linked == null ? Icons.link_rounded : null,
                      label:
                          linked == null ? 'Link' : _chipLabel(linked.name),
                      onTap: () => _pickLink(row, pantry),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stepRow(int i) {
    final row = _steps[i];
    final onlyEmptyRow = _steps.length == 1 && row.text.text.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TokenCard(
        padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text('${i + 1}.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: context.scheme.primary)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                key: Key('manual-step-$i'),
                controller: row.text,
                focusNode: row.focus,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _submitRow(_steps, i),
                onChanged: (_) => setState(() {}),
                maxLines: null,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.4),
                decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'What happens next?'),
              ),
            ),
            if (!onlyEmptyRow)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close_rounded,
                    size: 17, color: context.scheme.onSurfaceVariant),
                onPressed: () => _removeRow(_steps, i),
                tooltip: 'Remove',
              ),
          ],
        ),
      ),
    );
  }

  Widget _addButton(String label, VoidCallback onTap) {
    final scheme = context.scheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Icon(Icons.add_rounded, size: 18, color: scheme.primary),
          const SizedBox(width: 6),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: scheme.primary)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final pantry = _pantry();
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
                  const SizedBox(height: 4),
                  Text(
                    'Type a line like "2 dl melk" — it reads itself. Link a '
                    'line to your pantry and the recipe can count calories.',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _ings.length; i++)
                    _ingredientRow(i, pantry),
                  _addButton('Add ingredient', () => _addRow(_ings)),
                  if (pantry != null)
                    _addButton(
                        'Add from pantry', () => _addFromPantry(pantry)),
                  const SizedBox(height: 14),
                  const SectionLabel('Steps'),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _steps.length; i++) _stepRow(i),
                  _addButton('Add step', () => _addRow(_steps)),
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
  const _LinkPickerSheet({required this.item, required this.allowUnlink});

  /// The parsed item of the line being linked — names the question. Null
  /// for "Add from pantry", where there is no line yet.
  final String? item;

  /// The 'No product' row only makes sense when a link can be removed.
  final bool allowUnlink;

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
            SectionLabel(
                item == null ? 'Add which product?' : 'Which product is "$item"?'),
            const SizedBox(height: 8),
            if (allowUnlink) ...[
              // Plain unlink row on top — always available, so a wrong link
              // is one tap from gone.
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
            ],
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
