# MyReciBook — product brief for the marketing & frontend agent

*Written 2026-08-19 from the shipping code, not from wishes. Audience: the agent
designing the splash / landing page. Everything below is either **SHIPPED** (running
on a real Galaxy S21 today), **BUILT-HIDDEN** (code exists, switched off, do not sell it),
or **PLANNED** (do not put it on the page as a feature — at most a "coming" line).*

**The honesty rule is not optional.** The app itself refuses to draw a button that
does nothing ("no dead-ends"), refuses to say "synced" when nothing synced, and states
its AI cap in writing on the paywall. A landing page that oversells breaks the single
thing the product is selling: trust. Match the register.

---

## 1 · What the app is, in one breath

**MyReciBook rescues the recipes buried in your camera roll.**

You screenshot recipes off Instagram, TikTok, blogs, WhatsApp from your mum — and they
rot in a folder of 4,000 photos you will never scroll. MyReciBook turns those screenshots
into real, structured, searchable recipes. It also takes a shared link, a photo of a
cookbook page, or plain typing.

Three promises that the whole product is built around:

1. **Screenshot-first.** Not a URL importer with screenshots bolted on. Screenshots are
   the primary door, because that's where people's recipes actually are.
2. **Your files, your storage.** One plain JSON file per recipe in a folder *you* pick on
   *your* phone. No account. Ever. Delete the app and your recipes are still there. Back
   them up to your own Google Drive or Dropbox if you want to.
3. **Pay once.** One-time purchase, no subscription. "Your recipe box shouldn't have a
   landlord."

**Android-first is the moat.** "No Android version" is the top complaint against the
polished iOS recipe apps (Crouton, Mela, Pestle). None of them can follow quickly.

### The pitch lines that already exist in the product
Use these — they are already drafted, tested, and consistent with the app's voice:

- "Collect the recipes buried in your camera roll."
- "Pay once. Cook forever."
- "No subscription. No account. Ever."
- "Because your recipe box shouldn't have a landlord. You buy MyReciBook like you'd buy
  a good knife: once."
- "one recipe or a whole pile — you decide next"
- "cookbook or grandma's card — handwriting welcome"
- "Typing recipes in yourself is always unlimited"
- "Staples stay quiet unless you tap them."

### Who it's for
People with screenshot chaos. Heavy overlap with ADHD/neurodivergent "I saved it, I'll
never find it" behaviour — that angle works in *copy*, but note the ADHD subreddits ban
promo, so it's a positioning angle, not a channel. Sources are English-language web and
social. Home cooks, not chefs.

---

## 2 · The feature inventory

### 2.1 Import — the front door · SHIPPED

There are **four ways** a recipe gets in. One import sheet ("Add to your book") offers them.

**a) Screenshots** — pick one or many from the gallery.
- One shot → straight into review.
- Two or more → the app asks the question that matters: **"One recipe · 5 shots"** vs
  **"5 separate recipes."** A long recipe spread over five screenshots is stitched into one;
  a pile of unrelated saves becomes five recipes in a queue.
- The queue is **non-blocking**. It works through the pile one at a time and only stops you
  for the ones it isn't confident about. Clean ones save themselves.
- On-device OCR (free, ML Kit) plus a cloud vision model that turns the text into structure.

**b) A shared link** — share any recipe URL from any app into MyReciBook.
- **Free path:** most recipe sites embed machine-readable recipe data (schema.org JSON-LD).
  The app reads it verbatim. **No AI call, nothing invented, confidence 1.0.**
- **Fallback:** a page without that data goes through the AI over the page text — costs the
  same as one screenshot.
- **Cover toggle:** the site's own hero photo is offered as the recipe cover, shrunk to
  1080px, default on, and the user decides. The link is remembered in the recipe file.

**c) Snap a page** — camera. Cookbook page, index card, "grandma's handwriting welcome."

**d) Type it in yourself** — no AI, no cap, always unlimited. This is a *deliberate*
pressure valve on the paywall: the AI is what costs money, so typing is free forever.

### 2.2 Review — the trust moment · SHIPPED

Nothing is ever saved silently behind your back.

- Extraction lands in a review screen: title, ingredients, steps, servings, times.
- **Low-confidence lines are flagged**, marked with a warning, and need a tap to confirm —
  they are never auto-saved.
- Anything can be edited before saving.
- A failure is stated plainly and calmly ("that didn't work, here's what to try"), never a
  spinner that lies or a stack trace.
- **The user's original text is never destroyed.** Every ingredient and step keeps its raw
  line. Parsing adds structure on top; it never overwrites what the recipe actually said.

### 2.3 The cookbook · SHIPPED

- Grid view with covers, or compact list view — the choice sticks across restarts.
- Search across the whole book.
- Favorites (a heart) — and the favorite flag lives **in your file**, so deleting the app
  and restoring doesn't lose them.
- Covers: pick your own photo of the dish you cooked, choose one of the source screenshots,
  or use the site's photo on a link import. No cover = the app draws a clean tile; it
  deliberately does **not** fall back to a raw screenshot (they made ugly covers).
- Every recipe keeps its provenance — tap to flip the cover and see the original screenshot
  you imported it from.

### 2.4 The recipe · SHIPPED

- Ingredients with tap-to-check-off while you cook.
- Steps.
- Servings and times as chips.
- Your own notes, editable any time after saving ("halve the sugar", "40 min not 25").
- Delete.
- **Unit display toggle** — As written / Metric / US, in settings. The maths runs locally at
  render time, never through the AI, and **the recipe file is never rewritten** — it changes
  what a screen *shows*, nothing it stores. Volume→volume and weight→weight, plus °F→°C and
  inches. Odd units (a stick of butter, a pinch, an egg) pass through untouched. Metric mode
  deliberately leaves tsp/tbsp alone — spoons are universal, converting them is noise.

### 2.5 Cook mode · SHIPPED

Hands-off, steamy-hands step-by-step: big text (≥24sp), whole-screen tap zones, screen stays
awake, and a timer that finds the duration inside the step text ("simmer for 20 minutes")
and offers it.

### 2.6 Grocery list — the week-two retention hook · SHIPPED

This is the feature that makes the app a habit rather than a shoebox, and it is genuinely
better than the competition. Sell it.

- **Add a whole recipe to the list in one tap.**
- **Duplicates merge, with quantities summed.** Two recipes wanting lemons give you one
  row: "6 lemons — from 2 recipes." Same unit sums; different units sit side by side
  ("2 tbsp + 1 pack") — quantity is never silently lost.
- **Merging is suggest-and-confirm, never silent.** "lemon" and "lemons" surface as
  a prompt: **Merge · 6 lemons** / **Keep apart**. If you keep them apart, they stay apart —
  forever.
- **It remembers your corrections.** Move an item to a different aisle once and it lands
  there every time after. Your correction always beats the built-in guess. Aisles you invent
  are tagged "your aisle".
- **Staples stay quiet.** Salt, pepper, oil, water land dimmed and quantity-less instead of
  nagging you to buy 2 cups of sugar. Tap to activate one if you actually need it.
- **The list is a view, not a snapshot.** Change the plan and the list updates, with a
  receipt banner saying exactly what changed ("… — 3 amounts updated").
- Manual items you add by hand survive every recipe operation.
- Check off, clear checked, copy the whole list out as text.
- Fractions come back readable: ½, ⅓, ¾ — not 0.333.

### 2.7 Pantry & nutrition · SHIPPED (live on the current build)

- **Scan a barcode** off the shelf with the camera. Torch toggle. A "shelf-sweep" mode keeps
  the scanner open with a ~3-second cooldown so you can walk the cupboard scanning.
- Open Food Facts fills in name, brand, pack size and **the full nutrient list per 100g** —
  not just seven fixed macros; vitamins and minerals come along when the database has them.
- One JSON file per product in your own pantry folder, beside your recipes.
- Add your own photo of the product.
- **Link an ingredient to a product** — long-press "250 ml milk" and point it at *your*
  actual milk. The link is remembered in the recipe file.
- The grocery list uses it: rows show an **"in your pantry"** hint, and two rows carrying the
  same linked product merge as a fact, no prompt needed.
- Honest failure: "Open Food Facts doesn't know this barcode" and "the lookup didn't answer"
  are two different messages, never confused.

### 2.8 Storage, backup and ownership · SHIPPED

This is the second-biggest selling point after the screenshots. Give it real space on the page.

- On first run you **pick a folder**. That folder is the app. One `<id>.json` per recipe at
  the root, an `images/` folder beside it, a `pantry/` folder for products.
- The files are plain, readable JSON. Open them in a text editor. Exportable to other formats.
- **Optional** backup to your own **Google Drive** or **Dropbox** — both working and proven on
  a real device. It is a **one-way mirror**: your folder is the truth, the cloud is backup and
  restore. Restore is additive — it never overwrites what's already there.
- If a file was edited on another device or in the Drive web UI, the app **skips it and tells
  you**, rather than overwriting your other copy.
- No iCloud (Android-first, and no Mac exists in the build chain).
- **No account, no login, no telemetry.** The settings screen deliberately has three blocks —
  Theme, Storage, About — and nothing else. There is no analytics toggle because there is
  no analytics.
- The storage screen never says "synced" unless something actually synced.

### 2.9 The look · SHIPPED

- Two full themes, both designed, both ship: light **"Stitch Slate"** on a warm cream
  scaffold, and dark **"Midnight"** — deep navy, never black. Follows the system by default.
- Glass nav bar with a gradient import button as the centre door.

---

## 3 · What is BUILT-HIDDEN or PLANNED — do not put these on the page as features

| Thing | Status | What the page may say |
|---|---|---|
| **Meal planning** | Built as an empty screen only. **No engine.** Switched off. | Nothing, or a "coming" line at most. **Never** a feature bullet. |
| **In-app purchase / billing** | The paywall pitch screen exists and looks final; Google Play billing is **not built**. The button is deliberately disabled and says why. | The price and the one-time promise are safe to state. Do not imply you can buy it today. |
| **Per-serving nutrition badge** | Planned. Pantry data exists, the per-serving calculator does not. | Not yet a feature. |
| **Serving rescale (2x / halve)** | Planned. Servings show as a static chip today. | Not yet. |
| **Recipe tags beyond Favorites** | Chips are drawn but nothing can assign a tag. Off. | Say "favorites", not "tags". |
| **Density table** (cup of flour → grams) | Planned. Volume stays volume for now. | Not yet. |
| **Manual product entry / product editing** | Planned. | Not yet. |
| **Label-photo fallback** for products not in Open Food Facts | Planned. | Not yet. |
| **Rate / share-with-a-friend rows** | Hidden until a live destination exists — i.e. until *this landing page* is live and the Play listing exists. | n/a — but note the landing page is the unblocker. |
| **Extraction proxy** | Built, deployed nowhere. It holds the AI key so it never ships in the app, and counts usage against the cap. | Not user-facing. |

### Known rough edges (for your honesty calibration, not for the page)
- Link-imported ingredients don't have parsed quantities yet, so the unit toggle and
  nutrition maths don't cover them.
- A deleted pantry product leaves a silent dead link on an ingredient.
- One barcode per gallery photo.
- Some "not measured" values from Open Food Facts print as 0.
- A link-import failure is honest but final — no one-tap "try it as a screenshot instead" yet.

---

## 4 · Pricing and the cap — state it exactly, it can never be walked back

- **One-time purchase.** Working number: **$25**. Not final — confirm with Arnar before
  it goes on a public page.
- **Hard paywall.** No subscription. No account.
- **A fair-use AI cap must be stated in writing from day one**, on the page and in the store
  listing. Current working number: **600 AI rescues a year** (≈100/month is the strawman;
  real usage has not been measured yet). It can be *raised* later; it can never be lowered.
  Never write "unlimited" about the AI — that promise cannot be clawed back.
- **Typing recipes in yourself is always unlimited** — that's the honest counterweight, and
  it should appear right next to the cap so the cap doesn't read as mean.
- The current in-app card lists: *Every recipe, forever, in your storage · 600 AI rescues a
  year — fair-use cap, in writing · A grocery list that actually merges · All future features
  included.*

---

## 5 · Brand kit

**Name:** MyReciBook · **Studio:** Merkurial-studio · **Package:** `com.merkurialstudio.myrecibook`

**Logo files:** `docs/MyReciBook-logo/assets/logo/` — `logo-mark.svg`, `logo-mark-white.svg`,
`app-icon.svg`, plus PNGs at 48/96/192/512 and an adaptive foreground at 432.

**Design authority:** the mockup HTML in `docs/` is the design answer — newest wins.
`docs/design/handoff.md` holds the full token list. Screens as PNG in `docs/design/`.

### Colour
Seeded on **#3F51B5** ("Moody Blue").

*Light — "Stitch Slate"*
- primary `#24389C` · primaryContainer `#3F51B5` · onPrimaryContainer `#CACFFF`
- secondary `#4D5A9C` · secondaryContainer `#ABB7FF`
- **tertiary `#88003B` / container `#B40050`** — reserved for **rare** moments only: the
  ONE-TIME badge and the favorite heart. On a landing page, that means the buy moment and
  nothing else.
- scaffold `#FAF8F0` (warm cream) · surface `#F9F9FC` · cards `#FFFFFF`
- onSurface `#1A1C1E` · onSurfaceVariant `#454652` · hairlines `#C5C5D4` at ~50%
- status: success `#22C55E` · warning `#F59E0B` · error `#BA1A1A`

*Dark — "Midnight"*
- primary `#BAC3FF` · onPrimary `#071A86` · primaryContainer `#293CA0`
- scaffold `#0F1117` · surfaces `#0A0C11` / `#161922` / `#1C1F2B` / `#262A36`
- onSurface `#E4E2E6` · outlineVariant `#454652`
- **Elevation in dark is surface tint, not shadow.** Never pure black.

### Type
- **Plus Jakarta Sans** — display, headlines, titles. Hero headlines 26–29sp w700, tracking
  −0.02em. Wordmark "MyReciBook" w800 in primary.
- **Inter** — body and labels. Body 13.5–14, captions 12–12.5 in onSurfaceVariant.
- Tiny section labels: 11sp, w600, uppercase, letter-spacing 0.9px. **ALL-CAPS is allowed
  here and nowhere else.**

### Shape, space, effects
- Radius: 8 buttons · 12 cards/inputs · 16 large cards · 22 icon squircles · 24 sheet tops ·
  **full stadium** for pills, chips, segmented controls, primary CTAs.
- 4px grid: 4/8/12/16/24/32. Screen padding 20.
- Card shadow (light): `0 4px 10px rgba(36,56,156,0.06)` — **blue-tinted and subtle**, never grey.
- Glass surfaces: translucent fill + 20–24px blur + 1px hairline.
- Icons: Material Symbols **Rounded** only. Never emoji as an icon.

### Voice
English. **Playful, warm, plain.** **Sentence case everywhere, including buttons.**
Short. Concrete. It talks about your camera roll and your grandmother's index card, not
about "AI-powered recipe management solutions." When something fails it stays calm and says
what to do next. It never brags about the technology — the technology is invisible, the
rescued recipe is the point.

---

## 6 · Where the app is going

- **Now:** finish nutrition — per-serving numbers and a nutrition badge on each recipe, fed by
  the user's own barcode scans. Then billing.
- **Then:** meal planning, which turns the grocery list into a weekly loop and the pantry into
  a food diary. This is the promised week-two hook and it is not built yet.
- **Explicitly declined, do not imply:** inventory tracking (named as a trap), automatic
  remembered ingredient→product links, full two-way cloud sync, any account system, any
  telemetry, iOS.
- Store path: a closed test on Google Play (12 testers, 14 unbroken days) has to run before
  production access is granted. Launch window targeted for **December 2026**.

---

## 7 · What the landing page has to do

It has one job: **collect email signups before launch** (target: 200), and be the destination
the app's own "share with a friend" row can finally point at.

Suggested spine, in the app's own order of persuasion:

1. **Hero** — the camera-roll line, one screenshot-to-recipe visual. This is the whole product
   in one image: a messy phone gallery on the left, a clean recipe on the right.
2. **The three promises** — screenshot-first · your files · pay once.
3. **The grocery list** — the thing that makes it a habit. The merge prompt is the money shot.
4. **Ownership** — a plain JSON file, in a folder you picked, on your phone, backed up to your
   own Drive. No account. This paragraph converts the sceptical.
5. **Pay once** — price, ONE-TIME badge in the tertiary colour, the cap in writing, "typing is
   always unlimited" right beside it.
6. **Email capture.** Android. December.

Two positioning variants worth A/B testing (already planned in the marketing doc):
**"own your files, pay once"** for the developer/tech crowd, **"rescue your camera roll"** and
**"grandma's recipe box"** for the cooking-community crowd.

**Do not** put a subscription tier, a web app, an iOS badge, meal planning, or a "sign up for
an account" anywhere on the page. All four contradict the product.
