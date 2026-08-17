// Pantry tab — the POC surface for the food base (Arnar's slot-2 test call,
// 2026-08-17): scan a barcode off the shelf, OFF fills in the product, one
// JSON lands in the user's pantry folder. Everything downstream (ingredient
// linking, nutrition badges, diary totals) builds on this screen existing.
//
// Undesigned — built minimal in the app's idiom, copy flagged for a design
// turn: the row look, the add-confirm moment (auto-save today), and the
// empty state. Long-press a row removes it (grocery's destructive-confirm
// shape); a not-on-OFF scan states the label-photo fallback honestly.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/product.dart';
import '../theme.dart';
import '../widgets/skin.dart';
import 'barcode_scan_screen.dart';
import 'pantry_model.dart';

class PantryTab extends StatefulWidget {
  const PantryTab({super.key});

  @override
  State<PantryTab> createState() => _PantryTabState();
}

class _PantryTabState extends State<PantryTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PantryModel>().ensureLoaded();
    });
  }

  /// The shelf-sweep session: the scan screen stays open, saving product
  /// after product through [_collect]; Back lands here with the list already
  /// current (the model notified on every add).
  Future<void> _scan() =>
      Navigator.of(context).push<void>(MaterialPageRoute<void>(
          builder: (_) => BarcodeScanScreen(collect: _collect)));

  /// One detection → one honest flash line. The three-way outcome keeps
  /// "OFF didn't answer" visibly different from "not in the database".
  Future<ScanFeedback> _collect(String digits) async {
    final outcome = await context.read<PantryModel>().addByBarcode(digits);
    switch (outcome) {
      case PantryAdded(:final product, :final wasKnown):
        return ScanFeedback(wasKnown
            ? '${product.name} — refreshed'
            : '${product.name} — added');
      case PantryNotFound():
        return const ScanFeedback('Not on Open Food Facts — nothing saved',
            ok: false);
      case PantryUnavailable():
        return const ScanFeedback(
            'Open Food Facts didn\'t answer — scan it again',
            ok: false);
    }
  }

  /// Tap a row → pushed detail page (the recipe-detail gesture; a bottom
  /// sheet fought the device's own nav bar — Arnar's S21 pass, 2026-08-17).
  Future<void> _openDetail(Product p) =>
      Navigator.of(context).push<void>(MaterialPageRoute<void>(
          builder: (_) => _ProductDetailScreen(product: p)));

  Future<void> _removeSheet(PantryModel model, String id, String name) async {
    final ok = await showDestructiveConfirm(
      context,
      title: 'Remove $name?',
      body: 'Its file leaves your pantry folder. Scanning the barcode '
          'again brings it back with fresh data.',
      verb: 'Remove',
    );
    if (ok) await model.remove(id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final model = context.watch<PantryModel>();

    return Scaffold(
      body: SafeArea(
        bottom: false, // content scrolls under the shell's glass bar
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
          children: [
            Text('Pantry',
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontSize: 26, letterSpacing: -0.4)),
            const SizedBox(height: 2),
            Text(model.caption,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: model.busy ? null : _scan,
              icon: const Icon(Icons.barcode_reader),
              label: Text(model.busy ? 'Looking it up…' : 'Scan a product'),
            ),
            if (model.busy) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 20),
            if (model.loaded && model.products.isEmpty) ...[
              // The shell's honest zero-state look (grocery's empty shape).
              const SizedBox(height: 48),
              Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(Icons.kitchen_rounded, size: 32, color: scheme.primary),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Scan the barcode on anything from your shelf — '
                'MyReciBook looks it up and keeps it as a file you own, '
                'right beside your recipes.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
              ),
            ] else
              for (final p in model.products)
                _ProductRow(
                  product: p,
                  onTap: () => _openDetail(p),
                  onLongPress: () => _removeSheet(model, p.id, p.name),
                ),
            if (model.skipped > 0) ...[
              const SizedBox(height: 12),
              Text(
                '${model.skipped} file${model.skipped == 1 ? '' : 's'} in the '
                'pantry folder skipped (not product files).',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow(
      {required this.product, required this.onTap, required this.onLongPress});

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final kcal = product.nutriments?.kcal;
    final meta = [
      if ((product.brand ?? '').isNotEmpty) product.brand!,
      if ((product.quantity ?? '').isNotEmpty) product.quantity!,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TokenCard(
        radius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.kitchen_rounded,
                  size: 20, color: scheme.onSecondaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  if (meta.isNotEmpty)
                    Text(meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (kcal != null) ...[
              const SizedBox(width: 8),
              MetaChip(label: '${kcal.round()} kcal'),
            ],
          ]),
        ),
      ),
    );
  }
}

/// Product detail — everything the file carries, per 100 g, on a pushed
/// route (covers the glass bar like every detail screen). Read-only and
/// deliberately cover-less; the design turn decides the real look. Null
/// macros just don't print — OFF is crowdsourced and sparse files are normal.
class _ProductDetailScreen extends StatelessWidget {
  const _ProductDetailScreen({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final n = product.nutriments;
    final rows = <(String, double?, String)>[
      ('Energy', n?.kcal, 'kcal'),
      ('Fat', n?.fat, 'g'),
      ('— of which saturated', n?.saturatedFat, 'g'),
      ('Carbohydrates', n?.carbs, 'g'),
      ('— of which sugars', n?.sugars, 'g'),
      ('Protein', n?.protein, 'g'),
      ('Salt', n?.salt, 'g'),
    ];
    final meta = [
      if ((product.brand ?? '').isNotEmpty) product.brand!,
      if ((product.quantity ?? '').isNotEmpty) product.quantity!,
    ].join(' · ');

    return Scaffold(
      appBar: AppBar(leading: const AppBackButton()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(product.name,
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontSize: 24, letterSpacing: -0.3)),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(meta,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ],
          const SizedBox(height: 20),
          if (rows.every((r) => r.$2 == null))
            Text(
              'No nutrition data on Open Food Facts for this one — the '
              'label-photo rescue will fill it in later.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            )
          else
            TokenCard(
              radius: 16,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Per 100 g'),
                  const SizedBox(height: 6),
                  for (final (label, value, unit) in rows)
                    if (value != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          Expanded(
                              child: Text(label,
                                  style: theme.textTheme.bodyMedium)),
                          Text(
                              '${value == value.roundToDouble() ? value.round() : value} $unit',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ]),
                      ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Text(
            'From Open Food Facts · barcode ${product.barcode}\n'
            'Saved as its own file in your pantry folder.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
          ),
        ],
      ),
    );
  }
}
