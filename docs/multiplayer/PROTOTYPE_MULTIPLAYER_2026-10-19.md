# Player-hosted multiplayer (MP-01)

> **Status (DOC-RECON-01, 2026-10-31): HISTORICAL.** This document is the MP-01 prototype, which was SUPERSEDED by MP-MASTER. It is not a current instruction. Current status:
> `docs/expansions/MULTIPLAYER.md`. Precedence: `docs/expansions/README.md`. Content below kept unchanged.

Owner directive, 2026-10-19: "Minecraft-style player-hosted multiplayer": 2 to 4 players in one
persistent world, hosted by a player on a Windows or Linux PC or an Android device, with no
dedicated server. The game stays fully playable alone.

This is the first milestone: a two-player LAN prototype. It lives on the isolated branch
`wip/multiplayer` and does not go into staging or a build without the owner's approval
(DEVELOPMENT_QUEUE item 13).

## 1. What works now (automated, two to four Godot processes on one machine)

`game/tests/net_test.gd` (36 checks) runs a guest in its own process. `tests/net_host.gd` runs a
host, and `tests/net_guest.gd` runs extra guests. All talk through real Godot ENet networking on
127.0.0.1.

| Requirement | State | Evidence |
|---|---|---|
| Host a new or saved world | Works | Host With Friends: a saved world or a new one (after character creation); also from the pause menu |
| Discover a host on the network | Works on loopback | UDP query and reply; the guest lists host name, world name, players, password and version |
| Join from a second device | Works between processes | Not yet tried between two real devices |
| Two independent characters | Works | Each guest's character is a `PlayerState` kept by the host in `World.guests` |
| Both moving in the same world | Works | The guest's walk is seen by the host to 0.00 tiles; the host's walk is seen by the guest to 0.00 tiles |
| Movement, facing and basic animations | Works | Position, facing and idle, walk, sword or gather animation, at 10 per second |
| Disconnect and reconnect | Works | Leaving and rejoining restores the same character: place, pack and coins |
| Player state saved in the host's world | Works | The host saves guests with the world; after a host restart the guest's character returns |
| Single player unchanged | Works | Every single-player suite passes on the branch, and saves without guests load as before |
| Shared actions, host-validated | First action works | Picking a fruit tree twice gives the fruit once; if the host picks first, the guest's request is refused; unknown and out-of-reach requests are refused |
| Refusals in plain words | Works | Wrong version, wrong password, world full, same player already in, no name |

**Not tested on real devices yet:**
- Android as guest or host.
- Two PCs on a real router.
- A phone hotspot.
- Sleep and background behaviour.

Android hosting must not be called verified until it has run on a real phone.

## 2. Architecture: who decides what

| Layer | Where | Rule |
|---|---|---|
| Simulation authority | The host's `World` (`game/scripts/core/`) | The only simulation. Villagers, the economy, wildlife, crafting, inventories, farming, crime, time and saving all run here. |
| Player input | Each machine's `main.gd` | A guest moves its own character on its own screen for responsiveness, and asks the host for everything else. |
| Network sync | `game/scripts/net/net_session.gd` (`NetSession`, one node named "NetSession" under Main on every machine) | Requests go up and results come down. The host validates every request. |
| World state on a guest | A `World` loaded from what the host sent on joining | Never simulated or saved. Its clock, nearby villagers and the other players are overwritten by the host's snapshots. |
| Presentation and UI | `main.gd` (`_sync_avatars`), `game_ui.gd` (Host, Join, Players) | Shows what it is given. |
| Persistence | The host's save (`World.to_dict`, optional `guests` key) | Guests never save. Their characters live in the host's world. |

**Messages.** All are RPCs on `NetSession`.

| Direction | Message | When |
|---|---|---|
| host → guest | `s_challenge(salt)` | On connect |
| guest → host | `c_hello(version, key, name, password hash)` | In reply |
| host → guest | `s_welcome(world, id)` or `s_refuse(code)` | In reply |
| guest → host | `c_move(pos, dir, anim)` | 15 per second, unreliable |
| host → guest | `s_correct(pos)` | When a move is refused |
| host → all | `s_players(list)` | 10 per second: names, looks, positions, facing, animation |
| host → each guest | `s_npcs(minutes, villagers within 24 tiles)` | 4 per second |
| guest → host | `c_request(id, kind, args)` | A shared action |
| host → guest | `s_reply(id, result)` | The outcome |

**Movement validation.** The host accepts a guest's new position only if two things hold:
- It is no farther than sprint speed allows since the last accepted move: 1.5 × speed × time, plus 0.25 tiles.
- It is on open ground.

Otherwise the host sends the guest back.

**What a guest receives when joining.** The world as saved, with the guest's own character as the player. The host's character state, the other guests and every identity hash are removed first.

## 3. Identity and persistence

- Each device makes one random 128-bit key, once, and keeps it in `user://identity.cfg`.
  A guest sends it when joining.
- The host keeps only the key's SHA-256 hash, in `World.guests` and in its save, never the key itself.
  Peer ids are used only for the current connection.
- The same key always returns the same character: its place, pack, coins and skills.
- A key that is already playing is refused ("duplicate"), so a character can never be doubled.
- Discovery answers carry no identities, and joining sends no other player's private data.
- The world stops when the host stops. A guest is told "Host disconnected" and goes back to the title.
  When the host plays again, guests rejoin their own characters.
- The save gains an optional `guests` key. Older saves have none and load unchanged; older builds ignore it.
  No save version bump was needed.

## 4. Discovery and its fallback

- Discovery uses UDP port 47811. A guest broadcasts `MML_DISCOVER/1` once a second, and every host replies to that guest directly.
- The game itself uses ENet on UDP port 47810.
- **Fallback when discovery fails:** routers with client isolation, guest Wi-Fi, some phone hotspots, and firewalls on PCs can all hide games.
  - Join Nearby Game → Advanced → "Join by address": type the host's local address (e.g. 192.168.1.20).
  - Windows asks to allow the game through its firewall the first time it hosts. Allow it on private networks.

## 5. Android notes

- **Permissions** (Android export preset, this branch): INTERNET, ACCESS_NETWORK_STATE, ACCESS_WIFI_STATE, CHANGE_WIFI_MULTICAST_STATE and WAKE_LOCK.
  - The game never used the network before, so this is new.
  - Discovery uses unicast replies, so a guest needs no multicast lock. An Android host receiving broadcasts may need one on some phones (phase 4).
- **Sleep:**
  - A hosting device keeps the screen on (`DisplayServer.screen_set_keep_on`).
  - If the host's app is sent to the background, Android pauses it, and the world stops for everyone, as when the host quits.
  - A guest sent to the background loses its connection. Rejoining restores its character.
- **Text entry:** name, password and address boxes close the phone keyboard on Enter or when focus leaves.

## 6. The shared-interaction pattern (for every future shared system)

1. **Request.** A guest never changes the shared world itself. It sends `request(kind, args)`.
2. **Validate.** The host checks the request in `NetActions.apply` against its own world: the asker's reach, the thing's current state, and the asker's means.
3. **Apply once.** On success the host changes the world, gives the result to the asker's character on the host, and answers with what was gained. The guest adds exactly that to its own copy.
4. **Order.** Requests are handled one at a time in arrival order on the host. The host's own actions run in the same simulation, so when two players reach for the same thing, the second finds it gone. Nothing can be made twice.
5. **Refuse.** Unknown kinds, malformed arguments and out-of-reach requests get a plain refusal.

Implemented so far: `pick_fruit`. To add next, each with a two-player test:
- buying the last unit of an item (`Business`);
- harvesting a node (`ResourceNodes`);
- using a station (the existing reservations);
- taking from a container (`Chests.take`);
- handing items between players;
- damaging an animal or a villager (one blow at a time, `Combat` on the host).

## 7. Systems that assume one player (what multiplayer has to change)

Counts are references to the single player, by file:

| File | Refs | Notes |
|---|---|---|
| `main.gd` | 188 | Input, camera, targets and UI; per machine, mostly fine |
| `world.gd` | 76 | |
| `game_ui.gd` | 71 | |
| `business.gd` | 39 | |
| `quests.gd` | 36 | |
| `life.gd` | 21 | |
| `property.gd` | 17 | |
| `construction.gd` | 13 | |
| `chests.gd` | 13 | |
| `fitting.gd` | 8 | |
| `carts.gd` | 7 | |
| `inventory_window`, `chest_window`, `stall_window`, `dialogue` | 5–7 each | |
| `npc_brain`, `fauna`, `farming`, `manor_work` | 3–5 each | |

| System | Assumption now | Needed |
|---|---|---|
| Ownership (`World.PLAYER = "player"`, `PLAYER_ID = -2`) | One party called "player" owns land, shops, carts and chests; villagers target -2 | A party per player (e.g. `player:<hash>`), and NPC targets naming which player |
| Crime and guards | `player.crimes`, `stolen` marks and guards chasing "the player" | Per player, and guards choosing whom to chase |
| Quests | Offers and progress for one player | Per player |
| Business, storefronts, attendants | `Business.mine()` returns the player's stall | Per player |
| Needs (hunger, stamina, health) | Updated for `world.player` only | The host updates every guest's needs (frozen in this milestone) |
| Death and heirs | One family line | Each player's line, in that world |
| Property and rent | One tenant called "player" | Per player |
| Villagers' memories and talk | "met <player name>" | Per player name, then identity |
| Wildlife and bandits | Hunt or attack the one player near them | The nearest player |
| Saving | One `player` | Done for guests (`World.guests`), and the host's own player unchanged |
| Combat (`Combat`, CQ-01) | Swings run on the machine that pressed | Guest swings as host-validated requests |

Guests can only walk in this milestone. Working, fighting, trading, building and the pack are
blocked on a guest with a plain message (`main.guest_blocked`).

## 8. Measurements (automated, loopback, from `net_test.gd`)

- **Guest traffic:** about 0.8 KB/s up and 10 KB/s down with one guest. The download is mostly villager snapshots.
- **Host:** about 9 ms of script time per frame, about 237 MB static memory and 106 villagers alive while hosting (headless, this cloud machine).

Not measured yet:
- Over Wi-Fi, where latency and loss are real.
- With four players.
- Movement smoothness on a phone.
- Client CPU on Android.
- Reconnection after a real network drop.

## 9. Roadmap

| Phase | What | State |
|---|---|---|
| 1 | Two players on a LAN: this milestone | Built and passing on loopback; real-device check outstanding |
| 2 | Four players on a LAN | The cap is a setting (2 to 4); needs a four-process test |
| 3 | Shared inventories, crafting, commerce, harvesting, combat and world interactions | Through the request pattern (section 6), one system at a time, and the per-player party ids (section 7) |
| 4 | Android hosting and cross-platform stability | Needs real devices |
| 5 | Internet play with simple friend invitations | Only if it needs no paid relay. Options: port forwarding, or ENet with a free NAT-traversal service; to decide then |

## 10. Running the tests

```sh
godot --headless --path game --script res://tests/net_test.gd
```

It starts its own host and extra guests and picks ports from its process id. It needs
UDP on 127.0.0.1.
