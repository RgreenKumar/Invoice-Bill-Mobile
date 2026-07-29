import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colors pulled directly from `src/assets/css/invoicestyle.css` so the
/// Flutter UI matches the original React look exactly rather than
/// approximating it.
class AppColors {
  // .inv-left-panel gradient / .inv-btn-login gradient
  static const darkStart = Color(0xFF0F2027);
  static const darkMid = Color(0xFF1A3A4A);
  static const darkEnd = Color(0xFF0D3B52);

  // SVG accent color used throughout login illustration (#4fc3f7)
  static const accent = Color(0xFF4FC3F7);

  static const cardWhite = Color(0xFFFFFFFF);
  static const textDark = darkStart;
  static const borderGrey = Color(0xFFE2E8F0);
  static const invalidRed = Color(0xFFE53935);
}

class AppGradients {
  static const leftPanel = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.darkStart, AppColors.darkMid, AppColors.darkEnd],
    stops: [0.0, 0.5, 1.0],
  );

  static const loginButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.darkStart, AppColors.darkMid, AppColors.darkEnd],
    stops: [0.0, 0.5, 1.0],
  );
}

class AppTheme {
  /// `.inv-card-login h3` used 'Playfair Display' (serif, 26px/700).
  static TextStyle get headingSerif => GoogleFonts.playfairDisplay(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      );

  /// Body font: the React app's default stack used the bundled Open Sans
  /// (see src/assets/fonts/opensans/*), so we mirror that here.
  static TextStyle get body => GoogleFonts.openSans();

  // Explicit, high-contrast text colors used throughout the theme below -
  // never left to a generated/ambiguous default.
  static const _textOnLight = Color(0xFF1A2027); // near-black, on white/#F4F6F8
  static const _textMutedOnLight = Color(0xFF5B6B79); // readable grey, on light bg
  static const _textOnDark = Color(0xFFFFFFFF); // on darkStart/darkMid/darkEnd

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4F6F8),
        // Every "on*" color set explicitly rather than relying on
        // ColorScheme.fromSeed's generated defaults, so text/icons on
        // colored surfaces (buttons, AppBar, chips) always have a
        // guaranteed-readable color instead of an auto-derived one.
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.darkMid,
          onPrimary: _textOnDark,
          secondary: AppColors.accent,
          onSecondary: AppColors.darkStart,
          error: AppColors.invalidRed,
          onError: _textOnDark,
          surface: Colors.white,
          onSurface: _textOnLight,
        ),
        textTheme: GoogleFonts.openSansTextTheme().apply(
          bodyColor: _textOnLight,
          displayColor: _textOnLight,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkMid,
          foregroundColor: _textOnDark, // title + icons, incl. drawer hamburger
          iconTheme: IconThemeData(color: _textOnDark),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: _textOnDark,
            backgroundColor: AppColors.darkMid,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            foregroundColor: _textOnDark,
            backgroundColor: AppColors.darkMid,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.darkMid),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.darkMid),
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
        ),
        listTileTheme: const ListTileThemeData(
          textColor: _textOnLight,
          iconColor: _textMutedOnLight,
        ),
        dataTableTheme: const DataTableThemeData(
          dataTextStyle: TextStyle(color: _textOnLight),
          headingTextStyle: TextStyle(color: _textOnLight, fontWeight: FontWeight.w600),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF7F9FA),
          labelStyle: const TextStyle(color: _textMutedOnLight),
          hintStyle: const TextStyle(color: _textMutedOnLight),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.borderGrey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.borderGrey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.invalidRed),
          ),
        ),
      );
}
