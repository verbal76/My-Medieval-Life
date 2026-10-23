# Employment and contracts: what works, what is missing (B18-DP-01, PL1-10)

Owner decision B18-DP-01 (`docs/directives/2026-10-23_build18_decision_package_answers.md`): complete the approved Build 18
elements with existing systems, "do not invent a completely new universal contracting framework under Build 18", and
"distinguish clearly between an ongoing employee and a contracted worker, identify which workflows are functional, and
demonstrate real production, payment, and inventory conservation". This page is that audit. Developer reference (WIKI-01);
the player-facing text is the wiki pages "How do I hire an attendant?" and "Contracts".

## The two models

| | Ongoing employee | Contracted worker |
|---|---|---|
| What it is | A villager the employer hires to work for them until dismissed (or until the wage cannot be paid) | A priced agreement for one deliverable: goods by a day, or a service of a stated size |
| Record | The employer's premises (`attendant` id, `wage_day`); no negotiated terms | A `Contracts` record: parties, terms, price set aside, deadline, progress |
| Pay | The fixed wage (`attendant_wage`), every morning, from the till first, then the purse above the necessity reserve | The whole price is set aside from the buyer's purse at agreement and paid out per unit delivered |
| Ends | Dismissed, wage unpaid, premises closed, the worker dies | Delivered, cancelled, lapsed by its day, a party dies |
| Who decides the work | The employer, every day (production orders, the counter) | The terms of the contract; the worker decides how |

## Functional workflows (each with the code and the tests that prove it)

### Ongoing employee

1. **Attendant minding a stall or shop** (PL1-10 stage 4). Hire, daily wage, plan to the counter, sales while at the counter,
   dismissal, wage unpaid means they leave. Code: `Business.hire`, `_wage_due`, `plan_attendant`, `attended`, `dismiss`
   (`game/scripts/core/business.gd`). Tests: `game/tests/business_test.gd::_attendant` (hire and wage, one attendant, plan to the
   counter, no sale before they arrive, sales while the player is away, wages each morning, leaves when unpaid, a stall too).
2. **Attendant at the player's own workshop stations** (B18-DP-01, new). Production orders and a workroom on the premises; the
   attendant walks to a free station of a building the player owns or leases and works the real recipe through
   `World.work_craft`; goods go to the stall's stock and sell by the existing rules. Code:
   `game/scripts/core/business_works.gd` (`add_order`, `stock_work`, `next_job`, `plan_work`, `finish`), `Business.plan_attendant`,
   the `craft` step in `NPCBrain.act`. Tests: `game/tests/business_works_test.gd::_production` (inputs consumed only when done,
   goods made, price set, order counts down, wage paid by the existing rule, skill/tool/materials/busy station stop the work,
   dismissal and closing return the workroom), `_orders_and_limits` (keep-stock target, saves and an older save), `_display`
   (the made goods sell to a villager with a real need; coins conserved). Conservation is shown against the village census
   (`tests/census.gd`): the player's holdings lose exactly the inputs used and gain the goods made.
3. **Construction helpers** (a daily hire, closest to the employee model). A villager out of work is hired for the rest of the day
   to carry materials to a site; the wage (`helper_wage`) is paid up front, none for the employer's own household or a friend's favour.
   Code: `Construction.hire`, `can_hire`, `contract_of`, `plan_helper` (`game/scripts/core/construction.gd`). Tests:
   `game/tests/run_tests.gd::test_helpers` (hiring, wage, carrying to a site), `game/tests/housing_test.gd` (the responsible
   adult carries for the new house), `game/tests/relations_test.gd` (the friend's favour). The record is the construction's own `contracts` list, not `Contracts`; it is not negotiated.
4. **A household storefront keeper** (a family member, not hired): `BusinessMoney`, tested in `business_money_test.gd`.

### Contracted worker

5. **CON-01 goods contracts**, including ore quantities. Any party offers any other a contract for N of an item at a price by a day;
   the seller works toward it by mining, felling, harvesting, crafting or from stock; the price is set aside and paid per unit.
   Code: `game/scripts/core/contracts.gd`. Tests: `game/tests/contracts_test.gd` (window, quantity step, ore, accept and reserve,
   counteroffers, partial delivery, lapse, cancellation, a villager works toward it, NPC to NPC and NPC to player, death of a party,
   save and load, determinism), `contract_sign_test.gd`. Design: `docs/build17/CON01_COMPLETION.md`, `PROCUREMENT_CONTRACTS.md`.
6. **CON-02 service contracts**: dig a pit, survey a site, by the same record and rules. Code:
   `game/scripts/core/contract_services.gd`. Tests: `game/tests/services_test.gd` (player hires a villager to dig or survey, NPC to
   NPC, NPC to player, feasibility and counters, signing, lapse and cancel, save and load). Design: `docs/build17/CON02_SERVICES.md`.

## Not functional (recorded, not built under Build 18)

- **EMP-PERM-01 (Build 20 proposal): permanent employees with terms.** More than one attendant per premises; a named position
  (cook, smith's hand, keeper) with a standing wage that is negotiated, a notice period, skill-based pay, and the employee's own
  household reasoning about keeping the job. The attendant of Build 18 has one fixed wage and no terms.
- **EMP-CONTRACT-01 (Build 20 proposal): contracted production for a business.** A goods contract (CON-01) already lets the
  player buy goods from a villager who makes them; what is missing is the player contracting a worker to make a stated quantity of a
  recipe at the player's own stations from the player's materials (a service contract of the CON-02 kind with the player's inputs),
  and the worker's own reasoning about taking it. Under Build 18 production is done by the employee model only.
- A hired worker who is not an adult without a trade (a tradesman) cannot be hired as an attendant (`Business.hire_refusal`); that
  is the existing rule, kept.

## Provisional choices (agent decisions, `docs/DECISIONS.md` B18-DP-01)

One craft then one hour at the counter; at most 6 orders, 50 batches, a keep target to 99 (window limits, not balance); goods that
do not fit the stall stay in the workroom; the workroom has no capacity limit and decays like the stock. While the attendant is at
the bench nobody minds the counter, so nothing sells then unless the player is within range.
