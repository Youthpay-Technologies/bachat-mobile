# Bachat

Bachat helps teens understand their spending, build realistic budgets, and save toward things that matter. The current release supports teen accounts; parent onboarding is disabled while family features are prepared for a later release.

This repository contains the standalone Flutter mobile app for Android and iOS. The initial release focuses on everyday money habits in English, using Pakistani rupees (PKR).

## What you can do

- Create an account, verify your email, sign in, and recover your password.
- Record, edit, and delete expenses and income, with exact paisa amounts.
- Review monthly spending and category totals on the dashboard.
- Search activity, filter by date or category, and sort by date or amount.
- Set monthly category budgets and reuse missing categories from last month's plan.
- Create savings goals, add savings, and track progress toward each target.
- Keep your records in your own Supabase account, with offline edits queued for synchronization.
- Switch between light, dark, and system appearance.

The learning tab is coming soon. Automatic bank, SMS, and Gmail imports are planned for later.

## Accounts and data

Choose **Continue as a teen**, then sign in or create an account. Verify your email and complete your name and age (13-18). New accounts start with empty records. Parent onboarding is greyed out; sample personas and profile switching are not exposed in the authenticated app.

Supabase Auth manages sessions. PostgreSQL row-level security restricts transactions, budgets, and savings goals to their verified teen owner. Edits are saved locally before the screen updates, then synchronized when a connection is available. Signing out clears this device's account cache; a confirmation warns about unsynced changes.

Email confirmation and password recovery require working hosted email delivery and allowed redirect URLs. See [backend setup](docs/BACKEND.md) for the current deployment requirements. Recorded net flow is not a bank balance.

## Get started

Use Flutter **3.47.7** with Dart **3.13.5**, matching CI. Install Android tooling for Android development, or Xcode on macOS for iOS.

```sh
flutter pub get
flutter devices
flutter run -d <device-id>
```

For a browser preview:

```sh
flutter run -d chrome --web-port=8080
```

In the original Windows workspace, helper scripts use the prepared local toolchain:

```powershell
. ./scripts/env.ps1
./scripts/dev.ps1
```

The helper preview runs at http://127.0.0.1:8080. The app uses the development Supabase project by default. Only public client configuration ships with it; other environments can override `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` with Dart defines. Hosted auth configuration and email delivery must be completed before testing email links.

## Project structure

| Directory | Purpose |
| --- | --- |
| `lib/domain` | Money models, calculations, and activity filtering |
| `lib/application` | App state, profile journeys, and business rules |
| `lib/data` | Account snapshots, persistent outbox, and Supabase access |
| `lib/design` | Shared theme and interface components |
| `lib/presentation` | Screens, navigation, forms, and sheets |
| `test` | Domain, repository, controller, and widget checks |
| `supabase` | Migrations and backend integration resources |
| `docs` | Product decisions, architecture, design, and verification |

The app uses Riverpod for state management and Sembast / IndexedDB for local persistence. Financial amounts are stored as integer minor units to avoid floating-point rounding errors.

## Check and build

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
flutter build apk --debug
```

Android and web builds are verified locally. iOS signing and device testing require the team's Mac and Apple development setup.

## Contributing

Work on a focused branch, commit each coherent change, and use a pull request for review and merging. Run the checks relevant to the change. Keep credentials, signing keys, personal records, and generated build files out of version control.

See [the working agreement](AGENTS.md), [product brief](docs/PRODUCT-BRIEF.md), [design system](docs/DESIGN.md), and [verification notes](docs/VERIFICATION.md).
