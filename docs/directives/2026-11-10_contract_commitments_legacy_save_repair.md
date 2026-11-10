# Owner directive, 2026-11-10: Contract commitments and legacy save repair

Received 2026-11-10 in the lead session. Saved verbatim below; never edited. Register ids B25-CONTRACT-FUNDS-D1 (decision 1),
B25-SAVE-PHANTOM-D2 (decision 2); answers the two open questions raised with B25-INV-P52-BLOCKS and B25-INV-BANDIT-CHILD.

---

MML Build 25 — Owner Decisions: Contract Commitments and Legacy Save Repair

Decision 1: APPROVED

Correct contract acceptance so merchants account for coins already committed to market bids, existing contracts, and other enforceable obligations.

Use the economy's established available-funds and claims rules. Preserve legitimate credit and financing where supported.

Do not allow merchants to accept obligations they cannot fund merely because their total purse appears sufficient.

Investigate whether existing contract deposits, staged payments, or other obligations require different treatment. Prevent double-counting commitments.

Add focused tests for competing bids, insufficient available funds, legitimate credit, contract acceptance, and conservation.

Decision 2: APPROVED WITH SAFEGUARDS

Develop a deterministic migration or reconciliation procedure for phantom household memberships in existing saves.

Do not indiscriminately delete household entries.

Establish authoritative membership using existing household, residence, family, and migration records. Where ownership or membership cannot be determined safely, preserve the data and flag the ambiguity rather than guessing.

Validate against copies of representative older saves, including bandit households and orphan reassignment cases.

Ensure migration is idempotent, preserves legitimate relationships, and produces consistent save/load results.

Keep this work isolated from the Batch 3+4 merge candidate.

Integration requirements

Continue validation of the existing F015/P99, meal-claims, clan-child-pantry, and household-member-ID branches.

Do not merge or accept baselines without owner approval.

Complete baseline attribution and deliver the Batch 3+4 decision report as soon as its evidence is ready.

Document exact SHAs, test counts, findings, and remaining risks.

Proceed with these approved investigations and corrections without requesting another design decision unless a genuinely new issue arises.
