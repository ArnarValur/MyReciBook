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


/// A tag squeezed down to a badge, for the cookbook's rows and cover cards.
///
/// Always the ICON form, whatever the tag's own showLabel says: a row has no
/// room for words, and a glyph plus its colour is exactly the scanning aid
/// colour was added for. A tag with no icon falls back to its first letter,
/// so it still says WHICH tag rather than just "there is one".
class TagBadge extends StatelessWidget {
  const TagBadge({super.key, required this.tag, this.size = 20});

  final RecipeTag tag;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tint = tagColorOf(context, tag.color);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: dark ? 0.3 : 0.16),
        shape: BoxShape.circle,
      ),
      child: tag.icon != null
          ? TagGlyph(tag: tag, size: size * 0.62, color: tint)
          : Text(
              tag.name.characters.first.toUpperCase(),
              style: TextStyle(
                fontSize: size * 0.5,
                height: 1,
                fontWeight: FontWeight.w700,
                color: tint,
              ),
            ),
    );
  }
}

/// The badges for one recipe, in the user's Settings order, capped so a
/// heavily tagged recipe cannot push the title out of its own row.
class TagBadgeRow extends StatelessWidget {
  const TagBadgeRow({
    super.key,
    required this.names,
    required this.decorate,
    this.max = 3,
    this.size = 20,
  });

  /// The recipe's tag strings, already ordered.
  final List<String> names;

  /// Usually TagsModel.chipFor — decoration if the tag has one, a plain tag
  /// if it does not.
  final RecipeTag Function(String) decorate;

  final int max;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) return const SizedBox.shrink();
    final shown = names.take(max).toList();
    final extra = names.length - shown.length;
    final scheme = context.scheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final name in shown) ...[
          TagBadge(tag: decorate(name), size: size),
          const SizedBox(width: 4),
        ],
        if (extra > 0)
          Container(
            height: size,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('+$extra',
                style: TextStyle(
                    fontSize: size * 0.5,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant)),
          ),
      ],
    );
  }
}


/// The one door that adds a tag — a dashed chip so it reads as an action and
/// not as a tag called "Tag". Shared by the recipe page and the import
/// review, which are the two places a tag gets put on something.
class AddTagChip extends StatelessWidget {
  const AddTagChip({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return InkWell(
      key: const Key('add-tag-chip'),
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 15, color: scheme.primary),
            const SizedBox(width: 4),
            Text('Tag',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600, color: scheme.primary)),
          ],
        ),
      ),
    );
  }
}
