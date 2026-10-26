import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'brand.dart';

/// Editorial type is reserved for short, non-financial brand messages.
class BrandHeadline extends StatelessWidget {
  const BrandHeadline({super.key, required this.lead, required this.accent});
  final String lead, accent;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(text: "$lead\n"),
        TextSpan(
          text: accent,
          style: BachatBrand.figure(context, size: 52, weight: FontWeight.w400),
        ),
      ],
    ),
    style: Theme.of(context).textTheme.displaySmall,
  );
}

/// Monthly spending with an honest, cumulative daily series.
class SpendingHero extends StatelessWidget {
  const SpendingHero({
    super.key,
    required this.month,
    required this.amount,
    required this.contextLabel,
    required this.dailyTotals,
  });
  final String month, amount, contextLabel;
  final List<int> dailyTotals;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        const SizedBox(height: 58),
        Text(
          'Total spent in $month',
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 17),
        ),
        const SizedBox(height: 8),
        Text(
          amount,
          textAlign: TextAlign.center,
          style: BachatBrand.figure(context, size: 48, weight: FontWeight.w400),
        ),
        const SizedBox(height: 8),
        Text(
          contextLabel,
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 15),
        ),
        const SizedBox(height: 24),
        Semantics(
          label: 'Cumulative daily spending for $month. Total $amount.',
          image: true,
          child: SizedBox(
            height: 96,
            width: double.infinity,
            child: CustomPaint(
              painter: _SpendingPainter(dailyTotals, colors.onSurface),
            ),
          ),
        ),
      ],
    );
  }
}

class _SpendingPainter extends CustomPainter {
  const _SpendingPainter(this.values, this.color);
  final List<int> values;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maximum = values.reduce(math.max);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / math.max(1, values.length - 1);
      final y =
          size.height -
          8 -
          (maximum == 0 ? 0 : values[i] / maximum * (size.height - 20));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: .18), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _SpendingPainter old) =>
      old.values != values || old.color != color;
}

class BudgetSummaryCard extends StatelessWidget {
  const BudgetSummaryCard({
    super.key,
    required this.progress,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.overBudget = false,
  });
  final double progress;
  final String title, subtitle;
  final VoidCallback onTap;
  final bool overBudget;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 5,
                        strokeCap: StrokeCap.round,
                        backgroundColor: colors.surfaceContainerHigh,
                        color: overBudget
                            ? colors.error
                            : BachatBrand.categoryGreen,
                        semanticsLabel: 'Monthly category budgets used',
                        semanticsValue: '${(progress * 100).round()} percent',
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: BachatBrand.figure(
                        context,
                        size: 13,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.bodyLarge),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
    final scale = (size.width / 320).clamp(0.0, size.height / 144);
    canvas.save();
    canvas.translate(
      (size.width - 320 * scale) / 2,
      (size.height - 144 * scale) / 2,
    );
    canvas.scale(scale);
    final paint = Paint()..color = BachatBrand.mint;
    canvas.drawCircle(const Offset(160, 70), 67, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(70, 74, 48, 64),
        const Radius.circular(12),
      ),
      paint..color = BachatBrand.obsidian,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(134, 48, 48, 90),
        const Radius.circular(12),
      ),
      paint..color = BachatBrand.obsidian,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(198, 16, 48, 122),
        const Radius.circular(12),
      ),
      paint..color = BachatBrand.obsidian,
    );
    canvas.drawCircle(
      const Offset(260, 28),
      16,
      paint..color = BachatBrand.coral,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HabitPainter oldDelegate) => false;
}
