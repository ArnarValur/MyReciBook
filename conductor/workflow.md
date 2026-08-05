# Workflow — MyReciBook conductor (v3.1)

## The two laws
1. **One fact, one home.** Live truth → pulse. A session's story → ONE relay entry.
   Lessons → rules files (graduated at checkpoint). Decisions → ADR or track-plan
   D-numbers. Project truth → context.md. Never retell — point.
2. **An agreement binds only when it lands in a repo file.** Agent memory and chat are
   a cache. If we agree on something and it isn't written here, it doesn't exist.

## Memory temperature
- HOT — every boot, budget 300–400 lines total: pulse.md · relay.md last entry ·
  tracks.md one-liners · workflow.md · agent-rules/behavioral.md · context.md.
- WARM — loaded when work enters the domain, never at boot: track plans · adr/ ·
  agent-rules/technical.md · recipe-app-feasibility-report.md (cite §).
- COLD — on request only: pulse-archive/ · docs/.

## Checkpoint ceremony (detail: .claude/commands/checkpoint.md)
1. REWRITE pulse — state only, cap 60 lines.
2. Append ONE relay entry (≤10 lines). Guardrail: past 12 entries, trim to newest 8,
   archive the rest.
3. Graduate lessons: technical → rules file automatically; behavioral → only with
   Arnar's explicit yes.
4. Update touched track plan + its tracks.md one-liner. No metadata.json — facts live
   in the plan header.
5. ADR only if proposed AND approved in-session. ADR criteria: hard to reverse ·
   consequences across tracks · a future agent would plausibly redo it wrong.
6. Git: commit on main (solo repo, fold-to-main), ≤6-line confirm.

## Rules that keep this alive
- No static live-state in conductor docs (model prices, API versions, external URLs
  that rot) — enumerate live, always.
- Halt/recovery messages point at git history, never at commands this repo may not carry.
- Self-improvement loop: checkpoint's graduation step IS the loop. A failure that
  repeats without becoming a rule is a conductor bug — fix the conductor, not the memory.
