# Pulse — MyReciBook
*State only. REWRITTEN at every checkpoint, never appended. Cap 60 lines.*

> **Updated:** 2026-08-10 23:16 by checkpoint

## 📍 Now
- Phase: pre-project (kickoff 2026-08-20); building unblocked, gates decide
  ship/stop (context.md §4). GATE 1 PASSED; T1 closed.
- NOW-MODE (behavioral 15–16) · checkpoint commits EVERYTHING (18) · no
  dead-end surfaces (19).
- BRAND LANDED 2026-08-10: Arnar's logo (open book + steam) is now the app
  icon (adaptive + monochrome + legacy PNGs, Flutter default gone), the
  cookbook header mark, and the Cookbook tab glyph. Authority =
  docs/MyReciBook-logo/assets/logo/*.svg; app draws it from transcribed
  paths (app/lib/ui/widgets/logo_mark.dart), no new dependency.
- COVERS REWORKED same session, Arnar's call: a screenshot is NEVER the
  cover any more (they came out ugly). No-cover = drawn tile (brand
  gradient chosen from the title + logo watermark). Cover door = 'add
  cover' pill on the detail hero → photo / gallery / a screenshot / remove.
  New top-level `cover` field in the recipe JSON, absent unless set.
  Picked photos live at images/<id>-cover.jpg in the user's folder, so they
  sync and survive reinstall. UNTESTED PATH — 338 tests touch none of it.
- Release APK with dev.env keys INSTALLED on the S21 and confirmed good by
  Arnar (logo + covers). Dropbox connect+sync still the only PROVEN half of
  the storage smoke.
- DRIVE AUTH: reversed-client-id fix (tech rule 10) is in the installed
  build; Arnar's connect retry has still NOT been run. Drive smoke = queue
  head, unchanged from 2026-08-09.
- SENIOR REVIEW CLOSED. atomic_file.dart = THE write discipline (rule 7).
  F5 fence live. AAB signs with the upload key — keystore SINGLE COPY,
  backup pending.
- D2 PROXY BUILT, NOT DEPLOYED: proxy/ (key server-side, allowlist, cap
  strawman 100/mo). Deploy = Arnar's gcloud/billing call ($0 tier) + listed
  cap number.
- 338 app + 10 proxy tests, analyzers clean. Arnar has NOT audited the
  suite and distrusts its assertions — an adversarial audit is offered, not
  scheduled. Versioning 0.5.0+2 strawman still awaits him.
- Docs tidied: five dated session artifacts → docs/archive/.
  recipe-app-feasibility-report.md STAYS at root (warm strategy, cited by
  four files) — decided 2026-08-10, not stale, do not re-propose archiving.
- Turn-7 design queue: nav reshape ratify · collapsing hero · manual entry ·
  edit copy · batch edges (grep DEVIATION) · error-log door (long-press
  version footer, dialog UNDESIGNED).
- Play fee: bar met; verdict = his hands-on pass. D10: 3 free → ~$25.
- OPEN (Arnar): design authority in git — unzipped design-system gitignored,
  only the zip versioned.

## 🚀 Active tracks
- T3 mvp-build — brand + covers shipped to the phone; Drive retry still the
  one open proof. Plan: conductor/tracks/T3-mvp-build/plan.md
- T2 landing-page — myrecibook.com registered; live 2 Sep. Channels →
  docs/marketing-channels.md (5 venues; seed accounts).

## ⚠️ Blockers
- Drive smoke result ← Arnar retries connect on the installed build.
- Proxy deploy + listed cap number ← Arnar's gcloud/billing decision.
- Billing 3g ← Play fee ← his verdict.

## 📋 Next queue (sequence — no schedule)
1. Arnar: retry Drive connect → save → files visible in MyReciBook/recipes
   on Drive → kill/reopen. THEN storage smoke fully PASSED.
2. Tests on the cover flow (schema round-trip, picker branches, delete
   takes the cover file) — the one gap this session knowingly left.
3. Verdict → fee $25 → billing 3g.
4. Arnar decisions: proxy deploy + cap · versioning · keystore backup ·
   design-authority-in-git.
5. Claude Design turn 7 · then Arnar off-repo: T2 landing + Gate-2 venues.
6. External: festival 12–16 Aug (QR, 12 testers) · 20 Aug 09:00 kickoff +
   Play Console registration.

## 📌 Parked
- URL/link import (Arnar raised 2026-08-10, own session, he brings test
  links) — HEAD-ON with the bet's "not link/video scraping (permanent
  breakage)"; needs the bet re-argued or a narrow scope, not a quiet build.
- Proxy DEPLOY (D2: before 11 Dec) · durable cap store (4d) · Play Integrity ·
  D9 link door · inbox strip · serving-rescale · step↔ingredient chips ·
  camera-roll nudge · cover auto-crop tier 2 · AI covers · telemetry (D8) ·
  arm B ocr_dump · $2.99 top-up UNCONFIRMED · handwriting UNTESTED · ADR 0001
  graduation due · multi-image shares one recipe · token store → keystore
  pre-prod · orphan-image GC (post-alpha) · schema-v2 read policy · full a11y
  pass (16 Nov) · fixture superset beyond byte-identical · Dropbox production
  approval · Play App Signing cert at first Play upload needs BOTH a Drive
  client (rule 9) AND its reversed-id manifest entry (rule 10).
