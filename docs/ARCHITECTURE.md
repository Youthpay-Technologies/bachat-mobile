# Architecture

## Boundaries

- `lib/domain`: immutable models, exact paisa arithmetic, summaries and activity filtering.
- `lib/data`: Sembast/IndexedDB snapshots, persistent account outbox, secure session storage, public backend configuration and paginated Supabase reads.
- `lib/application`: Riverpod controller, authenticated account lifecycle, validated/serialized mutations and synchronization. Authentication methods live in a separate part of the controller library.
- `lib/presentation`: onboarding, email/password and recovery forms, profile completion, dashboard tabs and account settings.
- `lib/design`: shared semantic theme, radius scale and reusable surfaces.
- `supabase`: reproducible migrations and rollback-scoped authorization tests.

## Authentication

The app captures the initial callback URL before Flutter routing, initializes Supabase with publishable client configuration, restores its secure local session, then installs auth listeners before handling email callbacks. Password recovery is persisted until the password is changed or the user signs out. Link origins/schemes are constrained. PKCE code verification is performed by the Supabase client.

The root gate separates signed-out onboarding, password recovery, incomplete profiles, account-loading failures and the dashboard. Only teen accounts are enabled. Parent options are disabled, cached parent sessions cannot enter the dashboard, and the server rejects parent profile creation. Sample personas are available only to isolated tests using a repository without a cloud client.

Native tabs retain state through an IndexedStack; sheets and detail pages use native navigation. Account changes invalidate earlier asynchronous loads before they can populate the new account's interface.

## Local writes and synchronization

Each account has its own snapshot and durable outbox. Validated mutations are serialized, and the new snapshot plus queued operation are written in one database transaction before visible financial state changes. Persistence failures leave the displayed records unchanged. Deleted records are tombstones.

Outbox entries coalesce by account/table/record ID. Uploads verify the current session and row owner; an operation ID prevents an older upload from removing a newer queued edit. Paginated owner-filtered reads avoid the server's default page-size truncation. Pending records overlay remote data, and a local revision guard prevents an in-flight fetch from replacing a newer edit. Edits queued during a successful refresh trigger another pass.

Conflicts use the last successfully uploaded record, rather than an accounting ledger or additive server transaction. Budget synchronization resolves the active owner/month/category identity before uploading; a concurrent unique conflict remains queued and can be retried. Savings increments are serialized on one device; simultaneous edits from separate devices are not merged additively. This is an expense tracker, not a payment or banking system.

Connection failures preserve local snapshots and queued edits. Account settings exposes retry when synchronization needs attention. Sign-out confirms intent, warns if queued edits would be discarded, and clears this device's account cache and queue. Cloud records remain in the owner's account.

## Authorization and tests

Postgres RLS enforces verified teen ownership independently of client state. The application never ships a service-role key. Profile roles/signup ages and record ownership are immutable. Parent sharing is disabled at the database boundary for this release.

Domain, repository, auth/controller and widget tests cover financial validation, persistence, role gates, PKCE recovery, session boundaries, pagination, concurrency and narrow/large-text layouts. Live SQL tests use rollback fixtures. Approved disposable users also verified real Auth/REST and Flutter browser sign-in, CRUD, offline synchronization, account switching and password recovery; their accounts and records were removed afterward. See [backend setup](BACKEND.md) and [verification notes](VERIFICATION.md) for remaining hosted configuration and live email testing requirements.
