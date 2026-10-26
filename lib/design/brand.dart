import 'package:flutter/material.dart';

/// Brand primitives. Widgets consume ColorScheme roles for adaptive UI colors.
abstract final class BachatBrand {
  static const cobalt = Color(0xFF0C38A9);
  static const sunshine = Color(0xFFFFDE59);
  static const tangerine = Color(0xFFFF751E);
  static const ink = Color(0xFF142344);
  static const canvas = Color(0xFFF6F7FB);
  static const headingFont = 'Instrument Sans';
  static const interfaceFont = 'Instrument Sans';
  static const figuresFont = 'FK Grotesk';
  static const figuresMonoFont = 'FK Grotesk Mono';
  static const editorialFont = 'Instrument Serif';

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
        ..color = BachatBrand.sunshine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      const Offset(73, 25),
      8,
      Paint()..color = BachatBrand.tangerine,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BachatSymbolPainter oldDelegate) => false;
}

class BachatSymbol extends StatelessWidget {
  const BachatSymbol({super.key, this.size = 44});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: BachatBrand.cobalt,
        borderRadius: BorderRadius.circular(size * .29),
      ),
      child: const CustomPaint(painter: BachatSymbolPainter()),
    ),
  );
}
