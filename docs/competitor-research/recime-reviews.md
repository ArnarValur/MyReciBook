# ReciMe — Reviews, Complaints & Unmet Needs

_Researched: 2026-09-01_

Scope: user sentiment only. Features and pricing were covered by a separate agent and are referenced here only where users complain about them.

Method note: Play's public review endpoint (`UsvDTd` batchexecute, `hl=en&gl=US`) was queried directly and returned its **full servable text-review set — 4,754 reviews spanning 2023-05-02 to 2026-08-31**. All Play percentages below are computed over that corpus, not estimated. iOS reviews came from Apple's per-storefront RSS feeds across 16 countries (256 text reviews; the US feed returned empty, so iOS text is UK/AU/NZ/DE/NO-weighted). Everything else is marked `[SECONDARY]`.

---

## 1. Rating distribution and trend

### Headline numbers (observed 2026-09-01)

| Store | Displayed rating | Rating count | Notes |
|---|---|---|---|
| Google Play (`com.recime.app`) | **4.7★** | 97.2K header / 96.2K in ratings panel | 1M+ downloads; "#1 top grossing food & drink"; app v4.1.2, updated 2026-08-27 |
| App Store US (`id1593779280`) | **4.79★** | 282,997 | v6.1.5, released 2026-08-26; first released 2021-11-12 |

Per-storefront iOS rating counts and averages (Apple lookup API, 2026-09-01):

| US | CA | AU | GB | DE | NZ | FR | NL | ES | IE | SE | NO | DK | IT | FI | IS |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 283.0K / 4.79 | 21.5K / 4.69 | 19.0K / 4.75 | 18.3K / 4.74 | 4.9K / 4.57 | 2.9K / 4.70 | 1.9K / 4.65 | 711 / 4.61 | 684 / 4.69 | 544 / 4.72 | 335 / 4.63 | 292 / 4.64 | 256 / 4.60 | 195 / 4.41 | 103 / 4.48 | 70 / 4.59 |

Two things fall out immediately: iOS carries roughly **3.6× the rated user base of Android** (~353K iOS ratings across these 16 storefronts vs 97K on Play), and **non-English storefronts rate consistently lower** (IT 4.41, FI 4.48, DE 4.57 vs US 4.79).

### The gap between the star badge and the written record

This is the single most important number in this document.

**Play text reviews, full corpus (n=4,754): average 3.44★.**

| Stars | Count | Share |
|---|---|---|
| 5★ | 2,368 | 49.8% |
| 4★ | 406 | 8.5% |
| 3★ | 310 | 6.5% |
| 2★ | 312 | 6.6% |
| **1★** | **1,358** | **28.6%** |

The displayed 4.7★ aggregates *all* star taps including the very large majority that carry no text, and Google recency-weights it. The people who bothered to write something average **3.44★, with more than one in four giving one star**. iOS text reviews show the same shape: n=256, average **3.31★**, 30% one-star. The badge and the testimony disagree by more than a full star on both platforms. Section 8 explains the mechanism.

### Monthly trend (Play text reviews)

| Month | n | Avg | 1★ share | 5★ share |
|---|---|---|---|---|
| 2025-07 | 114 | 2.84 | 47% | 38% |
| 2025-08 | 489 | 3.22 | 33% | 44% |
| 2025-09 | 535 | 3.45 | 28% | 48% |
| 2025-10 | 566 | 3.53 | 26% | 52% |
| 2025-11 | 473 | 3.12 | 36% | 43% |
| 2025-12 | 277 | 3.18 | 32% | 42% |
| 2026-01 | 249 | 3.61 | 25% | 53% |
| 2026-02 | 199 | 3.73 | 20% | 54% |
| 2026-03 | 167 | 3.91 | 18% | 60% |
| 2026-04 | 260 | 3.52 | 29% | 52% |
| 2026-05 | 303 | 3.83 | 21% | 61% |
| 2026-06 | 321 | **3.88** | 19% | 60% |
| 2026-07 | 311 | 3.42 | 28% | 50% |
| 2026-08 | 236 | **3.31** | 31% | 46% |

Recent reviews run **materially worse than the app's own recent peak**: from 3.88 in June 2026 to 3.31 in August 2026, with the 1★ share going 19% → 31% in two months. That is the sharpest two-month deterioration in the series apart from the launch period.

### What shipped around the turn — two events, both datable

**(a) The paywall tightening, between ~2026-05-21 and 2026-08-09.** ReciMe's own help article "Is there a free version of the app?" (last updated 2026-08-09) lists as **premium**: unlimited imports, nutrition calculator, **measurement converter**, **export/print recipes**, **step-by-step guided cooking**. A third-party review updated **2026-05-21** describes measurement converters, cook mode and the ingredient scaler as free utilities available "even if you stick with the free version" `[SECONDARY]`. So the converter, print/export and guided cook mode crossed from free to paid inside that window. The exact ship date is `[UNVERIFIED]` — no Wayback snapshot of the help page exists — but the bracket is evidenced from a first-party page on one side and a dated review on the other, and it lands exactly on the June→August slide.
Corroborating detail: the **Play store listing still advertises** "Convert Measurements", "Cook with Ease… Follow recipes step-by-step" and "Adjust Ingredients" in the plain feature list with no premium marking, while the help centre calls three of those premium. That mismatch is verifiable from two first-party pages today.

**(b) A live, unfixed Instagram share-sheet regression, from ~2026-07-20.** Five independent Play reviewers between 2026-07-20 and 2026-08-26 report ReciMe vanishing from Instagram's share menu — the app's single most-marketed entry point. "Recime is no longer showing up as an option" (3★, 2026-08-01); "Now I can't share my IG recipes so I can save" (1★, 2026-07-30); "The share option doesn't allow me to import recipes from Instagram… anymore" (2★, 2026-08-26). One reviewer downgraded from 5★ to 3★ over it (2026-08-10). Same window: a hard import error for paying users — "Everything I put in says, 'Oh no, something went wrong.'" (1★, 2026-07-18).

Sources: https://play.google.com/store/apps/details?id=com.recime.app · https://recime.app/help/en/articles/11596201-is-there-a-free-version-of-the-app · https://itunes.apple.com/lookup?id=1593779280

---

## 2. What people love — ranked

Computed over the 2,774 Play reviews rated 4★ or 5★.

**1. It saves time and it is genuinely easy (18.6% of positive reviews).** This is the dominant praise theme by a wide margin, and it is about friction, not features.
- "so easy to search, the best" — 5★, Play, 2026-08-30
- "very easy to use. great app so far" — 5★, Play, 2026-08-24
- "the app you didn't know you needed until you used it" — 5★, Play, 2025-12

**2. Everything in one place; the end of scattered screenshots and open tabs (13.0%).**
- "I can easily organise all my open tabs and printed pieces of paper" — 5★, Play, 2025-10
- "I no longer have to doom scroll to find recipes I've saved" — 5★, Play, 2025-11
- "my own recipe collection, and so easy to add, from anywhere" — 5★, Play, 2026-04

**3. Social-video import as the core magic trick (4.7%).** When it works, this is what converts people.
- "GAME CHANGER. I'm literally obsessed with this app" — 4★, Play, 2025-08 (↑120)
- "it interprets both the audio and captioned text in posts" — 5★, Play, 2026-08-23
- "I love that I can save all the videos I see while doomscrolling" — 4★, Play, 2026-05

**4. Killing the food-blog life story.** Small in raw count (0.6% use those words) but disproportionately the thing people *evangelise* about — it dominated both OzBargain threads.
- "Recipes without the ads on the websites" — 5★, Play, 2025-08-22
- "If you love to cook and hate to scroll through endless saved recipes" — 5★, Play, 2025-07
- "ReciMe does such a good job of cutting all that out" — OzBargain, 2024-01-22

**5. OCR of handwritten and printed family recipes (0.6%, but the highest emotional weight in the entire corpus).**
- "taken my entire collection of handwritten and printed recipes and imported those too" — 4★, Play, 2025-11
- "Now I have my late Oma's delicious recipes digitally" — 4★, Play, 2025-11
- "The import from OCR and webpage functions are genius" — OzBargain, 2024-01-23

**6. Grocery list, aisle sorting and the meal planner (2.0% / 1.2%).**
- "The meal plan option is so cool too. So easy to use!" — 5★, Play, 2026-08-22
- "prepare the grocery list for each meal, right from the recipe" — 5★, Play, 2026-07

**7. Import accuracy, where it lands (1.0%).**
- "The most accurate imported information as well" — 4★, Play, 2025-10 (↑27)
- "Honestly, I'm impressed with the accuracy of this app" — 5★, Play, 2025-09
- "it also understands Norwegian!" — 5★, App Store NO

**8. Cross-device sync, including iOS→Android migration.**
- "once I signed in everything transitioned" — 5★, Play, 2026-05 (↑36)

Note the shape of this list: **praise concentrates on capture and organisation, not on cooking, nutrition or planning.** Nutrition draws praise in 0.5% of positive reviews and cook mode in 0.2%. Their users do not love ReciMe for the things it now charges for.

---

## 3. What people hate — ranked

Computed over the 1,670 Play reviews rated 1★ or 2★. Percentages are share of that negative corpus.

**1. Subscription as a category (20.2%) — the largest complaint by far, and it is refusal, not price-shopping.** A fifth of all negative reviews simply object to renting a recipe box.
- "I hate when apps bury the lead" — 2★, Play, 2025-08-20 (↑125)
- "another subscription another 1 s[tar]" — 1★, Play, 2026-08-24
- "I'm so sick and tired of these apps that require a subscription" — 1★, Play, 2025-07 (↑18)

**2. "It isn't actually free" / paywall shock (16.0%).** Users arrive from an ad promising a free recipe saver and meet a wall.
- "it's supposed to be free. but it's just free for 7 days?" — 1★, Play, 2025-07-27 (↑30)
- "all the ads say its free but conveniently leave out the unlimited part is paywalled" — 1★, Play, 2026-08-23
- "no free tier, misleading" — 2★, App Store DE

**3. Price level (14.6%).** Price-testing is visible in the corpus: reviewers quote **$59.99, $64.99, $65, $80, $40, $39.99** and "$5/mo" across the period. The anger clusters on the annual figure.
- "you're kidding with the price, right?" — 2★, Play, 2025-09-02 (↑123)
- "the yearly fee is way too steep" — 4★, Play, 2025-09-25 (↑1,454 — the most-helpful review on the listing)
- "It should cost like 8$ one time total." — 1★, Play, 2025-07-28 (↑58)

**4. Trial trap and forced card entry (11.9%).** The UK storefront is dense with a specific complaint: you cannot reach the free tier at all without first starting a card-backed trial.
- "I can't use app without signing up for the 7 day trial" — 1★, App Store GB
- "Didn't even get to use the free version" — 1★, App Store GB
- "it wouldn't tell me the subscription cost until I agreed to the 7 day trial" — 1★, Play, 2026-08-03

**5. Import failures (7.2%) — and note this is failure to import at all, distinct from inaccuracy.**
- "4 recipies in... and it stops importing. First the page was blank" — 1★, Play, 2025-10-15 (↑61)
- "I have tried to import dozens of recipes and none of them import" — 1★, App Store GB
- "it worked for the 4–5 times, but then failed every attempt after" — 1★, Play, 2026-02

**6. Ads and misleading advertising (7.1%).** Two separate grievances share the word: in-app ads on a paid product, and social ads that oversell.
- "the ads said it imports your saved recipes and categorizes them automatically" — 3★, Play, 2025-08 (↑71)
- "the ad that advertised how cool it was failed to tell me I was going to have to pay" — 1★, Play, 2025-07 (↑33)

**7. Bugs, crashes and load failures (8.6%).** Sharply concentrated around two redesigns (2025-11/12 and 2026-02/04) and the July 2026 regression.
- "since the update it just brings up a black screen" — 1★, Play, 2025-12
- "the update visually ruined everything that was great" — 2★, Play, 2026-02
- "I've been able to load aprox 5 recipes...in 5 months of trying" — 1★, Play, 2026-01

**8. Login and sync problems (9.3%).**
- "the app keeps logging me out" — 2★, Play, 2025-11 (↑27)
- "clunky app with irritating login everytime you open it" — 1★, Play, 2025-11

**9. Photo/OCR import quality (8.7%).** The feature that draws the most love also draws heavy criticism when it misfires.
- "It seems to struggle when the ingredients from recipe books are in 2 columns" — 4★, Play, 2025-12
- "uploading pictures of recipes also requires a lot of manual revision" — 3★, Play, 2026-08-13
- "import from a screenshot is buggy" — 5★, Play, 2026-08

**10. Billing, charges and refunds (6.6%), cancellation trouble (3.7%).** ReciMe's terms state all sales are final `[SECONDARY]`.
- "the cancelation had not gone through" — 4★, Play, 2025-09-25 (↑1,454)
- "As per 'refund policy', there are no refunds." — 1★, Play, 2025-10-02 (↑34)
- "I was charged without my knowledge" — 1★, Play, 2026-07 (↑13)
- A Black Friday promo grievance: a user reports subscribing under an in-app "100% off / $0 for the first year" banner and being "immediately charged" — 1★, Play, 2025-12-16 (↑41)

**11. Search, sorting and organisation (5.8%).** Consistently the top *constructive* complaint from people who otherwise love the app.
- "without a workable search, it is simply not as usable as I would like" — 3★, Play, 2026-04
- "the search function within the cookbooks does not [work]" — 4★, Play, 2026-04

**12. Guided cook mode / unit conversion behind the paywall (5.9%).**
- "Ridiculous to charge for conversions" — 1★, App Store GB
- "when converting measurements to metric it shows gra[ms wrong]" — 3★, Play, 2025-11

**13. Data loss and destructive bugs (4.1%).**
- "instead of moving the recipes it just deleted them" — 2★, Play, 2025-10
- "kept duplicating recipes into cookbooks I didnt have selected" — 1★, Play, 2025-10
- "still freezing and failing to save my edits to a recipe" — 1★, Play, 2025-11-22 (↑81)

**14. The free-tier limit itself (4.9%).** Worth noting the limit has *moved repeatedly* — reviewers cite 4, 5, 6, 8 and 10 recipes at different dates, before the current 5-per-week rule. That churn is itself a complaint driver: "app now says I reached my limit. don't we still get 5 per week? did the app change it's free version?" (1★, 2026-07-29).

**15. Import accuracy — wrong quantities, dropped steps (2.8%).** Lower-frequency than the money complaints but higher-severity, because it hits paying users.
- "Completely missed the cooking time and temperature" — 2★, Play, 2025-07-20 (↑53)
- "practically every recipe that was saved missed off half the ingredients list OR half of the method" — 2★, App Store GB
- "so far off in terms of calories etc it was laughable" — 1★, Play, 2025-07
- "calculations of calories and serving sizes are also prone to error" — 3★, Play, 2026-08-13
- Sectioned recipes specifically break it: a GB reviewer notes failure "if the recipe has sections such as a sauce". Sites named as failing: Pinterest (repeatedly), SBS Food, everydaygourmet.com.au, sallysbakingaddiction.com (unit parsing + raw `&amp;` entities), and Instagram posts where the recipe sits **in the comments rather than the caption**.

**16. Support responsiveness (2.2%).**
- "no one has replied to any emails. Avoid. It's a scam" — 1★, App Store GB
- "Many email[s]" unanswered — 1★, Play, 2025-11
- "emails being ignored. Really bold when it's an app that had a sub fee" — 3★, Play, 2026-04
- Counter-evidence, reported evenhandedly: a 4★ Play reviewer (2026-06) edited their review to "they got in touch and now all sorted", and a German 1★ notes "Support ist bemüht" (support is making an effort). Support is inconsistent, not uniformly dead.

**17. Offline access (0.7%) — small but absolute.**
- "i need internet to look at my recipes? yea no" — 1★, Play, 2026-05

---

## 4. Deal-breakers — the exact churn moments

Ranked by how often the corpus shows a user leaving at that point.

1. **The onboarding wall.** Questionnaire → rating prompt → paywall, before any value is delivered. "they making you go through the whole 'what specifications do you want' wasting your time, before telling you it needs a subscription" (1★, 2026-04, ↑5). Users uninstall inside two minutes.
2. **Trial-required-to-see-anything.** Especially UK/DE. "Installed but deleted straight away because you can't access the free app" (2★, App Store GB).
3. **Hitting the import limit mid-migration.** The worst possible moment — the user has committed effort. "started out great… then i hit the import limit" (2★, 2025-08-16, ↑66).
4. **Paying, then the app breaks.** The second-most-helpful review on the listing (5★→complaint, ↑440, 2025-09) is exactly this: "Once you processed the annual fee, I can no longer successfully save". Also "Since being impressed and then paying for the app it cannot transfer a single recipe" (1★, App Store GB).
5. **Trial auto-charge plus no refund.** The single most-helpful review on the listing (↑1,454).
6. **Renewal decision point.** Users who liked it decline to re-up at $40–60. "I found another app that is [cheaper]" (2★, 2025-09-02, ↑123).
7. **A redesign breaking a working install.** 2025-12, 2026-02 and 2026-04 all produced "used to work, now black screen / crashes / slow" clusters.
8. **The July 2026 Instagram share-sheet break** — currently converting existing 5★ users into 1–3★ reviewers.

**Where they go.** Named destinations, in rough order of frequency: **Paprika** (by far the most-named, and always for its one-time price — "I would much rather use Paprika 3… which has a lifetime premium", 2★, 2025-07, ↑14), **Mela** (named for not collecting data and allowing export), **Crouton**, **Samsung Food / Whisk**, **Cookmate**, **Pestle**, **Mealie** (self-hosted), **RecipeBox**, **Plan to Eat**, plus the recurring non-app fallbacks: **Notes app, Google Docs, phone notepad, browser bookmarks, a YouTube playlist, and ChatGPT**. That last cluster matters — a meaningful share of churned users conclude no app is worth paying for, which is a market ReciMe has actively soured and a one-time purchase can win back.

---

## 5. Feature requests — exhaustive

Everything asked for, across Play, App Store and the two OzBargain threads (where the co-founder solicited feedback directly and logged requests publicly). Grouped, not ranked within groups.

### Search, sorting, organisation — the loudest constructive cluster
- **Search by ingredient**, not just title — the single most-requested feature; the #2 most-helpful positive review is about it. "search the recipes by ingredient or key word instead of just the recipe title" (4★, ↑120)
- Search *inside* recipe bodies — "I want to be able to search 'rice paper' and find all recipes wi[th it]" (3★, 2026-04)
- Search within a cookbook (reported broken, 4★, 2026-04)
- **Sort alphabetically, and by newest/oldest added** — "I really want the ability to view recipes alphabetically and by newest to oldest" (4★, 2026-02, ↑84)
- Filter by ingredient for meal planning
- **User-defined tags** — "add tags to recipes so that I can filter by ingredient type" (4★, 2025-07)
- Nested/sub-cookbooks and folders
- Recently-viewed / history
- Favourites and pinning
- Duplicate detection ("already saved this")
- Fix mis-tagged diet labels, and a report mechanism that lets you say *why* — "If a recipe is tagged 'gluten free' or 'vegan' but it isn't" (OzBargain, 2024-01-22)

### Import
- **Bulk / batch import** — repeatedly, and it is a hard blocker for migrators. "until you can bulk upload recipes, it would be useless for me. It would take hours" (2★, 2026-08-29); "importing the recipes one at a time… takes WAY too long" (3★, 2026-07)
- **Direct import from Paprika** and other apps (asked twice on OzBargain; founder confirmed no integration exists)
- **PDF import** (asked twice on OzBargain; "To import existing pdfs would make it a game changer for me")
- Import from the phone's own photo library / saved images without screenshotting
- Import from **Apple News**
- Import from a **notepad / Notes app** — a user churned specifically over this (1★, 2025-10)
- Paste a raw block of ingredients as text (4★, 2025-07)
- Handle **multi-column cookbook pages** (4★, 2025-12)
- Handle recipes where the ingredients are **in the Instagram comments, not the caption** (5★, 2025-12, ↑29)
- Restore the old fallback: when import fails, **save the source video/link anyway** instead of forcing screenshots — "liked it better when, if it wasn't able to import the recipe, it would just save the link" (1★, 2025-12, ↑16)
- **Keep a link back to the original post/source** on the saved recipe (3★, 2026-05; also 4★, 2026-06)
- Site coverage requests: Pinterest (most-cited failure), SBS Food, everydaygourmet.com.au

### Grocery list
- **Merge duplicate ingredients across recipes** — "instead of 1/2 an onion 4 times call it 2 onions" (4★, 2026-06); also raised on OzBargain in 2023 with the harder version: **sum across mixed units**, "what 1 cup and 20ml of soy sauce adds up to"
- Add arbitrary non-recipe items to the list (4★, 2026-06)
- **Add a whole cookbook / multi-select recipes to the list at once** rather than one at a time (4★, 2026-07)
- **Export / copy the grocery list out** to another app — "I have to go back n forth between 2 lists" (3★, 2026-06); "no option to export the shopping list" (3★, 2025-07, ↑13)
- Ingredient **autocomplete** when typing on the grocery page — explicitly requested by a non-native English speaker (OzBargain, 2023-09)
- Customisable aisle categories `[SECONDARY]`
- Shared/collaborative live list for a household
- Siri / Reminders integration ("Hey Siri, add rice to Grocery list") — OzBargain, 2023-09

### Meal planning
- **Link the meal plan to the grocery list** so swapping a meal updates the list `[SECONDARY]` — currently they are separate
- Build a meal plan directly from a cookbook (3★, 2026-06)
- **Meal-planner home-screen widget** (5★, 2026-06)
- Repeat / copy a day or week
- Pantry & inventory feature — "Consider adding a pantry feature (so one can tell if they have ingredients while meal planning)" (4★, 2026-04); also cited as the thing Paprika has and ReciMe does not, by the founder herself

### Recipe page and cooking
- **Save personal notes and a personal rating that persists** — currently the in-recipe rating resets when you close it (4★, 2025-09, ↑109 and 4★, 2025-09, ↑23); "unable to rate the recipes and save my notes on how to improve them" (4★, 2026-06)
- **Type an exact serving number** instead of tapping increment (5★, 2025-11, ↑104)
- State **what a serving actually is** — "I wish it would figure out what exactly a serving is" (5★, 2025-08, ↑11)
- **Built-in timers** and Live Activities (OzBargain, 2023-09; founder said timers were coming)
- **Apple Watch app** (OzBargain, and 3★ Play 2025-07 ↑13)
- **Oven temperature conversion** inside method steps (OzBargain, 2024-01)
- Estimated total time to cook a recipe (5★, App Store NO)
- Multiple photos per recipe
- Ingredient density data for accurate volume↔weight (1★, 2026-08)
- A real nutrition **ingredient database** so the calculator doesn't need manual entry (1★, 2026-08)

### Platform, sync, access
- **Web / desktop / browser version** — asked repeatedly; a user explicitly said they would not switch from Paprika without it (OzBargain, 2024-01). Founder: "in our backlog"
- **Offline access** to already-saved recipes (1★, 2026-05)
- **iPad landscape mode** (OzBargain, 2024-01)
- Tablet support on Android (2★, 2023-09)
- Themed app icon on Android (2★, 2023-09)
- **Print / PDF export on Android** (4★, 2025-10, ↑27)
- Backup / export my own data
- Better Android back-gesture handling — "swiping back should not exit the recipe without saving, deleting everything" (4★, 2025-07)

### Social and sharing
- Shared cookbooks with a partner, both able to add/edit — asked in *both* OzBargain threads and still a complaint in 2026: "the sharing functionality where I give him th[e recipe]" is "not ideal" (3★, 2026-08-22)
- **Follow friends and browse their cookbooks** (4★, App Store NO)
- Private share links for individual recipes
- Make uploaded recipes **private by default** (OzBargain, 2024-01)

### Pricing model — asked for as a feature
- **Lifetime / one-time purchase** — "I wish there was a lifetime premium option" (2★, 2025-07, ↑14); "this is a yearly and not 1 time purchase" (5★, 2025-12); "It should cost like 8$ one time total" (1★, 2025-07, ↑58)
- **A monthly option** — at several points there was annual-only. "it does NOT give the option to pay monthly. I was willing to pay it monthly" (3★, 2025-11, ↑20); repeated 4★, 2026-03
- A **6-month** tier (5★, 2025-09, ↑11)
- An **ad-supported free tier instead of a hard paywall** — "PLEASE HAVE IT MADE SO THAT WE CAN AT LEAST HAVE ADS INSTEAD OF FORCING US TO PAY" (1★, 2026-04, ↑9)
- A genuine free plan — "Needs a free plan in this economy, not just two paid plans and a week's free trial" (3★, 2025-08)
- Trial without a card

### Accessibility
- A disabled user on a fixed income explicitly needed **print** and could not afford the subscription (1★, 2025-10, ↑2). Print is now premium.
- Larger text / display options

---

## 6. Android users specifically

**Verdict: Android is structurally second-class, and ReciMe has never really hidden it.**

The evidence, in order of strength:

1. **The Play store listing itself says the app syncs to "iOS and iPad."** The Android listing's feature list reads verbatim: *"Access Across Multiple Devices – iOS and iPad."* It is a copy-paste of the iOS description onto the Play Store, still live on 2026-09-01. Android is not mentioned in ReciMe's own Android marketing copy.
2. **Version skew.** Android is on **v4.1.2**; iOS is on **v6.1.5**. Two major versions behind.
3. **Android launched late and broken.** The Play app existed from 2023 as a stub — the co-founder wrote publicly in Sept 2023: *"Android is just a few versions behind and doesn't have subscription and some of the iOS features"* and *"Importing is coming for Android"*. Full Android with import arrived ~July 2025, and the most-helpful Android review describes it: *"On the first day of Android release literally nothing worked"* (5★, ↑116, 2025-07). July 2025 is the 2.84★ month in the trend table.
4. **The free lifetime giveaways were iOS-only, twice.** Asked directly whether Android would get it, the co-founder replied *"unfortunately not for android! sorry!"* (OzBargain, 2024-01-22). A second Android user asked the same question in 2023 and got no answer.
5. **Named Android-only feature gaps** from reviewers: no print/PDF export — *"lowered to 4 stars as you can't export to pdf or print in Android"* (4★, ↑27, 2025-10); no meal plan at the time of writing — *"there is no meal plan option for androids"* while being charged $80 (2★, ↑11, 2025-08); no tablet support and no themed icon (2★, 2023-09); can't edit saved recipes (2★, 2026-04); *"no support for older Android versions"* (1★, 2024-02); a nav bar that vanished on Android 14 (2★, 2023-10). Shared cookbooks and collaboration remain iOS-only.
6. **Quantified neglect.** Android carries ~97K ratings against ~353K on iOS across 16 storefronts — **~22% of the rated base**. Yet Android is where the written sentiment is worst (3.44★ text average) and where the churn language is bluntest.

Interestingly, Android reviewers are *not* mostly complaining about being on Android — only 1.3% of negative Play reviews mention the platform at all. They complain about money and broken imports. The neglect shows up as **capability gaps they may not even know are gaps**, and as a lower ceiling on quality. That is the exploitable part: Android users are not being served a worse app on purpose so much as being served last, always.

---

## 7. Non-US and European experience

- **Tiny Nordic footprint.** Norway 292 iOS ratings, Sweden 335, Denmark 256, Finland 103, Iceland 70 — about **1,056 ratings across all five**, versus 283K in the US. Nordic markets are effectively unclaimed. Norwegian reviewers are warm but few, and one specifically praises language handling: *"it also understands Norwegian!"* (5★, App Store NO).
- **Non-English storefronts rate lower**: Italy 4.41, Finland 4.48, Germany 4.57, Netherlands 4.61, against 4.79 US. The pattern is consistent enough to be real.
- **Language support is thin.** The app declares **EN, FR, DE, PT, ES only**. No Nordic languages, no Italian, no Dutch — despite paying users in all of those markets. The help centre offers the same five.
- **A live localisation/import bug in German**: a 1★ App Store DE reviewer reports imports that used to work for a year now return no image, no recipe, or come back *"nur noch auf arabisch"* (only in Arabic). Another DE reviewer: *"Nun fehlen die Bilder leider beim Import"* (3★).
- **Units are a European deal-breaker.** *"Ridiculous to charge for conversions… from cups to grams"* (1★, App Store GB). An Android reviewer: *"the deal breaker for me is that I prefer to use metric measurements for accuracy in ba[king]"* (3★, 2025-09). And when conversion does run, it is reported wrong: *"when converting measurements to metric it shows gra[ms incorrectly]"* (3★, 2025-11). Metric-first is not a nicety in this category; it is table stakes outside the US, and ReciMe has put it behind a paywall while getting it wrong.
- **The forced-trial complaint is disproportionately British and German.** The GB and DE negative reviews are dominated by "you cannot use the free version without handing over a card first". That is a materially worse look under EU/UK consumer-protection norms than in the US.
- **Pricing in local currency.** AU $59.99 is the documented AU annual price (OzBargain, 2024). NOK/EUR pricing complaints do not appear as specific figures in the corpus — a Norwegian reviewer only notes it is *"Not on the lower end of the price point"* (4★). No NOK figure verified `[UNVERIFIED]`.
- **GDPR / data concerns.** Low volume (0.9% of negatives) but present and sharp: *"Setup is data farming, way too involved"* (1★, ↑42, 2025-09-21). One user could not delete an old account after creating a second one (OzBargain, 2023-09). Separately, **Mela is named by users specifically because it does not collect or link your data** — evidence that a privacy-forward posture is a live differentiator in this category, not a compliance chore. Play's data-safety panel declares no third-party sharing, encryption in transit, and deletion on request.

---

## 8. Trust signals

Reported evenhandedly. Facts are separated from accusations, and accusations are labelled.

### Fact: an onboarding review prompt fires before the user has used the app

This is documented directly in the review stream, and it is the mechanism behind the badge-vs-testimony gap in Section 1.

**83 Play reviews mention being asked to rate the app**, and the recent ones are near-uniformly 1★:
- "wants me to rate before I even get into app" — 1★, 2026-08-17
- "App asks for a review before it even lets me set it up." — 1★, 2026-08-02
- "Bad apps ask you to review before using" — 2★, 2026-07-28
- "locking a review in order to access this app" — 1★, 2026-08-24
- "haven't even been able to verify app works as advertised and asked to rate" — 1★, 2025-09-21 (↑42)

The corresponding inflation is measurable on the other side: **9.5% of all 5★ Play reviews (226 of 2,368) contain pre-use language** — "just downloaded", "so far so good", "can't wait", "haven't used it yet", "will update", "still learning". A further 72 4★ reviews do the same. These are ratings harvested before the product has been experienced, and crucially **before the paywall is met**. That is a sufficient explanation for a 4.7★ badge sitting on top of a 3.44★ written record, with no bad faith required beyond aggressive prompt placement.

### Fact: free lifetime entitlements were given away by the founder, in threads where she also asked for App Store reviews

Both OzBargain giveaways were posted by the ReciMe co-founder herself under the handle `homecookingaddict` (flagged "Associated @ ReciMe"): **2023-09-05** (3,200 votes) and **2024-01-22** (2,480 votes, "Was AU $59.99"). The unlock method was a deliberate loophole — open and close the upgrade screen five times.

In both posts, the review ask sits in the same paragraph as the giveaway:
- "if you're enjoying the app, I would be so grateful if you could give the app a review!" — 2023-09-05
- "it would mean so much if you could give the app a review on the app store" — 2024-01-22
- And in a thread reply: "If you're enjoying ReciMe, feel free to leave us a review on the app store. Thank you! :)" — 2024-01-24

Whether this crosses into incentivised reviewing is a judgement call, and I am labelling it as **contested rather than proven**. The entitlement was given unconditionally, not in exchange for a review, which is the material distinction under both stores' policies. But the pairing is explicit, it was repeated, and OzBargain commenters called it at the time:
- **`[ACCUSATION]`** "They just want a shit load of reviews so then people will pay money for it." — OzBargain, 2023-09-06
- Observed effect, uncontested in-thread: "They went from #150s to #6 in the food & drink category in couple days with 0 marketing expenses." — OzBargain, 2023-09-06
- ReciMe reached **#1 on the App Store in January 2024** `[SECONDARY]`, immediately after the second giveaway.

Note the timing against the rating data: both giveaways landed in 2023–early 2024, when the Play text corpus is very thin. The bulk of the 283K iOS ratings accumulated after. So the giveaway probably bought **chart rank**, while the **onboarding prompt** is what sustains the star average. Two separate mechanisms.

### Fact: marketing claims that the app's own help centre contradicts

- The Play listing advertises "Convert Measurements", "Follow recipes step-by-step" and "Adjust Ingredients" as features, with no premium marking. The help centre (updated 2026-08-09) lists the measurement converter, export/print and step-by-step guided cooking as **premium**.
- The Play listing tells Android users the app syncs across "iOS and iPad."
- The listing claims "10 million users" while showing 1M+ Play downloads.
- **`[ACCUSATION]`** Reviewers repeatedly call the social ads misleading: "App advertising is slightly misleading" (2★, ↑153); "the ads said it imports your saved recipes and categorizes them automatically" (3★, ↑71); "bait [and switch]" (1★, 2025-07).

### Accusations of scam or bad-faith billing

Labelled as accusations throughout — I have no way to verify individual billing events.
- **`[ACCUSATION]`** "SCAM SCAM SCAM Imports never reset" — 1★, App Store GB
- **`[ACCUSATION]`** "Possibly a scam... I loved this app for the 1st free trial period" — 1★, Play, 2025-11-10 (↑29)
- **`[ACCUSATION]`** "I have paid for 12 months… no one has replied to any emails. Avoid. It's a scam" — 1★, App Store GB
- **`[ACCUSATION]`** "I was charged without my knowledge, and the subscription process is misleading. Google Play showed no active subscription, yet I was still bille[d]" — 1★, Play, 2026-07 (↑13)
- **`[ACCUSATION]`** The Black Friday "100% off / $0 first year" promo followed by an immediate charge — 1★, Play, 2025-12-16 (↑41)

### To ReciMe's credit

- They **do reply publicly** to Play reviews (developer responses are present throughout the corpus).
- The founder engaged in genuine, detailed, non-defensive product conversation on OzBargain, logged requests openly, and gave straight competitive answers — including naming Paprika's lifetime price as cheaper than her own product and conceding Paprika had pantry management they lacked.
- At least one 1★ and one 4★ reviewer edited upward after support resolved their issue.
- ReciMe raised ~$2M and is generating roughly $100K/month `[SECONDARY]` — this is a real, funded company, not a fly-by-night operation.

---

## 9. What this hands us

### (a) Quick wins — cheap to build, directly neutralise a named complaint

1. **Merge duplicate ingredients in the grocery list, and sum across units.** Named in reviews and in OzBargain feedback from 2023 — still unfixed three years later. Cheap, visible, and it is the #1 concrete grocery complaint.
2. **Search by ingredient and inside recipe bodies.** The single most-requested feature in the entire corpus, sitting on their second-most-helpful positive review. They still have not shipped it.
3. **Sort alphabetically and by date-added; user tags; filter by ingredient.** Their ↑84 review is literally this list.
4. **Never show a rating prompt before the user has completed a real task.** Their prompt is generating 1★ reviews at a measurable rate in 2026. Ours should fire only after a successful import or a cooked recipe. This is free goodwill and better ratings.
5. **When an import fails, save the link and the video anyway.** They removed this fallback and users noticed (↑16). Never let a user end a capture attempt with nothing.
6. **Persist personal notes and personal ratings on a recipe.** Theirs reset on close — a bug two separate high-vote reviewers complained about.
7. **Keep a visible link back to the original source post.** Asked for repeatedly; trivial to store.
8. **Type an exact serving count; state what a serving is.** Two named requests, both tiny.
9. **Bulk import and a documented migration path** from Paprika, Notes, screenshots, PDF. Their one-at-a-time import is an explicit blocker for the exact high-value user who has hundreds of recipes to move.
10. **Offline read access** to saved recipes. Absolute requirement for a few users, cheap for us, and impossible for a thin cloud client to retrofit gracefully.
11. **Print and PDF export on Android, day one.** They still do not have it and a paying Android user downgraded them over it.

### (b) Structural advantages our one-time ~$25 price gives us

1. **We delete their single largest complaint category outright.** Subscription objection (20.2%), "not really free" (16.0%) and price level (14.6%) together touch roughly **half** of their negative reviews. Most of that anger is not "too expensive" — it is refusal to rent. A one-time price does not compete on that axis; it exits it.
2. **The lifetime ask is already in their review stream.** "I wish there was a lifetime premium option", "It should cost like 8$ one time total", "this is a yearly and not 1 time purchase". Their churned users are describing our product. Paprika is the app they name when they leave, and they name it *for its pricing model*.
3. **No trial, no card, no auto-renew — so no trial trap, no refund war, no cancellation rage.** That erases the trial-trap complaint (11.9%), billing/refund (6.6%) and cancellation (3.7%) categories, and it kills the "all sales final" reputational wound. It also removes the most-helpful review on their entire Play listing as a category of failure we can ever have.
4. **Nothing to ration, so nothing to take away.** Their July–August 2026 slide is partly self-inflicted: moving the unit converter, print and guided cook mode from free to paid. A one-time purchase has no incentive to claw features back, and we can say so credibly. **Never paywall unit conversion** — it is a metric-user tax and it reads as contemptuous outside the US.
5. **Metric-first, free, and correct.** Their converter is paid *and* reportedly buggy. For our European and Nordic market this is a straight win at near-zero cost.
6. **A genuinely usable free entry, or none at all — but never a fake one.** Half their negative volume comes from the gap between "free" in the ad and a wall on arrival. Whatever we do, the store listing and the first run must agree.
7. **Privacy as a stated position.** Users name Mela specifically for not collecting data. We are Norway/EEA-based; GDPR compliance is our baseline anyway. Say it out loud — it is a differentiator their reviewers are already shopping for.
8. **Serve Android first and say so.** Their Play listing tells Android users the app syncs to "iOS and iPad". Being the app that treats Android as the primary platform is an identity, not just a feature list.
9. **The four-in-one scope.** Their users are asking for pantry/inventory and nutrition depth that ReciMe does not have; we already plan pantry, food diary and nutrition tracking. Their own founder conceded pantry management to Paprika.

### (c) Things they do well that we must simply match

1. **Import must be near-instant and near-perfect from Instagram, TikTok, Facebook, YouTube, Pinterest and blogs.** This is the entire reason people love them. It is also the reason people leave — our accuracy bar is set by their failures, not their successes.
2. **Handle the hard cases they fail on**, because these are exactly where their users churn: recipe text in the *comments* rather than the caption; video with no caption at all; recipes with **sections** ("for the sauce"); multi-column cookbook pages; handwritten cursive; Pinterest.
3. **OCR of handwritten and printed family recipes.** This drew the most emotionally loaded praise in the whole corpus — late grandparents' recipe cards. It is not a checkbox feature; it is the one that makes people evangelise.
4. **Strip the food-blog life story.** Non-negotiable, and it is what people quote when recommending them.
5. **Clean, modern, genuinely easy UI.** "Easy" is the most common word in their positive reviews. Also: their 2026 redesign was rejected by users — a warning that a modern look is worth nothing if it slows the app or breaks a working flow.
6. **Aisle-sorted grocery lists** and a **drag-and-drop weekly meal planner.**
7. **Reliable cloud sync across devices**, including a clean iOS→Android migration path — one of their genuinely praised strengths, and our route to poaching their users.
8. **Cook mode that keeps the screen awake, plus step-by-step.** They have it and now charge for it. We match it and never charge for it.
9. **Serving-size scaling.**
10. **Answer support email.** A low bar they clear only inconsistently, and it costs them 1★ reviews and the word "scam".

**The single biggest opening:** ReciMe has trained roughly half its unhappy users to say the words "I would pay once but I will not subscribe" — in public, on the store page, with vote counts next to them. They cannot answer that without breaking their own business model, and they have spent 2026 moving in the opposite direction by paywalling features their users previously had free. We can walk into that gap with the exact product those reviews describe.

---

## Sources

**Primary — raw review data**
- Google Play listing and review endpoint, `com.recime.app` — https://play.google.com/store/apps/details?id=com.recime.app (full text-review corpus, n=4,754, 2023-05-02 → 2026-08-31, pulled 2026-09-01)
- Apple lookup API, per-storefront ratings/averages, 16 countries — https://itunes.apple.com/lookup?id=1593779280
- Apple customer-review RSS feeds, US/GB/AU/CA/IE/NZ/NO/SE/DK/FI/IS/DE/NL/FR/ES/IT — e.g. https://itunes.apple.com/gb/rss/customerreviews/page=1/id=1593779280/sortby=mostrecent/json (n=256 text reviews)
- App Store listing — https://apps.apple.com/us/app/recime-recipes-meal-planner/id1593779280

**Primary — first-party ReciMe**
- "Is there a free version of the app?", ReciMe Help, updated 2026-08-09 — https://recime.app/help/en/articles/11596201-is-there-a-free-version-of-the-app
- "I was charged, but want a refund", ReciMe Help — https://recime.app/help/en/articles/11630496-i-was-charged-but-want-a-refund
- ReciMe website — https://www.recime.app/

**Primary — founder-authored community threads**
- OzBargain, "[iOS] ReciMe – Free Lifetime Subscription $0", posted by ReciMe co-founder, 2023-09-05 — https://www.ozbargain.com.au/node/798026
- OzBargain, "[iOS] ReciMe – Free Lifetime Subscription $0 (Was AU $59.99)", posted by ReciMe co-founder, 2024-01-22 — https://www.ozbargain.com.au/node/827499

**Secondary `[SECONDARY]`**
- Recipe One, "Recime App Review 2026" (competitor-authored; used only for the dated free/paid feature snapshot of 2026-05-21) — https://www.recipeone.app/blog/recime-app-review
- Recipe One, "Is Recime App Free? Yes, But Only 5 Recipes (2026 Pricing)" — https://www.recipeone.app/blog/is-recime-app-free
- Plan to Eat, "ReciMe App Review: Pros and Cons" (competitor-authored) — https://www.plantoeat.com/blog/2025/01/recime-app-review-pros-and-cons/
- Drizzle Lemons, "Best Recime Alternative 2026" (competitor-authored) — https://www.drizzlelemons.com/alternatives/recime
- Apple Support Communities, ReciMe cancellation thread — https://discussions.apple.com/thread/256094402
- AlternativeTo, ReciMe alternatives — https://alternativeto.net/software/recime
- Tracxn company profile (funding, founders) — https://tracxn.com/d/companies/recime
- Product Hunt, ReciMe — https://www.producthunt.com/products/recime-2
