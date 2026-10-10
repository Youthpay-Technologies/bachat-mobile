import 'package:flutter/material.dart';

class BachatMark extends StatelessWidget {
  const BachatMark({super.key, this.large = false});
  final bool large;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: large ? 52 : 36,
        height: large ? 52 : 36,
        decoration: BoxDecoration(
          color: const Color(0xFF172D35),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          'YP',
          style: TextStyle(
            color: const Color(0xFFEBDDB5),
            fontWeight: FontWeight.w800,
            fontSize: large ? 20 : 14,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'bachat',
              style: TextStyle(
                fontSize: large ? 27 : 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
              ),
            ),
            Text(
              'by YouthPay',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.tinted = false,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool tinted;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(4, 6),
          ),
          BoxShadow(
            color: Colors.white.withValues(
              alpha: Theme.of(context).brightness == Brightness.light
                  ? 0.75
                  : 0.025,
            ),
            blurRadius: 12,
            offset: const Offset(-4, -4),
          ),
        ],
      ),
      child: Material(
        color: tinted ? colors.primaryContainer : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: BorderSide(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.white
                : colors.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: double.infinity,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 36, bottom: 18),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final heading = Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        );
        final button = action == null
            ? null
            : TextButton(onPressed: onAction, child: Text(action!));
        if (MediaQuery.textScalerOf(context).scale(14) > 20 ||
            constraints.maxWidth < 300) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [heading, ?button],
          );
        }
        return Row(
          children: [
            Expanded(child: heading),
            ?button,
          ],
        );
      },
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.onAction,
  });
  final IconData icon;
  final String title, body;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Surface(
    child: Column(
      children: [
        Icon(icon, size: 34, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 14),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (action != null)
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: OutlinedButton(onPressed: onAction, child: Text(action!)),
          ),
      ],
    ),
  );
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, this.icon, this.danger = false});
  final bool danger;
  final String label;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: danger
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 16,
            color: danger
                ? Theme.of(context).colorScheme.onErrorContainer
                : Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: danger
                  ? Theme.of(context).colorScheme.onErrorContainer
                  : Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ],
    ),
  );
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).colorScheme.outlineVariant.withValues(alpha: .5);
    Widget block(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
    );
    return Scaffold(
      body: SafeArea(
        child: Semantics(
          label: 'Loading Bachat',
          liveRegion: true,
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      block(48, 48),
                      const SizedBox(width: 16),
                      block(120, 20),
                    ],
                  ),
                  const SizedBox(height: 64),
                  Center(child: block(120, 16)),
                  const SizedBox(height: 16),
                  Center(child: block(210, 48)),
                  const SizedBox(height: 40),
                  block(double.infinity, 52),
                  const SizedBox(height: 48),
                  block(100, 20),
                  const SizedBox(height: 20),
                  block(double.infinity, 120),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
