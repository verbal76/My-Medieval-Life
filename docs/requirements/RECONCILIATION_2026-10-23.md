# Requirements reconciliation of 2026-10-23

Written by `python3 tools/requirements_migrate_v2.py` (owner directive `docs/directives/2026-10-23_master_requirements_reconciliation.md`).
The line-by-line ledger is `docs/requirements/reconciliation_2026-10-23.json`: one line per original record in each
distinct copy of the register, with its canonical id, the action taken and why. A frozen record of the reconciliation.

| | Count |
|---|---|
| Branches carrying a copy of the register | 76 |
| Distinct copies (by content) | 28 |
| Original records inspected (every record in every distinct copy) | 15760 |
| Unique ids in the copies | 742 |
| Ids missing from the staging register, recovered | 72 |
| Ids identical on every copy | 518 |
| Ids with several versions (the latest kept; the others are earlier states) | 222 |
| Ids whose copies recorded different changes (histories merged) | 2 |
| Records added from documents (never registered) | 33 |
| Aliases recorded (other numberings of existing records) | 5 |
| Evidence corrections applied | 70 |
| Superseded records preserved (linked to their replacement) | 24 |
| Canonical records now | 775 |
| Unresolved conflicts between copies | 0 (no id had two copies with conflicting content and no common history) |

Duplicates by meaning: the register already linked them as SUPERSEDED (e.g. OWN-24 -> FR-01, F-3 -> FR-08, K-3 -> OD-02,
REQ-BANDIT -> WDR-016-C). New this time: STONE-05 is met by SKILL-TRADES-18 (Masonry, the owner's "Masonry (stoneworking)"),
linked as related, both kept; CARAVAN-TMP is superseded by ECON-P1.3 (owner answer 2026-10-23).

## Recovered ids (missing from staging, present on the build line)

B17-DIR, CON-02, CON-03, CON-04, CON-05, CON-06, CON-07, CON-08, CON-08-Q, CON02-S-1, CON02-S-2, CON02-S-3, CON02-S-4, CON02-S-5, CON02-S-6, EARTH-01, HEALTH-01, INFO-01, JOB-01, JOB-02, LOG-01, MAINT-01, MIN-C-Q1, MIN-C-Q2, MIN-C-Q3, MIN-COLLAPSE, MIN-D-Q1, MIN-D-Q2, MIN-D-Q3, MIN-D2, MIN-D3, MIN-E-Q1, MIN-E-Q2, MIN-E-Q3, MIN-E-Q4, MIN-E-Q5, MIN-EQUIP, MIN-F-Q1, MIN-F-Q2, MIN-F-Q3, MIN-F-Q4, MIN-F-Q5, MIN-F2, MIN-F2-Q1, MIN-F2-Q2, MIN-RIGHTS, MIN-SHOVEL, MIN-SKILLCAP, MIN-STONE-Q, OD01-QUEST, PIT-02, Q-C1, Q-C2, Q-C3, Q-C4, Q-C5, Q-C6, Q-C7, Q-C8, Q-C9, SIM-B17, STONE-01, STONE-02, STONE-03, STONE-04, STONE-05, STONE-06, STONE-Q, STONE-Q1, STONE-Q2, STONE-Q3, WIKI-B17

## Needs review (human; not mechanically checkable)

| ID | Why |
|---|---|
| B16-AUDIT | closure review against its acceptance criteria (human review) |
| B16-READY | closure review against its acceptance criteria (human review) |
| DVW-A3 | unknown: needs a human review of what remains |
| FARM-08 | unknown: needs a human review of what remains |
| FSE-00 | closure review against its acceptance criteria (human review) |
| PERF-01 | unknown: needs a human review of what remains |
| Q18-11 | Levels 0-10 for all productive industries; AdjustedPay = BasePay x PayMultiplier(industry, level); AdjustedOutput = BaseOutput x OutputMultiplier(industry, level); diminishing returns; industry-specific; numbers and comp |
| Q18-6 | Agent reading, not an owner answer: settled by Q18-3 (each settlement a simulated economy under the same rules, so profiles diverge). Needs the owner's confirmation. |
| WDR-018-C | compliance audit against the rule's verification scenario (human review) |
| WDR-020-C | compliance audit against the rule's verification scenario (human review) |
| WDR-021-C | compliance audit against the rule's verification scenario (human review) |
| WDR-022-C | unknown: needs a human review of what remains |
| WIKI-B17 | unknown: needs a human review of what remains |
| X19-DECAY | Held, provisional: half-life 2 game years (16 game days on the 8-day year) per deed in the observer's ledger; murder and assault permanent; deterministic. The owner asked for the calendar to be explained before finalizin |

Aliases not applied (uncertain): OD-1..OD-9 in docs/release/BUILD_14_OPEN_ITEMS_AUDIT.md look like OD-01..OD-09 but
were not verified; the consolidated Build 17 directive's own MIN-E-Q4 and MIN-E-Q5 collide with register ids of other
meaning (its header maps them to MIN-E-Q2 and MIN-E-Q3); INV-18-01..13 in the INV-18 directive are its numbered
requirements, covered by INV-18's acceptance criteria, not separate records.

