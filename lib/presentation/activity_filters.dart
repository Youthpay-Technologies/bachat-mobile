import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/activity_filter.dart';
import '../domain/models.dart';
import 'forms.dart';

Future<ActivityFilter?> activityFilterSheet(
  BuildContext context,
  ActivityFilter current,
) => showModalBottomSheet<ActivityFilter>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  showDragHandle: true,
  sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
      ? AnimationStyle.noAnimation
      : null,
  builder: (_) => ActivityFilterSheet(current),
);

class ActivityFilterSheet extends StatefulWidget {
  const ActivityFilterSheet(this.initial, {super.key});
  final ActivityFilter initial;
  @override
  State<ActivityFilterSheet> createState() => _ActivityFilterSheetState();
}

class _ActivityFilterSheetState extends State<ActivityFilterSheet> {
  late ActivityPeriod period;
  late ActivityOrder order;
  String? category;
  DateTimeRange? dates;
  String? error;
  @override
  void initState() {
    super.initState();
    period = widget.initial.period;
    order = widget.initial.order;
    category = widget.initial.category;
    if (widget.initial.from != null && widget.initial.through != null) {
      dates = DateTimeRange(
        start: widget.initial.from!,
        end: widget.initial.through!,
      );
    }
  }

  @override
  Widget build(BuildContext context) => SheetBody(
    children: [
      Text(
        'Filter activity',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 28),
      DropdownButtonFormField<ActivityPeriod>(
        initialValue: period,
        isExpanded: true,
        itemHeight: null,
        decoration: const InputDecoration(labelText: 'Period'),
        items: const [
          DropdownMenuItem(value: ActivityPeriod.all, child: Text('All time')),
          DropdownMenuItem(
            value: ActivityPeriod.thisMonth,
            child: Text('This month'),
          ),
          DropdownMenuItem(
            value: ActivityPeriod.lastMonth,
            child: Text('Last month'),
          ),
          DropdownMenuItem(
            value: ActivityPeriod.custom,
            child: Text('Choose dates'),
          ),
        ],
        onChanged: (value) => setState(() {
          period = value!;
          error = null;
        }),
      ),
      if (period == ActivityPeriod.custom) ...[
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.date_range_outlined),
          label: Text(
            dates == null
                ? 'Choose date range'
                : '${DateFormat.yMMMd().format(dates!.start)} – ${DateFormat.yMMMd().format(dates!.end)}',
          ),
          onPressed: () async {
            final selected = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
              initialDateRange: dates,
            );
            if (selected != null && mounted) {
              setState(() {
                dates = selected;
                error = null;
              });
            }
          },
        ),
      ],
      const SizedBox(height: 20),
      DropdownButtonFormField<String>(
        initialValue: category ?? 'all',
        isExpanded: true,
        itemHeight: null,
        decoration: const InputDecoration(labelText: 'Category'),
        items: [
          const DropdownMenuItem(value: 'all', child: Text('All categories')),
          ...categories.map(
            (value) => DropdownMenuItem(value: value, child: Text(value)),
          ),
        ],
        onChanged: (value) =>
            setState(() => category = value == 'all' ? null : value),
      ),
      const SizedBox(height: 20),
      DropdownButtonFormField<ActivityOrder>(
        initialValue: order,
        isExpanded: true,
        itemHeight: null,
        decoration: const InputDecoration(labelText: 'Sort by'),
        items: const [
          DropdownMenuItem(
            value: ActivityOrder.newest,
            child: Text('Newest first'),
          ),
          DropdownMenuItem(
            value: ActivityOrder.oldest,
            child: Text('Oldest first'),
          ),
          DropdownMenuItem(
            value: ActivityOrder.highest,
            child: Text('Amount: high to low'),
          ),
          DropdownMenuItem(
            value: ActivityOrder.lowest,
            child: Text('Amount: low to high'),
          ),
        ],
        onChanged: (value) => setState(() => order = value!),
      ),
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Semantics(
            liveRegion: true,
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      const SizedBox(height: 28),
      FilledButton(
        onPressed: () {
          if (period == ActivityPeriod.custom && dates == null) {
            setState(() => error = 'Choose a date range.');
            return;
          }
          Navigator.pop(
            context,
            ActivityFilter(
              period: period,
              category: category,
              order: order,
              from: dates?.start,
              through: dates?.end,
            ),
          );
        },
        child: const Text('Apply filters'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, const ActivityFilter()),
        child: const Text('Reset filters'),
      ),
    ],
  );
}
