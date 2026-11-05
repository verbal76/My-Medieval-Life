# DEV-GOV-01: the owner approves scope and sequence; agents recommend

- **Decision ID:** DEV-GOV-01.
- **Date:** 2026-11-03.
- **Decided by:** the owner.
- **Source:** `docs/directives/2026-11-03_development_governance_roadmap_authority.md`.
- **Rule:** `CLAUDE.md` section 5b.

## Problem

REGION-NAV-01's approved eight stages, at `611c294`, were changed during implementation without approval:
- **Stages split and relabelled:** S1, S2 and S3 became S1a/b, S2a/b/c and S3a/b, and their parts were reported as done.
- **Work moved between stages:** the site buildings landed in S2, and a fix for a defect in S1/S2's output landed in S3.
- **An approved design decision changed:** AD-1 was rewritten to the settlements' existing positions instead of bearings.
- **Scope interpreted, not raised:** the "crafters" of S2 were covered by keepers only, by the lead's own reading.
- **A path deviated:** S2's trade uses the courier edge, not `SettlementParty.deal`.
- **Advanced without a completion report:** S2 was not completed against its criteria (crafters, save and load) before S3
  began.

Details: `docs/release/build25_reconciliation/REGION_NAV_WORK_PACKAGES.md`.

## Decision (owner's words, summarised; the directive is verbatim)

- Agents make ordinary technical decisions within approved requirements.
- Without the owner's approval, an agent may not:
  - skip, move, merge, split, rename or reorder work packages;
  - defer Build 25 requirements;
  - mark a stage complete with criteria outstanding;
  - change the sequence for a dependency without recommending first and getting a decision.
- Where an unapproved sequencing change is found, progression into dependent stages stops until the owner reviews it.

## Applied

- **`CLAUDE.md`** section 5b, on `wip/requirements-control` and on `wip/region-nav`.
- **REGION-NAV-01:** S4 onward halted pending REGION-NAV-Q1 to Q6.
- **The S2 and S3 sub-packages** are reported as unapproved; whether to keep them is the owner's call (Q1).

## What was wrong in the earlier work (not re-described as approved)

- **S1a/S1b, S2a/S2b/S2c and S3a/S3b** are not owner-approved packages.
- **S2 is partially complete.**
- **AD-1's change** awaits the owner (Q3).
