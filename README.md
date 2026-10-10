# Bachat Mobile

A standalone Flutter app for Android and iOS. The existing Next.js project remains in `../bachat`.

## Run locally

Flutter **3.47.7 / Dart 3.13.5** is the verified toolchain. Dependencies are locked in `pubspec.lock`.

```powershell
# This workspace has an isolated Flutter SDK and dependency cache.
.\scripts\dev.ps1
# Phone-sized preview: http://127.0.0.1:8080
# Select Skip introduction → Preview teen / Preview parent.
```

For other machines:

```sh
flutter pub get
cp config/env.example.json config/dev.local.json
# Set the project's public URL/publishable key; ENABLE_PREVIEW=true is optional.
flutter run -d chrome --web-port=8080 --dart-define-from-file=config/dev.local.json
flutter run -d <android-device-id> --dart-define-from-file=config/dev.local.json
```

Preview is available only in debug builds with `ENABLE_PREVIEW=true`. It uses sample data and never substitutes for real authentication or server permissions. Reloading returns to sign-in.

## Included

- Three-step introduction, teen/parent role selection, Google OAuth integration, profile setup.
- Mandatory mutual parent approval using single-use, hashed, 24-hour family codes; five failed attempts trigger a 15-minute lockout.
- Teen dashboard, manual income/expense creation, editing and deletion, searchable activity.
- Category budgets, savings goals and editable saved totals; exact integer paisa throughout.
- Parents can connect multiple children and read each child's transactions, budgets, and goals.
- Learning coming-soon screen, family settings, light/dark/device theme, account-scoped sign-out cleanup.
- Local Sembast/IndexedDB storage, durable outbox, reconnect synchronization, and family status polling/realtime updates.
- Bundled DM Sans, native semantics, scrollable forms, and minimum-size controls.

## Backend

Private repository: https://github.com/saim-x/bachat-mobile

Development Supabase project: **bachat-mobile-dev**, `mqpcxptgmqzwylldiotr`, Mumbai. Project creation was confirmed at $0/month. Schema is deployed; migration source and rollback-only authorization checks are in `supabase/`.

**Google OAuth still needs account configuration.** Google is disabled in the new project's authentication settings until its OAuth client credentials are supplied. See [backend setup](docs/BACKEND.md). Local config is ignored by Git; never add a service-role key to the mobile app.

## Verify

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
flutter build apk --debug --dart-define-from-file=config/dev.local.json
```

See [architecture](docs/ARCHITECTURE.md), [platform handoff](docs/PLATFORM-HANDOFF.md), [product brief](docs/PRODUCT-BRIEF.md), and [design system](docs/DESIGN.md).

## Development limits

The release is manual-entry only. Automatic bank/SMS/Gmail imports and learning content are deferred. Net flow is a calculation from entered records, not a bank balance. Offline family authorization uses the last verified relationship; cloud policies enforce current access on reconnect. Device storage relies on platform app isolation; auth sessions use secure storage. See the architecture document for synchronization behavior and release hardening.
