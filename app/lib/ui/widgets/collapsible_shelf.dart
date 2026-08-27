// One shelf, every category on it — the folded-header list the Pantry tab
// and the Add sheet both draw (design 1b / 2a). Categories stack vertically,
// so a shelf with twenty of them still fits the screen without the chip row's
// horizontal scroll-hunt.
//
// THE CONTRACT: a folded section's [ShelfSection.builder] is never called.
// Nothing under a closed header is built, measured or laid out — that is the
// whole point, because the three starter packs are ~60 products each and the
// old flat dump built all 180 to show a heading. Both surfaces depend on it,
// so the `if (open)` below is load-bearing, not an optimisation.
//
// Open/closed is NOT held here: the caller owns the set and decides whether
// it outlives the widget (the Pantry tab persists it through AppSettings).
// A stateless shelf cannot forget the user's choice on a rebuild.

import 'package:flutter/material.dart';

import '../theme.dart';
import 'skin.dart';

/// One folded header and the content behind it.
class ShelfSection {
  const ShelfSection({
    required this.id,
    required this.label,
    required this.count,
    this.starterPack = false,
    required this.builder,
  });

  /// Stable identity across rebuilds — the category name. It is what the
  /// caller stores, so it must not carry emoji or counts.
  final String id;

  /// Display label, emoji included: `categoryLabel()` output.
  final String label;

  /// Items behind the header. Shown on the header so a closed section still
  /// tells you how much is in it.
  final int count;

  /// Ships with the app rather than scanned — draws the leaf mark, and the
  /// caller's default rule folds these first.
  final bool starterPack;

  /// Built ONLY while the section is open. See the contract above.
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

  /// Ids of the sections currently open.
  final Set<String> expanded;

  /// The tapped section's id — the caller flips it in [expanded].
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    // No categories yet: no empty card floating on the page.
    if (sections.isEmpty) return const SizedBox.shrink();
    return TokenCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            _ShelfHeader(
              section: sections[i],
              open: expanded.contains(sections[i].id),
              // Hairline between rows, never above the first one — the card's
              // own border already draws that edge.
              divided: i > 0,
              onTap: () => onToggle(sections[i].id),
            ),
            if (expanded.contains(sections[i].id))
              Padding(
                // Indented under the label: the body reads as belonging to
                // the header above it, not as a new top-level list.
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: sections[i].builder(context),
              ),
          ],
        ],
      ),
    );
  }
}

class _ShelfHeader extends StatelessWidget {
  const _ShelfHeader({
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
    // The open section is the one you are reading: it takes the accent, the
    // rest stay quiet so twenty headers don't shout at once.
    final accent = open ? scheme.primary : scheme.onSurface;
    return Semantics(
      button: true,
      expanded: open,
      child: InkWell(
        onTap: onTap,
        child: Container(
          // 44 not the mockup's 34: a header is a tap target before it is a
          // line of type.
          height: 44,
          decoration: divided
              ? BoxDecoration(
                  border: Border(top: BorderSide(color: context.rb.separator)))
              : null,
          child: Row(children: [
            Flexible(
              child: Text(
                section.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600, color: accent),
              ),
            ),
            const SizedBox(width: 9),
            Text('${section.count}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            const Spacer(),
            if (section.starterPack) ...[
              Icon(Icons.eco_rounded,
                  size: 15, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
            ],
            Icon(open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                size: 20,
                color: open ? scheme.primary : scheme.onSurfaceVariant),
          ]),
        ),
      ),
    );
  }
}
