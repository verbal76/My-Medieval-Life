# Zombie-squisher

Scanned 2026-10-18T15:42:15Z from a blobless clone (trees and commits; blobs fetched only for images and key documents). Nothing in the repository was changed.

| | |
|---|---|
| Product | Zombie Squisher / Zombie Crusher (name is an open owner decision) |
| Kind | game |
| Visibility | not stated (read through the session git proxy; may be private) |
| Engine / language | Expo SDK 54 / React Native 0.81, three.js (react-three-fiber) |
| GitHub default branch | `main` @ `2f8dac01d9e43786919912e1c088532635f3d428` (moving) |
| Most recent branch | `ccr-27903f19-fy49jb` |
| Last commit on any branch | 2026-10-12 |
| Status | active (active = a commit within 14 days of 2026-10-18) |
| Links | https://github.com/verbal76/Zombie-squisher |

## Purpose

"Top-down arcade-y driving game. Run swarms of zombies over with your bumper" (`ccr-27903f19-fy49jb:README.md`)

## Source of truth

docs/BRANCH_LEDGER.md (ccr-27903f19-fy49jb) names the working branch `ccr-27903f19-fy49jb` (PR #1) as the authoritative line; `main` "is the GitHub default branch but is **not** a product line". The README on that branch instead calls `Github-build-pipeline-zombie-crusher` the "Primary working branch": conflicting records.

## Branches

Branch heads move; the SHA is the head at scan time.

| Branch | Head SHA | Last commit | Ahead / behind default | Role | Relation to reference line | Last subject |
|---|---|---|---|---|---|---|
| `Github-build-pipeline-zombie-crusher` | `7004f7d46b260dc2cf739006353987df85395854` | 2026-05-13 | 158 / 4 | unknown | contained in `ccr-27903f19-fy49jb` | Add guns on/off toggle, side-hit damage, per-hit slowdown |
| `archive/scratch-rewrite-97a5729` | `97a57298d594d5aef52dc8ccb31d8f0b2aad376c` | 2026-10-04 | 3 / 0 | backup / checkpoint | contained in `ccr-27903f19-fy49jb` | Document architecture, handoff state and known issues |
| `ccr-27903f19-fy49jb` | `b1f89f410bff21c171741cd517caad441c6ca43d` | 2026-10-12 | 199 / 0 | authoritative line (per repo records), agent session branch |  | Save mirror extracted into a tested module; fix: a damaged live mirror file could overwrit |
| `checkpoint/pre-resurrection-7004f7d` | `7004f7d46b260dc2cf739006353987df85395854` | 2026-05-13 | 158 / 4 | backup / checkpoint | contained in `ccr-27903f19-fy49jb` | Add guns on/off toggle, side-hit damage, per-hit slowdown |
| `claude/fix-bounding-box-controls-7LQLQ` | `4f454c3d157ef826bb2cf9b67f348ae3f0f36543` | 2026-05-13 | 107 / 4 | agent session branch | NOT contained in `ccr-27903f19-fy49jb`; 152 days older than the newest branch: possibly stale or abandoned (unverified by content) | Bicycle-model steering: kill ice-sprite slide, add wheelbase-based turning arc |
| `claude/fix-build-artifacts-visibility-rwXqU` | `c74ae564b2254b0e2ea27d75bff249f6f8575a56` | 2026-05-09 | 32 / 4 | agent session branch | NOT contained in `ccr-27903f19-fy49jb`; 155 days older than the newest branch: possibly stale or abandoned (unverified by content) | Add expo-file-system explicit dep — required by @react-three/fiber/native |
| `claude/github-game-builds-AAswD` | `dba8096b15ae2d002b98af40e774d1b90faf7c75` | 2026-05-09 | 3 / 4 | agent session branch | NOT contained in `ccr-27903f19-fy49jb`; 156 days older than the newest branch: possibly stale or abandoned (unverified by content) | Add agentic docs folder with project rules and modes [skip ci] |
| `main` | `2f8dac01d9e43786919912e1c088532635f3d428` | 2026-10-04 | 0 / 0 | GitHub default | contained in `ccr-27903f19-fy49jb` | Add files via upload |

Pull-request refs on the remote: #1 (refs only; PR state not read).

## Tags and releases

Release details could not be read (the GitHub API refused: repository outside this session's scope). Tags from `git ls-remote --tags`; whether each tag has a GitHub Release is unknown.

| Tag | Commit | Commit date | Release | Commit subject |
|---|---|---|---|---|
| `apk-build-58` | `1707a6a8b5e0c2a37eeda8c276b6f9f21b72b591` | 2026-05-11 | unknown | Add prune-artifacts workflow to main (default branch) |
| `apk-build-59` | `1707a6a8b5e0c2a37eeda8c276b6f9f21b72b591` | 2026-05-11 | unknown | Add prune-artifacts workflow to main (default branch) |
| `apk-build-60` | `1707a6a8b5e0c2a37eeda8c276b6f9f21b72b591` | 2026-05-11 | unknown | Add prune-artifacts workflow to main (default branch) |
| `apk-build-61` | `1707a6a8b5e0c2a37eeda8c276b6f9f21b72b591` | 2026-05-11 | unknown | Add prune-artifacts workflow to main (default branch) |
| `apk-build-62` | `1707a6a8b5e0c2a37eeda8c276b6f9f21b72b591` | 2026-05-11 | unknown | Add prune-artifacts workflow to main (default branch) |
| `apk-build-63` | `1707a6a8b5e0c2a37eeda8c276b6f9f21b72b591` | 2026-05-11 | unknown | Add prune-artifacts workflow to main (default branch) |
| `apk-build-64` | `1707a6a8b5e0c2a37eeda8c276b6f9f21b72b591` | 2026-05-11 | unknown | Add prune-artifacts workflow to main (default branch) |
| `apk-build-65` | `1707a6a8b5e0c2a37eeda8c276b6f9f21b72b591` | 2026-05-11 | unknown | Add prune-artifacts workflow to main (default branch) |
| `apk-build-66` | `1707a6a8b5e0c2a37eeda8c276b6f9f21b72b591` | 2026-05-11 | unknown | Add prune-artifacts workflow to main (default branch) |
| `apk-build-68` | `1707a6a8b5e0c2a37eeda8c276b6f9f21b72b591` | 2026-05-11 | unknown | Add prune-artifacts workflow to main (default branch) |
| `apk-build-70` | `1707a6a8b5e0c2a37eeda8c276b6f9f21b72b591` | 2026-05-11 | unknown | Add prune-artifacts workflow to main (default branch) |
| `apk-build-71` | `1707a6a8b5e0c2a37eeda8c276b6f9f21b72b591` | 2026-05-11 | unknown | Add prune-artifacts workflow to main (default branch) |
| `apk-build-72` | `1707a6a8b5e0c2a37eeda8c276b6f9f21b72b591` | 2026-05-11 | unknown | Add prune-artifacts workflow to main (default branch) |
| `apk-build-74` | `1707a6a8b5e0c2a37eeda8c276b6f9f21b72b591` | 2026-05-11 | unknown | Add prune-artifacts workflow to main (default branch) |
| `apk-build-75` | `1707a6a8b5e0c2a37eeda8c276b6f9f21b72b591` | 2026-05-11 | unknown | Add prune-artifacts workflow to main (default branch) |
| `apk-build-76` | `1707a6a8b5e0c2a37eeda8c276b6f9f21b72b591` | 2026-05-11 | unknown | Add prune-artifacts workflow to main (default branch) |
| `apk-build-36` | `bd10062e97690a641ac0c44276d83332d9c8abfa` | 2026-05-09 | unknown | Rename project from 'Zombie-squisher' to 'Zombie Crusher' |
| `apk-build-37` | `bd10062e97690a641ac0c44276d83332d9c8abfa` | 2026-05-09 | unknown | Rename project from 'Zombie-squisher' to 'Zombie Crusher' |
| `apk-build-38` | `bd10062e97690a641ac0c44276d83332d9c8abfa` | 2026-05-09 | unknown | Rename project from 'Zombie-squisher' to 'Zombie Crusher' |
| `apk-build-41` | `bd10062e97690a641ac0c44276d83332d9c8abfa` | 2026-05-09 | unknown | Rename project from 'Zombie-squisher' to 'Zombie Crusher' |
| `apk-build-42` | `bd10062e97690a641ac0c44276d83332d9c8abfa` | 2026-05-09 | unknown | Rename project from 'Zombie-squisher' to 'Zombie Crusher' |
| `apk-build-43` | `bd10062e97690a641ac0c44276d83332d9c8abfa` | 2026-05-09 | unknown | Rename project from 'Zombie-squisher' to 'Zombie Crusher' |
| `apk-build-44` | `bd10062e97690a641ac0c44276d83332d9c8abfa` | 2026-05-09 | unknown | Rename project from 'Zombie-squisher' to 'Zombie Crusher' |
| `apk-build-52` | `bd10062e97690a641ac0c44276d83332d9c8abfa` | 2026-05-09 | unknown | Rename project from 'Zombie-squisher' to 'Zombie Crusher' |
| `apk-build-55` | `bd10062e97690a641ac0c44276d83332d9c8abfa` | 2026-05-09 | unknown | Rename project from 'Zombie-squisher' to 'Zombie Crusher' |
| `apk-build-56` | `bd10062e97690a641ac0c44276d83332d9c8abfa` | 2026-05-09 | unknown | Rename project from 'Zombie-squisher' to 'Zombie Crusher' |
| `apk-build-57` | `bd10062e97690a641ac0c44276d83332d9c8abfa` | 2026-05-09 | unknown | Rename project from 'Zombie-squisher' to 'Zombie Crusher' |
| `apk-build-18` | `214f7ba947443356f35a3c5a4c64a59d35c6aa65` | 2026-05-09 | unknown | Add agentic docs folder with project rules and modes [skip ci] |
| `apk-build-19` | `214f7ba947443356f35a3c5a4c64a59d35c6aa65` | 2026-05-09 | unknown | Add agentic docs folder with project rules and modes [skip ci] |
| `apk-build-20` | `214f7ba947443356f35a3c5a4c64a59d35c6aa65` | 2026-05-09 | unknown | Add agentic docs folder with project rules and modes [skip ci] |
| `apk-build-21` | `214f7ba947443356f35a3c5a4c64a59d35c6aa65` | 2026-05-09 | unknown | Add agentic docs folder with project rules and modes [skip ci] |
| `apk-build-17` | `1b6736336e10cfee8da123fc7197d651e55d1cd8` | 2026-05-08 | unknown | Initial commit |

## Asset manifests and licence records

- `THIRD_PARTY_NOTICES.md`
- `docs/THIRD_PARTY_ASSETS.md`
- `tests/provenance.test.ts`
- `tools/build-manifest.js`
- `tools/license-texts/expo.LICENSE`
- `tools/license-texts/react-native.LICENSE`
- `tools/license-texts/react-three-fiber.LICENSE`

## Important artwork

Logos, icons, splash, branding and store-like images, and any image 512 px or larger, across every branch head (69 distinct image path/blob pairs in total). Links pin the branch head SHA where the file was seen.

| Path | Size (px) | Bytes | Blob | Seen on | Link |
|---|---|---|---|---|---|
| `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` | 1536x1024 | 2838266 | `e11f8c576652` | `ccr-27903f19-fy49jb` +2 | [view](https://github.com/verbal76/Zombie-squisher/blob/b1f89f410bff21c171741cd517caad441c6ca43d/Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png) |
| `assets-source/characters/texture-a.png` | 1024x1024 | 20171 | `7c054d8d6898` | `ccr-27903f19-fy49jb` | [view](https://github.com/verbal76/Zombie-squisher/blob/b1f89f410bff21c171741cd517caad441c6ca43d/assets-source/characters/texture-a.png) |
| `assets-source/characters/texture-b.png` | 1024x1024 | 15606 | `9d7f85c2342a` | `ccr-27903f19-fy49jb` | [view](https://github.com/verbal76/Zombie-squisher/blob/b1f89f410bff21c171741cd517caad441c6ca43d/assets-source/characters/texture-b.png) |
| `assets-source/characters/texture-c.png` | 1024x1024 | 12829 | `ecf680d0d693` | `ccr-27903f19-fy49jb` | [view](https://github.com/verbal76/Zombie-squisher/blob/b1f89f410bff21c171741cd517caad441c6ca43d/assets-source/characters/texture-c.png) |
| `assets-source/characters/texture-d.png` | 1024x1024 | 13151 | `809546b9eeeb` | `ccr-27903f19-fy49jb` | [view](https://github.com/verbal76/Zombie-squisher/blob/b1f89f410bff21c171741cd517caad441c6ca43d/assets-source/characters/texture-d.png) |
| `assets-source/characters/texture-e.png` | 1024x1024 | 14509 | `68f3cf5bd237` | `ccr-27903f19-fy49jb` | [view](https://github.com/verbal76/Zombie-squisher/blob/b1f89f410bff21c171741cd517caad441c6ca43d/assets-source/characters/texture-e.png) |
| `assets-source/characters/texture-f.png` | 1024x1024 | 15886 | `38fe58986f18` | `ccr-27903f19-fy49jb` | [view](https://github.com/verbal76/Zombie-squisher/blob/b1f89f410bff21c171741cd517caad441c6ca43d/assets-source/characters/texture-f.png) |
| `assets-source/characters/texture-g.png` | 1024x1024 | 16069 | `6cb06fdae2cc` | `ccr-27903f19-fy49jb` | [view](https://github.com/verbal76/Zombie-squisher/blob/b1f89f410bff21c171741cd517caad441c6ca43d/assets-source/characters/texture-g.png) |
| `assets-source/characters/texture-h.png` | 1024x1024 | 16215 | `fdda30b9c47d` | `ccr-27903f19-fy49jb` | [view](https://github.com/verbal76/Zombie-squisher/blob/b1f89f410bff21c171741cd517caad441c6ca43d/assets-source/characters/texture-h.png) |
| `assets-source/characters/texture-i.png` | 1024x1024 | 14496 | `19ec6cba8f8a` | `ccr-27903f19-fy49jb` | [view](https://github.com/verbal76/Zombie-squisher/blob/b1f89f410bff21c171741cd517caad441c6ca43d/assets-source/characters/texture-i.png) |
| `assets-source/characters/texture-j.png` | 1024x1024 | 17576 | `7c74a3c1be7d` | `ccr-27903f19-fy49jb` | [view](https://github.com/verbal76/Zombie-squisher/blob/b1f89f410bff21c171741cd517caad441c6ca43d/assets-source/characters/texture-j.png) |
| `assets-source/characters/texture-k.png` | 1024x1024 | 17437 | `ad7e356c18f5` | `ccr-27903f19-fy49jb` | [view](https://github.com/verbal76/Zombie-squisher/blob/b1f89f410bff21c171741cd517caad441c6ca43d/assets-source/characters/texture-k.png) |
| `assets-source/characters/texture-l.png` | 1024x1024 | 22764 | `c4a7996ce61c` | `ccr-27903f19-fy49jb` | [view](https://github.com/verbal76/Zombie-squisher/blob/b1f89f410bff21c171741cd517caad441c6ca43d/assets-source/characters/texture-l.png) |
| `assets-source/characters/texture-m.png` | 1024x1024 | 19343 | `8b98e3d03ef0` | `ccr-27903f19-fy49jb` | [view](https://github.com/verbal76/Zombie-squisher/blob/b1f89f410bff21c171741cd517caad441c6ca43d/assets-source/characters/texture-m.png) |
| `assets-source/characters/texture-n.png` | 1024x1024 | 16824 | `5ad33102dc6a` | `ccr-27903f19-fy49jb` | [view](https://github.com/verbal76/Zombie-squisher/blob/b1f89f410bff21c171741cd517caad441c6ca43d/assets-source/characters/texture-n.png) |
| `assets-source/characters/texture-o.png` | 1024x1024 | 21064 | `e7776591eb34` | `ccr-27903f19-fy49jb` | [view](https://github.com/verbal76/Zombie-squisher/blob/b1f89f410bff21c171741cd517caad441c6ca43d/assets-source/characters/texture-o.png) |
| `assets-source/characters/texture-p.png` | 1024x1024 | 18000 | `43eddd9d8791` | `ccr-27903f19-fy49jb` | [view](https://github.com/verbal76/Zombie-squisher/blob/b1f89f410bff21c171741cd517caad441c6ca43d/assets-source/characters/texture-p.png) |
| `assets-source/characters/texture-q.png` | 1024x1024 | 16102 | `f4d122428770` | `ccr-27903f19-fy49jb` | [view](https://github.com/verbal76/Zombie-squisher/blob/b1f89f410bff21c171741cd517caad441c6ca43d/assets-source/characters/texture-q.png) |
| `assets-source/characters/texture-r.png` | 1024x1024 | 13909 | `76171dca3314` | `ccr-27903f19-fy49jb` | [view](https://github.com/verbal76/Zombie-squisher/blob/b1f89f410bff21c171741cd517caad441c6ca43d/assets-source/characters/texture-r.png) |
| `assets/brand/adaptive-icon-foreground.png` | 1024x1024 | 132906 | `5a134a26aae8` | `ccr-27903f19-fy49jb` | [view](https://github.com/verbal76/Zombie-squisher/blob/b1f89f410bff21c171741cd517caad441c6ca43d/assets/brand/adaptive-icon-foreground.png) |
| `assets/brand/adaptive-icon-monochrome.png` | 1024x1024 | 31360 | `4c58e2808fa9` | `ccr-27903f19-fy49jb` | [view](https://github.com/verbal76/Zombie-squisher/blob/b1f89f410bff21c171741cd517caad441c6ca43d/assets/brand/adaptive-icon-monochrome.png) |
| `assets/brand/hag-logo.png` | 1024x667 | 1135003 | `a41949867c85` | `ccr-27903f19-fy49jb` | [view](https://github.com/verbal76/Zombie-squisher/blob/b1f89f410bff21c171741cd517caad441c6ca43d/assets/brand/hag-logo.png) |
| `assets/brand/icon.png` | 1024x1024 | 187768 | `4a3277f25a64` | `ccr-27903f19-fy49jb` | [view](https://github.com/verbal76/Zombie-squisher/blob/b1f89f410bff21c171741cd517caad441c6ca43d/assets/brand/icon.png) |
| `assets/brand/splash-blank.png` | 288x288 | 401 | `165b21f09aa4` | `ccr-27903f19-fy49jb` | [view](https://github.com/verbal76/Zombie-squisher/blob/b1f89f410bff21c171741cd517caad441c6ca43d/assets/brand/splash-blank.png) |
| `assets/colormap.png` | 512x512 | 12684 | `356a686ff11a` | `ccr-27903f19-fy49jb` +3 | [view](https://github.com/verbal76/Zombie-squisher/blob/b1f89f410bff21c171741cd517caad441c6ca43d/assets/colormap.png) |
| `assets/adaptive-icon-foreground.png` | 1024x1024 | 6702 | `3f27d6c7fa3a` | `archive/scratch-rewrite-97a5729` | [view](https://github.com/verbal76/Zombie-squisher/blob/97a57298d594d5aef52dc8ccb31d8f0b2aad376c/assets/adaptive-icon-foreground.png) |
| `assets/hag-logo.png` | 1024x667 | 1135003 | `a41949867c85` | `archive/scratch-rewrite-97a5729` | [view](https://github.com/verbal76/Zombie-squisher/blob/97a57298d594d5aef52dc8ccb31d8f0b2aad376c/assets/hag-logo.png) |
| `assets/icon.png` | 1024x1024 | 7631 | `7aea70cbc539` | `archive/scratch-rewrite-97a5729` | [view](https://github.com/verbal76/Zombie-squisher/blob/97a57298d594d5aef52dc8ccb31d8f0b2aad376c/assets/icon.png) |
| `assets/splash-blank.png` | 288x288 | 401 | `165b21f09aa4` | `archive/scratch-rewrite-97a5729` | [view](https://github.com/verbal76/Zombie-squisher/blob/97a57298d594d5aef52dc8ccb31d8f0b2aad376c/assets/splash-blank.png) |
| `assets/texture-a.png` | 1024x1024 | 20171 | `7c054d8d6898` | `Github-build-pipeline-zombie-crusher` +2 | [view](https://github.com/verbal76/Zombie-squisher/blob/7004f7d46b260dc2cf739006353987df85395854/assets/texture-a.png) |
| `assets/texture-b.png` | 1024x1024 | 15606 | `9d7f85c2342a` | `Github-build-pipeline-zombie-crusher` +2 | [view](https://github.com/verbal76/Zombie-squisher/blob/7004f7d46b260dc2cf739006353987df85395854/assets/texture-b.png) |
| `assets/texture-c.png` | 1024x1024 | 12829 | `ecf680d0d693` | `Github-build-pipeline-zombie-crusher` +2 | [view](https://github.com/verbal76/Zombie-squisher/blob/7004f7d46b260dc2cf739006353987df85395854/assets/texture-c.png) |
| `assets/texture-d.png` | 1024x1024 | 13151 | `809546b9eeeb` | `Github-build-pipeline-zombie-crusher` +2 | [view](https://github.com/verbal76/Zombie-squisher/blob/7004f7d46b260dc2cf739006353987df85395854/assets/texture-d.png) |
| `assets/texture-e.png` | 1024x1024 | 14509 | `68f3cf5bd237` | `Github-build-pipeline-zombie-crusher` +2 | [view](https://github.com/verbal76/Zombie-squisher/blob/7004f7d46b260dc2cf739006353987df85395854/assets/texture-e.png) |
| `assets/texture-f.png` | 1024x1024 | 15886 | `38fe58986f18` | `Github-build-pipeline-zombie-crusher` +2 | [view](https://github.com/verbal76/Zombie-squisher/blob/7004f7d46b260dc2cf739006353987df85395854/assets/texture-f.png) |
| `assets/texture-g.png` | 1024x1024 | 16069 | `6cb06fdae2cc` | `Github-build-pipeline-zombie-crusher` +2 | [view](https://github.com/verbal76/Zombie-squisher/blob/7004f7d46b260dc2cf739006353987df85395854/assets/texture-g.png) |
| `assets/texture-h.png` | 1024x1024 | 16215 | `fdda30b9c47d` | `Github-build-pipeline-zombie-crusher` +2 | [view](https://github.com/verbal76/Zombie-squisher/blob/7004f7d46b260dc2cf739006353987df85395854/assets/texture-h.png) |
| `assets/texture-i.png` | 1024x1024 | 14496 | `19ec6cba8f8a` | `Github-build-pipeline-zombie-crusher` +2 | [view](https://github.com/verbal76/Zombie-squisher/blob/7004f7d46b260dc2cf739006353987df85395854/assets/texture-i.png) |
| `assets/texture-j.png` | 1024x1024 | 17576 | `7c74a3c1be7d` | `Github-build-pipeline-zombie-crusher` +2 | [view](https://github.com/verbal76/Zombie-squisher/blob/7004f7d46b260dc2cf739006353987df85395854/assets/texture-j.png) |
| `assets/texture-k.png` | 1024x1024 | 17437 | `ad7e356c18f5` | `Github-build-pipeline-zombie-crusher` +2 | [view](https://github.com/verbal76/Zombie-squisher/blob/7004f7d46b260dc2cf739006353987df85395854/assets/texture-k.png) |
| `assets/texture-l.png` | 1024x1024 | 22764 | `c4a7996ce61c` | `Github-build-pipeline-zombie-crusher` +2 | [view](https://github.com/verbal76/Zombie-squisher/blob/7004f7d46b260dc2cf739006353987df85395854/assets/texture-l.png) |
| `assets/texture-m.png` | 1024x1024 | 19343 | `8b98e3d03ef0` | `Github-build-pipeline-zombie-crusher` +2 | [view](https://github.com/verbal76/Zombie-squisher/blob/7004f7d46b260dc2cf739006353987df85395854/assets/texture-m.png) |
| `assets/texture-n.png` | 1024x1024 | 16824 | `5ad33102dc6a` | `Github-build-pipeline-zombie-crusher` +2 | [view](https://github.com/verbal76/Zombie-squisher/blob/7004f7d46b260dc2cf739006353987df85395854/assets/texture-n.png) |
| `assets/texture-o.png` | 1024x1024 | 21064 | `e7776591eb34` | `Github-build-pipeline-zombie-crusher` +2 | [view](https://github.com/verbal76/Zombie-squisher/blob/7004f7d46b260dc2cf739006353987df85395854/assets/texture-o.png) |
| `assets/texture-p.png` | 1024x1024 | 18000 | `43eddd9d8791` | `Github-build-pipeline-zombie-crusher` +2 | [view](https://github.com/verbal76/Zombie-squisher/blob/7004f7d46b260dc2cf739006353987df85395854/assets/texture-p.png) |
| `assets/texture-q.png` | 1024x1024 | 16102 | `f4d122428770` | `Github-build-pipeline-zombie-crusher` +2 | [view](https://github.com/verbal76/Zombie-squisher/blob/7004f7d46b260dc2cf739006353987df85395854/assets/texture-q.png) |
| `assets/texture-r.png` | 1024x1024 | 13909 | `76171dca3314` | `Github-build-pipeline-zombie-crusher` +2 | [view](https://github.com/verbal76/Zombie-squisher/blob/7004f7d46b260dc2cf739006353987df85395854/assets/texture-r.png) |
| `src/assets/icon.png` | unknown | 7180 | `96b8857d1eda` | `Github-build-pipeline-zombie-crusher` +3 | [view](https://github.com/verbal76/Zombie-squisher/blob/7004f7d46b260dc2cf739006353987df85395854/src/assets/icon.png) |

## Features and layout

Top level of `ccr-27903f19-fy49jb`:

`.easignore` (1), `.github/` (5), `.gitignore` (1), `App.tsx` (1), `CLAUDE.md` (1), `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` (1), `README.md` (1), `THIRD_PARTY_NOTICES.md` (1), `agentic docs/` (7), `app.json` (1), `assets-source/` (36), `assets/` (150), `babel.config.js` (1), `desktop/` (6), `docs/` (11), `eas.json` (1), `index.ts` (1), `metro.config.js` (1), `package-lock.json` (1), `package.json` (1), `plugins/` (2), `scripts/` (3), `src/` (54), `tests/` (13), `tools/` (28), `tsconfig.json` (1)

Top level of default `main`: `.github/` (1), `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` (1), `README.md` (1), `agentic docs/` (7)

## CI workflows

Path and trigger only; never changed or run.

| Branch:path | Name | Trigger (`on:`) |
|---|---|---|
| `ccr-27903f19-fy49jb:.github/workflows/build-apk.yml` | Build, verify and smoke-test APK | workflow_call:     inputs:       profile:         type: string         default: preview       run_smoke:         type: boolean         default: true       build |
| `ccr-27903f19-fy49jb:.github/workflows/build.yml` | Build (Android / Windows / Linux) | workflow_dispatch:     inputs:       platform:         description: 'Which platform(s) to build'         type: choice         options: [all, android, windows, l |
| `ccr-27903f19-fy49jb:.github/workflows/ci.yml` | CI | pull_request:     paths-ignore:       - '**/*.md'       - 'docs/**'       - 'agentic docs/**'       - 'LICENSE'   workflow_dispatch: |
| `ccr-27903f19-fy49jb:.github/workflows/eas-update.yml` | EAS Update (OTA) | workflow_dispatch:     inputs:       channel:         description: 'EAS update channel/branch'         type: choice         options: [preview, production]       |
| `ccr-27903f19-fy49jb:.github/workflows/prune-artifacts.yml` | Prune Artifacts | workflow_dispatch: |
| `main:.github/workflows/prune-artifacts.yml` | Prune Artifacts | workflow_dispatch:   schedule:     - cron: '0 6 * * *'   workflow_run:     workflows: ['Android APK (GitHub Runner)']     types: [completed] |

## Sensitive files (paths only; contents not read)

- none matched

## Unknowns and duplicates

Same blob under more than one path on some branch head: 39 blobs.
- `2e99b7874675`: `assets-source/characters/character-a.glb`, `assets/character-a.glb`
- `8de04f32906c`: `assets-source/characters/character-b.glb`, `assets/character-b.glb`
- `755957019277`: `assets-source/characters/character-c.glb`, `assets/character-c.glb`
- `25284ee29228`: `assets-source/characters/character-d.glb`, `assets/character-d.glb`
- `c6a8cceb0723`: `assets-source/characters/character-e.glb`, `assets/character-e.glb`
- `6247ec57d1c8`: `assets-source/characters/character-f.glb`, `assets/character-f.glb`
- `3a1baaeb36f7`: `assets-source/characters/character-g.glb`, `assets/character-g.glb`
- `bcc9e3e03402`: `assets-source/characters/character-h.glb`, `assets/character-h.glb`
- `1be9f8e1ec1d`: `assets-source/characters/character-i.glb`, `assets/character-i.glb`
- `da8855df1216`: `assets-source/characters/character-j.glb`, `assets/character-j.glb`
- `8600f846c9c2`: `assets-source/characters/character-k.glb`, `assets/character-k.glb`
- `3fcae2199335`: `assets-source/characters/character-l.glb`, `assets/character-l.glb`
- The GitHub default branch `main` holds only 10 files while work lives on `ccr-27903f19-fy49jb`; anyone cloning the default sees an upload snapshot, not the product.
