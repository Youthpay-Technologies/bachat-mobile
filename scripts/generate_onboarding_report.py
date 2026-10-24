"""Create a concise, complete onboarding walkthrough from one captured journey.

First run: flutter test tool/onboarding_preview_test.dart
Then run: python scripts/generate_onboarding_report.py
Requires ReportLab; reuses the visual review's page layout and bundled fonts.
"""

import json

from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

from generate_ui_report import ROOT, SHOTS, Report


PAGES = [
    ("1 / Explore Bachat", "For teens aged 13–18. Back and Skip let you move freely through the introduction.", [
        ("onboarding-01-spending-light", "Understand spending", "Choose Food, Rides or Fun to explore category tracking. These are examples; no money records are created."),
        ("onboarding-02-budget-light", "Try a monthly limit", "Move the slider to explore a budget. Your real budgets are set after signing in."),
    ]),
    ("2 / Choose a goal and continue", "New users create an account; returning users can sign in directly from any introduction step.", [
        ("onboarding-03-goal-light", "Choose a saving idea", "Explore a goal, then select Continue as a teen. This example does not create a savings goal. Parent accounts are coming soon."),
        ("onboarding-04-sign-in-light", "Open account creation", "Select Create an account. Existing users enter their email and password; Forgot password opens recovery."),
    ]),
    ("3 / Create and verify the account", "Create an account, confirm the email outside Bachat, then return and sign in.", [
        ("onboarding-05-create-account-light", "Create the account", "Enter an email and a password of at least 10 characters, then select Create account."),
        ("onboarding-06-verify-email-light", "Verify the email", "Open the confirmation link in your email app, then return and sign in. Use Resend confirmation email if needed. The email app is outside Bachat."),
    ]),
    ("4 / Personalize and protect", "After verification and sign-in, finish the profile and set up this device's PIN.", [
        ("onboarding-07-profile-light", "Complete the profile", "Enter your name, choose your age (13–18), then select Start tracking."),
        ("onboarding-08-pin-light", "Create a device PIN", "Choose six digits, enter them again to confirm, then select Save PIN. Each device has its own PIN."),
    ]),
    ("5 / Start tracking", "Onboarding ends at your empty Home screen. The next step is optional: record a first expense.", [
        ("onboarding-09-first-home-light", "Onboarding complete", "A new account starts with zero spending and no sample records. Choose Spend or Receive when you are ready."),
        ("onboarding-10-first-expense-light", "Record a first expense", "Enter the amount, purchase and category. Check the date, optionally add a note, then select Save transaction."),
    ]),
    ("6 / See the result and return", "The first entry is recorded. Device protection is ready for the next visit.", [
        ("onboarding-11-expense-saved-light", "See the recorded expense", "Monthly spending and recent activity update after saving. You can continue with more entries, budgets or savings goals."),
        ("onboarding-12-returning-unlock-light", "Unlock on return", "Enter the device PIN when Bachat locks. Forgotten PIN recovery requires signing in again; discarding unsynced changes requires confirmation."),
    ]),
]


def main():
    data = json.loads((ROOT / "docs/reports/verification-2026-10-23.json").read_text(encoding="utf-8-sig"))
    output = ROOT / "docs/reports/Bachat-Complete-Onboarding-2026-10-23.pdf"
    for _, _, shots in PAGES:
        for stem, _, _ in shots:
            if not (SHOTS / f"{stem}.png").is_file():
                raise FileNotFoundError(f"Capture the onboarding journey first: {stem}")
    pdfmetrics.registerFont(TTFont("Heading", str(ROOT / "assets/fonts/InstrumentSans.ttf")))
    pdfmetrics.registerFont(TTFont("Body", str(ROOT / "assets/fonts/Inter-Regular.ttf")))
    report = Report(output, data, label="BACHAT  /  COMPLETE ONBOARDING  /  SAMPLE ACCOUNT")
    report.canvas.setTitle("Bachat — Complete onboarding experience")
    report.canvas.setSubject("Six-page onboarding walkthrough with twelve actual Flutter screenshots")
    for title, subtitle, shots in PAGES:
        report.pair(title, subtitle, shots)
    report.canvas.save()
    print(f"Created {output} ({report.page} pages, 12 screenshots)")


if __name__ == "__main__":
    main()
