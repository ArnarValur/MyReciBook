# Index — MyReciBook (static map)
*Static. Update only when a file is added or retired — never reconciled at boot.*

## Hot (every boot, this order)
1. conductor/pulse.md — live state
2. conductor/relay.md — last entry only
3. conductor/tracks.md — registry one-liners
4. conductor/workflow.md — laws + ceremony
5. conductor/agent-rules/behavioral.md — how to work with Arnar
6. conductor/context.md — bet, constraints, gates, schedule

## Warm (trigger table)
| Trigger | Load |
|---|---|
| Working a track | conductor/tracks/<id>/plan.md |
| Strategy / market / pricing question | recipe-app-feasibility-report.md (cite §) |
| A past decision is questioned | conductor/adr/ (created on first ADR) |
| Recurring technical how-to | conductor/agent-rules/technical.md (created on first lesson) |

## Cold (on request)
- conductor/pulse-archive/ — trimmed relay + old pulses (created on first trim)
- conductor/docs/ — long-form records (created on first need)

## Root
- STATE.md — thin pointer into this conductor (project-instruction compatibility)
- CLAUDE.md — boot pointer for coding agents
- recipe-app-feasibility-report.md — the strategy (warm)
