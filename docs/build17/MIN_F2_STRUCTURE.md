# MIN-F2: collapses, hidden ore, tunnel jobs, minecart preference, shafts and player backfill (Build 17)

Register: MIN-F2 (the owner's MIN-F-Q1..Q5 decisions, `docs/directives/2026-10-21_build17_minf_q1_q5_decisions.md`, all
five approved as requirements). Branch `wip/b17-minf2` (base `wip/build17` `49b6380`). Builds on MIN-F and MIN-H
(`MIN_F_UNDERGROUND.md`). Binding: OD-29, OD-28 and B17-DIR (one deposit system, no regeneration, no automatic ore, no
mining wage), Q18-9 (levels never gate), WDR-022.

Labels: **DONE** (implemented and tested), **PARTIAL** (implemented as far as stated, the rest named), **DECISION** (an
agent decision: a balance parameter or a minor detail, in `game/data/mine_works.json` or here), **OPEN** (the owner's).

## 1. What is built

| Decision | State | Summary |
|---|---|---|
| Q1 collapses and support wear | DONE | Local daily stability of every excavated cell and shaft; collapse fills the cell with rubble (spoil), blocks it, reopened only by digging under timber; supports and ladders wear every dawn and are repaired with real goods or replaced; saved |
| Q2 hidden ore, manor tunnel jobs | DONE (see PARTIAL 3.1) | Hidden ore generated from the seed in deep rock of every level, exposed as an ordinary seam by the cut beside it; the manor's "tunnel" job on the existing job board |
| Q3 minecart preference | DONE (see PARTIAL 3.2) | A miner below ground with a full load uses a usable household minecart when its walking cost is lower, else carries; claims stop two workers sharing it; real load, haul on the rails, unload |
| Q4 shafts and levels | DONE (see PARTIAL 3.3) | Shafts sunk unit by unit from one level to the one below, a ladder (real goods) makes them a portal the router uses; levels below the cave are made by the first shaft that reaches them, bounded at -4; cargo only in a climber's hands, a minecart never goes through |
| Q5 player-directed backfill | DONE | A Backfill Tunnel action creates a paid order (the player's coins held in it); workers may take it through the job board and carry the player's spoil from the depot; the player may also fill with their own hands; nobody else ever fills |

## 2. How it works

### 2.1 Structural stability and deterioration (Q1)

- **Which cells:** every cell the works opened (`MineWorks.opened`) and every shaft. The generated gallery and cave are
  stable natural workings; they are never weighed (no global event).
- **Stability** of cell `c` (0..1, `MineWorks.stability`): for each standing support within `support.reach` (2) cells,
  condition / 1000 x `near_weight` (1.0, at most a cell away) or `far_weight` (0.7); plus, for each four-neighbouring
  cell holding backfill, `backfill_weight` (0.12) x its fill share, the backfill part capped at `backfill_cap` (0.3).
- **Collapse:** at dawn, a cell under `threshold` (0.5) collapses when a hash of the world seed, the day and the cell
  (0..999) is under (threshold - stability) x `rate` (0.4) x 1000: an unsupported cell 200 per mille a day, a cell held
  at 0.4 about 40. All cells are weighed first, then fall, so the order never matters. The world's random stream is
  untouched.
- **Effect:** the cell fills with rubble (5 units, less any fill it holds: the roof rock fallen in), is solid (its A* at
  once), a support on it is crushed, track under it stays; whoever, any cart or pile on it moves to the nearest floor.
  A shaft collapsing fills with rubble as deep as it was dug, its ladder is crushed and its portal removed.
- **Clearing:** the rubble is dug out with a pickaxe under a support within reach (the same rule as cutting), one unit
  of spoil a cut (cut_spoil; the books' `taken`): never stone or ore.
- **Wear:** every dawn supports and ladders lose `decay_per_day` (8) of 1000: a support beside a cut cell lets it
  weaken after about 36 days (far) or 63 (near). A support at 0 fails and is gone (supports_failed); a ladder at 0 has
  rotted through (no portal until replaced).
- **Repair:** with a mallet and `support.repair` (1 plank) or `ladder.repair` (1 plank, 2 nails), used up, back to
  whole (`MineWorks.repair`); a failed support is replaced by setting up a new one. Backfill never mends timber.
- **Cost:** once a day, over the cells the works opened (tens) and the supports near each; nothing per frame.

### 2.2 Hidden ore (Q2)

- `underground.json` `hidden` per map (gallery: iron ore, coal; cave: iron ore; a deep level: iron ore, coal, copper
  ore): placed by the generator in rock with rock all round (never beside a floor, so nothing shows), hashed order,
  no two within two cells, the village's own amount. In `Underground.hidden`, never in `World.deposits`: no villager's
  search (`nearest_seam`, the labour market, the caravan, the manor's choice of face) sees it.
- A cut that opens a cell (a tunnel cell or a shaft's landing) exposes hidden ore in that cell's four neighbours as an
  ordinary seam (`Discovery.open_hidden`: host rock, found_<ore>, its level's sprite, a note): mined by `work_mine`,
  depleted, never refilled. A save keeps exposed seams in `deposits`; on load they are dropped from the hidden list.

### 2.3 The manor's tunnel job (Q2)

- `ManorWork.post_tunnels` (the reeve's evening, after the pits): one "tunnel" job at a time while the works lack stone
  (the quarry's rule) and a face may be cut under sound timber (a support at least at the threshold) on a level
  villagers reach (`MineWorks.manor_face`, chosen by the works alone). Wage: the quarry rate a unit (`excavate_wage`),
  set aside from the treasury when taken, paid when done.
- Steps: walk below, cut a load (`carry_ore`, 6) at the face into the job's load (the heading moves on to the next
  face nearest), carry it to the works yard. The yard keeps the spoil; mending takes only materials (planks, stone, logs,
  iron bars), so spoil mends nothing.
- A miner whose ore is worked out takes it as a trial or excavate job; anyone looking for manor work may. An
  independent miner's ore stays theirs; a job's goes to the yard (the distinction kept).

### 2.4 Minecart preference (Q3)

- When a miner below ground has a full load (`carry_ore`) `NPCBrain._miner` asks `MineWorks.cart_haul_plan`. A cart is
  usable when it is a minecart of the miner's household (`Carts.may_use`), on track on their level, parked, unclaimed (or
  claimed by them), with room (`minecart.capacity` 48 units), within `near_seam` (4) cells' walk of the miner.
- Costs, in cells walked per unit, from the level's A* path lengths: **carry** = 2 x the walk from the face to the way
  out / `carry_ore`; **cart** = 2 x the walk to the cart / `carry_ore` + (rail length x (1 / `track_speed` + 1) + 2 x
  the walk from the rails' end to the way out) / `trip` (24). The cart is used only when cheaper.
- Plan: walk to the cart and put the load in (claimed by this miner); when it holds `trip` units or the seam is out, take
  hold, walk the track cells one by one to the rails' end nearest the way out (the cart follows on its rails), take the
  load into the pack, let go and unclaim; the usual selling follows. Before mining, a miner standing near a usable cart
  left at the rails' end pulls it back to the track cell nearest the seam (on the way: never a detour).
- Claims stop a second worker; a claim older than a day is let go at dawn.

### 2.5 Shafts and levels (Q4)

- `MineWorks.dig_shaft` from a floor cell of level L (support within reach, standing beside, not a portal's cell, no
  support or track on it, not cutting the level in two, the landing not a known seam and with a rock face for the
  ladder): the mouth is an open hole from the first unit; `shaft.units` (4 stone, 2 spoil) are dug, then a rock landing
  is cut as an ordinary cell. The first shaft to reach a level below the cave makes it (`Underground.add_level`: all
  rock, the cave's region, its own hidden ore). Levels end at `shaft.deepest` (-4): at most two more maps of about 200
  cells and A* points each, and the router's breadth-first search over a handful of portals.
- `install_ladder` (a ladder from the pack, used up, a mallet) makes a portal of kind "shaft": the stand beside the
  mouth above, the landing below (its door the rock face the ladder stands against). The level router, the player's
  crossing and villagers' plans use it like any portal; `World.villager_levels` follows.
- Goods change level only in someone's hands; `MineWorks.crossing_ok` refuses a minecart (or handcart) at a shaft.

### 2.6 Backfill (Q5)

- `MineWorks.fill(who, cell, from)`: a unit of spoil from `from` into a floor cell below ground (not a portal's cell, a
  shaft's landing or a collapsed cell), the filler standing beside it; counted filled_spoil; the cell fills a unit at a
  time (drawn as earth heaped from its foot) and at 5 units is solid. Dug again, the fill comes back as spoil
  (`fill_out`), never stone or ore; the cell is open again once it holds less than a full cell.
- **Only the player starts it:** `fill` is called by `main.gd::_fill_own` (the player's own hands, from the pack) and by
  the "backfill" job's fill step; `ManorWork.order_backfill` is called only by `main.gd` (the Backfill Tunnel action).
  `underground_struct_test` asserts both in the code and that two days of a world with spoil everywhere and an
  unsupported tunnel place no fill.
- **The order:** the player pays the wage (`backfill.order_rate`, 1 coin a unit) when ordering; it is held in the order
  (counted in the world's coins) and paid to the worker when done. The depot is the surface stand of the mouth leading
  to that level; the player leaves spoil there; a worker (not a manor hand: the order pays its own) takes it through the
  job board, carries loads of `carry_ore` down and fills the cell. Given up or lapsed, the worker sets down what they
  carry where they stand (back into the depot only at the depot), the order stays. Cancelled, the wage goes back to the
  player, the depot's spoil and any carried load are left lying, the fill placed stays. Saved with its progress.
- **Structure:** backfill adds a limited, local share to the stability of the cells beside it (2.1); it is never a
  support and never repairs timber.

## 3. Partial, and why

1. **No villager makes supports, ladders or minecarts**, and no manor job sets them up or repairs them. The manor's
   tunnel job and a miner's minecart haul therefore begin only where the player (or a household given the goods) has
   set a support or a minecart down: in the 30-day run of seed 1 none exists, so none happens (the run is unchanged).
   Maintenance by villagers was permitted, not required (directive section 8). OPEN 4.1.
2. **Minecarts belong to households** (the existing cart ownership rule); a household of miners must own one. Villagers
   pulling a cart still walk at full speed (the existing B14 gap: `World._walk` ignores `pull_speed`); the cost
   comparison uses `track_speed`, so the choice is the designed one; fixing the gap would slow every household's market
   run, so it is not changed here.
3. **Nobody but the player sinks a shaft**: villagers sink one by the same function (tested), but no job posts it. No
   hoist or windlass: goods go up and down in hands only (the directive's own example of a modelled mechanism).
4. **Backfill orders are carried by hand**, not by minecart (the directive: "where practical").

## 4. Owner questions (genuine; OPEN)

1. Should the carpenter make timber supports, ladders and minecarts for sale, and the manor buy supports (and post
   repair work) for its tunnels? Without a maker the village never tunnels, hauls by cart or digs shafts on its own.
2. A collapse moves the people under it to the nearest floor unhurt. Should a collapse injure or kill (a village may
   fail, WDR-022)?

## 5. Decisions (DECISION; balance parameters in `mine_works.json`, not owner policy)

Threshold 0.5, near/far weights 1.0/0.7, backfill 0.12 a full neighbour capped at 0.3, rate 0.4, wear 8 of 1000 a day;
repairs 1 plank (support), 1 plank and 2 nails (ladder); shaft 4 stone and 2 spoil, deepest level -4; ladder recipe 3
planks and 6 nails at the workbench; minecart capacity 48, trip 24, near 4 cells; backfill 15 minutes a unit, 1 coin a
unit; only cells the works opened are weighed; rubble is spoil; a collapse moves people unhurt; the tunnel job uses
the quarry rate and the quarry's "works lack stone" rule; the player takes neither tunnel nor backfill jobs from the
board (they work with their own hands). `mml-mine-works/2`, `Underground.GEN_VERSION` 3, save version still 17.

## 6. Interactions (for the lead's INT entries)

| Trigger | Sources | Affects | Expected |
|---|---|---|---|
| Dawn | `world.gd::_new_day`, `mine_works.gd::dawn`, `stability`, `collapse`, `_collapse_shaft` | supports and ladders (wear, failure), level collision and A*, portals, people, carts and piles on a fallen cell, villager levels | local, deterministic by seed, day and cell; no goods made or lost |
| A repair | `mine_works.gd::repair`, `main.gd::_works_fix` | inventory (used_plank, used_nails), condition | whole again |
| A cut beside hidden ore | `mine_works.gd::dig`, `dig_shaft`, `expose_beside`, `discovery.gd::open_hidden`, `_enter_seam` | `World.deposits`, found_<ore>, the level's view, villager sums | an ordinary seam, depleting, never refilled |
| The reeve's evening | `npc_brain.gd::reeve_day`, `manor_work.gd::post_tunnels`, `mine_works.gd::manor_face`, `face_refusal` | the job board, the treasury, the works yard | one tunnel job under sound timber; coins conserved |
| A miner with a full load below | `npc_brain.gd::_miner`, `mine_works.gd::haul_costs`, `cart_haul_plan`, `cart_fetch_plan`, `cart_act`, `carts.gd::room` | the minecart's store, claims, the miner's plan | cart only when cheaper; one claimant; goods carried |
| A shaft sunk, a ladder set | `mine_works.gd::dig_shaft`, `install_ladder`, `_link`, `underground.gd::add_level`, `add_portal` | level maps (a new level), portals, the router, `villager_levels`, `crossing_ok` | villagers path through; goods only by hand |
| Backfill | `main.gd::_fill_own`, `_works_targets`, `manor_work.gd::order_backfill`, `stock_backfill`, `cancel_backfill`, `do_step`, `mine_works.gd::fill` | the player's coins (held), spoil (filled_spoil), collision, stability beside | only by the player; placed = removed; saved progress |
| Save and load | `mine_works.gd::to_dict`, `load_dict`, `manor_work.gd` (stock), `world.gd::load_dict` (`drop_found`) | everything above | round-trips; older saves load whole supports and nothing else |

## 7. Tests and results

`game/tests/underground_struct_test.gd` (90 checks, the directive's section 10 items 1-11). Results on `wip/b17-minf2`:
0 failures; with it, 0 failures each: underground_ext 113, underground 95, openpit 66, discovery 65, quarry 39,
contracts 138, services 51, world 339, run_tests 3538, start 499 steps, play 37 steps, parity 55; check_resources 28
nodes 0 problems; check_materials 0 broken, 0 stale (18 open findings, as before); check_assets 0 problems; unittest OK.
`economy_sim --days 30 --seed 1`: LEAKS all zero, fingerprint `5063396929116f24aa7e707200ff846c`, identical to the
MIN-F/MIN-H run: in 30 days of seed 1 nobody owns a support, ladder or minecart, so nothing collapses, no tunnel job is
posted, no cart is hauled and nothing is filled (the reeve looks for a face each evening the works lack stone and finds
none). Screenshots (looked at, `main.gd --screenshot ... --panel collapse | shaft | backfill`).
