# Build 7 issue register

The running record of everything found while the owner tests Build 7 on real hardware. Build 7 is
the testing baseline and stays exactly as released:

| | |
|---|---|
| Release | `build-7` (pre-release), https://github.com/verbal76/My-Medieval-Life/releases/tag/build-7 |
| Source commit | `679907121654c7630b170690752429b55a74b8ac` |
| Development branch | `staging/my-medieval-life`; every fix below names the staging commit that carries it |
| Next build | Build 8 only when the owner authorizes it; fixes accumulate here until then |

## How to read it

**Kind**
- **Bug**: something does not work as built or approved.
- **Usability**: works, but is hard to see, reach or understand while playing.
- **Enhancement**: a proposed change to approved behaviour; needs the owner's approval first.
- **Future**: an approved or proposed feature not built yet; tracked, never shown as done.

**Severity**
- **S1**: crash, lost save or blocked play.
- **S2**: a feature cannot be used.
- **S3**: works with difficulty or looks wrong.
- **S4**: cosmetic.

**Status**
- **Open**: reported, not yet diagnosed.
- **Diagnosed**: the root cause is known.
- **Fixed (staging)**: corrected, tested here and pushed to staging.
- **Verified**: confirmed on the owner's device.
- **Won't fix**: the owner's decision, with the reason.

An issue reaches **Verified** only after the owner confirms it on a device. A fix tested on this
machine stays **Fixed (staging)** while "Device check" says it still needs hardware.

Each entry records: the date reported, platform, the screenshot or reproduction steps, root cause,
files and systems, the test evidence and the fixing commit.

## Open and fixed issues

| ID | Reported | Kind | Sev. | Platform | Summary | Status | Commit | Device check |
|---|---|---|---|---|---|---|---|---|
| B7-001 | 2026-10-18 | Usability | S2 | All | A new player has 5 coins and starves by day 5 without income | Diagnosed | — | Yes (play feel) |
| B7-002 | 2026-10-18 | Bug | S3 | All | Side quests pay less than their text promises when the giver is short of coins | Diagnosed | — | No |
| B7-003 | 2026-10-18 | Bug | S3 | All | Rings, amulet and helmets can be crafted but nobody buys them | Diagnosed | — | No |
| B7-004 | 2026-10-18 | Bug | S3 | All | Wheat cut for harvest work can be kept without paying or being marked stolen | Diagnosed | — | No |
| B7-005 | 2026-10-18 | Usability | S2 | All | Nothing tells a new player how to earn money; the shop window says "Buy from" though it also sells | Diagnosed | — | Yes |
| B7-006 | 2026-10-18 | Usability | S3 | All | Hired work pays poorly or is closed: the mine shift pays less than the ore is worth; woodcutting needs an axe the player can't afford | Diagnosed | — | No |
| B7-007 | 2026-10-18 | Bug | S2 | All | Ore and stone deposits never refill and the caravan brings no stone: the village works them out by about day 10, after which no house can be built | Diagnosed | — | No |
| B7-008 | 2026-10-18 | Usability | S4 | All | The player can sell a buyer down to 0 coins and kill every wild animal (NPCs leave a floor of 15 coins and 2 animals) | Diagnosed | — | No |

Agent findings B7-001 to B7-008 come from the early-economy review (`EARLY_ECONOMY_REVIEW.md`).
They were measured with `game/tests/earn_sim.gd`, seed 1. Each fix changes a rule or number, so
all of them wait for the owner's approval.

### Issue details

### B7-001 Not enough money to survive the start
- Reported: 2026-10-18, agent review of the owner's question; all platforms.
- Evidence: `earn_sim.gd --strategy idle`: coins 5 → 3 → 1, dead on day 5 at 19:22.
- Root cause: `start_coins_player` 5. Food costs about 3 coins a day (`player_hunger_per_hour` 3).
- Files: `game/data/balance.json`.
- Fix: proposal (15–20 coins, and/or manor day labour); awaiting the owner.
- Device check: whether the start feels fair in real play.

### B7-002 Quest rewards cut to the giver's purse
- Evidence: `quests.gd:268` pays `mini(reward, n.coins)`. In the runs the smiths held 1–15 coins
  while "Ore for the forge" promises twenty.
- Root cause: offers are made without checking that the giver can pay, and nothing is set aside.
- Fix: proposal (offer only when the giver can pay, and set the reward aside); awaiting the owner.

### B7-003 Craftable jewellery and helmets have no buyer
- Evidence: `npc_brain.gd:13-22` `BUYS` lists no ring, amulet, leather cap or iron helmet.
- Fix: proposal (the goods merchant buys them); awaiting the owner.

### B7-004 Harvest-work wheat is never the farmer's
- Evidence (code reading; not run): `quests.gd:177` and `world.gd:1093` treat wheat cut under a
  harvest job as not theft. If the job lapses, the wheat stays with the player unmarked: about 48
  coins of wheat instead of a 6-coin wage, up to 3 jobs at once.
- Fix: proposal (mark it stolen if the job lapses); awaiting the owner.

### B7-005 Earning money is undiscoverable
- Evidence: the opening line is only "Explore the village: talk to people, work, trade, build."
  (`main.gd:476`). "Any work for me?" has no marker. The shop window is titled "Buy from …"
  (`game_ui.gd:1243`).
- Fix: proposal (hint text; the title "Trade with …"); awaiting the owner.

### B7-006 Hired work pays less than doing it alone
- Evidence: the mine shift pays 8 for 6 iron ore, which sell for about 18. The woodcutting job
  needs an axe the player doesn't start with.
- Fix: proposal; awaiting the owner.

### B7-007 Deposits run out and stone has no source
- Evidence: `earn_sim.gd --strategy observe` (the village alone): iron, coal, stone and copper all at
  0 by day 10 (seed 1). `caravan_import_stock` brings iron, coal and copper, not stone. A house
  needs 20 stone.
- Root cause: deposits have a fixed `amount` with no refill.
- Fix: proposal (stone imports and/or a refill rate); awaiting the owner.

### B7-008 The player has no floor on buyers' coins or wildlife
- Evidence: the mining run left the smiths at 0–1 coins; the hunting run killed all 12 wild adults
  on day 1 and none came back.
- Fix: proposal (the same 15-coin floor for the player's sales); awaiting the owner. Wildlife is a
  design question.

(One section per issue, `B7-001` onwards, in this form.)

```
### B7-000 Title
- Reported: date, by; platform and device
- Evidence: screenshot file or reproduction steps
- Kind / severity:
- Root cause:
- Files and systems:
- Fix:
- Tests: automated (which suites, results) and visual (screenshots looked at)
- Interaction manifest: INT ids added or changed, or none
- Commit: staging hash
- Device check: still needed / done (date, device)
```

## Known before testing (carried from the Build 7 readiness report)

| ID | Kind | Summary | Status |
|---|---|---|---|
| K-1 | Usability | The player starts with 5 coins; land costs 60 or more. Reviewed in `EARLY_ECONOMY_REVIEW.md`; findings B7-001 to B7-008 | Reviewed |
| K-2 | Known limitation | The tavern child and the sage sleep on pallets for lack of beds; sleepers are the standing sprite turned on its side (no lying frame in the art) | Recorded |
| K-3 | Known limitation | Every number marked provisional (theft, rents, prices, wages, gear bonuses, child food factor, roof-fade timings) awaits the owner's balance review | Awaiting owner |

## Future development (tracked; not complete)

| ID | Feature | State |
|---|---|---|
| F-1 | NPC workshop construction: villagers build houses but not workshops, and never lease ground or fell trees to build | Approved, not built |
| F-2 | Births, children, aging and family growth: households only grow when people move in, so splits are rare | Approved, not built |
| F-3 | Music and sound: the volume settings exist; no audio has been supplied | Approved, not built |
| F-4 | Provisional economy and theft balance (K-3) | Awaiting owner's review |

## Verification by feature

What has been checked here (automated tests and screenshots on this machine) and what only a device
can show. "Device" stays blank until the owner reports on it.

| Feature | Checked here | Needs a device | Device |
|---|---|---|---|
| Movement and camera (dead zone, pan, recenter, map) | start_test, play_test; screenshots | Touch feel, two-finger pan, a real gamepad's sticks | |
| Touch and buttons | Simulated taps in start_test; screenshots at phone size | Real finger sizes, rounded corners, notches | |
| Text size, contrast, readability | Screenshots at phone and desktop sizes | A real phone screen in daylight | |
| Character creation and menus | start_test | Touch, Android Back, gamepad B | |
| Combat and targeting | run_tests, play_test | Touch and gamepad targeting | |
| Conversations | start_test; screenshots | Touch | |
| Shops, buying and selling | run_tests, start_test; screenshots | Touch | |
| Inventory and equipment | run_tests, start_test; screenshots | Touch, gamepad | |
| Theft, witnesses, consequences | run_tests, start_test | Play feel | |
| Building entry and roof fade | run_tests; screenshots | Flicker or timing on a phone | |
| Buying and leasing property | run_tests, start_test | Touch | |
| House placement and construction | run_tests, start_test; screenshots | Placing the footprint by touch and gamepad | |
| Hiring helpers | run_tests | Play feel | |
| Saving and loading | run_tests (saves from versions 1–6) | Android app suspend, resume and storage | |
| Performance | none | A mid-range phone | |
| Windows build | Compiles; icon checked in the released exe | Running on Windows | |
| Android build | Compiles (debug-signed APK) | Install and play | |
