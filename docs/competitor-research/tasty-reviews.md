# Tasty (BuzzFeed) — Reviews, Complaints & Unmet Needs

_Researched: 2026-09-01_

Scope: user sentiment only — ratings, praise, complaints, churn, feature requests, non-US experience, recipe-quality reputation. Features and pricing are covered by a separate agent and are only referenced here where reviewers complain about them.

Method note: Play Store reviews were pulled directly from Google Play's own review endpoint (320 most-recent reviews, global English stream — the `gl` country parameter is ignored by that endpoint, so there is no country-segmented Android review data). iOS reviews came from Apple's public review feed, which only returns entries for a handful of storefronts (US, DE, MX, PH, SG, FI); **GB, CA, AU, NO, SE, DK, IS, IE, NL and FR return zero entries even though the app is live and well-rated there**, so non-US iOS review text is thin and is supplemented with storefront review cards and secondary mirrors. Reddit is inaccessible to both the fetch tool and the browser in this environment (blocked by policy), so there is **no Reddit sourcing in this document** — where community sentiment is claimed it comes from store reviews or marked secondary write-ups.

---

## 1. Rating picture

### Google Play (Android) — observed 2026-09-01

| Metric | Value |
|---|---|
| Rating | **4.7** |
| Ratings/reviews | **~174,000** (listing header also shows "180K") |
| Installs | **10M+** |
| Last update | **13 Aug 2026** |
| Category | Food & Drink |
| Listing "What's new" | "Just the usual tweaks and fixes to make your Tasty experience even better!" |

Lifetime Play histogram (scraped from the live listing, total 173,587):

| Stars | Count | Share |
|---|---|---|
| 5 | 146,323 | 84.3% |
| 4 | 18,663 | 10.8% |
| 3 | 3,337 | 1.9% |
| 2 | 1,339 | 0.8% |
| 1 | 3,925 | 2.3% |

### Recent trend — this is the important number

320 most-recent Play reviews, spanning **2025-12-31 → 2026-08-30**:

| Stars | Count | Share | vs lifetime |
|---|---|---|---|
| 5 | 260 | 81.3% | −3.0 pts |
| 4 | 26 | 8.1% | −2.6 pts |
| 3 | 12 | 3.8% | +1.8 pts |
| 2 | 2 | 0.6% | −0.2 pts |
| 1 | **20** | **6.3%** | **+4.0 pts (2.8× lifetime rate)** |

Mean of the recent sample: **4.58** vs lifetime 4.7. Caveat: the histogram counts all ratings including text-free ones, while the recent stream is review-weighted, so this is indicative rather than exact. But the direction is unambiguous and the *cause* is legible in the text: **of the 20 recent 1-star reviews, 9 are login/account failures.** This is not a slow ad-driven decay — it is one specific unrepaired breakage.

### App Store (iOS) — observed 2026-09-01, version 3.40 (released 17 Aug 2026)

| Storefront | Rating | Ratings |
|---|---|---|
| US | 4.91 | 432,697 |
| GB | 4.87 | 41,053 |
| CA | 4.86 | 51,973 |
| AU | 4.86 | 21,346 |
| MX | 4.92 | 9,302 |
| DE | 4.85 | 8,501 |
| NL | 4.82 | 5,383 |
| FR | 4.80 | 4,779 |
| IN | 4.83 | 4,546 |
| PH | 4.90 | 4,464 |
| **DK** | **4.78** | **2,834** |
| **SE** | **4.82** | **2,415** |
| **SG** | 4.87 | 2,318 |
| **NO** | **4.86** | **2,129** |
| IE | 4.85 | 2,074 |
| **FI** | **4.77** | **447** |
| **IS** | **4.83** | **248** |

Two things fall out of that table. First, **the Nordic storefronts are the lowest-rated in the set** (FI 4.77, DK 4.78, SE 4.82) — a small but consistent gap against the US 4.91. Second, **every single storefront lists the app's language as English only.** There is no localisation anywhere in Europe.

### "Neglected / broken / ad-heavy?" — verdict on each

- **Neglected:** *Partly, and recently recovered.* iOS version history shows steady monthly releases through 2024–mid-2025, then a **~9-month gap between 3.39.1 (22 Jul 2025) and 3.39.2 (15 Apr 2026)**, then 3.39.2/3/4 in Apr–May 2026 and 3.40 in Aug 2026. Release notes are near-universally the same boilerplate line. The Android store description is stale in its own right — it still advertises "Over 3000 Tasty recipes" while the iOS listing claims "10,000+".
- **Broken:** *Yes, in one high-blast-radius way.* Facebook sign-in has been failing since roughly April–May 2026 and was still being reported on 29 Aug 2026. Because saved recipes live behind the account, a broken login means users lose their entire cookbook.
- **Ad-heavy:** *Contested.* Both store listings formally declare advertising (iOS "Contains: Advertising, User-Generated Content"; the app also embeds Nielsen measurement SDK). Ad complaints are loud but **cluster in older reviews**; several 2026 reviewers volunteer the opposite — "no ads easy directions" (App Store US, May 2026) and "absolutely no adds" (App Store US, May 2026). Best read: ad load is real but light/intermittent in 2026, and Tasty+ removes it. Ads are *not* currently the top Android grievance.

### Corporate risk sitting behind all of this

BuzzFeed disclosed in a 27 Jul 2026 SEC filing that it is cutting **~180 employees, ~35% of a 510-person staff, with cuts hitting Tasty**, targeting $29–32M in annualised savings. This is the first major restructuring under **Byron Allen**, who took a 52% controlling stake and the CEO seat in a $120M deal in May 2026. This is directly relevant to sentiment: the "app is decaying" reviews are not paranoia. One 1-star reviewer already connects the dots unprompted — "Unsure if this is related to lack of funds for app upkeep" (Play, Jul 2026).

---

## 2. What people love — ranked

**1. The step-by-step video attached to every recipe.** This is the single most-cited reason people keep the app, by a wide margin, and it is the thing MyReciBook will be measured against emotionally.
- "The step by step videos make it so helpful and easy!" — Play, Jul 2026
- "The videos make the recipe easier to follow." — App Store US, May 2026
- "The videos help take the stress out of cooking and make it fun!" — App Store US, Jun 2026

**2. It makes non-cooks feel capable.** Repeatedly framed as confidence, not convenience.
- "This app is helping me learn to bake." — App Store US, Jul 2026
- "Great and Easy way to learn how to cook for those who don't" — Play, Jun 2026
- "For someone who's new to cooking, this app is perfect!" — App Store GB, Feb 2020

**3. The recipes are genuinely achievable with ordinary ingredients.** This is the quiet, load-bearing praise theme — Tasty's real product advantage over recipe-blog culture.
- "actually has doable recipes with things most people have on hand" — App Store US via JustUseApp mirror, undated `[SECONDARY]`
- "I get 99% of my dinner ideas off this app!" — Play, Aug 2026
- "Easy recipes take you out of rush and out of worries" — App Store US, Aug 2026

**4. Breadth, and that the core is free.** Users explicitly notice they are not forced to pay.
- "Most dishes are free recipes." — Play, Jul 2026
- "found many recipes that fit my lifestyle without paying for their premium subscription" — App Store US, May 2026

**5. Serving-size scaling that rewrites the ingredient quantities.** Small feature, disproportionate affection.
- "when adjusting the portions of the dish, it also adjust the ingredients" — Play, Jun 2026

**6. The tips/comments layer — when it works.** Multiple reviewers and one long-form reviewer treat the comments as where the *real* recipe lives.
- "comments help to improve or substitute recipes" — Play, Jun 2026
- "Love the tips; Love the variety recipes from many cultures." — Play, Jul 2026

**7. Cultural range.** Frequently praised, and notable given the app is US-produced.
- "there are recipes from different parts of the world" — App Store US via JustUseApp mirror, undated `[SECONDARY]`

---

## 3. What people hate — ranked

**1. Account and login collapse — the dominant 2026 complaint, and the one that destroys trust.** Facebook SSO broken; account recovery broken; saved recipes vanish on update; support silent. Nine of the twenty most recent 1-star Play reviews are this.
- "I can't log back in through Facebook" — Play, Aug 2026
- "app was updated and every recipe I saved is gone." — Play, Jul 2026
- "I've emailed support multiple times with zero response." — Play, Aug 2026
- "I had NONE of my recipes I'd saved and cooked." — App Store US, Jun 2026
- "Where did my profile go?!" — App Store US, Apr 2026

**2. Total lock-in — no export, no print, no copy, no import.** This is the most *strategically* useful complaint in the whole corpus, because it is structural to Tasty and trivially winnable for us.
- "Good recipes, but I'm completely blocked from exporting them." — Play, Aug 2026
- "I can't even copy/paste to my word processor." — Play, Aug 2026
- "Great recipes would be awesome if there was a print option" — Play, Aug 2026

**3. Search is weak — no synonyms, no stemming, no exclusion.** Users cannot find things they know exist, and cannot get rid of things they don't want.
- "things I want to look for turn up no matches" — Play, Jul 2026
- "veg, veggie, vegetable. These are NOT pulled up together." — App Store US via JustUseApp mirror, undated `[SECONDARY]`
- "this app needs a way to filter out drinks and desserts" — App Store US, May 2026
- "I can't find the crunchy taco I'm looking for" — Play, Aug 2026

**4. Dietary and allergy filters are unreliable or absent.** Serious, because people rely on them for safety.
- "when I have only shellfish marked on avoid I still get things like shrimp" — App Store US, Jul 2026
- "only option to select is vegetarian. Deleted instantly." — Play, Jul 2026 (Android appears to expose fewer diet options than iOS)
- "I don't understand why there aren't any sugar restricted options!" — App Store US, Jul 2026
- "please add a halal filter to the search" — Play, Jun 2026

**5. The shopping list is a per-recipe ingredient dump wired to a retailer, not a list.** No consolidation, no aisle grouping, no "I already have salt".
- "who shops by recipe? No one" — App Store US via JustUseApp mirror, undated `[SECONDARY]`
- "the list should be organized by food type (produce, spices, etc)" — same source
- "I do not see how to add a recipe to the meal plan" — App Store US, May 2026

**6. Recipe accuracy and completeness.** The video and the written recipe disagree; essential steps are missing.
- "the ingredients list is Missing ingredients from the video" — App Store US via JustUseApp mirror, undated `[SECONDARY]`
- "These recipes lack a lot of essential instructions." — same source
- "some recipes are outdated or don't work" — same source

**7. Content has gone stale, and user-generated content diluted it.** A distinct and growing 2026 theme.
- "gone down hill in regards to frequency and quality of new recipes" — Play, Jul 2026
- "I only saw posts from 7 to 8 years ago" — Play, Jul 2026
- "the addition of amateur content" — Play, Mar 2026
- "showing the same recipes over & over again" — App Store US via JustUseApp mirror, undated `[SECONDARY]`

**8. The app got bloated and lost the thing people came for.** Long-tenured users specifically mourn the step-by-step video focus being buried under a social feed.
- "Too much going on in the app." — App Store US, Jul 2026
- "its a good app, I just find it to confusing to operate now." — Play, Feb 2026
- "Now it has too many 'community' stuff" — Play, Jun 2026

**9. Comment/tips moderation is broken in both directions.** Unmoderated spam on one side; accusations of censorship on the other; and the comment section was reportedly removed on Android entirely.
- "The comment section for the app on android is gone." — Play, Apr 2026
- "people have turned it into more of a random comment spot" — Play, Jul 2026
- "spamming the tips section with screenshots of online pictures and anime stuff" — App Store US via JustUseApp mirror, undated `[SECONDARY]`
- "TASTY DELETES PEOPLES COMMENTS!" — App Store US, long-standing review, undated `[SECONDARY]` — this is a *user allegation*, not a verified fact `[UNVERIFIED]`

**10. AI features actively erode trust.** Both the assistant and AI imagery.
- "now the photos have ai generated food so who knows if it's even good." — Play, Jun 2026
- "The ai bot is useless." — Play, Jun 2026
- "the ai assistant isn't great about helping me find exactly what I'm looking for" — App Store US, Jul 2026

**11. Notification spam that settings do not stop.**
- "I get constant push notifications no matter what I change in settings" — Play, Aug 2026

**12. Video and layout defects.**
- "The videos don't work and say their unavailable" — App Store US, May 2026
- "there's no way to view videos in full screen." — Play, Feb 2026
- "the ingredients are placed far away from the instructions" — App Store US via JustUseApp mirror, undated `[SECONDARY]`

**13. Nutrition data is shallow and inconsistent.** Present per recipe, but not on everything and not deep.
- "adding the nutritional info on all the recipes like amount of protien or fibre" — Play, May 2026
- "y'all forgot to put how much caffeine something has" — Play, Dec 2024 (116 helpful votes)

**14. Ads — historically the loudest complaint, currently muted.** Included for completeness; see the verdict in §1.
- "ads popping up between videos where before there weren't" — App Store US via JustUseApp mirror, undated `[SECONDARY]`
- "I don't have time to watch a 1 min ad every recipe" — same source

**15. Paywall resentment.**
- "wish I didn't have to pay to get the best of this ap" — Play, Jan 2026

---

## 4. Deal-breakers — where users actually churn

Ranked by how often the review explicitly states uninstall/abandonment.

1. **Losing the saved cookbook.** The clearest churn trigger in the corpus. It combines the login break with the export lock: the user cannot get in, and could never have got their data out. "I will be uninstalling" — Play, May 2026.
2. **Search failing on a specific thing they came for.** Fast bounce, sometimes within the first session: "Had the app for 20 minutes to check it out... Improve the filter ability and it might be a good enough app to download again" — App Store US, May 2026.
3. **Dietary filter failing.** Instant delete: "Deleted instantly." — Play, Jul 2026.
4. **Paying and not getting value.** "I've already cancelled this membership so it will NOT renew." — App Store US, Jun 2026.
5. **Ad interruption during cooking** (historical, still cited in older reviews as the moment they went back to a paper cookbook): "will more than likely break out our trusty cookbook instead" — App Store US via JustUseApp mirror, undated `[SECONDARY]`.

**Where they go.** Named alternatives in reviews and in Apple's own "You Might Also Like" adjacency for Tasty: **NYT Cooking, Kitchen Stories, Mealime, SideChef, Recipe Keeper, CookBook, Samsung Food, America's Test Kitchen, MealPrepPro, eMeals, Allrecipes, Paprika, Yummly, SuperCook.** One churned paying user names no app at all — "I can find the same stuff on IG or TT." (App Store US, Jun 2026), which is the real competitive floor: free short-form video on social platforms.

Note the shape of that list. The named escape routes split cleanly into **(a) editorially trustworthy recipe sources** (NYT Cooking, ATK) and **(b) personal recipe managers you own** (Paprika, Recipe Keeper, CookBook, Copy Me That). Tasty leaks users in both directions and covers neither.

---

## 5. Feature requests — the exhaustive list

This is the section to mine. Grouped, with the strongest evidence first inside each group.

### Ownership and portability (highest strategic value — Tasty structurally cannot serve these)
- **Add your own recipes.** "why not let users create there own recipes" — App Store US mirror, undated `[SECONDARY]`
- **Import recipes from the web / elsewhere.** Implied repeatedly; one user reports Tasty's own import is broken — "imports are inaccurate" (Play, Jun 2026)
- **Export recipes.** "completely blocked from exporting them" — Play, Aug 2026
- **Print a recipe.** "would be awesome if there was a print option" — Play, Aug 2026
- **Copy/paste ingredients to any other app.** "I would like an easy way to copy the ingredients to a clipboard" — App Store US, May 2026
- **Share a recipe with another person.** Absent; noted as a gap versus competitors `[SECONDARY]`
- **A real account not tied to a social login.** "I wish there was a way to create a distinct account as opposed to linking our Facebook accounts" — App Store US mirror, undated `[SECONDARY]`; and from GB, "you have to login to Facebook, Twitter or Apple just do favourite recipes" — App Store GB, May 2021

### Organisation
- **User-created cookbooks/categories with your own names.** "There is no way to categorize my many dishes into set type of meals" — App Store US mirror, undated `[SECONDARY]`
- **Stop auto-filing saves into fixed buckets.** "you can't organize the recipe books yourself" — same source
- **Tag / filter your own saved collection**, not just the global catalogue — same source
- **Fix the saved-recipes list losing old entries on scroll.** "it won't show all my previous likes, and it's deleted some stuff I've liked" — App Store US mirror, undated `[SECONDARY]`

### Search and filtering
- **Synonym/stemming search** ("veg" ⇄ "vegetable")
- **Negative filters — exclude categories.** Exclude desserts, drinks, specific proteins, specific cuisines
- **Exclude-ingredient filter.** "add an 'avoid ingredient' filter" — Play, Jun 2026
- **Ingredient substitution suggestions.** "provide possible replacements for ingredients" — Play, Jun 2026
- **Ingredient search beyond 3 items.** "I wish you could add more than 3 ingredients to the meal maker" — App Store US, May 2026
- **Cooking-method filter that is actually honoured.** "when I say no bake it's still showing" — Play, Jun 2026
- **Difficulty/complexity filter that works.** "all the recipes are soooo complicated" — Play, Jun 2026
- **Recipe randomiser from your own saved list.** "a recipe randomizer... pick a random recipe out of My Likes for me" — App Store US mirror, undated `[SECONDARY]`
- **Stop re-showing the same recipes.** "you won't always open up to something new" — Play, Feb 2026

### Diet, allergy and nutrition
- **Allergy exclusions that are actually enforced** (shellfish case above)
- **Sugar-free / diabetic mode.** App Store US, Jul 2026
- **Halal filter.** Play, Jun 2026
- **Keto, GLP-1 and other named diets.** "adding recipes specifically for diets (GLP-1, Keto, etc)" — Play, Jul 2026
- **Nutrition on *every* recipe, not some.** "adding the nutritional info on all the recipes like amount of protien or fibre" — Play, May 2026
- **More nutrient fields**, incl. caffeine — Play, Dec 2024
- **Less sugar/cheese/butter-dominant catalogue.** "mostly sugary food. Sugar, cheese, and butter all over the place." — Play, Mar 2026

### Planning and shopping
- **A weekly meal-planning view.** "if tasty would offer a weekly meal planning tab... this would be a perfect app" — App Store US, undated featured review (developer replied that meal planning shipped in 2023, which itself signals discoverability failure)
- **Meal plan → grocery list wiring.** "I do not see how to add a recipe to the meal plan so that its ingredients will show up on the grocery list" — App Store US, May 2026
- **A shopping list not tied to a retailer**, consolidated across recipes, grouped by aisle, with per-ingredient opt-out — App Store US mirror, undated `[SECONDARY]`
- **Deduplication of quantities across recipes.** "you will end up with a pound of fresh ginger and cilantro" — App Store US, undated featured review

### Content and media
- **Full-screen video.** Play, Feb 2026
- **Spoken audio instead of only background music.** "I'd prefer if all the videos had audio instead of music" — Play, Jun 2026
- **Individual recipe videos rather than only "x things 4 ways" compilations** — App Store US mirror, undated `[SECONDARY]`
- **Ingredients adjacent to instructions**, not a long scroll apart — same source
- **New recipes, more often** — Play, Jul 2026
- **Wider catalogue coverage**, incl. genuinely niche asks: "almost zero recipes for wild animals... rabbit, squirrels or deer" — Play, Aug 2026

### Platform and hygiene
- **Working non-Facebook account recovery**
- **Notification controls that are respected** — Play, Aug 2026
- **Offline access to saved recipes.** No user review in the sample explicitly demands this, but a 2026 secondary review states the app "requires an internet connection to function" and that "You cannot save recipes for offline use" — `[SECONDARY]`, `[UNVERIFIED]` (source shows strong signs of AI-generated SEO content; treat as a lead to test, not a fact)
- **Moderation of the tips/community feed** — Play, Jul 2026
- **Parity between phone and tablet builds.** "Two different Tasty(s) between the phone & pad. Why?" — App Store US, Jun 2026
- **Parity between Android and iOS** (comment section, diet options)

---

## 6. Non-US / European experience

**Language: English only, everywhere.** Confirmed on the App Store product page for every storefront checked, including DE, FR, NL, NO, SE, DK, FI and IS — the "Languages" field reads *English* with no exceptions. There is no Norwegian, Swedish, Danish, Finnish or Icelandic build, and no German or French either despite DE and FR having 8.5K and 4.8K ratings respectively. Users notice:
- "I would like to switch the languages as a Spanish native speaker so sometimes I have to go to the translator" — Play, Feb 2026

**Units: metric exists but is not a first-class mode.** Both store listings advertise "metric values side-by-side with US measurements" — side-by-side, not switchable. That is not the same as a metric app, and users say so:
- "It would be so nice if I could change lbs (imperial system) to kg in the app." — Play, Feb 2026
- A British reviewer credits the conversion but still flags the underlying problem: "some detective work to figure out what the American ingredients are" — App Store GB, Oct 2017

**Ingredient availability and culinary framing are American.** The GB quote above is the cleanest statement of it. The catalogue is built around a US supermarket (US cuts of meat, US brand-shaped pantry items, cup-based baking), and the entire commerce layer is **Walmart and Instacart** — both effectively US-only. For a European user the shopping and checkout half of the product is dead weight.

**Nordic specifics.** No Nordic-language review text was retrievable (Apple's review feed returns nothing for NO/SE/DK/IS, and Google Play does not segment reviews by country). What is measurable is the ratings gap: **FI 4.77, DK 4.78, SE 4.82, NO 4.86, IS 4.83** against **US 4.91** — the bottom of the international table, on small but non-trivial bases (248–2,834 ratings). Iceland has only 248 iOS ratings total. `[UNVERIFIED]` as to cause, but the combination of English-only, US-ingredient, US-retailer product is the obvious candidate.

**EU data posture.** No user reviews in the sample raise GDPR or privacy. But the disclosed practices are notably heavy for a recipe app and are a legitimate differentiator to attack: the app ships **Nielsen's market-research measurement SDK** (disclosed in both store listings), declares **Usage Data used to track you across other companies' apps and websites**, and links Purchases, Contact Info, User Content, Identifiers and Usage Data to your identity, plus coarse Location for third-party advertising. Account deletion exists but is manual and explicitly does not delete your other BuzzFeed accounts. A one-time-purchase app with no ad network and no third-party measurement is a genuinely different privacy proposition in an EEA market, and can be said plainly.

**Platform floor.** The iOS build requires **iOS 18.0 or later** — aggressive, and it strands older devices. Relevant as a general signal that Tasty optimises for its newest US audience rather than its long tail.

---

## 7. Recipe-quality reputation — evenhanded

**The affection is real and should not be dismissed.** Tasty's recipes are widely reported to work for their intended audience, and the app converts non-cooks into cooks at a rate very few products manage. Reviews describing first successful bakes, first dinner parties, and "my family thinks I can cook now" are the single most common five-star narrative. A recipe developer reviewing the app in Jan 2026 concedes the same: it is "extremely beginner-friendly" and "incredible for visual learners" `[SECONDARY]`.

**The criticism from serious cooks is consistent across a decade, and it is about three things:**

1. **The video omits what the written recipe contains.** A 2016 critique from a cook's perspective demonstrates this concretely: a Banana S'more Bites video never shows how to melt chocolate safely, though the full written recipe does — and most viewers only watch the video. Same piece: Tasty "would never" leave a mistake in the take the way Julia Child did, so the viewer never learns recovery. Its blunt summary is that you don't get a practical understanding of the cooking process from the videos.
2. **Virality is optimised over testing.** A 2026 recipe-developer review's central complaint is "Inconsistent Recipe Quality... not all recipes are rigorously tested for the home kitchen", with a worked example of a one-pan chicken-and-asparagus recipe that cooks thin asparagus for the same duration as thick chicken breasts `[SECONDARY]`. This matches user reviews — "some recipes are outdated or don't work", and the observation that ingredient lists and videos disagree.
3. **Attribution.** In 2017, Serious Eats' Kenji López-Alt and food blogger Nick Chipman (Dude Foods) publicly accused Tasty of lifting recipes and ideas without credit; Eugenie Kitchen's rainbow cookie recipe was another flashpoint. BuzzFeed's spokesperson called the suggestion "ludicrous" and said a sourcing and crediting system was subsequently put in place; CEO Jonah Peretti argued publicly that chefs "borrow and remix each other's recipes." Recipes are generally not protectable IP, so none of it was litigated. **Historical, contested, and both sides are on the record** — but it durably shaped how food professionals talk about the brand.

**The synthesis that matters to us:** the community tips section is not a nice-to-have on Tasty — it is the error-correction layer that makes an under-tested catalogue usable. Both the 2026 secondary reviewer and multiple app reviewers independently say the same thing: read the comments before you cook. That is a strong argument for treating recipe notes, ratings and personal amendments as a first-class feature rather than a social bolt-on — and it is exactly the layer Tasty is currently degrading (spam on iOS, removed entirely on Android).

---

## 8. What this hands us — ranked

### Tier A — structural to a free, media-owned, ad-supported app. Tasty cannot fix these without destroying its own business. These are permanent moats for a paid app.

1. **You can never own your recipes.** No import, no export, no print, no copy, no add-your-own. Tasty's only asset is its catalogue; letting users leave with it is suicide. A one-time-purchase app has the exact opposite incentive. This is our single strongest wedge, and users are already articulating it unprompted in Aug 2026.
2. **The shopping list is a retailer funnel, not a list.** It exists to fill a Walmart or Instacart basket. That is why it dumps every ingredient per recipe with no consolidation and no aisle grouping. We have no such conflict — our list can be built for the person walking round a shop.
3. **No nutrition tracking, no food diary, no pantry.** Tasty shows per-recipe nutrition but has no concept of *you over time*. A media discovery product has no reason to build personal longitudinal data. Our four extra pillars (nutrition tracking, food diary, pantry, grocery) are not features Tasty is behind on — they are features it is not in the business of having.
4. **Advertising, tracking, and the Nielsen SDK.** Free means the user is the product. "One payment, no ads, no tracking, no subscription" is a clean, honest, EEA-resonant claim we can make and Tasty structurally cannot.
5. **US-centric content and commerce.** American ingredients, cup-first measurements, Walmart/Instacart. Non-negotiable for them; free ground for us in Norway and the Nordics.
6. **Video-first means online-first.** Their asset is heavyweight video; ours can be text-and-image-first, fully offline, and fast. Worth verifying their offline behaviour directly rather than trusting the secondary claim.
7. **Corporate instability.** 35% layoffs including Tasty, new owner, media-asset strategy. The brand may be great; the app's future is not something a user can bet on. Ordinary users are already saying so in reviews.

### Tier B — pure neglect. Fixable by Tasty tomorrow, so do not build a *strategy* on these — but they are why users are unhappy *right now* and they set the quality bar we must clear on day one.

8. **Account and login must never lose someone's cookbook.** This is the top live complaint. Our answer should be structural, not just better-engineered: local-first storage, no mandatory account, no social-SSO dependency, and an export the user can take away. Then the failure mode simply cannot exist.
9. **Search with synonyms, stemming, and negative filters.** Their search cannot connect "veg" to "vegetable" or exclude desserts. Low-cost, high-visibility win.
10. **Dietary and allergy filters that are actually enforced** — and honest about it. Shellfish must mean shrimp. Include sugar-free/diabetic, halal, keto and named diets, plus a free-text "avoid this ingredient" rule.
11. **Nutrition on everything, and deeper.** Complete macro coverage as a baseline, not a sometimes-field.
12. **Meal plan wired to the grocery list, with quantity deduplication across recipes.** Their meal planner exists and users still cannot get its ingredients into a list — and cannot find the feature at all.
13. **Your own cookbooks, your own names, your own tags.** Auto-filing into fixed buckets is a long-standing irritation.
14. **Personal notes and amendments on a recipe, kept forever.** Tasty proved that the community tips layer is where recipes actually get fixed, then let it rot. A private "what I changed last time, and it worked" field is cheap and sticky.
15. **Respect notification settings. Don't force AI. Don't bloat the cook screen.** Three separate 2026 complaints that are really one complaint: users want the app to stay out of the way while they cook.
16. **Keep step-by-step cook mode with screen-wake.** This is the feature people love most about Tasty and it is table stakes, not differentiation. We must have it, and it must be at least as good.

### One caution
Do not attack Tasty on recipe quality. Its audience does not experience the recipes as bad — they experience them as the reason they can cook at all. Attack the *container*, not the food.

---

## Sources

**Primary — store data and review text (all observed 2026-09-01)**
- Google Play listing, histogram, and review stream — https://play.google.com/store/apps/details?id=com.buzzfeed.tasty&hl=en_US (320 most-recent reviews pulled via Play's own review endpoint on the same origin)
- Apple App Store product page, US — https://apps.apple.com/us/app/tasty-recipes-cooking-videos/id1217456898
- Apple App Store product page, GB (language field, IAP prices, full version history, GB review cards) — https://apps.apple.com/gb/app/tasty-recipes-cooking-videos/id1217456898
- Apple customer review feed, US — https://itunes.apple.com/us/rss/customerreviews/id=1217456898/sortBy=mostRecent/json
- Apple lookup API, per-storefront ratings and language codes — https://itunes.apple.com/lookup?id=1217456898&country=us (repeated for gb, ca, au, no, se, dk, is, ie, de, nl, fr, fi, ph, sg, mx, in)

**Secondary — mirrored/aggregated review text**
- JustUseApp mirror of App Store reviews (undated entries; brand names partially find-and-replaced by the site — quoted fragments verified against the mirror text, dates unavailable) — https://justuseapp.com/en/app/1217456898/tasty/reviews

**Recipe-quality reputation**
- Mic, "The secret ingredient to BuzzFeed's viral Tasty videos: Recipe theft, food bloggers say", Jan 2017 (includes BuzzFeed's on-record rebuttal) — https://www.mic.com/articles/163958/the-secret-ingredient-to-buzz-feed-s-viral-tasty-videos-recipe-theft-food-bloggers-say
- The Odyssey Online, "A Critical Look At Buzzfeed's TASTY Videos", Apr 2016 — https://www.theodysseyonline.com/critical-look-buzzfeeds-tasty-videos
- Flavor365 / eathealthy365, "Is the Tasty App Worth It? A Chef's Honest Review (2026)", Jan 2026 — https://flavor365.com/is-the-tasty-app-worth-it-a-chefs-honest-review-2026/ — `[SECONDARY]`, low-trust: strong indicators of AI-generated SEO content (formulaic structure, generic named testimonials). Used only for the asparagus/chicken timing example, the ad-load characterisation, and the offline claim, all flagged in text.

**Corporate context**
- Variety, "BuzzFeed Laying Off 35% of Its Employees After Byron Allen Takes Over Company", Jul 2026 — https://variety.com/2026/digital/news/buzzfeed-layoffs-employees-byron-allen-acquires-company-1236822122/ (retrieved via search result summary; the article page itself returned empty to the fetch tool)
- Yahoo Finance, "BuzzFeed, HuffPost and Tasty to Lay Off 180 Staffers" — https://finance.yahoo.com/media-advertising/articles/buzzfeed-huffpost-tasty-lay-off-203042395.html
- The Hollywood Reporter, "BuzzFeed to Lay Off 16 Percent of Its Workforce In Major Cuts", Feb 2024 (earlier restructuring; Tasty explicitly *not* impacted at that time) — https://www.hollywoodreporter.com/business/digital/buzzfeed-layoffs-new-restructuring-1235831847/

**Not sourced**
- Reddit (r/Cooking, r/AndroidApps, r/food): inaccessible — reddit.com is blocked to the fetch tool, the browser, and the search tool's domain filter in this environment. No Reddit claims appear in this document.
- YouTube comments: not retrieved.
- Nordic-language review text: unavailable — Apple's review feed returns zero entries for NO/SE/DK/IS/FI(3), and Google Play does not segment its review stream by country. Nordic findings rest on per-storefront rating aggregates and the English-only language field.
