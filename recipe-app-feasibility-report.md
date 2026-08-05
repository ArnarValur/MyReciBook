# Recipe-Screenshot App: Feasibility Report

**Research date:** August 3, 2026 · **Sources:** ~95 verified links, 11 parallel research tracks, key numbers cross-checked twice
**Framing:** evaluated as a solo indie app business (active side business, few hours weekly, long-term work-from-home income) — not as passive income.

---

## 0. Verdict first

**Conditional go as a solo indie business — but only with a differentiated wedge, and with income expectations set by base rates, not success stories. As a fast route to meaningful work-from-home income: no.**

The one-sentence version: the tech is cheap and easy (extraction costs ~$0.001–0.006 per recipe, ~80% gross margin), but the niche is saturated with 25+ near-identical AI apps launched since 2024, the funded category leader (ReciMe — full teardown in §2) owns the obvious positioning, and the realistic solo trajectory is **5–10 hrs/week indefinitely** for a median year-one income of ~$72/month, with a solo ceiling around Mela's ~$9K/month.

| Question | Answer |
|---|---|
| Can you build it? | Yes, easily. Weekend-prototype easy. |
| Are the unit economics good? | Yes — ~75–82% gross margin at $2.50/mo. AI cost is a rounding error. |
| Is the niche open? | No. One funded leader (ReciMe), one corporate player (Samsung), 25+ clones since 2024. |
| Weekly time commitment | Build: 6–10 weeks of nights. After launch: **5–10 hrs/week indefinitely** — import breakage, annual SDK rebuilds, support, marketing content. |
| Realistic income trajectory | Year 1: median **$72/mo**; good case low hundreds. Years 2–3 if top-quartile: $500–3K/mo. Solo ceiling in this category: **~$9K/mo** (Mela). ReciMe-scale requires funding + a full-time content operation. |
| Is there any real gap? | Yes — two big ones: (a) one-time price + local-first + AI import (§6.2), (b) grocery-list quality (§6.3); plus a smaller heirloom-recipe niche (§6.4) and an optional European language beachhead (§7). |

**If you proceed** (valid reasons: you'd enjoy the build, portfolio value, an asset with a ~1-in-6 shot at $1K MRR): skip to §8 for the lean validation path. Budget ~1 weekend to validate extraction, ~1 week to validate demand, and set a kill criterion before writing production code.

**Refined thesis (evaluated Aug 2026, §6.5):** the strongest formulation found is **screenshot-first import + user-owned storage + pay-once**, onboarded with a "rescue the recipes buried in your camera roll" batch import. It defuses the worst maintenance treadmill (link scraping becomes a droppable bonus), takes hosting costs to ~$0, and claims a positioning no recipe app owns. It does not change the go/no-go or the base rates — it changes the MVP spec.

---

## 1. Competition: very crowded, and commoditizing fast

### The leaders

| App | Price | Screenshot/social import | Scale | Notes |
|---|---|---|---|---|
| **ReciMe** | $39.99/yr US (listed up to $59.99); free = ~5 imports/week | Best-in-class marketing claim; real tests show missed steps, failed imports on caption-less videos | 269K iOS ratings (4.8), #9 Top Free + #2 Top Grossing Food & Drink; claims 10M users | Funded startup ($1.5M seed incl. Marissa Mayer), NYC, full-time TikTok content team. **Full teardown in §2.** |
| **Samsung Food** (ex-Whisk) | Free; Food+ $6.99/mo | Photo scan paywalled; weak on social video | 1M+ Play installs | Corporate; users say Samsung "ruined" Whisk; forced account login |
| **Flavorish** | $4.99/mo | **Won Android Police's Nov 2025 4-app head-to-head** | Small (~50K downloads) but #22 US grossing Food & Drink | The template for what you'd be building — already exists |

### The beloved incumbents (one-time purchase, weak AI)

| App | Price | Gap |
|---|---|---|
| **Paprika 3** | $4.99 one-time (mobile) | **#1 Top Paid Food & Drink for years.** No AI, no video import, no OCR. |
| **Recipe Keeper** | ~$10–20 one-time per platform | Strong cookbook/handwriting OCR; 2.5M+ Play downloads; confusing per-platform pricing |
| **Crouton** | $24.99 one-time (+$1.99/mo tier) | Apple Design Award 2024; Apple-only; solo dev **sold it to a hardware company** rather than run it |
| **Mela** | $4.99 one-time | Beautiful; caption-based video import; ~$9K/mo est. revenue — a *best-case* solo outcome |
| **Umami** | $0.99/mo or $19.99 lifetime | Tiny (~413 ratings) — shows what a well-made me-too app actually achieves |

### What this means for you

- **The exact idea (screenshot → AI → recipe book → cheap subscription) shipped in 2021 and the winner is funded.** If you ignore this, you launch app #26 into a market where users can't tell entrants apart — Android Police found three of four tested apps had near-identical onboarding.
- **25+ new AI recipe-import apps launched 2024–2026** (Stashcook, Recify, Seasoned, Simmer It, Peel, Nutrola, Recipe Notes, …). Every one runs the same playbook: LLM extraction + SEO comparison blogs + TikTok ads.
- **Even the leaders' extraction is imperfect.** In head-to-head testing, ReciMe failed one video import entirely and missed a step shown but not spoken. This is the one place quality can still win (§6).
- **The graveyard is instructive:** Yummly (20M users, Whirlpool-owned) shut down Dec 2024 and users lost their libraries; MasterCook's cloud dies Dec 2026; PlateJoy is dead. Users now actively fear lock-in — "export & local ownership" is a real selling point.

**Top user complaints across all apps** (your differentiation raw material): 1) subscription resentment — the single loudest theme; 2) paywall rug-pulls; 3) AI errors on video imports; 4) data loss / lock-in fear; 5) bad grocery lists (no dedupe, no plan↔list sync); 6) no Android (Crouton/Mela/Pestle).

---

## 2. ReciMe teardown: the incumbent you'd actually be fighting

### 2.1 What it does

**Import sources:** Instagram, TikTok, Facebook, Pinterest, YouTube, any website, screenshots, and photos of cookbook pages or handwritten cards; plus a Chrome extension. Under the hood it's a **fallback cascade, not true video understanding** — its own help docs state it works best "when the recipe is written out in the caption," then tries audio transcription, then tries to find the original recipe website. Silent/ASMR/no-caption videos are where it fails.

**Organization & features:** collections/cookbooks, serving-size scaling with metric↔US conversion, cook mode, weekly meal planner, aisle-grouped grocery list, recipe sharing (links, AirDrop, community feed), and nutrition calculation (premium). Cloud-account-based: offline works only for already-loaded content; importing and sync require internet.

**Pricing:** US annual is **$39.99/yr** (official help center, updated Mar 2026); regional listings show up to **$59.99/yr** — pricing varies by country and is A/B-tested. SKUs from $9.99 exist. Free tier: ~5 imports/week. The 7-day trial requires payment info up front. It **used to sell an AU$59.99 lifetime SKU** (periodically given away in promos) and discontinued it — now subscription-only.

**Scale and machine:**

| Metric | Value |
|---|---|
| iOS | 269K ratings, 4.8★; #9 Top Free, #2 Top Grossing Food & Drink (US) |
| Android | 1M+ installs, 77K reviews, 4.7★ |
| Users | Claims "10M community" (self-reported); 800K verified at seed (2024) |
| Revenue | ~$800K MRR per third-party estimate (unverified); 75%+ from the US |
| Funding/team | $1.5M seed (incl. Marissa Mayer); NYC; multi-person team |
| Growth engine | **Systematic, A/B-tested TikTok/Instagram content production** — a full-time marketing operation, not virality luck |

### 2.2 Top user complaints, categorized (App Store / Play / forums)

1. **Billing & pricing — the loudest category.** Its single most-upvoted Play review (1,419 "helpful" votes): *"yearly fee is way too steep… canceled 2 days before trial ended… still charged."* The 5-imports/week free tier reads as *"bait and switch"* after onboarding. Reviewers across sources say they'd prefer a one-time purchase.
2. **Data loss & reliability.** Multiple reviews report recipe libraries disappearing after paying, and the app hanging on a white screen. In a category where Yummly just vaporized 20M users' saved recipes, this is the trust wound.
3. **Import accuracy.** Android Police's head-to-head: one video import failed entirely, one recipe misnamed, one step shown-but-not-spoken missed. Handwriting test: ~80% accuracy (cursive "tsp" → "tbsp"). Some imports duplicate every ingredient line. ReciMe maintains a dedicated help page titled "Why didn't my recipe import correctly?" — the failure mode is common enough to need documentation.
4. **Grocery list neglect.** Doesn't merge duplicates — three recipes needing 2 lemons each yield *"3 rows of 1 X lemon"*; meal-plan changes don't propagate to the list; categories are locked (*"sesame oil is grouped under 'herbs and spices'… no way to move it"*).
5. **No household sharing.** No shared family accounts; sharing is per-recipe links, not a common cookbook/list.

### 2.3 What it deliberately doesn't offer — and why

These are strategy, not oversights. Each would undercut the funded-growth model:

- **No one-time or lifetime tier** (it killed the one it had). A VC-backed company needs MRR; $40/yr × retained subscribers is the whole P&L.
- **No local-first / offline independence.** Cloud accounts drive retention metrics, sync lock-in, and the community feed.
- **No real data export.** Official export is PDF, print, or share-link only — no CSV/JSON/structured format ([ReciMe help](https://recime.app/help/en/articles/11626121-can-i-print-or-export-my-recipes)); a third-party "ReciMe Recipe Exporter" Chrome extension and competitor "import from ReciMe" guides exist to fill the gap. "Your recipes live on our servers" is the business model.
- **No grocery-list craftsmanship.** Two-plus years of the same list complaints in reviews — engineering goes to import-source breadth and growth, because imports acquire users and lists don't demo well on TikTok.
- **No on-device or BYOK option.** Its cloud AI pipeline is also its cost structure and moat.

### 2.4 Can a solo dev compete? Honest assessment

**Not head-on — and you don't need to.** Ranked by odds:

1. **One-time pricing + local-first (best odds — structural).** ReciMe *cannot* follow you here without dismantling its own business model; its investors bought MRR. This is the only wedge where the incumbent's strength (funding) is your protection. Crouton proves the combination ships and passes review at $24.99 (§6.2).
2. **Grocery-list quality (good odds — but copyable).** It's a feature gap, not a structural one; ReciMe could fix it in a couple of sprints. The evidence it won't soon: the same complaints have sat in reviews for 2+ years while the team ships import sources and content. Treat it as your retention layer, not your billboard (§6.3).
3. **Offline/privacy alone (weak as a standalone).** Too abstract to market by itself; it works as the supporting argument for wedge #1 ("your recipes outlive any company" — post-Yummly, that lands).

**What to avoid competing on:**

- **Marketing spend / content volume.** Their ~systematic TikTok operation drives an estimated ~300K downloads/month. You will not out-content a funded team; one plain sentence: if your plan requires beating ReciMe on TikTok, you have no plan.
- **Import-source breadth.** Their video cascade (caption → audio → source site) is a permanent engineering treadmill they can afford and you can't.
- **Feature breadth.** Meal planning + community + nutrition + planner is table-stakes-creep; matching it delays launch by months and differentiates nothing.
- **Price-per-month undercutting.** $2/mo vs their $3.33/mo effective earns you 40% less per user at identical acquisition cost — cheap subscription is the worst of both worlds (§3).

---

## 3. Market: real demand, small honest market, one-time pricing is what users *want*

### Size — ignore the billion-dollar reports

- Headline "recipe app market" figures range **$1.4B to $6.1B for the same year** — the big ones bundle in content platforms (Tasty, Cookpad) and meal-kit adjacency. SEO-mill reports; discard.
- Most credible back-solve (Technavio): base market ~**$600M (2024), growing ~10–12%/yr**. Recipe-*organizer software* specifically is plausibly low hundreds of millions globally.
- **What breaks if you believe the $6B number:** you'll overestimate your ceiling ~10x and overbuild.

### Demand signals — genuine

- ReciMe: #9 Top Free and **#2 Top Grossing** Food & Drink; 1M+ Play installs. People demonstrably pay for this.
- TikTok itself piloted a recipe-save button (with Whisk) in 2021; TikTok auto-generates Discover hubs for "how to save TikTok recipes" — meaning real search volume.
- Reddit r/Cooking generates "which recipe app" threads several times per month. Real, recurring pain point — but moderate chatter, not viral.

### Willingness to pay — the most important finding in this section

- **Revealed preference is one-time purchase.** Paprika at $4.99 has held #1 Top Paid Food & Drink for years with 4.9 stars. "Buy once, own forever" is the category's love language.
- **Subscription monetizes better but generates the hate.** ReciMe's #2-grossing rank proves ~$40/yr works *if import quality delivers* — but its most-upvoted review is a billing complaint (§2.2), and competitors now market *against* subscriptions explicitly.
- Your **$1–5/mo price point is below-market**: ReciMe ≈ $3.33/mo effective, Flavorish $4.99/mo, Samsung $6.99/mo. Cheap ≠ advantage here (§2.4).
- Benchmarks: hard-paywall apps convert **12.1%** of downloads to paid vs **~2.2%** freemium (RevenueCat, 75K apps). Subscription-fatigue backdrop is real: US households cut avg. subscriptions from 4.1 → 2.8 (2024→2025).
- Core user skews female, Gen Z/Millennial, US-dominant (75%+ of ReciMe's revenue is US).

**What this means for you:** the demand is real but the winning price structure for a late entrant is probably **one-time or lifetime, not $2/mo** — it's what users beg for and no AI-import app offers it as its headline (§6.2).

---

## 4. Unit economics: excellent — and irrelevant

All API prices verified against official pricing pages, Aug 2026.

### Cost per recipe extraction (1 screenshot + ~200-token prompt → ~800-token JSON)

| Route | Cost/extraction |
|---|---|
| Apple Vision OCR on-device → cheap text-only LLM structuring | **~$0.0004** (and enables offline/free tier) |
| Apple Vision OCR → Apple Foundation Models on-device structuring | **$0.00** (see §6.2; Apple Intelligence devices only) |
| GPT-5-nano (vision) | ~$0.0005 |
| Gemini 3.1 Flash-Lite (vision) | ~$0.0015 |
| Claude Haiku 4.5 (vision) | ~$0.006 |
| Cloud OCR (Google Vision / Textract) | $0.0015 — no cheaper than a full LLM call; only on-device changes anything |

### Margin at $2.50/mo, 30 extractions/user/month

| Cost line | $/user/mo | % of revenue |
|---|---|---|
| App store fee (15% small-business rate — still in effect on both stores) | $0.375 | 15.0% |
| LLM API (Gemini Flash-Lite) | $0.045 | 1.8% |
| RevenueCat (free below $2.5K/mo tracked revenue, then 1%) | $0.025 | 1.0% |
| Hosting (Supabase/Cloudflare, amortized at 10K users) | $0.005 | 0.2% |
| **Gross margin** | **$2.05** | **~82%** |

Worst case (premium model, 40 extractions/mo): ~74% margin. Fixed floor: Apple $99/yr + Google $25 + ~$30/mo hosting → **~20 paying subscribers to break even** before valuing your time.

### Three fine-print items

1. **The 15% store fee is 8–10x your AI cost.** The platform, not the AI, is your biggest supplier. Optimizing model choice is bikeshedding.
2. **External payments don't save you at $2.50/mo.** Stripe's $0.30 fixed fee makes a $2.50 web charge cost 15.6% — a wash vs Apple. Web checkout only wins on **annual** plans ($25/yr → 4.8% fees). Also the US 0%-link-out regime (Epic v. Apple) is now before the Supreme Court — treat it as a window, not a foundation.
3. **Model prices are moving targets** (Gemini 2.5 Flash-Lite retires Oct 2026; Sonnet 5 intro pricing ends Aug 31, 2026) — but at 1–2% of revenue, even a 3x price swing doesn't matter.

**What this means for you:** unit economics are a green light and a trap — margins this good mean the moat isn't cost, so everyone can afford to compete, and your real constraint is acquisition and churn (§5).

---

## 5. Solo-business realism: what it pays, and what it costs you every week

### Base rates (RevenueCat 2026: 115K apps, $16B tracked revenue — the best dataset that exists)

| Metric | Number |
|---|---|
| Median revenue, 1 year after launch | **$72/month** |
| Top quartile / top 10% | $429/mo / $2,574/mo |
| Odds of reaching $1K MRR within 2 years | **17.3%** |
| Odds of $10K MRR | 4.6% |
| New subscription apps launched per month | **14,700+** (was ~2,000 in 2022) |
| Revenue share of apps launched since 2025 | **3%** (pre-2020 apps hold 69%) |
| Bottom-quartile YoY MRR | **shrinking ≥33%** — coasting is a decay path |

### Funnel reality (no marketing budget)

- Download → paying: median **~2.6%** (North America); hard paywall 10.7%.
- Monthly-plan retention: **~17% of subscribers still active at 12 months** (~14%/mo effective churn). At $2.50/mo, an average subscriber is worth roughly **$15–18 lifetime, ~$13–15 after store fees**.
- **AI-feature apps churn 30–36% faster** than average (novelty wears off).
- Paid ads are ~10x underwater for the median app (~$4 iOS CPI vs $0.34 median 60-day revenue per install). Organic (ASO + content) is the only viable channel — and content production is part of the weekly workload, not a launch task.
- Established comparison points: Mela (famous dev, gorgeous app) ≈ $9K/mo on <5K downloads/mo. Umami (well-made, $0.99/mo) — ~413 ratings after years. Crouton won an Apple Design Award and the dev still sold rather than run it as a business.

### The weekly workload — five treadmills that never stop

1. **Import breakage (the specific tax on this idea).** TikTok rotates video URLs, Instagram signs media URLs; Meta shut its consumer API (Dec 2024) and locked oEmbed behind app review (2025). Every social-import app is scraping in a gray zone. If ignored: your headline feature silently breaks and 1-star reviews arrive within days. (Largely defused by the screenshot-first scope in §6.5 — link import becomes a bonus that can break without killing the product.)
2. **Annual forced maintenance.** Apple requires rebuilding against the new SDK every year (iOS 26 SDK mandatory April 2026). If ignored: you lose the ability to ship updates, then get delisted as outdated.
3. **Review friction.** Apple rejected ~25% of 7.77M submissions in 2024. Budget for it in every release.
4. **Support load.** AI extraction is ~90% accurate on ingredients, ~70% on edge cases — every miss is a support email. Indie benchmarks: up to ~1 hr/day at real scale.
5. **Competitor pressure.** 25+ funded-or-hungry clones ship weekly. Standing still = the bottom quartile's −33%/yr.

### Realistic time-and-income trajectory for a solo builder

| Phase | Time | Income (probability-weighted) |
|---|---|---|
| Validation (§8 steps 1–2) | ~2 weeks of evenings | $0 |
| MVP build | 6–10 weeks of nights (~10–15 hrs/wk) | $0 |
| Year 1 post-launch | **5–10 hrs/wk** (fixes, support, ASO, content) | Median **$72/mo**; good case low hundreds/mo |
| Years 2–3, if top-quartile | 5–10 hrs/wk sustained | $500–3K/mo; ~1-in-6 odds of $1K+ MRR |
| Ceiling (solo, this category) | Effectively a part-time job | **~$9K/mo** (Mela — famous dev, years of compounding) |

Every visible bigger success is a different game: ReciMe is a funded team with a content operation; HabitKit ($30K/mo) is its dev's full-time job; Slopes took 9 years to $1M ARR. The low-workload solo apps that persist are zero-backend, local-only tools earning hundreds/month — which, notably, is what the §6.2 architecture approximates.

**What this means for you:** priced as work, year one likely pays under $1/hour; the honest frame is *building an asset* with a ~1-in-6 chance of reaching $1K MRR and a realistic path to beer-money-to-rent-money over 2–3 years — sustainable only if you'd do the 5–10 hrs/week with some enjoyment.

---

## 6. Differentiation: two real gaps, one small niche, one trap

### 6.1 True video understanding — the trap

The leader is caption-first with fallbacks (§2.1); nobody reliably handles silent/ASMR/no-caption videos (frames + audio + on-screen text). Winning here is possible and defensible-ish — but it sits on gray-zone scraping and permanent breakage risk (§5, treadmill 1). **High effort, high maintenance, competes head-on with the funded player. Skip it at launch.**

### 6.2 Gap 1: one-time price + local-first + AI import ✦ strongest angle

**The gap:** every AI-import app is subscription; every beloved one-time app (Paprika, Mela, Recipe Keeper) lacks real AI import. The obvious objection — "one-time price can't fund ongoing API costs" — turns out to have three proven mechanisms, with named precedents for each. And per §2.4, this is the one wedge the incumbent structurally cannot copy.

#### How one-time pricing coexists with per-use AI costs

**Mechanism A — on-device pipeline (the structural answer, $0 marginal cost).**

- Apple's Vision framework does OCR **on-device, free, on any iPhone** (document recognition expanded in iOS 26).
- The **Foundation Models framework (iOS 26+)** gives third-party apps free access to the on-device ~3B Apple Intelligence model — no API key, no per-call cost, works offline. Structured output is a first-class feature: `@Generable`/`@Guide` macros constrain generation to Swift structs, and **Apple's own documentation examples are literally recipe-shaped types** (ingredients arrays, cook time). This is your use case, blessed by the platform.
- Hard limits: **4,096-token context per session** (fits one OCR'd recipe + schema; long blog dumps need chunking), occasional blank fields on large structs (validate + cloud fallback), and it only runs on **Apple Intelligence devices (iPhone 15 Pro and later)** — older devices need the cloud path.
- Precedents that this model sustains a one-time price: **Pestle** does its Reels/TikTok caption parsing with on-device ML specifically to avoid third-party AI costs; **MacWhisper** built a sustainable ~$59–79 one-time license on on-device Whisper transcription; **Crouton advertises "AI IMPORTING — import a recipe from a single photo" inside its $24.99 one-time purchase** — the closest existing proof that one-time + AI import ships and passes App Review.

**Mechanism B — non-expiring credit packs for cloud-grade extraction (legal, precedented).**

- Apple Guideline 3.1.1 explicitly permits consumable credits with one hard rule: **purchased credits may never expire** (unredeemed credits = perpetual service liability; price accordingly).
- Precedent at scale: **Lensa AI** sold AI avatar packs ($3.99/100-tier pricing) as consumables and hit #1 on the App Store — App Review is fine with consumable AI credits.
- The math is comfortable: a **$1.99 pack of 100 cloud imports** costs you $0.05–0.60 in API (cheap→premium model) plus $0.30 Apple cut → healthy margin even at the expensive end. Decouple "credits" from dollar amounts so you can re-rate as API prices fall.
- Risk: credit systems in photo/AI tools attract "money grab" resentment when they're stingy or opaque (see Fstoppers' "industry's dirtiest money grab" piece). Mitigation: generous free on-device tier, credits only for the premium cloud model, transparent counts.

**Mechanism C — bring-your-own-API-key (power-user escape hatch only).**

- BYOK apps exist and ship on the App Store (BoltAI, Open Chat Inference, various Obsidian-adjacent tools), **but there is one documented App Review rejection (Sep 2024)** of exactly this model — rejected under 3.1.1 because "the app uses API keys to unlock or enable functionality." The apparent (inferred, not official) pattern: BYOK survives when it isn't the thing that gates paid features. Treat it as review roulette; never make it the primary path. Bonus: it lets your heaviest users self-fund unlimited extraction.

**Recommended stack** (all pieces precedented): on-device OCR + on-device structuring as the free/default path → cheap cloud vision model behind a capped one-time tier or credit packs → BYOK buried in settings for the HN crowd.

#### Evidence users actually want this combo

- HN, "Ask HN: Meal Planning App?": *"Paprika is great. I'd much rather pay once upfront than for a subscription"* — from the commenter who then **built Umami because nothing matched "Paprika in terms of features and payment model."*
- Crouton's App Store reviews capture both halves of the demand in users' own words: fear of subscription/abandonment (*"please don't leave users high and dry like the developer of my other recipe app"*) and AI-import delight (*"the AI takes wildly typed recipes and makes it a simple format… including my grandmother's 1950 recipes"* — Jan 2026).
- Whole SEO categories exist for the query ("best recipe apps with no subscription"); ReciMe's most-upvoted Play review is a pricing complaint (§2.2); its occasional free-lifetime giveaways triggered deal-site swarms — price sensitivity is extreme.
- Industry-level: RevenueCat's 2026 report notes **35% of apps now mix subscriptions with consumables or lifetime purchases**, with one-time purchases growing ~6% as a subscription-fatigue response *(figure from report summary — verify against the PDF before quoting publicly)*.
- Honesty flag: no verbatim user quote saying "one-time purchase recipe app with AI import" was found — the evidence is the two halves separately attested, plus Crouton profitably shipping the combination quietly.

#### Pricing benchmarks (what one-time buyers pay in this category, 2026)

| App | One-time price |
|---|---|
| Paprika | $4.99/platform (the low anchor) |
| Mela | ~$5–10 |
| Recipe Keeper Pro | $9.99/platform |
| Umami lifetime | $19.99 |
| Crouton Plus | $24.99 (includes AI photo import) |
| Pestle lifetime | $39.99 (the high end) |

Rule of thumb from RevenueCat's lifetime-pricing guide: lifetime SKUs typically price at **2–12x the annual sub**. Against ReciMe's $39.99/yr, a $19.99–29.99 lifetime with capped/credited AI is aggressive but inside category norms.

#### Risks of this model — each one sentence, what breaks if ignored

1. **You can never claw features back from lifetime buyers** (Guideline 3.1.2(a); Notability tried in 2021, was forced into a public reversal) — so if you ship "unlimited AI imports forever," you're contractually stuck with it; ship a stated fair-use cap or credits **from day one**.
2. **Heavy-user abuse is real but manageable:** a $9.99 lifetime nets ~$8.49 after Apple; at $0.0005/extraction a user needs ~17,000 imports to zero your margin, but at $0.006 (premium model) only ~1,400 — default to the cheap model, rate-cap, push whales to on-device or BYOK.
3. **Lifetime cannibalizes your best subscribers if you ever run both** (RevenueCat's guide; Astropad's CEO called supporting lifetime users while costs continued his hardest lesson) — and RevenueCat's own "should you offer lifetime?" quiz starts with *"are your ongoing costs per user low?"* — which is exactly why on-device-first matters.
4. **The revenue ceiling is structurally lower:** no recurring revenue means Mela's ~$9K/mo is the realistic best case, and every sale is one-and-done — fine for a side business, wrong if you secretly want MRR.

### 6.3 Gap 2: grocery-list quality — the boring wedge that names its own spec

**The gap:** the complaint pattern across ReciMe, Samsung Food, and the open-source recipe managers is remarkably consistent — and a $14.99/yr single-purpose app (AnyList) proves people pay for getting it right.

#### What the leaders do badly (cited, specific)

**ReciMe** (from Plan to Eat's hands-on review, updated 2026; also §2.2):

- *"The shopping list doesn't merge duplicate items (not even from the same recipe planned twice in one week)"* — an App Store reviewer: 3 recipes needing 2 lemons each produce *"3 rows of 1 X lemon"* instead of "6 X lemon."
- *"Changes and updates to your meal plan don't automatically update the items on the shopping list"* — change servings, manually rebuild the list.
- *"No customization options for shopping list categories… sesame oil is grouped under 'herbs and spices'… no way to move it."*

**Samsung Food** (from current App Store reviews; JustUseApp's analysis of 6,187 reviews scores it 60% "negative experience"):

- *"Changing the servings and adding recipe to shopping list doesn't preserve the adjusted ingredient amount, so shopping off that list will get you the wrong ingredient amounts."*
- The parser destroys ranges: *"'6 – 8 Tbsp of cold water'… it automatically changes it to just '6 tablespoons water.' Why?!"*
- *"Coconut milk gets sorted into dairy/eggs… several common ingredients get filed under 'uncategorized' with no option to change it"*; shared list doesn't show who added what; only one store layout.

**Open-source (Mealie/Tandoor) — years of effort, same wall:** Mealie only merges exact food+unit matches (500g mince + 1kg mince stay separate; the merge path itself had crash bugs); Tandoor's issue tracker asks for a per-food USDA conversion table just to combine "3 tsp salt" with "5 g salt." Mealie's own Oct 2024 user survey is effectively a free product-requirements doc — users literally spec the feature: *"Offer prompts to combine ingredients… 'Want to add 1 onion with 1/2 cup onion, diced?'"* — and multiple respondents report defecting to AnyList over exactly this. **The list layer is where recipe managers lose users.**

(Credit where due: Paprika and Crouton both auto-merge — *"if two recipes need onions, Crouton merges them"* — it's the AI-import generation that regressed on list basics.)

#### What best-in-class looks like (AnyList, 4.9★ / ~77K ratings, $9.99/yr or $14.99/yr household)

1. Ingredient parsing on import → one-tap add to list.
2. Automatic aisle categorization with **per-store category customization** — the exact feature ReciMe/Samsung users beg for.
3. **Scaling propagates to the list** (scale 4→8 servings, list quantities update — the exact Samsung Food bug, done right).
4. Live shared-list sync (~1.7s, fastest in independent testing), Alexa/Siri entry.
5. Twelve years of edge-case polish — the moat is accumulated corrections, not algorithms.

#### How hard is each piece to build? (evidence-based difficulty)

| Piece | Difficulty | Why |
|---|---|---|
| Ingredient-line parsing ("2 cups flour, sifted" → qty/unit/item/prep) | **Medium** (was hard pre-LLM) | Best open-source CRF parser: 95.9% sentence-level accuracy on 75K labeled lines; GPT-4o zero-shots ~95% incl. unit normalization (2026 FoodBench study). ~1 in 20 lines still wrong → ship a confirm/edit UX, not silent automation. NYT abandoned its own parser; a whole SaaS (Zestful) exists just to sell this function. Ranges and non-English inflections remain the trip wires. |
| Plan→list propagation & scaling | **Easy–medium** | The wild failure mode is architecture, not math: Samsung computes scaled amounts on the recipe page but exports a stale snapshot to the list. Model the list as a **live view of the meal plan** from day one — easy up front, painful retrofit. |
| Aisle sorting | **Easy–medium** | Classification is trivial for an LLM (and solved pre-LLM with lookups). The *actual* differentiator users name: per-store layouts + **remembering the user's corrections**. CRUD + persistence, not ML. |
| Cross-unit merging (2 tbsp butter + ½ stick butter; 500g + 1kg mince) | **Hard** — the graveyard feature | Volume↔weight is per-food (cup of flour ≠ cup of butter) → needs a food-density table (USDA FoodData Central is the open source for it); count units ("1 stick," "1 clove") need product-knowledge mappings with no clean open dataset. LLM one-pass gets ~95% — but 5% wrong quantities on a shopping list destroys trust. The evidence-backed design: **suggest-and-confirm merge prompts** (what Mealie's users explicitly requested), not silent merging. |
| Pantry awareness | **Hard** — skip it | Cooklist's approach (auto-import purchases from 75+ grocery loyalty programs) is an integration moat no solo dev replicates, and even it can't observe consumption; manual pantries die of neglect. The cheap 80% version: a "staples" flag that auto-unchecks salt/oil/etc. |

**Strategic note:** no AI-native entrant (Flavorish's "Aisle Sort," AisleBird, IntelliCart, …) has independent review volume validating its list intelligence — it's all first-party marketing — while the biggest AI-branded incumbent (Samsung "Vision AI") still ships the propagation and category-lock bugs in 2026. A list that *provably* merges, scales, and remembers your store layout would be the only one on the market attached to an AI importer. Weak as a headline feature; strong as the retention feature that stops churn to AnyList.

### 6.4 Small niche worth testing: heirloom/handwritten family recipes

Generic OCR still only manages **82–87% on handwriting** (vs 95–98% printed), and the emotional pull is real — Crouton's happiest 2026 review is about digitizing *"my grandmother's 1950 recipes."* A "digitize the family recipe box" positioning (side-by-side original photo + extracted text, gift/family sharing) is underserved and dodges the social-scraping treadmill entirely. Evidence is thinner than for §6.2/§6.3 — treat it as a marketing angle to A/B test (§8, step 2), not a product bet.

### 6.5 Refined product thesis, evaluated: screenshot-first + your-storage + pay-once ("rescue your camera roll")

**The thesis:** screenshots are the main import funnel (user screenshots the recipe themselves, vision AI extracts); link/share-sheet import is a bonus that can be dropped if it breaks; recipes live as open files in storage the user owns (local + iCloud by default, Google Drive/Dropbox optional); onboarding scans the camera roll and batch-imports existing recipe screenshots; after import, the app encourages deleting the screenshot ("no need to hoard them").

**Verdict: it holds together — this is the strongest formulation of the §6.2 wedge, and the report adopts it in §8.** It doesn't change the go/no-go or the §5 base rates. What each leg fixes, with evidence:

#### Leg 1: screenshot-first import — kills the worst treadmill

- **Treadmill immunity is real.** A screenshot pipeline can't suffer link rot, API shutdowns, or scraping ToS risk — the §5 treadmill-1 failure modes all live in URL-fetching. Link-based saves demonstrably rot: saved TikTok/IG entries turn into blank tiles when videos are deleted ([Recipy](https://recipyapp.com/blog/tiktok-recipe-save-broken-2026)), and Flavorish's changelog shows TikTok short-links breaking and needing emergency fixes ([changelog](https://www.flavorish.ai/changelog)). Demoting link import to a degradable bonus means platform breakage becomes a shrug, not a 1-star-review event.
- **The hoarding pain is verified.** 83% of Americans see food/recipe content on social; among savers, only a third usually cook what they save ([Harris Poll for Instacart](https://www.instacart.com/food-trends-delivered/)); the average phone holds ~2,795 photos ([PhotoAid](https://photoaid.com/blog/mobile-photography-statistics/)); "screenshot graveyard" is established consumer language, and a whole app category (screenshot organizers: Captr, Sorti, ShotBox) exists to service it. Recipe apps already buy SEO on "recipes buried in your camera roll" ([WiseList](https://www.wiselist.app/recipe-screenshot-to-saved-recipe/)).
- **Nobody is screenshot-FIRST.** Every incumbent treats screenshots as the fallback when link import fails (ReciMe's own help doc frames it that way — [import from screenshots](https://recime.app/help/en/articles/11049450-import-from-screenshots)); one competitor (Peel) actively markets *against* screenshots. The positioning is unclaimed.
- **What's lost, one sentence each:** video-only recipes (spoken aloud, nothing on screen) are out of scope by design — that's the price of treadmill immunity, and it's the segment even the leaders fail at anyway (§1). Truncated captions need expand-then-multi-screenshot — the extraction UX must accept 2–3 stacked images per recipe (precedented: ReciMe supports multi-screenshot imports). No source URL means no tap-back-to-video attribution unless the user also shares the link — no review evidence users demand this (flag), but Peel markets it as a feature. Note the flip side: a screenshot captures **on-screen overlay text that caption-only parsers (Kitchen Stories, Pestle) structurally miss**.

#### Leg 2: batch gallery import at onboarding — feasible, precedented, unowned

- **Two implementation tiers, both shipping-legal today:** (a) zero-permission — `PHPickerFilter.screenshots` presents a system picker pre-filtered to screenshots only, user multi-selects, no permission prompt ever (iOS 15+, [WWDC22](https://developer.apple.com/videos/play/wwdc2022/10023/)); (b) full auto-scan — `PHAssetMediaSubtype.photoScreenshot` filters the library to screenshots ([Apple docs](https://developer.apple.com/documentation/photos/phassetmediasubtype)), then on-device Vision OCR + keyword/Core ML classification decides "is this a recipe."
- **The exact pipeline has App Review precedent:** ShotBox ($0.99 one-time, indie) auto-imports the "screenshot graveyard," classifies on-device into categories **including Food & Recipes**, and offers one-tap camera-roll cleanup after import ([App Store](https://apps.apple.com/mt/app/shotbox/id6759891504)) — which also precedents the delete-after-import UX. CleanMyPhone (MacPaw, 5M+ downloads) proves full-library scanning passes review when scanning is the stated core function.
- **No recipe app scans the camera roll.** ReciMe, Flavorish, Recipe Keeper, WiseList all require manual per-recipe upload. The "mine your backlog at onboarding" slot is open — and it's a demo-able wow moment ("we found 87 recipes in your photos").
- **Framing economics favor "rescue/cleanup" over "recipe manager":** consumer spend on camera-roll cleaner apps runs ~$40M/month, with the top 10 grossing ~$197M in 2024 ([Appfigures](https://appfigures.com/resources/insights/20250606?f=1)) — proof of willingness to pay for the cleanup job that "recipe manager" framing has never shown. No direct A/B evidence for the recipe-specific version (flag) — test both framings in §8 step 2.
- **Design constraint:** iOS 17+ made full-library access prompts scarier and re-prompts limited-access users — default to the permission-free picker grid, offer the full auto-scan as an opt-in upgrade.
- **Sherlocking watch item:** iOS 26 visual intelligence acts on screenshots *at capture time*; Apple doesn't retroactively mine galleries for recipes today.

#### Leg 3: BYOS (your storage) — viable with the right defaults

- **Precedents that user-owned storage sustains an indie business:** Obsidian (~1.5M MAU on "your files, no account," monetizing optional sync); KeePassium/Strongbox (database file in the user's cloud, direct API connections to iCloud/Dropbox/Drive/OneDrive); Working Copy ($35.99 pay-once); and closest of all, **Mela — CloudKit sync plus a documented open export format** ([.melarecipe](https://mela.recipes/fileformat/index.html)); [Cooklang](https://cooklang.org/) proves the recipes-as-files demand exists (though it's a developer-skewed niche).
- **The right stack, verified against current platform rules:** local files + iCloud/CloudKit as the invisible default (zero OAuth, zero developer cost — user's quota). Optional connectors: **Google Drive via the `drive.file` scope — officially non-sensitive, app-folder pattern, no CASA security assessment, free brand verification** ([Google's scope table](https://developers.google.com/workspace/drive/api/guides/api-specific-auth)); **Dropbox app folder** (free; production approval kicks in at 50 linked users, no fee — [dev guide](https://www.dropbox.com/developers/reference/developer-guide)). **Skip OneDrive at launch** — its publisher verification effectively wants a registered company. Android later keeps Drive/Dropbox but forfeits iCloud.
- **Sync design (the part that kills naive BYOS apps):** one-file-per-recipe JSON/Markdown, last-write-wins per file, Dropbox-style "conflicted copy" recovery — recipes are rarely co-edited, so CRDTs are overkill. Talk to cloud APIs **directly**, never through the provider's file-sync app (KeePassium's hard-won lesson — [sync KB](https://support.keepassium.com/kb/sync/)). Paprika's famous 2011 "Dropbox can't sync a database" objection ([blog](https://paprikaapp.com/blog/2011/08/27/why-dropbox-is-not-a-feasible-cloud-sync-solution-for-paprika-recipe-manager/)) is answered by not having a monolithic database.
- **Economics:** no servers, no database, no per-user recurring cost; extraction on-device (§6.2 Mechanism A) or ~$0.0005–0.0015 in cloud API — this is precisely the "are your ongoing costs per user low?" condition that RevenueCat says makes pay-once viable. Hosting line in §4 → ~$0.
- **Caveats, one sentence each:** mainstream users don't buy "open files" — Mela's success *hides* iCloud entirely, so market the outcome ("your recipes can never be taken away" — post-Yummly, that lands), not the file format. BYOS trades server ops for supporting users' cloud quirks (full 5GB iCloud quotas, OAuth token expiry — KeePassium maintains an entire troubleshooting KB, budget the same). Apple's sign-in rule (4.8): keep the app fully functional with zero sign-in and treat cloud OAuth as an optional storage connection — the KeePassium/Cookmate pattern that ships today.

#### What the thesis does NOT fix

Retention and distribution. Batch onboarding is a one-shot wow — the §5 churn math still applies, and the week-two reason to open the app is the grocery list and cooking loop (§6.3). And a great onboarding hook still needs the §8 demand validation; ShotBox itself, with the same hook in a bigger category, is a $0.99 micro-app, not a business.

---

## 7. The Europe option: language beachhead maybe, grocery prices later

### 7.1 What's actually open in Europe

- **Not a differentiator:** metric units — every EU-native app is metric; table stakes.
- **Owned:** France's recipe-to-cart (Jow — 6M users, 6 major chains); UK/DE cart checkout, free (Samsung Food: Tesco/Ocado/Sainsbury's + REWE/Amazon Fresh); each retailer's own ecosystem (Albert Heijn Appie, ICA, REWE, Lidl).
- **Attempted but not won (teardowns in §7.2):** France's AI-clipper slot (RecetteClic — same thesis as yours, ~zero traction) and DACH import (Kitchen Stories — big-brand bolt-on with manager-features missing).
- **Genuinely open:** AI social import with native-language output/translation for **Dutch, Italian, Polish, and Nordic** markets. ReciMe's interface is EN/FR/DE/PT/ES only with an English-first pipeline and a stated 100%-US acquisition strategy ([SmartCompany](https://www.smartcompany.com.au/startupsmart/recime-nyc-new-york-move-recipe-app-startup/)); Flavorish only recently stopped force-translating imports to English ([changelog](https://www.flavorish.ai/changelog)).
- **The economics discount:** Western Europe converts and prices ~20–30% below North America (trial→paid median 2.0% vs 2.6%; subscription prices ~39% lower; retention slightly *better* — [RevenueCat](https://www.revenuecat.com/state-of-subscription-apps), via secondary summary).

### 7.2 EU competitor teardowns

**RecetteClic (France) — your exact thesis, executed fast, going nowhere yet.**

| Fact | Detail |
|---|---|
| Launch | iOS May 20, 2026; Android June 2026 ([App Store FR](https://apps.apple.com/fr/app/recetteclic-recettes-videos/id6753633455)) |
| Traction | **5.0★ from 4 ratings**; Google Play "10+" installs bucket; zero press, no Product Hunt, no social presence found |
| Execution | Solo dev (sole trader, VAT-franchise = sub-€37K/yr revenue); **16 releases in 10 weeks**; full GDPR polish; FR/EN/ES translation |
| Pricing | €3.99/mo / €29.99/yr — **cut from €6.99/€59.99 six weeks post-launch**; free tier = 5 imports *lifetime* |
| Gaps | No one-time tier, no export (GDPR JSON only), no web app, no offline import, cloud-only AI (OpenAI/Anthropic), no retailer integration; grocery list + meal planner shipped days ago |

What it means for you, in one sentence each: the French slot is contested but **not owned** — 4 ratings is not a moat; and it's a live base-rate exhibit — competent execution + the right thesis + no distribution = ~10 installs, which is exactly what §5 predicts happens to you without a demand plan.

**Kitchen Stories Rezept-Importer (DACH) — distribution without a manager.**

| Fact | Detail |
|---|---|
| Scale | 25M cumulative downloads, ~2M monthly uniques (self-reported); 45K DE App Store ratings (4.8★ lifetime) |
| Owner | **Funke Mediengruppe since Oct 2025** (media consolidation with Chefkoch — not a product-first owner); retrenched from 12 languages to **DE/EN only** ([turi2](https://www.turi2.de/aktuell/auf-den-appetit-gekommen-funke-uebernimmt-kitchen-stories/)) |
| Importer | Instagram/TikTok/web/screenshots; **iOS-only ~15 months after launch**; Plus-only (€39.99/yr promo, €79.99 list; 6 trial imports); **caption-only for videos** — own FAQ admits ingredients are missed if not in the text ([importer FAQ](https://www.kitchenstories.com/en/stories/faq-recipe-importer-issues)) |
| Manager gaps | Imported recipes are **read-only** (no editing, scaling, or notes); **no export in any format**; no offline mode; list doesn't merge quantities or sort per user reviews; ads reportedly persist for paying subscribers (single-source) |
| Health signal | Recent App Store reviews average **2.3★ over the last ~49** vs 4.8 lifetime ([iosapps.de](https://iosapps.de/apps/kitchen-stories-rezepte-kochen/)) |

What it means for you: Kitchen Stories validates DACH demand for social import while demonstrating, in live user reviews, every gap in your §6.2/§6.3 wedge — pay-once, editing, export, offline, and a competent list are all absent.

**Combined implication:** neither EU competitor blocks anything. Both are subscription-only, export-free, cloud-locked, and confined to FR/DACH; neither touches NL/IT/PL/Nordics. The window is more open than "two entrants in 12 months" suggests — but RecetteClic's 10 installs is the cautionary tale: in this market, being first ≠ being found.

### 7.3 Grocery price data across Europe, ranked for an indie dev

No EU-wide mandate or Instacart-style API exists; Eurostat publishes indices only. Accessibility is inverted from where the money is:

| Tier | Countries | Route | Catch |
|---|---|---|---|
| **1 — turnkey** | **Croatia** | Only EU Israel-style mandate (NN 75/2025): daily machine-readable price files from every retailer; open-source aggregator exists ([cijene-api](https://github.com/senko/cijene-api)) | Tiny market |
| **1 — turnkey** | **Norway** | [Kassalapp API](https://kassal.app/api): EAN-level prices, free hobby tier, ToS-clean | Norway only |
| **2 — scrapable portals** | Greece, Hungary | Gov portals ([PosoKanei](https://posokanei.gov.gr) ~8K products/10 chains daily; [Árfigyelő](https://arfigyelo.gvh.hu) 9 chains) | Per-chain not per-store; no official APIs |
| **2 — stable unofficial** | Netherlands, Denmark | Reverse-engineered AH/Jumbo app APIs ([SupermarktConnector](https://github.com/bartmachielsen/SupermarktConnector)); Denmark: [Salling official API](https://developer.sallinggroup.com/api-reference) | ToS gray zone (NL); partial coverage (DK) |
| **3 — scraping only** | UK, Spain, France | Mature scraper tooling; Tesco killed its official API | ToS risk; anti-bot (FR) |
| **4 — effectively closed** | **Germany, Italy, Poland**, Sweden, Finland | DE: Aldi/Lidl publish no shelf prices (fatal gap); IT: nothing; PL: flyer apps only | The biggest markets are the worst |

Pan-EU shortcuts: [Open Prices](https://prices.openfoodfacts.org) (ODbL) is the only open dataset but ~270K prices total — far too sparse as a primary source. [Pepesto](https://www.pepesto.com/supermarkets/) sells one API over 26 chains in 11 countries, pay-as-you-go — almost certainly scraped rails, so reliability and legal risk transfer to you, not away. Legality baseline: CJEU *Ryanair* (C-30/14) — ToS can prohibit scraping even of non-database-protected data ([Pinsent Masons](https://www.pinsentmasons.com/out-law/news/website-operators-can-prohibit-screen-scraping-of-unprotected-data-via-terms-and-conditions-says-eu-court-in-ryanair-case)).

### 7.4 Verdict: prices are a v2 feature, one market max

Grocery prices don't belong in the MVP. The data layer is fragmented per country, mostly unofficial or scraped (a second ToS-risk treadmill on top of the social-import one in §5), strongest where your market isn't (Croatia, Hungary, Greece) and weakest in Germany, Italy, and Poland — and the incumbents who do show prices (retailer apps, Bring!, KptnCook) give them away free, so prices won't win a paying user but will generate support tickets whenever a scraper breaks. Credible v2 shape: one deliberately chosen market on clean rails — Norway via Kassalapp, or the Netherlands via the battle-tested AH/Jumbo endpoints — added only after the core import-and-list loop is earning. If a Europe angle enters the MVP at all, it's the **language beachhead** (NL/IT/PL/Nordics, native-language extraction + translation), which costs little given LLM multilinguality — testable as a third landing-page variant in §8, step 2.

---

## 8. Go/no-go and the lean validation path

### Strongest case FOR

1. Margins ~80%; total build cost is nights-and-weekends + ~$150/yr fixed.
2. Two verified gaps with named, quotable user demand: the one-time/local-first quadrant (§6.2) and grocery-list quality (§6.3) — you'd launch with an actual answer to "why you?"
3. Demand is proven (ReciMe #2 grossing) and the pain point recurs monthly on Reddit.
4. Every mechanic you'd need is precedented: Crouton ships AI import inside a $24.99 one-time price, Pestle proved on-device parsing solo, Lensa proved consumable AI credits pass review, AnyList proves people pay yearly just for a good list.
5. Your primary wedge (§6.2) is the one thing the funded incumbent structurally can't copy (§2.4).

### Strongest case AGAINST

1. **The idea as stated is app #26.** Undifferentiated screenshot-import at $2/mo loses to ReciMe (better funded), Flavorish (better tested), and Paprika (better loved).
2. **Base rates:** ~83% of new subscription apps never reach $1K MRR; median $72/mo at one year; priced as work, year one pays under $1/hour.
3. **The workload floor is permanent:** 5–10 hrs/week indefinitely (import breakage, SDK rebuilds, support, content) — and the one-time model you'd differentiate on caps upside at ~Mela scale ($9K/mo best case).
4. The channel that grew ReciMe (systematic TikTok content) is a marketing job you'd have to want to do.

### If you go: validate in this order, cheapest first

1. **Weekend 1 — validate extraction AND detection (2 days, ~$1 in API calls).** Script: your own backlog of recipe screenshots → Gemini Flash-Lite / GPT-5-nano → structured JSON, plus 5 handwritten recipe cards. Also test the §6.5 batch hook: run on-device OCR + a keyword heuristic over your full screenshot folder and measure "is this a recipe" detection precision — ~100 real screenshots is a perfect test set. If you're on the iOS 26 SDK, spike Vision OCR → Foundation Models on-device structuring — §6.2 hinges on it. Pass bars: ≥90% of recipes usable without edits; detection good enough that the onboarding grid isn't full of junk. *If handwriting, on-device structuring, or detection fails badly, the differentiators die here — better now than after 3 months of SwiftUI.*
2. **Week 2 — validate demand (3–5 evenings, optional ~$100 ads).** One landing page, positionings A/B'd: (a) **"Rescue the recipes buried in your camera roll"** (the §6.5 cleanup framing — cleaner-app economics suggest this converts, but it's untested for recipes), (b) "Own your recipes forever — one-time price, AI import, no subscription," (c) "Digitize the family recipe box — grandma's handwriting included," (d) optionally a §7 language-market variant (e.g. Dutch or Polish copy). Post where the pain already surfaces (r/Cooking-adjacent threads, cooking Facebook groups). Pass bar: ~200 signups or one clearly winning message.
3. **Weeks 3–12 — MVP only if 1 and 2 pass (6–10 weeks of nights).** iOS-only, the §6.5 architecture: local files + iCloud default (no accounts), optional Drive (`drive.file`) / Dropbox app-folder connectors, one-file-per-recipe. **Batch onboarding** via the permission-free screenshots picker (full auto-scan as opt-in), share-sheet screenshot import as the everyday path, delete-after-import prompt, on-device OCR + structuring with cloud-credit fallback. Link import: bonus only, behind a feature flag you can kill remotely. Grocery list does the three things leaders provably fail at: **merge duplicates (suggest-and-confirm), live plan→list sync, remember category corrections**. **Hard paywall, $19.99–24.99 one-time with a stated fair-use AI cap** (hard paywall converts 12.1% vs 2.2% freemium; the cap keeps Guideline 3.1.2(a) from ever trapping you). No backend beyond a thin API proxy for cloud extraction.
4. **Kill criterion — set it now, in writing.** Example: if 3 months post-launch you haven't hit 1,000 downloads and ~$500 total revenue with honest ASO + a few content posts, stop building and keep it as a portfolio piece. *Without a pre-committed kill line, sunk-cost will eat a year — that's the single most common indie failure mode in every case study reviewed.*

### If the goal is dependable work-from-home income on a timeline

This category won't replace salary on any schedule you can plan around: the median outcome is pocket money, the good outcome takes 2–3 years of sustained 5–10 hrs/week, and the ceiling for the solo model is a part-time-job income. Better-EV uses of the same skills: B2B/niche utilities with hard paywalls (higher price, lower churn, less content-marketing dependence), a portfolio of small apps to diversify the 1-in-6 odds, or contract work. Build this app if you'd enjoy the craft *even if* it tops out at Umami-scale — that's the honest most-likely outcome.

---

## 9. Confidence notes & key sources

**High confidence (verified against primary/official sources):** API pricing (official Anthropic/OpenAI/Google pricing pages, fetched live); store fees and IAP rules (Apple/Google official, incl. Guidelines 3.1.1 and 3.1.2(a)); RevenueCat base rates (official report, 115K apps — cross-checked); store rankings, ratings, and IAP price lists (live App Store/Play listings); ReciMe US price $39.99/yr and import cascade (official help center); Foundation Models framework limits (Apple technote TN3193).

**Medium confidence:** download estimates (AppBrain/store brackets, not vendor-confirmed); ReciMe ~$800K MRR, ~300K downloads/mo, and "10M users" (third-party/self-reported, unaudited); churn benchmarks (Adapty/RevenueCat aggregates, category mix varies); RevenueCat "35% of apps mix subscriptions with consumables/lifetime" (taken from report summary, not the PDF); GPT-4o ~95% ingredient-parsing accuracy (single 2026 study); ReciMe App Store grocery-list quotes (surfaced via review aggregation, exact reviewers not captured).

**Low confidence / flagged:** all "recipe app market = $X billion" reports (SEO mills); AI-native apps' grocery-list claims (first-party marketing only); the BYOK App Review "pattern" (inferred from one rejection + shipping apps, no official Apple statement); no verbatim user quote requesting "one-time + AI import" found (halves separately attested); RecetteClic's extraction-quality claims (all self-published, zero third-party verification); Kitchen Stories importer launch timing (derived from asset/social timestamps, no announcement) and "ads despite Plus" (single-source); EU price-data rankings are point-in-time — mandates and portals are moving fast (Croatia's is from May 2025, Bulgaria's from Aug 2025); no A/B evidence exists for "rescue your camera roll" vs "recipe manager" framing (inferred from cleaner-category economics); no public benchmark exists for vision-LLM recipe extraction from social-media screenshots specifically; ShotBox details rest on a single App Store listing; Obsidian revenue figures are third-party estimates. Reddit was measured via archives and forums, not directly (crawler-blocked).

### Primary sources

- Competition & ReciMe teardown: [ReciMe pricing (official)](https://recime.app/help/en/articles/11630592-how-much-does-the-recime-subscription-cost) · [ReciMe TikTok import cascade (official)](https://recime.app/help/en/articles/11661452-import-from-tiktok) · [ReciMe "Why didn't my recipe import correctly?"](https://recime.app/help/en/articles/14773584-why-didn-t-my-recipe-import-correctly) · [ReciMe App Store](https://apps.apple.com/us/app/recime-recipes-meal-planner/id1593779280) · [ReciMe Google Play (incl. top review)](https://play.google.com/store/apps/details?id=com.recime.app) · [ReciMe review complaints (JustUseApp)](https://justuseapp.com/en/app/1593779280/recime-easy-tasty-recipes/reviews) · [ReciMe review — features/limits (Plan to Eat)](https://www.plantoeat.com/blog/2025/01/recime-app-review-pros-and-cons/) · [ReciMe seed round](https://www.startupdaily.net/topic/funding/marissa-mayer-cooking-app-recime-in-1-5-million-seed-round/) · [ReciMe growth + US revenue share (SmartCompany)](https://www.smartcompany.com.au/startupsmart/recime-nyc-new-york-move-recipe-app-startup/) · [ReciMe content-marketing analysis (third-party, unaudited)](https://www.socialgrowthengineers.com/recimes-800k-mrr-growth-strategy) · [ReciMe discontinued lifetime SKU (OzBargain)](https://www.ozbargain.com.au/node/827499) · [Android Police 4-app head-to-head, Nov 2025](https://www.androidpolice.com/i-tried-viral-recipe-apps-clear-winner/) · [Paprika App Store](https://apps.apple.com/us/app/paprika-recipe-manager-3/id1303222868) · [Crouton App Store (IAP list + reviews)](https://apps.apple.com/us/app/crouton-recipe-manager/id1461650987) · [Crouton acquisition (The Spoon)](https://thespoon.tech/combustion-acquires-award-winning-recipe-app-crouton-appoints-crouton-developer-as/) · [Yummly shutdown](https://thespoon.tech/whirlpool-lays-off-entire-team-for-cooking-and-recipe-app-yummly/) · [Pestle TikTok import (TechCrunch)](https://techcrunch.com/2024/11/25/pestle-recipe-app-can-now-save-dishes-from-tiktok) · [Samsung Food review (Plan to Eat)](https://www.plantoeat.com/blog/2026/01/samsung-food-review-pros-and-cons/)
- Market: [Technavio recipe apps](https://www.technavio.com/report/recipe-apps-market-industry-analysis) · [TikTok × Whisk pilot (TechCrunch)](https://techcrunch.com/2021/02/11/tiktok-partners-with-whisk-to-pilot-a-recipe-saving-feature-on-food-videos/) · [ReciMe 2023 growth (SmartCompany)](https://www.smartcompany.com.au/startupsmart/recime-sizzles-jumping-20000-400000-users-in-2023/) · [Gen Z food-content habits (Morning Consult)](https://pro.morningconsult.com/analysis/gen-z-social-media-restaurants-recipes)
- Unit economics: [Anthropic pricing](https://platform.claude.com/docs/en/about-claude/pricing) · [OpenAI pricing](https://developers.openai.com/api/docs/pricing) · [Gemini pricing](https://ai.google.dev/gemini-api/docs/pricing) · [Apple Vision on-device OCR (WWDC25)](https://developer.apple.com/videos/play/wwdc2025/272/) · [Apple Small Business Program](https://developer.apple.com/app-store/small-business-program/) · [Google Play 15% tier](https://support.google.com/googleplay/android-developer/answer/10632485) · [RevenueCat pricing](https://www.revenuecat.com/pricing) · [Stripe Billing pricing](https://stripe.com/billing/pricing) · [Epic v. Apple monetization impact (RevenueCat)](https://www.revenuecat.com/blog/growth/apple-anti-steering-ruling-monetization-strategy)
- One-time + AI mechanics (§6.2): [Apple App Review Guidelines (3.1.1 / 3.1.2(a))](https://developer.apple.com/app-store/review/guidelines/) · [BYOK 3.1.1 rejection (Apple Dev Forums)](https://developer.apple.com/forums/thread/763884) · [Foundation Models framework (MacRumors)](https://www.macrumors.com/2025/06/09/foundation-models-framework/) · [Context-window technote TN3193](https://developer.apple.com/documentation/technotes/tn3193-managing-the-on-device-foundation-model-s-context-window) · [WWDC25: Meet the Foundation Models framework](https://developer.apple.com/videos/play/wwdc2025/286/) · [Pestle on-device ML (TechCrunch)](https://techcrunch.com/2024/07/08/pestles-app-can-now-save-recipes-from-reels-using-on-device-ai) · [Lensa credit pricing (CNBC)](https://www.cnbc.com/2022/12/07/lensa-app-turns-selfies-into-avatars-with-artificial-intelligence.html) · [RevenueCat lifetime-subscription guide](https://www.revenuecat.com/blog/growth/lifetime-subscriptions) · [Notability forced reversal (9to5Mac)](https://9to5mac.com/2021/11/03/notability-subscription-broke-app-store-rules/) · [MacWhisper one-time pricing](https://www.getvoibe.com/resources/macwhisper-pricing/) · [HN: "I'd much rather pay once" thread](https://news.ycombinator.com/item?id=32319352) · [No-subscription recipe apps roundup](https://www.drizzlelemons.com/blog/recipe-apps-without-subscriptions) · [BoltAI (BYOK precedent)](https://boltai.com/)
- Grocery lists (§6.3): [ReciMe review — list failures (Plan to Eat)](https://www.plantoeat.com/blog/2025/01/recime-app-review-pros-and-cons/) · [Samsung Food review quotes (JustUseApp)](https://justuseapp.com/en/app/1133637674/samsung-food-meal-planner/reviews) · [Mealie Oct 2024 survey Q9 (free PRD)](https://docs.mealie.io/news/surveys/2024-october/q9/) · [Mealie cross-unit discussion](https://github.com/mealie-recipes/mealie/discussions/5177) · [Tandoor unit-merge issue](https://github.com/TandoorRecipes/recipes/issues/495) · [Tandoor USDA density proposal](https://github.com/TandoorRecipes/recipes/issues/4415) · [AnyList Complete pricing](https://www.anylist.com/complete) · [AnyList App Store](https://apps.apple.com/us/app/anylist-grocery-shopping-list/id522167641) · [AnyList review (The Kitchn)](https://www.thekitchn.com/anylist-app-review-23004503) · [ingredient-parser accuracy docs](https://ingredient-parser.readthedocs.io/) · [NYT ingredient-phrase-tagger](https://github.com/nytimes/ingredient-phrase-tagger) · [Resurrecting a dead parser (mtlynch)](https://mtlynch.io/resurrecting-1/) · [FoodBench LLM parsing study](https://arxiv.org/pdf/2604.25774) · [Cooklist pantry approach](https://cooklist.com/cooklist-app) · [Crouton list merging praise](https://mediatalky.com/crouton-app-review/)
- Refined thesis (§6.5): [Harris Poll × Instacart food-content survey](https://www.instacart.com/food-trends-delivered/) · [Phone photo-count stats (PhotoAid)](https://photoaid.com/blog/mobile-photography-statistics/) · [ShotBox — screenshot-graveyard precedent](https://apps.apple.com/mt/app/shotbox/id6759891504) · [Captr screenshot organizer](https://apps.apple.com/us/app/captr-organize-screenshots/id6738889624) · [Cleaner-app economics (Appfigures)](https://appfigures.com/resources/insights/20250606?f=1) · [PHAssetMediaSubtype (Apple)](https://developer.apple.com/documentation/photos/phassetmediasubtype) · [PHPicker filters (WWDC22)](https://developer.apple.com/videos/play/wwdc2022/10023/) · [ReciMe screenshot-import help](https://recime.app/help/en/articles/11049450-import-from-screenshots) · [WiseList camera-roll marketing](https://www.wiselist.app/recipe-screenshot-to-saved-recipe/) · [Peel (anti-screenshot counter-positioning)](https://trypeel.app/blog/how-to-save-tiktok-recipes) · [Google Drive scope classifications (official)](https://developers.google.com/workspace/drive/api/guides/api-specific-auth) · [Dropbox developer guide](https://www.dropbox.com/developers/reference/developer-guide) · [OneDrive app-folder permissions](https://learn.microsoft.com/en-us/graph/onedrive-sharepoint-appfolder) · [Mela open file format](https://mela.recipes/fileformat/index.html) · [Cooklang](https://cooklang.org/) · [KeePassium sync KB](https://support.keepassium.com/kb/sync/) · [Joplin conflict handling](https://joplinapp.org/help/apps/conflict/) · [Paprika's 2011 Dropbox-sync objection](https://paprikaapp.com/blog/2011/08/27/why-dropbox-is-not-a-feasible-cloud-sync-solution-for-paprika-recipe-manager/) · [Local-first essay (Ink & Switch)](https://www.inkandswitch.com/essay/local-first/) · [Obsidian privacy/positioning](https://obsidian.md/privacy)
- Europe option (§7): [RecetteClic App Store FR](https://apps.apple.com/fr/app/recetteclic-recettes-videos/id6753633455) · [RecetteClic Google Play](https://play.google.com/store/apps/details?id=com.recetteclic.app) · [RecetteClic comparison/marketing page](https://recetteclic.app/en/guides/best-app-to-save-tiktok-recipes) · [Kitchen Stories Rezept-Importer page](https://pages.kitchenstories.com/de/rezept-importer) · [Kitchen Stories importer-issues FAQ](https://www.kitchenstories.com/en/stories/faq-recipe-importer-issues) · [Kitchen Stories DE App Store](https://apps.apple.com/de/app/kitchen-stories-rezepte-kochen/id771068291) · [Recent-review analysis (iosapps.de)](https://iosapps.de/apps/kitchen-stories-rezepte-kochen/) · [Funke acquires Kitchen Stories (turi2)](https://www.turi2.de/aktuell/auf-den-appetit-gekommen-funke-uebernimmt-kitchen-stories/) · [Jow retailer coverage](https://jow.fr/pages/misc/frances-leading-e-recipe-and-grocery-app-jow-raises-20m-series-a-to-take-on-us-food-habits) · [Samsung Food integrated stores](https://support.samsungfood.com/hc/en-us/articles/360042706091-Integrated-Stores) · [Croatia price mandate (ESM)](https://www.esmmagazine.com/retail/croatian-retailers-to-publish-daily-price-lists-287803) · [cijene-api (Croatia aggregator)](https://github.com/senko/cijene-api) · [Kassalapp API (Norway)](https://kassal.app/api) · [PosoKanei (Greece)](https://posokanei.gov.gr) · [Árfigyelő (Hungary)](https://arfigyelo.gvh.hu) · [Salling Group API (Denmark)](https://developer.sallinggroup.com/api-reference) · [SupermarktConnector (NL)](https://github.com/bartmachielsen/SupermarktConnector) · [Pepesto aggregator](https://www.pepesto.com/supermarkets/) · [Open Prices (Open Food Facts)](https://prices.openfoodfacts.org) · [CJEU Ryanair scraping ruling (Pinsent Masons)](https://www.pinsentmasons.com/out-law/news/website-operators-can-prohibit-screen-scraping-of-unprotected-data-via-terms-and-conditions-says-eu-court-in-ryanair-case) · [Flavorish changelog (translation fix)](https://www.flavorish.ai/changelog)
- Solo-business realism: [RevenueCat State of Subscription Apps 2026](https://www.revenuecat.com/state-of-subscription-apps) · [SOSA 2026 benchmarks summary](https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026/) · [Median $72/mo breakdown](https://tasu.ai/library/how-much-money-do-subscription-apps-make) · [Adapty churn data](https://adapty.io/state-of-in-app-subscriptions-report/) · [Apple 2024 Transparency Report (25% rejections)](https://www.apple.com/legal/more-resources/docs/2024-App-Store-Transparency-Report.pdf) · [Apple SDK requirements](https://developer.apple.com/news/upcoming-requirements/) · [HabitKit revenue (dev's own writeup)](https://sebastianroehl.substack.com/p/2025-the-year-that-changed-everything) · [Slopes: 9 years to $1M ARR](https://www.revenuecat.com/blog/growth/slopes-from-indie-side-hustle-to-1m-in-arr-and-an-apple-design-award/) · [CPI benchmarks (Business of Apps)](https://www.businessofapps.com/ads/cpi/research/cost-per-install/) · [Meta API shutdown (TechCrunch)](https://techcrunch.com/2024/12/06/instagram-locks-out-developers-of-third-party-consumer-apps) · [Handwriting OCR limits (OrganizEat)](https://home.organizeat.com/blog/ocr-recipe-app/)
