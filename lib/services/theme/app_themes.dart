import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeMode { lightRed, darkSlate, goldLuxury, cyberMidnight, nordicMint }

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
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE11D48),
            primary: const Color(0xFFE11D48),
            secondary: const Color(0xFFBE123C),
          ),
          scaffoldBackgroundColor: const Color(0xFFFAF9F6),
          cardTheme: CardThemeData(
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.03),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFFF1EFE9)),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFFAF9F6),
            foregroundColor: Color(0xFF1C1917),
            elevation: 0,
          ),
        );
      case AppThemeMode.darkSlate:
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          textTheme: textTheme.apply(
            bodyColor: const Color(0xFFE2E8F0),
            displayColor: Colors.white,
          ),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF38BDF8),
            secondary: Color(0xFF34D399),
            surface: Color(0xFF151D2A),
            onSurface: Color(0xFFE2E8F0),
          ),
          scaffoldBackgroundColor: const Color(0xFF090D16),
          cardTheme: CardThemeData(
            color: const Color(0xFF151D2A),
            surfaceTintColor: Colors.transparent,
            elevation: 4,
            shadowColor: Colors.black.withValues(alpha: 0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFF222F43)),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF090D16),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        );
      case AppThemeMode.goldLuxury:
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          textTheme: textTheme.apply(
            bodyColor: const Color(0xFFEFEAD8),
            displayColor: const Color(0xFFF5E0A3),
          ),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFD4AF37),
            secondary: Color(0xFFB58920),
            surface: Color(0xFF1E1E1E),
            onSurface: Color(0xFFEFEAD8),
          ),
          scaffoldBackgroundColor: const Color(0xFF121212),
          cardTheme: CardThemeData(
            color: const Color(0xFF1E1E1E),
            surfaceTintColor: Colors.transparent,
            elevation: 6,
            shadowColor: const Color(0xFFD4AF37).withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFF332B15)),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF121212),
            foregroundColor: Color(0xFFD4AF37),
            elevation: 0,
          ),
        );
      case AppThemeMode.cyberMidnight:
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          textTheme: textTheme.apply(
            bodyColor: const Color(0xFFE2E8F0),
            displayColor: const Color(0xFFF472B6),
          ),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFD946EF), // Neon Pink/Magenta
            secondary: Color(0xFF8B5CF6), // Neon Purple
            surface: Color(0xFF120E25),
            onSurface: Color(0xFFE2E8F0),
          ),
          scaffoldBackgroundColor: const Color(0xFF07040F),
          cardTheme: CardThemeData(
            color: const Color(0xFF120E25),
            surfaceTintColor: Colors.transparent,
            elevation: 6,
            shadowColor: const Color(0xFFD946EF).withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFF2E224E)),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF07040F),
            foregroundColor: Color(0xFFD946EF),
            elevation: 0,
          ),
        );
      case AppThemeMode.nordicMint:
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          textTheme: textTheme,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F766E), // Teal Mint
            primary: const Color(0xFF0F766E),
            secondary: const Color(0xFF10B981),
          ),
          scaffoldBackgroundColor: const Color(0xFFF7FDF9),
          cardTheme: CardThemeData(
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 3,
            shadowColor: const Color(0xFF10B981).withValues(alpha: 0.04),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFFDCFCE7)),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF7FDF9),
            foregroundColor: Color(0xFF0F766E),
            elevation: 0,
          ),
        );
    }
  }
}
