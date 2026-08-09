# Pulse — MyReciBook
*State only. REWRITTEN at every checkpoint, never appended. Cap 60 lines.*

## 📍 Now
- Phase: pre-project (kickoff 2026-08-20); building unblocked, gates decide
  ship/stop (context.md §4). GATE 1 PASSED; T1 closed.
- NOW-MODE (behavioral 15–16) · checkpoint commits EVERYTHING (18) · no
  dead-end surfaces (19).
- HANDS-ON ROUND 2 (Arnar, 2026-08-09, upload-key build): CAMERA-photo
  extraction WORKS on device (first proof) · screenshots work · DROPBOX
  connect+sync WORKS — Dropbox half of the storage smoke PASSED.
- DRIVE AUTH: two causes found+fixed same evening. (1) signature flip →
  Arnar created a second Android OAuth client with the upload SHA-1
  (id 213431165631-72m8s4…nh, custom-URI-scheme box ticked; debug client
  kept). (2) Google POLICY: package-scheme redirect always 400s — installed
  apps MUST redirect to the REVERSED client id (tech rule 10). Fixed in
  code: oauth.dart derives it, AuthBridge routes com.googleusercontent.apps.*,
  manifest carries one <data> per client. Build with fix INSTALLED on S21 —
  RETRY RESULT UNKNOWN at checkpoint; Drive smoke = queue head.
- New client id lives in .env → app/dev.env (both gitignored). Debug-signed
  builds can't Drive-auth until their reversed id joins the manifest.
- SENIOR REVIEW CLOSED (docs 08-08/08-09): all findings fixed (eb2b6a5).
  atomic_file.dart = THE write discipline (rule 7). AAB signs with the
  upload key — keystore SINGLE COPY, backup pending.
- F5 FENCE live: no silent overwrite of remote-changed files — skip +
  "N changed elsewhere"; delete-vs-edit → remote wins; restoreDown baselines.
- D2 PROXY BUILT, NOT DEPLOYED: proxy/ (key server-side, allowlist, cap
  strawman 100/mo). Client: EXTRACTION_PROXY_URL + X-Install-Id. Deploy =
  Arnar's gcloud/billing call ($0 tier) + listed cap number.
- 338 app + 10 proxy tests, analyzers clean. Versioning 0.5.0+2 strawman
  awaits Arnar. Error-log door = long-press version footer; dialog
  UNDESIGNED — tester instructions must name it.
- Turn-7 design queue: cover-image picker · nav reshape ratify · collapsing
  hero · manual entry · edit copy · batch edges (grep DEVIATION) · log door.
- Play fee: bar met; verdict = his hands-on pass (round 2 strong). D10:
  3 free → ~$25. Stake ladder unchanged.
- OPEN (Arnar): design authority in git — unzipped design-system gitignored,
  only the zip versioned (workday 08-09 item 4).

## 🚀 Active tracks
- T3 mvp-build — extraction + Dropbox proven on-device; Drive reversed-
  redirect fix installed, awaiting retry. Plan: conductor/tracks/T3-mvp-build/plan.md
- T2 landing-page — myrecibook.com registered; live 2 Sep. Channels →
  docs/marketing-channels.md (5 venues; seed accounts).

## ⚠️ Blockers
- Drive smoke result ← Arnar retries connect on the installed build.
- Proxy deploy + listed cap number ← Arnar's gcloud/billing decision.
- Billing 3g ← Play fee ← his verdict (most evidence now in).

## 📋 Next queue (sequence — no schedule)
1. Arnar: retry Drive connect → save → files visible in MyReciBook/recipes
   on Drive → kill/reopen. THEN storage smoke fully PASSED.
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
  approval · Play App Signing cert at first Play upload needs BOTH a Drive
  client (rule 9) AND its reversed-id manifest entry (rule 10).
