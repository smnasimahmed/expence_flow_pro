import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF6C63FF);
  static const primaryDark = Color(0xFF4B44CC);
  static const background = Color(0xFF0F0F1A);
  static const surface = Color(0xFF1C1C2E);
  static const surfaceLight = Color(0xFF252538);
  static const white = Color(0xFFFFFFFF);
  static const grey = Color(0xFF8E8E9E);
  static const greyLight = Color(0xFFD1D1E0);
  static const red = Color(0xFFFF5C5C);
  static const green = Color(0xFF4CAF82);
  static const orange = Color(0xFFFF9800);
  static const yellow = Color(0xFFFFD600);

  static const cardGradientStart = Color(0xFF6C63FF);
  static const cardGradientEnd = Color(0xFF4B44CC);

  // Category colors
  static const food = Color(0xFFFF6B6B);
  static const transport = Color(0xFF4ECDC4);
  static const shopping = Color(0xFFFFBE0B);
  static const health = Color(0xFF06D6A0);
  static const entertainment = Color(0xFFFF006E);
  static const bills = Color(0xFF3A86FF);
  static const salary = Color(0xFF4CAF82);
  static const other = Color(0xFF8E8E9E);
}

ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primary,
    surface: AppColors.surface,
    background: AppColors.background,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: AppColors.white,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    iconTheme: IconThemeData(color: AppColors.white),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceLight,
    hintStyle: const TextStyle(color: AppColors.grey),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.red),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      minimumSize: const Size(double.infinity, 52),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
  ),
);
