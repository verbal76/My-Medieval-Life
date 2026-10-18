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
- **Expected:** The deposit loses what is mined and the ore goes to the pack. The pick's speed sets the time; the pick wears and can break, emptying the tool slot. Mining XP is gained. Gold needs Mining 3.
- **Tests:** `game/tests/start_test.gd`, `game/tests/play_test.gd`, `game/tests/run_tests.gd::test_simulation`

### INT-006 · Felling a tree
- **Trigger:** The player interacts with a tree holding an axe; or a woodcutter works.
- **Source:** `game/scripts/main.gd::interact`, `game/scripts/core/world.gd::fell`, `game/scripts/core/npc_brain.gd::_woodcutter`
- **Affects:** Resources, Inventory, Player state
- **Expected:** The tree becomes a stump and gives logs. The axe wears. Its whole canopy (both tiles) goes and the trunk cell becomes walkable; a sapling and then the full tree, with its solid trunk, come back on regrowth (INT-040).
- **Tests:** `game/tests/play_test.gd`, `game/tests/run_tests.gd::test_tree_canopy`

### INT-007 · Harvesting a field (player)
- **Trigger:** The player interacts with a ripe field.
- **Source:** `game/scripts/main.gd::interact`, `game/scripts/core/world.gd::player_harvest`, `game/scripts/core/world.gd::take_crop`
- **Affects:** Fields, Inventory, Ledger, Crime
- **Expected:** A handful (`harvest_handful`) leaves the field's crop and goes to the pack, counted as made wheat. When the crop is gone the field is tilled. A field is the manor's (INT-051) and its crop its farmers' (those whose workplace it is, `World.field_workers`): taking it is theft from the first of them (INT-008), except the wheat a farmer hired the player to cut there (INT-046); a farmer who has left the field is never named.
- **Tests:** `game/tests/run_tests.gd::test_player_actions`, `game/tests/run_tests.gd::test_hiring`, `game/tests/start_test.gd`

### INT-008 · Theft is witnessed
- **Trigger:** The player takes something that belongs to someone: wheat from a farmed field, anything from a container or an unattended stall (INT-043), or a pocket picked or tried (INT-044).
- **Source:** `game/scripts/core/world.gd::witness`, `game/scripts/core/world.gd::guard_confront`, `game/scripts/core/world.gd::near`
- **Affects:** Crime, Ledger, Coins, Treasury, Inventory, Interiors
- **Expected:** Villagers within `witness_radius` (not bandits) who are awake and in the same place as the player (inside the same building, or both outdoors: INT-048) remember it ("saw <player> take <what>"), the victim notices the loss, the player's crime record gains an entry, and the log says so if anyone saw. The goods are marked as stolen from the victim (INT-045). A guard among those who saw it stops the player (agent proposal): what was taken goes back where it came from (the field's farmer, the container), the player pays `theft_fine` to the treasury, and a player who cannot pay it all pays what they have and is fought, as for an attack (INT-013). Only goods and coins move.
- **Tests:** `game/tests/run_tests.gd::test_player_actions`, `game/tests/run_tests.gd::test_theft_and_shops`, `game/tests/run_tests.gd::test_interiors`, `game/tests/start_test.gd`

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
- **Source:** `game/scripts/main.gd::attack`, `game/scripts/main.gd::_hit`, `game/scripts/core/npc_brain.gd::fight`
- **Affects:** Combat, Health, Bandits
- **Expected:** The bandit loses health by the player's damage less its armour and turns on the player, damaging them each second within reach. A bandit below 30% health flees to camp. Combat XP is gained.
- **Tests:** `game/tests/start_test.gd`, `game/tests/play_test.gd`

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
- **Expected:** Food goes to the pantry. Coins and goods go to the heir: an adult, else an elder, else a child, lowest id first. A household with nobody left leaves the goods where they fell, and its house, leases and stores go to the manor (INT-054). The household's reckoning reruns at once. Pens pass on (INT-027); a merchant's stall falls vacant (INT-055).
- **Tests:** `game/tests/run_tests.gd::test_households_and_work`, `game/tests/scenarios.gd`

### INT-018 · Player death and the heir
- **Trigger:** The player's health reaches zero.
- **Source:** `game/scripts/core/world.gd::damage_player`, `game/scripts/core/world.gd::continue_as_heir`, `game/scripts/core/world.gd::give_start_kit`, `game/scripts/main.gd::continue_as_heir`
- **Affects:** Health, Character, Player state, Loot, Building, Property
- **Expected:** What the dead carried lies where they fell, for anyone to take, the heir too. The heir keeps the home, the chest and everything the family owns or leases (all held as "player", INT-051), starts every skill from nothing and carries only the starting kit, whose coins are counted in `coin_sources`. Anyone fighting the dead player stops; the heir inherits no fight. The world is not reset.
- **Tests:** `game/tests/play_test.gd`, `game/tests/run_tests.gd::test_player_actions`, `game/tests/run_tests.gd::test_property`

### INT-019 · Trade
- **Trigger:** The player or a villager buys or sells.
- **Source:** `game/scripts/core/world.gd::trade`, `game/scripts/core/world.gd::sell_price`, `game/scripts/core/world.gd::buy_price`, `game/scripts/core/npc_brain.gd::_plan_sell`
- **Affects:** Market, Coins, Inventory, Ledger
- **Expected:** Atomic: the goods and coins both move, or neither does. Traders keep their cash floor. Prices follow stock. The player sells through `World.player_sell`, which handles stolen goods first (INT-045).
- **Tests:** `game/tests/run_tests.gd::test_trade_is_atomic`, `game/tests/play_test.gd`

### INT-020 · The caravan
- **Trigger:** Noon on caravan days.
- **Source:** `game/scripts/core/npc_brain.gd::caravan`
- **Affects:** Market, Coins, Ledger
- **Expected:** The only source of new coins (counted in `coin_sources`). It does not buy food while the village holds under 3 days of it, days of its age-weighted need (INT-047).
- **Tests:** `game/tests/run_tests.gd::test_simulation`, `game/tests/run_tests.gd::test_child_food`

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
- **Expected:** The sage, reeve, guards and manor hands are paid from the treasury. The newest hand is let go when two days of wages cannot be paid. Day labour pays an adult of a short household who has earned nothing that day. A manor hand hired out for the day to carry building materials (INT-059) is paid by the employer, not the manor, that day.
- **Tests:** `game/tests/run_tests.gd::test_government`, `game/tests/run_tests.gd::test_households_and_work`

### INT-024 · Relief
- **Trigger:** A household can cover under 2 days of food.
- **Source:** `game/scripts/core/npc_brain.gd::_relief`, `game/scripts/core/npc_brain.gd::household_food_days`, `game/scripts/core/npc_brain.gd::_note_relief`
- **Affects:** Relief, Treasury, Granary, Households, Market
- **Expected:** Food goes into the pantry up to 3 days, from the granary first, then bought. Under 1 day of food it is paid below the reserve, down to one day of wages. Cash counts as food only up to the market's share. Chronic relief is named in the log. Days and the fill are measured against the household's age-weighted need (INT-047).
- **Tests:** `game/tests/run_tests.gd::test_government`, `game/tests/run_tests.gd::test_child_food`

### INT-025 · Granary purchases
- **Trigger:** The manor's evening business.
- **Source:** `game/scripts/core/npc_brain.gd::surplus_wheat`, `game/scripts/core/npc_brain.gd::keep_wheat`, `game/scripts/core/npc_brain.gd::reeve_day`
- **Affects:** Granary, Treasury, Market, Fields
- **Expected:** Only genuine surplus is bought: never a farmer's household food, feed reserve or buffer, never in a famine. The granary starts with 7 days of food and is finite. The household food, the target and the start are age-weighted (INT-047).
- **Tests:** `game/tests/run_tests.gd::test_government`, `game/tests/run_tests.gd::test_child_food`, `game/tests/scenarios.gd`

### INT-026 · Repairs and land sales
- **Trigger:** The evening business (repairs); the player buys, leases or sells land or a house (INT-052).
- **Source:** `game/scripts/core/npc_brain.gd::reeve_day`, `game/scripts/core/world.gd::buy_plot`, `game/scripts/core/property.gd::buy`, `game/scripts/core/property.gd::lease`, `game/scripts/core/property.gd::sell`
- **Affects:** Treasury, Market, Coins, Building, Property
- **Expected:** Repairs are bought from village sellers with money beyond 3 days of wages. A plot's price (`plot_price`, provisional) and every sale or rent go to the treasury; a house sold back is paid from it (`gov_land_sales`, `gov_rent`, `gov_land_bought`). The treasury's level then decides wages, repairs and works as before.
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
- **Expected:** Written atomically as save_version 6 (`World.SAVE_VERSION`; 6 adds each site's kind, workshops with their stamp and leave list, the day's hired helpers with what they carry, and founded households with where they came from; version 5 saves load with every site a house's and every built house drawn from the house stamp, `World._migrate_construction`, and nothing moves; villagers have no "hidden" flag: where they are is their position, inside a building or not; every property record carries its owner and tenant references, leases their rent, due day and arrears, `next_parcel` counts claimed parcels, a settled household is `ended`; the player has no plot list). Versions 1-4 load, with no coin lost: plot owners ""/"player" (and the player's plot list) become the manor's or the player's, a field's farmer ids give way to the manor's ownership (its farmers are those working it), a stall's and a pen's NPC id become their tenant reference (a dead one leaves it vacant), buildings get their starting owners and a house the player built is theirs on its plot, and a household that had died out gives its house and stores to the manor (INT-054); plots, houses and the player stay exactly where they are (`World._migrate_property`). Versions 1-3 also: their villagers "hidden" at home (standing on the door step) are moved inside, each to their own bed's spot (`World._move_indoors`). Fields added later (sex, look, tool, crimes, the stolen marks) load with defaults. The tavern tables' dishes are saved ("containers"); a save from before containers loads with its tables set from the keepers' stock (INT-042). A tree's tiles are taken from the map on load (saves from before two-tile trees hold other tiles); its state and regrowth day come from the save. Saves from before the building plots moved (they lay over houses b20-b22) move each plot to its place on the map with its owner, site and house, and the player with it if they stood on it; saved trees the map no longer has (cleared for the plots) are dropped. An unreadable save is kept and a new game starts.
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
  - The coins leave the village: `coin_sources` falls by what was spent, so coins stay conserved.
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
  - Completing moves the asked-for goods to the giver and up to the reward in coins from the giver's purse to the player; coins are conserved.
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
  - village.json lists the crates and barrels by each house, in and around the tavern and beside each stall, and each dish or mug drawn on a tavern table (no map tile moves).
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
  - Handing in moves the goods to the employer and the whole wage from their purse to the player (`hired_wages`); an employer who cannot pay keeps nothing and pays nothing. No coins are created.
  - A hired harvest hand cuts up to the hired amount from the employer's field without theft; the field's farmers leave it meanwhile. Undone work lapses after its `days`; it fails if the employer dies. Accepted work is saved with the player's quests.
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
- **Source:** `game/scripts/core/construction.gd::daily`, `game/scripts/core/construction.gd::crowded`, `game/scripts/core/construction.gd::founder_of`, `game/scripts/core/construction.gd::_found`, `game/scripts/core/construction.gd::_home_plan`, `game/scripts/core/construction.gd::_find_home`, `game/scripts/core/construction.gd::find_ground`, `game/scripts/core/construction.gd::_keep_building`, `game/scripts/core/construction.gd::on_finished`, `game/scripts/core/construction.gd::move_in`, `game/scripts/core/construction.gd::_rehouse`, `game/scripts/core/world.gd::home_spot`, `game/scripts/core/world.gd::_new_day`
- **Affects:** Households, Building, Property, Coins, Treasury, Market, Interiors, Save
- **Expected:** Owner rule: when a household is too big for its house and can afford it, a grown member founds a household. Only when the family keeps `split_keep_base` + `split_keep_per_member` a member staying behind, after giving the founder what the new home costs; at most one split a day. The new household (same family, a new index appended to the list, `founded_from`) gets, by the property API only: an empty house on the market (bought, or leased with two weeks' rent in hand) and moves in at once; else the manor's surveyed ground (a clearing) or new legal ground as near home as can be found, bought, a house marked out and built by the player's rules (hiring a helper each morning, or the founder carrying with no wage), then moves in (every member's home is the house). Until then the founder lodges with the family, on the house's next free sleeping place. A household that loses its house lodges with the family it came from and looks for a home again. Coins and goods only move.
- **Tests:** `game/tests/run_tests.gd::test_households_split`, `game/tests/households_sim.gd`

### INT-061 · Places named for the player
- **Trigger:** The land office, a door, a building window, a placement, a village record line names land or a building.
- **Source:** `game/scripts/core/property.gd::describe`, `game/scripts/core/property.gd::building_name`, `game/scripts/core/world.gd::where`, `game/scripts/core/property.gd::can_claim`
- **Affects:** Property, Interface
- **Expected:** No internal id ("plot0", "parcel3", "b7") reaches the player. A building is named for the family who live there or hold it ("the Reed family's house", "the Ashdown family's smithy"), the family that died out ("the Ford family's old house"), or where it stands ("the empty house north of the well"); ground for where it lies, by the nearest landmark ("the clearing north of the Reed family's house", "the ground west of the tavern"); a site for its family and kind. A name two places share gets where the place lies added, never by a landmark of the same name.
- **Tests:** `game/tests/run_tests.gd::test_construction`, `game/tests/start_test.gd`

## Reverse dependency index

<!-- index:start (generated by tools/check_interactions.py --write) -->

| System | Interactions |
|---|---|
| Character | INT-001, INT-018, INT-031 |
| Player state | INT-003, INT-004, INT-005, INT-006, INT-018, INT-021, INT-031, INT-038, INT-044, INT-052, INT-053 |
| Inventory | INT-003, INT-005, INT-006, INT-007, INT-008, INT-009, INT-010, INT-014, INT-015, INT-019, INT-021, INT-027, INT-028, INT-030, INT-031, INT-032, INT-038, INT-043, INT-044, INT-045, INT-046, INT-059 |
| Equipment | INT-003, INT-004, INT-015, INT-031 |
| Food | INT-010, INT-011, INT-027, INT-028, INT-042, INT-047, INT-054 |
| Health | INT-004, INT-010, INT-011, INT-012, INT-016, INT-018, INT-033 |
| Combat | INT-004, INT-012, INT-013, INT-032 |
| Crime | INT-007, INT-008, INT-013, INT-031, INT-032, INT-038, INT-039, INT-043, INT-044, INT-045, INT-046, INT-048, INT-050, INT-051 |
| Loot | INT-015, INT-016, INT-018, INT-028, INT-030 |
| Fields | INT-007, INT-009, INT-025, INT-029, INT-046, INT-051 |
| Resources | INT-004, INT-005, INT-006, INT-029, INT-035, INT-037, INT-040, INT-057 |
| Crafting | INT-021, INT-035, INT-036, INT-051, INT-058 |
| Market | INT-019, INT-020, INT-024, INT-025, INT-026, INT-035, INT-036, INT-037, INT-041, INT-042, INT-043, INT-045, INT-047, INT-050, INT-051, INT-055, INT-059, INT-060 |
| Coins | INT-003, INT-008, INT-014, INT-015, INT-016, INT-017, INT-019, INT-020, INT-022, INT-023, INT-026, INT-035, INT-036, INT-038, INT-044, INT-045, INT-046, INT-052, INT-053, INT-056, INT-057, INT-059, INT-060 |
| Treasury | INT-008, INT-022, INT-023, INT-024, INT-025, INT-026, INT-031, INT-036, INT-045, INT-052, INT-053, INT-056, INT-057, INT-060 |
| Wages | INT-023, INT-029, INT-059 |
| Relief | INT-024, INT-047 |
| Granary | INT-024, INT-025, INT-031, INT-047, INT-054 |
| Households | INT-016, INT-017, INT-022, INT-024, INT-027, INT-029, INT-038, INT-039, INT-042, INT-043, INT-047, INT-048, INT-050, INT-051, INT-053, INT-054, INT-059, INT-060 |
| Employment | INT-017, INT-023, INT-029, INT-037, INT-046, INT-047, INT-055, INT-059 |
| Inheritance | INT-017 |
| Livestock | INT-009, INT-013, INT-017, INT-027, INT-031, INT-033, INT-051 |
| Wildlife | INT-014, INT-028, INT-029, INT-033 |
| Bandits | INT-012, INT-014, INT-050 |
| Building | INT-018, INT-026, INT-030, INT-031, INT-036, INT-048, INT-051, INT-052, INT-054, INT-056, INT-057, INT-059, INT-060 |
| Workshops | INT-021, INT-030, INT-058 |
| Ledger | INT-007, INT-008, INT-009, INT-010, INT-019, INT-020, INT-021, INT-030, INT-046, INT-054 |
| Save | INT-001, INT-002, INT-031, INT-034, INT-038, INT-039, INT-042, INT-045, INT-046, INT-048, INT-059, INT-060 |
| Interface | INT-001, INT-002, INT-004, INT-032, INT-033, INT-034, INT-039, INT-040, INT-041, INT-042, INT-044, INT-046, INT-049, INT-050, INT-052, INT-057, INT-058, INT-061 |
| Containers | INT-031, INT-042, INT-043, INT-051, INT-054, INT-055 |
| Interiors | INT-008, INT-014, INT-048, INT-049, INT-050, INT-058, INT-060 |
| Property | INT-017, INT-018, INT-026, INT-030, INT-031, INT-051, INT-052, INT-053, INT-054, INT-055, INT-056, INT-057, INT-058, INT-060, INT-061 |

<!-- index:end -->
