# Bachat design system

The supplied three-phone image sets the visual direction. At an assumed 390px logical phone width, estimated tokens are 24px page padding, 26px surface corners, 28px button/input corners, soft 18px shadows, white surface rims and a floating rounded navigation surface. These estimates adapt the visual language to expense tracking rather than reproduce banking features.

Light: canvas #EEF0F4, surface #F7F8FA, text #14171C, secondary text #596171, primary #34C642, primary text #102314, readable green #216D2C. Dark: canvas #14171C, surface #20252D, text #F3F5F7, primary #67DE70. Buttons use dark text; focus borders and meaningful icons use readable green in light mode.

DM Sans is bundled. Large amounts use tabular figures. Home centers recorded monthly spending, followed by explicit actions and supporting metrics. Activity, Plan, Learn, You, onboarding, forms and family settings share tokens and components. Native Material controls provide semantics, focus and selection behavior. Forms use native numeric keyboards, persistent labels and inline validation; deletion/reset require confirmation. Parent controls remain read-only in both the UI and controller. Layouts scroll and adapt to large text rather than truncating financial records.

The reference does not define dark, error, loading or large-text states; these are Bachat adaptations required by the user's request for an integrated usable app. No bank transfers, payment keypad or unsupported banking action is implied.

## Minimal interface polish

Headings are concise, amounts use a 44px tabular display style, and section spacing is 36px above / 18px below. One primary action per screen replaces duplicate navigation actions. Repeated demo/storage notices and explanatory paragraphs are removed. Identity remains visible through names and roles; read-only child access is labeled.

Profile and appearance settings open native modal sheets. Forms share drag handles, rounded sheet surfaces, keyboard-aware padding and dismissible confirmation feedback. Learning uses a compact coming-soon badge; savings and over-budget badges carry meaningful status. Multiple home goals become a horizontally scrollable carousel with visible continuation and keyboard-accessible previous/next controls. A single goal remains a card.

Navigation retains each tab’s state and uses a restrained 150ms selection animation. Reduced motion disables sheet/carousel movement and selection animation; theme swaps are instantaneous. The static startup skeleton reflects actual initialization without introducing a delay or perpetual shimmer.

Activity filters live in a dismissible bottom sheet with staged choices and an explicit Apply action. The active count and a concise summary keep the current view visible; clearing advanced filters preserves search and transaction type. Date sorting groups entries by day, while amount sorting uses one ordered list. Empty results offer recovery.

Savings additions use a focused amount sheet with the remaining target visible, exact paisa validation, duplicate-submit protection and completion feedback. Completed goals and parent views omit the action. Reusing previous-month budgets is optional and only appears when a missing category can be copied; existing current-month limits are preserved.
