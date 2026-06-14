import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeMode { lightRed, darkSlate, goldLuxury }

class AppThemes {
  static ThemeData getTheme(AppThemeMode mode) {
    final baseTextTheme = GoogleFonts.interTextTheme();
    final outfitTheme = GoogleFonts.outfitTextTheme();

    // Custom TextTheme that merges Inter as body and Outfit as headlines
    final textTheme = baseTextTheme.copyWith(
      displayLarge: outfitTheme.displayLarge,
      displayMedium: outfitTheme.displayMedium,
      displaySmall: outfitTheme.displaySmall,
      headlineLarge: outfitTheme.headlineLarge,
      headlineMedium: outfitTheme.headlineMedium,
      headlineSmall: outfitTheme.headlineSmall,
      titleLarge: outfitTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      titleMedium: outfitTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      titleSmall: outfitTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
    );

    switch (mode) {
      case AppThemeMode.lightRed:
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          textTheme: textTheme,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE53935)),
          scaffoldBackgroundColor: const Color(
            0xFFF8FAFC,
          ), // Soft gray-blue background
          cardTheme: CardThemeData(
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        );
      case AppThemeMode.darkSlate:
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          textTheme: textTheme.apply(
            bodyColor: const Color(0xFFF1F5F9),
            displayColor: Colors.white,
          ),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF38BDF8), // Bright Sky Blue
            secondary: Color(0xFF34D399), // Emerald
            surface: Color(0xFF1E293B),
            onSurface: Color(0xFFF1F5F9),
          ),
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          cardTheme: CardThemeData(
            color: const Color(0xFF1E293B),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF334155)),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0F172A),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        );
      case AppThemeMode.goldLuxury:
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          textTheme: textTheme,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFD4AF37), // Metallic Gold
            primary: const Color(0xFFB58920),
            secondary: const Color(0xFF7A5F15),
          ),
          scaffoldBackgroundColor: const Color(
            0xFFFCFBF7,
          ), // Warm premium beige
          cardTheme: CardThemeData(
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFEFEAD8)),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFB58920),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        );
    }
  }
}
