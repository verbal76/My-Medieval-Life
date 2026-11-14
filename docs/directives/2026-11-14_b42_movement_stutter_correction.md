# FORGE MY LIFE — BUILD 42 MOVEMENT STUTTER INVESTIGATION AND CORRECTION

Owner directive, 2026-11-14 (faithful structured record; full text in the lead session transcript; quotes verbatim).
"This is an active engineering assignment, not a status audit." Owner's firsthand experience: "I started in the main
village. I headed south, following the trails. After traveling far enough, movement began repeatedly stuttering. The
character would advance, briefly freeze, advance again, and freeze again." Other directions untested; "Do not assume the
problem is exclusive to southbound travel." First priority: reproduce that exact behaviour (seed, coordinates, route,
elapsed time, distance, where the stutter first appears; if the original save is unavailable, a reproducible equivalent
clearly distinguished). Review existing work and the Build 41 tunnel and tile fixes; "Do not confuse preventing movement
through walls during a frozen frame with eliminating the freeze itself." Instrument: frame-time spikes and frequency,
render and simulation durations, main-thread blocking, memory and allocation, GC, terrain generation and tile loading,
NPC updates and pathfinding, autosave and persistence, periodic work; when it first appears and whether it worsens;
correlation with location, distance, elapsed time, accumulated state; compare south with at least one other direction.
Root cause by controlled experiments; document rejected hypotheses; coordinate with Agent M (KI-08) without duplicating;
do not assume the leak causes it unless profiling shows it. For each confirmed cause: failing case, root cause and
measurements, smallest reliable correction, regression coverage failing before and passing after, measured improvement,
movement/collision/terrain/NPC/determinism/multiplayer/saves verified, exact SHA. Completion test: start in the main
village, travel south along the trails beyond where the stutter occurred, before/after frame times under equivalent
conditions, number and severity of spikes (not just average FPS), repeated, another direction, "Confirm that the
correction addresses visible movement freezes rather than merely masking them through frame-time clamping." If headless
cannot establish visual smoothness, say so and prepare a focused playable build through the normal authorized build
process. Work independently, isolated branch, inexpensive local experiments, no expensive Actions or full-year sims, no
independent merge or release; provide the integration agent with commit, files, tests, measurements, conflicts. Report:
tracking id and owner, reproduction route/seed/coordinates, confirmed causes, rejected hypotheses, corrections and SHAs,
before/after frame times, tests, effects on other systems, integration readiness, remaining symptoms or blockers.
"Do not declare this issue complete simply because code compiles or unit tests pass." Escalate only genuine design
decisions, significant risks, expensive testing, or release/integration authorization.
