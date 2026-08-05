# /new-track — open a track
*Emitted by Orpheus conductor-init v3.1.*

1. Create conductor/tracks/<id>-<slug>/plan.md. Header carries the facts
   (no metadata.json): goal · gate it serves · deadline · hour budget · status ·
   decisions as D-numbers (D1, D2 …).
2. Body: numbered steps with a time estimate each, smallest runnable spike first.
3. Add ONE line to the conductor/tracks.md registry.
4. Reference, don't retell — bet, constraints, gates live in conductor/context.md.

A track that can't name the gate or milestone it serves is scope creep — challenge it
(behavioral rule 7) before creating anything.
