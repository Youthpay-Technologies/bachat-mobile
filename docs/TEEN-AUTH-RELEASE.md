# Teen authentication and cloud release

Enable Supabase-backed teen sign-up/sign-in, email verification, password recovery and session restoration. Parent onboarding is disabled for this release. Verified teens own and manage their records without a family-approval prerequisite while parent onboarding is unavailable. Family sharing remains deferred; no demo persona switching or sample reset is exposed in authenticated accounts.

Preserve the minimal interface and offline edit queue. Enforce teen-only profile creation and owner-isolated money records in Postgres, validate local writes, prevent account/session races and surface retryable sync failures. Use publishable client configuration only. Verify auth, database constraints/RLS, account switching, offline persistence, CRUD and platform builds; commit each coherent change and merge through PRs.

Implementation status: Supabase initialization, email/password and recovery screens, teen profile completion, account editing, secure sessions, authenticated CRUD and durable offline queue are implemented. Parent onboarding is disabled in the UI; parent profile creation and family RPCs are blocked on the server. The old local Next.js app has been deleted; brand assets remain.

Verification: live rollback SQL authorization checks and approved temporary-account HTTP checks pass. The actual Flutter browser passed sign-in, money creation/savings updates, offline save/reload/sync, account isolation and password recovery against the live backend, with zero page errors. Both fixture accounts and their owned records, sessions and tokens were removed afterward. Credentials were never written to disk.

Current hosted state (2026-10-24): the owner-approved native Auth callback and
10-character server password minimum are applied. The declared configuration diff
is clean and the native redirect probe passes. Real inbox confirmation/recovery
and a physical-device round trip remain unverified. See BACKEND.md and the current
SHIP-READINESS.md evidence; earlier localhost/fixture checks are historical.
