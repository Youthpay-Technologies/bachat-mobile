// Capture one complete new-account journey using isolated HTTP/PIN fixtures.
// No real account is created, no email is sent and no cloud data is accessed.
import 'dart:convert';

import 'package:bachat_mobile/application/controller.dart';
import 'package:bachat_mobile/application/device_lock.dart';
import 'package:bachat_mobile/data/repository.dart';
import 'package:bachat_mobile/design/theme.dart';
import 'package:bachat_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../test/device_lock_test.dart' show MemoryPinStorage;
import '../test/support/auth_fixture.dart';
import 'preview_support.dart';

void main() {
  testWidgets('capture the complete teen onboarding and first expense', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Map<String, dynamic>? profile;
    final transactions = <String, Map<String, dynamic>>{};
    var emailConfirmed = false;
    final fixtureRequests = <String>[];
    http.Response json(http.Request request, Object body, [int status = 200]) =>
        http.Response(
          jsonEncode(body),
          status,
          headers: {
            'content-type': 'application/json',
            'x-supabase-api-version': '2024-01-01',
          },
          request: request,
        );
    final client = (await tester.runAsync(
      () async => SupabaseClient(
        'https://example.supabase.co',
        'public-test-fixture',
        authOptions: AuthClientOptions(
          autoRefreshToken: false,
          pkceAsyncStorage: MemoryPkceStorage(),
        ),
        httpClient: MockClient((request) async {
          final path = request.url.path;
          fixtureRequests.add('${request.method} $path');
          if (path.endsWith('/signup')) {
            return json(request, {
              'user': {...fixtureUser(), 'email_confirmed_at': null},
            });
          }
          if (path.endsWith('/token')) {
            expect(
              emailConfirmed,
              isTrue,
              reason: 'The email step precedes sign-in.',
            );
            return json(request, fixtureSession());
          }
          if (path.endsWith('/profiles')) {
            if (request.method == 'POST') {
              profile = jsonDecode(request.body) as Map<String, dynamic>;
            }
            return json(request, [?profile]);
          }
          if (path.endsWith('/transactions')) {
            if (request.method == 'POST') {
              final row = jsonDecode(request.body) as Map<String, dynamic>;
              transactions[row['id'] as String] = row;
            }
            return json(request, transactions.values.toList());
          }
          if (path.endsWith('/budgets') || path.endsWith('/savings_goals')) {
            return json(request, []);
          }
          throw StateError(
            'Unexpected fixture request: ${request.method} $path',
          );
        }),
      ),
    ))!;
    addTearDown(client.dispose);
    final db = await databaseFactoryMemory.openDatabase('onboarding-report');
    addTearDown(db.close);
    final lock = DeviceLock(MemoryPinStorage());
    addTearDown(lock.dispose);
    final controller = AppController(
      BachatRepository(db, client),
      deviceLock: lock,
    )..theme = 'light';
    await tester.runAsync(
      () => controller.initialize(
        observeConnectivity: false,
        observeLinks: false,
        observeRealtime: false,
      ),
    );
    await loadPreviewFonts(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [controllerProvider.overrideWith((ref) => controller)],
        child: RepaintBoundary(
          key: previewBoundaryKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: BachatTheme.build(Brightness.light),
            home: const MediaQuery(
              data: MediaQueryData(
                size: Size(390, 844),
                disableAnimations: true,
              ),
              child: BachatApp(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) =>
        capturePreview(tester, 'onboarding-$name', dark: false);
    Future<void> tap(String text) async {
      await tester.ensureVisible(find.text(text));
      await tester.tap(find.text(text));
      await tester.pumpAndSettle();
    }

    Future<void> submit(String label) async {
      final button = find.widgetWithText(FilledButton, label);
      await tester.ensureVisible(button);
      await tester.runAsync(() async {
        await tester.tap(button);
        await Future.doWhile(() async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return controller.busy || controller.syncing || lock.busy;
        }).timeout(const Duration(seconds: 15));
      });
      await tester.pumpAndSettle();
      expect(controller.error, isNull, reason: fixtureRequests.join('\n'));
      expect(lock.error, isNull);
    }

    await capture('01-spending');
    await tap('Continue');
    await capture('02-budget');
    await tap('Continue');
    await capture('03-goal');
    await tap('Continue as a teen');
    await capture('04-sign-in');
    await tap('Create an account');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'fixture@example.invalid',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'sample-passphrase',
    );
    await capture('05-create-account');
    await submit('Create account');
    expect(controller.signedIn, isFalse);
    expect(controller.pendingEmail, 'fixture@example.invalid');
    await tester.ensureVisible(find.text(controller.authNotice!));
    await capture('06-verify-email');

    // The user opens the confirmation link in their own email app. Model that
    // external step in the fixture; do not invent an email-provider screenshot.
    emailConfirmed = true;
    await submit('Sign in');
    expect(find.text('A little about you'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Your name'),
      'Ayesha',
    );
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('16').last);
    await tester.pumpAndSettle();
    await capture('07-profile');
    await submit('Start tracking');
    expect(find.text('Create your PIN'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, '6-digit PIN'),
      '654321',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm PIN'),
      '654321',
    );
    await capture('08-pin');
    await submit('Save PIN');
    expect(controller.entries, isEmpty);
    await capture('09-first-home');
    await tap('Spend');
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '250');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Where or what was it?'),
      'Lunch at college',
    );
    await capture('10-first-expense');
    await tap('Save transaction');
    expect(controller.entries.single.amountMinor, 25000);
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, 3000),
    );
    await capture('11-expense-saved');
    lock.lock();
    await capture('12-returning-unlock');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
