# voiceforge

Scanned 2026-10-18T15:42:22Z from a blobless clone (trees and commits; blobs fetched only for images and key documents). Nothing in the repository was changed.

| | |
|---|---|
| Product | Voice Forge |
| Kind | app |
| Visibility | private |
| Engine / language | Expo / React Native, TypeScript (plus trainer/) |
| GitHub default branch | `main` @ `5e0b01d474a30421baf687f9a723d607860ac54a` (moving) |
| Most recent branch | `claude/youthful-brahmagupta-n6sglt` |
| Last commit on any branch | 2026-10-11 |
| Status | active (active = a commit within 14 days of 2026-10-18) |
| Links | https://github.com/verbal76/voiceforge |

## Purpose

"voice cloner for an AI" (`main:README.md`)

## Source of truth

unresolved (CLAUDE.md sets release naming; no branch ledger read).

## Branches

Branch heads move; the SHA is the head at scan time.

| Branch | Head SHA | Last commit | Ahead / behind default | Role | Relation to reference line | Last subject |
|---|---|---|---|---|---|---|
| `claude/follow-dev-doc-KzL3e` | `9ac6e3d984024ea72929e456e6a71912972c7384` | 2026-05-18 | 1 / 1 | agent session branch | NOT contained in `claude/youthful-brahmagupta-n6sglt`; 146 days older than the newest branch: possibly stale or abandoned (unverified by content) | feat: scaffold VoiceForge Phase 1 — foundation (no native deps) |
| `claude/pto-ledger-balance-cap-29vll2` | `87fe0737ac5c6ff1af9eacce654684e8043c81e9` | 2026-09-18 | 14 / 1 | agent session branch | NOT contained in `claude/youthful-brahmagupta-n6sglt`; 23 days older than the newest branch: possibly stale or abandoned (unverified by content) | Add "Start over" on the password screen to erase the ledger and reset the password |
| `claude/youthful-brahmagupta-n6sglt` | `deaffe8bee52cba0a564aa37c5df41735b162c6c` | 2026-10-11 | 168 / 0 | most recent branch (reference line; not stated authoritative), agent session branch |  | docs: self-hosted signed OTA (ADR-004), permanent required-capability rule |
| `claude/youthful-brahmagupta-n6sglt-wip-audio` | `6a389f051dc9219332d5852f9448e2ba0ebccace` | 2026-10-03 | 12 / 1 | agent session branch | contained in `claude/youthful-brahmagupta-n6sglt` | docs(audio): README with API, thresholds, verdict semantics, limitations |
| `claude/youthful-brahmagupta-n6sglt-wip-corpus` | `1d1b8841193874402f95241d59d1355395ef1037` | 2026-10-03 | 21 / 1 | agent session branch | contained in `claude/youthful-brahmagupta-n6sglt` | corpus: lists.txt |
| `claude/youthful-brahmagupta-n6sglt-wip-prompts` | `cd1da781124aaa98f8180e2716af8e12bd377457` | 2026-10-03 | 59 / 1 | agent session branch | contained in `claude/youthful-brahmagupta-n6sglt` | Merge remote-tracking branch 'origin/claude/youthful-brahmagupta-n6sglt' into worktree-age |
| `claude/youthful-brahmagupta-n6sglt-wip-runtime` | `2e42f973eb24af14a81a1eded669cb0270697d29` | 2026-10-03 | 13 / 1 | agent session branch | contained in `claude/youthful-brahmagupta-n6sglt` | docs(integration): compatibility matrix, quick starts, SAPI5, game engines, licensing |
| `claude/youthful-brahmagupta-n6sglt-wip-trainer` | `541ab3d3c1eb3782a22aacceb2ebba2a65475c32` | 2026-10-03 | 14 / 1 | agent session branch | contained in `claude/youthful-brahmagupta-n6sglt` | trainer: review/format pass, ruff clean; fix racy resume test (record init epoch at train  |
| `main` | `5e0b01d474a30421baf687f9a723d607860ac54a` | 2026-10-04 | 0 / 0 | GitHub default | contained in `claude/youthful-brahmagupta-n6sglt` | Add files via upload |

Pull-request refs on the remote: #1, #2, #3 (refs only; PR state not read).

## Tags and releases

Releases read with the GitHub API (this session's scope). Tags are immutable references unless moved; the commit is the peeled tag target.

| Tag | Commit | Commit date | Release | Commit subject |
|---|---|---|---|---|
| `voice-forge-v10` | `fde80f7123510beef316eefa5c1050ee1590c686` | 2026-10-08 | Voice Forge v10, published 2026-10-08 | release: request Voice Forge v10 (steady level guidance, no false end  |
| `voice-forge-v9` | `5fe38c06141625f86daca8000cfd665446b0f510` | 2026-10-06 | Voice Forge v9, published 2026-10-06 | build(android): request Voice Forge v9 (QC fixes from the v8 Pixel tes |
| `voice-forge-v8` | `5b51e0b09bdefe452c68ddd8ffad6ac35019b0be` | 2026-10-06 | Voice Forge v8, published 2026-10-06 | build(android): retry Voice Forge v8 — Maven Central 429 during depend |
| `voice-forge-v7` | `1d36eb5468c7bb330b3c3e2e06877d9d6ba44870` | 2026-10-05 | Voice Forge v7, published 2026-10-06 | build(android): request Voice Forge v7 (on-device AI) + emulator end-t |
| `voice-forge-v6` | `de96d6bb70abcb830c1870ebd120c625744e513b` | 2026-10-04 | Voice Forge v6 (pre-release), published 2026-10-04 | build(android): request Voice Forge v6 (Hot Attic Games studio splash) |
| `android-internal-vc5-1656acf` | `1656acfb7809078a6f120ba48bcd03206b3a573d` | 2026-10-03 | Voice Forge v5 (pre-release), published 2026-10-03 | fix(build): 16 KB check parsed the ELF alignment exponent wrong (vc4 v |
| `android-internal-vc4-3073b9b` | `3073b9b85437f70cec150dd0b14a83a60cb58724` | 2026-10-03 | Voice Forge v4 (pre-release), published 2026-10-03 | feat(release): self-discovering OTA (expo-updates), 'Please wait, appl |
| `android-internal-vc3-d30f35c` | `d30f35c62653e221a47526d996abe74e616a6fa8` | 2026-10-03 | Voice Forge v3 (pre-release), published 2026-10-03 | build(android): always publish the internal prerelease on push-trigger |

## Asset manifests and licence records

- `assets/data/CMUDICT-LICENSE.txt`
- `runtime/csharp/src/VoiceForge.Runtime/Manifest.cs`
- `runtime/node/schemas/manifest.schema.json`
- `runtime/node/src/manifest.ts`
- `runtime/python/src/voiceforge_runtime/manifest.py`
- `runtime/python/src/voiceforge_runtime/schemas/manifest.schema.json`
- `scripts/bench/tts/licences.py`
- `scripts/bench/vc/licences.py`
- `scripts/models/licence_texts.py`
- `spec/export/v1/manifest.schema.json`
- `src/core/export/manifest.ts`

## Important artwork

Logos, icons, splash, branding and store-like images, and any image 512 px or larger, across every branch head (10 distinct image path/blob pairs in total). Links pin the branch head SHA where the file was seen.

| Path | Size (px) | Bytes | Blob | Seen on | Link |
|---|---|---|---|---|---|
| `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` | 1536x1024 | 2838266 | `e11f8c576652` | `claude/youthful-brahmagupta-n6sglt` +1 | [view](https://github.com/verbal76/voiceforge/blob/deaffe8bee52cba0a564aa37c5df41735b162c6c/Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png) |
| `assets/images/adaptive-icon-monochrome.png` | 1024x1024 | 13011 | `5b5de788b78d` | `claude/youthful-brahmagupta-n6sglt` +1 | [view](https://github.com/verbal76/voiceforge/blob/deaffe8bee52cba0a564aa37c5df41735b162c6c/assets/images/adaptive-icon-monochrome.png) |
| `assets/images/adaptive-icon.png` | 1024x1024 | 18555 | `abd4d3234f22` | `claude/youthful-brahmagupta-n6sglt` +1 | [view](https://github.com/verbal76/voiceforge/blob/deaffe8bee52cba0a564aa37c5df41735b162c6c/assets/images/adaptive-icon.png) |
| `assets/images/favicon.png` | 48x48 | 1265 | `4c24a90e2027` | `claude/youthful-brahmagupta-n6sglt` +1 | [view](https://github.com/verbal76/voiceforge/blob/deaffe8bee52cba0a564aa37c5df41735b162c6c/assets/images/favicon.png) |
| `assets/images/icon.png` | 1024x1024 | 133958 | `ffc2c135eab5` | `claude/youthful-brahmagupta-n6sglt` +1 | [view](https://github.com/verbal76/voiceforge/blob/deaffe8bee52cba0a564aa37c5df41735b162c6c/assets/images/icon.png) |
| `assets/images/splash-blank.png` | 512x512 | 1096 | `35fa6a597cd2` | `claude/youthful-brahmagupta-n6sglt` | [view](https://github.com/verbal76/voiceforge/blob/deaffe8bee52cba0a564aa37c5df41735b162c6c/assets/images/splash-blank.png) |
| `assets/images/splash-icon.png` | 512x512 | 11541 | `7b8500344f11` | `claude/youthful-brahmagupta-n6sglt` +1 | [view](https://github.com/verbal76/voiceforge/blob/deaffe8bee52cba0a564aa37c5df41735b162c6c/assets/images/splash-icon.png) |
| `assets/images/adaptive-icon.png` | 1024x1024 | 5336 | `3d8c6e2ec1cb` | `claude/follow-dev-doc-KzL3e` +4 | [view](https://github.com/verbal76/voiceforge/blob/9ac6e3d984024ea72929e456e6a71912972c7384/assets/images/adaptive-icon.png) |
| `assets/images/icon.png` | 1024x1024 | 5337 | `191b88448ed1` | `claude/follow-dev-doc-KzL3e` +4 | [view](https://github.com/verbal76/voiceforge/blob/9ac6e3d984024ea72929e456e6a71912972c7384/assets/images/icon.png) |
| `assets/images/splash.png` | 1284x2778 | 16229 | `702b47a4d812` | `claude/follow-dev-doc-KzL3e` +4 | [view](https://github.com/verbal76/voiceforge/blob/9ac6e3d984024ea72929e456e6a71912972c7384/assets/images/splash.png) |

## Features and layout

Top level of `claude/youthful-brahmagupta-n6sglt`:

`.github/` (21), `.gitignore` (1), `CLAUDE.md` (1), `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` (1), `README.md` (1), `app.config.ts` (1), `assets/` (10), `docs/` (26), `eas.json` (1), `eslint.config.js` (1), `fingerprint.config.js` (1), `index.ts` (1), `jest.config.js` (1), `metro.config.js` (1), `package-lock.json` (1), `package.json` (1), `patches/` (1), `plugins/` (1), `release/` (7), `runtime/` (69), `scripts/` (81), `spec/` (8), `src/` (245), `trainer/` (57), `tsconfig.json` (1), `tsconfig.test.json` (1)

Top level of default `main`: `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` (1), `README.md` (1)

## CI workflows

Path and trigger only; never changed or run.

| Branch:path | Name | Trigger (`on:`) |
|---|---|---|
| `claude/youthful-brahmagupta-n6sglt:.github/workflows/android-apk.yml` | Android APK (internal) | workflow_dispatch:     inputs:       abi:         description: ABIs to build (Pixel 10 Pro XL is arm64-v8a)         required: true         default: arm64-v8a    |
| `claude/youthful-brahmagupta-n6sglt:.github/workflows/android-play.yml` | Android AAB (Google Play) | workflow_dispatch:   push:     branches: ['**']     paths: ['.github/android-play-request'] |
| `claude/youthful-brahmagupta-n6sglt:.github/workflows/android-smoke.yml` | Android smoke (emulator) | workflow_dispatch:     inputs:       tag:         description: Release tag whose APK to test         required: true   push:     branches: ['**']     paths: ['.g |
| `claude/youthful-brahmagupta-n6sglt:.github/workflows/android-test-apk.yml` | Android test APK (emulator) | push:     branches: ['**']     paths: ['.github/android-test-apk-request']   workflow_dispatch:     inputs:       abis:         description: ABIs (comma-separat |
| `claude/youthful-brahmagupta-n6sglt:.github/workflows/ci-sdk.yml` | CI (runtime SDKs and trainer) | pull_request:     types: [opened, synchronize, reopened, ready_for_review]     paths: ['runtime/**', 'trainer/**', '.github/workflows/ci-sdk.yml']   push:     b |
| `claude/youthful-brahmagupta-n6sglt:.github/workflows/ci.yml` | CI | pull_request:     types: [opened, synchronize, reopened, ready_for_review]     paths-ignore:       - '**/*.md'       - 'docs/**'       - 'release/**'       - 's |
| `claude/youthful-brahmagupta-n6sglt:.github/workflows/clone-bench.yml` | Clone TTS benchmark | push:     branches: ['**']     paths: ['.github/clone-bench-request'] |
| `claude/youthful-brahmagupta-n6sglt:.github/workflows/model-qualify.yml` | Model qualification | workflow_dispatch:   push:     branches: ['**']     paths: ['.github/model-qualify-request'] |
| `claude/youthful-brahmagupta-n6sglt:.github/workflows/ota-e2e.yml` | OTA end-to-end (emulator) | workflow_dispatch:   push:     branches: ['**']     paths: ['.github/ota-e2e-request'] |
| `claude/youthful-brahmagupta-n6sglt:.github/workflows/ota.yml` | OTA update | workflow_dispatch:     inputs:       name:         description: 'What changed (or "rollback <update id>: <reason>", or "deploy-only")'         required: true    |
| `claude/youthful-brahmagupta-n6sglt:.github/workflows/release-presentation.yml` | Release presentation | workflow_dispatch:   push:     branches: ['**']     paths: ['.github/release-presentation-request'] |
| `claude/youthful-brahmagupta-n6sglt:.github/workflows/vc-bench.yml` | VC bench | push:     branches: ['**']     paths: ['.github/vc-bench-request'] |

## Sensitive files (paths only; contents not read)

- `src/services/secrets.ts`

## Unknowns and duplicates

Same blob under more than one path on some branch head: 3 blobs.
- `188f057cc45d`: `runtime/node/schemas/consent.schema.json`, `runtime/python/src/voiceforge_runtime/schemas/consent.schema.json`, `spec/export/v1/consent.schema.json`
- `ae9beffd8e0d`: `runtime/node/schemas/lineage.schema.json`, `runtime/python/src/voiceforge_runtime/schemas/lineage.schema.json`, `spec/export/v1/lineage.schema.json`
- `0d30213d2c65`: `runtime/node/schemas/manifest.schema.json`, `runtime/python/src/voiceforge_runtime/schemas/manifest.schema.json`, `spec/export/v1/manifest.schema.json`
- The GitHub default branch `main` holds only 2 files while work lives on `claude/youthful-brahmagupta-n6sglt`; anyone cloning the default sees an upload snapshot, not the product.
