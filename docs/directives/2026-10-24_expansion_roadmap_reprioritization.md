# Owner directive, 2026-10-24: expansion roadmap reprioritization (Expansions 20-27)

Saved verbatim from the session.

---

# MY MEDIEVAL LIFE — EXPANSION ROADMAP REPRIORITIZATION

## Mission

Update the My Medieval Life development roadmap for Expansions 20–27 to reflect the newly approved priority order.

Build 19 has completed its automated release validation and is available as a private playtest draft. It remains frozen pending owner playtesting and final acceptance.

**This directive authorizes roadmap planning and documentation updates only. It does not authorize implementation of any expansion.**

## 1. Approved Development Priority

The new development order is:

| Priority | Expansion | Focus |
|---|---|---|
| 1 | 20 — Living Economy | Economic independence, transactions, financial hardship, and recovery |
| 2 | 21 — Politics | Leadership, governance, elections, and collective decisions |
| 3 | 23 — Bandits & Crime | Crime, enforcement, justice, and consequences |
| 4 | 22 — Settlement Advancement | Village development, decline, infrastructure, and growth |
| 5 | 24 — Legacy | Generational consequences, inheritance, and family continuity |
| 6 | 25 — Weather & Disasters | Environmental pressure and natural disasters |
| 7 | 26 — Creatures & Heroes | Creatures, extraordinary threats, and emergent heroism |
| Pending | 27 — To Be Verified | Preserve its existing specification and identify its dependencies |

**Expansion numbers remain unchanged. Only their development priority changes.**

Before updating the roadmap, inspect the existing expansion specifications and dependency records. Preserve all previously approved design decisions. Do not replace detailed existing specifications with the abbreviated descriptions above.

If a technical dependency makes the proposed order unsafe, identify the specific dependency and recommend the smallest necessary adjustment. Do not silently change the owner's priority order.

## 2. Architectural Direction

The central design objective remains:

**Create a living medieval world where every character operates under the same underlying rules, makes decisions based on individual circumstances, and experiences consequences that persist.**

NPCs must not behave as scripted background decorations.

The player must not receive special economic, political, or survival protections unavailable to NPCs under equivalent circumstances.

The simulation must support success, failure, recovery, decline, and unexpected outcomes without forcing predetermined stories.

### Expansion 20 — Living Economy

Prioritize the ability of NPCs to respond independently to economic circumstances.

For example, when Joan Stone loses her building fund to bandits, the simulation should support appropriate economic alternatives such as seeking employment, negotiating payment, selling possessions, borrowing, or requesting family assistance, where those mechanisms are included in the approved design.

These are possibilities, not guaranteed rescue mechanisms.

Financial hardship must remain capable of producing genuine failure.

### Expansion 21 — Politics

Political systems should respond to the economic and social conditions already present in the village.

Leadership decisions must have practical consequences for individuals, families, institutions, and village development.

Preserve previously approved election, office, eligibility, and term rules.

### Expansion 23 — Bandits & Crime

Extend the existing bandit and judgment systems rather than replacing them.

Crime should interact with reputation, economics, family relationships, leadership, enforcement, and community responses.

Preserve the approved bandit survival, food-purchasing, healing, and combat behavior from Build 19.

### Expansion 22 — Settlement Advancement

Settlement growth and decline should emerge from available resources, economic activity, governance, population needs, and accumulated decisions.

Do not create artificial development milestones that override the simulation's actual conditions.

### Expansion 24 — Legacy

Allow the consequences of earlier generations to influence later generations through the mechanisms defined in the approved specification.

Maintain consistency with permanent NPC identities, family relationships, property, reputation, and mortality.

### Expansions 25 and 26

Keep Weather & Disasters and Creatures & Heroes in design-only status until specifically authorized.

These systems should eventually create external pressures that interact with the existing simulation rather than bypassing it.

### Expansion 27

Locate and report the current approved specification. Do not invent its purpose or implementation requirements.

## 3. Dependency and Integration Review

Before finalizing the revised roadmap:

1. Review the existing specifications for Expansions 20–27.
2. Identify dependencies between expansions.
3. Identify systems established in Builds 16–19 that each expansion must preserve.
4. Identify shared infrastructure that can support multiple future expansions.
5. Flag any conflicts caused by moving Expansion 23 ahead of Expansion 22.
6. Identify potential performance, determinism, and resource-conservation risks.
7. Recommend logical implementation batches and testing checkpoints for future work.

Avoid unnecessary architectural duplication.

Do not implement infrastructure merely because a later expansion might eventually need it.

## 4. Development Efficiency

When implementation is subsequently authorized, organize work into related subsystem batches.

Do not implement and comprehensively retest every minor change individually.

Use targeted tests during development and comprehensive integration testing at meaningful release checkpoints.

Preserve deterministic simulation results, resource conservation, established performance budgets, and previously approved game behavior.

Do not run lengthy simulation campaigns repeatedly without a specific validation purpose.

## 5. Build 19 Protection

Build 19 remains the current private playtest candidate.

Do not modify its released packages, approved baseline, release artifacts, or established behavior as part of this roadmap update.

Do not merge the Build 19 draft pull request or publish anything publicly.

Any Build 19 defects discovered during owner playtesting must be documented and handled separately.

## 6. Required Deliverable

Produce a revised roadmap report containing:

- The complete new priority order.
- The existing scope of every expansion, preserved from its source specification.
- Dependencies and potential conflicts.
- Shared architectural requirements.
- Recommended development batches.
- Testing and release checkpoints.
- Current authorization status for every expansion.
- Any unresolved questions requiring owner approval.

Update the appropriate roadmap and planning documents only after verifying their existing contents.

Do not overwrite historical records or previously approved design specifications.

## 7. Execution Boundary

**Complete the roadmap review and documentation updates, then stop.**

Do not begin Expansion 20 implementation, launch new development agents, start release workflows, or build APK, Windows, or Linux packages.

Report what was updated, any dependency conflicts, and whether Expansion 20 is ready for a separate implementation authorization.

**The goal is to establish a coherent development sequence in which each expansion strengthens the living simulation and provides a foundation for the next.**
