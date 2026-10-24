# Multiplayer Batch B: guest characters persist in the host's world

Branch `wip/multiplayer-b19`, on Batch A (A1 `da57d7b`/`147991b`, A2 `c2efdb8`/`1c0f854`) and the crime and pursuit repair up to
`d6d4aab`. Requirements: `MULTIPLAYER_PREPARATION.md` section 6 (Batch B: guest characters in the host's save; reconnect to the
same character; MP-D1; newcomers, MP-D7; duplicate refusal; checkpoint: host restart and guest reconnect tests, coin and item census
before and after) and section 10 (gate G1). Owner decisions MP-D1, MP-D4, MP-D7 (2026-10-24). Register: MP-ARCH (the lead edits the
register; this branch does not). **No menu hosts or joins a game**: the preparation document gives menus to Batch D, so nothing here
is reachable by a player yet, and there is no development setting for it.

## 1. What each decision required, and what is done

| Decision | Requires | Done |
|---|---|---|
| MP-D1 | a disconnected character leaves active play (off the map, not acting, not targetable); every persistent record stays in the host's world; nothing deleted automatically | A2 marked a guest who leaves `away` (no needs, no wear, not a detail centre, not drawn). B adds: **loaded means away** (`World.suspend_guests` on the host's load, also for a save written while the guest played, e.g. a host that was killed after an hourly save); **not targetable** (a fighter whose player target is away gives up, `NPCBrain.fight`; a guard on its case cannot see it, `World.sees`, so the chase becomes a search and the case stays wanted). Its pack, purse, skills, crimes, case, killings, judgment facts, quests, property, contracts and debts stay and run on the shared clock under their own rules |
| MP-D4 (for guests) | a death never freezes the world; the established succession with the player's choice instead of an automatic transition | The world goes on while a guest is dead (the host simulates; the guest's death changes nothing for the others). The guest's death screen offers single player's choice, **"Continue as the heir"**, sent as the request `heir` and applied by the host with `World.continue_as_heir` as that guest; plus **"Leave the world for now"**: the dead character waits, and the choice is offered again when the player rejoins (also after a host restart). Nothing chooses for the guest. The host's own death was already handled by A2 (the world runs while guests play) |
| MP-D7 | a new guest arrives as a newcomer under the established rules | A2's newcomer (band pid, the starting kit, its purse and kit counted in) now also enters the village log ("Ann arrives in the village, a newcomer.") and the stat `player_newcomers` |
| Persistence | guests saved in save 21 `players`, restored on load; same identity, same character; host restart | A2 had the save, the identity hash and the restore; B tests every per-player record across a restart and a killed host, and fixes the load (above) |

### The family line of a guest (agent decision, `docs/DECISIONS.md`)

Single player's heir keeps "the house, the chest and what the family owns or leases", all held as `"player"`, a reference that outlives
every generation. A guest's records are held as `"player:<pid>"`, and an heir is a new person with a new pid. So the heir carries
`PlayerState.line`, the pid of the line's first guest character (save key `line`, optional, written only when set), and
`World.player_ref` gives `"player:<line>"`; `World.player_of_ref` finds the living character of the line. A guest who never died
has no line and its reference is its pid, as in A2. The heir also carries the identity hash (`net_key`), so the same device finds the
heir. The session moves the connection to the heir's pid; the guest machine adopts the heir (`Main.adopt_heir`).

### Succession per line

`World.continue_as_heir` for a guest now touches only that guest's line: its own debts and claims (`Credit.on_player_died`), open
contracts (`Contracts.on_player_died`), manor job (`ManorWork.release_player`), all matched by `World.is_acting_ref`. The family links
under -2 (`Life.retire_player_id`) and the tie snapshot of `Identity.succeed` are the host's line's (guests have no ties or family of
their own until Batch C5) and are done only for the host. With one player each of these is exactly the earlier behaviour (G0).

## 2. Edge cases

| Case | Behaviour |
|---|---|
| Duplicate identity | The same key while its character plays is refused ("duplicate", A2), tested again after a host restart. A reconnect after a network drop the host has not yet noticed (ENet times out in seconds) is refused until it does; taking the session over from the stale connection is MP-D6, Batch D. A damaged save with two characters under one identity gives the lowest pid every time |
| Joining while the host saves | Saving is synchronous on the host's main thread (`SaveStore.write_text`), and joins are handled between frames, so a join is never inside a save; tested with the host saving every frame for 4 seconds (75 saves) while the guest joined: the newest save is readable and has the guest |
| Disconnect mid-action | A request queued from a connection that is gone is dropped (A2); one already applied is whole. Tested: applied whole or not at all, coins conserved, the host's record is what the guest sees on rejoining |
| Old save, no `players` key | Loads as single player (the host alone, in play); A1's version 20 fixture, tested again |
| A guest whose character died | Kept dead and away, offered the choice on every rejoin; its heir by the choice (above) |
| The host killed | Its last save may have guests in play; the load puts them out of play |

## 3. Tests

- **`game/tests/multiplayer_b_test.gd`** (new, in `tests.yml`), 31 checks in one process: suspending guests on load (single player
  unchanged byte for byte); a guest away mid-chase not struck, the chase given up, the case, crime, killings and judgment fact kept and
  saved; a guest's death and heir: the world updates while it is dead and nothing chooses, the heir's pid, identity, line and reference,
  the host untouched (its character, -2 family links, ties, contract), the guest's contract cancelled, the line's killings kept, the case
  closed, coins conserved (only the heir's starting purse, counted in `coin_sources`), save 21 round trip of the heir; the host's heir
  unchanged in single player (`"player"`, links retired to -3, no new keys); the version 20 fixture as single player.
- **`game/tests/net_batch_b_test.gd`** (new, in `tests.yml`), 44 checks, two and three Godot processes over 127.0.0.1, the real game
  scene in each: per-player records made on the host as the guest (purse, skills, a theft on its record and its case, a killing, a
  judgment fact tagged `by:player:<pid>`), none of them the host's, both machines agreeing; disconnect with a request in flight; the host
  saves and quits: **coin census and goods census identical across the restart**, the guest out of play until it rejoins, then the same
  pid, place, pack, purse, skills, crimes, case, killings and judgment fact on both machines; the same identity refused while it plays;
  the host killed after a save with the guest in play, the guest out of play after the load; a join during a save storm; the guest's
  death: seen on both machines, the death screen, the world going on, nothing chosen for it, leaving and returning still dead, the choice
  offered again, the heir chosen (new pid, the identity, the line's reference, the dead an ancestor, the case closed, the killings kept,
  only the starting purse new), the identity then finding the heir; a newcomer by another identity (starting kit, clean record, counted).
- **`game/tests/net_host.gd`** gains the commands `endow`, `census`, `crash`, `save_storm`, `kill_guest`, a census in its status and an
  optional max-players argument (default 2, so `net_g1_test` runs as before). No existing assertion was changed.

### Evidence (2026-10-24)

See the final section of this file's commit and the batch report: G0, the SIM-GATE-01 suite, the full `tests.yml` inventory and
unittest, all run on the final code of this batch.

## 4. Left for Batch C and later

- **Per-player ties and family** (BATCH_A section 3, items 1, 2 and 5): ties, notoriety and judgment keys still name every player as
  -2, so a newcomer guest shares the host's standing with the villagers rather than starting "from nothing" (MP-D7's opinion part); the
  guest's own family, marriage and the child heir for guests come with Batch C5 (MP-D8).
- **Quests and manor work for guests**: the per-player records are saved (`PlayerState.quests`) but guests cannot take quests yet
  (guest actions are eating and picking plants), so their persistence is covered by the save round trip only.
- **Taking over a stale connection** on reconnect (MP-D6), the Android interruption save and recovery, and menus: Batch D.
- **The dead guest's loot** lies on the host; the guest's copy of the world is not sent loot changes (patches cover plants only).

## 5. Not verified on real devices

Everything here is loopback on one Linux machine. Real devices, Wi-Fi, Android backgrounding, Windows firewall prompts and mixed
platforms are gates G3-G8 (Batch D).
