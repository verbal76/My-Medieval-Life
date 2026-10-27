# Build 23: tester notes (Expansion 20)

A private playtest build for the owner: Android, Windows and Linux from one commit with one build number. The APK is signed with
the owner's permanent release key, the same certificate as Builds 21 and 22, so **Build 23 installs over Build 22 and keeps the
save** (please confirm it on the phone).

## Saves

- Build 23 still writes **save version 23**. A Build 22 save loads with everything kept; its Messages journal starts empty.
- Build 22 can open a Build 23 save, but it does not know the new parts (the Messages journal, villagers' remembered history,
  pending offers between players) and would drop them if it saved over the file. Keep a copy (Settings, Saves, **Copy my save to
  a file...**) if you may go back.

## What is new since Build 22

**Playing together (multiplayer)**
- **Other players can be chosen like villagers:** walk up to them; a ring shows at the feet of a player in reach. Tap or click
  them, or use Use / Talk (E, T, Y), Next (Q / Tab, the D-pad) on keys and pad. Clicking open ground still walks.
- **The player window** names the other player and offers **Talk** (a short message, or one of five ready phrases for a
  controller), **Give**, **Sell**, **Contract** (goods only), **Ask to be partners**, and Accept, Decline or Counter for what they
  offer you. Nothing happens without the other player's answer; offers wait until answered or until the day ends. The pause menu
  shows "Players (N waiting)".
- Up to four players (a host and three guests). A guest's offers and messages are seen only by the two players concerned.
- Fixed: guests could not use the mine entrance; a refused purchase vanished from the buyer's screen; the player who lost a race
  for the same plant was shown "+1" (now "Nothing left to pick.").

**On the screen (Android and everywhere)**
- **Messages** sit at the top edge in two short lines, and the prompt is one slim line at the bottom ("Use the oven · Tap them:
  Talk to Sybil Reed", with a small "1/3 >" Next button). Tap a message to put it away.
- **The journal's Messages page** keeps what mattered (deals, contracts, fines, family, quests, villagers' words) **with the
  saved world**, by day and time; each page fits the screen; Earlier and Later turn the pages.
- Recentre puts you in the middle of the clear play area; the status box is smaller; the touch buttons are compact round
  buttons nearer the edge; Use takes the thing in front, Talk takes the person; a soft glow marks what you can use.

**The village**
- Villagers no longer stand at a counter trying again and again to buy a tool they cannot afford; they go back to work.
- Bandits watching their prey at night no longer dither.
- A lie that is shown false now counts against the liar.
- Villagers remember help given toward a house and tell the giver's grandchildren of it ("Your grandmother helped my grandfather
  build our house: 180 coins toward it...").

**Built but switched off in this build** (not playable yet): villagers' aspirations (six kinds of goal), their career choices, a
witness weighing whether to report a crime, and the Living Economy model. They are tested and measured and wait for the owner's
review before they are turned on.

## Known limitations

- **Nothing here has been checked on a real phone, Windows PC, controller or two devices.** Multiplayer was tested with up to
  four copies of the game on one Linux machine; every host and guest platform pair still needs a real-device check
  (docs/expansion20/MP_TEST_MATRIX.md).
- Talk goes to the nearest person, so a villager standing closer is offered before a player (a tap, a click or Next reaches the
  player); keys and pad reach a player only within a villager's reach.
- Contracts between players are for goods only.
- Off-map settlements can decline and lose people to hunger (a legitimate outcome of their rules, under review by the owner).
- Builds 21 and 22's known limitations still apply.
