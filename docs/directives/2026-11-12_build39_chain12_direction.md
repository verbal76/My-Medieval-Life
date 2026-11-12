# Owner directive 2026-11-12 (received about 18:50 EST): MML Build 39 — Chain 12 Direction

Saved verbatim by the lead.

---

MML Build 39 — Chain 12 Direction

Continue from "b3c9eb5" on "wip/b25r2-rev2".

Baseline decision: NOT APPROVED YET.

The candidate baseline may be correct, but the 32 "eq_s1" differences must be investigated before acceptance.

1. Compare the accepted baseline "df67e8e" against chain 12.
2. Identify each of the 32 differences and trace it to the responsible code or system change.
3. Classify each difference as an expected behavioral change, test artifact, or potential regression.
4. Verify currency and item conservation, deterministic behavior, and save/load integrity.
5. Fix any actual regressions.
6. Preserve the existing accepted baseline until the investigation is complete.
7. Present the findings and a recommendation for owner approval.

Continue other work in parallel where safe:

- Prepare and execute the chain 12 365-day simulation campaigns.
- Investigate ND-19, ND-22, ND-28, and the two player-journey findings.
- Run INV-02 with its switch enabled.
- Investigate Android "--export-debug" behavior.
- Prepare hardware multiplayer test procedures for Android pause/resume, packet loss, slow joining, and device sleep.
- Continue verification of the 21 integrated items.
- Investigate prerequisites for REG-04, REG-05, MP-02, and JOB-02 without bypassing owner decisions.
- Preserve the inventory source and Idle-game backup until deletion is explicitly authorized.

Release conditions:

Do not activate a new baseline without owner approval.

Do not bypass the release gate.

Do not publish a private Build 39 draft until the baseline is approved and the required release checks pass.

Do not upload anything to Steam or make a public release.

Reporting:

Maintain the 69-item tracker, defect register, decision history, and timestamps.

Report verified counts rather than percentages.

Separate completed work, unresolved issues, and owner decisions.

Investigate unknowns rather than treating them as acceptable exceptions.

If the 22:00 freeze arrives before the baseline investigation is complete, preserve the current candidate and stop release promotion. Do not rush baseline acceptance to meet the deadline.
