# /checkpoint — close a MyReciBook session
*Emitted by Orpheus conductor-init v3.1.*

1. REWRITE conductor/pulse.md — state only, cap 60 lines, exactly these sections:
   📍 Now · 🚀 Active tracks · ⚠️ Blockers · 📋 Next queue · 📌 Parked.
   History never lives in pulse.
2. Append ONE entry to conductor/relay.md — ≤10 lines, plain language: what happened
   + what it means for Arnar · status · decisions · next.
   Guardrail: past 12 entries, trim to newest 8, archive the rest to
   conductor/pulse-archive/relay-pre-{date}.md.
4. Update the touched track plan + its one-liner in conductor/tracks.md.
   No metadata.json — facts live in the plan header.
5. ADR (conductor/adr/NNNN-title.md) only if proposed AND approved this session.