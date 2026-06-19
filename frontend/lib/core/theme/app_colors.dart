import 'package:flutter/material.dart';

abstract class AppColors {
  // Primárias
  static const Color primary = Color(0xFF1D9E75);
  static const Color primaryDark = Color(0xFF0F6E56);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFF5DCAA5);

  // Fundos — light
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEEEEEE);
  static const Color divider = Color(0xFFE0E0E0);

  // Fundos — dark
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVariantDark = Color(0xFF2C2C2C);
  static const Color dividerDark = Color(0xFF3A3A3A);

  // Textos — light
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // Textos — dark
  static const Color textPrimaryDark = Color(0xFFECECEC);
  static const Color textSecondaryDark = Color(0xFFAAAAAA);
  static const Color textHintDark = Color(0xFF555555);

  // Semânticas (iguais nos dois temas)
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF1976D2);

  // Quadro — light
  static const Color canvasBackground = Color(0xFFFFFFFF);
  static const Color strokeDefault = Color(0xFF212121);
  static const Color strokeSelected = Color(0xFF1D9E75);
  static const Color objectFill = Color(0xFFFFFFFF);

  // Quadro — dark
  static const Color canvasBackgroundDark = Color(0xFF1A1A1A);
  static const Color strokeDefaultDark = Color(0xFFECECEC);
  static const Color strokeSelectedDark = Color(0xFF5DCAA5);
  static const Color objectFillDark = Color(0xFF2C2C2C);

  // Neutras
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey900 = Color(0xFF212121);
}
