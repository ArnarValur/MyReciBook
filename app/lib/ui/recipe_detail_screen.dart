// Recipe detail (design 3e): hero cover with provenance flip, favorite heart
// (the schema's user-owned bool), ingredient check-off (ephemeral view state),
// notes editing post-save (D6) + delete. Servings render as a static chip —
// the stepper waits for the rescale engine (post-alpha).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../data/drive_docs.dart';
import '../data/recipe_pdf.dart';
import '../domain/product.dart';
import '../domain/nutrient_display.dart';
import '../domain/recipe.dart';
import '../domain/recipe_nutrition.dart';
import '../domain/units.dart';
import '../features.dart';
import 'cook_mode_screen.dart';
import 'grocery_model.dart';
import 'library_model.dart';
import 'manual_entry_screen.dart';
import 'pantry/pantry_model.dart';
import 'photo_sources.dart';
import 'storage_model.dart';
import 'theme.dart';
import 'units_model.dart';
import 'widgets/product_picker_sheet.dart';
import '../domain/recipe_tag.dart';
import 'tag_chip.dart';
import 'tags_model.dart';
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
    // Linked-row labels need the pantry list; cheap and cached after boot.
    if (kPantryEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<PantryModel>().ensureLoaded();
      });
    }
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

  /// The recipe's own tags, plus the one door that adds them. Each chip's ×
  /// takes the tag off THIS recipe; it never deletes the tag itself — that
  /// lives in Settings, behind a confirm.
  Widget _tagRow() {
    final tags = context.watch<TagsModel>();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final name in _recipe.tags)
          TagChip(
            tag: tags.chipFor(name),
            height: 32,
            onDeleted: () => _toggleTag(name),
          ),
        _AddTagChip(onTap: _openTagSheet),
      ],
    );
  }

  Future<void> _toggleTag(String name) async {
    final saved = await context.read<TagsModel>().toggleOn(_recipe, name);
    if (mounted) setState(() => _recipe = saved);
  }

  /// Pantry's "+ Category" sheet, with the user's tags as the source list —
  /// the same shape, so nothing new has to be learned.
  Future<void> _openTagSheet() async {
    final model = context.read<TagsModel>();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ChangeNotifierProvider<TagsModel>.value(
        value: model,
        child: StatefulBuilder(builder: (ctx, setSheet) {
          // Every tag that exists anywhere: decorated ones first, then names
          // only the library knows about.
          final decorated = model.tags;
          final extra = model.undecoratedNames;
          final empty = decorated.isEmpty && extra.isEmpty;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Tags'),
                  const SizedBox(height: 10),
                  if (empty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No tags yet. Make one in Settings → Tags, then come '
                        'back and put it on this recipe.',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            height: 1.5,
                            color: ctx.scheme.onSurfaceVariant),
                      ),
                    )
                  else
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final tag in [
                        ...decorated,
                        for (final n in extra) RecipeTag(name: n),
                      ])
                        TagChip(
                          tag: tag,
                          selected: _recipe.tags.any((t) =>
                              RecipeTag.canonical(t) ==
                              RecipeTag.canonical(tag.name)),
                          onTap: () async {
                            await _toggleTag(tag.name);
                            setSheet(() {});
                          },
                        ),
                    ]),
                ],
              ),
            ),
          );
        }),
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

  // The saved recipe reopens in the row editor (one editor for New and Edit,
  // 2026-08-20 — pantry links and parse corrections work there too) and
  // saves back in place. If the recipe feeds the grocery list, its
  // contributions re-sync (the list is a view, never a snapshot — §6.3);
  // the receipt banner on the grocery tab carries the change notice.
  /// Recipe → PDF → the system share sheet (export track D1). Built from the
  /// SAME display strings the screen shows, so the units toggle and
  /// pantry-linked product names carry into the page exactly as rendered.
  /// Android's sheet gives mail, print and Save to Drive for free.
  Future<void> _sharePdf() async {
    final messenger = ScaffoldMessenger.of(context);
    final data = await _exportData();
    try {
      final bytes = await buildRecipePdf(data);
      await Printing.sharePdf(bytes: bytes, filename: '${_pdfName()}.pdf');
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text("Couldn't build the PDF — try again")));
    }
  }

  /// The export model both doors read: PDF and Google Docs print the same
  /// content, so a field can never appear in one and go missing from the
  /// other.
  Future<RecipePdfData> _exportData() async {
    final system = context.read<UnitsModel>().system;
    final pantryProducts = kPantryEnabled
        ? context.read<PantryModel>().products
        : const <Product>[];

    final lines = <String>[];
    final groups = <int, String>{};
    String? prevGroup;
    for (final ing in _recipe.ingredients) {
      if (ing.group != null && ing.group != prevGroup) {
        groups[lines.length] = ing.group!;
      }
      prevGroup = ing.group;
      Product? linked;
      if (ing.productRef != null) {
        for (final p in pantryProducts) {
          if (p.id == ing.productRef) {
            linked = p;
            break;
          }
        }
      }
      lines.add(convertUnits(
          linked == null ? ing.raw : linkedIngredientLine(ing, linked.name),
          system));
    }

    Uint8List? coverBytes;
    final coverFile = _cover;
    if (coverFile != null && coverFile.existsSync()) {
      coverBytes = await coverFile.readAsBytes();
    }

    final url = _recipe.source.url;

    // Nutrition rides along only when there is something honest to say: at
    // least one covered ingredient, and words worth printing. The coverage
    // note travels with it — a printed page cannot be tapped for the caveat.
    final n = kPantryEnabled
        ? recipeNutrition(
            _recipe, {for (final p in pantryProducts) p.id: p})
        : null;
    NutritionBlock? block;
    if (n != null && !n.isEmpty) {
      final words = nutritionWords(n);
      if (!words.isEmpty) {
        block = NutritionBlock(
          headline: words.headline ?? 'Per serving',
          macros: words.macros,
          note: words.note,
        );
      }
    }

    return RecipePdfData(
      title: _recipe.title,
      ingredients: lines,
      groupBefore: groups,
      steps: [
        for (final s in _recipe.steps) convertUnits(s.raw, system),
      ],
      servings: _recipe.servings?.raw,
      time: _recipe.times?.raw,
      notes: _notes.text,
      sourceLine: url == null || url.isEmpty ? null : 'Source: $url',
      cover: coverBytes,
      nutrition: block,
    );
  }

  /// Google Docs door — shown only when Drive is already connected
  /// (export track D1). Uploads the recipe as HTML with the Docs conversion
  /// mimeType, then opens the document in the browser.
  Future<void> _openInDocs() async {
    final messenger = ScaffoldMessenger.of(context);
    final client = context.read<StorageModel>().driveClient();
    if (client == null) return;
    final data = await _exportData();
    messenger.showSnackBar(
        const SnackBar(content: Text('Making a Google Doc…')));
    try {
      final link = await exportRecipeToGoogleDocs(client, data);
      await const MethodChannel('com.merkurialstudio.myrecibook/auth')
          .invokeMethod<void>('launchUrl', link);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text("Couldn't reach Drive — the PDF still works")));
    }
  }

  /// Tap the share button: straight to the PDF unless Drive is connected,
  /// in which case the user picks. No menu with one live option in it.
  Future<void> _share() async {
    if (!context.read<StorageModel>().driveConnected) return _sharePdf();
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('share-as-pdf'),
              leading: const Icon(Icons.picture_as_pdf_rounded),
              title: const Text('Share as PDF'),
              subtitle: const Text('Mail, print, or save anywhere'),
              onTap: () => Navigator.of(sheetContext).pop('pdf'),
            ),
            ListTile(
              key: const Key('open-in-docs'),
              leading: const Icon(Icons.article_rounded),
              title: const Text('Open in Google Docs'),
              subtitle: const Text('Saved in your MyReciBook folder'),
              onTap: () => Navigator.of(sheetContext).pop('docs'),
            ),
          ],
        ),
      ),
    );
    if (choice == 'pdf') await _sharePdf();
    if (choice == 'docs') await _openInDocs();
  }

  /// Filename the user sees in the share sheet: their title, safe for any
  /// filesystem. Empty after stripping (emoji-only title) → 'recipe'.
  String _pdfName() {
    final slug = _recipe.title
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9\u00c0-\u024f]+"), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'recipe' : slug;
  }

  Future<void> _edit() async {
    final saved = await Navigator.of(context).push<Recipe>(MaterialPageRoute(
      builder: (_) =>
          ManualEntryScreen(initial: _recipe, originals: _originals),
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
    // Same live pantry list the linked ingredient rows watch — the badge
    // recomputes the moment a link is made or a product changes. Hidden
    // entirely when nothing is covered: a card promising numbers it doesn't
    // have is a dead end, not a feature (Arnar, 2026-08-19).
    final nutrition = kPantryEnabled
        ? recipeNutrition(_recipe,
            {for (final p in context.watch<PantryModel>().products) p.id: p})
        : null;

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
                  // Tags sit under the meta chips: they belong to the recipe
                  // the way its time and servings do, and they are the thing
                  // a user comes back to a recipe to change.
                  if (kRecipeTagsEnabled) ...[
                    const SizedBox(height: 12),
                    _tagRow(),
                  ],
                  if (nutrition != null && !nutrition.isEmpty) ...[
                    const SizedBox(height: 14),
                    const SectionLabel('Nutrition'),
                    const SizedBox(height: 8),
                    _nutritionCard(theme, scheme, nutrition),
                  ],
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
                                TextSpan(
                                    text: convertUnits(_recipe.steps[n].raw,
                                        context.watch<UnitsModel>().system)),
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

  /// Nutrition badge, fed by the pantry links. Per serving when the recipe
  /// says how many it serves; otherwise the whole-recipe sum, labelled as
  /// such — dividing by an invented count would be a lie with decimals. The
  /// '~' and the "N of M" line are the honesty contract: a partial sum is a
  /// hint, never the truth (Arnar, 2026-08-19).
  Widget _nutritionCard(ThemeData theme, ColorScheme scheme, RecipeNutrition n) {
    // Wording lives in domain/nutrient_display.dart so the PDF export prints
    // the identical lines — one honesty contract, one place to edit it.
    final words = nutritionWords(n);
    final headline = words.headline;
    final macros = words.macros;
    return TokenCard(
      key: const Key('nutrition-card'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (headline != null)
            Text(headline,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
          if (macros.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: headline == null ? 0 : 4),
              child: Text(macros,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ),
          const SizedBox(height: 6),
          Text(
            words.note,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
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
          key: const Key('share-pdf-button'),
          icon: Icons.ios_share_rounded,
          tooltip: 'Share as PDF',
          onTap: _share,
        ),
        const SizedBox(width: 8),
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

  /// Long-press an ingredient row → pick the pantry product it means. The
  /// user is the matcher (no AI): "250ml Milk" → their Mellommelk, saved in
  /// the recipe file as product_ref, nutrition math follows the link.
  Future<void> _linkSheet(int index) async {
    final pantry = context.read<PantryModel>();
    await pantry.ensureLoaded();
    if (!mounted) return;
    final ing = _recipe.ingredients[index];
    if (pantry.products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Your pantry is empty — scan some products on the '
              'Pantry tab first, then link them here.')));
      return;
    }
    final pick = await showProductPickerSheet(
      context,
      pantry: pantry,
      title: 'Which product is "${ing.item ?? ing.raw}"?',
      allowUnlink: ing.productRef != null,
    );
    if (!mounted || pick == null) return;
    final next = [..._recipe.ingredients];
    final chosen = pick.product;
    if (chosen != null) {
      next[index] = ing.copyWith(productRef: chosen.id);
      await _persist(_recipe.copyWith(ingredients: next),
          confirmation: 'Linked to ${chosen.name}');
    } else {
      next[index] = ing.copyWith(clearProductRef: true);
      await _persist(_recipe.copyWith(ingredients: next),
          confirmation: 'Unlinked');
    }
  }

  List<Widget> _ingredientRows(ThemeData theme, ColorScheme scheme) {
    final rows = <Widget>[];
    String? prevGroup;
    final rb = context.rb;
    // Linked labels resolve against the live pantry; a dangling ref (product
    // removed) just shows nothing — display noise, never an error.
    final pantryProducts =
        kPantryEnabled ? context.watch<PantryModel>().products : const <Product>[];
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
      Product? linked;
      if (ing.productRef != null) {
        for (final p in pantryProducts) {
          if (p.id == ing.productRef) {
            linked = p;
            break;
          }
        }
      }
      rows.add(InkWell(
        onTap: () => setState(
            () => checked ? _checked.remove(i) : _checked.add(i)),
        onLongPress: kPantryEnabled ? () => _linkSheet(i) : null,
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
                // Linked rows show the PRODUCT's name inline as the
                // ingredient name — one line, no sub-line (Arnar 2026-08-20).
                // Display-time substitution only: ing.raw in the file is
                // never touched, so unlink and re-import stay clean. The
                // trailing kitchen icon keeps the sub-line's linked marker.
                child: Text.rich(
                  TextSpan(children: [
                    qtyBoldSpan(
                      convertUnits(
                          linked == null
                              ? ing.raw
                              : linkedIngredientLine(ing, linked.name),
                          context.watch<UnitsModel>().system),
                      theme.textTheme.bodyMedium?.copyWith(
                        decoration:
                            checked ? TextDecoration.lineThrough : null,
                        color: checked ? scheme.onSurfaceVariant : null,
                      ),
                    ),
                    if (linked != null) ...[
                      const WidgetSpan(child: SizedBox(width: 5)),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(Icons.kitchen_rounded,
                            size: 12,
                            color: checked
                                ? scheme.onSurfaceVariant
                                : scheme.primary),
                      ),
                    ],
                  ]),
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

/// Display line for a pantry-linked ingredient row (Arnar 2026-08-20):
/// qty + unit + the PRODUCT's name stand in for the typed ingredient name.
/// Pure display-time substitution — never written back to the recipe file.
///
/// Rule, first match wins:
/// 1. `item` parsed and found in `raw` (case-insensitive) — replace that
///    first occurrence with the product name; the typed qty/unit/notes
///    around it survive verbatim ("2 dl milk, warm" -> "2 dl Mellommelk
///    2,0% fett, warm").
/// 2. else `qty` parsed — rebuild as "qty[ unit] productName".
/// 3. else — the product name alone.
///
/// The result feeds the same convertUnits + qtyBoldSpan pipeline as an
/// unlinked row, so the units toggle keeps working on the shown qty/unit.
/// Lives here for now; the manual-entry editor can lift the same rule.
String linkedIngredientLine(Ingredient ing, String productName) {
  final item = ing.item;
  if (item != null && item.isNotEmpty) {
    final at = ing.raw.toLowerCase().indexOf(item.toLowerCase());
    if (at >= 0) {
      return ing.raw.replaceRange(at, at + item.length, productName);
    }
  }
  final qty = ing.qty;
  if (qty != null) {
    final q = qty == qty.round() ? '${qty.round()}' : '$qty';
    final unit = ing.unit;
    return unit == null || unit.isEmpty
        ? '$q $productName'
        : '$q $unit $productName';
  }
  return productName;
}


/// The one door that adds a tag — a dashed chip so it reads as an action and
/// not as a tag called "Tag".
class _AddTagChip extends StatelessWidget {
  const _AddTagChip({required this.onTap});

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
