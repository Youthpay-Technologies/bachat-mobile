# Bachat

Bachat helps teens understand their spending, build realistic budgets, and save toward things that matter. Parents can follow their child's progress through a shared, read-only view while teens stay in control of their records.

This repository contains the standalone Flutter mobile app for Android and iOS. The initial release focuses on everyday money habits in English, using Pakistani rupees (PKR).

## What you can do

- Record, edit, and delete expenses and income, with exact paisa amounts.
- Review monthly spending and category totals on the dashboard.
- Search activity, filter by date or category, and sort by date or amount.
- Set monthly category budgets and reuse missing categories from last month's plan.
- Create savings goals, add savings, and track progress toward each target.
- Explore separate teen and parent journeys, including mutual family approval.
- Switch between light, dark, and system appearance.

The learning tab is coming soon. Android SMS transaction import is requested after onboarding for the teen persona and Gmail transaction import is available from Settings after Google OAuth is configured. SMS parsing uses bank-message heuristics, so support depends on the SMS format; iOS does not permit apps to read the SMS inbox.

## Current development experience

The app currently opens without authentication. Continue as **Ayesha**, a 16-year-old teen, or **Sana**, her parent. Switch profiles from the home header or **You** to explore both journeys.

Both profiles share one persistent local demo family. It starts with no sample transactions, budgets, or goals. Changes survive app restarts and profile switches; Settings includes a confirmed reset. Parent views cannot edit transactions, budgets, or goals. Family linking and approval can be explored locally, but do not verify real identities. SMS and Gmail imports stay on the device in this demo and are not uploaded to a server.

Authentication and cloud synchronization are deferred. Supabase migrations and adapters are retained for future integration; the current startup does not initialize Supabase or upload local records. Gmail sync requires Google OAuth client IDs and is not available without that configuration. Recorded net flow is not a bank balance.

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

Google Gmail setup and the Android OAuth build arguments are documented in [backend setup](docs/BACKEND.md). In the original Windows workspace, helper scripts use the prepared local toolchain:

```powershell
. ./scripts/env.ps1
./scripts/dev.ps1
```

The helper preview runs at http://127.0.0.1:8080. No sign-in or Supabase environment configuration is needed for the current local experience.

## Project structure

| Directory | Purpose |
| --- | --- |
| `lib/domain` | Money models, calculations, and activity filtering |
| `lib/application` | App state, profile journeys, and business rules |
| `lib/data` | Local persistence and future backend adapters |
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
