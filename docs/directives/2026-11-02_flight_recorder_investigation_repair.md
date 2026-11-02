# Owner directive, 2026-11-02: continue the Flight Recorder investigation and repair (FR-REPAIR-01)

Received in session, verbatim:

> Continue the MML Flight Recorder investigation and repair as planned.
>
> For KI-HOME-DOOR, distinguish the immediate exception from its underlying cause.
>
> 1. Use the saved day-200 Seed 2 snapshot to identify every villager with a missing, invalid, or stale home reference. Classify the causes, including housing shortages, building removal, sale, ownership transfer, and resident reassignment.
>
> 2. Fix stale references at their source wherever they occur. Independently make NPCBrain._plan_evening handle legitimate homelessness safely and deterministically.
>
> 3. Add regression coverage for villagers who begin homeless, lose a home, move to another home, and encounter a sold or removed building. Verify that the evening routine never dereferences an invalid building.
>
> 4. Resume Seed 2 from the saved snapshot for at least 10 days on the corrected source. Require zero related script errors and verify that residents still perform meaningful rest behavior rather than merely suppressing exceptions.
>
> 5. Preserve the original failing evidence and compare before/after behavior. Do not silently discard or reclassify historical findings.
>
> 6. Investigate KI-FR-CARTHITCH and the wheat-sale/contract-cancellation patterns independently. Determine whether each is a genuine behavioral loop, an expected market outcome, or an observation requiring more evidence.
>
> 7. Do not launch another full 365-day campaign until the focused repairs and regression tests pass. When ready, propose the next campaign with the exact fixed commit SHA and explain which prior evidence can be reused.
>
> Update KNOWN_ISSUES, CURRENT_STATE, the decision register, and the changelog with root causes, fixes, test evidence, and unresolved risks.
>
> Continue without stopping for routine implementation choices. Escalate only genuine design decisions or blockers.
