# R5: NPC aspirations (World Design Rule 011), design note

Build 19 recovery batch R5, register record **WDR-011-C** (next action "Design the five aspiration domains"). Design only:
no game code is written in this batch. The code batch comes after R2 (see section 9). Code is cited as `file:line` on
`origin/wip/expansion20` at **e49384e**; paths are under `game/scripts/core/` unless given in full.

Bound by WDR-022 ("a village is allowed to fail, the simulation is not"), MSW-01, and the owner's correction of 2026-10-26
(`docs/directives/2026-10-26_npc_judgment_refusal_correction.md`). Under that correction, judgment influences a decision and
does not dictate it. An aspiration is one more weighted influence of the same kind. It never forces an outcome, and it
adds no fixed cutoff.

Every number in this note is **PROVISIONAL** (an agent value) unless it is marked "owner". Rule 011 gives no numbers.

---

## 1. What Rule 011 requires, and where each part is designed

`docs/WORLD_DESIGN_RULES.md:113-121`, quoted:

> - Every NPC must pursue a better life according to their personality, means, age, circumstances and ambitions.
> - Track five aspiration domains: food/security, money/wealth, goods/property, professional growth, and family/household development.
> - Priorities must change after successes and setbacks; NPCs may fail, be content, or choose different definitions of success.
> - Link ambitions to actual purchases, production, relationships, housing, inheritance and employment.
>
> *Example:* An NPC may prioritize food, then wealth, property and family; another may prefer stability. Heirs do not automatically inherit ancestor skills.
> *Verification:* Test five aspiration domains and adaptation after illness, loss, marriage or prosperity.

| Rule 011 part | Design element |
|---|---|
| Pursue a better life according to personality, means, age, circumstances, ambitions | A **priority** per domain: a temperament set at birth by a seeded hash (personality, §4) and shaped by age (§4). A **satisfaction** per domain, read from real state (means and circumstances, §2). Their product gives a **pressure**, and the domain with the highest pressure is the **leading aspiration** (ambition, §2). |
| Track five domains | `food`, `wealth`, `property`, `profession`, `family` (§2), each derived each morning from fields that already exist |
| Priorities change after successes and setbacks | Bounded, saved **priority shifts** made by events (§4): a satisfaction band crossed upward (success) or downward (setback), loss of kin, marriage, injury or hunger |
| May fail, be content, choose different definitions of success | Failure: nothing in this design gives coins, food or goods (§4, "no rescue"). Contentment: when no pressure reaches `content_below`, there is no leading aspiration and the factor is neutral. A different definition of success: after repeated setbacks, an adaptive villager's priority moves to another domain (§4). |
| Link to purchases, production, relationships, housing, inheritance, employment | The factor enters the existing `JudgmentWeighting.choose` decision sites (§3): employment (`work_accept`, `contract_accept`), relationships and housing (`family_help` against the household's own housing goal), money (`credit_lend`) and goods (`barter_accept`). Inheritance moves real coins and goods (`world.gd:3201` `_inherit`), so the next morning's satisfaction reflects it. Purchases and production have no `choose()` site today; §3 explains how they connect. |
| "Heirs do not automatically inherit ancestor skills" | Already true: `NPC.skills` (`npc.gd:50`) belongs to each person, and `Skills.start_xp` (`skills.gd:115`) seeds only at world generation. Priorities are not inherited either, because the temperament hash is per person id. aspiration_test checks both. |
| Verification: five domains plus illness, loss, marriage, prosperity | `aspiration_test.gd` (§7) |

---

## 2. The five domains: what each reads

Satisfaction is milli-points on 0..100000, the same scale as every `choose()` factor (`judgment/judgment_weighting.gd:12`).
It is **derived each morning and never saved**. Only adults have aspirations (`NPC.role == "adult"`, `npc.gd:13`); children,
elders and bandits have none. Every domain reads existing state; nothing below adds an economy, a ledger, a store or a
stock. `econ` is the household's `hh.econ`, recomputed each morning by `NPCBrain.evaluate_household` (`npc_brain.gd:3818`,
fields at `:3848-3849`).

| Domain | Reads (exactly) | Satisfaction (PROVISIONAL shape) |
|---|---|---|
| **food** (food/security) | `econ.days` (food in hand plus what the cash buys, `household_food_days`, `npc_brain.gd:3700`); `econ.sustainable`, `econ.streak`; `NPC.hunger` (`npc.gd:26`) | `min(days / household_savings_days, 1)` (balance.json:591, 10 days), scaled to 100000. Each morning of `streak` takes `streak_step` off. Hunger at or below `eat_below` (balance.json:106, 55) caps it at `hunger_cap`. |
| **wealth** (money/wealth) | `NPC.coins` (`npc.gd:25`); the household purse `Property.purse(hh_ref)` (`property.gd:269`); `NPC.avg_income(5)` (`npc.gd:78`) against the adult's share `econ.cost / econ.adults` (the same test as `seek_work`, `npc_brain.gd:4045ff`) | Half from the purse against `wealth_days x econ.cost`, half from income against the share; each part is capped at 1 |
| **property** (goods/property) | `Property.homes_of(hh_ref)` and `held_by(hh_ref)` (`property.gd:161-166`); whether the home is owned or leased (`World.holds`); `FarmPlots.plots_of(hh_ref)` (`farm_plots.gd:91`); open housing goals `Construction.housing_goals(h)` (`construction.gd:775`, the `short` field), `hh.build`; the trade's tool `NPCBrain.tool_short(n)` (`npc_brain.gd:2178`) | Points: owned home > leased home > lodging or crowded. Farmland held adds points. An open goal with `short > 0` takes points off. A missing tool takes points off. |
| **profession** (professional growth) | `NPC.job` (`npc.gd:14`); `Skills.level(n, sk)` (`skills.gd:89`) for each skill in `balance.json` `skill_start.job_skills[job]` (balance.json:621), against `Skills.max_level()`; `NPC.job_since`, `NPC.left_job` (`npc.gd:57-58`) | No job: 0. Otherwise the mean level of the trade's skills over `profession_level_full`. A trade with no listed skill (manor hand, farmer) is scored on tenure alone, `(day - job_since) / profession_tenure_full`. |
| **family** (family/household development) | `NPC.partner`, `NPC.children` (`npc.gd:66-67`); `econ.dependants` and `econ.days` (dependants fed); the courting stage `Relations.stage(a, b)` (`relations.gd:504`); a couple's open goal `couple:<a>:<b>` (`construction.gd:1044`); age `Life.age_years` (`life.gd:106`) | Single, not courting: low. Courting: more. Partnered: mid. Partnered with children and the household sustainable: high. A household of its own (no open `couple`/`split` goal) adds points. |

**Standing and status are not a domain.** Rule 011 fixes five, and village opinion already enters every choice as the
`disposition` factor (`judgment_weighting.gd:91-101`). Using it again here would count it twice. See owner question Q6.

**Pressure and the leading aspiration.** `pressure_d = priority_d x (100000 - sat_d) / 1000`, where `priority_d` is in
permille (§4). The leading aspiration is the domain with the highest pressure. Ties go to the earlier domain in Rule 011's
order: food, wealth, property, profession, family. If the highest pressure is below `content_below`, the villager is
**content**: there is no leading aspiration, and the factor is neutral at every site.

---

## 3. How an aspiration enters decisions: one factor, no second engine

The aspiration is **one factor, `aspiration`**, in existing `decision.profiles` (`game/data/judgment.json`). It is
weighed by the existing `JudgmentWeighting._choose` (`judgment_weighting.gd:49`). It is scored like `disposition`:
`aspiration_mid` (50000) is neutral, values above it favour the option, and values below it count against it.

**Value of the factor for an option:** `mid + fit x min(pressure_lead, 50000)`. `fit` is -1, 0 or +1 from the table
`aspiration.fit[profile][domain]` in judgment.json. When the villager is content, or the profile/domain fit is 0, the value
is `mid`.

**Where it is read.** In `_choose`, next to the `disposition` fill (`judgment_weighting.gd:91-105`):
`if weights.has("aspiration") and not f.has("aspiration"): f.aspiration = store.asp.value(chooser, profile, cand.get("serves"))`.
An optional candidate key `serves` lets a caller override the table for that candidate (for example, `work_refusal` with
`wage == 0` is unpaid, so the wealth fit is 0). **No live caller needs editing**: they already pass their candidates to
`choose`.

**Neutral equals off.** The four sites below are single-candidate "yes or forgo" choices (`JudgmentLive.willing`,
`judgment_live.gd:625` (choose at `:629`); `work_refusal`, `:556`). A neutral factor adds `w x mid / 1000` to "yes" and would tilt every
answer, so `_choose` adds the same amount, using the chooser's own `trait_weight`, to that profile's `forgo` (`:130-137`).
A neutral aspiration therefore changes no answer. aspiration_test proves it (§7).

| Profile (weight, PROVISIONAL) | Live site | food | wealth | property | profession | family |
|---|---|---|---|---|---|---|
| `work_accept` (150) | `Construction.hire` `construction.gd:303`, `Business.hire` `business.gd:1002` | +1 | +1 (paid only) | +1 if a housing goal is `short` | 0 | +1 if dependants unfed |
| `contract_accept` (150) | `Contracts.evaluate` `contracts.gd:525` | +1 | +1 | 0 | +1 (work in the villager's own trade) | 0 |
| `credit_lend` (100) | `Credit.credit_refusal` `credit.gd:268` | -1 | -1 | -1 if a goal is `short` | 0 | 0 |
| `barter_accept` (100) | `Credit.barter_quote` | 0 | -1 | +1 | 0 | 0 |
| `family_help` (150) | `Construction._family_help` `construction.gd:1354` | -1 | -1 | -1 if the giver's own goal is `short` | 0 | +1 |

**Not weighted**, and why:
- `trade_sell`, `trade_buy_from`, `hire_choice`, `contract_seller` and `food_seller` choose among counterparties. An
  aspiration is the same for every candidate, so it cannot separate them.
- `court_choice` is left out until Q3 is answered.
- `befriend` is computed outside `_choose` (`judgment_live.gd:573`).
- The `family_*` profiles carry the owner's family-first rule (`judgment_family.gd`). That order is a rule, not a weight,
  so it is not touched.

**Purchases, production and job choice.** These have no `choose()` site today:
- `seek_work` (`npc_brain.gd:4045`) scores jobs by pay.
- Stall buying (`business.gd:1125ff`) works from need lists.
- `_find_home` (`construction.gd:1170`) is driven by the purse.

These sites already serve domains directly. A household saves toward a home through `housing_goals`; courting gifts wait
while `saving_for_home` (`npc_brain.gd:948`); and an adult whose income misses their share moves to better-paid work. The
aspiration reaches purchases once the Living Economy bids go through `choose` (R7, LE-02), when the same factor joins
those profiles. Steering careers needs a new `job_choice` profile; that is owner question Q2. v1 adds no second scoring
path to any of these sites.

---

## 4. Personality, adaptation, and failure without rescue

**Temperament at birth.** Nothing is stored for it, as with tolerance (`judgment_store.gd:745`):
`base_d = 1000 ± hash_ints([seed, id, 7001 + d]) % (2 x priority_spread + 1) - priority_spread` (`priority_spread` 300).
Some villagers therefore put food first, some wealth, some family, and some prefer stability: a flat profile with low
pressures, often content.

**Age** shifts these PROVISIONAL bases linearly from `Life.age_years`:
- Under `young_until` (25): family and profession +100.
- Over `old_from` (50): profession -200 and food +100. The profession domain is inactive once there is no job.

**The aspiration weight per person.** The factor's weight is spread per person by the existing
`JudgmentWeighting.trait_weight` (`:194`). Some villagers are therefore driven by their ambitions and others hardly at all,
with no new mechanism.

**Priority shifts** are saved per person per domain in permille, bounded to ±`max_shift` (300). Each morning,
`aspire_dawn` re-derives the satisfactions and compares each domain's band (0..4, by `band_edges`) with the band saved the
day before:

| Event (source) | Shift |
|---|---|
| **Success**: a band crossed upward (for example, wealth crosses into band 4: prosperity) | That domain -`success_step` (it is met), so the next pressure leads |
| **Setback**: a band crossed downward (a theft, lost work, a failed harvest) | Depends on personality (below) |
| **Illness**, read as injury (`hp <= injury_permille x max_hp`, `npc.gd:27-28`) or hunger at or below the owner's survival floor 25 (owner, judgment.json `decision.family.survival_floor_hunger`) | food +`illness_step` while it lasts, decaying `recover_per_day` once over (Q1) |
| **Loss**: death of partner, child or parent (`JudgmentLive.on_death`, called at `world.gd:3151`) | family: by personality (below) |
| **Marriage** (`JudgmentLive.on_marriage`, `judgment_live.gd:403`) | family satisfaction rises by state; property +`marriage_step` (a home of their own) |

**Response to a setback, by personality.** This uses the existing traits (`judgment/judgment_personality.gd`), with no new
trait:
- **Persevering:** a holder of stubbornness (about 30% of villagers, owner-approved distribution, `traits.stubbornness_share_permille`).
  The setback domain gets +`setback_step`, scaled by `stubbornness(person)` (`:249`), so they redouble.
- **Adaptive:** everyone else. The setback domain gets -`setback_step`, sped up by `general_wisdom(person)` (`:285`), and
  the next domain's pressure takes over. This is how a villager comes to choose a different definition of success.
- **Repeated setbacks:** after `giveup_after` setbacks in one domain within `window_days`, a persevering villager also
  adapts (the shift reverses). This is bounded; nobody loops forever.

**No rescue (WDR-022).**
- An aspiration only weights choices the live code already found feasible. An infeasible candidate is never chosen
  (`judgment_weighting.gd:85-88`).
- No coin, food or item is created, moved or granted by this layer.
- A villager whose aspiration is never met stays unmet. A household that fails, fails.
- Pressure can make a villager decline work while they still have coin, or refuse a relative help, and both outcomes are
  valid under the refusal directive. No fixed cutoff exists, because the factor is weighed against necessity and
  disposition.

---

## 5. Save data

- **Where.** Inside the existing judgment section (`JudgmentStore.to_dict`, `judgment_store.gd:2055`), as an optional key
  `aspire`: rows `[person, shift_food..shift_family (5), band_food..band_family (5), lead (-1 content, 0..4), lead_since_day, setbacks_packed]`,
  sorted by person. It is written only when non-empty. Temperament and satisfaction are not saved, because they are
  derived.
- **Version.** `JudgmentStore.VERSION` goes 2 → 3 (`:78`), and 3 is written **only when `aspire` is present**. With the
  flag off, a save is byte-identical to today's version 2.
  - An older build (19 to 22) meeting a version 3 section refuses it and keeps it unread (`migrate`, `:2304-2307`). The
    data is not silently dropped.
  - `World.SAVE_VERSION` (`world.gd:5126`, 23) is unchanged.
- **Migration 2 → 3.** Nothing is rewritten. If `aspire` is absent, there are no shifts, and the first morning only
  initialises the bands, so it does not count as a crossing (no false success or setback on load).
- **Tests.** migration_test gets a version 2 fixture (loads, no aspirations, then the first dawn initialises) and a
  version 3 round trip.

---

## 6. Determinism and the recorder (R3)

**Determinism.**
- Only `JudgmentMath.hash_ints` and integer milli-points are used. There is no `World.rng`, no float in a saved value, and
  no iteration over an unsorted dictionary (persons are walked by id).
- `aspire_dawn` runs once a day at one fixed point: a guarded line after `brain.dawn()`, beside `judgment.begin_day`
  (`world.gd:518`). It is therefore after `evaluate_household` and `seek_work` (`npc_brain.gd:4441-4443`). If Q2 adds
  `job_choice`, the call moves between those two lines.
- The same seed gives the same leads and the same choices.

**Recorder.** `world_recorder.gd:1072` `judgment_choice` already writes every factor and every weighted contribution of
every `choose()`. The `aspiration` and `weighted:aspiration` rows therefore appear with no new hook. The code batch adds:
- `_JSOURCE["aspiration"] = "aspiration"` (`:1069`), so the source column reads `aspiration`.
- The trace row carries `aspiration: {domain, pressure, fit}`, written as factors `aspiration_domain` (text),
  `aspiration_pressure` and `aspiration_fit`.
- The forgo row adds `forgo_aspiration_offset` (the neutral compensation in §3).
- One new event code, `judgment/aspiration` (in `game/data/recorder_codes.json` and `recorder_coverage.json`), per
  priority shift or lead change, with its cause (band, loss, marriage, illness) and the before and after values.

The recorder stays off by default and uses no RNG. A 10-day `economy_sim` fingerprint is identical with and without
`--record` (the R3 check).

---

## 7. Flag, tests and the G0 expectation

**Flag.** A new judgment.json section `aspiration` holds `"enabled": false`, the fit table, the profile weights and the
numbers in §8. Shipped **off until the owner reviews it**. It takes effect only when judgment itself is on (a store is
attached) and the profile's `decision.integration` flag is set (`JudgmentLive.on`, `judgment_live.gd:46`). With it off:
- `_choose` skips the `aspiration` weight.
- `aspire_dawn`, `on_death` and `on_marriage` do nothing.
- Nothing is saved.

A test switch `JudgmentAspiration.test_enabled` mirrors `JudgmentLive.test_enabled`.

**`game/tests/aspiration_test.gd`**, all deterministic fixtures:

1. **Five domains.** Each domain's satisfaction moves with exactly the fields in §2 and with no others (change one field,
   check one domain).
2. **Neutral = off.** With aspirations on and every villager content or the fit at 0, every result of the five profiles
   equals the off result.
3. **Off identity.** With the flag off, the judgment section has the same bytes, version 2, and no `aspire` key.
4. **Steering, both ways.** A wealth-led adult with coin accepts work that a content one with the same dislike refuses. A
   family-led relative gives `family_help` that a property-led one saving for a home declines. Need still outweighs both
   (the refusal directive's `test_need_vs_opinion` pattern).
5. **Feasibility.** An infeasible candidate is never chosen, whatever the pressure.
6. **Rule 011 verification scenario** (a fixture village and days):
   - **illness:** injury, then hunger below 25, raises food to lead, and the lead fades back after recovery;
   - **loss:** a partner killed through `World.kill`; a stubborn widow's family priority rises while an adaptive one's
     falls and another domain leads;
   - **marriage:** through `Relations.propose`, family satisfaction rises and property gains;
   - **prosperity:** coins cross into wealth band 4; wealth eases and the next domain leads; with all domains met, the
     villager is content;
   - **failure:** a villager whose setbacks persist stays unmet, and no coins or food appear (ledger totals unchanged).
7. **Heirs.** A grown child's skills start empty; their priorities come from their own hash, not the parent's.
8. **Save round trip** mid-scenario: identical leads and next choices. A version 2 load gives no false crossings.
9. **Determinism.** Two runs on the same seed give identical leads and traces. The recorder rows contain the aspiration
   factors.

Existing suites to rerun in the code batch: judgment_test, judgment_live_test, judgment_x19_test, family_first_test,
migration_test, recorder_test, conservation_test.

**G0 expectation.** With aspirations off, as shipped: **identical** to the registered baseline (`tools/sim_gate.py`). No
new code path runs, no RNG is drawn, and the save is unchanged. With aspirations on, a separate configuration on the four
seeds is **measured, not pass/fail** (WDR-022): it reports leads by domain, refusals moved by the factor, and village
outcomes. One run per seed (SIM-01).

---

## 8. Numbers, and questions for the owner

| Setting | Value | Status |
|---|---|---|
| survival floor hunger (illness trigger) | 25 | **owner** (`decision.family.survival_floor_hunger`, accepted 2026-10-23) |
| stubbornness share (persevering villagers) | 300 permille | **owner** (X19-TRAIT-DIST, `traits.stubbornness_share_permille`) |
| aspiration weights: work_accept 150, contract_accept 150, family_help 150, credit_lend 100, barter_accept 100 | | PROVISIONAL |
| aspiration_mid | 50000 | PROVISIONAL (same as `disposition_mid`) |
| priority_spread | 300 permille | PROVISIONAL |
| content_below | 15000 | PROVISIONAL |
| band_edges | 20000/40000/60000/80000 | PROVISIONAL |
| success_step 150, setback_step 150, illness_step 300, marriage_step 150, max_shift 300 (permille) | | PROVISIONAL |
| recover_per_day 50, giveup_after 3, window_days 8 | | PROVISIONAL (8 = one game year, as in `traits.frequency.window_days`) |
| young_until 25, old_from 50, age shifts ±100/200 | | PROVISIONAL |
| wealth_days 10, streak_step 10000, hunger_cap 30000, profession_level_full 8, profession_tenure_full 16 days, injury_permille 500 | | PROVISIONAL |
| fit table (§3) | | PROVISIONAL |

**Questions only the owner can settle:**

- **Q1. Illness.** The game has no illness system, so "illness" in the verification has no state to read.
  - Options: (a) read it as injury (low health) and near-starvation hunger, which are real states today; (b) wait for an
    illness system.
  - **Recommend (a).** It can be replaced once illness exists.
- **Q2. Careers.** Job switching (`seek_work`) scores pay only and is not a `choose()` site.
  - Options: (a) v1 steers employment only through accepting work and contracts; (b) add a `job_choice` profile, behind
    its own `integration` flag, so ambition (for example, staying in one's trade to grow) can outweigh small pay
    differences.
  - **Recommend (b)**, after R2, as its own small step.
- **Q3. Choosing a partner.** May a wealth-led or property-led villager favour a suitor whose household has means
  (`court_choice`)?
  - Options: (a) no, courting stays attraction plus opinion; (b) yes, at a small weight.
  - **Recommend (a)** for v1.
- **Q4. Who perseveres after a setback.**
  - Options: (a) the existing stubbornness holders (about 30%), with wisdom speeding adaptation; (b) a new seeded
    "ambition" temperament.
  - **Recommend (a).** It adds no trait, and the owner has already approved its distribution.
- **Q5. Numbers.** Approve the PROVISIONAL values above for a first measured run, or set them.
  - **Recommend:** approve them as a starting point, and tune from the four-seed measurements.
- **Q6. Social standing.** Should standing or status be a sixth domain?
  - Options: (a) no, Rule 011 names five and opinion already acts as `disposition`; (b) yes, read from aggregate opinion.
  - **Recommend (a).**
- **Q7. Visibility.** Should players see villagers' aspirations?
  - Options: (a) not in v1; (b) a dialogue line ("saving for a house of our own") from the leading domain.
  - **Recommend (b), later**, under WIKI-01, once the code is on and reviewed.

---

## 9. Effort and files for the code batch (after R2)

**Effort:** about 1.5 to 2 worker-days, including tests. It must run after R2 and not in parallel with R4: all three touch
`judgment_live.gd` and `judgment.json`.

| File | Change |
|---|---|
| `game/scripts/core/judgment/judgment_aspiration.gd` (new, ~300 lines) | Domains, satisfaction, temperament, shifts, `value()`, `aspire_dawn`, `on_loss`, `on_marriage`, to_dict/load_dict rows |
| `judgment/judgment_weighting.gd` (~15 lines) | Fill `aspiration` beside `disposition`; neutral forgo offset; skip the weight when off |
| `judgment/judgment_store.gd` (~40 lines) | `asp` member; `aspire` key; VERSION 3 written only when present; migrate 2 → 3 |
| `judgment/judgment_live.gd` (~15 lines) | `aspire_dawn(w)`; calls from `on_death` and `on_marriage`; `serves` override in `work_refusal` for unpaid work |
| `game/data/judgment.json` | `aspiration` section (off), profile weights, fit table |
| `world.gd` (1 guarded line at :518) | `JudgmentLive.aspire_dawn(self)` after `brain.dawn()` |
| `recorder/world_recorder.gd`, `game/data/recorder_codes.json`, `recorder_coverage.json` | `_JSOURCE` entry, trace factor rows, `judgment/aspiration` event |
| `game/tests/aspiration_test.gd` (new, ~400 lines); `migration_test.gd` (+2 cases) | §7 |
| `docs/SYSTEM_INTERACTION_MANIFEST.md` | New `INT-###`: aspiration (household econ, property, skills, relations) → judgment choices |
| `docs/DECISIONS.md` | Agent decisions for the PROVISIONAL values and the neutral-forgo rule |
| In-game wiki | None while the feature is off (WIKI-01: implemented only). A "Not in the game yet" line is optional. |

`npc_brain.gd` is **read only** (`evaluate_household`, `household_food_days`, `tool_short`); it needs no edit unless Q2(b)
is chosen.
