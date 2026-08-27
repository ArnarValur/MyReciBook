// Grocery screen (design 4a), live over GroceryModel: merge is
// suggest-and-confirm (never silent), plan changes surface as a dismissible
// receipt banner, aisle corrections are remembered, staples auto-dim.
//
// Undesigned on 4a — built minimal, copy flagged for design: the move gesture
// (long-press → aisle sheet), manual add field, the share/clear menu, and the
// empty state (reuses the shell's honest zero-state look).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:provider/provider.dart';

import '../domain/grocery.dart';
import '../features.dart';
import 'grocery_model.dart';
import 'library_model.dart';
import 'pantry/pantry_model.dart';
import 'theme.dart';
import 'widgets/skin.dart';

class GroceryTab extends StatefulWidget {
  const GroceryTab({super.key});

  @override
  State<GroceryTab> createState() => _GroceryTabState();
}

class _GroceryTabState extends State<GroceryTab> {
  final _addField = TextEditingController();

  @override
  void initState() {
    super.initState();
    // The "in your pantry" hint needs the shelf; cheap and cached after boot
    // (recipe detail's idiom).
    if (kPantryEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<PantryModel>().ensureLoaded();
      });
    }
  }

  @override
  void dispose() {
    _addField.dispose();
    super.dispose();
  }

  void _submitAdd() {
    final name = _addField.text.trim();
    if (name.isEmpty) return;
    _addField.clear();
    context.read<GroceryModel>().addManual(name);
  }

  void _onMenu(String action) {
    final model = context.read<GroceryModel>();
    switch (action) {
      case 'copy':
        Clipboard.setData(ClipboardData(text: model.exportText()));
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('List copied')));
      case 'clear':
        model.clearCompleted();
      case 'clearAll':
        _clearAll(model);
    }
  }

  /// Undo snackbar shared by row-swipe and clear-all: a destructive slip
  /// mid-shop must cost one tap, not a re-plan.
  void _undoBar(String label, List<GroceryItem> snapshot) {
    final model = context.read<GroceryModel>();
    // removeCurrent (instant), not hideCurrent (animated): the undo bar must
    // not wait in queue behind a stale toast's exit animation.
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(label),
        action: SnackBarAction(
            label: 'Undo', onPressed: () => model.restore(snapshot)),
      ));
  }

  Future<void> _clearAll(GroceryModel model) async {
    // 6f shape — body says what SURVIVES before what stops.
    final ok = await showDestructiveConfirm(
      context,
      title: 'Clear the whole list?',
      body: 'Your aisle corrections and merge choices are remembered — '
          'they apply again next time. Every item on the list right now '
          'is removed.',
      verb: 'Clear list',
    );
    if (!ok || !mounted) return;
    // Snapshot first, then fire-and-forget: the undo bar must not wait on
    // the persist (D3: pure op → notify → best-effort persist).
    final snapshot = model.items;
    model.clearAll();
    _undoBar('List cleared', snapshot);
  }

  // Simplest recategorize gesture (the per-store aisle switcher is left
  // undesigned by turn 4): long-press a row, pick or type the aisle.
  Future<void> _moveSheet(GroceryItem item) async {
    final model = context.read<GroceryModel>();
    final target = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 4,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Move to'),
            for (final aisle in model.aisleChoices)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(aisle,
                    style: TextStyle(
                        color: aisle == item.category
                            ? ctx.scheme.primary
                            : null)),
                onTap: () => Navigator.pop(ctx, aisle),
              ),
            TextField(
              key: const Key('new-aisle-field'),
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(hintText: 'New aisle'),
              onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
            ),
          ],
        ),
      ),
    );
    if (target == null || target.isEmpty || target == item.category) return;
    await model.moveTo(item.id, target);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final model = context.watch<GroceryModel>();
    final titles = {
      for (final r in context.watch<LibraryModel>().recipes) r.id: r.title
    };
    // Owned pantry ids for the row hint — hint only, never row behavior.
    final owned = <String>{
      if (kPantryEnabled)
        for (final p in context.watch<PantryModel>().products) p.id,
    };
    final items = model.items;
    final suggestion = model.suggestions.firstOrNull;

    final header = Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Grocery',
              style: theme.textTheme.headlineSmall?.copyWith(fontSize: 22)),
          Text(model.caption,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontSize: 12.5, color: scheme.onSurfaceVariant)),
        ]),
      ),
      PopupMenuButton<String>(
        key: const Key('grocery-share-button'),
        onSelected: _onMenu,
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'copy', child: Text('Copy list')),
          PopupMenuItem(value: 'clear', child: Text('Clear checked')),
          PopupMenuItem(value: 'clearAll', child: Text('Clear all…')),
        ],
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh, shape: BoxShape.circle),
          child: Icon(Icons.ios_share_rounded,
              size: 19, color: scheme.onSurfaceVariant),
        ),
      ),
    ]);

    final addField = TokenCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: TextField(
        key: const Key('grocery-add-field'),
        controller: _addField,
        textInputAction: TextInputAction.done,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Add an item',
          hintStyle: theme.textTheme.bodyMedium
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        onSubmitted: (_) => _submitAdd(),
      ),
    );

    if (items.isEmpty && suggestion == null) {
      return SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            header,
            const SizedBox(height: 11),
            addField,
            Expanded(
              child: Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.checklist_rounded,
                      size: 32, color: scheme.primary),
                ),
              ),
            ),
          ]),
        ),
      );
    }

    final sections = <String, List<GroceryItem>>{};
    for (final i in items) {
      sections.putIfAbsent(i.category, () => []).add(i);
    }
    final order = sections.keys.toList()..sort(GroceryCategories.compare);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 8, 20, navBarClearance(context)),
        children: [
          header,
          const SizedBox(height: 11),
          if (model.receipt != null) ...[
            _receiptBanner(model, theme, scheme),
            const SizedBox(height: 11),
          ],
          if (suggestion != null) ...[
            _mergeCard(suggestion, titles, theme, scheme),
            const SizedBox(height: 11),
          ],
          for (final category in order) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SectionLabel(
                '$category · ${sections[category]!.length}',
                trailing: GroceryCategories.isStock(category)
                    ? null
                    : _pinChip(theme, scheme),
              ),
            ),
            TokenCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Column(children: [
                for (var i = 0; i < sections[category]!.length; i++)
                  _itemRow(sections[category]![i], model,
                      last: i == sections[category]!.length - 1,
                      inPantry: owned.contains(sections[category]![i].productRef),
                      theme: theme,
                      scheme: scheme),
              ]),
            ),
            const SizedBox(height: 11),
          ],
          if (model.hasStaples) ...[
            Center(
              child: Text('Staples stay quiet unless you tap them.',
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11.5, color: scheme.onSurfaceVariant)),
            ),
            const SizedBox(height: 11),
          ],
          addField,
        ],
      ),
    );
  }

  Widget _receiptBanner(
      GroceryModel model, ThemeData theme, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
            scheme.secondaryContainer.withValues(alpha: 0.4), scheme.surface),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(Icons.event_repeat_rounded, size: 18, color: scheme.primary),
        const SizedBox(width: 9),
        Expanded(
          child: Text(model.receipt!,
              style:
                  theme.textTheme.bodySmall?.copyWith(fontSize: 12.5, height: 1.4)),
        ),
        InkWell(
          onTap: model.dismissReceipt,
          child:
              Icon(Icons.close_rounded, size: 16, color: scheme.onSurfaceVariant),
        ),
      ]),
    );
  }

  Widget _mergeCard(MergeSuggestion s, Map<String, String> titles,
      ThemeData theme, ColorScheme scheme) {
    TextSpan side(GroceryItem item) {
      final srcs = [
        for (final id in item.recipeParts.keys)
          if (titles[id] != null) titles[id]!
      ];
      return TextSpan(children: [
        TextSpan(
            text: item.qtyLabel.isEmpty
                ? item.name
                : '${item.qtyLabel} ${item.name}',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: scheme.onSurface)),
        if (srcs.isNotEmpty) TextSpan(text: ' (${srcs.join(', ')})'),
      ]);
    }

    final merged = s.mergedQtyLabel;
    final label = merged.isEmpty ? s.keep.name : '$merged ${s.keep.name}';
    return TokenCard(
      selected: true,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Same thing?',
            style: theme.textTheme.titleSmall?.copyWith(fontSize: 14)),
        const SizedBox(height: 3),
        Text.rich(
          TextSpan(children: [
            side(s.absorb),
            const TextSpan(text: ' + '),
            side(s.keep),
          ]),
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        Row(children: [
          FilledButton.tonal(
            onPressed: () => context.read<GroceryModel>().confirmMerge(s),
            style: FilledButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14)),
            child: Text('Merge · $label'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => context.read<GroceryModel>().keepApart(s),
            child: const Text('Keep apart'),
          ),
        ]),
      ]),
    );
  }

  Widget _pinChip(ThemeData theme, ColorScheme scheme) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.push_pin_rounded, size: 12, color: scheme.primary),
          const SizedBox(width: 3),
          Text('your aisle',
              style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: scheme.primary)),
        ]),
      );

  Widget _itemRow(GroceryItem item, GroceryModel model,
      {required bool last,
      required bool inPantry,
      required ThemeData theme,
      required ColorScheme scheme}) {
    // N8 tier 1: staples show the bare name — shopping, not cooking.
    final qty = item.displayQtyLabel;
    final moved = model.categoryOverrides.containsKey(item.key);
    final caption = item.staple
        ? null
        : moved
            ? 'moved here by you'
            : item.sourceCount > 1
                ? '${item.sourceCount} recipes'
                : null;

    final line = Row(children: [
      Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: item.checked ? scheme.primary : null,
          border:
              item.checked ? null : Border.all(color: scheme.outline, width: 2),
        ),
        child: item.checked
            ? Icon(Icons.check_rounded, size: 13, color: scheme.onPrimary)
            : null,
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text.rich(
          TextSpan(children: [
            if (qty.isNotEmpty)
              TextSpan(
                  text: '$qty ',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: item.name),
          ]),
          style: theme.textTheme.bodyMedium?.copyWith(
            decoration: item.checked ? TextDecoration.lineThrough : null,
            color: item.checked ? scheme.onSurfaceVariant : null,
          ),
        ),
      ),
      // N8 tier 2 hint — a bag ≠ enough: never checks off, removes, or dims
      // a row; it only says the product is on the shelf.
      if (inPantry) ...[
        Icon(Icons.kitchen_rounded, size: 12, color: scheme.onSurfaceVariant),
        const SizedBox(width: 3),
        Text('in your pantry',
            style: theme.textTheme.bodySmall
                ?.copyWith(fontSize: 11, color: scheme.onSurfaceVariant)),
      ],
      if (caption != null) ...[
        if (inPantry) const SizedBox(width: 8),
        Text(caption,
            style: theme.textTheme.bodySmall
                ?.copyWith(fontSize: 11, color: scheme.onSurfaceVariant)),
      ],
      if (inPantry && item.staple) const SizedBox(width: 8),
      if (item.staple)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8)),
          child: Text('staple',
              style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant)),
        ),
    ]);

    // Swipe left removes ONE row (undo in the snackbar) — the affordance
    // missing from Arnar's first shop-through, 2026-08-06.
    return Dismissible(
      key: ValueKey('grocery-${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 8),
        child: Icon(Icons.delete_rounded, size: 20, color: scheme.error),
      ),
      onDismissed: (_) {
        // Snapshot before the removal notifies; undo bar shows immediately,
        // never gated on the persist.
        final snapshot = model.items;
        model.removeItem(item.id);
        _undoBar('Removed ${item.name}', snapshot);
      },
      child: InkWell(
        onTap: () => model.toggleItem(item.id),
        onLongPress: () => _moveSheet(item),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: last
              ? null
              : BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: context.rb.separator))),
          child: item.staple ? Opacity(opacity: 0.55, child: line) : line,
        ),
      ),
    );
  }
}
