import 'package:bachat_mobile/application/controller.dart';
import 'package:bachat_mobile/data/repository.dart';
import 'package:bachat_mobile/design/theme.dart';
import 'package:bachat_mobile/domain/models.dart';
import 'package:bachat_mobile/presentation/app.dart';
import 'package:bachat_mobile/presentation/forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  const goalName =
      'A laptop for school, creative projects and learning new skills';
  Future<AppController> mount(
    WidgetTester tester,
    Brightness brightness,
    double scale, {
    double keyboard = 0,
  }) async {
    final db = await databaseFactoryMemory.openDatabase('responsive-receipt');
    addTearDown(db.close);
    final c = AppController(BachatRepository(db, null))..ready = true;
    c.startPreview(UserRole.teen);
    c.allEntries.clear();
    c.allGoals.clear();
    c.allGoals.add(
      const SavingsGoal(
        id: 'goal',
        ownerId: 'preview-teen',
        title: goalName,
        targetMinor: 100000,
      ),
    );
    c.allCashBalances = [
      const CashBalance(
        ownerId: 'preview-teen',
        amountMinor: 50000,
        ledgerNetMinor: 0,
      ),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [controllerProvider.overrideWith((ref) => c)],
        child: MaterialApp(
          theme: BachatTheme.build(brightness),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
              viewInsets: EdgeInsets.only(bottom: keyboard),
            ),
            child: child!,
          ),
          home: const DashboardShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return c;
  }

  Future<void> chooseGoal(WidgetTester tester) async {
    final dropdown = find.widgetWithText(
      DropdownButtonFormField<String>,
      'Save to a goal (optional)',
    );
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(goalName).last);
    await tester.pumpAndSettle();
  }

  Future<void> saveEntry(WidgetTester tester, AppController c) async {
    await tester.ensureVisible(find.text('Save transaction'));
    await tester.tap(find.text('Save transaction'));
    await tester.runAsync(() async {
      for (
        var i = 0;
        i < 100 && find.byType(EntryForm).evaluate().isNotEmpty;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Receive can split money, edit its allocation and reverse it on deletion',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = await mount(tester, Brightness.dark, 1);
      await tester.ensureVisible(find.text('Receive').first);
      await tester.tap(find.text('Receive').first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount'),
        '1000',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Where did it come from?'),
        'Birthday money',
      );
      await chooseGoal(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount to save'),
        '400',
      );
      await saveEntry(tester, c);
      expect(c.availableMinor, 110000);
      expect(c.goals.single.totalSavedMinor, 40000);
      expect(c.entries.single.amountMinor, 100000);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Activity'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Birthday money'));
      await tester.tap(find.text('Birthday money'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount'),
        '300',
      );
      await tester.ensureVisible(find.text('Save transaction'));
      await tester.tap(find.text('Save transaction'));
      await tester.pumpAndSettle();
      expect(
        find.text('Savings cannot exceed the received amount.'),
        findsOneWidget,
      );
      expect(c.entries.single.amountMinor, 100000);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount'),
        '500',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount to save'),
        '200',
      );
      await saveEntry(tester, c);
      expect(c.availableMinor, 80000);
      expect(c.goals.single.totalSavedMinor, 20000);
      await tester.ensureVisible(find.text('Birthday money'));
      await tester.tap(find.text('Birthday money'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Delete transaction'));
      await tester.tap(find.text('Delete transaction'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(c.entries, isEmpty);
      expect(c.goals.single.totalSavedMinor, 0);
      expect(c.availableMinor, 50000);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'receipt save stays reachable above the keyboard on a small phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(tester, Brightness.dark, 2, keyboard: 220);
      await tester.ensureVisible(find.text('Receive').first);
      await tester.tap(find.text('Receive').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save transaction'));
      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.text('Save transaction')).bottom,
        lessThanOrEqualTo(348),
      );
    },
  );

  for (final brightness in Brightness.values) {
    for (final size in [
      const Size(320, 568),
      const Size(360, 640),
      const Size(390, 844),
      const Size(430, 932),
      const Size(600, 960),
      const Size(844, 390),
    ]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'money pages and receipt allocation fit $size at $scale in $brightness',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            await mount(tester, brightness, scale);
            for (final label in ['Home', 'Activity', 'Plan']) {
              await tester.tap(
                find.descendant(
                  of: find.byType(NavigationBar),
                  matching: find.text(label),
                ),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull, reason: label);
            }
            await tester.tap(
              find.descendant(
                of: find.byType(NavigationBar),
                matching: find.text('Home'),
              ),
            );
            await tester.pumpAndSettle();
            await tester.ensureVisible(find.text('Receive').first);
            await tester.tap(find.text('Receive').first);
            await tester.pumpAndSettle();
            await tester.enterText(
              find.widgetWithText(TextFormField, 'Amount'),
              '1000',
            );
            await chooseGoal(tester);
            await tester.ensureVisible(
              find.widgetWithText(TextFormField, 'Amount to save'),
            );
            await tester.enterText(
              find.widgetWithText(TextFormField, 'Amount to save'),
              '400',
            );
            await tester.ensureVisible(find.text('Save transaction'));
            expect(
              tester.takeException(),
              isNull,
              reason: 'Receipt allocation must reflow',
            );
            expect(
              tester.getRect(find.text('Save transaction')).bottom,
              lessThanOrEqualTo(size.height),
            );
          },
        );
      }
    }
  }
}
