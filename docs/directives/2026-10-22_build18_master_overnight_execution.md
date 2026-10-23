MY MEDIEVAL LIFE — BUILD 18 MASTER OVERNIGHT EXECUTION DIRECTIVE

Full Combined Release | Owner Decisions | Controlled Model Usage | MSW-01

October 22, 2026

This is the consolidated, authoritative overnight directive.

It supersedes conflicting instructions in earlier overnight prompts and incorporates the owner's latest decisions on inventory, tailor services, armour, Build 18 scope, testing, model usage, and worker coordination.

Read this entire directive before assigning new work.

The owner is going to sleep and may be unavailable for approximately seven hours.

PRIMARY OBJECTIVE: Make the maximum amount of useful, approved Build 18 progress while preserving enough Claude usage for the owner to continue working tomorrow.

Seven hours of available time does not mean seven hours of maximum model spending.

A VILLAGE IS ALLOWED TO FAIL. THE SIMULATION IS NOT.

---

PART 1 — AUTHORITATIVE BUILD 18 SCOPE

OWNER DECISION: KEEP BUILD 18 COMBINED

Build 18 remains the full combined release.

Do not split it into smaller releases or move approved Build 18 requirements into later builds merely to reach an earlier release date.

Build 18 includes all three existing tracks:

Track A — Gameplay, interface, and playtest corrections

Includes:

- Visual improvements
- HUD improvements
- Inventory overhaul
- Character creator
- Equipment visuals
- Armour
- Barber
- Tailor
- Ore placement
- Axe animation
- Tree stump corrections
- Crop visuals
- Trading interface
- Village Encyclopedia
- Map improvements
- Other approved Build 18 directives

Track B — Expansion 18: Settlement Advancement

Includes approved work involving:

- Settlement capability
- Facilities and experience
- Effective capability
- Production and pay integration
- Courier transport
- Formal contracts
- Regional economic systems
- Stonecutter trade
- Related approved settlement advancement requirements

Track C — Earlier approved roadmap requirements assigned to Build 18

Includes, where approved:

- Player businesses
- Expandable property
- Modular buildings
- Farming and livestock
- World Design Rule compliance
- Coin sinks
- Announced taxation systems
- Horse functionality
- Other approved requirements assigned to Build 18

Do not interpret a roadmap title as permission to invent missing gameplay specifications.

All approved Build 18 requirements remain in scope unless the owner explicitly changes them.

MULTIPLAYER

Multiplayer remains a future major expansion.

Do not merge, rebase, or implement the old multiplayer prototype during this overnight session.

Do not allow multiplayer to interfere with Build 18.

The existing multiplayer prototype and documentation must remain preserved.

---

PART 2 — CURRENT VERIFIED DEVELOPMENT BASELINE

Use the repository and authoritative register to confirm current branch heads.

The latest owner-facing reports established:

- Build 17 frozen game commit: "cd7439c"
- Integrated Build 18 branch: "wip/build18"
- Previously reported Build 18 head: "0fafb8b"
- Latest reported staging decision commit: "f824dcc"
- Expansion 18 preparation branch: "wip/expansion18-preparation"
- Inventory task branch: "wip/b18-inventory"

These are historical reference points, not assumptions that the branches have not advanced.

Inspect the actual current heads before acting.

Existing progress

The following were previously reported as implemented and integrated into Build 18, awaiting owner playtesting:

- Hunger icon correction
- Compact HUD
- Progress bar improvements
- Village Encyclopedia
- Animal sprite fragment correction
- Wheat growth and harvest visuals
- Doorway appearance
- Axe swing correction
- Apple-tree stump correction
- Ore placement outside the village
- Proportional crop sharing
- Map improvements
- Contract response visibility
- Trading full-pack notice
- Buy confirmation visibility

Character creator foundation and save migration have been implemented, but equipment-driven visual redraw remained incomplete.

The inventory worker was active with 17 changed files and no committed inventory implementation at the time of the latest report.

Do not discard or duplicate that work.

Existing test evidence

The previous integrated Build 18 report included:

- 3,584 core checks passing
- 503 start steps
- 39 play steps
- 105 Python tests
- 224 farming checks
- 73 prospecting checks
- 45 tree checks
- 24 character-look checks
- 19 crop-sharing checks
- Additional focused feature tests

No outstanding test failures were reported at that checkpoint.

These results apply to the source versions actually tested.

Do not misrepresent them as proof that subsequent changes have passed.

Reuse applicable evidence rather than rerunning everything.

---

PART 3 — INVENTORY OWNER DECISIONS

INV-Q1 — CLOSED

The eight-category inventory architecture is approved.

Every registered item must belong to exactly one category.

Approved borderline classifications:

Item| Category
Rings and amulets| Crafted Goods and Valuables
Wheat grain| Raw Materials
Raw meat| Food and Drink
Seeds, saplings and cuttings| Raw Materials
Herbal tonic| Medicine and Consumables
Lockpicks and padlocks| Tools

The other registered items should use the existing classification plan, with one unambiguous category per item.

Do not reopen these six decisions.

Use recognizable category icons:

- General: pouch
- Food and Drink: red berries
- Raw Materials: log
- Tools: pickaxe
- Weapons: sword
- Armour and Clothing: chestplate
- Medicine and Consumables: bandage
- Crafted Goods and Valuables: ingot or appropriate valuables icon

Skills and Journal remain accessible separately rather than occupying inventory categories.

INV-Q2 — CLOSED

The previous 18 → 23 → 27 capacity progression is superseded.

THE APPROVED CAPACITY PROGRESSION IS 9 → 18 → 27 PER CATEGORY.

Each of the eight categories has three rows of nine positions.

Starting inventory

First row unlocked.

9 positions per category.

72 total backpack positions.

Second and third rows visibly locked.

First upgrade

Unlock the entire second row across all eight categories.

18 positions per category.

144 total backpack positions.

Second upgrade

Unlock the entire third row across all eight categories.

27 positions per category.

216 total backpack positions.

Equipment

Six separate equipment positions:

- In hand
- Tool
- Body
- Head
- Amulet
- Ring

Equipped items do not consume backpack positions.

Maximum fully upgraded occupancy:

216 backpack positions + 6 equipped positions = 222 positions.

Preserve existing stack behavior.

Do not introduce new weight or stack limits.

Each upgrade is purchased once and applies globally across all eight categories.

Do not create individual upgrade purchases for each tab.

Item handling

Automatic category placement must apply to:

- Pickup
- Gathering
- Crafting
- Trading
- Chests
- Stalls
- Transfers
- Loot
- Other legitimate item acquisition paths

Capacity checks must use the relevant category.

Messages must identify the full category.

Equip, unequip, and swap must be atomic.

Do not duplicate, destroy, or silently move items incorrectly.

If unequipping would exceed the relevant capacity, reject the unsafe operation with a clear message.

Existing saves

Preserve every item, quantity, durability value, and equipped item exactly once.

Older saves that exceed a new category capacity must retain all possessions.

For example, a migrated category containing 12 item types may show:

12 / 9

It cannot accept additional new item types until capacity becomes available.

Do not delete items to enforce the new cap.

Persist upgrade level and equipped-item separation correctly.

The inventory implementation is expected to introduce save version 19, subject to confirming the current repository state.

---

PART 4 — TAILOR-18: NEW TAILOR SERVICE

The owner approves a tailor as a real village profession and service.

The tailor is the seller of backpack upgrades.

The tailor is also the intended future location for changing clothing.

A complete clothing production system is not required for the initial tailor implementation.

Existing economic facts

The latest investigation established:

- Approximately 14 existing professions, with no tailor or weaver
- Typical wages: approximately 6 coins per day
- Quarry load payment: approximately 6 coins
- Axe price: approximately 45 coins
- Iron sword price: approximately 69 coins
- Owner's playtest: money increased from 20 to 85 coins by day 4
- Village starting money: approximately 2,900 coins in examined seeds
- Median adult purse: approximately 25 coins
- Richest starting villager: approximately 120 coins

Use this evidence when evaluating upgrade prices.

Do not rerun a large simulation campaign just to rediscover these facts.

Approved upgrade prices

First upgrade: 150 coins

Second upgrade: 450 coins

Total: 600 coins

These are approved initial gameplay prices.

Keep them unless a demonstrated serious economic or technical issue requires an owner decision.

Do not silently rebalance them.

The first upgrade should require meaningful effort but be achievable relatively early.

The second should be a substantial investment.

Tailor implementation

Use existing economic and service systems where possible.

The previously proposed minimum approach is:

- Introduce a tailor job through the existing labor market.
- Allow an existing eligible villager to take the role under normal job rules.
- Avoid displacing an existing worker unnecessarily.
- Use an appropriate existing service point or market pitch if compatible with the approved world rules.
- Offer backpack upgrades as legitimate paid services.
- Transfer the player's coins into the tailor's actual purse.
- Persist the purchased upgrade level.
- Prevent duplicate purchases.
- Require the tailor to be available under normal service rules.
- Give clear messages for insufficient funds or unavailable services.

The tailor must exist in the game world.

Do not introduce a disconnected magic upgrade menu.

Important implementation boundary

The existing-service-point approach is a proposal, not permission to violate settlement or profession rules.

If placing the tailor requires an unapproved building, worker displacement, or economic-policy change, document the issue and continue independent approved work.

Do not invent a clothing manufacturing economy.

Do not invent free backpack items.

Do not destroy coins.

Economic concentration

A tailor who receives both upgrades collects 600 coins, approximately 21% of the examined village's initial money supply.

This is not automatically a defect.

The tailor should spend money through the existing economy.

Observe the consequences in later appropriate testing.

Do not add artificial redistribution, taxes, spending caps, or money sinks without owner approval.

---

PART 5 — ARMOR-Q: OWNER APPROVAL

APPROVE OPTION A FOR BUILD 18.

This closes the outstanding armour scope question.

Keep the five existing wearable items and their current provisional statistics.

Item| Armour| Durability| Price
Plain clothes| 0| 240| 2
Leather armour| 3| 300| 30
Iron armour| 6| 600| 80
Leather cap| 1| 240| 14
Iron helmet| 2| 480| 36

These values are provisional gameplay values, not permanently approved balance targets.

Do not rebalance them without evidence and owner approval.

Visual integration

- Iron armour uses the existing licensed Puny Characters metal breastplate art.
- Iron helmet uses the most appropriate existing licensed European metal helmet sprite.
- Claude may choose the best-fitting existing helmet sprite as an implementation detail.
- Leather armour and leather cap remain mechanically functional but do not receive invented replacement artwork.
- Plain clothes use the existing character creator clothing layer.

Complete the character redraw when equipment changes.

The visual appearance must match the actual equipped items.

Preserve existing character creator customization and save behavior.

Existing supply rules

Preserve:

- Smith-forged iron pieces
- Existing leather crafting
- Actual armoury stock
- Existing combat rules
- Existing durability and wear
- Legitimate ownership and transactions

Do not create unlimited armour supplies.

Do not add:

- Boots
- Gloves
- New helmet classes
- Rarity tiers
- Weight systems
- Movement penalties
- New recipes
- Unapproved armour statistics

Option B and Option C are not approved for this implementation.

Record ARMOR-Q as closed with Option A.

Proceed with approved implementation.

---

PART 6 — BARBER AND CHARACTER CUSTOMIZATION

The barber remains part of the approved Build 18 scope.

The barber handles hair customization.

The tailor handles clothing-related services and backpack upgrades.

The armorer handles armour.

Do not merge these professions into a single generic customization vendor.

Inspect the approved barber requirements and existing character creator.

Proceed with any independently approved functionality.

If barber prices, location, staffing, or economic mechanics remain unresolved, record the exact decision required.

Do not invent missing rules.

Continue other approved work rather than waiting.

---

PART 7 — EXPANSION 18 SETTLEMENT ADVANCEMENT

Resume approved and unblocked Expansion 18 development.

Inspect the actual state of "wip/expansion18-preparation".

Previously reported existing code includes:

- Settlement capability composition
- Disabled capability modifiers
- Courier transport
- Formal contract signing

Confirm what is actually implemented and tested.

Existing approved capability principles

- Personal experience and effective capability are distinct.
- Facilities may limit effective capability.
- Facility shortages do not erase earned personal experience.
- Effective capability operates within the approved 0–10 framework.
- Capability must not prevent someone from being eligible for employment.
- Pay and output use effective capability only as approved.
- Existing experience and production systems must remain deterministic.

Do not invent unresolved D2–D9 values.

Do not activate incomplete modifiers.

If a specific settlement requirement is blocked on an owner decision, preserve the work and move to another approved task.

Integration

Do not blindly merge the settlement branch into Build 18.

Review ancestry, compatibility, save changes, and feature flags.

Integrate completed, approved, compatible systems when safe.

Keep unfinished or unapproved behavior disabled.

---

PART 8 — OTHER APPROVED BUILD 18 WORK

Review the authoritative register for independent, approved work.

Candidate areas include:

- Player-owned businesses
- Expandable property
- Modular buildings
- Farming and livestock
- Stonecutter trade
- World Design Rules
- Approved economic systems
- Coin sinks
- Announced taxation infrastructure
- Horse functionality
- Approved world improvements
- Character customization
- Remaining interface fixes

For every task:

1. Confirm its approved requirement.
2. Inspect existing code.
3. Check owner-decision dependencies.
4. Implement only the approved portion.
5. Validate the changed behavior.
6. Commit coherent work.
7. Record status and evidence.

Do not invent requirements from a title.

Do not treat planning work as completed implementation.

Do not reopen settled owner decisions.

---

PART 9 — PRELIMINARY GAME JUICE PASS

The owner has requested an initial game-feel improvement pass.

This is a restrained preliminary pass, not a new gameplay expansion.

Prioritize:

- Responsive input
- Clear action feedback
- Readable progress indicators
- Clear interaction targets
- Reliable confirmation dialogs
- Better visual alignment
- Appropriate feedback for successful actions
- Understandable failure messages
- Consistent controller and touch behavior
- Small improvements to existing animations
- Removal of distracting interface defects

Do not add speculative rewards, progression, economic rules, or new gameplay systems.

Do not prioritize cosmetic polish over broken core interactions.

The game should become more pleasant to play without compromising its simulation.

---

PART 10 — MODEL ROUTING AND CLAUDE USAGE CONTROL

THIS SECTION IS MANDATORY.

The owner previously experienced an unusually expensive development period caused by parallel agents using a higher-cost model at approximately 2.5 times the expected rate.

Do not repeat that mistake.

Use the existing model configuration

Inspect the current development environment, project instructions, worker settings, and newer testing-model setup.

Use the actual established model-routing configuration.

Do not invent model names.

Do not default every worker to the most expensive available model.

Lower-cost models

Prefer for:

- Routine inspection
- Focused tests
- Documentation
- Register updates
- Simple bug fixes
- Asset validation
- Straightforward bounded implementation

Standard development models

Use for:

- Feature implementation
- UI integration
- Save migration
- Normal gameplay fixes
- Existing-system extensions

Highest-capability models

Reserve for:

- Difficult architecture
- Serious determinism failures
- Conservation problems
- Complex integration conflicts
- Problems demonstrably beyond cheaper models

Escalate individual tasks when necessary.

Do not escalate the entire project by default.

Worker spending

Do not launch every possible worker just because workers are available.

Start by preserving and continuing the active inventory worker.

Use additional workers only for genuinely independent tasks with clear acceptance criteria.

Prefer one or two productive implementation workers over a large group of speculative agents.

Avoid file conflicts.

Avoid duplicate investigations.

Do not leave agents repeatedly polling one another.

Do not spend expensive model usage on work that is already complete.

Budget awareness

If the environment exposes reliable remaining usage, inspect it.

Do not pretend to know the owner's account balance if it is unavailable.

Use conservative defaults.

Preserve enough usage for the owner to continue tomorrow.

If usage becomes constrained:

- Reduce parallelism.
- Finish current coherent tasks.
- Commit and checkpoint.
- Stop optional work.
- Avoid starting large new tasks.

A clean stop is preferable to exhausting usage on speculative work.

---

PART 11 — TESTING: MSW-01

MINIMUM SUFFICIENT WORK IS A PERMANENT DIRECTIVE.

Before running a test, ask:

1. What exact code changed?
2. What behavior might be affected?
3. What relevant passing evidence already exists?
4. What is the narrowest test needed?

Use the project's existing newer testing models and established test strategy.

Do not

- Rerun all 3,584 checks after every small change.
- Repeatedly run year-long simulations.
- Rebuild all three platforms after each commit.
- Recheck unchanged systems without reason.
- Launch broad audits simply for reassurance.
- Repeat passing tests against identical source.
- Run multiple workers through the same test campaign.

Do

- Reuse commit-specific passing evidence.
- Run focused tests for changed behavior.
- Validate migration when save logic changes.
- Check conservation when ownership or transactions change.
- Check determinism when simulation behavior changes.
- Investigate actual failures.
- Record relevant evidence with the commit.

Full Build 18 release gate

The complete release gate is still required before an approved release.

It includes applicable:

- Integrated test suites
- Determinism evidence
- Conservation evidence
- Required long-run simulations
- Save migration
- Platform exports
- Device and controller checks

However, do not run the entire gate prematurely.

Run it when the integrated source is sufficiently stable and the evidence will remain useful.

Do not publish Build 18 without owner approval.

---

PART 12 — WORKER EXECUTION STRATEGY

Use a cost-conscious, bounded work cycle.

For each worker:

1. Read the relevant requirement.
2. Inspect only necessary files.
3. Implement a coherent change.
4. Run focused validation.
5. Commit and push.
6. Record evidence.
7. Move to the next approved, unblocked task.

Avoid excessive planning before straightforward implementation.

Avoid repeated full-project summaries.

Avoid long status messages after every commit.

Use concise technical records.

Suggested priority

1. Finish the active inventory implementation.
2. Integrate category capacity, save migration, and equipment separation.
3. Implement tailor services and upgrade purchases.
4. Implement Armour Option A and equipment redraw.
5. Advance approved, unblocked Expansion 18 systems.
6. Advance independent approved Build 18 roadmap requirements.
7. Address genuine gameplay defects.
8. Perform restrained game-feel polish.

Parallelize independent work only when worthwhile.

Do not let a blocked worker stop other workers.

Technical authority

Claude may decide:

- Internal code structure
- Function organization
- Safe refactors
- Existing art selection where approved
- Focused test selection
- Branch integration sequence
- Implementation details consistent with approved requirements

Claude may not decide:

- New economic policies
- Unapproved simulation rules
- New combat balance
- New progression mechanics
- Changes to owner-approved design
- New item classes or production chains
- Deferral of approved Build 18 scope
- Release publication

If an owner decision is required, record it and continue elsewhere.

---

PART 13 — BRANCH SAFETY

Build 17 remains frozen at "cd7439c".

Do not modify or rebuild it.

Build 18 integration occurs on "wip/build18".

Use isolated branches for overlapping or risky work.

Before integrating:

- Verify branch ancestry.
- Check for uncommitted changes.
- Preserve worker modifications.
- Review dependencies.
- Check approved scope.
- Run necessary focused validation.
- Commit coherent results.

Do not overwrite another worker's files.

Do not merge incomplete settlement mechanics merely to show progress.

Do not contaminate the frozen Build 17 baseline.

Do not release anything overnight.

---

PART 14 — CONTEXT AND COMPACTION RECOVERY

The owner's Claude conversations have consistently compacted around 80% context utilization.

Do not wait until the context is nearly full.

At approximately 70–75% context usage, prepare a recovery checkpoint.

Record:

- Current branch heads
- Uncommitted changes
- Active workers
- Completed requirements
- Open requirements
- Owner decisions
- Test evidence
- Known blockers
- Exact next actions

Preserve uncommitted worker changes safely without disrupting active work.

Update the current recovery handoff and state pointer.

After compaction:

1. Read the recovery handoff first.
2. Verify current branch state.
3. Resume the exact approved work.
4. Do not reopen answered questions.
5. Do not repeat completed investigations.

Keep handoffs concise but complete enough to resume safely.

---

PART 15 — OVERNIGHT STOP CONDITIONS

Continue productive, approved work while the session and usage budget allow.

If a task is blocked:

- Record the issue.
- Move to another approved task.

If integration is unsafe:

- Preserve the task branch.
- Record the dependency.
- Continue elsewhere.

If remaining usage is becoming constrained:

- Stop speculative work.
- Finish and save current tasks.
- Prepare recovery notes.

If no approved, unblocked implementation remains:

- Perform useful targeted planning only where necessary.
- Do not invent work to occupy time.

If further work has low value relative to its model cost, stop cleanly.

The owner values completed, working features more than maximum agent activity.

---

PART 16 — MORNING HANDOFF REPORT

When the owner returns, provide a concise executive summary followed by a detailed factual report.

Include:

Development

1. Starting and ending branch commits.
2. Features implemented.
3. Features integrated into Build 18.
4. Features tested.
5. Work remaining on task branches.
6. Active and blocked workers.
7. Important defects fixed.
8. Any simulation integrity concerns.

Build 18 status

9. Updated completion estimate using the same full combined scope as the earlier 30–40% estimate.
10. Completed, partial, active, and not-started requirement counts.
11. Remaining critical path.
12. Outstanding owner decisions in dependency order.

Testing

13. Tests actually run.
14. Existing evidence reused.
15. Tests deliberately avoided under MSW-01.
16. Save migration status.
17. Conservation and determinism status.

Claude usage

18. Models actually used, if observable.
19. Number of workers started.
20. Work completed per worker.
21. Any usage limits encountered.
22. Any avoidable duplicate work discovered.
23. Whether unfinished work was safely checkpointed.

Do not invent token counts or account balances.

Clearly distinguish:

- Implemented
- Integrated
- Tested
- Owner-playtested
- Release-ready

Do not claim owner playtesting occurred while the owner was away.

---

FINAL OWNER DIRECTIVE

Build 18 stays combined.

Inventory decisions are closed.

The approved inventory progression is:

9 → 18 → 27 slots per category.

The tailor sells the two upgrades for:

150 coins and 450 coins.

Armour Option A is approved, with existing statistics remaining provisional.

Multiplayer is excluded from Build 18.

Continue approved settlement and broader Build 18 work.

Use existing systems wherever possible.

Use the established newer testing models.

Use the least expensive capable development model.

Limit unnecessary parallel agents.

Reuse valid passing test evidence.

Avoid repeated simulation campaigns.

Checkpoint before the approximately 80% compaction threshold.

Preserve Build 17.

Do not publish a release.

Do not invent unapproved gameplay rules.

Make the most useful progress possible without exhausting my Claude usage before morning.

A VILLAGE IS ALLOWED TO FAIL. THE SIMULATION IS NOT.

Proceed autonomously on approved, unblocked work. Do not wait for additional owner input.
