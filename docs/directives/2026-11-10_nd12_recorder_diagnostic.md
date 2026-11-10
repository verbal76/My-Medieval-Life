# Owner directive, 2026-11-10: ND-12 recorder diagnostic defect

Received 2026-11-10 in the lead session. Saved verbatim below; never edited. Register id B25-ND12-01.

---

MML Build 25 — ND-12 Recorder Diagnostic Defect

Claude, I authorize you to investigate, reproduce, fix, test, and document ND-12: Recorder Diagnostic Line Being Overwritten.

This work is approved. Do not stop for additional authorization unless investigation reveals a new design decision or a change to established gameplay rules.

1. Establish the Exact Root Cause

Read ND-12 in "docs/audits/B25_NEW_DEFECTS_REGISTER.md" and trace the original evidence.

Investigate:

- Where diagnostic information is generated, stored, modified, and exported.
- Why a diagnostic line is overwritten or lost.
- Whether multiple events within the same simulation minute overwrite each other.
- Whether the issue affects transaction refusals, contracts, household actions, or other recorded events.
- Whether the correction already implemented on "wip/b25-meal-claims" ("d0ddf8f") partially or completely addresses ND-12.
- Whether the defect affects only reporting or also changes simulation behavior.

Do not assume ND-12 is the same defect as the previously incorrect "buyer_inventory_full" classification. Establish that through evidence.

2. Reproduce Before Fixing

Create focused regression tests demonstrating the actual defect.

Test multiple diagnostic events occurring close together, including events involving the same villager, transaction, or simulation minute.

Verify that every event retains its correct:

- Event identity and timestamp.
- Actor and affected entity.
- Action and outcome.
- Actual failure or refusal reason.
- Associated contract or transaction identifier, where applicable.

Record the number of checks failing before the correction.

3. Implement the Correction

Fix the underlying recorder behavior rather than hiding the symptom.

Requirements:

- Preserve distinct diagnostic events.
- Prevent accidental overwriting or loss.
- Report actual refusal reasons rather than misleading fallback labels.
- Maintain deterministic event ordering.
- Preserve existing event schemas where possible.
- If a schema change is necessary, provide backward compatibility or an explicit migration.
- Do not create duplicate events.
- Do not alter gameplay decisions merely to correct diagnostic output.

Keep this fix on an isolated branch based on the appropriate verified development commit.

Avoid conflicts with the existing meal-claims recorder changes.

4. Validate Thoroughly

Run focused failing-first tests, related recorder and economy suites, full Tests, and the simulation gate.

Verify:

- No missing or overwritten diagnostic records.
- No duplicate records.
- Correct refusal classifications.
- Deterministic event sequences.
- Save/load consistency.
- No currency or item conservation changes.
- No unintended gameplay changes.
- Compatibility with existing campaign archives and reporting tools.

Inspect actual CI artifacts and report the exact commit SHA and workflow IDs.

If the recorder correction changes historical measurements or gate outputs, explain precisely why. Do not automatically accept or re-record baselines.

5. Update Project Records

Update ND-12 with:

- Confirmed root cause.
- Affected scope.
- Before-and-after test results.
- Fix branch and commit.
- CI and simulation evidence.
- Any remaining limitations.

Cross-reference related defects where appropriate, but do not silently merge or close separate defect records.

6. Integration Rules

Continue the existing Batch 3+4 baseline attribution, F015/P99 campaign, WP-1 development, and other authorized validation work.

Do not interrupt or reset those workstreams unnecessarily.

Do not merge ND-12 or any other branch without my explicit approval.

Expected deliverable: A verified ND-12 correction, with before-and-after evidence, full regression results, and a clear recommendation on merge readiness.

Proceed with the investigation and correction now. Do not wait for another owner decision unless genuinely required.
