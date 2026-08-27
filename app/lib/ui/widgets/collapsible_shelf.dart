// The folded shelf — one collapsible list of headers, shared by the Pantry
// tab's category shelf and the Add-food sheet's category / recipe-tag shelves
// so the three cannot drift apart.
//
// The whole point is the FOLD, not the look: a section's [ShelfSection.builder]
// is only ever called while that section is open. Flat-rendering the pantry is
// what made the Add-food sheet slow to open (a 57-item spice wall built to
// draw a header), and a widget that "just" hides its children with Offstage or
// an AnimatedCrossFade would build them all over again. Nothing under a folded
// header exists.
//
// Sections are drawn in the order given: the caller owns shelf order (Unknown
// / Untagged pinned last), and open/closed is the caller's state as well —
// this widget holds none, so the Pantry tab can remember it and a modal sheet
// can start folded every time.

import 'package:flutter/material.dart';

import '../theme.dart';

class ShelfSection {
  const ShelfSection({
    required this.id,
    required this.label,
    required this.count,
    this.starterPack = false,
    required this.builder,
  });

  /// Stable key — the category or tag name. Toggling reports this.
  final String id;

  /// Display label, emoji included: '🥛 Dairy'. The caller decorates.
  final String label;

  final int count;

  /// Draws the leaf mark: a shelf full of bundled starter foods rather than
  /// the user's own scans. It is why those sections arrive collapsed.
  final bool starterPack;

  /// Built ONLY while the section is open. See the file header.
  final WidgetBuilder builder;
}

class CollapsibleShelf extends StatelessWidget {
  const CollapsibleShelf({
    super.key,
    required this.sections,
    required this.expanded,
    required this.onToggle,
  });

  final List<ShelfSection> sections;

  /// Ids currently open.
  final Set<String> expanded;

  final ValueChanged<String> onToggle;

  /// Compact enough that ten categories fit on one screen without scrolling —
  /// that is what buys "every category at a glance". 40 rather than the mock's
  /// 34 so the header is still an honest touch target.
  static const double headerHeight = 40;

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) return const SizedBox.shrink();
    final scheme = context.scheme;
    final rb = context.rb;
    final children = <Widget>[];
    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      final open = expanded.contains(section.id);
      children.add(_Header(
        section: section,
        open: open,
        // A hairline between blocks, never above the first one.
        divided: i > 0,
        onTap: () => onToggle(section.id),
      ));
      // The fold itself: the builder is not reached at all while closed.
      if (open) {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Builder(builder: section.builder),
        ));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: rb.hairline),
        boxShadow: rb.cardShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Column(children: children),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.section,
    required this.open,
    required this.divided,
    required this.onTap,
  });

  final ShelfSection section;
  final bool open;
  final bool divided;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final rb = context.rb;
    // Open reads in the primary tint — the one section you are looking at is
    // the one the eye should find on the way back up the shelf.
    final tint = open ? scheme.primary : scheme.onSurface;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: CollapsibleShelf.headerHeight,
        decoration: divided
            ? BoxDecoration(
                border: Border(top: BorderSide(color: rb.hairline)))
            : null,
        child: Row(children: [
          Expanded(
            child: Text(
              section.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(color: tint),
            ),
          ),
          const SizedBox(width: 8),
          Text('${section.count}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          if (section.starterPack) ...[
            const SizedBox(width: 6),
            Icon(Icons.eco_rounded,
                size: 14, color: scheme.onSurfaceVariant),
          ],
          const SizedBox(width: 6),
          Icon(open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              size: 20,
              color: open ? scheme.primary : scheme.onSurfaceVariant),
        ]),
      ),
    );
  }
}
