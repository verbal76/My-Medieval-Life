# Build decisions (first playable, The Well build test)

Implementation choices made while building the Godot prototype in `game/` where the Game Designer
export and the owner's decisions left a gap. Each one is an **agent proposal** until the owner
approves it; owner decisions live in `docs/DECISIONS.md`. Tunable numbers are in
`game/data/balance.json`, so changing one needs no code.

## Village and people

| Decision | Why |
|---|---|
| 100 villagers in 23 households, plus 6 bandits, with jobs from `game/scripts/core/population.gd` (`JOBS`, 26 children, 18 elders) | The owner's target of 100 NPCs. The job mix is chosen to keep food, tools and coin moving |
| The map is a fixed 120 x 90 tile village built from Shade's sample maps (`tools/build_village.py`) | A hand-made village first; world generation comes later |
| Trees are Shade's two-tile trees (canopy top and bottom over a stump, as in his sample maps): only the trunk cell is solid, the canopy is drawn over people and animals and is walkable for the player and villagers' paths, and the canopy over the player fades to 45% in 0.15 s. People are drawn with their feet on their position (5 px lower than before), so the player can step behind a canopy | The owner's request: walk between and behind trees, with only the trunk blocking. The generated forests had paired canopy halves with bushes and stumps, so a bush blocked while the tree's trunk did not |
| NPCs near the player update every frame, the rest every 0.5 s with the same rules | 100 NPCs at phone frame rates |
| Coins only enter through the merchant caravan; the reeve taxes, pays for repairs and gives relief; guards are paid | Bob's spec wants a closed economy; something has to stop money pooling in one place |
| Households share a food "tab": anyone without coin can eat on the richest member's money | Children and elders have no income |
| Traders keep 15 coins (`trader_cash_floor`) instead of spending everything on stock | A smith and a merchant spent their last coins on stock and their household starved |
| Miners mine only ore someone will buy | A miner starved holding unsellable stone and coal |
| Pottage instead of bread; there is no mill | No mill art; one cooking chain is enough to test the economy |
| NPCs craft at stations regardless of their skill level; skill levels gate only the player | Keeps 100 NPCs simple |

## Food and the long-run economy (the day-12 starvation)

Diagnosed with `game/tests/econ_report.gd`, which reports each day what was made, eaten, exported
and fed to animals, plus meals missed and why. Before these changes the village fell from 100 to 43
people by day 50. Causes, in the order they bite:

1. Fields ripened only at 06:00, so a 2-day crop took 3 days: a third of the harvest lost.
2. Wheat was eaten raw (20 food points) instead of cooked (120 points per wheat as pottage);
   raw eating used 23% of all wheat.
3. The mine is worked out around day 12, and its 11 miners and labourers became jobless with no
   income.
4. Coins pooled with the reeve (taxes greater than spending), the tavern and the cooks; families
   spent what they had on tavern ale and tavern meals instead of grain.
5. Relief went only to adults, so households of elders and children got nothing.
6. The caravan bought the village's food even when it was short.

| Decision | Why |
|---|---|
| Fields are checked every hour and ripen when grown | Cause 1 (a timing defect) |
| Households cook grain at home with the cook's recipe (2 wheat -> 6 pottage); people go home to eat their grain instead of eating it raw | Cause 2. No food is created: it is the same recipe the cooks use |
| Families stock the pantry with grain from farmers before buying tavern meals, and go to the tavern only with 12 coins to spare and a stocked larder | Causes 2 and 4: villagers respond to hard times |
| When the mine is worked out, miners become hands at the manor, paid 6 coins a day from the reeve's taxes | Cause 3, and it spends the reeve's hoard back into the village. No new coins |
| Relief is food into the household's pantry (see the manor section below) | Cause 5 |
| The caravan does not buy food while the village holds less than 3 days of it | Cause 6 |
| Famine (less than 2 days of food per person): keepers slaughter beyond the breeding stock for meat and feed only that stock; harvesters carry one day of feed instead of four | People come before livestock; herds can recover afterwards |
| Hands at the manor take over fields no living farmer works | Land should not lie idle while people starve |

Hunger rates, starvation damage, yields and recipes are unchanged.

## The manor: treasury, taxes, wages, granary and relief (owner-approved B3 plan)

Investigated with 100-day comparisons (`game/tests/econ_report.gd`): the old rules (a 15% daily tax
on each adult's coins above 60, relief of 2 coins a head once a pantry was empty, and the
treasury held as the reeve's own coins) left about two-thirds of all coins in the treasury by day
100, households poorer every month, and government ending if the reeve died.

| Rule | Value |
|---|---|
| The treasury is the manor's (`World.treasury`); the reeve keeps a 30-coin purse and is paid 6 a day | It outlives the reeve |
| Tax per household on cash above 40 + 20 per member: 12% while the treasury holds under 10 days of its obligations (wages), 6% up to 30 days, none above | `tax_*`, `treasury_*_days` |
| Wages, once a day: sage 4, reeve 6, guards 6, manor hands 6 | `pay_guards` |
| Relief: a household that can cover under 2 days of food (pantry plus what its cash buys as grain) gets food into its pantry up to 3 days: granary grain first, then grain or pottage the manor buys for it. Under 1 day of food it is helped even below the reserve, down to one day of wages; otherwise only from money above the reserve | Relief is food the whole household can eat, never coins |
| Repairs from money beyond 3 days of wages (40%, at most 40 loads) | Bought from the village's sellers |
| Granary: buys surplus wheat up to 7 days of village food from money above the 10-day reserve; a farmer keeps 3 days of household food, the livestock feed reserve and 10 more; a merchant keeps half its stock; nothing is bought in a famine or when the village holds under 3 days of food | No artificial shortages |
| Day labour: an adult of a short household who has earned nothing today may work a day at the manor for 6 coins while the treasury is above its reserve; farmers, cooks, hunters and tavern keepers stay at their work | |
| A household needing relief on 4 of the last 7 days is named in the log | Relief must not hide a living that does not pay |
| Building plots are sold by the manor; the price goes to the treasury (`World.buy_plot`). The two plots are clearings at the forest edge north of the east houses (they used to lie over houses b20-b22) | Owner asked for the overlap fixed; see DECISIONS |
| The evening business and the wages run at most once a day (`last_reeve_day`, `last_payday`, saved) | No double payments |
| Saves are version 3 (treasury, granary). Older saves move the reeve's coins beyond his purse into the treasury; no coin is lost | CLAUDE.md section 7 |

## Settlers' provisions, inheritance, households and work (agent proposals)

| Decision | Why |
|---|---|
| The manor granary starts with 7 days of the village's food (420 wheat for 100; 377 since children eat 0.6 of an adult's food) and each household brings 2 wheat a head, besides its 3 pottage. Finite: nothing is added later except by purchase | A failed first harvest killed 70 of 100. With these stores a 4-day failure is survived; a 12-day failure still killed 43 of 100 by day 14 (10 since children eat less; `game/tests/scenarios.gd`, seed 1) |
| A household's cash counts as food only up to its share of what the market actually has for sale | In a crop failure the granary sat full while people with coins starved: relief never saw them as short |
| Inheritance: when a villager dies of anything but violence, food goes into the household's pantry and coins and goods to an heir (an adult, else an elder, else a child, lowest id first). A slain villager's purse still lies where they fell; with nobody left in the household, belongings stay there too | Keeps a household's means together; keeps the existing loot and robbery play |
| A pen whose keeper dies or stops farming passes to another farmer, the same household first | Animals were left with nobody to feed them |
| A workstation holds one worker (`capacity` in the village data can raise it). A villager reserves a free station before walking to it and frees it when done; a lapsed reservation is cleared. If all are taken, the villager does something else | Three cooks were sharing one stove |
| An elder pays the family tab when no adult is left | A child starved beside an elder with coins |
| Every villager keeps 7 days of earnings (sales and wages). Each morning, and at once after a death or job change, each household reckons its members, daily food need and cost (food at the cheapest grain price plus firewood), income, food in hand, and runway (cash and trade stock someone is buying). It is sustainable when income covers cost or it holds 10 days of food or runway | Households see trouble coming instead of reacting only to hunger |
| Job mobility: the unemployed, and adults of a household unsustainable for 3 mornings who have 5 days of history and earn less than their share of its costs, look at the job board: manor hand (wage, while the treasury can afford 20 more days), farmhand (up to 2 per field), woodcutter (one per 30 standing trees), hunter (one per 6 game animals above the breeding stock), miner (while ore lasts). Pay is what those doing the job actually earned lately; a needed tool must be affordable and is counted over 10 days; the walk from home counts. They move only for 25% (and 2 coins) more than they earn now. A taken opening is gone for the next applicant. Not back to the job just left for 14 days; 7 days to settle after a change | Uses only existing jobs and wages. Skilled trades need training the game does not have |
| The manor lets its newest hand go when it cannot pay two days of wages | Wages must stay finite |
| Children eat less (owner-approved; the living-world design counts a household's food per member, adjusted for age-dependent consumption). Villagers have no ages, so the role decides: a child gets hungry `child_food_factor` (0.6) as fast as an adult and so eats 0.6 of an adult's food, in the same whole portions eaten less often. Every food reckoning weights members the same way (`NPCBrain.food_factor`, `household_day_food`, `village_day_food`): a household's days of food and its share of the market, relief, a farmer's household keep, the granary's target and its starting stock (7 days of the weighted need: 377 wheat instead of 420), the village's food days (famine), the caravan's food reserve, the household reckoning, and so the food quest's `household_food_below` and day labour. The 0.6 is an agent proposal, provisional: balance review pending | Children of about 4 to 13 need roughly half to three quarters of an adult's food; 0.6 is a round middle. Elders are left at 1.0 (not asked) |

## Player

| Decision | Why |
|---|---|
| Permadeath: the heir keeps the family's house, chest and plots, starts every skill from nothing and carries only the starting kit (5 coins, rusty sword and pickaxe, bread, rotten apple, plain clothes); what the dead carried lies where they fell, for anyone to take, the heir too. The heir's kit and coins are new to the village (counted in `coin_sources`). Anyone fighting the dead player stops | Owner rule, 2026-10-18 (house, chest and the dropped bag settled by the owner's answers) |
| The journal (Menu, or B): the village record written into an open book, two parchment pages at a time, six lines a page, a heading for each day (repeated as "continued" at the top of a page that starts mid-day), opening at the latest pages | The owner asked for a journal that looks like a book |
| Building: buy a plot from the manor (the price goes to the treasury), a wooden frame appears, deliver 30 planks, 20 stone and 10 logs, and the house stands. A progress bar over the frame and in the build window shows the share of loads delivered. Giving up the site returns every delivered load to the pack (what does not fit is left in a bundle at the site), takes the frame down and keeps the plot | The owner's rules (frame with a progress bar, materials only, no extra build time, cancel returns everything) |
| Attacking a villager, or killing a keeper's animal, is a crime: guards nearby and the victim respond | Bob's spec has crime but no penalty system yet |

## Animals (owner rule: a fed pair breeds, babies are half scale, animals become meat)

| Decision | Why |
|---|---|
| Four fenced pens below the market (cows, pigs, sheep, chickens), each kept by one farmer | Livestock needs a place and an owner; Cozy Farm fences fit the art |
| Wild boar (Puny Monsters) and rabbits (Cozy Farm) in the two northern forests | The packs have no deer; boar and rabbit are the game animals available |
| Hunger works like the villagers' (owner rule): it falls 3 points an hour. Below 55 an animal eats: livestock takes its `feed` of wheat from the trough (cow 2, others 1) and walks to the trough by the gate; wild animals graze, one animal per 15 open cells of their wood. At zero hunger an animal loses 10% of its health an hour and dies, about a day and a half after its last meal | The owner: "if you don't feed the humans they die... you get to feed the animals or they die as well". Keepers and the player feed the pens (owner answer) |
| Breeding: a well-fed adult female (hunger 40 or more) gives birth when a well-fed adult male of her kind shares the area. Litter, time between births and growing age per kind (`balance.json` "animals"). Pens and woods have caps | The owner's rule, with numbers that keep herds stable over 10-day tests |
| Babies are drawn at half scale until `grow_days`, then full scale; a baby gives half the meat and no hide | The owner's rule |
| Keepers feed the pen from their wheat, the household's store, or feed they buy. Whoever harvests a keeper's field carries 4 days of feed to the pen first. Keepers slaughter surplus when the pen is nearly full, and cull beyond the breeding stock only when no feed can be had for the next morning | The wheat went to whichever farmer harvested, and pens starved |
| Hunters hunt real animals and never take a kind below 2 adults per wood. Bandits poach near their camp. The player hunts with the sword or a fireball and takes the carcass (meat, hide) | Replaces the old invisible "deer count" |
| Saves from before hunger load with every animal full. Old saves (`save_version` 1) load: the deer count is dropped, and pens and woods are stocked as in a new game | CLAUDE.md section 7 |
| Puny Monsters boar frames 0-3 are used as the walk cycle | **Uncertain**: the sheet has no frame notes |

## Skilled trades and the treasury's excess (Phase 1, agent proposals)

Diagnosed over 90 days (seed 1):
- The mine's iron, copper and coal were gone by day 20, so the smiths could forge nothing.
- The woodcutters' axes wore out with no smith to replace them, and the woodcutters stopped felling.
- A defect left every woodcutter holding 7–9 unsold logs. A woodcutter without an axe went looking for one before selling what was carried.
- The carpenters had no logs from day 36. Both smiths and both carpenters had left their trades by day 87.
- Meanwhile the treasury held money it never spent, above its tax-holiday level.

| Decision | Why |
|---|---|
| A woodcutter or miner who has lost the tool sells what was gathered before looking for a new one | Defect fix |
| Once the village's own seams of an ore (or coal) are down to 10 units, each passing caravan sells it to the smiths: up to 12 iron ore, 8 coal and 6 copper ore in stock, at the item's value. Smiths keep the trader cash floor. The coins leave the village (`coin_sources` falls), the first outflow to balance the caravan's purchases | Inputs for the forge once the mine is worked out; real money out of the village |
| Repairs also buy iron bars from the smiths (fittings, nails) | Recurring local demand for the smiths' work |
| Public works: while there is a reeve, a quarter of whatever the treasury holds beyond its tax-holiday level (30 days of wages) is spent each day on planks from the carpenters, iron bars from the smiths and stone, at most 60 loads, each seller keeping a few. The goods are used up | Legitimate spending of the excess. With no reeve the money lies idle, so poor government is still possible |
| Tool wear was already in place (axes and picks break); with smiths able to forge, it is real demand again | No new rule needed |

Result, 3 seeds over 100 days:
- 100 of 100 villagers alive on every seed.
- Both smiths and both carpenters stay in their trades on every seed, with steady income (carpenters 211–415 coins on day 100, smiths 42–245).
- Public works spend 500–600 coins per seed.
- The treasury now levels off near its 30-day line instead of climbing without limit.

## Side quests (owner-authorized mechanic; details are agent proposals)

| Decision | Why |
|---|---|
| Quests are data (`game/data/quests.json`): who offers one (a job or role and a condition on what they hold, their household's food, or a robbery they remember), the goods asked for or the target, the reward and the giver's lines | Easy to add and tune without code |
| Five to start, each from a real state of the simulation: a smith short of iron ore, a cook out of firewood, a woodcutter whose axe broke, an elder whose household is short of food, a villager robbed by a bandit who still lives | Quests that grow from what villagers need |
| Each dawn, offers are re-checked: a need that has passed is withdrawn, new ones are offered (lowest villager id first), at most 4 open offers and 3 accepted quests | Deterministic; not a crowd of quest givers |
| Delivered goods go to the giver; the reward comes from the giver's purse, all they have if less (a poor giver says so). Nothing is created | The economy stays closed |
| A quest fails if its giver dies. An heir does not inherit the dead player's quests | Simple and clear |
| The giver remembers the help ("helped by ...") | Ready for friendlier talk and reputation later |
| Markers over quest givers (owner's scheme): a green swallow-tailed pennant for story quests; for side quests what the quest is about: a sealed scroll (a quest that teaches a skill), wheat (food), iron ore (mining), crossed swords (combat), and, extending the scheme, a log (wood) and an axe (tools). 16 px icons from the Survival pack with a 1 px dark outline; the pennant is drawn in the same style (`tools/import_game_assets.py` MARKERS) | The owner found "!" and diamonds overused |
| A quest giver inside their own home (asleep or resting) shows their marker over the house door, side by side if several of the household have one; at a workplace such as the tavern they are visible and marked as usual | The owner asked how to find a quest giver who is indoors |
| Quest markers and the attack-target sword draw over roofs and tree canopies, so a marker over a door or a villager under a tree is never hidden | Found when checking the door marker on screen: roofs covered it |
| Story quests (`"story": true`) are not offered from needs: every new player, and every heir, starts them; their giver shows the story marker until they are done. The first: "The sage in the north", learn Fireball from the sage in the hut at the north edge of the village, at his usual price (50 coins) | The owner chose the first storyline quest; the price is the existing one |
| A quest can teach a skill (`"teach": {"skill", "level"}`; owner: "the scroll should be on the quest giver that earns you a skill"). The first, "The tanner's craft" (agent proposal, provisional: balance review pending): a tanner holding under 4 hides asks for 2 hides and, instead of coins, raises the player's Crafting to level 2, which unlocks leather armour. It is offered only to a player below Crafting 2 (`player_below`), shows the scroll, and the talk window says what was learned under the tanner's words. Teaching sets the skill to the start of the level and never lowers it. It comes first among the side quests, so the dawn's 4 offers do not crowd it out | Crafting 2 is a real unlock (leather armour, `recipes.json`); hides come from hunting boar, an existing mechanic |

## Paid work for the player (owner directive: the player can "work, earn money"; details are agent proposals)

| Decision | Why |
|---|---|
| Paid work reuses the quest machinery (`"hire": true` templates in `quests.json`), with no new system: asked for, accepted, listed in the journal, handed in, failing if the employer dies | One mechanism for "bring this, get paid" |
| A working adult whose job a hire template names gets "Any work for me?" in conversation. Work is offered only when it exists and the employer holds the whole wage; otherwise they say they cannot pay or have nothing. It is never a dawn offer and shows no marker. A villager with work to offer stops to talk even when busy, as a quest giver does | Work comes from the simulation's state; a busy farmer at harvest must still be reachable |
| Jobs (agent proposal, provisional: balance review pending): a farmer whose own field is ripe with at least 24 wheat: cut 24 wheat from that field and bring it, 6 coins, 1 day; a woodcutter holding under 6 logs: bring 6 logs, 6 coins, 2 days; a miner holding under 6 iron ore: bring 6 iron ore, 8 coins, 2 days. 6 coins is the manor's day wage (`day_labour_wage`, `manor_wage_per_day`); the miner's 8 reflects ore's higher price. The tavern keeper and other trades do not hire yet | Existing mechanics (harvest, felling, mining); wages below the goods' price, so the employer gains and nothing is arbitraged |
| The wage comes from the employer's purse, in full or not at all: an employer who has since spent it says so ("unpaid") and the player keeps the goods until they can pay. Delivered goods go to the employer. No coins are created | Closed economy |
| A hired harvest hand may cut up to the asked-for wheat from the employer's field without it being theft (`Quests.hired_harvest`); beyond that it is theft as before. While the work is open, the field's farmers leave it (they tend instead of harvesting) | Otherwise the farmer would cut the field before the player could |
| Work left undone lapses at the dawn after its `days` have passed (`Quests.drop_failed`) | A day's work, not an open-ended quest; the farmer's field is not held forever |

## Controls, screen and settings (owner direction; the details are agent proposals)

| Decision | Why |
|---|---|
| The scheme in use is the one of the last input: a touch, a pad button or a stick push past half, or a key, a mouse click or a real mouse movement. Touch buttons show only for touch unless the setting says always or never; prompts name the key or pad button; with keys or a pad, panels take focus, and B closes them | The owner: detect the control scheme automatically |
| The interface is laid out 720 px high on a computer and 450 px on a phone (times 1.2 / 1 / 0.8 for the small, normal and large interface size), at 16:9, and stretched to fill any screen; the camera zoom is scaled with it, so the map looks the same | One layout for every resolution; build 1's phone text was too small to read |
| The interface stays inside the device's safe area (notches, cutouts, system bars) and, on a phone, at least 28 x 14 interface units from the screen edges, so rounded corners never cut off a window, the status box or a corner button; the map itself still fills the screen (`GameUI.fit_safe_area`, re-run when the screen size changes) | Owner report: the title window went off the screen at the corners |
| Camera dead zone (owner request): while following the player the camera stays still as long as the player is inside a box in the middle of the screen, 40% of the view wide and 35% high, and is pushed along by the box's edge when they walk past it; it never shows past the map's edges. Recenter puts the player back in the middle (`main.gd::_follow`) | The owner: the view need not always be centred on the player |
| Settings in `user://settings.cfg`, separate from the save: master, music and sound-effect volumes (Music and SFX audio buses, used once there are sounds), display mode, window size (16:9 sizes that fit the screen; first start: the second largest that fits), VSync, frame rate cap, interface size, on-screen buttons | The owner asked for the usual settings; window options only on a computer |
| Attack mode as the owner described. One strike when arriving at the target, then one per tap on it; tapping open ground walks there and clears the mark but keeps the mode; the mark is dropped when the target dies, hides indoors or gets 12 tiles away. A right-click strikes without attack mode; Space or the pad's X swings at what is in front | The owner's attack-mode rules, extended to mouse and pad |
| The interface is drawn with the owner's flat UI pack (dark scheme of set 3), recoloured on import from navy to wood brown (buttons, tabs and icon tiles 111/74/44, windows 43/29/19, parchment highlights) at the owner's word: windows in its dark tone, titles in its tab, every button on its button tile (lighter when pointed at, darker when pressed, a pale outline when it has keyboard or pad focus), the X tile to close, and its icon tiles on the touch bar (gauntlet Use, sword Attack, fire, backpack Pack, star Skills, list Menu) and in the HUD (heart, food bag, bolt, coin bag); health red from its status bars, hunger green, stamina gold | The owner: "All buttons should be a button from the UI pack"; "Do like a woody brown color" |
| Prompts and the controls list use Kenney Input Prompts (CC0): keyboard keys and mouse, Xbox-style pad buttons (the most common layout; others are in the pack), touch gestures | The owner supplied the pack for this |
| Attack mode on: the Attack tile turns red and reads "Attack ON" | Visible state for a toggle |
| The target marker is the iron sword item icon (16 px pixel art) turned to point down, bobbing above the target | Matches the pixel art; the owner's flat UI pack is not imported yet |
| Blood: 8 of the 36 Kenney splats, shrunk to 16 px with a hard edge, dark red with a darker rim, at a random quarter turn; looks only (not saved, not the world's random numbers). Only violent deaths bleed | The owner's rule, kept out of the deterministic simulation |
| Looking around (owner, 2026-10-18: "2 fingers ... drag the screen to look around", "a recenter button"): a two-finger drag pans the camera by the movement of the fingers' midpoint while their spread still zooms; the middle mouse button dragged, or the pad's right stick, pans too (arrow keys still walk). While looking around the camera stays put instead of following the player, kept over the map, and a Recenter tile (the UI pack's location pin) shows above the touch bar's right end in every scheme. Recenter, C, or a right-stick click follows the player again (the camera glides back); walking with keys or the left stick recenters by itself; a tap-to-walk does not, so the player can walk to a spot they looked at; closing the map does not | One finger stays for walking and using; looking ahead must not be undone by a walk the player chose there |
| Lifting two fingers is never a tap, and a finger that went down on a button is not a tap on the map when it lifts | Before this, ending a pinch walked the player to where the last finger left the glass |
| Village map (owner: "a map to toggle open and closed"): a Map tile (the UI pack's folded map) on the touch bar, M, or the pad's LB opens a window over the paused game; the same, the X, Esc, the pad's B, or Android's Back closes it. The village is drawn one pixel per tile from the map data, scaled to fit with nearest filtering: the kind of ground from the colour of the tile drawn there (grey rock, blue water, brown paths, green grass, dark green trees and bushes), then roads, fields by their state, pens, building plots and buildings as wood-brown roofs. It names the tavern, the Sage's hut, the smithy, the manor, the mine, the market, the fields, the pens and the plots for sale, outlines the player's home in gold, shows what the screen shows now as a pale frame, and the player as a red dot. A tap on the map closes it and looks there | One readable overview on a 450 px phone layout; built from the same data as the world, so it follows new houses and felled trees |
| Android's Back closes an open window that has an X; with none open it saves and quits as before (`quit_on_go_back` is off so the game handles Back) | The owner asked for Back to close the map |

## Talking to villagers (owner direction; the details are agent proposals)

| Decision | Why |
|---|---|
| The talk window is a conversation: the villager's portrait (their sprite's first frame, enlarged), "Name Family, a cook of the Reed family", and what they say in quotes on parchment, then choices: Trade and Learn Fireball where they were offered before, "What do you do?", "How are things at home?", "Any news?" and Goodbye. A question replaces what they say with the answer | The owner could not understand the old window's raw numbers ("Hunger 83/100 · coins 0 ...") |
| Everything said comes from the simulation: job (what `npc_brain.gd` has that job do), `doing`, hunger below the eating threshold, the household's members, food days, sustainability streak, relief days and firewood, memories of deaths, thefts and the player, and the latest village-record lines that name their family. No numbers are shown. Children and elders have their own wording | No invented facts; readable on a phone |
| A busy villager (walking somewhere, working with their hands, or fighting) does not stop: a comic-style bubble (dark ink on parchment, a tail pointing at them) shows a short line over their head for 2.5 s, then fades | The owner: villagers who walk away should still acknowledge the player, "like a comic book" |
| Strangers say "Who are you?"-style lines. Opening a conversation records the memory "met <player name>" (saved with the villager); after that they greet the player by name and their busy lines are friendlier. A villager who was attacked by the player, or saw them steal, is cold ("Stay away from me.", "I saw you take 3 wheat from Nicholas Holt's field.") | The owner: canned lines "until I get some notoriety"; for now notoriety is only whether they have met you (no reputation numbers) |
| Wording is chosen by the villager's id and the day, never by a random number generator | Same lines on every machine; the world's RNG stays untouched |
| An heir is a different person: villagers have not met them | Memories name the player who met them |

## The pack window and gear (owner direction, 2026-10-18; the details are agent proposals)

| Decision | Why |
|---|---|
| The pack window is Cozy Farm's inventory panel (owner's choice), imported by `tools/import_game_assets.py` (`_import_inventory`): the panel with flat tabs and the 9 x 3 grid, and a strip of its 8 copies with one tab raised, drawn over the panel's top for the open tab. It is drawn at a whole number of screen pixels per art pixel (5 on a 900 px high phone screen, 5 on a 1600 x 900 desktop), its corner on a whole pixel, over the darkened game; the HUD hides while it is open (the window shows the coins) | Pixel-crisp at any size; one image per piece, no hand-edited art |
| Tabs, left to right: All (Cozy Farm's own bag icon), Food (bread), Materials (log), Tools (pickaxe), Weapons (iron sword), Armour (iron armour), then Skills (a gilt book from the Assorted RPG Icons' `books.png`, column 8, row 8) and Journal (the quest marker's sealed scroll, without its outline), which open those windows. An item's tab comes from its `type` in items.json: resource is Materials; Armour also holds caps, helmets, amulets and rings | The owner's tab list; jewellery is worn gear |
| The bag grid stays at the pack's 24 kinds (`Inventory.max_stacks`); the last 3 of the 27 cells are drawn locked (darkened, a padlock) and cannot be focused. Raising the cap to 27 is left to the owner | No balance change without the owner |
| Tapping, clicking or pressing A on a cell chooses it; beside the panel (below it when the screen is too narrow) its name, kind, worth, what it does (hunger, damage, armour, bonus, wear left) and its actions: Eat; Use / Wield / Wear, or Take off when worn; Drop; Drop all. A gear slot chosen shows what is worn there with Take off. A small gold mark shows worn items in the grid. The old search box is dropped: the tabs do its job on a pack of at most 24 kinds | Every action of the old window kept |
| The portrait shows the player's idle figure (the first frame of their sprite sheet) at a whole number of screen pixels per pixel, the name on the plate below; the six slots around it: Head, Amulet, Body on the left, In hand (weapon), Tool, Ring on the right. An empty slot shows a faint outline of what goes there | The owner: "Keep all six"; placement need not mirror the body |
| New gear slots head, amulet and ring in `PlayerState` (saved; an older save loads with them empty). New items (**provisional** agent proposal, balance review pending): leather cap (head, armour 1, 14 coins), iron helmet (head, armour 2, 36), copper ring (+5 max stamina, 14), gold ring (+10 max stamina, 60), copper amulet (+5 max health, 20). Head armour adds to body armour; bonuses are data (`"bonus"` in items.json) and end when the item is taken off or dropped | Small, data-driven, nothing that changes the economy's balance |
| Who makes them (agent proposal): the player, from recipes in `recipes.json`: leather cap at the workbench (2 leather, crafting 1); iron helmet (2 iron bars, 1 leather, smithing 2), copper ring (1 copper bar), gold ring (1 gold bar, smithing 3) and copper amulet (1 copper bar, 1 leather) at the anvil. **NPCs do not make, buy or sell them yet**: the smith's and the merchants' plans name their recipes and goods explicitly, so the village economy and coin conservation are unchanged | Wiring jewellery into the merchants' trade is a larger change, left for the owner to decide |
| The pad's A presses the focused button and B closes a window: Godot 4.7's `ui_accept` / `ui_cancel` have no pad buttons by default, so `main.gd::_setup_input` adds them | B did not close windows with a pad (found while testing the pack) |

## Shops, containers and theft (owner rules, 2026-10-18; the details are agent proposals)

The owner's report: "I'm running around and cannot interact with any items. I should be able to take
food from the tables, buy things from the tavernkeeper they are a shop. Steal items to sell later."
Interactions INT-041 to INT-045 in `docs/SYSTEM_INTERACTION_MANIFEST.md`; numbers in `balance.json`.
**Provisional (owner, 2026-10-18):** the fines, success chances, resale rules and other numbers below
that the owner has not approved stay provisional until a separate gameplay-balance review.

| Decision | Who | Why |
|---|---|---|
| Tavern keepers and merchants are shops: using the counter, the stall, or the keeper at it opens their trade window ("Buy from Sybil (tavern)"), and a shopkeeper at their post always serves | Owner | "buy things from the tavernkeeper they are a shop" |
| Food on the tavern's tables is the tavern's stock; taking it unpaid is theft, witnessed and punished like a field's wheat | Owner | Owner's answer |
| The player may steal from market stalls, from crates and barrels (the tavern's and the houses': their owners' stock) and from villagers' pockets, with a skill-based chance of being noticed | Owner | Owner's answer |
| Stolen goods are marked: the owner knows them if they are offered back, and a guard may question the seller | Owner | Owner's answer |
| Ownership model: a house's crates and barrel ARE its household's pantry; tavern crates are the first alive tavern keeper's stock; a stall's crate (and the stall when its merchant is away) is the merchant's stock. Only a tavern table holds goods of its own: one dish or mug a keeper sets out from their stock each hour the tavern is open (07:00-22:00, in turn between the keepers, keeping at least `table_keep` = 4 of a kind), cleared back to them at closing, saved. Older saves get their tables set from the keepers' stock | **Provisional** (agent proposal; balance review pending) | The simplest model that keeps the closed economy: nothing is created, every good stays one owner's, and only the tables need saving |
| Containers come from the crates, barrels, dishes and mugs Shade drew (village.json "containers", read from the placed tiles, no other map change); an emptied table's dish tile is hidden until it is set again | **Provisional** (agent proposal; balance review pending) | The art already shows them; a dish drawn on an empty table would mislead |
| One use takes one piece of what the container holds most of; the prompt names it and says it is theft | **Provisional** (agent proposal; balance review pending) | Each take is a separate risk; the prompt says what will happen |
| A guard who sees a theft (field wheat included), hears a caught pickpocket's victim within 15 tiles, or is called by an owner offered their own goods stops the player: the goods go back where they came from and the player pays a 10-coin fine to the treasury; a player who cannot pay it all pays what they have and the guard attacks (as `_crime`) | **Provisional** (agent proposal; balance review pending) | Proportionate: "guards react"; a death sentence for a bowl of pottage would be too harsh, but an unpaid fine needs teeth |
| Pickpocketing is a "Pick pocket — theft" choice in the conversation (shown within 1.8 tiles: everyone who stops to talk), so it is the same on touch, gamepad and keyboard. Busy villagers who only call out a line cannot be robbed | **Provisional** (agent proposal; balance review pending) | Discoverable on every control scheme without a new button |
| A new skill, Stealth: success 40% at level 1, +12% a level, at most 85%; 1-5 coins, or one carried thing that is not a work tool when they have no coins. Stealth experience: 8 for a picked pocket, 2 for a caught try, 3 for an unseen theft | **Provisional** (agent proposal; balance review pending) | The owner asked for a skill-based chance; no existing skill fitted |
| Stolen goods sell to anyone but their owner at the usual price (the buyer cannot tell); marked pieces are sold first; a guard within sight questions the seller half the time (`guard_question_chance`). The owner's whole household knows their goods | **Provisional** (agent proposal; balance review pending) | Small and readable; a lower "fence" price would need a fence, which the village does not have |
| Marks follow the goods: stored in the home chest they keep their marks there (and an heir inherits them with the chest); eaten, dropped, sold or used up, they lose them | **Provisional** (agent proposal; balance review pending) | The chest must not wash stolen goods clean (the owner: stolen goods are marked) |
| NPCs still never steal (no desperation crime) | Owner | Not authorised |

## Building interiors and roof fade (owner decisions, 2026-10-18; the details are agent proposals)

Interactions INT-048 to INT-050 in `docs/SYSTEM_INTERACTION_MANIFEST.md`.

| Decision | Who | Why |
|---|---|---|
| Interiors use a roof fade, not separate interior scenes: "I want the world to remain continuous, with NPCs and the player using the same building-entry mechanics." | Owner | Owner message |
| One interior system for every enterable building, functional interiors first, nothing that only works for some buildings | Owner | Owner message |
| The interiors are Shade's own: his small house and manor have rooms and furniture drawn under their roofs (Puny World sample-village-1), and his tavern and smithy samples (-3, -2) have roofs he drew but left hidden in Tiled, which the generator now shows. No octoshrimpy indoor tiles (another style) are used | Agent proposal | Same art style, nothing invented; the octoshrimpy pack was not needed |
| The roof fades to nothing (0.25 s) while the player is under it: inside, or behind its eaves (so the player is never hidden by a roof); only that building's roof | Agent proposal | The inside should read clearly; the eaves rule keeps the player visible behind the tavern and smithy |
| Small houses get five beds (Shade's beds, four along the west wall where his straw mat, shelf and jars stood, one by the east wall); every home has six sleeping places, beds first, then straw pallets on free floor (the manor and the tavern have two beds and four pallets; the sage's hut one pallet, where Shade drew a box in its one inner cell) | Agent proposal | Households have up to five people; the manor's and tavern's extra people (guards, cooks) sleep on pallets |
| A villager's bed is theirs by household order; asleep they lie in it under its blanket (the standing sprite turned on its side), and are drawn only to someone inside the same building | Agent proposal | People stay in the world instead of vanishing |
| "Hidden" is gone. Inside a building means standing in its area. Witnesses, guards and talk targets are those awake in the same place (the same building, or outdoors); asleep villagers neither trade, serve, witness nor can be talked to, robbed or attacked, as when they vanished indoors; bandits stalk only people outdoors; a fight ends when its target goes into a building the fighter is not in | Agent proposal | Keeps every old behaviour of "hidden" with the new meaning; walls block sight |
| Villagers eat at their household's table and take feed from its chest; strolling villagers stay outdoors (no wandering into others' houses) | Agent proposal | The household's spots, used as the owner asked |
| In the player's house the bed rests until morning and the chest opens the family's store; the door still offers both | Agent proposal | Home actions from inside, the old way kept |
| Saves become version 4 (no "hidden"); older saves' villagers who were hidden at home load inside at their own bed | Agent proposal | Save compatibility (CLAUDE.md section 7) |

## Known gaps

- No marriage, births, aging, adoption or immigration exist yet; households only shrink. Proposals
  are waiting for the owner.
- Children eat by role, not age: villagers have no ages yet, so every child eats `child_food_factor`
  of an adult's food and elders eat as adults.
- Skilled trades cannot be learned (no apprenticeship); villagers move only between general,
  farming and resource work.
- The player cannot own livestock or hire helpers to deliver building materials. (Harvesting a
  field works: `World.player_harvest`, INT-007.)
- No eggs, milk or wool (the owner asked only for meat).
- No aging, no births of people, no audio yet (the volume settings are ready for it).
- Villagers keep only their last 8 memories (having met someone is never forgotten), so older
  grudges and sightings fade.
