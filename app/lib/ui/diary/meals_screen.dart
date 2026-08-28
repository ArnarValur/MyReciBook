// Settings → Meals. The diary's headings and, optionally, the hour each one
// starts — "Breakfast" is whatever hour the user's breakfast actually is,
// which for a night worker is not the morning. Hours are optional per meal;
// with none set the diary just lists the headings as it always has.
//
// Renaming here never rewrites the past: a day file always keeps the name an
// entry was logged under (see DiaryDay), and visibleMealNames still shows any
// old heading a day actually holds.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/diary.dart';
import '../theme.dart';
import '../widgets/skin.dart';
import 'diary_model.dart';

class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealRow {
  _MealRow(String name, this.start) : name = TextEditingController(text: name);
  final TextEditingController name;
  int? start; // minutes past midnight, null = no window

  void dispose() => name.dispose();
}

class _MealsScreenState extends State<MealsScreen> {
  late final List<_MealRow> _rows;

  @override
  void initState() {
    super.initState();
    final model = context.read<DiaryModel>();
    final starts = model.mealStarts;
    _rows = [
      for (final name in model.mealNames)
        _MealRow(name, parseHhMm(starts[name])),
    ];
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _pickTime(_MealRow row) async {
    final start = row.start;
    final picked = await showTimePicker(
      context: context,
      initialTime: start == null
          ? const TimeOfDay(hour: 8, minute: 0)
          : TimeOfDay(hour: start ~/ 60, minute: start % 60),
    );
    if (picked != null) {
      setState(() => row.start = picked.hour * 60 + picked.minute);
    }
  }

  Future<void> _save() async {
    final names = <String>[];
    final starts = <String, String>{};
    for (final row in _rows) {
      final name = row.name.text.trim();
      if (name.isEmpty || names.contains(name)) continue;
      names.add(name);
      if (row.start != null) starts[name] = formatHhMm(row.start!);
    }
    // An emptied list means "the defaults", per AppSettings.mealNames — say
    // so by saving nothing rather than inventing a heading here.
    await context.read<DiaryModel>().setMeals(names, starts);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Meals'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'The diary\'s headings, in the order the day runs. Give a meal '
              'a start time and the diary marks the one that is on now — set '
              'them to your own hours, night shifts included: the windows '
              'follow each other around the clock, not the calendar day.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _rows.length,
              onReorderItem: (from, to) => setState(() {
                _rows.insert(to, _rows.removeAt(from));
              }),
              itemBuilder: (context, i) => _row(context, i),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _rows.add(_MealRow('', null))),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add a meal'),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save meal times'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, int i) {
    final scheme = context.scheme;
    final row = _rows[i];
    return Padding(
      key: ObjectKey(row),
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: i,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.drag_handle_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: row.name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Meal name',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _TimePill(
            start: row.start,
            onTap: () => _pickTime(row),
            onClear: row.start == null
                ? null
                : () => setState(() => row.start = null),
          ),
          if (_rows.length > 1)
            IconButton(
              onPressed: () => setState(() {
                _rows.removeAt(i).dispose();
              }),
              icon: Icon(
                Icons.close_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
              tooltip: 'Remove',
            ),
        ],
      ),
    );
  }
}

/// The meal's start hour as a tappable pill — "from 06:00", or "any time"
/// until one is chosen. The × unsets it without opening the picker.
class _TimePill extends StatelessWidget {
  const _TimePill({required this.start, required this.onTap, this.onClear});

  final int? start;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final set = start != null;
    return Container(
      decoration: BoxDecoration(
        color: set ? scheme.secondaryContainer : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 7, set ? 2 : 12, 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 15,
                    color: set
                        ? scheme.onSecondaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    set ? 'from ${formatHhMm(start!)}' : 'any time',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: set
                          ? scheme.onSecondaryContainer
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (onClear != null)
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 7, 9, 7),
                child: Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
