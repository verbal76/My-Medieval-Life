# Development queue

The prioritized queue of approved work (owner directives of 2026-10-18). Development is always
active; only builds, releases and merges into `main` wait for the owner. When a task finishes, the
next ready task by priority starts. Bugs from the owner's testing go into
`docs/release/BUILD_7_ISSUES.md` and enter this queue by severity.

Statuses:
- **Ready**: can start.
- **In progress**: someone is working on it.
- **Blocked**: waiting on a named decision or dependency.
- **Awaiting integration**: implemented on a branch.
- **Integrated**: on staging and tested.
- **Device check**: integrated; needs the owner's hardware.
- **Next release**: done; waits for an authorized build.

Release gate: Build 7 is the testing release. No Build 8, no replacement release, no merge into
`main` without the owner's explicit authorization.

| # | Task | Status | Owner / branch | Depends on | Notes |
|---|---|---|---|---|---|
| 1 | Responsive HUD anchoring and Android layout corrections | Blocked: no report yet | — | The owner's screenshots or description | No HUD or layout report has reached this session or the issue register; it starts as soon as one does |
| 2 | Gather mode: a toggle, auto-approach, continuous gathering | Blocked: dependency | — | 3 (uses its `ResourceNodes` API) | Owner's flow: activate Gather, select a resource, approach and gather until depleted or interrupted, tap Gather to exit |
| 3 | Resource Node Manifest and Resource Usage Registry from one authoritative definition, with validation | In progress | agent worktree (to be pushed as `wip/`) | — | `game/data/resources.json` → generated `docs/systems/*.md`; validator in the unit tests |
| 4 | In-game Resources & Gathering journal page from the same definitions | Blocked: dependency | — | 3 | Includes the Gather mode instructions |
| 5 | Reeve employment: real jobs, NPCs by the same rules | Integrated | lead, staging | — | INT-066; save version 8 |
| 6 | Long-duration simulations (10/30/100/365 days) | In progress | lead (worktree pinned at `f836aca`) | 5 | Seeds 1 and 2; results go to `docs/release/LONG_RUN_SIMULATION.md` |
| 7 | Build 7 economy corrections (B7-001 to B7-005, B7-007 stone) | Device check | staging `ae0e01f` | — | See the issue register |
| 8 | Resource depletion and wildlife sustainability | Blocked: owner's choice among the proposals | — | Owner decision | `docs/release/ECONOMY_SUSTAINABILITY_PROPOSALS.md` P1–P3; B7-009 options |

## Waiting on the owner (decisions, not work)

- **Sustainability proposals P1–P3:** demand-driven mining and mining rights; a finite caravan market; prospecting; a distant quarry; wildlife with migration and hunting quotas; one working-money rule and market-based hire wages.
- **B7-009, the manor's starting treasury:** without a change, paid manor work starts about day 12.
- **A need-based maintenance model:** structures that wear, instead of repairs bought with surplus money.
- **The balance review** of every provisional number.

## Tracked future features (approved, not built)

NPC workshop construction; births, children, aging and family growth; music and sound.
