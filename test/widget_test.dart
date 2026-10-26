import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:bachat_mobile/main.dart';
import 'package:bachat_mobile/presentation/app.dart';
import 'package:bachat_mobile/presentation/auth_screens.dart';
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

  testWidgets('Spend and Receive open fixed flows with separate categories', (
    tester,
  ) async {
    final c = await controller();
    c.startPreview(UserRole.teen);
    await mount(tester, c);
    await tester.ensureVisible(find.text('Receive').first);
    await tester.tap(find.text('Receive').first);
    await tester.pumpAndSettle();
    expect(find.text('Receive money'), findsOneWidget);
    expect(find.byType(SegmentedButton<EntryDirection>), findsNothing);
    await tester.tap(
      find.widgetWithText(DropdownButtonFormField<String>, 'Category'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pocket money'), findsWidgets);
    expect(find.text('Salary'), findsWidgets);
    final receiveCategories = tester.widget<DropdownButton<String>>(
      find.descendant(
        of: find.widgetWithText(DropdownButtonFormField<String>, 'Category'),
        matching: find.byType(DropdownButton<String>),
      ),
    );
    expect(
      receiveCategories.items!.map((item) => item.value),
      isNot(contains('Food & dining')),
    );
    await tester.tap(find.text('Gift').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount'),
      '2000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Where did it come from?'),
      'Birthday',
    );
    await tester.ensureVisible(find.text('Save transaction'));
    await tester.tap(find.text('Save transaction'));
    await tester.pumpAndSettle();
    expect(c.entries.first.direction, EntryDirection.income);
    expect(c.entries.first.category, 'Gift');
  });

  testWidgets('Other savings is recorded once and excluded from spending', (
    tester,
  ) async {
    final c = await controller();
    c.startPreview(UserRole.teen);
    final before = MoneySummary(c.entries, DateTime.now()).spentMinor;
    await mount(tester, c);
    await tester.ensureVisible(find.text('Spend').first);
    await tester.tap(find.text('Spend').first);
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(DropdownButtonFormField<String>, 'Category'),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Other').last);
    await tester.tap(find.text('Other').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount'),
      '125.50',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Where or what was it?'),
      'Put aside',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Category name'),
      ' savings ',
    );
    await tester.pump();
    expect(
      find.text('Added to savings, outside your spending totals.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Save transaction'));
    await tester.tap(find.text('Save transaction'));
    await tester.pumpAndSettle();
    expect(c.entries.first.direction, EntryDirection.savings);
    expect(MoneySummary(c.entries, DateTime.now()).spentMinor, before);
    expect(MoneySummary(c.entries, DateTime.now()).savedMinor, 12550);
    await tester.ensureVisible(find.text('Put aside'));
    await tester.tap(find.text('Put aside'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(DropdownButtonFormField<String>, 'Category'),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Food & dining').last);
    await tester.tap(find.text('Food & dining').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save transaction'));
    await tester.tap(find.text('Save transaction'));
    await tester.pumpAndSettle();
    expect(MoneySummary(c.entries, DateTime.now()).savedMinor, 0);
    expect(MoneySummary(c.entries, DateTime.now()).spentMinor, before + 12550);
  });

  testWidgets('onboarding enables only teen authentication', (tester) async {
    final c = await controller();
    await mount(tester, c);
    expect(find.text('bachat'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Skip introduction'), 300);
    await tester.tap(find.text('Skip introduction'));
    await tester.pumpAndSettle();
    expect(find.text('Continue as a teen'), findsOneWidget);
    final parent = tester.widget<ChoiceChip>(
      find.byWidgetPredicate(
        (w) => w is ChoiceChip && (w.label as Text).data!.contains('parent'),
      ),
    );
    expect(parent.onSelected, isNull);
    await tester.ensureVisible(find.text('Continue as a teen'));
    await tester.tap(find.text('Continue as a teen'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
  });
  testWidgets(
    'auth modes retain email and validate before requesting sign-in',
    (tester) async {
      final c = await controller();
      await mount(tester, c);
      await tester.scrollUntilVisible(find.text('Skip introduction'), 300);
      await tester.tap(find.text('Skip introduction'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continue as a teen'));
      await tester.tap(find.text('Continue as a teen'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'teen@example.com',
      );
      await tester.ensureVisible(find.text('Create an account'));
      await tester.tap(find.text('Create an account'));
      await tester.pumpAndSettle();
      expect(find.text('teen@example.com'), findsOneWidget);
      await tester.ensureVisible(find.text('Create account'));
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(find.text('Use at least 10 characters.'), findsOneWidget);
    },
  );
  testWidgets('auth and profile setup fit 320px at 200 percent text', (
    tester,
  ) async {
    final c = await controller();
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final screen in [
      const AuthScreen(),
      const AuthScreen(recovery: true),
      const ProfileSetupScreen(),
    ]) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [controllerProvider.overrideWith((ref) => c)],
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 740),
                textScaler: TextScaler.linear(2),
              ),
              child: screen,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('teen dashboard and all tabs render', (tester) async {
    final c = await controller();
    c.startPreview(UserRole.teen);
    await mount(tester, c);
    expect(find.text('Demo'), findsOneWidget);
    expect(find.textContaining('Saved on this device'), findsNothing);
    expect(find.text('Rs 3,665'), findsOneWidget);
    await tester.tap(find.text('Activity').last);
    await tester.pumpAndSettle();
    expect(find.text('Activity').first, findsOneWidget);
    await tester.tap(find.text('Plan').last);
    await tester.pumpAndSettle();
    expect(find.text('Monthly budgets'), findsOneWidget);
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Preferences'), findsOneWidget);
    expect(find.text('Learn'), findsNothing);
    expect(find.text('You'), findsNothing);
  });
  testWidgets('parent dashboard is read-only', (tester) async {
    final c = await controller();
    c.startPreview(UserRole.parent);
    await mount(tester, c);
    expect(find.text('Child · Read only'), findsOneWidget);
    expect(find.text('Spend'), findsNothing);
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
    expect(find.text('Spend'), findsNothing);
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
    await tester.ensureVisible(find.text('Spend'));
    await tester.tap(find.text('Spend'));
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
    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ayesha').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sana'));
    await tester.pumpAndSettle();
    expect(c.isParent, isTrue);

    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
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
    await tester.scrollUntilVisible(
      find.byTooltip('Next goal'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final carousel = tester.widget<SingleChildScrollView>(
      find.descendant(
        of: find.byType(GoalCarousel),
        matching: find.byWidgetPredicate(
          (w) =>
              w is SingleChildScrollView &&
              w.scrollDirection == Axis.horizontal,
        ),
      ),
    );
    expect(carousel.controller!.offset, 0);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (w) => w is IconButton && w.tooltip == 'Previous goal',
            ),
          )
          .onPressed,
      isNull,
    );
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

  testWidgets(
    'activity filters apply visibly and reset without losing search',
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
      await tester.tap(find.byTooltip('Filter activity'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last month').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Apply filters'));
      await tester.tap(find.text('Apply filters'));
      await tester.pumpAndSettle();
      expect(find.text('No matches'), findsOneWidget);
      expect(find.text('Last month'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear advanced filters'));
      await tester.pumpAndSettle();
      expect(find.text('No matches'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(EntryTile),
          matching: find.text('Readings'),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(
              find.widgetWithText(TextField, 'Search transactions'),
            )
            .controller!
            .text,
        'Readings',
      );
    },
  );
  testWidgets(
    'add savings validates the remaining amount and updates the goal',
    (tester) async {
      final c = await controller();
      c.startPreview(UserRole.teen);
      await mount(tester, c);
      await tester.tap(find.text('Plan').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Add savings'),
      );
      await tester.tap(find.widgetWithText(OutlinedButton, 'Add savings'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount to add'),
        '8000',
      );
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Add savings'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Add savings'));
      await tester.pumpAndSettle();
      expect(
        find.text('This exceeds the remaining goal amount.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount to add'),
        '125.50',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Add savings'));
      await tester.pumpAndSettle();
      expect(c.goals.single.savedMinor, 447550);
      expect(c.entries.length, 5);
      expect(find.text('Savings added'), findsOneWidget);
    },
  );
  testWidgets('budget reuse action copies missing categories only', (
    tester,
  ) async {
    final c = await controller();
    c.startPreview(UserRole.teen);
    final now = DateTime.now();
    c.allBudgets.add(
      CategoryBudget(
        id: 'old-transport',
        ownerId: 'preview-teen',
        category: 'Transport',
        limitMinor: 50000,
        month: monthKey(DateTime(now.year, now.month - 1)),
      ),
    );
    await mount(tester, c);
    await tester.tap(find.text('Plan').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Reuse last month’s budgets'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reuse last month’s budgets'));
    await tester.pumpAndSettle();
    expect(c.budgets.length, 2);
    expect(find.text('Reuse last month’s budgets'), findsNothing);
    expect(find.text('Budget reused'), findsOneWidget);
  });
  testWidgets(
    'filter sheet and sorting survive narrow width at 200 percent text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = await controller();
      c.startPreview(UserRole.teen);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [controllerProvider.overrideWith((ref) => c)],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(320, 740),
                textScaler: TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: BachatApp(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Activity').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Filter activity'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Newest first'));
      await tester.tap(find.text('Newest first'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Amount: high to low').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Apply filters'));
      await tester.tap(find.text('Apply filters'));
      await tester.pumpAndSettle();
      expect(find.text('Amount: high to low'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
