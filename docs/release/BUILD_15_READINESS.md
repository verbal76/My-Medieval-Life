# Build 15 readiness (2026-10-20)

Build 15 is **simulation stabilization** (roadmap ROAD-01). This report checks it against:
- the ten completion conditions of OVN-01 section 4 (`docs/directives/2026-10-20_master_overnight_development_directive.md`);
- the closure standard of the owner's final mandate, OVN-02 section 5 (`docs/directives/2026-10-20_final_development_mandate.md`).

The mandate's founding principle (World Design Rule 022): **"A village is allowed to fail. The simulation is not."**
Build 15 closes on mechanical correctness and simulation integrity, not prosperity. Release authorization: OVN-01
section 9, REL-15-18 and OVN-02 section 7, as a **private draft**.

## Candidate

- **Game code:** the staging commit named in `BUILD_15_PACKET.md`, the one `release.yml` builds from. The year-long runs
  were on `3e326fd`; the commits after it are the order fixes (`afe087c`, the order lapse), documents and tools.
- **Contents:** single player only. Multiplayer stays on `wip/multiplayer` and is not in the build.
- **Changes since Build 14 (`7dbae4f`):** listed for testers in `BUILD_15_TESTER_NOTES.md`.

## The owner's closure standard (OVN-02 section 5)

| # | Question | Answer and evidence |
|---|---|---|
| 1 | Runs without release-blocking script errors | Yes. 0 script errors in every year-long run (the workflow fails on any). CI fails on script errors too |
| 2 | Required systems execute their functions | Yes. 25 Godot suites pass. The year runs exercise the whole world: houses, lofts, beds, households, trades, the manor, the caravan, bandits and guards |
| 3 | Essential NPC decisions follow approved rules | Yes. Defects found on the way were fixed with tests: EQ-17, EQ-10, EQ-18, the forge's order iron, the order lapse |
| 4 | Currency and resource accounting valid | Yes. Currency leak 0 and no item residuals in every year-long run, on both seeds |
| 5 | Save and load preserve essential state | Yes. A Build 14 save loads, plays, re-saves and reloads with coins unchanged. `conservation_test.gd` checks a round trip. Manor orders are saved |
| 6 | Construction, trade, employment, tools, households work when their prerequisites hold | Yes, by test. In the year runs 9 sites are finished on each seed, the manor equips workers, and job seekers buy tools |
| 7 | No unexplained resources or money | Yes. Ledger balanced; every coin from outside is counted in `coin_sources` |
| 8 | Test suites and release gates pass | 25 Godot suites, the Python tests and the requirement, interaction, resource, asset and material checks pass. The determinism gate passes against its recorded baseline |
| 9 | Noncritical issues documented | Yes: below, in `BUILD_15_TESTER_NOTES.md` and in `docs/SKIPPED_ITEMS.md` |
| 10 | Artifacts produced and validated | Recorded in `BUILD_15_PACKET.md` after `release.yml` runs |

## OVN-01 section 4

1. **Mandatory requirements implemented.** Build 15's scope (OVN-01 section 3), each item with its register entries:
   - housing completion: EQ-07, HOUSE-05, HOUSE-07;
   - persistent goals: HOUSE-01, HOUSE-03;
   - tool recovery: EQ-07, EQ-18, EQ-19;
   - bed sharing: HOUSE-08;
   - lofts: HOUSE-12;
   - house expansion: HOUSE-06, HOUSE-09, HOUSE-10;
   - ownership and occupancy: HOUSE-02, FAM-01, EQ-08, EQ-17;
   - regression tests: FR-07;
   - long simulations: INFRA-02, B14R-12;
   - saves: DVW-A2, DVW-A6, SAVE-00..09;
   - accounting: EQ-10, DVW-A4;
   - OD-16's answer: EQ-19..21.

   What remains open is waiting on the owner or on a device, not on engineering:
   - OD-15 (B7-008's buyer half);
   - B7-009 and B7-014 (the owner's choice of settings);
   - REC-003's policy confirmation;
   - DVW-A14 (a whole-life play-through);
   - the device queue.
2. **Integrated:** every system runs in the game itself. The small room was looked at in the game.
3. **Tests pass:** see the closure standard, row 8.
4. **Simulation and integrity checks:** the year-long runs below.
5. **No known game-breaking defects.**
6. **No unexplained leaks.**
7. **Save and load work.**
8. **Deferrals follow the policy:** one entry in `docs/SKIPPED_ITEMS.md`. It is WDR-010-C's feedback for blocked cart
   routes; carts have no collision, so no route is ever blocked.
9. **Committed and pushed:** every commit is on `staging/my-medieval-life`, the remote hash checked each time.
10. **Artifacts:** `BUILD_15_PACKET.md`.

## The year-long runs (365 days, no player)

Actions run 39408961143 on `3e326fd`, and local re-runs with the same fingerprints. The full record is
`LONG_RUN_SIMULATION.md`, "365 days on the OD-16 changes".

| Day 365 | Seed 1 | Seed 2 |
|---|---|---|
| Script errors / currency leak / item residuals | 0 / 0 / none | 0 / 0 / none |
| Alive (from 100) | 128 | 159 |
| Starvation deaths | 0 | 1 |
| Sites finished / started | 9 / 14 | 9 / 11 |
| Houses built | 6 | 8 |
| Smiths / woodcutters | 2 / 1 | 2 / 1 |
| Unemployed adults | 0 | 10 |
| Every wild species alive | yes | yes |

**Findings, classified under World Design Rule 022:**
- **Defects:** none open.
  - Fixed this cycle: EQ-17 (a baby with no home), EQ-10 (ledger residuals), EQ-18 (tools could not be bought; an
    abandoned trade left no post), the forge's use of order iron, and an unmet order holding its worker.
- **Legitimate outcomes,** recorded, not corrected:
  - smiths too poor to buy coal once the seams are worked out;
  - one woodcutter for much of the year;
  - nights without firewood;
  - 1 starvation death on seed 2;
  - seeds developing differently.
- **Future improvements:**
  - an advance earmarked for materials, or the manor buying an order's coal (EQ-19);
  - fuel and mining (Build 17);
  - the economy's long-term adaptation (Build 16).

## Known issues (in the tester notes)

**Economy:** coal, timber and firewood run short later in the year, the smith is often poor, and building can wait
months for planks. These are outcomes of finite resources and autonomous decisions, not breakage. Build 16 (adaptation)
and Build 17 (mining) build on them.

**Housing:** the small room fits beside only three original houses.

**Other:** no audio, and some stand-in art.

**Not verified:**
- No phone, tablet, controller or Windows PC was used.
- The Android build is signed with a throwaway key (`ANDROID_SIGNING.md`), so testers must uninstall Build 14 first.
  Exporting the save first keeps it.
