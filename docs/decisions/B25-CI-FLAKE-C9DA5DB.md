# B25-CI-FLAKE-C9DA5DB: two multiplayer suites failing on CI, judged a timing flake on `c9da5db` and re-run

> **Reconstructed 2026-11-09 by the documentation agent** (HAG-FORENSICS-01) from:
> - the job logs of runs 42589325057 and 42607051457, through the lead's subagent hand-backs in the session record;
> - the lead's tool calls and their results between 12:19 and 12:40 UTC, from the session record;
> - `NetSync.KEYS` at `c9da5db`, read in this recovery;
> - the state file.
>
> Times are UTC. This was the lead's engineering judgement, not an owner decision.

## A. Identity
- **Commits:** `f67afdb` (`wip/b25-backlog`) and `c9da5db` (`wip/b25-backlog-merge`).
- **Runs:** 42589325057 (Tests on `f67afdb`, 2026-11-09 08:54) and 42607051457 (Tests on `c9da5db`, 11:11; attempt 2 at 12:40).
- **Workstream:** the overnight backlog merge, by the lead.

## B. Observation
- **42589325057:** shard 5 of 12 failed. Only `net_fault_test` failed, on 1 check: the host still held a "ghost" connection 15 s
  after a simulated drop. Everything else passed, including the 10-day economy run with 0 currency and 0 item leaks.
- **42607051457, attempt 1:**
  - shard 5: `net_fault_test` "FAIL frozen past the timeouts and let go, it reconnects by itself as itself", with a JSON parse
    error while reading the test's status file;
  - shard 7: `net_mp4_test` "FAIL after the host was killed: Dan's copy is the host's world [trees[133].born host 9000.0, here
    -421.2; deposits[13].amount host 25.0, here 26.0]".
  - Neither log has a SCRIPT ERROR or a crash line.

## C. Investigation (what the lead did, in order)
1. **Hypothesis, recorded in the session:** SAV-02 added `brain_day` and `hour_caches` to `World.to_dict`, so the host might now
   sync them to guests, or send more each sync.
2. **Read `game/scripts/net/net_sync.gd`.** `NetSync.KEYS`, the sections the host hashes and re-sends on its timer, does not
   include `brain_day` or `hour_caches`. This recovery re-read the file at `c9da5db` and confirms it.
   - Not checked at the time: the initial welcome (`world_for`) sends a fuller `World.to_dict()` to a joining guest (issue #4
     comment 11, on MP-07). The new keys may reach a guest once, at join. That is not a periodic-sync cost, and the recovery found
     no evidence that it matters to these failures.
3. **Ran both suites locally on `c9da5db`:** `net_mp4_test` 148/0 and `net_fault_test` 54/0. Earlier, `net_fault_test` was 54/0
   on `f67afdb` too.
4. **Measured the cost of the new keys** with a throwaway script (not committed): `World.to_dict` took about 7.38 ms; the new
   parts about 0.13 ms; sizes 843 and 123 characters.
5. **Checked which scripts the merge changes:** `git diff --stat 53a56d3 c9da5db -- game/scripts` lists 10 files: business_money,
   chests, construction, employment, fitting, life, npc_brain, stalls, ventures, world. No file under `game/scripts/net/` changed.

## D. Decision
The lead treated the two failures as CI timing and re-ran the whole run (attempt 2).

**Reasons, from the evidence above:**
- both suites pass locally on the same commit;
- the merge touches no network code;
- the new save keys are not periodic sync sections, and they cost about 0.13 ms;
- the failures are timing-shaped: a peer not yet removed at 15 s, a status file read mid-write, a guest copy lagging the host.

**Condition set for the re-run** (the lead's scheduled check, 12:40): "If net_fault_test or net_mp4_test fail again: treat as
real; investigate the sync lag ... and status file parse race."

**Alternatives.** Investigating at once, or re-running only those two suites in CI, are not recorded as having been considered.

## E. Result and limits
- Attempt 2 of 42607051457 passed, with every shard green.
- **What is known:** these suites can fail on CI with this signature; across the four CI runs of these commits and
  of MP-05's rebase (42589325057; 42607051457 attempts 1 and 2; 42636628469), `net_fault_test` failed in 2 and `net_mp4_test`
  in 1.
- **What is not known:** the cause. A real intermittent defect (for example a status-file read racing a write, or sync lag after
  a host kill) is not ruled out.
- **Recorded in:** KNOWN_ISSUES KI-12. Reconsider if either suite fails again on CI, or if a multiplayer change lands.
- The merge went ahead after the recorded campaign was clean ([B25-AUD-BACKLOG-2026-11-09](B25-AUD-BACKLOG-2026-11-09.md)).
