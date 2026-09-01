# Library import — Paprika, ReciMe, and the rest

Research, 2026-08-30. Question asked: *"One-Tap Paprika/ReciMe Library Importer —
an easy bulk-import utility for users switching from Paprika or ReciMe, a
friction-free way to escape ongoing subscriptions or legacy platforms."*

Nothing here is built. This is the inspection that decides whether to open a
track, and what the track would actually contain. Lines marked ⚠ are unverified
and must be settled against a real export file before any code is written.

---

## 0 · The answer, five lines

- **Paprika: buildable, small, deterministic.** A `.paprikarecipes` file is a zip
  of gzipped JSON. No AI, no proxy, no cap spend. Most of the machinery already
  exists in the app; the new parts are a zip reader, a file picker and a mapper.
- **ReciMe: not buildable.** ReciMe ships no structured export in any format. An
  "import from ReciMe" button would be a lie. Three honest alternatives in §3.
- **The premise conflates two users.** Paprika charges nothing ongoing — its
  owners are not escaping a subscription. ReciMe's are, and they are the ones
  who cannot get their data out. Say this out loud before building.
- **The importer's real value is the sentence it lets us print**, not the
  switchers it converts: files in, files out, nothing held hostage.
- **One unknown can break the whole feature** (⚠ how `categories` are encoded).
  It costs one export file to settle. Settle it first.

---

## 1 · Premise check — who is actually switching, and from what

| | Paprika 3 | ReciMe |
|---|---|---|
| Price | $4.99 once per platform ($29.99 desktop); cloud sync free with purchase | $39.99/yr US (up to $59.99 regionally); free tier ~5 imports/week |
| Android | Yes, full app | Yes |
| Data export | **Yes** — bulk, structured, self-service | **No** — PDF or share-link, per recipe |
| Why someone leaves | No AI/OCR import; pay again per platform; major-version repurchase | Price; billing complaints; import accuracy; reported library loss |

Two consequences:

1. **"Escape the subscription" is the ReciMe story, and ReciMe is the one we
   cannot import from.** The app whose users are angriest has locked the door;
   the app whose door is open has users with the least reason to walk out. The
   irony is the whole shape of this feature — plan around it, don't discover it
   in month two.
2. **The Paprika pitch is not "stop paying".** It is: bring the book you already
   typed, keep it in files you own, and get AI import, a grocery list that
   merges, and the diary on top. The importer removes a switching cost. It does
   not create desire.

---

## 2 · The Paprika format — what is verified

**Container.** `.paprikarecipes` is a plain zip. Each entry is a
`.paprikarecipe`: **gzip-compressed JSON, one object per recipe**. No database,
no encryption, no obfuscation — proprietary only in that Paprika publishes no
spec. Everything below is third-party reverse engineering and can change without
notice.

**How the user produces one.** Paprika → menu → Settings → *Export Recipes* →
select **Paprika Recipe Format** → Export. On **Android the file lands in
Downloads**; on iOS it saves to Files/iCloud Drive. This matters: an Android
Paprika user can make the file and hand it to us **without leaving the phone**.
That is what makes "one tap" honest rather than marketing.

**Fields** (from the sync-API documentation and the exporter tooling built on
it):

```
uid, name, ingredients, directions, notes, servings, rating, difficulty,
prep_time, cook_time, total_time, source, source_url, created, categories[],
hash, image_url, photo, photo_hash, photo_large, photo_url, photo_data,
nutritional_info, on_favorites, in_trash, is_pinned, scale, deleted
```

Three facts that drive the whole mapper:

- **`ingredients` and `directions` are each ONE newline-separated string**, not
  arrays. Splitting them is the import.
- **Times are free text** ("20 min", "1 hr 30 min"), not ISO-8601. Unlike the
  JSON-LD path, they need parsing.
- **`photo_data` is a base64 JPEG** when the user shot the photo themselves;
  `image_url` when it came from the web.

**⚠ Unverified, in order of how badly each can hurt:**

1. **`categories` — names or uids?** The sync API keeps categories in a separate
   collection keyed by uid, and a recipe references them. If the export carries
   uids and no category table, every imported tag is a hex string and the tags
   feature is worse off than before we started. **This is the one that decides
   whether the feature works.**
2. **Multiple photos.** Paprika 3 holds several photos per recipe. Whether the
   export carries them (a `photos` array of `{name, data}`) is unknown.
3. **`photo_data` vs `photo`/`photo_large`.** Exporter tooling reads
   `photo_data`; the sync-API field list shows `photo`, `photo_hash`,
   `photo_large`. The export may use a different subset than the API.
4. **`on_favorites` / `in_trash` / `deleted` in the export.** If present:
   favourites map for free, and deleted rows must be skipped or we import a
   user's trash.

All four are answered by one real export file, opened with `unzip` + `gunzip`.

---

## 3 · ReciMe — the door is locked

**Official export is PDF or a share URL, one recipe at a time.** No JSON, no
CSV, no bulk file. ReciMe's own help page is the source. This is deliberate,
not an oversight: it is the retention model (feasibility report §2.3).

What the rest of the market does about it, all three worth knowing:

- **Competitors tell users to email support and ask.** CookBook's own migration
  page does exactly this. Shape of the returned file: unknown, probably ad hoc.
- **A third-party Chrome extension** bulk-exports to a *printable document*
  organised by cookbook — prose, not data.
- **Nobody has a real ReciMe importer.** If we shipped one, we would be first —
  and we cannot, for the same reason nobody else has.

**What we could honestly build, ranked:**

1. **The share-link door — possibly already built, at zero cost.** If a ReciMe
   share URL serves schema.org JSON-LD, `data/link_extractor.dart` already
   imports it verbatim at confidence 1.0, with no AI call and no cap spend.
   ⚠ Unverified: needs one live share URL inspected for a `application/ld+json`
   Recipe block. If it holds, "paste your ReciMe links" is a feature we own
   today and a page on the site. Per-recipe, not bulk — but real.
2. **Screenshots.** Our core competence, and the honest answer for an app that
   won't let its users leave. Costs the user AI rescues. Frame it truthfully:
   *"ReciMe won't give you a file. Here's what we can do about that."*
3. **Parse whatever support sends back.** Unknowable shape, one user at a time.
   Not a product; possibly a kindness for a loud early tester.

**Do not build: credential scraping.** Asking a user for another app's password
to pull their cloud library breaks that app's ToS, gets IP-blocked (Paprika's
API rate-limits aggressively and bans), and directly contradicts the no-account
bet. Not a close call.

---

## 4 · What the codebase already gives us

The importer is mostly seams that exist. This is the reason it is cheap.

**Already there:**

- **`data/link_extractor.dart` is the precedent.** Structured source → content
  map → `confidence: 1.0`, `needs_review: []`, model `'jsonld'`, no AI call, no
  cap. A Paprika reader is the same shape with a different front end. Copy the
  posture, including "site-published data, quoted verbatim — nothing was
  guessed."
- **`ui/batch_model.dart` is the queue.** Sequential worker, per-item state,
  auto-save above the confidence bar, review only for the doubtful, "batch of 20
  ≠ 20 review screens." A 300-recipe file is precisely the case it was designed
  for.
- **`LibraryModel.saveImported` is the one save seam** (`main.dart:385`);
  grocery and storage sync ride its `onChanged`. The importer never touches
  those layers.
- **`domain/validate.dart` already refuses junk.** Empty title or under two
  ingredients is save-blocking, so a hollow Paprika row gets held for review
  rather than silently written. Correct default, no new code.
- **Tags are safe by construction.** Membership lives in the recipe file;
  `tags.json` is decoration only and a missing decoration never loses a tag
  (`domain/recipe_tag.dart`). Paprika categories can land as plain strings with
  no risk to the tag shelf.
- **`Recipe.assemble`** already stamps the envelope from a content-only map —
  the currency both existing importers speak.

**Missing, precisely:**

- **No zip reader.** `dart:io` gives `GZipCodec` for free (the inner layer);
  the outer zip needs the `archive` package — a new dependency.
- **No single-document picker.** `SafBridge.kt` implements
  `ACTION_OPEN_DOCUMENT_TREE` only. A `pickDocument` method
  (`ACTION_OPEN_DOCUMENT`, `*/*`) is ~30 lines beside the existing one.
- **Free-text duration parsing exists in the wrong place** — a private static,
  `ui/manual_entry_screen.dart:372`, reading "25 min" / "1 hr 30 min" /
  "1,5 hr". Lift it into `domain/` before a second caller needs it.
- **`source.type` enum is `["screenshot", "link"]`** in
  `app/assets/recipe.schema.json`. A file import needs a third value or the
  provenance line lies.
- **Nothing carries a foreign id**, so a second import cannot recognise what the
  first one wrote. See risk 3.

---

## 5 · Field mapping — Paprika → recipe file v1

| Paprika | → | recipe v1 | Notes |
|---|---|---|---|
| `name` | → | `title` | direct |
| `ingredients` (one string) | → | `ingredients[].raw` | split on newlines; blank lines dropped |
| — group headings | → | `ingredients[].group` | ⚠ heuristic: Paprika users write a line ending in `:`. Convention, not format. Get it wrong and a heading becomes an ingredient — visible, not destructive, since `raw` is kept |
| `directions` (one string) | → | `steps[].raw` | split on newlines; strip leading "1." / "Step 1:" |
| `servings` | → | `servings.raw` + parsed `amount` | same shape as `_servings()` in link_extractor |
| `prep_time` / `cook_time` / `total_time` | → | `times.prep_min` / `cook_min` / `total_min` + `raw` | needs the lifted duration parser |
| `notes` | → | `notes` | clean map — our `notes` is the user's own field and extraction never writes it |
| `source` / `source_url` | → | `source.app_hint` / `source.url` | `url` already exists for link imports |
| `categories[]` | → | `tags[]` | ⚠ blocked on the names-vs-uids question |
| `photo_data` (base64) | → | `cover` (`images/<id>-cover.jpg`) | decode per entry, never all at once |
| `image_url` | → | cover fetch | `data/cover_fetcher.dart` already does this for links |
| `on_favorites` | → | `favorite` | ⚠ only if present in the export |
| `uid` | → | *(no home)* | needed for re-import dedupe — see risk 3 |
| `rating` | → | *(no home)* | options: drop · map ≥4 to `favorite` · new field |
| `difficulty` | → | *(no home)* | could become a tag; probably drop |
| `nutritional_info` (free text) | → | *(no home)* | our nutrition is computed from pantry links, not text. Appending to `notes` is the only lossless option, and it makes every imported note ugly. Recommend: drop, and say so |
| `created` | → | *(no home)* | `source.imported_at` means when it entered *our* book. Losing the original date is a real, small loss |
| `in_trash` / `deleted` | → | skip the row | ⚠ if present |
| `scale`, `hash`, `photo_hash`, `is_pinned` | → | discard | Paprika bookkeeping |

Four fields have nowhere to go. The v1 file's own patterns say how to add one
safely — `favorite` and `cover` are both "absent in JSON unless set, so
untouched files round-trip byte-identical." A `source.foreign_id` for `uid`
would follow that rule exactly, and it is the only addition that buys something
structural (dedupe) rather than cosmetic.

---

## 6 · The risks that actually bite

1. **SAF write throughput — the one that makes it feel broken.**
   `LibraryModel.saveImported` calls `rescan()` after **every** save, and
   `SafFolderStore.listAll()` re-reads every JSON file in the folder. Importing
   300 recipes that way is 300 full-folder rescans — quadratic in bytes read, on
   a phone, over SAF. Each save is also 2 platform round-trips for the JSON plus
   2 per image. A bulk path must write N and rescan **once**.
2. **Memory.** Base64 photos live inside the JSON. A 500-recipe library with
   photos is easily hundreds of MB. Never `readAsBytes` the zip: stream it
   (`InputFileStream` + `ZipDecoder().decodeStream`), gunzip one entry at a
   time, decode one photo at a time, and cap absurd ones rather than dying.
3. **Duplicates on a second import.** With no foreign id, importing the same
   file twice doubles the library. Either write `source.foreign_id` from `uid`,
   or match on title + first ingredient — a heuristic that will be wrong
   sometimes, in both directions.
4. **Tag explosion.** A Paprika user with 40 categories gets 40 default-coloured
   tags in a shelf designed to be hand-curated (tags track, 2026-08-28). Make it
   a switch, default on, and state the count *before* it happens: "brings 40
   categories in as tags."
5. **Partial failure.** A 300-recipe import that dies at 180 must not leave a
   half-book with no way to resume. The batch queue is session-only by design
   (D5). Here the folder itself is the progress record — already-written ids —
   but only if a foreign id exists (risk 3 again).
6. **The copy is wrong before it is written.** "Rescue", the spinner, the
   confidence flags, "N lines need your eyes" — none of it applies. A Paprika
   import extracts nothing and has nothing to confess; nearly every item sails
   straight to saved. Reusing the batch screen unchanged makes the app claim
   work it did not do. It needs its own voice on the same machinery.
7. **Cap honesty, in our favour.** Zero AI calls means the counter must not
   move, and the screen should say so: *"Importing a file never touches your
   rescues."* That line is worth more than the feature.

---

## 7 · What it is worth — and what it isn't

**For:**
- Costs nothing per user, forever. Every AI-import competitor pays per recipe.
- One Play-listing bullet and one landing-page section no subscription
  competitor will copy, because the point of their format is that it has no
  exit.
- Small: a parser, a picker, a queue that exists, a save seam that exists.
- It exercises the file format publicly, which is the bet's whole argument.

**Against, honestly:**
- Paprika owners paid $4.99 once and are not in pain. This converts people
  already considering the move; it does not create them.
- The angry, motivated cohort is ReciMe's, and we cannot serve them with a file.
- Nothing here helps before the app is on Play. It is a *switcher* feature and
  there is nothing yet to switch to.

**The stronger version of the same asset:** MyReciBook **exports** a
`.paprikarecipes` bundle so anyone can leave *us* just as easily. Same zip/gzip
code, opposite direction. Post-Yummly, "your recipes outlive any company" is the
line the market responds to (feasibility §1) — and it is only credible from an
app that hands you the door on the way out. The export track shipped PDF and
Docs for humans; this would be the machine-readable half, and it is the thing a
reviewer can actually test.

---

## 8 · Smallest thing that could ship

1. **Verify the ⚠ list against one real export file.** Nothing before this.
2. `domain/paprika_import.dart` — pure Dart: bytes → `List<Map>` content maps.
   Testable with no Flutter, no device, like `recipeContentFromHtml`.
3. Lift the duration parser out of `manual_entry_screen.dart` into `domain/`.
4. `pickDocument` on `SafBridge` + a Dart wrapper.
5. A bulk save path that writes N and rescans once (or `saveImported(…,
   rescan: false)` plus one rescan at the end).
6. One door in the import sheet, third row, in the sheet's own language:
   **"Bring a library — from Paprika · no AI, no cap"**, with the count
   confirmed before anything is written.

Not in the first cut: ReciMe, Mela, Crouton, Cookmate, undo, merge-on-conflict.

---

## 9 · Open questions for Arnar

1. Ship the **export** side (`.paprikarecipes` out) with the import side, or
   before it? It is the same code and the better story.
2. Is a switcher feature worth building **before** the Play listing exists?
3. Categories → tags: on by default, or an explicit opt-in with the count shown?
4. `rating`, `difficulty`, `nutritional_info`, `created` — drop them, or is one
   worth a schema addition? (Recommend: drop all four; add
   `source.foreign_id` for dedupe instead, which pays for itself.)
5. If ReciMe share links do carry JSON-LD, is "paste your ReciMe links" a page
   on the site today — a feature with zero code behind it?
6. Which other formats, if any, ever? Mela (`.melarecipes` = zip of JSON) and
   Crouton (`.zip` of `.crumb` JSON) are near-identical work once the zip reader
   exists. Both are iOS-only apps whose users have no Android app to switch to —
   which, per context.md, is exactly the moat.

---

## 10 · Verify before code

| ⚠ | How | Cost |
|---|---|---|
| `categories`: names or uids | `unzip` an export, `gunzip` one entry, read it | minutes, needs one real file |
| Multi-photo array present | same file | same |
| `photo_data` vs `photo`/`photo_large` | same file | same |
| `on_favorites` / `in_trash` in export | same file | same |
| ReciMe share pages carry JSON-LD | fetch one share URL, grep `application/ld+json` | minutes |
| `archive` package streams zip on Android without OOM | one spike over a synthetic 300MB zip | an hour |

Sources for a real export file, cheapest first: Arnar buys Paprika Android
($4.99) and exports a handful of test recipes — this also produces the fixture
the tests need; or a tester with a real library sends one.

---

## Sources

Paprika format and export:
[Paprika export formats (official)](https://paprikaapp.zendesk.com/hc/en-us/articles/360051324613-What-export-formats-do-you-support) ·
[Paprika Android user guide](https://www.paprikaapp.com/help/android/) ·
[Paprika sync API + recipe field list (community)](https://gist.github.com/mattdsteele/7386ec363badfdeaad05a418b9a1f30a) ·
[paprika-exporter](https://github.com/bojanrajkovic/paprika-exporter) ·
[paprika-recipes (Python, bidirectional sync)](https://github.com/coddingtonbear/paprika-recipes) ·
[paprika-to-markdown](https://github.com/simonhbor/paprika-to-markdown) ·
[.paprikarecipes structure explainer](https://movemyrecipes.com/blog/breaking-free-from-paprika-what-paprikarecipes-files-actually-are) ·
[Tandoor import/export](https://docs.tandoor.dev/features/import_export/) ·
[AnyList: importing from Paprika](https://help.anylist.com/articles/paprika-import/) ·
[Paprika 3 on Google Play](https://play.google.com/store/apps/details?id=com.hindsightlabs.paprika.android.v3)

ReciMe:
[Can I print or export my recipes? (official)](https://recime.app/help/en/articles/11626121-can-i-print-or-export-my-recipes) ·
[CookBook: importing from ReciMe](https://help.cookbookmanager.com/en/article/how-do-i-import-recipes-from-recime-into-cookbook-ynl2fw/) ·
[ReciMe Recipe Exporter (Chrome extension)](https://chromewebstore.google.com/detail/recime-recipe-exporter/nbmmcjlploegpicloeoknlgdblcbmoga)

Other formats:
[Mela file format (official spec)](https://mela.recipes/fileformat/index.html) ·
[mela-recipes stream parser](https://github.com/jphastings/mela-recipes) ·
[Crouton .crumb schema](https://gist.github.com/LukeChannings/11ba3649bcb9b9086e3e271c7c3e950d)

Tooling:
[archive (Dart)](https://pub.dev/packages/archive) ·
[Flutter #62328 — streaming large zips](https://github.com/flutter/flutter/issues/62328)

In-repo: `docs/recipe-app-feasibility-report.md` §1–2 (competitors, export gap,
lock-in fear) · `docs/ai-cap-mechanics.md` §0 (free paths never count) ·
`conductor/context.md` (the bet, constraint 3) ·
`conductor/tracks/export/plan.md` (the other half of "files you own").
