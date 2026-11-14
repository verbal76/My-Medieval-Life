# Inherited failures and quality gates: audit (2026-11-13)

Agent C under the owner's Build 41 parallel resolution directive
(`docs/directives/2026-11-13_build41_parallel_resolution_packaging.md` on `wip/requirements-control`). Read-only audit plus one
safeguard outside `game/`. Agent A owns the correction of the two failures; nothing here changes the register, the check's rules,
gameplay or a baseline.

## 1. The two `tests/test_requirements.py` failures

**Symptom.** In a fresh `git clone --shared /home/user/My-Medieval-Life` checked out at Build 41 candidate `0bbee94` or Build 40
`a5a0b7c`, `test_register_is_valid` and `test_generated_files_are_up_to_date` fail with 12 problems, all of one kind:
`<ID>: notes|source names docs/build18/PHASE_A_INVENTORY.md, which exists neither here nor on an integration branch` (ARMOR-01,
B18-DIR, BARBER-01, BARBER-Q, CC-01, UI-HUD-01, UI-HUNGER-01, UI-PROGRESS-01, UI-WIKI-01, VIS-ANIMAL-01, VIS-CROP-01, VIS-DOOR-01).
Full `unittest discover` in that clone: 196 tests, these 2 failures, 1 expected skip; nothing else.

**Root cause: the test environment, not the code.** `tools/check_requirements.py` (`path_exists`, `PATH_REFS`) accepts a path named
by a record if it is in the working tree **or on one of seven integration refs** (`origin/staging/my-medieval-life`,
`origin/wip/build17`, `origin/wip/build18`, `origin/wip/expansion18..21-preparation`). The inventory is not in the code line's tree;
it lives on staging (added `b518538`, 2026-10-22 03:04 UTC). In a clone of a *local* repository, `origin/*` are the source
repository's **local branches**, not GitHub's. The source checkout's local `staging/my-medieval-life` is `6607000`
(2026-10-21 13:01 UTC), one day older than the inventory; GitHub's staging (`a919963`, 2026-11-05, as the source last fetched it)
has it. Measured in `/dev/shm/audC`:

| `origin/staging/my-medieval-life` in the clone | `check_requirements.py` at `0bbee94` | `tests.test_requirements` |
|---|---|---|
| `6607000` (source's local branch; what `clone --shared` gives) | 12 problems | 22 tests, 2 failures |
| `a919963` (GitHub's, via `git fetch origin '+refs/remotes/origin/staging/my-medieval-life:refs/remotes/origin/staging/my-medieval-life'`) | 0 problems | 22 tests, OK |

The main checkout passes because its `origin/staging/my-medieval-life` is GitHub's `a919963` (and its own branch has the file in
the tree). CI passes for the same reason: `tests.yml` fetches the seven refs from GitHub (section 3).

**First appearance (code line, first-parent of `0bbee94` / `wip/b25-preview`).** The register copy naming the inventory and the
staging-aware path rule entered together:
- rule: `7f45de4` "Let the register's path check also look on staging" (2026-10-22 15:22 UTC), after `1ac79f5` introduced
  `PATH_REFS` (REQ-CTRL-01, 15:21 UTC);
- register + tool on a build branch: `2e3fb7f` "Synchronize the requirements register and its tools from staging" (2026-10-22 15:22 UTC);
- first first-parent commit of the code line containing it: **`c2ece16` (2026-10-23 11:22 UTC, "Merge Build 18 (wip/build18 at
  239bdff) into Expansion 19 (SYNC-18)")**. Verified in the stale clone: its parent `c4b10e4` reports 0 problems (old tool and
  register), `c2ece16` reports the same 12 problems.
- `tools/check_requirements.py` has not changed on the code line since `2e3fb7f`. The failure is therefore latent in every
  code-line commit from `c2ece16` (2026-10-23) to `0bbee94`, and shows only in a checkout whose `origin/staging` lacks the file.
  It is not a Build 40 or Build 41 regression.

**Prior dispositions.**
- No record before 2026-11-13 names these two failures (searched every `origin/*` branch's `docs/` for `test_requirements`,
  `PHASE_A_INVENTORY`, "exists neither", `KNOWN_ISSUES.md` KI entries, the state file, `docs/audits/*`, `docs/release/*`). The
  owner's directive of 2026-11-13 is the first, calling them "inherited" and adding: "Do not classify the issue as resolved merely
  because it also occurs in Build 40."
- **The same check failed the opposite way before** (`61dd5f8`, 2026-10-30, lead, LE-03 recovery directive
  `docs/directives/2026-10-30_le03_food_trade_coordinated_recovery.md` item 1): in CI's shallow checkout the seven refs were absent,
  so every unknown path was "undecidable", silently not reported, and `test_document_references_in_any_field_must_exist` failed
  "on every staging push since 2026-10-22 and on wip/x20-le03 run 41118607622". The fix added the fetch step to `tests.yml`; the
  check itself was left ref-dependent. Today's failure is the mirror image (refs present but stale).

## 2. Is it the gates or the environment?

Both, in different ways.
1. **Environment (the immediate cause).** The local audit environment differs from CI: `clone --shared` of a working checkout
   gives `origin/*` = that checkout's stale local branches. CI fetches GitHub's.
2. **Check design (a latent weakness).** The verdict depends on which refs exist: a missing ref silently weakens the check
   (undecidable, not reported); a stale ref gives a false failure. The same commit can pass or fail depending on the clone.
3. **Gate coverage (a real gap).** No `tests.yml` run exists on `a5a0b7c` or `0bbee94`. The last Tests run on the code line is
   43321399738 on `b3c9eb5` (chain 12, success; shard 0: `Ran 196 tests ... OK (skipped=1)`, `check_requirements` exit 0). The 31
   commits `b3c9eb5..0bbee94` (18 to Build 40, 13 more to Build 41) were packaged by `release.yml` (runs 43362745451, 43527275522)
   without a Tests run. `release.yml` runs packaging, Windows smoke and SIM-GATE-01 only: it never runs `unittest discover` or the
   Godot suites. **Correction (2026-11-14, found by Agent K while writing the Ark entry, verified):** the Godot half of that
   sentence is wrong. `release.yml` at `0bbee94` (lines 172-178) runs three Godot scripts in its `linux-full` cell
   (`res://tests/run_tests.gd`, `start_test.gd`, `demo_test.gd`); it runs no Python test and not the other game suites
   `tests.yml` runs (about 280). The conclusion stands: packaging is not a substitute for a full Tests run on the SHA. `tests.yml` triggers automatically only on pushes to `staging/my-medieval-life`; code branches get it only by
   manual dispatch (KI-04 "Still open").

## 3. CI behaviour (as configured at `0bbee94`)

| Workflow | Trigger | Python unittest | Refs for the path check |
|---|---|---|---|
| `tests.yml` | push to staging (paths filter); manual dispatch on any branch | shard 0, `python3 -m unittest discover -s tests` (full run only; a targeted `only`/`group` run skips the Python checks) | `fetch-depth: 2`, then `git fetch --depth=1` of the seven refs; a failed fetch only prints "note: not fetched" |
| `requirements.yml` | push to staging (register paths); dispatch | `tests.test_requirements` only | the same fetch, same silent note |
| `release.yml` | dispatch | none (three Godot scripts in `linux-full`: `run_tests.gd`, `start_test.gd`, `demo_test.gd`) | n/a |

## 4. Other repeatedly inherited failures (last ~10 Tests / release runs and the records)

| Item | Recent evidence | Status |
|---|---|---|
| SIM-GATE-01 red on every release attempt (32-33 baseline-difference findings against `df67e8e`; release step skipped) | builds 37-40: 43257420696, 43298122299, 43321404909, 43362745451 | OPEN, owner: baseline acceptance (BASELINE-AUTH-01, B25-BASELINE-D2, B25-BASELINE-REVIEW-01). Carried by design, not a test fault |
| KI-12 `net_fault_test` intermittent | chain 10 43279381316 ("second guest frozen: the host drops it in its time", dropped false after 20 s); chain 11 43298116326 ("the host stops on purpose: the guest is told at once"); both after the KI-12 fix `dc049d9` (an ancestor of chain 10 and 11) | OPEN: the fix covered the frozen-guest reconnect race; these are two **new** checks failing. Chain 12 43321399738 green. Needs a fresh investigation, not a carried "CI timing" label |
| `station_tap_test` s7 sawhorse | chain 9 43265670635 (both attempts) | RESOLVED in chain 12 (ND-27, test dismisses the opening message; 20/20 local) |
| KI-08 "resources still in use at exit" Godot warnings | MP04/PROP01/PROP05 verification notes (2026-11-08), lead measurement "69 resources" on `c9da5db` | OPEN, never investigated; called "long-standing noise" without a check |
| B25R2-BRUSHOFF script error (`dialogue.gd:526`) | strict run 42509510188 | INTEGRATED with Batch A `f0a854c` |
| KI-09 `demo_test` double free | 42542326507, 42734267343 | FIXED `167b235`; watch |
| KI-10 partial re-run reports failure | 42542326507 | OPEN (reporting) |
| KI-05 `housing_test` loft check | first noted before 2026-11-01 | KI entry still OPEN; `wip/b25-ci-green` `a5667ed` changed `housing_test` (clears trees); the KI entry was not updated. Record hygiene. **2026-11-14:** resolved by `a5667ed` (2026-11-02; bisected to `66fd330`, a stale test premise, no game change); 117 checks, 0 failures in Tests 43321399738 on `b3c9eb5`; draft KI text in section 10 |
| KI-04 suites not in CI / no automatic CI on code branches | see section 2.3 | OPEN; the coverage half was addressed on 2026-11-05 (34 suites added), the trigger half was not |
| Expected unittest skip | `test_sim_gate` real-gate test (`MML_GATE_DIR`), `OK (skipped=1)` | expected; no gate checks the skip count |

## 5. Safeguards

**Implemented on `wip/b41-inherited-failure-guard` (from `0bbee94`; no `game/`, register, rule or baseline change):**
- `tools/check_test_env.py`: reads the seven refs from `check_requirements.PATH_REFS` (one list) and reports each as ok, **missing**
  (the path check would be undecidable) or **stale** (a clone of a local repository whose `origin/X` differs from the source's
  `refs/remotes/origin/X`), printing the exact `git fetch` that fixes it. Exit 1 on stale; `--strict` also on missing. In the
  `/dev/shm` audit clone it reports `origin/staging/my-medieval-life` stale (`6607000` vs `a919963`) with the fix.
- `tests/test_check_test_env.py`: builds a source repo with a lagging local branch, `clone --shared`s it, and requires "stale" and
  "missing" to be reported.
- `tests.yml` and `requirements.yml`: `python3 tools/check_test_env.py --strict` right after the fetch loop, so a branch that
  fails to fetch stops the job instead of silently weakening the path check (the 2026-10-30 failure mode).

**Recommended (not implemented; need the lead or the owner):**
1. Local recipe for every agent clone: after `git clone --shared <checkout> <dir>`, run
   `git -C <dir> fetch origin '+refs/remotes/origin/*:refs/remotes/origin/*'` and then `python3 tools/check_test_env.py`; or clone
   from GitHub. Add to the worker brief (SCHEMA.md "Workers") and `docs/PROJECT_MEMORY.md`.
2. Make the path check deterministic (Agent A's area): decide a path from the working tree plus an explicit, recorded allow-list
   of known off-branch paths (or the register's own record of where each lives), not from whatever refs a clone holds; then the
   refs matter only for the optional cross-check.
3. Gate packaging on tests: `release.yml` should refuse (or run) unless a successful full `tests.yml` run exists for the same SHA.
   Builds 40 and 41 were packaged 18 and 31 commits after the last Tests run. This changes the release procedure: owner decision.
4. An expected-skip floor: fail the Python step if `unittest` reports more skips than the one known (`MML_GATE_DIR`), as
   `tools/ci_check_floors.json` does for check counts.
5. KI-12: open a new entry for the two post-fix `net_fault_test` checks rather than folding them into "CI timing"; update KI-05.

## 6. Needs the owner
- Whether `release.yml` must require a green Tests run on the packaged SHA (recommendation 3).
- The SIM-GATE-01 baseline (already pending; it is why every Build 25 release attempt stops before publishing).

Evidence commands (reproducible): `git ls-tree -r --name-only <ref> -- docs/build18/PHASE_A_INVENTORY.md` for `a919963`, `6607000`,
`0bbee94`, `a5a0b7c`; `git log --format='%h %ci %s' -S PATH_REFS --all -- tools/check_requirements.py`;
`gh run view 43321399738 --log | grep 'shard 0'`; `gh run view <id> --log-failed` for 43265670635, 43279381316, 43298116326.

---

# Part 2 (2026-11-14): eliminating outdated-branch contamination

Owner directive 2026-11-13, Build 42, section 2 (`docs/directives/2026-11-13_build42_engineering_directive.md` on
`wip/requirements-control`): "A stale local branch must never again silently produce misleading validation failures."
Branch `wip/b42-env-guard` (from `74bcc66`, which is directly on `0bbee94`). Sections 1-6 above are kept as written; where
they are corrected, the correction is marked in place. Status of section 5's recommendations: 1 (clone recipe) done in
`docs/PROJECT_MEMORY.md`; 4 (skip floor) done; 2, 3 and 5 below.

## 7. Every cross-branch dependency of testing and register validation

Found by searching `tools/`, `tools/git_hooks/`, `tests/` and `.github/workflows/` at `0bbee94` for `origin/`, `ls-tree`,
`git show REF:`, `cat-file`, `merge-base`, `ls-remote`, `fetch` and `--against`, and by reading each hit.

| # | Dependency | Why it exists | Necessary? | Moving branch or immutable | Authority and freshness | Can stale data change a result? | Simplify without losing traceability |
|---|---|---|---|---|---|---|---|
| D1 | `check_requirements.PATH_REFS` (7 branches at `0bbee94`; 8 on `wip/requirements-control`, which adds `wip/expansion20`): a path a record names exists if it is in the tree or on one of them | One register is copied to every branch, but documents and code live on the branch that made them (REQ-CTRL-01, `7f45de4`) | Measured: of 201 paths the `0bbee94` register names, **1** is not in the tree (`docs/build18/PHASE_A_INVENTORY.md`, on staging only). Of 407 the records-branch register names, 179 are not in `0bbee94`'s tree and 33 not in the records branch's tree; those need other branches | Moving branches | GitHub heads; freshness never established before this change (a ref was used as found) | **Yes, both ways:** missing ref = path undecidable, silently not reported (2026-10-30, `61dd5f8`); stale ref = false "exists neither" (2026-11-13) | Implemented: one list (CI fetches what `check_test_env.py --list-refs` derives from it), fetched from and compared with GitHub, recorded with the evidence. Recommended (Agent A / lead): record, for each off-tree path, the commit where it was verified (an immutable SHA), so the check reads `git cat-file -e SHA:path` and no longer depends on where a branch points; the branches stay only as the way to find a new path's commit |
| D2 | `check_requirements.py --against REF` (`at_ref`): no id disappears, no status changes without history | REQ-CTRL-01 loss detection | Yes | CI: `HEAD~1` (immutable relative to the commit); pre-push hook: the remote's old SHA (immutable); docs example: `origin/staging/my-medieval-life` (moving) | The commit itself | An unresolvable REF prints "note: no register at REF" and **passes** (silent). A stale branch only widens the comparison window; the history rule still applies, so no false pass | Implemented: `--require-commit HEAD~1` makes CI fail as an environment failure when the clone is too shallow. Recommended: make an unresolvable `--against` an error in the check (Agent A's area; it strengthens, not weakens) |
| D3 | `tools/git_hooks/pre-push`: `git fetch origin staging/my-medieval-life`, then a pushed register must be a version staging had | REQ-CTRL-01: the register is edited in one place | Yes, for pushes | Moving (staging) | Fetched at push time from `origin`; in a `--shared` clone whose origin is the local checkout, that fetch reads the **stale local branch**, and a clone does not inherit `core.hooksPath`, so the hook is usually **inactive** in agent clones | A stale staging could refuse a legitimate push (false failure, loud). No false pass | Recipe sets origin to GitHub and `core.hooksPath` (`docs/PROJECT_MEMORY.md`). Note: the register is now edited on `wip/requirements-control` (REQ-CTRL-02); the hook still compares with staging only, which works because the records branch's versions reach staging; if they stop doing so, every code-branch sync would be refused. Lead to confirm |
| D4 | CI fetch loops (`tests.yml`, `requirements.yml`) | Give the shallow CI clone the refs of D1 | Yes while D1 reads branches | Moving | GitHub at run time (fresh); a failed fetch only printed "note: not fetched" | Missing ref silently weakened D1. **Drift found:** on `wip/requirements-control` PATH_REFS has 8 refs but both workflows fetch 7, so in CI there `wip/expansion20` is missing and every path that only it holds is unchecked | Implemented: the loops are replaced by `check_test_env.py --fetch --strict --require-authority --candidate SHA --require-commit HEAD~1 --record`; the list comes from PATH_REFS, so the drift cannot recur once this lands on the records branch too |
| D5 | `tools/build_status.py` `BASE = "a8760be"` | Build 16's starting scope | Historical report only, not in tests or CI | Immutable commit | Needs full history | No (an absent commit errors loudly) | None needed |
| D6 | `tools/branch_audit.py` (`origin/<integration>`), `tools/requirements_audit.py` `CODE_REFS`, `tools/requirements_migrate_v2.py` | Branch hygiene report; one-off 2026-10-23 reconciliation and v2 migration | Not used by tests or CI | Moving | Whatever the clone has | Their reports could be stale; nothing gates on them | Note in their docstrings to fetch first (low priority) |
| D7 | `tools/checkpoint.py` (`ls-remote origin`) | Proves a pushed hash is on GitHub | Yes | Exact SHAs | Asks the remote directly | No | None needed |
| D8 | Simulation baseline (`docs/release/sim_baseline.json`, `tools/sim_gate.py`, `tools/sim_suite.py`) and `release.yml` `reuse_gate_run` | Gate comparison; an owner-approved reuse of an earlier gate | Yes | In-tree file (immutable with the commit); reuse names a run and diffs from its commit with `fetch-depth: 0` | The commit / the run id | No cross-branch read | None needed |
| D9 | `tests/*.py` | | | | | Only through D1 and D2 (`test_requirements.py`: `test_register_is_valid`, `test_generated_files_are_up_to_date`, `test_document_references_in_any_field_must_exist`) | |

Records-branch check, for scale: `check_requirements.py` on `wip/requirements-control` `26b4695` reported 0 problems in a
clone **without** `origin/wip/expansion20`, where 6 named paths were undecidable (a silent pass); after fetching it, still 0
(the paths are on it). The verdict was right by luck, not by check.

## 8. The procedure (automated)

`tools/check_test_env.py` (`mml-test-env/1` records) and `tools/check_unittest_skips.py`, used by agents and CI alike:

1. **Record the candidate.** `--candidate SHA`: unfit if `HEAD` is another commit.
2. **Required refs.** Read from the tree's own `check_requirements.PATH_REFS` (`--list-refs` prints them); `--require-commit
   HEAD~1` for `--against HEAD~1`.
3. **Fetch the authoritative refs.** `--fetch`: from GitHub (`origin`'s URL, or a local source's own `origin`), depth 1 in a
   shallow clone.
4. **Validate before dependent tests.** Each ref is compared with GitHub (`git ls-remote`): ok, stale, missing or
   unverified (`--offline` compares a local clone with its source instead). Unfit: any stale ref; with `--strict`/`--fetch` any
   missing ref; with `--require-authority` any unverified ref; a wrong candidate; an unresolvable required commit.
5. **Separate environment failures from defects.** `run -- CMD` runs the command only on a fit environment; otherwise it
   exits 3 and records "not run: environment". On a fit environment a nonzero exit is recorded as "failed on a fit
   environment: a candidate defect".
6. **Record the environment with the evidence.** `--record FILE` writes the candidate SHA, branch, whether tracked files
   differ, the authority (credentials stripped), every ref's SHA, date, GitHub's SHA and state, the required commits, the
   verdict and problems, git and Python versions, and the command with its exit code and classification. CI writes it into
   `ci-out/` (uploaded with `ci-report`).
7. **No silent skips.** `tools/check_unittest_skips.py` runs `unittest discover -s tests` and fails on a skip not listed in
   `tools/unittest_expectations.json` (one listed: `test_sim_gate.RealGateSplit.test_real_outputs`, needs `MML_GATE_DIR`) or on
   fewer tests than `min_tests` (201).

Agent recipe: `docs/PROJECT_MEMORY.md`, "Making a checkout to test in".

Evidence on `wip/b42-env-guard` `5621a56` (`/dev/shm/audC`, 2026-11-14):
- with `origin/staging/my-medieval-life` set back to `6607000`: "stale ... the authority has a919963", verdict UNFIT, and
  `run -- python3 -m unittest tests.test_requirements` was **not run** (exit 3, recorded "not run: environment");
- `--fetch --strict --require-authority --candidate 5621a56 --require-commit HEAD~1 --record ... run -- python3
  tools/check_unittest_skips.py`: 7 refs ok, verdict fit, 201 tests, 0 failures, 0 errors, 1 skipped (0 unexpected), exit 0,
  recorded "passed";
- an earlier run of `check_unittest_skips.py` with no expected skips listed failed: "unexpected skip:
  test_sim_gate.RealGateSplit.test_real_outputs";
- `tests/test_check_test_env.py`: 5 tests OK (authority = a bare repository by `file://`; source with a lagging local
  branch; `clone --shared`: stale online and offline, `--fetch` makes it fit, missing/candidate/shallow unfit, `run` refuses
  and records, skip floor).
- `tools/check_requirements.py` on the branch: 0 problems (the new `docs/PROJECT_MEMORY.md` section names only real paths).

Known limit: a branch pushed between the fetch and the `ls-remote` (seconds apart) reads as stale and fails the job as an
environment failure; a re-run clears it. Loud, never a false pass.

## 9. Why earlier processes did not catch it

1. **The check's verdict was never tied to its inputs.** `path_exists` reads whatever refs exist and records none, so a
   result could not be reproduced or questioned: nobody could tell a stale-ref failure from a real one without investigating.
2. **The 2026-10-30 incident was fixed at the symptom.** `61dd5f8` added a fetch to `tests.yml` (the mirror case: refs
   missing in CI) but left the check environment-dependent and the fetch failure a printed note. The class came back two
   weeks later in a different environment.
3. **Two lists for one fact.** PATH_REFS and the workflow loops drifted (8 vs 7 on the records branch) without any check
   noticing.
4. **Local and CI environments differ and nothing compared them.** CI fetches GitHub; agent clones (`clone --shared`)
   inherit the source's local branches, and do not inherit the pre-push hook. No procedure said to fetch, and the shared
   Build 42 brief's fetch list omits `wip/expansion20`, which the records branch's check reads (fine for `0bbee94`, whose
   PATH_REFS has 7 refs; wrong on `wip/requirements-control`). `--fetch` derives the list instead.
5. **Silent passes are invisible.** An undecidable path, an unresolvable `--against`, a skipped unittest and a failed fetch all
   exit 0. Gates report failures, so they never surfaced.
6. **Packaging was not tied to testing.** Builds 40 and 41 were packaged 18 and 31 commits after the last full Tests run;
   `release.yml` runs no Python test, and `tests.yml` triggers automatically only on staging pushes (KI-04). So the code line's
   Python results for those SHAs existed only in agents' local clones: the one environment that was wrong.
7. **"Inherited" was not a disposition anywhere.** No record named these failures before 2026-11-13; a failure seen in an
   older build was treated as background rather than investigated (the owner: "Do not classify the issue as resolved merely
   because it also occurs in Build 40").

## 10. Draft known-issue text (for the lead; `docs/KNOWN_ISSUES.md` is a records item, not edited here)

**KI-05 (update; proposed status RESOLVED)**
> ### KI-05 housing_test loft check fails (RESOLVED `a5667ed`, 2026-11-02; record updated 2026-11-14)
> - **Cause:** the check "short of 3 sleeping places, more than a loft gives: living quarters beside the house" failed from
>   `66fd330` (Build 22 market merge, village v16), bisected first-parent `a89484a` good / `66fd330` bad. The new village put
>   trees where seed 2's 9x10 quarters would stand, so `_enlarge` rightly weighed only the loft and the small room (HOUSE-12:
>   a tree in the way is not legitimate ground). The test's premise ("open ground beside the house") had gone stale; the game
>   was right.
> - **Fix:** `a5667ed` (`wip/b25-ci-green`): the test clears the trees beside the new house. No game change. Later `c423670`
>   stocks the small room's blocks.
> - **Verified:** `housing_test` 117 checks, 0 failures in Tests 43321399738 on `b3c9eb5` (floor 117). This entry stayed OPEN
>   for 12 days after the fix (audit `docs/audits/2026-11-13_INHERITED_FAILURES_AUDIT.md`, section 4).

**KI-12 (new section under KI-12; proposed status OPEN, recurrence after the fix)**
> ### KI-12 recurrence after the fix (2026-11-12; found by the inherited-failures audit 2026-11-13)
> - The fix `dc049d9` (guest reconnects at once after a frame gap over 4 s) is an ancestor of both commits below.
> - Tests 43279381316 on `428a494` (chain 10), shard 5: `net_fault_test` 55 checks, 1 failure: "the second guest frozen: the
>   host drops it in its time (playing before the freeze true; dropped false after 20.0 s ...)". This is the **host** side
>   (dropping a frozen peer), which the fix did not touch; the 2026-11-09 investigation measured the host dropping in
>   2.8-12.2 s.
> - Tests 43298116326 on `1d03eea` (chain 11), shard 5: `net_fault_test` 55 checks, 1 failure: "the host stops on purpose: the
>   guest is told at once and does not wait" (the guest showed "Connection to the host lost. Reconnecting..."). A deliberate
>   host stop was read as a lost connection: a different path again (the stop notice).
> - Tests 43321399738 on `b3c9eb5` (chain 12): green. Neither failure has been reproduced or investigated; both commits
>   touched no network code as far as recorded.
> - **Next:** treat as two open defects or test-timing faults to be classified with evidence (host peer timeout under
>   load; stop notice ordering vs disconnect), not as the closed 2026-11-09 race. Do not label "CI timing" without a
>   measurement.

## 11. What CI must run to prove these changes (not dispatched)

Nothing here has run in GitHub Actions yet. One `tests.yml` dispatch on `wip/b42-env-guard` (or on the integration commit
that carries it) proves: the new fetch step on a real shallow CI clone (`--fetch`, `ls-remote` with the runner's
credentials, `HEAD~1` present at `fetch-depth: 2`), `ci-out/test-env.json` in the `ci-report` artifact, and
`check_unittest_skips.py` in shard 0 (201 tests, 1 expected skip). One `requirements.yml` dispatch proves the same for
that workflow. The records branch's own workflows need the same change (D4 drift) when the lead next edits them.
