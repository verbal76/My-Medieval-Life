# Expansion 19 prospective development: design, decisions and assumptions

PROSPECTIVE work (owner directive `docs/directives/2026-10-21_parallel_prospective_development_18_19.md`, register
PROS-01, PROS-19) on `wip/expansion19-preparation`, branched from staging `b721616` (the released Build 16 plus
records). Nothing here is integrated gameplay, nothing is merged or released, and no open owner question
(SJD-Q01..Q14) is answered: where the code needs an answer it is a parameter in `game/data/judgment.json` with a
**provisional default**, listed in section 5. Source: the Judgment and Decision Engine master spec
(`docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf`, "spec s.N"), gates SJD-C and SJD-D,
and the question analysis `origin/wip/roadmap-docs:docs/roadmap/19_SJD_RECONCILIATION.md`.

## 1. Audit of the live systems (staging `b721616`) and how this work sits beside them

| Live system | What it holds today | How the judgment prototype relates |
|---|---|---|
| `Relations` (`relations.gd`) | One tie per pair: `regard` and `attraction`, 0..100, friendship, courting stage, days known; harm is player-centred (`harmed` lowers villagers' ties with the player, spread to kin and friends at once); ties cool daily | **Kept as the relationships store.** Judgment does not copy it: it reads kinship and friendship through `JudgmentSocial` (the live adapter `JudgmentLive.Social` calls `Relations.friends` and `Life.kin`). Regard and attraction (familiarity, liking, romance) stay distinct from moral judgment (spec invariant 7). |
| `NPC.memory` | At most 8 free-text lines ("saw ...", "met ..."), shown to the player | Untouched. Judgment memories are structured (event id, type, actors, provenance, confidence, salience) and live in `JudgmentStore`; a later reconciliation can render them as the text lines (GM-01). |
| `World.witness`, `aware_of_attack`, `raise_alarm`, `report_crime` (PAR-05, PICK-01) | Who sees a theft or an attack (sight within `witness_radius`), guards' response, reports | The **observation source**. With judgment attached, the same `seen` list becomes witnesses of a published event (`JudgmentLive.on_theft`, `on_attack`); nothing about who sees, or the guards' response, changes. |
| `NPCBrain.decide` and the trade searches (`_buyer_for`, `_seller_of`) | Rule-based priority order; the first feasible counterparty in villager order | **The decision authority stays here.** Judgment never decides: `JudgmentWeighting.choose` ranks the candidates the live code already found feasible, with judgment one weighted factor (spec s.7). The one prototype hook (`_buyer_for`) is off unless judgment is attached. |
| CRT-12 notoriety (`Relations.notoriety`, `refusal`) | A threshold over crimes seen and killings | A recorded conflict (EXP-C): judgment would replace the threshold with a weighed factor. **Not touched** here (Gate E, SJD-Q14). |
| Save (`World.to_dict`, `SAVE_VERSION` 16) | One dictionary | A provisional `"judgment"` section, written only when a store is attached; `SAVE_VERSION` unchanged; a Build 16 save has no section and loads an empty store. |

No parallel decision engine and no second relationships store: the judgment code owns only what nothing owns
today (events as facts, beliefs with provenance, GOOD/BAD contributions and ledgers).

## 2. Modules (all new, `game/scripts/core/judgment/`)

- `JudgmentMath`: integer milli-points and permille, rounding half away from zero, and a seeded FNV hash for every
  random choice (no `World.rng` draw, so existing random streams never shift when judgment is on).
- `JudgmentSocial`: the read-only adapter contract for kinship and friendship, and the test fixture.
- `JudgmentStore`: event catalog (from `judgment.json`), facts, memories, contributions, ledgers, interpretation,
  information sharing (`meet`, `tell`), daily fading and expiry, inspection, save and migration.
- `JudgmentWeighting`: the utility term that combines need and judgment for candidates supplied by live code, with
  explanation traces.
- `JudgmentLive`: the live adapter (World hooks, the `Social` view of the live world, the trade-choice prototype).

## 3. The model (spec s.4-s.7, as implemented)

1. **Facts.** `publish(type, actors, victims, beneficiaries, value, tags)`; immutable; a mistake is corrected by
   `revise_fact`, which keeps the original actors and counts a revision (spec s.3.1).
2. **Beliefs with provenance.** Each person's memory of an event: actors as believed, source (`participant`,
   `witnessed`, `told`, `rumour`), who told them, hops from a firsthand source, confidence, salience.
3. **Interpretation** P in [-1, +1] (permille), hierarchical: the affected party (victim of a BAD event, beneficiary
   of a GOOD one) reads it at `affected`; an accomplice at `accomplice`; others by their tie to the affected party:
   kin, friend, else bystander, reversed to `rival` when they judge the affected party at or below `rival_net_at`;
   loyalty to the actor (kin, friend) softens condemnation; on events marked ambiguous only, prior judgment of the
   actor biases P, capped. The parts are kept for diagnostics (`last_trace`).
4. **Contribution** I = S x P x C (confidence policy), split by actor share; I >= 0 adds to the baseline's ledger,
   I < 0 to the other; contributions are never negative; one active contribution per observer, actor and event,
   replaced by difference, so repeats and corrections never double count (spec s.5.1).
5. **Ledgers** observer -> subject: lifetime GOOD, BAD, contribution count, and an effective view that fades only
   if `effective_fade_permille` > 0 (default 0). NET = GOOD - BAD.
6. **Memory bounds.** `capacity` memories a person; salience = severity x confidence, fading `salience_fade_permille`
   a day; forgotten under `forget_below`; events at `permanent_severity` (killing) never fade. Forgetting keeps the
   points (`retract_on_forget` false). Events retire after `horizon_days`: past it nobody can tell or correct them,
   and their dedup keys go with the fact, which bounds memory use while keeping invariant 4.
7. **Sharing.** When two people spend time together each may tell the other their most salient memories the other
   lacks: per meeting and per day budgets, only to someone they judge above `share_net_at`, at most `max_hops`,
   never under `min_confidence`, never about the listener's own deed. Confidence falls by `hop_factor` and the
   listener's credibility of the teller (their judgment of the teller). Optional distortion: a seeded chance that a
   rumour names the teller's most disliked person (`misattribute_permille`, default 0); learning the truth reverses it.
8. **Decision weighting.** `JudgmentWeighting.choose(store, cfg, chooser, profile, candidates)`: the live code
   supplies feasible candidates and factors (0..100 points in milli); `disposition` = 50 + NET clamped to 0..100
   (reproduces the spec's -6.59 -> 43.41 and 81.841 exactly), `sole_source`, `ambivalence` filled in; utility =
   sum(weight x factor); `forgo` is the utility of doing without. An infeasible candidate is never chosen. Judgment's
   whole range moves a choice by at most its weight (10 points in `trade_buy`), so need, price or scarcity can
   outweigh it, and it can tip a close one.

## 4. Agent decisions (implementation details, provisional)

- **A19-1** Integer milli-points and permille everywhere (spec s.5.1 recommends it): exact replay and save text.
- **A19-2** All randomness by seeded hash of ids (`JudgmentMath.hash_ints`), never `World.rng` (spec s.13, s.16): a
  matched-seed comparison of judgment on and off differs only by what judgment itself changes.
- **A19-3** Separate config file `game/data/judgment.json` (`mml-judgment/1`), not `balance.json`, so the prototype
  changes no live data file.
- **A19-4** Event horizon (`horizon_days`, 30) bounds facts and dedup keys; a provisional engineering bound, not a
  gameplay rule (an event older than the horizon can no longer spread).
- **A19-5** Save section format `mml-judgment/1` with its own version and a migration function; a section the game
  cannot read is kept and written back unchanged (CLAUDE.md section 7).
- **A19-6** Live hooks are guarded by `World.judgment != null`; it is null unless `judgment.json` `enabled` is true
  (false) or a test attaches a store. With it null, no hook runs any code beyond the null check.

## 5. Owner questions: provisional defaults and what they block

None is answered. Each is a parameter; the default is what the isolated tests run with, labelled provisional.

| Question | Parameter(s) | Provisional default | Blocks live integration? |
|---|---|---|---|
| SJD-Q01 NEUTRAL events | `neutral_events` | false (owner's GOOD/BAD rule; NEUTRAL types exist, refused) | Yes (event schema, Gate C per the reconciliation) |
| SJD-Q02 decay | `memory.retract_on_forget`, `memory.effective_fade_permille` | no retraction, no fade (lifetime totals; only memory detail fades) | Yes |
| SJD-Q03 thresholds | one ledger scale; `decision.trait_spread_permille` | one scale, spread 0 | No (tunable) |
| SJD-Q04 ambivalence | `ambivalence` factor weight | stored, weight 0 | No (tunable) |
| SJD-Q05 prior bias | `interpret.prior_bias_*` | ambiguous events only, 0.01 per point, cap 0.15, never for the affected | No (tunable; spec approves a capped bias) |
| SJD-Q06 confidence | `belief.confidence_policy`, `confidence_threshold` | multiplier, with a separate belief layer | Yes |
| SJD-Q07 gossip reach | `gossip.*` | 2 a meeting, 6 a day, 3 hops, credibility by judgment | Yes for replacing `Relations.harmed`'s instant spread |
| SJD-Q08 law, morality, loyalty | `interpret.kin_of_actor`, `friend_of_actor` | loyalty softens condemnation (0.4, 0.7); legal status not modelled | Yes |
| SJD-Q09 best or near-best | `decision.selection`, `margin` | argmax (margin implemented and tested) | No (tunable) |
| SJD-Q10 player visibility | none (developer `inspect` and `explain` only) | nothing shown to the player | Yes |
| SJD-Q11 persistence by severity | `memory.permanent_severity`, `salience_fade_permille` | killings permanent, others fade | Yes |
| SJD-Q12 what is scored | catalog, `min_value` | the spec's seed severities; min_value 0 | No (tunable) |
| SJD-Q13 weights | `decision.profiles`, `trait_spread_permille` | data profiles; no run-time learning | No (data); yes if learning is wanted |
| SJD-Q14 first domain | the `_buyer_for` prototype hook (`trade_sell`: live order 0.4, need for coin 0.3, disposition 0.15, price 0) | trade (the reconciliation's recommendation), off | Yes |

Also open from the reconciliation: **Q19-0**, whether the owner accepts the TUNABLE/OWNER split this table uses.

## 6. Assumptions

- Kinship is `Life.kin` plus partners; friendship is `Relations.friends`. Regard is not used as judgment.
- The player is one more id (`Life.PLAYER_ID`): deeds by the player and by villagers are judged by the same rules
  (tested). Villagers' deeds are not yet published by live code (there is no NPC crime record; DVW-B2).
- Severity is not money (spec s.3): `value` only gates significance.

## 7. Performance and proposed budgets (spec s.13; CLAUDE.md section 8)

Measured by `game/tests/judgment_perf.gd` (40 simulated days, figures averaged over the last 20) on the development
container (4-core Xeon 2.8 GHz, Godot 4.7.2 headless). Synthetic load: **0.5 significant events a person a day** with 4
witnesses each, 3 shared hours a person a day (gossip), 2 judgment-weighted trade choices a person a day. That is about
80 times what the live village produced with judgment on (7 events in 10 days for about 110 people,
`economy_sim.gd --judgment`), so these are upper-bound stress figures.

| People | ms per simulated day (events / gossip / decisions / dawn) | Dawn, one call | Memory | Save | Save / load |
|---|---|---|---|---|---|
| 100 | 143 (30 / 92 / 16 / 5) | 5 ms | 11.6 MB | 0.5 MB | 65 / 78 ms |
| 500 | 815 (177 / 521 / 88 / 29) | 29 ms | 58 MB | 2.7 MB | 375 / 401 ms |
| 2000 | 3199 (705 / 2028 / 343 / 123) | 123 ms | 232 MB | 11.7 MB | 1673 / 1638 ms |

Scaling is linear in people (bounded memories, horizon-bounded facts); ledgers grow with how many people each person
hears of (72 a person here). A game day is 12 real minutes, so the daily total is small spread over a day; the risks are
the dawn spike and memory.

**Proposed budgets** (agent proposal, for the owner; a mid-range phone assumed about 4 times slower than this machine,
not yet measured on a device): at the village's size (about 110 people) and at 500, on the phone, judgment's work
within one frame at most 4 ms (so: the dawn's fade spread over the day's hours once over it), total judgment memory at
most 16 MB at 500 people at the live event rate, save section at most 1 MB at 500 people, save and load at most 250 ms
added. At the stress rate the prototype already meets the frame budget for 100 people (dawn 5 ms here, about 20 ms on
the phone: over, so the fade must be spread), and not for 500 or 2000; at the live rate (80 times fewer events) all
three sizes are within the memory and save budgets by extrapolation (not measured). Optimisations ready if needed:
spread `advance_day` over hours (spec s.13 "budgeted processing"), memories as packed arrays instead of dictionaries,
a per-person cap on ledgers kept (least significant first; an owner question as it forgets judgments), gossip
candidates kept sorted.

## 8. Integration notes

- `docs/SYSTEM_INTERACTION_MANIFEST.md` gets INT entries for the hooks (witness and alarm -> judgment, shared hours ->
  word of mouth, judgment -> whom a villager sells to) at reconciliation, when ids can be assigned on the Build 18
  baseline without colliding with Build 17 and 18's entries. The hooks are off, so no live interaction exists yet.
- `.github/workflows/tests.yml` lists the three judgment suites on this branch; it runs only on staging pushes.
