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

## Tests — how we decide, together
- Nothing runs on Claude's initiative. Before any test run Claude says: which
  file, why now, what it would prove. Arnar decides. That is the whole rule.
- Between changes the default check is `flutter analyze` — sub-second, no compile.
- Agreed run: hard `timeout 120`, output visible, one invocation. Ceiling hit
  means broken — kill it, say so, never sit and wait.
- Full suite: only before a release ships, Arnar's call, detached to a log.
- Known-bad tests get named out loud, not silently dodged. Open right now:
  cookbook_view_test ×2 red since 2026-08-29 — stale "no covers in list view"
  asserts, lib is right; repair proposed in docs/test-comb-2026-08-29.md.
- Why the caution: flutter test cold-compiles per invocation and has no default
  timeout, so a hung test sits silent forever.

## Checkpoint
1. Rewrite pulse from scratch. State only, cap 40 lines. No next queue.
2. Append one relay entry, 6 lines max.
3. Update the touched track plan and its line in tracks.
4. Version by what changed, never by "a checkpoint happened" (Arnar, repeated;
   written down 2026-08-20 after minor was bumped three checkpoints running).
   - minor — a capability a user would name out loud (diary, categories)
   - patch — fixes or polish to something that already exists
   - no bump — refactors, tests, conductor edits, anything invisible to a user
   - +build — ONLY when an APK is actually built for the device. It counts
     installs, not sessions.
   - 1.0.0 — the first paid release on Play. Nothing gets there by calendar.
   app/pubspec.yaml AND app/lib/version.dart move together (version_sync_test
   pins the pair). Say the new number in the relay entry.
5. Decision record only if proposed and approved in the same session.
6. Stage all, commit on main, then show Arnar the file list. Do NOT ask for a
   go — his original yes covered the session (corrected 2026-08-21, twice in
   one night). Ask only if something in the diff contradicts what he asked for.
