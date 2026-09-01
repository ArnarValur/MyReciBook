# ouroboros

**Status:** Open — 2026-09-01, Arnar: "Open track". PoC slice one builds in the
worktree `../MyReciBook-ouroboros`, branch `ouroboros`. Nothing merges to main
until Arnar's eyes verify it on the device.

**Goal:** the closed food loop — the idea is tracks/ouroboros/vision.md, this
file is what was decided and what gets built. Slice one proves the delight
moment: scan a receipt, the grocery list ticks itself, Inventory rises, the
recipe page says "you have 6 of 8".

**Serves:** the post-alpha flagship sentence — groceries, recipes and diary are
the same data. NOT on the 1.0 path; mvp-build's open items are untouched.

**Cost:** one rescue per receipt read (same slot as a label read). No proxy
change — the app sends the prompt, the proxy counts and forwards.

## Decisions — deep-dive 2026-09-01 (Arnar + Fable)

- **D1 (Arnar)** — Inventory says it out loud: "an estimate, not a count" on
  the screen. It drifts, it never scolds.
- **D2 (Arnar)** — Receipt lines not in the Collection: OFF fills Collection +
  Inventory automatically when the hit is confident; doubtful or empty → a
  "new to you?" card. Fact found tonight: OffClient does barcode lookup only,
  name search is new code — prove it on three real Rema/Kiwi receipts before
  the loop leans on it. Slice one ships cards only.
- **D3 (Arnar)** — Scan a barcode from the ingredient row's link picker:
  hand on pack → product created → linked, one gesture. Needs nothing from
  the loop; may ship on main ahead of it.
- **D4 (leaning, unratified)** — Drain is two events. "Cooked it" drains the
  pantry for the whole batch and puts "Lasagne, N servings" into Inventory;
  diary eating drains that one serving at a time. Servings math is the
  nutrition math already in lib: ingredient ÷ recipe servings × servings.
- **D5 (leaning, unratified)** — Inventory is ONE app-private file
  (inventory.json beside grocery_list.json), never fields on product files.
  Sync is open.
- **D6 (leaning, unratified)** — The meal planner is not a prerequisite;
  GroceryItem.recipeParts already feeds the list.
- **D7 (leaning, unratified)** — Matching is on-device and deterministic
  (normalizeName + Product.synonyms); AI only reads the receipt. A confirmed
  match teaches the printed text as a synonym, so the next receipt is free.

## Steps — sequence only

1. **PoC slice one** (worktree):
   a. assets/receipt_prompt.md + ReceiptReader on GeminiExtractor, mirror of
      extractLabel.
   b. domain/receipt_read.dart — refuse-to-trust parse, label_read pattern.
   c. domain/inventory.dart · data/inventory_store.dart · ui/inventory_model
      — one file, pack counts, have/out.
   d. domain/receipt_match.dart — the cascade: open list → Collection →
      unmatched. Pure Dart, tested.
   e. Grocery tab door "Scan a receipt" (kOuroborosEnabled + a ReceiptReader
      present, dead-end rule) → review screen: On your list (auto-checked) ·
      Already yours · New to you? → confirm applies check-offs, Inventory,
      new products (source 'receipt', synonym = the printed text).
   f. Recipe detail: "You have N of M · missing …" under Ingredients —
      Inventory says have-now, Collection falls back to you-keep-this.
   g. Device verify on Arnar's own receipt. Bump only after that.
2. **Slice two — drain.** "Cooked it" on the recipe (D4), leftovers as
   Inventory rows, the diary hook.
3. **Slice three.** OFF name search behind confidence (D2), synonym learning
   (D7), PDF receipts via the import sheet's doors.
4. Q5 steal order ratification rides this track (market plan).

## Open

- Inventory sync — user-owned file or app-private working state (D5).
- A "low" state needs the drain to exist first.
- The vision's audience line (diet trackers) vs context.md's bet — Arnar's
  word only, not this track's.
