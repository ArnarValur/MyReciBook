# Mob — Reviews, Complaints & Unmet Needs

_Researched: 2026-09-01_

Scope: user sentiment only (ratings, praise, complaints, unmet needs, the paywall backlash). Features and pricing are covered by a separate agent and are not duplicated here.

**Primary corpus pulled for this report (all observed 2026-09-01):**
- **404 Google Play text reviews** — the complete set Play's review endpoint serves for `com.mob.mobappprod`, 2024-09-11 → 2026-08-31. All four sort orders (newest / helpfulness / rating-high / rating-low) converge on the same 404, so this is the full served corpus, not a sample.
- **205 App Store reviews with dates** across 8 storefronts (GB 50, US 74, CA 38, NL 17, DE 17, IE 7, NO 2) via Apple's public customer-reviews feed.
- **iTunes aggregate ratings for 11 storefronts.**
- **Trustpilot `mob.co.uk`** — 631 reviews, read directly.

Combined analysed corpus: **609 reviews**. Reddit was inaccessible from this environment (blocked at both the fetch and browser layer), so there is no Reddit evidence here — that gap is stated rather than papered over.

---

## 1. Rating distribution and timeline

### Headline numbers (observed 2026-09-01)

| Surface | Rating | Volume | Notes |
|---|---|---|---|
| **Google Play (GB)** | **4.6** | 1,430 reviews, 100k+ installs | Badged **"#1 top grossing food & drink"**. Updated 2026-08-20, v1.24.x |
| **App Store GB** | **4.57** | 3,882 | Home market, largest single pool |
| App Store NL | 4.65 | 139 | |
| App Store DK | 4.62 | 29 | |
| App Store IE | 4.51 | 115 | |
| App Store NO | 4.49 | 37 | |
| App Store AU | 4.44 | 503 | |
| App Store CA | 4.17 | 252 | |
| App Store US | 4.16 | 467 | |
| App Store DE | 4.05 | 133 | |
| App Store FR | 4.03 | 67 | |
| App Store SE | 3.97 | 66 | Lowest storefront measured |
| **Trustpilot (mob.co.uk)** | **4.0** | 631 | 406 in the last 12 months |

**The 4.0 in the brief is the Trustpilot score, not the app store score.** The app stores currently read 4.0–4.6 depending on storefront. Both are real; they measure different things (Trustpilot skews to people with a billing problem or a support interaction).

### Play histogram (Play GB listing HTML, 2026-09-01)

5★ 1,186 · 4★ 112 · 3★ **0** · 2★ 55 · 1★ 55 · total 1,408 · weighted mean 4.65.
`Source: https://play.google.com/store/apps/details?id=com.mob.mobappprod&hl=en_GB&gl=GB`

⚠️ The 3★ bar reading exactly zero is **anomalous** — my own corpus contains 43 three-star text reviews. Treat the individual bar values as approximate. The 5★-heavy shape is not in doubt.

### The gap that matters

| | 5★ | 4★ | 3★ | 2★ | 1★ | Mean |
|---|---|---|---|---|---|---|
| Play **all ratings** (n=1,408) | 84% | 8% | 0% | 4% | 4% | **4.65** |
| Play **text reviews only** (n=404) | 18% | 6% | 11% | 13% | **52%** | **2.26** |
| Trustpilot (n=631) | 61% | 10% | 4% | 2% | **23%** | **4.0** |

**Silent tappers give 5 stars; people who type give 1 star.** Everyone who writes about Mob writes a complaint. This is the single most useful structural fact in the set: the 4.6 is real, and so is the fact that a majority of everyone who bothered to explain themselves was angry. Trustpilot's inverted-J (61% / 23%, almost nothing between) is the same shape.

### Timeline — Play text reviews, monthly mean

| Month | n | mean | 1★ | What was happening |
|---|---|---|---|---|
| 2024-09 → 11 | 6 | ~3.7 | 1 | Launch (iOS released 2024-09-06). "The mob app is finally here!!" |
| 2024-12 | 10 | **1.70** | 7 | **First collapse.** App shipped without meal planner or shopping list |
| 2025-01 | 7 | **1.43** | 5 | Same; login failures for existing web members |
| 2025-02 → 04 | 33 | 2.9–3.2 | 9 | Partial recovery; founder replying personally |
| 2025-05 → 07 | 61 | 2.3–2.7 | 22 | Free-recipe tier **still present** ("a few free recipes", 2025-06-09) |
| **2025-08** | **57** | **1.86** | **34** | **Worst month.** v1.8.8. Hard paywall complete + white-screen launch bug |
| **2025-09** | 31 | **1.71** | 20 | v1.9.x. White-screen peak (7 reports in one month) |
| 2025-10 → 12 | 37 | 1.9–2.2 | 22 | Cancellation/billing anger becomes dominant |
| 2026-02 | 19 | **1.42** | 15 | **Second trough** — trial→annual charge disputes, v1.15 |
| 2026-03 | 22 | 1.64 | 15 | Same, v1.16 |
| **2026-05** | 33 | **3.39** | 11 | **Best month since launch.** v1.19–1.20, features shipping, replies restored |
| 2026-06 → 08 | 48 | 2.2–2.5 | 26 | Settled; white-screen and login reports persist |

**Two distinct collapses, two different causes.** Dec 2024–Jan 2025 was *a shipped product that didn't do what it said*. Aug–Sep 2025 was *the paywall closing and the app breaking in the same month*. The second is the one worth studying.

`Sources: Play review endpoint (raw, 2026-09-01) · https://play.google.com/store/apps/details?id=com.mob.mobappprod`

---

## 2. What people love — ranked

Counts are of the 609-review combined corpus.

### 1. The food itself (59 mentions, 34 from 4–5★ reviewers)
The recipes are the product, and they carry everything. Even 1★ reviewers concede this constantly — "Tasty meals, garbage app" is close to a genre.
- "Haven't had a bad recipe yet" — iOS GB, 2026-07-24, 5★
- "the recipes are insane and the app is so so easy" — iOS GB, 2026-07-09, 5★
- "Genuinely has transformed the way I think about cooking" — iOS GB, 2026-08-14, 5★

### 2. Meal plan → auto shopping list (62 mentions)
The most-named *feature*, and the one that converts people from browsers into subscribers.
- "makes the most tedious part of my week... so much easier" — Play, 2025-11-01, 4★
- "I just enter the ingredients into the Ocado app" — iOS GB, 2026-07-09, 5★
- "Love the recipes and shopping list feature" — iOS GB, 2026-08-30, 2★ (note the rating)

### 3. Design and ease of use (24 mentions, 17 positive)
- "Easy to follow and beautifully designed" — Trustpilot, 2026-08-29, 4★
- "clearly designed for the user in mind" — iOS GB, 2026-05-08, 5★
- Dissent exists: "Interface is for toddlers. Drives me round the bend." — iOS GB, 2026-06-16, 3★

### 4. It changed how they cook (15 mentions)
The strongest emotional register in the whole set, and it is not about software.
- "Mob can save your marriage!" — iOS US, 2026-03-10, 5★
- "Returning joy to family meals" — Trustpilot, 2026-08-30, 5★
- "Very AuDHD friendly" — Play, 2026-03-29, 5★ (ingredients listed beside each method step)

### 5. Specific craft touches users name unprompted
Cook mode / screen-stays-awake ("saves the screen getting sticky marks!" — iOS GB, 2026-07-17, 5★); search-by-ingredient to use up what's in the fridge; freezable / batch-cook / leftovers labels; portion scaling; the newer "Swap" ingredient substitution.

---

## 3. What people hate — ranked

### 1. Subscription, trial, renewal and cancellation — 101 mentions (17%), 94 negative
**By a clear margin the biggest complaint, bigger than the paywall itself.** It is also the dominant 1★ theme on Trustpilot (23% of 631 reviews are 1★, and cancellation/refund runs through nearly all of them).

Distinct failure modes, all separately evidenced:
- **Trial converts to an annual charge, refund refused.** "Subscription renewed with no warning or communication" — Trustpilot AU, 2026-08-29, 1★
- **Web subscription and store subscription are two separate subscriptions**, cancelling one doesn't cancel the other. Mob confirms this in its own replies.
- **Circular cancellation instructions** — "The app says if you subscribed through the app go to the play store - it's not there" — Play, 2025-08-09, 2★
- **Instagram signups get a 5-day trial, in-app signups get 7** — a real asymmetry, **confirmed by Mob's own Trustpilot reply** (2026-08-12).
- **Access cut off immediately on cancelling a paid-up month** — Play, 2025-08-04, 2★

The word "scam" or "scammers" appears as a review *title* repeatedly across Play, iOS GB/US/CA/IE and Trustpilot. These are user accusations, not findings.

`Source: https://uk.trustpilot.com/review/mob.co.uk?stars=1&languages=all`

### 2. Bugs, crashes and the white screen — 88 mentions (15%), 69 negative
- **The white/blank/grey screen on launch** — 18 explicit Play reports, clustered Jul–Sep 2025 (13 of 18), still recurring in 2026. Present on **both platforms and in every storefront checked including Norway.**
  - "I open the app and its just a blank white screen" — iOS **NO**, 2026-03-27, 1★
  - "absolute white screen. Nothing. Deleted and reinstalled" — Play, 2025-08-02, 1★ (25 helpful votes)
  - "most of the time it just white screens constantly" — iOS IE, 2026-08-30, 2★
- **Logged out mid-session, told to subscribe again.** "it's telling me to 'subscribe' to..." — iOS GB, 2026-05-30, 1★
- **Meal plans and shopping lists silently deleting themselves** — Play, 2025-05-26, 2★
- Loyal users work around it: "my shopping lists sometimes disappear, so I take screenshots to be safe" — Play, 2025-10-28, 5★

**Android vs iOS:** the bug profile is essentially identical — white screen, logouts, lost lists on both. There is no evidence of an Android-specific quality gap; Play's headline rating (4.6) is *higher* than every non-UK iOS storefront. The one asymmetry is **iOS-side device breadth**: no usable iPad layout and no Mac support. "Who builds an app that..." — iOS GB, 2026-08-14, 1★.

### 3. Login and account access — 46 Play mentions (11%), 42 negative
Magic-link loops, lost access after changing phone, "restore purchases" never finding the account.
- "redirects back to email that opens the Web pages that opens the app" — Play, 2026-08-31, 1★
- "I changed my phone and can no longer access my paid-for 'premium subscription'" — Trustpilot, 2026-08-21, 1★
- "The subscription only ever works on one device" — iOS GB, 2026-08-18, 1★

### 4. Price versus what you get — 47 mentions (8%), 37 negative
- "Expensive for what it is. The recipes are all very samey" — Play, 2025-08-28, 2★ (**45 helpful votes — the single most-upvoted review**)
- "13$ a month lol who pays for that?" — iOS CA, 2026-07-30, 1★
- Paying users push back: "Ok its a STEEP price for an app but the recipes are fabulous" — iOS GB, 2026-05-09, 5★

### 5. The hard paywall before any value — 44 mentions (7%), 43 negative
Covered in full in §6.

### 6. AI — generated assets, AI recipes, AI support — 20 mentions (3%), 19 negative
A newer theme (mostly 2026) and disproportionately damaging because it attacks the *one thing* Mob is trusted for.
- "AI generated slop images, looks so bad" — iOS CA, 2026-01-04, 1★
- "the shopping list it generates for you is incomprehensible ai nonsense" — iOS US, 2026-07-14, 3★
- "worst of all - AI customer service" — iOS GB, 2026-06-29, 1★ (review title)
- "I got a reply from an AI agent 'Charlie'" — Trustpilot, 2026-08-21, 1★

### 7. Recipe accuracy — quantities, missing steps, list ≠ method
Small in count but high in consequence: it happens *after* the user has shopped and started cooking.
- "you find basic errors in the recipes, e.g., steps missing in the method" — Play, 2025-02-06, 2★
- "The shopping list generated does not match the recipes" — iOS US, 2026-05-03, 2★
- "told me I need to buy like 6 lemons" — Play, ingredient dedupe failure (lemon vs lemon zest)
- "parmesan used extensively in many vegetarian recipes when it isn't vegetarian" — Play, 2025-02-06, 2★

### 8. Allergies and dietary needs — 10+ mentions, near-unanimous negative
Onboarding asks only vegetarian / vegan / pescatarian.
- "only useful if you have no food intolerances or allergies whatsoever" — iOS GB, 2026-08-16, 1★
- "I filtered out peanut and sesame, searched noodles, and ALL..." — Play, 2026-04-22, 1★
- "Only about protein? No option for gluten free." — iOS CA, 2025-08-22, 1★

### 9. Calorie load and nutrition filtering
- "some of them have 900+ calories per portion which is insane" — Trustpilot, 2026-08-29
- "high-protein, high-fibre meals around 500 kcal... returned zero" — iOS GB, 2026-08-01, 4★

### 10. Repetition and library depth
- "Chicken breast and more chicken breast" — Trustpilot US, 2026-08-31, 3★
- "the recipes are super limited" — iOS GB, 1★

### 11. The onboarding quiz before the paywall — 10 mentions, all negative
- "Don't make me do a whole questionnaire just to tell me I have to pay" — iOS GB, "Fuming", 1★
- "stupid on-boarding questions, just take me to app" — Play, 1★
- "gathers all your information... before they show that there's no free option" — iOS CA, 2025-11-06, 1★

### Not a complaint: offline access
**Zero mentions across 404 Play reviews.** The only near-hits are connectivity *bugs* ("No connectivity constantly" — iOS US). Nobody in this audience is asking for offline recipes. Worth weighing before investing in it as a headline feature.

---

## 4. Deal-breakers — the exact moment people leave

Ranked by how often the moment appears in the corpus:

1. **Quiz → account → card wall, having seen nothing.** Uninstall before a single recipe is viewed. The most common abandonment in the whole set. "you don't even know what you're paying for. this is so shady" — iOS US, 2026-08-03, 1★
2. **Trial converts to an annual charge; refund refused.** Converts a lukewarm user into a public accuser. "I cancelled in the same hour of purchasing" — Play, 2026-03-05, 1★ (15 helpful)
3. **White screen after paying.** Paid, then locked out. "It'd be a great app if it actually worked" — Play, 2025-08-01, 1★
4. **Losing access on a new phone**, with restore-purchases failing.
5. **Discovering two subscriptions** (web + store) after cancelling one.
6. **A recipe failing mid-cook** — wrong quantities, ingredient not in the method. Breaks the one thing they paid for.
7. **Spotting AI-generated imagery or an AI support agent.** Immediate, pre-emptive churn: "Immediate turn off, So I will not be using the app" — iOS GB, 2★.
8. **Support answering a billing complaint by quoting the T&Cs.** Several reviewers escalate specifically because of the reply, not the charge.

**Where they go** (named by departing users): YouTube/Instagram plus ChatGPT to reconstruct the recipe; Pinterest + Notion; the BBC Food app; Samsung Food; NYT Cooking; Paprika; and — repeatedly — **Mob's own cookbooks**. "I'm going to cancel subscription and buy their books" (iOS GB, 2026-06-16, 3★) is a user choosing a one-time purchase from the same brand.

---

## 5. Feature requests — exhaustive

**Asked for and shipped late (a rating cost was paid in the gap):** meal planner in-app (web-only for months — the whole Dec 2024/Jan 2025 collapse); nutrition/macros in-app; ingredient substitution (now "Swap"); freezable/leftovers labels.

**Asked for and still missing:**
- Add / import your own recipes — "should be a way for a user to create recipes... mix their own recipes in the plan" (Play, 2025-08-05, 5★). Only 1 explicit request, but see §9.
- Recipe ratings, reviews and comments visible in-app ("no way to tell if actually delicious before cooking")
- Recipe videos in-app — the thing that built the brand ("I, like most people, found mob through social media")
- **Family / duo / household plan** — "really missing a family plan or duo subscription model" (iOS GB, 2026-08-11, 4★)
- iPad layout; Mac/desktop; reliable phone↔tablet sync
- Search and categorise *within* saved recipes; delete collections
- Proper allergen profile (dairy, gluten, nuts, sesame, soy, legume) beyond veg/vegan/pesc
- Combinable nutrition filters that return results
- Grams per portion in the nutrition panel
- GLP-1 / diabetic-friendly labels
- "Mark as cooked" — **existed, then removed**: "Latest update got rid of the 'mark as cooked' option... please bring it back" (Play, 2026-06-14, 4★)
- Shopping list: dedupe near-identical items; tick off what you already own; weights not counts for meat (US); export/order straight to a supermarket
- Auto-generate a week's plan
- Lower-calorie and low-carb ranges
- Notes on recipes in-app (web-only)
- Free-recipe filter for non-subscribers (2025 request, now moot)

---

## 6. The paywall backlash — documented

### What actually happened, with dates

Mob built its audience from 2016 on free social video — the "feed four for under £1" format — then moved to a subscription app. Founder Ben Lebus is billed at Business of Apps London 2026 to explain "how the positioning decision and the paywall that followed reshaped Mob's growth model... the shift from audience to owned product." That is Mob's own framing. `[SECONDARY]` `https://www.businessofapps.com/news/ben-lebus-to-headline-business-of-apps-london-2026-with-mobs-journey-to-the-uks-leading-recipe-app/`

The review record dates the closing precisely:
- **2024-10-30** — a free tier exists but can't be isolated: "No way to filter for non premium recipes"
- **2025-05-08** — still there: "for non-premium users please make it so we can filter by free recipes"
- **2025-06-09** — thinning: "all behind a paywall with a 'few' free recipes"
- **2025-08-04** — gone: "Can't access anything until I agree to start their free trial week"
- **2025-08-28** — the epitaph, and the most-upvoted review on Play: "has no free version where is certainly used to have some free recipes before" (45 helpful votes)

**The free tier closed between June and August 2025** — the exact window of the worst month in the app's history.

### How loud, and how sustained

44 of 609 reviews (7%), 43 of them negative. Peak Aug 2025 (9 mentions). **But it never stopped** — 7 mentions in Aug 2026, the most recent full month, a year later. Monthly counts: 2025-08 (9), 2026-01 (5), 2026-07 (5), 2026-08 (7).

**Verdict: sustained, not a spike — but never the loudest complaint.** Billing practice (17%) and bugs (15%) each outrank it more than twice over. The paywall costs Mob a steady stream of pre-install and first-session 1★ reviews from people who never became customers. The billing complaints come from people who *did*, which is the more expensive kind.

### What exactly people feel was taken

Not "recipes I used to own" — **a relationship**. The single most representative review in the set is a long-time follower from the "budget meals for students" era (Trustpilot GB, 2026-08-08, 1★). Its three load-bearing phrases:

- "it's really lost its way"
- "almost every decent recipe... is locked behind the Plus subscription"
- "they've turned their back on the community that built them"

And, critically, from the same review: **"I don't mind paying for quality, but the app is so buggy"**. **The objection is not to paying. It is to paying for something that doesn't work.**

Others in the same register:
- "Can get better and more variety for free from many food creators" — Play, 2025-08-28, 2★
- "There's tons of recipes for meal prepping on the internet why would I pay" — iOS DE, 2025-08-21, 1★
- "so many free recipes on the web...why?" — Play, 2025-08-04, 1★

### Did Mob respond or reverse anything?

**No reversal.** The free tier has not returned; as of 2026-09-01 the app is trial-or-pay. Mob does respond, publicly and by name. Its reply to the "turned their back on the community" review:

> "We've had to make some tough calls as Mob grew... we've expanded our Engineering Team to ensure the app is reliable."
> — Mob (Laura), Trustpilot, ~2026-08-31

That is the company's position: the paywall stays, the reliability complaint is accepted.

### The other side — people who happily pay

This matters as much as the backlash, and there is a lot of it:
- "Worth every penny and more!" — Play, 2026-05-18, 5★
- "best 40 quid i spend a year" — Play, 2026-05-24, 5★
- "I rarely use paid apps but this was worth the investment" — Play, 2026-07-24, 5★
- "I rarely pay for apps but am so glad I bought MOB" — Play, 2026-05-12, 4★
- "such good value for the amazing recipes" — iOS GB, 2026-07-13, 5★

And the commercial verdict is unambiguous: **Mob is badged "#1 top grossing food & drink" on Google Play** (observed 2026-09-01). **The paywall worked.** It bought a loud, permanent, low-grade stream of 1★ reviews from non-customers, and it made Mob the top-grossing app in the category. Any lesson drawn from the backlash has to be drawn against that fact.

---

## 7. Non-UK experience

**The rating penalty is real and measurable.** Every English-speaking non-UK storefront sits 0.4–0.5 stars below GB's 4.57: US 4.16, CA 4.17, AU 4.44. Non-English markets: DE 4.05, FR 4.03, SE 3.97.

**Measurements are the concrete failure.** Ounces used ambiguously, metric settings that don't persist, US-style instructions surviving a metric toggle:
- "I'm an American cook... is it 4 Tablespoons of pesto or 2 ounces by weight??" — iOS US, 3★
- "although I had everything set to metric found a lot of the cooking instructions... geared towards a US audience" — Play, 2026-07-13, 2★ (Mob replied within a day)
- "now can't change from US to UK/metric. total pain... just reverts back" — Play, 2025-09-12, 3★
- "changes my measurement settings on its own" — Play, 2026-01-10, 3★
- US shoppers want meat by weight, not count, for grocery pickup — Play, 2026-06-24, 5★

**Shopping-list structure is UK-shaped** — sorted by UK supermarket aisle; the standout GB workflow quote is Ocado integration by hand.

**Nordics.** Small samples, so treat directionally. NO 4.49 (37 ratings), DK 4.62 (29), **SE 3.97 (66) — the lowest storefront measured**. Norway has exactly **two** App Store reviews, **both 1★**, and they name the two headline problems precisely:
- "Expensive and no free option" / "Nothing to test the app and no free features" — iOS NO, 2026-03-27, 1★
- "I open the app and its just a blank white screen" — iOS NO, 2026-01, 1★

No review in the corpus mentions Norwegian supermarkets, NOK pricing, or Norwegian-language content. **A Norway-resident user's entire visible experience of Mob is: pay first, and it might not open.**

---

## 8. Trust signals

**Developer responsiveness — a genuine recovery story.** Play reply rate by half-year: 2024H2 **88%** → 2025H1 33% → **2025H2 24%** → 2026H1 66% → **2026H2 89%**. They went quiet exactly when the app was worst (Aug–Sep 2025) and have since fixed it. Trustpilot: **"Replied to 97% of negative reviews," "Typically replies within 1 week."** Replies are signed by a named human (Ben, Sam, Laura) and are often substantive — one Play reviewer got an email follow-up within a day.

**Support quality is contested and the split is legible.** Positive: several recent Trustpilot 5★ reviews specifically praise speed ("Super speedy resolutions," "jack solved issue"). Negative: an AI first-line agent named "Charlie," and replies to billing disputes that restate the terms rather than resolve. Multiple reviewers escalated *because of the reply*.

**Accusations (labelled as accusations, not findings):**
- **Misleading trial marketing.** Users allege the 7-day trial charged early or immediately. Mob's stated explanations: Instagram-link signups get **5 days**, not 7 (Mob confirms this); repeat trialists are charged at signup. Both are real mechanics; whether they were prominent enough at the point of sale is the disputed part. `[UNVERIFIED — user claims vs. company claims, unresolved]`
- **Renewal reminders landing in spam.** One reviewer alleges Mob's own FAQ acknowledges this. I did not verify the FAQ. `[UNVERIFIED]`
- **"Meal planner" advertised but absent.** Recurring on iOS GB into 2026 — "No meal planning as advertised" (2026-08-31, 2★). `[UNVERIFIED — may reflect discoverability rather than absence]`
- **Trustpilot "Unprompted review" label disputed.** One reviewer states they were sent an invite despite the label. Trustpilot's own panel says "No recent history of asking for reviews." `[UNVERIFIED]`
- Frequent "scam"/"scammers" language across all platforms. **These are expressions of anger about auto-renewal, not evidence of fraud.** No regulator action or substantiated finding was found.

---

## 9. What this hands us — ranked

1. **Our price is our best marketing, and it targets a real, identified, currently-churning audience.** Mob's exit interviews name the alternative: cookbooks. "I'm going to cancel subscription and buy their books" (iOS GB, 2026-06-16). "or buy some great cook books" (Play, 2025-08-28, 45 helpful votes). These people are not cheap; they are *anti-rental*.

2. **Charge for the thing, then get out of the way.** 17% of all reviews are about billing mechanics — trial conversions, dual subscriptions, refusal to refund, circular cancellation. **A one-time purchase deletes this entire category of complaint**, which is Mob's single largest. Nobody writes a 1★ review about renewing a purchase they made once.

3. **Show the goods before the wall.** The most common abandonment is quiz → account → card, having seen nothing. "I've no problem paying for a good service but I need more than promises" (iOS GB, 2026-07-21, 2★). MyReciBook should let people *browse real recipes* before any payment prompt — and the paid unlock should be a single visible price, not a trial with a clock on it.

4. **Reliability is the whole argument.** The most instructive line in the research: *"I don't mind paying for quality, but the app is so buggy that it's not worth the monthly fee."* A blank white screen after payment appears in **every storefront checked, including Norway, on both platforms, for over a year.** Our cold-start path — install → open → see content — is the highest-stakes code we will write.

5. **Never take something back.** Mob removed a free tier and removed "mark as cooked"; both generated durable, specific anger. A one-time purchase makes this constitutional: what you bought is what you keep. Say so on the store listing.

6. **Own the unmet needs Mob won't build.** Ranked by evidence strength: real allergen profiles (not veg/vegan/pesc); add-your-own recipes; a household/family plan (a one-time purchase sidesteps this entirely — no "duo subscription" needed); combinable nutrition filters that return results; tablet layout; shopping-list dedupe.

7. **Nail units and locale, and say so.** The 0.4–0.5 star non-UK penalty is measurable. Metric that persists, weights not counts, no supermarket-aisle assumptions.

8. **Recipe correctness is not a nice-to-have.** Shopping list must be derived from the method, not written beside it. Mob's ingredient-vs-method mismatches produce some of its angriest reviews because they surface mid-cook.

9. **Be visibly human, especially about money.** Mob's reply rate collapse (88% → 24%) during its worst months made the crisis worse; its recovery to 89% coincides with its best month. Cheap to do, expensive to skip.

10. **Don't be caught using AI where trust lives.** 19 of 20 AI mentions are negative — AI images, AI-looking recipes, AI support. Several reviewers churned *pre-emptively* on spotting it. Human-made, human-tested, human-answered is a competitive position.

11. **Expect the same silent-5★/loud-1★ asymmetry** and prompt happy users to review at a genuine moment of delight. Mob's 4.6 exists because most people never type.

### Lessons about charging money

**What Mob's audience tolerated:**
- Paying. Comfortably. "best 40 quid i spend a year." Mob is **#1 top grossing** in Food & Drink.
- A high price, *when the value was visible first* — "Ok its a STEEP price for an app but the recipes are fabulous."
- Losing free content, *provided the paid thing worked*.
- Being told no, when told by a named human who explained why.

**What it did not tolerate:**
- Paying before seeing anything. Quiz, account, card, nothing.
- A trial with a hidden clock — and especially two different trial lengths (5 days via Instagram, 7 via the app) for the same advertised offer.
- Two subscriptions where they thought they had one.
- "Per the T&Cs" as an answer to a refund request made within hours.
- Paying monthly and being logged out, white-screened, or having their list vanish.
- Any sense of being *harvested* — data collected during onboarding before the paywall was disclosed.

**What that implies for a one-time ~$25:**
- **Lead with "$25 once. No subscription. Ever."** in the store listing's first line. It is a direct answer to the loudest complaint about the category leader.
- **Never use the word "trial."** Ship a genuinely usable free surface — real recipes, real cook mode — and sell the unlock. A trial re-imports the exact machinery that generated 17% of Mob's complaints.
- **$25 is a cookbook, not a rental — say it in those words.** Mob's own churned users reach for the cookbook comparison unprompted ("Treat it like a cookbook and have a download fee"). Mob charges roughly £40/year *recurring*; a one-time $25 is under a year of Mob and is permanent. That sentence is the whole pitch.
- **Restore-purchase must be flawless.** Mob's failures here ("restore purchases but it never finds my account") are catastrophic under a subscription and would be *fatal* under one-time pricing, where a lost purchase means a lost customer with no recourse and a very good reason to write 1★.
- **Set the family expectation explicitly.** Google Play Family Library on a one-time purchase answers the "family plan" request Mob can't cheaply meet. Say so.
- Note per project convention: never use the word "unlimited"; "no subscription" and "yours to keep" carry the same promise honestly.

### Are Mob users explicitly asking for one-time purchase or lifetime access?

**Yes — three explicit, one implicit, all quoted verbatim:**
1. "Would be worth it for a one time payment but just another app thinking it needs to be a subscription based model." — Play, 2025-07-17, 1★
2. "Treat it like a cookbook and have a download fee. I don't want to pay monthly for a cooking app." — iOS CA, 2026-04-28, 1★ (review title: "okay" — a mild reviewer, not a hater)
3. "I'm going to cancel subscription and buy their books." — iOS GB, 2026-06-16, 3★
4. "or buy some great cook books." — Play, 2025-08-28, 2★ — the most-upvoted review on the entire listing (45 helpful votes)

Small in absolute count, but the framing recurs independently across three countries and two platforms, and **the highest-signal review Mob has ends with it.** The demand is not loud. It is consistent, and it is unserved.

---

## Sources

All observed 2026-09-01.

**Primary — raw review data**
- Google Play listing and ratings histogram — https://play.google.com/store/apps/details?id=com.mob.mobappprod&hl=en_GB&gl=GB
- Google Play review endpoint (`batchexecute`, rpcid `UsvDTd`, app `com.mob.mobappprod`) — 404 text reviews, 2024-09-11 → 2026-08-31, all four sort orders
- Apple customer-reviews feed — `https://itunes.apple.com/{gb,us,ca,ie,no,nl,de,se,au}/rss/customerreviews/page=N/id=6670216494/sortby=mostrecent/xml` — 205 dated reviews
- Apple aggregate ratings — `https://itunes.apple.com/lookup?id=6670216494&country={gb,us,ie,au,no,se,dk,nl,ca,de,fr}`
- App Store listing (GB) — https://apps.apple.com/gb/app/mob-meal-planner-and-recipes/id6670216494
- Trustpilot, mob.co.uk, all reviews — https://uk.trustpilot.com/review/mob.co.uk?languages=all
- Trustpilot, 1★ filter (8 pages) — https://uk.trustpilot.com/review/mob.co.uk?stars=1&languages=all

**Secondary**
- `[SECONDARY]` Business of Apps — Mob's own account of the paywall decision — https://www.businessofapps.com/news/ben-lebus-to-headline-business-of-apps-london-2026-with-mobs-journey-to-the-uks-leading-recipe-app/
- `[SECONDARY]` Mob Premium pricing help centre — https://support.mob.co.uk/en/articles/11021542-mob-premium-pricing-and-free-trials
- `[SECONDARY]` Mob website — https://www.mob.co.uk/

**Not obtained**
- Reddit (r/UKFood, r/CasualUK, r/Cooking, r/AndroidApps) — blocked at both the fetch and browser layer in this environment. No Reddit evidence is cited above.
- YouTube comment threads on Mob videos — not retrievable here.
- UK press comment sections and Twitter/X threads — no relevant indexed results surfaced.
- App Store storefront-level histograms — Apple publishes an average and a count, not a distribution.
