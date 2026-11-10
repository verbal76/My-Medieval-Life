# Build 25: work packages for the 29 open original items (B25-TRACK-69-02 section 4)

Planning only (owner 2026-11-10). No major feature is started without the owner's approval; deferred work is not cancelled.
Item status and evidence: `docs/audits/B25_69_ITEM_TRACKER.md`. File references are from the v14 audit at `fe7d8f8` and must be
re-located on the current development line before work starts.

The 29 = 3 awaiting integration + 1 awaiting device verification + 4 blocked + 21 not started.

## WP-0. Close on integration (4 items, no new code)

| Item | Closes when | Gate |
|---|---|---|
| SAV-03 (remaining maps), NPC-03, REG-06 | Batch 3+4 (`fbfd6ad`) is merged | owner's baseline decision after the attribution report |
| MP-05 | two-device play, a modified client's forged requests, reconnect and UI checks pass | two devices (owner or a test rig); `docs/multiplayer` device procedure |

## WP-1. Small, isolated, reproduce-first batch (14 items; can start now, one branch, does not touch running tests)

Rule for every item: write the reproduction test first. If it fails, fix minimally; if it cannot fail (unreachable), keep the
test as the evidence and record "not reproducible, guarded by test" (a status the owner reviews, not a silent close).

| Item | Kind | Reproduction / test | Likely fix size | Notes |
|---|---|---|---|---|
| SAV-05 | test gap | continuity tests serialize with production's full-precision `JSON.stringify(d, "", true, true)`; a precision-sensitive counterexample | test-only | no game change |
| DOC-SAV-01 | comments | correct `fauna.gd:28` (claims are rebuilt since SAV-03 on `fbfd6ad`), `journeys.gd:9`, `npc_brain.gd:238` | comments | after WP-0 for fauna wording |
| EMP-04 | suspected | two stations each with too little free time, summed enough: does the hire happen and can the worker work? | small | `skilled_place` |
| EMP-05 | reachability | can a village have zero fields (all burned/sold/claimed)? then the `w.fields[0]` path | guard, if reachable | |
| EMP-06 | intent | read FAMILY-01 and the day-labour rule; test an unemployed adult on a short-food day | likely none (intent) | report to owner if a rule gap |
| BIZ-06 | latent | force the final till `_keep` transfer to fail on venture close; assert coins conserved | small hardening only if reachable | |
| BIZ-07 | suspected + rule | a venture hand hired by a player keeps hand privileges? | small; exclusivity rule may need the owner | follows BIZ-05's rule |
| TRD-03 | hypothesis | can a player post an offer backed by chest goods? claim then transfer | small | |
| TRD-04 | latent | shipment with capped stores at both ends; recovery and conservation over save/load | small-medium | |
| NPC-04 | suspected | evening companion away on a journey, at a homestead, underground | small filter | |
| NPC-05 | measurement | `noted` key count and memory at day 365 | likely none | optional |
| REG-01 | suspected | save mid-road journey, load, compare path vs uninterrupted | small | |
| REG-03 | suspected | courier job whose sender dies or departs: where proceeds go | small-medium | may need an owner rule (estate) |
| REG-08 | recovery gap | courier job at a booth with a dead carrier and no replacement | small-medium | |

Validation for the batch: focused tests, strict CI, gate, one recorded 365-day campaign (one cycle for all 14).

## WP-2. Medium fixes (2 items now, 1 after a decision)

| Item | Plan | Test |
|---|---|---|
| NPC-01 | measure path searches per villager per hour on a seed; a per-target failure memo with a bounded back-off (like SIM-F2's buy_held), cleared when the map changes | inaccessible target: searches bounded; target opened: reached |
| MP-06 | a per-verb away rule (not gateway-wide: a rejoining guest is away until its first move, MP-D1) plus missing reach checks | modified-client requests while away; rejoin still works (net_c_test) |
| REG-02 debt part | after decision B below | a migrating household with open loans, each option |

## WP-3. Blocked items: the decisions needed

### A. INV-02: food in stash, homestead chests and courier stores never spoils (seven decisions)

Investigation and an off-by-default prototype exist (`wip/b25-inv02-proposal` `906f1a8`, `docs/design/INV02_SPOILAGE_PROPOSAL.md`;
flag off byte-identical; flag on: ledger exact, 60-day seed 1 village not worse). Each decision, its options and my recommendation:

| # | Decision | Options | Consequence | Recommendation |
|---|---|---|---|---|
| F1 | Storage classes | (a) no classes, extend today's rule to the missed holders; (b) open 1.5 / carried 1.0 / home 1.0 / cellar 0.5; (c) stronger contrasts (2.0 / 0.25) | (a) smallest; (b) storage matters, most food as tuned; (c) bigger swings | **(b)** |
| F2 | Off-map settlements | (a) never spoils (today); (b) same rates, audited; (c) one flat rate | (b) is the main regional effect to measure | **(b)** |
| F3 | Food in courier care | (a) none; (b) carried rate, sender bears the loss; (c) courier compensates | (c) adds a money rule | **(b)**, booths at the home rate |
| F4 | Base rates | (a) keep today's gentle rates; (b) faster for ale, bread, berries, raw meat, milk | (b) changes hunger more than all else | **(a)** now, revisit after measuring |
| F5 | Away guest's pack and chest | (a) spoils while away; (b) frozen while away, like wear | (b) offline players not punished | **(b)** |
| F6 | Eat the most perishable first | (a) today's order; (b) most perishable edible first | (b) realistic, offsets added spoilage, changes behaviour | **(b)**, as a separate small change |
| F7 | Preserving (salting, drying) | new mechanics and items | new content | **not now**; keep as a deferred idea |

Validation after a decision: four seeds over a year, conservation exact, save/load, determinism (proposal section E).

### B. REG-02 debt part: a migrating household's open loans

| Option | Consequence |
|---|---|
| (a) Debts travel with the household (stay owed; repaid from the settlement through the existing regional link, or on return) | most faithful; needs a cross-region repayment path |
| (b) Debts settle at departure from what the household carries/sells (the estate-sale rule of PROP-06), the remainder written off as a default | simple, uses the existing atomic estate sale; lenders may lose |
| (c) A household with open debts may not migrate until repaid | prevents loss; may trap poor households |

**Recommendation: (b)**, consistent with PROP-06's atomic estate sale and the existing default rule (Credit); the remainder is a
recorded default that hurts standing. Test: migrating with loans under the chosen option, coins conserved, creditor record correct.

### C. SAV-04: wildlife and combat transients not saved

| Option | Consequence |
|---|---|
| (a) Document the guarantee as "identical runs from the same save", accepting that a resumed game can differ from an uninterrupted one in wildlife and fights | no code change; matches current design |
| (b) Save the transients (fauna move RNG, animal intent/timers, NPC combat fields, tree damage) for exact continuation | save format change with migration; larger tests; long campaigns become exactly resumable |

**Recommendation: (a)** now, with the exception written into the save documentation; (b) only if exact continuation becomes a
requirement (e.g. multiplayer reconnect parity). Note SAV-02 already saves the economic in-hour state.

### D. REQ-B17F-JOBS: adult unemployment (6-30 adults at day 365), owner-deferred

Not cancelled. Options: (a) keep deferred (no work); (b) authorize an investigation only: measure unemployment by cause on the
current development line (after Batch 3+4) and report; (c) authorize a fix programme. **Recommendation: (b)**: the job system has
changed a great deal since Build 17 (EMP-01/03, BIZ-03, LE-03), so the old figure may no longer hold; measure before deciding.

## WP-4. Large systems: dependencies and test plans (no coding without approval)

| Item | What it needs | Depends on | Test plan |
|---|---|---|---|
| REG-04 (couriers travel physically; owner approved) | courier carriers walk the road legs (Journeys) instead of abstract day counts; booth hand-overs at arrival; loss on the road through existing route hazards | REG-08 (stranded jobs) and REG-03 first; Journeys determinism | delivery timing equals walked time; carrier death mid-road recovers the job; conservation; save mid-road; 365-day campaign |
| REG-05 (migrating households travel physically; owner approved) | the household walks to the settlement with its goods (the caravan-day teleport replaced); arrival hands over to the settlement | REG-02 decision (debts), PROP-06 estate sale timing, REG-04's travel pieces | departure to arrival with goods conserved; death on the road (estate); save mid-journey; settlement population counts |
| MP-02 (guest stall/shop management) | host-validated network verbs for arrears, till collect/deposit/withdraw, close, list/unlist, fetch stock, workroom stock/fetch, mirroring the host's UI functions | MP-03 store-auth rules (merged), property rules (`9fd18a5`) | per-verb host/guest parity; forged-request refusals with zero movement; two-device check |
| MP-07 (private records never shared automatically; owner approved) | a per-field audit of every snapshot sent to guests (justice cases, credit, relationships, stash, cart contents), filtered by viewer | MP-03, MP-05 sharing tiers | snapshot contents per viewer; a guest cannot see another's private records; host unaffected; two-device |
| REQ-JOB-02 (offered compensation on the manor job board; owner approved) | funded postings carry an offered wage; seekers compare offers; payroll from the posting's fund | BIZ-03 payroll rule (merged), EMP-03 seeker counting (merged), Employment | offer chosen by pay; fund conserved; vacancies filled; 365-day employment measurements (no pass/fail thresholds, WDR-022) |

## Recommended order

1. WP-0 integration as soon as the owner decides Batch 3+4 (closes 3; MP-05 needs devices).
2. WP-1 batch now, in parallel with the running validations (up to 14).
3. Owner decisions WP-3 (A-D); then INV-02 and REG-02's debt part.
4. WP-2 (NPC-01, MP-06).
5. WP-4 one system at a time after approval: REG-04 then REG-05 (shared travel pieces), MP-02 then MP-07, JOB-02.
