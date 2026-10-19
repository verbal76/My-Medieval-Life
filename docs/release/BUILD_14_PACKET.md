# Build 14: private three-platform testing packet

Made under the owner's standing authorization for Builds 14, 15 and 16
(`docs/directives/2026-10-19_builds_14_16_release_authorization.md`, register REL-14-16), as a private draft:
"Keep them private drafts for now". Build 13 and every earlier release are untouched.

| | |
|---|---|
| Build | 14 (stamped through the `build_number` input) |
| Source | `staging/my-medieval-life` at `7dbae4f`, all three platforms from this one commit. Its game code is the same as `5f0a07b`; the commits since change only documents and the register |
| CI on the code | Tests passed on `5f0a07b`: https://github.com/verbal76/My-Medieval-Life/actions/runs/39313936196. The release run repeats the tests before exporting |
| Local tests on that code | 18 Godot suites, 0 failures (run_tests 3,528 checks); Python unittest 83 OK; asset, resource, interaction and requirements checks 0 problems |
| Release run | https://github.com/verbal76/My-Medieval-Life/actions/runs/39315420666 |
| Since Build 13 (`4e76f72`) | the features in `BUILD_14_TESTER_NOTES.md` |

**Artifacts:** the private draft release "My Medieval Life Build 14":
https://github.com/verbal76/My-Medieval-Life/releases/tag/untagged-66641a95ba8b87a2950b

| File | Size | sha256 |
|---|---|---|
| `MyMedievalLife-build14-android.apk` | 64.7 MB | `3526bb328996d47d210e701e8fb7955c58b07a0721a15ab7b8a505ba52672e1e` |
| `MyMedievalLife-build14-windows-x86_64.zip` | 43.2 MB | `cf8f0cc2b072c4472585e0ba45ca844a75f7315311a33841b588f311895b1921` |
| `MyMedievalLife-build14-linux-x86_64.zip` | 33.5 MB | `3071058b256e8d0edb6075280bc5d8b51a1267d738402524b298e9d22a7afecd` |

## Checked here

- All three files were downloaded back from the draft and matched `SHA256SUMS.txt`.
- **Linux:** the build started under a virtual display and drew its title window. The screenshot was looked at: the
  menu buttons are at the top, in view.
- **Windows:** the zip holds `MyMedievalLife.exe`. The release run's icon check passed. Not run.
- **Android:** the APK is signed (it has `META-INF` signature files). Not installed.

## Release conditions (owner, 2026-10-19)

1. **Tests and regression checks:** all pass (above).
2. **Critical problems:** none open.
   - No crash, data corruption or save/load failure is known.
   - Build 13 saves load (`BUILD_14_READINESS.md`).
3. **Long runs:** reviewed (`BUILD_14_READINESS.md`, `LONG_RUN_SIMULATION.md`).
   - The wildlife collapse, the falling population and the lack of new houses are documented as nonblocking
     limitations of this build.
   - They are under investigation for Build 15 (EQ-07, WR-01).
4. **Packages:** all three built and passed the checks above. **No platform was tested on physical hardware:** no
   phone, tablet, controller or Windows PC was used.
5. **Known defects and limitations:** in `BUILD_14_TESTER_NOTES.md` at this commit.
   - Gap: the release page itself shows the workflow's generic testing checklist, not those notes. The workflow
     cannot edit a draft's text after the fact.
   - From Build 15 the release page includes the build's tester notes (`release.yml`).
6. **Unfinished requirements:** all stay in the register and carry over.
7. **Multiplayer:** not in this build. It stays on `wip/multiplayer`.
8. **Commit and packages:** `7dbae4f`, with the three packages under the usual names.

## Android signing

The stable test-key secrets still do not exist. Like every build so far, this APK is signed with a throwaway key,
which was generated on the runner and deleted there.

**For testers:**
- It cannot install over Build 13.
- Uninstall first. Uninstalling deletes the phone's save.
- To keep a save, follow "Moving testers to the stable key" in `ANDROID_SIGNING.md` (it needs `adb`).

## Known issues

See `BUILD_14_TESTER_NOTES.md`, "Known limitations". The main ones:
- Iron, coal and copper run out by game day 10, and the caravan then imports ore.
- Forest animals die out over long games.
- Over many game years the population falls and no houses are built.
- There is no audio.
- Some art is stand-in.
