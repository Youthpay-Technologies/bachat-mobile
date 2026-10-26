import 'package:bachat_mobile/application/controller.dart';
import 'package:bachat_mobile/data/repository.dart';
import 'package:bachat_mobile/domain/models.dart';
import 'package:bachat_mobile/main.dart';
import 'package:bachat_mobile/presentation/app.dart';
import 'package:bachat_mobile/presentation/forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  Future<AppController> mount(WidgetTester tester, {bool empty = false}) async {
    final db = await databaseFactoryMemory.openDatabase('simple-navigation');
    addTearDown(db.close);
    final c = AppController(BachatRepository(db, null))..ready = true;
    c.startPreview(UserRole.teen);
    if (empty) {
      c.allEntries.clear();
      c.allBudgets.clear();
      c.allGoals.clear();
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [controllerProvider.overrideWith((ref) => c)],
        child: const BachatApp(),
      ),
    );
    await tester.pumpAndSettle();
    return c;
  }

  testWidgets(
    'three destinations, no floating actions, complete profile and Back',
    (tester) async {
      await mount(tester);
      expect(
        tester
            .widget<NavigationBar>(find.byType(NavigationBar))
            .destinations
            .length,
        3,
      );
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.text('Learn'), findsNothing);
      expect(find.text('You'), findsNothing);
      expect(find.byTooltip('Your plan'), findsNothing);
      expect(
        find.descendant(of: find.byType(HomePage), matching: find.text('Home')),
        findsNothing,
      );
      await tester.tap(find.byTooltip('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Preferences'), findsOneWidget);
      expect(find.byType(ProfileScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('signing out from profile returns to the welcome screen safely', (
    tester,
  ) async {
    final c = await mount(tester);
    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    await tester.runAsync(c.signOut);
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsNothing);
    expect(c.signedIn, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back returns from Activity to Home and confirms before exit', (
    tester,
  ) async {
    await mount(tester);
    var exits = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') exits++;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
    expect(find.text('Exit Bachat?'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Exit Bachat?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(exits, 0);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exit'));
    await tester.pumpAndSettle();
    expect(exits, 1);
  });

  testWidgets(
    'guided budget setup continues to available money without creating fake income',
    (tester) async {
      final c = await mount(tester, empty: true);
      await tester.tap(find.text('Plan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set a budget'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Monthly limit'),
        '2000',
      );
      await tester.ensureVisible(find.text('Save budget'));
      await tester.tap(find.text('Save budget'));
      await tester.pumpAndSettle();
      expect(find.byType(AvailableMoneyForm), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Available amount'),
        '3500.50',
      );
      await tester.ensureVisible(find.text('Save available money'));
      await tester.tap(find.text('Save available money'));
      await tester.pumpAndSettle();
      expect(c.availableMinor, 350050);
      expect(c.entries, isEmpty);
      expect(c.budgets.length, 1);
      expect(find.text('Available to spend'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
