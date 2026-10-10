> Current release update: authentication is deferred. The app uses persistent, offline Ayesha/Sana demo personas with shared family data. See [demo experience](DEMO-EXPERIENCE.md). Cloud/OAuth descriptions below are retained for future integration.

# Backend setup

## Deployed development environment

- Organization: saim-x's Org
- Project: bachat-mobile-dev (`mqpcxptgmqzwylldiotr`)
- Region: ap-south-1 (Mumbai)
- URL: https://mqpcxptgmqzwylldiotr.supabase.co
- Dashboard: https://supabase.com/dashboard/project/mqpcxptgmqzwylldiotr
- Applied migration: `20261010093016_mobile_bootstrap.sql`

`config/dev.local.json` on the current workstation contains only the project URL, publishable client key, and debug preview flag. It is ignored by Git. Copy the example on another machine and get its publishable key from the dashboard. Public keys rely on RLS; privileged keys must never ship in Flutter.

## Enable Google sign-in

Google was confirmed **disabled** through `/auth/v1/settings` during setup. The mobile integration and callback handlers are implemented, but a live Google sign-in cannot pass until the account owner configures the provider.

1. In Google Cloud, configure an OAuth consent screen and a Web OAuth client for the development project. Add test users while the consent screen is in testing.
2. Add the authorized redirect URI `https://mqpcxptgmqzwylldiotr.supabase.co/auth/v1/callback` to that Google client.
3. Enter its client ID and secret in Supabase → Authentication → Sign In / Providers → Google. Enable and save. Keep secrets in Supabase, never in a repository or chat.
4. In Supabase Authentication URL Configuration, allow `com.getyouthpay.bachat://auth/callback`, `http://127.0.0.1:8080`, and `http://localhost:8080` for local development. Set the intended site URL for your environment.
5. Sign in once as a teen and once as a parent with separate Google accounts. Create a code, approve it as the parent, then confirm the named parent as the teen.
6. Verify child switching, offline edits followed by reconnect, and last-parent revocation on real devices.

Android/iOS custom scheme callbacks are configured in their manifests. Supabase’s app_links integration handles these callbacks; Flutter’s default deep-link handler is disabled to prevent competing navigation. See https://docs.flutter.dev/release/breaking-changes/deep-links-flag-change. Production should use verified universal/app links and separate environments where appropriate.

Official setup reference: https://supabase.com/docs/guides/auth/social-login/auth-google

## Authorization and tests

RLS covers every exposed table. Money writes require the authenticated teen and an approved family relationship. Parents have select access to approved children only. Profile roles and signup ages are immutable. Family tables have no direct client write grants; RPCs validate the caller. Codes are hashed at rest, expire after 24 hours, and are consumed on claim. Requests also expire after 24 hours.

`supabase/tests/family_authorization.sql` executes transactional fixtures and rolls back. It was executed successfully against the new development project. It checks: approval gating, parent self-confirm rejection, all three read permissions, parent write rejection, unrelated account isolation, rate limiting, multiple children, and revocation. A follow-up count confirmed zero test profiles remained.

Run this only in a development database with sufficient test-fixture privileges. It intentionally uses `auth.users` fixtures and `SET LOCAL ROLE authenticated`; do not run it as a mobile client.

Supabase advisors reported no security warnings/errors after migration. Two informational findings identify private RLS tables without policies: this is intentional deny-by-default storage, accessible only through checked definer functions. Unused-index informational findings are expected for the empty development database. References: https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy and https://supabase.com/docs/guides/database/database-linter?lint=0005_unused_index

## Migration workflow

The Supabase CLI configuration is committed for local development (`npx supabase start` requires Docker). Create future migrations with `npx supabase migration new <name>`, inspect their SQL, and deploy to the correct project. Do not modify the old web app's database. The initial migration was applied through the connected Supabase MCP tool using the committed SQL.

