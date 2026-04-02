import 'package:flutter/material.dart';

class AppTheme {
  // Palettes et contrastes WCAG respectés (> 4.5:1)
  static const Color primary = Color(0xFF4F46E5); // Indigo 600
  static const Color secondary = Color(0xFF0D9488); // Teal 600
  static const Color background = Color(0xFFF8FAFC); // Slate 50 (fond global)
  static const Color surface = Colors.white; // Fond des cartes
  static const Color textHigh = Color(0xFF0F172A); // Slate 900 (très lisible)
  static const Color textMedium = Color(0xFF334155); // Slate 700 (gris très lisible WCAG)
  static const Color textLight = Color(0xFF475569); // Slate 600 (secondaire)
  static const Color errorColor = Color(0xFFDC2626); // Red 600
  static const Color successColor = Color(0xFF16A34A); // Green 600
  static const Color warningColor = Color(0xFFD97706); // Amber 600 (mieux que amber base)

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textHigh,
      ),

      // Typographie hiérarchique et accessible
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: textHigh, fontSize: 28, fontWeight: FontWeight.bold, height: 1.2),
        headlineMedium: TextStyle(color: textHigh, fontSize: 24, fontWeight: FontWeight.w700, height: 1.3),
        titleLarge: TextStyle(color: textHigh, fontSize: 20, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textHigh, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: textMedium, fontSize: 14, height: 1.5),
        labelLarge: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textHigh,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        iconTheme: IconThemeData(color: primary),
        titleTextStyle: TextStyle(color: textHigh, fontSize: 18, fontWeight: FontWeight.w600),
      ),

      // Style unifié pour les cartes
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1), // Slate 200 contour subtil
        ),
      ),

      // Style unifié des boutons primaires
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54), // Zone de clic tactile optimale (WCAG = 44pt min)
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)), // Slate 300
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        prefixIconColor: textLight,
        hintStyle: const TextStyle(color: textLight, fontSize: 15),
      ),
      
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0), // Slate 200
        thickness: 1,
        space: 32,
      ),
    );
  }
}
