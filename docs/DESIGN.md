# Bachat mobile identity

The October 2026 mobile redesign replaces the previous green/DM Sans direction. Bachat is the product name; “by YouthPay” remains the endorsement. The Next.js application is outside this redesign.

## Brand

The mark is a rounded lowercase **b** with an orange dot, drawn by `BachatSymbolPainter` in `lib/design/brand.dart`. The in-app mark and Android, iOS and Flutter web-preview launcher assets share this geometry. Regenerate launcher assets with `flutter test tool/generate_icons_test.dart`.

| Brand color | Value | Role |
| --- | --- | --- |
| Cobalt | #0C38A9 | Identity, spending summary, primary light-theme actions |
| Sunshine | #FFDE59 | Savings identity and illustration highlights |
| Tangerine | #FF751E | Small identity and illustration accents |
| Ink | #142344 | Primary light-theme text |

Components use Material `ColorScheme` roles. Brand primitives are reserved for the identity and fixed cobalt spending panel. Yellow and orange never carry financial status by themselves. Warnings and destructive actions retain their labeled error treatment.

Light canvas is #F6F7FB with white surfaces, #142344 text and #566480 secondary text. Dark canvas is #0D1529 with #17233D surfaces, #F2F5FF text and #B7C3DE secondary text. Dark primary actions use #B5C8FF with #10275E text. Savings surfaces use #FFF5CB / #40391E in light / dark appearance.

## Typography

- **Instrument Sans:** wordmark, headings, financial display and section hierarchy.
- **Inter:** interface text, controls, descriptions, transaction lists and supporting figures. Inter is bundled with its SIL Open Font License; no proprietary SF Pro file is redistributed.
- **Instrument Serif Italic:** short editorial accents in onboarding, Plan and Learn. Financial values, controls and long descriptions stay in a sans serif.

All three requested families are bundled with their SIL Open Font Licenses and registered in `pubspec.yaml`, including Instrument Serif regular and italic. The app does not need a font network request. `scripts/install-brand-fonts.ps1` can provision the Instrument assets when maintaining the brand; its manifest edit is anchored to the top-level font list.

Financial display uses tabular figures. The normal amount is 44 logical pixels; at large text settings the display adopts a smaller base size and reflows the currency/value so ordinary amounts remain readable. No essential value is ellipsized. Native text scaling remains enabled.

## Layout and interaction

Page content keeps 24px gutters and a 600px maximum width. Radii are 10px for compact elements, 16px for controls, 24px for surfaces and 32px for sheets/navigation. Surfaces are flat; color and spacing establish grouping rather than shadows. Section headings expose heading semantics.

Home leads with recorded monthly spending in a cobalt panel, then the existing transaction action, supporting net-flow metrics and breakdowns. The summary never claims to be a bank balance. Savings cards use a quiet sunshine surface. Onboarding and Learn share a static geometric habit illustration with no invented financial data or continuous animation.

Native buttons, inputs, chips, navigation, focus handling and sheets remain in place. Keyboard entry, persistent field labels, inline validation, destructive confirmations, read-only parent controls and reduced-motion behavior are retained. Loading uses the Bachat symbol; empty, error and unavailable states share the theme. Authentication and business rules are outside the redesign.

## Verification and limitations

See [the redesign verification record](BRAND-REDESIGN.md) and [screen renders](screenshots/brand/). The screenshots come from the real Flutter rendering engine with local preview personas; they are development artifacts, not an authenticated release or device-build verification.
