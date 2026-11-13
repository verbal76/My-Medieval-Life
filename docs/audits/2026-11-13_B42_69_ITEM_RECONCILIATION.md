# Build 42: reconciliation of the original 69 audit items against `0bbee94` (Agent D, 2026-11-13)

Owner directive 2026-11-13 (`docs/directives/2026-11-13_build42_engineering_directive.md`, section 3). Read-only reconciliation:
no game code, no tracker or register edit (the lead owns `docs/audits/B25_69_ITEM_TRACKER.md` and the register). Item ids are the
original 69, unchanged, none added, merged, renamed or redefined. This document proposes; the lead decides any tracker change.

## 0. Inputs and how each fact was established

| Input | Value | How checked |
|---|---|---|
| Code line reconciled | `0bbee94` (`wip/b41-stream-candidate` = `wip/b42-integration`): Build 40 `a5a0b7c` + stream fixes (`8c78e24`, `ab68133`) + NAME-01 rename | `git ls-remote`, `git log` |
| Tracker | `docs/audits/B25_69_ITEM_TRACKER.md` on `wip/requirements-control` `26b4695` (counts 43 / 0 / 21 / 0 / 1 / 4) | read in full |
| Register | `docs/requirements/requirements.json` on `wip/requirements-control` `26b4695` (1,294 records) | scripted search for every id |
| Cited commits | all 65 short SHAs cited in the tracker | `git merge-base --is-ancestor <sha> 0bbee94`: **62 ancestors; 3 not** (`02ad7aa`, `6bacff0`, `48d8aee`: records-branch documents, not code; expected) |
| Fix commits found beyond the tracker's citations | MP-06 `ab995ff`; MP-07 `548f0f2`, `228b519`, `e0f6ca6`, `0a96070`, `6643d5a`; INV-02 `619813b`, `1a4f489`; REG-02 journey `add5061`; ND-15 `d7217b8`; MP-05 `448fc0b` | all ancestors of `0bbee94` |
| Full CI | Tests 43321399738 on `b3c9eb5` (chain 12), all 12 shards green: the last full Tests run. **No Tests run exists on `a5a0b7c` or `0bbee94`** (Actions API `head_sha` query returns only Build and release runs) | Actions API |
| 365-day campaigns on `b3c9eb5` | Long simulations 43332151718 (seeds 1-2) and 43332156022 (seeds 3-4), **both completed, success**, 2026-11-12 23:50 to 2026-11-13 03:17 UTC. Seed 1: 365/365, 0 CRITICAL, 7 HIGH, 62 MEDIUM, 0 confirmed defects. Seed 2: 365/365, 0 / 66 / 31 / 0. Seed 3: 365/365, 0 / 30 / 44 / 0. Seed 4: 365/365, 0 / 15 / 39 / 0 | job logs of the two `flight / report` jobs (read only). **Not yet recorded in the tracker or the state file** (state file line 42 still says "running") |
| Sim gate, Build 40 `a5a0b7c` | Build and release 43362745451: six packages and both Windows smokes success; `sim-gate / sim-gate` **failure** (expected known baseline findings per `docs/release/EXTRA_LIFE_PREVIEW_B40.md`; not re-analysed here) | Actions API |
| Sim gate, Build 41 `0bbee94` | Build and release 43527275522: six packages and both smokes success; `sim-gate / sim-gate` **in progress** at 23:49 UTC (not touched) | Actions API |

What changed in game code between `b3c9eb5` (the last full CI and campaign) and `0bbee94`: 18 script files, +451/-38
(`git diff --stat b3c9eb5 0bbee94 -- game/scripts`): the hunt reaction (`fauna.gd`, `animal.gd`, `combat.gd`), ND-19 re-pathing
in `World._walk` and the fence stand (`world.gd`, `farm_plots.gd`), ND-28 guest pacing and reach (`net_actions.gd`, `main.gd`),
journey findings 2-3, the player's sub-stepped movement (`8c78e24`), village tile warm-up (`ab68133`) and the rename. Items whose
code paths these touch are marked below (NPC-01, REG-01, SAV-04, MP-06).

## 1. Reconciled counts

| Status | Tracker | Reconciled (this review) | Note |
|---|---:|---:|---|
| Completed and verified (engineering) | 43 | 43 | ancestry and CI listing confirmed for every one; regression on the Build 42 candidate still owed (Group 1, Group 2) |
| Meets the tracker's own verified criteria today but not yet promoted | - | 2 | SAV-05, DOC-SAV-01: production change is comments only (`c1d4b7c`) or test only (`0d6a484`), so Sim is n/a as for TRD-05; Full CI Y on `b3c9eb5`. Proposed: promote after Group 1 |
| Integrated, awaiting verification | 21 | 19 | see the breakdown by missing category below |
| Not started | 4 | 4 | REG-04, REG-05, MP-02, JOB-02: no commit on `0bbee94` or any remote branch (agents F, G, H only just assigned) |
| Blocked | 1 | 1 | B17F-JOBS (owner question; measurement predates EMP-06 day labour) |
| **Total** | **69** | **69** | |

The 19 still awaiting verification, by what is missing (an item can lack more than one):

| Missing | Items | Count |
|---|---|---:|
| Full CI on a commit carrying the Build 40/41 changes (every item) | all 19 | 19 |
| Sim: satisfied by the chain 12 campaigns on `b3c9eb5` under the tracker's definition (0 CRITICAL, 0 confirmed) **once the lead accepts the HIGH findings as triaged**; a candidate campaign still owed by directive section 10 | EMP-04, EMP-05, EMP-06, BIZ-06, BIZ-07, TRD-03, TRD-04, NPC-04, NPC-05, REG-02, REG-03, REG-08 | 12 |
| Sim on the Build 42 candidate specifically (code path changed after `b3c9eb5`) | NPC-01, REG-01 (ND-19 re-path in `World._walk`), SAV-04 (new unsaved hunt-reaction fields) | 3 |
| Sim with the spoilage switch ON (owner: 4 seeds x 365 days), a separate configuration | INV-02 | 1 |
| Multiplayer internal check beyond CI (multi-process host/guest: reconnect, wire privacy, UI path) | MP-05, MP-06, MP-07 | 3 |
| Test or record gap against the owner's wording (section 4) | EMP-06, REG-02, REG-03, REG-08, SAV-04, MP-07 | 6 |
| Record only: "resolved, not reproducible, guarded, tested conditions documented" (owner 2026-11-12 item 5) has no register record | EMP-04, EMP-05, TRD-03, NPC-05, REG-01 | 5 |

## 2. Batching plan for Agent E (shared verification work)

| Group | One unit of work | Covers | Items |
|---|---|---|---|
| **G1** | One full Tests run (all shards) on the exact Build 42 candidate SHA, after the environment check of directive section 2 (fetch authoritative refs first) | "Full CI" for all 21 and the regression re-check of the 43 | all 69 except the 5 open (REG-04, REG-05, MP-02, JOB-02 have no code; B17F-JOBS has none). Test files to watch in the shard output, per item: section 3 |
| **G2** | One four-seed 365-day recorded campaign on the final candidate (Agent I; checkpoints 10/30/90/100/200/300/365), flag off as shipped | "Sim" for 15 items; regression for the 43; B17F-JOBS re-measurement | EMP-04, EMP-05, EMP-06, BIZ-06, BIZ-07, TRD-03, TRD-04, NPC-01, NPC-04, NPC-05, REG-01, REG-02, REG-03, REG-08, SAV-04. Read specifically: `walk_backoff`, `walk_repath` stats (NPC-01, ND-19), `courier_expired` stat and courier heir fields (REG-03, REG-08), JOBS lines / unemployed (EMP-06, B17F-JOBS), noted-key growth if recorded (NPC-05) |
| **G2a** | Interim: accept the completed chain 12 campaigns 43332151718 + 43332156022 (`b3c9eb5`) as the tracker's Sim evidence for the 12 items whose code is unchanged since, once the 118 HIGH findings (7+66+30+15) are triaged by Agent I | Sim column (interim) | the 12 of the Sim row in section 1 |
| **G3** | One four-seed 365-day campaign with `decay.storage.enabled` ON (separate configuration; owner B25-INV02-D2 "full validation") | INV-02 Sim | INV-02 |
| **G4** | One multi-process loopback host + guest session (two Godot processes on localhost; not owner devices) covering join, away, reconnect, sharing tiers, a captured guest wire payload, the sharing menus | "Multiplayer" column | MP-05, MP-06, MP-07 (and regression for MP-01, MP-03, MP-04, INV-03, PROP-01..05) |
| **G5** | Small focused test additions (no game change unless a test shows a defect), each run alone, then carried by G1 | intent gaps | EMP-06, REG-03, REG-08, MP-07, SAV-04 (section 4) |
| **G6** | Records only (lead): register records for the five guarded items, SAV-05/DOC-SAV-01 promotion, stale rows in section 5 | records | EMP-04, EMP-05, TRD-03, NPC-05, REG-01, SAV-05, DOC-SAV-01 |

Order: G5 first (cheap, local, before the candidate SHA is fixed), then G1 and G2/G3 on the same candidate SHA (G2 and G3 can run in
parallel if Actions capacity allows: four seeds x ~41-84 min per seed each), G4 alongside G1. G1 must be on the same SHA as G2.

## 3. The 21 integrated items, item by item

Legend: DONE = evidence exists on a named SHA; OUT = outstanding; n/a = does not apply. "Full CI (b3c9eb5)" means Tests 43321399738.
Every item's focused test is in `.github/workflows/tests.yml` at `0bbee94` (checked by name).

| # | ID | Title | Tracker | Fix commits, ancestor of `0bbee94` | Focused | Regression / Full CI | Sim | Save/load | Multiplayer | Packaged | Intent check (owner wording vs test) | Exact next check |
|---:|---|---|---|---|---|---|---|---|---|---|---|---|
| 4 | MML-EMP-04 | `skilled_place` sums time across stations, picks one | Integrated, awaiting verification | `31496e9` yes (guard only, no code) | DONE `emp04_skilled_place_split_test` (b3c9eb5) | DONE b3c9eb5; OUT candidate (G1) | DONE interim b3c9eb5 campaigns (G2a); OUT candidate (G2) | n/a | n/a | n/a | Owner: "Close with guard tests" (2026-11-12 item 5). Test asserts a hire is offered when summed room suffices and that another station is usable: matches the audit's question | G1; G6 register record with tested conditions |
| 5 | MML-EMP-05 | Unguarded `w.fields[0]` with zero fields | Integrated, awaiting verification | `94b297c` yes (guard only) | DONE `emp05_fields_present_test` | DONE b3c9eb5; OUT candidate | DONE interim; OUT candidate | DONE (test saves and loads) | n/a | n/a | Matches item 5 | G1; G6 |
| 6 | MML-EMP-06 | Unemployed excluded from `_day_labour` | Integrated, awaiting verification | `b0d9cca` yes (+ `a165b89` test) | DONE `emp06_unemployed_day_labour_test` 4/0 | DONE b3c9eb5; OUT candidate | DONE interim (changes outcomes; owner: "full gate"); OUT candidate | n/a | n/a | n/a | Owner: "the unemployed may take open manor day labour **when their household is short of food**, like labourers do". Test asserts they take it on a short-food day, but **no negative case** (not short of food, or work already earned: no day labour). Test header still says "intent check, no game change" (stale) | G5: add the negative case; G1; G2 read unemployment |
| 12 | MML-BIZ-06 | Venture close could erase a till | Integrated, awaiting verification | `a999e1a` yes | DONE `biz06_venture_close_till_test` | DONE b3c9eb5 (tracker cites chain 8 43257628284); OUT candidate | DONE interim; OUT candidate | n/a | n/a | n/a | Matches the audit's recommended forced-refusal + conservation test | G1, G2 |
| 13 | MML-BIZ-07 | Venture hand employed by a player | Integrated, awaiting verification | `b0d9cca` yes | DONE `biz07_hand_employed_by_player_test` 7/0 | DONE b3c9eb5; OUT candidate | DONE interim; OUT candidate | n/a | Player hire path is host-side; guest hire not separately tested | n/a | Owner "Refuse while a hand ... with a reason". Test asserts refusal and the "works at" reason: matches | G1, G2 |
| 17 | MML-TRD-03 | Player claims count chest goods | Integrated, awaiting verification | `ae7f1dd` yes (guard only) | DONE `trd03_player_chest_claims_test` | DONE b3c9eb5; OUT candidate | DONE interim; OUT candidate | n/a | n/a | n/a | Matches item 5 | G1; G6 |
| 18 | MML-TRD-04 | Shipment with no room at either end | Integrated, awaiting verification | `efb0b93` yes | DONE `trd04_stranded_shipment_test` | DONE b3c9eb5; OUT candidate | DONE interim; OUT candidate | DONE (test saves and loads) | n/a | n/a | Test establishes "no room at both ends" unreachable and fixes the reachable variant (seller gone): justified disposition recorded in the test header; matches the audit's request | G1, G2 |
| 21 | MML-INV-02 | Stash, chest, courier stores never spoil | Integrated, awaiting verification | `619813b`, `1a4f489`, `0498dc3` yes | DONE `inv02_spoilage_test` 51 checks (floor) | DONE b3c9eb5; OUT candidate | **OUT**: flag-on 4 x 365 (owner); flag-off covered by G2 | DONE (test: save/load mid-spoilage) | DONE (away guest keeps, active guest spoils, in the test) | n/a | Owner F1(b)-F6(b), F7 deferred, off by default: test checks each and that the shipped switch is off. Register B25-INV02-D2 still NOT STARTED (stale) | G3 flag-on campaign; G1 |
| 29 | MML-SAV-04 | Wildlife/combat transients not saved | Integrated, awaiting verification | `ae69d32` yes | DONE `sav04_reload_determinism_test` | DONE b3c9eb5; OUT candidate | OUT candidate (hunt AI added after b3c9eb5) | DONE b3c9eb5 | n/a | n/a | Owner: "Document the limitation and verify deterministic repeated reloads". **Gap at `0bbee94`:** Build 40's hunt reaction adds 10 unsaved animal fields (`startle_left`, `alarm`, `alarm_left`, `run_dir`, `zig_left`, `zig_side`, `slide`, `pause_left`, `breaking`, `at_bay`; `animal.gd`) that `docs/design/SAVE_WILDLIFE_COMBAT_CONTINUITY.md` does not list, and the test's transient comparison predates them | G5: extend the test's transient list and the document; G1; G2 |
| 30 | MML-SAV-05 | Continuity tests use a different JSON precision | Integrated, awaiting verification | `c1d4b7c`, `0d6a484`, ND-15 `d7217b8` yes | DONE `save_continuity_test`, `save_exact_test`, `plan_continuity_test` | DONE b3c9eb5 | **n/a** (test-only change) | DONE | n/a | n/a | Matches the audit ("align tests with production serialization") | G1 then promote (G6) |
| 31 | MML-DOC-SAV-01 | Comments say NPC plans are not saved | Integrated, awaiting verification | `c1d4b7c` yes (comments only in `game/scripts`) | DONE (as SAV-05) | DONE b3c9eb5 | **n/a** (comments only) | n/a | n/a | n/a | Matches | G1 then promote (G6) |
| 32 | MML-NPC-01 | Failed pathfinding retried without back-off | Integrated, awaiting verification | `5cb29b4`, `baaec84` yes | DONE `npc01_path_backoff_test` | DONE b3c9eb5; OUT candidate | DONE interim b3c9eb5; **OUT candidate**: ND-19 (`cab7d51`, Build 40) adds a re-path inside `World._walk` that can call `_walk_failed` | DONE (count saved, in test) | n/a | n/a | Matches the audit's bounded back-off contract; exemption of bandits, guards and fighters (ND-21) is an agent engineering correction recorded in the defects register | G1; G2 read `walk_backoff` and `walk_repath` per day |
| 35 | MML-NPC-04 | Evening companion away or underground | Integrated, awaiting verification | `d0628a9` yes | DONE `npc04_evening_company_away_test` | DONE b3c9eb5; OUT candidate | DONE interim; OUT candidate | n/a | n/a | n/a | Matches (journey, homestead, underground and a control) | G1, G2 |
| 36 | MML-NPC-05 | `noted` keys never pruned | Integrated, awaiting verification | `51e20b8` yes (measurement only) | DONE `npc05_noted_growth_test` | DONE b3c9eb5; OUT candidate | DONE interim; the bound is extrapolated from a short run, not measured at day 365 | n/a | n/a | n/a | Owner: not a defect, guarded. Test asserts an extrapolated memory bound | G1; G6 record; optional: read the key count at day 365 in G2 if the recorder exposes it |
| 42 | MML-REG-01 | Saved journey drops its `pathed` mark | Integrated, awaiting verification | `e5e6871` yes (guard only) | DONE `reg01_journey_reload_route_test` | DONE b3c9eb5; OUT candidate | DONE interim; OUT candidate (ND-19 re-path adds a `repathed` step key in the same walk code) | DONE | n/a | n/a | Matches item 5 | G1, G2; G6 |
| 43 | MML-REG-02 | Migration does not end a journey or resolve credit | Integrated, awaiting verification | `add5061` (journey), `3bb486d` (debt) yes | DONE `reg02_journey_migration_test`, `reg02_departure_debts_test` 12/0 | DONE b3c9eb5; OUT candidate | DONE interim; OUT candidate | DONE (test) | n/a | n/a | Owner (B25-REG02-DEBT-D1): "If obligations can legitimately continue, preserve them. If the household is ... departing the applicable economic system, settle ... record unpaid balances as defaults", and "Investigate whether the existing estate-sale process correctly applies". The code treats every move to a settlement as leaving the system for the leaver's own debts (repay or default); debts owed to a leaver stay open. That reading is stated only in the commit message of `3bb486d`: **no DECISIONS.md row, no investigation note**, and register B25-REG02-DEBT-D1 still NOT STARTED. Interacts with REG-05 (physical migration) | G6: record the reading (DECISIONS row); G1, G2; re-check when REG-05 lands |
| 44 | MML-REG-03 | Courier proceeds return under an absent sender | Integrated, awaiting verification | `b0d9cca` yes | DONE `reg03_courier_sender_dies_test` 7/0 | DONE b3c9eb5; OUT candidate | DONE interim; OUT candidate | n/a | n/a | n/a | Owner decided the **dead** sender (heir or estate). The item says "absent": a **migrated** sender (`away != ""`) is not redirected and their proceeds stay deposited under them (REG-08 investigation F3), and `CourierService.interrupt` still refunds a special fee with `add_coins(sender, fee)` without checking the sender (F2, `couriers.gd` ~1099 at `0bbee94`; latent: only the player books special deliveries). Neither path is tested. Test header still says "not in the CI suite list" (stale) | G5: a migrated-sender test; decide (lead) whether the migrated case is in REG-03's scope or REG-05's; possible owner question (section 6) |
| 49 | MML-REG-08 | Courier job stranded at a booth | Integrated, awaiting verification | `b0d9cca` yes | DONE `reg08_stranded_route_job_test` 9/0 | DONE b3c9eb5; OUT candidate | DONE interim; OUT candidate | DONE (test saves mid-wait) | n/a | n/a | Owner: "ends; the goods return to the sender (or their estate) and the unearned fee is refunded". Test asserts the job ends and the goods **leave the booth**, not that they **reach the sender**, and never asserts the refund. The code (`_expire`) refunds "as far as they hold the coins" (capped by the carrier's or heir's purse): an agent addition to an unconditional owner rule, recorded only in `couriers.json` `_wait_note` | G5: assert goods in the sender's pack or deposit and `refunded == fee` in the fixture; lead to record the cap as an engineering decision or ask (section 6) |
| 58 | MML-MP-05 | Any player's cart usable by any player | Integrated, awaiting verification | `242ca83`, `448fc0b` yes | DONE `mp05_mutual_asset_share_test`, `mp05_forged_client_test` 53/0 | DONE b3c9eb5 (and 42636628469, 42713486147) | DONE campaign 42664730920 on `242ca83` (0 CRITICAL, 0 confirmed) | DONE | DONE in CI (loopback); **OUT**: reconnect and UI menu walk (`docs/decisions/B25-AUD-MP-05.md` "Not done"); modified-client forging now DONE (`448fc0b`) | n/a | Every engineering column is Y; held only for the two-device check, which directive section 6 says is not required. Known limitation (KI-13): a guest promoted to host keeps only its own pairs' agreements | G4 (reconnect + menus); then promote |
| 59 | MML-MP-06 | Away guest accepted at the gateway | Integrated, awaiting verification | `ab995ff`, `cda94b8`, `fccab06` yes | DONE `mp06_away_reach_test`, `mp06_guest_trust_test` | DONE b3c9eb5; OUT candidate (ND-28 `bd952a8`, Build 40, changed `net_actions.gd` +77) | n/a | n/a | DONE in CI; OUT G4 | n/a | Matches the audit (per-verb away rule, place checks, joining-guest case) | G1, G4 |
| 60 | MML-MP-07 | Snapshots expose other players' private records | Integrated, awaiting verification | `548f0f2`, `228b519`, `e0f6ca6`, `0a96070`, `6643d5a`, `0092913` yes | DONE `mp07_private_records_test`, `net_snapshot` (loopback, via `0092913`), `net_family_test` (public family links on the guest) | DONE b3c9eb5; OUT candidate | n/a | DONE (the guest loads its view) | DONE in CI; OUT G4 | n/a | Owner 2026-11-12 asked to "Test multiplayer visibility for the owner, unrelated guests, **household members**, and other players" and to document which relationship fields stay public. Viewers tested: host, two unrelated guests, a tier-3 sharer. **No household-member viewer case** (a guest married into another player's household). Public fields are documented (manifest INT entry; `public_player` keeps partner and children); register B25-AUD-MP-07 still NOT STARTED (stale) | G5: household-member viewer case; G1, G4 |

## 4. Tests that check something other than what the owner asked (intended-design check)

Checked for the 21 integrated items and the 5 open ones, against the owner's wording in the register and directives
(`2026-11-10_blocked_decisions_wp1.md`, `2026-11-12_extra_life_owner_decisions.md`). For the 43 verified items only ancestry and
CI listing were checked here, not intent.

1. **REG-08**: the test proves the waiting delivery ends and the goods leave the booth; it does not prove the goods reach the
   sender, nor that the fee is refunded (owner: "the unearned fee is refunded"). The refund is capped at what the payer holds, a
   rule the owner did not state.
2. **REG-03**: only the dead-sender case is tested; the item is "absent sender" and the migrated sender and the special-fee refund
   in `interrupt` (F2) are untouched.
3. **EMP-06**: the positive case only; the owner's condition ("when their household is short of food") has no negative test.
4. **MP-07**: the household-member viewer the owner named is not tested.
5. **SAV-04**: the documented list of unsaved transients (the owner's "Document the limitation") is incomplete at `0bbee94` after
   the hunt reaction; the test compares the older list.
6. **REG-02**: a defensible reading of a conditional owner rule, implemented and tested consistently, but the reading is not
   recorded as a decision.
7. Stale test headers (describe pre-decision behaviour; checks are correct): `emp06_unemployed_day_labour_test.gd`,
   `reg03_courier_sender_dies_test.gd`, `reg08_stranded_route_job_test.gd`.

No test was found asserting behaviour contrary to the owner's wording.

## 5. Stale records found (not edited)

Tracker (`B25_69_ITEM_TRACKER.md`):
- 15 rows say "365-day campaign not run" on chain 12; the chain 12 campaigns 43332151718 / 43332156022 on `b3c9eb5` completed
  365/365 on all four seeds with 0 CRITICAL and 0 confirmed defects (HIGH 7 / 66 / 30 / 15 not yet triaged).
- SAV-05 and DOC-SAV-01 carry Sim N where Sim is n/a (no production behaviour change), as TRD-05 was treated.
- MP-05 row: every engineering column Y; status held at "awaiting" for a device check the Build 42 directive no longer requires.
- MP-06 and MP-07 rows cite only `cda94b8` / `0092913`; the code commits are `ab995ff` and `548f0f2` ... `6643d5a`.
- INV-02 row cites `0498dc3` (a floor/doc commit); the implementation is `619813b`, `1a4f489`.
- "Merged" means `wip/b25r2-rev2`; the current line is `0bbee94` (`wip/b42-integration`). Every cited code commit is an ancestor
  of it.

Register (`requirements.json`), statuses behind the code:
- B25-AUD-MP-07: NOT STARTED / NOT TESTED (code integrated at `b3c9eb5`).
- B25-SAV04-D1, B25-INV02-D2, B25-REG02-DEBT-D1: NOT STARTED (all implemented and integrated).
- B25-AUD-REG-08 and SAV-04: UNDER REVIEW with no owner_wording, though the owner decided both (2026-11-12 item 2; 2026-11-10).
- B25-INV02-SPOIL-D1: IMPLEMENTED ON TASK BRANCH (now integrated).
- B25-TRACK-69-02, B25-WP1-01: NOT STARTED (both in effect since 2026-11-10/12).
- No register record named after the item for 45 of the 69 ids (24 have one: `B25-AUD-*`, `SAV-04`, `MP-01`, `JOB-02`, `B17F-JOBS`, `LE-03`; the five guarded items are among the 45), so the owner's "record each as resolved"
  for EMP-04, EMP-05, TRD-03, NPC-05, REG-01 exists only in the tracker and test headers.
- B17F-JOBS title "6-30 adults" while `docs/audits/2026-11-12_B17F_JOBS_MEASUREMENT.md` measured 101 (seed 2) and 69 (seed 4).

Defects register (`B25_NEW_DEFECTS_REGISTER.md`), Merged column behind the line (all ancestors of `b3c9eb5` unless noted):
ND-04, ND-05 (`3d515d6`, `3570832`), ND-06, ND-07 (`d0ddf8f`), ND-08 (`11fdaa9`; Full CI still "running (42859327767)"), ND-09
(`bd17bd8`), ND-10 (`cdfa395`), ND-23, ND-24 (`f09e7c6`): all show Merged N. ND-19 says "open: needs re-pathing ..." but is fixed
by `cab7d51` (Build 40, in `0bbee94`). ND-20 says "in progress" but `fccab06` is merged. ND-28 has no fix recorded, but
`bd952a8` (Build 40) addresses it. ND-27 cites `581d3f8`, which is not an ancestor of `0bbee94` (its cherry-pick `b3c9eb5` is).

Known issues (`docs/KNOWN_ISSUES.md`): KI-15 (EMP-03) OPEN though EMP-03 is completed and verified; KI-16 (REG-08) OPEN "fixes await
owner policy" though decided and implemented (its F2/F3 remainder is the REG-03 gap above); KI-17 (SAV-05 float round trip)
OPEN though ND-15 tolerances were owner-approved; KI-12 OPEN though the fix `dc049d9` is an ancestor of `0bbee94`; KI-13 (MP-05)
lists "modified-client forging" as not done though `448fc0b` did it.

State file: `docs/CURRENT_DEVELOPMENT_STATE.md` line 42 still lists the chain 12 campaigns as "running".

## 6. Questions that may need the owner (lead to judge; not asked here)

1. **REG-03, migrated sender.** Proceeds coming home for a sender who has migrated stay deposited at a booth they cannot reach.
   Options: (a) treat as REG-05 scope (a physically travelling migrant could collect, or the courier follows); (b) send them on to
   the migrant's settlement as a regional credit; (c) leave deposited (current). Recommendation: (a), recorded now, tested with REG-05.
2. **REG-08, capped refund.** The owner said the unearned fee is refunded; the code refunds only what the carrier (or heir) still
   holds, to avoid creating coins. Recommendation: keep the cap as an engineering correction (conservation outranks a refund the
   payer cannot fund), record it in DECISIONS, and report the shortfall in the job history (already done in the `history` line).

## 7. The 43 completed and verified items

All cited fix commits are ancestors of `0bbee94`; every focused test named below is in the CI list at `0bbee94`. Their Full CI and
campaign evidence is on earlier SHAs (`72729e5`, `c9da5db`, `e44d6b8`, `f0a854c`, `b2cd024`, `229f76e`, `53a56d3`, `93bb304`,
`96b071c`); the Tests run and campaigns on `b3c9eb5` include all of them (green, 0 CRITICAL, 0 confirmed). What the Build 42
standard still asks is the regression evidence on the candidate SHA: G1 and G2. No item is demoted.

| # | ID | Title | Tracker | Cited commits ancestors of `0bbee94` | Focused test(s) in CI list at `0bbee94` | Next check |
|---:|---|---|---|---|---|---|
| 1 | MML-EMP-01 | Succession may retrain a permanently employed NPC, leaving the employment record | Completed and verified | yes (72729e5 7438665) | emp01_apprentice_employed | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 2 | MML-EMP-02 | Mid-day save/load resets `earned_at_dawn` / `laboured_today` | Completed and verified | yes (c9da5db f67afdb) | sav02_day_state | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 3 | MML-EMP-03 | Hiring competition counts the wrong seekers | Completed and verified | yes (00e47a6 72729e5) | emp03_seeker_count | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 7 | MML-BIZ-01 | Founding ends employment before the business opens | Completed and verified | yes (72729e5 82da3c6) | biz01_found_atomic | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 8 | MML-BIZ-02 | Expansion pays for premises before the purchase is confirmed | Completed and verified | yes (72729e5 82da3c6) | biz01_found_atomic | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 9 | MML-BIZ-03 | Owner withdrawals before payroll; hiring budgets one wage (owner decision: option B) | Completed and verified | yes (93327ae c9da5db) | biz03_payroll_priority | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 10 | MML-BIZ-04 | Venture tills escheat on migration (owner decision: household keeps them) | Completed and verified | yes (3e9b9a1 c9da5db) | biz04_venture_till_migration | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 11 | MML-BIZ-05 | Venture hand also hired as employee | Completed and verified | yes (2c05696 72729e5) | biz05_hand_not_hired | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 14 | MML-BIZ-08 | Hand ids as floats after load | Completed and verified | yes (4761957 e44d6b8) | biz08_venture_hands_load | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 15 | MML-TRD-01 | Guest stall settlement assigns a PlayerState to NPC | Completed and verified | yes (1fa94b5 e44d6b8) | trd01_guest_stall_settle | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 16 | MML-TRD-02 | Merchant earnings gross, not net of commission (owner: net) | Completed and verified | yes (36fa011 c9da5db) | trd02_merchant_net_earnings | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 19 | MML-TRD-05 | Comments say the Living Economy is off | Completed and verified | yes (85ad919 93bb304) | (comments only) | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 20 | MML-INV-01 | Player stash missing from the goods census | Completed and verified | yes (35f241c e44d6b8) | inv01_stash_census | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 22 | MML-INV-03 | Any player gets "own" access to another player's stash | Completed and verified | yes (f0a854c) | inv03_foreign_player_chests | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 23 | MML-INV-04 | Stash goods unreachable after a lease/ownership change (owner decision) | Completed and verified | yes (969a8f4 c9da5db) | inv04_stash_handover | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 24 | MML-INV-05 | Rubble returned as dressed stone (owner: no conversion) | Completed and verified | yes (c9da5db e42a37f) | inv05_rubble_refund | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 25 | MML-INV-06 | Worn tools restored in barter/credit/restitution | Completed and verified | yes (72729e5 916db07) | wear_transfer | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 26 | MML-SAV-01 | `food_days` not saved; famine lapses after reload | Completed and verified | yes (f0a854c) | sav01_famine_reload | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 27 | MML-SAV-02 | Hour caches and market snapshot not saved (owner: preserve) | Completed and verified | yes (c9da5db f67afdb) | sav02_day_state | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 28 | MML-SAV-03 | Reservation maps cleared on load (counters, farm, business, chapel, fauna) | Completed and verified | yes (89a3b06 b2cd024 bf6a1de e44d6b8 fbfd6ad) | sav03_counter_reload, sav03_reservations_reload | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 33 | MML-NPC-02 | Courtship gifts ignore contract holds | Completed and verified | yes (72729e5 aca3a8b) | npc02_gift_claims | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 34 | MML-NPC-03 | Manor-hand -> farmer bypasses job-change bookkeeping | Completed and verified | yes (0bfbb9e b2cd024 fbfd6ad) | npc03_field_takeover_bookkeeping | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 37 | MML-LIFE-01 | Retiring employee keeps wages | Completed and verified | yes (f0a854c) | life01_retirement_payroll | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 38 | MML-LIFE-02 | Dead employee's owed goods inherited | Completed and verified | yes (4266761 72729e5) | life02_employee_death | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 39 | MML-LIFE-03 | No sage succession (owner: qualified successor) | Completed and verified | yes (229f76e) | life03_sage_succession | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 40 | MML-LIFE-04 | Widowed NPCs cannot remarry (owner: may remarry) | Completed and verified | yes (229f76e) | life04_remarriage | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 41 | MML-LIFE-05 | Bandit child inherits first (owner: last) | Completed and verified | yes (c9da5db cbd91f6) | life05_bandit_heir | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 47 | MML-REG-06 | Off-map household changes leave the live resident stale | Completed and verified | yes (b2cd024 fbfd6ad fd55cdd) | reg06_household_change_live | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 48 | MML-REG-07 | Intel freshness too long for 8-day years (owner: one year) | Completed and verified | yes (53a56d3) | intel | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 50 | MML-JUS-01 | Dead guard stays a pursuer | Completed and verified | yes (f0a854c) | jus01_dead_guard_pursuit | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 51 | MML-JUS-02 | Joining the bandits skips shared termination | Completed and verified | yes (1497a5c 72729e5) | jus02_join_band_cleanup | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 52 | MML-JUS-03 | Player's heir inherits the criminal case | Completed and verified | yes (f0a854c) | jus03_old_age_justice | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 53 | MML-JUS-04 | Witness penalties spread too far (owner: only once the crime reached them) | Completed and verified | yes (53a56d3) | jus04_witness_knowledge | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 54 | MML-MP-01 | Guest-owned shops never get NPC customers | Completed and verified | yes (f0a854c) | mp01_guest_stall_attendance | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 56 | MML-MP-03 | Verb decoding accepts arbitrary inventories | Completed and verified | yes (93bb304 9fd18a5) | mp03_forged_store, mp03_household_tables, mp03_public_tables | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 57 | MML-MP-04 | `carts.place` creates carts for free | Completed and verified | yes (f0a854c) | mp04_cart_gateway | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 61 | MML-PROP-01 | `cancel_site` without ownership check | Completed and verified | yes (f0a854c) | prop01_cancel_site | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 62 | MML-PROP-02 | `Fitting.remove` without holding the building | Completed and verified | yes (f0a854c) | prop02_fitting_owner | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 63 | MML-PROP-03 | Lease end leaves the tenant's site on the parcel | Completed and verified | yes (b727954 c9da5db) | prop03_eviction_site | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 64 | MML-PROP-04 | Helper finishing a guest's site runs as the host | Completed and verified | yes (f0a854c) | prop04_guest_house_name | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 65 | MML-PROP-05 | `business.sell` allowed as a guest verb | Completed and verified | yes (f0a854c) | prop05_guest_sale | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 66 | MML-PROP-06 | Migrating household loses property (owner: atomic estate sale) | Completed and verified | yes (96b071c) | prop06_estate_transaction, prop06_migration_property | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |
| 69 | MML-REQ-LE-03 | Living Economy stage LE-03 | Completed and verified | yes (register LE-03: INTEGRATED, INTEGRATION VERIFIED) | le03_claims, le03_economy, le03_transactions | Regression only: Group 1 (Full CI on the Build 42 candidate) and Group 2 (four-seed campaign on it) |

## 8. The five not started or blocked

| # | ID | Title | Tracker | Code on `0bbee94` | Owner wording (register) | Verification categories when built | Exact next step |
|---:|---|---|---|---|---|---|---|
| 45 | MML-REG-04 | Couriers advance abstractly | Not started | none | B25-AUD-REG-04: "Couriers physically travel." (OWNER APPROVED) | focused, Full CI, Sim (changes outcomes), save/load (in-transit courier), multiplayer n/a | Agent F; design inputs in `docs/audits/2026-11-12_PREREQUISITES_REG04_REG05_MP02_JOB02.md` s.1; REG-08 F4 (migrating courier) folds in |
| 46 | MML-REG-05 | Migration is instant | Not started | none | B25-AUD-REG-05: "Migrating households physically travel." | focused, Full CI, Sim, save/load (household on the road), REG-02/REG-03/PROP-06/BIZ-04 regressions | Agent F; prerequisites s.2; re-check REG-02 debt rule and REG-03 migrated sender with it |
| 55 | MML-MP-02 | Guest stall/shop management has no mirror paths | Not started | none | no dedicated register record (prerequisites s.3 lists the source) | focused, Full CI, multiplayer (G4-style), save/load; Sim n/a | Agent G; prerequisites s.3 |
| 67 | MML-REQ-JOB-02 | Offered compensation on the job board | Not started | none | JOB-02: "Replace the long-term fixed-wage design with offered compensation that workers can accept or reject." Constrained by X18-D6 (wage fixed at acceptance) | focused, Full CI, Sim (employment outcomes), save/load | Agent H; prerequisites s.4 and s.6 owner questions |
| 68 | MML-REQ-B17F-JOBS | Unemployment 6-30 adults at day 365 | Blocked | n/a | B17F-JOBS (PROPOSED, UNDER REVIEW); measurement `48d8aee` on `fbfd6ad` (before EMP-06 day labour and chain 8-12) | Sim measurement only | Agent H: re-measure from G2 (or from the chain 12 campaign JOBS lines on `b3c9eb5`) before any owner question; the measured cause (supply outgrows posts) also depends on JOB-02 and REG-05 |

## 9. Method notes and limits

- Clone: `/dev/shm/agentD`, fetched every remote head fresh from GitHub (`+refs/heads/*:refs/remotes/origin/*`) before any
  ancestry check, per the brief's stale-branch warning.
- Nothing was run in Godot; no test result here is new. Every DONE cell cites an existing run on a named SHA.
- Campaign figures come from the two `flight / report` job logs; the HIGH findings themselves were not read (Agent I).
- The intent check read each test's header and `check(...)` lines and, where needed, the code at `0bbee94`
  (`couriers.gd` `_expire`, `_home`, `interrupt`; `animal.gd`; `world.gd` `_walk`).
