// Shared skin primitives — the DittoDatto visual language, one widget each:
// section labels, token cards, pill chips, glass circles, the gradient FAB.

import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme.dart';

/// `INGREDIENTS · 8` — tiny tracked uppercase label.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text.toUpperCase(),
      style: Theme.of(context)
          .textTheme
          .labelSmall
          ?.copyWith(color: context.scheme.onSurfaceVariant),
    );
    if (trailing == null) return label;
    return Row(children: [label, const SizedBox(width: 6), trailing!]);
  }
}

/// Card: surface-container-lowest, hairline border, radius 12–16, blue shadow.
/// [selected] switches to the 1.5dp primary border + glow treatment.
class TokenCard extends StatelessWidget {
  const TokenCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.radius = 12,
    this.selected = false,
    this.borderColor,
    this.borderWidth,
    this.color,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool selected;
  final Color? borderColor;
  final double? borderWidth;
  final Color? color;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final rb = context.rb;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? context.scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? (selected ? context.scheme.primary : rb.hairline),
          width: borderWidth ?? (selected ? 1.5 : 1),
        ),
        boxShadow: selected ? rb.glowPrimary : (shadow ? rb.cardShadow : null),
      ),
      child: child,
    );
  }
}

/// Stadium chip on surface-container-high with a primary icon.
class MetaChip extends StatelessWidget {
  const MetaChip({super.key, this.icon, required this.label, this.onTap});

  final IconData? icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: context.scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: context.scheme.primary),
            const SizedBox(width: 5),
          ],
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
    if (onTap == null) return chip;
    return InkWell(
        borderRadius: BorderRadius.circular(999), onTap: onTap, child: chip);
  }
}

/// Quiet status pill — the "On this phone" / "Synced" storage badge.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: RbColors.success.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: context.scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: context.scheme.onSurfaceVariant, letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }
}

/// 40dp frosted-glass circular button (hero overlays).
class GlassCircle extends StatelessWidget {
  const GlassCircle(
      {super.key, required this.icon, this.onTap, this.iconColor, this.filled = false});

  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final rb = context.rb;
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: rb.glassFill,
          shape: CircleBorder(side: BorderSide(color: rb.glassBorder)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon,
                  size: 20,
                  fill: filled ? 1 : 0,
                  color: iconColor ?? context.scheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}

/// Frosted-glass stadium pill with icon + label (the "original ⇄" flipper).
class GlassPill extends StatelessWidget {
  const GlassPill(
      {super.key, required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final rb = context.rb;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: rb.glassFill,
          shape: StadiumBorder(side: BorderSide(color: rb.glassBorder)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 15, color: context.scheme.onSurface),
                  const SizedBox(width: 5),
                  Text(label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(

                          fontSize: 11.5, letterSpacing: 0.2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The 52dp gradient FAB: primaryContainer → primary at 135°, strong glow.
class GradientFab extends StatelessWidget {
  const GradientFab({super.key, required this.onPressed, this.icon = Icons.add});

  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.primary],
        ),
        boxShadow: context.rb.glowFab,
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: Colors.transparent,
        shape: const CircleBorder(),
        child: Icon(icon, color: scheme.onPrimary),
      ),
    );
  }
}

/// Diagonal-striped placeholder — stands in wherever a user screenshot would
/// render but none exists. Mirrors the mockups' `repeating-linear-gradient`.
class StripedPlaceholder extends StatelessWidget {
  const StripedPlaceholder({super.key, this.icon});

  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final a = Color.alphaBlend(
        scheme.secondaryContainer.withValues(alpha: 0.45), scheme.surface);
    final b = Color.alphaBlend(
        scheme.secondaryContainer.withValues(alpha: 0.20), scheme.surface);
    return CustomPaint(
      painter: _StripePainter(a, b),
      child: icon == null
          ? const SizedBox.expand()
          : Center(
              child:
                  Icon(icon, size: 30, color: scheme.onSurfaceVariant)),
    );
  }
}

class _StripePainter extends CustomPainter {
  const _StripePainter(this.a, this.b);

  final Color a;
  final Color b;

  @override
  void paint(Canvas canvas, Size size) {
    final paintA = Paint()..color = a;
    final paintB = Paint()..color = b;
    canvas.drawRect(Offset.zero & size, paintB);
    const w = 8.0;
    // 45° stripes: iterate along x + y.
    for (var x = -size.height; x < size.width; x += w * 2) {
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + size.height, 0)
        ..lineTo(x + size.height + w, 0)
        ..lineTo(x + w, size.height)
        ..close();
      canvas.drawPath(path, paintA);
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) => old.a != a || old.b != b;
}

/// Dashed-border info card — the quiet product-promise framing ("Not a
/// recipe? We skip it and say so…"). True 1px dashes need a custom painter;
/// a soft outline reads the same at hairline weight.
class DashedInfoCard extends StatelessWidget {
  const DashedInfoCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12.5, height: 1.5, color: scheme.onSurfaceVariant)),
    );
  }
}

/// "400 g spaghetti" → bold leading quantity, regular rest. Display-only
/// heuristic over `raw`; when no leading amount is found the line stays plain.
TextSpan qtyBoldSpan(String raw, TextStyle? base) {
  final m = RegExp(r'^[\d½¼¾⅓⅔][\d\s./,½¼¾⅓⅔×x–-]*\s*(?:[a-zA-Zæøåðþ]+\.?)?')
      .firstMatch(raw);
  if (m == null || m.end == 0 || m.end >= raw.length) {
    return TextSpan(text: raw, style: base);
  }
  return TextSpan(style: base, children: [
    TextSpan(
        text: raw.substring(0, m.end),
        style: const TextStyle(fontWeight: FontWeight.w700)),
    TextSpan(text: raw.substring(m.end)),
  ]);
}

/// Full-screen pinch-zoomable viewer over the original screenshots —
/// the provenance affordance shared by review and detail.
class OriginalsViewer extends StatelessWidget {
  const OriginalsViewer({super.key, required this.images});

  final List<File> images;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Original · ${images.length}',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: Colors.white)),
      ),
      body: PageView(
        children: [
          for (final f in images)
            InteractiveViewer(
              maxScale: 5,
              child: Center(child: CoverImage(f, fit: BoxFit.contain)),
            ),
        ],
      ),
    );
  }
}

/// Renders a stored screenshot; falls back to stripes when missing.
class CoverImage extends StatelessWidget {
  const CoverImage(this.file, {super.key, this.fit = BoxFit.cover});

  final File? file;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (file == null) return const StripedPlaceholder();
    return Image.file(
      file!,
      fit: fit,
      errorBuilder: (context, error, stack) => const StripedPlaceholder(),
    );
  }
}
