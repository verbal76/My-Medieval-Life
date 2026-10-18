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
| Building plots are sold by the manor; the price goes to the treasury (`World.buy_plot`) | |
| The evening business and the wages run at most once a day (`last_reeve_day`, `last_payday`, saved) | No double payments |
| Saves are version 3 (treasury, granary). Older saves move the reeve's coins beyond his purse into the treasury; no coin is lost | CLAUDE.md section 7 |

## Settlers' provisions, inheritance, households and work (agent proposals)

| Decision | Why |
|---|---|
| The manor granary starts with 7 days of the village's food (420 wheat for 100) and each household brings 2 wheat a head, besides its 3 pottage. Finite: nothing is added later except by purchase | A failed first harvest killed 70 of 100. With these stores a 4-day failure is survived; a 12-day failure still kills half the village |
| A household's cash counts as food only up to its share of what the market actually has for sale | In a crop failure the granary sat full while people with coins starved: relief never saw them as short |
| Inheritance: when a villager dies of anything but violence, food goes into the household's pantry and coins and goods to an heir (an adult, else an elder, else a child, lowest id first). A slain villager's purse still lies where they fell; with nobody left in the household, belongings stay there too | Keeps a household's means together; keeps the existing loot and robbery play |
| A pen whose keeper dies or stops farming passes to another farmer, the same household first | Animals were left with nobody to feed them |
| A workstation holds one worker (`capacity` in the village data can raise it). A villager reserves a free station before walking to it and frees it when done; a lapsed reservation is cleared. If all are taken, the villager does something else | Three cooks were sharing one stove |
| An elder pays the family tab when no adult is left | A child starved beside an elder with coins |
| Every villager keeps 7 days of earnings (sales and wages). Each morning, and at once after a death or job change, each household reckons its members, daily food need and cost (food at the cheapest grain price plus firewood), income, food in hand, and runway (cash and trade stock someone is buying). It is sustainable when income covers cost or it holds 10 days of food or runway | Households see trouble coming instead of reacting only to hunger |
| Job mobility: the unemployed, and adults of a household unsustainable for 3 mornings who have 5 days of history and earn less than their share of its costs, look at the job board: manor hand (wage, while the treasury can afford 20 more days), farmhand (up to 2 per field), woodcutter (one per 30 standing trees), hunter (one per 6 game animals above the breeding stock), miner (while ore lasts). Pay is what those doing the job actually earned lately; a needed tool must be affordable and is counted over 10 days; the walk from home counts. They move only for 25% (and 2 coins) more than they earn now. A taken opening is gone for the next applicant. Not back to the job just left for 14 days; 7 days to settle after a change | Uses only existing jobs and wages. Skilled trades need training the game does not have |
| The manor lets its newest hand go when it cannot pay two days of wages | Wages must stay finite |

## Player

| Decision | Why |
|---|---|
| Permadeath: the heir keeps the family's house, chest and plots, starts every skill from nothing and carries only the starting kit (5 coins, rusty sword and pickaxe, bread, rotten apple, plain clothes); what the dead carried lies where they fell, for anyone to take, the heir too. The heir's kit and coins are new to the village (counted in `coin_sources`). Anyone fighting the dead player stops | Owner rule, 2026-10-18 (house, chest and the dropped bag settled by the owner's answers) |
| The journal (Menu, or B): the village record written into an open book, two parchment pages at a time, six lines a page, a heading for each day (repeated as "continued" at the top of a page that starts mid-day), opening at the latest pages | The owner asked for a journal that looks like a book |
| Building: buy a plot from the reeve, a wooden frame appears, deliver 30 planks, 20 stone and 10 logs, and the house stands | The owner's rules (frame, materials only, no extra build time) |
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
| Story quests (`"story": true`) are not offered from needs: every new player, and every heir, starts them; their giver shows the green diamond until they are done. The first: "The sage in the north", learn Fireball from the sage in the hut at the north edge of the village, at his usual price (50 coins) | The owner chose the first storyline quest; the price is the existing one |

## Controls, screen and settings (owner direction; the details are agent proposals)

| Decision | Why |
|---|---|
| The scheme in use is the one of the last input: a touch, a pad button or a stick push past half, or a key, a mouse click or a real mouse movement. Touch buttons show only for touch unless the setting says always or never; prompts name the key or pad button; with keys or a pad, panels take focus, and B closes them | The owner: detect the control scheme automatically |
| The interface is laid out 720 px high on a computer and 450 px on a phone (times 1.2 / 1 / 0.8 for the small, normal and large interface size), at 16:9, and stretched to fill any screen; the camera zoom is scaled with it, so the map looks the same | One layout for every resolution; build 1's phone text was too small to read |
| Settings in `user://settings.cfg`, separate from the save: master, music and sound-effect volumes (Music and SFX audio buses, used once there are sounds), display mode, window size (16:9 sizes that fit the screen; first start: the second largest that fits), VSync, frame rate cap, interface size, on-screen buttons | The owner asked for the usual settings; window options only on a computer |
| Attack mode as the owner described. One strike when arriving at the target, then one per tap on it; tapping open ground walks there and clears the mark but keeps the mode; the mark is dropped when the target dies, hides indoors or gets 12 tiles away. A right-click strikes without attack mode; Space or the pad's X swings at what is in front | The owner's attack-mode rules, extended to mouse and pad |
| The interface is drawn with the owner's flat UI pack (dark scheme of set 3), recoloured on import from navy to wood brown (buttons, tabs and icon tiles 111/74/44, windows 43/29/19, parchment highlights) at the owner's word: windows in its dark tone, titles in its tab, every button on its button tile (lighter when pointed at, darker when pressed, a pale outline when it has keyboard or pad focus), the X tile to close, and its icon tiles on the touch bar (gauntlet Use, sword Attack, fire, backpack Pack, star Skills, list Menu) and in the HUD (heart, food bag, bolt, coin bag); health red from its status bars, hunger green, stamina gold | The owner: "All buttons should be a button from the UI pack"; "Do like a woody brown color" |
| Prompts and the controls list use Kenney Input Prompts (CC0): keyboard keys and mouse, Xbox-style pad buttons (the most common layout; others are in the pack), touch gestures | The owner supplied the pack for this |
| Attack mode on: the Attack tile turns red and reads "Attack ON" | Visible state for a toggle |
| The target marker is the iron sword item icon (16 px pixel art) turned to point down, bobbing above the target | Matches the pixel art; the owner's flat UI pack is not imported yet |
| Blood: 8 of the 36 Kenney splats, shrunk to 16 px with a hard edge, dark red with a darker rim, at a random quarter turn; looks only (not saved, not the world's random numbers). Only violent deaths bleed | The owner's rule, kept out of the deterministic simulation |

## Known gaps

- No marriage, births, aging, adoption or immigration exist yet; households only shrink. Proposals
  are waiting for the owner.
- Children eat as much as adults (one hunger rate for everyone).
- Skilled trades cannot be learned (no apprenticeship); villagers move only between general,
  farming and resource work.
- The player cannot own livestock, harvest fields, or hire helpers to deliver building materials.
- No eggs, milk or wool (the owner asked only for meat).
- No aging, no births of people, no audio yet (the volume settings are ready for it).
