# Simplified expense flow — October 26, 2026

## Confirmed changes

- Preserve the cobalt/charcoal layout, Instrument Sans workhorse font and FK Grotesk main figures.
- Keep Home, Activity and Plan. Use plain icons within one compact pill-shaped surface, with full-radius corners and no extra bottom gap beyond the system safe area. Remove Learn and You from navigation.
- Open the entire profile section from the top-right Home profile icon, including appearance, PIN controls, account details, privacy and sign-out. Back returns to Home, and sign-out safely closes the profile route.
- Show only the transparent green-b/red-dot logo at Home's top left; remove the Home label, logo background and header Plan shortcut.
- Remove floating Receive/Spend actions. Preserve their inline forms above Recent activity and the existing Activity actions.
- Back from Activity or Plan returns to Home. Back from Home opens a confirmation before the Android exit call. Cancel keeps the app open.
- Home plots timestamped cumulative expenses on an initial trailing 24-hour axis. When the current-month expense history grows beyond a day, the axis expands to its full elapsed span. Hour/date tick labels show the actual time range; a new user is no longer represented by a centered single point.

## Setup and tracked available money

Setup is optional. Home and Plan offer a budget or savings goal, followed by the available-money sheet when using the guided buttons. Existing users with a plan can enter available money directly. The expense forms remain available before setup is complete.

The user confirmed that both expenses and savings should reduce available money. A checkpoint stores:

- `amount_minor`: cash the user says they can spend now, excluding existing savings.
- `ledger_net_minor`: recorded income minus expenses, savings entries and saved goal amounts at the time of reconciliation.

Tracked available money = entered amount + current ledger net - checkpoint ledger net.

All arithmetic uses integer paisa. Past activity is not deducted twice, budgets do not reserve cash, and reconciling cash does not create an income transaction. Later entry edits, deletion, received money and savings changes update the tracked amount. Existing goal savings are included in the checkpoint baseline. Users should record each savings addition once, either as a savings entry or on the goal. Zero checkpoints are valid; a later negative tracked amount is displayed with a review prompt rather than hidden or clamped.

## Storage and authorization

Migration `20261026154524_available_cash_balance.sql` adds one `cash_balances` record per profile. It uses the existing account snapshot, durable outbox, pending-write overlay, session guards and Realtime refresh. The checkpoint persists across restarts and syncs across devices using the existing last-uploaded-record behavior.

The table's RLS follows the verified-teen ownership rules. Anonymous access is revoked; authenticated users have SELECT, INSERT and UPDATE only. Checks prevent ownership reassignment and invalid entered amounts. No existing money rows are rewritten. The migration was applied to the configured development project after a dry run and rollback-only authorization checks. The same authorization suite passed against the deployed table; fixtures are rolled back.

## Verification

The test suite covers exact amounts, zero, negative remaining money, historical baselines, transaction edits/deletions, savings, reconciliation, restart persistence, three-item navigation, full profile routing, sign-out, guided setup, and confirmed exit. Existing 320px/200% text, short landscape, search/filter, budget reuse, privacy and PIN checks are retained.

Visual captures cover phone and wide layouts in both appearances, plus empty Home, first-day Home, available-money setup and exit confirmation at normal and 200% text. Captures use isolated in-memory records and bundled fonts. See `docs/screenshots/ux/aesthetics-*` and `docs/screenshots/ux/simplify-*`.

The connected NOTE 23 receives the debug APK using an in-place update; no app data is cleared. iOS remains unverified on this Windows host. The existing Auth leaked-password-protection warning remains unrelated to this change; database security advisors report no errors.

Reproduce:

```powershell
. ./scripts/env.ps1
flutter analyze --no-pub
flutter test --no-pub test tool/aesthetics_preview_test.dart tool/simplify_preview_test.dart
flutter build apk --debug --no-pub
```

## Final results

- All 109 combined unit, widget and visual-capture checks pass.
- `flutter analyze --no-pub`: no issues. Formatting for all changed Dart files and `git diff --check` pass.
- Android debug APK build passes. The connected NOTE 23 is updated in place and the app launches successfully; installed APK content is checked against the local build.
- The live migration and rollback-only owner/other-owner/unverified/parent authorization checks pass. Database security advisors report no errors.
- Current renders cover all three destinations plus the profile route at 390px and 1100px in both appearances, and six new-user/setup/exit states at 390px and 320px with 200% text.
- iOS build and physical-device testing remain unverified on Windows.

These changes continue [PR #17](https://github.com/saim-x/bachat-mobile/pull/17), preserving the original reference revamp and its commit history.

The subsequent owner clarification supersedes the earlier single-day point and separate-circle navigation treatment. See [the corrected time-axis and appearance record](TIME-AXIS-AND-APPEARANCE.md).
