# Expansions 20 and 21: decision packet (2026-10-23)

Prepared under the owner's 2026-10-23 directive (`docs/directives/2026-10-23_expansions_19_20_21_progress.md`). Neither
expansion is authorized for implementation (register `builds` map: Build 20 "OD-30, OD-LE-01: numbering and placement
only", Build 21 "OD-30: numbering only"). This packet asks only what is needed to start each one. Recommendations are
agent proposals; nothing here is decided until the owner answers.

Sources: the LE-00 audit (`docs/expansion20/LE00_ARCHITECTURE_AUDIT.md` on `wip/expansion20-preparation`, d82f173) and the
Expansion 21 preliminary plan (`docs/expansion21/PRELIMINARY_PLAN.md` on `wip/expansion21-preparation`, 0eeb3df).

## Where each stands

| | Expansion 20, Living Economy | Expansion 21, Village Politics |
|---|---|---|
| Approved design | LE-00..07 approved in principle (owner design 2026-10-20) | VP-01 approved concept (directive 2026-10-19 Part III); stages VP-01A..E are proposals |
| Done | LE-00 read-only audit: today's economy by file, conflicts with Expansions 18 and 19, decision-to-stage map, LE-01..07 sequence | Preliminary plan: requirements inventory, dependencies, conflicts with the reeve and manor, Q-POL list |
| Code | None | None |
| Open owner decisions | OD-LE-02..15 (14); OD-LE-01 still shows open (see A0) | Q-POL-1..9 |
| Hard dependency | Expansion 19's meetings and memory (economic knowledge spreads through them); Build 18's settlement parties and contracts | Expansion 19's live judgment (voters decide from beliefs); OD-LE-06 (what the manor may do) |

## Expansion 20: what blocks the first stage

**A0. Record keeping, no new policy.** OD-30 (owner, 2026-10-21) already named the Living Economy Expansion 20 after Build
19, which is what OD-LE-01 asked. Recommendation: mark OD-LE-01 answered by OD-30.

**A1. Authorize Build 20 work.** Options:
- (a) not yet: stay on documents until Build 19 is integrated;
- (b) prospective and isolated, as PROS-01 did for 18 and 19: LE-01 on `wip/expansion20-preparation`, never merged or
  released before Build 19 is complete (one worker, within the two-agent limit);
- (c) full authorization.

Recommendation: **(b)**, once the five LE-01 decisions below are answered. LE-01 is data records (actor, need, offer,
knowledge, contract) built on code that exists (CON-01 contracts, party references, Build 18's settlement parties), so it
can be built and tested while Build 19 finishes.

**A2. The five decisions LE-01 needs** (the audit's first group). Each shapes a field of a shared record:

| Decision | Shapes | Earlier owner answers that bear on it | Recommendation |
|---|---|---|---|
| OD-LE-02 market board, direct negotiation or hybrid; visibility | the Offer's visibility | CON-01 negotiates directly; stalls are physical places of sale; SJD-Q10 no numbers in normal play | Hybrid: offers are made in person at stalls, storefronts and meetings; there is no village-wide board; a villager knows the offers they saw or heard of |
| OD-LE-10 economic rumour, memory, reliability | the Knowledge record | Expansion 19: trust from regard, gossip at each meeting weighted by closeness (2026-10-23), permanent memories | The same channel as Expansion 19 gossip: a price heard from someone carries its source, its age and the trust in that source; it goes stale, it is not forgotten |
| OD-LE-07 restricted advances; business and household accounts | the Actor's accounts | ECON-P3 (Build 18, approved): business money kept apart from the purse | Follow ECON-P3 for every business; advances for materials earmarked to the business account |
| OD-LE-13 cancellation, penalties, death of a party | the Contract's breach fields | OD-29 provisional defaults: no money penalty, a lapse returns coins, death ends the contract | Keep OD-29's defaults as final for LE-01; add a recorded breach that harms standing (Expansion 19 regard), with no money penalty |
| OD-LE-15 performance and population targets | data-structure budgets, LE-06 gate | none set (CLAUDE.md section 8); Expansion 19's proposed frame budgets | A mid-range phone at 30 fps with 500 villagers; the economy's daily work spread across frames, never more than 4 ms in one frame |

The other nine (OD-LE-03..06, 08, 09, 11, 12, 14) are needed only at LE-02..05 and can wait. Two already have partial
answers from Build 18: OD-LE-12 (the chapel's alms, CHAPEL-R2) and OD-LE-03 (manor wage rivalry, COMP-R1).

## Expansion 21: what blocks starting

**B1. Placement and gate (Q-POL-7).** Options:
- (a) politics waits for Expansion 19's live judgment;
- (b) an interim voter model now, replaced later.

Recommendation: **(a)**. A voter who decides "from knowledge, testimony, family memory, gossip, conduct" (VP-01, Rule 019)
is Expansion 19's judgment; an interim model would be built twice.

**B2. The starting village's political structure (Q-POL-1).** Options:
- the manor with a reeve, as today;
- an elected mayor;
- a council;
- a mixture (manor lord, elected reeve).

No recommendation without the owner's picture of the village. Every other Q-POL question depends on this one.

Q-POL-2..6, 8 and 9 (franchise, terms, privacy, ties, removal, constable, taxes) can wait until B1 and B2 are answered.
Nothing for Expansion 21 should start before Expansion 20's OD-LE-06 (what the manor may do), since offices take over the
manor's decisions.

## The short version for the owner

1. Expansion 20: allow LE-01 as isolated prospective work (A1 b) and answer OD-LE-02, 10, 07, 13 and 15 (or accept the
   recommendations above).
2. Expansion 21: confirm it waits for Expansion 19 (B1 a) and say how the village is governed (B2).
