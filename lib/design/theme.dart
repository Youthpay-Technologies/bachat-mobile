import 'dart:ui';
import 'package:flutter/material.dart';

abstract final class BachatTheme {
  static ThemeData build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final accent = Color(dark ? 0xFFA4D1B2 : 0xFF285B46);
    final text = Color(dark ? 0xFFF1F4EC : 0xFF172D35);
    final canvas = Color(dark ? 0xFF111C1A : 0xFFF8F7F2);
    final scheme = ColorScheme.fromSeed(seedColor: accent, brightness: brightness).copyWith(
      primary: accent, onPrimary: dark ? const Color(0xFF173425) : Colors.white,
      surface: Color(dark ? 0xFF192622 : 0xFFFFFFFF), onSurface: text,
      onSurfaceVariant: Color(dark ? 0xFFB2C0B7 : 0xFF62716C),
      outline: Color(dark ? 0xFF72857B : 0xFF7A8A80),
      outlineVariant: Color(dark ? 0xFF41574A : 0xFFDDE3DB),
      primaryContainer: Color(dark ? 0xFF263C30 : 0xFFE7EEE6),
      onPrimaryContainer: text, error: Color(dark ? 0xFFFFB4AB : 0xFFA13636),
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: brightness, fontFamily: 'DM Sans');
    return base.copyWith(
      scaffoldBackgroundColor: canvas,
      textTheme: base.textTheme.copyWith(
        displaySmall: TextStyle(fontFamily: 'DM Sans', fontSize: 40, fontWeight: FontWeight.w600, height: 1.1, letterSpacing: -1.2, color: text, fontFeatures: const [FontFeature.tabularFigures()]),
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, height: 1.2, letterSpacing: -0.7, color: text),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: 1.2, color: text),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3, color: text),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: text),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: text),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: text),
      ),
      appBarTheme: AppBarTheme(backgroundColor: canvas, foregroundColor: text, elevation: 0, scrolledUnderElevation: 0, centerTitle: false),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(48, 54), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), textStyle: const TextStyle(fontFamily: 'DM Sans', fontSize: 16, fontWeight: FontWeight.w600))),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(minimumSize: const Size(48, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: scheme.surface, contentPadding: const EdgeInsets.all(18), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: scheme.outline)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: scheme.outline)), labelStyle: TextStyle(color: scheme.onSurfaceVariant)),
      navigationBarTheme: NavigationBarThemeData(backgroundColor: scheme.surface, elevation: 0, height: 78, indicatorColor: scheme.primaryContainer, labelBehavior: NavigationDestinationLabelBehavior.alwaysShow),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: text, contentTextStyle: TextStyle(color: scheme.surface)),
    );
  }
}
