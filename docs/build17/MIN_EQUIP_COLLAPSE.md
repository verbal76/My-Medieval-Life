# MIN-EQUIP and MIN-COLLAPSE: mining equipment from the village's trades, and the person caught in a cave-in

Register: MIN-EQUIP, MIN-COLLAPSE (HEALTH-01 stays a "Not in the game yet" placeholder). Owner decisions MIN-F2-Q1 and
MIN-F2-Q2, `docs/directives/2026-10-21_build17_minf2_q1_q2_decisions.md`. Branch `wip/b17-equip`, from `wip/build17`
`f09884a`, merged with `wip/build17` up to `f082790` (STONE-01, the mining wiki, MIN-SHOVEL and parity). Builds on
`MIN_F2_STRUCTURE.md` (stability, collapse, wear, the manor's tunnel job, shafts) and `MIN_F_UNDERGROUND.md`.

Player wiki: `sys:mine_equipment` ("Mining equipment: who makes it, who buys it") and `sys:mine_collapse` ("Caught in a
cave-in"), in `game/scripts/core/wiki_mine_equipment.gd` (registered with `Wiki.add_provider`); the collapse outcome is
also summarised on `sys:mine_stability` (`wiki_mining.gd`) and the carpenter's `job:carpenter` text (`Wiki.JOB_TEXT`).

## 1. MIN-EQUIP: who makes the equipment, and why anyone buys it

### Makers (recipes unchanged; `game/data/recipes.json`)

| Good | Recipe | Maker | Parts from other trades |
|---|---|---|---|
| Timber support | `make_timber_support` (sawhorse: log + 2 planks) | carpenter | none |
| Ladder | `make_ladder` (workbench) | carpenter | nails (smith) |
| Minecart | `build_minecart` (workbench) | carpenter | cart axle, cart ironwork (smith); cart wheels (carpenter) |
| Mallet | `make_mallet` | carpenter | none |
| Support repair | `MineWorks.repair` | whoever does the job | a plank (carpenter) |
| Ladder repair | `MineWorks.repair` | whoever does the job | a plank and nails (smith) |

The smith is not excluded: its nails, axles and ironwork are bought by the carpenter through the existing
`NPCBrain._parts_trip` (from the smith or the goods merchant, as for a handcart). Neither trade gets a new wage or a
mining-specific market: every piece is a recipe's output, every transfer a purchase at the holder's price.

### Code

- `game/scripts/core/mine_supply.gd` (`MineSupply`, no state of its own; `MineWorks.supply`). Reads the world and the
  mine works each time; nothing to save.
- `MineSupply.carpenter_work(n)`, first in the carpenter's branch of `NPCBrain` (before carts, goods, mallets, shovels):
  the manor's open orders on this carpenter first, then a minecart when some miner's household wants one and nobody has
  one for sale. `_make` makes the recipe, or the next step toward it (a cart wheel, planks sawn from its logs, or a parts
  trip for nails, axles or ironwork). Logs and planks are its trade's stock and are never bought for this.
- `NPCBrain.MADE_TO_ORDER` gains `timber_support`, `ladder`, `minecart`; `keeps` and `_deliver_orders` accept a
  carpenter as an order's maker (they accepted only the smith before). An order whose `for` is `-1` is the manor's: the
  finished piece is delivered into the works yard (`ManorWork.yard`), stat `gov_equipment_delivered_<tool>`.
- A carpenter holds back only as many of a good as the manor has ordered from it (`NPCBrain.keeps`): a second mallet it
  makes for the goods merchant, or that a labourer wants to dress stone with, is for sale while the manor's one waits for
  delivery, and `_carpenter_mallet` never sells the ordered one. (The smith's rule, EQ-19, is unchanged: it holds back
  every unit of an ordered tool.) Without this, one open order for a mallet stopped every labourer buying a mallet from
  that carpenter, which delayed building blocks and house building by days (found by `run_tests`' household split).

### Demand: real need only

`MineSupply.manor_needs()` (the reeve, each evening in `reeve_day`, after `post_tunnels`):

| Need | Rule (`mine_supply.gd`) |
|---|---|
| A support for a face | `tunnel_wanted()`: the works yard holds less stone than twice the mending load and the treasury could fund a tunnel wage; and `unsupported_face()` finds a below-ground face whose only refusal is "Set up a timber support", with a prop site (the last opened cell first) |
| A plank per worn support | `repairs_wanted()`: a support below `supply.repair_at` (600 per mille sound) that holds an opened, open cell |
| A ladder | `ladders_wanted()`: a finished shaft whose ladder rotted through or was crushed |
| A mallet | one for the works yard, when any of the above is wanted |

Less what the yard already holds, what a job is carrying and what is already on order. `procure()` then buys what a
carpenter, smith or goods merchant holds (`_holder`, respecting what each `keeps`), at their price, from the treasury,
never below `manor_support_floor_days` of daily obligations (`balance.json`); what nobody holds it orders from the
carpenter with the fewest orders, paying the price in advance into `manor_orders` (the same advance-and-deliver path as
the manor's tools). Stats: `gov_mine_equipment` (coins), `gov_bought_<id>`, `gov_ordered_<id>`.

`ManorWork.post_shore()` then posts a `shore` job (`mode`: `prop`, `repair` or `ladder`) for each need the yard can
equip, at the board's mend wage (`manor_jobs.mend_wage`), with the yard's mallet claimed by that job. Steps: take (the
goods and mallet into the job's load), prop (`place_support` / `repair` / `install_ladder` with `from = j.load`, the
same refusals as the player's; a refusal releases the job), put (the mallet and anything left back to the yard), finish
(wage from the treasury). Rank 2 on the board, ahead of mending (rank 4: mend jobs never run out, so shoring ranked
after them was never taken). The player is not offered shore jobs (as tunnel and backfill); the player does the same
work with their own hands.

A miner's household minecart (`minecart_wanted(n)`): the miner's seam is below ground, track runs within `near_seam` of
the seam's stand toward an unload point, the household has no minecart, and the minecart's cost is less than the carry
cost it saves (the MIN-F2-Q3 comparison). `miner_cart_plan(n)`: walk to the seller, buy it with the household's coins
(`buy_from`), walk to the track cell on its level and set it down (`mc_place`, `MineWorks.set_down_minecart`).

### Decisions (agent, within the directive)

- **Nobody lays track or sinks a shaft on their own.** Track has no need rule of its own: a minecart is wanted only where
  track exists, and track would be wanted only for a minecart, so an autonomous rule would be circular and invented.
  Minecarts therefore arise only where the player has laid track. Shafts likewise stay the player's (MIN-F2). Ladder
  replacement for existing shafts is autonomous (a real need: a broken way).
- **Spoil from the manor's tunnelling stays in the works yard**; mending takes only `MATERIALS` (unchanged).
- **A support is not repaired before it is needed**: only below `repair_at` and only where it holds an open passage.
- Equipment bought by the manor is the manor's (the yard), not a household's; a miner's minecart is the household's.

### Tunables (`game/data/mine_works.json`)

| Key | Value | Meaning |
|---|---|---|
| `supply.repair_at` | 600 | Soundness (per mille) below which the manor wants a support repaired |
| `collapse.survive_base` | 300 | Survival chance (per mille) for someone in a cell that falls with no hold at all |
| `collapse.survive_per_held` | 600 | Added per mille for a fully held cell, scaled by the cell's stability at the fall (0..1) |

All three are marked TEMPORARY TUNABLE in the file's notes, for owner review; none is policy.

## 2. MIN-COLLAPSE: the person caught in a cave-in

`MineWorks.collapse()` takes the cell's stability before filling it, then `caught(level, c, held)`; a shaft's fall
(`_collapse_shaft`) calls `caught` on the level the shaft lands on. For each person on that cell (the player, then
villagers by id):

- **Survival threshold** `survive = survive_base + survive_per_held * clamp(held, 0, 1)` per mille.
- **Roll** `Overworld.hash32(seed, 7301 + day, (level + 16) * 65536 + y * 256 + x, person + 2) % 1000` (person = -1 for
  the player, the NPC id otherwise). Deterministic: the same world, day, cell and person always give the same outcome; no
  global RNG and no wall clock.
- **Dies** if the roll is not below the threshold: a villager through `World.kill(n, "crushed in a mine collapse")` (the
  heir, inheritance, the family's memory, the village record, `brain.on_death`, open posts: INT-017, INT-054), the player
  through `World.damage_player(1e9, "crushed in a mine collapse")` (the existing player death and heir: INT-018). Stat
  `collapse_deaths`.
- **Survives** otherwise (stat `collapse_survivors`): moved to an adjacent open floor cell (`_escape`: the four sides
  first, then a corner only where a side next to it is open, so nobody passes through rock), stat `collapse_escaped`; or,
  with none, **trapped** (`MineWorks.trapped[ref] = "level,x,y"`, stat `collapse_trapped`, a village note). A trapped
  villager does nothing (`World._update_npc` idles them); a trapped player may only dig the cell they are in
  (`dig_refusal`). The cell's fallen rock is loose spoil, dug with a shovel (`tool_kind`, MIN-SHOVEL); when the cell is
  dug open again `_free_trapped` frees whoever it held.

The old behaviour (anyone in a falling cell moved unhurt to the nearest floor; minecarts and piles moved out) is gone:
minecarts and piles in a falling cell are now buried with it.

### Limitations (reported, not hidden)

- **No injury or medical system** (HEALTH-01 placeholder): a cave-in leaves a person unhurt or dead.
- **No rescue system.** Nobody digs out a trapped villager on purpose; only digging that cell open (by the player, or a
  job that happens to reach it) frees them. A trapped villager still grows hungry and can starve, a legitimate outcome
  under WDR-022.
- A person standing in the cell at dawn is the only one caught; there is no partial-adjacent damage.

### Saves

`mine_works.trapped` is saved under the `mine_works` key (`"trapped"`); older saves load with nobody trapped. No other
new state: `MineSupply` is derived each evening; orders use the existing `manor_orders`; shore jobs use the board's jobs.

## 3. System interactions (for the INT manifest; not edited on this branch)

- Underground stability ↔ Death and inheritance: a cave-in kills through `World.kill` / the player's death (INT-017,
  INT-018), or traps or moves the survivor (new; extends INT-193).
- Carpentry ↔ Manor treasury ↔ Underground works: the manor buys or orders supports, ladders and mallets from carpenters
  (and parts flow from the smith), paid from the treasury above its floor, delivered to the works yard (extends INT-178,
  INT-063, INT-194).
- Manor job board ↔ Underground works: `shore` jobs (prop, repair, ladder) at the mend wage, ahead of mending (extends
  INT-066, INT-194).
- Carpentry ↔ Miners' households ↔ Track: a household buys a minecart where track serves its below-ground seam
  (extends INT-191, INT-195).

## 4. Tests

`game/tests/equip_test.gd` (new): recipes and parity; the manor's order made by each carpenter and delivered to the yard;
procurement and the shore flow (prop, repair, ladder) paid from the treasury; the household minecart bought and set down;
coins conserved; collapse outcomes deterministic and mixed over seeds; a villager's death through `World.kill` with heir
and memory; the player's death; survivors escaping to an adjacent cell, trapped and idle, freed when the cell is dug;
save round-trip of `trapped`. `underground_struct_test`'s collapse check accepts death, an adjacent escape or trapping.
`economy_sim` samples an `underground` block (tunnel cells, supports, shore and tunnel jobs, equipment coins, minecart
hauls, collapses, deaths, survivors). Results are in the branch's report.
