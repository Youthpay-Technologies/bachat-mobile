# UI Aesthetics revamp

Requested source: https://github.com/kasonye/ui-aesthetics-skill
Canonical instructions: https://github.com/kasonye/ui-aesthetics-skill/blob/main/SKILL.md
References read: rewrite-playbook, component-aesthetics, interaction-states, color-system.

## Direction

Medium restructure: calm everyday money tracking. Preserve the confirmed cobalt,
sunshine and tangerine brand, bundled fonts, teen-only release and every existing
money action. Improve composition before decoration; add no dependencies.

Home prioritizes monthly spending, entry actions and recent activity. Secondary
metrics use neutral surfaces. Activity groups search and filters above a clear
results ledger. Plan separates recorded savings, monthly limits and savings goals.
Shared page headers, tighter radius/spacing scales, neutral empty states, consistent
form controls and an anchored navigation bar unify the complete journey. Light
and dark themes use distinct neutral luminance steps and semantic accent roles.

Translate the source's web guidance into Flutter themes, constraints, native focus,
semantics and text scaling. Preserve reduced motion and explicit coming-soon states.

## Git and validation

Branch: feat/ui-aesthetics-revamp, based on the existing expense-experience branch
so its latest onboarding and money flows are preserved. Commit every individual
change immediately, including formatting, fixes, tests and documentation.

Verify with formatting, Flutter analysis, existing unit/widget tests, new responsive
journey coverage, visual renders and web/Android builds where available. iOS device
verification requires macOS. Push a PR to main and merge after checks when GitHub
access is available. At task start, Git network access fails and gh cannot authenticate;
local commits are possible. Do not report a PR or merge as completed without evidence.

## Verified result

Application source: `7525195` (later commits contain captures and documentation).
Flutter 3.47.7 / Dart 3.13.5, October 24, 2026.

| Check | Observed result |
| --- | --- |
| Dart formatting, lib/test/tool | 43 files, no changes |
| Dart analysis server, lib/test/tool | Zero diagnostics |
| All application unit/widget tests | 75 passed, zero failed |
| Dedicated visual journeys | Four passed; 20 screenshots |
| Optimized JavaScript compilation | Passed; 2,467,376 output characters |
| Git whitespace check | Passed |
| Android APK / iOS device build | Not verified in this session |

During the initial restricted session, the standard Flutter CLI could not launch child processes
(`CreateFile failed 5`, including its Git subprocess). Validation therefore used
the installed analysis server through its JSON protocol, the installed frontend
compiler, and the Flutter engine directly. A temporary runner in ignored build
output declared the unchanged test files through test_api, ran their setup,
tests and teardown sequentially, and reported each result. The final 75-test run
includes all 71 existing tests and four new responsive tests. These are actual
Flutter-engine test runs, rather than inspection-only checks. JavaScript was
compiled with the installed dart2js snapshot and Flutter web SDK; this is a
compilation check, not a packaged web deployment or a native build.

In a normal environment, reproduce with:

```sh
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test
flutter test tool/aesthetics_preview_test.dart
flutter build web --release
flutter build apk --debug
```

The responsive tests cover all five tabs at 320px with 200% text in both themes,
search and selected-tab persistence across navigation breakpoints, and access to
navigation in a short landscape viewport. Existing tests continue to cover account
setup, device PINs, transactions, budgets, goals, filtering and destructive flows.

## Visual review

The capture tool loads the bundled fonts and native icons and uses isolated
in-memory preview records. It makes no backend calls. Visually reviewed Home,
Activity, Plan, Learn and You across phone/wide and light/dark captures. The
initial review caught missing explicit font families on rail and chip labels;
the final captures include the correction. Historical screenshots and PDF reports
remain unchanged. Captures display preview-only account controls where applicable.

| Screen | Phone light | Phone dark | Wide light | Wide dark |
| --- | --- | --- | --- | --- |
| Home | [View](screenshots/ux/aesthetics-phone-home-light.png) | [View](screenshots/ux/aesthetics-phone-home-dark.png) | [View](screenshots/ux/aesthetics-wide-home-light.png) | [View](screenshots/ux/aesthetics-wide-home-dark.png) |
| Activity | [View](screenshots/ux/aesthetics-phone-activity-light.png) | [View](screenshots/ux/aesthetics-phone-activity-dark.png) | [View](screenshots/ux/aesthetics-wide-activity-light.png) | [View](screenshots/ux/aesthetics-wide-activity-dark.png) |
| Plan | [View](screenshots/ux/aesthetics-phone-plan-light.png) | [View](screenshots/ux/aesthetics-phone-plan-dark.png) | [View](screenshots/ux/aesthetics-wide-plan-light.png) | [View](screenshots/ux/aesthetics-wide-plan-dark.png) |
| Learn | [View](screenshots/ux/aesthetics-phone-learn-light.png) | [View](screenshots/ux/aesthetics-phone-learn-dark.png) | [View](screenshots/ux/aesthetics-wide-learn-light.png) | [View](screenshots/ux/aesthetics-wide-learn-dark.png) |
| You | [View](screenshots/ux/aesthetics-phone-you-light.png) | [View](screenshots/ux/aesthetics-phone-you-dark.png) | [View](screenshots/ux/aesthetics-wide-you-light.png) | [View](screenshots/ux/aesthetics-wide-you-dark.png) |

## Delivery status

Every source, test, documentation and individual screenshot change is committed
on `feat/ui-aesthetics-revamp`. The earlier expense-experience commits are
preserved in its ancestry, so PR #15 contains the combined onboarding and UI work.

GitHub access is restored. A stale GITHUB_TOKEN environment override was masking
the valid saved login; GitHub commands now use that saved login. The branch is
pushed and [PR #15](https://github.com/saim-x/bachat-mobile/pull/15) targets main.
The earlier sandbox/network blocker is resolved. Standard local Flutter analysis
also passes. GitHub Actions independently runs formatting, analysis, the complete
test suite, a release web build and a debug Android APK build. The live PR checks
and merge record are authoritative for final delivery status. Signed iOS and
physical-device verification remain outside this Windows session.
