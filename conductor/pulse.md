# Pulse — MyReciBook
*State only. REWRITTEN at every checkpoint, never appended. Cap 60 lines.*

## 📍 Now
- Phase: pre-project (kickoff 2026-08-20); building unblocked, gates decide
  ship/stop (context.md §4). GATE 1 PASSED; T1 closed.
- NOW-MODE (behavioral 15–16) · checkpoint commits EVERYTHING (18) · no
  dead-end surfaces (19).
- HANDS-ON ROUND 2 (Arnar, 2026-08-09, upload-key build): CAMERA-photo
  extraction WORKS on device (first proof) · screenshots work · DROPBOX
  connect+sync WORKS on the S21 — Dropbox half of the storage smoke PASSED.
  DRIVE auth FAILS: the signature flip (debug→upload) changed the app's
  SHA-1 and the Drive Android OAuth client only knows the debug one.
  UPLOAD-KEY SHA-1 (from ~/keystores/myrecibook-upload.jks, alias upload):
  B0:E5:3A:23:85:47:3C:24:F6:8D:B5:2F:A4:4A:FD:DA:67:06:58:28
  Fix = Arnar in GCP console (gen-lang-client-0166122901): ADD a second
  Android OAuth client, same package, this SHA-1 — KEEP the debug client so
  `flutter run` debug builds still auth (tech rule 9).
- SENIOR REVIEW CLOSED (docs 08-08/08-09): all findings fixed (eb2b6a5).
  atomic_file.dart = THE write discipline (rule 7). AAB signs with the
  upload key — keystore SINGLE COPY, backup pending.
- F5 FENCE live: no silent overwrite of remote-changed files — skip +
  "N changed elsewhere"; delete-vs-edit → remote wins; restoreDown baselines.
- D2 PROXY BUILT, NOT DEPLOYED: proxy/ (key server-side, allowlist, cap
  strawman 100/mo, 10 tests, runbook). Client: EXTRACTION_PROXY_URL +
  X-Install-Id. Deploy = Arnar's gcloud/billing call ($0 tier) + cap number.
- 337 app + 10 proxy tests, analyzers clean. Versioning 0.5.0+2 strawman
  awaits Arnar. Error-log door = long-press version footer; dialog UNDESIGNED
  — tester instructions must name it.
- Turn-7 design queue: cover-image picker · nav reshape ratify · collapsing
  hero · manual entry · edit copy · batch edges (grep DEVIATION) · log door.
- Play fee: bar met; verdict = his hands-on pass (round 2 strong: extraction
  + Dropbox proven). D10: 3 free → ~$25. Stake ladder unchanged.
- OPEN (Arnar): design authority in git — unzipped design-system gitignored,
  only the zip versioned (workday 08-09 item 4).

## 🚀 Active tracks
- T3 mvp-build — extraction + Dropbox proven on-device; Drive blocked on
  SHA-1 registration only. Plan: conductor/tracks/T3-mvp-build/plan.md
- T2 landing-page — myrecibook.com registered; live 2 Sep. Channels →
  docs/marketing-channels.md (5 venues; seed accounts).

## ⚠️ Blockers
- Drive smoke ← Arnar registers the upload SHA-1 (above) in GCP console.
- Proxy deploy + listed cap number ← Arnar's gcloud/billing decision.
- Billing 3g ← Play fee ← his verdict (most evidence now in).

## 📋 Next queue (sequence — no schedule)
1. Arnar: GCP console → add Android OAuth client with upload SHA-1 → retry
   Drive connect → save → files visible in Drive → kill/reopen.
2. Verdict → fee $25 → billing 3g.
3. Arnar decisions: proxy deploy + cap · versioning · keystore backup ·
   design-authority-in-git.
4. Claude Design turn 7 · then Arnar off-repo: T2 landing + Gate-2 venues.
5. External: festival 12–16 Aug (QR, 12 testers) · 20 Aug 09:00 kickoff +
   Play Console registration.

## 📌 Parked
- Proxy DEPLOY (D2: before 11 Dec) · durable cap store (4d) · Play Integrity ·
  D9 link door · inbox strip · serving-rescale · step↔ingredient chips ·
  camera-roll nudge · cover-crop tier 2 · AI covers · telemetry (D8) · arm B
  ocr_dump · $2.99 top-up UNCONFIRMED · handwriting UNTESTED · ADR 0001
  graduation due · multi-image shares one recipe · token store → keystore
  pre-prod · orphan-image GC (post-alpha) · schema-v2 read policy · full a11y
  pass (16 Nov) · fixture superset beyond byte-identical · Dropbox production
  approval · Play App Signing SHA-1 on Drive client at first Play upload
  (THIRD cert — same errand as today's, tech rule 9).
