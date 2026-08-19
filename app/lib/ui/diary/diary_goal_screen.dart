// Daily goal — the number the diary measures the day against.
//
// Grams, not percentages. MyFitnessPal makes you set a macro split and then
// hides the grams behind it; a label prints grams, a diary row shows grams,
// so the goal is grams too. The percentage of calories each one accounts for
// is shown as you type, which is the part the split was actually for.
//
// Everything is optional. No goal set means the diary shows what you ate and
// says so, instead of measuring you against a number nobody chose.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../widgets/skin.dart';
import 'diary_model.dart';
import 'diary_tab.dart' show parseAmount;

class DiaryGoalScreen extends StatefulWidget {
  const DiaryGoalScreen({super.key});

  @override
  State<DiaryGoalScreen> createState() => _DiaryGoalScreenState();
}

class _DiaryGoalScreenState extends State<DiaryGoalScreen> {
  final _kcal = TextEditingController();
  final _macros = {
    'fat': TextEditingController(),
    'carbs': TextEditingController(),
    'protein': TextEditingController(),
  };

  /// Kilocalories per gram — the Atwater factors every food label is built on.
  static const _perGram = {'fat': 9.0, 'carbs': 4.0, 'protein': 4.0};

  static const _labels = {
    'fat': 'Fat',
    'carbs': 'Carbohydrates',
    'protein': 'Protein',
  };

  @override
  void initState() {
    super.initState();
    final model = context.read<DiaryModel>();
    final kcal = model.calorieGoal;
    if (kcal != null) _kcal.text = kcal.round().toString();
    for (final key in _macros.keys) {
      final g = model.macroGoal(key);
      if (g != null) _macros[key]!.text = g.round().toString();
    }
  }

  @override
  void dispose() {
    _kcal.dispose();
    for (final c in _macros.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final model = context.read<DiaryModel>();
    await model.setCalorieGoal(parseAmount(_kcal.text));
    for (final key in _macros.keys) {
      await model.setMacroGoal(key, parseAmount(_macros[key]!.text));
    }
    if (mounted) Navigator.of(context).pop();
  }

  /// What the typed macros add up to, in calories — the sanity check MFP's
  /// percentage wheel was really doing.
  double get _macroCalories {
    var total = 0.0;
    for (final key in _macros.keys) {
      final g = parseAmount(_macros[key]!.text) ?? 0;
      total += g * _perGram[key]!;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final kcalGoal = parseAmount(_kcal.text);
    final macroKcal = _macroCalories;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Daily goal'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'MyReciBook does not work out a goal for you — it has no idea '
              'what you weigh or what you are training for. Put in the numbers '
              'you were given, or leave them blank and the diary just counts.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 22),
            const SectionLabel('Calories'),
            const SizedBox(height: 8),
            TextField(
              controller: _kcal,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                  labelText: 'A day', suffixText: 'kcal'),
            ),
            const SizedBox(height: 24),
            const SectionLabel('Macros'),
            const SizedBox(height: 8),
            for (final key in _macros.keys) ...[
              TextField(
                controller: _macros[key],
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: _labels[key],
                  suffixText: 'g',
                  helperText: _share(key, kcalGoal),
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (kcalGoal != null && macroKcal > 0) ...[
              const SizedBox(height: 4),
              TokenCard(
                radius: 14,
                padding: const EdgeInsets.all(13),
                child: Text(
                  _reconciliation(kcalGoal, macroKcal),
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                ),
              ),
              const SizedBox(height: 18),
            ] else
              const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save goal'),
            ),
          ],
        ),
      ),
    );
  }

  /// "36% of 2 100 kcal" under each macro field.
  String? _share(String key, double? kcalGoal) {
    if (kcalGoal == null || kcalGoal <= 0) return null;
    final grams = parseAmount(_macros[key]!.text);
    if (grams == null || grams <= 0) return null;
    final pct = (grams * _perGram[key]! / kcalGoal * 100).round();
    return '$pct% of ${kcalGoal.round()} kcal';
  }

  /// Says plainly when the macros and the calorie goal disagree, instead of
  /// silently rounding one into the other.
  static String _reconciliation(double kcalGoal, double macroKcal) {
    final diff = macroKcal - kcalGoal;
    if (diff.abs() <= kcalGoal * 0.03) {
      return 'Your macros add up to ${macroKcal.round()} kcal — that matches '
          'the calorie goal.';
    }
    return diff > 0
        ? 'Your macros add up to ${macroKcal.round()} kcal, which is '
            '${diff.round()} more than the calorie goal. Both are saved as '
            'you typed them.'
        : 'Your macros add up to ${macroKcal.round()} kcal, which leaves '
            '${diff.abs().round()} kcal the macros do not account for. Both '
            'are saved as you typed them.';
  }
}
