# Multiplayer preparation: compatibility assessment, architecture, batch plan and decisions (2026-10-24)

Owner directive `docs/directives/2026-10-24_master_multiplayer_directive.md` (register MP-MASTER). **Preparation only: nothing
is implemented, merged or activated.** **Architecture approved in principle and MP-D1..D8 decided by the owner on 2026-10-24**
(`docs/directives/2026-10-24_owner_multiplayer_decisions.md`; register MP-ARCH, MP-INET; sections 5, 6 and 10 updated). Implementation starts after Build 19's owner acceptance and an explicit authorization.
Sequence: Build 19 acceptance → full multiplayer → Expansion 20.

Sources: a read-only audit of `wip/build19` (2026-10-24); the prototype `wip/multiplayer` `d18d7d1` and its notes
(`PROTOTYPE_MULTIPLAYER_2026-10-19.md`); the 2026-10-21 branch audit (`MULTIPLAYER_BRANCH_AUDIT_2026-10-21.md`), both copied here
unchanged.

## 1. Status (directive section 15)

| Stage | State |
|---|---|
| Designed | Yes: owner design 2026-10-17 (DECISIONS), directives 2026-10-19 and 2026-10-24 |
| Implemented on an isolated branch | Partly: the two-player LAN prototype `d18d7d1` (movement, identity, one shared action) |
| Integrated | **No**: in no build; Build 19 has no networking code |
| Tested locally | Prototype only: 36 checks, two processes on one machine, 2026-10-19, never re-run |
| Tested on real devices | **No** |
| Accepted by the owner | No |
| Released | No |

## 2. Build 19 compatibility assessment

**Scale.** 69 script files (about 1,100 lines) and 85 test files refer to the single player. The prototype's list of single-player
systems (about 20 files in October) has grown with credit, contracts, couriers, feasts, guardianship, mine works, open pits, the
chapel, judgment, law, identity, holdings, services and the recorder.

**What already helps.** Permanent identity (Build 19) gives every player character a permanent `pid` (band ids from 1,000,000) that
never collides with a villager; `rest_recover`, crime records (`player.crimes`, `stolen`) and much of the trade code already work on
"whoever is acting" (`who is PlayerState`); Expansion 19's judgment keys pack ids generically; overworld streaming follows each
machine's camera; touch and gamepad input are per machine.

**The ten highest-risk assumptions** (everything else depends on them):

| # | Assumption | Where |
|---|---|---|
| 1 | One `World.player` read by every player verb | `world.gd` (about 400 refs), 60+ other files; `main.gd` 291 refs |
| 2 | `Life.PLAYER_ID = -2` as the one person id in ties, family links, `NPC.target`, judgment, feasts (two duplicate constants) | `life.gd:20-21`, `feast.gd:23`, `settlement/experience.gd:37` |
| 3 | `World.PLAYER = "player"` as the one owner and party ref; `party()` returns null for it | property, business, stalls, carts, contracts, credit, couriers, manor work, pens |
| 4 | Relationship ties keyed with -2; one global `killings` and notoriety; all inherited by the heir | `relations.gd` |
| 5 | NPC combat targets: `target == -2`, bandits' `_prey_for` choosing the player, animals' `anger == "player"` | `npc_brain.gd:1767,1849,2755,2824`, `combat.gd:115`, `fauna.gd:315-364` |
| 6 | Simulation detail centred on one player (`detail_radius`) | `world.gd:342`, `fauna.gd`, `refuges.gd` |
| 7 | One global `player_level` (underground) for collision, paths, portals, loot | `world.gd:124,4946-5011`, mine works, open pit, discovery |
| 8 | One world random stream shared by player and NPC rolls | crits, work and craft rolls, pickpocket, saplings |
| 9 | Movement, action timers and projectiles in the client `main.gd`, not in `World` | `main.gd:1908,3897` |
| 10 | Succession for one player: `continue_as_heir`, `Identity.succeed`, one global former-player id -3, quest release | `world.gd:729`, `identity.gd:91`, `life.gd`, `quests.gd` |

**Shared-clock conflicts** (single player can stop or skip time; several players cannot all do so):
- **Resting** (`player_rest`, `world.gd:2472`) runs the shared world up to 12 game hours forward in a loop.
- **Menus and placement mode pause the world** (`game_ui.gd:1079`, `main.gd:3935,4025,4197`).
- **A player's death freezes the world** (`main.gd:1443`).
- Station holds, rent days, quest and contract deadlines, full-health-only-to-morning rest and hourly autosave all assume one
  person's clock.

**Saves.** One `"player"` section and one `player_level`; `SAVE_VERSION` 20. Multiplayer needs a `"players"` section and version
21, with a migration from 20 (the existing player becomes the host's character) and fixture tests.

## 3. The prototype: what to reuse, adapt or replace

| Component (`d18d7d1`) | Verdict | Why |
|---|---|---|
| `net_discovery.gd` (UDP LAN discovery, manual-address fallback) | **Reuse** | independent of game code; works as designed |
| `net_protocol.gd` (version string, salted password hash) | **Reuse, update** | version string must carry save version 21 and a protocol version |
| Identity: per-device 128-bit key, host stores only its SHA-256 hash, duplicate refused | **Reuse, bind to `pid`** | meets "no impersonation by name" and "no secrets to other guests"; the key will map to a permanent `pid` |
| `net_actions.gd` request, validate, apply once, reply pattern | **Reuse, generalize** | the right pattern; becomes the one path by which any player (host included) acts |
| `net_session.gd` ENet transport, join handshake, refusals | **Adapt** | keep the transport and handshake; replace its world model |
| Guests as a side list `World.guests`, guest needs frozen, guests limited to walking and fruit picking | **Replace** | contradicts full parity; guests become first-class players in `World.players` |
| Guest receives the whole save on joining, then position overwrites | **Adapt** | keep a join snapshot (without secrets), then interest-managed updates; the guest renders, never simulates |
| Multiplayer menus, plain-language refusals, keyboard closing | **Reuse, adapt** | to today's UI (`game_ui.gd` has changed by +323 lines since) |
| Android permissions in the export preset | **Reuse** | INTERNET, network state, Wi-Fi state, multicast, wake lock |
| `net_test.gd` multi-process harness | **Reuse, extend** | real separate processes; extend to four, to host restart, to every shared system |

The branch stays as it is (preserved); work starts on a new branch from accepted Build 19, carrying these files forward one by one.

## 4. Recommended architecture

1. **One simulation, several players.** `World.players`: the player characters by `pid`, each a full `PlayerState` with needs,
   health, skills, inventory, coins, crimes, home, family and level. The host's own character is one of them; single player is
   the case of one. No guest-only code paths.
2. **Every action is an intent applied by the host.** Input on any machine becomes an intent (move, buy, craft, strike, court…).
   On the host it calls the World verb directly; on a guest it is sent and the host calls **the same World verb with that player as
   the actor**. Every `_player_*` verb gains an actor parameter instead of reading `World.player`. Guests never create coins, items,
   NPCs, buildings or events.
3. **Ids and refs per player.** The person id in ties, family links, judgment, targets and records becomes the player's `pid`
   (no longer -2); the owner ref becomes `player:<pid>`, resolved by `party()`/`ref_id` like any household. Succession becomes per
   family line. The save migration (20 to 21) maps today's -2 and `"player"` to the host's `pid` exactly, keeping Build 18/19
   continuity (ID-D1).
4. **NPCs and animals react to whichever player is involved**: targets name a `pid`; bandits and animals choose among nearby players
   by the same rules; witnessing, alarms and guards name the offender.
5. **Detail and levels per player**: NPCs and animals are detailed near any player; each player carries their own level.
6. **Movement in the core**: walking and collision move from `main.gd` into a shared step the host validates (the prototype's speed
   and open-ground check), with prediction and correction on the guest.
7. **Replication**: a join snapshot, then the state each guest needs (its own character in full; nearby villagers, animals,
   buildings, stalls and containers; the clock), at bounded rates. The guest's world copy only renders.
8. **Determinism**: requests are applied at fixed points of the host's tick in a fixed order (time of arrival recorded, then `pid`),
   so a recorded session can be replayed; single player (no guests) keeps the Build 19 baseline exactly, which stays a release gate.
9. **Conservation**: every player's coins and goods count in `World.total_coins` and the census; networking adds no holder.
10. **Saves**: one world file on the host with all characters; guests never save.

## 5. Owner decisions (decided 2026-10-24)

| Id | Decision | What the implementation does |
|---|---|---|
| MP-D1 | Approved | A disconnected guest's character leaves active play (off the map, not acting, not targetable). Every persistent record stays in the host's world: property, coins, goods, contracts, debts, rent, relationships, family, reputation. Nothing is deleted automatically; obligations keep their own rules on the shared clock |
| MP-D2 | Approved | Accelerated rest happens only when every connected player agrees (each asks to rest); while anyone stays active the world runs at normal speed and a resting player simply rests in real time |
| MP-D3 | Approved | In a multiplayer session no individual menu or placement mode pauses the world; single-player pause is unchanged |
| MP-D4 | Modified | A death never freezes the world. The established succession mechanics apply (heir, inheritance, the village's view of the family, ID-D1), and the player is offered the choice those mechanics allow instead of an automatic transition; the world keeps running for everyone while they choose. The exact choices are those single player already has; no new succession rules are invented |
| MP-D5 | Approved conditionally | Free methods first (LAN discovery, manual address, automatic port mapping). Internet multiplayer is mandatory (MP-INET); a virtual-LAN workaround alone does not satisfy it. A practical connectivity proposal (costs, dependencies, privacy, alternatives) returns to the owner before internet support is called complete |
| MP-D6 | Modified | Android interruptions: a guest that is backgrounded or loses the network reconnects to the same character; an Android host that is backgrounded or killed suspends the world safely (save on interruption, guests told the host has paused) and recovers it when the host returns. No claim of uninterrupted background hosting without device evidence |
| MP-D7 | Approved | A new guest creates a character and arrives as a newcomer under the established world rules (housing, work, the village's opinion from nothing) |
| MP-D8 | Approved with mutual consent | Player-to-player marriage and every other action that needs both participants (courtship, gifts accepted, contracts, trades between players) require both players' consent; family, inheritance and succession work as they do today |

## 6. Batch plan (directive section 12)

| Batch | Content | Checkpoint |
|---|---|---|
| **A Foundation** | new branch from accepted Build 19; `World.players` with the host as one player; ids and refs per player and the 20-to-21 save migration; actor-parameterized verbs (no behaviour change); then the prototype's transport, identity, discovery and handshake carried forward | single player unchanged: all suites and the Build 19 baseline identical; two processes connect and hold the same world state |
| **B Persistence** | guest characters in the host's save; reconnect to the same character; MP-D1 (leave active play, every record kept); new guests as newcomers (MP-D7); duplicate refusal | host restart and guest reconnect tests; coin and item census before and after |
| **C Full gameplay** (sub-batches) | C1 movement in the core, needs, health, death and succession with the player's choice (MP-D4), rest by agreement of all (MP-D2), no menu pause in sessions (MP-D3); C2 gathering, inventory, equipment, crafting, stations; C3 economy: trade, negotiation, credit, contracts, employment, manor work, couriers; C4 property: land, rent, construction, farms, pens, chests, carts, businesses; C5 society: conversation, ties, judgment, gossip, courtship, marriage (mutual consent between players, MP-D8), families, guardianship, feasts; C6 crime and combat: theft, witnesses, guards, bandits, animals, family protection; C7 underground levels | each sub-batch: focused two-player tests on the same rules as the host; conservation; single-player baseline unchanged |
| **D Cross-platform** | Android, Windows and Linux hosting and joining; mixed platforms; LAN and the free internet methods, then the owner-approved connectivity proposal (MP-D5, MP-INET); Android lifecycle: guest reconnect, host safe suspend and recovery (MP-D6); Steam Deck controls | the nine-cell host-guest matrix on real devices (owner's devices; results recorded) |
| **E Three to four players** | simultaneous actions, conflicting purchases, shared construction, combat, several players with one NPC, disconnects, host restart, performance with normal load | sessions with four players; measured host frame time, bandwidth, memory on the Pixel 10 Pro XL |
| **F Final integration** | full regression, determinism, conservation, save integrity, security review, performance, packaging | release-readiness review for the owner; no publication without authorization |

One primary development agent throughout; focused tests while building, full suites at batch boundaries.

## 7. Effort and risk (estimates, not measurements)

| Batch | Estimated size | Main risk |
|---|---|---|
| A | large (touches most of the 69 files mechanically) | regressions in single player from the refactor; caught by the unchanged baseline |
| B | small to medium | save migration correctness |
| C | **largest**: about half the total | breadth; each system has its own one-player shortcuts; time rules (MP-D2-D4) |
| D | medium in code, large in testing | real devices, routers, NAT, Android lifecycle; depends on the owner's device time |
| E | medium | performance on Android hosting with 3-4 players and about 110 villagers |
| F | small to medium | |

Rough total: two to four weeks of development at the pace of Builds 17-19, plus the owner's device testing for Batch D. The biggest
uncertainties: Android hosting performance, and internet connectivity across mobile networks.

## 8. Networking services and costs (MP-D5)

| Method | Works for | Cost and dependencies | Notes |
|---|---|---|---|
| LAN discovery + ENet (prototype) | same network | free | routers with client isolation or guest Wi-Fi hide games: manual address fallback |
| Manual address over the internet + port forwarding | home broadband with a public address | free; the host configures the router | fails behind carrier-grade NAT (most cellular, some broadband) |
| Automatic port mapping (UPnP, built into Godot) | many home routers | free | often disabled on routers; never on cellular |
| A virtual LAN the players install (e.g. Tailscale, ZeroTier) | almost any network | free personal tiers today; each player needs that service's account | no code from us; a third-party dependency and privacy consideration for the players |
| Hole punching with a small introduction server | most home networks | a small hosted server (recurring hosting cost) | still fails for symmetric NAT (common on cellular) |
| A relay | every network, including cellular hosting | self-hosted relay: recurring server and bandwidth cost; platform relays (e.g. Steam's) are platform-locked (Steam does not cover Android) and have fees; free cross-platform relays need a developer account, an SDK and player accounts | the only method that covers cellular reliably |

**Recommendation:** Batch D starts with the free methods (LAN, manual address, automatic port mapping) and documents a
virtual-LAN fallback for players. Cellular hosting and "always connects" need a relay; before any relay work, a separate decision
with current prices, privacy terms and alternatives (prices to be checked at that time, not assumed here). No paid service is
introduced without the owner's approval.

## 10. Verification gates (MP-ARCH requirement 7)

Every gate records the exact build commit, devices, OS versions, network and the result per step; automated runs never count as
device checks (register `playtest`).

| Gate | When | Evidence required |
|---|---|---|
| G0 Single player | every batch | all suites, the Build 19 determinism baseline identical with no guests, conservation |
| G1 Two processes | A, B | host and guest processes on one machine: join, same state, reconnect, host restart |
| G2 Gameplay parity | each C sub-batch | two-player tests per system on the host's rules; census before and after |
| G3 Android | D | Pixel 10 Pro XL hosting and joining; background, lock, network change, interruption save and recovery |
| G4 Windows | D | hosting and joining; firewall prompt |
| G5 Linux | D | hosting and joining on a desktop |
| G6 Steam Deck | D | hosting and joining with Steam Deck controls, in game mode |
| G7 Mixed platforms | D | the nine-cell host-guest matrix (Android, Windows, Linux each as host with each as guest) |
| G8 Internet | D | the free methods, then the owner-approved method (MP-INET), across separate networks including mobile data |
| G9 Four players | E | a session with four players across at least two platforms; simultaneous and conflicting actions; host restart |
| G10 Release readiness | F | all gates passed, no known critical save, sync or security defect, performance on the supported hardware |

## 11. Reporting

Multiplayer appears in every status and release-readiness report until the owner accepts it, with its stage (designed,
implemented on a branch, integrated, tested locally, tested on devices, accepted, released) and the open gates.

## 12. Batch A starting point (readiness check, 2026-10-24)

Owner directive `docs/directives/2026-10-24_multiplayer_implementation_readiness.md`: the plan at `a7d88aa` is the development
requirement; implementation waits for Build 19's acceptance and the owner's Batch A authorization.

- **Base:** `wip/build19` at `42c33e0`, the Build 19 release commit `2f72ec3` plus the release packet only (no game change). If the
  owner's playtest acceptance names another commit, that commit is the base.
- **Branch:** a new `wip/multiplayer-b19`, created from that base. `wip/build19` and the Build 19 draft release (built from
  `2f72ec3`) stay untouched; `wip/multiplayer` (`d18d7d1`) stays as the reference prototype.
- **First steps:** `World.players` with the host's character as one player and every verb taking the acting player (no behaviour
  change), per-player ids and refs, and the save migration 20 to 21; G0 at the end of that step (focused suites throughout; the full
  Build 19 regression and determinism baseline at the checkpoint). Then the prototype's transport, identity, discovery and
  handshake carried forward file by file, and G1.
- **Then:** Batch B and the C sub-batches in order, with the gates in section 10.

## 9. Interactions with the roadmap

Multiplayer goes before Expansion 20 (MP-MASTER). ROAD-Q5's Batch 0 (bringing the Expansion 20 and 21 preparation branches onto
Build 19) therefore waits until multiplayer's Batch A has settled the player refs, so those branches are brought forward once,
onto the multiplayer-ready code; both are small (7 and 4 commits) and conflict only in `world.gd`. Expansions 20-27 then build on
`World.players` from the start.
