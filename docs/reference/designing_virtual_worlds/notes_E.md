# Notes E: Bartle, *Designing Virtual Worlds*, part E (book pp. 456-616)

Source: `part_E.txt`, read in full (6,352 lines). **Coverage note:** the file runs from the end of
Ch. 4 (p. 456, "World Design": ownership, time, proactive physics, reset strategy) through Ch. 5
"Life in the Virtual World", and stops mid-sentence at **p. 616** (player-created content and
intellectual property). It does **not** reach p. 626. It also holds **no dedicated sections on NPCs,
mobiles, AI or quests**. Those subjects come up only in passing here (NPCs in hardwired groups
p. 525; quests as a "requested reset" p. 465; "favors for the gods" p. 560; NPC justice p. 556).
The NPC/AI/quest guidance below is therefore taken from those passing mentions and from the
combat, death and group sections. It is not drawn from a chapter on the subject, which this part
does not contain.

Game context used: single-player Godot life sim; permadeath continued through heirs
(`World.continue_as_heir`: heir keeps home, chest and family property, carries only the start kit,
starts every skill from nothing); 9 skills in `game/data/skills.json` (mining, woodcutting,
smithing, crafting, cooking, combat, magic, trading, stealth), 10 levels, xp per action through
`main.gd::_xp`; autonomous NPCs with needs, jobs, succession and ageing.

---

## 1. Section-by-section summary

### Ch. 4 tail (pp. 456-465)
- **Ownership of movable things (p. 456).** Carried items, carts, horses and land need different
  ownership tracking. Stolen goods sold on raise the question of whether the buyer must return
  them, and a mule character can launder theft.
- **Time (pp. 456-460).** Time must map to real time but need not equal it. Travel at true speed
  shrinks the world. Non-linear time is possible: night (NPCs asleep) passes faster than day.
  Seasons have gameplay uses; years rarely do unless the world has a story arc. If a world keeps its
  own calendar, real-world holiday content clashes with it. Day and night: a strict model has most
  NPCs asleep at night and "a different set of monsters awake". Night can be real darkness or
  suggested darkness (a blue wash). Low light is also a display problem on weak screens. Night is
  colder too, which designers rarely model (fn 96).
- **Proactive physics (pp. 460-462).** World physics can be used to serve real-world ends. Bartle
  accepts this only when it increases freedom.
- **Reset strategy (pp. 462-465).** Sudden versus rolling resets. A rolling reset returns content
  "piecemeal at a rate roughly equivalent to that at which it is consumed". Triggers can be fixed
  (timers), contextual (metrics), requested (quests) or geographical (spawn-on-proximity, "faking an
  ecosystem"). Every kind of reset works against immersion: a sudden one is a big jolt, a rolling one
  a constant drip.

### Advancement (pp. 466-491)
- **Single versus multiple advancement (pp. 466-468).** Single advancement is focused and lets
  players switch focus without wasting effort. Multiple advancement is better when the mechanisms
  really differ.
- **Attributes (pp. 468-470).** In principle attributes are fixed physical traits; ageing could
  shift them. In practice they drift into skills and become homogenised ("puny geniuses and
  muscle-bound simpletons").
- **Levels (pp. 470-475).** Levels are goals: a step function gives the feeling of a step. Pacing
  matters both ways. The variable-ratio schedule is effective and ethically questionable. Curves
  start near doubling and then flatten. Characters at very different levels cannot share content.
  Points should reward exciting acts, not tedium. Levels can be applied to individual skills.
- **Skills (pp. 475-477).** Four kinds: binary (feats), discrete, continuous, binary-continuous.
  Skills are passive or active; active ones are increasingly called "powers".
- **Skill organisations (pp. 477-479).** Linear, hierarchy, network. Use one mechanism for all
  skills and attributes. Skills can apply to objects too (a shield deflecting, a wand casting).
- **Skill sets (pp. 479-483).** If more than 90% of characters take a skill, or nobody does, give it
  to everyone. The skill set sends a message: a deep weapon tree beside a single mining skill says
  "this world is about combat". Detail out of proportion to importance is "selective depth". Give
  even cosmetic skills tangible value. Multi-purpose skills (an axe for combat and for felling)
  create grinding incentives.
- **Caps (pp. 483-487).** Without caps characters grow all-powerful. With caps they max everything.
  "The only solution … truly guaranteed" is permanent death. Steep curves only delay the problem.
  Atrophy (Ultima Online) is unpopular because rusty is not the same as forgotten. A "power hour"
  caps time instead.
- **Skill improvement (pp. 487-491).** Random-chance versus cumulative-bin increments; related skills
  can preload the bin. The opportunity to improve can come from success, from near-failure (Bartle's
  favourite), from levelling (unrealistic but easy to balance), from **use of your products by
  others** (Star Wars Galaxies: crafters gain when people buy their goods) or from purchase. Never
  let a skill speed up learning (fn 22). Ask whether skill numbers are proportional or just noise.

### Character generation (pp. 491-509)
- **Appearance (pp. 491-495).** Mostly intangible. The first act of identity, which players later
  outgrow. Many players accept the random default.
- **Methods (pp. 495-501).** Random (points-balanced), pick points with rising costs, flaws and
  advantages, **kits** (a starting direction that does not lock the player in), questionnaires,
  **tabula rasa** (a chosen life history yields skills plus a written backstory, as in Darklands;
  Bartle's favourite, rarely used online "because it implies that characters age"), and essays.
- **Physical differences (pp. 502-506).** Gender differences are usually cosmetic for good reasons.
  Births and beards cannot be dismissed. Tangible ability differences carry real-world
  consequences.
- **Long-term characters (pp. 506-509).** Ageing implies decay and death, which players resist; they
  must supply the experience that makes an older character better. Virtual children raise a long
  list of problems: conception, custody, education, orphans, who plays the adult child. The
  exceptions where children make sense are historical or realistic worlds, worlds about children,
  and **permanent-death worlds that use children as an inheritance fiction** (p. 509).

### The virtual body (pp. 509-519)
- **Maintenance (pp. 510-511).** If every player must do the same boring routine, nobody should
  have to. Abstract the routine, but keep each of its actions available on demand.
- **Survival (pp. 511-513).** Immunity to the environment removes the reasons for houses,
  settlements, healthcare and mutual defence. The tedious parts of reality set up the enjoyable
  ones.
- **Senses (pp. 513-517).** Options for darkness: suggest it, give a trivial remedy, make it
  temporary, or play it straight. Dynamic descriptions can vary with a character's skills (a
  historian notices "antique").
- **Body composition (pp. 517-519).** Bodies are assemblies; restraints, damage and flaws disable
  parts. Don't build an anatomical simulation: "a spear through the chest means … dead".

### Groups (pp. 519-528)
- Groups vary along several axes: formal or informal, temporary or permanent, flat or hierarchical,
  **hardwired** (built into the world: ruling, military, religious, judicial, guild, educational,
  law enforcement) or player-made. NPCs join hardwired groups easily; nobody wants guard duty, so
  NPCs do it.
- **Hierarchies need downward incentives.** Asheron's Call allegiance trickled experience up and
  nothing down. The belief that you can rise is critical.
- **Automated succession** stops a group collapsing when its leader leaves.

### Combat (pp. 528-558)
- **Mechanism (pp. 529-532).** MUD1 used attrition hit points chosen for gameplay. Real medieval
  combat is different: a telling wound takes a fighter out of the battle and often kills later
  through infection.
- **Enhanced systems (pp. 532-536).** Reaction and recovery times, one-off attacks, stances, hit
  location, damage types, wound levels, critical hits (which keep losing players fighting),
  afflictions, combat scripts. Complex combat tends to dominate the whole world.
- **Problems (pp. 536-539).** Equaliser weapons, mixed weapon systems, over-robust defence,
  concurrent combat and ganging up, targeting, area effects, twitch, number of combat skills,
  **disengaging** (can I run, do you hack at me as I go, can I surrender). The test: will it work,
  keep players immersed, be fun, and will players accept it?
- **Opposition (pp. 539-549).** PvE, PvP and GvG; consent; arenas and flags; RvR. Aim for
  **equilibrium, not balance**: advancing gets harder the further a side pushes. Marian's tailor:
  non-combat careers must not be forced to take up arms.
- **Consequences (pp. 549-555).** Players want to judge risk by looking. Stake and prize must match
  the risk. Outcomes are victory, inconclusive or defeat. Death by old age or disease is usually
  removed from virtual worlds. Death the world causes is accepted as "my fault or bad luck"; death
  another player causes makes people angry.
- **Permanent death (PD) (pp. 552-558).** Unmoderated, post-moderated, world-moderated (karma, NPC
  justice, grudges), player-moderated, opt-in, opt-out, and inevitable-but-distant (old age, which
  only forces a fresh start).

### Alternatives to PD and their consequences (pp. 558-590)
- **Alternatives (pp. 558-562).** Don't call it "death" unless it is. The alternatives are
  resurrection, insurance, ghosts, a realm of the dead, left for dead, not a fight to the death,
  **inheritance** ("perhaps the best of these alternatives"; works best when characters are defined
  by possessions; players "treat it basically as resurrection"; the fiction is "stretched so thin as
  to be transparent"), and no explanation at all. "If you do, bite the bullet."
- **Costs of PD (pp. 563-566).** People leave over it. Keep incidence low and awareness high. Deaths
  that feel arbitrary or unavoidable drive players away. Without a strong elder game, PD combined
  with PvP breeds killers.
- **Costs of no PD (pp. 566-573).** Sandboxing (the first to power keep it), the irresistible rise,
  the treadmill, content consumed only once, item inflation and **twinking** (PD normally removes
  the kit you carried). Non-death clashes with historical authenticity. Say nothing rather than give
  an unconvincing fiction.
- **Why PD (pp. 573-577).** Without real loss, achievement and heroism are hollow. "Acts are only
  heroic when there is a significant, perceived chance of real loss and no easier alternative." The
  actual risk is usually lower than players perceive (fn 86). If you can't lose it, you don't value
  it. "If everyone is a hero, no one is", but everyone can be a hero at different times.
- **Hero's journey (pp. 577-588).** Campbell's departure, initiation and return, mapped onto player
  development. Virtual worlds lack an **ultimate boon**: "something special that players can only
  ever obtain once" (p. 587). MUD1 put its wizards' names on tombs in a graveyard (fn 94).
- **Attitudes (pp. 589-590).** Players lean against PD. A switch from PD to no PD had no effect on
  the number of complaints.

### Crafting (pp. 590-599)
- **Manufacture (pp. 591-593).** Raw, refined, component, finished, consumed, recycled. Crafting
  excitement "approaches 0%", even in deep chains (A Tale in the Desert); the fun comes from trading
  components. Three golden rules: every craft has gameplay value, the range of products is wide, the
  skills are deep. "Anything that impresses PCs should also impress NPCs." Identical goods to NPC
  smiths only sell at a lower price.
- **Recipes (pp. 593-595).** Secret, patented or individualised recipes all fail; recipes become
  common knowledge.
- **Offline action (pp. 595-599).** Hired NPC vendors, queued orders, banked time, skill learning
  that takes time, travel during offline time. Limit it so nobody builds a mule factory.

### Elder game and player-created content (pp. 599-616)
- **Elder game (pp. 599-605).** Players past the end need different things. Politics and building
  generate their own content. "The human thing" is to recognise a rite of initiation rather than
  add endless ladders.
- **Player-created content (pp. 606-616).** In-context versus out-of-context building, quality
  vetting, sandbox safety (recursion, quotas), and intellectual property. The text breaks off at
  p. 616.

---

## 2. Principles that apply (short verbatim quotes)

| # | Principle | Quote | Page |
|---|---|---|---|
| P1 | Abstract repetitive maintenance | "if every player has to do exactly the same boring thing, none of them should have to do it." | 511 |
| P2 | Keep the abstracted actions available | "Routine maintenance should always be abstracted, but the actions that it abstracts should also be available independently" | 511 |
| P3 | Survival pressure creates community | "If they don't have anything from which to shelter, they don't have to live in houses." | 512 |
| P4 | Day/night ecology | "A strict implementation would have most NPCs asleep at night and a different set of monsters awake." | 459 |
| P5 | Non-linear time | "time at night (when NPCs are asleep) passes quicker than time during the day" | 458 |
| P6 | Rolling regeneration | "content is returned piecemeal at a rate roughly equivalent to that at which it is consumed." | 462 |
| P7 | Levels as felt steps | "Levels use a step function because players like to feel they have taken a step." | 471 |
| P8 | Reward excitement, not tedium | "points should be awarded for things you find exciting, rather than as some kind of compensation for being fed up." | 474 |
| P9 | Universal skills | "if any one skill is adopted by more than 90% of characters, they all ought to get it." | 481 |
| P10 | The skill set is a message | "If you want crafting to be a viable career, the skill tree for crafting should be deep enough for people to take it seriously." | 482 |
| P11 | Avoid selective depth | "Crediting skills with a false sense of importance this way is a particular example of selective depth" | 482-483 |
| P12 | Give skills tangible value | "if you can find a way to give tangible value to skills, you should do so." | 483 |
| P13 | Multi-purpose skill grinding | "characters will become lumberjacks so they can increase their axe skills while making money." | 483 |
| P14 | PD is the true cap | "The only solution that is truly guaranteed to stop this from happening is permanent death" | 484 |
| P15 | No skill decay | "Being rusty at something is different than completely forgetting all about it." | 485 |
| P16 | No learning-speed stats | "Don't have skills or attributes that affect how quickly characters learn skills." | 488 (fn 22) |
| P17 | Learn from near-failure | "characters should get a skill enhancement opportunity for coming close to success but not actually succeeding." | 488 |
| P18 | Crafters gain when their goods are used | "the more people use the products of your skill, the more skill points you get." | 489 |
| P19 | Avoid pure random increments | "you may never gain a skill point while your luck is out, and you will complain loudly about this." | 487 |
| P20 | Kits give direction without a class | "the character kit you start with points you in a direction of your choosing, but you don't have to follow it." | 498 |
| P21 | Tabula rasa backstory | "When it stops, not only can a character be created, but a short history, too." | 500 |
| P22 | Children fit PD inheritance | "Virtual worlds with permanent death, where children are used in an inheritance fiction to replace dead characters." | 509 |
| P23 | Hardwired groups suit NPCs | "Few players will care to stand around bored for hours on guard duty" | 525 |
| P24 | Hierarchies need downward rewards | "Most people need no incentive to be the boss of other people, but they do need incentive to be bossed by them." | 524 |
| P25 | Automated succession | "institute automated rules of succession so that groups always have leaders" | 528 |
| P26 | Medieval wounds incapacitate | "once someone suffered a telling wound they could take no further part in the battle" | 532 |
| P27 | Crits keep losers fighting | "players who are losing a fight might stay rather than flee, in the hope that they can pull out a critical hit" | 535 |
| P28 | Complex combat dominates | "Few virtual worlds with an immensely complicated combat system avoid being completely dominated by it" | 535 |
| P29 | The combat acceptance test | "Will it work? / Will it keep players immersed? / Will it be fun?" | 539 |
| P30 | Equilibrium, not balance | "so long as it becomes increasingly harder to do so the more they advance." | 547 |
| P31 | Marian's tailor | "what's the point of putting in tailoring as a career if everyone is eventually forced to become a fighter anyway?" | 549 |
| P32 | Readable risk | "Players like to know their risks in advance. They like to be able to tell by looking whether or not they can beat a potential foe" | 549 |
| P33 | Always allow flight | "it should always be possible to cut your losses and flee from a fight." | 555 |
| P34 | Deaths the world causes feel fair | "players will be incredibly annoyed but will rapidly conclude that it was either their own fault or the result of incredible bad luck" | 554 |
| P35 | Low incidence, high awareness | "keep the incidence of PD low but the awareness of its possibility high" | 563 |
| P36 | Arbitrary death drives players away | "if it occurs too often or too unexpectedly, so that players feel it's either arbitrary or unavoidable, even those players who came may decide to go." | 565 |
| P37 | Inheritance works when possessions define a character | "This works best in materialistic virtual worlds that define characters by their possessions more than by their attributes." | 561 |
| P38 | Inheritance can collapse into resurrection | "they treat it basically as resurrection" | 561 |
| P39 | Commit to PD | "As a designer, either you want or you don't want PD in your virtual world. If you do, bite the bullet and have it." | 562 |
| P40 | Sandboxing | "the people who are first to positions of power get to keep them." | 566 |
| P41 | PD removes carried kit, which limits twinking | "PD usually involves the total loss of all the kit you had with you when you died." | 570 |
| P42 | Prefer silence to a weak fiction | "saying nothing may be better than saying something unconvincing" | 571 |
| P43 | Heroism needs real risk | "Acts are only heroic when there is a significant, perceived chance of real loss and no easier alternative." | 575 |
| P44 | Perceived risk above actual | "the actual risk of PD is generally lower than players estimate it to be" | 574 (fn 86) |
| P45 | Value requires possible loss | "if you can't lose something, you don't value it" | 575 |
| P46 | Ultimate boon | "it should be something special that players can only ever obtain once." | 587 |
| P47 | Recognise completion | "the human thing to do would be to add a recognition that the player has undergone a rite of initiation." | 601 |
| P48 | Crafting golden rules | "All crafts should have gameplay value. / The range of craftable objects should be great. / The depth of crafting skills should be deep." | 592 |
| P49 | NPCs react to quality | "Anything that impresses PCs should also impress NPCs, even if only crudely so by comparison." | 593 |
| P50 | Avoid flooding | "people will end up making the same things and flooding the economy with more goods of one type than it needs." | 593 |
| P51 | Recipes become known | "once a recipe is unearthed it rapidly becomes common knowledge." | 595 |
| P52 | Learning should take time | "Learning how to make a pot isn't something that occurs the instant you hand over your training fee" | 597 |
| P53 | World justice sees only tangible acts | "it can only ever track tangible actions" | 556 |
| P54 | Laundering stolen goods | "If I steal a sword and sell it for gold, does the new owner have to hand it back to the original owner?" | 456 |
| P55 | Illness rage | "players would seethe with rage if their characters were merely confined to bed with influenza" | 551 |

---

## 3. Actionable items for My Medieval Life

Each item gives the principle, the page and a priority. Items that change a gameplay mechanic need
the owner's approval (CLAUDE.md section 11) and are marked **[owner]**.

### Death / heirs
1. **HIGH: fix the contradictory heir rule in the code comments.** In `game/scripts/core/world.gd`
   around line 471, the comment says "the heir keeps the house, the chest and half of each skill's
   experience". The doc comment on `continue_as_heir` (around line 486) says the heir "starts every
   skill from nothing". Check which rule `docs/BUILD_DECISIONS.md` records and correct the stale
   comment. A PD design must be clear about what is lost (P39, p. 562; P45, p. 575).
2. **HIGH: make lethal risk readable before the fight (P32 p. 549, P35 p. 563, P36 p. 565).**
   - Give predators, bandits and later skeletons a visible threat cue relative to the current
     heir's combat level (con-colour or an "outmatched" marker).
   - Warn before needs become lethal (hunger and health stages).
   - Show the cause of death and the last few blows or causes on the succession screen
     (`p.death_cause` already exists), so the player concludes "my fault or bad luck" (P34, p. 554)
     rather than "arbitrary".
3. **HIGH: guarantee disengagement (P33, p. 555; disengaging, pp. 538-539).** Wolves, bears and
   bandits need a defined give-up rule: lose interest beyond a leash distance or time, and no
   free hits on a fleeing player beyond one swing. The player's sprint must be able to outrun or
   out-last at least the ordinary threats. Add a test that a full-health level-1 heir can escape
   one wolf and one bandit.
4. **HIGH: make heirs feel like successors, not resurrections (P37/P38, p. 561; P22, p. 509).**
   Inheritance already keeps home, chest and property, so possessions carry the line (which Bartle
   says suits inheritance). To stop players reading it as a respawn, the heir should differ in a way
   the player can see: their own name, age and appearance (already the case when the heir is the
   player's child), plus a short "tabula rasa" line on the succession screen listing what they grew
   up doing (P21, p. 500).
5. **MEDIUM [owner]: let the player shape the heir before death (P21 p. 500; children's
   education question p. 508).** Option: the player can apprentice or teach their child, so the heir
   starts with a small amount of experience in that trade. This conflicts with the current owner
   rule ("an heir inherits only" the start kit), so it is an owner decision, not a change.
6. **MEDIUM: test the children edge cases from Bartle's list (p. 508).** Cases to cover:
   - the player dies while every child is under 16 (who raises them, and do they become heir
     later?);
   - the player's household is gone or homeless;
   - the partner survives;
   - siblings who stay villagers keep consistent kin links (`Life.retire_player_id`).
7. **MEDIUM: record the line, a "graveyard of wizzes" for single-player (P46 p. 587; fn 94;
   P47 p. 601).** Add a family chronicle (a wiki page, or graves in the churchyard) listing each
   generation: name, life span, trade levels reached, property gained, cause of death. This gives
   the player a once-only recognition per life.
8. **MEDIUM: watch for twinking through the family chest (P41, p. 570).** Carried gear is lost
   where the player fell, which is good. The chest, though, passes the ancestor's best sword and
   armour straight to a level-1 heir, which lowers the stake. Options: accept it (it fits the
   possessions-based inheritance fiction), or require a combat level to wield top gear well.
   **[owner]**
9. **MEDIUM [owner]: stop the family's wealth growing without limit across generations (sandboxing,
   P40 p. 566; caps P14 p. 484).** Skills reset with each heir, but property and coin accumulate
   indefinitely. A historically grounded sink is a heriot or relief paid to the manor treasury on
   succession, such as the best beast or a fee. It ties into the existing manor taxes.
10. **MEDIUM: make illness curable and signalled (P55, p. 551).** If the health need can kill
    slowly, every case must show symptoms, name a remedy (poultice, tonic, the apothecary) and
    leave time to act. Incurable sickness reads as arbitrary PD (P36).

### Advancement
11. **HIGH: review the skill list's message and selective depth (P10 p. 482, P11 pp. 482-483).**
    The 9 skills do not include farming, animal husbandry, hunting or healing, yet the brief makes
    those core life-sim activities. Meanwhile combat has four numeric effects (damage, attack time,
    damage taken, crit) and magic three fireball effects. A missing farming skill tells players
    farming doesn't matter. Propose farming and husbandry (or hunting) skills with depth comparable
    to mining. **[owner]**
12. **HIGH: award xp for meaningful acts, not repetition (P8 p. 474, P17 p. 488).** `_xp` gives fixed
    xp per action. Scale xp by task difficulty relative to level: stone at mining 9 should give
    little, gold ore a lot. Optionally give partial xp for near-misses, such as a failed pickpocket
    that was close or a combat exchange you survived. Check with the economy simulation that no
    single spam loop (chopping, cheap trades) is the fastest path.
13. **MEDIUM: give crafting xp when NPCs use the player's goods (P18, p. 489).** When a villager or
    merchant buys a player-made tool, cart wheel or loaf, or wears or uses it, award smithing,
    crafting or cooking xp. This fits the "real demand" economy and keeps crafters making what
    villagers need, not what flatters the xp curve. Trading already gets xp per sale
    (`Skills.trade_xp`).
14. **LOW: check the curve's pacing (P7, p. 471).** `step_base` 100, `step_growth` 0.25, 10 levels.
    Measure the real minutes per level on Android sessions so early levels come in a session and
    late ones span an heir's life. Remember each heir restarts, so the curve is replayed every
    generation.
15. **LOW: keep the safeguards Bartle recommends (P15 p. 485, P16 p. 488, P19 p. 487, P51 p. 595).**
    No skill decay; no effect that speeds learning (`Skills.EFFECTS` has none, so keep it that way);
    deterministic cumulative xp rather than random increments; recipes listed openly in the wiki
    rather than secret.
16. **LOW: related skills learn faster (p. 488).** For example, smithing experience preloads
    crafting, and woodcutting preloads carpentry recipes. Only if a cheap version exists.
17. **LOW: avoid a multi-purpose axe loop (P13, p. 483).** Confirm woodcutting xp never raises
    combat and that combat xp never comes from felling.

### NPC AI
18. **MEDIUM [owner]: abstract the player's routine needs, but keep them under the same rules
    (P1/P2, p. 511).** NPCs and the player share hunger and sleep, which serves the owner's "same
    rules" intent. On mobile, offer an "eat from pack or pantry when hungry" option and a sleep
    shortcut, while keeping the explicit actions. The rule stays the same; only the routine is
    automated.
19. **MEDIUM: day/night ecology (P4 p. 459, P5 p. 458).** Check that most villagers sleep at night
    and that night brings different threats: wolves more active, skeletons out of caves if that is
    ever approved. Let sleeping pass night time faster. Darkness should be suggested (a tint plus a
    light radius) rather than black, because of the Android screen problem raised on p. 459.
20. **MEDIUM: provocation in the guard and fine logic (P53, p. 556).** World-moderated justice sees
    only tangible acts. Check that the guards treat the first attacker as the aggressor, so a player
    who fights back against a bandit or a hostile villager is not fined. Add tests.
21. **MEDIUM: laundering stolen goods (P54, p. 456).** Stolen marks (`chest_stolen`, `trim_stolen`)
    exist. Decide and test what happens when stolen goods are sold to a merchant: do the marks
    follow the goods, does the merchant become a fence, does the owner reclaim them? Make the
    behaviour deliberate.
22. **LOW: succession in hardwired posts (P23 p. 525, P25 p. 528).** Guards, the reeve, the sage and
    the merchants are hardwired groups staffed by NPCs. `NPCBrain` succession already refills posts.
    Add a long-run simulation test that no post stays empty for more than N days.
23. **LOW: rewards for working under someone (P24, p. 524).** Where the player takes manor work or
    an apprenticeship, being "bossed" needs tangible downward rewards: wages, training xp, a path to
    take over the post. Not just upward obligations.

### Combat
24. **MEDIUM [owner]: medieval wounds rather than pure attrition (P26 p. 532; wound levels and
    afflictions p. 534).** A light wound-or-bleed state that bandages and poultices cure would give
    the healing chain (cloth to bandages, flowers to poultices) gameplay value (P48, p. 592). Keep
    it simple (P28, p. 535) and run it through the acceptance test (P29, p. 539).
25. **MEDIUM: equilibrium between bandits and the village (P30, p. 547).** Bandit poaching and
    robbery should meet stronger guard response, or lose hideouts, the further they push. The
    village should not be overrun, and bandits should not be wiped out for good either.
26. **MEDIUM: Marian's tailor for single-player (P31, pp. 548-549).** A merchant or farmer heir must
    be able to live without fighting. Give bandit robbery non-combat counters: hand over the purse,
    travel with the caravan, hire a guard escort, avoid roads at night, or report to the reeve.
27. **LOW: crit and flee interplay (P27, p. 535).** `crit_chance` can tempt a losing player to stay
    in a PD fight. Show enemy health so staying is an informed gamble.
28. **LOW: concurrent attackers (p. 537).** Cap how many pack wolves or bandits can hit at once, or
    add a flanking penalty, so packs are dangerous but survivable by fleeing.

### Monsters / skeletons (planned)
29. **MEDIUM: decide how cave skeletons regenerate (P6 p. 462; geographical and proximity resets
    p. 465; P42 p. 571).** "Nothing comes from nowhere" rules out plain timer spawns.
    - Use geographical, out-of-sight regeneration tied to a fiction (barrow dead, a cursed depth),
      or make them finite per cave.
    - If no convincing fiction exists, say nothing rather than give a weak one.
    - Skeletons are not in Morris, so label them GAME EXPANSION in the world docs.
30. **LOW: cave darkness (p. 515).** Use the "trivially easy remedy" option (a carried torch or
    lantern from the existing chains) with a light radius. Not total blackout.

### Wildlife
31. **HIGH: grow herds back in proportion to what is taken, out of sight (P6 p. 462; "faking an
    ecosystem" p. 465).** Grazers and predators should repopulate through births from the surviving
    population, off-screen, at about the rate they are hunted. No respawn points at fixed spots.
    Bandit poaching and player hunting draw on the same stock. Add a balance test that steady
    hunting reaches an equilibrium rather than extinction or a population explosion.
32. **LOW: readable threat by look (P32, p. 549).** Fox, wolf and bear sprite size already signal
    danger. Keep stats ordered so that size matches threat.

### Quests
33. **MEDIUM: heroic quests need real risk and no easier route (P43, p. 575).** Quests from
    villagers' real needs are good self-generating content. A "dangerous" errand that can be met by
    buying the item at the market next door is "swimming next to a bridge". Mark which quests are
    meant to be brave, such as fetching from predator country, and check they can't be bypassed
    cheaply.
34. **MEDIUM [owner]: the Well at the World's End as the ultimate boon (hero's journey,
    pp. 578-588; P46 p. 587).** Morris's novel follows the departure, initiation and return
    structure. A once-per-line achievement, such as reaching or drinking from the Well, would give
    the family saga the recognised endpoint that Bartle says virtual worlds lack. Lore claims must
    follow the CANON or GAME EXPANSION labelling rules.

---

## 4. Warnings: risks the game runs

- **Shock and "that's-all-folks" loss (pp. 554-555, 563-565).** Every heir restarts all skills, so
  each death costs a whole life's advancement. If deaths feel arbitrary (an unseen bear, starvation
  without warning, slow illness), players quit. Keep actual risk below perceived risk (fn 86,
  p. 574).
- **Inheritance treated as a respawn (p. 561).** If heirs are interchangeable, PD loses its meaning
  and the fiction is "stretched so thin as to be transparent".
- **Twinking through the family chest and property (pp. 569-570).** This lowers the stake and makes
  early content trivial for heirs.
- **Wealth sandboxing across generations (p. 566).** Skills reset but money doesn't, so a dynasty
  can end up owning the village.
- **Selective depth (pp. 482-483).** Combat and magic are richer than farming and husbandry, which
  tells players the game is about fighting. That contradicts the life-sim intent.
- **Crafting tedium (pp. 591-592).** Deep production chains are near-zero excitement in themselves.
  The fun must come from NPC demand, trading and visible use of goods.
- **Flooding (p. 593).** If one product is the best xp or coin per minute, the player floods the
  merchants. Stock-based prices soften this but can also make the craft feel pointless.
- **Maintenance tedium on mobile (pp. 510-511).** Manual eating and sleeping every in-game day
  becomes a chore over many generations.
- **Combat complexity dominating (p. 535).** Adding wound levels, stances and crits risks the game
  becoming "about" combat.
- **Respawn fictions (pp. 462-465, 571).** Timer spawns of wildlife or skeletons visibly break the
  rule that nothing comes from nowhere. A thin explanation is worse than none.
- **Dark nights and caves on Android (p. 459).** Low-light visibility varies by screen.
- **Children's open questions (p. 508).** Orphans, education, underage heirs and custody produce
  edge-case bugs in a world that already ages and kills NPCs.
- **No endpoint (pp. 586-587, 601).** An endless chain of generations with no recognised
  achievement turns into a treadmill.
- **Skill decay (p. 485).** Players dislike atrophy; don't add it as a cap.
- **Justice that sees only tangible acts (p. 556).** Fines for self-defence feel unjust.

---

## 5. Not applicable (multiplayer or online-only)

- PvP, GvG/RvR, arenas, PvP flags, consent and permission levels, squelching, stalking (pp. 539-549,
  542-543). Single-player equivalent: the player and NPCs act on each other under the same rules,
  which the brief already intends.
- PD moderation by administrators, by players or by opt-in/opt-out switches (pp. 556-558);
  player-killer elder games (p. 565).
- Player groups and guilds: fellowships, clans, alliances, softwired groups, guild templates
  (pp. 519-528). Only the hardwired, NPC-staffed group ideas apply.
- Character-creation hacking (server-side rolls, fn 29), sharing kits online (p. 498),
  questionnaires as psychometrics (pp. 498-500), essays (p. 501), character homepage hyperlinks
  (pp. 492-493).
- Power hour, improvement by purchase, real-money sales, proactive physics against eBay sales
  (pp. 460-462, 486-487, 490).
- Live team, newbie churn, listening to high-level players, the trickle-down content treadmill
  (pp. 567-571). The design lesson about the treadmill is kept under warnings.
- Offline play through queued orders or email (pp. 595-599). Partly covered: shop attendants
  already act as hired NPC vendors, and sleep time-skip is the single-player analogue.
- Elder game for wizards: snooping, politics among players, player-built areas, intellectual
  property of player content (pp. 599-616).
- Real-world seasonal events (p. 458). The game keeps its own calendar, so real-date holidays would
  clash.
- Gender mechanics (pp. 502-506). Only the caution applies: keep ability differences cosmetic. Births
  are already modelled.

---

## 6. For the future player-hosted multiplayer (3-4 players)

Context: the owner has confirmed player-hosted co-op for about 3-4 players with no always-on server
(GAME_DESIGN Confirmed 10, DECISIONS 2026-10-17). It is not built yet. These items reopen the parts
of section 5 that apply to a small group of friends sharing one world. All items are design inputs
for that future work and need the owner's approval.

### Consent, harm between players, and PD
- **HIGH: keep PvP and PD as separate decisions (p. 552).** "PD is not the same as PvP." Combining
  them is player-killing.
  - Recommended default: co-op players cannot harm each other unless both opt in, for example a
    duel or a "fight" toggle (arenas and flags, p. 545).
  - Do this because death caused by another player makes people angry, while death the world causes
    reads as one's own fault (P34, p. 554).
  - With 3-4 friends, a small unmoderated world can work (p. 556) if fleeing is possible. The safer
    default is still no player-to-player PD without consent.
- **HIGH: consent in principle versus consent in fact (p. 548).** Joining a friend's world counts
  only as consent in principle. Make the rules visible when the host creates the world (PvP off or
  duels only; what happens to a dead player's goods), so nobody is surprised.
- **HIGH: one player's PD while the others play on.** Each player needs their own family line and
  heir. Decide:
  - where the heir appears;
  - whether the heir keeps a share of co-owned property;
  - that other players cannot loot the fallen player's carried goods before the heir can reach
    them, or that they can, but deliberately (looting as weak PvP, p. 541).
- **MEDIUM: Marian's tailor in co-op (pp. 548-549).** If one friend plays a crafter or merchant and
  another a fighter, the crafter must never be forced to fight. Bandit and wildlife threats should
  scale to who is present, or be shareable through escort play.

### Ownership, theft and justice between players
- **HIGH: theft between players and laundering (p. 456; fn 50, p. 526).**
  - Stolen marks must work across players: goods one player steals from another and sells to a
    merchant must not lose their marks silently.
  - Decide whether guards police thefts between players the same way they police thefts from NPCs
    (the same-rules intent says yes).
  - World justice tracks only tangible acts (P53, p. 556), so self-defence must not be flagged.
- **MEDIUM: shared property and treasury powers (p. 522).** A co-op household or business that owns
  houses, shops or a chest needs explicit rights: who may withdraw, sell or lease, and within what
  budget ("treasury powers"). Players leaving a group must not be able to take everything.
- **MEDIUM: offices held by players (p. 527).** If a player can become reeve or guard captain over
  friends, powers such as fines and jail need limits. "Just how long can you make a character's jail
  sentence be before it amounts to permanent death?"

### Advancement and play together
- **HIGH: level disparity (pp. 473-474).** Characters at very different levels cannot share content
  well, and PD heirs reset to zero. A friend's fresh heir beside a veteran will find threats either
  deadly or trivial.
  - Options: mentoring xp, where a low-level player learns faster near a skilled friend (a
    co-operative take on "skill support", p. 488).
  - Or threats that scale to the weakest player present.
- **MEDIUM: twinking between friends (pp. 569-570).** A veteran can hand an heir top gear, which
  removes the stake for the receiver. Either accept it as "family support" or require skill to
  wield gear well.
- **MEDIUM: Star Wars Galaxies crafter xp (P18, p. 489) works best with other players.** Award
  crafting xp when a co-op partner, not just an NPC, uses your goods. This builds interdependence:
  "it helps community, and it integrates crafters more fully into the economy".
- **LOW: unique or rare outputs (fn 26, p. 493; p. 593).** With several crafters, a wide range of
  products prevents everyone making the same goods (P50).

### Groups
- **MEDIUM: small groups need only light formal support (p. 520).** "In small-population virtual
  worlds, everyone knows everyone else and there is no need for formal grouping commands." Provide
  only what code must reference: a shared chest, shared ownership, a party marker on the map.
  Temporary groups must be quick to form and disband (p. 522).
- **LOW: automated succession (p. 528).** If a co-op guild or business has a leader who stops
  playing, rights pass on automatically.

### Time, presence and hosting
- **HIGH: one shared clock (pp. 459-460).** "One character can't go back to yesterday because for
  the other characters it's today." Sleep time-skip and fast-forwarded nights (p. 458) need every
  present player to sleep or agree. No player may pause or skip alone.
- **HIGH: absent players in a host-only world (pp. 595-599; fn 100, p. 596).**
  - When a guest leaves, their character must not stand defenceless in the world. Use offline
    abstraction: they go home, or the character is hidden "in the abstract".
  - Their needs and ageing need a rule: frozen, or simulated as an off-screen routine (P2, p. 511).
  - Decide what happens to a guest's property and household while the host plays alone. The
    world only runs when the host is online, so time passes for a guest's family without them.
  - Hired NPC attendants (p. 597) already suit absent players' shops.
- **MEDIUM: respawn camping and resource contention (pp. 463-465, p. 541).** With 3-4 players
  competing for the same ore nodes, herds and quest givers:
  - regrowth paced to consumption (item 31) must account for the number of players present;
  - quests from villagers' needs should either be shared or claimed visibly, to avoid "kill
    stealing" frustration.
- **LOW: collision and blocking (p. 542).** Players can block doors and bridges for each other.
  Allow passing through friends at reduced speed, or no player-to-player collision.

### Not needed even in co-op
- Squelch, gagging, anti-stalking, player-moderated reputation, karma or grudge markets,
  administrator appeals, live-team community management, guild alliances and überguilds,
  power hour, and player-created content intellectual property (pp. 542-543, 556-558, 527-528,
  606-616). These serve large anonymous populations, not 3-4 friends on a private host.
