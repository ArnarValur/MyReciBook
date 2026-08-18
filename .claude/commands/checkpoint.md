# /checkpoint — close a MyReciBook session
*Emitted by Orpheus conductor-init v3.1.*

0. STYLE, all files below: one fact per line, no prose paragraphs, no story, no
   self-criticism, no apology. If a line does not change what gets built next, cut it.

1. REWRITE conductor/pulse.md — state only, cap 40 lines, exactly these sections:
   📍 Now · 🚀 Active tracks · ⚠️ Blockers · 📌 Parked.
   A section with nothing in it is DELETED, not written as "none" or "empty".
   No next queue. Never re-add one.
   History never lives in pulse.
2. Append ONE entry to conductor/relay.md — ≤6 lines: what shipped · what broke ·
   what Arnar decided · the unfinished step. No reflection, no post-mortem.
   Guardrail: past 12 entries, trim to newest 8, archive the rest to
   conductor/pulse-archive/relay-pre-{date}.md.
4. Update the touched track plan + its one-liner in conductor/tracks.md.
   No metadata.json — facts live in the plan header.
5. ADR (conductor/adr/NNNN-title.md) only if proposed AND approved this session.