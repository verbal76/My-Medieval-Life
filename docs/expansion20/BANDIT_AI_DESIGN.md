# X20-BANDIT-AI: bandit survival, retaliation and pursuit intelligence (design)

Owner directive 2026-10-31 `docs/directives/2026-10-31_sjdh_c4_bandit_intelligence.md` (SJD-H C4), register X20-BANDIT-AI; with
X20-JUDG-C3 (incident counting, `docs/directives/2026-10-31_sjdh_decisions_le05_authorization.md`). Branch `wip/x20-bandit-ai`.
Developer reference: bandits are not a player-facing system with a wiki page of their own; the wiki's existing bandit text
(they rob, they can be fought) stays true.

## Principle

A bandit in danger decides as a villager head in danger does (FAMILY-01, `JudgmentFamily.danger`): through the one shared
interface, `JudgmentWeighting.choose`, with its own personality (each person's weight spread, stubbornness, anger), from what
it can perceive and what it has been through. Nothing is added to health, damage, speed or any combat number (point 4). No
target death rate (directive). The whole layer is behind `decision.integration.bandit_danger` (on as shipped; off is exactly
the Build 24 behaviour, tested), as every judgment decision point is.

## The ten points, mapped to existing mechanisms

| # | Directive | Mechanism | Where |
|---|---|---|---|
| 1 | Recognise pursuit, threat, being surrounded or outnumbered, from information reasonably available | `JudgmentBandit.perceive`: only the people in sight (`World.near`: within witness_radius, awake, same place, same level). Threats: those whose target is the bandit (coming at it) and guards in sight; allies: bandits in sight; a companion in need: an ally in sight with someone coming at it; a blocker: an attacker within cornered_radius on the way to the camp | judgment_bandit.gd |
| 2 | Anticipate retaliation from actions, experience, witnessed events, word from other bandits | wariness: routs it survived (its practical-wisdom record, `JudgmentPersonality` CH_MISTAKE "bandit_routed", via the existing `JudgmentLive.costly_mistake`) and violent bandit deaths it knows of (death news, now published for bandits: seen by those near the body, told on by word of mouth in the band's shared hours) | judgment_bandit.gd `wariness`, judgment_live.gd `on_death`, relations.gd `hour` |
| 3 | Being hunted raises tactical aggression where appropriate; a cornered bandit may strike an escape-blocker | `break_out`: cornered (a foe barring the way to the camp), weighed by its health; chosen over keeping on falling back when the way is blocked; the blow is the ordinary fight | judgment_bandit.gd `decide` |
| 4 | No increases to health, damage, speed or combat statistics | none touched; the fall-back walks at the existing go speed 1.2 | — |
| 5 | Fight, flee, hide, regroup, defend companions, ambush, from numbers, equipment, injuries, stamina, personality, relationships, escape | options press / retreat (to the camp, where the band is: the regroup) / break_out / defend; factors outnumbered and advantage (numbers in sight), hurt and able (health), wary (experience), bond (Relations regard and friendship), cornered (escape); personality through `choose` (trait spread, stubbornness, anger). Equipment and stamina: the game has no per-NPC stamina and every bandit carries the same copper sword, so neither varies between bandits yet (stated limitation). Hide and ambush: no existing hiding or ambush mechanic to use (stated limitation; not invented here) | judgment_bandit.gd |
| 6 | Cooperation by relationships, awareness, motivation, not universal loyalty | `on_struck`: a bandit struck in sight of fellow bandits; each free one weighs keep_on / defend (bond with the struck one, the odds) / retreat. The bond comes from the band's shared hours (Relations: bandits now share hours among themselves, never with villagers), so a stranger in the band is left to it | judgment_bandit.gd `on_struck`, relations.gd |
| 7 | No repeated hopeless combat | a retreat once begun is kept (`under_way`) while the way is open; struck while falling back it weighs again (break out only if blocked); press is not offered while retreating. The re-robbing loop (below) is removed at its cause | judgment_bandit.gd, npc_brain.gd |
| 8 | Villagers still organise and win retaliation | nothing in the villagers' family defence, reports, guards or pursuit changes; bandit_ai_test shows three villagers running a lone bandit down in the open | — |
| 9 | Same judgment principles for both populations | the same `JudgmentWeighting.choose`, personality layer, Relations ties and word of mouth as villagers | — |
| 10 | Learn through existing memory, judgment, experience | practical wisdom (routs), news memories (losses), Relations (bonds); no separate AI store, nothing new saved (the fall-back and the chosen prey are transient, like a chase target) | — |

## The re-robbing loop (defect, fixed at its cause)

`NPCBrain.fight`: a bandit's strike at any non-guard villager ran the robbery branch. After robbing its prey it makes off; the
victim (or a defender) strikes it; the blow sets the bandit's target to the striker; the next strike "robs" the striker again,
every two game minutes, down to robberies of nothing, while the striker's blows land on a bandit that never fights back. Fix
(with the flag on): the robbery is of the prey the bandit chose (`NPCBrain.bandit_prey`, set where `_bandit` picks it), once
per encounter; a striker is fought (or fled from) by the weighing above. Off: unchanged.

## Incidents (X20-JUDG-C3)

One continuous fight (the X19-EVENT-Q window, `self_defence.fight_minutes`) is one assault incident; distinct offences keep their
own facts (theft, killing); each victim apart; a robbery that took nothing is `attempted_robbery` (BAD, PROVISIONAL severity 1
point); a new encounter after the window passed is a new incident. `JudgmentStore.incident`, `set_incident`; the fight record
saves its incidents as two optional trailing values.

## Numbers (PROVISIONAL agent values, judgment.json)

Profile `bandit_danger` weights: live_order 300, advantage 300, able 200 (press); outnumbered 500, hurt 400, wary 300,
under_way 600 (retreat); cornered 700 (break_out); bond 500 (defend; with advantage). `decision.bandit`: cornered_radius 2.5,
wary_days 8, wary_per_rout 25 points, wary_per_loss 15 points, friend_bond 30 points, rout_cost_points 2.

## Tests

`game/tests/bandit_ai_test.gd` (controlled encounters: outnumbered retreat and holding to it, cornered break-out, aid to a friend
and not to a stranger, no re-robbing, villagers winning, no repeated hopeless combat, off unchanged; 12 checks, written to fail
without the layer: 6 behaviour checks fail with the flag off). `game/tests/judgment_incident_test.gd` (C3, 15 checks).
`game/tests/bandit_diag.gd` (read-only long-run diagnostics: BANDIT_DEATH and BANDITS lines).
