# Receipt savings and floating navigation

The Receive sheet has an optional goal and Amount to save. For example, receiving Rs 1,000 and assigning Rs 400 to a goal increases available spending by Rs 600 and goal progress by Rs 400. Receiving without a goal makes the entire amount available. Receipt edits and deletions reverse the corresponding contributions; category budgets track expenses only.

Money stays in integer paisa. Goal saved_minor stores separate manual savings; active receipt allocations are derived for display and available-balance calculations. Reconciled cash stores its ledger checkpoint to avoid counting older records twice. Plan shows total set aside, including standalone savings.

The additive migration 20261026170304_receipt_savings_allocations adds receipt allocation columns, ownership and capacity guards and an authenticated SECURITY INVOKER batch RPC. The RPC commits linked offline changes in one transaction, preserves RLS, and validates final capacity. A per-account profile lock serializes old REST writes and atomic batches. Outbox retries replace receipt rows by ID; they do not increment a credit counter. Failed batches retain pending records and report the goal conflict.

The bottom pill uses an 18-pixel backdrop blur with an 88-percent surface tint and an opaque fallback in high contrast. It remains compact, floats 12 pixels above the bottom safe area, and preserves screen content underneath. Existing dark and light palettes and fonts remain unchanged.

Verification includes financial lifecycle and persistence tests, atomic retry and in-flight edit tests, receipt form editing/deletion, six viewport sizes (320x568 through 600x960 and landscape), both themes and normal/200-percent text. The database suite checks foreign ownership, unverified users, overfunding, atomic goal swaps, rollback and goal deletion. The live concurrency probe creates one synthetic account, races two receipts against one target, verifies idempotent replay and deletes the exact synthetic account in a finally block. iOS device testing is unavailable on Windows.
