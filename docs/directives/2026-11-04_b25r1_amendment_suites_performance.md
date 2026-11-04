# Owner amendment, 2026-11-04: Build 25 Revision 1, integrated test failures and simulation performance

Saved as received (condensed formatting only). Supplements the 2026-11-04 "Parallel Repair, GitHub Validation, and Early
Access Packaging" directive. Register: EA-01, B25R1-015.

---

Do not stop, restart, or redirect the agents already working.

1. Four failing integrated test suites (run 41872740140). Do not assume the five defect repairs resolve them. After merging
   the three repair branches: identify all four suites by exact name; determine each original failure cause; compare each
   against the agents' repairs; run the relevant tests on the final integrated commit; verify all four are resolved;
   document the specific fix and passing evidence for each. If any failure remains, find its root cause and repair it. Do
   not weaken assertions, skip tests, suppress errors, or call a failure harmless without evidence. Acceptance: all four
   have documented resolutions and passing validation.

2. Simulation performance regression (about 73 minutes, then over GitHub's 120-minute limit). Agent 3 continues comparing
   f60772f and 2677ea7. Required: a controlled comparison (same seeds, workload, configuration, comparable environments);
   the specific code changes responsible; measurements before and after correction; proof the improvements do not change
   deterministic outcomes; the flight recorder still nonintrusive; a successful full simulation check on the integrated
   commit. Do not raise the timeout or reduce the workload. Quantify runner variability separately from code performance.
   Acceptance: the simulation completes, its performance is understood and any genuine regression is corrected.

3. GitHub validation strategy. After integration: run independent suites concurrently; run the flight-recorder regression
   independently; run performance comparisons in parallel where appropriate; start the full simulation check once its fixes
   are integrated; begin the approved 365-day twin campaign only after its prerequisites pass. Do not serialize independent
   work. Every run names the commit SHA, duration, test counts and artifact or log evidence. Reuse valid passing evidence
   when code and conditions are unchanged.

4. Packaging remains locked until: the five defects are fixed and proven; the four suites are resolved; the performance
   regression is investigated and corrected where necessary; the flight-recorder regression passes; the full simulation
   check passes; the new baseline is established with all differences explained; the 365-day twin campaign passes. Then the
   four authorized Early Access candidate packages: Windows full, Linux full, Windows Steam demo, Linux Steam demo, using
   the existing DEMO-01 configuration subject to verification against the approved demo requirements.

5. Resource budget: the 3-percentage-point Claude usage budget is unchanged. No additional agents and no restarted
   investigations. Use GitHub Actions for expensive work; keep reporting concise. If the budget is exhausted, preserve all
   work in GitHub and report the remaining blockers; never claim completion without evidence.

6. Reporting when the three agents finish: the five defects (fixed and verified versus outstanding); the four suites (exact
   names and results); simulation performance before and after; the flight-recorder regression result; the full simulation
   check result; the 365-day twin campaign result; the final integrated SHA; the remaining release blockers.

"Continue automatically within the authorized scope. The objective is not merely green GitHub checks. It is verified
correctness, restored performance, deterministic simulation, and four trustworthy Early Access candidate packages."
