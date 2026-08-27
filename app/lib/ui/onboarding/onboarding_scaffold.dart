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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        border: Border.all(color: context.rb.hairline),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined,
              size: 26, color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          if (note != null) ...[
            const SizedBox(height: 2),
            Text(note!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.75))),
          ],
        ],
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
