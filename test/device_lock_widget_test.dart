import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bachat_mobile/main.dart';
import 'package:bachat_mobile/application/controller.dart';
import 'package:bachat_mobile/application/device_lock.dart';
import 'package:bachat_mobile/data/repository.dart';
import 'package:bachat_mobile/domain/models.dart';
import 'package:bachat_mobile/presentation/device_lock_screen.dart';
import 'device_lock_test.dart' show MemoryPinStorage;
import 'support/auth_fixture.dart';

void main() {
  testWidgets(
    'PIN overlay covers sheets, locks on background and confirms reset',
    (tester) async {
      final db = await databaseFactoryMemory.openDatabase('pin-widget');
      final client = (await tester.runAsync(
        () async => SupabaseClient(
          'https://example.supabase.co',
          'public-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
          httpClient: MockClient(
            (r) async => http.Response(
              jsonEncode(
                r.url.path.endsWith('/profiles')
                    ? [
                        {
                          'id': fixtureAccount,
                          'name': 'Teen',
                          'role': 'teen',
                          'age': 16,
                        },
                      ]
                    : [],
              ),
              200,
              headers: {'content-type': 'application/json'},
            ),
          ),
        ),
      ))!;
      await tester.runAsync(
        () => client.auth.recoverSession(jsonEncode(fixtureSession())),
      );
      final lock = DeviceLock(MemoryPinStorage());
      addTearDown(lock.dispose);
      addTearDown(client.dispose);
      addTearDown(db.close);
      await tester.runAsync(() async {
        await lock.bind(fixtureAccount);
        await lock.createPin('654321');
      });
      lock.lock();
      final c = AppController(BachatRepository(db, client), deviceLock: lock)
        ..ready = true
        ..profile = const Profile(
          id: fixtureAccount,
          name: 'Teen',
          role: UserRole.teen,
          age: 16,
        );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [controllerProvider.overrideWith((ref) => c)],
          child: const BachatApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unlock'), findsOneWidget);
      expect(find.text('Spend'), findsNothing);
      await tester.tap(find.text('Forgot PIN? Sign in again'));
      await tester.pumpAndSettle();
      expect(find.text('Sign out'), findsOneWidget);
      await tester.tap(find.text('Keep locked'));
      await tester.pumpAndSettle();
      await tester.runAsync(() => lock.unlock('654321'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Spend').first);
      await tester.tap(find.text('Spend').first);
      await tester.pumpAndSettle();
      expect(find.text('Spend money'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();
      expect(find.text('Spend money'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pumpAndSettle();
      expect(find.text('Spend money'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Unlock'), findsOneWidget);
      expect(find.text('Spend money'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  test(
    'PinInputFormatter only accepts digits up to 6 and clears composing',
    () {
      const formatter = PinInputFormatter(maxLength: 6);

      // Single digit input
      final single = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '1',
          selection: TextSelection.collapsed(offset: 1),
          composing: TextRange(start: 0, end: 1),
        ),
      );
      expect(single.text, '1');
      expect(single.selection.baseOffset, 1);
      expect(single.composing, TextRange.empty);

      // Strips letters and special characters
      final filtered = formatter.formatEditUpdate(
        const TextEditingValue(text: '1'),
        const TextEditingValue(
          text: '1a#2b3c4',
          selection: TextSelection.collapsed(offset: 8),
        ),
      );
      expect(filtered.text, '1234');
      expect(filtered.selection.baseOffset, 4);
      expect(filtered.composing, TextRange.empty);

      // Clamps to max 6 digits
      final clamped = formatter.formatEditUpdate(
        const TextEditingValue(text: '12345'),
        const TextEditingValue(
          text: '123456789',
          selection: TextSelection.collapsed(offset: 9),
        ),
      );
      expect(clamped.text, '123456');
      expect(clamped.selection.baseOffset, 6);
      expect(clamped.composing, TextRange.empty);
    },
  );

  testWidgets(
    'entering 6 digits auto-submits and unlocks without clicking button',
    (tester) async {
      final db = await databaseFactoryMemory.openDatabase('pin-auto-unlock');
      final client = (await tester.runAsync(
        () async => SupabaseClient(
          'https://example.supabase.co',
          'public-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
          httpClient: MockClient(
            (r) async => http.Response(
              jsonEncode(
                r.url.path.endsWith('/profiles')
                    ? [
                        {
                          'id': fixtureAccount,
                          'name': 'Teen',
                          'role': 'teen',
                          'age': 16,
                        },
                      ]
                    : [],
              ),
              200,
              headers: {'content-type': 'application/json'},
            ),
          ),
        ),
      ))!;
      await tester.runAsync(
        () => client.auth.recoverSession(jsonEncode(fixtureSession())),
      );
      addTearDown(client.dispose);
      addTearDown(db.close);
      Future<String> fastHasher(Map<String, String> v) async =>
          base64Encode(utf8.encode('fast-${v["pin"]}-${v["salt"]}'));
      final lock = DeviceLock(MemoryPinStorage(), hasher: fastHasher);
      addTearDown(lock.dispose);
      await lock.bind(fixtureAccount);
      await lock.createPin('123456');
      lock.lock();

      final c = AppController(BachatRepository(db, client), deviceLock: lock)
        ..ready = true
        ..profile = const Profile(
          id: fixtureAccount,
          name: 'Teen',
          role: UserRole.teen,
          age: 16,
        );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [controllerProvider.overrideWith((ref) => c)],
          child: const BachatApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unlock'), findsOneWidget);

      // Enter 6 digits directly into the PIN field
      await tester.enterText(find.byType(TextFormField).first, '123456');
      await tester.pump();
      await tester.pumpAndSettle();

      // Automatically unlocked!
      expect(lock.locked, isFalse);
      expect(find.text('Spend').first, findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'PIN creation auto-focuses confirm and auto-proceeds when matching 6 digits entered',
    (tester) async {
      final db = await databaseFactoryMemory.openDatabase('pin-auto-setup');
      final client = (await tester.runAsync(
        () async => SupabaseClient(
          'https://example.supabase.co',
          'public-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
          httpClient: MockClient(
            (r) async => http.Response(
              jsonEncode(
                r.url.path.endsWith('/profiles')
                    ? [
                        {
                          'id': fixtureAccount,
                          'name': 'Teen',
                          'role': 'teen',
                          'age': 16,
                        },
                      ]
                    : [],
              ),
              200,
              headers: {'content-type': 'application/json'},
            ),
          ),
        ),
      ))!;
      await tester.runAsync(
        () => client.auth.recoverSession(jsonEncode(fixtureSession())),
      );
      addTearDown(client.dispose);
      addTearDown(db.close);
      Future<String> fastHasher(Map<String, String> v) async =>
          base64Encode(utf8.encode('fast-${v["pin"]}-${v["salt"]}'));
      final lock = DeviceLock(MemoryPinStorage(), hasher: fastHasher);
      addTearDown(lock.dispose);
      await lock.bind(fixtureAccount);
      expect(lock.needsSetup, isTrue);

      final c = AppController(BachatRepository(db, client), deviceLock: lock)
        ..ready = true
        ..profile = const Profile(
          id: fixtureAccount,
          name: 'Teen',
          role: UserRole.teen,
          age: 16,
        );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [controllerProvider.overrideWith((ref) => c)],
          child: const BachatApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Create your PIN'), findsOneWidget);
      expect(find.text('Save PIN'), findsOneWidget);

      // Enter 6 digits into first PIN field
      final pinFields = find.byType(TextFormField);
      expect(pinFields, findsNWidgets(2));
      await tester.enterText(pinFields.at(0), '654321');
      await tester.pump();
      await tester.pumpAndSettle();

      // Enter 6 matching digits into confirm field
      await tester.enterText(pinFields.at(1), '654321');
      await tester.pump();
      await tester.pumpAndSettle();

      // Automatically saved and unlocked without tapping 'Save PIN'!
      expect(lock.needsSetup, isFalse);
      expect(lock.locked, isFalse);
      expect(find.text('Spend').first, findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
