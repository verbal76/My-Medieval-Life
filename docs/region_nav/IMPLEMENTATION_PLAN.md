# Regional economy and world navigation: implementation plan (REGION-NAV-01, Build 25 scope)

**Owner authority**
- `2026-11-02_regional_economy_navigation_envoys_master.md`: the behaviour.
- `2026-11-02_build25_scope_correction_regional_economy.md`: the scope. This is mandatory Build 25 work; the `4b51c92` freeze is
  superseded.

Both files are in `docs/directives/` on `wip/requirements-control`. Audit: `ARCHITECTURE_AUDIT.md` (this folder).

**Branching (BRANCH-POL-01).**
- Development happens on `wip/region-nav`, from `4b51c92`.
- Each validated stage is merged into the integration branch `wip/expansion20` once the two running campaigns (41536805310 and
  41536810831, on `4b51c92`) have finished. `4b51c92` stays as the tested baseline.

## Architecture decisions

These are agent decisions, made within the directive and recorded in `docs/DECISIONS.md` as each one lands. None changes an
approved rule; the continuity notes cite DCR-01.

**AD-1. Settlements are physical places in the overworld at their recorded distance.**
- **Where each one goes:**
  - Each of the five settlements is placed at `miles × tiles_per_mile` from the village: 240-864 tiles.
  - It sits on the overworld road node nearest that point, so the existing global road network reaches it.
  - Wulstead lies on the road **south** (CANON: "the road south ... through Wulstead", `docs/expansion18/SETTLEMENTS.md`). The
    other four bearings are **GAME EXPANSION**: fixed in `settlements.json` by sector, so the settlements spread around the
    compass and never overlap.
- **What a place is:** a cleared site with a market square and one building for each of its businesses, drawn with the
  existing building art.
- **Generation:** the overworld becomes generation 3. Saves of generations 1 and 2 still load (`GEN_COMPATIBLE`); only the
  site areas change, and the saved changes (felled trees, works) inside a site are dropped and counted.
- **Rejected alternatives:**
  - Keep the settlements off-map. That contradicts the directive.
  - Run each settlement as a full second village, a World with walking villagers. That is about six times the simulation work
    on an Android phone, against the OD-LE-15 target of about 4 ms a frame at 500 villagers, and it would duplicate the
    settlement economy that is already audited.

**AD-2. One economy per settlement: the existing books, with named people.**
- `OffMapSettlement` and `SettlementParty` stay the settlement's economy, stepped daily, with the same conservation and audits.
- **Named people:** each business gets a named **keeper**, and each household with a trade an **independent crafter** where its
  books show one. These are persistent people, derived deterministically from the settlement's households and saved, with
  name, business, household, home building and a spot.
- **Physical presence:** when an observer (the player or a travelling villager) is within the site, the keepers stand at their
  workplaces by a day schedule (at work, at home, absent on market day). They can be met, interviewed and traded with.
- **Every exchange** goes through `SettlementParty.deal`, so no second set of books exists.
- **Rejected:** a village-wide inventory lookup. The owner forbids it.

**AD-3. Leadership: the reeve.**
- The game has no mayor. P21-MAYOR is not authorized; elections are owner decisions not yet made.
- The reeve is the village's acting leadership in code: manor work, the job board, the treasury's spending.
- The directive's "mayor or current legitimate village leadership" is therefore **the reeve**. When an elected office exists,
  that office takes the role.
- **Envoy posts:** a manor post, filled through the existing labour market and succession, and paid the manor's day wage from
  the treasury (`manor_work`). No new money.

**AD-4. Villagers travel the overworld on foot.**
- **Route:** Dijkstra over the road-node graph (a deterministic tie order, as in `TradeRoutes.grid_route`), then from node to
  node with the existing world collision.
- **Speed:** the villagers' walking speed.
- **Unobserved stretches:** a traveller off screen advances along the route at that speed. The same sum gives the same day of
  arrival, so behaviour stays deterministic.
- **Failure:** a blocked route (no path between nodes) fails the journey, which is recorded, and the traveller turns home.
- **Rest:** a traveller sleeps along the road by the KI-HOME-DOOR homeless rest rule.
- No fast travel and no teleport, for villagers or the player.

**AD-5. Economic knowledge with its source.**
- An `intel` record: `{about: party ref and person, place, item, have or want, quantity, unit price, kind (confirmed,
  estimate, refused, absent), told_by, collected_day, heard_day}`.
- Where it is kept:
  - the **envoy** carries their own records;
  - on return they are told to the **reeve** (the reeve's book);
  - the envoy then surveys the home village and tells each tradesperson the records that match that person's own needs and
    surplus;
  - other villagers hear by the existing word-of-mouth rules (`JudgmentStore._tell`), and each retelling keeps the original
    collected day.
- Records age by days since collection and are never treated as still true beyond `stale_days`.
- **Interviews:** a keeper who is absent or unwilling (judgment dislike) is recorded as absent or refused, never as surveyed.

**AD-6. Trade is the tradesperson's own decision, through CON-01.**
- **The decision:** a villager with a need (stations short of inputs, `npc_orders`) and a matching, fresh intel record weighs
  four things:
  - the reported price plus carriage (the courier's fee or their own journey's days of lost work);
  - against the local price;
  - their own funds;
  - the gain.
  This is the same pattern of judgment weighing used elsewhere.
- **Acting:** they either send a CON-01 offer through the courier service to the keeper's party, or travel in person.
- **The keeper side:** accepts, counters or refuses from the books (sale cap, reserve, price band).
- **Delivery:** the courier's carriage, booked in both ledgers, or the buyer's own cart. Goods are in transit for the route's
  days. If the goods were sold before the offer arrives, the keeper refuses and the record is marked out of date.
- **The envoy creates no contract.**

**AD-7. Regional demand reaches business founding only through real work.**
- The 35 % gate stays as it is.
- Accepted export contracts become real station work, so they raise the measured busy share.
- The measurement covers busy share before and after trade becomes available, and foundings with their cause.
- No change to the threshold.

**AD-8. World map.**
- A toggle in the existing map window: **Village | Region**.
- What it draws:
  - the region from the overworld's own classification (forest, rock, mountain, water, road), sampled coarsely;
  - the player's explored chunks (a saved bitset);
  - known settlements, discovered by entering a site or by being told by someone who knows it;
  - the player and home.
- Unexplored ground is drawn blank. Knowing where a settlement is reveals no economic facts.

## Stages (each one: code, focused tests, wiki and manifest, records, pushed)

| Stage | Delivers | Tests |
|---|---|---|
| **S1** | Settlement placement (AD-1, generation 3) and cleared sites; the player's known-places and explored-chunks records (saved); discovery by entering a site; the world map toggle (AD-8) | Same seed gives same sites; every site reachable from a village exit over the road graph; old-generation saves load; discovery is saved; the map draws only known things |
| **S2** | Settlement people (AD-2): keepers and crafters, their schedule and presence on site; the player can meet them, see what they sell and buy, and trade through `SettlementParty.deal` | Conservation (village and region audits); a keeper is absent off schedule; save and load |
| **S3** | Villager long-distance travel (AD-4) | Route found; arrival day deterministic; a blocked route fails and returns; death or save mid-journey conserves what is carried |
| **S4** | The envoy post (AD-3): assignment by the reeve (age of information, distance, availability, undiscovered places), the journey, interviews of every accessible keeper and crafter, return, report to the reeve, home survey | Each interview reads that person's real books; refused or absent recorded; nothing known at home before the return; succession of the reeve or the envoy mid-mission |
| **S5** | The intel network (AD-5): the reeve's book, telling tradespeople, word of mouth, ageing | Knowledge only through a teller; staleness |
| **S6** | Independent trade (AD-6) over CON-01 and couriers; in-person purchase | No forced trade; refusal; goods sold before arrival; funds limit; conservation; no instant transfer |
| **S7** | Regional demand and founding measurement (AD-7); the first-tool (P2) and retiree-stock (P3) findings, measured only (balance changes wait for the owner) | Busy share before and after; foundings with cause |
| **S8** | `economy_sim` regional measurements (the directive's Phase 7 list); performance on desktop; Android profile | Determinism (two runs); save mid-mission; the item and currency ledgers |

**After S8:** a proposal for one consolidated Living Economy validation campaign, reusing every result that still applies.
Packaging only on the owner's authorization.
