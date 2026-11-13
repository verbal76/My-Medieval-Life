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

## Follow-up: Build 40 pre-stream investigation directive (owner, 2026-11-13; summary)

Continue the four investigations without restarting or duplicating. Worker A: account for all 31–32 baseline differences
against the chain 12 changes, separate expected from regressions, examine Q33 and MEASURE the proposed correction "reserve =
max(80, trailing 10-day purchases)" before recommending it; verify all 19 runs for currency and item conservation,
determinism and script errors; never auto-accept or re-record a baseline. Worker B: reproduce the seed 6 day 20 births and
arrivals mismatch (19 recorder vs 18 simulation), identify the person and event, classify (reporting disagreement, lost or
duplicated population, corrupted state), trace the responsible change, correct, regression test, run the exact failing
scenario; "Do not dismiss a mismatch merely because it involves one person." Worker C: packaged Linux build: launch, new
game, save and load, Continue, progression, script errors, crashes or corrupted saves, presentation; whether memory
growth, Continue hitches or micro-freezes materially interfere; check the displayed title (Build 40 is from a5a0b7c,
before the rename); PLAYABLE / PLAYABLE WITH LIMITATIONS / UNSAFE. Worker D: classify every unresolved Build 25 issue as
STREAM BLOCKER / IMPORTANT / NONBLOCKING, which affect Build 40, recheck rather than carry forward. Integration: reconcile,
low-risk corrections on dedicated branches, targeted tests first, Build 40 preserved unchanged as fallback, no full CI only
to reproduce known baseline failures, no merges to protected branches or publishing, gate stays strict. Stream decision:
compare Candidate A Build 40 a5a0b7c and Candidate B b3c9eb5; if the population mismatch is a real integrity defect, do not
recommend the affected build until its impact is understood. Report immediately when the population discrepancy is
explained, a stream blocker is found, the packaged gameplay test completes, or a stream build can be recommended with
confidence; then continue the economy, simulation and performance work.
