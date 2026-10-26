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
- Three destinations in one compact pill-shaped navigation bar: Home, Activity and Plan. Full profile and preferences open from the Home profile icon; Learn is hidden for now.
- Optional budget-or-goal setup followed by manually entered available money. Expenses and savings reduce tracked available money; received money increases it. Checkpoints persist and sync per account without creating income or changing past transactions.
- Home graph uses a minimum 24-hour time axis with hour labels and expands to the current-month activity span; Home Back confirms before exiting.

Verified teens manage their own records without parent approval while parent registration is disabled. New accounts start empty. Sample personas are not exposed in the authenticated app. RLS independently enforces verified teen ownership for every cloud money operation.

## Future family journey

The earlier mutual-confirmation design remains a future requirement: a teen creates a short-lived code; a parent requests access and approves; the teen confirms the named parent. A parent may link multiple children and read approved transactions, budgets and goals; only teens edit them. Required approval and last-parent removal behavior must be reintroduced together with enabled parent onboarding and server authorization. These features are unavailable in this release.

Google sign-in, bank/SMS/Gmail imports, squads, rewards and parent personal spending are deferred. The learning module remains coming soon.

## Interface and architecture

The expense experience now includes an interactive three-step introduction with explicitly labeled examples, direct sign-in, Back and Skip. Example selections never create transactions, budgets or goals. Home prioritizes monthly spending, budget remaining and category cards; Activity shows totals for the filtered results; first-expense, budget and goal actions are available in empty states. All motion respects the device's reduced-motion preference. See [the UX improvement plan](UX-REVAMP.md).

The October 26 reference revamp uses the supplied dark mobile screenshot: cobalt light fading into a near-black canvas, rounded charcoal surfaces, a large monthly spending figure, a white cumulative spending chart, a budget progress ring and horizontal category cards. Instrument Sans is the workhorse interface font; the bundled FK Grotesk displays primary figures and selected brand statements. New installations default to dark mode; saved light, dark and system preferences remain available. The lowercase-b symbol and YouthPay endorsement remain. See [reference implementation and verification](REFERENCE-UI-REVAMP.md).

Flutter uses Riverpod, native navigation, an account-gated tab shell, and separate domain, application, data and presentation layers. Sembast/IndexedDB stores account snapshots and queued edits; Supabase provides Auth and PostgreSQL with RLS. Amounts use integer paisa. Cross-device conflicts use the last successfully uploaded record; savings changes on different devices are not merged additively.

## Delivery

The first launch phase targets Android through Play Store; store submission and
release APK creation are outside the current ship-readiness work. The owner
confirmed reuse of the existing Supabase project and has not supplied public
support/email details. The app now contains factual data-handling information,
license access, persistent pending-sync feedback and additional callback/network/
storage failure handling. This does not imply that hosted email delivery or
native callbacks are ready. See [the evidence and launch handoff](SHIP-READINESS.md).

The October 24 UI Aesthetics pass refines the complete Flutter interface using
the requested kasonye/ui-aesthetics-skill repository. Home places recent activity
before supporting totals. Shared page headings, neutral surfaces, consistent
controls and responsive bottom/side navigation carry the visual system across
the account and money journeys. See [the revamp record](UI-AESTHETICS-REVAMP.md)
for current verification and delivery status.

Private repository: https://github.com/saim-x/bachat-mobile. Commit each coherent change and merge through verified PRs. The old local Next.js app has been removed. Mac team members handle iOS signing and physical-device verification.

The development database is deployed and live Auth/REST/browser checks pass with approved temporary fixtures removed afterward. Native callback allowlisting and actual inbox delivery remain deployment requirements; see [backend setup](BACKEND.md) and [verification](VERIFICATION.md).

## October 26 simplification

The owner confirmed removing You and Learn from navigation and removing the duplicate floating Receive/Spend actions. The three remaining destinations share a compact pill-shaped surface with plain icons and fully curved corners. The Home header contains only the transparent green-b/red-dot mark and a right-aligned profile icon; its Plan shortcut and Home label are removed. Existing inline money actions remain above Recent activity.

Available money is manually reconciled cash, not a bank balance. Users may set a category budget or savings goal, then enter what they can spend now, or start tracking expenses immediately. Both savings entries and additions to goals reduce available money; users should record each savings addition once. Setting an available amount captures the existing ledger as a baseline so earlier activity is not deducted again. See [the implementation and verification record](SIMPLIFIED-EXPENSE-FLOW.md).

The time-axis correction uses actual transaction timestamps: the initial window is the trailing 24 hours, with hour labels; once current-month expense history exceeds a day, the window expands to cover that history. Profile uses the same in-content heading and backdrop as Activity and Plan, with an inline Back button. Light mode has opaque pale surfaces and stronger text/control contrast while the approved dark palette is unchanged. See [time-axis and appearance verification](TIME-AXIS-AND-APPEARANCE.md).
