import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color navy = Color(0xFF081020);
  static const Color dark = Color(0xFF111827);
  static const Color surface = Color(0xFF121A2E);
  static const Color surfaceElevated = Color(0xFF18213A);
  static const Color yellow = Color(0xFFFFB800);
  static const Color cyan = Color(0xFF00D4FF);
  static const Color purple = Color(0xFF6C5CE7);
  static const Color white = Color(0xFFFFFFFF);
  static const Color red = Color(0xFFFF4757);
  static const Color green = Color(0xFF2ED573);
  static const Color textSecondary = Color(0xFFB0BAC9);
  static const Color textMuted = Color(0xFF6B7A93);
  static const Color borderSubtle = Color(0x331E2D45);
}

class AppTheme {
  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.yellow,
      brightness: Brightness.dark,
      primary: AppColors.yellow,
      secondary: AppColors.cyan,
      surface: AppColors.surface,
    );

    final textTheme = GoogleFonts.dmSansTextTheme().apply(
      bodyColor: AppColors.white,
      displayColor: AppColors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.navy,
      canvasColor: AppColors.navy,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
      ),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.symmetric(vertical: 8),
        elevation: 0,
        color: AppColors.surface,
      ),
      textTheme: textTheme.copyWith(
        titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x33FFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x33FFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.yellow, width: 1.4),
        ),
        labelStyle: const TextStyle(color: Color(0xCCFFFFFF)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.dark,
        indicatorColor: const Color(0x22FFB800),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.yellow,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.white,
          side: const BorderSide(color: Color(0x14FFFFFF)),
          minimumSize: const Size.fromHeight(46),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  static ThemeData get lightTheme => darkTheme;
}
