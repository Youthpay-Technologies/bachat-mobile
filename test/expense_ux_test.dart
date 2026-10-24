import 'package:bachat_mobile/application/controller.dart';
import 'package:bachat_mobile/data/repository.dart';
import 'package:bachat_mobile/domain/models.dart';
import 'package:bachat_mobile/main.dart';
import 'package:bachat_mobile/presentation/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  Future<AppController> mount(WidgetTester tester, {bool empty = false}) async {
    final db = await databaseFactoryMemory.openDatabase('expense-ux');
    addTearDown(db.close);
    final controller = AppController(BachatRepository(db, null))..ready = true;
    controller.startPreview(UserRole.teen);
    if (empty) {
      controller.allEntries.clear();
      controller.allGoals.clear();
      controller.allBudgets.clear();
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [controllerProvider.overrideWith((ref) => controller)],
        child: const BachatApp(),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('activity totals follow search and direction filters', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(find.text('Activity').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Search transactions'),
      'Readings',
    );
    await tester.pumpAndSettle();
    final totals = find.byType(ActivityTotals);
    expect(
      find.descendant(
        of: totals,
        matching: find.text('1 transaction · Current results'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: totals, matching: find.text('Rs 1,740')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: totals, matching: find.text('Received')),
      findsNothing,
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'Income'));
    await tester.pumpAndSettle();
    expect(totals, findsNothing);
    expect(find.text('No matches'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: totals, matching: find.text('Rs 15,000')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: totals, matching: find.text('Spent')),
      findsNothing,
    );
  });

  testWidgets('empty Home starts a savings goal directly', (tester) async {
    await mount(tester, empty: true);
    await tester.ensureVisible(find.text('Create a savings goal'));
    await tester.tap(find.text('Create a savings goal'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Goal name'), findsOneWidget);
  });

  testWidgets('empty Plan starts a category budget directly', (tester) async {
    await mount(tester, empty: true);
    await tester.tap(find.text('Plan').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Set your first budget'));
    await tester.tap(find.text('Set your first budget'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Monthly limit'), findsOneWidget);
  });
}
