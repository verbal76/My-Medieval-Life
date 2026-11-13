# INV-02 storage spoilage switched on, and the Android debug export (audit, 2026-11-12/13)

Worker report for the lead. Docs only: nothing in the code, the workflows, the register or the shipped balance was
changed. Times are UTC unless marked EST.

## Part A: MML-INV-02 storage spoilage switched on (long-sims run 43332363247)

**Status: seeds 1 and 2 finished (365 days, exit 0, no FATAL, 0 script errors, currency leak 0, item leaks none); seeds 3 and 4 still running at 02:22 UTC.** Full results follow when they finish.

| | |
|---|---|
| Run | long-sims [43332363247](https://github.com/verbal76/My-Medieval-Life/actions/runs/43332363247) |
| Branch, commit | `wip/b25-inv02-android` `cebae28` (= development line `wip/b25r2-rev2` `b3c9eb5` plus one workflow change: `long-sims.yml` accepts `--spoil-storage` in `sim_args`) |
| Configuration | seeds 1, 2, 3, 4; 365 days; `--spoil-storage` (turns `Decay.storage_on` on for the run; the shipped `decay.storage.enabled` default is untouched) |
| Dispatched | 2026-11-12 23:51:42 UTC (by the previous worker; not re-dispatched) |
| Flag-off comparison | flight-recorder campaigns on `wip/b25r2-rev2` `b3c9eb5`: run 43332151718 (seeds 1, 2) and 43332156022 (seeds 3, 4), two segments a seed |

PART_A_RESULTS

## Part B: why the Android package is a debug export, and what it means

### Finding

`release.yml` exports Android with `--export-debug` and Windows and Linux with `--export-release`. The shipped APK is
therefore built from Godot's **debug** Android template. Checked on the Build 39 APK
(`MyMedievalLife-B39-Android.apk`, workflow artifact 13991241007 `pkg-full-android`, run 43321404909, commit `b3c9eb5`),
by decoding its binary `AndroidManifest.xml` (no aapt on the machine; a small AXML reader):

- `<application ... android:debuggable="true" ...>` and `<profileable android:enabled="true" android:shell="true">`.
- `org.godotengine.library.version = 4.7.2.stable`; `versionName 0.1.39-test`, `versionCode 39`; target and compile SDK
  36, min SDK 24.
- Launcher: `com.godot.game.GodotAppLauncher` (an exported activity alias) for `com.godot.game.GodotApp` (not exported).
- `assets/_cl_` (the command line Godot bakes into the APK) holds only Godot's own defaults:
  `--xr_mode_regular --xr-mode off --fullscreen --background_color #000000`. No game flag, and no `--` separator.
- `lib/arm64-v8a/libgodot_android.so` is 76.2 MB, `lib/armeabi-v7a/libgodot_android.so` 82.5 MB (debug template engine).

### Why it is so

History, not a decision. `--export-debug "Android"` arrived in the first release workflow, commit `c13c54b`
(2026-10-18, "Publish every build as a GitHub Release"), whose message says the APK was "debug-signed": at that time
there was no release keystore, and Godot's `--export-debug` signs with the `export/android/debug_keystore` editor setting,
which the workflow pointed at a generated test keystore. `docs/release/BUILDING.md` still shows the same command for
local builds. When the owner's permanent release identity arrived (Build 21, ANDROID-RELEASE-SIGNING,
`docs/release/ANDROID_SIGNING.md`), signing moved out of Godot (`package/signed=false`, then `zipalign` and `apksigner`
with the four `ANDROID_RELEASE_*` secrets), but the export flag was not revisited; the release keystore is still named to
Godot only as `debug_keystore` "because Godot's export check may ask for one". No entry in `docs/DECISIONS.md`,
`ANDROID_SIGNING.md` or the register chooses a debug export for players. So the signing is the release identity, but the
engine inside the APK is the debug one.

### What it means for players

1. **Debug behaviour differs from the PC builds.** `OS.is_debug_build()` is true in a debug export, so on Android only:
   - ND-24's gate in `game/scripts/main.gd` (line 191) does not hold: the development flags (`--screenshot`, `--warp`,
     `--advance`, `--zoom`, `--panel`, `--pick`, `--field-state`, `--safe`, `--cutout`) are read if they reach the game.
     `--screenshot X` starts `new_game()`, the case ND-24 was written to stop (a default world over the player's slot).
   - `--tree-growth N` (`game/scripts/core/trees.gd` line 38) multiplies tree regrowth.
   - `assert()` runs (7 scripts, e.g. `construction.gd:400`, `property.gd:310`); it is skipped in the PC release builds.
   Windows and Linux use release templates, so the three platforms do not run the same engine configuration.
2. **Can the flags reach an Android player's game?** Not in normal play. The baked `_cl_` file holds none, and
   `OS.get_cmdline_user_args()` needs a `--` before them. From Godot 4.x's Android host code (knowledge of the source, not
   reproduced on a device in this audit): `GodotActivity` also appends a string-array intent extra
   `command_line_params` to the command line when the activity starts, without a debug-build check. The launcher alias
   is exported, so `adb shell am start -n com.hotatticgames.mymedievallife.dev/com.godot.game.GodotAppLauncher --esa
   command_line_params "--,--screenshot,x"` (USB debugging on) or another app installed on the same phone could start
   the game with them. Risk is low (it needs deliberate action on the device), but in a release export the same intent
   would do nothing, because the game ignores the flags when `OS.is_debug_build()` is false.
3. **`android:debuggable="true"`** lets anyone with USB debugging attach a debugger, and `adb shell run-as
   com.hotatticgames.mymedievallife.dev` read and rewrite the app's private files (saves, settings) without root. That
   matters for multiplayer fairness and save integrity on a shared or borrowed phone, though not for a single-player
   private test. Google Play refuses to accept a debuggable APK, so a store build would need the change in any case.
4. **Performance and logging.** The debug template keeps Godot's `DEBUG_ENABLED` code: GDScript debug checks and line
   tracking, extra error checking, more detailed logcat errors and script backtraces, and the remote debugger (idle unless
   started with `--remote-debug`). It is normally slower on CPU-bound GDScript and the library is larger than the release
   one. Not measured in this audit (the release template was not downloaded; disk was ~370 MB); the size and frame-time
   difference should be measured on the first release-export APK rather than assumed. On a mid-range phone, the slowest
   target (CLAUDE.md section 8), the GDScript overhead is the part most likely to show.

### What switching to `--export-release` would need

Small, and no new secret:

- `release.yml`, Android export step: `--export-debug "Android${PRESET_SUFFIX}"` becomes `--export-release
  "Android${PRESET_SUFFIX}"`. The workflow already installs the full `export_templates.tpz`, which carries
  `android_release.apk` as well as the debug one.
- Signing is unchanged: the workflow already sets `package/signed=false`, so Godot signs nothing and `zipalign` plus
  `apksigner` sign with the `ANDROID_RELEASE_*` identity as now. With signing off, Godot's release export should not
  need a release keystore; if the 4.7.2 export check still asks for one, give it the same decoded keystore through
  `export/android/release_keystore`, `release_keystore_user`, `release_keystore_pass` in the generated editor settings,
  or the `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `_USER`, `_PASSWORD` environment variables, never in
  `export_presets.cfg` (which is committed and keeps `keystore/*` empty).
- Same package id, same certificate, rising version code: an installed debug-export build updates in place to a
  release-export one and keeps its saves (Android allows a debuggable app to be replaced by a non-debuggable one with
  the same signature).
- Checks to add in the same change: assert the manifest no longer says `debuggable="true"` (decode it as above, or
  `aapt2 dump xmltree` from the SDK's build-tools), keep the existing `apksigner verify`, and update
  `docs/release/BUILDING.md` and `ANDROID_SIGNING.md`. The demo preset (`Android Demo`) goes through the same step.
- Before the first such build: run the Android-relevant tests once on desktop with a release export, or at least on
  the PC release builds already shipped, which have run release templates all along, so release-only behaviour (asserts
  off, the development flags ignored) is already exercised on two platforms.

### Recommendation

Switch the Android export to `--export-release` for the next build, as an engineering correction that keeps the intent
of ANDROID-RELEASE-SIGNING and ND-24 (players get the release build; development flags are off in shipped builds). It
needs no gameplay decision. Because it changes the release workflow, it is the lead's or owner's change to make, not
this worker's. Keep a debug export only as an explicitly named developer artifact if one is wanted for on-device
debugging, never as the package published to players.

## Owner questions

1. May the Android package be exported with `--export-release` (non-debuggable, release engine template) from the next
   build, with signing unchanged? Recommended: yes.
2. Do you want a separate debug APK kept as a CI artifact for on-device debugging (not attached to releases)?
OWNER_QUESTIONS_A

## Wiki and documentation

No player-facing mechanic changed, so no wiki page was touched. Technical reference: this audit. `docs/release/BUILDING.md`
and `docs/release/ANDROID_SIGNING.md` should be updated with the workflow change if it is approved.
