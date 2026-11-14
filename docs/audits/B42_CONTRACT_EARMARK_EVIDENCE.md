# B42 contract-earmark reservation defect: verification evidence (Agent I, 2026-11-14)

Branch `wip/b42-contract-earmark` from 0bbee94: a11a082 (fix), ff307a5 (INT-784 placement). Why: DECISIONS.md row of 2026-11-14
(B42 reservation defect) and INT-784.

| check | result |
|---|---|
| `b42_earmark_eat_test`, failing-first at 0bbee94 | 10 checks, 7 failures (the earmarked milk was eaten; the contract's cheese then failed for "materials") |
| `b42_earmark_eat_test` at ff307a5 | 10 checks, 0 failures |
| le03_economy 38/0, le03_claims 81/0, le03_transactions 79/0, economy_foundation 89/0, economy_model 112/0, econ_p2p3 25/0, le02_market 102/0, le04 68/0, le05 11/0, meal_claims 14/0, trd03_player_chest_claims 6/0, contracts 154/0, contract_sign 21/0, contract_50ore 19/0, contract_funds 10/0 | all 0 failures, 0 script errors |
| `recorder_test` at ff307a5 | 214 checks, 0 failures |
| 10-day seed 1, recorder off and on | identical; fingerprint 893ced03f2d0dbb2582121538cde78f5 and judgment state hash 2716197525, the same as 0bbee94 (no villager tried to eat or store a claimed unit in those 10 days, so behaviour is unchanged there); coins leak 0, item leaks 0, 0 script errors; recorder archive check ok |
| `tools/check_interactions.py` | 449 interactions, 0 problems |

Root-cause trace of the triggering case (npc:39, seed 1): the milk was lost to spoilage in its own pack. That is not this defect,
which the same audit found in two paths that ignored claims. See wip/b42-recorder-reservation, docs/audits/B42_RECORDER_RESERVATION_EVIDENCE.md and DECISIONS.
