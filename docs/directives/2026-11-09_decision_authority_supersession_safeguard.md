# Owner directive, 2026-11-09: Permanent decision authority and supersession safeguard

Received 2026-11-09 13:43 EST (system clock) in the lead session. Saved verbatim below; never edited. Register id HAG-AUTH-01.

---

HOT ATTIC GAMES — PERMANENT DECISION AUTHORITY AND SUPERSESSION SAFEGUARD

Add the following requirement to our existing GitHub development documentation and recovery standards.

Historical documentation must never be mistaken for current development authority.

Every substantive owner or engineering decision must have a stable identifier and an explicit lifecycle status: ACTIVE, SUPERSEDED, COMPLETED, REJECTED, DEFERRED, or UNDER REVIEW.

When a decision is superseded:

1. Preserve the original decision and its reasoning.
2. Mark it SUPERSEDED and identify the replacing decision.
3. Make the replacement identify the earlier decision it supersedes.
4. Update the canonical register so the currently governing decision is immediately discoverable without traversing the entire historical chain.
5. Reconcile any current-state, recovery, requirement, or implementation documents affected by that change.
6. Distinguish a completed implementation from a decision that remains an active requirement.

Do not create a competing decision authority. Reuse the existing MML requirements register or Upwardly decision and requirements records, as appropriate.

Before implementing any significant change, check the current authoritative decision and its supersession status. Never implement from an isolated historical document without checking whether newer approved directions exist.

Investigate conflicting records. Do not silently choose an older interpretation or invent a resolution.

Add or extend automated documentation checks to flag conflicting active decisions, broken supersession links, missing current-authority references, and stale recovery instructions. Make checks enforceable without creating unnecessary full-game test runs.

Retroactively audit existing decisions and their supersession chains, prioritizing current development and recently changed requirements. Preserve history, correct authority, and commit and push the results through authorized branches.

The goal is that any new AI reading GitHub can identify immediately:

- What is currently authoritative.
- What has been superseded.
- Why it was superseded.
- What was completed and verified.
- What remains authorized or unresolved.

This safeguard is permanent and applies to all future development.
