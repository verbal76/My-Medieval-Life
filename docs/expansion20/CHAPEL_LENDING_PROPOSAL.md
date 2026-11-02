# Chapel community lending: implementation proposal (design only)

Register: CHAPEL-LENDING (owner directive 2026-11-02, `docs/directives/2026-11-02_chapel_economic_purpose_correction.md`,
section 4). Status: **proposal; nothing is built.** The owner approved the concept and asked that existing loan, credit,
property and repayment systems be inspected first, and that no interest rate, collateral seizure, repayment schedule or
debt enforcement be invented without an approved design. This document lists what exists, what is missing and the policy
questions, each with options. Written on `wip/b25-chapel-purpose` (worker report for the lead).

## 1. What the owner approved

The chapel may eventually support, by charitable grants and repayable loans:

- families recovering from serious hardship;
- viable businesses in temporary financial difficulty;
- legitimate village improvement projects;
- necessary community infrastructure;
- emergency assistance in economic downturns.

The immediate food and money relief (CHAPEL-PURPOSE) does not wait for this, and it does not depend on it.

## 2. Existing systems that can be reused

| System | File | What it already does | Reuse for chapel lending |
|---|---|---|---|
| Trade credit (TRADE-CREDIT, owner Q18-5) | `game/scripts/core/credit.gd` | A recorded debt `{id, creditor, debtor (refs), item, qty, value, made, due, state, ended}`; **no interest**; trust is the creditor's regard (`relations.befriend_at`); a limit owed to one creditor (`credit.limit` 30); due `credit.days` (7) later; villagers repay at dawn when they can above their reserve (`World.can_afford`); a day past due is a **default** (regard falls `default_regard`, no further credit while it stands; the debt stays until repaid late or written off); death passes debts and claims to the heir, else written off; saved under the optional key `credit`. | The debt record, the repayment rule (only above the debtor's OD-19 reserve: nobody is forced into hunger), the default rule, inheritance and save handling. Needs a creditor reference for the chapel (`"chapel"`; `EconActor` and `EconTransactions.VILLAGE` already resolve it) and a debt with coins and no goods (`item` empty). |
| Transaction authority (LE-03) | `game/scripts/core/economy/econ_transactions.gd` | One validate-then-commit path with single-use transaction ids, escrow and custody; already treats `"chapel"` as a village holder (coins = `Chapel.coins`, goods = `Chapel.store`); `lend` is used by tool rentals. Built always, claims enforced only with the economy on. | The conserved transfer of a loan's principal and each repayment, with a journal entry. |
| Tool rentals (LE05-RENTAL) | `game/scripts/core/economy/econ_rentals.gd` | Escrowed deposit, a fee for wear, end rules for every case, estate succession (`EconTransactions.estate_of`). Behind the economy switch. | A worked example of a secured arrangement with every ending handled, if the owner wants collateral (section 4, Q3). |
| Household means | `game/scripts/core/chapel.gd::household_means`, `household_shortfall`; `World.necessity`, `World.reserve_of` | Cash, till and stock against a 14-day essentials line; brackets; the necessity reserve. | Eligibility (hardship) and affordability of repayments. |
| Business money | `game/scripts/core/business_money.gd`, ventures (`docs/expansion20/BUSINESS_FOUNDING.md`, `BUSINESS_OWNERSHIP.md`) | Tills, costs (rent, wages, upgrades), a venture's working-day runway, closing an idle venture. | Whether a business is "viable but in temporary difficulty" (earnings history, costs, runway). |
| Property | `game/scripts/core/property.gd` | Land and houses sold and let by the manor; weekly rent; arrears; eviction after `rent_evict_missed` unpaid weeks; a house of a family that died out goes to the manor. | Only if the owner chooses property as security (Q3). Today only the manor lets, and only the manor evicts. |
| Manor works and construction | `game/scripts/core/manor_work.gd`, `construction.gd` | Public works paid from the treasury; building sites with materials and hired helpers. | Funding a village improvement or infrastructure project with chapel money would go through the same site and job systems. |
| Chapel fund and reserve | `game/scripts/core/chapel.gd::operating_reserve`, `alms` | The fund keeps its operating reserve and gives the surplus as alms. | The lending budget would come out of the surplus, after emergency relief and before or beside alms (Q6). |
| Judgment (deals) | `JudgmentLive.on_deal` (`trade_fair`, `trade_cheat`) | Repaid debts build trust; defaults are remembered. | A borrower's record with the chapel, if the owner wants it to count. |

## 3. What is missing

1. **A chapel creditor.** `Credit` debts are between people (NPC or player refs). The chapel is not a person; its debts
   need a creditor ref (`"chapel"`), a coin source (`Chapel.coins`) and a decision-maker (the preacher, or a rule).
2. **Cash loans.** `Credit` records goods sold on credit; a loan is coins now for coins later. The record needs `item` ""
   and the principal moved through the transaction authority.
3. **Applications and decisions.** Nothing decides who may borrow, for what, how much. Villagers have no "borrow" decision
   in the judgment framework (`judgment.json` profiles).
4. **Repayment schedules.** `Credit` has one due day, whole sum. Instalments do not exist.
5. **Grants versus loans.** The coin alms are grants without conditions; there is no conditional grant (for a project) and
   no record of what a grant was for.
6. **Project funding.** No way to say "the chapel pays for this public work": manor works are the treasury's.
7. **Business viability.** No single test that a business is viable and only temporarily short (the data exists: tills,
   earnings, costs, runway).
8. **Wiki and instrumentation** for loans (none until built).

## 4. Policy questions for the owner (each with options)

**Q1. Interest.** The game's only credit today charges none.
- A. No interest, ever (charity; the existing trade-credit rule). *Recommended for the first version.*
- B. A small fixed fee, stated at the start (for example a few coins), not growing with time.
- C. Interest by the week (needs a rate the owner sets).

**Q2. Who may borrow, and for what.**
- A. Households in hardship (the 14-day line) only, for recovery; grants stay the coin alms.
- B. A and businesses (ventures, stalls, shops) with an earnings history and a temporary shortfall.
- C. B and projects (village improvements, infrastructure) proposed by a villager or the manor.

**Q3. Security (collateral).**
- A. None: trust only, as trade credit (regard, judgment). *Recommended: no seizure exists today.*
- B. Goods pledged and held by the chapel (escrow, as the tool rentals do), returned on repayment.
- C. Property (needs a pledge record and a rule for what happens to a house; only the manor evicts today).

**Q4. Repayment schedule.**
- A. One due day (the existing rule), length set by the owner.
- B. Weekly instalments from what the debtor can spare above its necessity reserve.
- C. Repaid when able: no due day; the debtor repays from any surplus above its reserve.

**Q5. What happens when a borrower cannot repay.**
- A. Nothing beyond the record: no more loans while it stands; written off after a period. *Recommended (no enforcement exists).*
- B. The existing trade-credit default: regard falls, the creditor's friends think less of the debtor.
- C. Stronger enforcement (seizure, labour, the manor's court): needs a new design; not recommended now.

**Q6. How much the chapel may lend.**
- A. Only from the surplus above its operating reserve, after emergency relief, in place of part of the weekly coin alms
  (a share the owner sets).
- B. A fixed share of the fund.
- C. A separate lending purse built from repayments only (it starts empty and grows).

**Q7. Grants versus loans.**
- A. Hardship relief stays a grant (the coin alms); loans are for recovery and businesses only.
- B. The chapel chooses: a grant when the household can never repay, a loan otherwise (needs a rule).

**Q8. Who decides.**
- A. A fixed rule (as the alms are).
- B. The preacher, through the judgment framework (a profile like `chapel_offering`), so trust and opinion matter.

**Q9. The player.** May the player borrow from the chapel, and on the same terms as villagers (PAR-02, one rule for
everyone)? Recommended: yes, same rules.

## 5. Suggested first slice (once the owner answers)

With the recommended answers (Q1 A, Q2 A or B, Q3 A, Q4 A or C, Q5 A, Q6 A, Q7 A, Q8 A, Q9 yes):

1. Extend `Credit` with a cash debt (`item` "", `value` coins) and a creditor ref `"chapel"`; principal and repayments
   through `EconTransactions` (journal), coins from and to `Chapel.coins`.
2. On the service day, after emergency relief and before the coin alms, the chapel offers loans to eligible borrowers
   from its lending share of the surplus; repayments at dawn above the debtor's reserve (the existing rule).
3. Save: the existing `credit` key; a save without chapel debts loads unchanged.
4. Tests: conservation (coins between purse and fund only), no repayment below the reserve, default rule, inheritance, save
   and old save; instrumentation in the economy_sim `CHAPEL` line (loans made, repaid, defaulted, outstanding).
5. Wiki: a "Borrowing from the chapel" section only when built.

Nothing in this document is implemented. The relief corrections of CHAPEL-PURPOSE stand on their own.
