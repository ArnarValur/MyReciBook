// Cookbook home (design 3d; empty state 4b), hosted as the shell's first tab.
// The shell owns import + share intake; this screen renders the library and
// hands its two doors back up: the FAB/empty-state import and the 5c drawer.

import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/recipe.dart';
import '../features.dart';
import 'library_model.dart';
import 'postalpha/dev_gallery.dart';
import 'recipe_detail_screen.dart';
import 'theme.dart';
import 'widgets/logo_mark.dart';
import 'widgets/skin.dart';

enum _Filter { all, favorites, quick, sweet }

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({
    super.key,
    required this.onImport,
  });

  /// The shell's import flow (3a sheet → review) — empty-state button target.
  final VoidCallback onImport;

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  String _query = '';
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LibraryModel>().rescan();
    });
  }

  static bool _isSweet(Recipe r) {
    const sweet = {'sweet', 'dessert', 'cake', 'baking', 'cookies'};
    return r.tags.any((t) => sweet.contains(t.toLowerCase()));
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
              _Filter.sweet => _isSweet(r),
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
                      else
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
      final selected = _filter == f;
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

    // Bleeds to the screen edge — the half-visible last chip is the scroll cue.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 12, 0, 0),
      child: Row(children: [
        chip(_Filter.all, 'All'),
        chip(_Filter.favorites, 'Favorites', Icons.favorite_rounded),
        // Quick/Sweet are drawn in 3d but nothing lets a recipe EARN the tag —
        // dead filters on real libraries (Arnar's pass, 2026-08-06). Hidden
        // behind kRecipeTagsEnabled until a tagging design exists; the
        // predicates above stay live for the flip.
        if (kRecipeTagsEnabled) ...[
          chip(_Filter.quick, 'Quick', Icons.bolt_rounded),
          chip(_Filter.sweet, 'Sweet', Icons.cake_rounded),
        ],
      ]),
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
