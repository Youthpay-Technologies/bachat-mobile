# Adaptive time axis and appearance — October 26, 2026

## Corrected requirement

The owner clarified that the graph's x-axis time range and legend should adapt. Changing a first-day chart into a centered point was the wrong interpretation.

The chart now begins with a trailing 24-hour window, ending now. Transactions retain their actual timestamps and cumulative amounts. Once the first current-month expense is older than 24 hours, the start expands to that first expense: a three-day history uses a three-day axis. New transactions and the existing 30-second account refresh rebuild the range. Deleted, future and other-month records are excluded, and empty accounts still have a 24-hour scale.

Tick labels are positioned at evenly spaced elapsed-time intervals. First-day views show hours, with dates at the endpoints. Longer views show dates and times. Phones use three ticks, wide layouts five, and large text two endpoints to avoid overlap. The chart preserves actual transaction timing rather than spreading points evenly or inventing spending between records.

## Profile and navigation

Profile's empty native AppBar has been removed. Its Back button and title sit in the same PageHeading, PageBody spacing and continuous backdrop used by the other pages. Profile sign-out and Back behavior remain covered by tests.

The three navigation destinations share one fully curved pill surface, with plain outline/filled icons and labels. There are no individual circular backgrounds. The mobile bar is 64 logical pixels high, expands for large text, and has no decorative bottom gap; the system safe area remains respected.

## Light appearance

The light backdrop is opaque pale blue fading to a cool neutral canvas, avoiding the old translucent dark-blue tint. Light-only primary, secondary, error, border, muted-text and category accent colors have been adjusted. Existing dark color values, gradient colors and alpha remain unchanged.

Measured contrast ratios:

| Pair | Ratio |
| --- | --- |
| Secondary text / pale-blue backdrop | 5.50:1 |
| Primary link / pale-blue backdrop | 6.08:1 |
| White button text / primary fill | 6.94:1 |
| White button text / secondary fill | 5.39:1 |
| Input outline / white surface | 3.23:1 |

Tests enforce text/control contrast and pin the approved dark palette values. Rendered light and dark Home/Profile screens were inspected at 390 logical pixels, with all destination captures also generated at 1100 pixels. Axis labels and setup states are exercised at 320 pixels and 200% text.

## Validation

- All 112 combined unit, widget and visual-capture checks pass.
- Flutter analysis reports no issues.
- Tests verify a minimum 24-hour window, hourly ticks, three-day growth as time passes, timestamp positions and exclusions, compact navigation without icon circles, and the absence of a separate Profile AppBar.
- Android debug APK is rebuilt and installed in place on the connected NOTE 23, preserving app data. Installed APK content is compared with the local build.
- iOS build/device verification remains unavailable on this Windows host.

Current screenshots are under `docs/screenshots/ux/aesthetics-*` and `docs/screenshots/ux/simplify-*`. Changes continue [PR #17](https://github.com/saim-x/bachat-mobile/pull/17), with a separate commit for each coherent change.

## Floating-content refinement

The owner clarified that the pill must overlay the screens rather than reserve a separate footer band. The mobile shell now extends its body behind the bar and preserves that full-height viewport through its SafeArea. Home, Activity and Plan paint and scroll underneath the navigation pill. Their scroll padding includes the overlay and device inset so the final content and actions can still be moved completely above it.

The pill's normal maximum width is reduced from 440 to 280 logical pixels, bringing the three destinations closer together. Large text can use up to 344 pixels, constrained by the screen margins. The 64-pixel normal height, rounded corners, colors and plain icons are retained. Wide-screen navigation keeps its existing rail layout.

Regression tests measure the actual content viewport overlapping the pill on every destination and scroll to the final Plan action to verify that it remains visible and tappable, both normally and at 200% system text size.

Floating-pill verification: all 114 combined unit, widget and visual-capture checks pass; Flutter analysis reports no issues, formatting and diff checks pass, and the Android debug APK builds successfully. Updated captures show full-height content beneath the narrower pill in both appearances. The connected NOTE 23 is updated in place without clearing app data; iOS remains unverified on Windows.
