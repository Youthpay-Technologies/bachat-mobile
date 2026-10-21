# Mobile brand redesign verification

## Scope and integration

Worktree: `bachat-brand`, branch `feat/cobalt-brand-redesign`. The redesign includes updated `main` at `4269e64`, preserving the merged authentication, synchronization and test work. Its original checkout was not edited. The deprecated Next.js project is outside this change.

The integration target is `main`. Authentication PR #9 has merged; incorporating its main-branch merge adds ancestry without changing the application files used for the completed validation below.

## Delivered identity

- New code-native lowercase-b symbol and Bachat / YouthPay wordmark.
- Exact cobalt #0C38A9, sunshine #FFDE59 and tangerine #FF751E primitives with semantic light/dark themes.
- Bundled Instrument Sans headings, Inter interface text and selective Instrument Serif Italic editorial accents. Instrument Serif regular is included too. All requested families and their open font licenses ship offline.
- Tabular financial figures, flat surfaces, navigation, fields, badges, loading and empty states.
- Editorial onboarding, static habit illustration, spending hero, sunshine savings cards and revised Learn presentation.
- Android/iOS launcher icons and Flutter preview icons/install metadata.

`pubspec.yaml` and Flutter's generated font manifest register each family correctly. The installer only edits the top-level font list, preserving nested face declarations.

## Verification

Final checks use the normal Flutter 3.47.7 / Dart 3.13.5 CLI with the requested fonts bundled.

| Check | Result |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test tool` | Passed |
| `flutter analyze --no-pub` | Passed, no issues |
| `flutter test --no-pub` | 52 passed |
| `flutter build apk --debug --no-pub` | Passed; debug APK built |
| `flutter build web --release --no-pub` | Passed; release web preview built |
| `git diff --check` | Passed |
| PowerShell font installer parser | No syntax errors |
| APK font payload audit | All four requested font faces and three licenses present; legacy DM Sans excluded |
| Real Flutter renders with bundled typography | 26 completed, no Flutter exceptions |
| Launcher generation | Canonical painter rendered all 25 icon files |

The renders cover Welcome, Home/navigation, Activity, Plan, Learn and Settings in both themes, each at 390px / normal text and 320px / doubled text, plus both parent dashboards. The large-text spending panel was visually checked and refined to keep the amount readable. These artifacts use local preview records, not a live authenticated account. See [light home](screenshots/brand/home-light.png), [dark home](screenshots/brand/home-dark.png), [large-text home](screenshots/brand/home-light-large-text.png), [welcome](screenshots/brand/welcome-light.png) and [all renders](screenshots/brand/).

The upstream workflow keeps Android compilation required on PRs and makes APK artifact uploads opt-in. Its latest configuration was preserved when resolving the concurrent CI edit; the redesign does not change it.

## Measured contrast

Ratios were computed using WCAG relative luminance from the declared opaque foreground/background pairs. They do not substitute for a platform screen-reader or keyboard audit.

| Pair | Ratio |
| --- | --- |
| White / cobalt action and spending panel | 9.75:1 |
| Light primary text / white surface | 15.51:1 |
| Light secondary text / white surface | 5.95:1 |
| Light field outline / white surface | 3.94:1 |
| Light secondary action / primary container | 8.47:1 |
| Light savings label / savings container | 9.20:1 |
| Dark primary text / surface | 14.34:1 |
| Dark secondary text / surface | 8.83:1 |
| Dark primary action text / fill | 8.60:1 |
| Dark secondary action / primary container | 8.84:1 |
| Dark savings label / savings container | 9.30:1 |

## Platform boundaries

iOS builds and signing require macOS/Xcode and were not verified here. The Android result is a debug build, not release-signing verification. Screen-reader behavior and a complete keyboard audit remain outside the completed automated checks. Native Flutter controls, accessible names, field labels and reduced-motion handling are retained.
