# FINAL ASPIRATIONS DECISIONS (owner directive, WDR-011-C, Build 19 Recovery R5, Expansion 20, 2026-10-27)

Answers WDR-011-Q1 to WDR-011-Q7. Received in the session of 2026-10-27, verbatim:

MY MEDIEVAL LIFE

OWNER DIRECTIVE — FINAL ASPIRATIONS DECISIONS

WDR-011-C | Build 19 Recovery R5 | Expansion 20

I am answering all seven outstanding owner questions concerning NPC aspirations, self-improvement, and prosperity.

These decisions are FINAL for the current implementation.

Record them in the existing requirements register, update the R5 aspirations design document, and close WDR-011-Q1 through Q7.

Do not create duplicate requirements.

The existing design document is:

"docs/expansion20/R5_ASPIRATIONS_DESIGN.md"

The implementation must respect all previous owner-approved Judgment System, family responsibility, simulation, and Living Economy directives.

Q1 — SURVIVAL AND HEALTH: OPTION C

Severe hunger, injuries, and dangerous living conditions must influence all of an NPC's aspirations.

The game already has basic health mechanics, including HP, injuries, hunger, and healing. It does not yet have a comprehensive illness or disease system.

Use existing, measurable conditions.

Do not invent a complete illness system as part of R5.

A villager whose survival is threatened should reassess their ambitions and priorities.

For example:

- A starving craftsman may temporarily prioritize obtaining food over improving professional skills.
- An injured merchant may postpone business expansion.
- A household facing serious danger may redirect resources toward protection and stability.
- After recovery, previously important ambitions may regain influence.

This must be a dynamic, personality-sensitive response rather than a permanent personality change or an automatic cancellation of every other goal.

MANDATORY FAMILY-SACRIFICE SAFEGUARD

Preserve the existing owner-approved family responsibility hierarchy:

1. Children.
2. Spouse.
3. Parents.
4. Self.

This applies to parents and guardians according to the existing family-sacrifice directive.

An NPC's personal survival aspirations must not automatically override responsibility to dependents.

A starving parent may prioritize finding food without selfishly taking food from a hungrier child.

Preserve the existing rules concerning:

- Family responsibility.
- Reasonable personal sacrifice.
- Individual personality.
- Rare exceptional behavior.
- Long-term family survival.
- Avoiding automatic suicidal decisions where staying alive better protects the family.

Do not create a second competing family decision engine.

Survival pressure must feed into the existing decision architecture while preserving the previously approved responsibility ordering.

Q2 — CAREER AMBITIONS: OPTION B

Introduce meaningful career ambitions.

Employment decisions should account for:

- Wages.
- Existing skills.
- Opportunities to improve skills.
- Professional experience.
- Career satisfaction.
- Financial necessity.
- Available employment.
- Personal ambitions.

A skilled blacksmith may prefer to continue developing as a blacksmith instead of changing to a slightly better-paying occupation.

However, financial hardship may still make changing jobs the more attractive option.

Implement the proposed "job_choice" decision profile behind its own integration flag, consistent with the R5 design and existing Judgment System.

Do not create a separate career simulation or hardcode an occupation preference that overrides all other considerations.

Q3 — ROMANTIC PREFERENCES: OPTION C

Romantic preferences must reflect individual personality, values, circumstances, and ambitions.

Different villagers may prioritize different qualities when selecting a romantic partner.

Relevant influences may include:

- Attraction.
- Existing relationships.
- Personal opinions.
- Financial security.
- Wealth and property.
- Household stability.
- Family compatibility.
- Shared ambitions.
- Social standing.

These influences must vary by individual.

One villager may strongly prioritize affection.

Another may place greater importance on stability, financial security, or shared plans for the future.

Another may be willing to overlook significant financial differences because of attraction or an established relationship.

Use the existing Judgment System, personality information, relationship history, and actual world state.

Do not assume every NPC cares equally about wealth.

Do not introduce fixed wealth requirements for marriage or courtship.

Do not replace human-player mutual consent with NPC decision-making.

Preserve existing family, kinship, marriage, and relationship restrictions.

Q4 — PERSEVERANCE: OPTION A

Use the existing stubbornness and wisdom traits.

The previously approved approximate 30% stubbornness distribution remains unchanged.

Stubborn villagers generally persevere longer after setbacks.

Other villagers may adapt or reconsider their ambitions sooner.

Wisdom and experience may influence adaptation.

Repeated setbacks can eventually cause even stubborn villagers to change their objectives.

Do not introduce an additional ambition personality trait merely to reproduce behavior already covered by the existing personality system.

Avoid making every NPC respond identically.

Q5 — NUMERICAL SETTINGS: OPTION A

Approve Claude's proposed numerical settings as PROVISIONAL starting values.

Do not treat these values as permanently balanced.

Use the proposed four-seed measurement process to evaluate:

- Aspiration priorities.
- Satisfaction levels.
- Responses to setbacks.
- Recovery and adaptation.
- Career decisions.
- Relationships.
- Changes in family and household priorities.
- Economic behavior.
- Villager contentment.
- Long-term consequences.

The owner-approved hunger and stubbornness values remain authoritative.

All other provisional values must remain identifiable and adjustable.

Report observed results before recommending changes.

Do not silently alter the established simulation baseline.

Do not perform redundant long simulation campaigns.

Q6 — SOCIAL STANDING: OPTION B

Add SOCIAL STANDING as a sixth aspiration domain.

This intentionally expands World Design Rule 011 from five domains to six.

The six domains are now:

1. Food and security.
2. Money and wealth.
3. Goods and property.
4. Professional growth.
5. Family and household development.
6. Social standing and recognition.

Some villagers should aspire to:

- Earn respect.
- Improve their standing within the village.
- Gain recognition.
- Become more influential.
- Develop a respected reputation.
- Achieve greater community acceptance.

The importance of social standing must vary with personality and circumstances.

IMPORTANT: DO NOT DOUBLE-COUNT REPUTATION

The existing Judgment System already evaluates how individuals feel about one another.

Social standing as an aspiration is different.

The aspiration represents how much an NPC wants recognition, influence, or respect.

The Judgment System represents how other individuals actually judge that NPC.

Design the sixth domain so that the same reputation information is not improperly counted twice in one decision.

Use existing judgment and reputation data where appropriate, but maintain a clear separation between:

- An NPC's social ambitions.
- Their actual standing.
- Other NPCs' individual opinions.
- The influence of those factors on a particular decision.

Do not invent political offices, elections, or social institutions that have not been authorized.

Update the design documentation, aspiration data structures, serialization, reporting, and tests to support six domains instead of five.

Preserve backward-compatible saves and deterministic behavior.

Q7 — VISIBILITY: OPTION B

Villagers should eventually communicate their aspirations through natural dialogue.

Examples:

- "I'm hoping to buy a workshop of my own."
- "I'd like to start a family someday."
- "I want to become a better smith."
- "We've been saving for a bigger home."
- "I'd like the village to think better of me."

The dialogue must reflect the NPC's actual circumstances and current aspirations.

Do not generate statements about goals the villager does not have.

Do not have every villager repeatedly announce their ambitions.

Use the established dialogue, personal perspective, memory, and conversation systems.

Respect what the villager knows and what they are willing to share.

Implement the dialogue integration when the underlying aspiration system is functional and reviewed.

Do not enable unfinished aspiration dialogue prematurely.

IMPLEMENTATION REQUIREMENTS

Update the existing R5 design before coding.

Account for the implications of:

- The sixth aspiration domain.
- Personality-dependent romantic preferences.
- Career-choice weighting.
- Survival pressure across aspiration categories.
- Family-sacrifice priority rules.
- Existing Judgment System integration.
- Save compatibility.
- Simulation performance.

The design must use the existing weighted decision architecture rather than introducing a competing AI engine.

Preserve deterministic simulation and the established recorder requirements.

Add focused tests for all seven owner decisions.

In particular, verify:

- Severe hunger and injury alter priorities appropriately.
- Parents continue protecting children when personally hungry.
- A surviving parent does not sacrifice themselves unnecessarily when their continued survival is important to the family.
- Career ambitions can influence job choices without ignoring economic necessity.
- Romantic preferences genuinely vary among individuals.
- Stubbornness influences perseverance.
- Social-standing aspirations work without double-counting judgment.
- All six aspiration domains persist correctly through save/load.
- Aspirations disabled produce the established baseline.
- Enabling aspirations never creates coins, food, items, or other resources.

Keep the aspiration system behind its existing approved feature controls until validation and owner review.

DEVELOPMENT COORDINATION

Continue Build 19 recovery and Expansion 20 development according to the current workstream schedule.

Respect the existing R2/R4/R5 dependency and shared-file restrictions.

Do not interrupt the multiplayer interaction worker.

MP-INTERACT-01 remains the mandatory final integration and release blocker.

Do not package or publish an Expansion 20 build before that requirement is satisfied.

FINAL INSTRUCTION

Record all seven decisions exactly.

Close the seven owner questions.

Update the R5 design to reflect these choices.

Proceed with implementation when its established dependencies permit.

Do not reopen these decisions or invent additional owner policies.

Report any genuinely new conflict before making an unauthorized design change.
