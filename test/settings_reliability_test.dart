import 'package:bachat_mobile/application/controller.dart';
import 'package:bachat_mobile/data/repository.dart';
import 'package:bachat_mobile/domain/models.dart';
import 'package:bachat_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';

class _UnavailablePreferences extends BachatRepository {
  _UnavailablePreferences(Database database) : super(database, null);
  @override
  Future<void> saveTheme(String theme) async =>
      throw StateError('Storage full');
}

void main() {
  Future<AppController> controller() async {
    final db = await databaseFactoryMemory.openDatabase('settings-reliability');
    addTearDown(db.close);
    return AppController(_UnavailablePreferences(db))..ready = true;
  }

  test(
    'failed preference persistence preserves the current appearance',
    () async {
      final c = await controller();
      addTearDown(c.dispose);
      await expectLater(c.setTheme('dark'), throwsFormatException);
      expect(c.theme, 'system');
    },
  );

  test('invalid appearance is rejected before persistence', () async {
    final c = await controller();
    addTearDown(c.dispose);
    await expectLater(c.setTheme('unknown'), throwsFormatException);
    expect(c.theme, 'system');
  });

  testWidgets(
    'appearance failure is visible and does not escape the tap handler',
    (tester) async {
      final c = await controller();
      c.startPreview(UserRole.teen);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [controllerProvider.overrideWith((ref) => c)],
          child: const BachatApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('You').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Appearance'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(c.theme, 'system');
      expect(
        find.text(
          'Unable to save your appearance. Check available storage and try again.',
        ),
        findsOneWidget,
      );
      expect(c.busy, isFalse);
    },
  );
}
