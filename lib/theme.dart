import 'package:flutter/material.dart';
import 'package:fluttersdk_wind/fluttersdk_wind.dart';

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

MaterialColor _swatch(int base) {
  final c = Color(base);
  Color l(double t) => Color.lerp(c, Colors.white, t)!;
  Color d(double t) => Color.lerp(c, Colors.black, t)!;
  return MaterialColor(base, {
    50: l(.92), 100: l(.82), 200: l(.64), 300: l(.46), 400: l(.24),
    500: c,
    600: d(.12), 700: d(.28), 800: d(.44), 900: d(.60),
  });
}

WindThemeData buildWindTheme() => WindThemeData(
      colors: {
        'brand':  _swatch(0xFF0B7A93), // AppColors.teal
        'accent': _swatch(0xFFFF8A00), // AppColors.orange2
        'ink':    _swatch(0xFF16324A), // AppColors.ink
        'ok':     _swatch(0xFF17803D), // status normal
        'danger': _swatch(0xFFC62828), // status kritis
      },
    );