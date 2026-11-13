# FORGE MY LIFE — OWNER ENGINEERING DIRECTIVE: Build 41 → Build 42

Owner directive, 2026-11-13. Faithful structured record (the full text is in the Build 25 lead session transcript); quoted
lines are verbatim. Title: "Complete the Audit, Parallelize Development, Establish The Ark, and Deliver an Internally
Verified Game". Supplements the Build 41 directive; "Do not restart, discard, or duplicate work already underway."

1. Preserve Build 41: wip/b41-stream-candidate 0bbee94, packaging run 43527275522, Agents A (Python register check), B
   (six-package verification, Linux packaged playthrough), C (inherited failures, safeguards), final reconciliation. Do
   not cancel or duplicate the run. Build 40 stays the fallback. Agent A's finding recorded (stale local staging 6607000,
   Oct 21, ~677 commits behind a919963; 12 references falsely missing; 22/22 and 196 tests pass with correct refs; no
   tracked change). Agent C reviews independently and establishes permanent safeguards. "Preserve the investigation
   evidence before cleaning up the temporary testing copies." "Do not alter working game code to correct an
   environmental problem."
2. Eliminate outdated-branch contamination: investigate every cross-branch dependency of testing and register validation
   (why, necessary?, immutable commit vs moving branch, authoritative source, freshness, stale influence, simplification).
   Reproducible procedure: candidate SHA; required refs; fetch authoritative refs; validate before dependent tests; detect
   stale/missing/inconsistent environments; distinguish environmental failures from defects; record environment with
   evidence. Automate. "Do not weaken the requirements-register checker." "Do not erase historical records." "A stale local
   branch must never again silently produce misleading validation failures." Agent C coordinates and investigates why
   earlier processes did not catch it.
3. Complete all 69 original audit items (docs/audits/B25_69_ITEM_TRACKER.md on wip/requirements-control; last 43 verified,
   21 integrated awaiting verification, 4 not started, 1 blocked). Reconcile against code, tests, sims, evidence; preserve
   ids. Verified closure = implemented, integrated, applicable tests, cross-system checks, required sims, anomalies
   investigated, evidence against the source SHA; a not-a-defect finding needs evidence and a justified disposition ("Do
   not use reclassification as a shortcut"). "Do not count an issue as complete simply because code was written, an agent
   reported success, or one focused test passed." "Do not silently remove, combine, rename, defer, or redefine the
   original 69 items." Dedicated work: MML-REG-04 physical courier travel; MML-REG-05 physical migration; MML-MP-02
   multiplayer stall/shop management paths; MML-REQ-JOB-02 job-board compensation. Investigate blocked
   MML-REQ-B17F-JOBS (defect / intended outcome / valid but undesirable balance / owner design question); evidence and
   recommendation before changing employment policy; ask the owner promptly if needed. For the 21 integrated items, find
   the outstanding checks, complete them, update the tracker. Owner device playtesting not required for internal
   verification.
4. Parallelize aggressively: continue A, B, C; D audit reconciliation; E the 21 verifications; F regional travel (couriers,
   migration: persistence, failures, duration, pathfinding, economy); G multiplayer (stall/shop paths, permissions, sync,
   ownership, persistence, reconnect); H employment (JOB-02, B17F-JOBS); I flight-recorder simulations (multi-seed 365-day
   campaign and analysis); J integration and regression; K The Ark. May reorganize. "Maximize useful concurrency, not agent
   count for its own sake." Independent branches/worktrees; no overwriting; controlled evidence-based integration. Check
   Actions capacity before expensive validation; avoid redundant CI.
5. Flight-recorder simulations: first report the latest completed multi-seed 365-day campaigns (incl. Nov 12): dates,
   seeds, SHAs, run ids, checkpoints, findings, anomalies; reuse valid evidence. Build 42 target: at least four independent
   365-day simulations on the final integrated candidate, checkpoints days 10, 30, 90, 100, 200, 300, 365; preserve seeds,
   commits, configurations, artifacts, findings. Inspect population, households and inheritance, food and famine,
   employment and wages, businesses, construction, regional trade, physical couriers and migration, NPC decisions and
   travel and stalls, conservation, resources, save/load, economic changes, script errors, cross-system effects. Challenge
   results (a sim can run 365 days implementing incorrect behaviour). Classify findings (defect / legitimate outcome /
   improvement). "Do not change the simulation merely to improve statistics." No baseline approval without the owner.
6. Verification stages: Implemented; Internally verified; Ready for owner playtesting; Owner approved. Owner playtesting
   is not a prerequisite for engineering verification; owner playtest findings are new findings for the next cycle and do
   not invalidate previous verification. "Do not hold completed engineering work open indefinitely because I have not yet
   evaluated the experience."
7. Test whether the implementation is actually correct: both that it functions and that it satisfies the intended design;
   original requirements, assumptions, conflicts, side effects, long-term behaviour, boundaries, coverage, whether tests
   check the right thing; independent reviews, adversarial testing, cross-system analysis.
8. The Ark: new private repository verbal76/Ark (only an initial README; "Do not assume otherwise"); centralized
   engineering knowledge for all Hot Attic Games projects. Structure for incident investigations, reusable solutions, known
   failure patterns, development procedures, engineering decisions, project references. First entry: the Build 40/41
   Python register investigation (two failing checks, stale staging, 677-commit gap, 12 false references, correct remote
   branch, reproductions, 22/22, Python suite, root cause, correction, safeguards, general lessons; dates, SHAs, evidence).
   Rules: private; no links in public materials; never credentials, keys, tokens or secrets; keep project records in their
   repos; no whole histories; exact commits, timestamps, evidence; preserve failed approaches; facts vs hypotheses; no
   duplicate or contradictory guidance; searchable. Consult the Ark before recurring problem classes; add reusable lessons;
   automate safeguards; add references to project-level agent guidance. Deliverables: structure, contributor and usage
   instructions, first incident, documentation standards, cross-project guidance, exact files and commits. Agent K works
   independently.
9. Preserve engineering history and accountability for every significant correction (issue, why, root cause,
   alternatives, failed approaches, implementation, owner decisions, evidence, commits, integration, timestamps,
   disposition, limitations); do not overwrite superseded findings; reusable lessons to the Ark. Investigate why problems
   carried forward (gates, dismissed failures, stale branches, incomplete evidence, misunderstood requirements,
   verification vs implementation, packaging vs completion, lost between sessions). "A new build number must not erase
   outstanding obligations."
10. Build 42: Build 41 remains the packaging candidate; do not increment the build number for accumulated commits. Before
   requesting Build 42 packaging: all 69 verified; Python environment issue resolved and protected; tests pass; four
   365-day sims complete and analysed; anomalies investigated; all changes integrated; exact candidate SHA; package
   verification procedure ready. Ask for owner decisions rather than bypassing. No additional packaging run, merge to
   main, publication, release or baseline approval without authorization. Build 41 artifacts stay tied to 0bbee94.
11. Reporting: acknowledge; coordination report (active agents; added agents; verified of 69; outstanding and owners;
   owner decisions; reusable flight-recorder evidence; CI capacity; integration order; critical path; Ark status); then
   proceed in parallel; ask only for genuine owner decisions or restricted actions; counts not percentages; every
   completion claim with evidence tied to the SHA.
Final: "Your job is to deliver the most thoroughly investigated, internally verified package you can. My job is to tell you
how that package looks, feels, sounds, and plays. Do not confuse the two."
