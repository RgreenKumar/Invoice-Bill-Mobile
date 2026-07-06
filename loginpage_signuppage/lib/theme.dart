import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InvoiceBillTheme {
  // Theme Color Scheme
  static const Color darkBlueBg = Color(0xFF183548); // Deep Slate Dark Blue
  static const Color primaryBlue = Color(0xFF2563EB); // Enterprise Royal Blue
  static const Color accentBlue = Color(0xFF60A5FA); // Ice Blue Accent
  static const Color cardBg = Colors.white; // Solid Card White
  static const Color glassWhite = Color(0x0FFFFFFF); // White for glassmorphism
  static const Color glassBorder = Color(0x33FFFFFF); // White border for glassmorphism
  
  static const Color successGreen = Color(0xFF10B981); // Mint Emerald Green
  static const Color errorRed = Color(0xFFEF4444); // Crimson Error Red
  static const Color textDark = Color(0xFF1F2937); // Very Dark Grey
  static const Color textMuted = Color(0xFF6B7280); // Slate Muted Grey
  static const Color inputBorder = Color(0xFFE5E7EB); // Cool grey for inputs
  static const Color inputFocusBorder = Color(0xFF3B82F6); // Focus blue

  // Text Styles
  static TextStyle serifHeading({
    double fontSize = 28.0,
    FontWeight fontWeight = FontWeight.bold,
    Color color = textDark,
  }) {
    return GoogleFonts.lora(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: 1.25,
    );
  }

  static TextStyle sansBody({
    double fontSize = 14.0,
    FontWeight fontWeight = FontWeight.normal,
    Color color = textMuted,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: 1.5,
    );
  }

  static TextStyle sansHeader({
    double fontSize = 16.0,
    FontWeight fontWeight = FontWeight.w600,
    Color color = textDark,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextStyle buttonText({
    double fontSize = 15.0,
    FontWeight fontWeight = FontWeight.w600,
    Color color = Colors.white,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: 0.2,
    );
  }

  // Box Decoration Styles
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardBg,
    borderRadius: BorderRadius.circular(20.0),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 24.0,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: primaryBlue.withOpacity(0.02),
        blurRadius: 40.0,
        offset: const Offset(0, 16),
      ),
    ],
  );

  static BoxDecoration glassDecoration = BoxDecoration(
    color: glassWhite,
    borderRadius: BorderRadius.circular(20.0),
    border: Border.all(color: glassBorder, width: 1.5),
  );

  // Theme Data Builder
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: darkBlueBg,
      primaryColor: primaryBlue,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: accentBlue,
        surface: cardBg,
        error: errorRed,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(),
    );
  }
}
