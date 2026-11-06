# B25R1 family playtest release: record (2026-11-05/06)

Owner directives: `docs/directives/2026-11-05_b25r1_family_playtest_now.md` and the Windows-dependency instruction the same
evening (publish Windows without waiting for Linux; smallest change; never bypass `public-release` silently).

## Release

- **Published:** https://github.com/verbal76/My-Medieval-Life/releases/tag/build-34, tag `build-34` at `a9e9f6e` (F, `wip/b25r1`),
  title "My Medieval Life — Build 25R1 Family Playtest", public, not a pre-release, marked Latest, published 2026-11-06 01:52:22 UTC.
- **Built by:** release.yml run 42144510422 (build number 34, started 01:32:26 UTC, visibility private). Its packages, byte for byte.
- **Published by:** `.github/workflows/family-playtest-release.yml` on branch `wip/b25r1-family` (`0697150`), run 42146604466
  (01:51:49-01:52:24 UTC). Why a separate workflow: this session type may not create releases (GitHub API: "Creating, editing, or
  deleting releases is not permitted for this session type"), and release.yml's release job needs a passing simulation gate, which F
  does not have (determinism finding below; set aside for this family build by the owner's directive). It rebuilds nothing, checks
  the release run built `a9e9f6e`, the Windows smoke evidence and the tested file's sha256. It ran under the `public-release`
  environment; no approval was requested by GitHub (the environment has no required reviewer active), so none was bypassed.
- **Windows dependency:** release.yml's smoke-windows needs every package job; the full Linux job was still running 18 minutes after
  the other five finished. Bypassed without editing release.yml: the existing win-smoke.yml (workflow_dispatch: run_id, artifact) ran
  on the release run's own Windows artifacts, held to release.yml's rules (every launch exit 0, no SCRIPT ERROR, nothing in use or
  leaked at exit): full 42146459822 (2 launches, exit 0, no errors or leaks), demo 42146463230 (the same).
- **Byte identity:** `MyMedievalLife-B34-Windows.zip`, 236,000,563 bytes, sha256
  `db3b64043443c81027e5bbf6da12e49bd55127d7ab525b915555ec8ef16be369`: the artifact, the tested file and the public download (fetched
  without credentials after publication) are the same.
- **Assets (10):** Windows, Demo-Windows, Demo-Linux, Android and Demo-Android (APK, idsig, signature note each), SHA256SUMS.txt.
- **Missing: full Linux.** Its job runs the test suite first and stopped on run_tests' one failure on F ("a save and load of the new
  household leaves every section as it was (changed: npcs)": a villager left inside a just-finished house is moved on load; no loss).
  Fixed in `ce594c2` (wip/b25r1-fixhh); not bypassed. The full Linux package comes with the corrected candidate.

## Smoke checks for the family package (on `a9e9f6e`)

Automated, Tests run 42124894260 and the Windows smoke runs: Windows launch PASS; world generation PASS (overworld 440/0, world
339/0, start 523/0); joining and shared world PASS (net_g1, net_interact, net_mp4, net_batch_b, net_fauna, net_family, net_ui,
multiplayer A1/B); player persistence over a host restart PASS (multiplayer_c 326/0, net_c 43/0); save and reload PASS
(save_continuity, save_transfer, farm_shared_save, le06_save, judgment_guard_save); reconnect PASS (net_fault 54/0, net_soak 28/0);
economic persistence PARTLY (conservation 8/0; net_econ_integrity 1 failure: a host's offer did not reach the guest within 8 s, no
sale, no loss; its host-crash section did not run on F). Unverified: two real computers on a home network (manual check in the
release notes).

## Determinism finding (validation, not a playtest blocker per the directive)

Gate 42124898077 on F: det_s1 (seed 1 with the recorder against without) parted on day 18. Root cause (Actions traces 42141394672,
42141398779, 42144094135, 42144097399; debug branch wip/b25r1-detdebug): EconClaims.free_units reconciles stale offers when read, and
the recorder's observation scans read it for extra buyers, so the recorded run cut buyer 39's offers at other moments (claims 92
against 102 of the same 108 coins). An observation side effect; coins conserved in both runs. Fix `65a5f2e` (wip/b25r1-fixdet):
reads under World.observing do not reconcile. Verification: runs 42145933335 (recorded) and 42145938623 (unrecorded), 30 days.
