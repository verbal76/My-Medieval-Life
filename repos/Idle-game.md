# Idle-game

Scanned 2026-10-18T15:42:09Z from a blobless clone (trees and commits; blobs fetched only for images and key documents). Nothing in the repository was changed.

| | |
|---|---|
| Product | Where's the Bottom? (formerly "Boarder") |
| Kind | game |
| Visibility | not stated (read through the session git proxy; may be private) |
| Engine / language | Babylon.js + TypeScript inside an Expo WebView shell; EAS Update OTA |
| GitHub default branch | `main` @ `968e195d5dac1d6a6a339c89cafac1ddadd06d5d` (moving) |
| Most recent branch | `claude/hold-candidate-next` |
| Last commit on any branch | 2026-10-12 |
| Status | active (active = a commit within 14 days of 2026-10-18) |
| Links | https://github.com/verbal76/Idle-game |

## Purpose

"A low-poly snowboarding game for Android phones." The `main` README still calls it "Boarder". (`claude/hold-candidate-next:README.md`)

## Source of truth

authoritative.json (claude/hold-candidate-next): "authoritativeLine": "claude/repo-gameplay-review-loq9rq", baselineSha `41c8cfbbe8d747e6fce072c9e2164d0d2e7ade77` ("Source of the live OTA #83").

## Branches

Branch heads move; the SHA is the head at scan time.

| Branch | Head SHA | Last commit | Ahead / behind default | Role | Relation to reference line | Last subject |
|---|---|---|---|---|---|---|
| `Github-APK-Transition` | `5890e139077e599c1901579d4e254ae5f98b8bf9` | 2026-05-08 | 1 / 4 | unknown | contained in `claude/repo-gameplay-review-loq9rq` | Switch eas-build.yml to local-build mode (no EAS credits) |
| `Github-APK-Transition-snow` | `bf96e840e5747c5742efa0b22360e62bbd45b903` | 2026-10-03 | 22 / 4 | unknown | NOT contained in `claude/repo-gameplay-review-loq9rq`; 9 days older than the newest branch: possibly stale or abandoned (unverified by content) | Disable OTA and APK publishing on the stale snow branch |
| `claude/add-steering-obstacles-WCPxr` | `11c29660e144b5d1c2f9d7b88c5cb340c0f4bd66` | 2026-05-07 | 0 / 47 | agent session branch | contained in `claude/repo-gameplay-review-loq9rq` | Ramp orientation flip + backFaceCulling fix |
| `claude/android-snowboarding-game-UHUPI` | `dac4a1b9db519d7876f48e1e26cc39ca44d030de` | 2026-10-12 | 1 / 45 | agent session branch | NOT contained in `claude/repo-gameplay-review-loq9rq` | Disable OTA and APK publishing on this stale branch: a push here used to run an EAS cloud  |
| `claude/compile-teaching-document-zZQy6` | `2d64524e17fb174105f35753888168d3ca212bbb` | 2026-05-11 | 1 / 4 | agent session branch | NOT contained in `claude/repo-gameplay-review-loq9rq`; 154 days older than the newest branch: possibly stale or abandoned (unverified by content) | Add prune-artifacts workflow: keep only 3 most recent |
| `claude/fix-ota-updates-rBtFA` | `7e12a93dd48f1122df988b2c0fbc913bf882d3bf` | 2026-05-08 | 1 / 5 | agent session branch | NOT contained in `claude/repo-gameplay-review-loq9rq`; 157 days older than the newest branch: possibly stale or abandoned (unverified by content) | Hotfix: re-encode icon PNG via pngjs to dodge Sharp/libvips choke |
| `claude/hold-api36-migration` | `db672e2d1aa48bb72b45ecc5595ce73c31a26d6d` | 2026-10-03 | 93 / 3 | agent session branch | NOT contained in `claude/repo-gameplay-review-loq9rq`; 9 days older than the newest branch: possibly stale or abandoned (unverified by content) | Migration docs: stages, evidence, runtime lineages, save-protection notes, Play readiness  |
| `claude/hold-candidate-next` | `471436a724909699a5010c7dfef9e52759de52af` | 2026-10-12 | 134 / 3 | agent session branch | NOT contained in `claude/repo-gameplay-review-loq9rq` | Packaged smoke: kill the whole process group so no Xvfb/Electron child leaks [skip ci] |
| `claude/hold-release-naming` | `6832d3bdd073841b721243b5af68c95bea797a2c` | 2026-10-12 | 97 / 3 | release-related, agent session branch | NOT contained in `claude/repo-gameplay-review-loq9rq` | Build NN naming on the PR #66 line: About 'Release' row shows the label, release-info test |
| `claude/hold-save-export` | `a59ab981e4cff7d0d0066ed789c8d7ea34fc7083` | 2026-10-03 | 84 / 3 | agent session branch | NOT contained in `claude/repo-gameplay-review-loq9rq`; 9 days older than the newest branch: possibly stale or abandoned (unverified by content) | Save protection (HOLD): Back up & restore saves, with validated import |
| `claude/identify-issues-2Hub5` | `9148bf58c25b3b4567fa293527e9ed18279ccd90` | 2026-05-06 | 0 / 81 | agent session branch | contained in `claude/repo-gameplay-review-loq9rq` | Clamp downhill X to ±295 — stop the rider falling under the wall mesh |
| `claude/infra-hold-about-splash-applying` | `4c5f9e4c2ae1e8a11469a2e222a7f24ff657df6c` | 2026-10-12 | 88 / 3 | agent session branch | NOT contained in `claude/repo-gameplay-review-loq9rq` | Port to the PR #65 base: Build NN naming (release.json style switch), coordinated build wo |
| `claude/repo-gameplay-review-loq9rq` | `41c8cfbbe8d747e6fce072c9e2164d0d2e7ade77` | 2026-10-03 | 82 / 3 | authoritative line (per repo records), agent session branch |  | Narrower steering strip (OTA #83): about 30% less width on phones |
| `main` | `968e195d5dac1d6a6a339c89cafac1ddadd06d5d` | 2026-10-06 | 0 / 0 | GitHub default | NOT contained in `claude/repo-gameplay-review-loq9rq`; 6 days older than the newest branch: possibly stale or abandoned (unverified by content) | Prune artifacts: weekly instead of daily and after every build; keep the newest 6, never d |

Pull-request refs on the remote: #1, #2, #3, #4, #5, #6, #7, #8, #9, #10, #11, #12, #13, #14, #15, #16, #17, #18, #19, #20, #21, #22, #23, #24, #25, #26, #27, #28, #29, #30, #31, #32, #33, #34, #35, #36, #37, #38, #39, #40, #41, #42, #43, #44, #45, #46, #47, #48, #49, #50, #51, #52, #53, #54, #55, #56, #57, #58, #59, #60, #61, #62, #63, #64, #65, #66 (refs only; PR state not read).

## Tags and releases

Release details could not be read (the GitHub API refused: repository outside this session's scope). Tags from `git ls-remote --tags`; whether each tag has a GitHub Release is unknown.

| Tag | Commit | Commit date | Release | Commit subject |
|---|---|---|---|---|
| `snow-build-106` | `8827159abfad2cbdd283e524608205f268e8ea0c` | 2026-05-08 | unknown | Hotfix: re-encode icon PNG via pngjs to dodge Sharp/libvips choke (#62 |
| `snow-build-107` | `8827159abfad2cbdd283e524608205f268e8ea0c` | 2026-05-08 | unknown | Hotfix: re-encode icon PNG via pngjs to dodge Sharp/libvips choke (#62 |

## Asset manifests and licence records

- `THIRD_PARTY_NOTICES.md`
- `docs/THIRD_PARTY_ASSETS.md`
- `scripts/make-release-manifest.mjs`

## Important artwork

Logos, icons, splash, branding and store-like images, and any image 512 px or larger, across every branch head (56 distinct image path/blob pairs in total). Links pin the branch head SHA where the file was seen.

| Path | Size (px) | Bytes | Blob | Seen on | Link |
|---|---|---|---|---|---|
| `src/assets/character-texture.png` | 1024x1024 | 13151 | `809546b9eeeb` | `claude/repo-gameplay-review-loq9rq` +12 | [view](https://github.com/verbal76/Idle-game/blob/41c8cfbbe8d747e6fce072c9e2164d0d2e7ade77/src/assets/character-texture.png) |
| `src/assets/menu-bg.png` | 1254x1254 | 1886246 | `1158d27dfc7d` | `claude/repo-gameplay-review-loq9rq` +10 | [view](https://github.com/verbal76/Idle-game/blob/41c8cfbbe8d747e6fce072c9e2164d0d2e7ade77/src/assets/menu-bg.png) |
| `src/assets/rider-texture.png` | 1024x1024 | 24596 | `c2df03017f56` | `claude/repo-gameplay-review-loq9rq` +5 | [view](https://github.com/verbal76/Idle-game/blob/41c8cfbbe8d747e6fce072c9e2164d0d2e7ade77/src/assets/rider-texture.png) |
| `src/assets/settings-gear.png` | 1262x1246 | 1080516 | `3b6f43a4a11b` | `claude/repo-gameplay-review-loq9rq` +5 | [view](https://github.com/verbal76/Idle-game/blob/41c8cfbbe8d747e6fce072c9e2164d0d2e7ade77/src/assets/settings-gear.png) |
| `src/assets/splash-bg.png` | 941x1672 | 1833571 | `ae05568c2907` | `claude/repo-gameplay-review-loq9rq` +5 | [view](https://github.com/verbal76/Idle-game/blob/41c8cfbbe8d747e6fce072c9e2164d0d2e7ade77/src/assets/splash-bg.png) |
| `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` | 1536x1024 | 2838266 | `e11f8c576652` | `claude/hold-candidate-next` +3 | [view](https://github.com/verbal76/Idle-game/blob/471436a724909699a5010c7dfef9e52759de52af/Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png) |
| `src/assets/glyphs/xbox/sprite.png` | 632x1808 | 64455 | `ff79e3004c59` | `claude/hold-candidate-next` | [view](https://github.com/verbal76/Idle-game/blob/471436a724909699a5010c7dfef9e52759de52af/src/assets/glyphs/xbox/sprite.png) |
| `src/assets/menu-bg.png` | 1394x1128 | 1370357 | `757bfada4d8b` | `claude/add-steering-obstacles-WCPxr` +1 | [view](https://github.com/verbal76/Idle-game/blob/11c29660e144b5d1c2f9d7b88c5cb340c0f4bd66/src/assets/menu-bg.png) |
| `src/assets/studio-logo.webp` | 1536x1024 | 458302 | `3203be21b25b` | `claude/hold-candidate-next` +2 | [view](https://github.com/verbal76/Idle-game/blob/471436a724909699a5010c7dfef9e52759de52af/src/assets/studio-logo.webp) |

Other art/source files (svg, psd, pdf, ...): 1; first few: `public/icon.svg`

## Features and layout

Top level of `claude/repo-gameplay-review-loq9rq`:

`.builds/` (1), `.gitattributes` (1), `.github/` (5), `.gitignore` (1), `App.tsx` (1), `MOBILE_GAME_DEV_RULES.md` (1), `README.md` (1), `app.config.js` (1), `app.json` (1), `babel.config.js` (1), `docs/` (11), `eas.json` (1), `eslint.config.mjs` (1), `index.html` (1), `index.js` (1), `metro.config.js` (1), `package-lock.json` (1), `package.json` (1), `public/` (1), `scripts/` (7), `src/` (150), `tsconfig.json` (1), `vite.config.ts` (1), `vitest.config.ts` (1)

Top level of default `main`: `.builds/` (1), `.gitattributes` (1), `.github/` (4), `.gitignore` (1), `App.tsx` (1), `Assets/` (28), `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` (1), `README.md` (1), `app.json` (1), `babel.config.js` (1), `eas.json` (1), `index.html` (1), `index.js` (1), `metro.config.js` (1), `package.json` (1), `public/` (1), `scripts/` (3), `src/` (59), `tsconfig.json` (1), `vite.config.ts` (1)

## CI workflows

Path and trigger only; never changed or run.

| Branch:path | Name | Trigger (`on:`) |
|---|---|---|
| `claude/hold-candidate-next:.github/workflows/ci.yml` | CI | pull_request:     branches:       - main     paths-ignore:       - 'docs/**'       - '**/*.md'       - 'CLAUDE.md'       - '.claude/**' |
| `claude/hold-candidate-next:.github/workflows/eas-build.yml` | APK Build (GitHub-hosted) | workflow_dispatch:     inputs:       platform:         description: 'Platform(s) to build'         required: true         default: android         type: choice  |
| `claude/hold-candidate-next:.github/workflows/eas-update.yml` | EAS Update (OTA) | workflow_dispatch:     inputs:       source_sha:         description: 'Approved source commit (full 40-character SHA)'         required: true         type: stri |
| `claude/hold-candidate-next:.github/workflows/prune-artifacts.yml` | Prune Artifacts | workflow_dispatch:   schedule:     - cron: '17 6 * * 1'   # weekly (Mondays); it used to run daily and after every build |
| `claude/hold-candidate-next:.github/workflows/release-android.yml` | Release Android (signed AAB + APK, manual) | workflow_dispatch:     inputs:       source_sha:         description: 'Approved source commit (full 40-character SHA)'         required: true         type: stri |
| `main:.github/workflows/ci.yml` | CI | pull_request:     branches:       - main |
| `main:.github/workflows/eas-build.yml` | APK Build (GitHub-hosted) | workflow_dispatch: |
| `main:.github/workflows/eas-update.yml` | EAS Update (OTA) | workflow_dispatch: |
| `main:.github/workflows/prune-artifacts.yml` | Prune Artifacts | workflow_dispatch:   schedule:     - cron: '17 6 * * 1'   # weekly (Mondays); it used to run daily and after every build |

## Sensitive files (paths only; contents not read)

- none matched

## Unknowns and duplicates

Same blob under more than one path on some branch head: 0 blobs.
