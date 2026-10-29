import 'package:flutter/material.dart';

class AppColors {
  static const teal = Color(0xFF0B7A93);
  static const teal2 = Color(0xFF16A3C4);
  static const orange1 = Color(0xFFFFB400);
  static const orange2 = Color(0xFFFF8A00);
  static const ink = Color(0xFF16324A);
  static const muted = Color(0xFF5B6B7A);
  static const bg1 = Color(0xFFE6F4FA);
  static const bg2 = Color(0xFFFCEBD5);
}

const bgGradient = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.bg1, AppColors.bg2],
  ),
);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.teal),
  );
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg1,
    textTheme: base.textTheme
        .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
  );
}
