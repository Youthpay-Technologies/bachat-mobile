import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../application/controller.dart';
import '../design/components.dart';
import '../domain/models.dart';

Future<void> entryForm(
  BuildContext context,
  AppController c, {
  MoneyEntry? existing,
  EntryDirection direction = EntryDirection.expense,
}) async {
  final result = await showModalBottomSheet<String>(
    context: context,
    sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : null,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => EntryForm(c: c, existing: existing, direction: direction),
  );
  if (context.mounted && result != null) showFeedback(context, result);
}

class EntryForm extends StatefulWidget {
  const EntryForm({
    super.key,
    required this.c,
    this.existing,
    this.direction = EntryDirection.expense,
  });
  final EntryDirection direction;
  final AppController c;
  final MoneyEntry? existing;
  @override
  State<EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<EntryForm> {
  final form = GlobalKey<FormState>();
  late final TextEditingController merchant, amount, note, customCategory;
  late String category;
  late EntryDirection direction;
  late DateTime date;
  String? error;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    merchant = TextEditingController(text: e?.merchant);
    amount = TextEditingController(
      text: e == null ? '' : (e.amountMinor / 100).toStringAsFixed(2),
    );
    note = TextEditingController(text: e?.note);
    direction = e?.direction == EntryDirection.savings
        ? EntryDirection.expense
        : e?.direction ?? widget.direction;
    category = e?.category ?? categoriesFor(direction).first;
    customCategory = TextEditingController(text: e?.customCategory);
    date = e?.occurredAt ?? DateTime.now();
  }

  @override
  void dispose() {
    merchant.dispose();
    amount.dispose();
    note.dispose();
    customCategory.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readOnly = widget.c.isParent;
    return SheetBody(
      children: [
        Text(
          readOnly
              ? 'Transaction details'
              : widget.existing == null
              ? (direction == EntryDirection.income
                    ? 'Receive money'
                    : 'Spend money')
              : 'Edit transaction',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        Form(
          key: form,
          child: Column(
            children: [
              TextFormField(
                controller: amount,
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.start,
                textInputAction: TextInputAction.next,
                readOnly: readOnly,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'Rs ',
                  hintText: '0.00',
                ),
                validator: validateAmount,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: merchant,
                readOnly: readOnly,
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: direction == EntryDirection.income
                      ? 'Where did it come from?'
                      : 'Where or what was it?',
                ),
                validator: requiredText,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                isExpanded: true,
                itemHeight: null,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categoriesFor(direction)
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: readOnly
                    ? null
                    : (v) => setState(() => category = v!),
              ),
              if (category == 'Other') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: customCategory,
                  readOnly: readOnly,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Category name'),
                  validator: requiredText,
                  onChanged: (_) => setState(() {}),
                ),
              ],
              if (direction != EntryDirection.income &&
                  (category == 'Savings' ||
                      (category == 'Other' &&
                          customCategory.text.trim().toLowerCase() ==
                              'savings')))
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Added to savings, outside your spending totals.',
                  ),
                ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(DateFormat.yMMMd().format(date)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: readOnly
                    ? null
                    : () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (selected != null) setState(() => date = selected);
                      },
              ),
              TextFormField(
                controller: note,
                readOnly: readOnly,
                maxLength: 500,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
            ],
          ),
        ),
        if (error != null)
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: 16),
        if (!readOnly)
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    if (saving || !form.currentState!.validate()) return;
                    setState(() => saving = true);
                    try {
                      await widget.c.saveEntry(
                        MoneyEntry(
                          id: widget.existing?.id ?? const Uuid().v4(),
                          ownerId: widget.c.profile!.id,
                          merchant: merchant.text.trim(),
                          amountMinor: parseMoney(amount.text),
                          direction: direction,
                          category: category,
                          occurredAt: date,
                          note: note.text.trim(),
                          customCategory: category == 'Other'
                              ? customCategory.text.trim()
                              : '',
                        ),
                      );
                      if (context.mounted) {
                        Navigator.pop(context, 'Transaction saved');
                      }
                    } catch (_) {
                      if (mounted) {
                        setState(() {
                          saving = false;
                          error =
                              'Unable to save this entry. Check the details and try again.';
                        });
                      }
                    }
                  },
            child: Text(saving ? 'Saving…' : 'Save transaction'),
          ),
        if (widget.existing != null && !readOnly)
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: saving
                ? null
                : () async {
                    if (await confirmAction(
                      context,
                      title: 'Delete transaction?',
                      body:
                          'This transaction will be removed from your totals and activity.',
                      action: 'Delete',
                      destructive: true,
                    )) {
                      try {
                        await widget.c.saveEntry(
                          MoneyEntry.fromJson({
                            ...widget.existing!.toJson(),
                            'deleted': true,
                          }),
                        );
                        if (context.mounted) {
                          Navigator.pop(context, 'Transaction deleted');
                        }
                      } catch (_) {
                        if (mounted) {
                          setState(
                            () => error = 'Unable to delete. Try again.',
                          );
                        }
                      }
                    }
                  },
            child: const Text('Delete transaction'),
          ),
        if (readOnly)
          const Text('Shared by your teen. Only they can edit this entry.'),
      ],
    );
  }
}

String? requiredText(String? value) =>
    value == null || value.trim().isEmpty ? 'Enter a name to continue.' : null;
String? validateAmount(String? value) {
  try {
    parseMoney(value ?? '');
    return null;
  } on FormatException catch (e) {
    return e.message;
  }
}

class SheetBody extends StatelessWidget {
  const SheetBody({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    padding: EdgeInsets.fromLTRB(
      MediaQuery.sizeOf(context).width < 360 ? 16 : 24,
      8,
      MediaQuery.sizeOf(context).width < 360 ? 16 : 24,
      MediaQuery.viewInsetsOf(context).bottom + 32,
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    ),
  );
}

Future<void> budgetForm(
  BuildContext context,
  AppController c, {
  CategoryBudget? existing,
}) async {
  final result = await showModalBottomSheet<String>(
    context: context,
    sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : null,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => PlanForm(c: c, budget: existing, isBudget: true),
  );
  if (context.mounted && result != null) showFeedback(context, result);
}

Future<void> goalForm(
  BuildContext context,
  AppController c, {
  SavingsGoal? existing,
}) async {
  final result = await showModalBottomSheet<String>(
    context: context,
    sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : null,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => PlanForm(c: c, goal: existing, isBudget: false),
  );
  if (context.mounted && result != null) showFeedback(context, result);
}

class PlanForm extends StatefulWidget {
  const PlanForm({
    super.key,
    required this.c,
    required this.isBudget,
    this.budget,
    this.goal,
  });
  final AppController c;
  final bool isBudget;
  final CategoryBudget? budget;
  final SavingsGoal? goal;
  @override
  State<PlanForm> createState() => _PlanFormState();
}

class _PlanFormState extends State<PlanForm> {
  final form = GlobalKey<FormState>();
  late final TextEditingController title, amount, saved;
  late String category;
  bool saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    title = TextEditingController(text: widget.goal?.title);
    final minor = widget.isBudget
        ? widget.budget?.limitMinor
        : widget.goal?.targetMinor;
    amount = TextEditingController(
      text: minor == null ? '' : (minor / 100).toStringAsFixed(2),
    );
    saved = TextEditingController(
      text: ((widget.goal?.savedMinor ?? 0) / 100).toStringAsFixed(2),
    );
    category = widget.budget?.category ?? categories.first;
  }

  @override
  void dispose() {
    title.dispose();
    amount.dispose();
    saved.dispose();
    super.dispose();
  }

  int savedValue() => saved.text.trim() == '0' || saved.text.trim() == '0.00'
      ? 0
      : parseMoney(saved.text);
  Future<void> save({bool deleted = false}) async {
    if (saving) return;
    if (!deleted && !form.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      final c = widget.c;
      if (widget.isBudget) {
        final existing =
            widget.budget ??
            c.budgets.where((b) => b.category == category).firstOrNull;
        await c.saveBudget(
          CategoryBudget(
            id: existing?.id ?? const Uuid().v4(),
            ownerId: c.profile!.id,
            category: category,
            limitMinor: deleted
                ? widget.budget!.limitMinor
                : parseMoney(amount.text),
            month: monthKey(DateTime.now()),
            deleted: deleted,
          ),
        );
      } else {
        final target = deleted
            ? widget.goal!.targetMinor
            : parseMoney(amount.text);
        final savedMinor = deleted ? widget.goal!.savedMinor : savedValue();
        if (savedMinor > target) {
          throw const FormatException(
            'Saved amount cannot be greater than the goal target.',
          );
        }
        await c.saveGoal(
          SavingsGoal(
            id: widget.goal?.id ?? const Uuid().v4(),
            ownerId: c.profile!.id,
            title: title.text.trim(),
            targetMinor: target,
            savedMinor: savedMinor,
            deleted: deleted,
          ),
        );
      }
      if (mounted) {
        Navigator.pop(
          context,
          '${widget.isBudget ? 'Budget' : 'Goal'} ${deleted ? 'removed' : 'saved'}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          saving = false;
          error = e is FormatException
              ? e.message
              : 'Unable to save your plan. Try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => SheetBody(
    children: [
      Text(
        widget.isBudget ? 'Monthly budget' : 'Savings goal',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 12),
      Text(
        widget.isBudget
            ? 'Set your ${DateFormat.MMMM().format(DateTime.now())} limit.'
            : 'Set a target and track what you put aside.',
      ),
      const SizedBox(height: 24),
      Form(
        key: form,
        child: Column(
          children: [
            if (widget.isBudget)
              DropdownButtonFormField<String>(
                initialValue: category,
                isExpanded: true,
                itemHeight: null,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: widget.budget != null
                    ? null
                    : (v) => setState(() => category = v!),
              )
            else
              TextFormField(
                controller: title,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Goal name'),
                validator: requiredText,
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: amount,
              textInputAction: widget.isBudget
                  ? TextInputAction.done
                  : TextInputAction.next,
              onFieldSubmitted: (_) {
                if (widget.isBudget && !saving) save();
              },
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: widget.isBudget ? 'Monthly limit' : 'Target amount',
                prefixText: 'Rs ',
              ),
              validator: validateAmount,
            ),
            if (!widget.isBudget) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: saved,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) {
                  if (!saving) save();
                },
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Total saved so far',
                  prefixText: 'Rs ',
                ),
                validator: (v) {
                  try {
                    savedValue();
                    return null;
                  } on FormatException catch (e) {
                    return e.message;
                  }
                },
              ),
            ],
          ],
        ),
      ),
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: saving ? null : () => save(),
        child: Text(
          saving
              ? 'Saving…'
              : widget.isBudget
              ? 'Save budget'
              : 'Save goal',
        ),
      ),
      if (widget.budget != null || widget.goal != null)
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: saving
              ? null
              : () async {
                  if (await confirmAction(
                    context,
                    title:
                        'Remove this ${widget.isBudget ? 'budget' : 'goal'}?',
                    body: 'Your transactions will stay unchanged.',
                    action: 'Remove',
                    destructive: true,
                  )) {
                    await save(deleted: true);
                  }
                },
          child: const Text('Remove'),
        ),
    ],
  );
}

void showFeedback(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        showCloseIcon: true,
      ),
    );
}

Future<void> addSavingsForm(
  BuildContext context,
  AppController c,
  SavingsGoal goal,
) async {
  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : null,
    builder: (_) => AddSavingsSheet(c: c, goal: goal),
  );
  if (context.mounted && result != null) showFeedback(context, result);
}

class AddSavingsSheet extends StatefulWidget {
  const AddSavingsSheet({super.key, required this.c, required this.goal});
  final AppController c;
  final SavingsGoal goal;
  @override
  State<AddSavingsSheet> createState() => _AddSavingsSheetState();
}

class _AddSavingsSheetState extends State<AddSavingsSheet> {
  final form = GlobalKey<FormState>();
  final amount = TextEditingController();
  String? error;
  bool saving = false;
  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SheetBody(
    children: [
      Text('Add savings', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 12),
      Text(widget.goal.title),
      const SizedBox(height: 12),
      const Text(
        'Adding savings reduces your available money. Record each savings addition once; this does not transfer money.',
      ),
      const SizedBox(height: 24),
      Text(
        '${money(widget.goal.targetMinor - widget.goal.savedMinor)} to reach your goal',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 24),
      Form(
        key: form,
        child: TextFormField(
          controller: amount,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Amount to add',
            prefixText: 'Rs ',
          ),
          validator: (value) {
            final invalid = validateAmount(value);
            if (invalid != null) return invalid;
            if (parseMoney(value!) >
                widget.goal.targetMinor - widget.goal.savedMinor) {
              return 'This exceeds the remaining goal amount.';
            }
            return null;
          },
          onFieldSubmitted: (_) {
            if (!saving) save();
          },
        ),
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
        onPressed: saving ? null : save,
        child: Text(saving ? 'Saving…' : 'Add savings'),
      ),
    ],
  );
  Future<void> save() async {
    if (saving) return;
    if (!form.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.c.addSavings(widget.goal.id, parseMoney(amount.text));
      if (mounted) Navigator.pop(context, 'Savings added');
    } catch (e) {
      if (mounted) {
        setState(() {
          saving = false;
          error = e is FormatException
              ? e.message
              : 'Unable to add savings. Try again.';
        });
      }
    }
  }
}

Future<void> availableMoneyForm(BuildContext context, AppController c) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : null,
      builder: (_) => AvailableMoneyForm(c: c),
    );

class AvailableMoneyForm extends StatefulWidget {
  const AvailableMoneyForm({super.key, required this.c});
  final AppController c;
  @override
  State<AvailableMoneyForm> createState() => _AvailableMoneyFormState();
}

class _AvailableMoneyFormState extends State<AvailableMoneyForm> {
  final form = GlobalKey<FormState>();
  final amount = TextEditingController();
  bool saving = false;
  String? error;
  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SheetBody(
    children: [
      Text(
        widget.c.cashBalance == null
            ? 'Add available money'
            : 'Update available money',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 12),
      const Text(
        'How much can you spend right now? Exclude money already set aside for savings.',
      ),
      const SizedBox(height: 20),
      Form(
        key: form,
        child: TextFormField(
          controller: amount,
          enabled: !saving,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Available amount',
            prefixText: 'Rs ',
            hintText: '0.00',
          ),
          validator: (value) {
            try {
              parseAvailableMoney(value ?? '');
              return null;
            } on FormatException catch (e) {
              return e.message;
            }
          },
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'This is your own estimate. New expenses and savings reduce it; received money adds to it. Updating it sets a fresh starting point.',
      ),
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Semantics(
            liveRegion: true,
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: saving
            ? null
            : () async {
                if (!form.currentState!.validate()) return;
                setState(() {
                  saving = true;
                  error = null;
                });
                try {
                  await widget.c.setAvailableMoney(
                    parseAvailableMoney(amount.text),
                  );
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) {
                    setState(() {
                      saving = false;
                      error = e is FormatException
                          ? e.message
                          : 'Unable to save available money. Try again.';
                    });
                  }
                }
              },
        child: Text(saving ? 'Saving...' : 'Save available money'),
      ),
    ],
  );
}
