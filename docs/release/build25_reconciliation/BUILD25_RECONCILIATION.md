# Build 25 scope reconciliation (B25-SCOPE-AUDIT)

Owner directives 2026-11-01: `docs/directives/2026-11-01_build25_scope_reconciliation_audit.md`, decision B25-SCOPE-D1
(`2026-11-01_build25_scope_clarification.md`) and the career, business and employment decisions B25-CAREER-D1, B25-BUSINESS-D2,
B25-EMPLOY-D3, B25-AMBITION-D4 (`2026-11-01_career_business_employment_final_decisions.md`). Read-only audit of the Build 25
source `wip/expansion20` at `ad281dc` by four agents (agreement and social/NPC scope; economy and production; branch history;
multiplayer, saves and private-playtest readiness), against the register (`docs/requirements/requirements.json`), the owner directives
and the code. Classes: A implemented and integrated; B implemented with known defects; C partially implemented; D missing; E deferred
or removed by owner decision; F unverified.

## Conclusion

**SCOPE INCOMPLETE — SPECIFIC APPROVED WORK MISSING.** Most approved systems are present and wired into the game. The missing and
partial work is listed in section C; much of it was placed in Build 26 on 2026-10-31 and is Build 25 scope under B25-SCOPE-D1, and the
four 2026-11-01 decisions add the career, business and employment work. Build 25 is not yet consolidated.

## Agreement history (for the record; B25-SCOPE-D1 controls)

- 2026-10-24 and 2026-10-26: every outstanding and previously deferred Build 19 item into "the Expansion 20 effort"; "Nothing previously
  authorized, implemented or partially implemented should be abandoned simply because development advanced to another build number."
- 2026-10-27 to 2026-10-30: finish Expansion 20 first; "Complete LE-03 through LE-07 and all necessary dependencies".
- 2026-10-31: Build 25 = Expansion 20 validation and freeze; Build 26 = recovery of stranded work; LE-07, permanent employment, the LE-05
  remainder, economy activation preparation and Expansion 21 phase 1 recovery assigned to Build 26.
- 2026-11-01: Build 25 is the consolidation build (B25-SCOPE-D1); the 2026-10-31 assignments are history.
- No written record before 2026-10-31 uses "Build 25"; the earlier agreement is recorded as recovery into the Expansion 20 effort, which
  `wip/expansion20` is.

## A. Expansion completeness matrix (counts by class)

| Expansion / area | A | B | C | D | E | F |
|---|---|---|---|---|---|---|
| Expansion 19 remainder (judgment, gossip, personality, bonds, family reputation, misinformation, history) | 8 | 1 | 3 | 0 | 1 | 0 |
| Expansion 20 social (bandit AI, justice, dialogue, player family, migration, judgment C2-C5, aspirations, job choice) | 9 | 0 | 4 | 0 | 3 | 0 |
| Expansion 21 phase 1 (civic foundations) | 0 | 0 | 1 | 1 | 0 | 0 |
| Builds 15-18 social (courtship, marriage, births, aging, succession, orphans, outlaws, reeve) | ~20 | 0 | 0 | 0 | 0 | 0 |
| Employment and careers | 9 | 0 | 0 | 3 | 0 | 0 |
| Shops, businesses, stalls, storefronts, carts | 26 | 0 | 0 | 1 | 1 | 0 |
| Living Economy, trade, contracts, treasury | 25 | 0 | 3 | 7 | 2 | 1 |
| Mining and resources | 25 | 0 | 1 | 1 | 0 | 0 |
| Farming and food | 41 | 0 | 4 | 1 | 0 | 0 |
| Chapel and charity | 0 | 1 | 1 | 0 | 0 | 0 |
| Settlements and caravans | 16 | 0 | 1 | 0 | 2 | 0 |
| Multiplayer, saves, determinism | 13 | 2 | 2 | 0 | 2 | 1 |

The 2026-11-01 career, business and employment decisions (D1-D4) add approved scope not counted above: section C items 1-4.

Feature-level detail: shipped switches at `ad281dc`: `judgment.json` enabled, all decision integrations on except `report` and
`job_choice`, `aspiration.enabled false`; `economy.json enabled false` (market drive, speculation and rental on inside it; negotiated
wages and services off); `balance.json` shared and seasonal farming 0. A-class highlights: judgment core and its 16 live decision hooks,
personality, bonds, family reputation, misinformation and refutation, family stories and history, family sacrifice, judgment calibration
C2/C3/C5, bandit intelligence, guards and pursuit, perspective dialogue, assault and killing fines, player marriage and children, free
migration and identity; skills and trade skills, replacement of essential trades, manor job board, competition (specialisation, wage
raise, relocation, failure), shops, counters, stalls, storefronts, carts, player businesses and tills; Living Economy LE-00..LE-04 and
LE-06 (switched off), tool repair, tool rental (switched off); contracts and credit; treasury, taxes, relief, caravans, feasts and
luxuries; mining phases A-H, stone and ore; farming, seed and food security; regional settlements, food purchasing, reopening, couriers;
multiplayer core, guest validation, `World.mirror`, MP-INTERACT-01, MP-D1..D8, player family, economy integrity; save migration and
fixtures; Build 24 to Build 25 save compatibility (save version 23 unchanged); transaction replay and wear transfer; the 30-day gate.

## B. Abandoned branch recovery matrix

428 refs checked (local, remote, tags, backups), 57 reflog-only commits, 3 pull requests (closed; heads in `ad281dc`), every release
target (in `ad281dc`). 335 refs are in `ad281dc`; the rest were tested by patch equivalence and by the share of their game lines present.

| Branch / workstream | Approved work | Recovery | In `ad281dc`? | Outstanding |
|---|---|---|---|---|
| `wip/expansion21-preparation` `8ac88f5` | P21-00, P21-01, P21-02 (2026-10-23) | not recovered | No (6% of lines; civic offices, records, data, test, 3 docs absent) | port to current code, civic switch off |
| `wip/x20-chapel` `ae8641d` → `55c0881` | X20-CHAPEL-FIX (2026-11-01) | merge pending (authorized) | No | integrate |
| `wip/x20-tell-guard` `1e3b8cf` | X20-TELL-GUARD fix (2026-11-01) | merge pending (authorized) | No | integrate |
| `wip/x20-trader-inv` `3f58ce6` | X20-TRADER-PAY-INV analysis (2026-10-30) | not recovered | No | recover document and `--trader-diag` |
| `wip/juice-assessment` `bebf1f3` | JUICE-00 planning document | not recovered | No | recover document (no gameplay authorized) |
| `wip/roadmap-docs` `e1e8236` | ROAD-02 owner-supplied roadmap sources | not recovered | No | recover documents (no code) |
| staging / `wip/requirements-control` | register (789 vs 1,118 records), directives, 161 docs | documentation reconciliation | game code yes; docs no | bring the register and documents into the Build 25 source |
| `wip/x18-readiness`, `wip/val-recover` | historical and analysis tooling | optional | No | none required |
| MP-01 `wip/multiplayer`, overworld, wild-plants, work, economy backups, 2026-10-18 agent snapshots, guardianship, b17 parity, Expansion 18/19 and MP Batch C snapshots, other reflog commits | integrated | reimplemented or patch-equivalent (54-100% of lines; key files and functions present) | Yes | none (B7-016 stays blocked by its own record) |
| `inventory/registry`, `requirements-sources` archive, `main` uploads | preservation | none | n/a | owner deletion of `inventory/registry` pending (AR-P0-3) |

Uncommitted work: 20 of 65 worktrees have uncommitted files; none holds unrecovered approved game code (agent worktrees are identical to
their backup refs and superseded; the rest are generated `.uid` files, logs, or the gossip trace's debug prints).

## C. Missing approved Build 25 scope

| # | Work | Authorization | Evidence | Action |
|---|---|---|---|---|
| 1 | Career advancement connections (experience → skill → ambition → opportunity → decision → advancement) | B25-CAREER-D1 | skills do not influence job choice or vacancy filling (`seek_work`, `_apprentice_for`); see CAREER_PROGRESSION.md | implement (B25-CAREER-IMPL) |
| 2 | Activate and correct career ambition | B25-AMBITION-D4 | `aspiration.enabled false`, `integration.job_choice false`; stale skill mappings | implement (B25-AMBITION-IMPL) |
| 3 | Skilled employment without fixed headcount | B25-EMPLOY-D3 | `staff_target` = starting count (npc_brain.gd:4482) | implement (B25-EMPLOY-IMPL) |
| 4 | Independent business formation, workshops | B25-BUSINESS-D2 (supersedes F-1 deferral, OD-LE-04 future) | construction placed only from the player's interface; `econ_actor.gd` placeholder | implement (B25-BUSINESS-IMPL) |
| 5 | Permanent employment | EMP-PERM-01 (B18-DP-01) | only shop attendants and building helpers | implement |
| 6 | LE-05 remainder | X20-SCOPE (2026-10-27) | paid commercial repair, route risk, construction hiring, `World.transactions` links absent | implement |
| 7 | Negotiated wages and services | X20-SCOPE, OD-LE-03/D02 | wages built but off; services have no code | complete services; switches as decided |
| 8 | Economy activation preparation | 2026-10-31 s.2 | calibration and dependency evidence incomplete | prepare; activation stays the owner's call |
| 9 | LE-07 release readiness gates | LE-07 | not started | implement (process gates) |
| 10 | Expansion 21 phase 1 | P21-00..02, X21-RECOVERY-D1 | branch `8ac88f5` only | port, switch off |
| 11 | Chapel correction and gossip fix | X20-CHAPEL-INTEGRATE | on task branches | integrate |
| 12 | Trader analysis, JUICE-00, ROAD-02 documents; register and docs into the source | as listed in B | branch-only | recover documents |
| 13 | Judgment-weighted witness report switch; decision explanation record (XEXPL-01); friendship benefits remainder (CRT-06) | X19-SWITCHES-D1 (report part still open); XEXPL-01 no build; CRT-06 depends on politics | built but off / not built | owner decision needed for the report switch; XEXPL-01 and CRT-06 placement is an owner question |
| 14 | Shared and seasonal farming models | FSE-12, FSE-13, FARM-06, FARM-08 | built, off | blocked on open FARM-YIELD-D1 |
| 15 | Approved but never placed in any build: offered pay on the job board (JOB-02), independent villager service hiring (CON-07), further contract kinds and terms (CON-02-KINDS, CON-03..06, CON-08), deeper pits (PIT-02), gardens and multiple incomes (FSE-10), buying animals from the caravan (PL2-015-BUYANIMALS) | owner approvals without a build | not built | owner question: are these "previously approved expansion work" for Build 25? |

## D. Bug and system-correction register

Confirmed (with evidence):
- X20-TELL-GUARD gossip script error (`judgment_store.gd:1490`): fixed and reproduced on `wip/x20-tell-guard` `1e3b8cf`; not yet integrated. Severity: release-blocking (it fails the year-long validation).
- Chapel offerings automatic and the fund absorbing 77-83% of coins (DVW-B3-CHAPEL): corrected on the chapel branch; not yet integrated.
- Stale `skill_start.job_skills` mappings (carpenter, tanner to crafting; no farmer, stonecutter entry), latent while job choice is off; a documentation defect in `settlement/experience.gd:3-6`.
- Register text of WDR-012-C out of date (code has the competition it says is missing).

Suspected or unverified (needs evidence before classification):
- Firewood collapse after day ~180 in normal runs while logs are held and woodcutters fall to 1-2 (axe supply: 0 of 30-56 manor-advanced axes delivered).
- Manor wage raise never fires; public works never spent.
- Multiplayer: no net suite run recorded on `ad281dc` after the LE-05 guest verbs; real-device and real-network checks not done; `net_interact` timing flake.
- Living Economy unaffordable bids (about 12,600 a year): under analysis with the new instrumentation (X20-ECON-AFFORD).
- Save and load (confirmed by a probe on `63c0144`, three game days, seed 1, 2026-11-01): no value is lost (coins, items, positions,
  hunger, jobs equal), but a loaded world is not identical to the uninterrupted one: (1) the random-number state is not saved; load reseeds
  it from the world seed and the clock (`world.gd:6264`), so a loaded game is repeatable from its save but follows a different random
  path; (2) inventories come back with their items in sorted order, which can change "first item" choices; (3) deposit amounts come back
  as decimals (54 → 54.0). Severity: save continuity, not conservation. Proposed fix (small, additive): save and restore the random
  state as an optional key, keep inventory order, convert deposit amounts back to whole numbers on load; then a whole-world reload and
  continue check in the harness.

## Deferred or rejected (E, with the owner decision)

Go-between buying and dislike-driven migration (2026-10-31 merged-validation decisions); crime from desperation (FR-09); adult raised by
bandits chooses their future (FAM-08, future); lending and interest (OD-LE-05B, future); heriot (not chosen); trader pay change
(X20-TRADER-PAY, option A); player service contracts (MP-INTERACT-Q1); paid relay (MP-INET-RELAY option A); inter-settlement network
(SET-E, Expansion 22); multigenerational campaign (SET-D-MULTIGEN); Expansions 22-27 not authorized.

## E. Private playtest readiness

The packaging is ready: `release.yml` is unchanged since Build 24 and builds a signed Android APK (the owner's permanent identity,
package `com.hotatticgames.mymedievallife.dev`, installs over Build 24 and keeps its save), a Windows ZIP (icon checked; unsigned, so
Windows asks "More info, Run anyway") and a Linux ZIP, as a private draft. Save format 23 is unchanged since Build 24. What remains:
1. The missing scope in section C (Build 25 completion as the owner defined it).
2. Integration of the chapel correction and the gossip fix; a new 30-day simulation baseline (the chapel change alters behaviour).
3. Full automated suites on the final commit, including the network suites outside `tests.yml`.
4. Dispatch from a branch fixed at the chosen commit with `visibility=private`, `build_number=25`, on the owner's authorization.
5. Optional short tester notes.

## F. Owner summary

1. All approved expansion packages incorporated? No: Expansion 21 phase 1, the remaining Expansion 20 work and the new career and
   business decisions are not yet in.
2. All approved work from abandoned branches recovered? Nearly: everything except Expansion 21 phase 1, the trader analysis, the JUICE
   and roadmap documents, and the register and documentation, plus the chapel and gossip fixes still on task branches.
3. Approved features missing or partial? Yes, section C.
4. Only bug fixing left? Not yet: implementation of section C first.
5. What prevents packaging today: the missing scope, the unintegrated chapel and gossip fixes, the baseline and suite runs on the final
   commit, and the owner's packaging authorization.
