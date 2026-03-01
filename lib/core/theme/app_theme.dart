import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color navy = Color(0xFF001F3F);
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFFFF8E7);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color mediumGray = Color(0xFF808080);
  static const Color charcoalGray = Color(0xFF333333);
  static const Color dividerGray = Color(0xFFEEEEEE);
  
  // Custom transparent white used for input fields
  static final Color inputFillColor = white.withOpacity(0.1);
}

class AppTheme {
  static ThemeData get lightTheme {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.navy,
        onPrimary: AppColors.white,
        secondary: AppColors.gold,
        onSecondary: AppColors.navy,
        error: Colors.redAccent,
        onError: AppColors.white,
        surface: AppColors.white,
        onSurface: AppColors.navy,
        outline: AppColors.dividerGray,
        outlineVariant: AppColors.lightGray,
        tertiary: AppColors.gold,
      ),
      scaffoldBackgroundColor: AppColors.white,
    );

    return baseTheme.copyWith(
      primaryColor: AppColors.navy,
      highlightColor: AppColors.gold.withOpacity(0.1),
      splashColor: AppColors.gold.withOpacity(0.1),
      hoverColor: AppColors.gold.withOpacity(0.05),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.gold,
        selectionColor: AppColors.gold.withOpacity(0.3),
        selectionHandleColor: AppColors.gold,
      ),
      textTheme: GoogleFonts.outfitTextTheme(baseTheme.textTheme).copyWith(
        headlineLarge: GoogleFonts.outfit(
          textStyle: baseTheme.textTheme.headlineLarge,
          fontWeight: FontWeight.bold,
          color: AppColors.navy,
        ),
        headlineMedium: GoogleFonts.outfit(
          textStyle: baseTheme.textTheme.headlineMedium,
          fontWeight: FontWeight.bold,
          color: AppColors.navy,
        ),
        titleLarge: GoogleFonts.outfit(
          textStyle: baseTheme.textTheme.titleLarge,
          fontWeight: FontWeight.bold,
          color: AppColors.navy,
        ),
        bodyLarge: GoogleFonts.outfit(
          textStyle: baseTheme.textTheme.bodyLarge,
          color: AppColors.charcoalGray,
        ),
        bodyMedium: GoogleFonts.outfit(
          textStyle: baseTheme.textTheme.bodyMedium,
          color: AppColors.charcoalGray,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        surfaceTintColor: Colors.transparent,
        color: AppColors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.gold.withOpacity(0.2),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.navy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.mediumGray),
        floatingLabelStyle: const TextStyle(color: AppColors.gold),
      ),
    );
  }
}
