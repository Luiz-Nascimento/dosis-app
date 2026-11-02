import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cores medidas do protótipo de alta fidelidade.
class AppColors {
  const AppColors._();

  static const yellow = Color(0xFFFFD60A);
  static const orange = Color(0xFFFF9A22);
  static const orangeSoft = Color(0xFF3A2612);
  static const background = Color(0xFF141414);
  static const card = Color(0xFF1B1B1D);
  static const surface = Color(0xFF232326);
  static const navBar = Color(0xFF1A1B1F);
  static const border = Color(0xFF2E2E32);
  static const muted = Color(0xFF9A9A9F);
}

class AppTheme {
  const AppTheme._();

  static TextStyle get logo =>
      GoogleFonts.oswald(color: AppColors.yellow, fontSize: 26, fontWeight: FontWeight.w700);

  static ThemeData get dark {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    );
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color),
        );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.yellow,
        onPrimary: Colors.black,
        secondary: AppColors.orange,
        surface: AppColors.card,
        onSurface: Colors.white,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.yellow,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(54),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: AppColors.border),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
        border: border(AppColors.border),
        enabledBorder: border(AppColors.border),
        focusedBorder: border(AppColors.yellow),
      ),
    );
  }
}