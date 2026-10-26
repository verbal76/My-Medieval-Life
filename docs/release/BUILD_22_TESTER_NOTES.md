# Build 22: tester notes

A private playtest build for the owner: Android, Windows and Linux from one commit with one build number. The APK is
signed with the owner's permanent release key, the same certificate as Build 21, so **Build 22 installs over Build 21 and
keeps the save** (the first update signed with the same key; please confirm it on the phone). Builds up to 20 used other
keys and cannot be updated by it.

## Saves

- Build 22 writes **save version 23** (players' families). A Build 21 save (version 22) loads with everything kept; married
  players get their household on the first load. Build 21 cannot open a Build 22 save, so keep a copy (Settings, Saves,
  **Copy my save to a file...**) if you may want to go back.
- Market stalls and the shops' courier booths stand in new places; an older save moves them with everything they hold.

## What is new since Build 21

**Market and businesses**
- **Renting a market pitch rents the pitch you chose** (it used to rent the first free one and then say "You already rent a stall").
- **The market is spaced out:** two rows of five stalls with room to walk between them.
- **Business desks:** at the smithy, tavern, sawmill and stalls, one desk for trading and for the courier booth; the tavern
  counter works when nobody is serving.
- **Tables show the goods a business sells** (a look only: nothing on them can be taken).

**Armour and weapons**
- **Worn armour shows on your character**, every piece, from every side, and on other players in a shared game. Leather armour
  shows as a leather tunic with gloves and boots.
- **The armourer's catalogue:** 91 armour pieces, helmets, hats and cultural outfits (Viking, Mongol, Japanese, French) and
  1,920 weapons (16 kinds, 30 designs each, in bronze, iron, steel and gold). Order them from the smith, tanner or tailor, or
  make them at a station with the right skill. Cultural and rare pieces are commissions: bring the special materials and pay
  for the work. Rare pieces carry buffs (health, stamina, fireball damage, stamina recovery, melee damage).
- **Boar tusks and antlers** come from killed boars and stags; hunters sell them to the goods merchant.
- **Your weapon is drawn in your hand** while you walk, and attacks swing it; guards and bandits show theirs too.

**Family and village**
- **Married players** (two players in a shared game) have a household. A man and a woman can have children under the village's
  rules; any couple can adopt an orphan; both are the child's parents. Families are kept when a player is away or the game is saved.
- **Farmers walk their fields** with a shovel while they sow, tend and harvest.

**Controls and screens**
- **Being hunted:** a red ring at your feet and a small note under the status box say when guards are after you and why.
- **Lockpicking** is now a game: a cutaway lock with pins and springs; catch each pin at the line (touch, keys 1–6, mouse, or the
  pad's A, B, X, Y, LB, RB). Stopping leaves the lock as it was.
- **Quantity pickers:** on a pad, X picks the least and Y the most, in one press.
- **Right trigger opens Skills** in play (RB and L still work; in a window the trigger still moves between buttons).
- **The encyclopedia lists the tools** every recipe needs, and which items count as each tool.
- **Underground,** timber supports are drawn as a beam across the passage (no longer like a doorway over the ore), and each level
  shows its way out.

## Known limitations

- Nothing here has been checked on a real phone, controller, Windows PC or two devices. Screens and touch were tested with
  simulated input at phone, 16:9 and 16:10 sizes.
- The leather cap uses the pack's nearest helmet and reads orange.
- Food a tavern keeper sets out on a table can still be taken (as theft), as before.
- Orders are made while you wait; the tailor holds no cloth, so bring it for a hat; villagers do not yet make catalogue pieces to
  sell, and a player's business cannot make them.
- The armour and weapon values and buffs are provisional (the owner may change them at review: docs/design/ARMOUR_WEAPON_CATALOGUE.md).
- A couple with no house has no children (adoption already needed a home); their children eat from the household's food, gifts
  and relief, not the parents' chests.
