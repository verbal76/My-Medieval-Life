# Simulation baseline replaced: seed travelers and food for the road (B25R1-009, 2026-11-03)

SIM-GATE-01 re-record on `wip/b25r1-travelers` (from `wip/b25r1-interact`, 10491e7). Owner directive
`docs/directives/2026-11-03_b25r1_seed_travelers.md` (on `wip/requirements-control`).

## What changed in the shipped game

- **Seed travelers** (`SeedTravelers.designate`, once at the founding): three village residents walk to another settlement,
  buy one ordinary item there with their own coins and walk home (INT-695).
- **Food for the road** (`Journeys.provision`, `buy_food`): every traveller (seed travelers, envoys, buying trips) takes food
  for the walk from the household pantry (at most half its food) and buys food at the settlement for the way home, waiting for
  the sellers' doors to open. Before, a traveller ate only from their pack, which nothing filled, so a trip of more than about
  two days ended in starvation.
- Indirectly: the village's job board, pantries and alms differ from the first day, so everything downstream moves.

## Evidence (local `tools/sim_gate.py`, seeds 1 and 2, checks at days 10 and 30, code `df67e8e`)

| Run | Seed 1 day 30 | Seed 2 day 30 |
|---|---|---|
| Old baseline (`8d31017`) | alive 114, currency 4300, treasury 152 | alive 118, currency 3575, treasury 225 |
| `945d4cc` (seed travelers, food from the pantry only at the start) against the old baseline | `8fa55d91…`, alive 112, currency 4280 | `24218b00…`, alive 104, currency 3703 (FAIL, 28 differences) |
| `--write` from `df67e8e` | `34cc2e5372d61605dcc9598d5e6dddec`, alive 112, currency 4013 | `e4ed695e2b00625382b64cf964fbed7a`, alive 118, currency 3597 |
| Re-check, same code | PASS, identical | PASS, identical |

Day 10: seed 1 `c7ea116c…` alive 107, currency 3314; seed 2 `0735823b…` alive 109, currency 3034.

- **Determinism:** the `--write` run and the re-check are identical at every checkpoint (two independent runs per seed).
- **Conservation:** currency leak 0 and no item leaks at every checkpoint of all three runs.
- **Why the 945d4cc run lost people in seed 2:** its travellers left the settlement at 6:00, before the sellers keep their doors
  (7:00), bought no food for the way home and one starved; the household arithmetic downstream differed. `df67e8e` has them
  wait for the doors to open (seed 2: all three seed travelers home alive), and seed 2's population at day 30 is back to 118.
- The 945d4cc row is a superseded intermediate, not the baseline.
