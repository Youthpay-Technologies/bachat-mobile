import 'package:flutter/material.dart';

import '../design/brand_panels.dart';
import '../design/components.dart';
import '../domain/models.dart';
import 'app.dart' show RoleChoices;
import 'auth_screens.dart';

/// Example interactions stay on this screen and never create account records.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int step = 0;
  String category = 'Food';
  double budget = 2000;
  String goal = 'A bicycle';

  void openAuth() => Navigator.of(
    context,
  ).push<void>(MaterialPageRoute(builder: (_) => const AuthScreen()));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reducedMotion
        ? Duration.zero
        : const Duration(milliseconds: 220);
    final titles = [
      ('Make money', 'make sense.'),
      ('Small habits.', 'Real progress.'),
      ('Your money.', 'Your way.'),
    ];
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) => SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 600,
                  minHeight: viewport.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.all(viewport.maxWidth < 360 ? 16 : 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const BachatMark(),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              if (step > 0)
                                IconButton(
                                  tooltip: 'Previous introduction step',
                                  onPressed: () => setState(() => step--),
                                  icon: const Icon(Icons.arrow_back_rounded),
                                ),
                              Expanded(
                                child: Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    'Step ${step + 1} of 3',
                                    style: theme.textTheme.labelLarge,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: List.generate(
                              3,
                              (index) => Expanded(
                                child: Semantics(
                                  label: 'Introduction step ${index + 1}',
                                  selected: index == step,
                                  child: Tooltip(
                                    message: 'Go to step ${index + 1}',
                                    child: InkWell(
                                      onTap: () => setState(() => step = index),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 21,
                                        ),
                                        child: AnimatedContainer(
                                          duration: duration,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: index <= step
                                                ? theme.colorScheme.primary
                                                : theme
                                                      .colorScheme
                                                      .outlineVariant,
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          AnimatedSwitcher(
                            key: const ValueKey('onboarding-transition'),
                            duration: duration,
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            layoutBuilder: (current, previous) => Stack(
                              alignment: Alignment.topLeft,
                              children: [
                                for (final child in previous)
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: IgnorePointer(
                                      child: ExcludeSemantics(child: child),
                                    ),
                                  ),
                                ?current,
                              ],
                            ),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: reducedMotion
                                      ? child
                                      : SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0.04, 0),
                                            end: Offset.zero,
                                          ).animate(animation),
                                          child: child,
                                        ),
                                ),
                            child: Column(
                              key: ValueKey(step),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Semantics(
                                  header: true,
                                  child: BrandHeadline(
                                    lead: titles[step].$1,
                                    accent: titles[step].$2,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(switch (step) {
                                  0 =>
                                    'Track the everyday. See where each rupee goes.',
                                  1 =>
                                    'Give your everyday spending a little direction.',
                                  _ =>
                                    'Save for something that matters to you.',
                                }, style: theme.textTheme.bodyLarge),
                                const SizedBox(height: 24),
                                Surface(
                                  tone: theme.colorScheme.secondaryContainer,
                                  child: preview(context),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (step == 2) ...[
                              RoleChoices(
                                value: UserRole.teen,
                                onChanged: (_) {},
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'For teens aged 13–18. Parent accounts are coming soon.',
                              ),
                              const SizedBox(height: 16),
                            ],
                            FilledButton.icon(
                              onPressed: step == 2
                                  ? openAuth
                                  : () => setState(() => step++),
                              icon: const Icon(Icons.arrow_forward_rounded),
                              label: Text(
                                step == 2 ? 'Continue as a teen' : 'Continue',
                              ),
                            ),
                            if (step < 2)
                              TextButton(
                                onPressed: () => setState(() => step = 2),
                                child: const Text('Skip introduction'),
                              ),
                            TextButton(
                              onPressed: openAuth,
                              child: const Text(
                                'Already have an account? Sign in',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget preview(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Try it · Example only', style: theme.textTheme.labelMedium),
        const SizedBox(height: 16),
        if (step == 0) ...[
          Text('Everyday spending, sorted', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Food', 'Rides', 'Fun']
                .map(
                  (value) => ChoiceChip(
                    label: Text(value),
                    selected: category == value,
                    onSelected: (_) => setState(() => category = value),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(switch (category) {
              'Food' => 'Lunch or a snack? Keep the little purchases in view.',
              'Rides' => 'Bus fares and rides, all in one place.',
              _ => 'A movie or a treat. Make room for the things you enjoy.',
            }),
          ),
        ] else if (step == 1) ...[
          Text('Find your monthly limit', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          Text('Rs ${budget.round()}', style: theme.textTheme.headlineMedium),
          Slider(
            value: budget,
            min: 500,
            max: 5000,
            divisions: 9,
            label: 'Rs ${budget.round()}',
            semanticFormatterCallback: (value) =>
                '${value.round()} rupees monthly budget',
            onChanged: (value) => setState(() => budget = value),
          ),
          const Text(
            'Move the slider. Your real budgets are always yours to set.',
          ),
        ] else ...[
          Text('What would you save for?', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['A bicycle', 'Headphones', 'Something else']
                .map(
                  (value) => ChoiceChip(
                    label: Text(value),
                    selected: goal == value,
                    onSelected: (_) => setState(() => goal = value),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(
              'Your choice: $goal. Start small and track each step toward it.',
            ),
          ),
        ],
      ],
    );
  }
}
