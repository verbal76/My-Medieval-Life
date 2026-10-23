MY MEDIEVAL LIFE — BUILD 18 OWNER DECISIONS

Inventory Categories, Backpack Progression, Tailor Shop and Armor Scope

These are the owner's consolidated answers to INV-Q1, INV-Q2 and the outstanding armor-scope discussion.

Record the decisions and reconcile them with the active Build 18 inventory implementation.

IMPORTANT: The inventory worker is already active. Update its requirements rather than starting a duplicate worker or rebuilding completed work unnecessarily.

Build 17 remains frozen and untouched.

1. INV-Q1 — ITEM CATEGORY CLASSIFICATION

Approve the eight-category inventory architecture.

The six previously identified borderline item groups are classified as follows:

Item| Approved category
Rings and amulets| Crafted Goods and Valuables
Wheat grain| Raw Materials
Raw meat| Food and Drink
Seeds, saplings and cuttings| Raw Materials
Herbal tonic| Medicine and Consumables
Lockpicks and padlocks| Tools

These classifications are authoritative unless a demonstrated conflict requires another owner decision.

Every registered item must have exactly one category.

Preserve the eight recognizable category icons, including red berries for Food and Drink.

Do not use ambiguous icons that resemble unrelated objects.

2. INV-Q2 — REVISED INVENTORY CAPACITY

The owner is changing the previously specified upgrade progression.

SUPERSEDED:

- 18 starting slots per category.
- First upgrade adds five slots.
- Second upgrade adds four slots.

NEW APPROVED DESIGN:

Each of the eight inventory categories has a grid of three rows and nine columns.

Starting inventory

Only the FIRST ROW is unlocked.

9 available positions per category.

8 categories × 9 positions = 72 starting backpack positions.

The second and third rows are visibly locked.

First upgrade

Unlock the ENTIRE SECOND ROW across ALL EIGHT CATEGORIES.

18 available positions per category.

8 categories × 18 positions = 144 backpack positions.

Second upgrade

Unlock the ENTIRE THIRD ROW across ALL EIGHT CATEGORIES.

27 available positions per category.

8 categories × 27 positions = 216 backpack positions.

Equipment

The six equipment slots remain separate from backpack capacity.

Fully upgraded capacity:

216 backpack positions + 6 equipped positions = 222 total occupied positions.

Existing stacking rules remain unchanged.

Do not introduce arbitrary stack limits or weight restrictions.

Each upgrade applies globally to all eight inventory categories.

There are only two upgrade purchases, not sixteen separate category upgrades.

Persist upgrade ownership and capacity state in saves.

Do not allow upgrades to be purchased repeatedly.

3. NEW TAILOR SHOP — TAILOR-18

The owner approves introducing a tailor shop as the in-world seller of backpack upgrades.

The tailor is also the intended place for clothing changes, consistent with the planned character customization system.

However, the initial minimum scope is intentionally narrow.

Minimum initial functionality

A tailor exists in the village as a real NPC service provider.

The player can visit the tailor and purchase backpack capacity upgrades.

The tailor does not need a complete clothing manufacturing system, wardrobe economy or garment-production chain to make these upgrades available.

For the initial implementation, selling backpack upgrades is sufficient.

Do not block the upgrade shop waiting for the complete character customization or clothing systems.

Future clothing functionality

The tailor is the logical location for clothing changes and future clothing-related services.

Keep that future integration possible without inventing clothing production, inventory, or service rules now.

The barber remains a separate planned service for hairstyles.

The tailor handles clothing and backpack upgrades.

The armorer handles armor.

Do not merge these professions into one generic customization vendor.

4. BACKPACK UPGRADE PRICES

The owner wants meaningful economic progression.

Initial target prices:

- First upgrade: approximately 150 coins.
- Second upgrade: approximately 450 coins.

Total target investment: approximately 600 coins.

These prices are provisional balancing targets, not permission to invent unrelated economic mechanics.

Review the existing village economy, starting wealth, actual player earning opportunities and legitimate purchase prices.

Use existing economic evidence rather than running another large simulation campaign.

The first upgrade should require some effort but be attainable relatively early through normal gameplay.

The second upgrade should represent a more substantial investment.

If 150 and 450 coins are consistent with those goals, use them.

If evidence indicates a meaningful mismatch, present a concise alternative with the reason before changing the amounts.

Economic integrity

Upgrade purchases must deduct the appropriate coins from the player.

The payment must enter the legitimate economic system rather than disappearing without explanation.

Use the existing service/payment and ownership architecture wherever possible.

Do not create free coins or goods.

Do not invent a physical backpack manufacturing supply chain as part of this minimum implementation.

Do not grant upgrades without payment.

The tailor should not need to carry eight separate copies of the same upgrade item if the existing architecture supports legitimate service purchases.

Use the simplest existing economic mechanism that preserves money conservation and NPC agency.

5. TAILOR AVAILABILITY

The player must have a legitimate opportunity to purchase the upgrades.

Inspect existing settlement generation, profession assignment, building placement and NPC service systems.

Determine the smallest appropriate integration that makes a tailor available.

Do not invent a large new production profession or restructure village generation unnecessarily.

If introducing a new tailor NPC or shop requires displacing an existing worker, adding a building, or changing settlement economic balance, report the consequences and choose the least disruptive approved-compatible solution.

Avoid introducing a free-floating menu vendor disconnected from the village.

The tailor should exist in the world.

6. INVENTORY MIGRATION AND EQUIPMENT

Preserve the previously approved eight-category inventory design.

Items automatically enter the appropriate category when collected, purchased, crafted or transferred.

Equipped items occupy their six equipment slots and do not consume backpack capacity.

Equip, unequip and swap operations must preserve ownership, durability and item quantities.

If the relevant category is full, block an unsafe unequip or transfer rather than destroying or duplicating the item.

Existing save compatibility

Old saves may contain more item types in a category than the new starting capacity allows.

Preserve every existing item.

Allow the affected category to temporarily display over capacity, such as 12 / 9.

Do not accept additional new item types into an over-capacity category until sufficient room becomes available.

Do not delete possessions to enforce the new limits.

Preserve equipment and existing item metadata during migration.

7. ARMOR SCOPE — OWNER DIRECTION

The owner continues to approve the intended armor system:

- Players begin as ordinary villagers without armor.
- Armor must be acquired legitimately through gameplay.
- Existing armor sprite sheets should supply the visual appearances.
- Armor should eventually support distinct classes, protection values, durability, rarity, pricing and equipment behavior.
- Equipped armor should visibly change the player character.
- Armor availability should respect actual inventory, ownership and the village economy.

However, the report refers to an armor "Option A" without restating its exact scope.

Do not interpret this directive as approval of an undefined implementation option.

Present the precise wording and implications of Option A before implementing any additional armor mechanics requiring owner approval.

Do not invent armor statistics, rarity tiers, production recipes or combat balance.

Continue already approved, independent work where appropriate.

8. IMPLEMENTATION COORDINATION

The inventory worker is already working on Build 18.

Provide the worker with these revised requirements.

Do not discard completed implementation unnecessarily.

Adjust the capacity model to:

9 → 18 → 27 slots per category.

Replace any earlier 18 → 23 → 27 progression logic.

Preserve completed item categorization, equipment separation, trading integration, save migration and interface improvements where compatible.

Coordinate tailor integration with the existing Build 18 world and service systems.

Avoid overlapping workers editing the same inventory or NPC files.

9. VALIDATION

Apply MSW-01: Minimum Sufficient Work.

Reuse passing tests where the underlying code remains unchanged.

Focus new validation on:

- Eight independent inventory categories.
- 9, 18 and 27 positions per category.
- Global upgrades across all eight categories.
- Locked rows.
- Category classification.
- Equipment separation.
- Buying both upgrades from the tailor.
- Correct coin transfer.
- Preventing duplicate purchases.
- Save and load of upgrade state.
- Migration of existing saves.
- Over-capacity preservation.
- Trading, crafting and pickup capacity checks.
- Item and coin conservation.
- Existing mouse, keyboard, controller and touch functionality where affected.

Do not automatically rerun unrelated 365-day simulation campaigns.

10. REQUIRED REPORT

Report back with:

1. Confirmation that INV-Q1 and the revised INV-Q2 are recorded.
2. Inventory worker's updated scope.
3. The proposed tailor implementation using existing game systems.
4. Whether the 150/450-coin prices are reasonable against current earning rates.
5. Any genuine dependencies or blockers.
6. The exact armor Option A proposal still awaiting approval.
7. Relevant implementation commits and focused test evidence.

Do not request decisions already answered.

Do not modify frozen Build 17.

Do not publish or release Build 18 without owner authorization.

FINAL OWNER INTENT:

The inventory should start modestly but grow into a large, well-organized storage system appropriate for a complex medieval economic simulation.

Eight categories.

Nine starting slots each.

One full row unlocked per upgrade.

Six independent equipment slots.

A real tailor shop selling meaningful backpack upgrades.

Clothing customization belongs at the tailor.

Hair customization belongs at the barber.

Armor is acquired through the actual economy.

Preserve simulation integrity, reuse existing systems, and avoid unnecessary development overhead.
