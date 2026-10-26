import 'package:intl/intl.dart';

enum UserRole { teen, parent }

enum EntryDirection { expense, income, savings }

const categories = [
  'Food & dining',
  'Transport',
  'Shopping',
  'Entertainment',
  'Education',
  'Health',
  'Utilities',
  'Transfer',
  'Other',
];

const incomeCategories = [
  'Pocket money',
  'Gift',
  'Salary',
  'Freelance',
  'Refund',
  'Transfer',
  'Other',
];
const spendCategories = [...categories, 'Savings'];
final transactionCategories = {...spendCategories, ...incomeCategories};
List<String> categoriesFor(EntryDirection direction) => switch (direction) {
  EntryDirection.expense => spendCategories,
  EntryDirection.income => incomeCategories,
  EntryDirection.savings => const ['Savings'],
};

int parseMoney(String input) {
  final clean = input.trim().replaceAll(',', '');
  if (!RegExp(r'^\d{1,10}(\.\d{1,2})?$').hasMatch(clean)) {
    throw const FormatException(
      'Enter an amount with up to two decimal places.',
    );
  }
  final parts = clean.split('.');
  final amount =
      int.parse(parts.first) * 100 +
      (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
  if (amount <= 0) {
    throw const FormatException('Enter an amount greater than zero.');
  }
  return amount;
}

String money(int minor, {bool decimals = false}) =>
    'Rs ${NumberFormat(decimals || minor % 100 != 0 ? '#,##0.00' : '#,##0', 'en_PK').format(minor / 100)}';
String monthKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-01';

class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.role,
    this.age,
  });
  final String id;
  final String name;
  final UserRole role;
  final int? age;
  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    name: json['name'] as String,
    role: UserRole.values.byName(json['role'] as String),
    age: json['age'] as int?,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role.name,
    'age': age,
  };
}

class MoneyEntry {
  const MoneyEntry({
    required this.id,
    required this.ownerId,
    required this.merchant,
    required this.amountMinor,
    required this.direction,
    required this.category,
    required this.occurredAt,
    this.note = '',
    this.customCategory = '',
    this.deleted = false,
  });
  final String id, ownerId, merchant, category, note, customCategory;
  String get categoryLabel =>
      customCategory.isEmpty ? category : customCategory;
  final int amountMinor;
  final EntryDirection direction;
  final DateTime occurredAt;
  final bool deleted;
  factory MoneyEntry.fromJson(Map<String, dynamic> j) => MoneyEntry(
    id: j['id'] as String,
    ownerId: j['owner_id'] as String,
    merchant: j['merchant'] as String,
    amountMinor: (j['amount_minor'] as num).toInt(),
    direction: EntryDirection.values.byName(j['direction'] as String),
    category: j['category'] as String,
    occurredAt: DateTime.parse(j['occurred_at'] as String).toLocal(),
    note: j['note'] as String? ?? '',
    customCategory: j['custom_category'] as String? ?? '',
    deleted: j['deleted'] as bool? ?? false,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'owner_id': ownerId,
    'merchant': merchant,
    'amount_minor': amountMinor,
    'direction': direction.name,
    'category': category,
    'occurred_at': occurredAt.toUtc().toIso8601String(),
    'note': note,
    'custom_category': customCategory,
    'deleted': deleted,
  };
}

MoneyEntry normalizeEntry(MoneyEntry entry) {
  final tag = entry.customCategory.trim();
  final savings =
      entry.direction != EntryDirection.income &&
      (entry.category == 'Savings' ||
          (entry.category == 'Other' && tag.toLowerCase() == 'savings'));
  return MoneyEntry.fromJson({
    ...entry.toJson(),
    'direction': savings ? 'savings' : entry.direction.name,
    'category': savings ? 'Savings' : entry.category,
    'custom_category': !savings && entry.category == 'Other' ? tag : '',
  });
}

class CategoryBudget {
  const CategoryBudget({
    required this.id,
    required this.ownerId,
    required this.category,
    required this.limitMinor,
    required this.month,
    this.deleted = false,
  });
  final String id, ownerId, category, month;
  final int limitMinor;
  final bool deleted;
  factory CategoryBudget.fromJson(Map<String, dynamic> j) => CategoryBudget(
    id: j['id'] as String,
    ownerId: j['owner_id'] as String,
    category: j['category'] as String,
    limitMinor: (j['limit_minor'] as num).toInt(),
    month: j['month'] as String,
    deleted: j['deleted'] as bool? ?? false,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'owner_id': ownerId,
    'category': category,
    'limit_minor': limitMinor,
    'month': month,
    'deleted': deleted,
  };
}

class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.targetMinor,
    this.savedMinor = 0,
    this.deleted = false,
  });
  final String id, ownerId, title;
  final int targetMinor, savedMinor;
  final bool deleted;
  double get progress => (savedMinor / targetMinor).clamp(0, 1).toDouble();
  factory SavingsGoal.fromJson(Map<String, dynamic> j) => SavingsGoal(
    id: j['id'] as String,
    ownerId: j['owner_id'] as String,
    title: j['title'] as String,
    targetMinor: (j['target_minor'] as num).toInt(),
    savedMinor: (j['saved_minor'] as num).toInt(),
    deleted: j['deleted'] as bool? ?? false,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'owner_id': ownerId,
    'title': title,
    'target_minor': targetMinor,
    'saved_minor': savedMinor,
    'deleted': deleted,
  };
}

class FamilyLink {
  const FamilyLink({
    required this.id,
    required this.teenId,
    required this.status,
    this.parentId,
    this.teenName = '',
    this.parentName = '',
    this.expiresAt,
  });
  final String id, teenId, status, teenName, parentName;
  final String? parentId;
  final DateTime? expiresAt;
  bool get approved => status == 'approved';
  factory FamilyLink.fromJson(Map<String, dynamic> j) => FamilyLink(
    id: j['id'] as String,
    teenId: j['teen_id'] as String,
    status: j['status'] as String,
    parentId: j['parent_id'] as String?,
    teenName: j['teen_name'] as String? ?? '',
    parentName: j['parent_name'] as String? ?? '',
    expiresAt: j['expires_at'] == null
        ? null
        : DateTime.parse(j['expires_at'] as String),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'teen_id': teenId,
    'parent_id': parentId,
    'status': status,
    'teen_name': teenName,
    'parent_name': parentName,
    'expires_at': expiresAt?.toIso8601String(),
  };
}

class MoneySummary {
  MoneySummary(List<MoneyEntry> entries, DateTime month) {
    for (final e in entries.where(
      (e) =>
          !e.deleted &&
          e.occurredAt.year == month.year &&
          e.occurredAt.month == month.month,
    )) {
      if (e.direction == EntryDirection.income) {
        incomeMinor += e.amountMinor;
      } else if (e.direction == EntryDirection.savings) {
        savedMinor += e.amountMinor;
      } else {
        spentMinor += e.amountMinor;
        byCategory.update(
          e.category,
          (v) => v + e.amountMinor,
          ifAbsent: () => e.amountMinor,
        );
      }
    }
  }
  int incomeMinor = 0, spentMinor = 0, savedMinor = 0;
  final Map<String, int> byCategory = {};
}

/// A user-entered cash checkpoint, independent of budgets and monthly totals.
class CashBalance {
  const CashBalance({
    required this.ownerId,
    required this.amountMinor,
    required this.ledgerNetMinor,
  });
  final String ownerId;
  final int amountMinor, ledgerNetMinor;
  factory CashBalance.fromJson(Map<String, dynamic> json) => CashBalance(
    ownerId: json['owner_id'] as String,
    amountMinor: (json['amount_minor'] as num).toInt(),
    ledgerNetMinor: (json['ledger_net_minor'] as num).toInt(),
  );
  Map<String, dynamic> toJson() => {
    'id': ownerId,
    'owner_id': ownerId,
    'amount_minor': amountMinor,
    'ledger_net_minor': ledgerNetMinor,
  };
  int availableMinor(int currentLedgerNetMinor) =>
      amountMinor + currentLedgerNetMinor - ledgerNetMinor;
}

/// Recorded money received less expenses and both forms of recorded savings.
int spendingLedgerNet(List<MoneyEntry> entries, List<SavingsGoal> goals) =>
    entries
        .where((e) => !e.deleted)
        .fold<int>(
          0,
          (sum, e) =>
              sum +
              (e.direction == EntryDirection.income
                  ? e.amountMinor
                  : -e.amountMinor),
        ) -
    goals.where((g) => !g.deleted).fold<int>(0, (sum, g) => sum + g.savedMinor);

int parseAvailableMoney(String input) {
  final clean = input.trim().replaceAll(',', '');
  if (RegExp(r'^0+(\.0{1,2})?$').hasMatch(clean)) return 0;
  return parseMoney(input);
}

/// A real time axis: at least 24 hours, expanding with current-month activity.
class SpendingTimeline {
  SpendingTimeline(List<MoneyEntry> entries, DateTime now) {
    final expenses =
        entries
            .where(
              (e) =>
                  !e.deleted &&
                  e.direction == EntryDirection.expense &&
                  e.occurredAt.toLocal().year == now.year &&
                  e.occurredAt.toLocal().month == now.month &&
                  !e.occurredAt.isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    final minimumStart = now.subtract(const Duration(hours: 24));
    final first = expenses.firstOrNull?.occurredAt.toLocal();
    start = first != null && first.isBefore(minimumStart)
        ? first
        : minimumStart;
    end = now;
    hasExpenses = expenses.isNotEmpty;
    points.add(SpendingPoint(start, 0));
    var total = 0;
    for (final expense in expenses) {
      total += expense.amountMinor;
      points.add(SpendingPoint(expense.occurredAt.toLocal(), total));
    }
    if (points.last.at != end) points.add(SpendingPoint(end, total));
  }
  late final DateTime start, end;
  late final bool hasExpenses;
  final points = <SpendingPoint>[];
  bool get isHourly => end.difference(start) <= const Duration(hours: 24);
  List<DateTime> tickTimes(int count) => List.generate(
    count,
    (index) => start.add(
      Duration(
        microseconds:
            (end.difference(start).inMicroseconds * index / (count - 1))
                .round(),
      ),
    ),
  );
}

class SpendingPoint {
  const SpendingPoint(this.at, this.totalMinor);
  final DateTime at;
  final int totalMinor;
}
