import 'package:flutter/material.dart';

class AppColors {
  static const navyBg = Color(0xFF16294A);
  static const navBg = Color(0xFF0F2242);
  static const cardBg = Color(0xFF22385E);
  static const cardBorder = Color(0xFF33507B);
  static const accent = Color(0xFFF4A53A);
  static const textMuted = Color(0xFF9FB6D6);
  static const green = Color(0xFF2ECC71);
  static const greenDark = Color(0xFF1E8F5F);
  static const red = Color(0xFFFF6B6B);
  static const redDark = Color(0xFFC94C4C);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.navyBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.dark,
    ),
    fontFamily: 'Roboto',
  );
}
