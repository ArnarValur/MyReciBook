// Editor field widgets — structured inputs for the recipe editors (manual
// entry, import review). They replace the free-text "4 servings" / "25 min"
// pills: the number is stepped or typed, the words are labels the widget
// renders, and each maps straight onto what the recipe file already stores
// (Servings.amount + raw, RecipeTimes.total_min + raw — see domain/recipe.dart).
//
// CoverPickerField gives the editors the cover door the detail screen has:
// camera/gallery through the app-wide PhotoSources, emitting the File that
// LibraryModel's cover seam (saveImported coverImage:) already takes.
//
// All three are controlled widgets: value in, callback out — the screen owns
// the state, same as every TextEditingController-driven field around them.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../domain/recipe.dart';
import '../photo_sources.dart';
import '../theme.dart';
import 'skin.dart';

/// Stadium pill with −/+ around "N servings" — the word is rendered, never
/// typed. Clamped to [min]..[max]; [onChanged] only ever fires inside the
/// range. Needs bounded width (put it in an Expanded, like the old pill).
class ServingsStepper extends StatelessWidget {
  const ServingsStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 99,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  /// "1 serving" / "4 servings" — also exactly what the pill displays, so
  /// the file's raw always matches what the user saw.
  static String labelOf(int value) =>
      value == 1 ? '1 serving' : '$value servings';

  /// The domain form of a stepped value: amount feeds the nutrition math
  /// (servingsAmount prefers it), raw feeds display — the same two fields
  /// imports fill.
  static Servings servingsOf(int value) =>
      Servings(amount: value, raw: labelOf(value));

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(color: context.rb.hairline),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _StepButton(
            key: const Key('servings-minus'),
            icon: Icons.remove_rounded,
            tooltip: 'Fewer servings',
            onTap: value > min
                ? () => onChanged((value - 1).clamp(min, max))
                : null,
          ),
          Expanded(
            child: Text(
              labelOf(value),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          _StepButton(
            key: const Key('servings-plus'),
            icon: Icons.add_rounded,
            tooltip: 'More servings',
            onTap: value < max
                ? () => onChanged((value + 1).clamp(min, max))
                : null,
          ),
        ],
      ),
    );
  }
}

/// 32dp round tap target for the stepper ends; greys out when [onTap] is
/// null (value at the clamp).
class _StepButton extends StatelessWidget {
  const _StepButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    Widget button = InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(
          icon,
          size: 18,
          color: onTap == null
              ? scheme.onSurfaceVariant.withValues(alpha: 0.4)
              : scheme.primary,
        ),
      ),
    );
    final label = tooltip;
    if (label != null) button = Tooltip(message: label, child: button);
    return button;
  }
}

/// The two units the duration pill toggles between.
enum DurationUnit { minutes, hours }

/// Stadium pill: schedule icon, a number field, and a min/hr toggle — "min"
/// is a control, never typed. [onChanged] reports total minutes (null when
/// the field is empty or unparseable). Needs bounded width.
///
/// The domain mapping lives in the statics: [timesOf] builds the
/// RecipeTimes (total_min + raw) the file stores, [rawOf] the raw string.
class DurationField extends StatefulWidget {
  const DurationField({
    super.key,
    this.initialMinutes,
    required this.onChanged,
    this.hint = '25',
    this.label,
    this.onRemoved,
  });

  /// Pre-fill: shown in hours when it divides into clean half-hours
  /// (120 → "2", 270 → "4,5" with hr selected), else in minutes (100 → "100"
  /// with min selected). The 270-min cake read as "270" and invited a unit
  /// flip that used to 60× it (Arnar 2026-08-30).
  final int? initialMinutes;

  /// Total minutes after every edit or unit flip; null = no duration.
  final ValueChanged<int?> onChanged;

  final String hint;

  /// Which duration this is ("Prep", "Refrigerate"…) — shown in the pill in
  /// place of the clock. Null keeps the plain clock pill.
  final String? label;

  /// Shows a small ✕ in the pill; the times editor removes the part with it.
  final VoidCallback? onRemoved;

  /// Pure math seam (tested directly): "1,5" hours → 90. Comma decimals are
  /// normal here (Norwegian keyboards) — same rule as the parse-fix dialog.
  static int? totalMinutesOf(String text, DurationUnit unit) {
    final v = num.tryParse(text.trim().replaceAll(',', '.'));
    if (v == null || v <= 0) return null;
    final minutes = (unit == DurationUnit.hours ? v * 60 : v).round();
    return minutes < 1 ? null : minutes;
  }

  /// "25 min" / "2 hr" / "1 hr 30 min" — the raw form the file stores,
  /// matching the shape the extractor emits and MetaChips display.
  static String? rawOf(int? totalMinutes) => RecipeTimes.fmtMin(totalMinutes);

  /// The domain form: total_min for math, raw for display. Null when there
  /// is no duration — the recipe file simply omits times then.
  static RecipeTimes? timesOf(int? totalMinutes) =>
      totalMinutes == null || totalMinutes <= 0
      ? null
      : RecipeTimes(totalMin: totalMinutes, raw: rawOf(totalMinutes));

  @override
  State<DurationField> createState() => _DurationFieldState();
}

class _DurationFieldState extends State<DurationField> {
  late final TextEditingController _text;
  late DurationUnit _unit;

  /// "270" → "4,5": comma decimals to match what the field accepts.
  static String _hoursText(int minutes) {
    if (minutes % 60 == 0) return '${minutes ~/ 60}';
    var s = (minutes / 60).toStringAsFixed(2);
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return s.replaceAll('.', ',');
  }

  @override
  void initState() {
    super.initState();
    final m = widget.initialMinutes;
    final cleanHours = m != null && m >= 60 && m % 30 == 0;
    _unit = cleanHours ? DurationUnit.hours : DurationUnit.minutes;
    _text = TextEditingController(
      text: m == null ? '' : (cleanHours ? _hoursText(m) : '$m'),
    );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _emit() =>
      widget.onChanged(DurationField.totalMinutesOf(_text.text, _unit));

  void _setUnit(DurationUnit unit) {
    if (unit == _unit) return;
    // The flip preserves the duration — 270 min reads "4,5" hr, never
    // "270 hr". Reinterpreting silently 60×'d an imported time on save
    // (Arnar's cake, 2026-08-30). An empty field just switches the unit.
    final minutes = DurationField.totalMinutesOf(_text.text, _unit);
    setState(() {
      _unit = unit;
      if (minutes != null) {
        _text.text = unit == DurationUnit.hours
            ? _hoursText(minutes)
            : '$minutes';
      }
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      height: 40,
      padding: const EdgeInsets.fromLTRB(13, 0, 5, 0),
      decoration: BoxDecoration(
        border: Border.all(color: context.rb.hairline),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          if (widget.label != null)
            Text(
              widget.label!,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: scheme.primary),
            )
          else
            Icon(Icons.schedule_rounded, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              key: const Key('duration-value'),
              controller: _text,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              onChanged: (_) => _emit(),
              style: Theme.of(context).textTheme.labelMedium,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: widget.hint,
              ),
            ),
          ),
          const SizedBox(width: 4),
          _UnitChip(
            key: const Key('duration-unit-min'),
            label: 'min',
            selected: _unit == DurationUnit.minutes,
            onTap: () => _setUnit(DurationUnit.minutes),
          ),
          const SizedBox(width: 3),
          _UnitChip(
            key: const Key('duration-unit-hr'),
            label: 'hr',
            selected: _unit == DurationUnit.hours,
            onTap: () => _setUnit(DurationUnit.hours),
          ),
          if (widget.onRemoved != null) ...[
            const SizedBox(width: 2),
            InkWell(
              key: const Key('duration-remove'),
              customBorder: const CircleBorder(),
              onTap: widget.onRemoved,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tiny stadium segment for the unit toggle — secondaryContainer when
/// selected, quiet otherwise.
class _UnitChip extends StatelessWidget {
  const _UnitChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? scheme.secondaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 0.2,
            fontWeight: FontWeight.w600,
            color: selected
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Tappable cover slot: the chosen photo, or an "add a cover photo"
/// affordance. Tapping offers camera and gallery through the app-wide
/// PhotoSources (Provider — same seam the detail screen's cover door reads);
/// [onChanged] gets the picked File, or null when the user removes it.
/// Backing out of the sheet or the picker changes nothing.
///
/// The File is exactly what LibraryModel's cover seam takes:
/// saveImported(recipe, images, coverImage: file) / setCover(photo: file).
class CoverPickerField extends StatelessWidget {
  const CoverPickerField({
    super.key,
    required this.file,
    required this.onChanged,
    this.height = 140,
  });

  /// The currently chosen photo, or null for the empty slot.
  final File? file;

  final ValueChanged<File?> onChanged;

  final double height;

  Future<void> _pick(BuildContext context) async {
    final photos = context.read<PhotoSources>();
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (photos.camera != null)
              ListTile(
                key: const Key('cover-field-camera'),
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Take a photo'),
                subtitle: const Text('Snap the dish you just cooked'),
                onTap: () => Navigator.of(sheet).pop('camera'),
              ),
            ListTile(
              key: const Key('cover-field-gallery'),
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(sheet).pop('gallery'),
            ),
            if (file != null)
              ListTile(
                key: const Key('cover-field-remove'),
                leading: const Icon(Icons.hide_image_rounded),
                title: const Text('Remove photo'),
                onTap: () => Navigator.of(sheet).pop('remove'),
              ),
          ],
        ),
      ),
    );
    if (choice == null) return; // dismissed — no change

    File? photo;
    switch (choice) {
      case 'camera':
        photo = await photos.pickOne(photos.camera!);
      case 'gallery':
        photo = await photos.pickOne(photos.gallery);
      case 'remove':
        onChanged(null);
        return;
    }
    // Backing out of the camera/gallery must leave the cover alone — only
    // 'remove' clears it (the detail screen's rule).
    if (photo != null) onChanged(photo);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final theme = Theme.of(context);
    final current = file;

    final Widget slot;
    if (current == null) {
      slot = Container(
        height: height,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          border: Border.all(color: context.rb.hairline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_rounded, size: 22, color: scheme.primary),
            const SizedBox(height: 6),
            Text(
              'Add a cover photo',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.primary,
              ),
            ),
          ],
        ),
      );
    } else {
      slot = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CoverImage(current),
              Positioned(
                right: 8,
                bottom: 8,
                child: IgnorePointer(
                  child: const GlassPill(
                    icon: Icons.edit_rounded,
                    label: 'change',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label: current == null ? 'Add a cover photo' : 'Change cover photo',
      child: InkWell(
        key: const Key('cover-field'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => _pick(context),
        child: slot,
      ),
    );
  }
}
