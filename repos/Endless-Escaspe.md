# Endless-Escaspe

Scanned 2026-10-18T15:42:07Z from a blobless clone (trees and commits; blobs fetched only for images and key documents). Nothing in the repository was changed.

| | |
|---|---|
| Product | Endless Escape |
| Kind | game |
| Visibility | not stated (read through the session git proxy; may be private) |
| Engine / language | Expo / React Native, TypeScript |
| GitHub default branch | `main` @ `84f6b740b8ac0777b4588ccd1b1879dbafd6e080` (moving) |
| Most recent branch | `claude/api36-native-qualification` |
| Last commit on any branch | 2026-10-12 |
| Status | active (active = a commit within 14 days of 2026-10-18) |
| Links | https://github.com/verbal76/Endless-Escaspe |

## Purpose

"A stealth escape game for Android phones: slip past guards, dogs, cameras and searchlights across a prison yard." (`claude/api36-native-qualification:README.md`)

## Source of truth

unresolved (`main` holds 5 files; no ledger read).

## Branches

Branch heads move; the SHA is the head at scan time.

| Branch | Head SHA | Last commit | Ahead / behind default | Role | Relation to reference line | Last subject |
|---|---|---|---|---|---|---|
| `Github-APK-Transition-Escap` | `e970c74d6842f7e6d0dab42d7ec70bef99264a68` | 2026-05-11 | 116 / 7 | unknown | NOT contained in `claude/api36-native-qualification`; 154 days older than the newest branch: possibly stale or abandoned (unverified by content) | Add Prune Artifacts workflow |
| `claude/api36-native-qualification` | `4eb47b98a0d323cf4874b430ed233a1da68d6c46` | 2026-10-12 | 225 / 7 | most recent branch (reference line; not stated authoritative), agent session branch |  | Coordinated Android/Windows/Linux build workflow, request-based OTA, branch-protection rul |
| `claude/boss-pickups-scene-rebuild-0YBha` | `481e307743013c4426cf1ed5fb7dd492a3ba68a6` | 2026-04-28 | 39 / 3 | agent session branch | NOT contained in `claude/api36-native-qualification`; 167 days older than the newest branch: possibly stale or abandoned (unverified by content) | Pickups: crowbar + smoke bomb (#22) |
| `claude/endless-escape-game-android-gRlFH` | `0171d652179c0f963b4728e195823ecd1772bbd0` | 2026-05-08 | 111 / 7 | agent session branch | contained in `claude/api36-native-qualification` | Fire APK build #1 (GitHub-hosted): smoke test on Github-APK-Transition-Escap |
| `claude/fix-apk-screen-issue-etmic` | `b595f5d0678b072105caf49668cb1eead3b11432` | 2026-05-11 | 4 / 3 | agent session branch | NOT contained in `claude/api36-native-qualification`; 154 days older than the newest branch: possibly stale or abandoned (unverified by content) | HANDOFF.md: flag the default-branch requirement for workflow triggers |
| `claude/game-review-suggestions-cjxiqh` | `02e13eb2bcee30265a7006afc5c323bccfa02f19` | 2026-10-03 | 198 / 7 | agent session branch | contained in `claude/api36-native-qualification` | Game: cull far chunks, prefetch Endless chunks, smooth motion, idle-pause redraw |
| `claude/hold-ci-hardening` | `5e8b92fbd15a1f96cc107f10b7534a4ed55e5546` | 2026-10-03 | 201 / 7 | agent session branch | NOT contained in `claude/api36-native-qualification`; 9 days older than the newest branch: possibly stale or abandoned (unverified by content) | docs: CI pipeline map, gates, costs, runner decision and first-run checklist |
| `claude/hold-infra-ota-about-splash` | `c734f3101985a1339bcd3ad2c4fd5fd81ccb8c97` | 2026-10-03 | 200 / 7 | agent session branch | contained in `claude/api36-native-qualification` | Hold: saves backup UI, package-ID drift tests, concise About, blocker-resolution docs |
| `claude/hold-native-batch` | `7131cdb689622a75fbe22d0a36fb89f7c79ad547` | 2026-10-03 | 202 / 7 | agent session branch | contained in `claude/api36-native-qualification` | docs: native batch checklist and signing migration plan |
| `claude/hold-scenarios` | `1c962e51118ca65a30909fcba5dab04fc9fdc896` | 2026-10-03 | 200 / 7 | agent session branch | NOT contained in `claude/api36-native-qualification`; 9 days older than the newest branch: possibly stale or abandoned (unverified by content) | scenarios: regression guards for fixed review defects, docs, CI notes |
| `claude/ledger-docs` | `d2c9c4e5e14e381668c6a5eb4699ac2ac5f776c1` | 2026-10-03 | 203 / 7 | agent session branch | NOT contained in `claude/api36-native-qualification`; 9 days older than the newest branch: possibly stale or abandoned (unverified by content) | Docs: record hold-period branches, PRs and merge-order warnings |
| `main` | `84f6b740b8ac0777b4588ccd1b1879dbafd6e080` | 2026-10-04 | 0 / 0 | GitHub default | NOT contained in `claude/api36-native-qualification`; 8 days older than the newest branch: possibly stale or abandoned (unverified by content) | Add files via upload |

Pull-request refs on the remote: #1, #2, #3, #4, #5, #6, #7 (refs only; PR state not read).

## Tags and releases

Release details could not be read (the GitHub API refused: repository outside this session's scope). Tags from `git ls-remote --tags`; whether each tag has a GitHub Release is unknown.

| Tag | Commit | Commit date | Release | Commit subject |
|---|---|---|---|---|
| `build-16` | `c30232d13b12662bd6646df639fd529a06e87174` | 2026-10-04 | unknown | Build Endless Escape v15: smoke-test gate, packaged-content verificati |
| `build-15` | `95dcc77b8af55fbea7182d2a08fe0b8c8f0ed2c9` | 2026-10-03 | unknown | Qualification: retrigger APK build |
| `build-10` | `df65081c2b3b0a490b694f93dabbfec4f4757367` | 2026-05-11 | unknown | Prune Artifacts: add self-push trigger to fire workflow on demand |
| `build-12` | `df65081c2b3b0a490b694f93dabbfec4f4757367` | 2026-05-11 | unknown | Prune Artifacts: add self-push trigger to fire workflow on demand |
| `build-13` | `df65081c2b3b0a490b694f93dabbfec4f4757367` | 2026-05-11 | unknown | Prune Artifacts: add self-push trigger to fire workflow on demand |
| `build-9` | `df65081c2b3b0a490b694f93dabbfec4f4757367` | 2026-05-11 | unknown | Prune Artifacts: add self-push trigger to fire workflow on demand |
| `build-2` | `934391b570f979b6d99b5d72951bb8b0ded199f8` | 2026-04-26 | unknown | Sync npx-removal fix from dev branch |
| `build-4` | `934391b570f979b6d99b5d72951bb8b0ded199f8` | 2026-04-26 | unknown | Sync npx-removal fix from dev branch |
| `build-5` | `934391b570f979b6d99b5d72951bb8b0ded199f8` | 2026-04-26 | unknown | Sync npx-removal fix from dev branch |
| `build-7` | `934391b570f979b6d99b5d72951bb8b0ded199f8` | 2026-04-26 | unknown | Sync npx-removal fix from dev branch |

## Asset manifests and licence records

- `assets/LICENSES.md`
- `scripts/ci/write-provenance.mjs`
- `src/desktop/glyphManifest.ts`
- `tests/licenses.test.ts`

## Important artwork

Logos, icons, splash, branding and store-like images, and any image 512 px or larger, across every branch head (66 distinct image path/blob pairs in total). Links pin the branch head SHA where the file was seen.

| Path | Size (px) | Bytes | Blob | Seen on | Link |
|---|---|---|---|---|---|
| `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` | 1536x1024 | 2838266 | `e11f8c576652` | `claude/api36-native-qualification` +1 | [view](https://github.com/verbal76/Endless-Escaspe/blob/4eb47b98a0d323cf4874b430ed233a1da68d6c46/Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png) |
| `assets/adaptive-icon-background.png` | 1024x1024 | 450605 | `644d0d5afb60` | `claude/api36-native-qualification` +6 | [view](https://github.com/verbal76/Endless-Escaspe/blob/4eb47b98a0d323cf4874b430ed233a1da68d6c46/assets/adaptive-icon-background.png) |
| `assets/adaptive-icon.png` | 1024x1024 | 1361631 | `29f7fca791bf` | `claude/api36-native-qualification` +6 | [view](https://github.com/verbal76/Endless-Escaspe/blob/4eb47b98a0d323cf4874b430ed233a1da68d6c46/assets/adaptive-icon.png) |
| `assets/characters/texture-d.png` | 1024x1024 | 13151 | `809546b9eeeb` | `claude/api36-native-qualification` +8 | [view](https://github.com/verbal76/Endless-Escaspe/blob/4eb47b98a0d323cf4874b430ed233a1da68d6c46/assets/characters/texture-d.png) |
| `assets/characters/texture-g.png` | 1024x1024 | 16069 | `6cb06fdae2cc` | `claude/api36-native-qualification` +8 | [view](https://github.com/verbal76/Endless-Escaspe/blob/4eb47b98a0d323cf4874b430ed233a1da68d6c46/assets/characters/texture-g.png) |
| `assets/characters/texture-j.png` | 1024x1024 | 17576 | `7c74a3c1be7d` | `claude/api36-native-qualification` +8 | [view](https://github.com/verbal76/Endless-Escaspe/blob/4eb47b98a0d323cf4874b430ed233a1da68d6c46/assets/characters/texture-j.png) |
| `assets/favicon.png` | 48x48 | 1466 | `e75f697b1801` | `claude/api36-native-qualification` +9 | [view](https://github.com/verbal76/Endless-Escaspe/blob/4eb47b98a0d323cf4874b430ed233a1da68d6c46/assets/favicon.png) |
| `assets/icon.png` | 1254x1254 | 2336304 | `8e0f3180dcba` | `claude/api36-native-qualification` +8 | [view](https://github.com/verbal76/Endless-Escaspe/blob/4eb47b98a0d323cf4874b430ed233a1da68d6c46/assets/icon.png) |
| `assets/splash-icon.png` | 1024x1024 | 23367 | `a25e8617a88d` | `claude/api36-native-qualification` +6 | [view](https://github.com/verbal76/Endless-Escaspe/blob/4eb47b98a0d323cf4874b430ed233a1da68d6c46/assets/splash-icon.png) |
| `assets/vehicles/colormap.png` | 512x512 | 12371 | `5c4b1857dafd` | `claude/api36-native-qualification` +8 | [view](https://github.com/verbal76/Endless-Escaspe/blob/4eb47b98a0d323cf4874b430ed233a1da68d6c46/assets/vehicles/colormap.png) |
| `assets/adaptive-icon.png` | 1024x1024 | 17547 | `03d6f6b6c672` | `claude/boss-pickups-scene-rebuild-0YBha` | [view](https://github.com/verbal76/Endless-Escaspe/blob/481e307743013c4426cf1ed5fb7dd492a3ba68a6/assets/adaptive-icon.png) |
| `assets/adaptive-icon.png` | 1254x1254 | 2336304 | `8e0f3180dcba` | `Github-APK-Transition-Escap` +1 | [view](https://github.com/verbal76/Endless-Escaspe/blob/e970c74d6842f7e6d0dab42d7ec70bef99264a68/assets/adaptive-icon.png) |
| `assets/icon.png` | 1024x1024 | 22380 | `a0b1526fc7b7` | `claude/boss-pickups-scene-rebuild-0YBha` | [view](https://github.com/verbal76/Endless-Escaspe/blob/481e307743013c4426cf1ed5fb7dd492a3ba68a6/assets/icon.png) |
| `assets/splash-icon.png` | 1024x1024 | 17547 | `03d6f6b6c672` | `Github-APK-Transition-Escap` +2 | [view](https://github.com/verbal76/Endless-Escaspe/blob/e970c74d6842f7e6d0dab42d7ec70bef99264a68/assets/splash-icon.png) |

## Features and layout

Top level of `claude/api36-native-qualification`:

`.github/` (6), `.gitignore` (1), `App.tsx` (1), `CLAUDE.md` (1), `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` (1), `README.md` (1), `app.config.js` (1), `app.json` (1), `assets/` (112), `babel.config.js` (1), `desktop/` (6), `docs/` (23), `eas.json` (1), `index.ts` (1), `package-lock.json` (1), `package.json` (1), `release.json` (1), `scripts/` (21), `src/` (131), `tests/` (62), `tsconfig.json` (1)

Top level of default `main`: `.github/` (3), `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` (1), `README.md` (1)

## CI workflows

Path and trigger only; never changed or run.

| Branch:path | Name | Trigger (`on:`) |
|---|---|---|
| `claude/api36-native-qualification:.github/workflows/android-render-check.yml` | Android render check | workflow_dispatch:   # Called by eas-update.yml (OTA gate) and apk-build.yml (release gate).   # There is deliberately NO push trigger: an emulator run costs 15 |
| `claude/api36-native-qualification:.github/workflows/apk-build.yml` | Coordinated Build (Android, Windows, Linux) | workflow_dispatch:     inputs:       platform:         description: 'Target platform. A GitHub Release needs all; a single platform is a workflow artifact only  |
| `claude/api36-native-qualification:.github/workflows/ci.yml` | CI | pull_request:     types: [opened, synchronize, reopened, ready_for_review]   workflow_call:   workflow_dispatch: |
| `claude/api36-native-qualification:.github/workflows/eas-update.yml` | EAS Update (OTA) | workflow_dispatch:     inputs:       source_sha:         description: 'Exact commit to publish: the full 40-character SHA of the publishing branch head (the run |
| `claude/api36-native-qualification:.github/workflows/ota-rollback.yml` | OTA rollback | workflow_dispatch:     inputs:       action:         description: 'undo-latest (group = the bad, latest group) or republish (group = the good group to restore)' |
| `claude/api36-native-qualification:.github/workflows/production-build.yml` | Production build (EAS, manual only) | workflow_dispatch:     inputs:       confirm:         description: 'Type BUILD PRODUCTION to start an EAS production build'         type: string         require |
| `main:.github/workflows/eas-build.yml` | EAS Build (APK) | workflow_dispatch:     inputs:       profile:         description: 'EAS build profile'         required: true         default: 'preview'         type: choice    |
| `main:.github/workflows/eas-update.yml` | EAS Update (OTA) | workflow_dispatch:   # JS-only pushes ship as OTA. Native/build/config changes are handled   # by eas-build.yml instead (which embeds the new JS in the new APK) |
| `main:.github/workflows/prune-artifacts.yml` | Prune Artifacts | workflow_dispatch:   schedule:     - cron: '0 6 * * *'   workflow_run:     workflows: ['APK Build (GitHub-hosted)']     types: [completed]   # Bumping this file |

## Sensitive files (paths only; contents not read)

- none matched

## Unknowns and duplicates

Same blob under more than one path on some branch head: 2 blobs.
- `8e0f3180dcba`: `assets/adaptive-icon.png`, `assets/icon.png`
- `03d6f6b6c672`: `assets/adaptive-icon.png`, `assets/splash-icon.png`
- The GitHub default branch `main` holds only 5 files while work lives on `claude/api36-native-qualification`; anyone cloning the default sees an upload snapshot, not the product.
