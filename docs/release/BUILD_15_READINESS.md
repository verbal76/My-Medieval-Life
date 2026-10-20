# Build 15 readiness (2026-10-20)

Build 15 is **simulation stabilization** (roadmap ROAD-01). This report checks it against the owner's completion
conditions in OVN-01 section 4 (`docs/directives/2026-10-20_master_overnight_development_directive.md`). Release
authorization: OVN-01 section 9 and REL-15-18. A build that meets every condition is released as a **private draft**.
"You do not need to wake me up merely to publish a build that meets these conditions."

> **Status: not qualified; blocked on owner decision OD-16.** The release-candidate run on `af60f94` exposed two
> tool-recovery defects (EQ-18). They are fixed and verified on `248e383`: smiths are kept all year, and job seekers
> can buy tools. But the producing trades still run out of coins, so no axes are made for months and timber and
> building stall. That is OD-16, an economy fundamental for the owner. The figures below are from `af60f94` and will be
> redone after OD-16 is implemented.

## Candidate

- **Game code:** `af60f94` on `staging/my-medieval-life`. Later commits change only documents, the register and
  Python tools. The packet (`BUILD_15_PACKET.md`) names the exact commit the release was built from.
- **Contents:** single player only. Multiplayer stays on `wip/multiplayer` and is not in the build.
- **Changes since Build 14 (`7dbae4f`):** listed for testers in `BUILD_15_TESTER_NOTES.md`.

## The ten conditions

### 1. Mandatory approved requirements are implemented

OVN-01 section 3 lists Build 15's scope. Each item and its register evidence:

| Scope item | Entries | State |
|---|---|---|
| Housing construction and completion | EQ-07, HOUSE-07, HOUSE-05 | Complete and verified. Houses are finished on both seeds in every year-long run since `59057ac` |
| Persistent housing goals | HOUSE-01, HOUSE-03 | Complete and verified |
| Economic recovery from missing work tools | EQ-07 (tool reserve, tool-less workers count as out of work, the smith buys imported ore, the caravan keeps needed tools) | Complete and verified |
| Bed sharing | HOUSE-08 | Complete and verified |
| Sleeping lofts | HOUSE-12 | Implemented and tested: a loft is built, used and saved (`housing_test.gd`). Households start lofts in the year-long runs (1 and 3); none is finished there, because timber runs short (condition 4) |
| Existing-house expansion | HOUSE-06, HOUSE-09, HOUSE-10 | Complete and verified (the small room, the loft and the quarters) |
| Household ownership and occupancy integrity | HOUSE-02, FAM-01, EQ-08, EQ-17 | Implemented and tested |
| Required regression tests | FR-07 (a 10-day simulation in CI; CI fails on script errors) | Complete and verified |
| Long-duration simulation validation | INFRA-02, B14R-12 | Year-long runs on GitHub Actions (condition 4) |
| Save/load compatibility | DVW-A2, DVW-A6, SAVE-00..09 | Complete; the phone checks of save transfer are device items |
| Resource and currency accounting | EQ-10, DVW-A4 | Complete and verified: no leaks in any year-long run |

**Other Build 15 entries:**
- The documentation items are done: REC-004 (the Game Designer spec), REC-017, B14-12, FR-06 and PERF-06's evaluation.
- FR-04 (controller shortcuts) is implemented and tested, and needs a real controller.
- WDR-007-C (the material report) is covered by its own commit before the release.
- WDR-008-C and WDR-010-C need device checks. WDR-010-C's cart-route feedback is deferred (condition 8).
- **Waiting on the owner, not on engineering:**
  - B7-008's buyer half (OD-15);
  - B7-009 and B7-014 (the owner's choice among the measured settings);
  - REC-003's API 36 policy (the builds already target it);
  - DVW-A14 (a whole-life play-through on the installed build).
- **Device checks:** the playtest queue in `docs/DEVELOPMENT_LEDGER.md`.

### 2. Integrated into actual gameplay

Every item above runs in the game, not only in tests. The year-long simulations run the full game world (the same
`World` the game plays), so houses, lofts, beds, households and accounting are exercised together. The small room was
looked at in the game, outside and inside.

### 3. Automated tests pass

All on `af60f94`:
- 24 Godot suites, 0 failures (`housing_test.gd` 107 checks, `run_tests.gd` 3,535);
- Python unittest OK;
- the asset, resource, interaction and requirements checks report 0 problems;
- CI run 39396402372 passed.

### 4. Simulation and integrity checks

**Determinism gate:** `tools/sim_gate.py` matches the baseline exactly.

**Year-long runs:** Actions run 39396414426 on `af60f94`, 365 days, no player:

| | Seed 1 | Seed 2 |
|---|---|---|
| Script errors | 0 | 0 |
| Currency leak / item leaks | 0 / none | 0 / none |
| Alive at day 365 (from 100) | 115 | 122 |
| Births / deaths | 84 / 69, all old age | 92 / 70: 66 old age, 4 starvation |
| Households | 33 | 34 |
| Sites started / finished | 8 / 3 | 9 / 3 |
| Houses built | 3 | 2 |
| Lofts started | 1 | 3 |
| Unemployed adults | 17 of 72 | 17 of 79 |
| Nights without firewood | 6,917 | 6,633 |
| Fingerprint | `b21ba717e772664848724d5001a4028c` | `0647d6bf82c1f58ad21f95e5aeaca583` |

**Wildlife at day 365:** every wild species is alive on both seeds (local re-runs of `af60f94` with the same
fingerprints):
- seed 1: bear 2, bird 14, boar 22, deer 14, fox 6, rabbit 19, wolf 6;
- seed 2: bear 2, bird 18, boar 20, deer 9, fox 8, rabbit 23, wolf 7.

**Construction over the year:**
- Every site that got its materials was finished. No site was given up, and no script error or deadlock occurred.
- Seed 1's other five sites, and every loft started (1 and 3), wait for planks and logs from about day 270 to the
  year's end: timber runs short.

### 5. No known game-breaking defects

No crash, data corruption or save failure is known. The open defects are about the economy's long-term balance, not
breakage (condition 8 and the known issues below).

### 6. No unexplained leaks

The currency and every item balance exactly in both year-long runs (leak 0, no item residuals).

### 7. Save and load

- The format is unchanged (version 14).
- A save made by the Build 14 code (`7dbae4f`) loads in the candidate, plays a game day, saves and reloads. Its
  coins are unchanged (2,978 before and after).
- `conservation_test.gd` checks coins, goods, deposits, animals and villagers across a save round trip.
- Three dated backups are kept, and Continue falls back to them.

### 8. Deferrals follow the policy

**`docs/SKIPPED_ITEMS.md` has one entry:** WDR-010-C's feedback for blocked cart routes.
- Carts have no collision, so a route is never blocked and there is nothing to explain yet.
- It is low severity and presentation only.

**Not deferred, but carried to Build 16 by the roadmap:**
- the economy's long-term equilibrium (EQ-01..06, OD-16);
- stone (EQ-09);
- the bandit fallback for orphans (FAM-07).

Build 16 is defined as that work (ROAD-01). It is not skipped Build 15 work.

**The four starvation deaths on seed 2 were weighed against the "not deferrable" list.**
- They are 4 deaths in a year among the 192 villagers who lived in it (100 at the start, 92 born).
- The village grows: 100 to 122.
- Food is not short: 43,920 wheat was grown and 66,810 pottage made, and 2,931 wheat was left at the year's end. The deaths come from money, not supply.
- That is the economic-paralysis question Build 16's EQ-06 acceptance is written for ("no consistent spiral into
  extinction, starvation, permanent unemployment or economic paralysis"). It is not a broken survival system.
- It is stated plainly in the tester notes.

### 9. Committed and pushed

`af60f94` and every later commit are on `staging/my-medieval-life`. The remote hash was checked at each push.

### 10. Release artifacts produced and validated

Recorded in `BUILD_15_PACKET.md` once `release.yml` has run.

## Known issues (in the tester notes)

**Economy:**
- The trade economy stalls after a few game months: the smith runs short of coins, firewood is short, and about
  17 adults are out of work by day 365.
- Seed 2 lost four villagers to hunger in a year.
- That is Build 16's work.

**Housing:**
- Houses are finished on both seeds, but fewer on seed 1 than in the `59057ac` runs (3 against 8). Seed 1's five other
  sites, and the lofts started, wait for timber from about day 270.

**Other:**
- The small room fits beside only three original houses.
- No audio; some stand-in art.

**Not verified:** no phone, tablet, controller or Windows PC was used. The Android build is signed with a throwaway
key (`ANDROID_SIGNING.md`), so testers must uninstall Build 14 first. Exporting the save first keeps it.
