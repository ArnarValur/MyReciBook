# Hands-on triage — Arnar's S21 pass, 2026-08-06

Seven findings from the first creds-live build. Split: **bug** = code broke the
design or basic sense · **dead-end** = built surface with no engine behind it ·
**design** = needs a Claude Design turn before code can be right.

---

## 1. Status bar unreadable after leaving the cover-image viewer — BUG
`lib/ui/widgets/skin.dart:394` — `OriginalsViewer`'s AppBar is hardcoded black, so
Material derives a **light** status-bar icon style for it. Popping back does not
restore the previous route's style (nothing on the cookbook route declares one),
so white icons stay on the cream light theme → the clock and battery vanish.
Visible in your screenshot 1 ("12:35" barely legible).
Fix: declare `systemOverlayStyle` explicitly on the viewer AND wrap the app shell
in an `AnnotatedRegion<SystemUiOverlayStyle>` keyed to theme brightness, so every
pop lands on a route that asserts its own style. ~20 min incl. a widget test.

## 2. No way to change a recipe's cover image — DESIGN
Not built, and not drawn in any turn. The detail screen can toggle cover↔original
(`recipe_detail_screen.dart:342`) but never re-assign. You said you have ideas —
this belongs in the next design turn (crop? pick from the recipe's own
screenshots? camera? a plated photo you took?). Code after the frame exists.

## 3. Bottom navigation bar — NOT a deviation. Your design specifies it.
This one came out of the mockups, not out of a copied app:
- Turn 1 brief, your assumptions block: *"Frame: 360dp Android (Galaxy S21),
  Material 3, **bottom nav + FAB**"* and *"**glass bottom nav**, cream light theme
  + navy dark"*.
- Turn 5c, the navigation turn itself: *"The split: **bottom bar keeps the 4 daily
  surfaces**; the drawer holds the app's data and utility. Nothing lives only in
  the drawer except Help — no buried destinations."*
- The hi-fi screens import a `NavBar` component with `fab-icon="add"` on cookbook
  and grocery.

Why it *feels* copied: the component library your design project binds is the same
shared design system the other app uses — the nav component is literally imported
from it in the export. The shape is that library's; the decision to use it is in
your own turn-1 and turn-5 notes.

Removing it is therefore a **design change, not a bug fix** — and it cascades:
kill the bar and the FAB loses its home, Grocery/Plan/Settings lose their daily
surface, and 5c's "no buried destinations" rule inverts. Your call, but it should
be a turn-7 frame, not a code decision.

## 4. Meal plan opens a dead end — AGREED, hide it
`lib/ui/plan_tab.dart` is honest-empty by construction (its own header comment
says no meal-plan screen is designed in any turn and no engine exists). You're
right that an honest empty state is still a dead end for a tester.
Fix: drop Plan from the bar and the drawer until the engine lands. ~15 min.
Note the cascade for turn 7: the bar goes 4 surfaces → 3, which contradicts 5c's
split — record as a deviation for Design to ratify or redraw.
Also note it is **v1 scope, not cut**: context.md's week-two hook is a grocery
list that syncs with the meal plan.

## 5. Grocery list can't be cleared or edited row-by-row — BUG (gap)
What exists (`lib/ui/grocery_tab.dart`): overflow menu → *Copy list* / *Clear
checked*; long-press → move aisle. What's missing: delete ONE row, and clear the
whole list.
Fix: swipe-to-dismiss per row with undo snackbar + a *Clear all* entry in the same
overflow menu, behind the canonical 6f destructive confirm. ~45 min incl. tests.

## 6. "Change folder" — the extra screen is designed; the dark mode is a BUG
Two separate things:
- **The screen is correct.** Turn 6 ratified flags 6–7: *"the two doors Code
  needed — re-pick the local folder (the drawer's Storage row lands here)"*. It
  exists so "Keep current folder" can cancel safely; going straight to the system
  picker would leave no way back if you tap the wrong thing.
- **The dark theme is a bug.** `lib/ui/folder_gate.dart:210` builds its OWN
  `MaterialApp` with `theme:` + `darkTheme:` but **no `themeMode`** → it defaults
  to `ThemeMode.system`, so it follows the phone (dark) instead of your in-app
  choice (light). Fix: thread the saved theme mode into that MaterialApp. ~15 min.

## 7. Quick / Sweet filter chips do nothing — dead end, decide the scope
The chips ARE in your design (turn 1 wireframe and hi-fi 3d), but no turn ever
drew how a recipe *gets* a tag, so code shipped the chips with nothing behind them.
Options:
- **A — Favorites only (recommended for v1).** Delete Quick/Sweet, keep All +
  Favorites. Favorites already works end to end. ~15 min.
- **B — user-defined tags.** Tag chips in edit mode, tag store in the recipe JSON,
  chip row becomes dynamic, plus a manage-tags surface. ~1 full build night, and
  it needs a design turn first.
Recommendation: A. Build order is extract → save → list → open (context.md §6);
tagging is breadth, and Gate 2 (200 signups by 20 Sep) rewards none of it. B stays
parked as a post-launch idea.

---

## Version footer "MyReciBook 1.0.0"
Cosmetic — it's `pubspec.yaml`'s default, never a release. Arnar is settling
versioning with a separate cowork session; ignore until that lands.

## Suggested batch
Bugs and hides in one pass: **1 · 4 · 5 · 6 · 7A** ≈ 2 h with tests, one build to
the phone. **2** waits for a design frame. **3** waits for Arnar's verdict against
his own turn-5 note.
