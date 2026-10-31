# Expansion 19: NPC Judgment (Subjective Judgment & Universal Decision Engine, EXP-C), shipped as Build 19

Status record under the owner's documentation reconciliation directive (`docs/directives/2026-10-31_documentation_reconciliation.md`,
DOC-RECON-01). Vocabulary and precedence: `docs/expansions/README.md`. Reconciled 2026-10-31 against the register on staging
(`aeaa012` plus `3ecf89f`) and the code on `origin/wip/expansion20` `ad281dc`. Register corrections are proposals until the lead
applies them (listed at the end). Also covers ID-01 (persistent identity, released in Build 19), the Build 19 flight recorder and
the Build 19 recovery (B19-RECOVERY, batches R0-R8), which the owner carried into the Expansion 20 line on 2026-10-24/26.

**Overall status: PARTIAL, nearly complete.** Gates A-G of the specification are implemented; judgment is live and on in normal
play (owner X19-SCOPE). Build 19 was released as a private draft (2026-10-24) and accepted by the owner as the development
baseline. Gate H (owner review) is under way: the owner reviewed the Gate G soak report and issued decisions C1-C6 on 2026-10-31;
the calibration they ordered is integrated on `wip/expansion20` (`17432f0`, `a3643c8`) and is being validated by the running
X20-MERGED-VALIDATION year-long runs. Gate H closes only on the owner's review of those results.

## 1. Current approved scope

| Source | Date | What it settles |
|---|---|---|
| `docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf` / `.txt` | 2026-10-20 | Primary specification: events, signed interpretation, beliefs and confidence, GOOD/BAD ledgers, decision weighting (the 50-iron case), gossip, memory and decay, Gates A-H (s.17-24) |
| `2026-10-20_two_decisions_three_expansions.md`; ROAD-01 | 2026-10-20 | Separate expansion EXP-C; Build 19 |
| `2026-10-21_expansion19_sjd_final_decisions.md` | 2026-10-21 | Answers SJD-Q01..Q14 (all APPROVED) |
| `2026-10-23_owner_answers_build19_sjd.md`, `_x19_assault_crt12_decay.md`, `_x19_guard_harmed_timing_regard.md`, `_x19_release_decisions.md`, `2026-10-23_x19_foundations_round.md` | 2026-10-23 | X19-* decisions (all APPROVED); foundations round (personality, bonds, family reputation) |
| `2026-10-23_x19_complete_release_scope.md` (X19-SCOPE) | 2026-10-23 | **Later owner decision:** Expansion 19 ships complete with every part enabled. Supersedes the spec's Gate E "feature flag OFF by default" and its "isolated, provisional adapters" |
| `2026-10-23_family_sacrifice_responsibility.md` (FAM-SAC-01), `2026-10-23_build19_flight_recorder.md` (REC-19), `2026-10-23_build19_owner_advisement_emergence.md` (B19-EMERGE) | 2026-10-23 | Family-first rule; flight recorder; emergence principle |
| `2026-10-23_identity_foundation_approval.md`, `2026-10-23_id_d2_succession_decisions.md` | 2026-10-23 | ID-01 design, save version 20, ID-D1 and ID-D2 (APPROVED) |
| `2026-10-24_owner_build19_release_authorization.md`; register `builds.19` | 2026-10-24 | Private draft release; "Build 19 complete and accepted as the development baseline; the owner's playtest is not a prerequisite" |
| `2026-10-26_build19_carryover_audit_x20_integration.md` (B19-RECOVERY), `2026-10-26_npc_judgment_refusal_correction.md` | 2026-10-26 | Recover the 27 unfinished or unverified Build 19 records on the Expansion 20 line; opinion may cause a refusal only when it outweighs need, never by a fixed cutoff |
| `2026-10-27_final_aspirations_decisions.md`, D39 (`2026-10-27_39_decisions_current_first_reconciliation.md`) | 2026-10-27 | Aspirations (WDR-011-C, R5) |
| `2026-10-28` owner ruling on ID-D3 (register note) | 2026-10-28 | Identity baseline: conditional approval stands; promote a baseline only after a same-commit conservation, determinism and first-divergence audit |
| `2026-10-31_sjdh_c4_bandit_intelligence.md`, `2026-10-31_sjdh_decisions_le05_authorization.md` | 2026-10-31 | Gate H decisions C1-C6 (SJD-H-CAL APPROVED) |
| `2026-10-31_x20_merged_validation_decisions.md` | 2026-10-31 | Go-between purchasing and judgment-driven migration DEFERRED; merged year-long validation; "stop for my review before proceeding to another expansion or release" |

## 2. Implemented

Code on `ad281dc`: `game/scripts/core/judgment/` (`judgment_store.gd`, `judgment_weighting.gd`, `judgment_live.gd`,
`judgment_personality.gd`, `judgment_bonds.gd`, `judgment_family.gd`, `judgment_social.gd`, `judgment_aspiration.gd`,
`judgment_bandit.gd`, `judgment_soak.gd`, `judgment_math.gd`), `game/data/judgment.json` (`enabled: true`; aspiration `enabled:
false`; integration flags all on except `report` and `job_choice`), `game/scripts/core/identity.gd`, `game/scripts/core/recorder/*`
(recorder `enabled: false` in every build, by design REC-D1).

| Requirement | What | Commit / integrated | Tests (on `ad281dc`) | Validation |
|---|---|---|---|---|
| SJD-A | Build 16 baseline | Build 16 | n/a | INTEGRATED |
| SJD-B, SJD-C, SJD-D | Architecture audit; event catalog, beliefs, signed interpretation, ledger; factor registry, utility profiles, 50-iron scenario, explanation traces | `c4b10e4` onward; `0b5287c` | `judgment_test` (`test_decision_iron`, `test_determinism`) | INTEGRATION VERIFIED |
| SJD-E | First gated integration (live adapter, flag, matched-seed off path); now on by owner order | `c4b10e4`, `7559ab0` | `judgment_live_test` | INTEGRATION VERIFIED |
| SJD-F | Rollout: 13 decision domains through `JudgmentWeighting.choose`; witness reporting hook added in R2 (flag off) | `577821d`, `3022fbf`, `c51d49b` (R2, merge `9b90e05`) | `judgment_live_test` (one test per domain) | TARGETED TESTS PASSED; politics part belongs to Expansion 21 (Q-POL-1, Q-POL-7) |
| SJD-G | Full soak and calibration: 365-day judgment ON vs OFF, seeds 1-2, 100-day values from checkpoints; save growth; performance shortcut | `ed9ade0`, merged `531da40` | `judgment_soak_test`; Actions 41129188776 (ON) and 41129193143 (OFF): 365/365 days, leak 0, no item leak, 0 script errors (`docs/expansion20/SJDG_SOAK_REPORT.md`@X20) | INTEGRATION VERIFIED. Not run: seeds 3-4 and the trade-only/social-only ablations planned for R6 (lead budget 2026-10-30: two configurations, seeds 1-2) |
| PROS-19, X19-SCOPE | Expansion 19 complete and live: memory, judgment, gossip, trust, personality, relationships, family reputation, lies | `b7f832e`, `b2f7dc2`, `2685a26`, `2f72ec3` | Build 19: judgment 217/0, judgment_live 144/0, run_tests 3595/0 | INTEGRATION VERIFIED; X19-SCOPE release status RELEASE CANDIDATE (private draft released) |
| X19-FOUND, -PERS, -BONDS, -FAMREP | Personality framework (30% stubbornness), relationship history, family reputation | `c756211`, `a3aa237`, `3022fbf` | `judgment_personality_test`, `judgment_bonds_test`, `relations_test` | INTEGRATION VERIFIED (children) |
| X19-MISINFO, X19-STORY-LIFE | Deliberate lies and correction (R1: the liar's `false_accusation` is now itself published, `judgment_store.gd:1666-1676`); family stories across generations | `3022fbf`, `7559ab0`, R1 | `judgment_x19_test` (`test_lies`, `test_family_stories`) | TARGETED TESTS PASSED |
| FAM-SAC-01 | Family sacrifice and responsibility, including danger; recorder rows (R3) | `3022fbf`, `fff48a4`; `4f50ffb` | `family_first_test` | TARGETED TESTS PASSED |
| DVW-B1, DVW-B2 | Memory of favours and harms, gossip (judgment store); assault and killing as fined crimes, heir "case ends, stain stays" (GP-CRIME-PURSUIT) | `0b5287c` | `judgment_test`, `justice_test`, `manhunt_test` | TARGETED TESTS PASSED. DVW-B1 "prices read relationships" goes with the Living Economy (OD-LE-10/14) |
| GM-01, WDR-009-C | Historical memory: help toward a house kept as a record, retold by descendants (R4) | `de61317`, merge `9b90e05` (`5770d00`) | `history_test` 28/0 | TARGETED TESTS PASSED |
| WDR-011-C | Aspirations in six domains as a decision factor (R5) | `e25b0ed`, `8bde18b`, `2cc0007`, merge `3601211` | `aspiration_test` 145/0 (155/0 later) | TARGETED TESTS PASSED. **Switched off** (`aspiration.enabled: false`, `job_choice: false`) |
| REC-19, REC-STORE, REC-DIAG | Flight recorder with judgment rows (D5) and relations (D4) (R3); every choice's alternatives and factors; recorded-run analysis | `94b1304`, `2d5d49c`, `4f50ffb`; `3a6eee8`, `5c303be` | `recorder_test` 214, `test_rec_diag` | TARGETED / INTEGRATION VERIFIED; recorder off in builds by design |
| FIX-D1D2, FIX-D3, FIX-RECF1, RECON-01, B19-EMERGE | A save never activates a disabled feature; friendly-guard fine rule; REC-F1 loop root-cause fix; one tolerance calculation; emergence principle | `fd99591`, `af62948`, `3ec38d2`, `c27aaa2`, `b113f73`, `a7c84e9`, `4a0459f` | `judgment_guard_save_test`, `recf1_test` | INTEGRATION VERIFIED (most) |
| SIM-F2, SIM-F3, SIM-F4, SIM-F9 | Recorder findings answered by the owner and fixed | as in the register | `recf1_test`, `sim_f2_test`, `sim_f3_test` | TARGETED TESTS PASSED |
| X20-JUDG-C1, C2, C3, C5; X20-BANDIT-AI | Gate H calibration: judgment integration audit and effectiveness; second-hand memories fade, opinions persist; wrongdoing by incident; mixed feelings in real decisions; bandit self-preservation (C4) | `0d91b65` (merge `17432f0`), `8fb6244`, `dd7dca1` (`a3643c8`) | `judgment_calibration_test` 86/0, `judgment_incident_test` 15/0, `bandit_ai_test` 17/0 | TARGETED TESTS PASSED; year-long validation running (below) |
| **ID-01** | One permanent identity per person, never reused; separate id band from 1,000,000 (ID-D2 option B); save version 20 with one-time upgrade | `af6409f` .. `84d1880` on `wip/foundation-identity`, merged `801d24b` (recorder branch) and `b2f7dc2` (Build 19); released in Build 19 | `identity_test` (in `.github/workflows/tests.yml`), `migration_test`, `succession_test`, `save_transfer_test` | Register says IN DEVELOPMENT with next action "merge into wip/recorder": **stale. Proposed INTEGRATED / INTEGRATION VERIFIED.** The baseline question is ID-D3 (section 6) |

## 3. Partial

| Requirement | Done | Remaining |
|---|---|---|
| EXP-C (umbrella) | Gates A-G | Gate H (SJD-H). Stays PARTIALLY IMPLEMENTED; notes to update (the register note "SJD-G/H not started" is stale) |
| **SJD-H** Gate H owner review | Owner reviewed the SJD-G report and answered C1-C6 (2026-10-31); calibration integrated (`17432f0`, `a3643c8`); merged baseline `ad281dc`; broad enablement already ordered (X19-SCOPE, 2026-10-23); private Build 19 draft authorized (2026-10-24) | The X20-MERGED-VALIDATION results (runs 41233948995 normal seeds 1-2 and 41233970504 economy on, dispatched on `ad281dc`; results not recorded on staging) and the owner's review of them. Public release needs the owner. Register NOT STARTED: **PARTIALLY IMPLEMENTED (applied in the register 2026-10-31)** |
| **B19-RECOVERY** (27 records, batches R0-R8, `docs/expansion20/B19_RECOVERY_MATRIX.md`) | R0 register reconciliation (2026-10-26); R1 `false_accusation` wired; R2 witness reporting through `choose` (flag off, `9b90e05`); R3 recorder D5/D4 (`4f50ffb`); R4 historical memory (`9b90e05`); R5 aspirations (`3601211`, flags off); R6 measurement: recorded 30-day runs (REC-DIAG `5c303be`) and the SJD-G 365-day ON/OFF runs (`531da40`); R7: Living Economy bids and asks go through `JudgmentWeighting.choose` (`econ_market.gd:20`, LE-02, economy off by default) | R6's seeds 3-4 and ablations were not run (lead budget) and its planned output `docs/expansion20/B19_CALIBRATION.md` was never written (`SJDG_SOAK_REPORT.md` took its place); R8 = SJD-H above. Register NOT STARTED: **PARTIALLY IMPLEMENTED (applied in the register 2026-10-31)** |
| SJD-F | 13 domains live | Population-level evidence per domain (SJD-G report section 2 gives part); the `report` hook is off; politics waits for Expansion 21 |
| XAUDIT-01 | Cross-expansion audit written (`docs/design/CROSS_EXPANSION_PRESERVATION_AUDIT.md`) | Owner review of D1-D3 (D1/D2 built as FIX-D1D2, D3 as FIX-D3). Cross-expansion; left to the lead |

## 4. Remaining approved work

| Item | Status |
|---|---|
| SJD-H completion (owner review of the merged validation) | APPROVED, in progress on the Expansion 20 line; nothing for an agent to build until the owner reviews |
| SJD-F politics domain | DESIGN ONLY, NOT AUTHORIZED (Expansion 21; only phase 1 of 21 was ever authorized, and Build 27 needs fresh authorization) |
| DVW-B1 prices that read opinion | Waits on OD-LE-10/OD-LE-14 (Living Economy) |
| XEXPL-01 decision explainability record | APPROVED, unassigned; XEXPL-D1 answered (in-world explanations only for now, a panel later; `docs/design/X19_RELEASE_DECISIONS.md`). Its next action "owner: whether a panel is wanted" is stale |

## 5. Deferred and superseded

| Record | Status | Decision |
|---|---|---|
| FR-09 crime from desperation | DEFERRED | register approval DEFERRED |
| X20-GO-BETWEEN (asking someone to buy from a disliked seller) | DEFERRED | owner 2026-10-31 (`2026-10-31_x20_merged_validation_decisions.md`) |
| X20-JUDG-MIGRATION (strong dislike as a fifth migration reason) | DEFERRED | owner 2026-10-31: "Keep the four previously approved migration reasons unchanged" |
| Spec Gate E "feature flag OFF by default"; PROS-19 "isolated, provisional adapters" | SUPERSEDED | X19-SCOPE (owner 2026-10-23): ships complete and enabled |
| Spec Gate G "seeds 1-4" breadth for R6 | Reduced by the lead's budget (agent), not by the owner: recorded, not superseded | SJDG_SOAK_REPORT s.1 |
| REC-F1 (recorder finding) | Addressed by FIX-RECF1 | SUPERSEDED (applied in the register 2026-10-31) |
| B17F-PERF, E20-RISK-QUEUES | Ideas (PROPOSED) | not approved work |

## 6. Outstanding owner decisions

- **SJD-H**: the owner's review of the X20-MERGED-VALIDATION results (the owner's own instruction: stop for review before another
  expansion or release).
- **ID-D3** (PROVISIONAL): the identity-gate baseline may be promoted only after a same-commit, current-branch conservation,
  determinism and first-divergence audit (owner 2026-10-28). The old candidate `docs/design/IDENTITY_GATE_CANDIDATE.json` (code
  `45d68d3`) is not blessed. Since then the determinism baseline has been rewritten on current commits several times
  (`2685a26` for Build 19; `465a6a2`, `6ee13c7`, `ad281dc` on Expansion 20); whether one of those counts as the required audit is
  the owner's decision, not assumed here.
- **FR-11** personality, prestige and migration (owner list 2026-10-17; approval OWNER DECISION REQUIRED). Its parts now exist
  under other ids: personality (X19-FOUND-PERS), prestige/standing (WDR-011-C aspirations, off), migration (MIGRATE-18, X20-MIGRATE),
  with judgment-driven migration deferred (X20-JUDG-MIGRATION, 2026-10-31). The owner can confirm FR-11 is covered or name what
  is missing.
- **Switching on R5 aspirations and the R2 witness-report hook.** Both were integrated with their flags off "until validation and
  owner review" (agent decision recorded in `judgment.json`); no register record asks the owner. Proposed as a new decision record.
- REC-D1..D4, SJD-Q01..Q14 and every X19-* decision: answered (APPROVED). Agent-provisional values (family ring weights, danger
  radii, stubborn penalty sizes, lie threshold, family-story thresholds, R4/R5 numbers) are tunable by the owner; they block nothing.

## 7. Dependencies

Gate A needs the Build 16 baseline; ID-01 built on Build 18's settlements (members' ids); Expansion 20 depends on this engine
(LE-02 bids and asks use `JudgmentWeighting`; bandit AI reuses its profiles); Expansion 21 politics depends on SJD-F (Q-POL-7).
The SJD-H close depends on X20-MERGED-VALIDATION, which belongs to Build 25 (Expansion 20 validation and freeze).

## 8. Implementation and validation references

| Item | Reference |
|---|---|
| Branches | prospective `wip/expansion19-preparation` (`b7f832e`); `wip/foundation-identity` -> `wip/recorder` (`801d24b`); integration `wip/build19` (`42c33e0`, release `2f72ec3`, game code `417c07f`); carryover on `wip/expansion20` (`0b5287c` audit, `9b90e05`, `4f50ffb`, `3601211`, `5c303be`, `531da40`, `17432f0`, `a3643c8`, `ad281dc`) |
| Release | private draft "My Medieval Life Build 19", run 40044931601 (2026-10-24; first run 40043968310 stopped at a test, fixed in `2f72ec3`); throwaway Android key (pre-policy); `docs/release/BUILD_19_PACKET.md`@X20 |
| Determinism | three identical 30-day runs on `417c07f`; baseline `2685a26` (B19-BASELINE APPROVED), Build 18's kept as `sim_baseline_build18.json` |
| Gate G | `docs/expansion20/SJDG_SOAK_REPORT.md`@X20, Actions 41129188776 / 41129193143 |
| Running | X20-MERGED-VALIDATION 41233948995, 41233970504 on `ad281dc` (do not cancel or restart: SIM-02) |
| Stranded | `origin/wip/expansion19-snapshot` `239aa50` (superseded); `origin/wip/x20-sjdg-off` `d0f623b` (same commit as the SJD-G OFF run, kept only for that dispatch) |
| Stale headers on the validating branch (not edited here) | `docs/expansion19/DESIGN.md`@X20 "PROSPECTIVE ... nothing integrated" |

## 9. Next authorized phase

No new Expansion 19 work is authorized. The remainder (SJD-H) closes with **Build 25** (Expansion 20 validation and freeze),
after the owner reviews the merged validation. **Build 26** = repository recovery and consolidation (bring `docs/expansion19/`,
`docs/release/BUILD_19_PACKET.md` and the X20-only judgment notes onto the consolidated line). **Build 27** = Expansion 21 only if
the owner authorizes it; the politics domain of SJD-F goes with it.

## 10. Missing sources

- `docs/expansion20/B19_CALIBRATION.md`: planned R6 output named in `B19_RECOVERY_MATRIX.md`; never written on any branch. Its
  role was taken by `docs/expansion20/SJDG_SOAK_REPORT.md`@X20. An agent document, not an owner source; listed so nobody looks for it.
- The owner's 2026-10-17 "living-society" message (#47) behind FR-11 and FR-09: only summarized in
  `docs/requirements/RECOVERY_2026-10-19.md` (rows 28, 38, 41, 42, 46); its verbatim text is not in `docs/directives/` on any
  branch read. Recover from the owner if FR-11's exact wording matters.
