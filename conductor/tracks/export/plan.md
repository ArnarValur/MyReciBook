# export

**Goal:** a recipe leaves the app as something anyone can read — a PDF first,
a Google Doc for users who already connected Drive.

**Serves:** context constraint 3, "one JSON file (exportable in other formats)".
The export half has never been built. Also kills the "who is Jason?" problem —
users stop needing to know what the file format is called.

**Division:** Arnar owns the page layout — it is a design question, and the
mockups in docs/ are the authority. Agent owns the plumbing.

**No new backend.** PDF is generated on the phone. Docs uses the Drive OAuth
that already exists (data/oauth.dart, drive.file scope) — no new scope, no
Google verification round.

## Decisions
- D1 — PDF ships before Docs. It works for every user, connected or not, and
  the system share sheet already offers "Save to Drive" for free.
- D3 — nutrition rides along only when there is something honest to say, and
  the "N of M ingredients" note travels with it. A printed page cannot be
  tapped for the caveat. Wording lives once, in domain/nutrient_display.dart.
- D2 — plain language leads, the format is a stated bonus. Default copy says
  "a plain text file"; "it's JSON" appears where a technical user looks for it
  (settings, storage, the site) — never as the first thing a newcomer reads.
  Arnar's splash site already frames it this way.

## Built and on the S21 (0.9.1+7, Arnar verified)
- [x] pdf 3.13.0 + printing 5.15.0 build clean under AGP 9.0.1 / Gradle 9.1.0
- [x] A4 page: cover, servings/time, ingredients with group headings,
      numbered method, notes, source line, footer
- [x] Share button on recipe detail → system share sheet
- [x] Per-serving nutrition box, coverage note included (D3)
- [x] Page strings come from the screen, so units toggle and pantry-linked
      product names carry through — data/recipe_pdf.dart parses nothing
- [x] Google Docs door (data/drive_docs.dart): HTML upload with the Docs
      conversion mimeType into MyReciBook/exports, opened via the AuthBridge
      launchUrl channel. No new scope, no new dependency
- [x] Share button opens a two-way sheet ONLY when Drive is connected;
      otherwise it goes straight to the PDF
- [x] JSON wording per D2: the preview filename lost its extension, storage
      says "a plain text file — JSON, if that means something to you"

## Steps
1. Arnar verifies the Docs door on the S21 with Drive connected — the only
   path no test can prove.
2. Open question for later, do not build blind: export a whole collection or
   the week's meal plan as one document. Ask Arnar first.

## Risks
- drive.file only sees files the app created. A Doc converted from our upload
  qualifies. If Google disagrees, Docs dies and PDF still stands.
