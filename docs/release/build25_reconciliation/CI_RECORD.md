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

### Final flight result, read 2026-11-03 06:03 EST

The campaign finished at 05:58 EST (GitHub Actions 06:05-10:58 UTC). The four segments of each seed and both analyses passed. The step that fails on a defect did not trigger in any segment or analysis.

| Seed | Days | Stopped | CRITICAL | HIGH | MEDIUM | Confirmed defects | Archive and workbook |
|---|---|---|---|---|---|---|---|
| 1 | 365 of 365 | completed | 0 | 32 | 39 | 0 | ok (analysis job 125870169396) |
| 2 | 365 of 365 | completed | 0 | 58 | 14 | 0 | ok (analysis job 125864218439; also 9 INFORMATIONAL) |

- Seed 2's top HIGH findings are repeated failed trades: buying logs or coal, selling building blocks, and refused trades. For example, F001: p:68 failed to sell building blocks 2,380 times in a row from day 127.
- These are recorded as measurements, not confirmed defects: under the existing acceptance rules only CRITICAL findings and confirmed defects block, and the analyser confirmed none (WDR-022).
- Artifacts: `fr-seed1-results`, `fr-seed2-results` and `flight-recorder-campaign` (artifact 13225470964).

**Verdict: the final flight on `c4c3490` is clean.** Packaging was dispatched at 06:03 EST: `release.yml` run 41624309659, private, build number 25, on `c4c3490`.

## Release run 41624309659 on `c4c3490` (dispatched 2026-11-03 06:03 EST): FAILED at the simulation gate; no draft release created

**Packages (all passed, 06:03-06:14 EST):** six package jobs, plus Windows launch smoke tests of the full game and the demo.
- Android full: `com.hotatticgames.mymedievallife.dev`.
- Android demo: `com.hotatticgames.mymedievallife.dev.demo`.
- Both APKs: versionCode 25, versionName 0.1.25-test, signed with APK schemes v2 and v3 by the release identity (CN=Hot Attic Games, certificate SHA-256 `31704b80...cb80e6`), each with the four network permissions.
- The signing key was removed from the runner after each Android job.

**Simulation gate (SIM-GATE-01), 06:03-07:26 EST:** FAIL, 1 blocking failure of 19 runs.
- `social_chain_off`: "recorder output invalid: flag aspiration is True in the recording; the scenario requires False".
- Accepted baseline: identical, 36 values.
- Determinism: identical with the shipped switches and with the Expansion 20 switches.
- Results: artifact `sim-gate` (13229554670).

**Root cause:**
- `tools/sim_suite.py` `SHIPPED_FLAGS` still listed `aspiration: False`.
- Since the owner's B25-AMBITION-D4 (`eeae76e`, 2026-11-01), `judgment.json` ships `aspiration.enabled: true`, so the recording was correct.
- **Classification:** a stale expectation in the gate harness. Not a game defect.

**Correction:** `726ceeb`, `tools/sim_suite.py` only.
- `SHIPPED_FLAGS` now records aspiration as True.
- The scenario's description is corrected to match.
- No game code changed, so the final flight on `c4c3490` stands for `726ceeb`: `git diff --stat c4c3490 726ceeb` shows 1 file, `tools/sim_suite.py`.

**Verification:**
- `tests/test_sim_gate.py` passes 36 of 36.
- A local targeted run (`sim_suite --only social_chain_off`) reached day 10 of 15 with exact save round trips and 0 claims breaches, then stopped when the session's container restarted. It was not repeated.
- The release workflow reruns the full gate on the corrected commit, and that is the gate of record: release run 41648387967 on `726ceeb` (private, build 25), dispatched 2026-11-03 08:53 EST.

## Release run 41648387967 on `726ceeb`: PASSED; private draft release created 2026-11-03 09:55 EST

- Ran 08:53-09:55 EST. All six package jobs passed, as did both Windows launch smoke tests (full and demo) and the simulation gate (SIM-GATE-01 PASS on this commit, checked by the release job; artifact `sim-gate` 13240502316).
- Draft release "My Medieval Life — Build 25": tag `build-25`, release id 432836586, draft and prerelease, target `726ceeb`. Not public; not uploaded to Steam.
- Android: both APKs signed by the permanent release identity. Full game: `com.hotatticgames.mymedievallife.dev`. Demo: `com.hotatticgames.mymedievallife.dev.demo`. versionCode 25.

| File | Bytes | SHA-256 |
|---|---|---|
| MyMedievalLife-B25-Android.apk | 91,838,153 | `53268b35d060144b3be1fdc24a8b652b1064360982f8bf5a50c439385dff5fcd` |
| MyMedievalLife-B25-Windows.zip | 234,440,077 | `328c57996a95b4e2431a9624bc7d16bd8f849ca04aece1f8e197a7a16a8e66ad` |
| MyMedievalLife-B25-Linux.zip | 224,685,322 | `715cb9e00ab4235a685e549749e14a2072adf3bd108ebfb0b84f60b3dfb450de` |
| MyMedievalLife-B25-Demo-Android.apk | 91,838,153 | `f3f4c64d352326a1baaa974dc2109f23caf6cf5e645f95e88e5a0a3973a76d83` |
| MyMedievalLife-B25-Demo-Windows.zip | 234,440,119 | `aa499a3c95ec3c1b311452ae22cff411030205908bb7cfe1815389b736e8349d` |
| MyMedievalLife-B25-Demo-Linux.zip | 224,685,351 | `0bc0f5570b1cabd65517fff86f395a8061b0ed6c504d781ec31765947de10c21` |

The release also carries `SHA256SUMS.txt`, `SIZES.txt`, each APK's `.idsig` file and the two signature reports.

**Known issue found after packaging (owner report, 2026-11-03 09:10 EST):** settlement-site buildings outside the village (REGION-NAV-01 S2a, `909b180`) are drawn by `OverworldView._draw_site_buildings` entirely over the characters. They lack the GP-DRAW-UNDER-HOUSE front-wall sorting, so a character at a settlement building's front wall is drawn half under it.
- Village buildings are correct: `polish_p2_test` passes 104 of 104, and 8 `house_front_shot` screenshots were looked at.
- The fix and its timing (in Build 25 or after) await the owner's decision.
