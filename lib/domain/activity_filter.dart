import 'models.dart';

enum ActivityPeriod { all, thisMonth, lastMonth, custom }

enum ActivityOrder { newest, oldest, highest, lowest }

class ActivityFilter {
  const ActivityFilter({
    this.period = ActivityPeriod.all,
    this.category,
    this.order = ActivityOrder.newest,
    this.from,
    this.through,
  });
  final ActivityPeriod period;
  final String? category;
  final ActivityOrder order;
  final DateTime? from, through;
  int get activeCount =>
      (period == ActivityPeriod.all ? 0 : 1) +
      (category == null ? 0 : 1) +
      (order == ActivityOrder.newest ? 0 : 1);
  bool get groupsByDate =>
      order == ActivityOrder.newest || order == ActivityOrder.oldest;

  List<MoneyEntry> apply(
    Iterable<MoneyEntry> source, {
    String text = '',
    EntryDirection? direction,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final start = switch (period) {
      ActivityPeriod.all => null,
      ActivityPeriod.thisMonth => DateTime(today.year, today.month),
      ActivityPeriod.lastMonth => DateTime(today.year, today.month - 1),
      ActivityPeriod.custom =>
        from == null ? null : DateTime(from!.year, from!.month, from!.day),
    };
    final end = switch (period) {
      ActivityPeriod.all => null,
      ActivityPeriod.thisMonth => DateTime(today.year, today.month + 1),
      ActivityPeriod.lastMonth => DateTime(today.year, today.month),
      ActivityPeriod.custom =>
        through == null
            ? null
            : DateTime(through!.year, through!.month, through!.day + 1),
    };
    final search = text.trim().toLowerCase();
    final result = source
        .where(
          (e) =>
              !e.deleted &&
              (direction == null || e.direction == direction) &&
              (category == null || e.category == category) &&
              (start == null || !e.occurredAt.isBefore(start)) &&
              (end == null || e.occurredAt.isBefore(end)) &&
              '${e.merchant} ${e.category} ${e.note}'.toLowerCase().contains(
                search,
              ),
        )
        .toList();
    result.sort((a, b) {
      final comparison = switch (order) {
        ActivityOrder.newest => b.occurredAt.compareTo(a.occurredAt),
        ActivityOrder.oldest => a.occurredAt.compareTo(b.occurredAt),
        ActivityOrder.highest => b.amountMinor.compareTo(a.amountMinor),
        ActivityOrder.lowest => a.amountMinor.compareTo(b.amountMinor),
      };
      return comparison != 0 ? comparison : a.id.compareTo(b.id);
    });
    return result;
  }
}
