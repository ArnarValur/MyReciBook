// Create or edit one tag: name, icon, colour, "show the label", live preview.
//
// The preview is the point. Icon-only versus pill is the kind of choice you
// cannot make from a switch label, so the real chip sits at the top of the
// sheet and changes as you touch things.
//
// The icon field takes a Material catalog key OR an emoji, and the picker
// offers both behind a two-way switch: Material for the brand-clean look,
// Emoji because the pantry's category chips have used them since 2026-08-20
// and they cover exactly what Material cannot — named ingredients. Anything
// typed that is not a catalog key is taken as an emoji, so the palette is a
// convenience, never a ceiling.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
Future<void> showTagEditor(
  BuildContext context, {
  RecipeTag? initial,
  bool adopting = false,
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
        child: _TagEditor(
            initial: initial, adopting: adopting, isNew: initial == null),
      ),
    ),
  );
}

class _TagEditor extends StatefulWidget {
  const _TagEditor({
    required this.initial,
    required this.adopting,
    required this.isNew,
  });

  final RecipeTag? initial;
  final bool adopting;
  final bool isNew;

  @override
  State<_TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends State<_TagEditor> {
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
    Navigator.of(context).pop();
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
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.86),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Live preview — exactly the chip the cookbook will draw.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [TagChip(tag: _preview, selected: true)],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
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
                          ? 'Already on your recipes — rename it from the list'
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SectionLabel('ICON'),
                  const SizedBox(height: 8),
                  _IconField(
                    icon: _icon,
                    onChanged: (v) => setState(() {
                      _icon = v;
                      // No icon means the label must show; RecipeTag enforces
                      // it anyway, but the switch should not sit there lying.
                      if (v == null) _showLabel = true;
                    }),
                  ),
                  SwitchListTile.adaptive(
                    key: const Key('tag-show-label-switch'),
                    contentPadding: EdgeInsets.zero,
                    value: _showLabel,
                    // Forced on when there is no icon: the alternative is a
                    // chip with nothing in it. Sits directly under the icon
                    // picker because that is when the question arises —
                    // "you have an icon, do you still want the words?".
                    onChanged: _icon == null
                        ? null
                        : (v) => setState(() => _showLabel = v),
                    title: const Text('Show the name'),
                    subtitle: Text(
                      _icon == null
                          ? 'Pick an icon above to turn this off'
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
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
              child: Row(
                children: [
                  if (!widget.isNew && !widget.adopting)
                    TextButton.icon(
                      key: const Key('tag-delete-button'),
                      onPressed: _saving ? null : _confirmDelete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      style: TextButton.styleFrom(
                          foregroundColor: scheme.error),
                      label: const Text('Delete'),
                    ),
                  const Spacer(),
                  FilledButton(
                    key: const Key('tag-save-button'),
                    onPressed: _saving ? null : _save,
                    child: Text(widget.isNew || widget.adopting
                        ? 'Create tag'
                        : 'Save'),
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

/// The chosen icon, a search box, and the catalog by group. The text field
/// doubles as the emoji escape hatch: type a character that is not a catalog
/// key and it becomes the icon.
class _IconField extends StatefulWidget {
  const _IconField({required this.icon, required this.onChanged});

  final String? icon;
  final ValueChanged<String?> onChanged;

  @override
  State<_IconField> createState() => _IconFieldState();
}

class _IconFieldState extends State<_IconField> {
  final _search = TextEditingController();
  String _query = '';

  /// Which palette is showing. Opens on whichever kind the tag already wears,
  /// so editing an emoji tag does not start on the wrong list.
  late bool _emojiMode = widget.icon != null && !isTagIconKey(widget.icon!);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<TagEmoji> _emojiMatches(TagEmojiGroup group) {
    final q = _query.trim().toLowerCase();
    final all = tagEmojiIn(group);
    if (q.isEmpty) return all;
    return [
      for (final e in all)
        if (e.terms.any((t) => t.contains(q))) e
    ];
  }

  List<TagIcon> _matches(TagIconGroup group) {
    final q = _query.trim().toLowerCase();
    final all = tagIconsIn(group);
    if (q.isEmpty) return all;
    return [
      for (final i in all)
        if (i.key.replaceAll('_', ' ').contains(q) ||
            i.terms.any((t) => t.contains(q)))
          i
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final emojiTyped = _query.trim().isNotEmpty && !isTagIconKey(_query.trim());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 10),
        TextField(
          key: const Key('tag-icon-search'),
          controller: _search,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            hintText: _emojiMode
                ? 'Search emoji, or type your own'
                : 'Search icons, or type an emoji',
            border: const OutlineInputBorder(),
            suffixIcon: widget.icon == null
                ? null
                : IconButton(
                    tooltip: 'No icon',
                    onPressed: () => widget.onChanged(null),
                    icon: const Icon(Icons.backspace_outlined, size: 18),
                  ),
          ),
        ),
        // Typed something that is not a catalog key — offer it as the icon.
        if (emojiTyped) ...[
          const SizedBox(height: 10),
          InkWell(
            key: const Key('tag-icon-use-emoji'),
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              widget.onChanged(_search.text.trim());
              _search.clear();
              setState(() => _query = '');
              SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(_search.text.trim(),
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Use this as the icon',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (_emojiMode)
          for (final group in TagEmojiGroup.values)
            Builder(builder: (context) {
              final matches = _emojiMatches(group);
              if (matches.isEmpty) return const SizedBox.shrink();
              return _PaletteGroup(
                title: _emojiGroupName(group),
                children: [
                  for (final e in matches)
                    _Tile(
                      selected: widget.icon == e.char,
                      onTap: () => widget.onChanged(e.char),
                      // Emoji render as text — Android's own colour font, so
                      // they carry their colour without any tinting from us.
                      child: Text(e.char, style: const TextStyle(fontSize: 22)),
                    ),
                ],
              );
            })
        else
          for (final group in TagIconGroup.values)
            Builder(builder: (context) {
              final matches = _matches(group);
              if (matches.isEmpty) return const SizedBox.shrink();
              return _PaletteGroup(
                title: _groupName(group),
                children: [
                  for (final i in matches)
                    _Tile(
                      selected: widget.icon == i.key,
                      onTap: () => widget.onChanged(i.key),
                      child: Icon(foodIcon(i.key),
                          size: 21,
                          color: widget.icon == i.key
                              ? scheme.onSecondaryContainer
                              : scheme.onSurface),
                    ),
                ],
              );
            }),
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
