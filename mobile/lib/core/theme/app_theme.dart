import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

abstract final class PaceUpTheme {
  static ThemeData dark() {
    final colorScheme = const ColorScheme.dark(
      primary: PaceUpColors.electricGreen,
      onPrimary: PaceUpColors.greenInk,
      secondary: PaceUpColors.electricCyan,
      onSecondary: PaceUpColors.darkBackground,
      surface: PaceUpColors.darkPanel,
      onSurface: PaceUpColors.darkText,
      error: PaceUpColors.danger,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: PaceUpColors.darkBackground,

      textTheme: TextTheme(
        displayLarge: PaceUpTypography.display(PaceUpColors.darkText),
        headlineLarge: PaceUpTypography.heading(PaceUpColors.darkText),
        bodyLarge: PaceUpTypography.body(PaceUpColors.darkText),
        bodyMedium: PaceUpTypography.bodyMedium(PaceUpColors.darkText),
        labelLarge: PaceUpTypography.label(PaceUpColors.darkText),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: PaceUpColors.darkBackground,
        foregroundColor: PaceUpColors.darkText,
        elevation: 0,
        centerTitle: false,
      ),

      cardTheme: CardThemeData(
        color: PaceUpColors.darkPanel,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: PaceUpColors.darkBorder),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PaceUpColors.darkPanel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: PaceUpColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: PaceUpColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(
            color: PaceUpColors.electricCyan,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: PaceUpColors.darkPanel,
        indicatorColor: PaceUpColors.darkPanelSecondary,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: PaceUpColors.darkPanel,
        selectedColor: PaceUpColors.electricGreen,
        side: const BorderSide(color: PaceUpColors.darkBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        labelStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: PaceUpColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData light() {
    final colorScheme = const ColorScheme.light(
      primary: PaceUpColors.lightCyan,
      onPrimary: Colors.white,
      secondary: PaceUpColors.electricGreen,
      surface: PaceUpColors.lightPanel,
      onSurface: PaceUpColors.lightText,
      error: PaceUpColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: PaceUpColors.lightBackground,

      textTheme: TextTheme(
        displayLarge: PaceUpTypography.display(PaceUpColors.lightText),
        headlineLarge: PaceUpTypography.heading(PaceUpColors.lightText),
        bodyLarge: PaceUpTypography.body(PaceUpColors.lightText),
        bodyMedium: PaceUpTypography.bodyMedium(PaceUpColors.lightText),
        labelLarge: PaceUpTypography.label(PaceUpColors.lightText),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: PaceUpColors.lightBackground,
        foregroundColor: PaceUpColors.lightText,
        elevation: 0,
        centerTitle: false,
      ),

      cardTheme: CardThemeData(
        color: PaceUpColors.lightPanel,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: PaceUpColors.lightBorder),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PaceUpColors.lightPanel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: PaceUpColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: PaceUpColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(
            color: PaceUpColors.lightCyan,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: PaceUpColors.lightPanel,
        indicatorColor: PaceUpColors.lightPanelSecondary,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
