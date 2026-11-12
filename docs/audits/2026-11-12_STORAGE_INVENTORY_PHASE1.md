# Storage recovery: Phase 1 inventory (owner "Maximum-safety storage recovery directive", 2026-11-12)

Read only; nothing deleted. Free space 510 MB of 258,020 MB (used 39,377 MB; the session's allowance is the limit, not the volume).
Scratch = `/tmp/claude-0/-home-user/754052d8-fb21-5c64-b3f9-641f462e2c23/scratchpad`. Checked for every target: canonical path
(no target is a symlink), every file walked without following links (0 symlinks, 0 hard-linked files, 0 mount points inside any
target), open files and processes (none), Git repositories inside, and file kinds. Inventory script `scratch/tools/inventory.py`,
raw output `scratch/inventory_phase1.json`.

| Target | Size | Files / dirs | Git | What it is | Classification | Why |
|---|---|---|---|---|---|---|
| `/home/user/inventory-src` | 1,606 MB (all in `.git`) | 22 no-checkout clones | 22 repos; no stashes, no unpushed branch commits, no changes; **18 hold commits no remote-tracking ref contains** (e.g. Idle-game 20, others 1) | Oct 18 blobless clones for the studio registry | UNKNOWN | The local-only commits found so far are GitHub's pull-request test merges (`refs/pull/N/merge`, e.g. Idle-game `6bc1e01` = pull/66/merge), not local work; each must be confirmed present on GitHub (Phase 2) |
| scratch `icons` | 38 MB | 26 files, 25 clones | 25 repos; 0 local-only commits, 0 stashes, 0 changes | Nov 10 blobless clones made for the icon inventory (read-only; nothing local) | SAFE (pending Phase 2 remote check) | Every commit is reachable from a remote-tracking ref |
| scratch `ico` | 109 MB | 1 file `MyMedievalLife.exe` (Oct 18) | none | A downloaded Windows build | UNKNOWN | Must match a GitHub release asset (hash) to count as reproducible |
| scratch `b9` | 106 MB | 3: `MyMedievalLife.x86_64`, `lin.zip`, `t.png` (Oct 18) | none | A downloaded Linux build and a screenshot | UNKNOWN | Binary must match a release asset; the screenshot's purpose is uncertain |
| scratch `flyover_v3` | 266 MB | 273 (266 PNG, `post.py`, `run.log`, 3 JSON, 1 .sh) | none | Nov 5 aerial flyover renders and their post-processing script | UNKNOWN | `post.py`/the .sh may not be committed; renders are regenerable only if the script is |
| scratch `f015pop` (rest) | 43 MB | 115 files | none | F015 population worker's files: report (in repo), scripts, campaign extracts | **UNSAFE** | Holds two campaign saves (`b4_st3/state.gz`, `fp_st3/state.gz`, copies of CI artifacts that expire 2026-12-10): protected campaign checkpoints |
| scratch `inv02` | 75 MB | 11,889 | none (a copied game tree incl. `.godot` cache, 545 .gd) | INV-02 spoilage prototype comparison: base tree plus base/on/off/probe run logs (Nov 10) | **UNSAFE** | Run logs are the INV-02 prototype's evidence; the copied .gd tree must be shown identical to a commit |
| scratch `smoke` | 65 MB | 15,952 (recorder chunks, gate.json, workbook) | none | Oct 27 simulation-gate output (local or downloaded) | UNKNOWN | Origin and whether a copy exists on GitHub not established; test evidence |
| scratch `ci` | 95 MB | 2,159 (1,781 job logs, 26 zips) | none | Downloaded CI job logs and artifacts (Nov 6) | UNKNOWN | Copies of CI evidence; GitHub retention per run not yet checked |
| scratch `gate` | 81 MB | 218 | none | Nov 7 simulation-gate results (gate.json, summaries, workbooks) | UNKNOWN | Gate evidence; needs matching to a still-available CI artifact |
| scratch `x20f` | 45 MB | 12,745 (recorder chunks, test logs, `.sh`, `.bak`) | none | Oct 27 X20 local test runs | **UNSAFE** | Local run logs and scripts of uncertain uniqueness (no CI copy known) |
| scratch `inv_bc` | 63 MB | 3,584 recorder chunks + 1 JSON | none | Nov 10 recorder archive extract (the INV-B/C investigations) | UNKNOWN | Investigation evidence; needs matching to its CI artifact |

Totals: SAFE 38 MB; UNKNOWN about 2,280 MB (inventory-src 1,606 MB is the largest); UNSAFE about 163 MB.
