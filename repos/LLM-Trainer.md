# LLM-Trainer

Scanned 2026-10-18T15:42:17Z from a blobless clone (trees and commits; blobs fetched only for images and key documents). Nothing in the repository was changed.

| | |
|---|---|
| Product | LLM Trainer |
| Kind | tool |
| Visibility | not stated (read through the session git proxy; may be private) |
| Engine / language | Python factory core + Kotlin/Gradle Android app |
| GitHub default branch | `main` @ `f05d9bbc6900ace22828bfa7630229bb64ff16f5` (moving) |
| Most recent branch | `ccr-a278e57a-o761ch` |
| Last commit on any branch | 2026-10-06 |
| Status | active (active = a commit within 14 days of 2026-10-18) |
| Links | https://github.com/verbal76/LLM-Trainer |

## Purpose

"A reusable **specialist-model factory**: ingest authorized domain material, build and evaluate specialist LLMs" (`ccr-a278e57a-o761ch:README.md`)

## Source of truth

README: "Authoritative requirements: `CLAUDE.md` and `docs/START_PROMPT.md`". Authoritative branch: unresolved.

## Branches

Branch heads move; the SHA is the head at scan time.

| Branch | Head SHA | Last commit | Ahead / behind default | Role | Relation to reference line | Last subject |
|---|---|---|---|---|---|---|
| `catalog-data` | `c003f913e84ff3cbf26aa47233f54f1a6009f389` | 2026-10-05 | 142 / 0 | unknown | NOT contained in `ccr-a278e57a-o761ch` | catalog-data: refresh registry/artifacts from Hugging Face (d263f09) |
| `catalog/refresh` | `d263f091c55a7d2af9804e748a15c328d857c463` | 2026-10-05 | 141 / 0 | unknown | contained in `ccr-a278e57a-o761ch` | catalog: quantized files link to their full-precision twin across repos of the same base m |
| `ccr-a278e57a-o761ch` | `deda455a5f622339281b476cbb2e519ab213d913` | 2026-10-06 | 159 / 0 | most recent branch (reference line; not stated authoritative), agent session branch |  | engine.yml: engine/** branch push is the gate (drop the path filter, which suppressed re-p |
| `ci/android` | `deda455a5f622339281b476cbb2e519ab213d913` | 2026-10-06 | 159 / 0 | unknown | contained in `ccr-a278e57a-o761ch` | engine.yml: engine/** branch push is the gate (drop the path filter, which suppressed re-p |
| `engine/grid-1` | `05f874b12341fe26941ba44f4e32f005aa07048a` | 2026-10-06 | 154 / 0 | unknown | contained in `ccr-a278e57a-o761ch` | Actions budget policy: record it in CLAUDE.md, trim triggers (no duplicate push+PR runs, e |
| `engine/grid-2` | `6f187367b9870e605a59ea2cf2726db30b5239cd` | 2026-10-06 | 158 / 0 | unknown | contained in `ccr-a278e57a-o761ch` | Merge fix/engine-suite-honest: noise-floor/control-derived gates, build/suite split so rea |
| `engine/grid-3` | `deda455a5f622339281b476cbb2e519ab213d913` | 2026-10-06 | 159 / 0 | unknown | contained in `ccr-a278e57a-o761ch` | engine.yml: engine/** branch push is the gate (drop the path filter, which suppressed re-p |
| `main` | `f05d9bbc6900ace22828bfa7630229bb64ff16f5` | 2026-10-04 | 0 / 0 | GitHub default | contained in `ccr-a278e57a-o761ch` | Initial commit |
| `ota/v2` | `28de300c0a9afc175c118c2ed952b784b7ddddea` | 2026-10-05 | 87 / 0 | OTA channel/line | contained in `ccr-a278e57a-o761ch` | CI: Kotlin-produced job package must import cleanly through the Python importer (cross-lan |
| `release/v1` | `2e146d4a6d5c89d2a9bdaf04c7448dd919b8f086` | 2026-10-05 | 18 / 0 | release-related | contained in `ccr-a278e57a-o761ch` | Release workflow: trigger on release/v<N> branch push (tag pushes are blocked by the git p |

Pull-request refs on the remote: #1 (refs only; PR state not read).

## Tags and releases

Release details could not be read (the GitHub API refused: repository outside this session's scope). Tags from `git ls-remote --tags`; whether each tag has a GitHub Release is unknown.

| Tag | Commit | Commit date | Release | Commit subject |
|---|---|---|---|---|
| `ota-stable` | `28de300c0a9afc175c118c2ed952b784b7ddddea` | 2026-10-05 | unknown | CI: Kotlin-produced job package must import cleanly through the Python |
| `v1` | `2e146d4a6d5c89d2a9bdaf04c7448dd919b8f086` | 2026-10-05 | unknown | Release workflow: trigger on release/v<N> branch push (tag pushes are  |

## Asset manifests and licence records

- `app/src/main/AndroidManifest.xml`
- `docs/architecture/adr/0006-dataset-handling-and-provenance.md`
- `docs/architecture/adr/0012-base-model-license-gate.md`
- `factory/llmtrainer/data/registry/pipeline-validation-stub.LICENSE.txt`
- `factory/llmtrainer/jobs/license_override.py`
- `factory/llmtrainer/licenses.py`
- `factory/llmtrainer/provenance.py`
- `factory/tests/test_license_verification.py`
- `factory/tests/test_licenses.py`
- `factory/tests/test_provenance.py`
- `runtime/src/main/AndroidManifest.xml`
- `schemas/v1/base_model_license_entry.schema.json`
- `schemas/v1/dataset_manifest.schema.json`
- `schemas/v1/model_manifest.schema.json`
- `schemas/v1/source_manifest.schema.json`
- `studio-core/src/main/kotlin/com/hotatticgames/llmtrainer/studio/core/Licenses.kt`
- `studio-core/src/test/kotlin/com/hotatticgames/llmtrainer/studio/core/LicenseTest.kt`

## Important artwork

Logos, icons, splash, branding and store-like images, and any image 512 px or larger, across every branch head (2 distinct image path/blob pairs in total). Links pin the branch head SHA where the file was seen.

| Path | Size (px) | Bytes | Blob | Seen on | Link |
|---|---|---|---|---|---|
| `branding/hot-attic-games/studio-logo.png` | 1536x1024 | 2838266 | `e11f8c576652` | `ccr-a278e57a-o761ch` +8 | [view](https://github.com/verbal76/LLM-Trainer/blob/deda455a5f622339281b476cbb2e519ab213d913/branding/hot-attic-games/studio-logo.png) |

## Features and layout

Top level of `ccr-a278e57a-o761ch`:

`.gitattributes` (1), `.github/` (5), `.gitignore` (1), `CLAUDE.md` (1), `README.md` (1), `app/` (20), `branding/` (1), `build.gradle.kts` (1), `bundle/` (11), `docs/` (36), `engine-adapter/` (5), `extract/` (16), `factory/` (99), `gradle.properties` (1), `gradle/` (2), `gradlew` (1), `gradlew.bat` (1), `host-api/` (4), `native/` (22), `ota-core/` (18), `ota/` (3), `qualify/` (13), `registry/` (43), `runtime/` (16), `schemas/` (10), `scripts/` (4), `settings.gradle.kts` (1), `studio-api/` (13), `studio-core/` (52), `tools/` (13)

Top level of default `main`: `README.md` (1)

## CI workflows

Path and trigger only; never changed or run.

| Branch:path | Name | Trigger (`on:`) |
|---|---|---|
| `ccr-a278e57a-o761ch:.github/workflows/catalog-refresh.yml` | Catalog refresh | push:     branches: ["catalog/refresh"]   workflow_dispatch: |
| `ccr-a278e57a-o761ch:.github/workflows/ci.yml` | CI | pull_request:     paths-ignore: ["docs/**", "**/*.md", ".gitignore", "LICENSE*", "registry/artifacts/index.json"]   push:     branches: ["ci/**"]   workflow_dis |
| `ccr-a278e57a-o761ch:.github/workflows/engine.yml` | engine | push:     branches: ['engine/**']   # the branch name is the deliberate gate; no path filter (it hides re-pushes of already-pushed commits)   workflow_dispatch: |
| `ccr-a278e57a-o761ch:.github/workflows/publish-ota.yml` | Publish OTA bundle | workflow_dispatch:     inputs:       bundle_version:         description: "Bundle version (integer, strictly greater than any published)"         required: fals |
| `ccr-a278e57a-o761ch:.github/workflows/release-apk.yml` | Release APK | workflow_dispatch:     inputs:       version:         description: "Native version N (integer): versionCode=versionName=N, tag vN, LLM-Trainer-vN.apk"         r |

## Sensitive files (paths only; contents not read)

- none matched

## Unknowns and duplicates

Same blob under more than one path on some branch head: 0 blobs.
- The GitHub default branch `main` holds only 1 files while work lives on `ccr-a278e57a-o761ch`; anyone cloning the default sees an upload snapshot, not the product.
