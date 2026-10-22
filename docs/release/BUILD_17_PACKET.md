# Build 17: private playtest release packet

Authorized by the owner on 2026-10-22 as a personal playable test release, not a public release
(`docs/directives/2026-10-22_build17_personal_playtest_release.md`). Build 16 and every earlier release are untouched.

| | |
|---|---|
| Build | 17 (stamped through the `build_number` input) |
| Source | `wip/build17` at `80e6b99`; game code identical to the validated release candidate `cd7439c` except the wiki's wording (`3dcd583`: plain resource pages, the prospector's job page) |
| Release run | https://github.com/verbal76/My-Medieval-Life/actions/runs/39706003658 (imports and runs the tests before exporting; all steps succeeded) |
| Visibility | Private draft, pre-release, visible to the repository's collaborators only |
| Evidence reused | CI Tests 39689213264 on `cd7439c`: success; determinism gate on `cd7439c`: two independent runs identical (`DETERMINISM_GATE.md`); 365-day runs seeds 1-4: no leaks, errors or FATAL (`docs/build17/MIN_G_LONG_RUNS.md`); Build 16 save loads in Build 17 (`docs/build17/SAVE_MIGRATION.md`) |
| Tester notes | `BUILD_17_TESTER_NOTES.md` (the release description) |

**Artifacts** (draft release "My Medieval Life Build 17", tag `build-17` on publication; open the repository's Releases
page while signed in):

| File | Size |
|---|---|
| `MyMedievalLife-build17-android.apk` | 65.3 MB |
| `MyMedievalLife-build17-windows-x86_64.zip` | 43.8 MB |
| `MyMedievalLife-build17-linux-x86_64.zip` | 34.1 MB |
| `SHA256SUMS.txt` | checksums of the three |

## Checked here

- **Launch:** the release code (`80e6b99`) started headless in this session, ran 600 frames and exited 0 with no script
  errors. The published zip itself was not downloaded (a draft's files need a signed-in download this session cannot make).
- **Save and load:** covered by the suites the release run repeated (save round trips) and the real Build 16 save loaded
  into Build 17 (`SAVE_MIGRATION.md`); not repeated on the packaged build.
- **Visual:** the new item icons looked at (shovel blade and timber support read poorly; listed as known limitations).
- No platform was tested on physical hardware.

## Android signing

The stable test-key secrets still do not exist, so the APK is signed with a throwaway key (`SIGNING: temporary` in the
run): it cannot install over Build 16. Export the save first (Settings, Saves), uninstall, install Build 17, import.
