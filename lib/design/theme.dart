import 'package:flutter/material.dart';

abstract final class BachatRadii {
  static const compact = 8.0;
  static const control = 12.0;
  static const surface = 16.0;
  static const sheet = 20.0;
}

abstract final class BachatTheme {
  static ThemeData build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final accent = Color(dark ? 0xFF67DE70 : 0xFF34C642);
    final text = Color(dark ? 0xFFF3F5F7 : 0xFF14171C);
    final canvas = Color(dark ? 0xFF14171C : 0xFFEEF0F4);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: brightness,
        ).copyWith(
          primary: accent,
          onPrimary: const Color(0xFF102314),
          surface: Color(dark ? 0xFF20252D : 0xFFF7F8FA),
          onSurface: text,
          onSurfaceVariant: Color(dark ? 0xFFBAC2CE : 0xFF596171),
          outline: Color(dark ? 0xFF8290A1 : 0xFF7A8494),
          outlineVariant: Color(dark ? 0xFF3B4452 : 0xFFD8DEE7),
          primaryContainer: Color(dark ? 0xFF243D2B : 0xFFE0F3E3),
          onPrimaryContainer: text,
          error: Color(dark ? 0xFFFFB4AB : 0xFFA13636),
        );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      fontFamily: 'DM Sans',
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
      textTheme: base.textTheme.copyWith(
        displaySmall: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 44,
          fontWeight: FontWeight.w700,
          height: 1.1,
          letterSpacing: -1.4,
          color: text,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        headlineLarge: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: -0.7,
          color: text,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: text,
        ),
        titleLarge: TextStyle(
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
            fontFamily: 'DM Sans',
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
          borderSide: BorderSide(
            color: dark ? scheme.primary : const Color(0xFF216D2C),
            width: 2,
          ),
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        height: 74,
        indicatorColor: scheme.primary,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BachatRadii.compact),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimary
                : scheme.onSurfaceVariant,
          ),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: dark ? scheme.primary : const Color(0xFF22852E),
        linearTrackColor: scheme.outlineVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: dark ? scheme.primary : const Color(0xFF216D2C),
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
