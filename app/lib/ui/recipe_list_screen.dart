// Cookbook home (design 3d; empty state 4b), hosted as the shell's first tab.
// The shell owns import + share intake; this screen renders the library and
// hands its two doors back up: the FAB/empty-state import and the 5c drawer.

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
import 'tags_model.dart';
import 'widgets/skin.dart';

/// The built-ins. Sweet was deleted 2026-08-27: it guessed from a word list
/// and nothing ever let a recipe earn it. Quick survives because it is
/// computed from the recipe's own times, so it is honest and needs no tagging.
/// Everything past these two is a tag the user invented — [_tag] carries its
/// name.
enum _Filter { all, favorites, quick, tag }

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({
    super.key,
    required this.onImport,
    this.onOpenQueue,
  });

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
  _Filter _filter = _Filter.all;

  /// The selected user tag when [_filter] is [_Filter.tag]. Single-select in
  /// v1 — AND/OR across tags needs a different affordance and can follow.
  /// Session-only, like every other filter: one that survived a restart would
  /// make the cookbook look empty and broken.
  String? _tagName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LibraryModel>().rescan();
    });
  }

  static bool _isQuick(Recipe r) {
    final total = r.times?.totalMin ?? r.times?.cookMin;
    return total != null && total <= 30;
  }

  List<Recipe> _visible(List<Recipe> all) {
    final q = _query.trim().toLowerCase();
    return [
      for (final r in all)
        if ((q.isEmpty || r.title.toLowerCase().contains(q)) &&
            switch (_filter) {
              _Filter.all => true,
              _Filter.favorites => r.favorite,
              _Filter.quick => _isQuick(r),
              _Filter.tag => _tagName != null &&
                  r.tags.any((t) =>
                      RecipeTag.canonical(t) == RecipeTag.canonical(_tagName!)),
            })
          r
    ];
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<LibraryModel>();
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final recipes = _visible(model.recipes);
    final emptyBook = model.recipes.isEmpty && !model.loading;

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
                      sliver:
                          SliverToBoxAdapter(child: _queueStrip(theme, scheme)),
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
                            child: _searchBar(theme, scheme)),
                      ),
                      SliverToBoxAdapter(child: _filterRow(theme)),
                      if (recipes.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Text('Nothing matches — yet.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant)),
                            ),
                          ),
                        )
                      else if (context.watch<CookbookPrefs>().view ==
                          CookbookView.grid)
                        SliverPadding(
                          // 110 bottom: clears the 64dp bar hint + 16dp inset.
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              mainAxisExtent: 168,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, i) =>
                                  _RecipeCard(recipe: recipes[i]),
                              childCount: recipes.length,
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
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
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                            child: Text(
                              "${model.skipped} files in the folder couldn't be read",
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant),
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
                ? () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const DevGallery()))
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
                scheme.surface),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            if (moving > 0)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: scheme.primary),
              )
            else
              Icon(Icons.visibility_rounded, size: 18, color: scheme.primary),
            const SizedBox(width: 9),
            Expanded(
              child: Text(caption,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontSize: 12.5, height: 1.4)),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: scheme.onSurfaceVariant),
          ]),
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
                hintStyle: theme.textTheme.bodyLarge
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterRow(ThemeData theme) {
    Widget chip(_Filter f, String label, [IconData? icon]) {
      final selected = _filter == f && f != _Filter.tag;
      final scheme = context.scheme;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => setState(() => _filter = f),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.secondaryContainer
                  : scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon,
                      size: 15,
                      color: selected
                          ? scheme.onSecondaryContainer
                          : scheme.primary),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? scheme.onSecondaryContainer
                        : scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Chips bleed to the screen edge — the half-visible last chip is the
    // scroll cue; the view toggle stays pinned at the far end (Arnar's ask,
    // 2026-08-15: covers grid ⇄ compact list).
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20),
            child: Row(children: [
              chip(_Filter.all, 'All'),
              chip(_Filter.favorites, 'Favorites', Icons.favorite_rounded),
              if (kRecipeTagsEnabled) ...[
                // Quick is computed from the recipe's own times — no tagging
                // needed, so it stays a built-in (Arnar 2026-08-27).
                chip(_Filter.quick, 'Quick', Icons.bolt_rounded),
                // The user's own tags, in the order Settings puts them. Only
                // tags that are actually on a recipe appear: a filter that
                // can only ever return nothing is worse than no chip.
                for (final tag in _userTagChips())
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TagChip(
                      tag: tag,
                      selected: _filter == _Filter.tag &&
                          _tagName != null &&
                          RecipeTag.canonical(_tagName!) ==
                              RecipeTag.canonical(tag.name),
                      onTap: () => setState(() {
                        final same = _filter == _Filter.tag &&
                            _tagName != null &&
                            RecipeTag.canonical(_tagName!) ==
                                RecipeTag.canonical(tag.name);
                        // Tapping the selected tag clears back to All, so the
                        // row is never a trap you can't get out of.
                        _filter = same ? _Filter.all : _Filter.tag;
                        _tagName = same ? null : tag.name;
                      }),
                    ),
                  ),
              ],
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 20),
          child: _viewToggle(),
        ),
      ]),
    );
  }

  /// Decorated chips for every tag actually in use, ordered by the user's
  /// Settings order with any undecorated names after them.
  List<RecipeTag> _userTagChips() {
    final tags = context.watch<TagsModel>();
    final inUse = {
      for (final n in tags.namesInUse) RecipeTag.canonical(n): n
    };
    final out = <RecipeTag>[];
    final placed = <String>{};
    for (final t in tags.tags) {
      final key = RecipeTag.canonical(t.name);
      if (!inUse.containsKey(key)) continue;
      out.add(t);
      placed.add(key);
    }
    final rest = [
      for (final e in inUse.entries)
        if (!placed.contains(e.key)) e.value
    ]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return [...out, for (final n in rest) RecipeTag(name: n)];
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
          toList ? CookbookView.list : CookbookView.grid),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh, shape: BoxShape.circle),
        child: Icon(
            toList ? Icons.view_list_rounded : Icons.grid_view_rounded,
            size: 19,
            color: scheme.onSurfaceVariant,
            semanticLabel: toList ? 'Show as list' : 'Show as grid'),
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
            child: Icon(Icons.menu_book_rounded,
                size: 32, color: scheme.primary),
          ),
          const SizedBox(height: 18),
          Text('Your book is empty (for now)',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontSize: 21)),
          const SizedBox(height: 8),
          Text(
            'Somewhere in your camera roll, a pile of recipes is waiting to be rescued.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
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

/// Compact list form: title + meta, no cover decode — the fast scanning
/// view for big libraries. Favorites keep their heart (the tertiary moment).
class _RecipeRow extends StatelessWidget {
  const _RecipeRow({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final rb = context.rb;
    final meta = _RecipeCard.metaLine(recipe);
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => RecipeDetailScreen(recipe: recipe),
        )),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: rb.hairline),
            boxShadow: rb.cardShadow,
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontSize: 14, height: 1.3),
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11.5, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            if (recipe.favorite) ...[
              const SizedBox(width: 8),
              Icon(Icons.favorite_rounded, size: 16, color: scheme.tertiary),
            ],
          ]),
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe});

  final Recipe recipe;

  static String metaLine(Recipe r) {
    final parts = <String>[
      if (r.times?.raw != null)
        r.times!.raw!
      else if (r.times?.totalMin != null)
        '${r.times!.totalMin} min',
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
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => RecipeDetailScreen(recipe: recipe),
      )),
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
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontSize: 13.5, height: 1.3),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11.5,
                            color: context.scheme.onSurfaceVariant),
                      ),
                    ],
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
