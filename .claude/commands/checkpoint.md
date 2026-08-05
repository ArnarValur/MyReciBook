# /checkpoint — close a MyReciBook session
*Emitted by Orpheus conductor-init v3.1.*

1. REWRITE conductor/pulse.md — state only, cap 60 lines, exactly these sections:
   📍 Now · 🚀 Active tracks · ⚠️ Blockers · 📋 Next queue · 📌 Parked.
   History never lives in pulse.
2. Append ONE entry to conductor/relay.md — ≤10 lines, plain language: what happened
   + what it means for Arnar · status · decisions · next.
   Guardrail: past 12 entries, trim to newest 8, archive the rest to
   conductor/pulse-archive/relay-pre-{date}.md.
3. Graduate lessons learned this session: technical → conductor/agent-rules/technical.md
   automatically; behavioral → conductor/agent-rules/behavioral.md only with Arnar's
   explicit yes given this session.
4. Update the touched track plan + its one-liner in conductor/tracks.md.
   No metadata.json — facts live in the plan header.
5. ADR (conductor/adr/NNNN-title.md) only if proposed AND approved this session.
6. Git: stage work + conductor changes, commit on main. Verify `git status` clean —
   sandbox commits can leave stale lock files (behavioral rule 12); if locks appear,
   hand the commit to Arnar.
7. Confirm in ≤6 lines: ✅ date · commit hash · what moved · rollback line · top of
   next queue.
