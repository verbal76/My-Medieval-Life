Owner directive, 2026-10-24, verbatim.

MY MEDIEVAL LIFE — PERMANENT ANDROID SIGNING INTEGRATION
OWNER DIRECTIVE
I have completed the Android signing setup using Hot Attic Games Build & Signing Manager 1.0.0.
The permanent signing identity has been generated, backed up, and its four GitHub repository secrets have been configured.
Your task is to integrate this existing signing identity into My Medieval Life's Android build workflow, beginning with Build 21.
Do not generate another signing key, replace the existing identity, or use a temporary signing key.
This is a configuration and verification task, not a redesign of the release system.
1. Existing signing identity
The Build & Signing Manager reports:

* Identity: My Medieval Life release key
* Keystore filename: `mymedievallife-release.jks`
* Keystore format: PKCS12
* Key alias: `mymedievallife_release`
* Certificate validity: October 24, 2026 through October 23, 2053
* Certificate SHA-256 fingerprint: Available in the signing manager
* Keystore backup: Verified by the signing manager

The signing manager has detected Java, keytool, and apksigner.
Do not print, log, expose, or commit the keystore contents, passwords, or private key.
2. GitHub repository secrets
The following four secrets already exist:

* `ANDROID_RELEASE_KEYSTORE_BASE64`
* `ANDROID_RELEASE_KEYSTORE_PASSWORD`
* `ANDROID_RELEASE_KEY_ALIAS`
* `ANDROID_RELEASE_KEY_PASSWORD`

The existing workflow previously expected `ANDROID_TEST_*` secrets.
Update the Android release workflow to reference the existing `ANDROID_RELEASE_*` names.
Do not rename the GitHub secrets.
Do not require me to enter the values again.
Do not introduce fallback signing with a newly generated or disposable key.
If a required secret is missing or signing fails, stop the Android build and report the error without revealing credentials.
3. Verify the Android package identifier
The Build & Signing Manager currently shows the placeholder:
`com.hotatticgames.mygame`
This is not an approved package identifier for My Medieval Life.
Inspect the actual Godot project, Android export presets, and previous APK metadata.
Determine the exact Android package identifier currently used by the game.
Preserve the existing identifier unless an explicit migration is necessary and approved.
Report the correct identifier so I can update the Build & Signing Manager profile.
Do not silently change the package identifier.
4. Signing password compatibility
The signing identity uses a PKCS12 keystore.
The manager indicates that its keystore and key passwords are configured for this format.
Use the supplied secrets according to the actual Godot export and Android signing requirements.
Do not assume the two passwords are identical solely because the keystore is PKCS12.
Verify compatibility through the signing process.
If the export system requires matching passwords and the credentials are incompatible, report the problem rather than changing or regenerating the signing identity.
5. Verify the certificate
After producing the signed Android APK:

1. Inspect the APK signature using the available Android signing tools.
2. Verify that the APK is correctly signed.
3. Extract the signing certificate's SHA-256 fingerprint.
4. Compare it against the fingerprint recorded in Hot Attic Games Build & Signing Manager.
5. Record the verified fingerprint in the release evidence.

Do not expose the private key or credentials.
Preserve the certificate identity for future releases.
6. Build numbering and update compatibility
The Build & Signing Manager currently displays version `1.0.0` and build number `1`.
These are profile values, not authorization to reset My Medieval Life's existing release numbering.
Build 21 must retain its proper build number and use an Android version code greater than the previous release.
Future builds must continue increasing their Android version codes.
Preserve the same Android package identifier and signing certificate for subsequent updates.
7. Build 20 exception and Build 21 transition
Build 20 was explicitly authorized to use disposable Android signing.
Do not reopen or delay Build 20 for this change.
Build 21 will be the first intended release using the permanent signing identity.
Because previous APKs were signed with different keys, Build 21 may require a one-time uninstall and reinstall.
Ensure the release instructions tell the owner to:

1. Export the existing save.
2. Verify that the backup is safely stored outside the Android application.
3. Uninstall the previous APK.
4. Install Build 21.
5. Import the save.
6. Verify that the save loads correctly.

Do not claim that Build 21 can update an earlier disposable-key installation directly.
8. Preserve existing release architecture
Continue producing:

* Android APK
* Windows playable ZIP
* Linux playable ZIP

All three must originate from the same verified source commit and build number.
Prepare the authorized private draft release.
Do not publish publicly or trigger automatic OTA distribution without explicit authorization.
Android signing changes must not modify Windows or Linux signing behavior.
Do not introduce unrelated platform packaging requirements.
9. Preserve SIM-GATE-01
The permanent simulation and flight-recorder quality gate remains a separate requirement for Build 21 onward.
This signing task must not interfere with its development.
Do not introduce Excel generation or spreadsheet libraries into the Android APK.
The automated simulation analysis runs in CI.
Live gameplay Excel exports are supported only on Windows and Linux.
10. Timing and branch coordination
The existing development agent may still be working on the release branch.
Avoid conflicting edits.
Prepare the workflow correction on an appropriate isolated branch if necessary.
Integrate it before Build 21 packaging.
Do not unnecessarily interrupt active development, multiplayer work, or Build 20 verification.
11. Required verification report
When the integration is complete, report:

* Exact workflow files modified.
* Commit containing the signing integration.
* Confirmed Android package identifier.
* Confirmed Android version code.
* Signing secret names used.
* APK signature verification result.
* Whether the APK certificate matches the permanent signing identity.
* Confirmation that disposable-key fallback is disabled.
* Confirmation that Windows and Linux packaging remains unaffected.
* Confirmation that the release remains private.

Do not report signing as verified until an actual APK has been signed and inspected.
FINAL OWNER REQUIREMENT
Beginning with Build 21, every My Medieval Life Android release must use the existing permanent signing identity supplied through the four `ANDROID_RELEASE_*` GitHub secrets.
Never silently regenerate or replace the key.
Never fall back to disposable signing.
Never change the Android package identifier without explicit owner approval.
Preserve the current three-platform private release workflow, simulation requirements, and development priorities.
Complete the integration as part of Build 21 preparation without introducing unrelated work.
