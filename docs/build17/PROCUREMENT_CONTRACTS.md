# Universal negotiated procurement contracts: mapping to what exists (planning, read-only)

Prepared 2026-10-21 under the owner's directive `docs/directives/2026-10-21_build17_architecture_mining_contracts_decisions.md`
(section 5, Owner Decision 3). Planning only; no code or data changed. Code references are to staging `6607000`.
Register: the new entry for this capability is **CON-01** (and **MIN-H** for mining's use of it), entered by the lead
under OD-28.

Labels: **VERIFIED** (current behaviour, read in the code named), **APPROVED** (existing approved design),
**HISTORICAL** (earlier unapproved proposal), **RECOMMENDATION** (this document's advice), **OPEN** (the owner's
decision).

## 1. The owner's model, restated

**APPROVED** (directive section 5):

- **What a contract is.** One character offers another payment for a quantity of a product: item, quantity and price
  per unit, all chosen by the buyer. Example: 70 wheat at 2 gold, 140 in all.
- **Not a command.** It is an offer. The other side accepts, rejects or counteroffers after weighing feasibility,
  skills and tools, quantity, price, obligations, household needs, time, other opportunities, the relationship and
  risk.
- **Everyone uses it.** It works for player-NPC, NPC-player and NPC-NPC, under the same economic and inventory rules.
- **Conservation.** No free goods or money. Delivery needs real goods; payment needs real funds or an approved
  credit arrangement. No duplicate delivery or payment, no negative stock, no contradictory transfer.
- **Not limited to a trade.** It is not restricted to the worker's profession unless skill, equipment or
  feasibility makes it impossible.
- **Conversation.** The player proposes it in the normal talk window, as NPCs already offer jobs.
- **One design.** No competing contract architecture that would later need replacing.
- **Scope.** It is not put into Build 16 unless Build 16's approved scope already covers it.

## 2. What already exists (five contract-like mechanisms, each with its own record)

| Mechanism | Who to whom | Terms today | Money | Delivery | Deadline and failure | Evidence | Label |
|---|---|---|---|---|---|---|---|
| **Paid work quests** ("Any work for me?") | NPC (farmer, woodcutter, miner) to the player only | Fixed template: item and quantity (`need`), a **total** wage, `days`. Examples: 24 wheat for 6 coins in 1 day; 6 logs for 6 in 2 days; 6 iron ore for 8 in 2 days. Offered only when the NPC has the need and can fund it. **No negotiation** | **Reserved** from the giver's purse at acceptance (`Quests::_reserve`, `q.reserved`), so the giver cannot spend it; counted in `reserved_total` for the census | **All at once**: `Quests::ready` needs `has_all(need)`; `complete` moves the goods to the giver and pays exactly the reserved sum | Lapses at dawn after `days` (`drop_failed`): reservation back to the giver, a note, no penalty; harvest wheat kept becomes stolen (`settle_harvest`). Giver's death releases the coins | `quests.gd` header, `hire_offer`, `accept`, `complete`, `drop_failed`; `game/data/quests.json` | VERIFIED |
| **The manor's jobs** (the reeve's board) | Manor to the player **and** villagers by the same rules | Kinds haul, quarry (10 stone for 6 coins), mend; posted only for real needs | **Reserved** from the treasury when taken, only if the treasury keeps `manor_job_reserve_days` of obligations (`ManorWork::can_fund`, `take`) | Goods ride in the job's own load, never the worker's pack; paid in full on finishing (`_finish`) | Released at dawn after `days` 1: wage and goods back (`dawn`, `release`). One job per worker | `manor_work.gd` header, `take`, `release`, `_finish`, `dawn` | VERIFIED |
| **The manor's tool orders** (OD-16 b, EQ-19) | Manor to a smith: a real NPC-to-NPC procurement order | One tool for a named worker, at its value | **Paid in advance** (`smith.coins += advance`), unrestricted | The smith forges it and it goes to the worker (`_deliver_orders`) | Lapses after `manor_order_days` 10 or if the smith dies or quits; **the advance is not returned** | `npc_brain.gd::_support_trades`, `_deliver_orders`; `World.manor_orders` (saved) | VERIFIED |
| **Hired carriers for a building site** | Employer (the API accepts the player or a household, `hh:<n>`) to an NPC out of work. Only the player's talk window calls it today (`game_ui.gd::_helper_choices`) | A day's carrying for `helper_wage` 6, plus an optional budget to buy materials with the employer's money; a friend carries for free (CRT-06) | **Paid in advance**, all or nothing (`Construction::_pay`) | Carries the employer's goods in its own load | Ends with the day or the site; the load goes back to the employer's store (`end_contract`) | `construction.gd::can_hire`, `hire`, `_pay`, `end_contract` | VERIFIED |
| **Stall attendants** | Player to an NPC | A day's wage `attendant_wage` | **Paid in advance** from the till, then the purse | Not goods: a service | Day by day | `business.gd::hire_refusal`, `hire`, `_pay_wage` | VERIFIED |

Shared machinery the contract can stand on:

| Piece | What it does | Evidence | Label |
|---|---|---|---|
| `World::trade` | Atomic sale: checks coins, stock and room, then moves goods and coins together, or nothing | `world.gd::trade` | VERIFIED |
| `World::transfer`, `Inventory` | All-or-nothing moves; counts never go negative | `world.gd::transfer`; `inventory.gd` header | VERIFIED |
| World refs | One way to name any party: "player", `npc:<id>`, `hh:<n>`, the manor (`World.PLAYER`, `npc_ref`, `hh_ref`, `MANOR`) | `world.gd`; `construction.gd::_take` | VERIFIED |
| Necessity reserve (OD-19, PAR-02A) | `World::necessity(who)` estimates the coins a person needs over `reserve_days` for food, fuel, medicine and rent, less expected income and what the household holds; `reserve_of` caches it; `can_afford` and `purchase_qty` use it for every NPC purchase | `world.gd::necessity`, `reserve_of`, `can_afford`, `purchase_qty` | VERIFIED |
| Skills (PAR-01) | `Skills.level`, `Skills.has`; recipes' skill levels; `work_craft`, `work_mine`, `work_felled` are the one way to make or gather | `world.gd::work_*`; `skills.gd` | VERIFIED |
| Tools | `JOB_TOOL` (woodcutter axe, miner pickaxe); `ResourceNodes` node `tool`, `tool_required` | `npc_brain.gd` line 1789; `resources.json` | VERIFIED |
| Time | Working hours 7:00-18:00 (`NPCBrain.WORK_START`, `WORK_END`); per-unit minutes in `balance.json` (`mine_minutes` 25; `chop_minutes`; recipes) | `npc_brain.gd` lines 7-8 | VERIFIED |
| Prices | Buy and sell prices by stock and local supply (`World::sell_price`, `buy_price_at`, `deal_price` with Trading skill, `player_quote` with the friend's price) | `world.gd` | VERIFIED |
| Relations | Regard, friendship, "helped" (`Relations::peek`, `player_friend`, `helped`); a proposal can already be refused with a reason (`Relations::propose`) | `relations.gd` | VERIFIED |
| Memory | `NPC::remember` notes ("hired ...") | `quests.gd::complete` | VERIFIED |
| Talk window | Choices built per NPC: quests, "Any work for me?", hiring carriers, trade, gifts, friendship (`game_ui.gd::_quest_choices`, `_talk_view`, `_relation_choices`, `_helper_choices`) | `game_ui.gd` | VERIFIED |
| Quantity picker | The one "how many?" control (slider, -/+, Max, live total, Confirm or Cancel; keyboard, pad and touch) | `game/scripts/ui/quantity_picker.gd` | VERIFIED |
| Negotiation | **None anywhere**: no haggling or counteroffer in the code (searched `game/scripts`) | none | VERIFIED |

**APPROVED design already covering contracts:**

- The Living Economy design (EXP-D, its own build, placement OPEN as OD-LE-01) defines a **Contract** record:
  "Parties, quantity, price, delivery, deadline, deposit, obligations, renegotiation and breach". It also defines
  Offers ("expiration, visibility"), Reservations and Credit, and requires "offer expiry, partial fills,
  counteroffers ... delivery terms" and "atomic settlement" (sections 3 and 5 of
  `docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.txt`).
- Its stage **LE-01** is "Shared actor, need, offer, knowledge and contract model".
- Its open decisions include OD-LE-02 (board, direct negotiation or both), OD-LE-03 (wages, rents and service
  contracts), OD-LE-05 (loans and default), OD-LE-07 (restricted advances) and OD-LE-13 (cancellation, penalties,
  death of a party).

## 3. One contract record (RECOMMENDATION)

The record should **be** the Living Economy's Contract record, built first in its smallest form, so that EXP-D extends
it rather than replaces it:

| Field | Meaning |
|---|---|
| `id` | Stable id (saved; never reused) |
| `buyer`, `seller` | World refs: "player", `npc:<id>`, `hh:<n>`, the manor |
| `item`, `qty`, `price_each` | The three terms the owner named; `total = qty x price_each` |
| `deadline_day` | Agreed day (OPEN policy, section 6) |
| `terms` | Payment timing, partial delivery allowed, deposit; defaults set by the owner's policy answers |
| `state` | offered, countered, accepted, fulfilled, lapsed, cancelled, breached |
| `delivered`, `paid` | Units handed over, coins paid so far (never above `qty` or `total`) |
| `reserved` | Buyer's coins set aside and not spendable (as `Quests` and `ManorWork` do today), counted in the census |
| `history` | Offers and counters with day and who; read by memory and later by NPC Judgment (Build 19) |

Settlement rules:

- **One module** (proposed `game/scripts/core/contracts.gd`) is the only code that moves contract goods and coins.
  It uses `World::trade` and `World::transfer`, so every move is all or nothing.
- **Delivery** moves only goods the seller actually holds. **Payment** comes only from `reserved`, or from the
  buyer's coins at that moment if the terms allow.
- **No double counting.** A delivery and its payment are one step. The unit count and the paid coins can never
  pass `qty` or `total`. The record is saved with the world, so a save in between cannot duplicate anything.
- **The interface only shows.** It shows terms, the quantity picker and the NPC's reply; the rules live in
  `core/`, which matches DVW-A12.

How the existing mechanisms relate (RECOMMENDATION; each move is a later, separate change with its own tests):

| Existing | Relation |
|---|---|
| Manor tool orders (`manor_orders`) | The first to become contracts: already NPC-to-NPC procurement with an advance and a deadline |
| Paid work quests | Become NPC-made contract offers (fixed terms today; negotiable later) |
| Manor quarry job | The manor as buyer of stone. Haul and mend stay jobs (services) |
| Carriers and attendants | Day-labour **service** contracts, not goods; left as they are until OD-LE-03 decides on service contracts |

## 4. How an NPC could evaluate an offer, from what exists (RECOMMENDATION)

Every input below exists today. The decision is a deterministic score, with no new random draws on `world.rng`; if
any chance is wanted it uses a dedicated seeded stream.

| Question (directive) | Existing signal |
|---|---|
| Can I obtain or produce it? | Gather: a node that gives the item (`ResourceNodes::sources_of`), with stock left (`remaining`, `Quests::deposit_left`). Make: a recipe I have the skill for (`work_craft`'s level check, `NPCBrain._can_make`). Buy: a seller with stock (`World::sell_price`, `for_sale`) |
| Do I have the skills and tools? | `Skills.level`/`has`; the node's `tool`; my inventory |
| Is the quantity feasible? | Units per working day = (18:00 - 7:00) x 60 / minutes per unit, x days to the deadline, less hours already committed |
| Is the price worthwhile? | Compare `price_each` with what my best buyer pays now (`_buyer_for`, `sale_prices`) or what the inputs cost; and with my recent daily income (`income_days`, `earned`) |
| Existing obligations? | Open contracts, a manor job (`ManorWork::job_of`), a carrier contract (`Construction::contract_of`), an attendant post |
| Household needs? | `World::necessity` and `reserve_of` (OD-19): a household short of necessities values a sure income more; one with no gap can ask more |
| Available time? | As above, with the hours of the deadline |
| Competing opportunities? | My usual trade's expected earnings per day (the job market's `pay`, `NPCBrain::job_market`) |
| Relationship with the buyer? | `Relations` regard and friendship (a friend may accept a lower price, as a friend carries for free today) |
| Risk? | With reserved funds the buyer's risk to the seller is nil; the risk left is the seller's own feasibility, and a distant deadline |

The reply:
- **Accept** when it is feasible and the price is at or above the NPC's minimum.
- **Counteroffer** with the minimum price, a smaller feasible quantity or a later deadline.
- **Reject** with a stated reason in the game's words (as `can_hire` and `Relations::propose` give reasons today).

Hard limits: an NPC never accepts what it cannot do. The richer judgment belongs to Build 19 (NPC Judgment) and
EXP-D, and plugs into the same function.

**VERIFIED gap:** villagers act through their trade's planner (`_miner`, `_woodcutter`, ...). An NPC accepting a contract
outside its trade needs a general "obtain this item" plan: gather, craft or buy, then deliver. Parts exist (a carrier
buys materials at the market for the employer, `Construction::plan_helper`; `_get_tool` buys tools), but no general
planner does. That planner is the largest piece of new work.

Note: the owner's example "iron nuggets" corresponds to the game's **iron ore**; there is no "iron nugget" item
(`game/data/items.json`). VERIFIED.

## 5. Which build (RECOMMENDATION; the owner decides, OPEN)

- **Not Build 16.**
  - The Build 16 scope (long-term equilibrium; register target 16) has no contract entry.
  - EXP-D's owner wording forbids folding the overhaul into earlier builds; earlier builds "may expose compatible
    interfaces, never implement it early" (`docs/EXPANSION_ROADMAP.md`).
- **Options:**
  - (a) **A first slice in Build 17 as CON-01**: the record, settlement, player-to-NPC offers in the talk window, and
    NPC evaluation from the signals above. MIN-H then uses it for mining labour in place of a mine wage (B7-006).
  - (b) **Wait for the Living Economy build** (proposed Build 20, OD-LE-01). Mining in Build 17 then keeps today's
    hire quests and manor quarry job.
- **Recommendation: (a), limited to goods procurement.** Build 17's mining work otherwise needs a mining-specific
  wage, which the owner has just rejected. Designing the slice as LE-01's Contract record means EXP-D grows it
  (offers board, credit, renegotiation) instead of replacing it.
- **Dependency:** NPC-to-NPC contracts and NPCs working outside their trade need the general "obtain" planner. That
  can be the second half of the slice, or LE-03.

## 6. Policy details the owner has not decided

Each item gives what exists today, the options, their consequences and a recommendation. None of these is
established by this document; the recommendation is the proposed default until the owner answers.

1. **Payment in advance or on delivery.**
   - **Existing:**
     - Quests and manor jobs: reserved at acceptance, paid on completion.
     - Tool orders, carriers and attendants: paid in advance.
   - **Options:**
     - (i) On delivery, with the buyer's funds reserved at acceptance.
     - (ii) Fully in advance.
     - (iii) A deposit, the rest on delivery.
     - (iv) On delivery without reservation (credit).
   - **Consequences:**
     - (i) Safe for both sides, and the existing rule.
     - (ii) The seller may spend the money on food first: EXP-D section 8 calls that a legitimate choice, but it
       needs OD-LE-07's restricted-advance rule.
     - (iii) Needs forfeit rules.
     - (iv) Needs default and collection rules (OD-LE-05).
   - **Recommendation:** (i) as the default; (iii) as an option the buyer may offer; (iv) only once credit exists.
2. **Partial delivery.**
   - **Existing:** none. Quests are all at once; manor jobs pay only when finished.
   - **Options:**
     - Allowed, each unit paid as delivered.
     - Allowed, paid at the end.
     - Not allowed.
   - **Consequences:**
     - Paying per unit suits "price per unit" and big orders (70 wheat over several days), and keeps money moving.
     - All-at-once makes the seller carry the whole risk until the end.
   - **Recommendation:** allowed, paid per unit from the reservation at each handover.
3. **Deadlines.**
   - **Existing:** quests 1-2 days; manor jobs 1 day; tool orders 10 days. Lapse at dawn.
   - **Options:** the buyer sets one in the offer; a default from the feasibility estimate; no deadline.
   - **Consequences:** no deadline ties up reserved money indefinitely.
   - **Recommendation:** the buyer sets it, proposed by default from the seller's feasible rate. It is negotiable
     like price and quantity.
4. **Cancellation.**
   - **Existing:** a manor job's taker can give it up (wage and goods return); quest givers cannot cancel; lapse
     is automatic.
   - **Options:**
     - Either side freely before delivery starts.
     - After acceptance only with a fee or a forfeited deposit.
     - Never.
   - **Recommendation:**
     - Free before acceptance.
     - After acceptance, the buyer may cancel and pays for units already delivered; the seller may withdraw and
       keeps what was paid for delivered units.
     - Any agreed deposit is forfeited by the side that cancels.
     - Ties to OD-LE-13.
5. **Default and breach.**
   - **Existing:**
     - Quests lapse with only a note.
     - Tool orders lapse and the smith keeps the advance.
     - No reputation effect.
   - **Options:**
     - Lapse only.
     - Lapse plus regard loss and a memory.
     - Money penalties.
     - Lawful enforcement.
   - **Consequences:** penalties need an authority and rules (politics, OD-LE-06); reputation needs memory, which
     Build 19 deepens.
   - **Recommendation:** lapse; reserved money back to the buyer; regard loss through `Relations` and a memory
     note; no money penalty beyond an agreed deposit until OD-LE-05/06/13 are answered.
6. **Escrow and reserved funds.**
   - **Existing:** quests and manor jobs reserve, and reserved coins are counted in the census.
   - **Options:** always reserve the full unpaid value; reserve a share; none (trust).
   - **Recommendation:** always reserve the unpaid value at acceptance. It is the existing rule and the simplest
     way to rule out unbacked payment.
7. **All-at-once delivery.**
   - Covered by item 2.
   - **Recommendation:** not required; the buyer may ask for it as a term.
8. **Renegotiation after acceptance.**
   - **Existing:** none.
   - **Options:** not allowed (cancel and re-offer); by mutual agreement in conversation; automatic.
   - **Recommendation:** not in the first slice; cancel and re-offer covers it. Mutual renegotiation comes with
     EXP-D (its Contract record names renegotiation).

Further details to settle with these:
- **Death of a party.** Existing: a dead giver's reservation is released.
- **Where delivery happens.** In person, or to the buyer's store or site.
- **Who may see offers.** OD-LE-02.
- **Whether the manor's contracts follow the same rules.** Recommendation: yes.
- **The player's limit on open contracts.** Today quests cap at `quest_max_active` 3.

## 7. Tests the slice would need

- **Conservation.** Coins and goods are conserved through offer, accept, partial delivery, lapse, cancel and death;
  `reserved` is counted in the census.
- **No duplicates.** No duplicate payment or delivery across save and load.
- **Feasibility.** An NPC rejects what it cannot do (no tool, no skill, no stock, impossible quantity), and
  counteroffers deterministically for a fixed seed.
- **Parity.** The same evaluation for a player-made and an NPC-made offer.
- **Input.** The talk window works with touch, pad and keyboard through the quantity picker.
