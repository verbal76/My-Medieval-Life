# Overnight report, 2026-10-20 (master overnight directive, OVN-01 section 13)

Status labels as the directive asks: IMPLEMENTED, TESTED, STAGED, BUILT, RELEASED, BLOCKED, DEFERRED.

## Build status

| | |
|---|---|
| Highest build fully completed | **Build 14** (a private draft release, earlier) |
| In development | **Build 15**, simulation stabilization: **BLOCKED** on one non-deferrable item, house completion on seed 1, which needs owner decision OD-16 |
| Builds published tonight | None. Build 15 does not meet section 4: its core construction item is not verified on every seed |
| Builds 16-18 | Not started. The roadmap is strictly sequential (section 3) |

## Development results

| Item | What | Label |
|---|---|---|
| EQ-17 (new) | Every long run since the early fixes logged thousands of script errors from day 90-190: a baby born to a household still building its house got no home. Fixed (`Life.birth`). CI and the long-simulation workflow now fail on any script error | TESTED, STAGED; verified by 365-day Actions runs on both seeds (0 script errors) |
| EQ-10 | Item-ledger residuals. A successor got the trade's tools from nothing; now they come from the heir, or a newcomer brings them as an import. Villagers' medicine use was not counted | TESTED, STAGED; 365-day runs balance exactly |
| FR-07 | A 10-day simulation runs in CI on every staging push | TESTED, STAGED; CI run 39368652711 |
| DVW-A2 | Three dated save backups; Continue falls back to them | TESTED, STAGED |
| DVW-A6 | A test that coins, goods, deposits, animals and villagers survive a save round trip on both simulation tiers | TESTED, STAGED |
| DVW-A4 | The simulation prints the village's faucets and drains for coins and every good | TESTED, STAGED |
| B7-008 | Verified: wildlife recovers (refuges). The player can still sell a trader to 0 coins; whether the player keeps the traders' 15-coin floor is a game rule, raised as OD-15 | BLOCKED (OD-15) |
| PERF-02..05 | Profiled by subsystem; determinism gate and baseline (`tools/sim_gate.py`); parallel seeds 1.85x faster; two optimizations, each identical through the gate: **the simulation runs about twice as fast** (10 days 44.0 s to 25.5 s; 30 days 127/142 s to 68/73 s) | TESTED, STAGED |
| HOUSE-04 / EQ-07 | Housing routes from your directive: help from relatives; builders bring their own materials, saw planks, fell timber (keeping an axe); the caravan leaves tools the village needs | TESTED, STAGED. On seed 2 houses are finished; **on seed 1 none, because the village's trade economy stops (OD-16)** |
| FR-04 | Journal (D-pad up) and Build (left stick) on the pad; controls lists complete | TESTED, STAGED; needs a real controller check |
| FR-06 | Six missing wiki pages: magic, the employer star, journal and map, causes of death, the caravan, bandits | TESTED, STAGED |
| REC-003 | Investigated: the Android builds already target API 36 (Godot 4.7.2's template) | Nothing to build; your confirmation of the policy is open |
| INFRA-02 | Long simulations run on GitHub Actions (owner-approved), validated against a local run | STAGED; in use |

## Simulation outcomes (365 days, Actions run 39368663150 on `0ee0218`, no player)

- No script errors. The currency and every item balance exactly.
- Seed 1: 101 villagers at day 365 (from 100), no starvation. Every wild species is alive at the end.
- Seed 2: 2 starvation deaths (a merchant, an elder).
- **Houses: 7 sites started on seed 1, none finished.**
- Why (200-day traces, `docs/release/LONG_RUN_SIMULATION.md`, "Why seed 1 builds no house"):
  1. The mine runs out early.
  2. The smith runs out of coins by day 120 and can no longer buy imported iron.
  3. No axes are made, so woodcutters fall from 6 to 1 (20 unemployed).
  4. There is no timber, so house sites stall, though builders now have the money.
  5. About 45 % of the village's coins sit with bandits or as loot nobody picks up.
- A second Actions run on the housing corrections (`59057ac`) is recorded below when it ends.

## GitHub

- Branch: `staging/my-medieval-life`, 22 commits tonight, from `71f0b62` to `d4e2dc4`. Each push's remote hash was checked.
- `main`: only the one owner-permitted workflow commit (`de76782`).
- CI: green on every checked staging commit (runs 39368652711, 39370974090, 39372860024).
- Long simulations: Actions runs 39368663150 (validation and the year on `0ee0218`) and 39385942656 (`59057ac`).
- Releases: none tonight.

## Outstanding

**Owner decisions:**
- **OD-16 (blocks Build 15):** how money should flow back to the essential trades. Options and a recommendation are in the register: the manor supports the smithy and woodlands, and bandits' hoards and loot return to circulation.
- **OD-15:** the player and the traders' 15-coin floor.
- OD-14's upper floors (HOUSE-10, HOUSE-11).
- The others listed in `docs/CURRENT_DEVELOPMENT_STATE.md`.

**Skipped items:** none (`docs/SKIPPED_ITEMS.md` is empty). Nothing was deferred to advance a build.

**Remaining Build 15 work:**
- EQ-07 and HOUSE-07 after OD-16;
- B14-12 (sprite list);
- REC-004 and REC-017 (documents);
- device checks for the items marked playtest;
- then the Build 15 release gates and a private draft release.

**Next steps:** implement your answer to OD-16, re-run 365 days on both seeds on Actions, close EQ-07, then release Build 15 privately and begin Build 16.
