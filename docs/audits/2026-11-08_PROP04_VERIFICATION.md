# PROP-04 — Runtime-reproduced defect and isolated correction

**2026-11-08 UTC.** Audited source `fe7d8f88bf5df77ce7e6ea601d6abc62eed13122`. Branch `audit/prop04-guest-house-name-20261108`.

**Original problem and correction:** World._finish_site now derives the completed building name from the site-owner PlayerState (by reference), rather than the current default host actor when a helper completes a guest's house.

**RED:** https://github.com/verbal76/My-Medieval-Life/actions/runs/42506634010 — **5 checks, 2 failures** on original production code with focused regression test.

**GREEN:** https://github.com/verbal76/My-Medieval-Life/actions/runs/42506716192 — **5 checks, 0 failures**, correction commit `d29dd50038d6a95b3e1f9770c73e19aeb0369ab2`. Same focused test and one-runner workflow.

Regression: `game/tests/prop04_guest_house_name_test.gd`; standard test suite registration and minimum check-count floor 5 added.

**STATUS: REPRODUCED AND CORRECTED IN DRAFT PR ONLY. NOT MERGED/CLOSED.** Broader relevant suites, multiplayer/integration tests, and determinism/simulation gates need exact-SHA verification before merging. No baseline changes or Claude Console usage. Temporary branch-specific workflow removed from final PR changes.
