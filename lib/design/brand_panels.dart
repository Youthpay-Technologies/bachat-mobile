import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../domain/models.dart';
import 'package:flutter/material.dart';

import 'brand.dart';

/// Brand statements pair the workhorse font with the existing display face.
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

/// Monthly spending plotted against an adaptive, explicitly labeled time axis.
class SpendingHero extends StatelessWidget {
  const SpendingHero({
    super.key,
    required this.month,
    required this.amount,
    required this.contextLabel,
    required this.timeline,
  });
  final String month, amount, contextLabel;
  final SpendingTimeline timeline;

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
          label:
              'Cumulative spending from ${DateFormat.yMMMd().add_Hm().format(timeline.start)} to ${DateFormat.yMMMd().add_Hm().format(timeline.end)}. Total $amount.',
          image: true,
          child: SizedBox(
            height: 96,
            width: double.infinity,
            child: CustomPaint(
              painter: _SpendingPainter(timeline, colors.onSurface),
            ),
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final count = MediaQuery.textScalerOf(context).scale(13) > 20
                ? 2
                : constraints.maxWidth >= 480
                ? 5
                : 3;
            final times = timeline.tickTimes(count);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: times.indexed.map((item) {
                final (index, time) = item;
                final label =
                    timeline.isHourly && index > 0 && index < count - 1
                    ? DateFormat.Hm().format(time)
                    : DateFormat('MMM d\nHH:mm').format(time);
                return Expanded(
                  child: Text(
                    label,
                    textAlign: index == 0
                        ? TextAlign.start
                        : index == count - 1
                        ? TextAlign.end
                        : TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          timeline.hasExpenses
              ? timeline.isHourly
                    ? 'Last 24 hours'
                    : '${(timeline.end.difference(timeline.start).inHours / 24).ceil()} days of activity'
              : 'Your expenses will appear across this 24-hour window',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SpendingPainter extends CustomPainter {
  const _SpendingPainter(this.timeline, this.color);
  final SpendingTimeline timeline;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final points = timeline.points;
    final maximum = points.map((p) => p.totalMinor).reduce(math.max);
    final duration = timeline.end.difference(timeline.start).inMicroseconds;
    double y(int value) =>
        size.height -
        8 -
        (maximum == 0 ? 0 : value / maximum * (size.height - 20));
    final path = Path()..moveTo(0, y(0));
    var previous = 0;
    for (final point in points) {
      final x =
          size.width *
          point.at.difference(timeline.start).inMicroseconds /
          duration;
      path.lineTo(x, y(previous));
      path.lineTo(x, y(point.totalMinor));
      previous = point.totalMinor;
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
      old.timeline != timeline || old.color != color;
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
                        semanticsValue: '${(progress * 100).round()}%',
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
