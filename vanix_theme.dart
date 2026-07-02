import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// VANIX DESIGN SYSTEM v1.0
// Single source of truth for all design tokens.
// Import this file everywhere — never hard-code values.
// ─────────────────────────────────────────────

class VanixColors {
  VanixColors._();

  // Brand — two-hue system only
  static const Color brandGreen   = Color(0xFF4DDE95); // logo color; accent only — NEVER on white bg
  static const Color greenDeep    = Color(0xFF2EBD7E); // CTA fill (Continue/Confirm) w/ dark text; input focus accents
  static const Color greenInk     = Color(0xFF1E7A52); // green as text/icon on white — only green passing AA on white
  static const Color heroBlue     = Color(0xFF274C77); // hero surfaces (Milk Log header) — white text on it
  static const Color darkPrimary  = Color(0xFF111111); // dark cards, headers, FAB bg
  static const Color darkSecond   = Color(0xFF1C1C1C); // sub-cards on dark surfaces

  // Surfaces
  static const Color bgWarm       = Color(0xFFF2EDE4); // scaffold bg — always use this, never pure white
  static const Color bgCard       = Color(0xFFFFFFFF); // card surface on bgWarm

  // Text
  static const Color textPrimary  = Color(0xFF111111); // body text on bgWarm / bgCard
  static const Color textHint     = Color(0xFF8C8780); // placeholders, timestamps, captions
  static const Color textOnDark   = Color(0xFFFFFFFF); // text on darkPrimary / darkSecond

  // Navigation
  static const Color activeGreen  = Color(0xFF4DDE95); // active nav icon tint, CTAs
  static const Color activeBg     = Color(0xFFE8F5EE); // active nav tab pill background

  // Borders & dividers
  static const Color border       = Color(0xFFD8D0C5); // warm-tinted — card borders, input outlines

  // Semantic
  static const Color success      = Color(0xFF4DDE95); // reuses brandGreen
  static const Color warning      = Color(0xFFE8A020); // low yield, heat alert, 1hr escalation
  static const Color danger       = Color(0xFFD44C3A); // critical alert, 2hr+ escalation, badge

  // Semantic backgrounds (for banners / tinted cards)
  static const Color successBg    = Color(0xFFE8F5EE);
  static const Color warningBg    = Color(0xFFFFF8E8);
  static const Color dangerBg     = Color(0xFFFDEAE3);
}

// ─────────────────────────────────────────────

class VanixSpacing {
  VanixSpacing._();

  static const double xs    = 4;
  static const double sm    = 8;
  static const double md    = 12;
  static const double lg    = 16;
  static const double xl    = 20;
  static const double xxl   = 24;
  static const double touch = 48; // MINIMUM tap target — never go below this
}

// ─────────────────────────────────────────────

class VanixRadius {
  VanixRadius._();

  static const double xs   = 4;  // small tags, tight badges
  static const double sm   = 8;  // chips, buttons inside cards
  static const double md   = 12; // input fields, bottom sheet
  static const double lg   = 16; // primary card radius
  static const double pill = 24; // buttons, nav pill, session toggles
}

// ─────────────────────────────────────────────

class VanixTextTheme {
  VanixTextTheme._();

  // Use fontFamily based on locale:
  //   hi / bho → 'NotoSansDevanagari'
  //   en       → 'NotoSans'
  // Both are bundled assets — not network-loaded.

  static const TextStyle display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: VanixColors.textPrimary,
  );

  static const TextStyle heading = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: VanixColors.textPrimary,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: VanixColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.7, // tall for Devanagari shirorekha
    color: VanixColors.textPrimary,
  );

  static const TextStyle small = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: VanixColors.textPrimary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.05 * 12,
    color: VanixColors.textHint,
  );

  // Variants for on-dark surfaces
  static const TextStyle displayOnDark   = TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: 1.2, color: VanixColors.textOnDark);
  static const TextStyle headingOnDark   = TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3, color: VanixColors.textOnDark);
  static const TextStyle bodyOnDark      = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.7, color: VanixColors.textOnDark);
  static const TextStyle smallOnDark     = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.6, color: VanixColors.textOnDark);
  static const TextStyle hintOnDark      = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.6, color: VanixColors.textHint);
}

// ─────────────────────────────────────────────

ThemeData vanixTheme({String languageCode = 'hi'}) {
  final String fontFamily = (languageCode == 'en') ? 'NotoSans' : 'NotoSansDevanagari';

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: VanixColors.bgWarm,
    fontFamily: fontFamily,

    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary:          VanixColors.darkPrimary,
      onPrimary:        VanixColors.textOnDark,
      secondary:        VanixColors.brandGreen,
      onSecondary:      VanixColors.darkPrimary,
      error:            VanixColors.danger,
      onError:          VanixColors.textOnDark,
      surface:          VanixColors.bgCard,
      onSurface:        VanixColors.textPrimary,
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
      hintStyle: VanixTextTheme.small.copyWith(color: VanixColors.textHint),
      contentPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: VanixSpacing.lg,
        vertical: VanixSpacing.md,
      ),
      constraints: const BoxConstraints(minHeight: VanixSpacing.touch),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VanixRadius.md),
        borderSide: const BorderSide(color: VanixColors.border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VanixRadius.md),
        borderSide: const BorderSide(color: VanixColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VanixRadius.md),
        borderSide: const BorderSide(color: VanixColors.brandGreen, width: 1.5),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: VanixColors.darkPrimary,
        foregroundColor: VanixColors.textOnDark,
        minimumSize: const Size(0, VanixSpacing.touch),
        shape: const StadiumBorder(),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: VanixColors.bgCard,
      selectedItemColor: VanixColors.darkPrimary,
      unselectedItemColor: VanixColors.textHint,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
    ),

    dividerTheme: const DividerThemeData(
      color: VanixColors.border,
      thickness: 0.5,
      space: 0,
    ),
  );
}

// ─────────────────────────────────────────────
// USAGE IN main.dart:
//
// MaterialApp(
//   title: 'Vanix',
//   theme: vanixTheme(languageCode: Localizations.localeOf(context).languageCode),
//   localizationsDelegates: AppLocalizations.localizationsDelegates,
//   supportedLocales: const [Locale('hi'), Locale('bho'), Locale('en')],
//   localeResolutionCallback: (locale, supported) {
//     if (locale == null) return const Locale('hi');
//     for (final s in supported) {
//       if (s.languageCode == locale.languageCode) return s;
//     }
//     return const Locale('hi'); // default to Hindi
//   },
// )
//
// pubspec.yaml fonts:
//   fonts:
//     - family: NotoSans
//       fonts:
//         - asset: assets/fonts/NotoSans-Regular.ttf
//           weight: 400
//         - asset: assets/fonts/NotoSans-Medium.ttf
//           weight: 500
//         - asset: assets/fonts/NotoSans-SemiBold.ttf
//           weight: 600
//     - family: NotoSansDevanagari
//       fonts:
//         - asset: assets/fonts/NotoSansDevanagari-Regular.ttf
//           weight: 400
//         - asset: assets/fonts/NotoSansDevanagari-Medium.ttf
//           weight: 500
//         - asset: assets/fonts/NotoSansDevanagari-SemiBold.ttf
//           weight: 600
// ─────────────────────────────────────────────
