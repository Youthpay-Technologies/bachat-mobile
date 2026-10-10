import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:bachat_mobile/main.dart';
import 'package:bachat_mobile/presentation/app.dart';
import 'package:bachat_mobile/design/components.dart';
import 'package:bachat_mobile/application/controller.dart';
import 'package:bachat_mobile/data/repository.dart';
import 'package:bachat_mobile/domain/models.dart';

void main() {
  Future<AppController> controller() async {
    final db = await databaseFactoryMemory.openDatabase(
      'widget-${DateTime.now().microsecondsSinceEpoch}',
    );
    addTearDown(db.close);
    final c = AppController(BachatRepository(db, null))..ready = true;

    return c;
  }

  Future<void> mount(WidgetTester tester, AppController c) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [controllerProvider.overrideWith((ref) => c)],
        child: const BachatApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('onboarding explains role and required approval', (tester) async {
    final c = await controller();
    await mount(tester, c);
    expect(find.text('bachat'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Skip introduction'), 300);
    await tester.tap(find.text('Skip introduction'));
    await tester.pumpAndSettle();
    expect(find.text('Continue as Ayesha'), findsOneWidget);
    expect(find.textContaining('Teen'), findsOneWidget);
  });
  testWidgets('teen dashboard and all tabs render', (tester) async {
    final c = await controller();
    c.startPreview(UserRole.teen);
    await mount(tester, c);
    expect(find.textContaining('Demo'), findsNothing);
    expect(find.textContaining('Saved on this device'), findsNothing);
    expect(find.text('Rs 3,665'), findsOneWidget);
    await tester.tap(find.text('Activity').last);
    await tester.pumpAndSettle();
    expect(find.text('Activity').first, findsOneWidget);
    await tester.tap(find.text('Plan').last);
    await tester.pumpAndSettle();
    expect(find.text('Monthly budgets'), findsOneWidget);
    await tester.tap(find.text('Learn').last);
    await tester.pumpAndSettle();
    expect(find.text('Coming soon'), findsOneWidget);
    await tester.tap(find.text('You').last);
    await tester.pumpAndSettle();
    expect(find.text('Family connections'), findsOneWidget);
  });
  testWidgets('parent dashboard is read-only', (tester) async {
    final c = await controller();
    c.startPreview(UserRole.parent);
    await mount(tester, c);
    expect(find.text('Child · Read only'), findsOneWidget);
    expect(find.text('Add transaction'), findsNothing);
    await tester.tap(find.text('Plan').last);
    await tester.pumpAndSettle();
    expect(find.text('New goal'), findsNothing);
    expect(find.text('Add budget'), findsNothing);
  });
  testWidgets('last parent removal locks teen dashboard', (tester) async {
    final c = await controller();
    c.startPreview(UserRole.teen);
    await mount(tester, c);
    await tester.runAsync(() => c.revokeLink(c.links.first));
    await tester.pumpAndSettle();
    expect(find.text('A little support to get started'), findsOneWidget);
    expect(find.text('Add transaction'), findsNothing);
  });
  testWidgets('narrow large text onboarding has no layout exception', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = await controller();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [controllerProvider.overrideWith((ref) => c)],
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 740),
              textScaler: TextScaler.linear(2),
            ),
            child: const BachatApp(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      MediaQuery.textScalerOf(tester.element(find.byType(AppGate))).scale(14),
      28,
    );
  });
  testWidgets('transaction form validates and updates dashboard totals', (
    tester,
  ) async {
    final c = await controller();
    c.startPreview(UserRole.teen);
    await mount(tester, c);
    await tester.ensureVisible(find.text('Add transaction'));
    await tester.tap(find.text('Add transaction'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save transaction'));
    await tester.tap(find.text('Save transaction'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a name to continue.'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount'),
      '125.50',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Where or what was it?'),
      'School lunch',
    );
    await tester.ensureVisible(find.text('Save transaction'));
    await tester.tap(find.text('Save transaction'));
    await tester.pumpAndSettle();
    expect(c.entries.first.merchant, 'School lunch');
    expect(c.entries.first.amountMinor, 12550);
    expect(find.text('Rs 3,790.50'), findsOneWidget);
  });
  testWidgets('teen dashboard supports narrow screen and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = await controller();
    c.startPreview(UserRole.teen);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [controllerProvider.overrideWith((ref) => c)],
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 740),
              textScaler: TextScaler.linear(2),
            ),
            child: const BachatApp(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      MediaQuery.textScalerOf(tester.element(find.byType(AppGate))).scale(14),
      28,
    );
  });
  testWidgets('budgets and savings goals can be saved through their forms', (
    tester,
  ) async {
    final c = await controller();
    c.startPreview(UserRole.teen);
    await mount(tester, c);
    await tester.tap(find.text('Plan').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add budget'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Monthly limit'),
      '4500',
    );
    await tester.ensureVisible(find.text('Save budget'));
    await tester.tap(find.text('Save budget'));
    await tester.pumpAndSettle();
    expect(c.budgets.single.limitMinor, 450000);
    await tester.ensureVisible(find.text('New goal'));
    await tester.tap(find.text('New goal'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Goal name'),
      'A bicycle',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Target amount'),
      '20000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Total saved so far'),
      '2500',
    );
    await tester.ensureVisible(find.text('Save goal'));
    await tester.tap(find.text('Save goal'));
    await tester.pumpAndSettle();
    expect(c.goals.last.title, 'A bicycle');
    expect(c.goals.last.savedMinor, 250000);
  });

  testWidgets(
    'search is preserved across tabs and empty filters can be cleared',
    (tester) async {
      final c = await controller();
      c.startPreview(UserRole.teen);
      await mount(tester, c);
      await tester.tap(find.text('Activity').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Search transactions'),
        'Readings',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plan').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Activity').last);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(
              find.widgetWithText(TextField, 'Search transactions'),
            )
            .controller!
            .text,
        'Readings',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Search transactions'),
        'unmatched query',
      );
      await tester.pumpAndSettle();
      expect(find.text('No matches'), findsOneWidget);
      await tester.ensureVisible(find.text('Clear filters'));
      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();
      expect(find.text('No matches'), findsNothing);
      expect(
        tester
            .widget<TextField>(
              find.widgetWithText(TextField, 'Search transactions'),
            )
            .controller!
            .text,
        isEmpty,
      );
    },
  );
  testWidgets('profile and appearance sheets apply their choices', (
    tester,
  ) async {
    final c = await controller();
    c.startPreview(UserRole.teen);
    await mount(tester, c);
    await tester.tap(find.byTooltip('Switch profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sana'));
    await tester.pumpAndSettle();
    expect(c.isParent, isTrue);
    await tester.tap(find.text('You').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(c.themeMode, ThemeMode.dark);
    expect(find.text('Appearance'), findsOneWidget);
  });
  testWidgets('multiple goals provide swipe and button carousel navigation', (
    tester,
  ) async {
    final c = await controller();
    c.startPreview(UserRole.teen);
    c.allGoals.add(
      const SavingsGoal(
        id: 'second-goal',
        ownerId: 'preview-teen',
        title: 'A bicycle',
        targetMinor: 2000000,
      ),
    );
    await mount(tester, c);
    await tester.scrollUntilVisible(find.byTooltip('Next goal'), 300);
    final carousel = tester.widget<SingleChildScrollView>(
      find.byWidgetPredicate(
        (w) =>
            w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      ),
    );
    expect(carousel.controller!.offset, 0);
    await tester.tap(find.byTooltip('Next goal'));
    await tester.pumpAndSettle();
    expect(carousel.controller!.offset, greaterThan(0));
    expect(find.text('2 goals'), findsOneWidget);
  });
  testWidgets('startup shows a skeleton without a forced loading delay', (
    tester,
  ) async {
    final c = await controller();
    c.ready = false;
    await mount(tester, c);
    expect(find.byType(DashboardSkeleton), findsOneWidget);
    await tester.runAsync(c.initialize);
    await tester.pumpAndSettle();
    expect(find.byType(DashboardSkeleton), findsNothing);
    expect(find.text('Skip introduction'), findsOneWidget);
  });
}
