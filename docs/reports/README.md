# Latest app visual report

[Open the 23-page Bachat app review](Bachat-App-Review-2026-10-23.pdf).

The report contains 43 screenshot placements selected from 78 fresh Flutter captures. It covers the interactive introduction, sign-in and recovery, profile setup, device PINs, Home, Spend/Receive, editing/deleting, Activity search and filters, budgets, savings goals, account settings, both appearances and 320px layouts at 200% text. Captions identify scrolled views and explain the current behavior.

The app source shown is commit `698865d`. Later commits add capture tooling, screenshots and this report. All displayed names and money are isolated examples. Account and PIN screenshots use a mocked HTTP client and in-memory storage; no real account, mailbox or backend was accessed. The report shows the authenticated account settings separately from preview-only profile tools.

## Verification

- Standard Flutter runner: **71 application tests passed**.
- Explicit render checks: **6 journeys passed**, producing 78 PNGs at 2x resolution.
- `flutter analyze`: no issues; Dart formatting: 40 files unchanged.
- Release JavaScript web build and Android debug APK: passed.
- PDF validation: 23 pages, 43 screenshot placements, searchable text, 23 navigation bookmarks and all text inside page bounds. A rendered contact sheet and selected full pages were visually inspected.
- iOS signing, physical-device use and a complete assistive-technology audit remain unverified. The web build reported existing Wasm incompatibility in the secure-storage plugin; the JavaScript build succeeded.

## Regeneration

From the project root with Flutter available:

```sh
flutter test tool/ux_preview_test.dart tool/account_preview_test.dart
python scripts/generate_ui_report.py --verification docs/reports/verification-2026-10-23.json
```

The Python generator requires ReportLab and embeds the project's licensed fonts. Update the verification JSON with the current source revision and observed check results before regenerating; the generator does not run those checks itself. An alternate PDF path can be supplied with `--output`.

The screenshot tools never submit the pictured draft money forms. The deletion preview dismisses its confirmation. Existing screenshot names are overwritten so the PDF draws from the latest captures. PNGs are kept under [screenshots/ux](../screenshots/ux/).
