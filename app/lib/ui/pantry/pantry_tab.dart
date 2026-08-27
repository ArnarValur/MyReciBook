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
import '../../domain/product_categories.dart';
import '../theme.dart';
import '../widgets/category_chips.dart';
import '../widgets/product_row.dart';
import '../widgets/skin.dart';
import 'barcode_scan_screen.dart';
import 'pantry_model.dart';
import 'product_page.dart';
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
          builder: (_) => ProductPage(productId: p.id)));

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
