# Bachat Mobile working agreement

## Product

Develop the Flutter app for Android and iOS as the active Bachat project. The owner requested removal of the former local Next.js app on 2026-10-21; do not recreate it. The current release enables authenticated teen accounts only; parent onboarding is disabled until a later release. Learning is not exposed in navigation. The active shell has Home, Activity and Plan; the Home profile icon opens the full profile section. Record confirmed product decisions in docs/PRODUCT-BRIEF.md and distinguish proposals from implementation.

## Git workflow

The owner explicitly authorizes creation of a private GitHub repository, frequent commits, feature branches, pull requests, and merging those PRs. Commit each coherent change, including fixes and documentation. After the initial repository seed, use feature branches and PRs. Run appropriate checks before merging. Never commit credentials, signing keys, account data, build output, or local environment configuration. Do not silently treat failed checks as successful.

## Design

Use the requested jakubkrehel/skills collection and its relevant domain references. Translate web-specific guidance into Flutter's native layout, semantics, focus, motion, and theme APIs. Use semantic color and typography tokens, accessible labels and targets, text scaling, reduced-motion support, and clear empty/error/loading states. Product preferences take precedence over skill defaults. Avoid ornamental dashboard motion and unimplemented actions presented as functional.

## Architecture

Keep domain logic independent of widgets. Represent money with integer minor units or an exact decimal type. Preserve teen-approved family access if the owner confirms that rule. Never equate net transaction flow with a verified account balance. Keep demo/local state visibly separate from authenticated server access. Cloud authentication and authorization must be enforced by the backend, not simulated by client role flags.

## Verification

Use dart format, flutter analyze, unit and widget tests, and platform builds where tools permit. Report Android/iOS verification separately. An iOS target directory or unsigned CI compile is not proof of a signed device release.
