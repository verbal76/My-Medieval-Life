**My Medieval Life — Build 25R1 Family Playtest.** A family playtest, not a Steam or production release. Built on 2026-11-06 (01:32 UTC) by release run
42144510422 (build number 34) from `wip/b25r1` commit `a9e9f6e` (the complete integrated Build 25R1 scope). Not uploaded to Steam.

## Downloads

- **Windows (play this first):** `MyMedievalLife-B34-Windows.zip`. Unzip anywhere and run the `.exe` inside.
- Windows demo (separate, the existing DEMO-01 demo): `MyMedievalLife-B34-Demo-Windows.zip`.
- Linux (full game): **not included in this release.** The full-game Linux package failed to build (one test failed in its build job, run 42144510422), so no `MyMedievalLife-B34-Linux.zip` is attached. Linux players: use a newer verified build instead, Build 39 (`b3c9eb5`, 2026-11-12; its Linux package starts and quits cleanly), available privately from the developer. The Linux demo below is unaffected. (Correction made 2026-11-12, owner decision ND-22.)
- Android: `MyMedievalLife-B34-Android.apk`, signed with the permanent release key
  (installs over earlier builds and keeps their saves). Demo variants for Linux and Android are also attached.
- `SHA256SUMS.txt` lists every file's checksum.

## Playing together (same home network)

1. One player is the host: start a **new world** (any seed), then open the pause menu and choose **Open to friends**. The window
   shows an invite code and this computer's address.
2. Everyone else: on the title screen choose **Join a game**, pick the host's game from the list or paste the invite code (or
   type the host's address).
3. The host's world is the shared one and is saved on the host's computer. To stop: everyone saves through the host, then quits.
   To resume: the host loads the same world and chooses Open to friends again; the others Join again and get their own
   characters, purses and goods back.
4. Start fresh worlds for this playtest; older saves have not been checked against this build.

## What was checked on this exact commit (`a9e9f6e`)

- Windows: both Windows packages from this run were started headless and quit twice each on a Windows runner (win-smoke runs
  42146459822 and 42146463230), held to release.yml's rules: exit 0, no script errors, nothing leaked at exit. The full package
  attached here is byte-identical to the tested one (sha256 `db3b64043443c81027e5bbf6da12e49bd55127d7ab525b915555ec8ef16be369`).
- Automated (full test run 42124894260): world generation (overworld 440/0, world 339/0, start 523 steps/0); joining and
  shared play (net_g1, net_interact, net_mp4, net_batch_b, net_fauna, net_family, net_ui, multiplayer A1/B, all 0 failures); the
  host's world saved and restarted with every player's identity, purse, goods, relationships and records (multiplayer_c 326/0,
  net_c 43/0); rejoining after a dropped connection or the host's crash (net_fault 54/0, net_soak 28/0); save files and
  transfers (save_continuity, save_transfer, farm_shared_save, le06_save, judgment_guard_save, all 0 failures); coins and goods
  conserved (conservation 8/0).
- These tests run on one computer over the local network stack. **Not checked yet: two real computers on a home network.**
  Smallest check: host on one PC, join from another, buy something from a villager, save, quit both, reload and rejoin, and see
  that both purses and packs are as they were.

## Known issues

- On world seeds 7 and 11 one settlement (Bourton, Brookhurst) cannot be reached on foot; fixed on the validation branch, not in
  this build. Avoid those two seeds.
- When a house is finished, a villager standing on its site can end up inside the wall until the game is loaded again (no loss).
- A host's sale offer to a guest once failed to arrive in a slow automated test (net_econ_integrity, under investigation; no
  coins or goods were lost: the sale did not happen).
- The simulation's determinism check (a run with the flight recorder against one without) differs from day 18 on one seed; it does
  not affect play and is under investigation, with the 365-day campaign, on the validation branch. The owner's directive of
  2026-11-05 releases this family build while that continues.
