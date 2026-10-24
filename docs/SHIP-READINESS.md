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
settings or deploy database changes as an implied part of this audit.

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
