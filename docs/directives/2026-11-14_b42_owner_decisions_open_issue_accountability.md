# FORGE MY LIFE — BUILD 42 OWNER DECISIONS AND OPEN-ISSUE ACCOUNTABILITY

Owner directive, 2026-11-14. Faithful structured record (full text in the Build 25 lead session transcript); quotes verbatim.

A. Approved owner decisions
1. REG-08 courier refunds: "Approve the existing refund cap. Refund only the coins actually held by the payer's heir.
   Never create currency to complete a refund. Record any unpaid shortfall so it remains visible and auditable."
2. Multiplayer household pantry privacy: "Household pantry information is private by default. Other players may access
   it only through explicitly authorized sharing permissions. Preserve legitimate household access and verify behavior
   across multiplayer sessions, reconnects, and save/load."
3. Release workflow, exact-commit verification: "Require all mandatory release tests to pass against the exact commit
   SHA used to produce the release packages. Failed, skipped, missing, or incomplete required tests must block release.
   Reuse valid results for the exact SHA rather than running expensive duplicate tests."
B. Newly identified defects
4. Demo overwrites full-game saves: a player-data protection defect; investigate the shared save-directory design and
   all affected save/load paths; the safest solution that prevents unintended overwrites while preserving legitimate save
   compatibility and any intended demo-to-full-game progression; implement after establishing the required behaviour;
   regression tests for coexistence, new games, Continue, save migration and existing saves; "Do not delete or overwrite
   existing player data during testing."
5. Android packages built with debugging enabled: investigate why; separate development/test and production-release
   configurations; production packages with release settings, correct identifiers and signing continuity, verified before
   publication; "Do not rotate signing keys or publish packages without authorization."; a release gate that detects an
   incorrectly configured Android production build.
C. Additional observations
6. Demo window title lacks "Demo": correct where appropriate; verify full and demo identities stay distinct.
7. Character creation Begin button sometimes needs a second click: reproduce, find the actual cause, correct, focused
   regression coverage; "Do not dismiss it as intermittent without investigation."
8. Memory leak KI-08 / D1: Agent M continues; reproduced failure, identified retaining references, verified correction,
   repeated Continue-cycle measurements; no duplication.
9. Movement step-stutter: confirm tracking id, owner, status, evidence; "Do not assume it is caused by the memory leak.";
   if unassigned, identify the workstream or propose ownership; verify the actual movement behaviour before closing.
10. Integration and release gates: keep the 33 blocking findings visible until each is reconciled against the current
   integration line; rerun the recorder suite killed for lack of memory, not counted as passing; confirm the stream-fix
   regression tests and multiplayer two-process tests are in the required CI gates.
D. Accountability: for every issue report tracking id, agent or workstream, root cause or status, correction and commit,
   regression tests and results, integration status, remaining blockers. Use existing agents where practical; avoid
   duplicate investigations and unnecessary expensive CI. No completion because code was written, a test added or an
   agent reported success. Do not silently defer, dismiss or remove an issue. Genuine design decision or significant
   compatibility risk: investigate alternatives and bring a recommendation. Continue Build 42; do not release or merge
   unverified changes. Return a concise accountability report.
