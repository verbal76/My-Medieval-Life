# B25R1 owner questions, 2026-11-05 (seven decision groups)

Prepared for the owner's Option 1 decision (`docs/directives/2026-11-05_b25r1_audit_option1.md`, register B25R1-AUDIT-OPT1):
"For the seven owner-decision groups, prepare the exact outstanding questions, the existing approved policy, the available evidence,
and your recommended resolution. Ask me those questions one at a time."

- One section per group; within a group, each question is numbered and can be answered on its own.
- Recommendations are the lead's, marked as such; none is an approval and none is implemented as if it were.
- Evidence comes from the audit `docs/audits/B25R1_REQUIREMENTS_AUDIT_2026-11-05.md` and the register; code head `wip/b25r1` `a995397`.
- Development continues on all independent work while these wait.
- Suggested order of asking (most release-relevant first): 1, 2, 3, 4, 5, 6, 7.

---

## 1. B25-BIZ-OWN: no villager founds a business (with B25-ECON-P1..P5)

**Existing approved policy.**
- B25-BIZ-OWN (owner 2026-11-01, `docs/directives/2026-11-01_business_ownership_employment_final_decisions.md`): "A business must be
  something a villager can establish, operate, grow, sell, purchase, inherit, or lose." Acceptance 2: longer simulations show whether
  NPCs found, buy, sell, operate and expand businesses without intervention.
- B25-BIZ-TENANT-Q (APPROVED, Option B): a tenant may build a standalone workshop on purchased land.
- WDR-022: "A village is allowed to fail. The simulation is not." Outcomes are measured, not forced; no hidden rescue.

**Evidence.**
- Code integrated: d0dc0d7 (founding), 908a17e (milestones 1-6), 3c7e45b (tenant rule). Suites: business_founding 58-73/0,
  business_ownership 165/0, business 160/0, business_money 37/0, till_ownership 71/0.
- Year-long runs 41362329381 (908a17e, seeds 1 and 2): no venture considered, founded, bought, sold, hired or expanded all year;
  conservation clean. Population 356 and 308, unemployed 141 and 112.
- Funnel (d6ab686, `docs/expansion20/ECONOMIC_INVESTIGATION_2026-11-02.md` on the Build 25 source): every weekly look stops at
  the demand gate (founding trades' benches 2-20% busy against the 0.35 threshold).
- Not yet available: the funnel on the Revision 1 world at the final SHA (the R1 campaign). Option 1 item 4 orders that
  investigation; its result may change the recommendation.

**Q1.1 (B25-ECON-P1). Should a villager be able to found a business while the trade's existing benches are mostly idle?**
- A: keep the rule (found only when the trade's benches are at least 35% busy). B: the founder weighs independence even with idle
  benches (judgment decides). C: a lower busy threshold for founding only.
- *Recommendation:* A. The gate is working as designed; demand is the real constraint.

**Q1.2 (B25-ECON-P2). Should a household buy a coinless young adult's first work tool so they can take an open miner or woodcutter
place?**
- A: keep (no help). B: the household buys it from its own purse under existing purchase rules. C: the manor advances the tool against
  wages. D: tool rental outside the Living Economy.
- *Recommendation:* B (uses existing rules; no rescue money).

**Q1.3 (B25-ECON-P3). Should retired villagers and adults between jobs sell the trade stock they hold?** (Day 120: elders held 68 iron
ore, 47 coal, 24 iron bars, 8 pickaxes, 7 axes while the working smith held nothing.)
- A: keep. B: they sell it through the existing sell rule. C: it passes to the trade's successor, as tools already do.
- *Recommendation:* B.

**Q1.4 (B25-ECON-P4). Should a neighbour trader with no coins be able to carry ore on consignment?** (Garton's quarry stock 63 -> 175;
0 iron ore reached the village in 120 days.)
- A: keep as an outcome. B: the trader carries ore on consignment, paid on sale. C: smiths buy from the quarry directly.
- *Recommendation:* B, after the R1 campaign confirms the stall still occurs on the new world.

**Q1.5 (B25-ECON-P5). Should village land (fields, trees, game, ore) grow with population?**
- A: no (fixed land; unemployment rises with population). B: yes, by a rule the owner sets.
- *Recommendation:* A on present evidence.

**Q1.6 (checklist H1). If the answers above still produce no founding in the R1 campaign, is zero business founding over a year an
acceptable WDR-022 outcome that closes B25-BIZ-OWN acceptance 2?**
- A: yes, the mechanism is proven by its tests and the outcome is legitimate. B: no, founding must be observed in the campaign.
- *Recommendation:* A, provided the funnel shows a legitimate economic cause (demand), not a defect or an unreachable condition.

---

## 2. B25-FINISH-01: Build 25 definition of done (checklist section H)

**Existing approved policy.** B25-FINISH-01 (owner 2026-11-03, `docs/directives/2026-11-03_build25_completion_directive.md`): "finish
all work already approved for Build 25 ... No new features." Acceptance 2: every approved Build 25 requirement complete. Checklist
`docs/release/build25_reconciliation/COMPLETION_CHECKLIST.md` section H lists four owner answers. H1 is group 1 (Q1.6), H2 is group 3,
H3 is group 4; they are asked there, not repeated here.

**Evidence.** Build 25 private draft built: a459186, run 41666958781, release 432836586 (kept as the R1 rollback point). JOB-02, PIT-02
and FSE-10 have `target_build` "owner decision"; CON-02-KINDS is `unassigned`, but its history records that B25-NINE-D2 (owner
2026-11-01, Decision 2) incorporated the service-contract categories and their dependencies into Build 25.

**Q2.1 (H4). Are JOB-02 (offered pay on the manor job board), PIT-02 (larger, deeper open pits) and FSE-10 (gardens, rented land, side
hunting, multiple incomes) outside Build 25 and Revision 1?**
- A: confirm outside; they stay approved and unplaced. B: place one or more in Revision 1 (named).
- *Recommendation:* A.

**Q2.2 (H4, CON-02-KINDS). B25-NINE-D2 brought the service-contract categories into Build 25. Does that include CON-02-KINDS (further
labour and service contracts beyond dig and survey), so it must be built for Revision 1?**
- A: yes, CON-02-KINDS is Build 25 scope (it must be implemented before B25R1 completes). B: no, D2 covered CON-03..CON-08 only;
  CON-02-KINDS stays unplaced.
- *Recommendation:* ask, do not assume. The register is inconsistent (unassigned build, Build 25 history line); the lead leans B
  because D2's text names CON-03..CON-08.

**Q2.3. Does Build 25's completion (B25-FINISH-01) now close together with Revision 1 (B25R1-001), on the R1 final SHA, rather than on
the Build 25 draft a459186?**
- A: yes, one finish line: B25-FINISH-01 closes when B25R1 completes. B: no, close B25-FINISH-01 on the Build 25 draft evidence once
  H1-H4 are answered.
- *Recommendation:* A (Option 1 treats the audit, which spans both, as one completion checklist).

---

## 3. LE-07: release gate 11, mid-range phone performance

**Existing approved policy.** OD-LE-15 (APPROVED, D14 answer C): "Economy target about 500 NPCs on a mid-range Android phone, work
staggered to at most about 4 ms per game frame: a target to PROFILE, not a success claim." LE-07 acceptance: "All mandatory release
gates green."

**Evidence.** Gates 2, 3, 5, 7, 8 passed; 4 and 6 on the 4b51c92 year; 9 reviewed; 10 settled; 12 and 13 applied (b00439f). Gate 11 was
marked "PROFILED; not blocking" by the lead (b00439f, LE07_GATE_STATUS.md), not by the owner. Desktop profile: LE-06 25.07 s a game day
on, 25.39 s off (106 villagers). No measurement on a phone. B25R1-020 (crowd management) also asks for an Android measurement.

**Q3.1. Does gate 11 need a measurement on a real mid-range Android phone before B25R1 ships?**
- A: yes, a device profile is required (the owner runs it or names the phone). B: no, the desktop and container profiles settle it
  under OD-LE-15 ("a target to profile"); gate 11 records the numbers without blocking.
- *Recommendation:* A, combined with the B25R1-020 Android measurement in one profiling session on the R1 candidate APK, so one device
  check closes both. If no device is available before the Early Access date, B.

---

## 4. SJD-H: Judgment expansion Gate H, owner review

**Existing approved policy.** SJD-H: owner review; release and broad enablement approved separately. Broad enablement was ordered
(X19-SCOPE, 2026-10-23). The owner answered calibration C1-C6 on 2026-10-31; all integrated (17432f0, 8dc6cef).

**Evidence.** Calibration integrated and tested (X20-JUDG-C1/C2/C3/C5, X20-BANDIT-AI: targeted tests passed). The review input named in
the register, X20-MERGED-VALIDATION (runs 41233948995, 41233970504 on ad281dc), is VERIFICATION FAILED (gossip script error, fixed
since as X20-TELL-GUARD) and was never reported as a review package. The R1 campaign will produce judgment evidence on the new world.

**Q4.1. What should the Gate H review be based on?**
- A: the judgment section of the R1 365-day campaign reports (B25R1-016) plus the playtest build, presented as one package. B: the old
  X20-MERGED-VALIDATION runs. C: the owner's own play of the R1 candidate only.
- *Recommendation:* A (checklist H3: "review with the playtest build").

**Q4.2. Is Gate H a release blocker for B25R1, or can B25R1 ship with judgment enabled (as ordered) while Gate H stays open?**
- A: blocker. B: not a blocker; Gate H closes when the owner reviews.
- *Recommendation:* B (enablement is already the owner's order; Gate H is a review, not a defect).

---

## 5. CHAPEL-LENDING: nine design questions

**Existing approved policy.** Concept approved (owner 2026-11-02, `docs/directives/2026-11-02_chapel_economic_purpose_correction.md`):
"Do not invent interest rates, collateral seizure, repayment schedules, or debt enforcement without an approved design." Acceptance: a
written proposal with the open questions; nothing built until the design is approved.

**Evidence.** Proposal written: `docs/expansion20/CHAPEL_LENDING_PROPOSAL.md` (on the Build 25 source, 8b203c5). It reuses trade credit
(`credit.gd`: no interest, repayment only above the debtor's reserve, default lowers regard), the transaction authority (chapel already
a holder) and household means. Nothing is built. The acceptance (a proposal) is met; implementation waits for these answers. It is not
in the B25R1 directives, so building it is not B25R1 scope unless the owner places it.

**Q5.1 Interest.** A: none (as trade credit). B: a small fixed fee stated at the start. C: weekly interest at a rate the owner sets.
*Recommendation:* A.

**Q5.2 Who may borrow, and for what.** A: households in hardship (14-day line) for recovery. B: A plus businesses with an earnings
history and a temporary shortfall. C: B plus village improvement and infrastructure projects. *Recommendation:* B.

**Q5.3 Security.** A: none, trust only. B: goods pledged and held by the chapel, returned on repayment. C: property pledged.
*Recommendation:* A.

**Q5.4 Repayment schedule.** A: one due day (length set by the owner). B: weekly instalments from what the debtor can spare above its
reserve. C: repaid when able, no due day. *Recommendation:* C (or A with a long term).

**Q5.5 When a borrower cannot repay.** A: no more loans while it stands; written off after a period. B: the trade-credit default
(regard falls). C: stronger enforcement (needs a new design). *Recommendation:* A.

**Q5.6 How much the chapel may lend.** A: only from the surplus above its operating reserve, after emergency relief, a share the owner
sets. B: a fixed share of the fund. C: a separate purse built from repayments. *Recommendation:* A.

**Q5.7 Grants versus loans.** A: hardship relief stays a grant (coin alms); loans only for recovery and businesses. B: the chapel
chooses grant or loan by a rule. *Recommendation:* A.

**Q5.8 Who decides.** A: a fixed rule. B: the preacher through the judgment framework (trust and opinion matter).
*Recommendation:* A for the first version.

**Q5.9 The player.** May the player borrow from the chapel on the same terms as villagers? A: yes, same rules (PAR-02). B: no.
*Recommendation:* A.

**Q5.10 Placement.** Once answered, is chapel lending built in Revision 1, or placed in a later build? A: Revision 1. B: a later build
the owner names. *Recommendation:* B (not in the B25R1 directives; Option 1 forbids moving approved B25R1 work, not adding new work).

---

## 6. DOC-AUTH-01: document authority replacement

**Existing approved policy.** Owner 2026-10-31 (`docs/directives/2026-10-31_document_authority_replacement_policy.md`): the revised
master specification set becomes the sole authority only on the owner's explicit final approval; until then, the latest explicit
owner decisions and the validated baseline govern. "The authority switch occurs only after my explicit final approval—not when a draft
is first delivered."

**Evidence.** No revised package has been delivered (register: "waiting for the owner's revised document set"). Nothing in B25R1 depends
on it; the audit counts it as blocked only because it waits on the owner.

**Q6.1. Is the revised master specification package (rebuilt from the original packets) still coming, and should B25R1 continue under
the current authority (register plus latest owner directives) until it does?**
- A: yes, still coming; B25R1 proceeds under current authority and DOC-AUTH-01 is not a B25R1 completion item. B: the package is no
  longer planned; close DOC-AUTH-01 as superseded by the register. C: deliver it now and pause affected design work.
- *Recommendation:* A.

---

## 7. DOC-RECON-REVIEW-01: integrating wip/requirements-control

**Existing approved policy.** Owner 2026-10-31 (`docs/directives/2026-10-31_doc_recon_review_decisions.md`): "Keep
wip/requirements-control isolated at commit 3098a5f... until I explicitly authorize integration"; "Do not merge wip/requirements-control
into staging, wip/expansion20, or the gameplay baseline without my approval." Later directives (2026-11-01) make the register on this
branch authoritative and the place register changes are made.

**Evidence.** The consolidated owner-decision report was delivered (`docs/expansions/OWNER_DECISIONS_PENDING.md`, updated with the
2026-11-01 answers). `wip/requirements-control` is 168 commits ahead of `staging/my-medieval-life` (staging has one commit of its own:
the stale-state banner, baa6479). The register passes `tools/check_requirements.py` with 0 problems. Staging's copies of the register
and state file are stale.

**Q7.1. May wip/requirements-control now be merged into staging/my-medieval-life (register and documentation only; no gameplay code)?**
- A: yes, merge now, then staging carries the authoritative register again. B: yes, but only when B25R1 is frozen. C: no, keep it
  isolated.
- *Recommendation:* A. It ends the two-copy risk; staging's game code is untouched by these commits.

**Q7.2. Are the other items of the 2026-10-31 review (open questions WIKI-B17, E25-OD-07, REC-003, FR-11, REC-014, JD2-JD5 and the
weather and creature questions) to stay open and outside B25R1?**
- A: yes, they stay open and are not B25R1 work. B: the owner names any to answer now.
- *Recommendation:* A.
