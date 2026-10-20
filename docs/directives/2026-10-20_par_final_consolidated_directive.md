# Owner directive, 2026-10-20: final consolidated directive on player-villager parity, skill generation, career changes and experience

Saved verbatim. It consolidates and clarifies OD-18 (`2026-10-20_od18_player_villager_parity.md`) and supersedes any
conflicting interpretation. Register: PAR-00..PAR-05 (updated), PAR-01A..PAR-01C (new children of PAR-01), OD-19 (the
universal reserve threshold, section 6).

---

MY MEDIEVAL LIFE — BUILD 16

FINAL CONSOLIDATED DIRECTIVE: PLAYER–VILLAGER PARITY, SKILL GENERATION, CAREER CHANGES, AND EXPERIENCE

Status: Owner-approved design requirements

Claude, this directive consolidates and clarifies the owner's decisions for OD-18, PAR-00 through PAR-05, and particularly PAR-01.

You have already acknowledged the central player–villager parity directive and recorded it in the repository. This message refines those requirements and supersedes any conflicting interpretation in previous instructions.

Do not discard completed work or restart implementation unnecessarily. Incorporate these clarifications into the existing Build 16 development plan.

1. THE FUNDAMENTAL RULE: THE PLAYER IS A VILLAGER

The player and NPC villagers exist under the same simulation rules.

They use the same systems for:

- Skills and experience.
- Mining and resource gathering.
- Crafting and recipe requirements.
- Trading and economic transactions.
- Rest and health recovery.
- Crime detection and guard awareness.
- Inventory, material consumption, and production accounting.

The difference is who makes decisions.

The human controls the player. AI controls the other villagers.

Neither receives special privileges, hidden exemptions, or artificial advantages merely because of their player/NPC classification.

Individual differences must emerge from knowledge, experience, resources, circumstances, relationships, and decisions.

2. PAR-01: INITIAL WORLD GENERATION AND STARTING SKILLS

This is the owner's definitive clarification.

During initial world generation, established villagers may receive starting skill experience representing their lives and occupations before the simulation began.

This happens only during initial world generation.

Examples:

- An established blacksmith may begin with substantial Smithing experience.
- An experienced farmer may begin with Farming experience.
- A long-serving miner may begin with Mining experience.
- A young apprentice may begin with limited experience.
- A person with no history in a particular skill begins with zero experience in that skill.

Starting experience should reflect a plausible occupational history, not age alone.

A 50-year-old farmer does not automatically receive 30 years of blacksmithing experience.

Use deterministic generation consistent with the established world and character data.

Do not grant every villager maximum proficiency.

Do not automatically make every occupation holder capable of performing every advanced task associated with that occupation.

Skill levels must continue to matter.

Important distinction: This initial allocation represents a villager's presumed history before the game begins. It is not a recurring benefit of having an occupation.

Existing saves

For older saves that lack villager skill records, use a documented, deterministic, one-time migration that establishes plausible prior experience.

This is a compatibility operation, not an ordinary gameplay event.

Preserve actual recorded skill experience wherever it already exists.

Never repeatedly regenerate estimated experience after migration.

3. PAR-01: CAREER CHANGES DO NOT GENERATE EXPERIENCE

When a villager changes professions, they do not receive free experience in their new occupation.

They also do not automatically lose experience they have already earned.

A villager enters a new career with exactly the experience already recorded in the relevant skills.

If that experience is zero, they begin at zero.

If they previously earned some experience, they retain it.

No occupation change should trigger an artificial skill increase, reset, or recalculation based on age.

Example A: Blacksmith becomes a farmer

A blacksmith who has never performed farming activities changes occupations.

Their Farming experience is zero.

They must learn farming by actually performing farming activities.

Their Smithing experience remains unchanged.

Example B: Blacksmith becomes a lumberjack

A blacksmith has occasionally chopped firewood for their household.

Those activities have already earned Woodcutting experience.

When they become a lumberjack, they begin with that existing experience.

They do not start from zero if their recorded experience is greater than zero.

They also receive no bonus experience merely for becoming a lumberjack.

Example C: Farmer becomes a miner

A farmer has occasionally mined stone to support household construction.

They have already earned some Mining experience.

If they become a miner, that experience carries forward.

They cannot mine gold until they satisfy the same Mining level requirement as the player.

Example D: Returning to a previous profession

A villager previously worked as a smith, then spent several years farming.

If they return to smithing, their previously earned Smithing experience remains available.

They do not have to relearn everything simply because they changed occupations.

4. INCIDENTAL AND NECESSITY-DRIVEN EXPERIENCE

This is an essential part of the design.

Villagers earn experience from what they actually do, not merely from their assigned profession.

Experience can come from:

- Performing their regular job.
- Completing household chores.
- Gathering resources for personal use.
- Helping another villager.
- Building or repairing something.
- Producing goods for their family.
- Responding to an emergency.
- Hunting or defending themselves.
- Trading.
- Crafting outside their primary profession.
- Performing other activities that already award experience under the player's rules.

A farmer who occasionally cuts trees earns Woodcutting experience.

A blacksmith who occasionally hunts earns the relevant experience from hunting activities.

A miner who makes tools for personal use earns the appropriate crafting experience.

A villager who trades goods outside their normal occupation earns the same applicable trading experience as the player.

Do not require an NPC to formally hold an occupation before they can earn experience in its associated skills.

Do not award experience merely for holding an occupational title.

Experience must come from eligible activities.

Use the same skill definitions, experience rates, progression thresholds, and skill effects for the player and villagers.

5. OCCUPATION, EXPERIENCE, AND CAPABILITY ARE DIFFERENT THINGS

Maintain these distinctions throughout the simulation.

Occupation: What a person currently does for work.

Experience: What that person has learned through previous activity.

Capability: What that person can currently accomplish based on skills, available equipment, materials, physical condition, and other requirements.

These are related but not interchangeable.

A villager can accept an occupation before becoming proficient at it.

They may initially perform only basic tasks.

They can progress to advanced work through actual experience.

They must never bypass skill requirements merely because the village needs a particular product.

Likewise, someone can be skilled in a profession without currently working in that profession.

A former smith can retain advanced smithing ability while employed as a farmer.

Core rule: Occupation determines work. Experience determines proficiency. Activities generate experience.

6. PAR-02: ONE TRADING RULE

The player and villagers must follow the same economic transaction rules.

There must not be separate player-versus-NPC coin reserve checks.

The current difference, where villagers preserve a 15-coin reserve while player transactions can reduce a trader to zero, must be resolved through a single shared rule.

OD-15 is answered as a parity requirement.

However, parity alone does not specify whether the universal minimum reserve should be zero or 15 coins.

Review the purpose of the existing reserve and recommend one universal rule before finalizing that threshold.

Whatever rule is selected must apply equally to player and NPC transactions.

Differences in willingness to trade may arise from needs, preferences, obligations, relationships, or economic circumstances, but not hidden player/NPC exceptions.

7. PAR-03: SHARED REST AND HEALTH RECOVERY

Use the player's existing rest and health-recovery model for villagers.

Equivalent rest under equivalent conditions must produce equivalent recovery.

If qualifying player rest restores full health, qualifying villager rest must do the same.

Villagers should recognize their need for rest and seek an appropriate opportunity to recover.

They must still be subject to the practical circumstances of the world.

A villager who cannot reach safety or obtain rest does not receive an invisible healing benefit.

Do not maintain a weaker NPC-only recovery model.

8. PAR-04: SHARED RECIPE ACCESS AND SKILL GATES

Villagers must have access to every recipe available to the player.

All recipes must use the same:

- Skill prerequisites.
- Required materials.
- Equipment requirements.
- Resource consumption.
- Production outputs.
- Experience awards.
- Accounting rules.

The eleven recipes previously unavailable to villagers must be incorporated into the shared crafting system.

Villagers may craft them when qualified and when there is a legitimate reason to do so.

Do not automatically produce every recipe simply because a villager has unlocked it.

Production should remain responsive to needs, demand, resources, and opportunities.

Do not grant advanced crafting skills merely because a villager has accepted a crafting occupation.

A newly appointed smith may initially be unable to make advanced armour.

That is a legitimate consequence of losing experienced workers.

9. PAR-05: CONSISTENT CRIME AWARENESS

Guards must not possess unexplained knowledge of crimes.

Assault and theft should follow consistent information and witnessing rules.

A guard can learn of a crime through a legitimate supported mechanism, including:

- Direct observation.
- A witness reporting the incident.
- A victim reporting the incident.

The simulation currently has no general sound-propagation model.

Do not invent hearing mechanics merely to preserve the old 15-tile assault detection rule.

Distinguish between witnessing a crime, reporting it, and responding to it.

Apply the same awareness principles to crimes committed by players, villagers, and bandits.

10. SHARED CORE ARCHITECTURE

Move player-specific gameplay mechanics into shared simulation systems wherever necessary to achieve parity.

Avoid maintaining separate player and villager implementations of the same underlying rules.

The shared architecture must support:

- Skill experience and progression.
- Mining and woodcutting.
- Crafting and recipes.
- Resource consumption and production.
- Inventory and overflow accounting.
- Economic transactions.
- Rest and recovery.
- Crime detection and reporting.

Player input and NPC AI should invoke common mechanics rather than duplicating their underlying rules.

Preserve determinism and save compatibility.

Do not introduce hidden resources, free skill progression, or artificial economic rescues to compensate for consequences of these changes.

11. EXPECTED SIMULATION CONSEQUENCES

The owner explicitly accepts that these changes may make village life more difficult.

For example:

If both experienced smiths die, two other villagers may decide to become smiths.

That does not make them instantly competent.

They may need to learn basic smithing before producing advanced equipment.

The village may temporarily suffer from:

- Reduced production.
- Unfilled orders.
- Equipment shortages.
- Lower construction output.
- Increased dependence on trade.
- Slower economic recovery.

These are legitimate outcomes when they emerge from the rules.

Do not secretly accelerate experience, spawn skilled replacements, create free supplies, or bypass skill requirements to restore equilibrium.

A village is allowed to fail. The simulation is not.

12. TESTING REQUIREMENTS

Add regression coverage for at least the following:

1. Initial world generation assigns plausible, deterministic occupational experience.
2. A villager with no experience in a new trade begins at zero.
3. Career changes never award free experience.
4. Career changes never erase existing experience.
5. Incidental activity awards experience even outside the villager's current occupation.
6. A villager returning to a previous trade retains their prior skills.
7. NPCs and players earn identical experience for equivalent actions.
8. Skill gates apply equally to both.
9. A new miner below Mining level 3 cannot mine gold.
10. An inexperienced smith cannot bypass advanced recipe requirements.
11. All eleven previously inaccessible recipes can be crafted by qualified villagers.
12. Rest and health recovery follow the same rules.
13. Trade reserve rules apply equally to player and NPC transactions.
14. Crime detection requires legitimate awareness.
15. Older saves migrate skill records correctly without repeatedly generating experience.
16. All skill calculations remain deterministic.

After integration, rerun:

- The full Godot test suites.
- Relevant player-action and NPC-action tests.
- Material and coin conservation checks.
- Determinism tests.
- The EQ-06 intervention scenarios.
- The year-long simulation runs.

Preserve the existing pre-parity results as baselines.

Do not attempt to force the new simulation to reproduce old outcomes if the changes legitimately alter village behavior.

13. IMPLEMENTATION AND DEVELOPMENT CONTINUITY

Continue the established PAR-02 through PAR-05 implementation plan.

Use dependency-aware, individually testable changes.

Preserve existing completed work.

Update the directive and decision records in the repository to reflect this final interpretation.

Commit and push approved changes to the existing remote GitHub staging branch.

Do not merge the pull request or publish a new Build 16 release without authorization.

Do not stop unrelated approved development because a separate task is blocked.

Maintain the current long-run simulation results as the pre-parity baseline.

14. REQUIRED ACKNOWLEDGMENT

Claude, explicitly confirm that you understand these final rules:

1. Starting occupational experience is generated only at initial world creation, with a one-time compatibility migration for older saves.
2. Changing careers never generates or resets experience.
3. Villagers retain experience earned through previous jobs, incidental activities, and necessity.
4. A villager entering a new trade begins with their actual recorded experience in its relevant skills, which may be zero.
5. Skills belong to individuals, not occupational titles.
6. The player and villagers use identical experience, progression, crafting, trading, recovery, and awareness rules.
7. Legitimate skill shortages and economic consequences must not be artificially corrected.
8. Existing approved development continues without requiring repeated authorization.

Confirm that this clarification has been incorporated into the repository's authoritative PAR-01 requirements.

Identify any conflicts with implementation already underway and explain how they were resolved.

Then continue the approved implementation and testing work.

The final governing principle is:

Every person in My Medieval Life lives under the same rules. Their abilities come from what they have actually learned, and their future is shaped by what they choose or need to do.
