# Bachat

Bachat helps teens understand their spending, build realistic budgets, and save toward things that matter. The current release supports teen accounts; parent onboarding is disabled while family features are prepared for a later release.

This repository contains the standalone Flutter mobile app for Android and iOS. The initial release focuses on everyday money habits in English, using Pakistani rupees (PKR).

## What you can do

- Create an account, verify your email, sign in, and recover your password.
- Use separate Spend and Receive actions, each with relevant categories.
- Record, edit, and delete transactions with exact paisa amounts and custom Other tags.
- Type “savings” under Other to record money set aside, outside spending totals.
- Review monthly spending and category totals on the dashboard.
- Search activity, filter by date or category, and sort by date or amount.
- Set monthly category budgets and reuse missing categories from last month's plan.
- Create savings goals, add savings, and track progress toward each target.
- Sync your profile, transactions, budgets and goals across devices signed into the same account. Offline edits queue until reconnecting.
- Protect each device with its own 6-digit PIN, required when reopening Bachat.
- Switch between light, dark, and system appearance.
- See changes waiting to sync from every main screen and retry synchronization.
- Read how Bachat stores your data and view open-source licenses before signup or in You.

The learning tab is coming soon. Automatic bank, SMS, and Gmail imports are planned for later.

## Accounts and data

Choose **Continue as a teen**, then sign in or create an account. Verify your email and complete your name and age (13-18). New accounts start with empty records. Parent onboarding is greyed out; sample personas and profile switching are not exposed in the authenticated app.

Each device creates its own PIN after sign-in/profile setup. You can change it or lock immediately in You. A forgotten PIN requires signing out and authenticating again; unsynced changes are explicitly warned about before being discarded. PINs are never uploaded.

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

The helper preview runs at http://127.0.0.1:8080. The owner has retained the existing
Supabase project for the first Android release. Only public client configuration
ships with the app; other environments can override `SUPABASE_URL` and
`SUPABASE_PUBLISHABLE_KEY` with Dart defines. The hosted Auth default/allowlist now
uses the native callback, verified after the approved configuration update.
Confirmation/recovery links target Android; real inbox delivery is still unverified.
See [backend setup](docs/BACKEND.md) before changing hosted release settings.

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

The [ship-readiness report](docs/SHIP-READINESS.md) records verified app checks and
remaining public-launch service requirements. The existing Supabase project is
retained. Check local configuration and generated runtime artifacts with
`python scripts/check_ship_readiness.py` (Python 3.11+). Add `--check-backend` for
read-only Auth/anonymous-access/redirect probes; a passing local check does not
prove native callbacks or real email delivery are configured.

Work on a focused branch, commit each coherent change, and use a pull request for review and merging. Run the checks relevant to the change. Keep credentials, signing keys, personal records, and generated build files out of version control.

See [the working agreement](AGENTS.md), [product brief](docs/PRODUCT-BRIEF.md), [design system](docs/DESIGN.md), and [verification notes](docs/VERIFICATION.md).

For a visual walkthrough of the latest expense-tracking experience, open the [23-page app review PDF](docs/reports/Bachat-App-Review-2026-10-23.pdf). It includes onboarding, money forms, planning, account protection, light/dark appearance and large-text screenshots. See [report regeneration](docs/reports/README.md).
