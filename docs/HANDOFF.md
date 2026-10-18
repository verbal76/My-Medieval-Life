# Restart handoff

For whoever resumes the work (an agent in a new session, or the owner). The queue is
`docs/DEVELOPMENT_QUEUE.md`; the rules are in CLAUDE.md. Update this file whenever work stops.

## State (2026-10-18)

| | |
|---|---|
| Staging head | See `git log origin/staging/my-medieval-life`. Work up to the manor's job board (`f836aca`) is pushed |
| Release | Build 7 (`6799071`) is the testing release; no Build 8 and no merge into `main` without the owner's approval |
| Unmerged work | The resource registry agent's worktree; pushed as `wip/agent-*` at each checkpoint (`git branch -r --list 'origin/wip/*'`) |

## In progress

1. **The resource registry**: the agent is writing `game/data/resources.json`, the `ResourceNodes` API,
   `tools/check_resources.py` and `docs/systems/*.md`.
   - **Next:** integrate it into staging and run every suite.
   - **Then:** Gather mode (queue item 2), then the journal page (item 4), both built on `ResourceNodes`.
2. **The long runs** (queue item 6): seeds 1 and 2 at 10/30/100/365 days from `f836aca`.
   - Results go into `docs/release/LONG_RUN_SIMULATION.md`, with any new defects in the issue register.

## Waiting on the owner

- The HUD and Android layout report (queue item 1).
- The sustainability proposals P1–P3.
- B7-009 (the starting treasury).
- A need-based maintenance model.
- The balance review.
