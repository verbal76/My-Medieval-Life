# Build 25 candidate CI record (B25-FINISH-01, Phase 3)

Each entry: run, commit, result per shard, failures with cause and correction, and what evidence carries over.

## Run 41576207072, `b00439f` (the Living Economy on by default), dispatched 2026-11-02 23:07 EST

- **Shards 1, 2 and 3:** 121 game suites, 0 failures.
- **Shard 0:** finished after the read at 23:53 EST; its result is read with the next run.

## Run 41580777660, `a72ed0a` (candidate), dispatched 2026-11-02 23:54 EST

| Shard | Result |
|---|---|
| 0 | **Python step FAILED** (1 of 178 unittest tests). Its game suites, the five data checks (interactions, requirements, resources, weapons, materials) and the FR-07 10-day economy run passed |
| 1 | running at 00:22 EST |
| 2 | running at 00:22 EST |
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

**Candidate:** `da7c8c1`. The final 365-day flight is dispatched on it once shards 1 and 2 of run 41580777660 pass.
