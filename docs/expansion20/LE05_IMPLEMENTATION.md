# Expansion 20, LE-05: implementation note and handoff (construction, ecology, mining, bandits, regional links)

Register LE-05 (gate "Integration matrix covered", design s.9, s.17; branch `wip/x20-le05`, from LE-06's `857f9f8`). Rules: behind
`economy.json` `enabled` false (and `market.drive`); deferred systems behind off flags; no unbounded saved state; additive saves
only; the settlement layer (`game/scripts/core/settlement/`, Worker B) is consumed through its interfaces and `World.transactions`,
never edited without telling the lead; anything that changes gameplay outcomes or needs the owner is stopped and reported.
Actions: none until LE-06's run 41143001791 reports; at the LE-05 milestone one local `tools/sim_gate.py` (economy off) and one
`--market` run.

## Status (keep current)

| Part | State | Where |
|---|---|---|
| Travel in a delivered contract's price (design s.5 "travel and risk", deferred from LE-02) | done | `contracts.gd::travel_per_unit`, `price_terms`; INT-612; `le05_test::test_travel` |
| Risk in prices (route danger) | documented gap (section 2): no route-danger measure exists | |
| Rental and repair (OD-LE-08 D07: "model real assets, time, repairs and contracts in phased LE work") | proposal for the lead's review, not implemented | `LE05_RENTAL_REPAIR_PROPOSAL.md` |
| Player's market journal (OD-LE-14 D13; must not break the guest journal network path) | done (section 3) | INT-613; `le05_test::test_market_journal` |
| Construction: bids for materials, hiring (design s.9) | housing material bids exist since LE-02 (need kind `housing`); hiring is LE-04's wages flag (off) | |
| Ecology / mining under existing depletion rules; bandits; regional links via `World.transactions` | not started; regional food trade is Worker B's (X20-SETTLE-FOOD, merged) | |

## 1. Travel in a delivered contract's price

Design s.5: a seller's minimum covers "labor, material cost, household needs, other bids, stock and opportunity cost"; LE-02 left
"no travel cost in pricing ... for LE-05's regional links". `Contracts.price_terms` gains a `travel` term, added to the minimum:
the round trip between the seller's workplace and where the buyer takes delivery (its workplace; the manor's reeve; the player's
home), at walking speed (`walk_tiles_per_second`, `game_minutes_per_second`), valued at the seller's own earnings per working
minute (`NPC.avg_income` over the working day: the measure `alternatives` already uses), over a `delivery_lot`. No new number:
only `market.travel_cost` (on) gates it; the switch off leaves CON-01 exactly as before. A seller who earns nothing values its walk
at nothing. Face-to-face market deals (encounters) carry no travel (nothing is carried).

## 2. Route risk in prices: a documented gap (not invented)

Design s.5 asks buyers to weigh "travel and risk". Read-only search of the settlement and bandit layers (2026-10-30): couriers can
be waylaid (`settlement/couriers.gd`: the load drops as loot), and `Outlaws.band_alive` / `camp_cell` say whether a band is about,
but nothing measures danger on a route (no record of losses or attacks per road, per settlement link or per area). Per the lead's
instruction no measure is invented: route risk is not priced. When the settlement or bandit layer records losses by route (e.g. the
couriers' waylaid loads or caravan losses by road), a risk premium can read it here: the expected loss on the route over a trip,
added to the seller's travel term and the buyer's ceiling. Until then a delivered contract prices travel time only (section 1).

## 3. The player's market journal (OD-LE-14 D13)

When the player talks with a villager (`Relations.talked`) and the market drives, it learns that villager's open offers in person
(OD-LE-02B), and each price new to it, changed or older becomes a "market" line in its Messages journal: "<name> sells plank at 4
each (seen day 1, <place>)". The category is added to the journal's bounded ordinary tier (`message_journal.json`); staleness is the
line's day against today. Nothing else lists offers to a player (no feed). The host's player gets the line through
`World.player_tell`; a guest's is recorded under its reference in the host's world (the `c_journal` record, saved there): no new
network verb, so the guest journal path is unchanged. Known limit: a guest's own journal page shows those lines once its copy next
syncs with the host's saved journal, not at the moment. Not playable while the economy is off, so no wiki page yet (WIKI-01).
