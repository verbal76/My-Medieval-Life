# R5: NPC aspirations (World Design Rule 011), design note

Build 19 recovery batch R5, register record **WDR-011-C**. Design only: this batch writes no game code. The code batch
waits for R2 and R4, which change the same files (§10).

- **Revision 2 (2026-10-27).** This revision applies the owner's final answers to WDR-011-Q1 to Q7
  (`docs/directives/2026-10-27_final_aspirations_decisions.md`, verbatim there; quoted below as "FAD"). Revision 1 was
  e25b0ed.
- **Code citations.** Code is cited as `file:line` on `origin/wip/expansion20` at **e49384e**. Paths are under
  `game/scripts/core/` unless given in full.

**Binding directives.**
- WDR-022: "a village is allowed to fail, the simulation is not".
- MSW-01.
- The refusal correction (`docs/directives/2026-10-26_npc_judgment_refusal_correction.md`): opinion influences and never
  dictates, and there are no fixed cutoffs.
- FAMILY-01: the family-first hierarchy.
- FAD itself: "use the existing weighted decision architecture rather than introducing a competing AI engine".

**Numbers.** Every number in this note is **PROVISIONAL** (FAD Q5: agent starting values, "identifiable and adjustable",
kept in one `aspiration` section of judgment.json). The exceptions are marked **owner**: the hunger survival floor of 25 and
the stubbornness share of about 30% (FAD Q5: "authoritative").

---

## 1. The rule, as expanded by the owner, and where each part is designed

Rule 011 (`docs/WORLD_DESIGN_RULES.md:113-121`) has four mandatory bullets: pursue a better life by personality, means,
age, circumstances and ambitions; track the domains; priorities change after successes and setbacks (NPCs may fail, be
content, or redefine success); link ambitions to purchases, production, relationships, housing, inheritance and
employment. It also requires that heirs do not inherit skills, and its verification asks for a test of the domains and of
adaptation after illness, loss, marriage and prosperity.

FAD Q6 "intentionally expands World Design Rule 011 from five domains to six". The rule text in
`WORLD_DESIGN_RULES.md` is the lead's to update; it is not changed here.

| Requirement | Design element |
|---|---|
| Pursue a better life according to personality, means, age, circumstances, ambitions | Each domain has a priority, a satisfaction and a pressure, giving a leading aspiration (§2). The priority comes from a temperament seeded at birth, then age and life events (§5). |
| Six domains (FAD Q6) | `food`, `wealth`, `property`, `profession`, `family`, `standing` (§2, §3) |
| Priorities change; fail, be content, redefine success | Bounded, saved priority shifts on success and setback; survival pressure (§4); stubbornness and wisdom (FAD Q4, §5); contentment; no rescue |
| Link to purchases, production, relationships, housing, inheritance, employment | Yes-or-forgo profiles (§6.1); `job_choice` (FAD Q2, §6.2); `court_choice` (FAD Q3, §6.3). Housing goals and inheritance change the real state each domain reads. Purchases join when the Living Economy bids go through `choose` (R7, LE-02). |
| Heirs do not inherit skills | Already true: `NPC.skills` (`npc.gd:50`) is per person and `Skills.start_xp` (`skills.gd:115`) runs only at world generation. Priorities are not inherited either: they are a per-id hash. |
| Survival and health (FAD Q1) | Survival pressure across all domains, dynamic and personality-sensitive, recovering afterwards, composed with `JudgmentFamily` without touching its order (§4) |
| Dialogue (FAD Q7) | Not in this code batch: "implement the dialogue integration when the underlying aspiration system is functional and reviewed". Planned later through `EventTalk` and `DialogueVoice` (§9). |

---

## 2. The six domains: what each reads

**Satisfaction** is 0..100000 milli-points, the scale every `choose()` factor uses (`judgment/judgment_weighting.gd:12`).
It is derived each morning and never saved. Only adults have aspirations (`NPC.role == "adult"`, `npc.gd:13`).

`econ` means `hh.econ` from `NPCBrain.evaluate_household` (`npc_brain.gd:3818`, fields at `:3848`), and `ref` means
`World.hh_ref(h)`. No new economy, ledger, store or stock is introduced.

| Domain | Reads (exactly) | Satisfaction (PROVISIONAL shape) |
|---|---|---|
| **food** (food and security) | `econ.days` (`household_food_days`, `npc_brain.gd:3700`), `econ.sustainable`, `econ.streak`; `NPC.hunger` (`npc.gd:26`) | `min(days / household_savings_days 10 (balance.json:591), 1)`, minus `streak_step` for each unsustainable morning, capped at `hunger_cap` when hunger is at or below `eat_below` 55 (balance.json:106) |
| **wealth** | `NPC.coins` (`npc.gd:25`); `Property.purse(ref)` (`property.gd:269`); `NPC.avg_income(5)` (`npc.gd:78`) against the share `econ.cost / econ.adults` (the test in `seek_work`) | Half from the purse against `wealth_days x econ.cost`, half from income against the share |
| **property** (goods and property) | `Property.homes_of(ref)` and `held_by(ref)` (`property.gd:161-166`), owned or leased (`World.holds`); `FarmPlots.plots_of(ref)` (`farm_plots.gd:91`); `Construction.housing_goals(h)` (`construction.gd:775`, `short`) and `hh.build`; `NPCBrain.tool_short(n)` (`npc_brain.gd:2178`) | Owned home > leased home > lodging or crowded. Farmland adds points. An open goal and a missing tool take points off. |
| **profession** | `NPC.job`, `job_since`, `left_job` (`npc.gd:14,57-58`); `Skills.level(n, sk)` (`skills.gd:89`) over `skill_start.job_skills[job]` (balance.json:621) | 0 without a job. Otherwise the mean level over `profession_level_full` 8, or tenure over `profession_tenure_full` 16 days for a trade with no listed skill. |
| **family** (family and household development) | `NPC.partner`, `children` (`npc.gd:66-67`); `econ.dependants`, `econ.days`; `Relations.stage` (`relations.gd:504`); a couple's goal (`construction.gd:1044`); `Life.npc_age` (`life.gd:163`) | Single and not courting: low. Then courting, partnered, and partnered with children and a sustainable household: high. |
| **standing** (social standing and recognition) | Actual standing (§3) from the judgment store's personal ledgers; holding a recognised existing post (`NPC.job` in `reeve`, `sage`, `guard`, `preacher`, `church_assistant`) | `standing_value(n)` (§3) plus `post_points`. No office or institution is created (FAD Q6). |

**Pressure and the leading aspiration.**
- `pressure_d = eff_priority_d x (100000 - sat_d) / 1000`, where `eff_priority` is the priority after survival pressure
  (§4).
- The leading aspiration is the domain with the highest pressure. Ties go to the fixed order food, wealth, property,
  profession, family, standing.
- If every pressure is below `content_below` 15000, the villager is **content** and the aspiration factor is neutral
  everywhere.

---

## 3. The sixth domain: standing, without double counting (FAD Q6)

FAD Q6 asks that four things be kept apart.

| Quantity | What it is | Where it lives | Where it enters a decision |
|---|---|---|---|
| (a) The social **ambition** | How much this NPC wants respect | `eff_priority_standing(n)`: temperament, age, shifts (§5) | Scales pressure (single-candidate profiles); scales the weight of a counterparty's standing (court_choice) |
| (b) The **actual standing** | How the village judges this NPC overall | `standing_value(n)`, derived each morning (below) | Satisfaction of n's own standing domain; in `court_choice`, the factor `standing` of each **candidate** |
| (c) **Individual opinions** | What one observer thinks of a subject | The existing ledgers: `personal_disposition` (`judgment_store.gd:1111`) and `colour` | Only through the existing `disposition` factor (`judgment_weighting.gd:91-101`), unchanged |
| (d) **Influence on a decision** | The weighted contribution | `JudgmentWeighting._choose` trace | Recorded per factor (§8) |

**`standing_value(n)`**, 0..100000:
- Collect every observer `o != n` holding a personal ledger on `n`: villagers only, because players keep no ledgers.
- For each, take `personal_disposition(o, n) - disposition_mid`.
- Clamp the mean to ±50000 and add `disposition_mid`. Add `recognition`: `min(observers, recognition_full 20) x recognition_step`.
- Family colour is excluded (personal judgments only), so a family name never enters through standing. This keeps
  X19-BOND-LIMITS: "inherited reputation alone can never cause a refusal".

**Computation and exclusion.** It is computed once per dawn by one pass over all ledgers (§11). It also keeps each
observer's own contribution, so `standing_excluding(n, chooser)` is O(1).

**No double counting, per decision profile.** In any one `choose()`, a given ledger entry `(o, s)` contributes at most once.

| Profile | `disposition` reads | Standing reads | Overlap? |
|---|---|---|---|
| `work_accept`, `contract_accept`, `credit_lend`, `barter_accept`, `family_help` | Chooser's own opinion of the counterparty | Only the chooser's own standing (others' view of the **chooser**), through the pressure of the chooser's standing aspiration | None: different subjects |
| `job_choice` | not weighed | not weighed (the jobs that are posts carry `post` through the property and standing satisfaction only) | None |
| `court_choice` | Chooser's own opinion of candidate `x` (with colour) | `standing_excluding(x, chooser)`: everyone else's personal opinion of `x` | None: the chooser's own entry `(chooser, x)` is removed from the standing figure |
| `family_*`, `trade_sell`, `trade_buy_from`, `hire_choice`, `contract_seller`, `food_seller`, `befriend` | as now | not read | none |

**What serves the standing aspiration.** An option gets standing fit +1 only when the live outcome already publishes a GOOD
fact about the chooser, which others then judge:
- `family_help` publishes `help_build` (`construction.gd:1364`).
- `contract_accept` publishes `trade_fair` when the contract is kept (`contracts.gd:875`).

Anything else gets fit 0. The ambition can therefore change behaviour only through deeds that the judgment system already
scores. aspiration_test checks the exclusion (§9, V7).

---

## 4. Survival pressure across all domains (FAD Q1), and the family-sacrifice safeguard

**Survival level `surv(n)`**, 0..1000 permille. It is the highest of three measurable, existing conditions; no illness
system is invented.

| Condition | Reads | Term (PROVISIONAL) |
|---|---|---|
| Severe hunger | `NPC.hunger` (`npc.gd:26`) | 0 at `eat_below` 55; 1000 at the **owner** survival floor 25 (`decision.family.survival_floor_hunger`) and below; linear between |
| Injury | `NPC.hp / max_hp` (`npc.gd:27-28`) | 0 at `injury_from` 700 permille of max; 1000 at `danger.hp_floor_permille` 200 (owner-approved behaviour, agent value); linear |
| Dangerous conditions | The person's own memories (`JudgmentStore.memories[n]`, `judgment_store.gd:111`, `M_TYPE`/`M_DAY` `:82-83`) of BAD facts of family `violence` (assault, killing: judgment.json `events`) within `danger_days` 8, weighted 2x when a victim is of their household | `danger_step` per such fact, capped at 1000 |

**Recovery.**
- `surv` is recomputed each dawn and when hunger or health is read at a decision. It rises at once.
- It falls at most `recover_per_day` 200 a day, so ambitions regain influence gradually after recovery (FAD: "after
  recovery, previously important ambitions may regain influence").
- The decayed value is the one saved field for this (§7). It is **not** a priority shift: nothing about the person is
  changed permanently.

**Effect on all six domains** (dynamic, personality-sensitive, never cancelling):

```
eff_priority_food     = priority_food     x (1000 + surv x boost_food / 1000) / 1000              boost_food 2000
eff_priority_d (else) = priority_d        x (1000 - surv x yield_d(n) / 1000) / 1000              d in wealth, property, profession, family, standing
yield_d(n)            = yield_base_d x (1000 - hold(n)) / 1000, never below yield_floor 200
hold(n)               = stubbornness(n) (judgment_personality.gd:249) x hold_share 500 / 1000
```

- `yield_base` (PROVISIONAL): wealth 600, property 700, profession 600, family 300, standing 700.
- Family yields least: under danger, protection and household stability stay in view.
- Every domain keeps at least `(1000 - yield) / 1000` of its weight. A stubborn villager holds on to ambitions longer under
  hardship; others turn to survival sooner.
- Per-person variety also comes from the existing per-person weight spread (`trait_weight`, `judgment_weighting.gd:194`).

The FAD examples, traced:
- A starving craftsman: food leads; profession pressure falls. `contract_accept` and `work_accept` favour paid work.
  `job_choice` lowers the weight of staying for skill.
- An injured merchant: wealth and property yield; `credit_lend` and `barter_accept` lean conservative; the trade continues.
- A household in danger: food and security lead; wealth and property expansion yield.

**Composition with JudgmentFamily (the mandatory safeguard).** The family hierarchy stays as the owner approved it, in its
own module (`judgment/judgment_family.gd`). Aspirations and survival pressure **do not enter** its profiles.

- **Untouched profiles.** `family_meal`, `family_pay`, `family_work` and `family_danger` keep their weights. No
  `aspiration` factor is added to them, and `surv` is not read by them.
- **The order is a rule, not a weight.** Children, spouse, parents, then self are applied by `tier` (`judgment_family.gd:62`)
  and `unfed`: each person defers only to lower tiers (`defers`, `:125-160`).
- **Self-preservation stays where it is.** The only self-preservation inside the hierarchy remains the existing one:
  - `self_floor` (weight 5000 at hunger 25 or below, `:146-149`): "a sacrifice is never a suicide";
  - the coin floors in `payer` (`:162-185`);
  - fleeing only below `hp_floor_permille` in `danger` (`:240ff`);
  - the rare `self_first_temperament`, a fixed hash, `self_first` (`:75`).
- **Ordering.** On each tick the family-first decisions run first and unchanged. Aspirations act only in the other
  profiles (§6), which concern work, contracts, credit, barter, help to *other* households, careers and courting. None of
  these is a choice about who of the head's dependants eats, gets paid for, or is shielded.

The family-sacrifice cases (tested in §9):

| Case | What happens | Why |
|---|---|---|
| Hungry parent, hungrier child, pantry short | The parent defers (`family_meal` chooses `defer`) and, under the food aspiration, is more likely to take paid work or a contract | `family_meal` is unchanged; the food lead raises `work_accept` and `contract_accept` |
| Parent at the survival floor (hunger 25 or below), child still hungry | The parent eats (`self_floor`), then keeps working for the family | Existing rule (owner: survival floor 25); aspirations cannot remove it |
| Head, health below `hp_floor`, threat near the children | May flee and fetch help instead of fighting to the death | Existing `family_danger` rule; `surv` does not push toward or away from it |
| Starving adult asked by a relative's household for building money | More likely to keep the coin | `family_help` gets food fit -1. The relative is outside the head's care, so the hierarchy is unaffected. Need still decides with opinion, with no cutoff. |
| Rare self-first temperament | Unchanged: eats at `self_first_hunger` 40 | Existing rule, a fixed hash |

---

## 5. Personality and adaptation (FAD Q4: existing traits only)

**Temperament at birth.** `base_d = 1000 ± (hash_ints([seed, id, 7001 + d]) % 601 - 300)` (`priority_spread` 300). As with
tolerance (`judgment_store.gd:745`), nothing is stored for it. Some villagers put food or wealth first; some prefer
stability (a flat profile, often content).

**Age** (from `Life.npc_age`):
- Under `young_until` 25: family and profession +100.
- Over `old_from` 50: profession -200, food +100, standing +100.

**Priority shifts.** These are saved per domain in permille, bounded to ±`max_shift` 300. Each dawn compares each domain's
band (0..4, `band_edges` 20/40/60/80 thousand) with yesterday's saved band.

| Event (source) | Shift |
|---|---|
| Success: a band crossed upward (prosperity: wealth reaches band 4) | That domain -`success_step` 150, so the next pressure leads |
| Setback: a band crossed downward (theft, lost work, a failed harvest) | By personality (below) |
| Loss of partner, child or parent (`JudgmentLive.on_death`, `judgment_live.gd:374`, called at `world.gd:3151`) | Family: by personality (below) |
| Marriage (`JudgmentLive.on_marriage`, `judgment_live.gd:403`) | Property +`marriage_step` 150; family satisfaction follows the state |

Illness, injury, hunger and danger are survival pressure (§4), not shifts.

**Setback response.** This uses only the existing traits (`judgment/judgment_personality.gd`), with no new trait:
- **Persevering**: holders of stubbornness (**owner** share of about 30%, `traits.stubbornness_share_permille`). The domain
  gets +`setback_step` 150 scaled by `stubbornness(person)` (`:249`).
- **Adaptive**: the others. The domain gets -`setback_step`, sped up by `general_wisdom(person)` (`:285`), and another
  domain's pressure takes over.
- **Giving up**: `giveup_after` 3 setbacks in one domain within `window_days` 8 (one game year) reverse even a stubborn
  villager's shift. This follows FAD Q4: "repeated setbacks can eventually cause even stubborn villagers to change their
  objectives".

**No rescue (WDR-022).**
- Only candidates the live code found feasible are weighed (`judgment_weighting.gd:85-88`).
- This layer creates or moves no coin, food or item.
- Unmet ambitions stay unmet, and failing households fail.

---

## 6. How aspirations enter decisions: the existing `JudgmentWeighting.choose`

There are two forms. **Each form is used on its own set of profiles, never both on one profile**, so no ambition is counted
twice.

### 6.1 Yes-or-forgo profiles: one `aspiration` factor

**Value of the factor.** `mid + fit x min(pressure_lead, 50000)`, with `mid` = 50000. `fit` is -1, 0 or +1, from
`aspiration.fit[profile][domain]`; a caller can override it with a candidate key `serves`.

**Where it is filled.** In `_choose`, beside `disposition` (`judgment_weighting.gd:91-105`). No live caller changes,
except unpaid work in `work_refusal` (`judgment_live.gd:556`), which passes `serves`.

**Neutral = off.** `forgo` is raised by `trait_weight(aspiration) x mid / 1000` (`:130-137`), so a neutral factor changes
no answer.

| Profile (weight) | Site | food | wealth | property | profession | family | standing |
|---|---|---|---|---|---|---|---|
| `work_accept` (150) | `construction.gd:303`, `business.gd:1002` | +1 | +1 (paid) | +1 if goal `short` | 0 | +1 if dependants unfed | 0 |
| `contract_accept` (150) | `contracts.gd:525` | +1 | +1 | 0 | +1 (own trade) | 0 | +1 (`trade_fair` when kept) |
| `credit_lend` (100) | `credit.gd:268` | -1 | -1 | -1 if goal `short` | 0 | 0 | 0 |
| `barter_accept` (100) | `Credit.barter_quote` | 0 | -1 | +1 | 0 | 0 | 0 |
| `family_help` (150) | `construction.gd:1354` | -1 | -1 | -1 if own goal `short` | 0 | +1 | +1 (`help_build`) |

### 6.2 `job_choice` (FAD Q2): a new profile at an existing decision site

**Call site.** `NPCBrain.seek_work` (`npc_brain.gd:4045`). Who looks for work is unchanged (`:4061-4071`). Feasibility is
unchanged: an open place, no `left_job` return within the cooldown, and the tool affordable (`:4076-4091`).

**Flag.** `decision.integration.job_choice` (shipped false), read through `JudgmentLive.on(w, "job_choice")`. With the flag
on, the final pick (`:4093-4102`) becomes `JudgmentLive.pick_job(w, n, cands, current)`, which calls
`JudgmentWeighting.choose(..., "job_choice", ...)`.

**Candidates.**
- `stay`, when employed: feasible and `live_order`-first when the live rule would not switch.
- Each feasible open job, with the live rule's best first when it would switch. With equal career factors, the live answer
  therefore stands.

**Factors** (0..100000):

| Factor (weight) | Value | Owner's list (FAD Q2) |
|---|---|---|
| `live_order` (300) | The live rule's order | Available employment |
| `wage` (200) | The live score (`opt.pay - setup - walk`, `:4088`) over the best score | Wages |
| `need_wage` (300) | Wage gain over current × `coin_need` (`judgment_live.gd:640`) and `econ.streak`, so hardship magnifies pay | Financial necessity |
| `skill` (200, scaled by profession priority) | Level in the option's `job_skills` over `profession_level_full`; for `stay`, the current trade | Existing skills; professional experience |
| `growth` (100, scaled by profession priority) | Room to improve: the option's levels below `Skills.max_level()`, if the villager has any level in it | Opportunities to improve skills |
| `tenure` (100) | `stay` only: `(day - job_since) / profession_tenure_full` | Professional experience |
| `career_sat` (100) | `stay` only: profession satisfaction | Career satisfaction |

Personal ambition enters by **scaling** `skill` and `growth` with the person's `eff_priority_profession`. No `aspiration`
factor is used here, so the profession ambition is counted once. A survival-pressed villager's profession priority yields
(§4), so need and wage win.

This weighting reproduces FAD's blacksmith: a skilled smith already in hardship may stay rather than take a slightly
better-paid post, while severe hardship still makes the switch more attractive. Skilled trades still cannot be entered
without training (`npc_brain.gd:3854`); no occupation is hard-coded.

`_hiring_competition` (WDR-012-C, owner B18-DP-08) keeps working: the manor's raise feeds `opt.pay`, and so `wage`.

### 6.3 Romantic preferences (FAD Q3): `court_choice`, weighted per individual

**Decision site.** The only NPC partner-selection choice: `Relations._villagers_court` → `JudgmentLive.pick_court`
(`relations.gd:728`, `judgment_live.gd:592-603`), already behind `integration.court_choice`.

**What stays a rule (untouched).**
- `can_court` (`relations.gd:480`): kinship (`Life.kin`), age and existing partners.
- `ask_court` and `propose` thresholds, and `refusal` (`:375`): willing to marry, notoriety, `marry_regard`, rival.
- The pool: villagers only. Singles are NPCs (`relations.gd:698`), so no NPC ever chooses a player.

Players court and propose by their own action, and players' consent is never decided by an NPC (FAD Q3).

**Factors per candidate `x`** (chooser `n`, household `hx`), each from real state:

| Factor | Reads | Weight (base, PROVISIONAL) scaled by |
|---|---|---|
| `attraction` (exists) | `Relations` tie attraction | 500, scaled by `romance` spread |
| `disposition` (exists) | n's own opinion of x | 300 |
| `bond` | Existing relationship: tie `regard` and `days_known` (`Relations.peek`) | 150 |
| `security` | x's household `econ.sustainable` and `econ.days` | 100 × n's `eff_priority_food` |
| `wealth` | x's coins plus `purse(ref of hx)` against n's own (relative, so no fixed requirement) | 100 × n's `eff_priority_wealth` |
| `property` | x's household homes and land (§2 property satisfaction of x) | 100 × n's `eff_priority_property` |
| `stability` | `econ.streak` (0 is best) and x's tenure | 100 × n's `eff_priority_family` |
| `family_compat` | n's personal opinions of x's parents and siblings (personal ledgers only, the mean; members already in `disposition` excluded) | 100 × n's `eff_priority_family` |
| `shared_ambition` | 100000 when x's leading aspiration equals n's; 50000 when either is content; otherwise 0 | 100 |
| `standing` | `standing_excluding(x, n)` (§3) | 100 × n's `eff_priority_standing` |

**Why preferences genuinely differ.** Every weight passes through `trait_weight`'s per-person spread (300 permille,
`judgment_weighting.gd:194`) and then through that person's aspiration priority. One villager is attraction-led; another,
with a high wealth or food priority, weighs security. A villager with a low wealth priority and a strong `bond` overlooks
wealth (FAD Q3).

**No fixed wealth requirement.** Every factor is weighed, never gated. No candidate is removed for being poor.

**Double counting.** `disposition` and `family_compat` read disjoint ledger entries; `standing` excludes the chooser
(§3).

**RNG.** The RNG use is unchanged: the existing `npc_court_chance` roll (`relations.gd:707`) stays as it is. No new RNG
is added.

**Not weighted** (an aspiration is the same for every candidate there): `trade_sell`, `trade_buy_from`, `hire_choice`,
`contract_seller` and `food_seller`. Also not weighted: `befriend` (computed outside `_choose`) and the `family_*`
profiles (§4).

---

## 7. Save data, migration and backward compatibility

**Where.** An optional key `aspire` in the judgment section (`JudgmentStore.to_dict`, `judgment_store.gd:2055`):

```
"aspire": {"v": 1, "domains": ["food","wealth","property","profession","family","standing"],
           "rows": [[person, shift x6, band x6, lead (-1 content, 0..5), lead_since_day, setbacks_packed, surv], ...]}
```

- Rows are sorted by person and written only when non-empty.
- Temperament, satisfaction, standing and pressure are derived, not saved.
- `domains` names the columns, so a later domain is added by name.
- Loading maps columns by name. An unknown name is carried through to the next save and never dropped.

**Version.** `JudgmentStore.VERSION` goes from 2 to 3 (`:78`), written **only when `aspire` is present**.
- With the flag off, saves are byte-identical to today (version 2).
- Builds 19 to 22, meeting version 3, refuse the section and keep it unread (`migrate`, `:2304-2307`, and
  `World.judgment_foreign`). Nothing is silently dropped.
- `World.SAVE_VERSION` (`world.gd:5126`, 23) is unchanged.

**Migration 2 → 3.** Nothing is rewritten. If `aspire` is absent, there are no shifts and `surv` is 0. The first dawn
initialises the bands without counting a crossing. No released save holds a five-domain layout (revision 1 was never
coded), so no 5 → 6 conversion exists. Tests: a version 2 fixture, a version 3 six-domain round trip, and an
unknown-column carry-through.

---

## 8. Determinism and the recorder (R3)

**Determinism.**
- Only integer milli-points and `JudgmentMath.hash_ints` are used. There is no `World.rng`, persons are walked in id order,
  and ledgers are walked sorted.
- `aspire_dawn` runs from one guarded line after `brain.dawn()`, beside `judgment.begin_day` (`world.gd:518`). The order
  matters for `job_choice`: in `brain.dawn`, `evaluate_household` runs at `npc_brain.gd:4441` and `seek_work` at `:4443`.
  The code batch moves the aspiration update between those two lines, as an `aspire_households` call that `brain.dawn`
  makes when the store has aspirations. Satisfaction then reads that morning's `econ`, and `job_choice` sees that
  morning's priorities.

**Recorder.** `world_recorder.gd:1072` `judgment_choice` already writes every factor and weighted contribution. The new
factors (`aspiration`, the job and courting factors) therefore appear with no new hook. The code batch adds:
- `_JSOURCE` entries (`:1069`): `aspiration` → "aspiration"; `standing` → "judgment"; the rest → "world_state".
- Trace extras: `aspiration_domain`, `aspiration_pressure`, `aspiration_fit`, `surv`, and the priority multiplier applied
  to each scaled weight.
- The forgo row's `forgo_aspiration_offset`.
- One event code, `judgment/aspiration` (`game/data/recorder_codes.json`, `recorder_coverage.json`), per priority shift,
  lead change or survival change past `surv_record_step` 250, with its cause.

The recorder stays off by default and draws no RNG. The 10-day fingerprint is the same with and without `--record`.

---

## 9. Flag and tests, mapped to the owner's ten verification bullets

**Flags (all shipped off).** Off until validation and owner review (FAD).
- `aspiration.enabled`: domains, survival pressure, the factor, saving. Effective only with judgment on.
- `decision.integration.job_choice`: requires `aspiration.enabled`. Without it, `stay` and the jobs have no ambition
  scaling, so the flag is refused at load with a logged reason.
- The court factors beyond attraction and disposition are read only when `aspiration.enabled`.

**Dialogue** (FAD Q7) is a later batch, after review: a line from the leading domain through `EventTalk` and
`DialogueVoice`, said once, only to those the villager would tell, never for a goal they do not have.

**`game/tests/aspiration_test.gd`.** Fixture worlds; each check names the bullet it covers.

| # | Owner verification bullet (FAD) | Test |
|---|---|---|
| V1 | Severe hunger and injury alter priorities | Hunger 25 → `surv` 1000, food leads, other domains yield by `yield_d` (stubborn yields less). Health at the floor: the same. After recovery, `surv` falls 200 a day and the earlier lead returns. |
| V2 | Parents keep protecting children when hungry | A family-first fixture: parent hunger 40, child hungrier, pantry short. `family_meal` gives `defer` with aspirations on and off, with identical traces apart from `surv`. `work_accept` is more likely with aspirations on. |
| V3 | A surviving parent does not sacrifice unnecessarily | Parent at hunger 25 or below eats (`self_floor`). Head under `hp_floor` with a threat: the flee option stays available. Neither is changed by `surv` or by a family-led aspiration. |
| V4 | Career ambition without ignoring necessity | Smith-like fixture: a skilled stayer refuses a +10% job; the same villager with `econ.streak` high and few coins switches; an unskilled one switches. Flag off: the live `seek_work` result is identical. |
| V5 | Romantic preferences vary among individuals | Same pool, different choosers: attraction-led, security-led and bond-led pick different partners by seed hash. A poor, well-liked suitor can still win. `can_court` kin pairs are never in the pool. No player is ever chosen. |
| V6 | Stubbornness influences perseverance | Same setback: the stubborn villager's domain priority rises and the adaptive one's falls (faster with wisdom). After 3 setbacks in 8 days the stubborn one reverses. |
| V7 | Standing without double counting | `court_choice` trace: removing the chooser's own ledger on `x` changes only `disposition`, not `standing`. Family colour does not move `standing`. The standing ambition moves `family_help` and `contract_accept` only. |
| V8 | All six domains persist through save and load | Mid-scenario save and load: identical shifts, bands, lead, `surv` and next choices. Version 2 load: no false crossing. Unknown column carried. |
| V9 | Disabled gives the baseline | Flags off: the judgment section has the same bytes (version 2, no `aspire`); every profile's results equal the pre-R5 results; G0 below. |
| V10 | Enabling never creates resources | A 10-day fixture with aspirations on: the currency and item ledger totals equal those of the same trades with the conservation invariant; no coin or item enters through this layer. |

Plus: the five original domains each move only with their fields; neutral = off for §6.1; infeasible is never chosen;
determinism (two runs, identical leads and traces); recorder rows present; heirs' skills start empty and their priorities
come from their own hash.

Suites to rerun in the code batch: `judgment_test`, `judgment_live_test`, `judgment_x19_test`, `family_first_test`,
`relations_test`, `migration_test`, `recorder_test`, `conservation_test`, `judgment_perf`.

**G0 expectation.**
- **Flags off (shipped): identical** to the registered baseline (`tools/sim_gate.py`). No new path runs, no RNG is drawn,
  and the save is unchanged.
- **Flags on: measured, not pass/fail** (WDR-022, FAD Q5), on the four seeds, one run each (SIM-01). It reports leads,
  satisfaction, setbacks and recovery, job choices, courtships, household priorities, economy, contentment and long-term
  outcomes, before any number changes.

---

## 10. Effort and files for the code batch (after R2 and R4)

**Effort.** About **3 to 4 worker-days** with tests (revision 1 estimated 1.5 to 2 days; this revision adds the sixth
domain, survival pressure, `job_choice` and the romance factors).

**Order.** Sequential after R2 and R4, which touch `judgment_live.gd`, `judgment.json`, `judgment_store.gd`;
`npc_brain.gd` too for R2.

| File | Change |
|---|---|
| `judgment/judgment_aspiration.gd` (new, ~450 lines) | Six domains, standing pass, survival level, temperament, shifts, `value()`, `eff_priority`, `aspire_households`, `on_loss`, `on_marriage`, rows |
| `judgment/judgment_weighting.gd` (~25 lines) | Fill `aspiration`; neutral forgo offset; priority scaling in `trait_weight` for profiles with `scaled_by`; skip when off |
| `judgment/judgment_store.gd` (~50 lines) | `asp` member, `aspire` key, VERSION 3 when present, migrate, column mapping |
| `judgment/judgment_live.gd` (~80 lines) | `pick_job`; court factors in `pick_court`; `serves` in `work_refusal`; hooks in `on_death` and `on_marriage` |
| `npc_brain.gd` (~10 lines) | `seek_work` final pick through `pick_job` when the flag is on; `aspire_households` between `:4441` and `:4443` |
| `relations.gd` (0 to 3 lines) | None expected: `pick_court` receives the same pool. Kinship and consent are untouched. |
| `game/data/judgment.json` | `aspiration` section (off, every PROVISIONAL value named); `job_choice` profile; court weights; fit table; `integration.job_choice: false` |
| `recorder/world_recorder.gd`, `game/data/recorder_codes.json`, `recorder_coverage.json` | §8 |
| `game/tests/aspiration_test.gd` (new, ~600 lines); `migration_test.gd` (+3 cases); `judgment_perf.gd` (+1 case) | §9, §11 |
| `docs/SYSTEM_INTERACTION_MANIFEST.md`; `docs/DECISIONS.md` | `INT-###` entries (aspiration → choices; survival → aspiration; standing ← judgment); agent decisions for the values |
| In-game wiki | None while off (WIKI-01). Dialogue and wiki pages come with FAD Q7's later batch. |

---

## 11. Performance estimate

**Per dawn**, with V villagers and H households:
- **Domains:** O(V) reads. Per-household figures (`econ`, homes, plots, goals, purse) are cached once per household per
  dawn. Without the cache, `Property.homes_of` would scan the records for every adult.
- **Standing:** one pass over all personal ledgers, O(L), the same order as one ledger walk in `to_dict` (`:2081-2088`),
  storing per-observer contributions for `standing_excluding`.
- **Survival:** O(V + memories within `danger_days`), using the store's per-observer memory dictionaries.

**Per decision.**
- §6.1: an O(1) lookup of the person's cached lead and pressure.
- `job_choice`: at most 11 candidates for each morning's seeker. There are few seekers: only the unemployed and those in
  unsustainable households.
- `court_choice`: O(pool) × 10 factors, at the existing `npc_court_chance` rate.

**Expected total.**
- Well under 1 ms per game day for the shipped village size (about 60 to 100 villagers, L in the low thousands) on
  desktop. This is an estimate, not a measurement.
- The code batch measures it with `judgment_perf.gd` and the `world.profiling` "daily: brain dawn" slot. Target: at most 5%
  added to that slot. The phone budget is not yet set (CLAUDE.md §8). No per-frame work is added.

---

## 12. Developer notes: the code batch (2026-10-27, base `origin/wip/expansion20` 5770d00)

Implemented on `wip/x20-r5` as designed, with these differences and details. Everything is off by default
(`aspiration.enabled` false, `decision.integration.job_choice` false); with them off nothing below runs and G0 matches.

**Files.**
- `judgment/judgment_aspiration.gd` (new): domains, satisfaction, standing, survival, temperament, shifts, the factor,
  the dawn update, `on_loss`, `on_marriage`, the `aspire` save rows. `JudgmentAspiration.override` lets economy_sim switch it on
  (`--aspiration`, `--job-choice`).
- `judgment/judgment_weighting.gd::_choose`: with the layer on, the five yes-or-forgo profiles gain the `aspiration` weight
  from `aspiration.factor_weights` (not written into the profiles, so the profiles are byte-identical while off);
  `court_choice` takes its weights from `aspiration.court.weights`; weights named in a profile's or the court's `scaled_by`
  are multiplied by the chooser's effective priority. Trace extras: `row.aspiration` {domain, pressure, fit, surv},
  `row.scale` {factor: multiplier}, forgo `forgo_aspiration_offset`.
- `judgment/judgment_store.gd`: member `asp`; a weak reference `world` (set by `JudgmentLive.attach`); optional key
  `aspire`. **Versions:** R4 had already made the section version 3, so the R5 section is **version 4**
  (`ASPIRE_VERSION`), written only when `aspire` has rows; `VERSION` stays 3 (the version written otherwise) and
  `MAX_VERSION` 4 is the newest read. A store with the layer off keeps a loaded `aspire` unread and writes it back.
- `judgment/judgment_live.gd`: `on("job_choice")` refuses unless the layer is on (`push_warning` once); `aspiring`;
  `pick_job`; `court_factors` (used by `pick_court` only with the layer on); `serves` for unpaid work in `work_refusal`;
  `on_death` (loss of a partner, child or parent) and `on_marriage` hooks.
- `npc_brain.gd`: `seek_work` collects the feasible options and, with `job_choice` on, asks `pick_job`; the live
  condition is unchanged otherwise. `dawn` calls `asp.dawn(w)` between the households' evaluation and `succession_dawn`
  / `seek_work`.
- Recorder: `WorldRecorder.aspiration_event` (code `judgment/aspiration`, subsystem added to `recorder_codes.json`;
  coverage row added), `_JSOURCE` entries and the trace extras in `judgment_choice`.

**Differences from sections 2 to 8.**
- **Saved satisfaction.** Each row also saves the morning's satisfaction (`sat`, six values). Decisions all day read it
  (the yes-or-forgo factor, a candidate's property in courting, shared ambition); recomputing it at load would read a
  later world, so a mid-day save would not give the same next choices (V8).
- **Standing computed live.** `standing_value(x, exclude)` walks the observers' ledgers (sorted) at the time it is read
  (each dawn for the villager's own standing; per candidate in courting) instead of a dawn cache of per-observer
  contributions. Same separation, no saved derived state.
- **Row layout.** `[person, shifts[], bands[], sats[], lead, lead_since, setbacks[][], surv]`, each array in the order of
  `domains`; `lead` indexes `domains` (-1 content); `setbacks` per domain are the days of the recent setbacks (at most
  `giveup_after`).
- **job_choice weights.** need_wage 500, tenure 50, career_sat 50 (section 6.2 proposed 300, 100, 100): with the design's
  numbers the stay option of a skilled smith outweighs any hardship, which FAD Q2 rules out. `need_wage` = hardship x the pay
  gain, a gain of `need_gain_full_permille` (10%) counting in full; hardship = max(coin need, `hardship_per_streak_day` x the
  household's unsustainable days). Candidates: the live best, then staying (or staying first when the live rule would not
  switch), then the rest by live score.
- **Court weights.** Applied only with the layer on: attraction 500 and disposition 300 replace the profile's 600 and 400.
- **Satisfaction shapes** (PROVISIONAL, `docs/DECISIONS.md`): property owned 60, leased 40, none 15 points, land +20,
  short goal -20, missing tool -20; family single 15, courting 35 (`Relations.interests`), partnered 60, children 70 or 90
  when sustainable.
- **Survival danger** reads only permanent violence memories (assault, killing), so reading them without a catch-up is exact.

**Tests.** `game/tests/aspiration_test.gd`, one function per owner verification bullet (V1 to V10) plus domains and
neutral, the recorder and determinism. `judgment_x19_test` now tests "a newer game's section" with
`JudgmentStore.MAX_VERSION + 1` (version 4 is readable since R5).

**Not done here.** Dialogue (FAD Q7): the seam is `JudgmentAspiration.lead_of(person)` and `domain_name(d)`; nothing
speaks. No wiki page while the layer is off. Proposal acceptance is unchanged (open question WDR-011-Q8). The four-seed
measurement is R6's.
