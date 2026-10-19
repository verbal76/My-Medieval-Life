# Notes F1: Bartle, *Designing Virtual Worlds*, pp. 617-821 (end of Ch. 5, then Ch. 6 "It's Not a Game, It's a...")

Source file: `part_F1.txt` (8,441 lines, read in full). Note: the file actually runs from book p. 617
(the last ten pages of Chapter 5) to p. 821 (mid-way through "Education"), not pp. 627-831 as briefed.
Chapter 6 itself starts at p. 627. Despite the brief's description, Chapter 6 has **no dedicated
sections on law, crime, guards or governance**. It is a survey of how other academic disciplines view
virtual worlds. Law and crime come up inside "Gender Studies" (the Mr. Bungle case, punishment, how
designers should respond to forbidden commands), "Politics" (offices, law enforcement, punishments)
and "Economics". Those passages are the most useful for an NPC society and are covered in detail below.

Game context used to make items concrete (read only, nothing changed): `World.witness` /
`guard_confront` / `theft_fine_for` (game/scripts/core/world.gd ~1607-1670), `main.gd::_crime` and
`_hit` (~2633-2705), `Dialogue.attacked` (memory keyed `"attacked by " + player.name`), the manor's tax
rate switching between `tax_rate_normal` and `tax_rate_low_treasury` (npc_brain.gd ~1671), and the
relief system.

---

## 1. Section-by-section summary

| Pages | Section | Summary |
|---|---|---|
| 617-619 | Ch.5 "The Whole Picture" | Design is holistic: fixing one subsystem pushes the problem elsewhere (busy crafting towns empty the wilderness). Some goals contradict directly (permadeath vs resurrection) and some indirectly (fixed sale prices draw in too many producers, which raises raw-material costs). The economy will not work first time, so damage-limitation code is needed. Footnote: checks and balances are themselves a source of exploits; play devil's advocate. |
| 619-620 | Under- and Over-Design | Under-design: a beautiful world with nothing to do, or one activity repeated. Over-design: so much required detail that it swamps what players want to do (the arrow-spec example). Both come from misplaced focus; too much detail in one place makes everything else look shallow. |
| 620-623 | Participatory Design | Brainstorming works inside the team, with one lead holding the veto. Bringing players in has real benefits (investment, ideas) but also cynical uses, and unresolved credit and IP problems. |
| 623-626 | Testing a Design | Spreadsheets and quick code get the numbers right but say nothing about fun. Tabletop simulation helps. Dummy logs and **mock diaries** (pretend diary entries over many sessions, for each player type and each career stage) show sessions that are dull or repetitive. Think through every addition, and make sure nothing important depends on an untested idea. |
| 627-631 | Ch.6 opening, "Points of View" | Virtual worlds have been called simulations, services, media and games, but Bartle says they are **places**. Is there a discipline of studying them from inside? |
| 631-634 | Making Sense of Virtual Worlds | Hard vs soft science. Three attitudes: virtual worlds as a topic in their own right, as a subfield of another discipline, or as a tool. |
| 634-642 | Geography | Space vs place. Four kinds of virtual space: core public space, private spaces linked to it, disconnected private spaces, and multi-scale spaces. Kevin Lynch's five features of a mental map: nodes, paths, edges, districts, landmarks. Designers must **provide landmarks deliberately**. Unrestricted teleport is the greatest threat to the world's geography. Keep geography stable. |
| 642-647 | Architecture | Cicognani's five properties of a space: possibility of action, livability, community, time organisation, spatial organisation. Anders: popping players out of immersion is a betrayal. Watch for "black hole" rooms and unlinked areas. Away from the core you meet no one and the world feels empty. Restrict teleporting; link private spaces into the general space; have multiple local hangouts. Space limits generate activity. |
| 647-658 | Anthropology | Ethnography vs ethnology. Studies of single worlds (Rosenberg, Masterson, Cherny's five kinds of emote). Sociolinguistics can tell graphical worlds which few emotes to build. Reid: culture forms from players' needs under the world's conditions; nowadays culture is inherited from earlier players more than formed fresh. |
| 658-667 | Sociology | Curtis's LambdaMOO observations: anonymity, wizards as police, people drawn to busy spots, community larger than the online count, social consensus. Carazo-Chandler's migration study: push factors (housing shortage, no local services, harassment, poor reputation), barriers, pull factors. Players move around the world as their characters grow. |
| 667-699 | Psychology | Addiction: playing is habit-forming, not inherently addictive. Do not engineer addiction (Hopson's reinforcement work). Identity: Turkle, identity drift, reworking vs reenacting. Cherny on spoofing: being manipulated without expecting it is a betrayal of trust. **Unfairness**: something awful happens that you understood the rules did not permit. Raybourn: social worlds still form pecking orders, and "communication is identity", but actions communicate too. PK motives (Ito, Vaughan). Race and sexuality as identity. |
| 699-740 | Gender Studies | Cross-gender play: surveys and arguments for and against. Virtual sex. The Mr. Bungle "rape in cyberspace" case and how the community reacted. Key designer points: players assume **anything the world lets them do is allowed**; a punishment means nothing unless the player has a stake in the character; punishments must fit the crime. Six possible designer responses to a forbidden command, from "do nothing" to instant permanent death. Bartle's choice: "tangible meaning", with only the perpetrator facing the consequences. |
| 740-747 | Lexicography | A moderate amount of jargon binds a community: newcomers who learn it feel included. Words preserve a world's history, and a dictionary can be its gatekeeper. |
| 747-765 | Economics | Simpson on Ultima Online: why economies exist (to ration power, support specialisation, encourage interaction, provide goals, allow economic role-play). Why UO's closed economy failed: over-production from grinding skills by use, NPC vendors running out of money, arbitrage, hoarding, drains added too late, money duplication. Recommendations: enforceable contracts, auctions, vendors who buy, deeper production paths, buying skills instead of skill-by-use. A small closed economy can work (Shattered World), but every item must be audited and implied NPCs simulated. Star Wars Galaxies: fixed wealth pool, constant taxation, decay. Taxes are accepted only if present from the start. Beezer: real-economy behaviour needs permanent death, real necessities and transport costs. Castronova: GNP of Norrath; ways virtual economies differ from real ones (growth lowers challenge; players want work). Real-money trade. |
| 765-776 | Politics | Mihaly: static vs dynamic systems. Formal politics gives players a non-violent route to achievement, creates opinion leaders, gives veterans a reason to help newcomers, and makes emergent story. Offices **must have meaning** (public services). Use a hierarchy of offices. Too little power makes a sinecure; too much makes life unbearable for the governed. Which laws can the world itself enforce, and which need police and courts? What punishments work? Examples: Dark Ages "clout", SWG politics as a profession, Shadowbane guild cities. Governance of the worlds themselves (feudal by default; LambdaMOO's failed democracy). Newitz's Marxist critique. |
| 776-780 | Autobiography | Dibbell and Sinha. Sinha's worry: "what we imagine, we make", i.e. tolerating virtual cruelty desensitises. Bartle: designers are primarily responsible for making sure positive changes outweigh negative ones. |
| 780-794 | Theology | Religion-themed worlds. Ethics: should real-world morals apply? (Haeberle yes, Cranford pessimistic). Is there religion within virtual worlds (Clodius / Geertz)? Wertheim: a medieval double world. Kelly: an autonomous world of NPCs that evolves, so the designer must "let go to win". Designing gods (Hastings' questions). Schwanz's morality axes (health, wealth, power, information; giver vs taker). |
| 795-813 | Virtual Worlds as Subfields: Literary theory, RPG theory, Drama theory, CMC | Virtual worlds lack conventional story; Juul says the strength of games is that they don't tell stories. GNS modes: Simulation mode puts internal logic and consistency first. Actor vs author stance. Murray: immersion, agency, transformation. Computers can't keep planned plots on track when players act unexpectedly. CMC concerns (missing social cues, anonymity). |
| 813-816 | Post-Modernism | Simulacrum and hyperreal. Little use to a designer. |
| 817-821 | Virtual Worlds as Tools: Computer Science, AI, Education (start) | AI matters because of NPCs: intelligent NPCs make quests contextual, make reputation intangible but more effective, make the economy behave as it should, and stop clans dominating politics. **Don't make the world itself adapt** to the player (scaled monsters, adaptive loot): a constant challenge is patronising. |

---

## 2. Principles that apply (with quote and page)

**Holism and testing**
- P1. Fix systems together, not one at a time. "You can’t solve the problem by partitioning it." (p. 618)
- P2. Build economic damage limitation in from the start. "Any new design for the economy in particular is almost certain not to work straight away, so damage-limitation code will have to be in place" (p. 619)
- P3. Play devil's advocate against every rule. "How would I break the system if this or that rule were in place?" (p. 619, fn 128)
- P4. Avoid over-design. "What players want to do is lost in the noise of what they have to do to facilitate doing it." (p. 619)
- P5. Keep depth even. "Too much detail in one place gives an impression of shallowness elsewhere" (p. 620)
- P6. Test with mock diaries across career stages. "If the entries often lack excitement or fun, or they start to look the same, you may have discovered a potential problem." (p. 625)

**Place, navigation, liveliness**
- P7. Treat the world as a place. "Virtual worlds are places. Remember that, and many design issues cease to be issues at all." (p. 629)
- P8. Provide landmarks deliberately. "Designers should not simply assume people will find things to use as landmarks: They should follow the lead of urban planners and actually provide them." (p. 641)
- P9. Limit teleporting. "Unrestricted teleportation is perhaps the greatest threat to the geographical integrity of a virtual world" (p. 642)
- P10. Keep geography stable. "the virtual world’s geography should be relatively stable." (p. 642)
- P11. Never break immersion through broken space. "if the designer pops them out of their immersion, it amounts to nothing less than a betrayal." (p. 644)
- P12. Spread life outward from the centre. "the further away from it you are the less likely you are to meet anyone by chance." (p. 645)
- P13. Have several hangouts. "Have multiple entrance points, for multiple local hangouts." (p. 645)
- P14. Crowds attract. "anyone passing through will tarry awhile on the grounds that something interesting may be happening." (p. 661)
- P15. Make time visible through space. "Only through alterations to space can changes in time be detected" (p. 643)

**Society, reputation, crime and punishment**
- P16. Reputation and services drive moving away. Push factors include "Lack of local services" and "Their poor reputation" (p. 665)
- P17. Deeds communicate. "If I go off and fetch you something you need, I’m communicating an aspect of my personality even if I don’t say a word." (p. 686)
- P18. Societies form pecking orders. "Community building is no more democratic than in real life." (p. 685)
- P19. Unfairness means expectations are broken. "Unfairness occurs when it’s your understanding that nothing awful is, in the current circumstances, permitted to happen by the virtual world’s rules" (p. 677)
- P20. What the world allows reads as permission. "the default is that if the world lets you do it, it’s allowed." (p. 729)
- P21. Doing nothing is itself a response, and a scolding is toothless. "Issue a response telling the player off. This has the advantage of showing that you don’t approve of this kind of behavior, but the disadvantage of being toothless." (p. 736)
- P22. Give consequences "tangible force" or "tangible meaning": "Give the command tangible meaning." (p. 736)
- P23. Punishment must fit the crime. "Their punishment is beyond their crime." (p. 737); "what purpose was the punishment to serve—was it a warning to others, a step toward rehabilitation or merely an act of revenge?" (p. 728)
- P24. Punishment needs a stake. "punishing a character is no punishment at all unless the player has a stake in that character." (p. 734)
- P25. Without consequences, no restraint. "If everything is possible, if risk and consequence are not factors, why would anybody treat other people in a dignified or sensitive manner?" (p. 784)
- P26. Smart NPCs make reputation work. "Quest generation becomes contextual; reputation becomes intangible but works better; the economy behaves like it should" (p. 820)

**Governance (manor, reeve)**
- P27. Offices must mean something. "The critical thing about creating a system of offices is that they must have meaning." (p. 768); it "is best done through the provision of public services" (p. 768)
- P28. Balance static and dynamic power. "If governments changed daily, they wouldn’t get a lot done." (p. 766)
- P29. Calibrate an office's powers. "With too little, the offices are little more than sinecures; with too much, life for governed players can become unbearable" (p. 769)
- P30. Decide which laws the world enforces and which need agents. "Should the government only make laws that the virtual world itself can enforce" (p. 769); "Imprisonment in a virtual world isn’t quite as big a deal as in the real one." (p. 769)
- P31. Hierarchies are ladders: a hierarchy "is another ladder to climb." (p. 769)
- P32. Social rules must live in code. "Attempting to separate social from technical issues does not work when the social is rooted in the technical." (p. 773)

**Economy**
- P33. Over-supplied buyers must refuse, and that must not look like a bug: "the player should expect that the vendor refuses to buy any more; unfortunately, the player instead regards it as a bug" (p. 751)
- P34. Players sell but don't buy. "players wanted to sell things to NPC vendors but didn’t want to buy anything from them." (p. 751)
- P35. Hoarding starves a closed economy. "whenever people hold on to objects, rather than using them, there is a resource shortage." (p. 752)
- P36. Sinks and taxes must be there from day one. "Had these been there at the start, people would have accepted them" (p. 752); "as long as a taxation system is imposed from the beginning, the players will accept it" (p. 756)
- P37. Keep tax rates steady. The SWG approach "avoids the tax-level changes that players so hate." (p. 755)
- P38. Closed economies need auditing. "Pretty well everything must be audited so as to ensure that the overall money supply remains under control." (p. 754)
- P39. Simulate the implied population. "Virtual worlds where not all characters are PCs must simulate the behavior of their implied NPCs." (p. 754)
- P40. Deep production chains give newcomers a role. "Deepen production paths." (p. 753); also "Create enforceable contracts." (p. 752)
- P41. Recessions are realistic but not fun. "Periodic recessions may be required to cool down overheated economies, but they’re no fun for the players caught up in them." (p. 756)
- P42. Real economic behaviour needs real necessities, real death and transport costs. "Virtual worlds where the necessities aren’t necessary will also not work like the real world." (p. 759); "The further away you are from where something is produced, the more it costs to get it." (p. 759); "Death must be permanent, and also sufficiently unpleasant that players will take it seriously" (p. 759)
- P43. Growth erodes challenge. "increases in per capita wealth make it easier to accomplish tasks and therefore lower the challenge that they present." (pp. 763-764)
- P44. Players want work. "People in virtual worlds would rather not not work—they get bored with nothing to do." (p. 763)
- P45. Innovation must be anticipated. "in a virtual world, I can only do this if the designers have anticipated me." (p. 757)

**Design ethics, AI, story**
- P46. Don't engineer addiction. "you shouldn’t go out of your way to make the activities in your virtual world addictive; that way lies lawsuits." (p. 672)
- P47. Don't make the world adapt to the player. "Don’t try to make your virtual world itself be intelligent." (p. 821); "A constant challenge is constantly beatable and constantly patronizing." (p. 821)
- P48. Let the autonomous world evolve. "All entities—PCs and NPCs— would alter their world, physically and socially, until it evolved into something quite different from how it started." (p. 789)
- P49. Consistency is what simulation players value. Simulation mode: "Internal logic and consistency of experience are regarded as paramount." (p. 801)
- P50. Planned plots break. "computers cannot adapt to unexpected actions to keep a series of planned events on track" (p. 801)
- P51. Vocabulary binds people to a world and preserves its history. "Dictionaries can be the gatekeepers of history; would your virtual world benefit from one?" (p. 747)
- P52. Religion as a design question. "How much of the religion should be programmed in as laws of nature ... and how much should be left to enforcement by players or NPCs?" (pp. 793-794)

---

## 3. Actionable items for My Medieval Life

Per CLAUDE.md section 11, any new gameplay mechanic is an owner decision; items marked **(owner)** are
proposals that need approval before they are built. "Check" items are verification or tests only.

### HIGH

1. **[Law & crime] Make assault and killing a recorded, punished crime that weighs more than theft.**
   P20, P21, P23 (pp. 728-737). From reading the code: `main.gd::_crime` (called on hitting a villager
   or killing livestock) adds memories, sets guards and the victim hostile and writes a log note. It
   does **not** append to `player.crimes`, and it levies no fine. Theft goes through `World.witness`
   and `guard_confront` with `theft_fine_for` (record plus fine plus goods returned). So a pocket
   picked in front of a guard costs coins and goes on the record, while a beating may cost only a
   fight, and killing a villager (`world.kill`) leaves only a note. Bartle says a missing or toothless
   response tells the player the act is acceptable. Proposal **(owner)**: assault and killing go
   through the same witness and record path, carry a graded penalty (assault fine < theft of a high
   value < killing), and have a defined outcome for killing (outlawry, a wergild payment to the
   victim's household from the player's coins, or a fine to the manor). Verify the current behaviour
   with a test before changing anything.
2. **[Law & crime / Heirs] Decide whether a crime's consequences pass to the heir.** P24 (p. 734). A
   punishment only bites if the player has a stake. With permadeath and heirs, a criminal can die and
   carry on as a clean heir. NPC memories are keyed by the player's given name (`"attacked by " +
   player.name`, `"saw <name> <family> take ..."`), so a new heir with a new name is effectively
   forgiven. The theft and attack keys are also inconsistent (the theft key includes the family name;
   the attack key doesn't). **(owner)** Options: (a) the record dies with the person (current
   behaviour, by accident); (b) the family name carries a reduced stain (medieval kin liability);
   (c) only unpaid fines or debts pass to the estate. Recommendation: (c) plus a fading family stain
   for killings. At minimum, make the memory keys consistent.
3. **[Economy / Skills] Test skill-by-use over-production.** P33, P35 and Simpson (p. 751). UO
   flooded because players crafted only to raise skills. Here skills rise with use (`_xp`). Check
   with a sim run: a player who crafts the same item 200 times for XP. Does the item's price collapse
   at every merchant (limited funds, stock-based pricing), and does the game say so ("The smith has
   no use for more nails") rather than silently refusing? Add a clear refusal message wherever a
   buyer is at its stock cap or out of money (P33: it must not look like a bug).
4. **[Economy] Run an arbitrage and round-trip exploit test.** P3, P34 (pp. 619, 751). With stock-based
   prices, bulk pricing unit by unit, local-availability pricing and the caravan, script a loop of
   buy at A, sell at B (and buy and immediately sell back at the same seller, and bulk-buy then
   piecemeal-sell) and assert that no loop gains coins without a real cost (time, carrying, distance).
   UO groups found exactly these loops.
5. **[Economy] Add a coin and goods conservation audit test.** P38 and counterfeiting (pp. 752, 754).
   The game's own rule ("Coins and goods only move") is a closed economy, which Bartle says needs
   auditing everywhere. A test that totals all coins (players, households, merchants, treasury,
   caravan, loot) and all goods across N simulated days, accounting explicitly for every legitimate
   faucet and drain (caravan import and export, births and deaths, food eaten, wear), would catch the
   duplication bugs that broke UO. Include save and load and chest moves in the test.
6. **[Governance / Manor treasury] Make tax changes predictable and announced.** P36, P37 (pp. 752-756).
   The manor switches between `tax_rate_normal` and `tax_rate_low_treasury` depending on the treasury.
   Bartle: players hate tax-level changes, and drains are accepted only if they were there from the
   start. Check: (a) taxes apply from day one of a new game, before the player has earned much; (b) a
   rate change is announced in advance (a reeve's proclamation or a log entry with the reason, e.g.
   "the granary is low"); (c) the wiki explains the rule. Consider hysteresis so the rate doesn't flip
   every day around the threshold (P28).
7. **[Economy / Progression] Check late-game wealth.** P43, P44 (pp. 763-764). Write mock diaries
   (P6) for day 1, season 1, year 3 and the third heir. Check that wealth from shops, attendants and
   leases doesn't eventually make every task trivial and leave nothing to do. Look for ongoing costs
   that scale with holdings (upkeep, repairs, attendants' wages, the manor's tax on property) so a
   rich player still has real decisions.
8. **[Wildlife / Bandits] Don't scale threats to the player.** P47 (p. 821). Confirm that bandit
   strength, predator stats and loot never read the player's skill levels or wealth. Threats should
   vary by place (deeper overworld, caves) and season, not by who is looking. The only uses of player
   level found were lockpicking odds and quest eligibility, which is fine; keep it that way and add a
   test that fauna and bandit spawns don't depend on player skills.
9. **[Bandits / Safety zones] Set clear expectations of safety and keep to them.** P19 (p. 677). The
   unfairness example (an attack while shopping at a "mundane downtown store") maps to bandits
   robbing the player inside the village or at the market. Decide which places are guarded (the
   village core inside guard reach) and make the rule visible (guards patrol there; the wiki says
   so). If bandits can strike there, guards must visibly respond. The wilderness can be dangerous
   because the player expects it.

### MEDIUM

10. **[Reputation / NPC society] Build a village standing that grows from deeds, good and bad.**
    P17, P26, P16 (pp. 665, 686, 820). Today NPC memory records being met, attacked or robbed, and
    "met" makes later meetings friendlier, but help given (quests done, relief carried, goods sold
    fairly) isn't weighed against crimes, and memories don't spread. Proposal **(owner)**: record
    helpful deeds symmetrically ("<player> brought us firewood when we had none"), let household
    members and close neighbours share the most serious memories (gossip with a radius and decay),
    and let standing change prices (P34 trading skill), hiring, leasing, marriage prospects and the
    guards' leniency. Bartle's AI point: reputation held by NPCs works better than a visible score.
11. **[Governance] Give the reeve and manor visible public services and a ladder of offices.**
    P27, P29, P31 (pp. 768-769). The manor already provides real public services (granary, relief,
    repairs, guards' wages), which is exactly what gives an office meaning. Make that visible: the
    reeve announces relief, repairs and tax use. Proposal **(owner)**: a ladder the player can climb
    (hayward → constable/guard → reeve), each with bounded powers (e.g. the reeve allocates relief
    and repairs and sets fines within limits, but can't set the tax rate arbitrarily) so the office
    is neither a sinecure nor tyrannical over NPCs. Historically, manorial reeves were often chosen
    by the villagers, which gives the dynamic element of P28 inside a static lordship (record as
    GAME EXPANSION unless Morris supports it).
12. **[Law & crime] Set the scope of law to what NPC agents can enforce.** P30, P32 (pp. 769, 773).
    Because the player lives under the same rules as NPCs, laws should be enforced by agents
    (witnesses, guards, the reeve) rather than by disabling actions. Keep that principle, and list
    the enforceable laws (theft, lock-breaking, assault, killing, poaching manor game, cutting manor
    trees, fencing) in the wiki. Don't add laws with no enforcing agent. For punishments, prefer
    tangible ones (fines to the treasury, restitution to victims, a ban from the market or tavern,
    a day in the stocks with lost time) over imprisonment, which Bartle notes means little in a
    game.
13. **[Law & crime] Make sure crimes are seen to apply to NPCs too.** P20, P25 (pp. 729, 784). The
    owner's rule is "same rules as NPCs", and P18 says societies form pecking orders. Bandits already
    rob. Check that villagers in hardship can, rarely, commit petty crimes (gleaning, poaching,
    pilfering), that the same witness and guard path handles them, and that the player sees it. That
    makes the law part of the society rather than a trap aimed at the player.
14. **[Economy] Make hoarding self-correcting.** P35 (p. 752). "Nothing comes from nowhere" makes
    the economy closed, so a player who stockpiles iron or grain can starve the village. Check that
    the caravan import is a deliberate faucet that responds to prices or shortage (UO only fixed
    hoarding with a faucet), and that spoilage or wear acts as a drain on perishable stockpiles
    (food rots, tools wear).
15. **[Economy] Make buying from NPCs attractive.** P34, P40 (pp. 751-753). Players tend to sell and
    not buy. Make sure merchants stock things the player actually needs to buy (intermediates such
    as bars, planks and cloth that save real time) and that deep production chains have
    apprentice-level intermediate jobs (selling ore or planks to the smith or carpenter) a new heir
    can do (P40).
16. **[Overworld / Navigation] Add landmarks and districts deliberately.** P8, P10 (pp. 639-642). In
    the endless procedural overworld, the generator should place large, far-visible, structured
    landmarks (a hill fort, a standing stone, a ruined tower, a named crossroads) at deterministic
    intervals along roads, plus recognisable districts by biome. Name them on the map. Lynch's five
    elements make a useful generator checklist: roads = paths, rivers/cliffs = edges, biomes =
    districts.
17. **[Navigation / Travel] Keep fast travel limited.** P9 and Beezer (pp. 642, 759). Distance and
    hauling costs are part of the economy (local-availability pricing; carts planned). If fast
    travel is ever added, it should cost time or money and carry little or no cargo; carts should
    be the way bulk goods move.
18. **[Cliff steps / Interiors] Test for "black hole" spaces.** P11 (p. 644). For the planned cliff
    steps and stairs, and for building interiors, add a generator test that every walkable area the
    player can enter has a walkable exit (no plateau reached by a one-way drop, no house with a
    blocked door).
19. **[Village life] Have several hangouts and make busy spots draw people.** P12, P13, P14 (pp. 645,
    661). NPC schedules should create several gathering points (tavern, market, well, church or
    chapel, the manor yard) at different times of day, and small groups should attract passers-by.
    Outlying areas need occasional traffic too (woodcutters, a hunter, the caravan route) so the
    edges don't feel empty.
20. **[Testing process] Write mock diaries.** P6 (p. 625). Keep a short set of mock diaries in docs
    (first hour, first week, a merchant career, a criminal career, the third heir) and re-read them
    when a system changes, to catch sessions that are dull or repetitive. The criminal-career diary
    would have exposed item 1.

### LOW

21. **[Seasons / Time] Show time through changes in space.** P15 (p. 643): visible crop growth,
    seasonal tiles, buildings ageing or being repaired, graves in the churchyard after deaths. Most of
    this exists or is planned; check that each passing season shows at least one visible change in
    the village.
22. **[Wiki / Lore] Use a world vocabulary as glue.** P51 (pp. 743-747). The in-game wiki can carry a
    small glossary of Morris-derived terms and manor terms (reeve, hayward, toft, heriot) and a
    village chronicle of notable events (births, deaths, crimes, famines) built from the log. This
    would keep the family line's history (an in-world "gatekeeper of history").
23. **[Religion] Answer Hastings' questions for the setting.** P52 (pp. 793-794). If chapels or
    saints appear (Morris has them), decide: are religious acts only flavour, or does keeping holy
    days and paying tithes have rule effects that NPCs observe too? Label each choice CANON or GAME
    EXPANSION per CLAUDE.md.
24. **[Bandits] Give bandits motives.** Vaughan/Ito PK motives (pp. 687-688) map onto bandits: some
    are desperate (poverty, an outcast villager), some opportunistic. Tying bandit origin to the
    village's economy (failed households become poachers) supports the living world (owner).
25. **[Design ethics] No engineered compulsion loops.** P46 (pp. 672-673): no variable-ratio reward
    tricks or login streaks. Rewards should come from the simulation.

---

## 4. Warnings the game risks

- **Inverted proportionality of crime.** Theft is fined and recorded; assault and killing apparently
  are not (item 1). By P20, players read this as the world allowing violence. With guards fighting
  back, a player who wins the fight may face no further consequence. This undermines "same rules as
  NPCs".
- **The heir as a laundering mechanism.** Permadeath plus heirs plus name-keyed memories means a
  crime spree can be wiped by dying (item 2, P24).
- **Tax flip-flop.** A treasury-driven tax rate that changes without warning is the change Bartle
  says players hate most (P37). In a single-player game it will feel like the manor is punishing
  the player's success.
- **The closed economy will fail in ways that haven't been anticipated (P2).** UO's failures
  (skill-grind over-production, vendors out of money, arbitrage, hoarding, duplication) all have
  analogues here: limited merchant funds, stock pricing, bulk deals, chests, saves. Without
  damage-limitation hooks (caravan as a tunable faucet, decay as a drain, logs and stats) a bad
  seed can make the village starve or stall.
- **Realistic recessions that aren't fun.** Famine and relief are realistic, but P41 warns that a
  long downturn is just unpleasant for the player. Make sure hard times are survivable, telegraphed
  and time-limited.
- **Over-design of production chains.** P4/P5: requiring the player to source cart parts, wheel
  spokes, bars and so on for every simple need can swamp what they want to do. Offer buyable
  intermediates so depth is optional.
- **Late-game triviality.** Accumulated wealth and property remove challenge (P43). The family-line
  structure risks every heir starting rich and bored.
- **An empty endless overworld.** A procedural world without deliberate landmarks and traffic feels
  like a shell (P7, P8, P12, and under-design at p. 619).
- **Adaptive difficulty creep.** Any future "balance" that scales enemies or loot to the player
  would feel patronising (P47).
- **Unfair surprises in safe places.** Robbery or attack inside the guarded village without a
  visible guard response breaks expectations (P19).
- **Scripted Morris storylines.** Planned plot beats will be broken by an autonomous world (P50).
  Prefer lore placed in the world and quests that come from situations over fixed sequences.

---

## 5. Not applicable to the current single-player game

(Several of these items become relevant to the future multiplayer mode; see section 6.)

- Participatory design with players, and credit and IP for player ideas (pp. 620-623). Partly: owner
  playtest feedback is the analogue, but there is no community.
- Academic-discipline framing, ethnography and survey methods (pp. 627-660); geography of the
  Internet (pp. 635-637); multi-shard culture uniformity.
- Player-to-player migration between shards (pp. 664-666), except as a model for NPC migration
  (item 10 / P16).
- Internet-addiction debates, identity tourism, race, sexuality and gender studies, cross-gender
  play statistics, virtual sex, spoofing, gagging and harassment between players, the "rape" command
  debate as such (pp. 667-740). Only the general lessons on punishment, expectation and permission
  carry over (items 1, 2, 9, 12).
- Player killing between players, d00ds and griefers (pp. 687-690). There are no other players.
- Jargon as a barrier or glue between players (pp. 742-746), except the in-game glossary idea.
- Real-money trade, eBay, Castronova's GNP, There.com exchange rates, McDonald's kiosks
  (pp. 760-765).
- Democracy among players, governance of the server, players voting with their feet, virtual
  nations at the UN, Marxist surplus-identity critique (pp. 770-776).
- Autobiographies, technopaganism, e-churches, Western mysticism (pp. 776-792), except the design
  questions for in-world religion.
- Literary, drama and CMC theory, Plaintext Players, replay cameras, post-modernism, computer science
  research uses, educational MUDs (pp. 795-821), except the GNS "simulation mode" and anti-scripting
  points.
- Muling, players logging off, hoarding as server load, newbie grubstakes abused by alts (p. 750):
  there are no alts or servers. Starting money for each heir is the only analogue.

---

## 6. For the future player-hosted multiplayer (3-4 players)

Context: Confirmed 10 in `docs/GAME_DESIGN.md` (DECISIONS 2026-10-17) says the game will have
player-hosted worlds for about 3-4 players with no always-on server. This is not built yet. The
chapter's material on community, griefing and governance applies here, scaled down to a small group of
friends where one player's machine is the authority. Every item is a design input for that milestone,
and each new mechanic needs the owner's approval.

### 6a. Principles that come back into play

- M1. Players treat whatever the world allows as permitted. "the default is that if the world lets you do it, it’s allowed." (p. 729). Between friends, the rules the code enforces are the real rules.
- M2. Manipulating another player's character is a betrayal. Cherny "recommended that for ethical reasons players should not be able to manipulate other players as if they were puppets." (p. 676)
- M3. Unfairness is broken expectation. "Unfairness occurs when it’s your understanding that nothing awful is, in the current circumstances, permitted to happen by the virtual world’s rules" (p. 677)
- M4. The host owns the hardware, and that power overrides everything else. "the one power they couldn’t pass—control of the physical hardware—overrode all the other powers." (p. 773)
- M5. Wizards are treated with "complete respect or with complete disrespect." (p. 661). Whoever holds admin power, here the host, will be judged that way.
- M6. Punishment needs a stake. "punishing a character is no punishment at all unless the player has a stake in that character." (p. 734)
- M7. Warning victims can do harm. Telling a victim about a failed assault "can be highly disturbing" (p. 737). Notify thoughtfully.
- M8. Shared play needs enforceable deals. "If people agree to pay for work, or to perform work for pay, then neither should be able to rip off the other without serious consequences." (p. 752)
- M9. Offices give a non-violent route to status, but too much power ruins life for the governed (pp. 766-769).
- M10. People want to be where the others are. "When more than two people are in the same location, anyone passing through will tarry awhile" (p. 661)
- M11. Doing the same thing at the same time. "in a virtual world, different characters do different things at the same time" (p. 801). This suits socialisers and killers, so a shared world will be used for both.
- M12. Most griefing comes from a tiny minority, "sometimes only one in the whole virtual world" (p. 717). With 3-4 friends, one griefer is a quarter of the world.

### 6b. Actionable items for the multiplayer milestone

HIGH
1. **[MP / Host authority] Decide and document what the host can do.** M4, M5. Since the host's machine
   holds the save, the host is effectively the wizard. List in the design what the host can and cannot
   do through the game: pause, kick, ban, roll back, change world rules. Anything the host can do should
   be visible to the guests (a log of host actions) so authority is open rather than hidden.
2. **[MP / Same rules] Apply the NPC law system unchanged to every player.** M1, M3, P20-P23. Theft,
   lockpicking, assault and killing between players go through the same witness, guard, fine and record
   path as crimes against villagers (`World.witness`, `guard_confront`), so a friend robbing a friend
   meets the village guards. Fix the assault and killing gaps (section 3, item 1) first, or player
   versus player will be unpunished.
3. **[MP / Consent for PvP] Add a per-world player-versus-player setting.** M3, M12. Offer a host
   setting chosen when the world is created and shown on the join screen: "no harm between players",
   "crimes punished by the village" (default), or "free for all". Players then know what can happen
   before they join, which Bartle's expectation principle requires.
4. **[MP / Shared property] Model ownership precisely.** M8 and the shared-property problem. Houses,
   chests, stalls, livestock and leases need an owner field per player. A household can have several
   players (shared chest access by explicit grant). Taking from another player's chest is theft under
   the existing chest rules. Define what happens to a departed or absent player's property: it stays
   theirs, and it is not looted while they are offline.
5. **[MP / Offline players] Decide what happens to absent characters.** Simpson's question, "What to do
   with characters when players log off" (p. 750). With no always-on server, the world runs only while
   the host plays. When a guest is absent, does their character vanish, sleep at home (and so can be
   robbed?), or keep working as an NPC? Recommendation: sleep safely at home, with property protected
   while the owner is away. Anything else invites griefing of absent friends (M3).

MEDIUM
6. **[MP / Contracts & trade] Make trades between players enforceable.** M8 and Simpson (p. 752).
   Player-to-player exchange should use an atomic trade window, plus optional contracts (hire for
   wages, a delivery order) held in escrow by the reeve or the manor, so neither side can take the goods
   and refuse to pay.
7. **[MP / Economy] Keep the shared closed economy fair.** P35, P38. With 3-4 players in one closed
   economy, one player can hoard or corner a good and starve the others and the village. Re-run the
   conservation, arbitrage and hoarding tests (section 3, items 4, 5 and 14) with several players, and
   add a test that save and join or leave doesn't duplicate coins or items. Duplication through
   network desync is the multiplayer form of UO's money-cloning bug (p. 752).
8. **[MP / Governance] Let players compete for village offices.** M9, P27-P31. Village offices (reeve,
   constable) could be held by a player, chosen by villagers' standing or by vote among players,
   with bounded powers (set fines within limits, allocate relief or repairs) that never include harming
   another player's property. This gives friends a non-violent rivalry (Mihaly's first reason). Keep
   the NPC lord as the static top so the system can't be captured completely (P28).
9. **[MP / Griefing] Rate-limit and visibly limit the worst acts.** M2, M7, M12. No action may take
   control of another player's character, including charm or curse magic in the future. Killing
   another player's livestock or burning or destroying their buildings should be impossible, or slow
   and heavily punished. Notify the victim in plain terms ("Ada took 3 bread from your chest; the
   guard fined her"), without lurid wording.
10. **[MP / Permadeath & heirs] Think through permadeath when another player is the killer.** M6, P24.
    Permadeath inflicted by another player is the bitterest case. Consider whether player-versus-player
    killing within the village is allowed at all under the default setting, and whether the killer's
    heir inherits blood money owed to the victim's family.
11. **[MP / Hangouts] Bring players together through shared places.** M10, P13. Shared reasons to meet
    (the market day, the tavern, a manor feast, seasonal work such as harvest needing many hands) make
    the small group gather, and give crafters joint projects (Bartle's crafting-town example, pp.
    617-618). Bear in mind it can empty the wilderness (P1).

LOW
12. **[MP / Communication] Add a few quick social signals.** CMC and Cherny emotes (pp. 653-655,
    809). On touch and gamepad, players need a small fixed set of quick signals (wave, follow me, help,
    trade?, thanks), chosen for what players will actually need rather than a large emote list.
13. **[MP / Cross-play roles] Support different play styles in one world.** GNS modes (pp. 800-801).
    Friends will mix achiever, explorer, socialiser and troublemaker styles. Systems should let them
    do different things side by side (one trades, one hunts, one builds) without blocking each other.

### 6c. Warnings for the multiplayer mode

- One griefer among 3-4 friends ruins the world for everyone (M12). The world's rules and the host's
  tools are the only defence, because there is no moderation team.
- The host has absolute power. If they roll back or change the world, guests will feel betrayed
  unless that power is open and agreed (M4, M5).
- Absent players' property and characters are the most exposed targets (item 5).
- Real feelings are involved: Bartle stresses that harm to a character is felt by the person behind
  it (pp. 729-730). Between real friends, a theft or a permadeath kill can damage the friendship, so
  defaults should be gentle and opt-in for harsh play.
- Desync and duplication bugs in a closed economy are far worse than in single-player, because one
  player's exploit devalues everyone's work (p. 752).
