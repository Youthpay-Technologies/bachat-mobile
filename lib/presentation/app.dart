import 'package:flutter/foundation.dart';
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!c.signedIn) return const WelcomeScreen();
    if (c.profile == null) return const ProfileScreen();
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
                  : 'Choose your journey to get started. Your Google account keeps sign-in simple.',
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
                role == UserRole.teen
                    ? 'For ages 13–18. A parent must approve before you start tracking.'
                    : 'Support more than one child, with a separate view for each.',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: c.busy ? null : () => c.signIn(role),
                  icon: const Icon(Icons.login),
                  label: Text(
                    c.busy ? 'Opening Google…' : 'Continue with Google',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your records are private to you and your approved parent. We never connect to your bank automatically.',
              ),
              if (kDebugMode &&
                  const bool.fromEnvironment('ENABLE_PREVIEW')) ...[
                const Divider(height: 40),
                const Text('Development preview · sample data only'),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => c.startPreview(UserRole.teen),
                      child: const Text('Preview teen'),
                    ),
                    OutlinedButton(
                      onPressed: () => c.startPreview(UserRole.parent),
                      child: const Text('Preview parent'),
                    ),
                  ],
                ),
              ],
            ],
            AppError(c),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<ProfileScreen> {
  final name = TextEditingController();
  int age = 16;
  UserRole? role;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(controllerProvider);
    final selected = role ?? c.chosenRole;
    return Scaffold(
      body: SafeArea(
        child: PageBody(
          children: [
            const BachatMark(),
            const SizedBox(height: 36),
            Text(
              'Let’s make it yours.',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Your account type and age are fixed after setup. Check them before continuing.',
            ),
            const SizedBox(height: 28),
            TextField(
              controller: name,
              textCapitalization: TextCapitalization.words,
              maxLength: 60,
              decoration: const InputDecoration(labelText: 'Your name'),
            ),
            const SizedBox(height: 18),
            RoleChoices(
              value: selected,
              onChanged: (value) => setState(() => role = value),
            ),
            if (selected == UserRole.teen)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: DropdownButtonFormField<int>(
                  initialValue: age,
                  decoration: const InputDecoration(labelText: 'Age'),
                  items: List.generate(
                    6,
                    (i) => DropdownMenuItem(
                      value: i + 13,
                      child: Text('${i + 13} years'),
                    ),
                  ),
                  onChanged: (v) => setState(() => age = v!),
                ),
              ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: c.busy
                  ? null
                  : () => c.createProfile(
                      name.text,
                      selected,
                      selected == UserRole.teen ? age : null,
                    ),
              child: Text(c.busy ? 'Saving…' : 'Create my profile'),
            ),
            AppError(c),
            TextButton(onPressed: c.signOut, child: const Text('Sign out')),
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
    final c = ref.watch(controllerProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (c.preview || c.offline || c.pendingCount > 0)
              Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.primaryContainer,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Text(
                  c.preview
                      ? 'PREVIEW · Sample data, saved on this device only'
                      : c.pendingCount > 0
                      ? '${c.pendingCount} changes saved on this device · waiting to sync'
                      : 'Offline · Showing your saved records',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            Expanded(
              child: switch (tab) {
                0 => HomePage(
                  onActivity: () => setState(() => tab = 1),
                  onPlan: () => setState(() => tab = 2),
                ),
                1 => const ActivityPage(),
                2 => const PlanPage(),
                3 => const LearnPage(),
                _ => const SettingsPage(),
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
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
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'You'),
        ],
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
            decoration: const InputDecoration(
              labelText: 'Your child · read-only view',
            ),
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
              const Expanded(child: BachatMark()),
              IconButton(
                onPressed: c.syncing ? null : c.refresh,
                tooltip: 'Sync records',
                icon: const Icon(Icons.sync),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'A little clarity, ${c.profile!.name.split(' ').first}.',
            style: t.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            c.isParent
                ? 'Support their habits. Celebrate their progress.'
                : 'Your money, with a little more intention.',
          ),
          const SizedBox(height: 28),
          ChildPicker(c),
          if (c.isParent && c.children.isEmpty)
            const FamilyPage(embedded: true)
          else ...[
            Surface(
              tinted: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${DateFormat.MMMM().format(DateTime.now())} spending${c.isParent ? ' · ${c.viewingName}' : ''}',
                    style: t.labelLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(money(summary.spentMinor), style: t.displaySmall),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 36,
                    runSpacing: 16,
                    children: [
                      _Metric('Money in', money(summary.incomeMinor)),
                      _Metric(
                        'Net flow',
                        money(summary.incomeMinor - summary.spentMinor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Based on recorded entries, not a bank balance.',
                    style: t.bodySmall,
                  ),
                ],
              ),
            ),
            if (!c.isParent)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => entryForm(context, c),
                    icon: const Icon(Icons.add),
                    label: const Text('Add a transaction'),
                  ),
                ),
              ),
            const SectionHeading('Where it went'),
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
              'Something to save for',
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
              GoalCard(c.goals.first, c),
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
                  color: Theme.of(context).colorScheme.primary,
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
        Text('Your activity', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        const Text('The little things add up. See them clearly.'),
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
        Text('A plan for your money', style: t.headlineLarge),
        const SizedBox(height: 8),
        const Text('Spend with intention. Save for what’s next.'),
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
              ? 'You made it. A little habit, a real achievement.'
              : '${(goal.progress * 100).round()}% of the way there · ${money(goal.targetMinor - goal.savedMinor)} to go',
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
      const BachatMark(),
      const SizedBox(height: 48),
      const Icon(Icons.auto_stories_outlined, size: 52),
      const SizedBox(height: 24),
      Text(
        'Good habits.\nA little more know-how.',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: 18),
      const Text(
        'A space to learn about spending, saving, and making thoughtful money choices.',
      ),
      const SizedBox(height: 32),
      const Surface(
        tinted: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'COMING SOON',
              style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.5),
            ),
            SizedBox(height: 12),
            Text(
              'We’re putting the first lessons together. For now, every entry and savings goal is a small step forward.',
            ),
          ],
        ),
      ),
    ],
  );
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
              l.status == 'parent_approved' &&
              (l.expiresAt?.isAfter(DateTime.now()) ?? false),
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
                'Ask your parent to sign in as a parent and enter this code. It expires in 24 hours. A new code replaces the previous one.',
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
                      ? 'Your child needs to confirm you in their app.'
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
      TextButton.icon(
        onPressed: c.refresh,
        icon: const Icon(Icons.refresh),
        label: const Text('Check for updates'),
      ),
      if (widget.locked)
        TextButton(onPressed: c.signOut, child: const Text('Sign out')),
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
        Text('Your space', style: t.headlineLarge),
        const SizedBox(height: 24),
        Surface(
          child: Row(
            children: [
              CircleAvatar(
                child: Text(c.profile!.name.substring(0, 1).toUpperCase()),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.profile!.name, style: t.titleLarge),
                    Text(
                      '${c.isParent ? 'Parent' : 'Teen'} account · English · PKR',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionHeading('Make yourself at home'),
        DropdownButtonFormField<String>(
          initialValue: c.theme,
          decoration: const InputDecoration(labelText: 'Appearance'),
          items: const [
            DropdownMenuItem(
              value: 'system',
              child: Text('Use device setting'),
            ),
            DropdownMenuItem(value: 'light', child: Text('Light')),
            DropdownMenuItem(value: 'dark', child: Text('Dark')),
          ],
          onChanged: (v) {
            if (v != null) c.setTheme(v);
          },
        ),
        const SizedBox(height: 20),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.people_outline),
          title: const Text('Family connections'),
          subtitle: const Text('Approvals and shared access'),
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
        const SectionHeading('Your data'),
        const Text(
          'After setup and parent approval, your records remain available offline. New entries sync when you reconnect. Family approvals require a connection and are checked again when online.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Parents can read approved children’s records. Only teens can edit their own records. Removing the last parent pauses teen access.',
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () async {
            if (await confirmAction(
              context,
              title: c.preview ? 'Leave preview?' : 'Sign out of Bachat?',
              body: c.pendingCount > 0
                  ? 'You have ${c.pendingCount} unsynced changes. Signing out clears this device’s records, including these changes. Connect and sync first to keep them.'
                  : 'Your saved records will be cleared from this device. Synced records stay in your account.',
              action: c.preview ? 'Leave preview' : 'Sign out',
            )) {
              await c.signOut();
            }
          },
          icon: const Icon(Icons.logout),
          label: Text(c.preview ? 'Leave preview' : 'Sign out'),
        ),
        AppError(c),
        const SizedBox(height: 24),
        Text(
          'Bachat · by YouthPay\nA little clarity. A better money habit.',
          style: t.bodySmall,
        ),
      ],
    );
  }
}

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
