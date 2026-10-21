# Backend

The active development project is **bachat-mobile-dev** (`mqpcxptgmqzwylldiotr`), in Mumbai (`ap-south-1`): https://supabase.com/dashboard/project/mqpcxptgmqzwylldiotr.

## Current release

Supabase Auth provides email/password sign-up, confirmation, sign-in, password recovery, session refresh and sign-out. Profile completion collects a name and signup age (13-18). Parent registration is disabled in onboarding and rejected by the profile insert policy. Authenticated profiles and financial records belong to the caller; family sharing is deferred and its RPC permissions are revoked for this release.

The project was restored from its paused state on 2026-10-21. Email sign-up is enabled and email confirmation is required, verified through the public Auth settings endpoint.

## Hosted Auth configuration

The connected Supabase MCP tools expose database operations but no Auth settings update. The CLI remains signed out. Live token verification honored the localhost web redirect, but rejected the native scheme and fell back to the web site URL. Native email links therefore need the allowlist applied before device use. Sign in with `npx supabase@2.120.0 login`, then review and apply the narrow hosted configuration:

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
4. `20261021174145_money_tags_and_device_sync.sql`

Account deletion is outside this release and has no callable database function. The third migration removes the unused capability created during implementation.

## Verification

`supabase/tests/teen_authorization.sql` passed against the live project through MCP. It runs fixtures inside a transaction and rolls back: verified owner CRUD without parent approval, unrelated-user isolation, unverified-user write rejection, parent profile rejection, category/amount/goal limits, budget uniqueness and immutable identity checks. The older family test documents the prior release and is not the current access contract.

The latest security advisor run reports an existing hosted Auth warning for disabled leaked-password protection. Enable it through the Auth settings when configuring production password security; the available MCP tools do not mutate Auth settings. See [password security](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection). Two informational findings concern deny-by-default private family tables with no policies. Unused-index informational findings are expected in the empty development database. See [private RLS information](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy).

Approved temporary accounts passed real Supabase HTTP sign-in, unconfirmed-email rejection, confirmation-token exchange, teen profile creation, parent rejection, CRUD and unrelated-user isolation for all three money tables, recovery verification, password update, refresh and logout invalidation. The actual Flutter browser also passed live sign-in, transaction/budget/goal creation, exact savings addition, offline save/reload/reconnect, account switching and recovery/password update, with zero page errors. No successful Auth/REST responses were intercepted in that live run.

Confirmation/recovery tokens were prepared only for the two explicitly approved disposable accounts; this verifies Auth processing, not inbox delivery. A mail request to the reserved invalid fixture domain was rejected with `email_address_invalid`, which does not establish SMTP readiness for real recipients. Real inbox delivery remains unverified. Both accounts were removed after revoking sessions; queries confirmed zero remaining fixture users, profiles, money rows, sessions, refresh tokens or one-time tokens. Credentials were held in memory only. See [verification](VERIFICATION.md).

## Device synchronization and money categories

Profiles, transactions, budgets and savings goals are published to Supabase Realtime. The app subscribes with caller-account filters; RLS still determines delivered rows and all authoritative reads. Tombstones replicate as updates. Reconnection, app resume and a 30-second fallback poll close missed-notification gaps. Offline writes retain the account-scoped outbox and pending overlay.

Transactions now support expense, income and savings directions, direction-specific category checks, and `custom_category` for Other tags. A private invoker trigger trims tags and normalizes spending tagged savings into the savings direction. Historical income labels outside the new receive taxonomy were preserved as Other custom tags. The migration retains existing verified-owner RLS and adds no administrative client capability.

Both `supabase/tests/teen_authorization.sql` and `supabase/tests/money_flows.sql` pass against the hosted project with rollback fixtures. Live independent browser sessions verified delivery for every published account table and offline-reload propagation to another session. The disposable account was removed after session revocation; cleanup counts were zero. PIN hashes, cooldowns and appearance never enter these tables.
