// Explicit visual check: flutter test tool/ux_preview_test.dart
// Uses isolated preview records; never authenticates or changes cloud data.

import 'package:bachat_mobile/application/controller.dart';
import 'package:bachat_mobile/data/repository.dart';
import 'package:bachat_mobile/domain/models.dart';
import 'package:bachat_mobile/main.dart';
import 'package:bachat_mobile/design/theme.dart';
import 'package:bachat_mobile/presentation/forms.dart' show SheetBody;
import 'package:bachat_mobile/presentation/app.dart'
    show EntryTile, ProfileScreen;
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

import 'preview_support.dart';

void main() {
  for (final dark in [false, true]) {
    for (final large in [false, true]) {
      testWidgets(
        'render ${dark ? 'dark' : 'light'} ${large ? 'large text' : 'normal'} journeys',
        (tester) async {
          tester.view.physicalSize = Size(large ? 320 : 390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final db = await databaseFactoryMemory.openDatabase('ux-preview');
          final controller = AppController(BachatRepository(db, null))
            ..ready = true
            ..theme = dark ? 'dark' : 'light';
          addTearDown(db.close);
          await loadPreviewFonts(tester);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [controllerProvider.overrideWith((ref) => controller)],
              child: RepaintBoundary(
                key: previewBoundaryKey,
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: BachatTheme.build(
                    dark ? Brightness.dark : Brightness.light,
                  ),
                  home: MediaQuery(
                    data: MediaQueryData(
                      size: Size(large ? 320 : 390, 844),
                      textScaler: TextScaler.linear(large ? 2 : 1),
                      disableAnimations: true,
                    ),
                    child: const BachatApp(),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          Future<void> capture(String name) =>
              capturePreview(tester, name, dark: dark, large: large);

          for (var step = 0; step < 3; step++) {
            await capture('introduction-${step + 1}');
            if (step < 2) {
              await tester.ensureVisible(find.text('Continue'));
              await tester.tap(find.text('Continue'));
              await tester.pumpAndSettle();
              await tester.drag(
                find.byType(SingleChildScrollView).first,
                const Offset(0, 3000),
              );
              await tester.pumpAndSettle();
            }
          }
          controller.startPreview(UserRole.teen);
          await tester.pumpAndSettle();
          await capture('home');
          for (final tab in ['Activity', 'Plan']) {
            await tester.tap(find.text(tab).last);
            await tester.pumpAndSettle();
            await capture(tab.toLowerCase());
          }

          if (!large) {
            Future<void> selectTab(String name) async {
              if (find.byType(ProfileScreen).evaluate().isNotEmpty) {
                await tester.pageBack();
                await tester.pumpAndSettle();
              }
              if (name == 'Profile') {
                await tester.tap(find.text('Home').last);
                await tester.pumpAndSettle();
                await tester.tap(find.byTooltip('Profile'));
              } else {
                await tester.tap(find.text(name).last);
              }
              await tester.pumpAndSettle();
            }

            Future<void> tapText(String name) async {
              await tester.ensureVisible(find.text(name).first);
              await tester.tap(find.text(name).first);
              await tester.pumpAndSettle();
            }

            Future<void> dismiss() async {
              final dialog = find.byType(AlertDialog);
              final routeContent = dialog.evaluate().isNotEmpty
                  ? dialog
                  : find.byType(SheetBody).last;
              Navigator.of(tester.element(routeContent)).pop();
              await tester.pumpAndSettle();
            }

            await selectTab('Home');
            await tester.ensureVisible(find.text('Spending by category'));
            await tester.drag(
              find.byType(Scrollable).first,
              const Offset(0, -300),
            );
            await tester.pumpAndSettle();
            await capture('home-details');
            await tapText('Spend');
            await tester.enterText(
              find.widgetWithText(TextFormField, 'Amount'),
              '250',
            );
            await tester.enterText(
              find.widgetWithText(TextFormField, 'Where or what was it?'),
              'Lunch at college',
            );
            await capture('spend');
            await tester.ensureVisible(find.text('Save transaction'));
            await tester.pumpAndSettle();
            await capture('spend-details');
            await dismiss();
            await tapText('Receive');
            await tester.enterText(
              find.widgetWithText(TextFormField, 'Amount'),
              '5000',
            );
            await tester.enterText(
              find.widgetWithText(TextFormField, 'Where did it come from?'),
              'Monthly allowance',
            );
            await capture('receive');
            await dismiss();
            await selectTab('Activity');
            await tester.enterText(
              find.widgetWithText(TextField, 'Search transactions'),
              'Readings',
            );
            await tester.pumpAndSettle();
            await capture('activity-search');
            await tester.ensureVisible(find.byType(EntryTile).first);
            await tester.tap(find.byType(EntryTile).first);
            await tester.pumpAndSettle();
            await tester.ensureVisible(find.text('Delete transaction'));
            await capture('edit-transaction');
            await tapText('Delete transaction');
            await capture('delete-confirmation');
            await dismiss();
            await dismiss();
            await tester.tap(find.byTooltip('Filter activity'));
            await tester.pumpAndSettle();
            await capture('activity-filters');
            await dismiss();
            await selectTab('Plan');
            await tapText('Add budget');
            await tester.enterText(
              find.widgetWithText(TextFormField, 'Monthly limit'),
              '2500',
            );
            await capture('budget');
            await dismiss();
            await tapText('New goal');
            await tester.enterText(
              find.widgetWithText(TextFormField, 'Goal name'),
              'Art supplies',
            );
            await tester.enterText(
              find.widgetWithText(TextFormField, 'Target amount'),
              '8000',
            );
            await tester.enterText(
              find.widgetWithText(TextFormField, 'Total saved so far'),
              '500',
            );
            await capture('goal');
            await dismiss();
            await tester.ensureVisible(find.text('Add savings'));
            await tester.pumpAndSettle();
            await capture('plan-goal');
            await tapText('Add savings');
            await tester.enterText(
              find.widgetWithText(TextFormField, 'Amount to add'),
              '500',
            );
            await capture('add-savings');
            await dismiss();
            await selectTab('Profile');
            await tapText('Appearance');
            await capture('appearance');
            await dismiss();
            controller.allEntries.clear();
            controller.allBudgets.clear();
            controller.allGoals.clear();
            await tester.runAsync(
              () => controller.setTheme(dark ? 'dark' : 'light'),
            );
            await selectTab('Home');
            await tester.drag(
              find.byType(SingleChildScrollView).first,
              const Offset(0, 3000),
            );
            await tester.pumpAndSettle();
            await capture('empty-home');
            await selectTab('Plan');
            await tester.drag(
              find.byType(SingleChildScrollView).first,
              const Offset(0, 3000),
            );
            await tester.pumpAndSettle();
            await capture('empty-plan');
          }
        },
      );
    }
  }
}
