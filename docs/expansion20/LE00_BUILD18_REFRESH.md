# Expansion 20 (Living Economy), LE-00 refresh against Build 18

Owner directive 2026-10-23 (`docs/directives/2026-10-23_expansion20_phase1_authorization.md`, register E20-P1, LE-00).
Specification: `docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.txt` (owner, 2026-10-20).
Code read: `wip/expansion20-preparation` at `6ec3019` (the released Build 18, `wip/build18` 239bdff, merged under the
Build 17 audit). This refresh corrects `LE00_ARCHITECTURE_AUDIT.md` (written against Build 17 `cd7439c`) where the code
has moved, and adds the data-owner map, the LE-01 record inventory and the OD-LE table the phase-1 directive asks for.
It was produced by reading the code (`file::function` citations below); no simulation was run for it.

Statements here are FACT (read in the code) unless marked PROPOSAL (an agent recommendation for the owner).

## 1. Corrections to the Build 17 audit

| Audit section | Build 17 statement | Build 18 fact |
|---|---|---|
| 1.1 NPC brain | smith forges what is scarcest | `_crafter`/`_smith` order recipes by expected return at local asks (`by_return`, `recipe_return`, WDR-012-C); manor orders still first, goods a buyer wants before stock (`for_buyer`) |
| 1.3 Employment | six-job market | `job_market` adds stonecutter, tailor, barber and clergy places; the manor hand wage rises while places stay empty (`_hiring_competition`, `World.wage_offers`); experience scales pay and time per worker (`settlement/experience.gd`, `CapabilityHook`) |
| 1.7 Stalls and businesses | stock is the keeper's own | still true for NPC trades, but business money now has tills apart from the purse (ECON-P3, `business_money.gd::daily`, `after_trade`); the player's workshop has orders and a workroom (`business_works.gd`) |
| 1.8 Trade hooks | `note_trade` read by nothing | `Relations.note_trade` is called inside `World.trade` |
| 1.9 Caravan | a purse and a daily allowance | gone: the caravan is the traders of five off-map settlements, each paying from its own till (`settlement/regions.gd`, `buyer_for`, `seller_for`, `buy_from_village`); central allocation by `caravan_line_need` and the fixed 0.8 x value remain |
| 1.10 Contracts | CON-01/02 | unchanged apart from wording and the capability hook; formal agreements added (`couriers.agreements`, `formal_contracts.gd`) |
| 1.11 Manor | tax only under holiday days | `TaxPolicy.step`: three bands with margins and announced changes (saved `"tax"`) |
| 1.15 Accounting | `tests/census.gd` | the census lives in `settlement/holdings.gd::holders`/`coins` (chapel a holder); `World.total_coins` counts the chapel fund and courier escrow |
| 3.2 item 1 | where the village's holdings live | resolved: World holders stay the truth; `SettlementLedger` is a read-only snapshot (`settlement/report.gd::parties`) |
| 5 Saves | `SAVE_VERSION` 17 | 19; new optional keys `credit`, `regions`, `couriers`, `chapel`, `feast`, `tax`, `law_lessons`, `x18_settlements`, experience, `outlaw_gone_day` |
| new | | credit and barter (`credit.gd`), the chapel's fund, offerings and alms (`chapel.gd`), outlaws (`outlaws.gd`), migration (`settlement/migration.gd`), couriers (`settlement/couriers.gd`), luxury imports and feasts |

## 2. Authoritative data-owner map

One truth per kind of state; Expansion 20 extends these and adds no second inventory, ledger or brain.

| State | Owner (script: field) | Interfaces | Missing against the spec |
|---|---|---|---|
| Decisions | `npc_brain.gd::decide`, per-NPC `plan` | `_plan_job`, `_crafter`, `_smith`, `seek_work`, `_buyer_for`, `_seller_of` | needs with urgency, persistent goals, bounded knowledge (global searches) |
| Person's goods and coins | `NPC.inv`, `NPC.coins` | `World.trade`, `World.give`, `spendable`, `reserve_of` | none as storage |
| Household | `World.households[n]` {members, pantry, home, ended} | `necessity`, `evaluate_household`, `_payer_for` | a budget over competing uses; purses not pooled (by design so far) |
| Business money | `buildings[id].front.till`, `.counter`; stall tills | `business_money.gd::daily`, `after_trade`, `Business.tills` | a business identity (a business is its owner's ref, a building or a stall id) |
| Workshop goods | the owner's `NPC.inv`; player workroom `business_works.work` | `stock_work` | goods held for the business apart from the person |
| Coins set aside | `contracts::reserved_total`, `quests::reserved_total`, `manor_work::reserved_total`, courier `escrow`/`deposits` | each module's own | one reservation record (purpose, expiry, release) |
| Goods set aside | `contracts::held_for` (owed finished goods), the smith's iron for manor orders (`_smith`, `ordered`) | `npc_brain::reserve`, `credit::available` | input earmarks for accepted orders |
| Debts | `credit.gd::debts` {creditor, debtor, item, qty, value, made, due, state} | `sell_on_credit`, `repay`, `_default`, `on_death` | interest, security, restriction (OD-LE-05, OD-LE-07) |
| Contracts | `contracts.gd` records; `couriers.agreements` | `offer`, `evaluate`, `_maybe_finish`, `_lapse` | deposit, renegotiation, breach terms (OD-LE-13) |
| Prices | computed: `sell_price_at`, `buy_price_at`, `local_supply`, `deal_price`, `business.ceiling`, stall `prices` | `_market_price` (hour cache) | bids, asks, counteroffers, expiry (OD-LE-02, LE-02) |
| Treasury | `World.treasury`, `reeve_day` | `TaxPolicy.step`, `_relief`, `pay_guards`, `_public_works`, `_support_trades` | a constrained actor's choices (OD-LE-06) |
| Chapel | `chapel.coins`, food store | `offerings`, `ask`, `alms` | none for LE-01 |
| Off-map economy | `settlement/offmap.gd` per settlement; `regions.gd` | `step_hour`, `SettlementParty.deal`, `RegionalMarket.to_contract_offer` | knowledge-bounded traders (LE-05) |
| Bandits | bandit NPCs' purses and band stores; `outlaws.gd` | `_bandit_market`, `band_eat`, `_loot_to_recover` | hoarding and fencing (OD-LE-09) |
| Resources | `resources.json`, deposits, trees, plots | mining, forestry, farming scripts | none for LE-01 |
| Accounting | `World.total_coins`, `settlement/holdings.gd`, `offmap.audit`, `regions.audit`; `economy_sim.gd` FATAL checks | census, item ledger | an economic event record (diagnostics) |
| Save, determinism | `World.to_dict`/`load_dict` (v19), `tools/sim_gate.py` | optional keys per system | none |

## 3. LE-01 records: what exists

| Record | State | Existing structure | Missing |
|---|---|---|---|
| Economic Actor | partial | refs `npc:<id>`, `hh:<n>`, `player`, `manor`, `region:<s>/<holder>` (`World.npc_ref`, `hh_ref`, `party`, `ref_name`); `report.gd::parties` partitions holders; `SettlementParty` | one resolver over the refs; a business identity (blocked on OD-LE-04/07) |
| Need | missing as a record | `necessity`, `evaluate_household`, `business.needs`, `NPCBrain.wants`, off-map `need_rate` | urgency, deadline, substitutes, strategy |
| Knowledge | missing | `couriers.contacts`, `Relations.note_trade`, `NPC.memory`, prospecting knowledge | source, age, confidence (blocked on OD-LE-10) |
| Offer | partial | contracts in `offered`; `credit.requests`; stall prices; `to_contract_offer` | book, expiry, visibility (blocked on OD-LE-02) |
| Contract | exists | `contracts.gd`, formal agreements | deposit, renegotiation, breach (OD-LE-13) |
| Reservation | partial, scattered | `held_for`, four coin `reserved_total`s, escrow, workroom `work` | one record: owner, item or coins, quantity, purpose, expiry, release; input earmarks |
| Credit | exists, minimal | `credit.gd::debts` | interest, security, restriction (OD-LE-05/07) |
| Economic Event | missing | `World.note`/`log_lines` (300), `World.stats` (not saved), `offmap.journal`, `regions.moves` | a typed, ordered, bounded record |
| Ledger integration | exists | `total_coins`, holdings census, flow ledgers, off-map audits | reservations and events reconciled against it |

## 4. Risks found (Build 18, outside Expansion 20's scope to fix here)

- **Unbounded growth:** `NPCBrain.miss_log` (appended at `npc_brain.gd:966`, never cleared); courier `jobs`, `agreements` and
  `contacts` (no pruning found); `w.npcs` keeps every dead person (stable ids depend on it, so only the per-frame walk
  is the cost). Report to the owner as Build 19 maintenance candidates.
- **Population-wide scans:** `credit._villager_deals` (dawn: for each adult in a short household, `_cheapest_food` walks all
  people and foods, O(n^2)); caravan walks; migration's marriage filters; per-decision `_buyer_for`/`_seller_of`.
  LE-01's actor and supplier indexes are where these get bounded.
- **Diagnostics defect still present:** the `" marks out "` line in `economy_sim.gd:188` (known).
- **No economy performance budget or perf assertion exists** (OD-LE-15 open; `economy_sim.gd --profile` and
  `docs/release/SIMULATION_PERFORMANCE.md` are the tools).

## 5. Expansion 19 interface (documented, not enabled)

Expansion 19 owns subjective judgment, personality, trust and relationship-weighted choice; Expansion 20 owns needs,
offers, transactions, obligations and consequences. Today's contact points (judgment off): Expansion 19 reads economic
facts through its event feeds (`trade_fair` from `Contracts._maybe_finish` and `Credit.repay`, `trade_cheat` from
`_lapse` and `Credit._default`, `help_build`) and weighs six existing decision points (contract acceptance and seller
order, lending, barter, food seller, family help) through `JudgmentLive`. Expansion 20 rule (PROPOSAL): the economy
computes the feasible options and their economic value; judgment may only re-weigh among feasible options (as
SJD-Q14 already states) and never creates, settles or cancels an obligation. Economic events Expansion 20 records
are the facts Expansion 19 may subscribe to, one channel per fact (the audit's 3.2 item 4 double-count risk).

## 6. Owner decisions OD-LE-01..15

Status from the register (all OPEN except as noted). "Blocks now" means it blocks the phase-1 foundation work.

| Decision | What the game does today | Blocks now | Recommended default (PROPOSAL, not approved) | Consequence of the alternatives |
|---|---|---|---|---|
| OD-LE-01 placement | Expansion 20 after Build 19 (OD-30, owner 2026-10-21) | no | mark answered by OD-30 | none |
| OD-LE-02 market board / negotiation / hybrid; visibility | posted prices computed per trade; stalls show prices; contracts negotiate directly | LE-01 Offer visibility | hybrid: offers made in person at stalls, storefronts and meetings; no village-wide board | a board gives everyone near-global knowledge (against s.13); pure negotiation makes stalls' posted prices meaningless |
| OD-LE-03 wages, rents, service contracts in the first release | manor wages by rule with hiring competition; rents on leases; dig and survey service contracts (CON-02) | no (LE-03) | keep today's wage rule in the first release; negotiated wages later | negotiated wages now would change the established balance (needs approval) |
| OD-LE-04 business founding, partnerships, ownership, inheritance | anyone builds a stall; inheritance by the family graph; no business identity | business identity in the Actor record | a business is owned by one person, inherited with their estate; partnerships later | partnerships need shared-ownership rules in the ledger |
| OD-LE-05 loan interest, collateral, default, collection | credit sales with no interest; default lowers regard and limits credit | no (LE-04) | no money loans until decided | interest moves coins between actors and needs collection rules |
| OD-LE-06 manor interventions and authority | tax bands, relief, tool support, public works, guard pay, manor orders | no (LE-04); bears on Expansion 21 | keep today's manor rules as its whole authority until Expansion 21 | a lending manor needs OD-LE-05 first |
| OD-LE-07 restricted advances; business/household separation | ECON-P3 (approved 2026-10-23): tills apart from purses with defined transfers | Actor accounts | adopt ECON-P3 as the rule for every business; restricted advances only by explicit term | without it the spec's "family workshop conflict" cannot be told from a ledger bug |
| OD-LE-08 barter, rental, repair, substitution | barter exists (credit.gd); no rental; rubble substitutes stone | no (LE-02/05) | keep barter as built; rental and repair later | substitution rules change recipes |
| OD-LE-09 bandit markets, regional limits | bandits spend at the market; anyone may buy from another settlement (Q18-10) | no (LE-05) | keep today's | fencing needs custody vs ownership |
| OD-LE-10 rumour, memory, reliability | none for prices; Expansion 19 gossip at meetings weighted by closeness | LE-01 Knowledge | prices learned in person or heard through Expansion 19's channel with source, age and trust; stale, not forgotten | a separate economic rumour channel would double the gossip work and its frame cost |
| OD-LE-11 speculation, hoarding, manipulation | none | no (LE-02) | not before LE-02 | |
| OD-LE-12 charity, kinship, relief | manor relief; chapel relief and alms (CHAPEL-R2); family help to build | no (LE-03) | keep these as the charity layer | |
| OD-LE-13 cancellation, penalties, death | OD-29 provisional: no money penalty, lapse returns coins, death ends the contract | Contract breach fields | make OD-29 final; breach recorded (standing, Expansion 19 regard) | money penalties need collection (OD-LE-05) |
| OD-LE-15 performance and population targets | none set | data-structure budgets (soft: phase 1 measures, does not gate) | mid-range phone, 500 villagers, economy work spread so no frame spends more than 4 ms on it | |
| OD-LE-14 player intervention and visibility | the player trades by the villagers' rules (PAR-01); no numbers in normal play (SJD-Q10) | no (LE-02, LE-07) | the player sees offers they could see in person | |

**Genuinely blocking the next stage (LE-01 beyond phase 1):** OD-LE-02, OD-LE-10, OD-LE-07, OD-LE-13, OD-LE-04 (business
identity) and OD-LE-15. Nothing blocks the phase-1 foundation below.

## 7. Phase-1 foundation: what is settled and safe (ranked)

Policy settled by the specification itself (s.3, s.6, s.14, s.16), with a consumer and no open decision:

1. **Reservation record** (spec s.6: "Explicitly reserve or earmark material while retaining physical ownership and
   location"). One record {id, owner ref, item or coins, quantity, purpose, made, expiry, state} with reserve, release,
   expire and `available(owner, item)`; refuses to reserve more than is held minus already reserved; saved as an optional
   key. Consumer: the scattered forms in section 3 (first `contracts::held_for` and accepted-order inputs) when the
   owner approves integration. Live hook off: nothing in the live game calls it.
2. **Economic event record** (spec s.3 Event, s.14, s.16): typed, deterministic order (day, minute, sequence), bounded
   ring, saved or not by option; a diagnostics channel. Consumer: `economy_sim.gd` diagnostics and, later, the facts
   Expansion 19 subscribes to. Off in the live game.
3. **Actor resolver** over today's refs (`npc:`, `hh:`, `player`, `manor`, `region:`): kind, holdings readers (coins,
   goods, reserved), stable across save/load. Consumer: the reservation and event records. No business identity until
   OD-LE-04/07.

Not started (blocked on decisions): Offer book and visibility (OD-LE-02), Knowledge (OD-LE-10), Need urgency model (no
open OD, but it is the brain's priority model, which the directive keeps for the approved architecture), credit terms
(OD-LE-05), contract breach terms (OD-LE-13). Adaptive prices, loans, wage policy, manipulation, business founding and
government intervention stay out (directive section 6).
