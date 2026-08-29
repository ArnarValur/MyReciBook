// The recipe row editor — ONE screen for creating ("New Recipe", the 5b
// promise: no AI, no cap) and editing (every recipe, imported or typed).
//
// Row editor (Arnar's turn, 2026-08-19): one row per ingredient that
// structures itself as you type — the deterministic parse shows as chips
// under the line, inline-editable (qty and item swap to tiny fields, the
// unit chip opens an inline option row), with a pantry link chip per row —
// and numbered step rows.
//
// Edit mode (2026-08-20, replacing ImportReviewScreen.edit): the saved
// recipe opens here with its stored parse and links intact, and saves back
// over the same file — envelope (id, source, extraction stamps, notes,
// favorite) untouched. When a line's text changes, the parse re-runs so
// qty/unit/item always match the visible text; the pantry link survives the
// rewording. Linked rows display the product's name via the detail screen's
// linkedIngredientLine rule — display-time substitution only, the file keeps
// the typed text.
//
// DEVIATION (for Arnar to ratify on the S21): no hi-fi mockup exists for
// this screen — the row design was picked from ASCII options 2026-08-19.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../data/saf_store.dart';
import '../domain/ingredient_parse.dart';
import '../domain/product.dart';
import '../domain/recipe.dart';
import '../domain/recipe_nutrition.dart';
import '../domain/validate.dart';
import '../features.dart';
import 'library_model.dart';
import 'pantry/pantry_model.dart';
import 'recipe_detail_screen.dart' show linkedIngredientLine;
import 'theme.dart';
import 'widgets/editor_fields.dart';
import 'widgets/product_picker_sheet.dart';
import 'widgets/skin.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key, this.initial, this.originals = const []});

  /// Edit mode when set: pre-fills everything and saves back over the same
  /// file (ManualProductScreen's `initial:` idiom).
  final Recipe? initial;

  /// Hydrated original screenshots for the provenance pane — the detail
  /// screen already holds them; display-only here.
  final List<File> originals;

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

/// One editable row — an ingredient or a step. Ingredients also carry their
/// pantry link, the origin ingredient when editing a saved recipe, and, when
/// the user corrected the parse by hand, the override.
class _EntryRow {
  _EntryRow([String initial = ''])
    : text = TextEditingController(text: initial);

  final TextEditingController text;
  final FocusNode focus = FocusNode();
  String? productRef;

  /// The saved ingredient this row edits — carries note/group/confidence
  /// through a save untouched. Null for freshly added rows.
  Ingredient? origin;

  /// The saved step this row edits — carries confidence through a save.
  RecipeStep? originStep;

  /// Hand-corrected (or file-stored) parse. Cleared the moment the line's
  /// text changes — a correction belongs to the text it corrected, never to
  /// new text; the live parse takes over so the parse always matches what
  /// the row shows.
  ParsedQty? override;

  ParsedQty get parsed => override ?? parseIngredientLine(text.text);

  void dispose() {
    text.dispose();
    focus.dispose();
  }
}

/// One duration pill: "Prep", "Cook", "Total", or the source's own label
/// ("Refrigerate", "Rise"…). Minutes null = pill shown empty, part not saved.
class _TimePart {
  _TimePart(this.label, this.minutes);

  final String label;
  int? minutes;
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _title = TextEditingController();
  final List<_EntryRow> _ings = [];
  final List<_EntryRow> _steps = [];
  bool _saving = false;

  // Structured metadata (editor_fields). Touched-tracking keeps an edited
  // recipe's original servings/times raw ("6 loaves", "ca. 1 time") intact
  // until the user actually changes the value — raw is never destroyed by a
  // save that didn't touch it.
  int _servingsValue = 4;
  bool _servingsTouched = false;

  // Every duration the file states, one pill each — Prep, Cook, the source's
  // own labels (Refrigerate…), Total. The single-total pill collapsed all of
  // them on save and silently destroyed an import's parts (Arnar 2026-08-30).
  final List<_TimePart> _times = [];
  bool _timesTouched = false;

  // Cover: the shown file, and whether the user changed it this session.
  File? _coverFile;
  bool _coverTouched = false;

  // Inline chip editing — at most one editor open across all rows.
  int? _qtyEditRow;
  int? _itemEditRow;
  int? _unitPickerRow;
  TextEditingController? _inlineCtrl;

  /// Linked rows show a display line instead of their TextField; tapping it
  /// sets this row index to bring the field (and focus) back.
  int? _textEditRow;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _title.text = initial.title;
      _servingsValue = (servingsAmount(initial)?.round() ?? 4).clamp(1, 99);
      _seedTimes(initial.times);
      for (final ing in initial.ingredients) {
        final row = _makeRow(ing.raw)
          ..productRef = ing.productRef
          ..origin = ing;
        // The file's parse (extractor's or a previous save's) rides in as
        // the override: preserved verbatim until the text changes.
        if (ing.qty != null || ing.unit != null || ing.item != null) {
          row.override = ParsedQty(
            qty: ing.qty,
            unit: ing.unit,
            item: ing.item ?? '',
          );
        }
        _ings.add(row);
      }
      for (final step in initial.steps) {
        _steps.add(_makeRow(step.raw)..originStep = step);
      }
      if (initial.cover != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _loadCover());
      }
    }
    if (_ings.isEmpty) _ings.add(_makeRow());
    if (_steps.isEmpty) _steps.add(_makeRow());
    // New recipes get the empty Total pill as the affordance, same as a file
    // without times.
    if (_times.isEmpty) _times.add(_TimePart('Total', null));
  }

  @override
  void dispose() {
    _title.dispose();
    _inlineCtrl?.dispose();
    for (final r in [..._ings, ..._steps]) {
      r.dispose();
    }
    super.dispose();
  }

  _EntryRow _makeRow([String initial = '']) {
    final row = _EntryRow(initial);
    row.focus.addListener(() {
      if (!mounted) return;
      setState(() {
        // A linked row whose field lost focus goes back to its display line.
        final t = _textEditRow;
        if (t != null && t < _ings.length && !_ings[t].focus.hasFocus) {
          _textEditRow = null;
        }
      });
    });
    return row;
  }

  Future<void> _loadCover() async {
    final initial = widget.initial;
    if (initial == null) return;
    File? file;
    try {
      file = await context.read<LibraryModel>().coverFor(initial);
    } catch (_) {} // lost grant: the empty slot stands in
    // Never clobber a cover the user already picked this session.
    if (mounted && !_coverTouched) setState(() => _coverFile = file);
  }

  /// One pill per stated duration, in the order the file states them.
  /// A raw-only file (old manual saves, "ca. 1 time") seeds a Total pill from
  /// the light raw parse; a file with no times at all gets an empty Total
  /// pill as the affordance — same as a brand-new recipe.
  void _seedTimes(RecipeTimes? t) {
    if (t != null) {
      if (t.prepMin != null) {
        _times.add(_TimePart('Prep', t.prepMin!.round()));
      }
      if (t.cookMin != null) {
        _times.add(_TimePart('Cook', t.cookMin!.round()));
      }
      for (final e in t.extra) {
        if (e.min != null) _times.add(_TimePart(e.label, e.min!.round()));
      }
      if (t.totalMin != null) {
        _times.add(_TimePart('Total', t.totalMin!.round()));
      } else if (_times.isEmpty) {
        final parsed = _initialMinutes(t);
        if (parsed != null) _times.add(_TimePart('Total', parsed));
      }
    }
    if (_times.isEmpty) _times.add(_TimePart('Total', null));
  }

  /// Rebuilds the file's times from the pills — every part carried, raw
  /// regenerated so it never lies about the parts. Null when nothing is set.
  RecipeTimes? _rebuiltTimes() {
    int? named(String label) {
      for (final p in _times) {
        if (p.label == label && p.minutes != null) return p.minutes;
      }
      return null;
    }

    final prep = named('Prep');
    final cook = named('Cook');
    final total = named('Total');
    final extras = [
      for (final p in _times)
        if (p.label != 'Prep' &&
            p.label != 'Cook' &&
            p.label != 'Total' &&
            p.minutes != null)
          ExtraTime(label: p.label, min: p.minutes),
    ];
    if (prep == null && cook == null && total == null && extras.isEmpty) {
      return null;
    }
    final t = RecipeTimes(
      prepMin: prep,
      cookMin: cook,
      totalMin: total,
      extra: extras,
    );
    return RecipeTimes(
      prepMin: prep,
      cookMin: cook,
      totalMin: total,
      extra: extras,
      raw: t.compactLine(),
    );
  }

  /// A labeled duration pill bound to `_times[i]`. State follows the part
  /// object (ObjectKey), not the index, so removing a pill can't reseed a
  /// neighbour. Touched only marks when a value actually changes — adding an
  /// empty pill and saving leaves the file byte-identical.
  Widget _timePill(int i) {
    final part = _times[i];
    return KeyedSubtree(
      key: ObjectKey(part),
      child: DurationField(
        label: part.label,
        initialMinutes: part.minutes,
        onChanged: (m) => setState(() {
          if (part.minutes == m) return;
          part.minutes = m;
          _timesTouched = true;
        }),
        onRemoved: () => setState(() {
          if (part.minutes != null) _timesTouched = true;
          _times.remove(part);
        }),
      ),
    );
  }

  /// The add-time door: the labels an import can arrive with, minus the ones
  /// already on screen, plus a free-text custom label.
  Future<void> _addTimePart() async {
    const suggestions = [
      'Prep',
      'Cook',
      'Total',
      'Refrigerate',
      'Rise',
      'Marinate',
      'Rest',
    ];
    final present = {for (final p in _times) p.label};
    final label = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final s in suggestions)
              if (!present.contains(s))
                ListTile(
                  key: Key('add-time-$s'),
                  leading: const Icon(Icons.schedule_rounded),
                  title: Text(s),
                  onTap: () => Navigator.of(sheet).pop(s),
                ),
            ListTile(
              key: const Key('add-time-custom'),
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Something else…'),
              onTap: () async {
                final custom = await _askCustomLabel(sheet);
                if (custom != null && sheet.mounted) {
                  Navigator.of(sheet).pop(custom);
                }
              },
            ),
          ],
        ),
      ),
    );
    if (label == null || label.trim().isEmpty || !mounted) return;
    setState(() => _times.add(_TimePart(label.trim(), null)));
  }

  Future<String?> _askCustomLabel(BuildContext sheet) => showDialog<String>(
    context: sheet,
    builder: (dctx) {
      final ctrl = TextEditingController();
      return AlertDialog(
        title: const Text('Name this time'),
        content: TextField(
          key: const Key('custom-time-label'),
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'e.g. Proof'),
          onSubmitted: (v) => Navigator.of(dctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dctx).pop(ctrl.text),
            child: const Text('Add'),
          ),
        ],
      );
    },
  );

  /// Pre-fill for the duration pill: the structured total when the file has
  /// one, else a light read of the raw ("25 min", "1 hr 30 min", "1,5 hr").
  static int? _initialMinutes(RecipeTimes? times) {
    if (times == null) return null;
    final total = times.totalMin;
    if (total != null && total > 0) return total.round();
    final raw = times.raw?.toLowerCase();
    if (raw == null || raw.isEmpty) return null;
    num sum = 0;
    final h = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(?:hours?|hrs?|hr|h|timer?)(?![a-z])',
    ).firstMatch(raw);
    final m = RegExp(r'(\d+(?:[.,]\d+)?)\s*min').firstMatch(raw);
    if (h != null) sum += num.parse(h.group(1)!.replaceAll(',', '.')) * 60;
    if (m != null) sum += num.parse(m.group(1)!.replaceAll(',', '.'));
    if (h == null && m == null) {
      final n = RegExp(r'\d+(?:[.,]\d+)?').firstMatch(raw);
      if (n != null) sum = num.parse(n.group(0)!.replaceAll(',', '.'));
    }
    final r = sum.round();
    return r < 1 ? null : r;
  }

  /// Pantry the screen can reach, or null: flag off, or no model above
  /// (bare harness) — either way the link chips degrade to nothing.
  PantryModel? _pantry() {
    if (!kPantryEnabled) return null;
    try {
      return context.read<PantryModel>();
    } catch (_) {
      return null;
    }
  }

  // --- row plumbing, shared by both lists ---

  void _addRow(List<_EntryRow> rows) {
    setState(() => rows.add(_makeRow()));
    // Focus the new row on the next frame — it has no element yet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) rows.last.focus.requestFocus();
    });
  }

  void _removeRow(List<_EntryRow> rows, int i) {
    setState(() {
      _closeInlineEditors();
      final gone = rows.removeAt(i);
      // Dispose after the frame — the field may still be unmounting.
      WidgetsBinding.instance.addPostFrameCallback((_) => gone.dispose());
      if (rows.isEmpty) rows.add(_makeRow());
    });
  }

  /// Enter on a row: hop to the next one, growing the list from the last.
  void _submitRow(List<_EntryRow> rows, int i) {
    if (i == rows.length - 1) {
      _addRow(rows);
    } else {
      rows[i + 1].focus.requestFocus();
    }
  }

  /// Any open inline chip editor closes uncommitted. Call inside setState.
  void _closeInlineEditors() {
    _qtyEditRow = null;
    _itemEditRow = null;
    _unitPickerRow = null;
    final ctrl = _inlineCtrl;
    _inlineCtrl = null;
    if (ctrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.dispose());
    }
  }

  // --- ingredient rows ---

  Future<void> _pickLink(_EntryRow row, PantryModel pantry) async {
    await pantry.ensureLoaded();
    if (!mounted) return;
    final item = row.parsed.item;
    final name = item.isEmpty ? row.text.text : item;
    final pick = await showProductPickerSheet(
      context,
      pantry: pantry,
      title: 'Which product is "$name"?',
      allowUnlink: true,
    );
    if (pick == null || !mounted) return; // dismissed — no change
    setState(() => row.productRef = pick.product?.id);
  }

  /// "+ Add from pantry": pick first, then the row arrives pre-linked with
  /// the product's name as its text — type the amount in front of it.
  Future<void> _addFromPantry(PantryModel pantry) async {
    await pantry.ensureLoaded();
    if (!mounted) return;
    final pick = await showProductPickerSheet(
      context,
      pantry: pantry,
      title: 'Add which product?',
    );
    final id = pick?.product?.id;
    if (id == null || !mounted) return;
    final product = pantry.byId(id);
    if (product == null) return;
    setState(() {
      // Reuse a trailing empty row instead of stranding it above the new one.
      final row = _ings.last.text.text.trim().isEmpty ? _ings.last : null;
      final target = row ?? _makeRow();
      if (row == null) _ings.add(target);
      target.text.text = product.name;
      target.productRef = id;
      target.override = null;
      // Open the field straight away — the linked display line would
      // otherwise swallow the "type the amount in front" invitation.
      _textEditRow = _ings.length - 1;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final f = _ings.last.focus;
      f.requestFocus();
      // Caret at the front — the amount goes before the name.
      _ings.last.text.selection = const TextSelection.collapsed(offset: 0);
    });
  }

  // --- inline parse corrections (the "Fix the reading" dialog, dissolved
  //     into the chips themselves) ---

  void _openQtyEdit(int i) {
    final parsed = _ings[i].parsed;
    setState(() {
      _closeInlineEditors();
      _qtyEditRow = i;
      _inlineCtrl = TextEditingController(
        text: parsed.qty == null ? '' : _trimNum(parsed.qty!),
      );
    });
  }

  void _commitQty(int i, String text) {
    if (_qtyEditRow != i) return; // already committed/closed
    final row = _ings[i];
    final cur = row.parsed;
    setState(() {
      row.override = ParsedQty(
        qty: num.tryParse(text.trim().replaceAll(',', '.')),
        unit: cur.unit,
        item: cur.item,
      );
      _closeInlineEditors();
    });
  }

  void _openItemEdit(int i) {
    setState(() {
      _closeInlineEditors();
      _itemEditRow = i;
      _inlineCtrl = TextEditingController(text: _ings[i].parsed.item);
    });
  }

  void _commitItem(int i, String text) {
    if (_itemEditRow != i) return;
    final row = _ings[i];
    final cur = row.parsed;
    setState(() {
      row.override = ParsedQty(qty: cur.qty, unit: cur.unit, item: text.trim());
      _closeInlineEditors();
    });
  }

  void _toggleUnitPicker(int i) {
    setState(() {
      final wasOpen = _unitPickerRow == i;
      _closeInlineEditors();
      if (!wasOpen) _unitPickerRow = i;
    });
  }

  void _setUnit(int i, String? unit) {
    final row = _ings[i];
    final cur = row.parsed;
    setState(() {
      row.override = ParsedQty(qty: cur.qty, unit: unit, item: cur.item);
      _closeInlineEditors();
    });
  }

  /// Unit options for a row. Linked rows offer the units that make sense on
  /// the product's base: volume products get the ml family (+ the spoons),
  /// weight products the gram family (+ piece). Unlinked rows get the full
  /// common set. Canonical tokens only ("ss"/"ts"/"stk" typed in a line
  /// already parse to tbsp/tsp/piece — the file and the chips speak
  /// canonical, so the menu does too).
  List<String> _unitOptions(_EntryRow row, PantryModel? pantry) {
    final linked = row.productRef == null
        ? null
        : pantry?.byId(row.productRef!);
    if (linked == null) return _commonUnits;
    return _isMlBased(linked) ? _mlUnits : _gUnits;
  }

  static const _mlUnits = ['ml', 'dl', 'l', 'tbsp', 'tsp'];
  static const _gUnits = ['g', 'kg', 'piece'];
  static const _commonUnits = [
    'g', 'kg', 'ml', 'cl', 'dl', 'l', 'tsp', 'tbsp', 'cup', 'piece',
    'pinch', 'can', // the parse's canonical names (domain/ingredient_parse)
  ];

  /// A product measured in millilitres: its pack quantity ("1 l", "33 cl")
  /// or any named portion ("1 dl") says so. No volume token anywhere reads
  /// as a weight product — the honest default for food.
  static bool _isMlBased(Product p) {
    final hay = [
      p.quantity ?? '',
      for (final s in p.servings) s.label,
    ].join(' ').toLowerCase();
    return RegExp(r'(^|\d|\s)(ml|cl|dl|l)\b').hasMatch(hay);
  }

  static String _trimNum(num v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  // --- save ---

  static List<_EntryRow> _filled(List<_EntryRow> rows) => [
    for (final r in rows)
      if (r.text.text.trim().isNotEmpty) r,
  ];

  Ingredient _ingredientOf(_EntryRow row) {
    final parsed = row.parsed;
    final origin = row.origin;
    return Ingredient(
      raw: row.text.text.trim(),
      // The parse (or its correction) is stored as-is: what the chips show
      // is what the file says — never a stale parse behind new text.
      qty: parsed.qty,
      unit: parsed.unit,
      item: parsed.item.isEmpty ? null : parsed.item,
      // Fields the row editor doesn't touch ride through from the file.
      note: origin?.note,
      group: origin?.group,
      confidence: origin?.confidence,
      productRef: row.productRef,
    );
  }

  RecipeStep _stepOf(_EntryRow row) {
    final raw = row.text.text.trim();
    final origin = row.originStep;
    return origin == null ? RecipeStep(raw: raw) : origin.copyWith(raw: raw);
  }

  Future<void> _save() async {
    final initial = widget.initial;
    final Recipe recipe;
    if (initial == null) {
      recipe = Recipe(
        schemaVersion: Recipe.currentSchemaVersion,
        id: const Uuid().v4(),
        title: _title.text.trim(),
        // No extraction envelope, no images: nothing was extracted (rule 2 —
        // metadata is stamped by our code only when it is true).
        source: RecipeSource(
          type: 'manual',
          importedAt: DateTime.now().toIso8601String(),
        ),
        // Structured from the first save: amount + raw exactly as displayed
        // (what recipe_nutrition prefers).
        servings: ServingsStepper.servingsOf(_servingsValue),
        times: _rebuiltTimes(),
        // Born parsed (Arnar, 2026-08-19): the parse — or the user's
        // correction of it — and the pantry link are stored on save.
        ingredients: [for (final r in _filled(_ings)) _ingredientOf(r)],
        steps: [for (final r in _filled(_steps)) _stepOf(r)],
      );
    } else {
      // Save-in-place: same id and file; source, extraction stamps, notes,
      // favorite, tags all ride through copyWith untouched. Servings/times
      // only change when the user touched them — an untouched "6 loaves"
      // raw survives the save.
      recipe = initial.copyWith(
        title: _title.text.trim(),
        ingredients: [for (final r in _filled(_ings)) _ingredientOf(r)],
        steps: [for (final r in _filled(_steps)) _stepOf(r)],
        servings: _servingsTouched
            ? ServingsStepper.servingsOf(_servingsValue)
            : null,
        times: _timesTouched ? _rebuiltTimes() : null,
        clearTimes: _timesTouched && _rebuiltTimes() == null,
        clearCover: _coverTouched && _coverFile == null,
      );
    }

    final blocking = fileProblems(
      recipe.toJson(),
    ).where(isSaveBlocking).toList();
    if (blocking.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(blocking.join(' · '))));
      return;
    }

    setState(() => _saving = true);
    final Recipe saved;
    try {
      // Empty cachedImages keeps original_images intact (store contract).
      // The cover file only travels when this session picked one — passing
      // the already-stored file back would just copy it onto itself.
      saved = await context.read<LibraryModel>().saveImported(
        recipe,
        const [],
        coverImage: _coverTouched ? _coverFile : null,
      );
    } on GrantLostException {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Folder access was lost — your recipe is kept here. '
            'Try again, or go back and re-pick your folder.',
          ),
        ),
      );
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      return;
    }
    // Pops with the saved Recipe — the detail screen awaits it in edit mode.
    if (mounted) Navigator.of(context).pop(saved);
  }

  // --- widgets ---

  /// A tiny muted parse chip — the structure the line was read as. Tap to
  /// correct it in place.
  Widget _parseChip(
    String label,
    VoidCallback onTap, {
    Key? key,
    bool active = false,
  }) {
    final scheme = context.scheme;
    return InkWell(
      key: key,
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: active
              ? scheme.secondaryContainer
              : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: active
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  /// The tiny in-place field a qty/item chip becomes when tapped.
  Widget _inlineEdit({
    required Key fieldKey,
    required double width,
    TextInputType? keyboardType,
    required ValueChanged<String> onDone,
  }) {
    final ctrl = _inlineCtrl!;
    final scheme = context.scheme;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.primary, width: 1),
      ),
      child: TextField(
        key: fieldKey,
        controller: ctrl,
        autofocus: true,
        keyboardType: keyboardType,
        style: Theme.of(context).textTheme.labelSmall,
        decoration: const InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
        ),
        onSubmitted: onDone,
        onTapOutside: (_) => onDone(ctrl.text),
      ),
    );
  }

  Widget _unitOptionChip(int i, String? unit, {required bool selected}) {
    return _parseChip(
      unit ?? 'none',
      () => _setUnit(i, unit),
      key: Key('unit-option-${unit ?? 'none'}'),
      active: selected,
    );
  }

  Widget _ingredientRow(int i, PantryModel? pantry) {
    final row = _ings[i];
    final hasText = row.text.text.trim().isNotEmpty;
    final parsed = row.parsed;
    // A product deleted mid-session resolves to null → the chip honestly
    // falls back to 'Link' (dangling refs are display noise, never errors).
    final linked = row.productRef == null
        ? null
        : pantry?.byId(row.productRef!);
    final onlyEmptyRow = _ings.length == 1 && !hasText;
    // Linked rows show the product's name in the line (the detail screen's
    // substitution rule) — the typed text comes back the moment the row is
    // tapped for editing, and stays what the file stores.
    final showLinkedLine =
        linked != null && hasText && !row.focus.hasFocus && _textEditRow != i;

    final Widget line;
    if (showLinkedLine) {
      line = InkWell(
        key: Key('linked-line-$i'),
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _textEditRow = i),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: linkedIngredientLine(_ingredientOf(row), linked.name),
                ),
                const WidgetSpan(child: SizedBox(width: 5)),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(
                    Icons.kitchen_rounded,
                    size: 12,
                    color: context.scheme.primary,
                  ),
                ),
              ],
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    } else {
      line = TextField(
        key: Key('manual-ing-$i'),
        controller: row.text,
        focusNode: row.focus,
        autofocus: _textEditRow == i,
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => _submitRow(_ings, i),
        // Re-parse on every keystroke: the override belonged to the old
        // text. The pantry link survives the rewording (productRef stays).
        onChanged: (_) => setState(() => row.override = null),
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: const InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: 'e.g. 2 dl melk',
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TokenCard(
        padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: line),
                if (!onlyEmptyRow)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 17,
                      color: context.scheme.onSurfaceVariant,
                    ),
                    onPressed: () => _removeRow(_ings, i),
                    tooltip: 'Remove',
                  ),
              ],
            ),
            if (hasText) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (_qtyEditRow == i)
                    _inlineEdit(
                      fieldKey: Key('qty-edit-$i'),
                      width: 56,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onDone: (t) => _commitQty(i, t),
                    )
                  else
                    _parseChip(
                      parsed.qty == null ? '?' : _trimNum(parsed.qty!),
                      () => _openQtyEdit(i),
                      key: Key('ing-qty-$i'),
                    ),
                  _parseChip(
                    parsed.unit ?? 'unit?',
                    () => _toggleUnitPicker(i),
                    key: Key('ing-unit-$i'),
                    active: _unitPickerRow == i,
                  ),
                  if (_itemEditRow == i)
                    _inlineEdit(
                      fieldKey: Key('item-edit-$i'),
                      width: 120,
                      onDone: (t) => _commitItem(i, t),
                    )
                  else
                    _parseChip(
                      parsed.item.isEmpty ? '?' : parsed.item,
                      () => _openItemEdit(i),
                      key: Key('ing-item-$i'),
                    ),
                  if (pantry != null)
                    MetaChip(
                      icon: linked == null
                          ? Icons.link_rounded
                          : Icons.kitchen_rounded,
                      // The product's name lives in the line now — the chip
                      // is just the door to relink/unlink.
                      label: linked == null ? 'Link' : 'Linked',
                      onTap: () => _pickLink(row, pantry),
                    ),
                ],
              ),
            ],
            if (_unitPickerRow == i) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final u in _unitOptions(row, pantry))
                    _unitOptionChip(i, u, selected: parsed.unit == u),
                  _unitOptionChip(i, null, selected: parsed.unit == null),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stepRow(int i) {
    final row = _steps[i];
    final onlyEmptyRow = _steps.length == 1 && row.text.text.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TokenCard(
        padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                '${i + 1}.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: context.scheme.primary),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                key: Key('manual-step-$i'),
                controller: row.text,
                focusNode: row.focus,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _submitRow(_steps, i),
                onChanged: (_) => setState(() {}),
                maxLines: null,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.4),
                decoration: const InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'What happens next?',
                ),
              ),
            ),
            if (!onlyEmptyRow)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.close_rounded,
                  size: 17,
                  color: context.scheme.onSurfaceVariant,
                ),
                onPressed: () => _removeRow(_steps, i),
                tooltip: 'Remove',
              ),
          ],
        ),
      ),
    );
  }

  Widget _addButton(String label, VoidCallback onTap) {
    final scheme = context.scheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Icon(Icons.add_rounded, size: 18, color: scheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: scheme.primary),
            ),
          ],
        ),
      ),
    );
  }

  /// Provenance pane for edited imports — the same "tap to see what we
  /// read" door the import review has, because the original never stops
  /// mattering while the text is being changed.
  Widget _sourcePane(ThemeData theme, ColorScheme scheme) {
    final sourceUrl = widget.initial?.source.url;
    final originals = widget.originals;
    final fromLink = originals.isEmpty && sourceUrl != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        key: const Key('edit-originals-pane'),
        borderRadius: BorderRadius.circular(10),
        onTap: fromLink || originals.isEmpty
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => OriginalsViewer(images: originals),
                ),
              ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 52,
                height: 76,
                child: fromLink
                    ? ColoredBox(
                        color: scheme.surfaceContainerHigh,
                        child: Icon(
                          Icons.link_rounded,
                          size: 24,
                          color: scheme.onSurfaceVariant,
                        ),
                      )
                    : CoverImage(originals.firstOrNull),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fromLink
                        ? 'From a link'
                        : originals.length > 1
                        ? 'Original screenshots · ${originals.length}'
                        : 'Original screenshot',
                    style: theme.textTheme.titleSmall?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fromLink
                        ? (Uri.tryParse(sourceUrl)?.host ?? sourceUrl)
                        : 'tap to see what we read',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (!fromLink)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.swap_horiz_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final pantry = _pantry();
    final showSourcePane =
        _isEdit &&
        (widget.originals.isNotEmpty || widget.initial?.source.url != null);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const AppBackButton(),
                  Text(
                    _isEdit ? 'Edit recipe' : 'New Recipe',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: [
                  if (showSourcePane) _sourcePane(theme, scheme),
                  CoverPickerField(
                    file: _coverFile,
                    onChanged: (f) => setState(() {
                      _coverFile = f;
                      _coverTouched = true;
                    }),
                  ),
                  const SizedBox(height: 12),
                  TokenCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
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
                              hintText: 'Recipe title',
                            ),
                          ),
                        ),
                        Icon(
                          Icons.edit_rounded,
                          size: 19,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ServingsStepper(
                          value: _servingsValue,
                          onChanged: (v) => setState(() {
                            _servingsValue = v;
                            _servingsTouched = true;
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _times.isEmpty
                            ? const SizedBox.shrink()
                            : _timePill(0),
                      ),
                    ],
                  ),
                  for (var i = 1; i < _times.length; i += 2) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _timePill(i)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: i + 1 < _times.length
                              ? _timePill(i + 1)
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('add-time'),
                      onPressed: _addTimePart,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add time'),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const SectionLabel('Ingredients'),
                  const SizedBox(height: 4),
                  Text(
                    'Type a line like "2 dl melk" — it reads itself. Link a '
                    'line to your pantry and the recipe can count calories.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _ings.length; i++)
                    _ingredientRow(i, pantry),
                  _addButton('Add ingredient', () => _addRow(_ings)),
                  if (pantry != null)
                    _addButton('Add from pantry', () => _addFromPantry(pantry)),
                  const SizedBox(height: 14),
                  const SectionLabel('Steps'),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _steps.length; i++) _stepRow(i),
                  _addButton('Add step', () => _addRow(_steps)),
                  const SizedBox(height: 16),
                  if (!_isEdit) ...[
                    Text(
                      'Typed-in recipes are always unlimited — no AI involved.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_isEdit ? 'Save changes' : 'Save to cookbook'),
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
