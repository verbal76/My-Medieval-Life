# Business ownership, paid employment and economic expansion (Build 25)

Records: B25-BIZ-OWN and its children B25-BIZ-D1..D5 (owner, 2026-11-01), extending B25-BUSINESS-IMPL, EMP-PERM-01 and
ECON-P3; answers OD-LE-04 and OD-LE-07 for villager businesses. Source, verbatim:
`docs/directives/2026-11-01_business_ownership_employment_final_decisions.md` (on `wip/requirements-control`). Branch
`wip/b25-bizown` from `8d71c5e`. This document replaces the open questions Q1-Q5 of `BUSINESS_FOUNDING.md` section 8.

Principles kept throughout: WDR-022 (a business may fail; no hidden rescue), player/NPC parity (one rule for both),
conservation (every coin moves purse to purse, till to purse or through `EconTransactions`; every good through
`World.transfer`, `World.trade` or `World.work_craft`), determinism (seeded RNG, sorted iteration), save compatibility
(optional keys only; `save_version` unchanged), multiplayer (player verbs through `World.mirror` and `NetActions.VERBS`),
DCR-01 (classification in `docs/DECISIONS.md`).

Owner requirements are the five decisions; every number below marked PROVISIONAL is an agent balancing value
(`game/data/balance.json`), not an owner requirement.

## 1. Architecture audit and reuse plan (Milestone 1)

| Concern | What exists (reused) | What is extended | What was missing (added) |
|---|---|---|---|
| Business money (D1) | `BusinessMoney` (ECON-P3): storefront and counter tills, the morning settlement (necessity first, owner pay `payout_share` above `till_reserve`, top-up only from `World.spendable`), TILL-D1 `keep_till`, escheat; player stall and shop tills with deposit and withdraw (`Business`); `EconTransactions` till refs (`front:`, `counter:`) when the Living Economy is on; `World.total_coins` counts `Business.tills()` | the same till record and settlement now also on an open venture (`building.venture.till`, ref `venture:<building id>`); owner invest and withdraw for any till record; the venture's tills counted in `Business.tills()`; `EconActor`/`EconTransactions` know `venture:` | business goods bookkeeping (`venture.goods`), the business funding its materials (`Ventures.budget`, the `buy_from` act) and receiving its sales (`BusinessMoney.after_trade` with the item) |
| Paid workshop employment (D2) | the venture's "hands" (B25-BUSINESS-IMPL: independent craftspeople with the keeper's leave, `World.permit`); `Employment` (EMP-PERM-01) wage and owed-goods model; `JudgmentLive.work_refusal` (the worker's consent); the labour market's suitability order (`NPCBrain._hire_skilled`: skill, experience, need) | hands stay exactly as they were (independent); `Employment` takes a business employer (`venture:<id>`) whose wages come from its till and whose employees' sales and materials go through the till | the venture's own hiring (`Ventures._hire`) |
| Unfinished construction (D3) | `World.cancel_site` (materials back, ground kept, no money), the player's "give it up" in the build window, `Construction.end_contract` | the venture being set up gets an abandonment path through `cancel_site` | the abandonment triggers for villagers (`Ventures._review_setup`) |
| Permanent employment (D4) | `Employment` (miner only), `NPCBrain.seam_steps`/`work_mine`, the woodcutter's felling (`World.fell`, `work_felled`), `FarmPlots._plan_on` (the church plot already lets non-owners work a plot into another store), `Construction.plan_helper` (carrying the employer's goods to a site), `BusinessWorks`' crafting into a store (`work_craft` on a store's inventory), `Business.hire` (counter attendants) | `Employment` becomes the one framework: a profession table (`Employment.WORK`) maps a role to the existing work behaviour; wages from the labour market (`market_wage`) | resignation; refusal when another obligation holds; per-role refusals |
| Buying and selling (D5) | `Property` ownership (`World.set_owner`, `unit`, estates), the land office's valuation (`Property.price_of`), `World.deal_price` (Trading pulls the price), `JudgmentWeighting` profile `business_found`, TILL-D1 `keep_till` | `Ventures` offers, sales and purchases; `refusal`/`_consider` tries buying a listed workshop before building | the sale offer record (`building.sale`), detaching a module from its estate on a sale (the smallest separation of business from residence) |
| Expansion and careers (D5) | founding (`Ventures`), `NPCBrain._change_job`, `Skills`, `WorkExperience`, career ambition (`JudgmentAspiration`) | a keeper with business money may found or buy another workshop paid from the business till | listing a workshop nobody of the household works any more |

### 1.1 The two-shop investigation (D5 F)

Finding, from the code and a probe on seed 1 (Build 25 source `8d71c5e`), recorded as a test in
`game/tests/business_ownership_test.gd` (`test_no_shop_cap`):

- **No coded ownership limit exists.** Nothing counts the player's shops. `Business.open_refusal` asks only: a room the
  player holds, a counter in it, no shop open there already, the first licence. With four properties built the probe
  opened a shop in each of three storerooms and in a standalone smithy (four shops).
- **The market pitch is one per player**: `Business.rent_refusal` "You already rent a stall." (a pitch is the manor's
  market place; 4 pitches, 2 kept for the tailor and the barber, so 2 free at the start of seed 1). This is a market rule of
  the manor's pitches, not a shop limit.
- **Initially available properties: exactly two.** At the start the player holds nothing, and the land office's list
  ("The manor offers", `Property.market`) shows only the two plots the map surveys (`plot0`, `plot1`, village.json
  `plots`); there are no empty houses for sale on a new world. More ground is bought on the spot from the Build menu's
  "Choose a place" (`Construction.place`, free placement since Property phase 2), which the land office window did not say.
- **One room of each kind per property**: `Construction.module_refusal` "The property already has a storeroom." A shop
  needs free floor for its counter: a house's own room is furnished (no cell takes a counter on a built house), so the
  shop room is a storeroom module or a workshop.

So the apparent limit came from the number of initially offered properties (two surveyed plots, one shop room each) and
the land office window not pointing to the Build menu for more ground: an availability and interface limitation, not a
coded maximum, and not one of an older build (shops arrived after free placement). Nothing is capped; the land office
window now says where more ground comes from (Milestone 6).

## 2. Decision 1: separate business and household finances

- **The account.** Every operating business has one till record: the player's stall and shop (`Business`, unchanged),
  a household storefront (`front`), a trade counter (`counter`) and now an open villager venture (`building.venture`:
  `till`, `earned`, `paid`, `costs {materials, wages, premises}`, `invested`, `drawn`). One settlement rule for them all
  (`BusinessMoney._settle`), in building-id order each morning. No second ledger: the till is in the building's own dict,
  counted by `Business.tills()` in `World.total_coins`.
- **Revenue belongs to the business.** A sale (`World.trade`) by a venture's keeper or paid employee of units that are the
  business's goods (`venture.goods` for the keeper, the employment record's `owed` for an employee) moves the price of
  those units from the seller's purse to the till at once (`BusinessMoney.after_trade`, now told the item and quantity).
  Goods are the business's when they were bought with its money or made at its stations by its people (the `craft` act).
- **Expenses are paid from business funds.** A venture worker's purchase of an input of their trade's recipes is funded
  from the till (`Ventures.budget`, `NPCBrain.buy_qty` and the `buy_from` act): the till's coins go to the worker for the
  purchase and back if it fails; the units bought are the business's goods. Wages of its employees come from the till.
  A business cannot spend money it does not hold: no till money, no business purchase and no wage (the employee leaves).
- **Owners invest and withdraw** under the existing rules: on opening, the founding household invests working capital
  (`ventures.working_days` of its costs, as far as its spendable coins allow, PROVISIONAL) into the till; each morning the
  existing settlement applies (necessity first, PAR-02A; the owner's pay; a top-up only from coins above the necessity
  reserve, so a struggling business never draws the household's protected reserve); `BusinessMoney.invest`/`withdraw`
  move money by choice. The player's stall and shop keep `Business.deposit`/`withdraw`.
- **Failure has real consequences.** A business without money buys no materials, makes nothing, pays no wage (its
  employees go), then closes when idle (`close_idle_days`); its till goes to its household on closing (TILL-D1), the
  workshop stays the household's to use, sell or keep.

## 3. Decision 2: paid employees versus independent craftspeople

- **Independent craftsperson (unchanged):** a venture's hand (`venture.hands`) works the keeper's benches with leave,
  with their own materials, and keeps their own sales. No wage; nothing is routed to the till.
- **Business employee (new for ventures, `Employment`):** a record `{npc, employer: "venture:<id>" | player ref, role,
  wage, since, paid_day, owed, account?}`. The employer pays the agreed wage each dawn (first on hiring); production
  belongs to the employer; materials are the employer's.
- **Hiring by a villager business** (`Ventures._hire`, each dawn for each open venture): only when the business needs a
  worker (its trade has work, `skilled_place.work`, and the venture's stations have room: fewer workers than station
  places), can afford one (`till >= wage x ventures.hire_runway_days`, PROVISIONAL 7), and a willing qualified candidate
  exists: adults of the trade or without a trade of their own, free of other obligations (section 5), with at least
  level 1 in the trade's skill, chosen by `_hire_skilled`'s order (skill, experience, need); the candidate agrees through
  `JudgmentLive.work_refusal`. The employee works the trade's own day (`NPCBrain._plan_job`) at the venture's stations.
- **The player's businesses** hire attendants (`Business.hire`, unchanged) and permanent employees (section 5).

## 4. Decision 3: abandoning an unfinished business construction

The existing cancellation (`World.cancel_site`) is the only mechanism: delivered materials go back into the household's
pantry (or lie in a bundle at the door), the frame comes down, the ground stays the household's (no money refund; it may
be built on later, or sold to the manor under the existing land rule). The household's construction obligation ends
(`hh.build`, `hh.venture` cleared; hired helpers' day contracts for the site end), so it can pursue housing and survival.

- Voluntary: `Ventures.abandon(h, why)`; the player's "Give it up" on their own site (unchanged).
- When completion is unreasonable (`Ventures._review_setup`, each dawn): the household has a housing need (crowded, no home,
  a couple without a home: `Construction.housing_goals`) - home first; or the site has made no progress for
  `ventures.stall_days` days (PROVISIONAL 30) and the household cannot spare the remaining materials' cost.

## 5. Decision 4: one permanent-employment framework

A profession says what work is done; employment says for whom and for what pay. `Employment.WORK` maps each supported
role to the existing work behaviour:

| Role | Behaviour | Existing system reused | Output goes to |
|---|---|---|---|
| miner | `mine` | `World.nearest_seam`, `seam_steps`, `work_mine` | employer's store (carried, `owed`) |
| woodcutter | `chop` | `World.nearest_tree`, `fell`, `work_felled` | employer's store (carried, `owed`) |
| farmer | `farm` | `FarmPlots._plan_on` on the employer's farmland | employer's store (the plot's store is the employer's) |
| builder | `build` | `Construction.plan_helper` (an unpaid day contract on the employer's site, the wage being the employment's) | the employer's building site |
| smith, carpenter, tanner, cook, stonecutter | `craft` | for a player employer: `World.work_craft` at a station the employer holds, materials from and goods into the employer's store (the `BusinessWorks` rule); for a venture: the trade's own day (`_plan_job`) at the venture's stations, money through the till | employer's store / the business |
| attendant (shopkeeper) | counter | `Business.hire` (unchanged; already a permanent wage employment) | the premises' till |

Professions without a work system of their own are not offered (no invented production).

- **Who may be employed:** a living adult of a household, not employed already, without another obligation (a manor job,
  a building day contract, a counter, an open contract as seller, keeping a venture), whose job is one without a trade of
  its own (`Construction.HIRABLE`) or the role's own trade. Their job becomes the role (`_change_job`; skills and
  experience are kept).
- **Wage:** `Employment.market_wage(role)`, the labour market's own reading: a skilled trade's `skilled_place` pay, else the
  trade's average recent earnings (`NPC.avg_income(5)`), never below the manor's posted day wage (`manor_hand_wage`, which
  hiring competition raises); with the Living Economy's negotiated wages on, `EconMarket.wage_bargain`. The flat 10 coins
  (EMP-PERM-01's provisional value) is gone; an older saved record keeps its agreed wage. The player may offer more; an
  offer below the market wage is declined; the villager may decline any offer (`work_refusal`).
- **Affordability:** the employer's account (a player's purse, or the till of a premises the player names; a venture's
  till) must hold the first day's wage; each dawn an unpaid wage ends the employment.
- **Termination:** dismissal (`Employment.dismiss`, the player's verb; a venture dismisses when its till cannot pay),
  resignation (`Employment._resign`: on their weekly morning an employee whose wage is below `employment.resign_below`
  (PROVISIONAL 0.75) of the market wage leaves; one who founds or buys a business of their own leaves), death, the
  employer gone. On leaving, the employer's goods they still carry are handed over (to the store, or to the keeper).
- **What a crafter makes for a player:** the player chooses the recipe (`make`, one their own stations make;
  `Employment.set_make` changes it), so the employer's stored materials are used only for what the employer chose.
- **Saved** under the optional key `employment`; **verbs** `employment.employ`, `employment.dismiss`, `employment.set_make`
  through `World.mirror`.

## 6. Decision 5: building, buying, selling and expanding businesses

- **Building** is unchanged: a workshop module beside a house the household owns, or a standalone workshop on ground of
  its own (the player: Build menu; villagers: `Ventures.found`).
- **Offering for sale** (`Ventures.offer(b, ref, price)`; verb `ventures.offer` for the player): only the owner (not a
  tenant) of a finished workshop with no building work on it may offer it; the offer `building.sale {by, price, day}` is
  saved with the building and withdrawn with `ventures.withdraw`. A villager household offers a workshop it owns that
  nobody of the household works in any more (its venture closed, nobody of the trade at home), at the land office's value
  of the building and its ground (`Property.price_of`, PROVISIONAL as an asking price).
- **Buying** (`Ventures.buy(b, buyer_ref, ...)`; verb `ventures.buy` for the player): a willing seller (a current offer),
  a willing buyer (a villager: eligible to found in the workshop's trade, and decided through the same judgment profile,
  `business_found`; it is another way to found), an agreed price (`World.deal_price` on the asking price: each side's
  Trading pulls it), funds the buyer really holds (a villager household: what it can spare above its keep, as for
  founding). The seller receives the payment (to the household's head, or the player's purse).
- **What transfers:** the workshop's parcel and building (with its stations and fittings: equipment) by `World.set_owner`.
  The seller's venture closes (its hands lose leave; its employees' employment ends: "the business changed hands"), its
  till goes to the seller (TILL-D1: operating funds are the seller's money), and goods the seller's people hold stay
  theirs (inventory is not part of the building). Nothing else of the seller's moves: obligations are not inherited.
  A villager buyer opens a venture there at once (and invests its working capital); a player buyer gets the workshop.
- **Home-attached workshops:** a workshop module is already a parcel of its own (`estate` names the house's anchor). When
  it goes to another party it is **detached** from the estate (the `estate` mark is removed): it becomes a property of its
  own, the inner doorway between it and the house closes (the derived doorway is gone; its wall cells are solid again), and
  the house, its ground, its other rooms and everything in them stay the family's. A workshop that is the anchor of an
  estate with other rooms on it cannot be sold apart (the existing land office rule).
- **Expansion and several businesses:** a keeper whose venture's till holds more than a standalone workshop's start plus
  its working capital may found a second, standalone workshop (or buy a listed one) paid from the business's till, when
  the trade has work and no room; the new workshop is staffed through hiring. Nothing caps the number of businesses:
  money, ground, a willing seller, staff and work limit it.
- **Career changes** use the existing systems only: the labour market changes a villager's job (`_change_job`); skills
  (`NPC.skills`) and recorded experience (`WorkExperience`) are kept; owning or buying a workshop grants no skill (buying
  needs the same skill and experience as founding); a keeper who leaves the trade closes the venture, the household
  offers the unused workshop, and the money from the sale is theirs to found or buy in the new trade.

## 7. Provisional values (agent, `balance.json`)

| Key | Value | Meaning |
|---|---|---|
| `ventures.hire_runway_days` | 7 | days of a wage a venture's till must hold before it hires |
| `ventures.stall_days` | 30 | days without progress before an unaffordable venture site is abandoned |
| `employment.resign_below` | 0.75 | an employee whose wage is below this share of the market wage leaves on their weekly morning |
| `employment.wage` | 10 | kept only as the wage of a record saved without one (older saves) |
| asking price | `Property.price_of` | a villager's asking price for a workshop with its ground |

## 8. Implementation map

- `game/scripts/core/ventures.gd`: till and goods bookkeeping (`budget`, `fund`, `note_bought`, `after_craft`,
  `goods_of`), opening with investment, `_hire`, `abandon`, `_review_setup`, `offer`, `withdraw`, `buy`, `_list_unused`,
  `_consider` (buy before build, expansion).
- `game/scripts/core/business_money.gd`: venture tills in the settlement, `after_trade(seller, total, id, qty)`, `invest`,
  `withdraw`, `venture_tills`.
- `game/scripts/core/employment.gd`: the framework (`WORK`, `market_wage`, `refusal`, `employ`, `hire_for`, `dismiss`,
  `_resign`, `plan`, the work acts, `daily`).
- Hooks: `NPCBrain` (`buy_qty`, `buy_from`, `craft`, `_station_for`, `_decide`, `act` for `emp_chop`, `emp_craft`),
  `FarmPlots` (`_store`, `act`, seed and fence purchases), `World.trade`, `Business.tills`, `EconActor`,
  `EconTransactions`, `NetActions.VERBS`, `GameUI` (talk menu, workshop window, land office).
- Tests: `game/tests/business_ownership_test.gd`.

## 9. Evidence (source `b10eab3`, branch `wip/b25-bizown`)

- `game/tests/business_ownership_test.gd`: 165 checks, 0 failures (every bullet of the directive's testing requirements;
  section names in the file).
- Regression set, 0 failures: business_founding 59, business 160, business_money 37, business_works 61, till_ownership 71,
  skilled_employment 54, services_d2 89, contracts 154, le05_construction_hire 10, farm_plots 104, economy_model 112,
  stalls 104, conservation 8, net_econ_integrity 126, migration 109, save_transfer 21, save_continuity 5, multiplayer_c 340,
  wiki_test all passed, start_test 523 steps, run_tests 3601 checks. housing_test 115 checks with its one known
  pre-existing failure (the loft check), unchanged by this work. `tools/check_interactions.py`: 391 interactions, 0 problems.
- One local simulation, `economy_sim.gd --days 90 --seed 1 --every 30` (Living Economy off, the shipped defaults): currency
  leak 0 and item leaks 0 at days 30, 60 and 90 (coins 3009 -> 4721, all by the caravan's recorded flows); no workshop was
  built in the 90 days (`building.workshops_built` 0), so no venture opened, hired, was sold or expanded in this run. A
  90-day run cannot tell normal conditions from overly strict founding requirements (the directive: do not read an absence
  in a short run as a reason to change thresholds); longer, multi-seed runs on GitHub Actions are the lead's. The thresholds
  were not changed.
