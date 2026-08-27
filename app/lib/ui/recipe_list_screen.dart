// Cookbook home (empty state 4b), hosted as the shell's first tab. The shell
// owns import + share intake; this screen renders the library and hands its
// two doors back up: the FAB/empty-state import and the 5c drawer.
//
// The shape (Arnar 2026-08-27, replacing design 3d's flat dump + tag chips):
// the chip row keeps only All and Favorites, and the user's tags are folded
// sections on a collapsible shelf like the pantry's — every tag at a glance,
// no horizontal scroll-hunt. Untagged recipes flow flat above the shelf; a
// recipe with several tags sits under each of them. Favorites and a search
// stay flat results — the shelf is the All view's shape, not a filter's. The
// fold persists through AppSettings.cookbookOpenSections, defaulting to
// everything open.

import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_settings.dart';
import '../domain/recipe.dart';
import '../features.dart';
import 'batch_model.dart';
import 'cookbook_prefs.dart';
import 'library_model.dart';
import 'postalpha/dev_gallery.dart';
import 'recipe_detail_screen.dart';
import 'theme.dart';
import 'widgets/collapsible_shelf.dart';
import 'widgets/logo_mark.dart';
import '../domain/recipe_tag.dart';
import 'tag_chip.dart';
import 'tags_model.dart';
import 'widgets/skin.dart';

/// The built-ins — and now the whole row. Sweet was deleted 2026-08-27
/// (guessed from a word list), Quick the same day (computed, but
/// administrable nowhere — Arnar: a chip no settings screen explains is a
/// bug, not a feature), and the user-tag chips left for the shelf sections
/// the same day too.
enum _Filter { all, favorites }

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

  /// The shelf sections the user has open. Null = they have never touched a
  /// header on this install, and every section starts open — a cookbook is
  /// small enough to show whole, unlike the pantry's 180 starter rows.
  /// Persisted, so the fold survives a restart. Stale ids from deleted tags
  /// sit in the stored set harmlessly: no section claims them.
  Set<String>? _expanded;

  /// Null under a bare pump (nothing provided it) — the shelf still works,
  /// it just forgets the fold between launches.
  AppSettings? _settings;

  @override
  void initState() {
    super.initState();
    try {
      _settings = context.read<AppSettings?>();
    } on ProviderNotFoundException {
      _settings = null;
    }
    _expanded = _settings?.cookbookOpenSections?.toSet();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LibraryModel>().rescan();
    });
  }

  List<Recipe> _visible(List<Recipe> all) {
    final q = _query.trim().toLowerCase();
    return [
      for (final r in all)
        if ((q.isEmpty || r.title.toLowerCase().contains(q)) &&
            (_filter == _Filter.all || r.favorite))
          r
    ];
  }

  /// Fold or unfold one tag section. The full open set is written every time,
  /// so what lands on disk is always the whole answer — no merge on read.
  Future<void> _toggleSection(String id, Set<String> open) async {
    final next = {...open};
    if (!next.remove(id)) next.add(id);
    setState(() => _expanded = next);
    try {
      await _settings?.setCookbookOpenSections(next.toList());
    } catch (_) {} // persistence best-effort — the shelf is already redrawn
  }

  /// One shelf section per user tag that is on at least one recipe, ordered
  /// alphabetically by display name. A recipe with several tags appears under
  /// each of them; a tag Settings knows but no recipe carries gets no section
  /// — a section that can only be empty is worse than none. Bodies build only
  /// while open (the shelf contract), so a folded tag costs no cards.
  List<ShelfSection> _tagSections(List<Recipe> all, bool grid) {
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
    final sections = <ShelfSection>[];
    for (final e in members.entries) {
      final decorated = tags.chipFor(spelling[e.key]!);
      final carriers = e.value;
      sections.add(ShelfSection(
        id: e.key,
        label: decorated.name,
        count: carriers.length,
        leading: TagBadge(tag: decorated, size: 22),
        builder: (_) => grid
            // Non-scrolling: the outer CustomScrollView owns the scroll, this
            // just lays the same cards two across inside the open fold.
            ? GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 4),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 168,
                ),
                children: [for (final r in carriers) _RecipeCard(recipe: r)],
              )
            : Column(
                children: [for (final r in carriers) _RecipeRow(recipe: r)]),
      ));
    }
    sections.sort(
        (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<LibraryModel>();
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final recipes = _visible(model.recipes);
    final emptyBook = model.recipes.isEmpty && !model.loading;
    final grid = context.watch<CookbookPrefs>().view == CookbookView.grid;

    // The All view with no search is the shelf shape; Favorites or a query
    // flattens back to plain results, like the pantry's search does.
    final shelfShape =
        kRecipeTagsEnabled && _filter == _Filter.all && _query.trim().isEmpty;
    final untagged = [
      for (final r in recipes)
        if (r.tags.isEmpty) r
    ];
    final sections =
        shelfShape ? _tagSections(recipes, grid) : const <ShelfSection>[];
    final open = _expanded ?? {for (final s in sections) s.id};

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
                      else if (shelfShape) ...[
                        // Untagged first, flat, no header and no fold — they
                        // have no section to live in, and an "Untagged"
                        // heading would nag anyone who never tags.
                        if (untagged.isNotEmpty)
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                            sliver: grid
                                ? SliverGrid(
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      mainAxisExtent: 168,
                                    ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, i) =>
                                          _RecipeCard(recipe: untagged[i]),
                                      childCount: untagged.length,
                                    ),
                                  )
                                : SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, i) =>
                                          _RecipeRow(recipe: untagged[i]),
                                      childCount: untagged.length,
                                    ),
                                  ),
                          ),
                        // 110 bottom: clears the 64dp bar hint + 16dp inset.
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                                EdgeInsets.fromLTRB(20, 12, 20, navBarClearance(context)),
                            child: CollapsibleShelf(
                              sections: sections,
                              expanded: open,
                              onToggle: (id) => _toggleSection(id, open),
                            ),
                          ),
                        ),
                      ] else if (grid)
                        SliverPadding(
                          // 110 bottom: clears the 64dp bar hint + 16dp inset.
                          padding: EdgeInsets.fromLTRB(20, 12, 20, navBarClearance(context)),
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
                          padding: EdgeInsets.fromLTRB(20, 12, 20, navBarClearance(context)),
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
                            padding: EdgeInsets.fromLTRB(20, 0, 20, navBarClearance(context)),
                            child: Text(
                              "${model.skipped} file${model.skipped == 1 ? '' : 's'} in the folder couldn't be read",
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
                  // Only the heart carries an icon, and the heart is the
                  // tertiary moment everywhere — red like the rows', in both
                  // states, never the old unselected primary blue.
                  Icon(icon, size: 15, color: scheme.tertiary),
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

    // Two chips, no scroll — the user tags moved onto the shelf below. The
    // view toggle stays pinned at the far end (Arnar's ask, 2026-08-15:
    // covers grid ⇄ compact list).
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(children: [
        chip(_Filter.all, 'All'),
        chip(_Filter.favorites, 'Favorites', Icons.favorite_rounded),
        const Spacer(),
        _viewToggle(),
      ]),
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

/// A recipe's tags in the order Settings puts them, with anything undecorated
/// after. Without this the badges follow the order the tags happen to sit in
/// the file, and two recipes with the same tags would show them differently.
List<String> _orderTags(BuildContext context, List<String> tags) {
  final model = context.read<TagsModel>();
  final rank = {
    for (var i = 0; i < model.tags.length; i++)
      RecipeTag.canonical(model.tags[i].name): i
  };
  final sorted = [...tags]..sort((a, b) {
      final ra = rank[RecipeTag.canonical(a)] ?? 1 << 30;
      final rb = rank[RecipeTag.canonical(b)] ?? 1 << 30;
      return ra != rb ? ra.compareTo(rb) : a.toLowerCase().compareTo(b.toLowerCase());
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
