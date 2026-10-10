> Current release update: authentication is deferred. The app uses persistent, offline Ayesha/Sana demo personas with shared family data. See [demo experience](DEMO-EXPERIENCE.md). Cloud/OAuth descriptions below are retained for future integration.

# Architecture

## Boundaries

- `lib/domain`: immutable models, exact paisa parsing, monthly totals, serialization.
- `lib/data`: native Sembast / browser IndexedDB adapters, secure auth-session persistence, account snapshots, durable sync outbox.
- `lib/application`: Riverpod controller, role and family gates, mutations, cloud reconciliation.
- `lib/presentation`: onboarding, guarded dashboard shell, family flows, forms, and settings.
- `lib/design`: shared semantic color/type themes and reusable surfaces.
- `supabase`: reproducible schema, RLS, RPCs, and transactional authorization tests.

The root gate reacts to authentication, profile, and approved-parent state. A teen cannot reach dashboards through a navigation URL. Native Navigator handles detail sheets and family settings. Tabs are a stateful shell; no routing package is required for the initial small scope.

## Offline synchronization

Each account has its own snapshot and outbox. A mutation writes the current snapshot and pending operation in one local database transaction. Repeated edits coalesce by account/table/record ID. Deletes are tombstones. Synchronization upserts pending records only after refreshing family authorization. An edit queued while an older version uploads is retained by an operation-ID comparison. Pending rows overlay fetched remote rows so a concurrent edit is preserved.

Cloud writes use the signed-in user's JWT and RLS. Authentication session tokens use platform secure storage. On sign-out the account's local snapshot and queue are cleared, after warning if unsynced changes exist. Account changes reset in-memory data before hydration.

The initial conflict policy is last successful upload wins per record. There is no collaborative editing or merge history. A unique budget category/month constraint prevents duplicate active budgets. Cross-device simultaneous creation of the same budget category can produce a sync conflict requiring correction; a future revision can use deterministic category IDs or explicit conflict resolution.

Previously cached parent approval permits offline use. Remote revocation cannot instantly reach a disconnected device; reconnect revalidates and purges restricted views. Offline queued edits for a newly revoked teen remain unsent until approval is restored. Real-time family events and 30-second polling refresh relationship state while online.

## Storage and hardening

Local financial snapshots are isolated per account in the platform app directory (or origin-specific IndexedDB on web); the database is not encrypted at rest by this app. Platform secure storage protects native session persistence. Encrypt financial snapshots and decide offline retention before a production rollout involving minors. Web preview is a development surface, not the planned public product.

Startup uses an explicit public configuration file; no privileged key is present. Role flags in widgets only shape the UI; SQL policies enforce access. The data schema uses integer minor units and bounded amounts, immutable owners, server timestamps, and private consent-code tables.

## Tests

Domain tests cover exact money, serialization, monthly filtering, family approval, and savings progress. Repository/controller tests cover atomic coalescing, account isolation, parent write rejection, and revoked teen restrictions. Widget tests cover onboarding, all teen tabs, parent read-only views, last-parent locking, and narrow-screen scaled text. SQL tests exercise real authenticated RLS and rollback their fixtures.
