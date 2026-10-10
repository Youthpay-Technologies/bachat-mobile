# Bachat mobile design system

## Identity

Bachat is a calm expense tracker that helps teens understand their money and gives approved parents a clear view. Reuse the YP mark; use Bachat as the app name. DM Sans is bundled locally, including its SIL Open Font License, so typography works offline.

## Semantic palette

Light: warm cream canvas #F8F7F2, white surface #FFFFFF, navy primary text #172D35, muted text #62716C, green accent #285B46, soft green #E7EEE6, border #DDE3DB, danger #A13636.
Dark: canvas #111C1A, surface #192622, primary text #F1F4EC, muted text #B2C0B7, green accent #A4D1B2, soft green #263C30, border #41574A, danger #FFB4AB.

Meaning always has text or an icon as well as color. Verify contrast from rendered token pairs. Red is reserved for expenses/destructive/error semantics, not generic emphasis.

## Type and spacing

DM Sans, tabular money figures, sentence-case labels. Scale: amount 40/1.1, title 30/1.2, section 20/1.3, body 16/1.5, label 14/1.4, caption 12/1.4. Scale with platform text settings; allow wrapping and scrolling instead of clipping.

Spacing steps 4, 8, 12, 16, 24, 32. Standard screen inset 24; compact screens can use 20. Section gaps are at least twice within-group gaps. Cards have modest corners, faint borders, and no heavy shadows. Inputs and buttons have clear boundaries and touch targets of at least 48 logical pixels.

## Navigation

Teen: Home, Activity, Plan, Learn, Profile. Plan holds budgets and goals in one screen with clear subsections. Parent: Family, Activity, Plan, Learn, Profile. The active child is named in parent screens. Parents see read-only controls and explicit link status.

One primary action per view. Add-entry forms use a sheet with labels, numeric keyboard, inline errors, date/category controls, and a clear save state. Filters have a reset path. Empty states explain how to add the first item.

## Onboarding

Welcome -> role -> Google sign-in -> profile -> role-specific family setup -> mutual approval -> app. Returning accounts resume at the correct state. Teens cannot bypass approval with navigation. Pending/rejected/expired/revoked states have a clear recovery action.

## Motion and accessibility

Use brief, infrequent transitions; no perpetual dashboard motion. Respect reduced motion. Name icon controls, use native focus/semantics behavior, announce errors and status, and test at 320px width and large text. Avoid fixed-height text containers.

## Sources

https://github.com/jakubkrehel/skills and its better-accessibility, better-layout, better-writing, better-typography, better-colors, and better-ui skills. Flutter APIs replace web-specific recipes.
