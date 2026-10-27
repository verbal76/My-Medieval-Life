> **HISTORICAL BUILD / TEST EVIDENCE — NOT CURRENT RELEASE AUTHORITY (owner, 2026-10-27).** Preserve this packet for regression investigation, old test results and provenance, not as the active build, release gate, task list or packaging command. Current build status and policy live in `docs/CURRENT_DEVELOPMENT_STATE.md`, `CLAUDE.md` and the requirements register. Build 22 is the latest private three-platform draft; Expansion 20 remains blocked from packaging until MP-INTERACT-01 merges last and passes validation.

# Build 16: three-platform release packet

Published under the owner's standing release model (`docs/directives/2026-10-21_standing_continuous_release_directive.md`)
and the clarification authorizing publication to the GitHub Releases tab
(`docs/directives/2026-10-21_release_publication_clarification.md`). Build 15 and every earlier release are untouched.

| | |
|---|---|
| Build | 16 (stamped through the `build_number` input) |
| Source | `staging/my-medieval-life` at `b3bbb1c`; its game code, data and workflows are identical to the tested `dbbb66a` (only documents differ) |
| Release run | https://github.com/verbal76/My-Medieval-Life/actions/runs/39631523924 (repeats the tests before exporting) |
| Local tests | 35 Godot suites, 0 failures, on the integrated code; Python unittest OK; requirements, interactions, resources, materials and assets checks 0 problems; determinism gate re-baselined with no coin or item leaks |
| Year-long runs | Actions run 39618523947 on `dbbb66a`, normal game (farming switches off), 365 days, seeds 1-4: all passed (0 script errors, ledgers balanced); starvation 0/0/0/0, no famine; food days at the end 286/282/346/286; houses built 13/9/7/12; cattle herds kept (115-120 calves a seed) |
| Intervention scenarios | 100 days, seed 1, four scenarios: no starvation, no leaks, each intervention changes the course (`LONG_RUN_SIMULATION.md`) |
| Save compatibility | Save version 16. A real save written by the Build 15 code loads, migrates and plays on like a new world of its seed (checked 2026-10-21) |
| Since Build 15 (`a8760be`) | `BUILD_16_TESTER_NOTES.md` |

**Artifacts:** the published release "My Medieval Life Build 16" (tag `build-16`, published 2026-10-21 16:06 UTC, marked
pre-release by the workflow as every test build is): https://github.com/verbal76/My-Medieval-Life/releases/tag/build-16

| File | Size | sha256 |
|---|---|---|
| `MyMedievalLife-build16-android.apk` | 64.9 MB | `2cd5c747c77450cdabdc21ffcbae66a2bfb0a79905300c28f8eb7da196119a50` |
| `MyMedievalLife-build16-windows-x86_64.zip` | 43.5 MB | `dbb8d75a3777ac9104c98e524f3203e3be649fec1a336bfd0a407c0f18fd019a` |
| `MyMedievalLife-build16-linux-x86_64.zip` | 33.7 MB | `a78b2bd745596bdb6c78fbe7b3b093b6f4fd43f0ad301b03b1ae679b29b5f47c` |

## Checked here

- **Downloads:** all three files were downloaded back from the published release and match `SHA256SUMS.txt`; the
  release targets `b3bbb1c` and its page includes the Build 16 tester notes.
- **Linux:** the published build, unzipped, started headless, ran 600 frames and exited 0 with no script errors (also
  checked on a local export of the tested code beforehand).
- **Windows:** the zip holds `MyMedievalLife.exe` (the release run's icon check passed). Not run.
- **Android:** the APK carries its signature files (`META-INF`). Not installed.
- No platform was tested on physical hardware (phone, tablet, controller, Windows PC).

## Android signing

The stable test-key secrets still do not exist, so the APK is signed with a throwaway key generated and deleted on the
runner: it cannot install over Build 15. Export the save first (Settings, Saves), uninstall, install Build 16, import.

## Known issues

See `BUILD_16_TESTER_NOTES.md`, "Known limitations". Also from the year runs: on seed 4 the pig pen died out (3 pigs
starved), a legitimate outcome of the keeper's means under World Design Rule 022. Carried to later work: the FARM-08 yield
and the shared/seasonal farming switches (owner decision), the device checks of farmland placement, stalls and the
armoury counter, DVW-A3 (money supply re-measure), B7-016 and OD-17.
