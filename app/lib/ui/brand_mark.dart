// The MyReciBook mark, drawn rather than shipped as an asset.
//
// Traced from the `mrb-b` symbol in the Claude Design bundle (viewBox
// 108×108): an open book whose pages read as a bowl, with two curls of steam
// rising off it and a knocked-out spine. Vector so it stays crisp at any size
// and costs no image asset; the paths below are the mockup's verbatim.

import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 92,
    required this.background,
    required this.foreground,
  });

  final double size;

  /// The rounded-square tile. Also the spine knock-out colour: the mockup
  /// punches the spine through to the tile behind, so the two must match.
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        // 27% of the side, as drawn — a squircle-ish tile, not a circle.
        borderRadius: BorderRadius.circular(size * 0.27),
      ),
      child: CustomPaint(
        painter: _MarkPainter(foreground: foreground, knock: background),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.foreground, required this.knock});

  final Color foreground;
  final Color knock;

  @override
  void paint(Canvas canvas, Size size) {
    // Everything below is in the 108×108 design space; scale once.
    final s = size.width / 108;
    canvas.scale(s);

    final fill = Paint()
      ..color = foreground
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final book = Path()
      ..moveTo(54, 60)
      ..cubicTo(47, 53, 36, 51, 26, 53)
      ..lineTo(26, 72)
      ..cubicTo(36, 70, 47, 72, 54, 78)
      ..cubicTo(61, 72, 72, 70, 82, 72)
      ..lineTo(82, 53)
      ..cubicTo(72, 51, 61, 53, 54, 60)
      ..close();
    canvas.drawPath(book, fill);

    // Spine: punched through to the tile colour.
    canvas.drawLine(
      const Offset(54, 62),
      const Offset(54, 76),
      Paint()
        ..color = knock
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );

    final steam = Paint()
      ..color = foreground
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    for (final x in const [45.0, 63.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(x, 26)
          ..cubicTo(x - 5, 33, x + 5, 35, x, 42),
        steam,
      );
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.foreground != foreground || old.knock != knock;
}
