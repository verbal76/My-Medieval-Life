# Session recovery (compaction checkpoint)

After a context compaction, or in a fresh session, do not rebuild state from the conversation summary.

## After a compaction

1. Run `CLAUDE.md` section 0, steps 1–8.
2. Read `docs/CURRENT_DEVELOPMENT_STATE.md`: branches, workers in flight, next actions.
3. Read `docs/requirements/views/STATUS.md`, `BUILD_18.md`, `DECISIONS.md` and `QUEUES.md`. These are generated from the
   one register, `docs/requirements/requirements.json`.
4. Before restarting anything, check whether it is still running (workers, GitHub Actions runs).
5. **Expansion 20 (owner, 2026-10-24):** the consolidated scope is the umbrella record `X20-OPEN-ITEMS`, its planning snapshot
   `docs/expansion20/X20_OPEN_ITEMS.md` and the live view `docs/requirements/views/BUILD_20.md`
   (directive `docs/directives/2026-10-24_expansion20_open_items_reconciliation.md`). Recorded only: start nothing until the owner
   authorizes it. Release numbers (Builds 20, 21 and the Build 22 mini-build) are not expansion numbers (the register's `builds` map).

## Before a compaction

Do this at about 70–75% context, where measurable. Do not copy the register into this file.
1. Record any new owner words: a verbatim directive file, then the register record (`tools/requirements_update.py`).
2. Update `docs/CURRENT_DEVELOPMENT_STATE.md`: branches, workers, next actions.
3. Run `python3 tools/check_requirements.py --write`.
4. Commit and push to staging, then confirm the remote head.

Earlier long-form recovery notes are in `docs/handoffs/archive/` (history only).
