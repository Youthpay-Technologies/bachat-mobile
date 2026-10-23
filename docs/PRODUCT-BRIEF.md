# Bachat Mobile product brief

Bachat is a Flutter expense tracker for teens aged 13-18, launching in English with Pakistani rupees. Android and iOS share the same application. The active release enables teen accounts only; parent onboarding is greyed out.

## Current scope

- Email/password registration, email confirmation, sign-in, recovery and session restoration through Supabase.
- Profile setup and name editing; light, dark and system appearance.
- Separate Spend/Receive actions and category sets, with custom Other labels. A spending label "savings" records money set aside instead of an expense.
- Manual transactions with exact paisa amounts, editing and deletion.
- A personal six-digit app-lock PIN on every device; change/lock controls in You.
- Monthly spending and category breakdowns, searchable activity, date/category filters and sorting.
- Monthly category budgets, including reuse of missing categories from the previous month.
- Savings goals, recorded savings additions and progress. Adding savings does not transfer money or create an expense.
- Offline account snapshots and a durable sync queue after initial online sign-in/setup; Realtime and catch-up reads synchronize money records and profiles across devices on the same account. PINs and appearance remain device preferences.
- A coming-soon learning tab.

Verified teens manage their own records without parent approval while parent registration is disabled. New accounts start empty. Sample personas are not exposed in the authenticated app. RLS independently enforces verified teen ownership for every cloud money operation.

## Future family journey

The earlier mutual-confirmation design remains a future requirement: a teen creates a short-lived code; a parent requests access and approves; the teen confirms the named parent. A parent may link multiple children and read approved transactions, budgets and goals; only teens edit them. Required approval and last-parent removal behavior must be reintroduced together with enabled parent onboarding and server authorization. These features are unavailable in this release.

Google sign-in, bank/SMS/Gmail imports, squads, rewards and parent personal spending are deferred. The learning module remains coming soon.

## Interface and architecture

The expense experience now includes an interactive three-step introduction with explicitly labeled examples, direct sign-in, Back and Skip. Example selections never create transactions, budgets or goals. Home prioritizes recent activity; Activity shows totals for the filtered results; first-expense, budget and goal actions are available in empty states. All motion respects the device's reduced-motion preference. See [the UX improvement plan](UX-REVAMP.md).

Use the confirmed cobalt #0C38A9, sunshine #FFDE59 and tangerine #FF751E identity, with Instrument Sans headings, Inter interface text and selective Instrument Serif Italic accents. The lowercase-b symbol replaces the YP tile, with “by YouthPay” retained as endorsement. All requested font families and licenses are bundled for offline use. Keep semantic light/dark themes, flat surfaces and native accessible controls; see [design](DESIGN.md) and [redesign verification](BRAND-REDESIGN.md).

Flutter uses Riverpod, native navigation, an account-gated tab shell, and separate domain, application, data and presentation layers. Sembast/IndexedDB stores account snapshots and queued edits; Supabase provides Auth and PostgreSQL with RLS. Amounts use integer paisa. Cross-device conflicts use the last successfully uploaded record; savings changes on different devices are not merged additively.

## Delivery

Private repository: https://github.com/saim-x/bachat-mobile. Commit each coherent change and merge through verified PRs. The old local Next.js app has been removed. Mac team members handle iOS signing and physical-device verification.

The development database is deployed and live Auth/REST/browser checks pass with approved temporary fixtures removed afterward. Native callback allowlisting and actual inbox delivery remain deployment requirements; see [backend setup](BACKEND.md) and [verification](VERIFICATION.md).
