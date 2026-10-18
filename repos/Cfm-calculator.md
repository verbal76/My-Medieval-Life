# Cfm-calculator

Scanned 2026-10-18T15:42:18Z from a blobless clone (trees and commits; blobs fetched only for images and key documents). Nothing in the repository was changed.

| | |
|---|---|
| Product | Verbal's CFM Calculator |
| Kind | app (HVAC tool) |
| Visibility | not stated (read through the session git proxy; may be private) |
| Engine / language | Capacitor 8 / Android API 36, TypeScript + Vite |
| GitHub default branch | `main` @ `05abc05c53295a361f8a5ffea165584bcd14f872` (moving) |
| Most recent branch | `ccr-ac67996a-npuzs3` |
| Last commit on any branch | 2026-10-06 |
| Status | active (active = a commit within 14 days of 2026-10-18) |
| Links | https://github.com/verbal76/Cfm-calculator |

## Purpose

"Verbal's CFM Calculator (gas-heating CFM per ton and refrigerant subcooling checks)." (`ccr-ac67996a-npuzs3:README.md`)

## Source of truth

CLAUDE.md: "`release/VERSION` is the single source of truth (versionCode == N)"; branch: unresolved.

## Branches

Branch heads move; the SHA is the head at scan time.

| Branch | Head SHA | Last commit | Ahead / behind default | Role | Relation to reference line | Last subject |
|---|---|---|---|---|---|---|
| `ccr-ac67996a-npuzs3` | `b1fe120bdfbf40a7cc318b01c65b32264ecd59fd` | 2026-10-06 | 17 / 0 | most recent branch (reference line; not stated authoritative), agent session branch |  | CI: Actions budget policy - release-only android.yml, cheap ci.yml, opt-in promote/smoke,  |
| `main` | `05abc05c53295a361f8a5ffea165584bcd14f872` | 2026-10-04 | 0 / 0 | GitHub default | contained in `ccr-ac67996a-npuzs3` | Add files via upload |

Pull-request refs on the remote: #1 (refs only; PR state not read).

## Tags and releases

Release details could not be read (the GitHub API refused: repository outside this session's scope). Tags from `git ls-remote --tags`; whether each tag has a GitHub Release is unknown.

| Tag | Commit | Commit date | Release | Commit subject |
|---|---|---|---|---|
| `v7` | `641fc9bce0b85cd54aff3810a51a9bc79e37ffa1` | 2026-10-04 | unknown | Release v7: Verbal-CFM-Calculator-v7.apk (Back fix + studio-card robus |
| `v6` | `2d02a12ff337a454883707829494403c52859c9e` | 2026-10-04 | unknown | qualify-apk: fix pipefail/SIGPIPE false negatives in the new resource  |
| `v4.1.0-test.3` | `2d273539c579f0ab8bcc932a154038dce7e135a8` | 2026-10-03 | unknown | Add refrigerant engine, picker, pressure-based Subcooling, Superheat a |
| `v4.0.0-test.1` | `f18cd5a825fe486845988f20003df804c6dc48db` | 2026-10-03 | unknown | Modernize CFM Calculator: Capacitor 8 / Android API 36 build, preserve |

## Asset manifests and licence records

- `android/app/src/main/AndroidManifest.xml`

## Important artwork

Logos, icons, splash, branding and store-like images, and any image 512 px or larger, across every branch head (16 distinct image path/blob pairs in total). Links pin the branch head SHA where the file was seen.

| Path | Size (px) | Bytes | Blob | Seen on | Link |
|---|---|---|---|---|---|
| `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` | 1536x1024 | 2838266 | `e11f8c576652` | `ccr-ac67996a-npuzs3` +1 | [view](https://github.com/verbal76/Cfm-calculator/blob/b1fe120bdfbf40a7cc318b01c65b32264ecd59fd/Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png) |

## Features and layout

Top level of `ccr-ac67996a-npuzs3`:

`.github/` (4), `.gitignore` (1), `CLAUDE.md` (1), `Gas_CFM_calc.apk` (1), `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` (1), `README.md` (1), `android/` (41), `capacitor.config.ts` (1), `cfm original.zip` (1), `docs/` (6), `eslint.config.js` (1), `index.html` (1), `package-lock.json` (1), `package.json` (1), `release/` (2), `scripts/` (9), `src/` (9), `tests/` (7), `tsconfig.json` (1), `vite.config.ts` (1)

Top level of default `main`: `Gas_CFM_calc.apk` (1), `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` (1), `README.md` (1), `cfm original.zip` (1)

## CI workflows

Path and trigger only; never changed or run.

| Branch:path | Name | Trigger (`on:`) |
|---|---|---|
| `ccr-ac67996a-npuzs3:.github/workflows/android.yml` | Release build | push:     branches: ['**']     paths: ['release/deliver']     tags: ['v[0-9]*'] |
| `ccr-ac67996a-npuzs3:.github/workflows/ci.yml` | CI (cheap checks) | pull_request:     types: [opened, reopened, synchronize, ready_for_review]     paths-ignore: &ignored       - '**.md'       - 'docs/**'       - 'CLAUDE.md'      |
| `ccr-ac67996a-npuzs3:.github/workflows/promote.yml` | Promote verified release | push:     branches: ['**']     paths: ['release/promote.json']   workflow_dispatch:     inputs:       promote_version:         description: 'Public version numb |
| `ccr-ac67996a-npuzs3:.github/workflows/smoke.yml` | Emulator smoke test (opt-in) | push:     branches: ['**']     paths: ['release/smoke']   workflow_dispatch: |

## Sensitive files (paths only; contents not read)

- none matched

## Unknowns and duplicates

Same blob under more than one path on some branch head: 7 blobs.
- `036d09bc5fd5`: `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`, `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml`
- `c5a58d640db0`: `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`, `android/app/src/main/res/mipmap-hdpi/ic_launcher_round.png`
- `5c21dee40a66`: `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`, `android/app/src/main/res/mipmap-mdpi/ic_launcher_round.png`
- `f24a187a8b4c`: `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`, `android/app/src/main/res/mipmap-xhdpi/ic_launcher_round.png`
- `1e4393b53d60`: `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`, `android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png`
- `71629ab4cb03`: `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`, `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png`
- `7f8f011eb73d`: `release/VERSION`, `release/deliver`
- The GitHub default branch `main` holds only 4 files while work lives on `ccr-ac67996a-npuzs3`; anyone cloning the default sees an upload snapshot, not the product.
