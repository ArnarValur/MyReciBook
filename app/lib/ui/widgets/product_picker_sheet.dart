// THE product picker — one sheet for every "which product?" moment: linking
// an ingredient line (recipe detail, recipe editor, the diary's link sheet)
// and any future chooser. One implementation so search and the product card
// behave identically everywhere (Arnar, 2026-08-20: stop building
// near-identical drawers).
//
// It browses on the shared CollapsibleShelf now (Arnar, 2026-08-30: this was
// the last surface still drawing the old horizontal chip row — two ways to
// browse the same pantry). Same shelf as the Pantry tab and the Add-food
// sheet, same ProductRow behind the headers, and a folded section's rows are
// never built (the shelf's contract — three starter packs are ~60 rows each).

import 'package:flutter/material.dart';

import '../../domain/product.dart';
import '../../domain/product_categories.dart';
import '../pantry/pantry_model.dart';
import '../theme.dart';
import 'collapsible_shelf.dart';
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

  /// Sections the user has unfolded. Plain screen state, never persisted —
  /// the Add-food sheet's rule, for its reason: a modal that reopens
  /// half-unfolded is a modal that got slow to open again, and the shelf one
  /// ingredient sits on says nothing about where the next one lives. The
  /// Pantry tab persists its fold because that screen IS the shelf; this is a
  /// chooser you close.
  final Set<String> _open = {};

  bool get _searching => _query.trim().isNotEmpty;

  /// Add-food's matching rule, verbatim: name, brand or synonym substring —
  /// "Paprika" finds Bell Pepper here too.
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

  /// The shelf: product_categories' own grouping and order, so this sheet and
  /// the Pantry tab file the same food under the same heading.
  List<ShelfSection> _sections(List<Product> products) => [
        for (final (name, items) in groupByCategory(products))
          ShelfSection(
            id: name,
            label: categoryLabel(name),
            count: items.length,
            // A bundled pack, not the user's own scans — the leaf says why a
            // 60-item section is worth leaving folded.
            starterPack: items.every((p) => p.source == 'starter'),
            builder: (_) =>
                Column(children: [for (final p in items) _row(p)]),
          ),
      ];

  Widget _row(Product product) => ProductRow(
        product: product,
        imageFile: widget.pantry.imageFileOf(product),
        onTap: () => Navigator.of(context).pop(ProductPick(product)),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final products = widget.pantry.products;
    // Typing flattens the shelf into plain rows (the Pantry tab's rule):
    // categories are a way of browsing, and once you know the name you want
    // they are in the way — a hit must never hide behind a folded header.
    final matches = _searching ? _matches(products) : const <Product>[];
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
            else if (_searching) ...[
              if (matches.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    'Nothing on the shelf matches that.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                )
              else
                for (final product in matches) _row(product),
            ] else
              CollapsibleShelf(
                sections: _sections(products),
                expanded: _open,
                onToggle: (id) => setState(() =>
                    _open.contains(id) ? _open.remove(id) : _open.add(id)),
              ),
          ],
        ),
      ),
    );
  }
}
