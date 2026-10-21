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
import 'device_lock_test.dart' show MemoryPinStorage;
import 'support/auth_fixture.dart';

void main() {
  testWidgets(
    'PIN overlay covers sheets, locks on background and confirms reset',
    (tester) async {
      final db = await databaseFactoryMemory.openDatabase('pin-widget');
      final client = SupabaseClient(
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
      );
      await client.auth.recoverSession(jsonEncode(fixtureSession()));
      final lock = DeviceLock(MemoryPinStorage());
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
      lock.dispose();
      await tester.runAsync(() async {
        await client.dispose();
        await db.close();
      });
    },
  );
}
