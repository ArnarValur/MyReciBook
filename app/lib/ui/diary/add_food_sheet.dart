// "Add food" — the picker, MFP's food search in this app's idiom.
//
// Four doors, in the order a real week uses them: what you ate recently, your
// own shelf, a barcode you haven't scanned yet, and a food you type in
// yourself (the fruit-and-veg door — nothing edible has to have a barcode).
// Quick add sits at the bottom for the meal out you'll never itemise.
//
// Picking a food opens the log sheet; the log sheet is where the serving and
// the amount are chosen, so nothing is ever logged by a single stray tap.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/diary.dart';
import '../../domain/product.dart';
import '../pantry/barcode_scan_screen.dart';
import '../pantry/manual_product_screen.dart';
import '../pantry/pantry_model.dart';
import '../theme.dart';
import '../widgets/product_row.dart';
import '../widgets/skin.dart';
import 'diary_model.dart';
import 'diary_tab.dart' show showAmountDialog;
import 'log_food_sheet.dart';

Future<void> showAddFoodSheet(BuildContext context,
    {required String meal}) async {
  final diary = context.read<DiaryModel>();
  final pantry = context.read<PantryModel>();
  await pantry.ensureLoaded();
  await diary.ensureRecents();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => MultiProvider(
      // The sheet is a separate route: it needs the shell's models handed to
      // it explicitly, the same way the pushed detail routes do.
      providers: [
        ChangeNotifierProvider<DiaryModel>.value(value: diary),
        ChangeNotifierProvider<PantryModel>.value(value: pantry),
      ],
      child: _AddFoodSheet(meal: meal),
    ),
  );
}

class _AddFoodSheet extends StatefulWidget {
  const _AddFoodSheet({required this.meal});

  final String meal;

  @override
  State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<_AddFoodSheet> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Everything on the shelf whose name or brand contains the query. No
  /// fuzzy matching: the user's own pantry is small enough that substring
  /// search is honest and instant.
  List<Product> _matches(List<Product> products) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return products;
    return [
      for (final p in products)
        if (p.name.toLowerCase().contains(q) ||
            (p.brand ?? '').toLowerCase().contains(q))
          p
    ];
  }

  Future<void> _log(Product product) async {
    final logged = await showLogFoodSheet(context,
        product: product, meal: widget.meal);
    if (logged == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _logAgain(DiaryEntry previous) async {
    await context.read<DiaryModel>().logAgain(previous, meal: widget.meal);
    if (mounted) Navigator.of(context).pop();
  }

  /// Scan a barcode that isn't on the shelf yet: it lands in the pantry as a
  /// product file first (the pantry stays the one food base), then the log
  /// sheet opens on it.
  Future<void> _scan() async {
    final pantry = context.read<PantryModel>();
    Product? scanned;
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => BarcodeScanScreen(collect: (digits) async {
        final outcome = await pantry.addByBarcode(digits);
        switch (outcome) {
          case PantryAdded(:final product):
            scanned = product;
            return ScanFeedback('${product.name} — ready to log');
          case PantryNotFound():
            return const ScanFeedback(
                'Not on Open Food Facts — add it by hand instead',
                ok: false);
          case PantryUnavailable():
            return const ScanFeedback(
                'Open Food Facts didn\'t answer — scan it again',
                ok: false);
        }
      }),
    ));
    final product = scanned;
    if (!mounted || product == null) return;
    await _log(product);
  }

  /// The no-barcode door: apples, a bag of carrots, grandma's bread. The food
  /// is saved to the pantry as a manual product, then logged.
  Future<void> _createFood() async {
    final created = await Navigator.of(context).push<Product>(
        MaterialPageRoute<Product>(
            builder: (_) => const ManualProductScreen()));
    if (!mounted || created == null) return;
    await _log(created);
  }

  Future<void> _quickAdd() async {
    final kcal = await _askCalories();
    if (kcal == null || !mounted) return;
    await context
        .read<DiaryModel>()
        .logQuickAdd(meal: widget.meal, kcal: kcal);
    if (mounted) Navigator.of(context).pop();
  }

  Future<double?> _askCalories() => showAmountDialog(
        context,
        title: 'Quick add',
        subtitle: 'Calories only, no food behind them — for the meal out you '
            'are never going to itemise.',
        label: 'kcal',
        confirm: 'Add',
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final pantry = context.watch<PantryModel>();
    final diary = context.watch<DiaryModel>();
    final matches = _matches(pantry.products);
    final searching = _query.trim().isNotEmpty;
    final media = MediaQuery.of(context);
    final insets = media.viewInsets.bottom;
    // Same gesture-bar rule as the log sheet: the last row must clear it.
    final systemBar = insets > 0 ? 0.0 : media.viewPadding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + systemBar),
          children: [
            Text('Add to ${widget.meal.toLowerCase()}',
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontSize: 22, letterSpacing: -0.3)),
            const SizedBox(height: 12),
            TextField(
              controller: _search,
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
            const SizedBox(height: 14),
            Row(children: [
              MetaChip(
                  icon: Icons.barcode_reader, label: 'Scan', onTap: _scan),
              const SizedBox(width: 8),
              MetaChip(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Create food',
                  onTap: _createFood),
              const SizedBox(width: 8),
              MetaChip(
                  icon: Icons.bolt_rounded,
                  label: 'Quick add',
                  onTap: _quickAdd),
            ]),
            const SizedBox(height: 20),
            if (!searching && diary.recents.isNotEmpty) ...[
              const SectionLabel('Recent'),
              const SizedBox(height: 8),
              for (final entry in diary.recents.take(8)) ...[
                _RecentRow(entry: entry, onTap: () => _logAgain(entry)),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 12),
            ],
            SectionLabel(searching
                ? 'Pantry · ${matches.length} match'
                    '${matches.length == 1 ? '' : 'es'}'
                : 'Your pantry'),
            const SizedBox(height: 8),
            if (matches.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  searching
                      ? 'Nothing on the shelf matches that. Scan its barcode, '
                          'or create the food yourself.'
                      : 'Your pantry is empty. Scan a barcode, or create a '
                          'food by hand — an apple has no barcode either.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
                ),
              )
            else
              // The same card the Pantry tab shows, photo included (Arnar,
              // 2026-08-19: same card, same purpose). ProductRow carries its
              // own bottom gap, so no spacer here.
              for (final product in matches)
                ProductRow(
                  product: product,
                  imageFile: pantry.imageFileOf(product),
                  onTap: () => _log(product),
                ),
          ],
        ),
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.entry, required this.onTap});

  final DiaryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    return TokenCard(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: InkWell(
        onTap: onTap,
        child: Row(children: [
          Icon(Icons.history_rounded, size: 18, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall),
                Text(entry.servingSummary,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          Text('${(entry.total.kcal ?? 0).round()} kcal',
              style: theme.textTheme.labelMedium),
        ]),
      ),
    );
  }
}
