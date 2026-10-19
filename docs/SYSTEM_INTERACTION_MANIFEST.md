# System interaction manifest

Every place where one game system changes another, with a stable id. Use it before changing a
system: look the system up in the reverse dependency index, read the interactions listed there, and
run their tests.

Rules:
- Ids are `INT-###`. They are permanent: never renumber or reuse one. A removed interaction keeps its
  heading, with Expected reading "Removed (date, why)".
- Every entry has Trigger, Source, Affects, Expected and Tests. Source and Tests cite files as
  `path` or `path::function`, from the repository root.
- Add or update an entry in the same change as the code it describes.
- `python3 tools/check_interactions.py` checks the ids, the fields, that every cited file and
  function exists, and that the reverse index is current. `--write` regenerates the index. It runs
  in `python3 -m unittest discover -s tests`.
- The game tests are run with `godot --headless --path game --script res://tests/<file>`.

## Systems

- **Character** — the player's name, family, sex, look and sprite
- **Player state** — health, hunger, stamina, skills, generation
- **Inventory** — items carried, stacks, tool and weapon durability
- **Equipment** — the weapon, tool, armour, head, amulet and ring slots
- **Food** — eating, hunger, food points, spoiled food
- **Health** — damage, starvation, death
- **Combat** — attacks between the player, villagers, guards and bandits
- **Crime** — offences, witnesses, memories, guards' response
- **Loot** — bags left on the ground by the dead or by dropping
- **Fields** — crops, ripening, the harvest
- **Resources** — mine deposits and trees
- **Crafting** — recipes and workstations
- **Market** — trade, prices, sellers and buyers
- **Coins** — the coin supply and its conservation
- **Treasury** — the manor's funds, tax, repairs
- **Wages** — pay for the reeve, sage, guards and manor hands
- **Relief** — food for households that cannot cover their needs
- **Granary** — the manor's grain store
- **Households** — members, pantry, the family tab, the household reckoning
- **Employment** — jobs, the job board, job changes, layoffs
- **Inheritance** — what passes on when someone dies
- **Livestock** — pens, keepers, feeding, breeding, slaughter
- **Wildlife** — game animals in the woods, grazing, hunting
- **Bandits** — the bandit camp, robbery, poaching
- **Building** — plots, frames, delivered materials, houses and workshops, hired helpers
- **Workshops** — buildings with stations (forge, anvil, workbench, sawhorse, oven, stove), their holder's to use, others with leave
- **Ledger** — `World.stats` counters used by the economy reports
- **Save** — saving, loading and migrating older saves
- **Interface** — panels, HUD, touch controls
- **Containers** — crates, barrels, stalls and the tavern's tables: their owners' stock
- **Interiors** — the insides of buildings under their roofs: floor, walls, doors, beds and other spots, roof fade
- **Property** — who owns and who holds land, buildings, stalls, pens, fields and stations (one owner reference); the land registry, sales, leases, weekly rent
- **Calendar** — the world calendar: years of 8 days in four seasons, ages in years, the HUD clock (B8-029)
- **Family** — born, sex, the explicit links mother, father, partner and children, life stages, courting and partners (Relations), births, old-age death (B8-029)
- **Overworld** — the generated world outside the village: chunks, roads, mountains, trees, collision, the trees the player felled

## Interactions

### INT-001 · Character creation sets the player
- **Trigger:** The player presses Begin on the creation panel.
- **Source:** `game/scripts/ui/game_ui.gd::show_creation`, `game/scripts/main.gd::new_game`, `game/data/appearances.json`
- **Affects:** Character, Interface, Save
- **Expected:** A name is required (the family defaults to "Wanderer"). The chosen look's sprite becomes the player's and heir's sprite. The world waits paused on the origin story.
- **Tests:** `game/tests/start_test.gd`

### INT-002 · Origin story starts the game
- **Trigger:** Begin on the origin panel.
- **Source:** `game/scripts/ui/game_ui.gd::show_origin`, `game/scripts/main.gd::resume_after_origin`
- **Affects:** Interface, Save
- **Expected:** The world starts running and the new game is saved at once.
- **Tests:** `game/tests/start_test.gd`

### INT-003 · Starting kit from balance data
- **Trigger:** A new world is set up.
- **Source:** `game/scripts/core/world.gd::setup`, `game/data/balance.json`, `game/data/items.json`
- **Affects:** Player state, Inventory, Equipment, Coins
- **Expected:** 100 max health, 5 coins, a rusty sword, a rusty pickaxe, a loaf of bread, a rotten apple and plain clothes (worn), all from `balance.json`. The player's coins count in the coin total.
- **Tests:** `game/tests/run_tests.gd::test_player_actions`, `game/tests/start_test.gd`

### INT-004 · Equipping sets damage, armour, tool use and gear bonuses
- **Trigger:** Wield, Use, Wear or Take off in the pack window (an item or a gear slot chosen); dropping a worn item.
- **Source:** `game/scripts/core/world.gd::player_equip`, `game/scripts/core/world.gd::player_unequip`, `game/scripts/core/world.gd::player_drop`, `game/scripts/core/player_state.gd::damage`, `game/scripts/core/player_state.gd::tool_of`, `game/scripts/core/player_state.gd::defense`, `game/scripts/core/player_state.gd::bonus`, `game/scripts/core/player_state.gd::fit_caps`, `game/scripts/ui/inventory_window.gd::_build_details`, `game/data/items.json`
- **Affects:** Equipment, Combat, Resources, Health, Player state, Interface
- **Expected:** Six gear slots: weapon, tool, armour (body), head, amulet, ring. Only carried items can be equipped, each in the slot its type names. The weapon sets attack damage (unarmed 2). The equipped tool is used first, else the fastest carried one of that kind. Body and head armour add up. Worn items' `bonus` (items.json) raises max health (`hp_cap`) and max stamina (`stamina_cap`); taking one off, or dropping it, brings health and stamina down to the new caps. Head, amulet and ring are saved; an older save loads with them empty.
- **Tests:** `game/tests/run_tests.gd::test_player_actions`, `game/tests/start_test.gd`

### INT-005 · Mining a deposit
- **Trigger:** The player interacts with a deposit holding a pickaxe; or a miner works one.
- **Source:** `game/scripts/main.gd::interact`, `game/scripts/core/world.gd::mine_unit`, `game/scripts/core/npc_brain.gd::_miner`, `game/scripts/core/inventory.gd::wear`
- **Affects:** Resources, Inventory, Player state
- **Expected:** The deposit loses what is mined and the ore goes to the pack. The pick's speed sets the time; the pick wears and can break, emptying the tool slot. Mining XP is gained. Gold needs Mining 3. One Use is one cycle (B8-006): the pickaxe's icon is held in the hand through the swing, the ore is awarded with a "+1 Iron ore" gain line (item id passed to the interface) when the swing ends, and the player returns to idle; only Gather mode repeats. B, Esc, a right-click or a tap stops it with nothing awarded or worn, and so does opening the Pack or any window (B8-010, B8-011).
- **Tests:** `game/tests/start_test.gd`, `game/tests/play_test.gd`, `game/tests/run_tests.gd::test_simulation`

### INT-006 · Felling a tree
- **Trigger:** The player interacts with a tree holding an axe; or a woodcutter works.
- **Source:** `game/scripts/main.gd::interact`, `game/scripts/core/world.gd::fell`, `game/scripts/core/npc_brain.gd::_woodcutter`
- **Affects:** Resources, Inventory, Player state
- **Expected:** The tree becomes a stump and gives logs ("+3 Logs", and a sapling when one drops, as gain lines with the item ids). The axe is held in the hand through each blow and the player is idle when the tree falls; cancelling (B, Esc, a right-click, a tap, a window) stops the blows with nothing awarded. The axe wears. Its whole canopy (both tiles) goes and the trunk cell becomes walkable; a sapling and then the full tree, with its solid trunk, come back on regrowth (INT-040).
- **Tests:** `game/tests/play_test.gd`, `game/tests/run_tests.gd::test_tree_canopy`

### INT-007 · Harvesting a field (player)
- **Trigger:** The player interacts with a ripe field.
- **Source:** `game/scripts/main.gd::interact`, `game/scripts/core/world.gd::player_harvest`, `game/scripts/core/world.gd::take_crop`
- **Affects:** Fields, Inventory, Ledger, Crime
- **Expected:** A handful (`harvest_handful`) leaves the field's crop and goes to the pack, counted as made wheat. When the crop is gone the field is tilled. A field is the manor's (INT-051) and its crop its farmers' (those whose workplace it is, `World.field_workers`): taking it is theft from the first of them (INT-008), except the wheat a farmer hired the player to cut there (INT-046); a farmer who has left the field is never named.
- **Tests:** `game/tests/run_tests.gd::test_player_actions`, `game/tests/run_tests.gd::test_hiring`, `game/tests/start_test.gd`

### INT-008 · Theft is witnessed
- **Trigger:** The player takes something that belongs to someone: wheat from a farmed field, anything from a container or an unattended stall (INT-043), or a pocket picked or tried (INT-044).
- **Source:** `game/scripts/core/world.gd::witness`, `game/scripts/core/world.gd::guard_confront`, `game/scripts/core/world.gd::theft_fine_for`, `game/scripts/core/world.gd::goods_value`, `game/scripts/core/world.gd::pickpocket`, `game/scripts/core/chests.gd::take`, `game/scripts/core/world.gd::near`
- **Affects:** Crime, Ledger, Coins, Treasury, Inventory, Interiors
- **Expected:** Villagers within `witness_radius` (not bandits) who are awake and in the same place as the player (inside the same building, or both outdoors: INT-048) remember it ("saw <player> take <what>"), the victim notices the loss, the player's crime record gains an entry, and the log says so if anyone saw. The goods are marked as stolen from the victim (INT-045). A guard among those who saw it stops the player (agent proposal): what was taken goes back where it came from (the field's farmer, the container), the player pays `World.theft_fine_for(taken)` to the treasury: `theft_fine` plus `theft_fine_share` of the goods' base value (Build 13 owner economy rule 4, so emptying a chest costs more than taking one loaf); a player who cannot pay it all pays what they have and is fought, as for an attack (INT-013). Every crime record carries what was taken (`items`), how many (`qty`) and their base value (`value`, coins for a lifted purse), and `player_stolen_value` counts the total. Only goods and coins move.
- **Tests:** `game/tests/run_tests.gd::test_player_actions`, `game/tests/run_tests.gd::test_theft_and_shops`, `game/tests/run_tests.gd::test_interiors`, `game/tests/start_test.gd`, `game/tests/chests_test.gd::test_household_chest`, `game/tests/chests_test.gd::test_witnessed`

### INT-009 · Harvesting a field (farmers)
- **Trigger:** A farmer's plan reaches a ripe field.
- **Source:** `game/scripts/core/npc_brain.gd::_farmer`, `game/scripts/core/world.gd::take_crop`, `game/scripts/core/world.gd::_on_hour`
- **Affects:** Fields, Inventory, Livestock, Ledger
- **Expected:** The farmer takes what crop is left. A field ripens hourly once grown and holds `field_yield`. Whoever harvests a keeper's field carries feed to the pen first. A field whose farmer hired the player to cut it is left to the player while that work is open (INT-046).
- **Tests:** `game/tests/run_tests.gd::test_food_rules`, `game/tests/run_tests.gd::test_simulation`, `game/tests/run_tests.gd::test_hiring`

### INT-010 · Eating
- **Trigger:** The player eats from the inventory; a villager eats in its plan.
- **Source:** `game/scripts/core/world.gd::player_eat`, `game/scripts/core/npc_brain.gd::_plan_eat`, `game/scripts/core/npc_brain.gd::act`
- **Affects:** Food, Health, Inventory, Ledger
- **Expected:** The food's points go to hunger (max 100). Food with `harm` (the rotten apple) also damages. Non-food cannot be eaten.
- **Tests:** `game/tests/run_tests.gd::test_player_actions`, `game/tests/run_tests.gd::test_food_rules`, `game/tests/start_test.gd`

### INT-011 · Hunger damages, starvation kills
- **Trigger:** Time passes with hunger at zero.
- **Source:** `game/scripts/core/world.gd::_update_player`, `game/scripts/core/world.gd::damage_player`, `game/scripts/core/world.gd::_update_npc`
- **Affects:** Food, Health
- **Expected:** At zero hunger, health falls; at zero health the player or villager dies (INT-016, INT-018). A child's hunger falls `child_food_factor` as fast as an adult's (INT-047).
- **Tests:** `game/tests/run_tests.gd::test_simulation`, `game/tests/run_tests.gd::test_child_food`, `game/tests/scenarios.gd`

### INT-012 · Fighting a bandit
- **Trigger:** The player attacks a bandit.
- **Source:** `game/scripts/main.gd::attack`, `game/scripts/main.gd::_swing_step`, `game/scripts/main.gd::_blow`, `game/scripts/main.gd::attack_button`, `game/scripts/main.gd::_chase_step`, `game/scripts/core/combat.gd::press`, `game/scripts/core/combat.gd::target`, `game/scripts/main.gd::_hit`, `game/scripts/core/npc_brain.gd::fight`
- **Affects:** Combat, Health, Bandits, Interface
- **Expected:** (CQ-01, owner 2026-10-19: sword presses lost, hits needing sprite overlap) A press starts a swing at once (the sword animation shows); the blow lands on the slash frame `player_combat.windup` seconds later, once, on the nearest body within `player_combat.reach` tiles inside the arc ahead or within `close` tiles, with a clear line; foes before bystanders. One press in the last `buffer` seconds of a swing is kept and starts the next swing; others are ignored. The touch Attack button swings at a foe in reach (else toggles attack mode); tap-to-strike walks only into reach. The bandit loses health by the player's damage less its armour and turns on the player, damaging them each second within reach. A bandit below 30% health flees to camp. Combat XP is gained. A swing in progress does not survive loading or a new world.
- **Tests:** `game/tests/combat_test.gd`, `game/tests/start_test.gd`, `game/tests/play_test.gd`

### INT-013 · Attacking villagers or livestock is a crime
- **Trigger:** The player hits a villager, or kills a keeper's animal.
- **Source:** `game/scripts/main.gd::_crime`, `game/scripts/main.gd::_hit_animal`
- **Affects:** Crime, Combat, Livestock
- **Expected:** The victim remembers it. An adult victim and guards within 15 tiles fight the player. A killed animal's keeper comes after the player.
- **Tests:** `game/tests/play_test.gd`

### INT-014 · Bandits rob and poach
- **Trigger:** A bandit reaches an ordinary villager, or game near its camp.
- **Source:** `game/scripts/core/npc_brain.gd::_bandit`, `game/scripts/core/npc_brain.gd::fight`
- **Affects:** Bandits, Coins, Inventory, Wildlife, Interiors
- **Expected:** Half the victim's coins and one item the victim's job does not keep move to the bandit; nothing is created. Guards fight bandits. Bandits only stalk people outdoors; a fight ends when its target falls asleep or goes inside a building the fighter is not in (INT-050).
- **Tests:** `game/tests/run_tests.gd::test_simulation`

### INT-015 · Looting and dropping
- **Trigger:** The player interacts with a bag, or drops items from the inventory.
- **Source:** `game/scripts/main.gd::interact`, `game/scripts/core/world.gd::player_drop`
- **Affects:** Loot, Inventory, Coins, Equipment
- **Expected:** Looting moves the bag's coins and whatever fits into the pack; an empty bag disappears. Dropping puts exactly the dropped items in a new bag and empties a slot that held the last one.
- **Tests:** `game/tests/run_tests.gd::test_player_actions`, `game/tests/start_test.gd`

### INT-016 · Violent death leaves possessions
- **Trigger:** A villager or bandit is slain.
- **Source:** `game/scripts/core/world.gd::kill`
- **Affects:** Health, Loot, Coins, Households
- **Expected:** The purse and carried goods lie where they fell as a bag, labelled with their name. Nothing is invented.
- **Tests:** `game/tests/run_tests.gd::test_households_and_work`, `game/tests/start_test.gd`, `game/tests/play_test.gd`

### INT-017 · Non-violent death and inheritance
- **Trigger:** A villager dies of hunger, illness or a fall.
- **Source:** `game/scripts/core/world.gd::kill`, `game/scripts/core/world.gd::_heir`, `game/scripts/core/world.gd::_inherit`, `game/scripts/core/npc_brain.gd::on_death`
- **Affects:** Inheritance, Households, Coins, Employment, Livestock, Property
- **Expected:** Food goes to the pantry. Coins and goods go to the heir: the family first (INT-080: the eldest adult child, then the partner, then other kin), else an adult of the household, else an elder, else a child, lowest id first. A household with nobody left leaves the goods where they fell, and its house, leases and stores go to the manor (INT-054). The household's reckoning reruns at once. Pens pass on (INT-027); a merchant's stall falls vacant (INT-055).
- **Tests:** `game/tests/run_tests.gd::test_households_and_work`, `game/tests/scenarios.gd`

### INT-018 · Player death and the heir
- **Trigger:** The player's health reaches zero, or the player dies of old age (INT-080).
- **Source:** `game/scripts/core/world.gd::damage_player`, `game/scripts/core/world.gd::continue_as_heir`, `game/scripts/core/world.gd::give_start_kit`, `game/scripts/main.gd::continue_as_heir`
- **Affects:** Health, Character, Player state, Loot, Building, Property
- **Expected:** What the dead carried lies where they fell, for anyone to take, the heir too. The heir keeps the home, the chest and everything the family owns or leases (all held as "player", INT-051), starts every skill from nothing and carries only the starting kit, whose coins are counted in `coin_sources`. Anyone fighting the dead player stops; the heir inherits no fight. The world is not reset. If the player has a living child of 16 or more, the eldest becomes the heir and keeps their name, sprite, age and sex (INT-080); otherwise a relative takes over as before.
- **Tests:** `game/tests/play_test.gd`, `game/tests/run_tests.gd::test_player_actions`, `game/tests/run_tests.gd::test_property`

### INT-019 · Trade
- **Trigger:** The player or a villager buys or sells.
- **Source:** `game/scripts/core/world.gd::trade`, `game/scripts/core/world.gd::sell_price`, `game/scripts/core/world.gd::buy_price`, `game/scripts/core/world.gd::player_quote`, `game/scripts/core/world.gd::player_buy_many`, `game/scripts/core/world.gd::player_sell_many`, `game/scripts/ui/quantity_picker.gd::buy_max_priced`, `game/scripts/core/npc_brain.gd::_plan_sell`
- **Affects:** Market, Coins, Inventory, Ledger
- **Expected:** Atomic: the goods and coins both move, or neither does. Traders keep their cash floor. Prices follow stock. The player sells through `World.player_sell`, which handles stolen goods first (INT-045). What each trade buys, and its stock cap, is `NPCBrain.BUYS`: the goods merchant also takes made rings, amulets and helmets (B7-003, owner 2026-10-18), within its coins and caps. The player's Buy and Sell open the shared quantity control (`game/scripts/ui/quantity_picker.gd`, PL1-03). (Build 13, owner economy rules 1 and 2) Each unit of a bulk deal is priced at the stock it leaves (`World.player_quote`): buying runs the seller's stock down, so each unit costs the same or more; selling fills the buyer up, so each unit fetches the same or less; the total is the sum of the unit prices, never the opening price times the quantity. Buy max is the units the player's coins cover in turn (and pack room); sell max is the units the buyer still wants and their own coins cover in turn. Confirm calls `World.player_buy_many` (all or nothing, the bill from the player's own coins) or `World.player_sell_many` (refused whole unless the buyer's own coins cover the whole bill; then a unit at a time through `player_sell` at the live price); a merchant never buys without the coins. Cancel changes nothing. The same control moves stacks to and from the home chest (`World.transfer`; stolen marks move with the quantity, stolen first, PL2-012).
- **Tests:** `game/tests/start_test.gd::_pl_trade_ui_tests`, `game/tests/run_tests.gd::test_trade_is_atomic`, `game/tests/play_test.gd`, `game/tests/run_tests.gd::test_build7_economy`, `game/tests/farming_test.gd::test_market`

### INT-020 · The caravan
- **Trigger:** Noon on caravan days.
- **Source:** `game/scripts/core/npc_brain.gd::caravan`
- **Affects:** Market, Coins, Ledger
- **Expected:**
  - The only source of new coins (counted in `coin_sources`). It does not buy food while the village holds under 3 days of it, days of its age-weighted need (INT-047).
  - A finite regional market (B7-014, agent decision under the owner's authorization of 2026-10-18; every number provisional). It holds a purse, `World.caravan_purse` (starting at `caravan_float`). The purse gains the region's demand for the village's surplus, up to `caravan_allowance` coins a day (a visit adds the days between visits' worth), never above the float, and less and less as the village's coins approach `caravan_ceiling_per_head` a head (nothing at the ceiling); and it gains every coin the village pays it for ore, coal and stone (INT-035, INT-065).
  - It sells first, then buys the surplus at 0.8 x value (never the mine's raw iron ore, copper ore, gold ore, coal or stone, `NPCBrain.NOT_EXPORTED`: they are the forge's and the builders' finite input, B7-007; 79% of the stone mined in the first ten days used to be carried off), at most `caravan_coins` a visit and never more than the purse holds. The smiths' metal goods are bought first (they pay for the caravan's ore with them), then the others; one unit at a time from each seller in turn, the first turning each visit, so a short purse is shared. The village's currency can therefore grow only by the allowance and never past the ceiling (a year-long run with no player: 12-fold before, about 3.4-fold after). A closed currency with no allowance was tried and stalled the village (traders out of cash, 14,000 missed meals for lack of money, three deaths in a year): see `docs/release/LONG_RUN_SIMULATION.md`.
  - `caravan_purse` is saved from save_version 9; an older save's caravan arrives with its float (no village coin changes hands).
- **Tests:** `game/tests/run_tests.gd::test_simulation`, `game/tests/run_tests.gd::test_child_food`, `game/tests/run_tests.gd::test_caravan_purse`

### INT-021 · Crafting and stations
- **Trigger:** The player makes a recipe at a station; a villager plans a recipe.
- **Source:** `game/scripts/main.gd::craft`, `game/scripts/ui/game_ui.gd::show_craft`, `game/scripts/core/npc_brain.gd::_do_recipe`, `game/scripts/core/npc_brain.gd::_station_for`, `game/scripts/core/npc_brain.gd::release_station`, `game/scripts/core/world.gd::station_refusal`, `game/scripts/core/world.gd::station_workers`, `game/scripts/core/world.gd::reserve_for_player`, `game/data/recipes.json`
- **Affects:** Crafting, Inventory, Player state, Ledger, Workshops
- **Expected:** Inputs are removed and outputs added together. A villager reserves a free station it may use (`World.npc_may_use`: the village's are open to all, a workshop's need its holder's leave, INT-061) first (capacity 1) and frees it when done. When all are taken it does something else, counted as `station_busy_<station>`. Audit defect 3 (property phase 2): at a station the player does not hold, a villager's reservation is respected while that villager is at it or on the way (their plan still holds its work; a stale reservation lapses): the craft window says who is working and Make is off. The player working a station takes it for the work's time (`player_until`), so villagers wait or use another. In their own workshop the player never waits.
- **Tests:** `game/tests/run_tests.gd::test_households_and_work`, `game/tests/run_tests.gd::test_construction`, `game/tests/play_test.gd`, `game/tests/start_test.gd`

### INT-022 · Household tax
- **Trigger:** The manor's evening business, once a day.
- **Source:** `game/scripts/core/npc_brain.gd::reeve_day`
- **Affects:** Treasury, Coins, Households
- **Expected:** Each household pays on cash above 40 + 20 per member: 12% while the treasury holds under 10 days of obligations, 6% up to 30 days, none above. It continues if the reeve dies.
- **Tests:** `game/tests/run_tests.gd::test_government`, `game/tests/scenarios.gd`

### INT-023 · Wages and layoffs
- **Trigger:** Payday, once a day.
- **Source:** `game/scripts/core/npc_brain.gd::pay_guards`, `game/scripts/core/npc_brain.gd::_day_labour`
- **Affects:** Wages, Treasury, Coins, Employment
- **Expected:** The sage, reeve, guards and manor hands are paid from the treasury. The newest hand is let go when two days of wages cannot be paid. Day labour is a real job from the manor's work (INT-066), paid when done; an adult of a short household who has earned nothing that day seeks one, and with none open there is no pay. A manor hand hired out for the day to carry building materials (INT-059) is paid by the employer, not the manor, that day.
- **Tests:** `game/tests/run_tests.gd::test_government`, `game/tests/run_tests.gd::test_households_and_work`

### INT-024 · Relief
- **Trigger:** A household can cover under 2 days of food.
- **Source:** `game/scripts/core/npc_brain.gd::_relief`, `game/scripts/core/npc_brain.gd::household_food_days`, `game/scripts/core/npc_brain.gd::_note_relief`
- **Affects:** Relief, Treasury, Granary, Households, Market
- **Expected:** Food goes to the pantry up to 3 days, from the granary first, then bought: carried there as a manor job (INT-066), or at once when the household has under 1 day of food (then also from grain still at the farmers' for the granary); a household with relief on its way waits for it. Under 1 day of food it is paid below the reserve, down to one day of wages. Cash counts as food only up to the market's share. Chronic relief is named in the log. Days and the fill are measured against the household's age-weighted need (INT-047).
- **Tests:** `game/tests/run_tests.gd::test_government`, `game/tests/run_tests.gd::test_child_food`

### INT-025 · Granary purchases
- **Trigger:** The manor's evening business.
- **Source:** `game/scripts/core/npc_brain.gd::surplus_wheat`, `game/scripts/core/npc_brain.gd::keep_wheat`, `game/scripts/core/npc_brain.gd::reeve_day`
- **Affects:** Granary, Treasury, Market, Fields
- **Expected:** Bought grain waits at the farmer's, the manor's, until carried to the granary (INT-066); what is on its way counts toward the granary's target and the village's food. Only genuine surplus is bought: never a farmer's household food, feed reserve or buffer, never in a famine. The granary starts with 7 days of food and is finite. The household food, the target and the start are age-weighted (INT-047).
- **Tests:** `game/tests/run_tests.gd::test_government`, `game/tests/run_tests.gd::test_child_food`, `game/tests/scenarios.gd`

### INT-026 · Repairs and land sales
- **Trigger:** The evening business (repairs); the player buys, leases or sells land or a house (INT-052).
- **Source:** `game/scripts/core/npc_brain.gd::reeve_day`, `game/scripts/core/world.gd::buy_plot`, `game/scripts/core/property.gd::buy`, `game/scripts/core/property.gd::lease`, `game/scripts/core/property.gd::sell`
- **Affects:** Treasury, Market, Coins, Building, Property
- **Expected:** Repairs are bought from village sellers with money beyond 3 days of wages, left at the seller's for the manor's carriers and used up mending (INT-066); the manor buys no more while it holds `manor_jobs.works_stock_max` unused, and buys no stone while its own is being quarried. A plot's price (`plot_price`, provisional) and every sale or rent go to the treasury; a house sold back is paid from it (`gov_land_sales`, `gov_rent`, `gov_land_bought`). The treasury's level then decides wages, repairs and works as before.
- **Tests:** `game/tests/run_tests.gd::test_government`, `game/tests/run_tests.gd::test_property`, `game/tests/play_test.gd`

### INT-027 · Pens and keepers
- **Trigger:** Hourly animal update; a keeper's day; a keeper dies or changes job.
- **Source:** `game/scripts/core/fauna.gd::tick`, `game/scripts/core/fauna.gd::feed`, `game/scripts/core/fauna.gd::new_day`, `game/scripts/core/npc_brain.gd::_keeper`, `game/scripts/core/npc_brain.gd::_hand_over_pens`
- **Affects:** Livestock, Food, Inventory, Households
- **Expected:** Animals eat feed from the trough or starve. A fed pair breeds, and babies grow up. Keepers feed from their own wheat, the pantry or bought feed, and slaughter surplus. A pen is the manor's, let to its keeper (tenant "npc:<id>", `World.pen_keeper`, INT-051); it passes to another farmer, the same household first.
- **Tests:** `game/tests/run_tests.gd::test_animals`, `game/tests/run_tests.gd::test_households_and_work`

### INT-028 · Hunting
- **Trigger:** A hunter's plan; the player kills a wild animal.
- **Source:** `game/scripts/core/npc_brain.gd::_hunter`, `game/scripts/main.gd::_hit_animal`, `game/scripts/core/fauna.gd::kill`
- **Affects:** Wildlife, Loot, Inventory, Food
- **Expected:** The carcass gives meat (half for a baby) and hide. Hunters never take a kind below 2 adults per wood.
- **Tests:** `game/tests/run_tests.gd::test_animals`, `game/tests/play_test.gd`

### INT-029 · The household reckoning and job changes
- **Trigger:** Each morning, and at once after a death or a job change.
- **Source:** `game/scripts/core/npc_brain.gd::evaluate_household`, `game/scripts/core/npc_brain.gd::job_market`, `game/scripts/core/npc_brain.gd::seek_work`, `game/scripts/core/npc_brain.gd::_change_job`, `game/scripts/core/npc_brain.gd::dawn`
- **Affects:** Households, Employment, Wages, Fields, Resources, Wildlife
- **Expected:** A household is sustainable when income covers cost, or it holds 10 days of food or runway. Its daily food need and cost are age-weighted (INT-047). Adults of an unsustainable household, and the unemployed, move to an opening that pays at least 25% (and 2 coins) more. Cooldowns apply. Leaving work gives up the workplace at once: a field's farmers are those whose workplace it is (audit defect 1 fixed), a stall falls vacant (INT-055), a pen passes on.
- **Tests:** `game/tests/run_tests.gd::test_households_and_work`, `game/tests/run_tests.gd::test_child_food`, `game/tests/scenarios.gd`

### INT-030 · Building a house (or a workshop): generic construction
- **Trigger:** The holder of a parcel (its owner, or its tenant on leased ground) marks out a building and anyone delivers materials: the player, a hired helper, a founding household.
- **Source:** `game/scripts/core/world.gd::start_site`, `game/scripts/core/world.gd::deliver`, `game/scripts/core/world.gd::_finish_site`, `game/scripts/core/world.gd::site_progress`, `game/scripts/core/world.gd::site_goods`, `game/scripts/core/world.gd::cancel_site`, `game/scripts/core/world.gd::_workshop_stations`, `game/scripts/core/construction.gd::cost_of`, `game/scripts/main.gd::_sync_sites`, `game/scripts/ui/game_ui.gd::show_build`
- **Affects:** Building, Inventory, Loot, Property, Workshops, Ledger
- **Expected:** One construction for every builder and kind (property phase 2): `start_site(parcel, kind, owner)` marks out a house or a workshop (`Construction.KINDS`, cost `house_cost` / `workshop_cost`), `deliver(parcel, inventory, by)` takes what is still needed from any inventory, and the building is the site owner's whoever delivers. Materials delivered stay goods on the site until it stands (`World.site_goods`, counted by the goods-conservation test); then they are used up in the building (`used_building_<item>` in the ledger). A house stands when 30 planks, 20 stone and 10 logs are in, with no extra build time. A progress bar over the frame and in the build window shows the share of loads delivered. Giving up the site returns every delivered load (to the pack, or a bundle at the site if it is full); no coin moves. The finished house is the parcel holder's at the site's start (`site.owner`; phase 2 helpers may deliver, the owner keeps it), records its parcel (`building.parcel`, `parcel.building`) and changes hands with it (INT-052); a family's first house becomes its home. It has the house stamp's interior, collision and roof (INT-048, INT-049): its floor walkable, walls solid, its bed rests and its chest is the family's store, as the door does (INT-050). The two plots are clear land at the forest edge north of the east houses; no plot overlaps a building, field, pen or stall. A plot can be bought or leased at the plot itself.
- **Tests:** `game/tests/play_test.gd`, `game/tests/run_tests.gd::test_building_site`, `game/tests/run_tests.gd::test_interiors`, `game/tests/run_tests.gd::test_property`, `game/tests/start_test.gd`

### INT-031 · Saving and loading
- **Trigger:** Save from the menu, resting, leaving the app, starting a new game; Continue on the title.
- **Source:** `game/scripts/main.gd::save_game`, `game/scripts/main.gd::continue_game`, `game/scripts/core/world.gd::to_dict`, `game/scripts/core/world.gd::load_dict`, `game/scripts/core/world.gd::_migrate_construction`, `game/scripts/core/construction.gd::to_dict`, `game/scripts/core/construction.gd::load_dict`, `game/scripts/core/world.gd::_move_plots_to_map`, `game/scripts/core/world.gd::_load_containers`, `game/scripts/core/world.gd::_migrate_property`, `game/scripts/core/fauna.gd::load_dict`, `game/scripts/core/property.gd::settle_ended_households`, `game/scripts/core/player_state.gd::to_dict`
- **Affects:** Save, Character, Player state, Inventory, Equipment, Crime, Treasury, Granary, Livestock, Building, Containers, Property
- **Expected:** Written atomically as save_version 9 (`World.SAVE_VERSION`; 9 adds the caravan's balance, `caravan_balance` (INT-020), older saves taking `coin_sources` as it, every coin kept; 8 adds the manor's work, its lots, works yard and jobs (INT-066), loading older saves with nothing outstanding and dropping a version 7 save's single manor quarry job with its wage back (INT-063); 7 adds the coins set aside for each accepted quest (`reserved`) and the day of the player's last work for the manor; version 1-6 saves load with each accepted quest's promise set aside if its giver can pay, every coin kept (`Quests.migrate_reserves`, INT-062); 6 adds each site's kind, workshops with their stamp and leave list, the day's hired helpers with what they carry, and founded households with where they came from; version 5 saves load with every site a house's and every built house drawn from the house stamp, `World._migrate_construction`, and nothing moves; villagers have no "hidden" flag: where they are is their position, inside a building or not; every property record carries its owner and tenant references, leases their rent, due day and arrears, `next_parcel` counts claimed parcels, a settled household is `ended`; the player has no plot list). Versions 1-4 load, with no coin lost: plot owners ""/"player" (and the player's plot list) become the manor's or the player's, a field's farmer ids give way to the manor's ownership (its farmers are those working it), a stall's and a pen's NPC id become their tenant reference (a dead one leaves it vacant), buildings get their starting owners and a house the player built is theirs on its plot, and a household that had died out gives its house and stores to the manor (INT-054); plots, houses and the player stay exactly where they are (`World._migrate_property`). Versions 1-3 also: their villagers "hidden" at home (standing on the door step) are moved inside, each to their own bed's spot (`World._move_indoors`). Fields added later (sex, look, tool, crimes, the stolen marks) load with defaults. The tavern tables' dishes are saved ("containers"); a save from before containers loads with its tables set from the keepers' stock (INT-042). A tree's tiles are taken from the map on load (saves from before two-tile trees hold other tiles); its state and regrowth day come from the save. Saves from before the building plots moved (they lay over houses b20-b22) move each plot to its place on the map with its owner, site and house, and the player with it if they stood on it; saved trees the map no longer has (cleared for the plots) are dropped. An unreadable save is kept and a new game starts.
- **Tests:** `game/tests/run_tests.gd::test_save_round_trip`, `game/tests/run_tests.gd::test_player_actions`, `game/tests/run_tests.gd::test_interiors`, `game/tests/run_tests.gd::test_construction_migration`, `game/tests/run_tests.gd::test_helpers`, `game/tests/run_tests.gd::test_households_split`, `game/tests/start_test.gd`

### INT-032 · Controls: touch, gamepad, keyboard and mouse
- **Trigger:** Any input. A tap or click on the map; the touch action bar; a gamepad or key press.
- **Source:** `game/scripts/main.gd::_input`, `game/scripts/main.gd::_unhandled_input`, `game/scripts/main.gd::_tap`, `game/scripts/main.gd::attack_button`, `game/scripts/main.gd::strike`, `game/scripts/main.gd::_chase_step`, `game/scripts/main.gd::_route_step`, `game/scripts/main.gd::_talk_step`, `game/scripts/ui/game_ui.gd::set_scheme`, `game/scripts/ui/game_ui.gd::blocks`, `game/scripts/main.gd::pan_camera`, `game/scripts/main.gd::look_at_tile`, `game/scripts/main.gd::recenter`, `game/scripts/main.gd::_follow`, `game/scripts/main.gd::_look_step`, `game/scripts/ui/game_ui.gd::toggle_map`, `game/scripts/ui/village_map_view.gd::build_image`
- **Affects:** Interface, Combat, Crime, Inventory
- **Expected:**
  - The scheme follows the last input. Touch buttons show only for touch (setting: auto, always, never). Prompts name the key or pad button. With keys or a pad, panels take focus. The pad's B button closes panels.
  - A tap or click next to the player uses the target; elsewhere the player walks there along the villagers' pathfinder, around walls and trees, finding the way again if stuck. A tap on a villager walks up to them, following as they move, and speaks to them (INT-039). A tap on a button or panel never moves the player.
  - The Attack button toggles attack mode. In it:
    - A tap on a person or animal puts the sword marker on it. The player walks over and strikes once; each further tap on it strikes again.
    - A tap on someone else moves the marker. A tap on open ground walks there and clears the mark.
  - A right-click strikes without attack mode. Space or the pad's X swings at what is in front.
  - Striking a villager is a crime (INT-013).
  - Looking around: a two-finger drag (its midpoint; the spread still zooms), a middle-button drag or the right stick moves the camera off the player; it stays there, kept over the map, until Recenter, C, a right-stick click, or walking with keys or the left stick. Lifting two fingers never walks. Recenter shows only while looking around.
  - Following the player, the camera has a dead zone: it moves only when the player walks out of a box 40% x 35% of the view in the middle of the screen, then keeps them at its edge. Recenter puts the player in the middle.
  - While the player works (mining, felling, picking, harvesting, mending, crafting): B, Esc, a right-click or a tap stops it at once (B8-011), and the Pack, Skills, Journal or any window stops it (B8-010); nothing is awarded and nothing resumes on closing. Esc with nothing under way is still the menu.
  - Several things to use at once (a person beside a forge, a container, a seam, a bed) are all offered, nearest first (B8-014): Q or Tab (D-pad left and right) choose, Use does the chosen one, the prompt shows the next choice on a second line. B stays Cancel, LB and RB Map and Skills.
  - Sprint (B8-027): Shift held (or toggled with the balance's `sprint_toggle`) or LT toggled gives `sprint_speed` times the walking speed for `sprint_stamina_per_sec` stamina a second; it ends when stamina runs out and never starts during work or an attack.
  - The village map (Map button, M, pad LB; closed the same way, the X, Esc, B or Android's Back) pauses the game and draws the map data with the player, the player's home and the named places; a tap on it looks there.
- **Tests:** `game/tests/start_test.gd`

### INT-033 · Death shown: flicker and blood
- **Trigger:** A villager or bandit is slain, or an animal is hunted or slaughtered.
- **Source:** `game/scripts/core/world.gd::kill`, `game/scripts/core/fauna.gd::kill`, `game/scripts/main.gd::_on_bled`, `game/scripts/main.gd::_sync_sprites`, `game/scripts/main.gd::_sync_animals`
- **Affects:** Interface, Health, Wildlife, Livestock
- **Expected:** The world emits `bled` only for violent deaths (not hunger or illness). The body flickers for 1.2 s and disappears. A blood splat lies where it fell and fades over 90 s. Looks only: not saved, and the world's RNG is not used.
- **Tests:** `game/tests/start_test.gd`

### INT-034 · Settings and screen size
- **Trigger:** The game starts; a change on the settings screen; the window is resized.
- **Source:** `game/scripts/ui/game_settings.gd::apply`, `game/scripts/ui/game_settings.gd::layout_height`, `game/scripts/main.gd::apply_settings`, `game/scripts/ui/game_ui.gd::show_settings`
- **Affects:** Interface, Save
- **Expected:**
  - The interface is laid out 720 px high on a computer and 450 px on a phone, times the interface size, and scaled to the screen. The camera zoom compensates, so the map keeps its size.
  - Volumes set the Master, Music and SFX buses.
  - Display mode, window size (only sizes that fit the screen) and VSync apply on a computer. The frame cap applies everywhere.
  - Everything is saved in `user://settings.cfg`, apart from the game save.
- **Tests:** `game/tests/start_test.gd`

### INT-035 · Caravan imports for the forge
- **Trigger:** A caravan passes (noon on caravan days).
- **Source:** `game/scripts/core/npc_brain.gd::caravan`, `game/scripts/core/npc_brain.gd::_caravan_imports`, `game/data/balance.json`
- **Affects:** Market, Coins, Crafting, Resources
- **Expected:**
  - Only once the village's own deposits of iron ore, copper ore or coal are down to `caravan_import_when_left`.
  - Each smith buys up to `caravan_import_stock` at the item's value, keeping the trader cash floor.
  - The coins leave the village: `coin_sources` falls by what was spent, so coins stay conserved. They refill the caravan's purse (`caravan_balance` falls, INT-020), and the caravan sells before it buys.
  - Stone comes the same way, to the raw-goods merchants instead (INT-065).
- **Tests:** `game/tests/run_tests.gd::test_trades_and_works`

### INT-036 · Public works and repairs buy from the trades
- **Trigger:** The manor's evening business.
- **Source:** `game/scripts/core/npc_brain.gd::reeve_day`, `game/scripts/core/npc_brain.gd::_public_works`, `game/scripts/core/construction.gd::open_need`
- **Affects:** Treasury, Market, Coins, Crafting, Building
- **Expected:**
  - Repairs buy planks, stone, logs and iron bars.
  - While a reeve lives, public works spend `public_works_share` of the treasury beyond its tax-holiday level on planks, iron bars and stone, at most `public_works_max_loads`. Sellers keep `public_works_seller_keeps`.
  - Repairs and public works leave on sale what open building sites still need (`Construction.open_need`), so builders are not starved (audit).
  - The goods are used up. With no reeve, nothing is spent.
- **Tests:** `game/tests/run_tests.gd::test_trades_and_works`

### INT-037 · A lost tool and what was gathered
- **Trigger:** A woodcutter's axe or a miner's pick breaks, or is stolen.
- **Source:** `game/scripts/core/npc_brain.gd::_woodcutter`, `game/scripts/core/npc_brain.gd::_miner`, `game/scripts/core/npc_brain.gd::_get_tool`
- **Affects:** Resources, Market, Employment
- **Expected:** What was gathered is sold to a buyer first, then a new tool is bought from a smith or merchant. Without one, the worker waits and earns nothing, which the household reckoning sees (INT-029).
- **Tests:** `game/tests/run_tests.gd::test_trades_and_works`, `game/tests/scenarios.gd`

### INT-038 · Side quests
- **Trigger:** Dawn (offers are refreshed); the player accepts or completes a quest in conversation; a giver dies.
- **Source:** `game/scripts/ui/game_ui.gd::_quest_choices`, `game/scripts/ui/game_ui.gd::_quest_items`, `game/scripts/main.gd::_sync_diamonds`, `game/scripts/core/quests.gd::refresh`, `game/scripts/core/quests.gd::accept`, `game/scripts/core/quests.gd::complete`, `game/scripts/core/quests.gd::drop_failed`, `game/scripts/core/quests.gd::start_story`, `game/scripts/core/quests.gd::on_learned`, `game/scripts/core/quests.gd::marker`, `game/scripts/core/npc_brain.gd::dawn`, `game/scripts/core/world.gd::continue_as_heir`, `game/data/quests.json`
- **Affects:** Households, Inventory, Coins, Crime, Save, Player state
- **Expected:**
  - Offers come only from villagers whose condition holds (job or role, holding too little of something, a household short of food, a living bandit who robbed them), at most `quest_max_offers`.
  - Accepting moves an offer to the player's quests (at most `quest_max_active`).
  - Completing moves the asked-for goods to the giver and the promised reward, set aside when the player accepted, to the player (INT-062); coins are conserved. A giver who cannot pay the reward does not offer it.
  - A giver's death fails a side quest. Offers and accepted quests are saved.
  - Story quests start with every new player and every heir, and on loading a save from before they existed. Their giver shows the story marker, a green pennant, until done; a villager with an offer shows what the quest is about (scroll for a skill, wheat for food, iron for ore, crossed swords for combat, a log, an axe). A giver who is inside their own home shows the marker over the house door instead; givers at work (the tavern, the smithy) are seen and marked as usual. Markers draw over roofs and tree canopies. "The sage in the north" is done when the player learns Fireball.
  - A quest with `teach` raises a player skill to its level when done ("The tanner's craft": 2 hides for Crafting 2), offered only below that level (`player_below`), under the skill scroll; the talk window says what was learned under the giver's words.
  - In conversation: "Need any help?" hears an offer, then "I'll do it" or "Not now"; "Here you are" hands in a ready quest. A quest giver always stops to talk, even when busy (INT-039). The journal has a Quests page.
- **Tests:** `game/tests/run_tests.gd::test_quests`, `game/tests/run_tests.gd::test_skill_quest`, `game/tests/start_test.gd`

### INT-039 · Talking to a villager: conversation or a called-out line
- **Trigger:** The player uses a villager in front of them, or reaches one they tapped.
- **Source:** `game/scripts/main.gd::approach`, `game/scripts/main.gd::say`, `game/scripts/main.gd::_sync_bubbles`, `game/scripts/ui/dialogue.gd::busy`, `game/scripts/ui/dialogue.gd::brush_off`, `game/scripts/ui/dialogue.gd::opening`, `game/scripts/ui/dialogue.gd::meet`, `game/scripts/ui/dialogue.gd::animal_killed`, `game/scripts/core/npc.gd::remember`, `game/scripts/main.gd::_crime`, `game/scripts/ui/game_ui.gd::show_talk`, `game/scripts/view/speech_bubble.gd`
- **Affects:** Interface, Crime, Households, Save
- **Expected:**
  - A villager who is busy (the current plan step is a walk, or work with the working animation, or they are fighting) calls out one line in a speech bubble over their head for 2.5 s and carries on; the talk window does not open. At most one bubble per villager. Bandits always get the talk window. A shopkeeper at their counter or stall opens their shop instead (INT-041).
  - Anyone else opens the conversation: portrait, who they are, and what they say, built from their job, `doing`, hunger, the household's reckoning (`hh.econ`), relief days, pantry firewood, their memories and the village record. Nothing in the world changes except one memory, below.
  - Opening the conversation adds the memory "met <player name>" (once; saved with the villager's memories, which hold the last 8, but never drop a "met" memory). Lines then greet the player by name, and busy lines are friendlier than a stranger's.
  - A villager who remembers being attacked by the player, or seeing the player take something (INT-007, INT-013), answers coldly in both the bubble and the conversation. A keeper whose animal the player killed remembers "<player> killed my <animal>" (not an attack on them) and says that.
  - Lines are chosen by villager id and day, never by a random number generator.
- **Tests:** `game/tests/start_test.gd`

### INT-040 · Walking behind trees
- **Trigger:** The player or a villager walks among trees; a tree is felled or regrows.
- **Source:** `tools/build_village.py`, `game/scripts/core/village_map.gd::find_path`, `game/scripts/view/canopy_fade.gd::update`, `game/scripts/main.gd::_on_tile_changed`, `game/scripts/core/world.gd::fell`
- **Affects:** Resources, Interface
- **Expected:** Only a standing tree's trunk cell is solid, for the player's movement and every path; its two canopy tiles are drawn over people and animals, so they walk behind it. The canopy over the player fades to 45% in 0.15 s and back when they leave; villagers do not fade trees. A canopy change (felling, regrowth, a new house) puts any faded canopy back first.
  - Generator v6 (Build 8): the village map draws no tree at all: every tree is a record in village.json `trees` (trunk cell; the old tile ids only fix the species), drawn by TreeView, so no crown or trunk tile is left in a layer; trees stand clear of roads, doors, fields, plots, stations and deposits, and their crowns never overhang a building (`tests/test_village.py`).
- **Tests:** `game/tests/run_tests.gd::test_tree_canopy`, `game/tests/start_test.gd`

### INT-041 · Shops: a counter or stall with its keeper serves the player
- **Trigger:** The player uses (or taps) the tavern counter or a market stall, or a shopkeeper standing at it.
- **Source:** `game/scripts/main.gd::_find_target`, `game/scripts/main.gd::_shop_target`, `game/scripts/main.gd::approach`, `game/scripts/main.gd::interact`, `game/scripts/main.gd::_usable_at`, `game/scripts/core/world.gd::at_post`, `game/scripts/core/world.gd::shopkeeper_at`, `game/scripts/ui/game_ui.gd::show_trade`
- **Affects:** Market, Interface
- **Expected:**
  - A tavern keeper within 2.5 tiles of the counter's use cell, or a merchant within 2.5 tiles of their stall, alive, awake and not fighting, is at their post. The prompt reads "Buy from <name> (tavern)" or "(food stall)" etc., and using it opens their trade window directly, titled "Buy from ...", with a "Talk to <name>" button.
  - Approached at their post, a shopkeeper always serves (the shop opens; never a brush-off bubble), unless they have quest business, which opens the conversation as before (INT-039).
  - A tapped counter, stall or container is walked to and used on arrival (touch); keys and the pad use what the player faces.
  - The counter with nobody at it says so; a stall with its merchant away is the merchant's goods (INT-043).
- **Tests:** `game/tests/start_test.gd`

### INT-042 · Containers hold their owners' stock; the keepers set the tavern's tables
- **Trigger:** A new world or a load; each game hour (the tavern opens and closes, `tavern_hours`).
- **Source:** `tools/build_village.py`, `game/scripts/core/world.gd::_load_containers`, `game/scripts/core/world.gd::container_store`, `game/scripts/core/world.gd::container_owner`, `game/scripts/core/world.gd::serve_tables`, `game/scripts/core/world.gd::show_tables`, `game/scripts/core/world.gd::_update_food_days`, `game/scripts/core/npc_brain.gd::caravan`
- **Affects:** Containers, Households, Market, Food, Save, Interface
- **Expected:**
  - village.json lists the crates and barrels by each house, in and around the tavern and beside each stall, and each dish or mug drawn on a tavern table (no map tile moves). Generator v6: every house's crates and barrels stand inside its own rectangle (its door yard) and the tavern's in and by the tavern, so an owner's goods are always in or directly beside their building, never in a public row (`tests/test_village.py::test_chests_stand_by_their_owners`).
  - A house's crate or barrel is the pantry of the household that holds the house (`World.holder_of`, INT-051); a tavern crate is the first alive tavern keeper's stock; a stall's crate (and the stall itself) is the stock of the merchant it is let to. A house of the player's or the manor's holds nothing in its crates (the family chest is the player's store). They hold nothing of their own.
  - A tavern table holds one dish of its own: while the tavern is open, each empty table gets one of its kind from a keeper (in turn) who has more than `table_keep` of it, else any cooked food they can spare; at closing every dish goes back to the keeper who set it out. Food on the tables counts in the village's food days and the caravan's food check. A table shows its dish tile only while it holds food.
  - Goods only move between owners and tables: nothing is made or lost.
- **Tests:** `game/tests/run_tests.gd::test_theft_and_shops`, `game/tests/start_test.gd`

### INT-043 · Taking from a container or an unattended stall is theft
- **Trigger:** The player uses a crate, barrel, tavern table, or a stall whose merchant is away.
- **Source:** `game/scripts/main.gd::_container_target`, `game/scripts/main.gd::interact`, `game/scripts/core/world.gd::player_take`, `game/scripts/core/world.gd::container_pick`, `game/scripts/core/world.gd::witness`
- **Affects:** Containers, Crime, Inventory, Households, Market
- **Expected:** The prompt says what will happen: "Take pottage (the tavern's) — theft", "Take wheat (the Reed household's) — theft", "Empty crate (...)". One use takes one of what the container holds most of into the pack (not when the pack is full), marked as stolen from its owner (the table's keeper, the tavern keeper, the household's first adult, the merchant), and is witnessed as theft (INT-008). An unseen theft gives a little Stealth experience.
- **Tests:** `game/tests/run_tests.gd::test_theft_and_shops`, `game/tests/start_test.gd`

### INT-044 · Picking a pocket
- **Trigger:** "Pick pocket — theft" in the conversation with a villager within 1.8 tiles.
- **Source:** `game/scripts/ui/game_ui.gd::_talk_view`, `game/scripts/main.gd::pickpocket`, `game/scripts/core/world.gd::pickpocket`, `game/scripts/core/world.gd::guard_near`, `game/scripts/ui/dialogue.gd::caught`
- **Affects:** Crime, Coins, Inventory, Player state, Interface
- **Expected:** Success with chance `pickpocket_chance` + `pickpocket_chance_per_level` per Stealth level above 1 (at most `pickpocket_chance_max`), from the world's random numbers: 1 to `pickpocket_coins_max` coins (never more than they carry), or, with no coins, one thing they carry that is not a work tool, marked as stolen from them; they later find it missing. Caught: they remember "caught <player> picking my pocket" and shout; everyone in sight sees the try; a guard who saw it or is within `guard_call_radius` of them stops the player (fine, INT-008). Those who caught the player answer coldly. Stealth experience either way.
- **Tests:** `game/tests/run_tests.gd::test_theft_and_shops`, `game/tests/start_test.gd`

### INT-045 · Stolen goods are marked; selling them
- **Trigger:** The player steals (INT-007, INT-043, INT-044), sells in a trade window, eats, drops or otherwise loses goods; saving and loading.
- **Source:** `game/scripts/core/player_state.gd::mark_stolen`, `game/scripts/core/player_state.gd::trim_stolen`, `game/scripts/core/player_state.gd::unmark`, `game/scripts/core/world.gd::player_sell`, `game/scripts/ui/game_ui.gd::show_trade`
- **Affects:** Crime, Market, Inventory, Coins, Treasury, Save
- **Expected:**
  - Each stolen piece carried is marked with whose it was (PlayerState.stolen, saved); marks never outnumber what is carried, so eaten, dropped, sold or stored goods lose theirs. The trade window shows how many of a kind are stolen.
  - Offered to its owner or anyone of the owner's household: refused ("That pottage is ours!"), remembered, recorded as a crime, and a guard within `guard_call_radius` of the buyer stops the player and returns it (INT-008).
  - Sold to anyone else: the usual price (the buyer cannot tell), marked pieces first; a guard within `witness_radius` questions the seller with chance `guard_question_chance`: the piece goes back to its owner and the fine is paid.
- **Tests:** `game/tests/run_tests.gd::test_theft_and_shops`

### INT-046 · Paid work for the player
- **Trigger:** The player asks a villager "Any work for me?", accepts, cuts a hired field, hands the work in; dawn (lapses).
- **Source:** `game/scripts/core/quests.gd::hires`, `game/scripts/core/quests.gd::hire_offer`, `game/scripts/core/quests.gd::accept`, `game/scripts/core/quests.gd::complete`, `game/scripts/core/quests.gd::hired_harvest`, `game/scripts/core/quests.gd::hired_on`, `game/scripts/core/quests.gd::drop_failed`, `game/scripts/core/world.gd::player_harvest`, `game/scripts/core/npc_brain.gd::_farmer`, `game/scripts/ui/game_ui.gd::_quest_choices`, `game/scripts/main.gd::approach`, `game/data/quests.json`
- **Affects:** Employment, Coins, Inventory, Fields, Crime, Interface, Ledger, Save
- **Expected:**
  - A working adult whose job a `hire` template names (farmer, woodcutter, miner) offers work only when it exists (a ripe field, too few logs or ore) and they hold the whole wage; otherwise they say why not. Never a dawn offer or marker. One job per employer; at most `quest_max_active` tasks.
  - Taking the work on sets the whole wage aside from the employer's purse (INT-062); handing in moves the goods to the employer and that wage to the player (`hired_wages`). No coins are created. The reeve offers work for the manor (INT-063).
  - A hired harvest hand cuts up to the hired amount from the employer's field without theft; the field's farmers leave it meanwhile. Undone work lapses after its `days` (the wage goes back to the employer); it fails if the employer dies. Wheat cut for harvest work that lapses is the farmer's (INT-064). Accepted work is saved with the player's quests.
- **Tests:** `game/tests/run_tests.gd::test_hiring`, `game/tests/start_test.gd`

### INT-047 · Children eat by age in every food reckoning
- **Trigger:** Time passes (hunger); any reckoning of a household's or the village's food.
- **Source:** `game/scripts/core/npc_brain.gd::food_factor`, `game/scripts/core/npc_brain.gd::household_day_food`, `game/scripts/core/npc_brain.gd::village_day_food`, `game/scripts/core/npc_brain.gd::household_food_days`, `game/scripts/core/npc_brain.gd::_relief`, `game/scripts/core/npc_brain.gd::keep_wheat`, `game/scripts/core/npc_brain.gd::reeve_day`, `game/scripts/core/npc_brain.gd::evaluate_household`, `game/scripts/core/npc_brain.gd::caravan`, `game/scripts/core/world.gd::_update_npc`, `game/scripts/core/world.gd::_update_food_days`, `game/scripts/core/world.gd::setup`, `game/data/balance.json`
- **Affects:** Food, Households, Relief, Granary, Market, Employment
- **Expected:** A child's hunger falls `child_food_factor` (0.6) as fast as an adult's, so a child eats that share. Every food reckoning weights members the same way: household days and market share, relief, a farmer's household keep, the granary target and start, the village's food days (famine), the caravan's reserve, the household reckoning, and through them the food quest's `household_food_below` and day labour.
- **Tests:** `game/tests/run_tests.gd::test_child_food`, `game/tests/run_tests.gd::test_households_and_work`, `game/tests/run_tests.gd::test_simulation`

### INT-048 · Interiors: every roofed building has an inside, entered through its doors
- **Trigger:** The village is generated; a world starts or loads; the player finishes a house.
- **Source:** `tools/build_village.py`, `game/scripts/core/world.gd::index_interiors`, `game/scripts/core/world.gd::interior_for`, `game/scripts/core/world.gd::place_of`, `game/scripts/core/world.gd::near`, `game/scripts/core/world.gd::_built_collision`, `game/scripts/core/world.gd::stamp_of`, `game/scripts/core/npc_brain.gd::wander_cell`
- **Affects:** Interiors, Building, Crime, Households, Save
- **Expected:**
  - village.json gives each building an `interior` (owner rule: one system for every enterable building): its doors, `area` (the cells under its roof reached from its doors, inside its rectangle, never past a wall), `floor` (the walkable ones), `roof` (the cells its roof tiles cover) and `spots` (beds and straw pallets with the head's side and tile, tables, hearths, chests, each with the floor cell to use it from). Homes (houses, the manor, the tavern, the sage's hut) have six sleeping places: Shade's beds, five in each small house, then pallets.
  - Floor is walkable and walls and furniture solid; only doors (and open doorways) lead out. The roads, trees, buildings, plots and containers are where generator v2 put them.
  - A built house gets the house stamp's interior and collision, a workshop its workshop stamp's (`stamps.workshop_<kind>`: Shade's small house with the beds taken out and the smithy's or tavern kitchen's stations copied in, tile for tile, by `tools/build_village.py`), offset to its parcel, now and after loading; whoever built it.
  - "Where someone is" is their cell: inside a building's area, or outdoors. People see (World.near: witnesses, guards, targets) only within the same place, and not while asleep. Villagers strolling outdoors stay outdoors.
- **Tests:** `game/tests/run_tests.gd::test_interiors`, `game/tests/start_test.gd`

### INT-049 · Roof fade: the player sees inside the building they are in
- **Trigger:** The player walks under a building's roof (in through its door, or behind its eaves) or out from under it.
- **Source:** `game/scripts/view/roof_fade.gd::follow`, `game/scripts/view/roof_fade.gd::update`, `game/scripts/core/world.gd::roof_over`, `game/scripts/main.gd::_sync_sprites`, `game/scripts/main.gd::_covered`, `game/scripts/main.gd::_sync_diamonds`, `game/scripts/main.gd::_sync_bubbles`, `game/scripts/main.gd::_creature_at`, `game/scripts/main.gd::_talk_step`, `game/scripts/main.gd::_chase_step`, `game/scripts/main.gd::_on_building_added`
- **Affects:** Interiors, Interface
- **Expected:** Owner decision (roof fade, no separate interior scenes). Only that building's roof tiles (the village's roof layers, `roof_layers`) fade fully out in 0.25 s while the player is inside, and come back 0.3 s after they leave (no doorway flicker). Behind the eaves a roof fades only when it covers the player's feet and head, after 0.4 s there, and only to half (owner rule: only when needed, not simply behind the eaves). Other roofs and tree canopies stay. Someone inside a building whose roof is on is not drawn, not tapped or chased, has no bubble, and their quest marker hangs over that building's door; inside the building the player is in, they are drawn and can be talked to. A sleeper is drawn lying in their bed under its blanket (on a pallet, without one). Nothing scans the map each frame: the building comes from a cell lookup. A roof change (a new house) puts a faded roof back first.
- **Tests:** `game/tests/start_test.gd`

### INT-050 · Going home: villagers walk in, sleep in their beds, eat at the table
- **Trigger:** Night (`SLEEP`), a guard off duty, a hungry villager with food at home, a keeper taking feed from the pantry.
- **Source:** `game/scripts/core/npc_brain.gd::_plan_sleep`, `game/scripts/core/npc_brain.gd::_plan_bed`, `game/scripts/core/npc_brain.gd::_plan_eat`, `game/scripts/core/npc_brain.gd::act`, `game/scripts/core/npc_brain.gd::decide`, `game/scripts/core/world.gd::home_spot`, `game/scripts/core/world.gd::home_cell`, `game/scripts/core/world.gd::present`, `game/scripts/core/world.gd::wake`, `game/scripts/core/world.gd::wake_near`, `game/scripts/ui/game_ui.gd::show_sleeper`, `game/scripts/core/world.gd::asleep`, `game/scripts/main.gd::_find_target`, `game/scripts/main.gd::_show_sleeper`
- **Affects:** Interiors, Households, Crime, Market, Bandits, Interface
- **Expected:**
  - The same entry mechanic for villagers and the player (owner rule): they walk in through the door. Each member of a household has their own sleeping place: the family takes the beds, guards and cooks the straw pallets (`World._sleep_order`) and lies in it until morning (or two hours, off duty), asleep (`anim` "sleep"); they eat at the household's table and take from its chest.
  - Sleep limits awareness, not interaction (owner rule): asleep villagers do not trade, serve, witness, guard or get robbed by bandits, but the player can reach them (`World.present`): wake them and talk, pick their pocket in their sleep (easier; a fumble wakes them and they remember it), or attack them. A blow wakes the sleeper and the noise wakes sleepers within `sleep_wake_radius` in the same place, who then witness through the usual crime system (INT-008, INT-044). Fights between villagers go on against a sleeper, who wakes when struck. Awake villagers inside a building trade as anywhere.
  - In the player's own house, the bed rests until morning and the chest opens the family's store (rest too); the door still offers both.
- **Tests:** `game/tests/run_tests.gd::test_interiors`, `game/tests/run_tests.gd::test_beds`, `game/tests/start_test.gd`

### INT-051 · One owner reference for all property
- **Trigger:** A new world (starting owners), a load, and every deal, job change, death or eviction that changes who owns or holds something.
- **Source:** `game/scripts/core/world.gd::owner_of`, `game/scripts/core/world.gd::tenant_of`, `game/scripts/core/world.gd::holder_of`, `game/scripts/core/world.gd::holds`, `game/scripts/core/world.gd::set_owner`, `game/scripts/core/world.gd::set_tenant`, `game/scripts/core/world.gd::party`, `game/scripts/core/world.gd::field_workers`, `game/scripts/core/world.gd::pen_keeper`, `game/scripts/core/world.gd::may_use`, `game/scripts/core/world.gd::_init_ownership`, `game/scripts/core/world.gd::container_owner`, `game/scripts/core/population.gd::populate`
- **Affects:** Property, Building, Fields, Livestock, Market, Containers, Crafting, Households, Crime
- **Expected:**
  - One reference everywhere: "manor", "player" (the family, its own household), "hh:<id>", "npc:<id>" (only as the tenant of a stall or pen). Every building, parcel, stall, pen, field and station has `owner` and `tenant`; nothing else records ownership (the six older representations are gone or derived).
  - At the start a house and the sage's hut are their household's; the manor house and the tavern are the manor's, let rent-free to the reeve's and the tavern keepers' households; the smithy, fields, pens, stalls and stations the manor's; each stall let to its merchant, each pen to its keeper; plots the manor's, for sale.
  - Derived from it: a container's owner (INT-042), a field's farmers (INT-007), a shopkeeper's post, who may use a station (all public now).
- **Tests:** `game/tests/run_tests.gd::test_property`, `game/tests/run_tests.gd::test_theft_and_shops`, `game/tests/run_tests.gd::test_animals`

### INT-052 · The land office: buying, leasing and selling land and houses
- **Trigger:** The player uses "Land and houses" with the reeve, a plot's build window, or an empty or held house's door.
- **Source:** `game/scripts/core/property.gd::buy`, `game/scripts/core/property.gd::lease`, `game/scripts/core/property.gd::sell`, `game/scripts/core/property.gd::end_lease`, `game/scripts/core/property.gd::for_sale`, `game/scripts/core/property.gd::market`, `game/scripts/core/property.gd::unit`, `game/scripts/core/property.gd::set_home`, `game/scripts/core/property.gd::_settle`, `game/scripts/ui/game_ui.gd::show_land`, `game/scripts/ui/game_ui.gd::show_deal`, `game/scripts/ui/game_ui.gd::show_build`, `game/scripts/main.gd::_find_target`
- **Affects:** Property, Coins, Treasury, Building, Player state, Interface
- **Expected:**
  - Only the manor sells and lets (owner rule). On the market: what is the manor's, let to nobody, lived in by nobody, with no building work going on. A parcel and the house on it change hands together.
  - Buying pays `price_of` (a plot `plot_price` by area, a house `house_price`) to the treasury; leasing pays the first week's rent (`weekly_rent_share` of the price) at once. Selling back is paid `sell_back_share` from the treasury, refused if it cannot pay, if let, or with an unfinished site. Every coin moves between purses and the treasury.
  - The player may hold several houses; the home is one of them (`set_home`). A first house becomes the home; giving up the home moves it to another held house (lowest id) or leaves the family homeless, the chest kept for the next house.
- **Tests:** `game/tests/run_tests.gd::test_property`, `game/tests/start_test.gd`

### INT-053 · Weekly rent, arrears and eviction
- **Trigger:** Each morning (06:00), for every lease due that day.
- **Source:** `game/scripts/core/property.gd::collect_rents`, `game/scripts/core/property.gd::_release`, `game/scripts/core/world.gd::_new_day`
- **Affects:** Property, Coins, Treasury, Player state, Households
- **Expected:** The rent plus any arrears goes from the tenant's purse (a household's: its members, richest first) to the treasury, and the next due day is a week on. A tenant who cannot pay it all pays nothing that week: the rent joins the arrears. After `rent_evict_missed` (2) unpaid weeks the manor takes the lease back, with any building the tenant put on the ground, and the arrears are let go; giving up a lease pays the arrears the purse can. Rent-free lettings (the manor house, the tavern, stalls, pens) are never charged. No coin is made or lost.
- **Tests:** `game/tests/run_tests.gd::test_property`

### INT-054 · A household dies out: its house goes back to the manor
- **Trigger:** The last member of a household dies (`World.kill`); loading a save from before property with such a household.
- **Source:** `game/scripts/core/world.gd::kill`, `game/scripts/core/property.gd::household_ended`, `game/scripts/core/property.gd::settle_ended_households`, `game/scripts/core/construction.gd::employer_ended`
- **Affects:** Property, Households, Granary, Food, Containers, Ledger, Building
- **Expected:** Owner rule: what the household owned becomes the manor's and what it leased ends; a house it was building comes down (every load delivered goes to the manor's stores) and its hired help goes home; the stores in its pantry go to the manor's granary (escheat, counted in `escheat_items` and in the village's food days), so nothing is lost or made. The house is then on the market (INT-052) and its crates are nobody's. The household is marked `ended` once.
- **Tests:** `game/tests/run_tests.gd::test_property`, `game/tests/run_tests.gd::test_property_migration`, `game/tests/start_test.gd`

### INT-055 · A vacant stall is let again
- **Trigger:** A merchant dies or changes work; each morning.
- **Source:** `game/scripts/core/npc_brain.gd::_give_up_stall`, `game/scripts/core/npc_brain.gd::_change_job`, `game/scripts/core/property.gd::relet_stalls`
- **Affects:** Property, Market, Employment, Containers
- **Expected:** The stall falls vacant at once (its goods are nobody's while it is). Each morning the manor lets each vacant stall, rent-free for now, to the first villager by id who is out of work or a manor hand and holds `stall_min_coins`; they become its merchant and keep its kind (audit defect 2 fixed).
- **Tests:** `game/tests/run_tests.gd::test_property`

### INT-056 · Claiming new ground anywhere legal
- **Trigger:** A building placed by the player (INT-057) or a founding household (INT-060).
- **Source:** `game/scripts/core/property.gd::can_claim`, `game/scripts/core/property.gd::claim`, `game/scripts/core/property.gd::land_price`
- **Affects:** Property, Coins, Treasury, Building
- **Expected:** Owner rule: free placement on any clear spot not someone else's, bought or leased from the manor on the spot. A rectangle is legal when at least 3x3, inside the village with a one-tile margin, clear of buildings, surveyed parcels, fields, pens, stalls, stations, containers, the mine's seams, trees and the road, and walkable. A grown tree must be felled first; the stumps and saplings of felled trees do not stand in the way and are grubbed up for good when the ground is claimed (state "cleared": they never grow back there). A legal claim becomes a new manor parcel ("parcel<N>", never shown to the player) bought or leased at once; if that fails nothing is surveyed.
- **Tests:** `game/tests/run_tests.gd::test_property`, `game/tests/run_tests.gd::test_construction`

### INT-057 · Placing a building anywhere legal
- **Trigger:** The player chooses Build (Menu, or H), a kind, and a place for its footprint; or marks out a building on ground they hold.
- **Source:** `game/scripts/main.gd::begin_placement`, `game/scripts/main.gd::_placing_input`, `game/scripts/main.gd::_placing_step`, `game/scripts/main.gd::confirm_placement`, `game/scripts/view/placement_ghost.gd`, `game/scripts/ui/game_ui.gd::show_build_menu`, `game/scripts/ui/game_ui.gd::show_place_deal`, `game/scripts/core/construction.gd::can_place`, `game/scripts/core/construction.gd::may_build`, `game/scripts/core/construction.gd::place`
- **Affects:** Building, Property, Coins, Treasury, Interface, Resources
- **Expected:** Owner rules: free placement anywhere legal, the ground bought or leased from the manor on the spot, a house first and then workshops. While placing, the game waits; the footprint follows the mouse, moves a tile at a time with keys, d-pad or stick, and goes where a finger taps; it is green with the ground's price and rent where it may go, red with the reason where it may not (the land office's check, INT-056; the house-first rule; a door step that is clear and reachable from the village). Placing opens the deal: buying or leasing the ground and marking out the site happen in one step (`Construction.place`), the price or first week's rent to the treasury. Cancel (Esc, B, the button) changes nothing.
- **Tests:** `game/tests/run_tests.gd::test_construction`, `game/tests/start_test.gd`

### INT-058 · Workshops: stations, leave and reservations
- **Trigger:** A workshop is finished, sold, leased or loaded; its holder gives or takes back leave; anyone looks for a station.
- **Source:** `game/scripts/core/world.gd::_workshop_stations`, `game/scripts/core/world.gd::may_use`, `game/scripts/core/world.gd::npc_may_use`, `game/scripts/core/world.gd::permit`, `game/scripts/core/world.gd::set_owner`, `game/scripts/core/npc_brain.gd::_station_for`, `game/scripts/ui/game_ui.gd::show_workshop`, `game/scripts/main.gd::_find_target`
- **Affects:** Workshops, Crafting, Property, Interiors, Interface
- **Expected:** Owner rule: workshops are buildings with stations, used by their owner or tenant, others only with permission. A smithy has a forge and an anvil, a carpenter's shop a workbench and a sawhorse, a bakehouse an oven and a stove, placed from its stamp (made again on every load, ids `ws_<building>_<type>`, after the village's own so villagers try those first). They change hands with the workshop. The holder (and their household) may use them; others only when the workshop's `allow` list names them, or "all" (the holder's "Let anyone work here" at its door). The player respects villagers' reservations at stations they do not hold (INT-021).
- **Tests:** `game/tests/run_tests.gd::test_construction`, `game/tests/start_test.gd`

### INT-059 · Hired helpers carry the employer's goods
- **Trigger:** The player hires a villager out of work or labouring ("Hire to carry building materials" in conversation); a founding household hires one each morning (INT-060).
- **Source:** `game/scripts/core/construction.gd::hire`, `game/scripts/core/construction.gd::can_hire`, `game/scripts/core/construction.gd::plan_helper`, `game/scripts/core/construction.gd::act`, `game/scripts/core/construction.gd::end_contract`, `game/scripts/core/construction.gd::on_death`, `game/scripts/core/npc_brain.gd::decide`, `game/scripts/core/npc_brain.gd::act`, `game/scripts/core/npc_brain.gd::pay_guards`, `game/scripts/ui/game_ui.gd::_helper_choices`
- **Affects:** Building, Coins, Market, Inventory, Wages, Employment, Households, Save
- **Expected:** Owner rule: helpers are hired for coin and carry the owner's goods; the owner keeps the building. The day's wage (`helper_wage`) goes from the employer's purse to the helper at once, all or nothing (none for a member of the employer's own household). In working hours the helper fetches one material at a time from the employer's store (the family chest at the player's home, a household's pantry) or buys it from a seller with the employer's coins, within the budget the employer set, walks it to the site and delivers it through `World.deliver`. What they carry is the employer's (`Construction.carried`, counted as goods held); at the end of the day, when the building stands, or if the helper dies, it goes back to the employer's store (a household that died out: the manor's stores). One contract per helper a day; hired after working hours, it is for the next day. Saved with what they carry.
- **Tests:** `game/tests/run_tests.gd::test_helpers`, `game/tests/start_test.gd`

### INT-060 · Crowded households split, get a home and move in
- **Trigger:** Each morning, a household with more living members than its house has beds (real beds, not straw pallets) and two grown members or more; a household without a home of its own.
- **Source:** `game/scripts/core/construction.gd::daily`, `game/scripts/core/construction.gd::crowded`, `game/scripts/core/construction.gd::founder_of`, `game/scripts/core/construction.gd::_found`, `game/scripts/core/construction.gd::couples_needing_home`, `game/scripts/core/construction.gd::_found_couple`, `game/scripts/core/construction.gd::_home_plan`, `game/scripts/core/construction.gd::_find_home`, `game/scripts/core/construction.gd::find_ground`, `game/scripts/core/construction.gd::_keep_building`, `game/scripts/core/construction.gd::on_finished`, `game/scripts/core/construction.gd::move_in`, `game/scripts/core/construction.gd::_rehouse`, `game/scripts/core/world.gd::home_spot`, `game/scripts/core/world.gd::_new_day`
- **Affects:** Households, Building, Property, Coins, Treasury, Market, Interiors, Save
- **Expected:** Owner rule: when a household is too big for its house (births crowd it: they need no free bed) and can afford it, a grown member founds a household: a grown son or daughter first, else an adult with no partner at home, never the reeve, the sage, a guard or a parent of young children at home; a founder's partner in the household leaves too, so partners are never split. Only when the family keeps `split_keep_base` + `split_keep_per_member` a member staying behind, after giving the founder what the new home costs; at most one split a day. The new household (same family, a new index appended to the list, `founded_from`) gets, by the property API only: an empty house on the market (bought, or leased with two weeks' rent in hand) and moves in at once; else the manor's surveyed ground (a clearing) or new legal ground as near home as can be found, bought, a house marked out and built by the player's rules, started with the ground and `found_start_share` of the materials' price in hand and finished as the household earns (hiring a helper each morning when it can pay for the rest, else the founder carrying with no wage when there is anything to buy or carry; otherwise its people work and save), then moves in (every member's home is the house). Until then the founder lodges with the family, on the house's next free sleeping place. Couples found households too (EQ-07): partners who live apart, or a grown child and partner in their parents' full house (never the reeve, the sage, a guard, or a parent of young children at home), with their own coins and what each family can spare above its keep, one founding a day; partners who live apart move in together instead when one home has a free bed. A household that loses its house lodges with the family it came from and looks for a home again. Coins and goods only move.
- **Tests:** `game/tests/run_tests.gd::test_households_split`, `game/tests/aging_test.gd::test_couples_found_households`, `game/tests/households_sim.gd`

### INT-061 · Places named for the player
- **Trigger:** The land office, a door, a building window, a placement, a village record line names land or a building.
- **Source:** `game/scripts/core/property.gd::describe`, `game/scripts/core/property.gd::building_name`, `game/scripts/core/world.gd::where`, `game/scripts/core/property.gd::can_claim`
- **Affects:** Property, Interface
- **Expected:** No internal id ("plot0", "parcel3", "b7") reaches the player. A building is named for the family who live there or hold it ("the Reed family's house", "the Ashdown family's smithy"), the family that died out ("the Ford family's old house"), or where it stands ("the empty house north of the well"); ground for where it lies, by the nearest landmark ("the clearing north of the Reed family's house", "the ground west of the tavern"); a site for its family and kind. A name two places share gets where the place lies added, never by a landmark of the same name.
- **Tests:** `game/tests/run_tests.gd::test_construction`, `game/tests/start_test.gd`

### INT-062 · Promised coins are set aside
- **Trigger:** The player accepts a quest with a reward or paid work; completes it; it lapses; its giver or the player dies; an older save loads.
- **Source:** `game/scripts/core/quests.gd::can_fund`, `game/scripts/core/quests.gd::_reserve`, `game/scripts/core/quests.gd::_release`, `game/scripts/core/quests.gd::accept`, `game/scripts/core/quests.gd::complete`, `game/scripts/core/quests.gd::drop_failed`, `game/scripts/core/quests.gd::on_giver_died`, `game/scripts/core/quests.gd::release_all`, `game/scripts/core/quests.gd::migrate_reserves`, `game/scripts/core/quests.gd::reserved_total`, `game/scripts/core/world.gd::kill`, `game/scripts/core/world.gd::continue_as_heir`, `game/scripts/core/world.gd::total_coins`, `game/scripts/core/player_state.gd::from_dict`
- **Affects:** Coins, Households, Treasury, Inheritance, Save, Interface
- **Expected:** (owner, 2026-10-18; B7-002)
  - A quest with a reward, or work with a wage, is offered only by a giver who can pay it in full (the manor: INT-063).
  - Accepting sets the promised sum aside from the giver's purse (`reserved` on the accepted quest); if the giver spent it since offering, the offer is withdrawn with a reason and nothing is accepted.
  - Completing pays exactly the reserved sum. A lapse, the giver's death (before what they leave passes on, INT-017) or the player's death (INT-018) returns it to the giver or the treasury.
  - Reserved coins are counted in `World.total_coins`; saving and loading keep them, neither doubled nor lost. A version 1-6 save sets them aside on load if the giver can pay; otherwise completing pays only once they can.
- **Tests:** `game/tests/run_tests.gd::test_build7_economy`, `game/tests/run_tests.gd::test_quests`, `game/tests/run_tests.gd::test_hiring`, `game/tests/start_test.gd`

### INT-063 · Work for the manor
- **Trigger:** Removed.
- **Source:** `game/scripts/core/quests.gd::drop_manor_quarry`
- **Affects:** Employment, Treasury
- **Expected:** Removed (2026-10-18, owner: the reeve offers a choice of real jobs): the single quarrying quest is superseded by the manor's job board (INT-066). A version 7 save's accepted one is dropped and its wage returned to the treasury.
- **Tests:** `game/tests/run_tests.gd::test_manor_work`

### INT-064 · Wheat cut for harvest work is the farmer's
- **Trigger:** Harvest work lapses (dawn).
- **Source:** `game/scripts/core/quests.gd::settle_harvest`, `game/scripts/core/quests.gd::drop_failed`, `game/scripts/core/quests.gd::hired_harvest`, `game/scripts/core/player_state.gd::mark_stolen`
- **Affects:** Crime, Inventory, Fields, Households
- **Expected:** (owner, 2026-10-18; B7-004) The wheat cut under the work (`harvested`) stays the farmer's. If the work lapses, what the player carries of it is marked stolen from the farmer (INT-045), then what lies in the home chest (INT-044); the farmer remembers catching the player keeping it, and a theft goes on the player's record. Handing the work in clears it as before (INT-046).
- **Tests:** `game/tests/run_tests.gd::test_build7_economy`

### INT-065 · Stone by caravan
- **Trigger:** A caravan passes while the village's own stone deposits are down to `caravan_import_when_left`.
- **Source:** `game/scripts/core/npc_brain.gd::caravan`, `game/scripts/core/npc_brain.gd::_caravan_stone`, `game/scripts/core/npc_brain.gd::_stone_scarce`, `game/data/balance.json`
- **Affects:** Market, Coins, Building, Resources, Ledger
- **Expected:** (owner, 2026-10-18; B7-007)
  - The caravan carries at most `caravan_stone.load` stone a visit from a quarry on its road, sold at value × `caravan_stone.markup` (cartage; provisional).
  - The raw-goods merchants, the village's stone sellers, buy it up to their stock cap while keeping the trader cash floor; the rest goes back with the cart. The coins leave the village (`coin_sources`, `imported_stone`, `caravan_stone_coins`).
  - It never buys the village's stone (or ore, or coal) at all (INT-020).
- **Tests:** `game/tests/run_tests.gd::test_build7_economy`

### INT-066 · The manor's work: real jobs for the player and villagers alike
- **Trigger:** The manor's evening business buys or gives goods; the reeve's list ("Any work for me?"); a villager seeks day labour, waits idle at work or is a manor hand; a worker does a step; dawn; a worker dies; saving and loading.
- **Source:** `game/scripts/core/manor_work.gd::consign`, `game/scripts/core/manor_work.gd::refresh`, `game/scripts/core/manor_work.gd::post_quarry`, `game/scripts/core/manor_work.gd::works_want`, `game/scripts/core/manor_work.gd::open_for`, `game/scripts/core/manor_work.gd::take`, `game/scripts/core/manor_work.gd::release`, `game/scripts/core/manor_work.gd::do_step`, `game/scripts/core/manor_work.gd::plan`, `game/scripts/core/manor_work.gd::seek`, `game/scripts/core/manor_work.gd::dawn`, `game/scripts/core/manor_work.gd::deliver_now`, `game/scripts/core/manor_work.gd::take_bound`, `game/scripts/core/manor_work.gd::goods`, `game/scripts/core/npc_brain.gd::reeve_day`, `game/scripts/core/npc_brain.gd::_relief`, `game/scripts/core/npc_brain.gd::_public_works`, `game/scripts/core/npc_brain.gd::_day_labour`, `game/scripts/core/npc_brain.gd::_idle_at_work`, `game/scripts/core/npc_brain.gd::decide`, `game/scripts/ui/game_ui.gd::show_manor_jobs`, `game/scripts/ui/game_ui.gd::_quest_items`, `game/scripts/main.gd::_find_target`, `game/scripts/main.gd::interact`, `game/scripts/core/world.gd::total_coins`, `game/data/balance.json`
- **Affects:** Employment, Treasury, Wages, Market, Granary, Relief, Building, Resources, Coins, Inventory, Households, Ledger, Save, Interface
- **Expected:** (owner, 2026-10-18: a choice of real jobs, NPCs by the same rules; the details are agent proposals, numbers provisional)
  - Jobs are made only by the manor's own business: what it buys for repairs, public works and the granary waits at the seller's as the manor's *lot* until carried (to the works yard or the granary); relief goes from the granary (or a seller) as a lot for a household's pantry; the works yard's materials are used up by "mend" jobs (`mend_load` at a works site, the well or the roads, `mend_minutes`); one "quarry" job (`quarry_qty` stone from the village's seams) while repairs are funded and the works lack stone. No work is posted for its own sake, and none is guaranteed.
  - Taking a job sets its wage aside from the treasury, only while the treasury keeps `manor_job_reserve_days` (3, the line the evening's repairs are bought above; B7-009, provisional) of obligations after it, so paid work exists from day 0 (the ten-day `treasury_reserve_days` stays for tax rates and hiring staff); it is paid when done (`gov_manor_jobs`). Manor hands are already paid: they take jobs unpaid. One job at a time per worker. Undone work is released at the next dawn after `days`: the wage back, the load back to its lot.
  - Carried goods ride in the job's load, never a pack; goods are only moved or used up (`used_repairs_`), coins only moved: the goods census and `World.total_coins` count lots, yard, loads and wages set aside. A household under 1 day of food gets its relief at once.
  - The player and villagers see the same open jobs, most needed first (relief, the granary, the yard, mending, quarrying). Villagers seek them as day labour, when their own trade is idle (before `latest_start`), and as manor hands; they do the same steps (collect, carry, quarry, mend). The player takes one from the reeve's list, the journal shows its next step, and "Use" at the place does it.
  - Saved as `manor_work` (save version 8); older saves load with nothing outstanding.
- **Tests:** `game/tests/run_tests.gd::test_manor_work`, `game/tests/run_tests.gd::test_manor_job_reserve`, `game/tests/run_tests.gd::test_government`, `game/tests/economy_sim.gd`

### INT-067 · The resource node registry describes every harvest and resource use
- **Trigger:** Anything that reads which resource node is at a cell, what is left, whether the player can harvest it, or where an item comes from and goes (Gather mode and the journal, once built); any change to a harvestable node, a harvested material, a recipe or a resource use.
- **Source:** `game/data/resources.json`, `game/scripts/core/resource_nodes.gd::node_at`, `game/scripts/core/resource_nodes.gd::can_harvest`, `game/scripts/core/resource_nodes.gd::remaining`, `game/scripts/core/resource_nodes.gd::uses_of`, `game/scripts/core/resource_nodes.gd::sources_of`, `game/scripts/core/resource_nodes.gd::chain`, `game/scripts/core/game_data.gd::ensure`, `tools/check_resources.py`
- **Affects:** Resources, Fields, Wildlife, Livestock, Inventory, Crafting, Building, Employment, Market, Crime, Property, Save
- **Expected:** (owner, 2026-10-18: one machine-readable definition for the Master Resource Node Manifest and the Resource Usage Registry)
  - `resources.json` (format `mml-resources/1`) defines each node kind: the seams (finite: `World.mine_unit`), trees (regrow: `World._new_day`), wheat fields (ripen; the crop is its farmers', taking it is theft unless hired), wild boar and rabbits (breed; hunted by attacking), and the pens' livestock (the keeper's: the player killing one is a crime). Its tools are items' tool types (the inventory and equipment's pickaxe and axe), its yields items; uses come from recipes (crafting), `NPCBrain.BUYS` and the caravan (trade and NPC decisions), building costs (construction), quests and the manor's jobs (employment), food and household firewood.
  - `ResourceNodes` only reads: it finds instances in the World's own records, so it is always what the save holds (no saved state of its own; nothing to migrate). It changes no gameplay: harvesting stays in World, main.gd and NPCBrain.
  - `tools/check_resources.py` fails when a deposit ore, species, the trees or the fields lack a node, an item named anywhere is undefined, a source ref is missing, a code-defined note no longer matches its code, a finding is unrecorded or an exception stale, or the generated `docs/systems/RESOURCE_NODE_MANIFEST.md` and `RESOURCE_USAGE_REGISTRY.md` are out of date.
- **Tests:** `game/tests/run_tests.gd::test_resource_registry`, `tests/test_resources.py`

### INT-068 · Gather mode and tapping resources
- **Trigger:** The Gather button (or G, or the pad's D-pad down); a tap or click on a seam, a tree (trunk or canopy), a field or wild game; Use in front of a resource in Gather mode; each frame while gathering.
- **Source:** `game/scripts/main.gd::gather_button`, `game/scripts/main.gd::_resource_tap`, `game/scripts/main.gd::select_resource`, `game/scripts/main.gd::_gather_step`, `game/scripts/main.gd::stop_gather`, `game/scripts/ui/game_ui.gd::gain`, `game/scripts/main.gd::_sync_gather_mark`, `game/scripts/main.gd::_tap`, `game/scripts/main.gd::interact`, `game/scripts/main.gd::_use`, `game/scripts/main.gd::_find_target`, `game/scripts/core/resource_nodes.gd::node_at`, `game/scripts/core/resource_nodes.gd::can_harvest`, `game/scripts/core/resource_nodes.gd::theft_note`, `game/scripts/ui/game_ui.gd::set_gather_mode`
- **Affects:** Resources, Inventory, Crime, Fields, Wildlife, Combat, Interface
- **Expected:** (owner, 2026-10-18: B7-011, B7-012)
  - What can be gathered is only what `resources.json` defines (INT-067), found by `ResourceNodes.node_at` at the tapped cell exactly (a tree also by its canopy cell); decorative objects are never gathered.
  - Gather mode toggles with its button; it and Attack exclude each other. A tap chooses a resource: it is outlined, the player walks to it and gathers it a cycle at a time through the same action as Use (the same time, tool and tool wear, yield, skill bonus, depletion, inventory and theft rules; no stamina, as before), until it runs out, the pack is full, the tool is gone, the player is hurt, or the player moves, chooses another or turns Gather off. A run-out resource stops gathering; Gather stays on; nothing else is chosen automatically.
  - A refusal is said, never silent: the missing tool and where to get it (`tool_hint`), worked out, not ripe, the keeper's animals, out of reach ("You can't reach it from here"). Someone's field warns once ("… taking it is theft. Tap it again …"); taken anyway, each handful is theft as by hand; hired harvest work is not warned.
  - Outside Gather mode a tap on a seam, tree or field walks there and uses it once. Resource prompts wait until the player stops instead of flashing while they walk past, and say when a tool is missing.
  - Wild game chosen in Gather mode is hunted with the weapon (the chase and strike of attack mode) until it falls.
  - Nothing of it is saved.
- **Tests:** `game/tests/start_test.gd`

### INT-069 · The journal's Resources & Gathering page reads the resource registry
- **Trigger:** The journal's Resources button (from the journal, reached by B, the pause menu or the pack's Journal tab); a node's Uses button; a product in its chain.
- **Source:** `game/scripts/ui/game_ui.gd::show_resources`, `game/scripts/ui/game_ui.gd::_res_facts`, `game/scripts/ui/game_ui.gd::_res_use_text`, `game/scripts/ui/game_ui.gd::_res_chain`, `game/scripts/ui/game_ui.gd::_res_plain`, `game/scripts/ui/game_ui.gd::show_journal`, `game/scripts/core/resource_nodes.gd::products`, `game/scripts/core/resource_nodes.gd::uses_of`, `game/scripts/core/resource_nodes.gd::sources_of`, `game/scripts/core/resource_nodes.gd::chain`, `game/scripts/core/player_state.gd::tool_of`, `tools/check_resources.py`
- **Affects:** Resources, Inventory, Crafting, Building, Market, Crime, Interface
- **Expected:** (owner, 2026-10-18: B7-012's journal page)
  - The page is built only from `resources.json` through `ResourceNodes` (INT-067): every node with `player_harvest` (no discovery gating), with its name and icon, `where`, tool and skill, `tool_hint` when the player carries no such tool (`PlayerState.tool_of`), products, depletion and regeneration, owner and theft; nodes without `player_harvest` (the keepers' animals) under "Not yours to gather". Developer notes in the registry's texts (code names in brackets) are left out and balance keys shown as their numbers.
  - A node's page lists each product's uses (`ResourceNodes.uses_of`) and what it becomes (`ResourceNodes.chain`); a product in the chain opens its own uses and sources, with Back.
  - The Gather mode steps describe INT-068 as implemented. The page changes nothing and is not saved; the journal's village record and quests pages are unchanged but for the Resources button.
  - `tools/check_resources.py` fails if the page's functions stop reading `ResourceNodes` or name a node id, node name, product or icon from `resources.json` in a string.
- **Tests:** `game/tests/start_test.gd`, `tests/test_resources.py`

### INT-070 · Wild flowers and berry bushes are walkable and gatherable
- **Trigger:** The player walks over, taps, or uses (or, in Gather mode, gathers) a ripe flower or berry bush; the dawn after it was picked; building ground is claimed over one.
- **Source:** `tools/build_village.py`, `game/scripts/core/world.gd::plant_at`, `game/scripts/core/world.gd::pick_plant`, `game/scripts/core/world.gd::_new_day`, `game/scripts/core/world.gd::to_dict`, `game/scripts/core/world.gd::load_dict`, `game/scripts/core/world.gd::player_eat`, `game/scripts/core/property.gd::claim`, `game/scripts/core/resource_nodes.gd::node_at`, `game/scripts/main.gd::_use`, `game/scripts/main.gd::_find_target`, `game/scripts/main.gd::_gather_step`, `game/scripts/main.gd::_apply_world_changes`
- **Affects:** Resources, Inventory, Crafting, Building, Save, Interface
- **Expected:** (owner, 2026-10-18: B8-015, B8-016; numbers provisional)
  - Village generator v5: a cell whose only object is a flower (paid-atlas tiles 2657, 2658) or a berry bush (2660 red, 2662 blue), with nothing above it, is walkable and is exported in village.json `plants`; the cells on the buyable plots are cleared. Walls, roofs and every other object stay solid.
  - `resources.json` defines three nodes (`flower_patch`, `red_berry_bush`, `blue_berry_bush`, kind `plant`, no tool, no theft, villagers do not pick them). A tap, Use or Gather mode picks a ripe plant in 1.2 s (ResourceNodes, INT-067 and INT-068): the pack gets its yield (1 flower, 2 berries; a full pack refuses) and the plant tile goes (`tile_changed`, layer below1). The cell stays walkable.
  - At the dawn `plant_regrow_days` (balance.json, 2 to 4, provisional) later the plant is ripe again and its tile returns. A plant on ground the player claims is grubbed up and never returns (as stumps, INT-040).
  - Berries are food (eaten through the usual Eat action); three flowers are brewed into a herbal tonic at the stove (cooking 1), which restores `heal` health when eaten. No villager recipe or buyer uses them.
  - Plants are saved (`plants`: state and regrow day by id, save version 9); a save without them loads with every plant ripe.
- **Tests:** `game/tests/run_tests.gd::test_wild_plants`, `game/tests/start_test.gd`, `tests/test_resources.py`

### INT-071 · The overworld surrounds the village: movement, collision, felling and saves
- **Trigger:** The player walks, taps a goal, or fires a spell outside the village (or across its edge); fells an overworld tree; a day starts; the game saves or loads.
- **Source:** `game/scripts/core/overworld.gd::is_solid`, `game/scripts/core/overworld.gd::get_chunk`, `game/scripts/core/overworld.gd::tree_at`, `game/scripts/core/village_map.gd::is_solid_world`, `game/scripts/core/village_map.gd::find_path_world`, `game/scripts/core/village_map.gd::exits`, `game/scripts/core/world.gd::tree_at`, `game/scripts/core/world.gd::fell`, `game/scripts/core/world.gd::sync_tree`, `game/scripts/core/world.gd::to_dict`, `game/scripts/core/world.gd::load_dict`, `game/scripts/view/overworld_view.gd::follow`, `game/scripts/main.gd::_try_move`, `game/scripts/main.gd::_route_step`, `game/scripts/main.gd::_on_tile_changed`
- **Affects:** Overworld, Resources, Save, Interface
- **Expected:** (owner, 2026-10-18: B8-011; layout and numbers are agent proposals)
  - The village keeps its map and coordinates, (0,0) to (119,89). Outside it the world is the Overworld: a pure function of the world seed (integer hash and value noise), cut into 32-tile chunks made on demand, cached (at most `MAX_CACHED`, least recently used evicted) and identical every time, on every platform.
  - Collision outside the village is the overworld's: `VillageMap.is_solid_world` (the player's feet in `_try_move`, tap routes, spells) asks the village map inside the village and the overworld outside. `VillageMap.is_solid` is unchanged: to villagers, their path-finding, fauna and building placement the map still ends at its edge, so no villager leaves the village. A tap outside the village routes with a bounded A* over `is_solid_world` (`find_path_world`), or walks straight and slides when the goal is too far.
  - Cliffs (mountains), tree trunks and boulders are solid. Trees and boulders are never within a cell of each other or of a cliff; a road and the cells round it never hold a cliff, tree or boulder; mountains are cut by passes. So every open cell stays connected to the village's exits (tested).
  - The village's four exits (the road cell nearest each map edge and a grass trail to the edge, drawn as dirt path by Main) join the global road network; roads are one network of segments between jittered nodes, so a chunk's roads agree with its neighbours' (no seams).
  - The view draws the chunks within `overworld_chunk_radius` (balance.json) of the camera and frees those beyond one more, a few per frame; nothing is generated for chunks already loaded. The camera has no limits.
  - An overworld tree is a lifecycle tree like a village tree (INT-074): mature ones fell with the axe for 4 logs. A tree the player changes (felled, growing, planted) is recorded in `Overworld.changes` and saved (`overworld`: seed, generator version, changes with species, stage clock and planted flag); the terrain never is. A felled tree regrows through the stages by the game clock and, once mature, is the generated world again. A save from another generator version keeps the seed and drops the changes.
- **Tests:** `game/tests/overworld_test.gd`, `game/tests/start_test.gd`, `game/tests/run_tests.gd::test_save_round_trip`

### INT-072 · A guard provisions the household while the shops are open
- **Trigger:** A guard decides what to do between 07:00 and 18:00, on or off duty, and the household's pantry has no firewood or holds fewer food units than it has members.
- **Source:** `game/scripts/core/npc_brain.gd::_plan_provision`, `game/scripts/core/npc_brain.gd::_guard`, `game/scripts/core/npc_brain.gd::_plan_evening`
- **Affects:** Food, Households, Market, Coins
- **Expected:** (agent decision under the owner's authorization of 2026-10-18, B7-015; provisional)
  - The household shopping that used to be only the evening's (`_plan_evening`: firewood first, then grain from a farmer or food merchant, else cooked food) is one function, `_plan_provision`, which a guard also calls on the rounds or off duty while the shops are open. A guard's duty and bed left no evening, so guards' households stayed empty and 79 of 87 early missed meals were guards waking hungry at night while farmers held weeks of grain.
  - Same purchase rules as before (`buy_from`/`buy_food` through `World.trade`, atomic, the seller's price, the buyer needs 3 to 4 coins); nothing is made or lost. A stocked household sends no one.
- **Tests:** `game/tests/run_tests.gd::test_long_run_economy`

### INT-073 · The smith's tools are retailed by the goods merchant, and a woodcutter sells firewood
- **Trigger:** A smith has spare tools; a villager needs a tool; a household needs firewood and no trader has logs.
- **Source:** `game/scripts/core/npc_brain.gd::_smith`, `game/scripts/core/npc_brain.gd::_get_tool`, `game/scripts/core/npc_brain.gd::_seller_of`
- **Affects:** Market, Coins, Crafting, Households
- **Expected:** (agent decision under the owner's authorization of 2026-10-18, B7-016; provisional)
  - A smith with more than one pickaxe, axe or sword takes the spare to the goods merchant (a buyer within its stock cap, `NPCBrain.BUYS`, and its cash floor) before forging more; the goods merchant therefore has stock to retail and to sell on to the caravan (INT-020). Before, the smith kept its tools (`> 3` while forging stopped at 3), so the goods merchant's only supply was leather and it ended the year with no coin.
  - A villager without a tool buys it from the goods merchant first, else from the smith (`World.trade`, the seller's price).
  - A household that needs firewood buys it from a carpenter or raw-goods merchant with logs, else from a woodcutter carrying some (never any other item).
  - Nothing is made or lost; coins only move between purses.
- **Tests:** `game/tests/run_tests.gd::test_long_run_economy`

### INT-074 · Every tree is a lifecycle tree: growth by the clock, felling, saplings and planting
- **Trigger:** Game time passes; the player or a villager fells a tree; the player plants a sapling; the player walks near or away from a tree.
- **Source:** `game/scripts/core/trees.gd::sync`, `game/scripts/core/world.gd::chop_tree`, `game/scripts/core/world.gd::fell`, `game/scripts/core/world.gd::plant_tree`, `game/scripts/core/world.gd::sync_tree`, `game/scripts/core/overworld.gd::base_tree`, `game/scripts/view/tree_view.gd::update`
- **Affects:** Resources, Inventory, Save, Overworld, Property, Interface, Employment
- **Expected:** (agent decision under the owner's tree lifecycle approval of 2026-10-18; every number provisional, balance.json `tree_growth`)
  - Every tree, in the village, at its edge and across the overworld, is one model: species (oak or pine, summer, autumn or snow) and a stage sapling, young, growing, mature, by game minutes since it began to grow. Growth is lazy: `Trees.sync` brings a tree up to the clock when it is looked at, hourly for the few not full grown, and untouched overworld trees keep no record. The world starts with trees of every stage, in patches of one species, none on a road or exit.
  - Only a mature tree can be felled: `World.chop_tree` takes `chops` blows (cut marks, chips and leaves show each), the last gives the log yield once (4, plus the Woodcutting bonus) and, for the player, a sapling; a hurt tree heals after `heal_minutes`. Younger trees, saplings and stumps say why they cannot be felled and give nothing. Villagers fell mature village trees only.
  - A felled tree is a stump (walkable) that sprouts `tree_regrow_days` later and grows through the stages again; ground bought for building clears its trees for good. Saplings and young trees are not solid, a growing or mature tree's trunk cell is; a young tree waits to become solid while someone stands on its cell, and the player can always walk out of a trunk that grew under them.
  - The player plants a sapling from the pack on free grass in front of them, never on a road, exit, door, field, plot, building, station or beside another tree.
  - Saved with the world: village trees whole, the overworld's changed trees (felled, growing, planted) with species, stage clock and planted flag; chunks that unload and load again redraw the same trees.
- **Tests:** `game/tests/run_tests.gd::test_tree_canopy`, `game/tests/overworld_test.gd::_run_scene`, `game/tests/start_test.gd::_gather_tests`

### INT-075 · An essential trade is handed on after its worker dies: apprentice, then newcomer
- **Trigger:** A smith, carpenter, tanner, cook, tavernkeeper or merchant dies or retires (or the last farmer, woodcutter or miner); a day starts; the caravan comes.
- **Source:** `game/scripts/core/npc_brain.gd::on_death`, `game/scripts/core/npc_brain.gd::_open_vacancy`, `game/scripts/core/npc_brain.gd::succession_dawn`, `game/scripts/core/npc_brain.gd::succession_caravan`, `game/scripts/core/npc_brain.gd::_apprentice_for`, `game/scripts/core/npc_brain.gd::_newcomer_for`, `game/scripts/core/npc_brain.gd::_install`, `game/scripts/core/npc_brain.gd::_change_job`, `game/scripts/core/npc_brain.gd::caravan`, `game/scripts/core/world.gd::to_dict`, `game/scripts/core/world.gd::load_dict`, `game/scripts/main.gd::_sync_sprites`
- **Affects:** Employment, Households, Inheritance, Coins, Market, Crafting, Save, Property
- **Expected:** (owner decision 2026-10-19: "Apprentice, then newcomer"; the numbers are agent proposals, provisional, balance.json `succession_days`, `newcomer_max_days`, `newcomer_coins`)
  - A death or a retirement (INT-078) in an essential trade records an open post (`World.vacancies`: job, workstation or stall, home, household, day), unless the trade is still at its starting strength without the leaver (a retiring worker is still counted as an adult in the trade when the post is checked, so they are left out of the count: Build 13 fix) (smith 2, carpenter 2, tanner 2, cook 3, tavernkeeper 2, merchant 6; one farmer, woodcutter and miner at least) or a post is already open for every missing hand. Death stays permanent: nobody is resurrected.
  - After `succession_days` an adult without a trade (no job, a labourer or a manor hand; the dead worker's household first, then the lowest id; a merchant needs the stall's stock coins) is taken on as an apprentice: the job, the workstation (`NPC.workplace`: the forge, sawhorse, workbench, stove, counter or stall) and the trade's tool. They keep their own home.
  - With no such adult the post waits for the caravan (`NPCBrain.caravan` calls `succession_caravan`), and at the latest `newcomer_max_days` after the death a newcomer arrives anyway. The newcomer takes the post and workstation, and a home: a lodger in the dead worker's household if it lives, else the old house leased from the manor, else any other empty house, else a room with the smallest household. Their purse (`newcomer_coins`) is new money from outside, counted in `World.coin_sources`, so coins stay conserved; the house lease moves coins to the treasury like any other.
  - The post is dropped if the trade is back at strength meanwhile (a stall let again by the manor). Open posts are saved (`vacancies`; older saves have none).
- **Tests:** `game/tests/world_test.gd::_succession`, `game/tests/aging_test.gd::test_coming_of_age_and_retiring`

### INT-076 · A deposit is what its sprite shows, and a small grey boulder is a pickaxe node for stone
- **Trigger:** The map loads; the player looks at, mines or leaves a rock; the game saves or loads; a chunk outside the village loads or unloads.
- **Source:** `game/data/resources.json`, `game/scripts/core/village_map.gd::normalise_rocks`, `game/scripts/core/village_map.gd::decor_boulders`, `game/scripts/core/resource_nodes.gd::def_for_deposit`, `game/scripts/core/world.gd::deposit_at`, `game/scripts/core/world.gd::mine_unit`, `game/scripts/core/world.gd::sync_boulders`, `game/scripts/core/overworld.gd::boulder_at`, `game/scripts/core/overworld.gd::note_rock`, `game/scripts/core/overworld.gd::to_dict`, `game/scripts/view/overworld_view.gd::_build`, `game/scripts/main.gd::_apply_world_changes`
- **Affects:** Resources, Overworld, Save, Interface, Market
- **Expected:** (owner Build 8 playtest, B8-008 and B8-026)
  - `resources.json` `deposit_tiles` gives each ore its own flecked tile and stone the plain grey boulder; `VillageMap.normalise_rocks` applies it at load: every seam is drawn with its ore's tile, a flecked rock with no seam behind it is drawn as a plain boulder, a worked-out seam has a hollow tile. So an ore-bearing sprite is always a seam of that ore: the prompt, the name and the yield come from the seam's record.
  - A standalone grey boulder (a solid cell holding the boulder tile in the village, or a solid rock of the overworld generator) is the `boulder` node: stone, `uses_small` (2) pickaxe swings for a small one or `uses` (6) for a large one (`ResourceNodes.boulder_uses`, PL1-06), then the sprite is erased and the cell opens. Cliffs and terrain rocks stay obstacles. It is found by `World.deposit_at` like a seam, but is not in `World.deposits`, so the miners, the economy ledgers and the caravan's stone rule see the seams only.
  - The village's boulders are saved with the world (`boulders`); the overworld's in `Overworld.rock_changes` (`overworld.rocks`), so a broken boulder stays broken across chunk reloads and saves.
  - (Build 13) The mine has one gold seam (village generator v7, 8 units), the `gold_seam` node: `ResourceNodes.can_harvest` refuses it below Mining 3 ("Gold needs Mining level 3."), so the prompt, Gather mode and Use agree. Villager miners work it only when the seams their buyers want are worked out; the smith and the goods merchant buy gold ore. A save made before the seam existed gains it, full, on load (`World.load_dict` adds any map seam missing from the saved list); saved seams keep their amounts.
- **Tests:** `game/tests/world_test.gd::_deposits`, `game/tests/world_test.gd::_gold`, `game/tests/world_test.gd::_boulders`, `tools/check_resources.py`

### INT-077 · The calendar sets ages, stages and the clock
- **Trigger:** The world clock advances; a villager, the player or an animal is asked its age; the HUD shows the time.
- **Source:** `game/scripts/core/life.gd::age_years`, `game/scripts/core/life.gd::season`, `game/scripts/core/life.gd::clock_text`, `game/scripts/core/life.gd::stage_of`, `game/scripts/core/world.gd::clock_text`, `game/scripts/core/animal.gd::stage`
- **Affects:** Calendar, Family, Livestock, Wildlife, Interface, Save
- **Expected:** (owner-approved 2026-10-19, B8-029) A year is `calendar.year_days` (8) game days, in the seasons of `calendar.seasons` / `season_days`; the clock reads "Spring, Year 1  Day 3  07:00". Age in years is `(now - born) / year`; an animal's stage is its age in days against `juvenile_days`, `grow_days`, `elder_days`. Both are pure functions of `born` and the clock, so a reload and the areas the player is not near stay consistent; only `born` is saved.
- **Tests:** `game/tests/aging_test.gd::test_calendar`, `game/tests/aging_test.gd::test_save_load`

### INT-078 · Ages set roles, jobs and how people look and walk
- **Trigger:** Each dawn and on loading a save: a villager has passed 12, 16 or 55.
- **Source:** `game/scripts/core/life.gd::sync_roles`, `game/scripts/core/life.gd::role_for`, `game/scripts/core/life.gd::npc_scale`, `game/scripts/core/life.gd::walk_factor`, `game/scripts/core/npc_brain.gd::_apprentice_for`, `game/scripts/core/world.gd::_new_day`, `game/scripts/main.gd::_sync_sprites`
- **Affects:** Family, Employment, Households, Interface
- **Expected:** `NPC.role` follows age: child (under 16; drawn at 0.5 until 12, 0.75 as an adolescent), adult (16-55), elder (55+, walk 0.8x). Adolescents hold no job and are nobody's apprentice. A child turning 16 is an adult without a trade, so the job market, apprenticeship and succession (INT-075) take them. An adult turning 55 retires: the post opens like a death's (INT-075; the retiree is not counted as staff, Build 13 fix), pens and stalls pass on, manor jobs are released. Bandits age but keep their role; the sage and the reeve keep their posts for life.
- **Tests:** `game/tests/aging_test.gd::test_coming_of_age_and_retiring`, `game/tests/start_test.gd::_child_size_tests`

### INT-079 · Partners and births join households
- **Trigger:** Each dawn.
- **Source:** `game/scripts/core/relations.gd::propose`, `game/scripts/core/life.gd::births`, `game/scripts/core/life.gd::birth`, `game/scripts/core/life.gd::partner_player`, `game/scripts/core/life.gd::seed_population`
- **Affects:** Family, Households, Building, Interiors, Food
- **Expected:** Households are not families: relationships are explicit links (`mother`, `father`, `partner`, `children`), recorded for the starting households by `seed_population` and never inferred from a shared house. Two unpartnered adults, 18-50, not kin, of either sex, become partners by courting (INT-148), one moving into the other's home if it has a free bed; without room they pair and live apart until a home has room or they found a household (INT-060). Births are only to partners of opposite sex: a woman of 18-42, `birth_min_food_days` of food, no child in the last year; no free bed is needed (owner, 2026-10-19), so a birth can crowd the house and start a split (INT-060); about one in `birth_interval_years` years of days. The newborn is a child of the mother's household, with a name, a sprite and both parents recorded. The player partners an adult whose proposal was accepted (INT-148, `partner_player`); their children are villagers of the partner's household.
- **Tests:** `game/tests/aging_test.gd::test_start_population`, `game/tests/aging_test.gd::test_partners_and_births`, `game/tests/aging_test.gd::test_couples_found_households`

### INT-080 · Old age kills, and the family inherits
- **Trigger:** Each dawn, a villager or the player is 60 or older.
- **Source:** `game/scripts/core/life.gd::death_chance`, `game/scripts/core/life.gd::_natural_deaths`, `game/scripts/core/life.gd::_player_dawn`, `game/scripts/core/life.gd::heir_of`, `game/scripts/core/life.gd::player_heir_child`, `game/scripts/core/life.gd::make_heir`, `game/scripts/core/world.gd::_heir`, `game/scripts/core/world.gd::continue_as_heir`
- **Affects:** Family, Health, Inheritance, Employment, Households, Player state, Character
- **Expected:** From 60 a daily chance rising to certain death at 80 (`life.mortality_*`); the cause is "old age" and the death runs the ordinary hooks (INT-017: inheritance, vacancy, pens, stalls, household ended). Heirs come from the family graph first: the eldest adult child, then the partner, then other kin (parents, then siblings), then a minor child; only with no family heir does the household order of INT-017 apply. The player's old-age death shows "You died of old age."; the heir is the player's eldest living child of 16+, who leaves the villagers and keeps name, sprite, age and sex; with none, a relative takes over (INT-018).
- **Tests:** `game/tests/aging_test.gd::test_old_age_and_inheritance`, `game/tests/aging_test.gd::test_player`

### INT-081 · Animals pass through life stages and die of old age
- **Trigger:** Each dawn; an animal is drawn or breeds.
- **Source:** `game/scripts/core/fauna.gd::_old_age`, `game/scripts/core/fauna.gd::new_day`, `game/scripts/core/fauna.gd::breed_chance`, `game/scripts/core/fauna.gd::_start`, `game/scripts/core/animal.gd::stage`, `game/scripts/view/animal_sprite.gd::show_state`
- **Affects:** Livestock, Wildlife, Interface
- **Expected:** newborn, juvenile, adult, elderly by age (`balance.json` animals: `juvenile_days`, `grow_days`, `elder_days`). Only adults breed (the existing rules kept), and the chance falls to nothing as the area nears its cap. The elderly move at 0.7x and, from `death_days[0]`, die of old age by a daily chance spread evenly to `death_days[1]`; meat and hide rules are unchanged. Newborns and juveniles draw the Cozy Farm baby sheet at full scale (the boar, with none, at half scale). The starting animals have varied ages.
- **Tests:** `game/tests/aging_test.gd::test_animals`, `game/tests/aging_test.gd::test_baby_art`

### INT-082 · The wiki is generated from game data, and Settings returns where it came from
- **Trigger:** The player opens Settings or the Wiki (title screen, pause menu), switches tabs, or presses X, Esc, the pad's B or Menu in any window.
- **Source:** `game/scripts/core/wiki.gd::build`, `game/scripts/core/wiki.gd::add_provider`, `game/scripts/core/wiki.gd::search`, `game/scripts/ui/wiki_window.gd::open`, `game/scripts/ui/wiki_window.gd::step_back`, `game/scripts/ui/game_ui.gd::show_settings`, `game/scripts/ui/game_ui.gd::go_back`, `game/scripts/ui/game_ui.gd::hide_all`, `game/scripts/main.gd::_unhandled_input`
- **Affects:** Interface, Save
- **Expected:** (PL1-01, PL1-02, PL2-009) Wiki pages are built at open time from `items.json`, `recipes.json`, `resources.json`, `skills.json`, `balance.json` (animals, calendar, life, theft, property), `village.json` stations, `Population.JOBS`, `NPCBrain.BUYS`/`KEEPS` and `GameUI.CONTROLS`, so a new item, recipe or node gets a page, links and search entries with no wiki edit; hand-written system pages state only what the code does and mechanics that are not built are marked "Not in the game yet". Other systems add pages with `Wiki.add_provider`. Settings is one screen with tabs (Audio, Display, Interface, Controls, Wiki); each window records where Back goes (`panel_back`): X, Esc and B step back inside the wiki first (`inner_back`), then to the screen the window came from (title or pause menu), else close it and restore pause state, HUD and input. The title, origin and death screens never close, so no input can leave a grey, paused world. Settings are saved on every change (`user://settings.cfg`).
- **Tests:** `game/tests/wiki_test.gd`

### INT-083 · Medicines heal, and the sage's apothecary stock moves between real inventories
- **Trigger:** The player uses a medicine from the pack; the sage brews; the caravan visits.
- **Source:** `game/scripts/core/world.gd::player_use_medicine`, `game/scripts/core/npc_brain.gd::_caravan_apothecary`, `game/scripts/core/npc_brain.gd::_do_recipe`, `game/scripts/core/game_data.gd::effects`
- **Affects:** Health, Inventory, Market, Coins, Crafting, Employment, Wages, Ledger
- **Expected:** Items of type `medicine` (`items.json`: linen bandage 15, herbal poultice 30, healing tonic 50, strong healing tonic 80 health) heal only, never feed, never pass the health cap and are consumed only when they heal (at full health nothing is used). The sage keeps the village apothecary: the starting stock is `balance.json` `sage_start_stock`; the sage buys wild flowers (`BUYS.sage`, kept, not resold), brews poultices and healing tonics from them at the stove (the recipes `brew_poultice`, `brew_healing_tonic`), and sells everything else through the ordinary trade window. The caravan resupplies on each visit up to `caravan_apothecary_per_visit` pieces towards `caravan_apothecary_stock`, at base value, paid from the sage's own coins above the trader cash floor; those coins leave the village (`coin_sources` falls, the caravan purse rises), so supply is finite. The stove also makes the player's own tonics (`brew_strong_tonic` needs two healing tonics and ale). Every medicine shows its effect ("Restores 15 Health") in shop rows, the quantity control and the pack (`GameData.effects` reads `heal` without `food`: Build 13 fix).
- **Tests:** `game/tests/health_jobs_test.gd::test_use`, `game/tests/health_jobs_test.gd::test_apothecary`, `game/tests/start_test.gd::_pl_trade_ui_tests`

### INT-084 · The employer's star
- **Trigger:** Every frame (view); the player accepts, completes or drops a job.
- **Source:** `game/scripts/core/quests.gd::employer`, `game/scripts/main.gd::_sync_stars`
- **Affects:** Employment, Interface, Save, Interiors
- **Expected:** A gold star hangs over each villager the player has taken a non-story job from (an accepted quest or a hired day's work, or the reeve while the player holds a manor job) and has not yet been paid by. It is keyed by the giver's NPC id in the player's saved quest list, so it follows the villager everywhere (over the door while they are under a roof) and survives save and load; it clears when `Quests.complete` pays out (or the job is dropped). Several open jobs from one giver keep it until the last is settled. Offers alone show the older quest markers, not the star.
- **Tests:** `game/tests/health_jobs_test.gd::test_star`

### INT-085 · A station is blocked only by a villager actually working at it
- **Trigger:** The player opens or works at a station; a villager plans a recipe or arrives at its station.
- **Source:** `game/scripts/core/world.gd::station_workers`, `game/scripts/core/world.gd::station_refusal`, `game/scripts/core/world.gd::_run_plan`, `game/scripts/core/world.gd::player_at_station`, `game/scripts/core/world.gd::release_player_station`, `game/scripts/main.gd::craft`, `game/scripts/main.gd::cancel_action`, `game/scripts/core/npc_brain.gd::_station_for`, `game/scripts/core/npc_brain.gd::release_station`
- **Affects:** Workshops, Employment, Interface
- **Expected:** A reservation (`users`) is made for the walk and the work, but the player is refused ("X is using the forge") only while that villager is alive, awake, not fighting, has the station's work as the current plan step and stands at its use cell. Someone on the way, asleep, fighting, dead or gone to another task does not block, and their reservation is cleared the next time the station is asked about. Reservations are never saved. (Build 13) The player working at a station (`World.reserve_for_player`) keeps villagers off it: none can claim it (`_station_for` counts the player), and one who reserved it earlier and arrives while the player works waits beside it, idle, never working it at the same time (`_run_plan`); a villager waiting there does not count as using it. After `station_wait_minutes` the villager gives the place up, releases its reservation and plans again. The player's place is freed the moment their work finishes or is cut short (`release_player_station`, from the action's end and `cancel_action`), not when the reserved time runs out.
- **Tests:** `game/tests/world_test.gd::_pl2_001`, `game/tests/world_test.gd::_station_conflict`, `game/tests/run_tests.gd::test_building_site`

### INT-086 · Hunted animals leave a pile that can be seen, tapped and taken, and that spoils
- **Trigger:** The player (or a hunter) kills an animal; the player taps or uses the pile; a dawn passes.
- **Source:** `game/scripts/main.gd::_hit_animal`, `game/scripts/main.gd::_loot_at`, `game/scripts/main.gd::_loot_icon`, `game/scripts/main.gd::_find_target`, `game/scripts/core/world.gd::_new_day`
- **Affects:** Wildlife, Loot, Inventory, Interface, Save
- **Expected:** Fauna.kill yields meat and (adults of kinds that have one) hide, never coins. The pile is drawn with its first item's icon, the prompt names its contents, a tap in any mode walks to it and takes it, and it can be taken from underfoot. A carcass spoils after `World.ANIMAL_LOOT_DAYS` (3) days; piles of the dead (people) stay. The pile's time `t` is saved. A hide is tanned to leather by the `tan_leather` recipe at the workbench.
- **Tests:** `game/tests/world_test.gd::_pl2_004`

### INT-087 · Wild flowers and boulders outside the village are real nodes
- **Trigger:** The player targets a flower or a boulder anywhere; a dawn passes; the game is saved.
- **Source:** `game/scripts/core/overworld.gd::flower_at`, `game/scripts/core/overworld.gd::boulder_at`, `game/scripts/core/world.gd::plant_at`, `game/scripts/core/world.gd::pick_plant`, `game/scripts/core/resource_nodes.gd::boulder_uses`
- **Affects:** Overworld, Inventory, Save, Interface
- **Expected:** Every generated flower decoration outside the village is a ripe `flower` plant until picked, bare until `plant_regrow_days` later (`Overworld.plant_changes`, saved, the sprite hidden and restored at dawn); the village's red (2656) and white (2659) flowers are registered plants like the purple and yellow. Every boulder drawn outside the village is minable (mountain boulders too). A boulder is small (2 uses, drawn smaller) or large (6 uses) from a hash of its cell, the uses left are saved as before.
- **Tests:** `game/tests/world_test.gd::_pl2_006`, `game/tests/world_test.gd::_boulders`

### INT-088 · Nothing is targeted across a wall
- **Trigger:** The player uses, taps, gathers, talks to or attacks something.
- **Source:** `game/scripts/core/world.gd::reaches`, `game/scripts/core/combat.gd::clear_line`, `game/scripts/main.gd::_find_target`, `game/scripts/main.gd::_use`, `game/scripts/main.gd::select_resource`
- **Affects:** Interiors, Interface, Combat
- **Expected:** `World.reaches(from, to)` is false across a building's boundary (inside to outside, either way, or building to building) unless one end stands in that building's doorway, and false through a building neither end is in. The target list, the use guard, Gather taps and attacks all ask it; indoor stations, furniture, containers and people still work. A sword blow also needs no solid map cell (wall, fence, tree, rock) between the player and the target (`Combat.clear_line`).
- **Tests:** `game/tests/world_test.gd::_pl2_011`, `game/tests/combat_test.gd::test_walls`

### INT-089 · A field ripens on game time and stands ripe before the farmers cut it
- **Trigger:** The game hour passes; a farmer decides.
- **Source:** `game/scripts/core/world.gd::_on_hour`, `game/scripts/core/world.gd::field_cuttable`, `game/scripts/core/world.gd::field_grow_days`, `game/scripts/core/npc_brain.gd::_farmer`
- **Affects:** Fields, Employment, Granary
- **Expected:** A sown field is ripe `field_grow_days` later; it then stands ripe for `field_ripe_wait_hours` (12) before the farmers cut it, so the player sees and can harvest ripe wheat (it used to be cut within the hour). Farmers then cut, till and sow again. `field_grow_days` is the hook for seasons.
- **Tests:** `game/tests/world_test.gd::_pl2_007`

### INT-090 · A room added to a property is a parcel of the same estate
- **Trigger:** The player (holder of a property whose first building stands) chooses a module kind and a place.
- **Source:** `game/scripts/core/construction.gd::place`, `game/scripts/core/construction.gd::module_refusal`, `game/scripts/core/construction.gd::attach_refusal`, `game/scripts/core/property.gd::estate_parcels`
- **Affects:** Building, Property, Coins
- **Expected:** The module's ground is claimed like any ground (bought or leased from the manor, coins to the treasury, land price by area) and its parcel carries `estate` = the first parcel's id. It must touch a building of the property along at least `ATTACH_MIN` cells, must not cover any door step of the property, and needs a clear, reachable door; the property must be the player's, its first building must stand and nothing on it may be unfinished; one room of each kind. Nothing already built is demolished, moved or changed.
- **Tests:** `game/tests/property_test.gd::test_modules`, `game/tests/property_test.gd::test_rules`

### INT-091 · A module's materials, rent and sale value follow the building rules
- **Trigger:** A module site is delivered to; a week passes; the property's rooms are sold or a lease is ended.
- **Source:** `game/scripts/core/world.gd::deliver`, `game/scripts/core/property.gd::price_of`, `game/scripts/core/property.gd::sell`, `game/scripts/core/property.gd::end_lease`, `game/data/balance.json`
- **Affects:** Building, Property, Coins, Treasury
- **Expected:** A module is a site with `workshop_cost` materials (counted as used when finished), delivered by the player or a hired helper as for any building. Its parcel has its own deal: bought, or leased at weekly_rent_share of `module_price` with its own rent; the house's own rent is unchanged. A module can be sold back on its own at the usual share; the first parcel cannot be sold or have its lease ended while rooms stand on the property.
- **Tests:** `game/tests/property_test.gd::test_modules`

### INT-092 · A module's stations, doors and roof work as any building's
- **Trigger:** A module is finished; the player or a villager walks, uses a station, or goes indoors.
- **Source:** `game/scripts/core/world.gd::_finish_site`, `game/scripts/core/world.gd::_workshop_stations`, `game/scripts/core/world.gd::_built_collision`, `game/scripts/core/world.gd::index_interiors`
- **Affects:** Building, Crafting, Interiors, Workshops
- **Expected:** A finished module is a building with its own stamp: solid walls, a doorway, its own inside and roof (the roof of the one the player is in fades), and the stations of its stamp (smithy: forge and anvil; carpentry: workbench and sawhorse; bakehouse: oven and stove; kitchen and apothecary: a stove). Its door step is reachable from the village by the map's A*, checked before it is placed. The stations are the building owner's, usable by anyone with leave.
- **Tests:** `game/tests/property_test.gd::test_modules`

### INT-093 · Living quarters and storerooms are rooms of the house
- **Trigger:** A household sleeps or is checked for crowding; the player is inside a storeroom or quarters.
- **Source:** `game/scripts/core/property.gd::rooms_of`, `game/scripts/core/construction.gd::beds_in`, `game/scripts/core/world.gd::home_spot`
- **Affects:** Households, Building, Interiors
- **Expected:** The beds of living quarters on the same property (held by the same party) count in `Construction.beds_in` for the house, so the household is crowded later, and `World.home_spot` gives members those beds. The family chest and beds can be used from a storeroom or quarters of the home as from the house.
- **Tests:** `game/tests/property_test.gd::test_modules`

### INT-094 · A property with its rooms is saved and loaded whole
- **Trigger:** The game is saved and loaded.
- **Source:** `game/scripts/core/world.gd::to_dict`, `game/scripts/core/world.gd::load_dict`, `game/scripts/core/property.gd::estate_id`
- **Affects:** Save, Building, Interiors
- **Expected:** Parcels (with `estate`), built rooms and sites save with the world; on load the buildings, collision, insides, roofs and stations are rebuilt and a module site goes on where it was. Saves from before estates have no `estate` field: each parcel is its own property. The save version is unchanged (14).
- **Tests:** `game/tests/property_test.gd::test_save`

### INT-095 · Villagers sleep lying on their beds
- **Trigger:** A villager is asleep (`anim` "sleep") on the use cell of their bed.
- **Source:** `game/scripts/main.gd::_show_sleeper`, `game/scripts/view/actor_sprite.gd::lie`
- **Affects:** Households, Interface
- **Expected:** The sleeper is drawn from the sheet's lying frame (the end of the fall: head toward the pillow, a quarter turn for a head-up bed), centred on the bed cell, above the bed's own tiles, under the bed's blanket; no furniture moves. Waking (`NPCBrain.decide`) draws them standing again. Schedules and paths are untouched: only the drawing changed.
- **Tests:** `game/tests/furniture_test.gd::_run`

### INT-096 · Villagers eat at home seated on their chair
- **Trigger:** A villager with food at home plans a meal (`NPCBrain._plan_eat`).
- **Source:** `game/scripts/core/npc_brain.gd::_home_meal`, `game/scripts/main.gd::_show_sitter`, `game/scripts/core/furniture.gd::with_chairs`
- **Affects:** Households, Food, Interface
- **Expected:** The household's chairs (stool tiles in the home, shared out by member order like beds) are spots of kind "chair". The meal walks to the chair's use cell and eats there for the same 15 minutes with anim "sit", drawn seated (legs cut at the knee, hips on the seat); the next decision stands them. A home without a chair eats standing at the table as before.
- **Tests:** `game/tests/furniture_test.gd::_run`

### INT-097 · The player sits on chairs and stands with any input
- **Trigger:** The player uses a chair (spot kind "chair") in their own home.
- **Source:** `game/scripts/main.gd::sit_down`, `game/scripts/main.gd::stand_up`, `game/scripts/core/furniture.gd::options`
- **Affects:** Interface, Player state
- **Expected:** The chair is an ordinary target (keyboard, mouse, pad and touch reach it). The player is drawn seated until a movement, a button, a stick, a key or a tap, then stands on the free cell beside the chair. Chairs of a house the player builds work the same (found by spot kind).
- **Tests:** `game/tests/furniture_test.gd::_run`

### INT-098 · The player sleeps in their own bed and wakes beside it
- **Trigger:** The player rests inside their own home (the bed, the chest) while a bed spot exists.
- **Source:** `game/scripts/main.gd::rest`, `game/scripts/main.gd::lie_down`, `game/scripts/main.gd::_rest_now`
- **Affects:** Player state, Interface, Save
- **Expected:** The player lies on the bed (drawn lying under the blanket) for a short sleeping action, then the night passes (full health and stamina, morning, saved) and they stand on the cell beside the bed; B, Esc or a tap wakes them early beside the bed with the time unchanged. Resting outside the house is the plain rest as before.
- **Tests:** `game/tests/furniture_test.gd::_run`

### INT-099 · A home's hearth is an oven and its table a food-preparation station
- **Trigger:** The player uses a hearth or table spot in their own home.
- **Source:** `game/scripts/core/furniture.gd::options`, `game/scripts/core/furniture.gd::home_refusal`, `game/scripts/core/world.gd::station_refusal`
- **Affects:** Crafting, Food, Inventory
- **Expected:** A hearth spot offers the "oven" station's recipes (roasting; never the forge's smelting), a table spot the "prep" station's (`knead_flatbread`: 3 wheat to a loaf, cold work); the same recipes.json rules and costs as every station. Only the home's household may use them; villagers' own stations are unchanged. New rooms and houses get both by spot kind.
- **Tests:** `game/tests/furniture_test.gd::_run`

### INT-100 · Chests, crates and barrels are storage with an owner
- **Trigger:** The player uses a chest, crate or barrel, and stores or takes goods.
- **Source:** `game/scripts/core/chests.gd::info`, `game/scripts/core/chests.gd::store`, `game/scripts/core/chests.gd::take`, `game/scripts/ui/chest_window.gd::show`
- **Affects:** Containers, Inventory, Households, Property, Crime, Interface
- **Expected:** Your family chest (and any container in a house you hold) is yours: store and take any quantity, no crime; a house you hold but do not live in keeps a saved stash. Another household's chest or crate is its pantry, the tavern's chest is the keeper's stock, the manor's are the reeve household's: you may not store in them, and taking is theft (marked stolen, witnessed, guards fine you). A chest in a building nobody holds is decorative and holds nothing. Goods only move.
- **Tests:** `game/tests/chests_test.gd::test_own_chest`, `game/tests/chests_test.gd::test_household_chest`, `game/tests/chests_test.gd::test_decor_and_business`, `game/tests/chests_test.gd::test_crates`

### INT-101 · Locks, padlocks and lockpicking use Stealth and lockpicks
- **Trigger:** The player fits a padlock to their own chest, or picks the lock of someone else's.
- **Source:** `game/scripts/core/chests.gd::lock_of`, `game/scripts/core/chests.gd::set_own_lock`, `game/scripts/core/chests.gd::pick_chance`, `game/scripts/core/chests.gd::attempt`, `game/scripts/main.gd::pick_lock`
- **Affects:** Containers, Player state, Inventory
- **Expected:** Owners lock some chests (households about a third, the tavern and the manor always); a locked chest refuses taking. A pick needs a lockpick and takes game time per lock level; the chance rises with Stealth and falls with the lock level; a failure may snap the pick; success opens the lock until the next dawn and gives Stealth experience. Your own padlock (used up once) is opened with your key for free.
- **Tests:** `game/tests/chests_test.gd::test_locked_refuses`, `game/tests/chests_test.gd::test_own_lock`, `game/tests/chests_test.gd::test_lockpick`

### INT-102 · A seen lockpicking is a crime
- **Trigger:** The player tries to pick a lock with someone in the same room.
- **Source:** `game/scripts/core/chests.gd::attempt`, `game/scripts/core/world.gd::witness`, `game/scripts/core/world.gd::guard_confront`
- **Affects:** Crime, Households, Coins, Treasury
- **Expected:** Each attempt is recorded in the player's crimes; people in the room see it (a quiet success only within half the witness radius, a failure or a snapped pick at the full radius) and remember it; a guard who sees it fines the player `theft_fine` coins to the treasury. Taking from the opened chest is theft as for any container.
- **Tests:** `game/tests/chests_test.gd::test_witnessed`

### INT-103 · The smith forges lockpicks and padlocks from iron bars
- **Trigger:** The smith's forge routine finds lockpicks or padlocks scarce; the player forges them at an anvil.
- **Source:** `game/scripts/core/npc_brain.gd::_smith`, `game/data/recipes.json`
- **Affects:** Crafting, Market, Inventory, Resources
- **Expected:** `forge_lockpicks` (1 iron bar for 3 lockpicks) and `forge_padlock` (2 bars for 1 padlock, Smithing 2) are anvil recipes; the smith keeps a few in stock, which the player buys at the smith's usual prices. Iron bars are the only input, so nothing appears from nowhere.
- **Tests:** `game/tests/chests_test.gd::test_items`

### INT-104 · Locks and stashes are saved
- **Trigger:** The game is saved and loaded.
- **Source:** `game/scripts/core/chests.gd::to_dict`, `game/scripts/core/chests.gd::load_dict`, `game/scripts/core/world.gd::to_dict`
- **Affects:** Save, Containers, Inventory
- **Expected:** Lock levels and states, a lock picked today, and the stashes in held houses are saved under `chests`; the family chest is part of the player's save as before. A save without `chests` loads with the default locks and no stashes, so no save version bump.
- **Tests:** `game/tests/chests_test.gd::test_save_load`

### INT-105 · Skill levels follow one slower curve, and saved xp keeps its meaning
- **Trigger:** The player earns xp (mining, chopping, crafting, trading, fighting, casting, stealing), is taught a skill, or loads a save.
- **Source:** `game/scripts/core/skills.gd::level_of`, `game/scripts/core/skills.gd::xp_for_level`, `game/scripts/core/skills.gd::trade_xp`, `game/scripts/core/player_state.gd::level`, `game/scripts/core/player_state.gd::raise_to`, `game/scripts/main.gd::_xp`
- **Affects:** Player state, Save
- **Expected:** (PL2-005) Levels 1 to 10 from the curve in `skills.json` (step_base x L x (1 + step_growth x (L - 1)): 100, 250, 450, 700 ... xp a level); the saved `skills` dictionary still holds raw xp under the same keys, so an old save keeps every point and only the level it works out to follows the new curve (500 mining xp stays level 3, 1000 is now level 4). A quest's lesson raises to the start of the level on this curve and prints that tier's text.
- **Tests:** `game/tests/skills_test.gd::test_curve`, `game/tests/skills_test.gd::test_saves`, `game/tests/run_tests.gd::test_skill_quest`

### INT-106 · Gathering skills change yield, speed and tool wear
- **Trigger:** The player mines a seam, fells a tree, or the tier is reached.
- **Source:** `game/scripts/main.gd::interact`, `game/scripts/main.gd::_chop`, `game/scripts/core/world.gd::sapling_drop`, `game/scripts/core/skills.gd::value`
- **Affects:** Resources, Inventory, Player state
- **Expected:** (PL2-005) Mining tiers give a chance of a second ore a swing, gold at level 3, shorter swings and a chance a swing does not wear the pickaxe; Woodcutting tiers give extra logs a tree, shorter chopping, a chance a blow does not wear the axe, and a chance of a second sapling. The values come from `skills.json` tier effects through `Skills.value`; nothing is hard-coded to a level in the code.
- **Tests:** `game/tests/skills_test.gd::test_outcomes`, `game/tests/skills_test.gd::test_effects_are_wired`

### INT-107 · Crafting skills speed the work and stretch the materials
- **Trigger:** The player finishes a recipe at a station.
- **Source:** `game/scripts/main.gd::craft`, `game/scripts/core/skills.gd::is_gear`, `game/scripts/core/skills.gd::recipes_at`
- **Affects:** Crafting, Inventory, Workshops
- **Expected:** (PL2-005) A recipe's own skill (Smithing, Crafting, Cooking) sets how long the player's work takes (`craft_time`), the chance the materials come back unused (`save_chance`), and the chance of one extra unit of a product that is not gear (`bonus_chance`). Recipes still unlock at their own `skill` and `level` in `recipes.json`; the skills window and the wiki list them under that level. Villagers' crafting is unchanged.
- **Tests:** `game/tests/skills_test.gd::test_outcomes`, `game/tests/skills_test.gd::test_text_and_wiki`

### INT-108 · Combat, magic and trading skills change fights, spells and prices
- **Trigger:** The player strikes, casts Fireball, is hurt, buys or sells.
- **Source:** `game/scripts/core/player_state.gd::damage`, `game/scripts/main.gd::_strike`, `game/scripts/main.gd::attack`, `game/scripts/main.gd::fireball`, `game/scripts/core/world.gd::damage_player`, `game/scripts/core/world.gd::player_price_factor`
- **Affects:** Combat, Health, Market, Coins
- **Expected:** (PL2-005) Combat tiers raise blow damage, shorten the swing delay, give a chance of a double blow and cut damage taken (not hunger); Magic tiers shorten the Fireball cooldown, cut its stamina cost and raise its damage; Trading tiers move the player's buy and sell prices up to 20% (coins still move between real holders, so the supply is unchanged). Trade xp grows with the coins in the deal.
- **Tests:** `game/tests/skills_test.gd::test_outcomes`, `game/tests/skills_test.gd::test_early_play`

### INT-109 · Stealth makes a pickpocket likelier and a caught one quieter
- **Trigger:** The player tries a pocket.
- **Source:** `game/scripts/core/world.gd::pickpocket`, `game/scripts/core/world.gd::pickpocket_chance`
- **Affects:** Crime, Player state
- **Expected:** (PL2-005) The chance is `pickpocket_chance` plus `pickpocket_chance_per_level` times the tier's `pickpocket_steps`, never above `pickpocket_chance_max` (a sleeper's bonus is unchanged); higher tiers shrink the distance within which a guard hears a caught try (`guard_radius`). A guard who sees the theft still acts.
- **Tests:** `game/tests/skills_test.gd::test_outcomes`, `game/tests/run_tests.gd::test_theft_and_shops`

### INT-110 · Every interior floor shows a floor, not grass
- **Trigger:** The village map is generated (and drawn, with a roof lifted or faded).
- **Source:** `tools/build_village.py`
- **Affects:** Interiors
- **Expected:** Stamped floors lie in ground1+ over the village's grass layer (ground0); the tavern's open-air kitchen, which Shade drew as grass, gets the tavern's floor tile. Every cell of every building's interior floor has a floor tile.
- **Tests:** `game/tests/run_tests.gd::test_village_layout`

### INT-111 · The mine hill is bare rock and keeps trees off its rim
- **Trigger:** The village map is generated.
- **Source:** `tools/build_village.py`, `game/scripts/core/wiki_world.gd::add_pages`
- **Affects:** Resources, Interiors
- **Expected:** The hill's top is rock ground with two ledges (art only, geometry and solidity unchanged, so the track, seams and reachability stand); no tree trunk or crown stands within two cells of the hill. The wiki's mine page describes it.
- **Tests:** `game/tests/run_tests.gd::test_village_layout`

### INT-112 · Villagers at work show their tool
- **Trigger:** A villager's plan is on a work step (mining, felling, smithing, mending, hunting, farming).
- **Source:** `game/scripts/core/npc_brain.gd::work_look`, `game/scripts/main.gd::_process`
- **Affects:** Employment, Interface
- **Expected:** The sprite plays the swing frames with the pickaxe, axe, hammer or sword icon in hand (the gather frames for picking, sowing and feeding), as the player's do, instead of the staff swing. Sitting and sleeping poses are untouched.
- **Tests:** `game/tests/run_tests.gd::test_polish_work_looks`

### INT-113 · Rabbits and chickens leave a pelt and feathers
- **Trigger:** An adult rabbit or chicken is killed (hunt, slaughter).
- **Source:** `game/scripts/core/fauna.gd::kill`, `game/data/resources.json`
- **Affects:** Wildlife, Livestock, Loot, Inventory
- **Expected:** An adult rabbit gives meat and a rabbit pelt, an adult chicken meat and feathers (balance.json animals.*.pelt and feathers); young animals give neither. The bag is the same as for hide.
- **Tests:** `game/tests/run_tests.gd::test_polish_game_leftovers`

### INT-114 · Pelts are tanned or sold, feathers sold
- **Trigger:** The player or a villager holds a pelt or feathers.
- **Source:** `game/scripts/core/npc_brain.gd::_plan_sell_all`, `game/scripts/core/npc_brain.gd::_hunter`, `game/data/recipes.json`
- **Affects:** Crafting, Market, Employment
- **Expected:** Two pelts tan to one leather at the workbench (tan_pelts); the tanner and goods merchant buy pelts, the goods merchant buys feathers (no recipe uses them: the game has no arrows). Hunters and keepers sell them with their meat and hides.
- **Tests:** `game/tests/run_tests.gd::test_polish_game_leftovers`

### INT-115 · Every save carries its world's identity, for moving it between devices
- **Trigger:** The game is saved, loaded, or a new game starts.
- **Source:** `game/scripts/main.gd::save_game`, `game/scripts/main.gd::_save_meta`, `game/scripts/main.gd::_load_save`, `game/scripts/main.gd::new_game`
- **Affects:** Save
- **Expected:** (PL1-11 stage 1) The save's `meta` holds a world id made once per new game (kept through saves and loads), its creation and last-save times, play time, the saving device's platform and the character's name, so a copy on another device can be compared (same world, newer, longer played) without merging worlds. Nothing in a save names a device path; the world regenerates from its seed. A new game gets a new id. Cloud transfer itself (stages 2-5) is not built.
- **Tests:** `game/tests/start_test.gd::_save_meta_tests`

### INT-116 · The player rents a market pitch from the manor
- **Trigger:** The player uses an open pitch in the market and chooses Rent.
- **Source:** `game/scripts/core/business.gd::rent`, `game/scripts/core/business.gd::add_pitches`, `game/scripts/core/property.gd::relet_stalls`
- **Affects:** Market, Coins, Treasury, Save
- **Expected:** (PL1-10 stage 1) The manor keeps open pitches beside the merchants' stalls (stall entries with `pitch: true`; added to new worlds and to older saves on load). The player may hold one; the first day's rent (`stall_rent_day`, 5 coins) goes from the purse to the manor's treasury and the stall's tenant becomes the player. The merchants' re-letting skips pitches and Population never gives one to a merchant. Coins are conserved.
- **Tests:** `game/tests/business_test.gd::_rent`

### INT-117 · Goods move between the pack and the stall's sale stock, priced by the player
- **Trigger:** The player puts goods up, changes a price, takes goods back or closes the stall.
- **Source:** `game/scripts/core/business.gd::list_item`, `game/scripts/core/business.gd::unlist`, `game/scripts/core/business.gd::set_price`, `game/scripts/core/business.gd::close`, `game/scripts/ui/stall_window.gd::show`
- **Affects:** Inventory, Market, Crime, Loot
- **Expected:** (PL1-10 stage 1) Listing moves real items out of the pack (all or nothing) into the stall's stock at a price of 1 to 4 times the item's value; goods marked stolen cannot be listed (no fencing through a stall). Taking back and closing return every item and the till to the player; what does not fit the pack is left at the stall as loot. Nothing is created or lost.
- **Tests:** `game/tests/business_test.gd::_list_price_close`

### INT-118 · The stall sells only while the player is at it, into a till
- **Trigger:** A villager reaches the stall to buy.
- **Source:** `game/scripts/core/business.gd::attended`, `game/scripts/core/business.gd::arrive`, `game/scripts/core/business.gd::sell`, `game/scripts/core/npc_brain.gd::act`
- **Affects:** Market, Coins, Inventory, Households
- **Expected:** (PL1-10 stage 1) A sale needs the player within `stall_range` tiles of the stall (or, from stage 4, an attendant at it: INT-136) and no rent owing. The buyer's coins go into the stall's till (collected by the player, counted in World.total_coins), the goods leave the stock for the buyer's pack or household pantry, and the sale is recorded. A sale that cannot complete (stock gone, price changed, buyer cannot pay, player away) changes nothing.
- **Tests:** `game/tests/business_test.gd::_attended_sales`

### INT-119 · Villagers buy from the stall only for needs they really have
- **Trigger:** Each game hour while the player is at a stocked stall.
- **Source:** `game/scripts/core/business.gd::hour`, `game/scripts/core/business.gd::needs`, `game/scripts/core/business.gd::offer`, `game/scripts/core/business.gd::ceiling`, `game/scripts/core/npc_brain.gd::wants`, `game/scripts/core/construction.gd::open_need`
- **Affects:** Market, Employment, Households, Building, Coins, Inventory
- **Expected:** (PL1-10 stage 2) At most `stall_buyers_per_hour` idle, awake adults with a need walk to the stall and buy. Needs reuse the brain's model: a trade restocks below half its `NPCBrain.BUYS` cap (smith ore and coal, cook grain and meat, tanner hides), the carpenter, smith and labourer cover what open building sites ask for, miners, labourers and woodcutters replace a missing tool, guards their gear, the household's head firewood and food (as `_plan_provision`). Merchants and children do not shop. A buyer pays only up to the cheapest local price (a little more when urgent), only with coins above a cash floor, and the goods go into their pack or pantry, so a met need buys nothing more.
- **Tests:** `game/tests/business_test.gd::_demand`

### INT-120 · Stall rent is paid daily; unpaid rent stops sales and then returns the pitch
- **Trigger:** A new game day begins with a rented stall.
- **Source:** `game/scripts/core/business.gd::daily`, `game/scripts/core/business.gd::pay_arrears`, `game/scripts/core/world.gd::_new_day`
- **Affects:** Coins, Treasury, Market, Save
- **Expected:** (PL1-10 stage 1) Each morning the day's rent is taken from the purse and then the till and goes to the treasury. If it cannot be paid, sales stop (`missed` counts mornings); after `stall_evict_days` the manor takes the pitch back and the unsold goods and the till return to the player. The stall's whole state (tenant, stock, prices, sales, till, rent paid-through day) is part of World.stalls and survives save and load.
- **Tests:** `game/tests/business_test.gd::_rent_daily`, `game/tests/business_test.gd::_save_load`

### INT-121 · The player clears land they hold: stumps, saplings, wild plants and boulders go for good
- **Trigger:** Use on a stump, a growing tree, a sapling, a wild plant or a boulder that stands on a parcel the player owns or leases.
- **Source:** `game/scripts/core/farming.gd::obstacle`, `game/scripts/core/farming.gd::clear_tree`, `game/scripts/core/farming.gd::clear_plant`, `game/scripts/main.gd::_find_target`
- **Affects:** Resources, Property, Player state, Inventory
- **Expected:** (PL2-015) Only ground the player holds can be cleared this way. A mature tree is felled first (the axe, as anywhere), then its stump is dug out with an axe (stamina `farming.clear.stump_stamina`); a sapling or young tree is pulled up by hand; a wild plant is grubbed up; a boulder is mined away (B8-026). Each ends as "cleared" ground: the tree does not sprout again, the plant does not regrow, the cell is walkable and can be tilled.
- **Tests:** `game/tests/farming_test.gd::test_land_and_clearing`

### INT-122 · Tilling joins a cell to the player's field, at the cost of time and stamina
- **Trigger:** Use on a clear cell of held ground (the plough in hand makes it the first choice).
- **Source:** `game/scripts/core/farming.gd::till`, `game/scripts/core/farming.gd::till_cost`, `game/scripts/core/farming.gd::plan`
- **Affects:** Fields, Player state, Inventory, Property
- **Expected:** (PL2-015) Each tilled cell joins the player's field (`Farming.cells`), any shape; it is drawn with the field tiles closed at the edges of the shape. By hand a cell takes `farming.till.hand` seconds and stamina (the player needs that much to begin); with the hand plough (workbench: planks and iron bars) it takes `farming.till.plough`, which is less of both, and the plough wears one a cell. No draught animal exists yet. Villagers' farmers only work the manor's fields: nothing of the player's is cut or trampled.
- **Tests:** `game/tests/farming_test.gd::test_tilling`

### INT-123 · Sown crops grow by the hour at the season's rate and stop in winter
- **Trigger:** The player sows a tilled cell with a seed; every game hour afterwards.
- **Source:** `game/scripts/core/farming.gd::sow`, `game/scripts/core/farming.gd::hour`, `game/scripts/core/farming.gd::season_rate`, `game/scripts/core/world.gd::_on_hour`
- **Affects:** Fields, Calendar, Inventory
- **Expected:** (PL2-015) A seed is used up. A sown cell gains 1 / (crop days x 24) of growth an hour times the season's rate (`farming.season_rate`: spring and summer 1, autumn 0.5, winter 0) and is ripe at 1; nothing can be sown in winter (`farming.sow_seasons`). The manor's own fields keep `field_grow_days` and are not affected.
- **Tests:** `game/tests/farming_test.gd::test_crops`

### INT-124 · A harvest returns the crop and some seed (seed saving)
- **Trigger:** Use on a ripe cell of the player's field.
- **Source:** `game/scripts/core/farming.gd::harvest`, `game/scripts/core/farming.gd::harvest_goods`
- **Affects:** Fields, Inventory, Food, Market
- **Expected:** (PL2-015) The cell gives the crop's yield (wheat, carrots, potatoes, or the herb crop's wild flowers) and `seeds_back` seed of the same crop, and is tilled, empty soil again; it is refused while the pack cannot hold the goods. The crops are the player's alone (no theft rule applies).
- **Tests:** `game/tests/farming_test.gd::test_crops`

### INT-125 · Seed is bought from the farmers' and the food merchant's own stock with real coins
- **Trigger:** The player buys seed in the trade window of a farmer or the food stall's merchant; a farmer cuts a field; the caravan visits.
- **Source:** `game/scripts/core/farming.gd::buy_seed`, `game/scripts/core/farming.gd::seed_offers`, `game/scripts/core/farming.gd::save_seed`, `game/scripts/core/npc_brain.gd::_caravan_seeds`, `game/scripts/core/npc_brain.gd::act`, `game/scripts/core/population.gd::_equip`, `game/scripts/ui/game_ui.gd::show_trade`
- **Affects:** Coins, Market, Inventory, Fields, Ledger
- **Expected:** (PL2-015; Build 13 owner economy rule 3: seed never appears from nowhere) Seed is stock in real inventories. Farmers start with `farming.seed_stock.farmer`, the food merchant with `seed_stock.food_merchant`. A seller offers only the crops they hold seed of, and a sale moves that many seeds out of their inventory into the pack through `World.trade` at `seed_price` (adjusted by the Trading skill), all or nothing; more than they hold is refused. A farmer cutting a village field keeps `seed_keep` of the grain back as wheat seed, up to `seed_cap` (the rest stays grain; counted in `farm_seed_saved`, so the grain ledger balances). Each caravan visit sells the food merchant up to `caravan_seed_per_visit` seeds towards `caravan_seed_stock`, at seed value from the merchant's own coins above the trader cash floor; those coins leave the village. Seed is never offered as ordinary goods (`NPCBrain.KEEPS`). The player also saves seed from their own harvests (INT-124). A save from before Build 13 has no seed stock: the sellers' stock rebuilds from harvests and caravans.
- **Tests:** `game/tests/farming_test.gd::test_crops`, `game/tests/run_tests.gd::test_simulation`

### INT-126 · A fenced pen on held ground is a pen of the village's livestock model
- **Trigger:** The player fences a pen from the plot window on ground they hold, with planks.
- **Source:** `game/scripts/core/farming.gd::build_pen`, `game/scripts/core/farming.gd::pen_refusal`, `game/scripts/core/fauna.gd::to_dict`, `game/scripts/ui/game_ui.gd::_farm_options`
- **Affects:** Livestock, Property, Inventory, Building, Save
- **Expected:** (PL2-015) Planks are used up; the fence ring is solid but for the gate and drawn with the Cozy Farm fence tiles; the pen is in `Fauna.pens` as the player's (`player: true`, owner the player), so feeding, hunger, breeding and the life stages are the village's own rules. It holds one species. A building cannot be marked out over it. Pens, their trough and products, and the animals are saved.
- **Tests:** `game/tests/farming_test.gd::test_pens_and_animals`, `game/tests/farming_test.gd::test_save`

### INT-127 · Livestock is bought from a keeper's real stock
- **Trigger:** The player chooses Buy at a manor pen's gate while holding a pen of that species with room.
- **Source:** `game/scripts/core/farming.gd::buy_animal`, `game/scripts/core/farming.gd::spare_animal`, `game/scripts/main.gd::_find_target`
- **Affects:** Livestock, Coins, Wildlife
- **Expected:** (PL2-015) The animal comes out of the keeper's pen into the player's: never a newborn, and never below the species' breeding stock (`animals.keep`); a juvenile costs `young_price_share` of an adult's `animal_price`. The coins go to the keeper (the treasury if the pen has none): no coin is made. The keeper's pen refills by breeding.
- **Tests:** `game/tests/farming_test.gd::test_pens_and_animals`

### INT-128 · Well-fed adults in pens make eggs, milk and wool
- **Trigger:** Each morning (`World._new_day`).
- **Source:** `game/scripts/core/farming.gd::daily_products`, `game/scripts/core/farming.gd::collect`, `game/scripts/core/world.gd::_new_day`, `game/scripts/core/fauna.gd::to_dict`, `game/scripts/core/fauna.gd::load_dict`
- **Affects:** Livestock, Inventory, Food, Market, Save
- **Expected:** (PL2-015; Build 13) Each adult female hen, cow or any sheep in a pen that is well fed (`animal_breed_min_hunger`) makes its product when its time comes (`farming.products`), kept in the pen up to `product_cap` until collected: the player collects at their own pens' gates, and a village pen's products are its keeper's (INT-137); the player cannot collect them. Hungry, young and elderly animals make none. A village pen's waiting products are saved with the pen (older saves: none waiting).
- **Tests:** `game/tests/farming_test.gd::test_pens_and_animals`, `game/tests/farming_test.gd::test_save`

### INT-129 · Farm goods sell to the cook and the merchants, or from the player's stall, and feed the crafts
- **Trigger:** The player sells eggs, milk, cheese, carrots, potatoes or wool; or crafts with them.
- **Source:** `game/scripts/core/npc_brain.gd::wants`, `game/scripts/core/business.gd::needs`, `game/data/recipes.json`
- **Affects:** Market, Coins, Crafting, Food, Treasury
- **Expected:** (PL2-015) The cook and the food merchant buy eggs, milk, cheese, carrots and potatoes up to a stock; the goods merchant buys wool and cloth; the sage keeps buying flowers. Villagers with a trade's stock need buy them from the player's stall too. Cheese is pressed from milk and egg bread baked at a food table; wool is woven into cloth at the workbench and sewn into bandages (so bandages are craftable). (Build 13) The villagers now make them too: the cook at the kitchen's preparation table (INT-138), the tanner at the workbench (INT-139).
- **Tests:** `game/tests/farming_test.gd::test_market`

### INT-130 · Building on ground ploughs the field under; the village never claims the player's field
- **Trigger:** The player marks out a building on a parcel with a field on it; a villager or the player claims ground over a field.
- **Source:** `game/scripts/core/world.gd::start_site`, `game/scripts/core/farming.gd::give_up_cells`, `game/scripts/core/farming.gd::building_refusal`, `game/scripts/core/property.gd::can_claim`
- **Affects:** Fields, Building, Property, Save
- **Expected:** (PL2-015) Marking out a building on a parcel gives up the field cells on it (crops and soil are lost, a note says so) and is refused while a pen of the player's stands on it; ground cannot be claimed over a parcel the player holds, so the farm is never built over by the village.
- **Tests:** `game/tests/farming_test.gd::test_save`, `game/tests/farming_test.gd::test_tilling`

### INT-131 · A larger market stall is bought from the manor
- **Trigger:** The player chooses the larger stall in the stall window.
- **Source:** `game/scripts/core/business.gd::upgrade`, `game/scripts/core/business.gd::listing_cap`, `game/scripts/core/business.gd::rent_of`, `game/scripts/core/business.gd::set_display`
- **Affects:** Market, Coins, Treasury, Inventory
- **Expected:** (PL1-10 stage 3) For `stall_large_cost` coins (paid to the treasury, so coins are conserved) the rented pitch becomes a larger stall: it holds `stall_large_listings` kinds of goods instead of `stall_max_listings`, its daily rent becomes `stall_large_rent_day`, and one item on sale can be shown on a display that makes the hourly demand reach `stall_large_reach` times as far. The purchase is an expense in the stall's books; closing the stall returns the pitch plain again.
- **Tests:** `game/tests/business_test.gd::_larger_stall`

### INT-132 · Equipment is placed in a room the player holds
- **Trigger:** The player fits out a room they built: counter, shelves, stock chest, oven, stove, workbench, forge or anvil.
- **Source:** `game/scripts/core/fitting.gd::place`, `game/scripts/core/fitting.gd::why_not`, `game/scripts/core/fitting.gd::remove`, `game/scripts/ui/fit_window.gd::show`, `game/scripts/main.gd::begin_fit`
- **Affects:** Building, Inventory, Crafting, Save
- **Expected:** (PL1-10 stage 3) A piece goes on a free floor cell inside a room the player holds (house, workshop, storeroom, quarters), never on a door, bed, chair, table or station, its use cell, or the stamp's own furniture, and only where every cell of the room reachable before stays reachable from the door. The materials (`shop_equipment`) leave the pack and are counted as used in the building; the cell becomes solid and is drawn in the furniture layer; taking the piece up returns the materials. The list is part of the building (`fit`), so it survives save and load, with collision and stations restored.
- **Tests:** `game/tests/business_test.gd::_shop`, `game/tests/business_test.gd::_shop_save`

### INT-133 · A room's stations follow the equipment placed in it, and name the shop's trade
- **Trigger:** An oven, stove, workbench, forge or anvil is placed in or taken from a room.
- **Source:** `game/scripts/core/fitting.gd::apply`, `game/scripts/core/fitting.gd::trade`, `game/scripts/core/fitting.gd::station_kinds`, `game/scripts/core/world.gd::set_owner`
- **Affects:** Crafting, Building, Employment
- **Expected:** (PL1-10 stage 3) A placed station is an ordinary World.stations entry of that building (owner, use cell, capacity): the craft window, recipes and prompts are the existing ones; the owner uses it and villagers need leave as for any workshop or home. What the shop is follows its equipment: a forge and an anvil make a smithy, an oven a bakery, a workbench a carpenter's shop, a stove a kitchen, otherwise a general store. Taking a station up removes it from the world's stations.
- **Tests:** `game/tests/business_test.gd::_shop`

### INT-134 · A shop sells like a stall, from a counter, with shelves, a back room and its books
- **Trigger:** The player opens a shop at a placed counter, stocks it and sells.
- **Source:** `game/scripts/core/business.gd::open_shop`, `game/scripts/core/business.gd::record`, `game/scripts/core/business.gd::store_item`, `game/scripts/core/business.gd::sell`, `game/scripts/core/business.gd::profit`, `game/scripts/ui/stall_window.gd::show`
- **Affects:** Market, Coins, Treasury, Inventory, Households, Save
- **Expected:** (PL1-10 stage 3) The shop's record lives in the building (`shop`, saved with it) and has the stall's fields: stock, prices, sales, till, earned, paid through day. It pays `shop_licence_day` a day to the manor (the first at opening; unpaid stops sales and, after `stall_evict_days`, closes it and returns the goods), holds `shop_listings` kinds plus `shop_shelf_listings` per shelves, and a stock chest's `shop_store_per_chest` pieces refill a sold-out kind at its price. Buyers, needs, ceilings and cash floors are the stall's (INT-119). Revenue, expenses (licence, wages) and profit are kept; the till counts in the village's coins. Taking up the counter, or losing the room, closes the shop with nothing lost.
- **Tests:** `game/tests/business_test.gd::_shop`, `game/tests/business_test.gd::_shop_save`

### INT-135 · An attendant is hired and paid a daily wage
- **Trigger:** The player hires a villager at the stall or shop window, and each morning after.
- **Source:** `game/scripts/core/business.gd::hire`, `game/scripts/core/business.gd::hire_refusal`, `game/scripts/core/business.gd::_wage_due`, `game/scripts/core/business.gd::dismiss`, `game/scripts/core/business.gd::candidates`, `game/scripts/core/construction.gd::can_hire`
- **Affects:** Employment, Coins, Households, Market
- **Expected:** (PL1-10 stage 4) Only an adult without a trade of their own (`Construction.HIRABLE`: out of work, a manor hand with no job taken, or a labourer; not hired for building work, not another counter's attendant) can be hired, one attendant for each stall or shop. An attendant cannot in turn be hired as a carrier by the player's or a villager's building site (`Construction.can_hire`, Build 13 fix), so the counter is never left empty on a paid day. Today's `attendant_wage` is paid at once, from the till first and then the purse, to the villager's own coins (conserved; an expense in the books), and again every morning; when neither can pay, the attendant leaves. Closing the stall or shop, taking up the counter or a death lets them go; they keep what they were paid.
- **Tests:** `game/tests/business_test.gd::_attendant`

### INT-136 · An attendant at the counter lets the premises sell while the player is away
- **Trigger:** A working day (7 to 18) with a hired attendant; each game hour thereafter.
- **Source:** `game/scripts/core/business.gd::plan_attendant`, `game/scripts/core/business.gd::attended`, `game/scripts/core/business.gd::attendant_present`, `game/scripts/core/npc_brain.gd::decide`
- **Affects:** Employment, Market, Coins, Inventory, Households
- **Expected:** (PL1-10 stage 4) In working hours the brain plans the attendant's day to the counter (the stall, or the shop's counter cell) before their own trade, and at night they sleep as everyone does. A stall or shop sells when the rent is not owing and the player is near or the attendant is awake at the counter; with neither, nothing sells and no buyer is sent. Buyers are the same real needs with budgets (INT-119); sales made while the player is away are marked as the attendant's and give no trading experience. The attendant never buys from their own counter.
- **Tests:** `game/tests/business_test.gd::_attendant`

### INT-137 · Keepers collect their pens' eggs, milk and wool and sell them
- **Trigger:** A keeper's day when their pen has products waiting; then the keeper's next plan.
- **Source:** `game/scripts/core/npc_brain.gd::_keeper`, `game/scripts/core/npc_brain.gd::act`, `game/scripts/core/farming.gd::products_in`, `game/scripts/core/npc_brain.gd::_plan_sell`
- **Affects:** Livestock, Inventory, Market, Coins, Employment
- **Expected:** (Build 13, owner: livestock production chains) A keeper whose pen has eggs, milk or wool waiting walks to the gate and collects them (`collect_pen`: the pen's stock moves into the keeper's pack, `keeper_collected_<item>`), then sells them like meat and hides: eggs and milk to the cook (then the food merchant), wool to the tanner (then the goods merchant), each buyer paying from their own coins up to their `BUYS` cap. Nothing is made without a fed adult animal; nothing is sold to a buyer without the coins (INT-019).
- **Tests:** `game/tests/farming_test.gd::test_village_chain`

### INT-138 · The cook presses cheese and bakes egg bread at the kitchen's preparation table; villagers eat them
- **Trigger:** The cook's working day with milk or eggs in stock; a villager buying a meal; a hungry drinker at the tavern.
- **Source:** `tools/build_village.py`, `game/scripts/core/npc_brain.gd::_cook`, `game/scripts/core/npc_brain.gd::_do_recipe`, `game/scripts/core/npc_brain.gd::_meal_choice`, `game/scripts/core/npc_brain.gd::act`
- **Affects:** Crafting, Food, Market, Coins, Households, Interiors
- **Expected:** (Build 13) The tavern kitchen has a public preparation table (station s10, `prep`, village generator v7; stations are not saved, so older saves have it). The cook presses 3 milk into cheese and bakes 1 egg and 2 wheat into 2 loaves there (`press_cheese`, `bake_egg_bread`), the inputs taken from the cook's own stock, and takes cheese and bread out fresh to the tavern keeper and the food merchant. Cheese and bread are meals (`NPCBrain.COOKED`, `FOOD`): a villager buying a meal picks the most food per coin at today's prices (prices rise as a vendor's stock runs low), and one with `tavern_spare_coins` sometimes treats themselves to cheese (`cheese_treat_chance`); a drinker at the tavern below `tavern_supper_hunger` buys a bread or cheese supper from the keeper's stock. The grain used is counted (`used_wheat`), so the grain ledger balances.
- **Tests:** `game/tests/farming_test.gd::test_village_chain`, `game/tests/run_tests.gd::test_simulation`

### INT-139 · The tanner weaves wool into cloth and sews bandages for the Apothecary
- **Trigger:** The tanner's working day with wool or cloth in stock.
- **Source:** `game/scripts/core/npc_brain.gd::_tanner`, `game/scripts/core/npc_brain.gd::_crafter`, `game/scripts/core/npc_brain.gd::wants`
- **Affects:** Crafting, Market, Coins, Health, Employment
- **Expected:** (Build 13) Besides leather, the tanner buys wool (`BUYS.tanner`), weaves 2 into cloth at the workbench while holding under 4 cloth, and sews 1 cloth into 3 linen bandages when the sage wants at least 3 (`BUYS.sage` linen_bandage 8); the bandages go to the sage, who sells them in the Apothecary (INT-083), and spare cloth to the goods merchant. Every step takes its inputs from the tanner's stock.
- **Tests:** `game/tests/farming_test.gd::test_village_chain`

### INT-140 · A villager at the resource the player faces never takes the harvest away
- **Trigger:** The player faces a seam, boulder, tree, plant, field or farm cell while a villager stands within reach (often working it too).
- **Source:** `game/scripts/main.gd::_find_target`, `game/scripts/main.gd::talk_to_alt`, `game/scripts/main.gd::_player_step`, `game/scripts/main.gd::interact`, `game/scripts/ui/game_ui.gd::show_talk`
- **Affects:** Interface, Resources
- **Expected:** (owner, Build 13 playtest: "hit A to harvest, or another button to talk"; owner chose A and Y) The resource is the default choice: A (pad), E (keys) or Use works it. The villager is offered on the prompt's second line: Y on a pad, T on a keyboard; on touch, tap them. Y talks instead of casting Fireball while that offer stands; otherwise Y casts as before. Q / Tab and the D-pad still cycle every choice. With nobody beside the resource, nothing changes.
- **Tests:** `game/tests/start_test.gd::_actions_tests`

### INT-141 · Households forage, brew medicine at home and villagers treat their own wounds
- **Trigger:** A villager's evening (after work, or all day without a trade); a villager below `home_production.medicine_use_below` of their health.
- **Source:** `game/scripts/core/npc_brain.gd::_plan_evening`, `game/scripts/core/npc_brain.gd::_plan_heal`, `game/scripts/core/npc_brain.gd::_plan_home_work`, `game/scripts/core/npc_brain.gd::_wild_plant_near`, `game/scripts/core/npc_brain.gd::act`, `game/scripts/core/world.gd::pick_plant`
- **Affects:** Households, Health, Resources, Food, Crafting, Market, Coins
- **Expected:** (owner, Build 14: villagers make food and medicine at home for their own use) A hurt villager uses a medicine they carry or the household keeps (the least that will do first), else walks to the Apothecary and buys one with their own coins; villagers have no other healing. In the evening an adult gathers a ripe village plant within `forage_range` of home (wild flowers while the household lacks flowers for a poultice, else berries up to `berries_keep`), the plant is picked for real and regrows as usual, and the take goes into the household's store; with flowers enough they brew a poultice at the home's hearth (`brew_poultice`, inputs from the household's store) up to `poultice_keep`. Berries are pantry food (`NPCBrain.FOOD`). Plants are now shared with the player: what villagers pick is gone until it regrows.
- **Tests:** `game/tests/home_test.gd::test_healing`, `game/tests/home_test.gd::test_foraging_and_brewing`, `game/tests/home_test.gd::test_village_days`

### INT-142 · Houses add a storefront: households sell their surplus at their own counter
- **Trigger:** The player builds a storefront at a house they hold (Use at its door), or an industrious villager's evening (`home_production.storefront_coins` of their own, the household's medicine in store, room by the door); an evening at a house with a counter.
- **Source:** `game/scripts/core/business.gd::front_place`, `game/scripts/core/business.gd::build_storefront`, `game/scripts/core/business.gd::build_npc_front`, `game/scripts/core/business.gd::open_front`, `game/scripts/core/business.gd::rent_of`, `game/scripts/core/npc_brain.gd::_plan_storefront`, `game/scripts/core/npc_brain.gd::front_goods`, `game/scripts/core/npc_brain.gd::_plan_heal`, `game/scripts/core/world.gd::shop_post`, `game/scripts/main.gd::_find_target`
- **Affects:** Households, Property, Market, Coins, Crafting, Health, Interface
- **Expected:** (owner, Build 14: "house should be able to progress to adding a storefront") A storefront is a counter on two open cells by the house door, costing `storefront_cost` (planks and an iron bar) from the builder's own pack. The player's opens as one of their premises with listings and books; no rent or licence (the household's own ground); closing keeps the counter and it reopens free. A villager buys any missing materials from the carpenter or timber stall and the smith or goods stall with their own coins, then builds. In the evening one adult of the household takes the surplus (poultices beyond `poultice_keep`, berries beyond `berries_keep`) to the counter and keeps it until `storefront_close_hour`, trading with the player and villagers like any shopkeeper; a storefront household brews `storefront_stock` extra poultices to sell. Hurt villagers buy medicine from the nearest of the Apothecary and any storefront keeper at their post. Coins only move between people.
- **Tests:** `game/tests/home_test.gd::test_player_storefront`, `game/tests/home_test.gd::test_villager_storefront`

### INT-143 · Cart parts from the carpenter and the smith; households assemble or buy a handcart
- **Trigger:** The carpenter's work (planks to spare, too few wheels or no handcart for sale); the smith choosing what to forge; a storefront household's adult with `carts.cart_coins` of their own and no handcart in the household.
- **Source:** `game/scripts/core/npc_brain.gd::_carpenter_carts`, `game/scripts/core/npc_brain.gd::_smith`, `game/scripts/core/npc_brain.gd::_part_seller`, `game/scripts/core/npc_brain.gd::_parts_trip`, `game/scripts/core/npc_brain.gd::_plan_cart`, `game/scripts/core/npc_brain.gd::household_cart`, `game/scripts/core/npc_brain.gd::act`, `game/scripts/main.gd::craft`
- **Affects:** Crafting, Market, Coins, Households, Resources
- **Expected:** (owner, Build 14: carts from logs, planks, ore, coal and iron, a smithy and a carpenter; villagers build from scratch or buy components and assemble) Recipes shared by the player and villagers: a cart wheel from 3 planks at the sawhorse; an axle from an iron bar and a plank, and the ironwork from an iron bar and coal, at the anvil; a handcart from 2 wheels, an axle, the ironwork and 4 planks at a workbench. The carpenter saws wheels while it holds `wheel_min_planks` planks (up to `wheel_stock`) and assembles `handcart_stock` handcarts for sale, buying the axle and ironwork from the smith with its own coins; the smith forges one of each at a time from its own bars, planks and coal. A storefront household's adult buys the parts it lacks and assembles at a workbench, or buys the carpenter's finished handcart when that is cheaper or the parts are not to be had; the cart goes into the household's store. Prices are the sellers' supply prices; coins only move between people.
- **Tests:** `game/tests/home_test.gd::test_cart_parts`, `game/tests/home_test.gd::test_household_cart`, `game/tests/home_test.gd::test_cart_days`

### INT-144 · A seller's price follows what else is for sale nearby
- **Trigger:** Any villager selling to the player or to another villager (`World.sell_price`, the player's quote).
- **Source:** `game/scripts/core/world.gd::sell_price`, `game/scripts/core/world.gd::local_supply`, `game/scripts/core/world.gd::sell_price_at`, `game/scripts/core/world.gd::player_quote`, `game/scripts/core/business.gd::premises`
- **Affects:** Market, Coins, Crafting
- **Expected:** (owner, Build 14: "pricing should be determined by availability for sale in a certain diameter ... you either make your own or buy it at a high price, or make and sell them to lower the price") The asking price falls by `local_supply.weight` for each unit (up to `cap`) of the item that other traders (`local_supply.jobs`, and anyone keeping a counter) hold and the player's open stall and shops stock within `radius` tiles of the seller; a lone seller asks the full scarcity price set by its own stock. So a lone finished handcart costs more than its parts, and goods the player puts up for sale nearby lower the villagers' prices. What buyers offer is unchanged.
- **Tests:** `game/tests/home_test.gd::test_local_pricing`

### INT-145 · Forest animals feed themselves: grazers graze, hunters hunt, the fox raids the pens
- **Trigger:** Every game hour of an animal's hunger (Fauna.tick); a wild animal near the player moving (Fauna._move); the player or a hunter striking a wild animal.
- **Source:** `game/scripts/core/fauna.gd::_eat`, `game/scripts/core/fauna.gd::_predate`, `game/scripts/core/fauna.gd::take`, `game/scripts/core/fauna.gd::can_take`, `game/scripts/core/fauna.gd::spare`, `game/scripts/core/fauna.gd::_forage_berries`, `game/scripts/core/fauna.gd::_raid`, `game/scripts/core/fauna.gd::provoke`, `game/scripts/core/fauna.gd::_hunt_people`, `game/scripts/core/fauna.gd::_bite`, `game/scripts/core/fauna.gd::_move`, `game/scripts/core/fauna.gd::nearest_game`, `game/scripts/core/fauna.gd::seed_new_species`, `game/scripts/core/fauna.gd::_spare_prey`, `game/scripts/core/fauna.gd::new_day`, `game/scripts/main.gd::_hit_animal`
- **Affects:** Livestock, Health, Food, Resources, Player state, Households
- **Expected:** (owner, Build 14: forest animals roam and feed on their own, carnivores hunt and eat the grazers; owner answers 2026-10-19) Deer, boar and rabbits graze (the wood's grass counts only grazers); birds pick seeds. A hungry wolf, fox or bear kills one of its `prey` in its wood at most `wildlife.hunt_chance_per_hour` an hour; near the player the chase is seen and may end sooner, and prey run from a hunter within their `flee` distance. The bear eats a ripe berry bush by its wood first (the bush is picked). A hungry fox takes a pen chicken at night. Nobody (predator, hunter, poacher) takes the last grown male or female of a kind in a wood or goes below its `keep`; the village hunter leaves `wildlife.hunter_spare` more and never hunts wolves, foxes or bears. A hunter or omnivore breeds only while its wood holds `wildlife.prey_per_predator` spare prey for each of its kind and one more, and a wood's last pair of a hunting kind scavenges (hunger back to `wildlife.scavenge_hunger`) rather than starve, so no kind dies out. Foxes eat ripe berries first, like the bear. Wolves and bears struck by the player fight back and bite; a starving one goes for a person alone in its wood; foxes never attack people. Older saves gain the new species once.
- **Tests:** `game/tests/wildlife_test.gd::test_population`, `game/tests/wildlife_test.gd::test_predation`, `game/tests/wildlife_test.gd::test_chase_and_flee`, `game/tests/wildlife_test.gd::test_fox_raid`, `game/tests/wildlife_test.gd::test_people`, `game/tests/wildlife_test.gd::test_hunting`, `game/tests/wildlife_test.gd::test_save`, `game/tests/wildlife_test.gd::test_days`

### INT-146 · Carts in play: set down, pulled, filled, parked at cart stops, taken to market by households
- **Trigger:** The player sets a handcart down from the Pack, pulls, lets go of or opens a cart; a household buys or builds a handcart; an evening with a parked household cart and carts.trip_min surplus in store; each hour for the player's cart at a cart stop.
- **Source:** `game/scripts/core/carts.gd::place`, `game/scripts/core/carts.gd::hitch`, `game/scripts/core/carts.gd::may_use`, `game/scripts/core/carts.gd::update`, `game/scripts/core/carts.gd::hour`, `game/scripts/core/carts.gd::unload`, `game/scripts/core/chests.gd::_info_cart`, `game/scripts/core/npc_brain.gd::_plan_market_run`, `game/scripts/core/npc_brain.gd::cart_spot`, `game/scripts/core/npc_brain.gd::act`, `game/scripts/main.gd::set_down_cart`, `game/scripts/main.gd::_find_target`, `game/scripts/main.gd::_sync_carts`
- **Affects:** Inventory, Market, Households, Player state, Interface, Crime, Containers, Save
- **Expected:** (owner, Build 14 answers: pulled storage that slows walking, parked at home or a hub, only the owner, family or hired help use a cart; the mine cart as stand-in art) A set-down handcart is a cart in the world holding carts.stacks kinds of goods. Its owner pulls it (walking at carts.pull_speed), lets go anywhere and opens it like a chest; taking from another's cart is theft. A household's cart stands by its door; with enough surplus an adult loads it, pulls it to the merchants who buy each good (now including berries and poultices), sells, and brings it home, unsold goods returning to the store. The player's cart parked at a market cart stop near their stall is unloaded into the stall store hourly by their attendant. Carts are saved.
- **Tests:** `game/tests/home_test.gd::test_household_cart`, `game/tests/home_test.gd::test_carts_in_play` (pulling, who may use a cart, theft from it, the cart stop delivery, a market run, save and load)

### INT-147 · Apple trees: the cottagers' orchards bear apples in season; picked, felled and replanted
- **Trigger:** The player faces a grown apple tree in fruit; a villager's evening when the household is short of berries and apples; each dawn (fruit returns or goes with the season); felling an apple tree.
- **Source:** `game/scripts/core/trees.gd::fruit_ripe`, `game/scripts/core/trees.gd::planted_species`, `game/scripts/core/world.gd::pick_fruit`, `game/scripts/core/world.gd::_tree_species`, `game/scripts/core/world.gd::_new_day`, `game/scripts/core/npc_brain.gd::_fruit_tree_near`, `game/scripts/core/npc_brain.gd::_plan_home_work`, `game/scripts/view/tree_view.gd::_dress`, `game/scripts/main.gd::_find_target`
- **Affects:** Resources, Food, Households, Market, Calendar
- **Expected:** (asset pipeline, owner directive 2026-10-19; Craftpix fruit trees) Village trees near the houses are partly apple trees (fruit_trees orchard rules; new worlds). A grown apple tree bears fruit_trees.apple_orchard.yield apples in summer and autumn: the player or a villager picks them (the tree is then bare until regrow_days later, in season); apples are pantry food, sold at storefronts and to the food merchant. Felled, an apple tree gives logs and (by chance) an apple sapling that grows a new apple tree. Apples now have a source (the resources.json exception is gone). Saved with the trees.
- **Tests:** `game/tests/home_test.gd::test_apple_trees`

### INT-148 · Friendship, courting and marriage: gifts, help, befriending, proposals; friends' benefits
- **Trigger:** Every hour (people near each other share it); the player talks with, gives a gift to, completes a request for, befriends, asks to court or proposes in the talk window; each dawn (villagers court; ties cool); the player trades with, hires or is stopped by a guard near a friend.
- **Source:** `game/scripts/core/relations.gd::give`, `game/scripts/core/relations.gd::gift_effect`, `game/scripts/core/relations.gd::favourites`, `game/scripts/core/relations.gd::helped`, `game/scripts/core/relations.gd::befriend`, `game/scripts/core/relations.gd::ask_court`, `game/scripts/core/relations.gd::propose`, `game/scripts/core/relations.gd::dawn`, `game/scripts/core/relations.gd::_villagers_court`, `game/scripts/core/relations.gd::hour`, `game/scripts/core/relations.gd::share`, `game/scripts/core/relations.gd::talked`, `game/scripts/core/world.gd::_on_hour`, `game/scripts/ui/game_ui.gd::show_talk`, `game/scripts/core/quests.gd::complete`, `game/scripts/core/world.gd::player_quote`, `game/scripts/core/world.gd::guard_confront`, `game/scripts/core/construction.gd::hire`, `game/scripts/ui/game_ui.gd::_relation_choices`, `game/scripts/ui/game_ui.gd::show_gifts`, `game/scripts/ui/dialogue.gd::news`, `game/scripts/core/life.gd::dawn`
- **Affects:** Family, Households, Market, Crime, Building, Interface, Save
- **Expected:** (owner, 2026-10-19: CRT-01..07) Every pair of people has a tie: regard and attraction. Shared experiences start ties (CRT-08): each hour people awake within `shared.near_tiles` share it, work (same trade or workplace, at work) counting most, then evening company, then time nearby, at most `shared.daily_cap` regard a day; each pair's hour counts once (CRT-09); a conversation with the player counts that hour as shared and adds `talk_first`, then `talk_more`, then `talk_decay` times less each time that day; villagers befriend each other at `befriend_at` and court only someone at `interest_at` attraction or more. A gift moves one real item from the giver to the receiver: food, flowers, ale, clothes and jewellery always add attraction (between people who may court: humans of age, not kin, not partnered elsewhere, either sex) and regard; the receiver's favourites (their trade's FAVOURITES, food when hungry, medicine when hurt) count `favourite_factor` and are marked with the reason in the gift list; one gift a day counts, a repeat counts less. Help (a request done) adds regard. At `befriend_at` regard the player may Befriend (no proposal). At `court_at` attraction a request to court is accepted, else declined; a proposal while courting is accepted after `propose_min_days` at `propose_at`, else declined as too soon and attraction drops. Villagers court each other by the same rules each dawn (replacing the random pairing), with gifts they hold or time together. Friends trade at `friend_price` better, carry for the player's site with no wage, tell who is courting, and back the player before a guard (a friend guard warns only; a friend nearby halves the fine). Partners of one sex have no children. Ties save in `relations` (older saves: strangers). Goods and coins only move.
- **Tests:** `game/tests/relations_test.gd`, `game/tests/aging_test.gd::test_partners_and_births`

## Reverse dependency index

<!-- index:start (generated by tools/check_interactions.py --write) -->

| System | Interactions |
|---|---|
| Character | INT-001, INT-018, INT-031, INT-080 |
| Player state | INT-003, INT-004, INT-005, INT-006, INT-018, INT-021, INT-031, INT-038, INT-044, INT-052, INT-053, INT-080, INT-097, INT-098, INT-101, INT-105, INT-106, INT-109, INT-121, INT-122, INT-145, INT-146 |
| Inventory | INT-003, INT-005, INT-006, INT-007, INT-008, INT-009, INT-010, INT-014, INT-015, INT-019, INT-021, INT-027, INT-028, INT-030, INT-031, INT-032, INT-038, INT-043, INT-044, INT-045, INT-046, INT-059, INT-064, INT-066, INT-067, INT-068, INT-069, INT-070, INT-074, INT-083, INT-086, INT-087, INT-099, INT-100, INT-101, INT-103, INT-104, INT-106, INT-107, INT-113, INT-117, INT-118, INT-119, INT-121, INT-122, INT-123, INT-124, INT-125, INT-126, INT-128, INT-131, INT-132, INT-134, INT-136, INT-137, INT-146 |
| Equipment | INT-003, INT-004, INT-015, INT-031 |
| Food | INT-010, INT-011, INT-027, INT-028, INT-042, INT-047, INT-054, INT-072, INT-079, INT-096, INT-099, INT-124, INT-128, INT-129, INT-138, INT-141, INT-145, INT-147 |
| Health | INT-004, INT-010, INT-011, INT-012, INT-016, INT-018, INT-033, INT-080, INT-083, INT-108, INT-139, INT-141, INT-142, INT-145 |
| Combat | INT-004, INT-012, INT-013, INT-032, INT-068, INT-088, INT-108 |
| Crime | INT-007, INT-008, INT-013, INT-031, INT-032, INT-038, INT-039, INT-043, INT-044, INT-045, INT-046, INT-048, INT-050, INT-051, INT-064, INT-067, INT-068, INT-069, INT-100, INT-102, INT-109, INT-117, INT-146, INT-148 |
| Loot | INT-015, INT-016, INT-018, INT-028, INT-030, INT-086, INT-113, INT-117 |
| Fields | INT-007, INT-009, INT-025, INT-029, INT-046, INT-051, INT-064, INT-067, INT-068, INT-089, INT-122, INT-123, INT-124, INT-125, INT-130 |
| Resources | INT-004, INT-005, INT-006, INT-029, INT-035, INT-037, INT-040, INT-057, INT-065, INT-066, INT-067, INT-068, INT-069, INT-070, INT-071, INT-074, INT-076, INT-103, INT-106, INT-111, INT-121, INT-140, INT-141, INT-143, INT-145, INT-147 |
| Crafting | INT-021, INT-035, INT-036, INT-051, INT-058, INT-067, INT-069, INT-070, INT-073, INT-075, INT-083, INT-092, INT-099, INT-103, INT-107, INT-114, INT-129, INT-132, INT-133, INT-138, INT-139, INT-141, INT-142, INT-143, INT-144 |
| Market | INT-019, INT-020, INT-024, INT-025, INT-026, INT-035, INT-036, INT-037, INT-041, INT-042, INT-043, INT-045, INT-047, INT-050, INT-051, INT-055, INT-059, INT-060, INT-065, INT-066, INT-067, INT-069, INT-072, INT-073, INT-075, INT-076, INT-083, INT-103, INT-108, INT-114, INT-116, INT-117, INT-118, INT-119, INT-120, INT-124, INT-125, INT-128, INT-129, INT-131, INT-134, INT-135, INT-136, INT-137, INT-138, INT-139, INT-141, INT-142, INT-143, INT-144, INT-146, INT-147, INT-148 |
| Coins | INT-003, INT-008, INT-014, INT-015, INT-016, INT-017, INT-019, INT-020, INT-022, INT-023, INT-026, INT-035, INT-036, INT-038, INT-044, INT-045, INT-046, INT-052, INT-053, INT-056, INT-057, INT-059, INT-060, INT-062, INT-065, INT-066, INT-072, INT-073, INT-075, INT-083, INT-090, INT-091, INT-102, INT-108, INT-116, INT-118, INT-119, INT-120, INT-125, INT-127, INT-129, INT-131, INT-134, INT-135, INT-136, INT-137, INT-138, INT-139, INT-141, INT-142, INT-143, INT-144 |
| Treasury | INT-008, INT-022, INT-023, INT-024, INT-025, INT-026, INT-031, INT-036, INT-045, INT-052, INT-053, INT-056, INT-057, INT-060, INT-062, INT-063, INT-066, INT-091, INT-102, INT-116, INT-120, INT-129, INT-131, INT-134 |
| Wages | INT-023, INT-029, INT-059, INT-066, INT-083 |
| Relief | INT-024, INT-047, INT-066 |
| Granary | INT-024, INT-025, INT-031, INT-047, INT-054, INT-066, INT-089 |
| Households | INT-016, INT-017, INT-022, INT-024, INT-027, INT-029, INT-038, INT-039, INT-042, INT-043, INT-047, INT-048, INT-050, INT-051, INT-053, INT-054, INT-059, INT-060, INT-062, INT-064, INT-066, INT-072, INT-073, INT-075, INT-078, INT-079, INT-080, INT-093, INT-095, INT-096, INT-100, INT-102, INT-118, INT-119, INT-134, INT-135, INT-136, INT-138, INT-141, INT-142, INT-143, INT-145, INT-146, INT-147, INT-148 |
| Employment | INT-017, INT-023, INT-029, INT-037, INT-046, INT-047, INT-055, INT-059, INT-063, INT-066, INT-067, INT-074, INT-075, INT-078, INT-080, INT-083, INT-084, INT-085, INT-089, INT-112, INT-114, INT-119, INT-133, INT-135, INT-136, INT-137, INT-139 |
| Inheritance | INT-017, INT-062, INT-075, INT-080 |
| Livestock | INT-009, INT-013, INT-017, INT-027, INT-031, INT-033, INT-051, INT-067, INT-077, INT-081, INT-113, INT-126, INT-127, INT-128, INT-137, INT-145 |
| Wildlife | INT-014, INT-028, INT-029, INT-033, INT-067, INT-068, INT-077, INT-081, INT-086, INT-113, INT-127 |
| Bandits | INT-012, INT-014, INT-050 |
| Building | INT-018, INT-026, INT-030, INT-031, INT-036, INT-048, INT-051, INT-052, INT-054, INT-056, INT-057, INT-059, INT-060, INT-065, INT-066, INT-067, INT-069, INT-070, INT-079, INT-090, INT-091, INT-092, INT-093, INT-094, INT-119, INT-126, INT-130, INT-132, INT-133, INT-148 |
| Workshops | INT-021, INT-030, INT-058, INT-085, INT-092, INT-107 |
| Ledger | INT-007, INT-008, INT-009, INT-010, INT-019, INT-020, INT-021, INT-030, INT-046, INT-054, INT-065, INT-066, INT-083, INT-125 |
| Save | INT-001, INT-002, INT-031, INT-034, INT-038, INT-039, INT-042, INT-045, INT-046, INT-048, INT-059, INT-060, INT-062, INT-066, INT-067, INT-070, INT-071, INT-074, INT-075, INT-076, INT-077, INT-082, INT-084, INT-086, INT-087, INT-094, INT-098, INT-104, INT-105, INT-115, INT-116, INT-120, INT-126, INT-128, INT-130, INT-132, INT-134, INT-146, INT-148 |
| Interface | INT-001, INT-002, INT-004, INT-012, INT-032, INT-033, INT-034, INT-039, INT-040, INT-041, INT-042, INT-044, INT-046, INT-049, INT-050, INT-052, INT-057, INT-058, INT-061, INT-062, INT-066, INT-068, INT-069, INT-070, INT-071, INT-074, INT-076, INT-077, INT-078, INT-081, INT-082, INT-084, INT-085, INT-086, INT-087, INT-088, INT-095, INT-096, INT-097, INT-098, INT-100, INT-112, INT-140, INT-142, INT-146, INT-148 |
| Containers | INT-031, INT-042, INT-043, INT-051, INT-054, INT-055, INT-100, INT-101, INT-104, INT-146 |
| Interiors | INT-008, INT-014, INT-048, INT-049, INT-050, INT-058, INT-060, INT-079, INT-084, INT-088, INT-092, INT-093, INT-094, INT-110, INT-111, INT-138 |
| Property | INT-017, INT-018, INT-026, INT-030, INT-031, INT-051, INT-052, INT-053, INT-054, INT-055, INT-056, INT-057, INT-058, INT-060, INT-061, INT-067, INT-074, INT-075, INT-090, INT-091, INT-100, INT-121, INT-122, INT-126, INT-130, INT-142 |
| Calendar | INT-077, INT-123, INT-147 |
| Family | INT-077, INT-078, INT-079, INT-080, INT-148 |
| Overworld | INT-071, INT-074, INT-076, INT-087 |

<!-- index:end -->
