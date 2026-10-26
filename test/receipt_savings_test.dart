import 'package:bachat_mobile/application/controller.dart';
import 'package:bachat_mobile/data/repository.dart';
import 'package:bachat_mobile/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  Future<AppController> setup(String name) async {
    final db = await databaseFactoryMemory.openDatabase(name);
    addTearDown(db.close);
    final c = AppController(BachatRepository(db, null));
    addTearDown(c.dispose);
    c.startPreview(UserRole.teen);
    c.allEntries.clear();
    c.allGoals.clear();
    c.allBudgets.clear();
    await c.saveGoal(
      const SavingsGoal(
        id: 'a',
        ownerId: 'preview-teen',
        title: 'A',
        targetMinor: 100000,
        savedMinor: 10000,
      ),
    );
    await c.saveGoal(
      const SavingsGoal(
        id: 'b',
        ownerId: 'preview-teen',
        title: 'B',
        targetMinor: 200000,
      ),
    );
    await c.saveBudget(
      CategoryBudget(
        id: 'budget',
        ownerId: 'preview-teen',
        category: 'Food & dining',
        limitMinor: 60000,
        month: monthKey(DateTime.now()),
      ),
    );
    await c.setAvailableMoney(50000);
    return c;
  }

  MoneyEntry receipt({
    int amount = 100000,
    int saved = 30000,
    String? goal = 'a',
    bool deleted = false,
  }) => MoneyEntry(
    id: 'receipt',
    ownerId: 'preview-teen',
    merchant: 'Gift',
    amountMinor: amount,
    direction: EntryDirection.income,
    category: 'Gift',
    occurredAt: DateTime.now(),
    savingsGoalId: goal,
    savingsAmountMinor: saved,
    deleted: deleted,
  );
  MoneyEntry expense({bool deleted = false}) => MoneyEntry(
    id: 'expense',
    ownerId: 'preview-teen',
    merchant: 'Lunch',
    amountMinor: 20000,
    direction: EntryDirection.expense,
    category: 'Food & dining',
    occurredAt: DateTime.now(),
    deleted: deleted,
  );

  test(
    'receive, allocate, spend, save, edit, move and delete stay reconciled',
    () async {
      final c = await setup('receipt-lifecycle');
      await c.saveEntry(receipt());
      expect(c.availableMinor, 120000);
      expect(c.goals.first.totalSavedMinor, 40000);
      expect(c.goals.first.savedMinor, 10000);
      expect(c.totalSetAsideMinor, 40000);
      expect(MoneySummary(c.entries, DateTime.now()).spentMinor, 0);
      await c.saveEntry(expense());
      expect(c.availableMinor, 100000);
      expect(
        MoneySummary(c.entries, DateTime.now()).byCategory['Food & dining'],
        20000,
      );
      expect(c.budgets.single.limitMinor, 60000);
      await c.addSavings('a', 5000);
      expect(c.availableMinor, 95000);
      await c.saveEntry(
        MoneyEntry(
          id: 'standalone',
          ownerId: 'preview-teen',
          merchant: 'Cash saved',
          amountMinor: 10000,
          direction: EntryDirection.savings,
          category: 'Savings',
          occurredAt: DateTime.now(),
        ),
      );
      expect(c.availableMinor, 85000);
      expect(c.totalSetAsideMinor, 55000);
      await c.saveEntry(receipt(saved: 50000));
      expect(c.availableMinor, 65000);
      expect(c.goals.first.totalSavedMinor, 65000);
      await c.saveEntry(receipt(saved: 50000, goal: 'b'));
      expect(c.availableMinor, 65000);
      expect(c.goals.first.totalSavedMinor, 15000);
      expect(c.goals.last.totalSavedMinor, 50000);
      await c.saveEntry(receipt(amount: 120000, saved: 40000, goal: 'b'));
      expect(c.availableMinor, 95000);
      expect(c.goals.last.totalSavedMinor, 40000);
      final summary = MoneySummary(c.entries, DateTime.now());
      expect(summary.incomeMinor, 120000);
      expect(summary.savedMinor, 50000);
      expect(summary.spentMinor, 20000);
      await c.saveEntry(
        receipt(amount: 120000, saved: 40000, goal: 'b', deleted: true),
      );
      expect(c.availableMinor, 15000);
      expect(c.goals.last.totalSavedMinor, 0);
      expect(c.goals.first.totalSavedMinor, 15000);
      await c.saveEntry(expense(deleted: true));
      expect(c.availableMinor, 35000);
      expect(MoneySummary(c.entries, DateTime.now()).byCategory, isEmpty);
    },
  );

  test(
    'invalid allocation and goal edits fail without altering balances',
    () async {
      final c = await setup('receipt-validation');
      for (final bad in [
        receipt(saved: 100001),
        receipt(saved: -1),
        receipt(saved: 1, goal: null),
        receipt(saved: 0),
        receipt(goal: 'missing'),
      ]) {
        await expectLater(c.saveEntry(bad), throwsFormatException);
        expect(c.availableMinor, 50000);
        expect(c.entries, isEmpty);
      }
      await c.saveEntry(receipt(saved: 90000));
      expect(c.goals.first.progress, 1);
      await expectLater(c.addSavings('a', 1), throwsFormatException);
      await expectLater(
        c.saveGoal(
          const SavingsGoal(
            id: 'a',
            ownerId: 'preview-teen',
            title: 'A',
            targetMinor: 99999,
            savedMinor: 10000,
          ),
        ),
        throwsFormatException,
      );
      await expectLater(
        c.saveGoal(
          const SavingsGoal(
            id: 'a',
            ownerId: 'preview-teen',
            title: 'A',
            targetMinor: 100000,
            savedMinor: 10000,
            deleted: true,
          ),
        ),
        throwsFormatException,
      );
      expect(c.goals.first.totalSavedMinor, 100000);
      await c.saveEntry(receipt(saved: 0, goal: null));
      expect(c.availableMinor, 150000);
      await c.saveGoal(
        const SavingsGoal(
          id: 'a',
          ownerId: 'preview-teen',
          title: 'A',
          targetMinor: 100000,
          savedMinor: 10000,
          deleted: true,
        ),
      );
      expect(c.goals.any((g) => g.id == 'a'), isFalse);
    },
  );

  test(
    'receipt allocations survive restart and reconciliation without duplicate goal credit',
    () async {
      final c = await setup('receipt-restore');
      await c.saveEntry(receipt());
      final restored = AppController(c.repository);
      addTearDown(restored.dispose);
      await restored.startDemo(UserRole.teen);
      expect(restored.availableMinor, 120000);
      expect(restored.goals.first.totalSavedMinor, 40000);
      expect(restored.goals.first.savedMinor, 10000);
      await restored.setAvailableMoney(60000);
      expect(restored.availableMinor, 60000);
      await restored.saveEntry(receipt(saved: 40000));
      expect(restored.availableMinor, 50000);
      expect(restored.goals.first.totalSavedMinor, 50000);
      expect(
        restored.entries
            .where((e) => e.direction == EntryDirection.income)
            .length,
        1,
      );
    },
  );
}
