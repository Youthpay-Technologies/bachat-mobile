import 'package:bachat_mobile/application/controller.dart';
import 'package:bachat_mobile/data/repository.dart';
import 'package:bachat_mobile/design/theme.dart';
import 'package:bachat_mobile/domain/models.dart';
import 'package:bachat_mobile/presentation/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';

class _SyncController extends AppController {
  _SyncController(Database db) : super(BachatRepository(db, null));
  int attempts = 0;
  @override
  Future<void> refresh() async {
    attempts++;
    pendingCount = 0;
    offline = false;
    notifyListeners();
  }
}

void main() {
  Future<_SyncController> mount(
    WidgetTester tester, {
    bool syncing = false,
  }) async {
    final db = await databaseFactoryMemory.openDatabase('sync-status');
    addTearDown(db.close);
    final c = _SyncController(db)
      ..ready = true
      ..offline = true
      ..pendingCount = 2
      ..syncing = syncing
      ..profile = const Profile(
        id: 'fixture',
        name: 'Teen',
        role: UserRole.teen,
        age: 16,
      );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [controllerProvider.overrideWith((ref) => c)],
        child: MaterialApp(
          theme: BachatTheme.build(Brightness.light),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const DashboardShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return c;
  }

  testWidgets(
    'unsynced changes remain visible on every tab at 320px and 200% text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(tester);
      for (final tab in ['Home', 'Activity', 'Plan', 'Learn', 'You']) {
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(tab),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Saved on this device. 2 changes waiting to sync.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('retry sync clears the status after pending changes are sent', (
    tester,
  ) async {
    final c = await mount(tester);
    await tester.tap(find.text('Retry sync'));
    await tester.pumpAndSettle();
    expect(c.attempts, 1);
    expect(find.text('Retry sync'), findsNothing);
    expect(
      find.text('Saved on this device. 2 changes waiting to sync.'),
      findsNothing,
    );
  });

  testWidgets('retry is disabled while a synchronization is in progress', (
    tester,
  ) async {
    final c = await mount(tester, syncing: true);
    final button = tester.widget<TextButton>(
      find.descendant(
        of: find.byType(SyncStatus),
        matching: find.byType(TextButton),
      ),
    );
    expect(button.onPressed, isNull);
    expect(c.attempts, 0);
  });
}
