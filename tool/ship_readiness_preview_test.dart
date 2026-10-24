// Isolated Flutter renders; no remote accounts or email are used.
import 'package:bachat_mobile/application/controller.dart';
import 'package:bachat_mobile/data/repository.dart';
import 'package:bachat_mobile/design/theme.dart';
import 'package:bachat_mobile/domain/models.dart';
import 'package:bachat_mobile/presentation/app.dart';
import 'package:bachat_mobile/presentation/data_privacy_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'preview_support.dart';

void main() {
  for (final large in [false, true]) {
    testWidgets(
      'render data information ${large ? "large dark" : "phone light"}',
      (tester) async {
        tester.view.physicalSize = Size(large ? 320 : 390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await loadPreviewFonts(tester);
        await tester.pumpWidget(
          RepaintBoundary(
            key: previewBoundaryKey,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: BachatTheme.build(
                large ? Brightness.dark : Brightness.light,
              ),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(large ? 2 : 1)),
                child: child!,
              ),
              home: const DataPrivacyScreen(),
            ),
          ),
        );
        await capturePreview(tester, 'ship-data', dark: large, large: large);
        await tester.ensureVisible(find.text('Open-source licenses'));
        await capturePreview(
          tester,
          'ship-data-details',
          dark: large,
          large: large,
        );
      },
    );
  }

  testWidgets('render offline changes on Home', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = await databaseFactoryMemory.openDatabase('offline-render');
    addTearDown(db.close);
    final c = AppController(BachatRepository(db, null))
      ..ready = true
      ..offline = true
      ..pendingCount = 2
      ..profile = const Profile(
        id: 'fixture',
        name: 'Teen',
        role: UserRole.teen,
        age: 16,
      );
    await loadPreviewFonts(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [controllerProvider.overrideWith((ref) => c)],
        child: RepaintBoundary(
          key: previewBoundaryKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: BachatTheme.build(Brightness.light),
            home: const DashboardShell(),
          ),
        ),
      ),
    );
    await capturePreview(tester, 'ship-offline', dark: false);
  });
}
