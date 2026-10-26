# Build 22: changes to the accepted simulation baseline (GP-BASELINE-POLICY)

Each change below is an owner-approved change whose differences were listed, explained and checked before the baseline
(`docs/release/sim_baseline.json`, written by `python3 tools/sim_gate.py --write`) was replaced. The baseline before the change
is kept beside it. Worker A (wip/b22-market) is the only Build 22 worker allowed to change the single-player baseline; all its
layout changes are replaced in one step (this section).

## 1. The market laid out anew, and built stalls kept as far apart (GP-MARKET-SPACING; with GP-TABLE-ITEMS, GP-BUSINESS-DESK, GP-BUSINESS-COURIER, GP-STALL-RENT-WRONG-PITCH on the same branch)

- **Approved changes:** owner playtest 2026-10-26 "The market booths are not too close to each other with the new sprite",
  confirmed by the owner's binding amendment `docs/directives/2026-10-26_build22_final_owner_answers_amendment.md` section 6:
  "The booths are too close together. Space them farther apart ... Choose spacing based on actual footprint, player clearance
  and NPC pathing ... Record the layout change and its simulation-baseline effects before accepting a new baseline."
- **What changed that the simulation can see (two things, nothing else):**
  1. *The market's places* (village generator v16, `tools/build_village.py`, `game/data/village.json`): the six merchants'
     stalls and the manor's four pitches move from v15's two cramped rows (stalls at y 63, x 36..56 step 4; pitches at y 61,
     x 42..54 step 4) to two rows of five 5 tiles apart, 5 rows apart (north row y 59: pitch0, pitch2, pitch1, pitch3, stall5 at
     x 37..57; south row y 64: stall0..stall4 at x 37..57). Ids, kinds, tenants and the pitches' order in the world are as
     before. The map differs from v15 only there (key by key: `solid` and `below0` at the 24 old and new stall cells, `stalls`,
     the stall crates' `containers` cells, the new `pitches` key) and, not seen by the simulation, the counters' `show` cells
     and the sawmill desk's drawn plate (`below3` at (68, 25)). Trees, plants, boulders, deposits, roads, buildings, fields,
     pens and plots are identical (checked: every other key of village.json is unchanged).
  2. *Built stalls' spacing* (`Stalls.SPACING`, `Stalls.site_refusal`): a stall a villager household or the player builds must
     stand at least 5 tiles along x or 5 rows along y from every other stall (before: 3 tiles apart), the market's own spacing
     for the shelf drawing, so villagers' stalls go up on other ground (`Stalls.find_site`).
- **Kept:** `docs/release/sim_baseline_pre_market_spacing.json` (the accepted baseline from `1b57766`, which every Build 22
  worker's G0 passed against).
- **Isolation runs (all four checks, seeds 1 and 2, 30 days, the gate's own simulation):**
  - *Everything on the branch except the two changes above* (desks, the courier at the desk, table previews, the rent fix, the
    pitches read from village.json, the counters' `show` cells, the sawmill plate; the map's market at the v15 places and the
    old 3-tile rule): **identical to the baseline at every check** (all four fingerprints `682b04e9...`, `324285ea...`,
    `26e85cf8...`, `0aeb46c7...`; every alive, households, currency, treasury, deposits, animals and item-ledger value equal).
    So no difference below comes from those changes.
  - *The v15 market places with the new 5-tile rule only:* differs at all four checks (265 values): the first stall a household
    builds goes up elsewhere (seed 1: household 0 on Summer day 4, at (41, 68) instead of (43, 66), the walk there one game
    minute different; seed 2: household 24 on Autumn day 5, the same two sites), and the village's later days differ from there.
  - *Both changes (the build):* differs at all four checks (295 values). The first difference in both seeds is at 07:03 on the
    first day, two steps in: the merchant of stall1 (seed 1 John Lambert, seed 2 Edmund Mercer) walking from home to his
    stall, which now stands at (42, 64) instead of (40, 63), takes a different first step ((18.986, 84.5) instead of
    (18.844, 84.843)). Every merchant walks to a stall in a new place, and buyers walk to them; one shared random stream then
    tells the rest of the village's life differently. The first built stall goes up at (43, 69) (seed 1, Summer day 4) and,
    for seed 2, a year later (Summer, year 2, day 3, household 6).
- **Differences (both changes; the baseline -> the new values):**
  - seed 1 day 10: alive 109 -> 106, currency 3301 -> 3134, treasury 113 -> 2, fingerprint `682b04e9...` -> `101c54af...`;
    item ledger 63 values, animals 5, deposits 10.
  - seed 1 day 30: alive 115 -> 115, currency 4770 -> 4760, treasury 60 -> 8, fingerprint `324285ea...` -> `98eea745...`;
    item ledger 60 values, animals 6, deposits 5.
  - seed 2 day 10: alive 110 -> 110, currency 3222 -> 3179, treasury 136 -> 134, fingerprint `26e85cf8...` -> `c917b807...`;
    item ledger 51 values, animals 4, deposits 9.
  - seed 2 day 30: alive 119 -> 127, currency 4287 -> 4323, treasury 135 -> 104, fingerprint `0aeb46c7...` -> `720d343c...`;
    item ledger 59 values, animals 5, deposits 4.
  - Households 25 at every check, as before. The treasury and population moves are the same village life told differently
    (when tax, wages and relief fall, who is born and who dies); none is a failure of a mechanism, and none is corrected
    (WDR-022).
- **Conservation:** currency leak 0 and item leaks none at every check of both seeds, before and after.
- **Unrelated values:** shown unchanged by the first isolation run above (identical at every check with only the two changes
  taken out). No value of the gate could be kept identical with the market moved, since every merchant's first walk changes.
- The new baseline is written by `tools/sim_gate.py --write` on the code commit and names it; it equals the "both changes" run
  above value for value (checked before it was committed).
