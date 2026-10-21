# CON-02: service contracts inside CON-01

Prepared 2026-10-21 on `wip/b17-con02` (from `wip/build17` `70900c0`). Authority: the owner's directive
`docs/directives/2026-10-21_build17_con01_final_decisions_service_contracts.md`, which approves service contracts
(sections 2-4, 6). Under that directive, Q-C1 to Q-C9 are owner-approved Build 17 defaults, and every one of them is
kept unchanged here.

Labels: **BUILT** (in the code and tested), **DEPENDENCY** (needs a game system that does not exist yet; not
fabricated), **OWNER OPTION** (an economic decision the owner has not made; the default closest to CON-01 is used).

## 1. One engine

Service contracts are not a second contract engine. A service is a CON-01 record with `kind: "service"` and goes
through the same functions:

- `Contracts.evaluate`: the seller's judgment.
- `buyer_answer`: the villager buyer's answer to a counter.
- `counter_offer`.
- `propose`.
- `formal`, `face_to_face`, `npc_sign`: signing (Q-C6, Q-C7, Q-C8).
- `_open`: the reservation.
- `_pay_units`: payment. This is now the one place any contract pays its seller; goods delivery calls it too.
- `cancel`, `_lapse`, `dawn`, `on_death`, `on_player_died`.
- `to_dict` / `load_dict`: save.

`game/scripts/core/contract_services.gd` (class `ContractServices`) holds only what differs by kind of work:

- `means`: can this person do it, and how much by the deadline.
- `going`: the going rate.
- `plan` / `step`: how a villager does the next unit through the existing work system.
- `release`: what happens to anything carried when the contract ends.

## 2. The terms the directive lists (section 2), and where each lives

| Term | In the record or code |
|---|---|
| 1. Service or work requested | `service` ("dig", "survey") |
| 2. Contracting parties | `buyer`, `seller` (World refs: the player, a villager, the manor by its reeve) |
| 3. Work location | `site`: `{pit}` (an open pit) or `{clue}` (a stain's search area) |
| 4. Quantity, duration or objective | `qty`: units of work (units dug, readings told) |
| 5. Agreed compensation | `price_each` per unit; `qty x price_each` is set aside at agreement |
| 6. Required materials or equipment | The seller's own: a pickaxe to dig; a prospector's kit and the assay fees to survey (`means` refuses without them; the fee is a cost in the least price) |
| 7. Completion conditions | A unit counts only when the work system does it: `OpenPits.dig` for a unit dug, `Prospecting.assay` plus `share` for a reading told. A dig is fulfilled once all units are dug and nothing of the buyer's is still carried; a survey once all readings are told |
| 8. Deadline or schedule | `days` / `deadline_day`, negotiable; lapse at dawn after it (as goods) |
| 9. Existing obligations and availability | `Contracts.obligations`: open contracts (goods and services), the manor's tool orders, a manor job, a building site's carrying, a stall post. Today counts as taken by a manor job, a site or a stall post; the time is split among the rest |
| 10. Negotiation and counteroffers | `evaluate` counters with the least price, the work the seller can do, or a later day. `buyer_answer` (a villager buyer) counters a seller's or the player's terms (Q-C9: up to 25% over its price, never coins it lacks). The player counters a villager's offer in the talk window |

The seller's least price uses the same terms as goods (`price_terms`):

- **going:** the manor job board's own rate for the same work, never a new wage:
  - dig: an excavation load's wage over the load, which is the quarry rate per unit;
  - survey: the survey wage over its samples.
- **cost:** the assay fee.
- **alternatives:** its usual daily earnings over the units a day of this work yields (Q-C3).
- **household:** OD-19.
- **relationship:** friends, partners and kin.
- **risk:** the 15% time margin (Q-C4) and the early-cancellation premium (Q-C5).

## 3. Kinds of service

| Kind | Who | How it is done (existing system) | State |
|---|---|---|---|
| **Dig an open pit** (MIN-E) | Buyer: the pit's owner (the player, or the manor by its reeve); seller: anyone with a pickaxe | A villager digs one unit at a time with `OpenPits.dig` (its swing, wear, xp, the pit's layers), into the contract's load. It tips the earth onto the pit's spoil heaps (`OpenPits.tip`) and brings any stone to the player's chest at home (or the manor's works yard). A player without a home collects the stone in the contract window. This mirrors the manor's own `excavate` job | BUILT (player to villager; the manor as buyer is accepted by the engine but the manor posts its own pit work on the job board, unchanged) |
| **Survey a stain** (MIN-C, MIN-D; answers MIN-D-Q1) | Any buyer: the player, a villager, the manor; seller: anyone with a kit and the fees | `Prospecting.take_sample` with the seller's kit, then `Prospecting.assay` by a smith at the forge (fee and fuel as always). Each reading is told to the buyer face to face (`Prospecting.share`) and paid then. The player as seller does the same work and reports in the talk window | BUILT (all three directions) |
| Guard protection | | No escort or guarding behaviour exists (guards patrol and confront theft) | DEPENDENCY: a guard-duty system (not in Build 17 scope) |
| Transport goods between places or settlements | | Regular routes and special deliveries are Expansion 18's (Q18-12); within the village, goods contracts already include their delivery | DEPENDENCY: Expansion 18 |
| Repair a building (carpenter) | | Only the manor's `mend` jobs exist (works sites, not a party's building); there is no building-condition system to repair | DEPENDENCY: building wear and repair |
| Harvest a field (farmer) | | The harvest-hire rules (who may cut a field, the stolen-wheat rule, the field's farmers stepping aside) belong to the paid work quests, which Q-C2 keeps unchanged. An NPC-to-NPC harvest needs the same rules for a villager hand | DEPENDENCY (OWNER OPTION S-4) |
| Labour on a building site, construction steps | | The hired carriers (`Construction.hire`) are kept exactly as they are (section 3 of the directive) | Not routed (Q-C1/Q-C2 spirit; section 3) |

### Live use

No villager in the live economy hires services yet. In the 30-day run no service contract was made, and the run's
figures are unchanged (section 7). The reasons:

- A villager buyer would need a real need for the work. Today only the manor uses survey knowledge, and the manor posts
  its own survey and excavation jobs.
- Villagers own no open pits.

So service contracts are made today by the player (hiring a villager, or taking up a villager's offer) and through the
engine's API, which the tests use for all three directions. The live-buyer behaviour is recorded as OWNER OPTION S-5.

## 4. Payment: the CON-01 framework, unchanged

- The buyer's coins for the whole contract are set aside at agreement, or at signing for a formal contract (Q-C6), and
  counted in the census.
- Each unit is paid from them only when it is done; nothing is paid in advance.
- Cancelling pays only for units done.
- Lapse returns the rest and costs regard (the existing rule).
- A party's death ends the contract with the coins returned first.

Anything the seller still carries of the buyer's goes where it belongs: earth onto the pit's heaps, stone to the buyer.
This is what `ManorWork.release` does for the manor's excavation.

No new permanent rule was made for advances, progress payments, incomplete work or disputes. The questions below are for
the owner; each default is the one closest to existing CON-01.

## 5. Owner options

- **S-1. Advances for services.** Some work needs the seller to lay out money first: the survey's assay fees, 6 coins a
  reading. Today the seller pays them from its own purse and recovers them in its price; a seller without the fees above
  its household reserve cannot take the work.
  - (a) Keep this (the default; it matches the manor's survey, where "the fees are the worker's").
  - (b) Allow a buyer-paid advance for named costs, which needs OD-LE-07's restricted-advance rule.
  - (c) The buyer pays the fees directly at the forge.
- **S-2. Paying for work done versus results.** A unit of a survey is a reading told, whatever it shows: a barren
  reading is paid like a find (WDR-022: a failed venture costs time and money). A unit of a dig is a unit dug, whether
  or not the pit reaches ore.
  - (a) Pay for the work (the default; the manor's survey and excavation jobs do the same).
  - (b) Pay a bonus on results, which needs a new rule.
- **S-3. Incomplete work and disputes.** Units are verified by the work system itself (the pit's own count, the
  assayer's record), so there is nothing to dispute about a unit done. What a buyer can object to is quality or
  timeliness.
  - Default: lapse at the deadline (coins back, regard lost); no money penalty, no withholding of paid units.
  - Options: a withheld share until the whole is done, which is a progress-payment rule; or a dispute through the
    manor (OD-LE-06 politics).
- **S-4. Harvest by contract.** Extend the harvest-hire rules (a hand may cut an employer's field without theft, the
  farmers step aside, wheat kept is stolen on lapse) from the player's paid quest to a villager hand under a service
  contract, so a farmer can hire a villager.
  - This changes how fields are shared between villagers.
  - Recommendation: decide together with Q-C2's later review.
- **S-5. Villagers as buyers of services.** Which real need should lead a villager to hire work?
  - For example, a miner whose seams are worked out commissioning a survey, then digging its own trial pits. That is
    new villager behaviour and uses knowledge only the manor uses today, which is close to Expansion 19's judgment.
  - Default: none until approved; the engine supports it.
- **S-6. Formal signing for services.** Q-C6's 50-coin line is applied to services as to goods (a service of 50 coins or
  more is signed face to face). Confirm, or set a separate line for labour.

## 6. Preserved rules (section 3 of the directive)

| System | Kept | Evidence |
|---|---|---|
| Manor tool orders (Q-C1) | Advance payment, unchanged; counted as a smith's obligations | `npc_brain.gd::_support_trades` untouched; `Contracts.obligations` reads `World.manor_orders` |
| Paid work quests (Q-C2) | Whole wage on completion or nothing, unchanged | `quests.gd` untouched; `services_test` checks the template's whole wage |
| The manor's job board | Wages set aside from the treasury when taken and paid in full when done, unchanged | `manor_work.gd` untouched; `services_test` takes and finishes a manor job beside an open service contract: the treasury reserve and the contract's reserve are separate, no double reservation or payment |
| Hired carriers, stall attendants | Unchanged; counted as obligations | `construction.gd`, `business.gd` untouched |

## 7. Tests and results

`game/tests/services_test.gd` (new, 51 checks) covers:

- **Directions:**
  - player to villager: a dig, run to completion through `OpenPits.dig` and `tip`; and a survey, through
    `take_sample`, `assay` and `share`;
  - villager to villager: a survey, the readings told face to face;
  - villager to player: a survey offer; the player counters, the villager counters back, they agree face to face; the
    player samples, has the samples assayed and reports.
- **Feasibility:** no pickaxe, no such pit, a pit that is not the buyer's, no kit, more work than the time allows.
- **Counters:** a low price met with the least price, then agreed.
- **Signing:** a formal service is refused at a distance; a small one is agreed unsigned.
- **Obligations:** a manor job takes the seller's time.
- **Accounting and expiry:** payment and reservation accounting; cancellation mid-work (the earth carried goes to the
  heaps, done units stay paid); lapse.
- **Save and load:** mid-work, with no double payment after loading; a save with goods contracts only.
- **Determinism:** the same seed digs the same cells and keeps the same records.
- **Preserved rules:** manor job and quest payment rules; a goods contract alongside.

`contracts_test.gd` adds the talk window's "Dig your open pit" hire.

Results on this branch:

| Suite | Result |
|---|---|
| services_test | 51 checks, 0 failures |
| contracts_test | 138 / 0 |
| openpit_test | 66 / 0 |
| discovery_test | 65 / 0 |
| prospecting_test | 54 / 0 |
| world_test | 339 / 0 |
| run_tests | 3537 / 0 |
| start_test | 499 steps / 0 |
| parity_test | 55 / 0 |
| conservation_test | 8 / 0 |
| wiki_test | all passed |
| Python `unittest discover -s tests` | 105 OK |

**30-day run** (`economy_sim --days 30 --seed 1`):

- `LEAKS: currency 0; items {}; deposits []; animals {}`.
- Every daily summary line is byte-identical to the same run on `70900c0` (before this change): day 30 alive 104,
  starved 0, treasury 558, coins 4909.
- Contracts: the same 6 goods contracts made, 55 offers to the player, no service contracts. No villager hires
  services yet (section 3, Live use; S-5), so the village's economy is unchanged.
