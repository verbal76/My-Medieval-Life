# Session recovery (compaction checkpoint)

After a context compaction, or in a fresh session, do not rebuild state from the conversation summary.

## After a compaction

1. Run `CLAUDE.md` section 0, steps 1–8.
2. Read `docs/CURRENT_DEVELOPMENT_STATE.md`: branches, workers in flight, next actions.
3. Read `docs/expansions/README.md` and the status file of the work in hand (DOC-RECON-01, 2026-10-31), then the generated
   views `docs/requirements/views/STATUS.md`, `DECISIONS.md` and `QUEUES.md` (from the one register,
   `docs/requirements/requirements.json`). The views named `BUILD_NN.md` are by expansion number, not release build.
4. Before restarting anything, check whether it is still running (workers, GitHub Actions runs).
5. **Build sequence (owner, 2026-10-31, BUILD-SEQ-25-27):** Build 25 = Expansion 20 validation and freeze (`wip/expansion20`
   `ad281dc`); Build 26 = repository recovery and consolidation; Build 27 = Expansion 21 only on explicit authorization.
   The 2026-10-24 Expansion 20 open-items note that stood here is historical (`docs/handoffs/archive/`, X20_OPEN_ITEMS).

## Before a compaction

Do this at about 70–75% context, where measurable. Do not copy the register into this file.
1. Record any new owner words: a verbatim directive file, then the register record (`tools/requirements_update.py`).
2. Update `docs/CURRENT_DEVELOPMENT_STATE.md`: branches, workers, next actions.
3. Run `python3 tools/check_requirements.py --write`.
4. Commit and push to staging, then confirm the remote head.

Earlier long-form recovery notes are in `docs/handoffs/archive/` (history only).
