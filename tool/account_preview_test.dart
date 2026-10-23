// Explicit report captures. All sessions, HTTP responses and PIN storage are
// isolated fixtures. This tool cannot connect to a real Supabase project.
import 'dart:convert';

import 'package:bachat_mobile/application/controller.dart';
import 'package:bachat_mobile/application/device_lock.dart';
import 'package:bachat_mobile/data/pin_storage.dart';
import 'package:bachat_mobile/data/repository.dart';
import 'package:bachat_mobile/domain/models.dart';
import 'package:bachat_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../test/support/auth_fixture.dart';
import 'preview_support.dart';

class _PreviewPinStorage implements PinStorage {
  final values = <String, String>{};
  @override
  Future<String?> read(String account) async => values[account];
  @override
  Future<void> write(String account, String value) async {
    values[account] = value;
  }

  @override
  Future<void> delete(String account) async {
    values.remove(account);
  }
}

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'render isolated account and PIN flows ${dark ? 'dark' : 'light'}',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final db = await databaseFactoryMemory.openDatabase(
          'account-preview-$dark',
        );
        addTearDown(db.close);
        await loadPreviewFonts(tester);
        Future<void> mount(AppController controller) async {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [controllerProvider.overrideWith((ref) => controller)],
              child: const MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(
                    size: Size(390, 844),
                    disableAnimations: true,
                  ),
                  child: RepaintBoundary(
                    key: previewBoundaryKey,
                    child: BachatApp(),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        Future<void> tap(String text) async {
          await tester.ensureVisible(find.text(text));
          await tester.tap(find.text(text));
          await tester.pumpAndSettle();
        }

        Future<void> capture(String name) =>
            capturePreview(tester, name, dark: dark);

        final signedOut = AppController(BachatRepository(db, null))
          ..ready = true
          ..theme = dark ? 'dark' : 'light';
        await mount(signedOut);
        await tap('Already have an account? Sign in');
        await capture('sign-in');
        await tap('Create an account');
        await capture('create-account');
        await tap('Back to sign in');
        await tap('Forgot password?');
        await capture('reset-password');
        await tester.pumpWidget(const SizedBox.shrink());

        final client = (await tester.runAsync(
          () async => SupabaseClient(
            'https://example.supabase.co',
            'public-test-fixture',
            authOptions: const AuthClientOptions(autoRefreshToken: false),
            httpClient: MockClient(
              (request) async => http.Response(
                '[]',
                200,
                headers: {'content-type': 'application/json'},
              ),
            ),
          ),
        ))!;
        addTearDown(client.dispose);
        await tester.runAsync(
          () => client.auth.recoverSession(jsonEncode(fixtureSession())),
        );
        final lock = DeviceLock(_PreviewPinStorage());
        addTearDown(lock.dispose);
        final signedIn =
            AppController(BachatRepository(db, client), deviceLock: lock)
              ..ready = true
              ..profileChecked = true
              ..theme = dark ? 'dark' : 'light';
        await mount(signedIn);
        await capture('profile-setup');
        await tester.runAsync(() async {
          await lock.bind(fixtureAccount);
          signedIn.profile = const Profile(
            id: fixtureAccount,
            name: 'Ayesha',
            role: UserRole.teen,
            age: 16,
          );
          await signedIn.setTheme(dark ? 'dark' : 'light');
        });
        await capture('pin-setup');
        final created = await tester.runAsync(() => lock.createPin('654321'));
        expect(created, isTrue);
        lock.lock();
        await capture('pin-unlock');
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
