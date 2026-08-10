# Design handoff — input for the next mockup turn (turn 6)
*Written 2026-08-06, after the no-limits run. Paste this whole file into the
Claude Design session. Source of each flag: `grep -rn DEVIATION app/` — this
list is complete as of commit 475b67b.*

Context for Design: the whole alpha surface is BUILT and running on the S21
(309 tests). While building, Code hit surfaces the mockups don't cover. Each
was built minimal in the house skin and flagged in code. For every item below,
the ask is one of two answers: **ratify** (write the as-built version into the
next turn as designed truth) or **redraw** (draw the replacement; Code reskins).

## Headline ask: the settings screen (no mockup exists anywhere)
Turn 5 itself names it as next ("Try next: settings screen"). Built minimal
meanwhile, house skin, three blocks:
- Theme choice row: System / Light / Dark
- Storage row: truthful one-line summary → opens the storage screen
- About: standard licenses page + version footer reusing the drawer language
Deliberately absent — do NOT design them in: accounts (never), telemetry,
notification toggles, link-import door (post-alpha).

## Ratify-or-redraw list, by screen

### Batch queue — mockup 3b draws only the running state — 5 flags
1. Failed card: flagged-card pattern in the error color + "Retry"; caption
   keeps the calm register.
2. Skipped card: dimmed, "not a recipe — skipped, nothing saved".
3. Done-state header: "Recipes rescued" + honest count; reviewed-item caption
   "saved · you checked it" (the designed auto-save line said
   "saved · looked complete" — untrue for hand-reviewed items).
4. Running header gained an "N of M done" progress line (a wired queue needs
   overall progress; the static frame didn't).
5. Empty state (opened from the drawer, no batch yet): quiet caption.

### Storage screen — mockup 3h — 4 flags
6. "Change folder" + current folder name on the This-phone card (the drawer's
   Storage row routes here, so the re-pick flow needed a door).
7. "Restore from …" as the connected card's secondary action (5a reaches
   restore only via reconnect; a direct door was placed).
8. "awaiting keys in this build" caption — honest placeholder-credentials state.
9. Disconnect confirm copy — undesigned, drafted in code.

### Import sheet — mockup 3a — 2 flags
10. Third row added: the manual-entry door. Camera-row pattern, edit icon,
    copy "Type it in yourself / no AI, no cap — always unlimited" (4c/4d/5b
    make the promise; no mockup gave it a door).
11. Screenshots-tile caption redrafted: "one recipe or a whole pile — you
    decide next" (the old "pick every shot of one recipe" line became untrue
    once batch landed).

### Manual entry — whole screen, no mockup — 1 flag
12. Assembled from the review-screen patterns: title card, section-labeled
    cards one line per ingredient/step, pill inputs for servings/time,
    stadium CTA. Ratify the assembly or draw the screen.

### App drawer — 5c — 1 flag
13. Row 5 "Your copy": the designed "owned" trailing is dropped — an
    ownership claim the alpha cannot honestly make (untrue claims are HIGH).

### Import review — edit mode (decision D6) — 1 flag
14. Edit-mode copy: title "Edit recipe", CTA "Save changes" (the D6 amendment
    predates any mockup of editing).

### Settings tab — 4 flags = the headline ask above
15.–18. Whole screen + the three blocks (theme / storage / about).

Reply format: same as always — newest turn wins; export the full updated
mockups HTML.
