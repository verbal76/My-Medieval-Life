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
   trade profile (`trade_buy` weighs necessity, sole source, affordability, urgency and disposition against doing
   without); whether the profiles weigh price, scarcity and alternatives as LE-02 needs is for the Build 19 recovery
   workstream to confirm.
2. **No judged person for institutions or settlements.** `person_of_ref` gives -1 for the manor (its reeve is not
   substituted), the chapel, tills held by the manor and `region:` parties.
3. **No reliability of commercial information.** `JudgmentStore.belief` covers judged events; gossip carries judgment
   events, not prices or offers. How heard prices travel and how far they are trusted is OD-LE-10 and must ride on that
   channel, not a second one.
Nothing in LE-01 activates a decision that depends on opinion or trust.

**Owner rule on opinion and trade (2026-10-26, verbatim):** "An NPC absolutely may refuse a transaction because of their
opinion of another character. However, reputation must not act as a rigid, automatic prohibition based on a numerical
threshold. NPCs weigh their opinions against needs, scarcity, available alternatives, prices, relationships, personality
and other circumstances. A villager who dislikes someone may still trade with them out of necessity. Another villager in
the same circumstances may refuse because their dislike outweighs the benefit. Both outcomes are valid. The Judgment
System influences decisions rather than dictating universal outcomes. [...] Do not implement a hard-coded reputation
cutoff or a rule requiring every transaction to remain possible regardless of NPC preference."
So at the decision seam (LE-02 onward: whether to deal, with whom, at what terms) opinion is one factor in the shared
`JudgmentWeighting.choose`, weighed with need, scarcity, alternatives, price and relationships under each person's
personality (`trait_weight`), with doing without (`forgo`) a valid result. LE-01 has no regard or reputation threshold, no
rule that every trade stays possible, and no clamp on the opinion's weight. `economy_model_test.gd::test_opinion_is_weighed`
shows on the shared engine that the same strong dislike leads to a deal or a refusal depending on need, alternatives and
the person. The weights and formulas are owner-held (LE-02+); LE-01 adds none.

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

## 5. Verification (2026-10-26, code at `fc8f648`; later commits change only comments, docs and tests)

| Check | Result |
|---|---|
| `economy_model_test.gd` | 113 checks, 0 failures (includes a full day stepped with the model on and off: the saved world identical apart from the economy key; and `test_opinion_is_weighed`) |
| `economy_foundation_test.gd` | 89 checks, 0 failures (unchanged) |
| `run_tests.gd`, `start_test.gd`, `multiplayer_c_test.gd` | 3600 checks, 523 steps, 340 checks; 0 failures |
| G0, switch off (`tools/sim_gate.py`, seeds 1 and 2, 30 days, checks 10 and 30) | PASS, identical to the baseline |
| `economy_sim.gd --economy`, seeds 1 and 2, 30 days | LEAKS: currency 0, items none, deposits none, animals none (both seeds); fingerprints at days 10 and 30 identical to the G0 baseline, so the model changed no behaviour |

What the model recorded in 30 days: seed 1: 500 events (the ring full, ordered), 1944 knowledge entries, 119 needs recorded
(13 still dirty), no offers, reservations or links (nothing in live play posts them yet); seed 2: 500, 1712, 127 (9). The
saved economy section was 442 KB and 401 KB, almost all knowledge from dealings; it grows with who has dealt with whom
(bounded by pairs and items, not by time). Whether that size is acceptable on a phone is a performance question for
OD-LE-15; a compact encoding is an engineering option for LE-02 that changes no rule.

## 6. Till ownership (owner directive 2026-10-27, X20-COMPLETE s.2B; branch `wip/x20-foundation`)

**Finding.** The live money was never ownerless: storefront tills (`buildings[id].front.till`, ECON-P3) and trade-counter tills
(`buildings[id].counter.till`, B18-DP-01) are counted (`Business.tills`, so `World.total_coins` and the holdings census) and settled each
morning by `BusinessMoney.daily`. The gap was the model's: `EconActor` had refs only for `stall:` and `shop:` tills, so money in a
storefront or counter till had no actor, controller, location or judged person, and no event or reservation could name it.

**Model refs (read only, uncached).** `front:<building id>` and `counter:<building id>`: `kind`, `exists` (the building carries the
record; an older save without it has none), `coins` (the till), `controller`, `location` (the building), `profile`, `judged_person` (the
controller's person). `EconActor.till_refs()` lists every till `Business.tills` counts (stalls, shops, storefronts, counters, each by id),
so their coins add up to it; `economy_sim.gd --economy` prints that audit. `EconomyFoundation.on_trade` names the till a sale's proceeds go
into in the trade event's note (`till:front:<id>`, `till:counter:<id>`, from `BusinessMoney.till_ref_for`) and marks its controller's needs.

**One rule, not two.** The controller is read from the same functions the morning settlement pays by:
`BusinessMoney.front_owner(b)` (the household or villager holding the house; the holder's own ref when it is a player or the manor, whose
storefront tills `daily()` leaves alone; the manor when the holding household has ended: escheat) and `BusinessMoney.counter_owner(b)`
(the household holding the building, else the keeper who last served at it while they live, else the manor). `daily()` and `_payee` now
call them, so behaviour is unchanged (G0 identical). No `business:` identity was added.

**Defect found and fixed (coins paid to the wrong holder).** "A household that has ended leaves its till to the manor" (ECON-P3, the
comment and INT-340) was dead code for storefronts: `Property.household_ended` made the house the manor's first, `daily()` then skipped the
manor-held storefront, the till sat there, and the next household to buy or lease the house was paid the dead household's takings at its
first morning. `Property.household_ended` now calls `BusinessMoney.household_ended(ref)`, which moves the tills of the houses the
household held to the treasury (the existing `_settle` escheat, stat `front_till_escheat`) before the houses pass. Conserved; tested with
the economy switch off and on. Counter tills needed no change (the keeper is paid when the holder is gone; escheat when nobody is left).

**Cases audited** (`game/tests/till_ownership_test.gd`, 50 checks): world start (every till resolves, sum = `Business.tills`); a new
storefront built the villagers' way and its first sale; a counter's first sale; transfers by `set_owner` and `set_tenant` (household,
another household, the player, the manor); the holder household ending (escheat, and the regression: the next holder draws nothing); save
and load (round trip; an older save without `front.till` and without a `counter` record); closure (the player's shop: its till returns
to the player, the `shop:` ref goes, the storefront stays with an empty till); the switch off (the live escheat does not need the model).
Front and counter records are never removed by any code path, so "closure" of a villager storefront does not exist today.

**TILL-D1 (owner, 2026-10-28): "The household keeps its money. When it moves or gives up the property, its till balance is
transferred to its own funds. The next occupant receives an empty till."** `World.set_owner` and `World.set_tenant` now call
`World._handed_over`: when a house's holder changes, `BusinessMoney.keep_till` moves the whole storefront till to the household (or
villager) that held it, while one of them lives (`World.party`; stat `front_till_kept`, recorder `till_kept`); a player's or the manor's
storefront is unchanged, and a household with nobody left keeps the escheat. A whole household leaving the village takes its tills with it
(`Migration._household_out` calls `keep_tills_of` before packing, so the coins cross with its purses). Tests:
`till_ownership_test.gd::test_transfer` (let, lease ended, sale) and `test_till_d1_migration`.

**Verification (2026-10-28, code at `700d985`, with REC-DIAG).** G0 (`tools/sim_gate.py`, seeds 1 and 2, 30 days): PASS, identical to the
baseline. Suites: till_ownership_test 50/0, business_money_test 37/0, economy_model_test 113/0, economy_foundation_test 89/0,
property_test 123/0, business_test 160/0, run_tests 3600/0, start_test 523 steps/0, world_test 339/0, multiplayer_c_test 340/0,
recorder_test 214/0, Python tests/test_sim_gate.py 36 OK. Recorded 30-day runs (seeds 1 and 2) end on the baseline's day-30 fingerprints
(the recorder changes nothing); their archives verify with no problem.
