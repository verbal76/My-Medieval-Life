# FORGE MY LIFE — BUILD 42 INTEGRATION DIRECTIVE: resolve all five regressions and protect player data

Owner directive, 2026-11-14 (faithful structured record; full text in the lead session transcript; quotes verbatim).
"The combined integration line a9bb852 is NOT an approved Build 42 candidate." Agent Q investigates and corrects the two
failing suites; Agents F and G continue in parallel.
1. Private records (2 of 85 fail): players keep full access to their own household records and pantry; married players
   in the same household keep household access; "Household membership grants access independently of asset-sharing
   tiers"; outsiders restricted by the approved sharing rules; reconnect, save, load or membership change must not
   improperly grant or revoke access. Exact commit and code path; failing-first tests; other privacy protections intact.
2. Newer-version save protection (3 start_test failures): "Treat this as a potential player-data-loss defect until proven
   otherwise." A newer-version save "must never be overwritten, modified, truncated, deleted, or silently replaced by an
   older version." Investigate startup load and version checks, background autosave, manual save, demo save slots,
   shutdown and recovery, failed-load and retry; test the background-autosave race. While an unsupported newer save is
   present every write path affecting it stays blocked; any permitted new save uses a separate, non-destructive location;
   byte-for-byte comparisons before and after load, autosave, shutdown and restart.
3. Standards for each failure: reproduce reliably; first offending change; defect vs wrong test; fix the cause; failing-
   first tests; independent verification; no deterministic or gameplay regressions. No weakening, suppressing, baseline
   changes or exceptions; contradictions with requirements go to the owner.
4. Rerun after corrections: all 85 private-records checks; full start_test; stall management; pantry privacy and asset
   sharing; two-process multiplayer; save/load and autosave; demo save slots; reconnect and household membership; the
   10-day simulation against the approved reference, every difference investigated. Targeted local tests first.
5. Parallel: F continues; G continues the watchdog; Q owns the regressions; coordinate shared files. "Do not merge
   unfinished Agent F or G work into the integration line merely because Agent Q's corrections pass."
6. Governance: preserve a9bb852 as the failing reference; keep Q's corrections isolated until verified; no candidate status
   while any failure remains; no CI, packages or releases without authorization; no baseline re-recording; no unrelated
   gameplay changes.
7. Report: root cause per group, commits, tests and corrections, before/after counts, byte-for-byte save evidence,
   reconnect and household-permission verification, 10-day comparison, remaining risks, integration recommendation and
   exact source commit. Completion: all five failures resolved, suites pass, player data protected, ready for owner review.
   "Do not interpret this directive as authorization to merge, package, or release Build 42."

Lead record: the failing reference is preserved as branch wip/b42-integration-a9bb852-failing-ref (a9bb852).
