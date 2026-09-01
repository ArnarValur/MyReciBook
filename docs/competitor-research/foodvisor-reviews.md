# Foodvisor — Reviews, Complaints & Unmet Needs

_Researched: 2026-09-01_

> **Package-name correction:** the brief specified `com.foodvisor.foodvisor`. The live Play package is **`io.foodvisor.foodvisor`**. (`com.foodvisor.Foodvisor` is the *iOS* bundle ID.) Verified on the Play listing and via Apple's lookup API.
>
> **Scope:** this document covers sentiment only — ratings, praise, complaints, churn, feature requests, localisation, trust signals. Features and pricing mechanics are a separate agent's brief; pricing appears here only where users complain about it.

---

## 1. Rating distribution

All figures observed **2026-09-01**. App version 9.22.0, shipped 2026-08-27; Play listing updated 2026-08-26.

### Google Play (US storefront, English)
`https://play.google.com/store/apps/details?id=io.foodvisor.foodvisor`

| | Count | Share |
|---|---:|---:|
| 5★ | 157,625 | 80.9% |
| 4★ | 23,071 | 11.8% |
| 3★ | 6,255 | 3.2% |
| 2★ | 2,894 | 1.5% |
| 1★ | **4,866** | **2.5%** |
| **Total** | **194,711** | |

Headline: **4.7★, "196K reviews", 10M+ downloads.** Badged **"Contains ads"** and "In-app purchases".

The shape worth noting: **1★ outnumbers 2★ by 1.7:1.** A quality-drift problem produces a smooth tail; a billing-and-dark-pattern problem produces a spike at the bottom. Foodvisor has the spike. The negative tail is small (4.0% at 1–2★) but it is angry rather than disappointed.

### Apple App Store (Apple lookup API, per storefront)
`https://itunes.apple.com/lookup?id=1064020872&country=XX`

| Storefront | Ratings | Average |
|---|---:|---:|
| US | 17,124 | 4.59 |
| SE | 1,844 | 4.47 |
| NO | 1,645 | 4.54 |
| DK | 1,639 | 4.38 |
| FI | 1,381 | 4.38 |
| IS | **9** | 4.56 |

### Trustpilot
`https://www.trustpilot.com/review/foodvisor.io` — **4.8★, 4,872 reviews**; 92% 5★, 5% 4★, 2% 1★; 3,771 reviews in the last 12 months. Profile claimed **May 2025**. See §7 — Trustpilot's own banners qualify this number.

### Recent trend
Play does not publish a time series, so this is a **qualitative read of the review stream, not a computed trend**. Direction: the lifetime average is stable, but reviews from **June–August 2026 carry three complaint types that do not appear in 2024–early-2025 reviews at all**:

1. **Ads arrived in the free tier** (first flagged Play, 2025-08-14). "No ads" is now listed as a Premium benefit on both stores, and Play badges the app "Contains ads."
2. **Forced gamification screens** after a 2026 update (Play, 2026-06-23).
3. **Explicit dark-pattern accusations** about onboarding (Play, 2026-08-21; 2026-08-30).

So: satisfaction with the *core product* is holding; friction added for *monetisation* is generating fresh anger. The 1★ spike is being fed from the monetisation side, not the nutrition side.

---

## 2. What people love

Ranked by recurrence across Play, App Store, Trustpilot and Reddit.

**1. Speed and low friction of logging — the dominant positive.**
- "I like the food diary. It's fast and easy to add food" — Play, 2024-11-25
- "its fun and easy to understand and use" — App Store, via justuseapp
- "it's the app I've tried that has the best free version" — r/diet, 2026-07-17

**2. The daily lessons / classes — praised more often than the AI camera.**
- "I love the little 2-minute eLearning it prompts you to do." — r/diet, 2026-01-15
- "The daily classes, instant meal ratings" — App Store, via justuseapp
- "The coaching sessions have really helped me" — Trustpilot, 2026-08-09

**3. Real, reported weight-loss results.** The most emotionally durable praise category.
- "I'm 25 pounds down and living an overall healthier lifestyle" — Play, 2025-06-22
- "Been using it for 5 months now and I'm 8kg down." — r/diet, 2025-07-07
- "I reached my target weight and have maintained it for 6 months" — Play, 2026-08-28

**4. Barcode scanning specifically** — repeatedly named as the part that *works*, in explicit contrast to the camera.
- "Food is usually easy to find by bar code scan or search" — Play, 2025-03-18
- "I like the ease of scanning a meal or barcode" — Play, 2026-08-04

**5. Gamification (the seed/sprout pet, streaks, quests)** — genuinely loved by a subset, actively hated by another (see §3.7).
- "The mini quests, keeping up a streak, and the 'sprout' are fun extras." — Trustpilot, 2026-08-31
- "The emoji /color rating on food game-ify's it which is fun" — r/diet, 2025-02-17

**6. Depth of nutrition data beyond calories** — micronutrients, vitamins, minerals.
- "this helps me figure out what nutrients I need" — Trustpilot, 2026-08-28
- "This app has a LOT of nutrition info - LOVE!" — Play, 2025-07-26

**7. Price — but only at the discounted rate.** Nobody praises list price; everyone praising price got a deal.
- "I paid about $27 for the year and I think that's fully worth it." — r/diet, 2026-01-15
- "snill pris" ("kind price") — Play NO, 2026-04-27

**Contradiction worth carrying forward:** a minority praise the database — "it has a huge database of foods so journaling is easy" (App Store, via justuseapp) — while the majority attack it (§3.2). Both are true: coverage is good for packaged European supermarket goods and bad for fresh food, home cooking, and non-European restaurant items.

---

## 3. What people hate

### 3.1 AI photo recognition fails — and it is the feature they paid for (#1 complaint)
- "the picture recognition to be very unreliable and almost always requires modification" — App Store, via justuseapp
- "The AI doesn't recognize the food. Too many foods are not listed." — r/diet, 2025-01-25
- "Anything brown seems to be fried. Meats are not recognized." — r/diet, 2025-01-25
- "Photographic search is about 50/50, but good for what it is" — Play, 2025-03-18
- "Il reconnaît jamais les aliments après photo" ("it never recognises food after a photo") — Trustpilot FR, 2026-05-29

**The sharper sub-complaint is portion estimation, not identification.** Correcting the AI's guessed quantity takes longer than typing the food in:
- "it suggests quantities that are not applicable" — r/diet, 2025-01-25
- "Vous ne gagnerez pas de temps avec, vous en perdez énormément à corriger" ("you won't save time, you lose enormous time correcting") — Trustpilot FR, 2026-05-29
- "Need a way to be able to add something manually" — App Store, via justuseapp (butter on the plate went undetected)

### 3.2 Wrong nutrition data and a crowdsourced database that poisons itself
- "90% of the food items I scanned via barcode showed completely inaccurate nutritional values" — Trustpilot, 2025-09-15 (same barcodes reportedly correct in other apps)
- "a jr frosty at Wendy's is not 0 calories" — Play, 2025-08-14
- "die vielen Nahrungsmittel mit 0 kcal wurden vermutlich von Nutzern eingetragen" ("the many foods with 0 kcal were probably entered by users") — App Store DE, 2025-10-29
- "for serious calorie counters the database may be small and inaccurate too often" — App Store, via justuseapp
- "At least 50% of barcodes are unrecognized." — App Store, via justuseapp

Most damning because it comes from a **5-star** reviewer: "there are many items with different calorie totals than on the actual items" / "I double check everything now." — Trustpilot, 2026-08-29. When your fans have to double-check your numbers, the number is not the product.

The community diagnosis is that user-submitted entries are the rot, and the fix is undiscoverable: "Check for the blue checkmark when you select foods tho" — r/diet, 2025-02-17.

### 3.3 You cannot edit what you ate — the single highest-voted complaint found
Play's most-upvoted critical review (332 helpful):
- "you can not edit the amounts you've eaten" — Play, 2025-07-26
- "there isn't a way to directly edit the calories of a food" — Play, 2025-10-14 (a milkshake logged as 0 kcal, unfixable)
- "I can't manually write the calories for food" — App Store, via justuseapp
- "There is no clear edit button after adding an item." — App Store, via justuseapp
- "Appen lar deg ikke endre porsjonsstørrelsen" / "Da blir hele regnestykket feil." ("The app won't let you change the portion size" / "Then the whole calculation is wrong.") — App Store NO, 2025-06-27
- "the search algorithm is AWFUL at finding items by using keywords" — Play, 2026-04-09
- "It's just a flat list. You can't go back to edit favorites." — Play, 2025-03-18

### 3.4 Subscription, billing, trial traps, refund refusal — the loudest emotional cluster
This is what produces the word *scam*.

**Monthly-looking price, annual charge.** Note that Foodvisor's own App Store description states *"The auto-renewing subscription is billed monthly"* — directly contradicted by user experience across at least five countries:
- "it turned out to be something you had to pay yearly" — Play, 2026-08-30
- "Straight away the monhly fee paid for 1year." — Trustpilot (BE), 2026-03-04
- Chose "€3.99/month", debited €47.99 — Trustpilot FR, 2026-04-07
- "signed me up for annual recurring as the only subscription" — r/diet, 2025-01-25

**Trial-to-paid conversion.**
- "billed for a $60 yearly subscription before my reminder went off" — App Store, via justuseapp
- "when I signed up for my free trial, I was automatically billed" — r/diet, 2024-08-11
- On Foodvisor's suggested workaround: "I needed to lie to Apple and tell them a child purchased it" — r/diet, 2024-08-11

**Refund refusal, including inside the stated window.**
- "Getting a refund for premium is difficult even if you have had it" — App Store, via justuseapp
- "I was advised during the sign-up that there was a 14 day withdrawal period." — Trustpilot (GB), 2026-07-22 — cancelled minutes after signing up, refund denied
- "Terms and conditions say I have 14 days to change my mind." — Trustpilot (IT), 2025-03-20
- "It's really frustrating and feels like a scam." — r/diet, 2026-06-07

### 3.5 Support is a bot, and it does not resolve anything
- "the support is sending me in circles and is all made by AI" — r/diet, 2026-06-07
- "I have heard from others there is virtually no support" — App Store, via justuseapp
- "Service client inexistant" ("customer service non-existent") — Trustpilot FR, 2026-05-05
- "Par contre ils prennent bien la carte bleue." ("They take the bank card just fine, though.") — Trustpilot FR, 2026-02-02

Trustpilot's own profile banner states the company **"Hasn't replied to negative reviews."** Meanwhile every Play developer reply observed is templated and reads as AI-generated — warm, non-committal, and identical in structure across praise and complaint.

### 3.6 Paywall placement and onboarding dark patterns (sharply worse in 2026)
- "every deceptive, manipulative app practice is present here" — Play, 2026-08-21
- "rejecting premium brings up a rigged wheel" — Play, 2026-08-21 (also describes fake loading screens and an expiry timer)
- "A lot of paywalls that they don't warn you about" — Play, 2026-08-30
- "it will prompt you to pay the full amount multiple times" — r/diet, 2026-04-24
- "the app had me spin a wheel for a 75% off offer" — r/diet, 2026-07-01
- "there's no free version at all anymore" — r/diet, 2026-07-01
- "the 'limited time discount' is the same offer from day 1-256" — Play, 2025-08-14
- "Il faut au moins 30mn pour s inscrire" ("It takes at least 30 min to sign up") — Trustpilot FR, 2026-08-14

### 3.7 Ads in the free tier, and forced gamification — both are 2025–26 regressions
**Ads** (confirmed by the Play "Contains ads" badge and "No ads" as a Premium bullet on both stores):
- "New update of the app added ads to the free version" — Play, 2025-08-14 — with the specific grievance that video ads autoplay **with sound** in a previously silent app.

**Gamification made mandatory:**
- "you have to sit through two additional screens every time you log" — Play, 2026-06-23
- "People have asked for a way to turn it off for months" — Play, 2026-06-23
- "it means nothing to me to see the number of days in my streak" — Play, 2026-08-04
- "why the hell do I need streaks let alone streak freezes for a nutrition app" — Play, 2026-08-21

### 3.8 Recipes and batch cooking are effectively broken
This is the section most directly relevant to MyReciBook.
- "id rather not track my food at all - too much effort" — Play, 2025-11-05 — a user who cooks 12-quart pots of soup and cannot log one serving of a large recipe
- "I wish it let us add recipes more easily" — Play, 2025-04-28 — adding ingredients one by one is the only accurate method
- "it's also annoying you can't copy meals from one day to another" — Play, 2026-08-02
- "I haven't found a way to copy a previous day's meal or food" — Play, 2026-08-04
- "would like a way to copy food or meal to paste in future journals" — Play, 2026-08-29
- "Recipes in the app have numerous spelling errors" — Play, 2025-04-13

**Meal-copy is requested in three separate reviews within one month (Aug 2026) and remains unshipped.** That is an unusually clean signal.

### 3.9 Opaque food scoring, and eating-disorder risk
- "it's displaying a frowning face emoji for salmon. For salmon???!" — r/diet, 2024-04-08 (the most-repeated single Foodvisor story on Reddit)
- "I can't find any information about how they determine the colors" — r/diet, 2025-04-06
- "probably not good for those with any tendancy toward eating disorders" — r/diet, 2025-02-17
- "recommending I try sea urchins instead of a turkey sandwich" — Play, 2026-08-02

### 3.10 Rigid personalisation that ignores what the user already told it
- "Diets are not one-size-fits-all." — Play, 2025-08-30
- "constantly getting recommended meals that contain them" — Play, 2026-08-11 (allergies, unenterable after onboarding)
- "keeps recommending fasting which is at odds with my medical condition" — r/diet, 2025-01-25 (the condition was entered in the app)
- Premium meal plan groceries: "it came out to $394.22 for ONE WEEK" — Play, 2024-11-25

### 3.11 Sync gaps, data loss, bugs
- "Needs more connected apps other than Google fit, because it sucks" — Play, 2025-04-13
- "You have no way to sync a Fitbit or anything else" — App Store, via justuseapp
- "It doesn't sink with fitbit so I have to use other apps" — Trustpilot, 2025-10-10
- "all the daily totals are wrong and some meals are messed up" — App Store, via justuseapp (after logging out and back in)
- "App crashes when you try to edit a food by adding a photo" — App Store, via justuseapp
- Device migration wiping progress: "I had to start this program all over again" — Trustpilot, 2025-05-17
- "problems with this App locking up and losing entries" — Trustpilot, 2025-08-03

No **offline-mode** or **battery-drain** complaints surfaced for Foodvisor specifically. (Battery is a live grievance in the category generally — aimed at MyFitnessPal, r/caloriecount 2020-08-31.) Marking Foodvisor offline/battery as **[UNVERIFIED — no evidence either way]** rather than clean.

---

## 4. Deal-breakers — the exact moment they quit

Ordered by how often the pattern recurs.

**1. The camera fails on the first two or three meals, and the food goes cold.** Fastest recorded churn is three days:
- "I just gave up after three days" / "Really inconvenient and slow which means cold food" — r/diet, 2025-01-25
- "making my food cold by the time I can eat it!" — App Store, via justuseapp

The mechanism matters more than the complaint: correcting the AI is *slower than typing*, which destroys the entire value proposition rather than merely denting it.

**2. The trial converts to an annual charge.** The single most common trigger for the word "scam" (§3.4).

**3. Refund refused, then support turns out to be a bot.** This is the step that converts a churned user into a *public warning-poster* — the difference between losing one user and losing the ones who read the review.

**4. A structural blocker hits their actual cooking pattern.** Batch cooking, custom recipes, portion editing (§3.3, §3.8): "id rather not track my food at all" — Play, 2025-11-05.

**5. Reputation pre-kill — they never install.** One Reddit user read the complaint thread and stayed on MacroFactor: "I can confirm they are appealing to laziness" — r/diet, 2024-10-30.

**6. Sunk-cost captivity (not churn, but not loyalty either).** A distinct group keeps using it and resents it: "I just keep using it now because I already paid for it" — Trustpilot, 2026-01-27; "won't be renewing my membership" — Play, 2026-08-02.

### Where they go instead

Named by Foodvisor-context users: **MyFitnessPal** (≈3), **Yazio** (≈3), **Cronometer** (≈2), **MacroFactor**, **Welling**, **Trainest**, **FoodNoms**, **SnapCalorie**, **Lose It!**, **Easy Diet Diary** (AU), **Plan to Eat** (recipe/grocery side).

Category-wide destination counts, tallied by the Reddit sub-agent across ~467 comments in six generic "which tracker?" threads (directional only): MyFitnessPal ~64, Lose It ~37, Cronometer ~28, Simple ~14, Lifesum ~13, MyNetDiary ~13, Fitbit ~13, MacroFactor ~12, Yazio ~9, Nutracheck ~5.

**MyFitnessPal is simultaneously the default and the most resented** — most of those threads exist *because* MFP paywalled barcode scanning. That is the real incumbent to displace, and it is displaceable.

---

## 5. Feature requests — everything users ask for and are not getting

The highest-value section. Grouped, deduplicated, each traceable to a cited source above.

### Logging and editing (the biggest cluster)
1. **Edit the amount you actually ate** — portion, grams, count. Highest-voted complaint anywhere (Play, 332 helpful).
2. **Directly overwrite a food's calorie/macro values** when the database is wrong.
3. **Copy a meal or a whole day forward** — requested three times in Aug 2026 alone, unshipped.
4. **Log by count, not only grams** ("3 pieces") — App Store US, 2024-04-23.
5. **Sub-15 ml liquid entry.** Verified: "the smallest amount Foodvisor will let you use is 15ml" — App Store, via justuseapp. Blocks logging a quarter-teaspoon of anything.
6. **Sodium in mg, not grams**, on US labels — App Store US, 2024-04-23.
7. **A fixable search** — multi-keyword matching, not one-or-two-token matching.
8. **Editable, sortable, foldered favourites** — currently a flat chronological list that cannot be edited in place.
9. **Community-editable database entries, wiki-style**, to fix bad crowd data — Play, 2026-04-09.
10. **Surface verified entries by default** instead of hiding the trust signal behind a blue checkmark nobody finds.
11. **Manual add for items the camera missed**, without faking the quantity of something else.
12. **"Snap now, analyse later"** — capture the photo instantly, resolve the calories after the meal. Explicitly framed by users as the fix for cold food.
13. **A photo journal that keeps the images** as a mindfulness artifact, decoupled from the calorie math.
14. **Voice logging** — *now shipped* (both store listings advertise it as of Aug 2026); noted because it was a standing request.

### Recipes, batch cooking, groceries — MyReciBook's home turf
15. **Enter a full recipe at batch scale and log one serving of it.** The 12-quart-soup problem. Currently the reason at least one user abandoned tracking entirely.
16. **Fast recipe creation** — not ingredient-by-ingredient re-entry each time.
17. **Ingredient-level meal variants** (omelet with vs. without cheese).
18. **Proofread recipe content** — spelling errors confuse ingredients and measurements.
19. **Meal plans costed against a real budget** — not $394/week.

### Personalisation
20. **Edit allergies, dislikes and preferences after onboarding.** Currently apparently impossible; users get recommended their own allergens.
21. **Honour declared medical conditions** — stop recommending fasting to someone who said they cannot fast.
22. **Fully custom goals** for users with a clinician-set plan: "Diets are not one-size-fits-all."
23. **Split carbohydrate quality** (simple / fibre / whole grain).
24. **Distinguish good vs. bad fats and cholesterol** — Play, 2025-04-28.
25. **Turn the food-judging emoji/colour system off**, and **document how it is computed**.
26. **Non-binary / prefer-not-to-say** in the sex field — App Store, via justuseapp.
27. **Locale-appropriate coaching content** as a setting (French-origin lessons read as strange elsewhere — see §6).

### Integrations and platform
28. **Fitbit and Garmin sync.** The most-repeated integration ask; currently Apple Health (iOS) and Google Fit (Android) only.
29. **Android Health Connect / Samsung Health write-back** — a persistent unmet Android demand across the category.
30. **Manual entry of burned calories** for users without a supported wearable.
31. **Exercise calories should affect the daily allowance** — Play, 2026-08-09.
32. **Dark mode.** The single most concrete missing feature named anywhere: "there is no dark mode in a era of dark mode phones" — Trustpilot, 2025-05-25.
33. **A desktop or web version.**
34. **Reliable account restore across devices** — migration currently wipes progress.
35. **Configurable reminder times** — notifications currently fire when the user is not eating.
36. **A useful widget** — calories remaining in large type, not a streak counter.

### Product conduct
37. **A genuinely functional free tier**, and an honest per-tier feature matrix. Users cannot tell what they bought.
38. **Transparent pricing instead of the discount wheel**, with monthly billing that is actually monthly.
39. **A human support channel.**
40. **Skippable lessons** — currently unskippable and repetitive.
41. **Opt-out of gamification screens** — asked for repeatedly over months, explicitly ignored.
42. **Stop deactivating paid accounts for inactivity** — Trustpilot FR, 2026-06-05.
43. **Honour the referral reward** — "invite a friend and get 20£" reported as not paying out (EN 2025-11-19; FR 2026-08-04).
44. **State uncertainty honestly.** Users across the category *praise* apps that admit an estimate is an estimate — "they make it clear that it's an estimate" (r/Myfitnesspal, 2024-07-29) — and punish apps that present a guess as a fact. This is the cheapest trust win available in the entire category and nobody in it is taking it.

---

## 6. Non-US / European experience

Foodvisor is a French company (Foodvisor SAS, Paris). Localisation is broad but shallow.

### Store listing localisation is broken in the Nordics — verified first-hand
Apple's lookup API, queried per storefront on 2026-09-01, returns the **en-GB** listing by default to the **Norwegian, Danish, Finnish and Icelandic** storefronts. That listing advertises weight loss as **"1 stone 1.8 lb"** — a unit used nowhere in the Nordics. The same claim renders "7,18 kg" in Swedish and in the force-localised Norwegian variant, and "15.83 lb" in the US.

The Norwegian assets exist (`&lang=nb_no` returns a full Norwegian listing). They are simply not what the store serves. **Sweden is the only Nordic storefront defaulting to its own language.** Google Play is better localised than Apple here — the Norwegian Play listing is fully Norwegian.

### Language support
20 in-app languages (CS, DA, NL, EN, FI, FR, DE, EL, HU, IT, JA, KO, **NB**, PL, PT, RU, ZH, ES, SV, TR). **No Icelandic.**

The help centre — which is where the refund and cancellation terms live — exists in **five languages only**: English, German, Spanish, French, Portuguese (BR). A Norwegian, Swedish, Danish, Finnish, Dutch, Italian or Polish user must read the terms governing their money in a foreign language.

### Local food databases
The most consistent non-US complaint, in every language checked:
- "può essere migliorato il database dei cibi, spesso hanno nomi esteri" ("the food database could be improved, they often have foreign names") — App Store IT, 2024-10-14
- "i consigli culinari non si adattano benissimo a ciò che troviamo nei nostri supermercati" ("the food advice doesn't fit what we find in our supermarkets") — App Store IT, 2026-08-17
- "el escáner no acierta ni una, confunde el 100% de las fotos" ("the scanner never gets one right, confuses 100% of photos") — App Store ES, 2024-09-20
- Mirror-image complaint from the US: "the quick find option is also awful if you are an American" and "it was fully based more for European input" — App Store, via justuseapp

Restaurant and canteen logging is weak in every market. Germany's heise.de test frames it as the category's core unsolved problem — canteen food "muss man ohnehin mühselig aus einzelnen Zutaten zusammenbasteln" ("you have to laboriously cobble it together from individual ingredients").

### Units — the complaint runs in both directions
US users are angry it is metric-first ("The only option for serving size is grams"); the Nordic storefronts are served imperial marketing copy. Neither audience is served correctly. The 15 ml minimum liquid unit (§5.5) hurts everyone.

### Norway and the Nordics specifically
Real usage, almost no discourse. Play NO is the richest source:
- **The single best Nordic localisation datapoint:** the app scolds a user for a classic Norwegian meal — "to-tre grove knekkebrød med lett ost og lett salami og agurk" (two or three wholegrain crispbreads with light cheese, light salami, cucumber) — while she is *under* her calorie target. Her verdict: "Appen er alt for streng og gir tilbakemelding på at man må begrense" ("The app is far too strict and gives feedback that you must restrict") — Play NO, 2026-06-16. **The colour-scoring logic mis-scores a Nordic staple**, probably on salt.
- "oppskriftene som følger med er ofte ikke helt som jeg er vant med" ("the recipes it comes with are often not quite what I'm used to") — Play NO, 2026-08-11
- "Litt rare matanbefalinger" ("Slightly strange food recommendations") — Play NO, 2026-08-15
- "savner å kunne redigere på mengden" ("miss being able to edit the quantity") — Play NO, 2026-07-10

**Stated plainly, because absence is the finding:** zero Nordic reviews on Trustpilot across both language views. No Norwegian, Swedish, Danish, Finnish or Icelandic press review, blog test or forum thread found. **No mention anywhere, in any language, of Tine, Rema 1000, Kiwi, Coop, Bama or Q-Meieriene** in relation to Foodvisor's database — Norwegian barcode and brand coverage is **untested and unreported**, neither confirmed good nor bad. Iceland has **nine ratings total**, no Icelandic, and is billed in USD — effectively a non-market.

### EU pricing
Foodvisor refuses to publish a price. Its own help centre: "C'est pourquoi nous ne pouvons pas afficher un prix fixe universel." ("That is why we cannot display a fixed universal price.")

Observed annual figures within ~18 months: **€23, €47.99, €59.99, £59** — plus one **€59.99 per quarter**. No user complaint alleging "cheaper in the US" was found, and the secondary US figures contradict each other; what *is* evidenced is **intra-EU price incoherence**.

The dominant French pricing grievance is not the amount but the **TV advertising**, which multiple users say presents the app as free:
- "Grosse arnaque la pub tv vous vend une application" ("Huge scam, the TV ad sells you an app") — Trustpilot FR, 2026-07-14, with a call for a DGCCRF inspection
- "Foodvisor fait de la publicité à la TV en mettant en avant la gratuité" ("Foodvisor advertises on TV pushing the free aspect") — Trustpilot FR, 2026-07-09

### GDPR and data handling
From Foodvisor's own documents: data stored in EU databases; full GDPR rights offered via `data@foodvisor.io`; **stated processing purposes include "Profiling and targeted advertising"** alongside health and nutrition data. Apple's privacy label declares **Health & Fitness data Linked to You** and **Identifiers Used to Track You** across other companies' apps. Play's data-safety card declares sharing of personal info and messages with third parties.

**The account-deletion trap, confirmed as Foodvisor's own published policy:** *"Deleting your account in Foodvisor settings does not automatically cancel your Premium subscription."* This is the worst possible combination — a user exercises their GDPR erasure right, loses the account, keeps paying, and has no in-app record left to argue from.

**Policy text diverges between language versions.** The English refund policy contains "Renewal charges aren't eligible for a refund"; the French version of the same article ID, same update date, omits it.

**No regulator has acted.** No CNIL, Datatilsynet, AEPD or Garante decision, no complaints-board case, no class action found in any jurisdiction. Two users *threaten* consumer authorities; none has filed.

### EU refund friction
Foodvisor grants EU residents the 14-day withdrawal right in writing. Users in **GB, IT, FR, BE, NL** report invoking it and being refused — in one case after cancelling *minutes* after signing up. Two users in two member states independently report advertising that promised **"money back if not satisfied after 30 days"** against a published 14-day policy. Platform ping-pong is common: Foodvisor points to Google, Google says the developer is responsible.

---

## 7. Trust and safety signals

Reported evenhandedly. Accusations are labelled as accusations.

**Trustpilot profile shape — an observation, not an accusation.** 4,872 reviews at 4.8★, 92% five-star, 3,771 in the last 12 months, profile claimed **May 2025** with the volume appearing after. Trustpilot's *own* banners on the profile read **"No recent history of asking for reviews — this company hasn't invited customers recently, so reviews may not be representative"** and **"Hasn't replied to negative reviews."** Every review carries the "Unprompted review" label. The 4.8 also sits well above both app stores (4.7 Play, 4.59 iOS US) despite Trustpilot normally skewing *negative* for consumer apps. That combination is unusual and the 4.8 should not be quoted as an independent quality signal without this context. **[UNVERIFIED — no evidence of manipulation was found; this is a pattern note only.]**

**Review-gating accusation.** One App Store reviewer alleges being blocked from posting a low-star review: "Tried to share a 1-2 star but Foodvisor won't allow it" — attributed to a nickname-taken loop. **Single report, uncorroborated. [UNVERIFIED]** — the mechanism described is a normal App Store nickname collision, and I found no second instance.

**Misleading-marketing accusations — the best-corroborated trust problem.** Three independent strands:
1. **French TV advertising** presented as offering a free app — six or more separate Trustpilot FR reviews, mid-2026.
2. **"30-day money back"** advertised against a published 14-day policy — reported by users in Belgium and Italy independently.
3. **Monthly price displayed, annual charge taken** — reported across FR, BE, NL, GB and US, and contradicted by Foodvisor's own App Store text, "The auto-renewing subscription is billed monthly."

**Onboarding dark patterns — described concretely rather than vaguely.** Fake loading screens between survey sections, a countdown timer on the offer, and a discount wheel that lands on what users believe is the real intended price: "rejecting premium brings up a rigged wheel" (Play, 2026-08-21); "the app had me spin a wheel for a 75% off offer" (r/diet, 2026-07-01); "the 'limited time discount' is the same offer from day 1-256" (Play, 2025-08-14).

**Health-claim concerns.** The advertised "average weight loss of 15.83 lb in 3 months" is footnoted as an **internal study on 4,419 users, January 2026, average BMI 34.72** — self-reported, unpublished, not peer-reviewed, and drawn from an obese-average cohort whose results will not generalise. Separately, users report macro targets they consider unsafe ("It recommend me to eat a TON of carbs and very few proteins" — App Store, via justuseapp) and a 600 kcal deficit assigned to someone who asked for slow loss (r/diet, 2025-08-02). The app is listed under **Medical** as a secondary App Store category.

**Eating-disorder risk** is raised unprompted by users regarding the emoji/colour food-judging system (§3.9). Not an accusation of harm; a repeated concern.

**Data-privacy incidents:** none found. No breach, no enforcement action, no reported data-request refusal in any jurisdiction.

**One serious individual allegation, uncorroborated:** a paid annual account disabled for insufficient use, with reactivation requiring re-payment — "6 mois volés" ("6 months stolen"), Trustpilot FR, 2026-06-05. **[UNVERIFIED as a general practice — single report.]**

---

## 8. What this hands us

### A. Neutralise by design — cheap for us, structurally hard for them

**1. Editing is a right, not a feature.** Their highest-voted complaint is that you cannot change what you ate. Every number in MyReciBook must be tappable and overwritable — portion, unit, count, calories, macros — with no "validate" ceremony in the way. This is a UI decision, not an engineering problem, and it beats their single loudest grievance.

**2. Batch cooking and serving-splitting as a first-class primitive.** "Cook 12 quarts, log one bowl" made a user abandon calorie tracking altogether. We are a *recipe* app with nutrition attached — the recipe is already the unit. This is our natural advantage over every tracker-first competitor, and Foodvisor cannot retrofit it without rebuilding their data model.

**3. Copy a meal or a day forward.** Requested three times in one month and still unshipped. Trivial for us.

**4. Units that respect the user.** Metric and imperial as a real toggle; grams, millilitres, cups, spoons and counts all first-class; arbitrary precision (no 15 ml floor); sodium in mg. Norway-first defaults, since that is where Arnar is.

**5. Say when you are guessing.** Users across the category explicitly praise apps that label an estimate as an estimate. Show a confidence state on any AI-derived number and a one-tap correction. Nobody in this category does it. It is nearly free and it buys the trust their whole model is leaking.

**6. Verified vs. crowd data, visibly separated.** Their database is poisoned by 0-kcal user entries and the trust signal is hidden behind an undiscoverable checkmark. Ours should show provenance on the row, by default.

**7. Preferences and allergies editable forever.** Getting recommended your own allergen is an unforced error we simply never make.

**8. No forced ceremony between the user and a logged meal.** No gamification interstitials, no streak screens, no ads with sound. If we ship gamification at all, ship the off switch in the same release.

**9. Dark mode at launch.** The most concrete unmet ask in their entire review corpus.

**10. Health Connect / Samsung Health / Fitbit / Garmin.** Their Android integration is Google Fit only and users call it out by name.

**11. Local food data as a differentiator, not an afterthought.** Nordic barcode and brand coverage is *unreported* for Foodvisor — nobody has tested Tine, Rema 1000, Kiwi or Coop against it. That is an unclaimed position, not a crowded one. It also fixes the deeper bug their Norwegian user found: scoring logic that calls a normal Norwegian crispbread lunch excessive.

**12. Proofread content and honest recipe metadata.** Low glamour, repeatedly complained about, free to get right.

### B. Structural to their model — where a one-time ~$25 price wins outright

**13. The entire billing grievance disappears.** Trial traps, monthly-price-annual-charge, refund refusal, the 14-day window, deleting-your-account-still-charges-you, platform ping-pong, accounts deactivated for inactivity — every one of these is a *subscription* artifact. We do not have to solve them; we have to not have them. This is the largest single opening, and their 1★ spike (1★ outnumbering 2★ 1.7:1) is exactly where it shows up in the numbers.

**14. No ads, ever — and it is credible from us.** They added ads to their free tier in Aug 2025 and now sell "No ads" as a Premium bullet. A paid app has no reason to run ads and no incentive to add them later.

**15. No dark patterns, because there is nothing to upsell.** No discount wheel, no countdown timer, no fake loading, no thirty-minute onboarding gauntlet. Show the price once, take the money once. Their onboarding is now generating "every deceptive, manipulative app practice is present here" from Play reviewers — that sentence is our positioning brief written by their own users.

**16. AI cost discipline is their permanent tax and our design constraint.** Photo recognition is expensive per call, which is precisely why it must sit behind a recurring charge for them. Anything we do with AI has to be sized to a one-time price — which pushes us toward barcode, structured recipe data and local databases as the *primary* paths, with AI as assistance. That is not a compromise: **their own users say the camera sells the app but does not retain them**, and that barcode scanning is the part that actually works.

**17. Support that answers.** Their support is an AI bot that users say sends them in circles, and Trustpilot flags that they do not reply to negative reviews. A solo developer answering email within a day is a genuine competitive advantage here, and a one-time purchase makes the support load finite and predictable.

### C. The standing objection we must pre-answer

From r/ios, the top reply to a one-time-purchase thread: **"they'll eventually switch to a subscription model too and I won't get future updates."** Reddit does not believe one-time pricing survives. Address it explicitly and in writing at the point of sale — what the $25 covers, for how long, and what happens if the model ever changes.

Two further cautions from the same research:

- **The real price anchor is not their list price.** Determined users report paying **$5, €10, $23, $24, $27 per year** by refusing the upsell until the discount wheel appears. Our $25 must beat *that* number in the user's head, not the €59.99 sticker. The consolation is that the mechanics producing those prices are exactly what generates the anger we are exploiting.
- **Do not market in these subreddits directly.** The astroturf immune response is fast and explicit — "nice try cal AI agent" is a real reply to a positive app comment, and a Swedish commenter answered a positive Foodvisor post with "Låter inte alls som reklam.." ("doesn't sound like an ad at all"). Earn mentions; do not plant them.

---

## Sources

**Primary — store and platform data (all observed 2026-09-01)**
- Google Play listing, ratings histogram and review stream — https://play.google.com/store/apps/details?id=io.foodvisor.foodvisor
- Google Play, Norwegian storefront — https://play.google.com/store/apps/details?id=io.foodvisor.foodvisor&hl=no&gl=NO
- Apple lookup API, US — https://itunes.apple.com/lookup?id=1064020872&country=US
- Apple lookup API, NO — https://itunes.apple.com/lookup?id=1064020872&country=NO (also queried SE, DK, FI, IS)
- Apple App Store, US reviews — https://apps.apple.com/us/app/foodvisor-ai-calorie-counter/id1064020872?see-all=reviews
- Apple App Store, IT — https://apps.apple.com/it/app/foodvisor-contacalorie-e-dieta/id1064020872?see-all=reviews
- Apple App Store, ES — https://apps.apple.com/es/app/foodvisor-contador-de-calorías/id1064020872?see-all=reviews
- Apple App Store, DE — https://apps.apple.com/de/app/foodvisor-ki-kalorien-zähler/id1064020872?see-all=reviews
- Apple App Store, NO — https://apps.apple.com/no/app/foodvisor-ai-calorie-counter/id1064020872
- Trustpilot (EN) — https://www.trustpilot.com/review/foodvisor.io
- Trustpilot (EN, 1–2★ filter) — https://www.trustpilot.com/review/foodvisor.io?stars=1&stars=2
- Trustpilot (FR, 1–2★ filter) — https://fr.trustpilot.com/review/foodvisor.io?stars=1&stars=2

**Primary — Foodvisor's own documents**
- Refund policy (EN) — https://foodvisor.zendesk.com/hc/en-us/articles/7294486891932-Refund-Policy
- Refund policy (FR) — https://foodvisor.zendesk.com/hc/fr/articles/7294486891932-Politique-de-remboursement
- Subscription pricing statement (FR) — https://foodvisor.zendesk.com/hc/fr/articles/26650824663580-Combien-coûte-l-abonnement-Foodvisor
- Personal data handling — https://foodvisor.zendesk.com/hc/en-us/articles/360013674439-How-does-Foodvisor-manage-my-personal-data
- Privacy policy — https://www.foodvisor.io/en/privacy-policy/
- How to cancel — https://foodvisor.zendesk.com/hc/en-us/articles/360013675719-How-to-cancel-my-plan

**Reddit (archived comment bodies via Arctic Shift; reddit.com itself was blocked in this environment)**
- r/diet, the one substantive Foodvisor thread, 59 comments Mar 2024 – Aug 2026 — https://www.reddit.com/r/diet/comments/1bsb8eb/foodvisor/
- r/loseit, photo-calorie apps — https://www.reddit.com/r/loseit/comments/ucbhpy/are_there_any_good_apps_that_you_can_take_pics_of/
- r/loseit, photo-based counting (2016, the origin argument) — https://www.reddit.com/r/loseit/comments/5hxvn5/has_anyone_used_photobased_calorie_counting_apps/
- r/loseit, tracker migration — https://www.reddit.com/r/loseit/comments/xk3stu/what_calorie_counting_app_are_you_moving_to/
- r/loseit, calorie counting apps — https://www.reddit.com/r/loseit/comments/vin5jm/calorie_counting_apps/
- r/loseit, tracking apps — https://www.reddit.com/r/loseit/comments/13uwxr3/searching_for_calorie_tracking_apps_that/
- r/Myfitnesspal, image-based app accuracy — https://www.reddit.com/r/Myfitnesspal/comments/1c21hzg/are_imagebased_calorie_apps_like_cal_ai_accurate/
- r/caloriecount, SnapCalorie accuracy — https://www.reddit.com/r/caloriecount/comments/15po7go/is_snapcalorie_ai_worthy/
- r/caloriecount, one-time-purchase request — https://www.reddit.com/r/caloriecount/comments/ijqc34/is_there_a_one_time_purchase_cc_app_that_runs/
- r/ios, one-time-purchase apps — https://www.reddit.com/r/ios/comments/18sxvuc/must_have_one_time_purchase_apps/
- r/ios, best kcal app — https://www.reddit.com/r/ios/comments/ic8v1e/whats_the_best_food_app_to_count_kcal/
- r/androidapps, best one-time purchase — https://www.reddit.com/r/androidapps/comments/zucr10/whats_the_best_one_time_purchase_application_you/
- r/androidapps, Samsung Health sync — https://www.reddit.com/r/androidapps/comments/mdq562/food_tracking_app_that_syncs_with_samsung_health/
- r/GoogleFit, apps that write to Google Fit — https://www.reddit.com/r/GoogleFit/comments/p5ncw0/which_food_track_apps_write_to_google_fit/
- r/EatCheapAndHealthy, MFP alternatives — https://www.reddit.com/r/EatCheapAndHealthy/comments/wws8ll/any_good_myfitnesspal_alternatives/
- r/CICO, measurement honesty — https://www.reddit.com/r/CICO/comments/1dfpl0m/being_honest_and_accurate_with_measurements/
- r/france, meal-tracking app thread — https://www.reddit.com/r/france/comments/1ca9r04/bonne_appli_suivi_repas_calories_glucides/

**Aggregators and editorial**
- JustUseApp, republished App Store reviews (32 full reviews) — https://justuseapp.com/en/app/1064020872/foodvisor-calorie-counter/reviews
- heise.de, German editorial test (paywalled beyond intro) — https://www.heise.de/tests/Kalorienzaehlen-mit-KI-Foodvisor-im-Test-10195446.html
- Garage Gym Reviews, English editorial test — https://www.garagegymreviews.com/foodvisor-review

**Deliberately excluded:** nutriscan.app, nutrola.app, caloriescanai.com, food-trackers.com and calorietrackerlab.com all rank highly for "Foodvisor review" and are **content marketing published by competing calorie apps**. Their pricing and language-count figures contradict each other and contradict Apple's API. Not used, and not recommended as sources.

**Access limitations, stated plainly**
- reddit.com and old.reddit.com were blocked in this environment. Reddit quotes come from archived comment records (real stored text, not paraphrase), but comment scores are mostly unavailable, so Reddit quotes **cannot be ranked by upvotes**.
- Foodvisor's Reddit footprint is genuinely small — essentially one substantive thread. r/1200isplenty, r/xxfitness, r/intermittentfasting, r/Fitness, r/nutrition and r/EatCheapAndHealthy contained **no Foodvisor discussion at all**. Trustpilot was used to fill the gap and is marked where it does so.
- Play does not publish a rating time series; the "recent trend" read in §1 is qualitative.
- No Nordic-language press, blog or forum coverage of Foodvisor exists to be found; §6 says so rather than padding.
