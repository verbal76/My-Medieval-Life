# Repair audit: dialogue, perspective, crime and guards

Owner directive: `docs/directives/2026-10-24_master_gameplay_repair_dialogue_crime_guards.md` (staging `198b337`).
Code audited: detached checkout of `wip/multiplayer-b19` at `9304446`. Read-only: nothing was committed or pushed. A
throwaway reproduction script ran headless. It was copied into `game/tests/` for the run and removed afterwards.
Script: `/tmp/claude-0/-home-user/754052d8-fb21-5c64-b3f9-641f462e2c23/scratchpad/repair_audit_scripts/repro_audit.gd`.

All paths are relative to `game/scripts/` unless they say otherwise.

## Reproduction (seed 1, day 1 07:00, judgment attached as Build 19 ships it)

```
child Denise Reed id 6  relative Sybil Reed (adult) id 1 same household true
elder asleep? false  near(): true
killed: true
elder NPC.memory: ["saw Wat Ashdown attack Denise Reed", "Denise died (slain by Wat Ashdown)"]
elder report: { "offender": -2, "t": 420.0, "how": "saw" }
  fact 1 assault  actors [[-2,1000]] -> elder belief: {src: "witnessed", conf: 1000, permanent: true, ...}
  fact 2 killing  actors [[-2,1000]] -> elder belief: {src: "witnessed", conf: 1000, permanent: true, ...}
  elder ledger of player [good,bad,...]: [0, 2500, 2, 0, 0, 0, 2500]
Dialogue.opening(elder): I don't know you. You're new here? I'm not doing much just now.
Dialogue.news(elder):    People are talking. Denise Reed the child has died (slain by Wat Ashdown). Wat Ashdown attacked Denise Reed.
Dialogue.brush_off(elder): Don't know you. I'm busy.
Dialogue.home(elder):    I live at The Well House with Hugh, Mabel and two others. We have plenty put by. We lost Denise: slain by Wat Ashdown.
unrelated Amice Cooper (saw nothing) news: Nothing about us. But they say: Denise Reed the child has died (slain by Wat Ashdown).

household news (two log lines of the Lambert kind written for the Reed household):
Sybil Reed (adult): People are talking. The Reed household bought the farmland south-west of the market from the manor for 11 coins. The Reed household fenced the farmland south-west of the market.

guard Bartholomew at (51,51), player at (59,51) (8 tiles), wall x=54..56; A* path round it: 11 steps
after 0.75 s: guard.target=-1, guard at (53.87,51.5), solid cell ahead
guard decides next: doing='buying firewood'
player 25.5 tiles off in the open: guard.target=-1 (player walk 4.5, sprint x1.5, guard chase 3.38 tiles/s)
NPC.to_dict saves target? false
```

This reproduces all three reported defects exactly. The witness record **is** created: the NPC memory string, a
judgment belief marked `witnessed` at full confidence and permanent, a BAD ledger entry and a report to a guard all
exist. The dialogue reads none of them. A villager who saw nothing repeats the same news, and an elder who has just
watched the player kill her child greets the player as a stranger.

---

# Phase 1: root-cause audit

## 1. Where gossip is selected, combined and rendered

- **Selection and combination: `ui/dialogue.gd:388-423` `Dialogue.news`.** It walks the global village log
  `World.log_lines` from newest to oldest (`:399`). It strips the clock (`:401`), drops lines that start "You"
  (`_repeatable`, `:67-69`) and capitalises each line (`sentence`, `:55`). It splits lines into `about` (lines
  matching `\bFamily\b`, the speaker's surname; `:396`, `:407`) and `other`. It keeps at most two of each, and then
  **joins two raw log lines with a space** after "Have you heard?" or "People are talking." (`:414`). If nothing
  matches, it says "Nothing about us. But they say: " plus one raw line (`:416`). The only dedupe is exact
  string equality (`:405`). Nothing groups related events, and the newest line comes first, so stories are told
  backwards. In the owner's quote, "fenced" comes before "bought".
- **Rendering happens when the event is written, not when it is spoken.** Every news line is an English sentence
  that `World.note` (`core/world.gd:2707`) wrote when the event happened, with the names already resolved by
  `World.ref_name` (`core/world.gd:4386-4396`: "The %s household", "Name Family" for a player):
  - Lambert lines: `core/property.gd:340` ("%s bought %s from the manor for %d coins.") and `core/farm_plots.gd:248`
    ("%s fenced %s.").
  - Dale lines: `core/world.gd:2653` (`kill`: "%s the %s has died (%s)." with cause "slain by Maud Berbal",
    `:2025`) and `core/world.gd:2134` (`player_assault`: "%s %s attacked %s %s."). A one-blow kill writes both,
    because `_player_hit_npc` calls `player_assault` before `kill` (`core/world.gd:2017-2025`).
  - Oakley lines: `core/chapel.gd:306` ("The chapel gave the %s household food.") and `core/npc_brain.gd:2194`
    ("%s %s has no %s and cannot get one."). The two are joined by `:414`.
- **Other dialogue.** `opening` (`:203-234`), `brush_off` (`:428-456`), `home` (`:338-383`) and the friends-only
  courting gossip (`:460-475`). The real gossip system, judgment word of mouth (`core/judgment/judgment_store.gd:1309`
  `tell`, queued by `Relations.share`), feeds opinions only. **No dialogue function reads it.**

## 2. How speaker and listener identities reach dialogue

- Every `Dialogue` function takes `(w: World, n: NPC)`. `n` is the speaker. **There is no listener parameter.** The
  listener is taken to be `w.player`, the acting player (`_player_name`, `:41-42`; `_greeting` reads
  `w.player.name`, `:238`). The entry points are `ui/game_ui.gd:2348`, `:2513`, `:2646-2647` and `main.gd:557-619`
  and `:1844`.
- Knowledge about the player is held as **name-keyed strings** in `NPC.memory`: "met Name Family", "attacked by
  Name", "saw Name Family take ...", "caught Name Family ..." (`:77-117`). The memory holds 8 items, and "met"
  entries are kept first (`core/npc.gd:98-105`), so a non-acquaintance memory such as a witnessed killing is pushed
  out by newer ones.
- News lines are text. Once a line is written, nothing records who the actors, victims or beneficiaries were, so the
  speaker's and listener's relation to the event is lost before the dialogue sees it.
- Multiplayer: judgment, relations and `NPC.target` key every player as `Life.PLAYER_ID` (-2) (`core/life.gd:20-27`;
  `docs/multiplayer/BATCH_A.md` section 3 lists these as Batch C sites). NPC memory strings are keyed by player
  *name*, so two players with the same name collide.

## 3. How household and family relationships are accessed

- Household: `NPC.household` gives `w.households[h]` (`members`, `home`, `pantry`, `econ`, `relief_days`). The
  dialogue's `_members` (`:320`).
- Family graph: `NPC.mother/father/partner/children`, `Life.parent_of`, `Life.kin` and `Life.heir_of`
  (`core/life.gd`; "households are NOT families", `:13-15`). The judgment view of the same graph is
  `JudgmentLive.Social.kin/relatives` (`core/judgment/judgment_live.gd:72-94`).
- Family reputation, extended kin and resentment: `JudgmentBonds.family_reputation` (`judgment_bonds.gd:361`),
  `reach`/`_extended` (`:255`, `:322`) and `resentment` (`:175`).
- Identity: `core/identity.gd` (ID-01) gives permanent person ids. Players are `World.players`/pid,
  `World.player_ref` ("player"/"player:<pid>"), `is_player_ref` and `as_actor` (`core/world.gd:706-835`).
- **What dialogue actually uses:** only the surname string `NPC.family` in a regex over log text (`:396`). This
  misses relatives with another surname (`birth_family`, partners). It wrongly matches unrelated households that
  share a surname. It cannot tell "we did it" from "it was done to us".

## 4. How witnesses and knowledge are recorded

- **One sight channel: `World.near`** (`core/world.gd:2783-2791`). A person sees what happens within
  `witness_radius` (10 tiles) if they are awake, in the same place (the same building interior, or outdoors) and on
  the same level. Nothing is occluded outdoors; there is no ray cast.
- Theft: `World.witness` (`core/world.gd:3341-3375`) writes NPC memory strings and `relations.harmed`, appends to
  `player.crimes` (`:3360`), calls `JudgmentLive.on_theft` (`:3366`) and gets a guard to confront the thief
  (`guard_confront`, `:3400`).
- Assault (PAR-05): `aware_of_attack` (`:3465`) feeds `raise_alarm` (`:3474-3500`). Guards who saw it take the
  attacker as `target`; the victim and the other witnesses get `NPC.report` (`report_crime`, `:3504`). The judgment
  side is `on_attack` (`judgment_live.gd:133`).
- Killing: `World.kill` (`:2620-2661`) calls `relations.slain_by_player` (`:2630`) and
  `JudgmentLive.on_killing(..., Life.PLAYER_ID)` (`:2632`; witnesses are `near(victim)`,
  `judgment_live.gd:144-156`). It writes the log line `:2653`. **Every household member is given "Name died
  (cause)"** whether or not they saw anything (`:2655-2660`), and the cause names the killer. So the household learns
  the culprit automatically, while dialogue ignores the witness who actually saw it.
- Judgment beliefs: `observe`/`observe_all`/`learn` (`judgment_store.gd:463-537`) record the source as participant,
  witnessed, told or rumour, with the teller, hops and confidence. A killing memory is permanent (Q11). Other parts:
  word of mouth (`tell`, `:1309`; scheduled meetings `:1151-1205`), lies (`_maybe_lie`/`_invent`, `:1409-1452`),
  family stories (`tell_family_tick`, `judgment_live.gd:272`; `tell_family_stories`, store `:1518`) and gifts
  (`on_gift`, `judgment_live.gd:177`, seen by those near the receiver).
- Flight recorder codes: `witness_begin`, `alarm_begin`, `report` and `death_begin` (`core/recorder/world_recorder.gd:592`,
  `:636`, `:651`, `:444`). These are diagnostics only.
- **Could Nicholas Dale have had a witness record? Yes.** The reproduction shows a relative in `near()` range gets
  the memory string, the `witnessed` belief and the report. Witnessing worked. **The interpretation is broken**, as
  the directive's branch "repair the dialogue interpretation" anticipates. If Nicholas was indoors, asleep or more
  than 10 tiles away, he would only have the household memory, "Rose died (slain by Maud Berbal)", from
  `:2660`. That still names the killer, without his having seen it.

## 5. Why NPCs talk about their own family and the player in the third person

1. The sentence is written once, in the third person, by `World.note`/`ref_name` when the event happens. The
   structure is discarded (section 1).
2. `Dialogue.news` repeats the stored text verbatim (`:404`, `:414`). It has no speaker, listener or participant model
   to choose "I", "we", "you" or "Mum".
3. The only "you" filter does the opposite of what is needed: `_repeatable` (`:67-69`) *drops* lines addressed to
   the player instead of re-voicing them.
4. `opening`/`brush_off` check `attacked` (the victim only), `animal_killed`, `theft_seen` and `caught`
   (`:206-221`, `:431-436`). Nothing checks "saw ... attack" or the household death, so a witness of a killing falls
   through to the generic greeting ("I don't know you", as reproduced).

## 6. Why significant events come out as casual gossip, and how lines are prioritised

- The only priority is "lines that mention my surname before other lines", then newest first (`:407-412`), capped at
  two. A murder of the speaker's own child sits in the same bucket as a fence. One frame ("Have you heard?" or
  "People are talking.", `:414`) wraps it all.
- `home` has a "gravest first" order (`:365-382`): the latest death memory, then relief, then money, then firewood.
  It renders the death as "We lost X: <cause>.", again showing the third-person cause.
- No significance model links the event type and the speaker's involvement (victim's kin, witness, beneficiary).
  The data exists: the judgment catalog severity (killing 3000, assault 2000, theft 1000), `permanent`, and the
  belief source. No conversation history exists either, apart from "met": nothing stops a line from repeating, and
  nothing records that an emotional line was already said.
- Knowledge is omniscient: every villager can repeat any of the last 300 log lines (`core/world.gd:2709-2711`),
  whether or not they learned of it.

## 7. How crime severity is calculated

There is no single severity model. Several stores each hold a part:

| Crime | Response today | Where |
|---|---|---|
| Theft or pickpocket seen | witnesses remember; nearest free guard who saw confronts: goods back, fine `theft_fine` 10 + 0.5 x value; a friend halves (X19-GUARD: never waived with judgment on) | `world.gd:3341-3375`, `:3392`, `:3400-3462` |
| Theft, fine unpaid | the guard draws a weapon: `g.target = -2`, the same lethal chase as for murder | `world.gd:3452-3453` |
| Theft reported later | the guard fines only if the thief is in sight then; no chase | `deliver_report`, `:3527-3536` |
| Assault | guards who saw it chase; witnesses and the victim report (6 h, 40 tiles); no fine (DVW-B2 approved, not started) | `player_assault` `:2118-2135`; `raise_alarm` |
| Killing | nothing beyond the assault before it: no alarm of its own; `relations.killings += 1`; judgment `killing` (sev 3000, permanent) | `kill` `:2629-2632`; `relations.gd:297-301` |
| Multiple killings | no escalation. `notoriety()` = killings x 3 + crimes seen in 16 days, used only for courtship and contract refusal | `relations.gd:306-313`, `:344-346`, `:474`; `contracts.gd:458` |
| Attacking a guard | the victim guard and the guards who saw it chase; no escalation | `raise_alarm` `:3494-3497` |

Assaults and killings are **not** in `player.crimes`, which holds theft, pickpocket, fencing and kept harvest
(`world.gd:3360`, `:3913`, `:3968`; `quests.gd:481`).

## 8. How guard pursuit states are managed

- **One integer, `NPC.target`** (`core/npc.gd:45`: -1 none, -2 the player, else an NPC id). `World._update_npc`
  runs `brain.fight(n, dt)` whenever `target != -1`, and the guard's schedule stops (`core/world.gd:549-551`).
- `NPCBrain.fight` (`core/npc_brain.gd:2751-2841`) has no states. It walks straight at the target's current
  position at 1.3 x walk speed (`:2780`), strikes when within 1.1 tiles, and **clears `target` on any of**:
  - the target is dead or on another level (`:2757`, `:2766-2771`), or (for an NPC target) has gone into a
    different building (`:2762`);
  - the target is more than 25 tiles away, or (for a guard) the target is near the bandit camp (`:2773-2776`);
  - **the next step lands in a solid cell** (`:2781-2789`, the SIM-F4 "blocked chase" fix: "A blocked chase is
    given up as one whose target is gone");
  - for a bandit, health below 30%.
- After a clear, `plan` is empty, so the next tick runs `decide`, which gives the ordinary schedule
  (`_guard`, `:1706-1734`: provisioning, loot or patrol). Nothing records that a chase took place.
- The player's death clears every chase targeting -2 (`core/world.gd:955-960`).
- `fight` does not use pathfinding. `World._walk` does (`core/world.gd:623-639`, `map.find_path`, AStarGrid2D in
  `core/village_map.gd:11`, `:224`), but only for plan steps.

## 9. The actual reason a guard disengages at a corner

**Pathfinding failure, which the chase code turns into a disengage rule.** `core/npc_brain.gd:2781-2786`: the chase
moves in a straight line, and the first step into a wall cell rolls back the move and sets `n.target = -1`. This is
the SIM-F4 fix, which was meant for bandits stalking through fences. Reproduced: guard and player 8 tiles apart on
either side of a 3-cell wall, with an 11-step A* route around it. The chase ended after 0.75 s, and the guard went
"buying firewood" at once. It is not line of sight: the game has no occlusion, and `near()` would still "see" the
player. It is not a timeout, it is not target memory (there is none to clear), and it is not a schedule override (the
schedule only takes over after the clear).

Second cause (open ground): `:2773`. The player walks at 4.5 tiles/s (sprint 6.75) and the guard chases at 3.38
tiles/s, so a walking player reaches the 25-tile cut-off in about 20 s, and in about 7 s sprinting. Third: a report
delivered later (`deliver_report` `:3539`) sets `g.target = -2` even when the player is more than 25 tiles away, and
the next `fight` tick drops it at once. **A reported crime produces a chase only if the player is within 25 tiles of
the guard at that moment.**

## 10. How guards communicate or request reinforcements

They do not. Guards learn only by:
- seeing it themselves (`raise_alarm`, every free guard in `near()`);
- a witness or the victim walking to the **nearest** awake guard within 40 tiles and telling them face to face
  (`NPCBrain._report`, `npc_brain.gd:2319-2339`; `deliver_report`). One report goes to one guard.

Guards never pass anything to other guards, never share a last-known position, and never call for help. PAR-05 (the
owner's wording) forbids unexplained knowledge and says: "Do not invent unsupported sensing mechanics." "An audible
disturbance where supported" is allowed in principle, but no hearing channel exists ("There is no hearing",
`world.gd:3463`).

## 11. Whether any wanted status persists, and whether it is saved

There is **no wanted status**. What does persist:

| Record | Saved |
|---|---|
| `player.crimes` (theft family only) | yes (`player_state.gd:312`, `:362`) |
| `relations.killings` | yes (`relations.gd:718`, `:763`) |
| Each witness's NPC memory strings (8-item cap) | yes |
| `NPC.report` (pending, lapses after 6 h) | yes (`npc.gd:119`, `:156`) |
| Judgment beliefs and ledgers (killing permanent) | yes |
| `NPC.target`, the chase itself | **no** (absent from `npc.gd:108-121`) |

So a save and reload ends every chase. Guards remember nothing of a suspect.

## 12. Which existing systems can be reused

- **Knowledge, provenance and spread: the judgment store.** Facts with actors, victims and beneficiaries; beliefs
  with src, by and conf; scheduled word of mouth; lies; family stories; permanent murder memories. It is the
  natural source of "what does this speaker know, and how". Q01 already allows NEUTRAL facts that are "recorded,
  remembered and told" without moral weight, which suits purchases, fences, relief, aid and deaths.
- **Morality and opinion (must stay authoritative):** judgment GOOD/BAD ledgers, disposition and
  `family_reputation` (`judgment_bonds.gd:361`), `Relations` regard (`harmed`, kin and friend spread,
  `slain_by_player`), `notoriety()`, and the decision domains that already let opinion refuse trade, credit, barter,
  work and contracts (`judgment_live.gd:18-33`, `:455-602`).
- **Family graph:** `Life`, `JudgmentLive.Social` and `JudgmentBonds` (kin up to second cousins). Household:
  `w.households`.
- **Witnessing and reports:** `World.near`, `aware_of_attack`, `raise_alarm`, `report_crime`/`_report`/`deliver_report`
  (PAR-05, PICK-01).
- **Crime ledger:** `player.crimes` (extend with assault and killing kinds rather than adding a second ledger), and
  `guard_confront` for fines.
- **Danger response:** `JudgmentFamily.danger` and `_threats` (`judgment_family.gd:211-260`; shield, fight or flee
  for heads of household). Today it knows only bandits and angry beasts; a known killer can be added as a threat.
- **Pathfinding:** `map.find_path` / `underground.find_path` (the `World._walk` code). Determinism: `_pick`
  (`dialogue.gd:37`, varies by id and day, no RNG) and seeded hashes.
- **Save pattern:** optional keys with no `save_version` bump (used throughout).

---

# Phase 2: repair plan

## Root causes (one line each)

1. **Gossip:** news is raw, pre-rendered log text joined two lines at a time, newest first. There is no event
   structure, no grouping and no knowledge gate (`dialogue.gd:388-423`; `world.gd:2707`; `world.gd:4386`).
2. **Perspective:** dialogue has no listener and no participant model. It reads only name-keyed memory strings for
   the victim, the theft witness and the catcher, and never the witness-of-violence or judgment records that exist
   (`dialogue.gd:203-234`, `:428-456`). The household death memory hands every household member the culprit's
   name (`world.gd:2655-2660`).
3. **Guards:** the chase is a stateless `NPC.target` with a straight-line walk. A wall step, 25 tiles of distance or
   a late report clears it (`npc_brain.gd:2773`, `:2781-2786`). Nothing escalates, nothing coordinates, nothing is
   saved and no wanted record exists.

## Changes per item

### Item 1 and 2: the event-perspective dialogue layer (one system for both)

- **D1, the knowledge source.** Add a pure reader, `Dialogue` plus a new `core/event_talk.gd` (presentation, no
  writes), that lists what speaker `n` knows. With judgment attached, this is `judgment.memories[n.id]`: belief
  plus fact, src, by, conf and permanent. With judgment off (the Build 18 path), it is the existing NPC memory
  strings, so the fallback is no worse than today. **The omniscient `log_lines` news path is removed.** `log_lines`
  stays as the player's village record.
- **D2, NEUTRAL news facts.** Publish catalog events that already happen as structured facts: `land_bought`,
  `land_leased`, `fenced`, `relief` (manor or chapel), `death` (cause, and killer only as an actor of the separate
  `killing` fact), `no_tool`, `moved_house`, `marriage` (exists) and `gift` (exists). Each publish goes next to the
  `note()` call that exists today (`property.gd:340`, `:356`; `farm_plots.gd:248`; `chapel.gd:306`;
  `npc_brain.gd:2194`, `:3386`; `construction.gd:1392`; `world.gd:2653`). Tags carry the place id and price. They
  are `polarity NEUTRAL`, with no personal rule, so they never touch a ledger (Q01) and the morality stays as it is.
  Participants: a household's events name its responsible adult as actor and the members as beneficiaries, which
  makes "we" correct. Who knows: participants, and those in `near()` where the event has a place. Otherwise they
  travel by the existing word of mouth.
  - Change `world.gd:2655-2660`. Household members learn of the **death**, as a `participant` of the `death` fact,
    but not who did it. The killer's identity comes only from the `killing` fact (witnessed or told). This is an
    agent decision consistent with the directive's "household membership alone must not provide automatic
    knowledge".
- **D3, consolidation (table-driven).** Before rendering, group the speaker's known facts by
  `(subject household or actor, object or place, day window)`. Rules live in data (`game/data/dialogue_events.json`,
  `mml-dialogue-events/1`): `killing` subsumes `assault` of the same actor and victim; `land_bought` plus `fenced`
  of the same plot become one statement; repeated `relief` becomes "again" or a count; `no_tool` attaches as a reason
  clause to `relief`. Keep chronological order inside a group, and keep every fact (price, place, parties, outcome).
- **D4, perspective rendering.** For each element (actor, victim, beneficiary), work out its relation to the speaker:
  self ("I"), own household ("we"), a named kin role from `JudgmentLive.Social.relatives` ("my mother" or "Mum" for
  a child, "my daughter", "our Rose"), the listener ("you", compared by person id or player ref), or other (a short
  name, or "the Lamberts" for a household, with the name given once and a pronoun after). Mark the source: src
  `witnessed` gives "I saw", `told` gives "X told me" or "I heard", `rumour` gives "they say". Templates in the data
  file have variants per relation, chosen by `_pick` (deterministic). Never name an actor the speaker does not
  believe in: if the belief has no actor, the line has none either.
- **D5, priority and repetition.** Score candidates: listener is an actor or victim, then speaker's household is
  victim or beneficiary (by severity), then a recent personal interaction with the listener (gift, help), then
  household developments, then ordinary news. These are the directive's tiers, computed from the catalog severity
  and the relation. Keep a per-speaker "said to <player ref>" set of event ids, with the day; an optional saved key
  (`NPC.talked` or a judgment-section key). An emotional line plays fully once, then in short forms ("I haven't
  forgotten what you did."), with a cooldown, and never loops.
- **D6, the opening and the brush-off.** Before the greeting, check for a known `killing` or `assault` with the
  listener as actor. Choose confront, fear, evade or cold based on: the source (saw or heard: "You killed Rose! I
  saw you." or "They say you killed Rose. Is it true?"), the relation to the victim, the judgment disposition and
  ledger, the personality traits (`JudgmentPersonality`), and the speaker's health or role (a child or elder
  speaker afraid). This replaces the "I don't know you" fall-through.
- **D7, `home()` and household news.** Use the same renderer, so the Oakley child says "The church brought us some
  food. Mum hasn't got an axe..." and acknowledges the player's bread only if they hold the `gift` belief.

### Item 3: justice and pursuit

- **J1, the crime record.** Extend the existing `player.crimes` with kinds `assault`, `killing` and `guard_assault`
  (written by `player_assault` and `kill`; no second ledger). Add a per-offender **case record**, keyed by player
  ref ("player" or "player:<pid>"), in a small `core/justice.gd` owned by World. It holds:
  - the crimes and the severity score from the judgment catalog (`severity` x count, plus guard assault), with a
    tier table in `balance.json` "justice": minor, theft, assault, murder, multiple murder;
  - which guards know (only through `raise_alarm`, `deliver_report` or guard-to-guard sharing, so no omniscience);
  - the last-known position and minute, updated **only** when a guard actually sees the offender (`near()`);
  - the state: open, wanted, or resolved (killed, fined, pardoned, expired).

  It is saved as an optional key (no `save_version` bump). Severity and tier never overwrite the morality ledgers;
  they only drive enforcement.
- **J2, the pursuit state machine for guards chasing a player.** Keep `NPC.target` as the "in combat" flag that the
  rest of the code reads (`Combat.foe`, `counters.gd:66`). Add `NPC.pursuit` {state, offender ref, last_seen pos and
  minute, search cells, until}, saved as an optional key. States: responding, then pursuing, then searching, then
  confronting, then resolved, with coordinating handled as an action inside pursuing or searching:
  - **Pursuing:** follow `map.find_path` toward the offender, re-planned when the target moves more than 2 cells or
    every 0.5 s, instead of the straight walk. The `is_solid` give-up no longer applies to this case.
  - **Losing sight** (not in `near()` of the guard: beyond witness radius or another place) means searching, toward
    the last-known position. Then a bounded search (N nearby walkable cells or doors from a seeded ring) for a
    severity-scaled time. Sight restored means pursuing again.
  - **Resolved:** the search ends with the case still open (wanted). The guard returns to post knowing the case.
  - The 25-tile rule is replaced for this case by the sight and search rule.
  - A late report gives responding (go to the reported place), not an instant drop.
- **J3, coordination with no new senses.** Guard-to-guard sharing happens when two guards are in `near()` of each
  other: case knowledge and the newer last-known position pass from one to the other. This is event-driven: checked
  when a guard's pursuit state changes, and on the guard's hourly tick against the handful of guards. Villagers who
  know the offender and see them report a **sighting** (extend `NPC.report` with `pos`) through the existing
  `_report`. Mobilisation for murder tiers: a guard who learns a murder case breaks off the schedule (on duty) and
  heads to the last-known position; the number mobilised is limited by the guards that actually exist. An *audible*
  alarm (hue and cry or a bell) is an owner decision (below).
- **J4, proportionate force.** Theft stays with `guard_confront`. "Fine unpaid" gives a pursuit at the theft tier
  with a give-up and no lethal blow, *if* a non-lethal mode is approved (below); otherwise today's behaviour stays.
  At the assault tier and above, today's lethal combat applies. Attacking a guard or killing again during a pursuit
  raises the case tier, and the guard pulls in whoever is in sight. Death of the player is reached through ordinary
  combat (`damage_player`).
- **J5, villager responses.** With judgment on, add "a known killer" (an offender whose open case is murder tier, and
  whom the head believes is the killer) to `JudgmentFamily._threats`, which reuses shield, flee and fetching a guard
  (`judgment_family.gd:211`, `:230`). Refusing trade or credit already follows from the BAD ledger through the
  existing decision domains. Check that the player-facing trade paths (`player_quote`, stalls) consult it; if not,
  route through `contract_refusal`/`willing`.
- **J6, multiplayer correctness.** Key the case, pursuit and crime attribution by player ref. In `fight()`, resolve
  a pursuit target through `player_of_ref` instead of `w.player`. **Today a guard targeting -2 chases whatever
  `w.player` is**, which in the simulation is the host, even for a guest's crime (`npc_brain.gd:2755-2757`;
  `raise_alarm` uses `Life.PLAYER_ID`). Judgment, ties and `NPC.target` remain -2 until Batch C, so per-player
  dialogue is only fully correct after Batch C.

## Reused systems (nothing parallel)

Judgment store (knowledge, provenance, spread, ledgers), Relations (regard, harm, notoriety), the Life and
JudgmentBonds family graph, `World.near`/`aware_of_attack`/`raise_alarm`/`report_crime` (PAR-05), `player.crimes`,
`guard_confront`, `JudgmentFamily` danger, `map.find_path`, `Dialogue._pick`. New pieces are thin: `event_talk.gd`
(the renderer), `dialogue_events.json` (templates and grouping), `justice.gd` (the case records), and the
`NPC.pursuit` field.

## Dependencies

- D2 to D7 depend on D1. D3 and D4 need D2 for non-violent news. D6 can ship before D2, because violence already
  exists as facts.
- J2 needs J1 for the give-up length and for keeping the case afterwards. J3 needs J2. J5 needs J1 and judgment on.
- Per-player correctness (D4 "you" for guests, J6 judgment attribution) needs MP **Batch C** (person ids per pid).
  MP-MASTER is on Batch B next, so the repair should key everything new by player ref now and not wait.

## Risks to multiplayer and determinism

- **The gate** (`tools/sim_gate.py`, economy sim with an inert player; documented to run `--sim-args=--no-judgment`
  against `docs/release/sim_baseline.json`, last written at `7551616`). The fingerprint includes every villager's
  position.
  - D1 and D3 to D7 (presentation) and the removal of the log-news path: **no gate change**. Dialogue writes nothing
    except `meet` and the new "said" set, and the sim never talks. Judgment state is not in the fingerprint either,
    but judgment-on decisions move positions and coins, which are.
  - D2 (new NEUTRAL facts): **no change on the judgment-off gate.** With judgment on, the new facts take memory
    capacity (24) and per-meeting and daily telling budgets (2 and 6), so other stories travel less, which shifts
    decision weights. **This changes judgment-on runs.** Mitigations: exempt NEUTRAL news from the moral telling
    budget, or give it its own budget, and keep it out of the ordinary capacity bound. Measure with the judgment-on
    four-seed runs and record the change.
  - Changing `world.gd:2655-2660` (death memory without the culprit): the gate's fingerprint
    (`game/tests/economy_sim.gd:988`) holds id, alive, coins, position, hunger, job and goods, not NPC memory. The
    change is gate-neutral as long as nothing in the simulation reads those strings. Only `Dialogue` does today:
    `home`, `dialogue.gd:366-373`.
  - J1, J2, J4 and J6, **scoped to guards whose pursuit offender is a player:** no gate change. In the sim no player
    crime occurs, so guards never take -2. Bandits do take -2 (`npc_brain.gd:1767`), so the new code must be gated
    on `n.job == "guard" and pursuit`, not on `is_player_id(target)`. **Extending path-following or search to guards
    chasing bandits, or to bandits, would change the gate** (it supersedes the SIM-F4 give-up). Recommend deferring
    that and rebaselining separately with the reason recorded.
  - J3 (guard sharing) and J5 (killer as a threat): no player cases in the sim, so no change. The hourly guard check
    must not consume `w.rng`.
- **Multiplayer:** the risks above. Also NPC memory strings keyed by name. New "said" sets and case records must be
  keyed by player ref, and the `as_actor` guest verbs (`player_assault`, `player_hit_npc`) already run with
  `w.player` set to the guest. `kill()` checks `cause.begins_with("slain by %s" % player.name)` (`world.gd:2629`),
  which is name-based; carry the killer's ref explicitly instead.

## Tests

- **`game/tests/dialogue_perspective_test.gd`** (new, headless, World.new). It reproduces the three reports from
  procedural households (no hard-coded families):
  - a witness elder confronts in the second person ("saw") after the player kills a child;
  - a told kinsman asks ("heard");
  - an unaware villager says nothing;
  - a household purchase and fence render once with "we" for a member and "the <Family>s ... they" for an outsider,
    with price and place kept;
  - a child renders "Mum" or "us" for relief with the reason, and mentions the gift only when holding the belief;
  - assault plus killing collapse into one statement;
  - priority: a murder beats a fence; a second ask does not repeat in full;
  - a guest and the host get the right "you" (after Batch C, or ref-based now for the case parts);
  - judgment off gives the memory-only fallback.
- **`game/tests/pursuit_test.gd`** (new):
  - a corner (the wall from the reproduction) does not end the chase, and the guard reaches the player by path;
  - losing sight leads to a search at the last-known position, then a reacquire;
  - a bounded search ends wanted with no omniscient position;
  - a late report leads to responding, not a drop;
  - two guards share on meeting;
  - an unwitnessed crime alerts no one (the PAR-05 tests in `world_test.gd:684-760` must still pass);
  - theft tier, assault, murder and multiple-murder tiers, and guard assault escalate;
  - the case and pursuit survive save and load;
  - attribution for a guest by ref;
  - a performance bound: guard checks per tick are at most the guard count, timed in the existing profiling.
- **Regression:** `world_test`, `combat_test`, `judgment` tests, `family_first_test`, `wiki_test`,
  `tools/sim_gate.py --sim-args=--no-judgment` (must be identical), the judgment-on four-seed run (measured, and
  changes explained), save-migration fixtures, `tools/check_interactions.py` (new and updated INT entries for
  dialogue, justice and guards), and `tools/check_requirements.py`.

## Implementation order (independently shippable steps)

**Small, safe, independent fixes** (presentation or player-only; gate-neutral; candidates for the build in progress
if it is not frozen):

| Step | What | Hours |
|---|---|---|
| S1 | `opening`/`brush_off`/`home`: read the existing witness record ("saw X attack Y", the judgment `killing`/`assault` belief with the listener as actor) and answer in the second person with saw or heard, with a role- and disposition-aware confront or fear line; stop greeting a witness as a stranger; `home` renders the death of kin as "my daughter Rose" without the cause text | 3-4 |
| S2 | `news`: drop lines naming the listener (re-voice instead of dropping); drop `attacked` when the same victim's death is listed; chronological order. Interim string-level only; superseded by D1-D4 | 2 |
| S3 | Guard versus player only: when blocked, re-route by `map.find_path` instead of clearing `target`; a late report takes the guard to the place, not an instant drop (fixes the corner case; gate-neutral when gated on `job == "guard"` and a player target) | 3-4 |

**Architecture work** (next checkpoint, in order):

| Step | What | Hours |
|---|---|---|
| A1 | J1 case record (`justice.gd`, `player.crimes` kinds, tiers in balance.json, save key, ref-keyed) plus tests | 5-7 |
| A2 | J2 pursuit state machine (pursuit field, path chase, last-known, bounded search, reacquire, resolve to wanted, save) plus pursuit tests | 8-12 |
| A3 | J3 coordination (guard-to-guard sharing, sighting reports, murder-tier mobilisation by real guards) plus J4 escalation (guard assault, violence in pursuit) | 6-8 |
| A4 | D1 knowledge reader plus D4 perspective renderer plus D6 and D7 on the existing violent and gift facts, with the data file of templates; remove the omniscient log news | 8-10 |
| A5 | D2 NEUTRAL news facts at the existing `note()` sites, the death-knowledge change, and the budget and capacity treatment; judgment-on runs measured | 6-8 |
| A6 | D3 consolidation rules plus D5 priority and "said" history (save key) | 5-7 |
| A7 | J5 villager responses (killer as threat in `JudgmentFamily`, refusal check on player trade paths) | 3-5 |
| A8 | J6 MP attribution by ref in `fight` and `kill`; the per-player "you" completes with Batch C | 2-3 now (plus Batch C) |
| A9 | Wiki (crime, guards, talk pages) plus the developer docs (`docs/SYSTEM_INTERACTION_MANIFEST.md` INT entries, DECISIONS agent entries) plus the full regression | 3-4 |

Total: about 8-10 h for S1-S3, and about 46-64 h for A1-A9.

## Owner decisions and conflicts

1. **Guard communication beyond face to face.** PAR-05 (owner wording): "Do not invent unsupported sensing
   mechanics." There is no hearing channel. A murder-tier settlement alarm ("hue and cry", a bell, shouted
   warnings) is a new sensing channel. Options:
   - (a) face-to-face sharing only (guards and villager sightings); fully PAR-05-compliant;
   - (b) an audible hue and cry within a radius from a witness who sees a murder;
   - (c) a manor bell rung by a guard who knows of a murder, audible to every guard on duty.

   Recommendation: (a) now, with (b) as an approved extension.
2. **Arrest, surrender, jail and non-lethal force.** Today a guard either fines or fights to the death; there is no
   subdue, surrender or jail. The directive's "arrest or surrender" and "no lethal combat for minor offences" need a
   new mechanic (CLAUDE.md section 11). They also touch **Q-POL-8 (OPEN)**, "the constable and the law: a constable
   and crime records before Expansion 22". Options:
   - (a) keep fine-or-fight, with the theft tier giving up rather than killing;
   - (b) add yield-at-low-health leading to a fine or confiscation;
   - (c) jail time.

   Recommendation: (b), without a constable.
3. **The wanted status and the heir.** The player's death clears every chase (`world.gd:955-960`). DVW-B2 (approved,
   not started) covers "assault and killing as recorded, fined crimes; heir inheritance of fines/stain"; the details
   are unspecified. Decide whether an open murder case passes to the heir (the stain) or ends with the offender.
   Recommendation: it ends, and the family-reputation spillover that already exists in JudgmentBonds carries the
   social stain.
4. **The DVW-B2 assault fine.** It is approved but its amounts are not set. The amounts are agent proposals unless
   the owner wants to set them. No conflict.
5. **Boundary with Build 23** ("Bandit Factions and Criminal Careers", audit only). The case record should be general
   (offender ref), but no criminal-career behaviour comes here.
6. **Build 20 protection.** `docs/directives/2026-10-24_build20_signing_exception.md` treats Build 20 as the build
   being prepared now, while the register's Build 20 is Living Economy phase 1. This checkout cannot show whether
   the build is frozen. The lead must confirm before S1-S3 go into it.

Not owner decisions (agent decisions to record in DECISIONS.md):
- the household learning of a death without the culprit;
- the NEUTRAL news event types and their telling budget;
- the template wording;
- the severity tiers and search times as provisional balance values;
- scoping the new pursuit to guard-versus-player, so the SIM-F4 bandit behaviour and the gate are unchanged.

No existing owner decision is contradicted: X19-GUARD ("reduce, never waive"), PAR-05, PICK-01/OD-20, X19-Q-TIMING
and the Q01, Q06, Q07 and Q11 judgment rules are all kept.
