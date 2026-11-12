# Owner directive, 2026-11-12: Chain 10 follow-up (integration, multiplayer security, player journey, final packaging)

Received in the lead session at about 13:45 EST. Saved as received; never edited. Summary of its binding points, in the owner's words where quoted:

- Recover status from the repository and GitHub Actions; "Do not restart completed work, duplicate existing tests, or launch unnecessary workers."
- Complete the three active worker assignments:
  - Worker 1, ND-20 multiplayer guest trust: "Verify that guests cannot manipulate host-owned state, impersonate other players, bypass authorization, or perform actions beyond their permissions. Preserve legitimate multiplayer interactions and existing gameplay rules."
  - Worker 2, MP-07 private records: "Ensure guests receive only information they are authorized to access", including through snapshots, synchronization, reconnection and save/load, "Do not break information that should legitimately be shared".
  - Worker 3, the player journey through the full game and the demo on the Chain 10 candidate. It reports findings independently rather than silently changing gameplay code.
- Integrate Chain 10:
  - Review each change, resolve conflicts without discarding functional changes or weakening security.
  - "Preserve the existing approved multiplayer rules, including independent player interactions and mutual agreement where cooperation or hostile interaction requires consent."
  - "Do not assume that a passing Chain 10 baseline validates changes merged afterward"; run regression and integration tests on the final combined commit.
- Verify on the integrated candidate (ten areas):
  - multiplayer authorization and guest security;
  - private information isolation;
  - host and guest synchronization;
  - join, leave and reconnect;
  - save/load;
  - full-game progression;
  - demo progression and termination;
  - economy and simulation integrity;
  - determinism and conservation;
  - packaging prerequisites.
  For every failed or skipped test, investigate the cause; no automatic baseline re-recording.
- Resources:
  - Keep the four-agent limit; no more agents without approval.
  - Avoid out-of-memory and monitor RAM; preserve active workers' uncommitted changes.
  - Remove temporary worktrees only once clean and preserved.
  - Prefer local targeted tests; avoid duplicate CI.
  - "Do not interpret this directive as authorization for unlimited additional CI runs."
- Packages: after the gates pass, prepare the established release-package matrix and verify each package:
  - correct commit;
  - full or demo content;
  - launch;
  - save compatibility;
  - version and build identity;
  - no development tools or private assets.

  Keep the Steam preparation requirements. "Package preparation is authorized after successful verification, but do not publish publicly, upload to Steam, or merge protected branches without explicit owner approval."
- Update the recovery, history, working-state, decision and known-issues documentation, with the reasons, SHAs, Eastern Time timestamps, evidence and limitations.
- Report:
  - Chain 10;
  - the workers;
  - multiplayer;
  - the player journey;
  - integration;
  - packages by platform and edition;
  - remaining work.

  "Do not report completion based solely on green CI status."
