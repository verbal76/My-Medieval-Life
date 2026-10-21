# Owner directive, 2026-10-21: Build 17 — MIN-F-Q1 through Q5: Final Owner Decisions and Implementation Directive

Saved verbatim from the owner's message (CLAUDE.md section 9a).

---

MY MEDIEVAL LIFE — BUILD 17

MIN-F-Q1 THROUGH Q5: FINAL OWNER DECISIONS AND IMPLEMENTATION DIRECTIVE

Repository: verbal76/My-Medieval-Life
Workstream: Build 17 — Underground Mining
Status: Five owner decisions approved
Authorization: Implement on the appropriate Build 17 development branch. Do not publish a new release without authorization.

1. OWNER DIRECTIVE

All five outstanding MIN-F mining questions have been answered.

These decisions are approved gameplay requirements, not suggestions or provisional design options.

Implement them using the existing mining, inventory, construction, job, pathfinding, and economic systems wherever possible.

Do not replace working mining functionality or introduce parallel systems unnecessarily.

The fundamental rules remain:

A VILLAGE IS ALLOWED TO FAIL. THE SIMULATION IS NOT.

Everything must obey physical access, available labor, material conservation, and deterministic simulation.

No teleporting resources, creating free materials, magically stabilizing excavations, or granting villagers knowledge of undiscovered deposits.

---

2. MIN-F-Q1 — COLLAPSES AND SUPPORT DETERIORATION

OWNER DECISION: APPROVED

Unsupported underground tunnels can collapse.

Timber supports deteriorate over time and require maintenance, repair, or replacement.

Implementation requirements

- Preserve the existing timber-support placement mechanics.
- Continue consuming actual materials when constructing supports.
- Introduce structural stability evaluation for excavated tunnels.
- Unsupported or inadequately supported excavations must be capable of collapsing.
- Installed supports provide stability according to their condition and placement.
- Supports gradually deteriorate through the simulation.
- Damaged supports can be repaired or replaced using real labor and materials.
- A collapsed passage becomes physically obstructed.
- Clearing collapsed material requires actual excavation and handling of the resulting material.
- Update navigation and access when a passage becomes blocked or reopens.
- Save and restore support condition and collapsed passages.

Do not use an arbitrary global collapse event that ignores the actual excavation.

The exact collapse probabilities, deterioration rates, support capacities, and repair requirements are implementation parameters to document and balance through testing.

Do not silently establish irreversible owner policy for those values.

Collapses must not destroy or create goods without an explicitly modeled, conserved material transformation.

---

3. MIN-F-Q2 — HIDDEN ORE AND MANOR TUNNELING JOBS

OWNER DECISION: APPROVED

Tunneling may expose previously hidden ore deposits.

The manor may offer paid tunneling work through the existing job system.

Hidden ore requirements

Underground discoveries must use the same recognizable ore-bearing rock objects and existing depletion and sustainability mechanics already used for surface and cave deposits.

Do not create a separate underground ore economy.

Do not introduce new ore regeneration rules.

Hidden deposits must exist as part of the deterministic world state before discovery or be deterministically generated through the existing world-generation rules.

Excavation exposes a deposit. It must not magically create ore as a reward.

Once exposed, the deposit behaves like an ordinary ore deposit.

Miners must still physically extract and transport the ore.

Manor tunneling jobs

Use the existing manor job framework.

The manor may post work to excavate a specified tunnel or passage.

Workers can evaluate and accept available jobs according to existing labor, payment, scheduling, and decision rules.

Jobs must have a defined work location and completion condition.

Payment must come from actual available funds.

Excavation must produce real material outputs and modify the actual terrain.

Do not create a mining-specific wage economy or bypass the existing employment and job systems.

Preserve the distinction between an independent miner working for personal needs or sale and a worker accepting a paid manor assignment.

---

4. MIN-F-Q3 — AUTOMATIC MINECART PREFERENCE

OWNER DECISION: APPROVED

Miners should automatically prefer minecarts when practical and use manual carrying otherwise.

Implementation requirements

When transporting mined materials, workers should evaluate whether a usable minecart and connected track route are available.

If using the minecart provides a practical hauling advantage, the miner should prefer it.

The cart must have sufficient available capacity.

The route must physically connect the loading and unloading locations.

Materials must be loaded into the cart's real inventory, transported along the track, and unloaded at the destination.

The cart cannot teleport, duplicate cargo, or pass through disconnected track.

If no suitable minecart exists, or using it would be impractical, miners must be able to carry goods manually.

Do not require minecarts for all underground mining.

Do not force a miner to walk a large detour to use a cart when carrying the material directly is more practical.

Respect other workers' use of carts and prevent multiple workers from claiming the same unavailable capacity.

The exact efficiency calculation may use existing pathfinding and hauling costs.

Do not add unnecessary micromanagement to routine hauling.

---

5. MIN-F-Q4 — VERTICAL SHAFTS AND MULTIPLE UNDERGROUND LEVELS

OWNER DECISION: APPROVED

Allow multiple underground levels connected by physically excavated vertical shafts.

Implementation requirements

Workers must be able to excavate vertical shafts connecting underground levels.

Shaft construction requires real labor and appropriate physical excavation.

Shafts must be represented in the world as actual connections between levels.

Villagers must use those connections to travel between levels.

Vertical access may require appropriate constructed access equipment, such as ladders or other physically modeled mechanisms.

Equipment and materials must also have a valid method of moving between levels.

A minecart cannot automatically move vertically merely because a shaft exists.

If a cart or its cargo must change elevation, that movement requires a suitable physical transport mechanism.

Preserve navigation between the surface, mine entrances, caves, horizontal tunnels, and connected underground levels.

Include shafts in structural stability and collapse evaluation.

Save and restore excavated levels, shaft connections, access equipment, and their conditions.

Do not introduce unlimited underground levels without considering world generation, memory, performance, and pathfinding.

Use the existing underground world representation wherever feasible.

---

6. MIN-F-Q5 — PLAYER-DIRECTED BACKFILLING AND STRUCTURAL SUPPORT

OWNER DECISION: APPROVED

Excavated tunnels may be backfilled with spoil.

Backfilling provides structural support to nearby excavations.

CRITICAL OWNER RESTRICTION: BACKFILLING IS NOT AUTOMATIC.

Player interaction

The player must deliberately select a tunnel or excavated area for backfilling.

Provide an appropriate Backfill Tunnel action through the existing mining or construction interaction interface.

After the player selects the target, the work may be assigned through the existing worker/job system.

A worker must not independently decide to backfill a tunnel merely because it is unused, dangerous, or close to a spoil stockpile.

No autonomous manor backfill orders are authorized by this decision.

Physical work

The assigned worker must obtain real spoil from an accessible location.

The worker must physically transport that spoil to the selected backfill area.

Use the existing inventory, hauling, and minecart systems where practical.

The quantity of material placed must correspond to the amount removed from the source inventory.

Do not generate free fill material.

Backfilling must require labor and progress through the existing simulation.

Result

As fill is placed, the selected tunnel becomes progressively filled.

A fully backfilled passage is blocked for ordinary travel.

The passage cannot remain navigable as though empty.

Reopening it requires physical excavation.

The placed material contributes to structural stability according to its quantity, placement, and the surrounding excavation.

Backfill may reduce collapse risk in nearby excavations when the physical conditions support that benefit.

Do not give every backfilled cell an unlimited stability bonus.

Do not treat backfill as equivalent to a timber support in all circumstances.

Backfilling must not magically repair damaged timber.

Material conservation

Spoil transferred into backfill remains accounted for as material occupying the world.

If the passage is excavated again, the material must be recovered or transformed through an explicitly modeled and conserved process.

Never award fresh ore simply because previously backfilled spoil is excavated again.

Track enough provenance or material classification to distinguish placed fill from natural ore-bearing rock.

Work cancellation and interruptions

If the job is interrupted, preserve completed fill and all remaining material.

Do not refund already placed material magically.

If the player cancels a partially completed job, the existing placed fill remains until physically removed.

Save and restore partially completed backfill operations.

---

7. INTEGRATION WITH EXISTING MINING

Build on the previously reported MIN-F and MIN-H functionality:

- Horizontal tunnel excavation.
- Timber supports.
- Physical track construction.
- Minecart hauling.
- Natural cave entrances.
- Ordinary ore seams and depletion.
- Underground villager pathfinding.
- Save/load.
- Visible remaining ore quantities.

Preserve these existing features.

The natural cave floor currently uses placeholder art. Do not treat that visual limitation as authorization to redesign the underground graphics during this implementation round.

Keep the work focused on the five approved mechanics and their necessary supporting systems.

---

8. NPC AGENCY AND JOB SELECTION

Distinguish between automatic work decisions and player-directed construction.

Automatic behavior permitted:

- Choosing existing mining opportunities.
- Accepting available manor tunneling jobs.
- Preferring minecart hauling when practical.
- Maintaining supports when authorized through applicable existing work or maintenance systems.
- Responding to blocked routes and unavailable equipment.

Player authorization required:

- Selecting a tunnel for backfilling.
- Initiating the backfill operation.

Do not interpret permission for autonomous mining or tunneling as permission for autonomous backfilling.

If the existing job system supports NPC acceptance of a player-created backfill order, that is permitted.

The decision to create the backfill order remains with the player.

---

9. DETERMINISM, SAVE INTEGRITY AND PERFORMANCE

All new behavior must remain deterministic under identical world state, seed, and action sequence.

Ensure stable processing of:

- Support deterioration.
- Collapse evaluation.
- Underground excavation.
- Hidden ore exposure.
- Shaft navigation.
- Minecart selection and reservations.
- Backfill progress.
- Structural changes.
- Job completion and interruption.

Save/load must preserve these states without resetting deterioration, duplicating cargo, losing fill, or revealing undiscovered ore.

Maintain material and currency conservation.

Evaluate performance with the existing village-scale simulation.

Avoid expensive full-map structural recalculation every frame when only a small number of cells have changed.

Use appropriately localized updates where feasible.

---

10. TESTING AND BUILD DISCIPLINE

MIN-F and MIN-H were previously reported as merged locally with 113 underground checks and 12 related suites passing.

The determinism baseline was being re-recorded because villagers began using cave resources and the manor began digging an open pit.

Do not confuse that legitimate simulation behavior change with a nondeterminism defect.

Complete the appropriate baseline verification before treating the changed Build 17 simulation as established.

Reuse passing tests and CI evidence where still applicable.

For these five newly implemented decisions, add focused tests for:

1. Collapse and support deterioration.
2. Repair and replacement material consumption.
3. Hidden ore discovery and depletion.
4. Manor tunneling job execution and payment.
5. Minecart preference and manual fallback.
6. Multi-level shaft navigation and hauling.
7. Player-authorized backfill jobs.
8. No autonomous backfilling.
9. Backfill structural effects.
10. Backfill excavation and material conservation.
11. Save/load and deterministic replay.

Do not rerun every unrelated suite solely for reassurance.

Run the broader tests only when necessary for a genuine integration or release gate.

Keep the MIN-G long multi-seed runs coordinated with existing GitHub workflow capacity rather than duplicating queued campaigns.

---

11. REQUIRED IMPLEMENTATION REPORT

Proceed with implementation using the existing Build 17 development workflow.

Report:

1. Which of the five approved decisions are fully implemented.
2. Which remain partial and why.
3. Files and systems changed.
4. The branch and exact commit HEAD.
5. New or modified gameplay interactions.
6. How structural stability and deterioration work.
7. How minecart preference is calculated.
8. How shafts connect levels and transport goods.
9. How player-directed backfilling is enforced.
10. Material conservation and determinism evidence.
11. Test results and remaining gaps.
12. Any genuine owner decisions needed to complete the work.

Do not report an approved design as completed code until it is implemented and verified.

Do not merge into unrelated branches.

Do not publish an APK, Windows, or Linux release without explicit authorization.

FINAL OWNER PRINCIPLE:

Mining must behave like a physical economic activity.

Workers excavate real material, move it through real routes, use real equipment, maintain real structures, and receive payment from real funds.

Supports and backfill affect structural conditions.

Minecarts improve transportation when practical.

Underground levels connect through physical shafts.

Backfilling only begins when the player selects it.

A VILLAGE IS ALLOWED TO FAIL. THE SIMULATION IS NOT.
