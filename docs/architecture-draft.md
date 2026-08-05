# MyReciBook — architecture draft

*DRAFT v2, 2026-08-06 — rewritten after a 3-lens adversarial review (constraints ·
build-realism · consistency; 22 findings folded in). For /grill — nothing here is
settled until grilled. Decided facts cite context.md / T1 plan; proposals are
marked **P#** and are the grill targets. This doc must never re-litigate the bet
or pull post-alpha scope forward (context.md §The bet, §Gates).*

*Team = Arnar + agents. The scarce resource is Arnar's human hours, not headcount.*

## 1. System at a glance

```
 ┌─────────────────────────── Android phone ───────────────────────────┐
 │                                                                     │
 │  share-sheet / picker ─→ app-private cache (always, first thing)    │
 │        ↓                                                            │
 │  [ML Kit OCR]* ─→ extraction client ────────────────────────────────┼──→ ┌────────────┐
 │        ↓                                                            │    │ thin proxy │──→ flash-class
 │  review screen (editable) ←─ validated recipe JSON (schema v1)      │    │ (P5 timing)│    vision model
 │        ↓                                                            │    └────────────┘
 │  user's own folder (SAF):  <id>.json + images/<id>-<n>.jpg          │
 │        ↑                                                            │
 │  list ─ open ─ delete  (read from files, derived index only)        │
 └─────────────────────────────────────────────────────────────────────┘
   * only if spike arm B wins (T1 D3); else images go up directly — ONE arm gets built
   post-alpha, NOT in this diagram: Drive/Dropbox connectors · one-time IAP paywall
```

## 2. v1 scope = build order (decided — context.md constraint 6)

**extract → save → list → open.** Installable alpha on closed track 2026-10-19.
Paywall, sync connectors, grocery-list engine, polish: post-alpha, out of this doc.

## 3. Import pipeline (the product)

1. **Entry:** Android share-sheet (`ACTION_SEND` / `ACTION_SEND_MULTIPLE`) +
   in-app multi-picker. Multi-screenshot recipe = ONE import (proven 2026-08-05).
   **Iron rule: shared bytes are copied to app-private cache before anything
   else** — share-intent URI grants die when the activity finishes, and that
   cached copy is also the retry artifact (P4). Review screen gets a reorder
   affordance: gallery apps don't guarantee multi-select order.
   *Realism: this "one bullet" is the product's front door — budget 3–4 nights
   in MVP weeks 1–2 (T3 plan).*
2. **OCR / extraction:** one interface — `Extractor(List<Image>) → RecipeDraft`.
   Per D3, **only the winning arm gets built**: arm B wins → `ocr_text` impl +
   `image` retry-fallback on low confidence; arm A wins → `image` impl alone.
   Impl names = the schema's `extraction.mode` enum: `image` | `ocr_text`.
3. **Structuring:** spike's `structure_prompt.md` + schema v1, JSON mode, temp 0.1.
   **Envelope split** — the model emits *content* fields only (title, lang,
   servings, times, ingredients, steps, `source.app_hint`, extraction confidences
   + `needs_review`); the app stamps the envelope at save: `id`, `schema_version`,
   `source.imported_at`, `source.original_images`, `extraction.model/mode/extracted_at`.
   Raw model output is never schema-complete by design — validate it as the
   content subset, wrap, then validate the whole file. **Never save a file that
   doesn't validate** (→ §7).
4. **Review screen:** driven by the data — `needs_review` paths + confidence < 0.8
   highlighted. **P6:** fields are *editable* before save (minimum: title + any
   `raw` line) — Gate 1's own metric is "usable without editing"; the 10th recipe
   gets fixed here, so highlighting without editing would be pointless. Missing
   steps/fields → "add another screenshot?" (D4): re-runs extraction over the full
   image list, re-enters review; corrections re-applied by raw-text match where
   possible, else lost (accepted, v1). The model never invents content (D4).
5. **Save:** validated JSON + cached image(s) move to the user's folder
   (`images/<id>-<n>.jpg`). Import done.

## 4. Data & storage (D1 draft — settles as ADR 0001 on Gate-1 pass)

- **One file per recipe:** `<uuid>.json` (schema v1), source images at
  `images/<uuid>-<n>.jpg` — `source.original_images` is an ordered array
  (schema fixed 2026-08-06 after review: was singular, contradicted the proven
  multi-screenshot flow; "hardest thing to change later" — changed while cheap).
- **The folder is the user's** — picked once via SAF. Take
  `takePersistableUriPermission` at pick; grant lost / folder gone → "re-pick
  your folder" flow, never a crash. That folder IS the later sync surface
  (Drive/Dropbox mirror it) and the export story.
- **`raw` is sacred** (D1): parsed fields may be wrong; the user's text is never
  destroyed. Display falls back to raw.
- **List index: derived, disposable.** Scan once per app session into memory;
  list via one ContentResolver child-documents query (SAF `listFiles` is one
  Binder IPC *per file* — a naive scan of 200 recipes is a 10–20 s cold open);
  lazy-read JSON bodies. Foreign/unparseable files in the folder (sync conflict
  copies, hand-edits) are skipped silently, counted, never fatal. **P1:** no
  *persisted* index in alpha; add a cache file when a real library passes
  ~100 recipes (not "hundreds" — SAF is slower than a normal filesystem).
- **Delete exists in v1:** detail screen → delete removes JSON + its images.
  Duplicate imports (same post shared twice = two files) are **accepted in v1**
  — stated so tester reports don't derail week 5.

## 5. Thin proxy — the only backend (constraint 3)

- Thin HTTPS endpoint (Cloud Run-class free tier): accepts image(s) or OCR text,
  holds the model key, returns model JSON untouched. Never stores recipe
  content; logs counters, not content.
- **Constraint-3 tension, named for the grill:** the fair-use cap (constraint 2)
  requires a per-install counter — that is persistent state, so "stateless" is
  honest only as "stateless except the cap counter". Decide at grill whether
  constraint 3 tolerates that (it likely must, since constraint 2 demands a cap)
  and record it in the ADR. **P2:** cap mechanism = static shared secret +
  `install_id` field frozen into the request shape from day one; Play Integrity
  only if abuse actually shows up.
- **P5 — proxy timing:** alpha (12 known testers, ~6 weeks) can call the model
  directly with a restricted dev key behind a compile-time flag; the frozen
  request shape makes the later proxy swap ~1 hour of client work. Constraint 3
  permits a proxy, it doesn't date it — production (Dec) needs it, 19 Oct
  doesn't. Saves ~2 nights before the milestone. *Grill question: is a raw model
  key in a closed-track APK an acceptable 6-week risk?*

## 6. Flutter app structure (P3)

```
lib/domain   recipe model = schema v1 (pure Dart, zero Flutter imports) · Extractor interface
lib/data     file_store (SAF) · extractor (winning arm only) · folder index
lib/ui       import · review (edit) · list · detail (+ delete, notes)
```

- **State: boring on purpose.** ChangeNotifier + Provider, nothing more — a state
  framework is not on the critical path. Revisit only on real pain (**P3**).
- **Tests:** schema round-trip as *semantic* deep-equality (decoded-map compare —
  byte-stability in Dart is a serializer fight worth nothing). **P7:** spike
  `out/*.json` as golden fixtures — needs a T1-plan amendment at grill (plan
  currently graduates only schema + prompt; fixtures would be a third artifact).

## 7. Failure model

- Local files → list/open/delete work offline by construction.
- **Transport failures** (offline, proxy error, 429): cached image + a plain
  "extraction failed — retry" on the saved copy. **P4 recommendation: the inbox
  strip is CUT from alpha** — the mandatory cache copy (§3.1) already covers
  retry with ~2 h of UI; a persistent inbox is up to 2 days of the night budget.
  Inbox becomes post-alpha polish. Pending images live in app-private storage
  and move to `images/` only on successful save.
- **Content failures** (HTTP 200, garbage payload — the failure class the product
  hinges on): validate model output against the content-subset schema on receipt
  → one automatic retry (D3 fallback path if arm B) → then the same plain-retry
  mechanism as transport failures. Never save an invalid file.
- **Environment failures:** revoked/lost SAF grant → re-pick flow (§4), never a
  crash; foreign files in the folder → skipped, never fatal.

## 8. Known cost items → feed the T3 plan at /new-track

| Item | When | Nights |
|---|---|---|
| Share-sheet plumbing (intents, cache-first, reorder) | build wk 1–2 | 3–4 |
| SAF lifecycle (persistable grant, re-pick, scan strategy) | build wk 1–2 | 2–3 |
| Play closed-track admin: signing, privacy policy URL (host on the 2 Sep landing page), Data Safety form (declares images-to-server — draft when P5 lands), content rating, target API, 12 testers | build wk 3, NOT wk 4 | 1–2 |

## 9. Open questions → /grill

1. **P1** index: rescan-only until ~100 recipes — agree the threshold?
2. **P2** cap: static secret + install_id, Play Integrity only on abuse — agree?
3. **P3** state: Provider enough?
4. **P4** cut inbox from alpha, plain retry on cached copy — agree?
5. **P5** proxy deferred to post-alpha, dev key behind flag for the closed track —
   acceptable risk?
6. **P6** review-screen editing minimum (title + raw lines); post-save editing =
   notes only in v1, full edit post-alpha — agree?
7. **P7** spike out/*.json graduate as fixtures (amend T1 plan)?
8. Telemetry: **recommendation = none in alpha.** A Sentry-class SDK is a second
   backend under constraint 3 and muddies the Data Safety form; Play vitals +
   12 named testers cover the closed test. Revisit at production as its own
   decision.
