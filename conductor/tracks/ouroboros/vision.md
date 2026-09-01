# Ouroboros — the food loop

*Vision doc, banked 2026-09-01 from a Cowork brainstorm (Arnar + Cowork).
NOT a track yet — listed under "Not open yet" in tracks.md. This document
exists so the dedicated deep-dive session boots with the whole idea intact.
Nothing here builds until Arnar opens the track.*

---

## The loop, in one breath

Shop → scan the receipt → Inventory rises → cook from recipes linked to the
Collection → log the meal in the diary → Inventory falls → the grocery list
knows what's low → shop.

The user never bookkeeps. Both halves of inventory tracking dissolve into
things the user already does: **food in** is one receipt scan per shopping
trip (a batched artifact that already exists in their hand), and **food out**
is the diary — which diet-lifestyle users already fill for nutrition reasons.
Inventory becomes a *side effect of existing habits*, which is the only form
of inventory that has ever survived contact with real users.

Nobody in the competitor matrix can copy this without rebuilding their
product: closing the loop requires a cookbook AND a pantry AND a diary, and
we are the only app that has all three columns (docs/competitor-research/
_SYNTHESIS.md §3).

**The sentence it earns:** the app where your groceries, your recipes, and
your food diary are the same data.

**The audience:** the diet/fitness/tracking crowd — one of the largest app
categories in either store (Foodvisor alone: 194K Play ratings for *half* of
this loop), paying subscription prices, refilled every January.

---

## The two-layer pantry

- **Collection** — what exists today. The user's curated food vocabulary:
  products they keep, barcode-scanned at their own stores (Rema/Kiwi products
  resolve on OFF), package size + nutrition attached. Presence, not counts.
  This layer is the feature users "hoard" into — staples, regulars, their
  personal food world. It ships value on its own and never requires the loop.
- **Inventory** — new. Approximate current stock, fed by receipt scans and
  grocery check-offs, drained by diary logging. Explicitly a *second* layer:
  Collection answers "do I keep this?", Inventory answers "do I have it now?"

## Design rules (settled in the brainstorm — re-ratify when the track opens)

1. **Inventory is humble, never authoritative.** It will drift (eating out,
   family raids, unlogged snacks). Approximate states, graceful uncertainty,
   never scold. Each receipt scan doubles as the self-healing moment
   ("milk again — finish the old one?"). Drift-tolerant or dead.
2. **Screenshot/photo/PDF receipts only. No chain integrations, ever.**
   Æ/Trumf-style APIs are per-chain, per-country, forever-maintenance — the
   Never tier from Q5. An image of a receipt (paper photo or digital-receipt
   screenshot/PDF — Höddi's case) rides the existing rescue pipeline and
   works in every store on earth.
3. **Every AI step spends from the 1,200 grant** (market Decision 1) — so the
   whole loop is cost-bounded by construction. No new pricing surface.
4. **Everything lands inside the one $25 bundle** (generosity principle).
   No feature paywalls; the bundle getting fatter IS the marketing.
5. **Graceful degradation all the way down.** No receipts? Check-offs still
   feed Inventory. No Inventory at all? Collection + presence-only
   cook-from-the-shelf still work. No pantry at all? It's still a great
   grocery list. Every layer optional, every layer additive.
6. **Cook-from-the-shelf ships presence-only** (against the Collection),
   before and without Inventory. Inventory later upgrades its honesty
   ("you have this NOW" vs "you keep this"), it is not a prerequisite.

## The grocery screen is the hinge

The screen that evolves most. Mental model: **the grocery list is a list of
expectations; the receipt is a list of facts.** Reconciliation is a cascade,
cheapest first:

1. Receipt line matches an item on the open grocery list → **auto-check it
   off** (the loop's delight moment: scan the receipt, the list ticks
   itself). Purchased → Inventory up.
2. Unmatched lines match against the **Collection** — the user's own known
   products, not the world's catalog. Matching "TINE LETTMELK 1L" against a
   few hundred products the user themselves scanned is a bounded AI task,
   with OFF names/barcodes as anchors. Match → Inventory up, silently.
3. Still unmatched → **"new to you?" cards**: propose adding to the
   Collection (and to Inventory), user confirms in one sweep.
4. Manual check-off (no receipt) is the no-AI purchase event — same
   Inventory effect, zero grant spend.

Before the trip, the list already shows overview: items derived from a
recipe's Collection-linked ingredients carry a state badge — in Inventory /
in Collection only / new. ("You have 6 of 8 — missing cream and dill.")

## Reuse map — why this is cheaper than it looks

- **Rescue pipeline**: a receipt is a new source type through the same
  extraction proxy, quota counter, and BYOK door.
- **Import review screen / batch_model**: the receipt confirmation screen
  already exists as a pattern — AI proposes with confidence, user confirms
  the doubtful, batch of 30 lines ≠ 30 screens.
- **Barcode + OFF**: the Collection's product identities and package sizes
  are already the matching anchors.
- **Diary**: already logs meals from recipes/pantry with per-meal totals —
  the consumption side needs a decrement hook, not a new feature.
- **Grocery list**: already merges, dedupes, and checks against the pantry.

## Prerequisites (shared with already-queued work)

- **Ingredient ↔ Collection linking** — the same foundation Q5's
  cook-from-the-shelf needs. Whatever builds first builds it for both.
- **Index cache** — big libraries must be fast before the loop adds screens.
- **Meal planner** (parked; ui/plan_tab.dart placeholder) — the loop's front
  half: planned meals → grocery list → the cascade above. The loop is why
  the planner matters; nutrition's dormant meal-plan-totals item also waits
  on it.

## Open questions for the deep-dive session

- [ ] **Decrement math.** A logged meal consumes how much of a package?
      Package-size math exists for nutrition — does it drive Inventory too,
      or is Inventory per-item state (have / low / out) with no arithmetic?
      The humble-inventory rule (design rule 1) leans toward states.
- [ ] **What a receipt scan costs.** 1 rescue per receipt, or per N lines?
      Token-wise a receipt ≈ a recipe; decide and print it honestly.
- [ ] **Drift reconciliation UX.** How the self-healing prompts look without
      becoming nag screens; how "out" flows back onto the grocery list.
- [ ] **Digital receipt shapes.** Photo and screenshot are proven paths;
      PDF export (Höddi) needs a look at the import sheet's doors.
- [ ] **Inventory data shape + where it lives** (user-owned files like
      everything else — but which file, and does it sync?).
- [ ] **Grocery badge design** — how much state the list shows per item
      without clutter.
- [ ] **Q5 ratification** — the steal-order tier list (market plan, pending
      Decision 4) should be settled alongside, since cook-from-the-shelf is
      both steal #1 and this loop's first visible surface.
