# Build 13: private three-platform testing packet

This build was made under the owner's Build 13 directives of 2026-10-19:
- the corrective work from the Build 12 audit;
- the four economy rules;
- the four remaining audit items.

It is a private draft release, not public. Build 12 and every earlier release are untouched.

| | |
|---|---|
| Build | 13 (Android `version/code` 13, `version/name` 0.1.13-test; Windows file version 0.1.13.0) |
| Source | `staging/my-medieval-life` at `4e76f72`, all three platforms from this one commit. Its game code is the same as `ccec9c8`; `4e76f72` changes only the release workflow and a document |
| CI on that commit | Tests passed: https://github.com/verbal76/My-Medieval-Life/actions/runs/39260293114 (also on `ccec9c8`: https://github.com/verbal76/My-Medieval-Life/actions/runs/39259161523) |
| Release run | https://github.com/verbal76/My-Medieval-Life/actions/runs/39260892613 |
| Since Build 12 (`f8b4a98`) | 16 commits on staging |

**Artifacts:** the private draft release "My Medieval Life Build 13": https://github.com/verbal76/My-Medieval-Life/releases/tag/untagged-d06c61b5aee445e85328

| File | Size | sha256 |
|---|---|---|
| `MyMedievalLife-build13-android.apk` | 64.6 MB | `f6990ed3d3d249476601563fa0e7dfefc23db408d6a6dd58551f6549c25445c4` |
| `MyMedievalLife-build13-windows-x86_64.zip` | 43.1 MB | `c05bca8c417dce95679cec6c446fbe1f155f46477bdc18a970675485276c26ab` |
| `MyMedievalLife-build13-linux-x86_64.zip` | 33.4 MB | `84796e8aa776509b37e9031168aae6f62103add1e4fa96429fc6762c344ae47f` |

**Checked here:**
- All three files were downloaded back and matched `SHA256SUMS.txt`.
- The Linux build started under a virtual display and drew its title window (screenshot looked at; see Known issues).
- Windows and Android were not run.

## Run numbering

The workflow numbers each build from its run counter.
- **Run 13** was the signing check below. It stopped at the signing step, before building anything.
- **Run 14** was cancelled as soon as it started.
- **Run 15** made this build. It was stamped Build 13 through the new `build_number` input on `release.yml`.

## Android signing (checked)

**The stable test-key secrets do not exist.**
- The run with the temporary-key fallback switched off stopped at its signing step: "The test-signing secrets are missing".
- Its log shows `ANDROID_TEST_KEYSTORE_B64`, `ANDROID_TEST_KEYSTORE_PASSWORD` and `ANDROID_TEST_KEY_ALIAS` all empty.
- This build is therefore signed with a throwaway key, generated on the runner and deleted there.

**Consequences of the throwaway key:**
- The Build 13 APK cannot install over Build 12.
- Testers must uninstall Build 12 first, and uninstalling deletes that phone's save.
- That save would otherwise load in Build 13: the save format did not change (save version 14).
- The first build signed with the stable key will need one more uninstall. After that, builds update in place and keep saves.

**To fix it:** follow `docs/release/ANDROID_SIGNING.md` ("Owner action"). It covers creating the keystore on your own computer and adding the three secrets on GitHub. No key or password has been committed to the repository.

## Changelog since Build 12

**Corrective work (the Build 12 audit):**
- A worker retiring from a fully staffed trade now opens their post, and an apprentice fills it.
- Gold ore has a source: one gold seam in the mine, 8 units, Mining 3. Older saves gain it.
- Medicines show their healing in shops and the Pack.
- Shop attendants can no longer be hired away as carriers.
- `health_jobs_test` runs in CI, and two assertions that could never fail now check real results.

**The owner's economy rules:**
- Merchants never buy without the money.
- Bulk deals are priced unit by unit as stock changes.
- Seed comes only from sellers' stock, farmers' saved seed and the caravan.
- Theft is counted by the items taken, their quantity and their value, and the guard's fine grows with the value.

**The four remaining audit items:**
- **The livestock chain.** Village pens make eggs, milk and wool, and keepers collect and sell them. A new preparation table in the tavern kitchen is where the cook presses cheese and bakes egg bread. Villagers buy and eat them, and the tavern serves bread and cheese suppers. The tanner weaves wool into cloth and sews bandages for the Apothecary.
- **Back on quantity controls.** B, Esc and the window's X close only an open quantity or price control, not the window under it.
- **Touch sprint.** A Run toggle on the touch bar: same speed and stamina cost as LT and Shift, lit while on.
- **Station occupancy.** A villager waits while the player works a station and gives way after 45 game minutes. The player's place is freed the moment their work ends or is cancelled.

**Text and documents:**
- the stamina tooltip, the starting-coins text and the sprint note;
- a Medicine category and a new "Eggs, milk and wool" page in the wiki;
- the release lists, the ledger, the manifest (139 interactions) and the living-world compliance record.

## Tests on the source commit

**Automated:**
- Python unit tests: OK.
- `check_resources.py`: 19 nodes, 0 problems.
- `check_interactions.py`: 139 interactions, 0 problems.
- Regenerated data unchanged.

**Godot suites, all 0 failures:**

| Suite | Result |
|---|---|
| run_tests | 3,515 checks |
| start_test | 478 steps |
| furniture_test | passed |
| play_test | 37 |
| overworld_test | 101 |
| tree_test | 45 |
| world_test | 116 |
| aging_test | 101 |
| wiki_test | passed |
| skills_test | passed |
| chests_test | 72 |
| property_test | 62 |
| business_test | 154 |
| farming_test | 155 |
| health_jobs_test | 37 |

The same suites passed in CI on both commits listed above.

**Device testing:** none.
- No phone, controller, Windows PC or Steam Deck was available.
- Touch sprint, the touch-bar layout and the pad's B were tested headless with simulated input only. In the headless runs the screen-size changes in the touch-bar layout test did not take effect, so only the default screen size was really tested.

## Known issues and limits

- **Android signing:** throwaway key; see above.
- **Title window opens scrolled to the bottom.** On the Linux build under a 1280x720 virtual display, the title window opens at the bottom of its controls list. The Build 12 source does the same, so this is not new in Build 13. Not investigated further here: no way to interact with the window in this environment.
- **Bread and cheese are minor meals.** Villagers still cook most of their meals at home from grain, because two wheat make six bowls of pottage. In an 8-day test run villagers ate 5 egg breads and 2 cheeses.
- **Art limits:** no sit, tool-swing, inner doorway, sawhorse, chimney or feather art in the packs.
- **Still to come:** cloud saves need a Google sign-in app from the owner. Draught animals, coops, hired farm help, trapping and shop production chains are deferred.

## Install and launch

- **Android:**
  1. Allow installs from unknown sources.
  2. Uninstall any earlier My Medieval Life test build. This deletes its save.
  3. Open the APK.
- **Windows:** unzip the package and run `MyMedievalLife.exe`. It is unsigned, so Windows may warn: choose "More info", then "Run anyway".
- **Linux / Steam Deck (desktop mode):** unzip, run `chmod +x MyMedievalLife.x86_64`, then run it.
- **Checksums:** check the files against `SHA256SUMS.txt`. The paths in it start with `release/`.
