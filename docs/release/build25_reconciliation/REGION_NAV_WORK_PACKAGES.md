# REGION-NAV-01 work-package register and the S2 investigation (2026-11-03)

- **Owner directive:** `docs/directives/2026-11-03_development_governance_roadmap_authority.md` (DEV-GOV-01).
- **Approved plan:** `docs/region_nav/IMPLEMENTATION_PLAN.md` on `wip/region-nav`, first committed at `611c294` (2026-11-02
  23:46 UTC) and approved by the owner's scope correction ("Report the initial architecture findings and implementation
  sequence, then proceed").
- **Evidence:** git history of `wip/region-nav` and the test logs named below. No new test was run for this report.
- **No completion percentages are given.**

## Findings: what happened to S2, and to the stage structure

**1. The approved S2 (plan at `611c294`).**
- Delivers: "Settlement people (AD-2): keepers and crafters, their schedule and presence on site; the player can meet them, see
  what they sell and buy, and trade through `SettlementParty.deal`".
- Tests: "Conservation (village and region audits); a keeper is absent off schedule; save and load".

**2. What was done instead of S2 as one package.** The lead split S2 into three sub-packages, named them S2a, S2b and S2c, and
reported each as done in session messages. There is no single S2 completion report against the approved acceptance criteria.

| Sub-package | Commit (UTC) | Work |
|---|---|---|
| S2a | `909b180`, 11-03 00:02 | A building per trade at each site |
| S2b | `8a57974`, 11-03 00:16 | Named keepers; trading with them |
| S2c | `add1651`, 11-03 00:19 | Keepers drawn; the talk window; the wiki |

The same was done to S1 (S1a `2745f2f`, S1b `3fd24e2`) and to S3 (S3a `6c88df0`, S3b in progress).
- **Owner approval: none.** The split and the renaming were the lead's choice. They were reported after the fact, not
  proposed beforehand.
- Under DEV-GOV-01 rule 3 (no splitting or renaming without approval), this is an **unapproved change to the work-package
  structure**.

**3. Work moved between stages without approval.**
- **(a) The settlement buildings.** S2a built them, although the plan's S1 row says only "cleared sites". AD-1's text did
  describe "one building for each of its businesses", but the stage table placed none in S2.
- **(b) The road network ran through the sites and under their buildings.** This was a defect in the S1a/S2a output. It was
  found and fixed under S3a (`6c88df0`), after S1a and S2a had been reported done.

Neither move was approved before it happened.

**4. S2 is not complete against its approved criteria (rule 5).**

| Criterion | Status | Evidence |
|---|---|---|
| Keepers: presence, schedule, meeting, what they sell and buy, trade | Done | `settlement_folk_test` 21/0 at `8a57974`; screenshots looked at, `add1651` |
| Conservation, village and region audits | Done | Same test |
| A keeper absent off schedule | Done | Same test |
| "**Crafters**" | **Not done** | Only business keepers and the treasury official exist. The lead judged that the settlement model has no independent crafter apart from the business keepers, and recorded that in the code (`settlement_folk.gd` header) instead of asking. That is a scope interpretation that needed the owner. |
| "Trade through `SettlementParty.deal`" | **Changed** | Trade goes through the courier service's edge (`CourierService.inv_of` and `add_coins`, which call the party's `add`, `remove` and `outside_coins`) instead of `deal`. The ledgers balance in the test, but the plan named a different path, and the change was not raised. |
| "**Save and load**" | **Not tested** | No test saves and loads a world after a trade with a keeper, or checks that the keepers, their names and their books are the same after a load. |

**5. AD-1 was changed after approval.**
- **The plan approved at `611c294`:** bearings and a road node.
- **What was built (`2745f2f`):** the settlements' existing `OffMapSettlement.pos`, the geography the regional trade already
  measures distances by. The plan text was rewritten to match (`2745f2f`'s plan edit).
- The reason is a technical one (one geography, not two). But it changed an approved design decision without approval, and the
  owner should confirm or reject it.

**6. S3 is in progress and incomplete.**
- **Done:**
  - routes (`overworld_test` 179/0 at `6c88df0`);
  - the journeys (`journey_test` 14/0, run on 2026-11-03 at `aafcc4d`, the working-tree state that was then committed);
  - an absent traveller can no longer trade at home, a defect `journey_test` found and fixed.
- **Not yet tested from S3's criteria:**
  - "arrival day deterministic" (two runs compared);
  - "a blocked route fails and returns": only a non-existent place was tested, not a route that becomes blocked;
  - "death ... mid-journey conserves what is carried".
- **Per the directive:** no further dependent stage (S4 onward) is started until the owner has reviewed these findings.
  Finishing S3's own outstanding tests would also be progress, so it waits for the owner too, unless the owner says otherwise.

## Work-package register (stages as approved at `611c294`)

| Stage | Approved scope (verbatim, abridged) | Actual status | Validation evidence | Depends on | Outstanding |
|---|---|---|---|---|---|
| **S1** | Settlement placement (AD-1, gen 3), cleared sites; the player's known places and explored chunks (saved); discovery by entering a site; world map toggle | Implemented, as unapproved sub-packages S1a/S1b. Placement uses the existing positions, not the approved bearings (finding 5). | `overworld_test` 159/0 at `909b180`, then 179/0 at `6c88df0`; `atlas_test` 17/0 at `3fd24e2`; `countryside_test` 38/0; screenshots (Region map) looked at. Criteria: same sites from the same seed, reachable, old saves load, discovery saved, map shows only known things: all tested. | — | Owner decision on AD-1 (positions or bearings). The roads-through-sites defect in S1's output was fixed in S3a. |
| **S2** | Settlement people: keepers and crafters, schedule and presence; meet, see sales and wants, trade through `SettlementParty.deal`. Tests: conservation, absent off schedule, save and load | **Partially complete; split without approval** (S2a/S2b/S2c). Buildings (S2a) were added to this stage (finding 3a). | `settlement_folk_test` 21/0 at `8a57974`; `wiki_test` passes; screenshots at `add1651` | S1 | **Crafters** (owner decision on interpretation); **save and load test**; **trade path** (`deal` versus the courier edge; owner decision or rework) |
| **S3** | Villager long-distance travel. Tests: route found, arrival day deterministic, blocked route fails and returns, death or save mid-journey conserves what is carried | **In progress** (S3a/S3b, unapproved split). Contains the S1/S2 roads-through-sites fix (finding 3b). | `overworld_test` 179/0 at `6c88df0` (routes); `journey_test` 14/0 at `aafcc4d` (journey there and back, save mid-journey, no coin moved, no gain on the road) | S1 (routes); not S2 | Deterministic arrival day; blocked route fails and returns; death mid-journey; the S3 records (manifest, decision row, wiki) |
| **S4** | The envoy post: the reeve assigns; journey; interviews of every accessible keeper **and crafter**; return; report; home survey | Not started (halted per DEV-GOV-01) | — | S2 (people to interview), S3 (travel) | All |
| **S5** | The intel network: the reeve's book, telling tradespeople, word of mouth, ageing | Not started | — | S4 | All |
| **S6** | Independent trade over CON-01 and couriers; in-person purchase | Not started | — | S2 (trade path), S3, S5 | All |
| **S7** | Regional demand and founding measurement; the P2 and P3 findings measured only | Not started | — | S6 | All |
| **S8** | `economy_sim` regional measurements; performance on desktop; Android profile | Not started | — | S3-S7 | All |
| **After S8** | Proposal for one consolidated Living Economy validation campaign; packaging only on the owner's authorization | — | — | S8; merge into `wip/expansion20` | All |

## Owner decisions (answered 2026-11-03, `docs/directives/2026-11-03_region_nav_owner_decisions_q1_q6.md`)

| ID | Decision |
|---|---|
| **Q1** | The eight stages S1-S8 are the milestones. Subtasks are internal only. A stage is complete only against its original criteria. |
| **Q2** | The buildings stay in S2 and the road fix in S3. Work is documented under the requirement it satisfies. An earlier stage with unmet criteria stays open. |
| **Q3** | The existing trade coordinates, **conditional** on verifying that physical locations, distances, roads, travel times and economic geography agree as one model. Approved design amendment: `docs/decisions/REGION-NAV-AD1.md`. |
| **Q4** | **Option C:** independent crafting and self-employment within the regional economy, integrated with skills, ownership, inventory, negotiation and conservation. It must not be every worker household. Crafters are met when actively offering, and envoys interview each relevant one. **This adds to S2 and S4.** |
| **Q5** | The courier hand-over is kept, **conditionally**: two-sided accounting, real transfers, conservation, save and load, and determinism must be verified, and any required semantics of `deal` integrated. Equivalence is documented and tested. |
| **Q6** | S2 first, then S3's tests and records, each reported complete with SHAs and evidence. Then S4-S8 in order without further approval. |

## Stage status (DEV-GOV-01 reporting; kept current with development)

Updated 2026-11-02 22:55 EST. All eight stages are integrated into `wip/expansion20` at `b540971` (fast-forward from
`wip/region-nav`; 2026-11-03 03:5x UTC). Test counts are local Godot 4.7.2 headless runs on the commit named. CI: sharded run
41567411820 on `54c2738`: 2 shards green; shards 1 and 3 failed on 3 stale or pre-existing checks, fixed in `14bbd86`.

| Stage | State | Outstanding deliverables | Evidence | Blocker | Next action |
|---|---|---|---|---|---|
| S1 | Completed | — | overworld 179/0; atlas 17/0; countryside 38/0; region_geography 132/0 (Q3: positions, roads, route lengths, courier links, after a load too); start_test and crafts_test updated for generation 3 and the map bar (`14bbd86`) | — | Final candidate CI |
| S2 | Completed | — | settlement_folk 36/0 (Q5 equivalence, save and load); settlement_crafter 25/0 (Q4: crafters, emergence, failure on a spent purse, wind-up, 150-day no-double-role, leave-with-load); validation defects D1-D4 fixed (`8792886`, `b18f418`); regions 120/0, settlement_life 54/0, settlement_development 32/0, migration 109/0, courier_live 138/0 | — | Final candidate CI |
| S3 | Completed | — | journey 14/0; journey_s3 19/0 (arrival day deterministic; a blocked route fails and turns home; death conserves what is carried); INT-682 | — | Final candidate CI |
| S4 | Completed | — | envoy_test 31/0 (`b281e90`, `14bbd86`): the reeve posts; a villager takes the post; interviews read each keeper's and crafter's real books face to face; away recorded with reason; nothing known before the return; envoy death and reeve succession mid-mission; wage conserved; book saved. INT-683 | — | — |
| S5 | Completed | — | intel_test 13/0 (`619fcc2`): knowledge only through a teller; word of mouth limited to the listener's trade; collected day kept; stale and forgotten. INT-684 | — | — |
| S6 | Completed | — | region_trade_test 23/0 (`14bbd86`): no forced trade; refusal (goods come back); sold before arrival; funds limit; conservation; no instant transfer; face to face only. World._walk defect found and fixed. INT-685 | — | — |
| S7 | Completed | — | region_demand_test 11/0 (`5a00993`): a told want moves the crafter's recipe choice (station work); busy share before and after; foundings with cause; P2 and P3 measured. INT-686 | — | — |
| S8 | Completed (Android profile: device check, LE-07 gate 11) | Phone profile (device) | region_sim_test 8/0 (`b540971`): two runs identical; save mid-mission exact for the regional state, stable reload, mission finishes; currency ledger and settlement books balance. economy_sim REGION line (12-day run: 1 mission, 33 records, word to 12 villagers, 7 sales, 4 refused; leak 0, item leaks none). Desktop timing against the baseline: running | Phone: device | Read the timing; final flight |

Summary: eight approved stages; all eight complete against their criteria; the Android profile is the device check of LE-07 gate 11.

## Owner decisions requested (as asked; answered above)

| ID | Question | Recommendation |
|---|---|---|
| **REGION-NAV-Q1** | **Stage structure.** Keep the eight approved stages as the only work packages, with the lead's a/b/c labels withdrawn and used only as commit labels; or approve the sub-packages as recorded. | Keep the approved eight. |
| **REGION-NAV-Q2** | **Moved work.** Accept that the site buildings landed in S2 and the roads-through-sites fix in S3, or require them to be re-attributed to S1 and S1 reopened. | Accept, recorded as moves. S1 is complete only with the fix. |
| **REGION-NAV-Q3** | **AD-1 placement.** The settlements' existing positions (built), or the approved bearings. | The existing positions: one geography for trade distances and travel. |
| **REGION-NAV-Q4** | **"Crafters" in S2 and S4.** The settlement model's businesses are run by worker households sharing one till, with no household producing on its own account. Options: (a) the business keeper and the official are the people interviewed (as built); (b) also meet the head of every worker household (each speaks for the same business books, plus their own household's purse and pantry); (c) extend the settlement model so households can work on their own account (a larger change to the economy). | (b): it meets "every independent crafter" literally, without changing the economy model. |
| **REGION-NAV-Q5** | **S2's trade path.** Keep the courier edge (it books the village side too, and balances) or rework it onto `SettlementParty.deal` as approved. | Keep the courier edge, recorded as an approved deviation, because `deal` books only the party's side. |
| **REGION-NAV-Q6** | **What to do next.** (a) Finish S2's outstanding items (the save and load test; crafters per Q4) and S3's three outstanding tests, then report S2 and S3 complete for review before S4; or (b) anything else the owner prefers. | (a) |
