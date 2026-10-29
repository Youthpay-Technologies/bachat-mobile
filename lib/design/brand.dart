import 'package:flutter/material.dart';

/// Brand primitives. Widgets consume ColorScheme roles for adaptive UI colors.
abstract final class BachatBrand {
  // Approved YouthPay palette: five colours only.
  static const red = Color(0xFFD62828);
  static const gold = Color(0xFFF7C948);
  static const navy = Color(0xFF1B2A4A);
  static const cream = Color(0xFFFAF7EF);
  static const green = Color(0xFF2D7D46);

  // Backward-compatible semantic aliases without adding new colour values.
  static const mint = green;
  static const mintLight = green;
  static const obsidian = navy;
  static const darkCard = navy;
  static const coral = red;
  static const coralLight = red;
  static const ink = navy;
  static const canvas = cream;
  static const canvasGlowLight = cream;
  static const cobaltOnLight = navy;
  static const greenOnLight = green;
  static const orangeOnLight = red;
  static const errorOnLight = red;
  static const canvasDark = navy;
  static const trackGrey = navy;

  static const cobalt = navy;
  static const cobaltGlow = navy;
  static const categoryOrange = red;
  static const categoryGreen = green;
  static const sunshine = gold;
  static const tangerine = red;

  static const headingFont = 'Poppins';
  static const interfaceFont = 'Poppins';
  static const figuresFont = 'Poppins';
  static const figuresMonoFont = 'Poppins';
  static const editorialFont = 'Lora';

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
        ..color = BachatBrand.navy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      const Offset(73, 25),
      8,
      Paint()..color = BachatBrand.red,
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
