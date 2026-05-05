import 'package:flutter/material.dart';

import 'app_colors.dart';

// ── Light theme ───────────────────────────────────────────────────────────────

final ThemeData lightTheme = _buildTheme(
  colorScheme: const ColorScheme(
    brightness: Brightness.light,

    primary: AppColors.primary,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: AppColors.lightPrimaryContainer,
    onPrimaryContainer: AppColors.lightOnPrimaryContainer,

    secondary: AppColors.secondary,
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: AppColors.lightSecondaryContainer,
    onSecondaryContainer: AppColors.lightOnSecondaryContainer,

    tertiary: AppColors.tertiary,
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: AppColors.lightTertiaryContainer,
    onTertiaryContainer: AppColors.lightOnTertiaryContainer,

    error: AppColors.error,
    onError: Color(0xFFFFFFFF),
    errorContainer: AppColors.lightErrorContainer,
    onErrorContainer: AppColors.lightOnErrorContainer,

    surface: AppColors.lightSurface,
    onSurface: AppColors.lightOnSurface,
    onSurfaceVariant: AppColors.lightOnSurfaceVariant,

    outline: AppColors.lightOutline,
    outlineVariant: AppColors.lightOutlineVariant,

    surfaceContainerHighest: AppColors.lightSurfaceContainerHighest,
    surfaceContainerHigh: AppColors.lightSurfaceContainerHigh,
    surfaceContainer: AppColors.lightSurfaceContainer,
    surfaceContainerLow: AppColors.lightSurfaceContainerLow,
    surfaceContainerLowest: AppColors.lightSurfaceContainerLowest,

    inverseSurface: AppColors.lightOnSurface,
    onInverseSurface: Color(0xFFF1F5F9),
    inversePrimary: AppColors.darkPrimary,

    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  ),
  scaffoldBg: AppColors.lightBackground,
  appBarBg: AppColors.primary,
  appBarFg: const Color(0xFFFFFFFF),
  cardColor: AppColors.lightSurface,
  cardShadow: const Color(0x14000000), // 8% black
);

// ── Dark theme ────────────────────────────────────────────────────────────────

final ThemeData darkTheme = _buildTheme(
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,

    primary: AppColors.darkPrimary,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: AppColors.darkPrimaryContainer,
    onPrimaryContainer: AppColors.darkOnPrimaryContainer,

    secondary: AppColors.darkSecondary,
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: AppColors.darkSecondaryContainer,
    onSecondaryContainer: AppColors.darkOnSecondaryContainer,

    tertiary: AppColors.tertiary,
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: AppColors.darkTertiaryContainer,
    onTertiaryContainer: AppColors.darkOnTertiaryContainer,

    error: AppColors.error,
    onError: Color(0xFFFFFFFF),
    errorContainer: AppColors.darkErrorContainer,
    onErrorContainer: AppColors.darkOnErrorContainer,

    surface: AppColors.darkSurface,
    onSurface: AppColors.darkOnSurface,
    onSurfaceVariant: AppColors.darkOnSurfaceVariant,

    outline: AppColors.darkOutline,
    outlineVariant: AppColors.darkOutlineVariant,

    surfaceContainerHighest: AppColors.darkSurfaceContainerHighest,
    surfaceContainerHigh: AppColors.darkSurfaceContainerHigh,
    surfaceContainer: AppColors.darkSurfaceContainer,
    surfaceContainerLow: AppColors.darkSurfaceContainerLow,
    surfaceContainerLowest: AppColors.darkSurfaceContainerLowest,

    inverseSurface: AppColors.darkOnSurface,
    onInverseSurface: AppColors.darkSurface,
    inversePrimary: AppColors.primary,

    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  ),
  scaffoldBg: AppColors.darkBackground,
  appBarBg: AppColors.darkSurface,
  appBarFg: AppColors.darkOnSurface,
  cardColor: AppColors.darkSurface,
  cardShadow: const Color(0x3D000000), // 24% black
);

// ── Shared builder ────────────────────────────────────────────────────────────

ThemeData _buildTheme({
  required ColorScheme colorScheme,
  required Color scaffoldBg,
  required Color appBarBg,
  required Color appBarFg,
  required Color cardColor,
  required Color cardShadow,
}) {
  return ThemeData.from(colorScheme: colorScheme, useMaterial3: true).copyWith(
    scaffoldBackgroundColor: scaffoldBg,

    appBarTheme: AppBarTheme(
      backgroundColor: appBarBg,
      foregroundColor: appBarFg,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: appBarFg),
      actionsIconTheme: IconThemeData(color: appBarFg),
      titleTextStyle: TextStyle(
        color: appBarFg,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    ),

    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 2,
      shadowColor: cardShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      filled: true,
      fillColor: colorScheme.surfaceContainerLowest,
    ),

    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 1,
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide(color: colorScheme.outline),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        foregroundColor: colorScheme.primary,
      ),
    ),

    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 6,
      backgroundColor: cardColor,
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
    ),

    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colorScheme.onPrimary;
        return colorScheme.onSurfaceVariant;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colorScheme.primary;
        return colorScheme.surfaceContainerHighest;
      }),
    ),

    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
      linearTrackColor: colorScheme.primaryContainer,
    ),

    textTheme: TextTheme(
      displayLarge: TextStyle(color: colorScheme.onSurface),
      displayMedium: TextStyle(color: colorScheme.onSurface),
      displaySmall: TextStyle(color: colorScheme.onSurface),
      headlineLarge: TextStyle(
          color: colorScheme.onSurface, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(
          color: colorScheme.onSurface, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(
          color: colorScheme.onSurface, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(
          color: colorScheme.onSurface, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(
          color: colorScheme.onSurface, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(color: colorScheme.onSurface),
      bodyLarge: TextStyle(color: colorScheme.onSurface),
      bodyMedium: TextStyle(color: colorScheme.onSurface),
      bodySmall: TextStyle(color: colorScheme.onSurfaceVariant),
      labelLarge: TextStyle(color: colorScheme.onSurface),
      labelMedium: TextStyle(color: colorScheme.onSurfaceVariant),
      labelSmall: TextStyle(color: colorScheme.onSurfaceVariant),
    ),
  );
}
