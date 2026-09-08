// Create or edit one tag, in a bottom sheet: name, icon, colour, live preview.
//
// A sheet, one tap from wherever the tag is seen (Direction A, Arnar
// 2026-09-03): "Edit tag" on the narrowed cookbook header, a long-press on a
// tile, the New tag tile, and the picker's New tag button. It replaces the
// Settings list page plus a full editor page — three screens deep for a
// name, a colour and an icon. The first sheet (2026-08-27) fought the
// keyboard; this one is isScrollControlled, pads the view insets, and keeps
// the form in a ListView so the name field can always scroll into view.
//
// The preview is the point. Icon-only versus pill is the kind of choice you
// cannot make from a switch label, so the real chip sits at the top and
// changes as you touch things — and the whole icon grid wears the chosen
// colour, so picking red repaints every icon before you commit to one.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/recipe_tag.dart';
import '../domain/tag_emoji.dart';
import '../domain/tag_icons.dart';
import 'icons/food_icons.dart';
import 'tag_chip.dart';
import 'tags_model.dart';
import 'theme.dart';
import 'widgets/skin.dart';

/// [initial] null creates. [adopting] means the name already lives on recipes
/// and is only gaining a look — the name field locks, because renaming here
/// would rewrite files the user did not come to rename.
///
/// Returns the saved tag's name, so an opener can put the fresh tag straight
/// onto whatever it was tagging, or follow a rename. Dismiss and delete
/// return null.
Future<String?> showTagEditor(
  BuildContext context, {
  RecipeTag? initial,
  bool adopting = false,
}) {
  final model = context.read<TagsModel>();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: ChangeNotifierProvider<TagsModel>.value(
        value: model,
        child: TagEditorSheet(initial: initial, adopting: adopting),
      ),
    ),
  );
}

class TagEditorSheet extends StatefulWidget {
  const TagEditorSheet({super.key, this.initial, this.adopting = false});

  final RecipeTag? initial;
  final bool adopting;

  bool get isNew => initial == null;

  @override
  State<TagEditorSheet> createState() => _TagEditorSheetState();
}

class _TagEditorSheetState extends State<TagEditorSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initial?.name ?? '');
  late String? _icon = widget.initial?.icon;
  late TagColor _color = widget.initial?.color ?? TagColor.primary;
  late bool _showLabel = widget.initial?.showLabel ?? true;
  String? _nameError;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  RecipeTag get _preview => RecipeTag(
        name: _name.text.trim().isEmpty ? 'Tag name' : _name.text.trim(),
        icon: _icon,
        color: _color,
        showLabel: _showLabel,
      );

  Future<void> _save() async {
    final model = context.read<TagsModel>();
    final name = _name.text.trim();
    if (!RecipeTag.isValidName(name)) {
      setState(() => _nameError = 'Give it a name');
      return;
    }
    // adopting: the tag is not in tags.json yet, so it is a create even though
    // the name already exists out in the library.
    final existing = widget.initial;
    final isCreate = widget.isNew || widget.adopting;
    if (isCreate && model.nameTaken(name)) {
      setState(() => _nameError = 'You already have a tag called that');
      return;
    }
    setState(() => _saving = true);
    final tag = RecipeTag(
        name: name, icon: _icon, color: _color, showLabel: _showLabel);
    final ok = isCreate
        ? await model.create(tag)
        : await model.update(existing!.name, tag);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _saving = false;
        _nameError = 'You already have a tag called that';
      });
      return;
    }
    Navigator.of(context).pop(name);
  }

  /// Deleted means gone (Arnar 2026-08-27): off every recipe that carries it
  /// as well as out of tags.json. The house destructive dialog says what
  /// survives before what stops.
  Future<void> _confirmDelete() async {
    final model = context.read<TagsModel>();
    final tag = widget.initial!;
    final uses = model.usageOf(tag.name);
    final ok = await showDestructiveConfirm(
      context,
      title: 'Delete “${tag.name}”?',
      body: uses == 0
          ? 'Nothing carries it, so nothing else changes.'
          : 'Your recipes stay as they are. The tag comes off '
              '$uses of them.',
      verb: 'Delete',
    );
    if (!ok || !mounted) return;
    setState(() => _saving = true);
    await model.delete(tag.name);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final model = context.watch<TagsModel>();
    final uses = widget.isNew ? 0 : model.usageOf(widget.initial!.name);
    return ConstrainedBox(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Live preview — exactly the chip the cookbook will draw.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Row(
              children: [
                TagChip(tag: _preview, selected: true),
                const Spacer(),
                if (!widget.isNew)
                  Text(
                    uses == 0
                        ? 'not on any recipe yet'
                        : 'on $uses recipe${uses == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              children: [
                TextField(
                  key: const Key('tag-name-field'),
                  controller: _name,
                  enabled: !widget.adopting,
                  autofocus: widget.isNew,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() => _nameError = null),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    hintText: 'Weeknight',
                    errorText: _nameError,
                    helperText: widget.adopting
                        ? 'Already on your recipes — the name stays'
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
                // Right under the name it governs — "do the words show on
                // the chip?" belongs beside the words.
                SwitchListTile.adaptive(
                  key: const Key('tag-show-label-switch'),
                  contentPadding: EdgeInsets.zero,
                  value: _showLabel,
                  // Forced on when there is no icon: the alternative is a
                  // chip with nothing in it. RecipeTag enforces it anyway,
                  // but the switch should not sit there lying.
                  onChanged: _icon == null
                      ? null
                      : (v) => setState(() => _showLabel = v),
                  title: const Text('Show the name'),
                  subtitle: Text(
                    _icon == null
                        ? 'Pick an icon below to turn this off'
                        : _showLabel
                            ? 'A pill with the icon and the name'
                            : 'Icon only — a small circle, no words',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 12),
                const SectionLabel('COLOUR'),
                const SizedBox(height: 10),
                _ColorRow(
                    value: _color,
                    onChanged: (c) => setState(() => _color = c)),
                const SizedBox(height: 20),
                const SectionLabel('ICON'),
                const SizedBox(height: 8),
                _IconField(
                  icon: _icon,
                  color: _color,
                  onChanged: (v) => setState(() {
                    _icon = v;
                    if (v == null) _showLabel = true;
                  }),
                ),
              ],
            ),
          ),
          // Footer: content-sized in a ROW, never a Center — the blank-editor
          // regression (Arnar 2026-08-28) came from a Center taking every
          // pixel a bottom slot offered.
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                if (!widget.isNew)
                  TextButton(
                    key: const Key('tag-delete-button'),
                    onPressed: _saving ? null : _confirmDelete,
                    style: TextButton.styleFrom(foregroundColor: scheme.error),
                    child: const Text('Delete tag'),
                  ),
                const Spacer(),
                FilledButton(
                  key: const Key('tag-save-button'),
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 32)),
                  child: Text(
                      widget.isNew || widget.adopting ? 'Create tag' : 'Save'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The catalog by group, plus the emoji palette behind a two-way switch.
/// Every Material glyph is drawn in the tag's chosen colour, so the colour
/// row repaints the whole grid. Emoji render as text — Android's own colour
/// font — so they keep their own colours untinted.
class _IconField extends StatefulWidget {
  const _IconField({
    required this.icon,
    required this.color,
    required this.onChanged,
  });

  final String? icon;
  final TagColor color;
  final ValueChanged<String?> onChanged;

  @override
  State<_IconField> createState() => _IconFieldState();
}

class _IconFieldState extends State<_IconField> {
  /// Which palette is showing. Opens on whichever kind the tag already wears,
  /// so editing an emoji tag does not start on the wrong list.
  late bool _emojiMode = widget.icon != null && !isTagIconKey(widget.icon!);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment<bool>(value: false, label: Text('Icons')),
                ButtonSegment<bool>(value: true, label: Text('Emoji')),
              ],
              selected: {_emojiMode},
              onSelectionChanged: (s) => setState(() => _emojiMode = s.first),
            ),
            const Spacer(),
            if (widget.icon != null)
              TextButton.icon(
                key: const Key('tag-icon-clear'),
                onPressed: () => widget.onChanged(null),
                icon: const Icon(Icons.backspace_outlined, size: 18),
                label: const Text('No icon'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_emojiMode)
          for (final group in TagEmojiGroup.values)
            _PaletteGroup(
              title: _emojiGroupName(group),
              children: [
                for (final e in tagEmojiIn(group))
                  _Tile(
                    selected: widget.icon == e.char,
                    onTap: () => widget.onChanged(e.char),
                    child: Text(e.char, style: const TextStyle(fontSize: 22)),
                  ),
              ],
            )
        else
          for (final group in TagIconGroup.values)
            _PaletteGroup(
              title: _groupName(group),
              children: [
                for (final i in tagIconsIn(group))
                  _Tile(
                    selected: widget.icon == i.key,
                    onTap: () => widget.onChanged(i.key),
                    child: Icon(foodIcon(i.key),
                        size: 21, color: tagColorOf(context, widget.color)),
                  ),
              ],
            ),
      ],
    );
  }
}

String _groupName(TagIconGroup g) => switch (g) {
      TagIconGroup.dishes => 'DISHES',
      TagIconGroup.ingredients => 'INGREDIENTS',
      TagIconGroup.kitchen => 'KITCHEN & TOOLS',
      TagIconGroup.occasions => 'OCCASIONS',
      TagIconGroup.dietary => 'DIETARY',
      TagIconGroup.time => 'TIME',
    };

String _emojiGroupName(TagEmojiGroup g) => switch (g) {
      TagEmojiGroup.fruitVeg => 'FRUIT & VEG',
      TagEmojiGroup.meatFish => 'MEAT & FISH',
      TagEmojiGroup.dairyEggs => 'DAIRY & EGGS',
      TagEmojiGroup.grains => 'GRAINS & BREAD',
      TagEmojiGroup.sweets => 'SWEETS',
      TagEmojiGroup.drinks => 'DRINKS',
      TagEmojiGroup.dishes => 'MEALS & DISHES',
      TagEmojiGroup.kitchen => 'KITCHEN',
      TagEmojiGroup.occasions => 'OCCASIONS',
    };

class _PaletteGroup extends StatelessWidget {
  const _PaletteGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Text(title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 0.9,
                  color: context.scheme.onSurfaceVariant)),
        ),
        Wrap(spacing: 8, runSpacing: 8, children: children),
        const SizedBox(height: 14),
      ],
    );
  }
}

/// One palette cell. Holds an Icon or an emoji Text — the selected skin is
/// identical either way, so the two lists cannot drift.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.child,
    required this.selected,
    required this.onTap,
  });

  final Widget child;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? scheme.secondaryContainer
              : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border:
              selected ? Border.all(color: scheme.primary, width: 1.5) : null,
        ),
        child: child,
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({required this.value, required this.onChanged});

  final TagColor value;
  final ValueChanged<TagColor> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final c in TagColor.values)
          GestureDetector(
            onTap: () => onChanged(c),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: tagColorOf(context, c),
                shape: BoxShape.circle,
                border: c == value
                    ? Border.all(color: context.scheme.onSurface, width: 2.5)
                    : null,
              ),
              child: c == value
                  ? const Icon(Icons.check_rounded,
                      size: 18, color: Colors.white)
                  : null,
            ),
          ),
      ],
    );
  }
}
