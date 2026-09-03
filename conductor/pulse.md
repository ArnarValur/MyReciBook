# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*

> **Updated:** 2026-09-03

## 📍 Now
- Phase: closed test + Play review. 0.20.0+42 is what Play holds (tag
  `the-first-0.20.0+42`); main moves freely, hotfixes branch from the tag.
- Closed "Alpha" (NO+SE) live, 1 opted in — internal testers do NOT count; the
  12×14d clock needs 12 through the closed opt-in link.
- Drive on prod DONE: Android OAuth client 283856393795-2jpu0hnvnbglr8pihpnrri
  2vqq932dsd on Play's app-signing SHA-1, consent screen published to
  production, app/prod.env off the DEV client. `drive.file` needs no review.
- Offer = terms: 1,200 grant never refills, top-up 600 for $5; both proxies
  live on the no-refill ledger.
- PROD LIVE: myrecibook.com + www on Cloud Run; Firestore eur3; keys in Secret
  Manager; Firebase Production; prod key on prepaid Gemini credits. Contact
  form posts to DEV on purpose. Website picker hidden, non-en pages stickered.
- Release path ready, NOT for testers: app/prod.env + build-release.sh.
- .aab: `flutter build appbundle --release --dart-define-from-file=dev.env`.

## 🚀 Active tracks
- mvp-build — THE focus (Arnar 2026-09-02). Open: Play review outcome, 10 more
  closed testers, listing + welcome screenshots, App Check SHA-256, card on
  import sheet + paywall, billing seam, CLI Play publishing.
- ouroboros — side experiment in the worktree, never blocks mvp-build (Arnar
  2026-09-02). Slice one a–f built + tested on branch `ouroboros`; folding it
  into main is looked at only if the PoC proves itself.
- market — open: Q2 export recon (Arnar running), Q5 steal list (rides
  ouroboros), Q6 cadence. i18n PAUSED (Decision 2).

## ⚠️ Blockers
- None open.

## 📌 Parked
- i18n paused · nutrition dormant · 429 means three things, app says one ·
  borrowed listing photos (takedown clause) · is/sv stale money rows · stale
  tests cookbook_view ×2 + recipe_diary_chain ×1 + shell ×2 · 34 deps outdated
  · serving labels ignore units toggle · pack math can't reach density table ·
  audit H2/M1-M6/L1-L4 · app-side Faroese needs a custom delegate (da falls).
