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
  static ThemeData lightTheme([Color? customPrimary, Color? customNavy, Color? customTextColor, Color? customHighlightTextColor]) {
    final primaryAccent = customPrimary ?? AppColors.gold;
    final primaryNav = customNavy ?? AppColors.navy;
    final textColor = customTextColor ?? AppColors.charcoalGray;
    final highlightTextColor = customHighlightTextColor ?? primaryAccent;
    
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primaryNav,
        onPrimary: AppColors.white,
        secondary: primaryAccent,
        onSecondary: highlightTextColor,
        error: Colors.redAccent,
        onError: AppColors.white,
        surface: AppColors.white,
        onSurface: textColor,
        onSurfaceVariant: textColor.withValues(alpha: 0.7),
        outline: AppColors.dividerGray,
        outlineVariant: AppColors.lightGray,
        tertiary: primaryAccent,
      ),
      scaffoldBackgroundColor: AppColors.white,
    );

    return baseTheme.copyWith(
      primaryColor: primaryNav,
      focusColor: Colors.transparent,
      highlightColor: primaryAccent.withOpacity(0.1),
      splashColor: primaryAccent.withOpacity(0.1),
      hoverColor: primaryAccent.withOpacity(0.05),
      shadowColor: Colors.black.withOpacity(0.1),
      canvasColor: AppColors.white,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryAccent,
        selectionColor: primaryAccent.withOpacity(0.3),
        selectionHandleColor: primaryAccent,
      ),
      textTheme: GoogleFonts.outfitTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold),
        headlineSmall: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold),
        titleMedium: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold),
        titleSmall: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold),
        bodyLarge: GoogleFonts.outfit(color: textColor),
        bodyMedium: GoogleFonts.outfit(color: textColor),
        bodySmall: GoogleFonts.outfit(color: textColor),
        labelLarge: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.8)),
        labelMedium: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.8)),
        labelSmall: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.8)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryNav,
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
        indicatorColor: primaryAccent.withOpacity(0.2),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: highlightTextColor,
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
          borderSide: BorderSide(color: primaryAccent, width: 2),
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
        floatingLabelStyle: TextStyle(color: primaryAccent),
      ),
    );
  }
}
