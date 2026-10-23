"""Build the review PDF from fresh Flutter captures and recorded check results.

Requires reportlab. Run from any directory:
  python scripts/generate_ui_report.py --verification docs/reports/verification-2026-10-23.json
Screenshots are produced by the explicit tool/*_preview_test.dart checks.
"""

from __future__ import annotations

import argparse
import json
from datetime import date
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.utils import ImageReader, simpleSplit
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen.canvas import Canvas


ROOT = Path(__file__).resolve().parents[1]
SHOTS = ROOT / "docs/screenshots/ux"
INK = colors.HexColor("#142344")
MUTED = colors.HexColor("#566480")
COBALT = colors.HexColor("#0C38A9")
PAPER = colors.HexColor("#F6F7FB")
LINE = colors.HexColor("#DEE4F0")
WIDTH, HEIGHT = A4
MARGIN = 36

# The image files are actual, uncropped Flutter screen renders. A second capture
# of a scrolled page is explicitly described as such in its caption.
PAGES = [
    ("Everyday money, at a glance", "The main expense-tracking experience.", [
        ("home-light", "Home", "Monthly spending, recorded expense count, Spend/Receive and a clearly explained net flow."),
        ("activity-light", "Activity", "Search, direction filters, totals for the current results and dated transactions."),
    ]),
    ("A hands-on introduction", "Three short steps explain the app with examples you can change.", [
        ("introduction-1-light", "1 / Understand spending", "Choose Food, Rides or Fun. The description responds to the selected category."),
        ("introduction-2-light", "2 / Explore a budget", "Adjust the example monthly limit. Back, Skip and direct sign-in remain available."),
    ]),
    ("From a goal to your account", "Examples stay separate from real transactions, budgets and savings goals.", [
        ("introduction-3-light", "3 / Choose a goal", "Explore what you might save for. Teen accounts are enabled; parent accounts remain unavailable."),
        ("sign-in-light", "Sign in", "Email and password entry, password visibility, account creation and recovery. Back returns to the introduction."),
    ]),
    ("Create an account or recover access", "Persistent labels and a clear account-setup sequence.", [
        ("create-account-light", "Create an account", "The screen explains account creation, email verification and profile completion."),
        ("reset-password-light", "Reset a password", "Request an email link, or return to sign-in. This capture does not send an email."),
    ]),
    ("Profile and device protection", "The account journey includes a profile and a separate PIN on each device.", [
        ("profile-setup-light", "Complete the profile", "After email verification, enter a name and choose an age from 13 to 18."),
        ("pin-setup-light", "Create a PIN", "Choose and confirm six digits. The pictured session uses an isolated account fixture."),
    ]),
    ("Return safely and manage preferences", "Account protection and personal appearance are available in the app.", [
        ("pin-unlock-light", "Unlock Bachat", "The PIN gate protects the app when it is reopened. Forgotten-PIN recovery returns to account sign-in."),
        ("account-settings-light", "You", "The authenticated account view: profile, appearance and device PIN controls. The account itself is an isolated fixture."),
    ]),
    ("Record spending and money received", "Separate forms keep categories relevant to the kind of entry.", [
        ("spend-light", "Spend", "Enter an amount, what the purchase was, a spending category, date and optional note."),
        ("receive-light", "Receive", "Record money received with income categories such as Pocket money and Gift."),
    ]),
    ("Finish an entry and narrow the list", "Native sheets keep related tasks together.", [
        ("spend-details-light", "Transaction details", "A further view of the same expense sheet shows its date, optional note and Save transaction action."),
        ("activity-filters-light", "Filter activity", "Choose a period, category and sort order; then apply or reset the filters."),
    ]),
    ("See the scope of your spending", "Search results and category context use the same recorded transactions.", [
        ("activity-search-light", "Search results", "A search for Readings narrows both the list and its count and spending total."),
        ("home-details-light", "Home, scrolled", "The lower Home view contains category analysis and the route into savings goals."),
    ]),
    ("Edit an entry with care", "Existing records can be corrected, and deletion requires confirmation.", [
        ("edit-transaction-light", "Edit a transaction", "Review and change the recorded details. This scrolled view includes the save and delete actions."),
        ("delete-confirmation-light", "Confirm deletion", "Deletion has a clear label, distinct color and a confirmation explaining its effect on totals and activity."),
    ]),
    ("Plan the month and track a goal", "Budgets and savings have distinct roles and clear progress.", [
        ("plan-light", "Monthly plan", "Review recorded savings and category budget limits for the current month."),
        ("plan-goal-light", "Plan, scrolled", "The goal shows its saved amount, target, percentage, remaining amount and Add savings action."),
    ]),
    ("Set a limit. Give savings a purpose.", "Existing forms let you start small and update the plan later.", [
        ("budget-light", "Monthly budget", "Choose a spending category and set a limit in Pakistani rupees."),
        ("goal-light", "Savings goal", "Give the goal a name, target amount and total already saved."),
    ]),
    ("Add progress and choose an appearance", "Small, direct actions support repeated use.", [
        ("add-savings-light", "Add savings", "See what remains to reach the goal and record an addition. This does not transfer money."),
        ("appearance-light", "Appearance", "Choose System, Light or Dark using native selection controls."),
    ]),
    ("A useful start with no records", "Empty states help new accounts take their first action.", [
        ("empty-home-light", "Empty Home", "The monthly summary starts at zero. Spend and Receive are ready without sample records."),
        ("empty-plan-light", "Empty Plan", "A first-budget action appears with a short explanation; goals can be created further down."),
    ]),
    ("Dark appearance", "Semantic surfaces and readable controls adapt to a darker canvas.", [
        ("home-dark", "Home / Dark", "The identity and spending summary stay consistent across appearances."),
        ("activity-dark", "Activity / Dark", "Result counts, money amounts and explicit direction labels remain readable."),
    ]),
    ("Planning after dark", "Savings retain their warm highlight without relying on color alone.", [
        ("plan-dark", "Plan / Dark", "Monthly budget values and progress use the dark theme's semantic colors."),
        ("plan-goal-dark", "Goal / Dark", "Saved amounts, completion percentage and the remaining target stay explicit."),
    ]),
    ("Account screens after dark", "The account journey follows the selected appearance too.", [
        ("create-account-dark", "Create account / Dark", "The same labeled inputs and setup sequence on the dark canvas."),
        ("pin-unlock-dark", "Unlock / Dark", "The device privacy screen follows the app appearance."),
    ]),
    ("Device and account controls", "The authenticated settings view uses an isolated account fixture.", [
        ("account-settings-dark", "You / Dark", "Appearance, Change PIN and Lock now are available for a signed-in teen account."),
        ("account-actions-light", "Account actions, scrolled", "Reset a password or sign out. Sign-out warns about unsynced records before discarding local changes."),
    ]),
    ("More room for larger text", "320 logical pixels wide, with text scaled to 200 percent.", [
        ("home-light-large", "Home / Large text", "Amounts and actions reflow; the page remains scrollable to reach the rest of the information."),
        ("activity-light-large", "Activity / Large text", "Search, filters and actions grow with the text rather than shrinking essential labels."),
    ]),
    ("Large text in dark appearance", "The same narrow-screen checks cover planning and onboarding.", [
        ("plan-dark-large", "Plan / Large text", "The plan uses natural wrapping and vertical scrolling at larger text settings."),
        ("introduction-2-dark-large", "Introduction / Large text", "Interactive example controls remain reachable. Reduced-motion settings disable the step transition."),
    ]),
    ("Learning is coming soon", "The app describes unavailable features honestly.", [
        ("learn-light", "Learn / Light", "The learning area remains a coming-soon screen, rather than an unfinished action."),
        ("learn-dark", "Learn / Dark", "The same availability message and brand illustration in dark appearance."),
    ]),
]


class Report:
    def __init__(self, output: Path, verification: dict):
        self.data = verification
        self.page = 0
        self.canvas = Canvas(str(output), pagesize=A4, pageCompression=1)
        self.canvas.setTitle("Bachat — Latest app visual review")
        self.canvas.setAuthor("Bachat by YouthPay")
        self.canvas.setSubject("Latest Flutter app screens and verified UX improvements")

    def text(self, value, x, y, width, size=10, color=MUTED, font="Body", leading=None):
        self.canvas.setFillColor(color)
        self.canvas.setFont(font, size)
        leading = leading or size * 1.5
        for paragraph in str(value).split("\n"):
            for line in simpleSplit(paragraph, font, size, width):
                self.canvas.drawString(x, y, line)
                y -= leading
        return y

    def start(self, title):
        self.page += 1
        self.canvas.setFillColor(colors.white)
        self.canvas.rect(0, 0, WIDTH, HEIGHT, fill=1, stroke=0)
        self.canvas.bookmarkPage(f"page-{self.page}")
        self.canvas.addOutlineEntry(title, f"page-{self.page}")
        self.text("BACHAT  /  APP REVIEW", MARGIN, HEIGHT - 34, 400, 8, COBALT)

    def finish(self):
        self.canvas.setStrokeColor(LINE)
        self.canvas.line(MARGIN, 49, WIDTH - MARGIN, 49)
        self.text(f"{self.data['date']} · App source {self.data['app_revision']}", MARGIN, 33, 440, 8)
        self.canvas.setFont("Body", 8)
        self.canvas.drawRightString(WIDTH - MARGIN, 33, f"{self.page:02d}")
        self.canvas.showPage()

    def image(self, stem, x, top, max_width, max_height):
        reader = ImageReader(str(SHOTS / f"{stem}.png"))
        iw, ih = reader.getSize()
        factor = min(max_width / iw, max_height / ih)
        width, height = iw * factor, ih * factor
        x += (max_width - width) / 2
        self.canvas.setStrokeColor(LINE)
        self.canvas.setLineWidth(0.6)
        self.canvas.roundRect(x - 2, top - height - 2, width + 4, height + 4, 8, fill=0)
        self.canvas.drawImage(reader, x, top - height, width=width, height=height)

    def cover(self):
        self.start("Bachat — Latest app visual review")
        self.text("bachat", MARGIN, HEIGHT - 94, 500, 44, INK, "Heading")
        self.text("Latest app visual review", MARGIN, HEIGHT - 127, 500, 22, COBALT, "Heading")
        display_date = date.fromisoformat(self.data["date"]).strftime("%d %B %Y")
        self.text(f"{display_date}  ·  Flutter for Android and iOS", MARGIN, HEIGHT - 154, 500, 10)
        self.canvas.setStrokeColor(LINE)
        self.canvas.line(MARGIN, HEIGHT - 176, WIDTH - MARGIN, HEIGHT - 176)
        self.image("home-light", 315, 634, 240, 464)
        y = self.text("A clearer way to track\neveryday money.", MARGIN, 624, 250, 24, INK, "Heading", 31)
        y = self.text("An updated first-use journey and more direct tools for spending, budgets and savings.", MARGIN, y - 18, 244, 12)
        for title, body in [
            ("Try the app's ideas", "Interactive spending, budget and goal examples during onboarding."),
            ("Record and understand", "Separate Spend/Receive forms, clearer activity and filtered totals."),
            ("Make a plan", "Budget progress, savings targets and useful first-action prompts."),
        ]:
            y = self.text(title, MARGIN, y - 23, 244, 12, COBALT, "Heading")
            y = self.text(body, MARGIN, y - 3, 244, 10)
        self.text("About these screenshots", MARGIN, 126, 500, 11, INK, "Heading")
        self.text("Actual Flutter renders of the latest app, using isolated sample records and account fixtures. Amounts and names are examples. Captures show selected scroll positions; animations are described in the captions.", MARGIN, 108, WIDTH - 2 * MARGIN, 9)
        self.finish()

    def pair(self, title, subtitle, pictures):
        self.start(title)
        self.text(title, MARGIN, HEIGHT - 80, WIDTH - 2 * MARGIN, 25, INK, "Heading")
        self.text(subtitle, MARGIN, HEIGHT - 106, WIDTH - 2 * MARGIN, 10)
        column = (WIDTH - 2 * MARGIN - 24) / 2
        for index, (stem, label, caption) in enumerate(pictures):
            x = MARGIN + index * (column + 24)
            self.image(stem, x, 696, column, 515)
            self.text(label, x, 162, column, 12, COBALT, "Heading")
            bottom = self.text(caption, x, 144, column, 9)
            if bottom < 75:
                raise ValueError(f"Caption does not fit: {stem}")
        self.finish()

    def verification(self):
        self.start("What changed and what was checked")
        self.text("What changed", MARGIN, HEIGHT - 82, 520, 28, INK, "Heading")
        y = HEIGHT - 117
        for text in [
            "A three-step interactive introduction, reversible navigation, direct sign-in and Android system Back support.",
            "More useful Home and Activity layouts, recorded expense counts, readable dates and totals for filtered results.",
            "Contextual first-budget and first-goal actions, clearer form navigation, named progress and distinct delete controls.",
            "Consistent light/dark surfaces and native text scaling. Introduction animations respect reduced motion.",
        ]:
            y = self.text("• " + text, MARGIN, y, 520, 11) - 13
        y = self.text("Verification", MARGIN, y - 6, 520, 23, COBALT, "Heading") - 15
        for check in self.data["checks"]:
            y = self.text(check["label"], MARGIN, y, 160, 10, INK, "Heading")
            right_bottom = self.text(check["result"], 209, y + 15, 345, 10)
            y = min(y, right_bottom) - 18
        y = self.text("Scope and remaining device checks", MARGIN, y - 3, 520, 16, INK, "Heading")
        y = self.text("Teen accounts remain the current release scope. Parent onboarding and learning content remain unavailable. Bank/SMS/Gmail imports are future work. Physical Android/iOS use, iOS signing and assistive-technology checks are separate from the automated checks above.", MARGIN, y - 6, 520, 10)
        y = self.text(f"Branch: {self.data['branch']}", MARGIN, y - 12, 520, 9)
        if self.data.get("pr_url"):
            self.text("Review the pull request", MARGIN, y - 7, 520, 10, COBALT)
            self.canvas.linkURL(self.data["pr_url"], (MARGIN, y - 22, 230, y + 4), relative=0)
        if y < 70:
            raise ValueError("Verification page does not fit")
        self.finish()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--verification", required=True, type=Path)
    parser.add_argument("--output", type=Path, default=ROOT / "docs/reports/Bachat-App-Review-2026-10-23.pdf")
    args = parser.parse_args()
    data = json.loads(args.verification.read_text(encoding="utf-8-sig"))
    for stem in {"home-light"} | {shot[0] for page in PAGES for shot in page[2]}:
        if not (SHOTS / f"{stem}.png").is_file():
            raise FileNotFoundError(f"Missing screenshot: {stem}")
    pdfmetrics.registerFont(TTFont("Heading", str(ROOT / "assets/fonts/InstrumentSans.ttf")))
    pdfmetrics.registerFont(TTFont("Body", str(ROOT / "assets/fonts/Inter-Regular.ttf")))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    report = Report(args.output, data)
    report.cover()
    for title, subtitle, screenshots in PAGES:
        report.pair(title, subtitle, screenshots)
    report.verification()
    report.canvas.save()
    print(f"Created {args.output} ({report.page} pages)")


if __name__ == "__main__":
    main()
