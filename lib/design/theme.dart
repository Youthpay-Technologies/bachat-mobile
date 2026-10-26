import 'package:flutter/material.dart';

import 'brand.dart';

abstract final class BachatRadii {
  static const compact = 10.0;
  static const control = 16.0;
  static const surface = 28.0;
  static const sheet = 32.0;
  static const pill = 999.0;
}

abstract final class BachatTheme {
  static ThemeData build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF5F7FA) : BachatBrand.ink;
    final canvas = dark ? BachatBrand.canvasDark : BachatBrand.canvas;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: dark ? const Color(0xFF8CA9FF) : BachatBrand.cobalt,
      onPrimary: dark ? const Color(0xFF071438) : Colors.white,
      primaryContainer: dark
          ? const Color(0xFF172758)
          : const Color(0xFFE7EDFF),
      onPrimaryContainer: dark ? const Color(0xFFCBD7FF) : BachatBrand.cobalt,
      secondary: BachatBrand.mint,
      onSecondary: dark ? Colors.black : const Color(0xFF062010),
      secondaryContainer: dark
          ? const Color(0xFF133621)
          : BachatBrand.mintLight,
      onSecondaryContainer: dark
          ? const Color(0xFF7DF6B4)
          : const Color(0xFF09582D),
      tertiary: BachatBrand.coral,
      onTertiary: Colors.white,
      tertiaryContainer: dark
          ? const Color(0xFF381515)
          : BachatBrand.coralLight,
      onTertiaryContainer: dark
          ? const Color(0xFFFFB4B4)
          : const Color(0xFF8C1B1B),
      error: dark ? const Color(0xFFFFB4AB) : BachatBrand.coral,
      onError: dark ? const Color(0xFF690005) : Colors.white,
      errorContainer: dark ? const Color(0xFF381515) : BachatBrand.coralLight,
      onErrorContainer: dark
          ? const Color(0xFFFFB4B4)
          : const Color(0xFF8C1B1B),
      surface: dark ? BachatBrand.darkCard : Colors.white,
      surfaceContainerLow: dark
          ? const Color(0xFF111216)
          : const Color(0xFFF7F8FA),
      surfaceContainer: dark
          ? const Color(0xFF202126)
          : const Color(0xFFEDF0F3),
      surfaceContainerHigh: dark
          ? const Color(0xFF2C2D33)
          : const Color(0xFFE2E6EC),
      onSurface: text,
      onSurfaceVariant: dark
          ? const Color(0xFF9AA2B1)
          : const Color(0xFF6B7280),
      outline: dark ? const Color(0xFF2E333E) : const Color(0xFFE2E5EB),
      outlineVariant: dark ? const Color(0xFF20232B) : const Color(0xFFEEF1F4),
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
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.surfaceContainer,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        shape: CircleBorder(side: BorderSide(color: scheme.outline)),
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
              fontFamily: BachatBrand.figuresFont,
              fontFamilyFallback: const [BachatBrand.headingFont],
              fontSize: 48,
              fontWeight: FontWeight.w400,
              height: 1.1,
              letterSpacing: -1.2,
              color: text,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            headlineLarge: TextStyle(
              fontFamily: BachatBrand.figuresFont,
              fontFamilyFallback: const [BachatBrand.headingFont],
              fontSize: 32,
              fontWeight: FontWeight.w500,
              height: 1.2,
              letterSpacing: -0.7,
              color: text,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            headlineMedium: TextStyle(
              fontFamily: BachatBrand.figuresFont,
              fontFamilyFallback: const [
                BachatBrand.headingFont,
                BachatBrand.interfaceFont,
              ],
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: text,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            headlineSmall: TextStyle(
              fontFamily: BachatBrand.figuresFont,
              fontFamilyFallback: const [
                BachatBrand.headingFont,
                BachatBrand.interfaceFont,
              ],
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: text,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            titleLarge: TextStyle(
              fontFamily: BachatBrand.headingFont,
              fontFamilyFallback: const [BachatBrand.interfaceFont],
              fontSize: 18,
              fontWeight: FontWeight.w500,
              height: 1.3,
              color: text,
            ),
            titleMedium: TextStyle(
              fontFamily: BachatBrand.interfaceFont,
              fontFamilyFallback: const [BachatBrand.headingFont],
              fontSize: 18,
              fontWeight: FontWeight.w700,
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
            borderRadius: BorderRadius.circular(BachatRadii.pill),
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
          fontFamily: BachatBrand.interfaceFont,
          color: scheme.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontFamily: BachatBrand.interfaceFont,
          color: scheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        height: 68,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BachatRadii.pill),
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
        labelStyle: TextStyle(
          fontFamily: BachatBrand.interfaceFont,
          color: scheme.onSurface,
          fontSize: 13,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BachatRadii.pill),
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
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BachatRadii.surface),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .6)),
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
