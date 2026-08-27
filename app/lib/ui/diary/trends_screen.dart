// Trends — the diary over time.
//
// Pushed from the diary's date row, same depth as the product page: no bottom
// nav, one back arrow. Five zoom levels; everything on screen is worked out
// from the day files already on the phone, which is why the footer can say
// nothing leaves it and be telling the truth. There is no network call on this
// route and there must never be one.
//
// The screen changes shape with the zoom, because the question changes with
// it. Week and month: what did the days look like, and which nutrients did the
// labels actually carry. Three months and wider: the chart stops being the
// point and the ledger of records is.
//
// Nothing here scores the user. "Days logged 178 of 239" is a count next to
// the days that were available — never a percentage, a badge, or a nudge.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/diary_stats.dart';
import '../../domain/nutrient_display.dart';
import '../theme.dart';
import '../widgets/skin.dart';
import 'diary_model.dart';
import 'trends_chart.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  TrendRange _range = TrendRange.week;
  DiaryStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load(_range);
    });
  }

  /// Read the range, then compute. The model caches the days it has already
  /// read this session, so coming back to a range is free — the first look at
  /// a year is the only one that touches the folder.
  Future<void> _load(TrendRange range) async {
    setState(() {
      _range = range;
      _loading = true;
    });
    final model = context.read<DiaryModel>();
    final now = DateTime.now();
    final window = trendWindow(range, now);
    final days = await model.loadRange(window.start, window.last);
    if (!mounted || range != _range) return;
    setState(() {
      _stats = computeDiaryStats(range: range, today: now, days: days);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final stats = _stats;
    final goal = context.watch<DiaryModel>().calorieGoal;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Trends'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
          children: [
            _RangeBar(range: _range, onPick: _load),
            const SizedBox(height: 12),
            if (stats == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: LinearProgressIndicator(),
              )
            else ...[
              _EnergyCard(stats: stats, goal: goal),
              const SizedBox(height: 10),
              if (_range.showsMicros) ...[
                _MacroCard(stats: stats),
                const SizedBox(height: 10),
                _MicrosCard(stats: stats),
                const SizedBox(height: 12),
                Text(
                  'Averages only count days that measured. Blank stays blank '
                  '— never zero.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant, height: 1.45),
                ),
              ] else ...[
                _RecordsCard(records: stats.records),
                const SizedBox(height: 12),
                Text(
                  'Counted from the diary files on this phone. Nothing leaves '
                  'it.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant, height: 1.45),
                ),
              ],
              if (_loading) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// `W · M · 3M · 6M · Y` — the zoom.
class _RangeBar extends StatelessWidget {
  const _RangeBar({required this.range, required this.onPick});

  final TrendRange range;
  final void Function(TrendRange) onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final rb = context.rb;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final option in TrendRange.values)
            Expanded(
              child: Semantics(
                selected: option == range,
                button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: option == range ? null : () => onPick(option),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: option == range
                        ? BoxDecoration(
                            color: scheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: rb.cardShadow,
                          )
                        : null,
                    child: Text(
                      option.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: option == range
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: option == range
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }
}

/// The headline number and the bars under it.
class _EnergyCard extends StatelessWidget {
  const _EnergyCard({required this.stats, required this.goal});

  final DiaryStats stats;

  /// Set a goal and the dashed line becomes the goal. Until then it anchors on
  /// the average — a line the diary measured, not one it invented.
  final double? goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final average = stats.averageKcal;

    return TokenCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                average == null ? '—' : groupedNumber(average),
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontSize: 26, letterSpacing: -0.5),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    // Never "avg / day": a day nobody logged is not a day of
                    // zero calories, so it is not in the divisor either.
                    average == null
                        ? 'nothing logged · ${stats.window.caption}'
                        : 'kcal avg / logged day · ${stats.window.caption}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TrendChart(
            buckets: stats.buckets,
            guide: goal ?? average,
            guideLabel:
                goal != null ? 'goal' : (average == null ? null : 'avg'),
            semanticsLabel: _chartWords(stats, average),
          ),
          // A diary with three logged days says so, rather than letting a
          // convincing-looking chart imply the other four were empty plates.
          if (stats.daysLogged < stats.daysAvailable) ...[
            const SizedBox(height: 8),
            Text(
              stats.daysLogged == 0
                  ? 'No days logged in this range yet.'
                  : 'From ${stats.daysLogged} of ${stats.daysAvailable} days.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  static String _chartWords(DiaryStats stats, double? average) {
    if (average == null) {
      return 'Energy chart, nothing logged in ${stats.window.caption}.';
    }
    return 'Energy chart, ${stats.window.caption}: '
        '${groupedNumber(average)} kcal average per logged day, from '
        '${stats.daysLogged} of ${stats.daysAvailable} days.';
  }
}

/// Where the energy came from. The three brand hues, once each — tertiary is
/// out of its CTA cage here on purpose: this is data, not chrome.
class _MacroCard extends StatelessWidget {
  const _MacroCard({required this.stats});

  final DiaryStats stats;

  Color _hue(BuildContext context, String key) => switch (key) {
        'fat' => context.scheme.tertiary,
        'carbs' => context.scheme.primary,
        _ => context.scheme.secondary,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final shares = stats.macros;

    return TokenCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Where the energy came from'),
          const SizedBox(height: 8),
          if (shares.isEmpty)
            Text(
              'No day in this range recorded fat, carbs or protein.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    // Already in fat / carbs / protein order — the bar reads
                    // left to right in the same order as the legend below it.
                    for (final share in shares)
                      Expanded(
                        flex: (share.share * 1000).round().clamp(1, 1000),
                        child: ColoredBox(color: _hue(context, share.key)),
                      )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                for (final share in shares)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _hue(context, share.key)),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${_short(share.key)} ${(share.share * 100).round()}% '
                        '· ${share.gramsPerDay.round()} g/day',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  )
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _short(String key) =>
      key == 'carbs' ? 'Carbs' : nutrientLabel(key);
}

/// Every nutrient field the logged days actually carry, with its coverage.
class _MicrosCard extends StatelessWidget {
  const _MicrosCard({required this.stats});

  final DiaryStats stats;

  /// Dots stop being readable long before a month's worth fit, so past this
  /// many the fraction carries the coverage on its own.
  static const _maxDots = 10;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final rows = stats.micros;

    return TokenCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Micros · avg per day'),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                stats.isEmpty
                    ? 'Nothing logged in this range yet.'
                    : 'None of the foods logged here carried anything beyond '
                        'energy and the three macros.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: i == rows.length - 1
                  ? null
                  : BoxDecoration(
                      border: Border(
                          bottom: BorderSide(color: context.rb.separator))),
              child: _MicroRowView(row: rows[i], dots: _dots(rows[i])),
            ),
        ],
      ),
    );
  }

  static bool _dots(MicroRow row) => row.coverage.length <= _maxDots;
}

class _MicroRowView extends StatelessWidget {
  const _MicroRowView({required this.row, required this.dots});

  final MicroRow row;
  final bool dots;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final (value, unit) = formatNutrient(row.key, row.average);

    return Semantics(
      label: '${ledgerLabel(row.key)}, $value $unit average, measured on '
          '${row.daysMeasured} of ${row.daysAvailable} days',
      child: ExcludeSemantics(
        child: Row(
          children: [
            Expanded(
              child: Text(ledgerLabel(row.key),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge),
            ),
            const SizedBox(width: 8),
            Text('$value $unit', style: theme.textTheme.titleSmall),
            if (dots) ...[
              const SizedBox(width: 8),
              CoverageDots(coverage: row.coverage),
            ],
            const SizedBox(width: 8),
            Text(
              '${row.daysMeasured}/${row.daysAvailable}',
              textAlign: TextAlign.right,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// The ledger of records. Counts and measurements only.
class _RecordsCard extends StatelessWidget {
  const _RecordsCard({required this.records});

  final DiaryRecords records;

  @override
  Widget build(BuildContext context) {
    final highest = records.highestKcal;
    final food = records.topFood;
    final recipe = records.topRecipe;

    return TokenCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Column(
        children: [
          _RecordRow(
            icon: Icons.calendar_month_rounded,
            title: 'Days logged',
            value: '${records.daysLogged}',
            suffix: ' of ${records.daysAvailable}',
          ),
          _RecordRow(
            icon: Icons.bolt_rounded,
            title: 'Longest streak',
            value: '${records.longestStreak}',
            suffix: records.longestStreak == 1 ? ' day' : ' days',
          ),
          _RecordRow(
            icon: Icons.local_fire_department_rounded,
            title: 'Highest day',
            value: highest == null ? '—' : groupedNumber(highest),
            suffix: highest == null
                ? null
                : ' kcal · ${shortDate(records.highestDate!)}',
          ),
          _RecordRow(
            icon: Icons.kitchen_rounded,
            title: 'Most logged food',
            subtitle: food?.name ?? 'Nothing logged yet',
            value: food == null ? '—' : '×${food.count}',
          ),
          _RecordRow(
            icon: Icons.menu_book_rounded,
            title: 'Top recipe',
            subtitle: recipe?.name ?? 'No recipe logged yet',
            value: recipe == null ? '—' : '×${recipe.count}',
            last: true,
          ),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    this.suffix,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String value;
  final String? suffix;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: last
          ? null
          : BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: context.rb.separator))),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyLarge),
                if (subtitle != null)
                  Text(subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text.rich(
            TextSpan(
              text: value,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
              children: [
                if (suffix != null)
                  TextSpan(
                    text: suffix,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}

/// The product page nests sub-nutrients under their parent ("— of which
/// saturated"); this ledger is flat, so the dash has nothing to hang off. The
/// few keys that read wrong un-nested are named here, and everything else
/// comes straight from nutrient_display.
const _flatLabels = <String, String>{
  'saturated_fat': 'Saturated fat',
  'monounsaturated_fat': 'Monounsaturated fat',
  'polyunsaturated_fat': 'Polyunsaturated fat',
  'trans_fat': 'Trans fat',
  'sugars': 'Sugars',
  'added_sugars': 'Added sugars',
  'starch': 'Starch',
  'polyols': 'Polyols',
};

String ledgerLabel(String key) => _flatLabels[key] ?? nutrientLabel(key);
