// Create or edit one tag, on a full page: name, icon, colour, live preview.
//
// A page, not a sheet (Arnar 2026-08-27): the sheet fought the keyboard,
// carried a search field for a 78-icon catalog, parked "show the name" a
// scroll away from the name it belonged to, and wore a different blue than
// the screen that opened it. The search field is gone — and with it the
// typed-emoji escape hatch; the 117-emoji palette is the emoji offer now.
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
/// onto whatever it was tagging. Back and delete return null.
Future<String?> showTagEditor(
  BuildContext context, {
  RecipeTag? initial,
  bool adopting = false,
}) {
  final model = context.read<TagsModel>();
  return Navigator.of(context).push<String>(MaterialPageRoute<String>(
    builder: (_) => ChangeNotifierProvider<TagsModel>.value(
      value: model,
      child: TagEditorScreen(initial: initial, adopting: adopting),
    ),
  ));
}

class TagEditorScreen extends StatefulWidget {
  const TagEditorScreen({super.key, this.initial, this.adopting = false});

  final RecipeTag? initial;
  final bool adopting;

  bool get isNew => initial == null;

  @override
  State<TagEditorScreen> createState() => _TagEditorScreenState();
}

class _TagEditorScreenState extends State<TagEditorScreen> {
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

  Future<void> _confirmDelete() async {
    final model = context.read<TagsModel>();
    final tag = widget.initial!;
    final uses = model.usageOf(tag.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text('Delete “${tag.name}”?'),
        content: Text(uses == 0
            ? 'It is not on any recipe. Nothing else changes.'
            : 'It comes off $uses recipe${uses == 1 ? '' : 's'} too. The '
                'recipes themselves are not touched.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(dctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _saving = true);
    await model.delete(tag.name);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew || widget.adopting ? 'New tag' : 'Edit tag'),
        actions: [
          if (!widget.isNew && !widget.adopting)
            IconButton(
              key: const Key('tag-delete-button'),
              tooltip: 'Delete tag',
              onPressed: _saving ? null : _confirmDelete,
              icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          // Live preview — exactly the chip the cookbook will draw.
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [TagChip(tag: _preview, selected: true)],
            ),
          ),
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
                  ? 'Already on your recipes — rename it from the list'
                  : null,
              border: const OutlineInputBorder(),
            ),
          ),
          // Right under the name it governs — "do the words show on the
          // chip?" belongs beside the words, not a scroll below them.
          SwitchListTile.adaptive(
            key: const Key('tag-show-label-switch'),
            contentPadding: EdgeInsets.zero,
            value: _showLabel,
            // Forced on when there is no icon: the alternative is a chip
            // with nothing in it. RecipeTag enforces it anyway, but the
            // switch should not sit there lying.
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
              value: _color, onChanged: (c) => setState(() => _color = c)),
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
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        // Content-sized and centred, not stretched — in a ROW, never Center:
        // bottomNavigationBar hands its child the whole remaining height and
        // Center takes all of it, which squeezed the body to nothing and
        // shipped a blank editor (Arnar 2026-08-28). A Row only spreads
        // sideways; its height stays the button's own.
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
