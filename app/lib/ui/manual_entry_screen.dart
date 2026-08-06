// Manual entry — the 5b promise "Typing recipes in yourself is always
// unlimited": no AI, no cap, no images. Builds a source.type "manual" recipe
// file (schema-additive — old files unaffected) and saves through the same
// LibraryModel seam as imports, so grocery/storage integration rides along.
//
// DEVIATION (for Arnar to ratify): no hi-fi mockup exists for this screen —
// 5b names the promise, 4c/4d name the door. Assembled from the 3c review
// patterns: title card, section-labeled cards with one line per
// ingredient/step, pill inputs for servings/time, stadium CTA.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../data/saf_store.dart';
import '../domain/recipe.dart';
import '../domain/validate.dart';
import 'library_model.dart';
import 'theme.dart';
import 'widgets/skin.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _title = TextEditingController();
  final _ingredients = TextEditingController();
  final _steps = TextEditingController();
  final _servings = TextEditingController();
  final _times = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _ingredients.dispose();
    _steps.dispose();
    _servings.dispose();
    _times.dispose();
    super.dispose();
  }

  static List<String> _lines(TextEditingController c) => [
        for (final l in c.text.split('\n'))
          if (l.trim().isNotEmpty) l.trim()
      ];

  Future<void> _save() async {
    final servings = _servings.text.trim();
    final times = _times.text.trim();
    final recipe = Recipe(
      schemaVersion: Recipe.currentSchemaVersion,
      id: const Uuid().v4(),
      title: _title.text.trim(),
      // No extraction envelope, no images: nothing was extracted (rule 2 —
      // metadata is stamped by our code only when it is true).
      source: RecipeSource(
          type: 'manual', importedAt: DateTime.now().toIso8601String()),
      servings: servings.isEmpty ? null : Servings(raw: servings),
      times: times.isEmpty ? null : RecipeTimes(raw: times),
      ingredients: [for (final l in _lines(_ingredients)) Ingredient(raw: l)],
      steps: [for (final l in _lines(_steps)) RecipeStep(raw: l)],
    );

    final blocking =
        fileProblems(recipe.toJson()).where(isSaveBlocking).toList();
    if (blocking.isNotEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(blocking.join(' · '))));
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<LibraryModel>().saveImported(recipe, const []);
    } on GrantLostException {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Folder access was lost — your recipe is kept here. '
              'Try again, or go back and re-pick your folder.')));
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Widget _pillInput(
      {required Key key,
      required TextEditingController controller,
      required IconData icon,
      required String hint}) {
    final scheme = context.scheme;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        border: Border.all(color: context.rb.hairline),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              key: key,
              controller: controller,
              style: Theme.of(context).textTheme.labelMedium,
              decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: hint),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Text('Type it in yourself', style: theme.textTheme.titleLarge),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: [
                  TokenCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('manual-title'),
                            controller: _title,
                            style: theme.textTheme.titleLarge,
                            decoration: const InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                                hintText: 'Recipe title'),
                          ),
                        ),
                        Icon(Icons.edit_rounded,
                            size: 19, color: scheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _pillInput(
                            key: const Key('manual-servings'),
                            controller: _servings,
                            icon: Icons.restaurant_rounded,
                            hint: '4 servings'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _pillInput(
                            key: const Key('manual-times'),
                            controller: _times,
                            icon: Icons.schedule_rounded,
                            hint: '25 min'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const SectionLabel('Ingredients'),
                  const SizedBox(height: 8),
                  TokenCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: TextField(
                      key: const Key('manual-ingredients'),
                      controller: _ingredients,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                      maxLines: null,
                      minLines: 4,
                      decoration: const InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: 'One ingredient per line'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const SectionLabel('Steps'),
                  const SizedBox(height: 8),
                  TokenCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: TextField(
                      key: const Key('manual-steps'),
                      controller: _steps,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                      maxLines: null,
                      minLines: 4,
                      decoration: const InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: 'One step per line'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Typed-in recipes are always unlimited — no AI involved.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: const Text('Save to cookbook'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
