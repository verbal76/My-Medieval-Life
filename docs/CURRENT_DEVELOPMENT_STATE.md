# Current development state

This is the session handoff (owner directive 2026-10-20, register MEM-01). Read it after `docs/PROJECT_MEMORY.md` at the start of every session, and update it before a session ends, before a context handoff and before a build. It records where the work stands. It does not copy the register: every id below is an entry in `docs/requirements/requirements.json`, and the register is authoritative where they differ. `tools/check_requirements.py` fails if an entry in ACTIVE DEVELOPMENT is not named here, or if a path named here does not exist.

**Updated:** 2026-10-20.

## Where the work is

| | |
|---|---|
| Repository | `verbal76/My-Medieval-Life` |
| Development branch | `staging/my-medieval-life` (push here; standing authorization) |
| Last verified remote commit | The head of `origin/staging/my-medieval-life` (`git log origin/staging/my-medieval-life -1`). This file was last brought up to date in the commit `git log -1 -- docs/CURRENT_DEVELOPMENT_STATE.md` shows; anything newer on staging is described in that commit's successors. |
| `main` | Changes only when the owner merges. |
| Multiplayer | `wip/multiplayer` (MP-01), isolated. It must not be merged into staging without the owner's explicit approval. |
| Active build | **Build 17** (mining and underground, contracts, decay, terrain; OD-28, OD-29) on `wip/build17`. **Build 16 is released:** published 2026-10-21 16:06 UTC from `b3bbb1c` (game code identical to the tested `dbbb66a`), https://github.com/verbal76/My-Medieval-Life/releases/tag/build-16, packet `docs/release/BUILD_16_PACKET.md`; its open carry-overs (FARM-08 yield decision, FARM-08B, FSE-12, FSE-13, STALL-06, DVW-A3, B7-016, device playtests) stay in the register |
| Recovery handoff | Read `docs/handoffs/CURRENT_SESSION_RECOVERY.md` first after a compaction (branches, workers, open decisions, next steps) |
| Game Juice (JUICE-00) | Read-only presentation assessment (owner 2026-10-22), unnumbered workstream, assessment done (wip/juice-assessment bebf1f3); top ten and decisions JD1-JD6 with the owner; nothing implemented |
| Expansion 20 now | Preparation only (owner 2026-10-22): LE-00, the Living Economy's read-only architecture audit, on wip/expansion20-preparation; no implementation; OD-LE-02..15 open |
| Expansion 18 now | X18-CAPNUM (all seven capability profiles approved, Q18-11A closed) being implemented on wip/expansion18-preparation; next design question: the experience measure and facility caps (X18-CAPCOMP) |
| Expansion sync (SYNC-17) | Owner 2026-10-21: one-way merge of wip/build17 at cd7439c into wip/expansion18-preparation and wip/expansion19-preparation, by their workers, focused tests only; nothing back into Build 17 |
| Prospective work | PROS-01 (owner, 2026-10-21): Expansion 18 (PROS-18) on `wip/expansion18-preparation` and Expansion 19 (PROS-19) on `wip/expansion19-preparation`, both branched from staging; isolated until their reconciliation gates; Build 17 stays priority 1 |
| Expansion 18 now | X18-SIM (capability simulations, no constants before owner review), X18-Q12 (transport) with X18-Q12-BOOTH (courier booths, known recipients) and X18-Q12-POST (courier contract popup and fee), X18-Q13 (signing) on `wip/expansion18-preparation`; Q18-11A/B open |
| Directive in force | OVN-02, `docs/directives/2026-10-20_final_development_mandate.md` (final mandate: Build 15 closes on mechanics and integrity, not prosperity; then Builds 16 → 17 → 18 in order), with OVN-01 (`docs/directives/2026-10-20_master_overnight_development_directive.md`) and `docs/directives/2026-10-20_compaction_readiness.md`. The design principle WDR-022: "A village is allowed to fail. The simulation is not." |
| Last released build | **Build 15**, a private draft from `a8760be` (`docs/release/BUILD_15_PACKET.md`), released 2026-10-20 |
| Release authorization | OVN-01 section 9 and REL-15-18: Builds 15 to 18 may be released as **private drafts**, in order, each only when every condition of OVN-01 section 4 holds (REL-14-16 before it). No placeholder builds. Public visibility needs new owner approval. |

Old agent worktrees (`.claude/worktrees/*`, branches `pl-*`, `b8-*` and others) hold work that has been merged. They are history. Only `wip/multiplayer` is live.

## In progress (ACTIVE DEVELOPMENT)

**Build 18 (owner B18-DIR, 2026-10-22, `docs/directives/2026-10-22_build18_master_integration.md`).** Integration branch
`wip/build18`, cut from Build 17's frozen head `dfec7ec` (Build 17 is untouched). FARM-CROP-01 merged there (`9cb011d`,
crop_share_test 19/19). Phase A inventory: `docs/build18/PHASE_A_INVENTORY.md`. Active: UI-HUNGER-01, UI-HUD-01,
UI-PROGRESS-01, VIS-ANIMAL-01, VIS-CROP-01, VIS-DOOR-01 (visual worker, `wip/b18-visual`); UI-WIKI-01 (`wip/b18-wiki`);
CC-01 (character worker, `wip/b18-character`: runtime layered sprites, recipe saves, creator UI; no armour values, no barber
economy). ORE-PLACE-01 fixed and merged into `wip/build18` (`ff8749f`; prospecting clues kept out of the settlement footprint; the determinism gate must be re-baselined at integration). VIS-AXE-01 (lead, `wip/b18-axe`) and VIS-TREE-02 (worker, `wip/b18-trees`). INV-18 merged (wip/build18), TAILOR-18 purchase built, placement awaits TAILOR-Q. ARMOR-01 Option A merged. BARBER-01 waits on owner decisions (armour scope first). Nothing is built or published without the owner.

The validator checks that every ACTIVE DEVELOPMENT id is named here. Updated 2026-10-20 in the evening (UTC).

- **EQ-18 (Build 15):** tool recovery fixed and verified; what remained was OD-16.
- **EQ-18..21 (Build 15):** complete and verified (EQ-19's earmarked advances are a recorded future improvement).
- **Build 16:**
  - FAM-07 is implemented and tested, with the owner's clarification of 2026-10-20 (`docs/directives/2026-10-20_fam07_clarification_living_economy.md`): an orphan no household takes lives with the bandit clan. At coming of age they leave for a household that can take them, and stay with the band only with nowhere to go. The fuller adult judgement is FAM-08, future work.
  - The audits DVW-A7, A8 and A12 are done (`docs/release/BUILD_16_AUDITS.md`). The player's own production is now counted in the ledger (`World.player_gain`). The audits' owner questions are OD-18; A12's moves into core remain.
  - **EQ-06** (the acceptance harness): `economy_sim.gd --scenario kill_smiths|corner_wheat|gift_coins|hunt_out --at DAY`. The pre-parity baseline is recorded in `docs/release/LONG_RUN_SIMULATION.md`: the 100-day scenarios on seeds 1-2, and the 365-day runs on seeds 1-4 (Actions 39430585149 on `8d3f623`). Seed 3's 23 starvation deaths are under investigation (B7-015).
  - **Player-villager parity (PAR-00..05), the owner's OD-18 and the final consolidated directive** (`docs/directives/2026-10-20_od18_player_villager_parity.md`, `docs/directives/2026-10-20_par_final_consolidated_directive.md`):
    - PAR-01 (with PAR-01A..C) villager skills, PAR-03 rest, PAR-04 the eleven recipes and PAR-05 crime awareness (sight and reports, no hearing) are complete and pushed.
    - PAR-02A, OD-19's dynamic reserve (`docs/directives/2026-10-20_od19_dynamic_reserves.md`), is implemented (`World.necessity`, `reserve_test.gd`) and was being tested with the full suites; commit it once they pass.
    - OD-20 (the pickpocket's cry) is open; theft keeps its 2026-10-18 cry until the owner answers.
  - **Next:** re-run the EQ-06 scenarios (100 days, seeds 1-2) and the 365-day runs (seeds 1-4, Actions) on the parity code; compare with the baseline; investigate seed 3's starvation (B7-015); classify under WDR-022.
  - **Starvation after parity (B7-015, FSE-16):** every one of seed 2's 11 deaths is analysed in `docs/design/FOOD_SECURITY_AUDIT.md` section 2, from an exact reproduction of the baseline (`economy_sim.gd --watch-from`). Fixed and on staging: the family tab's fixed 2-coin test and the relief order (`9db091b`, gate re-baselined in `722abe1`). Next: FSE-17 (relief buys from every food store; a household's own stores all count), then the eating and cooking parity (households roast their own meat, eat eggs and milk), then rerun seed 2 for 365 days and compare with the baseline in `docs/release/LONG_RUN_SIMULATION.md`.
- **FSE-00 (owner's food-security and goal-driven economy directive, 2026-10-20,** `docs/directives/2026-10-20_food_security_goal_driven_economy.md`**):** audit first (FSE-01..07, deliverables in `docs/design/FOOD_SECURITY_AUDIT.md`), then only defects and small foundations in Build 16 (FSE-09); gardens, rented land and pens, side hunting, household stalls, multiple incomes and goal-driven individual choices go with the Living Economy build (FSE-10, with EXP-D). The owner's follow-up of the same day (`docs/directives/2026-10-20_agricultural_findings_followup.md`) orders the work: first the seed-2 starvation report, death by death (**FSE-16**, active); then seed consumption at sowing (FSE-11) and one agricultural model for player and village (FSE-12); seasonal village farming is built and tested behind a switch that stays off in the baseline until the owner reviews the comparison (FSE-13); land planning is design and foundations only (FSE-14); the land requirement is recalculated after them (FSE-15). Note: a calendar year is 8 game days (four 2-day seasons), so a 365-day run is about 45 years.
- **AGENT-01 and MILE-01 (owner, 2026-10-20, `docs/directives/2026-10-20_controlled_parallel_development.md`):** at most two subagents at once, bounded and non-overlapping, only the lead runs long simulations, an agent summary in each progress report; nothing moves into Build 16 from the Living Economy build or Build 19 without the owner.
- **B16-AUDIT (owner, 2026-10-20):** the Build 16 status audit, `docs/BUILD_16_STATUS.md`, its tables generated from the register by `tools/build_status.py --write`; kept current as work completes.
- **OD-22, OD-23, OD-24 (owner, 2026-10-20, `docs/directives/2026-10-20_od22_od23_od24_farms_leases_stalls.md`):** family farm plots for any household (FARM-01..07) and stalls on a 5% sales commission for anyone (STALL-01..06). Order: first report the running family-chest comparisons (FSE-18), then build them incrementally with tests. FSE-18 (the family chest) is in active development.
- **OD-21 (owner, 2026-10-20, `docs/directives/2026-10-20_od21_time_model.md`):** keep the 8-day year; every timed system classified as operational, economic or calendar time. TIME-01 (done): the time-system audit in `docs/design/TIME_MODEL.md` (defects D1 = FSE-13, D2 and D3 = TIME-02, D4 = TIME-04); TIME-02: explicit units through one shared conversion layer, behaviour unchanged at 8 days; TIME-03: retuning proposals only, owner review before any change.
  - Then the rest of the Build 16 entries (the ledger's Roadmap), each finding classified under WDR-022.
- **Living Economy (EXP-D):** the owner's standalone build design, kept as a separate major build (OD-LE-01..15 open). It does not delay Build 16.
- **EQ-16** (Build 16 objective, world equilibrium) and **DVW-A3** (money supply measurements): they share the 365-day runs. OD-16 is their first question.
- **OVN-02** (the final mandate) and **OVN-01:** the directives in force. **WDR-022-C:** classify every finding as defect, legitimate outcome or future improvement. **ROAD-01:** the roadmap.
- **REL-14-16:** superseded in practice by REL-15-18 for Builds 15-18. Build 14 is done.
- **PERF-01:** the runtime answer. PERF-02..05 are complete (the simulation is about twice as fast, and every change passes the gate). PERF-06 (checkpoint and resume) is evaluation only, done in `docs/release/SIMULATION_PERFORMANCE.md` section 4.
- **MP-01:** multiplayer on `wip/multiplayer` only. Nothing to do without the owner.

Closed on 2026-10-20, with evidence in the register:
- EQ-07 and HOUSE-07 (houses finished on both seeds in the 365-day runs on `59057ac`: 8 and 2);
- HOUSE-10 (the small 5x6 room with two beds, for the three original houses with ground beside them), HOUSE-09 and HOUSE-06;
- EQ-17 and EQ-10, both verified by 365-day Actions runs;
- FR-07 (CI run 39368652711), DVW-A4, FR-06, PERF-02..05, B14-12 (sprite list), REC-017;
- B7-008 verified, with its buyer half waiting on OD-15.

Implemented and tested ahead of Build 16 (kept in Build 16): FAM-02..06 (orphans taken in by kin or another household), WR-02 (grazers over capacity). FAM-07 (the bandit-clan fallback) is now built, interim (camp dependants).

## Last test results (2026-10-20, late, on `d6d80a4`)

- **Godot suites:** all 27 in `.github/workflows/tests.yml` pass locally.
- **Python:** `python3 -m unittest discover -s tests` OK. `tools/check_requirements.py`, `check_interactions.py`, `check_resources.py`, `tools/assets/check_assets.py`: 0 problems.
- **Determinism gate:** re-baselined on `d6d80a4` after FSE-B06/B12 and the whole-pot grain rule (TIME-02 left it identical); no coin or item leaks.
- **Year-long runs** (`docs/release/LONG_RUN_SIMULATION.md`): the family chest (`61750f1`): starvation 1 / 1 / 2 / 7 on seeds 1-4; seed 4 with the firewood fix (`1c7b9f4`, local): 1 death, a relief-grain defect, fixed in `d6d80a4`. A four-seed Actions run on `d6d80a4` is under way.
- **Known failures:** none in the tests.

## Known defects (open)

- **The trade economy stalls (Build 16, EQ-06 and OD-16):** the smith is near 0 coins from about day 120, unemployment reaches 24-39 by day 365, and households go without firewood on most nights. Seed 2 lost four villagers to hunger in a year. About 45 % of coins sit with bandits or as loot nobody picks up.
- **Hunters' income:** most meat finds no buyer, and hunters miss most meals for lack of money. Build 16 equilibrium (EQ-01); part of OD-16's question.
- **EQ-09, stone (Build 16):** deposits run out; caravan stone (B7-007) supplies it.

## Hardware checks still required (done, not verified on a device)

The device queue is entries with status AUTOMATED TESTS PASSED — PLAYTEST REQUIRED (the ledger lists them). Among them:
- SAVE-00 and SAVE-02..09 (SAVE-01 is complete): export and import a save on an Android phone, through the system picker (SAVE-05);
- CRT-01, CRT-02, CRT-04, CRT-05 and CRT-07..12 (CRT-03 and CRT-06 are not device items): courtship and friendship;
- WR-01: the refuges;
- CQ-01, B13-12, B13-13, B14-01, B14-06 and B14-13;
- B7-001, B7-005 and B7-010..013;
- B8-018, PL1-03, PL1-05 and Q-04.

The complete list is the ledger's "Real-device verification queue". None of these can be closed until a real device check is recorded.

**Who does them and when:** the owner (or a tester the owner names) does them on their own phone, controller and PC. This happens when a private build is installed, Build 15 next. The agent prepares the checklist in the build's packet and records the results the owner reports with `tools/requirements_update.py set ID --playtest-done "device, date"`. The umbrella entry B12A-10 is this owner action.

## Next approved tasks, in order

Updated 2026-10-20 about 10:00 UTC under the overnight directive (OVN-01): Builds 15 to 18 in order. The overnight report for the owner is `docs/release/OVERNIGHT_REPORT_2026-10-20.md`.

1. **Build 15: complete** (released 2026-10-20, `docs/release/BUILD_15_PACKET.md`).
0. **Coordinated Build 16 push (owner master directive 2026-10-21, `docs/directives/2026-10-21_build16_master_completion_directive.md`):** complete Build 16 in full. Q8-Q13 answered (OD-27). Workers, each in its own worktree and branch, the lead integrating: A family farms (FARM-01, FARM-02, FARM-03, FARM-04, FARM-05, FARM-07, FARM-09, FSE-14, FSE-15) on `wip/b16-farms`; B market stalls (STALL-01, STALL-02, STALL-03, STALL-04, STALL-05, STALL-06, the commission to the treasury) on `wip/b16-stalls`; C cattle and yield (FARM-08, 08B, 08C, FSE-12/13 evidence) on `wip/b16-cattle`; D remaining items (TREAS-01 manor procurement, REC-001, DVW-A5, then EQ-03/EQ-04) on `wip/b16-misc`. Land pricing: the existing Property.land_price (60 per 90 cells) and rent_of (10 % a week); no new coefficient. Then integration, the four-seed runs, the private candidate.
1a. **Owner audit of 2026-10-21 (B16-READY, `docs/directives/2026-10-21_build16_audit_release_readiness.md`):** answered in `docs/BUILD_16_STATUS.md` sections F and R. A private Build 16 development candidate needs only the four-seed 365-day run of the current staging with both farming switches off (control jobs of Actions run 39598992347) and the owner's authorization; no build is made without it. Then FARM-08B/FARM-08 continue.
2. **Build 16, now** (plan: `docs/BUILD_16_STATUS.md` section E; owner decisions in `docs/directives/2026-10-21_*.md`): FARM-08 (ACTIVE DEVELOPMENT, the lead): the shared-yield comparison, `long-sims.yml` with `variants` shared_wheat_yield 1.0/1.5/2.0/2.5/3.0 and both switches on, four seeds, 365 days; then the report with a proposed yield for the owner (switches stay off). Run 39580481791 (23 of 24 jobs) is read; FARM-08A (a homeless household's script error, seed 2 at 2.5) is fixed on staging and its re-run is Actions run 39595792732. Owner directive of 2026-10-21 (`docs/directives/2026-10-21_farm08_cattle_investigation.md`): no yield is recommended until the cattle decline is explained (FARM-08B, ACTIVE DEVELOPMENT: cattle die out under shared + seasonal farming even at yield 3.0) and the wheat price floor is recorded as a finding (FARM-08C, ACTIVE DEVELOPMENT; no pricing change without evaluation). The milk drop under FSE-13 alone is explained in `docs/design/FSE13_COMPARISON.md`. SHOP-01/TRADE-01/CTR-04 are on staging (0217431). Waiting on the owner: the six farm and stall audit questions (status doc section C, 8-13), the EQ-22/PICK-01/seed readings, ARM-01 and CTR-01..03 device playtest. Then Build 17, Build 18 in order.
3. Open Build 15 entries that are not code: DVW-A14 (the whole-life play-through, item 8 of the testing checklist), REC-003 (the owner's confirmation of the API 36 policy), and the device checks.

Skipped (deferred) items: one, WDR-010-C's cart-route feedback (`docs/SKIPPED_ITEMS.md`): carts have no collision, so no route is ever blocked.

## Waiting on the owner

- **OD-14:** answered (smaller attached rooms; the small room is built, HOUSE-10). Upper floors stay a future design consideration (HOUSE-11, deferred by the owner).
- OD-11, OD-12 and OD-13 were answered by the owner on 2026-10-20 (`docs/directives/2026-10-20_owner_answers_OD11_OD12_OD13.md`). Their implementation is open:
  - HOUSE-08 (bed sharing) and HOUSE-09 (now done through the small room), Build 15;
  - FAM-03 and FAM-07 (the bandit-clan fallback, interim until bandit factions, WDR-016-C, Build 20+) are implemented.
- **OD-16: answered 2026-10-20** ((a), (b), (c); see the register). Formerly: the village's trade economy stops around day 120-140 on seed 1 (the smith out of coins, no iron, no axes, no timber), so no house is finished there. How should money flow back to the essential trades? Options and a recommendation are in the entry and in `docs/release/LONG_RUN_SIMULATION.md`.
- **OD-18, OD-15 and OD-19: answered 2026-10-20** (PAR-00..05, PAR-02A).
- **OD-20 (open, 2026-10-20):** should a caught pickpocket's cry (the 2026-10-18 theft rules; the Stealth guard_radius perk acts on it) become a report, like assault's?
- **OD-17 (new, 2026-10-20):** the Game Designer spec's open calls (the hero, the view, Steam Deck labelling), from `docs/game-designer/SPEC_RECONCILIATION.md` section 4 (REC-004, done).
- **OD-15 (new, 2026-10-20):** should the player's sales stop at a trader's 15-coin floor, as villagers' do? It came up while verifying B7-008; options and a recommendation are in the entry. B7-008 stays BLOCKED on it (its wildlife half is verified).
- **OD-01..09:** open owner decisions. Some are listed under the build whose design they decide, with the gate "owner decision first".
- **SJD-Q01..Q14:** the judgment system's 14 questions. They are items 25–38 under the heading "Owner decisions still open" (line 584 of `docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.txt`; the spec numbers two headings 19, and this is the second). The spec also names open points inside its sections, such as the rumour and credibility questions in its evidence section. Those belong to the same gates and are unanswered too. Never answer any of them on the owner's behalf.
- **GM-01, generational memory:** placed in Build 19 as the closest fit. The owner has not confirmed this (gate "fit to confirm"). **VP-01, village politics:** approved, but in none of the five builds (target `20+`, after Build 19's judgment).
- Entries with `target_build` `owner decision` or `owner action`, such as the permanent Android signing key, deferred by the owner.
- **Builds 17–19 (EXP-A, EXP-B, EXP-C):** approved objectives that have not been started. They need the owner's authorization to begin.

## Interrupted or fragile processes

- **Running (2026-10-21):** on Actions, `long-sims.yml`, one after another: run 39523615798 (acceptance, four seeds, 365 days, `1fefddb`), run 39525733581 (FSE-12 comparison, `set: shared_manor_farming=1`, `09c8cb1`), run 39526774144 (FSE-13 comparison, `set: seasonal_village_farming=1`, `df54ef1`). Read each job's log tail (summary about 150 lines from the end). A worker builds SEED-02..04 and MERCH-01 in its own worktree (merged by the lead after the suites and gate). Nothing running locally.
- Runs 39385942656 (`59057ac`) and 39430585149 (`8d3f623`, the pre-parity baseline) are finished and recorded.
- **Long runs belong on Actions** (INFRA-02): dispatch `long-sims.yml` with `ref=staging/my-medieval-life` and inputs seeds, days, every. Local runs die with the container.
- **Local scratch output** in `out/` (git-ignored) is not a record: only the written reports are.
- **Never restart a run because context was compacted:** check Actions (or `ps -eo pid,args | grep godot` locally) first.

## Recovery test (MEM-01, 2026-10-20)

**How it was run:** an agent with no conversation context, working from a fresh clone of `staging/my-medieval-life` at `3814618`.

**Result:** it answered all seven questions of the directive from the committed files. It needed four core files (CLAUDE.md, this index, this file, the ledger) and about 13 files in all.

**Gaps it found, fixed in `c2ed962` and the commit after it (a re-check by the same agent confirmed them):**
- stale pointers to the old plan and queue (CLAUDE.md section 5, the ledger header, `docs/DEVELOPMENT_PLAN.md`);
- a device queue missing the status-only playtest items;
- the decision lists' counts;
- the expansion roadmap's superseded sequence;
- CLAUDE.md's platform line;
- the Build 15 run results kept only outside the repository;
- the SJD question mapping;
- GM-01 and VP-01 placement;
- REL-14-16's next action;
- REC-002's off-repository source.

Some register sources cite `docs/HANDOFF.md`, `docs/DEVELOPMENT_QUEUE.md` or `docs/DEVELOPMENT_PLAN.md`. Those are where the item was first recorded; the files are kept, marked historical, so the citations stay valid. Repeat this test after any large change to the memory files.

## Recovery tests (MEM-02, 2026-10-20: the owner's nine questions)

Each pass used a new agent with no conversation context, working only from a fresh clone of `staging/my-medieval-life`.

**Pass 1, at `d672353`:**
- All nine questions were answered.
- 17 gaps were found and fixed in `6a56b9e`. The main ones:
  - 365-day runs that a clone cannot see;
  - counts that disagreed between files;
  - stale pointers in CLAUDE.md;
  - sources that live only in chat.

**Pass 2, at `6a56b9e`:**
- All nine questions were answered.
- Verdict: "a new agent could resume the project correctly from these files alone, with the caveats".
- Two gaps were blocking, and the commit after `6a56b9e` fixed both:
  - stone was not registered as an owner decision; it is now OD-10, and EQ-09 is BLOCKED on it;
  - the unfinished 365-day runs had no rule for a later session; they now have an expected end time and a re-run rule.
- Minor gaps fixed at the same time: stale stone figures, SET-E's placement, whether SET-A needs authorization, PR #1's final state, numbering and counts.

**Re-check of pass 2, at `9a01e88`:**
- Both blocking gaps were confirmed fixed.
- The remaining minor wording (the titles and next actions of EQ-07, EQ-09 and EQ-10, and this section) was fixed in the commit after `9a01e88`.
- EQ-07's title is kept on purpose: it names the Build 14 failures the entry was opened for.

**Known limits that remain:**
- `wip/multiplayer` is not in a staging clone.
- A few early sources exist only in chat; their wording is copied into the register.
- The spec's inline open points beyond SJD-Q01..Q14 are noted here but have no entries of their own.
