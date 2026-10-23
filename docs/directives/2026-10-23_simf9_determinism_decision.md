# Owner decision, 2026-10-23: SIM-F9 and determinism

Saved verbatim.

---

Owner decision — SIM-F9 and determinism

Approve SIM-F9.

Correct the same wait-plan initialization defect in eating, taking medicine, and homeless villagers going to bed.

Use each activity's existing intended duration. Do not impose a universal 30-minute wait or introduce arbitrary cooldowns.

Preserve hunger responses, interruptions, sleep behavior, and all existing gameplay rules except the defective timing.

Use targeted regression tests and compare survival, food consumption, medicine use, rest, and deaths before and after the correction.

Investigate any unexpected behavioral changes rather than automatically accepting them.

For determinism, preserve the original Build 18 baseline as historical evidence. Do not repeatedly establish new baselines for each individual fix.

Once the approved identity and wait-plan changes are integrated, verify the combined differences against both seeds and present one proposed new baseline for approval.

Keep the recorder, family-sacrifice work, and other authorized expansion development progressing independently.

Do not merge into the release baseline or publish without authorization.
