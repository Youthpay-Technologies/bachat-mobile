# Platform handoff

## Android and Windows

The current workspace uses Flutter 3.47.7 / Dart 3.13.5 under `E:/Projects/renaissance/YouthPay/.tools/flutter`, with an isolated pub cache, Android SDK and Gradle cache. `scripts/env.ps1` configures the current terminal; `scripts/dev.ps1` starts the browser preview or a chosen device.

```powershell
. ./scripts/env.ps1
./scripts/dev.ps1
# Or: ./scripts/dev.ps1 -Device <android-device-id>
```

The app initializes Supabase by default. No demo flag or local JSON is required. `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` may be overridden with Dart defines for another environment; never pass a secret/service-role key.

The debug APK is `build/app/outputs/flutter-apk/app-debug.apk`. Physical Android testing remains separate from successful compilation. App ID: `com.getyouthpay.bachat_mobile`; review identifiers before store registration.

## iOS

1. Install Flutter 3.47.7 and Xcode on macOS; run `flutter doctor`.
2. Clone the repository and run `flutter pub get`.
3. Open `ios/Runner.xcworkspace`, choose the Apple development team and confirm the bundle ID.
4. Run `flutter run -d <ios-device-id>`.
5. Verify email confirmation/recovery callbacks, secure session restoration, keyboard/safe-area layouts, offline edits and reconnect on a real device.

The callback scheme is `com.getyouthpay.bachat://auth/callback`. Flutter's default deep-link handler and Supabase's automatic callback handler are disabled; the app installs its auth listener before processing initial/live links. Verified universal links should be considered before a public store release.

## Hosted requirements

Complete [hosted Auth configuration and email delivery](BACKEND.md) before testing signup/confirmation/recovery with a real inbox. Parent onboarding is disabled. The old local Next.js app was removed at the owner's request; brand assets remain in the sibling brand folder.

A signed iOS build and physical-device validation have not been performed in this Windows environment.
