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
| `wip/build18` (worktree `scratchpad/b18wt`) | `0fafb8b` | integrated Build 18: tracks A fixes, CC-01, FARM-CROP-01, ORE, AXE, TREES, MAP, trade fixes, visuals |
| `wip/b18-inventory` (worktree `scratchpad/b18inv`) | from `0fafb8b`, uncommitted work in progress | INV-18 plus TAILOR-18 (inventory worker, model inherited) |
| `wip/b18-armour` (worktree `scratchpad/b18armour`) | from `0fafb8b` | ARMOR-01 Option A plus gear redraw (Sonnet worker) |
| `wip/x18-readiness` (worktree `scratchpad/x18ready`) | from `wip/expansion18-preparation` `3de7a8f` | integration-readiness review only, no merge (Sonnet worker) |
| `wip/expansion18-preparation` | `3de7a8f` | Expansion 18 code; D2–D9 open |
| `wip/expansion19-preparation` | `c4b10e4` | waiting on owner decisions |
| `wip/multiplayer` | `d18d7d1` | preserved, untouched |

## Next actions, in order

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
