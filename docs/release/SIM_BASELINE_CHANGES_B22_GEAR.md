# G0 baseline changes from the armour and weapon catalogue (worker D, wip/b22-gear)

Evidence for the lead's one combined baseline change at integration (Build 22). The baseline file
(`docs/release/sim_baseline.json`) was **not** replaced on this branch.

- Branch: `wip/b22-gear`, merge commit `8809dce` (this branch merged with `wip/build22` at `97cba8b`, whose baseline is
  the single-player baseline worker A replaced with evidence).
- Gate: `python3 tools/sim_gate.py --godot /opt/godot/godot` (seeds 1 and 2, 30 days, checkpoints days 10 and 30, run in
  parallel; 1,596 s wall).
- Records: ARMOR-MATERIALS-01 (boar tusks and antlers from killed boars and stags), ARMOR-CATALOG-01, WEAPON-CATALOG-01,
  WEAPON-VISIBLE-01.

## Result

`determinism gate: FAIL, 28 differences`: every compared value of both seeds at both checkpoints differs (fingerprint,
alive, currency, treasury, deposits, animals, item ledger; households unchanged at 25). Leaks are zero in every sample
(`currency 0, items {}`): no coin or item is made or lost.

| Seed, day | Fingerprint (baseline -> branch) | Alive | Currency | Treasury |
|---|---|---|---|---|
| 1, 10 | 101c54af... -> ca5b7869... | 106 -> 103 | 3134 -> 3274 | 2 -> 48 |
| 1, 30 | 98eea745... -> f9fa18b1... | 115 -> 113 | 4760 -> 4720 | 8 -> 137 |
| 2, 10 | c917b807... -> 8b3102b2... | 110 -> 113 | 3179 -> 3315 | 134 -> 72 |
| 2, 30 | 720d343c... -> fd2108ea... | 127 -> 126 | 4323 -> 4676 | 104 -> 116 |

## The cause, proved by a control run

A control run on the same commit with one change only, the tusk and antler drops switched off (`balance.json`
`animals.boar.tusks` 2 -> 0 and `animals.deer.antlers_m` 2 -> 0, in a separate temporary worktree), gave
`determinism gate: PASS, identical to the baseline` (1,537 s): all four samples' fingerprints equal the baseline's
(`101c54af...`, `98eea745...`, `c917b807...`, `720d343c...`).

So the 91 armour pieces, the 1,920 catalogue weapons and their recipes, the orders, the worn bonuses, the drawn weapons,
the existing items' new `order` fields and the encyclopedia change **nothing** in the simulation: villagers craft only
the recipes their job code names (NPCBrain `_smith`, `_tanner`, `_crafter` lists), no trade's batch unit changes (every new
recipe takes at least as much of a bought input as the smallest existing recipe of that trade), and orders are player
actions only.

The whole difference follows from the tusks and antlers, as the owner asked for them (ARMOR-MATERIALS-01: "boar tusks
and reindeer antlers ... come from boars that are killed (hunter and player)"):

1. `Fauna.kill` adds 2 boar tusks to the carcass of every grown wild boar and 2 antlers to every grown stag, for the
   village hunter, poachers and anyone else who kills one (counted `made_boar_tusk`, `made_antler`).
2. The hunter carries them; with the new OUTLETS entry they are among the goods `_plan_sell_all` takes to the goods
   merchant, whose new BUYS caps (10 each) let it buy them with its coins, and the caravan may carry them away
   (`ResourceNodes.exported`: anything a merchant buys).
3. From the first such sale the hunter's and the merchant's coins, trips and timing differ from the baseline's; every
   later decision that reads coins, positions or prices (and the RNG draws they lead to) follows a different path. This
   is the ordinary divergence of a deterministic simulation from a changed input, not a defect: the same commit gives
   the same numbers every time (the detail run below reproduced the gate's seed 1 fingerprints exactly).

## Item ledger (seed 1, a detail run with its output kept)

`economy_sim.gd -- --days 30 --seed 1 --every 10` on `8809dce` (fingerprints `ca5b7869...` day 10 and `f9fa18b1...` day
30, the same as the gate's run).

| Item | Day 10 | Day 30 |
|---|---|---|
| boar_tusk (new) | start 0, produced 10, consumed 0, exported 0, end 10 | produced 16, end 16 |
| antler (new) | start 0, produced 4, consumed 0, exported 0, end 4 | produced 8, end 8 |

Both are conserved (end = start + produced - consumed - exported). The other ledger rows (60 of 81 at day 10, 58 of 81 at
day 30) differ by the divergence in point 3, for example at day 10: ale produced 72 -> 68, bread produced 111 -> 124, log
produced 995 -> 1064, iron_bar consumed 46 -> 49, wheat consumed 1603 -> 1541; rows that were 1-3 units at day 10 in the
baseline (iron_armor, jewellery, ore_sample, prospecting_kit) are absent or present depending on that path. The
`animals` summaries differ for the same reason (which animals the hunter, wolves and bears met, and when).

## What is unchanged

- Households 25 at every checkpoint of both seeds; leaks 0 everywhere.
- With the drops off, everything is identical to the baseline (the control run), so no other part of this branch changes
  the simulation.

## Recommendation for the lead

Take this branch's numbers into the combined Build 22 baseline (`python3 tools/sim_gate.py --write` on the integrated
commit), citing ARMOR-MATERIALS-01 and this document. The values are outcomes, not pass/fail thresholds (WDR-022); the
gate's role is determinism, which the control and detail runs show holds.
