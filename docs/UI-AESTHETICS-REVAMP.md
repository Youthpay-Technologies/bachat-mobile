# UI Aesthetics revamp

Requested source: https://github.com/kasonye/ui-aesthetics-skill
Canonical instructions: https://github.com/kasonye/ui-aesthetics-skill/blob/main/SKILL.md
References read: rewrite-playbook, component-aesthetics, interaction-states, color-system.

## Direction

Medium restructure: calm everyday money tracking. Preserve the confirmed cobalt,
sunshine and tangerine brand, bundled fonts, teen-only release and every existing
money action. Improve composition before decoration; add no dependencies.

Home prioritizes monthly spending, entry actions and recent activity. Secondary
metrics use neutral surfaces. Activity groups search and filters above a clear
results ledger. Plan separates recorded savings, monthly limits and savings goals.
Shared page headers, tighter radius/spacing scales, neutral empty states, consistent
form controls and an anchored navigation bar unify the complete journey. Light
and dark themes use distinct neutral luminance steps and semantic accent roles.

Translate the source's web guidance into Flutter themes, constraints, native focus,
semantics and text scaling. Preserve reduced motion and explicit coming-soon states.

## Git and validation

Branch: feat/ui-aesthetics-revamp, based on the existing expense-experience branch
so its latest onboarding and money flows are preserved. Commit every individual
change immediately, including formatting, fixes, tests and documentation.

Verify with formatting, Flutter analysis, existing unit/widget tests, new responsive
journey coverage, visual renders and web/Android builds where available. iOS device
verification requires macOS. Push a PR to main and merge after checks when GitHub
access is available. At task start, Git network access fails and gh cannot authenticate;
local commits are possible. Do not report a PR or merge as completed without evidence.
