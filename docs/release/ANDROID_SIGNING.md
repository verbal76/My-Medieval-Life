# Android signing

**Status (2026-10-24): permanent release identity, from Build 21** (owner directive
`docs/directives/2026-10-24_permanent_android_signing_integration.md`). Never paste a keystore, a password or the base64
text into a chat, an issue, a commit or a file in this repository; they live only in GitHub's secret store and the
owner's signing manager.

## The identity

| | |
|---|---|
| Keystore | `mymedievallife-release.jks`, PKCS12 (kept by the owner) |
| Alias | `mymedievallife_release` |
| Valid | 2026-10-24 to 2053-10-23 |
| Certificate SHA-256 | in the owner's signing manager; every build prints it (below) for comparison |
| Package id | `com.hotatticgames.mymedievallife.dev` (`game/export_presets.cfg`, unchanged since 2026-10-18; the signing manager's `com.hotatticgames.mygame` is a placeholder). Changing it needs the owner's approval. |

## The four repository secrets (never renamed)

| Secret | Holds |
|---|---|
| `ANDROID_RELEASE_KEYSTORE_BASE64` | the keystore file as base64 text |
| `ANDROID_RELEASE_KEYSTORE_PASSWORD` | the keystore password |
| `ANDROID_RELEASE_KEY_ALIAS` | the key alias |
| `ANDROID_RELEASE_KEY_PASSWORD` | the key password |

Agents cannot create or read these secrets; they only reference them by name.

## What `release.yml` does

1. Checks all four secrets are set and that the keystore decodes. A missing secret stops the build with an error naming
   the missing secret, never its value.
2. Exports the APK **unsigned** (the build sets `package/signed=false`), aligns it with `zipalign` (16 KB pages) and signs
   it with `apksigner`, passing the keystore password and the key password separately (they are never assumed equal).
   A wrong password, alias or keystore stops the build; the signer's log stays on the runner and is not printed.
3. Verifies the APK (`apksigner verify --print-certs`) and records the certificate's SHA-256 fingerprint in the job log,
   in the release notes and in `MyMedievalLife-build<n>-android-signature.txt` (with the package id and version code
   from `aapt dump badging`). Compare it with the signing manager's fingerprint.
4. Deletes the decoded keystore and the Godot settings file before the release step.

There is **no fallback**: the old `allow_temporary_key` input and its throwaway key are gone. Windows and Linux are not
signed and are unaffected.

Each build stamps its build number into the versions: Android `version/code` = the build number (Build 21 has code 21,
above Build 20's 20; Android refuses a lower code), `version/name` = `0.1.<n>-test`, Windows file and product version
`0.1.<n>.0`. The preset in the repository keeps its placeholder values.

## Moving to the permanent key (one reinstall)

Builds up to 20 were signed with throwaway keys, so Build 21 cannot update them. To keep a save:

1. In the installed build: Settings > Saves > Export, to a folder outside the app (for example Downloads).
2. Check the exported file is there (a file manager), before uninstalling.
3. Uninstall the old build (this deletes its private data, the save included).
4. Install Build 21 (allow installs from unknown sources).
5. Settings > Saves > Import the exported file, then load it and check the character and world.

From Build 21 on, builds signed with this key install over each other and keep the save. That is reported as verified
only after one does so on a phone.

## History

Builds 1–8 used a key generated fresh on every run (audit finding P1-1). The three `ANDROID_TEST_*` secrets planned in
2026-10-18 were never created, so Builds 9–20 also used throwaway keys (Build 20 by the owner's one-time exception).
