# B42 recorder reservation check: verification evidence (Agent I, 2026-11-14)

Branch `wip/b42-recorder-reservation`, commits d1a6242, 1d1f2cb, 3f63280 (all from 0bbee94). The changes are in the flight
recorder only: `world_recorder.gd`, a 2-line call in `world.gd` after `economy.dawn()`, `recorder_codes.json` text,
`recorder_test.gd` and DECISIONS rows. Why: DECISIONS.md, rows of 2026-11-14 (B42 recorder).

| check | commit | result |
|---|---|---|
| failing-first, B42 dawn-reconcile checks | 0bbee94 (recorder unchanged) | 8 checks, 5 failures (red, as intended) |
| B42 dawn-reconcile checks | d1a6242 | 8 checks, 0 failures |
| full `recorder_test` | d1a6242 | 222 checks, 0 failures |
| failing-first, B42 earmark checks | d1a6242 | 12 checks, 2 failures (red, as intended) |
| B42 checks | 1d1f2cb and 3f63280 | 12 checks, 0 failures |
| full `recorder_test` | 1d1f2cb | 226 checks, 0 failures |
| full `recorder_test` | 3f63280 | 226 checks, 0 failures |
| recorder on/off, 10 days seed 1 (`economy_sim.gd -- --days 10 --seed 1` with and without `--record`) | d1a6242, 1d1f2cb, 3f63280 | day lines and fingerprint identical on and off at each commit: fingerprint 893ced03f2d0dbb2582121538cde78f5, judgment state hash 2716197525 (the 0bbee94 base log matched line for line); 0 script errors |
| `tools/recorder_archive.py` on the recorded 10-day run | d1a6242, 1d1f2cb, 3f63280 | ok, no problems |
| unbacked-reservation violations in the recorded 10-day run | d1a6242 / 3f63280 | 3 (all npc:39 milk, earmark of contract 22) / 0, recorded as earmark_short |
| B42 checks with cause labels (confirmed, suspected, unknown) and the reservation summary, failing-first | 3f63280 | 12 checks, 2 failures and "Nonexistent function holder_spoiled" (red, as intended) |
| B42 checks | 518780e | 16 checks, 0 failures |
| full `recorder_test` | 518780e | 230 checks, 0 failures |
| recorder on/off, 10 days seed 1 | 518780e | identical; fingerprint 893ced03f2d0dbb2582121538cde78f5, judgment state hash 2716197525; coins leak 0, item leaks 0, 0 script errors; archive ok; 0 unbacked violations. The recorded run says "npc:39:milk short 1, confirmed spoilage (1 milk spoiled from npc:39's own stock on day 9 at 06:00, Decay.spoil_inv)" and "violations 0; earmark short 1 claim, 1 milk", which matches the instrumented trace |
| Python flight tests (test_flight_analyse, test_flight_lives, test_sim_gate) | d1a6242, 1d1f2cb | 55 tests, OK, 1 skipped |

The logs were in /dev/shm and went with container restarts; this note keeps the results. The cause of the npc:39 milk shortfall
is under investigation (B42-EARMARK-SHORT, owner follow-up 2026-11-14). Reclassifying the shortfall in the recorder does not
resolve that discrepancy.
