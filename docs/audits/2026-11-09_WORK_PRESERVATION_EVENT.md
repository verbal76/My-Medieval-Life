# Work preservation event, 2026-11-09 (HAG-PRESERVE-01)

Owner directive: `docs/directives/2026-11-09_urgent_work_preservation_disk_safety.md`. Performed by the lead session
(754052d8), 2026-11-09 16:50-17:10 EST. Written at the time.

## Safety check (before any change)
- **Free space:** 144 MB at the owner's report; 91 MB at the check (16:50 EST), 89 MB after snapshotting. Inodes 8% used
  (1,301,190 of 16,777,216).
- **Worktrees:** 73 registered. 29 had uncommitted, staged or untracked files (table below); 44 were clean.
- **Agents at the check:** both helpers had already finished (MP-05 forged-client worker: pushed `wip/b25-mp05-forge`
  `448fc0b`; REG-08 investigator and the audit-triage agent: read-only, no worktree). Only the lead was writing. The owner's
  directive lists "Helper 2: REG-08"; that investigation had finished before the directive arrived.
- **The 74 files in `b25r2`:** not work. That worktree had `wip/b25r2-rev2` checked out at `fe7d8f8`. The lead later moved the
  same local branch to `242ca83`/`b7884d3` from another worktree (`prop06`, `git checkout -B wip/b25r2-rev2`), so `b25r2`'s HEAD moved
  while its files stayed at `fe7d8f8`: its working files equal `fe7d8f8` exactly (`git diff fe7d8f8` empty, no untracked files).
  The 74 "changes" (31 modified, 43 deleted) are the difference between `fe7d8f8` and `b7884d3`, both on GitHub. This was a lead
  error (one branch checked out in two worktrees, against the isolation rule); corrected below.
- **The other 28 dirty worktrees:**
  - 10 older agent worktrees (`agent-*`, Build 13-16 era, no live owner): real uncommitted, mostly staged work (code, data, docs,
    imported assets). Never pushed before. No current agent owns them.
  - 16 `b25r1-*` worktrees: only untracked Godot `.uid` files (generated), except `b25r1-rec-scratch` (one modified
    `world_recorder.gd`).
  - `wt_old` (scratchpad worktree at `3c53431`): 3 files.

## Preservation (method and destination)
- `tools/checkpoint.py` was reviewed. Its `snapshot()` (temporary index, worktree and its own index untouched) was used for every
  dirty worktree. Not used as-is: `--offsite` writes a bundle onto the same full disk; `--push` also pushes the current branch
  to the historical `staging/my-medieval-life`.
- For each of the 29: a **work snapshot** commit (the full working state, untracked included, first parent = the worktree's HEAD)
  and an **index snapshot** commit (the worktree's staged state, parent = HEAD). 58 commits.
- **Off-machine destination:** GitHub, branches `wip/backup-20261109/<worktree>-work` and `-index` (58 branches). Only project
  files; no secrets, no large binaries beyond the project's own staged assets.
- **No worktree file, index or branch was changed by the preservation.**

## Verification
- Local: re-snapshotting each worktree reproduced the same commit (working state unchanged), and each worktree's own index tree
  equals its index snapshot's tree: 29 of 29.
- Remote refs: all 58 branches exist on GitHub with exactly the local SHAs (`git ls-remote`): 58 of 58.
- **Independent, from GitHub's copy** (verification agent, GitHub REST API on the server's commits, not the local object store):
  for every work snapshot, every locally changed path appears with the same status and, for files on disk, the same blob SHA:
  **29 of 29 entries, 288 files matched, 0 mismatches** (155 modified, 90 added, 43 removed); first parent equals the recorded
  HEAD (ancestry preserved). Content spot-checks via `get_file_contents` at the snapshot SHA (blob SHA, size, first and last 200
  characters): `agent-a217…` `game/tests/debug_econ.gd`, `agent-aa29…` `game/data/recipes.json`, `agent-ad98…`
  `docs/HOUSING_LAND_AUDIT.md`: all match. Index snapshots were verified locally (tree equality), not through the API.
- **Not done:** a restore into a fresh clone (no disk for a clone). Restore steps: `git fetch origin
  wip/backup-20261109/<name>-work` then, in a worktree at the recorded HEAD, `git checkout <work snapshot> -- .` (or
  `git diff <HEAD> <work snapshot> | git apply`); the index snapshot restores the staged state the same way with `git read-tree`.

## Isolation correction
- `b25r2` detached at `fe7d8f8` (its files already equal it; nothing changed on disk). No branch is now checked out in two
  worktrees. EMP-03's branch `wip/b25-emp03` (`00e47a6`) is built on `b7884d3`, the current `wip/b25r2-rev2`, not on a PROP-06
  snapshot.

## Disk recovery
- Measured: session scratch area 5.3 GB (`/tmp/claude-0/.../scratchpad`: folders of 100-450 MB from earlier work in this session,
  e.g. `fam` 451 MB, `wt_old` 276 MB (a worktree), `flyover_v3` 267 MB, `b25report` 158 MB, and about ten of ~105 MB; contents
  not yet inventoried, so **not touched**), session transcripts 953 MB and Godot user data 893 MB (test saves and logs: kept), old
  local checkpoint bundles `~/mml-backups` 794 MB (kept: backups), `uv` package cache 425 MB, `pip` cache 15 MB.
- Reclaimed with the tools' own clean commands (download caches only, rebuilt on demand): `uv cache clean` (391.4 MiB) and
  `pip cache purge`. **Free space 89 MB -> 526 MB.**
- Remaining constraint: about 0.5 GB free. Each fresh Godot import or recorded artifact download costs tens to hundreds of MB.

## Remaining risks
- The scratch folders (about 5 GB) are uninventoried; deleting them needs an inventory first and, where they hold evidence not on
  GitHub, the owner's approval.
- The 10 old `agent-*` worktrees and their snapshot branches hold unreviewed work from earlier builds; whether any of it is still
  wanted is undetermined (preserved, not integrated).

## Snapshot inventory
| Worktree | Branch at check | HEAD | Changed files | Work snapshot (GitHub branch `wip/backup-20261109/<name>-work`) | Index snapshot (`-index`) |
|---|---|---|---|---|---|
| agent-a217c774f1de24975 | worktree-agent-a217c774f1de24975 | `4ff0cc9` | 21 | `df8282359c` | `9d7b87d180` |
| agent-a28f3c5d8f920a88e | worktree-agent-a28f3c5d8f920a88e | `6d9ded9` | 9 | `cb3338d03d` | `522e87d1cf` |
| agent-a60c2cbc4621292ca | worktree-agent-a60c2cbc4621292ca | `9b02f8a` | 11 | `861f442dfd` | `d1115550f1` |
| agent-a73835a027337e85e | worktree-agent-a73835a027337e85e | `020bb88` | 14 | `2ee58300b9` | `6178f79393` |
| agent-a801c196c1304eddf | worktree-agent-a801c196c1304eddf | `22490d5` | 28 | `317a84470d` | `f5039bcf6b` |
| agent-aa290624e90a83da5 | worktree-agent-aa290624e90a83da5 | `8d7a9a3` | 34 | `cb7f0d1541` | `193e83e9a8` |
| agent-ab560d4b676bf7b69 | worktree-agent-ab560d4b676bf7b69 | `6d9ded9` | 13 | `7a92a6f83f` | `631dab17a3` |
| agent-ac3f19ceb6d7088ba | worktree-agent-ac3f19ceb6d7088ba | `020bb88` | 14 | `98ccbc715f` | `737ff2d57c` |
| agent-acc7aa6071d10ba12 | worktree-agent-acc7aa6071d10ba12 | `8d7a9a3` | 14 | `7ec0e73846` | `fde050e5e5` |
| agent-ad98d07112ec5147a | worktree-agent-ad98d07112ec5147a | `c8033ac` | 22 | `fbee7c8a9d` | `3dd8ee6291` |
| b25r1-axe | wip/b25r1-axe | `8d05942` | 2 | `f2307b389f` | `e66afef469` |
| b25r1-cicover | wip/b25r1-cicover | `27dfdd6` | 2 | `092ce2a278` | `9c5545d188` |
| b25r1-fix1 | wip/b25r1-fix1 | `5cd1765` | 2 | `6f6ad86fbf` | `61c52bdbbe` |
| b25r1-fix2 | wip/b25r1-fix2 | `2275b92` | 2 | `762a6eeb57` | `29f4412f7c` |
| b25r1-fix3 | wip/b25r1-fix3 | `40f190e` | 2 | `abe765826f` | `9cc11bb7e4` |
| b25r1-grassmap | wip/b25r1-grassmap | `ebf246b` | 2 | `06e16af591` | `9d582a8be4` |
| b25r1-houses | wip/b25r1-houses | `7189e89` | 2 | `8597e62069` | `d0439bc1d5` |
| b25r1-leak | wip/b25r1-leak | `7d60644` | 2 | `acb30461e8` | `fd0113babd` |
| b25r1-net2 | wip/b25r1-net2 | `e7c39f5` | 1 | `a16318423b` | `d1112ed109` |
| b25r1-net3 | wip/b25r1-net3 | `0d1723e` | 1 | `20229bf652` | `cf90dc0da7` |
| b25r1-od16 | wip/b25r1-od16 | `52d2e9d` | 2 | `ac0286db86` | `12a58d06e0` |
| b25r1-presence | wip/b25r1-presence | `711d59d` | 1 | `2f9e7ffda9` | `b5b8eca72d` |
| b25r1-rec-scratch | scratch/b25r1-rec | `0bd00d1` | 3 | `d72a891464` | `18740cbae4` |
| b25r1-region3 | b25r1-region3 | `9ce9a2e` | 1 | `dd7c6ef0b7` | `60f10d0294` |
| b25r1-terrain | wip/b25r1-terrain | `9f54984` | 2 | `d0bae335cf` | `89bc8f226c` |
| b25r1-wellbiz | wip/b25r1-wellbiz | `059909c` | 2 | `c63dda911f` | `00e9b57145` |
| b25r1-winsmoke | wip/b25r1-winsmoke | `5af20c5` | 2 | `9841133c0c` | `281d0ce6cd` |
| b25r2 | wip/b25r2-rev2 | `b7884d3` | 74 | `f1d931f5b7` | `8e4adaf556` |
| wt_old | HEAD | `3c53431` | 3 | `81bacc8312` | `74cd325096` |

Total changed files: 288
