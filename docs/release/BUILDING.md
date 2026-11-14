# Building Forge My Life

All three platforms are built by `.github/workflows/release.yml`, started by hand on an approved
commit (never on a push; CLAUDE.md section 5). One run builds Linux, Windows and Android from the
same commit with the same build number (the run number) and publishes them together as a GitHub
Release (a pre-release unless built from `main`), with `SHA256SUMS.txt` and release notes that name
the commit and include `docs/release/TESTING_CHECKLIST.md`.

The packages are named `ForgeMyLife-B<n>-Android.apk`, `ForgeMyLife-B<n>-Windows.zip` (holding `ForgeMyLife.exe`) and
`ForgeMyLife-B<n>-Linux.zip` (holding `ForgeMyLife.x86_64`), with `-Demo` before the platform for the demo edition
(owner rename to Forge My Life, 2026-11-13, NAME-01). Builds up to Build 40 were named `MyMedievalLife-...`; their
records keep those names. The Android application id stays `com.hotatticgames.mymedievallife.dev` (`ANDROID_SIGNING.md`).
Steam: the game's App ID is 5615690; nothing is uploaded to Steam without the owner's explicit authorization.

## Build dependencies

| Dependency | Version | What for | Where it comes from |
|---|---|---|---|
| Godot | 4.7.2 stable, with its export templates | the game and all three exports | godotengine/godot GitHub release (installed by the workflow) |
| Java (Temurin) | 17 | Android export | `actions/setup-java` |
| Android SDK | the runner's preinstalled SDK | Android export | GitHub's ubuntu runner |
| Android release key | the owner's permanent keystore in the secrets `ANDROID_RELEASE_KEYSTORE_BASE64`, `ANDROID_RELEASE_KEYSTORE_PASSWORD`, `ANDROID_RELEASE_KEY_ALIAS`, `ANDROID_RELEASE_KEY_PASSWORD` (no fallback key: a missing secret stops the build) | signing the APK with `apksigner` so builds from Build 21 update each other (`ANDROID_SIGNING.md`) | the owner (secrets) |
| Python | 3.12 | the Windows icon check | `actions/setup-python` |
| Pillow | 10.4.0 | the Windows icon check (decodes the icon images) | PyPI |

**The Windows icon needs no extra tool.** Godot 4.7 writes the icon into the `.exe` itself when the
Windows preset has `application/modify_resources=true` and `application/icon` set; it no longer needs
rcedit or Wine. The icon is `game/assets/icon/icon.ico` (16 to 256 px), made by
`tools/import_game_assets.py` from the owner's `My_Medieval_Life_Icon_Pack.zip`.

**Every Windows build is checked:** `tools/check_exe_icon.py` reads the icon resources out of the
exported `.exe` and compares each image, pixel by pixel, with the approved artwork; the build fails
on a mismatch (Godot's default icon differs by about 80 out of 255 per channel; the right icon by 0).

## Building locally (no release)

    cd game
    godot --headless --path . --import
    godot --headless --path . --export-release "Linux" ../out/pc/linux/ForgeMyLife.x86_64
    godot --headless --path . --export-release "Windows Desktop" ../out/pc/windows/ForgeMyLife.exe
    python3 ../tools/check_exe_icon.py ../out/pc/windows/ForgeMyLife.exe
    godot --headless --path . --export-debug "Android" ../out/forgemylife-dev.apk   # DEVELOPMENT/TEST ONLY: needs the Android SDK and a keystore in the editor settings

## Android: development builds and production packages (B42-ANDROID-DEBUGGABLE)

Two configurations, never mixed (owner directive 2026-11-14, item 5):

| | Development / test APK | Production package (release.yml) |
|---|---|---|
| Export | `godot --export-debug "Android"` (local) | `godot --export-release "Android"` / `"Android Demo"`, `package/signed=false` |
| Godot template | `android_debug.apk`: debug engine, `android:debuggable=true` | `android_release.apk`: release engine, no `android:debuggable` |
| Signing | Godot's debug keystore from the editor settings | zipalign, then `apksigner` with the permanent `ANDROID_RELEASE_*` key (`ANDROID_SIGNING.md`) |
| Version | the preset's placeholders (code 1, `0.1.0-dev`) | code = the build number, name `0.1.<n>-test` |
| Shared? | never: not a release package | the release's APKs |

Every production APK passes `tools/check_android_apk.py` in its package job and again in the release job before anything is
published: it reads the APK's own compiled manifest (`tools/axml.py`) and `apksigner verify --print-certs`, and fails on
`android:debuggable` or `android:testOnly` true, a package id other than `com.hotatticgames.mymedievallife.dev` (full) or
`com.hotatticgames.mymedievallife.dev.demo` (demo), a versionCode other than the build number, a versionName other than
`0.1.<n>-test`, a signature that does not verify, more than one signer, a certificate other than the permanent one
(SHA-256 `31704b8025a4585cf4119e268ee6c8b30d5a39d1c62cdc00eecf0b7e76cb80e6`), or no v2/v3 signature. The expected values are
in `tools/release_requirements.json` ("android").

Why the earlier packages were debuggable: the first release workflow (c13c54b, 2026-10-18) exported Android with
`--export-debug` so that Godot signed it with its debug keystore (there was no release key yet). When the permanent key
came (8f38920, Build 21) Godot's export became unsigned and `apksigner` re-signed it, but the export stayed a debug one, so
Builds 21 to 41 shipped Godot's debug template (`android:debuggable=true`, debug engine). Re-signing changes the
signature, not the manifest. Checked locally with Godot 4.7.2 and its templates on a minimal project carrying the game's
Android preset: `--export-debug` gives `debuggable=true`, `--export-release` with `package/signed=false` gives no
`debuggable`, needs no keystore in Godot's settings, and keeps the package id, versionCode and versionName from the preset
(fixtures in `tests/fixtures/release/`).

## Release requirements on the exact commit (B42-RELEASE-EXACT-SHA)

`tools/release_requirements.json` is the one definition of what must pass on the commit being packaged; release.yml's
`release` job checks every item (`tools/release_evidence.py needs`) before collecting the packages, and nothing bypasses it:

| Requirement | Job | Passes when |
|---|---|---|
| Tests on exactly this commit | `tests-evidence` | a full Tests (tests.yml) run of this commit: completed and successful; all its latest attempt's jobs success (plan, every shard of the full plan read from this commit's tests.yml, report; none skipped or cancelled); its consolidated validation passes for this commit; every shard's report is TESTED on this commit, every suite passed, every game suite at or above its floor (`tools/ci_check_floors.json`); shard 0 ran the python, game and sim groups and each required Python check (the unittest skip guard `tools/check_unittest_skips.py` when the commit has it); and, when the commit has `tools/check_test_env.py`, shard 0's environment record is "fit" for this commit |
| Simulation gate | `sim-gate` | SIM-GATE-01 as before (skipped only for the owner-approved private `reuse_gate_run`, checked against the diff since that gate's commit) |
| Packages | `package` | six packages from this commit; each Android APK passes the production gate; the Linux packages launch headless with no script error or leak |
| Windows launch | `smoke-windows` | both Windows packages start headless and quit with no script error or leak |

Reuse, not duplication: a passing Tests run of the commit is reused, whoever started it; one in progress is awaited (up to
110 minutes). Only when no full run of the commit exists (none, or only targeted, cancelled, skipped or expired ones) does
`tests-evidence` start one, on the branch being released and only when that branch's head is still the commit
(`tests_when_missing: dispatch`, the default; `fail` blocks instead). A full run of the commit that failed blocks the
release and is never re-run by the workflow; a person decides whether a failure was the runner's and re-runs its failed
jobs. Concurrency (owner, 2026-11-14, B42-Q-RELEASE-TESTS item 2): the run a release starts carries `release_sha` and is in
a concurrency group of its own commit (`tests-release-<sha>`, cancel-in-progress off), so it never cancels, and is never
cancelled by, a push's or anyone's Tests run; a second request for the same commit queues behind the first, and the
release waits for a queued or running run of its commit instead of starting another. Pushes keep superseding older
pushes' runs on the same branch (`tests-<ref>`), as before. A `release_sha` run fails at once if the branch head is no
longer that commit, and the release then blocks with that reason. Tests artifacts are kept 30 days (owner-approved): after
that a commit's evidence has expired and the release starts a new verification run. The record
(`release-evidence` artifact, mml-release-evidence/1) names the run used and every run considered, and its summary goes
into the release notes.
