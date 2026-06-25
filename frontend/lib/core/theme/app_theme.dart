import 'package:flutter/material.dart';

abstract class AppTheme {
  static ThemeData build(Color seedColor, Brightness brightness) {
    var colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    if (brightness == Brightness.light) {
      // ColorScheme.fromSeed suaviza demais o tom primário no claro;
      // usamos a cor-semente em força total para um visual mais vivo.
      colorScheme = colorScheme.copyWith(
        primary: seedColor,
        onPrimary: Colors.white,
        secondaryContainer: Color.lerp(seedColor, Colors.white, 0.65),
        onSecondaryContainer: Color.lerp(seedColor, Colors.black, 0.35),
        outline: Color.lerp(seedColor, Colors.black, 0.1),
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surfaceContainerLowest,
      dividerColor: colorScheme.outlineVariant,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surfaceContainerLowest,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
        bodyMedium:     TextStyle(fontSize: 16, color: colorScheme.onSurface),
        bodySmall:      TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}
