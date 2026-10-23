# Owner directive, 2026-10-21: simulation monitoring, check-ins and run protection (SIM-02; summary with the owner's words for the rules)

Permanent; supplements SIM-01; applies to Build 17, Expansions 18 and 19 and future builds.

- "Do not cancel, restart, reset, redispatch, or replace any active simulation simply to check its progress or improve
  reporting." Reading GitHub Actions status, logs and completed artifacts must be non-destructive. "Do not change the code
  underneath a running test." "Do not launch duplicate runs because the current jobs have not reported recently."
- If a run appears stalled, investigate without interrupting it. Before any restart, report why it appears stalled, the
  progress made, the estimated time to completion, the time saved by restarting and the evidence at risk, and "Obtain my
  explicit approval before manually canceling or restarting an active simulation." The exception is an existing automated
  fail-fast that stops a run on a genuine simulation defect.
- Continuous validation under SIM-01 (coin and goods conservation, invalid states, duplicate transactions, broken
  production or transport invariants); checkpoints at the relevant days; stop only on established fatal conditions, never
  on legitimate village failure. "A VILLAGE IS ALLOWED TO FAIL. THE SIMULATION IS NOT."
- Check-ins: "Do not schedule the first status review hours after simulations are expected to finish." Check dispatch and
  runner assignment promptly, check near the expected finish, then about every 10-15 minutes while active; retrieve and
  report results promptly; prefer completion events and low-cost status over polling; no busy-wait loops; "A scheduled
  check-in must not delay analysis of results already available." If the environment cannot monitor continuously, "state
  that limitation accurately".
- Keep SIM-01's single long run per seed and configuration; no new tests because monitoring changed; do not restart the
  Build 17 MIN-G runs, repeatable-results testing or CI.
- "Observe the work. Preserve the progress. Report the results. Do not repeat completed work."
