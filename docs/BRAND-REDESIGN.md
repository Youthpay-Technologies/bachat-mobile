# Mobile brand redesign verification

## Scope and isolation

Worktree: `bachat-brand`, branch `feat/cobalt-brand-redesign`. The branch starts at committed mobile snapshot `c2aa2b9` on `feat/teen-auth-and-cloud`. The other agent's original checkout and the deprecated Next.js project were not edited.

This is currently stacked on the authentication work, which was not yet in local `main` at the start. A PR against `main` before that work merges would include its commits. Target the authentication branch for a stacked PR, or rebase the redesign onto updated `main` after authentication merges. Do not silently merge unrelated authentication changes as part of this redesign.

## Implemented

- New code-native lowercase-b symbol and Bachat / YouthPay wordmark.
- Exact cobalt #0C38A9, sunshine #FFDE59 and tangerine #FF751E brand primitives with semantic light/dark themes.
- Shared typography roles, tabular financial figures, flat surfaces, navigation, fields, badges, loading and empty states.
- Editorial onboarding, static habit illustration, spending hero, sunshine savings cards and revised Learn presentation.
- Android/iOS launcher icons, Flutter preview icons and install metadata.
- Licensed offline Inter. Instrument Sans and Instrument Serif placements are implemented but their assets are pending.

## Checks completed

The normal Flutter CLI could not write the shared SDK cache or launch child tools under this session's sandbox. Verification used the existing installed Flutter 3.47.7 / Dart 3.13.5 binaries directly, without changing the shared SDK or the other agent's source.

| Check | Result |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test tool` | Passed |
| `git diff --check` | Passed |
| Direct Dart analysis-server protocol | 28 files, 0 diagnostics |
| PowerShell parser for `scripts/install-brand-fonts.ps1` | No syntax errors |
| Existing domain, repository, demo, everyday-tools and widget tests | 36 passed, 0 failed through an in-process `test_api` Declarer/Invoker harness in `flutter_tester` |
| Real Flutter renders | 26 completed, no Flutter exceptions |
| Launcher generation | Canonical Flutter painter rendered all 25 icon files |

The test harness used a local copy of the existing Material test shader assets. These are test runs through the installed Flutter engine, not a claim that the normal `flutter test` command succeeded. Temporary harnesses and logs remain in the ignored `.dart_tool` directory of this worktree.

The existing tests exposed two stale expectations, corrected in separate commits: a queued transaction retains its `owner_id`, and the disabled parent choice uses the existing typographic apostrophe. No application authentication or synchronization behavior was changed.

The renders cover Welcome, Home/navigation, Activity, Plan, Learn and Settings in both themes, each at 390px / normal text and 320px / doubled text, plus both parent dashboards. The large-text spending panel was visually checked and refined to keep the sample amount readable. The artifacts use local preview records and fallback Instrument typography. See [light home](screenshots/brand/home-light.png), [dark home](screenshots/brand/home-dark.png), [large-text home](screenshots/brand/home-light-large-text.png) and [all renders](screenshots/brand/).

## Measured contrast

Ratios were computed using WCAG relative luminance from the declared opaque foreground/background pairs. They do not substitute for a platform screen-reader or keyboard audit.

| Pair | Ratio |
| --- | --- |
| White / cobalt action and spending panel | 9.75:1 |
| Light primary text / white surface | 15.51:1 |
| Light secondary text / white surface | 5.95:1 |
| Light field outline / white surface | 3.94:1 |
| Light secondary action / primary container | 8.47:1 |
| Light savings label / savings container | 9.20:1 |
| Dark primary text / surface | 14.34:1 |
| Dark secondary text / surface | 8.83:1 |
| Dark primary action text / fill | 8.60:1 |
| Dark secondary action / primary container | 8.84:1 |
| Dark savings label / savings container | 9.30:1 |

## Remaining work before merge

1. In a network-enabled session, run `./scripts/install-brand-fonts.ps1`, commit the fonts/licenses and manifest, then refresh verification and screenshots. Until then the requested Instrument faces are not delivered: headings fall back to Inter and editorial text uses the platform serif.
2. Run the normal Flutter checks and relevant platform builds in an environment with writable tooling. Android and iOS builds, signed releases, screen-reader behavior and a complete keyboard audit were not verified in this redesign session.
3. Confirm the authentication branch's integration status, push this branch, create the appropriately based PR and merge after checks. `git push` and the explicit `gh pr create --draft` attempt both failed because the session routes network requests to an unavailable proxy at `127.0.0.1:9`. The draft body is prepared in the ignored `.pr-brand.md`. No PR or merge has happened.

The session's approval policy also rejected the attempted font-download escalation. That policy must change, or the remaining network work must run in a different session; no approval was inferred.
