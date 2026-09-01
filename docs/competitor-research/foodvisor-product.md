# Foodvisor — Product, Features & Pricing

_Researched: 2026-09-01_

> **Package-name correction:** the brief specified `com.foodvisor.foodvisor`. The real Android package is **`io.foodvisor.foodvisor`** [1]. `com.foodvisor.foodvisor` does not exist on Play. Anything keyed on the wrong ID (scrapers, ASO tools) will return nothing.

---

## 1. Identity

| Field | Value | Source |
|---|---|---|
| App name (Play) | Foodvisor - AI Calorie Counter | [1] |
| Android package | `io.foodvisor.foodvisor` | [1] |
| Play developer ID | `6548442100506074701` | [1] |
| Legal entity | FOODVISOR (SAS), 46 rue Raspail, 92300 Levallois-Perret, France | [1] |
| Founded | 2015, Paris — Charles Boes (CEO), Yann Giret (Chief Science Officer), Gabriel Samain, Aurore Tran (CMO) | [7][11] |
| Public launch | Beta on App Store 2016; official iOS + Android launch **January 2018** with Premium | [7] |
| iOS store release date | 12 Feb 2016 | [6] |
| **Ownership (current)** | **Acquired by Xynergy (owner of the French diet brand "Comme J'aime") — announced Jan 2026, deal reported at €50–60M** | [8][10] |
| Funding before exit | ~$6.2M / ~€5M over 2 rounds: €1.7M seed (Kima Ventures / Xavier Niel, Bpifrance, 2018) + $4.5M Series A (Agrinnovation, Nov 2019) | [9][10] |
| Team size | 22 employees (as of 30 Jun 2026) | [9] |
| Android installs | **10M+**, 4.7★, **196K reviews** | [1] |
| iOS ratings | 4.6★ / 17K ratings (US storefront); 4.5★ / 1.6K (Norway) | [2][12] |
| Own marketing claim | "over 15 million users" | [1][2] |
| Category | **Health & Fitness** (not Food & Drink) | [1][2] |
| Play chart position | **#8 top-grossing Health & Fitness (US-locale listing); #10 top-grossing Health & Fitness (Norway)** | [1] |
| iOS chart position | #74 Health & Fitness top-free (US); #17 (Norway) | [2][12] |
| Last update | Android **26 Aug 2026**; iOS **v9.22.0, ~30 Aug 2026** | [1][2] |
| Update cadence | Roughly every 1–2 weeks. iOS shipped 9.5.0 → 9.22.0 between 23 Dec 2025 and 30 Aug 2026 (~22 releases in 8 months) | [2] |
| Release notes quality | Every single release note is the identical boilerplate: "we made some general improvements and squashed a few bugs" | [1][2] |

**Conflicting rating counts — which to trust.** Foodvisor's own homepage still says "4.6/5 on +58,000 ratings" and "4.7/5 on +99,800 ratings" [3] — stale. A French review site claims 850,000 Play reviews and 915k total [10] — inflated. **Trust the live store: 196K Play reviews, 4.7★, 10M+ installs [1].**

---

## 2. Positioning

- **Play short description (the ASO line):** "All-in-One App For Weight Loss: Diet & Macro Tracker, Nutrition Scanner, Recipes" [1]
- **iOS subtitle:** "Diet Tracker for Weight Loss" [2]
- **One-sentence pitch:** photograph your plate, the AI logs it, and a coach-style programme builds habits around the numbers.
- **Target:** weight-loss-motivated adults who find manual calorie logging too much friction. Internal study cited in the listing: average 15.83 lb lost in 3 months across 4,419 users, average BMI 34.72 — i.e. they explicitly target people with obesity [1][2].
- **Title/keyword strategy:** the app renamed itself into the keyword. It was "Foodvisor – Nutrition & Diet" in 2024 [6], now "Foodvisor - **AI Calorie Counter**". The short description crams four separate keyword clusters (weight loss, diet tracker, macro tracker, nutrition scanner, recipes).
- **Badges claimed in listing copy:** "APP STORE EDITORS' CHOICE" (iOS) / "PLAYSTORE EXCELLENCE" (Android) [1][2].
- **Recipes are a keyword, not the product.** "Recipes" appears in the ASO line and as a Premium bullet, but the recipe library is ~300 items and reviewers rate it weak (see §9).

---

## 3. Full feature inventory

| Group | Feature | Free / Premium | Notes |
|---|---|---|---|
| **Logging** | AI photo food recognition | **Premium** (per official help centre) | The signature feature. See §4 for the contradiction. |
| | Voice logging ("speak to the app") | Premium bundle w/ AI | Added ~2025 [5] |
| | Quick-add / natural-language typed meal ("type everything at once") | Free-ish | [5] |
| | Text search of food database | Free | Search quality is a top complaint [1] |
| | Barcode scan | Free (unlimited on Premium per FR sources) | Backed by Open Food Facts [7] |
| | Favourites / saved foods, meals, recipes | Yes | Flat chronological list, not editable in place [1] |
| **Nutrition tracking** | Calories, protein / carbs / fat | Free | |
| | **Fibre** | Free | Unusual — most rivals omit it [5] |
| | Vitamins, minerals, micronutrients (cholesterol, sodium, potassium, magnesium, calcium, iron) | **Premium** ("Full meal analysis") | [1][7] |
| | Custom macro split / editable goals | **Premium** | [4] |
| | Daily summary + "top and flop" foods of the day, next-day advice | **Premium** | [4][7] |
| | Colour-coded food scoring (red/orange/yellow/green) + smiley/frowny emoticons | Core UX | Noom-style. Flagged as psychologically harmful by a registered dietitian [5] |
| **Other trackers** | Water / hydration | Free | |
| | Weight | Free | **Weight only — no body measurements** (waist, hips, body fat) [5] |
| | Physical activity / calories burned | Free | |
| | Intermittent fasting | **Premium**, **iOS listing only** — absent from the Android listing | [1][2] |
| | Workout video sessions | **Premium** ("unlimited workout sessions") + separate one-off Sport Pack | Reviewers call the fitness content "lackluster" [4][5] |
| **Content** | 500+ daily micro-lessons (nutrition, psychology, motivation), 2–3 served per day | **Premium** | [4][5] |
| | Expert articles + meal plans (keto, low-carb, cutting, vegetarian, Mediterranean, detox, mass gain, gluten-free, 6-Week Challenge, Beach Body, Clean Eating) | **Premium** | [7] |
| | ~300 recipes + weekly meal-plan builder | **Premium** | [5] |
| | 28 days of menus | One-off Sport & Meal Plan bundle | [4] |
| **Gamification (2025–26 additions)** | "Seed" avatar that grows/dresses/decorates as you log | **Premium** ("Grow your seed") | [1][2] |
| | Daily quests, chests, gems, in-app shop | In app | **Cannot be turned off** — an active complaint [1] |
| | Friends: add friends, send nudges, celebrate progress | New, Aug 2026 | Announced as a "MAJOR UPDATE" App Store event [2] |
| | Community feed | New in 2026 listing copy | Historically there was **no in-app community**, only a Facebook group [5] |
| **Integrations** | Apple Health (iOS) | Yes | [2] |
| | Google Fit (Android) | Yes | [1] |
| | **Health Connect** | **[UNVERIFIED]** — the Android listing still says "Google Fit", which is deprecated | [1] |
| | Fitbit / Garmin / Polar / Strava / Whoop / Oura | **No** — repeatedly requested by reviewers | [5] |
| | Apple Watch app | Yes | [2] |
| | visionOS / Mac (Apple silicon) | Yes | [2] |
| **Platform** | Web app (desktop) | Yes — foodvisor.io account, Stripe billing | [4][5] |
| | Multi-device sync | Yes (account-based) | |
| | Offline behaviour | **[UNVERIFIED]** — photo recognition is server-side, so scanning is online-only by construction [15] | |
| | Home-screen widgets | **[UNVERIFIED]** — no widget mentioned in either listing | |
| | Data export (CSV etc.) | **[UNVERIFIED]** — no export mentioned anywhere; Play data-safety only promises deletion on request | [1] |
| **Reach** | Languages: 20 — EN, CS, DA, NL, FI, FR, DE, EL, HU, IT, JA, KO, **Norwegian Bokmål**, PL, PT, RU, zh-Hans, ES, SV, TR | [2] |
| | Regional food databases | French base from **Ciqual** (ANSES national table); packaged goods from **Open Food Facts**; a separate **US database** added ~2024 | [5][7] |
| **B2B** | **Foodvisor Vision API** — food detection + nutrition from images, sold to enterprises under commercial agreement. No public OpenAPI spec, no public pricing. Launched ~Oct 2023 | [14] |
| **Removed features** | Human dietitian chat / nutrition coaching — **used to be a Premium headline, no longer available** | [5] vs [7] |
| **Monetisation surface** | **Ads in the free tier** ("Contains ads" on Play; "No ads" is a Premium bullet) | [1] |

---

## 4. Free vs paywalled — and the free-scan contradiction

**Official position (Foodvisor Help Centre, article updated 09 Apr 2026) [4]:**

- **Free:** manual food-diary logging only.
- **Premium:** photo meal analysis, daily courses, expert articles + meal plans, hundreds of recipes, macro customisation, daily summaries.
- **Sport & Meal Plan bundle:** a **one-time purchase kept for life, no renewal** — workout video programmes + 28 days of menus.

Independent sources disagree on whether free users get any photo scans:

| Source | Claim | Date |
|---|---|---|
| Foodvisor Help Centre [4] | Photo analysis is **Premium**; free = manual logging | Apr 2026 |
| Kalivia, 21-day hands-on test [10] | Free gives "quelques scans photo par jour" (a few photo scans per day) | Apr–Aug 2026 |
| Third-party SEO blogs [13] | Variously "3/day", "zero", "a limited monthly allowance that shifts with promotions and regions" | 2026 |

**Reading:** this is not sloppy reporting, it is the product. Foodvisor's own pricing article says the offer "depends on your country or region, the platform used, and ongoing promotions" [4], and the App Store shows **ten simultaneous IAP SKUs** (§5). They are running continuous paywall and free-limit experiments. **Treat "free photo scans" as a variable A/B lever, not a fixed limit.**

**What breaks at the limit:** you fall back to typed search against a food database whose search quality is the single most-upvoted complaint on Play ("the search algorithm is AWFUL at finding items by using keywords", 32 helpful votes) [1], and which mixes verified entries with hundreds of inconsistent user-submitted duplicates [5]. So the free tier's fallback path is deliberately the worst path in the app.

**Historical drift:** in 2019 the free tier included the photo analysis, barcode scan, manual entry, stats and micronutrient breakdown [7]. Micronutrients and photo analysis have both since moved behind the paywall. The free tier has been hollowed out over ~7 years.

---

## 5. Pricing

### 5.1 US App Store — all live IAP SKUs

Observed **2026-09-01** on `apps.apple.com/us` [2]. Duration labels for the ambiguous ones come from the Adapty snapshot [6].

| SKU as listed | Price (USD) | Period | Notes |
|---|---|---|---|
| 1 month of Foodvisor | **$14.99** | monthly | cheapest monthly |
| 1 month of Foodvisor | **$29.99** | monthly | |
| 1 month of Foodvisor | **$39.99** | monthly | |
| 3 months of Foodvisor | **$59.99** | quarterly | ≈$20.00/mo |
| 3 months of Foodvisor | **$89.99** | quarterly | ≈$30.00/mo |
| Foodvisor Premium | **$23.99** | annual | ≈$2.00/mo |
| Foodvisor Premium | **$47.99** | annual | ≈$4.00/mo (in 2024 list [6]) |
| Foodvisor Premium trial | **$59.99** | annual w/ trial | **paid trial** |
| Foodvisor Premium Trial | **$71.99** | annual w/ trial | **paid trial** |
| Foodvisor Premium | **$83.99** | annual | ≈$7.00/mo — the headline annual price |
| **Premium Bundle** | **$29.99** | **one-time, for life** | Sport & Meal Plan pack, non-renewing [4] |

**Three concurrent monthly prices spanning 2.7× and five concurrent annual prices spanning 3.5×.** Which one you see depends on the cohort you land in. Foodvisor's help centre confirms it will not publish a price: "This is why we cannot provide a fixed universal price" [4].

### 5.2 Europe

| Market | Tier | Price | Observed |
|---|---|---|---|
| France (web/Stripe + store) | Monthly | **€11.99/mo** | 29 Aug 2026 [10] |
| France | 3 months | **€29.99** (≈€10.00/mo) | 29 Aug 2026 [10] |
| France | Annual | **€59.99/yr** (≈€5.00/mo) | 29 Aug 2026 [10] |
| France | Trial | 7 days free, **payment card required** | 29 Aug 2026 [10] |
| France | Promo | Annual discounted to ~€30–40 several times a year, incl. New Year sales | 29 Aug 2026 [10] |
| **Norway** | — | **[UNVERIFIED]** — Play confirms IAPs exist and "All prices include VAT", but no NOK figure is publicly listed [1]. Nordic stores bill the same tier structure in local currency. Extrapolating from the FR annual: expect roughly **NOK 650–800/yr**, unconfirmed. |

### 5.3 Price history

| When | Monthly | Annual | Source |
|---|---|---|---|
| ~2023 | $11.99 | — | [5] |
| Aug–Sep 2026 (US) | $14.99 | $83.99 | [2][5] |
| Aug 2026 (FR) | €11.99 | €59.99 | [10] |

US monthly rose ~25% ($11.99 → $14.99). Garage Gym Reviews notes the annual came *down* in effective terms to ~$6.99/mo, i.e. they widened the monthly-to-annual gap to push annual commitment [5].

### 5.4 Family plan

Family sharing is supported on both stores; Foodvisor has dedicated help articles for setting up family sharing on iOS and a family subscription on Android [4]. **No separate family price point is published** — it rides on Apple Family Sharing / Google Play family library. [UNVERIFIED] whether there is a distinct family SKU.

### 5.5 Lifetime

There is **no lifetime Premium**. Premium is subscription-only. The only perpetual purchase is the **$29.99 / €? one-time Sport & Meal Plan bundle** [4]. Note the help centre has an article titled *"I paid 'for life' but I don't have access to Premium"* [4] — users are conflating the one-off bundle with lifetime Premium and getting burned.

---

## 6. Onboarding and monetisation mechanics

- **Onboarding quiz: ~10 minutes**, ~30+ questions. Goals, body metrics, pregnancy, medical conditions, then unusually personal ones: are you a student, is money a factor in your health journey, do you have work-life balance, do friends/family/colleagues support you, what past events caused weight change, have you tried to lose weight before and how [5].
- **Guilt-priming questions.** The habits section opens with "Would you say that snacking is an issue for you?" — described by a certified nutrition coach as "vague but kind of accusatory" [5].
- **Paywall timing: at the end of the quiz, before the app.** "During registration, you can choose between the free version or a paid subscription" [4]. Kalivia's tester hit "carte bancaire requise pour démarrer l'essai 7 jours" on **day 1** [10].
- **Soft paywall, hard trial.** You can decline and use the free tier indefinitely — the free tier is permanent, not time-limited [5]. But the trial requires a card [10].
- **Paid trials.** Two of the ten US SKUs are literally named "Foodvisor Premium trial" at **$59.99 and $71.99** [2][6]. The refund policy makes the mechanic explicit: *"you pick one that you're comfortable with and see if Foodvisor is a good fit"* [4] — i.e. the user chooses how much to pay up-front for the privilege of trialling. This is a known aggressive pattern; treat it as the single most cynical thing in the product.
- **Auto-renew:** monthly by default, renews unless cancelled ≥24h before renewal (Apple terms) [2].
- **Refund friction [4]:**
  - **14-day hard window.** "no refund will be granted after that time period."
  - Cancelling ≠ refunding. "Just canceling a subscription does not automatically result in a refund, it only avoids a renewal."
  - **Renewal charges are never refundable.**
  - **Deleting your Foodvisor account does not cancel your subscription.** You must cancel separately in App Store / Play / on the website. This is the sharpest dark pattern in the stack — the natural "I'm done with this app" action leaves you still paying.
  - Refunds route to Apple/Google, so Foodvisor pushes responsibility outward.
- **Referral:** referred user gets 14 days free, then rolls into a 3-month subscription [4].
- **Retention loop:** daily quests, chests, gems, an in-app shop, and the "Seed" avatar. A July 2026 Play review: *"Daily mandatory quests, chest openings, gems, shop etc is getting very annoying. no way to turn it off! Can i just please log my food?"* [1]
- **Ads in the free tier** [1] — so the free user is monetised even before converting.
- **Complaints on record** about being charged for an unwanted Premium subscription and struggling to get refunded [5].

---

## 7. Tech / AI stack signals

- **Model:** self-supervised deep learning on user photos; the algorithm analyses colour, size, shape and gloss to identify item and quantity, and needs "several hundred photos" of a new food before it can recognise it. User corrections feed back into training [7].
- **Recognition scope:** ~20 foods at project start; **1,000+ foods by late 2017**; commonly cited as 1,200+ [7][9]. No current published figure.
- **Nutrition data sources — mostly not proprietary:**
  - **Ciqual** (ANSES French national food composition table) for recognised dishes [7]
  - **Open Food Facts** (free, open, crowdsourced) for barcode-scanned packaged goods [7]
  - A separate **US database** added ~2024 [5]
  - Plus a large mass of **user-submitted entries with inconsistent nutrition facts for the same food** [5]
- **Independent accuracy — the hard number:** in a peer-reviewed comparison of food-image-recognition platforms, Foodvisor scored **46.2% top-1 accuracy and 71.5% top-5 accuracy**; on mixed dishes it got most components into its top-5 in **70.8%** of cases [15]. That is: **it is wrong on first guess more often than it is right.**
- **Independent field test:** on 30 photographed prepared dishes Foodvisor got 24 right vs YAZIO's 18 (it wins on photo); on 30 specific French packaged products it got 25 vs YAZIO's 27 (it loses on database) [10].
- **Known blind spots:** stews, sauces, gratins, melted/covered dishes; and **any condiment or cooking fat that doesn't change appearance** — it cannot know whether the steak was seared in butter or avocado oil [5][7].
- **B2B API:** **Foodvisor Vision API** — image → food detection + calories, macros, serving estimates. Enterprise-only, commercial agreement, endpoint and auth shared privately, **no public OpenAPI spec and no public pricing** [14]. Launched ~Oct 2023.
- **Privacy / GDPR:**
  - French SAS, EU-hosted data, French GDPR regime [10].
  - Play Data Safety: may **share** Personal info, Messages + 3 others with third parties; collects Personal info, Messages + 4 others; encrypted in transit; deletion on request [1].
  - App Store privacy label: **"Data Used to Track You: Identifiers"** — i.e. cross-app/website advertising tracking. Health & Fitness data, purchase history, photos/videos and user ID are all Linked to You for analytics and for "Developer's Advertising or Marketing" [2].
  - Consent stack on the website is Didomi with **9 advertising/analytics partners** [3].
  - **The gap between "French, GDPR, privacy-respecting" positioning and an App Store label that admits cross-app ad tracking is a real, citable vulnerability.**

---

## 8. Business signals

- **Revenue (third-party estimates):**
  - Sept/Oct 2024: ~200k downloads and **$500–600k revenue** per month (Adapty, drawing on app-intelligence data) [6]
  - March 2026: ~300k downloads and **~$1M revenue** per month [9 via 13] → order of **$12M/yr gross** run-rate, before store fees. Treat as an estimate, not a filing.
  - Corroborating live signal: **#8 / #10 top-grossing Health & Fitness on Play** [1] — for a 22-person company that is a lot of money per head.
- **Exit:** acquired by **Xynergy** (French education/wellness group, owner of **Comme J'aime**) — reported Jan 2026, **€50–60M** [8][10]. This is the most important strategic fact in the file: Foodvisor now sits inside a group whose flagship brand is a commercial diet-programme business. Expect the product to be pushed toward selling programmes, and expect editorial independence pressure over 2026–27 [10].
- **Awards / editorial:**
  - App Store **Editors' Choice**, **App of the Day** (US and FR, repeatedly) [2][10]
  - Featured in Apple's **"Everyone Can Code"** editorial story [12]
  - App Awards 2016 — Best Startup App; Petit Poucet 2016 — Food Tech; Vitafoods 2016 French Innovation Corner Special Award; Graines de Boss 2017; BPI Innovation Numérique grant 2017 [7]
  - **Facebook Startup Garage** cohort 2 at Station F, 2018; met Tim Cook during his Europe visit, Oct 2018 [7]
  - Capgemini "AI, the gems of tomorrow" barometer, 2019 [7]
- **Marketing channels:** app-intelligence describes the app as "being advertised actively" [6]. Observable: a YouTube trailer embedded on the Play listing, Play "Events & offers" promo slots and App Store in-app events used as retention/marketing surfaces [1][2], aggressive ASO (app renamed to include "AI Calorie Counter"), an active Facebook group used in place of an in-app community [5], and a referral programme [4]. **Specific TikTok/Instagram influencer spend: [UNVERIFIED]** — no public breakdown found.
- **Partnerships:** the Vision API is the B2B arm; no named enterprise customers are public [14].

---

## 9. Gaps and weaknesses — what MyReciBook can beat them on

1. **They are not a recipe app and their recipe layer is visibly weak.** ~300 recipes, Premium-gated, and reviewers are blunt: *"a bowl of fruit is not a recipe"* [1]; *"Why would I pay extra to get what I can get on Pinterest for free"*; *"Articles & recipes poorly organized"* [2][5]. Recipes are ASO keyword filler for them. It's our entire product.
2. **No pantry inventory at all.** Nothing in either store listing, the help centre or any hands-on review mentions tracking what food you own. This is a whole category they don't compete in.
3. **Grocery lists are at best a byproduct of the Premium meal planner** — one review round-up lists "meal planning and grocery shopping" as a strength [5], but no source describes a standalone, editable, aisle-organised list. There is no pantry-aware list.
4. **You cannot edit or maintain your own food data.** Favourites are "just a flat list", chronological, not editable; to change one you must add it as a meal, edit, re-save, then delete the old one [1]. And you cannot fix a wrong database entry: *"there should be a way to edit previous entries if they were done by someone incorrectly, like a Wikipedia page"* [1]. **A recipe-first app where the user owns and edits their own data wins here outright.**
5. **Search is the app's weakest surface** and it's the fallback path for every free user [1].
6. **The subscription is unbounded.** At $83.99/yr US (€59.99 FR), a user who stays three years pays **$252 / €180**. Our one-time ~$25 is 30% of a single US year. At the mid monthly SKU ($29.99) they exceed our lifetime price in **under one month**.
7. **Opaque, experiment-driven pricing.** Ten concurrent SKUs, three different monthly prices, an explicit refusal to publish a price [4], and paid trials at $59.99/$71.99 [2]. A single published, honest, one-time price is a direct counter-position — and it is a *trust* message, not just a cheaper one.
8. **Refund and cancellation traps.** 14-day hard limit, no refund on renewals, and **deleting your account does not cancel your subscription** [4]. Nothing to defend there.
9. **Diet-culture and disordered-eating exposure.** Red/orange/yellow/green food scoring plus frowning-face emoticons on "bad" foods, which a registered dietitian calls actively harmful [5]; App Store reviews call it "a fine line to obsessive diet culture" and criticise daily weigh-in prompts [2]. **A recipe-and-pantry app that never scores a food as bad has a clean, defensible ethical position** — and it's genuinely better product, not just marketing.
10. **Forced gamification with no off switch.** Quests, chests, gems, a shop, a growing avatar — and a user asking *"Can i just please log my food?"* with no way to disable it [1].
11. **Wearable coverage is thin.** Apple Health and Google Fit only. No Fitbit, Garmin, Polar, Strava, Whoop, Oura — repeatedly requested [5]. The Android listing still names **Google Fit**, not Health Connect [1] — if that's literal, they are behind on Android's current health platform.
12. **The AI is wrong more often than it's right.** 46.2% top-1 accuracy [15]. It fails exactly on home-cooked food: stews, sauces, gratins, anything with a cooking fat [5][7][10]. **Their weakest domain is home cooking. Home cooking is our home turf.**
13. **No body measurements, weight only** [5].
14. **No data export found** [1] — lock-in by omission.
15. **Ads in the free tier of a health app** [1].
16. **Acquisition risk to their reputation.** Being owned by the group behind Comme J'aime is already being written up as an editorial-independence concern [10]. "Independent, not owned by a diet company" is available to us.
17. **Zero release-note transparency** — 22 consecutive releases with identical boilerplate [1][2]. Real changelogs are a cheap trust win.
18. **Human coaching was removed.** It used to be a Premium headline [7]; it's gone [5]. Users who bought for it were downgraded mid-subscription.

---

## 10. What we should steal — and what to avoid

### Steal

1. **Multi-modal capture with a fallback ladder.** Photo → voice → typed natural language → barcode → favourites [1]. The *ladder* is the real insight: never leave the user with only one way in. For us: photo/scan a recipe, paste a URL, dictate, type, or pick from pantry.
2. **"Log a meal in 5 seconds."** A concrete, testable speed promise as the top listing line [1][2]. Ours should be equally concrete ("your whole week planned in one screen").
3. **Save foods, recipes and meals as favourites** — but do it properly: editable, searchable, foldered. Their flat chronological list is the complaint [1]; fixing it is a stated user request we can answer on day one.
4. **Track fibre.** They do, most rivals don't, and reviewers specifically praise it [5]. Cheap to add, differentiating.
5. **Onboarding that asks about context, not just body metrics** — student status, budget constraints, work-life balance, whether people around you support you [5]. This genuinely personalises. Keep the questions, drop the guilt framing.
6. **Habit layering — one habit at a time.** Explicitly praised by a nutrition coach as the right pedagogy [5]. And their "you're not ready to exercise? no problem, come back later" framing is good, humane design.
7. **Open Food Facts for barcode data** [7]. It's free, open, EU-run, has strong European coverage including Nordics, and it removes a whole licensing cost. If Foodvisor at 10M installs runs on it, so can we.
8. **Ciqual-style authoritative national composition tables** for base ingredients rather than a crowdsourced soup [7]. Their user-generated duplicate mess is a named complaint [5]; a curated base is a quality moat for a paid-once app.
9. **In-store event slots.** They actively use Play "Events & offers" and App Store in-app events as free marketing surfaces [1][2]. Almost no small dev uses these.
10. **20 languages, incl. Norwegian Bokmål** [2]. Localisation is how a European app gets to 10M installs.
11. **App renamed into its category keyword.** "Foodvisor - AI Calorie Counter" [1]. Blunt but it works.

### Avoid

1. **Paid trials.** $59.99 and $71.99 "trial" SKUs [2] — corrosive to trust and irrelevant to a one-time-purchase model anyway.
2. **Refusing to publish a price.** [4] Publish ours, everywhere, permanently. It is our single biggest differentiator; hiding it would be self-harm.
3. **Hollowing out the free tier over time.** Micronutrients and photo analysis both migrated behind the paywall [7 vs 4]. With a one-time purchase we can promise the opposite and mean it.
4. **Deleting the account not cancelling billing** [4]. Never.
5. **Colour-coding foods good/bad with frowny faces** [5]. Show the numbers, don't judge the food.
6. **Un-disableable gamification.** Quests, chests, gems, shop [1]. If we ever add streaks, ship the off switch in the same release.
7. **Removing paid features mid-subscription** (human coaching) [5][7].
8. **Ads in a health app's free tier** [1].
9. **Boilerplate release notes** [1][2].
10. **Overpromising the AI.** They ship 46% top-1 accuracy [15] behind "AI identifies everything instantly" [1] and reviewers call the food-photo function "useless" [5]. If we use AI, state the confidence and make correction one tap.
11. **Ten concurrent price SKUs.** One price. One page. Done.

---

## Sources

1. Google Play listing — Foodvisor - AI Calorie Counter (`io.foodvisor.foodvisor`), US and Norway storefronts, observed 2026-09-01: https://play.google.com/store/apps/details?id=io.foodvisor.foodvisor&hl=en_US
2. Apple App Store listing (US) — Foodvisor - AI Calorie Counter, incl. full in-app purchase price list, version history and privacy labels, observed 2026-09-01: https://apps.apple.com/us/app/foodvisor-ai-calorie-counter/id1064020872
3. Foodvisor official website: https://www.foodvisor.io/en
4. Foodvisor Help Centre (Zendesk) — "Is Foodvisor free?" (upd. 2026-04-09), "How much does the Foodvisor subscription cost?" (upd. 2026-04-08), "Refund Policy" (upd. 2026-04-14): https://foodvisor.zendesk.com/hc/en-us/articles/360013600800-Is-Foodvisor-free · https://foodvisor.zendesk.com/hc/en-us/articles/26650824663580-How-much-does-the-Foodvisor-subscription-cost · https://foodvisor.zendesk.com/hc/en-us/articles/7294486891932-Refund-Policy
5. Garage Gym Reviews — "Foodvisor Review (2026): My Firsthand Experience" (certified nutrition coach, 1-month test): https://www.garagegymreviews.com/foodvisor-review
6. Adapty Paywall Library — Foodvisor (IAP SKU list, revenue/download estimates, store metadata snapshot Sept 2024): https://adapty.io/paywall-library/foodvisor/
7. Wikipédia (fr) — Foodvisor (founders, history, Ciqual + Open Food Facts data sources, awards, free vs premium as of ~2019): https://fr.wikipedia.org/wiki/Foodvisor
8. CFNEWS — "Xynergy avale une application de suivi alimentaire" (acquisition of Foodvisor by Xynergy): https://www.cfnews.net/L-actualite/M-A-Corporate/Operations/Majoritaire/Xynergy-avale-une-application-de-suivi-alimentaire-553686
9. Tracxn — Foodvisor company profile (funding rounds, investors, employee count 22 as of 2026-06-30): https://tracxn.com/d/companies/foodvisor/__TrHrEdghLfy6XL02BOeaWJOvg4dicn3SzSp4JlLU59E
10. Kalivia — "Avis Foodvisor 2026 : notre test après 21 jours" (French pricing grid, 21-day hands-on test, Xynergy €50–60M, head-to-head vs YAZIO), upd. 2026-08-29: https://kalivia.fr/applications/nutrition/foodvisor/
11. Crunchbase — Foodvisor: https://www.crunchbase.com/organization/foodvisor
12. Apple App Store listing (Norway storefront), observed 2026-09-01: https://apps.apple.com/no/app/foodvisor-ai-calorie-counter/id1064020872
13. Third-party pricing/free-tier write-ups (conflicting free-scan claims): https://nutriscan.app/blog/posts/foodvisor-pricing-2026-free-vs-premium-coaching-a7ea4512a0 · https://nutrola.app/en/blog/foodvisor-free-vs-premium-what-do-you-actually-get · https://www.bentobunny.app/guides/is-foodvisor-free
14. API Evangelist — Foodvisor Vision API index (`apis.yml`): https://raw.githubusercontent.com/api-evangelist/foodvisor/refs/heads/main/apis.yml · https://github.com/api-evangelist/foodvisor
15. "Use of Different Food Image Recognition Platforms in Dietary Assessment: Comparison Study" (peer-reviewed; Foodvisor 46.2% top-1 / 71.5% top-5 accuracy): https://pmc.ncbi.nlm.nih.gov/articles/PMC7752530/
16. TechCrunch — "Foodvisor raises $4.5 million to track what you eat using AI" (Nov 2019): https://techcrunch.com/2019/11/28/foodvisor-raises-4-5-million-to-track-what-you-eat-using-ai
17. DigitalFoodLab — "Foodvisor raises €4m for its food image recognition app": https://digitalfoodlab.com/foodvisor-raises-e4m-for-its-food-image-recognition-app/
