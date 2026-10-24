# Build 21: tester notes (prepared, not built)

A private playtest build for the owner, built from `wip/multiplayer-b19` by the lead (owner directive
`docs/directives/2026-10-24_build21_final_integration.md`): Android and Windows (and Linux, which the workflow makes from the same
commit) with one build number, the Android package signed with the permanent test key from the secrets. Nothing has been built or
published from this branch for Build 21 at the time of writing; the lead fills in the build number, commit and checksums.

## Saves: export yours first

- Build 21 writes **save version 22**. A Build 20 save (version 21) loads in Build 21 with everything kept (tested with a real Build 20
  save); loading it twice gives the same world.
- **Build 20 cannot open a Build 21 save** (it says the save is from a newer version and leaves the file alone). Before installing,
  open Settings, Saves, **Copy my save to a file...**, so you can go back to Build 20 with it.

## What is new since Build 20

**Playing with friends on your network (new):**
- **Open to friends** (pause menu, in your world): shows your address (for example 192.168.1.20) and port 47810; an optional password;
  who is playing; **Stop hosting** closes your world to friends and it carries on as yours (saved).
- **Join a game** (title screen): games found on your network are listed; or type the host's address by hand (this works when the
  list stays empty); your name is kept for next time; a password if the game has one; you see the connection's progress and why a
  join failed (wrong password, a different version, a full world, your character already playing, or the game could not be reached).
- A guest leaves by **Leave the game** in their pause menu; their character waits in the host's world.
- Animals now move, fight, die and are born on a guest's screen as on the host's (they were frozen before).
- The **pause menu is a small window** in two columns over the game (no more full-screen brown panel); the new windows are small too.
- The Village Encyclopedia has a **Playing with friends** page.
- **The bandit camp** has its campfire: your chosen animated campfire by SMStudios (credited, with a link), with a crate and a barrel
  round it instead of the market-stall pieces; you can walk behind and in front of the fire.

**Around the village (new in this round):**
- **Market stalls have shelves** (Craftpix art, credited with a link): a stall's goods stand on its two shelves while it is open,
  the stock of a built stall on darker wood; a closed stall's shelves show what it has put out.
- **Gifts:** choose how many to give (a number picker, starting at 1); a gift of several counts as one gift for friendship.
- **Putting up goods at a stall** asks the price in the same window.
- **The smithy is walled indoors** (its east wall, and the lane beside it a step further east); its **workbench** is the table with
  the hammer and tongs, and at the **grinding wheel** the smith, when there, sharpens a worn weapon for 1 coin paid to him (mended to
  full; no extra damage). The Encyclopedia has a **Sharpening** page.
- Containers are named as drawn: a woodpile, a plank pile, a counter, a stall crate.
- **Smaller windows and text** throughout, and a pause menu in two columns.
- **The Encyclopedia** reads as a parchment page, with links in the text.
- **Moving by touch** (Settings, Interface): tap (as before) or a **thumbstick** in the lower-left corner; it walks exactly as keys
  and a gamepad do.
- **Harvesting** (Settings, Interface): manual (as before: Use once, Gather mode for more) or continuous (Use keeps gathering until
  the resource runs out or you move); the same yield, time and tool wear either way.
- The bandit campfire is smaller; villagers no longer repeat the same news line twice; bandits no longer appear inside walls.

**Single player** (from the earlier Build 21 notes):
- **Crime and the guards**: the guards keep a case on you; one who loses sight of you searches where you were last seen, and you stay
  wanted for a time that depends on the crime; a murder seen raises the **hue and cry**, which spreads from voice to voice; a second
  known killing rings the **bell**; a guard who may not kill you beats you down and takes you in (a fine, the stolen goods back), and
  you can **yield**. The families of those you killed treat you as a danger.
- **What villagers say** comes from what they saw or were told, in their own voice, related events told as one, the gravest first.
- **Parcels** with alike names are told apart by a second landmark.
- The single-player village simulation changed in two explained ways only: bandits no longer start on solid cells, and the smithy's
  new wall moves the lane beside it (evidence in `docs/release/SIM_BASELINE_CHANGES_B21.md`); otherwise it matches Build 20's.

## The first LAN test: Windows PC hosts, the phone joins

1. Back up: on the PC, Settings, Saves, Copy my save to a file (or start a separate test world).
2. Both devices on the **same home Wi-Fi** (not a guest network, not the phone's own hotspot).
3. On the PC, start Build 21 and continue your world (or a test world).
4. **Windows Firewall:** the first time the game opens to friends, Windows asks whether to allow My Medieval Life: tick **Private
   networks** and allow it. If you missed it: Windows Security, Firewall and network protection, Allow an app through firewall,
   My Medieval Life, Private. The game uses **UDP ports 47810 (the game) and 47811 (finding games)**.
5. Pause menu, **Open to friends**, a password if you like, **Open to friends**. Note the address shown (192.168.x.x).
6. On the phone, start Build 21, **Join a game**. Pick the PC's game if it is listed; if not, type the address from step 5. Your
   name, the password, **Join**.
7. Check: both characters appear on both screens; both can walk; the other moves on each screen.
8. Try a few shared things: the phone player picks a plant, buys from a villager, talks to someone; watch villagers and animals
   on both screens.
9. On the phone: pause menu, **Leave the game**. The phone returns to the title.
10. On the PC: the world carries on; **Stop hosting**; save; check your world is as it was.

Report what you see; nothing about real devices is verified until you have tried it.

## Known limitations

- **Real devices are untested.** Everything above was tested on one Linux machine over loopback (two game processes); a real Wi-Fi
  network, Windows Firewall, Android and the two together have not been tried. Finding games automatically can fail on some
  routers and phones: type the address then.
- A PC hosts; a phone joins. Phone hosting, internet play and dedicated servers are not in the game. Two players were tested; three
  or four may work but are untested.
- A guest's pause menu has no Save: the host's game keeps the world and the guest's character.
- Players who marry each other have no children (an open owner question).
- Not in this build yet: the business desk, items on tables, farmers tending their fields, lockpicking and children for married
  players; the lead's reconciliation report lists each with its status.
- The thumbstick, the smaller windows and the shelves were checked in screenshots, not yet on a phone.
- The simulation warning thresholds are still proposals awaiting the owner.
