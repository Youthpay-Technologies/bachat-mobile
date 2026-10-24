import 'package:bachat_mobile/application/controller.dart';
import 'package:bachat_mobile/application/licenses.dart';
import 'package:bachat_mobile/data/repository.dart';
import 'package:bachat_mobile/design/theme.dart';
import 'package:bachat_mobile/domain/models.dart';
import 'package:bachat_mobile/main.dart';
import 'package:bachat_mobile/presentation/auth_screens.dart';
import 'package:bachat_mobile/presentation/data_privacy_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  Future<AppController> controller() async {
    final db = await databaseFactoryMemory.openDatabase('data-privacy');
    addTearDown(db.close);
    return AppController(BachatRepository(db, null))..ready = true;
  }

  testWidgets(
    'data information is available before signup and preserves the form',
    (tester) async {
      final c = await controller();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [controllerProvider.overrideWith((ref) => c)],
          child: MaterialApp(
            theme: BachatTheme.build(Brightness.light),
            home: const AuthScreen(),
          ),
        ),
      );
      await tester.ensureVisible(find.text('Create an account'));
      await tester.tap(find.text('Create an account'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'teen@example.com',
      );
      await tester.ensureVisible(find.text('How Bachat uses your data'));
      await tester.tap(find.text('How Bachat uses your data'));
      await tester.pumpAndSettle();
      expect(find.byType(DataPrivacyScreen), findsOneWidget);
      expect(find.text('Your account'), findsOneWidget);
      expect(c.signedIn, isFalse);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.widgetWithText(TextFormField, 'Email'))
            .controller!
            .text,
        'teen@example.com',
      );
    },
  );

  testWidgets('settings opens data information and the native license viewer', (
    tester,
  ) async {
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
    await tester.ensureVisible(find.text('Your data'));
    await tester.tap(find.text('Your data'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Open-source licenses'));
    await tester.tap(find.text('Open-source licenses'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('data information reflows at 320px with 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: BachatTheme.build(Brightness.dark),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const DataPrivacyScreen(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Open-source licenses'));
    expect(tester.takeException(), isNull);
  });

  test('every bundled font has one readable license notice', () async {
    BachatLicenses.register();
    BachatLicenses.register();
    final entries = await LicenseRegistry.licenses.toList();
    for (final font in ['Instrument Sans', 'Instrument Serif', 'Inter']) {
      final matching = entries
          .where((entry) => entry.packages.contains(font))
          .toList();
      expect(matching, hasLength(1));
      expect(
        matching.single.paragraphs.map((p) => p.text).join(' '),
        contains('SIL OPEN FONT LICENSE'),
      );
    }
  });
}
