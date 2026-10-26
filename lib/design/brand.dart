import 'package:flutter/material.dart';

/// Brand primitives. Widgets consume ColorScheme roles for adaptive UI colors.
abstract final class BachatBrand {
  // Vibrant high-contrast fintech palette from design reference
  static const mint = Color(0xFF22E385);
  static const mintLight = Color(0xFFE2F9EE);
  static const obsidian = Color(0xFF111215);
  static const darkCard = Color(0xFF18191D);
  static const coral = Color(0xFFFF5252);
  static const coralLight = Color(0xFFFFEBEB);
  static const ink = Color(0xFF0E1217);
  static const canvas = Color(0xFFF5F7FB);
  static const canvasGlowLight = Color(0xFFEAF0FF);
  static const cobaltOnLight = Color(0xFF244ECB);
  static const greenOnLight = Color(0xFF137A43);
  static const orangeOnLight = Color(0xFFA45B00);
  static const errorOnLight = Color(0xFFBD2C2C);
  static const canvasDark = Color(0xFF08090D);
  static const trackGrey = Color(0xFFE8ECEF);

  // Backward compatibility aliases
  static const cobalt = Color(0xFF3567FF);
  static const cobaltGlow = Color(0xFF183BA8);
  static const categoryOrange = Color(0xFFFFA010);
  static const categoryGreen = Color(0xFF32D447);
  static const sunshine = mint;
  static const tangerine = coral;

  static const headingFont = 'Instrument Sans';
  static const interfaceFont = 'Instrument Sans';
  static const figuresFont = 'FK Grotesk';
  static const figuresMonoFont = 'FK Grotesk Mono';
  static const editorialFont = 'Instrument Serif';

  static TextStyle figure(
    BuildContext context, {
    double size = 32,
    FontWeight weight = FontWeight.w700,
    Color? color,
    double? letterSpacing = -0.5,
  }) => TextStyle(
    fontFamily: figuresFont,
    fontFamilyFallback: const [headingFont, 'sans-serif'],
    fontSize: size,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    color: color ?? Theme.of(context).colorScheme.onSurface,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle editorial(BuildContext context, {double size = 38}) =>
      TextStyle(
        fontFamily: editorialFont,
        fontFamilyFallback: const ['Georgia', 'serif'],
        fontSize: size,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w400,
        height: 1.15,
        color: Theme.of(context).colorScheme.onSurface,
      );
}

/// A rising, open-ended lowercase b: a small start with room to grow.
/// Kept in code so launcher assets and the in-app identity share one source.
class BachatSymbolPainter extends CustomPainter {
  const BachatSymbolPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final stem = Path()
      ..moveTo(31, 24)
      ..lineTo(31, 59)
      ..cubicTo(31, 84, 73, 84, 73, 59)
      ..cubicTo(73, 35, 40, 35, 31, 54);
    canvas.drawPath(
      stem,
      Paint()
        ..color = BachatBrand.mint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      const Offset(73, 25),
      8,
      Paint()..color = BachatBrand.coral,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BachatSymbolPainter oldDelegate) => false;
}

class BachatSymbol extends StatelessWidget {
  const BachatSymbol({super.key, this.size = 44, this.withBackground = true});
  final double size;
  final bool withBackground;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: withBackground ? BachatBrand.obsidian : Colors.transparent,
        borderRadius: BorderRadius.circular(size * .29),
      ),
      child: const CustomPaint(painter: BachatSymbolPainter()),
    ),
  );
}
