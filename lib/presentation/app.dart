import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../application/controller.dart';
import '../design/components.dart';
import '../design/brand.dart';
import '../design/theme.dart';
import '../design/brand_panels.dart';
import '../domain/models.dart';
import '../domain/activity_filter.dart';
import 'activity_filters.dart';
import 'forms.dart';
import 'auth_screens.dart';
import 'onboarding.dart';
import 'data_privacy_screen.dart';
export 'onboarding.dart' show WelcomeScreen;

class AppGate extends ConsumerWidget {
  const AppGate({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(controllerProvider);
    if (!c.ready) {
      return const DashboardSkeleton();
    }
    if (c.recoveringPassword && c.signedIn) {
      return const AuthScreen(recovery: true);
    }
    if (!c.signedIn) return const WelcomeScreen();
    if (!c.preview && c.isParent) {
      return Scaffold(
        body: SafeArea(
          child: PageBody(
            children: [
              const Text('Parent accounts are coming soon.'),
              TextButton(onPressed: c.signOut, child: const Text('Sign out')),
            ],
          ),
        ),
      );
    }
    if (c.profile == null && c.syncing) {
      return const DashboardSkeleton();
    }
    if (c.profile == null && !c.profileChecked) {
      return Scaffold(
        body: SafeArea(
          child: PageBody(
            children: [
              const Text('Unable to load your account'),
              AppError(c),
              FilledButton(
                onPressed: c.syncing ? null : c.refresh,
                child: const Text('Try again'),
              ),
              TextButton(onPressed: c.signOut, child: const Text('Sign out')),
            ],
          ),
        ),
      );
    }
    if (c.profile == null) return const ProfileSetupScreen();
    if (c.needsApproval) {
      return const Scaffold(body: SafeArea(child: FamilyPage(locked: true)));
    }
    return const DashboardShell();
  }
}

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.storageKey});
  final List<Widget> children;
  final String? storageKey;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: storageKey == null ? null : PageStorageKey(storageKey),
    physics: const AlwaysScrollableScrollPhysics(),
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    padding: EdgeInsets.fromLTRB(
      MediaQuery.sizeOf(context).width < 360 ? 16 : 24,
      24,
      MediaQuery.sizeOf(context).width < 360 ? 16 : 24,
      36,
    ),
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
    final viewport = MediaQuery.sizeOf(context);
    final wide = viewport.width >= 840 && viewport.height >= 600;
    const destinations = [
      NavigationDestination(
        icon: _NavigationCircle(Icons.grid_view_outlined),
        selectedIcon: _NavigationCircle(
          Icons.grid_view_rounded,
          selected: true,
        ),
        label: 'Home',
      ),
      NavigationDestination(
        icon: _NavigationCircle(Icons.receipt_long_outlined),
        selectedIcon: _NavigationCircle(
          Icons.receipt_long_rounded,
          selected: true,
        ),
        label: 'Activity',
      ),
      NavigationDestination(
        icon: _NavigationCircle(Icons.savings_outlined),
        selectedIcon: _NavigationCircle(Icons.savings_rounded, selected: true),
        label: 'Plan',
      ),
    ];
    return Scaffold(
      body: BachatBackdrop(
        child: SafeArea(
          child: Row(
            children: [
              if (wide) ...[
                NavigationRail(
                  selectedIndex: tab,
                  onDestinationSelected: (value) => setState(() => tab = value),
                  minWidth: MediaQuery.textScalerOf(context).scale(12) > 18
                      ? 160
                      : 104,
                  labelType: NavigationRailLabelType.all,
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: BachatSymbol(),
                  ),
                  destinations: destinations
                      .map(
                        (destination) => NavigationRailDestination(
                          icon: destination.icon,
                          selectedIcon: destination.selectedIcon,
                          label: Text(destination.label),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(width: 1),
              ],
              Expanded(
                child: Column(
                  children: [
                    SyncStatus(c),
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : SafeArea(
              top: false,
              child: Center(
                heightFactor: 1,
                child: SizedBox(
                  width: 280,
                  child: NavigationBar(
                    height: MediaQuery.textScalerOf(context).scale(12) > 18
                        ? 112
                        : 80,
                    backgroundColor: Colors.transparent,
                    indicatorColor: Colors.transparent,
                    selectedIndex: tab,
                    animationDuration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 150),
                    onDestinationSelected: (value) =>
                        setState(() => tab = value),
                    destinations: destinations,
                  ),
                ),
              ),
            ),
    );
  }
}

class _NavigationCircle extends StatelessWidget {
  const _NavigationCircle(this.icon, {this.selected = false});
  final IconData icon;
  final bool selected;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? colors.primaryContainer : colors.surfaceContainer,
        border: Border.all(
          color: selected
              ? colors.primary.withValues(alpha: .4)
              : colors.outline,
        ),
      ),
      child: Icon(
        icon,
        size: 22,
        color: selected ? colors.onPrimaryContainer : colors.onSurfaceVariant,
      ),
    );
  }
}

Future<void> openProfile(BuildContext context) => Navigator.push<void>(
  context,
  MaterialPageRoute(builder: (_) => const ProfileScreen()),
);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(leading: const BackButton()),
    body: BachatBackdrop(
      child: SafeArea(
        child: Column(
          children: [
            SyncStatus(ref.watch(controllerProvider)),
            const Expanded(child: SettingsPage()),
          ],
        ),
      ),
    ),
  );
}

/// A local save is distinct from a completed server sync on every tab.
class SyncStatus extends StatelessWidget {
  const SyncStatus(this.controller, {super.key});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c.preview || (!c.offline && c.pendingCount == 0)) {
      return const SizedBox.shrink();
    }
    final colors = Theme.of(context).colorScheme;
    final message = c.pendingCount > 0
        ? 'Saved on this device. ${c.pendingCount} ${c.pendingCount == 1 ? 'change' : 'changes'} waiting to sync.'
        : 'You are offline. Showing records saved on this device.';
    final content = Semantics(liveRegion: true, child: Text(message));
    final retry = TextButton.icon(
      onPressed: c.syncing ? null : c.refresh,
      icon: const Icon(Icons.sync_rounded, size: 18),
      label: Text(c.syncing ? 'Syncing' : 'Retry sync'),
    );
    return Material(
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: LayoutBuilder(
          builder: (context, size) {
            if (size.maxWidth < 360 ||
                MediaQuery.textScalerOf(context).scale(14) > 21) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [content, retry],
              );
            }
            return Row(
              children: [
                Expanded(child: content),
                const SizedBox(width: 12),
                retry,
              ],
            );
          },
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
            decoration: const InputDecoration(labelText: 'Child · Read only'),
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
    final now = DateTime.now();
    final summary = MoneySummary(c.entries, now);
    final previous = MoneySummary(c.entries, DateTime(now.year, now.month - 1));
    final difference = summary.spentMinor - previous.spentMinor;
    final dailyTotals = <int>[];
    var cumulative = 0;
    for (var day = 1; day <= now.day; day++) {
      cumulative += c.entries
          .where(
            (e) =>
                e.direction == EntryDirection.expense &&
                e.occurredAt.year == now.year &&
                e.occurredAt.month == now.month &&
                e.occurredAt.day == day,
          )
          .fold<int>(0, (v, e) => v + e.amountMinor);
      dailyTotals.add(cumulative);
    }
    final limit = c.budgets.fold<int>(0, (v, b) => v + b.limitMinor);
    final budgetSpent = c.budgets.fold<int>(
      0,
      (v, b) => v + (summary.byCategory[b.category] ?? 0),
    );
    final colors = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: c.refresh,
      child: PageBody(
        storageKey: 'home',
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(5, 5, 14, 5),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: .7),
                  borderRadius: BorderRadius.circular(BachatRadii.pill),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: .3),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BachatSymbol(size: 30),
                    SizedBox(width: 8),
                    Text('Home'),
                  ],
                ),
              ),

              if (c.preview)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Text('Demo', style: TextStyle(fontSize: 12)),
                ),
              IconButton.outlined(
                style: IconButton.styleFrom(
                  shape: const CircleBorder(),
                  foregroundColor: colors.onSurface,
                  side: BorderSide(color: colors.primary.withValues(alpha: .3)),
                ),
                onPressed: onPlan,
                tooltip: 'Your plan',
                icon: const Icon(Icons.account_balance_wallet_outlined),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                style: IconButton.styleFrom(
                  shape: const CircleBorder(),
                  foregroundColor: colors.onSurface,
                  side: BorderSide(color: colors.primary.withValues(alpha: .3)),
                ),
                onPressed: () => openProfile(context),
                tooltip: 'Profile',
                icon: Icon(
                  c.preview ? Icons.swap_horiz_rounded : Icons.person_outline,
                ),
              ),
            ],
          ),
          ChildPicker(c),
          if (c.isParent && c.children.isEmpty)
            const FamilyPage(embedded: true)
          else ...[
            SpendingHero(
              month: DateFormat.MMMM().format(now),
              amount: money(summary.spentMinor),
              contextLabel: previous.spentMinor == 0
                  ? 'Your recorded spending this month'
                  : '${difference >= 0 ? '+' : '-'}${money(difference.abs())} vs last month',
              dailyTotals: dailyTotals,
            ),
            const SizedBox(height: 16),
            BudgetSummaryCard(
              progress: limit == 0 ? 0 : (budgetSpent / limit).clamp(0, 1),
              overBudget: budgetSpent > limit,
              title: limit == 0
                  ? 'Make room for what matters'
                  : budgetSpent > limit
                  ? '${money(budgetSpent - limit)} over budget'
                  : '${money(limit - budgetSpent)} left in budget',
              subtitle: limit == 0
                  ? 'Set your first category budget in Plan.'
                  : 'Across your monthly category budgets.',
              onTap: onPlan,
            ),
            SectionHeading(
              'Spending by category',
              action: 'View all',
              onAction: onActivity,
            ),
            if (summary.byCategory.isEmpty)
              EmptyState(
                icon: Icons.pie_chart_outline,
                title: 'A clearer picture starts here',
                body: 'Record an expense to see your spending by category.',
                action: c.isParent ? null : 'Record an expense',
                onAction: () => entryForm(context, c),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: summary.byCategory.entries.indexed.map((item) {
                    final (index, category) = item;
                    final budget = c.budgets
                        .where((b) => b.category == category.key)
                        .firstOrNull;
                    final accent = [
                      BachatBrand.categoryOrange,
                      BachatBrand.categoryGreen,
                      BachatBrand.cobalt,
                    ][index % 3];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 164,
                        child: Surface(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accent.withValues(alpha: .16),
                                  border: Border.all(color: accent, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withValues(alpha: .15),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  categoryIcon(category.key),
                                  color: accent,
                                  size: 25,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(category.key, style: t.bodyLarge),
                              const SizedBox(height: 26),
                              Text(
                                money(category.value),
                                style: BachatBrand.figure(
                                  context,
                                  size: 18,
                                  weight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                budget == null
                                    ? 'No budget set'
                                    : category.value > budget.limitMinor
                                    ? '${money(category.value - budget.limitMinor)} over'
                                    : '${money(budget.limitMinor - category.value)} left',
                                style: t.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 24),
            MoneySetupCard(c),
            const SizedBox(height: 16),
            if (!c.isParent) MoneyActions(c),
            SectionHeading(
              'Recent activity',
              action: 'See all',
              onAction: onActivity,
            ),
            if (c.entries.isEmpty)
              EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Your story starts with one entry',
                body:
                    'Add a purchase or allowance. Your recent activity will appear here.',
                action: c.isParent ? null : 'Add your first expense',
                onAction: () => entryForm(context, c),
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
            const SectionHeading('Overview'),
            Surface(
              tone: Theme.of(context).colorScheme.surfaceContainerLow,
              child: Wrap(
                spacing: 32,
                runSpacing: 16,
                children: [
                  _Metric('Money in', money(summary.incomeMinor)),
                  _Metric('Set aside', money(summary.savedMinor)),
                  _Metric(
                    'Net flow',
                    money(
                      summary.incomeMinor -
                          summary.spentMinor -
                          summary.savedMinor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Net flow is money in minus spending and money set aside.',
              style: t.bodySmall,
            ),
            SectionHeading(
              'Savings goals',
              action: 'Your plan',
              onAction: onPlan,
            ),
            if (c.goals.isEmpty)
              EmptyState(
                icon: Icons.flag_outlined,
                title: 'Give your savings a purpose',
                body:
                    'Create a goal in Plan and take it one small step at a time.',
                action: c.isParent ? null : 'Create a savings goal',
                onAction: () => goalForm(context, c),
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

/// Optional setup keeps the expense actions available at every stage.
class MoneySetupCard extends StatelessWidget {
  const MoneySetupCard(this.c, {super.key});
  final AppController c;

  Future<void> choosePlan(BuildContext context, bool budget) async {
    if (budget) {
      await budgetForm(context, c);
    } else {
      await goalForm(context, c);
    }
    if (context.mounted &&
        c.cashBalance == null &&
        (c.budgets.isNotEmpty || c.goals.isNotEmpty)) {
      await availableMoneyForm(context, c);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final available = c.availableMinor;
    if (available != null)
      return Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Available to spend', style: t.bodySmall)),
                if (!c.isParent)
                  IconButton(
                    tooltip: 'Update available money',
                    onPressed: () => availableMoneyForm(context, c),
                    icon: const Icon(Icons.edit_outlined),
                  ),
              ],
            ),
            Text(
              money(available),
              style: BachatBrand.figure(
                context,
                size: 28,
                weight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              available < 0
                  ? 'Recorded spending exceeds your available money. Review your entries or update this amount.'
                  : 'Tracked from your entered amount, expenses, savings and received money.',
              style: t.bodySmall,
            ),
          ],
        ),
      );
    if (c.isParent) return const SizedBox.shrink();
    final hasPlan = c.budgets.isNotEmpty || c.goals.isNotEmpty;
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasPlan ? 'Add your available money' : 'Start with a simple plan',
            style: t.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            hasPlan
                ? 'Your plan is ready. Enter what you can spend now, then track expenses as you go.'
                : 'Choose a budget or savings goal, add your available money, then track everyday expenses. You can also start tracking right away.',
            style: t.bodySmall,
          ),
          const SizedBox(height: 16),
          if (hasPlan)
            OutlinedButton(
              onPressed: () => availableMoneyForm(context, c),
              child: const Text('Add available money'),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => choosePlan(context, true),
                  child: const Text('Set a budget'),
                ),
                OutlinedButton(
                  onPressed: () => choosePlan(context, false),
                  child: const Text('Set a savings goal'),
                ),
              ],
            ),
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
      const SizedBox(height: 6),
      Text(value, style: Theme.of(context).textTheme.titleMedium),
    ],
  );
}

IconData categoryIcon(String category) => switch (category) {
  'Savings' => Icons.savings_outlined,
  'Food & dining' => Icons.restaurant_outlined,
  'Transport' => Icons.directions_bus_outlined,
  'Education' => Icons.menu_book_outlined,
  'Shopping' => Icons.shopping_bag_outlined,
  'Entertainment' => Icons.headphones_outlined,
  'Health' => Icons.favorite_outline,
  _ => Icons.payments_outlined,
};

class MoneyActions extends StatelessWidget {
  const MoneyActions(this.controller, {super.key});
  final AppController controller;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) {
      final colors = Theme.of(context).colorScheme;
      final dark = Theme.of(context).brightness == Brightness.dark;

      Widget spendBtn = FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: dark
              ? colors.surfaceContainer
              : BachatBrand.obsidian,
          foregroundColor: dark ? colors.onSurface : Colors.white,
          minimumSize: const Size(48, 54),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () => entryForm(context, controller),
        icon: const Icon(Icons.north_east_rounded, size: 20),
        label: const Text('Spend'),
      );

      Widget receiveBtn = FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onSurface,
          minimumSize: const Size(48, 54),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () =>
            entryForm(context, controller, direction: EntryDirection.income),
        icon: const Icon(Icons.south_west_rounded, size: 20),
        label: const Text('Receive'),
      );

      if (size.maxWidth < 300 ||
          MediaQuery.textScalerOf(context).scale(14) > 21) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [spendBtn, const SizedBox(height: 12), receiveBtn],
        );
      }
      return Row(
        children: [
          Expanded(child: spendBtn),
          const SizedBox(width: 12),
          Expanded(child: receiveBtn),
        ],
      );
    },
  );
}

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
                backgroundColor: entry.direction == EntryDirection.savings
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  entry.direction == EntryDirection.income
                      ? Icons.south_west
                      : categoryIcon(entry.category),
                  color: entry.direction == EntryDirection.savings
                      ? Theme.of(context).colorScheme.onSecondaryContainer
                      : Theme.of(context).colorScheme.onPrimaryContainer,
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          '${switch (entry.direction) {
                            EntryDirection.expense => 'Spent',
                            EntryDirection.income => 'Received',
                            EntryDirection.savings => 'Set aside',
                          }} · ${entry.categoryLabel}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          DateFormat.MMMd()
                              .format(entry.occurredAt)
                              .replaceAll(' ', '\u00a0'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
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

class ActivityTotals extends StatelessWidget {
  const ActivityTotals(this.entries, {super.key});
  final List<MoneyEntry> entries;

  @override
  Widget build(BuildContext context) {
    int total(EntryDirection direction) => entries
        .where((entry) => entry.direction == direction)
        .fold(0, (sum, entry) => sum + entry.amountMinor);
    return Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${entries.length} ${entries.length == 1 ? 'transaction' : 'transactions'} · Current results',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              for (final direction in EntryDirection.values)
                if (entries.any((entry) => entry.direction == direction))
                  _Metric(switch (direction) {
                    EntryDirection.expense => 'Spent',
                    EntryDirection.income => 'Received',
                    EntryDirection.savings => 'Set aside',
                  }, money(total(direction))),
            ],
          ),
        ],
      ),
    );
  }
}

class ActivityPage extends ConsumerStatefulWidget {
  const ActivityPage({super.key});
  @override
  ConsumerState<ActivityPage> createState() => _ActivityState();
}

class _ActivityState extends ConsumerState<ActivityPage> {
  final search = TextEditingController();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  String query = '';
  String filter = 'All';
  ActivityFilter options = const ActivityFilter();
  @override
  Widget build(BuildContext context) {
    final c = ref.watch(controllerProvider);
    final entries = options.apply(
      c.entries,
      text: query,
      direction: filter == 'All'
          ? null
          : EntryDirection.values.byName(filter.toLowerCase()),
    );
    final hasFilters =
        query.isNotEmpty || filter != 'All' || options.activeCount > 0;
    final days = <DateTime, List<MoneyEntry>>{};
    for (final entry in entries) {
      final date = entry.occurredAt;
      days
          .putIfAbsent(DateTime(date.year, date.month, date.day), () => [])
          .add(entry);
    }
    return PageBody(
      storageKey: 'activity',
      children: [
        PageHeading(
          'Activity',
          action: IconButton.outlined(
            tooltip: 'Filter activity',
            icon: Badge(
              isLabelVisible: options.activeCount > 0,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              textColor: Theme.of(context).colorScheme.onPrimaryContainer,
              label: Text('${options.activeCount}'),
              child: const Icon(Icons.tune_rounded),
            ),
            onPressed: () async {
              final selected = await activityFilterSheet(context, options);
              if (selected != null && mounted) {
                setState(() => options = selected);
              }
            },
          ),
        ),
        ChildPicker(c),
        TextField(
          controller: search,
          onChanged: (v) => setState(() => query = v),
          decoration: InputDecoration(
            labelText: 'Search transactions',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      search.clear();
                      setState(() => query = '');
                    },
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...['All', 'Expense', 'Income', 'Savings'].map(
              (value) => ChoiceChip(
                label: Text(value),
                selected: filter == value,
                onSelected: (_) => setState(() => filter = value),
              ),
            ),
          ],
        ),
        if (options.activeCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _activitySummary(options),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Clear advanced filters',
                  onPressed: () =>
                      setState(() => options = const ActivityFilter()),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        if (!c.isParent) MoneyActions(c),
        const SizedBox(height: 16),
        if (entries.isNotEmpty) ...[
          ActivityTotals(entries),
          const SizedBox(height: 8),
        ],
        if (entries.isEmpty)
          EmptyState(
            icon: Icons.receipt_long_outlined,
            title: hasFilters ? 'No matches' : 'No transactions yet',
            body: hasFilters
                ? 'Try a different search or clear your filters.'
                : c.isParent
                ? 'Shared transactions will appear here.'
                : 'Add your first expense or income.',
            action: hasFilters ? 'Clear filters' : null,
            onAction: () {
              search.clear();
              setState(() {
                query = '';
                filter = 'All';
                options = const ActivityFilter();
              });
            },
          )
        else if (options.groupsByDate) ...[
          for (final day in days.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 12),
              child: Text(
                _dateLabel(day.key),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Surface(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: day.value
                    .map((entry) => EntryTile(entry, c))
                    .toList(),
              ),
            ),
          ],
        ] else
          Surface(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: entries.map((entry) => EntryTile(entry, c)).toList(),
            ),
          ),
        AppError(c),
      ],
    );
  }
}

String _activitySummary(ActivityFilter options) => [
  if (options.period != ActivityPeriod.all)
    switch (options.period) {
      ActivityPeriod.thisMonth => 'This month',
      ActivityPeriod.lastMonth => 'Last month',
      ActivityPeriod.custom =>
        '${DateFormat.yMMMd().format(options.from!)} – ${DateFormat.yMMMd().format(options.through!)}',
      ActivityPeriod.all => 'All time',
    },
  if (options.category != null) options.category!,
  if (options.order != ActivityOrder.newest)
    switch (options.order) {
      ActivityOrder.oldest => 'Oldest first',
      ActivityOrder.highest => 'Amount: high to low',
      ActivityOrder.lowest => 'Amount: low to high',
      ActivityOrder.newest => 'Newest first',
    },
].join(' · ');

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
String _dateLabel(DateTime date) {
  final now = DateTime.now();
  if (_sameDay(date, now)) return 'Today';
  if (_sameDay(date, DateTime(now.year, now.month, now.day - 1))) {
    return 'Yesterday';
  }
  return DateFormat.yMMMd().format(date);
}

class PlanPage extends ConsumerWidget {
  const PlanPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(controllerProvider), t = Theme.of(context).textTheme;
    final summary = MoneySummary(c.entries, DateTime.now());
    return PageBody(
      storageKey: 'plan',
      children: [
        PageHeading(
          'Plan',
          subtitle:
              '${DateFormat.yMMMM().format(DateTime.now())} · Your monthly plan',
        ),
        ChildPicker(c),
        MoneySetupCard(c),
        const SectionHeading('Set aside'),
        Surface(
          child: Row(
            children: [
              const Icon(Icons.savings_outlined),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      money(
                        c.entries
                            .where((e) => e.direction == EntryDirection.savings)
                            .fold<int>(0, (total, e) => total + e.amountMinor),
                      ),
                      style: t.headlineMedium,
                    ),
                    const Text('Recorded savings'),
                  ],
                ),
              ),
            ],
          ),
        ),
        SectionHeading(
          'Monthly budgets',
          action: c.isParent ? null : 'Add budget',
          onAction: () => budgetForm(context, c),
        ),
        if (c.budgets.isEmpty)
          EmptyState(
            icon: Icons.donut_large_outlined,
            title: 'Make a little room',
            body:
                'Set a monthly category limit to keep everyday spending in perspective.',
            action: c.isParent ? null : 'Set your first budget',
            onAction: () => budgetForm(context, c),
          ),
        if (!c.isParent && c.reusableBudgets.isNotEmpty) ReuseBudgetsButton(c),
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
                  if (spent > b.limitMinor) ...[
                    const SizedBox(height: 12),
                    const StatusBadge(
                      'Over budget',
                      icon: Icons.warning_amber_rounded,
                      danger: true,
                    ),
                  ],
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    semanticsLabel:
                        '${b.category} monthly budget: ${money(spent)} spent of ${money(b.limitMinor)}',
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

class ReuseBudgetsButton extends StatefulWidget {
  const ReuseBudgetsButton(this.c, {super.key});
  final AppController c;
  @override
  State<ReuseBudgetsButton> createState() => _ReuseBudgetsButtonState();
}

class _ReuseBudgetsButtonState extends State<ReuseBudgetsButton> {
  bool busy = false;
  String? error;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: busy
              ? null
              : () async {
                  setState(() {
                    busy = true;
                    error = null;
                  });
                  try {
                    final count = await widget.c.reusePreviousBudgets();
                    if (context.mounted) {
                      showFeedback(
                        context,
                        count == 1 ? 'Budget reused' : '$count budgets reused',
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(
                        () => error = e is FormatException
                            ? e.message
                            : 'Unable to reuse budgets. Try again.',
                      );
                    }
                  } finally {
                    if (mounted) setState(() => busy = false);
                  }
                },
          icon: const Icon(Icons.history_rounded),
          label: Text(busy ? 'Reusing…' : 'Reuse last month’s budgets'),
        ),
        if (error != null)
          Semantics(
            liveRegion: true,
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    ),
  );
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
          highlight: true,
        ),
        const SizedBox(height: 16),
        Text('${money(goal.savedMinor)} of ${money(goal.targetMinor)}'),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          semanticsLabel:
              '${goal.title} savings goal: ${money(goal.savedMinor)} saved of ${money(goal.targetMinor)}',
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
        if (!c.isParent && goal.progress < 1) ...[
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => addSavingsForm(context, c, goal),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add savings'),
            ),
          ),
        ],
      ],
    ),
  );
}

class LearnPage extends StatelessWidget {
  const LearnPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PageBody(
      children: [
        const PageHeading('Learn'),
        Surface(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatusBadge(
                'Coming soon',
                icon: Icons.schedule_rounded,
                highlight: true,
              ),
              const SizedBox(height: 20),
              Text(
                'Smart money habits, curated for teens.',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Bite-sized interactive lessons on budgeting, compound savings, and smart everyday spending.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'UPCOMING MODULES',
          style: TextStyle(
            fontFamily: BachatBrand.interfaceFont,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        const _LearnModuleTile(
          number: '01',
          title: 'The Smart Budgeting Formula',
          subtitle: 'A simple guide to setting limits without missing out',
        ),
        const SizedBox(height: 10),
        const _LearnModuleTile(
          number: '02',
          title: 'The Magic of Early Savings',
          subtitle: 'How small habits compound into big financial freedom',
        ),
        const SizedBox(height: 10),
        const _LearnModuleTile(
          number: '03',
          title: 'Needs vs. Wants in Practice',
          subtitle: 'Spotting impulsive buys and saving with clarity',
        ),
        const SizedBox(height: 20),
        Surface(
          tone: colors.surfaceContainerLow,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lock_clock_outlined,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Early Access Coming Soon',
                      style: TextStyle(
                        fontFamily: BachatBrand.headingFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Interactive lessons are currently being crafted. Keep recording expenses to prepare your streak!',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LearnModuleTile extends StatelessWidget {
  const _LearnModuleTile({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  final String number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  number,
                  style: TextStyle(
                    fontFamily: BachatBrand.figuresFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: colors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontFamily: BachatBrand.headingFont,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: BachatBrand.interfaceFont,
              fontSize: 13,
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
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
  void initState() {
    super.initState();
    scroll.addListener(() => setState(() {}));
  }

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
                  onPressed: scroll.hasClients && scroll.offset > 0
                      ? () => move(-1)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  tooltip: 'Next goal',
                  onPressed:
                      !scroll.hasClients ||
                          scroll.offset < scroll.position.maxScrollExtent
                      ? () => move(1)
                      : null,
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
        const PageHeading('Profile'),
        Surface(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(child: Text(c.profile!.name.substring(0, 1))),
            title: Text(c.profile!.name, style: t.titleLarge),
            subtitle: Text(c.isParent ? 'Parent' : 'Teen · ${c.profile!.age}'),
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
              if (!c.preview && c.deviceLock != null) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.pin_outlined),
                  title: const Text('Change PIN'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => c.deviceLock!.lock(changePin: true),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Lock now'),
                  onTap: () => c.deviceLock!.lock(),
                ),
              ],
              if (c.preview)
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
        const SectionHeading('About'),
        Surface(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Your data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const DataPrivacyScreen()),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (c.preview)
          TextButton.icon(
            onPressed: () async {
              if (await confirmAction(
                context,
                title: 'Reset sample data?',
                body:
                    'Your changes will be replaced with the original transactions, budgets, goals and family connection.',
                action: 'Reset data',
              )) {
                await c.resetDemo();
              }
            },
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset sample data'),
          ),
        if (!c.preview) AccountActions(c),
        AppError(c),
        const SizedBox(height: 32),
        Text('Bachat by YouthPay', style: t.bodySmall),
      ],
    );
  }
}

Future<void> accountSheet(BuildContext context, AppController c) =>
    showModalBottomSheet<void>(
      context: context,
      sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : null,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => !c.preview
          ? AccountDetails(c)
          : SheetBody(
              children: [
                Text(
                  'Switch profile',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
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
                        subtitle: Text(
                          role == UserRole.teen ? 'Teen · 16' : 'Parent',
                        ),
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
      sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : null,
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
                await c.run(() => c.setTheme(entry.key));
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
            onSelected: role == UserRole.parent ? null : (_) => onChanged(role),
            tooltip: role == UserRole.parent
                ? 'Parent accounts are coming soon'
                : null,
          ),
        )
        .toList(),
  );
}
