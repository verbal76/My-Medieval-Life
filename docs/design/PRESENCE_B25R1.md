# Presence by view (B25R1-019) and anticipatory crowd management (B25R1-020)

Owner decisions B25R1-Q5 (saves), Q6 (settlement people only when the player is there), Q7 ("Everywhere, village too"), the
errand clarification of 2026-11-03, and directive `docs/directives/2026-11-03_b25r1_anticipatory_crowd_management.md`
(B25R1-020). Branch `wip/b25r1-presence`. Code: `game/scripts/core/presence.gd` (class `Presence`, one per World as
`w.presence`), `World.update` / `World._tick`, `main.gd` (drawing), `tree_view.gd` (the breeze).

Status: this note describes what is on the branch. Measurements are in section 8. Anything not yet built is marked
**not built**.

## 1. The live range

- **One authority.** `Presence` holds one rect per active player: the camera's visible rect, in tiles. `main.gd`
  `_report_view()` sends the viewport size / camera zoom / 16 and the camera's centre every frame, so zooming out on a phone
  widens the range at once. With no view reported (a guest, the economy simulation, the tests), the rect is
  `DEFAULT_VIEW` = 30 x 17 tiles centred on the player. That is a 1280x720 window at the default x3 zoom, about 27 x 15,
  plus a little.
- **Live ring.** The visible rect grown by `MARGIN_IN` = 4 tiles. Something becomes live inside it and stays live until it is
  past `MARGIN_OUT` = 6 tiles (hysteresis, so nothing flaps at the edge).
- **Decision ring (B25R1-020).** The visible rect grown by `DECIDE_MARGIN` = 12 tiles, used only for crowd pressure
  (section 7).
- **Queries other systems use:** `live_rects()`, `in_live_range(pos)`, `cell_live(c)`, `rect_live(r)`,
  `keeps_live(pos, was_live)`, `version` (bumped when the rects change), the `entered(kind, id)` and `left(kind, id)` signals,
  `listen(cb)`, and the provider protocol (section 6).
- **Below the surface,** a villager is live only on the host's own level.

## 2. What live and calculated mean

The owner: "If anything falls inside of that they become a live thing ... outside of that range. Everything's just a math
problem." And on errands: "that math problem when it's unseen still has to walk from town to town and buy stuff and go back."

**Design choice: one fixed tick for the world's rules, whoever watches.**
- `World.update(real_dt)` adds the frame's time to `tick_left` and runs `_tick(TICK)` for every whole `TICK` = 0.5 real
  seconds (1 game minute).
- `_tick` advances the clock and runs the hours and dawn, the judgment gossip, every villager (`_update_npc`) and the animals
  (`Fauna.update`).
- The players' own walking, hunger, stamina, actions, carts and the region atlas stay per frame. Controls and combat
  input are unchanged at 60 Hz.

What this means for villagers:
- **Live and calculated differ only in what is drawn.** Every villager runs the same decide, act, transaction, needs, work
  and walking code at the same grain. No rule reads `NPC.live`.
- **The headless simulation already stepped at 0.5 s** (`economy_sim.gd` STEP). Under the fixed tick the live game steps
  the same way, which removes the old two tiers. Before, people within 34 tiles of a player were stepped every frame and
  everyone else every 0.5 s, so the old game's outcomes depended on where the player stood.
- **What "calculated" saves:**
  - no sprite update or animation (`ActorSprite` processing is switched off while a villager is not drawn);
  - no per-frame stepping;
  - no drawing.
- **What stays exact:** plans, decisions, `World.trade` / `transfer`, work and crafting at stations, hunger and health,
  relations, journeys.

**Walking.** A calculated villager walks its real path at its real pace (`walk_tiles_per_second`, the elder factor, carts on
worn stone) one tick at a time. Its `n.pos` is therefore known at every game minute: on its way to a station, along the road
to a settlement, or resting by the road at night (`Journeys.night_and_food`). I considered a travel-time estimate (jump to
the end after the walk's time) and rejected it, for three reasons:
- **Little to save.** The walk is 13% of the simulation's CPU, including every work step (section 8).
- **Wrong positions.** Every other rule that reads where people stand (guards seeing bandits, a wolf finding a lone
  villager, a traveller met on the road, the owner's errand requirement) would see a frozen position.
- **Observation effect.** Live walkers would move differently from calculated ones.

**Drawing a live villager.** `NPC.trail` keeps where the last tick took them: its start, each path cell passed, its end. The
view draws the sprite along that polyline at the fraction of the tick the frame has reached (`World.tick_left / TICK`). They
walk round corners and doorways, never through them, and stay at most one tick (1.3 tiles) behind their rule position. A
jump of more than 4 tiles (a door, a portal) is drawn where they landed. Animals are drawn on a straight line between their
last two tick positions. The countryside's clock-driven ambient life is drawn from a smooth clock (`_view_minutes`).

**Animals.** Every animal, live or calculated, grazes, feeds, breeds, ages, hunts and is hunted, and also strolls, flees and
chases (`Fauna._move`), on the tick. Before, only animals within 34 tiles of a player moved. That made where a hunter found
game, or a wolf found a lone villager, depend on where the player stood, and the first observation test showed it: the
villagers diverged within six game hours.
- Strolls draw from `Fauna.move_rng`, the fauna's own stream seeded from the world seed.
- A hungry hunter always chases the nearest prey; before, it did so only near the player and took one at random elsewhere.
- Dispersing young go to their settling point through `_move`; before, unseen ones went in a straight line.
- Cost: `_move` for every animal; 64 animals cost 312 us an update in the old profile, mostly the near ones. Measured in
  the Phase 4 profile.

**Water** (water worker, `wip/b25r1-water`): water's animation and sound play only where `rect_live` / `cell_live` say. The
water data is permanent.

**Trees sway in the breeze.**
- One shared shader per amount of sway; the trunk's foot stays fixed and the top moves.
  - saplings 1.4 texels;
  - young and slender trees 1.0;
  - medium 0.7;
  - stout 0.4 (by the picture's height over width);
  - stumps none.
- The phase comes from the tree's position and the breeze clock; there are no random draws.
- The GPU draws only what is on screen, so only trees in view sway. The CPU cost is one parameter a frame for each of the
  four classes.

## 3. Transitions and their invariants

- **One record per person.**
  - A village villager is one `NPC` in `World.npcs` in both modes. Becoming live or calculated copies nothing, spawns
    nothing and removes nothing; it flips `n.live` and the sprite's visibility.
  - A settlement member is one record. It is either the region worker's member record or, while materialised, one NPC with
    the same identity id (section 6), never both active.
- **Entering range.** The person is drawn where the rules have them: at their station's cell, in their bed, or at the
  point of the path or road they reached this minute, walking in the direction of travel with what they carry. A traveller
  met on the road is there because its calculated walk put it there.
- **Leaving range.** Nothing is written back, because nothing was split. The rules carried on in the same record the whole
  time: plan, position, needs, inventory, relations, journey. Anything the player did while they were live (a trade, a
  conversation, a fight) is already in that record.
- **Saves.** `live`, `trail`, `tick_left`, `ticks`, the crowd cooldowns and the locks are not saved; they are presentation
  or observation state.
  - A loaded world starts with everyone calculated, and the first update classifies them.
  - A save keeps whole ticks only: under 0.5 s of play is lost at a save, as the remainder of the frame was before.
  - Older saves: none needs migrating (owner Q5). This change alters no save key.

## 4. Determinism and observation

- **Removed.**
  - Villagers are stepped the same whether watched or not (the fixed tick).
  - The judgment gossip moved from per frame to per tick; before, it was told a few meetings at every frame, so the frame
    rate changed when gossip spread.
  - Animal strolls no longer draw from `World.rng`.
  - Animals move whether seen or not (above).
- **What remains:** the owner's approved exception, crowd management (section 7). It can be turned off
  (`presence.crowd_enabled`) to measure it alone.
- **The player's own actions** change the world, as they should.
- **Measurement:** the observation test runs one seed twice, the player standing still and the player walking a loop
  through the village, and compares the ledgers (section 8).

## 5. Risks to the village economy

- **Fixed tick in the live game.**
  - The economy already ran at 0.5 s in every simulation. In play, people near the player were stepped every frame; they
    are now stepped like everyone else.
  - Work steps end at whole game minutes, as they always did in the simulation.
  - Fights between villagers step at 0.5 s, as they did off screen.
  - A villager's blows against the player land on ticks. Their cooldown is about a second (`attack_cd` 1.0 times the
    Combat skill), so at most one blow in two ticks; the player's own blows are per frame.
- **Animals** now move everywhere, and hunters chase the nearest prey everywhere, so hunting outcomes shift against the old
  baseline. This is recorded in the sim-gate evidence note, not a defect.
- **Crowd management** shortens pastimes (resting, taking the air, play, company) when the view is crowded. The next
  decision comes sooner; that is the exception the owner approved. Its effect on the economy is measured with it on and off.

## 6. The APIs for the other workers

- **Water:** `w.presence.cell_live(c)`, `rect_live(chunk_rect)`, and `version` to cache.
- **Region (settlements and hamlets), provider protocol:** `w.presence.register(provider)`. Each update, Presence calls:
  - `presence_candidates() -> [{id, pos}]`: where each member is this minute, from `Presence.road_tiles` on the road, or the
    member's station or house;
  - `materialise(id) -> NPC`: the member as a live NPC in `w.npcs` with the same identity id, its record marked live;
  - `fold(npc)`: the NPC's changes back into the member and the NPC out of `w.npcs`, in that one call.

  The same 4/6-tile hysteresis as everyone else applies. Presence never edits the provider's records.
- **The road's one pace:** `Presence.road_tiles(depart, m)`, `walking_minutes`, `arrival`, `along(path, tiles)`.
  - 1.3 tiles a game minute, which is the villagers' walk: 2.6 tiles/s over 2 game minutes/s.
  - Night stops 20:00 to 06:00, as in `Journeys.REST_FROM` / `REST_TO`.
  - A village traveller and a settlement traveller on the same road move alike.
- **Homestead:** households, homesteaders and the band are NPCs in `w.npcs`. They get both modes with no code of theirs.
- **Recorder:** no presence events (lead, 2026-11-03). Becoming visible changes nothing, so the record is the same
  whoever watched. Ids are unchanged, because the same act and trade code runs.

## 7. Anticipatory crowd management (B25R1-020)

The owner's directive, in short:
- Keep the world fully populated and simulated, while a crowded view on Android gets a little less crowded through
  legitimate departures.
- Never hide, teleport, delete, or hurry a protected person.
- The visible target is soft.

**Where it lives.** It is built into the existing schedule and is not a separate crowd AI.
- `NPCBrain` marks the steps that are only passing the time as loose (`NPCBrain.loose`): a child playing, an elder taking
  the air, an adult resting, an evening keeping company.
- `Presence.crowd_step()`, at the start of each tick, may end such a step early. The brain then makes the decision it would
  have made when the step ended anyway, through the same `decide()`, paths, coins and goods.

**The rule.**
- Count the ordinary (unprotected) people awake on the surface in the decision ring (the visible rect + 12 tiles).
- If there are more than `CROWD_TARGET` (18), end the loose steps of up to that excess, farthest from the view's centre
  first (those in the buffer, unseen), in id order on ties. That is a fixed order, from the previous tick's positions, with
  no random draws and nothing frame-based.

**Eligible.** Only a loose step, only after it has lasted `CROWD_MIN_STAY` = 10 game minutes (they are seen to arrive and
settle), and only once in `CROWD_COOLDOWN` = 240 game minutes per person (nobody is shooed about). No errand, purchase,
work step or journey is ever cut: they are not loose.

**Protected, never hurried:**
- anyone fighting or pursuing;
- anyone on a journey;
- anyone below the surface;
- anyone with an attack to report;
- a trader at their trade (a sells-to role and not in a pastime);
- a quest giver or anyone with a marker over them (`Quests.marker`);
- anyone within `LOCK_RADIUS` = 5 tiles of a player;
- anyone under an availability lock (`presence.lock(id, minutes)`, 60 game minutes).

Protected people are counted (`crowd_stats.protected_over_target`) but never moved. If 25 must be present, 25 stay.
`main.gd` locks the villager the player approaches (`approach`) and the one they are walking up to (`_talk_step`).
- Counting: only people outdoors count toward the crowd; someone under a roof is not seen.

**Safeguards.**
- *Hysteresis and cooldown* (above).
- *No reversal:* the brain's next decision is a real one, so a person may legitimately decide to rest again nearby. The
  cooldown stops them being hurried twice.
- *No unsafe destination:* the brain picks it, as it always does.
- *Tick-based, not frame-based.*

**The exception** is recorded in `docs/DECISIONS.md` (2026-11-03). The player's nearness may bring forward an eligible
person's next activity, and nothing else: identities, inventories, coins and completed transactions are untouched.

**Measured:** section 8. Departures that worked, protected people over the target, frame time by visible count, pathing.

## 8. Measurements

Machine: this cloud container (4 cores), Godot 4.7.2 headless. All numbers are measured unless marked "projected".

**Before presence** (seed 1, 2 days, 105 villagers, today's code, STEP 0.5 everywhere headless):
- 41.0 s for 2 days (20.5 s per day). Region worker: 17.9 s per day for 111 NPCs, about 150 ms per NPC per day.

| Subsystem | Share | Per call |
|---|---|---|
| villagers (all) | 65% | |
| villagers: decide | 46.5% | 4.5 ms, 4,212 calls |
| villagers: run plan, incl. walking and work | 13% | 17 us, 317k calls |
| path searches | 0.4% | 40 us |
| hourly and daily | 27% | |
| fauna | 2% | |

**Conclusion for the owner, plainly.**
- In the simulation, calculated mode saves almost nothing for the village. The cost is the decisions (`decide`) and the
  dawn, and those must stay exact for the economy to keep its rules. At most the walking share (under 13%) could be
  estimated instead, and that would break meeting people on the road and add an observation effect, so it is not done.
- The win is in the live game's frame time. Before, every villager within 34 tiles of the player was stepped every frame,
  and sprites were updated within 30 tiles of the camera. Now every villager is stepped twice a second, and only those in
  the view plus 4 tiles are drawn and animated.
- Settlements: the region worker keeps their people as records (34 us per member per day), not as calculated NPCs.

Live-render frame time: (Phase 2 measurement, to be filled in).
Observation test: (Phase 4, to be filled in).
