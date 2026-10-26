import 'dart:async';
import 'dart:convert';
import 'package:bachat_mobile/data/repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'support/auth_fixture.dart';

void main() {
  test(
    'linked writes use one RPC and newer in-flight edits remain durable',
    () async {
      final db = await databaseFactoryMemory.openDatabase('linked-sync');
      addTearDown(db.close);
      final started = Completer<void>(), release = Completer<void>();
      Map<String, dynamic>? requestBody;
      final client = SupabaseClient(
        'https://example.supabase.co',
        'public-test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          expect(request.url.path, '/rest/v1/rpc/apply_money_changes');
          requestBody = jsonDecode(request.body) as Map<String, dynamic>;
          started.complete();
          await release.future;
          return http.Response('', 204, request: request);
        }),
      );
      addTearDown(client.dispose);
      await client.auth.recoverSession(jsonEncode(fixtureSession()));
      final r = BachatRepository(db, client);
      await r.queue(
        fixtureAccount,
        'savings_goals',
        {'id': 'goal', 'owner_id': fixtureAccount},
        {'version': 1},
      );
      await r.queue(
        fixtureAccount,
        'transactions',
        {'id': 'receipt', 'owner_id': fixtureAccount, 'amount_minor': 100},
        {'version': 2},
        atomicMoneySync: true,
      );
      final sync = r.synchronize(fixtureAccount);
      await started.future;
      await r.queue(
        fixtureAccount,
        'transactions',
        {'id': 'receipt', 'owner_id': fixtureAccount, 'amount_minor': 200},
        {'version': 3},
      );
      release.complete();
      await sync;
      expect((requestBody!['p_changes'] as List).length, 2);
      final pending = await r.pending(fixtureAccount);
      expect(pending.length, 1);
      expect((pending.single.value['row'] as Map)['amount_minor'], 200);
      expect(pending.single.value['atomic_money_sync'], isTrue);
      expect((await r.load(fixtureAccount))!['version'], 3);
    },
  );

  test(
    'failed atomic sync keeps every pending row for correction and retry',
    () async {
      final db = await databaseFactoryMemory.openDatabase('linked-failure');
      addTearDown(db.close);
      final client = SupabaseClient(
        'https://example.supabase.co',
        'public-test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'code': '23514',
              'message': 'Savings goal target would be exceeded.',
            }),
            400,
            request: request,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );
      addTearDown(client.dispose);
      await client.auth.recoverSession(jsonEncode(fixtureSession()));
      final r = BachatRepository(db, client);
      await r.queue(
        fixtureAccount,
        'savings_goals',
        {'id': 'goal', 'owner_id': fixtureAccount},
        {'version': 1},
      );
      await r.queue(
        fixtureAccount,
        'transactions',
        {'id': 'receipt', 'owner_id': fixtureAccount},
        {'version': 2},
        atomicMoneySync: true,
      );
      await expectLater(
        r.synchronize(fixtureAccount),
        throwsA(isA<PostgrestException>()),
      );
      expect((await r.pending(fixtureAccount)).length, 2);
      expect((await r.load(fixtureAccount))!['version'], 2);
    },
  );
}
