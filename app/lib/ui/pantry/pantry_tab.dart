// Pantry tab — the POC surface for the food base (Arnar's slot-2 test call,
// 2026-08-17): scan a barcode off the shelf, OFF fills in the product, one
// JSON lands in the user's pantry folder. Everything downstream (ingredient
// linking, nutrition badges, diary totals) builds on this screen existing.
//
// Undesigned — built minimal in the app's idiom, copy flagged for a design
// turn: the row look, the add-confirm moment (auto-save today), and the
// empty state. Long-press a row removes it (grocery's destructive-confirm
// shape); a not-on-OFF scan states the label-photo fallback honestly.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/nutrient_display.dart';
import '../../domain/product.dart';
import '../photo_sources.dart';
import '../theme.dart';
import '../widgets/skin.dart';
import 'barcode_scan_screen.dart';
import 'pantry_model.dart';

class PantryTab extends StatefulWidget {
  const PantryTab({super.key, this.header});

  /// Drawn above the title — the Diary/Pantry segmented control when the tab
  /// is hosted in slot 3. Null on a standalone route.
  final Widget? header;

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
  /// By id, not value: photo edits on the pushed route re-render live.
  Future<void> _openDetail(Product p) =>
      Navigator.of(context).push<void>(MaterialPageRoute<void>(
          builder: (_) => _ProductDetailScreen(productId: p.id)));

  /// Ask Open Food Facts about everything on the shelf again. Products saved
  /// before the app kept vitamins and minerals hold only the seven macros,
  /// and the alternative is re-scanning every pack by hand.
  Future<void> _refreshAll(PantryModel model) async {
    final report = await model.refreshAll();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(_refreshLine(report))));
  }

  /// One line, counted honestly — a sweep that hit the network floor says so
  /// instead of claiming everything updated.
  static String _refreshLine(PantryRefreshReport r) {
    if (r.total == 0) return 'Nothing with a barcode to update.';
    final parts = [
      if (r.updated > 0) '${r.updated} updated',
      if (r.unchanged > 0) '${r.unchanged} already current',
      if (r.missing > 0) '${r.missing} no longer on Open Food Facts',
      if (r.failed > 0) '${r.failed} couldn\'t be reached — try again',
    ];
    if (parts.isEmpty) return 'Nothing changed.';
    return parts.join(' · ');
  }

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
            if (widget.header != null) ...[
              widget.header!,
              const SizedBox(height: 16),
            ],
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
            // Products saved by an older build hold only the seven label
            // macros; this is the route to their vitamins and minerals
            // without re-scanning every pack by hand.
            if (model.refreshableCount > 0) ...[
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed:
                    model.busy || model.refreshing ? null : () => _refreshAll(model),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(model.refreshing
                    ? 'Updating ${model.refreshDone} of ${model.refreshTotal}…'
                    : 'Update nutrition data (${model.refreshableCount})'),
              ),
              if (model.refreshing) ...[
                const SizedBox(height: 6),
                LinearProgressIndicator(
                    value: model.refreshTotal == 0
                        ? null
                        : model.refreshDone / model.refreshTotal),
              ],
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
                  imageFile: model.imageFileOf(p),
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
      {required this.product,
      this.imageFile,
      required this.onTap,
      required this.onLongPress});

  final Product product;
  final File? imageFile;
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
            if (imageFile != null && imageFile!.existsSync())
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(imageFile!,
                    width: 38, height: 38, fit: BoxFit.cover, cacheWidth: 114),
              )
            else
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
/// route (covers the glass bar like every detail screen). The user's own
/// photo enriches it (their ask, 2026-08-17) — recipe-cover mechanics: copy
/// into pantry/images, replace cleans up, delete takes it. Null macros just
/// don't print — OFF is crowdsourced and sparse files are normal.
class _ProductDetailScreen extends StatelessWidget {
  const _ProductDetailScreen({required this.productId});

  final String productId;

  Future<void> _pick(BuildContext context, Product product,
      Future<List<File>> Function() source) async {
    final model = context.read<PantryModel>();
    final photo = await context.read<PhotoSources>().pickOne(source);
    if (photo == null) return;
    final old = model.imageFileOf(product);
    await model.attachImage(product, photo);
    // Same path, new bytes: evict or the cache shows the old photo.
    if (old != null) await FileImage(old).evict();
    final fresh = model.byId(productId);
    final file = fresh == null ? null : model.imageFileOf(fresh);
    if (file != null) await FileImage(file).evict();
  }

  Future<void> _photoSheet(BuildContext context, Product product) async {
    final photos = context.read<PhotoSources>();
    final model = context.read<PantryModel>();
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (photos.camera != null)
            ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(ctx, 'camera')),
          ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('From gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery')),
          if (product.image != null)
            ListTile(
                leading: Icon(Icons.delete_outline_rounded,
                    color: ctx.scheme.error),
                title: const Text('Remove photo'),
                onTap: () => Navigator.pop(ctx, 'remove')),
        ]),
      ),
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case 'camera':
        await _pick(context, product, photos.camera!);
      case 'gallery':
        await _pick(context, product, photos.gallery);
      case 'remove':
        await model.removeImage(product);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final model = context.watch<PantryModel>();
    final found = model.byId(productId);
    if (found == null) {
      // Removed while this route was open — honest empty, not a crash.
      return Scaffold(
          appBar: AppBar(leading: const AppBackButton()),
          body: const Center(child: Text('This product was removed.')));
    }
    final product = found;
    final imageFile = model.imageFileOf(product);
    final hasImage = imageFile != null && imageFile.existsSync();
    final n = product.nutriments;
    // The label macros in the order a pack prints them, then everything else
    // Open Food Facts sent — vitamins, minerals, whatever it has.
    // Zeros are hidden. Open Food Facts stores "nobody measured this" as a
    // literal 0, so printing them fills the card with rows that say nothing.
    final macroRows = [
      if (n != null)
        for (final key in Nutriments.macroKeys)
          if (n[key] != null && n[key] != 0) (key, n[key]!),
    ];
    final extraRows = [
      if (n != null)
        for (final key in n.extraKeys)
          if (n[key] != 0) (key, n[key]!),
    ];
    final hasAnything = macroRows.isNotEmpty || extraRows.isNotEmpty;
    final meta = [
      if ((product.brand ?? '').isNotEmpty) product.brand!,
      if ((product.quantity ?? '').isNotEmpty) product.quantity!,
    ].join(' · ');

    return Scaffold(
      appBar: AppBar(leading: const AppBackButton()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // The user's own photo of the product; tap to add/replace/remove.
          if (hasImage)
            GestureDetector(
              onTap: () => _photoSheet(context, product),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(imageFile,
                    height: 180, fit: BoxFit.cover, cacheWidth: 1080),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: () => _photoSheet(context, product),
              icon: const Icon(Icons.add_a_photo_rounded, size: 18),
              label: const Text('Add your photo'),
            ),
          const SizedBox(height: 16),
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
          if (!hasAnything)
            Text(
              'No nutrition data on Open Food Facts for this one — the '
              'label-photo rescue will fill it in later.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            )
          else ...[
            if (macroRows.isNotEmpty)
              TokenCard(
                radius: 16,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('Per 100 g'),
                    const SizedBox(height: 6),
                    for (final (key, value) in macroRows)
                      _NutrientRow(nutrientKey: key, value: value),
                  ],
                ),
              ),
            if (extraRows.isNotEmpty) ...[
              const SizedBox(height: 12),
              TokenCard(
                radius: 16,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('Vitamins and minerals'),
                    const SizedBox(height: 6),
                    for (final (key, value) in extraRows)
                      _NutrientRow(nutrientKey: key, value: value),
                  ],
                ),
              ),
            ],
          ],
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

/// One nutrient line: name on the left, value and unit on the right. Grams
/// step down to mg/µg so trace amounts stay readable (see nutrient_display).
class _NutrientRow extends StatelessWidget {
  const _NutrientRow({required this.nutrientKey, required this.value});

  final String nutrientKey;
  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (shown, unit) = formatNutrient(nutrientKey, value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(
            child: Text(nutrientLabel(nutrientKey),
                style: theme.textTheme.bodyMedium)),
        Text('$shown $unit',
            style:
                theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
