# Export recon — can their users get out?

*Opened 2026-09-01. Arnar's manual investigation, feeding Q2 (migration in) and
Decision 2. Sources of prior knowledge: the fourteen dossiers in
docs/competitor-research/ and docs/library-import-research.md.*

**The question, per app:** can a user get their recipes OUT, in what format,
and does it cost money to find out? We investigate cheapest-first: reading docs
costs nothing, free installs cost time, purchases come last and only where the
first two passes proved a real door exists.

**Why we care:** users with 500–1,500 recipes are trapped by file formats, not
loyalty. Every open door is an importer we can build; every locked door is a
sentence in our marketing ("files in, files out, nothing held hostage").

---

## The workflow — three passes

**Pass 1 — desk research (free, no installs).** For each app: search its help
centre for *export / backup / download my data*, then dig the wider web — GitHub
tools that read the format, reverse-engineering write-ups, sample export files
in test fixtures. Claude can run this pass with web agents; Arnar only reviews
the findings. GDPR is a crowbar here: every one of these apps must answer a
data-access request from an EEA user, so the help docs often reveal more than
the app UI does.

**Pass 2 — hands-on (free installs, S21).** Only for apps whose Pass 1 said a
door might exist AND that have a usable free tier. Enter the two standard test
recipes (below), attempt the export, save whatever comes out.

**Pass 3 — purchases (last resort).** Only where Passes 1–2 proved the door is
real and we need an actual file to build against — and only after checking
whether a sample file already exists somewhere for free.

---

## The two standard test recipes

Enter the SAME two recipes in every app so the exports are comparable.

**Recipe A — "Vöfflur"** (the friendly case): 5 ingredients including one group
heading line ("Þurrefni:" / "Dry:"), æ ð ö å characters in title and
ingredients, one photo, two tags/categories, prep 10 min + cook 20 min,
4 servings, one note ("Amma's recipe").

**Recipe B — "Stress test stew"** (the hostile case): 12+ ingredients with
fractions (½, ¾) and comma decimals ("1,5 dl"), numbered multi-paragraph
directions, multiple photos if the app allows, a very long title, an emoji in
the notes.

What survives the round-trip tells us what the importer can promise.

---

## The evidence card — fill one per app

```
App / version / date checked:
Export path (exact menu clicks):
Format(s) produced:
Bulk (whole library) or per-recipe only?
Behind a paywall? Which tier?
Contents: photos? tags? times? servings? notes? nutrition?
Where the file lands (Downloads / share sheet / email):
Sample saved to: docs/competitor-research/export-samples/<app>/
Verdict: DOOR OPEN / DOOR LOCKED / NOTHING TO EXPORT
The sentence it earns us:
```

---

## The checklist — cheapest first

### Tier 0 · Desk-only, likely "nothing to export" (≈10 min each, no install)

These three have no personal cookbook per the dossier matrix — there should be
nothing to export. Confirm via docs so the verdict is evidence, not assumption.

- [ ] **Tasty** — no own recipes (favourites only). Docs check: can favourites
      be exported at all? Expected verdict: NOTHING TO EXPORT.
- [ ] **Mob** — no own recipes. Same check. Expected: NOTHING TO EXPORT.
- [ ] **Foodvisor** — no cookbook, but it's a diary: does it export the *food
      log* (CSV via GDPR request?)? A diary import could matter to us one day.
      Expected: no recipe export; note whatever the diary answer is.

### Tier 1 · Free installs, real doors suspected

- [ ] **COOKmate** — *highest yield, start here.* Dossier says export is best
      in class with a published backup schema. Free version on Play.
      - [ ] Pass 1: find the published schema + any GitHub readers.
      - [ ] Pass 2: install, enter both test recipes, export every format it
            offers, save all files.
      - [ ] Note whether export sits behind the paid tier.
- [ ] **ReciMe** — door is locked (PDF / share-link only, per research), but
      two things still need live verification on the free tier:
      - [ ] Create one test recipe, produce a **share URL**, paste it to
            Claude/Code — we inspect it for schema.org JSON-LD. If present,
            our existing link importer may already read ReciMe recipes today,
            zero new code.
      - [ ] Export one recipe as PDF and save it — worth knowing exactly what
            their "export" gives people.
- [ ] **Cookpad** — own recipes exist (metered). Export: unknown, the one
      genuine blank on the matrix.
      - [ ] Pass 1: help centre + GDPR data-request page.
      - [ ] Pass 2 only if Pass 1 hints at a door.
- [ ] **SideChef** — manual recipes exist; matrix says no export. Confirm via
      docs; install only if docs surprise us. Expected: DOOR LOCKED.

### Tier 2 · Paid, only if justified

- [ ] **Paprika** — format already reverse-engineered (zip of gzipped JSON,
      docs/library-import-research.md §2). The ONLY reason to spend money is
      generating a real export file to settle the categories-names-vs-uids
      question. Before buying:
      - [ ] Pass 1: hunt GitHub exporter tools for a committed sample
            `.paprikarecipes` fixture file — a free real file ends the
            question without a purchase.
      - [ ] If none found: buy Paprika 3 on Android (a few dollars, one-time —
            check current price), enter both test recipes + 2 categories,
            export, dissect.

### Tier 3 · Desk-only forever (iOS-only, no iPhone in the house)

context.md names these as the pay-once rivals; none run on Android, so switchers
*to Android* lose them entirely — they are forced exporters, which makes their
formats interesting.

- [ ] **Crouton** — docs + community: export format? (⚠ believed to have one.)
- [ ] **Mela** — same. (⚠ believed Paprika-compatible import; export format?)
- [ ] **Pestle** — same.
- [ ] If any format looks real and sample files exist publicly, grab them; an
      importer for iPhone-to-Android switchers needs no iPhone to build.

---

## Companion spike — the social caption test (15 min, free)

Same recon spirit, different question: does the recipe text of a public social
post survive a plain page fetch? Collect and paste to Claude/Code:

- [ ] 3 TikTok recipe links (public, caption contains the recipe)
- [ ] 3 YouTube links (recipe in description)
- [ ] 3 Instagram Reel links (we expect the login wall — proving it is the point)

Outcome decides whether the share-link door learns captions, or whether
screenshots remain the whole social answer.

---

## Where results land

Sample files → `docs/competitor-research/export-samples/<app>/`.
Evidence cards → appended to this file, one section per app, dated.
When the checklist is done, the findings + the library-import research become
**Decision 2** in plan.md: which importers we build, in what order, and the
exact sentences the listing may print.
