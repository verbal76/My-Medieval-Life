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
| `mining_adapter.gd` | `MiningCapabilityAdapter` | B (provisional) | The only way the model learns mining capability (MIN-D): fixture, live (duck-typed), none. |
| `report.gd` | `SettlementReport` | B/C | The village's goods by group (market, private, public, player, loot), coins by holder, outside money, food days, capabilities, transport; measured daily use from the World's stats; a read-only ledger snapshot of the village. |
| `ledger.gd` | `SettlementLedger` | C | Books of an abstract off-map settlement: stock, coins, needs, production, explicit income; every change a journal line; `balanced()` proves the books. |
| `regional.gd` | `RegionalMarket` | C (E rules) | Supply, demand, willingness to pay, purchasing power; `plan()` (competition, cooperation, capacity, unmet reasons, lost sales) and `execute()` (atomic, matched); `matched()`. |
| `routes.gd` | `TradeRoutes` | C/E | Grid routes (Dijkstra over road/open/rough/solid; overworld classifier), abstract routes, haulage cost, cart capacity. |
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
- **No bonus.** A level moves no coin and no item and gives no villager a skill. How levels should change NPC decisions
  (MIN-D "autonomous adoption", SET-B gates on recipes) is not decided and not implemented.
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

- **Demand** = a settlement's daily need times `reserve_days`, less what it holds. **Supply** = what it holds beyond its
  own reserve (and, for the village snapshot, only what its traders and producers hold: pantries are not for sale).
- **Willingness to pay** = the item's value, raised up to `scarcity_premium` x value as the buyer's store runs out; a
  settlement pays nothing for what it does not need.
- **Purchasing power** = coins above `cash_floor`. Need never creates coins: a cash-poor town's unmet need is recorded
  with reason `funds` (spec s.11 "trade failure is observable").
- **Allocation** (deterministic): goods in id order; buyers neediest first (share of horizon lacking; ties by id); each
  buyer takes from the cheapest delivered seller (ties by id), limited by the seller's supply, its transport capacity
  this round and the buyer's coins. Unmet reasons: `no supplier`, `price`, `funds`.
- **No resale in the round** (spec s.9 "prevent circular money printing via ... resale"): supply is fixed at the start
  of a round; goods bought in it cannot be sold on in it.
- **Execution** moves goods seller -> buyer and coins buyer -> seller as one atomic, matched pair of journal lines; a
  line that no longer holds is refused whole.
- **Off-map settlements** change only by journaled lines: production, use (with recorded shortages), explicit income
  (default 0, a closed purse; Q18-3) and matched trade.

### Ore demand (the overstatement fixed)

The first shadow runs counted the village's daily use of ore and coal as import demand, though its own seams supply them.
Now `MiningCapabilityAdapter.local_supply("village")` gives what the village's own reachable seams still hold (MIN-D:
`_quarry_sources` filtered by `villagers_reach`, only while the mining level is 1 or more, since at 0 nobody can dig; on
this branch the Build 16 seams in `World.deposits` stand in), `SettlementReport.as_ledger` puts it in the snapshot's
`local_supply`, and `RegionalMarket.demand` subtracts it. It is never stock and never for sale: ore still in the ground is
not goods. The settlement model itself still reads no deposit.

### Transport cost (agent decision)

Haulage is labour: the carters' day wage (`helper_wage`, the manor's day wage) for the round trip, spread over a full
load and rounded up, is added to the asking price and **paid to the seller, who hauls**. No coin is destroyed by
distance and none is created. Terrain lengthens a route (road 1, open 1.6, rough 2.5 tiles of travel a tile; solid is
impassable). A settlement with handcarts (B14 carts, already in the game) sends 60 units a cart a round; without, one
carrier's 12.

## 4. Competition and cooperation (spec s.6 row 5, s.7 mature phase)

- Competition: the cheapest delivered price wins; the losers' lost sales are recorded (for reports and later merchant
  AI). Capacity spills the remainder to the next cheapest.
- Cooperation: an agreement `[a, b, "preferred"]` lets a partner win a sale when its delivered price is within
  `preferred_margin_pct` of the cheapest. It is paid its own price: no discount, gift, loan or barter (no hidden rescue,
  WDR-022; credit and barter are Q18-5).

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
