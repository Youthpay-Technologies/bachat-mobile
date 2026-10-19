import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repository.dart';
import '../domain/models.dart';
import 'package:another_telephony/telephony.dart';

final controllerProvider = ChangeNotifierProvider<AppController>(
  (ref) => throw StateError('AppController must be provided at startup.'),
);

class AppController extends ChangeNotifier {
  AppController(this.repository);
  final BachatRepository repository;
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
  SupabaseClient? get client => repository.cloud;
  String? get accountId => preview ? profile?.id : client?.auth.currentUser?.id;
  bool get signedIn => accountId != null;
  bool get isParent => profile?.role == UserRole.parent;
  bool get approved => links.any((l) => l.approved && l.teenId == profile?.id);
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

  Future<void> startDemo(UserRole role) async {
    if (!preview) {
      final saved = await repository.load(demoKey);
      if (saved != null) _restoreDemo(saved);
    }
    startPreview(role);
    await repository.save(demoKey, snapshot());
  }

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
        .toList();
    allBudgets = (saved['budgets'] as List)
        .map(
          (j) => CategoryBudget.fromJson(Map<String, dynamic>.from(j as Map)),
        )
        .toList();
    allGoals = (saved['goals'] as List)
        .map((j) => SavingsGoal.fromJson(Map<String, dynamic>.from(j as Map)))
        .toList();
    selectedChildId = saved['selected_child'] as String?;
    familyCode = saved['family_code'] as String?;
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
      if (saved != null) _restoreDemo(saved);
      ready = true;
      notifyListeners();
      return;
    }
    if (accountId != null) await _hydrate();
    ready = true;
    notifyListeners();

    await initSmsListener();
    _auth = client?.auth.onAuthStateChange.listen((event) async {
      if (preview) return;
      if (event.event == AuthChangeEvent.signedOut) {
        _generation++;
        _reset();
        notifyListeners();
      } else if (event.session != null &&
          event.event != AuthChangeEvent.initialSession) {
        await _hydrate();
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
    final now = DateTime.now();
    allEntries = [
      MoneyEntry(
        id: 'preview-1',
        ownerId: teenId,
        merchant: 'Monthly allowance',
        amountMinor: 1500000,
        direction: EntryDirection.income,
        category: 'Other',
        occurredAt: DateTime(now.year, now.month, 1),
      ),
      MoneyEntry(
        id: 'preview-2',
        ownerId: teenId,
        merchant: 'Foodpanda',
        amountMinor: 86500,
        direction: EntryDirection.expense,
        category: 'Food & dining',
        occurredAt: now,
      ),
      MoneyEntry(
        id: 'preview-3',
        ownerId: teenId,
        merchant: 'Readings',
        amountMinor: 174000,
        direction: EntryDirection.expense,
        category: 'Education',
        occurredAt: now.subtract(const Duration(days: 1)),
      ),
      MoneyEntry(
        id: 'preview-4',
        ownerId: teenId,
        merchant: 'Careem',
        amountMinor: 42000,
        direction: EntryDirection.expense,
        category: 'Transport',
        occurredAt: now.subtract(const Duration(days: 2)),
      ),
      MoneyEntry(
        id: 'preview-5',
        ownerId: teenId,
        merchant: 'Lunch with friends',
        amountMinor: 64000,
        direction: EntryDirection.expense,
        category: 'Food & dining',
        occurredAt: now.subtract(const Duration(days: 3)),
      ),
    ];
    allBudgets = [
      CategoryBudget(
        id: 'preview-budget',
        ownerId: teenId,
        category: 'Food & dining',
        limitMinor: 400000,
        month: monthKey(now),
      ),
    ];
    allGoals = [
      const SavingsGoal(
        id: 'preview-goal',
        ownerId: teenId,
        title: 'A new pair of headphones',
        targetMinor: 1200000,
        savedMinor: 435000,
      ),
    ];
    notifyListeners();
  }

  @override
  void dispose() {
    _auth?.cancel();
    _connection?.cancel();
    _poll?.cancel();
    _familyChannel?.unsubscribe();
    super.dispose();
  }

  // SMS INTEGRATION

  final Telephony _telephony = Telephony.instance;

  Future<void> initSmsListener() async {
    // Only activate for teens or active accounts where editing is allowed
    if (isParent || !approved || profile == null) return;

    bool? permissionsGranted = await _telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted == true) {
      // 1. Optional: Backfill past transactions from inbox on first load
      await _loadPastSmsTransactions();

      // 2. Listen to live incoming SMS in foreground & background
      _telephony.listenIncomingSms(
        onNewMessage: _onNewSmsMessage,
        onBackgroundMessage: backgroundSmsHandler,
        listenInBackground: true,
      );
    }
  }

  Future<void> _onNewSmsMessage(SmsMessage message) async {
    final body = message.body ?? '';
    final address = message.address ?? '';

    if (_isTransactionSms(body, address)) {
      final entry = _parseSmsToMoneyEntry(body);
      if (entry != null) {
        try {
          await saveEntry(entry);
        } catch (_) {
          // Handle or ignore duplicate/invalid entries gracefully
        }
      }
    }
  }

  Future<void> _loadPastSmsTransactions() async {
    try {
      List<SmsMessage> messages = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(SmsColumn.BODY)
            .like("%debited%")
            .or(SmsColumn.BODY)
            .like("%credited%")
            .or(SmsColumn.BODY)
            .like("%spent%")
            .or(SmsColumn.BODY)
            .like("%paid%"),
      );

      for (var message in messages) {
        final body = message.body ?? '';
        final entry = _parseSmsToMoneyEntry(
          body,
          timestamp: message.date != null
              ? DateTime.fromMillisecondsSinceEpoch(message.date!)
              : null,
        );
        if (entry != null) {
          // Check if entry with similar details already exists to avoid duplication during re-syncs
          bool exists = allEntries.any(
            (e) =>
                e.merchant == entry.merchant &&
                e.amountMinor == entry.amountMinor &&
                e.occurredAt.difference(entry.occurredAt).inMinutes.abs() < 5,
          );
          if (!exists) {
            allEntries.add(entry);
          }
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  bool _isTransactionSms(String body, String sender) {
    final lower = body.toLowerCase();
    // Filter for common banking keywords in Pakistan (Habib Bank, Meezan, Alfalah, Easypaisa, JazzCash, etc.)
    return lower.contains('debited') ||
        lower.contains('credited') ||
        lower.contains('spent') ||
        lower.contains('paid') ||
        lower.contains('rs.') ||
        lower.contains('pkr');
  }

  MoneyEntry? _parseSmsToMoneyEntry(String smsBody, {DateTime? timestamp}) {
    final lower = smsBody.toLowerCase();

    // Determine direction (Income vs Expense)
    EntryDirection direction = EntryDirection.expense;
    if (lower.contains('credited') ||
        lower.contains('received') ||
        lower.contains('deposited')) {
      direction = EntryDirection.income;
    }

    // Extract amount using Regex (matches Rs. 1,500.00 or PKR 500)
    final amountRegExp = RegExp(
      r'(?:rs\.?|pkr)\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    );
    final match = amountRegExp.firstMatch(smsBody);
    if (match == null) return null;

    String cleanAmount = match.group(1)!.replaceAll(',', '');
    double parsedAmount = double.tryParse(cleanAmount) ?? 0.0;
    if (parsedAmount <= 0) return null;

    // Convert to minor units (matching your app's convention, e.g., multiplying by 100)
    int amountMinor = (parsedAmount * 100).round();

    // Extract merchant name
    String merchant = _extractMerchantName(smsBody);

    // Categorize based on merchant or text content
    String category = _categorizeTransaction(merchant, smsBody);

    return MoneyEntry(
      id: const Uuid().v4(),
      ownerId: profile!.id,
      merchant: merchant,
      amountMinor: amountMinor,
      direction: direction,
      category: category,
      occurredAt: timestamp ?? DateTime.now(),
    );
  }

  String _extractMerchantName(String body) {
    // Common anchor words for merchant names in bank alerts
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
}

// Top-level background handler required by telephony package
@pragma('vm:entry-point')
void backgroundSmsHandler(SmsMessage message) {
  // Background isolates cannot easily access Riverpod providers directly without re-initializing local DB.
  // Typically, you initialize Sembast here and insert directly into the outbox or local db,
  // or let the foreground handler sync it up when the app next opens.
}
