import 'package:flutter/material.dart';

import 'brand.dart';
import 'theme.dart';

/// Editorial type is reserved for short, non-financial brand messages.
class BrandHeadline extends StatelessWidget {
  const BrandHeadline({super.key, required this.lead, required this.accent});
  final String lead, accent;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(text: '$lead\n'),
        TextSpan(text: accent, style: BachatBrand.editorial(context, size: 52)),
      ],
    ),
    style: Theme.of(context).textTheme.displaySmall,
  );
}

class SpendingHero extends StatelessWidget {
  const SpendingHero({super.key, required this.month, required this.amount});
  final String month, amount;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: BachatBrand.cobalt,
      borderRadius: BorderRadius.circular(BachatRadii.surface),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$month spending',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: Colors.white),
              ),
            ),
            const ExcludeSemantics(
              child: Icon(
                Icons.north_east_rounded,
                color: BachatBrand.sunshine,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          amount,
          style: Theme.of(context).textTheme.displaySmall
              ?.copyWith(color: Colors.white, fontSize: 44),
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsetsDirectional.only(top: 5, end: 8),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: BachatBrand.sunshine,
                shape: BoxShape.circle,
              ),
            ),
            const Expanded(
              child: Text(
                'Your everyday, in perspective.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// A static, code-native illustration: no animation, network or sample money.
class HabitIllustration extends StatelessWidget {
  const HabitIllustration({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: compact ? 100 : 144,
      width: double.infinity,
      child: CustomPaint(painter: _HabitPainter()),
    ),
  );
}

class _HabitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Scale from a single artboard so the composition also fits narrow phones.
    final scale = (size.width / 320).clamp(0.0, 1.0);
    canvas.save();
    canvas.translate((size.width - 320 * scale) / 2, 0);
    canvas.scale(scale, size.height / 144);
    final paint = Paint()..color = BachatBrand.sunshine;
    canvas.drawCircle(const Offset(160, 70), 67, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(70, 74, 48, 64),
        const Radius.circular(12),
      ),
      paint..color = BachatBrand.cobalt,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(134, 48, 48, 90),
        const Radius.circular(12),
      ),
      paint..color = BachatBrand.cobalt,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(198, 16, 48, 122),
        const Radius.circular(12),
      ),
      paint..color = BachatBrand.cobalt,
    );
    canvas.drawCircle(
      const Offset(260, 28),
      16,
      paint..color = BachatBrand.tangerine,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HabitPainter oldDelegate) => false;
}
