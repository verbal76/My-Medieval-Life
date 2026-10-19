# Build 14: tester notes

Build 14 is a private draft release made from `7dbae4f` (packet: `docs/release/BUILD_14_PACKET.md`; readiness:
`docs/release/BUILD_14_READINESS.md`). It is single player only, with no multiplayer code in the build.

How to read them:
- **Tested** means checked by an automated test or a screenshot looked at on the build machine.
- **Expected** means it should work but nobody has tried it on that kind of device.
- No phone, tablet, controller or Windows PC has been used to check any of this.

## What is new since Build 13

**Harvest or talk.** When a villager stands at the rock, tree or plant you face:
- A (pad), E (keys) or Use works the resource.
- Y (pad) or T (keys) talks to the villager.
- On touch, a tap on the villager talks.
- Tested.

**Villagers look after themselves.** In the evening adults:
- forage flowers, berries and apples near home;
- brew herbal poultices at their hearth;
- treat their own wounds, or buy medicine at the Apothecary.

Tested.

**House storefronts.** Build a counter beside the door of a house you hold (6 planks and 1 iron bar). It is your shop:
- no rent;
- your stock;
- your prices.

Villager households build their own and sell their spare poultices, berries and apples. Tested, with a screenshot looked at.

**Cart parts and handcarts.**
- The carpenter makes wheels, and the smith forges axles and ironwork.
- A handcart is assembled at a workbench from those parts and four planks.
- You can make or buy every part, or buy a finished cart.

Tested.

**Carts in play:**
- Set a handcart down from the Pack, pull it (you walk slower), let go of it, and fill it like a chest.
- Only you, your family or your hired help may use a cart. Taking from someone else's is theft.
- Park at a market cart stop and your stall's attendant unloads it into the stall's store each hour.
- Villager households take their goods to market by cart.
- Tested; screenshot looked at. The cart is drawn with the mine-cart picture (stand-in art).

**Local prices.** A seller asks less when others nearby sell the same thing, and more when they are the only one. Tested.

**Forest animals.**
- Deer, wolves, foxes, bears, birds, boar and rabbits.
- Grazers graze, and predators hunt them. Foxes raid chicken pens at night.
- Wolves and bears fight back, and a starving one may attack a lone person in the woods. Foxes never attack people.
- All can be hunted.

Tested.

**Apple trees** near the houses bear apples in summer and autumn. You and the villagers pick them. Fell them for logs and a sapling. Tested.

**Sword fighting, reworked:**
- A press always swings, with the animation at once.
- The blow lands on the slash.
- You can strike from about a tile and a half in front, with no need to stand on top of the enemy.
- A press near the end of a swing queues the next one.
- Walls and trees block blows.
- On touch, the Attack button swings at a nearby enemy.

Tested in automated tests. The feel on a phone is expected, not checked.

**Controllers on phones and tablets.** Connecting a Bluetooth or wired controller hides the touch buttons and switches to the controller's controls. Unplugging brings the touch buttons back.
- Tested in automated tests.
- Expected on real devices, but not checked.
- Phones whose fingerprint reader shows up as a game controller are handled.

**Title screen** now opens at the top with its buttons in view. Tested.

## Controls

| | Touch | Keyboard and mouse | Controller |
|---|---|---|---|
| Move | Tap the ground | WASD / arrows; click | Left stick |
| Use / work | Use button or tap | E | A |
| Talk to the villager at a resource | Tap them | T | Y |
| Attack | Attack button | Space / J, right-click a target | X |
| Gather mode | Gather button | G | D-pad down |
| Run | Run button | Shift | LT |
| Pack, Skills, Journal, Map | Buttons | I, L, B, M | Menu buttons |

The full list is in Settings → Controls.

## Known limitations (please do not report these as new bugs)

**Art and sound**
- No music or sound: no audio has been supplied, so the volume sliders do nothing yet.
- Stand-in art:
  - the cart is the mine cart;
  - the storefront counter;
  - tools are held, not swung;
  - seated villagers have no sitting pose;
  - the sawhorse and stove are approximations.

**Economy and resources**
- **Iron, coal and copper run out after about 2 hours of play** (game day 10): villagers mine the seams out.
  - The forge keeps working on ore that the visiting caravan sells, but you can no longer mine these yourself.
  - Stone lasts longer.
  - What to do about deposits is waiting on the owner (sustainable mining, prospecting).
- **Forest animals die out in long games:** rabbits after about 8 hours of play, most other kinds after about 14–18 hours. Protected breeding refuges are approved and next in line.
- **Very long games:** over about 45 game years the population slowly falls and no new houses are built. Normal play sessions will not reach this.
- Unemployment grows over the first 100 game days as children come of age with no new trades to take up.

**Other**
- Red wild flowers grow only in the village, not in the wider world.
- Multiplayer is not in this build.

## Saves

- **Save format:** unchanged (version 14). A Build 13 save loads in the candidate code.
  - Tested: a save made by the Build 13 code loads, plays, saves and reloads.
- **New world features in old saves:**
  - An old world gains the new forest animals once.
  - It has no apple trees, which grow only in worlds started in Build 14.
- **Android:** the build is signed with a throwaway key, as every build so far has been (the stable test key does not exist yet). **Installing it over an earlier build will fail: uninstall first, which deletes the save on the phone.**
  - To keep a save across the reinstall, follow "Moving testers to the stable key" in `docs/release/ANDROID_SIGNING.md` (it needs `adb`).

## Please check on your devices

**Phone or tablet**
- The touch buttons, including Run, Gather and Attack.
- Pulling a cart.
- The storefront window.
- Text size.
- The phone's safe areas (notches and rounded corners).

**Controller (phone and PC)**
- Connecting and disconnecting a controller.
- A for Use and Y for Talk.
- X for attack.
- LT for Run.

**Windows**
- The game starts.
- The window icon.
- SmartScreen.

**Sword fighting**
- Do quick presses each swing?
- Do blows land when the bandit is a step away?

Report problems to the owner's issue register with the device, what you did, and what you saw.
