# T5 — nutrition (POC BUILT + FOLDED to main, 2026-08-17 night)
goal: per-serving nutrition on every recipe, fed by the user's own barcode scans +
      label photos, in any country — "the meal plan becomes the food diary."
start condition: was post-v1; Arnar pulled the capture shelf forward
      2026-08-17 ("agreements were goals, not stone") under amended
      constraint 4: building ahead is allowed, gates still decide shipping.
      Billing 3g / T2 / T4 remain the standing queue.
origin: Cowork brainstorm 2026-08-17 (Arnar + Hermes-side session). Evidence
      IN: spikes/off_barcode_lookup.sh — 15/15 of Arnar's shelf, then 28
      real products scanned on-device. N1 resolved: OFF-first stands.

## 2026-08-17 night — PoC status (branch poc/pantry, 9 commits)
BUILT + proven by Arnar's eyes on the S21: mobile_scanner collect-mode
scan (3s cooldown, 8s same-code grace) · OffClient (sealed three-way
result — tech rule 16) · Product + LocalPantryStore (store discipline,
38 tests) · Pantry tab on nav slot 2 (kPantryEnabled borrows it from
Unlock on dev builds) · product detail w/ per-100g macros · user photo
per product (cover mechanics, additive `image` ref) · ingredient
long-press → product link (`product_ref`, additive, tri-state copyWith)
with search + photo thumbnails in the picker.
DISCOVERY: Phase 0 below is OBSOLETE — the qty/unit/item split has been
in D1's Ingredient since day one AND the extractor's schema asks for it;
Arnar's real files carry it filled. No D-number, no work: it exists.
GAPS accepted in the PoC: pantry lives in app docs and does NOT sync
(sync layout confines to root *.json + images/ — needs an additive
pantry/ case, first job after the fold) · dangling product_ref after a
product delete is silent · one barcode per gallery image.
STILL UNBUILT from the phases below: link memory (N7) · label-photo
fallback · manual digit/product entry · staples + density table ·
calculator + badge · plan totals.
division: same as T3 — Arnar owns UI/design (screens enter a future design
      turn; rule 17 — the mockups are the design answers, so engine phases
      never block on skin). Agent owns engine. All new surfaces behind a
      features.dart flag until wired (rule 19, no dead ends).
shape: three shelves + a calculator. Capture (barcode scan with Open Food
      Facts autofill · label photo through the SAME extraction pipeline that
      passed Gate 1) → the user's product library (one JSON per product, their
      storage, syncs like recipes) + a bundled generic-staples table →
      per-serving calculator → recipe badge, meal-plan totals, grocery links.
      No new backend of ours anywhere (constraint 3 intact).

## Phase 0 — in-v1 door-opener
Structured ingredient lines. Today a recipe stores raw ingredient strings;
three parked features (serving-rescale · step↔ingredient chips · this track)
all wait on the same split. Additive change:
- Each ingredient line gains optional `parsed: {qty, unit, item, note}`;
  `raw` stays canonical and is never dropped. Extractor prompt asks for the
  split; readers tolerate absence (old files stay valid — parked schema-v2
  read policy applies).
- File-format change → needs its own D-number when we agree (D11 precedent).
- Timing: NOT a queue jump — it lands whenever the extractor files are next
  open for other reasons. Tests: golden fixtures extended with parsed lines.

## Phase 1 — product library engine
- `product.json` schema (N2): barcode, name, brand, per100g map (canonical
  keys: kcal, protein_g, fat_g, satfat_g, carbs_g, sugars_g, fiber_g,
  salt_g), serving_size?, source (off | label | manual), fetched_at,
  schema_version. One file per product in the user's folder, store mirrored
  on recipe_store patterns AND its test discipline (copy-in, delete
  semantics, confinement, corrupt→null).
- OFF client: GET world.openfoodfacts.org/api/v2/product/{barcode}.json
  ?fields=product_name,brands,nutriments,serving_size — no key; UA
  "MyReciBook/x.y (contact email)"; ~6 s timeout; miss/timeout → label path.
  Normalize OFF nutriment keys (energy-kcal_100g, proteins_100g, …) into
  per100g at write time; the product file IS the cache, so scans work
  offline afterwards. Tests over MockClient like the extractor.
- Link memory (N7): one small store mapping normalized ingredient item →
  product barcode or staple id, written on user confirmation, remembered
  forever — the same correction-memory pattern as grocery categories; one
  linking store, two consumers.

## Phase 2 — capture
- Scanner: mobile_scanner (ML Kit under the hood — same family we already
  ship). EAN-13/8 + UPC-A/E, torch toggle, manual digit entry fallback.
  Screen behind the flag; preview can live in the dev gallery like batch/
  grocery/cap did in T3. (~2 nights)
- Label-photo fallback: new prompt profile against the SAME relay — photo of
  a nutrition panel → per100g JSON + serving size. On-device OCR first pass
  identical to recipes. Request-shape addition = D2 review (frozen shape);
  calls count against the D7 per-install cap like any extraction. (~2–3
  nights) Spike verdict may promote this to the primary path (N1).

## Phase 3 — staples, densities, calculator
- Staples table (N4): curated subset of USDA FoodData Central (public
  domain), ~1k generic foods (flour, onion, chicken thigh…), bundled asset,
  offline. Committed build script (tools/) so the subset is reproducible.
  ÍSGEM (Icelandic table) only if its license clears — not assumed.
- Density + portion table: ~200 entries for volume→mass (flour ≠ sugar) and
  count units ("1 onion" → average g, USDA portion weights). Unit
  canonicalizer: g/kg/ml/dl/l/tsp/tbsp/cup + unicode fractions; canonical
  units g and ml. Metric-first market makes this cheaper for Arnar's own
  recipes; cups matter for imported English-language ones.
- Calculator: pure functions — parsed qty × per100g ÷ servings, summed per
  recipe. Unmatched or unparseable lines are SURFACED as "not counted",
  never silently wrong (N5). Golden tests on a 10-recipe fixture; 3 recipes
  hand-checked against reference numbers, deltas documented.

## Phase 4 — surfaces
Flows only until a design turn ratifies the skin (rule 17): recipe-card
badge + per-recipe breakdown (with "estimate" label and the not-counted
list) · "My products" list + product confirm sheet · scanner entry point.
Meal-plan day/week totals ride on the planner engine when it exists — that
is the week-two loop of the bet, so totals slot in behind it naturally.
Every surface: flag-gated, no dead ends (rule 19).

## Proposed decisions — N-numbers, graduate to D-numbers only when we agree
- N1 capture order: OFF-first with label fallback; FLIPS to label-first if
  Arnar's shelf spike shows a low hit rate. Evidence before preference.
- N2 product.json format as in Phase 1 — file-format change, D-worthy.
- N3 no new backend: device→OFF direct + in-app attribution "Product data:
  Open Food Facts (ODbL)"; we never redistribute the database (each user
  holds only their own scanned products). One license read before this
  track's launch to confirm the share-alike reading.
- N4 staples source: USDA subset, public domain, reproducible build script.
- N5 estimates honesty: UI always says "estimate"; cooked-vs-raw and "to
  taste" make precision claims false — never present as medical-grade.
- N6 monetization: candidate second one-time "nutrition pack" through the
  existing Unlock seam, OR included in the base unlock — banked as a
  T4-adjacent pricing decision; either way label-photo calls sit inside the
  stated fair-use cap (constraint 2 language already covers it).
- N7 one linking store shared by grocery categories + nutrition (Phase 1).
  2026-08-17 night sharpened this: "remembered links" is the coverage
  engine — a confirmed "milk → Mellommelk" gets SUGGESTED on every future
  recipe, one tap to accept; nobody hand-links 40 recipes, the memory
  snowballs coverage instead.
- N8 grocery product-ization (Arnar's brainstorm, 2026-08-17 night —
  "one doesn't buy 2 cups of sugar"): three tiers, in order. Tier 1:
  staple rows hide quantities (display only — the engine already knows
  staples). Tier 2: "in your pantry" hint on rows matching an owned
  product — suggest-and-confirm, NEVER auto-remove (a bag ≠ enough).
  Tier 3: linked rows aggregate to package counts ("600ml milk → 1
  carton") — waits for the unit table, which nutrition math needs anyway:
  one conversion engine, two customers. Linked rows also merge by
  barcode identity (exact), replacing fuzzy text merge where links exist;
  unlinked rows keep today's behavior — no forced chore anywhere.

## Testing
Store tests mirror recipe_store discipline; calculator = pure-function
goldens; OFF client over MockClient; scanner logic behind an interface so
tests skip the camera. NO UI tap-choreography tests — dropped 2026-08-17,
stays dropped (behavioral 16). Suites run per-file as today (tech rule 13).

## Risks — one line each
- OFF coverage thin in small markets: without the label fallback shipping in
  the same release, scanning feels broken on day one in exactly our market.
- Staples/density gaps: without them most recipes show nothing or fiction —
  the curation nights are load-bearing, not polish.
- Schema creep: product.json and parsed lines are file-format changes; each
  gets a D-number and a read policy or old libraries break on sync.
- Trust: numbers presented without the "estimate" frame invite health
  decisions the data can't carry.
- Scope gravity: this track is recipe-attached nutrition, NOT a diary app —
  MFP-style manual logging is out; the meal plan is the diary.
- NAMED TRAP (agreed 2026-08-17 night): NO inventory tracking, ever. The
  pantry says WHAT you own, never HOW MUCH is left — depletion bookkeeping
  is a diligence chore that kills apps. Hints, not ledgers.


## Open (Arnar)
1. ~~Shelf spike result → N1 order.~~ RESOLVED 2026-08-17: 15/15, OFF-first.
2. Pack vs included → bank for T4 pricing round.
3. Launch scope: metric-only units first, or cups from day one?
4. ~~Fold poc/pantry → main~~ DONE same night → pantry/ sync case heads the follow-ons.

## Relay note for Claude Code
On receipt: read this file, then STOP — the track is parked; the standing
queue (billing 3g → T2 → T4) is unchanged. At your next checkpoint: add the
T5 row to conductor/tracks.md and a one-line parked entry in pulse 📌 (this
session touched no conductor state on purpose — parallel-session hygiene).
Phase 0 alone may ride into v1 the next time the extractor is open; treat
its schema change as a new D-number proposal for Arnar first.
