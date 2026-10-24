# Reference-led demo experience

The October 10 reference supersedes the earlier cream/forest direction. The reference establishes the cool gray canvas, restrained green accents and 24px page margins. The subsequent shape refinement uses 12px controls, 16px cards and 20px sheets/navigation with subtle shadows; current tokens are documented in DESIGN.md. This is an adaptation for expense tracking, not a bank wallet.

Authentication is deferred. Launch offers Ayesha (teen, 16) and Sana (parent). Both use one persistent local demo family; switching personas does not delete locally entered or imported transactions, budgets, goals or approvals. The demo starts without sample transactions, budgets, or goals; an existing installation also removes the original seeded demo records when it loads. Demo data never enters the cloud. Family approval can be explored locally and does not represent real identity verification.

On Android, continuing as the teen after onboarding requests SMS permissions through the native Android permission prompt. If granted, the app scans the available inbox and listens for new messages, including while in the background. SMS parsing is heuristic; unsupported message formats are skipped. SMS import is unavailable on iOS. Gmail sync is started manually from Settings and requires the Google OAuth client IDs documented in [backend setup](BACKEND.md).

Usability priorities: visible persona and state, descriptive actions, parent read-only enforcement, reversible edits with confirmed deletion, validation beside fields, native keyboard/focus behavior, labeled controls, generous touch targets, 320px reflow and 200% text scaling. Green buttons use dark text to preserve contrast. Learning remains coming soon.

The subsequent minimalism pass removes persistent “Demo” and device-storage messaging from product screens. Names/roles identify the active persona; this document and README explain the local sample environment. Authentication remains deferred.
