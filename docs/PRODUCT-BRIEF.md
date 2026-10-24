> Current release update: authentication is deferred. The app uses persistent, offline Ayesha/Sana demo personas with shared family data. See [demo experience](DEMO-EXPERIENCE.md). Cloud/OAuth descriptions below are retained for future integration.

# Bachat Mobile product brief

## Confirmed scope

A Flutter app for Android and iOS, with distinct teen and parent journeys. Launch language is English and currency is PKR. Core features are onboarding, Google sign-in through Supabase, teen expense tracking, budgets, savings goals, parent linking and approval, child dashboards, settings, and a coming-soon learning screen.

Gmail and automatic bank/SMS import are included in the current local Android teen flow. The app requests Android SMS access after onboarding when the user continues as a teen, then scans the inbox and listens for future messages. Parsing is heuristic and cannot guarantee every bank's wording or language. Gmail import is user-initiated and requires Google OAuth client configuration. Imported transactions are saved locally in the demo; cloud authentication and Gmail-to-cloud sync are not part of this release. iOS does not expose an API for reading SMS.

The local demo starts with no sample transactions, budgets, or goals. Its fictional family approval is only a demo convenience and is not real identity verification. Squads, rewards, and parent personal spending remain deferred. Manual expense and income entry is included.

## Accounts and family access

- Teens are 13 through 18 inclusive.
- A teen signs in, sets up a profile, and generates a short-lived family code.
- A parent signs in, enters the code, and explicitly approves the teen.
- The teen sees the named parent and confirms or declines.
- Only mutual confirmation enables the teen's main app and parent reading.
- Parents can link multiple children.
- Parents may read each approved child's transactions, budgets, and savings goals. Only the teen edits them.
- Removing the last approved parent returns the teen to the approval screen.
- Server authorization enforces the relationship; a local role flag is never sufficient.

## Offline behavior

The app must remain usable offline after account setup and a verified approval. Local changes queue for synchronization. Previously cached approval is not proof that server access remains approved: refresh on reconnect, enforce server policies for every cloud operation, and clear restricted views if access has ended. First-time sign-in and family approval require a connection.

## Branding

Warm cream surfaces, navy text, restrained green accents, DM Sans, subtle motion, light/dark themes. Reuse the existing YouthPay/YP mark with Bachat naming initially; the logo may change later.

## Architecture decisions

- Flutter stable, Riverpod, native Navigator and a guarded tab shell.
- Separate domain, repository, application state, and presentation layers.
- Local database and durable sync queue scoped by authenticated account.
- Exact money represented as integer paisa.
- New Supabase architecture, including profiles, family approval, transactions, budgets, goals, and preferences. Do not apply unreviewed migrations to the old web app's production schema.
- Google OAuth and native callback/deep links.
- Minimal feature set with complete empty, loading, error, and offline states.

## Delivery

Private repository: https://github.com/saim-x/bachat-mobile
Frequent coherent commits; feature branches; PRs; merge after relevant verification. Team members with Macs will finish native iOS device/signing verification. Report it separately from Android and Flutter tests.

## External dependency

The new Supabase project bachat-mobile-dev is created and the schema is deployed. Live RLS authorization tests pass. Google OAuth remains disabled until its client credentials and redirect allowlist are configured; see BACKEND.md.
## Everyday money tools iteration

Add transaction date/category filtering and sorting through a compact sheet, date-grouped activity, additive savings entry with target limits, and optional reuse of last month's budgets. Keep existing search/tab state, read-only parent access, local persistence, exact paisa arithmetic and minimal gray/green design. Savings entry updates the recorded total only; it does not transfer money or automatically add an expense. Budget reuse never overwrites a category already configured for the current month.
