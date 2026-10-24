Owner directive, 2026-10-24, verbatim.

MY MEDIEVAL LIFE — OVERNIGHT BUILD 20 DELIVERY DIRECTIVE
OWNER PRIORITY: I want Build 20 complete and ready for playtesting when I wake up.
Build 20 is already in final validation. Finish it tonight.

1. Complete the current development agent's final tests and independently review its changes.
2. Resolve any actual release-blocking defects, including invalid determinism baselines, simulation integrity problems, and broken gameplay.
3. Preserve the previously approved Build 20 exception to SIM-GATE-01. Do not delay Build 20 waiting for the new flight-recorder or Excel pipeline.
4. Continue SIM-GATE-01 development independently on wip/sim-gate. Do not merge unfinished simulation infrastructure into Build 20.
5. Do not introduce unrelated features, new gameplay systems, or major architectural changes into Build 20.
6. Run the existing required verification:
   * Full applicable test suite
   * Determinism
   * Money and item accounting
   * Save/load integrity
   * Platform build checks
7. If verification passes, package:
   * Android APK
   * Windows playable ZIP
   * Linux playable ZIP
8. Use the same verified commit and Build 20 number across all three platforms.
9. The previously authorized disposable Android signing key is permitted for Build 20 only. Do not delay this build to establish permanent signing.
10. Prepare the private draft release with checksums and verification results. Clearly disclose that Build 20 predates the mandatory SIM-GATE-01 release gate.
11. Do not request additional owner approval for routine work already authorized.
12. If a genuine release blocker remains, continue investigating and repairing it. Do not fabricate test success or package a known-broken release.

Morning deliverable: A complete, playable My Medieval Life Build 20, with the private release location, commit, platform packages, and verification summary.
The next build must use the permanent simulation and Excel gate. Build 20 must not be held hostage by that separate development effort.
