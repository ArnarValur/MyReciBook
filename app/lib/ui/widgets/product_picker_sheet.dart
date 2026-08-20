// THE product picker — one sheet for every "which product?" moment: linking
// an ingredient line (recipe detail, recipe editor) and any future chooser.
// One implementation so search, synonyms, category chips and the product
// card behave identically everywhere (Arnar, 2026-08-20: stop building
// near-identical drawers). Add-food keeps its own richer sheet (Recent,
// recipes, Quick add) but shares CategoryChipRow and ProductRow with this.

import 'package:flutter/material.dart';

import '../../domain/product.dart';
import '../../domain/product_categories.dart';
import '../pantry/pantry_model.dart';
import '../theme.dart';
import 'category_chips.dart';
import 'product_row.dart';
import 'skin.dart';

/// What the picker returned. [product] null means "No product" — the
/// deliberate unlink, distinct from dismissing the sheet (null result).
class ProductPick {
  const ProductPick(this.product);

  final Product? product;
}

Future<ProductPick?> showProductPickerSheet(
  BuildContext context, {
  required PantryModel pantry,
  required String title,
  bool allowUnlink = false,
}) =>
    showModalBottomSheet<ProductPick>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ProductPickerSheet(
          pantry: pantry, title: title, allowUnlink: allowUnlink),
    );

class _ProductPickerSheet extends StatefulWidget {
  const _ProductPickerSheet(
      {required this.pantry, required this.title, required this.allowUnlink});

  final PantryModel pantry;
  final String title;
  final bool allowUnlink;

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  String _query = '';
  String? _category;

  /// Add-food's matching rule, verbatim: name, brand or synonym substring —
  /// "Paprika" finds Bell Pepper here too.
  List<Product> _matches(List<Product> products) {
    final q = _query.trim().toLowerCase();
    return [
      for (final p in products)
        if (q.isEmpty ||
            p.name.toLowerCase().contains(q) ||
            (p.brand ?? '').toLowerCase().contains(q) ||
            p.synonyms.any((s) => s.toLowerCase().contains(q)))
          if (_category == null ||
              (_category == otherCategory
                  ? p.tags.isEmpty
                  : p.tags.contains(_category)))
            p
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final products = widget.pantry.products;
    final counts = categoryCounts(products);
    final showChips =
        counts.keys.any((c) => c != otherCategory) && products.isNotEmpty;
    final active = counts.containsKey(_category) ? _category : null;
    final matches = _matches(products);
    final media = MediaQuery.of(context);
    final insets = media.viewInsets.bottom;
    // The gesture-bar rule shared by every sheet: the last row clears it.
    final systemBar = insets > 0 ? 0.0 : media.viewPadding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + systemBar),
          children: [
            SectionLabel(widget.title),
            const SizedBox(height: 8),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search your pantry',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: scheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
              ),
            ),
            if (showChips) ...[
              const SizedBox(height: 12),
              CategoryChipRow(
                counts: counts,
                active: active,
                onSelect: (c) => setState(() => _category = c),
              ),
            ],
            const SizedBox(height: 12),
            if (widget.allowUnlink) ...[
              InkWell(
                key: const Key('link-no-product'),
                onTap: () =>
                    Navigator.of(context).pop(const ProductPick(null)),
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
            if (products.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'Your pantry is empty. Scan a barcode or create a food on '
                  'the Pantry tab first, then link it here.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
                ),
              )
            else if (matches.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'Nothing on the shelf matches that.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              )
            else
              for (final product in matches)
                ProductRow(
                  product: product,
                  imageFile: widget.pantry.imageFileOf(product),
                  onTap: () =>
                      Navigator.of(context).pop(ProductPick(product)),
                ),
          ],
        ),
      ),
    );
  }
}
