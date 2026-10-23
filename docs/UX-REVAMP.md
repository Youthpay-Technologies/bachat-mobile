# Expense tracking experience revamp

## Scope and current architecture

The active application is `bachat-mobile`; `bachat-brand` is a separate earlier brand working copy. This review follows the runtime from `main.dart` through account/profile/PIN gates, all five dashboard tabs, transaction/budget/goal sheets, activity filters and account controls. Models use integer paisa; Riverpod owns application state; Sembast persists records and queued edits. Existing authentication, synchronization, device security and money rules remain the foundation.

Repository references: `AGENTS.md`, `PRODUCT-BRIEF.md`, `ARCHITECTURE.md`, `DESIGN.md`, `DESIGN-SKILLS.md`, existing widget tests and stored screenshots. Existing screenshots describe earlier revisions; fresh rendering is required before claiming visual verification of this work.

## Design direction

Keep the established cobalt, sunshine and tangerine identity and bundled typography. Make money tasks immediate, information easier to scan, and onboarding explain the app through small interactions. Use Flutter controls, semantic colors, visible labels, 48px targets, tabular amounts, natural text wrapping and restrained transitions. Respect reduced motion. Never display example money as account data.

## Ranked plan

| Priority | Evidence and user consequence | Improvement | Acceptance check |
| --- | --- | --- | --- |
| 1 | `presentation/app.dart`, WelcomeScreen: repeated static artwork, forward/skip only, returning users must pass introduction | Dedicated introduction with Back, direct sign-in, labeled step navigation, distinct spending/budget/goal previews and short reversible transitions | Continue, Back, Skip and sign-in work; preview state never reaches the controller; 320px/200% text and reduced motion work |
| 2 | `presentation/auth_screens.dart`: welcome authentication replaces the whole introduction without an exit; create-account password uses Done despite a following confirmation in recovery | Native auth route with Back, clear account/profile progress, correct keyboard actions, stable form state | Existing sign-in/recovery/profile tests pass; Back returns to the chosen introduction step |
| 3 | `presentation/app.dart`, PageBody: fixed page padding and no keyboard dismissal or always-scrollable refresh | Shared responsive gutters, stable page scroll identity and drag-to-dismiss keyboard | Home refresh works with short content; tab scroll/search state survives switching |
| 4 | `design/brand_panels.dart`, SpendingHero: fixed promotional footer supplies no monthly context | Show recorded-entry context and keep the spending figure dominant | Empty and populated monthly summaries describe actual recorded data; no bank-balance claim |
| 5 | `presentation/app.dart`, HomePage: three passive empty states ask users to find another screen | Add contextual first-expense, first-goal and budget actions; recent activity precedes detailed category analysis | Every empty-state action opens the correct existing sheet; parent views remain read only |
| 6 | `presentation/app.dart`, EntryTile: income/expense/savings rely on signs and similar icons; savings shares expense minus notation | Explicit direction labels, intentional category tiles, aligned tabular amounts and readable dates | Income, expense and savings can be distinguished without color; long names and amounts wrap |
| 7 | `presentation/app.dart`, ActivityPage: filtering changes list without a result summary | Result count and totals computed from the visible records | Search/direction/date/category filters update the displayed count and sums together |
| 8 | `presentation/forms.dart`: keyboard navigation is implicit; long category dropdowns use default sizing | Explicit Next actions, expanded wrapping category menus, useful amount hint and labeled optional details | Spend/Receive/edit/savings flows retain exact money validation; keyboard and 200% text remain usable |
| 9 | `presentation/app.dart`, PlanPage/GoalCard: progress bars lack a consistent spoken summary | Named progress with saved/spent and target values; month context for budgets | Screen readers receive meaningful budget/goal descriptions; over-budget labels remain visible |
| 10 | `design/theme.dart` and shared surfaces: control rhythm and surface separation vary | Consistent control padding, subtle surface outlines, coherent selected icons, destructive button treatment | Both themes, focus, text contrast and narrow layouts checked |

## Implementation sequence and commit policy

1. Commit this audit and plan.
2. Build and verify interactive onboarding, then commit it.
3. Improve authentication and profile handoff, then commit it.
4. Polish shared layouts and everyday Home/Activity/Plan surfaces, then commit it.
5. Improve entry ergonomics and destructive affordances, then commit it.
6. Record validation and remaining device checks, then commit it.

Each coherent change and each subsequent fix receives its own commit on `feat/expense-experience-revamp`. Run format/analyze and relevant widget tests before committing code. No new dependencies are needed.

## Review coverage and verification

Accessibility, layout, writing, typography, color and polish are reviewed through the corresponding better-* skills adapted to Flutter. Source inspection establishes implementation findings only. Runtime claims require fresh Flutter checks. Planned checks include the full existing suite, onboarding navigation/interaction tests, 320px at 200% text in both themes, reduced-motion behavior, web compilation and Android compilation where the environment permits. iOS device/signing verification requires macOS.

## Deferred proposals

Do not enable parent registration, invent learning content, add bank integrations, change authentication rules or add chart/animation packages as part of this UI work. Persisting introduction completion and user research on budget discovery can be evaluated separately; neither is required to give returning users a direct sign-in path.
