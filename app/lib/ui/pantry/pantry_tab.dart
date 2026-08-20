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
import '../../domain/product_categories.dart';
import '../photo_sources.dart';
import '../theme.dart';
import '../widgets/category_chips.dart';
import '../widgets/product_row.dart';
import '../widgets/skin.dart';
import 'barcode_scan_screen.dart';
import 'manual_product_screen.dart';
import 'pantry_model.dart';
import 'starter_foods_screen.dart';

class PantryTab extends StatefulWidget {
  const PantryTab({super.key, this.header});

  /// Drawn above the title — the Diary/Pantry segmented control when the tab
  /// is hosted in slot 3. Null on a standalone route.
  final Widget? header;

  @override
  State<PantryTab> createState() => _PantryTabState();
}

class _PantryTabState extends State<PantryTab> {
  /// The one tag the list is narrowed to; null shows everything. Plain
  /// screen state — a filter is a way of looking, not data worth persisting.
  String? _tagFilter;

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
  /// and the alternative is re-scanning every pack by hand. Confirmed first
  /// (Arnar, 2026-08-19): a bulk overwrite from a crowdsourced database
  /// shouldn't fire off one tap, and hand-edited products sit it out.
  Future<void> _refreshAll(PantryModel model) async {
    final n = model.refreshableCount;
    final edited = model.editedCount;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Update from Open Food Facts?'),
        content: Text(
          '$n product${n == 1 ? '' : 's'} will be refreshed with whatever '
          'Open Food Facts has now.'
          '${edited > 0 ? ' $edited you have edited by hand will be left alone.' : ''}',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dctx, true),
              child: const Text('Update')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
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

    // Category chips with counts, recomputed each build so they appear and
    // vanish with the products; a filter whose category was edited away
    // silently falls back to All instead of stranding an empty list.
    // "Other" is render-only — untagged files stay untagged on disk.
    final counts = categoryCounts(model.products);
    final activeTag = counts.containsKey(_tagFilter) ? _tagFilter : null;
    final visible = switch (activeTag) {
      null => model.products,
      otherCategory => [
          for (final p in model.products)
            if (p.tags.isEmpty) p
        ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
      final tag => [
          for (final p in model.products)
            if (p.tags.contains(tag)) p
        ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
    };
    // The chips only earn their row once something is actually categorised —
    // a shelf that is 100% "Other" gets no filter UI to click into nothing.
    final showChips =
        counts.keys.any((c) => c != otherCategory) && model.products.isNotEmpty;

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
            // Title row — the bulk refresh lives up here compressed
            // (Arnar, 2026-08-20): an icon and the count, not a banner.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text('Pantry',
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontSize: 26, letterSpacing: -0.4)),
                ),
                if (model.refreshableCount > 0)
                  TextButton.icon(
                    onPressed: model.busy || model.refreshing
                        ? null
                        : () => _refreshAll(model),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(model.refreshing
                        ? '${model.refreshDone}/${model.refreshTotal}'
                        : '${model.refreshableCount}'),
                  ),
              ],
            ),
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
            const SizedBox(height: 6),
            // The un-barcoded door: fresh produce and spices come built in
            // (starter_foods.dart) — nothing edible needs a barcode.
            TextButton.icon(
              onPressed: () =>
                  Navigator.of(context).push<void>(MaterialPageRoute<void>(
                      builder: (_) => const StarterFoodsScreen())),
              icon: const Icon(Icons.eco_rounded, size: 18),
              label: const Text('Add starter foods — veggies, fruit, spices'),
            ),
            if (model.busy) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(),
            ],
            if (model.refreshing) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                  value: model.refreshTotal == 0
                      ? null
                      : model.refreshDone / model.refreshTotal),
            ],
            // Category chips — only once something is categorised (dead-end
            // rule: an all-"Other" shelf gets no filter UI).
            if (showChips) ...[
              const SizedBox(height: 14),
              CategoryChipRow(
                counts: counts,
                active: activeTag,
                onSelect: (c) => setState(() => _tagFilter = c),
              ),
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
            ] else if (activeTag == null && showChips)
              // The grouped shelf: category sections, alphabetical inside —
              // never the scan sequence. Headers only when there IS more
              // than one way to shelve things (showChips).
              for (final (category, members) in groupByCategory(model.products)) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 6),
                  child: Text(
                    '${categoryLabel(category)} · ${members.length}',
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 0.3),
                  ),
                ),
                for (final p in members)
                  ProductRow(
                    product: p,
                    imageFile: model.imageFileOf(p),
                    onTap: () => _openDetail(p),
                    onLongPress: () => _removeSheet(model, p.id, p.name),
                  ),
              ]
            else
              for (final p in visible)
                ProductRow(
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

  /// Fix what OFF got wrong (or add what it never had) — the manual screen
  /// in edit mode. No result handling: the model notifies on save and this
  /// route watches by id, so the page under it is already fresh.
  Future<void> _edit(BuildContext context, Product product) =>
      Navigator.of(context).push<Product?>(MaterialPageRoute<Product?>(
          builder: (_) => ManualProductScreen(initial: product)));

  /// Shelve it without the trip through Edit (Arnar, 2026-08-20: tagging
  /// was buried). The canonical pills, toggled live — every tap saves.
  /// Custom tags still live on the edit screen; this is the fast path.
  Future<void> _tagSheet(BuildContext context, String productId) async {
    final model = context.read<PantryModel>();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final tags = model.byId(productId)?.tags ?? const [];
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Category'),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final c in productCategories)
                      _CategoryToggle(
                        label: categoryLabel(c),
                        selected: tags.contains(c),
                        onTap: () async {
                          final next = tags.contains(c)
                              ? [for (final t in tags) if (t != c) t]
                              : [...tags, c];
                          await model.setTags(productId, next);
                          setSheet(() {});
                        },
                      ),
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Ask OFF about this ONE product again. Hand-edited files warn first —
  /// this is the only path that overwrites edits, and the confirm says
  /// honestly what survives (photo, tags) before what gets replaced.
  Future<void> _refreshFromOff(BuildContext context, Product product) async {
    final model = context.read<PantryModel>();
    if (product.userEdited) {
      final ok = await showDestructiveConfirm(
        context,
        title: 'Replace your edits?',
        body: 'Your photo and tags stay. The name, brand and nutrition you '
            'typed are overwritten with whatever Open Food Facts has now, '
            'and the edited-by-hand mark is cleared.',
        verb: 'Replace',
      );
      if (!ok || !context.mounted) return;
    }
    final outcome = await model.refreshOne(product.id);
    if (!context.mounted) return;
    final line = switch (outcome) {
      PantryAdded() => 'Updated from Open Food Facts',
      PantryNotFound() =>
        'No longer on Open Food Facts — your copy is kept as it is',
      PantryUnavailable() => 'Open Food Facts didn\'t answer — try again',
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(line)));
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
          const SizedBox(height: 10),
          // Shelving, right here on the product — one tap to the category
          // pills, no trip through Edit (Arnar, 2026-08-20).
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final tag in product.tags)
              _CategoryToggle(
                label: categoryLabel(tag),
                selected: true,
                onTap: () => _tagSheet(context, product.id),
              ),
            _CategoryToggle(
              label: product.tags.isEmpty ? '+ Category' : '+',
              selected: false,
              onTap: () => _tagSheet(context, product.id),
            ),
          ]),
          const SizedBox(height: 16),
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
          const SizedBox(height: 20),
          // The two deliberate per-product actions (photo-button idiom).
          // "Update" hides on barcode-less manual foods — dead-end rule:
          // there is nothing to look up.
          OutlinedButton.icon(
            onPressed: () => _edit(context, product),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Edit this product'),
          ),
          if (product.barcode.isNotEmpty) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: model.busy
                  ? null
                  : () => _refreshFromOff(context, product),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Update from Open Food Facts'),
            ),
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

/// The category pill on the product page and its tag sheet — the chip-row
/// look (category_chips.dart), toggling instead of filtering.
class _CategoryToggle extends StatelessWidget {
  const _CategoryToggle(
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
