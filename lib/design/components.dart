import 'package:flutter/material.dart';

import 'theme.dart';
import 'brand.dart';

class BachatMark extends StatelessWidget {
  const BachatMark({super.key, this.large = false});
  final bool large;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      BachatSymbol(size: large ? 56 : 40),
      const SizedBox(width: 12),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'bachat',
              style: TextStyle(
                fontFamily: BachatBrand.headingFont,
                fontSize: large ? 32 : 25,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.1,
                height: 1.1,
              ),
            ),
            Text(
              'by YouthPay',
              style: TextStyle(
                fontSize: 12,
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
    this.tone,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool tinted;
  final Color? tone;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BachatRadii.surface),
      ),
      child: Material(
        color: tone ?? (tinted ? colors.primaryContainer : colors.surface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BachatRadii.surface),
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
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(BachatRadii.surface),
          ),
          child: Icon(
            icon,
            size: 30,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
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
      borderRadius: BorderRadius.circular(BachatRadii.compact),
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
    final color = Theme.of(context).colorScheme.outlineVariant
        .withValues(alpha: .5);
    Widget block(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(BachatRadii.control),
      ),
    );
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
      ),
    );
  }
}
