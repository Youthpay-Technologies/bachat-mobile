# Current teen authentication verification — 2026-10-21

Analyzer is clean and **51 tests pass**. Coverage now includes email/password validation, pending confirmation, invalid credentials, profile setup, blocked parent registration and sample bypasses, PKCE password recovery, owner-scoped outbox, 501-row pagination, serialized savings increments, failed persistence, edits queued during refresh, and auth/profile layouts at 320px / 200% text. Native and web session storage use the configured platform adapters; tests use isolated storage.

Live Supabase MCP migrations are applied and `supabase/tests/teen_authorization.sql` passed with rollback-scoped fixtures. It verifies owner CRUD, unrelated-user isolation, unverified-user write rejection, blocked parent profiles/family RPCs, immutable identity/age, category/amount bounds, goal limits and budget uniqueness. Follow-up queries confirmed RLS on all exposed application tables, zero test profiles, no persistent auth fixtures, and no account-deletion RPC. Advisors report no security warnings/errors; private deny-by-default family tables and unused indexes have informational notices.

Chrome at 390 x 844 verified the actual live invalid-credential response and the greyed-out parent option. A separate browser context intercepted successful Auth/REST responses in memory to verify sign-in, profile completion, empty initial records, transaction/budget/goal creation, exact savings addition, offline editing across reload, synchronization and sign-out. This run reported zero page errors. The screenshots below were visually inspected. They do not represent permanent cloud test users.

Successful **live** email confirmation, sign-in and recovery remain unverified. Hosted redirect/password settings await CLI login because the MCP tool set has no auth-settings mutation. SMTP delivery to a real inbox has not been verified. Automatic approval rejected persistent cloud test-account creation; no generated credentials or users were created. See [backend setup](BACKEND.md).

| Teen onboarding | Sign in | Live invalid credentials |
|---|---|---|
| ![Onboarding](screenshots/auth-onboarding.png) | ![Sign in](screenshots/auth-sign-in.png) | ![Error](screenshots/auth-error.png) |

| Profile completion | Empty dashboard | Plan |
|---|---|---|
| ![Profile](screenshots/auth-profile-setup.png) | ![Dashboard](screenshots/auth-empty-dashboard.png) | ![Plan](screenshots/auth-plan.png) |

![Account settings](screenshots/auth-settings.png)

The previous local Next.js application was removed at the owner's request. Flutter and sibling brand assets remain. Earlier verification notes below are historical and include sample personas that are not exposed by the current app.

---

# Demo verification

36 domain, repository, controller and widget tests passed. Coverage includes persistent shared demo records, persona restoration, reset, mutual family approval, read-only parent enforcement, access removal, exact money parsing, validated transactions/budgets/goals, narrow/large-text layouts, profile/appearance sheets, retained searches, empty-filter recovery, carousel buttons, startup skeleton, calendar boundaries, date/category filters, sorting, exact savings increments, savings persistence and limits, and previous-month budget reuse without overwrites. Analyzer is clean.

Web release compilation and Windows Android arm64 debug APK compilation pass. Chrome at 390 × 844 verified teen and parent dashboards, Plan, Learn, persona switching, transaction save feedback, live total updates, search retention, goal creation/carousel navigation, appearance changes and parent restoration after reload, with zero page errors. Light and dark screenshots were visually inspected. Widgets cover 320px and 200% text scaling. This is targeted usability/accessibility verification, not certification of every HCI principle or an assistive-device audit.

Measured light-theme sRGB contrast: button text #102314 on #34C642 **7.31:1**; body #14171C on #EEF0F4 **15.74:1**; secondary #596171 on #EEF0F4 **5.46:1**; readable green #216D2C on #F7F8FA **6.01:1**. Selected navigation icons use dark primary text in both themes.

Demo records stay on this device. Authentication and cloud synchronization are deferred. No live login is claimed. iOS signing/device testing requires the Mac team; no physical Android test has been performed.

| Teen | Parent | Plan |
|---|---|---|
| ![Teen](screenshots/teen-home.png) | ![Parent](screenshots/parent-home.png) | ![Plan](screenshots/plan.png) |

| Introduction | Learning | Dark theme |
|---|---|---|
| ![Introduction](screenshots/onboarding.png) | ![Learning](screenshots/learn.png) | ![Dark](screenshots/teen-dark.png) |

| Profile sheet | Settings | Transaction sheet |
|---|---|---|
| ![Profile sheet](screenshots/profile-sheet.png) | ![Settings](screenshots/settings.png) | ![Transaction](screenshots/transaction-sheet.png) |

| Activity | Goal carousel |
|---|---|
| ![Activity](screenshots/activity.png) | ![Goal carousel](screenshots/goals-carousel.png) |


## Everyday money tools

Chrome at 390 x 844 verified last-month filtering, the applied-filter summary, clear-filter recovery and keyboard selection in the native period dropdown. Adding Rs 125.50 updated the sample goal from Rs 4,350 to Rs 4,475.50. The parent saw the same updated goal without edit controls, and the amount persisted after reload. This run reported zero page errors. Previous-month budget reuse is covered by controller/widget tests; the sample family has no previous-month budgets to exercise in this browser run.

| Filter sheet | Filter recovery | Savings sheet |
|---|---|---|
| ![Filters](screenshots/filter-sheet.png) | ![Applied filters](screenshots/filtered-activity.png) | ![Add savings](screenshots/savings-sheet.png) |

## Restrained shape refinement

The updated interface uses 12px control corners, 16px cards, 20px sheets/navigation and 8px badges/selection indicators. Card shadows use one subtle elevation layer. Chrome at 390 x 844 verified all tab transitions used in this pass, filter-sheet open/reset, savings-sheet open/dismiss, appearance switching and parent switching, with zero page errors. The eight screenshots below were visually inspected. Analyzer is clean and all 36 existing tests pass, including 320px / 200% text layouts. Earlier screenshots above document previous iterations.

| Home | Plan | Activity |
|---|---|---|
| ![Home](screenshots/radius-home.png) | ![Plan](screenshots/radius-plan.png) | ![Activity](screenshots/radius-activity.png) |

| Filters | Savings | Profile |
|---|---|---|
| ![Filters](screenshots/radius-filters.png) | ![Savings](screenshots/radius-savings.png) | ![Profile](screenshots/radius-profile.png) |

| Dark theme | Parent |
|---|---|
| ![Dark](screenshots/radius-dark.png) | ![Parent](screenshots/radius-parent.png) |

The final native-control pass also verified transaction-sheet opening and date-picker opening/cancellation in Chrome with zero page errors. The transaction selector and date dialog screenshots were inspected. Android arm64 debug and web release builds both pass for the final source.

| Transaction sheet | Date picker |
|---|---|
| ![Transaction](screenshots/radius-transaction.png) | ![Date picker](screenshots/radius-date-picker.png) |
