# Screenshot reference revamp — October 26, 2026

The owner requested a complete UI and layout revamp based on the attached phone image, retaining Instrument Sans for interface text and FK Grotesk for main figures. This supersedes earlier palette and font guidance in historical redesign documents.

## Implementation

The screenshot is interpreted at approximately 390 logical pixels of phone content width. Measurements are estimates from an image rather than exact Figma values. Existing Flutter/Riverpod widgets, bundled fonts, money records and native controls are retained.

| Reference element | Implementation |
| --- | --- |
| Cobalt light at the upper left | Shared radial backdrop across the shell, onboarding, auth and privacy journeys |
| Near-black canvas and charcoal cards | Semantic dark theme, #08090D canvas and #18191D card surfaces |
| Compact Home pill and round controls | Home identity pill, functional Plan and account controls |
| Large, centered spending figure | FK Grotesk regular at 48 logical pixels, in PKR |
| Fine white spending chart | Cumulative daily expenses for the current month; excludes income and savings |
| Compact budget ring | Actual spending against this month's budgeted categories; empty and over-budget states |
| Horizontal category cards | 164 logical pixel cards with category icons, actual spending and remaining category budgets |
| Circular bottom actions | Functional Receive and Spend controls on mobile Home |
| Rounded controls throughout | Shared themes for fields, sheets, buttons, chips, navigation and surfaces |

Hard-coded planner progress, fallback budget amounts and the fabricated monthly comparison have been removed. The comparison uses actual previous-month spending; accounts without prior spending show a factual current-month label. Sample records are visibly labeled Demo. Authenticated accounts retain their existing records and empty states.

## Adaptations

- Bachat's five navigation destinations remain reachable through a rounded bottom bar, or a rail on wide screens. The reference does not specify these destinations or a tablet layout.
- PKR formatting, the Bachat identity and supported category names replace the reference's foreign currency and labels.
- Wallet integrations and receipt scanning are unavailable, so the interface uses working Plan, account and manual entry actions.
- The spending line follows actual daily totals rather than reproducing the reference's decorative curve.
- Light appearance remains supported. Dark is the default only when no appearance has been saved.
- Existing accessible empty, error, loading, keyboard and text-scaling behavior is retained. No speculative backend features are introduced.

## Visual review

Flutter captures use isolated in-memory sample records and load both requested fonts. The phone captures are 390 × 844 logical pixels; wide captures are 1100 × 844. All five destinations are captured in both appearances under `docs/screenshots/ux/aesthetics-*`. Home, Activity, Plan, You and wide Home were visually reviewed against the supplied reference's palette, spacing, typography and surface treatment. The app does not reproduce the reference's physical phone bezel or system status bar.

The existing tests also exercise 320-pixel layouts at 200% text, short landscape screens, navigation breakpoint state, money forms, PIN privacy and appearance persistence failures. iOS device verification requires macOS and has not been performed in this Windows workspace.

## Reproduce

```powershell
. ./scripts/env.ps1
flutter analyze --no-pub
flutter test --no-pub test tool/aesthetics_preview_test.dart
flutter build apk --debug
```

Work is isolated in `bachat-reference-ui` on `feat/reference-ui-complete` because the original checkout was concurrently switched and reset during implementation. Each implementation step and follow-up fix has its own commit.

## Final verification

- `flutter analyze --no-pub`: no issues.
- Dart formatting for changed sources and `git diff --check`: pass.
- `flutter test --no-pub test tool/aesthetics_preview_test.dart`: all 99 checks pass.
- `flutter build apk --debug`: pass; local artifact at `build/app/outputs/flutter-apk/app-debug.apk`. SDK XML and Java 8 deprecation warnings remain toolchain warnings.
- iOS: not built or device-tested on this Windows host.
- [Pull request #17](https://github.com/saim-x/bachat-mobile/pull/17).

The merge from main resolves duplicated floating-action edits without changing the verified implementation tree.
