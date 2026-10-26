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
      final navigation = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      for (final item
          in navigation.destinations.cast<NavigationDestination>()) {
        expect(item.icon, isA<Icon>());
        expect(item.selectedIcon, isA<Icon>());
      }
      expect(navigation.height, 64);
      expect(
        tester.getRect(find.byType(NavigationBar)).bottom,
        tester.view.physicalSize.height / tester.view.devicePixelRatio - 12,
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
      expect(
        find.descendant(
          of: find.byType(ProfileScreen),
          matching: find.byType(AppBar),
        ),
        findsNothing,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final large in [false, true]) {
    testWidgets(
      'screens scroll behind the compact pill and final controls remain reachable ${large ? "at 200 percent" : "normally"}',
      (tester) async {
        tester.view.physicalSize = Size(large ? 320 : 390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        if (large) {
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        }
        await mount(tester);
        for (final label in ['Home', 'Activity', 'Plan']) {
          await tester.tap(
            find.descendant(
              of: find.byType(NavigationBar),
              matching: find.text(label),
            ),
          );
          await tester.pumpAndSettle();
          final content = tester.getRect(find.byType(IndexedStack));
          final navigation = tester.getRect(find.byType(NavigationBar));
          expect(content.bottom, 844);
          expect(navigation.bottom, 832);
          expect(content.contains(navigation.center), isTrue);
          expect(navigation.width, lessThanOrEqualTo(large ? 296 : 280));
          expect(tester.takeException(), isNull);
        }
        final scrollable = tester.state<ScrollableState>(
          find
              .descendant(
                of: find.byType(PlanPage),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
        await tester.pumpAndSettle();
        final action = find.text('Add savings').first;
        expect(
          tester.getRect(action).bottom,
          lessThan(tester.getRect(find.byType(NavigationBar)).top),
        );
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(find.byType(AddSavingsSheet), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

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
