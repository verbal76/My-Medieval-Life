# Simulation-gate baseline attribution: the 33 findings of gate 42788012219 on `fbfd6ad`

Recorded 2026-11-10/11 (worker, read-only investigation under owner directive B25-BASELINE-REVIEW-01,
`docs/directives/2026-11-10_no_auto_merge_baseline_review.md` on `wip/requirements-control`). No game code, data, test,
baseline or gate was changed; `sim_gate.py --write` was never run; `docs/release/sim_baseline.json` was only read. This
document is the only file committed.

Sections 1 to 3 are **measured facts**. Sections 4 to 6 are **interpretation**: classifications and recommendations
for the owner to decide on. Nothing here accepts a baseline.

## 1. Method

**What was measured.** The gate's own comparison: `game/tests/economy_sim.gd` with
`--days 30 --seed S --every 10 --out ...`, seeds 1 and 2 in parallel processes, each with its own `XDG_DATA_HOME` and
`TMPDIR` (the `run_seed` command of `tools/sim_gate.py`), Godot 4.7 headless (`/root/godot-bin/godot`), after
`godot --headless --path game --import` at each commit. The eight values were taken from the day-10 and day-30 samples by
a copy of `sim_gate.summarise()` (alive, households, currency, treasury, fingerprint, animals, deposits, item_ledger;
leaks recorded as well). Runs were unrecorded, as `sim_gate.py` runs them. The CI gate's `eq_s1` and `eq_s2` are recorded
runs. At `fbfd6ad` the two are identical (section 2). Commits were checked out detached in a worktree whose tracked files
were clean before every checkout. Scripts and raw results were kept in the session scratch directory.

**Which baseline.** The comparison is against the baseline the gate uses: `docs/release/sim_baseline.json` as it stands
at `fbfd6ad`. It was introduced by `49cddbd` (2026-11-03, "Re-record the sim baseline for seed travelers"), and its
`commit` field is `df67e8e`. The brief said to copy the file *from* `df67e8e`. At `df67e8e` that file still holds the
older `8d31017` baseline (seed 1 day 10: currency 3382, treasury 155), which is not what the gate compares against. The
gate's baseline (currency 3314, treasury 130) is the one recorded from `df67e8e`. The same numbers were used for every
commit. `49cddbd` is not on the first-parent line, and later commits did not change the file.

**How the change points were found.** The 157 first-parent commits `df67e8e..fbfd6ad` were indexed #1 to #157
(`df67e8e` is #0). Merges were treated as single steps.
1. Full 30-day runs at coarse points (#0, #27, #32, #34, #88, #109, #132, #157), then at the merges inside each segment
   whose endpoints differed.
2. Within the 2026-11-04 to 2026-11-06 segments (#34 to #109), a 10-day scan of every commit that changed
   `game/scripts`, `game/data`, `economy_sim.gd` or `project.godot`. Commits that changed none of these were skipped,
   including docs-only, CI-only and test-only commits. A 10-day run reproduces the 30-day run's day-10 sample exactly:
   27 commits were measured both ways, both seeds, with identical values.
3. A 30-day run on each side of every change point found by the scan, plus 30-day runs bracketing the stretches that
   showed no day-10 change. This caught three changes that show only at day 30 (#64 on seed 2, #67, #71).
4. Two merges were split along their own side branch, measured against the side branch's merge-base: #133 (`229f76e`,
   PRs #16 and #17) and #151 (`acc24b2`, audit-sim2).
5. Equivalence: #33 `9f191f2` and #34 `65f2665` have byte-identical `game/` trees, so #34's measurement stands for #33.

**Measurement totals.** 89 runs, 66 distinct commits.

**Determinism checks.**
- `df67e8e` reproduces the baseline exactly (0 differences in all 32 values).
- The local `fbfd6ad` run equals the CI gate run (0 differences).
- 27 commits were measured twice, in separate processes, and agreed every time.
- `af8a190` and `b4a302b` were each repeated a third time because of the anomaly in section 4, item 16, and agreed.
- No commit gave a run-to-run difference: there is no sign of non-determinism.

**Limits.**
- Only seeds 1 and 2, days 10 and 30, were measured.
- A commit with no effect on those eight values can still change other days, other seeds or recorded runs.
- Commits inside a bracket whose two 30-day endpoints are equal were not measured one by one. A change cancelled by a
  later change inside the same bracket cannot be ruled out (not seen anywhere).
- #93 (`04fa910`, wiki text only) lies inside the #92 to #94 bracket and was not measured on its own. The bracket's change
  is attributed to #94.

## 2. Endpoint measurements (facts)

| Seed, day | alive | households | currency | treasury | fingerprint |
|---|---|---|---|---|---|
| s1 d10 at `df67e8e` (measured) | 107 | 25 | 3314 | 130 | c7ea116c… |
| s1 d10 at `fbfd6ad` (measured) | 110 | 26 | 2957 | 70 | 6355b652… |
| s1 d30 at `df67e8e` | 112 | 25 | 4013 | 323 | 34cc2e53… |
| s1 d30 at `fbfd6ad` | 119 | 26 | 3295 | 37 | 867c8f45… |
| s2 d10 at `df67e8e` | 109 | 25 | 3034 | 190 | 0735823b… |
| s2 d10 at `fbfd6ad` | 107 | 26 | 2973 | 107 | 10dc3130… |
| s2 d30 at `df67e8e` | 118 | 25 | 3597 | 184 | e4ed695e… |
| s2 d30 at `fbfd6ad` | 112 | 26 | 3760 | 185 | 0d9a4895… |

- `df67e8e`: equal to `sim_baseline.json` in all 32 values.
- `fbfd6ad`: equal to the gate's actual values (CI `eq_s1` and `eq_s2` `sim.json`) in all 32 values.
- Conservation: currency leak 0 and no item leaks in every one of the 236 samples taken (all commits, both seeds).
- Script errors: one commit, #31 `e0b2b1a`, logged 7 `SCRIPT ERROR` lines per seed, exit code 0. The next commit, #32
  `7951dee`, logged none and gave identical values (section 4, item 3).
- Starting world: the day-0 households count is 25 up to #29 and 26 from #30. At day 0 (and on day 1, when the
  households table is first written) household 25 has 6 members: 0 adults, 0 children, 0 elders, so the 6 bandits.
  The bandit count (6) is the same before and after.

## 3. Change points (facts: commit, date, subject, values moved)

Twenty-one change points. Values are alive / households / currency / treasury as before → after. The hashed values
(fingerprint, animals, deposits, item_ledger) moved at every listed seed and day except where the table says otherwise.
The full 30-day measurement table is in the appendix.

| # | Commit, date | Subject (short) | Values that moved (before → after) |
|---|---|---|---|
| 29 | `953e750` 11-04 | Merge wip/b25r1-water: overworld generation 4 region layout, settlements along streets, rivers, fords, travel planning (B25R1-018) | s1 d10 alive 107→109, cur 3314→3243, tre 130→152; s1 d30 cur 4013→3943, tre 323→91; s2 d10 cur 3034→3113, tre 190→127; s2 d30 alive 118→114, cur 3597→3594, tre 184→164. Seed 2's day-0 fingerprint changes (new world). |
| 30 | `1d024dc` 11-04 | Merge wip/b25r1-region: towns, civic buildings, plus the homestead branch's band move (`bf20dc9`, B25R1-014) | **households 25→26 at every checkpoint, both seeds**; s1 d10 alive 109→105, cur 3243→3253, tre 152→120; s1 d30 cur 3943→4281, tre 91→278; s2 d10 alive 109→108, cur 3113→3020, tre 127→108; s2 d30 alive 114→117, cur 3594→3672, tre 164→286 |
| 31 | `e0b2b1a` 11-04 | Merge wip/b25r1-settle: hamlets, trips carried by walkers, SettlementPeople residents (B25R1-018, B25R1-019) | s1 d10 alive 105→110, cur 3253→3233, tre 120→86; s1 d30 alive 112→120, cur 4281→4854, tre 278→445; s2 d10 alive 108→104, cur 3020→3071, tre 108→143; s2 d30 alive 117→106, cur 3672→4000, tre 286→502 |
| 33 | `9f191f2` 11-04 (measured as `65f2665`, same `game/` tree) | Merge wip/b25r1-presence: fixed world tick, animals move everywhere (B25R1-019, B25R1-020) | s1 d10 alive 110→109, cur 3233→3223, tre 86→95; s1 d30 cur 4854→4539, tre 445→363; s2 d10 alive 104→109, cur 3071→3104, tre 143→94; s2 d30 alive 106→117, cur 4000→4064, tre 502→285 |
| 44 | `0c1aeb3` 11-04 | Keep the region's roads off every settlement's ground; pave busy stretches by town pairs (B25R1-018, Q1) | s1 d10 alive 109→108, cur 3223→3267, tre 95→118; s1 d30 alive 120→118, cur 4539→4322, tre 363→32; s2 d10 alive 109→108, cur 3104→3127, tre 94→86; s2 d30 alive 117→113, cur 4064→3888, tre 285→260 |
| 57 | `a995397` 11-05 | Merge wip/b25r1-axe: a villager keeps its work tool when courting (treasury axe loop) | s1 d10 alive 108→111, cur 3267→3286, tre 118→151; s1 d30 alive 118→114, cur 4322→4634, **tre 32→414**; s2 d10 fingerprint only; s2 d30 alive 113→112, cur 3888→3924, tre 260→307 |
| 64 | `edf1854` 11-05 | Merge wip/b25r1-econ1: founding without the full-bench gate (P1), household first tool (P2), unused stock sold (P3) | s1 d10 alive 111→109, cur 3286→3228, tre 151→138; s1 d30 alive 114→110, cur 4634→4780, tre 414→531; s2 day 10 unchanged; s2 d30 alive 112→114, tre 307→360 (fingerprint, animals and item_ledger; currency and deposits unchanged) |
| 67 | `c3d9d91` 11-05 | Merge wip/b25r1-econ2: ore on consignment (P4), land cleared by labour (P5) | day 10 unchanged on both seeds; s1 d30 alive 110→116, cur 4780→4823, tre 531→434; s2 d30 alive 114→104, cur 3924→3862, tre 360→380 |
| 71 | `e097fab` 11-05 | Merge wip/b25r1-econ3: other traders carry a traderless place's ore on consignment (owner question 27) | s1 d30 only: alive 116→115, cur 4823→4813, tre 434→433 (fingerprint, animals and item_ledger; deposits unchanged) |
| 72 | `81c102a` 11-05 | Merge wip/b25r1-visual: overworld generation 6 (rivers through settlements, castle way, dead-end roads) | s1 d10 alive 109→107, cur 3228→3093, tre 138→95; s1 d30 alive 115→120, cur 4813→4458, tre 433→246; s2 d10 alive 108→109, cur 3127→3171, tre 86→99; s2 d30 alive 104→118, cur 3862→3886, tre 380→199 |
| 79 | `fc35629` 11-05 | Merge wip/b25r1-wood: overworld generation 7 (Wood Perilous ridge, castle way on every seed) | s1 d10 alive 107→111, cur 3093→3148, tre 95→96; s1 d30 alive 120→117, cur 4458→4320, tre 246→262; s2 d10 alive 109→110, cur 3171→2975, tre 99→97; s2 d30 alive 118→117, cur 3886→3955, tre 199→306 |
| 84 | `a9e9f6e` 11-05 | Merge wip/b25r1-econ5: owner decisions 32 and 33 (neighbours collect spare ore; founding traders keep the 80 reserve) | s1 d10 alive 111→108, cur 3148→3036, tre 96→62; s1 d30 cur 4320→3670, tre 262→112; s2 d10 cur 2975→2960, tre 97→108; s2 d30 alive 117→113, cur 3955→3694, tre 306→169 |
| 89 | `856d946` 11-06 | WIP (B25R2): generation 8 road crossings over the water as drawn; bridge_validity_test | s1 d10 alive 108→110, cur 3036→3003, tre 62→67; s1 d30 alive 117→118, cur 3670→3478, tre 112→235; s2 d10 alive 110→105, cur 2960→3073, tre 108→107; s2 d30 alive 113→112, cur 3694→3733, tre 169→126 |
| 90 | `8d71894` 11-06 | WIP (B25R2): road nodes out of the water (generation 8); walkable travel legs; stuck = no approach | seed 1 only: d10 alive 110→106, cur 3003→2977, tre 67→86; d30 alive 118→114, cur 3478→3151, tre 235→67 |
| 94 | `c0be482` 11-06 | B25R2: pad focus fixes; fords walkable in the travel checks; generation 8 roads reach a wet end by a short stub | s1 d10 alive 106→108, cur 2977→2979, tre 86→90; s1 d30 alive 114→115, cur 3151→3650, tre 67→165; s2 d10 alive 105→106, cur 3073→2975, tre 107→113; s2 d30 alive 112→114, cur 3733→3514, tre 126→247 |
| 96 | `b4a302b` 11-06 | Generation 8: drop the half-tile second search for a dry way ("it changed no road on seeds 1 and 2") | seed 2 only: d10 alive 106→108, cur 2975→2896, tre 113→96; d30 alive 114→111, cur 3514→3556, tre 247→221 |
| 97 | `6ca3b1f` 11-06 | Generation 8: the roads see the water as the settlements draw it, so a dry way round is found | seed 1 only: d10 alive 108→111, cur 2979→2945, tre 90→65; d30 alive 115→119, cur 3650→3581, tre 165→139 |
| 99 | `0112fd1` 11-06 | Generation 8 bridges: roads cross where the water parts the land; generation kept fast | s1 d10 alive 111→110, cur 2945→2957, tre 65→70; s1 d30 alive 119→116, cur 3581→3366, tre 139→161; s2 d10 alive 108→110, cur 2896→3055, tre 96→113; s2 d30 alive 111→119, cur 3556→3667, tre 221→209 |
| 102 | `6893763` 11-06 | Generation 8: no road loops over the water on any of the 8 test seeds | seed 2 only: d10 alive 110→107, cur 3055→2965, tre 113→95; d30 alive 119→118, cur 3667→3775, tre 209→274 |
| 133 | `229f76e` 11-09, via **`4d7cc77`** (PR #17, LIFE-04) | Merge LIFE-03 and LIFE-04 | seed 2 only: d10 cur 2965→2973, tre 95→107; d30 alive 118→112, cur 3775→3760, tre 274→185 |
| 151 | `acc24b2` 11-10, via **`aca3a8b`** (NPC-02) | Merge wip/b25-audit-sim2 | seed 1 day 30 only: alive 116→119, cur 3366→3295, tre 161→37 |

**Inside the split merges.**
- #133: the side branch's base `0d252b4` and PR #16 (`d67fa11`, LIFE-03) give #132's values exactly. PR #17 (`4d7cc77`,
  LIFE-04) gives #133's values exactly. `46d934c` (LIFE-03 level 2) and `494af9a` (LIFE-04 Q8) change nothing further.
- #151: the side branch's base `448fc0b` and `add5061` (REG-02 journey on emigration) give #150's values. `aca3a8b`
  (NPC-02) gives #151's values. `1497a5c` (JUS-02) changes nothing further.

**No change to the eight values (seeds 1 and 2, days 10 and 30).** Every other commit on the line, including these that
changed game code:
- Recorder and B25R1 work: the flight-recorder and B25R1 commits #1 to #28; #32 (`7951dee`, homestead merge, same
  values as #31); #47 (`2677ea7`, REC-D3: unrecorded runs unchanged, as intended).
- Generation 5: #61 (`6c25674`).
- Network-only commits: #65, #66, #70, #74, #81, #111, #117, #128, #129, #146, #147, #154, #156.
- View and save-store commits: #59 (OverworldView cache), #60 (SaveStore).
- UI, aerial-map and wiki commits: #73, #75, #76, #104, #110, #112, #113, #132.
- 2026-11-08 audit corrections: PRs #6 to #15 (#121 to #130).
- 2026-11-09 merges: PROP-06 (#134), JUS-04 and REG-07 (#135), the audit backlog (#136), MP-05 (#138 to #140).
- 2026-11-09 and 2026-11-10 fixes: INV-01, BIZ-08, TRD-01, SAV-03 (#142 to #145); EMP-03 (#149); audit-sim1 (#150);
  KI-09 (#153); MP-03 (#154).
- TRD-05 Living Economy comment change (#155).
- Simulation batches 3 and 4 (#157 `fbfd6ad` itself: REG-06, NPC-03, SAV-03 reservations, self-trade payer,
  B25-HH-BIZFOOD-D1, bought-meal price).

## 4. Classification of each change point (interpretation)

The four classes, with their counts:
- **(a) EXPECTED**: an owner-approved behaviour change whose effect is the intended one. 10 change points.
- **(b) EXPECTED ENGINEERING**: a defect fix whose effect follows from the fix. 10 change points.
- **(c) CONCERNING**: a change that should not have moved these values, or moved them against its stated intent.
  1 change point.
- **(d) UNEXPLAINED**: no cause found. 0 change points.

**How to read the size and direction of a movement.** Every listed change alters the order or content of villagers'
decisions in the first days. Once two runs diverge, the whole 30-day trajectory differs: every value moves, and how far
and in which direction is mostly the chaotic consequence of the divergence, not the direct effect of the change. A
movement is therefore judged on whether the change *should* alter the simulation of seeds 1 and 2 at all. Its sign is
used only where the change predicts one (items 2 and 6).

1. **#29 `953e750`: (a)**, B25R1-018 (owner 2026-11-03, regional world reconstruction). Overworld generation 4 lays the
   region out anew and places the settlements along streets, a home per household. A different world for seed 2 (its
   day-0 fingerprint changes) and different roads and travel times for both seeds are the intended consequence. The
   overnight report (`docs/handoffs/OVERNIGHT_2026-11-04.md`, `3c53431`) listed these differences as expected from the
   merged world.
2. **#30 `1d024dc`: (a)**, B25R1-014 and B25R1-Q2 option (a), owner 2026-11-03. **The extra household:**
   - What it is: the outlaw band's own household (6 members, all bandits, no adults, children or elders; index 25, the
     last). `Wilds.found_band` creates it at setup on a concealed outlaw claim in the open country (`bf20dc9` "The band
     moves to the wild", on the region branch, merged by `1d024dc`).
   - Before: the 6 bandits counted under the 25 village households (a camp at the village).
   - Why it was expected: this was registered in advance in
     `docs/release/SIM_BASELINE_CHANGES_B25R1_HOMESTEAD.md` item 1 ("From the founding the six bandits are a household
     on a concealed outlaw claim").
   - The other values move with the band's dawn raids and travel; the same note listed robberies, bandit deaths and
     coins carried out.
3. **#31 `e0b2b1a`: (a)**, B25R1-018 and B25R1-019: hamlets, trade carried by walkers on the roads, live residents.
   - Side fact: this merge state logged 7 script errors per seed (exit 0). The merge note says the dependency
     (`Wilds.add_well`'s count argument) arrives with the next merge.
   - `7951dee` (#32) fixes it with identical values, so the errors did not reach the final code.
   - That a script-erroring intermediate state gives the same numbers as the fixed one suggests the erroring calls did
     not alter the eight values in 30 days. This was not traced further.
4. **#33 `9f191f2`: (a)**, B25R1-019 and B25R1-020 (owner 2026-11-03). Every animal now moves on the world's tick,
   everywhere. Before, only animals near the player did. This removes an observation effect and changes hunting, hence
   food, coins and lives. Registered in advance in `docs/release/SIM_BASELINE_CHANGES_B25R1_PRESENCE.md`.
5. **#44 `0c1aeb3`: (b)**, under B25R1-018 and B25R1-Q1. Fixes overlapping settlement grounds (Milton on Higham and
   others) and side roads through houses. Roads, and so travel, change on both seeds.
6. **#57 `a995397`: (b)**, the B25R1 axe defect (`8d05942`).
   - The defect: a woodcutter gave away its only axe at each dawn, and the manor re-equipped it from the treasury.
   - What the fix commit predicted for seed 1 at day 30: a treasury of 32 with the bug, not 323.
   - Measured: seed 1 day-30 treasury 32 → 414 across this merge. Direction and size match the prediction (the bug
     spent the treasury).
   - Test: od16_test `test_courting_gift_keeps_the_work_axe`.
7. **#64 `edf1854`: (a)**, B25-ECON-P1, P2 and P3. Owner approved 2026-11-05 (B25R1 owner questions 20 to 26):
   founding without the full-bench gate, a household's first tool, elders' unused stock sold.
8. **#67 `c3d9d91`: (a)**, B25-ECON-P4 and P5 (owner 2026-11-05): ore on consignment, land cleared by labour. It shows
   only after day 10, consistent with consignment trips and field clearing taking days.
9. **#71 `e097fab`: (a)**, owner question 27 (recorded in B25-ECON-P4's history): other traders carry a traderless
   place's ore. A small seed-1 day-30 change only.
10. **#72 `81c102a`: (b)**, generation 6, the B25R1 flyover repair under B25R1-018. Rivers were erased at settlements;
    the castle had no way; streets ended in grass. A generation-5 world is refused (B25R1-Q5).
11. **#79 `fc35629`: (a)**, owner decision, question 29 (`docs/DECISIONS.md` 2026-11-05: the Wood Perilous redrawn as a
    ridge, generation 7).
12. **#84 `a9e9f6e`: (a)**, owner decisions 32 and 33 (2026-11-05, recorded in B25-ECON-P4): neighbours collect spare
    ore after the own trader's claim; founding traders keep the 80-coin reserve.
13. to 19. **The generation-8 series: (b) for #89, #90, #94, #97, #99 and #102.**
    - Authority: owner directive 2026-11-06, items 2 (riverbank autotravel) and 6 (looping bridge geometry), in
      `docs/directives/2026-11-06_my_folklore_pc_playtest_repair.md`; `docs/DECISIONS.md` 2026-11-06 "Overworld
      generation 8" (engineering corrections; a generation-7 world keeps its roads).
    - Each commit changes where roads cross water, or how travel legs and fords are walked, so travellers' routes and
      timings change.
    - #94 also contains controller-focus UI changes. Its simulation effect comes from "fords walkable in the travel
      checks" and "generation 8 roads reach a wet end by a short stub".
16. **#96 `b4a302b`: (c) CONCERNING (a record defect, not necessarily a game defect).**
    - The claim: the subject says the removed fallback search "changed no road on seeds 1 and 2".
    - Measured, simulation: it changes seed 2's simulation at days 10 and 30. Deterministic: repeated in a third
      process with identical values; the previous commit was also repeated.
    - Measured, roads: a read-only probe (every site-to-site `Overworld.site_route` for the 15 sites, hashed) shows the
      routes changed on **both** seeds. Seed 1: 120708 route cells before and after, but different route hashes, for
      example ashcombe-brookhurst. Seed 2: 124062 → 123802 cells, many routes changed. Probe results were identical when
      repeated.
    - Conclusion: the commit's stated "no road changed" is contradicted by measurement. The later generation-8 commits
      (#97, #99, #102) changed the same code again. The final generation-8 roads were checked by `bridge_validity_test`
      (8 seeds, no loops, per `6893763`) but not compared with the commit's claim.
20. **#133 via `4d7cc77`: (a)**, B25-AUD-LIFE-04 (owner 2026-11-08: "Widows and widowers may remarry; previous marriage
    history kept").
    - The audit item (MML-LIFE-04) said widowed NPCs kept their dead partner's id, so the singles selection in
      `Relations._villagers_court` and `can_court` treated them as taken.
    - `Life.free_to_partner` now admits them. That only seed 2 moves is consistent with a widowed villager entering
      seed 2's courting pool within 10 days.
    - Not verified: which villager, and whether a remarriage actually took place. That was not traced.
    - A side observation, not investigated: `Life.has_partner` also treats a partner who is `away` (emigrated,
      `alive == false`) as no partner, so such a spouse's partner would now be free to court as well. Whether that case
      can arise is for the owner or lead to judge.
21. **#151 via `aca3a8b`: (b)**, audit MML-NPC-02: a courtship gift no longer gives away goods held under a Living
    Economy claim or contract. The commit itself says it "changes the simulation (villagers' gifts)". Test:
    `npc02_gift_claims_test`, 3 failures before and 8/0 after. Only seed 1 day 30 moves.

## 5. The 33 findings mapped to their change points

**Finding 1** (the note "baseline not applicable: no overworld_gen or save_version recorded; this code is generation 8,
save 23"). This is a fact about the baseline file, not a behaviour change. The baseline predates TEST-GOV-01's
`versions` field. Since it was recorded, the code went from generation 4 (#29) through generations 5, 6, 7 (#61, #72,
#79) to generation 8 (#89 onward); the save-version changes were not measured. **Class:** not a difference. Its premise,
"another generation", is confirmed by #29, #72, #79 and #89 to #102.

**Findings 2 to 33** (difference = baseline → `fbfd6ad`; change points that moved that value, all measured):

| Seed, day | Value | Difference | Change points that moved it | Classes involved |
|---|---|---|---|---|
| s1 d10 | alive | 107 → 110 | 29 30 31 33 44 57 64 72 79 84 89 90 94 97 99 | a, b |
| s1 d10 | animals | (hash) | same 15 | a, b |
| s1 d10 | currency | 3314 → 2957 | same 15 | a, b |
| s1 d10 | deposits | (hash) | same 15 | a, b |
| s1 d10 | fingerprint | c7ea116c → 6355b652 | same 15 | a, b |
| s1 d10 | households | 25 → 26 | **30 only** | a |
| s1 d10 | item_ledger | (hash) | same 15 | a, b |
| s1 d10 | treasury | 130 → 70 | same 15 | a, b |
| s1 d30 | alive | 112 → 119 | 31 44 57 64 67 71 72 79 89 90 94 97 99 151 | a, b |
| s1 d30 | animals | (hash) | 29 30 31 33 44 57 64 67 71 72 79 84 89 90 94 97 99 151 | a, b |
| s1 d30 | currency | 4013 → 3295 | same 18 as animals | a, b |
| s1 d30 | deposits | (hash) | the same except 71 (17) | a, b |
| s1 d30 | fingerprint | 34cc2e53 → 867c8f45 | same 18 as animals | a, b |
| s1 d30 | households | 25 → 26 | **30 only** | a |
| s1 d30 | item_ledger | (hash) | same 18 as animals | a, b |
| s1 d30 | treasury | 323 → 37 | same 18 as animals | a, b |
| s2 d10 | alive | 109 → 107 | 30 31 33 44 72 79 89 94 96 99 102 | a, b, **c (96)** |
| s2 d10 | animals | (hash) | 29 30 31 33 44 72 79 84 89 94 96 99 102 133 | a, b, **c (96)** |
| s2 d10 | currency | 3034 → 2973 | same 14 as animals | a, b, **c (96)** |
| s2 d10 | deposits | (hash) | same 14 as animals | a, b, **c (96)** |
| s2 d10 | fingerprint | 0735823b → 10dc3130 | the 14 plus 57 | a, b, **c (96)** |
| s2 d10 | households | 25 → 26 | **30 only** | a |
| s2 d10 | item_ledger | (hash) | same 14 as animals | a, b, **c (96)** |
| s2 d10 | treasury | 190 → 107 | same 14 as animals | a, b, **c (96)** |
| s2 d30 | alive | 118 → 112 | 29 30 31 33 44 57 64 67 72 79 84 89 94 96 99 102 133 | a, b, **c (96)** |
| s2 d30 | animals | (hash) | same 17 | a, b, **c (96)** |
| s2 d30 | currency | 3597 → 3760 | the same except 64 (16) | a, b, **c (96)** |
| s2 d30 | deposits | (hash) | the same except 64 (16) | a, b, **c (96)** |
| s2 d30 | fingerprint | e4ed695e → 0d9a4895 | same 17 | a, b, **c (96)** |
| s2 d30 | households | 25 → 26 | **30 only** | a |
| s2 d30 | item_ledger | (hash) | same 17 | a, b, **c (96)** |
| s2 d30 | treasury | 184 → 185 | same 17 | a, b, **c (96)** |

Notes on the table:
- "#33" is `9f191f2`, measured as `65f2665`, whose `game/` tree is identical.
- No finding is explained by a single change point except the four households findings.
- Seed 2's treasury at day 30 nearly returns to the baseline (184 → 185) after 17 movements, some as large as ±200.
  This is coincidence, not stability.

## 6. Recommendations (interpretation; owner decides)

**Group H: households, 4 findings (s1/s2 × d10/d30). Recommend: accept.**
- Approval: B25R1-014 and B25R1-Q2 option (a), owner 2026-11-03.
- Cause: the extra household is the outlaw band's own household, the six bandits on their claim, created at setup.
- This was predicted in `SIM_BASELINE_CHANGES_B25R1_HOMESTEAD.md` before the merge.
- No other commit touches the count.

**Group V: 28 value findings** (alive, currency, treasury and the four hashes, at s1/s2 × d10/d30).
**Recommend: accept, with one item investigated first.**
- They are the combined result of 21 change points:
  - ten owner-approved changes: B25R1-018, B25R1-014/Q2a, B25R1-019/020, B25-ECON-P1 to P5, owner questions 27, 29,
    32 and 33, B25-AUD-LIFE-04;
  - ten engineering corrections: roads off settlement grounds, the axe-gift loop, generation 6, the generation-8
    playtest repairs, NPC-02;
  - one record defect (#96).
- No change point is unexplained.
- No commit that was network-only, UI-only, test-only, wiki-only or comment-only moved any value. That was checked
  for every such commit on the line, including TRD-05's "Living Economy comments" (#155).
- Conservation held throughout: 0 currency leak and no item leaks in 236 samples.
- Determinism held throughout: 27 commits repeated, no divergence.
- **Investigate before accepting** (generation 8, #96 `b4a302b`): confirm that the final generation-8 road network on
  seeds 1 and 2 is the intended one, and correct the record of `b4a302b`'s "changed no road on seeds 1 and 2". It
  changed routes on both seeds and seed 2's simulation.
  - Suggested evidence: a road-cell diff of generation 8 at `6893763` against the generation-7 roads for seeds 1 and 2,
    and `bridge_validity_test` on them.
  - This does not by itself indicate a game defect: the commit removed a fallback search, and the later commits
    reworked the same stage.
- Optional checks, not needed for attribution:
  - #133, LIFE-04: confirm which seed-2 villager becomes eligible (expected: a widowed villager entering the courting
    pool, MML-LIFE-04).
  - #133, LIFE-04: decide whether a partner who emigrated (`away`, `alive == false`) should free the spouse left behind,
    which `free_to_partner` now allows.
  - #31: confirm that the 7 script errors at that intermediate merge (fixed at #32 with identical values) were
    harmless.

**Correct (suspected defect): none.** No change point was found whose effect contradicts an approved rule.

**Not covered by this attribution:**
- The gate's other comparisons and findings (recorder neutrality, determinism pairs, the scenarios).
- Seeds other than 1 and 2, days other than 10 and 30.
- Whether the 365-day campaign outcomes are acceptable.

### Owner decisions

1. **Households (4 findings):** accept the band's own household (B25R1-014 / Q2a) as the new behaviour?
2. **The 28 value findings:** accept them as the combined effect of the 20 approved changes and engineering corrections
   (section 4), subject to item 3?
3. **Generation 8, `b4a302b`:** have the lead verify the final generation-8 roads on seeds 1 and 2 and correct the
   commit's recorded claim before the baseline is accepted, or accept the generation-8 series on the strength of
   `bridge_validity_test` as it stands?
4. **LIFE-04 scope (optional):** should a villager whose partner emigrated (not died) be free to court again? The current
   code allows it. Whether it arises in play was not measured.
5. **New baseline:** if 1 to 3 are accepted, authorize re-recording the baseline on the accepted commit with the
   `versions` field, which removes finding 1. This document does not do it.

## Appendix: every 30-day measurement (alive / households / currency / treasury)

| # | commit | s1 d10 | s1 d30 | s2 d10 | s2 d30 |
|---|---|---|---|---|---|
| 0 | `df67e8e` | 107 / 25 / 3314 / 130 | 112 / 25 / 4013 / 323 | 109 / 25 / 3034 / 190 | 118 / 25 / 3597 / 184 |
| 27 | `eb04908` | 107 / 25 / 3314 / 130 | 112 / 25 / 4013 / 323 | 109 / 25 / 3034 / 190 | 118 / 25 / 3597 / 184 |
| 28 | `fee6521` | 107 / 25 / 3314 / 130 | 112 / 25 / 4013 / 323 | 109 / 25 / 3034 / 190 | 118 / 25 / 3597 / 184 |
| 29 | `953e750` | 109 / 25 / 3243 / 152 | 112 / 25 / 3943 / 91 | 109 / 25 / 3113 / 127 | 114 / 25 / 3594 / 164 |
| 30 | `1d024dc` | 105 / 26 / 3253 / 120 | 112 / 26 / 4281 / 278 | 108 / 26 / 3020 / 108 | 117 / 26 / 3672 / 286 |
| 31 | `e0b2b1a` | 110 / 26 / 3233 / 86 | 120 / 26 / 4854 / 445 | 104 / 26 / 3071 / 143 | 106 / 26 / 4000 / 502 |
| 32 | `7951dee` | 110 / 26 / 3233 / 86 | 120 / 26 / 4854 / 445 | 104 / 26 / 3071 / 143 | 106 / 26 / 4000 / 502 |
| 34 | `65f2665` | 109 / 26 / 3223 / 95 | 120 / 26 / 4539 / 363 | 109 / 26 / 3104 / 94 | 117 / 26 / 4064 / 285 |
| 43 | `aba1e7d` | 109 / 26 / 3223 / 95 | 120 / 26 / 4539 / 363 | 109 / 26 / 3104 / 94 | 117 / 26 / 4064 / 285 |
| 44 | `0c1aeb3` | 108 / 26 / 3267 / 118 | 118 / 26 / 4322 / 32 | 108 / 26 / 3127 / 86 | 113 / 26 / 3888 / 260 |
| 52 | `b4aa3a2` | 108 / 26 / 3267 / 118 | 118 / 26 / 4322 / 32 | 108 / 26 / 3127 / 86 | 113 / 26 / 3888 / 260 |
| 57 | `a995397` | 111 / 26 / 3286 / 151 | 114 / 26 / 4634 / 414 | 108 / 26 / 3127 / 86 | 112 / 26 / 3924 / 307 |
| 61 | `6c25674` | 111 / 26 / 3286 / 151 | 114 / 26 / 4634 / 414 | 108 / 26 / 3127 / 86 | 112 / 26 / 3924 / 307 |
| 64 | `edf1854` | 109 / 26 / 3228 / 138 | 110 / 26 / 4780 / 531 | 108 / 26 / 3127 / 86 | 114 / 26 / 3924 / 360 |
| 66 | `d678887` | 109 / 26 / 3228 / 138 | 110 / 26 / 4780 / 531 | 108 / 26 / 3127 / 86 | 114 / 26 / 3924 / 360 |
| 67 | `c3d9d91` | 109 / 26 / 3228 / 138 | 116 / 26 / 4823 / 434 | 108 / 26 / 3127 / 86 | 104 / 26 / 3862 / 380 |
| 70 | `9871099` | 109 / 26 / 3228 / 138 | 116 / 26 / 4823 / 434 | 108 / 26 / 3127 / 86 | 104 / 26 / 3862 / 380 |
| 71 | `e097fab` | 109 / 26 / 3228 / 138 | 115 / 26 / 4813 / 433 | 108 / 26 / 3127 / 86 | 104 / 26 / 3862 / 380 |
| 72 | `81c102a` | 107 / 26 / 3093 / 95 | 120 / 26 / 4458 / 246 | 109 / 26 / 3171 / 99 | 118 / 26 / 3886 / 199 |
| 77 | `9dabee7` | 107 / 26 / 3093 / 95 | 120 / 26 / 4458 / 246 | 109 / 26 / 3171 / 99 | 118 / 26 / 3886 / 199 |
| 79 | `fc35629` | 111 / 26 / 3148 / 96 | 117 / 26 / 4320 / 262 | 110 / 26 / 2975 / 97 | 117 / 26 / 3955 / 306 |
| 83 | `fb64eab` | 111 / 26 / 3148 / 96 | 117 / 26 / 4320 / 262 | 110 / 26 / 2975 / 97 | 117 / 26 / 3955 / 306 |
| 84 | `a9e9f6e` | 108 / 26 / 3036 / 62 | 117 / 26 / 3670 / 112 | 110 / 26 / 2960 / 108 | 113 / 26 / 3694 / 169 |
| 88 | `20e579e` | 108 / 26 / 3036 / 62 | 117 / 26 / 3670 / 112 | 110 / 26 / 2960 / 108 | 113 / 26 / 3694 / 169 |
| 89 | `856d946` | 110 / 26 / 3003 / 67 | 118 / 26 / 3478 / 235 | 105 / 26 / 3073 / 107 | 112 / 26 / 3733 / 126 |
| 90 | `8d71894` | 106 / 26 / 2977 / 86 | 114 / 26 / 3151 / 67 | 105 / 26 / 3073 / 107 | 112 / 26 / 3733 / 126 |
| 92 | `82cb449` | 106 / 26 / 2977 / 86 | 114 / 26 / 3151 / 67 | 105 / 26 / 3073 / 107 | 112 / 26 / 3733 / 126 |
| 94 | `c0be482` | 108 / 26 / 2979 / 90 | 115 / 26 / 3650 / 165 | 106 / 26 / 2975 / 113 | 114 / 26 / 3514 / 247 |
| 95 | `af8a190` | 108 / 26 / 2979 / 90 | 115 / 26 / 3650 / 165 | 106 / 26 / 2975 / 113 | 114 / 26 / 3514 / 247 |
| 96 | `b4a302b` | 108 / 26 / 2979 / 90 | 115 / 26 / 3650 / 165 | 108 / 26 / 2896 / 96 | 111 / 26 / 3556 / 221 |
| 97 | `6ca3b1f` | 111 / 26 / 2945 / 65 | 119 / 26 / 3581 / 139 | 108 / 26 / 2896 / 96 | 111 / 26 / 3556 / 221 |
| 98 | `18e4c41` | 111 / 26 / 2945 / 65 | 119 / 26 / 3581 / 139 | 108 / 26 / 2896 / 96 | 111 / 26 / 3556 / 221 |
| 99 | `0112fd1` | 110 / 26 / 2957 / 70 | 116 / 26 / 3366 / 161 | 110 / 26 / 3055 / 113 | 119 / 26 / 3667 / 209 |
| 101 | `cb5e323` | 110 / 26 / 2957 / 70 | 116 / 26 / 3366 / 161 | 110 / 26 / 3055 / 113 | 119 / 26 / 3667 / 209 |
| 102 | `6893763` | 110 / 26 / 2957 / 70 | 116 / 26 / 3366 / 161 | 107 / 26 / 2965 / 95 | 118 / 26 / 3775 / 274 |
| 109 | `1f2ff4f` | 110 / 26 / 2957 / 70 | 116 / 26 / 3366 / 161 | 107 / 26 / 2965 / 95 | 118 / 26 / 3775 / 274 |
| 132 | `f0a854c` | 110 / 26 / 2957 / 70 | 116 / 26 / 3366 / 161 | 107 / 26 / 2965 / 95 | 118 / 26 / 3775 / 274 |
| 133 | `229f76e` | 110 / 26 / 2957 / 70 | 116 / 26 / 3366 / 161 | 107 / 26 / 2973 / 107 | 112 / 26 / 3760 / 185 |
| 134 | `96b071c` | 110 / 26 / 2957 / 70 | 116 / 26 / 3366 / 161 | 107 / 26 / 2973 / 107 | 112 / 26 / 3760 / 185 |
| 135 | `53a56d3` | 110 / 26 / 2957 / 70 | 116 / 26 / 3366 / 161 | 107 / 26 / 2973 / 107 | 112 / 26 / 3760 / 185 |
| 136 | `199809b` | 110 / 26 / 2957 / 70 | 116 / 26 / 3366 / 161 | 107 / 26 / 2973 / 107 | 112 / 26 / 3760 / 185 |
| 137 | `c9da5db` | 110 / 26 / 2957 / 70 | 116 / 26 / 3366 / 161 | 107 / 26 / 2973 / 107 | 112 / 26 / 3760 / 185 |
| 146 | `1b8bbd8` | 110 / 26 / 2957 / 70 | 116 / 26 / 3366 / 161 | 107 / 26 / 2973 / 107 | 112 / 26 / 3760 / 185 |
| 149 | `b3a1696` | 110 / 26 / 2957 / 70 | 116 / 26 / 3366 / 161 | 107 / 26 / 2973 / 107 | 112 / 26 / 3760 / 185 |
| 150 | `dd0ba5b` | 110 / 26 / 2957 / 70 | 116 / 26 / 3366 / 161 | 107 / 26 / 2973 / 107 | 112 / 26 / 3760 / 185 |
| 151 | `acc24b2` | 110 / 26 / 2957 / 70 | 119 / 26 / 3295 / 37 | 107 / 26 / 2973 / 107 | 112 / 26 / 3760 / 185 |
| 155 | `93bb304` | 110 / 26 / 2957 / 70 | 119 / 26 / 3295 / 37 | 107 / 26 / 2973 / 107 | 112 / 26 / 3760 / 185 |
| 157 | `fbfd6ad` | 110 / 26 / 2957 / 70 | 119 / 26 / 3295 / 37 | 107 / 26 / 2973 / 107 | 112 / 26 / 3760 / 185 |

Side-branch 30-day runs:
- #133's branch: `0d252b4` and `d67fa11` equal #132's values; `4d7cc77`, `46d934c` and `494af9a` equal #133's.
- #151's branch: `448fc0b` and `add5061` equal #150's; `aca3a8b` and `1497a5c` equal #151's.

Further 10-day scans: 41, 43, 45, 47, 51, 52, 60, 61, 66, 67, 70, 71, 77, 81, 83, 85, 86, 92, 95, 98, 101 and 106 each
equal their predecessor at day 10; the day-10 change points are the ones listed in section 3.
