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

Release gate: Build 13 (`4e76f72`) is the current private testing build (a draft release); device reports go
into the issue register as before. No public release and no merge into `main` without the owner's explicit
authorization.

This queue gives the order of work. Every item's status, evidence and branch is in `docs/DEVELOPMENT_LEDGER.md`
(the open-items register, including B13, B14, CQ, MP, GM, WR, VP, DVW and FR items); the full Build 14 audit is
`docs/release/BUILD_14_OPEN_ITEMS_AUDIT.md`.

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
| 11 | Design gap assessment and phased implementation sequence for the isometric, 8-direction, multiplayer, persistent-character, magic and living-society goals | Proposed — awaiting owner approval | agent proposal | Owner decisions D1–D12 | [`docs/DESIGN_GAP_ASSESSMENT.md`](DESIGN_GAP_ASSESSMENT.md); documentation only, no code started; preparatory refactors R1–R7 and spikes S1–S2 need approval first |
| 12 | CQ-01 Sword combat responsiveness and hit detection (owner, 2026-10-19: presses lost every second or third time, hits needing sprite overlap) | Integrated; device check outstanding | lead, staging | — | Root causes: presses during the 0.6 s cooldown were dropped; the touch Attack button only toggled attack mode (so mashing switched it on and off); tap-to-strike walked to 1.0 tile; damage landed on the press; the first NPC in list order was hit, not the nearest foe; solid cells did not block blows. Fixed by `Combat` (windup to the slash frame, one blow, recovery, one buffered press), a reach arc with a clear line, the touch button swinging at a foe in reach. `combat_test` (41 checks). Real Android touch feel not verified. Archery not authorised |
| 13 | MP-01 Player-hosted multiplayer foundation: two-player LAN prototype (host, discover, join, two moving characters, reconnect with a persistent guest identity), host-authoritative (owner directive, 2026-10-19) | In progress: prototype on `wip/multiplayer` `d18d7d1` (isolated, not in staging) | lead | — | Phases 2-5 (four players, shared interactions, Android hosting, internet) after the LAN milestone is verified on two real instances |
| 14 | GM-01 Generational memory and historical consequences: event records with causal links, knowledge transmission, family lineage, dialogue from real history (owner directive, 2026-10-19) | Ready (approved) | — | DVW relationships item | Acceptance: the 30-planks multigenerational chain from real records |
| 15 | WR-01 Protected wildlife breeding refuges, offspring cohorts and dispersal (owner directive, 2026-10-19) | Ready (approved) | — | B14-08 forest animals | Supersedes the wildlife half of item 8's proposals; replaces the scavenging floor added in `f9fb853` once refuges exist |
| 16 | VP-01 Living village politics: offices (mayor or equivalent, constable, captain of the guard, guards), individual NPC voting, election cycles, civic authority with real treasury costs (owner directive, 2026-10-19) | Ready (approved) | — | 14 (memory), DVW items | Acceptance: section 32 tests of the directive |

## Waiting on the owner (decisions, not work)

- **Sustainability proposals P1–P3:** demand-driven mining and mining rights; a finite caravan market; prospecting; a distant quarry; wildlife with migration and hunting quotas; one working-money rule and market-based hire wages.
- **B7-009, the manor's starting treasury:** without a change, paid manor work starts about day 12.
- **A need-based maintenance model:** structures that wear, instead of repairs bought with surplus money.
- **The balance review** of every provisional number.

## Tracked future features (approved, not built)

NPC workshop construction; births, children, aging and family growth; music and sound.
