# Migration inventory

## Existing system

Next.js 16 / React 19 web application, primarily JavaScript, Tailwind 4, localStorage-first persistence, optional Supabase, Next.js server routes, Vitest and Playwright tests.

## Native implementation work

- Rebuild all UI as Flutter widgets, including role-specific onboarding and navigation.
- Translate categorization, bank parsing, duplicate detection, insights, balance rules, budgets, goals, and reporting into Dart as scope requires.
- Replace browser storage with mobile persistence and explicit account isolation.
- Implement mobile auth deep links, secure session storage, and recovery flows.
- Implement mobile family-code claims and teen approvals through backend authorization.
- Rework Gmail OAuth; existing web cookies are not a native authentication design.
- Keep learning marked coming soon.
- Build and test Android and iOS separately.

## Backend gaps to resolve

The web repository contains patch migrations, not a complete application bootstrap schema. Its SQL test scaffold is a fixture, not a production migration. Goals, budgets, rewards, squads, and stated balance currently have no cloud copy. A mobile release that syncs these needs explicit schema, ownership policies, and conflict rules.

## Existing rules to confirm and preserve

- Parent requests access; teen approval grants read access; revocation ends it.
- A claimed family code alone grants no transaction access.
- Parent access is read-only and supports multiple children.
- Parent personal expenses remain separate from child transactions.
- Amounts are positive; debit/credit determines direction.
- Net transaction flow is not the user's verified balance.

Source evidence: `../bachat/doc/MOBILE-MIGRATION.md`, `USER-ROLES.md`, `DATABASE.md`, `AUTHENTICATION.md`, and `FEATURES.md`.
