# Owner directive, 2026-10-24: multiplayer implementation readiness

Saved verbatim from the session.

---

MY MEDIEVAL LIFE — MULTIPLAYER IMPLEMENTATION READINESS DIRECTIVE
The multiplayer preparation report and updated decisions at staging commit `a7d88aa` are accepted.
The architecture, MP-D1 through MP-D8, MP-ARCH, MP-INET, and verification gates G0–G10 are approved as the development requirements.
1. Development Priority
The approved sequence remains:
Build 19 acceptance → Multiplayer implementation → Expansion 20 → Remaining expansions.
Multiplayer is the next development milestone. Do not allow it to be silently deferred, excluded from reporting, or replaced by unrelated expansion work.
2. Build 19 Protection
Build 19 remains frozen pending my playtest acceptance.
Do not modify its release artifacts, approved simulation baseline, or existing gameplay to prepare multiplayer.
Do not begin multiplayer implementation until I explicitly accept Build 19 and authorize Batch A.
3. Implementation Strategy
Once authorized, implement multiplayer using the approved A–F batches.
Use one primary development agent unless independent work clearly justifies additional agents.
Implement related changes together and use targeted testing at meaningful checkpoints.
Do not rerun the entire expensive simulation suite after every minor adjustment.
For verification gate G0:

* Run focused single-player regression tests throughout each batch.
* Run the complete Build 19 regression and determinism baseline at major integration checkpoints.
* Run comprehensive validation before release.
* Any change affecting simulation rules, resource conservation, or save integrity requires appropriate additional validation.

Never weaken a test merely to obtain a passing result.
4. Architectural Requirements
Maintain one host-authoritative simulation supporting multiple fully participating player characters.
Preserve the existing single-player gameplay experience.
Every connected player must use the same gameplay systems, including survival, economics, property, crafting, construction, combat, crime, relationships, family, and succession.
Guest characters must not be restricted to movement and basic interactions.
Preserve permanent identities, world-specific characters, persistence, and ownership.
5. Cross-Platform Requirements
Android, Windows, and Linux must each support hosting and joining.
Steam Deck must be validated separately.
Complete the nine-way platform compatibility matrix.
Validate real devices, not only simulated clients.
Internet multiplayer across separate networks is mandatory. LAN-only functionality or a virtual-LAN workaround is insufficient for final acceptance.
Do not introduce paid networking services without my authorization.
6. Approved Multiplayer Decisions
Implement MP-D1 through MP-D8 exactly as recorded at `a7d88aa`.
Do not reinterpret or simplify them.
Pay particular attention to:

* Shared resting and time acceleration.
* Menus that do not pause multiplayer.
* Death and player-selected succession.
* Disconnected character persistence.
* Android host interruption and recovery.
* Newcomer character creation.
* Mutual consent for player-to-player interactions.

7. Verification and Reporting
Maintain G0–G10 as mandatory acceptance gates.
Each gate must record the tested build, devices, operating systems, network conditions, results, and unresolved limitations.
Automated tests must not be reported as successful physical-device tests.
Every status report must identify:

* Completed implementation batches.
* Current verification results.
* Outstanding defects.
* Unresolved owner decisions.
* Platform limitations.
* Remaining work before multiplayer acceptance.

Do not claim multiplayer is complete until all mandatory acceptance requirements are satisfied.
8. Immediate Execution
For now:

1. Confirm that all approved multiplayer decisions and verification gates are correctly recorded.
2. Confirm that Build 19 remains unchanged.
3. Confirm that the old multiplayer prototype is preserved.
4. Confirm that the roadmap places multiplayer immediately after Build 19.
5. Identify the exact starting point for Batch A once authorized.
6. Do not start implementation, additional agents, release workflows, or builds.

Once these checks are complete, stop and report readiness.
Do not request another round of architectural planning unless a genuine unresolved technical dependency requires an owner decision.
The objective is to move directly into implementation after Build 19 acceptance, not continue producing planning documents indefinitely.
