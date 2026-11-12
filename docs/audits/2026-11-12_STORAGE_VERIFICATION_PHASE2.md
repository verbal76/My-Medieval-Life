# Storage recovery: Phase 2 verification (owner approval 2026-11-12, read-only)

Nothing deleted, pruned, reset, fetched into a repository or written to disk beyond small text results in the scratchpad
(`scratch/p2/`: ls-remote listings). Remote copies were read in memory only. Sizes are allocated disk blocks (what deletion
would free). Scratch = `/tmp/claude-0/-home-user/754052d8-fb21-5c64-b3f9-641f462e2c23/scratchpad`.

## 1. `/home/user/inventory-src` (1,606 MB, 22 clones from 2026-10-18)

- 4 clones hold no local-only commit (HotAtticGames.github.io, personal-assistant-, spiroglyphics, web_auditor).
- 18 clones hold 73 commits that no remote-tracking branch contains (`git rev-list --all --reflog --not --remotes`).
  - Every one is reachable from a local `refs/pull/N/merge` or `refs/pull/N/head` ref copied from GitHub.
  - There are no local branch commits, no reflog-only or unreferenced commits, no detached HEAD (all on `main`), no stashes and no
    working trees (no-checkout clones).
- **64 of the 73** are, byte for byte, the current tip of a ref on GitHub today (`git ls-remote`). These are the
  `refs/pull/*/merge` and `refs/pull/*/head` refs: 54 merge refs plus Idle-game's 17 PR heads #45–#61 (in `refs/pull/N/head`).
- **9** are older GitHub test-merge commits ("Merge X into Y") that GitHub has since regenerated:
  - Repos: Backrooms #5, Cfm #1, Climb-Up #1, Game-Designer #1, My-Medieval-Life #1, Tartaria #32/#34/#35, voiceforge #3.
  - All 9 commit objects still answer on GitHub's API (`GET /commits/<sha>` = 200), but no ref points at them.
  - Both parents of each are reachable today (GitHub compare against the current branch: "behind" or "identical").
  - So their content is the merge of two preserved commits, synthesized by GitHub, and contains no developer work.

| Repo | Local-only commits | Exact remote tip | Remote via unreferenced object + both parents reachable |
|---|---|---|---|
| Axolotl | 2 | 2 | 0 |
| Backrooms-Survivor | 1 | 0 | 1 |
| Cfm-calculator | 1 | 0 | 1 |
| Climb-Up | 2 | 1 | 1 |
| Endless-Escaspe | 7 | 7 | 0 |
| Fix-Tremors | 1 | 1 | 0 |
| Game-Designer | 1 | 0 | 1 |
| Idle-game | 20 | 20 | 0 |
| LLM-Trainer | 1 | 1 | 0 |
| Manual-J | 1 | 1 | 0 |
| My-Medieval-Life | 1 | 0 | 1 |
| My-Personal-Crossow0rd | 2 | 2 | 0 |
| Ocean-spore | 1 | 1 | 0 |
| Purgatory-Dungeon | 9 | 9 | 0 |
| Ragdoll-Rally | 5 | 5 | 0 |
| Tartaria-RPG | 14 | 11 | 3 |
| Zombie-squisher | 1 | 1 | 0 |
| voiceforge | 3 | 2 | 1 |
| **Total** | **73** | **64** | **9** |

**Dependency flagged:**
- Idle-game PR heads #45–#61 (17 commits) are not on any branch. Their only copy outside this container is GitHub's
  `refs/pull/N/head`, which GitHub keeps for the life of the repository but which is lost if the repository is deleted.
- The same holds for every PR head whose branch was deleted.
- A durable backup of the 22 repositories (e.g. a mirror bundle stored off this machine) is recommended if they matter beyond GitHub.
- Deleting this local copy does not change that exposure: it was a no-checkout clone made from GitHub, not a backup.

**Classification: SAFE**, with the dependency above stated. Recoverable: 1,606 MB.

## 2. `icons` (76 MB; 25 clones from 2026-11-10 plus `out/`)

- All 25 clones: 0 local-only commits, 0 stashes; every local and remote-tracking ref is a current GitHub tip.
- One exception: HotAtticGames.github.io's `main` is now an ancestor of GitHub's `main` (status "behind", after PR #1 merged).
- `out/` (6.6 MB, 25 files from the icon inventory) is not a Git repository.
  - 4 files are byte-identical to icons published on the studio site (808-beat-machine, my-medieval-life, tartaria-realms,
    upwardly).
  - `animator.svg` is in animator-studio's history.
  - The other 20 (renders made with `render.js`, a contact sheet, launcher XML extracts, alternative sizes) are unverified local
    working files.

**Clones: SAFE** (about 69 MB). **`out/`: UNKNOWN** (6.6 MB; small, recommend keeping).

**Incident during this check:**
- `git log --find-object` in the partial (blob-less) clones made Git fetch missing objects from GitHub.
- It wrote 478 new promisor pack files (48 MB) into 4 clones: 808-beats, animator-studio, axolotl, hotatticgames.github.io.
- Free space went from 510 MB to 461 MB.
- Nothing existing was changed or removed; the new objects are copies of GitHub's. The command was stopped.
- `inventory-src` and the project repository received no new objects. No further commands of that kind were run on partial clones.
- The added packs are part of `icons` and would be recovered with it.

## 3. `ico` and `b9` (110 MB and 107 MB, 2026-10-18)

| File | SHA-256 | Remote match |
|---|---|---|
| `ico/MyMedievalLife.exe` | `6c77ab02…0610031` | None. Same size as the exe inside the build-7 Windows zip (`f217acce…`), but a different hash; made 6 minutes before build 7 was published. A local export. |
| `b9/MyMedievalLife.x86_64` | `12037c27…04e84e` | None. It is the member of `b9/lin.zip`. |
| `b9/lin.zip` | `97c1317a…60c108c4` | None. No release asset of the 32 releases has its size (checked 2026-11-10; drafts' digests not readable now). |
| `b9/t.png` | `5cff3d56…438f24` | Not in any commit of the repository. A 1280×720 screenshot of that Linux build on day 1 (smoke test). |

- These are local test exports of October 18 code, superseded by Builds 7–25.
- No remote copy exists. Godot exports are not byte-reproducible.
- **Classification: UNSAFE under the primary rule** (no verified copy). Only you can declare them disposable as obsolete.
- Recoverable only on that decision: 217 MB.

## 4. CI evidence: `ci` (102 MB), `gate` (83 MB), `inv_bc` (73 MB)

Every file was compared with the GitHub artifact or log in memory.

| Local | GitHub source | Identity | Expires |
|---|---|---|---|
| 24 `ci/*.zip` + their 24 extracted dirs | runs 41733575763, 41737006430, 41735516442, 41978365595, 41997211755, 42027807813 (ci-report shards); 41733570702, 41737024930 (sim-gate) | zip SHA-256 = artifact digest; dirs = zip contents | 2026-12-03 to 2026-12-05; sim-gate 2027-02-01 |
| `ci/home240.zip`, `ci/pre60.zip` (+dirs) | runs 41740383468, 41740563376 (`sim-v0-seed1-days240/60`) | digest match | 2026-12-03, 2026-12-04 |
| `ci/r4*/` (20 dirs), `ci/x_ci-report-*` (56 dirs) | runs 41580777660, 41733575763, 41735516442, 41737006430, 41740708833; 41997201621 … 42027818010 | 1,155 files identical, 0 extra | 2026-12-03 to 2026-12-05 |
| 12 `ci/*.log` | jobs of runs 42055669578, 42124894260 | text identical apart from `gh run view` formatting (job/step prefix, timestamps rounded) | log retention (not readable without admin; default 90 days) |
| `ci/h*.txt`, `ci/m*.txt` (8 files, 0.36 MB) | none | local greps of the logs (derivable from them) | n/a |
| `gate/g.zip`, `gate/` root, `gate/g/` | run 41770724025 sim-gate | digest match; 70/70 files identical | 2027-02-02 |
| `gate/gate.zip`, `gate/x/` | run 42297641550 sim-gate | digest match; 76/76 identical | 2027-02-04 |
| `inv_bc/x/` (3,584 files) | run 42788018729 artifact `fr-seed1-seg4-archive` (332 MB) | archive digest verified; every local file identical | **2026-12-10** |

- These are identical copies of GitHub artifacts. Artifacts expire; they are not permanent backups.
- **Classification: SAFE as duplicates while the artifact exists** (until the earliest expiry, 2026-12-03).
- Deleting them loses nothing that GitHub does not hold today.
- The 8 derived text files (0.36 MB) are regenerable from the logs; they are kept or deleted with `ci`.
- Recommendation: if any of this evidence must outlive its artifact (notably the Batch 3+4 seed-1 recorder archive in `inv_bc`,
  expiring 2026-12-10, and the ci-report shards), take a durable off-machine copy before the expiry. That is a separate
  decision from deleting the local duplicate.
- Recoverable: 258 MB.

## 5. `smoke` (106 MB, 2026-10-27)

- A **local** simulation-gate subset (run id `local-1793080984`, commit `6bc405a`). No CI copy exists.
- **Classification: UNSAFE** (unique evidence).

## 6. `flyover_v3` (267 MB, 2026-11-05)

| Part | Size | Unique? |
|---|---|---|
| `post.py`, `seam2.py`, `run.sh` (scripts) | 10 KB | **Yes: committed nowhere** (blob ids absent from every ref) |
| `run.log`, `post_all.json`, `seams.json`, `raw/shots.json` | 0.45 MB | Yes (run metadata) |
| `raw/` 240 PNG shots | 152 MB | Regenerable only with `run.sh` at commit `ece34f5` (on GitHub) with the committed `game/tests/drone_shot.gd` (deterministic: paused world, fixed hour) |
| `crops/` 22 PNG, 4 stitched PNG | 117 MB | Regenerable only with `post.py`/`seam2.py` from `raw/` |

- **Classification: UNKNOWN.**
- The renders become SAFE only after the scripts and metadata (about 0.46 MB) are preserved durably, e.g. committed to the
  records branch, which needs your authorization.
- Keep the scripts in any case. Recoverable after that: 266 MB.

## 7. Unchanged and not touched

`f015pop` (45 MB), `inv02` (116 MB), `x20f` (78 MB): **UNSAFE**, unchanged.

## 8. Summary

| Target | MB | Classification | Condition |
|---|---|---|---|
| `/home/user/inventory-src` | 1,606 | SAFE | Only GitHub copies; durable mirror of PR-only commits recommended (dependency on GitHub) |
| `icons` clones | ~69 | SAFE | |
| `icons/out` | 6.6 | UNKNOWN | 20 unverified working files |
| `ci` | 102 | SAFE (duplicate) | Until artifacts expire 2026-12-03…05 (sim-gate 2027-02); not a permanent backup |
| `gate` | 83 | SAFE (duplicate) | Artifacts expire 2027-02-02 / 2027-02-04 |
| `inv_bc` | 73 | SAFE (duplicate) | Artifact expires 2026-12-10 |
| `flyover_v3` | 267 | UNKNOWN | SAFE for the renders (266 MB) once the 0.46 MB of scripts and metadata are preserved |
| `ico`, `b9` | 217 | UNSAFE | No remote copy; disposable only by owner decision as obsolete |
| `smoke` | 106 | UNSAFE | Unique local gate run |
| `f015pop`, `inv02`, `x20f` | 239 | UNSAFE | Protected, untouched |

- **SAFE now:** about 1,933 MB (1,606 + 69 + 102 + 83 + 73).
- **After preserving the flyover scripts:** about 2,199 MB.
- **With owner decisions on `ico`/`b9`:** about 2,416 MB.
- **Free now:** 461 MB.
