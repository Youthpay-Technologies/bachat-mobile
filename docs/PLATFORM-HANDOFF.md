> Current release update: authentication is deferred. The app uses persistent, offline Ayesha/Sana demo personas with shared family data. See [demo experience](DEMO-EXPERIENCE.md). Cloud/OAuth descriptions below are retained for future integration.

# Platform handoff

## Windows / Android

The current workspace uses an isolated SDK under `E:/Projects/renaissance/YouthPay/.tools/flutter` with its own `pub-cache`, `android-sdk`, and `gradle-cache`. `scripts/dev.ps1` sets task-specific environment variables without changing global paths. Android Studio's bundled JDK is used for Android tooling.

Dot-source `. .\scripts\env.ps1` to expose the isolated tools in your current terminal. Android SDK 36, build tools 36, NDK 28.2, and accepted licenses are installed; `flutter doctor` reports the Android toolchain healthy.

Run `flutter devices`, then `scripts/dev.ps1 -Device <device-id>` to develop on a connected Android device. USB debugging and device authorization must be enabled on the phone. No emulator image is required for a physical device.

App ID currently follows the scaffold: `com.getyouthpay.bachat_mobile`. Display name is Bachat. Review final identifiers before store registration. OAuth custom scheme is `com.getyouthpay.bachat://auth/callback`.

Android debug compilation has passed in GitHub Actions and locally on Windows (arm64). The local APK is `build/app/outputs/flutter-apk/app-debug.apk`. The `bachat-debug-apk` artifact is available on successful workflow runs. Builds use the development project’s public URL/key from repository variables and expose the clearly labeled debug preview. No service-role key is present. Physical-device OAuth and offline/reconnect checks are still required.

## macOS / iOS

1. Install Flutter 3.47.7 and Xcode, select its command-line tools, and run `flutter doctor`.
2. Clone the private repository, run `flutter pub get`, and create `config/dev.local.json` from the example using public Supabase configuration.
3. Open `ios/Runner.xcworkspace`, select your Apple development team, and confirm a unique bundle identifier.
4. Run `flutter run -d <ios-device-id> --dart-define-from-file=config/dev.local.json`.
5. Check Google browser sign-in and callback, session restoration, Keychain storage, parent confirmation, offline edits, reconnect, text scaling, dark theme, and keyboard behavior.
6. Produce a signed archive with `flutter build ipa --dart-define-from-file=config/dev.local.json` once release settings are ready.

No iOS compile, signing, simulator, or device check was performed on this Windows machine. Committed iOS project files are the handoff, not proof of a tested iOS release.

## Before store release

Configure production Google OAuth, real-device end-to-end tests, release signing, app icons, store metadata, reviewed privacy/consent copy, an account-deletion mechanism, local financial-data protection, and recovery/support procedures. Assess Apple's sign-in requirements for the final login options. Disable debug preview in all release configuration. Learning should remain explicitly coming soon.

The existing YouthPay-style YP mark is used inside the app. The same mark is used in generated Android, iOS, and web launcher assets. Regenerate with `flutter test tool/generate_icons_test.dart`. Review final artwork before distribution.
