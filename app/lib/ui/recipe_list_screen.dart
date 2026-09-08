// Cookbook home (empty state 4b), hosted as the shell's first tab. The shell
// owns import + share intake; this screen renders the library and hands its
// two doors back up: the FAB/empty-state import and the 5c drawer.
//
// The shape (Direction A, Arnar 2026-09-03, replacing the folded tag shelf
// that stacked untagged recipes above tagged ones and filed a recipe once per
// tag): ONE grid, always. Above it a strip of tiles — Favorites, then the
// user's tags — each showing the covers of the recipes inside. Tapping a tile
// narrows the same grid in place; the header names the selection with its
// chip, its count and an "Edit tag" door. Nothing is folded, nothing is filed
// twice. Search narrows within the selection. The selection is session-only:
// a filter that survived a restart made the cookbook look empty and broken.

import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/recipe.dart';
import '../features.dart';
import 'batch_model.dart';
import 'cookbook_prefs.dart';
import 'library_model.dart';
import 'postalpha/dev_gallery.dart';
import 'recipe_detail_screen.dart';
import 'theme.dart';
import 'widgets/logo_mark.dart';
import '../domain/recipe_tag.dart';
import 'tag_chip.dart';
import 'tag_editor_screen.dart';
import 'tag_tiles.dart';
import 'tags_model.dart';
import 'widgets/skin.dart';


class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key, required this.onImport, this.onOpenQueue});

  /// The shell's import flow (3a sheet → review) — empty-state button target.
  final VoidCallback onImport;

  /// Reopens the pushed batch-queue route. Since the queue tab retired
  /// (2026-08-15) the attention strip below is the way back to a batch
  /// that is still moving or wants eyes.
  final VoidCallback? onOpenQueue;

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  String _query = '';

  /// What the grid is narrowed to: null = every recipe, [kFavoritesTileId] =
  /// favourites, otherwise a canonical tag name. Session-only on purpose.
  String? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LibraryModel>().rescan();
    });
  }

  List<Recipe> _visible(List<Recipe> all, String? selected) {
    final q = _query.trim().toLowerCase();
    bool inSelection(Recipe r) {
      if (selected == null) return true;
      if (selected == kFavoritesTileId) return r.favorite;
      return r.tags.any((t) => RecipeTag.canonical(t) == selected);
    }

    return [
      for (final r in all)
        if ((q.isEmpty || r.title.toLowerCase().contains(q)) && inSelection(r))
          r,
    ];
  }

  /// The strip: Favorites, then every decorated tag in tags.json order (even
  /// one nothing carries yet — the user just made it and wants to see it),
  /// then names the library carries that tags.json says nothing about,
  /// alphabetical. A recipe with several tags is counted under each; the
  /// grid itself never files it twice.
  List<TagTileData> _tiles(List<Recipe> all) {
    final tags = context.watch<TagsModel>();
    final members = <String, List<Recipe>>{};
    final spelling = <String, String>{};
    for (final r in all) {
      final seen = <String>{};
      for (final t in r.tags) {
        final key = RecipeTag.canonical(t);
        if (!seen.add(key)) continue; // hand-edited duplicate casing
        members.putIfAbsent(key, () => []).add(r);
        spelling.putIfAbsent(key, () => t);
      }
    }
    final out = <TagTileData>[
      TagTileData(
        id: kFavoritesTileId,
        label: 'Favorites',
        recipes: [
          for (final r in all)
            if (r.favorite) r,
        ],
      ),
    ];
    if (!kRecipeTagsEnabled) return out;
    final done = <String>{};
    for (final t in tags.tags) {
      final key = RecipeTag.canonical(t.name);
      done.add(key);
      out.add(TagTileData(
        id: key,
        label: t.name,
        tag: t,
        recipes: members[key] ?? const [],
      ));
    }
    final rest = [
      for (final key in members.keys)
        if (!done.contains(key)) key,
    ]..sort((a, b) =>
        spelling[a]!.toLowerCase().compareTo(spelling[b]!.toLowerCase()));
    for (final key in rest) {
      final name = spelling[key]!;
      out.add(TagTileData(
        id: key,
        label: name,
        tag: RecipeTag(name: name),
        recipes: members[key]!,
      ));
    }
    return out;
  }

  /// The sheet, for a tile. A decorated tag edits in place; a name only the
  /// library knows adopts (gains a look, keeps its name). A rename is
  /// followed; a delete leaves a selection nothing claims, which build reads
  /// as "everything".
  Future<void> _editTag(TagTileData tile) async {
    final tags = context.read<TagsModel>();
    final decorated = tags.byName(tile.label);
    final name = await showTagEditor(
      context,
      initial: decorated ?? RecipeTag(name: tile.label),
      adopting: decorated == null,
    );
    if (!mounted || name == null) return;
    if (_selected == tile.id) {
      setState(() => _selected = RecipeTag.canonical(name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<LibraryModel>();
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final tiles = _tiles(model.recipes);
    // A selection nothing claims any more (the tag was deleted, or renamed
    // away under us) reads as "everything", never as an empty book.
    final selected =
        _selected == null || tiles.any((t) => t.id == _selected)
            ? _selected
            : null;
    final recipes = _visible(model.recipes, selected);
    final emptyBook = model.recipes.isEmpty && !model.loading;
    final grid = context.watch<CookbookPrefs>().view == CookbookView.grid;

    return Scaffold(
      body: SafeArea(
        bottom: false, // content scrolls under the shell's glass bar
        child: model.loading && model.recipes.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => context.read<LibraryModel>().rescan(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      sliver: SliverToBoxAdapter(child: _header(theme, scheme)),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: _queueStrip(theme, scheme),
                      ),
                    ),
                    if (emptyBook)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _emptyBook(theme, scheme),
                      )
                    else ...[
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        sliver: SliverToBoxAdapter(
                          child: _searchBar(theme, scheme),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: TagTileStrip(
                            tiles: tiles,
                            selectedId: selected,
                            onSelect: (id) => setState(() => _selected = id),
                            onEdit: _editTag,
                            onNew: () => showTagEditor(context),
                            showNew: kRecipeTagsEnabled,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _gridHeader(
                            theme, tiles, selected, recipes.length),
                      ),
                      if (recipes.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                'Nothing matches — yet.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        )
                      else if (grid)
                        SliverPadding(
                          // 110 bottom: clears the 64dp bar hint + 16dp inset.
                          padding: EdgeInsets.fromLTRB(
                            20,
                            12,
                            20,
                            navBarClearance(context),
                          ),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  mainAxisExtent: 172,
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (context, i) => _RecipeCard(recipe: recipes[i]),
                              childCount: recipes.length,
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            12,
                            20,
                            navBarClearance(context),
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, i) => _RecipeRow(recipe: recipes[i]),
                              childCount: recipes.length,
                            ),
                          ),
                        ),
                      if (model.skipped > 0)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              20,
                              0,
                              20,
                              navBarClearance(context),
                            ),
                            child: Text(
                              "${model.skipped} file${model.skipped == 1 ? '' : 's'} in the folder couldn't be read",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _header(ThemeData theme, ColorScheme scheme) {
    return Row(
      children: [
        LogoMark(size: 28, color: scheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            // Debug-only door to the post-alpha design previews.
            onLongPress: kDebugMode
                ? () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const DevGallery()),
                  )
                : null,
            child: Text(
              'MyReciBook',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.primary,
                letterSpacing: -0.46,
              ),
            ),
          ),
        ),
        // Wordmark only — the drawer (and its menu button) was removed
        // 2026-08-06; sync status lives on the Settings storage row (6a).
      ],
    );
  }

  /// Non-blocking batch receipt (3b's promise kept without its tab): visible
  /// only while the queue is moving or holding items that want eyes, gone
  /// without residue once everything saved. Tap = back into the queue route.
  Widget _queueStrip(ThemeData theme, ColorScheme scheme) {
    final batch = context.watch<BatchModel?>();
    if (batch == null) return const SizedBox.shrink();
    final moving = batch.remaining;
    final eyes = batch.attention;
    if (moving + eyes == 0) return const SizedBox.shrink();

    final caption = [
      if (moving > 0) 'Rescuing $moving…',
      if (eyes > 0) '$eyes need${eyes == 1 ? 's' : ''} your eyes',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: InkWell(
        key: const Key('queue-strip'),
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onOpenQueue,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              scheme.secondaryContainer.withValues(alpha: 0.4),
              scheme.surface,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              if (moving > 0)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary,
                  ),
                )
              else
                Icon(Icons.visibility_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  caption,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchBar(ThemeData theme, ColorScheme scheme) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              key: const Key('cookbook-search'),
              onChanged: (v) => setState(() => _query = v),
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Search your cookbook…',
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The row above the grid. Nothing selected: "ALL RECIPES · N". A tile
  /// selected: its chip with a × to clear, the count, and — for a tag, never
  /// for Favorites — the door to the tag sheet. The view toggle stays pinned
  /// at the far end (Arnar's ask, 2026-08-15: covers grid ⇄ compact list).
  Widget _gridHeader(
    ThemeData theme,
    List<TagTileData> tiles,
    String? selected,
    int count,
  ) {
    final scheme = context.scheme;
    final tile =
        selected == null ? null : tiles.firstWhere((t) => t.id == selected);
    void clear() => setState(() => _selected = null);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          if (tile == null)
            SectionLabel('All recipes · $count')
          else ...[
            if (tile.isFavorites)
              _FavoritesChip(onClear: clear)
            else
              TagChip(tag: tile.tag!, selected: true, onDeleted: clear),
            const SizedBox(width: 10),
            Text(
              '$count recipe${count == 1 ? '' : 's'}',
              key: const Key('selection-count'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (!tile.isFavorites)
              TextButton(
                key: const Key('edit-tag-button'),
                onPressed: () => _editTag(tile),
                child: const Text('Edit tag'),
              ),
          ],
          const Spacer(),
          _viewToggle(),
        ],
      ),
    );
  }

  /// Grid ⇄ list switch. Shows the layout a tap takes you TO (files-app
  /// convention); the choice persists through CookbookPrefs.
  Widget _viewToggle() {
    final prefs = context.watch<CookbookPrefs>();
    final scheme = context.scheme;
    final toList = prefs.view == CookbookView.grid;
    return InkWell(
      key: const Key('view-toggle'),
      customBorder: const CircleBorder(),
      onTap: () => context.read<CookbookPrefs>().setView(
        toList ? CookbookView.list : CookbookView.grid,
      ),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          shape: BoxShape.circle,
        ),
        child: Icon(
          toList ? Icons.view_list_rounded : Icons.grid_view_rounded,
          size: 19,
          color: scheme.onSurfaceVariant,
          semanticLabel: toList ? 'Show as list' : 'Show as grid',
        ),
      ),
    );
  }

  Widget _emptyBook(ThemeData theme, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.menu_book_rounded,
              size: 32,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Your book is empty (for now)',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontSize: 21),
          ),
          const SizedBox(height: 8),
          Text(
            'Somewhere in your camera roll, a pile of recipes is waiting to be rescued.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: widget.onImport,
            icon: const Icon(Icons.add),
            label: const Text('Rescue your first recipe'),
          ),
        ],
      ),
    );
  }
}

/// A recipe's tags in the order Settings puts them, with anything undecorated
/// after. Without this the badges follow the order the tags happen to sit in
/// the file, and two recipes with the same tags would show them differently.
List<String> _orderTags(BuildContext context, List<String> tags) {
  final model = context.read<TagsModel>();
  final rank = {
    for (var i = 0; i < model.tags.length; i++)
      RecipeTag.canonical(model.tags[i].name): i,
  };
  final sorted = [...tags]
    ..sort((a, b) {
      final ra = rank[RecipeTag.canonical(a)] ?? 1 << 30;
      final rb = rank[RecipeTag.canonical(b)] ?? 1 << 30;
      return ra != rb
          ? ra.compareTo(rb)
          : a.toLowerCase().compareTo(b.toLowerCase());
    });
  return sorted;
}

/// Compact list form: a 38px cover thumb + title + meta — the fast scanning
/// view for big libraries. The thumb decodes small (cacheWidth, the pantry
/// row's idiom), so a long list never holds full screenshots in memory.
/// Favorites keep their heart (the tertiary moment).
class _RecipeRow extends StatelessWidget {
  const _RecipeRow({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final rb = context.rb;
    final model = context.read<LibraryModel>();
    final meta = _RecipeCard.metaLine(recipe);
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => RecipeDetailScreen(recipe: recipe),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: rb.hairline),
            boxShadow: rb.cardShadow,
          ),
          child: Row(
            children: [
              // Coverless recipes get the mini RecipeCover instead of a blank
              // box, so a recipe keeps its title-hashed colour identity in
              // both views.
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: FutureBuilder<File?>(
                    future: model.coverFor(recipe),
                    builder: (_, snap) {
                      final file = snap.data;
                      if (file == null) {
                        return RecipeCover(file: null, title: recipe.title);
                      }
                      return Image.file(
                        file,
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                        cacheWidth: 114,
                        errorBuilder: (_, _, _) =>
                            RecipeCover(file: null, title: recipe.title),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Tags, then the heart. Badges rather than chips: the row's job
              // is the title, and a glyph plus its colour says which tags are
              // on this recipe without spending any of that width on words.
              if (kRecipeTagsEnabled && recipe.tags.isNotEmpty) ...[
                const SizedBox(width: 8),
                TagBadgeRow(
                  names: _orderTags(context, recipe.tags),
                  decorate: context.watch<TagsModel>().chipFor,
                ),
              ],
              if (recipe.favorite) ...[
                const SizedBox(width: 8),
                Icon(Icons.favorite_rounded, size: 16, color: scheme.tertiary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe});

  final Recipe recipe;

  static String metaLine(Recipe r) {
    // Total first: cards want "8 hr 15 min", not the import's full
    // "Prep Time: 30 mins, Refrigerate Time: 4 hrs…" run-on. Raw is the
    // fallback for files with no parsed number at all ("ca. 1 time").
    final time = RecipeTimes.fmtMin(r.times?.totalMin) ?? r.times?.raw;
    final parts = <String>[
      ?time,
      if (r.servings?.raw != null)
        r.servings!.raw!
      else if (r.servings?.amount != null)
        '${r.servings!.amount} servings',
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rb = context.rb;
    final meta = metaLine(recipe);
    final model = context.read<LibraryModel>();
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RecipeDetailScreen(recipe: recipe),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: rb.hairline),
          boxShadow: rb.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 106,
                width: double.infinity,
                child: FutureBuilder<File?>(
                  future: model.coverFor(recipe),
                  builder: (_, snap) =>
                      RecipeCover(file: snap.data, title: recipe.title),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(11, 9, 11, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 13.5,
                        height: 1.3,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11.5,
                          color: context.scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    // No badges here — the cover card's 168dp is spent on the
                    // photo and title, and badges only ever peeked out as a
                    // clipped sliver (Arnar 2026-08-27). List view carries them.
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The selected-Favorites chip: the old filter chip's skin (secondary
/// container, heart in tertiary) plus the × that clears the selection.
class _FavoritesChip extends StatelessWidget {
  const _FavoritesChip({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded, size: 15, color: scheme.tertiary),
          const SizedBox(width: 5),
          Text(
            'Favorites',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSecondaryContainer,
                ),
          ),
          const SizedBox(width: 4),
          InkWell(
            key: const Key('clear-selection'),
            customBorder: const CircleBorder(),
            onTap: onClear,
            child: Icon(Icons.close_rounded,
                size: 14, color: scheme.onSecondaryContainer),
          ),
        ],
      ),
    );
  }
}
