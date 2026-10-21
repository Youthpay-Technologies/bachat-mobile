import 'package:flutter_test/flutter_test.dart';
import 'package:bachat_mobile/domain/models.dart';
import 'package:bachat_mobile/domain/activity_filter.dart';

void main() {
  MoneyEntry entry({
    String tag = '',
    EntryDirection direction = EntryDirection.expense,
  }) => MoneyEntry(
    id: 'entry',
    ownerId: 'teen',
    merchant: 'Test',
    amountMinor: 12550,
    direction: direction,
    category: 'Other',
    customCategory: tag,
    occurredAt: DateTime(2026, 10, 21),
  );
  test('Other preserves user tags across serialization and search', () {
    final tagged = normalizeEntry(entry(tag: '  Cricket  '));
    expect(tagged.category, 'Other');
    expect(tagged.categoryLabel, 'Cricket');
    expect(MoneyEntry.fromJson(tagged.toJson()).customCategory, 'Cricket');
    expect(const ActivityFilter().apply([tagged], text: 'cricket'), [tagged]);
    expect(
      MoneyEntry.fromJson(
        {...tagged.toJson()}..remove('custom_category'),
      ).customCategory,
      '',
    );
  });
  test('Savings is normalized once and stays out of expense totals', () {
    final saved = normalizeEntry(entry(tag: '  SaViNgS '));
    expect(saved.direction, EntryDirection.savings);
    expect(saved.category, 'Savings');
    expect(normalizeEntry(saved).toJson(), saved.toJson());
    final summary = MoneySummary([saved], DateTime(2026, 10));
    expect(summary.savedMinor, 12550);
    expect(summary.spentMinor, 0);
    expect(summary.incomeMinor, 0);
    expect(summary.byCategory, isEmpty);
    final removed = MoneyEntry.fromJson({...saved.toJson(), 'deleted': true});
    expect(MoneySummary([removed], DateTime(2026, 10)).savedMinor, 0);
  });
  test('Receive has its own categories and never silently becomes savings', () {
    expect(
      categoriesFor(EntryDirection.income),
      containsAll(['Pocket money', 'Gift', 'Refund']),
    );
    expect(
      categoriesFor(EntryDirection.income),
      isNot(contains('Food & dining')),
    );
    expect(categoriesFor(EntryDirection.expense), isNot(contains('Salary')));
    final received = normalizeEntry(
      entry(tag: 'savings', direction: EntryDirection.income),
    );
    expect(received.direction, EntryDirection.income);
    expect(received.customCategory, 'savings');
  });
}
