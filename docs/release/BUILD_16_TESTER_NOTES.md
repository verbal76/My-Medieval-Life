# Build 16: tester notes

What changed since Build 15 (`a8760be`), what to try, and what is known not to work yet. The farming switches for the
shared per-cell and seasonal village farming models are **off**: those stay behind their switches until the owner
approves a yield (FARM-08).

## New things to try

- **Farmland (FARM-01..09).** Build menu, "Farmland: Mark out". Press for the first corner and drag (touch, mouse or
  stick) to the opposite corner: the rectangle is green when the land is free, red with the reason when not, and the
  weekly lease and the purchase price show in the middle of the screen as it grows. Confirm, then choose Lease or Buy.
  Prices follow the land office's rule by area (a 16-30 cell plot leases for 2 coins a week); bought land pays no rent.
  Fence it (planks by the length of the edge, plus 2 stone for the gate) before ploughing, then plough, sow and harvest
  as on any farmland. Villager households take plots by the same rules when they are short of food.
- **Market stalls (STALL-01..06).** Face clear ground with 3 planks: "Build a market stall here". Stock it, press OPEN
  STALL: it sells by itself while you do something else. The takings stay in the stall until you CLOSE it (or it sells
  out); then the manor takes its 5 % and the rest is yours. Every market stall pays the same 5 %, the merchants'
  included. Villager households build and run stalls too.
- **The armoury counter (ARM-01, CTR-01..03).** Stand at the counter and press A: a smith walks over and serves you,
  in working hours. Off hours or when everyone is busy, it tells you why.
- **Businesses buy by need (SHOP-01, TRADE-01).** A business only buys what it can use, as far as its coins allow; when
  it cannot take everything you offer, it says how many it can use.
- **Taking in an orphan (REC-001).** With a partner's household, talk to an orphaned child: "Offer a home".
- **Seeds and cuttings (SEED-02..04, MERCH-01).** Picked flowers sometimes give seed and berry bushes cuttings; the food
  stall sells seed; berry bushes bear in summer and autumn.

## Changed behaviour you may notice

- Villagers have skills by the same rules as you, craft the recipes only you could make before, rest and heal as you
  do, and learn of a crime only by seeing it or being told (player-villager parity, PAR-01..05).
- Relief gives the manor's own stores first; food bought for relief becomes the manor's before it is handed out.
- A dead reeve or guard is replaced through the village's succession of posts; a hunter with no game left takes
  other work.
- Cattle keepers buy feed in part lots and farmers keep the keepers' feed for sale; old cattle are culled before calves.
- Pickpocketing caught is reported by witnesses, not by an automatic alarm.

## Saves

The save format is version 16. A Build 15 save loads (checked with a real Build 15 save): the villagers are given their
skills once, there is no farmland and every stall starts closed. Export your save first (Settings, Saves) before
installing, as always.

## Known limitations

- Not tried on a physical phone, controller or Windows PC: the touch drag for farmland, the armoury counter's A press
  and the stall windows need a device check.
- A player without a partner cannot adopt (there is no player household yet).
- The village can still struggle by design ("A village is allowed to fail. The simulation is not.").
- No audio; some art is stand-in.
