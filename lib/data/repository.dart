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

  Future<String> loadTheme() async =>
      (await _preferences.record('appearance').get(database))?['theme']
          as String? ??
      'system';
  Future<void> saveTheme(String theme) async {
    await _preferences.record('appearance').put(database, {'theme': theme});
  }

  Future<void> queue(
    String account,
    String table,
    Map<String, dynamic> row,
    Map<String, dynamic> snapshot,
  ) async {
    if (!['transactions', 'budgets', 'savings_goals'].contains(table)) {
      throw ArgumentError('Unknown sync table');
    }
    await database.transaction((txn) async {
      await _snapshots.record(account).put(txn, snapshot);
      await _outbox.record('$account:$table:${row['id']}').put(txn, {
        'account': account,
        'table': table,
        'row': row,
        'operation': const Uuid().v4(),
      });
    });
  }

  Future<List<RecordSnapshot<String, Map<String, dynamic>>>> pending(
    String account,
  ) => _outbox.find(
    database,
    finder: Finder(filter: Filter.equals('account', account)),
  );
  Future<void> synchronize(String account) async {
    final client = cloud;
    if (client == null) return;
    for (final operation in await pending(account)) {
      final value = operation.value;
      await client
          .from(value['table'] as String)
          .upsert(Map<String, dynamic>.from(value['row'] as Map));
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
