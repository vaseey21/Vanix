import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// VANIX DESIGN SYSTEM v1.0 — Flutter tokens
// Mirrors vanix_screens.html / vanix_design_system.html exactly.
// Import this file everywhere — never hard-code values.
// ─────────────────────────────────────────────

class VanixColors {
  VanixColors._();

  // Brand — two-hue system only
  static const Color brandGreen = Color(0xFF4DDE95); // accent only — NEVER on white bg
  static const Color greenDeep = Color(0xFF2EBD7E); // CTA fill w/ dark text; focus accents
  static const Color greenInk = Color(0xFF1E7A52); // green as text/icon on white
  static const Color darkPrimary = Color(0xFF111111);
  static const Color darkSecond = Color(0xFF1C1C1C);
  static const Color darkSubSurface = Color(0xFF262626);
  static const Color darkBorder = Color(0xFF3A3A3A);

  // Light-mode surfaces
  static const Color bgWarm = Color(0xFFF2EDE4); // scaffold bg — never pure white
  static const Color bgCard = Color(0xFFFFFFFF);

  // Text — light
  static const Color textPrimary = Color(0xFF111111);
  static const Color textHint = Color(0xFF8C8780);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnDarkDim = Color(0xFFF5F5F5);

  static const Color activeBg = Color(0xFFE8F5EE);
  static const Color border = Color(0xFFD8D0C5);
  static const Color divider = Color(0xFFEBE6DD); // lighter than border — rails/dividers only
  static const Color darkDivider = Color(0xFF2A2A2A);

  // Extra accents used by the colourful Overview / Milk Data cards
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color accentViolet = Color(0xFF7C3AED);

  // Semantic
  static const Color warning = Color(0xFFE8A020);
  static const Color danger = Color(0xFFD44C3A);
  static const Color warningBg = Color(0xFFFFF8E8);
  static const Color dangerBg = Color(0xFFFDEAE3);
  static const Color warningInk = Color(0xFF8A5A00);
  static const Color dangerInk = Color(0xFF8B2800);
}

class VanixSpacing {
  VanixSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double touch = 48; // minimum tap target
}

class VanixRadius {
  VanixRadius._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 24;
}

class VanixTextTheme {
  VanixTextTheme._();

  static const TextStyle display = TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: 1.2, color: VanixColors.textPrimary);
  static const TextStyle heading = TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3, color: VanixColors.textPrimary);
  static const TextStyle subheading = TextStyle(fontSize: 18, fontWeight: FontWeight.w500, height: 1.4, color: VanixColors.textPrimary);
  static const TextStyle body = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.7, color: VanixColors.textPrimary);
  static const TextStyle small = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.6, color: VanixColors.textPrimary);
  static const TextStyle label = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.6, color: VanixColors.textHint);

  static const TextStyle displayOnDark = TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: 1.2, color: VanixColors.textOnDark);
  static const TextStyle headingOnDark = TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3, color: VanixColors.textOnDark);
  static const TextStyle bodyOnDark = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.7, color: VanixColors.textOnDark);
  static const TextStyle smallOnDark = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.6, color: VanixColors.textOnDark);
  static const TextStyle hintOnDark = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.6, color: VanixColors.textHint);
}

/// App-wide dark mode is a manual toggle (Account tab), not the OS theme —
/// see CLAUDE.md. Callers pick vanixLightTheme / vanixDarkTheme explicitly
/// based on a ValueNotifier<bool>, not ThemeMode.system.
ThemeData vanixLightTheme({String languageCode = 'hi'}) {
  final fontFamily = languageCode == 'en' ? 'NotoSans' : 'NotoSansDevanagari';
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: VanixColors.bgWarm,
    fontFamily: fontFamily,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: VanixColors.darkPrimary,
      onPrimary: VanixColors.textOnDark,
      secondary: VanixColors.brandGreen,
      onSecondary: VanixColors.darkPrimary,
      error: VanixColors.danger,
      onError: VanixColors.textOnDark,
      surface: VanixColors.bgCard,
      onSurface: VanixColors.textPrimary,
    ),
    cardTheme: CardThemeData(
      color: VanixColors.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VanixRadius.lg),
        side: const BorderSide(color: VanixColors.border, width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: VanixColors.bgCard,
      hintStyle: VanixTextTheme.small.copyWith(color: VanixColors.textHint, fontSize: 13),
      contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: VanixSpacing.lg, vertical: VanixSpacing.md),
      constraints: const BoxConstraints(minHeight: VanixSpacing.touch),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(VanixRadius.md), borderSide: const BorderSide(color: VanixColors.border, width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(VanixRadius.md), borderSide: const BorderSide(color: VanixColors.border, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(VanixRadius.md), borderSide: const BorderSide(color: VanixColors.greenDeep, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(VanixRadius.md), borderSide: const BorderSide(color: VanixColors.danger, width: 1.5)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: VanixColors.greenInk,
        foregroundColor: VanixColors.textOnDark,
        disabledBackgroundColor: const Color(0xFFB5B5B5),
        minimumSize: const Size(0, VanixSpacing.touch),
        shape: const StadiumBorder(),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: VanixColors.textPrimary,
        minimumSize: const Size(0, VanixSpacing.touch),
        shape: const StadiumBorder(),
        side: const BorderSide(color: VanixColors.border, width: 1.5),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    dividerTheme: const DividerThemeData(color: VanixColors.border, thickness: 0.5, space: 0),
  );
}

ThemeData vanixDarkTheme({String languageCode = 'hi'}) {
  final fontFamily = languageCode == 'en' ? 'NotoSans' : 'NotoSansDevanagari';
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: VanixColors.darkPrimary,
    fontFamily: fontFamily,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: VanixColors.textOnDarkDim,
      onPrimary: VanixColors.darkPrimary,
      secondary: VanixColors.brandGreen,
      onSecondary: VanixColors.darkPrimary,
      error: VanixColors.danger,
      onError: VanixColors.textOnDark,
      surface: VanixColors.darkSecond,
      onSurface: VanixColors.textOnDarkDim,
    ),
    cardTheme: CardThemeData(
      color: VanixColors.darkSecond,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VanixRadius.lg),
        side: const BorderSide(color: VanixColors.darkBorder, width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: VanixColors.darkSecond,
      hintStyle: VanixTextTheme.small.copyWith(color: const Color(0x738C8780), fontSize: 13),
      contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: VanixSpacing.lg, vertical: VanixSpacing.md),
      constraints: const BoxConstraints(minHeight: VanixSpacing.touch),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(VanixRadius.md), borderSide: const BorderSide(color: VanixColors.darkBorder, width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(VanixRadius.md), borderSide: const BorderSide(color: VanixColors.darkBorder, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(VanixRadius.md), borderSide: const BorderSide(color: VanixColors.greenDeep, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(VanixRadius.md), borderSide: const BorderSide(color: VanixColors.danger, width: 1.5)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: VanixColors.greenDeep,
        foregroundColor: VanixColors.textOnDark,
        disabledBackgroundColor: const Color(0xFF4A4A4A),
        minimumSize: const Size(0, VanixSpacing.touch),
        shape: const StadiumBorder(),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: VanixColors.textOnDarkDim,
        minimumSize: const Size(0, VanixSpacing.touch),
        shape: const StadiumBorder(),
        side: const BorderSide(color: VanixColors.darkBorder, width: 1.5),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    dividerTheme: const DividerThemeData(color: VanixColors.darkBorder, thickness: 0.5, space: 0),
  );
}

// ─────────────────────────────────────────────
// Elevation — Airbnb-style soft shadows for cards (light + dark).
// Matches prototype.html: 0 4px 16px / 0 1px 3px, deepened on dark.
// ─────────────────────────────────────────────

class VanixShadow {
  VanixShadow._();

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 3, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> cardDark = [
    BoxShadow(color: Color(0x59000000), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x4D000000), blurRadius: 3, offset: Offset(0, 1)),
  ];
}
