# Owner decisions, 2026-10-20: OD-22, OD-23, OD-24 (family farming, farmland leases, market stalls)

Saved verbatim. The owner's answers to the questions raised in `docs/design/FOOD_SECURITY_AUDIT.md` section 8. Register:
OD-22, OD-23, OD-24 (answered) and their implementation entries FARM-01..07 and STALL-01..06.

---

MY MEDIEVAL LIFE — OWNER DECISIONS OD-22, OD-23, OD-24
These are my decisions regarding farming, land leasing, and market stalls. Record them in the design decision register and incorporate them into the existing simulation architecture.
These decisions apply to both the player and NPC villagers. Maintain player/NPC mechanical parity, real resource accounting, and the existing economic simulation principles.
OD-22 — Family Farming and Land Development
Families must be able to establish and operate their own small farms, even if farming is not their primary occupation.
Farming should be a genuine option for household food security, surplus production, and income.
Establishing farmland

1. A player or NPC household identifies a suitable plot of available land.
2. The household must lease the land from the realm, using the same general land-acquisition system used when building a house.
3. The farmland lease costs 2 coins, compared with the existing 6-coin house lease.
4. The household selects the plot using the existing green-square placement system.
5. Any trees or other obstructions must be cleared before the land can be developed.
6. The household must supply the materials needed to construct a fence and gate around the plot.
7. The required construction materials are logs and stone, deducted from actual available inventory.
8. The household constructs the fenced farmland using the normal construction and labor mechanics.
9. Once the land is prepared, the household must plow it.
10. The household must then plant crops using actual seeds and the established agricultural mechanics.

Do not generate a completed farm instantly when the lease is paid.
The lease grants permission to develop the land. Clearing, construction, plowing, planting, tending, and harvesting remain real activities.
Household participation
Family members should be able to contribute labor according to their age, ability, skills, available time, and other responsibilities.
A household may farm primarily to feed itself, sell surplus crops, or pursue a longer-term economic goal.
Do not require a villager to have the formal occupation of farmer before they can grow food.
Do not force every family to become a farmer. The decision should emerge from its circumstances, needs, skills, preferences, opportunities, and available resources.
The player must have access to the same farming mechanics and requirements.
OD-23 — Manor Land and Farmland Lease Economics
Use the 2-coin farmland lease as the established price for a small household plot.
The 6-coin house lease remains unchanged.
The lease payment must transfer actual coins from the household or player to the appropriate realm/manor treasury. Do not create or destroy coins during the transaction.
The land must be registered as leased or occupied so another household cannot simultaneously claim the same plot.
Use the existing land-leasing framework wherever possible rather than creating a separate, incompatible system.
For manor-operated farmland, preserve the same physical resource and labor accounting. Manor farms should not receive free construction materials, crops, seeds, or labor.
If the existing lease framework distinguishes an initial payment from recurring rent, preserve that distinction and identify any remaining ambiguity before introducing new recurring charges. Do not invent an additional rental interval without authorization.
OD-24 — Player and NPC Market Stalls
Market stalls operate under a percentage-of-sales lease, not a fixed rental charge.
The realm receives 5% of the total value of goods actually sold while the stall is open.
There is no charge based on the value of unsold inventory.
Building a stall
A player or NPC must:

1. Find suitable available land.
2. Clear trees and obstructions.
3. Agree to the realm's 5% sales-based stall lease.
4. Place the stall using the existing green-square construction placement system.
5. Supply the actual building materials.
6. Construct the stall through the normal construction system.

Use the existing construction-material definitions for stalls where possible. Do not invent free materials or instant construction.
Operating a stall
The process should be straightforward:

1. Place the goods intended for sale into the stall inventory.
2. Set or use the appropriate selling prices.
3. Select OPEN STALL.
4. The stall begins selling its inventory through the existing customer and market systems.
5. The owner is free to walk away and perform other activities. They do not need to stand beside the stall.
6. Sales continue while the stall is open and eligible customers actually purchase goods.
7. When the stall runs out of saleable inventory, it automatically closes.
8. The owner receives a notification that the stall has closed.
9. The realm collects its 5% commission from the value of goods sold during that open session.

Manual closure
The owner may select CLOSE STALL at any time.
When manually closed:

* Sales stop.
* Unsold goods remain accounted for in the stall inventory.
* The session's sales are totaled.
* The realm collects its 5% commission on actual completed sales.
* The owner retains the remaining proceeds.
* The stall may be restocked and reopened later.

For example, if a stall sells 100 coins worth of goods, the realm receives 5 coins and the seller receives 95 coins.
The commission must be transferred through the actual coin economy. No fictional revenue, free purchases, or money creation.
NPC stall behavior
NPC households should be able to construct, stock, open, close, and restock stalls using the same mechanics as the player.
They should make reasonable decisions about selling surplus based on household needs, inventory, market demand, prices, financial goals, and other obligations.
An NPC should not sell the last of its family's necessary food without evaluating the consequences, but the reserve should remain a decision-making consideration rather than an absolute prohibition.
Do not require an NPC to remain physically at its stall while the stall is open.
Do not simulate guaranteed sales. Purchases must arise from legitimate buyers with actual needs, funds, and access to the market.
Shared Economic and Simulation Requirements

* Player and NPC households use the same underlying land, construction, inventory, farming, and market mechanics.
* Physical resources must be acquired, transported, consumed, and accounted for.
* Land ownership and leasing must be tracked consistently.
* Goods cannot be sold twice or remain in two inventories simultaneously.
* Stall proceeds and realm commissions must balance.
* Family farming must integrate with the new shared household pantry.
* Seeded simulation behavior must remain deterministic.
* Avoid arbitrary subsidies, hidden rescues, guaranteed customers, or forced economic equilibrium.
* Use existing systems and interfaces wherever practical.

Implementation and Testing
Record these three owner decisions as approved.
First, complete and report the currently running household-pantry starvation comparisons so the baseline remains meaningful.
Then integrate these decisions into the implementation plan.
Build and test the systems incrementally, with coverage for land availability, leasing, construction, farming, stall inventory, unattended selling, automatic closure, manual closure, commission collection, and resource conservation.
Continue approved development autonomously.
Commit and push verified changes to the appropriate staging branch.
Do not merge, create a release, or publish a build without explicit owner authorization.
Report any remaining genuinely unresolved design decisions separately rather than silently inventing new economic rules.
