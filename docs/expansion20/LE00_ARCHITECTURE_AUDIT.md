# Expansion 20 (Living Economy), LE-00: read-only architecture audit and cross-system dependencies

Branch `wip/expansion20-preparation`, created from Build 17's code (`wip/build17` `80e6b99`). Register: EXP-D, stage
LE-00 (ACTIVE DEVELOPMENT). Authority: owner directive 2026-10-22 (`docs/directives/2026-10-22_expansions_18_19_20_directive.md`
on staging: "begin preparation as a separate planning and investigation workstream"), OD-30 (Expansion 20 is the Living
Economy), OD-LE-01 (answered: Expansion 20, Build 19 Judgment not displaced). Specification: the owner's design
`docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.txt` on staging (cited "design s.N").

**Status: PLANNING ONLY.** This document changes no code, data, save format, test or register entry. Nothing in it is
approved policy. Where it recommends, the recommendation is an agent proposal for the owner. LE-00's gate is
"Owner decisions registered; no guessed policy" (design s.17): section 6 maps every open decision (OD-LE-02..15) to the
stage it blocks, and section 9 lists the register changes proposed to the lead (staging is the lead's).

Method: the Build 17 code in this worktree was read (`game/scripts/core/*.gd`, `game/data/balance.json`); Expansion 18 and
19 designs were read with `git show` from `origin/wip/expansion18-preparation` (`4ce9927`) and
`origin/wip/expansion19-preparation` (`05adc9d`); the register and records were read from `origin/staging/my-medieval-life`.
No simulation or test was run (MSW-01: reading sufficed).

---

## 1. How the economy works today (Build 17)

Citations are `file::function`. All files are under `game/scripts/core/` unless named.

### 1.1 The NPC brain (decisions)

- **Priority list, not needs.** `npc_brain.gd::decide` runs a fixed order each time a villager's plan empties: bandit or
  clan child; a report to a guard; eat when hunger is below `eat_below`; rest when hurt; guard duty; sleep at night;
  children and elders; then, in work hours, hired carrying (`construction.gd::plan_helper`), stall attendance
  (`business.gd::plan_attendant`), a manor job (`manor_work.gd::plan`), a contract (`contracts.gd::plan`), day labour
  (`npc_brain.gd::_day_labour`), the trade's own routine (`npc_brain.gd::_plan_job`), else the evening
  (`npc_brain.gd::_plan_evening`, which includes household provisioning `_plan_provision` and storefronts).
- **Trade routines are per job.** `_plan_job` dispatches to `_miner`, `_woodcutter`, `_smith`, `_cook`, `_farmer`,
  `_keeper`, `_hunter`, `_tanner`, the carpenter's chain (`_carpenter_carts`, `_carpenter_goods`, `_carpenter_mallet`,
  `_carpenter_shovel`, `mine_supply.gd` `carpenter_work`), the sage's brewing, `_mason`. Each is an ordered list of "if
  stock/condition then recipe or trip". Example: `_smith` smelts if it holds ore and coal, then sells surplus tools, then
  serves `World.manor_orders`, then forges "whatever is scarcest" in its own stock, then buys ore/coal from the raw-goods
  merchant, then planks from the first carpenter.
- **Who to trade with is a global search.** `_buyer_for` (through the `OUTLETS` preference list and `_with_buy_role`),
  `_seller_of`, `_vendor_with_food`, `_grain_seller`, `tool_price`, `_buy_tool` and `construction.gd::_seller` scan every
  living villager (`w.npcs`) and pick the first or nearest. Nobody has to have heard of a seller to find it.
- **Rules every party shares** (PAR-01/PAR-02): `world.gd::trade` (atomic sale), `world.gd::transfer` (gift/move),
  `world.gd::purchase_qty` (how much a business buys), `world.gd::can_afford`, `world.gd::work_craft` (recipes consume
  inputs). Items a villager keeps for its work: `NPCBrain.KEEPS`, `npc_brain.gd::keeps`.

### 1.2 Households and budgets

- **Household record**: `World.households` `{id, family, home, members, pantry}`; the pantry is the family chest
  (`npc_brain.gd::stock_family_chest`, FSE-18). Money is not pooled: each member has a purse; "the household's" payments
  fall on its richest member (`property.gd::_payers`, `npc_brain.gd::_richest_in_household`, `_payer_for`: the family tab
  for meals).
- **Economic position**: `npc_brain.gd::evaluate_household` each dawn computes need, cost (food at the market wheat price
  plus a log), income (members' average earnings over 5 days), days of food, runway (cash plus sellable trade stock) and an
  "unsustainable" streak. It drives job mobility (`seek_work`) and nothing else.
- **Reserves (OD-19, PAR-02A)**: `world.gd::necessity` and `reserve_of` give each person the coins their household needs
  for food, fuel, medicine and rent over `reserve_days` (2), less expected wages, at today's asking prices
  (`world.gd::_market_price`). `can_afford` lets necessities use reserved coins and other purchases only the surplus.
  This is the closest thing today to a household budget: one horizon, one rule, no competing goals.
- **Food**: `_plan_eat` (pocket, pantry, raw food, then a meal bought, with the family tab), `_plan_provision` (grain or
  food and a log when the pantry holds fewer units than members), `_cook_at_home`. One valuation of food:
  `npc_brain.gd::food_points`, `store_points`, `household_food_days`. A missed meal is counted by reason
  (`missed_meal_no_money`, `missed_meal_no_food_for_sale`).
- **Founding and building homes**: `construction.gd::daily`, `_found`, `_found_couple`, `_keep_building` (a budget is
  the purse less the OD-19 reserve; hires a helper or carries its own), `couples_needing_home`.
- **Family farmland** (FARM-01..09): `farm_plots.gd` (households lease or buy plots and work them after hours).

### 1.3 Employment and wages

- **Job market**: `npc_brain.gd::job_market` lists six open jobs (manor hand, farmer, woodcutter, hunter, miner,
  prospector) with "pay" = the average recent earnings of everyone in that job (village-wide knowledge) and "open"
  places from global counts (fields, grown trees, takeable game, ore left, `discovery.gd::prospector_place`).
- **Mobility**: `npc_brain.gd::seek_work` each dawn: the unemployed, a worker who is `tool_short`, a hunter with no game,
  or an adult in a household unsustainable for `mobility_unsustainable_days` who earns less than its share, picks the
  best score (pay - tool cost / 10 - distance / 60), with a margin and cooldowns. `_change_job` records it.
- **Skilled trades are not chosen**: smith, carpenter, tanner, cook, tavernkeeper and merchant are filled only by
  succession (`succession_dawn`, `succession_caravan`, `_apprentice_for`, `_newcomer_for`: a newcomer brings
  `newcomer_coins` from outside, counted in `coin_sources`).
- **Wages**: the treasury pays the sage, the reeve, guards and manor hands daily (`npc_brain.gd::pay_guards`); the most
  recent manor hand is laid off when the treasury is below two days of obligations. Helpers are paid by the employer
  (`construction.gd::hire`, `_pay`); the player's attendants by the player (`business.gd::_pay_wage`); manor jobs per job
  (`manor_work.gd`); paid work for the player by the giver (`quests.gd`, set aside, paid in full or not at all).
- **Out of work**: `_get_tool` leaves a worker "out of work: needs an axe" when no tool is for sale it can pay for;
  `_miner` moves a miner to manor hand when every seam is worked out; `_day_labour` lets a hungry household's adult take
  a manor job for the day.

### 1.4 Production and recipes

- `game/data/recipes.json` (station, inputs, outputs, skill level, tool) and `world.gd::work_craft` (consumes inputs,
  makes outputs, wears tools, gives xp). Stations are reserved by `_station_for` / `release_station`.
- What a trade buys and how much: `NPCBrain.BUYS` (stock caps by role), `wants` and `batch_unit` (SHOP-01: only inputs of a
  recipe it has the skill for, rounded to whole batches). Made-to-order goods: `NPCBrain.MADE_TO_ORDER`, made only when
  `_buyer_for` finds a buyer.
- Raw production: `world.gd::work_mine`, `work_felled`, fields (`_farmer`, `farming.gd`), pens (`_keeper`, `fauna.gd`),
  hunting (`_hunter`), foraging (`_plan_home_work`). Finite sources: deposits and seams (`World.deposits`, MIN-A..F),
  trees (`trees.gd`, regrowth), wildlife (`fauna.gd`, refuges `refuges.gd`).
- Spoilage and wear: `decay.gd::dawn` (perishables spoil by a hashed draw; armour, clothes and carts wear).

### 1.5 Construction

- `world.gd::start_site`, `deliver`, `_finish_site`, `cancel_site` (one construction for all builders); bills of
  materials `site_cost`; `construction.gd::open_need` (what open sites still need), `estimate`, `_seller`,
  `_make_timber`, `plan_helper`. Builders of their own home who lack an axe count as tool needers (`tool_needers`).
- Public works and repairs: the manor buys planks, iron bars and stone into its works yard (`npc_brain.gd::reeve_day`,
  `_public_works`) and posts mend jobs (`manor_work.gd`). Sellers keep back what open sites need (`open_need`).

### 1.6 Markets and prices

- **Asking price is a formula of the seller's stock and nearby supply**: `world.gd::sell_price` ->
  `sell_price_at(id, stock, nearby)`: value x clamp(1.5 - 0.05 x stock - weight x min(nearby, cap), price_min + 0.2,
  price_max). `local_supply` counts what other traders and open stalls offer within `local_supply.radius` (B14, owner:
  "pricing ... determined by availability for sale in a certain diameter").
- **Buying price is a formula of the buyer's stock**: `buy_price_at(id, stock)` = value x clamp(1.2 - 0.04 x stock,
  0.4, 1.2) x `sell_ratio`. Both sides' Trading skill move it (`deal_factor`, `deal_price`). Bulk deals are priced unit
  by unit (`sale_prices`, `player_quote`).
- **There is no bid**: a buyer pays the posted price or does not buy; it never offers more, and a seller never lowers
  its price for a specific buyer. Only CON-01 contracts negotiate (1.10). The market wheat price for household
  reckoning is the cheapest farmer's or food merchant's asking price (`npc_brain.gd::update_market`).
- **Price ceiling at stalls**: `business.gd::ceiling` (a villager pays at most the cheapest village price, plus
  `stall_urgency_step` per urgency level), `business.gd::needs` (the one list of real needs a stall can serve).

### 1.7 Stalls and businesses

- Merchants' stalls (`World.stalls`, kinds raw, food, goods; `buy_role` = `merchant_<kind>`), the player's pitches and
  shops (`business.gd`: rent, prices, till, attendants, villager customers by `needs`/`offer`/`_send_buyers`), villagers'
  built stalls and the 5% commission on every stall's sales (`stalls.gd::settle`, `plan_npc`, `daily`), storefronts
  (`npc_brain.gd::_plan_storefront`, `front_goods`). Counters for skilled trades (`counters.gd`).
- Vacant stalls are let again (`property.gd::relet_stalls`); the manor's land office sells and leases land and houses,
  with weekly rent and eviction (`property.gd::buy`, `collect_rents`).

### 1.8 Trade hooks

- `world.gd::trade_hook` (diagnostics: `tests/economy_sim.gd`), `stalls.gd::after_trade` (a stall sale's session).
  Expansion 18 adds `Relations.note_trade` from `World.trade` on its branch (couriers' known recipients); Expansion 19
  adds the trade-choice adapter on `_buyer_for` / `_seller_of` (off unless judgment is attached).

### 1.9 The caravan (CARAVAN-TMP, B7-014)

- `npc_brain.gd::caravan` every `caravan_every_days` (2) at noon: the purse (`World.caravan_purse`, up to
  `caravan_float` 1500) gains `caravan_allowance` (30 a day) tapering to nothing as the village's coins reach
  `caravan_ceiling_per_head` (100) a head. It sells ore and coal to smiths when seams run low (`_caravan_imports`, at
  `caravan_import_markup`), stone to the raw-goods merchant (`_caravan_stone`), medicines to the sage
  (`_caravan_apothecary`) and seed to the food merchant (`_caravan_seeds`); then buys surplus at 0.8 x value, up to
  `caravan_coins` (600) a visit, one unit at a time to the seller with the greatest `caravan_line_need` (EQ-22). It keeps
  food when the village is short and tools a villager needs (`local_tool_need`). It never exports raw ore, coal, stone or
  blocks (`NOT_EXPORTED`). It also brings newcomers (`succession_caravan`).
- This is the only source of new money besides newcomers' purses (`World.coin_sources`). It is a planner (it knows the
  village's whole food, tool need and every seller's coins), not a trader with margins.

### 1.10 Contracts (CON-01, CON-02)

- `contracts.gd`: one record `{id, buyer, seller, item, qty, price_each, deadline_day, terms, state, delivered, paid,
  reserved, route, made_day, history}` for player-NPC, NPC-player and NPC-NPC. The module header says it is "the Living
  Economy design's Contract (docs/build17/PROCUREMENT_CONTRACTS.md section 3) in its smallest form".
- Negotiation: `evaluate` (means, skills, tools, time with `risk_margin`, price against the going price and alternatives,
  obligations, household needs, tie with the buyer, past early endings), `price_terms`, `min_price`, counters both ways
  (`counter_offer`, `buyer_answer`, `meet_counter`). Signing: small agreements at once, formal ones face to face
  (`formal`, `face_to_face`, `npc_sign`, Q18-13).
- Obligation and reservation: the buyer's coins for the unpaid value are set aside at acceptance (`reserved`, counted in
  `reserved_total` and `World.total_coins`); the seller's stock owed is held back from sale (`held_for`, read by
  `npc_brain.gd::reserve`). Delivery and payment only through `deliver` / `_pay_units` (unit by unit).
- Ending: `_lapse` at dawn after the deadline (coins back, regard lowered, a memory line "let down by ..."), `cancel`,
  `on_death`, `on_player_died`. Policy is OD-29's provisional defaults (no money penalty, no renegotiation after
  acceptance).
- NPC orders: `contracts.gd::npc_orders` / `order_input`: once a dawn, up to `npc_orders_per_day` businesses that lack an
  input nobody sells (`_vendor`) offer a contract to each villager in turn, then to the player (`offer_to_player`).
- Services (CON-02): `contract_services.gd` kinds `dig` and `survey`, paid per unit actually done.

### 1.11 Treasury, tax and relief (the manor)

- `npc_brain.gd::reeve_day` at 17:00: `update_market`, reeve succession, guard posts, **tax** (only while the treasury is
  under `treasury_tax_holiday_days` of obligations; a share of each household's cash above an exemption), **relief**
  (`_relief`: households under `relief_trigger_days` of food, hungriest first, from the granary's grain, then its other
  food (`_relief_from_granary`, TREAS-01), then bought from any food store at asking prices (`_relief_offers`), down to
  one day of wages in an emergency), **trade support** (`_support_trades`, EQ-19: tools bought for tool-short workers, or
  advances to a smith on `World.manor_orders`), repairs, mining work postings, public works, and **granary** purchases
  from farmers' surplus up to `granary_target_days`.
- Wages: `pay_guards` at 18:00 (1.3). Treasury income: tax, rents (`property.gd::collect_rents`), stall commission
  (`stalls.gd::settle`), land sales.
- Chronic relief is named, not hidden (`_note_relief`).

### 1.12 The manor's work board

- `manor_work.gd`: jobs `haul` (bought goods carried to the yard, granary or a pantry), `mend`, `quarry`, `survey`,
  `trial`, `excavate`, `tunnel`, `shore`; posted by `reeve_day` through `post_quarry`, `post_discovery`, `post_pits`,
  `post_tunnels`, `post_shore`; taken by `seek` / `seek_kind` / `plan`; wages set aside (`reserved_total`). The reeve
  carries an unclaimed delivery himself (LOG-01, `reeve_fallback`). `mine_supply.gd::procure` buys or orders the
  underground's equipment.

### 1.13 Mining

- `npc_brain.gd::_miner` (needs a pickaxe; mines what a buyer wants, `_wanted_ores` reading the first smith's stock, with a
  15% `w.rng` draw for copper); `seam_steps`; finite seams `World.deposits` (MIN-A levels, MIN-B quarry stone, MIN-C
  prospecting `prospecting.gd`, MIN-D discovery and capability `discovery.gd`, MIN-E open pits `open_pit.gd`, MIN-F
  underground `mine_works.gd`, `underground.gd`). When the wanted seams run out the miner digs the manor's posted pits,
  buys a shovel, mines what still sells, or becomes a manor hand. Imports when seams run low: `_caravan_imports`.

### 1.14 Bandits

- `npc_brain.gd::_bandit` (stalk at night, `_prey_for` any villager with 3+ coins away from guards), robbery through
  combat (`fight`, `world.gd::witness`/`raise_alarm`), `_bandit_market` (OD-16 a, EQ-20: by day a bandit with
  `bandit_spend_min` coins buys food from a seller no guard stands near), `band_eat` (FSE-B06: the band eats only its real
  stores), guards recover lying loot to the treasury (`_loot_to_recover`, `_guard`).

### 1.15 Accounting

- Coins: `world.gd::total_coins` (purses, treasury, reserved coins of quests, manor jobs and contracts, loot, tills) plus
  `coin_sources` (what crossed the village boundary). Goods: the census (`tests/census.gd`; on the Expansion 18 branch
  moved to `settlement/holdings.gd`). `World.stats` is a diagnostic running ledger (made_, used_, eaten_, spoiled_,
  exported_, imported_, gov_*), not saved. The Build 17 long runs show 0 coin leak and no item leak on four seeds
  (`docs/build17/MIN_G_LONG_RUNS.md`).

---

## 2. The design's principles against today's code

| Principle (design s.1) | State | Where it holds | Where it does not |
|---|---|---|---|
| **Needs drive behaviour; no universal job-specific action order** | **Partly met** | Hunger, injury and food days trigger eating, resting, provisioning, relief and day labour (`decide`, `_plan_eat`, `_plan_provision`, `_day_labour`); OD-19 reserves weigh necessities against other spending (`necessity`, `can_afford`); contracts weigh household needs and obligations (`contracts.gd::evaluate`); building is a household goal (`construction.gd::_goal`). | `decide` is a fixed priority list; each trade's routine is a hard-coded action order (`_smith`, `_cook`, `_carpenter_*`): exactly the "make axes first" pattern the design's anti-patterns name (s.19), visible in `_smith`'s "the manor's orders first". Needs have no urgency value that competes across uses of money and time; goals do not persist except building and contracts. Skilled trades never change by choice. |
| **Prices are offers** (scarcity, urgency, opportunity cost, affordability) | **Partly met** | Asking prices fall with stock and local supply (`sell_price_at`, `local_supply`); buying prices fall as the buyer fills (`buy_price_at`); urgency raises the stall ceiling a step (`business.gd::ceiling`); CON-01 negotiates price, quantity and deadline with counters and judges the price against alternatives and inputs (`contracts.gd::evaluate`, `price_terms`). | Ordinary trade is take-it-or-leave-it at a formula price: no bid, no counteroffer, no expiry, no partial fill by negotiation, no reference/advertised/settled distinction (design s.5). A buyer's urgency, cash or penalties do not move what it offers; a seller's labour and opportunity cost do not set its ask outside contracts. Manor, caravan and relief pay formula prices (`buy_price`, 0.8 x value, `sell_price`). |
| **Accepted orders are obligations** (reservations, credit, contracts) | **Partly met** | CON-01/02: buyer's coins set aside, seller's owed stock held back from sale (`held_for`), delivery and payment unit by unit, lapse and death rules, regard loss on default. Quests and manor jobs set wages aside. | Reservation covers only the seller's finished goods (`held_for`), not the inputs the seller will need (the smith's iron and coal for an axe contract can still be spent elsewhere). The manor's tool advances (`_support_trades`) are paid outright: when an order lapses after `manor_order_days` (`_deliver_orders`) the advance stays with the smith with no repayment, default record or regard change. No credit record exists (no lender, principal, repayment or security). No renegotiation after acceptance (OD-29). |
| **Bounded knowledge** | **Not met** (one partial exception) | Prices react only to supply within a radius (`local_supply`); MIN-C clues and assays are known by whoever samples or is told (`prospecting.gd`); villagers keep 8 lines of memory (`NPC.memory`, `remember`). | Every search for a buyer, seller, vendor or job reads the whole village (`_buyer_for`, `_seller_of`, `_vendor_with_food`, `_grain_seller`, `tool_price`, `job_market`'s village-wide average pay, `_wanted_ores` reading the smith's pack, `contracts.gd::_order` asking every villager in turn). The manor, the caravan and relief act on exact village totals (`village_day_food`, `local_tool_need`, `_relief_offers`). Design s.13: "Never grant every NPC global market knowledge." |
| **Organic safety levers, no hidden rescue** | **Partly met** | Every lever moves real coins and goods from someone who has them: manor tools and relief from the treasury above a floor (EQ-19, TREAS-01), bandit spending (EQ-20), caravan purchases from a finite purse, relief bought from real stores. Failure stays possible: missed meals, unemployment, culled herds, worked-out seams (`MIN_G_LONG_RUNS.md`). | The levers are rules triggered by global thresholds, not decisions by actors with knowledge and risk (design s.10: "who noticed the problem, what did they know, why act ... what happens if it fails?"). The caravan's daily allowance creates coins by schedule (CARAVAN-TMP, labelled temporary; Expansion 18 plans its removal). A worked-out miner is moved to manor hand automatically (`_miner`), and the manor is the employer of last resort through the job market; both are paid only while the treasury can, so they are bounded, but they are rules rather than offers. |
| One ledger, one inventory (design s.1, s.19) | **Met** | `World.trade`, `transfer`, `Contracts._pay_units`, `ManorWork.consign` move real holdings; `total_coins` and the census close; reservations are counted holders. | `World.stats` is diagnostics only; nothing yet records ownership separately from custody (design s.3 Ledger: "custody, ownership"), apart from contract escrow and manor lots. |

---

## 3. Cross-system dependencies with Expansions 18 and 19

Read-only from `origin/wip/expansion18-preparation:docs/expansion18/DESIGN.md` (and `CARAVAN_REPLACEMENT.md`) and
`origin/wip/expansion19-preparation:docs/expansion19/DESIGN.md`. Both are prospective and off in the game.

### 3.1 Shared interfaces (what Expansion 20 should build on, not duplicate)

| Interface | Owner today | What Expansion 20 needs from it |
|---|---|---|
| **One settlement primitive** for goods and coins: `World.trade`, `World.transfer`, `Contracts.deliver/_pay_units`, `ManorWork.consign` | Build 17 | LE-02's settled transactions. Offers, bids and reservations are records; only these primitives move holdings (design s.19: "Treat bids as completed sales or reservations as consumption" is forbidden). |
| **The Contract record** (`contracts.gd`) | Build 17 (CON-01/02) | LE-01's Contract is this record, extended (renegotiation, deposit, breach, input reservations, credit terms). Expansion 18's couriers and formal agreements are to become CON-01 contracts at its reconciliation (X18 DESIGN s.11). |
| **Party references** `player`, `npc:<id>`, `manor`, `hh:<id>` (`World.npc_ref`, `hh_ref`, `party`, `ref_name`) | Build 16-17 | LE-01's Actor identity. Expansion 18 needs household and off-map party refs in CON-01 (Q18-13 notes); the design needs workshops and businesses distinct from households (s.3, OD-LE-07). One scheme for all three. |
| **Holdings census** (`settlement/holdings.gd`, moved from `tests/census.gd`) and `World.total_coins` | Expansion 18 | LE's accounting tests (design s.16 "Accounting") and every new holder (offers' escrow, deposits, credit) counted once. |
| **Parties of the village** (`settlement/report.gd::parties`: each trader, household, villager without a household, the manor; each purse and good in exactly one party) | Expansion 18 | A ready list of economic actors for LE-01, already proven to partition the village's holdings. |
| **Regional market** (`settlement/regional.gd`: demand, supply, willingness to pay, `to_contract_offer`) and **routes and carriage** (`routes.gd`, couriers `couriers.gd`, booths) | Expansion 18 | LE-05's regional links and LE-04's merchants. Carriage is a separate paid service (Q18-10, Q18-12) as LE needs. |
| **Caravan replacement** (SET-C, `CARAVAN_REPLACEMENT.md`: off-map settlements with finite purses, trade rounds, the allowance removed) | Expansion 18 | The design's "Caravans buy or sell when expected margin covers acquisition, transport and risk" (s.12). Expansion 20 must extend this, not replace the caravan a second time (X18 PROGRESS item 7: "keep one merchant model"). |
| **Workforce experience** (`settlement/experience.gd`, per person and industry, from hours worked) and capability pay/output multipliers (Q18-9, Q18-11) | Expansion 18 | LE-03's job choice ("skills, ... retrain", design s.7): a worker's own experience is a real input to expected return. The multipliers act on base pay and work time only and never on negotiated prices or contracts (X18 s.9a rule 7), which is compatible with offers. |
| **Information sharing by meetings** (`JudgmentStore.meet/tell`, word of mouth only through shared hours; confidence from Relations regard; no hop limit; per-meeting and daily budgets) | Expansion 19 | LE's bounded knowledge (design s.13: "Social information may spread through conversations and relationships when those mechanics exist"). Economic news (prices, suppliers, defaults) should ride the same channel, not a second gossip system. |
| **Decision weighting** (`JudgmentWeighting.choose`: live code supplies feasible candidates and factors; judgment is one weighted factor) | Expansion 19 | LE's choices of supplier, buyer, employer, borrower (design s.9 row "Relationships / Judgment: trust, history, debt, reputation -> choose partners, price risk, lend"). The CON-01 module header already names `price_terms` as the plug for judgment. |
| **Events as facts** (`JudgmentStore.publish`, catalog in `judgment.json`; `trade_fair`, `trade_cheat` listed, not wired) | Expansion 19 | Design s.3's Event record and s.14's event triggers. A default, a lapse or a broken advance becomes a judged fact. |
| **Seeded hash draws** instead of `World.rng` (`JudgmentMath.hash_ints`; also `decay.gd`'s draw) | Expansion 19, Build 17 | LE's randomness, so turning it on does not shift every other random stream (design s.14 "deterministic RNG use"). |

### 3.2 Conflicts and overlaps to resolve (not resolved here)

1. **A second ledger.** Expansion 18's `SettlementLedger` keeps journals and books for each party (`balanced()`), and the
   design lists a "Ledger" record (s.3). The design forbids "a second authoritative ledger or inventory service" (s.19).
   Proposal: the World's holdings stay the only truth; journals are derived views or confined to off-map parties (which
   have no World holdings). Decide at the Expansion 18 reconciliation, before LE-01.
2. **Two pricing models.** Expansion 18's regional market prices by formula (willingness to pay up to
   `scarcity_premium` x value) and allocates centrally (neediest buyer first, cheapest delivered cost), and the live
   caravan allocates by `caravan_line_need` (EQ-22). The design wants prices as offers set by each actor's own valuation
   and bounded knowledge (s.5, s.13). LE-02 needs one bid/ask model that the regional rounds also use; otherwise the
   village and the region trade by different rules.
3. **Two signing paths.** Build 17's `Contracts.face_to_face`/`npc_sign` (Q18-13 for local parties) and Expansion 18's
   `formal_contracts.gd` (`FormalAgreements`, notaries) both implement Q18-13. X18 plans to fold its special deliveries
   and formal goods contracts into CON-01; Expansion 20 should then extend only `contracts.gd`.
4. **Household versus business money.** ECON-P3 ("Household vs business money, quotes follow money, stock days, market
   hire wages, `World.spendable`") is a BLOCKED proposal targeted at Build 18; OD-LE-07 (restricted advances and
   business/household account separation) is the same question in Expansion 20. One decision should settle both.
5. **Regard as trust, harm and default.** A lapsed contract lowers regard (`contracts.gd::_lapse`); Expansion 19 uses
   regard as trust in a teller (Q06) and records the coupling as its conflict 4. If a default also becomes a judged
   `trade_cheat` fact, the same breach would count twice (regard and judgment). Decide the one channel with OD-LE-05/13.
6. **Instant spread versus word of mouth.** `Relations.harmed` spreads instantly to kin and friends (X19 conflict 1). If
   LE's economic memory (OD-LE-10) uses meetings only, the two rules must not mix for the same event.
7. **Capability pay versus wage offers.** X18 multiplies manor wages (quarry, mend) and the harvest hand's wage by the
   capability pay factor. If OD-LE-03 makes wages negotiated offers, the multiplier must act on the employer's base
   offer, never as a fixed wage (X18 s.9a rule 7 already says it touches no negotiated price).
8. **Caravan ownership.** CARAVAN-TMP is "Replaced by demand-driven trade in EXP-B" (Expansion 18). LE-04's "merchants"
   and LE-05's "regional links" must start from Expansion 18's replacement.
9. **Performance budget shared with gossip.** Expansion 19's open concern is the gossip frame cost (p99 1.41 ms, p99.9
   3.67 ms at 500 people). Economic knowledge on the same channel adds content to it; OD-LE-15's targets must include it.
10. **Save versions.** Expansion 18 writes optional keys `x18_settlements`, `x18_experience`; Expansion 19 `judgment`;
    none bumps `SAVE_VERSION` (17, Build 17's). Expansion 20 adds needs, offers, knowledge and credit: it must follow
    the same optional-section pattern while prospective, and take its version number at integration after 18 and 19.

---

## 4. Build 17 findings that bear on the Living Economy (CANDIDATES, not assigned)

The owner's directive: "Consider unresolved findings from Build 17 as potential backlog candidates, but do not
automatically assign them to Expansion 20." Each is listed with the Living Economy mechanism it touches; none is
claimed for Expansion 20. Under WDR-022 most are economic outcomes, not defects.

| Candidate | Evidence | Mechanism today | Living Economy bearing | Possible other home |
|---|---|---|---|---|
| **Food affordability and missed meals** | `MIN_G_LONG_RUNS.md`: missed meals for want of money 606 / 879 / 2,012 / 5,417 on seeds 1-4 at day 365, food days 55-204 (food exists; coins do not reach it); one starvation death on seed 2 | `_plan_eat` buys at posted prices; family tab `_payer_for`; relief only under `relief_trigger_days` (`_relief`) | Household budgets (LE-03), prices that fall when demand cannot pay (LE-02), kinship support and charity (OD-LE-12), wages (OD-LE-03) | FSE work in a later build; a measurement first (who misses, with how many coins in the household) |
| **Unemployment** | 9 / 21 / 6 / 30 unemployed of 83-104 adults at day 365 | `seek_work` picks among six jobs by village-wide average pay; skilled trades only by succession; `tool_short` | Occupational response (design s.7: side work, retraining, borrowing a tool), job choice from known opportunities (LE-03), business founding (OD-LE-04) | Expansion 18's experience model (retraining is experience in another industry) |
| **Chicken die-out** | Chickens died out early on seeds 2 and 3 (63 and 56 eggs against about 1,700) | `_keeper` feeds from the keeper's wheat; feed bought from the keeper's own coins (`npc_brain.gd` around `feed_want`) | Input procurement against expected returns, supplier credit (LE-03, LE-04) | FARM-08 follow-up (the herd questions below) |
| **Cattle keeper's herd costs more than it earns; the 4-day trough; unsold milk; stalled cheese** | `docs/design/FARM08_YIELD_COMPARISON.md` (staging): a cow eats 4 wheat a day (8 coins at the floor) and earns about 4 in milk; a cutting fills the trough with a fixed 4 days of feed while seasonal fields are cut 3-6 days apart; 70 of 176 milk sold, up to 27 held unsold at 0 coins, cheese making stalled (`used_milk` 33 from day 21 to 40); 930-1,410 milk unsold at day 365 in surviving herds; owner questions 5.5 (granary sales to keepers, trough rule, pasture or hay, herd economics) open; crop allocation (`take_crop` to the finisher) under review | Fixed `BUYS` caps (the cook buys `milk` to 12, the tavern `cheese` to 8), `_cook`'s fixed recipe order, the trough's fixed 4-day rule, posted prices | Demand saturation answered by price falling and by substitutes (LE-02); a producer sizing its herd to expected margin (LE-03); feed bought on credit or from the granary by an organic lever (OD-LE-05, OD-LE-06) | FARM-08 owner questions (5.5) and FARM-CROP-01, which are farming decisions in their own right |
| **Resource depletion** | 26-28 seams worked out a seed by day 365; Build 15 runs: iron and coal gone by day 10-20 | Finite deposits; `_caravan_imports` / `_caravan_stone` when low; prospecting and pits (MIN-C..F) | "Prices cannot create exhausted ore seams" (s.11): higher bids motivating prospecting, imports, substitution (OD-LE-08) or migration; the coal-exhaustion and mine-closure scenarios (s.15) | Expansion 18 regional supply (imports from regions that hold ore) |
| **economy_sim reporting defect** | `MIN_G_LONG_RUNS.md`: `economy_sim.gd` counts every note containing " marks out " as a building site started, so a staked open pit counts as a site (seeds 2 and 3); harness only, no game effect; one-line fix not applied | `game/tests/economy_sim.gd` note parser | LE-06 relies on the harness's reports; it should be fixed before any LE long run | Build 17 maintenance or any branch that next touches the harness (the lead's choice) |

---

## 5. What Expansion 20 adds, per system (design s.9 against the code)

| System | Today | Expansion 20's change (design) | Stage |
|---|---|---|---|
| NPC brain | Fixed priority list and per-job routines (`decide`, `_plan_job`) | Needs with urgency choose among actions; trade routines become recipe choices weighed by value | LE-01, LE-03 |
| Households | One OD-19 reserve horizon; purses not pooled; richest pays | Budgets over competing uses; borrowing, selling assets; account rules (OD-LE-07) | LE-03 |
| Employment | Six-job market by village averages; succession for trades; treasury wages | Vacancies and wage offers by employers; retraining; side work; leaving (OD-LE-03, OD-LE-04) | LE-03 |
| Production | Fixed stock caps (`BUYS`), fixed recipe order | Production chosen by expected value; inputs reserved for accepted orders | LE-03 |
| Inventory and ledger | One holdings model, census, `total_coins` | Reservations and custody vs ownership as records; no second ledger | LE-01, LE-02 |
| Construction | Bills of materials, hired helpers, sellers keep for sites | Builders bid for materials and labour; sites pause or finish by funds | LE-05 |
| Markets and prices | Formula asks and buys; no bids; contracts negotiate | Bids, asks, counteroffers, expiry, partial fills, atomic settlement | LE-02 |
| Contracts | CON-01/02 with OD-29 defaults | Renegotiation, deposits, breach rules, input reservations, credit terms (OD-LE-05, OD-LE-13) | LE-01, LE-04 |
| Manor | Rule-driven tax, relief, tool support, granary, public works | A constrained actor that lends, commissions, procures or refuses with its own knowledge (OD-LE-06) | LE-04 |
| Caravan | Allowance-funded planner | Merchants trading for margin (on Expansion 18's regional model) | LE-04, LE-05 |
| Mining, forestry, farming, wildlife | Finite sources; imports when low | Prospect, conserve, import or stop by value | LE-05 |
| Bandits | Spend at the market, eat their stores, loot recovered | Trade, hoard, fence, lose (OD-LE-09) | LE-05 |
| Knowledge | Global searches | Known suppliers and offers with source, age, confidence (OD-LE-10), spread through Expansion 19's meetings | LE-01 |
| Saves | `SAVE_VERSION` 17 | Needs, offers, knowledge, commitments, credit, RNG state saved (design s.16 "Persistence") | LE-01 onward |

---

## 6. Open owner decisions and the stages they block

All OD-LE decisions are BLOCKED (open) on the register except OD-LE-01 (answered: Expansion 20). Some already have a
partial answer in an earlier owner decision; that is noted so nothing settled is asked again (CLAUDE.md section 0).

| Decision | Blocks | Earlier owner decisions that bear on it (not a substitute for the answer) |
|---|---|---|
| **OD-LE-02** market board, direct negotiation or hybrid; visibility | LE-01 (the Offer's visibility field), LE-02 | CON-01 negotiates directly; stalls and storefronts are physical places of sale; X19 Q10 (no numbers in normal play) |
| **OD-LE-10** economic rumour, memory persistence, reliability | LE-01 (the Knowledge record), LE-02 | X19 Q06 (trust from regard), Q07 (meetings only, no hop limit), Q11 (permanent memories) |
| **OD-LE-07** restricted-use advances; business/household account separation | LE-01 (the Actor and its accounts), LE-03, LE-04 | ECON-P3 (same question, BLOCKED, Build 18); EQ-19's next action ("earmark advances for materials") |
| **OD-LE-13** contract cancellation, penalties, death of a party | LE-01 (the Contract's breach and renegotiation fields), LE-04 | OD-29 provisional defaults (no money penalty, lapse returns coins, death ends the contract, no renegotiation after acceptance) |
| **OD-LE-15** performance and population targets | LE-01 (data-structure budgets), LE-06 gate | CLAUDE.md section 8 (budgets unset); X19's proposed frame budgets; OVN-01 gate practice |
| **OD-LE-11** speculation, hoarding, deliberate manipulation | LE-02 | None |
| **OD-LE-14** player intervention and visibility of market decisions | LE-02 (what the player sees and can do), LE-07 (wiki) | X19 Q10; PAR-01 (the player trades by the villagers' rules) |
| **OD-LE-08** barter, rental, repair, resource substitution | LE-02 (barter settlement), LE-05 | X18 cooperation excludes barter until Q18-5; OD-16 (d) "the manor lends axes" not chosen |
| **OD-LE-03** wages, rents and service contracts in the first release | LE-03 | CON-02 (service contracts approved for dig and survey); Q18-12 (courier fees and negotiated special deliveries); property rents exist |
| **OD-LE-04** business founding, partnerships, ownership, inheritance | LE-03 | Stalls built by anyone (STALL-01..06); inheritance through the family graph (B8-029) |
| **OD-LE-12** charity, kinship support, communal relief | LE-03, LE-04 | Relief (INT-024, TREAS-01, FSE-17); the family tab |
| **OD-LE-05** loan interest, collateral, default, collection | LE-04 | OD-16 (b) "lends to the smith against future output" (implemented as an advance, EQ-19) |
| **OD-LE-06** permissible manor interventions and political authority | LE-04, LE-05 | OD-16 (b), TREAS-01, OD-19; Expansion 21 Politics (VP-01) follows |
| **OD-LE-09** bandit market participation, regional trading limits | LE-05 | OD-16 (a) bandits spend at the market (EQ-20); Q18-10 (anyone may buy from another settlement) |

**Order to ask them (agent proposal):** the five that shape the shared records first, then by stage:
1. OD-LE-02, OD-LE-10, OD-LE-07, OD-LE-13, OD-LE-15 (LE-01);
2. OD-LE-11, OD-LE-14, OD-LE-08 (LE-02);
3. OD-LE-03, OD-LE-04, OD-LE-12 (LE-03);
4. OD-LE-05, OD-LE-06 (LE-04);
5. OD-LE-09 (LE-05).
LE-06 and LE-07 need no new policy beyond OD-LE-15 and the release authorization in force.

---

## 7. Proposed implementation sequence (agent proposal; nothing starts before its decisions and gates)

Placement: Expansion 20 after Build 19 (OD-30, OD-LE-01). The design asks for a read-only audit first and "Do not rewrite
the economy until the standalone build placement and material gameplay-policy questions are approved" (s.21). Under the
2026-10-22 directive this branch does planning only. The sequence below is for when implementation is authorized.

| Stage | Scope | Builds on | Depends on Expansion 18 | Depends on Expansion 19 | Gate (design s.17) |
|---|---|---|---|---|---|
| **LE-01** Shared records | Actor (party refs incl. households, workshops, off-map parties), Need (urgency, deadline, substitutes), Offer (bid/ask, expiry, visibility), Knowledge (source, age, confidence), Contract (CON-01 extended), Reservation (inputs earmarked, owned and located), Credit, Event; persistence as an optional save section; no behaviour change (shadow) | `contracts.gd`, `World` refs, `necessity` | Party list (`report.gd::parties`), census (`holdings.gd`), one ledger decision (3.2 item 1), household/off-map refs in CON-01 (Q18-13 notes) | Event catalog and `publish`; meetings as the knowledge channel; hash draws | Unit tests and persistence |
| **LE-02** Bids, asks, settlement | Each actor's maximum and minimum from its own valuation; counteroffers, partial fills, expiry, atomic settlement through `World.trade` / `Contracts._pay_units`; offers replace the formula price for NPC-NPC trade behind a switch; oscillation damping (lifetimes, switching costs) | `sell_price_at`/`buy_price_at` kept as reference prices | Regional market to use the same bid/ask model (3.2 item 2) | `JudgmentWeighting` as one factor in choosing a counterparty | Ledger-safe multi-actor trades |
| **LE-03** Production, jobs, budgets | Recipes chosen by expected value; input reservations for accepted orders; household budgets over competing uses; job choice from known vacancies and wage offers; retraining; no tool-order traps (`tool_short`, `_get_tool`) | `seek_work`, `evaluate_household`, `BUYS`/`wants` | Workforce experience as a skill input; capability pay as a factor on base offers | Work acceptance and hiring adapters (`work_accept`, `hire_choice`) | No tool-order traps; real opportunity response |
| **LE-04** Finance, merchants, manor | Credit records (manor loans, supplier credit, advances with or without restriction); manor as a constrained actor with its own knowledge (tax, relief, support, procurement as decisions); merchants trading for margin | `_support_trades`, `manor_orders`, `_relief`, `reeve_day` | Caravan replacement (SET-C) and couriers as the merchant and carriage model | Trust and reputation in lending and supplier choice | Costs, default and refusal paths |
| **LE-05** Construction, ecology, mining, bandits, regions | Builders bid for materials and labour; prospect/import/stop by value; bandits trade, hoard, fence; regional arbitrage | `construction.gd`, MIN-A..F, `_bandit_market` | Routes, regions, SET-E (several settlements, targeted 20+) | Judged events for bandit dealings | Integration matrix covered (design s.9) |
| **LE-06** Long runs, determinism, profiling | Multi-seed long runs, matched fingerprints, profiling against OD-LE-15 | `economy_sim.gd` (fix the reporting defect first), determinism gate | Shared census | Shared frame budget with gossip | No errors or leaks; legitimate failure allowed |
| **LE-07** Release readiness | Platform builds, release packet, wiki | `release.yml` | — | — | All mandatory release gates green |

What can be prepared before Builds 18 and 19 are complete, without gameplay implementation (agent proposal): the LE-01
record schemas as a design note checked against CON-01's record and Expansion 18's parties; the decision brief for the
five LE-01 decisions (options, recommendation, economic effects); a measurement plan for the section 4 candidates using
the existing harness. Each needs the lead's go-ahead.

---

## 8. Risks

### 8.1 Performance

- Today's searches are linear in the population and run per decision: `_buyer_for` (cached roles), `_seller_of`,
  `_vendor_with_food`, `_grain_seller`, `tool_price`, `_relief_offers` (every villager and household per hungry
  household), `_sale_stock` (every villager per item, called from `stock_family_chest` for each food item: quadratic in
  the population), `business.gd::ceiling` (every villager per need), `contracts.gd::_order` (proposes to every villager
  in turn, each running `evaluate`). The population grows to 133-173 in a year (MIN-G).
- An offer book with per-actor valuation multiplies this unless it is event-driven and indexed (design s.14: "Prefer
  meaningful events plus bounded periodic reevaluation over population-wide scans"; "local supplier indexes"). Bounded
  knowledge helps: each actor evaluates only the suppliers it knows.
- Economic news on Expansion 19's meeting channel adds to its open frame-cost concern (3.2 item 9).
- No budgets exist (CLAUDE.md section 8; OD-LE-15 open). LE-01 should not fix data structures before OD-LE-15.

### 8.2 Saves

- `SAVE_VERSION` is 17 (Build 17); `SaveStore.MIN_VERSION` 14; migrations through `SaveTransfer.MIGRATIONS` with fixture
  tests (CLAUDE.md section 7). Expansions 18 and 19 add optional sections without bumping. Expansion 20 adds persistent
  needs, offers, knowledge, reservations, credit and goals (design s.4 "Persist goals through saves"), and its RNG state.
- Risks: three expansions adding sections out of order; an older save with open contracts (OD-29 records) meeting
  extended contract fields; reservations or credit with no counterpart after migration. Mitigation: one versioned
  section per expansion taken at integration, defaults that reproduce Build 17 behaviour, fixture saves from Builds
  17, 18 and 19.

### 8.3 Determinism

- `World.rng` is shared by decisions (`_wanted_ores`'s 15% copper draw, `_cook`'s ale draw, `_meal_choice`'s cheese
  treat, `wander_cell`, newcomers' names). Any added draw from it shifts every later draw and changes fingerprints far
  from the cause. Expansion 19 and `decay.gd` avoid this with seeded hash draws; Expansion 20 should do the same.
- Iteration order: offers and needs must be processed in a stable order (ids), as contracts and relief do today
  (`contracts.gd` "kept in id order", `_relief`'s sort).
- Feedback loops: adaptive prices can oscillate (design s.5); the determinism gate checks replay, not stability, so
  oscillation needs its own measure in LE-06.

### 8.4 Design risks

- Rewriting the per-job routines touches almost every gameplay system; a feature switch with matched-seed comparisons
  (as Expansion 19 did) keeps Build 17-19 behaviour reproducible while LE stages land.
- Hidden rescue can re-enter through defaults: a "minimum price" or "guaranteed buyer" written to keep a test village
  alive would break WDR-022 and the design's anti-patterns (s.19).

---

## 9. Proposed register changes (for the lead; not made here)

1. **LE-00**: add `branch` `wip/expansion20-preparation`, the commit of this document, `implementation`
   "docs/expansion20/LE00_ARCHITECTURE_AUDIT.md (read-only audit)", and a history line. Status: the audit part is done;
   the gate "Owner decisions registered; no guessed policy" is met for registration (OD-LE-02..15 are registered); keep
   LE-00 ACTIVE DEVELOPMENT until the lead accepts the audit, then COMPLETE AND VERIFIED with this document as evidence.
2. **OD-LE-02..15**: add `blockers`/`next_action` naming the stage each blocks (section 6) and the earlier decisions that
   bear on it, so the owner sees them together; no status change.
3. **LE-01..LE-07**: add `depends_on` (the OD-LE decisions of section 6; PROS-18/SET-C for LE-04 and LE-05; PROS-19 for
   LE-01's knowledge and LE-04's lending) and the gate column of section 7.
4. **ECON-P3** and **OD-LE-07**: cross-reference as the same question (household versus business money), one decision.
5. **CARAVAN-TMP**: note that Expansion 20's merchants extend Expansion 18's replacement (no second caravan model).
6. **Section 4 candidates**: record them, if the lead wishes, as CANDIDATE notes on EXP-D (not children, not assigned),
   each with its other possible home.
7. **economy_sim reporting defect** (" marks out " counts open pits as sites): it has no register id in this branch's
   view; the lead may give it one for whichever branch next touches the harness.

---

## 10. Wiki and documentation

- Player-facing wiki: nothing changed, none needed (no feature implemented; the Living Economy is not in the game).
- Developer documentation: this file is new. No other document was edited; `docs/EXPANSION_ROADMAP.md`'s Living Economy
  section and the register are the lead's on staging.
