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

## Delivered improvements

All ten plan items above have an implementation in this branch. The welcome screen now lives in `presentation/onboarding.dart`; the remaining work uses the existing theme, widgets and native routes. No dependency, database, financial calculation or authentication policy changed.

JUDGMENT: JUSTIFIED. The requested benefits are easier first use and more direct everyday expense tracking. The evidence is the original forward-only introduction, passive empty states, hidden filter totals and implicit keyboard actions. The solution adds one introductory screen module and one results-summary widget while reusing existing controllers and forms. Behavioral acceptance is covered by navigation, example-isolation, filtered-results and empty-state tests.

### Consolidated review

| Domain | Evidence inspected | Result |
| --- | --- | --- |
| Accessibility | `onboarding.dart`, `auth_screens.dart`, `forms.dart`, `GoalCard`, budget progress, native controls; reduced-motion and 320px/200% widget tests | Step names, progress labels, wrapping dropdowns and destructive treatment implemented; physical screen-reader and full keyboard traversal not verified |
| Layout | `PageBody`, Home, Activity, Plan, Learn, You and three introduction steps; 32 Flutter renders | Responsive gutters, preserved scroll identity, keyboard dismissal, wrapping amounts and result summaries implemented; render checks passed |
| Writing | Introduction examples, account/profile progress, recorded-spending context, direction labels, empty-state actions | Clear example-only scope, direct task verbs and recovery controls retained |
| Typography | Shared theme, bundled fonts, financial text styles; normal and doubled-text renders | Existing tabular amounts and native scaling retained; no financial value ellipsized by these changes |
| Color | Semantic color roles in shared surfaces, actions, savings previews and delete confirmations in both themes | Existing palette retained; destructive controls use error roles and labels; no new palette introduced |
| UI polish | Introduction switcher, native route handoff, selected navigation icons, surface outlines and action heights | 220ms transitions with instant reduced-motion state; no perpetual motion; consistent 54px minimum button heights |

| Severity | Domain | Location | Before | After | Why |
| --- | --- | --- | --- | --- | --- |
| MEDIUM | Layout | `presentation/app.dart:71` | Fixed gutters and implicit page scroll identity | Responsive gutters, per-tab storage keys and draggable keyboard dismissal | Narrow screens and repeated task navigation need usable space and retained context |
| MEDIUM | UI polish | `presentation/onboarding.dart:10` (previously WelcomeScreen in app.dart) | Repeated illustration and forward/skip only | Interactive examples, step controls, Back and direct sign-in | First use explains the actual money tasks and lets people navigate freely |
| MEDIUM | Writing | `presentation/auth_screens.dart:8` | No visible introduction-to-auth return; limited setup context | Native Back and account/profile progress | Users can recover their place and understand the remaining steps |
| MEDIUM | Writing | `presentation/app.dart:218` | Passive empty states and category analysis before recent entries | Direct expense/goal actions and recent activity first | Frequent actions are easier to discover and review |
| MEDIUM | Writing | `presentation/app.dart:522` | Filtered list without an aggregate | Count and totals from the same visible records | Filtering communicates the scope and effect of the results |
| MEDIUM | Accessibility | `presentation/app.dart:858`, `presentation/app.dart:1005` | Generic progress without goal/budget context | Named money context plus native numeric percentage | Spoken progress identifies what the amount belongs to |
| LOW | UI polish | `presentation/forms.dart:233`, `design/components.dart:169` | Delete/remove controls shared primary treatment | Labeled error-colored controls and confirmation | Consequential actions are easier to distinguish |

Resolved verification findings: the first animation implementation constrained outgoing content to the incoming height; real widget tests exposed the overflow and it was corrected in `ef17838`. Flutter's progress semantics require numeric values, so money descriptions moved into the accessible labels in `2233f75`. Test controller disposal is owned by Riverpod; duplicate test teardown was removed in `0122d80`.

### Verification on 23 October 2026

| Check | Result |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test tool/ux_preview_test.dart` using the installed Dart executable | Passed: 37 files unchanged |
| Dart analysis server, `analysis.setAnalysisRoots` on this project and `analysis.getErrors` on every edited Dart file | Passed: no diagnostics; the normal CLI's subprocess startup is blocked in this sandbox |
| Direct Flutter frontend compilation of the app and combined test entrypoint | Passed: zero compiler errors |
| Existing test files plus `onboarding_test.dart`, `expense_ux_test.dart`, and `tool/ux_preview_test.dart`, run with Flutter's actual `flutter_tester.exe` engine | Passed: **74 tests**, including 70 application tests and four rendering journeys; latest run completed in 47 seconds |
| Introduction Continue/Back/Skip, direct sign-in, account-route dismissal, example isolation, editable example budget and goal choice | Passed |
| Filtered counts/totals, empty Home goal action and empty Plan budget action | Passed |
| 390px normal text and 320px doubled text, both appearances, all five tabs and all three introduction steps | Passed: 32 generated PNGs, no Flutter exceptions |
| Manual image inspection | Home light, Activity light, Plan dark, introduction step 3 light, step 2 dark and Home light at doubled text inspected |
| `git diff --check` | Passed |
| Standard `flutter test` / `flutter analyze` launcher | Blocked: SDK-cache writes and child-process startup denied; direct SDK compiler/analyzer/test-engine execution used instead |
| Web release and Android APK builds | Not verified in this sandbox; standard Flutter build orchestration has the same access restriction |
| iOS signing/device release, physical TalkBack/VoiceOver and complete keyboard audit | Not verified |
| PR creation | Blocked: `gh auth status` reports invalid environment and stored GitHub tokens; commits remain on the local feature branch |

The fallback compiled `build/ux-review/run_all_tests.dart` with the installed `frontend_server_aot.dart.snapshot`, `--target=flutter`, `--sdk-root .../flutter_patched_sdk/` and a merged local SDK/project package configuration. It ran the resulting kernel through `flutter_tester.exe --disable-vm-service --enable-software-rendering --skia-deterministic-rendering --non-interactive --use-test-fonts --disable-asset-fonts --packages=build/ux-review/package_config.json --flutter-assets-dir=build/unit_test_assets build/ux-review/all-tests.dill`, with `FLUTTER_TEST=true`. This uses the installed test runner and real Flutter engine; it does not replace the application tests. Fallback entrypoints and logs stay in ignored build output.

Normal environments can repeat the checks with `flutter analyze`, `flutter test`, and `flutter test tool/ux_preview_test.dart`. Fresh preview artifacts are under [screenshots/ux](screenshots/ux/): [Home](screenshots/ux/home-light.png), [Activity](screenshots/ux/activity-light.png), [Plan](screenshots/ux/plan-dark.png), and [introduction](screenshots/ux/introduction-1-light.png). These use isolated sample records, not a live account.

Verdict: **Approve within the inspected source and automated rendering scope.** No remaining HIGH finding was observed there. Physical assistive-technology, complete keyboard traversal and release-platform verification remain outside this verdict.
