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

Release gate: Build 8 (`cd35b54`) is the private testing build (a draft release); device reports go
into the issue register as before. No public
release and no merge into `main` without the owner's explicit authorization.

| # | Task | Status | Owner / branch | Depends on | Notes |
|---|---|---|---|---|---|
| 1 | Responsive HUD anchoring and Android layout corrections (B7-010) | Device check | staging `633898f` | — | Status box, log and action bar anchored to the corners; camera cutouts avoided per element |
| 2 | Gather mode, plus taps on resources (B7-011, B7-012) | Device check | staging `fabb58f` | — | Built on `ResourceNodes`; INT-068 |
| 3 | Resource Node Manifest and Resource Usage Registry from one authoritative definition, with validation | Integrated | staging `95fc554` | — | `game/data/resources.json`, `tools/check_resources.py`, `docs/systems/*.md`; INT-067 |
| 4 | In-game Resources & Gathering journal page from the same definitions | Device check | staging `8641ff6` | 3 | Includes the Gather mode instructions |
| 5 | Reeve employment: real jobs, NPCs by the same rules | Integrated | lead, staging | — | INT-066; save version 8 |
| 6 | Long-duration simulations (10/30/100/365 days) | Integrated | staging | 5 | Results in `docs/release/LONG_RUN_SIMULATION.md`; defects B7-014 to B7-017 |
| 7 | Build 7 economy corrections (B7-001 to B7-005, B7-007 stone) | Device check | staging `ae0e01f` | — | See the issue register |
| 9 | Brown glyph icons for the HUD, gear slots, skills and journal (B7-013) | Device check | staging `49f5cb9` | — | — |
| 10 | Hot Attic Games read-only registry | Blocked: owner's decision on the registry branch and on a private location | — | Owner decision | Publication paused (owner, 2026-10-18): public repositories only on a public branch; the full registry continues locally until a private location exists |
| 8 | Resource depletion and wildlife sustainability | Blocked: owner's choice among the proposals | — | Owner decision | `docs/release/ECONOMY_SUSTAINABILITY_PROPOSALS.md` P1–P3; B7-009 options |

## Waiting on the owner (decisions, not work)

- **Sustainability proposals P1–P3:** demand-driven mining and mining rights; a finite caravan market; prospecting; a distant quarry; wildlife with migration and hunting quotas; one working-money rule and market-based hire wages.
- **B7-009, the manor's starting treasury:** without a change, paid manor work starts about day 12.
- **A need-based maintenance model:** structures that wear, instead of repairs bought with surplus money.
- **The balance review** of every provisional number.

## Tracked future features (approved, not built)

NPC workshop construction; births, children, aging and family growth; music and sound.
