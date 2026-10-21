# Expansion 18 (Settlement Advancement & Regional Economy): prospective design note

Branch `wip/expansion18-preparation` (baseline `b721616`, the released Build 16 plus records; no Build 17 code).
Authority: owner directive 2026-10-21, `docs/directives/2026-10-21_parallel_prospective_development_18_19.md`
(register PROS-01, PROS-18). Specification: `docs/directives/My_Medieval_Life_Settlement_Advancement_Regional_Economy_Expansion.pdf`
(cited "spec s.N"); engineering plan `origin/wip/roadmap-docs:docs/roadmap/18_SETTLEMENTS_ENGINEERING_PLAN.md`.

**Status: PROSPECTIVE.** Nothing here is live gameplay, nothing is integrated, and no phase (SET-A..D) is complete. The code
runs only in its own tests and the shadow harness. Live behaviour of the single village is unchanged (the one touch of
existing code is `game/tests/census.gd`, which now delegates to the moved census; see "Hooks").

## 1. Modules (`game/scripts/core/settlement/`)

| File | Class | Phase | What it does |
|---|---|---|---|
| `holdings.gd` | `SettlementHoldings` | B/C | The census of goods by holder (moved unchanged from `tests/census.gd`) and coins by holder (sums to `World.total_coins`). Read-only. |
| `facts.gd` | `SettlementFacts` | B | A settlement's facts read from the World: living adult practitioners (job, skill levels; role "adult" as MIN-D counts them; the player's skills and goods are not the settlement's, as MIN-D decided), tools as MIN-D counts them (villagers' packs, households, the manor's yard), goods held (not the player's, not loot), stations, structures (fields, stalls), transport (handcarts, carrying), and deposit access, records, portals and the mining level from the adapter. |
| `industries.gd` | `SettlementIndustries` | A/B | Validates `game/data/settlement_industries.json`; derives each industry's level from facts; names unmet needs; specialization and leaders across settlements; level history. |
| `mining_adapter.gd` | `MiningCapabilityAdapter` | B (provisional) | The only way the model learns mining capability (MIN-D's `World.discovery`): fixture, live, none; also deposit access, records, portals and the village's own reachable ore. |
| `report.gd` | `SettlementReport` | B/C | The village's goods by group (market, private, public, player, loot), coins by holder, outside money, food days, capabilities, transport; measured daily use from the World's stats; the village's parties to regional trade (traders, households, villagers, the manor) as read-only snapshots. |
| `ledger.gd` | `SettlementLedger` | C | Books of one party to regional trade (an abstract settlement, or a buyer or seller in a place): stock, coins, needs, production (times the output factor), explicit income, transport, whether it can travel or carts for hire; every change a journal line; `balanced()` proves the books. |
| `regional.gd` | `RegionalMarket` | C (E rules) | Supply, demand, willingness to pay, purchasing power; `plan()` (any buyer; carriage by the buyer's own trip or a paid carter; competition, cooperation, capacity, unmet reasons, lost sales), `execute()` (atomic, matched, carriage fees apart), `matched()`, `to_contract_offer()` (CON-01 shape). |
| `routes.gd` | `TradeRoutes` | C/E | Grid routes (Dijkstra over road/open/rough/solid; overworld classifier), abstract routes, carriage cost, carrying capacity (handcarts, packs). |
| `settlement_save.gd` | `SettlementSave` | A | Provisional save section `x18_settlements` (`mml-settlements/0`). |

Data: `game/data/settlement_industries.json` (`mml-capabilities/1`), test fixture `game/tests/fixtures/x18_regions.json`
(`mml-regions/0`).

## 2. Capability model (SET-B; spec s.3, s.4, s.9)

- Schema: Build 17's SET-A sketch (`MIN_A_ARCHITECTURE.md` s.9): industries -> levels -> needs. Need kinds:
  `practitioners` (job and/or skill at a minimum level, a count), `tool_stock`, `stock`, `structure`, `transport`,
  `records`, `portal`, `industry` (cross-industry), and `any` (alternatives, e.g. toolmaking needs a working mine *or*
  iron bars in store, so imports can substitute for a mine).
- **Derived, never stored as truth.** A level holds when every need of it and of each level below it holds; it falls the
  moment one stops holding. The save keeps only the levels last seen and the day each changed (history).
- **Never a gate (owner Q18-9, 2026-10-21).** A level moves no coin and no item, gives no villager a skill, and never
  refuses or blocks an activity: a settlement at mining 0 can still mine with the resources, tools and access. Its only
  effects are on pay and production output, as data-driven factors (section 9), all 1.0 until the owner sets them.
- **Population plays no part** (spec s.3): tested; a 12-person mining hamlet leads a 90-person farming town in mining.
- **Mining is external.** The data file marks mining `external`; its level is read from `MiningCapabilityAdapter`,
  which on this branch reports `unavailable` (level 0) in the live game. The model never reads `World.deposits` (a test
  empties every seam and checks no level moves). The adapter is mapped to MIN-D's real interface (`World.discovery`:
  `evaluate("mining")` for the level now, `level("mining")` for the last dawn's, `history`, `manor_finds()`; portals from
  `World.underground`; reachable seams from `World._quarry_sources` and `villagers_reach`), read on
  `origin/wip/b17-mind` b0506db and tested against a fake World with those members.
- **Vocabulary aligned with MIN-D.** `settlement_industries.json` uses MIN-D's need kinds (`practitioners` with `jobs`,
  `station {type}`, `structure {what}`, `transport` with `carry`, `deposit_access`), and the facts count practitioners
  (adults only, not the player) and tools (villagers, households, the manor's yard) as MIN-D does.
- First industries (provisional, Q18-2): forestry, carpentry, smithing, farming, tanning, trade, plus external mining.
  Farming, carpentry and tanning have no skill yet (Q18-1, DVW-B8), so they are measured by job, tools and structures.

## 3. Regional economy (SET-C; spec s.5-s.7, s.9, s.11)

Trade is between **parties** (`SettlementLedger`): a whole abstract settlement, or one buyer or seller inside a place
(owner Q18-10: villagers, households, merchants, businesses, treasuries). Routes run between places (`settlement`);
parties of the same place do not trade here (that is the local market).

- **Demand** = a party's daily need times `reserve_days`, less what it holds and what its own workings can still yield
  (`local_supply`). **Supply** = what it holds beyond its own reserve, within its sale limit (a household's pantry and
  the granary are not for sale; members' and traders' packs beyond what they keep are).
- **Willingness to pay** = the item's value, raised up to `scarcity_premium` x value as the buyer's store runs out, for
  the goods and their carriage together; a party pays nothing for what it does not need.
- **Purchasing power** = coins above `cash_floor`. Need never creates coins: a cash-poor buyer's unmet need is recorded
  with reason `funds` (spec s.11 "trade failure is observable").
- **Allocation** (deterministic): goods in id order; buyers neediest first (share of horizon lacking; ties by id); each
  buyer takes from the seller with the cheapest delivered cost (price at the seller's door + carriage fee), then the
  shorter trip, then the lower id; limited by the seller's supply, the carriage capacity (the buyer's own or the
  carter's) left this round and the buyer's coins. Unmet reasons: `no supplier`, `no carriage`, `price`, `funds`.
- **No resale in the round** (spec s.9 "prevent circular money printing via ... resale"): supply is fixed at the start
  of a round; goods bought in it cannot be sold on in it.
- **Execution** moves goods seller -> buyer and the price buyer -> seller, and any carriage fee buyer -> carter, each as
  an atomic, matched pair of journal lines; a line that no longer holds is refused whole.
- **Off-map settlements** change only by journaled lines: production (times the output factor, section 9), use (with
  recorded shortages), explicit income (default 0, a closed purse; Q18-3) and matched trade and carriage.
- **The village's parties** (`SettlementReport.parties`): each trader (the villagers whose trade buys in
  `NPCBrain.BUYS`; demand from the live `NPCBrain.wants`), each household (members' purses and packs, the pantry;
  demand = its share of the village's measured food use), each villager of no household, and the manor (treasury and
  granary; cannot travel; no demand rule yet). Every purse and good is in exactly one party (tested). The player buys by
  hand and is not a party. Snapshots only: nothing is written back to the World on this branch.

### Ore demand (the overstatement fixed)

The first shadow runs counted the village's daily use of ore and coal as import demand, though its own seams supply them.
Now `MiningCapabilityAdapter.local_supply("village")` gives what the village's own reachable seams still hold (MIN-D:
`_quarry_sources` filtered by `villagers_reach`, only while the mining level is 1 or more, since at 0 nobody can dig; on
this branch the Build 16 seams in `World.deposits` stand in); `SettlementReport.parties` gives it to the traders whose
trade buys that ore, and `RegionalMarket.demand` subtracts it. It is never stock and never for sale: ore still in the
ground is not goods. The settlement model itself still reads no deposit.

### Transport cost (owner Q18-10)

Carriage is never free and never folded into the price of the goods. Either the **buyer fetches the goods itself**
(`self`: no coin; as much as its own transport carries a round: 60 units a handcart, else 12 a carrier; a party that
cannot travel, such as the treasury, cannot), or it **pays a willing carter** (`carter`: a party with
`carts_for_hire`, based at either end of the route, with room left; fee = the carters' day wage, `helper_wage`, for the
round trip spread over a full load, rounded up, times the carter's pay factor; paid buyer -> carter as its own matched
transfer). No coin is destroyed by distance and none is created. Terrain lengthens a route (road 1, open 1.6, rough 2.5
tiles of travel a tile; solid is impassable).

## 4. Competition and cooperation (spec s.6 row 5, s.7 mature phase)

- Competition: the cheapest delivered cost wins (then the shorter trip); the losers' lost sales are recorded (for
  reports and later merchant AI). Carriage capacity spills the remainder to the next cheapest (or to a carter).
- Cooperation: an agreement `[place_a, place_b, "preferred"]` lets a partner's seller win a sale when its delivered cost
  is within `preferred_margin_pct` of the cheapest. It is paid its own price: no discount, gift, loan or barter (no
  hidden rescue, WDR-022; credit and barter are Q18-5).

## 5. Persistence (provisional)

`SettlementSave` keeps `{format, capabilities: {id: {levels, since, history}}, regions: [ledger], agreements, day}` in the
save dictionary under `x18_settlements`. `World.load_dict` ignores unknown keys, so saves with the section load in the
live game, and every existing save (14-16) gives the default state. `SAVE_VERSION` is not bumped: Build 17 owns the next
versions; the section becomes part of the versioned save (with a migration fixture from Build 17's last version) at
integration. An unknown section format is refused, never reinterpreted.

## 6. Hooks into existing code

| Hook | Where | Why |
|---|---|---|
| `tests/census.gd` delegates to `SettlementHoldings` | test infrastructure | one census for `economy_sim`, the conservation test and the settlement report; `tests/` is not exported, so the walk had to move into `core/` to run in the game. No behaviour change (run_tests, conservation_test, economy_sim 30 days run). |

Planned for integration, not made here: `World.to_dict/load_dict` calling `SettlementSave.attach/extract`; a dawn
recompute of levels in `World._new_day`; a wiki page from the report; `NPCBrain.caravan()` replaced (see
`CARAVAN_REPLACEMENT.md`).

## 7. Determinism

No randomness is used. Every iteration over settlements, goods and industries is sorted; route search breaks ties by
cell order. Tests run the same scenarios twice and compare JSON fingerprints.

## 8. One capability file and one evaluator at the Build 18 reconciliation (plan)

Today there are two files and two evaluation loops: MIN-D's `game/data/capabilities.json` with `Discovery.evaluate`
(Build 17, mining only, reads the World directly in `need_holds`) and this branch's `settlement_industries.json` with
`SettlementIndustries.evaluate` (every other industry, reads a facts snapshot). Until the reconciliation the settlement
model only **consumes** MIN-D's mining level (adapter; mining is `external`), so mining is never derived twice. At the
reconciliation they become one file and one evaluator:

| Step | What moves | Where |
|---|---|---|
| 1. File | The non-mining industries (forestry, carpentry, smithing, farming, tanning, trade), `need_kinds`, `transport` and `market` blocks move from `settlement_industries.json` into MIN-D's `game/data/capabilities.json` (it keeps its name, format `mml-capabilities/1` and MIN-D's mining block unchanged). `settlement_industries.json` is deleted. | `capabilities.json` |
| 2. Schema | Already aligned on this branch: `practitioners {jobs, skill, min_level, count, as}`, `station {type}`, `structure {what}`, `transport {any: handcart, carry}`, `deposit_access`, `records`, `portal` are MIN-D's; this branch adds `stock {item}`, `industry {id, min}` and `any {of}` (additive: MIN-D's block needs none of them). MIN-D's `note` key and this branch's `_note` both stay comments. | — |
| 3. Algorithm | One level-climbing loop: `SettlementIndustries.evaluate(facts, data)` (sequential levels, unmet needs per level, cross-industry order). MIN-D's `Discovery.evaluate(industry)` becomes a thin call: `SettlementIndustries.evaluate(SettlementFacts.from_world(w)).levels[industry]`, keeping its return shape `{level, holds, unmet}` for its callers (dawn, prospector place, manor postings). | `industries.gd` |
| 4. Need readers | MIN-D's World readers move into the one facts builder, `SettlementFacts.from_world`: `deposit_access` (`_quarry_sources`, `villagers_reach`, `level_of`), `records` (`manor_finds`), `portal` (`underground.portals`), `structure` (`Discovery.structures`: pit ramps, timber supports), `transport.carry` (`carry_ore`). They are already the adapter's methods; at integration the adapter's live mode is folded into `from_world` and only the fixture mode remains (for abstract settlements and tests). Practitioners and tools are already counted MIN-D's way. | `facts.gd` |
| 5. Mining no longer external | Remove `"external": "mining"`; mining is evaluated by the one evaluator from MIN-D's block. `test_min_d_schema` (settlement_test) already proves the evaluator gives MIN-D's documented levels from MIN-D's block. MIN-D's `discovery_test` must still pass unchanged (its gate). | `capabilities.json`, tests |
| 6. History | One history: MIN-D's `Discovery.history` `{day, industry, from, to, why}` and its dawn notes, extended to every industry by iterating `caps().industries` (it already does). `SettlementIndustries.record` and the provisional `x18_settlements.capabilities` save key are dropped in its favour (no second history in the save). | `discovery.gd` (dawn), `settlement_save.gd` |
| 7. Effects | Levels gate nothing (owner Q18-9, 2026-10-21): their only effects are data-driven pay and output factors (section 9). | — |

Order: after Build 17 is complete and its baseline is merged into this branch (directive's reconciliation gate). Owner of
the change: the Build 18 integration; MIN-D's files are not edited before then.

## 9. Capability effects: pay and output only (owner Q18-9, 2026-10-21)

Decision (verbatim in `docs/directives/2026-10-21_expansion18_decisions_q18_9_q18_10.md`): "Capability levels affect pay
scales and production output only. They must never function as permission gates or prevent an NPC, player, or
settlement from performing an activity."

- Data: `settlement_industries.json` `effects`: `pay_factor` and `output_factor`, per industry a list indexed by level
  (0..max), `default_factor` 1.0, and `outputs` (which goods each industry's output factor scales).
- Code: `SettlementIndustries.pay_factor(industry, level)`, `output_factor(industry, level)`, `industry_of(item)`.
  Applied on this branch to abstract settlements' production (`SettlementLedger.tick`) and to a carter's fee (trade
  industry). At integration the same factors apply to the live wages of an industry's workers (MIN-D's prospector pay,
  the labour market's job pay) and to the output of extraction and recipes; never as a condition.
- Every factor is **1.0 (no effect)**: the magnitudes are the owner's (**Q18-11**). Tested: with neutral factors a level-0
  and a level-2 settlement produce the same; with a test curve in the data the level scales output (never to zero by
  rule), and the books still balance.
- Audit of this branch: nothing in the settlement model refuses an activity because of a level. Smithing 2's "mining 1
  or iron bars" need decides only the level, not whether anyone may smith.

**Q18-11 (owner):** What pay factor and output factor should each capability level give, and for which industries
(mining only first, or every industry in the schema)? Until answered, every factor is 1.0.

## 10. Regional purchasing and carriage (owner Q18-10, 2026-10-21)

Decision (verbatim, same file): anyone may buy from another settlement; the buyer travels, collects and carries the goods,
or negotiates and pays a willing carter or delivery service; no free delivery, no merchant-only buying, nothing created;
use the existing negotiation, contract, inventory, transportation and conservation systems; no duplicates.

What exists and is reused (audit of this branch, Build 16 code, and of `origin/wip/build17` for CON-01, read only):

| Need | Existing system | Used here |
|---|---|---|
| Purses and goods of each buyer | NPC `coins`/`inv`, household `pantry`, `World.treasury`, `granary` (`SettlementHoldings`) | `SettlementReport.parties` snapshots them, each once |
| What a trader wants | `NPCBrain.wants`, `BUYS`, `keeps` | trader demand and what it keeps from sale |
| Carrying goods | packs (`carry_ore` and the carrier load), B14 handcarts (`Carts`: owner, family or hired help may pull) | self-collection capacity (carts owned by the household count) |
| Negotiated purchase | CON-01 `Contracts` (Build 17: goods procurement, offer/accept/counter, reserved coins, delivery pack to pack) | `RegionalMarket.to_contract_offer` maps each line to a CON-01 offer; `execute` stands in until integration |
| Delivery inside the village | B14-06 cart stops and the attendant's unloading (`Carts.hour`, the player's stall only); household market runs | not a carrier between settlements; not reused for that, not duplicated |
| Hiring someone to carry | `Construction.hire` (a helper for the day at `helper_wage`, carrying the employer's goods **to its own building site**) | its wage is the carter's day rate; the rule itself covers only building sites |
| Conservation | journal, `balanced()`, `matched()`; the World ledger stays untouched | carriage fees are matched transfers |

Gaps that need the owner (not invented here):

- **Q18-12 (owner):** CON-01 covers goods only, and `Construction.hire` hires a carrier only to one's own building site.
  May a party hire a willing villager or carter to haul goods between settlements, and on what terms (a day wage as
  `helper_wage`, a fee per load, or negotiated like a CON-01 contract with service terms)? It overlaps OD-LE-03 (service
  contracts in the Living Economy) and MIN-D's open question 1 (commissioning a survey by CON-01). Until answered, carters
  exist only as fixtures in tests (`carts_for_hire`); in the live shadow no carter is offered, so a party that cannot
  travel (the treasury) buys nothing, recorded as `no carriage`.
- **Q18-13 (owner):** CON-01 parties are "player", "npc:<id>" and "manor"; a household, an off-map settlement or its
  people have no CON-01 reference. Should CON-01 gain household and off-map party references, or should regional buying
  be done by a named member (a household's responsible adult) and a named regional merchant?
- Travel time: a buyer who fetches its own goods is away for the route's days. The shadow records the days on each line
  but does not take the villager out of the village; at integration this is the live trip (villagers walk), not a model.
