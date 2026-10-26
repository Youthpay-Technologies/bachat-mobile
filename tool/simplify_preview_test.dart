import 'package:bachat_mobile/application/controller.dart';
import 'package:bachat_mobile/data/repository.dart';
import 'package:bachat_mobile/design/theme.dart';
import 'package:bachat_mobile/domain/models.dart';
import 'package:bachat_mobile/presentation/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'preview_support.dart';

void main() {
  for (final large in [false, true]) {
    testWidgets(
      'capture new-user graph and setup at ${large ? "200 percent" : "normal"} text',
      (tester) async {
        tester.view.physicalSize = Size(large ? 320 : 390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final db = await databaseFactoryMemory.openDatabase('simplify-preview');
        addTearDown(db.close);
        final c = AppController(BachatRepository(db, null))..ready = true;
        c.startPreview(UserRole.teen);
        c.allEntries.clear();
        c.allBudgets.clear();
        c.allGoals.clear();
        await loadPreviewFonts(tester);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [controllerProvider.overrideWith((ref) => c)],
            child: RepaintBoundary(
              key: previewBoundaryKey,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: BachatTheme.build(Brightness.dark),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(large ? 2 : 1),
                    disableAnimations: true,
                  ),
                  child: child!,
                ),
                home: const DashboardShell(),
              ),
            ),
          ),
        );
        Future<void> capture(String name) =>
            capturePreview(tester, 'simplify-$name', dark: true, large: large);
        await capture('empty-home');
        await tester.runAsync(
          () => c.saveEntry(
            MoneyEntry(
              id: 'first',
              ownerId: 'preview-teen',
              merchant: 'Lunch',
              amountMinor: 12500,
              direction: EntryDirection.expense,
              category: 'Food & dining',
              occurredAt: DateTime.now(),
            ),
          ),
        );
        await capture('one-day-home');
        await tester.tap(find.text('Plan').last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Set a budget'));
        await tester.tap(find.text('Set a budget'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Monthly limit'),
          '2000',
        );
        await tester.ensureVisible(find.text('Save budget'));
        await tester.tap(find.text('Save budget'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Available amount'),
          '3500.50',
        );
        await capture('available-money-form');
        await tester.ensureVisible(find.text('Save available money'));
        await tester.tap(find.text('Save available money'));
        await tester.pumpAndSettle();
        await capture('plan-with-available-money');
        await tester.tap(find.text('Home').last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(MoneySetupCard).first);
        await capture('home-with-available-money');
        await tester.binding.handlePopRoute();
        await capture('exit-confirmation');
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      },
    );
  }
}
