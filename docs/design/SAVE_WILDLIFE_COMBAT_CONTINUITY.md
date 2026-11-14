# Save continuity of wildlife and combat (MML-SAV-04, B25-SAV04-D1)

Owner decision 2026-11-10, option (a) (`docs/directives/2026-11-10_blocked_decisions_wp1.md`): "A saved game must reload
deterministically, but exact equivalence with an uninterrupted wildlife or combat simulation is not currently required. Document
the limitation and verify deterministic repeated reloads. Do not silently discard persistent world state that existing gameplay
rules require."

## The guarantee

- **Deterministic from its save.** The same save loaded any number of times, independently, goes on identically; so does a save
  loaded, saved again at once and loaded (reload-save-reload). Everything the save holds and everything a loaded world rebuilds for
  itself (below) follows from the save alone, never from the wall clock or the order of loading.
- **Not equal to the game that was never saved.** A world loaded from a save made at minute M can differ from the same world
  played on from M without saving, in where animals stroll and in fights that were going on at the moment of saving. From there the
  two runs can drift apart in anything those touch (a bite, a kill, a hunt's outcome). Neither is wrong: each is a legitimate
  continuation (WDR-022).
- Fractions may come back one unit in the last place off (ND-15, `SAVE_NUMERIC_TOLERANCE.md`); that does not change the
  guarantee.

## What the save keeps (persistent: the rules read it)

| State | Where |
|---|---|
| Every animal: id, species, skin, sex, birth, area (pen or woods), alive, health, position, hunger, next birth, next product, a young animal's dispersal (dest, settle_by, origin) | `Animal.to_dict` |
| Every pen: owner, tenant, trough, waiting products; the player's and claims' pens whole; the seeded wild species; the refuges | `Fauna.to_dict` |
| Every villager's health, maximum health, damage, armour, life, position, level, plan, journey and a guard's pursuit of a wanted player (A2) | `NPC.to_dict` |
| Crimes, cases, deaths and what follows from them (justice, inheritance) | their own sections |

## What it does not keep (transient), and what a loaded world does instead

| Not saved | After loading |
|---|---|
| `Fauna.move_rng`, the animals' stroll stream (B25R1-019) | seeded again from the world's seed: strolls restart from the stream's start |
| An animal's stroll goal, wait, moving flag and facing | each animal picks a new stroll |
| An animal's hunt (`hunt`) | `Fauna.claims` is rebuilt from the villagers' saved plans (`World._rebuild_reservations`); a wild predator chooses prey again |
| An animal's anger at someone, its time left and its bite cooldown, a one-off animation (`anger`, `anger_left`, `bite_cd`, `act`) | the animal is calm; it can be angered again by the ordinary rules (being struck, hunger near people) |
| A struck animal's flight (B25-ANIMAL-HUNT-AI, Build 40): `startle_left`, `alarm`, `alarm_left`, `run_dir`, `zig_left`, `zig_side`, `slide`, `pause_left`, `breaking`, `at_bay` | the animal is calm where it stood, with its health; struck again it is startled and runs by the ordinary rules (`Fauna.provoke`). A flight lasts seconds (`wildlife.struck.flee_seconds` 6, then while the attacker is within `calm_distance`), and nothing a rule reads later depends on it: a hunter's claim on prey is rebuilt from the saved plans. `zig_side` and `slide` outlive one flight (they are not reset on calming), so the first leg of a later flight may bend the other way than in the never-saved game: part of the non-equivalence above |
| A villager's fight: `target`, `target_ref`, `chase_route`, `attack_cd` | the villager decides afresh; a bandit, a guard or anyone attacked may take the fight up again by the ordinary rules. Wounds (health) are kept |
| A walk's path (`path`, `path_i`) and the view's `trail`, `live` | the path is found again from the saved plan step |
| `World.tree_damage`, axe blows in a standing tree | the tree stands whole (blows heal in play too) |
| `World.tick_left`, under half a second not yet ticked | starts at 0 |

None of these is persistent state a rule needs after the moment of saving: health, life, ownership, position and the plans that
claim prey are kept. If a later rule comes to depend on one of them across a save (for example multiplayer reconnect parity, or a
fight that must be resumed exactly), that is SAV-04 option (b): save the transients, with a save-format change and migration.

## Verification

`game/tests/sav04_reload_determinism_test.gd` (seed 1, two days, then a villager fighting another, a wolf or bear angered at a
villager, a tree with axe blows and a wild grazer struck by a villager and running; saved a quarter of an hour into the fight and
a second and a half into the flight):

1. every animal, pen, villager's health and place and hunter's claim survives the save (ND-15 tolerance for fractions);
2. the transients above are reset after loading, not half kept; since Build 42 the world is also saved with a struck wild animal
   mid-flight: it loads calm (its ten flight fields at their defaults), alive, with its health and place, and, struck again after
   the load, runs and calms down by the ordinary rules;
3. saving straight after loading writes the same save again (within ND-15's tolerance);
4. the save loaded twice independently, and loaded, saved and loaded again, go on identically for six game hours: the whole saved
   world and the transients the save leaves out (the flight fields among them).

`save_continuity_test` (three days, villagers and animals) and `plan_continuity_test` (plans) check the same guarantee for the
rest of the world.

## Limits

- One seed and six hours after the load; longer runs from one save rely on the same mechanism (no wall clock, no unordered
  iteration) and the gate's determinism comparison.
- The player's own swing timers are not part of this record; a player's health and pack are saved.
