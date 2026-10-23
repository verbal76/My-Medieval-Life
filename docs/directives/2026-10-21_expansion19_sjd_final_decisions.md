# Owner directive, 2026-10-21: Expansion 19 Master Owner Directive — Final SJD Decisions, Universal Judgment Integration, Gossip and Performance

Saved verbatim from the owner's message (CLAUDE.md section 9a).

---

MY MEDIEVAL LIFE — EXPANSION 19 MASTER OWNER DIRECTIVE

Final SJD Decisions, Universal Judgment Integration, Gossip and Performance

Repository: verbal76/My-Medieval-Life
Development branch: wip/expansion19-preparation
Last reported Expansion 19 HEAD: 6615da4
Date: October 21, 2026

1. OWNER AUTHORIZATION

I am formally answering all eight outstanding SJD owner questions:

SJD-Q01, Q02, Q06, Q07, Q08, Q10, Q11, and Q14.

Record these as owner-approved design decisions in the authoritative Expansion 19 documentation and decision register.

The judgment engine is intended to be a universal influence on NPC decision-making.

It must not replace the existing decision systems, override physical or economic constraints, or become the sole determining factor in NPC behavior.

An NPC's judgment influences a decision. It does not dictate that decision.

Expansion 19 remains on its isolated development branch. This directive authorizes continued development and integration preparation, not an immediate merge into Build 17 or a public release.

---

2. SJD-Q01 — FACTUAL EVENTS AND NEUTRAL INTERPRETATIONS

OWNER DECISION: APPROVED.

An event is a fact. Its moral impact depends on how the individual observer interprets it.

An observer may assign a positive, negative, or zero contribution.

Zero means the event has no meaningful moral effect on that observer.

For example, a marriage may mean nothing morally to an unrelated villager, be positive to a close friend, or be interpreted negatively by someone personally affected.

Do not require every recorded fact to generate a nonzero GOOD or BAD contribution.

Keep the existing GOOD and BAD ledgers.

A zero contribution does not require a third moral ledger.

Factual information may still be remembered, discussed, and used by other systems even when it contributes no moral points.

Preserve the distinction between what happened, what someone believes happened, and how that person interprets it.

Do not automatically assign moral significance to ordinary factual events.

---

3. SJD-Q02 — MORAL JUDGMENT DECAY

OWNER DECISION: APPROVED.

Ordinary GOOD and BAD judgments fade very slowly over time.

This fading should represent the gradual weakening of an old opinion rather than an immediate reset when an event's details are forgotten.

Murder is a permanent exception.

A moral contribution associated with murder must never decay.

The permanent rule applies to judgments of both players and NPCs.

Do not use a blanket decay calculation that inadvertently reduces murder-related contributions.

Preserve individual contributions or equivalent provenance so permanent and fading judgments can coexist within the same ledger.

The exact numerical decay rate is not specified by this decision. Propose a conservative configurable value and demonstrate its long-term effects before treating it as an approved balance setting.

Do not silently choose a permanent decay rate.

---

4. SJD-Q06 — BELIEF CONFIDENCE AND TRUST

OWNER DECISION: APPROVED.

A listener's confidence in information received from another character depends on how much that listener trusts the person telling the story.

The existing friendship or relationship number must influence the confidence percentage.

A closer, more trusted friend generally has greater credibility than a stranger.

The system must distinguish firsthand knowledge from secondhand information.

A witness who directly observes an event does not need to evaluate the credibility of a separate storyteller.

For secondhand information, use the listener's trust in the immediate storyteller as a major confidence input.

Preserve the source and provenance of the information.

When information passes through multiple people, the resulting confidence should reflect the transmission history and the trust relationships involved.

Do not automatically treat a rumor as established fact.

Do not award the same event's moral contribution repeatedly merely because the listener hears the story again.

If new information changes confidence, update the existing belief and corresponding contribution rather than creating duplicate judgments.

Do not invent an unrelated second friendship system.

Reuse the existing social relationship data.

---

5. SJD-Q07 — GOSSIP REACH AND PHYSICAL INFORMATION SPREAD

OWNER DECISION: APPROVED.

Remove the fixed maximum number of retellings.

A story may pass through any number of people if actual social interactions allow it.

Information spreads through real conversations and encounters, not through automatic village-wide knowledge.

A villager must have an opportunity to communicate with another villager before information can pass between them.

Confidence depends on trust and the information's provenance.

The same story can travel across the entire village over time, but it must follow actual communication paths.

Do not create artificial instant broadcasts.

Do not introduce information teleportation.

Reasonable configurable limits on how much information can be exchanged during a conversation may remain for simulation and performance purposes.

However, these limits must not impose an arbitrary maximum number of people through whom a story can travel.

Maintain deterministic event ordering and save/load integrity.

The removal of the hop limit must not permit infinite loops, duplicate contributions, or unlimited repeated processing of the same event.

Use event identity, provenance, and deduplication to prevent those failures.

---

6. SJD-Q08 — PERSONAL MORALITY, RELATIONSHIPS AND LAW

OWNER DECISION: APPROVED.

An NPC's interpretation of an event depends on personal morality, relationships, loyalties, and the people affected.

Different observers may assign different moral contributions to the same event.

Friendship and family loyalty can soften condemnation.

Relationships with victims or beneficiaries can strengthen or reverse an observer's interpretation.

Personal morality may also influence the response.

The legal system is separate from personal moral judgment.

An NPC can personally sympathize with someone who committed a crime.

A guard can personally like someone while still enforcing the law.

Likewise, an action being legal does not automatically mean every villager considers it morally good.

Do not make legal status the sole determinant of GOOD or BAD.

Preserve existing crime reporting and guard enforcement unless separately authorized changes are required.

Do not create a second legal system inside the judgment engine.

---

7. SJD-Q10 — PLAYER-FACING JUDGMENT INFORMATION

OWNER DECISION: APPROVED.

The player must not see exact judgment numbers during normal gameplay.

Do not display numerical GOOD points, BAD points, net judgment scores, confidence percentages, or internal decision weights in ordinary character interactions.

Instead, communicate attitudes through natural gameplay:

- Dialogue and conversational responses.
- Willingness or refusal to trade.
- Prices and negotiated terms.
- Willingness to help or cooperate.
- Friendship and courtship behavior.
- Employment and business interactions.
- Reactions to witnessed or reported events.
- Other existing NPC behavior where judgment is relevant.

The player should be able to infer how people feel without having access to their internal mathematical calculations.

Exact numbers, provenance, and decision explanations should remain accessible through developer diagnostics and testing tools.

Do not remove the inspection functionality needed to investigate simulation behavior.

---

8. SJD-Q11 — PERMANENT MEMORIES

OWNER DECISION: APPROVED.

Memories of murder are permanent.

Other exceptionally significant events may also qualify as permanent memories based on their severity and personal significance.

Ordinary memories may gradually lose salience and eventually be forgotten.

Memory permanence and moral judgment permanence are related but distinct concepts.

A permanent memory does not automatically mean every moral consequence must remain permanently unchanged.

Murder is explicitly permanent in both respects.

For other significant events, the criteria for permanent retention must be configurable and based on the established event and observer framework.

Do not arbitrarily classify every serious disagreement or ordinary offense as permanently unforgettable.

Do not impose the existing ordinary-memory expiration horizon on permanent memories.

Ensure save/load, memory compaction, and long-term simulation do not erase permanent records.

Keep memory usage bounded for ordinary events.

---

9. SJD-Q14 — UNIVERSAL DECISION INTEGRATION

OWNER DECISION: APPROVED.

The judgment system is intended to influence every applicable NPC decision in which personal opinion of another character could reasonably matter.

This includes, where supported by existing game mechanics:

- Buying and selling.
- Negotiated contracts.
- Employment and hiring.
- Cooperation and assistance.
- Friendship and social interaction.
- Courtship and marriage.
- Business relationships.
- Requests for favors.
- Trust-based interactions.
- Other interpersonal choices.

Do not limit judgment permanently to the current trade prototype.

However, do not rewrite all NPC decision systems into a new monolithic judgment engine.

The existing decision authority remains responsible for selecting actions.

Judgment supplies a weighted influence on those decisions.

Need, scarcity, money, available inventory, skills, available time, obligations, safety, relationships, and economic opportunities must remain relevant.

A villager who dislikes someone may still trade with that person if the need is sufficiently important.

A villager who likes someone must not agree to an impossible transaction.

Judgment must never override feasibility or resource conservation.

Integration method

Integrate the judgment influence into applicable existing decision points in controlled, reviewable stages.

Use shared weighting and evaluation interfaces rather than duplicating judgment calculations in every subsystem.

Preserve deterministic behavior.

Test the decisions where judgment actually changes the outcome, as well as cases where other factors correctly outweigh it.

Document unsupported decision domains and the dependencies required before they can use judgment.

Do not invent entire new gameplay systems solely to satisfy this integration requirement.

---

10. GOSSIP PERFORMANCE AND X19-Q-TIMING

The completed third gossip-performance round is accepted as valid development progress.

The current spread implementation preserves the same results as the original hourly processing and should remain the default for now.

Do not activate the scheduled timing alternative without a separate owner decision.

The reported performance figures are estimates based on a development machine and an assumed fourfold phone slowdown.

They are not actual measurements from the owner's Android device.

Preserve the current deterministic, result-equivalent spread implementation while preparing for real-device profiling.

The current 99th-percentile performance achievement is acceptable for continued development.

Do not claim the 99.9th-percentile target has been met.

Do not continue speculative optimization rounds solely to chase that target without new evidence.

The owner will evaluate real-device performance during playtesting.

---

11. PERFORMANCE AND INTEGRITY REQUIREMENTS

Maintain the simulation's core invariants:

- No currency created or destroyed outside authorized economic sources and sinks.
- No items duplicated or lost.
- No fabricated knowledge.
- No repeated moral scoring for the same belief event.
- No nondeterministic behavior introduced by processing order.
- No unauthorized changes to unrelated random-number streams.
- No unnecessary simulation slowdown when judgment is disabled.
- No loss of permanent memories through normal expiration.
- No cross-branch contamination of Build 17, Expansion 18, or experimental FARM systems.

At 500 villagers, continue monitoring frame-time percentiles, memory use, save size, and decision-processing overhead.

Reuse existing passing test evidence when the tested source and requirements are unchanged.

For modified systems, run focused regression tests that prove the affected behavior.

Broader integration testing should be performed when changes genuinely invalidate previous evidence or an integration gate requires it.

Do not repeat full test campaigns without a technical reason.

---

12. DOCUMENTATION AND REMAINING WORK

Update the authoritative Expansion 19 decision register and design documentation.

Mark the following questions as owner answered:

- SJD-Q01
- SJD-Q02
- SJD-Q06
- SJD-Q07
- SJD-Q08
- SJD-Q10
- SJD-Q11
- SJD-Q14

Do not mark a feature as implemented simply because its design has been approved.

Reconcile the approved rules with the existing provisional settings in "game/data/judgment.json".

Identify which changes require code modifications, which are configuration-only, and which require integration into existing NPC decision systems.

Preserve the existing decisions for Q03, Q04, Q05, Q09, Q12, and Q13 as provisional where they have not been separately approved.

Keep X19-Q-TIMING pending, with the current spread mode retained.

Continue Expansion 19 development on its isolated branch.

Do not merge or release without authorization.

---

13. REQUIRED RESPONSE

After recording these decisions, report:

1. The eight owner decisions recorded.
2. Exact files and documentation updated.
3. Current pushed branch HEAD.
4. Which approved behaviors are already implemented.
5. Which require additional development.
6. The universal integration plan and its remaining work.
7. Any conflicts between the new decisions and existing mechanics.
8. Performance and integrity evidence that remains valid.
9. Any genuinely unresolved owner decisions that prevent further progress.

Do not reopen the eight approved design questions unless an actual contradiction or missing requirement is discovered.

Do not substitute agent-created gameplay policy for an owner decision.

A VILLAGE IS ALLOWED TO FAIL. THE SIMULATION IS NOT.
