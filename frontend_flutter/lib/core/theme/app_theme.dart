import 'package:flutter/material.dart';

class AppTheme {
  // Palette Indigo Unifiée
  static const Color primaryColor = Color(0xFF4F46E5);
  static const Color highContrastPrimary = Color(0xFF1E1B4B);

  static ThemeData get lightTheme => _createTheme(
        ColorScheme.light(
          primary: primaryColor,
          secondary: const Color(0xFF0D9488),
          surface: Colors.white,
          background: const Color(0xFFF8FAFC),
          error: const Color(0xFFDC2626),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: const Color(0xFF0F172A),
        ),
      );

  static ThemeData get highContrastTheme => _createTheme(
        const ColorScheme.light(
          primary: highContrastPrimary,
          secondary: Color(0xFF004D40),
          surface: Colors.white,
          background: Colors.white,
          error: Color(0xFF7F1D1D),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.black,
        ),
        isHighContrast: true,
      );

  static ThemeData _createTheme(ColorScheme cs, {bool isHighContrast = false}) {
    final textHigh = isHighContrast ? Colors.black : const Color(0xFF0F172A);
    final textMedium = isHighContrast ? Colors.black : const Color(0xFF334155);

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.background,
      
      textTheme: TextTheme(
        headlineLarge: TextStyle(color: textHigh, fontSize: 28, fontWeight: FontWeight.bold, height: 1.2),
        headlineMedium: TextStyle(color: textHigh, fontSize: 24, fontWeight: FontWeight.w700, height: 1.3),
        titleLarge: TextStyle(color: textHigh, fontSize: 20, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textHigh, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: textMedium, fontSize: 14, height: 1.5),
        labelLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: isHighContrast ? Colors.white : cs.primary,
        foregroundColor: isHighContrast ? Colors.black : Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: isHighContrast ? cs.primary : Colors.white),
        titleTextStyle: TextStyle(
          color: isHighContrast ? Colors.black : Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      cardTheme: CardThemeData(
        color: cs.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isHighContrast ? Colors.black : const Color(0xFFE2E8F0),
            width: isHighContrast ? 2 : 1,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isHighContrast ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isHighContrast ? Colors.black : const Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isHighContrast ? Colors.black : const Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: isHighContrast ? 3 : 2),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: isHighContrast ? Colors.black : const Color(0xFFE2E8F0),
        thickness: isHighContrast ? 2 : 1,
        space: 32,
      ),
    );
  }
}
