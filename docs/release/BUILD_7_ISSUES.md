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
| B7-001 | 2026-10-18 | Usability | S2 | All | A new player has 5 coins and starves by day 5 without income | Fixed (staging) | `ae0e01f` | Yes (play feel) |
| B7-002 | 2026-10-18 | Bug | S3 | All | Side quests pay less than their text promises when the giver is short of coins | Fixed (staging) | `ae0e01f` | No |
| B7-003 | 2026-10-18 | Bug | S3 | All | Rings, amulet and helmets can be crafted but nobody buys them | Fixed (staging) | `ae0e01f` | No |
| B7-004 | 2026-10-18 | Bug | S3 | All | Wheat cut for harvest work can be kept without paying or being marked stolen | Fixed (staging) | `ae0e01f` | No |
| B7-005 | 2026-10-18 | Usability | S2 | All | Nothing tells a new player how to earn money; the shop window says "Buy from" though it also sells | Fixed (staging) | `ae0e01f` | Yes (readability on a phone) |
| B7-006 | 2026-10-18 | Usability | S3 | All | Hired work pays poorly or is closed: the mine shift pays less than the ore is worth; woodcutting needs an axe the player can't afford | Diagnosed; proposal awaits owner | — | No |
| B7-007 | 2026-10-18 | Bug | S2 | All | Ore and stone deposits never refill and the caravan brings no stone: the village works them out by about day 10, after which no house can be built | Stone imports fixed (staging); depletion itself diagnosed, proposal awaits owner | `ae0e01f` | No |
| B7-008 | 2026-10-18 | Usability | S4 | All | The player can sell a buyer down to 0 coins and kill every wild animal (NPCs leave a floor of 15 coins and 2 animals) | Diagnosed; proposal awaits owner | — | No |
| B7-009 | 2026-10-18 | Bug | S2 | All | The manor's treasury starts (270) below its own 10-day reserve (460) and falls to about 100 by day 5: the reeve has no paid work, for the player or villagers, until about day 12 | Diagnosed; proposal awaits owner | — | No |
| B7-010 | 2026-10-18 | Bug | S3 | Android (all) | The status panel sits too far from the top-left corner; HUD placed by fixed coordinates inside an inset root | Fixed (staging) | `633898f` | Yes |
| B7-011 | 2026-10-18 | Bug | S2 | Android (all, touch) | "Mine"/"Fell" prompts appear while walking past, but tapping a tree or ore does nothing and how to gather is unclear | Fixed (staging) | `633898f`, `c8dce2e` | Yes |
| B7-012 | 2026-10-18 | Enhancement (approved) | — | All | Gather mode: a toggle; tap a resource; walk to it and gather until it runs out or is stopped | Done (staging) | `c8dce2e` | Yes |
| B7-013 | 2026-10-18 | Enhancement (approved) | — | All | Icons from the flat UI pack's set 2 as brown glyphs on a transparent background for the HUD status panel, equipment slots, skills and journal, and the action bar | Ready | — | Yes (looks) |

Agent findings B7-001 to B7-008 come from the early-economy review (`EARLY_ECONOMY_REVIEW.md`),
measured with `game/tests/earn_sim.gd`, seed 1. The owner approved the corrections for B7-001 to
B7-005 and the stone imports of B7-007 on 2026-10-18 (`docs/DECISIONS.md`); B7-006, B7-008, deposit
depletion (B7-007) and B7-009 wait on the investigation's proposals.

Test evidence for `ae0e01f` (run on this machine):
- `run_tests.gd`: 632 checks, 0 failures (`test_build7_economy` is new)
- `start_test.gd`: 221 steps, 0 failures
- `play_test.gd`: 37 steps, 0 failures
- `households_sim.gd --seed 2 --days 30 --crowd 3`: 100/100 alive, coins and grain conserved
- `python3 -m unittest discover -s tests`: OK
- `check_interactions.py`: 65 interactions, 0 problems
- Screens looked at (phone layout): the opening message, the journal's Quests page, the reeve's offer and his "can't spare" answer, the tavern counter, and a trade window from conversation.

### Issue details

### B7-001 Not enough money to survive the start
- Reported: 2026-10-18, agent review of the owner's question; all platforms.
- Evidence: `earn_sim.gd --strategy idle`: coins 5 → 3 → 1, dead on day 5 at 19:22.
- Root cause: `start_coins_player` 5. Food costs about 3 coins a day (`player_hunger_per_hour` 3).
- Files: `game/data/balance.json`.
- Approved (owner, 2026-10-18): 20 coins, provisional, for new characters only.
- Fix: `start_coins_player` 20. It applies to new games and heirs (the starting kit); a loaded save keeps its coins.
- Tests: `start_test` (20 coins at the start); `run_tests::test_build7_economy`.
- Commit: `ae0e01f`.
- Device check: whether the start feels fair in real play.

### B7-002 Quest rewards cut to the giver's purse
- Evidence: `quests.gd:268` pays `mini(reward, n.coins)`. In the runs the smiths held 1–15 coins
  while "Ore for the forge" promises twenty.
- Root cause: offers are made without checking that the giver can pay, and nothing is set aside.
- Approved (owner): offer paid quests only when the giver can pay; reserve at acceptance; pay exactly; return on cancel or expiry; safe across save and load.
- Fix: `Quests.can_fund`, `_reserve`, `_release`, `on_giver_died`, `release_all`, `migrate_reserves`, `reserved_total`. An offer the giver can no longer pay is withdrawn at acceptance with a reason. A dead giver gets the reserve back before inheritance. The player's death returns all reserves. Save version 7: older saves fund accepted quests on load if the giver can pay; otherwise completing pays only once they can. `World.total_coins` counts reserves. The same applies to hired work's wages.
- Interaction manifest: INT-062 (new); INT-038, INT-046, INT-031 updated.
- Tests: `test_build7_economy` (reserve, save round trip, giver's death, lapse, player's death, v6 migration, poor giver), `test_quests`, `test_hiring`, `start_test`.
- Commit: `ae0e01f`.

### B7-003 Craftable jewellery and helmets have no buyer
- Evidence: `npc_brain.gd:13-22` `BUYS` lists no ring, amulet, leather cap or iron helmet.
- Approved (owner): merchants buy these within their funds, stock and trading rules.
- Fix: `BUYS.merchant_goods` adds copper ring 3, gold ring 2, amulet 2, leather cap 3, iron helmet 2 (stock caps; provisional). The caravan carries the surplus away like other made goods.
- Interaction manifest: INT-019 updated.
- Tests: `test_build7_economy` (wants, price, sale paid from the purse, cap, no coins means no sale).
- Commit: `ae0e01f`.

### B7-004 Harvest-work wheat is never the farmer's
- Evidence (code reading; not run): `quests.gd:177` and `world.gd:1093` treat wheat cut under a
  harvest job as not theft. If the job lapses, the wheat stays with the player unmarked: about 48
  coins of wheat instead of a 6-coin wage, up to 3 jobs at once.
- Approved (owner): the wheat stays the employer's; abandoning the job is theft.
- Fix: `Quests.settle_harvest` on a lapse: the cut wheat (`harvested`) the player carries is marked stolen from the farmer, then what is in the home chest. The farmer remembers catching the player, and a theft goes on the record. Completed work is unchanged. Wheat already sold or eaten counts in the theft record, but no mark can follow it.
- Interaction manifest: INT-064 (new); INT-046 updated.
- Tests: `test_build7_economy` (18 carried and 6 in the chest marked, the theft recorded, the farmer knows).
- Commit: `ae0e01f`.

### B7-005 Earning money is undiscoverable
- Evidence: the opening line is only "Explore the village: talk to people, work, trade, build."
  (`main.gd:476`). "Any work for me?" has no marker. The shop window is titled "Buy from …"
  (`game_ui.gd:1243`).
- Approved (owner): unobtrusive guidance, no tutorial; "Trade with …".
- Fix: a new game's message: "For paid work, ask farmers, miners, woodcutters or the reeve "Any work for me?". Who buys what is in the journal." (8 s). The journal's Quests page always ends with "Earning money" (who buys what). The shop's labels and title read "Trade with …".
- Tests: `start_test` (the message, the journal note, the shop labels and title). Screens looked at: `opening`, `journal_quests`, `shop`, `trade`.
- Commit: `ae0e01f`.
- Device check: readability of the message on a phone.

### B7-006 Hired work pays less than doing it alone
- Evidence: the mine shift pays 8 for 6 iron ore, which sell for about 18. The woodcutting job
  needs an axe the player doesn't start with.
- Fix: proposal; awaiting the owner.

### B7-007 Deposits run out and stone has no source
- Evidence: `earn_sim.gd --strategy observe` (the village alone): iron, coal, stone and copper all at
  0 by day 10 (seed 1). `caravan_import_stock` brings iron, coal and copper, not stone. A house
  needs 20 stone.
- Root cause (investigation, 2026-10-18): extraction is not driven by demand. Fixed buyer stock caps plus a caravan that buys everything above half the cap every 2 days make an unlimited export sink. 79% of stone mined by day 10 was exported; none was used in the village. Nobody checks stock before mining. See the long-run report.
- Approved (owner): stone in the caravan's goods, with a defined outside source and real quantities and prices.
- Fix (stone imports): once the village's stone deposits are at or under `caravan_import_when_left`, each caravan brings at most 20 stone from a quarry on its road. It is sold to the raw-goods merchants, the stone sellers, at value × 2.0 (cartage; provisional), up to their cap and keeping their cash floor. The coins leave the village. While it brings stone, the caravan buys none of the village's.
- Interaction manifest: INT-065 (new); INT-035 updated.
- Tests: `test_build7_economy` (none while the village has its own, at most a cart, within caps and floor, the price recorded, coins leave, no export).
- Commit: `ae0e01f`.
- Still open: depletion itself (proposals P1.1–P1.5, awaiting the owner).

### B7-008 The player has no floor on buyers' coins or wildlife
- Evidence: the mining run left the smiths at 0–1 coins; the hunting run killed all 12 wild adults
  on day 1 and none came back.
- Not approved yet (owner): the 15-coin reserve for player sales; wildlife respawn. Investigation proposals P2 (wildlife) and P3 (operating capital) await the owner.

### B7-010 The status panel is far from the top-left corner on Android
- Reported: 2026-10-18, owner, Android phone (Build 7).
- Reproduction: start or load a game on the phone; the health, hunger, stamina, coins and clock panel sits well in from the corner.
- Root cause: the panel was placed at a fixed `position = (12, 12)` inside the interface root, which on a phone is inset by the display's whole safe-area band (a camera cutout insets the entire side, not just the hole) and at least `CORNER_MARGIN` (28, 14): the offsets added up. The action bar and the log were anchored, but inside the same inset root.
- Fix: the HUD has its own full-screen root (`GameUI.hud_root`) that keeps system bars clear but not a cutout's band; the status box is anchored top-left, the log top-right and the action bar bottom-right, each `HUD_MARGIN` (12 on a phone, 10 on a desktop) from the edges, applied on every resize (`fit_safe_area` → `_fit_hud`). A camera cutout (`DisplayServer.get_display_cutouts`) moves only an element it would overlap, just past it (`_avoid_cutouts`). Windows keep their existing safe-area and corner margins.
- Files: `game/scripts/ui/game_ui.gd`, `game/scripts/main.gd` (`--safe` / `--cutout` screenshot options to simulate a phone display), `game/tests/start_test.gd`.
- Tests: `start_test` (the status box 12 units from the corner, the action bar 12 from the bottom-right, a simulated camera hole: the box steps past it only). Screens looked at: a 2400x1080 phone with and without a simulated top-left camera hole, 1920x1080 and 1280x800 desktops.
- Device check: needed (the real phone's safe area and cutouts).

### B7-011 Tapping trees and ore does nothing; gathering is unclear
- Reported: 2026-10-18, owner, Android phone (Build 7).
- Root cause (from the code):
  - A tap only acts on a resource if it lands within 1.8 tiles of the player and the facing probe then finds it. A tap on a tree's canopy (one or two tiles above the trunk, the only cell the game knew as the tree) found nothing and only walked the player under it; a tap on ore, a solid cell, asked for a walk that failed silently.
  - Nobody starts with an axe (the kit is a rusty sword and a rusty pickaxe), yet the prompt still said "Fell this tree".
  - Resource prompts were shown for whatever was in front of the player, so they flashed while walking past.
  - Tools need only be carried, not equipped (`PlayerState.tool_of`); that rule is unchanged.
- Fix: the prompts say when a tool is missing and where to get it ("A tree: requires an axe (the smith sells them)") and wait until the player stops (`633898f`). A tap or click on a seam, tree (trunk or canopy) or field finds it through the registry (`ResourceNodes.node_at`, exact cell), walks there and uses it once; a refusal is always said (the tool and where to get it, worked out, not ripe, out of reach). Use with keys or the pad still acts on what is in front. The tool rule (carried, not equipped) is unchanged.
- Files: `game/scripts/main.gd`, `game/scripts/core/resource_nodes.gd`, `game/tests/start_test.gd`; INT-068.
- Tests: `start_test` (a canopy tap without an axe says so; a tap on a seam outside Gather mode walks there and mines once; Use in front of a seam in Gather mode). Looked at: Gather mode on a 2400x1080 phone.
- Device check: needed.

### B7-012 Gather mode
- Approved by the owner, 2026-10-18: a Gather button; tap a resource; walk to it and gather until it is depleted or stopped; the same rules for time, tools, stamina, depletion, inventory, ownership and theft.
- Implementation: a Gather button (the branch icon) beside Use, G on the keyboard, D-pad down on the pad; Gather and Attack exclude each other. A tap or click (or Use in front) chooses a resource from the registry; it is outlined; the player walks there by the usual pathfinding and gathers it a cycle at a time through the existing action (time, tool wear, yield, skill bonus, depletion, inventory, theft; no stamina, the existing rule) until it runs out, the pack is full, the tool is gone, the player is hurt or moves, chooses another or turns Gather off. Gather mode stays on when a resource runs out; nothing else is chosen automatically. Someone's field warns once; hired harvest work does not. Wild game is hunted with the weapon. The prompt shows "Walking to the …" or "Mining the iron seam · 60 left"; the progress bar sits above the player. Not saved.
- Files: `game/scripts/main.gd`, `game/scripts/ui/game_ui.gd`, `game/scripts/core/resource_nodes.gd`, `tools/import_game_assets.py` (G and D-pad prompt icons), `game/tests/start_test.gd`; INT-068.
- Tests (`start_test`): the toggle and Attack exclusivity; selection by tap; the outline; walking to it; repeated cycles to depletion; mode kept; no axe; a tree felled once; cancelled by moving and by Gather off; a full pack; a farmer's field warned then taken as theft; a single use outside Gather mode; Use in front (keys and pad); out of reach; wild game; nothing saved.
- Device check: needed (touch on the phone, a real gamepad).

### B7-013 Brown glyph icons
- Owner, 2026-10-18: icons from the flat UI pack's set 2, drawn as a brown glyph on a transparent background (not a white glyph on a brown tile), for the HUD status panel, equipment slots, skills and journal, and the action bar. Status: ready, after B7-012.

### B7-009 The manor cannot afford paid work for its first twelve days
- Reported: 2026-10-18, agent, while checking the reeve's work.
- Evidence: seeds 1 and 2 (scratch measurement, no player). The treasury is 270 at the start against a reserve of 460 (10 days of obligations of 46). It falls to about 100 by day 5, and reaches the reserve only on day 12 (seed 1) or 13 (seed 2). Until then the reeve has no work for the player (he says the manor's chest can't spare a wage), and no NPC day labour is paid either.
- Root cause: the starting treasury is below the manor's own reserve rule.
- Fix: none yet; a balance decision. Options: a larger starting treasury; a smaller reserve for day labour (e.g. 3 days); or day labour allowed above the guards' two-day payroll. Awaiting the owner.

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
