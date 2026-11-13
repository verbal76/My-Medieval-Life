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
   Godot suites. `tests.yml` triggers automatically only on pushes to `staging/my-medieval-life`; code branches get it only by
   manual dispatch (KI-04 "Still open").

## 3. CI behaviour (as configured at `0bbee94`)

| Workflow | Trigger | Python unittest | Refs for the path check |
|---|---|---|---|
| `tests.yml` | push to staging (paths filter); manual dispatch on any branch | shard 0, `python3 -m unittest discover -s tests` (full run only; a targeted `only`/`group` run skips the Python checks) | `fetch-depth: 2`, then `git fetch --depth=1` of the seven refs; a failed fetch only prints "note: not fetched" |
| `requirements.yml` | push to staging (register paths); dispatch | `tests.test_requirements` only | the same fetch, same silent note |
| `release.yml` | dispatch | none | n/a |

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
| KI-05 `housing_test` loft check | first noted before 2026-11-01 | KI entry still OPEN; `wip/b25-ci-green` `a5667ed` changed `housing_test` (clears trees); the KI entry was not updated. Record hygiene |
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
