# Build 21: tester notes (prepared, not built)

A private playtest build for the owner, to be built from `wip/multiplayer-b19` when the owner asks: Android, Windows and Linux from one
commit with one build number (BUILD-3PLATFORM; Android signed with the permanent test key from the secrets, no disposable key). Nothing
has been built or published from this branch for Build 21.

## Saves

- Build 21 writes **save version 22**. A Build 20 save (version 21) loads in Build 21 with everything kept (tested with a real Build 20
  save, `game/tests/fixtures/b20_save_v21_single.json`); loading it twice gives the same world. **Build 20 cannot open a Build 21 save**
  (it says the save is from a newer version and leaves the file alone): export your save before trying Build 21 if you may go back.

## What is new since Build 20 (single player)

- **Crime and the guards** (the crime, pursuit and talk repair): the guards keep a case on you; one who loses sight of you searches
  where you were last seen, and you stay wanted for a time that depends on the crime; a murder seen raises the **hue and cry**, which
  now spreads from voice to voice: those who hear it call it on, so it travels through a crowd but not past walls or empty ground; a
  second known killing rings the **bell**, heard farther; a guard who may not kill you beats you down and takes you in (a fine, the
  stolen goods back), and you can **yield** to a guard of your case. The families of those you killed treat you as a danger.
- **What villagers say** comes from what they saw or were told, in their own voice, related events told as one, the gravest first,
  and not over and over; village news travels by who knows it.
- **Parcels** with alike names are told apart by a second landmark.
- The simulation gate (SIM-GATE-01) now runs before every build; the flight recorder (off in play) gained hourly village snapshots.

## Multiplayer: foundations only, not playable

Playing one world with friends is being built and is **not reachable in this build**: there is **no menu to host or join** a game,
and Android has no network permission for it yet. What is in place underneath, and tested on one machine only: friends' characters
kept in your world and save, each with their own purse, goods, skills, crimes, standing with the villagers, family and heirs; every
action by the same rules as yours, applied by your game; rest only when everyone rests; marriage and gifts between players only when
both agree. Nothing of it changes a single-player game (the single-player simulation is identical to Build 20's, checked).

## Known limitations

- Multiplayer cannot be tried (above). Real devices, Wi-Fi and mixed platforms are untested (the next batch).
- The items listed as still on the list in the Build 20 notes are unchanged by this build (the smithy wall indoors, the bandit camp's
  pictures, the gift number picker, and the rest).
- The five simulation warning thresholds are still proposals awaiting the owner.
