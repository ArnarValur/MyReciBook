# Workflow — MyReciBook

## The two laws
1. **One fact, one home.** Live state → pulse. A session's story → one relay entry.
   Project truth → context. Task detail → the track plan. Never retell — point.
2. **An agreement binds only when it lands in a repo file.** Chat and agent memory
   are a cache. Not written here = does not exist.

## Writing rules — apply to every conductor file
- One fact per line. No prose paragraphs, no story, no reflection, no apology.
- If a line does not change what gets built next, cut it.
- No rule lists that only grow. Fix the file that caused the mistake instead.
- No static live-state that rots (prices, versions, URLs) — check it live.


## Memory temperature
- HOT, every boot: pulse · relay last entry · tracks · workflow · context.
- WARM, only when work enters that area: the track plan · adr/ · the feasibility report.
- COLD, on request: pulse-archive/ · docs/.

## Tests — Arnar's law, 2026-08-20, final
- DEFAULT: no test runs at all. `flutter analyze` (sub-second, no compile)
  is the verification after every change. Claude never fires flutter test
  on his own — not per feature, not per phase, not "just the touched files".
- Tests run ONLY when Arnar says "test it" — then: hard `timeout 120`,
  output visible (never piped to tail), one invocation. A run that hits
  the ceiling is broken — kill, fix, never wait.
- Full suite: ONLY before a release ships to Play, Arnar's call, detached
  to a log file.
- Why: flutter test cold-compiles the app per invocation, has NO default
  timeout, and a hung test sits silently forever — this burned whole
  sessions for weeks. Green lines are for Claude's comfort, not Arnar's
  time.

## Checkpoint
1. Rewrite pulse from scratch. State only, cap 40 lines. No next queue.
2. Append one relay entry, 6 lines max.
3. Update the touched track plan and its line in tracks.
4. Bump the version when the session finished something a user would notice —
   app/pubspec.yaml AND app/lib/version.dart together (version_sync_test pins
   the pair). Minor for a feature, patch for fixes; build number always +1.
   Say the new number in the relay entry. Arnar asked for this 2026-08-19.
5. Decision record only if proposed and approved in the same session.
6. Stage all, show Arnar the file list, wait for his go, then commit on main.
