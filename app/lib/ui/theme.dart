// Skin tokens — DittoDatto design system → Flutter.
// Source of truth: docs/design/handoff.md + tokens/*.css in the design bundle.
// Two themes ship: light "Stitch Slate" (cream scaffold) and dark "Midnight"
// (deep navy, never black). Elevation in dark = surface tint, not shadow.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:google_fonts/google_fonts.dart';

abstract final class RbColors {
  // Light — "Stitch Slate"
  static const lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF24389C),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF3F51B5),
    onPrimaryContainer: Color(0xFFCACFFF),
    secondary: Color(0xFF4D5A9C),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFABB7FF),
    onSecondaryContainer: Color(0xFF394687),
    tertiary: Color(0xFF88003B),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFB40050),
    onTertiaryContainer: Color(0xFFFFC3CE),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF93000A),
    surface: Color(0xFFF9F9FC),
    onSurface: Color(0xFF1A1C1E),
    onSurfaceVariant: Color(0xFF454652),
    surfaceDim: Color(0xFFDADADC),
    surfaceBright: Color(0xFFF9F9FC),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF3F3F6),
    surfaceContainer: Color(0xFFEEEEF0),
    surfaceContainerHigh: Color(0xFFE8E8EA),
    surfaceContainerHighest: Color(0xFFE2E2E5),
    outline: Color(0xFF757684),
    outlineVariant: Color(0xFFC5C5D4),
    inverseSurface: Color(0xFF2F3133),
    onInverseSurface: Color(0xFFF0F0F3),
    inversePrimary: Color(0xFFBAC3FF),
    surfaceTint: Color(0xFF4355B9),
  );

  // Dark — "Midnight"
  static const darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFBAC3FF),
    onPrimary: Color(0xFF071A86),
    primaryContainer: Color(0xFF293CA0),
    onPrimaryContainer: Color(0xFFDEE0FF),
    secondary: Color(0xFFB9C3FF),
    onSecondary: Color(0xFF21326F),
    secondaryContainer: Color(0xFF354282),
    onSecondaryContainer: Color(0xFFDEE1FF),
    tertiary: Color(0xFFFFB1C1),
    onTertiary: Color(0xFF650029),
    tertiaryContainer: Color(0xFF8F003F),
    onTertiaryContainer: Color(0xFFFFD9DF),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF0F1117),
    onSurface: Color(0xFFE4E2E6),
    onSurfaceVariant: Color(0xFFC5C5D4),
    surfaceDim: Color(0xFF0F1117),
    surfaceBright: Color(0xFF35373E),
    surfaceContainerLowest: Color(0xFF0A0C11),
    surfaceContainerLow: Color(0xFF141720),
    surfaceContainer: Color(0xFF161922),
    surfaceContainerHigh: Color(0xFF1C1F2B),
    surfaceContainerHighest: Color(0xFF262A36),
    outline: Color(0xFF8F8F9E),
    outlineVariant: Color(0xFF454652),
    inverseSurface: Color(0xFFE4E2E6),
    onInverseSurface: Color(0xFF2F3133),
    inversePrimary: Color(0xFF24389C),
    surfaceTint: Color(0xFFBAC3FF),
  );

  static const scaffoldLight = Color(0xFFFAF8F0); // warm cream
  static const scaffoldDark = Color(0xFF0F1117);

  // Status — theme-stable.
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
}

/// Tokens that don't fit ColorScheme: shadows, glow, glass, hairlines.
@immutable
class RbTokens extends ThemeExtension<RbTokens> {
  final List<BoxShadow> cardShadow; // elev-1
  final List<BoxShadow> modalShadow; // elev-2
  final List<BoxShadow> glowPrimary; // focus / selected
  final List<BoxShadow> glowFab;
  final Color hairline; // outline-variant @ ~50%
  final Color separator; // outline-variant @ ~35%
  final Color glassFill;
  final Color glassBorder;

  const RbTokens({
    required this.cardShadow,
    required this.modalShadow,
    required this.glowPrimary,
    required this.glowFab,
    required this.hairline,
    required this.separator,
    required this.glassFill,
    required this.glassBorder,
  });

  static const light = RbTokens(
    cardShadow: [
      BoxShadow(color: Color(0x0F24389C), blurRadius: 10, offset: Offset(0, 4)),
    ],
    modalShadow: [
      BoxShadow(color: Color(0x1F24389C), blurRadius: 20, offset: Offset(0, 8)),
    ],
    glowPrimary: [
      BoxShadow(color: Color(0x263F51B5), blurRadius: 12, spreadRadius: 2),
    ],
    glowFab: [
      BoxShadow(
        color: Color(0x733F51B5),
        blurRadius: 16,
        spreadRadius: 2,
        offset: Offset(0, 8),
      ),
    ],
    hairline: Color(0x80C5C5D4),
    separator: Color(0x59C5C5D4),
    glassFill: Color(0x8CFFFFFF),
    glassBorder: Color(0x14000000),
  );

  static const dark = RbTokens(
    cardShadow: [
      BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 2)),
    ],
    modalShadow: [
      BoxShadow(color: Color(0x80000000), blurRadius: 20, offset: Offset(0, 8)),
    ],
    glowPrimary: [
      BoxShadow(color: Color(0x2EBAC3FF), blurRadius: 12, spreadRadius: 2),
    ],
    glowFab: [
      BoxShadow(
        color: Color(0x4DBAC3FF),
        blurRadius: 18,
        spreadRadius: 2,
        offset: Offset(0, 8),
      ),
    ],
    hairline: Color(0x80454652),
    separator: Color(0x59454652),
    glassFill: Color(0x59000000),
    glassBorder: Color(0x1FFFFFFF),
  );

  @override
  RbTokens copyWith() => this;

  @override
  RbTokens lerp(RbTokens? other, double t) => t < 0.5 ? this : (other ?? this);
}

extension RbThemeX on BuildContext {
  RbTokens get rb => Theme.of(this).extension<RbTokens>()!;
  ColorScheme get scheme => Theme.of(this).colorScheme;
}

/// Display/headline/title = Plus Jakarta Sans; body/label = Inter.
TextTheme _textTheme(TextTheme base) {
  final inter = GoogleFonts.interTextTheme(base);
  TextStyle pjs(TextStyle? s, double size, FontWeight w, [double? spacing]) =>
      GoogleFonts.plusJakartaSans(
        textStyle: s,
        fontSize: size,
        fontWeight: w,
        letterSpacing: spacing,
      );
  return inter.copyWith(
    displayLarge: pjs(base.displayLarge, 48, FontWeight.w700, -0.96),
    headlineLarge: pjs(base.headlineLarge, 32, FontWeight.w600, -0.32),
    headlineMedium: pjs(base.headlineMedium, 26, FontWeight.w700, -0.52),
    headlineSmall: pjs(base.headlineSmall, 23, FontWeight.w700, -0.23),
    titleLarge: pjs(base.titleLarge, 18, FontWeight.w700),
    titleMedium: pjs(base.titleMedium, 15, FontWeight.w600),
    titleSmall: GoogleFonts.inter(
      textStyle: base.titleSmall,
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: GoogleFonts.inter(textStyle: base.bodyLarge, fontSize: 14),
    bodyMedium: GoogleFonts.inter(textStyle: base.bodyMedium, fontSize: 13.5),
    bodySmall: GoogleFonts.inter(textStyle: base.bodySmall, fontSize: 12),
    labelLarge: GoogleFonts.inter(
      textStyle: base.labelLarge,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: GoogleFonts.inter(
      textStyle: base.labelMedium,
      fontSize: 12.5,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: GoogleFonts.inter(
      textStyle: base.labelSmall,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.9,
    ),
  );
}

ThemeData _theme(ColorScheme scheme, Color scaffold, RbTokens tokens) {
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final text = _textTheme(base.textTheme);
  return base.copyWith(
    scaffoldBackgroundColor: scaffold,
    textTheme: text,
    extensions: [tokens],
    appBarTheme: AppBarTheme(
      backgroundColor: scaffold,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      iconTheme: IconThemeData(color: scheme.onSurface, size: 22),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: const StadiumBorder(),
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 44),
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.secondary, width: 1.5),
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: text.labelLarge?.copyWith(fontSize: 13),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearMinHeight: 6,
    ),
  );
}

ThemeData rbLightTheme() =>
    _theme(RbColors.lightScheme, RbColors.scaffoldLight, RbTokens.light);

ThemeData rbDarkTheme() =>
    _theme(RbColors.darkScheme, RbColors.scaffoldDark, RbTokens.dark);

/// MaterialApp.builder for BOTH MaterialApps (gate and app): the status-bar
/// anchor. Every route inherits icons matching the theme — a Scaffold with no
/// AppBar (import review, manual entry…) used to assert nothing, so whatever
/// the Android photo picker's dark UI left behind stuck: white clock on cream
/// (Arnar's rescue screenshots, 2026-08-29). A route that wants its own style
/// (black OriginalsViewer, barcode scan) still wins — inner regions beat this
/// outer one.
Widget rbStatusBarAnchor(BuildContext context, Widget? child) =>
    AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: child ?? const SizedBox.shrink(),
    );
