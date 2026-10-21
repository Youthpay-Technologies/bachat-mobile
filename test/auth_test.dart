import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bachat_mobile/application/controller.dart';
import 'package:bachat_mobile/data/repository.dart';
import 'package:bachat_mobile/domain/models.dart';
import 'support/auth_fixture.dart';

void main() {
  Future<AppController> setup(
    Future<http.Response> Function(http.Request) handler, {
    bool signedIn = false,
  }) async {
    final db = await databaseFactoryMemory.openDatabase(
      'auth-${DateTime.now().microsecondsSinceEpoch}',
    );
    addTearDown(db.close);
    final client = SupabaseClient(
      'https://example.supabase.co',
      'public-test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        final response = await handler(request);
        return http.Response(
          response.body,
          response.statusCode,
          headers: {
            ...response.headers,
            'x-supabase-api-version': '2024-01-01',
          },
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);
    if (signedIn)
      await client.auth.recoverSession(jsonEncode(fixtureSession()));
    final c = AppController(BachatRepository(db, client));
    addTearDown(c.dispose);
    return c;
  }

  http.Response json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  test('auth inputs enforce email and password boundaries', () {
    expect(validateEmail('teen@example.com'), isNull);
    expect(validateEmail('bad'), isNotNull);
    expect(validateEmail('a b@example.com'), isNotNull);
    expect(validatePassword('short'), isNotNull);
    expect(validatePassword('a' * 129), isNotNull);
    expect(validatePassword('a long passphrase'), isNull);
  });
  test(
    'signup persists only pending email and requires confirmation',
    () async {
      Map<String, dynamic>? body;
      final c = await setup((r) async {
        body = jsonDecode(r.body) as Map<String, dynamic>;
        return json({'user': fixtureUser(), 'session': null});
      });
      expect(
        await c.signUp('  teen@example.com ', 'a long passphrase'),
        isTrue,
      );
      expect(c.signedIn, isFalse);
      expect(c.pendingEmail, 'teen@example.com');
      expect(await c.repository.loadPendingEmail(), 'teen@example.com');
      expect(body!['email'], 'teen@example.com');
      expect(c.authNotice, contains('confirmation'));
      expect(await c.repository.load(fixtureAccount), isNull);
    },
  );
  test(
    'invalid credentials provide recovery without creating session',
    () async {
      final c = await setup(
        (_) async => json({
          'code': 'invalid_credentials',
          'msg': 'Invalid login credentials',
        }, 400),
      );
      expect(await c.signIn('teen@example.com', 'incorrect'), isFalse);
      expect(c.error, contains('reset your password'));
      expect(c.signedIn, isFalse);
      expect(c.busy, isFalse);
    },
  );
  test(
    'successful sign-in opens profile setup without sample money data',
    () async {
      final c = await setup((r) async {
        if (r.url.path.endsWith('/token')) return json(fixtureSession());
        if (r.url.path.endsWith('/profiles')) return json([]);
        return json([]);
      });
      expect(await c.signIn('teen@example.com', 'a long passphrase'), isTrue);
      expect(c.signedIn, isTrue);
      expect(c.profileChecked, isTrue);
      expect(c.profile, isNull);
      expect(c.allEntries, isEmpty);
      expect(c.preview, isFalse);
    },
  );
  test('parent profile and sample-account bypasses are blocked', () async {
    var requests = 0;
    final c = await setup((_) async {
      requests++;
      return json([]);
    }, signedIn: true);
    expect(await c.createProfile('Parent', UserRole.parent, null), isFalse);
    expect(requests, 0);
    expect(c.error, contains('coming soon'));
    expect(() => c.startPreview(UserRole.teen), throwsStateError);
    await expectLater(c.startDemo(UserRole.teen), throwsStateError);
  });
  test(
    'password recovery returns a generic notice and handles expiry',
    () async {
      final c = await setup((r) async => json({}));
      expect(await c.requestPasswordReset('teen@example.com'), isTrue);
      expect(c.authNotice, contains('If an account exists'));
      expect(await c.finishPasswordRecovery('a long passphrase'), isFalse);
      expect(c.error, contains('expired'));
    },
  );
  test('owner mismatch is rejected before sending an outbox record', () async {
    var requests = 0;
    final c = await setup((_) async {
      requests++;
      return json([]);
    }, signedIn: true);
    await c.repository.queue(fixtureAccount, 'transactions', {
      'id': 'entry',
      'owner_id': 'another-user',
    }, {});
    await expectLater(
      c.repository.synchronize(fixtureAccount),
      throwsFormatException,
    );
    expect(requests, 0);
    expect(await c.repository.pending(fixtureAccount), hasLength(1));
  });
  test('pagination loads records beyond the server page limit', () async {
    var pages = 0;
    final c = await setup((r) async {
      pages++;
      if (r.url.queryParameters.containsKey('id'))
        return json([
          {'id': 'last', 'owner_id': fixtureAccount},
        ]);
      return json(
        List.generate(
          500,
          (i) => {
            'id': 'id-${i.toString().padLeft(4, '0')}',
            'owner_id': fixtureAccount,
          },
        ),
      );
    }, signedIn: true);
    final rows = await c.repository.fetchRows('transactions', fixtureAccount);
    expect(rows, hasLength(501));
    expect(pages, 2);
  });
  test(
    'simultaneous savings additions are serialized without losing increments',
    () async {
      final db = await databaseFactoryMemory.openDatabase('serial');
      addTearDown(db.close);
      final c = AppController(BachatRepository(db, null));
      addTearDown(c.dispose);
      c.startPreview(UserRole.teen);
      await Future.wait([
        c.addSavings('preview-goal', 100),
        c.addSavings('preview-goal', 250),
      ]);
      expect(c.goals.single.savedMinor, 435350);
      expect(
        (await c.repository.load(AppController.demoKey))!['goals'],
        isNotEmpty,
      );
    },
  );
  test(
    'persistence failure leaves visible financial records unchanged',
    () async {
      final db = await databaseFactoryMemory.openDatabase('failed-write');
      final c = AppController(BachatRepository(db, null));
      addTearDown(c.dispose);
      c.startPreview(UserRole.teen);
      final before = c.goals.single.savedMinor;
      await db.close();
      await expectLater(c.addSavings('preview-goal', 100), throwsA(anything));
      expect(c.goals.single.savedMinor, before);
    },
  );
  test('bad transaction fields fail before entering the outbox', () async {
    final db = await databaseFactoryMemory.openDatabase('bad-entry');
    addTearDown(db.close);
    final c = AppController(BachatRepository(db, null));
    addTearDown(c.dispose);
    c.startPreview(UserRole.teen);
    await expectLater(
      c.saveEntry(
        MoneyEntry(
          id: 'bad',
          ownerId: c.profile!.id,
          merchant: '',
          amountMinor: -1,
          direction: EntryDirection.expense,
          category: 'unknown',
          occurredAt: DateTime.now(),
        ),
      ),
      throwsFormatException,
    );
    expect(c.entries, hasLength(5));
  });
}
