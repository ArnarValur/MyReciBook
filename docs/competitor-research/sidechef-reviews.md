# SideChef — Reviews, Complaints & Unmet Needs

_Researched: 2026-09-01_

Scope: user sentiment only. Features and pricing mechanics are covered in `sidechef-product.md`.

**Primary evidence base.** I harvested **1,632 text reviews** directly from Google Play's own review endpoint for `com.sidechef.sidechef`, spanning **2014-11-11 to 2026-08-30**. All Play quotes below are verbatim from that corpus (truncated to under 15 words per the brief). Star averages per country are Google's own published localized figures. Anything I could not verify at source is marked `[SECONDARY]` or `[UNVERIFIED]`.

---

## 1. The headline correction: the rating did not fall — it is *split by geography*

The brief's "4.0 stars" is real, but it is **not the global number and not a collapse over time**. Google Play shows a *country-localized* average for the same app. Observed 2026-09-01:

| Storefront | Play rating | Approx. 5★ | 4★ | 3★ | 2★ | 1★ | Approx. 1★+2★ share |
|---|---|---|---|---|---|---|---|
| United States | **4.5** | 5,866 | 1,034 | 492 | 197 | 394 | ~7.4% |
| Iceland | **4.5** | 5,869 | 1,191 | 514 | 150 | 263 | ~5.2% |
| United Kingdom | **4.4** | 5,108 | 1,660 | 546 | 231 | 399 | ~7.9% |
| Sweden | **4.2** | 5,447 | 726 | 363 | 363 | 726 | ~14.3% |
| **Norway** | **4.0** | 4,493 | 1,497 | 0 | 0 | 1,497 | ~20.0% |
| **Germany** | **3.8** | 4,022 | 1,416 | 453 | 849 | 1,076 | ~24.6% |

Total review count is the same everywhere (~8.24K ratings / ~7.99K reviews, 1M+ installs). Source: `https://play.google.com/store/apps/details?id=com.sidechef.sidechef` with `&gl=` set per country.

**Caveats, stated plainly.** The star *averages* are Google's published per-country numbers and are reliable. The histogram *counts* are derived from the rendered bar widths and are approximations — the Norwegian row showing literally zero 3★ and zero 2★ is a quantisation artefact of a very small local sample, not a real distribution. Norway and Iceland have few local raters, so their averages are high-variance. **Germany at 3.8, with the largest European sample, is the statistically meaningful European signal** — and Germany is a full **0.7 stars below the US**.

The takeaway is not "SideChef fell from good to 4.0." It is: **SideChef is a 4.5-star app in America and a 3.8-star app in Germany, at the same moment, from the same binary.** The half-star-to-full-star gap is the price of being a US-only product sold worldwide.

### iOS tells the same story from the other side

| iOS storefront | Rating | Rating count |
|---|---|---|
| US | 4.7 | ~1,700 |
| UK | 4.66 | 110 |
| Germany | 4.77 | 31 |

Source: `https://itunes.apple.com/lookup?id=905229928&country=de` (and `gb`, `us`). iOS looks healthy *everywhere* — but the non-US samples are 31 and 110 ratings. iOS never acquired a European user base large enough to be disappointed. Android did, and Android is where the anger is recorded.

### The actual timeline, from the review corpus

Yearly average of **text** reviews (text reviews skew more negative than star-only ratings, so read the shape, not the absolute level):

| Year | Reviews | Avg | What was happening |
|---|---|---|---|
| 2014 | 38 | 3.89 | Launch |
| 2015 | 88 | 3.81 | |
| 2016 | 26 | 3.58 | Crash reports begin |
| **2017** | 61 | **2.67** | **Crash + signup collapse after mass-media exposure** |
| 2018 | 340 | 4.39 | Recovery; Google Play "Best App of 2017" |
| 2019 | 305 | 4.17 | Performance complaints peak |
| 2020 | 119 | 3.82 | Load-time complaints |
| **2021** | 128 | **4.50** | **Peak** |
| 2022 | 178 | 4.37 | Walmart exclusivity bites |
| **2023** | 172 | **4.02** | **Budget Bytes migration** |
| 2024 | 77 | 4.13 | Sync/save breakage |
| 2025 | 62 | 4.24 | Last app update (Mar 2025) |
| 2026 | 38 | 4.13 | Paywall tightening on a frozen app |

Two things are visible. First, a genuine **2017 crater to 2.67** — the app broke in public. Second, a **slow bleed from the 2021 peak of 4.50 down to ~4.0–4.1**, never recovered.

Third, and most damning: **review velocity collapsed**. 340 text reviews in 2018 → 38 in the first eight months of 2026. For a 1M+ install app, that is an app people have stopped caring about.

### Three events that shipped and cost stars

**a) Late 2017 — the app broke on camera.** A dense cluster of December 2017 reviews reports the app not loading past the landing page, right as the app got national US TV exposure. "This app was just advertised on The Today Show" (2★, 2017-01-25). Then: "the app is not opening from the landing page" (2★, 2017-12-01); "Unable to open on my Moto e4 plus" (1★, 2017-12-28). Simultaneously, signup was broken — "Unable to even join. Repeatedly tells me username needs to be letters or numbers" (1★, 2017-03-02) — and login demanded phone contacts. That combination is what produced the 2.67 year.

**b) July 2023 — the Budget Bytes migration.** SideChef terminated the Budget Bytes app on **July 6, 2023** and funnelled its ~220K users into SideChef. SideChef's own notice states plainly: "your existing recipes will not be transferred to SideChef" and "Your personal data will be deleted." (https://www.sidechef.com/articles/1666/bb-app-termination/, published 2023-06-19). A wave of 1–2★ reviews follows within weeks, all from the same cohort — see §3.

**c) Early 2026 — a paywall tightened server-side on an app nobody is maintaining.** The Android app was last updated **2025-03-14** and the iOS app is on **5.31.1, also 2025-03-14** — roughly **18 months with no release** as of this writing. Yet in 2026 users report a *new* subscription gate: "they added a subscription feature" (1★, 2026-04-12); "you guys want a subscription to get a recipe that's behind a paywall?" (1★, 2026-08-04). A paywall that appears without a client update is a server-side change. **They stopped shipping improvements and kept shipping monetisation.**

---

## 2. What people love — ranked

**1. Step-by-step guided cooking with a picture per step (the single most-praised thing).** This is what converts non-cooks. It is mentioned in more 5★ reviews than any other feature.
- "it's an amazing app, I find new recipes every day" — Play, 5★, 2019-07-11 (59 helpful)
- "This app is excellent for beginning cooks who don't know how to shop" — Play, 5★, 2026-08-30
- "it's a perfect app for beginners" — Play, 5★, 2025-11-03

**2. Meal plan → grocery list as one connected flow.** Users describe the *linkage* as the value, not either half alone.
- "the way the meal plan and the shopping list is connected is a really good idea" — Play, 5★, 2020-01-06 (29 helpful)
- "this app has been a life saver on extra busy weeks" — Play, 5★, 2021-09-03 (62 helpful)
- "best app to give me ideas & a shopping list in one place" — Play, 5★, 2026-05-19

**3. Breadth of recipes, and free access to most of them.** The generosity of the free tier is repeatedly the reason for the fifth star.
- "the free version is super robust and has everything I was looking for" — Play, 5★, 2020-12-31 (27 helpful)
- "not everything is locked behind premium" — Play, 5★, 2022-01-04 (24 helpful)
- "This app offers so many recipes... And plus, no ads absolutely" — Play, 5★, 2019-07-04 (81 helpful)

**4. Clean, uncluttered design.** Praised specifically against recipe-blog clutter.
- "the design is so clean" — Play, 5★, 2020-01-06
- "i love how simple the ui is... i appreciate the no bs approach" — Play, 4★, 2025-09-20

**5. Walmart/Instacart one-click checkout — *when you are in the US*.** Genuinely loved by the American users it serves.
- "The Walmart integration is pretty great" — Play, 5★, 2022-01-04
- "Price checking with local Walmarts is an added benefit" — Play, 4★, 2024-10-10

---

## 3. What people hate — ranked

**1. Dietary filters and allergy settings that are ignored. This is the #1 recurring complaint and it spans nine years unfixed.** 42 reviews in the corpus mention diet/allergy filtering. It is the complaint most likely to make a user uninstall on day one, and — because it involves allergens — the most dangerous.
- "I set my diet to vegetarian and still get meat dishes recommended to me" — Play, 3★, 2026-07-11
- "First 5 suggestions ALL had recipes with the foods that I listed to avoid" — Play, 1★, 2026-02-05
- "Using the vegetarian filter, I have seen recipes with shrimp, salmon, chicken" — Play, 3★, 2018-01-30 (19 helpful)
- "Very inaccurate for allergies!! The 'gluten free' recipes call for malted milk powder" — Play, 1★, 2017-12-07
- "If your life threatening allergies go beyond the top 8, you're f***ed" — Play, 2★, 2024-03-25
- "You can't add your own foods to avoid. Useless for those who can't have oranges" — Play, 1★, 2023-12-18

Same complaint, 2018 and 2026. Nothing was fixed in eight years.

**2. Crashes, blank screens, and app-won't-open.** 50 corpus mentions. Never resolved for long.
- "The app simply doesn't open past the first screen" — Play, 1★, 2023-08-18
- "SideChef will not open for me. It shows the front screen and never gets any farther" — Play, 2★, 2025-10-04
- "doesn't work after update." — Play, 1★, 2026-02-15
- "it froze my entire phone to the point it had to restart" — Play, 1★, 2023-06-29 (10 helpful)

**3. Slowness and load times.** 52 corpus mentions, and it drove down the 2019–2020 years specifically.
- "it's slowness is frustrating" — Play, 3★, 2020-04-27 (109 helpful)
- "It takes 10x too long to be able to just make a simple search" — Play, 2★, 2020-02-25 (17 helpful)
- "the load times are horrendous" — Play, 3★, 2019-12-31 (24 helpful)

**4. Losing saved recipes and meal plans.** The single most trust-destroying category, because it destroys accumulated user work.
- "After an update months ago I lost all my saved recipes. Thousands gone." — Play, 1★, 2023-01-27 (8 helpful)
- "Spent over a month making a rotating 6 week meal plan... ALL IF MY SAVED MEALS ARE GONE!!!" — Play, 2★, 2023-01-23
- "the recipes no longer save into the grocery list" — Play, 1★, 2024-03-10 (24 helpful)
- "app erases all my saved recipes often" — Play, 2★, 2023-08-19

**5. The Budget Bytes forced migration (2023).** A distinct, dated cohort of betrayed users.
- "ALL of my saved and favorites recipes disappeared and I can't find 90% of them" — Play, 2★, 2023-07-23
- "This app is not what Budget bytes used to be, and I'm quite sad" — Play, 1★, 2023-08-13 (6 helpful)
- "I'm being forced to change from budget bytes to this? No thanks" — Play, 1★, 2023-07-14
- "it is being taken down and replaced with this garbage" — Play, 1★, 2023-06-17 (4 helpful)

**6. Walmart exclusivity — the app reads as an advertisement.** 36 corpus mentions of grocery partners.
- "This app feels like one big giant walmart ad" — Play, 1★, 2023-07-03
- "it's apparently just a big shill for Walmart now??" — Play, 3★, 2023-07-21 (16 helpful)
- "Only having Walmart as a shopping partner is a non starter for me" — Play, 1★, 2022-09-11
- "since there r no Walmarts in Brooklyn... this app is now 100% fully useless" — Play, 1★, 2023-12-15

**7. Grocery cart substitutes the wrong ingredient.** Breaks the core promise at the point of payment.
- "a pork loin chop isn't the lamb chop in the literal title of the recipe" — Play, 2★, 2023-11-22 (28 helpful)
- "Black pepper can be in 4 recipes, and end up in your cart 4 times" — Play, 2★, 2022-02-02 (45 helpful)
- "my order did not sync to the cart in the Walmart app" — Play, 4★, 2025-01-03 (50 helpful)

**8. Subscription resentment and paywall creep.** 23 corpus mentions; the tone hardens sharply after 2023.
- "Without spending money the app is basically useless." — Play, 1★, 2024-07-30
- "More paywalls and more tracking with each update." — Play, 1★, 2020-08-08
- "Needing to mentally skip past too many premium only recipes" — Play, 3★, 2021-03-01 (10 helpful)
- "there is no possibility to purchase the app once and for all" — Play, 2★, 2022-03-27 (68 helpful) — the same review calls it "ripoffware"
- "I need to send an email to cancel my subscription... a tactic to get people to not cancel" — Play, 3★, 2022-01-20

**9. Forced account creation.** 36 corpus mentions.
- "Forced account creation, not worth it" — Play, 2★, 2024-04-15
- "Require signing in for no reason" — Play, 1★, 2023-02-02
- "For some reason you have to sign up." — Play, 1★, 2019-11-03 (16 helpful)

**10. Privacy: contacts permission, clipboard reading, account deletion.**
- "it won't allow me to log in without granting access to my contacts" — Play, 2★, 2017-12-06 (63 helpful)
- "Not GDPR compliant. Why does a cooking app require access to my contacts?" — Play, 1★, 2018-04-19
- "The app reads the clipboard on startup" — Play, 1★, 2023-07-26 (10 helpful)
- "Can't delete account, legally you need to provide an option to delete user accounts" — Play, 1★, 2022-04-21
- "doesn't have a delete account option afterward" — Play, 1★, 2019-07-09

**11. Can't add your own recipes / import is unreliable.**
- "Making your own recipe is a struggle" — Play, 3★, 2019-07-08 (44 helpful)
- "when I paste the URL it keeps saying there is an error" — Play, 3★, 2026-07-09
- "Import of recipes is very hit and miss. I tried from 6 different food websites" — Play, 2★, 2023-01-16 (10 helpful)
- "Can't save anything from the Internet." — Play, 2★, 2024-11-22

**12. Unwanted robotic voice narration with no off switch.**
- "the robotic voice is such a huge annoynce" — Play, 2★, 2017-12-05
- "Couldn't disable the voice in the step by step instructions... Uninstalled it and deleted my account" — Play, 1★, 2023-02-13 (6 helpful)

---

## 4. Deal-breakers — the exact moment people left

Ranked by how often the review contains an explicit uninstall statement:

1. **Allergy/diet filter fails on first use.** "The allergy and food to avoid didn't work... Uninstalling" (3★, 2025-01-02). "'For any diet!'... First screen doesn't allow me to choose what I'm allergic to. Basic feature. Uninstall" (1★, 2023-07-19). This kills users in the first session, before any value is delivered.
2. **Saved work disappears.** Thousands of saved recipes gone after an update (1★, 2023-01-27). Users who lose accumulated data do not come back.
3. **Grocery checkout is unusable where they live.** "Can't use in Britain. It only shows Walmarts" (1★, 2021-12-28). "apparently it's inappropriate for someone who lives outside US" (2★, 2019-07-05, 35 helpful).
4. **Measurements unusable.** "Need to have metric measurements. Don't understand pounds and oz... it's useless to me and I'm uninstalling" (5★ rating, negative text, 2018-03-27, 17 helpful).
5. **The app won't open.** "The app is unusable unfortunately." (1★, 2025-08-23).
6. **Paywall hit at the moment of need.** "you guys want a subscription to get a recipe that's behind a paywall? Every recipe is already on the Internet for free" (1★, 2026-08-04).
7. **Privacy demand at signup.** Contacts permission (2017–2018 cohort); clipboard reading (2023).

**Where they went.** Named destinations in the corpus, in rough order of frequency: **Copy Me That** ("Highly recommend 'Copy me that' app", 1★, 2024-06-30), **Mealime** (2★, 2023-07-16 and 5★, 2022-01-04 switching *to* SideChef — traffic runs both ways), **AllRecipes** ("I'm sticking with All Recipes", 1★, 2017-12-07), **Budget Bytes' website** (users who refused the app migration), **Pinterest** (App Store, 1★, 2022-01-07), and plain **Google search** ("I'd rather just google", 1★, 2023-07-14).

---

## 5. Feature requests — exhaustive list of what users ask for and don't get

Ordered by how often and how loudly requested.

- **Custom "ingredients to avoid" beyond the top-8 allergens** — the most repeated request in the corpus. "expand the ingredients to avoid so you can add your own" (3★, 2025-10-19); "You can't add your own foods to avoid" (1★, 2023-12-18); low-sodium diets specifically unsupported (1★, 2020-12-15).
- **A one-time / lifetime purchase instead of a subscription.** "please create a one time/lifetime payment option... the only thing stopping me is the recurring yearly subscription of $87 AUD" (3★, 2023-10-10, 20 helpful). Also "no possibility to purchase the app once and for all" (2★, 2022-03-27, 68 helpful). **Users are explicitly asking for MyReciBook's exact model, and being refused.**
- **Nutrition / calorie / macro data per recipe** — asked for repeatedly and never satisfactorily delivered. "there's no nutritional information for the recipes" (3★, 2018-08-30); "no nutritional breakdown and for my lifestyle I need to know" (4★, 2019-11-14); "could you add what the meals contain like how many calories" (5★, 2020-01-24).
- **A real pantry with quantities and expiry dates.** "It would be nice to have a pantry... details like expiration dates" (3★, 2019-01-23, 23 helpful); "I expected to be able to also enter the amount" (4★, 2025-09-20); "Not any clear way to mark items as in your pantry" (2★, 2022-02-02, 45 helpful). Pantry shipped in 2023 but stayed shallow: "I don't want to update my pantry every single time" (3★, 2025-11-21).
- **Choice of grocery store beyond Walmart.** "Wish I could have more control over what stores I can shop" (3★, 2021-11-08, 17 helpful); "would have preferred" a different partner (3★, 2022-11-21, 15 helpful).
- **Custom items and custom units on the shopping list.** "Wish i could put custom items on shopping list (eg cat food)" (4★, 2019-05-05); "Please make units editable so we can add custom units such as portions" (1★, 2019-09-19).
- **Adding your own ingredients that aren't in their database.** "I can only add Italian Dressing, but not..." (1★, 2019-09-19); "it's unaware of some simple ingredients... Please at least add chickpea flour. And Kimchi." (2★, 2024-10-08); "i cant add some ingredients peculiar to local's" (2★, 2023-12-05, Philippines).
- **Personal notes on saved recipes.** "the ability to add your own notes to saved recipes. 'Husband thought it needed more seasoning'" (5★, 2024-08-16, 17 helpful).
- **Sharing a cookbook / meal plan with a household member.** "I wish I could share my cookbooks with people! Why is this not a feature?" (4★, 2017-12-15, 42 helpful); "share with another household member" (3★, 2021-07-11, 28 helpful).
- **Offline access.** "Make an offline app" (4★, 2018-12-11); "save a recipe to the device without having to register and log in" (3★, 2015-01-02).
- **More languages.** "i wish to add more languages" (5★, 2024-03-27); "Ojalá pudiera poner la aplicación en otros idiomas" (2★, 2023-01-16). SideChef ships **English and German only** (iTunes metadata).
- **Print a recipe.** "the option to print a recipe instead of your phone reading it to you" (1★, 2020-07-24).
- **Turn off the voice narration.** (2★ 2017-12-05; 1★ 2023-02-13).
- **Filter by equipment you own** (microwave, pressure cooker). "a category for cooking utensils" (5★, 2017-12-31, 25 helpful).
- **Ingredient price / total grocery cost estimate in local currency.** "I'll pay for premium if you add it, I swear." (4★, 2023-09-09).
- **Consolidate duplicate ingredients across recipes into one line.** (2★, 2022-02-02, 45 helpful).
- **Recipe variety / rotation** — the same recipes keep resurfacing. "I am only seeing the same recipes repeated" (3★, 2019-10-20); "I see alot of the same ones in recommended and trending" (3★, 2022-05-02, 33 helpful).
- **Better cookbook organisation** — checkbox multi-add to collections (4★, 2018-11-21).
- **Meal-prep category** (2★, 2023-06-26).
- **Ingredient substitution suggestions** (5★, 2024-11-12).

---

## 6. Non-US / European experience — the decisive section

This is where SideChef's rating actually lives, and it is the section most directly transferable to MyReciBook.

**a) Grocery checkout does not exist outside the US, and SideChef says so in its own listing.** The Play description reads: "shop ingredients directly through Walmart and Amazon Fresh (**U.S. only**)". The headline feature — the thing every screenshot and press quote sells — is geo-fenced to one country and then marketed to 1M+ installs worldwide.
- "Can't use in Britain. It only shows Walmarts in the store lists and the UK doesn't have Walmarts." — Play, 1★, 2021-12-28
- "apparently it's inappropriate for someone who lives outside US" — Play, 2★, 2019-07-05 (35 helpful)

**b) Recipes assume American supermarkets.** "the app is based on US recipes, which highlights ingredients mostly found in American stores rather than EU locations" — Play, 2★, 2018-10-30 (8 helpful).

**c) Metric conversion is broken, not merely absent — which is worse.** The app *has* a metric toggle and it produces nonsense:
- "I select the metric system and it converts very weirdly such as asking me for 45mL of diced carrots or 237mL of rice. Unusable if you live outside the US" — Play, 2★, 2017-12-03 (11 helpful)
- "the metric measurements are quite odd: 0.9kg instead of 900g" — Play, 3★, 2018-01-30 (19 helpful)
- "Metric conversion doesn't include temperature" — Play, 4★, 2018-01-05
- "maybe you may thinking adings Celsius degrees, not all people use Fahrenheit degrees" — Play, 1★, 2017-12-09
- "there is no real easy way to change between metric and us" in the grocery list — Play, 4★, 2021-08-26
- Getting it right is worth a five-star all by itself: "When I saw, that I no longer have to convert cups into grams, I instantly uninstalled all of my other recipe apps" — Play, 5★, 2022-09-28

**d) Prices are shown in USD to everyone.** "while week planning price is displayed in USD, but that info is quite useless outside US" — Play, 4★, 2023-11-02.

**e) Language support is English + German only.** Confirmed in iTunes metadata (`languageCodesISO2A: ["EN","DE"]`). No Nordic language. Ingredient entry is English-only, which blocks non-English users from even building a recipe: "it's in English and that's the only available language" — Play, 1★, 2019-03-16 (21 helpful).

**f) Location handling is unreliable even when it matters.** "I put in my zipcode but you ignored it and pulled from my VPN instead" (3★, 2025-02-25); "the app has put a completely different zip in Tampa -- 3 hours away" (2★, 2025-02-26). ZIP-code-based store selection is itself a US-only construct.

**g) GDPR and EU privacy friction.** A user explicitly invoked GDPR over the contacts permission in 2018 (1★, 2018-04-19). Account deletion has been reported as missing or unanswered on both stores: "Can't delete account, legally you need to provide an option" (Play, 1★, 2022-04-21); an App Store reviewer reports repeated unanswered deletion requests. SideChef does now publish an EU GDPR representative link (`gdpr-rep.eu`) in its site footer, so the formal compliance apparatus exists — the *user-facing* deletion path is what people say failed.

**h) Nordic specifics.** I found **no Nordic-language reviews and no Norwegian, Swedish, Danish, Icelandic or Finnish grocery integration** anywhere in the corpus or the product listings. The Nordic evidence is the *ratings gap only* (Norway 4.0, Sweden 4.2 vs US 4.5) — and given the small local samples, I would treat the Nordic averages as indicative rather than precise. **The Nordics are, for practical purposes, an unserved market in this category.**

**i) The one non-US thing they did do — and it shows what a real localisation looks like.** SideChef supports LG, GE and **Bosch Home Connect** (Thermador, Gaggenau) smart appliances — a European appliance partnership. It is a B2B integration, not a consumer localisation, and no review in the corpus praises it.

---

## 7. Trust signals — reported evenhandedly

**Documented, verifiable:**

- **The app has not shipped a release in ~18 months.** Android last updated 2025-03-14; iOS 5.31.1, 2025-03-14. Both stores agree. Meanwhile the Play listing still carries an **Editors' Choice** badge and quotes "Best App of 2017."
- **The Budget Bytes shutdown destroyed user data by design and SideChef documented it themselves**: "your existing recipes will not be transferred" / "Your personal data will be deleted" (sidechef.com, 2023-06-19). This was announced 17 days before the July 6 cutoff.
- **The company's own website foregrounds B2B**, not the consumer app: Cooking Experience Platform, Cost-Per-Order Campaigns, Shoppable Tech, SideChef AI. The consumer app increasingly reads as a shop window for a retail-media business — which is exactly what the "one big giant walmart ad" reviews are perceiving.
- **A paid-review-adjacent promotion did happen.** In December 2021 SideChef ran a $100 Visa gift-card promotion tied to app trial and a survey. Both sides are visible: "They really are legit! They most definitely sent the gift card" (Play, 5★, 2022-01-11, 17 helpful) and, from a user who says they never received it, "Basically they wanted my information and for me to do a survey so they could use that information than ghost you" (App Store, 1★, 2022-01-07, title "False promises").
- **The US App Store listing title uses a Cyrillic "С" homoglyph**: "SideСhef: Easy Cooking Recipes" (US/DE storefronts) versus the Latin-spelled "SideChef: Recipes+Meal Planner" (UK storefront). Same app ID, 905229928. I can confirm the character difference; I cannot confirm the intent. `[UNVERIFIED]` as to purpose.

**Accusations, labelled as accusations (users' claims, not established fact):**

- **Dead support.** Multiple users across both stores allege emails go unanswered — including account-deletion requests. Against this: SideChef *does* reply publicly to Play reviews, and did so as recently as 2026-08-03, and one 5★ specifically praises "Really good customer service from the developer" (2022-01-04). The pattern looks like **public replies maintained, private support queue not**.
- **Spyware / excessive tracking.** "Doesn't do much other than send your GPS COORDINATES AND OTHER TRACKING INFO... Deleting this spyware" (Play, 1★, 2023-04-12). This is a user's characterisation. What is independently verifiable from Apple's privacy label is that **Location is declared as used to track users across other companies' apps and websites**, and that coarse location, email, device ID, search history and usage data are all linked to identity.
- **Review quality in 2026.** `[UNVERIFIED — observation, not an accusation]` The 2026 review stream is dominated by very short, generic, emoji-heavy 5★ entries ("Uh-mazing", "fantastic", "Bro this is the gem") on an app that has shipped nothing in 18 months, while the substantive reviews skew critical. I have no evidence of manipulation and am not alleging any; I note only that the recent five-star signal carries little information.
- **NPS.** `[SECONDARY]` Comparably reports a SideChef NPS of **-34** (33% promoters / 67% detractors) and a customer-service score of 3.5/5. Comparably samples are small and self-selected; treat as directional only.

---

## 8. What this hands us

### Ranked opportunities for MyReciBook

1. **Europe is open.** The category leader is a 3.8-star app in Germany and has no Nordic presence, no Nordic language, no European grocery integration, and broken metric conversion. This is not a crowded field we are entering — it is an *unserved* one wearing an American app's hand-me-downs.
2. **"Buy it once" is a request users are already making by name.** Two of the most-upvoted critical reviews in twelve years are literally asking for a lifetime purchase option and being refused. We do not have to educate the market on our pricing model; we have to show up with it.
3. **Working allergy and avoid-ingredient filtering is a category-defining gap.** The #1 complaint, unfixed for nine years, at the market leader. Custom avoid-lists (not just the top-8 allergens) with hard exclusion from recommendations is a feature we can win on outright.
4. **Nutrition data per recipe is requested constantly and delivered thinly.** Our nutrition tracking and food diary land directly in the hole SideChef left.
5. **A pantry with quantities and expiry dates.** Requested since 2019; SideChef's 2023 pantry is too shallow and too manual to keep. Ours has to be cheap to maintain or it will be abandoned the same way.
6. **Offline-first is unclaimed.** SideChef requires an account and a connection to do anything. A cookbook you own, on your device, is a real differentiator for a one-time purchase.
7. **Reliable recipe import from the web.** Broken at SideChef for years; users named Copy Me That as the escape hatch specifically for this.
8. **Household sharing.** Asked for since 2017, never shipped.

### How not to lose your rating — rules from SideChef's mistakes

1. **Never advertise a feature that only works in one country.** SideChef sells one-click grocery checkout in every screenshot, then admits "(U.S. only)" in the body text. If a feature is regional, gate the *marketing*, not just the button — or European users will rate the disappointment, not the app.
2. **Metric is not a toggle, it is a first-class unit system.** "237mL of rice" and "0.9kg" cost more stars than having no conversion at all. A broken conversion says the app was not built for you. Get grams, millilitres, and Celsius right at the recipe-data level, not with a display-time multiplier.
3. **Never lose a user's saved data. Not in a migration, not in an update, not once.** SideChef's most furious reviews across twelve years are all data-loss reviews. Their own migration notice said "your existing recipes will not be transferred" — and that sentence is still generating 1-star reviews three years later. Migrations either carry the data or do not happen.
4. **If you ask for a preference, honour it everywhere.** Asking for allergies and then recommending those allergens is worse than not asking. It converts a neutral first session into a 1-star and an uninstall — and with allergens it is a safety issue, not a UX one.
5. **Don't put a feature behind a paywall after people already have it.** The 2026 anger is specifically that a subscription *appeared*. Whatever we sell for $25 must be the whole thing, permanently. Adding a second paywall later would cost more than it earns.
6. **Don't demand an account before delivering any value.** Forced signup is a recurring 1-star trigger. Let people cook first; ask for an account only when they want sync.
7. **Ask for the minimum permissions, and never a scary one at signup.** A cooking app asking for phone contacts produced the single most-upvoted critical review of the 2017 era and an explicit GDPR accusation. Every permission needs a sentence of justification the user would accept.
8. **Ship a working account-and-data deletion path, visible in the app.** Absent deletion generates both 1-star reviews and EU legal exposure. In Norway/EEA this is not optional.
9. **Don't let a commercial partner become the interface.** "This app feels like one big giant walmart ad" — an exclusive integration that reshapes the product is perceived as the product being sold out from under the user. If we ever add commerce, it stays optional and secondary.
10. **Silence reads as abandonment.** Eighteen months without a release, on an app still wearing a 2017 award badge, while the paywall tightens. Users notice the direction of travel. A small, visible, regular release cadence is itself a trust signal.
11. **Never let core reliability slip.** Crashes and slow loads dragged whole years (2017, 2020) below 4.0 on their own. No feature recovers a rating that "the app won't open" is destroying.
12. **Fix the top complaint before building the next feature.** SideChef shipped RecipeGen AI, barcode scanning, a widget, and smart-appliance control while the vegetarian filter still returned chicken. Users score the gap between what you promise and what works — not the length of the feature list.

---

## Sources

- Google Play listing and localized ratings (US/GB/DE/SE/NO/IS): https://play.google.com/store/apps/details?id=com.sidechef.sidechef — observed 2026-09-01
- Google Play review corpus (1,632 text reviews, 2014-11-11 → 2026-08-30), retrieved from Play's own `batchexecute` review endpoint for `com.sidechef.sidechef` via the listing page above
- Apple App Store (US): https://apps.apple.com/us/app/side%D1%81hef-easy-cooking-recipes/id905229928 — 4.7, ~1.7K ratings; full version history
- Apple lookup API, per-storefront ratings: https://itunes.apple.com/lookup?id=905229928&country=de (also `gb`, `us`)
- SideChef, "BudgetBytes App Termination", 2023-06-19: https://www.sidechef.com/articles/1666/bb-app-termination/
- SideChef Premium: https://www.sidechef.com/premium/ and https://www.sidechef.com/faq/
- SideChef GDPR representative (site footer): https://gdpr-rep.eu/q/11973578
- Budget Bytes app (delisted July 2023): https://www.appbrain.com/app/budget-bytes-easy-recipes/com.sidechef.sidechef.partner.budgetbytes
- `[SECONDARY]` Comparably NPS and customer-service score: https://www.comparably.com/brands/sidechef
- `[SECONDARY]` Trustpilot (1 review only, positive): https://www.trustpilot.com/review/www.sidechef.com
- `[SECONDARY]` JustUseApp review aggregation: https://justuseapp.com/en/app/905229928/sidechef-recipes/reviews
- `[SECONDARY]` AppGrooves negative-review aggregation: https://appgrooves.com/app/sidechef-step-by-step-cooking-by-sidechef-holdings-limited-1/negative
