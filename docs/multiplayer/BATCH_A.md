# Multiplayer Batch A1: one simulation, several players, no behaviour change

Branch `wip/multiplayer-b19`, from the Build 19 baseline `wip/build19` `42c33e0`. Requirements: `MULTIPLAYER_PREPARATION.md` (architecture
section 4, batch A section 6, gates section 10 and the starting point in section 12 on `staging/my-medieval-life`), owner decisions
MP-D1..D8 (2026-10-24). Register: MP-ARCH (the lead edits the register; this branch does not).

**Scope of A1.** The world can hold several full player characters; every player verb can act for an explicit player; single player is
exactly Build 19 (gate G0). **Not in A1:** networking, guests joining, menus, rest by consent, the death choice, per-player relations and
judgment keys (Batch A2 and C).

## 1. What changed

| Area | Change |
|---|---|
| `World.players` | the player characters by permanent pid (band ids from 1,000,000), the host's first, then the guests' in pid order. A read-only view built on each read (the host's pid can change when an heir takes over); membership changes through `add_guest` / `remove_guest` |
| `World.player` | now the **acting player**: the host's character unless a verb runs for someone else. The host's is `host_player()`. Assigning `World.player = x` still replaces the host's character (load, heir) |
| Actor verbs | every `player_*` verb of `world.gd` (and `damage_player`, `buy_plot`, `pick_plant`, `plant_bush`, `plant_tree`, `take_crop`, `container_store`, `container_pick`, `reserve_for_player`, `release_player_station`, `solid_for_player`, `path_for_player`, `continue_as_heir`) takes a last parameter `actor: PlayerState = null`; so do the player's verbs of Business (stalls and shops), BusinessWorks, Carts.park, Chests, Chapel, ContractServices, Contracts (accept, counter, deliver), Credit (repay, answer), Quests (accept, complete), ManorWork (backfill orders), Property.set_home, Farming.clear_plant, OpenPits (backfill, take, tip), Feast.player_feast, Guardianship.player_adopt, Fitting (place, remove), Decay.wear_player / blow_player |
| Refs | `"player"` is the host (as in every save), `"player:<pid>"` a guest; `Life.PLAYER_ID` (-2) is kept as the legacy person id of the host. One set of helpers decides all of it (below) |
| Level | `World.player_level` is now the acting player's `PlayerState.map_level` (the host's still saved in "underground") |
| Detail tier | `World.nearest_player_distance(at)` / `player_positions()`: villagers, animals and refuges are detailed near any player in play |
| Needs and dawn | `_update_player`, `Life._player_dawn` and `Decay.wear_clothes` run for every player (one in single player: identical) |
| Census | `World.total_coins`, `SettlementHoldings.holders` and `.coins` add every player's purse, pack and chest (the economy simulation's ledger sees them) |
| Save | version 21 (section 4) |

### The acting-player context

A verb that gets an `actor` other than the current one re-enters itself inside `World.as_actor(actor, callable)`, which makes `actor` the
value of `World.player` for the call (and restores the previous one afterwards, also when nested). So the whole body of the verb, and every
module it reaches that reads `world.player` (some 60 files, about 570 references), runs for the actor without being rewritten. Each
verb gained exactly two lines:

```gdscript
func player_eat(id: String, actor: PlayerState = null) -> bool:
	if actor != null and actor != player:
		return as_actor(actor, player_eat.bind(id))
	...                                   # the body is unchanged
```

With no actor (every existing caller and test) the `if` is false and the body is the Build 19 body. This is the conservative option; Batch
A2 uses the same entry for a request from a guest (`world.as_actor(guest_player, func(): world.player_buy_many(vendor, id, qty))` or
`world.player_buy_many(vendor, id, qty, guest_player)`). The interface still reads "mine" as the acting player, so a guest's machine
runs its interface inside `as_actor(local_player)` (Batch A2).

### Helper API

| Call | Meaning |
|---|---|
| `World.players` | `{pid: PlayerState}`, host first |
| `player_list()` | the same as an Array |
| `host_player()`, `is_host(p)` | the host's character |
| `player_by_pid(pid)` | the player with that permanent pid, or null |
| `add_guest(p)` / `remove_guest(pid)` | membership of the others (refused: the host, null, no pid, a repeat) |
| `as_actor(p, callable)` | run `callable` as `p` (null keeps the current actor) |
| `acting_player()` | `player` |
| `player_ref(p)` | `"player"` for the host, `"player:<pid>"` for a guest |
| `acting_ref()` | the acting player's reference |
| `World.is_player_ref(x)` (static) | `x` is a player reference: `"player"`, `"player:<pid>"` or the legacy -2 |
| `is_acting_ref(x)` | `x` names the acting player ("is this mine?") |
| `player_of_ref(x)` | the PlayerState a reference (or -2) names: `"player"` and -2 are the host; null when none |
| `World.pid_of_ref(ref)` | the pid in `"player:<pid>"`, 0 otherwise |
| `Life.is_player_id(id)` (static) | a person id (target, tie, family link, judgment id) names a player: today only -2 |
| `player_positions()`, `nearest_player_distance(at)` | the detail centres |
| `World.ref_id("player:<pid>")` | -1 (a player is no villager); `party("player:<pid>")` is null; `ref_name` names the player |

Where code compared a reference with `World.PLAYER` it now asks `World.is_player_ref(ref)` (kind tests) or `is_acting_ref(ref)` (the
interface); where it passed `World.PLAYER` as "the acting player's reference" it passes `acting_ref()` (or `player_ref(p)` when it has the
PlayerState). `ref == "player"` tests, `== Life.PLAYER_ID` tests and `target == -2` tests go through `World.is_player_ref` and
`Life.is_player_id`. Every one of these is true for exactly the same inputs as before while there is one player.

## 2. Behaviour kept (G0)

- With no guest, `players` is the host alone, `as_actor` is never entered, `nearest_player_distance` is the host's distance, the
  per-player loops run once, and every random number is drawn in the same order: the Build 19 determinism baseline is unchanged.
- The host's reference stays `"player"`; relations, judgment, ties and the heir's continuity still use -2 (ID-D1).
- A guest never adds a coin or item: its purse and goods are counted in the census, and its verbs are the same code as the host's.

## 3. Remaining single-player sites for Batch C

Recorded, not changed (changing them alters ties, hashes or order, or needs the guest's own state in a record that is shared):

1. **Person id -2 as the key of ties and judgment.** `Life.PLAYER_ID` as a value (arguments to `Relations`, `JudgmentLive`, `NPC.target`,
   `NPC.partner/mother/father`): `relations.gd` (about 14 places: `give`, `befriend`, `player_tick`, `tie(PLAYER_ID, …)`, defend, courting,
   talk), `judgment/judgment_live.gd` (about 10), `judgment/judgment_social.gd` (key packing), `world.gd` (trade notes, killings, the
   alarm, the fight targets), `life.gd` (the family graph, partner, births, `retire_player_id`), `guardianship.gd`, `quests.gd`
   (`helped`, `on_help`), `contracts.gd` (`rel_id`), `credit.gd`, `business.gd` (`hire`), `construction.gd`, `feast.gd` (`PLAYER`),
   `settlement/couriers.gd`, `npc_brain.gd` (prey), `ui/dialogue.gd`, `ui/game_ui.gd`. Make `Life.is_player_id` true of every pid and
   `PLAYER_ID` the view id of the acting player, then key ties by pid (a save migration of the tie keys, ID-D1).
2. **One global notoriety and `killings`** in `Relations` (`notoriety()`, `slain_by_player`), inherited by the heir.
3. **NPCs and animals choosing their target:** `NPC.target` holds -2 (bandits' `_prey_for`, the guards, `Combat.target`), `Animal.anger`
   holds `"player"` (`fauna.gd` provoke and anger); they must name a pid and choose among nearby players.
4. **Owner references stored in records.** Every site that stores `acting_ref()` is already per player; the legacy migrations
   (`_migrate_construction`, `_migrate_property`) and `Contracts.ref_of(who)` (static, returns `"player"`) still return the host.
5. **Succession:** `continue_as_heir` works for the acting player (the setter replaces a guest's character in `players`), but
   `Identity.succeed` keeps the village's ties under -2, `Life.retire_player_id`, one `FORMER_PLAYER` (-3), `quests.release_all()`
   and `manor_work.release_player()` still release for the host, and `credit.on_player_died` / `contracts.on_player_died` are not per player.
6. **Station and loot reservation** (`reserve_for_player`, `release_player_station`, `player_at_station`) are per actor but the
   reservation key is the single `"player"` entry in `stations`; two players can share one key.
7. **Business and stalls:** `Business.mine()` / `premises()` / `attendant_of` take the one player stall; the courier booth keeper,
   `Stalls.built(ref)` and the shop/stall owner checks use `acting_ref()`, but the data model has one `player` stall slot in places.
8. **Client code** (`main.gd`, `ui/*`): about 230 reads of `world.player` in `main.gd`, 46 in `game_ui.gd`: movement, action timers and
   projectiles live in the client (risk 9). In A2 the client calls the verbs with its own player as the actor.
9. **Shared world random stream** (risk 8): player rolls and NPC rolls draw from `World.rng`; with several players the order of
   requests decides who gets which roll (A2 applies requests at fixed points of the host's tick, by arrival then pid).
10. **Time:** `player_rest` runs the shared clock forward (MP-D2), menus pause the world (MP-D3), a death freezes (MP-D4): Batch C1.
11. **`economy_sim.gd`** reports the host only under `player`; the ledgers it checks come from `SettlementHoldings` and include all.
12. **`WorkExperience.PLAYER`, `Identity.PLAYER` ("player" location) and the recorder's `player_view`** are one key for the host.

(The exact list is regenerated by `grep -rn "Life.PLAYER_ID\|World.PLAYER\|\"player\"" game/scripts`; the counts above are from this commit.)

## 4. Save format 21

`World.SAVE_VERSION` 20 to 21 (`mml-save/21`).

- New optional key **`players`**: `{"host": <the host's pid>, "by_pid": {"<pid>": <PlayerState dict>, …}}` with every player character,
  the host's included (its record is identical to `player`).
- **`player` stays and stays authoritative for the host**: an older build reads the save and ignores `players`.
- `PlayerState` gains **`map_level`** (written only when not 0). The host's level stays in `underground.player_level`
  (which wins on load); a guest's is in its own record. A guest saved on a level that is gone comes up at the first portal's surface stand.
- A record of `players` that cannot become a player (no usable pid, or a repeat) is kept in `World.players_foreign` and written back (key
  `x<original key>`), never dropped.
- **Loading a 20 (or older) save:** no `players` key: `player` is the only player, nothing else changes (no data migration, no new
  identity work: the pid of a version 20 save is already there). A 19 or older save goes through `Identity.upgrade` first, as before.
- `tests/fixtures/b19_save_v20_seed3.json` is a real Build 19 version 20 save (seed 3, 600 ticks, the player's coins and goods set),
  written by the unmodified Build 19 code.

## 5. Tests

- New: `game/tests/multiplayer_a1_test.gd` (in `.github/workflows/tests.yml`): the players map and helpers, the acting-player context
  (nesting, restore), actor verbs on a guest (host untouched), references, the census (coins and goods), the detail tier, needs over
  a tick, save 21 (round trip, older build shape, foreign record, a level that is gone) and the version 20 fixture.
- Changed: `identity_test.gd` asserts the current save version where it said 20 (the bump is the change).

Evidence: see the report at the end of the batch (suite counts and the determinism gate), recorded in the commit messages.
