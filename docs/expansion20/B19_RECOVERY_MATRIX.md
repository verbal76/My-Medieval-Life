# Build 19 recovery matrix (B19-RECOVERY)

> **Status (DOC-RECON-01, 2026-10-31): CURRENT-STATUS-ELSEWHERE.** This document is the 2026-10-26 audit. Since then R1-R5 have been integrated, R6 and R7 done in substance (SJD-G, LE-02 and C1/C5), and R8 presented (SJD-H C1-C6). It is not a current instruction. Current status:
> `docs/expansions/EXPANSION_20.md` (section 3). Precedence: `docs/expansions/README.md`. Content below kept unchanged.

Owner directive `docs/directives/2026-10-26_build19_carryover_audit_x20_integration.md` (sections 1-4 and 9). Read-only audit,
2026-10-26, of the code on `origin/wip/expansion20` **0b5287c** (detached worktree), compared with `wip/build19` 42c33e0
(game code 2f72ec3), `wip/expansion19-preparation` b7f832e, `wip/expansion20-preparation` 1befd0e, `wip/build22` b7e1c91
and `staging/my-medieval-life` 8529ca1. The register read is the staging copy. Every status below comes from the code and
from tests run on 0b5287c, not from the register. Nothing was committed and no register entry was changed.

Notation: `file:line` is on `wip/expansion20` 0b5287c unless another ref is named. "x20" means `wip/expansion20`.

---

## (a) The true baseline

### Branch ancestry (`git rev-list --count A..B`)

| Branch | Head | Commits it has that x20 lacks |
|---|---|---|
| `wip/build19` | 42c33e0 (release packet; game code 2f72ec3) | **0** |
| `wip/expansion19-preparation` | b7f832e | **0** (also 0 against `wip/build19`) |
| `wip/expansion20-preparation` | 1befd0e | **0** |
| `wip/build22` | b7e1c91 | **0** |
| `wip/expansion20` | 0b5287c | (the reference) |

So **x20 contains everything**: every Expansion 19 commit, the recorder line (`wip/recorder` 2d5d49c via b2f7dc2), Build 19
(2f72ec3), the Build 20/21/22 line (`wip/multiplayer-b19` through `wip/build22` b7e1c91) and the Living Economy foundation
(X20-B1 merge 0b5287c). No older preparation branch holds code newer than x20, so **there is nothing to port from a
preparation branch**, and there is no risk of overwriting a newer implementation with an older one.

### Newest implementation of each system

| System | Newest code | Where it was last changed | State on x20 |
|---|---|---|---|
| Judgment store, gossip, trust, lies, family stories (`game/scripts/core/judgment/*.gd`, 4,659 lines) | x20 (= Build 19 + Build 20-22 additions: GP-DIALOGUE A5 news facts, MP Batch C player ids) | b7f832e, 3022fbf, 7559ab0 (X19); A5/A6/A8 repairs and MP Batch C on the Build 20-22 line | **ON**: `game/data/judgment.json:4` `"enabled": true`; attached at `game/scripts/core/world.gd:178-179` |
| Decision weighting (`JudgmentWeighting.choose`) and 13 live decision hooks | x20 | 577821d (hooks), 3022fbf (stubbornness, family colour) | **ON**: `judgment.json:117` `decision.integration` all 13 domains `true` |
| Personality, bonds, family reputation (`judgment_personality.gd`, `judgment_bonds.gd`) | x20 | a3aa237, c756211, 3022fbf | ON (part of the store) |
| Family-first (`judgment_family.gd`) | x20 | fff48a4, 3022fbf | ON (`integration.family_first` true) |
| Flight recorder (`game/scripts/core/recorder/*`, `game/scripts/recorder_export/*`, 2,757 lines) | x20 | f32f7d1 (Build 21 audit), 612e4a1, 133ee54 (XLSX), 2dc8cc0 | **OFF** in every build: `game/data/recorder.json:4` `"enabled": false` (owner X19-SCOPE: off in public builds) |
| Crime and justice (`game/scripts/core/justice.gd`) | x20 | GP-CRIME-PURSUIT (f846ccc, 5984def, b3ff749, f2cc09c) | ON |
| Living Economy foundation (`game/scripts/core/economy/*.gd`, 553 lines) | x20 only (0b5287c) | 0b5287c | **OFF**: `game/data/economy.json:4` `"enabled": false`; `world.gd:284` attaches nothing while off |

### How Build 22 and the Expansion 20 foundation reconcile

`git diff origin/wip/build22 origin/wip/expansion20` touches only 18 files: the economy scripts and their test, three
`docs/expansion20/LE0*` notes, `economy.json`, `tests.yml` (one line), `contracts.gd` (9 lines) and `world.gd` (15 lines:
the `economy` / `economy_foreign` fields, attach at setup and load, `_economy_section()` in `to_dict`). Both sides are kept;
the foundation adds no reputation, trust, opinion or decision logic of its own (no such identifiers in the economy files),
so **there is no competing judgment or reputation engine** (directive sections 5 and 7). The registered evidence for X20-B1
(FIX-D1D2 tests field: economy_foundation_test 89/0, run_tests 3600/0, start_test 523/0, G0 identical to the Build 22
baseline with the foundation disabled) stands; `economy_foundation_test` re-run here: **89 checks, 0 failures**.

Two integration notes for the lead (no behaviour impact today):
- `world.gd:5993-5996`: the merge put `_economy_section()` between `_unstick()`'s doc comment ("## Anyone saved standing
  where the map now has furniture...") and `func _unstick`, so that comment now documents the wrong function. Cosmetic;
  move the comment back when `world.gd` is next touched.
- `contracts.gd:995-1001`: a lapsed contract both publishes a `trade_cheat` judgment fact and lowers Relations regard.
  `docs/expansion20/LE00_ARCHITECTURE_AUDIT.md:266-268` already flags this as one breach on two channels (after X19-REGARD,
  regard is liking and trust lives in the judgment store, so it is two different values, but the LE design must settle the
  one channel before LE defaults go live; OD-LE-05/OD-LE-13 are APPROVED and should be read for it in batch 5).

---

## (b) The Build 19 contradiction (directive section 4)

**Finding: explanations 1, 3 and 4 hold for Gates E and F; explanation 5 holds, narrowly, for Gate G; Gate H is an owner
gate by definition. Explanation 2 (code not integrated) does not hold for any judgment stage.**

Evidence:

1. **Done under other ids (explanation 1).** The judgment rollout was carried out under PROS-19 and X19-SCOPE, not under
   SJD-E/F:
   - live adapter, switched off: 221ac6f (named in `docs/expansion19/PROGRESS.md:44` on x20);
   - event feeds from live acts: e8d4122 (PROS-19 history, 2026-10-23);
   - the Q14 decision hooks: 577821d ("wire contract acceptance, seller order, credit, barter, food seller and family help
     through the judgment weighting");
   - "Expansion 19 complete: ... judgment on by default": 3022fbf, 7559ab0, b7f832e (X19-SCOPE, register COMPLETE,
     INTEGRATION VERIFIED, test_commit 2f72ec3).
   The code on x20 confirms it: `judgment.json:4` `enabled: true`; `judgment.json:117` 13 domains on; `JudgmentLive.on()`
   (`judgment_live.gd:41-44`) gates each hook; hooks at `npc_brain.gd:1903` (trade_sell), `npc_brain.gd:2149`
   (trade_buy_from), `construction.gd:1293` (hire_choice), `construction.gd:303` and `business.gd:1002` (work_accept),
   `relations.gd:629` (befriend), `relations.gd:710` (court_choice), `contracts.gd:524-525` (contract_accept),
   `contracts.gd:1168-1169` and `prospecting.gd:595-596` (contract_seller), `credit.gd:333` (credit_lend), `credit.gd:267`
   (barter_accept), `credit.gd:499` / `farm_plots.gd:255` (food_seller), `construction.gd:1354-1356` (family_help),
   `npc_brain.gd:239,898,968,994,1167` (family_first). The judgment changes behaviour, not only scores:
   `judgment_test.gd:329 test_decision_iron`, `:351 test_need_vs_opinion`, `judgment_live_test.gd:132 test_trade_choice`
   and `:312-576` (one test per Q14 domain) assert different choices with judgment on.
2. **Superseded (explanation 3).** Gate E's "feature flag OFF by default" and PROS-19's acceptance ("isolated scenarios
   ... the live NPC decision system is not replaced") were overridden by the owner's X19-SCOPE directive
   (`docs/directives/2026-10-23_x19_complete_release_scope.md`: "Do NOT release Build 19 with personality or
   family-reputation layers disabled. Both must be enabled, integrated, and actively influencing NPC decisions"). The
   off-path survives only as the test switch `JudgmentLive.test_disabled` (`judgment_live.gd:47-55`), used by
   `judgment_live_test.gd:73 test_off_by_default` and `tools/sim_gate.py --no-judgment` (7559ab0) for matched-seed
   comparison with Build 18.
3. **Register not updated (explanation 4).** SJD-E's `remaining_work` (staging register) still lists the rework for the
   2026-10-23 answers and "synchronize with the finished Build 18 (the branch is on Build 17 cd7439c)". Every item is in
   x20's history: SYNC-18 c2ece16; X19-Q-TIMING af819a6/3f89816 (`judgment.json` gossip `"timing": "scheduled"`); SJD-Q05
   and X19-ASSAULT 2456294 (`judgment.json` `assault` `permanent: true`); X19-REGARD 46b46e5 (`judgment_store.gd:1684
   trust_of`); X19-GUARD 949b5b9 (`world.gd:3996-4000`); X19-HARMED and X19-CRT12 were "keep" answers (no change). SJD-F
   still reads NOT STARTED although 13 domains are live. X19-MISINFO and X19-STORY-LIFE read NOT STARTED although 3022fbf
   implements both (`judgment_store.gd:1467-1580`, `:1584-1630`). PROS-19 and X19-FOUND `next_action` still ask the owner
   for X19-DECAY, X19-PERS-FORMULA, X19-SPILL-REACH etc., all answered on 2026-10-23
   (`docs/directives/2026-10-23_owner_answers_x19_release_decisions.md`; numbers in `judgment.json` `decay`, `traits`,
   `bonds`). SIM-F4 is still OPEN although Build 19 ships the owner's SIM-F4 rules (417c07f, a7c84e9; release packet).
4. **Released with material scope unfinished (explanation 5), limited to validation and diagnostics.** The Build 19
   packet (`docs/release/BUILD_19_PACKET.md` on `wip/build19`) shows 30-day runs on seeds 1-4, determinism and
   conservation, but no 100- or 365-day judgment-on versus judgment-off comparison, no ablations (spec section 16: off,
   trade-only, social-only, full), no device performance measurement: Gate G was not met. The recorder, which X19-SCOPE
   kept for private testing, does not instrument judgment at all (`game/data/recorder_coverage.json:170` "Judgment
   (Expansion 19) ... Not instrumented, stage D5"; `:132` Relationships and `:139` Contracts and credit "Not instrumented,
   D4"; the workbook says so at `game/scripts/recorder_export/workbook_builder.gd:292`), so FAM-SAC-01's criterion
   "family-priority factors visible in the recorder" is not met either (`JudgmentStore.family_trace`,
   `judgment_store.gd:122`, is a 64-row ring filled by `judgment_family.gd:107-116` and read by nothing outside tests).
   The owner accepted Build 19 "as the development baseline" (builds map, 2026-10-24) and the 2026-10-24 reconciliation
   recorded these as "Build 19 carry-forward: unfinished, not part of the accepted Build 19 work", so this is disclosed,
   not hidden; but the release-notes phrase "Expansion 19 complete" is true of the gameplay layers, not of Gate G or the
   recorder's judgment coverage.
5. **Not integrated (explanation 2): no.** No judgment, personality, family or recorder code exists on any branch that is
   missing from x20 (ancestry table above).

Per stage: **E** = 1 + 3 + 4 (complete). **F** = 1 + 4 for trade, aid, friendship, courtship, employment; crime only
partly (guard fines, `world.gd:3996-4013`; witnesses' reporting is not weighted); politics absent because no political
system exists (Expansion 21; Q-POL-1, Q-POL-7 OPEN). **G** = 5 (not done). **H** = owner gate; broad enablement was
ordered by the owner in X19-SCOPE, public release is not authorized.

---

## (c) The matrix

Tests run on x20 0b5287c (headless, `XDG_DATA_HOME` isolated), 2026-10-26: `judgment_test` 217/0, `judgment_live_test`
144/0, `judgment_personality_test` 91/0, `judgment_bonds_test` 98/0, `judgment_x19_test` 101/0, `family_first_test` 104/0,
`judgment_guard_save_test` 20/0, `judgment_decay_demo` 29/0, `relations_test` 80/0, `family_test` 51/0, `recf1_test` 28/0,
`recorder_test` 169/0 (the two "Decompression failed" lines are its truncated-chunk negative cases), `identity_test` 98/0,
`migration_test` 93/0, `save_transfer_test` 21/0, `economy_foundation_test` 89/0, `conservation_test` 8/0,
`outlaw_return_test` 24/0, `justice_test` 33/0, `manhunt_test` 60/0, `pursuit_test` 35/0, `judgment_perf` 23/0. All
exited 0: 22 suites, 1,616 checks, 0 failures. No long simulation was started (directive section 11, MSW-01); the
registered sim_gate and G0 evidence for 0b5287c is reused.

Classification key: NI not implemented; PI partially implemented; INI implemented, not integrated; IND integrated but
disabled; IU implemented but unverified; C completed.

### Eighteen carryovers

| ID | Original scope | Current implementation | Source location | Integration (x20) | Actual functionality | Validation | Remaining work | Dependencies | Class / Disposition |
|---|---|---|---|---|---|---|---|---|---|
| **SJD-E** | Spec Gate E: first gated integration, one low-risk domain, flag off by default, matched-seed tests | Done under PROS-19/X19-SCOPE: live adapter `JudgmentLive`, flag, matched-seed off-path | 221ac6f, e8d4122, 577821d, 3022fbf; `judgment_live.gd:41-55`, `world.gd:178-179`, `tools/sim_gate.py` (`--no-judgment`, 7559ab0) | Yes | Working; default ON by owner order (X19-SCOPE supersedes "off by default") | judgment_live 144/0 (`test_off_by_default` :73, `test_running_world` :229); Build 19 sim_gate identical with judgment off (X19-SCOPE history) | Register only: close with this evidence; drop the stale remaining_work (all items in c2ece16, af819a6, 2456294, 46b46e5, 949b5b9) | SJD-D | C / **complete** |
| **SJD-F** | Gate F: rollout across trade, aid, friendship, courtship, employment, crime, politics "as existing systems permit" | 13 decision domains wired through `JudgmentWeighting.choose`, all ON | 577821d, 3022fbf; hooks listed in (b)1; `judgment.json:117` | Yes | Trade, aid, friendship, courtship, employment: working and enabled. Crime: only the friendly-guard fine (`world.gd:3996-4013`). Politics: no political system to integrate (Expansion 21) | judgment_live 144/0 (one test per domain, :312-:576); judgment_test `test_need_vs_opinion` :351 (opinion is one weighed factor: it can make a villager do without, never through a fixed cutoff) | Population-level evidence that each domain changes choices (decision counts on vs off, read from the SJD-G runs and recorder D5); decide whether witnesses' reporting and NPC crime choices are in Gate F scope (agent: yes, a small `report` hook at `npc_brain.gd:237` through the same `choose`); politics deferred to Expansion 21 under Q-POL-7 | REC-19 D5 for measurement; Expansion 21 for politics | IU / **verify** (politics part blocked by Q-POL-1/Q-POL-7, Expansion 21) |
| **SJD-G** | Gate G: 100/365-day comparison, failure analysis, performance and save migration | Partial: 30-day runs seeds 1-4, determinism, synthetic perf harness, save migration tests | `game/tests/judgment_perf.gd`; `migration_test`, `judgment_x19_test.gd:469 test_save_and_upgrade`; Build 19 packet | Yes (tools) | Save migration verified; long-run calibration absent | migration 93/0, save_transfer 21/0, judgment_x19 101/0; Build 19 packet: 30 days x 4 seeds, no leaks | One 365-day run per seed (1-4), judgment on, with `--every` checkpoints (day 100 read from them, SIM-01) plus the judgment-off control per seed; spec section 16 ablations (trade-only, social-only) as separate configurations; failure analysis with recorder D5; device performance on a phone (owner device) | Batches 1-4 first (directive section 11: not against unfinished code) | PI / **implement** (validation) |
| **SJD-H** | Gate H: owner review; release and broad enablement approved separately | Enablement already ordered by the owner (X19-SCOPE); private draft authorized 2026-10-24 | owner directives 2026-10-23 X19-SCOPE, 2026-10-24 release authorization | n/a | Owner gate | n/a | Present the SJD-G report to the owner | SJD-G | NI (owner gate) / **genuinely blocked** (owner review, after SJD-G) |
| **PROS-19** | Prospective X19: memory, subjective judgment, signed opinions, decision weighting, provenance, sharing, persistence, determinism and performance tests | All of it, now live (acceptance "isolated, provisional adapters" superseded by X19-SCOPE) | commits in its record (e05d367 ... c756211) + 3022fbf, 7559ab0, b7f832e | Yes | Working, enabled | judgment 217/0, judgment_live 144/0, decay_demo 29/0 | None of its own: its next_action (owner numbers) was answered 2026-10-23; its last item (matched-seed 365-day calibration, device perf) is SJD-G; wiki (7559ab0 'What villagers think of you') and INT-405..411 done | SJD-G | C (umbrella) / **complete** (closes with SJD-G's evidence; no separate implementation) |
| **X19-FOUND** | Foundations round: personality, relationship history, family reputation (judgment off at the time) | Children PERS, BONDS, FAMREP implemented and now live; owner numbers set | c756211, a3aa237, 3022fbf; `judgment_personality.gd`, `judgment_bonds.gd`, `judgment.json` `traits`, `bonds` | Yes | Working, enabled | personality 91/0, bonds 98/0, relations 80/0 | Register: next_action decisions (X19-PERS-FORMULA, X19-TRAIT-DIST, X19-SPILL-REACH, X19-REP-TRANSMIT, X19-BOND-LIMITS, costly mistake, reminder, stubbornness effect) answered in `X19_RELEASE_DECISIONS.md` B/C and the 2026-10-23 answers; close when the three children close | children | IU (umbrella) / **verify** |
| **DVW-B1** | Villager relationships; memory of favours, gifts and harms that greetings, prices and help read; gossip | Satisfied by the judgment store: provenance memories, GOOD/BAD ledgers, gossip at meetings, trust; greetings read it through `EventTalk` (`event_talk.gd:1-20`); help reads it (family_help, credit_lend, barter) | X19 commits; `relations.gd:207` (gifts), `construction.gd:1364`, `quests.gd:405` (help), `JudgmentStore.tell` `judgment_store.gd:1346` | Yes | Working, enabled, except **prices**: `trade_sell` weight `price: 0` (`judgment.json` decision.profiles), no price is adjusted by opinion | judgment 217/0, judgment_live 144/0, relations 80/0 | Close greetings, help, gossip with this evidence. Prices reading opinion is an economic policy: route to LE-02 (bids and asks use the shared `JudgmentWeighting`, never a second store) and its open decision OD-LE-10/OD-LE-14 | LE-02 for prices | IU / **verify** (price part waits for LE-02) |
| **DVW-B2** | Assault and killing recorded and fined, above theft; decide what passes to an heir (unpaid fines, a fading stain) | Done under **GP-CRIME-PURSUIT** (Build 21): assault, guard_assault, killing in the case file with tiers above theft; yield and be fined; heir: owner answer "Case ends; stain stays", stain carried by family reputation | `justice.gd:1-35, 343-346`; `world.gd:4035` (fine settles), `world.gd:1194 player_yield`; `balance.json` `justice`; `judgment_bonds.gd` (stain); owner answers `docs/directives/2026-10-24_owner_answers_crime_repair.md:10-14` | Yes | Working for the player. NPC-on-NPC assault is judged (judgment events) but not fined (the source row is about the player) | justice 33/0, manhunt 60/0, pursuit 35/0, outlaw_return 24/0 | Register: link to GP-CRIME-PURSUIT evidence and the owner's heir answer; nothing to build | none | IU / **verify** (equivalent implementation) |
| **GM-01** | Generational memory: historical event records with causal links (gift -> materials -> house -> descendants), family identity across generations, dialogue generated from records, reflecting later fate of the building | Partial: facts with provenance (participant/witnessed/told/rumour), permanent memories, family stories passed at coming of age, dialogue reads what the speaker knows (`EventTalk`) | `judgment_store.gd:11, 1584-1630`; `judgment_live.gd:272-310`; `event_talk.gd` | Partly | The 30-planks chain is **absent**: `on_help(.., "help_build", give)` (`construction.gd:1364`, `judgment_live.gd:190-192`) records coins, no building or item reference; no causal link field; `family_story.good_severity` 2000 > `help_build` 1000, so such a gift is never handed down; ordinary facts retire after `memory.horizon_days` 30; no "descendant of the helper" recognition line | judgment_x19 `test_family_stories` :255 (permanent deeds only) | (1) a historical-record layer over judgment facts: building/item/household ids and `links` (caused, enabled, contributed) on the facts, kept permanent above a significance threshold, saved; (2) construction records which gift's materials or coins went into which building; (3) retelling of significant help as a family story (a significance rule, not raising severity); (4) `EventTalk` line built from the record + lineage + building's present state; (5) save migration and a three-generation test. Reuse the judgment store (no second ledger) | DVW-B1, X19-STORY-LIFE (done), Life lineage, construction | PI / **implement** |
| **X19-MISINFO** | NPCs may fabricate false accusations; credibility; investigation; proven-false corrects the judgment it caused; consequences by intent, harm, repetition, relationships | Implemented as the owner approved it (packet D): liars with motive (resentment or rivalry), 5% of meetings, one a year; credibility from trust; a guard or kin of the accused shows it false; only those who learn it correct; liar loses 15 trust with each | 3022fbf; `judgment_store.gd:1467-1580` (`is_lie`, `lie_motive`, `_maybe_lie`, `_invent`, `_contradicts`, `_refute`), `:1399-1402` in `tell`; `judgment.json:88` | Yes | Working, enabled | judgment_x19 `test_lies` :150, `test_lie_frequency` :236 (101/0) | Register: close against packet D. Two loose ends for the lead: the catalog's `false_accusation` event (`judgment.json`) is never published (dead entry: remove or publish it from `_refute`); "repetition" scales nothing (each lie costs the same 15 trust). Neither needs an owner decision unless the owner wants repeated lying to cost more | none | IU / **verify** |
| **X19-STORY-LIFE** | Family stories across generations; observers judge relatives by their own knowledge; reputation recovers through conduct; important stories survive, minor fade | Implemented: parents pass permanent and serious-good memories at coming of age and at home; family colour from the observer's own memories of relatives, capped, never alone a refusal; each personal dealing replaces a tenth | 3022fbf, 7559ab0; `judgment_store.gd:1584-1630`, `:1106-1125` (`colour`); `judgment_live.gd:272-310`; `world.gd:470`, `life.gd:253` | Yes | Working, enabled | judgment_x19 `test_family_stories` :255, `test_reach` :321, `test_colour_and_limits` :349; bonds 98/0 | Register only | none | IU / **verify** |
| **REC-19** | Full flight recorder: every interaction, decision, state change and cause; invariants; coverage audit; archive; Excel on three platforms | D1 core, D2/D3 points, hourly snapshots, XLSX workbook, live export; off by default | 30dccb6, ba1ce0a, 0fb93f9, 2dc8cc0, 133ee54, 612e4a1, f32f7d1; `game/scripts/core/recorder/*`, `game/scripts/recorder_export/*` | Yes | Integrated, **disabled** (`recorder.json:4`); coverage **incomplete**: Relationships, Contracts and credit, Business/stalls/property/construction, Farming/mining/chapel/quests (D4) and Judgment (D5) "Not instrumented" (`recorder_coverage.json:132,139,170`) | recorder 169/0 | D4 (relations, contracts/credit, business, construction, farming) and D5 (judgment facts, beliefs, gossip tellings, ledger posts, trust moves, every `JudgmentWeighting.choose` with its trace, `family_trace`); keep it out of the RNG and off in public builds; Android/Windows Excel export is an owner-device check | none (all code exists to hook) | PI / **implement** |
| **REC-DIAG** | Use the recorder for analysis: progressive runs, findings with evidence, defects vs emergent, gaps reported | Runs 1-4 and the seeds 3-4 gate analysed with findings F1-F9 | `docs/design/SIM_FINDINGS.md` (staging; 8e19329, 61e5823, 304814e) | n/a (process) | Active practice; judgment cannot be analysed (D5 missing) | SIM_FINDINGS runs 1-4 | After REC-19 D5: a short (10-30 day) recorded run on x20 with judgment on, analysed per SIM_FINDINGS format; open findings SIM-F2, SIM-F3 wait for the owner | REC-19 D5 | PI / **implement** (continue) |
| **REC-STORE** | Keep every decision's alternatives and factors; no sampling; cap stops recording, keeps data, marks incomplete | Storage rule done; brain decisions keep every branch and factor | `flight_recorder.gd:14, 29, 86-88, 279-281, 337-368`; `world_recorder.gd:136-160` | Yes | Working for `NPCBrain.decide`; **judgment-weighted decisions record no alternatives or factors** (no recorder call in `game/scripts/core/judgment/`; the trace exists in `JudgmentWeighting.choose` result, `judgment_weighting.gd:23,75-161`) | recorder 169/0 | Record each `choose` trace row (candidate, feasible, factor values, utility, policy, stubborn penalty, family colour) as alternative and factor rows: same work as REC-19 D5 | REC-19 D5 | PI / **implement** (one implementation with REC-19 D5) |
| **B19-EMERGE** | Classify unexpected outcomes as emergent, defect or design question; no rescues; tests verify rules; Build 18 baseline kept, Build 19 proposed with explained differences | Applied for Build 19: runs 2-4 classified (F9a defect fixed a7c84e9; F4/F4b design questions; deaths emergent); baseline 2685a26 with `sim_baseline_build18.json` kept | `docs/design/SIM_FINDINGS.md:45-70`; baseline written at 2685a26, kept on x20 as `docs/release/sim_baseline_build19.json` beside `sim_baseline_build18.json` | n/a (principle) | Met for Build 19's 30-day scope; judgment-driven changes cannot carry recorder evidence until D5 | SIM_FINDINGS | Close for Build 19 against SIM_FINDINGS; apply it again to the SJD-G runs | REC-19 D5, SJD-G | IU / **verify** |
| **WDR-009-C** | Rule 009 emergent gameplay, verified by the 30-planks scenario (provenance, transfer, construction, generations, dialogue, save/load, consequences) | Shared systems with consequences exist; the scenario does not | see GM-01 | Partly | Scenario absent | none | GM-01, then a test of rule 009's verification scenario | GM-01 | PI / **implement** (through GM-01; no separate code) |
| **WDR-011-C** | Rule 011: five aspiration domains steering real choices, changing after success and setback | None (`git grep -i aspiration game/` finds nothing); job mobility, apprenticeships, storefronts exist | n/a | No | Absent | none | Design note: aspiration state per villager over the five domains derived from real state, read as one factor through `JudgmentWeighting` profiles (no second decision engine), changes on illness, loss, marriage, prosperity via personality; then implement behind a flag with tests | Personality (done), LE-01 actors for goods/property | NI / **implement** (design first; B18-DP-07 APPROVED moved it here) |
| **FIX-D1D2** | A save never activates a disabled feature; a disabled feature keeps its section byte-identical (D1 judgment, D2 economy) | D1: `judgment_foreign` (`world.gd:156, 5511-5514, 5719-5724`), fd99591; D2: `economy_foreign` (`world.gd` x20 diff, `_economy_section` :5996), af62948, merged 0b5287c | as named | Yes | Working. D1 is now only reachable through the test switch (judgment ships ON); D2 is the live case (economy off) | judgment_guard_save 20/0 (`test_foreign_section` :59, `test_enabled_restores` :91, `test_old_save` :106); economy_foundation 89/0 | Register only | none | C / **complete** |

### Nine awaiting verification

| ID | Original scope | Current implementation | Source location | Integration (x20) | Actual functionality | Validation (x20) | Remaining work | Dependencies | Class / Disposition |
|---|---|---|---|---|---|---|---|---|---|
| **FAM-SAC-01** | Children, spouse, parents, self; real decisions (food, resources, work, spending, care, protection, danger); no separate family AI; factors visible in the recorder | `JudgmentFamily` (rule order, never weighed) + `family_*` profiles through `JudgmentWeighting` | fff48a4, 3022fbf, 7559ab0; `judgment_family.gd`; hooks `npc_brain.gd:239,898,968,994,1167` | Yes | Working, enabled. **Recorder criterion unmet**: `family_trace` (`judgment_store.gd:122`, filled `judgment_family.gd:107-116`, cap 64) is read only by `family_first_test` | family_first 104/0 (`test_hierarchy` :148 ... `test_danger` :414, `test_determinism` :552) | Feed `family_trace` rows into the recorder as decision/alternative/factor rows (part of REC-19 D5) | REC-19 D5 | IU / **integrate** |
| **FIX-D3** | Friendly guard: Build 18 fine with judgment off; halve, never waive, with it on | `world.gd:3996-4013` | 3ec38d2, 949b5b9 | Yes | Working | judgment_guard_save `test_guard` :130 (20/0), relations 80/0 | none | none | C / **complete** |
| **FIX-RECF1** | Fix the unsold-goods re-decision loop by root cause | `World._run_plan` work-step minutes; SIM-F9 and blocked-chase follow-ups | c27aaa2, b113f73, a7c84e9 | Yes | Working | recf1 28/0 (REC-F1, SIM-F9, blocked chase) | none (SIM-F2 is a separate open owner finding) | none | C / **complete** |
| **SJD-B** | Gate B: architecture audit and integration map | `docs/expansion19/DESIGN.md` (on x20) | c4b10e4 onward | Yes (doc) | Delivered | doc present | none | none | C / **complete** |
| **SJD-C** | Gate C: event catalog, beliefs, signed interpretation, ledger, tests | `judgment_store.gd`, `judgment.json` events/interpret/belief | c4b10e4 onward | Yes, now live | Working | judgment 217/0 (`test_spec_fixtures` :99, `test_idempotent_and_correction` :146, `test_catalog` :193) | none | none | C / **complete** |
| **SJD-D** | Gate D: factor registry, utility profiles, iron scenario, explanation traces, determinism | `judgment_weighting.gd` (`choose` :33, `explain` :205), `decision.profiles` | c4b10e4 onward | Yes, now live | Working | judgment 217/0 (`test_decision_iron` :329, `test_selection_policies` :392, `test_determinism` :478) | none | none | C / **complete** |
| **X19-FOUND-BONDS** | Relationship history, resentment, familiarity bonus, trust by reliability, serious grievances a year | `judgment_bonds.gd`; Relations gain scaling before caps | 89e5d5a, 6773760, c756211, 3022fbf | Yes | Working | bonds 98/0, relations 80/0 | none | none | C / **complete** |
| **X19-FOUND-FAMREP** | Family reputation, 5%/12% calibration, spillover, trust individual | `judgment_bonds.gd`, `JudgmentStore.colour`, `bonds.reach "extended"` | c756211, 3022fbf | Yes | Working (ring weights PROVISIONAL) | bonds 98/0, judgment_x19 `test_reach` :321 | none (the PROVISIONAL ring weights are owner-tunable, not open decisions) | none | C / **complete** |
| **X19-FOUND-PERS** | Personality framework, 30% stubbornness potential, wisdom, anger, recovery | `judgment_personality.gd`, `judgment.json` `traits` | a3aa237, c756211, 4a0459f, 3022fbf | Yes | Working | personality 91/0, judgment_x19 `test_stubbornness_in_decisions` :394, `test_clock_and_anger` :457 | none (stubborn penalty sizes PROVISIONAL) | none | C / **complete** |

Owner-device acceptance, kept separate: none of these 27 records names a device check in its `playtest` field. The items a
device would still show: SJD-G phone performance; REC-19 Excel export on Android and Windows; the owner's informal play of
judgment in Build 19 (not a gate, owner 2026-10-24).

---

## (d) Totals by disposition

| Disposition | Count | Records |
|---|---|---|
| complete | 11 | SJD-E, PROS-19 (umbrella), FIX-D1D2, FIX-D3, FIX-RECF1, SJD-B, SJD-C, SJD-D, X19-FOUND-BONDS, X19-FOUND-FAMREP, X19-FOUND-PERS |
| verify | 7 | SJD-F, X19-FOUND (umbrella), DVW-B1, DVW-B2, X19-MISINFO, X19-STORY-LIFE, B19-EMERGE |
| integrate | 1 | FAM-SAC-01 (recorder visibility) |
| implement | 7 | SJD-G, GM-01, WDR-009-C, WDR-011-C, REC-19, REC-DIAG, REC-STORE |
| genuinely blocked | 1 | SJD-H (owner review after SJD-G) |
| **total** | **27** | 18 carryovers + 9 verification items |

"verify" here means the code is present, enabled and its tests pass on x20; what is left is closing it against its
acceptance with the evidence above (plus, for SJD-F and B19-EMERGE, the population-level evidence that batch 4 produces).
By real implementation work, the 7 "implement" rows collapse to **four pieces of code**: recorder D4/D5 (REC-19,
REC-STORE, REC-DIAG and FAM-SAC-01's gap), historical memory (GM-01, WDR-009-C), aspirations (WDR-011-C), and the
validation campaign (SJD-G, then SJD-H).

`judgment_perf` (synthetic 100/500-person stress: memory bounds, horizon, save round-trip, sliced vs immediate gossip
identical): **23 checks, 0 failures** on x20. Its timings were taken with 18 other suites running at once, so they are not
a performance measurement.

---

## (e) Proposed implementation order (directive section 5)

Each batch is small, has its own tests and is merged into x20 alone, with `judgment_*`, `family_first`, `recorder_test`,
`migration_test`, `conservation_test` and a short `sim_gate` run before the next one.

| Batch | Directive stage | Content | Files touched | Tests | Parallel? |
|---|---|---|---|---|---|
| **R0** register reconciliation (lead, staging only) | 1 foundations | Record the 11 "complete" and 7 "verify" findings with this evidence; fix the stale `remaining_work`/`next_action` of SJD-E, PROS-19, X19-FOUND; set SJD-F, X19-MISINFO, X19-STORY-LIFE, DVW-B1, DVW-B2 to IMPLEMENTED/INTEGRATED with x20 0b5287c; record that SIM-F4 was answered (417c07f) | `docs/requirements/requirements.json` (via `tools/requirements_update.py`), views | `check_requirements.py` | Yes, with anything (register only on staging) |
| **R1** small foundation cleanups | 1 | Remove or wire the unused `false_accusation` event (publish it in `_refute` so the liar's deed is itself a judged fact); restore the `_unstick` doc comment | `judgment_store.gd`, `judgment.json`, `world.gd` (comment) | judgment_x19, judgment_test, sim_gate | Yes, with R3/R5 (different files); not with LE work in `world.gd` at the same time |
| **R2** judgment integration closure (SJD-F) | 2 judgment | Optional crime hook: a witness weighs reporting through `JudgmentWeighting.choose` (profile `report`, feasibility unchanged), behind its own `integration` flag; politics stays out (Expansion 21) | `npc_brain.gd` (~:237), `judgment_live.gd`, `judgment.json` | new cases in judgment_live_test; sim_gate on vs off | After R1 (same `judgment.json`) |
| **R3** recorder D5 + D4 relations (REC-19, REC-STORE, FAM-SAC-01) | 4 diagnostics (pulled forward: it is the measuring tool for stages 2, 3 and 5) | Recorder hooks on `JudgmentStore.publish/learn/tell/_post/trust_add`, every `JudgmentWeighting.choose` (alternatives + factors in full), `family_trace` rows, Relations shared hours/gifts/harm; coverage rows updated; recorder off by default, no RNG use | `recorder/world_recorder.gd`, `recorder/flight_recorder.gd` (codes), `game/data/recorder_codes.json`, `recorder_coverage.json`, one guarded line each in `judgment_live.gd`, `judgment_weighting.gd` callers, `relations.gd`; `recorder_export/workbook_builder.gd` | recorder_test (+ judgment rows), 10-day economy_sim fingerprint identical with and without `--record` | **Yes, with R1/R2/R5 and LE-01** (recorder files are disjoint; the guarded hook lines are one line each) |
| **R4** historical memory (GM-01, WDR-009-C) | 3 misinformation and memory | Fact `links` and entity refs (building, item, household) in `JudgmentStore`, saved; construction records the gift that went into a building; significance rule for handing down help; `EventTalk` line from record + lineage + building state; save migration | `judgment_store.gd`, `judgment_live.gd` (`on_help`), `construction.gd` (~:1356-1366), `event_talk.gd`, `ui/dialogue_voice.gd`, `world.gd` (save key unchanged: inside the judgment section), `judgment.json` | new `history_test.gd` (three generations: gift -> house -> grandson's line; house destroyed/sold variants), judgment_x19, migration_test | After R1; **not** in parallel with R2 (both in `judgment_live.gd`/`judgment.json`) |
| **R5** aspirations (WDR-011-C) | 2 judgment (a decision factor) | Design note first (five domains from real state, one factor in existing profiles, personality-driven adaptation); then code behind a flag, off until reviewed | new `judgment/judgment_aspiration.gd` or `aspiration.gd`, `judgment.json` profiles, `npc_brain.gd` read sites | new `aspiration_test.gd`; sim_gate | Design in parallel with anything; code after R2 |
| **R6** measurement (SJD-G, B19-EMERGE, REC-DIAG, SJD-F evidence) | 4 then 5 | Short recorded run (10-30 days, seeds 1-2, judgment on vs `--no-judgment`) analysed; then one 365-day run per seed 1-4 with `--every` checkpoints (day 100 read from them) and the off control; ablations trade-only/social-only via `integration` flags; findings classified (B19-EMERGE) | no game code; `docs/design/SIM_FINDINGS.md`, a new `docs/expansion20/B19_CALIBRATION.md` | economy_sim, sim_gate | After R1-R4 are merged (section 11) |
| **R7** economy interaction check | 5 Living Economy | Before any LE decision reads opinion: LE-02 bids/asks call `JudgmentWeighting.choose` with economic factors (need, price, scarcity, alternatives) and `disposition`, so opinion may lead to a refusal when it outweighs the benefit, but never through a fixed reputation cutoff and with no rule that every trade stays possible (owner correction 2026-10-26, `docs/directives/2026-10-26_npc_judgment_refusal_correction.md`; `test_need_vs_opinion` pattern); settle the lapse double channel (`contracts.gd:995-1001`) under OD-LE-05/13; prices that read opinion (DVW-B1 remainder) only after OD-LE-10/14 | `economy/*.gd`, `contracts.gd`, `judgment.json` profiles | economy_foundation_test, judgment_live, conservation | After R3 (to measure it); coordinate with worker F (`wip/x20-le01`) |
| **R8** owner gate (SJD-H) | | Present the R6 report | docs | n/a | last |

Safe in parallel now: R0 (staging), R1, R3 (recorder) and the R5 design note; the Android batch X20-B2 and LE-01 worker F
do not touch the judgment or recorder files.

---

## (f) Open owner decisions that block specific items

| Decision | Disposition | Blocks | Materially changes gameplay? |
|---|---|---|---|
| Gate H itself (spec section 17.24) | owner gate | SJD-H; broad public release | Yes (release) |
| Q-POL-1, Q-POL-7 (politics structure; whether politics waits for live judgment) | OPEN, target 21 | the "politics" part of SJD-F only | Yes; Expansion 21 scope, not Build 19 recovery |
| OD-LE-10 (economic rumour, memory persistence, reliability), OD-LE-14 (player visibility of market decisions) | OPEN, target 20 | DVW-B1's "prices read relationships" remainder; LE use of judgment knowledge (R7) | Yes |
| OD-LE-12 (charity, kinship support, communal relief) | OPEN | any widening of `family_help`/aid weighting into LE (R7); does not block FAM-SAC-01 | Yes |
| OD-LE-15 (performance and population targets) | OPEN | the pass line of SJD-G's performance part (measurement can proceed) | No (acceptance threshold) |
| SIM-F2, SIM-F3 (recorder findings: failed-purchase re-choice; bandits' empty night decisions) | OPEN, target 19 | REC-DIAG closure | F2 no (defect class), F3 no (performance); both await the owner's go-ahead per the bounded-simulation directive |
| SIM-F4 | OPEN in the register, but **answered**: Build 19 ships the owner's rules (417c07f, a7c84e9) | nothing; register update only (R0) | n/a |

No open SJD-Q* or X19-* decision blocks any of the 27: SJD-Q01..Q14 and X19-ASSAULT, -CRT12, -DECAY, -GUARD, -HARMED,
-Q-TIMING, -REGARD, -PERS-FORMULA, -TRAIT-DIST, -SPILL-REACH, -REP-TRANSMIT, -BOND-LIMITS, -MISINFO, -STORY-LIFE are
answered (`docs/directives/2026-10-21_expansion19_sjd_final_decisions.md`, `2026-10-23_owner_answers_*.md`). Values the
release packet calls PROVISIONAL (family ring weights, danger radii, stubborn penalty sizes, lie motive threshold,
family-story thresholds) are agent values the owner may tune; they block nothing.
