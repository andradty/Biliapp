import 'package:flutter/material.dart';

class AppColors {
  static const teal = Color(0xFF0B7A93);
  static const teal2 = Color(0xFF16A3C4);

  // Gradient oranye tombol (5% #FCB712 -> 100% #FF8806)
  static const orange1 = Color(0xFFFCB712);
  static const orange2 = Color(0xFFFF8806);

  static const ink = Color(0xFF16324A);
  static const muted = Color(0xFF5B6B7A);

  // Gradien background Figma: biru muda lembut ke krem hangat di bawah
  static const bg1 = Color(0xFFE8F5FA);
  static const bg2 = Color(0xFFFBEFD7);
}

const bgGradient = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFEAF5FA),
      Color(0xFFF2F6F7),
      Color(0xFFFBEFD9),
    ],
    stops: [0.0, 0.52, 1.0],
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
