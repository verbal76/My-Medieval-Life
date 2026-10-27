> **HISTORICAL BUILD / TEST EVIDENCE — NOT CURRENT RELEASE AUTHORITY (owner, 2026-10-27).** Preserve this packet for regression investigation, old test results and provenance, not as the active build, release gate, task list or packaging command. Current build status and policy live in `docs/CURRENT_DEVELOPMENT_STATE.md`, `CLAUDE.md` and the requirements register. Build 22 is the latest private three-platform draft; Expansion 20 remains blocked from packaging until MP-INTERACT-01 merges last and passes validation.

# Build 15: tester notes

Build 15 is a private draft release from `staging/my-medieval-life` (packet: `docs/release/BUILD_15_PACKET.md`). It is
**simulation stabilization**: a village that keeps going for a year without the player. It is single player only,
with no multiplayer code in the build.

How to read them:
- **Tested** means checked by an automated test, a year-long simulation, or a screenshot looked at on the build
  machine.
- **Expected** means it should work but nobody has tried it on that kind of device.
- No phone, tablet, controller or Windows PC has been used to check any of this.

## What is new since Build 14

**Friendship, courting and marriage.**
- Help villagers and give them gifts. A Befriend option appears once they like you.
- Court someone with gifts and time together, then propose. A proposal made too early, or to someone who does
  not want to marry, can be refused.
- Villagers court each other the same way, and single villagers with money to spare seek company.
- Couples of any sex may marry.

Tested.

**Families grow and build.**
- A crowded family can do one of three things:
  - send a grown child out with their partner to found a household;
  - add a sleeping loft under its roof;
  - add a small room or living quarters beside the house.
- Couples share a bed, and young children share two to a bed.
- A household saves for its house, and its relatives help when they can spare the money.
- Builders saw planks and fell timber themselves when nobody sells them.
- Every house goes up with real materials and work over time.

Tested. In a year-long simulation of this build, new houses were finished on both test worlds (6 and 8).

**Money comes back to the trades** (the owner's choices):
- The manor keeps the village's workers in tools. It buys a woodcutter's axe or a miner's pickaxe that is on sale, or
  pays the smith in advance for one.
- Bandits spend their coins on food at the market, where no guard is near.
- Guards bring coins left lying to the manor's treasury.
- The caravan buys hunters' meat and hides and tanners' leather.

Tested.

**Trades are handed on.** A smith who leaves the trade opens the post for an apprentice or a newcomer, as a death
does. Someone out of work can buy an axe to become a woodcutter. Tested.

**Orphaned children are taken in**, in this order:
1. a surviving parent;
2. grandparents;
3. the nearest relative;
4. another household with room.

They keep their birth family's name and family tree. Tested.

**Wildlife lasts.**
- Protected breeding refuges in the woods keep every species alive.
- When a wood has more grazers than grass, the strongest feed first instead of all starving together.

Tested: every species was alive after a simulated year.

**Saves are safer:**
- the game keeps three dated backups, and Continue falls back to them if the save is damaged;
- you can export a copy of your save and import it again (Settings, Saves), to carry a game across a reinstall.

Tested on the build machine; not on a phone.

**Controls:**
- On a controller, D-pad up opens the Journal and pressing the left stick opens the Build menu.
- On the keyboard, H opens Build.
- The controls lists show them all.

Tested.

**Wiki:** six new pages:
- magic;
- the star over an employer;
- the journal and map;
- causes of death;
- the caravan;
- bandits.

Tested.

## Controls

The same as Build 14, plus the shortcuts above. The full lists are in the game (Settings, Controls).

## Known limitations (please do not report these as new bugs)

**Economy**
- **The village can struggle, and that is intended** (the owner's rule: "A village is allowed to fail. The simulation
  is not."). Once the coal seams are worked out the smith is often too poor to buy coal from the caravan, timber and
  firewood run short, and building sites can wait months for planks. One villager died of hunger in a simulated year
  on one test world.
- Different worlds develop differently.
- The caravan brings a fixed 30 coins a day into the village. This is a labelled stand-in for neighbouring
  settlements, which are not simulated yet.
- Iron, coal and copper seams run out after about 2 hours of play. After that, the caravan sells ore.

**Art and sound**
- No music or sound: no audio has been supplied, so the volume sliders do nothing yet.
- Stand-in art:
  - the cart is the mine cart;
  - the storefront counter;
  - tools are held, not swung;
  - seated villagers have no sitting pose;
  - the sawhorse and stove are approximations.

**Other**
- The small room fits beside only three of the village's original houses. The others have no free ground beside
  them: roads, neighbours, fields or the map's edge.
- Multiplayer is not in this build.

## Saves

- **Save format:** unchanged (version 14).
  - Tested: a save made by the Build 14 code loads in this build, plays a day, saves and reloads, with every coin
    accounted for.
- **Android:** the build is signed with a throwaway key, as every build so far has been (the stable test key does
  not exist yet). **Installing it over an earlier build will fail: uninstall first, which deletes the save on the
  phone.**
  - Export your save first (Settings, Saves), then import it after reinstalling.
  - This is new in this build; nobody has tried it on a phone.

## Please check on your devices

**Phone or tablet**
- Export a save, uninstall, install this build, and import the save.
- The touch buttons.
- Gift-giving and the Befriend and Propose choices in conversation.
- Text size and the phone's safe areas.

**Controller (phone and PC)**
- D-pad up for the Journal.
- Pressing the left stick for the Build menu.

**Windows**
- The game starts.
- The window icon.
- SmartScreen.

**A whole life** (the owner's checklist item, DVW-A14)
- Play one character from the start through courting, marriage and a household of their own.

Report problems to the owner's issue register with the device, what you did, and what you saw.
