# Bachat Mobile

A standalone Flutter app for Android and iOS with a soft gray and green interface inspired by the supplied reference. DM Sans, rounded surfaces, pill actions and distinct teen/parent journeys.

Run with Flutter **3.47.7 / Dart 3.13.5**:

```powershell
. ./scripts/env.ps1
./scripts/dev.ps1
```

Preview: http://127.0.0.1:8080. Choose **Skip introduction**, then explore as **Ayesha** (teen, 16) or **Sana** (parent). Switch personas from **You**. Both share one persistent local demo family. No sign-in, environment configuration or internet connection is required after installation. Reset sample data from settings with confirmation.

On other machines:

```sh
flutter pub get
flutter run -d chrome --web-port=8080
flutter run -d <android-device-id>
```

Included: onboarding, spending dashboard, searchable transactions, exact paisa arithmetic, expense/income editing and deletion, monthly category budgets, savings goals, parent read-only dashboard, local mutual family approval, appearance settings and a coming-soon learning tab. Data persists in Sembast/IndexedDB across restarts and persona changes.

Authentication and cloud synchronization are deferred. Existing Supabase migrations and adapters remain available for future integration, but the demo startup never initializes Supabase and never uploads demo data. Historical backend instructions describe that future integration, not prerequisites for this demo.

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
flutter build apk --debug
```

Private repository: https://github.com/saim-x/bachat-mobile. See [current demo decisions](docs/DEMO-EXPERIENCE.md). iOS signing and device validation require the team's Mac. Automatic imports and learning content remain deferred. Recorded net flow is not a bank balance.
