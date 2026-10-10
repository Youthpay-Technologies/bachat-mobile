# Product discovery

## Confirmed by the owner

Bachat is an expense-tracking mobile app for teens and parents. It will be implemented in a new Flutter project, with redesigned minimal UI, proper onboarding, separate role journeys, relevant dashboards and tabs, and a coming-soon learning module. Source control must use a new private GitHub repository with frequent commits and merged PRs. The requested design reference is https://github.com/jakubkrehel/skills.

## Decisions pending owner answers

1. Release scope: Gmail import, squads, rewards, and parent personal spending.
2. Teen age range and whether parent approval is required before app use.
3. Sign-in providers and account recovery.
4. Teen consent rules, parent permissions, and multiple-child support.
5. Branding, colors, fonts, mascot, themes, and reference apps.
6. Existing or separate Supabase environment; offline behavior and sync scope.
7. Launch languages, currencies, and import methods.
8. GitHub owner and repository name.
9. Flutter state-management preferences and macOS access for iOS builds.

## Proposed release structure (not approved or implemented)

Teen: Home, Activity, Plan (budgets/goals), Learn (coming soon), Profile.
Parent: Family, Child activity/insights, Reports, Profile; personal spending if requested.

Onboarding: introduction, role selection, account access, profile, role-specific setup, optional family linking, completion. The exact order depends on the chosen authentication and consent model.

Suggested technical baseline: Flutter stable, feature-oriented architecture, Riverpod, go_router, an offline local database, and Supabase repositories. Final choices await product decisions and toolchain verification.
