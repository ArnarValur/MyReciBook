# Scratchpad

Arnar's notes. Fresh page pulled 2026-08-21 on Arnar's word; old page in git history.

## Carried over — still live
- Grocery list revamp — ask Arnar what he wants changed.
- Import recipes from other apps — research feasibility.
- User feedback channel — Crashlytics covers the error half; feedback half still open.
- OPEN, Arnar's call: Crashlytics on by default with an off switch, vs off until opt-in.
  Built 2026-08-21 defaulting OFF, toggle present. One constant flips it:
  kCrashReportingDefaultOn in app/lib/data/crash_reporter.dart.
- Decided, not yet in code: remove the delete-screenshot toggle from import review
  (app/lib/ui/import_review_screen.dart).
- Crashlytics install recipe — DONE in code 2026-08-21. Only google-services.json
  is left, and that is a Console download (docs/runbook-dev-deploy.md step 7).

## 2026-08-21 — weekend plan, agreed (Cowork session)

Sequence, not schedule. Finish line: Arnar installs MyReciBook from Play + landing site moving.

**Stage 1 — harden**
- Device verify diary categories 2–4.
- ~~Three pinned link-picker test files~~ — checked 2026-08-21: manual_entry (5)
  and edit_recipe (4) pass, recipe_detail_link no longer exists. Nothing to fix.
- Secret scan done 2026-08-21: client_secret, dev.env, key.properties all untracked,
  never in git history. Clean.

**Stage 2 — infra on MyReciBook-Dev** (Google ecosystem, agreed)
- Proxy → Cloud Run, key in Secret Manager, per ai-cap-mechanics.md §4.
  CODE READY 2026-08-21, NOT DEPLOYED — gcloud absent on PlutoII.
  Runbook with every click-path: docs/runbook-dev-deploy.md.
- Durable cap counter → Firestore per §1 — BUILT. Firestore database created.
  Usage measuring on (per-install ID until billing).
- Offer confirmed 2026-08-21: two weeks free, then 1200/year. Grace spending is
  recorded separately (graceUsed), so free is still measured.
- Arnar's catch: added a 50/bucket/day governor, live during the free fortnight
  too — the offer must not be drainable in a day.
- Prepay Gemini credits, auto-reload off. Spend-cap budgets $50 Gemini / $10 Cloud Run,
  plus one alerts-only budget across the billing account.
- Unparked by Arnar: Crashlytics · Play key backup.
- Cost ceiling Arnar set: up to ~100–200 NOK/mo is fine; expected spend ≈ 0.

**Stage 3 — Play internal track**
- Release bundle, app created in Play Console, data safety form, privacy policy URL
  (avj.info hosts it until myrecibook.com exists).
- Internal testing track → Arnar installs from Play. First official user.
- Update propagation = push a new bundle to the track, Play auto-updates every install.
  Prove it with the next build. (Old scratchpad question "confirm update flow" — confirmed.)

**Stage 4 — landing site**
- Base: Arnar's AI Studio prototype — keep the elements he likes. SEO is the point.
- Cats on the page. Non-negotiable; they are the shareholders.
- Hosting decision when the stage opens (Firebase Hosting is the ecosystem default, free tier).

**Cap decision**
- Working number moves 600 → 1200 rescues/year ("100 a month"). Math at verified
  2026-08-21 pricing ($0.30/$2.50 per M): maxed user $3.84/yr, all-worst-path $6.72/yr,
  against ~$21.24 net per sale. Fleet cost follows real usage (~150/yr), not the cap.
- Nothing prints in the listing until closed-test usage data confirms.
- Once printed, 1200 can rise, never fall.

Parked by Arnar for another session: tester recruitment / branching out to networks —
he has ideas, ask him there.
