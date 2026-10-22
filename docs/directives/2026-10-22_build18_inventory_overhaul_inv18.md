MY MEDIEVAL LIFE — BUILD 18 MASTER INVENTORY OVERHAUL

INV-18: Categorized Inventory, Equipment Separation, Capacity Expansion and UI Redesign

Project: My Medieval Life
Studio: Hot Attic Games
Target: Build 18
Priority: Core gameplay system overhaul
Owner directive: Approved inventory architecture and capacity targets

---

1. PRIMARY OBJECTIVE

Replace the existing 24-item-type shared backpack with a genuine eight-category inventory system.

The game is developing into a deeply interconnected medieval economic simulation with farming, mining, forestry, manufacturing, trade, medicine, construction, weapons, armor and many levels of finished products.

The inventory must accommodate that complexity.

The current design is inadequate because:

1. All eight tabs filter the same 24 inventory positions.
2. Most category tabs appear empty even when the backpack is full.
3. Equipped items still count against backpack capacity.
4. The inventory provides too little usable storage for the number of item types the game supports.
5. Several category icons are visually ambiguous.
6. The locked-slot layout does not provide meaningful expansion.
7. Players cannot easily understand where items belong or why they cannot collect or purchase more.

The owner wants a large, organized, expandable inventory system.

Do not simply increase the existing shared capacity from 24 to 48 or 72.

Implement the underlying categorized capacity model.

---

2. REQUIRED INVENTORY ARCHITECTURE

INV-18-01 — Eight independent inventory categories

The inventory has exactly eight category tabs across the top.

Each category has its own independent capacity.

Items automatically belong to their designated category.

Switching tabs displays the actual contents of that category, not a filtered view of one shared 24-slot backpack.

An item occupies capacity only in its assigned category.

The same item must never appear as separately owned copies across multiple categories.

Maintain a single authoritative inventory and ownership system underneath the categorized interface.

The eight categories are separate capacity pools, not eight disconnected inventories.

INV-18-02 — Capacity per category

Each tab has:

- Three rows.
- Nine columns.
- Twenty-seven total item-type positions.

Starting capacity

The first two rows are unlocked.

That provides:

18 available slots per category.

The entire bottom row begins locked.

First inventory upgrade

Unlock the first five positions of the bottom row.

Capacity becomes:

23 available slots per category.

Second inventory upgrade

Unlock the remaining four positions.

Capacity becomes:

27 available slots per category.

The bottom row should visibly communicate the two upgrade stages.

Do not retain the current arbitrary three locked positions.

INV-18-03 — Total capacity

Stage| Per category| Eight categories
Starting| 18| 144
First upgrade| 23| 184
Second upgrade| 27| 216

The player also has six independent equipment slots.

Fully upgraded, the player can occupy up to:

216 backpack item-type positions + 6 equipped positions = 222 positions.

These are item-type or stack positions, not 222 individual physical items.

Preserve the existing legitimate stack quantity rules.

Do not introduce unlimited stack sizes as part of this overhaul.

INV-18-04 — Upgrade scope

Use the following provisional implementation assumption:

One inventory upgrade increases capacity across all eight categories simultaneously.

The first upgrade unlocks five slots in every tab.

The second upgrade unlocks the remaining four in every tab.

This avoids requiring sixteen separate category purchases.

However, the owner has not yet approved the acquisition method, price, crafting requirements or other economic mechanics of these upgrades.

Implement the capacity stages and their persistent state without inventing an economic source for upgrades.

Present any unresolved upgrade-progression decisions to the owner before activating them in normal gameplay.

The starting capacity of 18 per category must work without upgrades.

---

3. SIX INDEPENDENT EQUIPMENT SLOTS

INV-18-05 — Equipment does not consume backpack space

The six character equipment positions are separate from the eight inventory grids.

An item actively equipped in a valid equipment slot does not occupy a backpack position.

Equipping an item transfers its occupied position from backpack storage into the corresponding equipment slot.

Unequipping an item returns it to the appropriate inventory category, provided there is available capacity.

Equipment requirements

Inspect the existing six equipment slots and preserve their intended meanings.

Do not invent additional body slots.

Do not assume every slot accepts every type of item.

Preserve existing equipment restrictions, item ownership, durability, and stats.

The same physical item cannot simultaneously be equipped and present as a separate backpack item.

Full backpack behavior

If the destination category is full, unequipping must not silently delete or drop the item.

Use a safe, explicit response consistent with existing inventory and equipment behavior.

Do not duplicate equipment during swaps.

If replacing one equipped item with another, handle the displaced item and available capacity atomically.

Character appearance

Equipment changes must remain compatible with the Build 18 character creator and armor sprite integration.

An equipped armor item should eventually be reflected in the character's appearance according to the approved equipment-rendering system.

Do not grant free armor or equipment through inventory changes.

---

4. EIGHT DISTINCT ITEM CATEGORIES

INV-18-06 — Category taxonomy

Use eight clearly differentiated categories.

Start with this proposed taxonomy, then inspect the actual item registry to ensure every existing item has one unambiguous assignment.

Category 1 — General and Miscellaneous

Icon: Backpack or pouch.

For miscellaneous personal items and objects that do not fit another category.

This must not become an arbitrary dumping ground for items with missing classifications.

Category 2 — Food and Drink

Icon: Bright red berries.

Examples:

- Bread.
- Berries.
- Meat.
- Fish.
- Vegetables.
- Fruit.
- Milk.
- Cheese.
- Prepared meals.
- Beverages.

Do not use the current yellow loaf icon that resembles a gold bar.

The category must be recognizable immediately as food.

Category 3 — Raw Materials

Icon: Logs or a recognizable raw-resource bundle.

Examples:

- Timber.
- Logs.
- Raw stone.
- Ore.
- Plant fibers.
- Unprocessed hides.
- Other naturally gathered materials.

Category 4 — Tools

Icon: Pickaxe.

Examples:

- Pickaxes.
- Axes.
- Shovels.
- Hammers.
- Mallets.
- Chisels.
- Other work tools.

Tools used for labor belong here when not equipped.

Category 5 — Weapons

Icon: Sword.

Examples:

- Swords.
- Daggers.
- Bows.
- Other combat weapons.

Preserve the distinction between weapons and work tools.

Category 6 — Armor and Clothing

Icon: Chestplate.

Examples:

- Helmets.
- Body armor.
- Boots.
- Protective clothing.
- Ordinary clothing.
- Other wearable gear.

Unworn equipment belongs here.

Worn equipment occupies its applicable equipment slot instead.

Category 7 — Medicine and Consumables

Icon: Clearly recognizable medicine bottle or bandage.

Examples:

- Bandages.
- Healing remedies.
- Medicinal preparations.
- Other nonfood consumables.

Food must not be duplicated into this category merely because eating consumes it.

Category 8 — Crafted Goods and Valuables

Icon: Recognizable crafted-goods symbol, such as a finished ingot, jewelry or trade-goods bundle.

Examples:

- Manufactured products.
- Jewelry.
- Certain finished trade goods.
- Processed materials not assigned to another category.

This category must have a clear, consistent classification rule.

Classification precedence

Some items may reasonably fit more than one category.

For example:

- A crafted sword is a weapon, not a generic crafted good.
- A crafted pickaxe is a tool.
- A finished helmet is armor.
- Bread is food even though it is manufactured.
- A medicinal preparation is medicine even though it is consumable.

Define a deterministic classification rule so every item belongs to exactly one category.

Review the actual item registry before finalizing assignments.

Provide the owner with any genuine ambiguous classifications rather than silently inventing new item semantics.

---

5. AUTOMATIC ITEM SORTING

INV-18-07 — Items automatically enter their category

When a player obtains an item through:

- Picking it up.
- Purchasing it.
- Receiving payment in goods.
- Crafting.
- Harvesting.
- Mining.
- Looting.
- Trading.
- Receiving gifts.
- Completing contracts.
- Transferring goods from storage.

The item automatically occupies space in its designated category.

The player should not need to manually move items between category tabs.

Existing stacks should continue to stack according to the existing stack rules.

If an item already has a compatible stack, adding more of that item should not unnecessarily consume another item-type position.

Full-category behavior

If the relevant category is full, the game must report that specific category as full.

For example:

"Tools inventory full: 18 of 18 slots."

Do not claim that the entire backpack is full if other categories still have space.

Do not allow free space in the Food category to accommodate an item classified as a weapon.

Never delete, duplicate, or silently discard an item because of category capacity.

---

6. INVENTORY USER INTERFACE

INV-18-08 — Eight usable tabs

Keep eight category tabs across the top of the existing inventory interface.

Each tab displays its own 3 × 9 grid.

The interface should preserve the game's medieval pixel-art presentation.

The player must be able to:

- Open the backpack.
- Switch categories.
- View items in that category.
- Inspect item details.
- Equip applicable items.
- Unequip items.
- Transfer items.
- Use applicable consumables.
- See which slots are available and locked.

Tab indicators

Each category icon should be immediately recognizable.

Use distinct silhouettes and readable colors.

Icons must remain understandable at normal gameplay size.

Avoid ambiguous shapes such as the existing bread icon that resembles a gold bar.

Existing asset reuse

Inspect the repository's licensed pixel-art assets first.

Use existing suitable icons wherever possible.

Only replace or create artwork where the current assets are genuinely inadequate.

Capacity display

Show the category's current usage and capacity.

Examples:

"Tools: 12 / 18"

"Food: 8 / 23"

"Armor: 21 / 27"

A separate total backpack summary may be displayed, but it must not imply a shared capacity restriction.

Locked slots

The bottom row should visibly show:

- Five positions belonging to the first upgrade.
- Four positions belonging to the second upgrade.

Use understandable lock icons or another clear visual indicator.

Do not display a locked position as an available empty slot.

Controls

Support the game's existing:

- Mouse controls.
- Keyboard navigation.
- Controller navigation.
- Touch input.

Maintain readable text and visible focus states.

Do not let tooltips or confirmation panels open outside the visible scroll area.

---

7. TRADING AND PURCHASING INTEGRATION

INV-18-09 — Respect category-specific capacity

The previous axe-purchasing defect revealed two problems:

1. The player could not buy an axe because the shared backpack was full.
2. The purchase confirmation panel appeared outside the visible scroll area.

The Build 18 branch already contains corrections to the purchase confirmation visibility and full-inventory messaging.

Preserve those fixes.

Adapt the inventory capacity checks so a purchased item is validated against its actual category.

Example

The player has:

- Tools: 18 / 18.
- Food: 3 / 18.
- Weapons: 4 / 18.

Purchasing a new tool type should be blocked if no valid stack or slot is available.

Purchasing food should remain possible.

Transaction integrity

Do not charge the player if the purchased item cannot be transferred.

Do not transfer an item without applying the legitimate payment.

Preserve normal merchant stock, ownership, prices, and physical inventory.

Ensure purchase and sale operations remain atomic.

Existing trade interfaces

Inspect all systems that use the shared inventory logic:

- Merchant trading.
- Market stalls.
- Chests.
- Household storage.
- Workshop storage.
- Contract deliveries.
- Player-to-NPC exchanges.
- Other existing item-transfer interfaces.

Apply the new capacity model consistently wherever the player inventory is involved.

Do not automatically expand NPC, merchant, warehouse or household storage capacity. Those systems have their own economic and physical constraints.

---

8. CRAFTING, PRODUCTION AND RESOURCE GATHERING

INV-18-10 — Preserve production integrity

The inventory overhaul must support the existing economic simulation.

When crafting consumes ingredients and produces goods:

- Validate actual ingredient availability.
- Preserve item ownership.
- Consume the correct physical quantities.
- Create only the approved output quantities.
- Assign resulting items to their correct categories.
- Respect capacity rules without destroying outputs or ingredients.

Full output category

If crafting would produce an item the player cannot carry, use the existing legitimate output-handling behavior where applicable.

If no such behavior exists, report the required design decision.

Do not silently delete the output or create unlimited temporary storage.

Gathering and mining

Harvested crops, ore, timber, stone, and other resources must enter the appropriate categories.

Preserve:

- Resource depletion.
- Tool requirements.
- Gathering labor.
- Ownership.
- Theft rules.
- Physical goods conservation.

Inventory organization must not increase yields or generate free goods.

---

9. SAVE FILES AND MIGRATION

INV-18-11 — Save compatibility

This is a structural inventory change.

Inspect the current save format and determine what must change.

Required persistence

Save and restore:

- Every owned item.
- Item quantities.
- Item condition and durability.
- Item ownership.
- Category assignment.
- Equipped items.
- Six equipment slots.
- Inventory upgrade state.
- Other existing item metadata.

Existing saves

Develop a deterministic migration from the old shared 24-slot inventory to the new categorized system.

Every existing item must be preserved exactly once.

Equipped items must migrate to the correct equipment state without consuming backpack capacity.

No item may be lost or duplicated during migration.

Do not assume all existing saves have identical inventory layouts.

Save integrity

Test representative saves with:

- Empty inventories.
- Partially filled inventories.
- Full inventories.
- Equipped weapons and tools.
- Stacked items.
- Different item categories.
- Existing durable or unique items.

Preserve compatibility wherever feasible.

If an old save format cannot be supported safely, report the exact limitation before changing it.

---

10. INVENTORY UPGRADES

INV-18-12 — Two upgrade stages

The architecture must support exactly two capacity expansions beyond the starting inventory.

Starting state

18 slots per category.

Upgrade 1

23 slots per category.

Upgrade 2

27 slots per category.

Persist the upgrade level in the save.

Prevent repeated application of the same upgrade.

Prevent locked positions from being used through crafting, trading, equipment swaps, or direct inventory APIs.

Unresolved economic design

The owner has not yet determined:

- How upgrades are acquired.
- What upgrades cost.
- Whether they require a crafted backpack.
- Whether a merchant sells the upgrade.
- Whether upgrades require materials.
- Whether upgrades require a specific skill.
- Whether upgrades are available immediately or later in progression.

Do not invent these rules.

Implement the underlying capacity progression and present a concise owner decision when necessary.

Do not give the player free access to locked slots by default.

---

11. CONSERVATION AND ECONOMIC INTEGRITY

INV-18-13 — No duplication or loss

The inventory overhaul must preserve the simulation's governing principle:

A VILLAGE IS ALLOWED TO FAIL. THE SIMULATION IS NOT.

The following operations must not create or destroy items improperly:

- Pickup.
- Drop.
- Purchase.
- Sale.
- Trade.
- Equip.
- Unequip.
- Equipment swap.
- Crafting.
- Storage transfer.
- Looting.
- Contract delivery.
- Save and load.
- Migration.

The eight categories are capacity and organization rules.

They are not eight independent sources of goods.

An item must exist in one authoritative ownership location at a time.

Capacity versus weight

Do not invent new weight limits, encumbrance penalties, or hauling-speed reductions.

Preserve any existing physical transport or carrying restrictions.

The owner is explicitly choosing a large inventory to support the complexity of the game's economy.

If that produces a demonstrated balance problem, report it with evidence rather than silently reducing capacity.

---

12. IMPLEMENTATION PLAN

Phase A — Inspect existing systems

Before changing code:

1. Locate the existing 24-slot capacity logic.
2. Identify the inventory's authoritative data structure.
3. Identify the current eight tab definitions.
4. Inspect all item types in the registry.
5. Identify equipment storage and the six body slots.
6. Locate purchase, sale, pickup, crafting and transfer capacity checks.
7. Inspect save-file serialization.
8. Identify reusable inventory and category icon assets.

Report any important architectural conflicts.

Avoid a broad unrelated repository audit.

Phase B — Implement category classification

Assign each existing item exactly one category.

Add focused checks ensuring no registered item is left unclassified.

Use explicit item metadata or an equally deterministic registry mechanism.

Avoid fragile name-based classification where possible.

Phase C — Implement categorized capacity

Replace the shared 24-slot capacity restriction with eight independent capacity pools.

Support 18, 23 and 27 slots per category according to upgrade state.

Preserve existing stack rules.

Phase D — Separate equipment

Ensure the six equipped positions do not consume backpack capacity.

Correct equip, unequip, and swap behavior.

Preserve actual item identity and metadata.

Phase E — Update inventory UI

Display each category's real contents.

Use the 3 × 9 grid.

Implement the two-stage locked bottom row.

Update icons, capacity labels, focus behavior and category navigation.

Phase F — Integrate with existing gameplay

Update capacity and transfer behavior across affected systems.

Preserve the existing Build 18 purchase-dialog fixes.

Phase G — Save migration

Implement and validate migration from existing inventory saves.

Phase H — Focused validation

Use targeted tests for:

- Category assignment.
- Per-category capacity.
- Existing stack behavior.
- Equip and unequip.
- Equipment swaps.
- Pickup and drop.
- Buying and selling.
- Crafting.
- Storage transfers.
- Save and load.
- Old-save migration.
- Item and coin conservation.
- Mouse, keyboard, controller and touch interactions where affected.

Reuse existing passing test evidence when still applicable.

Do not automatically run full simulation campaigns or unrelated suites.

---

13. ACCEPTANCE CRITERIA

The inventory overhaul is ready for owner review when:

1. All eight tabs display separate categorized contents.
2. Every registered item has exactly one valid category.
3. New items automatically enter their correct categories.
4. Each tab displays three rows of nine slots.
5. The top two rows are available immediately.
6. The bottom row begins locked.
7. Upgrade 1 unlocks five additional positions per category.
8. Upgrade 2 unlocks the remaining four positions per category.
9. The maximum backpack capacity is 216 occupied item-type positions.
10. Six equipped items may exist separately from backpack capacity.
11. Equipping and unequipping do not duplicate or destroy items.
12. Category-specific capacity is enforced correctly during trading and gathering.
13. Existing stack rules remain intact.
14. Inventory icons are immediately recognizable, especially the food tab's red berries.
15. Existing save data migrates without item loss.
16. All affected gameplay interfaces remain functional.
17. Item and coin conservation checks pass.
18. Unapproved upgrade prices and acquisition rules are not invented.
19. Frozen Build 17 remains untouched.
20. No build is released without owner approval.

---

14. REQUIRED REPORT TO OWNER

Before substantial implementation, provide a concise report identifying:

- Existing inventory architecture.
- The actual eight category definitions currently in the game.
- Any proposed category adjustments required by the item registry.
- Existing equipment-slot behavior.
- Save migration implications.
- Genuine unresolved design decisions.
- Planned implementation sequence.

After implementation, report:

- Branch and commit.
- Systems changed.
- Item classification coverage.
- Capacity and equipment validation.
- Save migration results.
- Conservation results.
- Remaining limitations.
- Build 18 integration readiness.

Ask owner questions one at a time when decisions are genuinely required.

Do not repeatedly reopen settled decisions.

---

15. RELEASE BOUNDARY AND FINAL OWNER INSTRUCTION

Build 17 is frozen.

All inventory overhaul work belongs in Build 18.

Preserve Build 17's existing release evidence.

Do not restart its validation runs.

Do not modify unrelated simulation mechanics.

Apply MSW-01 throughout.

The inventory must support the game we're building, not constrain the game to the limitations of an early prototype.

Eight categories.

Three rows of nine per category.

Eighteen starting positions per category.

Five more with the first upgrade.

Four more with the second.

Six separate equipment slots.

Automatic categorization.

Recognizable icons.

Reliable trading, crafting, equipment handling and saving.

No duplicated or lost goods.

Build the complete underlying system, not just a larger-looking inventory screen.
