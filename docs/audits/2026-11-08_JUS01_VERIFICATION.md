# JUS-01 — Runtime-reproduced defect and isolated correction

**2026-11-08 UTC.** Audited source `fe7d8f88bf5df77ce7e6ea601d6abc62eed13122`. Branch `audit/jus01-guard-death-20261108`.

**Original problem and correction:** World.kill now calls the existing justice.release for a dying NPC with a pursuit, removing dead guards from active case records while keeping unresolved crimes wanted.

**RED:** https://github.com/verbal76/My-Medieval-Life/actions/runs/42506631586 — **6 checks, 3 failures** on original production code with focused regression test.

**GREEN:** https://github.com/verbal76/My-Medieval-Life/actions/runs/42506737179 — **6 checks, 0 failures**, correction commit `f9c4679293460a0021ebb30af116475dd5abfc7a`. Same focused test and one-runner workflow.

Regression: `game/tests/jus01_dead_guard_pursuit_test.gd`; standard test suite registration and minimum check-count floor 6 added.

**STATUS: REPRODUCED AND CORRECTED IN DRAFT PR ONLY. NOT MERGED/CLOSED.** Broader relevant suites, multiplayer/integration tests, and determinism/simulation gates need exact-SHA verification before merging. No baseline changes or Claude Console usage. Temporary branch-specific workflow removed from final PR changes.
