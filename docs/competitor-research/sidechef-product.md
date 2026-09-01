# SideChef — Product, Features & Pricing

_Researched: 2026-09-01_

## Headline correction: the "4.0 stars" is a Norwegian storefront artifact

The brief describes SideChef as "4.0 stars — notably low for its size." That number is real but it is **not** a global quality signal. Google Play shows a **country-localised** star rating. Same app, same 8.24K global review base, four different headline numbers observed on 2026-09-01:

| Storefront | Displayed rating | Editors' Choice badge? |
|---|---|---|
| US (`gl=US`) | **4.5** | Yes |
| UK (`gl=GB`) | **4.4** | No |
| Norway (`gl=NO`) | **4.0** | No |
| Germany (`gl=DE`) | **3.8** | No |

All four observed 2026-09-01 on `com.sidechef.sidechef`. Details and the underlying histograms are in [§7](#7-why-40-stars--the-structural-answer). Short version: the Norwegian 4.0 is computed from roughly **five** Norwegian ratings and means almost nothing; the **German 3.8 is the number that should worry us**, because Germany is the one European market SideChef actually localised.

---

## 1. Identity

| Field | Value | Source |
|---|---|---|
| Android package | `com.sidechef.sidechef` — **verified** | [Play listing](https://play.google.com/store/apps/details?id=com.sidechef.sidechef) |
| iOS app ID / bundle | `905229928` / `com.SideChef.SideChef-iphone` | [iTunes lookup](https://itunes.apple.com/lookup?id=905229928&country=us) |
| Play title | SideChef: Recipes & Meal Plans | Play |
| iOS title (varies by store) | US: "SideСhef: Easy Cooking Recipes"; NO: "SideChef: Recipes+Meal Planner" | iTunes lookup US / NO |
| Legal entities | "SideChef Inc." (website footer); Apple seller **"SideChef Group Limited"** | [sidechef.com](https://www.sidechef.com/), iTunes lookup |
| Founder & CEO | **Kevin Yu** (ex-Blizzard community developer) | [About Us](https://www.sidechef.com/business/about-us), [TechCrunch](https://techcrunch.com/2023/03/01/sidechef-commerce-recipe-app/) |
| COO | **Cadence Hardenbergh** (Shanghai-based co-founder) | [About Us](https://www.sidechef.com/business/about-us) |
| Founded | 2013–2014 (sources differ); iOS app first released **2014-08-21** | iTunes lookup; [TechCrunch](https://techcrunch.com/2023/03/01/sidechef-commerce-recipe-app/) |
| HQ / offices | US (California) HQ with **Shanghai** and **Zurich** offices. Aggregators disagree on the exact US address (San Jose vs San Francisco) — treat the street address as `[UNVERIFIED]`; the **US + Shanghai + Europe split is well supported** by the staff roster (Chinese, Italian, Croatian and Nordic given names across engineering, content and partnerships) | [About Us](https://www.sidechef.com/business/about-us); [ZoomInfo](https://www.zoominfo.com/c/sidechef-inc/374943671) `[UNVERIFIED]` |
| Total funding | **>$16M** across seed, Series A, Series B (company's own statement) | [Series B press release](https://www.sidechef.com/business/press-releases/sidechef-secures-6-million-in-series-b-funding-to-invest-in-the-future-of-shoppable-recipes) |
| Series B | **$6M led by LG Electronics** | same |
| Investors | LG Technology Ventures, **AB Electrolux**, **V-ZUG AG**, Ideate Ventures, Peacock Capital Group, Ilion Capital, Empower Investment, Innolead Investment, KZone LLC | same |
| Team size | **~30 people named** on the About Us page (2026-09-01). PitchBook says 57; other aggregators say 11–50 — all `[UNVERIFIED]` | [About Us](https://www.sidechef.com/business/about-us); [PitchBook](https://pitchbook.com/profiles/company/102399-13) |
| Android installs | **1M+**, 8.24K reviews (2026-09-01) | Play |
| iOS ratings | US: **4.73 from 1,658 ratings**. Norway: **5.0 from 6 ratings** (2026-09-01) | iTunes lookup [US](https://itunes.apple.com/lookup?id=905229928&country=us) / [NO](https://itunes.apple.com/lookup?id=905229928&country=no) |
| App languages | **English and German only** (`["EN","DE"]`) — no Norwegian, no Nordic languages | iTunes lookup |
| Current version | **5.31.1**, released **2025-03-14** on *both* iOS and Android; release notes read only "Feature improvement" | iTunes lookup; Play "Updated on Mar 14, 2025" |
| Maintenance status 2026 | **The consumer app has not shipped an update in ~18 months.** The B2B site, by contrast, was updated in 2026 (see §8) | derived from the above |
| Install footprint | iOS min version 13.4, 74.6 MB | iTunes lookup |

**The single most important identity fact:** the consumer app is frozen at a March 2025 build while the business-side website ships new case studies into 2026. That asymmetry is the whole story of this company.

---

## 2. Positioning — consumer app vs B2B platform

**SideChef is a B2B food-commerce infrastructure company that also operates a consumer app as a showroom and data source.** This is not a hedge; the evidence is one-directional.

Structural evidence:

- **The website is split at the root.** `sidechef.com` is the consumer site; `sidechef.com/business` is a completely separate site with its own navigation, its own newsletter, its own "Schedule a demo" funnel and a lead form that asks "Business Type: Retailers / CPG / Manufacturer / Content Creator or Publisher." ([business home](https://www.sidechef.com/business/))
- **The B2B side has a full product catalogue; the consumer side has one $4.99 subscription.** B2B products: Recipe Platform Development, Shoppable Recipe Button, Recipe Site Widgets, SideChef AI Experiences, Brand Awareness Campaign, In-Recipe Campaign, Shoppable Campaign Page, Shoppable Social Links, Recipe Management System, Food Photo Generator, Cooking Experience Platform (CXP), Cost-Per-Order Campaigns (CPO). ([nav on any /business page](https://www.sidechef.com/business/partners))
- **Careers is tagged "WE'RE HIRING" on the business site** while the consumer app sits unpatched for 18 months.
- **Their own European expansion was a B2B deal, not an app launch.** The M&S case study quotes Kevin Yu: the "UK expansion" *is* powering Marks & Spencer's own recipe hub inside M&S's website and app — not growing SideChef's app in Britain. ([M&S case study](https://www.sidechef.com/business/client-project/marks-and-spencer))
- **Investors are appliance OEMs.** LG Electronics led the Series B; Electrolux and V-ZUG are on the cap table. Those are customers-as-investors — the classic signature of a licensing business.

The consumer app's role in that machine: it is the reference implementation they demo to retailers and OEMs, the corpus that trains the shoppable ingredient-matching, and the panel that generates the "in-recipe behaviour" data they sell back to CPG brands (see the Super Bowl case study in §6).

---

## 3. Full feature inventory

| Feature | Present? | Detail | Source |
|---|---|---|---|
| Recipe library | Yes | **18,000** step-by-step recipes (store listings). Company pages variously say 20,000, 18,000 and 16,000 — the numbers are not kept in sync | Play; [About Us](https://www.sidechef.com/business/about-us); [FAQ](https://www.sidechef.com/faq/) |
| Step-by-step guided cooking | Yes — **the core asset** | Image or video at *every* step | Play listing |
| How-to technique videos | Yes | e.g. how to dice an onion, how to press tofu | Play listing |
| Voice guidance / hands-free | Yes | "advance through each step at your own pace using voice commands" | [FAQ](https://www.sidechef.com/faq/) |
| Built-in step timers | Yes | Timers fire on steps with specified cook times | [FAQ](https://www.sidechef.com/faq/) |
| Meal planner | Yes | Calendar by date + meal type; save from recipe or start from calendar | [FAQ](https://www.sidechef.com/faq/) |
| Grocery list | Yes | Multiple named lists; add from recipe with serving-size scaling; uncheck what you already have | [FAQ](https://www.sidechef.com/faq/) |
| **Shoppable recipes / one-click checkout** | Yes — **US-gated** | US listing: "Walmart and Amazon Fresh **(U.S. only)**". Older listings still served outside the US name Instacart, Walmart, Amazon Fresh, Target "and more" with **no US-only caveat** | [Play US](https://play.google.com/store/apps/details?id=com.sidechef.sidechef&hl=en_US&gl=US) vs [Play NO](https://play.google.com/store/apps/details?id=com.sidechef.sidechef&hl=en&gl=NO) |
| Real-time prices & availability | Yes (US retailers) | Ingredients matched to in-store products | Play listing |
| Cost per serving | Yes | e.g. "$6.56 Cost Per Serving" — **USD only** | [recipe 7077](https://www.sidechef.com/recipes/7077/mahi_mahi_with_vanilla_sauce/) |
| % of ingredient used | Yes | Leftover/waste planning aid — genuinely clever | Play listing |
| Nutrition data | Yes, **free, and detailed** | Per serving: calories, fat, saturated, trans, cholesterol, carbs, fibre, sugars, protein, sodium, vitamin D, calcium, iron, potassium, with %DV. Powered by **Edamam** | [recipe 7077](https://www.sidechef.com/recipes/7077/mahi_mahi_with_vanilla_sauce/); [Edamam partnership](https://www.sidechef.com/business/partners/edamam) |
| **Food diary / calorie logging** | **No** | Nothing in listings, FAQ or site navigation. Nutrition is per-recipe reference data only — you cannot log what you ate | absence across all sources |
| **Weight / body tracking** | **No** | same | same |
| Pantry | Yes | "My Pantry" in site nav; pantry management named as a CXP feature | [FAQ nav](https://www.sidechef.com/faq/); [IoT page](https://www.sidechef.com/business/iot-and-smart-kitchen) |
| Ingredient-based search ("what's in my fridge") | Yes | Filter by "ingredients you already have at home" | Play listing |
| Fridge / food scanning | **B2B only** | "Food Scanning & Image Recognition Technology" is sold to appliance brands; not advertised as a consumer app feature | [IoT page](https://www.sidechef.com/business/iot-and-smart-kitchen) |
| Dietary filters | Yes, strong | Vegan, Vegetarian, Pescatarian, Low-Carb, Paleo, Keto + allergens: Gluten, Egg, Dairy, Soy, Peanut, Tree Nuts, Fish, Shellfish | Play listing |
| Unit switching | Yes | US / metric toggle; servings scale 1–16 | [recipe 7077](https://www.sidechef.com/recipes/7077/mahi_mahi_with_vanilla_sauce/) |
| Smart appliance control | Yes | **2,000+ CookAssist** smart recipes; **LG, GE, Bosch Home Connect (incl. Thermador, Gaggenau)** | Play listing |
| Voice assistants / smart displays | Yes | **Amazon Alexa/Echo, Google Home Hub, Samsung Bixby, Facebook Portal** | [Series B PR](https://www.sidechef.com/business/press-releases/sidechef-secures-6-million-in-series-b-funding-to-invest-in-the-future-of-shoppable-recipes); [Premium page](https://www.sidechef.com/premium/) |
| Web app | Yes | Full recipes, meal planner, pantry, grocery, cookbooks on sidechef.com | site nav |
| Community | Yes | Rate recipes, upload photos, exchange tips | Play listing |
| Save your own recipe | Yes, but **manual entry only** | "My Saved Recipes → CREATE RECIPE → input a title and at least one ingredient" | [FAQ](https://www.sidechef.com/faq/) |
| **Import a recipe from a URL** | **No** | No import feature anywhere in the FAQ, listings or site. Only manual creation | absence across all sources |
| **Share a meal plan or list with household** | **No** — explicitly | "At this time, we do not support sharing meal plans or shopping lists" | [FAQ](https://www.sidechef.com/faq/) |
| **Family / household subscription sharing** | **No** — explicitly | "all subscriptions are for individuals only" | [FAQ](https://www.sidechef.com/faq/) |
| Offline use | Not established | No offline claim found in any source. Given the retailer price lookups and video-per-step design, assume online-first `[UNVERIFIED]` | — |
| Languages | **English, German only** | No Norwegian | iTunes lookup |
| Android form factors | Phone, Tablet, Chromebook | No Android TV / Wear listed | Play |

---

## 4. Free vs Premium

The paywall is unusually **narrow** — and that is instructive, because SideChef doesn't need the subscription to pay the bills.

**Free tier includes** (this is the surprising part): the full 18,000-recipe library, step-by-step guided cooking with photos/videos, voice step control, timers, the meal planner, grocery lists, pantry, dietary filters, full nutrition data, smart-appliance control, and the shoppable checkout. Almost everything MyReciBook plans to charge for, SideChef gives away.

**SideChef Premium adds only:**

| Premium unlock | Detail |
|---|---|
| 800+ exclusive recipes & on-demand cooking classes | From Le Cordon Bleu instructors, a Top Chef Masters winner, and other named experts |
| Cooking tips & techniques library | Expert step-by-step guided videos |
| Premium recipes inside your meal plan | Premium content unlocked in the planner |
| In-house testing guarantee | "tested by our in-house culinary team" |

**How the paywall actually behaves:** on a Premium recipe the ingredients, tags, cost per serving and full nutrition panel all render free — but the **Cooking Instructions section is replaced by "🔒 Unlock to View All"** linking to `/purchase/`. Verified on [recipe 7077](https://www.sidechef.com/recipes/7077/mahi_mahi_with_vanilla_sauce/), 2026-09-01. So Premium gates *steps on ~800 recipes*, nothing else.

**Free-tier friction that is not a paywall:** an account is required to save recipes, use cookbooks, the meal planner or grocery lists (every such link routes through `/account/signin/`). And free recipes carry **sponsored ingredient placements** — see §6.

---

## 5. Pricing

| Tier | Price | Currency | Observed | Source |
|---|---|---|---|---|
| App download | Free | — | 2026-09-01 | Play, App Store |
| SideChef Premium — monthly | **$4.99** | USD | 2026-09-01 | [Premium page](https://www.sidechef.com/premium/), [FAQ](https://www.sidechef.com/faq/), both store listings |
| SideChef Premium — annual | **$49.99** | USD | 2026-09-01 | same |
| Free trial | 7 days, **payment method required up front** | — | 2026-09-01 | [FAQ](https://www.sidechef.com/faq/) |
| Norway / EEA local pricing | **None published.** The Norwegian Play and App Store listings both quote the price in **USD** in the description text; no NOK or EUR figure is surfaced anywhere | NOK/EUR | 2026-09-01 | [Play NO](https://play.google.com/store/apps/details?id=com.sidechef.sidechef&hl=en&gl=NO), [iTunes NO](https://itunes.apple.com/lookup?id=905229928&country=no) |

**Effective annual cost: $49.99/yr.** Against MyReciBook's one-time ~$25, SideChef costs more than our lifetime price **every single year** — and the buyer gets less, because the parts SideChef charges for (celebrity cooking classes) are not the parts a daily cook needs.

**Price changes:** $4.99/mo and $49.99/yr appear consistently across the store listings, the FAQ and the Premium page, all of which were written at different times. No evidence of any price change. `[UNVERIFIED]` that these have ever moved.

**Terms worth noting** (all [FAQ](https://www.sidechef.com/faq/)): auto-renews; **cannot be paused**; **no refunds** on cancellation ("you will not be refunded"); **no family sharing**; promo codes can only be redeemed on the website, never in-app.

---

## 6. Partnerships and revenue model

### Named partners

| Category | Partners | Source |
|---|---|---|
| **Retailers** | Walmart, Target, Kroger, Amazon Fresh, Instacart, **REWE** (DE), **Marks & Spencer** (UK), Sunset Foods | [Partners](https://www.sidechef.com/business/partners), [press](https://www.sidechef.com/business/press) |
| **Appliance / IoT OEMs** | **LG**, **Bosch** (+ Thermador, Gaggenau via Home Connect), **GE Appliances**, **Electrolux**, **V-ZUG**, **Panasonic**, **Sharp**, **Midea**, Amazon Echo | [Partners](https://www.sidechef.com/business/partners) |
| **CPG / food brands** | Nestlé, Unilever, Tyson Foods, Barilla, Bacardi, GOYA, Lee Kum Kee, Torani, It's Skinny, Kemps, Bob Evans, Farmhouse Eggs, Simply Organic | [Partners](https://www.sidechef.com/business/partners), [case studies](https://www.sidechef.com/business/client-projects) |
| **Publishers / media** | Budget Bytes, Gusto TV, New England, ITV ("Cooking with the Stars"), Yahoo Search | [Partners](https://www.sidechef.com/business/partners), [press](https://www.sidechef.com/business/press) |
| **Data / infrastructure** | **Edamam** (nutrition analysis), Pathformance (campaign measurement) | [Partners](https://www.sidechef.com/business/partners), [press](https://www.sidechef.com/business/press) |

### Revenue lines, ranked by apparent importance

| Line | What it is | Evidence of weight |
|---|---|---|
| **1. Cost-Per-Order (CPO) campaigns** | CPG brands pay **per grocery order driven** to a retailer. "Stop wasting money. Pay for what matters. Orders." | Has its own named product page, its own case studies (Bob Evans, GOYA ×2, Kemps, Farmhouse Eggs), and its own measurement partner. The most-productised line on the site. [CPO page](https://www.sidechef.com/business/cost-per-order/) |
| **2. White-label platform licensing (CXP)** | SideChef builds and runs the retailer's/OEM's own recipe experience inside *their* app | M&S Recipe Hub (launched in 90 days, app + web), VZUG V-Kitchen, LG ThinQ, Sunset Foods "Recipe Rack" | 
| **3. In-recipe sponsored placement** | A brand's product **replaces the generic ingredient** in a recipe you are cooking | Directly observed: recipe 7077 lists "Sponsored — Simply Organic® Black Pepper" and "Sponsored — GOYA® Coconut Milk" in the ingredient list. [recipe 7077](https://www.sidechef.com/recipes/7077/mahi_mahi_with_vanilla_sauce/) |
| **4. Affiliate "Shoppable Links"** | One affiliate link carrying a whole ingredient basket, shareable to blogs, IG stories, newsletters, YouTube | [FAQ](https://www.sidechef.com/faq/) |
| **5. Content & AI services** | Culinary consulting, content licensing, Recipe Management System, AI Food Photo Generator | [business nav](https://www.sidechef.com/business/) |
| **6. Consumer subscription** | $4.99/mo — 800 recipes' worth of cooking classes | Smallest, least-developed line. One page, no tiers, no experimentation |

**Revenue split:** SideChef publishes no revenue breakdown and no aggregator has a credible figure — Growjo/Owler/PitchBook estimates are all `[UNVERIFIED]` and mutually inconsistent. But the *structural* read is safe: five of six revenue lines are B2B, the B2B lines have dedicated product pages and case studies while the subscription has one static page, and the company's investors are its appliance customers. **The consumer subscription is a rounding error.**

SideChef also runs a **Recipe Rewards Program**, a revenue-share paying content partners recurring income on the recipes they contribute — i.e. the recipe corpus is acquired on rev-share rather than bought outright ([FAQ](https://www.sidechef.com/faq/)).

---

## 7. Why 4.0 stars — the structural answer

Google Play's displayed rating is country-localised. Star histograms observed directly on 2026-09-01:

| Storefront | 5★ | 4★ | 3★ | 2★ | 1★ | Computed mean | Displayed |
|---|---|---|---|---|---|---|---|
| **US** | 5,866 | 1,034 | 492 | 197 | 394 | 4.48 | **4.5** |
| **UK** | 5,108 | 1,660 | 546 | 231 | 399 | 4.37 | **4.4** |
| **Norway** | 4,493 | 1,497 | 0 | 0 | 1,497 | 4.00 | **4.0** |
| **Germany** | 4,022 | 1,416 | 453 | 849 | 1,076 | 3.83 | **3.8** |

**Norway's 4.0 is five people.** The Norwegian histogram is an exact **3 : 1 : 0 : 0 : 1** ratio (4,493 ÷ 1,497 = 3.0007), scaled up for display against the global review total. Three 5★, one 4★, one 1★ → mean exactly 4.0. Corroborated by the Norwegian App Store, which has **6 ratings**. SideChef has essentially **no Norwegian user base at all**. So the honest reading of the brief's premise: the 4.0 is not a cautionary tale about product quality — it is a measurement of absence.

**Germany's 3.8 is the real signal, and it is the one worth learning from.** Germany is the *only* European market SideChef genuinely invested in: German is one of only two app languages, they employ a "Senior Content Strategist and German Localization Specialist," and REWE is a named retail partner. Result: **24.6% of the German distribution sits at 1–2 stars**, versus 7.4% in the US and 7.9% in the UK. Where SideChef half-entered Europe, Europeans rejected it three times harder than Americans did.

### Structural causes, from product-side evidence

1. **The core value proposition is US-only, and the store listing outside the US doesn't say so.** The US listing reads "shop ingredients directly through Walmart and Amazon Fresh **(U.S. only)**." The Norwegian listing — an older, unsynced version of the description, complete with a surviving typo ("exchange tips, **anad** share") — promises "shop ingredients directly from Instacart, Walmart, Amazon Fresh, Target, **and many more of your favorite grocers**" with **no geographic caveat**. The iOS description outside the US does the same. A European installs an app whose headline feature is advertised without qualification, then discovers it does nothing where they live. That is a manufactured 1-star.
2. **No European retailer reaches the consumer app.** REWE and M&S are B2B deals that live inside *REWE's and M&S's own* properties. A German user who reads "REWE partner" gets no REWE checkout in the SideChef app.
3. **Everything monetary is dollars.** Cost-per-serving renders as USD. Premium is quoted in USD in the Norwegian listing. There is no NOK figure anywhere.
4. **No Norwegian language, and no Nordic content.** Two languages, EN and DE.
5. **Account wall before value.** Saving a recipe, planning a meal or building a list all require sign-up — a hard stop for a user who has already discovered the shopping features don't work.
6. **An 18-month-stale build.** Version 5.31.1 (2025-03-14) on both platforms. Bugs reported in reviews have had no shipping vehicle for a year and a half.
7. **Sponsored ingredients in free recipes.** US CPG brands substituted into ingredient lists (Simply Organic, GOYA) are products a Norwegian cannot buy, in a recipe they are trying to cook.

---

## 8. Business signals

**Positive:**
- Google Play **Editors' Choice** (US storefront, current) and **"Best App of 2017"**.
- **Inc. 5000 #737** — celebrated on the About Us page.
- Press quotes from NYT ("favorite cooking app"), USA Today, Forbes, Tom's Guide, The Today Show.
- 1M+ Android installs, 8.24K reviews; the US business is healthy and well-regarded.
- **The B2B side is demonstrably alive in 2026**: the Cost-Per-Order page carries a Super Bowl commerce case study whose asset is literally named `Screenshot 2026-02-03`, and the Success Stories page uses a case-study asset set revised "Rev31Oct" (late 2025). Careers is flagged "WE'RE HIRING."

**Negative / decline:**
- **Consumer app frozen since 2025-03-14** — ~18 months, both platforms, release notes "Feature improvement."
- **Last press release: 2025-07-01** (Yahoo Search). Nothing in the ~14 months since. ([Press](https://www.sidechef.com/business/press))
- **No CES 2026 presence found.** SideChef appeared at CES 2024; searches surface nothing for 2026. `[UNVERIFIED]` as an absence.
- **Recipe counts contradict each other across their own pages** (16,000 / 18,000 / 20,000) — nobody is maintaining the consumer marketing copy.
- **The Premium page still advertises Facebook Portal**, a device Meta discontinued for consumers in 2022. A page selling a subscription on the strength of a four-year-dead product has not been reviewed in a long time.
- **The Norwegian Play listing serves a stale description** that the US listing has since corrected — localised store assets are not being maintained.
- No revenue figures published; aggregator estimates conflict and are `[UNVERIFIED]`.

**Read:** not a company in distress — a company that has **reallocated**. The B2B business is being actively sold in 2026; the consumer app has been put in run-mode as a demo asset and a data tap.

---

## 9. Gaps and weaknesses — European / Norwegian lens

1. **Zero Norwegian grocery integration.** No Kolonial/Oda, no Meny, no Rema, no Coop, no Bunnpris. The flagship feature is inert in Norway — and the local store listing still advertises it.
2. **No Norwegian language.** EN + DE only. No Norwegian recipe corpus, no Nordic cuisine depth, no Norwegian ingredient names in the pantry or list.
3. **Currency and cost data are USD-only.** Cost-per-serving, the $10-off-$50 Walmart promo, and the subscription price are all dollars. "Save money" is unbacked outside the US.
4. **Cannot import your own recipes.** No URL import, no photo/OCR import, no cookbook migration — only manual typing, one ingredient at a time. For anyone with a decade of saved recipes this is a wall.
5. **Personal-cookbook depth is shallow.** Cookbooks are folders for *SideChef's* recipes. There is no notion of your own annotated, versioned, private collection.
6. **No food diary, no nutrition tracking, no weight tracking.** Nutrition exists as reference data on a recipe page and stops there. Nothing logs what you actually ate. This is a whole product category SideChef simply does not enter.
7. **No household sharing at all** — meal plans and grocery lists explicitly cannot be shared, and subscriptions are individual-only. A family cannot use it as a family.
8. **Account required before any value is stored.**
9. **Ads inside the product.** Sponsored ingredient substitution in free recipes.
10. **Metric support is a toggle, not a design.** US units are the default and cost data has no metric/NOK equivalent.
11. **Stale build.** 18 months without a fix means reported bugs stay broken.
12. **Offline behaviour unproven** — a video-per-step, price-lookup-driven app is unlikely to work well in a cabin with no signal. `[UNVERIFIED]`

---

## 10. What we should steal — and what to avoid

### Steal

1. **Photo or video at every single step.** Not a photo per recipe — a photo per *step*. It is the reason SideChef gets 4.5 stars in its home market and the reason the NYT called it their favourite. This is the single highest-leverage UX idea in this dossier and it is content work, not engineering.
2. **Voice-advanced hands-free step mode.** Hands are wet, greasy, or holding a pan. Voice to advance a step is the correct interaction model for the cooking screen, and it needs no cloud AI — local keyword spotting on "next" / "back" / "repeat" is enough.
3. **Timers bound to steps, not to a separate timer screen.** The step declares its own duration and the timer starts from the step.
4. **"% of ingredient used."** Telling a cook that a recipe uses 40% of a bunch of coriander is a genuinely original waste-and-leftover insight, cheap to compute, and it feeds a pantry model beautifully.
5. **Free, detailed, per-serving nutrition rendered as a proper %DV panel.** SideChef gives this away and it lifts every recipe page. We should match it and then go further — because our diary means we can total it across a day, which they cannot.
6. **The grocery-list confirm step.** Add-to-list opens a review sheet where you uncheck what you already have before it commits. Small, obviously right, and it is exactly where the pantry should auto-uncheck for us.
7. **Servings scaling 1–16 with live ingredient and cost recalculation.**
8. **Give away more than feels comfortable.** SideChef's free tier is enormous — and it is why the app is loved where it works. Our one-time $25 lets us be even more generous: everything, forever, no tiers to explain.

### Avoid

1. **Do not let a B2B partner set the consumer roadmap.** SideChef's app is frozen at March 2025 while its business site ships case studies in February 2026. Every engineering hour went to the payers, and the payers are not the users. A one-time-purchase model is our structural protection here — our only customer is the person cooking.
2. **Never advertise a feature the user's country cannot use.** SideChef's Norwegian listing promises one-click grocery checkout from four retailers with no caveat, and none of them work in Norway. That single mismatch manufactures 1-star reviews. If we ship anything region-bound, **the store listing must name the region**, and the in-app entry point must be hidden — not present-and-broken — outside it.
3. **Do not build the business on retailer integrations we cannot get.** SideChef's core feature required Walmart-scale partnerships. We cannot get Oda or Meny APIs as a solo developer, so the grocery list must be **complete and excellent as a list** — shareable, printable, orderable by store aisle — and never feel like a degraded checkout funnel.
4. **Do not paywall the steps.** Locking cooking instructions while showing the ingredients is the most resented shape a paywall can take. Our paywall is the purchase, once, and then nothing is locked.
5. **Do not put ads or sponsored ingredients in a recipe.** A cook mid-recipe is a captive audience; substituting a paid brand into their ingredient list is a trust cost that no CPM justifies. This is the clearest thing our business model buys us — say so in the store listing.
6. **Do not block the household.** "We do not support sharing meal plans or shopping lists" and "subscriptions are for individuals only" are indefensible in a *family* cooking app. Shared lists and plans should be a headline feature.
7. **Do not ship a marketing surface you will not maintain.** Three different recipe counts and a dead Facebook Portal on a live sales page tell every prospective user the app is abandoned before they install it.
8. **Own recipe import as the wedge.** SideChef, with $16M and 30 staff, still has no URL import. Every user with a saved-recipe backlog is stranded. That is our beachhead.

---

## Sources

**Store listings (all observed 2026-09-01)**
- Google Play US — https://play.google.com/store/apps/details?id=com.sidechef.sidechef&hl=en_US&gl=US
- Google Play Norway — https://play.google.com/store/apps/details?id=com.sidechef.sidechef&hl=en&gl=NO
- Google Play UK — https://play.google.com/store/apps/details?id=com.sidechef.sidechef&hl=en&gl=GB
- Google Play Germany — https://play.google.com/store/apps/details?id=com.sidechef.sidechef&hl=en&gl=DE
- Apple lookup, US storefront — https://itunes.apple.com/lookup?id=905229928&country=us
- Apple lookup, Norway storefront — https://itunes.apple.com/lookup?id=905229928&country=no
- App Store page — https://apps.apple.com/us/app/side%D1%81hef-easy-cooking-recipes/id905229928

**SideChef consumer site**
- Home — https://www.sidechef.com/
- Premium — https://www.sidechef.com/premium/
- FAQ (pricing, Premium, subscription terms, shoppable links, content partnerships) — https://www.sidechef.com/faq/
- Recipe page showing free nutrition panel, sponsored ingredients and the locked-instructions paywall — https://www.sidechef.com/recipes/7077/mahi_mahi_with_vanilla_sauce/

**SideChef business site**
- Business home — https://www.sidechef.com/business/
- About Us (founders, team roster, mission) — https://www.sidechef.com/business/about-us
- Partners (full retailer / OEM / CPG / publisher list) — https://www.sidechef.com/business/partners
- For Retailers — https://www.sidechef.com/business/retailers
- For Kitchen Appliance Brands — https://www.sidechef.com/business/iot-and-smart-kitchen
- Cost-Per-Order Campaigns — https://www.sidechef.com/business/cost-per-order/
- Success Stories index — https://www.sidechef.com/business/client-projects
- Marks & Spencer Recipe Hub case study — https://www.sidechef.com/business/client-project/marks-and-spencer
- Press index — https://www.sidechef.com/business/press
- Series B / funding press release — https://www.sidechef.com/business/press-releases/sidechef-secures-6-million-in-series-b-funding-to-invest-in-the-future-of-shoppable-recipes
- Edamam partnership — https://www.sidechef.com/business/partners/edamam

**Third-party**
- TechCrunch, founder and commerce model — https://techcrunch.com/2023/03/01/sidechef-commerce-recipe-app/
- Crunchbase — https://www.crunchbase.com/organization/sidechef
- PitchBook (headcount, `[UNVERIFIED]`) — https://pitchbook.com/profiles/company/102399-13
- ZoomInfo (address, `[UNVERIFIED]`) — https://www.zoominfo.com/c/sidechef-inc/374943671
- The Spoon, Electrolux APAC partnership — https://thespoon.tech/electrolux-partners-with-sidechef-to-alter-cooking-journey-in-asian-market/
