# Overnight report, 2026-10-20 (master overnight directive, OVN-01 section 13)

Status labels as the directive asks: IMPLEMENTED, TESTED, STAGED, BUILT, RELEASED, BLOCKED, DEFERRED.

## Build status

| | |
|---|---|
| Highest build fully completed | **Build 14** (a private draft release, earlier) |
| In development | **Build 15**, simulation stabilization: **BLOCKED on OD-16**. Everything else in its scope is implemented and tested. The release-candidate run found two tool-recovery defects (EQ-18), which are fixed. The rest of the failure is money: the producing trades go broke, so no axes are made and timber and building stall |
| Builds published tonight | None. Build 15 does not meet section 4 while its tool recovery fails on money (OD-16) |
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
| HOUSE-04 / EQ-07 / HOUSE-07 | Housing routes from your directive: help from relatives; builders bring their own materials, saw planks, fell timber (keeping an axe); the caravan leaves tools the village needs | TESTED, STAGED; verified over 365 days: 8 houses on seed 1, 2 on seed 2 |
| HOUSE-10 / HOUSE-09 / HOUSE-06 | Your OD-14 answer: a small 5x6 room with two beds, made from Shade's house art, for the three original houses with ground beside them (b23, b24, b_v1_house). Built with real ground, materials and work; beds only when finished. Also fixed: rooms added by villagers were not joined to their house's property | TESTED, STAGED; looked at in the game, outside and inside |
| FAM-02..06 (Build 16) | Orphaned children are taken in: a surviving parent, then grandparents, then the nearest relative, then another household with room; ranked by your OD-12 order; genealogy and birth surname kept. FAM-07 (bandit fallback) not built | TESTED, STAGED |
| WR-02 (Build 16) | When a wood has more grazers than grass, the strongest feed first instead of all starving together | TESTED, STAGED |
| B14-12, REC-017 | The sprite list with pixel-grid copies for Aseprite (`docs/assets/SPRITE_NEEDS.md`, 53 entries) | Done |
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
- **Second year-long run** (Actions run 39385942656 on `59057ac`, the housing corrections; local re-runs identical):
  - seed 1: 111 alive, 13 sites started, 9 finished, **8 houses**, no starvation;
  - seed 2: 128 alive, 9 sites started, 3 finished, **2 houses**, 4 starvation deaths;
  - both: 0 script errors, the currency and every item balance exactly.
- The trade economy still stalls (the smith near 0 coins from about day 120, 24-39 unemployed, firewood short). That is Build 16's equilibrium work; OD-16 moved there.

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
- a year-long run on the release candidate, the readiness packet, then the private draft release;
- REC-004 (the Game Designer spec: its source files must be found first);
- device checks for the items marked playtest (yours, on the installed build).

**Next steps:** your answer to OD-16; implement it, re-run a year on both seeds, then release Build 15 privately and begin Build 16.
