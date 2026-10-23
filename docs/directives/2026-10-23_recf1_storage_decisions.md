# Owner decisions, 2026-10-23: REC-F1 and recorder storage

Saved verbatim.

---

Owner decisions — REC-F1 and recorder storage

REC-F1: Approved for investigation and a narrowly scoped gameplay correction.

The repeated decision loop involving villagers holding unsold goods is a legitimate simulation defect to investigate.

Identify the actual cause before modifying behavior. Correct the condition that causes villagers to reconsider an unavailable action hundreds of times without productive results.

Do not simply impose an arbitrary cooldown that conceals the problem. Preserve NPC autonomy, economic behavior, and the ability to react promptly when circumstances change.

Verify that the correction reduces redundant decisions without suppressing legitimate work, trading, production, or other activities.

Keep the correction isolated from unrelated gameplay systems. Preserve Build 18 as the released baseline.

Storage: Retain all recorded decision details.

Do not reduce, sample, or discard the alternatives and decision factors. The complete decision history is a primary requirement of this recorder.

Retain the approved storage-limit behavior: stop recording, preserve existing data, and explicitly mark incomplete sessions.

Continue the identity integration and recorder development as planned. Do not delay Expansion 19 for unnecessary optimization or unrelated refactoring.

Use targeted tests and existing valid evidence. Report the root cause, exact correction, and before/after decision and action counts.

No merges into the release baseline or publication without authorization.
