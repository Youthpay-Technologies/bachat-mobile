import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repository.dart';
import '../domain/models.dart';

part 'auth.dart';

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
  String? pendingEmail;
  String? authNotice;
  bool recoveringPassword = false;
  bool profileChecked = false;
  bool _disposed = false;
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
  Future<void> _mutationTail = Future<void>.value();
  int _generation = 0;
  int _localRevision = 0;
  String? _loadedAccount;
  SupabaseClient? get client => repository.cloud;
  String? get accountId => preview ? profile?.id : client?.auth.currentUser?.id;
  bool get signedIn => accountId != null;
  bool get isParent => profile?.role == UserRole.parent;
  bool get approved => links.any((l) => l.approved && l.teenId == profile?.id);
  bool get needsApproval =>
      preview && profile?.role == UserRole.teen && !approved;
  bool get canUseOwnData =>
      profile?.role == UserRole.teen && (!preview || approved);
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
    if (client != null) {
      throw StateError(
        'Sample profiles are unavailable in authenticated mode.',
      );
    }
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
    if (client != null) {
      throw StateError(
        'Sample profiles are unavailable in authenticated mode.',
      );
    }
    final role = profile?.role ?? UserRole.teen;
    _reset();
    startPreview(role);
    await repository.save(demoKey, snapshot());
  }

  Future<void> initialize() async {
    theme = await repository.loadTheme();
    chosenRole = UserRole.teen;
    pendingEmail = await repository.loadPendingEmail();
    recoveringPassword = await repository.loadRecovery();
    if (client == null) {
      final saved = await repository.load(demoKey);
      if (saved != null) _restoreDemo(saved);
      ready = true;
      notifyListeners();
      return;
    }
    _auth = client!.auth.onAuthStateChange.listen(
      (event) {
        unawaited(_handleAuth(event));
      },
      onError: (Object event) {
        error = event is AuthException
            ? authMessage(event)
            : 'Unable to restore your session. Please sign in again.';
        notifyListeners();
      },
    );
    if (accountId != null) await _hydrate();
    ready = true;
    notifyListeners();
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

  Future<void> _handleAuth(AuthState event) async {
    if (preview || _disposed) return;
    try {
      if (event.event == AuthChangeEvent.signedOut) {
        final previous = _loadedAccount;
        _generation++;
        _reset();
        recoveringPassword = false;
        await repository.saveRecovery(false);
        if (previous != null) await repository.clearAccount(previous);
      } else if (event.session != null) {
        if (event.event == AuthChangeEvent.passwordRecovery) {
          recoveringPassword = true;
          await repository.saveRecovery(true);
        }
        await _hydrate();
        await refresh();
      }
    } catch (_) {
      error =
          'Unable to restore your account. Check your connection and retry.';
    }
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
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
    if (_loadedAccount == account && profile != null) return;
    if (_loadedAccount != account) {
      _generation++;
      _reset();
      _loadedAccount = account;
    }
    final generation = _generation;
    final cached = await repository.load(account);
    if (accountId != account || generation != _generation) return;
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
      profileChecked = profile != null;
    }
    final pending = await repository.pending(account);
    if (accountId != account || generation != _generation) return;
    pendingCount = pending.length;
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
      error = authMessage(e);
      return false;
    } on PostgrestException catch (e) {
      error = e.code == '23505'
          ? 'A record already exists for this category. Refresh and edit the existing record.'
          : 'Unable to save your changes. Refresh and try again.';
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
        if (role != UserRole.teen) {
          throw const FormatException('Parent accounts are coming soon.');
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
        final existing = await client!
            .from('profiles')
            .select()
            .eq('id', id)
            .maybeSingle();
        if (existing == null) await client!.from('profiles').insert(p.toJson());
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
        profileChecked = true;
        return;
      }
      profileChecked = true;
      profile = Profile.fromJson(p);
      if (isParent) {
        await signOut();
        error =
            'Parent accounts are coming soon. Please sign in with a teen account.';
        return;
      }
      links = [];
      final visible = {id};
      if (isParent && !visible.contains(selectedChildId)) {
        selectedChildId = visible.firstOrNull;
      }
      allEntries.removeWhere((e) => !visible.contains(e.ownerId));
      allBudgets.removeWhere((b) => !visible.contains(b.ownerId));
      allGoals.removeWhere((g) => !visible.contains(g.ownerId));
      if (!isParent) await repository.synchronize(id);
      pendingCount = (await repository.pending(id)).length;
      if (visible.isNotEmpty) {
        final data = await Future.wait([
          repository.fetchRows('transactions', id),
          repository.fetchRows('budgets', id),
          repository.fetchRows('savings_goals', id),
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
      if (localRevision == _localRevision) {
        await repository.save(id, snapshot());
      }
    } catch (e) {
      if (generation != _generation) return;
      offline = e is! PostgrestException;
      error = e is PostgrestException
          ? (e.code == '23505'
                ? 'A budget category already exists on another device. Review it before retrying sync.'
                : 'Unable to sync your changes. Try again.')
          : 'You are offline. Your saved changes will sync when you reconnect.';
    } finally {
      if (generation == _generation) syncing = false;
      notifyListeners();
    }
  }

  Future<void> _serialize(Future<void> Function() action) {
    final account = accountId;
    final generation = _generation;
    final next = _mutationTail.then((_) async {
      if (account != accountId || generation != _generation || _disposed) {
        throw const FormatException('Your account changed. Try again.');
      }
      _requireEdit();
      await action();
    });
    _mutationTail = next.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return next;
  }

  Future<void> _commitRecord(
    String table,
    Map<String, dynamic> row, {
    List<MoneyEntry>? entries,
    List<CategoryBudget>? budgets,
    List<SavingsGoal>? goals,
  }) async {
    final id = profile!.id;
    final generation = _generation;
    final next = snapshot();
    if (entries != null) {
      next['entries'] = entries.map((e) => e.toJson()).toList();
    }
    if (budgets != null) {
      next['budgets'] = budgets.map((e) => e.toJson()).toList();
    }
    if (goals != null) next['goals'] = goals.map((e) => e.toJson()).toList();
    _localRevision++;
    if (preview) {
      await repository.save(demoKey, next);
    } else {
      await repository.queue(id, table, row, next);
    }
    if (generation != _generation || accountId != id) return;
    if (entries != null) allEntries = entries;
    if (budgets != null) allBudgets = budgets;
    if (goals != null) allGoals = goals;
    pendingCount = preview ? 0 : (await repository.pending(id)).length;
    notifyListeners();
    if (!preview) unawaited(refresh());
  }

  void _validateOwner(String owner) {
    if (owner != profile!.id) {
      throw const FormatException('You can only edit your own records.');
    }
  }

  Future<void> saveEntry(MoneyEntry entry) => _serialize(() async {
    _validateOwner(entry.ownerId);
    final now = DateTime.now();
    if (entry.merchant.trim().isEmpty ||
        entry.merchant.length > 100 ||
        entry.note.length > 500 ||
        entry.amountMinor <= 0 ||
        entry.amountMinor > 999999999999 ||
        !categories.contains(entry.category) ||
        entry.occurredAt.isBefore(DateTime(2000)) ||
        !entry.occurredAt.isBefore(
          DateTime(now.year, now.month, now.day + 1),
        )) {
      throw const FormatException(
        'Check the amount, category, date and transaction details.',
      );
    }
    await _commitRecord(
      'transactions',
      entry.toJson(),
      entries: [...allEntries.where((e) => e.id != entry.id), entry],
    );
  });

  Future<void> saveBudget(CategoryBudget budget) => _serialize(() async {
    _validateOwner(budget.ownerId);
    if (budget.limitMinor <= 0 ||
        budget.limitMinor > 999999999999 ||
        !categories.contains(budget.category) ||
        !RegExp(r'^\d{4}-(0[1-9]|1[0-2])-01$').hasMatch(budget.month)) {
      throw const FormatException(
        'Choose a valid category, month and positive limit.',
      );
    }
    if (!budget.deleted &&
        allBudgets.any(
          (b) =>
              !b.deleted &&
              b.id != budget.id &&
              b.ownerId == budget.ownerId &&
              b.category == budget.category &&
              b.month == budget.month,
        )) {
      throw const FormatException(
        'A budget already exists for this category. Edit its limit instead.',
      );
    }
    await _commitRecord(
      'budgets',
      budget.toJson(),
      budgets: [...allBudgets.where((e) => e.id != budget.id), budget],
    );
  });

  Future<void> saveGoal(SavingsGoal goal) => _serialize(() => _saveGoal(goal));
  Future<void> _saveGoal(SavingsGoal goal) async {
    _validateOwner(goal.ownerId);
    if (goal.targetMinor <= 0 ||
        goal.targetMinor > 999999999999 ||
        goal.savedMinor < 0 ||
        goal.savedMinor > goal.targetMinor ||
        goal.title.trim().isEmpty ||
        goal.title.length > 80) {
      throw const FormatException(
        'Use a goal name, positive target and a saved amount between zero and the target.',
      );
    }
    await _commitRecord(
      'savings_goals',
      goal.toJson(),
      goals: [...allGoals.where((e) => e.id != goal.id), goal],
    );
  }

  Future<void> addSavings(
    String goalId,
    int amountMinor,
  ) => _serialize(() async {
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
    await _saveGoal(
      SavingsGoal(
        id: goal.id,
        ownerId: goal.ownerId,
        title: goal.title,
        targetMinor: goal.targetMinor,
        savedMinor: goal.savedMinor + amountMinor,
      ),
    );
  });

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
    if (isParent || !canUseOwnData || profile == null) {
      throw const FormatException(
        'Sign in with a teen account to make changes.',
      );
    }
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
    profileChecked = false;
    syncing = false;
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
    if (client != null) {
      throw StateError(
        'Sample profiles are unavailable in authenticated mode.',
      );
    }
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
    _disposed = true;
    _auth?.cancel();
    _connection?.cancel();
    _poll?.cancel();
    _familyChannel?.unsubscribe();
    super.dispose();
  }
}
