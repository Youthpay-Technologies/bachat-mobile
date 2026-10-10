import 'package:flutter_test/flutter_test.dart';
import 'package:bachat_mobile/domain/models.dart';

void main() {
  test('money parsing uses exact paisa and rejects ambiguous values', () {
    expect(parseMoney('1,250.05'), 125005);
    expect(parseMoney('0.01'), 1);
    expect(parseMoney('17.5'), 1750);
    for (final input in ['0', '-5', '1.234', 'NaN', '1e3', '']) {
      expect(() => parseMoney(input), throwsFormatException, reason: input);
    }
  });
  test('monthly summary excludes deleted and other-month entries', () {
    MoneyEntry entry(
      String id,
      int amount,
      EntryDirection direction,
      DateTime date, {
      bool deleted = false,
    }) => MoneyEntry(
      id: id,
      ownerId: 'teen',
      merchant: 'Lunch',
      amountMinor: amount,
      direction: direction,
      category: 'Food & dining',
      occurredAt: date,
      deleted: deleted,
    );
    final summary = MoneySummary([
      entry('a', 15005, EntryDirection.expense, DateTime(2026, 10, 3)),
      entry('b', 25000, EntryDirection.income, DateTime(2026, 10, 4)),
      entry('c', 40000, EntryDirection.expense, DateTime(2026, 9, 4)),
      entry(
        'd',
        80000,
        EntryDirection.expense,
        DateTime(2026, 10, 4),
        deleted: true,
      ),
    ], DateTime(2026, 10));
    expect(summary.spentMinor, 15005);
    expect(summary.incomeMinor, 25000);
    expect(summary.byCategory, {'Food & dining': 15005});
  });
  test('transaction serialization preserves exact amount and direction', () {
    final original = MoneyEntry(
      id: 'a',
      ownerId: 'teen',
      merchant: 'Stationery',
      amountMinor: 1045,
      direction: EntryDirection.expense,
      category: 'Education',
      occurredAt: DateTime.utc(2026, 10, 10),
    );
    final restored = MoneyEntry.fromJson(original.toJson());
    expect(restored.amountMinor, 1045);
    expect(restored.direction, EntryDirection.expense);
    expect(restored.occurredAt.toUtc(), original.occurredAt);
  });
  test('family access requires full approval', () {
    for (final status in ['pending', 'parent_approved', 'revoked']) {
      expect(
        FamilyLink(id: 'a', teenId: 'teen', status: status).approved,
        false,
      );
    }
    expect(
      const FamilyLink(id: 'a', teenId: 'teen', status: 'approved').approved,
      true,
    );
  });
  test('goal progress does not overflow the visual track', () {
    expect(
      const SavingsGoal(
        id: 'a',
        ownerId: 'teen',
        title: 'Books',
        targetMinor: 10000,
        savedMinor: 12000,
      ).progress,
      1,
    );
  });
}
