# Website copy audit — canvas text vs. what's true
*For the joint overview. FIXED = changed in code. FLAG = Arnar's call.*

## Fixed in code
- "Android today · iOS in the works" / "iOS soon" → "Made for Android".
  Hard constraint: no Mac, no Swift path; Android-first IS the moat.

## Flags — need Arnar
- **$24.99** — the number only. Pay-once stands (grilled, in code:
  proxy/lib/usage_counter.dart — two weeks free = AI grace window, 1200/year
  = rescue cap, not money). Exact price tag still Arnar's to name.
- **Grocery list card** ("merged, deduplicated, asks before combining") — in
  the bet, not shipped as described.
- **"1,200 AI rescues a year"** — TRUE (kDefaultYearlyCap). "Top-ups if you
  run out" = billing seam, unstarted — the one soft claim on that card.
- **"the cap resets 1 January"** — unverified against proxy code.
- **"we read cursive"** — handwriting import untested as a claim; charming
  but risky in writing.
- **support@myrecibook.com** (contact page) — domain owned, mailbox not set
  up/verified.

## True, verified against tracks
- Cook mode EXISTS (app/lib/ui/cook_mode_screen.dart, "Start cooking" on the
  recipe page) — card claim stands, wording detail Arnar's.
- Screenshots + links + review-before-save import flow.
- Local files, Drive/Dropbox backup, PDF/Docs export.
- Barcode → Open Food Facts. Trends day/week/year with coverage.
- Gradient covers picked by title. Stitch Slate / Midnight themes.
- No accounts. Crash reporting on by default, recipe text scrubbed.

## Screenshots (docs/MyReciBook-Screenshots/, 2026-08-29)
- base = cookbook grid → LIVE in the phone frame (public/screenshots/cookbook.png).
- Copy 1 add-to-meal sheet · 2 pantry shelf · 3 "Rescuing…" · 4 source
  screenshot · 5/6 rescue review (screenshot) · 7 recipe page (unit-converted!)
  · 8/9 link rescue w/ photo-cover toggle + auto tags · 10/11 + 12 product pages.
- Weight note: cookbook.png is 728 KB — squeeze to WebP via @nuxt/image
  before deploy.

## Structure notes
- Privacy + Terms pages carry a "Draft — not yet in force" stamp until
  approved. Privacy text doubles as the Play data-safety source material.
- PhoneMockup takes `src` — drop screenshots in public/screenshots/ and pass
  the path to retire the fake screen.
