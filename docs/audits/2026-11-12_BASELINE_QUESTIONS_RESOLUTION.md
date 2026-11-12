# The five baseline-comparison questions: findings (B25R2-CONT-01 section 2)

Owner directive 2026-11-11 (`docs/directives/2026-11-11_b25r2_authorization_continuation.md`, section 2). Source of the questions:
`docs/audits/2026-11-10_BASELINE_ATTRIBUTION.md` (33 gate findings against the accepted baseline `df67e8e`, attributed to 21
change points). The accepted baseline is unchanged; nothing here re-records it.

## 1. Band household (households 25 -> 26, 4 findings): intentional, owner-approved

- Root cause: `bf20dc9` "The band moves to the wild" (merged as change point #30 `1d024dc`). From day 0 the outlaw band is its own
  household (index 25, six members, all bandits) on a concealed wild camp.
- Approval: owner decision B25R1-Q2 option (a) (register B25R1-014). The effect on the household count was written down before the
  change in `docs/release/SIM_BASELINE_CHANGES_B25R1_HOMESTEAD.md` ("1. The band lives in the wild (owner B25R1-Q2 option a). From
  the founding the six bandits are a household ...").
- Verdict: not a defect. The 4 findings are the approved behaviour; they disappear when the baseline is re-recorded (question 5).

## 2. The 28 value differences: intentional changes and defect fixes, none unexplained

- Each of the 28 is tied to one of 20 change points: 10 owner-approved changes (generations 4 and 7, the band, hamlets and
  walkers, presence, economy P1-P5, owner questions 27/32/33, LIFE-04) and 10 defect fixes (roads off settlement ground, the
  axe-gift loop, generation 6 and 8, NPC-02). Measured over 66 commits and 89 runs; every repeat matched (no non-determinism),
  and no sample had a currency or item leak (attribution report, sections 2-4).
- Verdict: not defects. They are the current approved behaviour; the accepted baseline predates them.

## 3. Roads and the `b4a302b` record: the roads are valid; the commit message was wrong

- `b4a302b` (2026-11-06, two lines removed from `overworld.gd`) says "it changed no road on seeds 1 and 2". The attribution's route
  probe (a hash of every site-to-site route) shows the roads did change on both seeds, repeatably, and seed 2's simulation with
  them. The claim is wrong; the change itself (dropping the half-tile second search for a dry way) was later reworked by the other
  generation-8 commits.
- Road validity on the current line: `bridge_validity_test` (no bridge loops over water and back, seeds 1, 2, 3) and
  `road_types_test` run in every full Tests run and passed on the development line (Tests 42947422593 on `1f7043b`) and on the
  Batch 3+4 merge (42940243926).
- Correction (routine, record only): this file and the erratum in `docs/DECISIONS.md` correct the record; the commit is not
  rewritten (history is never rewritten).
- Verdict: not a gameplay defect; a wrong statement in a commit message, now corrected.

## 4. Courting after a partner emigrates: a real conflict with an owner rule (decision needed)

- Code (development line `1f7043b`):
  - `Life.free_to_partner` (LIFE-04): "free to court and marry unless a partner is still alive ... only death (or a partner the
    world no longer holds) frees."
  - An emigrant is marked `away` with `alive == false` (`settlement/migration.gd`), so the spouse left behind counts as free.
  - The **work** move (`Migration._work_out`, migration.gd:686) takes a single adult without a trade (`Life._may_move` checks
    household, reeve, sage, guard and young children, not a partner) and moves them alone: a married person can leave their
    spouse behind. The **land** move takes "the grown member who would have founded a household, with their partner"; the
    **hunger** move takes the whole household.
- Effect: a villager whose spouse left for work may court and remarry while that spouse is alive in a settlement.
- Conflict: owner LIFE-04 rule "a living spouse cannot be bypassed". Whether it occurred in the gate's seed 2 run was not traced.
- Decision for the owner (gameplay rule):
  - (a) A married adult who leaves for work takes the partner along, as the land move does (recommended: consistent with the
    land move and with LIFE-04; a small change in `_work_out`).
  - (b) Married adults do not leave alone for work at all.
  - (c) Emigration ends the marriage (a separation rule), so the spouse may remarry (new rule; contradicts LIFE-04 as written).

## 5. Does the baseline need re-recording? Yes, after 1 and 2 are accepted; owner approval required

- The accepted baseline `df67e8e` no longer matches the code's versions; every gate since reports the same 33 findings, all
  explained (questions 1 to 3). While it stands, every gate keeps reporting them and a real new difference must be found among
  them by hand.
- Recommendation: once the owner accepts 1 and 2 (and decides 4, if it is to change the behaviour first), re-record the baseline
  on the then-current development commit, with its version field, keeping `df67e8e` and this comparison archived.
- Not done: re-recording needs the owner's explicit approval (BASELINE-AUTH-01).
