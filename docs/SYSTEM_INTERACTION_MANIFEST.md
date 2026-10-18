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
- **Building** — plots, frames, delivered materials, houses
- **Ledger** — `World.stats` counters used by the economy reports
- **Save** — saving, loading and migrating older saves
- **Interface** — panels, HUD, touch controls

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
- **Expected:** A handful (`harvest_handful`) leaves the field's crop and goes to the pack, counted as made wheat. When the crop is gone the field is tilled. A field worked by farmers is theft from them (INT-008).
- **Tests:** `game/tests/run_tests.gd::test_player_actions`, `game/tests/start_test.gd`

### INT-008 · Theft is witnessed
- **Trigger:** The player takes something that belongs to someone (today: wheat from a farmed field).
- **Source:** `game/scripts/core/world.gd::witness`
- **Affects:** Crime, Ledger
- **Expected:** Villagers within `witness_radius` (not bandits) remember it, the victim notices the loss, the player's crime record gains an entry, and the log says so if anyone saw. There is no penalty yet. Punishment is not designed.
- **Tests:** `game/tests/run_tests.gd::test_player_actions`, `game/tests/start_test.gd`

### INT-009 · Harvesting a field (farmers)
- **Trigger:** A farmer's plan reaches a ripe field.
- **Source:** `game/scripts/core/npc_brain.gd::_farmer`, `game/scripts/core/world.gd::take_crop`, `game/scripts/core/world.gd::_on_hour`
- **Affects:** Fields, Inventory, Livestock, Ledger
- **Expected:** The farmer takes what crop is left. A field ripens hourly once grown and holds `field_yield`. Whoever harvests a keeper's field carries feed to the pen first.
- **Tests:** `game/tests/run_tests.gd::test_food_rules`, `game/tests/run_tests.gd::test_simulation`

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
- **Expected:** At zero hunger, health falls; at zero health the player or villager dies (INT-016, INT-018).
- **Tests:** `game/tests/run_tests.gd::test_simulation`, `game/tests/scenarios.gd`

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
- **Affects:** Bandits, Coins, Inventory, Wildlife
- **Expected:** Half the victim's coins and one item the victim's job does not keep move to the bandit; nothing is created. Guards fight bandits.
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
- **Affects:** Inheritance, Households, Coins, Employment, Livestock
- **Expected:** Food goes to the pantry. Coins and goods go to the heir: an adult, else an elder, else a child, lowest id first. A household with nobody left leaves the goods where they fell. The household's reckoning reruns at once. Pens pass on (INT-027).
- **Tests:** `game/tests/run_tests.gd::test_households_and_work`, `game/tests/scenarios.gd`

### INT-018 · Player death and the heir
- **Trigger:** The player's health reaches zero.
- **Source:** `game/scripts/core/world.gd::damage_player`, `game/scripts/core/world.gd::continue_as_heir`, `game/scripts/core/world.gd::give_start_kit`, `game/scripts/main.gd::continue_as_heir`
- **Affects:** Health, Character, Player state, Loot, Building
- **Expected:** What the dead carried lies where they fell, for anyone to take, the heir too. The heir keeps the house, chest and plots, starts every skill from nothing and carries only the starting kit, whose coins are counted in `coin_sources`. Anyone fighting the dead player stops; the heir inherits no fight. The world is not reset.
- **Tests:** `game/tests/play_test.gd`, `game/tests/run_tests.gd::test_player_actions`

### INT-019 · Trade
- **Trigger:** The player or a villager buys or sells.
- **Source:** `game/scripts/core/world.gd::trade`, `game/scripts/core/world.gd::sell_price`, `game/scripts/core/world.gd::buy_price`, `game/scripts/core/npc_brain.gd::_plan_sell`
- **Affects:** Market, Coins, Inventory, Ledger
- **Expected:** Atomic: the goods and coins both move, or neither does. Traders keep their cash floor. Prices follow stock.
- **Tests:** `game/tests/run_tests.gd::test_trade_is_atomic`, `game/tests/play_test.gd`

### INT-020 · The caravan
- **Trigger:** Noon on caravan days.
- **Source:** `game/scripts/core/npc_brain.gd::caravan`
- **Affects:** Market, Coins, Ledger
- **Expected:** The only source of new coins (counted in `coin_sources`). It does not buy food while the village holds under 3 days of it.
- **Tests:** `game/tests/run_tests.gd::test_simulation`

### INT-021 · Crafting and stations
- **Trigger:** The player makes a recipe at a station; a villager plans a recipe.
- **Source:** `game/scripts/main.gd::craft`, `game/scripts/core/npc_brain.gd::_do_recipe`, `game/scripts/core/npc_brain.gd::_station_for`, `game/scripts/core/npc_brain.gd::release_station`, `game/data/recipes.json`
- **Affects:** Crafting, Inventory, Player state, Ledger
- **Expected:** Inputs are removed and outputs added together. A villager reserves a free station first (capacity 1) and frees it when done. When all are taken it does something else, counted as `station_busy_<station>`.
- **Tests:** `game/tests/run_tests.gd::test_households_and_work`, `game/tests/play_test.gd`

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
- **Expected:** The sage, reeve, guards and manor hands are paid from the treasury. The newest hand is let go when two days of wages cannot be paid. Day labour pays an adult of a short household who has earned nothing that day.
- **Tests:** `game/tests/run_tests.gd::test_government`, `game/tests/run_tests.gd::test_households_and_work`

### INT-024 · Relief
- **Trigger:** A household can cover under 2 days of food.
- **Source:** `game/scripts/core/npc_brain.gd::_relief`, `game/scripts/core/npc_brain.gd::household_food_days`, `game/scripts/core/npc_brain.gd::_note_relief`
- **Affects:** Relief, Treasury, Granary, Households, Market
- **Expected:** Food goes into the pantry up to 3 days, from the granary first, then bought. Under 1 day of food it is paid below the reserve, down to one day of wages. Cash counts as food only up to the market's share. Chronic relief is named in the log.
- **Tests:** `game/tests/run_tests.gd::test_government`

### INT-025 · Granary purchases
- **Trigger:** The manor's evening business.
- **Source:** `game/scripts/core/npc_brain.gd::surplus_wheat`, `game/scripts/core/npc_brain.gd::keep_wheat`, `game/scripts/core/npc_brain.gd::reeve_day`
- **Affects:** Granary, Treasury, Market, Fields
- **Expected:** Only genuine surplus is bought: never a farmer's household food, feed reserve or buffer, never in a famine. The granary starts with 7 days of food and is finite.
- **Tests:** `game/tests/run_tests.gd::test_government`, `game/tests/scenarios.gd`

### INT-026 · Repairs and plot sales
- **Trigger:** The evening business (repairs); the player buys a plot.
- **Source:** `game/scripts/core/npc_brain.gd::reeve_day`, `game/scripts/core/world.gd::buy_plot`
- **Affects:** Treasury, Market, Coins, Building
- **Expected:** Repairs are bought from village sellers with money beyond 3 days of wages. A plot's price goes to the treasury.
- **Tests:** `game/tests/run_tests.gd::test_government`, `game/tests/play_test.gd`

### INT-027 · Pens and keepers
- **Trigger:** Hourly animal update; a keeper's day; a keeper dies or changes job.
- **Source:** `game/scripts/core/fauna.gd::tick`, `game/scripts/core/fauna.gd::feed`, `game/scripts/core/fauna.gd::new_day`, `game/scripts/core/npc_brain.gd::_keeper`, `game/scripts/core/npc_brain.gd::_hand_over_pens`
- **Affects:** Livestock, Food, Inventory, Households
- **Expected:** Animals eat feed from the trough or starve. A fed pair breeds, and babies grow up. Keepers feed from their own wheat, the pantry or bought feed, and slaughter surplus. A pen passes to another farmer, the same household first.
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
- **Expected:** A household is sustainable when income covers cost, or it holds 10 days of food or runway. Adults of an unsustainable household, and the unemployed, move to an opening that pays at least 25% (and 2 coins) more. Cooldowns apply.
- **Tests:** `game/tests/run_tests.gd::test_households_and_work`, `game/tests/scenarios.gd`

### INT-030 · Building a house
- **Trigger:** The player delivers materials to their plot.
- **Source:** `game/scripts/core/world.gd::start_site`, `game/scripts/core/world.gd::deliver`, `game/scripts/core/world.gd::site_progress`, `game/scripts/core/world.gd::cancel_site`, `game/scripts/main.gd::_sync_sites`
- **Affects:** Building, Inventory, Loot
- **Expected:** Materials are consumed as delivered. The house stands when 30 planks, 20 stone and 10 logs are in, with no extra build time. A progress bar over the frame and in the build window shows the share of loads delivered. Giving up the site returns every delivered load (to the pack, or a bundle at the site if it is full); no coin moves. The two plots are clear land at the forest edge north of the east houses; no plot overlaps a building, field, pen or stall.
- **Tests:** `game/tests/play_test.gd`, `game/tests/run_tests.gd::test_building_site`

### INT-031 · Saving and loading
- **Trigger:** Save from the menu, resting, leaving the app, starting a new game; Continue on the title.
- **Source:** `game/scripts/main.gd::save_game`, `game/scripts/main.gd::continue_game`, `game/scripts/core/world.gd::to_dict`, `game/scripts/core/world.gd::load_dict`, `game/scripts/core/world.gd::_move_plots_to_map`, `game/scripts/core/player_state.gd::to_dict`
- **Affects:** Save, Character, Player state, Inventory, Equipment, Crime, Treasury, Granary, Livestock, Building
- **Expected:** Written atomically as save_version 3. Versions 1 and 2 load, with no coin lost. Fields added later (sex, look, tool, crimes) load with defaults. A tree's tiles are taken from the map on load (saves from before two-tile trees hold other tiles); its state and regrowth day come from the save. Saves from before the building plots moved (they lay over houses b20-b22) move each plot to its place on the map with its owner, site and house, and the player with it if they stood on it; saved trees the map no longer has (cleared for the plots) are dropped. An unreadable save is kept and a new game starts.
- **Tests:** `game/tests/run_tests.gd::test_save_round_trip`, `game/tests/run_tests.gd::test_player_actions`, `game/tests/start_test.gd`

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
- **Source:** `game/scripts/core/npc_brain.gd::reeve_day`, `game/scripts/core/npc_brain.gd::_public_works`
- **Affects:** Treasury, Market, Coins, Crafting
- **Expected:**
  - Repairs buy planks, stone, logs and iron bars.
  - While a reeve lives, public works spend `public_works_share` of the treasury beyond its tax-holiday level on planks, iron bars and stone, at most `public_works_max_loads`. Sellers keep `public_works_seller_keeps`.
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
- **Affects:** Households, Inventory, Coins, Crime, Save
- **Expected:**
  - Offers come only from villagers whose condition holds (job or role, holding too little of something, a household short of food, a living bandit who robbed them), at most `quest_max_offers`.
  - Accepting moves an offer to the player's quests (at most `quest_max_active`).
  - Completing moves the asked-for goods to the giver and up to the reward in coins from the giver's purse to the player; coins are conserved.
  - A giver's death fails a side quest. Offers and accepted quests are saved.
  - Story quests start with every new player and every heir, and on loading a save from before they existed. Their giver shows the story marker, a green pennant, until done; a villager with an offer shows what the quest is about (scroll for a skill, wheat for food, iron for ore, crossed swords for combat, a log, an axe). A giver who is inside their own home shows the marker over the house door instead; givers at work (the tavern, the smithy) are seen and marked as usual. Markers draw over roofs and tree canopies. "The sage in the north" is done when the player learns Fireball.
  - In conversation: "Need any help?" hears an offer, then "I'll do it" or "Not now"; "Here you are" hands in a ready quest. A quest giver always stops to talk, even when busy (INT-039). The journal has a Quests page.
- **Tests:** `game/tests/run_tests.gd::test_quests`, `game/tests/start_test.gd`

### INT-039 · Talking to a villager: conversation or a called-out line
- **Trigger:** The player uses a villager in front of them, or reaches one they tapped.
- **Source:** `game/scripts/main.gd::approach`, `game/scripts/main.gd::say`, `game/scripts/main.gd::_sync_bubbles`, `game/scripts/ui/dialogue.gd::busy`, `game/scripts/ui/dialogue.gd::brush_off`, `game/scripts/ui/dialogue.gd::opening`, `game/scripts/ui/dialogue.gd::meet`, `game/scripts/ui/dialogue.gd::animal_killed`, `game/scripts/core/npc.gd::remember`, `game/scripts/main.gd::_crime`, `game/scripts/ui/game_ui.gd::show_talk`, `game/scripts/view/speech_bubble.gd`
- **Affects:** Interface, Crime, Households, Save
- **Expected:**
  - A villager who is busy (the current plan step is a walk, or work with the working animation, or they are fighting) calls out one line in a speech bubble over their head for 2.5 s and carries on; the talk window does not open. At most one bubble per villager. Bandits always get the talk window.
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

## Reverse dependency index

<!-- index:start (generated by tools/check_interactions.py --write) -->

| System | Interactions |
|---|---|
| Character | INT-001, INT-018, INT-031 |
| Player state | INT-003, INT-004, INT-005, INT-006, INT-018, INT-021, INT-031 |
| Inventory | INT-003, INT-005, INT-006, INT-007, INT-009, INT-010, INT-014, INT-015, INT-019, INT-021, INT-027, INT-028, INT-030, INT-031, INT-032, INT-038 |
| Equipment | INT-003, INT-004, INT-015, INT-031 |
| Food | INT-010, INT-011, INT-027, INT-028 |
| Health | INT-004, INT-010, INT-011, INT-012, INT-016, INT-018, INT-033 |
| Combat | INT-004, INT-012, INT-013, INT-032 |
| Crime | INT-007, INT-008, INT-013, INT-031, INT-032, INT-038, INT-039 |
| Loot | INT-015, INT-016, INT-018, INT-028, INT-030 |
| Fields | INT-007, INT-009, INT-025, INT-029 |
| Resources | INT-004, INT-005, INT-006, INT-029, INT-035, INT-037, INT-040 |
| Crafting | INT-021, INT-035, INT-036 |
| Market | INT-019, INT-020, INT-024, INT-025, INT-026, INT-035, INT-036, INT-037 |
| Coins | INT-003, INT-014, INT-015, INT-016, INT-017, INT-019, INT-020, INT-022, INT-023, INT-026, INT-035, INT-036, INT-038 |
| Treasury | INT-022, INT-023, INT-024, INT-025, INT-026, INT-031, INT-036 |
| Wages | INT-023, INT-029 |
| Relief | INT-024 |
| Granary | INT-024, INT-025, INT-031 |
| Households | INT-016, INT-017, INT-022, INT-024, INT-027, INT-029, INT-038, INT-039 |
| Employment | INT-017, INT-023, INT-029, INT-037 |
| Inheritance | INT-017 |
| Livestock | INT-009, INT-013, INT-017, INT-027, INT-031, INT-033 |
| Wildlife | INT-014, INT-028, INT-029, INT-033 |
| Bandits | INT-012, INT-014 |
| Building | INT-018, INT-026, INT-030, INT-031 |
| Ledger | INT-007, INT-008, INT-009, INT-010, INT-019, INT-020, INT-021 |
| Save | INT-001, INT-002, INT-031, INT-034, INT-038, INT-039 |
| Interface | INT-001, INT-002, INT-004, INT-032, INT-033, INT-034, INT-039, INT-040 |

<!-- index:end -->
