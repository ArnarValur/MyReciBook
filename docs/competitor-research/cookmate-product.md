# COOKmate — Product, Features & Pricing

_Researched: 2026-09-01_

## Identity

| Field | Value | Source |
|---|---|---|
| Android package | **`fr.cookbook`** (NOT `com.mizuvoip.cookmate` or `com.grandsoft.mycookbook` — those are unrelated apps) | [Play listing](https://play.google.com/store/apps/details?id=fr.cookbook) |
| Retired paid twin | `fr.cookbookpro` ("COOKmate Pro") — delisted **11 Jul 2022** | [AppBrain](https://www.appbrain.com/app/cookmate-pro/fr.cookbookpro) |
| iOS app | `id1587685734` — "Cookmate - My Recipe Organizer" | [App Store](https://apps.apple.com/us/app/cookmate-my-recipe-organizer/id1587685734) |
| Legacy iOS app | `id1015322975` — "My CookBook (Recipe Manager)", still listed under the same developer | [App Store dev page](https://apps.apple.com/us/developer/maadinfo-services/id1015322704) |
| Publisher | **MAADINFO SERVICES**, 2 All des Ormeaux, 06130 Grasse, **France**. `support@cookmate.io`, +33 6 63 08 31 72 | [Play listing developer block](https://play.google.com/store/apps/details?id=fr.cookbook) |
| On Google Play since | **October 2010** (`fr.cookbook`); Pro since October 2011 | [AppBrain](https://www.appbrain.com/app/cookmate-my-recipe-organizer/fr.cookbook) |
| Name history | "Mes Recettes" (FR, 2010) → "My CookBook" (EN) → **"Cookmate"**, announced **12 Aug 2020** on the app's 10th anniversary | [Rename post](https://cookmate.blog/my-cookbook-becomes-cookmate/) |

**Install and rating counts (observed 2026-09-01):**

| Platform | Installs | Rating | Reviews |
|---|---|---|---|
| Google Play (US locale) | 1M+ (AppBrain estimates **2.3M** lifetime) | 4.7 | 45.8K global / 38.6K US-visible |
| Google Play (NO locale) | 1M+ | **4.5** | 45.8K |
| App Store (US) | n/a | 4.8 | **294** — tiny |
| Amazon Appstore | listed (`B007R63QUG`) | — | — |
| Huawei AppGallery | listed (`C103918609`) | — | — |

Play rating histogram per AppBrain: 32K×5★, 4.3K×4★, 730×3★, 400×2★, **790×1★** — the 1★ bucket is larger than the 2★ and 3★ buckets combined, a classic signature of a monetisation change angering a legacy cohort.

**Maintenance status: actively maintained, low velocity.** Android **5.3.3.7**, updated **6–7 May 2026** (16.5 MB APK, requires Android 6.0+). iOS **1.7.1**, released **11 May 2026** (27.5 MB, iOS 16.6+). Android release notes for 5.3.3 list TikTok import, filtering, pinch-to-zoom on images and Google Sign-In fixes — small, real, shipping work. But AppBrain measures only **~640 downloads in the last 30 days (~21/day)** against a 2.3M lifetime base: this is a mature, slowly declining install engine, not a growth story. It still ranks **#31 Top Grossing, Food & Drink, US**, so the small paying base is disproportionately valuable.

## Positioning

The pitch, verbatim from the Play listing: _"Store all your favorite recipes in one place! COOKmate is a recipe manager with search and import features."_ The web home page frames it as **"Build your private cookbook"** and the meta description says **"Private cloud for collecting and storing recipes from the Web"** ([cookmate.online](https://www.cookmate.online/en/home/)).

That word "private" is the whole differentiator. COOKmate is explicitly **not** cloud-first and **not** a discovery feed: there is no editorial content, no community recipe database, no algorithmic browse. Its unit of value is *your* collection, harvested from other people's websites. The Play listing states the position bluntly: _"The creation of an account on COOKmate Online is optional and the number of recipes is not limited in the Android application if you don't use online features."_

**Target user:** a long-tenured home cook with a large personal archive, frequently migrating from 1990s–2000s desktop recipe software. The import format list (MasterCook, Meal Master, LivingCookBook, RezKonv) is a direct pitch to that migration.

**ASO keywords** (site meta tags, [cookmate.online](https://www.cookmate.online/en/home/)): `COOKmate, My CookBook, Recipes, cook, cooking, recipe, android, app, recipe manager, mastercook, shopping list`. AppBrain's comparison flags the terms COOKmate is **missing** versus category peers: *meal, grocery, keeper, save, organize, plan, meals, planner, AI, organizer, categories, photos, dinner, tiktok, weekly, step, instagram* ([AppBrain keyword compare](https://www.appbrain.com/app/cookmate-my-recipe-organizer/fr.cookbook)). Their title — "COOKmate - My recipe organizer" — burns most of its characters on a brand name nobody searches for.

## Full feature inventory

| Capability | Present? | Detail |
|---|---|---|
| **Web import — supported sites** | Yes | **200+ sites** claimed; the published list runs ~200 entries across 25+ languages ([supported sites](https://www.cookmate.online/sites/)). US English is the deepest (~55 sites: NYT Cooking, Serious Eats, Food Network, Allrecipes, King Arthur, Smitten Kitchen…). **Norwegian: only 2 entries** (arla.no, quorn.no). Danish 11, Swedish 4, Finnish 5. |
| **Unsupported / blocked sites** | Partial | Two fallbacks: (a) a public **site-request and voting board** ([siterequests](https://www.cookmate.online/siterequests/)); (b) an **AI-assisted import** for unsupported sites, capped at **50 recipes/yr free, 500 Premium** ([pricing](https://www.cookmate.online/en/pro/)). No paywall-bypass claim. |
| **User-authored import parsers** | Yes | Users can drop **JSON site definitions** (XPath + regex) into `Android/data/fr.cookbook/files/sitesdef/`, using the RecipeFox Firefox add-on format ([add your own websites](https://cookmate.blog/add-your-own-websites/)). Genuinely open architecture — but the documented toolchain requires Firefox + Java JRE + a SourceForge add-on and was last touched in 2016. |
| **OCR / photo-to-recipe** | Yes, gated | "Scan a recipe" from books/magazines. **Requires a COOKmate Online account**; costs **1 AI credit per scanned area** ([import from photos](https://cookmate.blog/import-a-recipe-from-photos/)). |
| **TikTok import** | Yes, gated | Added in Android 5.3.3 (2026); requires an online account. No Instagram or YouTube import. |
| **Manual entry** | Yes | Multi-line paste that auto-splits into ingredient/step rows; reorder, merge and split line controls; **rich-text formatting** (bold/italic/underline/colour) on Android and web — **not on iOS** ([create/edit](https://cookmate.blog/create-or-edit-a-recipe/)). |
| **Categories / tags / groups** | Yes | User-defined categories (multiple per recipe), tags, and **recipe "groups"** for linking related recipes (e.g. a dough linked to its filling) ([group your recipes](https://cookmate.blog/group-your-recipes/)). No multi-cookbook / notebook concept — requested since 2013, never built. |
| **Custom fields** | Yes, gated | Enable optional fields or define your own at `cookmate.online/fields/`. **Requires an online account with sync enabled** ([custom fields](https://cookmate.blog/add-your-own-custom-fields-to-your-recipes/)). |
| **Search / filter** | Yes | Text search, category filter (optionally pinned to the list), filter improvements shipped 2026. |
| **Scaling servings** | Yes in app; **Premium on web** | Listed as a core app feature, but the web pricing table sells "Scale your recipes" as a **Premium-only** line ([pricing](https://www.cookmate.online/en/pro/)). |
| **Unit conversion** | Weak / absent | No conversion setting exists in the documented Android settings. A user reports metric imports being **auto-converted to imperial with no way to stop it** ([settings comments, Sept 2024](https://cookmate.blog/my-cookbook-settings/)). |
| **Cooking timers** | **No** | No timer appears in any settings page, feature list, changelog or press kit. |
| **Step-by-step cook mode** | **No** | No dedicated cook mode; no keep-screen-awake setting. The nearest thing is **text-to-speech recipe reading** and the Wear OS ingredient/step swipe view. |
| **Shopping list** | Yes | Built from recipe ingredients or the meal planner. Free cloud tier: **1 list**. Printable (iOS 1.2.14, 2023). |
| **Meal planner** | Yes, gated | Weekly/monthly calendar, drag recipes in, adjust servings, generate a week's shopping list. **Requires an online account with sync enabled** ([meal planner guide](https://cookmate.blog/meal-planner/)). Printable. |
| **Pantry / inventory** | **No** | No pantry feature exists anywhere in the product. |
| **Nutrition data** | **Text field only** | The XML schema exposes `<nutrition>` described merely as *"Nutritional information"* — a **free-text blob** carried over from the source website ([XML schema](https://cookmate.blog/my-cookbook-xml-schema/)). No ingredient database, no per-serving calculation, no macros, no scaling of nutrition with servings. |
| **Food diary / logging** | **No** | Does not exist. |
| **Ratings & notes** | Yes | `<rating>` 1–5 integer, plus a free-text `<comments>` field and a `<source>` field. |
| **Photos per recipe** | Yes | Own photos, imported image URLs; pinch-to-zoom added 2026. Images stored in a user-configurable directory (relocatable to external SD). AI image generation via **DALL·E**, 10 credits per image. |
| **Import formats** | Extensive | `.mcb` (own; ZIP archive **with pictures**), `.xml` (own; **no pictures**, public XSD), Meal Master `.mmf/.mm/.txt`, MasterCook `.mz2/.mx2/.mxp/.txt`, LivingCookBook `.fdx`, RezKonv `.rk/.txt`, CookML `.cml`, CookBook Wizard `.txt`, Springpad `.json`, Handy CookBook `.hcb`, Digital Recipe Sidekick `.xml`; **CSV** on the website ([file import/export](https://cookmate.blog/file-importexport/), [CSV import](https://cookmate.blog/import-csv-files/)). |
| **Export formats** | Good | `.mcb` and `.xml` to local storage or **Dropbox**; **PDF export** from the website since 16 May 2024. Documented caveat: exporting to non-native formats **loses comments, source URL and cooking time**. |
| **Automatic local backup** | Yes | The app writes a `.mcb` backup to the device **daily** by default, frequency configurable in settings ([Android settings](https://cookmate.blog/my-cookbook-settings/)). This is the single best data-safety behaviour in the product. |
| **Cloud sync** | Yes, quota-limited | Two-way sync to COOKmate Online, default **every 1 hour**, configurable, can be set to **Never**. Optional "auto-delete" mirror of server deletions. |
| **Dropbox sync/backup** | Yes, Android only | Separate from cloud sync; export destination and device-to-device transfer path. |
| **Web app** | Yes | [cookmate.online](https://www.cookmate.online) — full CRUD, categories, meal planner, shopping lists, scan, AI, PDF export, custom fields. |
| **Cross-platform** | Android, iOS, web, Amazon, Huawei | Android is the lead platform and is materially ahead of iOS (formatting, Dropbox, Wear OS, TTS are all Android-only). |
| **Wearables** | Yes | Wear OS app with a **tile** for the most recently cooked recipe; swipe through ingredients then directions ([Wear OS v2](https://cookmate.blog/open-your-recipes-on-your-android-wear-watch-v2/)). |
| **Voice assistants** | Alexa only | Alexa skill live since 30 Mar 2020. The **Google Assistant action was killed by Google on 13 Jun 2023** — yet the Play listing still advertises "your voice assistants OK Google and Alexa" ([Google action post](https://cookmate.blog/cookmate-google-action/)). Stale store copy. |
| **Chromecast / TV** | **No** | No evidence of any TV or cast target in any listing, changelog or docs. |
| **Widgets / shortcuts** | Partial | Android long-press **app shortcuts** (5.1.63) and iOS Home Screen quick actions; no true home-screen widget documented. |
| **Sharing between users** | Yes | "Friends" — invite others, view their cookbooks. **Requires an online account**. Plus share to Facebook/email/SMS and `.mcb` file handoff. |
| **Printing** | Yes | Recipes, shopping lists (2023) and the meal planner (2022). |
| **Offline behaviour** | Excellent | Full local database; unlimited local recipes; no account required; daily local backup. |
| **Languages** | 20+ app / 12 iOS | Play claims "more than 20 languages"; iOS lists 12 (EN, DA, NL, FI, FR, DE, EL, IT, JA, PT, SK, ES). **Crowd-translated** via a public portal. **No Norwegian and no Icelandic** in the iOS list. |

## Free vs paid — what is actually limited

The publisher's own support matrix ([Zendesk](https://mycookbook.zendesk.com/hc/en-us/articles/200594822-I-have-COOKmate-Android-app-Do-I-have-to-create-on-online-account), updated Aug 2024):

| | App offline (no account) | App + Free account | App + Premium account |
|---|---|---|---|
| Recipes **on device** | unlimited | unlimited | unlimited |
| Shopping lists **on device** | unlimited | unlimited | unlimited |
| Recipes **in cloud** | 0 | **60** | 20,000 |
| Shopping lists **in cloud** | 0 | **1** | 10,000 |
| Manage on any computer/device | No | Yes (until limit) | Yes |
| Multi-device sync | No | Yes (until limit) | Yes |
| Friends' recipes | No | Yes (until limit) | Yes |
| Meal planner | **No** | Yes (until limit) | Yes |
| Scan a recipe (OCR) | **No** | Yes (until limit) | Yes |
| ChatGPT recipe creation | **No** | Yes (until limit) | Yes |
| **Ads** | **Yes** | **Yes** | No |

Three things matter here.

1. **The free local app has no recipe cap.** That is the honest, unusual part of the model and the reason for the loyal base.
2. **Ads run even in fully offline use.** There is now *no* way to remove ads except an active subscription. Ads were introduced deliberately: the iOS 1.2.2 changelog (3 Oct 2022) reads _"Maintenance and support of COOKmate requires a lot of time... To be able to continue working on the app, we have added ads in recipes for free users"_ ([App Store version history](https://apps.apple.com/us/app/cookmate-my-recipe-organizer/id1587685734)).
3. **Every modern feature is behind the account, not just the cloud.** Meal planner, OCR, custom fields and AI all require a COOKmate Online account with sync enabled — so the "offline-first" promise quietly stops at the feature boundary.

**The free tier has shrunk over time.** In 2017 support stated the free cloud allowance was **105 recipes and 8 shopping lists** ([support comment, Oct 2017](https://mycookbook.zendesk.com/hc/en-us/articles/200594822-I-have-COOKmate-Android-app-Do-I-have-to-create-on-online-account)). It is now **60 recipes and 1 shopping list** — a ~43% cut in recipes and a 87% cut in lists.

**AI credits** (introduced ~Mar 2026): free 50/month, Premium 500/month. Spend rates: AI recipe generation 1, AI import of an unsupported site 1, recipe scan 1 per scanned area, **image generation 10** ([AI credits](https://cookmate.blog/how-to-use-your-cookmate-ai-credits/), [pricing](https://www.cookmate.online/en/pro/)).

## Pricing

All prices observed **2026-09-01** unless noted.

| Channel | Plan | Price | Notes |
|---|---|---|---|
| **Website** ([cookmate.online/pro](https://www.cookmate.online/en/pro/)) | Premium quarterly | **€6 / quarter** (or **$6**) | ≈ €24/yr |
| **Website** | Premium yearly | **€20 / year** (or **$20**) | Cheapest route to Premium |
| **App Store (iOS)** | Premium monthly | **$1.99 / mo (US)**, **€2.39 / mo (EU)** | ≈ $23.88/yr |
| **App Store (iOS)** | Premium yearly | **$22.99 / yr (US)**, **€24.99 / yr (EU)** | Added in iOS 1.5.0, Mar 2025 |
| **Google Play (Android)** | Premium monthly | listed as "In-app purchases"; **price range not published on the Play page** | Play subscription enabled in Android 5.1.53. Support states monthly is the only mobile-app option; quarterly/yearly must be bought on the website ([Zendesk](https://mycookbook.zendesk.com/hc/en-us/articles/200552312-How-to-Subscribe-to-a-Premium-Account)) |
| **Norway / NOK** | — | **No NOK price published** on any COOKmate surface; the Norwegian Play listing exposes no IAP price range. `[UNVERIFIED]` — assume Play/App Store standard NOK tiers (≈ NOK 25–29/mo, ≈ NOK 249 /yr) |
| **RETIRED — COOKmate Pro** (`fr.cookbookpro`) | **One-time purchase, ad-free** | **$5.99 one-time** | On Play Oct 2011 → **removed 11 Jul 2022**. Last version 5.1.59 (31 May 2022). 22K downloads, 4.51★, 2,754 ratings ([AppBrain](https://www.appbrain.com/app/cookmate-pro/fr.cookbookpro)) |

Store listings claim **1 month or 1 year** durations; the website sells **3 months or 1 year**. So the same product has three price ladders (web €20/yr, iOS $22.99/yr, Play monthly-only) and the developer keeps ~100% of the web one. The website is cheaper than the App Store yearly by roughly 13%.

### The one-time → subscription pivot — the part that matters to us

This is documented, not inferred:

- **Oct 2011 – Jul 2022**: a **$5.99 one-time ad-free "Pro"** app shipped alongside the free app. Its listing carried an explicit disclaimer: _"COOKmate Pro (Ad-Free) does not include a subscription for COOKmate Online Premium"_ — the one-time purchase never bought cloud.
- **Android 5.1.53** changelog: _"It is now possible to subscribe to Premium with the Google Play Store."_ The subscription rail was added *inside* the paid app.
- **11 Jul 2022**: COOKmate Pro is **removed from Google Play**. Existing owners keep it; nobody can buy it again.
- **3 Oct 2022**: ads are added to the free apps for the first time ([iOS 1.2.2 changelog](https://apps.apple.com/us/app/cookmate-my-recipe-organizer/id1587685734)).

The user reaction is on the record. A Play review captured by AppBrain (7 Jul 2026): _"Paid for the original Pro version to get rid of ads, but now that version was silently discontinued in favor of a subscription version. Not paying this company a second time for the same thing."_ And the developer's own defence, in a 2018 support thread: _"maintenance and support of My CookBook require a lot of time... the supported websites always change and I continuously update the import engines. If I want to continue to work on it, I need to ask a monthly / annual subscription."_

**The lesson for MyReciBook is precise, not general.** COOKmate did not fail at one-time pricing; it failed to make one-time pricing *cover a recurring cost*. Their recurring cost is the **import scraper fleet for 200+ sites** plus a **cloud sync service** — both of which cost money every month forever. Our $25 one-time is only defensible if the recurring costs it must fund are bounded: device-local storage, no server sync obligation, and an import path that degrades gracefully rather than requiring a maintained parser per site.

## Sync and data ownership

**Where recipes live:** on the device, in a local database, always. The cloud copy is optional and quota-limited. This is the opposite of Paprika/ReciMe-style cloud-primary designs.

**Fully offline:** yes. No account required to install, import from a URL, create, edit, scale, shop or export.

**Backup/restore:** three independent paths — automatic daily `.mcb` on device; manual `.mcb`/`.xml` export to local storage or Dropbox; server-side sync plus PDF/file export from the web. Recipes are recoverable without the company's cooperation as long as the user ever exported.

**Account requirement:** optional for the app, mandatory for meal planner, OCR, custom fields, friends, AI and any multi-device sync.

**If the company disappears:** local recipes survive indefinitely; daily `.mcb` backups survive. What dies is the **import engine** (the site definitions and AI import are server-fed), sync, the web app, friends, the meal planner and the Alexa skill. Since the import engine is the app's core value, the practical answer is *your data survives, the product does not*.

**Subscription lapse behaviour** is unusually decent and worth copying: recipes are **not deleted**. Over-quota recipes and lists become **read-only**, and app↔cloud sync is disabled ([Zendesk](https://mycookbook.zendesk.com/hc/en-us/articles/200541891-Will-I-Lose-My-Recipes-and-Shopping-Lists-When-My-Premium-Subscription-Ends)). No hostage-taking.

**GDPR/EEA:** French controller (Grasse, France), so GDPR applies natively; Norwegian users are covered on the same EEA footing. The Android app exposes a **"Privacy Options — customize your GDPR settings"** screen, and settings include **"Close your Cookmate Online account"**, which permanently deletes the account and all server-side recipes ([settings](https://cookmate.blog/my-cookbook-settings/)). Play Data Safety declares data sharing with third parties (app activity, app info/performance), encryption in transit and a deletion request path. iOS App Privacy is heavier: **identifiers used to track you across apps**, plus coarse location, device ID and advertising data linked to identity for third-party advertising and analytics.

## Ecosystem

- **Companion web app** — [cookmate.online](https://www.cookmate.online), full-featured, the primary Premium sales channel. Django-style stack, CloudFront assets.
- **Browser extensions** — **Chrome Web Store** (`ldbehgakcmbdalmpdfjedahogegmgpba`, still published under the old "my-cookbook" slug) and **Firefox add-on** ([links page](https://cookmate.blog/links/)). Plus a **bookmarklet** for any other browser.
- **Alexa skill** — live since Mar 2020 (`B0BWYMJ29R`). **Google Assistant action — dead since Jun 2023.**
- **Wear OS app + tile.**
- **Community** — Facebook, Instagram, X (EN + FR), Bluesky; a public **site-request voting board**; a public **crowd-translation portal**; and a public Zendesk help centre where the founder ("Carine") answers personally. Also a documented **Android beta programme**.
- **Import from other apps** — strong on *legacy desktop* software (MasterCook, Meal Master, LivingCookBook, RezKonv, CookML, Springpad, Handy CookBook, Digital Recipe Sidekick) and generic CSV. **No documented importer for Paprika, ReciMe, Cookpad, Whisk, AnyList or Recipe Keeper** — the modern competitive set is entirely absent.
- **Export to other apps** — only via the shared legacy formats, with the documented warning that comments, source URL and cook time are dropped.

## Business signals

- **Marketing: essentially none.** The press kit was last edited **28 Jun 2022** and still claims *"1,000,000 downloads, 150,000 active users, translated in more than 20 languages"* ([press page](https://cookmate.blog/reviews/)). The listed press coverage is concentrated in **2012–2016** (AndroidPit, Softonic, Clubic, CHIP, NDTV, Android Police) with almost nothing after 2019. There is no content engine, no influencer motion, no paid UA visible.
- **Monetisation mix:** ads (AdMob-class, on every free user including offline ones) + subscriptions on three channels + AI credit scarcity as an upsell lever.
- **Revenue scale:** Sensor Tower's public overview pages indicate roughly **7K downloads and ~$6K revenue per month in the US**, and **7K downloads / ~$7K per month in France** (figures surfaced via search snippet of a gated page, ~mid-2025) — `[UNVERIFIED]`, gated source. Triangulating against **#31 Top Grossing Food & Drink (US)** and ~21 installs/day, this reads as a **low-to-mid six-figure annual business run by a very small team** — plausibly one or two people.
- **Longevity: 16 years and still shipping.** That is the genuinely impressive number. It also means a deep moat of legacy users with large archives who are expensive to move.
- **Team signal:** the same person ("Carine") answers support tickets, blog comments and App Store reviews going back to 2013. Single-maintainer risk is high, but so is the credibility with the base.

## Gaps and weaknesses

Concrete and honest — these are the openings.

1. **Nutrition is a text field, not a feature.** `<nutrition>` is a free-text blob copied from whatever website the recipe came from. No ingredient database, no calculation, no per-serving math, no macro breakdown, and nutrition does **not** rescale when you scale servings. Anyone who wants to know what they actually ate has to leave the app.
2. **No food diary at all.** Zero logging, zero history, zero "what did I eat this week". This is a whole product category they have not touched.
3. **No pantry, no inventory, no expiry.** Shopping lists are generated *from* recipes and then forgotten. There is no notion of what you already own, so lists are always wrong.
4. **No cooking timers and no cook mode.** In 16 years they never shipped a timer or a screen-awake step-through view. The nearest substitutes are text-to-speech and a Wear OS swipe list. For a "kitchen companion" this is a startling hole.
5. **Design is dated.** The visible affordances are theme pickers, font-size sliders, "tablet layout vs phone layout with tabs", and colour pickers for ingredient text — 2014-era Android customisation in place of a coherent design system. Screenshots and the web app share a flat green/grey aesthetic that has not been meaningfully refreshed since the 2020 rebrand.
6. **Onboarding is hostile.** A Play reviewer (Jun 2026): _"I don't want to log in, just want to see recipes with pictures and how to cook... So many unnecessary things to do, import add? Just deleted this."_ There is no seeded content, so a new user's first screen is an empty cookbook with an ad in it.
7. **Ads on paying-adjacent users and no ad-free one-time.** Offline users who will never touch the cloud still get ads, and the only exit is a subscription for a cloud they do not want. This is the single most-resented thing about the product.
8. **The free tier was cut** from 105 recipes / 8 lists to 60 / 1. Users who remember the old numbers experience this as a takeaway.
9. **Nordic coverage is nearly nonexistent.** Two Norwegian import sites. No Norwegian UI language. No Icelandic anything. For a Norway-based launch this is an unguarded flank.
10. **AI is bolted on and rationed.** ChatGPT recipe generation, DALL·E images and AI import are metered in credits (10 credits per image against 50/month free = five images). It reads as a cost-control mechanism, not a feature.
11. **iOS is a second-class port** with a 294-rating footprint, missing text formatting, Dropbox, Wear and TTS.
12. **Stale store copy.** The Play listing still promises Google Assistant support that Google killed in June 2023.
13. **Import fragility is structural.** 200+ hand-maintained site definitions is a treadmill; when a site changes markup, import breaks, and the user-facing remedy is a voting board. Users report exactly this (BBC Good Food ingredient lists needing hand-editing every time).
14. **Single-maintainer concentration risk**, with a 16-year archive of other people's family recipes riding on it.

## What we should steal — and what to avoid

**Steal:**

1. **The "unlimited local, quota'd cloud" split, but honest.** Their best idea is that the *device* is never limited and only the *server* is. Keep that shape, then remove the sting: with a one-time purchase and no server obligation, we can offer unlimited local **and** no ads **and** no account, which is strictly better than anything COOKmate can offer at any price.
2. **Automatic daily local backup to a user-visible file.** COOKmate silently writes a dated `.mcb` to device storage every day. It is the cheapest trust-building feature in the product and almost nobody copies it. Ship this on day one.
3. **A real, documented, self-contained archive format.** `.mcb` = a ZIP with recipes **and images**; `.xml` = text-only with a **published XSD**. Two formats, two honest trade-offs, publicly specified. We should publish our schema too — it is the strongest possible answer to "what if you disappear", and it costs nothing.
4. **Read-only degradation instead of data hostage-taking.** Over-quota content stays visible and exportable, only editing stops. Whatever we gate, gate it this way.
5. **The legacy-format import list as a migration wedge.** MasterCook / Meal Master / LivingCookBook / CSV import is why 50-year-old recipe archives end up in COOKmate. Cheap to implement, and it converts the most loyal, highest-value users in the category. **Then go further than they did** and import from **Paprika, Recipe Keeper, ReciMe, AnyList and Cookpad**, which they conspicuously do not support.
6. **User-extensible import definitions.** The idea of a declarative, user-supplied parser (`sitesdef/*.json`) is excellent and lets the community cover the long tail without the developer maintaining it. Steal the concept; replace the execution — a Firefox add-on plus a Java JRE plus SourceForge is not a 2026 onboarding path. Better modern answer: parse **JSON-LD / schema.org Recipe** first (which covers the large majority of real recipe sites with zero per-site maintenance), fall back to a heuristic parser, and only then to a per-site override.
7. **Recipe "groups"** — linking a dough recipe to the pie that uses it. Small, distinctive, genuinely useful, and nobody else does it.
8. **The public site-request voting board.** It converts breakage complaints into a prioritised roadmap and makes users feel heard for the price of a form.
9. **Crowd-translation portal.** How a one-person team ships 20+ languages. Directly relevant to Norwegian and Icelandic coverage we would otherwise have to fund.
10. **Custom fields.** Users get to extend the recipe schema themselves, which absorbs an endless stream of feature requests. Ours should be local, not account-gated.

**Avoid:**

1. **Never take away a purchased tier.** Delisting Pro is the origin of the 790 one-star reviews. Whatever we sell for $25 must be honoured forever, including on reinstall and new devices.
2. **Never show ads to someone who paid, and preferably not to anyone.** Ads on offline users is their most-hated decision.
3. **Never shrink the free tier.** 105→60 recipes reads as theft even when the app is still generous.
4. **Do not gate core kitchen features behind an account.** Meal planner, OCR and custom fields requiring a login is what breaks their offline-first promise. Ours should work signed-out.
5. **Do not build a per-site scraper fleet as the primary import path.** It is an unbounded recurring cost — exactly the cost that forced their subscription — and it is incompatible with a one-time price.
6. **Do not ship 2014 customisation in place of design.** Font-size sliders and ingredient colour pickers are what you build when there is no design system.
7. **Do not leave the store listing lying.** Advertising a dead Google Assistant integration for three years erodes the trust their support quality earns.

## Sources

- Google Play — COOKmate (`fr.cookbook`): https://play.google.com/store/apps/details?id=fr.cookbook
- App Store — Cookmate (`id1587685734`), incl. full version history and App Privacy: https://apps.apple.com/us/app/cookmate-my-recipe-organizer/id1587685734
- AppBrain — `fr.cookbook` stats, rankings, rating histogram, download velocity: https://www.appbrain.com/app/cookmate-my-recipe-organizer/fr.cookbook
- AppBrain — COOKmate Pro (`fr.cookbookpro`), $5.99 one-time, delisted 11 Jul 2022: https://www.appbrain.com/app/cookmate-pro/fr.cookbookpro
- COOKmate Online — home & pricing: https://www.cookmate.online/en/home/
- COOKmate Online — Premium pricing and AI credits: https://www.cookmate.online/en/pro/
- COOKmate Online — supported sites list: https://www.cookmate.online/sites/
- COOKmate Online — site request board: https://www.cookmate.online/siterequests/
- Blog — feature overview: https://cookmate.blog/
- Blog — "My CookBook becomes Cookmate" (12 Aug 2020): https://cookmate.blog/my-cookbook-becomes-cookmate/
- Blog — File import/export & formats: https://cookmate.blog/file-importexport/
- Blog — XML schema (incl. `<nutrition>` as free text): https://cookmate.blog/my-cookbook-xml-schema/
- Blog — Add your own websites (JSON site definitions): https://cookmate.blog/add-your-own-websites/
- Blog — Android settings (backup, sync frequency, GDPR options): https://cookmate.blog/my-cookbook-settings/
- Blog — Meal planner guide: https://cookmate.blog/meal-planner/
- Blog — Import a recipe from photos: https://cookmate.blog/import-a-recipe-from-photos/
- Blog — Custom fields: https://cookmate.blog/add-your-own-custom-fields-to-your-recipes/
- Blog — Group your recipes: https://cookmate.blog/group-your-recipes/
- Blog — AI credits: https://cookmate.blog/how-to-use-your-cookmate-ai-credits/
- Blog — Google Assistant action removed 13 Jun 2023: https://cookmate.blog/cookmate-google-action/
- Blog — Downloads & links (Chrome/Firefox extensions): https://cookmate.blog/links/
- Blog — Press kit and press coverage: https://cookmate.blog/reviews/
- Support — free vs premium matrix: https://mycookbook.zendesk.com/hc/en-us/articles/200594822-I-have-COOKmate-Android-app-Do-I-have-to-create-on-online-account
- Support — subscription lapse behaviour: https://mycookbook.zendesk.com/hc/en-us/articles/200541891-Will-I-Lose-My-Recipes-and-Shopping-Lists-When-My-Premium-Subscription-Ends
- Support — how to subscribe (web quarterly/yearly vs mobile monthly): https://mycookbook.zendesk.com/hc/en-us/articles/200552312-How-to-Subscribe-to-a-Premium-Account
- Support — how to back up recipes: https://mycookbook.zendesk.com/hc/en-us/articles/21107728348178-How-Can-I-Back-Up-My-Recipes
- Sensor Tower overview pages (gated; revenue figures `[UNVERIFIED]`): https://app.sensortower.com/overview/fr.cookbook?country=US
