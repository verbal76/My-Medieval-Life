# Expansion 25: Weather, Seasons and Disasters

**My Medieval Life — expansion packet (design specification, implementation plan and audit), 2026-10-23**

Register: WEATHER-01 (Build 25). Status: **design approved in parts by the owner; no code until the owner approves this
packet.** Build 19 is the priority; nothing here delays it. Founding principle (World Design Rule 022): *a village is
allowed to fail, the simulation is not* — disasters are real outcomes, never secretly undone.

Companion packet: Expansion 26, Creatures and Heroes (`EXPANSION26_CREATURES_AND_HEROES.md`), which builds on this one.

---

## 1. Why two packets

The owner's ideas of 2026-10-23 (weather, seasons, disasters, pets, monsters, bounties) were first gathered as one "Wild
World" expansion, then split at the owner's request into two packets starting at 25:

| Packet | Scope | Why this order |
|---|---|---|
| **25 Weather, Seasons and Disasters** | the world's weather and what it does: rivers, seasons you can see, rain, snow, wind, drought, fire, floods, tornadoes, weather illness, damage and rebuilding | it builds the ground the second packet stands on: rivers and banks, building damage and repair, seasons, warnings and village emergencies |
| **26 Creatures and Heroes** | pets and companions, monsters and bosses, village defence, bounties, monster goods, heroes | the crab and Buwaya need the rivers, the yeti needs winter, monster attacks need building damage and emergency response, all from 25 |

Each is about the size of Expansions 19-23. Each is designed, approved, built on its own branch, tested and released in
turn.

## 2. What exists today (audit of the released Build 18 code)

| Area | Fact |
|---|---|
| Calendar | a game year is 8 game days, four seasons of 2 days; a game day is 12 real minutes |
| Seasonal effects | crop growth by season (winter none), sowing spring to autumn, wild plants and fruit trees bear in season, wildlife breeds in season, feasts, summer cicadas |
| Weather, fire, flood, drought, illness | **none**; the wiki says there is no weather or sickness to die of |
| Water on the maps | **none**: no river, creek, pond, bank or bridge on the village map or the overworld |
| Buildings | a rectangle and door; construction sites with materials; **no condition, damage, repair or destruction** |
| Crops and trees | crops grow hourly; trees die only to an axe and regrow from stumps |
| People | health 30; healing by rest or medicine; death with a recorded cause; the mine cave-in is the only hazard |
| Away and return | permanent identity (Build 19) keeps a person who leaves and returns the same person |
| Firewood | each household burns a log at dawn; without one it is "cold", which does nothing yet |
| Relief | chapel alms and relief; the reeve's relief and public works from the treasury |
| Visuals and sound | no day/night tint or particles; a screen layer exists; ambience has two layers and a wind loop already |
| Saves | optional sections can be added without breaking old saves |
| Ticks | an hourly step and a dawn step; seeded hashes for hazards (determinism) |

## 3. The owner's approved design

### 3.1 Seasons and weather
- **Seasonal, with varied years:** heavy rains and mud in spring and autumn, snow in winter, drought risk in summer;
  storms in spring and autumn. Each year is wetter or drier, so a drought can last a season or more.
- **Rain:** waters crops, slows outdoor work, raises rivers.
- **Heavy rain and rainstorms:** can cause a flash flood on their own; creeks and rivers swell to **one and a half to
  twice their width** and flood their banks.
- **Thunderstorms:** lightning can start fires (rarely; more in a dry season).
- **Heavy wind:** damages weak roofs and fences, fans fires.
- **Tornado:** rare; a path of damage to buildings, crops, animals and people.
- **Snow and cold (hardship):** slower walking, no crop growth, animals need shelter and feed, homes need firewood, chills
  for the cold and wet, heavy snow can collapse a weak roof.
- **Drought:** lower yields and failed crops, drought fever (elderly and children most at risk), campfires can start fires,
  forest fires more likely.

### 3.2 What you see
Snow flurries fall and snow builds up on ground and roofs; children build snowmen and go sledding; footprints, cart ruts,
hoof and paw tracks show in the snow. After heavy rain grass turns muddy, paths become muddy trails, animals leave trails,
and other signs of bad weather show. Rain and snow fall on screen; storms darken the sky.

### 3.3 Disasters (rare but real)
- About **one serious disaster in several game years**, sometimes deadly; damage stays until rebuilt; no hidden rescue.
- **Fire** spreads from a forest fire into a town that is too close; **campfires** can start fires in a drought.
  **Firefighting:** villagers and the player carry water in bucket lines from wells and the river, clear firebreaks; rain
  puts fires out; smoke and burns can injure or kill.
- **Flash flood** tears through low ground and along the banks, destroying buildings, crops and goods. **Mixed fates:** some
  drown; others are carried downstream, missing for a while (the family grieves, the village searches), and walk back days
  later as the same person with their identity and memories.
- **Animals** flee fires and floods: herds trample crops and fences and can injure people; wild animals move to new grounds
  for a while; farm animals may break out of pens.

### 3.4 Warning
A few game hours of readable signs: darkening clouds, rising water, fleeing animals. Experienced villagers act on them
(bring in the harvest, move away from the banks). No numeric forecast.

### 3.5 Weather illness
A small illness system tied to weather only: drought fever (elderly and children most at risk), chills from cold, wet and
snow, foul water after floods. Treated with rest, shelter, food and the existing medicines; it can kill the weak.

### 3.6 Rebuilding
The owner of a building rebuilds through the existing construction system with their own coins and materials; the
treasury repairs public buildings and may grant relief; chapel alms and neighbours' help (Expansion 19 relationships) cover
the poor; the homeless shelter where they can. After a flood a household may rebuild where it stood or **choose a free plot
away from the banks**, remembering the flood.

### 3.7 Rivers and settlements
- **A river along one side of the village and a creek crossing it, with a bridge on the road**, made with the existing map
  tools. **A few low houses and fields sit near the banks** (cheaper land, water at hand), so a flood can take some homes but
  not the whole village. New worlds get the water; old saves keep their map.
- **The other settlements** (simulated off-map) suffer droughts and floods **in their numbers**: harvests fall, people can
  be lost, which changes regional trade and migration.

### 3.8 The player
Caught like anyone: burned, injured, chilled or swept away (washing up downstream and walking back), and can die; the heir
continues.

## 4. How it works (proposed architecture)

- **Weather record** (one saved section): the year's wetness, today's weather, soil moisture, river levels per reach,
  active fires and disasters. Updated in the existing hourly step; nothing runs per frame. Every draw is a seeded hash of
  world seed, day, hour and place, so the same world gives the same weather (determinism).
- **Rivers:** generated by the existing Python terrain and river tools (the reference implementation), imported as map
  data with river, bank and low-ground cells; a map version bump; old saves keep their map.
- **Building condition** (0-100, saved; absent means whole): damage from wind, fire, flood and snow; a damaged building
  works partly; a destroyed one becomes a ruin; repair and rebuilding are ordinary construction sites with real materials,
  so no coins or goods appear from nowhere (conservation).
- **Fire:** spreads cell by cell on a coarse grid (trees, fields and buildings burn; roads, water and bare ground stop it),
  stepped every few game minutes only while something burns, capped for phones.
- **Flood:** a water level per river reach; a flash flood is a fast rise into the low cells near the banks, then a fall.
- **Illness:** a small condition per person (kind, severity, days) on top of health; new causes of death through the
  existing death path.
- **Missing persons:** reuse permanent identity and the "away" state: swept away = away downstream with a return day.
- **Villager decisions:** shelter in storms, harvest early on warning, leave the banks, join bucket lines, flee fire,
  rebuild, buy firewood, through the existing brain and the Expansion 19 decision engine, with explanations recorded.
  Expansion 19 emotions: grief for the lost, fear after a flood, gratitude to helpers.
- **Visuals and sound:** screen tint, rain and snow particles, snow, mud and track overlays, snowman and sled sprites, fire
  and flood tiles; wind, rain, thunder and fire sounds. The asset pipeline searches the owned packs first.
- **Wiki:** weather and disaster pages in plain words (what happens, the warning signs, what to do).

## 5. Implementation plan (phases, each tested and committed before the next)

| Phase | Content | Done when |
|---|---|---|
| **25-A Ground** | rivers, creek, bridge, wells on the maps (map version bump); building condition, repair and rebuild; the weather record and its save section | old saves load unchanged; new worlds have water; a damaged building can be repaired with real materials; gate identical with weather off |
| **25-B Everyday weather** | seasonal odds and wet/dry years; rain, snow, wind, drought effects on crops, walking, firewood and animals; snow, mud and track visuals; snowmen and sledding; sounds | a game year shows every season's weather; crops and firewood respond; looked at on screen |
| **25-C Illness** | drought fever, chills, foul water; treatment with rest, shelter, food and medicine; deaths of the weak | targeted tests by age and condition |
| **25-D Disasters** | flash flood (with the swept away and their return), fire (spread, bucket lines, firebreaks, campfires, lightning), tornado, heavy snow on roofs, fleeing and trampling animals | each disaster in a scripted test; conservation holds through destruction and rebuilding |
| **25-E Warning and response** | readable signs; villagers' responses; relief, alms and rebuilding; choosing a safer plot; off-map settlements' numbers; Expansion 19 emotions | villagers act on warnings in tests; relief and rebuilding traced in the recorder |
| **25-F Gate** | wiki, phone performance, save migration, determinism, one bounded long run per seed | owner presented the build for release authorization |

## 6. Questions still open (with recommendations)

| Id | Question | Recommendation |
|---|---|---|
| E25-OD-03 | Wells for bucket lines away from the river | add one or two wells as public works the reeve can build |
| E25-OD-06 | May the reeve keep a disaster reserve? | yes, inside the existing reserve rule (no new money) |
| E25-OD-07 | When to build it, relative to Expansions 20-24 | after Build 19; the owner sets the order (it depends on none of 20-24; Expansion 20's prices make shortages bite harder, which helps but is not required) |
| E25-OD-08 | How long is a swept-away person missing? | 1 to 3 game days (several weeks of calendar time), by a seeded draw |
| E25-OD-09 | Can a building be insured or protected (stone vs wood)? | stone buildings resist fire and wind better; no insurance in this expansion |

Answered on 2026-10-23: rivers (river and creek), flood risk (a few on the banks), rebuilding (their choice), settlements (in
their numbers), firefighting (bucket lines), warning (signs in the sky), illness (weather illnesses), rebuilding cost
(owner with village aid), seasons (seasonal, varied years), snow (hardship), animals (trample and scatter), the player (same
as everyone), rain timing (spring and autumn rains, winter snow), severity (rare, real), the washed away (mixed fates).

## 7. Risks
- **Map change:** water changes paths and parcels and the determinism gate for new worlds; old saves keep their map.
- **Phones:** fire and particles must stay inside the frame budget (capped cells, coarse grids).
- **Balance:** disasters on an economy that can already fail; measured with bounded runs, never tuned to favourable results.
- **Saves:** new optional sections (weather, building condition, illness); old saves load with clear weather and whole
  buildings.

---

## Appendix: the owner's words (verbatim)

### Dynamic weather and disasters (with the owner's answers)


I was thinking about what else would actually help here. I think we need some dynamic weather. Thunderstorms rainstorms maybe a forest fire snow, a flash flood heavy winds really dry droughts maybe a hurricane to come. Not a hurricane. Sorry a tornado to come through and do some damage to buildings and people they need to see inclement weather a flash flow be awesome. Like a river. Just rips through the town and destroy stuff and kill. Some people washes some people away and they eventually find their way back. So I think that'd be a good expansion. 24 maybe

## Owner answers (same day, in the session)

- Number: **"Expansion 25 (Recommended)"**: Weather becomes 25; Legacy stays 24.
- Now: **"Record and design (Recommended)"**: a design specification and audit on paper, written between Build 19
  tasks; no code until the owner approves; Build 19 not delayed.
- Severity: **"Rare, real (Recommended)"**: ordinary weather every season; a serious disaster about once in several game
  years, sometimes deadly; damage real and lasting until rebuilt; no hidden rescue (WDR-022).
- Washed away: **"Mixed fates (Recommended)"**: some drown; others are carried downstream, missing for a while (family
  grieves, village searches), and walk back days later as the same person with their permanent identity and memories.

## Owner design details (same day, in the session; verbatim, spoken)

Well hit me with the questions there boss
Fires should be able to spread through towns if they come from a forest fire. That's too close campfires have the chance of starting fires if it's in a drought. When there's heavy rains, they can create a flash flood on their own. If there's already a crick or a river running through an area the banks will swell to. Maybe you know a half or twice their size and cause flooding along the banks. Animals will migrate away from fires and floods and stampede in different areas. Droughts cause obviously less production of grown goods possibly failed crops. It will also cause illness in the elderly

## Owner answers, second round (same day, in the session)

- Firefighting: **"Bucket lines (Recommended)"**: villagers and the player carry water from wells and the river to slow
  or put out a fire and can clear a firebreak; rain puts fires out; fighting fire is dangerous (smoke and burns can
  injure or kill).
- Warning: **"Signs in the sky (Recommended)"**: a few game hours of readable warning (darkening clouds, rising water,
  fleeing animals); experienced villagers act on the signs; no numeric forecast.
- Illness: **"Weather illnesses (Recommended)"**: a small illness system tied to weather only (drought fever, elderly and
  children most at risk; chills from cold, wet and snow; foul water after floods), treated with rest, shelter, food and
  the existing medicines; it can kill the weak.
- Rebuilding: **"Owner, with village aid (Recommended)"**: the owner rebuilds through the existing construction system;
  the treasury repairs public buildings and may grant relief; chapel alms and neighbours' help (Expansion 19) cover the
  poor; the homeless shelter where they can.
- Seasons: **"Seasonal, varied years (Recommended)"**: per-season odds (snow only in winter, drought mostly in summer,
  storms in spring and autumn); wetter and drier years, so droughts can last a season or more.
- Snow: **"Hardship (Recommended)"**: slower walking, no crop growth, animals need shelter and feed, homes need firewood,
  chills for the cold and wet, heavy snow can collapse a weak roof.
- Stampedes: **"Trample and scatter (Recommended)"**: fleeing herds trample crops and fences and can injure people;
  wild animals move to new grounds for a while; farm animals may break out of pens.
- Player: **"Same as everyone (Recommended)"**: the player can be burned, injured, chilled or swept away (washing up
  downstream and walking back) and can die; the heir continues.

## Owner answers, third round (same day, on docs/design/EXPANSION25_WEATHER_DESIGN.md section 4)

- E25-OD-01 Rivers: **"River and creek (Recommended)"**: a river along one side of the village and a creek crossing it,
  with a bridge on the road; made with the existing map tools; other settlements get their own streams; new worlds get
  water, old saves keep their map.
- E25-OD-02 Flood risk: **"A few on the banks (Recommended)"**: a few low houses and fields near the banks; a flood can
  take some homes but not the whole village.
- E25-OD-04 Rebuild: **"Their choice (Recommended)"**: where it stood by default; a household that lost its home to a
  flood may move to a free plot away from the banks, remembering the flood.
- E25-OD-05 Settlements: **"Yes, in their numbers (Recommended)"**: droughts and floods cut off-map harvests and can cost
  people, changing regional trade and migration.

## Owner design details, seasonal visuals (same day, in the session; verbatim, spoken)

Also, this should tie into seasons too like spring and fall. I have the heavy rains winter. I should have some snow now accumulating you know we should see his snow flurries coming down should see snow accumulate kids build snowmen. We should see kids sled riding. We should see tracks in the snow from footsteps and carts and horses and animals
When it rains a lot we should see trails and mud. The green grass should get like a muddy-ish texture to it. Should see trails from animals And other signs of inclement weather

Owner answer (same day): rain timing **"Rains spring/fall, snow winter (Recommended)"**: heavy rains and mud in spring and
autumn, snow in winter, drought risk in summer.
