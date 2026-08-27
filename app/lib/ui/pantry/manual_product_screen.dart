// Create a food by hand — the no-barcode door. Apples, a bag of carrots, the
// bread from the bakery down the road, anything Open Food Facts never heard
// of. It saves a normal product file to the pantry, so a hand-typed food is
// indistinguishable from a scanned one everywhere downstream.
//
// Numbers are entered per 100 g because that is what a label prints and what
// the product file stores; a portion (label + grams) is optional and is what
// the diary preselects.
//
// The tag cloud ([ProductTagCloud]) lives here but is not this screen's: the
// product page opens the same one as a sheet, so the two doors onto a
// product's tags cannot drift into two vocabularies.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/product.dart';
import '../../domain/product_categories.dart';
import '../theme.dart';
import '../widgets/skin.dart';
import 'pantry_model.dart';

class ManualProductScreen extends StatefulWidget {
  const ManualProductScreen({super.key, this.initial});

  /// Editing an existing product instead of creating one. The barcode and the
  /// file it lives in are kept — this is an edit, not a second file.
  final Product? initial;

  @override
  State<ManualProductScreen> createState() => _ManualProductScreenState();
}

class _ManualProductScreenState extends State<ManualProductScreen> {
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _portionLabel = TextEditingController();
  final _portionGrams = TextEditingController();
  final _fields = <String, TextEditingController>{
    for (final key in _entered) key: TextEditingController(),
  };

  /// What a nutrition label actually prints, in label order. Deliberately
  /// short: a hand-typed food should take under a minute, and the open
  /// nutriment map still accepts anything a scan adds later.
  static const _entered = [
    'kcal',
    'fat',
    'saturated_fat',
    'carbs',
    'sugars',
    'protein',
    'salt',
  ];

  static const _labels = {
    'kcal': 'Calories (kcal)',
    'fat': 'Fat (g)',
    'saturated_fat': 'of which saturated (g)',
    'carbs': 'Carbohydrates (g)',
    'sugars': 'of which sugars (g)',
    'protein': 'Protein (g)',
    'salt': 'Salt (g)',
  };

  bool _saving = false;

  /// Selected tags, in the order they were picked. A list, not a set: the
  /// order a person chose is the order the shelf should show.
  final _tags = <String>[];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial == null) return;
    _tags.addAll(initial.tags);
    _name.text = initial.name;
    _brand.text = initial.brand ?? '';
    if (initial.servings.isNotEmpty) {
      _portionLabel.text = initial.servings.first.label;
      _portionGrams.text = _trim(initial.servings.first.grams);
    }
    final values = initial.nutriments?.values ?? const <String, double>{};
    for (final key in _entered) {
      final v = values[key];
      if (v != null) _fields[key]!.text = _trim(v);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _portionLabel.dispose();
    _portionGrams.dispose();
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  static double? _parse(String raw) {
    final cleaned = raw.trim().replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  void _toggleTag(String tag) {
    setState(() {
      if (!_tags.remove(tag)) _tags.add(tag);
    });
  }

  Future<void> _addOwnTag() async {
    final tag = await askForOwnTag(context);
    if (tag == null) return;
    setState(() {
      if (!_tags.contains(tag)) _tags.add(tag);
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);

    // Only what was actually typed. A blank field is "not measured", never a
    // zero — the pantry's own rule, and the reason a diary total can say
    // "from 3 of 5 items" honestly later.
    final values = <String, double>{};
    for (final key in _entered) {
      final v = _parse(_fields[key]!.text);
      if (v != null) values[key] = v;
    }

    // Any nutriments a scan already stored that this form never shows —
    // vitamins, minerals — survive the edit untouched.
    final existing = widget.initial?.nutriments?.values;
    if (existing != null) {
      for (final e in existing.entries) {
        if (!_entered.contains(e.key)) values[e.key] = e.value;
      }
    }

    final grams = _parse(_portionGrams.text);
    final portionLabel = _portionLabel.text.trim();
    final servings = <Serving>[
      if (grams != null && grams > 0)
        Serving(
            label: portionLabel.isEmpty ? '1 portion' : portionLabel,
            grams: grams),
    ];

    final initial = widget.initial;
    final product = initial == null
        ? Product(
            schemaVersion: Product.currentSchemaVersion,
            barcode: '',
            name: name,
            brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
            source: 'manual',
            addedAt: DateTime.now().toUtc().toIso8601String(),
            nutriments: Nutriments.fromMap(values),
            servings: servings,
            defaultServing: servings.isEmpty ? null : 0,
            tags: List.of(_tags),
          )
        : initial.copyWith(
            name: name,
            brand: _brand.text.trim(),
            nutriments: Nutriments.fromMap(values),
            servings: servings,
            defaultServing: servings.isEmpty ? null : 0,
            tags: List.of(_tags),
          );

    final saved = await context.read<PantryModel>().upsert(product);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final editing = widget.initial != null;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(editing ? 'Edit food' : 'Create a food'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              editing
                  ? 'Open Food Facts is crowdsourced and sometimes wrong. What '
                      'you type here wins, and stays yours.'
                  : 'For everything without a barcode — fruit, veg, the loaf '
                      'from the bakery. It becomes a normal file in your '
                      'pantry, exactly like a scanned one.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _name,
              autofocus: !editing,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                  labelText: 'Name', hintText: 'Apple, medium'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _brand,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  labelText: 'Brand or shop (optional)'),
            ),
            const SizedBox(height: 24),

            const SectionLabel('A portion'),
            const SizedBox(height: 6),
            Text(
              'What one of these weighs, so the diary can offer it. Skip it '
              'and everything logs per 100 g.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _portionLabel,
                  decoration: const InputDecoration(
                      labelText: 'Called', hintText: '1 medium'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _portionGrams,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Weighs', suffixText: 'g'),
                ),
              ),
            ]),
            const SizedBox(height: 24),

            const SectionLabel('Tags'),
            const SizedBox(height: 6),
            Text(
              'Group your shelf — dairy, wine, whatever fits.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 10),
            ProductTagCloud(
              selected: _tags,
              onToggle: _toggleTag,
              onAddOwn: _addOwnTag,
            ),
            const SizedBox(height: 24),

            const SectionLabel('Per 100 g'),
            const SizedBox(height: 6),
            Text(
              'Straight off the label. Leave anything you do not know blank — '
              'blank means "not measured", not zero.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 12),
            for (final key in _entered) ...[
              TextField(
                controller: _fields[key],
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: _labels[key]),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed:
                  _saving || _name.text.trim().isEmpty ? null : _save,
              icon: const Icon(Icons.check_rounded),
              label: Text(editing ? 'Save changes' : 'Save to pantry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Every tag on offer: the canonical shelf categories (the SAME list the
/// chips and auto-tagging use — one source, never a parallel copy), then
/// anything already selected that isn't among them — a product's old custom
/// tags, or one just typed — appended sorted for a stable home. Last comes
/// the door to invent another.
///
/// Shared by the create screen (inline) and the product page (as a sheet).
class ProductTagCloud extends StatelessWidget {
  const ProductTagCloud({
    super.key,
    required this.selected,
    required this.onToggle,
    required this.onAddOwn,
  });

  final List<String> selected;
  final void Function(String tag) onToggle;
  final VoidCallback onAddOwn;

  @override
  Widget build(BuildContext context) {
    final extras = selected.where((t) => !productCategories.contains(t)).toList()
      ..sort();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tag in [...productCategories, ...extras])
          _TagPill(
            label: categoryLabel(tag),
            selected: selected.contains(tag),
            onTap: () => onToggle(tag),
          ),
        ActionChip(
          avatar: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add your own'),
          onPressed: onAddOwn,
        ),
      ],
    );
  }
}

/// "Wine", "spices" — a tag nobody's taxonomy had. Returns the trimmed name,
/// or null when the user backed out or typed nothing.
Future<String?> askForOwnTag(BuildContext context) async {
  final controller = TextEditingController();
  final raw = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Add a tag'),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Wine, spices…'),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const Text('Add'),
        ),
      ],
    ),
  );
  controller.dispose();
  final tag = raw?.trim() ?? '';
  return tag.isEmpty ? null : tag;
}

/// A selectable pill — same look as the log sheet's serving picker, copied
/// locally rather than shared across features while there are only two.
class _TagPill extends StatelessWidget {
  const _TagPill(
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
