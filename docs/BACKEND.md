# Backend

The active development project is **bachat-mobile-dev** (`mqpcxptgmqzwylldiotr`), in Mumbai (`ap-south-1`): https://supabase.com/dashboard/project/mqpcxptgmqzwylldiotr.

## Current release

Supabase Auth provides email/password sign-up, confirmation, sign-in, password recovery, session refresh and sign-out. Profile completion collects a name and signup age (13-18). Parent registration is disabled in onboarding and rejected by the profile insert policy. Authenticated profiles and financial records belong to the caller; family sharing is deferred and its RPC permissions are revoked for this release.

The project was restored from its paused state on 2026-10-21. Email sign-up is enabled and email confirmation is required, verified through the public Auth settings endpoint.

## Hosted Auth configuration

The connected Supabase MCP tools expose database operations but no Auth settings update. The CLI was signed out during implementation. Sign in with `npx supabase@2.120.0 login`, then review and apply the narrow hosted configuration:

```powershell
./scripts/configure-auth.ps1
./scripts/configure-auth.ps1 -Apply
```

The script uses `config/hosted/supabase/config.toml`. It configures the local site URL, allowed local/native redirects, required email confirmation and minimum password length. Other undeclared settings are left unchanged. Review the diff before applying. CLI v2.120.0 was used to prepare this workflow.

Allowed development redirects:

- `http://127.0.0.1:8080` and its trailing-slash form
- `http://localhost:8080` and its trailing-slash form
- `com.getyouthpay.bachat://auth/callback`

Add the deployed web origin before using another host. Use a separate environment for production.

For email delivery beyond organization team addresses, configure custom SMTP in Supabase Authentication settings. Enter SMTP credentials in Supabase, never in this repository or chat. SMTP configuration and delivery to a real inbox were not verified in this run. Supabase's built-in mail service restricts recipients and rates; see [official SMTP guidance](https://supabase.com/docs/guides/auth/auth-smtp).

The app manages native/web email callbacks after its auth listener starts, so password recovery cannot be missed during initialization. PKCE links should be opened on the device/browser where they were requested. Android/iOS schemes are configured; the native Supabase automatic link handler is disabled to avoid competing handlers.

## Database and security

- `profiles`: caller-owned name, immutable role/signup age; only teen profiles may be registered.
- `transactions`: owner, direction, category, exact paisa amount, date, note and deletion tombstone.
- `budgets`: one active category per owner/month, with exact positive limit.
- `savings_goals`: target and saved paisa, constrained between zero and the target.
- Legacy family tables remain stored but sharing and linking are unavailable to clients in this release.

Every exposed table has RLS. Money access requires the caller's teen profile, confirmed email and non-anonymous Auth user. Owners and record IDs cannot be reassigned. Categories and monetary bounds are validated by the database. Client credentials are publishable; no administrative key ships in Flutter.

Applied migration versions match the remote MCP history:

1. `20261010093016_mobile_bootstrap.sql`
2. `20261021152127_teen_owned_accounts.sql`
3. `20261021152447_remove_unused_account_deletion.sql`

Account deletion is outside this release and has no callable database function. The third migration removes the unused capability created during implementation.

## Verification

`supabase/tests/teen_authorization.sql` passed against the live project through MCP. It runs fixtures inside a transaction and rolls back: verified owner CRUD without parent approval, unrelated-user isolation, unverified-user write rejection, parent profile rejection, category/amount/goal limits, budget uniqueness and immutable identity checks. The older family test documents the prior release and is not the current access contract.

Security advisors reported no warnings/errors. Two informational findings concern deny-by-default private family tables with no policies. Unused-index informational findings are expected in the empty development database. See [private RLS information](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy).

Automated auth tests use isolated HTTP/PKCE fixtures. The browser's successful sign-in/CRUD journey uses an intercepted test transport; live invalid-credential handling is checked separately. Permanent remote test-account creation was rejected by automatic approval review, so a successful live email confirmation/sign-in/recovery journey is not claimed. It requires configured email delivery, hosted redirects, and an approved test account.
