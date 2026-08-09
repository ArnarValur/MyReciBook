# Pulse — MyReciBook
*State only. REWRITTEN at every checkpoint, never appended. Cap 60 lines.*

## 📍 Now
- Phase: pre-project (kickoff 2026-08-20); building unblocked, gates decide
  ship/stop (context.md §4). GATE 1 PASSED; T1 closed.
- NOW-MODE (behavioral 15–16) · checkpoint commits EVERYTHING (18) · no
  dead-end surfaces (19).
- SENIOR REVIEW CLOSED (docs/senior-review-2026-08-08.md, workday docs
  08-08/08-09): every finding fixed incl. the 18 from the 08-09 correctness
  lens (eb2b6a5). atomic_file.dart = THE write discipline (tech rule 7).
  Release AAB signs with the UPLOAD KEY (~/keystores/myrecibook-upload.jks —
  SINGLE COPY, backup pending).
- F5 FENCE live: sync never overwrites a remote file whose rev moved — skip +
  "N changed elsewhere" in status lines; local-delete vs remote-edit → remote
  wins, claim released; restoreDown baselines revs.
- D2 PROXY BUILT, NOT DEPLOYED: proxy/ (key server-side, allowlist,
  per-install cap strawman 100/mo, 10 tests, Cloud Run runbook). Client done:
  EXTRACTION_PROXY_URL + X-Install-Id (install_id.dart). Deploy needs Arnar:
  gcloud/billing on gen-lang-client-0166122901 ($0 tier) + listed cap number.
- ON THE S21 (08-09): upload-key build with creds installed, launched clean.
  Signature flip forced one-time uninstall — FOLDER RE-PICK NEEDED, grocery
  list gone; SAF-folder recipes intact. Storage smoke still NOT run.
- 337 app + 10 proxy tests, analyzers clean (strict). Versioning 0.5.0+2
  strawman awaits Arnar. Error-log door = long-press version footer (padded);
  dialog UNDESIGNED — tester instructions must name the long-press.
- Turn-7 design queue: cover-image picker · nav reshape ratify · collapsing
  hero · manual entry · edit copy · batch edges (grep DEVIATION) · log door.
- Play fee: strong-build bar met; verdict = his hands-on pass. D10: 3 free →
  ~$25. Stake ladder: 150 paid ≈ org account · ~285 ≈ MacBook → iOS.
- OPEN (Arnar): design authority in git — unzipped design-system now
  gitignored, only the zip versioned (workday 08-09 item 4).

## 🚀 Active tracks
- T3 mvp-build — review closed, F5 + D2 built, fresh build on-device; next:
  Arnar pokes it → storage smoke → verdict → fee → billing 3g.
  Plan: conductor/tracks/T3-mvp-build/plan.md
- T2 landing-page — myrecibook.com registered; live 2 Sep. Channels →
  docs/marketing-channels.md (5 venues; seed accounts).

## ⚠️ Blockers
- Storage smoke needs Arnar (re-pick folder, Drive/Dropbox login on S21) —
  runbook Part C; failure modes in docs/storage-creds-runbook.md.
- Proxy deploy + listed cap number ← Arnar's gcloud/billing decision.
- Billing 3g ← Play fee ← hands-on verdict.

## 📋 Next queue (sequence — no schedule)
1. Arnar: poke fresh build (re-pick folder) → storage smoke: connect Dropbox
   AND Drive → save → files visible remotely → kill/reopen.
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
  approval + Play-signing SHA-1 on Drive client.
