# MY MEDIEVAL LIFE — MANDATORY THREE-PLATFORM BUILD POLICY

Owner directive, 2026-10-24, verbatim.

Effective immediately, every authorized My Medieval Life build, including development checkpoints, private playtests, release candidates, and final releases, must produce all three platform artifacts:

1. Android: Installable APK.
2. Windows: Playable PC build packaged as a ZIP containing the executable and required files.
3. Linux: Playable Linux build packaged as a ZIP containing the executable and required files, suitable for Linux and Steam Deck testing.

This is a permanent build requirement.
Checkpoint 1 Correction
The previously authorized Checkpoint 1 is now a three-platform private playtest release, not an Android-only APK.
All three artifacts must:

* Come from the same verified source commit.
* Use the same game version and build number.
* Include the same approved gameplay changes.
* Pass applicable platform-specific build checks.
* Include checksums and source-commit identification.
* Be uploaded together to the same private draft release.
* Be clearly identified as a coordinated build set.

Use the established Android signing identity and existing build pipeline. Do not generate temporary replacement signing keys.
Release Integrity
Do not declare a build complete if only one or two platform artifacts succeed.
If a platform fails, report the failure, repair it, and complete the three-platform set.
Do not publish publicly without authorization.
Preserve Build 19 and all existing release artifacts.
Development Continuity
This requirement does not change the approved development order.
Complete Checkpoint 1, produce all three builds, and continue multiplayer development.
Do not require my personal playtesting before continuing development.
From now on, when I say "build," I mean Android, Windows, and Linux together unless I explicitly specify otherwise.
