# Verification evidence

## Palette contrast

| Actual semantic pair | Contrast |
|---|---:|
| Light body on canvas | 13.38:1 |
| Light secondary on white | 5.12:1 |
| Light button text | 7.85:1 |
| Dark body on canvas | 15.68:1 |
| Dark secondary on surface | 8.29:1 |
| Dark button text | 7.94:1 |

Ratios calculated from sRGB relative luminance using WCAG contrast arithmetic. These text pairs exceed 4.5:1. This is not a claim that every state and generated Material color has been audited.

## Verified locally

- Flutter analyzer: clean.
- 19 domain, repository, controller, and widget tests cover entry validation, budgets/goals, offline queue coalescing and in-flight edits, account isolation, offline sign-out cleanup, parent restrictions, and approval gates.
- Web release compilation passes. Debug preview runs at http://127.0.0.1:8080.
- Android arm64 debug APK compiled successfully on Windows at `build/app/outputs/flutter-apk/app-debug.apk`; universal debug APK builds also pass in GitHub Actions.
- Chrome mobile-viewport smoke checks reached onboarding, teen dashboard, transaction form, Plan, and Learn; screenshot inspection checked the rendered teen dashboard.
- Live Supabase transactional authorization tests pass; fixture rollback confirmed zero test profiles remain.

## External or platform-specific validation

- Google provider credentials and redirects are pending the owner’s setup; live Google login has not been verified.
- iOS compile/signing/device checks require the Mac team.
- Android debug APK compilation passed in GitHub Actions (PR #1). Physical Android device testing has not been performed.

## Screenshots

Captured from the running debug app in Chrome at 390 × 844. Dashboard screenshots contain clearly marked sample data.

| Onboarding | Teen home | Parent home |
|---|---|---|
| ![Onboarding](screenshots/onboarding.png) | ![Teen dashboard](screenshots/teen-home.png) | ![Parent dashboard](screenshots/parent-home.png) |

| Budgets and goals | Learning placeholder |
|---|---|
| ![Planning screen](screenshots/plan.png) | ![Learning screen](screenshots/learn.png) |
