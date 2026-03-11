import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

// S15 §15.4 — Dark theme only. Manrope typeface with tabular lining numerals.
class ZxTheme {
  ZxTheme._();

  static TextTheme _buildTextTheme() {
    final base = GoogleFonts.manropeTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: TypographyTokens.displayXlSize,
        fontWeight: TypographyTokens.displayXlWeight,
        height: TypographyTokens.displayXlHeight,
        color: ColorTokens.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: TypographyTokens.displayLgSize,
        fontWeight: TypographyTokens.displayLgWeight,
        height: TypographyTokens.displayLgHeight,
        color: ColorTokens.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: TypographyTokens.headerSize,
        fontWeight: TypographyTokens.headerWeight,
        height: TypographyTokens.headerHeight,
        color: ColorTokens.textPrimary,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: TypographyTokens.bodyLgSize,
        fontWeight: TypographyTokens.bodyWeight,
        height: TypographyTokens.bodyLgHeight,
        color: ColorTokens.textPrimary,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: TypographyTokens.bodySize,
        fontWeight: TypographyTokens.bodyWeight,
        height: TypographyTokens.bodyHeight,
        color: ColorTokens.textPrimary,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: TypographyTokens.bodySmSize,
        fontWeight: TypographyTokens.bodySmWeight,
        height: TypographyTokens.bodySmHeight,
        color: ColorTokens.textSecondary,
      ),
    );
  }

  static ThemeData dark() {
    final textTheme = _buildTextTheme();
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ColorTokens.surfaceBase,
      colorScheme: const ColorScheme.dark(
        primary: ColorTokens.primaryDefault,
        onPrimary: ColorTokens.textPrimary,
        secondary: ColorTokens.primaryActive,
        onSecondary: ColorTokens.textPrimary,
        surface: ColorTokens.surfacePrimary,
        onSurface: ColorTokens.textPrimary,
        error: ColorTokens.errorDestructive,
        onError: ColorTokens.textPrimary,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: ColorTokens.surfacePrimary,
        foregroundColor: ColorTokens.textPrimary,
        elevation: 0,
        titleTextStyle: textTheme.headlineSmall,
      ),
      cardTheme: CardThemeData(
        color: ColorTokens.surfacePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
        ),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorTokens.surfaceRaised,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ShapeTokens.radiusInput),
          borderSide: const BorderSide(color: ColorTokens.surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ShapeTokens.radiusInput),
          borderSide: const BorderSide(color: ColorTokens.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ShapeTokens.radiusInput),
          borderSide:
              const BorderSide(color: ColorTokens.primaryDefault, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.sm,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ColorTokens.surfacePrimary,
        selectedItemColor: ColorTokens.primaryDefault,
        unselectedItemColor: ColorTokens.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: ColorTokens.surfaceBorder,
        thickness: 1,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: const TextStyle(fontSize: TypographyTokens.bodySize),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: const TextStyle(fontSize: TypographyTokens.bodySize),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontSize: TypographyTokens.bodySize),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: const TextStyle(fontSize: TypographyTokens.bodySize),
        ),
      ),
    );
  }
}
