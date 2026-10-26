# Developing Bachat

Technical setup and contribution notes for the mobile team. For a product walkthrough and the private Android tester build, start with the [app showcase](../README.md).

## Accounts and storage

The current release supports verified teen accounts (ages 13–18); parent registration is disabled. New accounts start empty. Each device has its own six-digit PIN, available through the Home profile icon. PINs are not uploaded. A forgotten PIN requires signing out and authenticating again, with a warning before unsynced changes are discarded.

Supabase Auth manages sessions. PostgreSQL row-level security restricts money records to their verified teen owner. Edits are saved locally, then synchronized when a connection is available. Linked receipt allocations synchronize atomically; see [receipt accounting and verification](RECEIPT-SAVINGS.md). Signing out clears the local account cache after warning about pending edits.

Email confirmation and recovery need hosted email delivery and allowed redirects. See [backend setup](BACKEND.md). Available money is manually reconciled cash, not a bank balance.

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
See [backend setup](BACKEND.md) before changing hosted release settings.

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

The [ship-readiness report](SHIP-READINESS.md) records verified app checks and
remaining public-launch service requirements. The existing Supabase project is
retained. Check local configuration and generated runtime artifacts with
`python scripts/check_ship_readiness.py` (Python 3.11+). Add `--check-backend` for
read-only Auth/anonymous-access/redirect probes; a passing local check does not
prove native callbacks or real email delivery are configured.

Work on a focused branch, commit each coherent change, and use a pull request for review and merging. Run the checks relevant to the change. Keep credentials, signing keys, personal records, and generated build files out of version control.

See [the working agreement](../AGENTS.md), [product brief](PRODUCT-BRIEF.md), [design system](DESIGN.md), and [verification notes](VERIFICATION.md).
