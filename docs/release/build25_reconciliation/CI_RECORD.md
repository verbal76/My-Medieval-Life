# Build 25 candidate CI record (B25-FINISH-01, Phase 3)

Each entry: run, commit, result per shard, failures with cause and correction, and what evidence carries over.

## Run 41576207072, `b00439f` (the Living Economy on by default), dispatched 2026-11-02 23:07 EST

- **Shards 1, 2 and 3:** 121 game suites, 0 failures.
- **Shard 0:** finished after the read at 23:53 EST; its result is read with the next run.

## Run 41580777660, `a72ed0a` (candidate), dispatched 2026-11-02 23:54 EST

| Shard | Result |
|---|---|
| 0 | **Python step FAILED** (1 of 178 unittest tests). Its game suites, the five data checks (interactions, requirements, resources, weapons, materials) and the FR-07 10-day economy run passed |
| 1 | **FAILED**: 40 of 41 suites passed; `od16_test` 4 of 33 checks failed (below) |
| 2 | passed (41 of 41 suites) |
| 3 | passed |

**Failure, read 2026-11-03 00:20 EST:**
- `tests/test_android_export.py`, `AndroidNetworkPermissions.test_each_permission_once`: `AssertionError: 2 != 1 : internet`.

**Root cause:**
- The test counted `permissions/<name>=` lines across the whole `game/export_presets.cfg`.
- DEMO-01 (`ca27195`) added the "Android Demo" preset, the demo's own app, which carries the same four network permissions.
- **Classification:** a test expectation written when the project had one Android preset. Not a game regression and not a CI or environment problem. The exported APKs' permissions are checked separately, in the release workflow (`aapt dump permissions`).

**Correction:** `da7c8c1`, `tests/test_android_export.py` only.
- Each Android preset ("Android", "Android Demo") must name each permission exactly once, with it on.
- A new check pins the package ids: the full game keeps `com.hotatticgames.mymedievallife.dev`; the demo is `com.hotatticgames.mymedievallife.dev.demo`.

**Verification:**
- `python3 -m unittest discover -s tests` passes 179 tests locally on `da7c8c1`; the 179th is the new package-id check.
- `test_android_export`: 5 of 5.

**Evidence carried over:** `da7c8c1` differs from `a72ed0a` only in that test file (`git diff --stat`: 1 file). The game suites, data checks and economy run on `a72ed0a` therefore stand for `da7c8c1`, and no full re-run is made for this test-only change.

**Candidate:** `da7c8c1`, superseded by `c4c3490` because of the shard 1 failure below.

### Shard 1 failure, read 2026-11-03 00:45 EST (the run finished at 00:45 EST; GitHub Actions 04:54-05:45 UTC)

**Failure:** `game/tests/od16_test.gd`, 33 checks, 4 failures:
- "with no axe on sale, the manor orders one for the woodcutter"
- "the poorest smith is paid an axe's worth in advance"
- "the smith buys all the ore two bars need, reserve or not ({ })"
- "the axe is forged and handed to the woodcutter"

The same 4 failures were reproduced locally on `da7c8c1`.

**Root cause:**
- Since the LE-07 activation (`b00439f`), the Living Economy is on by default.
- With the market driving, `NPCBrain._support_trades` hands the manor's tool support to `EconMarket.manor_tools` (LE-04): the manor buys a tool on sale, or else commissions a smith by CON-01 contract. It does not use the `World.manor_orders` advances.
- `test_manor_pays_the_smith_in_advance` and `test_advance_pays_the_orders_inputs` test the economy-off advance rule (OD-16 b, EQ-19, X20-FIREWOOD). Unlike the other economy-off suites, they never pinned the switch off, so they read the shipped default.
- **Classification:** a test expectation, made stale by the approved activation. Not a game regression, and not a CI or environment problem.
- The economy-on behaviour (a purchase or a CON-01 commission, delivery, refusal and lapse) is covered by `le04_test`.

**Correction:** `c4c3490`, in `game/tests/od16_test.gd` only. The two advance tests pin `EconomyFoundation.off_config()`, and the override is cleared afterwards. No game code changed.

**Verification (local, Godot 4.7.2 headless, `c4c3490`):**
- `od16_test`: 46 checks, 0 failures. It now runs 46 checks instead of 33 because the advance test no longer returns early.
- `le04_test`: 68 checks, 0 failures.
- `python3 -m unittest discover -s tests`: 179 tests, OK.
- In the earlier run 41576207072 (`b00439f`), `od16_test` fell in shard 0, whose report was not read. It is not counted as evidence.

**Evidence carried over:** `git diff --stat a72ed0a c4c3490` shows 2 files, both tests (`tests/test_android_export.py` and `game/tests/od16_test.gd`). Every other result of run 41580777660 stands for `c4c3490`:
- shard 0: game suites, five data checks and the FR-07 10-day economy run;
- shard 1: the other 40 suites;
- shards 2 and 3.

No full re-run was made for the two test-only corrections.

## Candidate `c4c3490`: required gates met 2026-11-03 01:03 EST

**Final 365-day flight (E3):** run 41587688728 on `c4c3490`, dispatched 2026-11-03 01:05 EST (06:05 UTC).
- Seeds 1 and 2, 365 days, checkpoints every 10 days, recorded.
- Flight mode, segments of 100 days, Living Economy on (the shipped default).
