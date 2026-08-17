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

  Future<void> _scan() async {
    final model = context.read<PantryModel>();
    if (model.busy) return;
    final digits = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const BarcodeScanScreen()),
    );
    if (digits == null || !mounted) return;
    final outcome = await model.addByBarcode(digits);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context)..removeCurrentSnackBar();
    switch (outcome) {
      case PantryAdded(:final product, :final wasKnown):
        messenger.showSnackBar(SnackBar(
            content: Text(wasKnown
                ? '${product.name} refreshed — already on your shelf'
                : '${product.name} added to your pantry')));
      case PantryNotFound():
        messenger.showSnackBar(const SnackBar(
            content: Text('Not on Open Food Facts yet — the label-photo '
                'rescue lands later. Nothing saved.')));
      case PantryUnavailable():
        messenger.showSnackBar(SnackBar(
          content: const Text('Open Food Facts didn\'t answer — nothing '
              'saved. Worth one more try.'),
          action: SnackBarAction(label: 'Retry', onPressed: _retry(digits)),
        ));
    }
  }

  VoidCallback _retry(String digits) => () async {
        final model = context.read<PantryModel>();
        final outcome = await model.addByBarcode(digits);
        if (!mounted || outcome is! PantryAdded) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${outcome.product.name} added to your pantry')));
      };

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
  const _ProductRow({required this.product, required this.onLongPress});

  final Product product;
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
