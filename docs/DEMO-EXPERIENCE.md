> Historical design/demo notes. The current app uses authenticated teen accounts; see [the current release](TEEN-AUTH-RELEASE.md). Sample personas are retained only in isolated tests.

# Reference-led demo experience

The October 10 reference supersedes the earlier cream/forest direction. The reference establishes the cool gray canvas, restrained green accents and 24px page margins. The subsequent shape refinement uses 12px controls, 16px cards and 20px sheets/navigation with subtle shadows; current tokens are documented in DESIGN.md. This is an adaptation for expense tracking, not a bank wallet.

Authentication is deferred. Launch offers Ayesha (teen, 16) and Sana (parent). Both use one persistent local demo family; switching personas never deletes transactions, budgets, goals or approvals. No Google sign-in or Supabase credentials are needed. Demo data never enters the cloud. Family approval can be explored locally and does not represent real identity verification.

Usability priorities: visible persona and state, descriptive actions, parent read-only enforcement, reversible edits with confirmed deletion, validation beside fields, native keyboard/focus behavior, labeled controls, generous touch targets, 320px reflow and 200% text scaling. Green buttons use dark text to preserve contrast. Learning remains coming soon.

The subsequent minimalism pass removes persistent “Demo” and device-storage messaging from product screens. Names/roles identify the active persona; this document and README explain the local sample environment. Authentication remains deferred.
