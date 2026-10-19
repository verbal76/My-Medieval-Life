# Notes B: Bartle, *Designing Virtual Worlds*, Chapter 3 "Players" (book pp. 157-318)

Source file: `part_B.txt`. Its actual extent is **book p. 157 (end of Ch. 2) to the middle of p. 318**: it
starts with the last pages of Chapter 2 (input modes, VR, extensibility) and stops mid-sentence in
"Things to Demote" (p. 318). Pages 319-328 are **not** in the file and are not covered here. Everything
was read in full.

The game is single-player. Wherever Bartle talks about other players, these notes read it as
**the ~70 villagers (NPCs) standing in for other players** or mark it not applicable. Page numbers
are the book's printed numbers.

Repo facts used for "current game" checks (looked at briefly, read-only): the dialogue keeps
only a single "met" flag per villager (`game/scripts/ui/dialogue.gd:73-78`); the player can ask an
adult to be their partner (`game/scripts/core/life.gd:441`); the heir keeps a child's name and sprite
(`life.gd:574-591`); there is a journal holding a "village record" and quests, a resources page, a
wiki window, an appearance picker (`game/data/appearances.json`) and a single opening hint
(`game/scripts/ui/game_ui.gd:56`). The code has no reputation, epithet, gossip or festival system.

---

## 1. Section-by-section summary

**End of Ch. 2: modes, VR, extensibility (pp. 157-166).** The default input mode a designer picks
("a simple, almost throwaway design decision") shapes the world's ethos. In graphical worlds you
have to stop playing to talk (p. 157). Flat graphics already immerse well, because players "will
happily ignore negative cues" when they get enough positive ones. VR adds little unless the design
actually uses it (pp. 158-163). Worlds are extended by a live team that drifts from the original
vision. Players "know nothing about virtual world design" because their view is personal and
short-term, and designers can no longer play for fun (pp. 163-166).

**Who are players and what do they want (pp. 167-171).** Design for the player, not the character
(p. 167). Demographics lead to stereotypes. Designers need **playing styles**: what players find fun
and how the styles interact, so that every style has activities and new features can be checked
against each one (pp. 168-171).

**The nature of fun and the four types (pp. 172-177).** "Fun" means whatever brings a player back,
and it differs from player to player. Drudgery such as long empty treks and rare spawns wears thin
while rewards lose their shine (p. 172). The four types are achievers, socializers, explorers and
killers (pp. 173-174). They sit on two axes, acting/interacting and players/world: achievers act on
the world, explorers interact with it, socializers interact with players, killers act on players
(pp. 175-176). Limiting how much the world can be changed hurts achievers and explorers. Adding
interaction tools, such as notes on anything, helps socializers and explorers (p. 177).

**Dynamics (pp. 178-182).** The types affect each other's numbers like predators and prey. Killers
drive socializers away sharply. Explorers mildly suppress killers, and "a virtual world can really
only ever benefit by attracting explorers" (pp. 180-181). There are four stable states: killers and
achievers; socializers dominant; all four balanced (the best); empty (p. 181). You can **fake a type
with mobiles (NPCs)**, killers especially, because NPC aggression is easier to bear and can be
controlled (p. 182).

**General observations and using the model (pp. 183-188).** Achievers treat the world as a game,
explorers as a pastime ("gardening, or messing about in the kitchen"), socializers as entertainment,
and killers as sport ("huntin', shootin', and fishin'") (p. 183). Don't be too exclusive, don't try to
please everybody, and tell the same message to everyone (p. 184). The design tells players what the
game is "through deeds rather than words": with 25 weapon types and 2 basket types, the game is
about weapons (p. 185). Check each new feature against the four types (pp. 185-186). The model's
limits: players change type over time along the "main sequence" (killer, explorer, achiever,
socializer). It can't account for poor design, such as phone players who won't type commands
(p. 187). It is descriptive, not normative. Fix outside problems first: "recover the players, then
balance it" (p. 188).

**Newbie flow (pp. 189-193).** Without newcomers a world empties. Churn, sink and the newbie hose.
"Newbie-friendliness should always come before oldbie-friendliness" (p. 192). For a total beginner the
first job is to get them to do anything at all. Then let them find the behavioural limits quickly
and give them plenty to see and do, without overwhelming them. Show only the commands they need and
consider a simplified newbie UI (pp. 192-193, fn 24). The design can steer newcomers towards a type
by "presenting opportunities, not arm-twisting" (p. 193).

**Bartle Test (pp. 194-197).** This is a self-selected questionnaire with flaws (giveaway questions,
no "neither" answer, poor handling of ties). It is useful only to compare similar worlds with each
other.

**Other categorizations (pp. 197-205).** Farmer's **Path of Ascension** runs passives, actives,
motivators, caretakers, geek gods. Help people move along it, or the community goes sterile
(pp. 198-199). Hedron's **Circles** run survival, competence, excel, prove mastery, seek new
challenges ("the only entertainment left is interaction with other players"), and everything is one
(pp. 200-201). Yee's **facets** are relationship, immersion, grief, achievement and leadership. In
that survey explorers did not show up as a type. Immersive is not the same as addictive. Stickiness
is strongest for relationships, then achievement, then leadership (pp. 201-205).

**Levels of immersion (pp. 205-210).** The levels are player, avatar (a puppet), character (a
representation) and persona (the player *is* the character: "you feel that you have died").
Immersion is psychological more than perceptual and is different from flow. Immersion matters
because of what it delivers, which is identity (pp. 206-210).

**Celebration of identity (pp. 210-220).** In Polly's Tale, part 1, Bartle wants shy students to try
out behaviour safely. Identity is "the fundamental, critical, absolutely core point" (p. 212). You
can't design it systematically, but everything affects it. Identity grows covertly, through how you
respond to challenges: responsibility, relationships, unfairness, success and failure, betrayal,
strangers (p. 215). "Virtual worlds enable you to find out who you are by letting you be who you want
to be" (p. 216). Identification (modelling yourself on an ideal, such as a class) helps people start,
but fixed ideals become a problem when the player outgrows them. The world is a mirror (pp. 217-220).

**Progression and the 8 types (pp. 220-233).** Adding an implicit/explicit axis splits each type in
two. Killers become **griefers** and **politicians**. Socializers become **networkers** and
**friends**. Achievers become **opportunists** and **planners**. Explorers become **scientists** and
**hackers** (pp. 223-227). There are four development tracks (p. 228): griefer, scientist, planner,
friend (the main one); opportunist, networker, planner, friend (minor); griefer, networker,
politician, friend (socializer); opportunist, scientist, planner, hacker (explorer). Lessons:
- Politicians only ever become friends, so politician features should not be hard-coded deeply or
  allowed to reshape the physical world (pp. 229-230).
- The **elder game** should give tools to tinker with the world or to enjoy company (p. 230).
- Planners are immersed, so show statistics descriptively rather than as raw numbers (pp. 230-231).
- Learning follows "locate, discover, apply, internalize" (p. 232).
- "People play virtual worlds to celebrate their identity... It's a freedom thing" (p. 233).

**Anonymity, starting again, names, image (pp. 233-250).** Anonymity makes experiment safe. New
characters are a way to backspace, and players mature faster when they restart, but they won't give
up what they have invested. Forced restarts through permanent death would help, but people might
not sign up (p. 236). Let players start new characters easily (several slots), and let them build an
identity as deep or shallow as they like (p. 237). On names, players identify more with names they
choose themselves. Vetting is a barrier, so offer **name lists**, ideally drawn from the setting
(syllables, tribe surnames). Use relative names ("The Tall Stranger") until people are introduced,
and let players annotate others (pp. 238-243). **Tangibles and intangibles**: cosmetic choice costs
almost nothing and matters greatly to socializers. A full crimson armour set can carry a small real
bonus. Chekhov's gun applies to props (pp. 243-246). Freeform descriptions and fixed looks anchor a
player. The remedy is **profiling**: epithets and biographies generated from deeds, which fade at a
rate set by how important the deed was, plus auto-generated news (pp. 247-250).

**Role-playing (pp. 250-264).** In Polly's Tale, part 2, players need permission and a shielding
context before they will role-play. The role-playing paradox: you try to become the character, and
once you succeed you are no longer role-playing. "The journey is the point" (pp. 255-257). Classes
came from wargames. Their reasons are expectation, individuality, balance and direction ("Classes
provide signs"). Bartle prefers **classless** play. You can still give direction with "character
kits", and maxed-out characters are curbed by permanent death or by removing level caps. Classless
allows change: guard a caravan, take up trading, become a merchant. "You can be something that the
designers haven't even dreamed of" (pp. 257-263). With soft role-playing (class and race limits) the
character hits walls the player wants to pass (pp. 263-264).

**Masquerading and playing incognito (pp. 265-273).** People lie about who they are in real life,
and when it comes out the damage is real. Designers should play their own world incognito "from
beginning to (nominal) end" to learn what it feels like (p. 272).

**Player rights and A Story About a Tree (pp. 274-283).** Players have real-world rights and
characters have none. Inside the world, the implementation defines ownership. Content the player
"didn't sign up for" breaks immersion, and an ethical lapse is remembered longer than a bug
(pp. 278-280). Karyn's memorial tree shows that virtual relationships and communities are real
(pp. 280-283). "Creating constructs in the minds of players is what a designer's job is all about"
(p. 283).

**Community (pp. 284-299).** Communities are 20% nature (design) and 80% nurture. The first
inhabitants seed the culture. A world that looks empty loses newcomers within minutes (p. 287,
fn 108). Greeters reassure, teach the basics and introduce people (p. 289). A community needs means,
reason, shared context, voluntary participation and overlapping membership (p. 290). It is stronger
with shared knowledge, common practices, a history, a shared vision and joint projects (p. 291).
Levels: communication, interest, practice, commitment, spiritual (pp. 291-293). Groups must stay
voluntary, and stress has to come in order (p. 294). Designing for community is designing for
relationships: "It's a friendship thing" (p. 295). Community levels mirror the instinctive, learner,
doer, expert stages of a player (pp. 296-297).

**Influence through design (pp. 299-318).** Every rule has indirect consequences. The lockpicking
example: unpickable locks push thieves into pickpocketing the keys instead (p. 299). **Sink**
(newcomers leave early) and **drift** (established players fade away silently) (pp. 300-302). The
cures are an "auto" button at character creation, a mentor, a "wow" within five minutes, rewards for
anything, good help and easy early goals (p. 301). "Immersion is a freedom thing; community is a
friendship thing" (p. 302). Community size: communities fragment beyond about 250 (150 in real
life). Small communities are friendlier and treat newcomers personally (pp. 302-304). Partitions can
be geographic, functional, formal (a village "leader" office that sets local rates) or informal
(bandits drawn by "plump wagon trains"). Communities can be entwined, with cross-links ("we only buy
old swords from members of the fighters' guild"), and given structure (pp. 304-309). Ways to promote
community:
- Communication channels and non-verbal cues and emotes.
- Filtered speech, such as drunken "sh".
- Language barriers.
- Mutual dependencies: miners and smiths, but never "50 components to make a cart", and a smith may
  still dig their own ore.
- Favours: "acts of kindness are the currency of friendships".
- Dependencies between communities over resources.
- Reconnection without teleporting, because teleporting "plays merry hell with economic systems";
  instead the character keeps acting while the player is offline.
- A recorded jargon dictionary.
- Communal leisure: storytelling, music, a way to relax inside the world.
- Stake-holding through housing, with property condition as an indicator of community health
  (pp. 309-317).

Things to demote are xenophobia, prejudice and oppression: "People don't like having to be on their
guard the whole time" (pp. 317-318; the file ends here).

---

## 2. Principles that apply to My Medieval Life

| # | Principle | Quote (verbatim) | Page |
|---|---|---|---|
| P1 | The default control mode shapes the style of play | "The designer sets the default mode. The default mode shapes the style of play." | 157 |
| P2 | Enough positive cues make immersion easy; 16 px art is enough | "Players like being immersed in virtual worlds, and will happily ignore negative cues if they get sufficient positive ones" | 161 |
| P3 | Design for the player's experience | "The aim of designers is to provide an experience for players, not for characters." | 167 |
| P4 | Give every playing style something to do | "they could ensure that there were activities available for all playing styles (or be prepared to accept the consequences if there weren't)" | 170 |
| P5 | Empty travel and repeated chores wear thin | "Is spending 40 minutes tromping across a desert without meeting a single fellow player fun?" | 172 |
| P6 | Drudgery doesn't get better with time | "the rewards lose their luster, whereas the drudgery never gets any more interesting?" | 172 |
| P7 | Notes and annotation help explorers and socializers | "allowing players to keep notes on anything in the world ... then you'd boost socializers and explorers" | 177 |
| P8 | Explorers are always good for a world | "a virtual world can really only ever benefit by attracting explorers" | 180-181 |
| P9 | NPCs can stand in for killers | "Players can tolerate being inconveniently beaten up by mobiles more readily than they can by fellow players, and mobiles have the advantage of being controllable." | 182 |
| P10 | Each type sees the world differently; explorers treat it as a homely pastime | "Explorers see them more as pastimes, such as reading, gardening, or messing about in the kitchen." | 183 |
| P11 | Content tells players what the game is about | "when there are 25 different kinds of weapons and two different kinds of baskets, that's not what it's saying." | 185 |
| P12 | Check every new feature against the types | "When you add new functionality, it's useful to run through the player types to be sure it doesn't help or hurt any of them too much" | 185-186 |
| P13 | Phone input friction defeats good design | "people just can't be bothered to thumb in commands." | 187 |
| P14 | Newcomers come before veterans | "newbie-friendliness should always come before oldbie-friendliness." | 192 |
| P15 | Newcomers need limits and plenty to see and do | "enabling them to find the world's behavioral boundaries quickly and providing plenty of interesting things to see and do" | 192-193 |
| P16 | Don't overwhelm newcomers | "But not so many that the newbie is overwhelmed." | 193 |
| P17 | Steer by offering, not forcing | "It's about presenting opportunities, not arm-twisting." | 193 |
| P18 | Late game turns to people | "Players feel that they have exhausted everything that the virtual world has programmed in for them to do. The only entertainment left is interaction with other players." | 201 |
| P19 | Relationships are the stickiest motivation | "Stickiness is strongest for relationships, then for achievement, then for leadership." | 205 |
| P20 | Death at persona level feels personal | "If you're killed in a fight, you don't feel that your character has died, you feel that you have died." | 207 |
| P21 | Identity is the core | "The celebration of identity is the fundamental, critical, absolutely core point of virtual worlds." | 212 |
| P22 | Identity grows through how you respond to challenges | "Dealing with responsibility, relationships, unfairness, success/failure, betrayal, strangers, and so on." | 215 |
| P23 | Fixed ideals hold players back | "If a virtual world commits a player to identifying with a fixed set of ideals, there will be problems when those ideals are no longer appropriate." | 219 |
| P24 | The elder game: tinkering tools and company | "the elder game ... would work best if it aimed at providing tools for people to tinker with the world or to enjoy one another's company." | 230 |
| P25 | A fresh start needs a radically different situation | "Only if the elder game is radically different from what went before will players begin development from scratch again." | 230 |
| P26 | Keep political power away from the physical world | "politicians should not be given too much ability to affect the physical structure of the world" | 230 |
| P27 | Immersed planners prefer descriptions to numbers | "the number is represented descriptively or graphically instead." | 231 |
| P28 | Learning cycle | "Locate, discover, apply, internalize." | 232 |
| P29 | Restarting helps people grow, but permanent loss of all progress scares them off | "if they knew that characters could die dead-dead after months of playing time, players perhaps wouldn't sign up" | 236 |
| P30 | Identity as deep as the player wants; easy fresh starts | "Identities should be constructible to as great (or shallow) a level of detail that a player wants." | 237 |
| P31 | Chosen names and names from the setting | "Players identify more with their characters if they get to choose the names themselves" | 240 |
| P32 | Names learned on introduction; annotation | "in the real world people don't walk about with their names tattooed to their foreheads" | 242 |
| P33 | Cheap cosmetics matter to socializers | "It costs a virtual world practically nothing to allow characters to have different color clothes, hair, weapons, and so on" | 244 |
| P34 | Props should work | "If there's a gun on the wall then you ought to be able to fire it" | 245 (fn 80) |
| P35 | Profiling: titles and records generated from deeds | "characters have computer-generated descriptions based on their actions." | 249 |
| P36 | A record's lifetime depends on its weight | "The half-life of these descriptions should depend on their importance." | 249 |
| P37 | Classless play needs signposts | "Not everyone knows who they want to be." / "Classes provide signs." | 260 |
| P38 | Curbing maxed-out characters | "To stop getting maxed-out killing machines, either introduce permanent death into your virtual world or take off the level caps." | 261 |
| P39 | Classless lets players change career | "In a classless system, you can be something that the designers haven't even dreamed of." | 263 |
| P40 | Designers should play the whole thing through | "By actually playing a virtual world as a real player from beginning to (nominal) end, designers can get an unparalleled understanding of what it 'feels' like." | 272 |
| P41 | Content outside what the player expects breaks the game | "They didn't sign up for that, and suddenly the game is not a game any more." | 278 |
| P42 | Ethics outlast bugs | "Bugs just show incompetence, and can quickly be fixed; poor ethics show poor principles, and they aren't so easily forgotten." | 279-280 |
| P43 | An empty-feeling world loses newcomers | "If a prospective player arrives and finds the world empty, they'll perhaps potter around for a few minutes but then leave." | 287 (fn 108) |
| P44 | The greeter's three aims | "Greeters have three aims: to reassure newbies; to ensure they understand the basics of how to play; to introduce them to the community." | 289 |
| P45 | Community needs a history | "The community has a history." | 291 |
| P46 | Solo play must remain possible | "Players should be able to spend time on their own if they feel like it." | 294 |
| P47 | Community means relationships | "When designers are designing for community, they are really designing for relationships." | 295 |
| P48 | Rules have indirect consequences (lockpicking) | "Will thief-class characters ignore lock-picking skills and max out pickpocketing instead so they can steal the keys they need?" | 299 |
| P49 | Sink: the first minutes | "giving them a mentor the moment they've caught their breath, showing them 'wow!' environmental effects within five minutes and rewarding them for absolutely anything they do." | 301 |
| P50 | An "auto" button at creation | "a virtual world with a beautiful character creation system still needs an 'auto' button" | 301 |
| P51 | Drift is silent | "most players—the 'silent majority'—simply drift away without a word." | 301 |
| P52 | Freedom and friendship | "Immersion is a freedom thing; community is a friendship thing." | 302 |
| P53 | Small communities are personal | "Friendlier. Newbies are treated by all members at a personal level." | 303 |
| P54 | NPCs are usually second-class; this game's are not | "Non-player characters are usually either disenfranchised or statistical aggregates." | 306 (fn 121) |
| P55 | A formal leader office that sets local rates | "all villages may be defined to have a 'leader' office, the holder of which is responsible for setting local rates" | 306 |
| P56 | Entwine groups with cross-links | "Sorry, we only buy old swords from members of the fighters' guild" | 308 |
| P57 | Speech filters spark conversation | "If characters drink 10 bottles of ale, replace all occurrences of the letter 's' in their speech with 'sh.'" | 310 |
| P58 | Mutual economic dependency | "Miners need blacksmiths to buy their iron, and blacksmiths need miners to provide the raw materials they need." | 311 |
| P59 | Dependency must not become a component maze | "If you need to source 50 components to make a cart, you're not going to make any carts." | 311 |
| P60 | Promote dependency, don't enforce it | "If blacksmiths want to dig their own iron ore, it should be possible for them to do so." | 312 |
| P61 | Favours build friendships | "Acts of kindness are the currency of friendships." | 312 |
| P62 | Threatened dependencies cause conflict | "Dependencies that are threatened can give cause for conflict." | 312 |
| P63 | Teleport and fast travel break local economies | "if characters can appear anywhere at a moment's notice it makes everywhere local to everywhere else; this plays merry hell with economic systems." | 314 |
| P64 | Record the jargon that sticks | "record anything that sticks, and make the record available to players." | 315 |
| P65 | Relaxation inside the world | "Give them ways to do it, or they'll log off and find a real-world alternative." | 316 |
| P66 | Stake-holding | "If they own some of that community space, it can help them feel like they're a permanent part of that community." | 316 |
| P67 | Property as a health gauge | "If the area where all the bards congregate is run-down, with few people on the streets, something is wrong in bardland" | 317 |
| P68 | Constant vigilance drives people away | "People don't like having to be on their guard the whole time." | 318 |

---

## 3. Actionable items for My Medieval Life

Marked **HIGH / MEDIUM / LOW** by value. *[System]* names the area of the game the item touches.
Under CLAUDE.md section 11, anything that adds a **gameplay mechanic** needs the owner's approval
(marked **owner decision**). Checks and audits do not.

### 3a. Player types: served or neglected now, and what would serve them

| Type (and its 8-type subtypes) | Served now | Neglected or at risk | What would serve it in single-player |
|---|---|---|---|
| **Achievers** (act on world; *planners*, *opportunists*) | Strongly. Skill levels and tiers, recipes unlocked by level, wealth, property, shops with attendants, a family line. | No world-defined *ranks or recognition*: "progressing their character through the world's built-in ranking system" (p. 174). Skill numbers are the only ranking. There are no long-term goals the world itself names. | Titles and standing the village grants for deeds (A3). Planners need goal tools, such as a "my plans" page in the journal (A12). Opportunists are served by classless switching (A10). |
| **Explorers** (interact with world; *scientists*, *hackers*) | Partly. An endless procedural overworld, a deep and consistent simulation (good for scientists), Morris lore, a wiki. | (1) The endless overworld risks the "40 minutes tromping across a desert" problem (p. 172) if it is only procedural filler. (2) A wiki that spells out every number removes the discovery explorers enjoy (pp. 173, 230-231). (3) No way to make notes on the world (p. 177). | Discoverable systems: the wiki opens entries as the player meets things (A7). Map pins and notes (A6). Overworld landmarks and lore finds at a set density (A8). Hackers' elder game is tinkering: building and layout tools (A14). |
| **Socializers** (interact with players → **NPCs**; *networkers*, *friends*) | Weakly. Villagers greet, talk about their work and hunger, have a binary "met" flag, can become the player's partner, and there are families and heirs. | This is the biggest gap. Relationships are the *stickiest* motivation (p. 205), and late-game players turn to other people for entertainment (p. 201). A one-bit "met" flag cannot carry friendship, favours, history or gossip. | Per-villager relationship memory built from favours, gifts, help and harm (A1). Gossip and news passed between villagers for networkers (A2). Communal evenings at the tavern (A15). Emotes or gestures towards NPCs (A16). Player notes on villagers (A6). |
| **Killers** (act on players → **NPCs**; *griefers*, *politicians*) | Griefers are served through NPC stand-ins (p. 182): theft, lockpicking, combat, hunting, bandits. Guards and fines give consequences. | No consequence beyond fines (no reputation memory). *Politicians* have nothing: the reeve and manor exist, but the player cannot hold office or sway villagers. | Crimes leave a lasting reputation record that decays by severity (A3, P36), so the boundary-testing that starts the main sequence (p. 192) teaches something. **Owner decision:** a formal office path, such as reeve or manor steward, with economic and social levers (taxes, relief, wages) but no terrain changes (A13, P26, P55). |

**Main-sequence check (pp. 186, 192, 228):** newcomers first test boundaries (killer or griefer), then
explore (scientist), then achieve (planner), then settle into company (friend). The game currently
supports steps 1-3 and is thin at step 4, the stage where long-term players stay or drift away.
Design work should focus on step 4 (A1, A2, A14, A15).

### 3b. Item list

**A1. HIGH. Give each villager a relationship memory beyond "met".** *[NPC dialogue / social]*
P19 (p. 205), P47 (p. 295), P61 (p. 312), P18 (p. 201). Add a small per-NPC record of standing with
the player, changed by favours done (quests completed, gifts, help when hungry or sick, buying their
goods) and harms done (theft seen, assault, broken deals). Greetings and prices would read from it.
Bartle says acts of kindness are what friendships are made of, and that relationships keep players
longer than advancement does. In single-player this is the main lever against drift. **Owner
decision** (new mechanic). It interacts with the economy and theft, so it would need `INT-###`
entries.

**A2. MEDIUM-HIGH. Let villagers share news (networker support and a living-world signal).**
*[NPC brain / dialogue / journal]* P35-P36 (p. 249), P45 (p. 291), P22 (p. 215). Villagers mention
recent events from the village record: deaths, births, thefts, a big sale, a bear killed. Each item
lasts according to its importance ("half-life"). This turns the existing village record into a
shared history that people talk about, so the community "has a history" in the player's ears. Data
already exists in the journal. **Owner decision** if it changes behaviour; text-only gossip could be
a small step.

**A3. HIGH. Titles and a biography generated from deeds (profiling).** *[Player state / journal /
dialogue]* P35, P36 (p. 249), P23 (p. 219). Give the player and each heir an epithet the village
uses ("Maud the smith", "Hob the poacher") and a short life record built from tangible deeds. Bad
deeds fade more slowly than small good ones, as in Bartle's example. This serves achievers (the
recognition the world defines, p. 174) and killers (consequence), and it is the profiling remedy for
an anchored image (p. 248). It also fits the heir system: each generation gets its own record, and a
family chronicle across generations gives identity to the line. **Owner decision.**

**A4. HIGH. Audit the first ten minutes against sink (newcomers leaving early).** *[Onboarding /
UI]* P43 (p. 287), P44 (p. 289), P49-P50 (p. 301), P14-P16 (pp. 192-193). Check on a fresh game:
(a) Villagers are visibly busy near the start point within the first minute, so the world does not
look empty. (b) One villager acts as greeter, covering all three aims (reassure, teach the basics,
introduce people). Today there is a single hint line at `game_ui.gd:56`. (c) Something striking
happens or is shown within five minutes. (d) Early actions are rewarded at once (the first harvest,
sale or craft gets a visible acknowledgement). (e) Character creation has an "auto" button (a random
name and look). (f) The HUD and journal show only what the beginner needs at first and reveal pages
as they become relevant. A check is approved work. A greeter NPC behaviour would be an **owner
decision**.

**A5. HIGH. Keep the planned carts shallow and optional.** *[Production chains / carts (planned)]*
P59 (p. 311), P60 (p. 312). Bartle's example is literally a cart: "If you need to source 50 components
to make a cart, you're not going to make any carts." Count the full recipe tree for a handcart and a
pulled cart (logs, planks, wheels, smith bars, cart parts). Make sure a player can either buy one
from a carpenter or build it with a modest number of distinct inputs. Keep the dependency web
promoted, not enforced: the player can always gather the raw materials themselves, which the game
already allows.

**A6. MEDIUM. Map pins and player notes on places and villagers.** *[Map view / journal]* P7
(p. 177), P32 (pp. 242-243). Let the player drop a note on a map location ("iron here",
"wolves") and on a villager ("buys wool dear"). Bartle says this boosts explorers and socializers
together, it costs little, and it touches no game rules.

**A7. MEDIUM. Let the wiki unlock gradually and describe rather than list numbers.** *[In-game
wiki / skills window]* P8 (p. 180), P10 (p. 183), P27 (pp. 230-231), P28 (p. 232). Explorers want to
discover how the world works. A wiki that opens with every recipe, price formula and tier number
takes that away. Option: entries appear once the player has seen or done the thing ("locate,
discover, apply, internalize"), and prices and qualities are described in words ("dear this week",
"fine work"), with numbers available as an option for players who want them. Check this against
the existing generated wiki text before changing anything. **Owner decision** on the default.

**A8. MEDIUM. Set a density for points of interest in the endless overworld.** *[Overworld
generator]* P5 (p. 172), P6 (p. 172), P63 (p. 314). Measure, in generated output for the golden seeds,
the typical walking time between things worth finding (resource clusters, ruins and landmarks,
Morris lore locations, bandit camps, caravan routes). Bartle calls long empty walks the
archetypal unfun drudgery. A target spacing, checked by a deterministic test, keeps exploration
rewarding. This would be a generator version bump if output changes (CLAUDE.md section 6).

**A9. HIGH. Do not add instant fast travel; if travel is shortened, make it cost time and go
through the world.** *[Overworld / economy / horses and carts (planned)]* P63 (p. 314). The economy
depends on local availability ("more sellers nearby = cheaper") and on caravans importing and
exporting. Teleporting "makes everywhere local to everywhere else; this plays merry hell with
economic systems." Horses and carts that shorten trips are fine. Avoid any warp. If the owner ever
wants something to shorten a trip, Bartle's model is that time passes and the journey happens off
screen. Record this as a design constraint (owner to confirm).

**A10. MEDIUM. Keep play classless and add career signposts ("kits").** *[Skills / journal /
onboarding]* P37 (p. 260), P39 (p. 263), P23 (p. 219), P17 (p. 193). The game is already
skills-based, which is what Bartle prefers. What it lacks is *direction* for players who "don't know
who they want to be". Add a journal page of village trades: what each trade does, the skills and
tools it needs, who in the village practises it, and how to start (approach the smith, the
tanner...). This offers paths without locking anyone in. The quest line "ask farmers, miners,
woodcutters or the reeve" already points this way.

**A11. MEDIUM. Make sure heirs feel like a new identity, not a continuation.** *[Life /
inheritance / player state]* P25 (p. 230), P29 (p. 236), P30 (p. 237), P38 (p. 261), P20 (p. 207).
Bartle: players grow when forced to restart, but they dread losing everything. The heir system is a
good compromise (property and family carry on, the person changes). Check: (a) What carries over
(skills? coins? reputation?) and is that intended? If heirs keep all skills, the family line becomes
a maxed-out character over generations, which permanent death is supposed to prevent (p. 261).
(b) `make_heir` resets `look` to "": does the new heir get the appearance picker and a chance to
rename or re-style, so that the start feels like "being someone new"? (c) Does the heir's situation
differ enough (a different age, home or trade) for development to begin again (p. 230)? Report the
findings. Changes are an **owner decision**.

**A12. LOW-MEDIUM. A planner's goal list.** *[Journal]* (p. 226 planners "decide what they want to do
then go off and do it"; P28.) Let the player pin goals they set themselves ("buy the forge", "100
coins by winter", "teach my son smithing") in the journal and tick them off. This needs no new rules.

**A13. MEDIUM (owner decision). A path to office for politician-type players.** *[Manor / reeve /
economy]* P55 (p. 306), P26 (p. 230), P19 (leadership third in stickiness, p. 205). The game already
has a reeve and a manor treasury with taxes, wages, granary and relief. That is the formal "leader
office ... responsible for setting local rates" Bartle describes. A later-life route in which the
player can be appointed (by standing, A1/A3) to a role with social and economic levers would serve
politicians and the "prove mastery" circle (p. 201). Following p. 230, the role's powers should be
over rates, relief and appointments, not over terrain or buildings by decree. It also fits the
owner's "same rules as NPCs" intent, since NPCs hold these roles now.

**A14. MEDIUM-HIGH. Treat building and business as the elder game.** *[Construction / property /
business]* P24 (p. 230), P66 (p. 316), P67 (p. 317). Bartle's best elder game is "tools to tinker with
the world or to enjoy one another's company." The game already has house and workshop building,
storefronts and shops with attendants. Check that late-game players can lay out and furnish
buildings freely, expand holdings and see their effect on the village. Use property condition (lived
in, maintained, run-down) as a visible indicator of how the village economy is doing: "if the area
... is run-down ... something is wrong."

**A15. MEDIUM (owner decision). Communal leisure at the tavern.** *[NPC schedules / tavern]*
P65 (p. 316), P57 (p. 310), P18. In the evening some villagers gather at the tavern. The player can
sit, drink ale, which produces Bartle's drunken "sh" speech filter for NPCs and the player, hear a
tale (lore snippets from Morris, labelled per CLAUDE.md) or music. This gives a relaxing place inside
the world that serves socializers and needs no gameplay reward. Ale already exists in the production
chain, so the drink has a real source.

**A16. LOW-MEDIUM. Non-verbal gestures towards villagers.** *[Dialogue / input]* (pp. 309-310), P13
(p. 187). A few one-tap gestures (greet, bow, thank, scold) that villagers react to and that feed A1.
On Android, social actions must be **one or two taps**. Bartle warns that phone players simply won't
type commands.

**A17. MEDIUM. Check the default context action on a villager.** *[Input / UI]* P1 (p. 157). On
touch, gamepad and keyboard, find out what the primary "interact" does when the target is a
villager: talk, trade, attack or steal. The default mode shapes the ethos. If the default is
combat-like, or theft is one mis-tap away, players drift into griefer play by accident. The default
should be *talk*, with theft and attack behind a deliberate second input. This is an approved check.

**A18. MEDIUM. Lockpicking and stealth: look for side routes.** *[Theft / lockpicking / stealth
skills]* P48 (p. 299). Bartle's own lockpicking example: if some locks cannot be picked, players will
pickpocket or steal the key instead, or rob the person who carries it. Audit the theft paths (picking
locks, house chests, stalls, taking from the inventories of sleeping or dead NPCs, loot left at doors
by `make_heir`) for routes that bypass intended limits. Check that each route has a consequence (seen
by a witness, fines, A3 reputation).

**A19. MEDIUM. Run the four types against every new feature (process).** *[Development process /
docs]* P12 (pp. 185-186), P4 (p. 170). Add a line to the feature checklist in
`docs/BUILD_DECISIONS.md` or the plan: "Which of achiever, explorer, socializer and killer (NPC
stand-in) does this help or hurt?" Bartle considers this the most useful day-to-day way to apply the
model. This is a documentation change and needs no mechanic approval.

**A20. MEDIUM. Weigh content against the pitch (deeds, not words).** *[Content balance / smithing]*
P11 (p. 185). Count the craftable item types by category: weapons and armour against domestic goods,
food, cloth, tools and medicine. The brief sells a *life sim*. If the smithing list is dominated by
weapons and armour while households have few goods to make, the content says "combat RPG". Report
the counts and keep domestic production broad.

**A21. MEDIUM. Bandits, wolves and theft: avoid constant vigilance.** *[Wildlife / bandits / guards]*
P68 (p. 318), P9 (p. 182), P62 (p. 312). Use NPC threats as the controllable stand-in for killers, so
tune them. Check that the village core is reliably safe (guards respond, predators rarely enter) and
that danger rises with distance or at night, so the player is not "on their guard the whole time".
Bandits drawn by the caravan are exactly Bartle's "plump wagon trains" (p. 306). Make sure that loss
to bandits can be recovered (as with sink, early losses drive newcomers away).

**A22. LOW. Name choice from Morris-flavoured name lists.** *[Character creation]* P31 (p. 240),
P50 (p. 301). Offer the player a short list of setting-appropriate names to pick from (or "random"),
alongside free entry. `PLAYER_HEIR_NAMES` in `life.gd` already holds medieval English names (Alys,
Hob, Maud, Piers...). Reuse that list, and the lore registry, rather than inventing a new one.

**A23. LOW. Unnamed villagers until introduced.** *[Dialogue / UI labels]* P32 (p. 242). Show unmet
villagers by role ("the tanner", "a stranger") until the first conversation reveals the name. The
`met` flag already exists. This makes the first conversation a small discovery that serves both
socializers and explorers. **Owner decision**, since Bartle notes that most games show names because
it is easier on newcomers.

**A24. LOW. Cosmetic choice from real materials.** *[Appearance / production chains]* P33 (p. 244),
P34 (p. 245). Clothing colour and style matter to socializers and cost little. Under the "nothing
from nowhere" rule, dyes could come from real inputs (flowers already exist). A matched set (for
example a full set of good armour) may carry a small real bonus, following Bartle's crimson-armour
example. **Owner decision.**

**A25. LOW. A memorial for the dead.** *[Life / village / family line]* (pp. 280-283), P45 (p. 291),
P20. Villagers and earlier player generations die permanently. A churchyard or memorial stones that
record the dead (names and epithets from A3) give the village and the family line a visible history.
It is the single-player version of Karyn's tree: a reminder that relationships with the people of
this world mattered.

**A26. HIGH (process). The owner and agents should play one full life from new game to heir.**
*[Testing / release readiness]* P40 (p. 272). Bartle's incognito advice comes down to playing as a
real player from beginning to (nominal) end to feel what it is like. Add one full-life playthrough
(start to death and succession to the heir) to the release-readiness checklist. The aim is to catch
drudgery (P6), empty stretches (P5) and late-game drift (P51), which unit tests cannot see.

**A27. MEDIUM. Handle the novel's thralldom with care.** *[World lore / content]* P41 (p. 278),
P42 (pp. 279-280). Morris's novel includes thralls and tyranny (Utterbol's lord and his thralls,
among others). If the game depicts such material, keep it within what a player of a cosy medieval
life sim "signed up for", or signal it clearly beforehand. Bartle notes that an ethical misjudgement
is remembered far longer than a bug. Flag this for the owner whenever lore content of that kind is
scheduled.

**A28. LOW. Treat the wiki as a jargon and term glossary.** *[Wiki]* P64 (p. 315). Record period
terms the game uses (reeve, pottage, chapman, carucate, and so on) in the wiki so players can look
them up. Bartle says acquiring the vocabulary makes players feel part of the place. Don't invent
jargon; record what the game and Morris actually use.

---

## 4. Warnings: what the book says commonly goes wrong that this game risks

1. **Socializer starvation leads to a world that is "all game" and silent drift.** Relationships are
   the stickiest facet (p. 205). Late-game players turn to people (p. 201). Players who don't
   complain simply drift away (p. 301). With only a "met" flag, the game risks becoming an
   achiever-only world, which Bartle's dynamics say is not stable in the long run (pp. 181, 188).
2. **Drudgery and empty travel.** "The drudgery never gets any more interesting" (p. 172). The
   living-world rule that every resource comes from a real source, together with an endless
   overworld, can turn into chores and long empty walks unless the density of interesting things
   and the burden of hauling are watched (A5, A8, carts).
3. **A component maze.** The dependency web (miners, smiths, carpenters, carts) is right in
   principle (p. 311), but it fails if a goal requires too many sources. The cart is Bartle's own
   example (p. 311).
4. **Fast travel destroying local economies** (p. 314). This is a direct risk to the stock-based and
   local-availability pricing and to the caravan.
5. **Newcomers lost in the first minutes:** a world that looks empty, no mentor, no "wow", too much
   UI at once, no "auto" button (pp. 192-193, 287, 301). It matters more on Android, where people
   abandon a game quickly.
6. **Phone input friction killing social play.** "People just can't be bothered to thumb in
   commands" (p. 187). Social actions need one tap.
7. **Telling players the wrong thing through content mix:** many weapon types and few domestic
   ones would say "combat game" in a life sim (p. 185).
8. **Over-explaining kills exploration:** an exhaustive numeric wiki or stat screens can remove the
   explorer's pleasure and break immersion for planners (pp. 230-231).
9. **Rules with side routes:** lock and theft limits can be dodged by other routes (p. 299).
10. **Constant threat:** bandits, predators and theft that keep the player always on guard drive
    people away (p. 318). Early losses feed sink.
11. **Fixed ideals and an anchored image:** if heirs inherit everything, including an unchangeable
    look, reputation or skills, the family line can lock the player into one identity (pp. 219,
    248). Skills carried down unchanged risk maxed-out characters despite permanent death (p. 261).
12. **Ethical content shock:** lore material such as thralldom placed where the player didn't expect
    it (pp. 278-280).
13. **Designers judging by their own taste instead of playing it fresh:** designers can't play for
    fun (p. 166). Listen to the reasons behind player opinions rather than the opinions themselves
    (pp. 164-166, 187). A full playthrough as a player is the corrective (p. 272).
14. **Forcing community:** groups or dependencies that make solo play impossible (p. 294, p. 312).
    The game must keep the self-sufficient path open (it does today, so preserve it).

---

## 5. Not applicable (briefly)

- **VR interfaces** (pp. 158-163) and textual **command modes** with leading characters (p. 157,
  table 2.1).
- **Live team versus dev team, message-board politics, community managers** (pp. 163-166, 284-286):
  there is no live service. The only transferable point is "playtest as a player" (A26).
- **Demographics and marketing, the newbie hose, churn figures for subscription games, the Bartle
  Test statistics** (pp. 168-169, 189-197): no subscriptions or population. The single-player
  equivalent is first-session retention (sink) and long-term drift, covered above.
- **Player-versus-player type dynamics as population numbers** (pp. 178-182): there is no
  population to balance. Only the qualitative lessons carry over (NPCs as stand-in killers, valuing
  explorers).
- **Anonymity between players, multiple accounts, mules, character slots per account**
  (pp. 233-238): not applicable. A remote equivalent is several save slots, so the player can try a
  different life without losing their main one (p. 237 suggests 3-5).
- **Name uniqueness and clashes across servers, vetting, impersonation** (pp. 238-240).
- **Masquerading and playing incognito among real players** (pp. 265-273), apart from the
  designer-playtest point.
- **Player rights, real-money ownership of virtual items** (pp. 274-280), apart from the content and
  ethics point (A27).
- **Beta-test seeding of community culture, server-wide community size management, guild tools,
  modular versus entwined guilds, chat channels, language barriers between players**
  (pp. 286-288, 302-311): the village is one community of about 70, well under the 150-250
  fragmentation threshold (p. 302). The single-player equivalents (NPC gossip, cross-linked trades,
  tavern evenings) are in section 3.
- **Reconnecting with a party after missing a session** (pp. 313-314): there is no party. Only the
  no-teleport economic point applies (A9).

---

## 6. For the future player-hosted multiplayer (3-4 players)

The owner has confirmed player-hosted co-op for about 3-4 players with no always-on server
(`docs/GAME_DESIGN.md` Confirmed 10; DECISIONS 2026-10-17). It is not built yet. Sections 1-5 cover
the current single-player game. The items below are Bartle's multiplayer advice as it applies to a
small, friends-only shared world. The group is small, real-life friends will often play together,
and the host's machine is the world, so the server-scale advice (population dynamics, newbie hoses,
vetting) still does not apply.

| # | Item | Value | System | Principle, quote, page |
|---|---|---|---|---|
| M1 | **Keep the world playable solo and in parallel.** No content should require all 3-4 players at once. Each player can follow their own trade, and group content stays optional. | HIGH | Quests / production / co-op design | "Players should be able to spend time on their own if they feel like it." (p. 294); explorers "probably won't want to have to hook up with six other people just to do the experimenting" (p. 294) |
| M2 | **Let the trade economy create soft dependencies between players.** One player mines, one smiths, one farms and cooks. Make it worthwhile to trade with a co-player, but never required. The single-player rule (a smith can dig their own ore) still holds. | HIGH | Economy / production chains | "Miners need blacksmiths to buy their iron, and blacksmiths need miners" (p. 311); "If blacksmiths want to dig their own iron ore, it should be possible" (p. 312); "the idea is to promote dependencies, not to enforce them" (p. 312) |
| M3 | **Make favours between players easy:** hand over items, lend tools, share a storage chest, gift coins, all with a tap. Small helpful acts matter more than formal systems. | HIGH | Inventory / chests / UI | "find ways to allow players to do each other favors" ... "Acts of kindness are the currency of friendships." (p. 312) |
| M4 | **Be cautious about player-versus-player harm (theft, assault, lockpicking a co-player's house).** In a group of 3-4 friends, one killer-type quickly drives out the others, and killers hit socializers hardest. Default to no harm between players, or a host-set option shown before joining. Keep NPC bandits and predators as the source of threat. | HIGH | Theft / combat / host settings | "More killers leads to ... Far fewer socializers" (p. 179); "Players can tolerate being inconveniently beaten up by mobiles more readily than they can by fellow players" (p. 182) |
| M5 | **No systems that reward betraying a co-player's trust** (for example, an easy steal from a partner's shared chest or stall). Make shared property permissioned. | HIGH | Property / chests / business | A system that let groups slaughter members "once they'd gained their trust" ... "People don't like having to be on their guard the whole time." (p. 318) |
| M6 | **Shared group property and goals:** a jointly owned house, workshop or stall with a shared chest, plus village-scale projects that need pooled effort (rebuild the mill, fill the granary). Shared goals are how a group becomes a "community of commitment". | MEDIUM-HIGH | Property / construction / manor | "Allowing groups to own property, keep archives, and institute a formal structure will encourage the development of communities of practice. Communities of commitment will arise if groups are afforded goals" (p. 294) |
| M7 | **Order the stress.** Give a new group small shared dangers first. Keep the harshest events (raids, famine, a bear at the door) for later in a save. Don't open a co-op world with a crisis. | MEDIUM | Events / difficulty / fauna | "Use smaller conflicts as filters so that the riskiest situations are only available for those groups mature enough to handle them." (p. 294) |
| M8 | **Rejoining without teleporting.** When a friend joins a running world, place them sensibly: at their home, or with a "travel to the host" option that costs game time. Never use free warps, which break local-availability pricing. Decide what a guest's character does while that player is offline: stays home, keeps working, or sleeps. | HIGH | Networking / overworld / economy | "if characters can appear anywhere at a moment's notice it makes everywhere local to everywhere else; this plays merry hell with economic systems." (p. 314); "When you're not playing, your character is still active." (p. 314) |
| M9 | **Mixed ability.** A friend joining the host's advanced world as a fresh character needs a useful role at once (an apprentice to a co-player, or easy paid work) so the gap does not shut them out. The host player becomes the greeter or mentor, which is Hedron's "prove mastery" circle. | MEDIUM | Onboarding / skills / quests | "providing mixed-ability content for them is awkward" (p. 305); "demonstrate this to other players ... by helping/mentoring/leading" (p. 201); greeter aims (p. 289) |
| M10 | **Non-verbal communication for touch and gamepad players:** emotes, pings and quick phrases, because Android players won't type. Optional text chat on PC. Small speech filters (drunk "sh") as fun extras. | HIGH | UI / input / networking | "people just can't be bothered to thumb in commands" (p. 187); "provide substitutes that allow for players to articulate themselves without using words" (p. 310); drunk "sh" (p. 310) |
| M11 | **Shared events and leisure:** tavern evenings, music and storytelling that several players can attend together with no gameplay reward needed. | MEDIUM | Tavern / NPC schedules | "They're communal activities that serve no gameplay purpose ... They're popular because they bring people together." (p. 316) |
| M12 | **Make the world the shielding context for friends.** Friends who know each other in real life tend not to role-play. Give each player their own identity tools (chosen name, look, epithets and life record from §3 A3) so they can be someone else within the group. | MEDIUM | Character creation / profiling | Friends in one room were "subject to the same peer pressure as in the real one ... They're constrained." (p. 250); "They need permission to role-play." (p. 250) |
| M13 | **Per-player profiling and shared news.** The village record and NPC gossip (§3 A2, A3) should name which player did what, so co-players see each other's deeds ("Hob built the new forge"). Auto-generated news gives the group a shared history. | MEDIUM | Journal / dialogue | "the server could automatically generate a newsflash ... to inform everyone what's happened" (p. 249); "The community has a history." (p. 291) |
| M14 | **Market domination by one player.** Real coins and limited merchant funds mean one player can buy up stock and squeeze the others, which is the "politicking" form of killing. Watch for it. Consider NPC behaviour that dampens cornering (merchants restock, a caravan brings in supply). | MEDIUM | Economy / merchants / caravan | Killers "dominate others ... it also can manifest in less overt fashion, such as politicking" (p. 174); "Dependencies that are threatened can give cause for conflict." (p. 312) |
| M15 | **The host's code of conduct is stated in-game.** The host has their "finger on the power button". Show the host's rule settings (PvP harm, theft, who can build where, what happens to an absent player's goods) on the join screen, and apply them to everyone equally. | MEDIUM | Host settings / UI | "Ultimately, someone has their finger on the power button." / "Codes of conduct should be fair and should be applied fairly." (pp. 275-276) |
| M16 | **Names and identity within one save:** names unique within a world, including players versus villagers, so dialogue and the record are never ambiguous. Each player can also make private notes on co-players and villagers. | LOW-MEDIUM | Character creation / journal | "disallowing name clashes ... is essentially a customer relations requirement" (p. 239); "Why not allow players to annotate one another?" (p. 243) |
| M17 | **Permanent death and heirs in co-op.** Losing a character permanently while friends carry on is the "great tragedy of persona death" in sharp form. Decide how a dead player's heir re-enters the shared world (immediately, with their inheritance) so nobody sits out a session. | HIGH | Life / inheritance / networking | "if they knew that characters could die dead-dead after months of playing time, players perhaps wouldn't sign up" (p. 236); "This is the great tragedy of persona death in virtual worlds" (p. 236) |
| M18 | **Check co-op features against the player types** (process): ask of each multiplayer feature whether it lets one type (usually a killer) spoil play for the others in a group this small. | MEDIUM | Development process | "When you add new functionality, it's useful to run through the player types to be sure it doesn't help or hurt any of them too much" (pp. 185-186) |

Multiplayer advice that still does not apply at 3-4 players: population-level type dynamics and
stable states (pp. 178-182), community size and partition theory for thousands (pp. 302-308), beta
seeding (pp. 286-288), name vetting and server-wide uniqueness (pp. 238-241), masquerading as
another real person (pp. 265-271), and channel systems by topic or group (p. 309). Between friends,
voice or the platform's own chat will do.
