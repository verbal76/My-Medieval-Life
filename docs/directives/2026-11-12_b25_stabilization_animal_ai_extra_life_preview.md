# Owner directive 2026-11-12 (received about 20:00 EST): Build 25 — 69-item stabilization, animal behavior and Extra Life preview

Saved verbatim by the lead.

---

MY MEDIEVAL LIFE — BUILD 25 OWNER DIRECTIVE

69-Item Stabilization, Animal Behavior and Extra Life Preview

Development baseline: Chain 12, "b3c9eb5"

1. Development priorities

Build 25 is NOT a Steam release candidate.

The immediate objective is to stabilize the existing playable game for a private Extra Life demonstration.

Do not begin the five untouched expansion packages.

Work through the existing 69-item audit tracker. Do not declare items completed merely because code has been merged.

For each item:

- Confirm the intended behavior.
- Verify the implementation.
- Run appropriate regression tests.
- Investigate unexpected results.
- Record evidence and exact commit SHA.
- Update the existing tracker.

Identify items that require owner decisions. Do not silently choose answers or bypass them.

2. New requirement — Animal hunting AI

Create a tracked requirement and regression coverage for animal reactions to melee attacks.

Current defect:

Animals often turn away from the player, remain in idle movement, and back into the player while being repeatedly struck. This creates an extremely unnatural and visually inappropriate hunting interaction.

Required behavior:

1. Animals interrupt idle behavior when attacked.
2. They orient toward the attacker for an alert, defensive, or startled reaction.
3. Prey animals attempt to escape after reacting.
4. Escape behavior includes controlled direction changes, zigzags, occasional hesitation, and obstacle avoidance.
5. Animals must not repeatedly reverse into the attacking player.
6. Animals should face their movement direction while fleeing.
7. Dangerous animals, particularly bears, must retain appropriate defensive or aggressive behavior.
8. Animals must not become trapped in repeated idle/alert/flee transitions.
9. Hunting with existing melee weapons must remain functional and reasonably achievable.
10. Preserve existing harvesting, loot, death, persistence, and combat systems.

Investigate existing animal AI and movement code before implementing changes. Reuse established systems where possible.

Do not introduce bows or other new weapon systems as part of this fix.

Add deterministic automated tests for reactions, escape decisions, collision avoidance, state transitions, and attack/death behavior.

Include a visual gameplay test because passing AI unit tests alone will not establish that the animations look natural.

3. Extra Life gameplay preview

Prepare a private Windows build suitable for casual gameplay during a charity livestream.

Prioritize:

- Character movement and interaction.
- Tree cutting and resource collection.
- Animal hunting and harvesting.
- Inventory and equipment.
- Basic crafting and professions.
- Village interactions.
- Save/load reliability.
- Stability during extended play.

Test a representative continuous gameplay session and document any remaining defects.

Do not represent the preview as a Steam-ready release.

4. Existing integration and simulation work

Continue the 69-item verification process and the investigation of simulation baseline differences.

Do not activate a replacement baseline without owner approval.

Do not ignore the observed changes in village labor distribution, production, and trade.

Keep the 365-day simulation work separate from the immediate preview validation so long-running simulations do not prevent preparation of a playable build.

5. Reporting

Provide:

- The updated 69-item tracker counts.
- Status of the new animal behavior requirement.
- Remaining blockers and owner decisions.
- Results of gameplay smoke tests.
- Windows preview package status.
- Exact commits and test evidence.

No Steam uploads, public releases, or release-gate bypasses.

A private preview is permitted as a separate test artifact, clearly identified as incomplete.

Focus on repairing and verifying what already exists rather than expanding the game's scope.
