# Relay — MyReciBook
*One entry per session, newest last, ≤10 lines, plain language.
Past 12 entries: trim to newest 8, archive to conductor/pulse-archive/relay-pre-{date}.md.*

## 2026-08-05 — v3.1 initialized · T1 groundwork · partnership language
- What happened: emitted the v3.1 conductor into a fresh repo (7cc39dd), then built the
  whole T1 spike toolkit — schema v1 draft, structuring prompt, zero-dep harness
  (compile-verified), ocr_dump source. The 22–23 Aug spike is now "run it".
- For Arnar: ~30 min of phone/laptop time (screenshots + free key) is all that's left
  before the festival; everything else waits for you, armed.
- Agreed: Play Console moves to 20 Aug (festival budget; slack spent) · cooperative
  language everywhere, never authority framing (behavioral rule 13) · STATE.md stays a
  thin pointer.
- Scheduled: 20 Aug 09:00 kickoff session · 30 Aug 18:00 Gate-1 verdict session.
- Next: queue item 1 in pulse (screenshots + key + smoke-run, ~30 min).

## 2026-08-06 — smoke PASSED · constraint 4 amended · engine build began
- What happened: arm A smoke test on 4 real screenshots (2 multi-image recipes, ads,
  dark mode) extracted cleanly — no invented steps. Architecture draft written, then
  3-lens adversarial review (22 findings) → v2; unanimous blocker fixed: schema
  original_images is now an array. All-nighter: app/ scaffolded
  (com.merkurialstudio.myrecibook), domain + data layers written, analyze clean;
  ocr_dump APK built for arm B. Session cut short by an IDE reload — checkpointed.
- Decided together: constraint 4 amended — gates judge ship/stop, not building
  (agent-hours changed the cost math) · Arnar owns skin, agent owns engine ·
  no Icelandic test framing (sources are English web/social) · Play fee after
  festival · /grill on P1–P7 before building further.
- Next: grill session, then engine remainder; Arnar: 6 screenshots.

## 2026-08-06 (later) — grill complete: 8/8 settled · taught while deciding
- What happened: the full /grill ran in a cowork session — visual decision map,
  then three recommend-first rounds. All 8 agreed as recommended: P1 rescan-only ·
  P2 cap machinery + constraint-3 amendment · P3 Provider · P4 inbox cut ·
  P5 proxy post-alpha (restricted dev key in the closed track) · P6 editing
  minimum · P7 spike outputs = golden fixtures · telemetry none in alpha.
  Folded same-session: T3 D2–D8 · T1 graduation · context.md §3 · draft §9 · tracks.
- Learned: Arnar wants concepts taught in plain words as we build — the
  two-folders model (Gallery input vs owned SAF folder) cleared real confusion;
  his camera-roll auto-scan idea is parked post-v1, enters the same door.
- Next: engine remainder in Claude Code (tests → bare UI → device run);
  Arnar: 6 honest screenshots (~20 min).

## 2026-08-06 (design drop) — Arnar's 8 screens land · link door decided
- Arnar delivered the full skin spec early, in the pre-festival all-nighter push
  (festival starts 12 Aug): import sheet, batch
  queue, review, cookbook, detail, cook mode, paywall, storage → docs/design/.
  Four screens solved open engine questions (pairing toggle, flagged-only review,
  provenance flip, cap-on-the-wall paywall).
- Decided together (T3 D9): link import = post-alpha bonus, blogs-only via
  JSON-LD, no AI cost; social links get "screenshot the caption" honesty —
  report §6.5's droppable-bonus, which Arnar's own annotation re-derived.
- Next: unchanged — engine tests in Code; Arnar: screenshots THIS week (all-nighter
  window before the 12th) — arm B this week could pull Gate 1 ~3 weeks early.
- Honest note: f05d8c5 ALSO carries the live Code session's engine slice (bare UI
  ×3 screens, 4 test suites, spike fixtures) — a Cowork `add -A` swept it in.
  Nothing lost; graduated as technical rule 5. Code session: `flutter test`
  before building further — its work is committed but unverified-run here.

## 2026-08-06 (night) — engine slice done: 77 tests + bare UI, running on the S21
- What happened: a 15-agent workflow built the slice in one night — engine tests
  (spike fixtures as goldens) + bare UI in parallel, then a 3-lens adversarial
  review: 11 findings, 7 survived the skeptics, all fixed (stuck import spinner,
  unreachable retry on timeouts, hostile-path confinement, ½-mojibake, FAB
  double-tap, silent notes-save loss). Debug APK installed + launched clean on S21.
- For Arnar: the app is ON YOUR PHONE — open it, hit +, pick the two smoke
  screenshots, watch it extract → edit → save. Debug config you asked for is
  live: Run and Debug → "MyReciBook (S21, dev key)".
- Watch-out: the design-drop session's commit swept this work in early (f05d8c5)
  — harmless solo; both sessions graduated the same lesson, merged as technical
  rule 5 (dev.env = 6, utf8 = 7). Next: queue 1–3 in pulse.

## 2026-08-06 (late) — first REAL import passed on the S21 · cover idea parked
- Arnar ran the app for real: extract → edit → save worked, and add-screenshot
  pulled the method in — "comes out pretty well for the bare ui". T3 step 4 ✔.
  The whole engine slice is now proven end-to-end on the actual device.
- Idea parked (Arnar's, not built): auto-detect + crop the recipe cover photo.
  Two tiers in pulse 📌 — free BoxFit.cover of screenshot 1 at skin time; AI
  bbox crop only if the Gate-1 spike proves it (same call, no extra cost).
- Next session: UI-heavy — Arnar brings many screens and new layouts; agent
  pairs the skin onto the proven flows, then share-sheet + SAF store (arch §8).

## 2026-08-06 (all-nighter, skin) — all 12 hi-fi screens built · skin live on the S21
- What happened: Arnar's Claude Design project landed (DittoDatto design system,
  full handoff spec → docs/design/handoff.md). One session built the whole set:
  tokens → theme (light+dark), shared skin primitives, alpha screens wired on
  the proven flows (import sheet · review with confirm chips · cookbook grid
  with screenshot covers · detail with provenance flip + favorite heart · cook
  mode with wakelock+timer), and the five post-alpha screens (batch, paywall,
  storage, grocery, cap) as debug-gallery previews. Fonts bundled offline-safe
  (rule 8); schema gained the agreed favorite bool. 77 green → APK on the S21,
  skin verified rendering with Arnar's real recipe. Review-note catches all in.
- For Arnar: open the app — it looks like your mockups now. Long-press the
  wordmark for the post-alpha previews. Next session: share-sheet + SAF.
- Deep doc: docs/design/skin-implementation-map.md — every deviation + why,
  where each screen lives, test-contract changes, post-alpha wiring points.

## 2026-08-06 (eve→night, cowork) — arm A in-app · blitz · money + infra rounds
- Arnar challenged the spike protocol — right, it predated the app. T1 D5:
  arm A judged in-app (y/n at review BEFORE edits); harness = tuning fallback;
  unit = recipes/rows (8 more → 10). Arm B unchanged.
- Blitz (constraint 4 as amended): 4 Code nights — SAF → grocery 4a → batch
  3b+manual → settings+D9; billing joins IF the fee lands Fri (Arnar's offer).
  Fri = closed-test-complete; account = PERSONAL (no org nr) → 12×14 stands,
  festival = tester QR.
- T3 D10 on delegated call: 3 lifetime free imports → one-time unlock, ~$25
  anchor, price ON the landing page. Dashboard = Play Console (nothing to
  host). Gemini project now TIER 3 POSTPAY (cap task queued). Proxy home:
  Cloud Run beside Gemini, service identity — supersedes CF rec. Firebase: no.
- Arnar's stake: 150 buyers ≈ 30k NOK ≈ funds his formal org. Learned:
  hyperfocus etiquette (no clock talk, banked stays banked) — behavioral
  candidate, needs his explicit yes next session.
- Next: Code night 1 = SAF (firing); fee Fri if strong; Gate 1 target: w/e.

## 2026-08-06 (day, cowork) — T2 channel research (deep-research + verify)
- Where MyReciBook gets seen: full playbook → docs/marketing-channels.md.
  Gate-2 five: r/SideProject · r/alphaandbetausers · FB answer-posting
  (Declutter 365 / Grandma's Secret Recipes / Instant Pot) · r/Cooking
  comments · XDA beta post. BetaList $39 optional; $100 ads = skip (noise).
- Verification killed: r/androidapps (bans ALL self-promo + tester asks),
  r/ADHD, Product-Hunt-as-install-driver. Beckman = 616K subs, Dec series real.
- Launch pitches: Beckman → Android Police (Jon Gilbert; ReciMe screenshot
  import reported broken May 2026 = the angle) → AA Walker → Show HN local-first.
- Bet scope: "can't follow me" = Crouton/Mela/Pestle only; ReciMe wedge =
  pay-once + working screenshot import + owned files (doc §7).

## 2026-08-06 (night→dawn, Code) — no-limits run complete: 6/6 items, 77 → 309 tests
- The whole remaining alpha surface landed in one run, each item built,
  adversarially reviewed, tested, and verified installed on the S21:
  SAF store + share-sheet · grocery engine + nav shell (bar + 5c drawer) ·
  saved-recipe edit (D6 am.) · storage connect 3h (Drive+Dropbox, full on
  placeholder creds) · batch 3b + manual entry · settings (minimal, flagged).
- For Arnar: your strong-build bar is met on paper — the verdict is a
  hands-on pass on the phone. Creds spec + debug SHA-1 are in chat; two
  dev.env lines activate storage. ~15 DEVIATION flags await your design turn.
- Next: your review → fee call → billing 3g. Code queue otherwise empty.
