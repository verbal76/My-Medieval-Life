# Multiplayer hardware test procedures (real devices)

For the owner's informal playtesting with real phones and PCs. Written 2026-11-12 from the code on `wip/b25r2-rev2` at
`b3c9eb5` (chain 12: ND-26 heartbeat, MP-05, MP-06, MP-07 merged). The owner's playtesting is never a release gate
(CLAUDE.md section 5); what you find is recorded in the register's `playtest` field by the lead, because automated tests
are not device checks (CLAUDE.md section 9a, "Automated is not device").

Contents:
- [0. Before you start (every test)](#0-before-you-start-every-test)
- [A. Host pause and resume](#a-host-pause-and-resume): A1 Android host, PC guest; A2 PC host, Android guest
- [B. Packet loss and jitter on Wi-Fi](#b-packet-loss-and-jitter-on-wi-fi)
- [C. A slow phone joining as a guest](#c-a-slow-phone-joining-as-a-guest)
- [D. A guest device locked or asleep, then woken](#d-a-guest-device-locked-or-asleep-then-woken)
- [E. MP-05: sharing carts and chests between players](#e-mp-05-sharing-carts-and-chests-between-players)
- [F. MP-06: a guest who is away cannot act](#f-mp-06-a-guest-who-is-away-cannot-act)
- [G. MP-07: what one player can see of another](#g-mp-07-what-one-player-can-see-of-another)
- [H. The record sheet, and where to report](#h-the-record-sheet-and-where-to-report)
- [Appendix: the numbers in the code](#appendix-the-numbers-in-the-code)

## 0. Before you start (every test)

1. **The same build on every device.** Install the APK, Windows ZIP or Linux ZIP of one build number on each device. The
   network protocol is `mml-net/5`, and the game also checks the save format (save 23). A device with another build is
   refused with: "That game runs a different version of My Medieval Life. Both players need the same version." That
   refusal is correct; it is not a failure.
2. **One network.** Put every device on the same Wi-Fi (same router). Write down the router and whether each device is on
   2.4 GHz or 5 GHz if you know.
3. **Windows firewall.** On a Windows host, allow the game through Windows Firewall when it asks (UDP ports 47810 for the
   game and 47811 for finding games on the network).
4. **Host.** From the title screen, choose **Host a game** (or, in a running world, the pause menu's **Open to friends**).
   The window shows the invite code and address.
5. **Guest.** From the title screen, choose **Join a game**, then pick the game found on the network, or type the invite
   code or address. When the guest is in, the guest sees "Joined <world name>." and the host sees "<name> joined the world."
6. **Do not reinstall or clear the game's data on a guest between steps.** The guest's character is tied to a key the
   game keeps on that device. A reinstall makes a new key, so the host would see a new character.
7. **Have ready:** a stopwatch (a second phone works), a way to take screenshots or a screen recording on each device, and
   the record sheet in section H.
8. **A PC can record.** On Windows and Linux, Settings has **Record gameplay** and **Export the recording...** (not on
   Android). If a PC is in the test, switch recording on before you start; send the exported folder with a failure report.

A test "passes" when every expected result in its table happens. "Fail" means one of them did not. Write "Unclear" if you
could not tell, and say why.

## A. Host pause and resume

### A1. Android host, PC guest (owner decision MP-D6)

What the game does: when the host's Android app goes to the background (Home button, switching apps, or pressing the
power button), the host saves the world and tells each guest it is paused, then the world stops for everyone. The game does
not keep a hosted world running in the background (the wiki lists that as "not in the game yet"). While hosting, the host
phone's screen does not turn off by itself.

**Setup:** Android phone hosts; a Windows or Linux PC joins as guest. Both play for a minute (walk, pick something up).

**Steps:**

| # | Do this | Expected |
|---|---|---|
| A1.1 | Host: press Home. Start the stopwatch. Stay away about **5 seconds**, then reopen the game. | Guest at once: "The host's game is paused (in the background). Waiting for it to come back..." When the host returns, play goes on. No "left the world" on the host; nothing reconnects. |
| A1.2 | Host: press Home again. Stay away about **1 minute**, then reopen. | Guest: the paused message, then, after about 10 seconds, the guest's game stops (it cannot move) and keeps showing the waiting message. The host may show "<name> left the world." and then "<name> joined the world." when it comes back; that is the guest's old connection being replaced. Within about 20 seconds of the host reopening, the guest sees "Reconnected to <world name>." and plays as the same character, with the same pack and coins. |
| A1.3 | Host: lock the phone with the power button for about **3 minutes**, then unlock and reopen the game. | As A1.2. The host's world does not jump ahead: it carries on from the moment it was paused. |
| A1.4 | Host: press Home and stay away **more than 5 minutes** (6 minutes is enough), then reopen. | After 5 minutes of waiting, the guest goes to the title screen with: "Lost the connection to the host. The world has stopped until the host plays again; your character waits there." When the host is back, the guest can join again (Join a game) and gets the same character. |
| A1.5 (optional) | Host: while in the background, close the game from Android's recent-apps list, then start it again and host the same world. | Nothing done before the pause is lost (the host saved at the pause). The guest can join again and gets the same character. |

**Record:** for each step, the time away, the time from the host reopening to the guest's "Reconnected" (or to the title
screen), the messages on both screens (exact words), and a screenshot of each message.

**Pass:** every expected result happens; the guest never gets a second character; nothing in either pack or purse changes
because of the pause. **Fail:** the guest is sent to the title screen before 5 minutes; the guest comes back as a new
character; items or coins appear, vanish or are counted twice; the game freezes or crashes.

### A2. PC host, Android guest

A PC host keeps running when its window is minimized or loses focus (it saves, but it does not pause). This test is mostly
about the Android guest going to the background.

**Setup:** a Windows or Linux PC hosts; an Android phone joins.

| # | Do this | Expected |
|---|---|---|
| A2.1 | Host: minimize the game window for 1 minute, then restore it. | The guest keeps playing the whole time; nothing on either screen. |
| A2.2 | Guest: press Home for about **2 seconds**, then reopen the game. | The guest just carries on; no reconnect message. |
| A2.3 | Guest: press Home for about **7 seconds**, then reopen. | The guest shows "Connection to the host lost. Reconnecting..." at once and then "Reconnected to <world name>." within a few seconds. The host does **not** show "<name> left the world." (the old connection is replaced quietly); it may show "<name> joined the world." |
| A2.4 | Guest: press Home for about **30 seconds**, then reopen. | Host: about 10 seconds after the guest went to the background, "<name> left the world."; the guest's character leaves active play (it is no longer shown in play). Guest, on reopening: "Reconnecting...", then "Reconnected to <world name>." as the same character. |
| A2.5 (optional) | Host (laptop): close the lid or put the PC to sleep for **30 seconds**, then wake it. | Guest: after about 10 seconds, "Connection to the host lost. Reconnecting..." (no "paused" message: a sleeping PC sends no notice). When the PC wakes within 60 seconds of that message, the guest reconnects by itself. |
| A2.6 (optional) | As A2.5, but keep the PC asleep for **2 minutes**. | The guest gives up 60 seconds after the reconnect message and goes to the title with the "Lost the connection to the host" message. It can join again later as the same character. |

**Record, pass and fail:** as A1.

## B. Packet loss and jitter on Wi-Fi

What the game does: actions (buying, giving, eating, crafting) are numbered and the host applies each number once, so a
lost or repeated network packet never makes a second purchase or gift. Walking may stutter or snap back when packets are
lost; that is allowed. Both sides send a heartbeat every second; a side that hears nothing for more than 10 seconds ends
the connection, and the guest then tries to come back for 60 seconds. The automated tests run 20% loss, 15% repeats, 15%
reordering, 30 ms delay and 40 ms jitter through a relay on one machine; this test is the same thing on a real network.

### How to make a bad network

- **Windows: clumsy** (free, from its official site: jagt.github.io/clumsy). Run it as administrator. Filter:
  `udp and (udp.DstPort == 47810 or udp.SrcPort == 47810)` (only the game's traffic). Tick **Drop** (the loss
  percentage), **Lag** (delay in ms) and, if you like, **Out of order** and **Duplicate**. Press Start; press Stop to end.
- **Linux: `tc netem`** (part of the `iproute2` package). Find the Wi-Fi interface with `ip link` (often `wlan0` or
  `wlp2s0`). Then:
  - start: `sudo tc qdisc add dev wlan0 root netem loss 10% delay 80ms 40ms`
  - change: `sudo tc qdisc change dev wlan0 root netem loss 20% delay 100ms 60ms`
  - stop: `sudo tc qdisc del dev wlan0 root`

  This affects everything the PC sends on that interface (not what it receives), so close downloads and calls. Always run
  the stop command at the end.
- **Phones: distance.** Phones have no simple loss tool. Walk the phone away from the router, through walls or to another
  floor until the Wi-Fi shows one bar. Do not use the phone's mobile data: joining over mobile data is not supported yet.

### Levels to try

Run each level for about **3 minutes of play**. Clumsy and netem settings are per machine; with both a Windows and a Linux
PC, set the same level on one of them only.

| Level | Loss | Delay / jitter | Expected |
|---|---|---|---|
| L0 | 0% | none | The baseline: smooth play. |
| L1 | 5% | 50 ms / 20 ms | Play feels normal; maybe a small stutter now and then. |
| L2 | 10% | 80 ms / 40 ms | Some stutter or snapping back while walking; every action still happens exactly once. No disconnection. |
| L3 | 20% | 100 ms / 60 ms | Clear stutter and delay; actions are slow to show but each happens exactly once. No disconnection is expected (this is the automated level). |
| L4 (stress) | 30-40% | 150 ms / 80 ms | Very poor play. A "Reconnecting..." may happen; if it does, the guest should come back by itself once you lower the loss. Nothing may be duplicated or lost. |
| L5 (outage) | 100% (clumsy Drop 100, or netem `loss 100%`) for **20 seconds**, then off | | About 10 seconds in: the host shows "<name> left the world.", the guest shows "Reconnecting...". After you switch it off, the guest is "Reconnected to <world name>." within about 10 seconds, as the same character. |
| L6 (long outage) | 100% for **90 seconds**, then off | | The guest gives up after 60 seconds of reconnecting and goes to the title with "Lost the connection to the host..." It can join again as the same character. |

### What to do at each level (the exactly-once checks)

Before each level, write down the guest's coins and the count of one food in its pack. Then, under the bad network:

1. **Eat three times**, one at a time: the food count drops by exactly 3.
2. **Buy two things** from a villager (or a stall): the coins drop by exactly the two prices; two items arrive.
3. **Give the other player one item** (and have them accept): it leaves one pack and arrives in the other, once.
4. Walk around the village for a minute.

**Record:** the tool and its exact settings (screenshot of clumsy, or the netem command), the distance and walls for a
phone, the counts before and after, any "Reconnecting..." with its time, and a screen recording of walking at L3.

**Pass:** at L0-L3, no disconnection, and every count is exactly right; at L4-L6, counts are exactly right after any
reconnect and the guest comes back by itself (L4, L5) or rejoins as itself (L6). **Fail:** any item or coin counted twice,
lost or made from nothing; a disconnection at L0-L2; a guest that does not come back when the network recovers; a new
character after a reconnect.

## C. A slow phone joining as a guest

What the game does: when a guest is let in, it receives the whole world and builds it in one long step (4-5 seconds on a
test PC with other work running; longer on a slow phone), and cannot answer the network meanwhile. The host gives a joining
guest **30 seconds** (`JOIN_TIMEOUT_MS`) before it gives up on the connection; the 10-second heartbeat watch starts only
once the guest is playing. So a phone that builds the world in under 30 seconds must not be dropped.

**Setup:** the slowest phone you have as guest (an old or cheap Android). Host on a PC or a fast phone. Use a host world that
has been played for a long time (more villagers, buildings and history make the world bigger to send). To make the phone
slower still, switch on its battery saver and leave a few other apps open.

| # | Do this | Expected |
|---|---|---|
| C1 | Guest: Join a game. Start the stopwatch when you press the final Join, stop it when "Joined <world name>." appears and you can walk. | The guest gets in and can walk. The host shows "<name> joined the world." once. No "left the world" and no "Reconnecting..." during the build. |
| C2 | Play on for **5 minutes**: walk, buy something, eat. | No disconnection. |
| C3 | Guest: Leave the game (pause menu), then join again. Time it again. | As C1, the same character. |
| C4 | Repeat C1 three times and note each time. | Times roughly alike. |

**Record:** the phone model, Android version, how much free storage and memory it shows if you know, battery saver on or
off, the host world's in-game day, and each join time.

**Pass:** the phone gets in every time and stays connected. **Fail:** the guest is sent back to the title or shows
"Reconnecting..." while it builds the world, or the host shows "<name> left the world." during the join.
**Report the join times in every case.** A join that takes more than about **20 seconds** passes but is close to the
30-second limit: say so, because it tells the lead whether the limit is safe for slow phones.

## D. A guest device locked or asleep, then woken

What the game does (owner decision MP-D1 and the ND-26 heartbeat watch): a guest that stops answering is dropped by the
host after about 10 seconds. Its character goes **out of active play** but **every record stays** in the host's world
(pack, purse, property, family, agreements). When the guest wakes, it reconnects by itself (it tries for 60 seconds from the
moment it wakes) and comes back **as itself**.

**Setup:** host on a PC or phone; guest on an Android phone (also try a laptop guest if you have one). Before you start, write
down the guest's coins and three items in its pack, and anything it owns (a stall, a plot, a cart) or is married to.

| # | Do this | Expected |
|---|---|---|
| D1 | Guest: lock the phone (power button). Start the stopwatch. Keep it locked **30 seconds**. | Host: "<name> left the world." about 9 to 12 seconds after the lock; the guest's character is no longer shown in play. |
| D2 | Guest: unlock and reopen the game. | Guest: "Connection to the host lost. Reconnecting..." then "Reconnected to <world name>." within about 10 seconds. Host: "<name> joined the world." The guest is the same character, with the same coins, pack, property and family as written down. |
| D3 | Guest: lock the phone for **10 minutes**, then unlock and reopen. | As D1 and D2. (The 60-second reconnect window starts when the phone wakes, so a long sleep still comes back.) If Android closed the game while it was locked, start it again and Join: the same character comes back. |
| D4 (laptop guest) | Close the lid or sleep the PC for 30 seconds, then wake it. | As D1 and D2: the game notices it was frozen and reconnects at once. |
| D5 | While the guest is locked (after D1's "left the world"), the host walks to where the guest's character was. | The guest's character is not there to talk to, trade with, strike or rob. |

**Record:** the exact times (lock, the host's "left the world", unlock, "Reconnected"), the before and after values, and
screenshots of the host's messages and the guest's pack after the rejoin.

**Pass:** the drop happens at about 10 seconds (not 30), every record is unchanged after the rejoin, and the guest comes
back as itself. **Fail:** the host never drops the sleeping guest, or drops it much later than about 15 seconds; the guest
comes back as a new character; any record changed or is missing; the guest could be acted on while away.

## E. MP-05: sharing carts and chests between players

Owner rule (2026-11-08, register `B25-AUD-MP-05`): sharing is mutual and reciprocal, needs a proposal and acceptance, and
there is none by default. Tiers: 1 materials; 2 materials and finished goods; 3 materials, finished goods, tools and
property use. Either player may revoke. Ownership, the right to sell and the right to demolish never pass. The automated
tests (including forged-client tests) pass; these checks are the real two-device and menu checks still outstanding.

**Setup:** host and one guest, each with a chest of their own holding: some planks or stone (tier 1), some cooked food or
cloth (tier 2) and a tool such as a spare axe (tier 3). One of them (say the host) owns a cart.

| # | Do this | Expected |
|---|---|---|
| E1 | Before any agreement, the guest opens the host's chest. | The guest cannot take from it as if it were its own (it is treated as anyone else's chest). The guest cannot pull the host's cart. |
| E2 | Host: open the Players window, choose the guest, **Asset sharing**, tier 1. | Message that the guest must accept tier 1 first. Nothing is shared yet. |
| E3 | Guest: accept the offer. | Both now share tier 1, both ways. The guest can take the host's planks or stone but not the food or the tool; the host can do the same at the guest's chest. |
| E4 | Repeat with tier 2, then tier 3. | Tier 2 adds food or cloth; tier 3 adds the tool, and each can now pull the other's cart. |
| E5 | At tier 3, the guest tries to sell or demolish anything of the host's (a building, the cart). | Refused: ownership, sale and demolition are never shared. |
| E6 | Guest: pull the host's cart. While pulling it, the **host** revokes sharing (Players window, Asset sharing, revoke). | The guest lets go of the cart at once; it stays the host's. Neither can now take from the other's chest. |
| E7 | Share at tier 2 again, then do test D1-D2 (lock and wake the guest). | After the rejoin the agreement is still in place, at tier 2. |
| E8 | While the guest is away (after D1), the guest's agreement is revoked by the host. Then the guest rejoins. | The revocation stands after the rejoin. (A guest that is away may itself revoke too: it is one of the few things an away guest may do.) |

**Pass:** each expected result; nothing duplicated or lost when goods are taken. **Fail:** any access before acceptance,
access above the agreed tier, one-way sharing, a cart kept after revocation, any ownership change.

## F. MP-06: a guest who is away cannot act

Rule (audit MML-MP-06, merged `cda94b8`): a guest out of active play (disconnected, or still building the world it was
sent) may only do what touches its own character (eat, medicine, gear, wake, rest, yield, let go of a station, withdraw an
asset-sharing agreement); everything that touches the world or other people is refused, and what a guest acts on must be
within its reach. The forged-request side is covered by automated tests; the device check is that real play is not
affected.

| # | Do this | Expected |
|---|---|---|
| F1 | Do test C (join) and then at once buy something and talk to a villager. | It all works: the guest is in play from its first move, so the away rule never blocks a real join or rejoin. |
| F2 | Do test D1-D2 and, straight after "Reconnected", open a chest, buy, and give the host an item. | It all works. |
| F3 | During D1 (guest locked), the host checks the guest's stall, cart or plot. | Nothing is done in the guest's name while it is away. |

**Pass:** F1 and F2 work at once after joining and rejoining; nothing changes during F3 except the ordinary work of hired
villagers. **Fail:** "You are not in the world now." shown to a guest that is playing; any change made in the guest's name
while it was away.

## G. MP-07: what one player can see of another

Owner rules (2026-11-08 and 2026-11-12, register `B25-AUD-MP-07`): marriage, spouses, children and parents are **public**
and may appear in household, family and genealogy views. **Private**: debts, crimes, personal knowledge, private notes,
hidden relationships, inventories and other protected records. Family membership and asset sharing give no access to private
records. The host enforces this in what it sends, not only on screen; that part is checked by automated tests
(`mp07_private_records_test`). The device check is that the public family shows and nothing private does.

**Setup:** host and two guests if you can (one married to the host, or to each other; one unrelated), otherwise host and
one guest. Give the host something private: coins and items in its pack, a debt (buy on credit or owe a villager), a crime on
record (be caught pickpocketing), and friendships with villagers.

| # | Do this | Expected |
|---|---|---|
| G1 | Marry two players (one asks, the other accepts); have or adopt a child if you can. | Every player can see the marriage, the spouse, the children and the parents in the family and household views. |
| G2 | A guest opens everything it can about the host: the Players window, the host's household and family, the map, the journal. | It shows the host's name, look, worn armour and weapon in hand, place, and public family. It never shows the host's pack, coins, debts, crimes, friendships, notes or what the host knows (prices, finds). |
| G3 | The spouse guest does the same as G2. | The same as G2: being family shows no private record. |
| G4 | Set up tier 3 asset sharing (section E) between the host and a guest, then repeat G2. | The same as G2: sharing assets shows no private record (only the shared chests' contents, as section E says). |
| G5 | Do test D1-D2 (lock and wake a guest), then repeat G2. | The same as G2 after the rejoin. |
| G6 | A guest talks with a villager who saw the host's crime. | The guest may learn of it from the villager (ordinary gameplay), not from the host's records. |

**Record:** screenshots of every view checked in G2-G5, with which player is looking at whom.

**Pass:** public family visible to all; nothing private visible to anyone but its owner. **Fail:** any private item listed
above visible to another player, or the public family missing.

## H. The record sheet, and where to report

Copy this for each test you run:

```
Test:            (e.g. A1.2, B L3, C1, D3, E6, G2)
Build number:    (from the release or file name; the same on every device?)
Date and time:   (with your time zone)
Host device:     (model, Android/Windows/Linux version)
Guest device(s): (model, version)
Network:         (router; 2.4 or 5 GHz; distance and walls for phones; tool and settings for section B)
What I did:      (the steps, with stopwatch times)
What I saw:      (the exact messages on each screen)
Before / after:  (coins, item counts, owner and family, where the test asks)
Result:          Pass / Fail / Unclear
Screenshots:     (file names; screen recording for stutter or timing)
Recording:       (the exported recording folder from a PC, if one was used)
Notes:
```

**Where to report:** paste the filled-in sheets to the lead in the Claude session (attach the screenshots there, or on the
GitHub issue the lead names). The lead records each result in the register's `playtest` field through the normal register
procedure; you do not edit the register yourself. The entries these tests feed:

| Section | Register entries (via the lead) | Also tracked in |
|---|---|---|
| A (host pause and resume) | `MP-D6`, `MP-MASTER`, `B21-LAN-PLAYTEST` (PC host with Android guest) | |
| B (loss and jitter) | `MP-MASTER`, `X20-MP-ECON-INTEGRITY` (exactly-once under bad networks) | |
| C (slow join) | `MP-MASTER` (the B25R1 join time limit) | |
| D (sleep and wake) | `MP-D1`, `MP-MASTER` | ND-26 in `docs/audits/B25_NEW_DEFECTS_REGISTER.md` |
| E (MP-05) | `B25-AUD-MP-05` (device and menu checks, KI-13) | MML-MP-05 in `docs/audits/B25_69_ITEM_TRACKER.md` |
| F (MP-06) | (no register id yet; the lead decides) | MML-MP-06 in the item tracker |
| G (MP-07) | `B25-AUD-MP-07` | MML-MP-07 in the item tracker |

A failure is not something to fix on the spot: report it with the sheet, and the lead files it as a defect.

## Appendix: the numbers in the code

From `game/scripts/net/net_session.gd` and `net_protocol.gd` at `b3c9eb5`, for the lead checking a report:

| Constant | Value | Meaning |
|---|---|---|
| `NetProtocol.VERSION` | `mml-net/5` (with `save-23`) | host and guest must match exactly (`full_version`) |
| `GAME_PORT` / `DISCOVERY_PORT` | 47810 / 47811 (UDP) | game traffic; finding games on the network |
| `TIMEOUT_MIN_MS` / `TIMEOUT_MAX_MS` | 4000 / 10000 ms | ENet timeouts while playing |
| `JOIN_TIMEOUT_MS` | 30000 ms | a welcomed guest building the world (host and guest side), until its first move or `zz_playing` |
| `BEAT_SECONDS` | 1.0 | the `zz_tick` heartbeat, both ways, while a guest plays (ND-26) |
| ND-26 watch | silence > `TIMEOUT_MAX_MS` | host drops the guest (`_watch_guests` → `_drop_peer`: `away = true`, records kept, world saved); guest ends the connection and reconnects |
| `OWN_GAP_MS` | 1000 ms | a side's own long frame (or its own pause) is not counted as the other side's silence |
| `RECONNECT_SECONDS` | 60 | how long a dropped guest keeps trying, from when it starts reconnecting |
| `HOST_PAUSED_SECONDS` | 300 | the same, after the host said it is paused (`z_paused(true)` from `on_app_paused`) |
| `RESUME_AFTER_PAUSE_MS` | 4000 ms | a guest back from a pause (or a freeze, KI-12) longer than this reconnects at once |
| `BYE_WAIT_SECONDS` / `BYE_CLOSE_SECONDS` | 2.0 / 0.3 | a host stopping on purpose waits for its guests to read the goodbye (`z_bye`): guests go to the title and do not retry |
| reconnect back-off | 0.5 s doubling to 8 s; each attempt 5 s | `_retry_later`, `_reconnect_step` |
| `MAX_PLAYERS` | 4 | the host and up to three guests |

Paths: Android pause and resume reach `NetSession.on_app_paused` / `on_app_resumed` from `Main._notification`
(`NOTIFICATION_APPLICATION_PAUSED` / `RESUMED`; the host also saves there). A desktop window losing focus saves but does not
call `on_app_paused`. A guest resumed or rejoining is matched by its device key hash (`guest_by_key`), with the resume token
(`z_token`, this hosting session only) letting a new connection replace an old one the host still holds (`_drop_peer(id,
true)`, no "left" message). The host's world does not catch up after a freeze (`Main.HOST_STALL_SECONDS`).
