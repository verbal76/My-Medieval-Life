# Build 42: eat_home starvation victim traces (Agent I, for Agent L)

These are evidence for the navigation stranding defect (Agent L, `wip/b42-nav-stranding`). They were read from the chain 12 flight campaign at code `b3c9eb593fe1`: runs 43332151718 (seeds 1, 2) and 43332156022 (seeds 3, 4), every seed 365/365 days with the recorder on. The flight-recorder archives expire around 2026-12-13, so this folder keeps what was read from them.

- Per-victim files `tr_s<seed>_<id>.md`: the last 2 days before death, hour by hour.
  - Sources: the recorder archive's event and sample tables (`fr-seedN-segK-archive`), and the segment-start world save (`fr-seedN-stateK`, days 100, 200, 300).
- Tool: `scripts/trace.py` (python3 standard library; `gcpf.py` reads Godot's compressed file, `stateworld.py` the world save inside a segment state). Usage: `python3 -I scripts/trace.py SESSION_DIR STATE_FILE p:<id> <death day> "<label>"`.

## Limits of the evidence
- The archive does not record a `go` step's target cell. The "presumed target" is the household home's door from the save (`World.building_door(home)`). The save is up to 99 days before the death. Victims born later are matched by the `household=` of their death record.
- Samples record no depth.
- Every failure is `walk_lost` / `no_path`; there is no `no_level_route`. No victim was on a journey, migration or courier trip, or at a neighbouring settlement. Every household has an existing home building with a door: none under construction, none a homestead claim member.

## Summary (13 victims; the other 34 of the 47 chain-12 starvation deaths are 23 envoy journeys and the 11 'lost' cases of the first report)
| seed | victim | died | household / home door | stranded at | how they got there | box to home door (limit 140) | failed walks (2 days) |
|---|---|---|---|---|---|---|---|
| 1 | p:1000539 | 210 | hh 1 manor, door (23,52) | (140,98) | 'spending time with Simon' (social), day 208 22:00 | 138x67, **within the limit** | 37 |
| 1 | p:1000019 | 211 | hh 6, door (26,69) | (162,122) | chapel relief to the Marsh household, day 209 20:00 | 157x74, refused | 35 |
| 1 | p:1000583 | 211 | hh 6, door (26,69) | (162,122) | 'spending time with Beatrice' (social), day 209 23:00 | 157x74, refused | 39 |
| 2 | p:1000227 | 86 | hh 2, door (40,34) | (6,161) | chapel relief to the Outlaw household, day 84 | 55x148, refused | 43 |
| 2 | p:1000004 | 155 | hh 2, door (40,34) | (6,161) | chapel relief to the Outlaw household, day 154 | 55x148, refused | 36 |
| 2 | p:1000505 | 183 | hh 2, door (40,34) | (3,160) | chapel relief to the Outlaw household, day 182 | 58x147, refused | 38 |
| 2 | p:1000583 | 246 | hh 29, door (111,21) | (3,160) | chapel relief to the Outlaw household, day 245 | 129x160, refused | 35 |
| 2 | p:1000609 | 275 | hh 16, door (6,34) | (30,176) | chapel relief to the Outlaw household, day 273 | 45x163, refused | 46 |
| 2 | p:1000058 | 294 | hh 3, door (115,56) | in village (112,50) (111,57) (85,61), then (-40,149) | in-village loop, then chapel relief | in village within limit; then 176x114, refused | 136 |
| 2 | p:1000648 | 307 | hh 14, door (103,84) | chapel (83,38), then (-42,148) | chapel pickup loop, then relief to the Brook household | 166x85, refused | 70 |
| 2 | p:1000588 | 309 | hh 27, door (114,42) | chapel (83,38), then (-40,149) | chapel pickup loop (60 tries an hour), then relief to the Brook household, day 308 | 175x128, refused | 248 |
| 4 | p:1000501 | 232 | hh 26, door (95,21) | (23,142) | 'spending time with Alan' (social), day 230 23:00 | 93x142, refused | 41 |
| 4 | p:1000807 | 323 | hh 26, door (95,21) | (20,148) | chapel relief to the Outlaw household, day 321 22:00 | 96x148, refused | 33 |

## Findings
1. Two triggers take villagers out of reach:
   - (a) chapel relief delivery to a household with no house in the village: 10 of 13. `chapel.gd _dest()` uses the first member's current cell, an outlaw or homestead household at the map edge or off the map (x<0).
   - (b) social companionship ('spending time with X'): 3 of 13.
2. For 12 of 13, the return search box exceeds `WORLD_PATH_CELLS = 140` (`village_map.gd find_path_world`), so the walk home is refused outright. The exception, seed 1 p:1000539 at (140,98), is within the limit and still `no_path`; it needs a focused reproduction (the box margin cutting off the only way round, or an enclosed cell).
3. In-village loops (seed 2 p:1000058, p:1000648, p:1000588):
   - The chapel pickup succeeds and resets `path_fails`. The walk to the off-map recipient then fails, so the villager re-plans every game minute (the MML-NPC-01 back-off bypass).
   - Once the recipient is in range they walk out and are stranded.
4. The same households lose people again and again: seed 2 household 2 lost 3; seed 4 household 26 lost 2.
5. Persists on 0bbee94: early campaign 43530227383, seed 2, the preacher Hawise Webb starved on day 13 (day 15 at b3c9eb5).
