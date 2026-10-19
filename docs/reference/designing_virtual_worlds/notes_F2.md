# Notes F2: Bartle, *Designing Virtual Worlds*, book pp. 822-937

Source file: `part_F2.txt`. The file actually runs from book page 822 to 937 (not 832-947 as labelled):
pp. 822-831 are the tail of Ch. 6 ("It's Not a Game, It's a..."), pp. 832-891 are Ch. 7 "Toward a
Critical Aesthetic", pp. 892-937 are Ch. 8 "Coda: Ethical Considerations". The hero's journey itself
is *defined* earlier in the book (Ch. 6); this part only applies it (pp. 860, 876, 889, 891, 908-912).

Game context used (from `game_brief.md` and the repo): single-player life sim / mini RPG in Godot; one
fixed village of ~70 simulated villagers in an endless generated overworld; lore from Morris's *The
Well at the World's End*. Repo facts that matter here: `docs/GAME_DESIGN.md` Confirmed 7 ("Its story
is the world's history, not the player's quest") and Confirmed 8 ("The player is not the chosen
one"); quests come from villagers' real needs plus a few `story: true` quests with a green pennant
(`game/data/quests.json`); permadeath with heirs; open items U21 (content rating, crime, thralldom)
and J-S1 (thralldom depiction), J-M4 (religious risk to magic practitioners). Multiplayer: `GAME_DESIGN.md`
Confirmed 10 (owner, DECISIONS 2026-10-17) is player-hosted multiplayer for about 3-4 players with no
always-on server, not built yet; the brief describes the current single-player builds. Items for
that future mode are in section 6.

---

## 1. Section-by-section summary

### Ch. 6 tail (pp. 822-831)
- **Education (pp. 822-824).** Educational worlds (mostly text MOOs) teach language, programming,
  writing, team skills. All virtual-world traditions share one aim: learning, ultimately about the
  self.
- **Law (pp. 824-827).** Open legal questions: data and IP ownership, employment, jurisdiction,
  liability for addiction/violence/RSI. Korea's 2002 PK age rating as precedent.
- **Community management (pp. 827-830).** Live teams handle confused/stuck players, loot disputes,
  addiction worries; players multi-line, divert risk to throwaway characters, collude, play the
  system, use bots. Designer stays in charge but listens to the live team.
- **Conclusion (pp. 830-831).** Virtual worlds are a legitimate object of study and an art form.

### Ch. 7 Toward a Critical Aesthetic (pp. 832-891)
- **Art vs design (pp. 832-834).** Designers are really artists; the lead designer holds artistic
  responsibility as a film director does.
- **A Theory of Virtual Worlds / Motivation (pp. 834-840).** A critical aesthetic is a system for
  ascribing meaning to works. The Mulligan-Koster-Casey debate: are players objectified as parts of
  the designer's art? Bartle: players are players first, "components ... only occasionally".
  Critical self-consciousness can kill fun, but without rules designers repeat old mistakes.
- **Some Questions (pp. 840-842).** Value of the experience = what players gain (self-understanding),
  not hours played; player development model (Ch. 3) as half a theory; worlds mimic real physics
  because it is the paradigm.
- **Template Theories (pp. 842-844).** Film is the closest art form with a mature aesthetic; games
  have only reviews.
- **Signs and Symbols (pp. 844-847).** Media develop codes (split screen, speech bubbles) that become
  invisible once learned. "Immersion is accepting the signifier as the signified." Symbols make
  external (real-world, political) statements, e.g. classes = conformity, and internal ones, e.g.
  falling light = danger.
- **Dimensions (pp. 847-856).** Dialectics from film and games: life/drama, realism/expressionism,
  genre/auteur, reality/fantasy, entertainment/communication, innovation/derivation, hard
  core/mass market, graphics/gameplay; plus world-specific ones: direction/non-direction,
  responsibility/liability, story/history, individual/community. Top five: genre/auteur,
  entertainment/communication, direction/non-direction, responsibility/liability, hard core/mass
  market. Asheron's Call 2's "cosseted blandness" (infinite arrows, sell loot from backpack) as the
  wrong way to go mass market.
- **Whence the Symbols Come (pp. 856-859).** Designers cannot cut, fade or pause (in an MMO);
  players hold the camera. Designers compose what exists and where it starts. Art-within-art and
  ownership. Designers covenant that tools and toys have value, meaning and make sense.
- **A Chemistry for Virtual Worlds (pp. 859-866).** Everything should have a *potential* purpose.
  Atoms (objects, commands, characters, locations) build molecules. Quests are molecules with
  meaning at the hero's-journey level. Breadth (choice, form) vs depth (understanding, function):
  newcomers want breadth and to know depth exists; veterans want depth. Relative breadth signals
  importance (50 desserts vs 5 weapons says cooking matters). Depth differences (named vs unnamed
  kobolds) signal importance but players read them as bugs. Atmosphere is the symbol channel players
  actually read: open/closed, light/dark, vistas/corners, familiar/alien, ease/difficulty (harder
  quests in rougher places), large/small, beauty/ugliness, colour saturation. MUD1 used age as a
  metaphor for danger.
- **The Story of Story / Narrative (pp. 866-873).** Worlds are places and cannot impose three-act
  structure. Narrative spectrum: non-fiction, backstory arcs (backstory should come first, not be
  retro-fitted), idea arcs, story arcs, responsive arcs, 360-degree arcs (perpetual struggle reads
  as meaningless), player arcs. Random events feel different from deliberate ones (paint-gun
  analogy). A pool of content released in reaction to player actions (dig deep, meet dwarfs) is
  viable but players resent perceived favouritism; they trust impartial code. Local narrative
  forms: puzzles, static quests (teach shared culture to newcomers), dynamic quests (gameplay only,
  rarely meaningful), chained quests (most narrative scope, can encode a moral question), player
  quests.
- **Why Story Arcs Don't Work (pp. 873-877).** Reasons designers want them, and flaws: player is
  impotent or the arc is derailable; story can be followed without playing; late joiners;
  "the more story ... the less world"; arcs end or never end; recursive conspiracy trap. "Sparks,
  yes; arcs, no." Story over the player's own story makes the world a prison.
- **Koster-Vogel cube (pp. 877-880).** Control, context, impact; Bartle drops context. Overarching
  designed storylines face a long struggle vs opt-in mini-narratives.
- **The Place of Narrative (pp. 880-882).** Designers write the history (prose or implicitly in the
  design), then cede narrative control. "Virtual world designers can't add story, they only can add
  content." Episodic content is really about boredom.
- **The Critical Aesthetic in Use (pp. 882-889).** Critics vs rant sites; worlds take months to
  review. Player-created content: in-context vs out-of-context; "99% is crap"; disappointment when
  creators aim high; subworlds; creation as an alternative path to self-discovery vs the hero's
  journey.
- **My Take on All This (pp. 889-891).** Ideally never add content except fixes, balance and
  functional enhancement; other content emerges from player activity in a deep, broad world.
  "You can only tell a story when it has ended." Load, aim, fire; the world is the designer's own
  hero's journey (Arthur: the king is the kingdom).

### Ch. 8 Coda: Ethical Considerations (pp. 892-937)
- **Intro (pp. 892-893).** Designers are responsible for real effects; a known-distressing feature
  becomes an artistic statement. Children's worlds excluded.
- **Censorship / Unpleasantness (pp. 893-898).** Self-censorship of unpleasant history (slavery in a
  pirate economy), gender strength differences, terminology that ages badly, localisation (hunting
  games in the UK).
- **The Real as the Virtual (pp. 898-901).** Worlds legalise real crimes; brands; designers avoid
  ethical edges, which stifles debate; a fruitful area for small worlds.
- **Passive Censorship (pp. 901-902).** Not acting (e.g. guild asset-stripping) is itself censorship;
  an audit trail of where goods came from is one fix, though it hurts thief play.
- **Players as People / Persona Issues (pp. 902-906).** Players accept what they could reasonably
  expect; unexpected hurtful content (rape) needs explicit warning even if historically justified.
  Disability, disease (lung cancer from smoking), poisons, food taboos (MUD2 ham). Bartle: be true
  to your beliefs, use content warnings, let players choose.
- **Privacy (pp. 906-907).** Logging vs common-carrier status.
- **Addiction (pp. 907-909).** Defensible if players come out better, would not develop as much
  otherwise, and the journey has a definite end. Not defensible: gambling-psychology variable
  rewards, and interfering with closure ("move the winning post").
- **Mental Illness (pp. 909-913).** Duty of care; worlds can help or harden issues; denying
  completion removes therapeutic value.
- **Religion (pp. 913-918).** Four options: ignore; invent (or use a dead one); include real religion
  passively (buildings with no mechanical effect, the safest for historical settings); embrace with
  tangible effects (a target for trouble). Santa Claus, Ramadan, omission, sect choice, schisms.
- **Groups / Icons (pp. 918-923).** Iconic figures (the little old man who must be wise, white
  unicorns) deliver immersion; races-as-stereotypes endorse real stereotyping; classes impose
  conformity; animal symbolism (cunning fox, predator wolf); identity drift playing non-sentient
  animals.
- **Social Engineering (pp. 923-930).** Players learn world facts, interface skills, tactics, social
  skills, values, and the real/virtual difference; not desensitisation or NPC-objectification.
  "Evil" in worlds is a sanitised label. Lessons come from abstraction of episodes (semantic
  memory); designers care whether players develop.
- **Confounding Expectations (pp. 930-934).** Challenging expectations consistently with the world's
  rules makes players think; low-level challenges (instant acceleration, walking through people) may
  transfer to reality.
- **Yourself (pp. 934-937).** The world's ethics reflect the designer's; the Karyn / "Story About a
  Tree" hoax.

---

## 2. Principles that apply

| # | Principle | Quote | Page |
|---|---|---|---|
| P1 | Immersion is the player accepting the token as themselves | "Immersion is accepting the signifier as the signified." | 846 |
| P2 | Design choices make real-world statements whether intended or not | "A virtual world that imposes a character class regime is 'about' order and conformity; one that doesn't is 'about' choice and independence." | 847 |
| P3 | Internal symbols: environment carries danger and mood | "a room complex that has increasingly lower light levels ... says that these rooms are successively more dangerous" | 847 |
| P4 | Every object should have a potential purpose | "It's not the case that everything must have a purpose, but everything ought to have a potential purpose." | 859 |
| P5 | Covenant on tools and toys | "they covenant with the players that, within the virtual world, these: Have value / Have meaning / Make sense" | 859 |
| P6 | Breadth for newcomers, depth for veterans | "They want to know that there is depth but they don't want to be exposed to it" | 861 |
| P7 | Relative breadth tells players what matters | "If ... there were 50 different ways to combine fruit to make desserts but only five legal weapon/armor configurations, that would tell players that combat was not as important" | 861 |
| P8 | Depth differences signal importance (named vs unnamed) | "this says that the ones here are not as important as the ones elsewhere" | 862 |
| P9 | Atmosphere is the symbol channel players actually read | "With atmosphere, at last, we have a way of using virtual world mechanisms and objects as symbols that players actually interpret as symbols." | 862 |
| P10 | Harder quests in rougher places warn players | "By giving players harder quests in rougher areas, designers inform them that these are tougher areas." | 864 |
| P11 | Vistas symbolise distant goals | "you can just make out the spires of the City of Bronze ... By proceeding, you're reaffirming your goal." | 864 |
| P12 | Age can signal danger | "MUD1 used time as a metaphor for danger ... The really dangerous places were flagged by their great age." | 864 (n.37) |
| P13 | Backstory first, never retro-fitted | "The backstory should come first, not second." | 868 |
| P14 | Initial configuration echoing the fictional past aids immersion | "If a virtual world's initial configuration is constructed to echo events of a fictional past, this can be a great aid to immersion." | 867 |
| P15 | Perpetual struggle reads as meaningless | "the players will eventually conclude that the struggle is meaningless" | 869 |
| P16 | Random vs deliberate events | "being hit at random is not the same as being hit deliberately" | 870 |
| P17 | Players trust impartial code, not hand-placed favours | "they trust the code to be impartial but they don't trust the live team to be so" | 871 |
| P18 | Reactive content pools | "it may be worth building a pool of content that can be released when appropriate to advance players' stories" | 870 |
| P19 | Static quests teach shared culture | "designers will use the opportunity to promote shared cultural contexts" | 871 |
| P20 | Dynamic (generated) quests are gameplay-only | "They serve gameplay purposes only, and rarely matter beyond their existence." | 872 |
| P21 | Chained quests can carry a moral question | "can conform to a predefined concept, such as whether it matters more to rescue a friend or save a village of strangers" | 872 |
| P22 | The player's own story outranks the designer's | "Virtual worlds that impose narrative—even narrative written by a famous author—are overlooking what virtual worlds are about." | 873 |
| P23 | Follow the fiction, not the story | "A virtual world based on a book can be incredibly detailed, so long as it adheres only to the fiction and not the story." | 875 (n.42) |
| P24 | More story, less world | "The more story that designers add to a virtual world, the less world there is" | 875 |
| P25 | Sparks, not arcs | "It is very good for presenting and identifying symbols. It is hopeless for presenting and identifying choice. Sparks, yes; arcs, no." | 876 |
| P26 | Designer-driven story above player story is a prison | "any virtual world that places designer-driven story above players' personal stories is a prison" | 877 |
| P27 | Avoid the recursive villain trap | "When in doubt, widen the conspiracy. Eventually, the whole world ends up as a conspiracy" | 876 |
| P28 | Designers add content, players make story | "Virtual world designers can't add story, they only can add content." | 881 |
| P29 | Write the history, then cede control | "The designers of virtual worlds write the history, either explicitly ... or implicitly (in the design)." | 881 |
| P30 | Emergent content from depth and breadth | "you need a virtual world with enough depth and breadth that players can, through the effects of their own actions, create content" | 889 |
| P31 | Story is told only after it ends | "Narrative: You can only tell a story when it has ended." | 890 |
| P32 | Do not over-protect (cotton wool) | "removing any challenge by wrapping characters in virtual cotton wool wouldn't deliver it" | 855 |
| P33 | Value = what players gain, not time spent | "I don't want to know what people are prepared to lose in terms of time or money; I want to know what they gain." | 841 |
| P34 | Known-distressing features are deliberate statements | "its inclusion then becomes an artistic statement, rather than merely an element of gameplay" | 892 |
| P35 | Unexpected hurtful content needs explicit warning | "Even if it did fit the context ... an explicit warning would be a good idea" | 904 |
| P36 | Content warnings, then let players choose | "General content warnings, like film classifications, can be used to forewarn people of what range of material they can expect." | 905-906 |
| P37 | Ethical addiction requires an end | "The process has a definite end. When your hero's journey finishes, all signs of addiction/dependency/habit are gone." | 908 |
| P38 | No gambling-style variable rewards | "virtual worlds that deliberately implement in tandem with this a variable feedback system of rewards have something of an ethical case to answer" | 909 |
| P39 | Do not move the winning post | "Virtual worlds that move the winning post as players approach it are dealing out an unnecessary cruelty." | 909 |
| P40 | Denying completion removes the benefit | "any self-realization that comes from completing a hero's journey is not going to happen if the designer never lets anyone finish" | 911-912 |
| P41 | Religion in historical settings: passive inclusion is safest | "This is the safest approach for an historical genre where religion plays a part without being the central theme" | 915 |
| P42 | Tangible effects from real religion invite trouble | "Overtly religious virtual worlds that give tangible virtual world effects to implementations of real-world religious practices are making themselves targets" | 916 |
| P43 | Unpleasant history: deliberate choice | "slavery was such an important part of Caribbean trade ... were you to omit, it your economic model would be missing a third of its goods. Do you put it in" | 895 |
| P44 | Inaction is also censorship; audit trails | "make a change to the virtual world design so that there was always an audit trail available and players can see where their stuff came from" | 902 |
| P45 | Iconic figures carry expectations | "If a player comes across a 'little old man' NPC, it's a source of great disappointment if it turns out he really is just a little old man" | 920 |
| P46 | Decide stereotypes consciously | "they should at least make that decision consciously. At the moment, most of them simply follow the flow without thinking about it." | 921 |
| P47 | Disease and disability need care | "it's by no means impossible to incorporate these themes into virtual worlds; the difficult part is doing so responsibly" | 905 |
| P48 | Challenge expectations, consistent with the rules | "If you give someone something that they are not expecting, but which is consistent with the way the virtual world operates, then they will either accept it or reject it." | 931 |
| P49 | "Evil" as label vs evil as rule by fear | "What evil really means is rule by fear." | 926 |
| P50 | The world reflects the designer's ethics | "If you think ethics are other people's responsibility, so will your players." | 934 |
| P51 | Players divert risk to characters they don't care about | "They will do anything dangerous with a character they don't care about, then hand the benefits ... over to one they do care about." | 828 |

---

## 3. Actionable items for My Medieval Life

Format: **[PRIORITY] [system]** item. *Principle, page.*

### Narrative / quests

1. **[HIGH] [narrative/quests]** Keep the Confirmed 7 rule enforced in data and code: no quest,
   marker or tutorial line may put the player on Ralph's road to the Well as *the* plot. Add a check
   to the quest test suite (or `tools/check_*`) that no `story: true` quest in
   `game/data/quests.json` references Well-quest milestones (the Well, the Dry Tree, Utterbol's
   overthrow) as player goals. *P22, P23, P26; pp. 873, 875, 877.*
2. **[HIGH] [narrative/quests]** Audit every `story: true` quest: each must be a short, opt-in
   "spark" with a clear end (teach a skill, introduce a place or person), never a chain that blocks
   other play or keeps escalating. Cap story-quest chains at a fixed length and give each a
   completion state. *P25, P27, P31; pp. 876, 890.*
3. **[HIGH] [narrative/quests]** Need-based side quests are dynamic quests, which Bartle says
   "rarely matter beyond their existence". Give them meaning by making their *consequences* persist
   in the simulation: the robbed giver's household recovers, the fed family stays in the village,
   the relationship value changes, and the player's chronicle records it. Test: completing a quest
   changes at least one persistent NPC/household value. *P20, P28, P30; pp. 872, 881, 889.*
4. **[MEDIUM] [narrative/quests]** Add one or two hand-authored *chained* quests that pose a moral
   choice with no "correct" answer in Morris's terms, e.g. a thrall fleeing from a Burg/Utterbol
   trader: hide them (risk with the lord and guards) or hand them over (reward). Both outcomes run
   through the same law/economy rules as everything else. *P21, p. 872.* (Blocked on J-S1/U21; owner
   decision.)
5. **[MEDIUM] [narrative/quests]** Build a pool of reactive content keyed to *systemic* triggers
   rather than designer whim: e.g. mining past a depth threshold reveals an old working, travelling
   far along a road reveals a canon place (Burg of the Four Friths, Cheaping Knowe), a lord's
   tax rises when the manor treasury runs short. Triggers must be deterministic (seeded) and
   identical for every player, so they read as world rules, not favouritism. *P16, P17, P18; pp.
   870-871.*
6. **[MEDIUM] [narrative/quests]** Use "ease versus difficulty" to signal danger by distance: quests
   offered in the home village are errands (bread, logs, bandages); quests about the wilder overworld
   (bandit camps, bears, caves with skeletons) are harder and pay more. Check that generated quest
   difficulty correlates with distance from the village / danger zone. *P10, p. 864.*
7. **[LOW] [narrative/quests]** Avoid 360-degree loops: bandits and predators should be suppressible
   for a meaningful period (bounties clear a camp; a cleared camp stays cleared for a season) so the
   player's effort shows. *P15, p. 869.*

### Lore

8. **[HIGH] [lore]** Make backstory precede mechanics, never justify them after the fact. When a
   mechanic needs a reason (heirs after permadeath, why magic is learnable, why the caravan exists),
   source it from `docs/world/` canon or label it GAME EXPANSION in the wiki; do not invent lore to
   paper over a balance decision. Add a review step: each new mechanic's wiki entry cites a
   paragraph id or carries the GAME EXPANSION label. *P13, p. 868.*
9. **[HIGH] [lore]** Make the village's *initial configuration* echo Morris's past: ruins, wayside
   crosses, old roads toward the Wall of the World, place names and inherited goods that point to
   events in `F_TIMELINE.md`, so history is "written implicitly in the design" and discovered, not
   narrated. *P14, P29; pp. 867, 881.*
10. **[MEDIUM] [lore]** Use age as a danger code (MUD1's trick) consistently in the overworld
    generator: the farther from the village and the older the remains (barrows, ruined towers, the
    deserts toward the Dry Tree), the more dangerous. Fits Morris, where the far east is older and
    stranger. *P12, p. 864.*
11. **[MEDIUM] [lore]** Iconic figures should deliver on their icon: the hermit, the old wise woman
    (the Sage / Swevenham echo), the friar who "keeps goats, is somewhat of a leech" in canon should
    give real knowledge (recipes, magic lore, a map hint), not be decorative. *P45, p. 920.*
12. **[LOW] [lore]** Keep the wiki optional and layered: give newcomers breadth (what can be done)
    and let depth (formulas, canon citations) sit one tap deeper. Bartle notes "Not everyone wants
    to read page after page of lore". *P6, p. 861; p. 859 n.32.*

### Immersion

13. **[HIGH] [immersion]** Every interactable or visible object should have a potential use: audit
    `items.json`, recipes and placed props for items with no use (no recipe input, no sale value, no
    need it satisfies) and either give them one or mark them clearly decorative in the wiki. The
    "nothing comes from nowhere" rule already matches this; extend it to "nothing goes nowhere". A
    test can list item ids that are never consumed, sold, worn or used. *P4, P5; p. 859.*
14. **[HIGH] [immersion]** Use atmosphere codes deliberately in the overworld and caves: darker
    palette or lighting as cave depth rises, closed corridors for caves, open vistas from plateaus
    showing distant landmarks (a far tower or mountain line that the player can actually reach).
    Visually check a generated sample for each code. *P3, P9, P11; pp. 847, 862-864.*
15. **[MEDIUM] [immersion]** Check what relative breadth says. Count recipes and actions per system
    (cooking, smithing, farming, trading vs combat). A life sim should have breadth in production
    and trade; if combat options outnumber them, the game "says" it is about fighting. Report the
    counts in the design doc. *P7, p. 861.*
16. **[MEDIUM] [immersion]** Depth signals importance: every villager is named, aged and in a
    household; make sure bandits and caravan traders are not the only unnamed humans, or that the
    difference is intended (unnamed bandits say "these people do not matter", which conflicts with
    the "player lives under the same rules" intent). *P8, p. 862.*
17. **[MEDIUM] [immersion]** Resist cotton-wool convenience: keep real friction such as carrying
    goods to market, limited merchant funds, arrows/tools wearing out. When a quality-of-life change
    is proposed (sell from backpack anywhere, infinite ammo), weigh it against the living-economy
    intent, since Bartle uses exactly these as the mass-market mistake. *P32, p. 855.*
18. **[LOW] [immersion]** Any deviation from real-world physics that the player relies on (walking
    through villagers, instant acceleration) should be consistent and, where possible, motivated
    (villagers step aside). *P48, pp. 931-932.*

### Progression

19. **[HIGH] [progression]** Define and expose a life's "definite end" and a family-line arc: a
    character's life ends (old age, death), the heir carries on, and the game records a chronicle of
    each life (deeds, property, quests done). Give the player the option to retire or close a line
    with a summary. This is the hero's-journey closure Bartle says makes a compelling game ethical.
    *P31, P37, P40; pp. 890, 908, 911-912.*
20. **[HIGH] [progression]** No moving winning posts: skill thresholds, prices and quest rewards
    must not scale up with the player's level to keep them grinding. Add a balance check that no
    curve in `balance.json` rescales targets by player progress (prices stay stock-driven, not
    player-level-driven). *P39, p. 909.*
21. **[HIGH] [progression]** No variable-ratio reward loops designed for compulsion: loot from
    hunting, mining and bandits should come from the simulation (what the animal or bandit actually
    has), not from random jackpot tables with rare spikes. Review any drop tables for this. *P38, p.
    909.*
22. **[MEDIUM] [progression]** Permadeath with heirs invites risk-diversion (play a throwaway heir
    recklessly, pass wealth to the favoured one). Decide whether this is acceptable; if not,
    inheritance should follow the same rules as NPC inheritance (tax, division among heirs,
    reputation inherited too). *P51, p. 828.*
23. **[LOW] [progression]** Measure success by what players gain (skills learned, places found,
    a life built) in the chronicle and end-of-life summary, not by hours played or streaks. Do not
    add daily-login or streak mechanics. *P33, p. 841.*

### Ethics

24. **[HIGH] [ethics]** Settle U21/J-S1 consciously and record it in `docs/DECISIONS.md`: thralldom
    is to Morris what slavery is to Bartle's pirate economy. Options: (a) depict it as an evil of
    certain lands that the player can oppose but never profit from; (b) depict it only in lore/
    dialogue; (c) omit it. Recommendation: (a) or (b), since omission falsifies the canon world and
    (a) gives a real moral dimension; never let the player buy or sell thralls as goods. *P34, P43;
    pp. 892, 895.*
25. **[HIGH] [ethics]** Add a short content note on first launch or on the store page: violence,
    theft, hunting animals, death of the player character and of villagers including children's
    parents, ageing and death of family. Bartle's test is what the player "could reasonably expect";
    permanent death of the character and family members needs saying up front. *P35, P36; pp. 904-906.*
26. **[HIGH] [ethics]** Religion: Morris's world is overtly medieval Christian (Holy Church, a
    bishop-baron, friars, knighting in a church). Use Bartle's third option: churches, priests and
    feasts exist as places and people with ordinary economic roles, but no prayer-buffs, divine
    healing or sacrament mechanics; keep the magic discipline secular (Confirmed 9) and keep J-M4
    (sorcery trials) as social/legal risk, not a theology statement. Record this in
    `docs/DECISIONS.md`. *P41, P42; pp. 915-916.*
27. **[MEDIUM] [ethics]** Disease and injury: if illness, poison or lasting injury is added to the
    health system, avoid real named diseases with moralising causes (e.g. a "drinking causes
    disease" rule), and make lasting disability optional or recoverable. *P47, pp. 904-905.*
28. **[MEDIUM] [ethics]** Theft and robbery: the economy already tracks real goods; consider a
    provenance trail on stolen goods (marked as stolen for a while, recognisable by the owner or
    guards) so the law system can act and the player can see consequences, keeping a deliberate
    stance rather than passive tolerance. *P44, p. 902.*
29. **[MEDIUM] [ethics]** Stereotyping: the asset set includes Philippine-mythology monsters and
    wolves/foxes/bears. Decide consciously how creatures and any foreign peoples (the Burg folk,
    Utterbol and the far eastern peoples; check `docs/world/A_ENCYCLOPEDIA.md` for any period racial
    description in Morris's text) are shown; do not import Morris's period racial language into NPC text without review. *P46, pp.
    920-921.*
30. **[MEDIUM] [ethics]** Make "evil" mean rule by fear, as Morris does with Utterbol (the Lord of
    Utterbol rules by terror), rather than an aesthetic label: villains' power should show in how
    their subjects behave (fear, flight), giving the player a meaningful moral contrast. *P49, p.
    926.*
31. **[LOW] [ethics]** Food taboos: the cook and tavern chains include meat and ale; keep vegetarian
    and non-alcoholic routes viable (pottage, bread, cheese) so no player is forced to "eat the ham"
    to survive. *pp. 905, 916.*
32. **[LOW] [ethics]** Hunting: if regional releases are ever considered, note Bartle's UK hunting
    example; keep hunting a means of food/hides inside the economy, not a trophy score. *p. 897.*

---

## 4. Warnings the game risks

- **The Well becomes the quest anyway.** The temptation to use Morris's plot as a main questline
  (the obvious marketing hook) is exactly Bartle's "narrative written by a famous author" trap, and
  would contradict Confirmed 7/8. Story markers (green pennants) can drift into a railroad. (pp.
  873, 875, 877)
- **Generated need-quests feel hollow.** "Bring X to Y" quests from needs are dynamic quests;
  without persistent consequences they are filler. (p. 872)
- **Endless loop with no closure.** An endless overworld plus endless heirs risks a never-ending
  journey; without a per-life ending and chronicle the game loses its strongest hook and its
  ethical defence. (pp. 908-912)
- **Convenience creep erodes the living economy.** Each QoL shortcut (remote selling, infinite
  supplies) is the Asheron's Call 2 cotton-wool error and breaks "nothing comes from nowhere".
  (p. 855)
- **Retro-fitted lore.** With an agent-heavy pipeline it is easy to write a lore justification for
  each mechanic after the fact; Bartle calls this "less satisfactory" and players notice. (p. 868)
- **Unexamined political statements.** A job/skill system can read as conformity; thralldom, church
  and lordship in Morris all carry real-world meaning. Silence or omission is also a statement.
  (pp. 847, 901-902)
- **Inconsistency read as bugs.** Deliberate differences in depth (unnamed bandits) will be read as
  bugs unless clearly coded through atmosphere. (p. 862)
- **Period racial and religious language in Morris.** Quoting canon verbatim in NPC dialogue can
  carry 1890s attitudes that age badly. (pp. 897, 920-921)
- **Unexpected distress from permadeath of family members**, especially for younger players if the
  rating is low; Bartle explicitly excludes children's worlds from his analysis. (pp. 893, 904)
- **Single-player assumptions baked in before multiplayer.** Confirmed 10 (player-hosted 3-4
  player co-op) is coming; systems built now (quests, inheritance, theft, story triggers) can harden
  into single-player-only shapes. See section 6.

---

## 5. Not applicable (current single-player build; see section 6 for what returns in co-op)

- Law of data/IP ownership, virtual property sale, jurisdiction, employment law for volunteers
  (pp. 824-826); Korea PK ratings (p. 825).
- Live-team community management, multi-lining, collusion, out-of-world communication, bots (pp.
  827-830), except the risk-diversion point re-read for heirs.
- Episodic patch-based story arcs, shards, live-team favouritism accusations, monthly patches as
  narrative (pp. 868-871, 881-882); only the deterministic-trigger lesson carries over.
- Koster-Vogel cube's context axis and real-world holiday events (pp. 877-880), unless seasonal
  events are wanted.
- Rant sites and critic/reviewer economics (pp. 882-885).
- Player-generated out-of-context content, subworlds, peer review (pp. 885-889); in-context
  building (houses, workshops) is the only relevant form and already exists.
- Brand placement and real-world locations (pp. 899-900).
- Privacy and chat logging (pp. 906-907); guild asset-stripping (pp. 901-902) beyond the
  provenance idea.
- Live-team duty of care and barring players (pp. 909-911).
- Identity drift from playing as animals (pp. 922-923).
- Karyn hoax (pp. 934-937), except as a reminder that the design reflects the designer's ethics.
- Art vs design debate, film-theory dialectics as such (pp. 832-856), beyond the symbolism lessons
  extracted above.

---

## 6. For the future player-hosted multiplayer (3-4 players)

Context: Confirmed 10 (owner, DECISIONS 2026-10-17): player-hosted worlds for about 3-4 players, no
always-on server; not built yet. In a small co-op world the "live team" is effectively the host
player, and the players usually know each other. Bartle's pp. 893 and 913 note that small worlds
where "everyone knows everyone else" are on safer ground, but several multiplayer issues still apply.

### Shared story and narrative

1. **[HIGH] [narrative/quests]** Each player's story must stay their own. In a shared world, one
   player's quests must not consume or end another's: need-based quests belong to the player who
   accepted them, and story sparks should be per player (each player can do them) or shared with
   credit to all present. Late joiners must not find that the story already happened without them
   ("People don't like coming in on a narrative after it has started", p. 875). *P22, P26; pp. 873,
   875, 877.*
2. **[HIGH] [narrative/quests]** Reactive content triggers (section 3 item 5) must fire by world rule,
   the same for every player and every host, and never on the host's say-so. Players trust code to
   be impartial; a host-controlled trigger reads as favouritism ("Hey, I dug a hole in this mountain
   over here, how come you didn't give me any dwarfs?", p. 871). *P16, P17; pp. 870-871.*
3. **[MEDIUM] [narrative/quests]** Player quests (Bartle's top form, p. 872): let players hire and
   commission each other through the same systems NPCs use (contracts, wages paid from a real purse,
   deliveries). The living economy then creates co-op content without designer arcs. *P30; pp. 872,
   889.*
4. **[MEDIUM] [narrative/quests]** Shared chronicle: record deeds per player in the world chronicle,
   so each player's story can be told when it ends ("You can only tell a story when it has ended",
   p. 890). *P31.*
5. **[LOW] [narrative/quests]** Individual vs community: groups get through content faster than
   individuals (p. 854). Scale quest supply to the number of players present, from real village
   needs, rather than handing three players three copies of the same quest.

### Ethics between players

6. **[HIGH] [ethics]** Decide player-vs-player harm explicitly: can one player steal from, rob or kill
   another, or another's family? Bartle's "responsibility versus liability" dialectic: players
   accept only the risks they could reasonably expect (pp. 854, 903-904). Recommendation: make PvP
   harm a per-world host setting chosen at world creation, shown to every joining player before
   they join, and default it to off. *P34, P35; pp. 854, 892, 904.*
7. **[HIGH] [ethics]** If theft between players is allowed, give stolen goods the same provenance
   trail as NPC theft (section 3 item 28), so the victim can see what happened and the law system
   can act. Doing nothing is itself a stance (p. 902). *P44.*
8. **[HIGH] [ethics]** Shared property and shared treasuries: a shared household, workshop or stall
   with pooled coins needs clear rules for who can withdraw and sell, plus a visible ledger. Bartle's
   guild asset-stripping case (pp. 901-902) is the failure mode in miniature. *P44.*
9. **[MEDIUM] [progression]** Risk diversion between characters (p. 828): with several players and
   heirs, players can funnel wealth from a reckless character to a protected one. Inheritance and
   gifts between players should follow the economy's normal rules (real transfers, visible in
   the ledger), and the decision whether this is acceptable should be recorded. *P51.*
10. **[MEDIUM] [ethics]** "Players play the system" (p. 828): with a host who controls the save,
    exploits such as duplicating goods by save reloads or disconnecting mid-trade become possible.
    Make trades atomic and persist both sides of every transfer together; consider host-side
    validation of guests' actions. *p. 828.*
11. **[MEDIUM] [ethics]** Content expectations differ between players in one world: the content note
    (section 3 item 25) should be shown to guests on join as well as to the host, together with the
    world's PvP setting. *P36; pp. 905-906.*
12. **[LOW] [ethics]** Chat and privacy (pp. 906-907): if in-game chat is added, keep it
    peer-to-peer, do not log it to any server, and say so. Logging implies taking responsibility
    for what is said.
13. **[LOW] [ethics]** Community management in miniature (pp. 827-828): the host needs basic tools,
    such as kicking a guest, recovering a stuck character, and resolving a loot dispute by an
    ownership record. Design these in; there is no live team.

### Immersion and progression in co-op

14. **[MEDIUM] [immersion]** Keep body collision rules consistent and motivated: if players can walk
    through each other (to stop body-blocking doors, p. 932), make villagers step aside too, so
    the rule reads as part of the world.
15. **[MEDIUM] [progression]** Per-life closure must still work when players are at different
    stages: one player's character dying or retiring must not end the world or the others' journeys,
    and the next heir rejoins the same world. *P37, P40; pp. 908-912.*
16. **[LOW] [narrative]** Reputation (J-S3): decide whether it is shared by the party or per player.
    Bartle's individual vs community dialectic (p. 854) argues for per player with party-level
    effects only where the deed was joint, so no player is punished for another's crime.

### Not applicable even in co-op
- Large-scale live-team operations, shard divergence, monthly patches, rant sites, real-money trade
  and eBay sales, legal jurisdiction questions, and server-side logging (pp. 824-830, 868-871,
  882-885, 906-907): there is no operator and no always-on server.
