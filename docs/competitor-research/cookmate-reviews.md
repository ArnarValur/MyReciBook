# COOKmate — Reviews, Complaints & Unmet Needs

_Researched: 2026-09-01_

Scope: user sentiment only (reviews, praise, complaints, unmet needs). Feature/pricing teardown is covered by a separate agent and is referenced here only where users complain about it.

**Method / evidence base.** Google Play review data was read directly from the Play Store listing and its own review endpoint via the built-in browser: **2,111 unique reviews** de-duplicated across the "newest" and "most relevant" feeds, spanning **2021-10-23 → 2026-08-25**, of which **146** are substantive negatives (≤3 stars, >40 chars). iOS was read from Apple's public customer-review RSS across 10 storefronts plus the iTunes lookup API. All quotes below are verbatim from those feeds.

**Access limitation:** Reddit is blocked in this environment on every available route (browser pane, web_fetch, and the search tool's own crawler policy). No Reddit evidence appears in this document. Any Reddit-sourced claim in the wider dossier must come from another agent or another session. Cookmate's own site-request/voting board (`cookmate.online/siterequests/`) is login-walled and could not be read.

---

## 1. Rating distribution

Observed **2026-09-01**.

### Android — `fr.cookbook`, Google Play

| Metric | Value |
|---|---|
| Headline rating | **4.7** |
| Reviews (store header) | 45.8K |
| Ratings in histogram | 38,607 |
| Installs | 1M+ |
| Last updated | 2026-05-07 (v5.3.3) |

| Stars | Count | Share |
|---|---|---|
| 5★ | 32,321 | 83.7% |
| 4★ | 4,309 | 11.2% |
| 3★ | 791 | 2.0% |
| 2★ | 395 | 1.0% |
| 1★ | 791 | 2.0% |

Note the shape: **1★ ties 3★ at 791**. This is not a "mildly disappointed" tail, it is a small, polarised, furious minority sitting under a very large satisfied base. The 1★ bucket is overwhelmingly about monetisation changes and lost recipes, not about the product's core job.

### Are recent reviews worse than the lifetime average?

Only slightly. The **350 newest reviews (2025-03-04 → 2026-08-25) average 4.64** against the 4.7 lifetime figure — distribution 5★ 287, 4★ 34, 3★ 10, 2★ 5, 1★ 14. **There is no recent collapse.** COOKmate is not a wounded app; it is a stable, well-liked one with a specific and repeatable set of failure modes. We should plan to beat it on merit, not wait for it to fall over.

### iOS

| App | ID | Avg | Ratings | Version | Last updated |
|---|---|---|---|---|---|
| Cookmate — My Recipe Organizer | 1587685734 | **4.81** | **287** | 1.7.1 | 2026-05-11 |
| My CookBook (Recipe Manager) — legacy | 1015322975 | **2.5** | 14 | 1.0.45 | **2020-04-20** |

Two things matter here. First, **iOS is a rounding error**: 287 ratings against Android's 38,607. COOKmate is an Android product with an iOS afterthought. Second, **the legacy iOS app is still listed, five-plus years stale, at 2.5 stars** — and users were pushed off it onto the new app. That migration is one of the ugliest episodes in the review record (§4, §7).

The US iOS RSS sample (33 most-recent reviews) averages **4.24** — visibly below the 4.81 lifetime figure, i.e. the iOS trend *is* worse than its own average, unlike Android.

**European iOS presence is close to zero.** RSS returned 2 reviews for GB, 5 for FR, and **zero for DE, NO, DK, NL, CA**. There is no iOS incumbent to displace in the Nordics.

Sources: https://play.google.com/store/apps/details?id=fr.cookbook · https://itunes.apple.com/lookup?id=1587685734 · https://itunes.apple.com/lookup?id=1015322975

---

## 2. What people love

Ranked by frequency across the 1,955 positive (4–5★) reviews sampled.

### 1. Web import that strips the blog waffle — the single reason this app exists
269 positive reviews mention importing from the web; 70 explicitly praise the removal of blog narrative. This is the product. Nothing else comes close.

- "The 'import internet recipe' is a godsend tbh." — Play, 5★, 2026-08-08
- "It gets rid of the story and only ports over the important stuff." — Play, 5★, 2026-08-08
- "Super easy and you don't have to read/look through the blog." — Play, 5★, 2024-02-09

### 2. It is simple and it gets out of the way
367 positive reviews use "easy to use", "simple", "intuitive" or "user-friendly".

- "This is a super easy, no nonsense app to use." — Play, 5★, 2026-07-01
- "Very user friendly recipe 'book'." — Play, 5★, 2026-05-27

### 3. Organisation: user-defined categories and tags
301 positive reviews mention tags, categories, sorting or folders. Users want *their* taxonomy, not a vendor's.

- "You can add tags... which makes filtering a breeze." — Play, 5★, 2026-08-08
- "I love the customization and flexibility." — Play, 5★, 2026-08-10

### 4. Recipes are editable — it's *your* copy, not a read-only clipping
185 positive reviews. This is the emotional core of a *personal* recipe manager and it separates COOKmate from content apps.

- "Once saved, I can add my own notes and changes." — Play, 5★, 2026-06-24
- "I love how easy it is to edit the recipes." — Play, 5★, 2026-07-04

### 5. Sharing with family and friends
256 positive reviews. Account-linking to share a collection with a partner, parent or adult child recurs constantly.

- "we can link our accounts and share our recipes." — Play, 5★, 2026-08-08
- "it's easy for us to share recipes." — iOS, 5★, 2026-06-04

### 6. Longevity and trust from long tenure
84 positive reviews reference multi-year use. These are extraordinarily sticky users — the switching cost is their own library.

- "I love this app...been using it now for 10 years" — Play, 5★, 2026-08-09
- "Had it for over 12 Years and is my go to App" — Play, 5★, 2026-07-04

### 7. Shopping list generated from recipes (77), meal planner (44), ingredient scaling (41), recipe scanning/OCR (16), read-aloud & voice assistants (9)
Real but second-tier. Notably, **every one of these is also a top complaint source** (§3) — they are loved in principle and resented in execution.

Source: https://play.google.com/store/apps/details?id=fr.cookbook

---

## 3. What people hate

Ranked by volume and by severity of churn.

### 1. The monetisation switch from one-time purchase to subscription — the dominant grievance
124 of 2,111 sampled reviews touch pricing model; it saturates the 1★ bucket. Two distinct injuries: (a) people who **already bought** the old paid app and found it converted or devalued, and (b) people who resent subscribing for a recipe box at all.

- "Paid for the original Pro version to get rid of ads, but now that version was silently discontinued" — Play, 1★, 2026-07-07
- "I bought the pro version some years ago... changed its business model from purchase based to monthly subscription." — Play, 1★, 2022-03-19
- "I am getting subscription fatigue developers!" — Play, 1★, 2019-06-19
- "Imagine paying a subscription fee for your recipe book" — Play, 1★, 2025-09-21

The explicit ask for our exact model is stated over and over: **"I'd prefer to do a one time payment."** — Play, 3★, 2026-07-06; **"Wish there was a one time payment option for premium like all the other recipe apps."** — Play, 2★, 2025-05-25; **"If it were $20.00 for a one time purchase I would definitely be in."** — Play, 3★, 2021-04-08.

### 2. The 60-recipe cloud limit, and the confusion around it — the #1 churn trigger
This is the most important finding in the document. The Android app is genuinely unlimited *offline*; the 60-recipe cap applies to the **online account** used for sync. **Users do not understand this**, and the misunderstanding is what kills them. The developer has replied to review after review explaining it, and the confusion persists — which means the confusion is a product-design failure, not a comprehension failure.

- "It was good before I reached the secret recipe limits." — Play, 2★, 2026-07-29
- "now I've reached the threshold I feel tricked" — Play, 2★, 2026-07-29
- "60 recipes are max on free version. So sad for i love this app." — Play, 3★, 2025-02-21
- "What happened? I had the premium account, but now I'm limited to 80 recipes." — Play, 2★, 2026-07-28

Developer's standing reply, verbatim: "Recipes are not limited in the Android app. You can use it without an online account" (Play, dev reply, 2023-01-17). The gap between that truth and the user's felt experience *is* the opening.

### 3. Lost recipes on device change — the fear that defines the category
13 sampled reviews report outright loss; the theme dominates the 1★ bucket emotionally. The pattern is nearly always: **new phone → library gone**, because local storage was never actually backed up and the cloud only held 60.

- "I lost all my recipe once I change my phone." — Play, 1★, 2025-01-02
- "I had used this for a couple years and had over 1500 recipes until I switched phones & now I have 60" — Play, 2★, 2022-04-01
- "100s of my recipes and hard work all wiped out." — Play, 1★, 2022-03-26
- "After the app updated my almost decades worth of recipes were gone." — Play, 5★ (!), 2025-07-02
- "there are only 4 recipes there!" — Play, 1★, 2026-01-30

That a **5★ review** contains a decade-of-data-loss report tells you how much goodwill the import feature buys.

### 4. Backup / restore / export is unreliable and hard to find
42 reviews mention backup or export; it is the mechanism behind theme 3.

- "The Export/Import function is abysmal." — Play, 1★, 2025-11-26 (500+ recipes, never transferred)
- "export is not available or too complicated to find" — Play, 2★, 2020-10-17
- "it made an incomprehensible mess out of them. lost the formatting & the photos." — Play, 4★, 2026-07-13
- "I can't backup to a SD card or thumb drive" — Play, 3★, 2023-12-07
- Storage-scope bug: "Why is the app limited to reading files from SD Cards which so many devices no longer support?" — Play, 2★, 2024-12-24

### 5. Ads — intrusive, and *still present after paying*
113 reviews mention ads. Two separate complaints, and the second is a trust wound.

Intrusiveness:
- "you have to now tap three times to even get out of it" — Play, 3★, 2026-06-14
- "a loud ad come on that I cannot close" — Play, 3★, 2024-10-19
- "full screen ads are too much" — Play, 3★, 2019-01-12

Paid and still served ads (repeated across years — treat as a **recurring accusation**, entitlement state is not independently verifiable):
- "I upgraded to premium and still get Ads" — Play, 2★, 2024-07-28
- "Paid for a year subscription and am getting ads." — Play, 1★, 2024-07-20
- "why I am seeing adds on premium subscription?" — Play, 1★, 2023-11-10

### 6. Sync is slow, silent, or fails
52 reviews mention sync.

- "sometimes it takes days for the devices to sync" — Play, 4★, 2022-10-18
- "the synchronization always fails" — Play, 2★, 2020-10-17
- "It is constantly syncing.... Keeps a notification up all the time" — Play, 2★, 2019-01-14
- "I can only see 27 of my 600 recipes on my secondary device." — Play, 1★, 2020-07-26

### 7. Import breaking on specific sites after those sites change
Fewer mentions than expected (5 explicit failure reports) but they are high-intent, high-anger, and they name sites.

- "now up to 4 websites that it used to import that now it won't... Make that 5 websites as now The Mediterranean Dish does not import" — Play, 1★, 2026-06-14
- "Still doesn't work with BBC goodfood recipes and I suspect it's to do with the goodfood website being sold on." — Play, 3★, 2025-08-30
- "I can no longer download recipes from the internet" — Play, 3★, 2021-03-11
- "Couldn't get any of my TikTok recipes to come in at all. Everything was just blank." — iOS, 1★, 2025-08-06

### 8. Shopping list does not merge duplicates or group by aisle
93 reviews mention the shopping list; this specific defect is the most-repeated functional complaint in the app.

- "I had over 300 items which I had to merge on my own" — Play, 3★, 2025-03-29
- "why doesn't the grocery list combine each recipe into one list? and in categories for the store?" — Play, 1★, 2020-02-10
- "every other app for recipe and groceries does this." — Play, 1★, 2020-02-10
- FR: "tout est mélangé" (everything is jumbled) — iOS FR, 2★, 2023-11-12

### 9. Dated, clunky UI
- "Very primitive and repulsive." — Play, 1★, 2026-08-15
- "It looks old and sloppy" — Play, 2★, 2020-10-17
- "Not user friendly and so many ads. Looks cheap." — Play, 1★, 2025-01-27
- "Could benefit from UX overhaul, otherwise good app" — Play, 3★, 2022-08-10
- "the Gui/Usability is complicated..." — Play, 3★, 2025-09-12

### 10. Search and filtering are weak
- "you can type a search term but there is no button to launch the search" — Play, 3★, 2022-11-04
- "I wish you could search by tags, as it seems you can only search by category." — Play, 4★, 2025-01-18
- "a filtering limitation that is a real handicap if you have many entries" — Play, 4★, 2023-11-12
- "The category filter... keyboard pops up and covers the categories" — Play, 1★, 2022-07-06
- "I cannot see any of my recipes, only the icon." — Play, 1★, 2022-03-26

### 11. Account creation and login are genuinely broken for some users
A recurring, years-long, self-inflicted wound — and it happens at the exact moment of first value.

- "Made an account and then it said I couldn't log in with those credentials." — Play, 1★, 2024-09-15
- "it's showing it an error." — iOS, 1★, 2024-11-27
- "I don't wanna log in, Just wanna see recipes" — Play, 1★, 2026-06-07
- Legacy iOS: "I tried registering but it would not allow me to use any @/./ in my password" — iOS, 1★, 2017-04-09

### 12. No dark mode / inconsistent dark mode
- "Dark mode is inconsistent. Uninstalled." — Play, 1★, 2023-06-29
- "The only thing lacking though is a pantry and a dark theme." — Play, 5★, 2025-01-31

### 13. Ingredient model is too crude
- "Doesn't let you enter the measurement for an ingredient seperately" — Play, 3★, 2018-10-18
- "useless since it doesnt allow for submenus in ingredients" — Play, 3★, 2019-07-21
- "would love to see groups added to ingredients and recipe instruction sections" — Play, 5★, 2025-03-22
- Scaling is arithmetically naive: "it converts 1/4 cup water to .083 cups water? You can't measure that" — Play, 3★, 2019-12-31

Source: https://play.google.com/store/apps/details?id=fr.cookbook · https://apps.apple.com/us/app/cookmate-my-recipe-organizer/id1587685734

---

## 4. Deal-breakers — the moment users churn

The churn moments, in order of how often they end a relationship:

**1. New phone, empty app.** The single most destructive event. It converts a decade-long advocate into a 1★ reviewer in one afternoon, and it is the moment they go looking for a competitor. — "time to find a new app." (Play, 1★, 2026-06-14)

**2. Hitting the 60-recipe cloud wall after already investing effort.** Users describe it as betrayal, not pricing: "it has all my previous recipes held to ransom" (Play, 2★, 2026-07-29); "I was held hostage for a pricey subscription" (Play, 1★, 2019-06-19).

**3. The subscription conversion for people who had already paid once.** — "Not paying this company a second time for the same thing." (Play, 1★, 2026-07-07)

**4. Forced iOS migration to the new app.** The most damaging single episode in the record: "So they say we have to switch and the new free app only accepts 60 recipes... Can't even move 60 over to the new app." (iOS, 1★, 2026-03-10). Same reviewer alleges "this is their 3rd time 'upgrading' to less free features" — **flagged as an accusation, not verified.**

**5. Import stops working on the sites they actually use.** Silent, cumulative, and fatal for a product whose whole value is import.

### Where they go

The Play/iOS review corpus is **thin on named destinations** — reviewers overwhelmingly say "another app" without naming it. Only 10 sampled reviews name any competitor, and most of those use "recipe keeper" as a generic noun rather than the product. Verified named mentions:

- **Recipe Keeper → COOKmate** (inbound, and it failed): "I cannot import recipes currently stored in Recipe Keeper... the image was missing and there were several other errors." — Play, 3★, 2025-02-04
- **Pepperplate → COOKmate** (inbound, subscription refugee): "I was a loyal Pepperplate user, but when Pepperplate began charging a monthly fee, I decided to shop around." — Play, 4★, 2020-02-04
- **COOKmate → unnamed one-off-payment app** (outbound, the archetype): "I have found an alternative app with more features and a one-off payment option so I have switched and uninstalled Cookmate. This would not have happened if Cookmate hadn't jumped on the subscription bandwagon." — Play, 2★, 2022-10-30

Paprika, Crouton, ReciMe, Mela, AnyList, Samsung Food/Whisk, Tandoor and Mealie **do not appear by name** in the 2,111 Play reviews sampled. Treat any claim about COOKmate users specifically migrating to those as unsupported by this evidence base.

**Migration friction is bidirectional and severe.** Both inbound and outbound moves fail on the same rock: nobody's export format survives the trip. "I have more than 500 recipes on this app and have never been able to transfer them to another device." (Play, 1★, 2025-11-26). Users who escape often have to **retype**: "now I'm going to have to manually rewrite a c[ookbook]" (Play, 1★, 2019-01-21).

**[SECONDARY]** Two 2026 comparison round-ups of personal recipe managers — recipeone.app (updated 2026-06-03) and cookbookmanager.com — list Paprika, Recipe Keeper, Mela, AnyList, Samsung Food, ReciMe, Copy Me That, OrganizEat, SideChef, Cooklist, Pestle and Tandoor. **Neither mentions COOKmate at all**, despite its 1M+ installs. Its 38K-rating Android base is not translating into category visibility — which is both a warning about SEO/press and an opening. The same sources note that "Paprika, Mela, and Recipe Keeper are the strongest no-recurring-subscription options, but none are a single universal purchase across every platform."

Sources: https://www.recipeone.app/blog/best-recipe-manager-apps · https://cookbookmanager.com/recipe-manager-app-comparisons

---

## 5. Feature requests — what users ask for and don't get

112 of 2,111 sampled reviews contain an explicit request ("I wish", "would love", "please add", "would be nice"). Consolidated and de-duplicated. **This is the backlog.**

### Units, scaling and conversion (most-requested cluster)
- Automatic **imperial ⇄ metric** conversion: "Would be nice if it can automatically convert lbs to kg, oz to g" — Play, 4★, 2023-01-26
- **Fahrenheit ⇄ Celsius**: "a measurement converter for imperial and metric system as well as Farenheit/Celsius" — Play, 5★, 2020-05-06
- Scaling that produces **cookable numbers**, not decimals (see §3.13)
- Batch-size / yield calculator: "add a feature to calculate ingredients according to batch size" — Play, 3★, 2023-06-13
- Structured ingredient fields (quantity / unit / item as separate fields) — Play, 3★, 2018-10-18

### Shopping list
- **Merge duplicate ingredients across recipes** (most-repeated functional request in the whole corpus)
- **Group by supermarket aisle, in the user's own aisle order**: "sorted the shopping lists into categories that you can put in order of the aisles in the store" — Play, 4★, 2021-12-17
- Auto-generate list from selected recipes — Play, 4★, 2020-10-02
- Shopping list **on the watch app** (built a Wear OS app and omitted the list — two separate 2★ reviews call this out) — Play, 2★, 2025-01-18 and 2024-11-18
- Send to Alexa / Google shopping list — Play, 4★, 2026-08-19; Play, 5★, 2018-10-18

### Organisation and search
- Search **by tag**, not only category — Play, 4★, 2025-01-18
- **Multi-select filtering**: "pull up low fat recipes, then chicken recipes" — Play, 4★, 2022-04-15
- Alphabetical categories; nested folders; "to try" vs "core recipes" collections — Play, 5★, 2021-07-07
- Sort by / display **date added**, and prompt to rate after cooking — Play, 4★, 2022-02-13
- Categorise **at import time** rather than editing afterwards — Play, 5★, 2018-12-17
- Pre-made starter category/tag set — Play, 5★, 2023-12-18
- Duplicate detection and merge — Play, 5★, 2023-12-18

### Cooking experience
- **Per-step timers, one tap**: "options to add timer to each step in directions... now need to switch do different apps" — Play, 5★, 2022-03-06
- **Step check-off list** so you don't lose your place — Play, 4★, 2024-06-05
- **Two recipes open at once** — Play, 4★, 2021-10-30
- **Ingredient sub-groups / recipe sections** ("for the sauce", "for the base") — Play, 3★, 2019-07-21; Play, 5★, 2025-03-22
- **Per-step photos** — Play, 4★, 2024-06-14
- Rich text: bold the measurement for glanceability — Play, 4★, 2021-02-25
- **Link related recipes** (cake ↔ icing) — Play, 5★, 2019-09-11; Play, 5★, 2025-12-13
- Screen-stays-awake is already loved — keep it.

### Import and capture
- **Facebook and TikTok video import**: "90% of my saved recipes are from social media (FB & TT)" — Play, 3★, 2026-02-01 (TikTok shipped in v5.3.3 but requires an online account)
- **Import from unsupported sites with manual element selection**: "even if it didn't work perfectly and required some manual selecting of the DIVs" — Play, 5★, 2020-01-11
- Bulk **Pinterest** import — Play, 4★, 2020-09-29
- Import from email — Play, 4★, 2021-12-24
- Photograph a cookbook page / handwritten card — Play, 5★, 2019-05-21 (OCR now exists but is account-gated)
- Import **from other recipe apps** (Recipe Keeper explicitly) — Play, 3★, 2025-02-04

### Nutrition (directly relevant to MyReciBook)
16 reviews touch nutrition. Today it is a **manual free-text field**, and users want it computed.
- "nutrition facts automatically" — Play, 5★, 2020-09-26
- "a nutrition section in the recipes so I can fill in carbs and protein amounts per serving" — Play, 5★, 2020-05-20
- "if it was linked with my fitness Pal app or have its own recipe calorie counter it would be a game changer" — Play, 3★, 2023-06-10
- Formatting: "Nutrition section is scrappy and would be better as a formatted table" — Play, 3★, 2020-05-08
- Ordering: "would prefer nutritional info to follow ingredients and directions" — Play, 5★, 2022-12-27

### Pantry (directly relevant to MyReciBook)
12 reviews. The feature does not exist and is asked for by name.
- "The only thing lacking though is a pantry and a dark theme." — Play, 5★, 2025-01-31
- "i want you to add a pantry option, in order for us to know what we have in s[tock]" — Play, 4★, 2019-02-19
- Cost tracking: "note the ingredients price and calculate price points" — Play, 5★, 2024-12-12

### Sharing, output and platform
- Easier household/family sharing and group cookbooks — Play, 5★, 2026-07-30; Play, 4★, 2025-10-06; Play, 4★, 2025-11-09
- **Print from the app**; better web printing (recipes spilling to 4–5 pages) — Play, 5★, 2023-11-18; Play, 5★, 2019-01-12
- Export a **clean PDF / physical cookbook**: "an option to order glossy bound prints" — Play, 4★, 2021-09-02
- Share a recipe **in the app's own format**, not as a screenshot — Play, 5★, 2019-02-03
- **Dark mode** — Play, 3★, 2022-11-04
- Meal planner: week-at-a-glance; tap through from planner to recipe; drag-and-drop (which reviewers say was **removed** — Play, 3★, 2023-10-29); non-recipe entries in the planner — Play, 5★, 2019-01-19
- Google Play **Family Library** support — Play, 3★, 2021-10-09
- Defaults (e.g. default meal slot) — Play, 4★, 2019-10-25

Source: https://play.google.com/store/apps/details?id=fr.cookbook

---

## 6. Non-US / European experience

**The developer is French.** Cookmate's own site footer reads "Designed and developed in 🇫🇷" and the company is MAADINFO SERVICES. This is a European product with a European data story — but the review record shows the localisation is skin-deep.

**Units are the loudest European complaint.** Import preserves US units with no conversion:
- "it seems to be uploading all my recipes in US and not metric" — Play, 3★, 2025-10-25
- "it would be great if the app has an extra feature that can help to convert measurements to metric" — Play, 4★, 2026-03-21
- "As you never know what recipe you find and you need to edit and convert it all by hands." — Play, 4★, 2023-01-26

**Decimal separator bug — a concrete, unfixed European defect.** A German user reports fraction/portion conversion breaking because German uses a comma decimal separator: "Converting portion sizes to fractions does not work in German because we use commas instead of dots" — Play, **1★**, 2025-09-27. That is a one-line locale bug costing a full star.

**Translation quality is machine-grade and it shows.**
- "It is translated automatic 😄 in other language, a ridiculous one" — Play, 1★, 2023-09-03
- "There are some glitches in other language version but it's still worth using" — Play, 5★, 2020-07-16
- Import quality degrades in non-English: "They don't get ported as well as english language recipes" — Play, 5★, 2020-07-11
- Translation is **crowdsourced from users** — the store listing links to `cookmate.online/translate/`. That explains the quality and the gaps.

**Language coverage (iOS listing):** DA, NL, EN, FI, FR, DE, EL, IT, JA, PT, SK, ES. **No Norwegian. No Swedish. No Icelandic. No Polish.** Danish and Finnish are covered but Norwegian is not — a direct, specific gap in Arnar's own market. **Zero Norwegian-language reviews and zero Norway-storefront iOS reviews were found.**

**EU recipe sites.** BBC Good Food is confirmed broken by a UK user ("Still doesn't work with BBC goodfood recipes... I suspect it's to do with the goodfood website being sold on" — Play, 3★, 2025-08-30). The 200+ supported-site list and its Europe/Nordic coverage could not be audited — the site-request board is login-walled. **[UNVERIFIED]** whether Nordic sites (matprat.no, godt.no, tine.no, arla, coop) are supported.

**GDPR / privacy.** Only one review raises it, but it raises it squarely: "The app also isn't clear about GDPR choices and data sharing" — Play, 3★, 2021-10-09. Play's own data-safety panel declares the app **may share App activity and App info/performance with third parties** and **may collect Personal info, Photos and videos and 2 others**. For an ad-supported app aimed at EU users this is a soft spot, and one paying user's accusation about hidden storage ("over 1000mb of space taken up by THIS APP hidden in folders labeled 'facebook' and 'big buck'" — Play, 1★, 2019-07-07) should be recorded as **an accusation only; not verified, and consistent with ordinary ad-SDK cache naming.**

**French-market sentiment is notably worse than US.** The FR iOS storefront's 5 sampled reviews average 3.00 (vs 4.81 lifetime), including "C'est nul" (1★, 2026-05-31) and category filtering broken ("les catégories ne fonctionnent pas", 2★, 2025-09-04). The developer's home market is not its happiest.

Sources: https://www.cookmate.online/ · https://play.google.com/store/apps/details?id=fr.cookbook · https://itunes.apple.com/lookup?id=1587685734

---

## 7. Trust signals

**Developer responsiveness has collapsed.** Of 2,111 sampled reviews, 62 carry a developer reply. By year of reply: 2020 — 4, 2021 — 11, **2022 — 23 (peak)**, 2023 — 15, **2024 — 1, 2025 — 5, 2026 — 0**. The latest developer reply anywhere in the sample is **2025-07-18**. Of the **22 one- and two-star reviews since January 2025, exactly one received a reply.**

Users notice:
- "update 5 days later I got NO response. Nothing! Remember: I pay for this. Every month!" — Play, 1★, 2026-06-25
- "Tried emailing support on 11/9 but have yet to hear a response." — Play, 1★, 2020-11-23
- "I have emailed the developper twice but no one dares to get back to me" — legacy iOS, 1★, 2020-03-17
- "There is nowhere to go to even reach out to/ contact anyone" — Play, 1★, 2024-07-20
- "Contact dev link is broken :(" — Play, 3★, 2020-05-08

**But the app itself is NOT abandoned.** Android last updated **2026-05-07** with substantive work (TikTok import, filtering, pinch-to-zoom); iOS **2026-05-11**. Report this evenhandedly: **shipping continues, support has gone quiet.** That is a specific, exploitable weakness — not a dying competitor.

**Abandonment fears are live and reasonable.**
- "Are they shutting the app and website down?" — iOS, 2★, 2025-07-21, during a multi-day outage where the website returned "cannot connect to server" and in-app import showed a blank screen
- The **legacy iOS app remains listed and unmaintained since 2020-04-20** at 2.5 stars — a public monument to a stranded user cohort
- Ownership change is referenced by users as the turning point: "once again a great app gets sold and now is useless!" — Play, 3★, 2021-04-20; "Review updated from 5 to 3 stars due to sale of app" — Play, 3★, 2021-03-05. **The sale/ownership-change narrative is user-reported and [UNVERIFIED]**, though the rename from My CookBook to COOKmate and the business-model change are documented facts.

**Data-loss incidents.** No single mass incident is evidenced. What exists is a **steady drip of individual losses** across 2019–2026 tied to device changes, factory resets, app updates and failed restores (§3.3). One accusation of deletion at the model change — "They deleted hundreds of mine without warning when they made the change." (Play, 1★, 2023-09-18) — is **an accusation and is contradicted by the developer's position that local recipes are unlimited and never removed.** Record it, don't repeat it as fact.

**Billing accusations.** One user alleges an unauthorised $111 charge: "I was charged $111 ($104.99 + tax) for an ad free service... and cannot get a refund." (Play, 1★, 2025-10-06). **Single-source accusation, unverified**, and the amount is inconsistent with the published $22.99/yr tier. Note it; do not build on it.

Source: https://play.google.com/store/apps/details?id=fr.cookbook

---

## 8. What this hands us

Ranked by expected effect on winning COOKmate's users.

### Structural advantages — things our architecture and business model give us for free

**1. One-time ~$25 purchase answers the loudest complaint in the corpus, verbatim.**
Users are literally writing our pricing page for us: "I'd prefer to do a one time payment", "If it were $20.00 for a one time purchase I would definitely be in." No engineering required — this is positioning, and it is already validated by 124 reviews. Say the price once, plainly, before install.

**2. No recipe limit — and prove it in the UI, not in a review reply.**
COOKmate's cap is *technically* generous (unlimited local) and *experientially* a betrayal, because the boundary is invisible until you hit it. Our advantage is not "a bigger number", it is **never letting a user wonder where the wall is.** Show library count with no ceiling anywhere in sight.

**3. Migration-in as a first-class feature — the moat nobody has crossed.**
Both directions fail today. A user with 500–1500 recipes is trapped by the format, not by love. If we can ingest a COOKmate export (`.mcb`/`.mmf`/`.mxp`/`.fdx`/`.rk`), Paprika and Recipe Keeper exports **with images and formatting intact**, we can take the most valuable users in the category — the multi-year, high-library, high-intent ones — at the exact moment they are angriest. This is the single highest-leverage build in this document.

**4. Backup that cannot fail silently — the churn moment, neutralised.**
"New phone → empty app" is the #1 relationship-ending event. Design against it: automatic local export, visible "last backed up" state, restore that is one tap and cannot half-succeed, and an explicit pre-uninstall / new-device flow. **Never let a backup be something the user was supposed to have known to do.**

**5. No ads at all.**
113 reviews complain about ads; a repeated subset complain about ads *after paying*, which is a trust wound we simply never open. One price, no ads, ever.

**6. Pantry + nutrition + food diary are already in our scope and are unmet asks here.**
Users request pantry by name and it does not exist. Nutrition exists only as a manual text field and users want it computed and tabulated. We are not adding features COOKmate has — we are shipping the things its users have been asking it for since 2019.

**7. EU-native from day one.**
French developer, but metric conversion is missing, the German decimal separator is broken, translation is crowdsourced and visibly poor, Norwegian is absent entirely, and GDPR clarity is questioned. A properly localised, metric-first, GDPR-clean Norwegian/Nordic product has no incumbent to fight in this niche.

### Quick wins — small builds that neutralise named complaints

**8. Shopping list that merges duplicates and groups by user-ordered aisle.** The most-repeated functional complaint in the entire corpus, and not hard.

**9. Metric ⇄ imperial and °C ⇄ °F conversion, plus scaling that yields cookable amounts** (⅓ cup, not 0.083 cups). Locale-aware decimal separators — get the comma right.

**10. Per-step timers, tap-to-check-off steps, screen stays awake.** Cheap, and directly requested.

**11. Ingredient sub-groups / recipe sections** ("for the sauce"). Called "useless" without it by one reviewer; requested repeatedly.

**12. Search across tags *and* categories, with multi-tag filtering.** Their search is described as having no search button.

**13. Dark mode, done consistently.** One reviewer uninstalled purely over inconsistent dark mode.

**14. No account required to start.** "I don't wanna log in, Just wanna see recipes" — account-wall failures kill users at first contact, repeatedly, across a decade. Local-first, account optional.

**15. Import that degrades gracefully.** When a site isn't supported or breaks, offer manual selection or clean paste instead of a blank screen. Requested explicitly. Publish the supported-site list and fix breakages visibly — import breakage is invisible decay that users experience as betrayal.

**16. Preserve what they love — do not out-clever it.** Web import that strips blog waffle, fully editable recipes, user-defined tags, dead-simple UI, easy family sharing. These five things are why 32,321 people gave five stars. Our differentiation is everything *around* them, not a reinvention of them.

**17. Answer support tickets.** Their replies went from 23 in 2022 to 0 in 2026, and 21 of 22 recent angry reviews got silence. Visible responsiveness is a cheap, durable competitive advantage in this category.

---

## Sources

**Primary — review data read directly**
- Google Play listing and review feed, `fr.cookbook` (2,111 unique reviews sampled, 2021-10-23 → 2026-08-25; ratings histogram; data-safety panel; changelog): https://play.google.com/store/apps/details?id=fr.cookbook
- Apple App Store listing, Cookmate — My Recipe Organizer (id1587685734): https://apps.apple.com/us/app/cookmate-my-recipe-organizer/id1587685734
- Apple iTunes lookup API, current app metadata (id1587685734): https://itunes.apple.com/lookup?id=1587685734
- Apple iTunes lookup API, legacy app metadata (id1015322975): https://itunes.apple.com/lookup?id=1015322975
- Apple customer-review RSS, 10 storefronts (us, gb, de, no, dk, se, fr, nl, ca, au), both app IDs: https://itunes.apple.com/us/rss/customerreviews/id=1587685734/sortBy=mostRecent/json
- Apple App Store listing, legacy My CookBook (Recipe Manager) (id1015322975): https://apps.apple.com/us/app/my-cookbook-recipe-manager/id1015322975
- Cookmate official site (developer origin, news, footer): https://www.cookmate.online/

**Secondary — marked `[SECONDARY]` in the text**
- "12 Best Recipe Apps in 2026 (In-Depth Comparison)", recipeone.app, updated 2026-06-03: https://www.recipeone.app/blog/best-recipe-manager-apps
- "Recipe App Comparisons", cookbookmanager.com: https://cookbookmanager.com/recipe-manager-app-comparisons

**Attempted and inaccessible**
- Reddit (r/AndroidApps, r/Cooking, r/MealPrepSunday, r/selfhosted, r/recipes) — blocked in this environment via browser pane, web_fetch, and search-crawler policy. No Reddit evidence is used in this document.
- Cookmate site-request / feature-voting board — login-walled: https://www.cookmate.online/siterequests/
- AppGrooves negative-review aggregation — returned empty.
