# Build 18: private playtest release packet

Authorized by the owner on 2026-10-23 for completion overnight and release as a private or access-controlled GitHub
playtest release (`docs/directives/2026-10-23_build18_overnight_completion_release.md`). Not a public release: the repository
is public, so the release stays a draft, visible only to the repository's collaborators. No storefront.

| | |
|---|---|
| Build | 18 (stamped through the `build_number` input) |
| Source | `wip/build18` at `61ec528` (all three platforms from this one commit) |
| Release run | https://github.com/verbal76/My-Medieval-Life/actions/runs/39935635926 (fetches the PC music, imports and runs the tests, exports the three platforms; every step succeeded) |
| Release | draft pre-release "My Medieval Life Build 18" (tag `build-18` on publication), https://github.com/verbal76/My-Medieval-Life/releases (signed in) |
| Visibility | private draft, collaborators only |
| Tester notes | `BUILD_18_TESTER_NOTES.md` (the release description) |

**Artifacts** (downloaded back from the draft in this session; every checksum matches `SHA256SUMS.txt`):

| File | Size | sha256 |
|---|---|---|
| `MyMedievalLife-build18-android.apk` | 86.2 MB | `616facb5e2ab043e89b7a800c9540664c3e316dc9f5709d38e2c8305779d9ac0` |
| `MyMedievalLife-build18-windows-x86_64.zip` | 231.1 MB | `80020d7fea3f738876fc1c4347912e62e5f096839c236ff6314e93482bda4f66` |
| `MyMedievalLife-build18-linux-x86_64.zip` | 221.4 MB | `02f2a5ebba05d0a842a20bd63d03496bb8eb5fde9a65da6b37f11f4b94c79343` |
| `SHA256SUMS.txt` | | checksums of the three |

## Gates (all on the release code or game-code-identical commits)

| Gate | Evidence |
|---|---|
| Suites | all 85 Godot suites pass on `5bdecb7`, game code identical to `61ec528` (later commits: tester notes only); Python unittest OK; interactions, materials, resources and assets checks 0 problems |
| Determinism | `tools/sim_gate.py` on the alms code: PASS, identical to the recorded baseline (seeds 1 and 2, days 10 and 30, no leaks) |
| Long runs | 365 days, seeds 1-4, run 39904513181 on `61ec528`: all reach day 365, currency leak 0, no item leaks, no FATAL line, no script error (`docs/build18/LONG_RUNS_365_ALMS.md`) |
| Alms | `chapel_test::test_alms` (keep, one need per household, order, no double pay, conservation); a probe on the release code shows the alms reach every short household (seed 2: 68 coins in 35 household payments by day 146) |
| Saves | a real Build 17 save loads (`docs/build18/SAVE_MIGRATION.md`); `chapel_test::test_b17_save` on the release code |
| Wiki | `wiki_test` passes; the chapel page describes the alms |
| Packaging | the release run's music step fetched and checked the five WAVs; Windows and Linux carry the five songs as WAV (no song Ogg), Android carries them as Ogg plus 57 sound files (no WAV); the Linux release binary launched headless, 900 frames, exit 0, no errors |

## Android signing

The stable test-key secrets still do not exist, so the APK is signed with a throwaway key (`allow_temporary_key`, as for
Build 17): it cannot install over Build 17. Export the save first (Settings, Saves), uninstall, install Build 18, import.

## Not checked here

No platform tested on physical hardware; the sound was not heard (footstep loudness, fades, phone memory with long WAVs
on PC). Owner-review decisions: `docs/build18/OWNER_REVIEW_DECISIONS.md`.
