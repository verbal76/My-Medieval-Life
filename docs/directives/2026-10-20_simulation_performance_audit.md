# Owner directive, 2026-10-20: simulation performance audit and optimization

Relayed verbatim from a separate read-only monitoring session (session_01QtY89XhsHj9UUUWPsvq5NX, 02:19 UTC). The owner confirmed it in this session the same day ("Yes, I authorized the simulation performance audit directive forwarded by the independent read-only Claude session"; `docs/directives/2026-10-20_build15_followup_performance_clarification.md`). Register: PERF-01..05.

---

OWNER'S DIRECTIVE: SIMULATION PERFORMANCE AUDIT AND OPTIMIZATION (approved work, lower priority)

Priority order (owner): 1. finish the ongoing Build 15 simulations; 2. resolve the EQ-07 construction-completion bottleneck; 3. finish the housing corrections and their regression tests; 4. establish the current performance baseline; 5. small, measured, low-risk optimizations; 6. recheck performance and determinism after each change. Don't interrupt running simulations or delay the housing work for this. Documentation, tests and profiling setup may be prepared alongside, provided they don't interfere.

1. Record the audit (below) in the development docs and register a performance task. Find out why runtime has grown since LONG_RUN_SIMULATION.md recorded 365 days in 530–689 s: new systems, a bigger population, resource contention, the execution environment, or something else.
2. Profile before optimizing, on a representative 10-day run. Record wall-clock time, CPU where available, population, animal counts and the time spent in: npc_brain decisions, _run_plan, movement and pathfinding, fauna.gd, hourly world processing, daily world processing, harness sampling and validation, and anything else that turns out expensive. Don't treat the suspected bottlenecks as proven.
3. Investigate:
   - the NPC-population scans in npc_brain.gd: could maintained indexes or caches (relationships, jobs, households) replace them with decisions unchanged?
   - wildlife: array duplication, animal-to-animal searches, predator detection, repeated graze and population counts, linear searches through area cell lists, other safe caching;
   - GameData.b() calls in hot loops (driven by the profile);
   - whether the expensive Living Forest tree growth / solidity checks have reached staging (only if relevant).
4. Parallel seeds: test two seeds running at once as separate Godot processes against the same two run back to back. Each process must have its OWN save data, temp files and output paths. A test failure has already happened from two processes writing the same save files; don't repeat it. Check that contention doesn't make the parallel runs slower or less reliable.
5. Fidelity is mandatory:
   - no bigger STEP;
   - no disabling NPCs, wildlife, movement, pathfinding or the economy;
   - no simplified shortcuts around gameplay rules;
   - keep the ledger checks;
   - don't change random-number consumption or execution order without understanding the consequences;
   - stay deterministic.
6. Determinism gate: record baseline fingerprints first. After each optimization, compare the same seeds at 10 and 30 days: identical fingerprints, population and households, inventories and resources, animals and deposits, treasury and currency, zero unexplained leaks, no new failures. If an outcome changes, find out why; never accept a speed-up that silently changes behaviour.
7. Preserve work on staging or a WIP branch, following the existing test and promotion gates.
8. Report:
   1. measured runtime for 10, 100 and 365 days (measured vs estimated);
   2. time per subsystem;
   3. bottlenecks ranked by measured cost;
   4. recommended optimizations and their risks;
   5. before/after runtimes;
   6. fingerprint comparisons;
   7. parallel vs sequential results;
   8. problems that will grow at 250, 500 or 1,000 villagers;
   9. the commits.
   Report any measurement you couldn't take as pending. Don't run full-year benchmarks that would interfere with Build 15.

READ-ONLY AUDIT FINDINGS (staging 4627531; "verified" = read in code or docs, "hypothesis" = not measured)

Verified:
- game/tests/economy_sim.gd extends SceneTree and runs headless. _init() loops w.update(STEP); there is no await, timer or _process, and no rendering (World.new() is never added to the tree).
- STEP = 0.5 and game_minutes_per_second = 2.0 give one game minute per step and 1,440 steps per day: 144,000 for 100 days, 525,600 for 365.
- The near/distant NPC split (world.gd update, around lines 250–258, detail_radius 34) does nothing in the harness: at a 0.5 s step the distant tier also updates every step.
- Every step: hunger and _run_plan for each NPC (brain.decide only when the plan is empty); _walk while moving; fauna.tick over animals.duplicate(); fauna.update, which duplicates the array again, and _move for animals within 34 tiles of the idle player (much of the village); carts; the player.
- Pathfinding: VillageMap.find_path uses AStarGrid2D (native code), once per "go" step.
- Hourly (_on_hour): _grow_trees, _update_food_days (scans every NPC inventory and pantry), serve_tables, relations.hour, fields. Daily: _new_day, reeve_day, pay_guards, caravan.
- Harness: _hourly every 60 steps; _sample, _growth and one printed line every --every days (default 1); the JSON written once at the end. The ledger and fingerprint (_fingerprint) already exist and make the natural determinism gate.
- The docs say the old runs went one after another on a 4-core container.

Hypotheses (unmeasured):
- npc_brain.gd has 39 loops over w.npcs, so decisions likely grow with population squared.
- fauna.gd:
  - the predator loop in _move (around line 613) compares every animal with every other;
  - count() and grazers() scan all animals, per hungry animal (tick, around line 160);
  - cells(area) returns an Array, and .has() on it is a linear search (lines 330 and 648) over woods_w 616 cells and woods_e 408 cells. Keeping the Array for iteration and adding a Dictionary set for membership gives the same answers.
- About 160 GameData.b() calls in world.gd, npc_brain.gd and fauna.gd, many per NPC per step.
- On wip/agent-aabfa7824abfa5174, Trees.sync inside overworld.is_solid took overworld_test from about 1 minute to timing out after 9 minutes. Check whether any of it reached staging.
- Parallel seeds are the one speed-up guaranteed not to change results: close to N times faster for N seeds, up to the core count. It still needs measuring, with isolated paths.
