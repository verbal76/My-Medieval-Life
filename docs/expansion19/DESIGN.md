# Expansion 19 prospective development: design, decisions and assumptions

PROSPECTIVE work (owner directive `docs/directives/2026-10-21_parallel_prospective_development_18_19.md`, register
PROS-01, PROS-19) on `wip/expansion19-preparation`, branched from staging `b721616` (the released Build 16 plus
records). Nothing here is integrated gameplay, and nothing is merged or released. **The owner answered SJD-Q01, Q02,
Q06, Q07, Q08, Q10, Q11 and Q14 on 2026-10-21** (`docs/directives/2026-10-21_expansion19_sjd_final_decisions.md`,
on staging): their rules are in section 5 and implemented in round 4. Q03, Q04, Q05, Q09, Q12 and Q13 stay
provisional. **X19-Q-TIMING was answered 2026-10-23** (gossip spreads organically by contact and closeness): `gossip.timing` is now "scheduled" with closeness weighting (A19-12, section 15a). Where code needs a number the owner did not
set, it is a parameter in `game/data/judgment.json` with a proposed value (section 5a). Source: the Judgment and Decision Engine master spec
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
   loyalty to the actor (kin, friend) softens condemnation; prior judgment of the actor never colours the reading
   (SJD-Q05, "Not at all"). The parts are kept for diagnostics (`last_trace`).
4. **Contribution** I = S x P x C (confidence policy), split by actor share; I >= 0 adds to the baseline's ledger,
   I < 0 to the other; contributions are never negative; one active contribution per observer, actor and event,
   replaced by difference, so repeats and corrections never double count (spec s.5.1).
5. **Ledgers** (round 4, Q02) observer -> subject: lifetime GOOD and BAD (history, never decay), the contribution
   count, a fading part (GOOD, BAD; decays at `decay.ordinary_permille_per_day`) and a permanent part (GOOD, BAD; from
   a murder, never decays). NET = (fading + permanent GOOD) - (fading + permanent BAD). A contribution goes to the part
   its event type sets, so a correction or retraction comes off the same part.
6. **Memory** (round 4, Q11). Ordinary memories: `capacity` a person; salience = severity x confidence, fading
   `salience_fade_permille` a day; forgotten under `forget_below`. Permanent memories never fade, are never pushed out
   and are not counted in `capacity`: a murder always, anything at `permanent_severity`, and for the one it happened
   to anything at `permanent_personal_severity`. Forgetting keeps the judgment, which then fades by decay. Ordinary
   events retire after `horizon_days`; permanent records (a murder, or any fact someone remembers permanently) never do.
7. **Sharing** (round 4, Q06, Q07). Only when two people actually spend time together (Relations' shared hours, told a
   few a tick, round 3). Each may tell the other up to `per_meeting` of their most salient memories the other does not
   hold or holds less surely, within the teller's `daily_budget`, only to someone they judge above `share_net_at`,
   never about the listener's own deed. There is **no hop limit and no confidence floor**. Confidence = the teller's x
   `hop_factor` x credibility. Credibility is the listener's trust in the immediate teller (`trust_of`, its own value since X19-REGARD, section 15b; starting
   as a first impression of Relations regard), `credibility_stranger` at trust 0, up to 1000 at 100, moved a little by their judgment of the teller. Along a
   chain it is the product of the links. Each person judges an event once. A belief is replaced only by a strictly more
   confident telling, which updates its contribution in place. An ordinary story travels until it is too faint to
   remember (salience = severity x confidence); a murder, never forgotten, travels as far as meetings carry it (tested
   over 39 links). Optional distortion: a seeded chance that a rumour names the teller's most disliked person
   (`misattribute_permille`, default 0); learning the truth reverses it.
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
- **A19-10** (round 3 option, **chosen 2026-10-23**, owner answer X19-Q-TIMING) `gossip.timing` "scheduled" tells each
  meeting at its own minute. It gives smaller frames and different results from "hour", which stays as the reference mode.
- **A19-11** (round 4) A belief is replaced only by a strictly more confident telling (Q06 updates). Together with the
  per-event knowers this bounds processing without a hop limit (Q07). The round-3 "nothing new to tell" cache was
  removed because trust can change.
- **A19-12** (round 4) Decay of a fading part takes at least 0.001 point a day while anything is left, so remainders
  fade out instead of sticking at the rounding threshold.
- **A19-13** (round 4) Q14 adapters use the live order as a factor, so with neutral judgments every decision point
  makes exactly the live choice. Each point has its own `decision.integration` flag.
- **A19-6** Live hooks are guarded by `World.judgment != null`; it is null unless `judgment.json` `enabled` is true
  (false) or a test attaches a store. With it null, no hook runs any code beyond the null check.

## 5. Owner questions

### 5.1 OWNER ANSWERED (2026-10-21; rules quoted in short, the directive is the record)

| Question | Owner's rule | Implemented in round 4 (tests) | Pending |
|---|---|---|---|
| SJD-Q01 facts and zero | "An event is a fact"; each observer may assign "positive, negative, or zero"; zero needs no third ledger; facts may still be "remembered, discussed, and used"; no automatic moral significance for ordinary facts | NEUTRAL facts are always recorded, remembered and told; P = 0 posts nothing; a NEUTRAL type scores only by an optional per-observer `personal` rule, none set (`test_q01_facts_and_zero`, with the owner's marriage example as a fixture rule) | Which NEUTRAL types, if any, get personal rules (content, not code) |
| SJD-Q02 decay | Ordinary judgments "fade very slowly"; "Murder is a permanent exception"; for players and NPCs alike; keep provenance so both coexist; propose a conservative rate and demonstrate it, not silently chosen | Fading and permanent parts in every ledger, routed by event type; lifetime totals kept; decay daily on the fading parts only (`test_q02_decay_and_murder`; the 365-day demonstration, section 11) | **The rate**: 3 permille a day is PROPOSED, unapproved |
| SJD-Q06 confidence and trust | Confidence from "how much that listener trusts the person telling the story"; "the existing friendship or relationship number must influence" it; firsthand distinct; chains reflect transmission; never re-award on re-hearing; update the existing belief | Credibility from Relations regard (no second friendship system); witnesses firsthand; product along the chain; re-hearing ignored; a more credible telling replaces the belief and its contribution (`test_q06_trust`, `test_q06_live_trust`) | The numbers (`credibility_stranger` 500, `hop_factor` 900, judgment adjustment 10 a point) are proposals |
| SJD-Q07 gossip reach | "Remove the fixed maximum number of retellings"; spread only through "real conversations and encounters"; no broadcast or teleportation; exchange limits per conversation may remain; no loops, duplicates or unlimited processing | `max_hops` and `min_confidence` removed; `per_meeting` and `daily_budget` kept; dedup by event identity (knowers) and strictly-increasing confidence (`test_q07_no_hop_limit`: a murder 39 links down a line, one meeting a day, each person judged once, processing ends, nobody hears without a meeting) | The live `Relations.harmed` instant spread conflicts (section 10) |
| SJD-Q08 morality, loyalty, law | Interpretation from "personal morality, relationships, loyalties, and the people affected"; "The legal system is separate"; keep crime reporting and guards; "Do not create a second legal system" | Personal morality per person and family of deeds (`morality_spread_permille`, proposal 150), kin and friend loyalty, ties to victims and beneficiaries, rivals; nothing legal in the store (`test_q08_morality`) | CRT-06's friendly guard (section 10) |
| SJD-Q10 what the player sees | No exact numbers in normal gameplay; attitudes through behaviour; numbers stay in developer diagnostics | No UI script reads judgment (`test_q10_no_numbers_in_ui`); refusals are words; `inspect` and `explain` remain | Player-facing words for attitudes, when judgment goes live (Gate E) |
| SJD-Q11 permanent memories | Murder permanent; other significant events by configurable severity and personal significance; not the ordinary horizon; survive save, load and compaction; ordinary memory bounded | Permanent memory flag, outside capacity, never fades; facts of permanent memories never retire; saved and reloaded (`test_q11_permanent_memories`; perf: ordinary memory within 24 at every size) | `permanent_personal_severity` 2000 (being assaulted or rescued oneself) is a proposal |
| SJD-Q14 universal integration | Judgment influences "every applicable NPC decision"; existing decision authority remains; "shared weighting and evaluation interfaces"; never override feasibility or conservation; staged; document unsupported domains | Six existing decision points through `JudgmentWeighting` (section 9), each behind the off switch, each tested both ways | Further domains (section 9.2); CON-01 on Build 17 |

### 5.2 Answered 2026-10-23 (directives `2026-10-23_owner_answers_build19_sjd.md`, `..._x19_assault_crt12_decay.md`, `..._x19_guard_harmed_timing_regard.md`)

| Question | Owner's answer | State in the prototype |
|---|---|---|
| SJD-Q03 thresholds | Own tolerance each: personality-based, seeded at birth | **wired (round 7)**: each person has a tolerance (1000 +/- 300 permille, a hash of world seed and id) that scales the two NET thresholds (`interpret.rival_net_at`, `gossip.share_net_at`); see section 15c. Numbers are agent proposals |
| SJD-Q04 mixed feelings | Yes: wary but willing; payment up front, gossip, can swing either way | partly matches: large GOOD and BAD give `ambivalence` (stored, weight 0); net near zero reads as disposition 50, so the person is willing and still gossips (share_net_at is a NET test); "payment up front" is a live trade-terms change, not made (needs a gameplay choice, reported) |
| SJD-Q05 prior opinion | "Not at all": every event judged on its own | **changed**: prior bias and the `ambiguous` flag removed from code and config (`test_prior_bias`) |
| SJD-Q09 best or near-best | Usually the best, occasionally a close second, seeded and repeatable | **changed**: `selection` "margin" with `runner_up_permille` 150 (AGENT-PROPOSED): the best, except that seeded 15% of the time one of the others within `margin` (2 points) (`test_selection_policies`) |
| SJD-Q12 which events count | Affects them, kin or property, plus witnessed crimes and kindnesses; trivia ignored | already matches: the catalog holds only significant deeds; observers are the affected (victim, property owner, beneficiary), witnesses, and those told (kin and friends by the tie rules); fair trade and meetings carry no moral score; `min_value` is a per-type threshold (0 now, so any theft counts) |
| SJD-Q13 weights | Born with + shaped by life | not yet wired (profiles are data, no learning) |
| X19-ASSAULT | Permanent | **changed**: `events.assault.permanent` true: memories never fade for anyone, judgments never decay (`test_x19_assault_permanent`) |
| X19-GUARD | Reduce, never waive | APPLIED in live code (`World.guard_confront`): a friend guard halves the fine, a friend nearby halves it again, always at least 1 coin (agent proposal for the amount, `docs/DECISIONS.md`); outside the judgment (section 10.3) |
| X19-REGARD | Separate them: liking and trust tracked apart | **changed**: a separate trust value in the store (section 15b); regard stays liking and gossip closeness (`test_x19_regard`) |
| X19-HARMED | Keep instant | already matches: `Relations.harmed` unchanged |
| X19-CRT12 | Keep fixed cut-offs | already matches: `Relations.refusal` and `marry_regard` unchanged |
| X19-DECAY | Half-life 2 game years (16 days), on each deed's ledger contribution | not touched here (decay rate stays the proposed 3 permille a day until the lead sets it) |

Old section 5.2 (still provisional) is superseded by this table.

### 5a. Reconciliation of every judgment.json setting and code path with the decisions

Classes: **config** (a value only), **code** (code changed in round 4), **integration** (needs an existing decision
system to call the shared interface).

| Setting or code path | Decision | Class | State |
|---|---|---|---|
| `neutral_events` (removed) | Q01 | code | NEUTRAL facts always recorded |
| `events.*.personal` | Q01 | config | none set (no automatic moral meaning) |
| `events.killing.permanent` | Q02, Q11 | config + code | murder: permanent memory and never-decaying judgment |
| `events.*` severities, `min_value` | Q12 | config | answered; seed severities |
| `events.assault.permanent` | X19-ASSAULT | config | true (like murder) |
| `interpret.affected/kin/friend/bystander/rival/accomplice`, `kin_of_actor`, `friend_of_actor` | Q08 | config | proposals implementing the owner's rule |
| `interpret.morality_spread_permille` | Q08 | code + config | new; 150 proposed |
| `interpret.prior_bias_*`, `events.*.ambiguous` (removed) | Q05 | code + config | none: every event judged on its own |
| `personality.*`, `decision.trait_spread_permille` | Q03, Q13 | code + config | spread 300 each, steps 40 and 30 per point, bound 250: all proposed (section 15c) |
| `decision.selection`, `margin`, `runner_up_permille` | Q09 | code + config | margin; 150 agent-proposed |
| `belief.credibility_stranger`, `credibility_permille_per_point`, `credibility_min` (replacing `credibility_base`) | Q06 | code + config | credibility from Relations regard |
| `belief.hop_factor` | Q06 | config | 900 proposed (loss per retelling) |
| `belief.confidence_policy`, `confidence_threshold` | Q06 | config | multiplier |
| `gossip.max_hops`, `gossip.min_confidence` (removed) | Q07 | code | no hop limit, no floor |
| `gossip.per_meeting`, `daily_budget` | Q07 | config | kept as exchange limits |
| `gossip.share_net_at`, `misattribute_permille` | Q07 | config | proposals (0: no distortion) |
| `gossip.pump_per_tick` (hour mode only), `timing` | X19-Q-TIMING | config | "scheduled" |
| `gossip.closeness_floor_permille` | X19-Q-TIMING (closeness) | config, agent-proposed, awaiting review | 500 |
| `memory.effective_fade_permille` (removed) -> `decay.ordinary_permille_per_day` | Q02 | code + config | 3 proposed, unapproved |
| `memory.permanent_severity`, `permanent_personal_severity` | Q11 | code + config | 3000; 2000 proposed |
| `memory.capacity`, `salience_fade_permille`, `forget_below`, `horizon_days` | Q11 | config | ordinary memory only |
| `memory.retract_on_forget` | Q02 | config | false (judgment fades by decay instead) |
| `decision.profiles.*`, `integration.*` | Q14 | integration | six points wired (section 9) |
| `JudgmentStore.inspect`, `JudgmentWeighting.explain` | Q10 | code | developer only |
| `NPCBrain._buyer_for`, `_seller_of` | Q14 | integration | wired, off |
| `Construction._keep_building`, `Construction.hire`, `Business.hire` | Q14 | integration | wired, off |
| `Relations._befriend_if_close`, `_villagers_court` | Q14 | integration | wired, off |
| `Relations.harmed`, `notoriety`, `refusal` (CRT-10, CRT-12), `World.guard_confront` (CRT-06) | Q07, Q08, Q14 | integration (conflict) | not changed (section 10) |

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

**The scheduled model** (`gossip.timing` "scheduled", the live setting since 2026-10-23; section 15a). Each meeting is told at its own minute of the hour (a seeded
hash of the pair and the hour), and nothing has to be told early, so a frame holds only that minute's meetings.
- **Frames:** smallest of the three, 0.62 / 1.25 ms at 500 people live (about 2.5 / 5 ms on the phone).
- **Results:** it changes when word passes within an hour, so they differ from rounds 1 and 2 (for example, 3,073
  memories instead of 3,102 at 500 people live).
- **Save:** meetings still to come are saved (`"scheduled"` in the section).
- **Tests:** it is deterministic and tested (`test_scheduled_gossip`).
- **Decision:** the owner chose it (X19-Q-TIMING, 2026-10-23).

**The live village with the queue on** (`economy_sim`, 10 days, seed 1, run one after the other):

| Judgment | Wall times |
|---|---|
| off | 78.1 s, 77.5 s |
| on | 75.9 s, 75.2 s |

- **Overhead:** within noise, with no leaks and the baseline fingerprint.
- **Gossip:** 0.11 s over the 10 days; the largest flush was 25 meetings in 0.65 ms.
- **Memory:** the store measured 6.1 MB at 500 people live, against 4.0 in round 2. The extra is the shortcut cache
  (capped at 20,000 pairs) and the queue.

### Event feeds: wired in round 8 (see section 9.3)

Round 1 published the player's thefts and caught pickpocketing (`World.witness`), anyone's attacks including bandit
robberies as assaults (`World.raise_alarm`) and the player killing a villager (`World.kill`). The other catalog events are
now fed from the live acts that perform them (section 9.3); what has no act is listed there.

## 8. Integration notes

- `docs/SYSTEM_INTERACTION_MANIFEST.md` gets INT entries for the hooks (witness and alarm -> judgment, shared hours ->
  word of mouth, judgment -> whom a villager sells to) at reconciliation, when ids can be assigned on the Build 18
  baseline without colliding with Build 17 and 18's entries. The hooks are off, so no live interaction exists yet.
- `.github/workflows/tests.yml` lists the three judgment suites on this branch; it runs only on staging pushes.

## 9. Q14: universal integration plan and status (round 4; stage 2 in round 9)

### 9.1 Wired (each behind the off switch: a store attached and `decision.integration.<point>` set)

All go through the one shared interface (`JudgmentWeighting.choose`), with adapters in `JudgmentLive`. The existing
code still decides who is feasible; with every judgment neutral the live choice stands.

| Decision point (existing code) | What judgment weighs | Tests: judgment changes it / other factors outweigh it / feasibility |
|---|---|---|
| Whom a villager sells to (`NPCBrain._buyer_for`) | live order, need for coin, the seller's judgment of each buyer | avoids a disliked buyer when another can buy; still sells when every buyer is disliked; never outside the live buyers |
| Whom a household buys timber from (`NPCBrain._seller_of`) | live order, the buyer's judgment | goes to the other seller with logs; the only seller left is used despite dislike; no seller with logs, no purchase however liked |
| Whom a building household hires (`Construction._keep_building`) | live order, the household head's judgment; only those who would take the work | hires another; disliking everyone still hires; never someone who cannot be hired or would refuse |
| Whether a villager takes work (`Construction.hire`, `Business.hire`, for the player and for households alike) | need for coin, the wage, the worker's judgment of the employer, against doing without | a villager with coin refuses a disliked employer (in words); the same villager with no coin accepts; a neutral one does an unpaid favour |
| Whether two villagers become friends (`Relations._befriend_if_close`) | closeness (regard) and the lower of their two judgments, at the live threshold | a dislike holds back a just-close-enough friendship; great closeness outweighs it; a high opinion never befriends below the threshold |
| Whom a single villager courts (`Relations._villagers_court`) | attraction and the villager's judgment, among the live candidates | the slightly less attractive but not disliked one; much greater attraction outweighs dislike; no candidate, no interest |

Stage 2 (round 9) wires six more, on the same interface (`JudgmentLive.willing` for a yes or no, `_pick`/`seller_order`/
`pick_food_seller` for a choice). Each is behind its own `decision.integration` flag and a store; the live code still
decides feasibility, amounts, prices and terms. A "willing" hook asks only whether the person who could do it does so:
the live yes (live_order, 100 points) plus their need for coin (under 50 coins) and what they think of the other, against
doing without (forgo 20 points), so with neutral judgment every personality says yes (tested for every adult), a person
with coin to spare who strongly dislikes the other says no in words (no numbers: Q10), and need outweighs dislike.

| Decision point (existing code) | What judgment weighs | Tests |
|---|---|---|
| Whether a seller takes on a contract or service (`Contracts.evaluate`, `contract_accept`) | need for coin, the seller's judgment of the buyer (a player, a villager, a household's responsible adult; the manor is no person and is not judged); asked only after the offer is feasible | neutral: the live answer word for word; a disliked player is refused ("I'd rather not take work from you") by a seller with coin and accepted by one without; an infeasible offer keeps its own reason; the manor is not judged |
| Which seller a villager buyer asks first (`Contracts._order`, the prospector's kit order in `Prospecting`; `contract_seller`) | live order, the buyer's judgment | neutral: live order; a disliked first seller is asked second, nobody is dropped (the rest keep the live order, so a refusal still falls through); a single seller is asked regardless |
| Whether a villager sells on credit (`Credit.credit_refusal`, `credit_lend`) | need for coin, the creditor's judgment of the debtor, after trust (regard), limit, old debts and reserve | neutral: lends; disliked: "would rather not lend" (player or villager buyer); nothing moves, no debt |
| Whether a villager takes a swap (`Credit.barter_quote`, `barter_accept`) | same | neutral: swaps; disliked: "would rather not swap" |
| Whom a short household asks for food (`Credit._cheapest_food`, `food_seller`) | live order (cheapest per food point, a villager before the player on a tie), the member's judgment of each neighbour | neutral: the cheapest; a disliked cheapest is passed over for the next; the only neighbour with food is asked anyway; none, no ask |
| Whether a relative household gives toward a home (`Construction._family_help`, `family_help`) | the relative household's responsible adult's judgment of the builder; amount and means unchanged | neutral: gives; strongly disliked: gives nothing, no coin made or lost; neutral again: gives |

Not changed by design: **Q04** mixed feelings are "wary but willing" (ambivalence is stored with weight 0 in every profile):
a person who feels both ways is not made to refuse; asking for payment up front would be a trade-terms choice the owner has
not made, so it is NOT added. **Q08**: none of these hooks decides whether a law applies, and the guard's fine stays X19-GUARD's.
**X19-CRT12**: courtship refusals keep the fixed cut-offs (courtship stays `court_choice` among those the cut-offs allow).
**X19-HARMED**: `Relations.harmed` unchanged. The buyer's answer to a counter (`Contracts.buyer_answer`) is not wired: it
is a calculation of terms within the buyer's tolerance, not a choice among options, and moving prices by opinion would be a
trade-terms choice (as for Q04).

With judgment on for 10 village days (`economy_sim --judgment`, seed 1) there were no currency or item leaks (section 12).

### 9.2 Not wired yet, and why

| Domain (owner's list) | Status | Dependency |
|---|---|---|
| Negotiated contracts and services | wired in round 9 (`contract_accept`, `contract_seller`, section 9.1); the breach feed (`trade_cheat`) was wired in round 8 | `buyer_answer` (terms tolerance) is not a choice and stays the live rule's |
| Business relationships (stall custom, supplier loyalty) | partly: trade choices above, credit and swaps (`credit_lend`, `barter_accept`), whom a short household asks (`food_seller`) | Expansion 18 settlement trade and the Living Economy actors (proposed Build 20) have no decision point yet |
| Requests for favours, cooperation and assistance | relatives' house help wired in round 9 (`family_help`); food relief and alms: no decision point | relief and alms are the manor's and the chapel's (institutions, no personal judgment); a villager's ask of the player (`Credit._ask_player`) is the player's choice |
| Courtship proposals and marriage acceptance between villagers | deliberately not wired | X19-CRT12 (owner, 2026-10-23): the fixed cut-offs stay; only `court_choice` among those they allow |
| Player's courtship, gifts, quests | not wired | player-facing; Q10 words and CRT rules |
| Crime reporting, testimony | deliberately not wired | Q08: law is separate; reporting stays World's |
| Villagers' thefts | bandit robberies fed (section 9.3); other villager thefts have no act | DVW-B2 |
| Help, gifts, rescue, fair or cheating trade as judged events | wired in round 8 (section 9.3) | - |

### 9.3 Event feeds (round 8, PROS-19, SJD-Q12: events that help or harm them, their kin or property, plus witnessed crimes and kindnesses; trivia ignored)

Every feed is one guarded call in the live act (`if judgment != null`, a no-op with no store attached) into `JudgmentLive`
(`_event`, `on_*`). Nothing in the act changes: same arguments, same order, same random draws. Witnesses are the people
`World.near` finds within `witness_radius` (the one channel the world has for seeing, PAR-05), as for the existing feeds;
victims and beneficiaries are participants; an actor gets no memory of their own deed (as for assaults).

| Catalog event | Live act that performs it (the feed) | Actor / victim / beneficiary | Who learns | Trivia rule |
|---|---|---|---|---|
| `gift` | `Relations.give` (player or villager gives) | giver / - / receiver | receiver, those near the receiver | only the first gift of the day that earns regard (`gift_effect`); a second the same day, a non-gift (rotten apple) or a worthless item publish nothing |
| `help_minor` | `Quests.complete`, a quest done for a villager | player / - / the giver | giver, those near | paid hire jobs are work for pay, not a kindness: no event |
| `help_build` | `Construction._family_help`, relatives' coins toward a home | family household's responsible adult / - / builder | the two only | - |
| `rescue` | `Relations.defended`: the player puts down a bandit or dangerous beast near villagers; `MineWorks._free_trapped`: digging someone out of a cave-in | player or digger / - / those awake near, or the freed | the beneficiaries (and the digger's act) | digging yourself out is no rescue; nobody near, no event |
| `trade_fair` | `Contracts._maybe_finish` (a contract fulfilled), `Credit.repay` (a debt repaid on time) | seller or debtor / - / buyer or creditor | the two only | only between two people (a household party publishes nothing); under 1 coin ignored; a late repayment is not scored |
| `trade_cheat` | `Contracts._lapse` (a contract let lapse), `Credit._default` (a debt unpaid) | seller or debtor / buyer or creditor / - | the two only | same; value is the coins' worth undelivered, or the debt |
| `theft` (villager) | `NPCBrain` bandit robbery (beside the existing assault) | bandit / victim / - | victim, the people who saw (the same `aware` as the assault) | - |
| `killing` (villager) | `NPCBrain` after `World.kill` for a blow by a villager or bandit | killer / victim / - | victim's neighbours as for the player's killing | a bandit killed is not a killing, as for the player |
| `pickpocket` (unseen) | `World.pickpocket` success | player / victim / - | nobody: the victim knows only that something is missing | the fact is kept, nobody learns it (no actor is known to them) |
| `marriage` (NEUTRAL) | `Relations.propose` accepted (villagers), `Life.partner_player` via the player's proposal | both / - / - | the two | recorded and told like any fact; means nothing morally (Q01) |

No source in the game, so nothing is published (and nothing was invented):
- `self_defence`: the game does not tell a blow in self-defence from an attack (`target == -2` is also set by the
  player's own assault).
- `hoard_in_famine`, `false_accusation`: no act hoards or accuses.
- `meeting` (NEUTRAL): meetings happen every hour between everyone; each one would be a fact, and neutral facts take memory
  slots (24 a person) from help and harm. Left out as trivia (SJD-Q12); first acquaintance could be added if the owner
  wants it.
- Ordinary market sales: a sale at the going price is not an event (trivia, and about 3,000 a village day); fair and
  cheating dealing are the kept and broken contract and credit promises above. Selling stolen goods is already the
  theft's.
- Legal facts (a guard's fine, a conviction): the catalog has no legal event type and SJD-Q08 keeps law separate;
  `World.guard_confront` publishes nothing. The theft it fines is already a fact.
- A villager's theft other than a bandit's robbery: no act exists (DVW-B2).
- Discovered thefts: an unseen container theft already reaches the victim as a participant (`World.witness` with nobody
  seen); an unseen pickpocket is the new fact above. A "found missing" with an unknown thief stays a fact nobody has
  the actor of.

Open for the owner: whether a guard's killing of an assaulter should count as `killing` (today it does, as `World.kill`
cannot tell); whether first acquaintance should be a `meeting` fact; whether late repayments should score.

## 10. Conflicts between the owner's decisions and existing mechanics (not resolved here; live behaviour unchanged)

1. **`Relations.harmed` (CRT-10, CRT-12) vs Q07.** A crime against a villager instantly lowers the ties of their kin
   (`kin_harm_share` 0.6) and friends (`friend_harm_share` 0.4) with the player, whether or not they learned of it. That
   is an instant broadcast, which Q07 forbids for judgment. Options:
   - (a) keep it, as the tie's own rule (regard, not moral judgment), and add judgment beside it (today's state);
   - (b) when judgment goes live, stop the instant spread and let word of mouth carry the harm;
   - (c) keep only the victim's own loss in `harmed`.
   Recommendation: (b) at Gate E, since Q07 is explicit; it changes CRT-12 outcomes, so it needs the owner's nod.
2. **CRT-12 notoriety and killings vs Q14 and Q11.** A proposal to a known killer, or above `notoriety_refuse` crimes
   seen, is refused by a fixed threshold (`Relations.refusal`); `marry_regard` is a fixed regard bar. Q14 asks for
   weighted influence, not a threshold. Options:
   - (a) keep CRT-12 for the player and leave villagers' proposals unweighted;
   - (b) replace the threshold with judgment as a weighted factor beside attraction (a murder's permanent BAD would
     still weigh heavily);
   - (c) keep the killer rule as an absolute refusal (owner's earlier rule) and weigh the rest.
   Recommendation: (c).
3. **CRT-06 friendly guard vs Q08 (ANSWERED 2026-10-23: X19-GUARD "Reduce, never waive"; APPLIED in `World.guard_confront`: a friend guard halves the fine, never waives it).** A guard who is the player's friend lets them off with a warning
   (`World.guard_confront`), and a friend nearby halves the fine. Q08: "A guard can personally like someone while still
   enforcing the law." Options:
   - (a) keep CRT-06 as the owner's earlier, explicit rule;
   - (b) the guard enforces always, and friendship shows only in words;
   - (c) friendship may reduce the fine but never waive it.
   Answered (c). Nothing in the judgment code touches it.
4. **Regard as trust (Q06) and regard as harm. ANSWERED 2026-10-23 (X19-REGARD, "Separate them"): trust is now its own value (section 15b); a crime lowers liking, trust moves only with reliability.** Q06 reused Relations regard as trust. But `harmed` also lowers regard
   when a crime is seen, so a crime against someone lowers how far they believe the culprit's stories. That is coherent
   but couples two concepts. No action proposed; noted for calibration.
5. **Regard decay vs Q02.** `Relations.dawn` cools ties without contact (0.5 a day), which is much faster than the
   proposed judgment decay. These are different concepts (closeness and moral judgment, spec invariant 7). No conflict
   in code; noted so the two rates are not confused.
6. **Ordinary stories and Q07.** With no hop limit, an ordinary story still stops when it becomes too faint to remember:
   salience is severity x confidence, and confidence falls along the chain. This is Q11's ordinary forgetting, not a
   count. If the owner wants ordinary stories to travel further, raise `hop_factor`, or base a told memory's salience
   on severity alone.

## 11. Q02 decay demonstration (`game/tests/judgment_decay_demo.gd`, 365 game days, judgment only)

On day 0 Bob is robbed ten times by a thief (10 BAD), sees the thief murder his cousin (kin 0.55 x 3 = 1.65 BAD,
permanent), and is helped twenty times by a neighbour (10 GOOD). Bob's NET at days 0 / 8 / 30 / 90 / 180 / 365. A game
year is 8 days.

| Rate (permille a day) | Half-life (days) | Thief, 10 thefts | Thief, thefts + murder | Helper, 20 helps |
|---|---|---|---|---|
| 0 (off) | none | -10.0 throughout | -11.65 throughout | 10.0 throughout |
| 1 | 693 | -10.0 / -9.92 / -9.70 / -9.14 / -8.35 / -6.95 | -11.65 / ... / -8.60 | 10.0 / ... / 6.95 |
| 2 | 346 | -10.0 / -9.84 / -9.42 / -8.35 / -6.98 / -4.82 | -11.65 / ... / -6.47 | 10.0 / ... / 4.82 |
| **3 (proposed)** | **231** | -10.0 / -9.76 / -9.14 / -7.63 / -5.82 / -3.34 | -11.65 / -11.41 / -10.79 / -9.28 / -7.47 / -4.99 | 10.0 / 9.76 / 9.14 / 7.63 / 5.82 / 3.34 |
| 5 | 138 | -10.0 / ... / -1.60 | -11.65 / ... / -3.25 | 10.0 / ... / 1.60 |
| 10 | 69 | -10.0 / ... / -0.25 | -11.65 / ... / -1.90 | 10.0 / ... / 0.25 |

At every rate the murder's 1.65 BAD is unchanged on day 365, fading parts never grow or go negative, and the lifetime
totals (11.65 BAD, 10 GOOD) are kept as history (24 checks). At the proposed 3 permille, the decisions' disposition
toward the thief moves from 38.35 on day 0 to 40.72 on day 90 and 45.01 on day 365: an old grudge softens over decades
of game time but never vanishes while a murder is part of it. Small remainders fade out (at least 0.001 a day) rather
than sticking. **The rate is not approved.**

## 12. Round 4 evidence

All run on this branch, judgment off unless stated:

| Suite | Checks |
|---|---|
| `judgment_test` | 164 |
| `judgment_live_test` | 53 |
| `judgment_decay_demo` | 24 |
| `judgment_perf` | 23 |
| `run_tests` | 3535 |
| `world_test` | 200 |
| `relations_test` | 79 |
| `parity_test` | 55 |
| `conservation_test` | 8 |
| `save_transfer_test` | 21 |

All had 0 failures. Python unittest: 105 OK. `tools/sim_gate.py`: see PROGRESS.md. `economy_sim --judgment`, 10 days,
seed 1: see PROGRESS.md.

**Performance after the owner's rules** (`judgment_perf.gd`, spread, live rate, 500 people):
- **Frames:** p99 1.45 ms (round 3: 0.87); p99.9 3.78 ms (round 3: 2.15).
- **Per day:** 208 ms (round 3: 150).
- **Memory:** 5.9 MB, plus 23 permanent memories.
- **At stress:** the permanent memories grow (1,646 at 500 people over 40 days, mostly assault victims at
  `permanent_personal_severity` 2000). Ordinary memory stays bounded.

The rise has three causes:
- the daily decay now touches every ledger with a fading part (about 35 ledgers a person);
- stories travel further (no hop limit);
- more confident tellings now update beliefs.

The owner accepted the round-3 p99 and asked for no more speculative optimisation rounds, so this is reported, not
chased. A ready fix if wanted: apply the decay lazily, when a ledger is read or changed (same daily steps in the same
order, so the same results), instead of every ledger at dawn.

## 13. Synchronization with Build 17 (SYNC-17, owner directive 2026-10-21)

The owner directed a one-way refresh: `docs/directives/2026-10-21_sync_expansions_with_build17.md` on staging `d91ea7f`
amends PROS-01. Build 17 is merged into this branch; nothing of Expansion 19 goes into Build 17.

- **Build 17 baseline: `cd7439c`.** This was the head of `wip/build17` when checked ("Let the reeve carry an unclaimed
  delivery when no manor hand is free (LOG-01)"). Build 17 is not released; a later Build 17 fix comes in by a targeted
  follow-up sync.
- **Before:** `1b05da0`. **Merge commit:** `93c107f`.

**Conflicts.** All three were adjacent additions; both sides were kept:
- `world.gd`: Build 17's new members (contracts, discovery, prospecting, pits, underground, levels, mine works), their
  setup and their load, followed by the judgment store's lines;
- `economy_sim.gd`: Build 17's `reached` days, plus the judgment summary lines;
- `tests.yml`: Build 17's suites, then the judgment suites.

Every other judgment hook auto-merged into Build 17's versions of the same functions. No generated file conflicted;
`check_interactions`, `check_resources` and `check_materials` report 0 problems.

**Compatibility review against Build 17's additions**

| Build 17 path | Effect on judgment | State |
|---|---|---|
| Underground levels (MIN-A) | `World.near` and `Relations.hour` now ignore people on another level ("not through rock"). Witnesses of thefts, attacks and a killing, and who meets whom for gossip, come from them | Resolved by construction: no knowledge passes between levels, and no change was needed |
| Mine collapse (MIN-COLLAPSE: `World.kill(n, "crushed in a mine collapse")`, trapped survivors in `MineWorks.trapped`) | An accident with no actor: no judged event is published. The killing hook fires only for a villager slain by the player | Consistent with "do not invent new judgment behaviour". A collapse death as a remembered fact (a NEUTRAL record, seen only by those on the same level) would be a new event feed: listed, not wired |
| Contracts and services (CON-01, CON-02: `Contracts.evaluate`, breaches "let down by ...") | Not wired: a breach is a natural "trade_cheat" event, and acceptance a natural Q14 decision point | Outstanding: new feeds and a new decision point. Per section 9.2 they go in at the Build 18/19 reconciliation, through the same interface |
| LOG-01 reeve fallback, `is_staff` includes the reeve, manor hands | `hire_choice` and `work_accept` use `Construction.can_hire` and `Business.hire_refusal` as they stand. Neither function changed in Build 17's diff | Compatible; `judgment_live_test` hiring checks pass on the merged code |
| Trading (`_buyer_for`, `_seller_of`), ownership, the prospector trade | The live candidate rules are unchanged in Build 17, and the adapters mirror them | Compatible; the trade-hook shortcut is still taken for every sale (56,350 in 30 days) |
| Dawn work (`mine_works.dawn`, `discovery.dawn`, mine supply, timber wear) | `judgment.begin_day` runs after them in `World._new_day`; the hourly slices are unchanged | Compatible |
| Saves (`SAVE_VERSION` 17, Build 17's) | The judgment section stays optional and is written only when a store is attached | Compatible; the round-trip and Build 16/17 save tests pass |

**Measurements after the merge**
- **Village, 30 days** (`economy_sim --judgment`, seed 1, checkpoints at days 10, 20 and 30; one run under SIM-01):
  - no currency, item, deposit or animal leak at any checkpoint;
  - 2,186 tellings and 1,893 belief upgrades;
  - gossip cost (pump plus flushes) 0.71 s over 30 days, about 24 ms a day. Round 4 was about 28 ms a day over 10 days,
    so the gossip hotspot is not worse after the merge;
  - largest flush 77 meetings, 2.4 ms;
  - time inside the trade hook 139 s over 30 days. Nearly all of it is Build 17's own buyer search, which the game pays
    with judgment off too; the judgment part is one disposition check a sale.
- **Synthetic frames** (`judgment_perf`, 500 people, live rate, spread): p99 1.41 ms, p99.9 3.67 ms. Round 4 was 1.45
  and 3.78 ms: unchanged.
- **Still open:** the gossip frame hotspot remains the open performance concern. Section 14 takes it up.

## 14. Gossip frame round (owner-directed, 2026-10-22, on `e91d903`)

The task was to cut the worst single-frame cost of word of mouth without changing anything it decides: who hears what
and when, how witnesses read a deed, the Good and Bad ledgers, relationship weighting and rivalry, NPC choices, and
determinism. Nothing else was merged in.

### Cause (measured)

`judgment_perf` was run at 500 people, rates live and stress, over 40 days, before any change. The heavy frames were:
- **Dependency flushes forced by reads.** A villager's decision reads an opinion (`net`, `disposition`, `ledger`). Before
  that read, every queued meeting the person depends on was told: the dependency closure, up to 83 meetings, about 70 to
  100 us each here.
  - The worst live frame was 5.4 ms, almost all of it inside decisions: one such flush.
  - Over 40 days at the live rate there were 391 flushes, 378 ms in all.
  - In the 30-day village (seed 1) there were 459 flushes; the largest was 77 meetings.
- **Flushes forced by writes at the heavy rate.** An observation (`observe_all`) changes a witness's records, so their
  queued meetings must be told first. The worst stress frame (25 ms) was mostly event observation (15.9 ms).
- **Repeated work in each telling.** For every friends and regard check, the live adapter built a 21-field `_blank()`
  relationship dictionary and its string key. `interpret` built a parts dictionary for every evaluation, even with nobody
  reading the trace. Permanence copied the fact's victims and beneficiaries into new arrays.
- **The daily update.** At each person's dawn, the decay walked every one of their ledger entries: 11.6 ms a day at 500
  live, 38 ms at stress, and a worst update tick of 6.6 ms at stress.

### What changed (`judgment_store.gd`, `judgment_live.gd`)

1. **Reads skip flushes that cannot change what they read.** `_cu_read(o, subject)` tells the queued meetings first only
   when one of them could change the entry being read. A meeting changes a ledger only by telling `o` a memory that `o`
   does not hold, or holds less surely, and has not already judged. It then changes only the entries of that event's
   believed actors, plus those `o` believed before for an upgrade. `_learnable` collects those actors over the
   dependency closure:
   - a read of one entry (`net`, `ledger`, `disposition`) skips the flush when that subject is not among them;
   - a read of the whole ledger (`most_disliked`, the trade adapter's `_first_stands`) skips it when nothing is
     learnable at all.
   With false rumours (misattribution) or retraction on forgetting, every entry counts as changeable, so every read
   flushes. A write still flushes first, as before.
2. **The reach is cached.** `_reach(o)` holds the closure, the learnable actors and whether anything is learnable, under
   a version counter `_gver`. Anything that could change the answer bumps `_gver`: a meeting queued or told, a memory
   learned, corrected or forgotten, a revised fact, a ledger set by a fixture, a new day, or a load.
3. **Lazy ledger decay.** Each ledger entry carries the day it was decayed to (an eighth slot, not saved). `_entry()`
   applies the decay it is owed when the entry is next read, changed or saved: the same integer `_decay_step` steps, in
   the same order, as the dawn update applied. The dawn update no longer walks the ledgers. Saved rows are unchanged
   (nine columns, decayed values).
4. **Interpretation without allocation.** `_interpret_p` returns the number and fills a parts dictionary only when one
   is passed. `interpret()` still returns the full parts. The trace (`last_trace`) is kept only when `trace` is on (a
   developer switch, off by default). Permanence scans the packed fact in place. In `tell`, credibility is computed only
   when a candidate needs it.
5. **The live adapter reads relationship ties directly.** It uses `ties.get(key)` for friends and regard: no `_blank()`
   dictionary is built for a pair with no tie.

### Proof that results are identical

- **State hashes.** Every `judgment_perf` configuration ends in the same hash before and after: live 577419741 (spread
  and told at once), scheduled 1316774373, stress 1399701037, stress scheduled 1092040246. The before run used the
  judgment code of `e91d903` with the same harness.
- **Village, 30 days** (`economy_sim --judgment`, seed 1, checkpoints at days 10, 20 and 30):
  - world fingerprint `1c755f53d12c72bd470b7913fb5e52a6` before and after;
  - judgment state hash 1780545997 before and after;
  - the same 2,186 tellings, 1,893 upgrades and 305 ledgers;
  - currency and item leaks 0 at every checkpoint.
- **Tests.** `judgment_test.gd` `test_spread_gossip` now also counts reads that skipped a flush. Some must occur in the
  default setting, and none may occur with misattribution, while the end state still equals telling every meeting at
  once. A new stale-cache test reads between two queued meetings, with no pump, and compares with meetings told at
  once.
- **Mutation checks.** These deliberate faults each fail the suite:
  - always skipping the flush;
  - ignoring the subject of a one-entry read;
  - not bumping the version when a meeting is queued.

### Before and after (`judgment_perf`, 500 people, 40 days, same harness, the machine shared)

| Configuration | Frame p99 ms | p99.9 ms | Worst ms | Most tellings in one frame | Daily update ms/day | Update worst tick ms | Memory MB |
|---|---|---|---|---|---|---|---|
| live, spread, before | 1.27 | 3.35 | 5.94 | 107 | 11.58 | 3.48 | 5.9 |
| live, spread, after | **1.05** | **1.81** | 6.22 | 107 | **4.02** | 3.06 | 6.1 |
| stress, spread, before | 8.19 | 15.77 | 25.00 | 188 | 38.38 | 6.62 | 17.2 |
| stress, spread, after | **6.20** | **13.82** | 26.58 | 188 | **11.34** | **2.44** | 17.4 |

- **Flushes.** Live, 40 days: 391 flushes and 378 ms became 29 flushes and 36 ms, with 11,738 reads served without a
  flush. Stress: 391 became 292, and 1.60 s became 1.31 s.
- **Village, 30 days:** flushes 459 to 225 (1,524 reads served without one), flush time 112 to 55 ms, dawn time 14.3 to
  7.8 ms. The largest flush is still 77 meetings (3.2 ms before, 1.8 ms after).
- **On a phone (4x).** Live spread p99.9 is about 7 ms, from 13. The worst frame is about 25 ms. At stress, p99.9 is
  about 55 ms and the worst about 105 ms.
- **The worst single frame did not fall.** The tellings in the heaviest frame are a deterministic count, free of machine
  noise, and they are unchanged: 107 live and 188 stress. When a flush is needed it is still the whole dependency
  closure, and that ordering is what keeps results identical. The worst frame figures move within the shared machine's
  noise (idle ticks reached 1.1 to 1.5 ms).
- **Save time.** It rose in the harness (live 71 to 307 ms). The harness saves once, at day 40, so the save brings 40
  days of deferred decay up to date in one go. The game autosaves every hour (`main.gd`), so there the backlog is at
  most one day. That is the decay the dawn update used to do, now paid in the first save after dawn.
- **Memory** read 0.2 MB higher, within the old measure's noise. That measure also counted the harness's own arrays.
  Section 15 measured the eighth ledger slot directly: it costs nothing, because a packed array of 8 values takes the
  same allocation as one of 7. Stress was already above 16 MB before this round, with 17.2 MB at `e91d903`.

### What remains

- Under the reference "hour" mode the worst single frame is bounded by a necessary dependency flush. The chosen
  "scheduled" model (X19-Q-TIMING, answered 2026-10-23) bounds it further.
  - With the scheduled option: 8 to 12 ms worst, and 11 and 28 tellings a frame, against 107 and 188.
- At stress, writes (observations) still force full flushes, since a write must see every earlier meeting.
- Stress memory is 17.4 MB, above the 16 MB proposed budget, as it already was. Section 15 brings it to 13.5 MB.

## 15. Investigation round: timing, the worst frame, memory (owner-directed, 2026-10-22, on `05adc9d`)

There were three questions:
1. The X19-Q-TIMING proposal. It is written in `docs/expansion19/GOSSIP_TIMING_PROPOSAL.md` (decided and implemented 2026-10-23, section 15a);
   "hour" stays the default.
2. Can the worst frame fall without changing when anyone learns anything?
3. Where does the heavy-rate memory go?

Every change is byte-identical:
- the same `judgment_perf` hashes in all six configurations at 500 people: live 577419741 (spread and told at once),
  live scheduled 1316774373, stress 1399701037 (spread and told at once), stress scheduled 1092040246;
- the same counts and stats;
- the 30-day seed-1 village: fingerprint `1c755f53d12c72bd470b7913fb5e52a6`, judgment state hash 1780545997, the same
  tellings, and no leaks at any checkpoint.
- Suites: `judgment_test` 168, `judgment_live_test` 53, `judgment_decay_demo` 24 and `judgment_perf` 9 checks, all with
  0 failures.

### 15.1 The worst frame

**Where a telling's time goes.** The meeting time is split by part, from a temporary profile build (not committed), at
500 people over 40 days:

| Part | live | stress |
|---|---|---|
| all meetings | 3.13 s | 11.27 s |
| the teller's scan of their memories for what to tell | 1.32 s (42%) | 3.27 s (29%) |
| judging a story learned: interpretation | 0.49 s | 2.81 s |
| judging a story learned: posting to the ledgers | 0.27 s | 1.84 s |
| the memory capacity check (`_bound`) | 0.04 s | 3.41 s (30%) |
| the gate (budget, opinion of the listener), catch-up, storing the memory | 0.56 s | 1.40 s |
| finding the dependency chain, and what a read may skip | 0.08 s | 0.31 s |

**Tried, and kept.**
- `_bound` in one pass. When over capacity it scanned the memories, forgot the least salient, then scanned again only
  to find one ordinary memory fewer. It now returns at once in that case: 3.41 s became 2.49 s at stress (−27%).

**Tried, and taken out again.**
- Computing credibility only after the cheap filters (an exact bound shows when it cannot matter). It saved nothing:
  the live scan went from 1.32 to 1.29 s. At stress it cost more (3.27 to 3.71 s), since every memory then paid an
  extra calculation.

**Net result.**
- The time per meeting changed within the machine's drift. In the A/B pair, the daily update, whose code did not
  change, moved 11% between the two runs.
- The heaviest frame still holds 107 tellings live and 188 heavy: worst about 6.6 ms and 23 ms here.

**Why the flush cannot be split or cut further with identical results.**
- **Splitting it across frames:** the decision needs its answer in that frame. Deferring the decision would change
  behaviour.
- **Telling only the meetings that carry stories about the subject read:** not exact. Each meeting passes at most 2
  stories, by salience, and each teller at most 6 a day. Every telling therefore depends on every earlier telling in
  the chain, whatever it was about.
- **Caching or incremental structures inside a flush:** finding the chain and what a read may skip are already only
  2.5% of the time. The rest is per-telling work that must be done for each telling: scanning, interpreting, posting.
- **Telling ahead in idle frames:** the queue is already told in idle frames. The heavy flush comes in an hour's
  first frames, right after its meetings are queued, so telling faster only makes that frame heavier.
- **What would work, but needs the owner:**
  - native code (a GDExtension in C++) for telling and judging, likely an order of magnitude faster a telling. It is a
    second implementation language for one concern and a new build dependency (CLAUDE.md sections 2 and 11);
  - a different timing (the proposal).

### 15.2 Memory

**The measure changed.** `judgment_perf` now measures the memory that releasing the store gives back. The old measure
also counted the harness's own arrays: the frame times, and now the record of choices. `--breakdown` empties each
structure in turn and records what that gives back.
- In a reported run with the breakdown, the parts add up to the total.
- Runs without it read about 1.7 MB lower for the same store. The reductions below are the same in both.

**Stress, 500 people, 40 days** (KB; with the breakdown):

| Structure | Before | After | Entries | Bytes an entry before -> after |
|---|---|---|---|---|
| opinions (ledgers) | 6,744 | **3,205** | 32,413 | 213 -> 101 |
| memories | 3,561 | 3,561 | 13,646 | 267 |
| contributions | 2,395 | 2,395 | 13,646 | 180 |
| who has judged each event (knowers) | 2,247 | 2,247 | 8,052 events | 286 |
| facts | 1,761 | 1,761 | 8,052 | 224 |
| events by day, permanent references, the rest | 375 | 375 | | |
| **total** | **16.9 MB** | **13.5 MB** | | |

**Live rate, 500 people:** 5.7 MB became 3.6 MB; opinions went from 3,806 to 1,719 KB.

**What changed: ledgers as packed arrays per observer.**
- Before: each opinion was a dictionary slot holding its own packed array of 8 values. That is about 213 bytes: the
  slot, the array object, and a 64-byte buffer.
- Now: each observer has two packed arrays, the subjects (ascending) and 8 values for each.
- The same values in the same order are saved. Iteration is ascending, as the save and `most_disliked` already sorted
  it.
- The trade adapter now asks the store for the subjects (`subjects()`).
- Posting to a ledger is about 12% slower, about 2% of meeting time.
- The eighth slot (the day an entry was decayed to) costs nothing: a packed array of 7 or 8 values takes the same
  allocation.

**Options not taken.**
- **Memories, contributions and facts** could be packed the same way per observer. Estimate: 40-50% less each, about
  3 to 4 MB more at stress. They are read in many more places (telling, learning, the capacity check, the daily
  update, saving), so the change is larger, and inserts make each write slower.
- **Knowers** grows with the 30-day memory horizon. A shorter horizon would change behaviour.
- **Smaller fields** (32-bit) would cap ids and points, and that needs a guard.

**The 16 MB target.** It is an agent proposal for 500 people at the heavy rate, which is about 80 times the events of
the live village. Both rates are now within it (13.5 and 3.6 MB). A budget at the live rate (say 8 MB at 500 people)
would track what the game actually produces. Phone memory is in gigabytes, so frame time remains the binding cost.


## 15a. X19-Q-TIMING decided and implemented (2026-10-23)

Owner answer, verbatim: "They should spread organically by contact and closeness like a real rumor or gossip would"
(`docs/directives/2026-10-23_owner_answers_x19_guard_harmed_timing_regard.md`). The lead's reading (recorded 2026-10-23):
each passing of gossip happens at the meeting itself, weighted by how close the two people are.

- **A19-12 Timing.** `gossip.timing` is "scheduled" (the round-3 prototype, finished, not a parallel model): each meeting is
  told at its own seeded minute of the hour it was shared, with no catch-up flush. "hour" is kept as a reference mode
  (the identity tests prove the queue and dependency flush equal telling at once; `judgment_perf` compares against it);
  nothing in the live game uses it. The hour-queue code was not removed because those tests and measurements need it.
- **A19-13 Closeness.** Before this change closeness already weighted how far a story is *believed* (credibility, from the
  existing relationship number, Q06) but not *whether* it passed: every meeting passed up to `per_meeting` stories.
  Now each story a teller could pass passes with a chance from `gossip.closeness_floor_permille` (500, an AGENT-PROPOSED
  number awaiting owner review; strangers, regard 0) rising linearly to certain at regard 100 (the existing Relations
  regard through `JudgmentSocial.regard`). The roll is a seeded hash of the world seed, event, teller, listener, the
  meeting's minute and the day: deterministic, no global random. A story withheld does not use the meeting's or the
  teller's daily limits and may pass in a later meeting (another minute, another roll). 1000 turns it off. SJD-Q07
  (meetings only, no hop limit, no confidence floor) is unchanged.
- **A19-14 Pending meetings and saves.** Meetings whose minute has not come are saved (`"scheduled"`: minute, a, b) and
  restored; a row is removed before it is told, so none is told twice. Closed gap: a scheduled save loaded while
  the setting is "hour" now moves its pending meetings into the hour queue in minute order (before, they would have
  waited forever). `begin_day` also tells any scheduled meeting older than the day (a long time skip), so a meeting never
  spends the next day's tellings. Section format and `SAVE_VERSION` unchanged.
- **Tests.** `judgment_test`: `test_scheduled_gossip`, `test_closeness_gossip`, `test_scheduled_save_migration` (180 checks).
- **Measured** (`judgment_perf`, 500 people, 40 days, worst single frame; this machine; phone figure = 4x):
  | rate | before, "hour" (c2ece16) | after, "scheduled" | tellings in the worst tick before / after |
  |---|---|---|---|
  | live | 11.7 ms (about 47 ms on the phone) | 7.4 ms (about 30 ms) | 107 / 11 |
  | heavy (stress) | 27.0 ms (about 108 ms) | 15.6 ms (about 62 ms) | 188 / 28 |
  Frames are noisy (one outlier can set the worst); the telling counts per tick are exact. The earlier 76 to 105 ms
  phone figure was the heavy "hour" worst. The closeness weighting itself costs one hash per story.


## 15b. X19-REGARD: liking and trust apart (2026-10-23)

Owner answer: "Separate them (Recommended)": liking and trust tracked apart. The lead's reading: Relations' `regard` is
liking and contact (it keeps setting gossip closeness, befriending, courting, prices); belief credibility takes its own
value. Nothing in Relations or the live game changes: judgment is off live, so the gate stays identical.

- **Store.** `JudgmentStore.trust[listener][subject]`, milli-points 0..100000, `trust_of(a, b)`, `trust_add`. Saved as an optional
  `"trust"` list of [listener, subject, value] with the section (format and `VERSION` unchanged; older sections have none and load
  fine; a store with no trust writes none).
- **Starting value.** With no record, a first impression: regard x `trust.seed_from_regard_permille` (250, proposal) / 1000, so a
  stranger is 0 and a well-liked newcomer a little above; the first thing that moves trust stores the value. This keeps Q06's
  "the relationship number must influence" without letting liking alone buy belief.
- **What raises or lowers trust (reliability, not warmth).**
  - A deed's own `trust` in `events` (milli-points, proposals): fair deal +4000, cheat -20000, false accusation -20000, times the
    observer's confidence and the actor's share, once, when the belief is first formed. Kept promises and contracts are the same
    field once the game publishes them as events (none are published today; no new event invented here).
  - A teller's account meeting what the listener learns first-hand: right (same actors) +4000 (`rumour_confirmed`); wrong (another
    actor) -15000 (`rumour_false`), also on `correct`. Counted once per story.
  - Liking (shared time, kindness, help, harm seen) stays in Relations regard; judgment's moral view (`net`) still nudges credibility
    as before.
- **No decay** of trust (proposal; trust only moves on evidence). Every number above is an AGENT PROPOSAL labelled in
  `judgment.json` (`_trust_note`).
- **Tests.** `judgment_test::test_x19_regard` (a liked liar is believed less once found out, liking unchanged; a disliked honest
  trader gains trust; cheats lower it, clamped at 0; a story borne out raises the teller; closeness still follows liking; save and
  load; an older section; determinism). `test_q06_trust` and `test_q06_live_trust` updated to the first-impression values (0.612, 0.6).
- **Open for the owner.** Whether liking should seed trust at all (and how much); the rates; whether trust should fade.


## 15c. Own tolerance and shaped weights (SJD-Q03, SJD-Q13; round 7)

Owner answers 2026-10-23: Q03 "Own tolerance each: personality-based thresholds seeded at birth; some forgive quickly, some hold grudges"; Q13 "Weights seeded from personality at birth, then shaped by life events; deterministic".

**There is no personality system in the game** (`npc.gd` has no traits), so a person's temperament is a hash of the world seed and their id: nothing stored for it, identical after save and load, no global random. If the owner later adds a real personality, `JudgmentStore.tolerance` and `JudgmentWeighting.trait_weight` are the two places to feed it.

- **Tolerance (Q03).** `tolerance(person)` = 1000 +/- `personality.tolerance_spread_permille` (300) plus the life shift. It scales the two NET thresholds a person applies, through `threshold(person, base)`: `interpret.rival_net_at` (when a bystander turns a person's rival) and `gossip.share_net_at` (whom a teller will still tell). Above 1000 a person puts up with more before souring; below, holds a grudge sooner. The existing per-family `morality_spread_permille` (Q08, how strongly a deed registers) is a separate dial and stays.
- **Weights (Q13).** `decision.trait_spread_permille` (300) moves each person's weight of each factor by up to that much either way (was 0). The `_first_stands` shortcut in `judgment_live.gd` no longer switches off for a non-zero spread: it uses the seller's own weights.
- **Life events.** Smallest rule fitting the catalog: only firsthand experience (src participant or witnessed) as the victim of a BAD deed or the beneficiary of a GOOD one, once per event per person. A victim's tolerance falls by `tolerance_per_point` (40) x severity points (theft 40, assault 80, killing's victims are dead); a beneficiary's weight on the disposition factor (what they think of others, hence trust in a helper) rises by `weight_per_point` (30) x severity points (rescue 60). Each shift is clamped to +/- `max_shift_permille` (250). Shifts are person-wide, not per family of deed ("less tolerant of theft" generalises to all dealings): the owner's words do not say which, and per-family would need a family key on the thresholds. They do not decay (X19-DECAY is untouched).
- **Saved** as an optional `life` list `[person, tolerance shift, weight shift]` in the judgment section; sections without it load (no shifts); `VERSION` stays 1. Recomputable part (temperament) is never saved.
- **Live game unchanged**: `enabled` stays false; the store is not attached, so none of this runs. Tests in `judgment_test.gd` `test_personality`; the baseline `cfg()` there sets the spreads and steps to 0 so the exact fixtures of earlier checks keep their meaning (they assumed one scale).
- All spreads, steps and the bound are AGENT PROPOSALS (judgment.json `personality`, `_status`).
