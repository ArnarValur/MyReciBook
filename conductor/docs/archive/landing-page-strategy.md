# Landing page strategy — myrecibook.com

Researched and written 2026-08-19 by the marketing/frontend agent. Inputs: the Code
agent's product brief (2026-08-19), `marketing-channels.md` (2026-08-06), and three
fresh research passes (competitors, pricing sentiment, landing-page patterns), all
source-linked at the bottom. Framework deliberately not chosen yet — this doc is
what the page says and shows; the build constraints section is framework-agnostic.

The clock that matters: Gate 2 wants 200 signups with community posts staggered
through September, external deadline Sun 20 Sep. The page must be live before the
first post. Counting back from today, that means copy locked and page live within
~2 weeks.

---

## 1 · Fact-check of the brief — where it holds, where it breaks

| Brief claim | Verdict | Evidence |
|---|---|---|
| Screenshot import on Android is rare | **Breaks.** It's crowded now. | ReciMe (1M+ installs, top-grossing Food & Drink, screenshot import is core), CookBook, Samsung Food (3 free scans, then Food+), Flavorish, Honeydew, Umami all do AI photo/screenshot import on Android; Recipe Keeper does classic OCR. |
| "None of them can follow quickly" | Holds **only** for Crouton/Mela/Pestle (Apple-locked, verified still Apple-only Aug 2026). ReciMe already followed. | `marketing-channels.md` §7 reached the same conclusion. |
| "No Android" is the top complaint vs Crouton/Mela/Pestle | Plausible, **unproven** — Reddit is unreachable from research tooling. Indirect: rivals run "Crouton alternative for Android" SEO pages; press tells Android users to use Samsung Food. | Internal aiming only. Never page copy. |
| The moat | **Restate it.** The unoccupied ground is the *combination*: AI screenshot import **+** plain local files **+** no account **+** pay once. No mainstream Android app has it. Every AI-quality importer is subscription + cloud account. The closest exceptions are small or partial (Recipe One: one-time but OCR-tier and unproven; Recipe Keeper: OCR, no AI; RecetteTek/Cookmate: own-cloud files, no AI). | Competitor research pass, section 3–4. |
| $25 one-time | **Holds, with the right anchor.** It equals Crouton Plus exactly — and Crouton *still* charges $1.99/mo extra for AI import, which produces its angriest reviews. It's less than one year of ReciMe ($39.99/yr) or Samsung Food+ ($59.99/yr), equal to one year of Pestle ($25/yr, lifetime $39.99–49.99). Against Paprika ($4.99) or Mela ($6.99) it looks greedy — never let those be the comparison; neither includes server-side AI. | Pricing pass, sections 2–3. |
| Stated AI cap with one-time price | **Normalized, not weird.** AppSumo now says openly that AI-era lifetime deals ship with stated allowances; 1min.AI sells a $24.97 lifetime with a stated monthly credit cap. Rule: denominate in the user's unit ("recipe rescues"), never abstract credits. | Pricing pass, section 3. |
| "Own your files" has an audience | **Confirmed.** Obsidian (~1.5M MAU) monetizes optional sync on top of free local files; "File over app" is a rallying cry; HN quotes on recipe apps: "I'd much rather pay once upfront than a subscription", "an alternative that belongs to the user, not a subscription service". Anova's $1.99/mo move caused a documented user revolt. | Pricing pass, sections 4–5. |
| Brief's page spine (capture at the bottom) | **Amend.** Waitlist evidence says: email field in the hero, one CTA, no site navigation, under two scrolls, founder block for trust. All six competitor sites do zero email capture — they're launched; their structure is the wrong template. Their *proof* patterns transfer (Pestle's is best: real UI in motion + dated reviews + honest pricing table). | Landing-page pass, sections 1–2. |
| A/B test two positionings on the page | **Drop on-page A/B.** ~200 signups implies ~1,800 visitors at the ~11% waitlist median; no test reaches significance at that traffic. Instead: one stable page, one angle per venue (as `marketing-channels.md` already assigns), UTM-tagged links per post, compare signup sources. | Landing-page pass, section 2. |
| 200 signups target | Ambitious but real: the average finished waitlist collects ~148. At the ~11% median you need ~1,800 visitors — the page is the bucket, the September community posts are the water. | Landing-page pass, sections 2–3. |

Three risks, plainly:
- If the page claims "the only screenshot recipe app on Android," one Google search
  falsifies it and the trust positioning dies on first contact.
- If a price appears publicly before Arnar confirms it, it can never be walked back.
- If the visuals are mockups instead of real S21 captures, an unlaunched product
  reads as vaporware and the emails don't come.

## 2 · Positioning — the sentence the whole page serves

> **MyReciBook rescues the recipes buried in your camera roll — and what it makes
> is yours: plain files in your folder, no account, no subscription, pay once.**

The emotional hook (camera roll) opens; the structural moat (files + no account +
pay once) closes. Subscription apps can copy the first half; copying the second
half breaks their business model — that's what makes it a moat.

Venue angles (not page variants): "own your files, pay once" for r/SideProject,
XDA, and later Show HN; "rescue your camera roll" / "grandma's recipe box" for the
Facebook cooking groups. Same page, different first sentence in each post.

## 3 · Page blueprint — one page, no nav, under two scrolls

> **Mockup exists:** `docs/myrecibook-landing-mockup.html` (2026-08-19) — the
> design authority per the "newest wins" rule. Dashed outlines mark slots for
> real S21 captures; the MailerLite embed replaces the placeholder form.

Every visual is a real capture from the S21 build. Sentence case everywhere.
Material Symbols Rounded, never emoji. Tertiary red-violet appears exactly once:
the ONE-TIME badge.

**1. Hero — the whole product in one screen**
- Headline options (pick one, gut call):
  - A. "Collect the recipes buried in your camera roll." *(the tested in-product line)*
  - B. "Your camera roll is eating your recipes."
  - C. "That recipe you screenshotted three weeks ago? Found in seconds."
- Sub-line: "MyReciBook turns recipe screenshots into a clean, searchable cookbook —
  on Android. No subscription. No account. Your recipes are plain files in a folder
  you own."
- Email field + one button: "Email me at launch". Micro-line beneath: "Launching on
  Google Play, December 2026. A few progress notes before then — nothing else,
  unsubscribe anytime."
- Visual beside/below: before-and-after. Left: a staged messy gallery grid (recipes
  drowning among 4,000 photos). Right: the same recipe as a clean MyReciBook card.
  A 15-second muted loop (screenshot → review → saved recipe) beats a static image
  if the capture is good — and the same clip is the r/SideProject demo GIF, made once.

**2. The three promises — three compact cards**
- **Screenshots first.** "Instagram, TikTok, your mum on WhatsApp. Pick one
  screenshot or a whole pile — one recipe across five shots gets stitched, five
  different saves become five recipes. Nothing is saved silently: you review, you
  confirm, done. Cookbook pages and handwritten cards welcome, by camera. And typing
  one in yourself is always unlimited."
- **Your files, not our cloud.** "One plain, readable file per recipe, in a folder
  you pick, on your phone. Back up to your own Google Drive or Dropbox. Delete the
  app and every recipe is still there. No account. No login. No tracking. Ever."
- **Pay once.** "You buy MyReciBook like you'd buy a good knife: once. AI rescues
  have a fair-use cap stated in writing — and typing is always free and unlimited."

**3. The grocery list — the money shot**
- Headline: "The grocery list that actually merges."
- Copy: "Add two recipes and 'lemon' + 'lemons' become one row — 6 lemons, from 2
  recipes — and only after asking you. Move an item to your own aisle once and it
  lands there every time after. Salt, pepper and oil stay quiet unless you tap them."
- Visual: the merge prompt itself — **Merge · 6 lemons / Keep apart** — it's the
  money shot because it shows the app asking instead of guessing.
- Beneath, a quiet one-line strip of other shipped things: cook mode that keeps the
  screen awake and finds timers inside steps · as-written / metric / US display
  toggle · favorites and tags that live in your files · search across everything.
- Trap to avoid: the bet doc mentions the grocery list syncing with the meal plan —
  meal planning is switched off and must not appear here in any form.

**4. Know your food — nutrition without another subscription**

- Promoted 2026-08-19, S21-proven per Arnar: tags/categories, nutrition
  calculator, pantry-built recipes, food logging. The product brief's "say
  favorites, not tags" rule is dissolved — tags shipped.
- Headline: "Your pantry knows its numbers."
- Copy: "Scan a barcode off the shelf and the pantry fills itself — name, brand,
  pack size and the full nutrient list per 100g, vitamins included when the
  database knows them. Link '250 ml milk' to the actual milk you scanned, and
  recipes show per-serving numbers computed from your own food. Build a new
  recipe straight out of the pantry. Log what you actually ate, day by day.
  All of it is AI-free — the whole nutrition kit lives on the never-capped
  side, forever."
- Visual: a recipe's per-serving nutrition numbers, with the barcode-scan
  moment as the secondary shot.
- Keep the MyFitnessPal comparison off this page (no competitor names). It
  belongs in ASO/listing experiments after launch — their users are still angry
  about barcode scanning going behind Premium, a second audience for later.

**5. Ownership — the paragraph that converts the sceptics**
- Headline: "Delete the app. Keep every recipe."
- Prose, not bullets: the folder is the app; one JSON file per recipe you can open
  in any text editor; backup is a one-way mirror to your own Drive/Dropbox, restore
  never overwrites; the settings screen has three blocks because there is no
  telemetry to toggle.
- Visual: an actual recipe JSON open in a file manager / text editor on the phone.
  For the r/SideProject and XDA crowd this single screenshot does more than any
  paragraph.

**6. Pay once — price block**
- "Pay once. Cook forever." + **ONE-TIME** badge (tertiary, the page's only use).
- Price: **$25 — confirmed by Arnar 2026-08-19.** Safe for public copy; carry it
  into the next conductor checkpoint so the app, listing and page all say the same number.
- The in-app paywall card, mirrored: every recipe, forever, in your storage ·
  600 AI recipe rescues — fair-use cap, in writing · a grocery list that actually
  merges · all future features included. ("600" is also a working number — confirm
  alongside the price.)
- Directly beside the cap, always: "Typing recipes in yourself is unlimited. The
  cap can go up over time; it can never go down."
- Anchor line: "Less than a single year of the big subscription recipe apps."
  True and checkable ($39.99–59.99/yr). Name no competitor on the page.

**7. Founder note + second email form**
- Short, first-person, photo optional: built solo, by one cook; it runs on my own
  Galaxy S21 every day; pay-once because there's no investor asking me to charge
  rent. This block doubles as the honest consent framing for the email signup.
- Repeat the email field + button. Footer: privacy policy link, contact address,
  logo. No nav anywhere.

**Success page / welcome email — where the testers come from**
- Success page: "Check your inbox to confirm." Welcome email asks the warmest
  Android signups: "I need 12 closed testers before Google lets me launch — want
  in early? One tap." This feeds the 12-tester/14-day quota from the top of the
  list without splitting the page's single CTA. (Matches the tester pipeline in
  `marketing-channels.md` §2.)

## 4 · What must never appear on the page

Meal planning in any form (food *logging* — past tense, shipped — is fine;
*planning* stays off) · "unlimited" anywhere near AI · iOS or a web app ·
"create an account" · a subscription tier · fake counters, invented testimonials,
or star ratings we don't have · "the only app that…" claims · competitor names ·
Paprika/Mela price comparisons · the price before it's confirmed · "as seen on
Reddit" (unverifiable) · superlatives ("world's best") · ALL-CAPS outside the tiny
section labels.

We have no reviews yet, so the trust budget is: real screenshots, the founder
note, the cap stated in writing, and restraint.

## 5 · Build constraints for the eventual framework choice

1. One static page + one plain privacy page. Zero backend — the site must not
   grow one; the extraction proxy stays app-only.
2. Email: MailerLite free tier (1,000 subscribers, EU company, embedded form,
   double opt-in switched on). Collecting EU/EEA emails means GDPR + ePrivacy
   apply regardless of where the business sits: prior opt-in for marketing mail,
   sender name + address + unsubscribe in every message, double opt-in as the
   consent proof. The exact national statute follows the business's country of
   establishment — confirm with Arnar for the privacy policy. Fallback if 1,000
   subscribers ever binds: Kit free tier.
3. Mobile-first — 60%+ of waitlist signups happen on phones, and ours arrive from
   phone-first communities.
4. Self-host the fonts (Plus Jakarta Sans, Inter). Loading them from Google Fonts
   is a documented GDPR foot-gun in the EU.
5. Tokens from `docs/design/handoff.md`; logo from `docs/MyReciBook-logo/assets/logo/`.
   Light "Stitch Slate" first (warm cream `#FAF8F0`, primary `#24389C`, blue-tinted
   shadows); dark "Midnight" via `prefers-color-scheme` is a nice-to-have, not a gate.
6. Weight budget ~1MB: compress the screenshots, poster-frame the loop, no video
   autoplay on data-saver.
7. UTM parameters on every community-post link; MailerLite groups per source so
   the venue comparison is measurable without any analytics script on the page.

## 6 · Asset checklist (all from the real S21 build)

1. Staged messy gallery grid with recipe screenshots scattered in it.
2. Review screen mid-confirm (a low-confidence line visible — honesty as a visual).
3. A finished recipe card, cover on.
4. The merge prompt: Merge · 6 lemons / Keep apart.
5. Grocery list with an "in your pantry" hint row and a "your aisle" tag.
6. A recipe's JSON file open in a text editor / file manager.
7. 15-second screen recording: pick screenshot → review → saved recipe (page loop
   + r/SideProject GIF + the eventual Play listing video, one capture session).
8. Barcode scan in action (torch on, mid shelf-sweep).
9. A recipe showing its per-serving nutrition numbers.
10. The food log with a real day's entries — staged with believable food, not
    lorem-ipsum meals.

## 7 · Page lifecycle

1. Now → 20 Sep: page live, email capture, September community posts point at it.
2. Early Nov: add the Google Play pre-registration button beside the email form
   (pre-reg auto-notifies on launch day; the list gets pointed at it too).
3. 11 Dec: CTA swaps to the Play badge; the confirmed price goes live on page,
   listing, and app on the same day.

## 8 · Open decisions for Arnar

1. ~~Price~~ — **decided: $25** (Arnar, 2026-08-19).
2. **Cap number** — 600/year is the working strawman and usage is unmeasured;
   it can be raised later, never lowered, so confirm you're happy committing to it
   in public writing.
3. **Hero headline** — A, B, or C from the blueprint.
4. **Founder note** — comfortable with name + optional photo? (Location stays off
   the page.)
5. **Domain** — confirm myrecibook.com is registered and in your hands.

## Key sources

Competitors: crouton.app · apps.apple.com (Crouton id1461650987, Mela id1548466041) ·
mela.recipes · pestlechef.app/pro · techcrunch.com/2024/11/25 (Pestle TikTok import) ·
recime.app/help (screenshot import; $39.99/yr, updated Aug 2026) · play.google.com
(ReciMe com.recime.app, Paprika v3, Recipe Keeper, Flavorish, Honeydew, Umami) ·
samsungfood.com/add-from-photo-howto + /food-plus · cookbookmanager.com/pricing ·
paprikaapp.com · recipenotes.app/free-crouton-alternative (Android-gap SEO evidence) ·
myrecipebox.app / cookmate.blog (own-cloud file sync, no AI)
Pricing/sentiment: revenuecat.com/state-of-subscription-apps · appsumo.com/blog/
lifetime-deals-in-ai-era · stacksocial.com (1min.AI $24.97 stated-credit lifetime) ·
news.ycombinator.com items 32319352, 48531184, 47060460 (pay-once/ownership quotes) ·
anovaculinary.com blog (subscription backlash) · stephango.com/file-over-app ·
ungatedapps.com (Crouton/Pestle IAP lists + review quotes, fetched 2026-08-19) ·
techrt.com/subscription-fatigue-statistics (directional only)
Landing pages: pestlechef.app, recime.app, crouton.app, mela.recipes, paprikaapp.com,
recipekeeperonline.com (all fetched live 2026-08-19) · getlaunchlist.com waitlist
guides · craftuplearn.com waitlist anatomy · waitlister.me/growth-hub (11% median,
~148 avg list) · mailerlite.com/features/embedded-forms · docs.buttondown.com ·
dlapiperdataprotection.com (EU/EEA e-marketing consent rules) ·
support.google.com/googleplay/android-developer/answer/14151465 (12 testers) ·
testerscommunity.com/blog/recruit-google-play-testers
Unverified/flagged: Reddit threads (blocked from tooling) · ReciMe free-tier limit ·
Recipe Keeper exact Android price · Mela macOS price · waitlist conversion numbers
above ~11% (vendor-inflated).
