// Settings → Tags. The list, reorder, and the create/edit sheet.
//
// Two lists on purpose. The top one is the tags the user has designed. The
// bottom one — "found in your recipes" — is every tag string the library
// carries that tags.json says nothing about: a hand-edited file, a folder
// synced from another install, or a tags.json that went missing. They are
// real tags, so they are shown and can be adopted, not quietly dropped.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/recipe_tag.dart';
import 'tag_chip.dart';
import 'tag_editor_sheet.dart';
import 'tags_model.dart';
import 'theme.dart';
import 'widgets/skin.dart';

class TagsScreen extends StatelessWidget {
  const TagsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<TagsModel>();
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final orphans = model.undecoratedNames;
    return Scaffold(
      appBar: AppBar(title: const Text('Tags')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('tags-new-button'),
        onPressed: () => showTagEditor(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New tag'),
      ),
      body: model.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
              children: [
                Text(
                  'Your own tags. Put them on recipes from a recipe page, then '
                  'filter your cookbook by them.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(height: 1.5, color: scheme.onSurfaceVariant),
                ),
                if (model.error != null) ...[
                  const SizedBox(height: 12),
                  _ErrorNote(model.error!),
                ],
                const SizedBox(height: 18),
                if (model.tags.isEmpty)
                  _Empty(hasOrphans: orphans.isNotEmpty)
                else ...[
                  const SectionLabel('YOUR TAGS'),
                  const SizedBox(height: 8),
                  // Order is the filter row's order, so it is worth dragging.
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: model.tags.length,
                    // onReorderItem, not onReorder: it hands back an index
                    // already adjusted for the removed row, so the model's
                    // reorder needs no off-by-one dance of its own.
                    onReorderItem: model.reorder,
                    itemBuilder: (context, i) {
                      final tag = model.tags[i];
                      return _TagRow(
                        key: ValueKey(RecipeTag.canonical(tag.name)),
                        index: i,
                        tag: tag,
                        uses: model.usageOf(tag.name),
                      );
                    },
                  ),
                ],
                if (orphans.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const SectionLabel('FOUND IN YOUR RECIPES'),
                  const SizedBox(height: 6),
                  Text(
                    'These are on recipes already but have no icon or colour '
                    'yet. Tap one to give it a look.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(height: 1.5, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final name in orphans)
                        TagChip(
                          tag: RecipeTag(name: name),
                          onTap: () => showTagEditor(context,
                              initial: RecipeTag(name: name), adopting: true),
                        ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({
    super.key,
    required this.index,
    required this.tag,
    required this.uses,
  });

  final int index;
  final RecipeTag tag;
  final int uses;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showTagEditor(context, initial: tag),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.rb.hairline),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                children: [
                  // The chip itself is the row's preview — what you see here
                  // is exactly what the cookbook will draw.
                  TagChip(tag: tag),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      uses == 0
                          ? 'not on any recipe yet'
                          : 'on $uses recipe${uses == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                  ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.drag_handle_rounded,
                          size: 20, color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.hasOrphans});

  final bool hasOrphans;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.sell_rounded, size: 30, color: scheme.primary),
          ),
          const SizedBox(height: 16),
          Text('No tags yet',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            hasOrphans
                ? 'Your recipes already carry the names below — give one a '
                    'look, or invent a new tag.'
                : 'Invent one: a name, an icon, a colour. Weeknight. Mum’s. '
                    'Too much effort.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(height: 1.55, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 18, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onErrorContainer)),
          ),
        ],
      ),
    );
  }
}
