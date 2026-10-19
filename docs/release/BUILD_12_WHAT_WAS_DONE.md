# Build 12: what was done

This report is about what was built. It goes item by item through the three lists you gave:
- the Build 8 master fix list (B8);
- Build 11 punch list 1 (PL1);
- Build 11 punch list 2 (PL2).

For each item it says what you asked for, what was built, and how you will see it in the game. The second
part lists every problem the Build 12 audit found and whether it has been fixed since, in the Build 13
corrective work.

| Status | Meaning |
|---|---|
| **Done** | Built in full and checked by automated tests (visual items also checked in screenshots) |
| **Mostly done** | The feature works, but part of it could not be built, usually because the art packs have no art for it. What is missing is named |
| **Blocked** | Needs something from you first |

**What "checked" means here:**
- Nothing has been tried on a real phone, a real controller, Windows hardware or a Steam Deck.
- The Linux build was launched and drew the village.
- Everything else was checked by the game's automated tests and by screenshots taken on this machine.

## Scorecard

| List | Items | Done | Mostly done | Blocked |
|---|---|---|---|---|
| Build 8 master list | 24 (plus B8-001, already fixed earlier) | 22 | 2 (B8-007, B8-016*) | 0 |
| Punch list 1 | 13 | 8 | 4 | 1 (PL1-11, stages 2 to 5) |
| Punch list 2 | 15 | 10 | 5 | 0 |
| **Total** | **52** | **40** | **11** | **1** |

\* B8-016 had a bug in Build 12 (retirements left trades short). It is fixed in Build 13 and counts as
done from Build 13 on.

---

## Part 1: item by item

### Build 8 master fix list

| ID | You asked for | What was built | What you see in the game | Status |
|---|---|---|---|---|
| B8-001 | (earlier fix) | Already fixed before this list | — | Done earlier |
| B8-002 | The village looked pasted onto the land | The whole village was laid out again as one place: 26 buildings, roads, a mine, a new Sawmill, fields, pens and stalls on one continuous ground. Every room has a floor | One village with no seams or pasted blocks. The edge runs into the countryside without a line | Done |
| B8-003 | Floating or half-drawn trees | Trees are now only real tree objects; no tree pictures are left in the map layers | No floating trunks or canopies | Done |
| B8-004 | The mining area was broken | A rock quarry hill with one connected cart track from the mine entrance to the cart stop; every ore seam can be walked to; no trees on the rim | A proper mine hill you can walk round and work | Done |
| B8-005 | Trees: collision and see-through | Checked: only trunks block you, canopies fade when you walk behind them, you can still chop a faded tree | You walk under canopies; the trunk stops you | Done |
| B8-006 | The harvest animation never stopped | One press is one swing, then your character goes back to standing | Mining and chopping stop when the job is done | Done |
| B8-007 | The wrong tool was shown in hand | You and the villagers now hold the right tool (pickaxe, axe, hammer) while working | The right tool in hand, shown over the throw motion | Mostly done: the art packs have no real tool-swing animation |
| B8-008 | Ore deposits looked like the wrong ore | Each ore has its own rock picture, so a rock always gives what it looks like | Iron rocks give iron, coal rocks give coal | Done |
| B8-009 | Pickup messages needed icons | Every pickup shows a small line with the item's icon, such as "[icon] +1 Iron ore" | Icon messages for ore, logs, saplings, flowers, wheat and loot | Done |
| B8-010 | You could not open the Pack while harvesting | Opening any window stops the job at once | Open the Pack whenever you like | Done |
| B8-011 | No way to cancel a job | B, Esc, right-click or a tap cancels at once | Cancel any job | Done |
| B8-012 | Inventory highlight boxes were too big | The highlights fit their slots | Neat inventory focus | Done |
| B8-013 | Action prompts were too big | Prompts fit their text and sit above the touch buttons | Smaller, tidier prompts | Done |
| B8-014 | A villager standing at a station blocked it | When several things are in reach you choose: Q or Tab on the keyboard, D-pad left and right on a pad. Stealing is never the default | "Use forge / Talk to Alice (1 of 2)": you pick | Done |
| B8-015 | Weapon racks | Racks are decoration: solid, nothing to take | Racks look right and don't pretend to be usable | Done |
| B8-016 | Key trades lost when a worker dies | If a smith, carpenter, tanner, cook, tavern keeper or merchant dies or retires, after 3 days a jobless villager is apprenticed; if there is nobody, a newcomer arrives with the caravan (within 10 days) | The forge comes back to life after a smith dies | Done (retirement fixed in Build 13) |
| B8-017 | Personal chests in public rows | Each family's chests stand in its own door yard | Chests by the houses they belong to | Done |
| B8-018 | Roofs flickered indoors | Fixed: a lifted roof stays lifted | Walk indoors without the roof blinking | Done |
| B8-019 | The HUD was unclear | The bars are labelled, the food icon is bread (it was a cannon), and a bar blinks red when low | Clear Health, Food and Stamina bars | Done |
| B8-020 | No cause of death | Death is recorded and shown: "You starved.", "Killed by Wat the guard.", "You died of old age." | The death screen tells you why | Done |
| B8-025 | You were drawn behind tabletops | Tabletops are layered properly with characters, from all four sides | No more walking "into" tables | Done |
| B8-026 | Grey boulders could not be mined | Every boulder can be mined: small ones in 2 swings, large ones in 6, in the village and outside it | Mine any boulder for stone | Done |
| B8-027 | Sprint | LT toggles sprint on a pad and Shift holds it on a keyboard. Sprint is 1.5x speed and uses stamina | Run when you need to | Done (keyboard and pad; touch has no sprint button yet) |
| B8-028 | Sawmill | A named Sawmill building holds the sawhorse; planks are made there | The Sawmill is where you saw planks | Done |
| B8-029 | Calendar, aging, families, animal life cycles | An 8-day year in four seasons. Everyone ages: children grow up, adults work, elders retire and in time die of old age. Couples form, babies are born, and families inherit. Your grown child carries on after you. Animals have young, adult and old stages, with baby sprites | Babies and children in the village; the date and season on the clock; elders slowing down; calves and chicks in the pens | Done |

### Build 11 punch list 1

| ID | You asked for | What was built | What you see in the game | Status |
|---|---|---|---|---|
| PL1-01 | **Critical:** leaving Settings > Controls froze the game | Found and fixed the cause (the game stayed paused). Back now returns to wherever you came from | Settings never leaves you on a grey, frozen screen | Done |
| PL1-02 | One Settings screen with tabs and Back | One Settings screen with Audio, Display, Interface, Controls and Wiki tabs; Back from the button, Esc or the pad; settings are saved | A single tidy Settings screen | Done (the volume sliders have no sounds to control yet: the game has no audio) |
| PL1-03 | Choose how many to buy or sell | A "how many?" control with a slider, minus and plus, Max, a live total, Confirm and Cancel | Buy 8 coal in one go and see the total first | Done (Build 13 adds unit-by-unit pricing) |
| PL1-04 | Reliable healing and an Apothecary | Four medicines (bandage 15, poultice 30, healing tonic 50, strong tonic 80 health), 2 bandages to start, and the sage runs an Apothecary that brews from flowers and restocks from the caravan | Buy, brew and use medicine; never wasted at full health | Done |
| PL1-05 | Numbers inside the bars | Health, Food and Stamina show "85/100" inside the bar, with an outline | Exact numbers at a glance | Done |
| PL1-06 | Every stone minable, by size | Small boulders 2 swings, large 6; a missing-tool message; a mined boulder disappears and stays gone | Every boulder works | Done |
| PL1-07 | Villagers sunk into beds and chairs | Sleepers lie on the bed properly. Villagers eat sitting at their chair | People sleeping in beds and eating at tables | Mostly done: no sitting art exists, so a seated villager uses the standing picture cut at the knees |
| PL1-08 | Show what food and medicine do | Effects come from the item data and show in shops, the quantity control and the Pack: "Restores 12 Health / 4 Food" | You can see what each thing does before using it | Done in Build 13 (Build 12 missed medicines) |
| PL1-09 | Gold star over the person whose job you took | A gold star follows the villager who owes you payment, survives saving, and clears when you are paid | You always know who to report back to | Done |
| PL1-10 | Player businesses and real villager demand (4 stages) | Stage 1: rent a market pitch (5 coins a day). Stage 2: villagers walk over and buy only what they really need, with their own money. Stage 3: a larger stall, and shops in rooms you built, with a counter, shelves, stock chests and work equipment you place. Stage 4: hire an attendant who sells while you are away | Run a stall or a shop and watch villagers come and buy | Mostly done: workers crafting from shop stock, a stall display picture and shops in rented village houses are not built yet |
| PL1-11 | Google Drive cloud saves (5 stages) | Stage 1: saves are one portable file with a world id, play time, device and character name, ready to move between devices | Saves are ready for cloud transfer | Blocked: stages 2 to 5 need you to register a Google sign-in app |
| PL1-12 | The red flowering plant could not be picked | It is now a pickable plant; it gives a flower and regrows | Pick the red flowers in the village | Mostly done: the countryside never draws this plant, so it exists only in the village |
| PL1-13 | A recognisable stove | A hearth with a pot; the prompt reads "Use Stove"; the window is titled "Stove — Cooking & Tonics" | You can tell the stove apart | Mostly done: no chimney (the wall row sits above it) |

### Build 11 punch list 2

| ID | You asked for | What was built | What you see in the game | Status |
|---|---|---|---|---|
| PL2-001 | "Alice is using the forge" with nobody there | A station is busy only while a villager is actually standing at it and working | No more phantom "in use" messages | Done |
| PL2-002 | Usable chests, locks and lockpicking | Your chests are yours to use; others' are theft to take from; empty-house chests are decoration. Locks, padlocks, lockpicks (using Stealth), witnesses and fines | Store and take freely, fit a padlock, pick a lock when nobody's looking | Done (Build 13 counts theft by what was taken) |
| PL2-003 | Garbled villager dialogue | Sentences fixed, no repeats, proper "James's", no internal names showing, choices wrap | Readable conversations | Done |
| PL2-004 | Hunting gave nothing | Kills leave a visible pile you can tap to take (spoils after 3 days). Rabbits give a pelt, chickens give feathers, and pelts and hides tan into leather | Hunt for meat and leather | Done (the feather icon is a stand-in) |
| PL2-005 | Skill trees too short | Every skill now runs from level 1 to 10 on a slower curve, and every perk listed actually works | Long-term progress in every skill | Done |
| PL2-006 | Outside the village flowers and rocks could not be used | Every flower outside is pickable and regrows; every boulder is minable | Gather anywhere, not only in the village | Done |
| PL2-007 | Fields never looked ripe | Fields now stand ripe for 12 hours before the farmers cut them | Golden fields you can actually see | Done |
| PL2-008 | Expandable property | Start with a house and add rooms later (workshop, smithy, kitchen, bakery, apothecary, storage, living quarters) without knocking anything down | Grow your property over time | Mostly done: each room has its own street door (no inner doorway art), and the two plots have room for about one extra room |
| PL2-009 | An in-game encyclopedia | The Wiki: 209 pages built from the game's own data, covering items, recipes, resources, skills, jobs, animals and stations, plus controls, how-to guides, production chains, search and links | Settings > Wiki, also from the title and pause menus | Done |
| PL2-010 | A recognisable sawhorse | A trestle bench with logs | Looks like a work bench for sawing | Mostly done: no sawhorse or saw art exists |
| PL2-011 | You could reach through walls | Nothing can be used, gathered or attacked through a wall, either way | No more chopping trees from indoors | Done |
| PL2-012 | Storage needed quantities and better pad focus | The same "how many?" control, plus Store all and Take all; focus stays where you were | Fast, controller-friendly storage | Done |
| PL2-013 | Usable furniture | Sit on chairs, sleep in your own bed and wake beside it, cook at the home hearth, prepare food at the table | Your home works | Mostly done: the sitting pose is the standing picture cut at the knees |
| PL2-014 | Workshops added onto your house | Same system as PL2-008: rooms with working stations | A smithy or kitchen on your own property | Mostly done (as PL2-008) |
| PL2-015 | Farming and livestock | Clear land, till by hand or with a craftable plough, sow wheat, carrots, potatoes and herbs by season, and keep seed back. Fence pens, buy animals, collect eggs, milk and wool. New recipes: cheese, egg bread, cloth, bandages | Start a farm from nothing on land you hold | Mostly done: coops, hired farm help, draught animals, trapping and watering are not built, and all crops share the wheat picture |

### Also new in Build 12, outside the lists

- **Rooms you build get a full floor.** A house, workshop or shop you built used to show grass inside.
- **Theft is never the default choice** when several things are in reach.
- **The "how many?" control** keeps the controller in the right place.
- **New art:** 34 new pieces with their source recorded:
  - baby animals, produce and seed icons (Cozy Farm);
  - medicine, pelt, lockpick, padlock and plough icons (Shade);
  - keyboard and pad button prompts (Kenney).

---

## Part 2: the problems the Build 12 audit found, and whether they are fixed

Build 13 corrective work, all pushed to staging and covered by new tests:

| # | Problem found | Fixed? | How |
|---|---|---|---|
| 1 | A worker retiring from a fully staffed trade opened no post, so the village slowly lost smiths, cooks and merchants | **Fixed** | A retiree is no longer counted as staff; an apprentice takes over (tested) |
| 2 | Gold ore could not be found anywhere, so gold bars and rings could not be made | **Fixed** | One gold seam in the mine (8 units, needs Mining 3); old saves get it too. Gold stays rare: the caravan brings none |
| 3 | Medicines showed no "Restores N Health" text | **Fixed** | Shown in shops, the quantity control and the Pack |
| 4 | A shop attendant could be hired away to carry building loads, leaving the counter empty while you still paid | **Fixed** | Attendants cannot be hired as carriers |
| 5 | The medicine, Apothecary and gold-star tests were not run by the automatic checks | **Fixed** | Added to the automatic test run |
| 6 | You could sell until a merchant had no money left, and a bulk sale paid the top price for every unit | **Fixed** (your rules 1 and 2) | Each unit is priced in turn as stock changes; a merchant must have the money for the whole deal |
| 7 | Seeds appeared from nowhere | **Fixed** (your rule 3) | Seeds come from farmers' and the food merchant's own stock. Farmers keep seed from their harvests, and the caravan sells the merchant more |
| 8 | Emptying a chest counted as one small theft | **Fixed** (your rule 4) | Every theft records what was taken, how many and their value; the fine grows with the value |
| 9 | Two tests could never fail ("or true") | **Fixed** | Both now check the real result. (A third test the audit called always-true was checked again and is fine) |
| 10 | Wrong text: the stamina tooltip, the "L3" sprint note, "five coins" at the start | **Fixed** | All corrected; the start text shows the real 20 coins and the 2 bandages |
| 11 | Medicines were filed under Materials in the wiki | **Fixed** | They have their own Medicine category |
| 12 | Out-of-date documents (Build 8 list, punch-list statuses, ledger, manifest) | **Fixed** | Updated |
| 13 | The village has no preparation table, so villagers never make cheese or egg bread, and nobody uses eggs, milk or wool | **Not yet** | Not in the authorised Build 13 list |
| 14 | B on a "how many?" control closes the whole window instead of just the control | **Not yet** | Not in the authorised Build 13 list |
| 15 | Touch screens have no sprint button | **Not yet** | Not in the authorised Build 13 list |
| 16 | A villager walking to a station can arrive while you are using it | **Not yet** | Low priority |

### Still waiting on something outside the code

- **Real hardware checks:** a phone, a controller, Windows and a Steam Deck.
- **Android signing:** a stable signing key, so new builds install over old ones (you add four secrets).
- **Cloud saves:** a Google sign-in app you register (PL1-11).
- **Art not in the packs:** sitting, tool swings, inner doorways, a chimney, a sawhorse and saw, a feather, separate crop pictures, a baby boar, and a stall display.
