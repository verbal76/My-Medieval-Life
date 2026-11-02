# Business founding, business hiring and permanent employment (Build 25)

Records: B25-BUSINESS-IMPL (owner B25-BUSINESS-D2), the business-hiring part of B25-EMPLOY-D3, EMP-PERM-01 (owner
B18-DP-01). Sources: `docs/directives/2026-11-01_career_business_employment_final_decisions.md` (Decision 2, sections 5
and 6), Decision 1 of `docs/directives/2026-11-01_nine_owner_decisions_consolidated.md` (organic skills, no credentials),
`docs/release/economic_maturation/CAREER_PROGRESSION.md` (F-1, OD-LE-04 gaps). Branch `wip/b25-business`.

Principles kept: WDR-022 (a business may fail; no rescue), conservation (no coin, material or good is created: every
coin moves purse to purse, every good through `World.transfer`, building through `World.start_site`/`deliver`), X18-D3
(no level promotes anyone), DCR-01 (classification in `docs/DECISIONS.md`), saves (optional additive keys only).

## 1. What a villager business is

A villager business ("venture") is a **workshop module of the founder's trade built on the founder's household's own
property** through the existing construction rules, plus a small record of who runs it. Nothing else is invented:

- **Premises:** the workshop building (`World.buildings`, type `workshop`, owned by `hh:<n>`) and its stations
  (`World._workshop_stations`, owner the household). Built by `Construction.place(kind, rect, hh_ref, false, house)` beside
  the household's house (`find_module_slot`, `module_refusal`: a property it holds, nothing else being built there, no room
  of that kind yet) or, when there is no legal ground beside it, as a workshop on ground of its own near the house
  (`Construction.find_ground`; the owner's "a house first" rule holds: the household has a home; owner 2026-11-02, B25-BIZ-TENANT-Q Option B: an owned home allows a workshop beside it, an owned or rented home a standalone one on bought ground), the ground bought
  from the manor on the spot (`Property.claim`), the materials delivered by the
  household and its hired helpers (`_keep_building`, `hh.build`), exactly as households already build quarters and rooms.
- **Trade to workshop kind:** smith `smithy` (forge, anvil), carpenter `carpentry` (workbench, sawhorse), tanner
  `carpentry` (its workbench), cook `bakehouse` (oven, stove). Tavernkeepers have the tavern; merchants already found
  outlets through stalls and household storefronts (`build_npc_front`, ECON-P3 tills), so they found no workshop here.
- **Record:** `household.venture` while it is being set up, then `building.venture` on the workshop
  `{founder, keeper, trade, day, opened, idle_days, hands: [npc ids]}` (saved with the household and the building; older
  saves have neither: no business).
- **Money:** the business's money is its household's (purses), as for every villager trade today. ECON-P3 tills remain
  for storefronts and counters; a workshop business does not get a till of its own (see open question Q1). Its goods are
  made and sold by its workers through the existing crafting and trade paths (`World.work_craft`, `NPCBrain` selling), so
  it has **no guaranteed customers and no artificial stock**.

## 2. How a villager decides to found one

Once a week, on each villager's own seeded morning (`hash(seed, npc id, 7411) % look_days`), at dawn after the labour
market (`Ventures.daily`), an adult villager is **considered** only when every condition the game can see holds:

1. **Ability and experience:** in a founding trade (above), level at least `min_level` in the trade's own skill
   (`NPCBrain._trade_skill`, the corrected B25 mapping) and at least `min_trade_days` working days in its industry
   (`WorkExperience`). These make one eligible, never founders (X18-D3; no credentials, nine-decisions D1).
2. **Premises:** their household owns (not leases) the house it lives in, there is legal ground beside it
   (`find_module_slot` + `can_place`) or near it (`find_ground`), and the household is building nothing (`hh.build` empty) and has
   no housing goal (a crowded or homeless household puts its home first).
3. **Capital and household finances:** the household's purse, less what it keeps for its people (`Construction._keep`) and
   its workers' missing tools (`_tool_reserve`), covers the start (`_start_of`: the ground and `found_start_share` of the
   materials it does not already hold, at today's prices) plus `working_days` days of its daily costs
   (`evaluate_household` cost) as working capital. The rest of the materials is bought as it earns, as for a house.
4. **Demand and competition (economic opportunity):** the trade's own labour-market reading (`NPCBrain.skilled_place`,
   B25-EMPLOY-IMPL) says there is **work** (its workers spent at least `busy_share` of a working day at its stations)
   and **no room** (the stations open to the trade, now including other ventures' stations that are taking hands, have
   no free time for another worker). A trade with spare bench time, including a rival's new workshop, offers no opening.
   No other venture of the same trade is being set up.
5. **Not already:** the villager runs no venture and no household member is founding one.

The considered villager then **decides** through the shared weighing (`JudgmentWeighting.choose`, new profile
`business_found` in `judgment.json`, a yes-or-forgo choice like `proposal_accept`): factors `ambition` (their effective
profession priority, `JudgmentAspiration.eff_priority`, the career-ambition reading of B25-AMBITION-IMPL), `skill`
(`skill_fit`), `capital` (how far the spare purse exceeds the need) and `demand` (how far the trade's work exceeds the
busy share), against the profile's `forgo`. Not every eligible villager founds; a content one does not. With the judgment
layer off (`JudgmentLive.on(w, "business_found")` false) nobody founds (conservative: motivation cannot be read).

On founding: `Construction.place` marks out the site (ground paid from the household purse by the land office);
`hh.build` is the site, `hh.venture` the record; the household builds by `_keep_building` (helpers or the founder,
materials bought with its own coins). Family help (`_family_help`) is for homes only and is not given to a venture.
Stats `ventures_considered`, `ventures_founded`, `ventures_founded_<trade>`. Diagnostics only (B25 economic investigation, `docs/expansion20/ECONOMIC_INVESTIGATION_2026-11-02.md`): `venture_looks`, `venture_refused_<stage>` (the stage `refusal` stopped at, `Ventures.last_refusal`), `venture_option_<kind>`, `ventures_declined`, `ventures_found_failed`; nothing decides by them.

## 3. Opening, working and hiring

When the site is finished (`World._finish_site`), the workshop stands with its stations owned by the household
(`set_owner` keeps stations with the building). `Ventures.daily` opens the venture: `building.venture` is written, the
founder's workplace becomes the workshop's first station of their trade (buyers find them there, `_workplace_cell`), and
`NPCBrain._station_for` tries a worker's own venture stations first (only for a venture's founder or hands; everyone else
unchanged). Stat `ventures_opened`.

**Hiring (B25-EMPLOY-D3, "a successful business may expand its workforce"):** a venture's stations count as room for its
trade in `skilled_place` (as a manor station does) while the venture is open; when the place offered is a venture's
station, the trade's applicants are chosen by `_hire_skilled` (most suitable first: skill, then experience, then need),
the keeper's leave is given (`World.permit(workshop, npc ref, true)`, the existing workshop permission) and the hand's
workplace is that station. A hand works under the existing skilled model: their own materials and tools, their own sales
and earnings (no wage; Q2). A venture adds room only while it has free station time, so it hires only when it is busy and
its trade's earnings afford one more (the skilled_place `afford` and `work` conditions). Stat `venture_hires`.

## 4. Struggle, change of hands and closing

Each dawn an open venture is checked (`Ventures.daily`):

- **Change of hands:** when the keeper dies, leaves the trade or the household, an adult of the same household in the same
  trade becomes keeper (the business stays with the household that owns the building). Stat `venture_handovers`.
- **Closing:** with no such keeper, or after `close_idle_days` days in a row with no work recorded at its stations
  (`World.station_load`, the B25-EMPLOY-IMPL record: no materials, no orders, nobody working), the venture closes: the
  record leaves the building, its hands lose the keeper's leave (`permit(..., false)`) and their workplace goes back to a
  station they may use. Nobody is paid anything and nothing is taken: **the workshop and its stations stay the household's
  property** under the existing ownership rules (it may be sold to the manor by `Property.sell`, inherited, or escheat to
  the manor when the household ends, `Property.household_ended`), and may become a venture again later. Stats
  `ventures_closed`, `ventures_closed_idle`, `ventures_closed_keeper`.
- **Household ended:** the existing `Property.household_ended` passes the building on; a venture whose owner is no longer
  the founding household closes the next dawn.
- **Setting up fails:** a site never finished stays the household's building goal under the housing rules (a household
  that becomes crowded keeps building it first); the venture record stays "setting up". Q3.

## 5. Permanent employment by the player (EMP-PERM-01)

`Employment` (`game/scripts/core/employment.gd`, `World.employment`, saved under the optional key `"employment"`): the
player (host or guest, `World.acting_ref`) employs a villager in a **lasting production role at a workplace the employer
owns**, distinct from a day's building helper (`Construction.hire`), a counter attendant (`Business.hire`) and a contract
(CON-01/02).

- **Role:** `miner`: the employee mines the village's seams they may work (`World.nearest_seam`, `_can_mine`: gold needs
  Mining 3) with their own pickaxe (bought with their own coins when they have none, `_get_tool`), by the one swing rule
  (`World.work_mine`, Mining xp and tool wear). What they mine for the employer is recorded as `owed` and carried, a load
  (`carry_ore`) at a time and at the end of the working day, to the employer's store (`Construction.store_of`: the player's
  family chest at home) by `World.transfer`. The ore is the employer's: the employee does not sell it.
- **Who:** an adult with no trade of their own (`Construction.HIRABLE`) or a miner, not minding a counter, not hired for
  building that day, not already employed, willing (`JudgmentLive.work_refusal`, as attendants). Their job becomes
  `miner` (`NPCBrain._change_job`, the job-change record), so the labour market counts them as a miner; the morning
  labour market does not move an employee.
- **Wage and terms:** `employment.wage` coins a day, the first day paid on hiring, then each dawn, from the employer's
  purse (`PlayerState.coins`) to the employee (`earned`, `income_days`): coins move, none is made. An unpaid wage ends the
  employment ("the wage could not be paid"). Hours: the working day (`WORK_START`..`WORK_END`). Termination: the employer
  dismisses (`Employment.dismiss`), the wage fails, the employee dies, or the employer's home store is gone. The employee
  keeps their wages and their own tools; goods already delivered are the employer's.
- **Verbs:** `employment.employ(n, role)` and `employment.dismiss(n)`, through `World.mirror` and
  `NetActions.VERBS` (host validation, C3) like the business verbs; the villager's talk menu offers them.
- **Requires:** the employer has a home with its chest (`store_of` not null) and can pay the first wage.

## 6. Provisional numbers (agent proposals, `balance.json` `ventures` and `employment`)

| Key | Value | Meaning |
|---|---|---|
| `ventures.look_days` | 7 | a villager considers founding once a week on their own seeded morning |
| `ventures.min_level` | 4 | level in the trade's own skill to be considered |
| `ventures.min_trade_days` | 20 | recorded working days in the trade's industry |
| `ventures.working_days` | 10 | days of household costs kept as working capital beyond the start |
| `ventures.close_idle_days` | 14 | days in a row with no work at its stations before a venture closes |
| `ventures.kinds` | smith smithy, carpenter carpentry, tanner carpentry, cook bakehouse | the workshop each trade founds |
| `judgment.json decision.profiles.business_found` | weights ambition 350, demand 250, capital 200, skill 200; forgo 45000 | the founding decision |
| `employment.wage` | 10 | a permanent employee's daily wage (attendant 8, the manor's day wage) |

## 7. Implementation (Build 25, branch `wip/b25-business`)

- `game/scripts/core/ventures.gd` (`Ventures`, `World.ventures`): `daily`, `_consider`, `refusal`/`eligible`, `decides`,
  `found`, `_open_finished`, `_check`, `close`, `took_place`, `hiring_station`, `stations_for`.
- `game/scripts/core/employment.gd` (`Employment`, `World.employment`): `employ`, `refusal`, `dismiss`, `daily`, `plan`,
  `act_mine`, `act_deliver`, `to_dict`/`load_dict`.
- Hooks: `NPCBrain.skilled_place` (venture stations as room; `busy`), `_take_place` (`took_place`), `_station_for`,
  `_decide` (branch `employee`, `recorder_codes.json`), `act` (`emp_mine`, `emp_deliver`), `seek_work` (employees stay);
  `Construction.daily` (no family help for a venture); `World._new_day`, `to_dict`, `load_dict`; `NetActions.VERBS`;
  `GameUI` talk menu. Wiki: `sys:trade_experience` ("A business of their own"), `guide:employee`, "Not in the game yet".
  Interactions INT-661..663. Tests `game/tests/business_founding_test.gd`.

## 8. Open questions: answered by the owner (2026-11-01)

The owner answered all five (`docs/directives/2026-11-01_business_ownership_employment_final_decisions.md`, B25-BIZ-D1..D5).
The specification that replaces the provisional choices is **`docs/expansion20/BUSINESS_OWNERSHIP.md`**; the earlier
conservative options are kept here as history only:

- **Q1** (separate business accounts): was "none, the household's purse"; now **replaced** by Decision 1 (a venture keeps
  its own till under the ECON-P3 rules, BUSINESS_OWNERSHIP.md section 2).
- **Q2** (hands paid a wage): was "leave, no wage"; now **replaced** by Decision 2: hands stay independent craftspeople,
  and businesses also hire paid employees whose production is the employer's (section 3).
- **Q3** (abandoning a site): "no automatic refund" is **confirmed** by Decision 3, with a cancellation path through
  `World.cancel_site` (section 4).
- **Q4** (further player employee roles): was "miner only"; now **replaced** by Decision 4, one framework across the
  professions with real work systems (section 5).
- **Q5** (buying or renting an existing workshop): was "build only"; now **replaced** by Decision 5, buying, selling and
  expanding (section 6).
