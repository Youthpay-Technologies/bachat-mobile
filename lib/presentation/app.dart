import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../application/controller.dart';
import '../design/components.dart';
import '../domain/models.dart';
import 'forms.dart';

class AppGate extends ConsumerWidget {
  const AppGate({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(controllerProvider);
    if (!c.ready) {
      return const DashboardSkeleton();
    }
    if (!c.signedIn) return const WelcomeScreen();
    if (c.profile == null && c.syncing) {
      return const DashboardSkeleton();
    }
    if (c.profile == null) return const WelcomeScreen();
    if (c.needsApproval) {
      return const Scaffold(body: SafeArea(child: FamilyPage(locked: true)));
    }
    return const DashboardShell();
  }
}

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    ),
  );
}

class AppError extends StatelessWidget {
  const AppError(this.c, {super.key});
  final AppController c;
  @override
  Widget build(BuildContext context) => c.error == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Semantics(
            liveRegion: true,
            child: Text(
              c.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        );
}

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});
  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeState();
}

class _WelcomeState extends ConsumerState<WelcomeScreen> {
  int step = 0;
  UserRole role = UserRole.teen;
  @override
  Widget build(BuildContext context) {
    final c = ref.watch(controllerProvider), t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: PageBody(
          children: [
            const BachatMark(large: true),
            const SizedBox(height: 52),
            Text(
              step == 0
                  ? 'Small steps.\nBetter money habits.'
                  : step == 1
                  ? 'A little support.\nA lot of independence.'
                  : 'Make room for\nyour money goals.',
              style: t.displaySmall,
            ),
            const SizedBox(height: 18),
            Text(
              step == 0
                  ? 'Know where your money goes. Build a budget that fits your day. Save for something that matters.'
                  : step == 1
                  ? 'Teens track their own money. Parents stay in the loop, with access both of you approve.'
                  : 'Track spending, build a budget and save for what matters.',
              style: t.bodyLarge,
            ),
            const SizedBox(height: 36),
            Surface(
              tinted: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    step == 0
                        ? Icons.account_balance_wallet_outlined
                        : step == 1
                        ? Icons.people_outline
                        : Icons.savings_outlined,
                    size: 40,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    step == 0
                        ? 'Your everyday, in perspective'
                        : step == 1
                        ? 'Connected, by choice'
                        : 'A plan worth looking forward to',
                    style: t.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    step == 0
                        ? 'Food, rides, a little treat. Give every rupee a place.'
                        : step == 1
                        ? 'One family code. Two confirmations. A shared view of transactions, budgets, and goals.'
                        : 'Start with a small saving goal. Keep your progress close.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (step < 2) ...[
              Semantics(
                label: 'Introduction ${step + 1} of 3',
                child: Row(
                  children: List.generate(
                    3,
                    (i) => Container(
                      margin: const EdgeInsets.only(right: 6),
                      width: i == step ? 28 : 8,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == step
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => setState(() => step++),
                  child: const Text('Continue'),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => step = 2),
                  child: const Text('Skip introduction'),
                ),
              ),
            ] else ...[
              RoleChoices(
                value: role,
                onChanged: (value) => setState(() => role = value),
              ),
              const SizedBox(height: 20),
              Text(
                role == UserRole.teen ? 'Ayesha, 16 · Teen' : 'Sana · Parent',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: c.busy ? null : () => c.startDemo(role),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(
                    role == UserRole.teen
                        ? 'Continue as Ayesha'
                        : 'Continue as Sana',
                  ),
                ),
              ),
            ],
            AppError(c),
          ],
        ),
      ),
    );
  }
}

class DashboardShell extends ConsumerStatefulWidget {
  const DashboardShell({super.key});
  @override
  ConsumerState<DashboardShell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<DashboardShell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: tab,
                children: [
                  HomePage(
                    onActivity: () => setState(() => tab = 1),
                    onPlan: () => setState(() => tab = 2),
                  ),
                  const ActivityPage(),
                  const PlanPage(),
                  const LearnPage(),
                  const SettingsPage(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: NavigationBar(
            selectedIndex: tab,
            animationDuration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 150),
            onDestinationSelected: (value) => setState(() => tab = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                label: 'Activity',
              ),
              NavigationDestination(
                icon: Icon(Icons.savings_outlined),
                label: 'Plan',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_stories_outlined),
                label: 'Learn',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                label: 'You',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChildPicker extends StatelessWidget {
  const ChildPicker(this.c, {super.key});
  final AppController c;
  @override
  Widget build(BuildContext context) => !c.isParent || c.children.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: DropdownButtonFormField<String>(
            initialValue: c.selectedChildId,
            decoration: const InputDecoration(labelText: 'Child'),
            items: c.children
                .map(
                  (l) => DropdownMenuItem(
                    value: l.teenId,
                    child: Text(l.teenName),
                  ),
                )
                .toList(),
            onChanged: (id) {
              if (id != null) c.selectChild(id);
            },
          ),
        );
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key, required this.onActivity, required this.onPlan});
  final VoidCallback onActivity, onPlan;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(controllerProvider), t = Theme.of(context).textTheme;
    final summary = MoneySummary(c.entries, DateTime.now());
    return RefreshIndicator(
      onRefresh: c.refresh,
      child: PageBody(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  c.profile!.name.substring(0, 1),
                  style: t.titleLarge,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good to see you',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(c.profile!.name, style: t.titleMedium),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => accountSheet(context, c),
                tooltip: 'Switch profile',
                icon: const Icon(Icons.swap_horiz_rounded),
              ),
            ],
          ),
          const SizedBox(height: 40),
          ChildPicker(c),
          if (c.isParent && c.children.isEmpty)
            const FamilyPage(embedded: true)
          else ...[
            Center(
              child: Column(
                children: [
                  Text(
                    '${DateFormat.MMMM().format(DateTime.now())} spending',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    money(summary.spentMinor),
                    style: t.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                if (!c.isParent)
                  FilledButton.icon(
                    onPressed: () => entryForm(context, c),
                    icon: const Icon(Icons.add),
                    label: const Text('Add transaction'),
                  ),
                OutlinedButton.icon(
                  onPressed: onActivity,
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Activity'),
                ),
                OutlinedButton.icon(
                  onPressed: onPlan,
                  icon: const Icon(Icons.savings_outlined),
                  label: const Text('Your plan'),
                ),
              ],
            ),
            const SectionHeading('Overview'),
            Surface(
              child: Wrap(
                spacing: 32,
                runSpacing: 16,
                children: [
                  _Metric('Money in', money(summary.incomeMinor)),
                  _Metric(
                    'Net flow',
                    money(summary.incomeMinor - summary.spentMinor),
                  ),
                ],
              ),
            ),
            const SectionHeading('Spending breakdown'),
            if (summary.byCategory.isEmpty)
              const EmptyState(
                icon: Icons.pie_chart_outline,
                title: 'A clearer picture starts here',
                body: 'Record an expense to see your spending by category.',
              )
            else
              Surface(
                child: Column(
                  children: summary.byCategory.entries
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(e.key)),
                                  Text(money(e.value), style: t.titleSmall),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Semantics(
                                label: '${e.key}: ${money(e.value)}',
                                child: LinearProgressIndicator(
                                  value: e.value / summary.spentMinor,
                                  minHeight: 5,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            SectionHeading(
              'Recent activity',
              action: 'See all',
              onAction: onActivity,
            ),
            if (c.entries.isEmpty)
              const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Your story starts with one entry',
                body:
                    'Add a purchase or allowance. Your recent activity will appear here.',
              )
            else
              Surface(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: c.entries
                      .take(3)
                      .map((e) => EntryTile(e, c))
                      .toList(),
                ),
              ),
            SectionHeading(
              'Savings goals',
              action: 'Your plan',
              onAction: onPlan,
            ),
            if (c.goals.isEmpty)
              const EmptyState(
                icon: Icons.flag_outlined,
                title: 'Give your savings a purpose',
                body:
                    'Create a goal in Plan and take it one small step at a time.',
              )
            else
              GoalCarousel(c),
          ],
          AppError(c),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 4),
      Text(value, style: Theme.of(context).textTheme.titleMedium),
    ],
  );
}

IconData categoryIcon(String category) => switch (category) {
  'Food & dining' => Icons.restaurant_outlined,
  'Transport' => Icons.directions_bus_outlined,
  'Education' => Icons.menu_book_outlined,
  'Shopping' => Icons.shopping_bag_outlined,
  'Entertainment' => Icons.headphones_outlined,
  'Health' => Icons.favorite_outline,
  _ => Icons.payments_outlined,
};

class EntryTile extends StatelessWidget {
  const EntryTile(this.entry, this.c, {super.key});
  final MoneyEntry entry;
  final AppController c;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact =
          constraints.maxWidth < 300 ||
          MediaQuery.textScalerOf(context).scale(14) > 20;
      final amount = Text(
        '${entry.direction == EntryDirection.income ? '+' : '−'}${money(entry.amountMinor)}',
        style: Theme.of(context).textTheme.labelLarge,
      );
      return InkWell(
        onTap: () => entryForm(context, c, existing: entry),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  entry.direction == EntryDirection.income
                      ? Icons.south_west
                      : categoryIcon(entry.category),
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFF216D2C)
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.merchant,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.category} · ${DateFormat.MMMd().format(entry.occurredAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (compact)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: amount,
                      ),
                  ],
                ),
              ),
              if (!compact) ...[const SizedBox(width: 8), amount],
            ],
          ),
        ),
      );
    },
  );
}

class ActivityPage extends ConsumerStatefulWidget {
  const ActivityPage({super.key});
  @override
  ConsumerState<ActivityPage> createState() => _ActivityState();
}

class _ActivityState extends ConsumerState<ActivityPage> {
  String query = '';
  String filter = 'All';
  @override
  Widget build(BuildContext context) {
    final c = ref.watch(controllerProvider);
    final entries = c.entries
        .where(
          (e) =>
              (filter == 'All' || e.direction.name == filter.toLowerCase()) &&
              '${e.merchant} ${e.category} ${e.note}'.toLowerCase().contains(
                query.toLowerCase(),
              ),
        )
        .toList();
    return PageBody(
      children: [
        Text('Activity', style: Theme.of(context).textTheme.headlineLarge),

        const SizedBox(height: 24),
        ChildPicker(c),
        TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: const InputDecoration(
            labelText: 'Search transactions',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: ['All', 'Expense', 'Income']
              .map(
                (v) => ChoiceChip(
                  label: Text(v),
                  selected: filter == v,
                  onSelected: (_) => setState(() => filter = v),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        if (!c.isParent)
          OutlinedButton.icon(
            onPressed: () => entryForm(context, c),
            icon: const Icon(Icons.add),
            label: const Text('Add transaction'),
          ),
        const SizedBox(height: 16),
        if (entries.isEmpty)
          const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No transactions here yet',
            body: 'Try another search, or add your first transaction.',
          )
        else
          Surface(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: entries.map((e) => EntryTile(e, c)).toList(),
            ),
          ),
        AppError(c),
      ],
    );
  }
}

class PlanPage extends ConsumerWidget {
  const PlanPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(controllerProvider), t = Theme.of(context).textTheme;
    final summary = MoneySummary(c.entries, DateTime.now());
    return PageBody(
      children: [
        Text('Plan', style: t.headlineLarge),

        const SizedBox(height: 24),
        ChildPicker(c),
        SectionHeading(
          'Monthly budgets',
          action: c.isParent ? null : 'Add budget',
          onAction: () => budgetForm(context, c),
        ),
        if (c.budgets.isEmpty)
          const EmptyState(
            icon: Icons.donut_large_outlined,
            title: 'Make a little room',
            body:
                'Set a monthly category limit to keep everyday spending in perspective.',
          ),
        ...c.budgets.map((b) {
          final spent = summary.byCategory[b.category] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(b.category, style: t.titleMedium)),
                      if (!c.isParent)
                        IconButton(
                          onPressed: () => budgetForm(context, c, existing: b),
                          tooltip: 'Edit ${b.category} budget',
                          icon: const Icon(Icons.edit_outlined),
                        ),
                    ],
                  ),
                  Text('${money(spent)} of ${money(b.limitMinor)}'),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: (spent / b.limitMinor).clamp(0, 1),
                    minHeight: 6,
                    color: spent > b.limitMinor
                        ? Theme.of(context).colorScheme.error
                        : null,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    spent > b.limitMinor
                        ? '${money(spent - b.limitMinor)} over your plan'
                        : '${money(b.limitMinor - spent)} left this month',
                    style: t.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }),
        SectionHeading(
          'Savings goals',
          action: c.isParent ? null : 'New goal',
          onAction: () => goalForm(context, c),
        ),
        if (c.goals.isEmpty)
          const EmptyState(
            icon: Icons.savings_outlined,
            title: 'What are you saving for?',
            body:
                'Pick something that matters to you. Start with a target, then record what you put aside.',
          ),
        ...c.goals.map(
          (g) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GoalCard(g, c),
          ),
        ),
        AppError(c),
      ],
    );
  }
}

class GoalCard extends StatelessWidget {
  const GoalCard(this.goal, this.c, {super.key});
  final SavingsGoal goal;
  final AppController c;
  @override
  Widget build(BuildContext context) => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flag_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                goal.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (!c.isParent)
              IconButton(
                onPressed: () => goalForm(context, c, existing: goal),
                tooltip: 'Edit savings goal',
                icon: const Icon(Icons.edit_outlined),
              ),
          ],
        ),
        const SizedBox(height: 20),
        StatusBadge(
          goal.progress == 1
              ? 'Complete'
              : '${(goal.progress * 100).round()}% saved',
          icon: goal.progress == 1
              ? Icons.check_rounded
              : Icons.savings_outlined,
        ),
        const SizedBox(height: 16),
        Text('${money(goal.savedMinor)} of ${money(goal.targetMinor)}'),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: goal.progress,
          minHeight: 6,
          borderRadius: BorderRadius.circular(6),
        ),
        const SizedBox(height: 12),
        Text(
          goal.progress == 1
              ? 'Goal reached'
              : '${money(goal.targetMinor - goal.savedMinor)} to go',
        ),
      ],
    ),
  );
}

class LearnPage extends StatelessWidget {
  const LearnPage({super.key});
  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      Text('Learn', style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 72),
      const Icon(Icons.auto_stories_outlined, size: 64),
      const SizedBox(height: 32),
      const StatusBadge('Coming soon', icon: Icons.schedule_rounded),
      const SizedBox(height: 24),
      Text(
        'A little knowledge.\nBetter money habits.',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: 16),
      const Text(
        'Short lessons on spending, saving and making your money go further.',
      ),
    ],
  );
}

class GoalCarousel extends StatefulWidget {
  const GoalCarousel(this.c, {super.key});
  final AppController c;
  @override
  State<GoalCarousel> createState() => _GoalCarouselState();
}

class _GoalCarouselState extends State<GoalCarousel> {
  final scroll = ScrollController();
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goals = widget.c.goals;
    if (goals.length == 1) return GoalCard(goals.single, widget.c);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * .88;
        void move(int direction) {
          final offset = (scroll.offset + direction * (width + 16)).clamp(
            0.0,
            scroll.position.maxScrollExtent,
          );
          if (MediaQuery.disableAnimationsOf(context)) {
            scroll.jumpTo(offset);
          } else {
            scroll.animateTo(
              offset,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
            );
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              controller: scroll,
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < goals.length; i++)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 16),
                      child: SizedBox(
                        width: width,
                        child: Semantics(
                          label: 'Savings goal ${i + 1} of ${goals.length}',
                          child: GoalCard(goals[i], widget.c),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${goals.length} goals',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Previous goal',
                  onPressed: () => move(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  tooltip: 'Next goal',
                  onPressed: () => move(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class FamilyPage extends ConsumerStatefulWidget {
  const FamilyPage({super.key, this.locked = false, this.embedded = false});
  final bool locked, embedded;
  @override
  ConsumerState<FamilyPage> createState() => _FamilyState();
}

class _FamilyState extends ConsumerState<FamilyPage> {
  final code = TextEditingController();
  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(controllerProvider), t = Theme.of(context).textTheme;
    final pending = c.links
        .where(
          (l) =>
              (c.preview && l.status == 'pending') ||
              (l.status == 'parent_approved' &&
                  (l.expiresAt?.isAfter(DateTime.now()) ?? false)),
        )
        .toList();
    final content = <Widget>[
      if (widget.locked) ...[const BachatMark(), const SizedBox(height: 32)],
      Text(
        c.isParent ? 'Your family' : 'A little support to get started',
        style: t.headlineMedium,
      ),
      const SizedBox(height: 12),
      Text(
        c.isParent
            ? 'Connect with your child to view their transactions, budgets, and savings goals. Only they can edit their records.'
            : 'A parent must approve your account. You then confirm it’s the right person before your dashboard unlocks.',
      ),
      const SizedBox(height: 24),
      if (c.isParent) ...[
        TextField(
          controller: code,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Family code',
            hintText: 'BCHT-XXXXXXXX',
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: c.busy
              ? null
              : () async {
                  if (await confirmAction(
                    context,
                    title: 'Approve this teen’s account?',
                    body:
                        'Entering their code approves their use of Bachat. They must confirm you before you can see their records.',
                    action: 'Approve and request access',
                  )) {
                    await c.claimCode(code.text);
                  }
                },
          child: const Text('Approve & connect'),
        ),
      ] else ...[
        Surface(
          tinted: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1. Share a family code', style: t.titleMedium),
              const SizedBox(height: 12),
              const Text(
                'Share a code with your parent. Confirm their request to connect.',
              ),
              const SizedBox(height: 16),
              if (c.familyCode != null) ...[
                SelectableText(c.familyCode!, style: t.headlineSmall),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: c.familyCode!));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Family code copied')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy code'),
                ),
              ],
              FilledButton(
                onPressed: c.busy ? null : c.generateCode,
                child: Text(
                  c.familyCode == null
                      ? 'Create family code'
                      : 'Create a new code',
                ),
              ),
            ],
          ),
        ),
      ],
      if (pending.isNotEmpty) const SectionHeading('Waiting for confirmation'),
      ...pending.map(
        (l) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.isParent
                      ? 'Waiting for ${l.teenName}'
                      : '2. Confirm ${l.parentName}',
                  style: t.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  c.isParent
                      ? 'Ayesha needs to confirm this request.'
                      : 'Only confirm someone you know is your parent. They will be able to read your transactions, budgets, and goals.',
                ),
                if (!c.isParent)
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton(
                        onPressed: c.busy
                            ? null
                            : () async {
                                if (await confirmAction(
                                  context,
                                  title: 'Confirm ${l.parentName}?',
                                  body:
                                      'This parent will be able to read your transactions, budgets, and savings goals. They cannot edit them.',
                                  action: 'Confirm parent',
                                )) {
                                  await c.decideLink(l, true);
                                }
                              },
                        child: const Text('Confirm parent'),
                      ),
                      TextButton(
                        onPressed: c.busy ? null : () => c.decideLink(l, false),
                        child: const Text('Decline'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
      if (c.links.any((l) => l.approved))
        const SectionHeading('Connected family'),
      ...c.links
          .where((l) => l.approved)
          .map(
            (l) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.verified_user_outlined),
              title: Text(c.isParent ? l.teenName : l.parentName),
              subtitle: const Text('Approved · Read-only parent access'),
              trailing: IconButton(
                tooltip: 'Remove family connection',
                icon: const Icon(Icons.link_off),
                onPressed: () async {
                  if (await confirmAction(
                    context,
                    title: 'Remove this connection?',
                    body:
                        'The parent will lose access. If this is the last approved parent, the teen dashboard locks until a parent is approved again.',
                    action: 'Remove connection',
                  )) {
                    await c.revokeLink(l);
                  }
                },
              ),
            ),
          ),
      AppError(c),
      OutlinedButton.icon(
        onPressed: () =>
            c.startDemo(c.isParent ? UserRole.teen : UserRole.parent),
        icon: const Icon(Icons.swap_horiz),
        label: const Text('Switch profile'),
      ),
    ];
    return widget.embedded
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: content,
          )
        : PageBody(children: content);
  }
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(controllerProvider), t = Theme.of(context).textTheme;
    return PageBody(
      children: [
        Text('You', style: t.headlineLarge),
        const SizedBox(height: 32),
        Surface(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(child: Text(c.profile!.name.substring(0, 1))),
            title: Text(c.profile!.name, style: t.titleLarge),
            subtitle: Text(c.isParent ? 'Parent' : 'Teen · 16'),
            trailing: const Icon(Icons.unfold_more_rounded),
            onTap: () => accountSheet(context, c),
          ),
        ),
        const SectionHeading('Preferences'),
        Surface(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.contrast_rounded),
                title: const Text('Appearance'),
                subtitle: Text(switch (c.theme) {
                  'light' => 'Light',
                  'dark' => 'Dark',
                  _ => 'System',
                }),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => appearanceSheet(context, c),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.people_outline),
                title: const Text('Family connections'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('Family')),
                      body: const SafeArea(child: FamilyPage()),
                    ),
                  ),
                ),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.language_outlined),
                title: Text('English'),
                trailing: Text('PKR'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        TextButton.icon(
          onPressed: () async {
            if (await confirmAction(
              context,
              title: 'Reset sample data?',
              body:
                  'Your changes will be replaced with the original transactions, budgets, goals and family connection.',
              action: 'Reset data',
            ))
              await c.resetDemo();
          },
          icon: const Icon(Icons.restart_alt),
          label: const Text('Reset sample data'),
        ),
        AppError(c),
        const SizedBox(height: 32),
        Text('Bachat by YouthPay', style: t.bodySmall),
      ],
    );
  }
}

Future<void> accountSheet(
  BuildContext context,
  AppController c,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  useSafeArea: true,
  isScrollControlled: true,
  builder: (sheetContext) => SheetBody(
    children: [
      Text('Switch profile', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 24),
      ...UserRole.values.map(
        (role) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Surface(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                child: Text(role == UserRole.teen ? 'A' : 'S'),
              ),
              title: Text(role == UserRole.teen ? 'Ayesha' : 'Sana'),
              subtitle: Text(role == UserRole.teen ? 'Teen · 16' : 'Parent'),
              trailing: c.profile!.role == role
                  ? const Icon(Icons.check_circle_outline)
                  : const Icon(Icons.chevron_right),
              onTap: () async {
                Navigator.pop(sheetContext);
                await c.startDemo(role);
              },
            ),
          ),
        ),
      ),
    ],
  ),
);

Future<void> appearanceSheet(BuildContext context, AppController c) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => SheetBody(
        children: [
          Text('Appearance', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          ...{'system': 'System', 'light': 'Light', 'dark': 'Dark'}.entries.map(
            (entry) => ListTile(
              title: Text(entry.value),
              leading: Icon(switch (entry.key) {
                'light' => Icons.light_mode_outlined,
                'dark' => Icons.dark_mode_outlined,
                _ => Icons.brightness_auto_outlined,
              }),
              trailing: c.theme == entry.key
                  ? const Icon(Icons.check_circle_outline)
                  : null,
              onTap: () async {
                Navigator.pop(sheetContext);
                await c.setTheme(entry.key);
              },
            ),
          ),
        ],
      ),
    );

class RoleChoices extends StatelessWidget {
  const RoleChoices({super.key, required this.value, required this.onChanged});
  final UserRole value;
  final ValueChanged<UserRole> onChanged;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: UserRole.values
        .map(
          (role) => ChoiceChip(
            label: Text(role == UserRole.teen ? 'I’m a teen' : 'I’m a parent'),
            avatar: Icon(
              role == UserRole.teen
                  ? Icons.person_outline
                  : Icons.people_outline,
            ),
            selected: value == role,
            onSelected: (_) => onChanged(role),
          ),
        )
        .toList(),
  );
}
