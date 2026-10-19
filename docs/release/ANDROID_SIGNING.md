# Android signing

**Status (2026-10-19): not configured.** The three test-key secrets below did not exist when Build 13 was made
(release runs 13 and 15 stopped at signing), so every test build so far used a throwaway key and every update needs an
uninstall that deletes the save. Stable signing is reported as working only after a build signed with the secrets
installs over another on a phone and keeps the save (the check at the end). Never paste a keystore, a password or the
base64 text into a chat, an issue, a commit or a file in this repository; they go only into GitHub's secret store.

## The problem (audit finding P1-1)

Builds 1–8 were signed with a debug key that `release.yml` generated fresh on every run. Android
only lets a new APK update an installed app when both are signed with the same key, so each build
had to be uninstalled first, and uninstalling deletes the app's data, including the save
(`user://save1.json`, which on Android is in the app's private `files` folder).

## The fix: one private test key, kept as repository secrets

`release.yml` now signs Android test builds with the owner's own **test key**, read from three
repository secrets. Builds signed with it install over each other and keep the save. The key never
enters the repository, the logs (GitHub masks secret values) or the release files: the job decodes
it into the runner's temporary folder with owner-only permissions and deletes it, and the Godot
settings file that names it, before the release step.

Godot uses one password for both the keystore and the key, so make them the same.

If the secrets are missing, the build stops with an error, unless the run's `allow_temporary_key`
box is ticked. Then it signs with a throwaway key as before, and the release notes say the APK cannot
update an earlier install.

Each build also stamps its build number into the versions (the run number, or the run's `build_number` input when a failed run has used a number up, digits only): Android `version/code` = the build number
(Android refuses to update to a lower code), `version/name` = `0.1.<n>-test`, Windows file and
product version `0.1.<n>.0`. `game/export_presets.cfg` itself is not changed in the repository.

Checked locally (2026-10-18): two Android exports with the same custom key carried the same signing
certificate (`apksigner verify --print-certs`), and the export output never printed the password.
Not verified: installing one over the other on a phone (no device here).

## Owner action: create the test key (once)

On your own computer, with a JDK installed (`keytool` comes with it). Keep the files off the
repository.

1. Make the key; choose a strong password and enter it for both prompts:
   ```sh
   keytool -genkeypair -v -keystore mml-test.keystore -alias mmltest \
     -keyalg RSA -keysize 4096 -validity 10000 -dname "CN=Hot Attic Games test signing"
   ```
2. Turn it into text:
   - Linux: `base64 -w0 mml-test.keystore > mml-test.keystore.b64`
   - macOS: `base64 -i mml-test.keystore -o mml-test.keystore.b64`
   - Windows PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes("mml-test.keystore")) | Set-Content mml-test.keystore.b64`
3. On GitHub: the repository > **Settings** > **Secrets and variables** > **Actions** > **New
   repository secret**, three times:

   | Name | Value |
   |---|---|
   | `ANDROID_TEST_KEYSTORE_B64` | the whole contents of `mml-test.keystore.b64` |
   | `ANDROID_TEST_KEYSTORE_PASSWORD` | the password |
   | `ANDROID_TEST_KEY_ALIAS` | `mmltest` |

4. Keep `mml-test.keystore` and its password in your password manager or another safe place. If the
   key is lost, testers must uninstall once more.
5. Delete `mml-test.keystore.b64` from the computer once the secret is saved.

Agents cannot create or read these secrets; they only reference them by name.

## Moving testers to the stable key (one unavoidable reinstall)

The installed Builds 1–8 carry throwaway keys, so the first stable-key build still needs one
uninstall. To keep a save across it (debug builds can be read with `adb`; unverified on a device):

```sh
# before uninstalling the old build: copy the save off the phone
adb exec-out run-as com.hotatticgames.mymedievallife.dev cat files/save1.json > save1.json
adb uninstall com.hotatticgames.mymedievallife.dev
adb install MyMedievalLife-buildN-android.apk
# open the game once, close it, then put the save back
adb push save1.json /data/local/tmp/save1.json
adb shell run-as com.hotatticgames.mymedievallife.dev cp /data/local/tmp/save1.json files/save1.json
```

Saves older than save version 14 are refused (owner decision: the fixed village of generator v6 and the aging
rules made older saves disposable; `SaveStore.MIN_VERSION`), so a save from Build 13 or later carries over this way;
older ones do not.

## Keeping the key (it is the app's identity)

- The keystore file and its password are the only way to sign updates that install over earlier test builds. Keep two
  copies in separate safe places (a password manager and an offline copy), never in the repository or a shared drive.
- Do not change the alias, the password or the keystore once testers have a stable-key build: GitHub secrets can be
  updated, but a different key is a different signing identity.
- **If the key is lost or replaced:** Android refuses to update the installed app with an APK signed by another key
  ("App not installed" or a signature conflict). Every tester must uninstall, which deletes the save unless it is
  copied off first (above), and then install the new build. There is no way to recover a lost key.
- **If the key leaks:** anyone holding it could sign an APK that installs over the testers' copy. Make a new key, update
  the secrets, and treat the next build as a reinstall for everyone.
- The test key never signs a store release (below).

## Checking that an update keeps the save (once the secrets exist)

1. Run `release.yml` with the secrets present (leave `allow_temporary_key` unticked); the job fails rather than fall
   back to a throwaway key.
2. On a phone: install that build, start a game, save, close.
3. Install the next stable-key build over it, without uninstalling. Android must update it in place.
4. Open the game: Continue must offer the same save (same character, day and coins).
5. Optional, with a computer: `apksigner verify --print-certs` on both APKs shows the same certificate digest.
6. Record the result (date, builds, phone model) in the requirements register under B13-15; only then is stable
   signing reported as working.

## Production signing (later; not built yet)

The test key is for private test builds only. A store release needs:
- a separate **upload key**, never the test key, with Google Play App Signing holding the app key;
- the release package name (`com.hotatticgames.mymedievallife`, without `.dev`), which makes it a
  different app from the test builds: they install side by side, and saves do not move between them;
- an AAB export (`gradle_build/use_gradle_build=true`, `export_format` AAB) and the target API level
  Google Play currently requires;
- its own secrets (`ANDROID_RELEASE_KEYSTORE_B64`, `ANDROID_RELEASE_KEYSTORE_PASSWORD`,
  `ANDROID_RELEASE_KEY_ALIAS`) and its own workflow run, approved by the owner.
