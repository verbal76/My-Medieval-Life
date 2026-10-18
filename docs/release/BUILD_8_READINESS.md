# Build 8 readiness report

Prepared 2026-10-18 for the owner's decision. **Decision (owner, 2026-10-18): Build 8 is authorized as a private testing build only**: a draft GitHub Release that only the repository's collaborators can see, not a public release, and no merge into `main`.

**Built 2026-10-18:** run 8 of `release.yml` from `staging/my-medieval-life` at `cd35b5446ccc473c0d85d7a839743f07425fd996`, a draft release (no tag yet). Downloaded back and checked: the three files match `SHA256SUMS.txt`; the Windows `.exe` carries the game's icon; the Linux build starts and shows the opening screen (20 coins, the new guidance). Not verified here: the APK on a phone and the `.exe` on Windows.

## Source

| | |
|---|---|
| Proposed source | `staging/my-medieval-life` at the commit this report is pushed in (or a later approved one) |
| Last released build | Build 7, `679907121654c7630b170690752429b55a74b8ac` |
| Changes since Build 7 | 24 commits, 93 files, +7,766 / −170 lines |
| Build number | **Build 8**, the next run of `.github/workflows/release.yml`, started by hand with `visibility: private` (a draft release) |
| Platforms | Linux, Windows and Android from that one commit, kept together in one draft GitHub Release |

## What changed since Build 7

Owner-approved, in order. Issue ids are in `BUILD_7_ISSUES.md`.

- **Economy corrections** (`ae0e01f`):
  - 20 starting coins (B7-001).
  - Guidance in the opening message and the journal, and "Trade with …" (B7-005).
  - Quest rewards set aside and paid exactly (B7-002).
  - The goods merchant buys jewellery and helmets (B7-003).
  - Harvest wheat stays the farmer's (B7-004).
  - Stone by caravan (B7-007).
- **The reeve's real jobs** (`f836aca`, INT-066): the manor's goods are carried and used by the player and villagers alike, paid from the treasury.
- **The HUD anchored to the screen corners**, with camera cutouts avoided (B7-010, `633898f`).
- **Resource prompts and taps** (B7-011, `633898f`, `c8dce2e`): missing tools are named with where to get them; a tap on a seam, tree or field walks there and uses it.
- **Gather mode** (B7-012, `c8dce2e`, INT-068): the Gather button, G, or D-pad down.
- **The resource registry** (`b683461`, `95fc554`, INT-067): one definition of every harvestable node, validated, with generated manifests.
- **The Resources & Gathering journal page**, built from that registry (`8641ff6`).
- **Brown glyph icons** for the action bar, the status panel, empty gear slots and skills (B7-013, `f94ece2`).

## Test results (staging, 2026-10-18)

| Suite | Result |
|---|---|
| `game/tests/run_tests.gd` | 696 checks, 0 failures |
| `game/tests/start_test.gd` (the real interface, including Gather mode, the HUD and the journal page) | 264 steps, 0 failures |
| `game/tests/play_test.gd` | 37 steps, 0 failures |
| `python3 -m unittest discover -s tests` | OK |
| `tools/check_interactions.py` | 69 interactions, 0 problems |
| `tools/check_resources.py` | 12 nodes, 0 problems |
| `game/tests/economy_sim.gd`, 365 days, seeds 1 and 2 (from `f836aca`) | 100/100 alive; no currency, item, deposit or animal leaks |

Screens were looked at on a 2400x1080 phone layout:
- the HUD, with and without a simulated camera hole;
- Gather mode;
- the reeve's job list;
- the pack with filled and empty slots;
- the skills window;
- the journal's Resources & Gathering pages.

## Save compatibility

Saves are now version 8. Build 7 saves are version 6.
- Older saves load with migrations, each tested from a fixture.
- Accepted quests get their promised coins set aside if the giver can pay.
- The manor's work starts empty.
- A version 7 save's single manor quarry job is dropped, with its wage returned to the treasury.
- A save newer than version 8 is refused with a message and kept.

## Platform readiness (compiled locally from staging, 2026-10-18; not distributed)

| | Exported here | Checked here | Not verified |
|---|---|---|---|
| Linux | yes (79 MB) | launched to the title screen under a virtual display | a real desktop |
| Windows | yes (115 MB) | `check_exe_icon.py`: the game's icon is in the `.exe` | running it on Windows |
| Android | yes (64 MB debug APK) | none possible here | the phone: the HUD anchoring and cutouts, Gather taps, touch sizes, the journal page |

All three come from one Godot project with no platform-specific features except Android's Back button and the phone layout, so they carry the same features and content.

## Known issues and limitations

- **Device checks outstanding:**
  - B7-001, B7-005, B7-010, B7-011, B7-012, B7-013, the journal page and a real gamepad;
  - from Build 7: two-finger touch, Android Back, phone performance, and Windows on Windows.
- **Awaiting the owner's decision** (`ECONOMY_SUSTAINABILITY_PROPOSALS.md`):
  - B7-006 (hire wages);
  - B7-007 (deposit depletion);
  - B7-008 (the cash floor and wildlife);
  - B7-009 (the manor's starting treasury: paid manor work begins about day 12);
  - B7-014 (caravan money);
  - B7-015 (food not for sale);
  - B7-016 (insolvent tanners and goods merchants).
- **Open questions:** gold has no seam; apples have no source; whether hunting belongs in Gather mode (it is in, and easy to remove).
- **Tracked future work, not complete:** NPC workshop construction; births and family growth (B7-017); music and sound.
- Every number marked provisional awaits the balance review.

## Decision needed

Whether to run Build 8 for Linux, Windows and Android from the current `staging/my-medieval-life` head, or to keep testing Build 7.
