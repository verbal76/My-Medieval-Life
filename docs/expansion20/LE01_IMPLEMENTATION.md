# Expansion 20, LE-01: implementation note (actor, need, offer, knowledge and contract model)

Register LE-01 (batch X20-B3, worker F, branch `wip/x20-le01`, base `0b5287c`). Authority: owner directives 2026-10-26
(`docs/directives/2026-10-26_build22_expansion20_execution_authorization.md` and its amendment) and the carryover directive
of the same day (`2026-10-26_build19_carryover_audit_x20_integration.md` s.7, the Living Economy dependency rule).
Design: `docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.txt` s.3-6, 13, 14, 16. Contracts:
`LE01_DATA_CONTRACTS.md`. Developer reference only: nothing here is playable, so no wiki page changes.

## 1. What exists

Everything sits behind `game/data/economy.json` `"enabled": false` (shipped off). With it off the World builds nothing and
the two new live calls (`World.trade`, `World._new_day`) are skipped by `if economy != null`.

| Part | Script | What it does | What it never does |
|---|---|---|---|
| Actor resolver (extended) | `economy/econ_actor.gd` | `profile`, `controller`, `household_of`, `location`, `judged_person`; guest players (`player:<pid>`); "player" is now the host (it read the acting player) | cache, move, decide; invent a business ref |
| Needs | `economy/econ_needs.gd` | derives food, tool, input, contract and housing needs from existing state; dirty set; `refresh(limit)`; saved table | write game state (it avoids `evaluate_household`, `_market_price`, `reserve_of`, whose caches would change live results); rank needs |
| Offers | `economy/econ_offers.gd` | asks over reserved goods, bids over reserved coins; withdraw, expire, `record_fill` (books a trade already made, shrinks the reservation); indexes by item and actor; `backed` | sell, set a price, tell anyone |
| Knowledge | `economy/econ_knowledge.gd` | who knows who deals in what at what price, by own offer, dealing (a completed trade) or contract; age; indexes by knower and subject | store trust, regard or opinion; forget; accept undecided sources |
| Contract links | `economy/econ_contracts.gd` | `view` joins a CON-01 contract with the model (owed = the RECON-01 hold, escrow); `earmark` an input for an accepted contract; `sweep` follows endings | create a second contract record, a penalty or a breach rule |
| Observers | `economy/economy_foundation.gd` | `on_trade` (event, dealing knowledge, needs marked) and `dawn` (expiries, links, contract terms learned once by cursor, needs refresh) | anything a villager or the player decides by |

Persistence: the optional `"economy"` key gains `needs`, `offers`, `knowledge`, `contracts`, `contract_cursor`, each only
when non-empty. A foundation-only save, or one without the key, loads with those parts empty. Disabled: the D2 rule (the
section is carried byte-identical; tested through three save cycles with the new parts). No `SAVE_VERSION` change.

Determinism: ids count up, every listing and saved array is sorted, knowledge is keyed by a stable string, no RNG, no wall
clock. Cost (E20-RISK-QUEUES): every operation touches an index (owner, item, knower, subject, linked contract); the only
walks are the dirty set (bounded by `needs.refresh_budget` a dawn), open offers at expiry, linked contracts at the sweep, and
contracts newer than the cursor. A trade's observation costs the same with 500 extra villagers (test).

## 2. The shared judgment model (owner rule 2026-10-26, carryover directive s.7)

The economy holds no reputation, trust, opinion or decision engine. Economic knowledge is commercial fact only. When a
decision later needs what one person thinks of another it reads the Expansion 19 model:

| Need | Existing shared API |
|---|---|
| the person judged for an economy ref | `JudgmentLive.person_of_ref` (npc, player, household's responsible adult), via `EconActor.judged_person` (a till: its controller) |
| trust | `JudgmentStore.trust_of(a, b)` |
| regard, friendship, kin | `Relations.peek(a, b).regard`, `JudgmentSocial.regard / friends / kin` |
| choosing among feasible options with opinion as one factor | `JudgmentWeighting.choose(store, cfg, chooser, profile, candidates, key)` (as `JudgmentLive.pick_seller`, `seller_order`, `pick_food_seller` do) |

Missing or incomplete for the economy (reported, not substituted):
1. **No neutral opinion read for a trade.** `JudgmentLive.willing` and the `pick_*` functions return a choice or a yes/no;
   there is no call returning the chooser's weighted opinion of a counterparty as a factor beside need, price, scarcity and
   alternatives without itself choosing. LE-02 should pass those as candidate factors to `JudgmentWeighting.choose` with a
   trade profile; whether the existing profiles (`trade_sell`, ...) weigh price, scarcity and alternatives, and that a
   strong dislike can never on its own refuse a feasible trade, needs the Build 19 recovery workstream to confirm.
2. **No judged person for institutions or settlements.** `person_of_ref` gives -1 for the manor (its reeve is not
   substituted), the chapel, tills held by the manor and `region:` parties.
3. **No reliability of commercial information.** `JudgmentStore.belief` covers judged events; gossip carries judgment
   events, not prices or offers. How heard prices travel and how far they are trusted is OD-LE-10 and must ride on that
   channel, not a second one.
Nothing in LE-01 activates a decision that depends on opinion or trust.

## 3. OWNER DECISION placeholders

Each is a named constant that does nothing while the economy is off and decides nothing while it is on; all are listed in
`economy.json` `owner_decisions`.

| Placeholder | Where | Holds | Decision |
|---|---|---|---|
| `EconOffers.VISIBILITY` | every offer's `visibility` | "undecided"; posting tells nobody | OD-LE-02B offer visibility |
| `EconKnowledge.SOURCES_UNDECIDED` in_person, notice | `learn` refuses, counts `refused` | no knowledge by sight or board | OD-LE-02B |
| `EconKnowledge.SOURCES_UNDECIDED` word_of_mouth, rumour; `MEMORY`; `reliability()` = -1 | knowledge | no hearsay, no decay, no forgetting, no confidence | OD-LE-10 rumour, memory, reliability |
| `EconActor.BUSINESS_IDENTITY` | resolver | no `business:` ref; a business is its till plus its holder (ECON-P3) | OD-LE-04 founding/ownership/inheritance, OD-LE-07 account separation |
| `EconNeeds.SUBSTITUTION` | needs | no material substitutes (food's EDIBLE list is existing rule) | OD-LE-08 barter, rental, repair, substitution |
| `EconContractLinks.DEATH_OF_PARTY` | links | `Contracts.on_death` (OD-29 provisional) stays the rule; the sweep follows | OD-LE-13B death of a party |
| no needs derived for the player | needs | the player decides for themselves | OD-LE-14 player intervention and visibility |
| `needs.refresh_budget` 64 | economy.json | an engineering bound, not an acceptance target | OD-LE-15 performance and population targets |

Not placeholders, deliberately absent: need urgency and strategy (the weighing is LE-03's decision model; LE-01 records
shortfall, cover days and deadlines); prices (LE-02 under OD-LE-02's approved answer).

## 4. What LE-02 can and cannot do

Can, without further owner answers: implement OD-LE-02's approved answer (asking prices informed by supply, demand,
scarcity and completed trades; negotiated deals with limited counteroffers; no guaranteed deal) as offers posted by the
existing traders, settled atomically through `World.trade` then `record_fill`; partial fills, expiry and minimum lots; the
seller's input earmarks for accepted CON-01 contracts; OD-LE-13's approved context-sensitive renegotiation (partial
delivery, extension, changed payment, cancellation; no automatic penalty) on CON-01's counters; knowledge by dealing and
contract.

Cannot until answered: who sees an offer beyond its poster and the parties (OD-LE-02B), so every offer reaching anyone
else is blocked; hearsay prices and memory decay (OD-LE-10); interest and money loans (OD-LE-05B); a contract surviving a
death (OD-LE-13B); business accounts and identity (OD-LE-04/07); hoarding and speculation rules (OD-LE-11); what the player
sees (OD-LE-14); performance targets (OD-LE-15). And any purchase choice weighed by opinion waits for the Build 19 judgment
recovery (section 2).

## 5. Verification

`game/tests/economy_model_test.gd` (every contract above, including a full day stepped with the model on and off: the
saved world identical apart from the economy key), `game/tests/economy_foundation_test.gd` (unchanged, still passing), and
the gates recorded in the worker report and the register (G0 with the switch off; `economy_sim.gd --economy` 30 days on
seeds 1 and 2 for conservation and behaviour).
