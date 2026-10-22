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
- **Settlements** — the five neighbouring off-map settlements and their traders: households, businesses, treasuries, markets (SET-C)

## Interactions

### INT-001 · Character creation sets the player
- **Trigger:** The player presses Begin on the creation panel.
- **Source:** `game/scripts/ui/game_ui.gd::show_creation`, `game/scripts/main.gd::new_game`, `game/scripts/view/character_look.gd::render`, `game/data/character_style.json`
- **Affects:** Character, Interface, Save
- **Expected:** A name is required (the family defaults to "Wanderer"). The appearance (CC-01) is a recipe of Puny Characters layers chosen feature by feature or at random within creation's civilian choices; it becomes the player's and the relative heir's look (PlayerState appearance and heir_appearance, saved; a save of version 17 or older migrates its look to the recipe it was baked from) and the player is drawn from it. Appearance only: the starting kit, armour and coins are unchanged. ARMOR-01: worn iron armour and the iron helmet are drawn over that look (view only; the recipe and save are unchanged, taking them off restores it); leather gear draws nothing. The world waits paused on the origin story.
- **Tests:** `game/tests/start_test.gd`, `game/tests/character_look_test.gd`

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
- **Source:** `game/scripts/core/world.gd::player_equip`, `game/scripts/core/world.gd::equip_refusal`, `game/scripts/core/world.gd::player_unequip`, `game/scripts/core/world.gd::unequip_refusal`, `game/scripts/core/player_state.gd::gear_refusal`, `game/scripts/core/world.gd::player_drop`, `game/scripts/core/player_state.gd::damage`, `game/scripts/core/player_state.gd::tool_of`, `game/scripts/core/player_state.gd::defense`, `game/scripts/core/player_state.gd::bonus`, `game/scripts/core/player_state.gd::fit_caps`, `game/scripts/ui/inventory_window.gd::_build_details`, `game/data/items.json`
- **Affects:** Equipment, Combat, Resources, Health, Player state, Interface
- **Expected:** Six gear slots: weapon, tool, armour (body), head, amulet, ring. Only carried items can be equipped, each in the slot its type names. The weapon sets attack damage (unarmed 2). The equipped tool is used first, else the fastest carried one of that kind. Body and head armour add up. Worn items' `bonus` (items.json) raises max health (`hp_cap`) and max stamina (`stamina_cap`); taking one off, or dropping it, brings health and stamina down to the new caps. Head, amulet and ring are saved; an older save loads with them empty. INV-18 (Build 18): the worn unit stays in the one pack store but takes no backpack place (INT-210); taking it off puts it back in its category and is refused, the item staying worn, when that category is full and no other unit of it is carried ("Crafted goods inventory full: 9 of 9 slots."); a swap whose displaced item would need a place in a full category is refused with nothing moved. No unit is made or lost.
- **Tests:** `game/tests/run_tests.gd::test_player_actions`, `game/tests/start_test.gd`, `game/tests/inventory18_test.gd`

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
- **Expected:** A field ripens hourly once grown and holds `field_yield`. When a farmer's cutting completes, the seed kept back goes to that farmer as before and the feed for the pen of any keeper of the field is carried there first; the rest of the crop is shared among the field's farmers cutting it at that moment in proportion to the minutes each has cut (FARM-08-Q-CROP, `Farming.split_crop`: largest remainder, ties to the smaller id), whoever finishes first; the others stop cutting with their share, and a farmer not cutting gets none. Each share tops up its own household pantry to 10. A field whose farmer hired the player to cut it is left to the player while that work is open (INT-046).
- **Tests:** `game/tests/run_tests.gd::test_food_rules`, `game/tests/run_tests.gd::test_simulation`, `game/tests/run_tests.gd::test_hiring`, `game/tests/crop_share_test.gd`

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
- **Expected:** At zero hunger, health falls by `starve_damage_per_hour`, for the player as for a villager (TIME-04; the player's was a literal 3); at zero health the player or villager dies (INT-016, INT-018). A child's hunger falls `child_food_factor` as fast as an adult's (INT-047).
- **Tests:** `game/tests/run_tests.gd::test_simulation`, `game/tests/run_tests.gd::test_child_food`, `game/tests/scenarios.gd`, `game/tests/world_test.gd::_fse_defects`

### INT-012 · Fighting a bandit
- **Trigger:** The player attacks a bandit.
- **Source:** `game/scripts/main.gd::attack`, `game/scripts/main.gd::_swing_step`, `game/scripts/main.gd::_blow`, `game/scripts/main.gd::attack_button`, `game/scripts/main.gd::_chase_step`, `game/scripts/core/combat.gd::press`, `game/scripts/core/combat.gd::target`, `game/scripts/main.gd::_hit`, `game/scripts/core/relations.gd::refusal`, `game/scripts/core/relations.gd::slain_by_player`, `game/scripts/core/world.gd::kill`, `game/scripts/core/npc_brain.gd::fight`
- **Affects:** Combat, Health, Bandits, Interface
- **Expected:** (CQ-01, owner 2026-10-19: sword presses lost, hits needing sprite overlap) A press starts a swing at once (the sword animation shows); the blow lands on the slash frame `player_combat.windup` seconds later, once, on the nearest body within `player_combat.reach` tiles inside the arc ahead or within `close` tiles, with a clear line; foes before bystanders. One press in the last `buffer` seconds of a swing is kept and starts the next swing; others are ignored. The touch Attack button swings at a foe in reach (else toggles attack mode); tap-to-strike walks only into reach. The bandit loses health by the player's damage less its armour and turns on the player, damaging them each second within reach. A bandit below 30% health flees to camp. Combat XP is gained. A swing in progress does not survive loading or a new world.
- **Tests:** `game/tests/combat_test.gd`, `game/tests/start_test.gd`, `game/tests/play_test.gd`

### INT-013 · Attacking villagers or livestock is a crime
- **Trigger:** The player hits a villager, or kills a keeper's animal.
- **Source:** `game/scripts/core/world.gd::player_assault`, `game/scripts/main.gd::_hit_animal`, `game/scripts/core/world.gd::aware_of_attack`, `game/scripts/core/world.gd::raise_alarm`, `game/scripts/core/world.gd::report_crime`, `game/scripts/core/world.gd::deliver_report`, `game/scripts/core/npc_brain.gd::_report`, `game/scripts/core/world.gd::witness`
- **Affects:** Crime, Combat, Livestock
- **Expected:** (PAR-05, owner OD-18.5, 2026-10-20: guards have no unexplained knowledge of an assault) The victim remembers it and an adult victim fights back. Who learns of it is decided by `World.aware_of_attack`, the same for any attacker: those who see it (awake, in the same place, within `witness_radius`) remember it, and the victim knows. There is no hearing (final directive, section 9). Free guards who saw it answer (`World.raise_alarm`); the victim and the other witnesses carry a report (`World.report_crime`, saved on the villager) to a guard: at once if one is in sight, else they walk to the nearest awake guard within `report.range` (`NPCBrain._report`, the `report` step), who then takes on the attacker (`World.deliver_report`). A report lapses after `report.hours` or when the attacker is dead. Nobody else knows. Killing a keeper's animal is a theft from the keeper, known as a theft is (`World.witness`, INT-008): a keeper who sees it remembers who did it and comes after the player; one who does not finds the animal dead.
- **Tests:** `game/tests/play_test.gd`, `game/tests/world_test.gd::_par05_awareness`

### INT-014 · Bandits rob and poach
- **Trigger:** A bandit reaches an ordinary villager, or game near its camp.
- **Source:** `game/scripts/core/npc_brain.gd::_bandit`, `game/scripts/core/npc_brain.gd::fight`, `game/scripts/core/npc_brain.gd::_bandit_seen`, `game/scripts/core/world.gd::aware_of_attack`
- **Affects:** Bandits, Coins, Inventory, Wildlife, Interiors
- **Expected:** Half the victim's coins and one item the victim's job does not keep move to the bandit; nothing is created. Guards fight the bandits they see (within `witness_radius`, in the same place: `NPCBrain._bandit_seen`), and a bandit's robbery or blow is known by the rule any attack is (PAR-05, INT-013: seen, and reported by the victim and witnesses), so the guards who know of it take on the bandit. Bandits only stalk people outdoors; a fight ends when its target falls asleep or goes inside a building the fighter is not in (INT-050). FSE-B06: the band eats only real food, from its stores (the living bandits' packs, the eater's first: food bought at the market, stolen or poached; `NPCBrain.band_eat`); a hungry bandit with nothing to eat poaches, and the carcass (meat, hide) goes into their pack; raw meat is roasted at the camp fire by the oven's recipe on deadwood (no log; an explicit difference put to the owner). Clan children eat from the same stores. With nothing in them the band goes hungry (WDR-022).
- **Tests:** `game/tests/run_tests.gd::test_simulation`, `game/tests/world_test.gd::_par05_awareness`, `game/tests/world_test.gd::_fse_defects`

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
- **Source:** `game/scripts/core/world.gd::trade`, `game/scripts/core/world.gd::sell_price`, `game/scripts/core/world.gd::buy_price`, `game/scripts/core/world.gd::player_quote`, `game/scripts/core/world.gd::player_buy_many`, `game/scripts/core/world.gd::player_sell_many`, `game/scripts/core/world.gd::purchase_qty`, `game/scripts/core/world.gd::sale_prices`, `game/scripts/core/world.gd::sale_refusal`, `game/scripts/ui/quantity_picker.gd::buy_max_priced`, `game/scripts/core/npc_brain.gd::_plan_sell`, `game/scripts/core/npc_brain.gd::_buyer_for`, `game/scripts/core/npc_brain.gd::wants`, `game/scripts/core/npc_brain.gd::batch_unit`
- **Affects:** Market, Coins, Inventory, Ledger
- **Expected:** Atomic: the goods and coins both move, or neither does. Buyers of stock keep their foreseeable-needs reserve (OD-19, INT-158). Prices follow stock. The player sells through `World.player_sell`, which handles stolen goods first (INT-045). What each trade buys, and its stock cap, is `NPCBrain.BUYS`: the goods merchant also takes made rings, amulets and helmets (B7-003, owner 2026-10-18), within its coins and caps. A business buys by real need and funds (SHOP-01, TRADE-01, owner 2026-10-20 section 6): of an input its trade works (the recipes at its stations, `NPCBrain.TRADE_STATIONS`), none when it lacks the skill for every recipe taking it (a smith below Smithing 3 buys no gold ore), otherwise what keeps its holding at or below its want: its `BUYS` stock rounded up to whole batches (`NPCBrain.batch_unit`), capped by that stock (`NPCBrain.wants`); part lots towards a batch are bought (a cook with no milk buys 1 or 2 towards a 3-milk cheese). Goods no recipe of its trade consumes are stock up to `BUYS`. `World.purchase_qty` cuts that need a unit at a time to what its own coins pay for the whole bill above its reserve (OD-19; the reserve's one-unit exception covers a single-unit sale only). It is the one rule for every sale to a business: the player's (`World.player_sell_many`, refused whole with `World.sale_refusal`'s reason: does not buy it, has no use for it, has all it can use, keeps a reserve) and a villager's (`NPCBrain._buyer_for`, the `sell_to` action, one atomic `World.trade` at `World.sale_prices`). The player's Buy and Sell open the shared quantity control (`game/scripts/ui/quantity_picker.gd`, PL1-03). (Build 13, owner economy rules 1 and 2) Each unit of a bulk deal is priced at the stock it leaves (`World.player_quote`): buying runs the seller's stock down, so each unit costs the same or more; selling fills the buyer up, so each unit fetches the same or less; the total is the sum of the unit prices, never the opening price times the quantity. Buy max is the units the player's coins cover in turn (and pack room); sell max is `World.purchase_qty` of what the player carries. Confirm calls `World.player_buy_many` (all or nothing, the bill from the player's own coins) or `World.player_sell_many` (refused whole unless the buyer's own coins cover the whole bill; then a unit at a time through `player_sell` at the live price); a merchant never buys without the coins. Cancel changes nothing. The same control moves stacks to and from the home chest (`World.transfer`; stolen marks move with the quantity, stolen first, PL2-012).
- **Tests:** `game/tests/start_test.gd::_pl_trade_ui_tests`, `game/tests/run_tests.gd::test_trade_is_atomic`, `game/tests/play_test.gd`, `game/tests/run_tests.gd::test_build7_economy`, `game/tests/farming_test.gd::test_market`, `game/tests/world_test.gd::_shop01_need`

### INT-020 · The caravan
- **Trigger:** Noon on caravan days.
- **Source:** `game/scripts/core/npc_brain.gd::caravan`, `game/scripts/core/npc_brain.gd::caravan_line_need`, `game/scripts/core/npc_brain.gd::restock_cost`
- **Affects:** Market, Coins, Ledger
- **Expected:**
  - Not a source of coins any longer (ECON-P1.3, owner 2026-10-23: "their traders, carrying only what they actually have and paying with their actual coins; the daily allowance goes away"): the traders of the neighbouring settlements (`Regions`, INT-230, INT-231) pay from their own tills, so what crosses the village's boundary is a net of coins both ways, logged in `coin_sources` (it falls when the village pays them). It does not buy food while the village holds under 3 days of it, days of its age-weighted need (INT-047).
  - The traders on the road today (`Regions.visiting`: a settlement comes every `ceil(miles / 20)` caravan visits, all five on the first) sell what their stocks hold (INT-035, INT-065) and buy only goods their settlement still wants (`OffMapSettlement.wants`) with coins in the trader's own till above its floor. Removed with the allowance: `World.caravan_purse` and the balance keys `caravan_allowance`, `caravan_float`, `caravan_ceiling_per_head` and `caravan_coins`.
  - It sells first, then buys the surplus at 0.8 x value (never the mine's raw iron ore, copper ore, gold ore, coal or stone, `NPCBrain.NOT_EXPORTED`: they are the forge's and the builders' finite input, B7-007; 79% of the stone mined in the first ten days used to be carried off).  No seller is served first for its trade (EQ-22, owner 2026-10-21: "allocate purchasing according to actual demand and need"; the smiths-first order is gone): it buys one unit at a time, each from the seller that needs the sale most (`NPCBrain.caravan_line_need`: the share of its holding of the good that is surplus over what it keeps, plus the share of the cost of its trade's missing inputs, `NPCBrain.restock_cost`, its coins cannot pay), ties to the lower seller id then item id; a unit sold lowers that need. A short purse goes where the need is: no seller is guaranteed a sale and the purse is not split equally. A trader with no coins buys nothing (the village's currency grows only by what the traders really pay it; the earlier fixed allowance and its measurements in `docs/release/LONG_RUN_SIMULATION.md` are history).
  - Saved: the settlements and their traders' tills are the `regions` section of the save (INT-233); an older save's `caravan_purse` becomes the traders' coins on load (no village coin changes hands).
- **Tests:** `game/tests/run_tests.gd::test_simulation`, `game/tests/run_tests.gd::test_child_food`, `game/tests/run_tests.gd::test_caravan_traders`, `game/tests/regions_test.gd::test_world_caravan`, `game/tests/od16_test.gd::test_caravan_buys_by_need`

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
- **Source:** `game/scripts/core/npc_brain.gd::_relief`, `game/scripts/core/npc_brain.gd::_relief_offers`, `game/scripts/core/npc_brain.gd::household_food_days`, `game/scripts/core/npc_brain.gd::_note_relief`, `game/scripts/core/world.gd::cheapest_food_unit`
- **Affects:** Relief, Treasury, Granary, Households, Market
- **Expected:** The hungriest household first (B7-015: helped by number before, a household with nothing waited behind others and went without). Food goes to the pantry up to 3 days, from the granary first, then bought (FSE-17, the owner's amendment of 2026-10-20: "Relief should check all possible food stores"): cheapest food point first, from every food seller's edible stock (tavern, cook, food merchant; farmers' grain beyond their keep and their pens' eggs and milk), raw meat from hunters and keepers for as many logs as the household holds to roast it, and other households' food beyond their own reserve horizon (OD-19's reserve_days), paid to them at its base value. It is carried there as a manor job (INT-066), or at once when the household has under 1 day of food (then also from grain still at the farmers' for the granary); a household with relief on its way waits for it. Under 1 day of food it is paid below the reserve, down to one day of wages. A household's food is reckoned from all it holds (pantry and members' pockets, meat it can roast; INT-159). Cash counts as food only for what it can buy now (whole units of the cheapest food on sale, `World.cheapest_food_unit`) and only up to the market's share. Chronic relief is named in the log. Days and the fill are measured against the household's age-weighted need (INT-047).
- **Tests:** `game/tests/run_tests.gd::test_government`, `game/tests/run_tests.gd::test_child_food`, `game/tests/reserve_test.gd::relief_sources`

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
- **Source:** `game/scripts/core/fauna.gd::tick`, `game/scripts/core/fauna.gd::feed`, `game/scripts/core/fauna.gd::new_day`, `game/scripts/core/npc_brain.gd::_keeper`, `game/scripts/core/npc_brain.gd::_hand_over_pens`, `game/scripts/core/npc_brain.gd::relet_pens`
- **Affects:** Livestock, Food, Inventory, Households
- **Expected:** Animals eat feed from the trough or starve. A fed pair breeds, and babies grow up. Keepers feed from their own wheat, the pantry or bought feed, and slaughter surplus. A pen is the manor's, let to its keeper (tenant "npc:<id>", `World.pen_keeper`, INT-051); it passes to another farmer, the same household first, and a pen left with no keeper goes at dawn to a farmer with none (FSE-B05; before, its animals starved untended).
- **Tests:** `game/tests/run_tests.gd::test_animals`, `game/tests/run_tests.gd::test_households_and_work`, `game/tests/world_test.gd::_fse_defects`

### INT-028 · Hunting
- **Trigger:** A hunter's plan; the player kills a wild animal.
- **Source:** `game/scripts/core/npc_brain.gd::_hunter`, `game/scripts/main.gd::_hit_animal`, `game/scripts/core/fauna.gd::kill`, `game/scripts/core/fauna.gd::nearest_game`, `game/scripts/core/fauna.gd::takeable_game`
- **Affects:** Wildlife, Loot, Inventory, Food, Employment
- **Expected:** The carcass gives meat (half for a baby) and hide. Hunters never take a kind below 2 adults per wood. Every kill is in the wildlife ledger, the player's included (FSE-B10). A claim on an animal lasts only while its hunter still plans that hunt (FSE-B08). Hunter openings in the job market count only the game hunters may take (FSE-B09; before, every wild adult, wolves and bears included).
- **Tests:** `game/tests/run_tests.gd::test_animals`, `game/tests/play_test.gd`, `game/tests/world_test.gd::_fse_defects`

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
  - Each smith buys up to `caravan_import_stock` at the item's value, keeping their foreseeable-needs reserve (OD-19, INT-158), from a trader on the road that holds the ore or coal (INT-231; Garton's diggings are where it comes from): a trader with none sells none.
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
- **Source:** `game/scripts/main.gd::approach`, `game/scripts/main.gd::say`, `game/scripts/main.gd::_sync_bubbles`, `game/scripts/ui/dialogue.gd::busy`, `game/scripts/ui/dialogue.gd::brush_off`, `game/scripts/ui/dialogue.gd::opening`, `game/scripts/ui/dialogue.gd::meet`, `game/scripts/ui/dialogue.gd::animal_killed`, `game/scripts/core/npc.gd::remember`, `game/scripts/core/world.gd::player_assault`, `game/scripts/ui/game_ui.gd::show_talk`, `game/scripts/view/speech_bubble.gd`
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
- **Source:** `game/scripts/main.gd::_find_target`, `game/scripts/main.gd::_shop_target`, `game/scripts/main.gd::approach`, `game/scripts/main.gd::interact`, `game/scripts/main.gd::_usable_at`, `game/scripts/core/world.gd::at_post`, `game/scripts/core/world.gd::shopkeeper_at`, `game/scripts/core/counters.gd::summon`, `game/scripts/ui/game_ui.gd::show_trade`
- **Affects:** Market, Interface
- **Expected:**
  - A tavern keeper within 2.5 tiles of the counter's use cell, or a merchant within 2.5 tiles of their stall, alive, awake and not fighting, is at their post. The prompt reads "Buy from <name> (tavern)" or "(food stall)" etc., and using it opens their trade window directly, titled "Buy from ...", with a "Talk to <name>" button.
  - Approached at their post, a shopkeeper always serves (the shop opens; never a brush-off bubble), unless they have quest business, which opens the conversation as before (INT-039).
  - Skilled-trade counters (CTR-01..03, ARM-01; `game/scripts/core/counters.gd`): a counter station whose type is in `Counters.KEEPERS` (the Smithy and Armory's `armory_counter`, kept by the smiths) has nobody standing at it. At it, the prompt rings for service; the first keeper able to come (alive, awake, in working hours, not fighting, not hungry enough to eat, not on a building contract) is given a plan to walk there by the ordinary path and serve for `counter_serve_minutes`, renewed while the player stays; work in hand is put down and its station freed (a recipe takes its materials only when done). Serving there, the keeper is at their post (`World.shop_post`), so the ordinary trade window opens. Otherwise the player is told who cannot come and why. One service a counter at a time; a second ring says who is on the way. Not saved (villagers' plans are not). A counter is not a market stall (CTR-04, owner 2026-10-20 section 7): a sale there is the ordinary trade (INT-019) between the player and the serving keeper, and no stall commission is taken.
  - A tapped counter, stall or container is walked to and used on arrival (touch); keys and the pad use what the player faces.
  - The counter with nobody at it says so; a stall with its merchant away is the merchant's goods (INT-043).
- **Tests:** `game/tests/start_test.gd`, `game/tests/world_test.gd::_ctr01_counters`, `game/tests/world_test.gd::_ctr04_counter_terms`

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
- **Source:** `game/scripts/ui/game_ui.gd::_talk_view`, `game/scripts/main.gd::pickpocket`, `game/scripts/core/world.gd::pickpocket`, `game/scripts/core/world.gd::report_crime`, `game/scripts/core/world.gd::deliver_report`, `game/scripts/core/npc_brain.gd::_report`, `game/scripts/ui/dialogue.gd::caught`
- **Affects:** Crime, Coins, Inventory, Player state, Interface
- **Expected:** Success with chance `pickpocket_chance` + `pickpocket_chance_per_level` per Stealth level above 1 (at most `pickpocket_chance_max`), from the world's random numbers: 1 to `pickpocket_coins_max` coins (never more than they carry), or, with no coins, one thing they carry that is not a work tool, marked as stolen from them; they later find it missing. Caught: they remember "caught <player> picking my pocket"; everyone in sight sees the try (INT-008); a guard who saw it stops the player (fine, INT-008). PICK-01 (owner OD-20, 2026-10-21: the witnessed-crime reporting system, no omniscient guards, not every incident an audible alarm): there is no cry a guard hears. When no guard saw it, the victim and every other villager who saw the try (not bandits, not guards) carry a theft report (`report_crime`, crime "theft") to a guard by PAR-05's rules (INT-013: at once to one in sight, else walking to the nearest awake guard within `report.range`; lapsing after `report.hours`). The guard it reaches remembers it (`theft_reports_delivered`) and, if the player is in that guard's sight then, stops them as for a theft seen (`guard_confront`: the base fine); a theft report never starts a chase. A pocket picked unseen (success) is reported by nobody: no guard knows of it. Those who caught the player answer coldly. Stealth experience either way.
- **Tests:** `game/tests/run_tests.gd::test_theft_and_shops`, `game/tests/start_test.gd`, `game/tests/world_test.gd::_pick01_reports`

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
- **Expected:** Owner rule: when a household is too big for its house (births crowd it: they need no free bed) and can afford it, a grown member founds a household: a grown son or daughter first, else an adult with no partner at home, never the reeve, the sage, a guard or a parent of young children at home; a founder's partner in the household leaves too, so partners are never split. Only when the family keeps `split_keep_base` + `split_keep_per_member` a member staying behind, after giving the founder what the new home costs; at most one split a day. The new household (same family, a new index appended to the list, `founded_from`) gets, by the property API only: an empty house on the market (bought, or leased with two weeks' rent in hand) and moves in at once; else the manor's surveyed ground (a clearing) or new legal ground as near home as can be found, bought, a house marked out and built by the player's rules, started with the ground and `found_start_share` of the materials' price in hand and finished as the household earns (hiring a helper each morning when it can pay for the rest, else the founder carrying with no wage when there is anything to buy or carry; otherwise its people work and save), then moves in (every member's home is the house). Until then the founder lodges with the family, on the house's next free sleeping place. Couples found households too (EQ-07): partners who live apart, or a grown child and partner in their parents' full house (never the reeve, the sage, a guard, or a parent of young children at home), with their own coins and what each family can spare above its keep, one founding a day; partners who live apart move in together instead when one home has a free bed, except that a partner whose household is building its own home never leaves it: the other joins them (EQ-07). A household that loses its house lodges with the family it came from and looks for a home again. Coins and goods only move.
- **Tests:** `game/tests/run_tests.gd::test_households_split`, `game/tests/aging_test.gd::test_couples_found_households`, `game/tests/households_sim.gd`, `game/tests/housing_test.gd`
- **Housing goals (EQ-07, owner directive 2026-10-20):** see INT-151. Couples of either sex found homes (HOUSE-02). The responsible adult carries for the household's own site (`responsible_adult`).

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
  - The caravan carries at most `caravan_stone.load` stone a visit, from the stock of the traders on the road (Garton's diggings and Bourton's quarry; INT-231), sold at value × `caravan_stone.markup` (cartage; provisional).
  - The raw-goods merchants, the village's stone sellers, buy it up to their stock cap while keeping their foreseeable-needs reserve (OD-19, INT-158); the rest goes back with the cart. The coins leave the village (`coin_sources`, `imported_stone`, `caravan_stone_coins`).
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
  - At the dawn `plant_regrow_seasons` (balance.json, 2 to 4, provisional) later the plant is ripe again and its tile returns. A plant on ground the player claims is grubbed up and never returns (as stumps, INT-040).
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
  - A smith with more than one pickaxe, axe or sword takes the spare to the goods merchant (a buyer within its stock cap, `NPCBrain.BUYS`, and its foreseeable-needs reserve, INT-158) before forging more; the goods merchant therefore has stock to retail and to sell on to the caravan (INT-020). Before, the smith kept its tools (`> 3` while forging stopped at 3), so the goods merchant's only supply was leather and it ended the year with no coin.
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
  - A felled tree is a stump (walkable) that sprouts `tree_regrow_seasons` later and grows through the stages again; ground bought for building clears its trees for good. Saplings and young trees are not solid, a growing or mature tree's trunk cell is; a young tree waits to become solid while someone stands on its cell, and the player can always walk out of a trunk that grew under them.
  - The player plants a sapling from the pack on free grass in front of them, never on a road, exit, door, field, plot, building, station or beside another tree.
  - Saved with the world: village trees whole, the overworld's changed trees (felled, growing, planted) with species, stage clock and planted flag; chunks that unload and load again redraw the same trees.
- **Tests:** `game/tests/run_tests.gd::test_tree_canopy`, `game/tests/overworld_test.gd::_run_scene`, `game/tests/start_test.gd::_gather_tests`

### INT-075 · An essential trade is handed on after its worker dies: apprentice, then newcomer
- **Trigger:** A smith, carpenter, tanner, cook, tavernkeeper or merchant dies, retires or leaves the trade for other work (or the last farmer, woodcutter or miner); a day starts; the caravan comes.
- **Source:** `game/scripts/core/npc_brain.gd::on_death`, `game/scripts/core/npc_brain.gd::_open_vacancy`, `game/scripts/core/npc_brain.gd::_post_left`, `game/scripts/core/npc_brain.gd::succession_dawn`, `game/scripts/core/npc_brain.gd::succession_caravan`, `game/scripts/core/npc_brain.gd::_apprentice_for`, `game/scripts/core/npc_brain.gd::_newcomer_for`, `game/scripts/core/npc_brain.gd::_install`, `game/scripts/core/npc_brain.gd::_change_job`, `game/scripts/core/npc_brain.gd::caravan`, `game/scripts/core/world.gd::to_dict`, `game/scripts/core/world.gd::load_dict`, `game/scripts/main.gd::_sync_sprites`
- **Affects:** Employment, Households, Inheritance, Coins, Market, Crafting, Save, Property
- **Expected:** (owner decision 2026-10-19: "Apprentice, then newcomer"; the numbers are agent proposals, provisional, balance.json `succession_days`, `newcomer_max_days`, `newcomer_coins`)
  - A death or a retirement (INT-078) in an essential trade records an open post (`World.vacancies`: job, workstation or stall, home, household, day), unless the trade is still at its starting strength without the leaver (a retiring worker is still counted as an adult in the trade when the post is checked, so they are left out of the count: Build 13 fix) (smith 2, carpenter 2, tanner 2, cook 3, tavernkeeper 2, merchant 6; one farmer, woodcutter and miner at least) or a post is already open for every missing hand. Death stays permanent: nobody is resurrected.
  - After `succession_days` an adult without a trade (no job, a labourer or a manor hand; the dead worker's household first, then the lowest id; a merchant needs the stall's stock coins) is taken on as an apprentice: the job, the workstation (`NPC.workplace`: the forge, sawhorse, workbench, stove, counter or stall) and the trade's tool. They keep their own home.
  - With no such adult the post waits for the caravan (`NPCBrain.caravan` calls `succession_caravan`), and at the latest `newcomer_max_days` after the death a newcomer arrives anyway. The newcomer takes the post and workstation, and a home: a lodger in the dead worker's household if it lives, else the old house leased from the manor, else any other empty house, else a room with the smallest household. Their purse (`newcomer_coins`) is new money from outside, counted in `World.coin_sources`, so coins stay conserved; the house lease moves coins to the treasury like any other.
  - The post is dropped if the trade is back at strength meanwhile (a stall let again by the manor). Open posts are saved (`vacancies`; older saves have none).
  - (EQ-07) A worker who leaves an essential trade through the job market (`seek_work`) opens its post the same way when the trade falls below strength (`_post_left`): the workstation they left, and the tools pass on from them. The worker who left is never taken back as the apprentice.
- **Tests:** `game/tests/world_test.gd::_succession`, `game/tests/aging_test.gd::test_coming_of_age_and_retiring`, `game/tests/housing_test.gd::test_left_trade_post_opens`

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
- **Expected:** (owner-approved 2026-10-19, B8-029) A year is `calendar.year_days` (8) game days, in the seasons of `calendar.seasons` / `season_days`; the clock reads "Spring, Year 1  Day 3  07:00". Age in years is `(now - born) / year`; an animal's stage is its age in days against `juvenile_years`, `grow_years`, `elder_years`. Both are pure functions of `born` and the clock, so a reload and the areas the player is not near stay consistent; only `born` is saved.
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
- **Expected:** Households are not families: relationships are explicit links (`mother`, `father`, `partner`, `children`), recorded for the starting households by `seed_population` and never inferred from a shared house. Two unpartnered adults, 18-50, not kin, of either sex, become partners by courting (INT-148), one moving into the other's home if it has a free bed; without room they pair and live apart until a home has room or they found a household (INT-060). Births are only to partners of opposite sex: a woman of 18-42, `birth_min_food_days` of food, no child in the last year; no free bed is needed (owner, 2026-10-19), so a birth can crowd the house and start a split (INT-060); about one in `birth_interval_years` years of days. The newborn is a child of the mother's household, with a name, a sprite and both parents recorded; while that household is still building its house and lodges with family, the baby lives where its parents lodge and moves in with them when the house is finished (EQ-17). The player partners an adult whose proposal was accepted (INT-148, `partner_player`); their children are villagers of the partner's household.
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
- **Expected:** newborn, juvenile, adult, elderly by age (`balance.json` animals: `juvenile_years`, `grow_years`, `elder_years`). Only adults breed (the existing rules kept), and the chance falls to nothing as the area nears its cap. The elderly move at 0.7x and, from `death_years[0]`, die of old age by a daily chance spread evenly to `death_years[1]`; meat and hide rules are unchanged. Newborns and juveniles draw the Cozy Farm baby sheet at full scale (the boar, with none, at half scale). The starting animals have varied ages.
- **Tests:** `game/tests/aging_test.gd::test_animals`, `game/tests/aging_test.gd::test_baby_art`

### INT-082 · The wiki is generated from game data, and Settings returns where it came from
- **Trigger:** The player opens Settings or the Village Encyclopedia (the wiki: Encyclopedia on the title screen, the pause menu or Settings' tab row), switches tabs, or presses X, Esc, the pad's B or Menu in any window.
- **Source:** `game/scripts/core/wiki.gd::build`, `game/scripts/core/wiki.gd::add_provider`, `game/scripts/core/wiki.gd::search`, `game/scripts/ui/wiki_window.gd::open`, `game/scripts/ui/wiki_window.gd::step_back`, `game/scripts/ui/wiki_window.gd::close_window`, `game/scripts/ui/game_ui.gd::show_wiki`, `game/scripts/ui/game_ui.gd::show_settings`, `game/scripts/ui/game_ui.gd::go_back`, `game/scripts/ui/game_ui.gd::hide_all`, `game/scripts/main.gd::_unhandled_input`
- **Affects:** Interface, Save
- **Expected:** (PL1-01, PL1-02, PL2-009) Wiki pages are built at open time from `items.json`, `recipes.json`, `resources.json`, `skills.json`, `balance.json` (animals, calendar, life, theft, property), `village.json` stations, `Population.JOBS`, `NPCBrain.BUYS`/`KEEPS` and `GameUI.CONTROLS`, so a new item, recipe or node gets a page, links and search entries with no wiki edit; hand-written system pages state only what the code does and mechanics that are not built are marked "Not in the game yet". Other systems add pages with `Wiki.add_provider`. Settings is one screen with tabs (Audio, Display, Interface, Controls, Saves) and an Encyclopedia tab that opens the wiki's own window (UI-WIKI-01, Build 18: `GameUI.show_wiki`, panel kind `wiki`, titled Village Encyclopedia; it keeps the pause state it found). The window is a top bar (Back, Contents, search, Close, and Resume play while a game runs), a left navigation panel of categories and a scrolling article panel; below 840 layout pixels wide (a phone with the large interface, a 16:9 phone) it is one column with the search atop the article. Page lists are equal-width grids whose words wrap, never clip. Each window records where Back goes (`panel_back`): X, Esc and B step back inside the wiki first (`inner_back`, restoring the earlier view's scroll place and focusing the page just left), then to the screen the window came from (title, pause menu or Settings), else close it and restore pause state, HUD and input; Close leaves at once from any page and Resume play closes every menu. The window only draws: page ids, links, search and the "Not in the game yet" separation stay in `wiki*.gd`. The title, origin and death screens never close, so no input can leave a grey, paused world. Settings are saved on every change (`user://settings.cfg`).
- **Tests:** `game/tests/wiki_test.gd`

### INT-083 · Medicines heal, and the sage's apothecary stock moves between real inventories
- **Trigger:** The player uses a medicine from the pack; the sage brews; the caravan visits.
- **Source:** `game/scripts/core/world.gd::player_use_medicine`, `game/scripts/core/npc_brain.gd::_caravan_apothecary`, `game/scripts/core/npc_brain.gd::_do_recipe`, `game/scripts/core/game_data.gd::effects`
- **Affects:** Health, Inventory, Market, Coins, Crafting, Employment, Wages, Ledger
- **Expected:** Items of type `medicine` (`items.json`: linen bandage 15, herbal poultice 30, healing tonic 50, strong healing tonic 80 health) heal only, never feed, never pass the health cap and are consumed only when they heal (at full health nothing is used). The sage keeps the village apothecary: the starting stock is `balance.json` `sage_start_stock`; the sage buys wild flowers (`BUYS.sage`, kept, not resold), brews poultices and healing tonics from them at the stove (the recipes `brew_poultice`, `brew_healing_tonic`), and sells everything else through the ordinary trade window. The caravan resupplies on each visit up to `caravan_apothecary_per_visit` pieces towards `caravan_apothecary_stock`, at base value, paid from the sage's own coins above their foreseeable-needs reserve (INT-158); those coins leave the village (`coin_sources` falls, the caravan purse rises), so supply is finite. The stove also makes the player's own tonics (`brew_strong_tonic` needs two healing tonics and ale). Every medicine shows its effect ("Restores 15 Health") in shop rows, the quantity control and the pack (`GameData.effects` reads `heal` without `food`: Build 13 fix).
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
- **Expected:** Every generated flower decoration outside the village is a ripe `flower` plant until picked, bare until `plant_regrow_seasons` later (`Overworld.plant_changes`, saved, the sprite hidden and restored at dawn); the village's red (2656) and white (2659) flowers are registered plants like the purple and yellow. Every boulder drawn outside the village is minable (mountain boulders too). A boulder is small (2 uses, drawn smaller) or large (6 uses) from a hash of its cell, the uses left are saved as before.
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
- **Expected:** A sown field is ripe `World.field_grow_days` later (`field_grow_seasons` calendar seasons, TIME-02); it then stands ripe for `field_ripe_wait_hours` (12) before the farmers cut it, so the player sees and can harvest ripe wheat (it used to be cut within the hour). Farmers then cut, till and sow again. `field_grow_days` is the hook for seasons.
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
- **Expected:** The beds of living quarters and small rooms (HOUSE-10) on the same property (held by the same party) count in `Construction.beds_in` for the house, so the household is crowded later, and `World.home_spot` gives members those beds, every room's beds before the house's straw pallets. The family chest and beds can be used from a storeroom or quarters of the home as from the house.
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
- **Source:** `game/scripts/core/player_state.gd::damage`, `game/scripts/core/world.gd::player_strike`, `game/scripts/main.gd::attack`, `game/scripts/main.gd::fireball`, `game/scripts/core/world.gd::damage_player`, `game/scripts/core/world.gd::player_price_factor`
- **Affects:** Combat, Health, Market, Coins
- **Expected:** (PL2-005) Combat tiers raise blow damage, shorten the swing delay, give a chance of a double blow and cut damage taken (not hunger); Magic tiers shorten the Fireball cooldown, cut its stamina cost and raise its damage; Trading tiers move the player's buy and sell prices up to 20% (coins still move between real holders, so the supply is unchanged). Trade xp grows with the coins in the deal.
- **Tests:** `game/tests/skills_test.gd::test_outcomes`, `game/tests/skills_test.gd::test_early_play`

### INT-109 · Stealth makes a pickpocket likelier and a caught one less seen
- **Trigger:** The player tries a pocket.
- **Source:** `game/scripts/core/world.gd::pickpocket`, `game/scripts/core/world.gd::pickpocket_chance`
- **Affects:** Crime, Player state
- **Expected:** (PL2-005) The chance is `pickpocket_chance` plus `pickpocket_chance_per_level` times the tier's `pickpocket_steps`, never above `pickpocket_chance_max` (a sleeper's bonus is unchanged); a guard who sees the theft acts (INT-044). Since PICK-01 removed the cry a guard heard (owner OD-20, 2026-10-21; there is no hearing, PAR-05), the tiers' `guard_radius` shortens how far a caught try is seen (`witness_radius` x `guard_radius`, by guards and villagers alike, and so who reports it; the victim always knows), as `lockpick_quiet` does for a quiet lock (agent proposal).
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
- **Expected:** (PL1-10 stage 2) At most `stall_buyers_per_hour` idle, awake adults with a need walk to the stall and buy. Needs reuse the brain's model: a trade restocks below half its `NPCBrain.BUYS` cap (smith ore and coal, cook grain and meat, tanner hides), the carpenter, smith and labourer cover what open building sites ask for, miners, labourers and woodcutters replace a missing tool, guards their gear, the household's head firewood and food (as `_plan_provision`). Merchants and children do not shop. A buyer pays only up to the cheapest local price (a little more when urgent), with any coins for a household need (food, firewood, medicine) and otherwise only with coins above their reserve (INT-158), and the goods go into their pack or pantry, so a met need buys nothing more.
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
- **Expected:** (PL2-015; Build 13 owner economy rule 3: seed never appears from nowhere) Seed is stock in real inventories. Farmers start with `farming.seed_stock.farmer`, the food merchant with `seed_stock.food_merchant`. A seller offers only the crops they hold seed of, and a sale moves that many seeds out of their inventory into the pack through `World.trade` at `seed_price` (adjusted by the Trading skill), all or nothing; more than they hold is refused. A farmer cutting a village field keeps `seed_keep` of the grain back as wheat seed, up to `seed_cap` (the rest stays grain; counted in `farm_seed_saved`, so the grain ledger balances). Each caravan visit sells the food merchant up to `caravan_seed_per_visit` seeds towards `caravan_seed_stock`, at seed value from the merchant's own coins above their foreseeable-needs reserve (INT-158); those coins leave the village. Seed is never offered as ordinary goods (`NPCBrain.KEEPS`). The player also saves seed from their own harvests (INT-124). A save from before Build 13 has no seed stock: the sellers' stock rebuilds from harvests and caravans.
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
- **Expected:** (PL1-10 stage 3) The shop's record lives in the building (`shop`, saved with it) and has the stall's fields: stock, prices, sales, till, earned, paid through day. It pays `shop_licence_day` a day to the manor (the first at opening; unpaid stops sales and, after `stall_evict_days`, closes it and returns the goods), holds `shop_listings` kinds plus `shop_shelf_listings` per shelves, and a stock chest's `shop_store_per_chest` pieces refill a sold-out kind at its price. Buyers, needs, ceilings and reserves are the stall's (INT-119, INT-158). Revenue, expenses (licence, wages) and profit are kept; the till counts in the village's coins. Taking up the counter, or losing the room, closes the shop with nothing lost.
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
- **Source:** `game/scripts/core/fauna.gd::_eat`, `game/scripts/core/fauna.gd::_may_graze`, `game/scripts/core/fauna.gd::_predate`, `game/scripts/core/fauna.gd::take`, `game/scripts/core/fauna.gd::can_take`, `game/scripts/core/fauna.gd::spare`, `game/scripts/core/fauna.gd::_forage_berries`, `game/scripts/core/fauna.gd::_raid`, `game/scripts/core/fauna.gd::provoke`, `game/scripts/core/fauna.gd::_hunt_people`, `game/scripts/core/fauna.gd::_bite`, `game/scripts/core/fauna.gd::_move`, `game/scripts/core/fauna.gd::nearest_game`, `game/scripts/core/fauna.gd::seed_new_species`, `game/scripts/core/fauna.gd::_spare_prey`, `game/scripts/core/fauna.gd::new_day`, `game/scripts/main.gd::_hit_animal`
- **Affects:** Livestock, Health, Food, Resources, Player state, Households
- **Expected:** (owner, Build 14: forest animals roam and feed on their own, carnivores hunt and eat the grazers; owner answers 2026-10-19) Deer, boar and rabbits graze (the wood's grass counts only grazers); over the wood's capacity only as many graze as it feeds, the strongest and best fed first, so the weakest and hungriest go short rather than the whole herd (`Fauna._may_graze`, WR-02); birds pick seeds. A hungry wolf, fox or bear kills one of its `prey` in its wood at most `wildlife.hunt_chance_per_hour` an hour; near the player the chase is seen and may end sooner, and prey run from a hunter within their `flee` distance. The bear eats a ripe berry bush by its wood first (the bush is picked). A hungry fox takes a pen chicken at night. Nobody (predator, hunter, poacher) takes the last grown male or female of a kind in a wood or goes below its `keep`; the village hunter leaves `wildlife.hunter_spare` more and never hunts wolves, foxes or bears. A hunter or omnivore breeds only while its wood holds `wildlife.prey_per_predator` spare prey for each of its kind and one more, and a wood's last pair of a hunting kind scavenges (hunger back to `wildlife.scavenge_hunger`) rather than starve. These floors do not stop old age, so they alone let every kind die out (measured: no wild animal left by day 100 of a no-player run); the breeding refuges of INT-148 are what keeps a species from global extinction. Foxes eat ripe berries first, like the bear. Wolves and bears struck by the player fight back and bite; a starving one goes for a person alone in its wood; foxes never attack people. Older saves gain the new species once.
- **Tests:** `game/tests/wildlife_test.gd::test_population`, `game/tests/wildlife_test.gd::test_predation`, `game/tests/wildlife_test.gd::test_chase_and_flee`, `game/tests/wildlife_test.gd::test_fox_raid`, `game/tests/wildlife_test.gd::test_people`, `game/tests/wildlife_test.gd::test_hunting`, `game/tests/wildlife_test.gd::test_save`, `game/tests/wildlife_test.gd::test_days`, `game/tests/wildlife_test.gd::test_grazing_over_capacity`

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
- **Expected:** (asset pipeline, owner directive 2026-10-19; Craftpix fruit trees) Village trees near the houses are partly apple trees (fruit_trees orchard rules; new worlds). A grown apple tree bears fruit_trees.apple_orchard.yield apples in summer and autumn: the player or a villager picks them (the tree is then bare until regrow_seasons later, in season); apples are pantry food, sold at storefronts and to the food merchant. Felled, an apple tree gives logs and (by chance) an apple sapling that grows a new apple tree. Apples now have a source (the resources.json exception is gone). Saved with the trees.
- **Tests:** `game/tests/home_test.gd::test_apple_trees`

### INT-148 · Friendship, courting and marriage: gifts, help, befriending, proposals; friends' benefits
- **Trigger:** Every hour (people near each other share it); the player talks with, gives a gift to, completes a request for, befriends, asks to court or proposes in the talk window; each dawn (villagers court; ties cool); the player trades with, hires or is stopped by a guard near a friend.
- **Source:** `game/scripts/core/relations.gd::give`, `game/scripts/core/relations.gd::gift_effect`, `game/scripts/core/relations.gd::favourites`, `game/scripts/core/relations.gd::helped`, `game/scripts/core/relations.gd::befriend`, `game/scripts/core/relations.gd::ask_court`, `game/scripts/core/relations.gd::propose`, `game/scripts/core/relations.gd::dawn`, `game/scripts/core/relations.gd::_villagers_court`, `game/scripts/core/relations.gd::hour`, `game/scripts/core/relations.gd::share`, `game/scripts/core/relations.gd::talked`, `game/scripts/core/relations.gd::player_tick`, `game/scripts/core/relations.gd::defended`, `game/scripts/core/relations.gd::harmed`, `game/scripts/core/npc_brain.gd::_plan_seek_company`, `game/scripts/core/world.gd::witness`, `game/scripts/core/world.gd::player_assault`, `game/scripts/main.gd::_hit`, `game/scripts/core/world.gd::_on_hour`, `game/scripts/ui/game_ui.gd::show_talk`, `game/scripts/core/quests.gd::complete`, `game/scripts/core/world.gd::player_quote`, `game/scripts/core/world.gd::guard_confront`, `game/scripts/core/construction.gd::hire`, `game/scripts/ui/game_ui.gd::_relation_choices`, `game/scripts/ui/game_ui.gd::show_gifts`, `game/scripts/ui/dialogue.gd::news`, `game/scripts/core/life.gd::dawn`
- **Affects:** Family, Households, Market, Crime, Building, Interface, Save
- **Expected:** (owner, 2026-10-19: CRT-01..07) Every pair of people has a tie: regard and attraction, and days known (separate days of real contact). The player's closeness is measured as they play (CRT-10): minutes within `close.tiles` of awake villagers in the same place, the nearest counting `close.focus_factor`, at most `close.daily_regard` a day, a day known after `close.known_minutes`; every channel adds within `regard_daily_cap` and `attraction_daily_cap` a day; courting needs `court_min_days` days known and marriage `marry_min_days`. Killing a bandit, wolf or bear near villagers raises their regard (`defend_regard`, once a day); a crime seen or suffered lowers it (`witness_harm`, `victim_harm`). A single villager with `seek.coins` or a gift spends `seek.chance` of evenings beside the one they court (or their closest friend), buying a gift first with `seek.gift_coins` (CRT-11). A proposal is refused (CRT-12) when the one asked does not mean to marry (`unwilling_percent`, fixed per person), when the suitor has slain a villager or is notorious (`notoriety_refuse` crimes seen in `notoriety_days`), when their regard is below `marry_regard`, or when a rival courting them holds more of their heart; harm spreads to the victim's kin (`kin_harm_share`) and friends (`friend_harm_share`); a villager slain by the player is `kill_harm`. Shared experiences start ties (CRT-08): each hour people awake within `shared.near_tiles` share it, work (same trade or workplace, at work) counting most, then evening company, then time nearby, at most `shared.daily_cap` regard a day; each pair's hour counts once (CRT-09); a conversation with the player adds `talk_first`, then `talk_more`, then `talk_decay` times less each time that day; villagers befriend each other at `befriend_at` and court only someone known on `interest_days` days at `interest_at` attraction or more, never again someone who refused them for good. Attraction from time together is scaled by the pair's chemistry (fixed per pair and world: `chemistry_min` + `chemistry_span` u²) and by `shared.courting_factor` while courting; gifts do not depend on chemistry. Villagers without spare means seek company on `seek.poor_chance` of evenings. A gift moves one real item from the giver to the receiver: food, flowers, ale, clothes and jewellery always add attraction (between people who may court: humans of age, not kin, not partnered elsewhere, either sex) and regard; the receiver's favourites (their trade's FAVOURITES, food when hungry, medicine when hurt) count `favourite_factor` and are marked with the reason in the gift list; one gift a day counts, a repeat counts less. Help (a request done) adds regard. At `befriend_at` regard the player may Befriend (no proposal). At `court_at` attraction a request to court is accepted, else declined; a proposal while courting is accepted after `propose_min_days` at `propose_at`, else declined as too soon and attraction drops. Villagers court each other by the same rules each dawn (replacing the random pairing), with gifts they hold or time together. Friends trade at `friend_price` better, carry for the player's site with no wage, tell who is courting, and back the player before a guard (a friend guard warns only; a friend nearby halves the fine). Partners of one sex have no children. Ties save in `relations` (older saves: strangers). Goods and coins only move.
- **Tests:** `game/tests/relations_test.gd`, `game/tests/aging_test.gd::test_partners_and_births`

### INT-149 · Protected breeding refuges: offspring cohorts, release in season below capacity, dispersal and recolonization
- **Trigger:** Each dawn (Fauna.new_day: a due refuge breeds in season; a cohort old enough leaves); every update (young walk to their settling points, migrants reach their wood); saving and loading; a new world or an older save without refuges.
- **Source:** `game/scripts/core/refuges.gd::ensure`, `game/scripts/core/refuges.gd::new_day`, `game/scripts/core/refuges.gd::_breed`, `game/scripts/core/refuges.gd::_release`, `game/scripts/core/refuges.gd::fed`, `game/scripts/core/refuges.gd::_destination`, `game/scripts/core/refuges.gd::settle_point`, `game/scripts/core/refuges.gd::update`, `game/scripts/core/refuges.gd::to_dict`, `game/scripts/core/refuges.gd::load_dict`, `game/scripts/core/fauna.gd::new_day`, `game/scripts/core/fauna.gd::update`, `game/scripts/core/fauna.gd::_move`, `game/scripts/core/fauna.gd::load_dict`, `game/scripts/core/fauna.gd::seed_new_species`, `game/scripts/core/animal.gd::to_dict`, `game/scripts/core/life.gd::season`, `game/scripts/core/wiki.gd::_animals`
- **Affects:** Wildlife, Calendar, Ledger, Save, Bandits, Food, Market, Interface
- **Expected:** (owner directive 2026-10-19 Part II, WR-01; World Design Rule 018; Build 16 directive section 2) Each wood holds one refuge per wild species that lives there (wolf den, bear cave, rabbit burrow, boar concealed shelter, deer sheltered habitat, bird nesting area, fox earth). Its breeding stock is a hidden count, not an Animal: no strike, area attack, village hunter, poacher or predator can reach it, and no population update lowers it. At dawn, once `refuges.species.<kind>.interval_years` have passed and in one of its `seasons` (Life.season), a refuge raises one litter, but only up to the room its woods have below `refuges.release_below` of the species' woods_cap, never less than a pair (young in transit count) and only where they can feed (grazers: the wood not overgrazed; hunters and omnivores: `wildlife.prey_per_predator` spare prey each); otherwise it waits without resetting its timer. The young leave at the first dawn after `juvenile_years` as juveniles into Fauna.animals (counted `born_<kind>` there, plus `refuge_released_<kind>`; `refuge_born_<kind>`, `refuge_held_<kind>`, `migrating_<kind>`, `migrated_<kind>`, `lost_migrating_<kind>` and `settled_<kind>` are statistics only). Each goes to the wood with the lowest share of its cap (another wood counts `cross_wood_penalty` more; that journey is unseen, takes travel time and may be lost at `transit_loss`, and the animal is counted born only on arrival), then walks to a settling point `disperse` tiles away, the farthest of `samples` cells from others of its kind and its littermates, and settles there or after `settle_days`. From then on it is an ordinary animal: grazes, is hunted and eaten, breeds when grown. So an overhunted wood stays empty until the refuge's young arrive, and fills only to `release_below` of its cap from refuges; hunter productivity, meat and hide supply and the predators' food follow the actual animals. Saved in the fauna block (`refuges`: refuges with their timers and cohorts, migrants; animals' `dest`, `settle_by`, `origin`); no save version change: an older save gains its refuges once on loading, and loading never duplicates animals or resets timers.
- **Tests:** `game/tests/refuge_test.gd::test_refuges_exist`, `game/tests/refuge_test.gd::test_out_of_reach`, `game/tests/refuge_test.gd::test_season_and_capacity`, `game/tests/refuge_test.gd::test_dispersal`, `game/tests/refuge_test.gd::test_migration`, `game/tests/refuge_test.gd::test_overhunt_and_recolonize`, `game/tests/refuge_test.gd::test_save_round_trip`, `game/tests/refuge_test.gd::test_old_save`, `game/tests/refuge_test.gd::test_determinism`, `game/tests/wildlife_test.gd::test_days`

### INT-150 · Save continuity: copy out, keep a copy up to date, import with backup, migration and validation
- **Trigger:** The player chooses Copy my save, Keep a copy up to date or Import a save file in Settings, Saves; every save (the linked copy); loading a save with sections this build does not know.
- **Source:** `game/scripts/core/save_transfer.gd::export_save`, `game/scripts/core/save_transfer.gd::import_save`, `game/scripts/core/save_transfer.gd::migrate`, `game/scripts/core/save_transfer.gd::validate`, `game/scripts/core/save_store.gd::inspect_text`, `game/scripts/core/save_store.gd::write_text`, `game/scripts/main.gd::export_save_to`, `game/scripts/main.gd::import_save_from`, `game/scripts/main.gd::_update_linked_copy`, `game/scripts/main.gd::_save_meta`, `game/scripts/main.gd::_load_save`, `game/scripts/ui/game_ui.gd::_settings_saves`, `game/scripts/ui/game_ui.gd::_pick_file`, `game/scripts/ui/game_settings.gd::save_file`
- **Affects:** Save, Interface, Player state
- **Expected:** (owner directive 2026-10-20, SAVE-00..09) A copy of the save goes to a file the player chooses with the platform's picker (Android's Storage Access Framework, built into Godot 4.7; the PC's file dialog) and is read back; a linked copy is rewritten after every save. Import reads the chosen file; refuses a damaged, newer or too old save without changing anything; copies the original byte for byte into `user://save_backups/`; migrates it in memory (`MIGRATIONS`, then World.load_dict and to_dict) carrying unknown sections; validates it (seed, identity, people, households, buildings, character, a stable second round trip); keeps any existing save in the backups; then swaps it in with SaveStore's atomic write and continues the world. Saves record their world id (`meta.save_id`) and the builds they were played in; sections a build does not know survive loading and saving.
- **Tests:** `game/tests/save_transfer_test.gd`, `game/tests/start_test.gd::_save_meta_tests`

### INT-151 · Housing goals: a household's need is kept, worked and saved for; the responsible adult decides; crowded families enlarge
- **Trigger:** Each morning, for every household that is crowded, a couple needing a home of their own, or a household without a home of its own.
- **Source:** `game/scripts/core/construction.gd::daily`, `game/scripts/core/construction.gd::housing_goals`, `game/scripts/core/construction.gd::_goal`, `game/scripts/core/construction.gd::saving_for_home`, `game/scripts/core/construction.gd::responsible_adult`, `game/scripts/core/construction.gd::start_cost`, `game/scripts/core/construction.gd::_enlarge`, `game/scripts/core/construction.gd::_keep_building`, `game/scripts/core/npc_brain.gd::_plan_seek_company`, `game/scripts/core/npc_brain.gd::_smith`, `game/scripts/core/life.gd::_move_in`, `game/scripts/core/construction.gd::loft_refusal`, `game/scripts/core/construction.gd::start_loft`, `game/scripts/core/world.gd::_with_loft`, `game/scripts/core/world.gd::_finish_loft`, `game/scripts/core/world.gd::in_loft`, `game/scripts/main.gd::_sync_sprites`, `game/scripts/core/construction.gd::beds_needed`, `game/scripts/core/life.gd::has_room`, `game/scripts/core/property.gd::survey_under`, `game/scripts/core/construction.gd::_tool_reserve`, `game/scripts/core/npc_brain.gd::tool_short`, `game/scripts/core/npc_brain.gd::seek_work`
- **Affects:** Households, Building, Crafting, Market,, Property, Coins, Family, Inheritance, Ledger, Save
- **Expected:** (owner directive 2026-10-20, HOUSE-01..06, FAM-01) A real need (crowded, a couple apart, no home) is kept on the household as a goal (`housing`: need, since, by, plan, cost, short, why), saved with it. The goal lasts while the need lasts, and goes when the need goes. It says what the next step costs and what the household still has to put by, or what blocks it. While a household is saving or building, its members buy no courting gifts. The evening with a friend still happens (Relations). The household's responsible adult is a living adult (elders when there are none, never a child): a parent of someone at home first, then the eldest. When a parent dies, the surviving parent of either sex decides. That adult carries for the household's own site. A crowded household nobody can leave (the parents of young children) adds living quarters, the existing module that adds beds, to its house. It starts and builds them as a house is started and built, never from what it keeps to live on. Crowding counts sleeping places (`beds_needed`, HOUSE-08): a couple shares a bed, and children below `life.child_until` share `bed_share.children_per_bed` to a bed. `Life.has_room` counts the same way, so a partner joining shares their partner's bed. An original village house's ground is surveyed into a parcel when its household can start quarters (`Property.survey_under`, HOUSE-09). Nothing is paid, and the letting's terms move with the deal. On the current layout no original house has free ground beside it for the quarters (OD-14); three (b23, b24, b_v1_house) have ground for the **small room** (`room`, HOUSE-10: a 5x6 module with two beds, cut from the house stamp by `tools/build_village.py::room_stamp`), which a crowded household weighs beside the loft and the quarters and builds through the same module rules (ground bought or leased beside the house, materials delivered, the beds only when finished). A module's parcel joins the house's property whether the anchor given is the house or its parcel (`Construction.place`). A crowded household that nobody can leave weighs its options (HOUSE-12, owner-approved). A **sleeping loft** (`loft` in balance.json: 12 planks, 6 logs, 2 sleeping places, one per house) is built on the house's own parcel through the normal site and delivery path. Its beds appear only when it is finished (`World._finish_loft` sets the house's `loft`; `World._with_loft` adds bed spots whose use cell is a ladder floor cell). A loft sleeper is hidden while asleep (`World.in_loft`). Living quarters are built where there is ground. The option that gives the room lacking comes first, then the cheaper, net of materials held. With no option, the goal says why and nothing is retried. Materials only move (helper_took_/helper_bought_ stats); none appear. With nothing to forge, the smith buys coal and iron ore from the raw-goods merchant, so the caravan's ore (B7-007) reaches the forge and axes for felling go on being made (EQ-07). What a household keeps back from its building includes the price of a member's missing work tool (`_tool_reserve`). A worker who lacks their trade's tool and cannot pay for one counts as out of work in the job market (`NPCBrain.tool_short`, `seek_work`) (EQ-07). Someone looking for work who has no axe or pickaxe weighs woodcutting or mining when they can pay for the tool where tools are sold (the smith or the goods merchant, `NPCBrain.tool_price`), so the trades are taken up again as tools wear out (EQ-07; `housing_test.gd::test_axe_bought_to_take_up_woodcutting`).
- **Tests:** `game/tests/housing_test.gd`

### INT-152 · A builder's family helps pay, and the builder makes timber when none can be bought
- **Trigger:** Each morning for a household building its home (family help); during the working day for the builder carrying for their own household's site (timber).
- **Source:** `game/scripts/core/construction.gd::_family_help`, `game/scripts/core/construction.gd::plan_helper`, `game/scripts/core/construction.gd::_own_builder`, `game/scripts/core/construction.gd::_make_timber`, `game/scripts/core/construction.gd::act`, `game/scripts/core/npc_brain.gd::keeps`, `game/scripts/core/npc_brain.gd::_do_recipe`, `game/scripts/core/npc_brain.gd::_get_tool`, `game/scripts/core/world.gd::nearest_tree`
- **Affects:** Households, Building, Coins, Family, Resources, Crafting, Market, Ledger
- **Expected:** (owner directive 2026-10-20, housing: "obtaining help from relatives", "gathering available timber", "producing materials through existing crafting"; HOUSE-04, EQ-07) A household building its home receives, toward what its site still costs, what its family can spare. The family is the household it was founded from and the households of the builder's parents. It gives only above what it keeps for its own people and its own missing tools, and nothing while it is building itself. Coins only move. A builder carrying for their own household's site first brings what they hold, then buys. When no timber can be bought, they make their own. They saw logs they hold beyond the site's log need into planks at a sawhorse (`saw_planks`). With an axe they fell a tree. Without one, they buy an axe when the household can pay for it and half of what the site still costs. A builder keeps their axe while building (`NPCBrain.keeps`). Every log is felled (`felled_log`) and every plank sawn (`made_plank`, `used_log`); none comes from nothing.
- **Tests:** `game/tests/housing_test.gd::test_family_helps_builder`, `game/tests/housing_test.gd::test_builder_makes_timber`

### INT-153 · Orphaned children are taken in by kin or another household
- **Trigger:** Each dawn (Life.dawn), for a household whose living members are all children.
- **Source:** `game/scripts/core/guardianship.gd::dawn`, `game/scripts/core/guardianship.gd::place`, `game/scripts/core/guardianship.gd::candidates`, `game/scripts/core/guardianship.gd::kin_distances`, `game/scripts/core/guardianship.gd::move`, `game/scripts/core/life.gd::dawn`, `game/scripts/core/npc_brain.gd::_lodge`, `game/scripts/core/property.gd::household_ended`, `game/scripts/core/construction.gd::_may_found`, `game/scripts/core/guardianship.gd::join_clan`, `game/scripts/core/guardianship.gd::leave_camp`, `game/scripts/core/npc_brain.gd::_clan_child`, `game/scripts/core/npc_brain.gd::_prey_for`, `game/scripts/core/life.gd::_set_role`
- **Affects:** Family, Households, Building, Property, Bandits, Save
- **Expected:** (owner directive 2026-10-20, housing, succession and adoption, Parts 3-4; OD-11, OD-12; FAM-02..05) When both parents are dead and only children are left, each child is taken in, in order, by:
  1. a surviving parent living elsewhere;
  2. living grandparents (either side);
  3. the nearest eligible blood relative by genealogical distance through parent and child links;
  4. another household with a home, a responsible adult and room for the child.
  Equally close candidates are ranked by ability to provide care, capacity, food, relationship and proximity, then the lower household id. The child becomes a member and lodges in that house. Mother, father and children links are unchanged, and a changed surname keeps the birth surname (`NPC.birth_family`, saved). The emptied household ends as any household whose members are gone. Children never found households (`_may_found`), and the receiving household's crowding is its own, so no house is built for it. With no household able, the child joins the bandit clan (FAM-07, owner OD-11), an interim handling until bandit factions (WDR-016-C): `Guardianship.join_clan` leaves the household (`NPC.clan` = "bandit", saved), and the child lives, sleeps and eats with the band at the camp (`NPCBrain._clan_child`, the camp's meal as the bandits' own). It is never a bandit's prey, and keeps its name, age, role, parents and relationships. At coming of age it is not bound to the band (owner, clarified 2026-10-20): `Guardianship.leave_camp` finds it a place by the guardianship order (kin first, then a household with room), where it joins as an adult without a trade; with no place it stays with the band (`Life._set_role`: a bandit's health and blow, no item made for it). Its own weighing of the choice is FAM-08 (NPC Judgment, bandit factions). `orphans_to_clan` counts the cases.
- **Tests:** `game/tests/family_test.gd`

### INT-154 · Money flows back to the essential trades: the manor's tools, bandits at the market, loot recovered, the caravan buys producers' surplus
- **Trigger:** The manor's evening business (`reeve_day`); a bandit's day; a guard on duty; the caravan's visit.
- **Source:** `game/scripts/core/npc_brain.gd::_support_trades`, `game/scripts/core/npc_brain.gd::tool_needers`, `game/scripts/core/npc_brain.gd::_deliver_orders`, `game/scripts/core/npc_brain.gd::_order_for`, `game/scripts/core/npc_brain.gd::tool_short`, `game/scripts/core/npc_brain.gd::keeps`, `game/scripts/core/npc_brain.gd::_smith`, `game/scripts/core/npc_brain.gd::_bandit_market`, `game/scripts/core/npc_brain.gd::_loot_to_recover`, `game/scripts/core/npc_brain.gd::_guard`, `game/scripts/core/npc_brain.gd::caravan`, `game/scripts/core/world.gd::to_dict`, `game/scripts/core/world.gd::load_dict`
- **Affects:** Coins, Treasury, Crafting, Market, Employment, Bandits, Loot, Ledger, Save
- **Expected:** (owner answer to OD-16, 2026-10-20: (b), (a), (c); register EQ-19, EQ-20, EQ-21; every number an agent proposal in balance.json, `_od16_note`)
  - **(b) The manor keeps the trades in tools.** Each evening, after relief and before optional spending, each worker short of their trade's tool (a woodcutter's axe, a miner's pickaxe, a builder's axe) gets one. If one is on sale at the goods merchant's or the smith's, the treasury buys it. Otherwise the poorest smith is paid its worth in advance (`World.manor_orders`, saved; at most `manor_orders_per_smith` each). The forge buys ore and coal with it, forges ordered tools first and keeps them from sale, and the tool goes to the worker (or the next one short of it). The order lapses if the smith dies or leaves the trade, or after `manor_order_days` unmet (then its worker counts as short of the tool again and may seek other work). A worker whose tool is on order is not counted out of work. The treasury keeps `manor_support_floor_days` of its obligations.
  - **(a) Bandits' coins recirculate.** By day a bandit holding `bandit_spend_min` coins and not badly hurt buys up to `bandit_spend_units` food at a food seller no guard stands within 10 tiles of. A guard on duty brings coins from loot lying `loot_recover_hours` within `guard_loot_range` tiles (no bandit within 8) to the treasury; the goods stay where they lie.
  - **(c) The caravan buys producers' surplus.** Besides the market's and the smiths' stock, it buys what hunters (meat, hides, pelts) and tanners (leather) hold beyond `caravan_producer_keep`, within its purse and its food reserve rule, paid from outside (`caravan_in_<job>`).
  - Coins and goods only move: the ledger balances.
- **Tests:** `game/tests/od16_test.gd`

### INT-155 · One recovery model: a rest heals the player and villagers alike
- **Trigger:** The player's rest; a villager's night's sleep, a guard's rest off duty, a clan child's sleep at the camp; a villager badly hurt by day.
- **Source:** `game/scripts/core/world.gd::rest_recover`, `game/scripts/core/npc_brain.gd::_plan_bed`, `game/scripts/core/npc_brain.gd::_plan_sleep`, `game/scripts/core/npc_brain.gd::_plan_rest_hurt`, `game/scripts/core/npc_brain.gd::act`, `game/scripts/core/npc.gd::hp_cap`, `game/scripts/main.gd::_rest_now`
- **Affects:** Health, Player state, Households, Employment
- **Expected:** (PAR-03, owner OD-18.3, 2026-10-20: the player's recovery model for everyone) A rest that lasted to the morning, or at least `rest.day_minutes` (the player's two hours) by day, restores health to its cap (and the player's stamina); `World.rest_recover` decides it for both. A villager's rest is a plan step that ends in `rest_end`; being woken clears the plan, so a rest cut short heals nothing. A villager below `rest.seek_below` of their health by day dresses the wound if a medicine is to hand (INT-143's medicine rules), else goes home to rest (in bed, at the door step of a home without one, or where they stand with no home). Bandits are not covered: they do not sleep.
- **Tests:** `game/tests/world_test.gd::_par03_rest`

### INT-156 · Villagers have skills by the player's rules
- **Trigger:** Any work that earns the player experience, done by anyone: a swing at a seam, a tree felled, a recipe made (at a station, or at home), a blow struck, game killed, a deal; a new world; loading a save from before version 15.
- **Source:** `game/scripts/core/skills.gd::level`, `game/scripts/core/skills.gd::gain`, `game/scripts/core/skills.gd::start_xp`, `game/scripts/core/skills.gd::seed_villagers`, `game/scripts/core/world.gd::work_mine`, `game/scripts/core/world.gd::work_felled`, `game/scripts/core/world.gd::work_craft`, `game/scripts/core/world.gd::harm_npc`, `game/scripts/core/world.gd::npc_blow`, `game/scripts/core/world.gd::deal_factor`, `game/scripts/core/world.gd::deal_price`, `game/scripts/core/world.gd::deal_xp`, `game/scripts/core/npc_brain.gd::_do_recipe`, `game/scripts/core/npc_brain.gd::_can_mine`, `game/scripts/core/npc_brain.gd::fight`, `game/scripts/core/npc_brain.gd::act`, `game/scripts/core/manor_work.gd::mine_into`, `game/scripts/core/npc.gd::to_dict`, `game/scripts/core/npc.gd::from_dict`, `game/scripts/core/world.gd::load_dict`, `game/scripts/main.gd::craft`, `game/scripts/main.gd::_chop`
- **Affects:** Player state, Resources, Crafting, Market, Combat, Employment, Save
- **Expected:** (PAR-01, owner OD-18.1, 2026-10-20: "All villagers must develop skills exactly as the player does") One store (`skills`, skill -> xp) and one curve (`skills.json`) for the player and every villager. The same work earns the same xp: 8 an ore, 12 a felled tree, a recipe's `xp`, 4 a blow at a person, 2 at game, `Skills.trade_xp` a deal for each side. The same gates hold: gold ore needs Mining 3 (`World.work_mine`; a miner below it does not set out for gold, `_can_mine`), a recipe needs its skill level (`World.work_craft`; a villager below it does not set out to make it, `_do_recipe`). The same tier effects apply through the same functions: extra ore, extra logs, tools spared wear, shorter work, inputs saved, bonus units, harder and critical blows, less damage taken, better prices (`deal_factor`: 1 + the seller's price_bonus - the buyer's, the player's own rule when the other side has none). (Owner's final directive, sections 2-4: PAR-01A..C.) Starting experience is given once only: at world creation each established villager gets a plausible history in their trade (`Skills.start_xp`: a fixed per-person share of their working years, between `tenure_min` and all of them, at most `max_tenure_years`, at `xp_per_year`, in that trade's skills only), and a 14 save's villagers are given the same once on load; a 15 save is never re-seeded. Newcomers, children coming of age and the player start with none. A career change neither grants nor removes experience (`_change_job` does not touch skills). Experience comes from the activity, whatever the person's job: a household felling its own timber, home cooking and brewing, a manor hand at the quarry, a villager defending themselves, any deal. Not covered: Magic and Stealth (no villager casts or steals), saplings (the player plants, DECISIONS.md).
- **Tests:** `game/tests/parity_test.gd`

### INT-157 · Villagers make every recipe the player can, for a buyer
- **Trigger:** A smith, tanner, carpenter, cook or sage deciding what to make.
- **Source:** `game/scripts/core/npc_brain.gd::_smith`, `game/scripts/core/npc_brain.gd::_tanner`, `game/scripts/core/npc_brain.gd::_carpenter_goods`, `game/scripts/core/npc_brain.gd::_cook`, `game/scripts/core/npc_brain.gd::_plan_job`, `game/scripts/core/npc_brain.gd::_can_make`, `game/scripts/core/world.gd::work_craft`
- **Affects:** Crafting, Market, Coins
- **Expected:** (PAR-04, owner OD-18.4 and the final directive, section 8) The eleven recipes only the player used to make now have makers, through the one craft function (`World.work_craft`: the same skill level, inputs, outputs, xp and ledger), and only when there is a reason: the smith smelts gold (Smithing 3) when someone wants the bar or a gold ring, and forges a copper or gold ring, an amulet or an iron helmet while the goods merchant wants one; the tanner makes a leather cap or leather armour for the goods merchant; the carpenter makes a plough for it, buying the two iron bars; the cook kneads flatbread when it has no egg and someone wants bread; the sage keeps a few herbal tonics and, at Cooking 3, brews the strong tonic (buying a little ale). Goods made for a buyer are all sold (`MADE_TO_ORDER`); a gold bar a wanted ring needs is forged into it first. The goods merchant takes up to 2 ploughs, by B7-003's rule for made goods.
- **Tests:** `game/tests/parity_test.gd::test_eleven_recipes`

### INT-158 · A reserve is what a household foreseeably needs, not a fixed sum
- **Trigger:** Any purchase of stock, materials or goods by a villager (a trader buying from a seller, the player included; the caravan's restocking; a builder's budget), and a household buying its necessities.
- **Source:** `game/scripts/core/world.gd::necessity`, `game/scripts/core/world.gd::reserve_of`, `game/scripts/core/world.gd::_market_price`, `game/scripts/core/world.gd::can_afford`, `game/scripts/core/world.gd::is_necessity`, `game/scripts/core/business.gd::cash_floor`, `game/scripts/core/npc_brain.gd::act`, `game/scripts/core/construction.gd::_household_need`, `game/scripts/ui/game_ui.gd::show_trade`
- **Affects:** Coins, Market, Households, Food, Building
- **Expected:** (OD-19, owner 2026-10-20; PAR-02A) No fixed reserve. `World.necessity(who)` reckons, from what the person can know now, what their household needs over `reserve_days` days at today's asking prices: its members' food less the food its pantry and members hold, a log a night less the logs held, a medicine for each member hurt below `medicine_use_below` with none to hand, and rent falling due; less the wages its guards and reeve can expect after the first day while the treasury can pay them. The reserve is that need less what the rest of the household holds (`reserve_of`, cached for the game hour). Buying stock, materials or goods for resale is done only with coins above it (`can_afford`; a villager's `buy_from` of materials too); food, firewood and medicine for the household, and a worker's own work tool, may be bought with any coins. A household building its house keeps its need back from the budget. The player sees their own reckoning in the trade window and decides for themselves; their sales to a villager meet that villager's reserve, as anyone's do. Nothing stops poverty or failure: a household that misjudges or cannot earn goes short.
- **Tests:** `game/tests/reserve_test.gd`, `game/tests/world_test.gd::_par02_reserve`

### INT-159 · One valuation of food, and villagers eat what the player can
- **Trigger:** Any food reckoning (a household's days, its OD-19 reserve, the village's food days and famine, market prices, relief), and a hungry villager choosing what to eat.
- **Source:** `game/scripts/core/npc_brain.gd::food_points`, `game/scripts/core/npc_brain.gd::store_points`, `game/scripts/core/npc_brain.gd::household_stores`, `game/scripts/core/npc_brain.gd::_plan_eat`, `game/scripts/core/npc_brain.gd::stock_family_chest`, `game/scripts/core/npc_brain.gd::_sale_stock`, `game/scripts/core/npc_brain.gd::_cook_at_home`, `game/scripts/core/world.gd::_update_food_days`, `game/scripts/core/world.gd::necessity`, `game/scripts/core/world.gd::_market_price`
- **Affects:** Food, Households, Relief, Granary, Market, Coins
- **Expected:** A food item is worth its food as eaten, except wheat, worth what a household's hearth makes of it as pottage (120 points), and raw meat, worth its roast (120) for as many logs as the stores hold; every reckoning uses this one valuation (before, the village's food days and famine counted wheat at 20 and the rest at 120). Villagers eat what the player can (`NPCBrain.EDIBLE`: also eggs, milk, carrots and potatoes, in hand or from the pantry), a household roasts its own meat at the hearth with a log, the player's home recipe, and a household's food is kept in its family chest, the pantry (FSE-18, the owner's instruction of 2026-10-20): home (entering, or at a meal), a villager puts the food they carry for eating in the pantry, and the firewood they carry, keeping only trade stock (a food vendor's stock; a trade's inputs; what a producing trade makes, as far as buyers will take it, `_sale_stock`, `TRADE_GOODS`; a helper's building loads stay with the site), and a trader first stocks the chest to the household's reserve horizon; the player's family chest counts in the player's reserve (`World.necessity`) by the same rule (B7-015 after FSE-17: elders starved while a member carried 79 milk no buyer would take) (owner directive 2026-10-20, FSE-00 section 1; B7-015: a keeper starved holding 318 eggs, hunters' families holding meat). Grain counts as pottage only in whole pots (2 grains), across the household's stores; an odd grain is worth its raw food, and relief gives and buys grain in whole pots (B7-015, seed 4). A trader home also puts in the logs needed to roast the chest's meat, up to the reserve horizon, from trade stock if need be, as for its food (B7-015, seed 4: children starved beside raw meat while a member kept logs for sale).
- **Tests:** `game/tests/reserve_test.gd::relief_sources`

### INT-160 · The manor's fields under the shared farming model (FSE-12, FARM-06; behind a switch)
- **Trigger:** A farmer sows or cuts a manor field while balance `shared_manor_farming` is 1.
- **Source:** `game/scripts/core/farming.gd::sow_field`, `game/scripts/core/farming.gd::seed_back`, `game/scripts/core/farming.gd::field_work_minutes`, `game/scripts/core/npc_brain.gd::_farmer`, `game/scripts/core/world.gd::hour`, `game/scripts/core/population.gd::populate`
- **Affects:** Fields, Inventory, Households, Ledger
- **Expected:** (owner, 2026-10-21: behind a test switch, compared before activation; off in the baseline) Sowing takes one wheat seed a cell from the field's farmers' packs, then their households' pantries, as many cells as there is seed; with none the field stays unsown (`field_unsown_no_seed`). The crop is the sown cells times the crop's `yield`, and the cutter gets `seeds_back` seed a sown cell; sowing, cutting and ploughing take the player's time a cell. A new world under the switch starts its farmers with a field's seed between them (a world-setup assumption for the comparison). Off, the old model is untouched: a field yields `field_yield`, sown without seed, the farmer keeping `seed_keep` seed up to `seed_cap`. Seed used and returned are in the ledger (`used_wheat_seed`, `made_wheat_seed`). The comparison runs with `--set shared_manor_farming=1` (economy_sim, and the `set` input of long-sims.yml).
- **Tests:** `game/tests/world_test.gd::_fse12_shared_fields`

### INT-161 · Seasonal village farming (FSE-13; behind a switch)
- **Trigger:** A manor field is sown or grows an hour while balance `seasonal_village_farming` is 1.
- **Source:** `game/scripts/core/world.gd::grow_field`, `game/scripts/core/world.gd::set_field`, `game/scripts/core/npc_brain.gd::_farmer`, `game/scripts/core/farming.gd::seasonal_fields`
- **Affects:** Fields, Calendar
- **Expected:** (owner, 2026-10-21: comparison first, then the owner's review; off in the baseline) The manor's fields keep the player's seasons (`farming.sow_seasons`, `farming.season_rate`): a farmer does not sow in winter ("waiting for the sowing season"), and a growing field gains an hour's share of its growth (`field_grow_seasons` through Life) at the season's rate, none in winter, half in autumn; it is ripe when its growth is complete. The calendar is the 8-day year (OD-21). Off, a field ripens `field_grow_seasons` after sowing whatever the season. Comparison runs: `--set seasonal_village_farming=1`.
- **Tests:** `game/tests/world_test.gd::_fse13_seasonal_fields`

### INT-162 · Planting material from wild plants (SEED-02, SEED-04)
- **Trigger:** The player or a villager picks a ripe wild flower or berry bush; the player plants a cutting or flower seed; a foraging villager comes home.
- **Source:** `game/scripts/core/world.gd::propagation_drop`, `game/scripts/core/world.gd::plant_bush`, `game/scripts/core/world.gd::plant_bush_refusal`, `game/scripts/main.gd::plant_cutting`, `game/scripts/main.gd::interact`, `game/scripts/core/npc_brain.gd::act`, `game/scripts/core/npc_brain.gd::front_goods`, `game/scripts/core/farming.gd::sow`
- **Affects:** Resources, Inventory, Households, Market, Ledger, Save
- **Expected:** (owner directive 2026-10-20 section 1; numbers agent proposals, balance `propagation`) Whoever picks a ripe plant of a kind in `propagation.kinds` (the player or a villager, by the same rule; the bear eating berries gets none) recovers one of its item (`flower_seed`, `red_berry_cutting`, `blue_berry_cutting`) with its `chance`, decided by a hash of the plant's cell, the day and the world seed (no draw from the world's RNG); it is counted `made_`. A villager's goes into the household's pantry with the foraged goods; the household keeps `household_keep` of each and offers the rest for market (the food stall buys it, `BUYS.merchant_food`). The player plants one on free village grass by the sapling rule: it is used up (`used_`) and a young plant of its kind (`planted`, saved with the world) bears `grow_seasons` later at a dawn in its seasons. Sowing a crop and planting a sapling now count the seed or sapling `used_` as well.
- **Tests:** `game/tests/farming_test.gd::test_propagation`, `game/tests/farming_test.gd::test_household_seed`

### INT-163 · Wild plants bear by season (SEED-03)
- **Trigger:** Each dawn, and when a world is made.
- **Source:** `game/scripts/core/world.gd::season_plants`, `game/scripts/core/world.gd::plant_in_season`, `game/scripts/core/world.gd::_new_day`, `game/scripts/main.gd::_show_plants`
- **Affects:** Resources, Calendar, Food, Wildlife
- **Expected:** (agent proposal, balance `plant_seasons`) A berry bush bears only in its seasons (Summer and Autumn): a ripe bush out of season is bare at the dawn (the berries were never items, so nothing leaves the ledger), and a bare one is ripe again at a dawn in season once `plant_regrow_seasons` have passed. A kind not listed (wild flowers) bears all year. Picking never removes a plant (perennial); fruit trees keep their own fruiting seasons (`fruit_trees`). Households forage and bears eat berries only when bushes bear; the game starts in spring with the bushes bare.
- **Tests:** `game/tests/farming_test.gd::test_perennials`, `game/tests/start_test.gd::_plant_gather_tests`

### INT-164 · The seed seller sells to villagers and stocks cuttings (MERCH-01)
- **Trigger:** A farmer's household holds less than `farming.seed_keep` wheat seed in the evening; the caravan visits; the player opens a seed seller's trade window.
- **Source:** `game/scripts/core/npc_brain.gd::_plan_buy_seed`, `game/scripts/core/npc_brain.gd::act`, `game/scripts/core/npc_brain.gd::_caravan_seeds`, `game/scripts/core/farming.gd::buy_seed_item`, `game/scripts/core/farming.gd::seed_item_price`, `game/scripts/core/farming.gd::propagule_offers`, `game/scripts/ui/game_ui.gd::show_trade`
- **Affects:** Market, Coins, Inventory, Households, Fields
- **Expected:** A seed seller (a farmer or the food stall's merchant) sells crop seed, cuttings and flower seed from its own stock to the player and to villagers by one rule: the crop's `seed_price` or the kind's `propagation` price less the buyer's Trading bonus, paid to the seller (World.trade; coins conserved). A farmer short of seed walks to the stall and buys the shortfall with their own coins within the household's reserve. Cuttings and flower seed reach the stall only from the caravan (`farming.caravan_seed_stock`, the merchant's coins leaving the village, `imported_`) and from households' surplus sold to it; nothing is stocked from nothing.
- **Tests:** `game/tests/farming_test.gd::test_seed_seller`

### INT-165 · Relief from the manor's own stock (TREAS-01)
- **Trigger:** The manor's relief round finds a household short of food.
- **Source:** `game/scripts/core/npc_brain.gd::_relief`, `game/scripts/core/npc_brain.gd::_relief_from_granary`
- **Affects:** Granary, Households, Coins, Market, Ledger
- **Expected:** Relief gives the granary's grain, then the granary's other food (stores taken over from a household that died out, goods carried back), before the treasury buys anything. A bought relief good passes through the granary (it is the manor's before it is given), and a purchase whose goods cannot move is not paid. No food or coin from nothing.
- **Tests:** `game/tests/treasury_test.gd`

### INT-166 · Orphans take their household's stores; the player adopts (REC-001)
- **Trigger:** A household's last adult dies leaving children; the player offers a child a home.
- **Source:** `game/scripts/core/guardianship.gd`, `game/scripts/ui/game_ui.gd::_relation_choices`
- **Affects:** Households, Inventory, Ledger
- **Expected:** The orphaned household's pantry goes with its children, child by child (a clan child carries its share); the receiving household is re-evaluated at once. The player's partner's household stands in the guardianship order by kinship; the player may take in a child not already with family at least as close.
- **Tests:** `game/tests/family_test.gd`

### INT-167 · The reeve's office passes on (EQ-04)
- **Trigger:** The reeve dies.
- **Source:** `game/scripts/core/npc_brain.gd::reeve_day`, `game/scripts/core/npc_brain.gd::_reeve_succession`
- **Affects:** Households, Ledger, Calendar
- **Expected:** The office opens as a vacancy (World.vacancies, job "reeve") and is filled by the trades' succession rule after `succession_days`: an adult without a trade, the late reeve's household first, otherwise a caravan newcomer. Public works resume under the new reeve.
- **Tests:** `game/tests/succession_test.gd`

### INT-168 · Built market stalls: build, stock, open, close (STALL-01..04, STALL-06)
- **Trigger:** The player builds a stall from 3 planks, or a household with surplus goods and planks does in its evening work; a seller opens or closes it; it sells out.
- **Source:** `game/scripts/core/stalls.gd::build`, `game/scripts/core/stalls.gd::open`, `game/scripts/core/stalls.gd::close`, `game/scripts/core/stalls.gd::after_sale`, `game/scripts/core/stalls.gd::daily`, `game/scripts/core/construction.gd::build_stall`, `game/scripts/core/business.gd`
- **Affects:** Market, Inventory, Coins, Households, Building, Ledger
- **Expected:** A stall takes 3 planks from the builder's pack (counted as used in building) on clear ground the builder may use, at least 3 tiles from another stall. Goods moved in exist only in the stall. An open stall sells unattended to the existing buyers through business.gd's sale path; a household never buys back its own goods. Closing stops sales and keeps the unsold stock; selling out closes it. A dead household's built stall becomes the manor's (stock to the granary); merchant hiring never takes a pitch or a built stall.
- **Tests:** `game/tests/stalls_test.gd`

### INT-169 · Stall settlement and the manor's commission (STALL-05, TREAS-01)
- **Trigger:** A stall closes or sells out; a merchant leaves their stall; a pitch's takings are collected.
- **Source:** `game/scripts/core/stalls.gd::settle`, `game/scripts/core/stalls.gd::record_sale`, `game/scripts/core/stalls.gd::after_trade`, `game/scripts/core/world.gd::trade`
- **Affects:** Coins, Treasury, Market, Ledger
- **Expected:** Every market stall (built, pitch, the merchants' six) keeps its session's takings in the till while open (not withdrawable, not used for rent or wages). Settlement reckons 5 % of the session's sales in hundredths of a coin plus the stall's carried fraction; whole coins go to the treasury, the rest to the seller, the remainder (0-99 hundredths) carries to that stall's next settlement. Coins are only moved, never made (World.total_coins counts tills). The pitch's 5-coin daily rent is kept as a separate rent; shops and storefronts keep their counter terms (CTR-04).
- **Tests:** `game/tests/stalls_test.gd`, `game/tests/business_test.gd`

### INT-170 · Farmland: marking out, leasing or buying, the fence (FARM-09, FARM-01, FARM-07, FARM-02)
- **Trigger:** The player marks out farmland from the Build menu (drag two corners); a household decides to take a plot (FarmPlots.consider).
- **Source:** `game/scripts/core/farm_plots.gd::terms`, `game/scripts/core/farm_plots.gd::refusal`, `game/scripts/core/farm_plots.gd::claim`, `game/scripts/core/farm_plots.gd::build_fence`, `game/scripts/core/farm_plots.gd::consider`, `game/scripts/core/property.gd::claim`, `game/scripts/main.gd`
- **Affects:** Property, Treasury, Coins, Inventory, Households, Building, Fields
- **Expected:** A farmland parcel is an ordinary Property parcel marked farm: price Property.land_price (60 per 90 cells), weekly lease ceil(price x 0.1) by the existing lease, collection, arrears and escheat rules; bought land pays no rent; every payment goes to the treasury through Property._pay_manor. A plot may not overlap land, fields, pens, buildings, stalls, roads or solid ground, and its gate must open onto reachable ground. The fence follows the pen rule on the real perimeter (ceil((border-1)/3) planks, the gate free) plus farm_plot.gate_stone stone, from real inventory; it is solid but for the gate, and the plot is ploughed only once fenced. Households use the same prices and rules (no free land or materials).
- **Tests:** `game/tests/farm_plots_test.gd`, `game/tests/farm_place_test.gd`

### INT-171 · Household farm work and the farmland harvest (FARM-03, FARM-04, FARM-05, FSE-15)
- **Trigger:** A household holding farmland: adults in their evening or when out of work, elders by day for light tasks.
- **Source:** `game/scripts/core/farm_plots.gd::plan_work`, `game/scripts/core/farm_plots.gd::till`, `game/scripts/core/farm_plots.gd::sow`, `game/scripts/core/farm_plots.gd::harvest`, `game/scripts/core/farm_plots.gd::land_requirement`, `game/scripts/core/npc_brain.gd::act`
- **Affects:** Fields, Inventory, Households, Market, Calendar, Ledger
- **Expected:** Household cells use Farming's per-cell rules: one seed a cell from the household's stores (bought from the food merchant or farmers above their seed_keep when short, within the reserve), growth by the season's rate, the crop's yield and seed back, the player's seconds a cell; the harvest goes to the household's pantry. Children do not work; members below rest.seek_below rest. A household takes a plot when short of food or living, with an able adult, in a sowing season, free ground near home and coins above its necessity reserve; it gives up a lease when nobody can work it. land_requirement weighs a year's food need against a cell's net yearly yield, capped by labour.
- **Tests:** `game/tests/farm_plots_test.gd`

### INT-172 · Keepers buy feed in part lots; farmers hold keepers' feed for sale; the elderly culled first (FARM-08B)
- **Trigger:** A pen's trough holds less than two days' need and the keeper has no grain in hand or at home; a farmer decides what to keep in hand for sale; a keeper short of feed culls.
- **Source:** `game/scripts/core/npc_brain.gd::_keeper`, `game/scripts/core/npc_brain.gd::_sale_stock`, `game/scripts/core/npc_brain.gd::feed_want`, `game/scripts/core/fauna.gd::surplus`
- **Affects:** Livestock, Market, Coins, Households, Granary
- **Expected:** The keeper buys whatever part of its feed want the best seller can spare and the keeper can pay for (the SHOP-01 part-lot rule, as the player may), not only a whole three-day lot. Farmers keep in hand for sale what the keepers lack of their four-day feed reserve, besides what the cook and food merchant want, so grain is not all put away in family chests no one buys from. A keeper short of feed culls beyond the breeding stock elderly animals first (they no longer breed), then the young. No feed or animal from nothing.
- **Tests:** `game/tests/herd_test.gd`

### INT-173 · The adit gallery: a separate level map tied to its surface portal (MIN-A, OD-29)
- **Trigger:** The player or a villager steps through the adit portal; a villager's goal lies on another level.
- **Source:** `game/scripts/core/underground.gd::portal_from`, `game/scripts/core/underground.gd::next_leg`, `game/scripts/core/underground.gd::find_path`, `game/scripts/core/level_map.gd::find_path`, `game/scripts/core/world.gd`
- **Affects:** Resources, Employment, Inventory, Save, Interface
- **Expected:** Underground space is its own map, entered only through a portal fixed to a surface cell; open pits stay on the surface. A villager whose goal is on another level walks to the portal, crosses and paths on the far level (one router for every level). Seams below use the surface seam rules; what is carried crosses with its carrier, nothing is made or lost at the portal. The gallery and its seams are saved (save version 17).
- **Tests:** `game/tests/underground_test.gd`

### INT-174 · Quarry stone from worked-out seams and boulders (MIN-B, B7-007)
- **Trigger:** A seam's ore is used up; the player swings at its rock; a labourer, miner, manor quarry hand or contract seller looks for stone.
- **Source:** `game/scripts/core/world.gd::quarry_stone_left`, `game/scripts/core/world.gd::_quarry_sources`, `game/scripts/core/world.gd::_open_quarried`, `game/scripts/core/manor_work.gd::post_quarry`, `game/scripts/core/npc_brain.gd`
- **Affects:** Resources, Inventory, Employment, Market, Treasury, Building, Ledger
- **Expected:** Each ore seam keeps a second finite pool of stone (20) that opens only once its ore is out; the ore never refills. Player and villagers quarry it, and the village's boulders, by the seam rule (time, wear, xp, mined_stone). The village's stone left (seams, leftover rock, boulders) sets the caravan's stone threshold, the reeve's quarry posting and contract feasibility. A fully quarried cell opens like a broken boulder, on the surface or widening the gallery.
- **Tests:** `game/tests/quarry_test.gd`, `game/tests/underground_test.gd`

### INT-175 · Negotiated procurement contracts (CON-01)
- **Trigger:** A buyer (the player, a villager, a business, the manor through its reeve) proposes a contract for an item, quantity, unit price and term; a villager makes the player a standing offer; the other side accepts, counters, refuses, signs, delivers or lets it lapse.
- **Source:** `game/scripts/core/contracts.gd::evaluate`, `game/scripts/core/contracts.gd::obligations`, `game/scripts/core/contracts.gd::propose`, `game/scripts/core/contracts.gd::offer_to_player`, `game/scripts/core/contracts.gd::counter_offer`, `game/scripts/core/contracts.gd::buyer_answer`, `game/scripts/core/contracts.gd::accept_offer`, `game/scripts/core/contracts.gd::deliver`, `game/scripts/core/contracts.gd::reserved_total`, `game/scripts/core/contracts.gd::_pay_units`, `game/scripts/core/contract_services.gd::means`, `game/scripts/core/npc_brain.gd`
- **Affects:** Coins, Market, Inventory, Employment, Treasury, Workshops, Households, Ledger, Interface, Save
- **Expected:** One contract record for player-villager, villager-player and villager-villager. The seller weighs feasibility, skill, tools, stock, time (with a 15 % spare margin; a later day countered rather than a refusal), its obligations (manor jobs, building-site carrying, the manor's tool orders it is forging, a post at a stall: read, never changed), household needs, input costs and what its hours earn in its own trade, relationship (friend's price for friends, partners and kin) and risk (a premium per early cancellation on record); counters both ways through one buyer rule. A contract of at least `formal_total` coins is formal and is concluded only face to face (within `sign_reach`, same place and level; the reeve for the manor; owner Q18-13): a distant villager buyer walks over first, nothing set aside meanwhile; unsigned in 2 days, or a party dead, it ends with nothing moved. Small agreements need no signing. The buyer's coins are reserved on agreement, paid per unit delivered, counted in the coin census and returned on lapse or cancel; no double delivery or payment. Goods and services (CON-02, owner 2026-10-21) share the record, evaluation, counters, signing and one payment path: coins reserved at agreement, each unit paid only when delivered or done. Q-C1..Q-C9 are owner-approved Build 17 defaults (`docs/build17/CON01_COMPLETION.md`).
- **Tests:** `game/tests/contracts_test.gd`

### INT-176 · Goods decay: stored food spoils, clothes, armour and carts wear (DVW-B4)
- **Trigger:** Each dawn (spoilage and wear of what is worn); a blow on an armoured fighter.
- **Source:** `game/scripts/core/decay.gd::dawn`, `game/scripts/core/decay.gd::spoil_inv`, `game/scripts/core/decay.gd::wear_npc`, `game/scripts/core/decay.gd::wear_player`, `game/scripts/core/npc_brain.gd`
- **Affects:** Food, Inventory, Equipment, Granary, Households, Market, Combat, Ledger
- **Expected:** Stored food spoils at its item's rate by a seeded draw, so the same world spoils the same way; worn clothes, armour and carts lose condition and break at zero. Spoiled goods leave through the ledger as decay, never silently. A guard whose armour wore out buys again by the ordinary rule.
- **Tests:** `game/tests/decay_test.gd`

### INT-177 · Cliff steps, stairs and walkways; no unreachable cells (B14-07, DVW-A10)
- **Trigger:** The player cuts cliff steps or builds wooden stairs or a walkway; the overworld is generated.
- **Source:** `game/scripts/core/terrain.gd::refusal`, `game/scripts/core/terrain.gd::cost`, `game/scripts/core/terrain.gd::plan`, `game/scripts/core/terrain.gd::targets_at`
- **Affects:** Overworld, Building, Inventory, Crafting, Player state
- **Expected:** Steps need a pickaxe and Mining, stairs and walkways planks, nails, a mallet and Carpentry, taken from real inventory; each opens a crossing over a cliff or water. Ground nothing can reach is sealed, so no item or creature is lost in a black-hole space.
- **Tests:** `game/tests/terrain_test.gd`

### INT-178 · Nails and mallets made to order for the goods merchant (B14-07, PAR-04)
- **Trigger:** A goods merchant holds fewer than 24 nails or 2 mallets; a smith or carpenter at work.
- **Source:** `game/scripts/core/npc_brain.gd::_carpenter_mallet`, `game/scripts/core/npc_brain.gd`
- **Affects:** Crafting, Workshops, Market, Coins, Inventory
- **Expected:** The smith forges nails (iron bars, taken from its other forging) and the carpenter makes a mallet (a log and a plank at the workbench) only when a goods merchant wants them, and sells all of it to that buyer; nothing is made for an absent buyer. The player crafts both by the same recipes. Coins only change hands.
- **Tests:** `game/tests/crafts_test.gd`

### INT-179 · Red flowers grow outside the village (PL1-12)
- **Trigger:** The overworld generator draws a chunk.
- **Source:** `game/scripts/core/overworld.gd`, `tools/build_overworld_tiles.py`
- **Affects:** Overworld, Resources, Save
- **Expected:** The low red flower (tile 2656) is among the wild flowers outside the village, picked, regrown and saved like the others. Overworld generator version 2; every object keeps its cell, so a version 1 save still applies its felled trees and worked rocks.
- **Tests:** `game/tests/crafts_test.gd`, `game/tests/overworld_test.gd`

### INT-180 · Prospecting clues, samples and assay (MIN-C)
- **Trigger:** The world starts or loads (clues placed from the seed); the player or a prospector samples in a clue's area; a holder asks a smith to assay a sample; a prospector reports to the manor.
- **Source:** `game/scripts/core/prospecting.gd::generate`, `game/scripts/core/prospecting.gd::take_sample`, `game/scripts/core/prospecting.gd::assay`, `game/scripts/core/prospecting.gd::npc_assay`, `game/scripts/core/prospecting.gd::plan`, `game/scripts/core/prospecting.gd::report`, `game/scripts/main.gd`
- **Affects:** Resources, Inventory, Coins, Workshops, Employment, Save, Interface, Ledger
- **Expected:** Clues come from the world seed alone (no rng draw, overworld generator unchanged), only on wild ground outside the settlement footprint (ORE-PLACE-01, `Prospecting.wild_cells`: stains, sample spots, bodies and trial pits; open-pit staking unchanged); 55 % lie over a mineral body, the rest are false, and no body is added to the deposits (that is MIN-D). One sample a cell, four a clue, with a prospecting kit that wears; samples carry their origin. A smith assays at the forge for a 6-coin fee paid holder to smith, 1 coal and 40 minutes queued after its current work; the reading is seeded and can miss or mislead, confidence at most 0.9. Only the sampler, the smith and (once reported) the manor know a reading. No coins or ore from nothing.
- **Tests:** `game/tests/prospecting_test.gd`

### INT-181 · A prospector orders its kit by contract (MIN-C, CON-01)
- **Trigger:** A prospector has no kit and none is for sale.
- **Source:** `game/scripts/core/prospecting.gd::_get_kit`, `game/scripts/core/contracts.gd::propose`, `game/scripts/core/contracts.gd::buyer_answer`, `game/scripts/core/world.gd::work_craft`
- **Affects:** Crafting, Workshops, Coins, Market
- **Expected:** The prospector proposes a CON-01 contract for one kit at its value and answers a smith's counter by the shared buyer rule; a smith forges it (1 iron bar, 1 plank, 1 leather) and delivers it against the reserved coins.
- **Tests:** `game/tests/prospecting_test.gd`, `game/tests/contracts_test.gd`

### INT-182 · Trial pits open hidden bodies as ordinary seams (MIN-D, OD-28, OD-29)
- **Trigger:** The player or a villager digs a trial pit with a pickaxe within 2 cells of a clue, on clear, open ground.
- **Source:** `game/scripts/core/discovery.gd::trial_dig`, `game/scripts/core/discovery.gd::_open_seam`, `game/scripts/main.gd`, `game/scripts/core/manor_work.gd::do_step`
- **Affects:** Resources, Inventory, Player state, Employment, Save, Ledger
- **Expected:** One rule for player and villagers (120 minutes, pickaxe wear 2, 6 Mining xp, at most 4 pits a clue); most pits miss and a misleading stain never yields. A struck body becomes one ordinary seam in World.deposits (same record, swing, host rock and save as any seam), sized as the village's per-seam amount x grade / 5, never refilled; `found_<ore>` records the amount so deposits balance as start + found - end = mined. Opened seams are restored on load.
- **Tests:** `game/tests/discovery_test.gd`

### INT-183 · Village mining capability levels from present assets (MIN-D)
- **Trigger:** Each dawn.
- **Source:** `game/scripts/core/discovery.gd::dawn`, `game/scripts/core/discovery.gd::evaluate`, `game/scripts/core/world.gd`
- **Affects:** Employment, Workshops, Households, Treasury
- **Expected:** Levels are computed from what villagers, households and the manor hold now (capabilities.json) and gate nothing (owner, Q18-9: they shape pay and output only, the effect coming with Expansion 18): 1 surface extraction from the start; 2 needs a living prospector, a kit, a smith, a forge and a find the manor knows; 3 and 4 wait for MIN-E and MIN-F. The player's own goods do not count. Levels fall when the assets go; each change is logged with its reason. Nothing is granted.
- **Tests:** `game/tests/discovery_test.gd`

### INT-184 · Prospecting adopted through the labour market and the manor's job board (MIN-D, MIN-C-Q1)
- **Trigger:** The labour market's review; the reeve's evening postings; a miner with no ore left.
- **Source:** `game/scripts/core/discovery.gd::prospector_place`, `game/scripts/core/discovery.gd::survey_target`, `game/scripts/core/discovery.gd::trial_target`, `game/scripts/core/manor_work.gd::post_discovery`, `game/scripts/core/npc_brain.gd::job_market`, `game/scripts/core/npc_brain.gd::reeve_day`, `game/scripts/core/npc_brain.gd::_miner`
- **Affects:** Employment, Treasury, Wages, Coins, Workshops
- **Expected:** One prospector's place opens while nobody prospects and villagers take it by the ordinary job rules. The reeve posts one survey at a time (two samples, assays, a report; 22 coins from the treasury, the worker paying the assay fees) and one trial pit at a time for the manor's best known find (8 coins for the labour, strike or not), as ordinary manor work, not a mining wage. A miner whose ore is out takes a trial pit before quarrying. Independent prospecting and CON-01 sales stay open; no ownership or rights in finds (MIN-C-Q2).
- **Tests:** `game/tests/discovery_test.gd`, `game/tests/prospecting_test.gd`

### INT-185 · An open pit staked: its ground is reserved (MIN-E)
- **Trigger:** The player stakes a pit with a pickaxe in hand, or the manor stakes one for a known find no trial pit can reach.
- **Source:** `game/scripts/core/open_pit.gd::open_pit`, `game/scripts/core/open_pit.gd::site_refusal`, `game/scripts/core/manor_work.gd::post_pits`, `game/scripts/main.gd`
- **Affects:** Property, Fields, Building, Market, Resources, Ledger
- **Expected:** Pits are on the surface inside the village (OD-29), 5x5 with a walkable border and two spoil heaps. Planting, land claims, stalls, house sites and trial pits all refuse pit ground, its border and heaps; the ground is counted once in the ledger.
- **Tests:** `game/tests/openpit_test.gd`

### INT-186 · Digging an open pit unit by unit (MIN-E)
- **Trigger:** The player or a villager (the manor's excavate job, or a miner with no ore left) digs a pit cell.
- **Source:** `game/scripts/core/open_pit.gd::dig`, `game/scripts/core/manor_work.gd::do_step`, `game/scripts/core/npc_brain.gd`, `game/scripts/main.gd`
- **Affects:** Inventory, Equipment, Player state, Employment, Treasury, Wages, Resources, Ledger
- **Expected:** One rule for player and villagers: each dig takes one finite unit of the cell's layer (topsoil, dirt, spoil, then stone), wears the pickaxe 1, gives 4 Mining xp and is counted `dug_<item>`; terraces and a ramp keep the floor reachable and a dig that would cut a walkable cell off is refused. The manor's excavate job pays the existing quarry rate per load from the treasury (no new wage); capability levels gate nothing (Q18-9).
- **Tests:** `game/tests/openpit_test.gd`

### INT-187 · A pit dug to rock exposes a hidden body as an ordinary seam (MIN-E, MIN-D, OD-28)
- **Trigger:** A pit cell (not the ramp) is dug down to the rock within 2 cells of a prospecting body.
- **Source:** `game/scripts/core/open_pit.gd::_expose`, `game/scripts/core/discovery.gd::expose`, `game/scripts/core/discovery.gd::_open_seam`
- **Affects:** Resources, Employment, Market, Ledger
- **Expected:** The body opens through the trial pit's code into one ordinary seam in World.deposits (host rock, `found_<ore>` counted, mined by the one swing, never refilled); a misleading stain has nothing under it.
- **Tests:** `game/tests/openpit_test.gd`, `game/tests/discovery_test.gd`

### INT-188 · Earth tipped on heaps, taken or backfilled (MIN-E)
- **Trigger:** A digger tips its load; someone takes earth from a heap; earth is put back into the pit.
- **Source:** `game/scripts/core/open_pit.gd::tip`, `game/scripts/core/open_pit.gd::take`, `game/scripts/core/open_pit.gd::backfill`
- **Affects:** Containers, Inventory, Resources, Ledger, Save
- **Expected:** Topsoil, dirt and spoil are real items (value 0, no buyer yet) held in the heaps, which are solid while they hold anything and are counted in the census; stone is kept. Backfill returns the last layer dug first. Nothing appears or vanishes. Pits and heaps are saved (save version 17, "pits"; absent: none).
- **Tests:** `game/tests/openpit_test.gd`

### INT-189 · A service contract's work done through the existing work code (CON-02)
- **Trigger:** A seller under a service contract (digging the buyer's open pit; surveying a stain) does its next unit.
- **Source:** `game/scripts/core/contract_services.gd::means`, `game/scripts/core/contract_services.gd::plan`, `game/scripts/core/contract_services.gd::step`, `game/scripts/core/open_pit.gd::dig`, `game/scripts/core/open_pit.gd::tip`, `game/scripts/core/prospecting.gd::take_sample`, `game/scripts/core/prospecting.gd::assay`
- **Affects:** Employment, Coins, Inventory, Resources, Containers, Ledger, Save
- **Expected:** The going rate is the manor job board's rate for the same work (no new wage). A pit dig uses the open-pit dig and tip code (earth to the pit's heaps, stone to the buyer's chest or collected in the window); a survey takes samples with the seller's own kit, pays the assay fee as the manor's survey does, and tells each reading to the buyer face to face. Each unit is paid when done from the coins reserved at agreement; cancel or lapse returns the rest; units done stay paid. Goods a seller carries on a service are counted in the census. Manor tool orders, paid quests, the job board, carriers and attendants are unchanged and count only as obligations.
- **Tests:** `game/tests/services_test.gd`

### INT-190 · Tunnels cut through rock, within reach of a timber support (MIN-F)
- **Trigger:** The player or a villager cuts a rock cell below ground with a pickaxe; someone sets up a timber support.
- **Source:** `game/scripts/core/mine_works.gd::dig_refusal`, `game/scripts/core/mine_works.gd::dig`, `game/scripts/core/mine_works.gd::place_support`, `game/scripts/main.gd`
- **Affects:** Inventory, Equipment, Player state, Resources, Crafting, Save, Ledger
- **Expected:** One rule for player and villagers: a rock cell under the hill (rock all round, never a seam, from an open face, within 2 cells of a support) gives 3 stone then 2 spoil, one unit per cut (counted `cut_<item>`, pickaxe wear, Mining xp), and opens only after its last unit; no floor is left unreachable. Supports (sawhorse: 1 log, 2 planks) are set up with a mallet from real inventory and used up; their only effect is where rock may be cut (no collapse is simulated); the capability evaluator may count them, gating nothing (Q18-9). Saved in "mine_works".
- **Tests:** `game/tests/underground_ext_test.gd`

### INT-191 · Track and minecarts (MIN-F)
- **Trigger:** Track is laid (workbench: 2 planks, 4 nails; a mallet); a minecart (the handcart parts chain) is set down on track and pulled; a minecart reaches a level's mouth.
- **Source:** `game/scripts/core/mine_works.gd::lay_track`, `game/scripts/core/mine_works.gd::set_down_minecart`, `game/scripts/core/carts.gd::place`, `game/scripts/core/carts.gd::pull_speed_for`, `game/scripts/core/carts.gd::cross`, `game/scripts/core/world.gd::player_through`, `game/scripts/core/world.gd::_npc_through`
- **Affects:** Inventory, Crafting, Containers, Resources, Save
- **Expected:** Track sections are used up from real inventory, laid on a level's floor or the mine yard. A minecart follows its puller only along track on its level (0.95 of walking speed against a handcart's 0.75) and crosses a mouth only with track on both sides; handcarts are still refused at the adit. Goods ride in the cart and are never made or lost.
- **Tests:** `game/tests/underground_ext_test.gd`

### INT-192 · The natural cave and stacked levels (MIN-H)
- **Trigger:** The world is set up or loaded; a villager or the player goes through the cave's mouth; awareness, reach or fights between people.
- **Source:** `game/scripts/core/underground.gd::levels_at`, `game/scripts/core/underground.gd::reachable_levels`, `game/scripts/core/world.gd::level_at`, `game/scripts/core/world.gd::_npc_through`
- **Affects:** Resources, Employment, Market, Crime, Combat, Save
- **Expected:** A natural cave on level -2 under the mine hill with its own surface mouth, generated from the seed by the gallery's generator with its own salt (the adit gallery unchanged); its seams are ordinary deposit records, so the cave's ore counts as the village's own (labour market, caravan threshold, quests). Villagers reach it through the one level router. Where levels stack, a person's level is resolved by who stands there; nobody sees, reaches or fights across levels. Underground generator version 2; saves keep version 17 with defaults for absent keys.
- **Tests:** `game/tests/underground_ext_test.gd`, `game/tests/underground_test.gd`

### INT-193 · Underground stability, collapse and support wear (MIN-F2, MIN-F-Q1)
- **Trigger:** Each dawn, for cells the works have dug and for shafts.
- **Source:** `game/scripts/core/mine_works.gd::dawn`, `game/scripts/core/mine_works.gd::stability`, `game/scripts/core/mine_works.gd::collapse`, `game/scripts/core/mine_works.gd::repair`, `game/scripts/core/world.gd`
- **Affects:** Resources, Inventory, Containers, Save, Ledger
- **Expected:** Stability from nearby supports by condition and distance plus a capped share from backfilled neighbours; below the threshold a cell may collapse by a seeded hash of seed, day and cell (the world's random stream untouched), filling with rubble as spoil, blocking paths, crushing a support on it, and moving people, carts and piles to the nearest floor; rubble is dug out again as spoil. Supports and ladders wear daily and are repaired with real planks and nails. Generated gallery and cave cells are treated as stable. Rates are balance parameters (`mine_works.json`).
- **Tests:** `game/tests/underground_struct_test.gd`

### INT-194 · Hidden underground ore and the manor's tunnelling jobs (MIN-F2, MIN-F-Q2)
- **Trigger:** A tunnel or shaft cut beside hidden ore; the reeve's evening.
- **Source:** `game/scripts/core/mine_works.gd::expose_beside`, `game/scripts/core/discovery.gd::open_hidden`, `game/scripts/core/manor_work.gd::post_tunnels`, `game/scripts/core/mine_works.gd::manor_face`
- **Affects:** Resources, Employment, Treasury, Wages, Ledger
- **Expected:** Hidden ore exists in the seeded world beforehand and opens as an ordinary seam (`found_<ore>`), depleting and never refilled; villagers gain no knowledge of unexposed ore. The manor posts one tunnelling job at a time, only under sound timber, on the existing job board and wage rules from the treasury; independent mining stays separate.
- **Tests:** `game/tests/underground_struct_test.gd`

### INT-195 · Minecart preference for miners below ground (MIN-F2, MIN-F-Q3)
- **Trigger:** A miner below ground with a full load.
- **Source:** `game/scripts/core/mine_works.gd::haul_costs`, `game/scripts/core/mine_works.gd::cart_haul_plan`, `game/scripts/core/mine_works.gd::cart_act`, `game/scripts/core/carts.gd::room`, `game/scripts/core/npc_brain.gd`
- **Affects:** Containers, Inventory, Employment
- **Expected:** The miner uses a household minecart on connected track within reach, with room and unclaimed, only when its cost in walked cells per unit is lower than carrying; one claimant at a time; goods loaded, pulled along the track and unloaded, never made or lost; otherwise the miner carries.
- **Tests:** `game/tests/underground_struct_test.gd`

### INT-196 · Shafts, ladders and deeper levels (MIN-F2, MIN-F-Q4)
- **Trigger:** A shaft dug unit by unit and a ladder set (3 planks, 6 nails).
- **Source:** `game/scripts/core/mine_works.gd::dig_shaft`, `game/scripts/core/mine_works.gd::install_ladder`, `game/scripts/core/underground.gd::add_level`, `game/scripts/core/underground.gd::add_portal`
- **Affects:** Resources, Inventory, Employment, Save
- **Expected:** A laddered shaft becomes a portal the one level router uses; the first shaft below the cave makes level -3 (rock with its own hidden ore), levels stop at -4; goods change level only in someone's hands; carts are refused at shafts; shafts are in the stability check.
- **Tests:** `game/tests/underground_struct_test.gd`

### INT-197 · Player-ordered backfilling (MIN-F2, MIN-F-Q5)
- **Trigger:** The player chooses Backfill Tunnel (or fills a cell themselves).
- **Source:** `game/scripts/core/manor_work.gd::order_backfill`, `game/scripts/core/manor_work.gd::cancel_backfill`, `game/scripts/core/mine_works.gd::fill`, `game/scripts/main.gd`
- **Affects:** Coins, Inventory, Employment, Resources, Save, Ledger
- **Expected:** Only the player's action creates an order; its wage comes from the player's coins and is held until done; labourers may take it from the board (manor hands may not) and carry the player's spoil from the depot; units placed equal units removed (`filled_spoil`); a filled cell blocks travel and adds limited, capped stability, never repairing timber; re-dug fill returns as spoil, never ore; cancelling returns the held wage and leaves placed fill. No villager or manor ever starts a backfill.
- **Tests:** `game/tests/underground_struct_test.gd`

### INT-198 · Stone dressed into building blocks for construction (STONE-01)
- **Trigger:** A labourer (or the player) dresses stone at a workbench; a building site or room takes its materials.
- **Source:** `game/data/recipes.json`, `game/scripts/core/npc_brain.gd::_mason`, `game/scripts/core/world.gd::work_craft`, `game/data/balance.json`
- **Affects:** Crafting, Building, Resources, Market, Inventory, Employment, Save
- **Expected:** Quarried raw stone is the only source of blocks, 2 stone to 2 blocks (`exact`, no skill save or bonus); labourers dress only when the raw-goods merchant or open building sites want blocks, buying a mallet and stone if needed, and sell blocks to the merchant and builders; houses, workshops and rooms take blocks where they took stone, in the same numbers; fittings, mending, the farmland gate, contracts and the caravan keep raw stone; sites from older saves keep their recorded stone cost and refund stone. No block from nothing.
- **Planned (Expansion 18, not built):** the Stoneworking skill governs dressing and how much stone becomes blocks, the rest conserved as waste (STONE-04, STONE-05); an iron chisel from the smiths is needed with the mallet (STONE-06), linking stoneworking to smithing and iron; the stonecutter trade and villagers dressing for their own use (X18-STONECUT, STONE-02); materials by kind of repair (STONE-03).
- **Tests:** `game/tests/stone_test.gd`, `game/tests/housing_test.gd`, `game/tests/play_test.gd`

### INT-199 · A recipe's required tool, one rule for player and villagers (STONE-01)
- **Trigger:** Anyone crafts a recipe that names a `tool` (today `dress_stone`, the mallet).
- **Source:** `game/scripts/core/world.gd::work_craft`, `game/scripts/core/npc_brain.gd::_can_make`, `game/scripts/core/npc_brain.gd::_do_recipe`, `game/scripts/main.gd`
- **Affects:** Crafting, Equipment, Inventory, Employment
- **Expected:** Without the tool the craft is refused ("You need a mallet.") for the player and skipped by villagers and contract work alike; each craft wears the tool by 1.
- **Tests:** `game/tests/stone_test.gd`, `game/tests/contracts_test.gd`

### INT-200 · The resident player counted in the village's mining capability (MIN-D2, MIN-SKILLCAP)
- **Trigger:** Dawn, when the capability levels are evaluated.
- **Source:** `game/scripts/core/discovery.gd::dawn`, `game/scripts/core/discovery.gd::evaluate`
- **Affects:** Player state, Employment, Equipment, Households
- **Expected:** While the player's family has a home in the village, the player counts by the villagers' rule (skills, and the tools in pack and home chest), read only, never moved; leaving drops them at the next dawn. People count by skill and tools, not job title; a tool in a household store counts for one member. Levels are reported only, never a gate (Q18-9).
- **Tests:** `game/tests/parity_mining_test.gd`, `game/tests/discovery_test.gd`

### INT-201 · A trial pit's earth left in a pile and reused (MIN-D3)
- **Trigger:** A trial pit is dug by the player, a villager or a manor job.
- **Source:** `game/scripts/core/discovery.gd::trial_dig`, `game/scripts/main.gd`, `game/scripts/core/manor_work.gd::do_step`, `game/scripts/core/open_pit.gd::backfill`
- **Affects:** Resources, Loot, Inventory, Ledger
- **Expected:** One cell of earth down to the rock (2 topsoil, 3 dirt, 3 spoil), counted `trial_ground_`/`dug_`, left in a pile beside the pit; anyone may take it, carry it or tip it into an open pit (`backfilled_`). No coins, stone or ore from the earth; goods conserved.
- **Tests:** `game/tests/parity_mining_test.gd`, `game/tests/discovery_test.gd`

### INT-202 · Earth by shovel, rock by pickaxe, for every digger and job (MIN-SHOVEL)
- **Trigger:** Anyone digs a pit, a trial pit, a tunnel's fallen rock or fill, or takes a dig job or contract.
- **Source:** `game/scripts/core/open_pit.gd::dig`, `game/scripts/core/mine_works.gd::dig`, `game/scripts/core/manor_work.gd::excavate_cell`, `game/scripts/core/contract_services.gd::means`
- **Affects:** Equipment, Resources, Employment, Crafting
- **Expected:** Topsoil, dirt, spoil, fallen rock and fill take a shovel; stone and cutting rock take a pickaxe; the tool used wears and may break, for the player and villagers alike. Jobs and contracts only take cells the worker's tools can dig; older saves' open jobs and part-dug pits are not stranded.
- **Tests:** `game/tests/parity_mining_test.gd`, `game/tests/openpit_test.gd`, `game/tests/underground_ext_test.gd`, `game/tests/services_test.gd`

### INT-203 · Shovels made to want and bought with own coins (MIN-SHOVEL)
- **Trigger:** The goods merchant wants shovels, or a miner can take posted digging only for want of one.
- **Source:** `game/scripts/core/npc_brain.gd::_carpenter_shovel`, `game/scripts/core/npc_brain.gd::_buy_tool`, `game/scripts/core/manor_work.gd::shovel_would_open`, `game/data/recipes.json`
- **Affects:** Crafting, Market, Coins, Inventory
- **Expected:** The smith forges a blade (1 iron bar), the carpenter makes a haft (1 plank) and assembles the shovel; they are made only to a buyer's want and sold to the merchant's stock; a miner buys one with its own coins. Nothing free.
- **Tests:** `game/tests/parity_mining_test.gd`, `game/tests/crafts_test.gd`

### INT-204 · Digging refused on held land and the manor's fields (MIN-RIGHTS)
- **Trigger:** Anyone marks out a pit or digs a trial pit.
- **Source:** `game/scripts/core/open_pit.gd`, `game/scripts/core/discovery.gd::trial_refusal`
- **Affects:** Property, Fields, Resources
- **Expected:** Refused on land a household holds and on the manor's fields; common ground needs no permit or fee; no tunnel rock lies under held land.
- **Tests:** `game/tests/parity_mining_test.gd`

### INT-205 · The manor procures mining equipment from the trades (MIN-EQUIP, MIN-F2-Q1)
- **Trigger:** The reeve's evening.
- **Source:** `game/scripts/core/mine_supply.gd::manor_needs`, `game/scripts/core/mine_supply.gd::procure`, `game/scripts/core/npc_brain.gd`
- **Affects:** Treasury, Crafting, Market, Inventory, Employment
- **Expected:** The manor works out real needs (a support for the face it wants to tunnel, planks for worn supports holding an open passage, ladders for broken shafts, one mallet for the yard), buys what someone holds from the treasury above its reserve, or orders the rest from a carpenter with a paid advance; finished pieces are delivered to the works yard. Carpenters make supports, ladders, mallets and minecarts; the smith supplies nails, axles and ironwork by the usual part purchases. A carpenter holds back only what the manor ordered. No mining wage or market of its own. Extends INT-063, INT-178, INT-194.
- **Tests:** `game/tests/equip_test.gd`

### INT-206 · Shore jobs on the manor's board (MIN-EQUIP)
- **Trigger:** The manor holds a support, plank or ladder for a face, a worn support or a broken shaft.
- **Source:** `game/scripts/core/mine_supply.gd::shore_wanted`, `game/scripts/core/manor_work.gd`
- **Affects:** Employment, Wages, Equipment, Resources
- **Expected:** A "shore" job (set up a support, repair one, fit a ladder) at the repair wage, ranked before mending, taken by villagers by the board's rules; not offered to the player. Extends INT-066, INT-194.
- **Tests:** `game/tests/equip_test.gd`

### INT-207 · A miner's household buys a minecart where track serves its seam (MIN-EQUIP)
- **Trigger:** A miner's seam below ground is served by track and a cart would save carrying.
- **Source:** `game/scripts/core/npc_brain.gd`, `game/scripts/core/mine_supply.gd`
- **Affects:** Coins, Market, Equipment, Households
- **Expected:** Bought from a carpenter with the household's own coins and set on the rails; nobody lays track or sinks a shaft on their own, so carts appear only on track the player laid. Extends INT-191, INT-195.
- **Tests:** `game/tests/equip_test.gd`

### INT-208 · A collapse's outcome for the people in the cell (MIN-COLLAPSE, MIN-F2-Q2)
- **Trigger:** A tunnel or shaft cell collapses at dawn.
- **Source:** `game/scripts/core/mine_works.gd::collapse`, `game/scripts/core/world.gd`
- **Affects:** Health, Character, Player state, Save, Loot
- **Expected:** Each person in the cell lives or dies by a fixed seeded formula (seed, day, cell, person; tunables in `mine_works.json`, temporary); a villager who dies goes through `World.kill` (INT-017), the player through the ordinary death (INT-018); a survivor steps to an open neighbouring cell or is trapped, unable to act, until the cell is dug out with a shovel; minecarts and piles in the cell are buried with it; trapped people are saved. No injuries (HEALTH-01). Extends INT-193.
- **Tests:** `game/tests/equip_test.gd`, `game/tests/underground_struct_test.gd`

### INT-209 · The reeve carries an unclaimed delivery when no manor hand is free (LOG-01)
- **Trigger:** A villager reeve's working round, before the board's latest start, with a delivery (haul) open.
- **Source:** `game/scripts/core/manor_work.gd::reeve_fallback`, `game/scripts/core/manor_work.gd::is_staff`, `game/scripts/core/npc_brain.gd`
- **Affects:** Employment, Wages, Inventory, Granary, Relief
- **Expected:** Only when no living manor hand is free does the reeve take an open delivery, by the board's rules (first come, one job at a time); as salaried staff no wage is set aside or paid (the reeve is also excluded from surveys and backfill, as hands are). The goods are loaded where they lie and put down once at their destination. Urgent relief keeps `deliver_now`.
- **Tests:** `game/tests/job_board_test.gd`

### INT-210 · The player's pack: eight categories, capacity per category, gear outside it (INV-18)
- **Trigger:** Anything that adds to the player's pack: buying (trade window, quantity box, seed), taking from the family chest, a chest, a stall or shop, a contract delivery, a pit heap, loot; picking, gathering, harvesting, mining, felling, sampling, crafting; equipping and taking off gear; loading a save.
- **Source:** `game/scripts/core/inventory.gd::can_add`, `game/scripts/core/inventory.gd::can_add_all`, `game/scripts/core/inventory.gd::used`, `game/scripts/core/inventory.gd::full_text`, `game/scripts/core/game_data.gd::category`, `game/scripts/core/player_state.gd::_hook_pack`, `game/scripts/core/player_state.gd::from_dict`, `game/scripts/core/world.gd::pack_full_text`, `game/scripts/core/world.gd::player_buy_many`, `game/scripts/core/world.gd::player_loot`, `game/scripts/ui/game_ui.gd::show_trade`, `game/scripts/ui/inventory_window.gd::lock_stage`, `game/data/items.json`
- **Affects:** Inventory, Equipment, Market, Crafting, Resources, Containers, Loot, Save, Interface
- **Expected:** Every item names one of eight categories in `items.json` (general, food, raw, tools, weapons, armour, medicine, crafted; owner INV-Q1). The player's pack is one store (`Inventory`) whose capacity is per category: 9, 18 or 27 kinds by `PlayerState.pack_level` 0-2 (owner INV-Q2: one row of the 3 x 9 grid, then the second, then the third, in all eight at once); a kind is one place whatever its count (stacks unchanged), a worn or wielded unit takes none, a second unworn unit does. `can_add` admits more of a kind already holding a place, else a new kind only while its category has a free place; goods one action yields together (crop and seed, a fitting's materials) are checked together (`can_add_all`). Every refusal names the category ("Tools inventory full: 9 of 9 slots."); the trade window lists each full category for goods on sale (TRADE-AXE-01 adapted). A refused purchase moves no coin and no good; a transfer moves nothing; made, mined or felled goods with no place are set down at the player's feet (INT-021); nothing is lost. Villagers', chests', carts' and stalls' inventories have no category rule and are unchanged. Save 19 stores `pack_level`; categories come from the registry and are never stored; an 18 or older save loads every item, count, wear and gear slot as saved at level 0, and a category over its capacity keeps everything and takes no new kind.
- **Tests:** `game/tests/inventory18_test.gd`, `game/tests/start_test.gd`, `game/tests/wiki_test.gd`

### INT-211 · A tailor sells the pack's rows (TAILOR-18)
- **Trigger:** The player chooses "Backpack: unlock the second row (150 coins)" (then the third) in a tailor's talk window.
- **Source:** `game/scripts/core/world.gd::is_tailor`, `game/scripts/core/world.gd::pack_row_price`, `game/scripts/core/world.gd::pack_row_refusal`, `game/scripts/core/world.gd::player_buy_pack_row`, `game/scripts/ui/game_ui.gd::show_talk`, `game/data/balance.json`
- **Affects:** Inventory, Coins, Market, Player state, Save, Interface
- **Expected:** A villager whose job is `tailor` (balance.json `tailor.job`) sells the pack's two upgrades as a service, not an item: the second row, then the third (`tailor.pack_rows`, 150 and 450 coins, owner provisional), only in order, never twice, only from a tailor awake and at work (when they have a workplace), and only with the price in the player's own purse. All or nothing: the price passes from the player's coins to the tailor's own (counted as the tailor's earnings, theirs to spend by their usual rules; the coin total unchanged) and `PlayerState.pack_level` rises by one, opening that row in all eight categories (INT-210); saved. Every new world starts with one extra adult tailor housed where there is most room and let the manor's service pitch `pitch2` (rent-free like a merchant's stall; never open for sales, never rentable by the player), who keeps it by day. A save made before there was one, or a world whose tailor has died, opens one tailor's place in the labour market (`NPCBrain.service_place`, adopted by `seek_work` like the prospector's) for an adult who becomes free; no villager is made on load. The tailor never leaves the trade by `seek_work`; their only income is these sales.
- **Tests:** `game/tests/inventory18_test.gd`, `game/tests/tailor_barber_test.gd`

### INT-212 · A barber changes the player's looks (BARBER-18)
- **Trigger:** The player chooses "Hair, beard and colour (5 coins a visit)" in a barber's talk window, picks and pays.
- **Source:** `game/scripts/core/world.gd::is_barber`, `game/scripts/core/world.gd::barber_recipe`, `game/scripts/core/world.gd::barber_refusal`, `game/scripts/core/world.gd::player_barber_visit`, `game/scripts/ui/game_ui.gd::show_barber`, `game/scripts/core/population.gd::populate`, `game/scripts/core/npc_brain.gd::service_place`, `game/data/balance.json`
- **Affects:** Coins, Market, Player state, Save, Interface
- **Expected:** A villager whose job is `barber` (balance.json `barber.job`) changes only the player's hair style, beard and hair colour, within the character creator's own options (CharacterLook), for `barber.price` coins (5, owner 2026-10-23), atomically, only from a barber awake and at their post (the tailor's service rule), only for a change and with the price in the player's purse. The coins pass to the barber's own purse (total unchanged); the saved appearance recipe changes in those features only (worn gear is drawn over it as before) and the player's sprite is redrawn. A new world starts with one barber at the service pitch `pitch3`; an older save, or a world whose barber has died, opens a barber's place in the labour market (as the tailor's, INT-211).
- **Tests:** `game/tests/tailor_barber_test.gd`

### INT-213 · The plough horse: bought from the visiting caravan, kept in a pen, speeds the plough (B14-11)
- **Trigger:** The player stands within `farming.caravan_horse.reach` of the caravan's stop while it is in the village (visit days, from `from_hour` for `hours` game hours) and chooses Buy a plough horse; later, each tilling, and every hour of the horse's hunger.
- **Source:** `game/scripts/core/farming.gd::buy_horse`, `game/scripts/core/farming.gd::caravan_here`, `game/scripts/core/settlement/regions.gd::horse_dealer`, `game/scripts/core/farming.gd::plough_horse`, `game/scripts/core/farming.gd::till_cost`, `game/scripts/core/fauna.gd::tick`, `game/scripts/main.gd::_find_target`
- **Affects:** Coins, Livestock, Fields, Player state, Save
- **Expected:** (B14-11, owner 2026-10-23) The horse comes from a horse-dealer among the traders on the road that day (`Regions.horse_dealer`: Wulstead or Higham-on-the-Way, the nearest with a horse; with none on the road none is for sale): its herd is one less. The price (`farming.caravan_horse.price`, 120) goes from the player to the dealer's trader's till and leaves the village exactly as any coin the village pays the traders (`coin_sources` and the player's coins fall by it, the dealer's till rises by it: no coin is made or lost). The horse is bought only with a horse pen of the player's with room (one animal: `animals.horse.pen_cap` 1) and never when one is already owned; it comes from outside the village, an adult male that never breeds. It is an ordinary pen animal: it eats `animals.horse.feed` (2) wheat a meal from the pen's trough (INT-126, the player feeds it at the gate), loses health and dies when its hunger is empty, and ages and dies of old age by the cow's figures (agent proposal). With a living horse in one of the player's pens and the hand plough carried, `till_cost` is `till.horse` (1 s, 10 stamina) instead of `till.plough`; without the plough, or after the horse dies or is slaughtered, tilling is as before. The horse is saved as a pen animal and no save version changed (19).
- **Tests:** `game/tests/horse_test.gd`, `game/tests/farming_test.gd::test_pens_and_animals`

### INT-214 · Outlaws return after the band is gone (BANDIT-RETURN)
- **Trigger:** The last living bandit dies (any cause), and a calendar season later the dawn comes.
- **Source:** `game/scripts/core/outlaws.gd::dawn`, `game/scripts/core/outlaws.gd::arrive`, `game/scripts/core/outlaws.gd::on_death`, `game/scripts/core/outlaws.gd::after_load`, `game/scripts/core/world.gd::kill`, `game/scripts/core/life.gd::dawn`
- **Affects:** Bandits, Family, Coins, Overworld
- **Expected:** (owner 2026-10-23, `docs/directives/2026-10-23_owner_answers_bandits.md`) `World.outlaw_gone_day` is the day the last bandit (role bandit; the camp's children do not count) died, -1 while one lives. At the first dawn a season (`Life.seasons_to_days(1.0)` days) after it, 2 or 3 grown outlaws come in at one of the map's edge exits and walk to the bandits' camp, where the existing bandit behaviour (INT-014) takes over; they are bandits with the original band's health, damage, copper sword and a purse of 5 to 15 coins, which is new money from outside and is added to `coin_sources` (the ledger balances). Their count, names, ages, purses and entry exit come from a stream seeded by the world seed and the day the band ended, so they are the same on every run and no other stream moves. The wait is saved as the optional key `outlaw_gone_day` (no save-version change); a save without it starts the wait on the day it is loaded if no bandit lives. While any bandit lives nothing arrives. The band then grows only by the orphan rule (INT-014's camp, FAM-07).
- **Tests:** `game/tests/outlaw_return_test.gd`, `game/tests/run_tests.gd::test_simulation`

### INT-215 · Life in the countryside: ambient wild animals and travellers outside the village (WORLD-LIFE-01)
- **Trigger:** The camera is over the overworld outside the village (every frame `Main._sync_countryside` asks `Countryside` for what lives within `countryside.cull_radius` tiles of it at the world clock's minute).
- **Source:** `game/scripts/core/countryside.gd::animals_near`, `game/scripts/core/countryside.gd::travellers_near`, `game/scripts/core/countryside.gd::chunk_animals`, `game/scripts/core/overworld.gd::gate_trails`, `game/scripts/main.gd::_sync_countryside`
- **Affects:** Overworld, Wildlife, Calendar
- **Expected:** (owner 2026-10-23, `docs/directives/2026-10-23_owner_answers_countryside.md`; counts and rates are agent decisions, provisional, balance.json `countryside`) Wild animals roam the overworld outside the village and travellers walk the trails to the village gates; other towns stay off the map. It is ambient and drawn only: a pure function of the world seed and the game minute (integer hashes of seed, chunk, trail and slot; no random generator, no wall-clock time), so a fresh `Countryside` of the same seed gives the same animals and walkers at every minute in any order of asking, and nothing of it is saved (the memoised legs are only a cache). Animals: each overworld chunk holds 0..`animals.open_max` (0..`forest_max` where it has at least `forest_trees` trees) of the wild species of its kind (rabbit, bird, deer, fox, boar; never the wolf or bear, nothing outside bites yet), each on a free home cell outside the village and its margin and off mountain tops, walking a leg of `leg_minutes` game minutes to a target within `roam` tiles (kept clear of trees, rocks and cliffs) and back, then resting; they are `Animal` objects drawn with `AnimalSprite` (same MiniFolks sheets as the village woods) but belong to no `Fauna`: they cannot be hunted, hunt, breed, eat or die, and are in no animal count. Travellers: each trail (`Overworld.gate_trails`: the road cells from a road node, at least `travellers.min_trail` cells out, to the gate's outside cell) starts a journey with probability `chance` in each `slot_minutes` slot that begins between `from_hour` and `to_hour`; the pedlar, pilgrim or wayfarer (villager sheets, weights `kinds`) walks in at `speed` of the walk rate, waits `pause_minutes` at the gate, walks out and is gone at the far end. On a caravan visit day (`caravan_every_days`, the day rule of `Farming.caravan_here`) its wagon and driver walk the trail of the gate nearest `farming.caravan_horse.stop` at `caravan_speed`, arriving as the visit begins and leaving as it ends (the village's own wagon sprite stands at the stop meanwhile). Nothing here touches coins, items, the population, the animal or any other ledger, the world's random stream or the economy simulation (`Countryside` is built from the `Overworld` alone and the headless simulations never build it); the view draws only what is within the cull radius, a handful at a time, and frees what leaves.
- **Tests:** `game/tests/countryside_test.gd`, `game/tests/overworld_test.gd`, `game/tests/wiki_test.gd`

### INT-216 · Each worker's own experience shortens their work and raises their pay (X18-CAPCOMP, X18-CAPNUM, D2 to D5, D8)
- **Trigger:** Any work step planned or started for a villager or the player at a hook site (a mining swing, a felling, a recipe at a forge, anvil, sawhorse or workbench, tilling, sowing, cutting, pen feeding and collecting), and any wage the hook is asked to set (the manor's mending and quarrying at acceptance, the harvest hand's wage at acceptance).
- **Source:** `game/scripts/core/settlement/capability_hook.gd::level_for`, `game/scripts/core/settlement/capability_hook.gd::time`, `game/scripts/core/settlement/capability_hook.gd::work_time`, `game/scripts/core/settlement/capability_hook.gd::pay`, `game/scripts/core/settlement/capability_hook.gd::bind`, `game/scripts/core/settlement/experience.gd::effective_level`, `game/scripts/core/settlement/experience.gd::wear_cap`, `game/scripts/core/settlement/industries.gd::_bonus`, `game/scripts/core/world.gd::update`
- **Affects:** Employment, Wages, Crafting, Resources, Fields, Coins, Save
- **Expected:** (owner answers 2026-10-23, X18-D2, D3, D5, D8; `docs/directives/2026-10-23_owner_answers_tailor_barber_d2_d3.md`, `docs/directives/2026-10-23_owner_answers_x18_d4_d9.md`) The hook is on in the game: the World binds its own `WorkExperience` record (when made, loaded and at each update) and every hook site reads the working person's OWN effective level in the work's industry (`effective_level` = experience level, no facility limit now: `wear_cap`, the seam for a later wear rule, limits nothing; D2). A person with no experience in the industry has level 0 and works at the base time and wage. The approved tables (`settlement_industries.json`, profile `approved`) give less time per unit (the output multiplier divides the existing time; where a Skill already shortens the same work the two gains add once, `SettlementProductivity.unit_minutes`) and a better wage (the pay multiplier on a wage the game sets, rounded to the nearest whole coin, D8); real-valued levels read in a straight line between the two whole levels around them (7.3 is 30% of the way from level 7 to 8, D5). No level gates anything (D3): bands novice (below 3), journeyman (3 to below 7) and master (7 and over) only name a level where it reaches the player (the settlement report's workforce). Capability never creates ore, grain, goods or coins: every unit still takes its full inputs from the seam, field or pack, and a wage is paid from the same purse. A hook with no worker and no forced level returns its base; analysis runs (`CapabilityHook.analysis`, the forced levels of `capability_metrics.gd`) keep the forced levels alone. The player's own farming work reads the player's own record (none at the start); mining, felling and crafting by the player are not hooked (they never were). A world's experience is saved (`x18_experience`), so a loaded game works at its own levels.
- **Tests:** `game/tests/experience_test.gd::test_switched_on`, `game/tests/experience_test.gd::test_per_worker_path`, `game/tests/experience_test.gd::test_effective_kept_apart`, `game/tests/capability_test.gd`

### INT-217 · A wage is fixed when the job is taken, at the taker's level (X18-D6)
- **Trigger:** A villager or the player takes a manor job (mending or quarrying), or the player accepts a farmer's offer to hire them for the harvest; the treasury or giver then sets the wage aside.
- **Source:** `game/scripts/core/manor_work.gd::wage_for`, `game/scripts/core/manor_work.gd::can_fund`, `game/scripts/core/manor_work.gd::take`, `game/scripts/core/quests.gd::promised`, `game/scripts/core/quests.gd::wage_of`, `game/scripts/core/quests.gd::accept`
- **Affects:** Wages, Treasury, Coins, Employment, Interface
- **Expected:** (owner 2026-10-23, X18-D6 "Set wage when taken", D8) A manor job is posted at the base wage (`mend_wage`, `quarry_wage`) and the treasury sets nothing aside until a worker takes it. On acceptance the wage is `CapabilityHook.pay(base, industry, taker)` (mending: carpentry; quarrying: mining; the taker's own effective level; nearest whole coin), the treasury check of `can_fund` is made with that wage for that taker (the chest must still keep `manor_job_reserve_days` of obligations after it), and the same sum is set aside (`reserved`), paid when the job is done and returned whole on release, lapse or death: one payment, no coin made. The salaried staff (manor hands, the reeve), the player's own backfill orders and the manor's other jobs (carry, survey, trial pit, excavate, tunnel, shore) keep their posted wage. The harvest hand's wage is fixed the same way when the player accepts (`q.wage`, from the player's own farming level, giver's purse checked and the sum set aside at that figure), so later experience does not change a wage already agreed. The reeve's list and the journal show the wage the player would get or has agreed.
- **Tests:** `game/tests/experience_test.gd::test_d6_wages`, `game/tests/job_board_test.gd`, `game/tests/capability_test.gd`

### INT-218 · Crop and seed shared by work done (FARM-08-Q-CROP, X18-D7, FARM-CROP-SEED)
- **Trigger:** A farmer finishes cutting a ripe field that other farmers of the field are cutting at the same time.
- **Source:** `game/scripts/core/npc_brain.gd::_cutting_shares`, `game/scripts/core/npc_brain.gd::act`, `game/scripts/core/farming.gd::split_crop`, `game/scripts/core/farming.gd::seed_pool`, `game/scripts/core/farming.gd::keep_seed`, `game/scripts/core/settlement/capability_hook.gd::rate`
- **Affects:** Fields, Resources, Inventory, Households, Livestock
- **Expected:** (owner 2026-10-22 FARM-08-Q-CROP; 2026-10-23 D7 "By ground cut" and FARM-CROP-SEED "Share seed by work too") Each cutter's work is their minutes at the field times their own work rate (`CapabilityHook.rate`: the farming output multiplier of their effective level, 1.0 with none), so a quicker cutter's share follows the ground cut, not the clock; a farmer not cutting at that moment has no work and no share. The seed kept back (the earlier model: `seed_keep` of the crop; the shared-manor model: `seeds_back` a sown cell) is split by those shares with the same rule as the grain (`split_crop`: largest remainder, ties to the smaller id) and each cutter gets their part as seed (under the earlier model only a farmer, and only up to `seed_cap`: what does not fit stays grain). The pen's feed still comes off the crop first. Seed and grain together are exactly the crop (and, under the shared model, the seed back): nothing is made or lost; the rate decides who gets what, never how much there is.
- **Tests:** `game/tests/crop_share_test.gd`, `game/tests/farming_test.gd`

### INT-219 · Which work earns which industry's experience (X18-D4)
- **Trigger:** A villager works a step (each game minute of it), the player finishes or cancels a timed action, or a merchant or stall attendant keeps a stall open.
- **Source:** `game/scripts/core/settlement/experience.gd::industry_of_step`, `game/scripts/core/world.gd::_note_work`, `game/scripts/core/world.gd::note_player_work`, `game/scripts/main.gd::cancel_action`, `game/scripts/core/npc_brain.gd::decide`, `game/scripts/core/business.gd::plan_attendant`
- **Affects:** Employment, Player state, Save, Workshops
- **Expected:** (owner 2026-10-23, X18-D4 "Use the table") Experience is credited per game minute of work, to the industry the table names: stall hours (a merchant or a hired attendant at the counter) trade; slaughter, clearing ground, fencing farmland, tilling, sowing, cutting, pen feeding and collecting farming; mining swings, rock sampling, service-contract digging, and the manor's survey, trial pit, excavate, tunnel, shore and backfill jobs mining; felling forestry; recipes by their station (forge, anvil: smithing; sawhorse: carpentry; workbench: tanning or the industry of its output, e.g. masonry for dressed blocks); the manor's mending carpentry. Hunting, foraging, picking fruit, building, hauling, carting and assays earn none. The player's finished action credits its whole time, and one cancelled part-way credits the seconds actually worked. Experience only accrues; nothing it records changes by itself the coins, items or ground.
- **Tests:** `game/tests/experience_test.gd::test_step_mapping`, `game/tests/experience_test.gd::test_live_world`, `game/tests/experience_test.gd::test_switched_on`

### INT-220 · Rooms of one property are joined by a doorway through their shared wall (ROOMS-18)
- **Trigger:** A room is finished beside another room of the same property (or a save with such rooms is loaded); someone walks, targets or looks across the shared wall.
- **Source:** `game/scripts/core/doorways.gd::find`, `game/scripts/core/doorways.gd::row_between`, `game/scripts/core/world.gd::index_interiors`, `game/scripts/core/world.gd::reaches`, `game/scripts/core/construction.gd::find_module_slot`, `game/scripts/core/fitting.gd::floor_set`, `game/scripts/main.gd::_draw_doorways`
- **Affects:** Building, Property, Interiors, Workshops
- **Expected:** (owner 2026-10-23, OD-05) Where the side walls of two finished rooms of one property meet, a one-cell gap is cut through both walls at a row where each room's stamp has the plain side wall and a free, reachable floor cell just inside it. The gap is derived from the buildings and never saved, so every load gives the same one; its wall cells become open ground (collision), belong to their own room's inside and roof, and the wall tile gives way to the room's own floor tile (no new art). Nothing earlier moves: furniture stays, the street doors stay, a house's east wall (lined with furniture in every stamp) gets none. `find_module_slot` counts ground where a doorway can be cut as nearer, so a suggested room goes there when it can; `reaches` treats the gap as a way between the two rooms; `Fitting` never puts equipment in the gap itself (equipment placed in the floor cell before it closes the doorway until taken up). Rooms stacked north and south have a yard between them and no shared wall: no doorway.
- **Tests:** `game/tests/property_test.gd::test_doorways`

### INT-221 · The survey plots lie on open ground in new worlds; a world made before keeps its plots (ROOMS-18, village generator v8)
- **Trigger:** A new world is made; a saved world is loaded.
- **Source:** `tools/build_village.py`, `game/scripts/core/world.gd::_move_plots_to_map`, `game/scripts/core/prospecting.gd::wild_cells`, `game/data/village.json`
- **Affects:** Property, Save, Building, Overworld
- **Expected:** (owner 2026-10-23, OD-05) A new world's two plots the manor sells lie on open ground north-east of the village (plot0 at 73,11 and plot1 at 91,12, each with a lane from its door step to the road), away from roads, houses, fields and pens, so rooms can be added on every side (a room on a treed side waits for the trees to be felled). A world saved before keeps its plots where they were (`legacy_plots` in the map data: 90,20 and 107,20), with their owner, site, house and the player in it, and loses no tree. Prospecting keeps both layouts' plots out of the wild ground.
- **Tests:** `game/tests/property_test.gd::test_plots`, `game/tests/property_test.gd::test_old_plots`, `tests/test_village.py`

### INT-222 · Carpentry, Masonry and Tanning are skills of their own, started from Crafting (SKILL-TRADES-18, Q18-1, Q18-2)
- **Trigger:** A new world is made, an older save (without the `trade_skills` mark) is loaded, or anyone makes a woodwork, stone-dressing or leather recipe.
- **Source:** `game/scripts/core/skills.gd::seed_trades_for`, `game/scripts/core/skills.gd::seed_trades`, `game/scripts/core/world.gd::setup`, `game/scripts/core/world.gd::load_dict`, `game/data/recipes.json`, `game/scripts/core/settlement/experience.gd::start_days`, `game/scripts/core/settlement/capability_hook.gd::recipe_industry`
- **Affects:** Player state, Crafting, Employment, Workshops, Save
- **Expected:** (owner Q18-1 and Q18-2, 2026-10-23) `skills.json` has Carpentry, Masonry and Tanning (`starts_from: crafting`) beside Crafting. Once per world, after the settlers' history (new world) or when a save lacks the `trade_skills` key (older save), each person who has Crafting experience is given the same experience in each of the three they have no record of, so no one loses progress and a person with no Crafting gets nothing; a saved world is never re-seeded. Recipes train and are gated by their own skill (agent decision, docs/DECISIONS.md): woodwork and joinery (saw_planks, make_mallet, make_cart_wheel, build_handcart, make_timber_support, make_track_section, build_minecart, make_ladder, make_shovel_haft, assemble_shovel), and the timber work of the terrain and mine works (stairs, walkways, supports, track, ladders) are Carpentry; dress_stone is Masonry; tan_pelts, tan_leather, leather_armor and leather_cap are Tanning; Crafting keeps weave_cloth, sew_bandages and craft_plough. The settlement industries become forestry, carpentry, masonry, smithing, farming, tanning, trade and mining (Q18-2); carpentry, masonry and tanning count practitioners by their own skill, their experience start (D1) reads that skill (`WorkExperience.SKILL_OF`) and their time effect is the skill's `craft_time` (`SKILL_TIME_EFFECTS`); masonry's recipe work (building_block) is attributed to it by `effects.outputs`, and its caps and profile numbers are the carpentry ones (agent proposal). The quest that taught Crafting 2 for leather armour teaches Tanning 2.
- **Tests:** `game/tests/trade_skills_test.gd`, `game/tests/skills_test.gd`, `game/tests/experience_test.gd`, `game/tests/settlement_test.gd`

### INT-223 · Law: witnessing and carrying documents, the reeve's lessons, and the notary check (LAW-SKILL, Q18-14)
- **Trigger:** A notary courier witnesses a signature or brings a formal document home; the player asks the reeve to teach the law; a courier is asked to notarise.
- **Source:** `game/scripts/core/law.gd::witnessed`, `game/scripts/core/law.gd::carried`, `game/scripts/core/law.gd::teach`, `game/scripts/core/law.gd::qualified`, `game/scripts/core/settlement/formal_contracts.gd::send_with_notary`, `game/scripts/core/settlement/formal_contracts.gd::tick`, `game/scripts/ui/game_ui.gd::_quest_choices`, `game/data/couriers.json`
- **Affects:** Player state, Employment, Interface, Save, Coins
- **Expected:** (owner Q18-14, 2026-10-23) Law starts at 0 for everyone and is saved with the other skills. A notary gains `law.witness_xp` for each signature given before them and `law.carry_xp` when the document is back, whatever the answer. The reeve teaches (the talk choice "Teach me about the law"): `law.lesson_xp` a lesson, `law.lessons_per_day` a game day a pupil (kept in `World.law_lessons`, saved when set), up to the Law level in `law.teachers` for the teacher's job (3 for the reeve; 6 for the chapel's preacher; any villager with a listed job teaches). A courier may notarise (`FormalAgreements.send_with_notary`) only with Law at `couriers.json notary` (provisional: Law 2); Trading no longer qualifies. No coins move in a lesson.
- **Tests:** `game/tests/trade_skills_test.gd::test_law`, `game/tests/contract_sign_test.gd`, `game/tests/courier_test.gd`

### INT-224 · Farming, Husbandry, Hunting and Healing are skills trained by the work (DVW-B8)
- **Trigger:** The player or a villager tills, sows or harvests; feeds a pen, gathers its products or slaughters livestock; hunts; dresses a wound with a medicine; or brews a tonic or poultice.
- **Source:** `game/scripts/core/skills.gd::step_xp`, `game/scripts/core/skills.gd::action_xp`, `game/scripts/core/skills.gd::seed_farming`, `game/scripts/core/world.gd::_note_work`, `game/scripts/core/world.gd::player_hit_animal`, `game/scripts/core/world.gd::player_use_medicine`, `game/scripts/core/farming.gd::till`, `game/scripts/core/farming.gd::harvest`, `game/scripts/core/npc_brain.gd::act`, `game/data/skills.json`
- **Affects:** Player state, Fields, Livestock, Wildlife, Employment, Save
- **Expected:** (owner DVW-B8, 2026-10-23) The four skills exist in `skills.json` and are trained by actions (agent decision, `work_xp` in `skills.json`): Farming by tilling, sowing and harvesting (the player's fields and wild-field picking; a villager's harvest, sow and farm-plot work steps); Husbandry by feeding a pen, collecting its products and slaughtering (a villager's feed, collect and slaughter steps); Hunting by killing wild game (player and villager hunts); Healing by dressing a wound with a medicine and by the tonic and poultice recipes (moved from Cooking). Farming starts from each person's recorded farming experience (`WorkExperience`, level on the skill's curve) when a world is made or an older save loaded; Healing starts from Cooking (which covered the brewing); Husbandry and Hunting start at 0. The skills give no perks beyond Healing's recipe-work effects (a copy of Cooking's): they are recorded and shown, and nothing is gated by them.
- **Tests:** `game/tests/trade_skills_test.gd::test_work_xp`, `game/tests/experience_test.gd`, `game/tests/farming_test.gd`

### INT-225 · The village gives to the chapel; the chapel pays its clergy (DVW-B3-CHAPEL)
- **Trigger:** The weekly service day (every 7th game day, 16:00) and any time the player gives to the chapel; every day at 16:00 for the wages.
- **Source:** `game/scripts/core/chapel.gd::offerings`, `game/scripts/core/chapel.gd::evening`, `game/scripts/core/chapel.gd::piety`, `game/scripts/core/chapel.gd::player_offer_coins`, `game/scripts/core/chapel.gd::player_offer_item`, `game/scripts/core/world.gd::total_coins`, `game/data/balance.json`
- **Affects:** Coins, Inventory, Wages, Households, Employment, Ledger, Save
- **Expected:** (owner DVW-B3-CHAPEL, 2026-10-23; numbers are agent decisions in `balance.json` "chapel", provisional) Each person has a fixed piety (0 to 1, from the world seed and their id); on the service day those at or above `min_piety` give `coin_share` x piety of the coins they hold above their OD-19 reserve (`World.reserve_of`) and `keep_coins`, and a household gives `goods_share` x its piety of the wheat it holds beyond `goods_keep_days` of its own food. The coins go to `Chapel.coins`, counted in `World.total_coins`, the economy simulation's currency ledger and `SettlementHoldings.coins`; the wheat to `Chapel.store`, counted in `SettlementHoldings.holders`. The player may give coins, food or seed through the preacher or assistant. The clergy (preacher 3, church assistant 2 coins a day, below the manor's 6) are paid from the fund only; an unpaid wage is owed (up to 14 days) and paid when the fund allows; nothing is made, and no manor coin pays it. Coins are conserved.
- **Tests:** `game/tests/chapel_test.gd::test_offerings`, `game/tests/chapel_test.gd::test_wages`, `game/tests/chapel_test.gd::test_player`, `game/tests/chapel_test.gd::test_days`

### INT-226 · A household short of food asks the church, which relieves it before the manor does (DVW-B3-CHAPEL)
- **Trigger:** A household's food days fall below `relief_trigger_days` and a member plans their early morning or evening; the manor's evening business (`reeve_day`, 17:00) after.
- **Source:** `game/scripts/core/chapel.gd::plan_ask`, `game/scripts/core/chapel.gd::ask`, `game/scripts/core/chapel.gd::relieve`, `game/scripts/core/chapel.gd::player_ask`, `game/scripts/core/npc_brain.gd::_plan_evening`, `game/scripts/core/npc_brain.gd::act`, `game/scripts/core/npc_brain.gd::_relief`, `game/scripts/core/npc_brain.gd::_relief_offers`
- **Affects:** Relief, Food, Households, Granary, Treasury, Coins, Inventory, Wages
- **Expected:** (owner DVW-B3-CHAPEL: "all the donations ... the first funds used for food relief"; "villagers can go to the church and ask") When the church has food or coins (`Chapel.can_give`) one member of a short household walks to the chapel door once a day and asks; the church fills the household's pantry toward `relief_fill_days`: its store first (grain in whole pots, then any other food), then food bought from the same sellers the manor's relief buys from (`_relief_offers`), paid from `Chapel.coins` to the sellers. The manor's relief then sees the pantry as it is and gives only the rest: its granary and treasury are untouched by what the church gave. A church with nothing sends no one and gives nothing (WDR-022: no hidden rescue). The player with `ask_player_max_coins` or fewer may ask once a day for up to `ask_player_units` food from the store.
- **Tests:** `game/tests/chapel_test.gd::test_relief_first`, `game/tests/chapel_test.gd::test_relief_bought`, `game/tests/chapel_test.gd::test_player`

### INT-227 · The church's farm plot, worked by volunteers or the clergy; the clergy's places; the chapel on the map (DVW-B3-CHAPEL, village generator v9)
- **Trigger:** Each morning (`Chapel.dawn`) and each working day of the clergy or free time of a volunteer; a new world is made; a save is loaded.
- **Source:** `game/scripts/core/chapel.gd::dawn`, `game/scripts/core/chapel.gd::plan_clergy`, `game/scripts/core/chapel.gd::plan_volunteer`, `game/scripts/core/chapel.gd::found`, `game/scripts/core/chapel.gd::place`, `game/scripts/core/farm_plots.gd::plan_church`, `game/scripts/core/farm_plots.gd::act`, `game/scripts/core/population.gd::populate`, `game/scripts/core/npc_brain.gd::job_market`, `game/scripts/core/npc_brain.gd::_change_job`, `game/scripts/core/law.gd::teacher_cap`, `game/scripts/core/property.gd::can_claim`, `tools/build_village.py`
- **Affects:** Fields, Employment, Property, Interiors, Households, Food, Inventory, Save, Relief
- **Expected:** (owner DVW-B3-CHAPEL; agent decisions in `docs/DECISIONS.md`) The map (generator v9) has a chapel (Shade's small house, beds cleared: no new art) at (79, 29), east of Mill Road, with a lane south to the crossing at (88, 43), and an 8 x 7 church plot at (70, 32) beside it (`church_plot`). The plot is a `FarmPlots` plot with the same till, sow, grow and harvest rules, fenced from the start, its harvest going to `Chapel.store`; it is no parcel of the land office, so nobody can claim or build on it (`Property.can_claim`, `Construction._free_sums`). Each morning up to `volunteers_max` pious villagers with time (elders, those out of work at `volunteer_piety`, the very pious after work at `evening_piety`) are chosen; they work it in the time their day leaves. With none able, the preacher (not on the service day) and the church assistant work it in their working day. The plot's seed is the new world's starting seed corn, then bought with the fund (`Chapel._buy_seed`, paid to the seller). A new world starts with one preacher and one church assistant, made from their own random stream after the service trades (nobody else's id, name or place moves). A save made before the chapel has the chapel and plot founded on load on free ground, with no seed or coins and no villager made: the two places open in the labour market (`job_market`), and an adult who becomes free takes one; where something of a household's or the player's stands on the ground, there is no chapel. The preacher teaches Law to level 6 (`couriers.json` law.teachers). `World` saves the optional key "chapel" (no save version bump: absent means founded on load).
- **Tests:** `game/tests/chapel_test.gd::test_places`, `game/tests/chapel_test.gd::test_plot_work`, `game/tests/chapel_test.gd::test_old_save`, `game/tests/chapel_test.gd::test_save`, `game/tests/chapel_test.gd::test_law_and_claims`, `tests/test_village.py`

### INT-230 · Each neighbouring settlement is an economy of its own, stepped once a day (SET-C-SIM, SET-C-FIVE)
- **Trigger:** Each game hour from six, one more settlement takes the day's step (`Regions.step_hour`, called from `World._on_hour`); the next day starts again with the first.
- **Source:** `game/scripts/core/settlement/offmap.gd::step_day`, `game/scripts/core/settlement/offmap.gd::create`, `game/scripts/core/settlement/offmap.gd::audit`, `game/scripts/core/settlement/regions.gd::step_hour`, `game/scripts/core/settlement/regions.gd::create`, `game/scripts/core/world.gd::_on_hour`, `game/data/settlements.json`
- **Affects:** Settlements, Coins, Market, Treasury, Wages, Households, Food, Ledger
- **Expected:** (owner Q18-3, 2026-10-23: "those settlements have simulated economies just like this one, it comes from their villagers, or village political structure or companies"; Q18-4: five of mixed kinds; "same rules, lighter detail") Five settlements (Wulstead, Netherton, Garton, Higham-on-the-Way, Bourton Abbas; the lore and its labels in `docs/expansion18/SETTLEMENTS.md`) are founded from the world seed with real households (adults, children, a purse, a pantry), businesses (a till, a stock, worker households, the village's real recipes) and a treasury (the manor, council, abbey or elders). Each day, in this order: the market opens (one price per good floating with yesterday's imbalance inside `price_min`/`price_max`; households shop every other day: food counted in points as in the village (`NPCBrain.food_points`), the goods of daily life, a share of savings on a wish list; the treasury relieves a household with under a day of food and buys upkeep goods; businesses buy their recipes' inputs; the trader collects the carried goods left over), then production (natural output with finite reserves for the diggings and the quarry, or recipes from inputs held), wages (a business keeps its reserve and pays out of the rest at least the day wages and up to half the surplus, equally among its workers), tax (the village's `tax_rate_*` and `tax_exemption_*` from households and from tills above their reserve, plus a toll of 6% of sales), the officials' pay and day labour for a household nearly out of coins, then eating (a household with under 60% of its food for six days loses a member, children first; an empty household is dissolved and its coins and food go to the treasury), and the horses' feed. Coins and goods change only by flow lines: coins(now) = start + paid in by the village - paid out to it + wholesale in - out + migrated in; goods(now) = start + produced - used + bought from the village - sold to it + wholesale in - out. `audit()` checks both and the horses; nothing is created but natural output, nothing destroyed but use, and no income line exists (a settlement's money comes from its people, its government and its businesses). There are no births or deaths of age yet (MIGRATE-18). Deterministic: only founding draws numbers, from (world seed, settlement index).
- **Tests:** `game/tests/regions_test.gd`, `game/tests/regions_sim.gd`

### INT-231 · The caravan is the settlements' traders: they carry what they have and pay with their own coins (ECON-P1.3)
- **Trigger:** Noon on caravan days (`NPCBrain.caravan`); an import for the forge, stone, the sage's medicines, the food merchant's seed.
- **Source:** `game/scripts/core/npc_brain.gd::caravan`, `game/scripts/core/npc_brain.gd::_caravan_imports`, `game/scripts/core/npc_brain.gd::_caravan_stone`, `game/scripts/core/npc_brain.gd::_caravan_apothecary`, `game/scripts/core/npc_brain.gd::_caravan_seeds`, `game/scripts/core/settlement/regions.gd::begin_visit`, `game/scripts/core/settlement/regions.gd::visiting`, `game/scripts/core/settlement/regions.gd::seller_for`, `game/scripts/core/settlement/regions.gd::buyer_for`, `game/scripts/core/settlement/offmap.gd::sell_to_village`, `game/scripts/core/settlement/offmap.gd::buy_from_village`, `game/scripts/core/settlement/offmap.gd::wants`
- **Affects:** Settlements, Market, Coins, Ledger, Inventory
- **Expected:** (owner ECON-P1.3, 2026-10-23: "their traders ... carrying only what they actually have and paying with their actual coins; the daily allowance goes away") The traders whose turn it is (every `ceil(miles / 20)` caravan visits; the first visit brings all five) come to the village. What the village imports (ore, coal and copper ore for the smiths once the village's seams are down, stone, the sage's medicines, the food merchant's seed) is taken from a trader's own stock, the trader holding most of it first (then the nearer), and its price goes into that trader's till, so a trader holding none sells none (an empty trip). What the village exports (the surplus of the merchants, smiths and producers at 0.8 x value, EQ-22's order unchanged, and its food and tool rules unchanged) is bought only by a trader whose settlement still wants it (the most wanting first, then the nearer) and who can pay from the coins in its till above its floor; the goods enter its stock (and its settlement's market). The village's `coin_sources` moves by every coin crossing; `imported_*`, `exported_*` and the `caravan_coins_*` stats are unchanged, so the economy ledgers hold. There is no purse, float, allowance, ceiling or per-visit cap. The countryside caravan on its visit days stays the picture of it (`Countryside`).
- **Tests:** `game/tests/regions_test.gd::test_world_caravan`, `game/tests/run_tests.gd::test_caravan_traders`, `game/tests/od16_test.gd::test_caravan_buys_by_need`, `game/tests/housing_test.gd::test_caravan_keeps_needed_tools`

### INT-232 · The traders trade among themselves every few days (SET-C-FIVE)
- **Trigger:** The day a round falls due (`road_trade_every_days`, 6) after the last settlement has taken its step.
- **Source:** `game/scripts/core/settlement/regions.gd::road_trade`, `game/scripts/core/settlement/regions.gd::step_hour`
- **Affects:** Settlements, Coins, Market, Ledger
- **Expected:** A trader whose settlement has no use for a carried good (ore, coal, stone, bars, seed, medicine) sells it, at the good's base value, to a trader whose settlement still wants it and whose till pays, up to a load; goods and coins move together as a pair of flow lines in each settlement, and the road coins and goods in and out cancel across the five (`Regions.audit`). This is how Garton's ore reaches Higham's forge and Bourton's stone Higham's masons; nobody is paid for carriage in this round (carriage as a paid service waits on Q18-12).
- **Tests:** `game/tests/regions_test.gd::test_roads`

### INT-233 · The settlements are saved with the world; an older save founds them and keeps its caravan's coins (SET-C-FIVE)
- **Trigger:** The game is saved or loaded.
- **Source:** `game/scripts/core/world.gd::to_dict`, `game/scripts/core/world.gd::load_dict`, `game/scripts/core/settlement/regions.gd::to_dict`, `game/scripts/core/settlement/regions.gd::from_dict`, `game/scripts/core/settlement/regions.gd::add_migrated`, `game/scripts/core/settlement/regions.gd::catch_up`
- **Affects:** Settlements, Save, Coins
- **Expected:** The save carries the key `regions` (format `mml-regions-world/1`: every settlement's households, businesses, treasury, prices, flows and opening books); no save-version bump (an optional key). Loaded, the settlements are exactly as saved and go on the same. A save without it (every earlier one) founds the five from its seed, steps them to the saved day with no trade with the village, and gives the coins of its `caravan_purse` (or nothing) to the traders' tills (`migrated_in`), so no coin is made or lost; `caravan_purse` is no longer saved. A section of an unknown format is refused (the world founds none from it), never reinterpreted.
- **Tests:** `game/tests/regions_test.gd::test_determinism_and_save`, `game/tests/regions_test.gd::test_old_save`

### INT-240 · A household (or the player) pays the tavern keeper for a feast; the food and ale are eaten (DVW-B3-FEAST)
- **Trigger:** 17:00 each game day (`Feast.plan_day` chooses wedding and seasonal feasts), 20:00 (`Feast.resolve` buys and feeds), and any evening the player pays at the counter (`Feast.player_feast`).
- **Source:** `game/scripts/core/feast.gd::plan_day`, `game/scripts/core/feast.gd::resolve`, `game/scripts/core/feast.gd::_quote`, `game/scripts/core/feast.gd::_fit`, `game/scripts/core/feast.gd::_serve`, `game/scripts/core/feast.gd::player_feast`, `game/scripts/core/world.gd::trade`, `game/scripts/core/world.gd::_on_hour`, `game/data/balance.json`
- **Affects:** Coins, Inventory, Food, Households, Market, Wages, Ledger
- **Expected:** (owner DVW-B3-FEAST, 2026-10-23; every number is an agent decision in `balance.json` "feast", provisional) The host (the richest adult of the household by coins above their OD-19 reserve, or the player) pays the tavern keeper through `World.trade` for one plate each (the menu in order of preference, from the keeper's real stock, at most `stock_share` of any item) and ale for each grown guest, at the prices the keeper asks at the start (the host's deal price). The guests who are at the tavern at 20:00 eat and drink at once: hunger rises by the items' food values and `eaten_<item>` and `eaten_food` are counted, the host's pack is left as it was. The size follows the purse (at most `spend_share` of the host's free coins; guests are dropped from the end until it fits); below `min_guests` at the table, or with the host absent, nothing is bought or paid (WDR-022: no hidden rescue, a household that cannot afford one holds none). No fund and no stored table exist, so `World.total_coins`, the economy simulation's currency and item ledgers need nothing added: the coins move host to keeper and the goods leave the keeper's stock as eaten.
- **Tests:** `game/tests/feast_test.gd::test_purchase`, `game/tests/feast_test.gd::test_affordability`, `game/tests/feast_test.gd::test_player`, `game/tests/feast_test.gd::test_determinism`

### INT-241 · Becoming partners owes a wedding feast; the invited go to the tavern in the evening (DVW-B3-FEAST)
- **Trigger:** `Relations.propose` accepted (villagers, or the player with a villager); each 17:00 until the feast is held or `wedding_window_days` have passed; seasonal feasts on the first day of the seasons in `seasonal_seasons`; each guest's decision from 18:00 to 20:00.
- **Source:** `game/scripts/core/relations.gd::propose`, `game/scripts/core/feast.gd::on_partnered`, `game/scripts/core/feast.gd::_plan_wedding`, `game/scripts/core/feast.gd::_plan_seasonal`, `game/scripts/core/feast.gd::plan_attend`, `game/scripts/core/npc_brain.gd::decide`, `game/scripts/core/feast.gd::to_dict`, `game/scripts/core/world.gd::to_dict`
- **Affects:** Households, Food, Interface, Save, Employment
- **Expected:** (owner DVW-B3-FEAST; agent decisions, provisional) A partnership is the village's wedding (there is no separate marriage rite): `Feast.weddings` records it and, from `wedding_delay_days` to `wedding_window_days` later, the couple's household(s) hold a feast if the host can afford it and the household is fed (`min_food_days`); a death or parting cancels it. A seasonal feast is rolled per household from the world seed, the day and the household (own `RandomNumberGenerator`, no shared stream) on the first day of a feast season. Invited people (household members and a few friends; never a guard on duty, the tavern keeper, a bandit or someone underground) walk to the tavern yard once their day's work ends (`Feast.plan_attend` from `NPCBrain.decide`, after the guard, sleep and eating rules) and wait there until the feast. The player's own wedding is paid for by the player at the counter once the partner's family have come (`GameUI._feast_choices`); if the player never pays, nothing is bought. The state (`weddings`, `plans`, `planned_day`) is saved in the World's optional key "feast"; a save without it loads with no feasts owed.
- **Tests:** `game/tests/feast_test.gd::test_triggers`, `game/tests/feast_test.gd::test_save`, `game/tests/feast_test.gd::test_player`

### INT-250 · Villagers with spare coins buy the traders' luxuries; the coins leave with the caravan (DVW-B3-LUX)
- **Trigger:** Noon on caravan days, after the day's other trade (`NPCBrain.caravan` calls `Luxury.visit`).
- **Source:** `game/scripts/core/luxury.gd::visit`, `game/scripts/core/luxury.gd::pick`, `game/scripts/core/luxury.gd::spare`, `game/scripts/core/luxury.gd::taste`, `game/scripts/core/npc_brain.gd::caravan`, `game/scripts/core/world.gd::reserve_of`, `game/scripts/core/settlement/offmap.gd::sell_to_village`, `game/data/balance.json`
- **Affects:** Settlements, Coins, Inventory, Households, Ledger, Market
- **Expected:** (owner DVW-B3-LUX, 2026-10-23: "luxury imports, costly caravan goods (spices, fine cloth, jewellery) bought for status, the coins leaving with the caravan"; every number in `balance.json` "luxury" is an agent proposal, provisional) Of the villagers who are adults with a taste for luxuries (a fixed 0 to 1 hashed from the world seed and their id, at or above `min_taste`), those holding more than their OD-19 reserve (`World.reserve_of`) plus `keep_coins`, in a household with at least `min_food_days` of food (`NPCBrain.household_food_days`), buy: at most `buyers_per_visit` a visit, the most spare coin first (then the lower id), each the dearest luxury whose price (value x `markup`) is within `spend_share` of their spare coins, held by a trader on the road, and of which they own fewer than `own_max`. The goods come out of that trader's stock (`OffMapSettlement.sell_to_village`: its books show the units to the village and the coins from it) and the coins go into its till; the buyer's coins fall, `World.coin_sources` falls by the price, and `caravan_coins_out` and `imported_<item>` are logged, so the village's currency and item ledgers balance and the world's coins are unchanged. Luxuries are kept (no recipe takes them; nothing eats them), so a household short of money or food buys none and a villager's reserve is never spent on one. No random draw: the same seed buys the same. "For status": the game has no standing measure in Build 18 (regard is between two people, `Relations`; notoriety is the player's crimes), so ownership has no effect yet; `Luxury.held_by` is the reading point for a standing system (Expansion 19's judgment).
- **Tests:** `game/tests/luxury_test.gd::test_villagers_buy`, `game/tests/luxury_test.gd::test_rules`, `game/tests/luxury_test.gd::test_save_and_determinism`

### INT-251 · The player buys luxuries at the caravan's wagon from the traders' stock (DVW-B3-LUX)
- **Trigger:** The player stands within reach of the caravan's stop while it is in the village (visit day, from noon) and uses the "Buy ... from the caravan" choice.
- **Source:** `game/scripts/core/luxury.gd::offers`, `game/scripts/core/luxury.gd::refusal`, `game/scripts/core/luxury.gd::buy`, `game/scripts/main.gd::_find_target`, `game/scripts/main.gd::_use`, `game/scripts/core/farming.gd::caravan_here`
- **Affects:** Settlements, Coins, Inventory, Ledger, Interface
- **Expected:** The wagon offers each luxury a trader on the road today still holds (`Regions.seller_for`: the trader with the most), one unit a use, at value x `markup`. A refusal says why: the caravan is not here, no trader holds any, the player lacks the coins, or the pack's category is full (`Inventory.can_add`). A sale moves the unit out of the trader's stock and the coins into its till and out of the village exactly as INT-250 does; nothing is made for the sale.
- **Tests:** `game/tests/luxury_test.gd::test_player`

### INT-252 · Luxury stock is a trader's own opening stock and is finite (DVW-B3-LUX)
- **Trigger:** A world is made, or an older save is loaded.
- **Source:** `game/data/settlements.json`, `game/scripts/core/settlement/offmap.gd::create`, `game/scripts/core/settlement/offmap.gd::audit`, `game/scripts/core/luxury.gd::held_by`
- **Affects:** Settlements, Inventory, Save, Ledger
- **Expected:** Wulstead's and Higham-on-the-Way's traders start with spices, fine cloth and jewellery in their stock (GAME EXPANSION from beyond the map; lore basis BTWO-C14-P002 and BONE-C3-P031), part of the settlement's opening books, so `OffMapSettlement.audit` balances. No settlement makes, restocks, wants or carries them wholesale (they are not in `rules.carry`), so a sale that empties a trader's stock ends that supply for good. A save made before this change keeps its traders' stock as saved (none of these goods): it loads and sells none. What villagers own is their pack's contents and what the player owns is the player's pack, saved with them; no other state is kept.
- **Tests:** `game/tests/luxury_test.gd::test_data`, `game/tests/luxury_test.gd::test_stock_limit`, `game/tests/luxury_test.gd::test_save_and_determinism`

### INT-260 · The neighbouring settlements' people age, are born, marry, found households and leave to kin (REG-DEMO-01)
- **Trigger:** A settlement's daily step (after eating); a settlement is made or an older save is loaded.
- **Source:** `game/scripts/core/settlement/offmap.gd::_life`, `game/scripts/core/settlement/offmap.gd::_old_age`, `game/scripts/core/settlement/offmap.gd::_found_household`, `game/scripts/core/settlement/offmap.gd::_after_loss`, `game/scripts/core/life.gd::death_chance`
- **Affects:** Settlements, Households, Save, Ledger
- **Expected:** Each household's members carry ages (`mem`: born day, sex, partnered, unwilling) on the village's calendar (`Life.year_days`, 8 days a year) and the village's life rules (`balance.json` life and relations: stages, `Life.death_chance`, birth mother range, interval, gap and food days, partner ages, gap and `marry_min_days`, `unwilling_percent`), rolled by a reproducible function of settlement, day and person (nothing random is saved). Births add a child, old age removes a member, a grown child (18+) marries and founds a worker household of a business, and a household with no adult left passes its coins, pantry and children to kin (else its children to the smallest household, else the coins and food to the treasury). All are moves between holders or births and deaths of people: no coin or good is created or destroyed, so `OffMapSettlement.audit` is unchanged. Hunger deaths remain; old-age deaths are counted apart. A save without ages gets them on load from each household's adults and children, deterministically; no `save_version` change.
- **Tests:** `game/tests/settlement_life_test.gd::test_founding`, `game/tests/settlement_life_test.gd::test_births`, `game/tests/settlement_life_test.gd::test_marriage_and_growing_up`, `game/tests/settlement_life_test.gd::test_inheritance`, `game/tests/settlement_life_test.gd::test_save_and_old_save`

### INT-270 · A regional trade moves the settlements' own coins and goods between their holders, as matched flow lines (REG-PARTY-01)
- **Trigger:** `RegionalMarket.execute` applies a planned line between two parties (`Regions.parties`): a settlement's trader, a business, the treasury or a household. Nothing in the live game loop calls it yet (a later task does).
- **Source:** `game/scripts/core/settlement/settlement_party.gd::deal`, `game/scripts/core/settlement/settlement_party.gd::can_deal`, `game/scripts/core/settlement/regional.gd::execute`, `game/scripts/core/settlement/regions.gd::parties`, `game/scripts/core/settlement/regions.gd::party`, `game/scripts/core/settlement/offmap.gd::audit`, `game/scripts/core/settlement/regions.gd::audit`
- **Affects:** Settlements, Coins, Inventory, Ledger, Market
- **Expected:** (owner Q18-10, 2026-10-21: "Anyone may purchase goods from another settlement, including individual villagers, households, merchants, businesses, and settlement treasuries") A party is a handle on one holder of an `OffMapSettlement` (address `region:<settlement>/<holder>`, holder `trader`, a business type, `treasury` or `hh:<n>`): it reads and changes the settlement's own till, stock, treasury, granary, purse and pantry, and keeps nothing of its own. A line is checked on every side first and applied whole or refused whole (a seller short of goods, a buyer short of coins, a carter that is not there). The seller's goods go to the buyer and the price to the seller; a carter's fee goes from the buyer to the carter. Between holders of two settlements each side writes `regional_in`/`regional_out` (goods) and `regional_coins_in`/`regional_coins_out` (coins); inside one settlement no line is needed (its total does not change). `OffMapSettlement.audit` includes those lines and `Regions.audit` requires that all settlements' regional coins and goods in equal out, so nothing is made or lost. Demand and supply per holder are derived from the settlement's own rules (the trader from `wants()`, a business from its recipes' inputs, the treasury from its upkeep, a household from its food and basket; sale caps from the same keeps the local market uses), and the region supplies only what the settlement as a whole lacks. No random draw. Treasuries, businesses and the traders of settlements cannot travel or hire carts (Q18-12 open), so such a buyer is planned only with a carter a test sets.
- **Tests:** `game/tests/party_test.gd::test_every_kind_buys_and_sells`, `game/tests/party_test.gd::test_carriage_and_refusals`, `game/tests/party_test.gd::test_determinism`, `game/tests/regional_test.gd::test_genuine_trade`

### INT-271 · The courier service hands goods and coins to and from a settlement's holder as `outside_*` flow lines (REG-PARTY-01)
- **Trigger:** `CourierService` books, delivers, collects or returns something for a party whose reference is `region:<settlement>/<holder>` (booking, `_arrive`, `_home`, `withdraw`).
- **Source:** `game/scripts/core/settlement/couriers.gd::inv_of`, `game/scripts/core/settlement/couriers.gd::add_coins`, `game/scripts/core/settlement/couriers.gd::place_of`, `game/scripts/core/settlement/settlement_party.gd::add`, `game/scripts/core/settlement/settlement_party.gd::remove`, `game/scripts/core/settlement/settlement_party.gd::outside_coins`
- **Affects:** Settlements, Coins, Inventory, Ledger
- **Expected:** A settlement's holder is an Inventory-like store to the courier service (`count`, `has`, `add`, `remove`, `can_add`) with a purse (`outside_coins`). Goods and coins that leave or enter it cross the settlement's boundary to the service's booths, escrow and couriers' packs, so they are written as `outside_in`/`outside_out` and `outside_coins_in`/`outside_coins_out` flow lines that `OffMapSettlement.audit` counts; the other end is booked in the villager's pack, the booth store or the courier's pack, so every good and coin is always in exactly one holder. A payment past the holder's purse is refused. The service is not in the live game loop yet (REG-COURIER-01). A recipient's history of regional trade (`known_recipients`) reads the party's journal (`Regions.journal`, not saved).
- **Tests:** `game/tests/courier_test.gd::test_route_delivery`, `game/tests/party_test.gd::test_reads_and_writes_the_settlements_books`, `game/tests/party_test.gd::test_outside_exchanges`

### INT-280 · The live world keeps a courier booth for each settlement and the village, joined by regular routes, and steps the couriers every hour (REG-COURIER-01)
- **Trigger:** `World.setup` (and a load) makes `World.couriers`; every game hour `World._on_hour` calls `CourierService.step`; every dawn `World._new_day` calls `CourierService.daily`.
- **Source:** `game/scripts/core/settlement/couriers.gd::create_live`, `game/scripts/core/settlement/couriers.gd::daily`, `game/scripts/core/settlement/couriers.gd::step`, `game/scripts/core/settlement/couriers.gd::tick`, `game/scripts/core/settlement/regions.gd::village_route_table`, `game/scripts/core/world.gd::_on_hour`, `game/scripts/core/world.gd::_new_day`
- **Affects:** Settlements, Market, Employment, Interface, Save
- **Expected:** (owner Q18-12, X18-Q12-BOOTH) Each of the five settlements has a booth served by its own trader party (`region:<id>/trader`, resolved from `World.regions` so a load needs no handles); the village has one at a free market stall (else a stall its keeper builds by the STALL rules), kept by a villager the job rule lets be hired (`Construction.can_hire`), replaced at dawn if the keeper dies. A regular route runs each way between the village booth and each settlement's, its days the settlement's distance from settlements.json (miles times tiles per mile, hauled by a carrier along roads) and the coefficients the provisional `couriers.json` ones; the player reaches the courier window through a context action beside the village booth. Nothing in a villager's own decisions books a delivery yet.
- **Tests:** `game/tests/courier_live_test.gd::test_booths_and_routes`, `game/tests/courier_live_test.gd::test_regular_route`, `game/tests/courier_test.gd::test_booths`

### INT-281 · What a courier carries across the village's boundary is booked in the village's ledgers and the settlement's `outside_*` flow lines (REG-COURIER-01)
- **Trigger:** A delivery hands goods to, or takes goods or coins from, a settlement's party (`CourierService._arrive`, `_home`, `book_route`, `book_special`).
- **Source:** `game/scripts/core/settlement/couriers.gd::add_coins`, `game/scripts/core/settlement/couriers.gd::inv_of`, `game/scripts/core/settlement/couriers.gd::_arrive`, `game/scripts/core/settlement/regions.gd::net_paid_by_village`, `game/tests/economy_sim.gd::_regions`
- **Affects:** Settlements, Coins, Inventory, Ledger
- **Expected:** A good given to a settlement's party counts as `exported_<item>` and one taken from it as `imported_<item>` in the village's ledger; coins paid to the party lower `World.coin_sources` and count `caravan_coins_out`, coins it pays raise it and count `caravan_coins_in`. The party writes the matching `outside_*` flow lines, so `Regions.audit`, `Regions.net_paid_by_village` (which now includes the outside coins) and the economy simulation's goods check balance with the village's. No coin or good is made or lost.
- **Tests:** `game/tests/courier_live_test.gd::test_regular_route`, `game/tests/courier_live_test.gd::test_special_and_fees`, `game/tests/courier_live_test.gd::test_save_and_old_save`

### INT-282 · A villager's or the player's real dealing with a settlement's trader makes that trader someone a courier may be sent to (REG-COURIER-01)
- **Trigger:** A caravan sale or purchase between a villager (or the player) and a visiting trader: the imports, stone, medicine and seed rounds, the surplus sales, the luxury buys and the plough horse.
- **Source:** `game/scripts/core/world.gd::note_settlement_trade`, `game/scripts/core/settlement/couriers.gd::note_settlement_trade`, `game/scripts/core/settlement/couriers.gd::known_recipients`, `game/scripts/core/npc_brain.gd::caravan`, `game/scripts/core/luxury.gd::buy`
- **Affects:** Settlements, Market, Save
- **Expected:** (X18-Q12-POST) The pair (actor, `<settlement>/trader`) is recorded, and saved with the courier service; nothing moves and no price, stock or decision changes. `known_recipients` then lists that trader as a business with where it is found (the settlement's booth), the same for the player and villagers; a settlement never dealt with is not offered and a delivery to it is refused.
- **Tests:** `game/tests/courier_live_test.gd::test_recipients`

### INT-283 · A courier's load is held by its delivery, counted as the village's goods and coins, and dropped where the courier falls (REG-COURIER-01)
- **Trigger:** A regular route leaves (`_depart`), a special delivery is booked (`book_special`), the courier hands over and collects payment (`_arrive`), comes home (`_home`) or dies on the road (`interrupt`).
- **Source:** `game/scripts/core/settlement/couriers.gd::_depart`, `game/scripts/core/settlement/couriers.gd::_arrive`, `game/scripts/core/settlement/couriers.gd::_home`, `game/scripts/core/settlement/couriers.gd::interrupt`, `game/scripts/core/settlement/couriers.gd::held_goods`, `game/scripts/core/settlement/couriers.gd::held_coins`, `game/scripts/core/settlement/holdings.gd::holders`, `game/scripts/core/world.gd::total_coins`
- **Affects:** Coins, Inventory, Loot, Ledger, Save, Employment
- **Expected:** Goods on the road and the takings on their way home are held by the delivery (not by the courier's pack, which the courier's own trading would otherwise sell), booth stores, deposits and held fees are counted in the census and `World.total_coins`, and all are saved under the optional World key `couriers`. A courier who dies on the road drops the load as a loot pile where they fell and the held fee returns to the payer; a full pack leaves proceeds at the booth. An older save loads with no deliveries on the road. The fee goes to the courier only when the work is done.
- **Tests:** `game/tests/courier_live_test.gd::test_dead_courier`, `game/tests/courier_live_test.gd::test_save_and_old_save`, `game/tests/courier_test.gd::test_unavailable_and_interrupted`

### INT-290 · A settlement's trader takes along the food its place can spare, from the farms, herds and cookshop (REG-BUY-P1)
- **Trigger:** `OffMapSettlement.begin_visit` (the trader is on the road on a visit day; `Regions.begin_visit`) runs `stock_trader_food` after the settlement's morning step.
- **Source:** `game/scripts/core/settlement/offmap.gd::stock_trader_food`, `game/scripts/core/settlement/offmap.gd::food_claim_pts`, `game/scripts/core/settlement/offmap.gd::expected_food_pts`, `game/scripts/core/settlement/offmap.gd::cash_shortfall`, `game/scripts/core/settlement/offmap.gd::_expense_due`, `game/scripts/core/settlement/offmap.gd::_inputs_short`, `game/scripts/core/settlement/offmap.gd::_food_spare`, `game/scripts/core/settlement/offmap.gd::_keep`, `game/scripts/core/settlement/offmap.gd::_wage_bill`
- **Affects:** Settlements, Coins, Inventory, Food, Market, Wages, Households
- **Expected:** (owner REG-BUY-D1 and approved policy REG-BUY-P1) The food businesses (those whose output or recipes make a food: farm, herd, cookshop) sell their food to the trader at the settlement's floating price times `trader_pays_share`, from the trader's own till above its trading capital. Rule 2: only food above the local claim is released, the claim being the households' foreseeable need over the village's `reserve_days` (per household, need less pantry) less the food the businesses expect to make over those days (natural output at the workers they have); the food a business keeps for its recipes and tools and a farm's horses' feed over `reserve_days` is never offered. Rule 3: a business with a demonstrated cash shortfall (its wage bill plus the cost of the inputs and tools it lacks, less its till) also sells out of the part the claim protects, food worth at most that shortfall; never a business without one. Coins and goods change hands inside the settlement (no flow line; `audit` holds). The settlement keeps agency: it may sell what it will go short of, and nothing rescues it afterwards. A trader's unsold food is offered to its settlement's households the next morning like any stock.
- **Tests:** `game/tests/regional_food_test.gd::test_claim`, `game/tests/regional_food_test.gd::test_release`, `game/tests/regional_food_test.gd::test_shortfall`, `game/tests/regional_food_test.gd::test_prices`, `game/tests/regional_food_test.gd::test_determinism_and_save`

### INT-291 · The village's buyers buy food from the traders on the road when the village cannot supply it (REG-BUY-01)
- **Trigger:** `NPCBrain.caravan` (noon on a visit day) calls `_caravan_food` after the seed trade, before the exports.
- **Source:** `game/scripts/core/npc_brain.gd::_caravan_food`, `game/scripts/core/npc_brain.gd::_caravan_food_households`, `game/scripts/core/npc_brain.gd::_caravan_food_treasury`, `game/scripts/core/npc_brain.gd::_caravan_food_businesses`, `game/scripts/core/npc_brain.gd::_local_food_for_sale`, `game/scripts/core/npc_brain.gd::_food_unit`, `game/scripts/core/settlement/regions.gd::food_seller`, `game/scripts/core/settlement/offmap.gd::sell_to_village`
- **Affects:** Settlements, Coins, Inventory, Food, Market, Households, Treasury, Granary, Relief, Ledger
- **Expected:** (owner Q18-10) Households, the manor's treasury and the food trades buy a unit at a time from the cheapest trader on the road (`food_seller`), each under the rule the village already follows: a household whose reserve-days food (World.necessity's food, in points) is not covered and that finds no grain seller or food vendor in the village (`_grain_seller`, `_vendor_with_food`) pays from its members' coins; the treasury fills the granary towards `granary_target_days` less what the farmers' and merchants' surplus will supply this evening, from money above `treasury_reserve_days` of obligations (the reeve's procurement rule; in a famine the farmers' surplus is not counted on); the food merchant, cook and tavernkeeper buy up to `NPCBrain.wants` less what the village's sellers hold, when `World.can_afford`. The buyer pays the settlement's price into the trader's till (`sell_to_village`), the food enters the buyer's store; the coins leave the village (`coin_sources`, `caravan_coins_out`) and the goods are `imported_*` in the ledger; the whole world's coins are unchanged.
- **Tests:** `game/tests/regional_food_test.gd::test_village_buys`, `game/tests/regional_food_test.gd::test_prices`

### INT-300 · The manor's tax rate is a band with hysteresis, announced before it applies (DVW-B5)
- **Trigger:** `NPCBrain.reeve_day` (the reeve's evening, once a day) steps `TaxPolicy` with the treasury in days of daily obligations before collecting tax.
- **Source:** `game/scripts/core/tax_policy.gd::step`, `game/scripts/core/tax_policy.gd::target_band`, `game/scripts/core/npc_brain.gd::reeve_day`, `game/scripts/core/world.gd::to_dict`
- **Affects:** Treasury, Coins, Households, Wages, Settlements
- **Expected:** The rates (12% low, 6% normal, 0% holiday) and boundaries (`treasury_reserve_days`, `treasury_tax_holiday_days`) are unchanged, but a band changes only once the treasury is `tax_band_margin` (20%) past a boundary, and only `tax_announce_days` (3) after the manor announces it in the village record; an announcement is withdrawn if the treasury returns. Tax moves coins from households to the treasury exactly as before (nothing made or lost). State is `World.tax_state` (save key "tax", optional: absent starts in the band the treasury plainly shows, without an announcement). The off-map settlements' `_taxes_and_officials` still use the old single-threshold rule (not yet banded).
- **Tests:** `game/tests/tax_test.gd::no_flip_flop`, `game/tests/tax_test.gd::announced_before_applied`, `game/tests/tax_test.gd::save_round_trip`

### INT-310 · People travel between the village and the five settlements with the caravan, carrying their purses and goods (MIGRATE-18)
- **Trigger:** `NPCBrain.caravan` (noon on a visit day) calls `Migration.visit` first, before the succession newcomers and the trade: for each settlement whose trader is on the road (`Regions.visiting`), each reason is tried in both directions, at most one move for each reason, direction and settlement.
- **Source:** `game/scripts/core/settlement/migration.gd::visit`, `game/scripts/core/settlement/migration.gd::_gone`, `game/scripts/core/settlement/migration.gd::_settled`, `game/scripts/core/settlement/migration.gd::_book`, `game/scripts/core/settlement/offmap.gd::receive_household`, `game/scripts/core/settlement/offmap.gd::release_household`, `game/scripts/core/settlement/offmap.gd::release_person`, `game/scripts/core/settlement/regions.gd::log_move`, `game/scripts/core/npc.gd::to_dict`
- **Affects:** Settlements, Households, Coins, Inventory, Food, Employment, Family, Property, Save
- **Expected:** (owner Q18-7 "Both ways, for reasons"; REG-DEMO-D1: no new population-balancing mechanics, no change to demographic rates) People move only with a real signal from rules the game already has (INT-311, INT-312), travelling on the caravan's visit day, so the nearer settlements see more traffic. A traveller keeps name, age, sex and skills; the purse and the pack (and, for a whole household, its pantry) go with them. The village's coins and goods cross exactly like the couriers' (`coin_sources`, `caravan_coins_in/out`, `exported_/imported_`; the settlement's `outside_*` flow lines, so both audits balance) and people are counted on both sides (`Regions.move_counts` against the settlements' `migrants_in/out`, which `Regions.net_migrants_from_village` and `net_migrants_counted` must agree on). The villager who leaves stays in `World.npcs` with `alive` false and `away` set, their post and stall handed on as after a death (`NPCBrain.on_death`) and their experience forgotten; a settlement member who arrives is a new villager. Nothing is made or lost, and no rate is added: the log is capped, the counts are not. The move is written to the village log and to the settlement's own journal.
- **Tests:** `game/tests/migration_test.gd::test_no_reason_no_move`, `game/tests/migration_test.gd::test_conservation_and_save`, `game/tests/migration_test.gd::test_old_save`, `game/tests/migration_test.gd::test_determinism`, `game/tests/regions_test.gd::test_world_caravan`

### INT-311 · Hunger and work send people the other way when the home place cannot feed or employ them, and a real migrant fills a post before a newcomer is made (MIGRATE-18)
- **Trigger:** `Migration.visit` (INT-310), reasons "hunger" and "work".
- **Source:** `game/scripts/core/settlement/migration.gd::_hunger_out`, `game/scripts/core/settlement/migration.gd::_hunger_in`, `game/scripts/core/settlement/migration.gd::_work_out`, `game/scripts/core/settlement/migration.gd::_work_in`, `game/scripts/core/settlement/migration.gd::open_vacancies`, `game/scripts/core/settlement/migration.gd::hiring`, `game/scripts/core/settlement/migration.gd::spare_food_pts`, `game/scripts/core/settlement/offmap.gd::_move_jobs`
- **Affects:** Settlements, Households, Food, Relief, Employment, Coins, Inventory, Granary
- **Expected:** Hunger out: a village household under `relief_trigger_days` of food while the village is in famine (`World.famine`: the manor's relief cannot cover it) goes, with its pantry, to a settlement whose food businesses hold food above their own claim (`food_claim_pts`). Hunger in: a settlement household that is hungry and cannot buy a day's food (the PAR-02A test) goes to a village that is out of famine and holds more than `reserve_days` of food for its need, if there is a home to lease or a room. Work out: an adult without a trade, in a household that cannot live on its income (the `seek_work` condition), while the labour market has no open place, goes to a settlement business that paid its workers `switch_to_at_least` a day last week. Work in: an adult of a settlement household that earned under `switch_below` a day for a week takes a village post nobody could fill (a succession vacancy past `succession_days` with no apprentice, which a real migrant now takes before `_newcomer_for` makes one with a made purse), else an open tool-free place that pays more than their household earned. A village household that is hungry in a village that is not in famine, or a settlement household that can pay, never moves.
- **Tests:** `game/tests/migration_test.gd::test_hunger`, `game/tests/migration_test.gd::test_work`

### INT-312 · Land and marriage: a household without a home waits then leaves, a landless settlement household with a house's price comes, and couples meet at the caravan (MIGRATE-18)
- **Trigger:** `Migration.visit` (INT-310), reasons "land" and "marriage".
- **Source:** `game/scripts/core/settlement/migration.gd::_land_out`, `game/scripts/core/settlement/migration.gd::_land_in`, `game/scripts/core/settlement/migration.gd::_marry_out`, `game/scripts/core/settlement/migration.gd::_marry_in`, `game/scripts/core/settlement/migration.gd::_courted`, `game/scripts/core/settlement/offmap.gd::wed_in`, `game/scripts/core/construction.gd::housing_goals`, `game/scripts/core/life.gd::_link_partners`
- **Affects:** Settlements, Households, Property, Building, Family, Coins, Employment
- **Expected:** Land out: a village household whose housing goal ("no home", or "crowded" with a grown member who would found a household) has waited on coins for `mobility_unsustainable_days` goes (the household, or that member and their partner) to a settlement whose land yields food above its claim; the off-map has no houses, so none is needed there. Land in: a settlement household formed by a marriage there (`landless`) that can pay for a house on the manor's market by the village's own rule (`Construction._home_plan`: buy, else two weeks' rent) comes and takes it (`_find_home`). Marriage: a grown, unpartnered, willing person of each side within `partner_min_age`..`partner_max_age` and `partner_max_gap` (a settlement member also past `marry_min_days` of age, as `_found_household`) who is not kin meets at the caravan; after `marry_min_days` days of the same pair (the village's courting time, kept in `Regions.suits`) the bride goes to the groom's place: into his household's house when it has a bed, or into a household of their own with a share of his household's coins and pantry. The couple are partners by the village's own link (`Life._link_partners`) or a settlement couple.
- **Tests:** `game/tests/migration_test.gd::test_land`, `game/tests/migration_test.gd::test_marriage`, `game/tests/migration_test.gd::test_carried_across`

### INT-313 · Each settlement's tax is the village's banded, announced rule, on its own treasury and in its own journal (DVW-B5)
- **Trigger:** `OffMapSettlement.step_day` (once a day, after wages) runs `_taxes_and_officials`, which steps `TaxPolicy` with the settlement's treasury in days of its wages before tax is taken.
- **Source:** `game/scripts/core/settlement/offmap.gd::_taxes_and_officials`, `game/scripts/core/settlement/offmap.gd::note`, `game/scripts/core/settlement/offmap.gd::to_dict`, `game/scripts/core/settlement/offmap.gd::from_dict`, `game/scripts/core/tax_policy.gd::step`
- **Affects:** Settlements, Treasury, Coins, Households, Wages, Save
- **Expected:** The single-threshold copy is gone: a settlement's rate is the village's band (12% low, 6% normal, none at holiday; the same margin `tax_band_margin` and notice `tax_announce_days`; no new numbers). Each settlement keeps its own tax state (`tax`) and journal (`journal`, the last 100 lines: tax announcements, arrivals and departures), both saved as optional keys; an announcement goes to the journal, never the village log. A save without the keys starts in the band the treasury plainly shows. Tax still only moves coins from households and tills to the treasury.
- **Tests:** `game/tests/tax_test.gd::settlements_use_the_banded_rule`, `game/tests/tax_test.gd::settlement_taxes_save`

### INT-320 · A business with a shop opens a courier booth of its own, carried by the village booth's keeper (X18-Q12-BOOTH, Q18-15)
- **Trigger:** A business's first posting (`CourierService.villagers_post`, daily) or the player's "Open a courier booth at your stall" action (`main.gd`); each dawn `daily` joins every shop booth to every settlement's booth and tidies the booths of the dead.
- **Source:** `game/scripts/core/settlement/couriers.gd::open_shop_booth`, `game/scripts/core/settlement/couriers.gd::home_booth`, `game/scripts/core/settlement/couriers.gd::carrier_booth`, `game/scripts/core/settlement/couriers.gd::book_route`, `game/scripts/core/settlement/couriers.gd::_tidy_shop_booths`, `game/scripts/main.gd::_find_target`
- **Affects:** Market, Coins, Inventory, Employment, Settlements, Save
- **Expected:** (owner Q18-15, "any business with a shop"; Q18-16) The booth stands at the shop (the market stall or workplace), kept by its owner, with a route to each of the five settlements carried by the village booth's keeper: the flat fee `routes.fee_per_load` is paid to that keeper, never to the owner of the shop. The goods wait in the shop booth's store and deposits wait at it. The village's own booth is a free market stall or a stall its keeper builds near the market from their own planks. An owner's booth passes to the stall's new tenant or closes (with its routes) when empty. No coin or good is made.
- **Tests:** `game/tests/courier_live_test.gd::test_shop_booths`, `game/tests/courier_live_test.gd::test_near_market_booth`

### INT-321 · A merchant or smith with surplus a settlement lacks posts it by its own booth's regular route (X18-Q12-POST, same rules for NPCs)
- **Trigger:** `CourierService.daily` (each dawn, from `World._new_day`) runs `villagers_post` for the villagers in id order.
- **Source:** `game/scripts/core/settlement/couriers.gd::villagers_post`, `game/scripts/core/settlement/couriers.gd::book_route`, `game/scripts/core/npc_brain.gd::export_caps`, `game/scripts/core/npc_brain.gd::caravan`, `game/scripts/core/settlement/offmap.gd::wants`
- **Affects:** Market, Coins, Inventory, Settlements, Ledger
- **Expected:** A merchant or smith that has dealt with a settlement's trader (`contacts`) and holds more than the caravan's own surplus rule leaves it (`export_caps`, beyond half of the most it stocks; never food, never the village's tools in need) of something that settlement lacks now, within what the trader's till can pay and a small agreement (`contracts.small_value`), books the regular route at the flat fee, asking the caravan's price on arrival. One delivery in flight a business. The same booking, fee and conservation as the player's; the books balance across the boundary (INT-281).
- **Tests:** `game/tests/courier_live_test.gd::test_villagers_post`

### INT-322 · A formal payment is signed before a courier-notary, never remotely (X18-Q13, Q18-13)
- **Trigger:** A special delivery is booked (`book_special`), arrives (`_arrive`) and comes home (`_home`) with a payment above `contracts.small_value`.
- **Source:** `game/scripts/core/settlement/couriers.gd::refusal`, `game/scripts/core/settlement/couriers.gd::is_formal`, `game/scripts/core/settlement/couriers.gd::book_special`, `game/scripts/core/settlement/couriers.gd::_arrive`, `game/scripts/core/settlement/couriers.gd::_home`, `game/scripts/core/settlement/couriers.gd::interrupt`, `game/scripts/core/settlement/formal_contracts.gd::sign_before_notary`, `game/scripts/core/settlement/formal_contracts.gd::bring_home`
- **Affects:** Coins, Inventory, Save, Employment, Player state
- **Expected:** A payment above the small-agreement line is a formal contract. A regular route and a courier without Law at `notary.min_level` cannot carry it; a special delivery's courier holds the document: the sender signs before it at booking, the recipient on arrival (only while the notary holds it), and it binds only when the notary has brought it home. A recipient who refuses or cannot pay leaves it rejected (goods return); a notary who dies interrupts it and the held fee returns. The notary gains Law for each signature witnessed and the document carried (INT-223). A small payment has no document. The document is saved with the courier service. No coin moves because of a signature.
- **Tests:** `game/tests/courier_live_test.gd::test_notary_live`, `game/tests/contract_sign_test.gd`, `game/tests/courier_test.gd::test_deposit_and_rejection`

### INT-323 · The village's courier keepers take the lessons that give them the Law a notary needs (LAW-SKILL)
- **Trigger:** `CourierService.daily` runs `keepers_learn`.
- **Source:** `game/scripts/core/settlement/couriers.gd::keepers_learn`, `game/scripts/core/law.gd::teach`, `game/scripts/core/law.gd::teacher_cap`, `game/data/couriers.json`
- **Affects:** Employment, Player state, Save
- **Expected:** Each villager keeping a village booth with less Law than the notary level takes a lesson from the reeve or the preacher, a lesson a game day by `Law.teach`'s rule (`law.lesson_xp`, `law.lessons_per_day`, the teacher's ceiling), until Law 2 (the provisional notary level). Free; no coin moves. The player learns from the same teachers by the talk choice.
- **Tests:** `game/tests/courier_live_test.gd::test_notary_live`, `game/tests/courier_live_test.gd::test_law_lessons`

### INT-324 · A settlement's trader may carry a special delivery for a negotiated fee, on its way home (Q18-10)
- **Trigger:** The courier form lists the couriers for the chosen recipient's settlement (`carriers`); a special delivery is booked with one (`refusal` checks `carrier_refusal`).
- **Source:** `game/scripts/core/settlement/couriers.gd::carriers`, `game/scripts/core/settlement/couriers.gd::carrier_refusal`, `game/scripts/core/settlement/couriers.gd::quote`, `game/scripts/core/settlement/settlement_party.gd::option`, `game/scripts/ui/courier_window.gd::_couriers`
- **Affects:** Settlements, Coins, Market
- **Expected:** (owner Q18-10, "a willing carter, negotiated and paid; never free") The trader of a settlement the sender has dealt with is offered as a courier to its own settlement (its way home), and anywhere if its party offers `carts_for_hire` (an option that stays off in the live game: the regional market is unchanged). Its fee is the fee worked out from the work (the days, loads, stops) and is paid, as coins crossing the village's boundary, only when the work is done. A trader has no Law and cannot notarise.
- **Tests:** `game/tests/courier_live_test.gd::test_settlement_carriage`

### INT-325 · The player buys food at the caravan's wagon at the traders' prices (REG-BUY-01 parity)
- **Trigger:** The player stands beside the visiting caravan's wagon and chooses a food (`main.gd` context action `caravan_food`).
- **Source:** `game/scripts/core/caravan_food.gd::buy`, `game/scripts/core/caravan_food.gd::offers`, `game/scripts/core/caravan_food.gd::refusal`, `game/scripts/main.gd::_find_target`, `game/scripts/core/settlement/regions.gd::food_seller`
- **Affects:** Settlements, Coins, Food, Inventory, Market
- **Expected:** One unit at a time of the settlements' foods and raw meat, from the cheapest trader on the road that holds it, at its floating price (`food_price`): the unit leaves its stock, the coins enter its till and leave the village (`coin_sources`, `caravan_coins_out`, `imported_<item>`), the same booking as the households' and businesses' purchases (INT-291). What no trader holds cannot be bought; the pack's capacity applies.
- **Tests:** `game/tests/luxury_test.gd::test_player_food`

### INT-330 · Barter swaps goods for goods at both sides' prices and moves no coins (TRADE-CREDIT)
- **Trigger:** the player's Barter button in the trade window's credit page, or a villager household short of food at dawn that cannot pay and holds goods the neighbour who sells food is glad of (`Credit.dawn` after `NPCBrain.dawn`).
- **Source:** `game/scripts/core/credit.gd::barter_quote`, `game/scripts/core/credit.gd::barter`, `game/scripts/ui/credit_window.gd::show`, `game/scripts/core/npc_brain.gd::dawn`
- **Affects:** Market, Inventory, Coins, Households, Save
- **Expected:** The buyer takes the wanted goods from a seller and gives as many units of one other good as it takes for the seller's bids (`World.buy_price_at`, both sides' Trading, the player's friend price) to reach the seller's ask (`World.sell_price_at`, local supply); the seller takes only what its trade works (`NPCBrain.wants`) or is glad of (`Relations.favourites`), the giver offers only what is its own to spare (not what its trade keeps or owes, not a necessity, not the player's stolen goods). Goods move both ways at once or nothing does; no coin is made, moved or spent; the pair become commercial contacts (`Relations.note_trade`). The rule is the same for the player and a villager.
- **Tests:** `game/tests/credit_test.gd::test_barter`, `game/tests/credit_test.gd::test_barter_refusals`, `game/tests/credit_test.gd::test_parity`

### INT-331 · Credit rests on the creditor's regard; a debt is repaid from coins above the reserve or defaults (TRADE-CREDIT)
- **Trigger:** a purchase on credit (the player's Buy 1 on the credit page, or a villager household short of food at dawn with neither coins nor barter goods) and every dawn for the debts on the record (`Credit.dawn`).
- **Source:** `game/scripts/core/credit.gd::credit_refusal`, `game/scripts/core/credit.gd::sell_on_credit`, `game/scripts/core/credit.gd::repay`, `game/scripts/core/credit.gd::dawn`, `game/scripts/core/credit.gd::_default`, `game/scripts/core/world.gd::to_dict`, `game/scripts/core/world.gd::load_dict`
- **Affects:** Market, Coins, Households, Relief, Save, Interface
- **Expected:** A seller hands over goods now for a recorded debt in coins (the ask, no interest, `credit.days` to pay) only if its regard for the buyer is at least `relations.befriend_at`, the buyer owes no defaulted debt to it, the sum owed stays within `credit.limit`, and the seller holds its own reserve in coins (`World.reserve_of`). A villager debtor repays at dawn from the due day if `World.can_afford` allows (coins above the household's reserve); otherwise a day after the due day it defaults: the creditor's regard falls `credit.default_regard` (the player's default spreads to the creditor's kin and friends through `Relations.harmed`; a villager's to the creditor's friends), no more credit while it stands, and nothing is seized. The player repays by choice in the trade window; a repayment raises regard (half when late). Repayment only moves coins from debtor to creditor: none are made. Debts are saved (optional key "credit"; an older save has none).
- **Tests:** `game/tests/credit_test.gd::test_credit_trust`, `game/tests/credit_test.gd::test_repay_and_default`, `game/tests/credit_test.gd::test_need_defaults`, `game/tests/credit_test.gd::test_player_debtor`, `game/tests/credit_test.gd::test_save`, `game/tests/credit_test.gd::test_villagers_in_need`

### INT-332 · A debtor's or creditor's death passes the debt to the heir or writes it off (TRADE-CREDIT)
- **Trigger:** `World.kill` (a villager dies) and `World.continue_as_heir` (the player dies).
- **Source:** `game/scripts/core/credit.gd::on_death`, `game/scripts/core/credit.gd::on_player_died`, `game/scripts/core/world.gd::kill`, `game/scripts/core/world.gd::continue_as_heir`
- **Affects:** Inheritance, Households, Coins, Family
- **Expected:** A villager who dies of natural causes leaves their debts and claims to the heir the inheritance rule names (`World._heir`: the goods and coins pass the same way); a villager slain, or with no heir, leaves a debt written off (state lost, counted), a claim forgiven. A debt whose heir is the other party is written off. The player's death writes off every debt of theirs and owed them: the heir starts with the kit only, and as a stranger to the village. No coin is made or destroyed.
- **Tests:** `game/tests/credit_test.gd::test_death`

### INT-370 · The player volunteers on the church field by the villagers' rules and work path (DVW-B3-CHAPEL, B18-DP-12)
- **Trigger:** The player faces a cell of the church's plot and Uses (a "Volunteer: ..." choice for harvesting, sowing, tilling or clearing).
- **Source:** `game/scripts/core/farm_plots.gd::church_targets`, `game/scripts/core/farm_plots.gd::church_plan`, `game/scripts/core/farm_plots.gd::church_work`, `game/scripts/core/farm_plots.gd::work_cell`, `game/scripts/core/farm_plots.gd::clearable`, `game/scripts/core/farming.gd::targets_at`, `game/scripts/core/farming.gd::plan`, `game/scripts/main.gd`
- **Affects:** Fields, Inventory, Relief, Food, Player state, Interface, Save
- **Expected:** (owner B18-DP-12, 2026-10-23: "the player must be able to volunteer on the church field under the same applicable rules as NPC villagers"; no new rule) The one cell rule `FarmPlots.work_cell` (and the one clearing rule `clearable`) serves a volunteer villager's step (`act`) and the player's: the crop and its seed back go into the church's store (`Chapel.store`), seed is sown from the worker's pack then the church's store, the plot's fence and till rules apply, and a badly hurt person (`able`, `able_player`) does not work it. The player's time and stamina are those of their own field (`Farming.till_cost`, the configured seconds); the player is paid no coin, takes no crop, and gets only the farming experience the work trains (DVW-B8; a villager's `fp_work` step trains it too); coins and goods are only moved, none made. Cells and the store are saved with the world, so a save keeps the work.
- **Tests:** `game/tests/chapel_test.gd::test_player_volunteers`, `game/tests/chapel_test.gd::test_plot_work`

## Reverse dependency index

<!-- index:start (generated by tools/check_interactions.py --write) -->

| System | Interactions |
|---|---|
| Character | INT-001, INT-018, INT-031, INT-080, INT-208 |
| Player state | INT-003, INT-004, INT-005, INT-006, INT-018, INT-021, INT-031, INT-038, INT-044, INT-052, INT-053, INT-080, INT-097, INT-098, INT-101, INT-105, INT-106, INT-109, INT-121, INT-122, INT-145, INT-146, INT-150, INT-155, INT-156, INT-177, INT-182, INT-186, INT-190, INT-200, INT-208, INT-211, INT-212, INT-213, INT-219, INT-222, INT-223, INT-224, INT-322, INT-323, INT-370 |
| Inventory | INT-003, INT-005, INT-006, INT-007, INT-008, INT-009, INT-010, INT-014, INT-015, INT-019, INT-021, INT-027, INT-028, INT-030, INT-031, INT-032, INT-038, INT-043, INT-044, INT-045, INT-046, INT-059, INT-064, INT-066, INT-067, INT-068, INT-069, INT-070, INT-074, INT-083, INT-086, INT-087, INT-099, INT-100, INT-101, INT-103, INT-104, INT-106, INT-107, INT-113, INT-117, INT-118, INT-119, INT-121, INT-122, INT-123, INT-124, INT-125, INT-126, INT-128, INT-131, INT-132, INT-134, INT-136, INT-137, INT-146, INT-160, INT-162, INT-164, INT-166, INT-168, INT-170, INT-171, INT-173, INT-174, INT-175, INT-176, INT-177, INT-178, INT-180, INT-182, INT-186, INT-188, INT-189, INT-190, INT-191, INT-193, INT-195, INT-196, INT-197, INT-198, INT-199, INT-201, INT-203, INT-205, INT-209, INT-210, INT-211, INT-218, INT-225, INT-226, INT-227, INT-231, INT-240, INT-250, INT-251, INT-252, INT-270, INT-271, INT-281, INT-283, INT-290, INT-291, INT-310, INT-311, INT-320, INT-321, INT-322, INT-325, INT-330, INT-370 |
| Equipment | INT-003, INT-004, INT-015, INT-031, INT-176, INT-186, INT-190, INT-199, INT-200, INT-202, INT-206, INT-207, INT-210 |
| Food | INT-010, INT-011, INT-027, INT-028, INT-042, INT-047, INT-054, INT-072, INT-079, INT-096, INT-099, INT-124, INT-128, INT-129, INT-138, INT-141, INT-145, INT-147, INT-149, INT-158, INT-159, INT-163, INT-176, INT-226, INT-227, INT-230, INT-240, INT-241, INT-290, INT-291, INT-310, INT-311, INT-325, INT-370 |
| Health | INT-004, INT-010, INT-011, INT-012, INT-016, INT-018, INT-033, INT-080, INT-083, INT-108, INT-139, INT-141, INT-142, INT-145, INT-155, INT-208 |
| Combat | INT-004, INT-012, INT-013, INT-032, INT-068, INT-088, INT-108, INT-156, INT-176, INT-192 |
| Crime | INT-007, INT-008, INT-013, INT-031, INT-032, INT-038, INT-039, INT-043, INT-044, INT-045, INT-046, INT-048, INT-050, INT-051, INT-064, INT-067, INT-068, INT-069, INT-100, INT-102, INT-109, INT-117, INT-146, INT-148, INT-192 |
| Loot | INT-015, INT-016, INT-018, INT-028, INT-030, INT-086, INT-113, INT-117, INT-154, INT-201, INT-208, INT-210, INT-283 |
| Fields | INT-007, INT-009, INT-025, INT-029, INT-046, INT-051, INT-064, INT-067, INT-068, INT-089, INT-122, INT-123, INT-124, INT-125, INT-130, INT-160, INT-161, INT-164, INT-170, INT-171, INT-185, INT-204, INT-213, INT-216, INT-218, INT-224, INT-227, INT-370 |
| Resources | INT-004, INT-005, INT-006, INT-029, INT-035, INT-037, INT-040, INT-057, INT-065, INT-066, INT-067, INT-068, INT-069, INT-070, INT-071, INT-074, INT-076, INT-103, INT-106, INT-111, INT-121, INT-140, INT-141, INT-143, INT-145, INT-147, INT-152, INT-156, INT-162, INT-163, INT-173, INT-174, INT-179, INT-180, INT-182, INT-185, INT-186, INT-187, INT-188, INT-189, INT-190, INT-191, INT-192, INT-193, INT-194, INT-196, INT-197, INT-198, INT-201, INT-202, INT-204, INT-206, INT-210, INT-216, INT-218 |
| Crafting | INT-021, INT-035, INT-036, INT-051, INT-058, INT-067, INT-069, INT-070, INT-073, INT-075, INT-083, INT-092, INT-099, INT-103, INT-107, INT-114, INT-129, INT-132, INT-133, INT-138, INT-139, INT-141, INT-142, INT-143, INT-144, INT-151, INT-152, INT-154, INT-156, INT-157, INT-177, INT-178, INT-181, INT-190, INT-191, INT-198, INT-199, INT-202, INT-203, INT-205, INT-210, INT-216, INT-222 |
| Market | INT-019, INT-020, INT-024, INT-025, INT-026, INT-035, INT-036, INT-037, INT-041, INT-042, INT-043, INT-045, INT-047, INT-050, INT-051, INT-055, INT-059, INT-060, INT-065, INT-066, INT-067, INT-069, INT-072, INT-073, INT-075, INT-076, INT-083, INT-103, INT-108, INT-114, INT-116, INT-117, INT-118, INT-119, INT-120, INT-124, INT-125, INT-128, INT-129, INT-131, INT-134, INT-135, INT-136, INT-137, INT-138, INT-139, INT-141, INT-142, INT-143, INT-144, INT-146, INT-147, INT-148, INT-149, INT-151, INT-152, INT-154, INT-156, INT-157, INT-158, INT-159, INT-162, INT-164, INT-165, INT-168, INT-169, INT-171, INT-172, INT-174, INT-175, INT-176, INT-178, INT-181, INT-185, INT-187, INT-192, INT-198, INT-203, INT-205, INT-207, INT-210, INT-211, INT-212, INT-230, INT-231, INT-232, INT-240, INT-250, INT-270, INT-280, INT-282, INT-290, INT-291, INT-320, INT-321, INT-324, INT-325, INT-330, INT-331 |
| Coins | INT-003, INT-008, INT-014, INT-015, INT-016, INT-017, INT-019, INT-020, INT-022, INT-023, INT-026, INT-035, INT-036, INT-038, INT-044, INT-045, INT-046, INT-052, INT-053, INT-056, INT-057, INT-059, INT-060, INT-062, INT-065, INT-066, INT-072, INT-073, INT-075, INT-083, INT-090, INT-091, INT-102, INT-108, INT-116, INT-118, INT-119, INT-120, INT-125, INT-127, INT-129, INT-131, INT-134, INT-135, INT-136, INT-137, INT-138, INT-139, INT-141, INT-142, INT-143, INT-144, INT-151, INT-152, INT-154, INT-157, INT-158, INT-159, INT-164, INT-165, INT-168, INT-169, INT-170, INT-172, INT-175, INT-178, INT-180, INT-181, INT-184, INT-189, INT-197, INT-203, INT-207, INT-211, INT-212, INT-213, INT-214, INT-216, INT-217, INT-223, INT-225, INT-226, INT-230, INT-231, INT-232, INT-233, INT-240, INT-250, INT-251, INT-270, INT-271, INT-281, INT-283, INT-290, INT-291, INT-300, INT-310, INT-311, INT-312, INT-313, INT-320, INT-321, INT-322, INT-324, INT-325, INT-330, INT-331, INT-332 |
| Treasury | INT-008, INT-022, INT-023, INT-024, INT-025, INT-026, INT-031, INT-036, INT-045, INT-052, INT-053, INT-056, INT-057, INT-060, INT-062, INT-063, INT-066, INT-091, INT-102, INT-116, INT-120, INT-129, INT-131, INT-134, INT-154, INT-169, INT-170, INT-174, INT-175, INT-183, INT-184, INT-186, INT-194, INT-205, INT-217, INT-226, INT-230, INT-291, INT-300, INT-313 |
| Wages | INT-023, INT-029, INT-059, INT-066, INT-083, INT-184, INT-186, INT-194, INT-206, INT-209, INT-216, INT-217, INT-225, INT-226, INT-230, INT-240, INT-290, INT-300, INT-313 |
| Relief | INT-024, INT-047, INT-066, INT-159, INT-209, INT-226, INT-227, INT-291, INT-311, INT-331, INT-370 |
| Granary | INT-024, INT-025, INT-031, INT-047, INT-054, INT-066, INT-089, INT-159, INT-165, INT-172, INT-176, INT-209, INT-226, INT-291, INT-311 |
| Households | INT-016, INT-017, INT-022, INT-024, INT-027, INT-029, INT-038, INT-039, INT-042, INT-043, INT-047, INT-048, INT-050, INT-051, INT-053, INT-054, INT-059, INT-060, INT-062, INT-064, INT-066, INT-072, INT-073, INT-075, INT-078, INT-079, INT-080, INT-093, INT-095, INT-096, INT-100, INT-102, INT-118, INT-119, INT-134, INT-135, INT-136, INT-138, INT-141, INT-142, INT-143, INT-145, INT-146, INT-147, INT-148, INT-151, INT-152, INT-153, INT-155, INT-158, INT-159, INT-160, INT-162, INT-164, INT-165, INT-166, INT-167, INT-168, INT-170, INT-171, INT-172, INT-175, INT-176, INT-183, INT-200, INT-207, INT-218, INT-225, INT-226, INT-227, INT-230, INT-240, INT-241, INT-250, INT-260, INT-290, INT-291, INT-300, INT-310, INT-311, INT-312, INT-313, INT-330, INT-331, INT-332 |
| Employment | INT-017, INT-023, INT-028, INT-029, INT-037, INT-046, INT-047, INT-055, INT-059, INT-063, INT-066, INT-067, INT-074, INT-075, INT-078, INT-080, INT-083, INT-084, INT-085, INT-089, INT-112, INT-114, INT-119, INT-133, INT-135, INT-136, INT-137, INT-139, INT-154, INT-155, INT-156, INT-173, INT-174, INT-175, INT-180, INT-182, INT-183, INT-184, INT-186, INT-187, INT-189, INT-192, INT-194, INT-195, INT-196, INT-197, INT-198, INT-199, INT-200, INT-202, INT-205, INT-206, INT-209, INT-216, INT-217, INT-219, INT-222, INT-223, INT-224, INT-225, INT-227, INT-241, INT-280, INT-283, INT-310, INT-311, INT-312, INT-320, INT-322, INT-323 |
| Inheritance | INT-017, INT-062, INT-075, INT-080, INT-151, INT-332 |
| Livestock | INT-009, INT-013, INT-017, INT-027, INT-031, INT-033, INT-051, INT-067, INT-077, INT-081, INT-113, INT-126, INT-127, INT-128, INT-137, INT-145, INT-172, INT-213, INT-218, INT-224 |
| Wildlife | INT-014, INT-028, INT-029, INT-033, INT-067, INT-068, INT-077, INT-081, INT-086, INT-113, INT-127, INT-149, INT-163, INT-215, INT-224 |
| Bandits | INT-012, INT-014, INT-050, INT-149, INT-153, INT-154, INT-214 |
| Building | INT-018, INT-026, INT-030, INT-031, INT-036, INT-048, INT-051, INT-052, INT-054, INT-056, INT-057, INT-059, INT-060, INT-065, INT-066, INT-067, INT-069, INT-070, INT-079, INT-090, INT-091, INT-092, INT-093, INT-094, INT-119, INT-126, INT-130, INT-132, INT-133, INT-148, INT-151, INT-152, INT-153, INT-158, INT-168, INT-170, INT-174, INT-177, INT-185, INT-198, INT-220, INT-221, INT-312 |
| Workshops | INT-021, INT-030, INT-058, INT-085, INT-092, INT-107, INT-175, INT-178, INT-180, INT-181, INT-183, INT-184, INT-219, INT-220, INT-222 |
| Ledger | INT-007, INT-008, INT-009, INT-010, INT-019, INT-020, INT-021, INT-030, INT-046, INT-054, INT-065, INT-066, INT-083, INT-125, INT-149, INT-151, INT-152, INT-154, INT-160, INT-162, INT-165, INT-166, INT-167, INT-168, INT-169, INT-171, INT-174, INT-175, INT-176, INT-180, INT-182, INT-185, INT-186, INT-187, INT-188, INT-189, INT-190, INT-193, INT-194, INT-197, INT-201, INT-225, INT-230, INT-231, INT-232, INT-240, INT-250, INT-251, INT-252, INT-260, INT-270, INT-271, INT-281, INT-283, INT-291, INT-321 |
| Save | INT-001, INT-002, INT-031, INT-034, INT-038, INT-039, INT-042, INT-045, INT-046, INT-048, INT-059, INT-060, INT-062, INT-066, INT-067, INT-070, INT-071, INT-074, INT-075, INT-076, INT-077, INT-082, INT-084, INT-086, INT-087, INT-094, INT-098, INT-104, INT-105, INT-115, INT-116, INT-120, INT-126, INT-128, INT-130, INT-132, INT-134, INT-146, INT-148, INT-149, INT-150, INT-151, INT-153, INT-154, INT-156, INT-162, INT-173, INT-175, INT-179, INT-180, INT-182, INT-188, INT-189, INT-190, INT-191, INT-192, INT-193, INT-196, INT-197, INT-198, INT-208, INT-210, INT-211, INT-212, INT-213, INT-216, INT-219, INT-221, INT-222, INT-223, INT-224, INT-225, INT-227, INT-233, INT-241, INT-252, INT-260, INT-280, INT-282, INT-283, INT-310, INT-313, INT-320, INT-322, INT-323, INT-330, INT-331, INT-370 |
| Interface | INT-001, INT-002, INT-004, INT-012, INT-032, INT-033, INT-034, INT-039, INT-040, INT-041, INT-042, INT-044, INT-046, INT-049, INT-050, INT-052, INT-057, INT-058, INT-061, INT-062, INT-066, INT-068, INT-069, INT-070, INT-071, INT-074, INT-076, INT-077, INT-078, INT-081, INT-082, INT-084, INT-085, INT-086, INT-087, INT-088, INT-095, INT-096, INT-097, INT-098, INT-100, INT-112, INT-140, INT-142, INT-146, INT-148, INT-149, INT-150, INT-173, INT-175, INT-180, INT-210, INT-211, INT-212, INT-217, INT-223, INT-241, INT-251, INT-280, INT-331, INT-370 |
| Containers | INT-031, INT-042, INT-043, INT-051, INT-054, INT-055, INT-100, INT-101, INT-104, INT-146, INT-188, INT-189, INT-191, INT-193, INT-195, INT-210 |
| Interiors | INT-008, INT-014, INT-048, INT-049, INT-050, INT-058, INT-060, INT-079, INT-084, INT-088, INT-092, INT-093, INT-094, INT-110, INT-111, INT-138, INT-220, INT-227 |
| Property | INT-017, INT-018, INT-026, INT-030, INT-031, INT-051, INT-052, INT-053, INT-054, INT-055, INT-056, INT-057, INT-058, INT-060, INT-061, INT-067, INT-074, INT-075, INT-090, INT-091, INT-100, INT-121, INT-122, INT-126, INT-130, INT-142, INT-151, INT-153, INT-170, INT-185, INT-204, INT-220, INT-221, INT-227, INT-310, INT-312 |
| Calendar | INT-077, INT-123, INT-147, INT-149, INT-161, INT-163, INT-167, INT-171, INT-215 |
| Family | INT-077, INT-078, INT-079, INT-080, INT-148, INT-151, INT-152, INT-153, INT-214, INT-310, INT-312, INT-332 |
| Overworld | INT-071, INT-074, INT-076, INT-087, INT-177, INT-179, INT-214, INT-215, INT-221 |
| Settlements | INT-230, INT-231, INT-232, INT-233, INT-250, INT-251, INT-252, INT-260, INT-270, INT-271, INT-280, INT-281, INT-282, INT-290, INT-291, INT-300, INT-310, INT-311, INT-312, INT-313, INT-320, INT-321, INT-324, INT-325 |

<!-- index:end -->
