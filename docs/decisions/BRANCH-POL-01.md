# BRANCH-POL-01: one code integration branch, short-lived worker branches, audited merges

## Identification
- Decision ID: BRANCH-POL-01 (register `docs/requirements/requirements.json`)
- Date: 2026-11-02
- Project / build: My Medieval Life, during Build 25. Permanent workflow rule, not tied to a build.
- Decided by: owner (policy); agent (how it is applied, below)
- Source of authority: [`docs/directives/2026-11-02_branch_consolidation_worktree_control.md`](../directives/2026-11-02_branch_consolidation_worktree_control.md)
- Status: OWNER APPROVED; applied 2026-11-02 (`wip/expansion20` `d73bd0a`; records on `wip/requirements-control`)
- Related: DOC-RECON-01 review (2026-10-31), which keeps `wip/requirements-control` isolated; HAG-MEM-02; CLAUDE.md sections 5, 5a, 9a, 10.

## Original problem
The owner saw development diverge again about two hours after a four-branch consolidation. They asked for the cause to be fixed,
not only the branch graph.

## What the audit found (2026-11-02, content-based: `git merge-tree` against the integration tip, not ahead/behind counts)
- **Integration branch:** `wip/expansion20`, at `0d194c8` when the audit started (Tests run 41509578455 is running on that SHA),
  `d73bd0a` after the policy commit.
- **Recent worker branches.** 21 of the 22 recent `wip/b25-*` branches are **INTEGRATED**: merging any of them would not change
  the integration tree. This includes the four from the previous consolidation (`b25-ci-green`, `b25-leak2`,
  `b25-chapel-purpose` and `b25-flight-recorder`).
  - Only `wip/b25-home-door` holds unique work: 6 files, in progress.
  - `wip/b25-farm-phase2` and `wip/b25-fr-investigate` are still at the integration head. Their work so far is uncommitted, in
    their worktrees.
- **Why it looked divergent:**
  1. **Three lines, one of them stale and still named as current.** `CLAUDE.md` (both copies) still named
     `staging/my-medieval-life` as "the development branch". In fact:
     - code is integrated on `wip/expansion20`;
     - records live on `wip/requirements-control`, which the owner keeps isolated;
     - `staging` stopped on 2026-11-01 at `baa6479`.
     Its 447 "unique" commits are the old records lineage, not unmerged work.
  2. **Two copies of the rules.** The `CLAUDE.md` on the code branch dated from the Build 18 era. Workers start from the code
     branch, so they read stale rules.
  3. **A branch per task, including read-only ones.** Within minutes of the consolidation the lead created three new task
     branches. One of them (`wip/b25-fr-investigate`) was for a read-only investigation and was pushed only to satisfy a records
     check. There were also two run-only branches (`wip/b25-farm-b1` and `-b2`, both at `8acbdea`), which existed so two
     simulation dispatches would not replace each other in the long-sims concurrency queue.
  4. **No automatic check of stale bases or file overlap before a merge.** The current three workers overlap:
     - all three touch `world.gd`;
     - home-door and the investigation both touch `npc_brain.gd`;
     - home-door and farming both touch `docs/DECISIONS.md` and `docs/SYSTEM_INTERACTION_MANIFEST.md`.

## Decision (policy; CLAUDE.md section 5a)
- **One code integration branch: `wip/expansion20`.** No worker redefines the baseline.
- **Records stay on `wip/requirements-control`,** edited by the lead. Merging the two lines needs the owner (see the open
  question below).
- **Short-lived task branches,** started from the integration head, one owner per file. A read-only investigation gets no branch.
- **Prompt merges.** Run `tools/branch_audit.py --worktrees` before every merge:
  - a stale base is brought up to date by merging the integration branch in first;
  - an overlap is settled by naming one owner per file, merging the first finished branch, and having the other merge it in.
- **No historical ancestry** merged into the integration branch.
- **Nothing deleted while it holds unmerged work.**
- **Every integration recorded:** SHA, source branch and head, tests, conflict decisions.

## Applied today
- `wip/expansion20` `d73bd0a`:
  - a notice and section 5a in its `CLAUDE.md`;
  - `tools/branch_audit.py` (read-only).
  Python suite 178 tests OK.
- On `wip/requirements-control`: the authoritative `CLAUDE.md` names the right branches (sections 0, 5, 5a, 9a and 10); this
  record; the register; the state file; the changelog.
- **Workers told** the integration head, which of their work is integrated, where to submit, and which files they own:
  - home-door merges first;
  - farming Phase 2 merges home-door's changes in before submitting;
  - the investigation stays read-only and commits nothing.
- **Retired:** the `b25-ci-green` worktree. It was INTEGRATED, and its two leftover files were byte-identical to the committed
  ones. Its branch stays on GitHub.
- **Not done:**
  - No historical branch or worktree was deleted. About 60 old worktrees are kept until each is audited.
  - Nothing was merged to tidy the graph.
  - No run was cancelled.

## Why not the alternatives
- **Merging `wip/requirements-control` into `wip/expansion20`** would make one branch. But:
  - it would contradict the owner's 2026-10-31 instruction ("Do not merge wip/requirements-control into staging,
    wip/expansion20, or the gameplay baseline without my approval");
  - it would bring in 300+ files of a different ancestry, which this directive's own "no unnecessary merging of unrelated
    historical branch ancestry" forbids.
  It is raised as an owner question instead.
- **Reviving `staging` as the integration branch** would need its old records lineage reconciled with the code line. That is
  the same unrelated-ancestry problem, and it creates a second competing mainline.
- **Creating `docs/CURRENT_STATE.md` and `docs/OWNER_DECISIONS.md`** as named in the directive would duplicate:
  - `docs/CURRENT_DEVELOPMENT_STATE.md` (the one state file, DOC-CONT-01);
  - the register, with `docs/requirements/views/DECISIONS.md` and `docs/decisions/` (REQ-CTRL-01's one register).
  Those existing records were updated instead.

## Open owner question (BRANCH-POL-Q1)
Should the records line and the code line become one branch? There are two options:
- **(a) Keep them separate (recommended).** Records are written by the lead on `wip/requirements-control`, code is integrated on
  `wip/expansion20`, and the copies of `CLAUDE.md` and the state file on the code line carry a notice pointing to the records
  line.
- **(b) Records into the code line.** Authorize bringing the records into `wip/expansion20` as one reviewed change (the files
  only, not the old ancestry). The records would then follow the code. The cost: every records commit becomes a commit on
  the branch whose SHAs are being tested and run.
