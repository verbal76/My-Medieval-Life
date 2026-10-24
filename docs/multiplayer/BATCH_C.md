# Multiplayer Batch C: full gameplay parity, gate G2

Branch `wip/multiplayer-b19`, on Batch B (`805a1c9`). Requirements: `MULTIPLAYER_PREPARATION.md` section 6 (C1-C7) and section 10
(G2: two-player tests per system on the host's rules, census before and after), the owner's Batch C directive
(`docs/directives/2026-10-24_multiplayer_batch_c_g2.md`) and decisions MP-D1..D8. Register: MP-ARCH (the lead edits the register;
this branch does not). **No menu hosts or joins a game** (Batch D): nothing here is reachable by a player yet.

## 1. The design in four parts

| Part | What | Where |
|---|---|---|
| A player is their own person | A player's **person id** stands for them wherever a villager's id would: ties, Good and Bad ledgers and facts (judgment), family links, NPC targets, reports, feasts. The host's line keeps the legacy -2 (ID-D1); a guest's line is the negative of its line's pid (`World.person_id`), recognised without a world (`Life.is_player_id`: -2 or at or below -1,000,000). `"player:<line>"` and `-line` name one line; a guest heir keeps both | `World.person_id`, `acting_id`, `player_of_id`, `ref_of_id`, `id_of_ref`, `id_of_party`, `player_for(ref)`; `PlayerState.party` (so `Contracts.ref_of` names a guest) |
| Every verb a request | On a guest's machine every player verb the interface calls is sent to the host (`World.mirror`: a two-line prologue in each verb of `NetActions.VERBS`) and also run locally, only so the interface answers at once. The host decodes the arguments in its own world (villagers, players, animals by id; records by kind and key; the guest's pack and chest by name; `NetActions.dec`), refuses an unknown verb, anything naming another player (reference, person id, character, store) and what is beyond 24 tiles, and calls the same verb as the guest (`World.as_actor`): the same rules, no guest-only path | `World.mirror`, `NetActions.VERBS`, `apply_verb`, `enc`, `dec`, `NetSession.send_verb` |
| The guest's copy follows | The host sends each guest the sections of `World.to_dict` whose hash changed since that guest last had them (after each of its requests, then every 3 s); the guest takes them in place (`NetSync.adopt`: the same objects, the host's values; villagers keep the snapshot's place). Its own character comes whole (`Main.adopt_own_state`). Coins and goods exist only on the host | `NetSync`, `NetSession.send_syncs`, `s_sync` |
| The world's own work covers every player | Daily and hourly processes that served "the player" serve each: rent and wages of each player's premises, attendants and buyers, cart deliveries, quests lapsing, decay of packs and chests, villagers' asks (put to one player, answered by that player), stations held apart, animals and bandits choosing among players | `Business.all_premises`, `Carts.hour`, `NPCBrain` dawn, `Decay.dawn`, `Credit._cheapest_food`, `World.players_at`, `Fauna`, `NPCBrain._prey_for` |

Single player has one player: every id is -2, every loop runs once, `World.remote` is unset, so nothing differs from Build 19/20 (G0).

## 2. G2: the per-system parity checklist

"Parity" (`multiplayer_c_test.gd::parity`): the same verb, done by the host in one world and by a guest in an identical world (the other
player standing elsewhere), gives the actor exactly the same outcome (purse, pack, health, skills, crimes, case and tier, killings,
notoriety, ties, Good and Bad ledgers, quests, home, partner, plots held, carts, contracts, debts, chest, level, tool) and the same
answer; the other player is untouched; coins are conserved. "Network": `net_c_test.gd`, the guest's own interface verb applied by the
host, both machines' records of the guest agreeing and every synchronized section identical on both machines, coins conserved.

| Sub-batch | System | Parity (one process) | Network (loopback) | Status |
|---|---|---|---|---|
| C1 | eating, medicine, equipment, dropping and picking up | eat; equip and unequip; drop and loot | eat | PASS |
| C1 | needs and health | per-player ticks (A1); a blow wakes a resting player | own record agrees each second | PASS |
| C1 | death and succession (MP-D4) | guest heir is its own child, its line's id and reference kept, host untouched | guest death and heir: `net_batch_b_test` (B) | PASS |
| C1 | rest by agreement (MP-D2) | one rests in real time, the second makes the night pass; wake by acting, by a blow; single player unchanged | the guest rests in real time, the clock does not jump; wakes | PASS |
| C1 | menus never pause a session (MP-D3) | (A2) | (A2, `net_g1_test`) | PASS (A2) |
| C1 | walking in the core | `World.step_ok` for every player (the host checks guests by it) | the guest walks, the host has it there (`net_g1_test`) | PASS |
| C2 | gathering | pick a wild plant; two players reach for one plant (first gets it, goods once) | pick a plant | PASS |
| C2 | mining, felling | mine a seam; fell a tree | (one-process) | PASS |
| C2 | crafting, stations | craft a first-level recipe; stations held apart, one freeing only its own | (one-process) | PASS |
| C2 | inventory, chest, decay | drop/loot; decay of every player's pack and chest | own pack agrees | PASS |
| C3 | trade | buy; sell; a shared transaction without duplication; the trade contact is the buyer's own | buy from a villager | PASS |
| C3 | contracts, credit | propose a contract; a villager's ask put to the guest, answered (or refused) by the guest only | (one-process) | PASS |
| C3 | quests | the guest's quest on its own list, the offer taken once, its lapse the guest's only | (one-process) | PASS |
| C3 | employment, manor work, couriers | verbs in the catalog, each sent and applied as the guest | (catalog check) | catalog only |
| C4 | property, plots | buy a plot | (one-process) | PASS |
| C4 | stalls, shops | rent a pitch; premises per player (`shop.by`), daily rent from each player's purse | (one-process) | PASS |
| C4 | carts | set a cart down | set a cart down, the cart the guest's | PASS |
| C4 | farms, pens, construction, fittings | verbs in the catalog | (catalog check) | catalog only |
| C5 | conversation, gifts, ties | talk and give; one villager, two players: each tie its own; closeness its own; a newcomer from nothing (MP-D7) | talk and give: the tie the guest's on both machines | PASS |
| C5 | courtship, marriage, families | two families: each player partners a villager; the guest's child; the guest's heir | (one-process) | PASS |
| C5 | marriage and gifts between players (MP-D8) | offer, accept, decline, lapse, save; marks travel with goods | (one-process; the verbs are in the catalog) | PASS |
| C5 | guardianship, feasts | by person id (code); verbs in the catalog | | code only |
| C6 | crime and justice | strike a villager; pick a pocket; one guilty, one innocent (record, case, Bad ledger, ties, reports, the guard told) | strike: the guest's record and case, the host innocent | PASS |
| C6 | animals, bandits, family protection | a beast struck by the guest fights and bites the guest; a bandit stalks the player near it; A7 threats by player id | | PASS |
| C6 | the hue and cry (owner decision) | voice to voice; a guard out of earshot of every voice hears nothing (`manhunt_test`) | | PASS |
| C7 | underground levels | go below through the adit (the actor's level only) | | PASS |
| all | verbs catalog | every `NetActions.VERBS` entry resolves and is sent by its own verb (130 verbs) | refusals: unknown verb, another player's reference, out of reach, another character | PASS |
| all | host save and restart, several players | | two guests across a host restart, each back as itself | PASS |
| all | disconnect mid-transaction, reconnect | | `net_batch_b_test` (B, unchanged) | PASS |
| all | save 22, migration | round trip; the Build 20 save; a save 21 with a guest; idempotent; SaveTransfer | | PASS |

"catalog only" and "code only": the verb is sent and applied as the guest by the same mechanism the passing rows test, and the code
reads the player by id or reference; no dedicated scenario yet.

## 3. Save format 22

`World.SAVE_VERSION` 21 to 22 (`mml-save/22`), because a guest's person id (negative, at or below -1,000,000) appears in records an
older build reads as villagers' ids; an older build refuses a save 22 (`SaveStore.inspect`: "newer").

- New optional keys: `player_offers` (MP-D8), `credit.refused_by` (a guest's refusals), a shop's `by` (a guest's shop), a credit ask's
  `to` (an ask put to a guest). Each is written only when set; a single-player save gains none of them.
- **From 21** (`World.migrate_21_to_22`, run by `World.load_dict` and `SaveTransfer.MIGRATIONS`): everything is kept. The single
  player is the host by its permanent pid and -2 in person-id records (ID-D1). What a save 21 held under -2 stays the host's line's:
  a guest's ties and opinions in a save 21 were everyone's and cannot be split by person; a guest's facts keep their `by:player:<pid>`
  tag, which the talk reads (`EventTalk.person_of_id`). One record is unambiguous and is moved: a villager's report on a guest's crime
  (offender -2 with the guest's reference) names the guest's own id. The step is idempotent (a 22 is returned as it is).
- Fixtures: `game/tests/fixtures/b20_save_v21_single.json`, written by the unmodified Build 20 code (`56c24cb`) through
  `Main.save_game` (`game/tests/gen_b20_save_fixture.gd`); `game/tests/fixtures/mp_save_v21_guest.json`, a save 21 with a guest,
  written by the Batch B code (`805a1c9`, `game/tests/gen_v21_guest_fixture.gd`).

## 4. Owner decisions applied

- **MP-D2** rest by agreement; **MP-D4** a guest's death and heir by the established succession, now with its own family; **MP-D7** a
  newcomer with no standing and the story quests; **MP-D8** both players' consent for partnership and gifts.
- **Hue and cry** (directive section 5): local propagation from voice to voice within earshot; the bell heard within its reach, not
  everywhere. `manhunt_test` was restaged for it (below).
- **Known killers and shops**: no rule added; the existing judgment decides.

## 5. Changed test inputs (no assertion weakened)

| Test | Old | New | Why |
|---|---|---|---|
| `multiplayer_a1_test.gd` | `int(d.save_version) == 21 and World.SAVE_VERSION == 21` (three checks) | `== World.SAVE_VERSION and World.SAVE_VERSION >= 21` | the bump to 22 is the change |
| `manhunt_test.gd` (guest killer and courtship) | `ask_court(Life.PLAYER_ID, single)` as the guest | `ask_court(w.person_id(gu), single)` | a guest now courts by its own id; the assertion (refused) is the same |
| `net_host.gd` (`endow`) | `on_gift(w, Life.PLAYER_ID, v, ...)` as the guest | `on_gift(w, w.person_id(g), v, ...)` | the same |
| `net_g1_test.gd` (the guest walks) | read the host's record of the guest 0.6 s after walking | the same, then wait up to 3 s for it to match (`until`) | under load the host's status lagged the guest's last steps (it now also sends world sections); the assertion (< 0.3 tiles) is unchanged |
| `manhunt_test.gd::test_hue_and_cry`, `test_guard_struck` | a guard 20 tiles off hears the cry directly | the cry reaches the guard through a villager who takes it up; a new check: a guard within the cry's reach but out of earshot of every voice hears nothing | the owner's decision changes how the cry spreads; every earlier assertion still holds |

## 6. Evidence (2026-10-24)

On the checkpoint `3d988d0` (an exact copy of the commit, nothing edited during the runs):
- **G0** (`python3 tools/sim_gate.py`, baseline untouched): **PASS, identical** (seed 1 day 30 `60742ce2...`, seed 2 day 30 `573d6000...`),
  currency and item leaks 0.
- **SIM-GATE-01** (`tools/sim_suite.py --jobs 4`): **PASS**, 0 blocking findings, accepted baseline identical, determinism and recorder
  neutrality identical (744 s).
- **Full `tests.yml` Godot inventory** (111 scripts, 4 in parallel, each its own data dir, `$RUNNER_TEMP` set): 110 exit 0, 0 script
  errors, 11,354 checks, 1 failure: `net_g1_test` "traffic stays small" (20.1 KB/s down against its 20 KB/s, the section sync's
  villagers' records every 3 s). Fixed in the next commit (the villagers' records go on the timer every fifth time, at once after a
  request): `net_g1_test` 44/0 (15.0 KB/s down), `net_batch_b_test` 44/0, `net_c_test` 35/0 on it. The fix touches only
  `scripts/net/` (no simulation code), so G0 and SIM-GATE stand.
- `multiplayer_c_test` 241 checks, `net_c_test` 35, `manhunt_test` 60, `run_tests` 3,598, `start_test` 523: 0 failures.
- `python3 -m unittest discover -s tests`: 140 OK (in the repository; in a plain copy without git two register tests cannot run).
- `check_interactions` 303, 0 problems; `check_requirements` 0 problems.
- An earlier run (before `3d988d0`) had `world_test` fail with one failing check and 87,984 script errors: one root cause, `main.BODY`
  gone when walking moved into the core (the test reads it each frame); `const BODY := World.PLAYER_BODY` in `main.gd` restored it.

## 7. Incomplete in Batch C (no dedicated passing test yet)

- Employment (villagers hired by a player), manor work, couriers' bookings, farms and pens, construction sites and fittings,
  guardianship (adoption by a guest), feasts: their verbs are in the network catalog and sent and applied as the guest by the same
  mechanism the passing rows test, and their code reads the player by id or reference, but no scenario runs them for a guest.
- The other players' private records are not sent to a guest (public looks only), so a guest's copy cannot show another player's
  stall stock or partner; the shared sections (stalls, contracts...) do show what is in the world.
- Fauna (animals' places and pens) is not synchronized to guests.

## 8. Left for Batch D and later

- Menus to host and join; Android permissions; real devices and networks (G3-G8). Taking over a stale connection (MP-D6).
- Three and four players, performance of section synchronization with many villagers (Batch E: the sync sends whole sections).
- Owner question: should a marriage between two players have children? Today births need a villager parent, so none come.
- Animals' positions are not yet synchronized to guests (they render as at join); fauna is a host-only section for now.
