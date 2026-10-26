import 'dart:math' as math;
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
        TextSpan(text: "$lead\n"),
        TextSpan(text: accent, style: BachatBrand.editorial(context, size: 52)),
      ],
    ),
    style: Theme.of(context).textTheme.displaySmall,
  );
}

/// Custom painter for diagonal hatched stripes
class HatchedPatternPainter extends CustomPainter {
  const HatchedPatternPainter({
    required this.color,
    this.stripeWidth = 3.0,
    this.gap = 5.0,
  });
  final Color color;
  final double stripeWidth;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = stripeWidth
      ..style = PaintingStyle.stroke;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final total = size.width + size.height;
    final step = stripeWidth + gap;
    for (double x = -size.height; x < total; x += step) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HatchedPatternPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.stripeWidth != stripeWidth ||
      oldDelegate.gap != gap;
}

/// Semi-circle arc radial gauge from the design reference
class RadialArcGauge extends StatelessWidget {
  const RadialArcGauge({
    super.key,
    required this.progress, // 0.0 to 1.0
    required this.amountLabel,
    this.title = 'Total Expensed',
    this.size = 200,
  });

  final double progress;
  final String amountLabel;
  final String title;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = dark ? const Color(0xFF262A33) : const Color(0xFFE8ECEF);
    final activeColor = BachatBrand.mint;

    return SizedBox(
      width: size,
      height: size * 0.72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size * 0.72),
            painter: _RadialArcGaugePainter(
              progress: progress.clamp(0.05, 0.95),
              activeColor: activeColor,
              trackColor: trackColor,
              strokeWidth: 24,
            ),
          ),
          Positioned(
            bottom: 4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: BachatBrand.interfaceFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amountLabel,
                  style: TextStyle(
                    fontFamily: BachatBrand.figuresFont,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RadialArcGaugePainter extends CustomPainter {
  const _RadialArcGaugePainter({
    required this.progress,
    required this.activeColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color activeColor;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.82);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track arc (pi to 2*pi, 180 degrees)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, math.pi, math.pi, false, trackPaint);

    // Active progress arc in Mint Green
    final activeSweep = math.pi * progress;
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, math.pi, activeSweep, false, activePaint);
  }

  @override
  bool shouldRepaint(covariant _RadialArcGaugePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.activeColor != activeColor ||
      oldDelegate.trackColor != trackColor;
}

/// Buddy Planner / Radial Goal Card from the design reference
class BuddyPlannerCard extends StatelessWidget {
  const BuddyPlannerCard({
    super.key,
    required this.amount,
    required this.categoryName,
    this.progress = 0.65,
    this.onNextCategory,
    this.onPrevCategory,
  });

  final String amount;
  final String categoryName;
  final double progress;
  final VoidCallback? onNextCategory;
  final VoidCallback? onPrevCategory;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BachatRadii.surface),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: dark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Buddy avatars
              SizedBox(
                width: 44,
                height: 28,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: colors.surfaceContainerLow,
                      child: Icon(Icons.person, size: 16, color: colors.onSurfaceVariant),
                    ),
                    Positioned(
                      left: 14,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: BachatBrand.mint,
                        child: const Icon(Icons.bolt_rounded, size: 16, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Buddy Planner',
                  style: TextStyle(
                    fontFamily: BachatBrand.headingFont,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
              ),
              Icon(Icons.more_horiz_rounded, color: colors.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 12),
          RadialArcGauge(
            progress: progress,
            amountLabel: amount,
            size: 220,
          ),
          const SizedBox(height: 16),
          // Category selector capsule in dark black
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: dark ? colors.surfaceContainer : BachatBrand.obsidian,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: onPrevCategory,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 20,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    categoryName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: BachatBrand.headingFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onNextCategory,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: BachatBrand.mint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.black,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Revamped Spending / Balance Hero matching the attached screenshot style.
class SpendingHero extends StatelessWidget {
  const SpendingHero({
    super.key,
    required this.month,
    required this.amount,
    required this.contextLabel,
  });

  final String month, amount;
  final String contextLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    if (dark) {
      // Middle screen dark theme emerald mint hero card
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: BachatBrand.mint,
          borderRadius: BorderRadius.circular(BachatRadii.surface),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    month,
                    style: const TextStyle(
                      fontFamily: BachatBrand.headingFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.receipt_long_outlined, color: Colors.black87),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final largeText = MediaQuery.textScalerOf(context).scale(14) > 20 ||
                    constraints.maxWidth < 280;
                final amountWidget = Text(
                  amount,
                  style: TextStyle(
                    fontFamily: BachatBrand.figuresFont,
                    fontSize: largeText ? 26 : 40,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.0,
                    color: Colors.black,
                  ),
                );
                final labelWidget = const Text(
                  'Spent this month',
                  style: TextStyle(
                    fontFamily: BachatBrand.interfaceFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                );
                if (largeText) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [amountWidget, const SizedBox(height: 4), labelWidget],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [Expanded(child: amountWidget), labelWidget],
                );
              },
            ),
            const SizedBox(height: 16),
            // Progress capsule inside hero
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(999),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Row(
                  children: [
                    Container(
                      width: 120,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              contextLabel,
              style: const TextStyle(
                fontFamily: BachatBrand.interfaceFont,
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Light mode hero matching Left Screen of reference
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BachatRadii.surface),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final largeText = MediaQuery.textScalerOf(context).scale(14) > 20 ||
                  constraints.maxWidth < 280;
              final amountWidget = Text(
                amount,
                style: TextStyle(
                  fontFamily: BachatBrand.figuresFont,
                  fontSize: largeText ? 26 : 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                  color: colors.onSurface,
                ),
              );
              final labelWidget = Text(
                'Spent this month',
                style: TextStyle(
                  fontFamily: BachatBrand.interfaceFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                ),
              );
              if (largeText) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [amountWidget, const SizedBox(height: 4), labelWidget],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [Expanded(child: amountWidget), labelWidget],
              );
            },
          ),
          const SizedBox(height: 14),
          // Progress bar track with black fill
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(999),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 90,
                  color: BachatBrand.obsidian,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                contextLabel,
                style: TextStyle(
                  fontFamily: BachatBrand.interfaceFont,
                  fontSize: 13,
                  color: colors.onSurfaceVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '+15% vs last month',
                  style: TextStyle(
                    fontFamily: BachatBrand.figuresFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ],
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
