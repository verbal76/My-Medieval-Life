# Current session recovery handoff (updated 2026-10-22, overnight session start)

Continuity checkpoint for the lead agent after a context compaction. The authoritative records are:
- the register (`docs/requirements/requirements.json`);
- `docs/DECISIONS.md`;
- `docs/directives/`, newest first: `2026-10-22_build18_master_overnight_execution.md` (the overnight mandate);
- `docs/CURRENT_DEVELOPMENT_STATE.md`;
- CLAUDE.md (MSW-01, SIM-01, SIM-02, WIKI-01).

Read the overnight directive first.

## Mandate in force (owner, overnight, 2026-10-22)

- **Scope:** Build 18 is combined (tracks A, B, C; register B18-SCOPE). Multiplayer is excluded: do not touch
  `wip/multiplayer`.
- **Usage control:**
  - workers on Sonnet, routine work on Haiku;
  - at most 2 or 3 workers;
  - no repeated campaigns and no full gate early;
  - checkpoint at 70–75% context.
- **Decisions closed tonight:**
  - INV-Q1: lockpick and padlock to Tools;
  - INV-Q2: capacity 9/18/27 per category, two global upgrades sold by the tailor at 150 and 450 coins;
  - ARMOR-Q: Option A.

  Do not reopen them.
- **No releases. Build 17 is frozen at `cd7439c`.**

## Branches (remote heads at the start of the night)

| Branch | Head | State |
|---|---|---|
| `staging/my-medieval-life` (main worktree, local `wip/b16-integration`; push both) | latest decision record | records only |
| `wip/build18` (worktree `scratchpad/b18wt`) | `d63d8d7` | integrated Build 18: track A fixes, CC-01 complete, FARM-CROP-01, INV-18 (save 19), TAILOR-18 purchase, ARMOR-01 Option A, Expansion 18 (inactive parts off) |
| `wip/b18-inventory` | `ba1369e` | merged; worker done |
| `wip/b18-armour` | `9f3a237` | merged; worker done |
| `wip/b18-polish` (worktree `scratchpad/b18polish`) | from `d63d8d7` | `8366315` merged into wip/build18; worker done |
| `wip/x18-readiness` | `0182466` | readiness note (done); Expansion 18 merged into Build 18 as `d63d8d7` |
| `wip/expansion18-preparation` | `3de7a8f` | Expansion 18 code; D2–D9 open |
| `wip/expansion19-preparation` | `c4b10e4` | waiting on owner decisions |
| `wip/multiplayer` | `d18d7d1` | preserved, untouched |

## Progress so far tonight (checkpoint)

- `wip/build18` went from `0fafb8b` to `d63d8d7`:
  - INV-18 merged (`5f82f0c`): categories, capacity 9/18/27, save version 19, migration, `inventory18_test` 88/0;
  - TAILOR-18: the purchase is built; where the tailor comes from waits on TAILOR-Q;
  - ARMOR-01 Option A merged (`609635d`), which also completes CC-01's gear redraw;
  - Expansion 18 merged (`d63d8d7`) with its inactive parts off: experience recording is live (records only), the
    capability hook is OFF, and the couriers, formal contracts and regional code are present but not wired.
- Focused tests on `d63d8d7`, all 0 failures:

  | Suite | Result |
  |---|---|
  | `run_tests` | 3,584 checks |
  | start | 506 steps |
  | play | 39 steps |
  | inventory | 88 checks |
  | experience | 61 checks |
  | capability | 72 checks |
  | farming | 224 checks |
  | crop sharing | 19 checks |
  | contracts | 138 checks |
  | courier | 44 checks |
  | settlement | 83 checks |
  | wiki | all passed |
  | character look | 0 failures |
  | Python | OK |

  Static checks: 0 problems. Run each Godot test with its own private `XDG_DATA_HOME`: a shared user folder gives
  false save-timing failures.
- Running: the polish worker (Sonnet) on `wip/b18-polish`: VIS-STEPS-01 art, the contract grid fit and the contract
  refusal grammar.
- New owner decisions recorded tonight: TAILOR-Q (where the tailor comes from), BARBER-Q, HORSE-Q.
- Workers started tonight: armour (Sonnet), Expansion 18 readiness (Sonnet), polish (Sonnet). The inventory worker was
  already running.
- Next: merge the polish branch; then stop optional work and write the morning report (part 16 of the overnight
  directive). The release gate is premature: the tailor placement and the D-decisions are open.

## STATUS (2026-10-23, later): wip/build18 at 83d3afc, all 66 Godot suites + Python pass. Merged since: contract window (+plural fix), trade/Law/farming-etc skills, rooms+plots (generator v8), import-validation fix (fresh map). X19-DECAY held (owner asked for calendar explanation; given; awaiting their call). Workers running: wip/b18-chapel (DVW-B3-CHAPEL), wip/b18-regions (SET-C-SIM/FIVE from docs/world gazetteer, caravan as their traders). Next: feasts, luxury imports, ECON-P3 tills, TRADE-CREDIT, MIGRATE-18, courier booths (Q18-14..16), DVW-B5 taxes, X18-SIM, then release gate. No release without the owner.

## Next actions, in order (historical)

1. **When the inventory worker reports:**
   - review its commits;
   - spot-check one screenshot;
   - merge into `wip/build18` (save version 19);
   - run the focused tests the merge touches;
   - register INV-18 and TAILOR-18.
2. **When the armour worker reports:** merge it after the inventory work (both touch the player's look indirectly).
   Register ARMOR-01 and CC-01 (the gear redraw completes CC-01).
3. **When the readiness review reports:** integrate only the complete, approved, flag-off pieces of Expansion 18,
   after INV-18 is merged (save-version ordering).
4. **Barber (BARBER-01):** still blocked on owner decisions (BARBER-Q): who staffs it, where, the price, and whether
   colour and beard count as hair. Record only.
5. **Only if budget remains:** a restrained game-feel pass (part 9) on confirmed defects.
6. **Morning report:** the format in part 16 of the overnight directive.

## Evidence on `wip/build18` `0048b56`/`0fafb8b` (reuse; do not rerun on unchanged code)

- `run_tests` 3,584 checks, start 503 steps, play 39 steps, wiki;
- character look 24, prospecting 73, crop sharing 19, farming 224, trees 45;
- Python 105 tests;
- asset, interaction and register checks, 0 problems each.
