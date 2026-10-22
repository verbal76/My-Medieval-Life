# Owner directive, 2026-10-21: Courier Contract Interface and Pricing Design (extends X18-Q12-BOOTH)

Saved verbatim from the owner's message (CLAUDE.md section 9a).

---

Expansion 18 — Owner-Approved Courier Contract Interface and Pricing Design
Extend X18-Q12-BOOTH with the following owner direction.
The courier contract interface should function similarly to modern online postage, with a structured delivery request and calculated service fee.
1. Contract popup
When negotiating courier services, display a popup containing dropdown selections for:

* Quantity of goods.
* Item being transported.
* Person or business receiving the delivery.
* Delivery location.
* Whether payment should be collected.
* Whether collected money or items should be delivered or deposited.
* Type and amount of money or items involved.
* Regular established route or special negotiated delivery.

The interface should assemble these choices into a readable delivery instruction before confirmation.
2. Intelligent recipient selection
Use the game's existing social, acquaintance, transaction, and business records to populate the recipient dropdowns.
The list should include people the sender knows and businesses the sender knows or has previously dealt with.
Prior commercial transactions must establish usable commercial contacts even when the sender has no personal relationship with the business owner.
For businesses, the owner represents the business publicly. The courier service resolves the business location through existing world records.
Do not generate arbitrary unknown recipients or require the player to manually type addresses.
Apply the same recipient knowledge rules to NPCs.
3. Fee calculation
Calculate the courier fee from the actual delivery requirements, including:

* Established route versus special service.
* Travel distance and expected journey.
* Quantity, weight, or carrying burden of goods.
* Available carrying capacity.
* Delivery and collection stops.
* Required return travel or deposit location.
* Courier labor and service availability.
* Any required legal or notarial service.

Established routes retain their approved flat-rate pricing structure. Special services use negotiated terms informed by the calculated work.
Do not establish arbitrary permanent numerical pricing constants without simulation and owner review.
4. Physical execution
The courier must physically collect the goods, travel to the destination, deliver them, collect payment or other items when instructed, and complete the specified return or deposit.
All goods and money must remain accounted for.
No instant delivery, invented goods, invented currency, or invisible transfers.
5. Validation and tests
Test known contacts, prior business contacts, recipient-location resolution, item availability, cargo capacity, fee calculation, payment collection, deposits, rejected deliveries, unavailable recipients, and interrupted journeys.
Do not mark the contract fulfilled until its required physical and financial obligations have actually been completed.
Keep this work on the isolated Expansion 18 development branch and reconcile it with the completed Build 17 systems before integration.
