# Demo verification

36 domain, repository, controller and widget tests passed. Coverage includes persistent shared demo records, persona restoration, reset, mutual family approval, read-only parent enforcement, access removal, exact money parsing, validated transactions/budgets/goals, narrow/large-text layouts, profile/appearance sheets, retained searches, empty-filter recovery, carousel buttons, startup skeleton, calendar boundaries, date/category filters, sorting, exact savings increments, savings persistence and limits, and previous-month budget reuse without overwrites. Analyzer is clean.

Web release compilation and Windows Android arm64 debug APK compilation pass. Chrome at 390 × 844 verified teen and parent dashboards, Plan, Learn, persona switching, transaction save feedback, live total updates, search retention, goal creation/carousel navigation, appearance changes and parent restoration after reload, with zero page errors. Light and dark screenshots were visually inspected. Widgets cover 320px and 200% text scaling. This is targeted usability/accessibility verification, not certification of every HCI principle or an assistive-device audit.

Measured light-theme sRGB contrast: button text #102314 on #34C642 **7.31:1**; body #14171C on #EEF0F4 **15.74:1**; secondary #596171 on #EEF0F4 **5.46:1**; readable green #216D2C on #F7F8FA **6.01:1**. Selected navigation icons use dark primary text in both themes.

Demo records stay on this device. Authentication and cloud synchronization are deferred. No live login is claimed. iOS signing/device testing requires the Mac team; no physical Android test has been performed.

| Teen | Parent | Plan |
|---|---|---|
| ![Teen](screenshots/teen-home.png) | ![Parent](screenshots/parent-home.png) | ![Plan](screenshots/plan.png) |

| Introduction | Learning | Dark theme |
|---|---|---|
| ![Introduction](screenshots/onboarding.png) | ![Learning](screenshots/learn.png) | ![Dark](screenshots/teen-dark.png) |

| Profile sheet | Settings | Transaction sheet |
|---|---|---|
| ![Profile sheet](screenshots/profile-sheet.png) | ![Settings](screenshots/settings.png) | ![Transaction](screenshots/transaction-sheet.png) |

| Activity | Goal carousel |
|---|---|
| ![Activity](screenshots/activity.png) | ![Goal carousel](screenshots/goals-carousel.png) |


## Everyday money tools

Chrome at 390 x 844 verified last-month filtering, the applied-filter summary, clear-filter recovery and keyboard selection in the native period dropdown. Adding Rs 125.50 updated the sample goal from Rs 4,350 to Rs 4,475.50. The parent saw the same updated goal without edit controls, and the amount persisted after reload. This run reported zero page errors. Previous-month budget reuse is covered by controller/widget tests; the sample family has no previous-month budgets to exercise in this browser run.

| Filter sheet | Filter recovery | Savings sheet |
|---|---|---|
| ![Filters](screenshots/filter-sheet.png) | ![Applied filters](screenshots/filtered-activity.png) | ![Add savings](screenshots/savings-sheet.png) |
