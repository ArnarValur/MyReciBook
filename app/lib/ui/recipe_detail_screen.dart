// Recipe detail (design 3e): hero cover with provenance flip, favorite heart
// (the schema's user-owned bool), ingredient check-off (ephemeral view state),
// notes editing post-save (D6) + delete. Servings render as a static chip —
// the stepper waits for the rescale engine (post-alpha).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/recipe.dart';
import 'cook_mode_screen.dart';
import 'grocery_model.dart';
import 'import_review_screen.dart';
import 'library_model.dart';
import 'photo_sources.dart';
import 'theme.dart';
import 'widgets/skin.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipe});

  final Recipe recipe;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Recipe _recipe = widget.recipe;
  late final TextEditingController _notes =
      TextEditingController(text: widget.recipe.notes ?? '');
  final Set<int> _checked = {}; // kitchen-session state, not persisted
  bool _showOriginal = false;
  List<File> _originals = const [];
  File? _cover;

  @override
  void initState() {
    super.initState();
    _loadOriginals();
    _loadCover();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadOriginals() async {
    final model = context.read<LibraryModel>();
    final files = <File>[];
    for (final ref in _recipe.source.originalImages ?? const <String>[]) {
      try {
        final f = await model.imageFor(ref);
        if (f != null) files.add(f);
      } catch (_) {} // lost grant: detail still renders, list owns re-pick (§7)
    }
    if (mounted) setState(() => _originals = files);
  }

  Future<void> _loadCover() async {
    File? file;
    try {
      file = await context.read<LibraryModel>().coverFor(_recipe);
    } catch (_) {} // lost grant: the drawn tile stands in, list owns re-pick
    if (mounted) setState(() => _cover = file);
  }

  Future<void> _persist(Recipe next, {String? confirmation}) async {
    // Empty cachedImages keeps original_images intact (store contract).
    final Recipe saved;
    try {
      saved = await context.read<LibraryModel>().saveImported(next, const []);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      return;
    }
    if (!mounted) return;
    setState(() => _recipe = saved);
    if (confirmation != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(confirmation)));
    }
  }

  /// Cover door (Arnar 2026-08-10). Own photo first — that is the picture he
  /// actually wants on the card; the screenshots are the fallback, not the
  /// default. Every branch writes into the user's own folder, so covers sync
  /// and survive a reinstall like the recipes do.
  Future<void> _pickCover() async {
    final photos = context.read<PhotoSources>();
    final model = context.read<LibraryModel>();
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (photos.camera != null)
              ListTile(
                key: const Key('cover-camera'),
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Take a photo'),
                subtitle: const Text('Snap the dish you just cooked'),
                onTap: () => Navigator.of(sheet).pop('camera'),
              ),
            ListTile(
              key: const Key('cover-gallery'),
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(sheet).pop('gallery'),
            ),
            if (_originals.isNotEmpty)
              ListTile(
                key: const Key('cover-screenshot'),
                leading: const Icon(Icons.image_rounded),
                title: const Text('Use a screenshot'),
                subtitle: Text(_originals.length == 1
                    ? 'The original you imported'
                    : 'Pick one of ${_originals.length} originals'),
                onTap: () => Navigator.of(sheet).pop('screenshot'),
              ),
            if (_recipe.cover != null)
              ListTile(
                key: const Key('cover-remove'),
                leading: const Icon(Icons.hide_image_rounded),
                title: const Text('Remove cover'),
                onTap: () => Navigator.of(sheet).pop('remove'),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;

    String? ref;
    File? photo;
    switch (choice) {
      case 'camera':
        photo = await photos.pickOne(photos.camera!);
      case 'gallery':
        photo = await photos.pickOne(photos.gallery);
      case 'screenshot':
        ref = await _chooseOriginal();
      case 'remove':
        break;
    }
    // Backing out of the camera/gallery/grid must leave the cover alone —
    // only 'remove' clears it.
    if (!mounted || (choice != 'remove' && photo == null && ref == null)) return;

    try {
      final saved = choice == 'remove'
          ? await model.clearCover(_recipe)
          : await model.setCover(_recipe, photo: photo, ref: ref);
      if (!mounted) return;
      setState(() {
        _recipe = saved;
        _showOriginal = false;
      });
      await _loadCover();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Cover not saved: $e')));
    }
  }

  /// One screenshot → straight through; several → a grid to choose from.
  Future<String?> _chooseOriginal() async {
    final refs = _recipe.source.originalImages ?? const <String>[];
    if (refs.length <= 1) return refs.firstOrNull;
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.72,
            children: [
              for (var i = 0; i < refs.length && i < _originals.length; i++)
                InkWell(
                  onTap: () => Navigator.of(sheet).pop(refs[i]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CoverImage(_originals[i]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveNotes() =>
      _persist(_recipe.copyWith(notes: _notes.text), confirmation: 'Notes saved');

  Future<void> _toggleFavorite() =>
      _persist(_recipe.copyWith(favorite: !_recipe.favorite));

  // 3e footer: one-tap whole-recipe add; when on-list, the same tap subtracts
  // the recipe's contribution again. Snackbar copy undesigned — flagged.
  Future<void> _toggleGrocery() async {
    final grocery = context.read<GroceryModel>();
    final String msg;
    if (grocery.isOnList(_recipe.id)) {
      await grocery.removeRecipe(_recipe.id);
      msg = 'Removed from grocery';
    } else {
      final res = await grocery.addRecipe(_recipe);
      // addedCount == 0: every line hit a checked-off row, nothing was added
      // and the recipe is NOT on the list — never claim "Added".
      msg = res.addedCount == 0
          ? 'Nothing added — everything is already checked off'
          : res.excludedCheckedCount > 0
              ? 'Added to grocery — checked-off items skipped'
              : 'Added to grocery';
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // D6 as amended: the saved recipe reopens in the review screen and saves
  // back. If the recipe feeds the grocery list, its contributions re-sync
  // (the list is a view, never a snapshot — §6.3); the receipt banner on the
  // grocery tab carries the change notice.
  Future<void> _edit() async {
    final saved = await Navigator.of(context).push<Recipe>(MaterialPageRoute(
      builder: (_) =>
          ImportReviewScreen.edit(recipe: _recipe, originals: _originals),
    ));
    if (saved == null || !mounted) return;
    setState(() => _recipe = saved);
    final grocery = context.read<GroceryModel>();
    if (grocery.isOnList(saved.id)) await grocery.syncRecipe(saved);
  }

  Future<void> _delete() async {
    // The canonical 6f destructive shape; copy unchanged (nothing survives a
    // delete, so the body states plainly what is removed).
    final ok = await showDestructiveConfirm(
      context,
      title: 'Delete recipe?',
      body: '"${_recipe.title}" and its images will be removed.',
      verb: 'Delete',
    );
    if (!ok || !mounted) return;
    await context.read<LibraryModel>().delete(_recipe.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final originals = _originals;

    return Scaffold(
      // Collapsing hero (Arnar's S21 pass, 2026-08-06): the cover must NOT
      // stay pinned while reading — it scrolls away and only the slim action
      // bar stays, giving the height back to the ingredient list. The
      // grocery/cook footer keeps its fixed 3e position below the scroll.
      body: SafeArea(
        top: false, // the SliverAppBar owns the status-bar inset
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  _heroSliver(scheme, originals),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    sliver: SliverList.list(
                      children: [
                  Text(_recipe.title, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_recipe.times?.raw != null)
                        MetaChip(
                            icon: Icons.schedule_rounded,
                            label: _recipe.times!.raw!),
                      if (_recipe.servings?.raw != null)
                        MetaChip(
                            icon: Icons.restaurant_rounded,
                            label: _recipe.servings!.raw!),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const SectionLabel('Ingredients'),
                  const SizedBox(height: 8),
                  TokenCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    child: Column(children: _ingredientRows(theme, scheme)),
                  ),
                  const SizedBox(height: 14),
                  const SectionLabel('Steps'),
                  const SizedBox(height: 8),
                  TokenCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var n = 0; n < _recipe.steps.length; n++)
                          Padding(
                            padding: EdgeInsets.only(top: n == 0 ? 0 : 8),
                            child: Text.rich(
                              TextSpan(children: [
                                TextSpan(
                                  text: '${n + 1}  ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: scheme.primary),
                                ),
                                TextSpan(text: _recipe.steps[n].raw),
                              ]),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.55,
                                color: n == 0
                                    ? scheme.onSurface
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const SectionLabel('Notes'),
                  const SizedBox(height: 8),
                  TokenCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          key: const Key('notes-field'),
                          controller: _notes,
                          maxLines: null,
                          style: theme.textTheme.bodyMedium,
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: 'Your notes',
                            hintStyle: theme.textTheme.bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _saveNotes,
                            child: const Text('Save notes'),
                          ),
                        ),
                      ],
                    ),
                  ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_recipe.steps.isNotEmpty || _recipe.ingredients.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    if (_recipe.ingredients.isNotEmpty)
                      if (_recipe.steps.isEmpty)
                        Expanded(child: _groceryButton())
                      else
                        _groceryButton(),
                    if (_recipe.ingredients.isNotEmpty &&
                        _recipe.steps.isNotEmpty)
                      const SizedBox(width: 10),
                    if (_recipe.steps.isNotEmpty)
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () =>
                              Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) => CookModeScreen(recipe: _recipe),
                          )),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Start cooking'),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _groceryButton() => FilledButton.tonalIcon(
        onPressed: _toggleGrocery,
        icon: Icon(context.watch<GroceryModel>().isOnList(_recipe.id)
            ? Icons.playlist_add_check_rounded
            : Icons.playlist_add_rounded),
        label: const Text('Grocery'),
      );

  /// Collapsing hero: expanded it is the 210px cover (tap → originals
  /// viewer, swap pill bottom-right, cover door bottom-left); scrolled, the
  /// image parallaxes away and only the pinned toolbar with
  /// back/edit/favorite/delete remains.
  Widget _heroSliver(ColorScheme scheme, List<File> originals) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 210,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leadingWidth: 16 + 36 + 8,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(
          child: GlassCircle(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back',
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
      actions: [
        GlassCircle(
          key: const Key('edit-button'),
          icon: Icons.edit_rounded,
          tooltip: 'Edit',
          onTap: _edit,
        ),
        const SizedBox(width: 8),
        GlassCircle(
          key: const Key('favorite-button'),
          icon: _recipe.favorite
              ? Icons.favorite_rounded
              : Icons.favorite_outline_rounded,
          filled: _recipe.favorite,
          iconColor: _recipe.favorite
              ? scheme.tertiaryContainer
              : scheme.onSurface,
          tooltip: _recipe.favorite ? 'Remove favorite' : 'Favorite',
          onTap: _toggleFavorite,
        ),
        const SizedBox(width: 8),
        GlassCircle(
            icon: Icons.delete_rounded, tooltip: 'Delete', onTap: _delete),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: originals.isEmpty
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => OriginalsViewer(images: originals))),
              // The flip now swaps two different pictures: the chosen cover
              // (or its drawn stand-in) and the screenshot it came from.
              child: _showOriginal
                  ? ColoredBox(
                      color: scheme.surfaceContainerLow,
                      child: CoverImage(originals.firstOrNull,
                          fit: BoxFit.contain))
                  : RecipeCover(file: _cover, title: _recipe.title),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: GlassPill(
                key: const Key('cover-door'),
                icon: Icons.add_photo_alternate_rounded,
                label: _recipe.cover == null ? 'add cover' : 'cover',
                onTap: _pickCover,
              ),
            ),
            if (originals.isNotEmpty)
              Positioned(
                bottom: 12,
                right: 12,
                child: GlassPill(
                  icon: Icons.swap_horiz_rounded,
                  label: _showOriginal ? 'cover' : 'original',
                  onTap: () => setState(() => _showOriginal = !_showOriginal),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _ingredientRows(ThemeData theme, ColorScheme scheme) {
    final rows = <Widget>[];
    String? prevGroup;
    final rb = context.rb;
    for (var i = 0; i < _recipe.ingredients.length; i++) {
      final ing = _recipe.ingredients[i];
      if (ing.group != null && ing.group != prevGroup) {
        rows.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 2),
          child: Align(
              alignment: Alignment.centerLeft, child: SectionLabel(ing.group!)),
        ));
      }
      prevGroup = ing.group;
      final checked = _checked.contains(i);
      final last = i == _recipe.ingredients.length - 1;
      rows.add(InkWell(
        onTap: () => setState(
            () => checked ? _checked.remove(i) : _checked.add(i)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: last
              ? null
              : BoxDecoration(
                  border: Border(bottom: BorderSide(color: rb.separator))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: checked ? scheme.primary : null,
                  border: checked
                      ? null
                      : Border.all(color: scheme.outline, width: 2),
                ),
                child: checked
                    ? Icon(Icons.check_rounded,
                        size: 13, color: scheme.onPrimary)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  qtyBoldSpan(
                    ing.raw,
                    theme.textTheme.bodyMedium?.copyWith(
                      decoration:
                          checked ? TextDecoration.lineThrough : null,
                      color: checked ? scheme.onSurfaceVariant : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ));
    }
    return rows;
  }
}
