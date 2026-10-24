# Harden Bachat reliability and add launch-readiness checks

Handle malformed and retryable email callbacks safely; cancel stalled backend
requests; preserve appearance when preference writes fail; and show pending/offline
sync status on every tab. Exclude private caches, credentials and PIN records from
Android backup/device transfers. Add pre-signup/account data information, bundled
font notices and native license access.

Add regression tests, five isolated review captures, a location-only source/runtime
secret scan, and read-only hosted Auth/anonymous-access/redirect probes. Prepare
native-only release Auth settings separately from development settings.

Validation: all 91 application tests pass; static analysis and formatting pass;
three visual journeys pass; release JavaScript web build passes; local automated
readiness checks pass. OSV reported no advisories for 113 locked hosted packages.

This PR does not claim public launch readiness: the hosted native redirect probe
currently falls back to localhost:3000, the CLI cannot yet see the owner's login,
and real inbox delivery, public support/privacy details and a physical Android
round trip remain unverified. The owner has approved the prepared native Auth
change; credentials are the remaining dependency for applying it. No SMTP,
database data, Play Store submission, signing or release APK work is included.

[Read the evidence, screenshots and launch handoff](https://github.com/saim-x/bachat-mobile/blob/feat/ship-readiness/docs/SHIP-READINESS.md).
Every change, including individual screenshots, is committed separately.
