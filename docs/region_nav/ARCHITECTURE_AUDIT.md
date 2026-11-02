# Regional economy and world navigation: architecture and gap audit (REGION-NAV-01, Phase 1)

- **Owner directive:** `docs/directives/2026-11-02_regional_economy_navigation_envoys_master.md`, on `wip/requirements-control`.
- **Code audited:** branch `wip/region-nav`, created from the frozen Build 25 candidate `4b51c92`. The candidate itself is not
  changed.
- **Method:** module headers and execution paths were traced in the code, not inferred from names.

**Classification key:**
- **IV**: implemented and verified;
- **ID**: implemented but disconnected;
- **P**: partially implemented;
- **M**: missing;
- **D**: defective.

## Why the player never meets another village

**It is by design, and recorded.**
- The playable world is the village rectangle, (0,0)-(119,89), plus an endless overworld of meadows, forests, hills and roads
  generated from the seed (`game/scripts/core/overworld.gd`).
- The five neighbouring settlements (Wulstead, Netherton, Garton, Higham-on-the-Way and Bourton Abbas;
  `game/data/settlements.json`) exist only as **off-map** economic simulations. Each is stepped once a day
  (`settlement/offmap.gd`, which says "stepped once a day without walking anyone").
- They have no coordinates in the overworld: only `miles` (20-72) at `tiles_per_mile` 12, which is 240-864 tiles.
- The countryside module says it plainly (`countryside.gd`): "Other towns stay off the map".
- Owner decisions behind this:
  - **Q18-8** (2026-10-23, `docs/directives/2026-10-23_owner_answers_q18_4_q18_8.md`): "visiting the other settlements in person
    stays at Build 20 or later", answered "Keep it for 20+".
  - The countryside answer of the same day: "other towns stay off-map for now".
- **DCR-01 classification:** this directive is the intentional revision those decisions anticipated (in-person visits, "20+").
  It is not a conflict.

## System audit

| # | System | Class | Evidence and execution path |
|---|---|---|---|
| 1 | World generation, multiple villages | **M** (other villages), **IV** (the overworld) | `overworld.gd`: deterministic chunks, a global road network joined to the village's four exits (`VillageMap.exits`). No settlement is placed in it. Settlements: `settlements.json` (id, name, kind, miles; no direction or position). |
| 2 | Coordinates, distances, roads, terrain | **P** | Overworld terrain and roads are real tiles. Settlement distance is abstract miles only. `settlement/routes.gd` has a deterministic grid Dijkstra (`grid_route`) usable on the overworld, but it is PROSPECTIVE, and live trade uses `abstract_route`. |
| 3 | Player movement between settlements | **P** | The player walks the overworld freely, with world collision (`World.solid_for_player`). Route-finding outside the village is a local A* capped at 140 cells (`VillageMap.find_path_world`, `WORLD_PATH_CELLS`). There is nothing to walk to. |
| 4 | NPC travel and pathfinding | **M** outside the village | Villagers path only on the village grid (`VillageMap.find_path`, A* region (0,0,w,h); `NPCBrain` 3419, `World` 681). Countryside travellers are ambient drawings: "cannot be talked to", no ledger (`countryside.gd`). The caravan, migration and couriers cross the map edge abstractly. |
| 5 | Local and world map | **IV** (local), **M** (world) | `ui/village_map_view.gd` (VillageMapPanel): the village drawn one pixel a tile, named places, home, the player and tap-to-look. There is no world or regional map. |
| 6 | Village discovery, exploration memory | **M** | `discovery.gd` is mining-deposit discovery (MIN-D). No explored-area or known-settlement record exists for the player. Couriers keep `contacts`: a villager who traded with a settlement's trader may then address it (`couriers.gd` 72, 413). This is the only existing settlement knowledge. |
| 7 | Independent settlement populations and economies | **IV** (aggregate) | `offmap.gd`: households with purses and pantries, businesses with tills, stock and workers, a treasury, tax, a market price band, births, deaths and migration. Conservation is audited (`OffMapSettlement.audit`, `Regions.audit`). Households are **counts** (adults, children), not individual people. |
| 8 | Businesses, professions, inventories, production | **IV** (village), **P** (settlements) | Village: named NPCs with jobs, skills, stations, workshops and ventures. Settlements: 12 business types with real recipes, but **no named owner or keeper**. An envoy cannot today interview "Smith B of Higham", only the smith business's books. |
| 9 | Local and regional demand | **P** | Local: `NPCBrain.skilled_place` (station busy-ness), `Contracts.npc_orders`. Regional: `settlement/regional.gd` RegionalMarket, PROSPECTIVE, called "a STAND-IN for the negotiated contracts", plus `Regions` wholesale rounds between the settlements' traders. The village's demand reaches the region only through the caravan. |
| 10 | Merchant travel, buying, selling, contracts | **IV** (caravan, couriers), **ID** (contracts) | The caravan is the settlements' traders, with real coins and stock (`NPCBrain.caravan` 5259, `Regions`). Couriers are live (`CourierService.create_live`): booths, regular routes and special deliveries, booked in both ledgers. CON-01 contracts never take a settlement party: no `region:` reference in `contracts.gd`. A business lacking an input offers it to the player (`Contracts.offer_to_player`), not to a settlement. |
| 11 | Mayor, leadership, succession, task scheduling | **P** | No mayor: P21-MAYOR is NOT STARTED and needs owner decisions. Offices that act: the **reeve** (manor work, the job board, wages and treasury; `manor_work.gd`), the guards and the sage. `civic/civic_offices.gd` (P21-01) names offices "DESCRIPTIVE... grants no power". Succession of jobs: `NPCBrain.succession_dawn`. |
| 12 | NPC communication, memory, information sharing | **IV** (local) | Judgment memories and gossip (`JudgmentStore._tell`, `World.witness`), relations, and acquaintance records. Information travels person to person within the village. None of it carries market information. |
| 13 | Business founding and the 35 % utilisation gate | **IV** (works as written) | `Ventures.refusal`; `skilled_places.busy_share` 0.35 over `window_days` 5. It measures only local station busy-ness, so external demand cannot raise it today. See B25-ECON-P1..P5 (`BUSINESS_FOUNDING_DECISIONS_AND_PHONE_TEST.md`). |
| 14 | Save and determinism | **IV** | Settlements are saved under the optional key `regions`; couriers under `couriers`; the overworld comes from the seed plus saved changes. A random-state save key (B25). Deterministic by construction (no global random, ordered iteration). |
| 15 | Long-run coverage, performance | **IV** (aggregate) | `economy_sim` and the flight recorder audit currency and items, including the settlements' flows. Measured: about 3.67 ms of simulation at 500 villagers on desktop (`LE00_ARCHITECTURE_AUDIT.md`). No regional travel exists to measure. |

## Gaps against the directive

**Physical presence**
1. **Physical settlements.** None exists in the playable world (1, 2, 6). This is the root of everything else.
2. **Individuals in other villages.** The envoy must interview named owners and crafters, but settlement businesses have none
   (7, 8).

**Travel, knowledge and maps**

3. **NPC long-distance travel.** No villager can walk the overworld (4). The player's router is capped at 140 cells; the
   settlements lie 240-864 tiles away.
4. **World map, discovery and knowledge persistence.** All missing (5, 6).

**Leadership and envoys**

5. **Leadership.** No mayor exists. The reeve is the acting leadership in code (11).
6. **Envoy role and survey records with provenance.** Missing. The nearest existing parts are the courier service's contacts
   and the caravan's trader meetings.

**Trade and demand**

7. **Economic information to the relevant villagers, with age.** Missing (12 carries no market facts).
8. **Contracts with distant parties.** CON-01 offers and couriers exist, but a villager never chooses a settlement party (10).
9. **Regional demand in business decisions.** Not connected: the founding gate is local only (13).

## What can be reused (no second framework)

- **Overworld:** chunks, roads and terrain for placement, the map and travel. `TradeRoutes.grid_route` (deterministic Dijkstra)
  over `overworld_classifier` serves long routes, at road-node granularity rather than per tile.
- **Settlements:** `OffMapSettlement` and `SettlementParty` remain the economic books, with the same conservation and audits.
  Every sale and contract settles through `SettlementParty.deal`.
- **Contracts:** CON-01 contracts (item, quantity, unit price, terms, accept or counter) are the negotiation. The courier
  service is the carriage, at its existing fees. A villager travelling in person ("self") is RegionalMarket's existing buyer
  mode.
- **People and jobs:** the job market and `succession_dawn` fill an envoy post; `manor_work` and the reeve pay and schedule it;
  `JudgmentStore._tell` spreads the report from person to person.
- **Saves:** optional save keys, with no version change, as `regions` and `couriers` already do.

## Dependencies (order of work)

The order below is the one owner decision **A** gives; topology settles everything after it.

1. **Topology (owner decision):** where and how the five settlements stand in the overworld.
2. Then a **known-places record** (player and NPC) and the **world map** (needs 1).
3. Then **NPC long-distance travel** along the road network (needs 1).
4. Then **the people of a settlement**, materialised from its books when someone is there (needs 1).
5. Then **the envoy post and survey records** (needs 3, 4 and the leadership answer).
6. Then **information delivery and NPC trade decisions over CON-01 and couriers** (needs 5).
7. Then **regional demand in skilled_place and founding** (needs 6, and the owner's B25-ECON-P answers where they apply).
8. Measurements and tests are added at each stage. Year-long runs only with the owner's authorization.
