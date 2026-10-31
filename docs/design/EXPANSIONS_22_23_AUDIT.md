> STATUS (2026-10-31, DOC-RECON-01): CURRENT-STATUS-ELSEWHERE. The audit (E22-P1, E23-BANA) awaits the owner's review and stays valid as a record of Build 18; parts of section 4 are stale (GP-CRIME-PURSUIT, DVW-B2 fines and X20-BANDIT-AI have since been integrated on the Expansion 20 line). No implementation is authorized (owner 2026-10-23, 2026-10-30). Current status: docs/expansions/EXPANSION_22.md and EXPANSION_23.md.

# Expansion 22 (Settlement Advancement Phase 2) and Expansion 23 (Bandit Factions): audit (2026-10-23)

Owner directive and renumbering answer: `docs/directives/2026-10-23_expansions_22_23_kickoff.md` (register E22-P1, E23-BANA,
E22-OD-01, E22-OD-02, OD-30). Specification: `docs/directives/My_Medieval_Life_Settlement_Advancement_Regional_Economy_Expansion.txt`
(the PDF beside it is authoritative). Code read: the released Build 18 code (`wip/expansion20-preparation` 4d9bc05, Build 18 plus the
switched-off Expansion 20 foundation). Read-only; nothing run; no implementation (the owner: "Do not begin implementation until we
review the audit and approve the architecture"). FACT unless marked PROPOSAL.

## 1. What Build 18 already delivers (do not rebuild)

| Specification capability | State | Where (Build 18) | What is missing |
|---|---|---|---|
| Settlement capability from real conditions (workers, skills, tools, stock, structures, transport, records) | **Complete for the village** | `settlement/industries.gd` (`evaluate`, `levels`, `holds`; a level drops as soon as a need fails), `facts.gd`, `data/settlement_industries.json`, `profile.gd:update` at dawn, saved `x18_settlements` | off-map settlements carry a static `industries` list, no derived profile |
| Worker experience and its loss | **Complete** | `experience.gd` (8 work hours = 1 experience day, per-industry cap, 0-10 level, leaves with the person, X18-D9), saved `x18_experience`; tools and buildings cap it (X18-D2) | teaching, apprenticeship, records (knowledge transfer) |
| Capability affecting output and pay | **Built, neutral** | `CapabilityHook` on (`world.gd:130`), factors 1.0 by the owner (Q18-11 PROVISIONAL) | the owner's factors; gating does not act yet |
| Specialization | **Partial** | `industries.gd:specialization`, `leader`; off-map businesses open on persistent unmet demand and close without workers (`offmap.gd:_develop`, `_open_trade`, `_close_idle`) | settlement-level comparison over time; no tiers (correct by the spec) |
| Abstract settlements with conserved state | **Complete** | `offmap.gd` (households with members, purses, pantries; businesses with tills, stock, workers, real recipes, finite quarry; treasury and officials; tax, wages, floating prices; births, marriages, deaths, heirs); conservation by `flows` and `audit()` per settlement and `regions.gd:audit` across them; no RNG after creation | dwellings and infrastructure; abandonment of a whole settlement |
| Abstract to full simulation transitions | **Absent** | none (SET-E deferred, Q18-8) | the whole of E22-OD-01's promote and demote |
| Migration | **Complete** | `migration.gd:visit` (hunger, work, land, marriage, both ways; carries age, skills, purse, goods) | migration between the five settlements themselves (only village to and from them) |
| Housing and infrastructure growth off-map | **Absent** | `landless` flag only; no population cap by the owner's REG-DEMO-D1 ("as those systems become available") | off-map dwellings, roads, warehouses |
| Decline and disappearance | **Partial** | starvation, member loss, household dissolution, business closure | settlement abandonment (no rule) |
| Trade routes, distance, capacity, cost, interruption | **Partial** | `regions.gd:road_trade` (every 6 days, instant, capped by `rules.carry`), `cadence` by miles; couriers live (`couriers.gd`, journey days from miles, fees, interruption with cargo dropped as loot); `regional.gd` and `routes.gd` (Dijkstra paths, terrain, cart capacity, carter fees) are prospective stand-ins used only for courier route tables | travel time and losses for traders' own trade; disruption by bandits or weather; carts in regional trade |
| Retiring the 30-coin caravan allowance | **Complete** | gone in Build 18 (CARAVAN-TMP superseded by ECON-P1.3; owner "the daily allowance goes away"); old `caravan_purse` saves become traders' tills at load | none |
| Geography | **Partial** | `settlements.json`: miles and one `x` offset each; `tiles_per_mile` 12; the village map and the overworld generator (`overworld.gd`) | 2D coordinates, inter-settlement distances, continuous world (E22-OD-02) |
| Player views | **Partial** | wiki pages (neighbouring settlements, caravan, couriers), the courier window | settlement panel, map, trends, shortages, routes |
| Developer diagnostics | **Complete** | `regions_sim.gd` (`--report`, `--profile`, FATAL on audit), `report.gd`, ten settlement test suites | settlement change history records for the explanation layer (XEXPL-01) |
| Long-run evidence | **Missing** | SET-C C8 and SET-D-MULTIGEN not run (multi-seed, multi-generation) | runs on the final code |

## 2. Phases A-E against Build 18

| Phase | Already there | To build (when authorized) | Depends on |
|---|---|---|---|
| A Architecture and regional ledger | one World truth for the village; per-settlement books with `flows` and `audit`; `report.gd:parties` | a single regional ledger view over village and settlements (read-only, no second ledger) | E20 event record and actor resolver (built, off) |
| B Capability model | `industries.gd`, `experience.gd`, `CapabilityHook` | derived profiles for off-map settlements from their workers and businesses; knowledge transfer (teaching, records) | Q18-11 factors; owner decision on knowledge persistence |
| C Abstract settlements | `offmap.gd` complete | promote and demote (E22-OD-01): a distant settlement's people keep identities, households, property, state and history when the player approaches | E22-OD-01 detail, stable person ids across both representations |
| D Development | births, marriage, migration, business open and close | dwellings and construction off-map, infrastructure, abandonment | E20 (construction purchasing), REG-DEMO-D1 |
| E Regional networks | road trade, couriers, route stand-ins | travel time, capacity, losses, interruption, competition between traders on real routes, carts | E22-OD-02 geography, E23 (route banditry), E21 (tolls, jurisdiction) |

## 3. Proposed regional data model (PROPOSAL, for the architecture review)

Extend, do not replace (the owner: "extend the existing regional simulation, not replace it unnecessarily"):

1. **One person identity across both representations.** Off-map members today are entries in an off-map household with age, sex
   and partner but no `npc:<id>`. Give every off-map person a region-wide person id from the same id space as `World.npcs`
   (reserved ranges or a shared counter), so a person keeps identity, family links, experience and history when a settlement is
   promoted to full simulation or demoted back (E22-OD-01). Migration already carries a person across; it would carry the id.
2. **Settlement state stays in `OffMapSettlement`** (abstract) or in `World` (full), never both: promotion moves households, purses,
   stock and property into World records and empties the abstract books through `flows` (so `audit()` proves nothing was created
   or lost); demotion is the reverse. Deterministic: promotion is a pure function of the saved state.
3. **Geography (E22-OD-02).** Replace `miles` and `x` with world coordinates per settlement in a continuous map split into regions
   (chunks) streamed around the player; the village becomes one region. `routes.gd`'s grid paths already compute terrain-weighted
   routes and can work on the streamed map. Player and NPC changes to a region persist in the region's saved state.
4. **Capability for every settlement** from its own people (experience records) and businesses (tools, structures), with the same
   `industries.gd` rules, so a small mining hamlet can out-rank a town (the directive's example).
5. **Trade on routes**: the five traders' `road_trade` and the caravan become trips with travel time and capacity on route paths,
   still paid from their own tills (no allowance), so a cut route stops trade without inventing goods.
6. **Records for explanation** (XEXPL-01): settlement changes (business opened or closed, people arrived or left, shortages) as
   events in the shared record, read by the player views (filtered by what the player knows) and by developer diagnostics.

Performance: abstract settlements step once a day each (now one per game hour 06:00-10:00); population growth has no ceiling
(735 people a year in a settlements-only run), so step cost grows; a continuous world multiplies settlements. Budgets wait on
OD-LE-15.

## 4. Expansion 23: BAN-A audit

Roadmap (the only source naming the phases): `docs/directives/2026-10-21_master_expansion_roadmap.md` lines 178-200 (written when
bandits were numbered 22): BAN-A audit; BAN-B faction identity, membership, hierarchy, safehouse ownership, persistent resources;
BAN-C career actions, recruitment, theft and raids, resale, suspicion and response; BAN-D rank, challenge, leadership, schism,
succession; BAN-E economy, judgment and politics integration and long runs. Acceptance: no invented loot or currency, stolen items
keep provenance and custody; factions can fail and disband; guards act only on knowable crimes; child dependents gain no adult
combat abilities.

| Rule 016 capability | Today | Owner of the state |
|---|---|---|
| Bandits as NPCs with real food and money | **Partial**: bandit NPCs (`role == "bandit"`), camp from map data; poach, market trips (`_bandit_market`), eat from packs and game (`band_eat`) | NPC records; no faction record |
| Robbery and theft | **Partial**: villagers robbed away from guards (`_prey_for`, half their coins and one item), alarm, retreat | NPC brain |
| Stolen goods, custody | **Partial**: loot recovered by guards to the treasury; the player's stolen goods marked | `World.loot`, player marks |
| Factions, membership, ranks, leadership, hideouts, loot division | **Absent** | none (BAN-B needs a new owner and save key) |
| Recruitment | **Partial**: orphans with no kin join the clan (FAM-07), adults may leave or stay at coming of age | guardianship |
| Faction continuity | **Partial**: outlaws return a season after the last bandit dies (`outlaws.gd`, own seeded stream, purses from outside) | `World.outlaw_gone_day` |
| Burglary, livestock theft, smuggling, raids, fencing | **Absent** | |
| Player criminal career, joining | **Absent** (player assault and theft exist, no fines for assault or killing: DVW-B2) | |
| Guard investigation, bounties, patrols against bandits | **Absent** beyond fighting seen bandits and recovering loot | |
| Criminal reputation apart from social judgment and legal status | **Absent**: notoriety counts the player's crimes; Expansion 19 judges deeds; legal status has no record | |

Proposed architecture (PROPOSAL): a faction record (members by `npc:<id>`, leader, hideout as owned property, a faction purse and
store in the World holders so conservation covers them), crimes as Expansion 20 events with provenance (stolen goods keep their
owner of record, custody moves), criminal reputation as a per-group value (bandits, villagers, guards) separate from Expansion 19's
moral judgment and Expansion 21's legal record. Bandit behaviour uses the shared `w.rng`: any change shifts the random stream (gate).

## 5. Integration and performance risks

1. Promotion and demotion is the hardest new piece: identity, property and conservation across two representations.
2. Unbounded off-map growth (no housing yet) and a continuous world multiply step cost; no budget is set (OD-LE-15).
3. `regional.gd` and `routes.gd` are stand-ins: their outputs must be re-validated before the live trade relies on them.
4. Coins flow one way into Garton (REG-CIRC-D1, deferred).
5. Capability factors at 1.0: the "no advanced work without people, tools and buildings" criterion is measured, not enforced.
6. Bandit changes move the shared random stream; every faction change needs a gate re-baseline with the owner's knowledge.
7. Stale documents: CLOSEOUT B5/B8 and the "prospective, not enabled" headers in `experience.gd` and `capability_hook.gd`
   contradict the live hook (fix in the next Build 18 maintenance, not here).

## 6. Recommended next assignment (after the owner's review)

The architecture for E22-OD-01 (one person id space and the promote/demote contract, with conservation and determinism tests
designed first) and E22-OD-02 (world coordinates and region streaming over the existing map), as a design document with
interfaces; then, on approval, the first isolated foundation: region-wide person ids and settlement coordinates behind a switch.
Expansion 23 stays at BAN-A until the faction decisions are answered.
