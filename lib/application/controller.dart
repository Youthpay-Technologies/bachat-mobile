import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sembast/sembast.dart';
import '../data/database.dart';
import '../data/repository.dart';
import '../domain/models.dart';
import 'package:another_telephony/telephony.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:http/http.dart' as http;

final controllerProvider = ChangeNotifierProvider<AppController>(
  (ref) => throw StateError('AppController must be provided at startup.'),
);

final _smsAmountExpression = RegExp(
  r'(?:rs\.?|pkr|₨)\s*([\d,]+(?:\.\d{1,2})?)|([\d,]+(?:\.\d{1,2})?)\s*(?:rs\.?|pkr|rupees?)|\b(?:debited|debit|credited|credit|spent|paid|purchase|withdrawn|withdrawal|deposited|deposit|transferred|transfer|charged|refund(?:ed)?)\b.{0,24}?([\d,]+(?:\.\d{1,2})?)',
  caseSensitive: false,
);

class AppController extends ChangeNotifier {
  AppController(this.repository) {
    _lifecycleListener = AppLifecycleListener(onResume: _handleAppResumed);
  }
  final BachatRepository repository;
  late final AppLifecycleListener _lifecycleListener;
  Profile? profile;
  List<FamilyLink> links = [];
  List<MoneyEntry> allEntries = [];
  List<CategoryBudget> allBudgets = [];
  List<SavingsGoal> allGoals = [];
  String? selectedChildId;
  UserRole chosenRole = UserRole.teen;
  String theme = 'system';
  String? error;
  String? familyCode;
  bool busy = false,
      ready = false,
      preview = false,
      offline = false,
      syncing = false;
  int pendingCount = 0;
  StreamSubscription<AuthState>? _auth;
  StreamSubscription<List<ConnectivityResult>>? _connection;
  Timer? _poll;
  RealtimeChannel? _familyChannel;
  int _generation = 0;
  int _localRevision = 0;
  String? _loadedAccount;
  bool _smsListenerStarted = false;

  void _handleAppResumed() {
    if (!_smsListenerStarted) return;
    unawaited(
      _processPendingSms().catchError((Object error) {
        this.error = 'Could not import a transaction received while the app was closed.';
        notifyListeners();
      }),
    );
  }
  SupabaseClient? get client => repository.cloud;
  String? get accountId => preview ? profile?.id : client?.auth.currentUser?.id;
  bool get signedIn => accountId != null;
  bool get isParent => profile?.role == UserRole.parent;
  bool get approved => links.any((l) => l.approved && l.teenId == profile?.id);
  bool get isTeenWithApprovedAccess =>
      profile != null && profile!.role == UserRole.teen && approved;
  bool get needsApproval => profile?.role == UserRole.teen && !approved;
  List<FamilyLink> get children => links.where((l) => l.approved).toList();
  String? get viewingId => isParent
      ? (children.any((link) => link.teenId == selectedChildId)
            ? selectedChildId
            : null)
      : profile?.id;
  String get viewingName => isParent
      ? children
                .where((l) => l.teenId == selectedChildId)
                .map((l) => l.teenName)
                .firstOrNull ??
            'Your child'
      : profile?.name ?? '';
  List<MoneyEntry> get entries =>
      allEntries.where((e) => e.ownerId == viewingId && !e.deleted).toList()
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  List<CategoryBudget> get budgets => allBudgets
      .where(
        (b) =>
            b.ownerId == viewingId &&
            !b.deleted &&
            b.month == monthKey(DateTime.now()),
      )
      .toList();
  List<SavingsGoal> get goals =>
      allGoals.where((g) => g.ownerId == viewingId && !g.deleted).toList();
  ThemeMode get themeMode => switch (theme) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  static const demoKey = 'demo-family-v1';

  void _restoreDemo(Map<String, dynamic> saved) {
    preview = true;
    profile = Profile.fromJson(
      Map<String, dynamic>.from(saved['profile'] as Map),
    );
    links = (saved['links'] as List)
        .map((j) => FamilyLink.fromJson(Map<String, dynamic>.from(j as Map)))
        .toList();
    allEntries = (saved['entries'] as List)
        .map((j) => MoneyEntry.fromJson(Map<String, dynamic>.from(j as Map)))
        .where((entry) => !{'preview-1', 'preview-2', 'preview-3', 'preview-4', 'preview-5'}.contains(entry.id))
        .toList();
    allBudgets = (saved['budgets'] as List)
        .map(
          (j) => CategoryBudget.fromJson(Map<String, dynamic>.from(j as Map)),
        )
        .where((budget) => budget.id != 'preview-budget')
        .toList();
    allGoals = (saved['goals'] as List)
        .map((j) => SavingsGoal.fromJson(Map<String, dynamic>.from(j as Map)))
        .where((goal) => goal.id != 'preview-goal')
        .toList();
    selectedChildId = saved['selected_child'] as String?;
    familyCode = saved['family_code'] as String?;
  }

  Future<void> startDemo(UserRole role) async {
    if (!preview) {
      final saved = await repository.load(demoKey);
      if (saved != null) _restoreDemo(saved);
    }
    startPreview(role);
    await repository.save(demoKey, snapshot());
  }

  Future<void> resetDemo() async {
    final role = profile?.role ?? UserRole.teen;
    _reset();
    startPreview(role);
    await repository.save(demoKey, snapshot());
  }

  Future<void> initialize() async {
    theme = await repository.loadTheme();
    chosenRole = UserRole.values.byName(await repository.loadRole());
    if (client == null) {
      final saved = await repository.load(demoKey);
      if (saved != null) {
        _restoreDemo(saved);
        await repository.save(demoKey, snapshot());
      }
      ready = true;
      notifyListeners();
      if (isTeenWithApprovedAccess) await initSmsListener();
      return;
    }
    if (accountId != null) await _hydrate();
    ready = true;
    notifyListeners();

    if (isTeenWithApprovedAccess) await initSmsListener();
    _auth = client?.auth.onAuthStateChange.listen((event) async {
      if (preview) return;
      if (event.event == AuthChangeEvent.signedOut) {
        _generation++;
        _reset();
        notifyListeners();
      } else if (event.session != null &&
          event.event != AuthChangeEvent.initialSession) {
        await _hydrate();
        if (isTeenWithApprovedAccess) {
          await initSmsListener();
        }
        await refresh();
      }
    });
    _connection = Connectivity().onConnectivityChanged.listen((results) {
      offline = results.contains(ConnectivityResult.none);
      notifyListeners();
      if (!offline) unawaited(refresh());
    });
    _poll = Timer.periodic(const Duration(seconds: 30), (_) {
      if (signedIn && !preview) unawaited(refresh());
    });
    if (signedIn) unawaited(refresh());
  }

  Map<String, dynamic> snapshot() => {
    'profile': profile?.toJson(),
    'links': links.map((l) => l.toJson()).toList(),
    'entries': allEntries.map((e) => e.toJson()).toList(),
    'budgets': allBudgets.map((b) => b.toJson()).toList(),
    'goals': allGoals.map((g) => g.toJson()).toList(),
    'selected_child': selectedChildId,
    'family_code': familyCode,
  };
  Future<void> _hydrate() async {
    final account = accountId;
    if (account == null) return;
    if (_loadedAccount != account) {
      _generation++;
      _reset();
      _loadedAccount = account;
    }
    final cached = await repository.load(account);
    if (cached != null) {
      profile = cached['profile'] == null
          ? null
          : Profile.fromJson(
              Map<String, dynamic>.from(cached['profile'] as Map),
            );
      links = (cached['links'] as List? ?? [])
          .map((j) => FamilyLink.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
      allEntries = (cached['entries'] as List? ?? [])
          .map((j) => MoneyEntry.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
      allBudgets = (cached['budgets'] as List? ?? [])
          .map(
            (j) => CategoryBudget.fromJson(Map<String, dynamic>.from(j as Map)),
          )
          .toList();
      allGoals = (cached['goals'] as List? ?? [])
          .map((j) => SavingsGoal.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
      selectedChildId = cached['selected_child'] as String?;
    }
    pendingCount = (await repository.pending(account)).length;
    notifyListeners();
  }

  Future<bool> run(Future<void> Function() action) async {
    if (busy) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on FormatException catch (e) {
      error = e.message;
      return false;
    } on AuthException catch (e) {
      error = e.message;
      return false;
    } on PostgrestException catch (e) {
      error = 'Unable to save. ${e.message}';
      return false;
    } catch (_) {
      error = 'Unable to connect. Check your connection and try again.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> createProfile(String name, UserRole role, int? age) =>
      run(() async {
        if (name.trim().isEmpty || name.trim().length > 60) {
          throw const FormatException(
            'Enter a name between 1 and 60 characters.',
          );
        }
        if (role == UserRole.teen && (age == null || age < 13 || age > 18)) {
          throw const FormatException(
            'Bachat teen accounts are for ages 13 to 18.',
          );
        }
        final id = accountId;
        if (id == null) {
          throw const FormatException('Sign in again to finish your profile.');
        }
        final p = Profile(
          id: id,
          name: name.trim(),
          role: role,
          age: role == UserRole.teen ? age : null,
        );
        await client!.from('profiles').insert(p.toJson());
        profile = p;
        await repository.save(id, snapshot());
        await refresh();
      });
  Future<void> refresh() async {
    final id = accountId, cloud = client;
    if (id == null || cloud == null || preview || syncing) return;
    final generation = _generation;
    final localRevision = _localRevision;
    syncing = true;
    notifyListeners();
    try {
      final p = await cloud
          .from('profiles')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (generation != _generation) return;
      if (p == null) {
        profile = null;
        return;
      }
      profile = Profile.fromJson(p);
      final rows = await cloud
          .from('family_links')
          .select(
            '*,teen:profiles!family_links_teen_id_fkey(name),parent:profiles!family_links_parent_id_fkey(name)',
          );
      if (generation != _generation) return;
      links = rows
          .map(
            (r) => FamilyLink.fromJson({
              ...r,
              'teen_name': (r['teen'] as Map?)?['name'] ?? 'Teen',
              'parent_name': (r['parent'] as Map?)?['name'] ?? 'Parent',
            }),
          )
          .toList();
      final visible = isParent
          ? children.map((l) => l.teenId).toSet()
          : (approved ? {id} : <String>{});
      if (isParent && !visible.contains(selectedChildId)) {
        selectedChildId = visible.firstOrNull;
      }
      allEntries.removeWhere((e) => !visible.contains(e.ownerId));
      allBudgets.removeWhere((b) => !visible.contains(b.ownerId));
      allGoals.removeWhere((g) => !visible.contains(g.ownerId));
      if (!isParent && approved) await repository.synchronize(id);
      pendingCount = (await repository.pending(id)).length;
      if (visible.isNotEmpty) {
        final data = await Future.wait([
          cloud
              .from('transactions')
              .select()
              .inFilter('owner_id', visible.toList()),
          cloud.from('budgets').select().inFilter('owner_id', visible.toList()),
          cloud
              .from('savings_goals')
              .select()
              .inFilter('owner_id', visible.toList()),
        ]);
        if (generation != _generation) return;
        final pending = await repository.pending(id);
        if (generation != _generation) return;
        List<Map<String, dynamic>> overlay(
          String table,
          List<Map<String, dynamic>> remote,
        ) {
          final merged = {for (final row in remote) row['id'] as String: row};
          for (final op in pending.where((op) => op.value['table'] == table)) {
            final row = Map<String, dynamic>.from(op.value['row'] as Map);
            if (visible.contains(row['owner_id'])) {
              merged[row['id'] as String] = row;
            }
          }
          return merged.values.toList();
        }

        if (localRevision == _localRevision) {
          allEntries = overlay(
            'transactions',
            data[0],
          ).map(MoneyEntry.fromJson).toList();
          allBudgets = overlay(
            'budgets',
            data[1],
          ).map(CategoryBudget.fromJson).toList();
          allGoals = overlay(
            'savings_goals',
            data[2],
          ).map(SavingsGoal.fromJson).toList();
        }
      }
      if (generation != _generation) return;
      offline = false;
      error = null;
      await repository.save(id, snapshot());
      _familyChannel ??= cloud
          .channel('family-$id')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'family_links',
            callback: (_) => unawaited(refresh()),
          )
          .subscribe();
    } catch (e) {
      offline = true;
      error = e is PostgrestException
          ? 'Sync needs attention. ${e.message}'
          : null;
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  Future<void> saveEntry(MoneyEntry entry) async {
    _requireEdit();
    if (entry.ownerId != profile!.id) {
      throw const FormatException('You can only edit your own records.');
    }
    _localRevision++;
    allEntries.removeWhere((e) => e.id == entry.id);
    allEntries.add(entry);
    await _persist('transactions', entry.toJson());
  }

  Future<void> saveBudget(CategoryBudget budget) async {
    _requireEdit();
    if (budget.ownerId != profile!.id) {
      throw const FormatException('You can only edit your own records.');
    }
    if (budget.limitMinor <= 0 || !categories.contains(budget.category)) {
      throw const FormatException(
        'Choose a category and a limit greater than zero.',
      );
    }
    _localRevision++;
    allBudgets.removeWhere((b) => b.id == budget.id);
    allBudgets.add(budget);
    await _persist('budgets', budget.toJson());
  }

  Future<void> saveGoal(SavingsGoal goal) async {
    _requireEdit();
    if (goal.ownerId != profile!.id) {
      throw const FormatException('You can only edit your own records.');
    }
    if (goal.targetMinor <= 0 ||
        goal.savedMinor < 0 ||
        goal.savedMinor > goal.targetMinor ||
        goal.title.trim().isEmpty) {
      throw const FormatException(
        'Use a positive target and a saved amount between zero and the target.',
      );
    }
    _localRevision++;
    allGoals.removeWhere((g) => g.id == goal.id);
    allGoals.add(goal);
    await _persist('savings_goals', goal.toJson());
  }

  Future<void> addSavings(String goalId, int amountMinor) async {
    _requireEdit();
    final goal = allGoals
        .where((g) => g.id == goalId && g.ownerId == profile!.id && !g.deleted)
        .firstOrNull;
    if (goal == null) {
      throw const FormatException('This goal is no longer available.');
    }
    if (goal.savedMinor >= goal.targetMinor) {
      throw const FormatException('This goal has already reached its target.');
    }
    if (amountMinor <= 0 || amountMinor > goal.targetMinor - goal.savedMinor) {
      throw FormatException(
        'Enter an amount between Rs 0.01 and ${money(goal.targetMinor - goal.savedMinor)}.',
      );
    }
    await saveGoal(
      SavingsGoal(
        id: goal.id,
        ownerId: goal.ownerId,
        title: goal.title,
        targetMinor: goal.targetMinor,
        savedMinor: goal.savedMinor + amountMinor,
      ),
    );
  }

  List<CategoryBudget> get reusableBudgets {
    final now = DateTime.now();
    final previous = monthKey(DateTime(now.year, now.month - 1));
    final existing = budgets.map((b) => b.category).toSet();
    return allBudgets
        .where(
          (b) =>
              b.ownerId == viewingId &&
              !b.deleted &&
              b.month == previous &&
              !existing.contains(b.category),
        )
        .toList();
  }

  Future<int> reusePreviousBudgets() async {
    _requireEdit();
    final previous = reusableBudgets;
    var copied = 0;
    for (final budget in previous) {
      // Recheck after each write so a repeated request cannot duplicate a category.
      if (budgets.any((b) => b.category == budget.category)) continue;
      await saveBudget(
        CategoryBudget(
          id: const Uuid().v4(),
          ownerId: profile!.id,
          category: budget.category,
          limitMinor: budget.limitMinor,
          month: monthKey(DateTime.now()),
        ),
      );
      copied++;
    }
    return copied;
  }

  void _requireEdit() {
    if (isParent || !approved || profile == null) {
      throw const FormatException(
        'An approved teen account is required to make changes.',
      );
    }
  }

  Future<void> _persist(String table, Map<String, dynamic> row) async {
    final id = profile!.id;
    if (!preview) {
      await repository.queue(id, table, row, snapshot());
      pendingCount = (await repository.pending(id)).length;
    } else {
      await repository.save(demoKey, snapshot());
    }
    notifyListeners();
    if (!preview) unawaited(refresh());
  }

  Future<void> generateCode() => run(() async {
    if (preview) {
      familyCode = 'BCHT-${const Uuid().v4().substring(0, 8).toUpperCase()}';
      await repository.save(demoKey, snapshot());
      return;
    }
    familyCode = await client!.rpc('generate_family_code') as String;
  });
  Future<bool> claimCode(String code) => run(() async {
    if (preview) {
      if (!isParent ||
          familyCode == null ||
          code.trim().toUpperCase() != familyCode) {
        throw const FormatException(
          'Enter the code generated in the teen demo.',
        );
      }
      if (links.any((l) => l.approved || l.status == 'pending')) {
        throw const FormatException(
          'This family is already connected or awaiting confirmation.',
        );
      }
      links = [
        const FamilyLink(
          id: 'preview-link',
          teenId: 'preview-teen',
          parentId: 'preview-parent',
          status: 'pending',
          teenName: 'Ayesha',
          parentName: 'Sana',
        ),
      ];
      familyCode = null;
      await repository.save(demoKey, snapshot());
      return;
    }
    final result =
        await client!.rpc(
              'claim_family_code',
              params: {'p_code': code.trim().toUpperCase()},
            )
            as Map;
    if (result['result'] != 'ok') {
      throw FormatException(switch (result['result']) {
        'locked' => 'Too many attempts. Wait 15 minutes and try again.',
        'already_requested' =>
          'You already requested this child. Check Family for their response.',
        _ => 'This code is invalid or expired. Ask your teen for a new one.',
      });
    }
    await refresh();
  });
  Future<void> decideLink(FamilyLink link, bool approve) => run(() async {
    if (preview) {
      if (isParent || link.status != 'pending') {
        throw const FormatException(
          'Only the teen can confirm a pending parent.',
        );
      }
      links = approve
          ? [
              FamilyLink(
                id: link.id,
                teenId: link.teenId,
                parentId: link.parentId,
                status: 'approved',
                teenName: link.teenName,
                parentName: link.parentName,
              ),
            ]
          : [];
      await repository.save(demoKey, snapshot());
      return;
    }
    final changed = await client!.rpc(
      'decide_family_link',
      params: {'p_id': link.id, 'p_approve': approve},
    );
    if (changed != true) {
      throw const FormatException(
        'This request has changed or expired. Refresh to see its current status.',
      );
    }
    await refresh();
  });
  Future<void> revokeLink(FamilyLink link) => run(() async {
    if (preview) {
      links.removeWhere((l) => l.id == link.id);
      await repository.save(demoKey, snapshot());
      notifyListeners();
      return;
    }
    final changed = await client!.rpc(
      'revoke_family_link',
      params: {'p_id': link.id},
    );
    if (changed != true) {
      throw const FormatException(
        'This link has already changed. Refresh and try again.',
      );
    }
    await refresh();
  });
  void selectChild(String id) {
    selectedChildId = id;
    notifyListeners();
    if (accountId != null) {
      unawaited(repository.save(preview ? demoKey : accountId!, snapshot()));
    }
  }

  Future<void> setTheme(String value) async {
    theme = value;
    await repository.saveTheme(value);
    notifyListeners();
  }

  Future<void> signOut() async {
    final id = accountId;
    _generation++;
    try {
      if (!preview) await client?.auth.signOut(scope: SignOutScope.local);
    } catch (_) {
      // GoTrue removes the local session before requesting server revocation.
      // Offline revocation failure must not retain this device's records.
      if (client?.auth.currentSession != null) rethrow;
    } finally {
      if (id != null) await repository.clearAccount(id);
      _reset();
      notifyListeners();
    }
  }

  void _reset() {
    _loadedAccount = null;
    profile = null;
    links = [];
    allEntries = [];
    allBudgets = [];
    allGoals = [];
    selectedChildId = null;
    preview = false;
    familyCode = null;
    pendingCount = 0;
    _familyChannel?.unsubscribe();
    _familyChannel = null;
  }

  void startPreview(UserRole role) {
    if (preview) {
      profile = Profile(
        id: role == UserRole.teen ? 'preview-teen' : 'preview-parent',
        name: role == UserRole.teen ? 'Ayesha' : 'Sana',
        role: role,
        age: role == UserRole.teen ? 16 : null,
      );
      selectedChildId = 'preview-teen';
      error = null;
      notifyListeners();
      return;
    }
    _generation++;
    _reset();
    preview = true;
    offline = false;
    error = null;
    const teenId = 'preview-teen';
    profile = Profile(
      id: role == UserRole.teen ? teenId : 'preview-parent',
      name: role == UserRole.teen ? 'Ayesha' : 'Sana',
      role: role,
      age: role == UserRole.teen ? 16 : null,
    );
    links = [
      const FamilyLink(
        id: 'preview-link',
        teenId: teenId,
        parentId: 'preview-parent',
        status: 'approved',
        teenName: 'Ayesha',
        parentName: 'Sana',
      ),
    ];
    selectedChildId = teenId;
    allEntries = [];
    allBudgets = [];
    allGoals = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _auth?.cancel();
    _connection?.cancel();
    _poll?.cancel();
    _familyChannel?.unsubscribe();
    _lifecycleListener.dispose();
    super.dispose();
  }

  // SMS INTEGRATION

  final Telephony _telephony = Telephony.instance;

  Future<void> initSmsListener() async {
    if (defaultTargetPlatform != TargetPlatform.android ||
        isParent ||
        !approved ||
        profile == null ||
        _smsListenerStarted) {
      return;
    }

    try {
      final permissionsGranted = await _telephony.requestSmsPermissions;
      if (permissionsGranted != true) {
        error =
            'SMS access was not granted. Allow SMS access in Android settings to import transactions.';
        notifyListeners();
        return;
      }

      _telephony.listenIncomingSms(
        onNewMessage: _onNewSmsMessage,
        onBackgroundMessage: backgroundSmsHandler,
        listenInBackground: true,
      );
      _smsListenerStarted = true;
      error = null;
      await _processPendingSms();
      await _loadPastSmsTransactions();
    } catch (_) {
      error = 'Could not start SMS import. Check SMS access and try again.';
      notifyListeners();
    }
  }

  Future<void> _onNewSmsMessage(SmsMessage message) async {
    final body = message.body ?? '';
    final address = message.address ?? '';
    if (!_isTransactionSms(body, address)) return;

    final entry = _parseSmsToMoneyEntry(
      body,
      timestamp: message.date == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(message.date!),
      sourceId: message.id?.toString(),
    );
    if (entry == null || _hasDuplicateTransaction(entry)) return;
    try {
      await saveEntry(entry);
    } catch (_) {
      error = 'Could not save a transaction received by SMS.';
      notifyListeners();
    }
  }

  Future<void> _loadPastSmsTransactions() async {
    final messages = await _telephony.getInboxSms(
      columns: [
        SmsColumn.ID,
        SmsColumn.ADDRESS,
        SmsColumn.BODY,
        SmsColumn.DATE,
      ],
    );

    for (final message in messages) {
      final body = message.body ?? '';
      final address = message.address ?? '';
      if (!_isTransactionSms(body, address)) continue;
      final entry = _parseSmsToMoneyEntry(
        body,
        timestamp: message.date == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(message.date!),
        sourceId: message.id?.toString(),
      );
      if (entry != null && !_hasDuplicateTransaction(entry)) {
        await saveEntry(entry);
      }
    }
    notifyListeners();
  }

  Future<void> _processPendingSms() async {
    if (!isTeenWithApprovedAccess) return;
    final store = stringMapStoreFactory.store('pending_sms_imports');
    final queued = await store.find(repository.database);
    for (final record in queued) {
      final message = record.value;
      final body = message['body'] as String? ?? '';
      final address = message['address'] as String? ?? '';
      if (_isTransactionSms(body, address)) {
        final date = message['date'] as int?;
        final entry = _parseSmsToMoneyEntry(
          body,
          timestamp: date == null ? null : DateTime.fromMillisecondsSinceEpoch(date),
          sourceId: record.key,
        );
        if (entry != null && !_hasDuplicateTransaction(entry)) {
          await saveEntry(entry);
        }
      }
      await store.record(record.key).delete(repository.database);
    }
  }

  bool _isTransactionSms(String body, String sender) {
    final content = '$body $sender'.toLowerCase();
    final transactionTerms = RegExp(
      r'\b(debit(?:ed)?|credit(?:ed)?|spent|paid|purchase[ds]?|bought|withdraw(?:n|al)?|deposit(?:ed)?|transfer(?:red)?|received|refund(?:ed)?|charged|payment|transaction)\b',
    );
    return transactionTerms.hasMatch(content) &&
        _smsAmountExpression.hasMatch(body);
  }

  MoneyEntry? _parseSmsToMoneyEntry(
    String smsBody, {
    DateTime? timestamp,
    String? sourceId,
  }) {
    final lower = smsBody.toLowerCase();

    EntryDirection direction = EntryDirection.expense;
    if (lower.contains('credit') ||
        lower.contains('received') ||
        lower.contains('deposit') ||
        lower.contains('refund')) {
      direction = EntryDirection.income;
    }

    final match = _smsAmountExpression.firstMatch(smsBody);
    if (match == null) return null;

    final rawAmount = (match.group(1) ?? match.group(2) ?? match.group(3))
        ?.replaceAll(',', '');
    if (rawAmount == null) return null;
    final int amountMinor;
    try {
      amountMinor = parseMoney(rawAmount);
    } on FormatException {
      return null;
    }
    String merchant = _extractMerchantName(smsBody);
    String category = _categorizeTransaction(merchant, smsBody);

    return MoneyEntry(
      id: sourceId == null
          ? const Uuid().v4()
          : const Uuid().v5(Uuid.NAMESPACE_URL, 'sms:$sourceId'),
      ownerId: profile!.id,
      merchant: merchant,
      amountMinor: amountMinor,
      direction: direction,
      category: category,
      occurredAt: timestamp ?? DateTime.now(),
    );
  }

  String _extractMerchantName(String body) {
    final atRegExp = RegExp(
      r'\b(?:at|to|from|infovisa\*|pos\*)\s+([A-Za-z0-9\s]+?)(?:\s+on|\s+avail|\s+avl|\.|$)',
      caseSensitive: false,
    );
    final match = atRegExp.firstMatch(body);
    if (match != null) {
      String found = match.group(1)!.trim();
      if (found.isNotEmpty && found.length < 30) return found;
    }
    return 'Bank Transaction';
  }

  String _categorizeTransaction(String merchant, String body) {
    final combined = '$merchant $body'.toLowerCase();

    if (combined.contains('foodpanda') ||
        combined.contains('mcdonalds') ||
        combined.contains('kfc') ||
        combined.contains('restaurant') ||
        combined.contains('cafe')) {
      return 'Food & dining';
    } else if (combined.contains('uber') ||
        combined.contains('careem') ||
        combined.contains('bykea') ||
        combined.contains('fuel') ||
        combined.contains('shell') ||
        combined.contains('PSO')) {
      return 'Transport';
    } else if (combined.contains('daraz') ||
        combined.contains('imtiaz') ||
        combined.contains('carrefour') ||
        combined.contains('grocery')) {
      return 'Groceries';
    } else if (combined.contains('readings') ||
        combined.contains('book') ||
        combined.contains('tuition') ||
        combined.contains('school')) {
      return 'Education';
    }

    return 'Other';
  }

  bool _hasDuplicateTransaction(MoneyEntry candidate) {
    final candidateMerchant = _normalizeMerchant(candidate.merchant);
    const genericMerchants = {'banktransaction', 'emailreceipt'};
    return allEntries.any((existing) {
      if (existing.id == candidate.id) return true;
      if (existing.amountMinor != candidate.amountMinor ||
          existing.direction != candidate.direction) {
        return false;
      }

      final minutesApart = existing.occurredAt
          .difference(candidate.occurredAt)
          .inMinutes
          .abs();
      final existingMerchant = _normalizeMerchant(existing.merchant);
      if (candidateMerchant == existingMerchant) return minutesApart <= 1440;
      if (genericMerchants.contains(candidateMerchant) ||
          genericMerchants.contains(existingMerchant)) {
        return minutesApart <= 30;
      }
      return candidate.category != 'Other' &&
          candidate.category == existing.category &&
          minutesApart <= 30;
    });
  }

  String _normalizeMerchant(String merchant) =>
      merchant.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  // GMAIL INTEGRATION

  static const _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
  static const _googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [gmail.GmailApi.gmailReadonlyScope],
    serverClientId: _googleServerClientId.isEmpty
        ? null
        : _googleServerClientId,
    clientId: _googleClientId.isEmpty ? null : _googleClientId,
  );

  Future<int> syncEmailTransactions() async {
    if (isParent || !approved || profile == null) {
      throw const FormatException(
        'An approved teen profile is required to sync transactions.',
      );
    }
    if (_googleServerClientId.isEmpty) {
      throw const FormatException(
        'Gmail sync is not configured yet. Add a Google web OAuth client ID as GOOGLE_SERVER_CLIENT_ID when building the app.',
      );
    }

    final account =
        await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
    if (account == null) {
      throw const FormatException(
        'Google sign-in was cancelled.',
      );
    }

    final authHeaders = await account.authHeaders;
    final httpClient = GoogleAuthClient(authHeaders);
    try {
      final gmailApi = gmail.GmailApi(httpClient);
      const query =
          '{debited credited receipt order invoice paid payment transaction purchase withdrawal deposit refund}';
      String? pageToken;
      var imported = 0;
      do {
        final response = await gmailApi.users.messages.list(
          'me',
          q: query,
          maxResults: 100,
          pageToken: pageToken,
        );
        for (final reference in response.messages ?? <gmail.Message>[]) {
          final messageId = reference.id;
          if (messageId == null) continue;
          final message = await gmailApi.users.messages.get('me', messageId);
          final transactionDate = message.internalDate == null
              ? DateTime.now()
              : DateTime.fromMillisecondsSinceEpoch(
                  int.parse(message.internalDate!),
                );
          final entry = _parseEmailToMoneyEntry(
            message.snippet ?? '',
            _extractEmailBody(message),
            messageId: messageId,
            timestamp: transactionDate,
          );
          if (entry != null && !_hasDuplicateTransaction(entry)) {
            await saveEntry(entry);
            imported++;
          }
        }
        pageToken = response.nextPageToken;
      } while (pageToken != null);
      notifyListeners();
      return imported;
    } finally {
      httpClient.close();
    }
  }

  String _extractEmailBody(gmail.Message message) {
    String? extract(gmail.MessagePart? part) {
      final data = part?.body?.data;
      if (data != null) {
        try {
          return utf8.decode(base64Url.decode(data), allowMalformed: true);
        } on FormatException {
          return null;
        }
      }
      for (final nested in part?.parts ?? <gmail.MessagePart>[]) {
        final content = extract(nested);
        if (content != null && content.isNotEmpty) return content;
      }
      return null;
    }

    final content = extract(message.payload);
    if (content != null && content.isNotEmpty) return content;
    return message.snippet ?? '';
  }

  MoneyEntry? _parseEmailToMoneyEntry(
    String snippet,
    String body, {
    String? messageId,
    DateTime? timestamp,
  }) {
    final content = '$snippet $body'.toLowerCase();

    EntryDirection direction = EntryDirection.expense;
    if (content.contains('credit') ||
        content.contains('received payment') ||
        content.contains('refund')) {
      direction = EntryDirection.income;
    }

    final amountRegExp = RegExp(
      r'(?:rs\.?|pkr|\$)\s*([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    );
    final match = amountRegExp.firstMatch(content);
    if (match == null) return null;

    final matchedText = match.group(0)?.toLowerCase() ?? '';
    if (matchedText.contains('\$')) {
      return null;
    }

    String cleanAmount = match.group(1)!.replaceAll(',', '');
    final int amountMinor;
    try {
      amountMinor = parseMoney(cleanAmount);
    } on FormatException {
      return null;
    }
    String merchant = 'Email Receipt';
    if (content.contains('foodpanda')) {
      merchant = 'Foodpanda';
    } else if (content.contains('uber') || content.contains('careem')) {
      merchant = 'Careem / Uber';
    } else if (content.contains('daraz')) {
      merchant = 'Daraz';
    } else if (content.contains('netflix')) {
      merchant = 'Netflix';
    } else {
      final extracted = _extractMerchantName(content);
      if (extracted != 'Bank Transaction') merchant = extracted;
    }

    String category = _categorizeTransaction(merchant, content);

    return MoneyEntry(
      id: messageId == null
          ? const Uuid().v4()
          : const Uuid().v5(Uuid.NAMESPACE_URL, 'gmail:$messageId'),
      ownerId: profile!.id,
      merchant: merchant,
      amountMinor: amountMinor,
      direction: direction,
      category: category,
      occurredAt: timestamp ?? DateTime.now(),
    );
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

@pragma('vm:entry-point')
Future<void> backgroundSmsHandler(SmsMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await openDatabase();
  try {
    final id = message.id?.toString() ??
        const Uuid().v5(
          Uuid.NAMESPACE_URL,
          'sms:${message.date}:${message.address}:${message.body}',
        );
    final store = stringMapStoreFactory.store('pending_sms_imports');
    await store.record(id).put(database, {
      'body': message.body ?? '',
      'address': message.address ?? '',
      'date': message.date,
    });
  } finally {
    await database.close();
  }
}
