import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:bachat_mobile/domain/models.dart';
import 'package:bachat_mobile/domain/activity_filter.dart';
import 'package:bachat_mobile/application/controller.dart';
import 'package:bachat_mobile/data/repository.dart';

MoneyEntry entry(
  String id,
  DateTime date, {
  int amount = 100,
  String category = 'Food & dining',
  EntryDirection direction = EntryDirection.expense,
  bool deleted = false,
}) => MoneyEntry(
  id: id,
  ownerId: 'preview-teen',
  merchant: id,
  amountMinor: amount,
  direction: direction,
  category: category,
  occurredAt: date,
  note: 'School lunch',
  deleted: deleted,
);

void main() {
  test('month filters respect year boundaries and exclude deleted records', () {
    final rows = [
      entry('december', DateTime(2025, 12, 31, 23, 59)),
      entry('january', DateTime(2026, 1, 1)),
      entry('deleted', DateTime(2025, 12, 1), deleted: true),
    ];
    expect(
      const ActivityFilter(
        period: ActivityPeriod.lastMonth,
      ).apply(rows, now: DateTime(2026, 1, 10)).map((e) => e.id),
      ['december'],
    );
    expect(
      const ActivityFilter(
        period: ActivityPeriod.thisMonth,
      ).apply(rows, now: DateTime(2026, 1, 10)).map((e) => e.id),
      ['january'],
    );
  });
  test(
    'custom range includes the entire end date and rejects invalid ranges',
    () {
      final rows = [
        entry('start', DateTime(2025, 12, 31)),
        entry('end', DateTime(2026, 1, 1, 23, 59, 59, 999)),
        entry('outside', DateTime(2026, 1, 2)),
      ];
      final filter = ActivityFilter(
        period: ActivityPeriod.custom,
        from: DateTime(2025, 12, 31),
        through: DateTime(2026, 1, 1),
      );
      expect(filter.apply(rows).map((e) => e.id), ['end', 'start']);
      expect(
        () => const ActivityFilter(period: ActivityPeriod.custom).apply(rows),
        throwsFormatException,
      );
      expect(
        () => ActivityFilter(
          period: ActivityPeriod.custom,
          from: DateTime(2026, 2, 1),
          through: DateTime(2026, 1, 1),
        ).apply(rows),
        throwsFormatException,
      );
    },
  );
  test(
    'search category direction and amount sorting compose deterministically',
    () {
      final now = DateTime.now();
      final rows = [
        entry('b', now, amount: 300),
        entry('a', now, amount: 300),
        entry('income', now, direction: EntryDirection.income),
        entry('ride', now, category: 'Transport'),
        entry('small', now, amount: 10),
      ];
      const filter = ActivityFilter(
        category: 'Food & dining',
        order: ActivityOrder.highest,
      );
      expect(
        filter
            .apply(rows, text: ' SCHOOL ', direction: EntryDirection.expense)
            .map((e) => e.id),
        ['a', 'b', 'small'],
      );
      expect(
        const ActivityFilter(order: ActivityOrder.lowest).apply(rows).first.id,
        'small',
      );
      expect(filter.groupsByDate, isFalse);
      expect(filter.activeCount, 2);
    },
  );
  Future<AppController> controller(String name) async {
    final db = await databaseFactoryMemory.openDatabase(name);
    addTearDown(db.close);
    final c = AppController(BachatRepository(db, null));
    addTearDown(c.dispose);
    await c.startDemo(UserRole.teen);
    return c;
  }

  test(
    'adding savings preserves transactions and survives restart and parent switching',
    () async {
      final c = await controller('savings-persistence');
      final transactions = c.allEntries.map((e) => e.toJson()).toList();
      await c.addSavings(c.goals.single.id, 12550);
      expect(c.goals.single.savedMinor, 447550);
      expect(c.allEntries.map((e) => e.toJson()).toList(), transactions);
      final restored = AppController(c.repository);
      addTearDown(restored.dispose);
      await restored.initialize();
      expect(restored.goals.single.savedMinor, 447550);
      await restored.startDemo(UserRole.parent);
      expect(restored.goals.single.savedMinor, 447550);
      await expectLater(
        restored.addSavings(restored.goals.single.id, 100),
        throwsFormatException,
      );
    },
  );
  test(
    'savings reject zero over-target missing goals and completed targets',
    () async {
      final c = await controller('savings-limits');
      final id = c.goals.single.id;
      for (final amount in [0, -100, 765001]) {
        await expectLater(c.addSavings(id, amount), throwsFormatException);
      }
      await expectLater(c.addSavings('missing', 100), throwsFormatException);
      expect(c.goals.single.savedMinor, 435000);
      await c.addSavings(id, 765000);
      expect(c.goals.single.progress, 1);
      await expectLater(c.addSavings(id, 1), throwsFormatException);
      expect(c.goals.single.savedMinor, 1200000);
    },
  );
  test(
    'budget reuse only copies missing categories and is safe to repeat',
    () async {
      final c = await controller('budget-reuse');
      final now = DateTime.now();
      final previous = monthKey(DateTime(now.year, now.month - 1));
      c.allBudgets.addAll([
        CategoryBudget(
          id: 'old-food',
          ownerId: 'preview-teen',
          category: 'Food & dining',
          limitMinor: 99900,
          month: previous,
        ),
        CategoryBudget(
          id: 'old-transport',
          ownerId: 'preview-teen',
          category: 'Transport',
          limitMinor: 50000,
          month: previous,
        ),
        CategoryBudget(
          id: 'old-deleted',
          ownerId: 'preview-teen',
          category: 'Education',
          limitMinor: 10000,
          month: previous,
          deleted: true,
        ),
        CategoryBudget(
          id: 'older',
          ownerId: 'preview-teen',
          category: 'Shopping',
          limitMinor: 10000,
          month: monthKey(DateTime(now.year, now.month - 2)),
        ),
      ]);
      expect(c.reusableBudgets.single.category, 'Transport');
      expect(await c.reusePreviousBudgets(), 1);
      expect(await c.reusePreviousBudgets(), 0);
      expect(c.budgets.length, 2);
      expect(
        c.budgets.singleWhere((b) => b.category == 'Food & dining').limitMinor,
        400000,
      );
      expect(
        c.budgets.singleWhere((b) => b.category == 'Transport').limitMinor,
        50000,
      );
      await c.startDemo(UserRole.parent);
      await expectLater(c.reusePreviousBudgets(), throwsFormatException);
    },
  );
  test(
    'invalid goal totals and budget limits are rejected by the controller',
    () async {
      final c = await controller('financial-validation');
      await expectLater(
        c.saveGoal(
          const SavingsGoal(
            id: 'bad',
            ownerId: 'preview-teen',
            title: 'Bad goal',
            targetMinor: 100,
            savedMinor: 101,
          ),
        ),
        throwsFormatException,
      );
      await expectLater(
        c.saveBudget(
          CategoryBudget(
            id: 'bad',
            ownerId: 'preview-teen',
            category: 'Food & dining',
            limitMinor: 0,
            month: monthKey(DateTime.now()),
          ),
        ),
        throwsFormatException,
      );
      expect(c.goals.length, 1);
      expect(c.budgets.length, 1);
    },
  );
}
