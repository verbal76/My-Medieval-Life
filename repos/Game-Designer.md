# Game-Designer

Scanned 2026-10-18T15:41:29Z from a blobless clone (trees and commits; blobs fetched only for images and key documents). Nothing in the repository was changed.

| | |
|---|---|
| Product | Game Designer |
| Kind | tool (Android app) |
| Visibility | public |
| Engine / language | Kotlin / Gradle (Android) |
| GitHub default branch | `main` @ `b28ff434aaa0c3a6c499014ca58920e3614c74d2` (moving) |
| Most recent branch | `ccr-6330e20f-dm7zhm` |
| Last commit on any branch | 2026-10-17 |
| Status | active (active = a commit within 14 days of 2026-10-18) |
| Links | https://github.com/verbal76/Game-Designer |

## Purpose

"This is an app that takes all of your aggregated input and builds a claude.md file and a Master Claude prompt to start game development with a working build." (`main:README.md`)

## Source of truth

CLAUDE.md: "This file is the authoritative product specification for `verbal76/Game-Designer`." HANDOFF.md names branch `ccr-6330e20f-dm7zhm` (PR #1, draft) as the working branch; which branch is the product line is not stated outright, so: unresolved.

> HANDOFF.md (ccr-6330e20f-dm7zhm) records a PRIVATE DRAFT release `gd-signing-keys` holding signing material. Recorded by name only; not read.

## Branches

Branch heads move; the SHA is the head at scan time.

| Branch | Head SHA | Last commit | Ahead / behind default | Role | Relation to reference line | Last subject |
|---|---|---|---|---|---|---|
| `ccr-6330e20f-dm7zhm` | `788d4ec4d729503843ad82a0728a56f771c5aba7` | 2026-10-17 | 119 / 12 | most recent branch (reference line; not stated authoritative), agent session branch |  | UI test: check label visibility by visible line end instead of hasVisualOverflow |
| `main` | `b28ff434aaa0c3a6c499014ca58920e3614c74d2` | 2026-10-07 | 0 / 0 | GitHub default | NOT contained in `ccr-6330e20f-dm7zhm`; 9 days older than the newest branch: possibly stale or abandoned (unverified by content) | docs: index additional game design lenses |

Pull-request refs on the remote: #1 (refs only; PR state not read).

## Tags and releases

Release details could not be read (the GitHub API refused: repository outside this session's scope). Tags from `git ls-remote --tags`; whether each tag has a GitHub Release is unknown.

| Tag | Commit | Commit date | Release | Commit subject |
|---|---|---|---|---|
| `v5` | `a4bed68b74bb4ddf78878279e55cafd05813aa83` | 2026-10-16 | unknown | Request native release v5 (complete application layer v5.0, sequence 1 |
| `v4` | `fa437b3f86607c158c64b05dd3757f8c7bdd9082` | 2026-10-06 | unknown | Add one-shot v4 release workflow (internal physical-test APK; update l |
| `v3` | `e2c10879ba113d1c8ca059ef5c72a642eebdce68` | 2026-10-05 | unknown | Add one-shot v3 release workflow (internal physical-test APK; 16 KB an |
| `model-catalog` | `dbe1d118b6f6ca70ab13118dd97037d4bc370993` | 2026-10-05 | unknown | Model catalog discovery: verified size/sha256/license from Hugging Fac |
| `ota-dev` | `5789a5bd8a15e175afa26dbe6abba243925b37c6` | 2026-10-05 | unknown | Monotonic CI version code; fix APK minSdk verification check |
| `v2` | `5789a5bd8a15e175afa26dbe6abba243925b37c6` | 2026-10-05 | unknown | Monotonic CI version code; fix APK minSdk verification check |
| `v1` | `2b53d80a1e8a5f08eaa3a7c77cd09b30b37c55ba` | 2026-10-04 | unknown | Update HANDOFF with CI-verified status |

## Asset manifests and licence records

- `app/src/main/AndroidManifest.xml`
- `applayer/src/main/AndroidManifest.xml`
- `otabundle/src/main/AndroidManifest.xml`
- `shellapi/src/main/AndroidManifest.xml`

## Important artwork

Logos, icons, splash, branding and store-like images, and any image 512 px or larger, across every branch head (3 distinct image path/blob pairs in total). Links pin the branch head SHA where the file was seen.

| Path | Size (px) | Bytes | Blob | Seen on | Link |
|---|---|---|---|---|---|
| `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` | 1536x1024 | 2838266 | `e11f8c576652` | `ccr-6330e20f-dm7zhm` +1 | [view](https://github.com/verbal76/Game-Designer/blob/788d4ec4d729503843ad82a0728a56f771c5aba7/Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png) |
| `app/src/main/res/drawable-nodpi/hot_attic_logo.webp` | 1280x853 | 158706 | `1a0df5687f13` | `ccr-6330e20f-dm7zhm` | [view](https://github.com/verbal76/Game-Designer/blob/788d4ec4d729503843ad82a0728a56f771c5aba7/app/src/main/res/drawable-nodpi/hot_attic_logo.webp) |
| `app/src/main/res/drawable-nodpi/splash_icon_raster.png` | 1152x1152 | 533118 | `26f5bfef7d8c` | `ccr-6330e20f-dm7zhm` | [view](https://github.com/verbal76/Game-Designer/blob/788d4ec4d729503843ad82a0728a56f771c5aba7/app/src/main/res/drawable-nodpi/splash_icon_raster.png) |

## Features and layout

Top level of `ccr-6330e20f-dm7zhm`:

`.github/` (5), `.gitignore` (1), `CLAUDE.md` (1), `HANDOFF.md` (1), `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` (1), `README.md` (1), `app/` (16), `applayer/` (31), `build.gradle.kts` (1), `core/` (148), `docs/` (46), `gradle.properties` (1), `gradle/` (3), `gradlew` (1), `gradlew.bat` (1), `ota/` (1), `otabundle/` (2), `otakit/` (9), `settings.gradle.kts` (1), `shellapi/` (5), `tools/` (13)

Top level of default `main`: `CLAUDE.md` (1), `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` (1), `README.md` (1), `docs/` (10), `games_march2025_cleaned-selected-columns.csv` (1)

## CI workflows

Path and trigger only; never changed or run.

| Branch:path | Name | Trigger (`on:`) |
|---|---|---|
| `ccr-6330e20f-dm7zhm:.github/workflows/android.yml` | Android CI | pull_request:     types: [opened, synchronize, reopened, ready_for_review]     paths-ignore: ["**.md", "docs/**", "tools/models/**", "ota/publish-request.json", |
| `ccr-6330e20f-dm7zhm:.github/workflows/model-catalog.yml` | Model catalog discovery | push:     paths: ["tools/models/candidates.json", "tools/models/discover.py"]   workflow_dispatch: |
| `ccr-6330e20f-dm7zhm:.github/workflows/ota-publish.yml` | Publish OTA bundle | push:     paths: ["ota/publish-request.json"]   workflow_dispatch:     inputs:       channel: { description: "dev or stable", required: true, default: "dev" }   |
| `ccr-6330e20f-dm7zhm:.github/workflows/release-v4.yml` | Publish v4 release | push:     paths: [".github/workflows/release-v4.yml"]   workflow_dispatch: |
| `ccr-6330e20f-dm7zhm:.github/workflows/release-v5.yml` | Publish v5 release | push:     paths: [".github/workflows/release-v5.yml"]   workflow_dispatch: |

## Sensitive files (paths only; contents not read)

- none matched

## Unknowns and duplicates

Same blob under more than one path on some branch head: 1 blobs.
- `cc947c567995`: `applayer/src/main/AndroidManifest.xml`, `shellapi/src/main/AndroidManifest.xml`
- The GitHub default branch `main` holds only 14 files while work lives on `ccr-6330e20f-dm7zhm`; anyone cloning the default sees an upload snapshot, not the product.
