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
| Permadeath: the heir keeps the family's home, chest and everything the family owns or leases (see "Property and land"), starts every skill from nothing and carries only the starting kit (20 coins, provisional (owner, 2026-10-18; was 5), rusty sword and pickaxe, bread, rotten apple, plain clothes); what the dead carried lies where they fell, for anyone to take, the heir too. The heir's kit and coins are new to the village (counted in `coin_sources`). Anyone fighting the dead player stops | Owner rule, 2026-10-18 (house, chest and the dropped bag settled by the owner's answers) |
| The journal (Menu, or B): the village record written into an open book, two parchment pages at a time, six lines a page, a heading for each day (repeated as "continued" at the top of a page that starts mid-day), opening at the latest pages | The owner asked for a journal that looks like a book |
| Building (see also "Property and construction, phase 2"): buy or lease ground from the manor anywhere legal (the price or rent goes to the treasury), a wooden frame appears, deliver 30 planks, 20 stone and 10 logs, and the house stands. A progress bar over the frame and in the build window shows the share of loads delivered. Giving up the site returns every delivered load to the pack (what does not fit is left in a bundle at the site), takes the frame down and keeps the plot | The owner's rules (frame with a progress bar, materials only, no extra build time, cancel returns everything) |
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
| ~~The wage comes from the employer's purse, in full or not at all~~ Superseded (owner, 2026-10-18, B7-002): a reward or wage is offered only by someone who can pay it and is set aside when the player accepts (`reserved`), paid exactly on completion, and returned on a lapse, the giver's death or the player's death. Delivered goods go to the employer. No coins are created | Closed economy; a promise the giver cannot keep was paid short |
| A hired harvest hand may cut up to the asked-for wheat from the employer's field without it being theft (`Quests.hired_harvest`); beyond that it is theft as before. While the work is open, the field's farmers leave it (they tend instead of harvesting) | Otherwise the farmer would cut the field before the player could |
| Work left undone lapses at the dawn after its `days` have passed (`Quests.drop_failed`) | A day's work, not an open-ended quest; the farmer's field is not held forever |
| Wheat cut for harvest work is the farmer's (owner, 2026-10-18, B7-004): if the work lapses, what the player carries of it, then what is in the home chest, is marked stolen from the farmer, the farmer knows, and it is a theft on the record (`Quests.settle_harvest`) | Abandoning the job must not leave the player the employer's wheat |
| ~~Work for the manor: one quarrying task for the player~~ Superseded (owner, 2026-10-18): the manor's job board below | The owner chose a choice of real jobs and the same rules for villagers |
| **The manor's job board** (owner, 2026-10-18: a choice of real jobs from real needs, no artificial demand, no guaranteed work, NPC day labourers by the same rules; design and numbers agent proposals, provisional — balance review pending). What the manor already decides each evening is made physical: repair and public-works materials it buys wait at the seller's as its lot and are carried to the works yard (haul, 2 coins a load of up to 10); the yard's materials are used mending the well and the roads (mend: 4 loads, 3 hours, 4 coins); grain bought for the granary waits at the farmer's to be carried there; relief is carried to the household (a household under a day of food gets it at once, also from grain still at the farmers'); stone for the works is quarried from the village's seams (10 stone, 6 coins) instead of bought while one quarry job is open. The manor buys no more works materials while it holds 40 unused. Wages are set aside from the treasury when a job is taken, only above its 10-day reserve, and paid when done; manor hands take jobs unpaid (already waged); one job at a time; undone jobs return at the next dawn | The repair, works, granary and relief purchases already existed (owner-approved B3 plan); only the carrying and using are new, so demand is not invented. Their money-driven trigger is unchanged; a need-based maintenance model is a separate proposal |
| Villagers whose own trade is idle (waiting for buyers or orders) ask the reeve for this work before 15:00 (agent decision under the owner's equal-rules directive) | Without it nobody but rare relief households took the work: 0 jobs in 15 simulated days; with it, 26 (13 hauls, 13 mends) |
| Starting coins 20 (owner, 2026-10-18; was 5; provisional — balance review pending), for new characters and heirs; saved games keep their coins | B7-001: 5 coins bought about two meals |
| A new game's first message says where paid work is; the journal's Quests page keeps a note on who buys what; the shop window is "Trade with …" (owner, 2026-10-18, B7-005) | Guidance without a tutorial |
| The goods merchant buys copper and gold rings (3, 2), the amulet (2), the leather cap (3) and the iron helmet (2) (stock caps; agent proposal, provisional) (owner, 2026-10-18, B7-003) | Craftable goods had no buyer; the caravan carries the merchant's surplus away like other made goods |
| Stone by caravan (owner, 2026-10-18, B7-007): once the village's stone deposits are down to `caravan_import_when_left`, each caravan brings at most 20 stone (`caravan_stone.load`) from a quarry on its road, sold to the raw-goods merchants at value × 2.0 (`caravan_stone.markup`, cartage) up to their cap, keeping the trader cash floor; it then buys none of the village's stone. The quarry is a GAME EXPANSION (no source in Morris). Numbers provisional — balance review pending | A finite, priced outside source, not free stone; smiths (who take the ore imports) do not sell stone, so the stone sellers buy it |

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
| Work animations (Build 8, B8-006/007/010/011): a piece of work (mining, felling, picking, harvesting, planting, mending, crafting) is one timed action. Use starts it, it plays one animation, then the result is awarded, the notice shown and the player returns to idle; further cycles need another Use (Gather mode's "until it runs out" is the explicit exception). The action ends the same way whenever it is cancelled: B (pad), Esc, a right-click, a tap, walking away in Gather mode, or any window opening (the Pack, Skills, Journal, the menu). Cancelled work awards nothing, wears nothing and is not resumed when the window closes | Agent proposal (owner's Build 8 test report) | The animation used to stay on "work" for ever once an action had ended, and the Pack could not be opened while working |
| **MISSING ART: no pickaxe, axe or hammer swing exists in the character sheets.** The Puny Characters sheet (29 columns x 8 directions) has walk, sword (5-8, the sword drawn in), bow, staff (13-15, the red-orb staff drawn in: this was the "work" animation, so a pickaxe looked like a sword or staff), throw (16-18, empty hands), hurt, death and carry. What was done: tool work plays the throw frames bare-handed (the "swing" animation, columns 16-18) with the tool's own item icon (pickaxe, rusty pickaxe, axe, smith's hammer) drawn in the hand over them, raised, struck and following through, at 0.85 scale, mirrored for the side faced and behind the body when facing away (`ActorSprite.hold`); picking, harvesting and planting play the arms-forward carry frames ("gather"). The villagers' own work (`NPC.anim == "work"`, set by the NPC brain) is unchanged and still shows the staff frames: they need the same treatment and a tool per job. Proper pickaxe and axe swing sheets would replace the overlay | Agent decision, art missing | The owner's rule: when the art does not settle something, record it and use the closest existing animation |
| Sprint (B8-027): LT toggles it on a pad (owner, 2026-10-19: LT, not L3; LT still steps through buttons inside a window); on a keyboard Shift held sprints (balance `sprint_toggle` true makes Shift a toggle). `sprint_speed` 1.5 times the walking speed, `sprint_stamina_per_sec` 12 net of regeneration, and not startable under `sprint_min_stamina` 12 **(all provisional)**. It ends at once when stamina runs out (with Shift held it stays off until Shift is let go), when the player stops, or when an action or an attack begins, and never starts during either. The walking animation runs 1.5 times as fast | Agent proposal (owner's Build 8 test report) | A held Shift is the usual keyboard sprint; a pad has no held button free, so a trigger press toggles |
| Several things to use at once (B8-014): a person, container, counter, loot or animal near the front, the seam, tree, plant or field in front, and the station, pen, door, bed or manor step underfoot are all offered (`main.target_options`, nearest first); Use (E, A, a tap) does the chosen one, and the prompt shows a second line "Q / Tab: next - <the next choice> (1 of 3)". Q or Tab (D-pad left and right on a pad) cycle; Tab cycles only when there is a choice, and otherwise stays the Pack's key. LB and RB stay Map and Skills and B stays Cancel. On touch, tapping the thing chooses it | Agent proposal (owner's Build 8 test report) | A villager standing by a forge hid the forge: only the nearest target was offered |
| Collection notices (B8-009) go through `GameUI.gain(text, item_id)` (the corner line, with the item's icon once the UI shows it): "+1 Iron ore", "+3 Logs", "+2 Wheat", picked flowers and berries, and what is taken from a hunted animal's remains or a body | Agent proposal | One notice for every gain |

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
| The interiors are Shade's own: his small house and manor have rooms and furniture drawn under their roofs (Puny World sample-village-1), and his tavern and smithy samples (-3, -2) have roofs he drew but left hidden in Tiled, which the generator now shows. No octoshrimpy indoor tiles (another style) are used | Owner (2026-10-18: keep the tavern and smithy roofs, the smithy's stone roof for now; one roof and interior system for every enterable building) | Same art style, nothing invented; the octoshrimpy pack was not needed |
| The roof over the building the player is inside fades to nothing (0.25 s) at once; it comes back 0.3 s after they leave (no flicker at a doorway). Behind the eaves a roof fades only when it would hide the player (it covers the cell at their feet and the one above), only after 0.4 s there (not in passing), and only to half (EAVES_ALPHA 0.5, provisional) so the player shows through. Only that building's roof (`roof_fade.gd::follow`) | Owner (2026-10-18: fully transparent inside; fade only when needed so the roof does not hide the player, not simply behind the eaves; no distracting flicker); the timings and 0.5 are provisional | The inside shows; the player is never lost under a roof; passing by a roof changes nothing |
| Small houses get five beds (Shade's beds, four along the west wall where his straw mat, shelf and jars stood, one by the east wall); every home has six sleeping places, beds first, then straw pallets on free floor (the manor and the tavern have two beds and four pallets; the sage's hut one pallet, where Shade drew a box in its one inner cell) | Agent proposal | Households have up to five people; the manor's and tavern's extra people (guards, cooks) sleep on pallets |
| Families sleep in beds: a household's members take its beds first, in member order, and its guards and cooks lodge on the straw pallets (`World._sleep_order`, `LODGERS`). The manor gets two more beds (generator: `EXTRA_BEDS`, placed only where every reachable floor cell stays reachable), so the reeve's family has beds. Two exceptions remain: the tavern has no room for more beds outside its dining hall, so its child sleeps on a pallet in the inn's back room, and the sage's hut has a single floor cell, so the sage has a pallet | Owner (2026-10-18: villagers with homes normally sleep in their own beds; pallets for guards and cooks); the placement is the agent's | Beds in the dining hall looked wrong (checked on a render) |
| A villager's bed is theirs by household order; asleep they lie in it under its blanket (the standing sprite turned on its side), and are drawn only to someone inside the same building | Agent proposal | People stay in the world instead of vanishing |
| "Hidden" is gone. Inside a building means standing in its area. Witnesses, guards and talk targets are those awake in the same place (the same building, or outdoors); asleep villagers neither trade, serve, witness nor can be talked to, robbed or attacked, as when they vanished indoors; bandits stalk only people outdoors; a fight ends when its target goes into a building the fighter is not in | Agent proposal | Keeps every old behaviour of "hidden" with the new meaning; walls block sight |
| Sleeping limits awareness, not interaction: a sleeper sees nothing (not a witness, not a guard on watch) but can be reached (`World.present`), woken ("Wake <name>", then the conversation), robbed in their sleep ("Pick pocket while asleep", the chance raised by `pickpocket_asleep_bonus` 0.3 up to `pickpocket_asleep_max` 0.95; a fumble wakes them and they remember it) or attacked: a blow wakes them and the noise wakes sleepers within `sleep_wake_radius` (6 tiles) in the same place, who then witness through the usual crime system. Villagers' fights go on against a sleeper, who wakes when struck | Owner (2026-10-18: sleepers are not immune; sleep affects awareness and reaction; use the existing crime and witness systems); the numbers are **provisional** (balance review pending) | Sleep was a way to make villagers untouchable |
| Villagers eat at their household's table and take feed from its chest; strolling villagers stay outdoors (no wandering into others' houses) | Agent proposal | The household's spots, used as the owner asked |
| In the player's house the bed rests until morning and the chest opens the family's store; the door still offers both | Agent proposal | Home actions from inside, the old way kept |
| Saves become version 4 (no "hidden"); older saves' villagers who were hidden at home load inside at their own bed | Agent proposal | Save compatibility (CLAUDE.md section 7) |

## Property and land, phase 1 (owner decisions, 2026-10-18; the details are agent proposals)

The owner's answers to `docs/HOUSING_LAND_AUDIT.md` (`docs/DECISIONS.md`, "Property and
construction"). Code: the owner API in `game/scripts/core/world.gd` ("ownership"), the land office in
`game/scripts/core/property.gd`; interactions INT-051 to INT-056 (and INT-007, 017, 018, 021, 026,
027, 029, 030, 031, 042 updated). Phase 2 (placement interface, hired helpers, households splitting
and building, workshops) builds on it and is not done.
**Provisional (owner, 2026-10-18):** every price, rent, sale value and the eviction rule below are
agent proposals until the balance review.

| Decision | Who | Why |
|---|---|---|
| The manor, households and the player own land and buildings; the player counts as their own household; unsold land and empty houses are the manor's | Owner | Owner answer |
| Rent is weekly; only the manor lets land and buildings | Owner | Owner answer |
| A house whose family dies out goes back to the manor, which can sell or let it again; the player may sell their house and own several | Owner | Owner answer |
| Building is free placement anywhere legal, the ground bought or leased from the manor on the spot. Phase 1 gives the land model for it: `Property.can_claim(rect)` (at least 3x3, inside the village with a one-tile margin, no building, surveyed parcel, field, pen, stall, station, container, mine seam, tree or road, walkable ground) and `Property.claim(rect, owner, lease)`, which surveys a new manor parcel and sells or lets it at once. The placement interface is phase 2's | Owner (rule); legality details Agent | The road stays clear so nobody is walled off; a tree must be felled first, as a builder would |
| One owner reference everywhere, a String: `"manor"`, `"player"`, `"hh:<id>"`, `"npc:<id>"`. Every building, parcel, stall, pen, field and station has `owner` and `tenant` ("" for none), asked and changed only through `World.owner_of / tenant_of / holder_of / holds / set_owner / set_tenant` (resolved to a person with `World.party`). It replaces the six older ways (plot `""`/`"player"`, field id lists, stall and pen ids, container ownership derived from `home`, the player's `plots` list) | Agent proposal (audit recommendation) | The owner asked for no conflicting ownership mechanics. Strings save as they are, read in logs, and name the manor and households, which ids could not |
| `"npc:<id>"` is only ever a tenant (a stall's merchant, a pen's keeper), never an owner of land or buildings | Agent proposal | The owner listed the manor, households and the player as owners |
| Starting owners: a house and the sage's hut are their household's; the manor house and the tavern are the manor's, let rent-free to the reeve's household and to the tavern keepers' household (they live there as its officers; the tavern's stations stay the manor's); the smithy, fields, pens, market stalls and all stations the manor's; each stall let rent-free to its merchant, each pen to its keeper; the two plots the manor's, for sale or lease | Agent proposal | The obvious owner of a home is the family in it. The tavern as the manor's alehouse keeps its oven and stove public for the player, as before; owning it outright would change who may cook there |
| A field is the manor's; its farmers are those whose workplace it is (`World.field_workers`), so the list can never hold a farmer who left (audit defect 1). Taking its wheat is theft from the first of them | Agent proposal | Derived data cannot go stale |
| A building on a parcel and the parcel change hands together (`building.parcel`, `parcel.building`); a house built on leased ground is the builder's, but passes to the manor with the ground if the lease ends | **Provisional** (agent proposal) | One deal per place; the alternative (the manor pays for the house) is for the balance review |
| Prices: land `plot_price` 60 for a 9x10 plot (now used; the generator's price is ignored, audit defect 4), other ground by area (ceil(60 x tiles / 90)); a house with its ground `house_price` 150 (about its materials, 100 coins at village prices, plus the plot) | **Provisional** (agent proposal; balance review pending) | The plot price already in balance.json; a house worth its materials and land |
| Rent: `weekly_rent_share` 0.1 of the price a week (plot 6, house 15), the first week paid when the lease is signed | **Provisional** (agent proposal; balance review pending) | Ten weeks' rent buys it, so leasing suits a short stay |
| Selling back: the manor pays `sell_back_share` 0.6 of the price (a house 90, a plot 36) from the treasury, refused when the treasury cannot pay, when it is let, or while a site on it is unfinished | **Provisional** (agent proposal; balance review pending) | Below the price, so buying and selling makes no money; the treasury must hold the coins |
| Rent day: each morning every lease due is collected from the tenant's purse (a household's members, richest first) to the treasury. Unable to pay all, the tenant pays nothing that week and it joins the arrears; arrears are paid with the next rent; after `rent_evict_missed` 2 unpaid weeks the manor takes the lease back (with any building the tenant put on the ground) and lets the arrears go. Giving a lease up pays what arrears the purse can | **Provisional** (agent proposal; balance review pending) | One week's grace, no debt that outlives the lease, no coin made or lost |
| A household that dies out: everything it owned becomes the manor's, its leases end, and its pantry's stores go to the manor's granary (escheat). The village's food days count all food in the granary | **Provisional** (agent proposal) | Inheritance passes goods within a household only; with nobody left, the lord takes them (medieval escheat) and the house can be sold empty. Relief can then give out its grain |
| The player's home is one house they hold (`PlayerState.home`; "Make it home" at the land office or the house's door): its door and bed rest, its chest is the family chest. A family's first house becomes its home; giving up the home moves the family to another held house (lowest id), or leaves them homeless: they respawn at the village spawn and the family chest is kept, reached again from their next house | Agent proposal (owner question: what selling the home does) | Nothing the player owns is lost; homelessness is a real consequence without destroying goods |
| The heir inherits everything held as `"player"`: houses, land, leases (and their rent and arrears), the home and the chest | Owner (heir keeps the family's house and chest); extension to all property Agent | The family, not the character, owns |
| The land office: "Land and houses" in the reeve's conversation lists what the family holds (Make it home, Sell, End lease) and what the manor offers (Buy, Lease). An empty house's door offers the same deal; a plot's build window offers buy or lease. The reeve mentions an empty house when there is one | Agent proposal | The existing plot purchase was at the plot; the reeve keeps the manor's business |
| A vacant stall is let again (audit defect 2): when its merchant dies or leaves, the stall is vacant; each morning the manor lets it, rent-free, to the first villager (by id) out of work or a manor hand who holds `stall_min_coins` 20 to stock it | **Provisional** (agent proposal; balance review pending) | Merchants were outside the job market; the manor letting the stall keeps "only the manor lets" |
| ~~The player still ignores villagers' station reservations (audit defect 3)~~ Superseded in phase 2: the player respects a villager's live reservation at a station they do not hold | Agent proposal | See phase 2 |
| Saves become version 5; versions 1-4 migrate (`World._migrate_property`, `Fauna.load_dict`) with the plots, a house the player built and the player exactly where they were, and a household that had already died out settled as above | Agent proposal | CLAUDE.md section 7 |

## Property and construction, phase 2 (owner decisions, 2026-10-18; the details are agent proposals)

The owner's binding answers: building is free placement anywhere legal, the ground bought or leased
from the manor on the spot; a frame site with a progress bar, materials only, no extra build time,
cancelling returns everything; NPCs build by the same rules; house first, then workshops; the home is
the respawn point and storage; helpers are hired for coin and carry the owner's goods, the owner
keeps the building; crowded households split (a grown member founds a household, gets land or an
empty house, builds by the player's rules or moves in); workshops are buildings with stations, used by
their owner or tenant, others only with permission; no conflicting ownership or construction
mechanics (the phase 1 owner model and property API only). Code: `game/scripts/core/construction.gd`
(kinds, placement, helpers, households), `World.start_site` / `deliver` / `_finish_site`, the
placement controller in `game/scripts/main.gd`, `game/scripts/view/placement_ghost.gd`, the build,
deal, workshop and hire windows in `game/scripts/ui/game_ui.gd`; interactions INT-057 to INT-061.
**Provisional (owner, 2026-10-18):** every cost, price, wage and threshold below is an agent proposal,
provisional: balance review pending.

| Decision | Who | Why |
|---|---|---|
| Placement: Menu > Build (or H) lists a house and the workshops (greyed with the reason until the family owns a house); choosing one shows its footprint on the map, green where it may go with the ground's price and rent, red with the reason where it may not. Touch: tap where it should stand, then Place; mouse: it follows the pointer, a click on it places it; keys, d-pad or stick move it a tile at a time, E / A place, Esc / B cancel. The game waits meanwhile. Placing opens the deal: buy the ground (and mark out) or lease it (and mark out), one step | Owner (rule); interface Agent | The owner's "anywhere legal, bought or leased on the spot"; one flow on every control scheme |
| Legal ground is the land office's check (phase 1) plus the house-first rule, the building's own footprint (its stamp's size, 9 by 10) and a door step that is clear and reachable from the village. A grown tree must be felled first; a felled tree's stump or sapling no longer blocks, and is grubbed up for good when the ground is claimed | Agent proposal | Before, a stump blocked like a tree, so ground could never be cleared; in the whole village only two 9 by 10 spots and the two clearings were free |
| Generic construction: `start_site(parcel, kind, owner)` for a house or a workshop; `deliver(parcel, inventory, by)` from anyone's inventory; the building is the site owner's. Houses keep their id `house_<parcel>` and type; workshops are `workshop_<parcel>`, type "workshop", with a kind and a stamp | Owner (rule); names Agent | Saves and tests keep working; one construction for every builder |
| Workshop kinds and costs **(provisional)**: smithy (forge, anvil) 20 planks, 30 stone, 10 logs, 4 iron bars; carpenter's shop (workbench, sawhorse) 30 planks, 15 stone, 15 logs; bakehouse (oven, stove) 20 planks, 30 stone, 10 logs (`workshop_cost`). A workshop with its ground is valued `workshop_price` 140 (a house 150) | Agent proposal | About a house's materials; the smithy's iron fittings come from the smiths |
| Workshop art: Shade's small house (the house stamp) with its beds taken out and the stations of his smithy and tavern kitchen copied in tile for tile (generator `WORKSHOPS`); same interior, roof fade and collision system as houses. From outside a workshop looks like a house (no sign art); its name shows at the door | Agent (the brief allowed reusing the house stamp) | No new art invented; Shade's own station tiles |
| A workshop is used by its owner or tenant and their household; others only with leave: its holder's "Let anyone work here" at its door (the `allow` list, "all"). Villagers' stations come first for villagers; they use a player's workshop only with leave. Villagers do not build workshops yet | Owner (rule); leave model Agent | The owner's permission rule; the village's economy was tuned without NPC workshops |
| Station reservations (audit defect 3): at a station the player does not hold, a villager's reservation is respected while that villager is at it or on the way; the craft window says who works there and Make is off. The player's work holds the station for its time, so villagers wait or use another. In their own workshop the player never waits | Agent proposal | Fair both ways; a stale reservation (the villager went to eat) lapses at once, so the player is not kept waiting for nobody |
| Hired helpers: "Hire to carry building materials" in conversation with an adult out of work, a manor hand or a labourer, while the family has a building site. Wage **(provisional)** `helper_wage` 6 coins for the day (the manor's day wage), paid from the employer's purse when hired. The player chooses: carry from the family chest only, or also buy what is missing at the market with the player's coins, up to what the rest costs now. The helper really walks: one material at a time from the chest at the home's door, or from the nearest seller, to the site, and delivers through `deliver`. What they carry is the employer's; at the day's end (or if the building stands, or they die) it goes back to the chest. Hired after working hours, they start the next morning. A manor hand hired out is not also paid by the manor that day | Owner (rule); details Agent | The pack is not used: the owner's brief prefers the chest, the home's storage. Reusing the "villagers hire the player" quests did not fit (that is goods for a wage, given to the employer; this is carrying the employer's own goods), so hiring is its own small contract |
| Crowded **(definition provisional)**: more living members than the house has beds (real beds; straw pallets are for lodgers and guests), in a house the household holds, with two grown members or more. No household is crowded at the start (no births yet); one grows crowded only when people move in | Agent proposal (owner asked to define it by beds) | Interiors give beds; pallets would make every home hold six |
| Splitting **(thresholds provisional)**: each morning at most one crowded household splits, when after paying for the new home it keeps `split_keep_base` 40 + `split_keep_per_member` 20 coins a member staying. The founder is the last grown member by id (not the reeve or the sage); the family gives them what the new home costs (coins move within the family). The new household has the same family name and a new index at the end of the list (`founded_from`); members' `home` changes only when they move in, so containers keep following the house's holder | Agent proposal | The audit's warning: households are indexed by position and containers derive their owner from `home` |
| The new household's home, through the property API only: an empty house on the market (bought; or leased with two weeks' rent in hand), moving in at once; else a surveyed clearing for sale, else new legal ground as near home as can be found (`Construction.find_ground`), bought, and a house marked out. Cost budgeted: the ground, the materials at today's prices, and `founder_build_days` 3 days of helper wages. Each morning it hires a helper out of work (by id) when it can afford the materials and the wage, else the founder carries for no wage. Until the house stands the founder lodges with the family, on the next free sleeping place; then every member moves in. A household that loses its house lodges with the family it came from and looks again | Owner (rule); details Agent | Same rules as the player; no coin or good made |
| Public works and repairs leave on sale what open building sites still need | Agent proposal | The audit: public works bought every plank above 6, which would starve builders |
| Places are named for the player, never by internal id: a building for the family who live in or hold it ("the Reed family's house", "the Ashdown family's smithy"), the family that died out ("the Ford family's old house"), or where it stands; ground by the nearest landmark ("the clearing north of the Reed family's house", "the ground west of the tavern"); a duplicate name gets where it lies | Agent proposal (owner asked for readable names) | The owner's examples |
| Saves become version 6 (site kinds, workshops, helpers' contracts and loads, founded households); version 5 loads with every site a house's and built houses on the house stamp; 1-4 migrate through it | Agent proposal | CLAUDE.md section 7 |

Simulations (`game/tests/households_sim.gd`, 30 days, three households crowded at the start, seeds
1-4): 100 of 100 villagers alive on every seed; coins and grain conserved on every seed; 2, 2, 2 and
1 households founded, every one of them in a house it built (the third crowded household on each
seed could not afford to split). `run_tests.gd --days 30` (seed 1, nobody crowded): all checks pass.

## The Build 8 village (owner decision 2026-10-19: one fixed village; the details are agent proposals)

Generator v6 (`tools/build_village.py`) lays the village out as one settlement; the same in every game. Shade's sample maps are used only as building stamps (walls, floors under the roof, furniture, roofs), never as the finished layout.

- **Weapon racks and armour stands (B8-015).** Nothing in the code can take anything from a rack (the armory has a counter station, no take interaction), so they are decoration: every cell of a rack, its top half included, is solid, and the top half is drawn in a below layer (below3), so the player never stands under half a rack. Data only; nothing to take, nothing to steal.
- **Tabletop items (B8-025, data part).** The tops of tables, benches and racks that Shade drew in his "Object Top" layers go to below3 / below4 over their base; a top over a doorway or open passage (a lintel) stays over the characters. The y-sorting itself is the view's.
- **Sawmill (B8-028).** A small building named "Sawmill" on Mill Road north of the crossing holds the village's only sawhorse (station s7, recipe `saw_planks` unchanged), the carpenters' workplace. The smithy keeps forge, anvil, workbench and the armory counter. Planks and logs are piled in its yard.
- **Mine (B8-004).** A rocky hill (the free tileset's cliff terrain, solid) with a timbered adit in its south face; one track runs from the adit's mouth to a cart stop in the yard, the cart standing on it; the 14 seams (5 iron, 4 coal, 3 stone, 2 copper, 60/50/80/30) lie on the yard, each with open neighbours (tested reachable).
- **Chests (B8-017).** A house's crates and barrels stand inside its own door yard; the tavern's in and by the tavern; a stall's beside it. A test checks each is by its owner and by no other building.
- **Saves.** Version 13; `SaveStore.MIN_VERSION` refuses older saves ("older"), keeping them unchanged as `<save>.older-<time>.json`.

## Calendar, ages, families and life cycles (B8-029; owner-approved 2026-10-19, the numbers are agent proposals)

All in `game/data/balance.json` ("calendar", "life", and each animal's `juvenile_days`, `elder_days`, `death_days`,
`baby_frame`; `animal_breed_slow_from`, `animal_elder_speed`). Provisional:

- Calendar: 8-day year, seasons Spring, Summer, Autumn, Winter of two days. The HUD clock reads
  "Spring, Year 1  Day 3  07:00" (Day: of the year; 28 characters). Trees are not drawn by season.
- Stages: child to 12, adolescent 12-16, adult 16-55, elder 55+. `role` is child (to 16; drawn 0.5 then 0.75),
  adult or elder (walks 0.8x). Adolescents have no full job and are not apprentices (succession takes adults
  only, which now includes anyone who has just turned 16). Adults who turn 55 retire (post opens like a death's).
  The sage and the reeve serve for life. Bandits age and keep their role.
- Starting people: adults 17-50, elders 56-75, children 1-15 (parents 16+ years older), deterministic from the seed
  (own RNG). Sex comes from the name list (`Life.FEMALE`). A household's first adult man and woman are recorded as
  partners, its first elder pair likewise; its children get them as parents (or the one adult of the household).
- Natural death: daily chance `0.1 * ((age - 60) / 20) ^ 2`, certain at 80 (median about 70).
- Partnering: unpartnered adults 18-50, opposite sex, not kin, age gap at most 12, 50% a year for each woman;
  one moves into the other's home if it has a free bed (the tavern, manor and hut households are not moved
  into; the reeve, sage and guards do not move). Without room, nobody pairs.
- Births: partners only, woman 18-42, a free bed (`beds_in` greater than living members), at least one day of
  household food, no child in the last year; a day's chance of 1 in 16 (about one birth in two years).
- Inheritance order: the eldest adult child, then the partner, then other kin (parents, then siblings, eldest
  first), then a minor child; only when the family has no heir does the household order apply (adult, elder, child).
- Player: starts 18-20; dies of old age by the same chance (cause "old age"). Heir: the eldest living child
  of 16+ (made through an explicit partner; ask a villager "Ask to be partners"), who leaves the villagers; none:
  a relative, 18 years old, as before. Links to the dead player become `FORMER_PLAYER` (-3).
- Animals: existing `grow_days` and `breed_days` kept. Added juvenile_days, elder_days, death_days (game days):
  rabbit 0.5/24/[28,40], chicken 0.5/32/[40,56], pig 1/56/[64,96], boar 1/56/[64,80], sheep 1/64/[80,104],
  cow 2/96/[120,160]. Breeding chance is 1 up to half the cap, falling to 0 at the cap; the elderly do not breed and
  move at 0.7x. The elderly die by a daily chance spread evenly over `death_days`. Start: adults, one juvenile
  per group, one elderly in groups of four or more.
- Art: Cozy Farm baby sheets (cow, brown cow, pig, sheep, chicken, rabbit, grey rabbit; the brown chicken
  reuses the chick), full scale; the boar has none and is half scale.
- Not done: sprite art by season, marriage ceremonies, adolescent apprenticeships, a household for the player
  (a partner keeps their own home; the player's children are villagers of the partner's household).

## Health, jobs and stations (PL1-04, PL1-09, PL1-13, PL2-010; agent proposals, provisional)

Audit (PL1-04): damage comes from combat, starvation (`damage_player`) and spoiled food; healing was only the
herbal tonic (3 flowers at the stove, 12 health, food 4) and "Rest until morning" at the family house (full
health and stamina, saves). Nothing healed from the start, and the only tonic needed a stove, flowers and
Cooking. Rest already restores fully, so no new rest healing was added.

- Items (`items.json`, type `medicine`, heal only, no hunger): linen bandage 15 HP / 3c, herbal poultice 30 /
  6c, healing tonic 50 / 12c, strong healing tonic 80 / 22c. `World.player_use_medicine` uses one only when
  health is below the cap, never heals past the cap, and keeps the item otherwise. Health stays apart from
  hunger (food still heals only through `player_eat`). The player starts with two bandages
  (`player_start_items`, inherited by heirs).
- Recipes at the stove: poultice (2 flowers), healing tonic (5 flowers, Cooking 2), strong healing tonic
  (2 healing tonics + 1 ale, Cooking 3). Bandages are not craftable: no linen, flax or cloth exists yet
  (recorded as a `start_kit_only` exception in `resources.json`).
- Apothecary: the sage (Old Lorekeeper, at the sage's hut) is the village apothecary, an ordinary trader
  through the existing trade window (title "Apothecary"). Starting stock `sage_start_stock`; the sage buys
  wild flowers (cap 20, kept for brewing) and brews poultices (below 8 held) and healing tonics (below 6
  held, 5 flowers) when a stove is free; the caravan sells the sage up to `caravan_apothecary_per_visit`
  (4) pieces a visit towards `caravan_apothecary_stock`, at base value, paid from the sage's own coins above
  the trader cash floor; the coins leave the village. The sage's float rose from 30 to 60 coins. No new
  building: the stock sits with the sage, who stays at the hut. Not done: villagers do not forage flowers
  (only the player), so the sage's own brewing depends on the player selling flowers.
- Employer star (PL1-09): `Quests.employer(npc)`, drawn by `Main._sync_stars` (`markers/star.png`, a
  generated 16 px gold star, see the import tool). Keyed by the giver's id in the saved quest list.
- Stove (PL1-13): station cells unchanged; the two cells now stand on Shade's stone coal bed (tiles 3001,
  3004) with the pot on the right fire and the left fire open (the pan lifted off). A chimney was not added:
  the wall layer hides the row above. Prompt "Use Stove"; window "Stove - Cooking & Tonics".
- Sawhorse (PL2-010): the plank stacks are replaced by a plank trestle bench (Shade's table tiles 2539, 2540)
  with logs on it (1021, 1022); cells, use cell and collision unchanged. No tile of a true angled-trestle
  sawhorse or saw exists in the purchased packs.

Wiki notes (for the wiki agent):
- Healing: "Hurt? Use a bandage, poultice or tonic from your pack (it is kept if you are unhurt). Resting at
  home restores everything. The apothecary (the sage at the hut) sells them and buys wild flowers."
- Apothecary: stock is limited; it refills from the caravan (every second day, a few pieces, paid from the
  sage's coins) and from flowers you sell; strong tonics are made at the stove from two healing tonics and ale.
- Jobs: a gold star over a villager means you took a job from them and are not yet paid; deliver the goods
  and talk to them to clear it. Several jobs from one person keep it until all are done.
- Stove: "Use Stove" at the tavern kitchen: pottage, ale, herbal tonic, poultice, healing tonics.
- Sawhorse: the Sawmill's bench saws logs into planks.

## Known gaps

- No marriage, births, aging, adoption or immigration exist yet; households only shrink. Proposals
  are waiting for the owner.
- Children eat by role, not age: villagers have no ages yet, so every child eats `child_food_factor`
  of an adult's food and elders eat as adults.
- Skilled trades cannot be learned (no apprenticeship); villagers move only between general,
  farming and resource work.
- The player cannot own livestock. (Harvesting a field works: `World.player_harvest`, INT-007.)
- Villagers do not build workshops, lease ground to build, or fell trees to clear ground; with no
  births yet, a household is crowded only when people move in. From outside a workshop looks like a
  house. A built building's floor is the ground it stands on (the house stamp has no floor layer).
- No eggs, milk or wool (the owner asked only for meat).
- No audio yet (the volume settings are ready for it).
- Villagers keep only their last 8 memories (having met someone is never forgotten), so older
  grudges and sightings fade.
