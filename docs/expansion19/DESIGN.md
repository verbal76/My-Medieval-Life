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
- **A19-7** (round 2) Records are packed integer arrays; the daily update is sliced with catch-up on touch
  (`memory.dawn_slices`, 24); both proven result-neutral (identical state hashes). `JudgmentStore.timing` measures time
  by part and is never saved or read by the simulation.
- **A19-8** (round 2) The trade hook skips its full scan when the live pick provably wins (`JudgmentLive._first_stands`);
  `JudgmentLive.shortcut` turns it off for comparison.
- **A19-9** (round 3) Word of mouth is queued and told a few meetings a tick, and reads tell first the meetings they
  depend on (`_flush_for`). It is proven result-neutral against telling at once. Settings `gossip.pump_per_tick` (8) and
  `gossip.timing` ("hour"). The `_dry` shortcut cache is never saved and is capped at 20,000 pairs.
- **A19-10** (round 3, an option, not chosen) `gossip.timing` "scheduled" tells each meeting at its own minute. It gives
  smaller frames but different results, so it is left for the lead or the owner to choose.
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

Measured by `game/tests/judgment_perf.gd` on the development container (4-core Xeon 2.8 GHz, Godot 4.7.2 headless,
shared with other agents' runs, so single-hour maxima are noisy): 40 simulated days hour by hour, figures over the last
20. Two event rates: **live**, 0.0064 significant events a person a day (what the live village produced with judgment
on: 7 events in 10 days for about 110 people, `economy_sim.gd --judgment`), and **stress**, 0.5 (about 80 times more).
Each has 4 witnesses; 3 shared hours a person a day (gossip, 7:00 to 21:00); 2 judgment-weighted choices a person a day.

**Proposed budgets** (agent proposal; a mid-range phone assumed about 4 times slower than this machine, not yet
measured on a device): judgment's work in any one frame at most 4 ms on the phone (1 ms here); judgment memory at most
16 MB at 500 people; save section at most 1 MB at 500 people at the live rate; save plus load at most 250 ms added.

Round 2 (`judgment_perf.gd`, the same scenario before and after; **every final state hash is identical before and
after**, so the compaction and slicing changed no result):

| Rate, people | Memory MB (before -> after) | Daily update, largest hour ms (before: one call at dawn -> after: sliced; median day / worst) | Frame: update + events + gossip, largest hour ms (after) | Gossip ms/day (after) | Save KB, save / load ms (after) |
|---|---|---|---|---|---|
| live, 100 | 2.1 -> **0.8** | 1.77 -> **0.11 / 0.17** | 5.4 | 13 | 89, 13 / 14 |
| live, 500 | 10.7 -> **4.0** | 11.38 -> **0.55 / 4.54** (earlier runs of the same code: worst 1.09, 2.02) | 19.1 | 68 | 535, 49 / 72 |
| live, 2000 | 44.1 -> **16.4** | 56.30 -> **2.30 / 5.85** | 45.7 | 251 | 2347, 216 / 278 |
| stress, 100 | 11.5 -> **3.2** | 8.83 -> **0.29 / 0.33** | 9.1 | 49 | 493, 44 / 59 |
| stress, 500 | 57.9 -> **16.1** | 55.37 -> **1.39 / 4.51** | 65.7 | 286 | 2718, 253 / 365 |
| stress, 2000 | 231.9 -> **64.6** | 208.53 -> **6.36 / 15.01** | 227.7 | 1147 | 11713, 1184 / 1980 |

A judgment-weighted choice (`JudgmentWeighting.choose`, three candidates) costs about 85 to 115 microseconds.

Against the budgets:
- **Daily update per frame:** met at the live rate for 100 people (0.17 ms worst, about 0.7 ms on the phone) and, on the
  median day, for 500 (0.55 ms, about 2.2 ms on the phone); the worst single hours at 500 (1.09 to 4.54 ms across runs)
  vary with the shared machine's load, since the deterministic work per hour is a twenty-fourth of 4.7 ms. Not met at
  2000 (median 2.3 ms). If a device check shows the worst hour over budget, `dawn_slice(k)` can run every frame instead
  of every hour, with the same result.
- **Memory:** met at 500 people at both rates (4.0 MB live, 16.1 MB stress).
- **Save:** met at 500 people live (535 KB, 49 / 72 ms); not at stress (2.7 MB).
- **Not met, outside this round's scope: gossip.** `Relations.hour` runs an hour's meetings in one frame, so the hour's
  tellings land together: 19 ms here at 500 people live (about 76 ms on the phone). Next step proposed: queue the hour's
  meetings and tell them in budgeted slices (it changes when word passes, by minutes, so it needs its own equivalence
  argument), and make `tell` cheaper (it is about 45 microseconds a meeting).

### How the two round-2 changes work

- **Compact records.** Facts, memories, contributions and ledgers are `PackedInt64Array` rows (event types and sources by
  index), facts' knowers a sorted packed list, tags and original actors only for events that have them. `fact()`,
  `belief()` and `ledger()` return readable copies. The saved layout is unchanged (`mml-judgment/1`): a round-1 save loads.
- **Sliced daily update.** `begin_day` at dawn does only the global part (old events retire); each person's update
  (fading, forgetting, retiring their records, the optional effective view) runs in `dawn_hour` slices in id order, or the
  moment anything reads or changes that person's records (catch-up on touch). A person's update depends only on their
  own records and the day, so the result is the same however it is sliced: `judgment_test.gd` runs twelve days with
  events, gossip, newcomers and decisions every hour, once with the whole update at dawn and once sliced, and every
  telling, choice, opinion and the end state hash agree (also with retraction, a fading view and distorted rumours on).

### The trade hook in the live village (round 2)

`economy_sim.gd`, 10 days, seed 1, run one after the other (same machine, shared):

| Judgment | Wall time | Leaks | Day-10 fingerprint |
|---|---|---|---|
| off | 72.0 s, 72.8 s | currency 0, items none | `f63a01a0...` (the baseline's) |
| on, round 1 adapter (full scan of buyers every sale) | 89.3 s, 87.7 s, 89.1 s (about +20%) | 0, none | the same |
| on, round 2 adapter (shortcut) | 78.4 s, 73.0 s (about +5%, within the noise of two runs) | 0, none | the same |

The round-2 adapter first finds the live rule's own pick (the same early-exit search the game does with judgment off)
and skips the full scan when that pick must win anyway: under the shipped `trade_sell` profile another buyer can win
only by a disposition advantage worth more than `live_order`'s step, and no one can have a better disposition than the
best the seller holds of anyone. All 32,864 weighed sales in the 10 days took the shortcut; `judgment_live_test.gd`
checks the shortcut picks exactly as the full scan over twelve opinion mixes. Of the 29 to 31 s measured inside the
hook, nearly all is the live buyer search itself (`World.purchase_qty`), which the game pays with judgment off too.
Gossip in the live village cost 0.12 s over the 10 days, the daily update 3 ms.

### Round 3: word of mouth spread over frames

**What changed.** `Relations.share` now queues each meeting (`meet_hourly` -> `meet_later`) and `World.update` tells
`gossip.pump_per_tick` (8) of them each tick (`gossip_tick`). A meeting reads and changes only its two people's records,
so whenever anything reads or changes a person's records, the queued meetings that person depends on are told first:
their last queued meeting and, walking back, every earlier one sharing someone with a meeting already taken (the
dependency closure, `_flush_for`). The meetings left behind share nobody with those taken, so they commute. The result is
the same as telling every meeting at once, as rounds 1 and 2 did, however the pump is paced. Each telling is also
cheaper: settings are cached as integers, there is no string formatting in `interpret`, and `_post` and the candidate
sort work on packed arrays. A "nothing new to tell" shortcut (`_dry`) is never saved and changes no result.

**Proof of identical results.**
- `judgment_test.gd` `test_spread_gossip`: ten days of hourly events, an hour's meetings at once, and six ticks of
  pumping, choices, events and reads between them. Queued and told-at-once give the same tellings (1,933), the same
  opinion, memory count and choice at every read, the same 252 beliefs with provenance and confidence, and the same end
  state hash. This also holds with forgetting that takes points back, a fading opinion view and false rumours on.
  - Turning off the flush on touch makes 8 of these checks fail, so the test does detect a wrong ordering.
- `judgment_perf.gd`: spread and told-at-once give the same end state at 100 and 500 people at both rates.
- Every spread and told-at-once run, at 100, 500 and 2000 people at both rates, ends in exactly round 2's state hash.
- In the live village (`economy_sim --judgment`, 10 days, seed 1), the judgment counts and tellings are the same as in
  round 2 (515 memories, 367 ledgers, 499 tellings).

**Frames.** A frame is one tick, 60 to a game hour. The budget is 1 ms here (4 ms on the assumed 4x phone). These are
percentiles over 28,800 ticks. The machine is shared with other agents, and a tick doing no judgment work at all reached
0.1 to 1.4 ms (the noise floor), so the single worst frame is unreliable; p99 and p99.9 are the figures to read.

| Rate, people | Told at once (rounds 1-2): p99 / p99.9 / worst ms | Spread (round 3, default): p99 / p99.9 / worst ms | Scheduled option: p99 / p99.9 / worst ms |
|---|---|---|---|
| live, 100 | 0.36 / 1.07 / 5.83 | **0.28 / 0.49** / 2.96 | 0.31 / 0.42 / 4.26 |
| live, 500 | 1.03 / 5.66 / 9.30 | **0.87 / 2.15** / 4.16 | 0.62 / 1.25 / 4.40 |
| live, 2000 | - | 2.12 / 11.38 / 21.37 | - |
| stress, 100 | 1.12 / 5.61 / 10.19 | 1.54 / 3.07 / 7.68 | 0.80 / 1.50 / 2.27 |
| stress, 500 | 6.01 / 25.24 / 37.20 | 5.56 / 10.43 / 20.50 | 4.38 / 7.66 / 11.63 |

At 500 people at the live rate, with the default (spread, identical results):
- **99 frames in 100:** within budget, 0.87 ms here, about 3.5 ms on the phone.
- **1 frame in 1000:** not within it, 2.15 ms here, about 8.6 ms on the phone.

Those rare frames are a dependency flush: a villager's decision reads someone whose queued meetings chain through most
of the hour's meetings in a well-connected crowd. The largest flush measured was 83 meetings, 4 to 7 ms here. That flush
is what keeps the result identical, so it cannot be split up. Per day, gossip costs about the same as before (42 ms
spread, 46 ms told at once at 500 people live).

**The scheduled option** (`gossip.timing` "scheduled", off). Each meeting is told at its own minute of the hour (a seeded
hash of the pair and the hour), and nothing has to be told early, so a frame holds only that minute's meetings.
- **Frames:** smallest of the three, 0.62 / 1.25 ms at 500 people live (about 2.5 / 5 ms on the phone).
- **Results:** it changes when word passes within an hour, so they differ from rounds 1 and 2 (for example, 3,073
  memories instead of 3,102 at 500 people live).
- **Save:** meetings still to come are saved (`"scheduled"` in the section).
- **Tests:** it is deterministic and tested (`test_scheduled_gossip`).
- **Decision:** whether to use it is a design decision, so the default stays "hour".

**The live village with the queue on** (`economy_sim`, 10 days, seed 1, run one after the other):

| Judgment | Wall times |
|---|---|
| off | 78.1 s, 77.5 s |
| on | 75.9 s, 75.2 s |

- **Overhead:** within noise, with no leaks and the baseline fingerprint.
- **Gossip:** 0.11 s over the 10 days; the largest flush was 25 meetings in 0.65 ms.
- **Memory:** the store measured 6.1 MB at 500 people live, against 4.0 in round 2. The extra is the shortcut cache
  (capped at 20,000 pairs) and the queue.

### Event feeds not yet wired (listed, not added: they would change live behaviour once judgment is on)

Live code publishes today: the player's thefts and caught pickpocketing (`World.witness`), anyone's attacks including
bandit robberies (`World.raise_alarm`), the player killing a villager (`World.kill`). Missing:
- help: quests done and favours (`Relations.helped`), gifts (`Relations.give`), defending villagers from bandits and
  beasts (`Relations.defended`, the catalog's `rescue`);
- trade: fair dealing and cheating (`World.trade`; `trade_fair`, `trade_cheat`), and the player selling stolen goods
  back to its owner (`World.player_sell`);
- villagers' crimes other than attacks: there is no record of a villager's theft (DVW-B2);
- killings by villagers or bandits (`World.kill` with a villager's name in the cause);
- an unseen theft discovered later ("found missing": no actor is known, so it fits the evidence-discovery path, spec s.6);
- guards' fines as legal facts (SJD-Q08), hoarding in famine, false accusations, and the NEUTRAL meetings and
  marriages (SJD-Q01).

## 8. Integration notes

- `docs/SYSTEM_INTERACTION_MANIFEST.md` gets INT entries for the hooks (witness and alarm -> judgment, shared hours ->
  word of mouth, judgment -> whom a villager sells to) at reconciliation, when ids can be assigned on the Build 18
  baseline without colliding with Build 17 and 18's entries. The hooks are off, so no live interaction exists yet.
- `.github/workflows/tests.yml` lists the three judgment suites on this branch; it runs only on staging pushes.
