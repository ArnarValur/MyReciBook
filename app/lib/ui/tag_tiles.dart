// The cookbook's tag strip — how the tag system is projected (Direction A,
// Arnar 2026-09-03, replacing the folded shelf that stacked untagged recipes
// above tagged ones and filed a recipe once per tag).
//
// One tile per thing the grid can be narrowed to: Favorites first (the
// built-in no tag can replace), then the user's tags in tags.json order, then
// any tag the library carries that tags.json says nothing about, then the
// door that makes a new one. A tile shows the covers of the recipes inside
// it, so a tag reads as a shelf of food rather than a word in a list. Tap =
// narrow the one grid in place. Long-press = the tag sheet.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/recipe.dart';
import '../domain/recipe_tag.dart';
import 'library_model.dart';
import 'tag_chip.dart';
import 'theme.dart';
import 'widgets/skin.dart';

/// The id of the built-in Favorites tile. Every other id is a canonical tag
/// name ([RecipeTag.canonical]).
const String kFavoritesTileId = 'favorites';

class TagTileData {
  const TagTileData({
    required this.id,
    required this.label,
    required this.recipes,
    this.tag,
  });

  final String id;
  final String label;

  /// The recipes the tile narrows to, in library order.
  final List<Recipe> recipes;

  /// The tag's look. Null only for Favorites, which wears the heart.
  final RecipeTag? tag;

  bool get isFavorites => tag == null;
}

class TagTileStrip extends StatelessWidget {
  const TagTileStrip({
    super.key,
    required this.tiles,
    required this.selectedId,
    required this.onSelect,
    required this.onEdit,
    required this.onNew,
    this.showNew = true,
  });

  final List<TagTileData> tiles;
  final String? selectedId;

  /// Tapping the selected tile again hands back null — the caller clears.
  final ValueChanged<String?> onSelect;
  final ValueChanged<TagTileData> onEdit;
  final VoidCallback onNew;
  final bool showNew;

  static const double tileWidth = 120;
  static const double tileHeight = 132;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Air above and below for the selected tile's glow; the list clips.
      height: tileHeight + 12,
      child: ListView.separated(
        key: const Key('tag-tile-strip'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        itemCount: tiles.length + (showNew ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          if (i == tiles.length) return _NewTile(onTap: onNew);
          final t = tiles[i];
          final selected = t.id == selectedId;
          return TagTile(
            data: t,
            selected: selected,
            onTap: () => onSelect(selected ? null : t.id),
            onLongPress: t.isFavorites ? null : () => onEdit(t),
          );
        },
      ),
    );
  }
}

class TagTile extends StatelessWidget {
  const TagTile({
    super.key,
    required this.data,
    this.selected = false,
    this.onTap,
    this.onLongPress,
  });

  final TagTileData data;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final rb = context.rb;
    final tint = data.isFavorites
        ? scheme.tertiary
        : tagColorOf(context, data.tag!.color);
    final n = data.recipes.length;
    final badge = data.isFavorites
        ? _HeartBadge(tint: tint)
        : TagBadge(tag: data.tag!, size: 20);
    return Semantics(
      button: true,
      selected: selected,
      label: '${data.label}, $n recipe${n == 1 ? '' : 's'}',
      child: InkWell(
        key: Key('tag-tile-${data.id}'),
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          width: TagTileStrip.tileWidth,
          height: TagTileStrip.tileHeight,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? tint : rb.hairline,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: tint.withValues(alpha: 0.18),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : rb.cardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 72,
                  width: double.infinity,
                  child: _Collage(
                    recipes: data.recipes,
                    tint: tint,
                    emptyGlyph: data.isFavorites
                        ? Icon(Icons.favorite_rounded, size: 28, color: tint)
                        : data.tag!.icon != null
                            ? TagGlyph(tag: data.tag!, size: 28, color: tint)
                            : Text(
                                data.label.characters.first.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: tint,
                                ),
                              ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          badge,
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              data.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: selected ? tint : scheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Padding(
                        padding: const EdgeInsets.only(left: 26),
                        child: Text(
                          n == 0 ? 'none yet' : '$n recipe${n == 1 ? '' : 's'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The heart, as a badge — tertiary is the favourite's colour everywhere.
class _HeartBadge extends StatelessWidget {
  const _HeartBadge({required this.tint});

  final Color tint;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: dark ? 0.3 : 0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.favorite_rounded, size: 12, color: tint),
    );
  }
}

/// Up to four covers, tiled. Decoded small (cacheWidth) — six tiles of four
/// covers must never hold twenty-four full screenshots in memory.
class _Collage extends StatelessWidget {
  const _Collage({
    required this.recipes,
    required this.tint,
    required this.emptyGlyph,
  });

  final List<Recipe> recipes;
  final Color tint;
  final Widget emptyGlyph;

  @override
  Widget build(BuildContext context) {
    final rs = recipes.take(4).toList();
    if (rs.isEmpty) {
      return ColoredBox(
        color: tint.withValues(alpha: 0.10),
        child: Center(child: emptyGlyph),
      );
    }
    final model = context.read<LibraryModel>();
    Widget cell(Recipe r) => FutureBuilder<File?>(
          future: model.coverFor(r),
          builder: (_, snap) =>
              RecipeCover(file: snap.data, title: r.title, cacheWidth: 240),
        );
    const gap = SizedBox(width: 1, height: 1);
    return switch (rs.length) {
      1 => cell(rs[0]),
      2 => Row(children: [
          Expanded(child: cell(rs[0])),
          gap,
          Expanded(child: cell(rs[1])),
        ]),
      3 => Row(children: [
          Expanded(child: cell(rs[0])),
          gap,
          Expanded(
            child: Column(children: [
              Expanded(child: cell(rs[1])),
              gap,
              Expanded(child: cell(rs[2])),
            ]),
          ),
        ]),
      _ => Column(children: [
          Expanded(
            child: Row(children: [
              Expanded(child: cell(rs[0])),
              gap,
              Expanded(child: cell(rs[1])),
            ]),
          ),
          gap,
          Expanded(
            child: Row(children: [
              Expanded(child: cell(rs[2])),
              gap,
              Expanded(child: cell(rs[3])),
            ]),
          ),
        ]),
    };
  }
}

/// The door that makes a tag, drawn as an outline so it reads as an action
/// and not as a tag called "New tag" (the AddTagChip stance).
class _NewTile extends StatelessWidget {
  const _NewTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return InkWell(
      key: const Key('tag-tile-new'),
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: TagTileStrip.tileWidth,
        height: TagTileStrip.tileHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.6)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 22, color: scheme.primary),
            const SizedBox(height: 6),
            Text(
              'New tag',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
