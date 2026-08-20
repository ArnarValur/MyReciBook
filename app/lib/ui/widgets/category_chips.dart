// The category chip row — one widget for the pantry shelf and the Add-food
// drawer, so "pick a category" reads the same on both ends. Emoji render as
// text (Android's system font IS Noto Color Emoji); custom tags name-only.
//
// The row is dumb on purpose: counts and order come from categoryCounts
// (domain/product_categories.dart), selection is the caller's state.

import 'package:flutter/material.dart';

import '../../domain/product_categories.dart';
import '../theme.dart';

class CategoryChipRow extends StatelessWidget {
  const CategoryChipRow({
    super.key,
    required this.counts,
    required this.active,
    required this.onSelect,
  });

  /// Category → product count, already ordered (categoryCounts).
  final Map<String, int> counts;

  /// The selected category; null is "All".
  final String? active;

  /// Called with the tapped category, or null when "All" is tapped.
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        _CategoryPill(
          label: 'All',
          selected: active == null,
          onTap: () => onSelect(null),
        ),
        for (final entry in counts.entries) ...[
          const SizedBox(width: 8),
          _CategoryPill(
            label: '${categoryLabel(entry.key)} ${entry.value}',
            selected: active == entry.key,
            onTap: () => onSelect(entry.key),
          ),
        ],
      ]),
    );
  }
}

/// The pill look shared with the manual screen's tag picker (primary fill
/// when chosen) — moved here verbatim from pantry_tab's _FilterPill.
class _CategoryPill extends StatelessWidget {
  const _CategoryPill(
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
