import 'package:flutter/material.dart';

class Spooky {
  static const night = Color(0xFF120822);
  static const surface = Color(0xFF221238);
  static const surfaceHigh = Color(0xFF2F1A4D);
  static const pumpkin = Color(0xFFFF7A1A);
  static const ember = Color(0xFFFFB347);
  static const violet = Color(0xFF9B5CFF);
  static const moon = Color(0xFFFFEFC2);
  static const mist = Color(0xFFB9A8D6);

  static const titleFont = 'Creepster';
}

ThemeData buildSpookyTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Spooky.pumpkin,
    brightness: Brightness.dark,
  ).copyWith(
    primary: Spooky.pumpkin,
    secondary: Spooky.violet,
    surface: Spooky.surface,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Spooky.night,
    appBarTheme: const AppBarTheme(
      backgroundColor: Spooky.night,
      foregroundColor: Spooky.moon,
      elevation: 0,
    ),
    textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Spooky.moon,
          displayColor: Spooky.moon,
        ),
  );
}
