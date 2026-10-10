import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:bachat_mobile/main.dart';
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
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.textContaining('A parent must approve'), findsOneWidget);
  });
  testWidgets('teen dashboard and all tabs render', (tester) async {
    final c = await controller();
    c.startPreview(UserRole.teen);
    await mount(tester, c);
    expect(find.textContaining('PREVIEW'), findsOneWidget);
    expect(find.text('Rs 3,665'), findsOneWidget);
    await tester.tap(find.text('Activity').last);
    await tester.pumpAndSettle();
    expect(find.text('Your activity'), findsOneWidget);
    await tester.tap(find.text('Plan').last);
    await tester.pumpAndSettle();
    expect(find.text('Monthly budgets'), findsOneWidget);
    await tester.tap(find.text('Learn').last);
    await tester.pumpAndSettle();
    expect(find.text('COMING SOON'), findsOneWidget);
    await tester.tap(find.text('You').last);
    await tester.pumpAndSettle();
    expect(find.text('Family connections'), findsOneWidget);
  });
  testWidgets('parent dashboard is read-only', (tester) async {
    final c = await controller();
    c.startPreview(UserRole.parent);
    await mount(tester, c);
    expect(find.text('Your child · read-only view'), findsOneWidget);
    expect(find.text('Add a transaction'), findsNothing);
    await tester.tap(find.text('Plan').last);
    await tester.pumpAndSettle();
    expect(find.text('New goal'), findsNothing);
    expect(find.text('Add budget'), findsNothing);
  });
  testWidgets('last parent removal locks teen dashboard', (tester) async {
    final c = await controller();
    c.startPreview(UserRole.teen);
    await mount(tester, c);
    await c.revokeLink(c.links.first);
    await tester.pumpAndSettle();
    expect(find.text('A little support to get started'), findsOneWidget);
    expect(find.text('Add a transaction'), findsNothing);
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
  });
  testWidgets('transaction form validates and updates dashboard totals', (
    tester,
  ) async {
    final c = await controller();
    c.startPreview(UserRole.teen);
    await mount(tester, c);
    await tester.ensureVisible(find.text('Add a transaction'));
    await tester.tap(find.text('Add a transaction'));
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
}
