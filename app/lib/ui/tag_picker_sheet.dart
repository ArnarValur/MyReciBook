// "Put tags on this thing" — one sheet, used by the recipe page and by the
// import review before a recipe is ever saved.
//
// It works on tag NAMES, not on a Recipe, because at review time there is no
// recipe yet. That is the whole point: tags arrive with an import (link
// extraction maps recipeCategory, recipeCuisine and keywords into them), and
// the user should get to see and edit them before they land in the cookbook
// rather than discover them in Settings afterwards.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/recipe_tag.dart';
import 'tag_chip.dart';
import 'tags_model.dart';
import 'theme.dart';
import 'widgets/skin.dart';

/// [selected] is read fresh on every rebuild, so the caller can keep its own
/// state and the sheet stays in step. [onToggle] may be async — the sheet
/// awaits it before redrawing.
Future<void> showTagPicker(
  BuildContext context, {
  required List<String> Function() selected,
  required Future<void> Function(String name) onToggle,
}) {
  final model = context.read<TagsModel>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: ChangeNotifierProvider<TagsModel>.value(
        value: model,
        child: _TagPicker(selected: selected, onToggle: onToggle),
      ),
    ),
  );
}

class _TagPicker extends StatefulWidget {
  const _TagPicker({required this.selected, required this.onToggle});

  final List<String> Function() selected;
  final Future<void> Function(String name) onToggle;

  @override
  State<_TagPicker> createState() => _TagPickerState();
}

class _TagPickerState extends State<_TagPicker> {
  final _newTag = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _newTag.dispose();
    super.dispose();
  }

  bool _isOn(String name) => widget
      .selected()
      .any((t) => RecipeTag.canonical(t) == RecipeTag.canonical(name));

  Future<void> _toggle(String name) async {
    if (_busy) return;
    setState(() => _busy = true);
    await widget.onToggle(name);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _addTyped() async {
    final name = _newTag.text.trim();
    if (!RecipeTag.isValidName(name) || _isOn(name)) return;
    _newTag.clear();
    await _toggle(name);
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<TagsModel>();
    final theme = Theme.of(context);
    final scheme = context.scheme;
    // Everything that exists anywhere: decorated first (Settings order), then
    // names only the library knows about, then anything on THIS item that is
    // neither — which is exactly what a fresh import brings in.
    final known = <String, RecipeTag>{};
    for (final t in model.tags) {
      known[RecipeTag.canonical(t.name)] = t;
    }
    for (final n in model.undecoratedNames) {
      known.putIfAbsent(RecipeTag.canonical(n), () => RecipeTag(name: n));
    }
    for (final n in widget.selected()) {
      known.putIfAbsent(RecipeTag.canonical(n), () => RecipeTag(name: n));
    }
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  const SectionLabel('Tags'),
                  const Spacer(),
                  if (_busy)
                    const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                children: [
                  if (known.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'No tags yet. Type one below — icons and colours come '
                        'later, in Settings → Tags.',
                        style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.5, color: scheme.onSurfaceVariant),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in known.values)
                          TagChip(
                            tag: tag,
                            selected: _isOn(tag.name),
                            onTap: () => _toggle(tag.name),
                          ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('tag-picker-new'),
                    controller: _newTag,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addTyped(),
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'New tag',
                      hintText: 'Weeknight',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        key: const Key('tag-picker-add'),
                        tooltip: 'Add',
                        onPressed: _addTyped,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
              child: Row(
                children: [
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
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
