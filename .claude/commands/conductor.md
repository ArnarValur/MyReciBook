# /conductor — boot MyReciBook
*Emitted by Orpheus conductor-init v3.1. This repo boots without any plugin.*

Boot ceremony — read ONLY the hot set, in this order (budget 300–400 lines total):
1. conductor/pulse.md
2. conductor/relay.md — last entry only
3. conductor/tracks.md
4. conductor/workflow.md
5. conductor/agent-rules/behavioral.md
6. conductor/context.md

Then enumerate live — never trust static copies: `git status` + `git log --oneline -5`.

Warm files load later, via the trigger table in conductor/index.md — never at boot.

Report in ~10 lines: phase · active tracks · blockers on MY side only · the queue as
written (empty means empty — never fill it) · anything in git not reflected in pulse.
No gates, no countdowns, no calendar framing, and nothing Arnar owns.

Halt ONLY if conductor/ or conductor/pulse.md is missing. Recovery: restore from git
history (`git log --diff-filter=D --oneline -- conductor/pulse.md`, then checkout the
file from the last commit that had it). Never regenerate state from imagination.
