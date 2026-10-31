# Multiplayer branch audit: `wip/multiplayer` against Build 15 and staging (MP-A, read-only)

> **Status (DOC-RECON-01, 2026-10-31): HISTORICAL.** This document is an audit of the superseded `wip/multiplayer` prototype. It is not a current instruction. Current status:
> `docs/expansions/MULTIPLAYER.md`. Precedence: `docs/expansions/README.md`. Content below kept unchanged.

Prepared 2026-10-21 on `wip/roadmap-docs` as the Master Expansion Roadmap's MP-A documentation action. Read-only: no
merge, no checkout of the branch into staging, no Godot run. The two-instance run itself (MP-B) is a later task.
Merging `wip/multiplayer` into staging needs the owner's explicit authorization (CLAUDE.md section 0 step 8; register
MP-01 and CRT-03 notes; the 2026-10-19 directive section 11).

**Labels.** **FACT** (read from git or code) · **APPROVED** (owner source cited) · **PLAN** (this audit's proposal) ·
**OPEN DECISION**.

## 1. Exact references

| Ref | SHA | Date | Note |
|---|---|---|---|
| `origin/wip/multiplayer` | `d18d7d14fe9ae6b7b352841623a650a3003a150e` | 2026-10-19 18:47 UTC | "Add a two-player LAN multiplayer prototype (MP-01, isolated branch)" |
| Its base (merge-base with staging) | `3e283b6` | 2026-10-19 | "Fix sword attacks that dropped presses and needed sprite overlap (CQ-01)" |
| Build 15 | `a8760be` | 2026-10-20 | Current private testing build named in CLAUDE.md |
| `origin/staging/my-medieval-life` | `b3bbb1c` | 2026-10-21 15:34 UTC | Head at audit time |

- FACT: the branch is **one commit** (`d18d7d1`) on top of `3e283b6`.
- FACT: `d18d7d1` is **not an ancestor of `a8760be`** (Build 15) nor of staging; no `game/scripts/net/` exists in
  either; Build 15's Android preset has `permissions/internet=false`. **Multiplayer is not in Build 15** and has never
  been in a build. The Master Roadmap's caution ("NOT verified as a shipped Build 15 feature") is confirmed.
- FACT: register MP-01 is ACTIVE DEVELOPMENT, branch `wip/multiplayer`, commit `d18d7d1`, tests "net_test (36,
  separate processes)", target `multiplayer` (isolated until the owner authorizes integration). DGA-D3 "Connectivity
  with no server" is an agent proposal marked PARTIALLY IMPLEMENTED (LAN first approved via MP-01).

## 2. What is implemented on the branch

From `d18d7d1` (20 files, +1551/-4) and its `docs/MULTIPLAYER.md`. FACT unless marked.

| Directive requirement (2026-10-19, s.2 first milestone) | On the branch | Evidence |
|---|---|---|
| 1 Host an existing or new world | Yes: Host With Friends (saved or new world), also from the pause menu | `main.gd`, `game_ui.gd` |
| 2 Discover a host on the LAN | Yes on loopback: UDP 47811 `MML_DISCOVER/1`, unicast replies; manual address fallback under Advanced | `net_discovery.gd` |
| 3 Join from a second device | Between processes only; never between two real devices | `net_test.gd` |
| 4 Two independent characters | Yes: guests' `PlayerState` kept by the host in `World.guests` | `world.gd` (+14 lines) |
| 5-7 Movement, facing, basic animations in sync | Yes: guest moves locally, sends `c_move` at 15/s; host validates speed and open ground, corrects with `s_correct`; host sends players at 10/s, villagers within 24 tiles at 4/s | `net_session.gd` |
| 8 Disconnect and reconnect | Yes: same key restores place, pack, coins, skills; duplicate identity refused | `net_test.gd::reconnect`, `other_guests` |
| 9 Player state saved in the host's world | Yes: optional `guests` save key, keyed by SHA-256 of a per-device 128-bit key; no save-version bump | `world.gd::_guests_to_dict`, `load_dict` |
| 10 Single player unchanged | Claimed: "all single-player suites pass on the branch" (at `3e283b6`'s suites) | commit message |
| Menus, plain refusals, Android keyboard | Yes: version, password, full, duplicate, no name; keyboard closes on Enter | `game_ui.gd` |
| Shared-interaction pattern (s.7) | First action only: `pick_fruit` (request, host validates, apply once, reply). Guests can only walk; other actions are blocked with a message (`main.guest_blocked`) | `net_actions.gd` |
| Android permissions | INTERNET, ACCESS_NETWORK_STATE, ACCESS_WIFI_STATE, CHANGE_WIFI_MULTICAST_STATE, WAKE_LOCK added to the preset | `export_presets.cfg` |
| Password | Salted SHA-256 per session, never in clear | `net_protocol.gd` |
| Version check | `"mml-net/1 save-<SAVE_VERSION>"`: host and guest must match exactly | `net_protocol.gd::full_version` |

**Not implemented** (FACT, branch doc section 7): per-player ownership parties (land, shops, carts, chests use one
`"player"` party and `PLAYER_ID` -2), per-player crimes, quests, businesses, needs (frozen for guests), death and heirs,
property and rent, NPC memory of which player, wildlife and bandit targeting of the nearest player, guest combat as
host-validated requests, four-player tests, Android hosting, Internet play. CRT-03 (player-to-player courtship) is
APPROVED, NOT STARTED.

## 3. Tests on the branch

- FACT: `game/tests/net_test.gd` (273 lines) with helpers `net_host.gd` and `net_guest.gd` drives **real separate
  Godot processes** over ENet on 127.0.0.1, ports chosen from the process id. Areas: discovery (no identities in
  replies), refusals (version, password, duplicate identity, full), joining, movement both ways with distance checks,
  a refused 30-tile jump, traffic bound (< 20 KB/s down, < 5 KB/s up), shared fruit picks (granted once, refused when
  already picked or when the host picked first, unknown and out-of-reach requests refused), reconnect with the same
  character, host restart from its save, the save holding only the key's hash.
- FACT: the commit reports **36 checks passing** and all single-player suites passing; the branch adds `net_test.gd` to
  `.github/workflows/tests.yml`, but that workflow runs only on pushes to `staging/my-medieval-life` (and by hand), so
  **no CI run on the branch is on record**. The 36-check figure is the author's report, not re-verified here (no Godot
  in this task).
- FACT: measured on loopback: about 0.8 KB/s up and 10 KB/s down with one guest; about 9 ms host script time per
  frame and 237 MB static memory headless with 106 villagers. Not measured over Wi-Fi, with four players, or on a
  phone.

## 4. Divergence

| Measure | Value (FACT) |
|---|---|
| Staging commits since the branch base | 254 (`3e283b6..b3bbb1c`) |
| Build 15 commits since the base | 101 (`3e283b6..a8760be`) |
| Staging change since the base | 252 files, +73,230 / -1,066 |
| Save version | 14 at the base and at Build 15; 16 on staging; 17 on `wip/build17` |
| Files the branch touches that staging also changed | `world.gd` (+736/-60 on staging), `main.gd` (+472/-53), `game_ui.gd` (+323/-16), `tests.yml` (+39/-1); `export_presets.cfg` unchanged on staging |
| References to the single player (word `player`/`PLAYER`/`PLAYER_ID`) | `world.gd` 161 -> 204, `main.gd` 275 -> 303, `game_ui.gd` 88 -> 108, `npc_brain.gd` 15 -> 39; new single-player-aware modules since the base: `relations.gd` (38), `guardianship.gd` (25), `farm_plots.gd` (17), `stalls.gd` (14) |

**Trial merge** (`git merge-tree --write-tree`, nothing written to any branch): against staging `b3bbb1c` and against
Build 15 `a8760be`, textual conflicts in **two files** (three hunks) each:
1. `game/scripts/core/world.gd::to_dict`: staging added `"relations": relations.to_dict()` where the branch added
   `"guests": _guests_to_dict()` (keep both).
2. `game/scripts/core/world.gd::load_dict`: staging added the PAR-01 skill seeding for saves before 15 where the branch
   added the guests block (keep both).
3. `.github/workflows/tests.yml`: staging added about a dozen suites where the branch added `net_test.gd` (keep both).
`main.gd` and `game_ui.gd` merge automatically.

## 5. Merge risk (semantic, beyond the textual conflicts)

| Risk | Why | Level |
|---|---|---|
| R1 New single-player assumptions | Relations (ties keyed with the player id -2), guardianship of the player's children, farm plots and stalls owned by `"player"`, PAR-05/PICK-01 crime reports naming offender -2, CON-01 contracts with a `"player"` party (`wip/build17`) | High: each must be made per-player or blocked for guests |
| R2 Guest needs frozen | Staging added needs-driven systems (rest, food security, housing); a guest who never eats is a parity hole (PAR-00: one rule set) | Medium |
| R3 Join payload size | The guest receives the whole save (`world_for`); staging's save is larger (relations, farm plots, stalls, skills, guardianship) | Medium: measure; may need compression or chunking |
| R4 Save identity and migration | `guests` key without a version bump was fine at 14; staging's `SaveTransfer` validates a round trip and carries unknown sections; a fixture with guests is needed for 16/17 | Medium |
| R5 Determinism | Host-only simulation keeps one `World.rng`; guest requests change event order, so seeded replays differ when guests act | Low for play, Medium for test gates (`economy_sim` fingerprint must run without guests) |
| R6 Underground levels | `wip/build17` adds levels (`level_map.gd`); positions in `c_move` carry no level id | Medium after Build 17 merges |
| R7 Android permissions | The branch turns on INTERNET and Wi-Fi permissions; any build containing it changes the Android manifest | Owner-visible; part of the integration decision |
| R8 Key in transit | A guest sends its raw key to the host in `c_hello`; the host stores only the hash, but an untrusted host sees the key (usable only against itself) | Low; document |
| R9 CI | Adding `net_test.gd` to CI opens UDP on loopback in the runner and spawns processes; runtime and flakiness unmeasured | Low |

**Recommendation (PLAN):** do not merge the old commit. When the owner authorizes integration, rebase or re-apply the
branch onto the then-current staging on a new `wip/multiplayer-2` branch, resolve the two `world.gd` conflicts by
keeping both, add a guest save fixture, then extend the shared-interaction pattern system by system. OPEN DECISION:
whether and when to authorize integration, and in which build.

## 6. What the two-instance test plan should contain (MP-B; to run later with Godot)

Automated (two or more processes on one machine, as `net_test.gd` does, re-run on the rebased branch):
1. Host starts a new world and a saved world; guest discovers it (and joins by address with discovery off).
2. Refusals: wrong version (including a save-version mismatch 16 vs 17), wrong password, full, duplicate identity.
3. Movement both ways with facing and animation; host refuses an impossible move and corrects the guest.
4. Reconnect: guest leaves and rejoins with the same character (position, inventory, coins, skills).
5. Host stop and restart from the save; the guest is told, rejoins, and nothing is duplicated (coin and item census
   before and after, using `economy_sim`'s ledger helpers).
6. Shared action race: both players request the same fruit, then (as added) the last unit of a stall item, a resource
   node, a chest item; exactly one succeeds.
7. Single-player regression: the full `run_tests.gd` and the short economy simulation with no guest give the same
   fingerprint as staging.
8. Save compatibility: a staging save without `guests` loads; a save with `guests` survives `SaveTransfer` round trip.
9. Traffic and host time with one and three guests (four processes), recorded, not pass/fail beyond the existing bound.

Manual, real devices (each recorded separately; automated passes never count as device checks):
10. Windows or Linux host with an Android guest on a home router; then a phone hotspot; then a router with client
    isolation (fallback by address).
11. Two PCs on a LAN; Windows firewall prompt on first host.
12. Android guest sent to background and woken: connection loss message, rejoin restores the character.
13. Touch controls and keyboard dismissal on the join and password screens.
14. Android host (phase 4 of the directive; not before 10-13 pass).

Reporting: exact SHAs of host and guest builds, platform and network for each run, pass or fail per step, and what
remains unverified (directive s.10 and s.13).
