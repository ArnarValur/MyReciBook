// Pantry tab — the POC surface for the food base (Arnar's slot-2 test call,
// 2026-08-17): scan a barcode off the shelf, OFF fills in the product, one
// JSON lands in the user's pantry folder. Everything downstream (ingredient
// linking, nutrition badges, diary totals) builds on this screen existing.
//
// Drawn to design 1b: the two shelf actions are icons on the title row, the
// chip bar and the flat category dump are one collapsible shelf (every
// category at a glance, no horizontal scroll, the fold remembered), and a
// search box flattens it back to plain rows once the shelf runs to hundreds.
//
// Long-press a row removes it (grocery's destructive-confirm shape); a
// not-on-OFF scan states the label-photo fallback honestly.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_settings.dart';
import '../../domain/product.dart';
import '../../domain/product_categories.dart';
import '../theme.dart';
import '../widgets/collapsible_shelf.dart';
import '../widgets/product_row.dart';
import '../widgets/skin.dart';
import 'barcode_scan_screen.dart';
import 'manual_product_screen.dart';
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
  /// What the search box holds; empty means the shelf is on screen. Plain
  /// screen state — a search is a way of looking, not data worth persisting.
  final _searchField = TextEditingController();
  String _query = '';

  /// The shelf sections the user has open. Null = they have never touched a
  /// header on this install, and the default fold applies instead. Persisted,
  /// because a shelf that forgot itself would bury the screen under 180
  /// starter rows on every launch (design 1b).
  Set<String>? _expanded;

  /// Null under a bare pump (nothing provided it) — the shelf still works,
  /// it just forgets the fold between launches.
  AppSettings? _settings;

  @override
  void initState() {
    super.initState();
    try {
      _settings = context.read<AppSettings?>();
    } on ProviderNotFoundException {
      _settings = null;
    }
    _expanded = _settings?.pantryOpenSections?.toSet();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PantryModel>().ensureLoaded();
    });
  }

  @override
  void dispose() {
    _searchField.dispose();
    super.dispose();
  }

  /// Fold or unfold one section. The full open set is written every time, so
  /// what lands on disk is always the whole answer — no merge on read.
  Future<void> _toggleSection(String id, Set<String> open) async {
    final next = {...open};
    if (!next.remove(id)) next.add(id);
    setState(() => _expanded = next);
    try {
      await _settings?.setPantryOpenSections(next.toList());
    } catch (_) {} // persistence best-effort — the shelf is already redrawn
  }

  /// The shelf-sweep session: the scan screen stays open, saving product
  /// after product through [_collect]; Back lands here with the list already
  /// current (the model notified on every add).
  Future<void> _scan() =>
      Navigator.of(context).push<void>(MaterialPageRoute<void>(
          builder: (_) => BarcodeScanScreen(collect: _collect)));

  /// One detection → one honest flash line. The three-way outcome keeps
  /// "OFF didn't answer" visibly different from "not in the database".
  ///
  /// Two of the three now carry an action on the bar (Arnar 2026-08-27):
  /// a hit opens what was just saved so the numbers can be checked with the
  /// pack still in hand, and a miss leads straight into creating it. Only
  /// "OFF didn't answer" stays inert — there is nothing to open and nothing
  /// worth creating, only a rescan.
  Future<ScanFeedback> _collect(String digits) async {
    final outcome = await context.read<PantryModel>().addByBarcode(digits);
    switch (outcome) {
      case PantryAdded(:final product, :final wasKnown):
        return ScanFeedback(
          wasKnown ? '${product.name} — refreshed' : '${product.name} — added',
          actionLabel: 'Check',
          action: () => _openDetail(product),
        );
      case PantryNotFound(:final barcode):
        return ScanFeedback(
          'Not on Open Food Facts — nothing saved',
          ok: false,
          actionLabel: 'Add it',
          action: () => _createFromScan(barcode),
        );
      case PantryUnavailable():
        return const ScanFeedback(
            'Open Food Facts didn\'t answer — scan it again',
            ok: false);
    }
  }

  /// The miss door: create the product the database has never heard of, with
  /// its barcode already on the file so a later scan finds it again.
  Future<void> _createFromScan(String barcode) =>
      Navigator.of(context).push<void>(MaterialPageRoute<void>(
          builder: (_) => ManualProductScreen(barcode: barcode)));

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

  /// One pantry row, the shared card — the shelf, the search results and the
  /// diary's picker all draw the same product.
  Widget _row(PantryModel model, Product p) => ProductRow(
        product: p,
        imageFile: model.imageFileOf(p),
        onTap: () => _openDetail(p),
        onLongPress: () => _removeSheet(model, p.id, p.name),
      );

  /// A section counts as a starter pack when most of it came from the
  /// built-in packages: one scanned broccoli must not un-fold the sixty
  /// vegetables it landed beside.
  static bool _isStarterPack(List<Product> members) =>
      members.where((p) => p.source == 'starter').length > members.length / 2;

  /// The fold nobody chose: starter packs closed (3×~60 rows the user never
  /// asked to see), everything they put there themselves open. It applies
  /// only until they touch a header — from then on their own set is the
  /// answer, which is why a category added later arrives closed instead of
  /// re-seeding this.
  static Set<String> _defaultOpen(List<ShelfSection> sections) => {
        for (final s in sections)
          if (!s.starterPack) s.id
      };

  /// The picker's matching rule, verbatim: name, brand or synonym substring —
  /// "Paprika" has to find Bell Pepper on this screen too.
  static List<Product> _search(List<Product> products, String q) => [
        for (final p in products)
          if (p.name.toLowerCase().contains(q) ||
              (p.brand ?? '').toLowerCase().contains(q) ||
              p.synonyms.any((s) => s.toLowerCase().contains(q)))
            p
      ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final model = context.watch<PantryModel>();

    // The shelf: one folded header per category, "Other" last
    // (compareCategories), alphabetical inside — never the scan sequence.
    // The section list is rebuilt every frame, but the rows behind a closed
    // header are not: CollapsibleShelf leaves those builders uncalled.
    final sections = [
      for (final (category, members) in groupByCategory(model.products))
        ShelfSection(
          id: category,
          label: categoryLabel(category),
          count: members.length,
          starterPack: _isStarterPack(members),
          builder: (_) =>
              Column(children: [for (final p in members) _row(model, p)]),
        ),
    ];
    final open = _expanded ?? _defaultOpen(sections);

    // Typing flattens the shelf: categories are a way of browsing, and once
    // you know the name you want, they are in the way.
    final query = _query.trim().toLowerCase();
    final results =
        query.isEmpty ? const <Product>[] : _search(model.products, query);

    return Scaffold(
      body: SafeArea(
        bottom: false, // content scrolls under the shell's glass bar
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 24, 20, navBarClearance(context)),
          children: [
            if (widget.header != null) ...[
              widget.header!,
              const SizedBox(height: 16),
            ],
            // Title row — count under the title, both shelf actions
            // compressed to icons beside it (design 1b). Starter foods used
            // to own a permanent full-width row for a thing you do once.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pantry',
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(fontSize: 26, letterSpacing: -0.4)),
                      const SizedBox(height: 2),
                      Text(model.caption,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                // The un-barcoded door: fresh produce and spices come built
                // in (starter_foods.dart) — nothing edible needs a barcode.
                // Tooltip doubles as the semantics label; an icon-only tap
                // target must read under TalkBack.
                IconButton.filledTonal(
                  key: const Key('pantry-starter-foods'),
                  tooltip: 'Add starter foods — veggies, fruit, spices',
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      Navigator.of(context).push<void>(MaterialPageRoute<void>(
                          builder: (_) => const StarterFoodsScreen())),
                  icon: const Icon(Icons.eco_rounded, size: 19),
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
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: model.busy ? null : _scan,
              icon: const Icon(Icons.barcode_reader),
              label: Text(model.busy ? 'Looking it up…' : 'Scan a product'),
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
            // Nothing on the shelf, nothing to search for.
            if (model.products.isNotEmpty) ...[
              const SizedBox(height: 10),
              TextField(
                key: const Key('pantry-search'),
                controller: _searchField,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search ${model.caption}…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => setState(() {
                            _searchField.clear();
                            _query = '';
                          }),
                        ),
                  filled: true,
                  fillColor: scheme.surfaceContainerHigh,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                ),
              ),
            ],
            const SizedBox(height: 16),
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
                  child: Icon(Icons.kitchen_rounded,
                      size: 32, color: scheme.primary),
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
            ] else if (query.isNotEmpty) ...[
              if (results.isEmpty)
                Text('Nothing on the shelf matches that.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant))
              else
                for (final p in results) _row(model, p),
            ] else
              CollapsibleShelf(
                sections: sections,
                expanded: open,
                onToggle: (id) => _toggleSection(id, open),
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
