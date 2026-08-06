// Recipe detail (design 3e): hero cover with provenance flip, favorite heart
// (the schema's user-owned bool), ingredient check-off (ephemeral view state),
// notes editing post-save (D6) + delete. Servings render as a static chip —
// the stepper waits for the rescale engine (post-alpha).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/recipe.dart';
import 'cook_mode_screen.dart';
import 'library_model.dart';
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

  @override
  void initState() {
    super.initState();
    _loadOriginals();
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

  Future<void> _saveNotes() =>
      _persist(_recipe.copyWith(notes: _notes.text), confirmation: 'Notes saved');

  Future<void> _toggleFavorite() =>
      _persist(_recipe.copyWith(favorite: !_recipe.favorite));

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete recipe?'),
        content: Text('"${_recipe.title}" and its images will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<LibraryModel>().delete(_recipe.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final originals = _originals;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _hero(scheme, originals),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
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
            if (_recipe.steps.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () =>
                        Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => CookModeScreen(recipe: _recipe),
                    )),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start cooking'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _hero(ColorScheme scheme, List<File> originals) {
    final cover = originals.firstOrNull;
    return SizedBox(
      height: 210,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: originals.isEmpty
                ? null
                : () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => OriginalsViewer(images: originals))),
            child: _showOriginal
                ? ColoredBox(
                    color: scheme.surfaceContainerLow,
                    child: CoverImage(cover, fit: BoxFit.contain))
                : CoverImage(cover),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: GlassCircle(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Row(
              children: [
                GlassCircle(
                  key: const Key('favorite-button'),
                  icon: _recipe.favorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_outline_rounded,
                  filled: _recipe.favorite,
                  iconColor: _recipe.favorite
                      ? scheme.tertiaryContainer
                      : scheme.onSurface,
                  onTap: _toggleFavorite,
                ),
                const SizedBox(width: 8),
                GlassCircle(icon: Icons.delete_rounded, onTap: _delete),
              ],
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
