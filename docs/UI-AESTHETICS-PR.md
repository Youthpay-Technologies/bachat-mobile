# Polish Bachat UI and add responsive navigation

Apply the requested kasonye/ui-aesthetics-skill guidance across the Flutter app.
Home gives spending, entry actions and recent activity clear priority. Shared
headings, restrained light/dark surfaces, consistent controls and empty states
unify the account, PIN, activity, planning and learning screens. Phone navigation
anchors to the bottom; wider screens use a side rail while preserving tab and
search state. Narrow money sheets and large-text layouts retain usable controls.

Validation: standard Flutter analysis has no issues and all 75 application tests
pass. Four visual journeys produce 20 phone/wide light/dark captures. Formatting
and whitespace checks pass, and optimized JavaScript compiles. GitHub Actions
also checks release web and debug Android builds; see the PR checks for their
final results. Signed iOS and physical-device testing remain unverified.

[Review the screenshots and verification](https://github.com/saim-x/bachat-mobile/blob/feat/ui-aesthetics-revamp/docs/UI-AESTHETICS-REVAMP.md).
Historical PDF reports remain unchanged. This branch preserves the earlier
expense-experience commits from PR #14, so merging it delivers the combined
onboarding and UI work. All changes, including individual screenshots, have
separate commits. Merge with a merge commit to preserve that history.

Tracked in https://github.com/saim-x/bachat-mobile/pull/15.
