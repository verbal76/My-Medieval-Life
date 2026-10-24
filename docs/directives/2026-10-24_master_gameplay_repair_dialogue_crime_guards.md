Owner directive, 2026-10-24, verbatim.

# MY MEDIEVAL LIFE — MASTER GAMEPLAY REPAIR DIRECTIVE
## NPC Dialogue, Social Awareness, Crime Response, and Guard AI

### PURPOSE

This directive consolidates three major defects discovered during owner playtesting.

These are not isolated cosmetic problems. They expose weaknesses in how the game's simulation translates events, relationships, crimes, and knowledge into believable NPC behavior.

The objective is to make villagers behave as individuals who actually inhabit the simulated world, recognize their relationships, remember significant events, and respond appropriately to dangerous situations.

**Fix the underlying systems rather than hardcoding solutions for individual screenshots.**

This directive covers:

1. OPEN ITEM 01 — Repetitive, mechanically assembled gossip.
2. OPEN ITEM 02 — NPCs failing to recognize themselves, their families, the player, and their involvement in events.
3. OPEN ITEM 03 — Inadequate criminal consequences, broken guard pursuit, and failure to coordinate law enforcement.

---

# OPEN ITEM 01 — REPETITIVE AND MECHANICAL GOSSIP

## Observed defect

Reginald Lambert, an elder of the Lambert family, reported:

"Have you heard? The Lambert household fenced the farmland south-west of the market. The Lambert household bought the farmland south-west of the market from the manor for 11 coins."

Problems:

- The household name is unnecessarily repeated.
- The property location is repeated.
- Related events are described as disconnected reports.
- The speaker refers to his own household as an unrelated third party.
- The resulting dialogue sounds like database entries concatenated into sentences.

## Required behavior

Dialogue should combine related information naturally while preserving the underlying facts.

When a Lambert family member speaks:

"Our family bought that farmland south-west of the market from the manor for 11 coins. We've already fenced it off."

When an unrelated villager speaks:

"The Lamberts bought some farmland south-west of the market for 11 coins. They've already put up a fence."

These are examples, not mandatory templates.

## Implementation requirements

1. Audit the existing gossip generation pipeline.
2. Identify where redundant wording originates.
3. Determine whether related event records are being concatenated without contextual processing.
4. Consolidate related events when appropriate.
5. Avoid unnecessary repetition of names, households, locations, and actions.
6. Preserve relevant facts, including ownership, price, location, participants, and outcomes.
7. Maintain natural variation without introducing nondeterministic behavior.
8. Apply the correction across all gossip categories, not just property transactions.

Do not solve this by changing one Lambert dialogue string.

---

# OPEN ITEM 02 — NPC IDENTITY, FAMILY, LISTENER, AND EVENT AWARENESS

## Case A — NPC fails to recognize the player as the perpetrator

The player character, Maud Berbal, killed Rose Dale, a child from the Dale family.

Nicholas Dale, an elder of that family, reportedly witnessed the killing.

Nicholas subsequently told the player:

"People are talking. Rose Dale the child has died (slain by Maud Berbal). Maud Berbal attacked Rose Dale."

This is fundamentally incorrect.

Nicholas is speaking directly to the person responsible for killing his relative, yet describes the perpetrator in the third person.

He also presents the event as ordinary gossip despite reportedly witnessing it.

Furthermore, the attack and death are described redundantly.

### Required behavior

If Nicholas witnessed the killing and identified the player:

"You killed Rose! I saw you do it!"

If Nicholas only heard about the killing:

"They say you killed Rose. Is it true?"

If Nicholas does not know the perpetrator's identity, he must not magically identify them.

If Nicholas is frightened, his reaction might be fearful, evasive, or restrained rather than openly confrontational.

**Responses must depend on actual knowledge, relationships, personality, fear, and existing opinions.**

Do not force every NPC to respond aggressively.

## Case B — NPC fails to recognize their own family

An Oakley child told the player that the church had provided food to the Oakley family because the mother lacked an axe.

The child belongs to that household.

The player had also personally given the mother bread and observed her enthusiastic response.

The child nevertheless described the Oakley family's circumstances as though reporting news about unrelated villagers.

### Required behavior

An appropriate statement might be:

"The church brought us some food. Mum hasn't got an axe, so things have been difficult."

If the child knows about the player's gift:

"Mum was so happy when you brought us that bread. Thank you."

However, household membership alone must not provide automatic knowledge of every event.

The child should only acknowledge the gift if the event was witnessed, communicated, or learned through an existing knowledge-sharing mechanism.

## Required perspective awareness

Every dialogue involving an event must evaluate:

1. Speaker identity.
2. Listener identity.
3. Event participants.
4. Victims and beneficiaries.
5. Witnesses.
6. Household and family relationships.
7. Speaker involvement.
8. Listener involvement.
9. Actual event knowledge.
10. How that knowledge was obtained.
11. Previous conversations about the event.
12. Existing opinion, fear, trust, and personal significance.

### Perspective examples

| Relationship | Appropriate phrasing |
|---|---|
| Speaker performed the action | "I..." |
| Speaker's household performed the action | "We..." |
| Speaker's mother was involved | "My mother..." or "Mum..." |
| Listener performed the action | "You..." |
| Speaker witnessed the event | "I saw..." |
| Speaker learned about the event indirectly | "I heard..." |
| Unrelated participant | Appropriate name or third-person reference |

These are general perspective rules, not rigid dialogue scripts.

## Emotional and social significance

NPCs must distinguish ordinary village news from personally significant events.

Examples include:

- Death or injury of relatives.
- Murder, assault, and theft.
- Assistance received from another character.
- Household hunger and hardship.
- Property ownership changes.
- Marriage and family events.
- Employment and contracts.
- Business transactions.
- Events directly witnessed by the speaker.

An NPC who witnessed the player murder a relative should not casually default to generic village gossip.

However, fear, self-preservation, dependence, and existing relationships may affect whether the NPC confronts the player.

## Knowledge integrity

Distinguish between:

- Direct witnesses.
- Participants.
- Victims.
- Household members who learned about an event.
- Villagers who heard rumors.
- Villagers with incomplete information.
- Villagers unaware of the event.

Investigate whether the witness record for Nicholas Dale was actually created.

If witnessing worked correctly, repair the dialogue interpretation.

If witnessing failed, repair the witness-recording mechanism.

Do not compensate for missing information by making NPCs omniscient.

## Conversation priorities

Review whether the dialogue selection system appropriately prioritizes:

1. Immediate events involving the speaker and listener.
2. Serious incidents affecting the speaker's household.
3. Recent personal interactions with the listener.
4. Significant household developments.
5. Ordinary village gossip.

Prevent repeated emotional dialogue from becoming an endless loop.

Use the existing event memory and conversation history where possible.

---

# OPEN ITEM 03 — CRIME RESPONSE, GUARD PURSUIT, AND COORDINATED MANHUNTS

## Observed defect

During owner playtesting, the player murdered three children.

A single guard began pursuing the player.

After the player turned one corner and broke line of sight, the guard abandoned the pursuit and returned to normal behavior.

No effective coordinated response was observed.

This is unacceptable for the severity of the crime.

**Three murders should trigger a major law-enforcement response, not a brief chase that ends when the player rounds a building.**

## Required design outcome

Serious criminal acts must have meaningful, persistent, and proportionate consequences.

Multiple murders should mobilize available guards, alarm the settlement, trigger a coordinated search, and create an ongoing threat to the perpetrator.

For a known, actively violent multiple murderer, guards should be willing to use lethal force when appropriate.

The player may still escape through skill, stealth, deception, or distance, but should not escape merely by breaking line of sight for a moment.

## A. Crime severity classification

Audit the existing crime categories and enforcement responses.

Use or extend the current system rather than creating an unrelated second crime ledger.

Suggested response framework:

| Crime | Expected response |
|---|---|
| Minor theft | Warning, investigation, fine, restitution, or arrest |
| Repeated theft | Stronger investigation and possible active pursuit |
| Assault | Guards respond, intervene, and pursue when appropriate |
| Murder | Multiple guards alerted, persistent pursuit, serious consequences |
| Multiple murders | Settlement-wide alarm, coordinated manhunt, high-threat response |
| Attacking guards | Immediate escalation and reinforcement |
| Continued violence during pursuit | Escalating force and additional responders |

These are design targets. Reconcile them with the game's existing crime and justice systems before implementation.

## B. Guard pursuit must survive loss of line of sight

Implement or repair a coherent pursuit state machine.

Suggested states:

1. **Patrol:** Normal guard behavior.
2. **Alerted:** Crime witnessed or credible alarm received.
3. **Responding:** Moving toward the reported incident.
4. **Pursuing:** Suspect is identified and actively tracked.
5. **Searching:** Suspect is temporarily out of sight.
6. **Coordinating:** Sharing last-known location and requesting assistance.
7. **Confronting:** Attempting arrest, surrender demand, or combat as appropriate.
8. **Resolved:** Suspect captured, killed, escaped after a meaningful search, or case transferred into an ongoing wanted status.

A guard must not immediately return to ordinary patrol simply because the player turns a corner.

On losing sight, the guard should:

- Remember the suspect's last known position.
- Move toward that location.
- Search plausible nearby paths.
- Investigate nearby hiding places when supported by the environment.
- Communicate useful sightings to other guards.
- Resume direct pursuit if the suspect is found.
- End the immediate search only under defensible conditions.

Do not give guards magical knowledge of the player's position.

## C. Coordinated guard response

A major crime should not automatically be handled by one guard acting alone.

Implement appropriate reinforcement and coordination.

For multiple murders:

- Nearby guards respond immediately when aware.
- Additional guards are alerted through supported communication mechanisms.
- Guards share suspect identity and last-known location when that information is available.
- Multiple responders attempt to search or intercept the suspect.
- Guards avoid abandoning the incident simply because another guard is already pursuing.
- Available guards are mobilized according to actual settlement resources.

Do not spawn guards from nowhere merely to increase difficulty.

Use existing guard populations, schedules, locations, and movement systems.

If the settlement has limited manpower, the response should reflect that limitation while still treating the crime seriously.

## D. Persistent wanted status

A known murderer should not become an ordinary citizen again when an immediate chase ends.

Review or implement persistent criminal status using the existing justice and crime architecture.

Track, as appropriate:

- Known suspect identity.
- Crimes committed.
- Crime severity.
- Witness and evidence information.
- Whether authorities know the perpetrator.
- Current enforcement priority.
- Last-known location.
- Outstanding warrants or wanted status.
- Whether the suspect has been captured, punished, pardoned, or otherwise resolved.

A wanted status should survive:

- Temporary loss of line of sight.
- Leaving the immediate crime scene.
- Changing areas.
- Saving and loading.
- Reentering the settlement.

Do not create permanent omniscient tracking.

The authorities should remember the suspect without automatically knowing their location.

## E. Proportionate force and player survival

For minor offenses, guards should not automatically attempt lethal combat.

For serious violent crimes, guards should be substantially more dangerous.

A player who murders multiple children and continues resisting should face the realistic possibility of being killed by responding guards.

However, this should emerge from combat, pursuit, reinforcement, and the existing justice rules rather than a scripted unavoidable death.

Preserve player agency.

Possible outcomes should include:

- Escape.
- Arrest.
- Surrender.
- Combat.
- Death.
- Continued fugitive status.

Use only outcomes supported by the game's current design or identify required extensions before implementing them.

## F. NPC and household responses

A major crime should affect more than the guard directly observing it.

Relevant villagers may:

- Flee from immediate danger.
- Seek shelter.
- Alert nearby guards.
- Warn other villagers.
- Refuse assistance or trade.
- Express fear or anger.
- Remember the crime.
- Spread information about the perpetrator.
- Respond differently based on their relationship to the victim or offender.

Use the existing morality and relationship framework.

A victim's family should generally respond more strongly than an unrelated household, subject to individual relationships and knowledge.

The existing Good/Bad event ledgers and opinion weights must remain authoritative.

Do not replace the owner's established morality design with a simplified universal hostility score.

## G. Pathfinding and pursuit reliability

Investigate whether the guard abandoning pursuit was caused by:

- Line-of-sight loss.
- Pursuit timeout.
- Pathfinding failure.
- Navigation around buildings.
- Target memory being cleared.
- AI state transitions.
- Guard schedule overrides.
- Combat disengagement rules.
- Missing reinforcement logic.

Identify the actual cause.

Fix navigation and state management as needed.

Do not simply increase guard movement speed, detection radius, or chase duration and call the problem solved.

## H. Performance and simulation constraints

This is a persistent village simulation, potentially involving hundreds of NPCs.

Guard coordination must remain efficient.

Use event-driven alerts, bounded searches, and appropriate scheduling.

Avoid scanning every NPC and every crime every frame.

Preserve determinism and existing simulation performance targets.

---

# SHARED ARCHITECTURAL REQUIREMENTS

All three open items must integrate with the existing systems.

Relevant systems include:

- NPC identity.
- Player identity.
- Household and family membership.
- Event history.
- Witnessing.
- Knowledge propagation.
- Gossip.
- Relationships.
- Good/Bad morality ledgers.
- Crime and justice.
- NPC decision-making.
- Navigation and combat.
- Save/load.
- Multiplayer player identity.

## Non-negotiable constraints

1. Audit before modifying.
2. Fix root causes rather than individual examples.
3. Preserve existing save compatibility.
4. Preserve the established morality and reputation framework.
5. Do not create parallel or conflicting systems.
6. Keep the simulation deterministic and table-driven.
7. Do not introduce runtime LLMs.
8. Do not hardcode the Lambert, Dale, Oakley, or Berbal families.
9. Support procedurally generated villagers and households.
10. Ensure multiplayer conversations and criminal responsibility identify the correct individual player.
11. Do not break single-player behavior.
12. Do not introduce substantial performance regressions.
13. Do not alter unrelated economic balances or game mechanics.

---

# REQUIRED AUTOMATED VERIFICATION

## Dialogue and gossip tests

Test:

- Speaker discusses their own actions.
- Speaker discusses their household's actions.
- Child discusses their parent's circumstances.
- Speaker addresses the player responsible for an event.
- Speaker distinguishes witnessed facts from rumors.
- Speaker discusses the death of a relative.
- Speaker acknowledges assistance when actually informed.
- Speaker does not know about assistance they never learned of.
- Related events are consolidated without duplication.
- Important conversations take priority over generic gossip.
- Previously discussed events do not endlessly repeat.
- Different players receive correctly personalized dialogue.

## Crime and pursuit tests

Test:

- Minor theft triggers proportionate enforcement.
- Assault triggers appropriate guard intervention.
- Murder triggers a serious response.
- Multiple murders escalate the response.
- Available guards coordinate when alerted.
- Guards do not automatically know unwitnessed crimes.
- Guards remember an identified suspect after losing sight.
- Turning one corner does not terminate pursuit.
- Guards search last-known locations.
- Guards reacquire suspects when sight is restored.
- Guards navigate around buildings without silently abandoning pursuit.
- Attacking a guard escalates enforcement.
- Violent resistance permits appropriate lethal force.
- Surrender or arrest transitions resolve correctly where implemented.
- Wanted status persists through save/load.
- Authorities remember a suspect without magically tracking them.
- Multiplayer crimes are attributed to the correct player.
- Guard coordination stays within performance budgets.

## Regression gates

Preserve:

- Single-player determinism.
- Existing event and morality integrity.
- Save/load compatibility.
- Population and economic integrity.
- Multiplayer foundation.
- Android, Windows, and Linux functionality.

Add targeted regression tests that reproduce the reported failures before the repair and pass afterward.

---

# IMPLEMENTATION AND BUILD POLICY

This directive is a consolidated gameplay repair request.

It is not permission to destabilize an already approved release.

## Build 20 protection

First establish whether Build 20 has been frozen, built, or released.

If Build 20 is already frozen or in release validation, do not modify its source to accommodate this directive.

If Build 20 is still under development, evaluate whether any small, independently testable corrections can be included safely.

Do not hold Build 20 for a large dialogue or law-enforcement architecture rewrite.

Schedule substantial changes into the next appropriate development checkpoint.

Do not interrupt approved multiplayer work without identifying the impact and dependencies.

## Platform and release policy

Every authorized release must produce:

- Android APK.
- Windows playable ZIP.
- Linux playable ZIP.

All three artifacts must come from the same verified source commit and use the same build number.

Preserve private draft release status unless the owner explicitly authorizes publication.

The disposable Android signing exception applies to Build 20 only.

Subsequent builds must follow the established permanent-signing policy unless the owner authorizes another exception.

Do not make owner playtesting a prerequisite for continued development.

---

# REQUIRED EXECUTION AND REPORTING

## Phase 1 — Root-cause audit

Identify:

1. Where gossip is selected, combined, and rendered.
2. How speaker and listener identities are passed into dialogue.
3. How household relationships are accessed.
4. How event witnesses and knowledge are recorded.
5. Why NPCs describe their own families and the player in the third person.
6. Why personally significant events are presented as casual gossip.
7. How crime severity is calculated.
8. How guard pursuit states are managed.
9. Why guards disengage when the player rounds a corner.
10. How guards currently communicate or request reinforcements.
11. Whether wanted status persists.
12. Which existing systems can be reused.

## Phase 2 — Repair plan

Provide a concise implementation plan that identifies:

- Root causes.
- Required changes.
- Reused systems.
- Dependencies.
- Risks to multiplayer and determinism.
- Tests required.
- Recommended implementation order.

Do not reopen established design decisions unless a genuine conflict exists.

## Phase 3 — Implementation

Proceed with corrections within the approved development workflow.

Prioritize coherent system-level fixes over cosmetic patches.

Do not create unnecessary parallel agents or duplicate work.

## Phase 4 — Verification

Run targeted reproduction tests and the relevant regression suites.

Report actual results, including any failures or remaining limitations.

## Phase 5 — Handoff

Provide:

- Completed corrections.
- Relevant commits.
- Tests and results.
- Remaining open issues.
- Whether each issue is included in a release or remains on a development branch.
- Recommended next checkpoint.

---

# FINAL DESIGN INTENT

My Medieval Life is intended to be a living, reactive medieval simulation.

The world must not merely record events. Its inhabitants must behave as though those events actually happened.

A child should recognize news about their own family.

A villager should recognize the person standing in front of them.

A witness should distinguish what they saw from what they heard.

A grieving family member should not casually recite the murder of their relative as ordinary gossip.

And a player who murders three children should not escape justice because one guard lost sight of them around a corner.

**The village must remember, react, coordinate, and respond according to its existing social and simulation rules.**

Build these corrections as coherent, reusable systems that remain believable across procedurally generated characters, households, events, and future multiplayer gameplay.
