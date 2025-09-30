import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Light colors
  static const primaryLight = Color(0xFF6366F1);
  static const primaryVariantLight = Color(0xFF4F46E5);
  static const secondaryLight = Color(0xFF8B5CF6);
  static const secondaryVariantLight = Color(0xFF7C3AED);
  static const backgroundLight = Color(0xFFFAFAFA);
  static const surfaceLight = Colors.white;
  static const errorLight = Color(0xFFEF4444);
  static const successLight = Color(0xFF10B981);
  static const warningLight = Color(0xFFF59E0B);
  static const onPrimaryLight = Colors.white;
  static const onSecondaryLight = Colors.white;
  static const onBackgroundLight = Color(0xFF111827);
  static const onSurfaceLight = Color(0xFF111827);
  static const onErrorLight = Colors.white;
  static const shadowLight = Color(0x33000000);
  static const dividerLight = Color(0x1A111827);
  static const textSecondaryLight = Color(0xFF6B7280);
  static const textDisabledLight = Color(0xFF9CA3AF);

  // Dark colors
  static const primaryDark = Color(0xFF8B5CF6);
  static const primaryVariantDark = Color(0xFF7C3AED);
  static const secondaryDark = Color(0xFF6366F1);
  static const secondaryVariantDark = Color(0xFF4F46E5);
  static const backgroundDark = Color(0xFF0F172A);
  static const surfaceDark = Color(0xFF1E293B);
  static const errorDark = Color(0xFFEF4444);
  static const successDark = Color(0xFF10B981);
  static const warningDark = Color(0xFFF59E0B);
  static const onPrimaryDark = Colors.white;
  static const onSecondaryDark = Colors.white;
  static const onBackgroundDark = Color(0xFFF8FAFC);
  static const onSurfaceDark = Color(0xFFF8FAFC);
  static const onErrorDark = Colors.white;
  static const shadowDark = Color(0x33000000);
  static const dividerDark = Color(0x1AF8FAFC);
  static const textSecondaryDark = Color(0xFFCBD5E1);
  static const textDisabledDark = Color(0xFF64748B);

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: primaryLight,
      onPrimary: onPrimaryLight,
      primaryContainer: primaryVariantLight,
      onPrimaryContainer: onPrimaryLight,
      secondary: secondaryLight,
      onSecondary: onSecondaryLight,
      secondaryContainer: secondaryVariantLight,
      onSecondaryContainer: onSecondaryLight,
      tertiary: successLight,
      onTertiary: onPrimaryLight,
      tertiaryContainer: Color.fromRGBO(16, 185, 129, 0.1),
      onTertiaryContainer: successLight,
      error: errorLight,
      onError: onErrorLight,
      surface: surfaceLight,
      onSurface: onSurfaceLight,
      onSurfaceVariant: textSecondaryLight,
      outline: dividerLight,
      outlineVariant: Color.fromRGBO(17, 24, 39, 0.05),
      shadow: shadowLight,
      scrim: shadowLight,
      inverseSurface: surfaceDark,
      onInverseSurface: onSurfaceDark,
      inversePrimary: primaryDark,
    ),
    scaffoldBackgroundColor: backgroundLight,
    cardTheme: const CardThemeData(
      color: surfaceLight,
      elevation: 2,
      shadowColor: shadowLight,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      margin: EdgeInsets.all(8),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceLight,
      foregroundColor: onSurfaceLight,
      elevation: 2,
      shadowColor: shadowLight,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onSurfaceLight,
      ),
      iconTheme: const IconThemeData(color: onSurfaceLight),
      actionsIconTheme: const IconThemeData(color: onSurfaceLight),
    ),
    textTheme: _textTheme(isLight: true),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: primaryDark,
      onPrimary: onPrimaryDark,
      primaryContainer: primaryVariantDark,
      onPrimaryContainer: onPrimaryDark,
      secondary: secondaryDark,
      onSecondary: onSecondaryDark,
      secondaryContainer: secondaryVariantDark,
      onSecondaryContainer: onSecondaryDark,
      tertiary: successDark,
      onTertiary: onPrimaryDark,
      tertiaryContainer: Color.fromRGBO(16, 185, 129, 0.2),
      onTertiaryContainer: successDark,
      error: errorDark,
      onError: onErrorDark,
      surface: surfaceDark,
      onSurface: onSurfaceDark,
      onSurfaceVariant: textSecondaryDark,
      outline: dividerDark,
      outlineVariant: Color.fromRGBO(248, 250, 252, 0.05),
      shadow: shadowDark,
      scrim: shadowDark,
      inverseSurface: surfaceLight,
      onInverseSurface: onSurfaceLight,
      inversePrimary: primaryLight,
    ),
    scaffoldBackgroundColor: backgroundDark,
    cardTheme: const CardThemeData(
      color: surfaceDark,
      elevation: 2,
      shadowColor: shadowDark,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      margin: EdgeInsets.all(8),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceDark,
      foregroundColor: onSurfaceDark,
      elevation: 2,
      shadowColor: shadowDark,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onSurfaceDark,
      ),
      iconTheme: const IconThemeData(color: onSurfaceDark),
      actionsIconTheme: const IconThemeData(color: onSurfaceDark),
    ),
    textTheme: _textTheme(isLight: false),
  );

  static TextTheme _textTheme({required bool isLight}) {
    final base = GoogleFonts.interTextTheme();
    final primary = isLight ? onSurfaceLight : onSurfaceDark;
    final secondary = isLight ? textSecondaryLight : textSecondaryDark;

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(color: primary, fontWeight: FontWeight.w700),
      displayMedium: base.displayMedium?.copyWith(color: primary, fontWeight: FontWeight.w700),
      displaySmall: base.displaySmall?.copyWith(color: primary, fontWeight: FontWeight.w700),
      headlineLarge: base.headlineLarge?.copyWith(color: primary, fontWeight: FontWeight.w700),
      headlineMedium: base.headlineMedium?.copyWith(color: primary, fontWeight: FontWeight.w600),
      headlineSmall: base.headlineSmall?.copyWith(color: primary, fontWeight: FontWeight.w600),
      titleLarge: base.titleLarge?.copyWith(color: primary, fontWeight: FontWeight.w600),
      titleMedium: base.titleMedium?.copyWith(color: primary, fontWeight: FontWeight.w600),
      titleSmall: base.titleSmall?.copyWith(color: primary, fontWeight: FontWeight.w600),
      bodyLarge: base.bodyLarge?.copyWith(color: secondary),
      bodyMedium: base.bodyMedium?.copyWith(color: secondary),
      bodySmall: base.bodySmall?.copyWith(color: secondary),
      labelLarge: base.labelLarge?.copyWith(color: primary, fontWeight: FontWeight.w600),
      labelMedium: base.labelMedium?.copyWith(color: primary, fontWeight: FontWeight.w600),
      labelSmall: base.labelSmall?.copyWith(color: primary, fontWeight: FontWeight.w600),
    );
  }
}