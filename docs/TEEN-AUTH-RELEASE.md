# Teen authentication and cloud release

Enable Supabase-backed teen sign-up/sign-in, email verification, password recovery and session restoration. Parent onboarding is disabled for this release. Verified teens own and manage their records without a family-approval prerequisite while parent onboarding is unavailable. Family sharing remains deferred; no demo persona switching or sample reset is exposed in authenticated accounts.

Preserve the minimal interface and offline edit queue. Enforce teen-only profile creation and owner-isolated money records in Postgres, validate local writes, prevent account/session races and surface retryable sync failures. Use publishable client configuration only. Verify auth, database constraints/RLS, account switching, offline persistence, CRUD and platform builds; commit each coherent change and merge through PRs.

Implementation status: Supabase initialization, email/password and recovery screens, teen profile completion, account editing, secure sessions, authenticated CRUD and durable offline queue are implemented. Parent onboarding is disabled in the UI; parent profile creation and family RPCs are blocked on the server. The old local Next.js app has been deleted; brand assets remain.

Verification: live rollback-scoped SQL checks pass and leave no fixture records. Auth/client/widget tests and browser transport simulations exercise the app without permanent remote test accounts. A live invalid-credential request is verified. Successful live email confirmation/sign-in/recovery is pending hosted redirects/email delivery and an approved test account; see BACKEND.md. Automated approval rejected persistent fixture creation, so no generated account credentials or fixture users were created.
