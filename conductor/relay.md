# Relay — MyReciBook
*One entry per session, 6 lines max, newest first.*

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
