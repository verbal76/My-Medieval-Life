# Owner directive 2026-10-31: SJD-H decisions (C1-C6), LE-05 authorization and continued development

Verbatim, as received in the coordinating session on 2026-10-31.

---

MY MEDIEVAL LIFE — EXPANSION 20

SJD-H DECISIONS, LE-05 AUTHORIZATION, AND CONTINUED DEVELOPMENT

This message provides the owner's decisions on the remaining Expansion 20 questions.

The previous directive concerning bandit intelligence, survival, pursuit, defensive cooperation, tactical aggression, and retaliation remains fully approved and takes precedence on those subjects.

Do not reopen those decisions.

All work must remain on the Expansion 20 development branch. The economy must remain disabled by default, Build 24 must remain untouched, and no public or private release is authorized at this stage.

---

C1 — JUDGMENT INFLUENCE ON BEHAVIOR

DECISION: Strengthen the integration and effectiveness of judgment, but do not artificially force decisions.

The reported 0.3% difference in sales is not necessarily a problem by itself.

An NPC who dislikes someone may still need their goods, services, or assistance.

However, the Social Judgment and Decision system was designed to influence virtually every meaningful NPC decision.

It must not become a passive reputation database.

Requirements

1. Audit judgment integration across all existing decision systems.
2. Identify where judgment is considered, where it changes decisions, and where it should participate but currently does not.
3. Distinguish between judgment influencing a decision and judgment reversing its outcome.
4. Preserve practical motivations, including survival, economics, relationships, obligations, fear, personal needs, and opportunity.
5. Do not artificially increase wrongdoing penalties merely to produce more refusals.
6. Adjust behavioral weighting where testing demonstrates that legitimate judgment considerations are being ignored.
7. Both positive and negative judgment must influence decisions where appropriate.

An NPC with a strongly negative opinion of a merchant may still purchase desperately needed iron from that merchant if no alternatives exist.

However, given two reasonably comparable merchants, that same NPC should have a meaningful tendency to favor the one they trust.

The system must support these distinctions naturally.

Authorization: Audit, correct missing integration, and calibrate the system. Do not impose an arbitrary target percentage of changed decisions.

---

C2 — MEMORY RETENTION AND SAVE GROWTH

DECISION: APPROVED WITH CONDITIONS.

Allow secondhand memories of assaults and lesser offenses to fade over time.

However, separate the underlying memory from the opinion formed because of that memory.

Requirements

- Firsthand experiences should generally carry greater weight than secondhand information.
- Secondhand information should lose detail and relevance over time according to existing memory rules.
- Opinions formed from remembered events may persist after the detailed memory fades.
- Those opinions must remain subject to the existing judgment and reputation decay systems.
- Repeated offenses, reinforcement, and new information may strengthen or refresh an opinion.
- Killing must remain permanently remembered under the established rules.
- Personally significant experiences, particularly events involving family members, should receive appropriate importance.
- Do not create artificial permanent hostility from ordinary offenses.
- Preserve compatibility with existing saves.

Do not delete the social consequences of an event merely because its detailed secondhand memory expires.

The objective is realistic memory behavior while preventing unnecessary long-term save growth.

---

C3 — REPEATED WRONGDOING AND INCIDENT COUNTING

DECISION: APPROVED WITH MODIFICATION.

Count wrongdoing according to meaningful incidents rather than blindly counting every individual animation, attack, or interaction.

Requirements

1. A continuous fight should be understood as one incident containing potentially multiple meaningful actions.
2. Repeated blows within that fight should not automatically create unrelated assault incidents.
3. The seriousness of the incident must still reflect what actually occurred.
4. Injuries, attempted murder, actual murder, threats, robbery, and other distinguishable wrongdoing must retain their appropriate significance.
5. Multiple victims must remain identifiable.
6. A robbery that successfully takes nothing is not a completed theft.
7. However, attempting to rob someone is still meaningful wrongdoing.
8. Threatening someone, attacking them, or attempting to steal from them must not become consequence-free simply because the theft failed.
9. Separate encounters after a genuine disengagement may constitute separate incidents.

Do not allow incident grouping to erase genuinely different offenses.

Likewise, do not allow one fight containing twenty attack animations to inflate judgment as though twenty unrelated assaults occurred.

Use existing event and judgment infrastructure wherever possible.

---

C4 — EXTREME BANDIT MORTALITY

DECISION: COVERED BY THE PREVIOUS BANDIT DIRECTIVE.

The previous instructions remain fully authorized.

Do not artificially lower bandit mortality simply because villagers are successfully defending themselves or pursuing dangerous criminals.

Bandits must intelligently recognize danger, defend themselves, cooperate, retreat, regroup, and make tactical decisions based on their circumstances.

Villagers must retain their ability to organize and retaliate.

Investigate the reported mortality difference and determine whether it represents legitimate emergent behavior or deficient bandit survival intelligence.

Do not impose an arbitrary numerical mortality target.

Follow the previously supplied instructions for investigation, implementation, and validation.

---

C5 — MIXED FEELINGS AND CONFLICTING MOTIVATIONS

DECISION: IMPLEMENT THE MISSING BEHAVIOR. DO NOT LEAVE IT COSMETIC.

Mixed feelings were deliberately included in our original judgment design.

They must influence actual decisions.

An NPC must be capable of simultaneously:

- Disliking another individual.
- Respecting that individual's abilities.
- Fearing their strength.
- Depending on their products or services.
- Feeling loyalty through family or friendship.
- Remembering previous assistance or wrongdoing.

These considerations must compete within the established decision-making framework.

Example

An NPC strongly dislikes a blacksmith because the blacksmith previously assaulted his brother.

However, the blacksmith is the only nearby source of a tool the NPC desperately needs.

The NPC may decide to trade despite the hostility.

Alternatively, the NPC might pay more to obtain the tool elsewhere, delay the purchase, ask someone else to negotiate, or abandon the transaction.

The choice must emerge from the circumstances and individual motivations.

Requirements

1. Integrate conflicting considerations into existing decision evaluation.
2. Preserve the distinction between judgment, relationships, needs, and personal motivations.
3. Do not collapse every opinion into one universal relationship score.
4. Avoid deterministic rules such as automatically refusing to deal with disliked individuals.
5. Maintain behavioral variety consistent with personality and circumstances.
6. Use existing systems rather than introducing a separate incompatible decision architecture.
7. Validate that mixed feelings actually influence outcomes where meaningful alternatives exist.

The objective is believable individual decision-making.

---

C6 — JUDGMENT DECAY

DECISION: CONFIRMED AND APPROVED.

The previously approved decay behavior remains unchanged.

Preserve the existing rules.

Ensure the memory changes authorized under C2 interact correctly with reputation and judgment decay.

Do not reopen this decision unless a demonstrable defect or contradiction is discovered.

---

LE-05 — TOOL REPAIR AND RENTAL

DECISION: APPROVED FOR DEVELOPMENT.

Implement tool repair and rental using the existing inventory, durability, crafting, and transaction infrastructure.

The following distinctions are important.

A. TOOL REPAIR

APPROVED FOR BOTH NORMAL GAMEPLAY AND LIVING ECONOMY GAMEPLAY.

Basic tool repair is a normal gameplay mechanic and must not depend on the Living Economy switch.

Players and eligible NPC smiths should be able to repair tools at an appropriate anvil.

Requirements

1. Repairs consume appropriate materials derived from the tool's original forging requirements.
2. Material consumption should scale reasonably with the amount of wear being repaired.
3. Repairs require appropriate labor time.
4. Repairs must never create resources, equipment, or economic value from nothing.
5. Repairing a tool should restore durability according to existing equipment rules.
6. The player's repair ability must respect applicable crafting or smithing requirements.
7. NPC smiths must follow appropriate skill and capability restrictions.
8. A repair must preserve the tool's identity, ownership, and other relevant properties.
9. Partial wear, heavily damaged tools, and nearly destroyed tools must be handled consistently.
10. Existing saves and tools must remain compatible.

Do not invent arbitrary permanent durability penalties or new equipment quality tiers without discussing them first.

Use reasonable, deterministic rules for rounding material requirements and handling small repairs. Prevent exploits involving repeated tiny repairs.

When the Living Economy is disabled, basic repair must remain functional.

Paid commercial repair services and their associated financial transactions may depend on the economy system.

---

B. TOOL RENTAL

APPROVED BEHIND THE LIVING ECONOMY SWITCH.

NPC workers who need tools they do not own should be able to consider renting them.

Rental must represent a real economic transaction.

Requirements

1. A rental requires an available tool and a willing owner.
2. The renter must have sufficient resources to satisfy the rental agreement.
3. The deposit is based on the tool's value.
4. Rental fees reflect the economic value of durability consumed through use.
5. Deposits must be held and settled through the established transaction infrastructure.
6. Tool ownership must remain identifiable throughout the rental.
7. Tool wear must follow the actual tool.
8. Returning a tool must correctly reconcile its wear, applicable fees, and deposit.
9. Lost, stolen, destroyed, inherited, transferred, or unreturned rental tools must be handled consistently.
10. No transaction may duplicate or destroy coins or items.
11. Multiplayer behavior must respect ownership, authority, and transaction integrity.
12. Save/load and repeated transaction requests must remain safe and deterministic.

Renting must not automatically be the preferred choice.

An NPC should evaluate whether renting, purchasing, borrowing through existing mechanics, using another tool, or postponing the work makes the most sense.

Their financial circumstances, needs, available alternatives, and relationships should influence that decision.

Do not introduce free equipment generation to satisfy rental demand.

Economy switch behavior:

- Basic tool repair: available with economy ON or OFF.
- Commercial tool rental: economy ON only.
- Existing equipment wear: unchanged unless an actual defect is identified.
- Normal gameplay with economy OFF: preserve existing behavior except for the specifically approved basic repair functionality.

---

LE-06 — SAVE-GROWTH WORK

Worker A is authorized to continue the economy-enabled 365-day validation.

Once the required validation is complete:

1. Review the results.
2. Verify determinism and resource conservation.
3. Confirm save-growth improvements.
4. Confirm existing saves remain compatible.
5. Merge the completed work if all relevant requirements pass.
6. Record the evidence and integration commit.

Do not rerun already successful test campaigns simply for reassurance.

Reuse valid passing evidence tied to the exact source commit wherever appropriate.

Run additional tests only where changed code, missing coverage, failed validation, or genuine integration risk justifies them.

Worker A may continue LE-05 work without waiting for unrelated judgment calibration tasks.

---

DEVELOPMENT AUTHORIZATION

The owner authorizes continued Expansion 20 development on all items above.

These are implementation decisions, not requests for another planning discussion.

Proceed with appropriate parallel work where tasks are independent.

Use the existing design documents, decision register, technical architecture, and approved judgment framework as authoritative references.

Do not substitute simplified behavior for systems that have already been designed and approved.

Do not silently introduce new gameplay policies beyond the scope of these decisions.

For implementation details not explicitly specified, follow existing architecture and established game rules. Make reasonable engineering choices that preserve the design intent.

Only return to the owner for a genuinely new design decision, a significant conflict between approved requirements, or a change that would materially alter gameplay beyond the authorization above.

REPORTING

At the next meaningful checkpoint, provide:

1. Completion status for C1–C6.
2. Status of the previously authorized bandit intelligence work.
3. LE-05 repair and rental progress.
4. LE-06 validation and merge status.
5. Any newly discovered defects.
6. Relevant testing and simulation evidence.
7. Any actual owner decisions still required.

Keep the economy disabled by default.

Keep Build 24 frozen and unchanged.

Do not publish any build without explicit approval.

Proceed with development.
