# Teen authentication and cloud release

Enable Supabase-backed teen sign-up/sign-in, email verification, password recovery and session restoration. Parent onboarding is disabled for this release. Verified teens own and manage their records without a family-approval prerequisite while parent onboarding is unavailable. Family sharing remains deferred; no demo persona switching or sample reset is exposed in authenticated accounts.

Preserve the minimal interface and offline edit queue. Enforce teen-only profile creation and owner-isolated money records in Postgres, validate local writes, prevent account/session races and surface retryable sync failures. Use publishable client configuration only. Verify auth, database constraints/RLS, account switching, offline persistence, CRUD and platform builds; commit each coherent change and merge through PRs.
