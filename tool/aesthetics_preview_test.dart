// Explicit visual review with isolated records; no backend calls.
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
  for (final dark in [false, true]) {
    for (final wide in [false, true]) {
      testWidgets(
        'aesthetics ${dark ? "dark" : "light"} ${wide ? "wide" : "phone"}',
        (tester) async {
          tester.view.physicalSize = Size(wide ? 1100 : 390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final db = await databaseFactoryMemory.openDatabase(
            'aesthetics-preview',
          );
          addTearDown(db.close);
          final controller = AppController(BachatRepository(db, null))
            ..ready = true;
          controller.startPreview(UserRole.teen);
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
                  home: const DashboardShell(),
                ),
              ),
            ),
          );
          await capturePreview(
            tester,
            'aesthetics-${wide ? "wide" : "phone"}-home',
            dark: dark,
          );
          for (final tab in ['Activity', 'Plan']) {
            await tester.tap(
              find.descendant(
                of: wide
                    ? find.byType(NavigationRail)
                    : find.byType(NavigationBar),
                matching: find.text(tab),
              ),
            );
            await capturePreview(
              tester,
              'aesthetics-${wide ? "wide" : "phone"}-${tab.toLowerCase()}',
              dark: dark,
            );
          }
          await tester.tap(find.text('Home').last);
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Profile'));
          await capturePreview(
            tester,
            'aesthetics-${wide ? "wide" : "phone"}-profile',
            dark: dark,
          );
        },
      );
    }
  }
}
