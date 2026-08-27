// How a tag is drawn, in one place, so the cookbook filter row, the recipe
// detail row and the Settings editor cannot drift apart.
//
// Three forms, from two fields:
//   icon + showLabel → a pill:   ⚡ Weeknight
//   icon, no label   → a circle: ⚡        (the only form that fits on a grid
//                                 cover card beside the heart)
//   no icon          → label only (RecipeTag forces showLabel in that case,
//                                 so a blank chip cannot be built)

import 'package:flutter/material.dart';

import '../domain/recipe_tag.dart';
import '../domain/tag_icons.dart';
import 'icons/food_icons.dart';
import 'theme.dart';

/// The eight tints, resolved against the live scheme so a tag reads correctly
/// in both themes. Named colours rather than stored hex for exactly this.
Color tagColorOf(BuildContext context, TagColor c) {
  final scheme = context.scheme;
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (c) {
    TagColor.primary => scheme.primary,
    // Each pair is (light-theme tint, dark-theme tint). The dark values are
    // lifted so they clear a navy surface instead of sinking into it.
    TagColor.red => dark ? const Color(0xFFFF8A80) : const Color(0xFFC62828),
    TagColor.orange => dark ? const Color(0xFFFFB74D) : const Color(0xFFE65100),
    TagColor.amber => dark ? const Color(0xFFFFD54F) : const Color(0xFF9A6600),
    TagColor.green => dark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
    TagColor.teal => dark ? const Color(0xFF4DD0C4) : const Color(0xFF00695C),
    TagColor.blue => dark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0),
    TagColor.purple => dark ? const Color(0xFFB388FF) : const Color(0xFF6A1B9A),
  };
}

/// The icon half of a chip: a Material glyph for a catalog key, the character
/// itself for an emoji. Nothing else can be in that field.
class TagGlyph extends StatelessWidget {
  const TagGlyph({super.key, required this.tag, this.size = 15, this.color});

  final RecipeTag tag;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final icon = tag.icon;
    if (icon == null) return const SizedBox.shrink();
    if (!isTagIconKey(icon)) {
      // Emoji: Android ships Noto Color Emoji, so this needs no font work.
      // Slightly smaller than the glyph box — emoji render tall.
      return Text(icon, style: TextStyle(fontSize: size * 0.95));
    }
    return Icon(foodIcon(icon), size: size, color: color);
  }
}

/// One tag chip. [selected] is the filter-row state; [onTap] null draws it
/// inert (recipe detail, the editor's preview).
class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.tag,
    this.selected = false,
    this.onTap,
    this.onDeleted,
    this.height = 36,
  });

  final RecipeTag tag;
  final bool selected;
  final VoidCallback? onTap;

  /// Draws a small × inside the chip. Used by the recipe's own tag row to take
  /// a tag off THAT recipe — it never deletes the tag itself.
  final VoidCallback? onDeleted;

  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final tint = tagColorOf(context, tag.color);
    // Selected: the tag's own colour carries the chip. Unselected: a neutral
    // surface with the colour on the glyph, so a row of chips reads as one
    // row and the colours stay a scanning aid rather than a fairground.
    final bg = selected
        ? tint.withValues(alpha: theme.brightness == Brightness.dark ? 0.28 : 0.16)
        : scheme.surfaceContainerHigh;
    final fg = selected ? tint : scheme.onSurface;
    final circle = tag.icon != null && !tag.showLabel;

    final content = circle
        // Bigger than the pill's glyph: in the circle form the icon IS the
        // chip, so it gets the room the label would have taken.
        ? Center(child: TagGlyph(tag: tag, size: height * 0.5, color: fg))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (tag.icon != null) ...[
                TagGlyph(tag: tag, size: 15, color: tint),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  tag.name,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600, color: fg),
                ),
              ),
              if (onDeleted != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onDeleted,
                  child: Icon(Icons.close_rounded,
                      size: 14, color: scheme.onSurfaceVariant),
                ),
              ],
            ],
          );

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        height: height,
        width: circle ? height : null,
        padding: circle
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: bg,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(999),
          border: selected
              ? Border.all(color: tint.withValues(alpha: 0.55))
              : null,
        ),
        child: content,
      ),
    );
  }
}
