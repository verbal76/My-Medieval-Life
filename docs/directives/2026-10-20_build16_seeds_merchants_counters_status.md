# Owner directive, 2026-10-20: Build 16 seeds, farming, merchants, sales counters (sections 1-8) and the status audit (section 9)

Saved verbatim. Section 9 arrived first, alone; sections 1-8 followed when the agent reported them missing. Register:
SEED-01..04, MERCH-01, ARM-01, CTR-01..03, SHOP-01, TRADE-01, CTR-04 (sections 1-8); B16-AUDIT (section 9).

---

MY MEDIEVAL LIFE — BUILD 16
Missing Sections 1–8: Seeds, Farming, Merchants, and Sales Counters
You are correct. I accidentally sent Section 9 without the preceding sections.
The following are the missing requirements. Append them to the existing Build 16 directives and include them in your status audit.
Do not discard or duplicate existing tracked items.
1. Seeds and Plant Propagation
Audit whether a complete seed planting system currently exists.
Farming must support acquiring, storing, planting, growing, and harvesting crops using actual seeds.
Include agricultural crops, fruit trees, berry bushes, and flowers.
Harvesting should provide an appropriate chance of recovering viable seeds or propagation materials.
Use suitable propagation methods for each plant type, including seeds, cuttings, or saplings where appropriate.
Planting must consume actual inventory.
Perennial plants should survive harvesting and produce again under appropriate conditions.
Growth must respect the existing eight-day calendar year and seasonal mechanics.
Preserve deterministic randomness and resource conservation.
2. Village Seed Merchant
Provide a village merchant or booth where players and NPCs can purchase crop seeds, flower seeds, berry propagation materials, and fruit-tree seeds or saplings.
Use actual inventory, actual coins, and legitimate restocking.
Do not create unlimited stock or free goods.
Households may also save planting materials from their own harvests.
3. Armorer Availability
During my previous playtest, the armorer was never available when I wanted to purchase goods.
Investigate whether this problem has been corrected.
Verify the armorer's existence, schedule, location, inventory, pathfinding, and player trading interaction.
Report whether the problem is fixed, still present, or not yet verified.
Do not assume it has been resolved.
4. Skilled-Trade Sales Counters
Every appropriate established skilled-trade business must have a functional customer counter.
This includes armorers, blacksmiths, carpenters, and other skilled businesses as they develop.
When the player approaches a counter, display an interaction prompt consistent with the existing conversation system.
Press A to interact.
The appropriate available shopkeeper should come to the counter through normal navigation.
The player should not have to search the village for a shopkeeper simply to purchase goods.
5. Shopkeeper Availability
Shopkeepers remain ordinary villagers with schedules, needs, and responsibilities.
They do not need to stand behind counters all day.
When summoned, an available shopkeeper should approach and serve the customer.
If unavailable, communicate that clearly.
Do not teleport NPCs, interrupt emergencies, or create duplicate customer-service tasks.
Where appropriate, authorized employees or family members may serve customers.
6. Buying and Selling
Skilled businesses sell goods they actually produce or stock.
They may purchase useful goods from players or NPCs when they have genuine production needs and sufficient funds.
For example, a carpenter might purchase timber, while an armorer might purchase relevant crafting materials.
Buying interest must depend on actual inventory, production needs, available money, and market conditions.
No infinite merchant funds, guaranteed demand, or duplicated goods.
Player and NPC transactions must use the same underlying economic mechanics.
7. Permanent Shops Versus Market Stalls
Distinguish permanent skilled-trade counters from the separately approved market-stall system.
Permanent counters serve established businesses.
Market stalls follow OD-24, including unattended operation and the realm's 5% commission on completed sales.
Do not automatically apply stall commissions to permanent business counters without an approved rule.
8. Integration and Testing
Integrate these requirements with the existing household pantry, farming, land leasing, construction, trade, and economic simulation systems.
Add appropriate regression coverage for:

* Seed consumption and recovery.
* Fruit trees and berry bushes.
* Seasonal growth.
* Merchant inventory and purchases.
* Armorer availability.
* Counter interactions.
* Shopkeeper navigation and availability.
* Trade-specific purchasing.
* Coin and inventory conservation.
* Player/NPC parity.
* Deterministic simulation.

Finish the existing pantry starvation comparisons before introducing changes that would invalidate their baseline.
Commit and push verified work to staging.
Do not merge or publish a release without owner authorization.
Continue Section 9
Now incorporate these requirements into the complete Build 16 audit you are already preparing.
Identify their implementation status, remaining work, dependencies, and impact on Build 16 completion.
Do not pause approved development solely to prepare the report.
Important: The fact that Build 16 now has 84 tracked items does not mean every new idea must delay the next playable build. Report which items are essential for stabilization and which could be completed in a later milestone, but do not defer approved work without my authorization.

---

## Section 9 (sent first, 2026-10-20)

Recorded as register B16-AUDIT; its full wording is in the owner's message of 2026-10-20 ("9. BUILD 16 — COMPLETE STATUS
AUDIT AND REMAINING WORK"), whose requirements are restated in `docs/BUILD_16_STATUS.md`'s opening.
