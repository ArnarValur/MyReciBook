// The diary day screen — MyFitnessPal's shape in this app's skin.
//
// Read top to bottom: which day, how the day is going against the goal, then
// the meals in order with what went in each. Every number on screen is a sum
// of snapshots already in the day file; nothing here reads the pantry.
//
// Undesigned in the mockups (no turn ever drew a diary), so this is built in
// the established idiom — TokenCard rows, SectionLabel headings, the cream
// scaffold and the glass bar's 110px bottom gap — and flagged for a design
// turn on the copy and the totals card.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/diary.dart';
import '../../domain/nutrient_display.dart';
import '../theme.dart';
import '../widgets/skin.dart';
import 'add_food_sheet.dart';
import 'diary_model.dart';
import 'trends_screen.dart';

class DiaryTab extends StatefulWidget {
  const DiaryTab({super.key, this.header});

  /// Drawn above the day strip — the Diary/Pantry segmented control when the
  /// tab is hosted in slot 3. Null on a standalone route.
  final Widget? header;

  @override
  State<DiaryTab> createState() => _DiaryTabState();
}

class _DiaryTabState extends State<DiaryTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DiaryModel>().ensureLoaded();
    });
  }

  Future<void> _addFood(String meal) async {
    await showAddFoodSheet(context, meal: meal);
  }

  /// Trends is a sub-screen, not a tab: the settings-row idiom, the model
  /// handed down by value so the pushed route reads the same diary.
  void _openTrends() {
    Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider<DiaryModel>.value(
        value: context.read<DiaryModel>(),
        child: const TrendsScreen(),
      ),
    ));
  }

  Future<void> _entrySheet(DiaryEntry entry) async {
    final model = context.read<DiaryModel>();
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(entry.name,
                  style: Theme.of(sheetContext).textTheme.titleMedium),
              subtitle: Text(entry.servingSummary),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.tune_rounded),
              title: const Text('Change amount'),
              onTap: () => Navigator.of(sheetContext).pop('amount'),
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz_rounded),
              title: const Text('Move to another meal'),
              onTap: () => Navigator.of(sheetContext).pop('move'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded,
                  color: Theme.of(sheetContext).colorScheme.error),
              title: const Text('Remove from the diary'),
              onTap: () => Navigator.of(sheetContext).pop('remove'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'amount':
        final quantity = await showQuantityDialog(context, entry: entry);
        if (quantity != null) await model.setQuantity(entry, quantity);
      case 'move':
        if (!mounted) return;
        final meal = await showMealPicker(context, names: model.mealNames);
        if (meal != null) await model.moveEntry(entry.id, meal);
      case 'remove':
        await model.removeEntry(entry.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final model = context.watch<DiaryModel>();

    return Scaffold(
      body: SafeArea(
        bottom: false, // content scrolls under the shell's glass bar
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
          children: [
            if (widget.header != null) ...[
              widget.header!,
              const SizedBox(height: 16),
            ],
            _DayStrip(
              date: model.date,
              isToday: model.isToday,
              onShift: model.shiftDay,
              onToday: () => model.openDate(diaryDate(DateTime.now())),
              onTrends: _openTrends,
            ),
            const SizedBox(height: 14),
            _TotalsCard(model: model),
            const SizedBox(height: 22),
            for (final name in model.visibleMealNames) ...[
              _MealSection(
                name: name,
                meal: model.day.meal(name),
                onAdd: () => _addFood(name),
                onEntry: _entrySheet,
              ),
              const SizedBox(height: 18),
            ],
            if (model.loading) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              'Every entry keeps the numbers it was logged with. Correcting a '
              'product later never rewrites a day you already lived.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// `‹  Today · Tue 19 Aug  ›` — the day walker. Forward past today is allowed
/// (planning tomorrow's breakfast is a real thing), so the arrow never dims.
class _DayStrip extends StatelessWidget {
  const _DayStrip({
    required this.date,
    required this.isToday,
    required this.onShift,
    required this.onToday,
    required this.onTrends,
  });

  final String date;
  final bool isToday;
  final Future<void> Function(int) onShift;
  final VoidCallback onToday;
  final VoidCallback onTrends;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    return Row(
      children: [
        IconButton(
          onPressed: () => onShift(-1),
          icon: const Icon(Icons.chevron_left_rounded),
          tooltip: 'Previous day',
        ),
        Expanded(
          child: GestureDetector(
            onTap: isToday ? null : onToday,
            child: Column(
              children: [
                Text(
                  isToday ? 'Today' : longWeekday(date),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontSize: 24, letterSpacing: -0.4),
                ),
                const SizedBox(height: 1),
                Text(
                  longDate(date),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          onPressed: () => onShift(1),
          icon: const Icon(Icons.chevron_right_rounded),
          tooltip: 'Next day',
        ),
        IconButton(
          onPressed: onTrends,
          icon: const Icon(Icons.insights_rounded),
          tooltip: 'Trends',
        ),
      ],
    );
  }
}

/// The day against the goal — MFP's headline line, honest when no goal is set.
class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.model});

  final DiaryModel model;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final total = model.total;
    final eaten = total.kcal ?? 0;
    final goal = model.calorieGoal;
    final left = model.caloriesLeft;
    final over = left != null && left < 0;

    return TokenCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_round(eaten),
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontSize: 32, letterSpacing: -1)),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  goal == null ? 'kcal' : 'of ${_round(goal)} kcal',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
              const Spacer(),
              if (left != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    over
                        ? '${_round(left.abs())} over'
                        : '${_round(left)} left',
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: over ? scheme.error : scheme.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (goal != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (eaten / goal).clamp(0, 1).toDouble(),
                minHeight: 8,
                backgroundColor: scheme.surfaceContainerHigh,
                color: over ? scheme.error : scheme.primary,
              ),
            )
          else
            Text(
              'No daily goal set yet — Settings, under Diary.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final key in const ['fat', 'carbs', 'protein'])
                Expanded(
                  child: _MacroCell(
                    label: nutrientLabel(key),
                    grams: total[key] ?? 0,
                    goal: model.macroGoal(key),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _round(double v) => v.round().toString();
}

class _MacroCell extends StatelessWidget {
  const _MacroCell({required this.label, required this.grams, this.goal});

  final String label;
  final double grams;
  final double? goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.replaceFirst('Carbohydrates', 'Carbs'),
            style: theme.textTheme.labelSmall
                ?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 3),
        Text(
          goal == null
              ? '${grams.round()} g'
              : '${grams.round()} / ${goal!.round()} g',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: goal == null ? 0 : (grams / goal!).clamp(0, 1).toDouble(),
            minHeight: 4,
            backgroundColor: scheme.surfaceContainerHigh,
            color: scheme.secondary,
          ),
        ),
      ],
    );
  }
}

/// One meal heading, its rows, and the add door. An empty meal still draws —
/// MFP's four slots are the shape of the day, not a list that grows.
class _MealSection extends StatelessWidget {
  const _MealSection({
    required this.name,
    required this.meal,
    required this.onAdd,
    required this.onEntry,
  });

  final String name;
  final DiaryMeal? meal;
  final VoidCallback onAdd;
  final Future<void> Function(DiaryEntry) onEntry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final entries = meal?.entries ?? const <DiaryEntry>[];
    final kcal = meal?.total.kcal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SectionLabel(name),
            const Spacer(),
            Text(
              kcal == null ? '—' : '${kcal.round()} kcal',
              style: theme.textTheme.labelMedium?.copyWith(
                  color: kcal == null ? scheme.onSurfaceVariant : null),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final entry in entries) ...[
          _EntryRow(entry: entry, onTap: () => onEntry(entry)),
          const SizedBox(height: 8),
        ],
        InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Icon(Icons.add_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 6),
              Text('Add food',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: scheme.primary)),
            ]),
          ),
        ),
      ],
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, required this.onTap});

  final DiaryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final kcal = entry.total.kcal;
    final subtitle = [
      if ((entry.brand ?? '').isNotEmpty) entry.brand!,
      entry.servingSummary,
    ].join(' · ');

    return TokenCard(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: InkWell(
        onTap: onTap,
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(11)),
            child: Icon(_iconFor(entry.source),
                size: 18, color: scheme.onSecondaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 1),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(kcal == null ? '—' : kcal.round().toString(),
              style: theme.textTheme.titleSmall),
          const SizedBox(width: 2),
          Text('kcal',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
        ]),
      ),
    );
  }

  static IconData _iconFor(String source) => switch (source) {
        DiarySources.recipe => Icons.menu_book_rounded,
        DiarySources.quick => Icons.bolt_rounded,
        _ => Icons.kitchen_rounded,
      };
}

/// "How many?" — the one edit MFP puts everywhere.
Future<double?> showQuantityDialog(BuildContext context,
        {required DiaryEntry entry}) =>
    showAmountDialog(
      context,
      title: entry.name,
      subtitle: 'How many × ${entry.servingLabel ?? 'serving'}?',
      label: 'Servings',
      initial: formatQuantity(entry.quantity),
    );

/// One number, typed. The controller lives in a State so it is disposed with
/// the dialog's own element — disposing it right after `await showDialog`
/// kills it while the exit transition is still rebuilding the field.
Future<double?> showAmountDialog(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String label,
  String? suffix,
  String initial = '',
  String confirm = 'Save',
}) =>
    showDialog<double>(
      context: context,
      builder: (_) => _AmountDialog(
        title: title,
        subtitle: subtitle,
        label: label,
        suffix: suffix,
        initial: initial,
        confirm: confirm,
      ),
    );

class _AmountDialog extends StatefulWidget {
  const _AmountDialog({
    required this.title,
    required this.subtitle,
    required this.label,
    required this.suffix,
    required this.initial,
    required this.confirm,
  });

  final String title;
  final String subtitle;
  final String label;
  final String? suffix;
  final String initial;
  final String confirm;

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = parseAmount(_controller.text);
    if (parsed != null && parsed > 0) Navigator.of(context).pop(parsed);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.subtitle,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                  labelText: widget.label, suffixText: widget.suffix),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          FilledButton(onPressed: _submit, child: Text(widget.confirm)),
        ],
      );
}

/// Which meal? Used by "move" and by the picker when it was opened without one.
Future<String?> showMealPicker(BuildContext context,
        {required List<String> names}) =>
    showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final name in names)
              ListTile(
                title: Text(name),
                onTap: () => Navigator.of(sheetContext).pop(name),
              ),
          ],
        ),
      ),
    );

/// A typed amount, comma or point — a Norwegian keyboard sends "1,5".
double? parseAmount(String raw) {
  final cleaned = raw.trim().replaceAll(',', '.');
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday'
];

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
];

/// 'Tuesday' — the day strip's headline when it isn't today.
String longWeekday(String date) {
  final parsed = DateTime.tryParse(date);
  if (parsed == null) return date;
  return _weekdays[parsed.weekday - 1];
}

/// '19 Aug 2026' — the line under the headline.
String longDate(String date) {
  final parsed = DateTime.tryParse(date);
  if (parsed == null) return date;
  return '${parsed.day} ${_months[parsed.month - 1]} ${parsed.year}';
}
