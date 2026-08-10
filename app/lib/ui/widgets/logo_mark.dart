// The MyReciBook logo mark, drawn (not imported) so it tints with the scheme
// and stays crisp at any size. Geometry is a 1:1 transcription of
// docs/MyReciBook-logo/assets/logo/logo-mark.svg (108x108 viewBox) — that file
// is the authority; change it there first, then mirror the paths here.
//
// Two forms:
//   withSteam: true  — full mark (open book + two steam wisps). Headers, splash.
//   withSteam: false — book only. Below ~24dp the wisps turn to mush, so nav
//                      slots and list rows get the book alone.

import 'package:flutter/widgets.dart';

class LogoMark extends StatelessWidget {
  const LogoMark({
    super.key,
    required this.size,
    required this.color,
    this.withSteam = true,
  });

  /// Side of the square box the mark is fitted into.
  final double size;
  final Color color;
  final bool withSteam;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _LogoMarkPainter(color: color, withSteam: withSteam),
        // The mark carries the product name; screen readers get it once, from
        // the label beside it, so this stays decorative.
        isComplex: false,
      ),
    );
  }
}

class _LogoMarkPainter extends CustomPainter {
  _LogoMarkPainter({required this.color, required this.withSteam});

  final Color color;
  final bool withSteam;

  // Ink bounds in the 108-unit design space, stroke widths included.
  static const Rect _fullBounds = Rect.fromLTRB(26, 23, 82, 78);
  static const Rect _bookBounds = Rect.fromLTRB(26, 51, 82, 78);

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = withSteam ? _fullBounds : _bookBounds;
    final k = (size.width / bounds.width) < (size.height / bounds.height)
        ? size.width / bounds.width
        : size.height / bounds.height;

    canvas.save();
    canvas.translate(
      (size.width - bounds.width * k) / 2 - bounds.left * k,
      (size.height - bounds.height * k) / 2 - bounds.top * k,
    );
    canvas.scale(k);

    final fill = Paint()
      ..color = color
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

    // The spine is knocked OUT of the book, not painted over it — that is what
    // lets the mark sit on any background (svg does it with a mask).
    canvas.saveLayer(_fullBounds.inflate(8), Paint());
    canvas.drawPath(book, fill);
    canvas.drawLine(
      const Offset(54, 62),
      const Offset(54, 76),
      Paint()
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();

    if (withSteam) {
      final wisp = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;
      for (final x in const [45.0, 63.0]) {
        canvas.drawPath(
          Path()
            ..moveTo(x, 26)
            ..cubicTo(x - 5, 33, x + 5, 35, x, 42),
          wisp,
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_LogoMarkPainter old) =>
      old.color != color || old.withSteam != withSteam;
}
