import 'dart:math' as math;
import 'package:bachat_mobile/design/brand.dart';
import 'package:bachat_mobile/design/brand_panels.dart';
import 'package:bachat_mobile/design/theme.dart';
import 'package:bachat_mobile/domain/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (math.max(x, y) + .05) / (math.min(x, y) + .05);
}

void main() {
  test(
    'light text and controls remain legible on cards and the opaque backdrop',
    () {
      final c = BachatTheme.build(Brightness.light).colorScheme;
      for (final surface in [
        c.surface,
        BachatBrand.canvas,
        BachatBrand.canvasGlowLight,
      ]) {
        expect(contrast(c.onSurface, surface), greaterThanOrEqualTo(4.5));
        expect(
          contrast(c.onSurfaceVariant, surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(contrast(c.primary, surface), greaterThanOrEqualTo(4.5));
      }
      expect(contrast(c.primary, c.onPrimary), greaterThanOrEqualTo(4.5));
      expect(contrast(c.secondary, c.onSecondary), greaterThanOrEqualTo(4.5));
      expect(contrast(c.error, c.onError), greaterThanOrEqualTo(4.5));
      expect(contrast(c.outline, c.surface), greaterThanOrEqualTo(3));
      for (final accent in [
        BachatBrand.orangeOnLight,
        BachatBrand.greenOnLight,
        BachatBrand.cobaltOnLight,
      ]) {
        expect(
          contrast(
            accent,
            Color.alphaBlend(accent.withValues(alpha: .16), c.surface),
          ),
          greaterThanOrEqualTo(3),
        );
      }
    },
  );

  test('dark palette retains the approved brief values', () {
    final theme = BachatTheme.build(Brightness.dark);
    expect(theme.scaffoldBackgroundColor, const Color(0xFF1B2A4A));
    expect(theme.colorScheme.surface, const Color(0xFF1B2A4A));
    expect(theme.colorScheme.primary, const Color(0xFFD62828));
    expect(theme.colorScheme.onPrimary, const Color(0xFFFAF7EF));
    expect(theme.colorScheme.onSurface, const Color(0xFFFAF7EF));
    expect(theme.colorScheme.onSurfaceVariant, const Color(0xFFF7C948).withValues(alpha: .9));
    expect(theme.colorScheme.secondary, const Color(0xFFF7C948));
    expect(theme.colorScheme.error, const Color(0xFFD62828));
  });

  test('light palette retains the approved brief values', () {
    final theme = BachatTheme.build(Brightness.light);
    expect(theme.scaffoldBackgroundColor, const Color(0xFFFAF7EF));
    expect(theme.colorScheme.surface, const Color(0xFFFAF7EF));
    expect(theme.colorScheme.primary, const Color(0xFFD62828));
    expect(theme.colorScheme.onPrimary, const Color(0xFFFAF7EF));
    expect(theme.colorScheme.onSurface, const Color(0xFF1B2A4A));
    expect(theme.colorScheme.secondary, const Color(0xFFF7C948));
    expect(theme.colorScheme.tertiary, const Color(0xFF2D7D46));
  });

  test(
    'frosted navigation text stays legible over the lightest and darkest content',
    () {
      for (final brightness in Brightness.values) {
        final c = BachatTheme.build(brightness).colorScheme;
        for (final behind in [Colors.black, Colors.white]) {
          final glass = Color.alphaBlend(
            c.surface.withValues(alpha: .88),
            behind,
          );
          expect(
            contrast(c.onSurfaceVariant, glass),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrast(c.onPrimaryContainer, glass),
            greaterThanOrEqualTo(4.5),
          );
        }
      }
    },
  );

  testWidgets('hour ticks scale to 24 hours and stay readable at 200 percent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime(2026, 10, 26, 18);
    final timeline = SpendingTimeline([
      MoneyEntry(
        id: 'first',
        ownerId: 'teen',
        merchant: 'Lunch',
        amountMinor: 12500,
        direction: EntryDirection.expense,
        category: 'Food & dining',
        occurredAt: now.subtract(const Duration(hours: 2)),
      ),
    ], now);
    await tester.pumpWidget(
      MaterialApp(
        theme: BachatTheme.build(Brightness.light),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: SpendingHero(
                month: 'October',
                amount: 'Rs 125',
                contextLabel: 'Your recorded spending this month',
                timeline: timeline,
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Last 24 hours'), findsOneWidget);
    expect(find.text('Oct 25\n18:00'), findsOneWidget);
    expect(find.text('Oct 26\n18:00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
