import 'package:sembast/sembast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class SecureSessionStorage extends LocalStorage {
  const SecureSessionStorage();
  static const _storage = FlutterSecureStorage();
  static const _key = 'bachat_supabase_session';
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: _key);
  @override
  Future<String?> accessToken() => _storage.read(key: _key);
  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _key, value: persistSessionString);
  @override
  Future<void> removePersistedSession() => _storage.delete(key: _key);
}

class BachatRepository {
  BachatRepository(this.database, this.cloud);
  final Database database;
  final SupabaseClient? cloud;
  final _snapshots = stringMapStoreFactory.store('accounts');
  final _outbox = stringMapStoreFactory.store('outbox');
  final _preferences = stringMapStoreFactory.store('preferences');
  Future<Map<String, dynamic>?> load(String account) =>
      _snapshots.record(account).get(database);
  Future<void> save(String account, Map<String, dynamic> snapshot) async {
    await _snapshots.record(account).put(database, snapshot);
  }

  Future<String?> loadPendingEmail() async =>
      (await _preferences.record('verification').get(database))?['email']
          as String?;
  Future<void> savePendingEmail(String? email) async {
    await _preferences.record('verification').put(database, {'email': email});
  }

  Future<bool> loadRecovery() async =>
      (await _preferences.record('recovery').get(database))?['active'] == true;
  Future<void> saveRecovery(bool active) async {
    await _preferences.record('recovery').put(database, {'active': active});
  }

  Future<String> loadTheme() async =>
      (await _preferences.record('appearance').get(database))?['theme']
          as String? ??
      'dark';
  Future<void> saveTheme(String theme) async {
    await _preferences.record('appearance').put(database, {'theme': theme});
  }

  Future<String> loadRole() async =>
      (await _preferences.record('onboarding').get(database))?['role']
          as String? ??
      'teen';
  Future<void> saveRole(String role) async {
    await _preferences.record('onboarding').put(database, {'role': role});
  }

  Future<void> queue(
    String account,
    String table,
    Map<String, dynamic> row,
    Map<String, dynamic> snapshot, {
    bool atomicMoneySync = false,
  }) async {
    if (![
      'transactions',
      'budgets',
      'savings_goals',
      'cash_balances',
    ].contains(table)) {
      throw ArgumentError('Unknown sync table');
    }
    await database.transaction((txn) async {
      await _snapshots.record(account).put(txn, snapshot);
      final previous = await _outbox
          .record('$account:$table:${row['id']}')
          .get(txn);
      await _outbox.record('$account:$table:${row['id']}').put(txn, {
        'account': account,
        'table': table,
        'row': row,
        'operation': const Uuid().v4(),
        'atomic_money_sync':
            atomicMoneySync || previous?['atomic_money_sync'] == true,
      });
    });
  }

  Future<List<RecordSnapshot<String, Map<String, dynamic>>>> pending(
    String account,
  ) => _outbox.find(
    database,
    finder: Finder(filter: Filter.equals('account', account)),
  );
  Future<List<Map<String, dynamic>>> fetchRows(
    String table,
    String account,
  ) async {
    final client = cloud;
    if (client == null) return [];
    const pageSize = 500;
    final result = <Map<String, dynamic>>[];
    String? after;
    while (true) {
      if (client.auth.currentUser?.id != account) {
        throw const FormatException('Your account changed. Sign in again.');
      }
      var query = client.from(table).select().eq('owner_id', account);
      if (after != null) query = query.gt('id', after);
      final page = await query.order('id').limit(pageSize);
      result.addAll(page);
      if (page.length < pageSize) break;
      after = page.last['id'] as String;
    }
    return result;
  }

  Future<void> synchronize(String account) async {
    final client = cloud;
    if (client == null) return;
    for (final operation in await pending(account)) {
      final value = operation.value;
      if (client.auth.currentUser?.id != account) {
        throw const FormatException('Your account changed. Sign in again.');
      }
      final row = Map<String, dynamic>.from(value['row'] as Map);
      if (row['owner_id'] != account) {
        throw const FormatException(
          'Cannot sync a record owned by another account.',
        );
      }
      // Budgets have a natural owner/month/category identity across devices.
      if (value['table'] == 'budgets') {
        final existing = await client
            .from('budgets')
            .select('id')
            .eq('owner_id', account)
            .eq('month', row['month'])
            .eq('category', row['category'])
            .eq('deleted', false)
            .maybeSingle();
        if (existing != null) row['id'] = existing['id'];
      }
      if (client.auth.currentUser?.id != account) {
        throw const FormatException('Your account changed. Sign in again.');
      }
      await client.from(value['table'] as String).upsert(row);
      // Preserve any edit queued while the previous version was in flight.
      await database.transaction((txn) async {
        final latest = await _outbox.record(operation.key).get(txn);
        if (latest?['operation'] == value['operation']) {
          await _outbox.record(operation.key).delete(txn);
        }
      });
    }
  }

  Future<void> clearAccount(String account) async {
    await database.transaction((txn) async {
      await _snapshots.record(account).delete(txn);
      await _outbox.delete(
        txn,
        finder: Finder(filter: Filter.equals('account', account)),
      );
    });
  }
}
