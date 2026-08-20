# Relay — MyReciBook
*One entry per session, 6 lines max, newest first.*

## 2026-08-20 — unified editor, five agents, budget burn
- Five parallel agents: unified New/Edit row editor, inline units (popup dead),
  product name on linked rows, servings/time/cover widgets, picker reorder,
  7-test diary-chain e2e. 0.7.0+4.
- Editor agent burned heavy tokens busy-wait polling; killed, tail hand-finished.
- Arnar decided: linked name replaces typed text at render only; skip final
  test run for budget. Full suite deferred to the release gate (2026-08-20).
  Nothing pending.

## 2026-08-19 — the meal diary, end to end, and the thread that doesn't hold yet
- MFP-style diary shipped to the S21 at 0.6.0+3: day files, servings, tags,
  snapshot entries, per-serving calculator, recipe logging, diary sync,
  pantry-born manual recipes. 637 green serially. Built with parallel agents.
- Arnar's catches drove three fixes mid-session: a duplicated product card
  (extracted to one ProductRow), a bulk refresh that would silently revert
  hand edits (user_edited flag + confirm), and free-text recipe entry that
  didn't match how recipes read (now row editor with self-structuring lines).
- Versioning is now step 4 of the checkpoint ceremony — Arnar asked for it.
- UNFINISHED: the recipe→pantry→diary thread holds only for recipes born in
  the new editor. Edit-recipe has no linking, recipes sit below the whole
  pantry in Add food, and no end-to-end test covers the chain. Diagnosed in
  pulse blockers; that is where the next session starts.

## 2026-08-19 — link import shipped end-to-end
- Share a URL → recipe: JSON-LD free path + Gemini text fallback (ABC case),
  cover toggle from the site's photo, source.url in the file. On the S21,
  both paths verified by Arnar. 527 green serially. Folded to main.
- Broke twice on the way: dart:io chokes on Fastly's chunked trailers (read
  as "offline") → NetBridge over the platform stack; AGP 9 rejected Cronet.
- Arnar decided: spoons never convert; covers are a user toggle. Nothing pending.

## 2026-08-18 — unit toggle shipped, keyless-build trap closed
- Units pill in settings (As written / Metric / US): render-time math on
  ingredients, steps and cook mode. On the S21. 495 green serially.
- Two builds today shipped without dev.env keys — every extraction failed with
  the generic error. app/deploy-s21.sh is now the only build path; a keyless
  build now says "This build is broken" in-app. Nothing pending.

## 2026-08-18 — stale state cleared, unit conversion designed
- Cleared the stale "nutrient work uncommitted" lines from pulse, relay and the
  nutrition plan — the work was already on main (21d9094).
- Brainstormed metric conversion on import: parse structured quantities at
  extraction, convert with local math at render, keep the original string.
  Landed in the nutrition plan as two open items.
- Nothing pending.

## 2026-08-18 — conductor rebuilt
- Arnar deleted conductor/ because the files had grown verbose and poisoned each
  next session. Rebuilt from scratch: 8 files, ~200 lines, one fact per line.
- Cut: the 158-line technical rules file, the old relay and 3 archives, the
  narrative track plans, the landing-page track. All still in git history.
- Arnar edited context himself: pitch is now "collect", not "rescue"; gates,
  schedule and budget sections removed; recipe files exportable in other formats.
- Answered his two questions in the mvp-build plan: what the proxy is, what the
  Play closed test is.
- Nutrient work committed on main (21d9094). Nothing pending.
