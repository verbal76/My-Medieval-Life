# X19-Q-TIMING: when word of mouth is told (DECIDED and IMPLEMENTED 2026-10-23)

**Decided and implemented, 2026-10-23.** The owner answered: "They should spread organically by contact and closeness like
a real rumor or gossip would." Variant B ("scheduled") is now `gossip.timing` in `game/data/judgment.json`, with the
closeness weighting and the save-migration fix described in DESIGN.md section 15a. "Hour" remains only as a reference mode
for tests and measurements; "ordered" (C) was not built. The paper below is kept as the record of the options as they stood
on 2026-10-22; where it says "pending" or "default", read the above. Judgment itself stays `enabled: false` in the live game.

Original introduction (2026-10-22):
- `gossip.timing` was `"hour"`: the "spread" queue, with results identical to telling every meeting at once.
- `"scheduled"` existed only as the round-3 prototype, off by default.

Written 2026-10-22 on `wip/expansion19-preparation`. The measurements come from `judgment_perf` (500 people, 40 days).
The live-village facts come from `economy_sim --judgment` (30 days, seed 1).

## 1. What happens today ("hour", the default)

1. **Meetings are generated at the start of each game hour.** `Relations.hour` walks the awake villagers. Each pair
   that spent the hour near each other shares the hour (`Relations.share`), and their meeting is queued
   (`JudgmentStore.meet_later`).
2. **Meetings count as told at the start of that hour.** The game then tells them 8 a frame (`gossip_pump`).
3. **Reads and writes catch up first.** Before anything reads or changes a villager's judgments, the queued meetings that
   villager depends on are told first (the dependency flush). The one exception is a read that the queued meetings
   provably cannot change.
4. **So results are exactly as if every meeting were told the moment its hour began.** Pacing changes only the frame
   cost.
5. **The cost is the worst frame.** A decision in the first frames of an hour may have to tell a chain of up to 83
   meetings first:
   - 107 tellings in one frame at the live event rate, 188 at the heavy one;
   - about 6 ms here at the live rate, 26 ms heavy;
   - about 25 and 105 ms on the assumed 4x-slower phone.

## 2. What "scheduled" would change

### 2.1 Exactly when each telling is processed

Each meeting gets its own minute of the hour in which it was shared:
- **The minute:** `minute = hour start + h mod 60`, where `h` is a seeded hash of the pair (lower id, higher id), the
  hour and the world seed (`meet_hourly`).
- **When it is told:** when the world clock reaches that minute. `World.update` calls `gossip_tick(minutes)` every
  frame, and every meeting whose minute has come is told in that frame. Meetings sharing a minute go in the order they
  were queued.
- **No catch-up:** nothing is ever told early. Reads and writes see the store as it is at that minute.
- **In real time:** at 2 game minutes a second, a game minute lasts about half a second (about 30 frames), and an hour
  30 seconds. A meeting is therefore told 0 to 59 game minutes after its hour begins: 0 to about 30 real seconds.
- **Across days:** every meeting of an hour is told before that hour ends. Night has no meetings (sleepers are left
  out), so nothing is pending at dawn.

### 2.2 Who learns what, and when

There are three effects. Each is bounded per meeting, but not per story.

1. **Later, by under an hour.** A telling happens up to 59 game minutes after the moment "hour" timing gives it. A
   decision in that window reads the opinion from before the telling.
   - Example: Ann and Bob share 10:00-11:00, and Bob knows Carl stole. "Hour" counts Ann as told at 10:00. "Scheduled"
     might tell her at 10:41. A sale Ann weighs at 10:20 does not yet reflect the theft; one at 10:50 does.
2. **Fresher, by under an hour.** A teller who learns something during the hour, before the meeting's minute, can pass
   it on in that same meeting.
   - Example: Bob witnesses the theft at 10:15, and his meeting with Ann falls at 10:41. Under "scheduled", Ann hears it
     at 10:41.
   - Under "hour", the 10:00 meeting is already over. Ann hears it only at their next shared hour, at least an hour
     later and possibly days later.
3. **A different order within the hour.** "Hour" tells an hour's meetings in the order `Relations.hour` visited the
   pairs; "scheduled" tells them in minute order.
   - **Chains change.** Under "scheduled", A tells B at 10:10 and B tells C at 10:50, so C hears A's story this hour.
     "Hour" may have told B-C before A-B, and then C does not.
   - **Limits make it compound.** Each meeting passes at most 2 stories, by salience, and each teller at most 6 a day.
     A different order spends those limits on different stories, so later tellings differ as well.

**Bounds.**
- Each meeting is told under 60 game minutes later than under "hour", within its own hour.
- No telling moves across hours. Everything an hour's meetings carry is told by the end of that hour in both modes.
- A particular story is not bounded: a villager may hear it sooner, later, from someone else, or not at all, because
  chains and limits change.
- **Measured, live rate:** 3,104 memories instead of 3,198, and 16,648 opinions (ledger entries) instead of 17,624,
  over 40 days. Some news stops travelling.
- **Measured, heavy rate:** the memory count is the same (capacity binds), and there are 33,046 opinions instead of
  32,413.

### 2.3 How NPC decisions change

The decision points that read judgment are wired but off in the live game (DESIGN.md section 9.1):

| Decision | When it reads | Under "scheduled" |
|---|---|---|
| Whom a villager sells to (`_buyer_for`), whom a household buys timber from (`_seller_of`) | during the working day | may read an opinion up to 59 game minutes older than under "hour", when a meeting of the current hour has not reached its minute |
| Whom a building household hires, whether a villager takes work | during the working day | the same |
| Whether two villagers become friends (`_befriend_if_close`) | inside `Relations.share`, the moment the shared hour is counted | **systematically one shared hour behind** for what the two tell each other in that hour: "hour" tells the meeting first, "scheduled" has not yet |
| Whom a single villager courts (`_villagers_court`) | at dawn | no delay: every meeting is told before dawn. Only the content differs, through the chain changes above |
| Guards, fines, reports | not judgment's (owner decision Q08: the law stays in World) | unaffected. Witnesses always learn what they see at once, in both modes; only told stories are timed |

**Measured, the same 40,000 weighed trade choices asked in the same order** (`judgment_perf`, compared choice by
choice):

| Rate | Chosen differently | Dispositions read that differed | Largest difference |
|---|---|---|---|
| live | 0 of 40,000 | 6,805 of 120,000 (5.7%) | 0.40 points of 100 |
| heavy | 0 of 40,000 | 61,190 of 120,000 (51%) | 1.50 points of 100 |

Opinions differ slightly, but with the proposed weights (disposition is 10% of a purchase) no choice flipped.

**In the live village today, nearly nothing would change.** The wired event feeds (the player's thefts, attacks, a
killing) made only 4 judged events in 30 days on seed 1. With judgment on, the day-30 world fingerprint
(`1c755f53d12c72bd470b7913fb5e52a6`) is the one Build 17's determinism gate recorded for `cd7439c`, where judgment does not exist
(`docs/build17/DETERMINISM_GATE.md` on `wip/build17`, commit `7e19008`, seed 1, day 30). The timing will matter once more events are wired at Gate E: help, gifts, trade and
villagers' crimes (DESIGN.md section 7).

**Consequences.**
- **Trading and hiring:** a villager may deal with someone during the hour in which bad news about them is still
  travelling; they react once it arrives. That is plausible ("I had not heard yet"), but a player who sees a witness
  run straight to a friend may expect it sooner.
- **Friendship:** befriending lags the conversation by one shared hour.
- **Courtship:** no lag, only different content.

### 2.4 Determinism and fingerprints

- **Deterministic:** yes. Each minute comes from a seeded integer hash (pair, hour, world seed). Same-minute meetings
  keep their queue order. `test_scheduled_gossip` checks that the same seed gives the same minutes and result, and
  that a save made before a meeting's minute ends the same as one never saved.
- **Judgment off** (every released build): nothing changes. No store exists, and every fingerprint and save stays as it
  is.
- **Judgment on:** the judgment state hash changes; different results are the point of the option. The world
  fingerprint changes only if a judged opinion moves a decision.
  - In the 30-day seed-1 village no decision moves even under "hour", so it would most likely stay equal. This was
    not run for "scheduled": it would take one 30-day run.
- **Not a generator change:** the seeds, the world and the generators are untouched.

### 2.5 Relationships, ledgers, saves and migration

- **Regard (Relations).** It is raised by the shared hour itself (`Relations.share`), at once, in both modes. Timing
  changes only when judgment's Good and Bad points arrive.
- **Rivalry.** Interpretation treats someone as a rival from their ledger (NET at or below `rival_net_at`), so it lags
  in the same way as the ledgers.
- **Ledgers.** The same rules and points, posted when the telling happens. The decay is per day, so it is unaffected.
- **Saves.** Under "scheduled", meetings whose minute has not come are saved (`"scheduled"`: minute, a, b) and restored
  on load. Under "hour", the queue is told before saving, so nothing is pending. The section format and `SAVE_VERSION`
  do not change: the key is optional.
- **Migration risk (fixed 2026-10-23: `load_dict` queues them in minute order under "hour").** A save made under "scheduled" and loaded under "hour" puts its pending
  meetings back in the scheduled table. "Hour" never tells that table, so those meetings would wait forever, carried
  from save to save. If the setting can ever change on an existing world, loading must move them into the hour queue in
  minute order. The other direction is safe, since an "hour" save has nothing pending.

### 2.6 Frame benefit (measured) and risks

`judgment_perf`, 500 people, 40 days. A frame is one game minute here. In the game a minute is about 30 frames, which
spreads the work further.

| | Most tellings in one frame | Frame p99 | p99.9 | Worst |
|---|---|---|---|---|
| live, "hour" | 107 | 1.08 ms | 2.00 ms | 6.3 ms |
| live, "scheduled" | 11 | 0.73 ms | 1.32 ms | noisy (one 15 ms outlier) |
| heavy, "hour" | 188 | 6.5 ms | 13.5 ms | 26 ms |
| heavy, "scheduled" | 28 | 4.6 ms | 7.7 ms | 13 ms |

**Risks:**
- different judgment results, by design;
- befriending lags by one shared hour;
- the migration gap in 2.5;
- the hash can put several meetings on one minute (28 tellings in the worst minute at the heavy rate);
- a large time skip (sleeping, fast-forward) tells every due meeting in one frame, as "hour" also would;
- results stop being "as if told at once", so the round-3 identity tests become a separate scheduled-timing test suite.

## 3. Variants

**A. "Hour" (today).**
- **What it is:** results as if every meeting were told at its hour's start, kept exact by dependency flushes.
- **For:** the reference results; the simplest to reason about.
- **Against:** the worst frame is a whole dependency chain: 107 or 188 tellings, about 25 or 105 ms on the phone. It is
  rare at the live rate (29 flushes in 40 days at 500 people).

**B. "Scheduled" (the round-3 prototype).**
- **What it is:** each meeting at a seeded minute of its hour; no catch-up.
- **For:** a tenth of the work in the worst frame; implemented and tested; saves supported.
- **Against:** the within-hour order changes (minute order), so the results differ most from today's. Busy minutes
  are possible, and there is the migration gap.

**C. "Ordered" (not built).**
- **What it is:** the hour's queue stays in "hour" order and is told at an even pace through the hour. The k-th of N
  meetings goes when the clock reaches `hour start + k x 60 / N` minutes. Reads and writes do not catch up.
- **For:**
  - the same telling order as today, so the same chains and the same use of the per-meeting and daily limits; it
    differs from "hour" only where an event or decision falls in the minutes before a meeting is told;
  - the most even frame load (N/60 meetings a minute: about 2 at 500 people);
  - the same bound: within the hour, under 60 game minutes;
  - smaller than B: the existing queue, a paced pump and no flush;
  - the same save handling as "hour" (the queue is told before saving), so no migration gap.
- **Against:**
  - not yet measured;
  - still a change in results, though likely the smallest;
  - friendship has the same one-hour lag as B.

## 4. Recommendation

- **Keep "hour" until Gate E.** In the live village, judged events are rare (4 in 30 days) and no decision moves, so
  there is nothing to gain yet. Its rare heavy frame is the price of exact results, and the gossip round on 2026-10-22
  cut how often it happens (live flushes 391 to 29 in 40 days).
- **If a bounded frame is wanted at Gate E, choose C over B.** C keeps today's order of tellings, so the results stay
  closest to the reference. It spreads the work most evenly and avoids B's save-migration gap. It should first be built
  behind the same setting and measured as B was: the same choice-by-choice comparison, plus one 30-day village run.
- **Decide with a device measurement.** The phone figures are a 4x estimate. A real mid-range phone would show whether
  "hour"'s worst frame (about 6 ms here at the live rate) is ever visible.
