import 'package:flutter/material.dart';

import 'brand.dart';

abstract final class BachatRadii {
  static const compact = 10.0;
  static const control = 16.0;
  static const surface = 24.0;
  static const sheet = 32.0;
}

abstract final class BachatTheme {
  static ThemeData build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final accent = dark ? const Color(0xFFB5C8FF) : BachatBrand.cobalt;
    final text = dark ? const Color(0xFFF2F5FF) : BachatBrand.ink;
    final canvas = dark ? const Color(0xFF0D1529) : BachatBrand.canvas;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: brightness,
        ).copyWith(
          primary: accent,
          onPrimary: dark ? const Color(0xFF10275E) : Colors.white,
          surface: Color(dark ? 0xFF17233D : 0xFFFFFFFF),
          onSurface: text,
          onSurfaceVariant: Color(dark ? 0xFFB7C3DE : 0xFF566480),
          outline: Color(dark ? 0xFF8393B3 : 0xFF73819A),
          outlineVariant: Color(dark ? 0xFF2C3C5C : 0xFFDEE4F0),
          primaryContainer: Color(dark ? 0xFF243A6A : 0xFFE9EFFF),
          onPrimaryContainer: dark
              ? const Color(0xFFDCE5FF)
              : BachatBrand.cobalt,
          secondary: BachatBrand.sunshine,
          onSecondary: BachatBrand.ink,
          secondaryContainer: Color(dark ? 0xFF40391E : 0xFFFFF5CB),
          onSecondaryContainer: Color(dark ? 0xFFFFE68B : 0xFF514000),
          tertiary: BachatBrand.tangerine,
          onTertiary: BachatBrand.ink,
          tertiaryContainer: Color(dark ? 0xFF4B2C1D : 0xFFFFEBDD),
          onTertiaryContainer: Color(dark ? 0xFFFFCBA9 : 0xFF853900),
          error: Color(dark ? 0xFFFFB4AB : 0xFFA13636),
        );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      fontFamily: BachatBrand.interfaceFont,
    );
    return base.copyWith(
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: canvas,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(BachatRadii.sheet),
          ),
        ),
      ),
      scaffoldBackgroundColor: canvas,
      textTheme: base.textTheme
          .apply(bodyColor: text, displayColor: text)
          .copyWith(
            displaySmall: TextStyle(
              fontFamily: BachatBrand.headingFont,
              fontSize: 48,
              fontWeight: FontWeight.w700,
              height: 1.1,
              letterSpacing: -1.4,
              color: text,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            headlineLarge: TextStyle(
              fontFamily: BachatBrand.headingFont,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -0.7,
              color: text,
            ),
            headlineMedium: TextStyle(
              fontFamily: BachatBrand.headingFont,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: text,
            ),
            titleLarge: TextStyle(
              fontFamily: BachatBrand.headingFont,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: text,
            ),
            bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: text),
            bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: text),
            labelLarge: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BachatRadii.control),
          ),
          textStyle: const TextStyle(
            fontFamily: BachatBrand.interfaceFont,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.all(18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BachatRadii.control),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BachatRadii.control),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BachatRadii.control),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        height: 74,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BachatRadii.compact),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.outlineVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BachatRadii.control),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BachatRadii.control),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BachatRadii.control),
          ),
          minimumSize: const Size(48, 48),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BachatRadii.compact),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BachatRadii.control),
          ),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BachatRadii.sheet),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BachatRadii.sheet),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BachatRadii.control),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BachatRadii.control),
        ),
        backgroundColor: text,
        contentTextStyle: TextStyle(color: scheme.surface),
      ),
    );
  }
}
