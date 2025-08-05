import 'package:flutter/material.dart';


class AppTheme {

  const AppTheme._();

  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF2862F5),
    brightness: Brightness.light,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF2862F5),
    brightness: Brightness.dark,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  static ThemeData of(BuildContext context) {
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark
        ? darkTheme
        : lightTheme;
  }

}