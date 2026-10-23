# Expansion 25: Wild World — weather, disasters, monsters, pets and bounties: design specification and audit (draft, 2026-10-23)

Register WEATHER-01, MON-01, PET-01 (with B14-09 skeletons and FR-01 lizards and spiders), Build 25 (design only; **no code until the owner approves this document**). Owner idea, details and
answers verbatim in `docs/directives/2026-10-23_dynamic_weather_idea.md`. Facts below come from a read-only audit of the
released Build 18 code (`origin/wip/build18`, paths relative to `game/`). Build 19 stays the priority; nothing here
delays it. Founding principle WDR-022: a village may fail, the simulation may not; disasters are real outcomes, never
secretly undone.

## 1. What exists today (audit)

| Area | Fact | Where |
|---|---|---|
| Calendar | 8-day year, four 2-day seasons; a game day is 12 real minutes | `data/balance.json` calendar; `life.gd` `season()` |
| Seasonal effects | crop growth by season (winter 0), sowing spring-autumn, wild plants and fruit trees bear in season, wildlife breeds in season, feasts, summer cicadas | `balance.json:672-673,136,146`; `farming.gd`, `trees.gd`, `refuges.gd` |
| Weather, fire, flood, drought | **none**; the wiki says "no weather to die of" | `wiki_topics.gd:97`, `wiki.gd:735` |
| Water on the maps | **none**: no river, pond, bank or bridge tile on the village map or the overworld | `data/village.json`, `overworld.gd`, `routes.gd` |
| Buildings | dicts with a rectangle and door; construction sites with materials; **no condition, damage, repair or destruction** | `world.gd:39,2670-2739,2824` |
| Crops and trees | crops grow hourly; the only crop loss is ploughing under for a building; trees die only to an axe and regrow from stumps | `farming.gd:243`, `trees.gd` |
| People | hp 30; heal by rest or medicine; death through `World.kill(cause)`; a mine cave-in is the one hazard (seeded survival, trapped survivors) | `npc.gd`, `world.gd:2184`, `mine_works.gd` |
| Away and return | `npc.away` used by migration; permanent identity (Build 19 foundation) keeps a returning person the same | `migration.gd`, identity foundation |
| Firewood | each household burns a log at dawn; without one it is "cold" but nothing happens | `world.gd:459-468` |
| Relief | chapel alms and relief on request; the reeve's relief and public works paid from the treasury | `chapel.gd`, `npc_brain.gd:3062,3092` |
| Visuals and sound | no day/night tint or particles; a screen CanvasLayer exists; ambience has two layers and a `wind` loop already | `main.gd`, `audio.gd`, `data/music.json` |
| Saves | version 19 (20 with identity); optional sections added without a version bump | `world.gd` `to_dict`/`load_dict` |
| Ticks | hourly `_on_hour` and dawn `_new_day`; seeded hashes used for hazards | `world.gd:293-404` |

**The largest gap:** there is no water anywhere. River floods, bucket lines from the river and swelling banks need rivers
and creeks on the maps first (section 4).

## 2. Approved design (owner, 2026-10-23)

**Weather follows the seasons, with varied years.** Each season has its own odds: snow only in winter, drought mostly in
summer, storms in spring and autumn. Each year is drawn wetter or drier, so a drought can last a season or more.

| Weather | Effects |
|---|---|
| Rain | crops watered; outdoor work slower; rivers rise |
| Heavy rain, rainstorm | can cause a flash flood on its own; creeks and rivers swell to one and a half to twice their width and flood their banks |
| Thunderstorm | lightning can start a fire (rarely, more in a dry season) |
| Heavy wind | damages weak roofs and fences, fans fires |
| Tornado | rare; a path of damage to buildings, crops, animals and people |
| Snow and cold | hardship: slower walking, no crop growth, animals need shelter and feed, homes need firewood, chills for the cold and wet, heavy snow can collapse a weak roof |
| Drought | lower yields and failed crops; drought fever (elderly and children most at risk); campfires can start fires; forest fires more likely |

**Seasons and what you see (owner, 2026-10-23):** heavy rains and mud in spring and autumn, snow in winter, drought risk in
summer. Snow flurries fall and snow builds up on the ground and roofs; children build snowmen and go sledding; footprints,
cart ruts, hoof and paw tracks show in the snow. After heavy rain grass turns muddy, paths become muddy trails, animals
leave trails, and other signs of bad weather show. (Visual work for the asset pipeline: snow, mud and track overlays,
snowman and sled sprites, from the owned packs first.)

**Disasters are rare but real:** a serious disaster about once in several game years, sometimes deadly; damage stays until
rebuilt; no hidden rescue.

**Fire spreads** from a forest fire into a town that is too close. **Firefighting** by bucket lines (villagers and the
player carry water from wells and the river) and firebreaks; rain puts fires out; smoke and burns can injure or kill.

**Flash flood** rips through low ground and along banks, destroying buildings, crops and goods; some people drown, others
are carried downstream, missing for a while (family grieves, village searches), and walk back days later as the same
person with their identity and memories.

**Warning:** a few game hours of readable signs (darkening clouds, rising water, fleeing animals); experienced villagers act
on them (bring in the harvest, move away from the banks). No numeric forecast.

**Animals** flee fires and floods: herds trample crops and fences and can injure people; wild animals move to new grounds
for a while; farm animals may break out of pens.

**Illness (weather only):** drought fever, chills from cold, wet and snow, foul water after floods; treated with rest,
shelter, food and the existing medicines; it can kill the weak.

**Rebuilding:** the owner rebuilds through the existing construction system; the treasury repairs public buildings and may
grant relief; chapel alms and neighbours' help (Expansion 19 relationships) cover the poor; the homeless shelter where they
can.

**The player** is caught like anyone: burned, injured, chilled or swept away (washing up downstream, walking back), and
can die; the heir continues.

## 2b. Monsters, pets and bounties (owner, 2026-10-23; merged into this expansion by the owner)

Verbatim sources: `docs/directives/2026-10-23_animal_domestication_idea.md`, `docs/directives/2026-10-23_monsters_bounties_companions_idea.md`.

**Pets and companions (PET-01).** With an animal's liked food in hand the player gets an action to try taming a fox, wolf
or rabbit; a few feedings tame it (rabbits easiest, wolves hardest; about three unskilled, one or two with husbandry, a
master tames a rabbit at once but a wolf takes at least two); an animal already tried shows a marker. A tame animal
follows, waits at home when told and must be fed or slowly turns wild. A fox or wolf can be the player's companion: it
follows on missions, defends the player against animals and bandits, hunts for them, and can be hurt or killed. A tame
animal follows the player into their pen, where a prompt makes it stay; young born in the pen are tame. Penned rabbits
give meat and pelts; pen-bred wolves grow into guard dogs that bark at bandits near home; tame young can be sold to
villagers; foxes are pets (agent reading of the answers, to confirm). Villagers notice and react (Expansion 19), and
villagers with husbandry tame pets too.

**Monsters (MON-01, B14-09, FR-01).** Skeletons underground and in uncleared woods; spiders in the caves; bosses: a giant
crab by the new river, Buwaya (the crocodile-like "lizard") in the marshes and on the banks, a minotaur in the hills, a
yeti that comes down in winter, a necromancer in the caves raising skeletons, and dragons as the rarest and deadliest. Art:
`Skeletons_Free_Pack.zip`, `MiniWorldSprites.zip` Monsters, `PUNY_MYTH-CREATURES-RPGMAKER_v1.zip`, `PunyMonsters.zip`
(all in the repository, unused until now).

**Village defence.** Rarely, a monster attacks the village: guards go first, then able adults form a line with what they
hold, each deciding by courage, family duty and personality; the family-protection rule keeps parents between the danger
and their children; elders and children shelter indoors.

**Bounties and rewards.** The reeve posts bounties paid from the treasury, claimed with proof (a pelt, a claw); defending
the town or killing a boss makes the player a hero (admiration, trust, stories through Expansion 19 gossip); monsters give
rare goods only they provide (for example crab shell, Buwaya hide, yeti fur, bone dust) sold to craftsmen for special
armour, tools and medicine; brave villagers can take up monster hunting as a trade and compete for bounties. All of it
moves villagers' emotions, their view of the player and their sense of safety (Expansion 19 judgment and personality).

**Open for the design pass (agent proposals to bring to the owner):** monster spawning and respawn (B14-09 approved 3-day
respawn for skeletons, guarding by day and roaming at night), boss rarity and whether a boss returns after it is killed,
how weather and monsters interact (the yeti in snow, Buwaya after floods), bounty prices and who funds them when the
treasury is empty, the special goods' recipes, and the companion's combat numbers.

## 3. Proposed architecture (for approval)

- **One weather record** in the world (saved as an optional section): the year's wetness, today's weather per region, soil
  moisture, active fires (cells), water levels per river reach, active disasters. Updated hourly in `_on_hour`; no
  per-frame simulation. Every draw is a seeded hash of (world seed, day, hour, place), like the mine cave-in.
- **Building condition** added to buildings (0-100, saved; absent = whole): damage from wind, fire, flood, snow; a damaged
  building works partly, a destroyed one becomes a ruin parcel; repair and rebuild are construction sites with materials
  (existing `start_site`/`deliver`), so no coins or materials appear from nowhere.
- **Fire** as a cellular spread on a coarse grid (trees, fields, buildings burn; roads, water and bare ground stop it),
  stepped every few game minutes only while a fire is burning, capped in cells per step for phones.
- **Flood** as a water level per river reach plus low-ground cells computed once from the map; a flash flood is a fast
  rise along the reach and into low cells, then a fall.
- **Illness** as a small per-person condition (kind, severity, days) on top of hp, treated by rest, shelter, food and the
  existing medicines; a new death cause per illness through `World.kill`.
- **Missing persons** reuse permanent identity and the `away` state: swept away = away downstream with a return day; the
  household and friends react through Expansion 19 (grief, search), and the same person returns.
- **NPC decisions**: shelter in storms, harvest early on warning, leave the banks, join bucket lines, flee fire, rebuild,
  buy firewood, through the existing brain (and the Expansion 19 decision engine when on), with explanations recorded.
- **Visuals and sound**: a screen tint and rain/snow particles on the existing CanvasLayer, fire and flood tiles, wet and
  snowy ground variants; the `wind` loop plus rain, thunder and fire sounds (the asset pipeline finds them in the owned
  packs before anything new is needed).
- **Wiki**: a Weather page and disaster pages (what happens, warnings, what to do), WIKI-01.

## 4. Questions for the owner before implementation

**Answered 2026-10-23:** E25-OD-01, 02, 04 and 05 as recommended (`docs/directives/2026-10-23_dynamic_weather_idea.md`, third
round). Still open: E25-OD-03 (wells), E25-OD-06 (disaster reserve), E25-OD-07 (order), and approval of this design.

| Id | Question | Recommendation |
|---|---|---|
| E25-OD-01 | Rivers and creeks: the maps have no water. Add a river and creeks to the village map and the overworld? | **Yes**: one river along one side of the village and a creek crossing it, with a bridge on the road; generated by the existing Python terrain and river tooling and imported; settlements on the overworld get their own streams. Needs a map version bump (old saves keep their map; new worlds get water). |
| E25-OD-02 | Where does the river run relative to the houses? | Close enough that a flood can reach a few low houses and fields (a real risk), not through the middle of the village; some households live on the banks by choice (cheaper land, water at hand). |
| E25-OD-03 | Wells: needed for bucket lines away from the river. | Use the existing village well and add one or two more as public works the reeve can build. |
| E25-OD-04 | Can villagers rebuild on a safer spot, or must they rebuild where it stood? | Rebuild where it stood by default; a household that lost a home to a flood may choose a free parcel away from the banks (Expansion 19 memory of the flood). |
| E25-OD-05 | Does weather also reach the other settlements (off-map)? | Yes, abstractly: their harvests and populations suffer droughts and floods in their numbers, which moves regional trade and migration. |
| E25-OD-06 | Insurance-like help: may the reeve keep a disaster reserve in the treasury? | Yes, as part of the existing reserve rule (no new money). |
| E25-OD-07 | Order relative to other expansions | After Build 19; designed now; implementation authorized by the owner when wanted (Expansion 20 economy makes prices react to shortages, so after 20 is ideal but not required). |

## 5. Risks

- **Map change:** adding water changes paths, parcels and the determinism gate for new worlds; old saves must keep their
  map (CLAUDE.md section 6-7).
- **Phones:** fire spread and particles must stay inside the frame budget; capped cells and coarse grids.
- **Balance:** disasters on top of an economy already able to fail; measured with bounded runs, never tuned to favourable
  statistics (WDR-022).
- **Save format:** new optional sections (weather, building condition, illness); old saves load with clear weather and
  whole buildings.
