# MP-INTERACT-01 audit: player-to-player selection and interaction

Register record MP-INTERACT-01 (owner directives `docs/directives/2026-10-27_multiplayer_interaction_release_blocker.md` and
`docs/directives/2026-10-27_mp_interact_begin_now.md`, section 3). Branch `wip/x20-mp-interact`, starting commit `4f50ffb`
(the Expansion 20 integration commit "Merge the journal pager fix"). Line numbers are those of `4f50ffb`.

Playtest evidence: on Windows the owner saw Bob (Android) but could not select him or open any interaction with him.

## 1. What exists (backend)

| Function | Where | What it does | Reached from the interface? |
|---|---|---|---|
| `World.player_offer(kind, to_pid, item, qty)` | `game/scripts/core/world.gd:923` | MP-D8 consent offer between two players: kinds `partner` and `gift` only; refused unless the two stand within `OFFER_REACH` (3 tiles) on one level, alive, in play; one offer of a kind per pair | Only through `GameUI.show_players` |
| `World.player_answer(id, accept)` | `world.gd:942` | The recipient (only the offer's `to`) accepts (rechecked, then done once) or declines (removed) | Only through `GameUI.show_players` |
| `World.offers_to / offers_from` | `world.gd:881`, `:886` | Today's offers to / from a player | `main._beside_player`, `main._process` notice, `show_players` |
| `World._lapse_offers` | `world.gd:995` | Offers lapse at the end of their day | (daily) |
| `World.player_of_ref`, `player_by_pid`, `person_id`, `player_ref` | `world.gd:747-1168` | Stable player identities (pid, `"player"` / `"player:<line>"`, person ids) | yes |
| `World.trade(buyer, seller, id, qty, price_each)` | `world.gd:1328` | The one atomic sale (goods and coins together or nothing), for NPC or PlayerState parties | NPC trade windows only; never between two players |
| `Contracts` (CON-01/02) | `game/scripts/core/contracts.gd` | Negotiated procurement: one record for player-NPC, NPC-player, NPC-NPC; coins set aside at acceptance, paid per unit delivered, lapse at deadline, offers lapse after `offer_days` | Talk window with a villager only; **no player-to-player path** (`propose` takes an NPC seller, `counter_offer` answers with the NPC buyer's rule) |
| `NetActions.VERBS` (`player_offer`, `player_answer`) | `game/scripts/net/net_actions.gd:53` | A guest's verb is applied by the host as that guest (`apply_verb`); `dec` refuses another player's reference, person id, `$pid` or store; `to_pid` (a positive pid) passes as a plain int, so the offer names its recipient without acting as it | yes |
| `NetSync` section `player_offers` | `game/scripts/net/net_sync.gd:23`, `:175` | The guest's copy takes the host's offers | yes |
| Save | `world.gd:5541` (write), `:5956` (read) | Optional `player_offers` {next, list}; fields id, kind, from, to, item, qty, day | yes |
| Messages journal | `World.player_tell` (`world.gd:862`), `GameUI.message(text, s, category)` (`game_ui.gd:1258`) | A message shown with a category is kept in the acting player's journal (host-side for a guest, by `World.mirror`) | yes |

## 2. What the interface reaches (the defect)

1. **Another player is never a target.** `main._find_target` (`main.gd:2667`) lists villagers (`world.present`), containers,
   counters and stalls, desks, loot and animals, then the resource in front, then everything at the player's feet. It never
   looks at the other players. `_find_target_below` (`main.gd:6615`) the same below ground. So another player gets no prompt
   line, no place in `target_options`, cannot be reached by Next / Q / Tab / the D-pad (`cycle_target`, `main.gd:3007`), and
   Use / E / A never opens anything for them.
2. **The players window is reachable only with nothing else in reach.** `main.interact` (`main.gd:3328`) opens
   `GameUI.show_players` (`game_ui.gd:2119`) only in the `target.is_empty()` branch, through `_beside_player`
   (`main.gd:1235`). In a village a villager, a stall, a station or a door is nearly always in reach, so the branch is almost
   never taken: this is the playtest's failure on every platform, not Android's alone.
3. **Tap and click never pick a player.** `main._tap` (`main.gd:5227`) takes a tapped villager from `_creature_at`
   (`main.gd:4415`), which looks at villagers and animals only; a tap or left click on another player's character falls through
   to "walk there" (or, within 1.8 tiles, to Use on whatever else is the target). Right-click strikes `_creature_at` only.
   `_tap_below` (`main.gd:6578`) the same underground.
4. **Talk (T, Y, "Tap them") is villagers only.** `talk_alt` (`main.gd:2921-2927`) and the T / Y handling in `_player_step`
   (`main.gd:2416-2420`) take only kinds `npc` and `shop`; with a player chosen, Y on a pad would cast Fireball.
5. **No outline or mark.** `outline_cells` (`main.gd:6408`) draws things only; characters have none, so nothing shows which
   player is chosen.
6. **The notice points nowhere.** `main._process` (`main.gd:1851-1857`) says "X asks you something: press Use beside them to
   answer", but Use does the current target (2 above), and once the two have parted there is no way to the window at all.
7. **The guest's copy of the other players is stale.** `NetSession.s_players` (`net_session.gd:446`) moves the other players'
   records but never updates `map_level` or `away`; `players_list` (`:750`) does not send the level. A guest's copy keeps the
   level and the away flag of its welcome, so level checks on the guest are wrong after anyone takes the adit.
8. **A guest's answer shows a wrong result.** On a guest every verb also runs on the local copy (`World.mirror`,
   `world.gd:833`), and its result is what the window shows. `player_answer` there checks the offerer's pack, which a guest's
   copy holds only as the public record (empty: `NetSession.public_player`, `net_session.gd:266`): accepting a gift from the host
   says "You do not have that." though the host then does it. The offerer is never told the answer.
9. **Contracts between two players cannot work as written.** `Contracts.face_to_face` (`contracts.gd:136-145`) assumes one
   party is a villager (`var n: NPC = b if a is PlayerState else a`), so two players would fail the cast.

## 3. What is missing (against the directive, sections 4-9)

| Directive item | State at `4f50ffb` | Needed |
|---|---|---|
| Players in the normal target list, stable identity, name, reach, level, alive, connected, never self, deterministic | missing | a `player` kind in `_find_target` / `_find_target_below` |
| Tap, click, Use, Talk, Next / Q / Tab / D-pad for a player | missing | `_player_at`, the tap path, `talk_alt`, T / Y |
| An outline on the chosen player | missing | a mark at the player's feet |
| Named, compact player menu | `show_players` lists everyone in reach, untitled by name | `show_player(pid)`: the one player, named; the list kept as a supplement |
| Conversation | none (no text between players) | the smallest text message, host-validated, never read by villagers |
| Gift with consent | backend done (MP-D8), unreachable | reach it |
| Trade of goods for coins | none between players | an offer of goods for a price, settled by `World.trade` on acceptance |
| Contracts | none between players | a goods contract offered by the buyer, accepted by the seller: the CON-01 record and rules |
| Partner / family consent | backend done (MP-D8, MP-PLAYER-FAMILY), unreachable | reach it |
| Notification and journal for the recipient, confirmation to the offerer | the notice exists, the offerer learns nothing | a named notice with a way to the requests; the answer sent back as a note |
| Requests answerable until answered or expired, world never paused | lapse at day end; window does not pause | a way to the requests from anywhere (the pause menu) |
| Host authority and security | in place | keep; the new verbs name their recipient only |
| Tests through the interface | backend tests only (`multiplayer_c_test`, `net_family_test` call `player_offer` directly) | input-driven tests, one process and loopback |

## 4. Fix (summary; details in `docs/SYSTEM_INTERACTION_MANIFEST.md` INT-560 to INT-562, `docs/DECISIONS.md` 2026-10-27)

See the branch's commits. Players become targets of kind `player` beside villagers in the same list and order; the player
menu (`GameUI.show_player`) offers Talk (a short message), Gift, Sell (goods for coins), Contract (goods), Partner, and the
requests from that player; every request is a `World.player_offer` record answered by `World.player_answer`, with the
answer returned to the offerer as a note; the guest's copy of other players follows their level and presence.

## 5. Changed test inputs (no assertion weakened)

| Test | Old | New | Why |
|---|---|---|---|
| `multiplayer_c_test.gd::test_verbs_catalog` | every verb but `player_rest` must contain `mirror("<path>"` | `player_rest` and `player_answer` must contain `remote.call("<path>"` | a guest's answer is sent without a local run (its copy cannot know the other's pack); the assertion "every verb is sent by its own verb" is unchanged |
| `net_host.gd` | (commands) | new commands `stage`, `clear_villagers`, `face`, `key`, `pad`, `click_pid`, `press`, `picker`, `close`; status `ui`, `offers`, `spot` | additive, for `net_interact_test.gd`; earlier tests do not use them |

## 6. Evidence (branch `wip/x20-mp-interact`, Linux, headless Godot 4.7.2)

| Suite | Checks | Result |
|---|---|---|
| `mp_interact_ui_test` (new, one process, real input) | 112 | 0 failures |
| `net_interact_test` (new, three processes over loopback) | 67 | 0 failures, three consecutive runs |
| `multiplayer_c_test` | 340 | 0 failures |
| `net_c_test`, `net_batch_b_test`, `net_family_test`, `net_ui_test`, `net_fauna_test` | 35, 44, 22, 61, 13 | 0 failures |
| `multiplayer_a1_test`, `multiplayer_b_test` | 67, 31 | 0 failures |
| `net_g1_test` | 44 | 1 failure, **the same at the starting commit `4f50ffb`** (not caused here): "the guest eats a bread: the host applied it once" counts two requests, because the guest's notice of the reply is now journalled (`net.changed` to `ui.message(..., "game")`, GP-MESSAGE-JOURNAL), a second request |
| `run_tests`, `start_test`, `world_test`, `x20_android_ui_test`, `message_journal_test` | 3,600, 523, 339, 95, 50 | 0 failures |
| `contracts_test`, `contract_sign_test`, `contract_50ore_test`, `gift_quantity_test`, `pad_shortcuts_test`, `trade_skills_test`, `wiki_test` | 154, 21, 16, 7, 33, 96, 140 | 0 failures |
| `python3 -m unittest discover -s tests` | 151 | OK |
| `check_interactions`, `check_requirements` | 334 interactions; 789 records | 0 problems |
| Headless export, Linux and Windows presets (unsigned) | | both build; the Linux binary starts and quits without a script error |
| Screenshots (xvfb, opengl3): 2404x1080 touch (prompt, window, sale terms), 1920x1080 keys (prompt, window), 1920x1200 pad (prompt, players list) | | looked at: the prompt names "Bob (player)" on one line with the Talk key; the ring is at Bob's feet; the window is compact, titled, with thumb-sized buttons, clear of the status box and the touch columns |

## 7. Host and guest platform matrix

"Automated" means the input path of that platform was driven in a test on Linux (touch emulation at a phone's size, mouse, keys, a
pad's events) and the network path over loopback between separate Godot processes. It is not a device test: no Android or Windows
hardware, no real network, no real controller was used.

| Host | Guest | Host initiates | Guest initiates | Status |
|---|---|---|---|---|
| Android | Android | touch (emulated) | touch (emulated) | automated (input + loopback); OWNER DEVICE NEEDED (phone hosting is not supported for internet play; LAN phone host untested on hardware) |
| Android | Windows | touch (emulated) | mouse, keys | automated; OWNER DEVICE NEEDED |
| Android | Linux | touch (emulated) | mouse, keys | automated; OWNER DEVICE NEEDED |
| Windows | Android | mouse, keys | touch (emulated) | automated; OWNER DEVICE NEEDED (the playtest pair) |
| Windows | Windows | mouse, keys | mouse, keys | automated; OWNER DEVICE NEEDED |
| Windows | Linux | mouse, keys | mouse, keys | automated; OWNER DEVICE NEEDED |
| Linux | Android | mouse, keys | touch (emulated) | automated (this is the loopback test's own setup); OWNER DEVICE NEEDED for the phone |
| Linux | Windows | mouse, keys | mouse, keys | automated; OWNER DEVICE NEEDED for the Windows PC |
| Linux | Linux | mouse, keys | mouse, keys | automated end to end on this machine (three processes); a real two-machine LAN is still OWNER DEVICE NEEDED |

Controller: pad events (D-pad, A, B, Y) were driven on both sides; a physical controller on each platform is OWNER DEVICE NEEDED.
The game code is the same on every platform (no platform branch in the paths changed), so the remaining risk is the device itself:
touch accuracy on a real screen, a real controller's mapping, the Windows firewall and the network.
