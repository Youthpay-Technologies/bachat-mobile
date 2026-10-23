import 'package:bachat_mobile/application/controller.dart';
import 'package:bachat_mobile/data/repository.dart';
import 'package:bachat_mobile/design/theme.dart';
import 'package:bachat_mobile/presentation/auth_screens.dart';
import 'package:bachat_mobile/presentation/onboarding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  Future<AppController> mount(
    WidgetTester tester, {
    double scale = 1,
    Brightness brightness = Brightness.light,
    bool reducedMotion = false,
  }) async {
    final db = await databaseFactoryMemory.openDatabase('onboarding');
    final controller = AppController(BachatRepository(db, null))..ready = true;
    addTearDown(controller.dispose);
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [controllerProvider.overrideWith((ref) => controller)],
        child: MaterialApp(
          theme: BachatTheme.build(brightness),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: reducedMotion,
            ),
            child: child!,
          ),
          home: const WelcomeScreen(),
        ),
      ),
    );
    return controller;
  }

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets('tour interactions survive Back and never create money records', (
    tester,
  ) async {
    final controller = await mount(tester);
    await tap(tester, 'Rides');
    expect(find.text('Bus fares and rides, all in one place.'), findsOneWidget);
    await tap(tester, 'Continue');
    await tester.ensureVisible(find.byType(Slider));
    await tester.drag(find.byType(Slider), const Offset(100, 0));
    await tester.pumpAndSettle();
    final limit = tester.widget<Slider>(find.byType(Slider)).value;
    expect(limit, greaterThan(2000));
    await tap(tester, 'Continue');
    await tap(tester, 'Headphones');
    await tester.ensureVisible(find.byTooltip('Previous introduction step'));
    await tester.tap(find.byTooltip('Previous introduction step'));
    await tester.pumpAndSettle();
    expect(tester.widget<Slider>(find.byType(Slider)).value, limit);
    await tap(tester, 'Continue');
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Headphones'))
          .selected,
      isTrue,
    );
    expect(controller.allEntries, isEmpty);
    expect(controller.allBudgets, isEmpty);
    expect(controller.allGoals, isEmpty);
  });

  testWidgets('direct sign in and native Back preserve the tour step', (
    tester,
  ) async {
    await mount(tester);
    await tap(tester, 'Continue');
    await tap(tester, 'Already have an account? Sign in');
    expect(find.byType(AuthScreen), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 3'), findsOneWidget);
    await tap(tester, 'Skip introduction');
    await tap(tester, 'Continue as a teen');
    expect(find.byType(AuthScreen), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'tour reflows at 320px and 200% text in $brightness with reduced motion',
      (tester) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await mount(
          tester,
          scale: 2,
          brightness: brightness,
          reducedMotion: true,
        );
        expect(
          tester
              .widget<AnimatedSwitcher>(
                find.byKey(const ValueKey('onboarding-transition')),
              )
              .duration,
          Duration.zero,
        );
        await tap(tester, 'Continue');
        await tap(tester, 'Continue');
        await tap(tester, 'Something else');
        await tap(tester, 'Continue as a teen');
        expect(find.byType(AuthScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
