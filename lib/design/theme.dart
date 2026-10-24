import 'package:flutter/material.dart';

import 'brand.dart';

abstract final class BachatRadii {
  static const compact = 8.0;
  static const control = 12.0;
  static const surface = 20.0;
  static const sheet = 24.0;
}

abstract final class BachatTheme {
  static ThemeData build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final accent = dark ? const Color(0xFFB5C8FF) : BachatBrand.cobalt;
    final text = dark ? const Color(0xFFF0F2F6) : BachatBrand.ink;
    final canvas = dark ? const Color(0xFF101319) : BachatBrand.canvas;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: brightness,
        ).copyWith(
          primary: accent,
          onPrimary: dark ? const Color(0xFF10275E) : Colors.white,
          surface: Color(dark ? 0xFF1A1E26 : 0xFFFFFFFF),
          surfaceContainerLow: Color(dark ? 0xFF161A21 : 0xFFF0F2F6),
          surfaceContainer: Color(dark ? 0xFF222731 : 0xFFE9EDF3),
          surfaceContainerHigh: Color(dark ? 0xFF2A303C : 0xFFE2E7EF),
          onSurface: text,
          onSurfaceVariant: Color(dark ? 0xFFAFB7C6 : 0xFF596478),
          outline: Color(dark ? 0xFF7F8A9E : 0xFF788398),
          outlineVariant: Color(dark ? 0xFF333B49 : 0xFFDDE2EB),
          primaryContainer: Color(dark ? 0xFF223458 : 0xFFEAF0FD),
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
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        minVerticalPadding: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BachatRadii.control),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
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
              fontFamilyFallback: const [BachatBrand.interfaceFont],
              fontSize: 44,
              fontWeight: FontWeight.w700,
              height: 1.1,
              letterSpacing: -1.2,
              color: text,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            headlineLarge: TextStyle(
              fontFamily: BachatBrand.headingFont,
              fontFamilyFallback: const [BachatBrand.interfaceFont],
              fontSize: 32,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -0.7,
              color: text,
            ),
            headlineMedium: TextStyle(
              fontFamily: BachatBrand.headingFont,
              fontFamilyFallback: const [BachatBrand.interfaceFont],
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: text,
            ),
            titleLarge: TextStyle(
              fontFamily: BachatBrand.headingFont,
              fontFamilyFallback: const [BachatBrand.interfaceFont],
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: text,
            ),
            titleMedium: TextStyle(
              fontFamily: BachatBrand.headingFont,
              fontFamilyFallback: const [BachatBrand.interfaceFont],
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: text,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            titleSmall: TextStyle(
              fontFamily: BachatBrand.interfaceFont,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: text,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            bodyLarge: TextStyle(
              fontFamily: BachatBrand.interfaceFont,
              fontSize: 16,
              height: 1.5,
              color: text,
            ),
            bodyMedium: TextStyle(
              fontFamily: BachatBrand.interfaceFont,
              fontSize: 14,
              height: 1.5,
              color: text,
            ),
            bodySmall: TextStyle(
              fontFamily: BachatBrand.interfaceFont,
              fontSize: 13,
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
            labelLarge: TextStyle(
              fontFamily: BachatBrand.interfaceFont,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: text,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
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
        errorMaxLines: 6,
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
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
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
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
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: BachatBrand.interfaceFont,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
        ),
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
          backgroundColor: scheme.surface,
          side: BorderSide(color: scheme.outline),
          minimumSize: const Size(48, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
        backgroundColor: scheme.surface,
        selectedColor: scheme.primaryContainer,
        showCheckmark: true,
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: TextStyle(color: scheme.onSurface, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
