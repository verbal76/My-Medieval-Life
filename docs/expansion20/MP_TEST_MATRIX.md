# Multiplayer test matrix (Expansion 20 final validation, phase 4.5)

Owner directive 2026-10-27, `docs/directives/2026-10-27_x20_final_validation_recorder_release.md`, phase 4.5 ("Multiplayer
simulation") and phase 5 item 11; the approved design is unchanged: `docs/directives/2026-10-24_master_multiplayer_directive.md`
(a host-owned world, about three or four players, time stops when the host leaves) and
`docs/directives/2026-10-27_mp_interact_begin_now.md` (MP-INTERACT-01). Branch `wip/x20-mptest`, based on `87b69ab`
(MP-INTERACT-01 merged onto Expansion 20).

## What "automated-verified" means here

**automated-verified (loopback, this machine)**: separate Godot 4.7.2 processes on one Linux machine, each running the real game scene
headless, talking ENet over 127.0.0.1. Each platform's *input path* was driven by the events that platform produces (a screen touch
at the scene's own coordinates, a left mouse click, key presses, joypad button events), through the game's own input handlers. No
Android, Windows or Steam Deck hardware, no physical touchscreen, controller or mouse, no Wi-Fi, cellular or internet route, no
firewall and no exported build were used. A simulated screen size is not a device. Every row below therefore still needs the owner's
devices before it can be called device-validated (the register's `playtest` field).

**OWNER DEVICE NEEDED**: only a real device or a real network can settle it.

## Tests

| Test | Players | What it exercises |
|---|---|---|
| `game/tests/net_mp4_test.gd` (new) | 1 host + 2 guests, then 1 host + 3 guests; a 5th refused | every player choosing every other by tap, click, keys and pad; requests from several players applied in the same host frame; message delivery and order; every participant's copy compared with the host's; guest leave and return with offers pending both ways; a save with all guests playing; host quit and return (time stopped), host killed and return; coins and goods over all four players |
| `game/tests/net_interact_test.gd` (MP-INTERACT-01) | 1 host + 2 guests | the request flow end to end on each side's own screen: touch gift, mouse sale, pad decline, guest-to-guest message and gift, contract and delivery, disconnect mid-offer, host restart with an offer pending |
| `game/tests/mp_interact_ui_test.gd` | one process, host with two guest characters | targeting beside villagers, workstations, stalls; several players; moving players; cycling; other level; disconnected and reconnected; touch at 20:9, mouse, keys, pad |
| `net_g1_test`, `net_batch_b_test`, `net_c_test`, `net_family_test`, `net_fauna_test`, `net_ui_test`, `multiplayer_c_test` | 1 host + 1 or 2 guests | joining, refusals, persistence, verbs as the guest, family, animals, the interface at phone and desktop sizes |

The harness pieces: `net_host.gd` (the host process: commands and a status file; new: `hold`/`release` to apply several players'
requests in one frame, `freeze`/`thaw` and `dump` with `full` for a consistent snapshot, `put`, `offer`, `save`, `fell`),
`net_interact_guest.gd` (a guest process; new: an optional file tag so several can run, keys, pad, mouse, leave and join, `compare`),
`net_snapshot.gd` (new: one copy of the world against the host's frozen dump).

## Configurations

| Configuration | Status |
|---|---|
| 1 host + 2 guests (three players) | automated-verified (loopback, this machine): `net_mp4_test` (targets, a tap, a message, a full copy comparison for each guest) and `net_interact_test` (the whole interaction flow) |
| 1 host + 3 guests (four players, the design's maximum, `NetProtocol.MAX_PLAYERS`) | automated-verified (loopback, this machine): `net_mp4_test`; a fifth player is refused "full" |
| Three or four players on real devices over a LAN | OWNER DEVICE NEEDED |
| Over the internet (NAT, relay, cellular host) | OWNER DEVICE NEEDED (and the internet path itself is outside this validation: LAN and manual IP only, MP-D5) |

## Host and guest platform pairs

The code paths are the same on every platform (no platform branch in the network or interaction code); a pair differs only in which
input path each side uses and in the device and network. Both directions (host initiates, guest initiates) were driven for each
input path in the four-player test, and guest to guest as well.

| Host | Guest | Host's input | Guest's input | Status |
|---|---|---|---|---|
| Android | Android | touch | touch | automated-verified (loopback, this machine) for the input paths; OWNER DEVICE NEEDED (two phones, a phone hosting on Wi-Fi, backgrounding, sleep) |
| Android | Windows | touch | mouse, keys | automated-verified (loopback, this machine); OWNER DEVICE NEEDED |
| Android | Linux | touch | mouse, keys, pad | automated-verified (loopback, this machine); OWNER DEVICE NEEDED (Steam Deck as guest) |
| Windows | Android | mouse, keys | touch | automated-verified (loopback, this machine); OWNER DEVICE NEEDED (the owner's failed playtest pair: recheck first) |
| Windows | Windows | mouse, keys | mouse, keys | automated-verified (loopback, this machine); OWNER DEVICE NEEDED (Windows firewall prompt, two PCs) |
| Windows | Linux | mouse, keys | mouse, keys, pad | automated-verified (loopback, this machine); OWNER DEVICE NEEDED |
| Linux | Android | mouse, keys | touch | automated-verified (loopback, this machine); OWNER DEVICE NEEDED for the phone |
| Linux | Windows | mouse, keys | mouse, keys | automated-verified (loopback, this machine); OWNER DEVICE NEEDED for the Windows PC |
| Linux | Linux | mouse, keys, pad | mouse, keys, pad | automated-verified (loopback, this machine): all processes here are Linux; a real two-machine LAN and the Steam Deck are OWNER DEVICE NEEDED |

The platform a process "is" in these tests is the input path it uses; every process ran the Linux editor binary, not an exported
Android, Windows or Linux build.

## Input methods

| Input | Choosing another player | Opening their window, answering | Status |
|---|---|---|---|
| Touch (Android) | a tap on the character (Ann and Cara on three others each) | the window's buttons; the tap walks up and opens | automated-verified (loopback, this machine) as screen-touch events; OWNER DEVICE NEEDED (finger accuracy on a real screen, Pixel 10 Pro XL) |
| Mouse (Windows, Linux) | a left click on the character (the host and Dan on three others each) | the window's buttons | automated-verified (loopback, this machine); OWNER DEVICE NEEDED (a real mouse on Windows) |
| Keys (Windows, Linux) | turning to someone, Q round those in front, E (the host and Dan on three others each) | E, the window's buttons | automated-verified (loopback, this machine); OWNER DEVICE NEEDED |
| Controller (pad) | turning, D-pad round those in front, A (Ann on three others); B back to play | A, B | automated-verified (loopback, this machine) as joypad events; OWNER DEVICE NEEDED (a physical controller on Windows and Linux, the Steam Deck's built-in controls) |

Keys and pad choose among the people in front of the player, within the same short reach as villagers (`World.TARGET_PROBE`, as
designed in MP-INTERACT-01); a player two and a half tiles away is chosen by tap or click, or by stepping closer. That is the approved
targeting rule, not a defect.

## Results on this machine

`net_mp4_test` on `7ff8d8b`: **148 checks, 0 failures, three consecutive runs** (191 s, 194 s, 193 s, on a machine shared with
other workers' simulations), no script errors. On `f3e5b4c` (before defects 3 and 4) it was 138 checks, 0 failures, three runs; run
once there with defects 1 and 2's fixes reverted: 10 failures (the regression checks).

| Scenario | Exercised (asserted that it happened) |
|---|---|
| 1 host + 2 guests | each copy has the other two in play; Ann's target is the host she faces; Ann taps Cara and Cara taps the host: their windows; Cara's message reaches the host's journal; both guests' copies equal the host's world |
| 1 host + 3 guests | four distinct permanent pids; a fifth refused "full"; twelve directed choices: the host by mouse and by keys, Ann by touch and by pad, Cara by touch, Dan by mouse and by keys, each window naming the right player |
| Same tick (`hold`/`release`: held requests applied in one host frame, checked by count) | one ore offered to two players, both accept: it moves once, the late one told "no longer has it"; one buyer accepts two sales he can pay one of: paid once, the other left waiting (and still on his screen after a second refused try); two gifts offered in one frame and accepted in one frame: each gives one, gets one; two players pick one plant: one gets it and is shown its gain, the other is given nothing and shown "Nothing left to pick." with no gain |
| Delivery and order | six messages from two senders, turn about: each once, each sender's in order, the recipient's copy in the host's order, the last kept in his journal; five sent in one frame: once each, in order |
| Consistency (host frozen, `dump`; each copy compared: 23 synchronized sections, the offers, the clock, 110 villagers alive or not, every player's place, no other player's pack, its own pack and purse) | Ann, Cara and Dan at 1+3 after a tree was felled, after the concurrent actions, after two guests left and came back, after the host's restart, after the host was killed; Ann and Cara at 1+2 |
| Guest away and back | Dan leaves with an offer pending to him: away on the host, nobody can choose him, his machine holds no world; back as the same pid, the offer still his; accepted, the ore moves once. Cara offers and leaves: Ann's acceptance moves nothing ("They are gone."); Cara back with her ore and no offer |
| Save with guests playing, host away and back | the save holds all four players and the pending offer; the host quits: every guest out, no machine holds the world; 8.8 s later the loaded clock equals the saved one to the hundredth of a minute (no minute passed), coins and goods identical, every guest out of play until rejoining; all three rejoin as the same characters with the same packs, purses and places; time runs again; the pending offer accepted after the restart moves once |
| Host killed after a save | every guest told "Host disconnected. The world has stopped until the host plays again."; back from the save, the clock unchanged, all three return |
| Privacy between players | no copy holds an offer or message between two other players (after the messages, after a host offer to Cara), and a rejoining guest's welcome holds only its own offers and its own Messages journal |
| Conservation | coins conserved on the host after every step and over the run; ore counted over all four players before and after every exchange; no guest ever wrote a save |

Regression on `f3e5b4c` (the code of this branch): `net_batch_b_test` 44, `net_c_test` 35, `net_family_test` 22, `net_fauna_test` 13,
`net_g1_test` 45, `net_interact_test` 67, `net_ui_test` 61, `multiplayer_a1_test` 67, `multiplayer_b_test` 31, `multiplayer_c_test` 340,
`mp_interact_ui_test` 112, `message_journal_test` 51 checks, `start_test` 523 steps, `run_tests` 3,600 checks: 0 failures, no script
errors. G0 (`python3 tools/sim_gate.py`, once): **PASS, identical to the baseline**, seeds 1 and 2, days 10 and 30, currency and item
leaks 0 (2,104 s).

### Defects found and fixed (game code, `game/scripts/net/`)

1. **A refused acceptance made a waiting offer vanish from the recipient's screen** (`net_session.gd`). Root cause: a guest's copy takes
   an answered offer away at once (`World.player_answer` on a guest) and a mirrored `player_offer` adds one, before the host
   replies; when the host refuses (the buyer is short of coins, not beside them, "You have asked already") its offers do not change,
   so `NetSync.changed` never resends them and the copy keeps its guess. Reproduction: Dan, short of coins, accepts a player's sale;
   the host refuses and keeps the offer; Dan's copy has no offer and no Decline button, for the rest of the day. Fix: after applying a
   guest's `player_offer` or `player_answer`, the host marks that guest's copy of the offers stale so they are sent again.
   Regression: `net_mp4_test` "the refused acceptance leaves the offer waiting on the host and on Dan's screen", "Dan declines the
   other: nothing waits".
2. **A tree felled while guests watched kept its old growth date on their copies** (`net_sync.gd`). Root cause: `NetSync.adopt` copied
   each field of the host's tree record but never removed one the host had dropped (`World.fell` erases `born`). Reproduction: a
   woodcutter or the test fells a tree; each guest's stump keeps `born` -10000000 (a grown tree's) where the host reads its regrowth
   day. No visible effect was found (the host sets a new date when the stump sprouts and sends it), but the copies differed from the
   host. Fix: fields absent from the host's record are removed. Regression: the consistency checks after a felling.

3. **The loser of a same-plant race was shown "+1" and given nothing** (`main.gd`, `net_session.gd`). Root cause: a guest shows its
   own run of the picking verb at once (`World.mirror`); its copy cannot know another player picked the plant in the same host frame,
   and the host's empty answer carried no words. Reproduction: Ann and Dan pick one plant in one host frame; one is shown "+1 Flower"
   and has nothing. Fix: on a guest, a plant or fruit picking waits for the host's answer (`NetSession.verb_answered`) and shows what
   came, or the single-player wording "Nothing left to pick."; single player and the host are unchanged. Regression: `net_mp4_test`
   "the other is shown the truth".
4. **Every guest received every offer and message between all players** (`net_session.gd`). Root cause: the "player_offers" section
   and the welcome's whole save went to every guest alike, the welcome with every player's Messages journal. Fix: the host sends each
   guest only the offers and messages it sent or receives, and only its own journal (`NetSession._private_for`, in the welcome and
   in every sync); nothing else the game needs is held there. The snapshot comparison compares each copy with the host's offers as
   sent to that player (`NetSession.offers_for`). Regression: `net_mp4_test` "holds no offer or message between others", and the
   rejoin check of the welcome.

Regression on `7ff8d8b`: `net_interact_test` 67, `net_g1_test` 45, `net_ui_test` 61, `multiplayer_c_test` 340, `mp_interact_ui_test`
112, `message_journal_test` 51 checks: 0 failures, no script errors. G0 was not rerun for defects 3 and 4: they change only the network
layer and a guest-only branch of `main.gd` (no simulation code); the G0 above is on `f3e5b4c`.

### Note

- Keys and pad choose only among people in front of the player within the villagers' reach; a player 2.4 tiles away needs a tap, a
  click or a step closer. That is the MP-INTERACT-01 rule, recorded here so a device tester expects it.

## What still needs the owner's devices

1. Every platform pair above on real hardware, both directions, at least once: choose, open, offer, accept and decline.
2. Three and four players at once on real devices (one host, two and three guests), including two guests answering one host offer
   at the same moment.
3. A phone hosting: the screen kept on (`DisplayServer.screen_set_keep_on`), backgrounding and screen lock while guests play (the
   world must stop for everyone if the host's app is suspended), a Wi-Fi change.
4. The host closing the game and opening it again while guests wait: guests see "Host disconnected. The world has stopped until the
   host plays again." and rejoin as the same characters.
5. Touch accuracy on a real phone screen; a real mouse; a physical controller on Windows and Linux; the Steam Deck.
6. The Windows firewall prompt on first hosting; a real LAN between two machines (loopback has no packet loss or latency).

## Batch D cross-platform verification matrix (MP-MASTER Batch D, MP-INET, MP-D6; worker C, `wip/mp-batchd`, 2026-10-30)

Design and connectivity findings: `docs/multiplayer/BATCH_D_CONNECTIVITY.md`. Legend: **A** automated on this machine (real Godot
processes, real ENet over loopback), **S** simulated (faults injected by `game/tests/net_proxy.gd` into real ENet datagrams, by the
fault hooks in `NetSession.faults`, or by freezing and killing processes), **D** needs physical devices, **N** needs real external
networks (separate homes, mobile data, routers). D and N rows are **not verified**; nothing below claims otherwise.

### Platform pairs (each host with each guest; LAN and internet)

| Host \ Guest | Android guest | Windows guest | Linux guest | Steam Deck guest |
|---|---|---|---|---|
| Android host | D (LAN), N (internet) | D, N | D, N | D, N |
| Windows host | D, N | D, N | D, N | D, N |
| Linux host | D, N | D, N | **A** (loopback, same machine), D (two machines), N | D, N |
| Steam Deck host | D, N | D, N | D, N | D, N |

The protocol and code are the same on every platform (one ENet transport, one `mml-net/3` protocol, one save format); only the Linux
build runs here. Android export permissions in `game/export_presets.cfg` (INTERNET, ACCESS_NETWORK_STATE, ACCESS_WIFI_STATE,
CHANGE_WIFI_MULTICAST_STATE) already cover LAN, internet and the router's UPnP search; no permission was added.

### Connection methods

| Method | Status | Evidence / what is missing |
|---|---|---|
| LAN discovery and typed LAN address | A (loopback) | `net_ui_test`, `net_g1_test`; real two-machine LAN: D |
| Invite code: made, copied, pasted, read back, typing mistakes caught, wrong world refused, dead address passed over within its time | A | `net_fault_test` (codes, `_join_by_code`) |
| Invite code reaching a host on another network through a UPnP-mapped port | N | needs a home router with UPnP on, two networks |
| UPnP router search and mapping | A for "no router" (this container has none: the window and code claim no internet); mapped/refused/shared on a real router: N | `net_fault_test` `_router` |
| Host on mobile data / CGNAT: window says friends elsewhere cannot join | logic A (classification and wording); on a real phone: D+N | `net_fault_test` |
| Manual port forward + typed public address | N | |
| IPv6 address in the code / typed `[v6]:port` | parsing A; connection: **not testable here** (no IPv6 in this container); N | |
| Virtual LAN app (documented fallback) | N | owner: insufficient alone (MP-D5) |
| Windows Firewall prompt on first hosting | D | |

### Interruptions and message safety

| Case | Status | Evidence |
|---|---|---|
| Requests repeated (each sent twice): applied once, answered once, pack exact, coins conserved | S | `net_fault_test` `_repeats` |
| An applied request number sent again later: not applied | S | `_repeats` |
| Requests late (250 ms) and swapped in pairs: applied once each, in the order sent | S | `_repeats` |
| Lossy transport: 20% loss, 15% duplicate and 15% reordered datagrams, 30-70 ms delay: actions exactly once, walk arrives, coins conserved | S | `_lossy` |
| Network gone 1.5 s: connection holds | S | `_dropped` |
| Network gone past the timeouts: guest view stops, reconnects by itself to the same character; host takes it out of play meanwhile (MP-D1), no duplicate character, coins conserved, packs agree | S | `_dropped` |
| Android guest paused past the host's timeout and resumed: reconnects at once, takes its character back with its token | S (notification + frozen node + blackholed network) | `_guest_pause`; on a phone: D |
| Guest process killed: host drops it in its time, out of play, coins conserved; restarted: same character | S (SIGKILL) | `_guest_killed` |
| Guest process frozen (SIGSTOP) past the timeouts, then let go: reconnects by itself | S | `_guest_killed` |
| Android host paused: guests told, wait up to 5 minutes, come back; the host's clock does not run the frozen time | S (pause notification, process blocked 14 s, resume notification) | `_host_pause`; on a phone: D |
| Host process killed after a save, restarted from the save on the same port: guest comes back by itself, world as saved, its requests applied once | S (SIGKILL) | `_host_killed` |
| Host stops on purpose: guest told at once, no waiting | A | `_host_stops`, `net_g1_test` |
| Android OS killing a backgrounded host; screen lock; Wi-Fi to mobile data change; battery/thermal | D | |
| Three and four players under faults at once | partly A (two guests plus kill/freeze); real devices: D | |

### Results (this machine, Linux, Godot 4.7.2, loopback; other workers' suites running alongside)

New: `net_fault_test` **52 checks, 0 failures** on `1c019be` (the final Batch D code; three processes plus the relay). Earlier runs
under load found three defects, fixed (`docs/multiplayer/BATCH_D_CONNECTIVITY.md` section 5a) and one loose measurement in the test.

Regression on `f038daf`/`5266dea` (Batch D code before the last test-only change), all 0 failures, no script errors:
`net_mp4_test` 148, `net_interact_test` 67, `mp_interact_ui_test` 112, `multiplayer_c_test` 340, `net_ui_test` 61, `net_g1_test` 45,
`net_soak_test` 28, `save_transfer_test` 21, `net_batch_b_test` 44, `net_c_test` 35, `net_family_test` 22, `net_fauna_test` 13,
`net_recorder_quit_test` 20, `multiplayer_a1_test` 67, `multiplayer_b_test` 31. On `157a978` (before the takeover fix, which touches
only the network layer): `run_tests` 3600, `start_test` 523, `world_test` 339, `wiki_test` 141. `net_mp4_test`'s killed-host phase
now expects the guests to wait and come back by themselves (INT-641), the intended Batch D behaviour.

G0 (`tools/sim_gate.py`, seeds 1-2, days 10 and 30) on `a0114a8`: **PASS, identical to `docs/release/sim_baseline.json`**, currency and item
leaks 0.

What none of this shows: any real device, any second machine, any router, any network but loopback, IPv6, Android lifecycle on a
phone, the Steam Deck. Those rows stay unverified above.
