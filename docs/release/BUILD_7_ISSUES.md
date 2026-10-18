# Build 7 issue register

The running record of everything found while the owner tests Build 7 on real hardware. Build 7 is
the testing baseline and stays exactly as released:

| | |
|---|---|
| Release | `build-7` (pre-release), https://github.com/verbal76/My-Medieval-Life/releases/tag/build-7 |
| Source commit | `679907121654c7630b170690752429b55a74b8ac` |
| Development branch | `staging/my-medieval-life`; every fix below names the staging commit that carries it |
| Next build | Build 8 only when the owner authorizes it; fixes accumulate here until then |

## How to read it

**Kind**
- **Bug**: something does not work as built or approved.
- **Usability**: works, but is hard to see, reach or understand while playing.
- **Enhancement**: a proposed change to approved behaviour; needs the owner's approval first.
- **Future**: an approved or proposed feature not built yet; tracked, never shown as done.

**Severity**
- **S1**: crash, lost save or blocked play.
- **S2**: a feature cannot be used.
- **S3**: works with difficulty or looks wrong.
- **S4**: cosmetic.

**Status**
- **Open**: reported, not yet diagnosed.
- **Diagnosed**: the root cause is known.
- **Fixed (staging)**: corrected, tested here and pushed to staging.
- **Verified**: confirmed on the owner's device.
- **Won't fix**: the owner's decision, with the reason.

An issue reaches **Verified** only after the owner confirms it on a device. A fix tested on this
machine stays **Fixed (staging)** while "Device check" says it still needs hardware.

Each entry records: the date reported, platform, the screenshot or reproduction steps, root cause,
files and systems, the test evidence and the fixing commit.

## Open and fixed issues

| ID | Reported | Kind | Sev. | Platform | Summary | Status | Commit | Device check |
|---|---|---|---|---|---|---|---|---|
| — | | | | | No owner reports yet | | | |

### Issue details

(One section per issue, `B7-001` onwards, in this form.)

```
### B7-000 Title
- Reported: date, by; platform and device
- Evidence: screenshot file or reproduction steps
- Kind / severity:
- Root cause:
- Files and systems:
- Fix:
- Tests: automated (which suites, results) and visual (screenshots looked at)
- Interaction manifest: INT ids added or changed, or none
- Commit: staging hash
- Device check: still needed / done (date, device)
```

## Known before testing (carried from the Build 7 readiness report)

| ID | Kind | Summary | Status |
|---|---|---|---|
| K-1 | Usability | The player starts with 5 coins; land costs 60 or more. The early-earning review is in progress below. | Under review |
| K-2 | Known limitation | The tavern child and the sage sleep on pallets for lack of beds; sleepers are the standing sprite turned on its side (no lying frame in the art) | Recorded |
| K-3 | Known limitation | Every number marked provisional (theft, rents, prices, wages, gear bonuses, child food factor, roof-fade timings) awaits the owner's balance review | Awaiting owner |

## Future development (tracked; not complete)

| ID | Feature | State |
|---|---|---|
| F-1 | NPC workshop construction: villagers build houses but not workshops, and never lease ground or fell trees to build | Approved, not built |
| F-2 | Births, children, aging and family growth: households only grow when people move in, so splits are rare | Approved, not built |
| F-3 | Music and sound: the volume settings exist; no audio has been supplied | Approved, not built |
| F-4 | Provisional economy and theft balance (K-3) | Awaiting owner's review |

## Verification by feature

What has been checked here (automated tests and screenshots on this machine) and what only a device
can show. "Device" stays blank until the owner reports on it.

| Feature | Checked here | Needs a device | Device |
|---|---|---|---|
| Movement and camera (dead zone, pan, recenter, map) | start_test, play_test; screenshots | Touch feel, two-finger pan, a real gamepad's sticks | |
| Touch and buttons | Simulated taps in start_test; screenshots at phone size | Real finger sizes, rounded corners, notches | |
| Text size, contrast, readability | Screenshots at phone and desktop sizes | A real phone screen in daylight | |
| Character creation and menus | start_test | Touch, Android Back, gamepad B | |
| Combat and targeting | run_tests, play_test | Touch and gamepad targeting | |
| Conversations | start_test; screenshots | Touch | |
| Shops, buying and selling | run_tests, start_test; screenshots | Touch | |
| Inventory and equipment | run_tests, start_test; screenshots | Touch, gamepad | |
| Theft, witnesses, consequences | run_tests, start_test | Play feel | |
| Building entry and roof fade | run_tests; screenshots | Flicker or timing on a phone | |
| Buying and leasing property | run_tests, start_test | Touch | |
| House placement and construction | run_tests, start_test; screenshots | Placing the footprint by touch and gamepad | |
| Hiring helpers | run_tests | Play feel | |
| Saving and loading | run_tests (saves from versions 1–6) | Android app suspend, resume and storage | |
| Performance | none | A mid-range phone | |
| Windows build | Compiles; icon checked in the released exe | Running on Windows | |
| Android build | Compiles (debug-signed APK) | Install and play | |
