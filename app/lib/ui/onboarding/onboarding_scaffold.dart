// Shared pieces for the first-run flow.
//
// [OnboardingSlot] is the honest empty state: a labelled reservation for
// content that does not exist yet. It is visibly unfinished on purpose —
// a placeholder that looks designed is one nobody remembers to replace.
//
// [GradientButton] is the gate's primary-action treatment lifted verbatim so
// the welcome flow and the folder gate cannot drift apart.

import 'package:flutter/material.dart';

import '../theme.dart';

/// The mockup's dashed reassurance note.
class DottedNote extends StatelessWidget {
  const DottedNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.6)),
      ),
      child: Text(text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12.5, height: 1.5, color: scheme.onSurfaceVariant)),
    );
  }
}

/// A reserved region for art or screenshots Arnar has not supplied yet.
class OnboardingSlot extends StatelessWidget {
  const OnboardingSlot({
    super.key,
    required this.label,
    this.note,
    this.height = 160,
  });

  final String label;
  final String? note;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.rb.hairline),
      ),
      // The mockup's 45° hatch, so an unfilled slot reads as a placeholder at
      // a glance and nobody mistakes it for a finished screen.
      child: CustomPaint(
        painter: _HatchPainter(
          a: Color.alphaBlend(
              scheme.secondaryContainer.withValues(alpha: 0.45),
              scheme.surface),
          b: Color.alphaBlend(
              scheme.secondaryContainer.withValues(alpha: 0.22),
              scheme.surface),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              note == null ? label : '$label · $note',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}

/// The one primary action, in the gate's gradient-FAB treatment.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final IconData? icon;

  /// Null disables the button — used by the setup screen until a folder is
  /// chosen, so "Continue" can never advance into an app with nowhere to save.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final on = onPressed != null;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: on
              ? [scheme.primaryContainer, scheme.primary]
              : [
                  scheme.surfaceContainerHighest,
                  scheme.surfaceContainerHighest
                ],
        ),
        boxShadow: on ? context.rb.glowFab : null,
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: on ? scheme.onPrimary : scheme.onSurfaceVariant,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: scheme.onSurfaceVariant,
        ),
        icon: icon == null ? null : Icon(icon, size: 20),
        label: Text(label),
      ),
    );
  }
}


class _HatchPainter extends CustomPainter {
  const _HatchPainter({required this.a, required this.b});

  final Color a;
  final Color b;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = b);
    final stripe = Paint()
      ..color = a
      ..strokeWidth = 9;
    // 45° stripes, 9px on 9px off — the mockup's repeating-linear-gradient.
    final span = size.width + size.height;
    for (var d = -size.height; d < span; d += 18) {
      canvas.drawLine(
          Offset(d, 0), Offset(d + size.height, size.height), stripe);
    }
  }

  @override
  bool shouldRepaint(_HatchPainter old) => old.a != a || old.b != b;
}
