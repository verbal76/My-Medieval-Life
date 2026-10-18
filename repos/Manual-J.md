# Manual-J

Scanned 2026-10-18T15:42:19Z from a blobless clone (trees and commits; blobs fetched only for images and key documents). Nothing in the repository was changed.

| | |
|---|---|
| Product | Manual J |
| Kind | app (HVAC tool) |
| Visibility | not stated (read through the session git proxy; may be private) |
| Engine / language | Capacitor / TypeScript + Vite |
| GitHub default branch | `main` @ `2df7d7596637fdb7194fe1da5e9bea93aaa7873d` (moving) |
| Most recent branch | `ccr-5e589233-wbh6h3` |
| Last commit on any branch | 2026-10-06 |
| Status | active (active = a commit within 14 days of 2026-10-18) |
| Links | https://github.com/verbal76/Manual-J |

## Purpose

"Field-first residential heating/cooling load **survey and calculation** tool (phone/tablet, offline). **Not ACCA-approved; not an official Manual J result.**" (`ccr-5e589233-wbh6h3:README.md`)

## Source of truth

unresolved. CLAUDE.md says "do not publish OTAs or make the repo public"; its visibility was not given to this scan and could not be checked.

## Branches

Branch heads move; the SHA is the head at scan time.

| Branch | Head SHA | Last commit | Ahead / behind default | Role | Relation to reference line | Last subject |
|---|---|---|---|---|---|---|
| `ccr-5e589233-wbh6h3` | `14aa30deb5163cbe0d15ebcaa7ee7c160c1769d0` | 2026-10-06 | 20 / 1 | most recent branch (reference line; not stated authoritative), agent session branch |  | Actions budget policy: dev APK build manual-only, concurrency groups, standing rule in CLA |
| `main` | `2df7d7596637fdb7194fe1da5e9bea93aaa7873d` | 2026-10-04 | 0 / 0 | GitHub default | NOT contained in `ccr-5e589233-wbh6h3` | Add files via upload |
| `qualify/b7` | `f6e7c23571e0b6642925e6b5f6d7d66d02be6af6` | 2026-10-03 | 9 / 1 | release-related | NOT contained in `ccr-5e589233-wbh6h3` | qualify: point at Build 8 artifact (run 37137820018) |
| `release/v5` | `6923244abb1a5fb00985088ae5de6fb994ef83e6` | 2026-10-04 | 17 / 1 | release-related | NOT contained in `ccr-5e589233-wbh6h3` | Merge branch 'ccr-5e589233-wbh6h3' into release/v5 |
| `release/v6` | `1ddb4052e529f9ad0b04b63e43af558dd9d8beae` | 2026-10-04 | 19 / 1 | release-related | contained in `ccr-5e589233-wbh6h3` | Review fixes: engine UNKNOWN/kind validation, persistence normalizer+reconcile, report res |

Pull-request refs on the remote: #1 (refs only; PR state not read).

## Tags and releases

Release details could not be read (the GitHub API refused: repository outside this session's scope). Tags from `git ls-remote --tags`; whether each tag has a GitHub Release is unknown.

No tags.

## Asset manifests and licence records

- `android/app/src/main/AndroidManifest.xml`
- `scripts/make-manifest.ts`
- `src/engine/provenance.ts`
- `src/ota/manifest.ts`

## Important artwork

Logos, icons, splash, branding and store-like images, and any image 512 px or larger, across every branch head (48 distinct image path/blob pairs in total). Links pin the branch head SHA where the file was seen.

| Path | Size (px) | Bytes | Blob | Seen on | Link |
|---|---|---|---|---|---|
| `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` | 1536x1024 | 2838266 | `e11f8c576652` | `ccr-5e589233-wbh6h3` +2 | [view](https://github.com/verbal76/Manual-J/blob/14aa30deb5163cbe0d15ebcaa7ee7c160c1769d0/Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png) |
| `android/app/src/main/res/drawable-land-hdpi/splash.png` | 800x480 | 7705 | `e31573b4fc93` | `ccr-5e589233-wbh6h3` +3 | [view](https://github.com/verbal76/Manual-J/blob/14aa30deb5163cbe0d15ebcaa7ee7c160c1769d0/android/app/src/main/res/drawable-land-hdpi/splash.png) |
| `android/app/src/main/res/drawable-land-mdpi/splash.png` | 480x320 | 4040 | `f7a64923ea1a` | `ccr-5e589233-wbh6h3` +3 | [view](https://github.com/verbal76/Manual-J/blob/14aa30deb5163cbe0d15ebcaa7ee7c160c1769d0/android/app/src/main/res/drawable-land-mdpi/splash.png) |
| `android/app/src/main/res/drawable-land-xhdpi/splash.png` | 1280x720 | 9251 | `807725501bdd` | `ccr-5e589233-wbh6h3` +3 | [view](https://github.com/verbal76/Manual-J/blob/14aa30deb5163cbe0d15ebcaa7ee7c160c1769d0/android/app/src/main/res/drawable-land-xhdpi/splash.png) |
| `android/app/src/main/res/drawable-land-xxhdpi/splash.png` | 1600x960 | 13984 | `14c6c8fe39fc` | `ccr-5e589233-wbh6h3` +3 | [view](https://github.com/verbal76/Manual-J/blob/14aa30deb5163cbe0d15ebcaa7ee7c160c1769d0/android/app/src/main/res/drawable-land-xxhdpi/splash.png) |
| `android/app/src/main/res/drawable-land-xxxhdpi/splash.png` | 1920x1280 | 17683 | `244ca2506dbe` | `ccr-5e589233-wbh6h3` +3 | [view](https://github.com/verbal76/Manual-J/blob/14aa30deb5163cbe0d15ebcaa7ee7c160c1769d0/android/app/src/main/res/drawable-land-xxxhdpi/splash.png) |
| `android/app/src/main/res/drawable-port-hdpi/splash.png` | 480x800 | 7934 | `74faaa583c82` | `ccr-5e589233-wbh6h3` +3 | [view](https://github.com/verbal76/Manual-J/blob/14aa30deb5163cbe0d15ebcaa7ee7c160c1769d0/android/app/src/main/res/drawable-port-hdpi/splash.png) |
| `android/app/src/main/res/drawable-port-mdpi/splash.png` | 320x480 | 4096 | `e944f4ad4e1c` | `ccr-5e589233-wbh6h3` +3 | [view](https://github.com/verbal76/Manual-J/blob/14aa30deb5163cbe0d15ebcaa7ee7c160c1769d0/android/app/src/main/res/drawable-port-mdpi/splash.png) |
| `android/app/src/main/res/drawable-port-xhdpi/splash.png` | 720x1280 | 9875 | `564a82ff954a` | `ccr-5e589233-wbh6h3` +3 | [view](https://github.com/verbal76/Manual-J/blob/14aa30deb5163cbe0d15ebcaa7ee7c160c1769d0/android/app/src/main/res/drawable-port-xhdpi/splash.png) |
| `android/app/src/main/res/drawable-port-xxhdpi/splash.png` | 960x1600 | 13346 | `bfabe6871a17` | `ccr-5e589233-wbh6h3` +3 | [view](https://github.com/verbal76/Manual-J/blob/14aa30deb5163cbe0d15ebcaa7ee7c160c1769d0/android/app/src/main/res/drawable-port-xxhdpi/splash.png) |
| `android/app/src/main/res/drawable-port-xxxhdpi/splash.png` | 1280x1920 | 17489 | `6929071268eb` | `ccr-5e589233-wbh6h3` +3 | [view](https://github.com/verbal76/Manual-J/blob/14aa30deb5163cbe0d15ebcaa7ee7c160c1769d0/android/app/src/main/res/drawable-port-xxxhdpi/splash.png) |
| `android/app/src/main/res/drawable/splash.png` | 480x320 | 4040 | `f7a64923ea1a` | `ccr-5e589233-wbh6h3` +3 | [view](https://github.com/verbal76/Manual-J/blob/14aa30deb5163cbe0d15ebcaa7ee7c160c1769d0/android/app/src/main/res/drawable/splash.png) |
| `src/assets/hag-splash.webp` | 1536x1024 | 1687454 | `ee58a13a4622` | `ccr-5e589233-wbh6h3` +1 | [view](https://github.com/verbal76/Manual-J/blob/14aa30deb5163cbe0d15ebcaa7ee7c160c1769d0/src/assets/hag-splash.webp) |

## Features and layout

Top level of `ccr-5e589233-wbh6h3`:

`.github/` (4), `.gitignore` (1), `CLAUDE.md` (1), `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` (1), `README.md` (1), `android/` (57), `capacitor.config.json` (1), `docs/` (12), `index.html` (1), `package-lock.json` (1), `package.json` (1), `release/` (1), `scripts/` (7), `src/` (26), `tests/` (14), `tsconfig.json` (1), `vite.config.ts` (1)

Top level of default `main`: `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` (1), `README.md` (1), `docs/` (2)

## CI workflows

Path and trigger only; never changed or run.

| Branch:path | Name | Trigger (`on:`) |
|---|---|---|
| `ccr-5e589233-wbh6h3:.github/workflows/android-release.yml` | Android release (signed AAB) | workflow_dispatch: |
| `ccr-5e589233-wbh6h3:.github/workflows/android.yml` | Android debug build | workflow_dispatch: |
| `ccr-5e589233-wbh6h3:.github/workflows/deliver.yml` | Deliver build (GitHub Release) | push:     branches: ['release/v*'] |
| `ccr-5e589233-wbh6h3:.github/workflows/ota-publish.yml` | OTA publish | workflow_dispatch:     inputs:       channel: { description: 'OTA channel (must match the channel baked into installed apps)', default: internal, required: true |

## Sensitive files (paths only; contents not read)

- `android/app/debug.keystore`

## Unknowns and duplicates

Same blob under more than one path on some branch head: 3 blobs.
- `f7a64923ea1a`: `android/app/src/main/res/drawable-land-mdpi/splash.png`, `android/app/src/main/res/drawable/splash.png`
- `6751c8f26402`: `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`, `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml`
- `036d09bc5fd5`: `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`, `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml`
- The GitHub default branch `main` holds only 4 files while work lives on `ccr-5e589233-wbh6h3`; anyone cloning the default sees an upload snapshot, not the product.
