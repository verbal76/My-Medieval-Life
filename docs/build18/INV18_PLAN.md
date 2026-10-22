# INV-18: Phase A inspection and plan (2026-10-22)

The owner directive is `docs/directives/2026-10-22_build18_inventory_overhaul_inv18.md`. This plan was inspected on
`wip/build18` (`0048b56`). Build 17 is untouched.

## 0. Owner decisions and status (2026-10-22, after this plan)

The owner answered both questions (`docs/directives/2026-10-22_build18_owner_decisions_inventory_tailor_armor.md`):
- **INV-Q1:** the placements below stand, except lockpick and padlock, which are **tools** (not general). General now
  holds only the rock sample.
- **INV-Q2:** capacity is **9, 18, 27** per category, one whole row of the 3 x 9 grid per stage, in all eight
  categories at once; this replaces 18, 23 and 27 below. The two upgrades are bought from a tailor (TAILOR-18,
  150 and 450 coins, provisional).

Built on `wip/b18-inventory`: categories in `items.json`, the per-category capacity (`Inventory.category_cap`,
`PlayerState.pack_level`, `PACK_CAPS = [9, 18, 27]`), worn gear outside the grid, all-or-nothing equip, unequip and
swap, category-named refusals on every player path, the window (eight category tabs, Skills and Journal buttons,
rows locked by stage, over-capacity shown), save 19 with migration, the wiki page `sys:pack`, and
`game/tests/inventory18_test.gd`. The medicine tab shows the healing tonic, not the bandage: the bandage reads as a
grey scrap at tab size.

## 1. What exists

### Authoritative store

`Inventory` (`game/scripts/core/inventory.gd`) holds:
- `items`: item id → count. One entry is one "item-type position", and a stack has no upper size;
- `durability`: item id → the wear left on the one in use;
- `max_stacks`: 0 means any number of kinds.

The player's pack sets `max_stacks = 24` (`PlayerState`, line 55). Every add goes through `can_add(id)`. That covers
pickup, purchase (`World.trade`, `player_buy_many`), transfers (`World.transfer`), crafting outputs, chests and stalls,
so changing the capacity rule there covers every path at once. Carts and chests set their own `max_stacks`; they stay as
they are.

### Equipment

The six slots are weapon ("In hand"), tool, armor ("Body"), head, amulet and ring (`PlayerState.GEAR`). Each holds an
item id whose unit stays in `inv`. An equipped item therefore uses one of the 24 kinds today, and that is the defect the
directive names.

### Tabs

The tabs today are All, Food (food and medicine), Materials (`resource`), Tools, Weapons, Armour (armour, head, amulet,
ring), Skills and Journal (`inventory_window.gd`, `TABS`).
- Two of the eight open other windows; they hold no items.
- Every item tab is a filter over the same 24 kinds.

### Registry

The registry has 84 items:

| Type | Count |
|---|---|
| `resource` | 47 (raw and processed goods mixed) |
| `food` | 14 |
| `tool` | 8 |
| `medicine` | 4 |
| `weapon` | 3 |
| `armor` | 3 |
| `head` | 2 |
| `ring` | 2 |
| `amulet` | 1 |

There is no category field.

### Save

`Inventory.to_dict` saves items, durability and `max_stacks`. Equipment is saved on `PlayerState`.

## 2. Plan

### Classification

Each item gets an explicit `category` in `items.json`. A test fails if any item lacks one or names an unknown category.
Precedence: a weapon is a weapon, a tool a tool, a wearable is armour and clothing, food is food and medicine is
medicine, whatever made them. Raw materials are what is gathered, dug, cut or taken from animals before any workshop
step. Crafted goods are what a workshop made that is none of the above. General is what is left, kept short and listed
here.

| Category (tab icon) | Items |
|---|---|
| General (pouch) | ore_sample, padlock, lockpick |
| Food and drink (red berries) | ale, apple, blueberries, bread, carrot, cheese, egg, milk, potato, pottage, red_berries, roast_meat, rotten_apple, meat |
| Raw materials (logs) | log, stone, coal, copper_ore, iron_ore, gold_ore, dirt, topsoil, spoil, hide, rabbit_pelt, wool, feather, flower, wheat; seeds and planting stock: wheat_seed, carrot_seed, potato_seed, herb_seed, flower_seed, apple_sapling, oak_sapling, pine_sapling, red_berry_cutting, blue_berry_cutting |
| Tools (pickaxe) | axe, hammer, mallet, pickaxe, rusty_pickaxe, plough, prospecting_kit, shovel |
| Weapons (sword) | copper_sword, iron_sword, rusty_sword |
| Armour and clothing (chestplate) | plain_clothes, leather_armor, iron_armor, leather_cap, iron_helmet |
| Medicine (bandage) | linen_bandage, herbal_poultice, healing_tonic, strong_healing_tonic, herbal_tonic |
| Crafted goods and valuables (ingot) | copper_bar, iron_bar, gold_bar, plank, building_block, leather, wool_cloth, nails, cart_wheel, cart_axle, cart_ironwork, shovel_blade, shovel_haft, timber_support, track_section, ladder, handcart, minecart; jewellery: copper_ring, gold_ring, amulet |

The owner's question is about the borderline cases (section 3).

### Capacity

- The player's `Inventory` gets a category capacity of 18, 23 or 27 by `PlayerState.pack_level` (0 to 2; saved,
  default 0).
- `can_add(id)` is true when the kind is already in the pack, or when its category has a free position.
- A category's used positions are its kinds whose count minus the units equipped is above 0. So a worn or wielded item
  takes no backpack position, while a second, unworn copy of it does.
- Stacks are unchanged: any number per kind, as today.
- One authoritative store stays; the categories are capacity rules only.

### Equipment

Equip, unequip and swap keep working on the same store, so no copy is made or lost. Taking an item off is refused, with
"Armour and clothing full: 18 of 18", when its category has no room and no other unit of it is carried. A swap checks
room for the displaced item first and is all or nothing.

### Messages

Every refusal names the category ("Tools inventory full: 18 of 18 slots"). That includes the trade window's notice
(the Build 18 full-pack fix, adapted) and gathering and crafting.

### Interface

- The eight tabs are the eight categories, each a 3 × 9 grid showing "Tools: 12 / 18".
- The bottom row shows five cells with a first-upgrade lock and four with a second-upgrade lock.
- Skills and Journal move to two buttons beside the tabs. They open the same windows as before; they are not
  categories (agent decision).
- Icons come from owned art first:
  - the pouch (`tab_all`);
  - red berries (`red_berries`);
  - a log;
  - a pickaxe;
  - a sword;
  - a chestplate (`iron_armor`);
  - a bandage (`linen_bandage`);
  - an ingot (`iron_bar`).

### Saves

- Save version 19. Categories are not stored: they come from the registry, so a reclassification never strands an
  item. `pack_level` is stored.
- A version-18 or older save loads every item, count and wear exactly as saved, with equipment as it was.
- A save whose category now holds more kinds than 18 (possible: an old pack could hold 24 raw materials) keeps them
  all. The tab shows "Raw materials: 20 / 18" and takes no new kind until under capacity (agent decision: nothing is
  dropped).

### Upgrades

The capacity stages and their saved level are built, with no way to gain them in play until the owner chooses one.
Tests set the level directly.

### Tests

These are focused:
- classification coverage;
- per-category capacity at levels 0, 1 and 2;
- the equipped-takes-no-space rule;
- equip, unequip and swap refusals with no loss;
- buy, sell, pickup and craft against a full category while other categories have room;
- chest transfer;
- save and load, plus migration fixtures (empty, partial, full 24, over 18 in one category, equipped, stacked, worn
  items);
- item and coin conservation;
- the inventory window in mouse, pad and touch screenshots.

## 3. Owner decisions

1. **Borderline classifications.** Shown as recommended above:
   - jewellery: crafted and valuables, or armour and clothing;
   - wheat (grain): raw, or food;
   - raw meat: food, or raw;
   - seeds, saplings and cuttings: raw, or general;
   - herbal tonic (typed food today): medicine, or food;
   - lockpick and padlock: general, or tools and crafted.
2. **Upgrade acquisition.** How the two upgrades are gained and what they cost. This is presented later and is not
   needed to build the system.
