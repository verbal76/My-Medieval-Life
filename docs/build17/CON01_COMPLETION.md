# CON-01 completion: universal negotiated goods-procurement contracts

Prepared 2026-10-21 on `wip/b17-con01b` (from `wip/build17` `9f229f7`). Sources: the owner's directive
`docs/directives/2026-10-21_build17_architecture_mining_contracts_decisions.md` section 5 (Owner Decision 3), the
Build 17 start directive `docs/directives/2026-10-21_build17_start_underground_contracts.md` (OD-29: the documented
defaults are provisional), the plan `docs/build17/PROCUREMENT_CONTRACTS.md` (sections 2-7), and the owner's Q18-13 answer
on formal contracts (`docs/directives/2026-10-21_expansion18_capability_simulations_contracts.md` section 4, on staging).

Labels: **BUILT** (in the code and tested), **NOT ROUTED** (left in its own module, with the reason), **PROVISIONAL**
(an agent default, the owner decides), **NOT BUILT** (named, out of Build 17's scope).

## 1. Acceptance, item by item

| Register acceptance (CON-01) | Where | State |
|---|---|---|
| One contract system reused for player-NPC, NPC-player and NPC-NPC | `game/scripts/core/contracts.gd` (one record, one `evaluate`, one `buyer_answer`, one settlement) | BUILT |
| Offered through the existing conversation framework | Talk window: "Propose a contract" / "Contracts (n)" (`game_ui.gd::_relation_choices`, `show_contract`); the player's counter to a villager's offer (`_counter_terms`) | BUILT |
| NPCs evaluate feasibility, skills, tools, quantity, price, obligations, household needs, time, alternatives, relationship and risk | `Contracts.evaluate`, `means`, `price_terms`, `obligations`; every term is returned in the answer's `terms` | BUILT (section 2) |
| Accept, reject (with reasons) or counteroffer | Seller: `evaluate` (least price, the quantity it can manage, a later deadline); buyer: `buyer_answer` (the most it pays, the quantity it can use, its longest wait, the coins it can spare) | BUILT |
| Real goods and funds only | Delivery moves only goods the seller holds; payment only from coins set aside at acceptance (counted in the census) | BUILT (unchanged rule, retested) |
| No duplicate delivery or payment | One step per delivery, capped by `qty` and the reservation; ended records take nothing; save and load mid-contract | BUILT (tests) |
| Policy details decided by the owner before they are fixed | Provisional defaults (OD-29) plus the new ones in section 6, each an owner question | PROVISIONAL |

## 2. Evaluation: each question and the signal it reads

No judgment system was built (memory, trust and reputation are Expansion 19's); the terms below are existing signals,
deterministic (no random draw), and `price_terms` is the single place a later judgment plugs into.

| Directive question | Signal | Code |
|---|---|---|
| Can it obtain or produce the item? | Stock it may sell; mining (pickaxe, skill, a seam with ore left); felling (axe, a tree); its own ripe field; a recipe it has the skill, station and inputs for; a villager selling it below the offer | `means` |
| Skills and tools | `Skills`, `NPCBrain._can_mine`, `_can_make`; the tool in its pack | `means` (refusal reasons "tool", "skill", "station", "materials", "coins", "source") |
| Quantity feasible | Units per work minute x work minutes to the deadline | `means.cap` |
| Available time | Work hours left today and the days to the deadline, `work_share` of them; today counts as promised when it holds a manor job, a site's carrying or a stall post | `_work_minutes` |
| Existing obligations | Open contracts as seller; **the manor's tool orders it is forging** (new); a manor job; a building site's carrying; **a post at the player's stall** (new). Time is split among them; at most `max_open_per_seller` contracts | `obligations` |
| Risk and uncertainty | Payment risk is nil (the buyer's coins are set aside). Feasibility: `risk_margin` (0.15) of every time estimate is kept spare. Counterparty: a buyer who ended contracts with this seller early (still on record, `keep_days`) is asked `cancel_premium` (0.1) more for each | `_by_time`, `ended_early_by`, `price_terms.risk` |
| Price worthwhile | The going price (value, or what its best buyer pays now), the unit's cost (bought price + 1, or a recipe's inputs at value), and the alternatives term | `price_terms` |
| Competing opportunities | Its average daily income over the last days (`NPC.avg_income`) spread over the units a day's contract work yields, times `opportunity_weight` (1.0) | `price_terms.alternatives` |
| Household needs | OD-19 reserve: short of it, `needy_factor` (0.85, a sure income for less); covered, `comfortable_factor` (1.0). Food its household needs is never sold | `price_terms.household`, `means` |
| Relationship | Friends (CRT), partners and kin (`Life.kin`) get the friend's price (`Relations.friend_price`); the player's notoriety refuses all contracts | `close_to`, `evaluate` |
| Hard limit | It never accepts what it cannot do; a time-bound route with no time left by the deadline is countered with the first later day it can manage, or refused ("I've not the time") | `evaluate` |

## 3. Who contracts with whom

| Pairing | How it arises | State |
|---|---|---|
| Player to NPC | Talk window: goods, quantity, price each, days; the villager accepts, refuses with its reason or counters; "Agree" meets a counter | BUILT (first slice) |
| NPC to NPC | A real need only: each dawn a business holding none of an input its trade uses, which nobody sells, orders a batch at its own buying price (`npc_orders`, `order_input`); a MIN-C prospector without a kit orders one from a smith (`Prospecting._get_kit`). A seller's counter is met by `buyer_answer` through `meet_counter` (one rule for both) | BUILT |
| NPC to player | With nobody in the village able, the business's order stands for the player (`offer_to_player`), now with a log line. The player may Agree, Decline or **Counter** (new): the villager answers by `buyer_answer`; its own counter replaces the standing terms; a refusal leaves the offer as it was | BUILT |
| Manor | The record accepts the manor as a party (the reeve signs for it); no live manor procurement uses it (section 5) | BUILT (party only) |

## 4. Signing (owner Q18-13)

The owner's rule: ordinary small agreements need no notarization; formal commercial contracts and ownership transfers
need signatures; parties face to face sign without a notary; a courier with legal skill may carry the documents when
they cannot meet; **no remote instant signing**.

Built for Build 17 (one village; everyone can meet):

- `Contracts.formal(total)`: a contract worth **`formal_total` = 50 coins or more** is formal (PROVISIONAL, section 6
  Q-C6). A smaller one is an ordinary agreement, concluded where it is made, unsigned.
- `face_to_face(a, b)`: both parties within `sign_reach` (3 tiles), in the same place and on the same level
  (`World.present`'s rule). The manor is represented by its reeve.
- The player proposes, accepts or counters only in the talk window; core refuses a formal contract when the player is
  not face to face ("signed face to face. Come and see me.").
- A villager buyer whose formal order is agreed at a distance gets a `signing` record: **nothing is set aside or
  moved**. In working hours it walks to the seller (`plan`, act `contract_sign`), where the seller answers afresh
  (`npc_sign`); agreed, the coins are set aside then and the deadline runs from that day; changed circumstances end it
  with nothing moved. Not signed within `offer_days`, or a party dies on the way: it ends with nothing held.
- **NOT BUILT:** the courier-notary and any legal skill (Expansion 18's off-map case, X18-Q13); ownership transfers by
  contract (land and houses keep their own sale rules). Q18-12 transport fees are Expansion 18's; contracts stay
  goods-only.

## 5. Consolidation of the five contract-like mechanisms

The plan recommended routing overlapping mechanisms through the one record where it is safe and behaviour-preserving.
Result:

| Mechanism | Outcome | Reason |
|---|---|---|
| MIN-C prospector's kit orders | Already a CON-01 contract; its counter handling now goes through the shared `meet_counter`/`buyer_answer` (the duplicated rule removed) and its "already waiting" check through `waiting_on` (covers signing) | Same behaviour, one implementation |
| Manor tool orders (`World.manor_orders`, EQ-19) | **NOT ROUTED**; now read by `Contracts.obligations` so a smith's forging orders count against its contract time | The owner's OD-16 (b) says the manor "buys iron and tools ... or lends to the smith against future output": the advance is paid up front and funds the smith's ore and coal, the tool goes to a third party (the worker), and a lapsed order's advance is not returned. CON-01's provisional default is payment on delivery to the buyer from reserved coins, so routing it would contradict an explicit owner decision and change the economy (flagged, Q-C1) |
| Paid work quests (`Quests`, "Any work for me?") | **NOT ROUTED** | The owner's 2026-10-18 rule pays the wage "in full or not at all" as one sum on completion; CON-01 pays per unit with partial delivery. Harvest work cuts the employer's own wheat in its field (labour on the giver's goods, with the stolen-wheat rule), which is a service, not goods procurement (OD-LE-03). Routing would change payments, notes, stats and the quest UI (Q-C2) |
| The manor's job board (haul, quarry, mend) | **NOT ROUTED**, unchanged | The lead's instruction: do not change how the manor's job board pays work; haul and mend are services. Read by `obligations` (a manor job takes today) |
| Hired carriers, stall attendants | **NOT ROUTED**, unchanged | Day-labour service contracts; whether contracts cover services is open (OD-LE-03, MIN-D-Q1, Q18-12). Read by `obligations` (today is promised) |

## 6. Provisional defaults and owner questions

Defaults approved provisionally under OD-29 (unchanged): payment on delivery, unit by unit, from the buyer's coins set
aside at acceptance; partial delivery allowed; the buyer sets the deadline, negotiable; cancelling pays only for what
was delivered; lapse at the deadline with the coins returned and regard lost, no money penalty; no renegotiation after
acceptance.

New provisional agent defaults in this change (`game/data/balance.json` `contracts`), each an owner question:

- **Q-C1. Manor tool orders.** Keep the manor's paid-in-advance tool orders (OD-16 b) outside CON-01, or bring them
  under contracts with an advance-payment term (needs OD-LE-07's restricted-advance rule)? Recommendation: keep them
  apart until advances are decided.
- **Q-C2. Paid work quests.** Keep "Any work for me?" as fixed-wage quests, or make them villagers' contract offers
  (per-unit, negotiable)? Recommendation: keep them until service contracts (OD-LE-03) are decided, since harvest
  work is labour on the employer's crop.
- **Q-C3. Alternatives.** A seller's least price includes what the same hours earn it in its own trade
  (`opportunity_weight` 1.0 of its average daily income). Keep, weaken or drop?
- **Q-C4. Risk margin.** Sellers promise only 1/(1 + `risk_margin`) of their time estimate (`risk_margin` 0.15).
- **Q-C5. Counterparty risk.** A buyer who ended contracts with the seller early pays `cancel_premium` (10 %) more per
  such contract still on record (14 days). A seller who withdraws is not penalised beyond the existing regard loss
  on lapse. Keep, or tie it to reputation in Expansion 19?
- **Q-C6. Formal contract line (Q18-13).** Formal at **50 coins or more** in all (owner's own example, 70 wheat at 2,
  140 coins, is formal); smaller agreements unsigned. Alternatives: by kind (every contract over one day, every
  contract with the manor) or a different value. Also: may a small agreement be made at a distance (current default:
  yes, it is not signed), or must every contract be agreed in person?
- **Q-C7. Signing reach.** Face to face = within `sign_reach` 3 tiles, same place and level.
- **Q-C8. Unsigned agreements.** An agreement in principle not signed within `offer_days` (2) lapses with nothing held.
- **Q-C9. Buyer counters.** A villager buyer pays up to `npc_counter_tolerance` (25 %) over its own price, takes no
  fewer than its trade's batch and no more than it asked for, and waits at most `max_days` (10).

No default here contradicts a prior explicit owner decision; the two that would have (Q-C1, Q-C2) were not
implemented, and are flagged above.

## 7. Interactions for the manifest (for the lead to record)

- **INT-175 (update):** add `obligations`, `price_terms`, `buyer_answer`, `counter_offer`, `meet_counter`,
  `face_to_face`, `npc_sign`; the evaluation weighs alternatives, relationship (kin) and risk; counters both ways;
  formal contracts signed face to face.
- **INT-181 (update):** the prospector's kit order meets a smith's counter by `Contracts.meet_counter` and waits on
  `waiting_on` (offered, open or to be signed).
- **New: contract obligations read from other systems.** Trigger: a seller is asked for a contract. Source:
  `contracts.gd::obligations`, `_work_minutes`; `World.manor_orders`; `ManorWork.job_of`; `Construction.contract_of`;
  `Business.is_attendant`. Expected: each binds the seller's time; none is settled or changed by contracts.
  Tests: `contracts_test.gd` (test_evaluation_terms).
- **New: formal contracts signed face to face (Q18-13).** Trigger: a contract worth `formal_total` or more is agreed.
  Source: `contracts.gd::formal`, `face_to_face`, `propose`, `accept_offer`, `plan`, `npc_sign`, `dawn`, `on_death`;
  `npc_brain.gd::act` ("contract_sign"); `World.present`. Expected: no remote instant signing; nothing set aside
  before signing; a buyer walks to the seller; an unsigned agreement lapses or ends on a death with nothing moved.
  Tests: `contracts_test.gd` (test_signing).

## 8. Tests

`game/tests/contracts_test.gd` adds: every evaluation term on record (alternatives, household, relationship by
partner, risk after a buyer's cancellation, a smith's tool orders as obligations); time (an end-of-day offer countered
with more days, accepted in the morning); the buyer's rule (agree, the most it pays, too few, more than wanted, too long,
coins above its reserve only); NPC to NPC counters met within tolerance and not beyond; the player countering a
villager's offer (refused, countered, agreed; delivered and paid once; withdrawn with the rest returned; a countered
offer withdrawn after `offer_days`); open contracts and standing offers through save and load, a Build 16 save and an
early Build 17 record without the newer keys; determinism of orders and answers for one seed; signing (small unsigned,
formal refused at a distance and signed in person, the player accepting a formal order only in person, NPC buyer walks
and signs, interrupted by a death, never signed and lapsed, rejected at the meeting, completed); the talk window's
Counter button.
