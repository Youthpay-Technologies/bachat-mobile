# Simplified expense flow — October 26, 2026

## Confirmed changes

- Preserve the cobalt/charcoal layout, Instrument Sans workhorse font and FK Grotesk main figures.
- Keep Home, Activity and Plan. Use separate rounded circular navigation controls inspired by the supplied reference. Remove Learn and You from navigation.
- Open the entire profile section from the top-right Home profile icon, including appearance, PIN controls, account details, privacy and sign-out. Back returns to Home, and sign-out safely closes the profile route.
- Show only the transparent green-b/red-dot logo at Home's top left; remove the Home label, logo background and header Plan shortcut.
- Remove floating Receive/Spend actions. Preserve their inline forms above Recent activity and the existing Activity actions.
- Back from Activity or Plan returns to Home. Back from Home opens a confirmation before the Android exit call. Cancel keeps the app open.
- Adapt Home's monthly expense graph to the first recorded expense through today. Retain days without new expenses inside that range. A single recorded day is one point rather than a fabricated rising line. An empty account has an explicit first-expense cue.

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
