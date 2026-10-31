# Expansion 25: Weather, Seasons and Disasters

**Current status:**
- **DESIGN ONLY, NOT AUTHORIZED.**
- Owner design answers are recorded; questions E25-OD-03, 06, 08 and 09 are open, and the packet itself is not yet
  approved.
- Priority 6.
- It forms one combined design scope, "Wild World", with Expansion 26.
- **Next authorized phase: none until the owner authorizes it.**

Status vocabulary and precedence: `docs/expansions/README.md`. Reconciled 2026-10-31 (DOC-RECON-01).

## Numbering, combined design scope and authorization (kept separate)

| Question | Answer | Owner source (dated) |
|---|---|---|
| **Expansion number** | 25 = Weather, Seasons and Disasters | 2026-10-23: number "Expansion 25 (Recommended)"; "Weather becomes 25; Legacy stays 24" (`2026-10-23_dynamic_weather_idea.md`). 2026-10-24: priority "6 \| 25 — Weather & Disasters" and order "20 → 21 → 23 → 22 → 24 → 25 → 26 → 27" (`2026-10-24_expansion_roadmap_reprioritization.md`, `2026-10-24_owner_roadmap_question_decisions.md`). |
| **Combined design scope ("Wild World")** | 25 and 26 are designed together as one concept, delivered as two numbered packets | See the steps below this table. |
| **Implementation authorization** | **None** | 2026-10-23 "Record and design (Recommended)… no code until the owner approves". 2026-10-24 "Keep Weather & Disasters and Creatures & Heroes in design-only status until specifically authorized". 2026-10-30 "Do not begin Expansions 22–27". 2026-10-31 "Expansions 22–27: Do not begin implementation without explicit authorization". Register `builds.25.implementation_authorized: false`. |

How the combined "Wild World" scope came about, all on 2026-10-23:
1. The owner answered **"Merge with weather (25)": one "Wild World" expansion: weather, disasters, monsters, pets and
   bounties together, designed as one** (`2026-10-23_monsters_bounties_companions_idea.md`).
2. The same day the owner asked: "break us into one or two packets starting at number 25. You tell me how we should break
   this up" (`2026-10-23_split_expansions_25_26.md`).
3. The agent's split into 25 and 26 was applied ("owner may change it") as companion packets. 26 "builds on" 25.
4. The owner then used both numbers by name on 2026-10-24 (priority list; ROAD-Q3 "Expansion 26, Creatures & Heroes";
   ROAD-Q4 "Expansion 25 must reuse…").
5. On 2026-10-31 the owner described the two as designed together "as the Wild World concept".

No owner decision after 2026-10-24 changes the numbers or merges the builds. The single-document "Wild World 25" existed
for one day: `docs/design/EXPANSION25_WILD_WORLD_DESIGN.md`, renamed in `c64dd52` and deleted in the split `6c28fbc`. Its
content is carried whole into the two packets; recover it with `git show 6c28fbc^:docs/design/EXPANSION25_WILD_WORLD_DESIGN.md`.

## Current approved scope

**Owner idea** (2026-10-23, verbatim in `docs/directives/2026-10-23_dynamic_weather_idea.md`; WEATHER-01): thunderstorms,
rainstorms, forest fire, snow, flash flood, heavy winds, droughts and a tornado, damaging buildings and people; floods
sweeping some people away who later find their way back.

**Owner design answers, 2026-10-23** (all recorded verbatim in that directive and in packet §3):
- severity "Rare, real";
- washed away "Mixed fates";
- firefighting "Bucket lines";
- warning "Signs in the sky";
- illness "Weather illnesses";
- rebuilding "Owner, with village aid";
- seasons "Seasonal, varied years";
- snow "Hardship";
- stampedes "Trample and scatter";
- player "Same as everyone";
- rain timing "Rains spring/fall, snow winter";
- seasonal visuals (snow accumulation, snowmen, sledding, tracks, mud);
- E25-OD-01 rivers "River and creek";
- E25-OD-02 flood risk "A few on the banks";
- E25-OD-04 rebuild "Their choice";
- E25-OD-05 settlements "Yes, in their numbers".

**Owner, 2026-10-24 (ROAD-Q4, E22-CONDITION):** "Expansion 25 must reuse that infrastructure [Expansion 22's building
condition] for weather and disaster effects. Design one extensible system rather than separate damage models."

**Specification:** `docs/design/EXPANSION25_WEATHER_SEASONS_DISASTERS.md`. It was written by the agent at the owner's
request ("documents for each expansion packet that I can download") and holds the owner's words in its appendix. Its
header reads: "design approved in parts by the owner; no code until the owner approves this packet."

## Implemented

Nothing. Checked against code on `origin/wip/expansion20` `ad281dc`:
- no weather, fire, flood, illness, building-condition or river code;
- `wiki_topics.gd:99` still tells players "There is no sickness, bleeding, falling or weather to die of".

Seasonal crop growth, wildlife breeding and the dawn firewood burn predate this expansion and are reused, not rebuilt.

## Partial

None.

## Remaining approved work (approved design, not authorized)

WEATHER-01 (NOT STARTED). The packet's phases, which are an agent plan, are not separately approved:
- **25-A:** rivers, building condition (via E22-CONDITION), weather record;
- **25-B:** everyday weather and visuals;
- **25-C:** illness;
- **25-D:** disasters;
- **25-E:** warning and response;
- **25-F:** release gate.

## Design only / not authorized

- The proposed architecture (packet §4): weather record, river data with a map version bump, fire grid, flood levels,
  illness condition, missing-person "away" state.
- The packet as a whole, which awaits owner approval.

## Deferred and superseded

| Item | Status | By |
|---|---|---|
| "So I think that'd be a good expansion. 24 maybe" (number) | SUPERSEDED | owner 2026-10-23 "Expansion 25 (Recommended)" |
| Single "Wild World" Expansion 25 document | SUPERSEDED as a document by the two packets (content kept); the combined *design scope* stands | owner request 2026-10-23 (split); owner use of 25/26, 2026-10-24 |
| The packet's own building condition (packet §4, "Building condition (0-100)") | SUPERSEDED in ownership: designed and built in 22, reused by 25 | ROAD-Q4 / E22-CONDITION, 2026-10-24 |
| E25-OD-07 (when to build it) | Answered by the order "20 → 21 → 23 → 22 → 24 → 25 → 26 → 27" (2026-10-24); implementation still unauthorized | ROAD-03 / ROAD-Q |

## Outstanding owner decisions

These questions are not registered yet; decision records are proposed. All come from packet §6:
- **E25-OD-03:** wells for bucket lines away from the river.
- **E25-OD-06:** a disaster reserve in the treasury.
- **E25-OD-08:** how long a swept-away person is missing.
- **E25-OD-09:** whether stone buildings resist fire and wind better (and whether there is insurance or protection).

Also outstanding:
- **Approval of the packet itself.**
- **Implementation authorization.**

## Dependencies

- **Needs:**
  - map water: a map version bump (old saves keep their map). Design the rivers on Expansion 22's regional map to avoid
    two map migrations (ROADMAP §3.3);
  - Expansion 22's building condition (E22-CONDITION);
  - Expansion 19 emotions and decisions;
  - permanent identity (the swept-away who return).
- **Supplies to 26:** rivers and banks, winter, building damage and repair, emergency response.

## References

- Register:
  - WEATHER-01, E22-CONDITION;
  - ROAD-Q4, ROAD-03;
  - `builds.25`.
- `docs/design/EXPANSION25_WEATHER_SEASONS_DISASTERS.md`
- `docs/design/ROADMAP_20_27_PRIORITY.md` §2, 3, 11.
- Directives:
  - `docs/directives/2026-10-23_dynamic_weather_idea.md`;
  - `2026-10-23_split_expansions_25_26.md`;
  - `2026-10-23_monsters_bounties_companions_idea.md`.
- Git history:
  - `f2688e1` (first draft, `EXPANSION25_WEATHER_DESIGN.md`);
  - `01ad333` (rivers, flood answers);
  - `27894a6` (visuals);
  - `c64dd52` (Wild World merge);
  - `6c28fbc` (split).

## Missing sources

**The original owner-supplied "Weather, Seasons & Disasters" design packet: MISSING SOURCE, requiring recovery.**

The owner states that comprehensive packets were developed outside the repository and supplied to sessions. A search of
every branch (`git log --all --diff-filter=A`, `wip/roadmap-docs`) finds no owner-authored or externally developed weather
packet (no docx, pdf or md). What exists:
- the agent-written packet above, holding the owner's answers verbatim;
- its two deleted predecessors, recoverable from history.

If a fuller original exists, its features are **not** unapproved because the file is absent. Recover it and compare.
Nothing is reconstructed here. See `docs/expansions/MISSING_SOURCES.md`.
