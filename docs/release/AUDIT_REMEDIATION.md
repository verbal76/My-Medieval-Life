# Audit remediation (2026-10-18)

Follows the read-only repository audit of 2026-10-18. Status of each finding, what was changed on
`staging/my-medieval-life`, and what only the owner can do. This repository is public: this
document names no private repository and reproduces no asset contents.

## Findings and status

| Id | Finding | Status |
|---|---|---|
| P0-1 | A save the game could not read was overwritten by the new game that followed | **Fixed** (`21647e2`): `SaveStore` (atomic, verified writes with a backup; unusable saves moved aside unchanged before anything writes; honest messages); tests in `run_tests.gd` and `start_test.gd` |
| P1-2 | Development pushes could publish a public release | **Fixed on staging**; **one older branch still dangerous** (below) |
| P1-1 | Each Android build had a new signing key, so updating meant uninstalling and losing the save | **Prepared**: `release.yml` signs with a stable test key from secrets; **owner must create the key** (`ANDROID_SIGNING.md`) |
| P0-2 | Paid art packs' original files are in this public repository | **Assessed** (below); remediation needs owner approval |
| P0-3 | An old branch exposed private-repository details | Owner approved deleting it; **owner must delete it by hand** (the session cannot delete branches) and may send the prepared GitHub Support request |

## Release automation

| Branch | Workflow file | Trigger | Risk |
|---|---|---|---|
| `staging/my-medieval-life` | `release.yml` | manual only | Safe. Default is a private draft; "public" also needs the typed confirmation `publish publicly` and an approval in the `public-release` environment |
| `staging/my-medieval-life` | `tests.yml` (new) | push to staging touching code, data or tests; manual | Safe: tests only, read-only permissions, no build or release |
| `wip/agent-*` (7 branches) | `release.yml` | manual only | Safe |
| `main` | none | — | Safe today |
| `claude/charming-albattani-8jjfya` (draft PR #1) | old `release.yml` | **push** to `main` and `claude/**` touching `game/**` | **Dangerous**: any push to that branch publishes a public pre-release. Merging PR #1 would put this file on `main`, where every later push touching `game/` would publish a public full release |

Changing staging does not protect other branches: GitHub runs the workflow file of the branch that
was pushed.

**Actions use:** locally the tests take about 40 seconds (run_tests 21 s, start_test 10 s, play_test
2 s, Python 6 s); on GitHub, with checkout, setup and a cached Godot, expect roughly 3–5 minutes a
run [estimate]. Bursts of pushes cancel the older run. While the repository is public, standard
GitHub-hosted minutes are free; if it becomes private, they count against the account's quota. To
cut usage further: restrict `tests.yml` to manual runs, or skip runs with `[skip ci]`.

## Paid assets in the public repository

The source archives are kept unchanged in the repository root because the asset tools read straight
from them (`CLAUDE.md` §3). These are labelled **paid** in `ASSET_MANIFEST.md`, whose licence key
says the licence "allows use in games but forbids redistributing the original files":

`16x16 Armour RPG Icons.zip`, `16x16 Jewelry RPG Icons.zip`, `16x16 Survival RPG Icons.zip`,
`CozyFarm_full_version.zip`, `PUNY-WORLD-PAID_v1.zip` (twice on `main`), `PUNY_CHARACTERS_v2.1.zip`,
`PUNY_CHARACTERS_v2.1_tdsm-2026.zip`, `PUNY_SKILLS_v1.zip`, `Simple_Falt_Game_Interface_Pack.zip`,
`SunGraphica_Minimal_Icons_FREE.zip`.

Labelled **verify** (licence not confirmed): `Character-Customizer.zip`,
`My_Medieval_Life_Icon_Pack.zip`, `PUNY_WORLD_v1.zip`, `Flat Game UI Icon Pack/`. The Flat UI pack
supplies the whole in-game interface, so its terms matter most before any sale.

They are on `main`, `staging/my-medieval-life`, PR #1's branch and the `wip/*` branches, and have been
public since 2026-10-17. The repository has no forks. The game builds (Builds 1–7 public, Build 8 a
private draft) contain the art packed into the game, which is normally what "use in games" allows.

**Options (each needs the owner's approval):**
1. **Make the repository private** (recommended first step). It stops further public access at once.
   The history stays, but only for collaborators. Nothing else needs to change.
2. Later, if the source code should ever be public again: move the source archives to a private
   asset store (a private repository, or Git LFS in a private repository), change the tools to read
   them from there, then rewrite this repository's history to remove them. This is a destructive,
   coordinated change: every clone and agent worktree must be re-cloned.
3. Ask GitHub Support to purge cached views only if history is rewritten while public.

## Owner checklist

1. **Delete** the branch `inventory/registry`: https://github.com/verbal76/My-Medieval-Life/branches
   (trash icon), then send the prepared GitHub Support purge request (kept outside the repository).
2. **Decide on PR #1's branch** (`claude/charming-albattani-8jjfya`): close the draft PR and delete
   the branch (staging supersedes it), **or** allow one commit there that removes its push trigger.
   Until then, do not push to it or merge it.
3. **Create the `public-release` environment** before any public release: Settings > Environments >
   New environment `public-release` > Required reviewers: your own account. Without it, GitHub
   creates the environment automatically, unprotected, on the first public run. (Required reviewers
   are free on public repositories; on a private repository they need a paid plan, and the typed
   confirmation remains the guard.)
4. **Create the Android test key** and its three secrets (`ANDROID_SIGNING.md`).
5. **Decide repository visibility** (recommended: private) and the paid-asset option above.
6. Create the private infrastructure repository `verbal76/hag-infrastructure` (the registry is
   prepared and backed up privately).
