# FORGE MY LIFE — EMERGENCY PRE-STREAM SIMULATION GATE AUDIT

Owner directive, 2026-11-13, received in the Build 25 lead session. Summary of the owner's text (the full message is in
the session transcript): CRITICAL, Extra Life stream in about 7 hours. Two Build 25 release attempts (runs 43362745451,
Build 40, and 43321404909) built all six packages and passed the Windows smoke tests but were rejected by SIM-GATE-01.
Phase 1: retrieve the gate logs, reports and artifacts; identify every failing condition, whether both runs failed for the
same reasons, whether each failure is a gameplay defect, simulation regression, baseline difference or gate
implementation defect, whether any threatens a live demonstration, and the minimum legitimate correction. "Do not assume
the gate itself is defective." Phase 2: Workers A (gate logic and acceptance criteria), B (simulation results,
conservation, determinism, baseline differences), C (package readiness, startup, save/load, stream-critical gameplay),
D (unresolved Build 25 defects likely to affect a live playthrough), concurrently, no duplicate work. Phase 3: classify
every issue BLOCKER / IMPORTANT / NONBLOCKING; "A gate failure is not automatically nonblocking just because the game
launches." Phase 4: fix confirmed defects in priority order: no disabling or weakening simulation gates, no automatic
baseline re-recording, no hiding failures, no unrelated features, no unnecessary refactoring, preserve a known-good
fallback build, targeted tests first, verify against the exact failed conditions; "Do not launch another full CI campaign
until the cause is understood and a corrected candidate is ready." Phase 5: distinguish (1) a fully verified Build 25
candidate, (2) a playable but not release-qualified Build 25 preview, (3) a previous verified build suitable for tonight;
a private stream preview may be considered separately from a public release, but significant simulation defects must be
disclosed and assessed. First report as soon as the two gate failures are diagnosed: exact gate failures, root causes and
evidence, number of blockers, estimated correction and verification time, recommended stream build, whether a full CI
rerun is necessary. "Owner priority: A stable, playable Forge My Life demonstration tonight—not an artificial green CI
result." "Do not publish, merge into protected branches, or dispatch expensive workflows without authorization."
