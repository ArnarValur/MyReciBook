# market

**Goal:** know the field, and decide our position in it on evidence rather than
nerve. Competitor intel, positioning, price defence, the Nordic angle.

**Serves:** the Play listing's first line, the price defence when someone
undercuts or out-features us, and the order we build what is left. Feeds the
launch track when that opens.

**Opened 2026-09-01** (Arnar). A Play search for "recipes" looked intimidating —
millions of installs, glossy listings, 4.7-star badges. Fourteen agents were
sent underneath the listings to find out whether that was real.

**Discussion track, Cowork side.** Decisions land here; Code reads them at boot
through tracks.md. Nothing in this track builds anything on its own.

## The evidence

Fourteen dossiers, two independent agents per app (product/pricing ·
reviews/unmet needs) → `docs/competitor-research/`. Start at `_SYNTHESIS.md`;
`README.md` indexes the rest; `recipe-app-recon.html` is the visual read.

Seven apps: Foodvisor · COOKmate · Tasty · Cookpad · ReciMe · SideChef · Mob.

**Prices are NOT restated here — they rot.** Every figure in the dossiers
carries an observation date, and several of these apps run concurrent A/B price
cohorts. Re-check live before quoting one at anybody.

## What the research says about the bet

`context.md` says do not re-litigate the bet without new evidence. This is new
evidence, and it lands on the side of the bet. **Context.md is not edited here —
that changes only by Arnar's agreement.**

- **Pay-once — confirmed, loudly.** None of the seven sells a one-time price.
  Users ask for one unprompted in four separate apps' reviews, with vote counts;
  the most-upvoted review on Mob's entire Play listing tells people to go buy
  cookbooks instead. We do not have to educate this market.
- **Android-first is the moat — confirmed, and sharper than context.md puts it.**
  The moat is not only that Crouton/Mela/Pestle have no Android. Our nearest
  live rival, ReciMe, treats Android as second-class: Android v4.1.2 vs iOS
  v6.1.5, a listing that tells Android users the app syncs to "iOS and iPad",
  shared cookbooks iOS-only, both lifetime giveaways iOS-only.
- **User-owned files — confirmed as the category's open wound.** "I lost my
  recipes" is the loudest churn moment in every dossier without exception. One
  competitor of seven can honestly say your recipes are yours (COOKmate), and it
  is also the one that has survived sixteen years at 4.6 stars.
- **Screenshot-first import — no competitor contests it.** Cookpad added OCR of
  handwritten cards in 2026 and meters it. ReciMe's importer is genuinely better
  than ours today at social video; its wall is 5 imports/week.

## What is unoccupied

Nobody has combined a personal cookbook with a pantry and a food diary. One of
seven has a diary (Foodvisor — a calorie counter, not a recipe app). One has a
pantry (SideChef — no release since 2025-03-14). Matrix in the synthesis.

Nordic: five of seven ship no Nordic language at all. Cookpad will not sell
Premium in Norway. Mob charges NOK yearly for UK aisles. Nobody is contesting
the ground Arnar actually lives on.

## Rules taken from other people's mistakes

Ten in `_SYNTHESIS.md` §7. The four that touch decisions already made:

- **Never ship a trial.** Trial mechanics are the single largest complaint
  category across four of the seven. Pay-once makes them unnecessary — this is
  a reason the hard paywall in context.md constraint 2 is right.
- **Restore-purchase must be flawless.** Existential under one-time pricing,
  not a nicety. Touches the billing seam, currently unstarted.
- **Never take back what people already have.** Reinforces constraint 2's
  "never unlimited forever". COOKmate killed its one-time purchase in 2022 and
  still carries 790 one-star reviews for it.
- **Honour a stated preference everywhere.** SideChef's most-repeated complaint,
  unfixed 2018→2026, is that its allergy filters are ignored; Mob's break on
  unnormalised ingredients and a reviewer called it "dangerous". Safety issue.
  Relevant the day we ship dietary filters — we have not yet.

## Decisions

1. **The grant never refills — lifetime cost is bounded at the moment of sale.**
   *Settled 2026-09-01, Arnar + Cowork, answering Q1.* 1,200 AI rescues come
   with the purchase, once, forever — no anniversary reset. Top-up: **$5 buys
   600 more rescues**. BYOK stays as the power-user exit and the insurance
   against future model pricing. The arithmetic (docs/ai-cap-mechanics.md,
   prices verified 2026-08-19): a blended rescue costs ~$0.0032, so the worst
   any buyer can ever cost us is ~$3.84 lifetime against ~$21.24 net from the
   sale — bounded, ~18% in the maxed-out case, far less realistically. A
   yearly refill is unbounded (~$3.84/yr; underwater past year ~6 on heavy
   users) — the COOKmate spiral. $5-for-1,200 was considered and rejected:
   $4.25 net against up to $6.72 in an all-webpage-fallback mix loses money on
   exactly the heaviest buyers; $5-for-600 stays profitable in every mix
   (blended $1.92, worst case $3.36). Re-verify Gemini's price sheet the day
   the top-up SKU is created in Play.
   **Consequences for Code:** ① remove the lazy anniversary refill —
   proxy firestore_ledger.dart:206 + usage_counter.dart:206 and their tests;
   this closes the OFFER-CONTRADICTS-ENGINE blocker in pulse. ② Website terms
   and app unlock copy state the top-up as 600 for $5 (terms already say "no
   reset" since 2026-08-31; the quantity is the new part). ③ Anything else
   still implying a reset (`resets_at` in the proxy response contract, quota
   card wording) follows the same rule: nothing resets.

## Open — the discussion queue

- [x] **Q1 — bounded recurring cost. Highest stakes.** → **Decision 1.**
      COOKmate did not fail at
      one-time pricing; it failed because one-time money had to fund 200+
      hand-maintained scrapers plus cloud sync forever, and the developer said
      so publicly in 2018. Our proxy is already thin and stateless (constraint
      3) and storage is already the user's own — so the question is narrow:
      what is our per-purchase lifetime AI cost against a $25 one-time take,
      and what happens to it if a user rescues 1,200 recipes on day one and
      lives twenty years? Ties directly to the open OFFER-CONTRADICTS-ENGINE
      blocker in pulse — the yearly refill at firestore_ledger.dart:206.
- [ ] **Q2 — migration in.** Nobody in the category ingests a rival's export.
      Users with 500–1500 recipes are trapped by file formats, not loyalty;
      several COOKmate reviewers report retyping by hand. Which formats do we
      read? (Timeline framing dropped 2026-09-01 — Arnar: no "alpha/post-launch"
      talk, only build order.) **In progress:** Arnar is running the manual
      export recon — workflow + checklist in `export-recon.md` beside this
      file, cheapest-first (docs → free installs → purchases last). Prior
      art: docs/library-import-research.md (Paprika buildable, ReciMe locked).
      Findings become Decision 2.
- [ ] **Q3 — Nordic localisation at launch or after.** The i18n track already
      has Norsk bokmål, Svenska, Dansk and Suomi parked at 31 messages behind
      Íslenska. The market read says the Nordic gap is total and uncontested.
      Does that change the language order, or is it just confirmation that the
      existing order is right?
- [ ] **Q4 — the listing's first line.** Competitors' own users wrote our copy.
      Current draft texts live in `docs/play-store-listing.md`. Does the price
      go in the first line, and in what words?
- [ ] **Q5 — what we steal, and in what order.** Synthesis §8 lists eight
      mechanics worth taking (ReciMe's import cascade and inline ingredient
      quantities, SideChef's per-step photos and hands-free voice, Mob's Adapt
      Recipe and aisle-sorted list, Cookpad's ingredient-first search,
      COOKmate's published backup schema). None are sized. Most are post-alpha.
- [ ] **Q6 — refresh cadence.** This research is a snapshot dated 2026-09-01.
      ReciMe is moving fast and is the only genuine rival. When do we re-run
      it, and against which apps — the same seven, or a revised list? Note the
      seven came from a Play search, and context.md names a different set
      (Crouton, Mela, Pestle) that this sweep did not cover.
