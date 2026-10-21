# Owner directive, 2026-10-21: Parallel Prospective Development (Expansions 18 and 19)

Saved verbatim from the owner's message (CLAUDE.md section 9a).

---

My Medieval Life — Parallel Prospective Development Directive
Authorize immediate prospective development for Expansions 18 and 19 while Expansion 17 remains the primary active development milestone.
The objective is to buy back development time by preparing, implementing, and testing future systems before their preceding expansions are complete, without introducing instability into the active development branch.
Branches
Create and push two independent remote GitHub branches:

* `wip/expansion18-preparation`
* `wip/expansion19-preparation`

Use the latest appropriate stable baseline. Do not branch 19 from unfinished 18.
These branches are isolated development workspaces, not documentation-only branches.
Authorized work
Claude and its development agents may:

1. Read and audit existing game systems and approved expansion specifications.
2. Develop new gameplay code, services, data structures, algorithms, and interfaces.
3. Implement independent features that do not require unfinished systems from earlier expansions.
4. Build isolated prototypes, simulations, mocks, fixtures, and test harnesses.
5. Write unit tests, integration tests, deterministic simulation tests, and migration tests.
6. Refactor code within their own branches where needed, provided the changes do not interfere with active development.
7. Commit and push completed work to their respective remote branches.
8. Continue improving prospective implementations as new information becomes available.

Do not limit these workstreams to theoretical architecture or planning documents.
Restrictions
Neither prospective branch may:

* Merge into the active staging or release branch without integration authorization.
* Modify or interrupt the active Expansion 17 development process.
* Treat unfinished Expansion 17 or 18 interfaces as finalized.
* Introduce conflicting authoritative systems, duplicated ledgers, or parallel NPC decision engines.
* Publish a Build 18 or Build 19 release.
* Present prospective features as completed, integrated gameplay.

Prospective code must remain isolated until its dependencies are ready.
Expansion 18 — Settlement Advancement and Regional Economy
Begin implementation of independently developable components, including:

* Settlement capability and specialization models.
* Regional supply-and-demand calculations.
* Trade-route and transport planning.
* Settlement inventories and economic reporting.
* Economic competition and cooperation.
* Caravan subsidy replacement planning.
* Tests for resource conservation, genuine trade, and settlement independence.

Where Expansion 18 depends on mining and industrial systems from Expansion 17, define provisional interfaces and use test fixtures.
Do not create duplicate mining systems or assume unfinished production behavior is final.
Expansion 19 — NPC Judgment and Universal Decision Engine
Begin implementation of independently developable components, including:

* Personal memory and event interpretation structures.
* Subjective judgment calculations.
* Signed positive and negative opinion records.
* Decision-weighting algorithms.
* Memory provenance and information-sharing rules.
* Judgment persistence and save migration prototypes.
* Deterministic decision tests.
* Performance tests with large NPC populations.

Use isolated test scenarios and provisional adapters rather than prematurely replacing the live NPC decision system.
The judgment system must influence choices, not dictate them.
For example, an NPC with a strongly negative judgment of another character may still trade with that character when their need for iron outweighs the negative opinion.
Continuous compatibility checks
As Expansion 17 develops, periodically review changes affecting Expansion 18.
As Expansion 18 develops, periodically review changes affecting Expansion 19.
Do not repeatedly perform expensive full-repository audits when targeted comparisons are sufficient.
When a dependency changes:

1. Identify the affected interfaces and behaviors.
2. Update provisional adapters and affected implementation code.
3. Rerun relevant tests.
4. Record remaining incompatibilities.
5. Continue other independent work.

Do not automatically merge unfinished upstream changes into prospective branches merely to keep them current.
Mandatory reconciliation gates
After Build 17 is complete
Expansion 18 must undergo a full compatibility and integration-readiness review against the completed Build 17 baseline.
Rebase or merge the approved baseline into the Expansion 18 branch using an appropriate conflict-controlled process.
Reconcile mining, industrial production, resources, inventories, economic transactions, settlement capabilities, save formats, and tests.
Only then may the Expansion 18 code proceed into final integration for Build 18.
After Build 18 is complete
Expansion 19 must undergo the same reconciliation against the completed Build 18 baseline.
Reconcile NPC behavior, memory, economic decisions, trading, employment, relationships, settlement interactions, save formats, and tests.
Only then may the Expansion 19 code proceed into final integration for Build 19.
Development priorities
Priority 1: Continue Expansion 17 implementation, testing, integration, and release preparation without interruption.
Priority 2: Advance Expansion 18 prospective implementation wherever dependencies permit.
Priority 3: Advance Expansion 19 prospective implementation independently.
Avoid excessive parallel agents or duplicated repository analysis. Parallel development is worthwhile only when it produces useful progress without creating more integration work than it saves.
If one workstream is blocked, continue another approved task rather than waiting idly.
Progress reporting
For each expansion, maintain:

* Features implemented and tested.
* Features implemented provisionally.
* Dependencies awaiting earlier expansions.
* Known integration risks.
* Outstanding owner decisions.
* GitHub branch and latest pushed commit.
* Estimated integration-readiness, based on verified tests rather than speculation.

Standing authorization: Continue prospective coding, testing, documentation, and GitHub commits/pushes without requiring repeated permission. Final integration and release publication remain subject to their respective milestone gates.
The goal is to have Expansion 18 substantially developed when Build 17 finishes, and Expansion 19 substantially developed when Build 18 finishes, rather than starting either expansion from zero at that point.
