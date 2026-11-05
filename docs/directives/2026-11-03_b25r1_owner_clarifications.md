# Owner directive, 2026-11-03 (about 14:00 EST): Build 25 Revision 1, owner clarifications

Saved verbatim. Register: B25R1-007, B25R1-002, B25R1-010, B25R1-012.

---

BUILD 25 REVISION 1 — OWNER CLARIFICATIONS

These decisions are approved. Record them in the decision register and incorporate them into the current workstreams.

1. Character customization — no free-form color picker

The existing expanded color palettes are sufficient.

Do not implement a free-form color picker or introduce new save fields solely for one.

Retain the approved body types, cosmetic combinations, animated preview, and save/load compatibility.

2. Wilderness interactions

The owner accepts the reported interaction fixes and focused test evidence.

Keep the final integrated interaction verification and real-device playtest on the release checklist.

3. Homesteading — decision-making audit required

Before implementing NPC homesteading decisions, document exactly how the existing NPC simulation handles major life choices.

Identify:

- Which existing systems influence an NPC's decisions.
- How personal ambitions, occupations, skills, finances, household circumstances, marriage, family relationships, and available housing influence those decisions.
- Whether NPCs already evaluate opportunities in other settlements.
- How adulthood and independent household formation are handled.
- Whether existing personality, judgment, or aspiration systems can support homesteading decisions.
- How the NPC evaluates the costs, benefits, and risks of leaving.
- How settlement population safeguards affect eligibility.
- How a decision becomes an actual sequence of travel, land claiming, construction, and residence changes.

Do not create an isolated random-percentage decision system.

Use the existing NPC judgment and life-decision architecture wherever possible.

The small homesteading percentage is a population-balancing constraint, not a substitute for individual reasoning.

Before committing to a decision-making implementation, provide a concise explanation of the proposed decision process and its integration with existing systems.

Do not pause unrelated development while completing this audit.

4. Gamepad map navigation

Implement gamepad destination selection using the existing controller conventions.

When the regional map is open:

- Activate a visible map cursor.
- Use the D-pad to move the cursor across the map.
- Use the existing Interact/Confirm button to select the cursor's world position as a travel destination.
- Allow selection of any reachable location, not only settlements.
- Provide controller-compatible zoom controls using available, nonconflicting inputs.
- Provide a controller-compatible way to recenter the map on the player.
- Preserve existing Resume Destination and Dismiss Destination controls.
- Make cursor movement and destination selection visually clear.
- Do not allow map controls to move the character underneath the open map.

The controller cursor must select destinations through the same route-planning logic used by touchscreen taps and mouse clicks.

Do not implement separate controller-only travel mechanics.

Test destination selection, movement, zoom, interruption, resumption, and dismissal using controller input.

Execution

Record these decisions, update the relevant worker instructions, and continue the existing Build 25 Revision 1 implementation.

Avoid unrelated changes or redundant test campaigns.
