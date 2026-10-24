# Bachat ship readiness

Scope: application readiness for the first Android launch, using the existing
Supabase project. Play Store submission, signing and release APK creation are
excluded. The owner confirmed the existing project should be reused and that
support email/domain details are not yet available.

Skill: https://www.skillsdirectory.com/skills/forgeyclap-ship-readiness
Canonical: https://github.com/ForgeyClap/claude-forge/blob/main/.claude/skills/ship-readiness/SKILL.md

The skill is advisory: assess pass/fail with evidence. Its Forge verification and
secret-scrub executables are not installed in this Flutter repository; run their
requested commands and record unavailability rather than manufacturing a Forge
run or claiming those checks passed. Use app-native analysis, regression tests,
readiness checks and a source/runtime-artifact secret scan as additional evidence.

## Confirmed scope

Teen-owned accounts only; parent accounts and lessons remain explicitly coming
soon. Interactive onboarding examples must never become account records. Existing
Supabase Auth and database ownership rules remain authoritative. Use the existing
backend; do not create a new project, send real emails, change hosted production
settings or deploy database changes without explicit approval. The narrow native
Auth change was subsequently approved and applied as recorded below.

Commit every source, test and documentation change immediately on this branch.
Do not include private configuration, credentials, account data or build output.
Deliver reviewed changes through a PR.

## Audit areas

- Startup and retry after storage/backend failures.
- Account setup, callback parsing, recovery and session changes.
- Local persistence, offline queue, timeouts, synchronization and user feedback.
- Device PIN, backup behavior and privacy of local account records.
- Money validation, totals, pagination and cross-account isolation.
- Clear unavailable states, large text, narrow/wide layout and primary actions.
- Runtime/source secrets, configuration, public support/privacy information.
- Reproducible verification and a practical rollout/rollback handoff.

## Service dependencies

The public Auth settings endpoint currently confirms email sign-in is enabled,
sign-up is enabled, anonymous users are disabled and confirmation is required.
Earlier verification documented native redirect allowlisting and real email
delivery as incomplete. Recheck what is observable; do not substitute token-fixture
or mocked checks for real inbox/device verification. A public launch claim must
identify any remaining service configuration and delivery evidence honestly.

## Findings and app-side fixes

**JUSTIFIED:** the callback tests reproduced an uncaught invalid UTF-8 exception
and a failed callback that could never be retried. Settings tests reproduced an
appearance change despite failed storage and an exception escaping its tap handler.
The fixes are local to their existing error/persistence paths. New real HTTP-server
tests verify cancellation of stalled headers and response bodies, caller aborts,
and that timing out one request neither closes the client nor replays a write.

- Email callback parsing is inside error handling. Failed exchanges can retry;
  successful exchanges remain deduplicated. Existing PKCE verification is retained.
- Backend HTTP work has a 20-second transport deadline; PostgREST has a 15-second
  per-attempt timeout and retains the SDK's safe read retries/backoff. The new
  transport preserves upstream cancellation and never automatically repeats writes.
- Android cloud backups and device transfers exclude private data, local outbox,
  sessions and PIN records. This also avoids restoring encrypted preferences
  without their device-bound key. These rules have static verification; a physical
  backup/restore test has not been performed.
- Appearance changes become visible after persistence succeeds. Storage errors
  remain visible and retryable without changing the current appearance.
- Offline/pending changes are visible on every main tab, with a working retry.
  Local saves are clearly distinguished from completed server synchronization.
- Data-handling information is accessible before account creation and from You.
  It describes the actual local/cloud behavior and soft deletion. The native
  license viewer includes all three bundled font license notices.
- Startup error UI suppresses the debug banner. No new telemetry service,
  framework, database migration or package version upgrade was introduced.

## Evidence, October 24, 2026

| Area | Result and evidence |
| --- | --- |
| App unit/widget suite | PASS: 91 tests, including 16 new regressions |
| Static analysis | PASS: no issues |
| Formatting | PASS: lib/test/tool formatted; git whitespace check clean |
| Release web compile | PASS: packaged JavaScript web build; not an Android release artifact |
| Targeted visual checks | PASS: three real Flutter-engine journeys, five PNGs |
| Readiness script, offline | PASS: backup rules, prepared release settings, no localhost app URLs, no mock HTTP wiring, source/runtime secret scan |
| Secrets | PASS for the checked patterns: tracked sources and generated web artifacts, location-only output; no secret values printed |
| Locked dependency audit | PASS: OSV batch query for 113 hosted Pub package versions found no published advisories; this is not a guarantee against unknown vulnerabilities |
| Public Auth configuration | PASS: signup/email enabled, confirmations required, anonymous users disabled |
| Anonymous data isolation | PASS: unauthenticated REST probes expose no profiles, transactions, budgets or goals |
| Live authenticated RLS/CRUD | NOT rerun in this audit: earlier rollback/live verification is documented in BACKEND.md; current mocked/controller tests pass but do not replace fresh live authorization evidence |
| Native hosted Auth redirect | PASS after the approved fix: read-only invalid-token probe returns com.getyouthpay.bachat://auth/callback; declared remote configuration differences are zero |
| Live security advisors | No ERROR findings; one existing WARN for disabled leaked-password protection and two INFO findings for deny-by-default private family tables |
| Real inbox delivery and native link round trip | NOT VERIFIED; no mail provider/inbox details supplied |
| Public support/privacy and account-data request process | OWNER ACTION: no public contact/policy details supplied; in-app data information is factual product documentation, not a published legal policy |
| Forge verify / secret scrub | UNAVAILABLE: both requested commands returned MODULE_NOT_FOUND because the Forge runtime is absent; not represented as passes |
| Play Store submission, signing, release APK | EXCLUDED by owner; no release APK created |
| Physical Android / signed iOS | NOT VERIFIED in this session |

The secure-storage dependency reports its existing WebAssembly incompatibility
in Flutter's optional dry run. The JavaScript web build succeeds. The first-phase
Android app does not use WebAssembly.

### Review screenshots

- [Offline changes on Home](screenshots/ux/ship-offline-light.png)
- [Data information](screenshots/ux/ship-data-light.png)
- [Data details and licenses](screenshots/ux/ship-data-details-light.png)
- [Data information, 320px and 200% text](screenshots/ux/ship-data-dark-large.png)
- [Data details, 320px and 200% text](screenshots/ux/ship-data-details-dark-large.png)

All pictured account state is an isolated test fixture. No real user data is
captured or uploaded. Historical reports are unchanged.

## Hosted release configuration

The owner explicitly approved the native Auth change, and it is applied to the
existing project. Exactly three declared properties changed: site_url from
localhost:3000 to the native callback, the native redirect allowlist, and the
server password minimum from 6 to 10, matching the client. Email confirmations
remain required. All seven undeclared remote properties were preserved; SMTP
was untouched. The follow-up diff shows zero declared changes, and every read-only
backend readiness probe passes. See the [sanitized application record](reports/ship-readiness-auth-2026-10-24.json).

Applied file: [release Auth settings](../config/release/supabase/config.toml).
Existing development settings remain separate. Using the development profile on
this same project would change the active release redirects; review explicitly
before doing so. The release configuration contains no SMTP secrets.

```powershell
npx --yes supabase@2.120.0 login
./scripts/configure-auth.ps1 -Environment release
./scripts/configure-auth.ps1 -Environment release -Apply
python scripts/check_ship_readiness.py --check-backend
```

The first script invocation is read-only. The second applies the approved settings
only after reviewing the remote diff. The requested skill explicitly says,
"Production deploys should still have explicit user approval." Approval covers
this callback change, not an SMTP provider purchase, mail sending or unrelated
production changes. Never put provider credentials in Git or chat.

## Remaining public-launch checks

1. Configure/confirm production email delivery in Supabase and verify confirmation
   and recovery through a real inbox on the same device that requested each PKCE
   link. A mocked callback or prepared configuration does not prove delivery.
2. Supply public privacy/support information and own the account-data request
   process. Account deletion is not implemented by the current teen release;
   transaction soft deletion is not account removal.
3. On a physical Android device, complete signup, confirmation, profile and PIN;
   save/edit/delete an exact-paisa transaction; set a budget and savings goal;
   background/unlock; save while offline, restart and reconnect; check another
   signed-in device receives the change. Verify data cannot be viewed while locked.
4. Review hosted Auth/database error logs and backup/restore availability in the
   Supabase dashboard, and assign someone to handle launch support. No monitoring
   subscription or alert destination was invented in this code change.
5. Review the existing disabled leaked-password-protection warning. This feature
   requires Supabase Pro or above; enabling a paid feature or upgrading a plan is
   outside the approved callback change. See [official password security](https://supabase.com/docs/guides/auth/password-security).
   The two private-family-table RLS INFO findings reflect deliberate deny-by-default
   storage for disabled family features; do not add permissive policies to silence them.

Parent onboarding and lessons remain explicitly unavailable by the confirmed
product scope. Production sessions cannot switch into sample profiles; the
existing authenticated-mode guard tests continue to pass.

## Reproduction and rollout

```sh
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test
flutter test tool/ship_readiness_preview_test.dart
flutter build web --release
python scripts/check_ship_readiness.py
python scripts/check_ship_readiness.py --check-backend
```

Use Python 3.11+ for the readiness script. Offline checks also run in CI after the
web build so generated runtime artifacts are scanned. The optional backend check
is read-only and can legitimately fail while hosted configuration is incomplete.
The existing CI debug Android compilation is a regression check; Play Store
packaging and release signing remain outside this work.

Roll out app changes through a PR and a small physical-device pilot after service
checks pass. No database migration or destructive data operation is part of this
change. Code rollback is a revert PR to the previous verified main revision
fe08b02, preserving history; the rollback procedure is documented, not exercised
against users. Do not restore a broken localhost Auth redirect as a rollback.
