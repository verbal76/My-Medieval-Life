# Session recovery (compaction checkpoint)

After a context compaction, or in a fresh session, do not rebuild state from the conversation summary.

## After a compaction

1. Run `CLAUDE.md` section 0, steps 1–8.
2. Read `docs/CURRENT_DEVELOPMENT_STATE.md`: branches, workers in flight, next actions.
3. Read `docs/requirements/views/STATUS.md`, `BUILD_18.md`, `DECISIONS.md` and `QUEUES.md`. These are generated from the
   one register, `docs/requirements/requirements.json`.
4. Before restarting anything, check whether it is still running (workers, GitHub Actions runs).

## Before a compaction

Do this at about 70–75% context, where measurable. Do not copy the register into this file.
1. Record any new owner words: a verbatim directive file, then the register record (`tools/requirements_update.py`).
2. Update `docs/CURRENT_DEVELOPMENT_STATE.md`: branches, workers, next actions.
3. Run `python3 tools/check_requirements.py --write`.
4. Commit and push to staging, then confirm the remote head.

Earlier long-form recovery notes are in `docs/handoffs/archive/` (history only).
