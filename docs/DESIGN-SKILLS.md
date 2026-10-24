# Requested design skills

## UI Aesthetics, October 24, 2026

Source: https://github.com/kasonye/ui-aesthetics-skill

Read the canonical SKILL.md and its rewrite-playbook, component-aesthetics,
interaction-states and color-system references. Applied its medium-restructure
workflow to the complete Flutter UI: composition before decoration, neutral surface
hierarchy, restrained accent roles, shared control geometry and deliberate phone
and wide-screen navigation. The existing product identity takes precedence over
generic palette defaults. No web framework or animation package was added.

See [the implementation and validation record](UI-AESTHETICS-REVAMP.md).

## Earlier domain guidance

Source: https://github.com/jakubkrehel/skills

Recursively discovered and installed all 13 SKILL.md packages during discovery:

- better-accessibility
- better-colors
- better-interface
- better-layout
- better-typography
- better-ui
- better-writing
- break
- build-design
- explain-interface
- interface-review
- state-machine
- variant

The seven better-* skills guide accessibility, color, layout, typography, motion, and writing. Task-specific review, variant, and stress-test skills apply when their workflow is relevant. Installation does not mean every skill has been executed or every screen has passed a review.

## Flutter adaptation

Use ThemeData and semantic theme extensions for color/type roles; native widgets and Semantics for accessible controls; Flutter focus APIs for keyboard paths; responsive constraints and text scaling for small displays; MediaQuery accessibility settings for reduced motion; and persistent recovery instructions for errors. Use contextual Pakistani content and explicit demo labels where sample data appears.

No web framework, CSS library, or animation dependency from a skill overrides the owner's Flutter requirement.
