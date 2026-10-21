import 'dart:async';
import 'support/auth_fixture.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:bachat_mobile/data/repository.dart';
import 'package:bachat_mobile/application/controller.dart';
import 'package:bachat_mobile/domain/models.dart';

void main() {
  test('outbox coalesces edits and isolates accounts atomically', () async {
    final db = await databaseFactoryMemory.openDatabase('queue');
    addTearDown(db.close);
    final r = BachatRepository(db, null);
    await r.queue(
      'teen-a',
      'transactions',
      {'id': 'entry', 'amount_minor': 100},
      {'version': 1},
    );
    await r.queue(
      'teen-a',
      'transactions',
      {'id': 'entry', 'amount_minor': 250},
      {'version': 2},
    );
    await r.queue(
      'teen-b',
      'transactions',
      {'id': 'entry', 'amount_minor': 999},
      {'version': 3},
    );
    expect((await r.pending('teen-a')).single.value['row'], {
      'id': 'entry',
      'amount_minor': 250,
    });
    expect((await r.load('teen-a'))!['version'], 2);
    await r.clearAccount('teen-a');
    expect(await r.pending('teen-a'), isEmpty);
    expect((await r.pending('teen-b')).length, 1);
    expect(await r.load('teen-a'), isNull);
  });
  test('parent cannot mutate a child record even through controller', () async {
    final db = await databaseFactoryMemory.openDatabase('read-only');
    addTearDown(db.close);
    final c = AppController(BachatRepository(db, null));
    addTearDown(c.dispose);
    c.startPreview(UserRole.parent);
    await expectLater(
      c.saveGoal(
        const SavingsGoal(
          id: 'attack',
          ownerId: 'preview-teen',
          title: 'Attempt',
          targetMinor: 100,
        ),
      ),
      throwsFormatException,
    );
  });
  test('teen cannot edit after last parent is revoked', () async {
    final db = await databaseFactoryMemory.openDatabase('revoked');
    addTearDown(db.close);
    final c = AppController(BachatRepository(db, null));
    addTearDown(c.dispose);
    c.startPreview(UserRole.teen);
    await c.revokeLink(c.links.first);
    await expectLater(
      c.saveBudget(
        CategoryBudget(
          id: 'attempt',
          ownerId: c.profile!.id,
          category: 'Other',
          limitMinor: 100,
          month: monthKey(DateTime.now()),
        ),
      ),
      throwsFormatException,
    );
  });
  test('a newer edit remains queued while an older version uploads', () async {
    final db = await databaseFactoryMemory.openDatabase('in-flight');
    addTearDown(db.close);
    final started = Completer<void>(), release = Completer<void>();
    Map<String, dynamic>? uploaded;
    final client = SupabaseClient(
      'https://example.supabase.co',
      'public-test-key',
      httpClient: MockClient((request) async {
        uploaded = Map<String, dynamic>.from(jsonDecode(request.body) as Map);
        started.complete();
        await release.future;
        return http.Response('', 201, request: request);
      }),
    );
    addTearDown(client.dispose);
    await client.auth.recoverSession(jsonEncode(fixtureSession('teen')));
    final r = BachatRepository(db, client);
    await r.queue(
      'teen',
      'transactions',
      {'id': 'entry', 'owner_id': 'teen', 'amount_minor': 100},
      {'version': 1},
    );
    final sync = r.synchronize('teen');
    await started.future;
    await r.queue(
      'teen',
      'transactions',
      {'id': 'entry', 'owner_id': 'teen', 'amount_minor': 250},
      {'version': 2},
    );
    release.complete();
    await sync;
    expect(uploaded!['amount_minor'], 100);
    expect((await r.pending('teen')).single.value['row'], {
      'id': 'entry',
      'owner_id': 'teen',
      'amount_minor': 250,
    });
    expect((await r.load('teen'))!['version'], 2);
  });
  test('chosen onboarding role survives OAuth browser navigation', () async {
    final db = await databaseFactoryMemory.openDatabase('role');
    addTearDown(db.close);
    final r = BachatRepository(db, null);
    await r.saveRole('parent');
    final reopened = BachatRepository(db, null);
    expect(await reopened.loadRole(), 'parent');
  });
  test(
    'sign-out clears cached financial data when remote logout is offline',
    () async {
      final db = await databaseFactoryMemory.openDatabase('offline-sign-out');
      addTearDown(db.close);
      const id = '8e04df61-f8f1-43eb-a81a-e69944346ab0';
      String segment(Object value) =>
          base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
      final token =
          '${segment({'alg': 'HS256', 'typ': 'JWT'})}.${segment({'sub': id, 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})}.signature';
      final client = SupabaseClient(
        'https://example.supabase.co',
        'public-test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/token')) {
            return http.Response(
              jsonEncode({
                'access_token': token,
                'refresh_token': 'test-refresh',
                'expires_in': 3600,
                'token_type': 'bearer',
                'user': {
                  'id': id,
                  'aud': 'authenticated',
                  'role': 'authenticated',
                  'email': 'fixture@example.invalid',
                  'app_metadata': {},
                  'user_metadata': {},
                  'created_at': '2026-01-01T00:00:00Z',
                },
              }),
              200,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }
          throw http.ClientException('Offline');
        }),
      );
      addTearDown(client.dispose);
      await client.auth.signInWithPassword(
        email: 'fixture@example.invalid',
        password: 'fixture-only',
      );
      final repository = BachatRepository(db, client);
      await repository.save(id, {'private_record': 'fixture'});
      final c = AppController(repository);
      addTearDown(c.dispose);
      await c.signOut();
      expect(c.signedIn, isFalse);
      expect(await repository.load(id), isNull);
    },
  );
}
