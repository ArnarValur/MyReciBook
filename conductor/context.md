# Context — MyReciBook
*Project truth. Changes only by Arnar's ruling. Cite this file, don't retell it.*
*Strategy detail: recipe-app-feasibility-report.md — cite sections (§6.5, §8).*

## The bet — do not re-litigate without new evidence
Screenshot-first import + user-owned files + pay-once, sold as "rescue the recipes
buried in your camera roll" (report §6.5). Week-two retention hook: a grocery list
that merges duplicates, syncs with the meal plan, and remembers category corrections
(§6.3). NOT: link/video scraping (§6.1 trap), not a cheap subscription, not feature
breadth. Android-first is the moat — "no Android" is a top-6 complaint against
Crouton, Mela and Pestle, and none can follow quickly.

## Hard constraints — flag loudly if a plan violates one
1. Linux (Pop!_OS) + Flutter/Dart + Galaxy S21. No Mac — any Swift/Xcode plan is dead
   on arrival; report §6.2's free on-device Apple path does not exist here.
   Substitute: ML Kit on-device OCR (free) + cheap cloud vision model for structuring;
   Play Store one-time IAP; local files + Drive (drive.file) + Dropbox app-folder.
2. Pay-once, hard paywall, stated fair-use AI cap in the listing from day one.
   Never "unlimited forever" — it can't be clawed back.
3. No backend beyond a thin extraction proxy. One JSON file per recipe, user's storage.
4. Validation before production code: Gates 1 and 2 must pass first.
5. Budget: 10–15 hrs/wk to launch, ≤10 hrs/wk after. Name the number when exceeded.
6. Build order set by the closed-test deadline: extract → save → list → open.
   Paywall, sync connectors and polish come after the alpha ships.

## Gates — pre-committed 2026-08-05, not renegotiable mid-project
Project starts 2026-08-20; anything done before is bonus and pulls Gate 1 earlier.
- GATE 1 extraction — by Sun 2026-08-30: fewer than 9 of 10 of Arnar's own recipe
  screenshots extract into a recipe usable without editing → STOP.
- GATE 2 demand — by Sun 2026-09-20: under 200 landing-page signups after posting in
  5 real communities → STOP, or re-test ONE new positioning by Sun 2026-10-04.
  One re-test only.
- GATE 3 traction — by Thu 2027-03-11 (launch + 90 days): under 1,000 downloads OR
  under $500 total revenue → stop building, leave it listed, keep as portfolio.
"STOP" = no new features, no new marketing, archive the repo.
Restate the relevant gate whenever scope beyond v1 is proposed.

## Schedule
- before 2026-08-12 .... Play Console account registered (calendar time, not work time)
- w/e 2026-08-22/23 .... extraction spike (2 days)
- 2026-09-02 ........... landing page live
- 2026-09-21 → 11-15 ... MVP build, 8 weeks of nights
- 2026-10-19 ........... HARD MILESTONE: installable alpha on closed track, 12 testers
                         opted in — build week 4, not week 8. (Requirement disappears
                         if the Play account is an organisation account.)
- 2026-11-02 ........... 14-day closed test done → apply for production access
- 2026-11-16 → 12-10 ... store listing, ASO, launch content, slack
- 2026-12-11 ........... production release
- 2027-03-11 ........... Gate 3 check
