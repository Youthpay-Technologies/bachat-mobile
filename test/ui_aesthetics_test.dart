import 'package:bachat_mobile/application/controller.dart';
import 'package:bachat_mobile/data/repository.dart';
import 'package:bachat_mobile/design/components.dart';
import 'package:bachat_mobile/design/theme.dart';
import 'package:bachat_mobile/domain/models.dart';
import 'package:bachat_mobile/presentation/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  Future<void> mount(
    WidgetTester tester,
    Brightness brightness,
    double scale,
  ) async {
    final db = await databaseFactoryMemory.openDatabase('aesthetics');
    addTearDown(db.close);
    final controller = AppController(BachatRepository(db, null))..ready = true;
    controller.startPreview(UserRole.teen);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [controllerProvider.overrideWith((ref) => controller)],
        child: MaterialApp(
          theme: BachatTheme.build(brightness),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: const DashboardShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    testWidgets('all tabs fit 320px with 200% text in $brightness', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(tester, brightness, 2);
      expect(tester.takeException(), isNull);
      for (final label in ['Activity', 'Plan']) {
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(label),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.widgetWithText(PageHeading, label), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$label must reflow');
      }
    });
  }

  testWidgets('search and active tab survive navigation breakpoint changes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester, Brightness.light, 1);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text('Activity'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Search transactions'),
      'Readings',
    );
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsNothing);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Readings',
    );
    expect(find.text('1 transaction · Current results'), findsOneWidget);
    tester.view.physicalSize = const Size(1100, 900);
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      1,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Readings',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('short landscape screens keep every destination reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester, Brightness.dark, 1);
    expect(find.byType(NavigationRail), findsNothing);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Plan'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(PageHeading, 'Plan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
