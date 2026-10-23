# Owner directive, 2026-10-23: Expansion 21 Village Politics and Civic Authority, phase 1 authorization

Saved verbatim.

---

MY MEDIEVAL LIFE — EXPANSION 21

Village Politics and Civic Authority — Phase 1 Authorization

Project: Hot Attic Games — My Medieval Life
Expansion: 21 — Village Politics and Civic Authority
Immediate assignment: P21-00 architecture audit, P21-01 isolated foundations, P21-02 dependency mapping.

Mission

Begin foundational development of a living political and civic system in which villages govern themselves, officials perform real work, public resources are finite, and political leadership can change naturally through the simulation.

The player is another participant in this world, not automatically its ruler.

1. Establish the authoritative requirements

Read the existing Permanent World Design Rules, especially Rule 015, and the Subjective Judgment & Universal Decision Engine specification.

Inspect the Interlocking Systems Manifest, requirements register, current recovery handoffs, and active development branches.

Identify any additional political or civic requirements already approved by the owner.

Do not invent missing requirements or treat proposed engineering approaches as approved gameplay decisions.

2. Protect concurrent work

Expansion 19 is developing judgment, personality, and relationships.

Expansion 20 is developing the living economy.

Expansion 21 must not interfere with either.

Inspect worktrees and active workers before making changes. Use an isolated development branch and preserve all existing work.

Do not merge into staging or main, activate new gameplay systems, or publish builds.

3. P21-00 — Government architecture audit

Identify the current implementation and ownership of:

- Village and settlement administration.
- Manor authority and noble households.
- Mayors, elders, councils, and other leadership roles.
- Public treasuries, taxes, fines, rents, and fees.
- Government spending and civic wages.
- Guards, patrols, investigations, and crime responses.
- Courts, magistrates, bailiffs, and legal consequences.
- NPC occupations, employment, and career progression.
- Land, buildings, public property, and infrastructure.
- Political influence, reputation, trust, and family connections.
- NPC historical records, ancestry, and graveyards.
- Elections, appointments, and leadership succession, if any.
- Save/load and deterministic simulation behavior.

For each system, identify what exists, what is functional, what is incomplete, and what is absent.

Do not create a duplicate government or treasury system.

4. P21-01 — Isolated civic foundations

Where requirements are settled and existing architecture permits, prepare backward-compatible foundations for:

- Civic offices and unique office identifiers.
- Officeholder identity and tenure history.
- Government jurisdiction and settlement association.
- Office eligibility and authority metadata.
- Leadership succession-event records.
- Public treasury references and transaction attribution.
- Civic employment and official-duty records.
- Political historical records for NPC legacies.
- Data structures supporting future councils, elections, and appointments.

Reuse existing services and schemas.

Do not implement election formulas, voting eligibility, taxation rates, legal punishments, or office powers without owner approval.

Keep all new political behavior disabled.

5. P21-02 — Political decision architecture

Map the decisions required for:

- Seeking political office.
- Supporting candidates.
- Voting in elections.
- Appointing officials.
- Allocating public spending.
- Collecting taxes and enforcing payment.
- Hiring and paying guards.
- Investigating crimes.
- Applying legal judgments.
- Building and maintaining infrastructure.
- Responding to emergencies.
- Replacing officials through lawful succession.

For each decision, identify the existing game system that should own the action, the required information, and the unresolved owner choices.

Political decisions must account for practical interests as well as personal relationships.

A villager may support a candidate they dislike because the candidate's policies benefit their household or profession.

Personal moral judgment, legal guilt, and political eligibility must remain separate concepts.

6. Economic integration

Expansion 20 owns economic transactions and the movement of money and resources.

Expansion 21 will eventually use those systems for taxation, civic payroll, public purchasing, and treasury spending.

Government cannot create unlimited money or supplies.

Do not implement a parallel economy for government.

Where the current game already has a functioning manor treasury or institutional economy, preserve its authority and identify the correct integration points.

7. NPC autonomy and political careers

The architecture must support:

- NPCs seeking and holding public office.
- Officials carrying out actual responsibilities.
- NPCs evaluating political opportunities.
- Leadership changing without player involvement.
- Political advancement influenced by wealth, family, reputation, service, and personal ambitions.
- Government success and failure having real consequences.
- Political careers persisting in family and historical records.

Do not force political participation on every NPC or guarantee that any candidate succeeds.

8. Testing and safeguards

Implement narrowly scoped tests for any approved foundational changes.

Verify:

- Existing gameplay is unchanged while new systems are disabled.
- Civic records have stable identities.
- No duplicate officeholder or tenure records are created.
- Existing money and inventory remain conserved.
- Save/load preserves new records.
- Deterministic replay remains intact.
- Historical references survive officeholder death.
- Performance remains appropriate for larger settlements.

Reuse existing passing test evidence where applicable. Avoid redundant full simulation campaigns.

9. Owner decisions still required

Produce a grouped decision packet covering:

1. Village government structure and jurisdiction.
2. Election versus appointment versus hereditary succession.
3. Eligibility to hold office.
4. Voting eligibility and voting methods.
5. Term lengths and removal from office.
6. Taxation authority and limits.
7. Public spending priorities.
8. Legal authority and criminal procedures.
9. Guard command and enforcement responsibilities.
10. Political corruption and abuse of office.
11. Noble authority versus local government.
12. Player political participation.

For each, identify what is already approved, what exists in the codebase, and what requires an owner decision.

Do not decide these questions yourself.

10. Development and recovery

Commit meaningful authorized changes to the isolated Expansion 21 development branch and push them to GitHub.

Maintain a recovery handoff containing branch, commit, architecture findings, completed work, test evidence, active workers, blockers, and next steps.

Prepare recovery before approximately 80% context usage.

Do not launch unnecessary parallel agents or perform full multiplatform builds.

11. Deliverable

Provide a P21-00/P21-01/P21-02 readiness report with:

- Architecture inventory.
- Existing versus missing functionality.
- Safe foundation work completed.
- Files changed and commit IDs.
- Test results.
- Dependencies on Expansions 19 and 20.
- Owner decisions requiring answers.
- Recommended next implementation stage.

Begin the audit and authorized isolated foundation work now.

Do not activate politics, alter existing civic behavior, or publish a build without explicit owner authorization.
