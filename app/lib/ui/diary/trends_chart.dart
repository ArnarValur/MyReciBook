// The energy chart — bars, an axis, and one dashed guide line.
//
// Drawn with plain widgets and two small painters. A charting package for one
// bar chart would be a dependency the whole app then carries into every build,
// and none of what those packages are good at (zoom, tooltips, live data) is
// anything this screen does.
//
// Three bar states, and they are the mockup's own vocabulary:
//   solid   — a day (or month) that is over and was logged;
//   faded   — the one we are inside; the day is not finished yet;
//   stub    — a dashed baseline where nothing was logged, which includes the
//             future. A day nobody logged is NOT a bar of height zero — that
//             would read as "ate nothing", the exact lie the diary refuses.

import 'package:flutter/material.dart';

import '../../domain/diary_stats.dart';
import '../theme.dart';

class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.buckets,
    this.guide,
    this.guideLabel,
    this.semanticsLabel,
    this.height = 104,
  });

  final List<TrendBucket> buckets;

  /// The dashed reference line: the goal once one is set, otherwise the
  /// average. Null draws no line at all.
  final double? guide;
  final String? guideLabel;

  final String? semanticsLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    if (buckets.isEmpty) return const SizedBox.shrink();

    final gap = buckets.length > 14 ? 2.0 : (buckets.length > 7 ? 4.0 : 7.0);
    var top = guide ?? 0;
    for (final bucket in buckets) {
      final value = bucket.kcal;
      if (value != null && value > top) top = value;
    }

    final chart = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, box) {
              final plot = box.maxHeight;
              final layers = <Widget>[
                Positioned.fill(
                  child: Row(
                    spacing: gap,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final bucket in buckets)
                        Expanded(
                          child: _Bar(
                            bucket: bucket,
                            // A bar too short to see still has to be visible:
                            // 200 kcal on a 3,000 kcal scale is a real day.
                            height: top <= 0 || bucket.kcal == null
                                ? null
                                : (plot * bucket.kcal! / top).clamp(3.0, plot),
                          ),
                        )
                    ],
                  ),
                ),
              ];
              final line = guide;
              if (line != null && top > 0) {
                final y = plot * line / top;
                // Near the ceiling the caption would be clipped off the top of
                // the card, so it drops under its own line instead.
                final above = y < plot * 0.85;
                layers.add(Positioned(
                  left: 0,
                  right: 0,
                  bottom: y,
                  child: DashedRule(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                    thickness: 1.5,
                  ),
                ));
                if (guideLabel != null) {
                  layers.add(Positioned(
                    right: 0,
                    bottom: above ? y + 1 : y - 13,
                    child: ColoredBox(
                      // The card's own colour, so the rule does not run
                      // through the word.
                      color: scheme.surfaceContainerLowest,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          guideLabel!,
                          style: TextStyle(
                              fontSize: 9.5, color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ));
                }
              }
              return Stack(children: layers);
            },
          ),
        ),
        const SizedBox(height: 4),
        Row(
          spacing: gap,
          children: [
            for (final bucket in buckets)
              Expanded(
                child: Text(
                  // Seven columns can spell the word out; thirty cannot.
                  bucket.isCurrent && buckets.length <= 7
                      ? 'today'
                      : bucket.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    fontSize: 9.5,
                    height: 1.2,
                    fontWeight:
                        bucket.isCurrent ? FontWeight.w600 : FontWeight.w400,
                    color: bucket.isCurrent
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                  ),
                ),
              )
          ],
        ),
      ],
    );

    if (semanticsLabel == null) return chart;
    return Semantics(
      label: semanticsLabel,
      child: ExcludeSemantics(child: chart),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.bucket, required this.height});

  final TrendBucket bucket;

  /// Null when there is nothing to draw — a stub, not a zero.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final bar = height;
    if (bar == null) {
      return DashedRule(
          color: scheme.outline.withValues(alpha: 0.6), thickness: 2);
    }
    final unfinished = bucket.isCurrent || bucket.isFuture;
    return Container(
      height: bar,
      decoration: BoxDecoration(
        color: unfinished
            ? scheme.primary.withValues(alpha: 0.4)
            : scheme.primary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
    );
  }
}

/// A horizontal dashed line that fills its width.
class DashedRule extends StatelessWidget {
  const DashedRule({
    super.key,
    required this.color,
    this.thickness = 1.5,
    this.dash = 4,
    this.gap = 3,
  });

  final Color color;
  final double thickness;
  final double dash;
  final double gap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: thickness,
        width: double.infinity,
        child: CustomPaint(
            painter: _DashPainter(
                color: color, thickness: thickness, dash: dash, gap: gap)),
      );
}

class _DashPainter extends CustomPainter {
  const _DashPainter({
    required this.color,
    required this.thickness,
    required this.dash,
    required this.gap,
  });

  final Color color;
  final double thickness;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      final end = (x + dash).clamp(0.0, size.width);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) =>
      old.color != color ||
      old.thickness != thickness ||
      old.dash != dash ||
      old.gap != gap;
}

/// The coverage dots — one per day, filled where the nutrient was actually
/// measured. This is the honesty rule made visible: an average of five days
/// out of seven says so instead of pretending the other two were zeroes.
class CoverageDots extends StatelessWidget {
  const CoverageDots({super.key, required this.coverage});

  final List<bool> coverage;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 2.5,
      children: [
        for (final measured in coverage)
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: measured ? scheme.primary : null,
              border: measured
                  ? null
                  : Border.all(color: scheme.outline, width: 1),
            ),
          )
      ],
    );
  }
}
