# Build 15: private three-platform testing packet

Released under the owner's authorizations: OVN-01 section 9, REL-15-18, and the final mandate OVN-02 section 7
("Publish Build 15 using the previously authorized private-draft release procedure"). It is a private draft. Build 14
and every earlier release are untouched.

| | |
|---|---|
| Build | 15 (stamped through the `build_number` input) |
| Source | `staging/my-medieval-life` at `a8760be`, all three platforms from this one commit |
| CI | Tests run 39422392099 on `a8760be`. The release run repeats the tests before exporting |
| Local tests on that code | 25 Godot suites, 0 failures; Python unittest OK; the asset, resource, interaction, material and requirements checks report 0 problems; the determinism gate passes |
| Year-long runs | Actions 39408961143 on `3e326fd` (`BUILD_15_READINESS.md`; `LONG_RUN_SIMULATION.md`) |
| Release run | https://github.com/verbal76/My-Medieval-Life/actions/runs/39422414211 |
| Since Build 14 (`7dbae4f`) | `BUILD_15_TESTER_NOTES.md`, which the release page includes |

**Artifacts:** the private draft release "My Medieval Life Build 15":
https://github.com/verbal76/My-Medieval-Life/releases/tag/untagged-65f08d4328eb64be1d6b (tag `build-15`).

| File | Size | sha256 |
|---|---|---|
| `MyMedievalLife-build15-android.apk` | 64.8 MB | `2e4498d138989b1f47620ed42d66d3c3371e93acb52edaccf387825352b48916` |
| `MyMedievalLife-build15-windows-x86_64.zip` | 43.3 MB | `4a4b6210c3106a881bfe71f71cce20d58c8f4e7bf63d8aeb8a967dd8810f4f42` |
| `MyMedievalLife-build15-linux-x86_64.zip` | 33.6 MB | `9129ddd8a6a8a38f2c0ef809faaca4488a5fdc0f7532da70db53ae7a24dadd79` |

## Checked here

- **Downloads:** all three files were downloaded back from the draft and matched `SHA256SUMS.txt`. The draft's target is
  `a8760be`, and its page includes the Build 15 tester notes.
- **Linux:** the build ran under a virtual display and started a new game. The screenshot was looked at: the village,
  the HUD, the player and villagers drew correctly. The only messages were the headless machine having no sound device.
- **Windows:** the zip holds `MyMedievalLife.exe`, and `tools/check_exe_icon.py` confirms it carries the game's icon.
  Not run.
- **Android:** the APK is signed (it has `META-INF` signature files). Not installed.

## Release conditions

Every condition is recorded with its evidence in `BUILD_15_READINESS.md`: the owner's closure standard (OVN-02
section 5) and OVN-01 section 4.
- There are no open defects. The findings are classified under World Design Rule 022.
- Multiplayer is not in the build; it stays on `wip/multiplayer`.
- **No platform was tested on physical hardware:** no phone, tablet, controller or Windows PC was used.

## Android signing

The stable test-key secrets still do not exist. Like every build so far, this APK is signed with a throwaway key,
which was generated on the runner and deleted there.

**For testers:**
- It cannot install over Build 14.
- Export the save first (Settings, Saves), uninstall, install Build 15, then import the save.
- Nobody has tried that route on a phone yet.

## Known issues

See `BUILD_15_TESTER_NOTES.md`, "Known limitations". The main ones:
- **The village can struggle, by design** ("A village is allowed to fail. The simulation is not."). Once the coal seams
  are worked out the smith is often too poor to buy coal. Timber and firewood run short later in the year.
- The small room fits beside only three original houses.
- There is no audio, and some art is stand-in.
