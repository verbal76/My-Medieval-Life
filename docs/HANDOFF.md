# Restart handoff

> **Historical (superseded 2026-10-20, MEM-01).** The current handoff and next tasks are in `docs/CURRENT_DEVELOPMENT_STATE.md`; start every session from `docs/PROJECT_MEMORY.md`. The handoff below is kept as it was for the record and is not current.

For whoever resumes the work (an agent in a new session, or the owner). The queue is
`docs/DEVELOPMENT_QUEUE.md`; the rules are in CLAUDE.md. Update this file whenever work stops.

## State (2026-10-18)

| | |
|---|---|
| Staging head | See `git log origin/staging/my-medieval-life`. Work up to the manor's job board (`f836aca`) is pushed |
| Release | Build 7 (`6799071`) is the testing release; no Build 8 and no merge into `main` without the owner's approval |
| Unmerged work | The resource registry agent's worktree; pushed as `wip/agent-*` at each checkpoint (`git branch -r --list 'origin/wip/*'`) |

## In progress

1. **The Resources & Gathering journal page** (queue item 4): an agent, in its own worktree.
   - **Next:** integrate it into staging, run every suite and look at the page on a phone screen.
2. **The long runs** (queue item 6): seeds 1 and 2 at 10/30/100/365 days, from `f836aca` (worktree `/home/user/mml-sim`).
   - **Next:** write the results into `docs/release/LONG_RUN_SIMULATION.md` and log any new defects.
   - Currency grows about tenfold in a year from caravan coins; this needs analysis.

## Waiting on the owner

- The sustainability proposals P1–P3.
- B7-009, the starting treasury.
- A need-based maintenance model.
- Whether gold seams should exist (no deposit has gold; the recipes can't be made).
- Whether apples should have a source.
- Whether hunting belongs in Gather mode (it is implemented and can be removed).
- The balance review.
