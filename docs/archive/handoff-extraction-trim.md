# Handoff: recipe extraction — format fix, correctness fix, trim

Written 2026-08-30. Source: two real AI Studio runs with debug logging on.

## Evidence

Both runs: `models/gemini-3.5-flash-lite`. Rates $0.30/M input, $2.50/M output.

| Run | Input | Input tok | Output tok | Cost |
|---|---|---|---|---|
| A | allrecipes "Peach Tiramisu", 3 screenshots | 5,092 | 1,655 | $0.0057 |
| B | handwritten "Filled Cookies" card, 1 screenshot | 2,915 | 1,272 | $0.0041 |

Output is ~73% of cost. Cost tracks **image count and recipe length, not difficulty** — the torn cursive card was cheaper than the clean web page. Budget ~$0.005 typical, ~$0.01 worst case (6-screenshot carousel).

At the 1,200/year cap that is $7–12/year against $21.25 net per sale. Cost is not the constraint. **Make these changes for correctness, not for savings.**

---

## Change 1 — one source line can be several ingredients (do this first)

Run B returned:

```json
{ "raw": "1 teaspoon each of soda, cream of tartar & baking powder",
  "qty": 1, "unit": "teaspoon",
  "item": "soda, cream of tartar & baking powder",
  "note": "each", "confidence": 0.85 }
```

That is **three ingredients** in one entry. `item` is unusable for the grocery list and will never match in the pantry. The extraction was faithful — the format is what's wrong. It assumes one raw line = one ingredient, and handwritten cards break that constantly ("1 teaspoon each of…", "salt & pepper to taste", two ingredients on one line).

This is a v1 file-format decision and the hardest thing to change later. Settle it before real user data exists.

**Do:**

- Add optional `line_id` (string) to each ingredient in the schema.
- Ingredients parsed from the same physical source line repeat that line verbatim in `raw` and share one `line_id`.
- Add prompt rule: *"A single written line may contain several ingredients — '1 teaspoon each of soda, cream of tartar and baking powder', 'salt & pepper to taste'. Emit one entry per real ingredient. Every entry parsed from the same source line repeats that line verbatim in `raw` and carries the same `line_id`."*
- Review screen groups by `line_id`: original line shown once, parsed children beneath it.

---

## Change 2 — stop asking the model for fields the app owns (correctness bug)

Both runs fabricated values, differently each time:

| Field | Run A returned | Run B returned | Truth |
|---|---|---|---|
| `extraction.model` | `"vision-extractor"` | `"gpt-4o"` | `gemini-3.5-flash-lite` |
| `imported_at` / `extracted_at` | `2026-03-30T11:25:00Z` | `2026-03-31T00:00:00Z` | Aug 29 13:20 / Aug 30 00:41 |
| `id`, `source.original_images` | invented uuid + paths | invented uuid + path | app-generated |

It reads the phone's status-bar clock and invents a date around it. A recipe stamped with a March date it hallucinated is a data-integrity bug that outlives the cost question.

**Remove from the schema sent to the model, and from expected output:**

`schema_version`, `id`, `source.type`, `source.imported_at`, `source.original_images`, `cover`, `notes`, `extraction.model`, `extraction.mode`, `extraction.extracted_at`

The app fills every one of these after the call — it has a clock, it generated the uuid, it knows which model it called and whether the input was a screenshot or a link.

**Model still returns:** `title`, `lang`, `source.app_hint` (it can genuinely read "allrecipes.com" off the page), `servings`, `times`, `ingredients`, `steps`, `tags`, `extraction.confidence`, `extraction.needs_review`.

**Also:** strip the `"comment"` key from the schema before sending. It is an internal ADR note about T1/D1 and Gate-1 riding along in every single request.

---

## Change 3 — confidence as buckets, plus app-side flags

The float does not discriminate:

- Run A (clean HTML screenshot): every single item `1.0`, `needs_review: []`
- Run B (torn cursive, faded ink, thumb over the paper): `0.85`–`0.98`, overall `0.94`, `needs_review: []`

The `< 0.8` rule never fires. The distance between a perfect webpage and grandma's card is 0.98 vs 1.0 — that is noise. Do not build the review screen on this number.

**Do:**

- Replace numeric `confidence` with enum `"certain" | "probable" | "guess"` on ingredients and steps. Models bucket far better than they calibrate decimals.
- Rule: anything not `"certain"` must appear in `extraction.needs_review`.
- Add **deterministic app-side flags**, computed in code, independent of the model. These are the ones to trust:
  - `raw` contains digits but `qty` or `unit` is null
  - `raw` contains ` each `, ` or `, ` & `, ` + ` between item words
  - `servings` and `times` both null
  - two or more ingredients share a `line_id`
- Review screen highlights the **union** of model `needs_review` and app flags.

---

## Change 4 — smaller fixes

- **Step prefixes.** Run A kept `"Step 1\nPlace 2 of the pitted peaches…"` in `raw`. The app numbers steps itself, so cook mode renders "1. Step 1 — Place 2 of…". Strip a leading `Step N` / `N.` from `steps[].raw`.
- **Size words are not units.** Run A returned `"4 large peaches"` as `unit: "large"`. That breaks grocery merging — it will never combine with "2 peaches". Rule: size words (large, small, medium, jumbo) go in `note`; `unit` stays null.
- **Tags contradict themselves.** Rule 1 says never invent; the schema asks for tags. Run A invented `["dessert","tiramisu","peach"]`, Run B returned `[]`. Decide — recommend allowing derived tags and adding an explicit rule permitting them, since they're genuinely useful.
- **Verbatim vs best-reading.** The card writes "vanila"; run B silently wrote "vanilla" into `raw`. Defensible for handwriting, but `raw` is documented as untouched truth. Pick one and state it in the rule.
- **Steps that lose their subject.** Run B step 1 is `"Cover with water & boil until tender"` — the raisins moved to ingredients and the sentence lost its head. Acceptable extraction; check how it reads in cook mode with big type.

---

## Change 5 — prefix caching (cost, lowest priority)

Rules block + schema is roughly 2,000 identical tokens on every request. Ordering is already correct for caching (fixed text first, images last). Confirm implicit context caching is actually hitting; if not, set up explicit caching on that prefix. Worth ~5% — do it last.

---

## Verification

Re-run both fixtures. Read token counts straight from the AI Studio logs and multiply by the rates above — **do not wait on billing aggregation**, it is delayed and mixes runs.

Pass conditions:

1. No fabricated model name, timestamp, uuid or image path anywhere in the output.
2. Run B emits **three** ingredients for the soda / cream of tartar / baking powder line, sharing one `line_id`.
3. Run B populates `needs_review` with at least that line.
4. Output token count down — target ~20% on run A.
5. Quality unchanged where it was already right: Run A still yields `times.extra: [{Refrigerate, 240}]` and `total_min: 270`; Run B still assigns the `Filling` group and still returns `servings: null` / `times: null` rather than inventing them.

Save both runs as regression fixtures.

**Order: 1 → 2 → 3 → 4 → 5.**
