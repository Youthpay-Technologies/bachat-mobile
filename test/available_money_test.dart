import 'package:bachat_mobile/application/controller.dart';
import 'package:bachat_mobile/data/repository.dart';
import 'package:bachat_mobile/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  test(
    'spending timeline adapts to first activity, one day, gaps and removed entries',
    () {
      final now = DateTime(2026, 10, 26);
      MoneyEntry expense(
        String id,
        int day,
        int amount, {
        bool deleted = false,
      }) => MoneyEntry(
        id: id,
        ownerId: 'teen',
        merchant: 'Lunch',
        amountMinor: amount,
        direction: EntryDirection.expense,
        category: 'Food & dining',
        occurredAt: DateTime(2026, 10, day),
        deleted: deleted,
      );
      final empty = SpendingTimeline([], now);
      expect(empty.hasExpenses, isFalse);
      expect(empty.dailyTotals, [0]);
      final firstDay = SpendingTimeline([expense('today', 26, 12500)], now);
      expect(firstDay.start, now);
      expect(firstDay.dailyTotals, [12500]);
      final active = SpendingTimeline([
        expense('first', 24, 10000),
        expense('last', 26, 12500),
        expense('deleted', 1, 99900, deleted: true),
      ], now);
      expect(active.start, DateTime(2026, 10, 24));
      expect(active.dailyTotals, [10000, 10000, 22500]);
      expect(
        SpendingTimeline([
          expense('first', 1, 10),
          expense('last', 26, 20),
        ], now).dailyTotals.length,
        26,
      );
    },
  );

  test(
    'available money accepts zero and exact paisa but rejects invalid amounts',
    () {
      expect(parseAvailableMoney('0'), 0);
      expect(parseAvailableMoney('0.00'), 0);
      expect(parseAvailableMoney('1,234.56'), 123456);
      for (final invalid in ['', '-1', '1.234', '0.000', 'money']) {
        expect(() => parseAvailableMoney(invalid), throwsFormatException);
      }
    },
  );

  test(
    'checkpoint avoids deducting old entries twice and follows edits, income and savings',
    () async {
      final db = await databaseFactoryMemory.openDatabase('available-money');
      addTearDown(db.close);
      final repo = BachatRepository(db, null);
      final c = AppController(repo);
      addTearDown(c.dispose);
      await c.startDemo(UserRole.teen);
      final historicalCount = c.entries.length;
      await c.setAvailableMoney(100000);
      expect(c.availableMinor, 100000);
      expect(c.entries.length, historicalCount);
      MoneyEntry expense(int amount, {bool deleted = false}) => MoneyEntry(
        id: 'new-expense',
        ownerId: 'preview-teen',
        merchant: 'Lunch',
        amountMinor: amount,
        direction: EntryDirection.expense,
        category: 'Food & dining',
        occurredAt: DateTime.now(),
        deleted: deleted,
      );
      await c.saveEntry(expense(12500));
      expect(c.availableMinor, 87500);
      await c.addSavings(c.goals.first.id, 10000);
      expect(c.availableMinor, 77500);
      await c.saveEntry(
        MoneyEntry(
          id: 'new-income',
          ownerId: 'preview-teen',
          merchant: 'Gift',
          amountMinor: 5000,
          direction: EntryDirection.income,
          category: 'Gift',
          occurredAt: DateTime.now(),
        ),
      );
      expect(c.availableMinor, 82500);
      await c.saveEntry(expense(20000));
      expect(c.availableMinor, 75000);
      await c.saveEntry(expense(20000, deleted: true));
      expect(c.availableMinor, 95000);
      final restored = AppController(repo);
      addTearDown(restored.dispose);
      await restored.startDemo(UserRole.teen);
      expect(restored.availableMinor, 95000);
      await restored.setAvailableMoney(50000);
      expect(restored.availableMinor, 50000);
      expect(restored.entries.length, c.entries.length);
      await restored.setAvailableMoney(0);
      expect(restored.availableMinor, 0);
      await restored.saveEntry(expense(50));
      expect(restored.availableMinor, -50);
      await restored.startDemo(UserRole.parent);
      await expectLater(restored.setAvailableMoney(100), throwsFormatException);
    },
  );

  test('savings entries reduce money while budgets never reserve cash', () {
    final now = DateTime.now();
    final entry = MoneyEntry(
      id: 'saved',
      ownerId: 'teen',
      merchant: 'Set aside',
      amountMinor: 5000,
      direction: EntryDirection.savings,
      category: 'Savings',
      occurredAt: now,
    );
    const checkpoint = CashBalance(
      ownerId: 'teen',
      amountMinor: 10000,
      ledgerNetMinor: 0,
    );
    expect(checkpoint.availableMinor(spendingLedgerNet([entry], [])), 5000);
    expect(CashBalance.fromJson(checkpoint.toJson()).amountMinor, 10000);
  });
}
