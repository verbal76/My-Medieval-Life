# Notes on Bartle, *Designing Virtual Worlds*, Part A (Ch. 1–2)

Source: `part_A.txt`, read in full (file lines 1–6289). Page numbers are the book's printed page
numbers. **Coverage note:** the file ends at p.156, partway through the "Modes" subsection of
Ch. 2's "Theory and Practice". The brief says the file covers pp.1–166, but pp.157–166 (the rest of
"Theory and Practice") are **not in this file** and are not covered here.

Lens: My Medieval Life is single-player. Where Bartle means "other players", these notes read
"NPC villagers" when the point carries over, and mark it not applicable when it doesn't.

---

## 1. Chapter-by-chapter summary

### Preface (unnumbered)
Most virtual-world design copies earlier designs without knowing why those decisions were made, so
designers can't tell whether the original reasons still hold. "Are designers even aware that there
are decisions they can unmake?"

### Chapter 1: Introduction to Virtual Worlds (pp.1–108)

- **Definitions (pp.1–5).** A virtual world is "that which isn't, having the form or effect of that
  which is". It has five conventions: automated rules the player cannot change (*physics*); one
  *character* per player; real-time feedback; sharing between players; *persistence*, meaning the
  world keeps developing when nobody is interacting with it. Bartle says plainly that a
  single-player game is not shared (p.5). For this game the NPCs take the place of the other
  inhabitants.
- **History, First to Fifth Ages (pp.5–43).** MUD1 split the engine from the world-definition
  language (MUDDL) so that many worlds could run on one engine (p.6). Later, codebases spread
  without their reasons (p.11, pp.16–17). Ultima Online (pp.28–31) was innovative, but "the detailed
  ecological model employed broke down when players rapidly killed everything that moved" and its
  economy hyper-inflated after a bug (p.30). Meridian 59 (pp.31–34) had a bug that made its currency
  worthless overnight; it also had "insufficient content. The world felt very small" (p.33).
  EverQuest kept players because of the people they met (p.36). Asheron's Call added a monthly
  *story arc* that added and removed structures to tell a narrative (p.37). Asheron's Call 2 watered
  down death and the economy, and that "reduces the challenge" (p.42).
- **The Past Affects the Future, Missed Opportunities (pp.43–46).** Mostly industry history.
  Sierra's management resisted permanent character death (p.46).
- **Theory and Practice; Whither Innovation (pp.47–51).** History explains *why* things were done.
  A world cannot be designed in modules: "Every component affects every other", and it is judged as
  a whole, not by its best parts (p.48). Question basic assumptions: ask whether to have classes at
  all, not which classes (p.47). Text worlds are cheaper to experiment with (p.49).
- **The Basics: Appearance, Genre, Codebase (pp.51–65).** Newcomers care about appearance more
  than experienced players do (p.52). Genre matters less to design than people think, but some
  genres break. Comedy doesn't survive repetition (p.55). Lone heroes don't fit a world with many
  players (p.56). Licences constrain designers through canon (pp.56–58). A server has four layers:
  driver, *mudlib* (physics), world model, and instantiation (pp.59–60). They can be hard-coded,
  scripted or held as data. A *template database* changes a denizen's behaviour without changing
  code (p.61). Code-heavy engines suit intense action; scripted ones suit creativity (p.63).
- **Age and Player Base (pp.65–73).** Survival over time is the measure of a design's success
  (p.67). There are several ways to measure a player base. Design for *why* people play, not for
  demographics, with "checks and balances" so that no single play style overwhelms the others
  (p.72).
- **Dimensions: Change and Persistence (pp.73–83).** *Content* is "what they consume" (p.74):
  things to do, places to do them, and things to do them to. Other people are intangible content;
  the environment is tangible content (pp.74–75). Change can come *in context* ("a nobleman hires a
  gang of workers to build a castle") or through out-of-world *building* (p.76). Persistence means
  how much state survives a restart. Designers sometimes avoid full persistence because one-shot
  puzzles can't be reset: "you can't unlaunch a rocket" (pp.77–78). A grid of who may change the
  world against how much of it persists answers "Whose world is it?" (pp.78–83). In the top-right
  quadrant, players have a stake through "in-context actions that have lasting effects" (p.81).
- **Influences: Printed Works, Film and TV (pp.83–96).** Tolkien showed that one person could build
  a believable world (pp.84–85). Works adapted into worlds can be direct, partial or indirect
  (pp.85–86). From *Otherland* (pp.89–90): immersion is not visualization, and a world that "looks
  and behaves like reality" immerses. Meeting players' expectations of realism increases immersion;
  denying them decreases it. The holodeck (pp.93–95) separates *undirected* environments (a bar to
  hang out in) from *directed* ones (a scripted holonovel). Books tell and films show (pp.92–96).
- **Role-Playing Games and LARP (pp.97–104).** RPG rulebooks map onto the four server layers
  (p.98), and genre sourcebooks save research time. A computer referee is literal: "the squid picks
  up the sword" (p.100). Several things don't transfer to a computer referee (p.101): subjective
  judgements (alignment: is attacking a thief good?); individualism; overdone theory (going "too
  far … in creating believable non-player characters" or putting plotting over atmosphere); and
  meta-interaction. LARP shows that content nobody visits is wasted. In a virtual world, players
  "will nevertheless visit it in time" (p.103).
- **Other Influences; The Designer (pp.104–108).** The player base influences design most. Listen
  to players, but few of them understand design (p.105). Ideas are options, not a menu: "Italian
  cuisine does not call for pistachio ice cream to be added to spaghetti bolognaise" (p.107). The
  worlds people remember are the ones that are different (p.107).

### Chapter 2: How to Make Virtual Worlds (pp.109–156 in this file)

- **Development and the Team (pp.110–115).** Design mistakes cost the most because their effects
  spread everywhere. Example: shopkeepers with fixed prices under inflation or deflation (p.111).
  Asheron's Call players had to barter for months after its currency became worthless (p.111).
  Designers must know what the other disciplines can't do (p.112). Programmers should not "ad lib
  features of their own" (p.114, fn.2).
- **The Development Process (pp.115–125).** Pre-production produces a visualization document (a few
  pages: mission, philosophy, goals, main features, look and feel), a design document, a technical
  review, an art bible, a schedule and risk assessment, and prototypes (pp.116–118). Production
  builds tools first, *including analysis tools* to see what is happening "without having to ask"
  (pp.119–120). In roll-out, designers "run data through models" before release (p.121); outside
  reviewers are worth paying for (p.121); beta starts as early as possible to find exploits (p.123).
  Launch goals are a seeded community, a primed market, balance, and no bugs, and "All but the last
  of these are possible" (p.124). In operation, "the work only really begins" (p.125).
- **Architecture, Server, Load Balancing (pp.126–138).** Front ends, user database, shards, zones
  and seamless worlds. Zone boundaries change tactics (monsters can't follow across them) and cause
  flash crowds (pp.136–138). World design can spread the load: Dark Age of Camelot's realms (p.138).
- **Other Things Happen (pp.138–140).** Mobiles (NPCs and creatures) cost AI time. The usual fix is
  *proximity activation*, but it breaks causality. A goblin raid on sheep, which the villagers then
  pay to avenge, "would never happen if the goblins stayed in their camp until a player happened
  upon them". "Virtual world design is about consequences" (p.140).
- **Client/Server: Synchronization (pp.140–146).** Lag rules out twitch play. Timed windows need at
  least about 4 seconds, and commands must use absolute positions (pp.142–145). Mostly
  multiplayer-specific.
- **Security (pp.146–154).** Never let the client decide anything (p.147). Repetitive actions get
  automated, and wanting to automate something signals that it is "intrinsically uninteresting"
  (pp.148–149). The advice: do long jobs as background tasks, and put obstacles in exploration so
  brute force fails (pp.148–149). Data the client is sent will be read, so either keep it from
  mattering or give it to players officially (pp.150–151). The design itself can be an exploit:
  local supply-and-demand pricing with a high buy-back on scarce goods gives a money engine (the
  diamond example, pp.151–152). Bartle found the same exploit in a *single-player* trading game, The
  Patrician (p.152, fn.42). The rule is to log everything, which settled false death claims "at a
  stroke" (p.153), and to always be able to recover damaged data (p.154).
- **Theory and Practice: Modes (pp.154–156, truncated).** "Defaults set the tone … because all
  newbies play under them" (p.155). If command mode is the default, the world tells the player "you
  can do things"; if conversation mode is the default, it tells them "you can communicate" (p.156).
  *The file ends here.*

---

## 2. Principles that apply to this game

| # | Principle | Quote (verbatim) | Page |
|---|---|---|---|
| P1 | The world is one interdependent system; judge it as a whole | "Each one can't really be modularized: Every component affects every other." | 48 |
| P2 | Rich simulations collapse under player behaviour | "the detailed ecological model employed broke down when players rapidly killed everything that moved" | 30 |
| P3 | Currency bugs destroy economies | "one particular showstopping bug rendered the in-game currency completely worthless overnight." | 32 |
| P4 | Price models are where design failures do the most damage | "non-player shopkeepers sell goods at fixed prices. What happens if there is inflation in this virtual economy?" | 111 |
| P5 | The design itself can be an exploit | "Your design has given them an engine for generating however much money they like!" | 152 |
| P6 | Proximity activation breaks causality | "It's an evening's quest that would never happen if the goblins stayed in their camp until a player happened upon them." | 140 |
| P7 | Design is about consequences | "Virtual world design is about consequences." | 140 |
| P8 | Content is what the player consumes | "content in virtual worlds generally means giving people things to do, places to do it, and things to do it to." | 74 |
| P9 | In-context change (inside the fiction) beats out-of-world building | "within the context of the virtual world (for example, a nobleman hires a gang of workers to build a castle)" | 76 |
| P10 | Lasting in-context change gives the player a stake | "Players can make changes through in-context actions that have lasting effects." | 81 |
| P11 | One-shot world changes can't be reset | "you can't unlaunch a rocket or unexplode a bomb." | 77 |
| P12 | Realistic behaviour, not visuals, creates immersion | "Cyberpunk mistook visualization for immersion: The two are not the same." | 90 |
| P13 | Meet expectations of realism | "Fulfilling these expectations leads to increased immersion and denying it leads to decreased immersion." | 90 |
| P14 | The computer referee applies rules literally and evenly | "If a squid picks up a sword in a computer-moderated world, well, the squid picks up the sword." | 100 |
| P15 | Computers can't make subjective (moral) judgements | "Human beings can make value judgments, but computers are hopeless at it." | 101 |
| P16 | Don't overbuild NPC believability or put plot ahead of atmosphere | "go too far (for example, in creating believable non-player characters) or emphasize the wrong thing (for example, plotting over atmosphere)." | 101 |
| P17 | Undirected and directed environments are different things | "They distinguish between undirected and directed environments." | 94 |
| P18 | Repetition wears out | "You laugh the first time something funny happens, but by the tenth time that same thing happens, it ceases to amuse you." | 55 |
| P19 | Balance play styles | "checks and balances within the virtual world itself to ensure that no one playing style can come to overwhelm the others." | 72 |
| P20 | Wanting to automate something means it's tedious | "consider the possibility that it could be intrinsically uninteresting." | 149 |
| P21 | Avoid grinding repetition; push long tasks into the background | "If you really want an action to take a lot of time, let characters do it as a background task" | 148 |
| P22 | Build analysis tools | "build some analysis tools, too, so that once the world is running it will be possible to determine what the players, the software, and the hardware are doing" | 119–120 |
| P23 | Simulate before players do | "designers will run data through models to ensure that what they think will happen has a good chance of being what will happen" | 121 |
| P24 | Log, and be able to recover | "an incomplete ability to recover damaged data is incompetent." | 154 |
| P25 | Log everything | "If possible, log everything." | 153 |
| P26 | Defaults set the tone | "Defaults set the tone of virtual worlds, because all newbies play under them." | 155 |
| P27 | The default action tells the player what the world is about | "the message that the world is sending them is that this is a place where you can do things" | 156 |
| P28 | Thin content makes a world feel small | "It had insufficient content. The world felt very small" | 33 |
| P29 | Watering down hardship removes the challenge | "diluting anything inconvenient (character "death," the economy) may have backfired—it reduces the challenge somewhat." | 42 |
| P30 | Implementers shouldn't invent features | "It's particularly important that programmers don't feel that they can ad lib features of their own." | 114 fn.2 |
| P31 | Question inherited assumptions | "rather than "should we have character classes in our new game at all?"" | 47 |
| P32 | Unpredictability cuts both ways | "if you want the unpredictable, you can't complain when you get it." | 154 |
| P33 | Data-driven templates let you tune without code | "change the behavior of one of the virtual world's denizens by tinkering with the template ... you don't have to change/recompile any code." | 61 |
| P34 | Get outside review | "the opinions of knowledgeable people from outside the team who haven't been living and breathing it for two years are worth having" | 121 |

---

## 3. Actionable items for My Medieval Life

Code checks were spot reads of the repo (`/home/user/My-Medieval-Life`), not a full audit. Each
item cites the principle and page it follows from. Any item that adds or changes a gameplay
mechanic needs the owner's approval (CLAUDE.md §11), and that is marked where it applies.

### HIGH

1. **Check the buy-low/sell-high money pump in the pricing model.** System: Economy and trading
   skill. From P5, pp.151–152. Bartle's diamond exploit is a scarcity-based buy-back price, and he
   found it in a single-player trading game.
   - The numbers, from `game/scripts/core/world.gd:601-610` and `game/data/balance.json`:
     - A seller's lowest asking price is `price_min + 0.2` = 0.8 × value.
     - A buyer with empty stock pays 1.2 × `sell_ratio` (0.6) = 0.72 × value.
     - Trading skill multiplies buy prices by (1 − bonus) and sell prices by (1 + bonus).
   - At Trading 10 (bonus 0.20): buy at 0.64 × value, sell at 0.864 × value, about 35% profit per
     cycle.
   - At bonus 0.08 (Trading 4): 0.736 against 0.778, already profitable. At bonus 0.05 it breaks
     even.
   - So a player can buy from a well-stocked seller in a crowded market and sell to an NPC that
     holds none.
   - Limited merchant purses bound the pump: it moves real coins and does not mint them. Even so, it
     is a repeatable drain on merchants that the owner may not want.
   - **Action:** add a test that, for every tradeable item and every Trading level, the cheapest
     possible player buy is above the dearest possible player sell. Or decide that this arbitrage is
     intended "trading" play and record that. It does not apply if NPC buyers never buy items that
     merchants stock; the `BUYS` lists must be checked.
2. **Long headless "run data through models" simulation (P23 p.121, P2 p.30, P3 p.32).** System:
   Whole simulation and testing. Run the village for many game years with no player and with a
   scripted aggressive player who hunts everything, hoards coins, and buys out the granary. Assert:
   - no species goes extinct within reach;
   - coins are conserved (`World.total_coins()` changes only by `coin_sources` and the sinks);
   - no household starves while there is food in the village;
   - no price stays pinned at the clamp;
   - the population stays within bounds.

   UO's ecology and economy both collapsed under real player behaviour, not designer behaviour.
3. **Overhunting safeguard for wildlife (P2 p.30, P10 p.81).** System: Fauna and hunting. Fauna
   only breed (`fauna.gd:384`). I found no extinction or immigration handling. If the player kills
   every adult of one sex, a species disappears from the area for good. Decide whether that is an
   intended lasting consequence or needs an *in-world* source, such as animals wandering in from the
   endless overworld, which keeps the "nothing comes from nowhere" rule. This is a mechanic change,
   so it needs owner approval.
4. **No proximity activation that breaks causality (P6 p.140).** Systems: NPC AI, bandits,
   predators, quests. Check that bandit poaching, predator raids on pens, and NPC needs keep
   happening when the player is far away (in the overworld), or are resolved by a faithful
   catch-up. Quests "from villagers' real needs" depend on those events happening unwatched. If
   off-screen agents are put to sleep for phone performance, simulate them coarsely rather than not
   at all, and document it in the system interaction manifest. This also respects Bartle's point
   that load comes from *active* mobiles (p.139).
5. **Analysis tools and an event log (P22 pp.119–120, P25 p.153).** Systems: Debug, telemetry,
   saves. The world already keeps `log_lines` and `coin_sources`. Add a debug-only recorder covering:
   - price and stock history for each item;
   - coin distribution (player, treasury, merchants, households);
   - deaths by cause;
   - species counts;
   - jobs filled and unfilled.

   That lets balance be judged "without having to ask". For permadeath especially, keep a
   player-visible cause-of-death record. Bartle's "log everything" ended disputed deaths "at a
   stroke" (p.153). Here it gives the player trust that a death was fair and gives testers evidence
   for bug reports.

### MEDIUM

6. **Make the crime rules use observable facts, not judgements (P15 p.101).** System: Theft,
   guards, fines. Bartle's chain of stolen goods passing through a fence is exactly the kind of case
   a computer can't judge. Write the rule down: what a guard knows (witnessed act, item ownership
   tags), whether stolen goods stay marked through resale, and what happens when the player buys
   stolen goods in good faith from an NPC or a bandit.
7. **Find and remove grinds the player would want to automate (P20 p.149, P21 p.148).** Systems:
   Mining, woodcutting, crafting, farming input. List every action that takes many identical taps,
   which matters more on a touch screen: chopping (axe blows per tree), repeated crafting of the
   same item, and walking back and forth for deliveries. Give each one a queue or batch option, or
   route it through the game's existing hired attendants and helpers as a "background task". Planned
   carts and deliveries are a natural fit.
8. **Rotating save backups (P24 p.154).** System: Saves. `save_store.gd` keeps one `.bak`, which is
   overwritten on every save. A bug that corrupts world state, or a permadeath caused by a bug, can
   be saved over both copies. Keep several dated generations (for example, the last 3 days and the
   last 3 sessions) so a save can always be rolled back. Recovery from a bad state must "absolutely
   always be available".
9. **Audit first-session defaults (P26 p.155, P27 p.156).** Systems: UI, input, onboarding. On
   Android, the default tap on an NPC (talk, trade, or act) and the default notification and wiki
   pop-up density tell the player what the game is "about". Decide on purpose that the default
   should say "you can do things in a living village". Check the touch, gamepad, and
   keyboard-and-mouse defaults separately.
10. **Watch for repeated NPC lines (P18 p.55).** System: NPC dialogue and notes. Comedy and stock
    phrases wear out with repetition. Count how often each bark or note line appears per game day
    in a long sim (ties to item 5), and vary or rate-limit the most frequent ones.
11. **In-context change must persist and be visible (P9 p.76, P10 p.81).** Systems: Construction,
    property, overworld. Every lasting player change should survive save and load and be visible
    in the world: buildings the player had built by paying real workers, felled overworld trees,
    and emptied deposits. The game is designer-owned with the player holding a stake, which is
    Bartle's top-right quadrant. Add a round-trip test for each kind of change.
12. **Don't water down death or the economy to remove friction (P29 p.42).** Systems: Permadeath
    and heirs, economy. Asheron's Call 2 lost challenge by softening "death" and the economy. When
    testers complain about losses (theft, fines, scarcity, death), prefer making the cause clearer
    (items 5 and 6) over removing the consequence. Record this as a design guideline for owner
    approval.
13. **Keep the plot from overriding the living world (P16 p.101, P17 p.94).** Systems: Quests,
    Morris lore. The village is an undirected environment. Morris-based story content, if added,
    is directed. Keep scripted lore from overriding simulation rules, and let atmosphere (the
    Morris setting) come first. Don't over-invest in NPC dialogue depth at the cost of NPC
    behaviour, since believable behaviour is what immerses (P12, P13, p.90).

### LOW

14. **Write a one-page visualization document (pp.116–117).** System: Docs. Cover the mission,
    philosophy, goals, main features, and look and feel. `GAME_DESIGN.md` is still largely
    undecided. Bartle produces this first, and it would give agents one statement of tone to check
    against. Owner-authored or owner-approved.
15. **Guard against agents improvising features (P30 p.114).** System: Process. This repeats
    CLAUDE.md §11, and Bartle's footnote supports it. Keep requiring that every new mechanic be an
    owner-approved entry in `DECISIONS.md`.
16. **Keep tuning in data (P33 p.61).** System: Data. This is already the pattern (`balance.json`,
    `resources.json`). Keep new NPC and economy knobs in JSON templates rather than in code, so the
    long-run sim (item 2) can sweep them.
17. **Check that content is dense enough (P28 p.33, P8 p.74).** Systems: Overworld generation,
    content. An endless procedural overworld can still "feel very small" if it offers nothing to do.
    Measure points of interest (resources, wildlife, encounters, landmarks) per screen of overworld
    and set a minimum.

---

## 4. Warnings: common failures the game risks

- **Ecology collapse from player predation** (UO, p.30). Breeding-only fauna plus a hunting player
  can lead to local extinction (item 3).
- **Hyper-inflation or a worthless currency from one bug** (UO p.30, M59 p.32, AC p.111). There are
  many coin-moving systems: wages, taxes, relief, caravan, stall attendants, quest reserves,
  inheritance, loot. Any one leak breaks the "real coins" promise (item 2).
- **A dynamic-pricing exploit** (diamond example, pp.151–152). See item 1. Bulk buying is already
  priced unit by unit (Build 13 rule), which closes Bartle's exact case, but buying and selling
  across *different* NPCs is still open.
- **Proximity activation** silently removing the causes of quests and events (p.140).
- **Fixed-price thinking** (p.111). Any item still priced only by `GameData.value` with no stock
  feedback (for example `animal_price`, `seed_price`, `land_price`) should be checked against
  inflation and deflation in long runs.
- **Repetitive actions** that players would want to macro (UO crafting, p.148). This is worse with
  touch input.
- **Losing the ability to recover a damaged save** (p.154). Only one backup generation exists.
- **Thin content in a large space** (M59 "felt very small", p.33) for the endless overworld.
- **Softening hardship until the challenge is gone** (AC2, p.42) when tester feedback pushes against
  permadeath or theft.
- **Copying inherited conventions without knowing why** (Preface; pp.17, 47–48). For example:
  respawning resources, fixed shop prices, class systems. The game already rejects several of these.
  Keep asking "should we have this at all?"
- **Plot or lore overriding atmosphere and simulation** (p.101).

---

## 5. Not applicable (skipped)

These were read with single-player in mind. Section 6 brings back the network, security and
persistence items for the confirmed player-hosted co-op.

- **Industry history, business and markets** (pp.5–47): subscription models, AOL royalties,
  publishers, cancelled licences, subscriber benchmarks, beta-tester counts. Kept only the design
  lessons.
- **Measuring a player base** (pp.67–71): registered players, simultaneous players, player-hours.
- **Demographics for marketing** (pp.71–73), except the "balance play styles" point.
- **Licensing** (pp.56–58): the Morris novel is public domain, and the canon rules are already
  handled in `docs/world/`.
- **Codebase families** (pp.58–65) beyond the layering and template-data idea.
- **Team structure and live team** (pp.111–115, 124–125): customer service, operations, and the
  live-team staffing ratio.
- **Server architecture, shards, user database, front ends, load balancing, zones, flash crowds**
  (pp.126–138), except the AI-load point.
- **Network synchronization and lag** (pp.142–146): the 4-second timing window, prediction and
  warping, absolute against relative coordinates. These are network issues. Single-player touch
  input has no network lag.
- **Client security and hacked clients** (pp.146–151): no client/server split, and editing a
  single-player save only affects the player. The design-level exploit point (pp.151–152) is kept.
- **Character theft and the name problem** (pp.152–153).
- **Builder privileges and player-created content** (pp.76–83): the player changes the world only
  in context.
- **Command against conversation mode as text input** (p.156): kept only as the general point about
  what the default action signals.

---

## 6. For the future player-hosted multiplayer (3–4 players)

The owner has confirmed player-hosted worlds for about 3–4 players, with no always-on server and a
world that stops when the host stops (`docs/GAME_DESIGN.md` Confirmed 10; `docs/DECISIONS.md`
2026-10-17). It is not built yet. This section rereads the parts of Ch. 1–2 that section 5 marked
not applicable, read for a small co-op world. In that world the host's game acts as Bartle's
"server" and the guests' games act as "clients". Items marked *decision* need the owner (new
mechanics or network features, CLAUDE.md §11). Items marked *now* are cheap to prepare while the
game is still single-player.

### HIGH

- **MP1. The host decides everything; guests only send requests (*now*: keep the simulation
  separate from the view).** Systems: architecture, World/core. pp.140–141, 147.
  > "Absolutely no decisions with regard to what happens in a virtual world can be delegated to a
  > client." (p.147)

  - Trades, hits, theft, prices, harvests and quest rewards must all be computed by the host's
    `World`. A guest sends only intents ("buy 3 bread from X").
  - Otherwise the "real coins, real sources" rule cannot hold. Bartle's warning is "groups of
    players giving themselves money and spending it in inflation-causing amounts" (p.148).
  - *Now:* keep every rule in `game/scripts/core/` and none in `view/`, `ui/` or `main.gd`. Then the
    host can run the same `World` and guests can be thin views. Bartle: "The server embodies the
    virtual world; the client translates it" (p.140).
  - Audit `main.gd` (151 KB) for game rules sitting in the UI layer.
- **MP2. Check every guest message, and never crash on bad input.** Systems: networking, saves.
  p.147.
  > "all packets sent from the client to the server have to be checked to see if they make sense."
  > (p.147)

  Even among friends, a modified or out-of-date guest build must not be able to crash the host or
  corrupt the host's save. Malformed or impossible requests (an item not owned, a target out of
  reach) get rejected and logged. Version-check guests on join.
- **MP3. Nothing may depend on reflexes, because guests lag and the host doesn't.** Systems:
  combat (wolves, bears, bandits, the planned skeletons), hunting, stealth, lockpicking. pp.142–145.
  > "the window for success needs to be at least four seconds in duration or some players are going
  > to miss it while believing they hit it." (p.143)

  - The host plays with no lag, so any timing-based fight or minigame favours the host. Let the
    *character's* skill decide outcomes, not the player's reflexes (p.143).
  - Smooth corrections instead of letting things jump ("warping", pp.144–145).
  - Use absolute positions in messages (p.145).
  - For ranged attacks, decide between "shoot at a target" and "shoot at a location" (p.145).
  - Even at a 200–300 ms connection a guest should never feel cheated.
- **MP4. Decide what happens to a guest's character, house and goods while the guest is away
  (*decision*).** Systems: life/needs, property, saves, inheritance. pp.5, 62, 77, 90, 131.
  - Bartle's persistence ladder runs from "initial state and the records for individual player
    characters" up to "entire world state" (p.77). Character data is "stowed in a database while
    the player is not present" (p.62).
  - In this game the player lives under the NPCs' rules, so an absent guest's character would
    starve, lose a job or be robbed unless a rule says otherwise. Options:
    1. the character leaves the world ("travelling") and returns with the guest;
    2. the AI runs the character as an NPC;
    3. the character stays and is exposed to the rules.
  - Also decide where guest data lives (the host's save, the guest's device, or both).
  - Decide whether a character may move between different hosts' worlds. Moving characters and
    objects between worlds needs mapping rules (*Otherland*, p.90; character transfer, p.131
    fn.20). If carried coins and goods come from another world, that breaks "nothing comes from
    nowhere" and is a duplication route.
  - Recommendation: keep characters per world, stored in the host's save. Keep a separate
    *player identity* ("servers deal with characters rather than players", p.129), which also fits
    the heir and family-line system.
- **MP5. Exploits get worse with several players.** System: economy. pp.151–152.
  > "Exploits—design bugs—can ruin a virtual world overnight." (p.152)

  - The cross-NPC money pump in section 3, item 1 gets easier when one player buys out a well-stocked
    seller while another sells to an empty buyer. Players can also run a stall and play the
    economy against each other.
  - Merchants' limited purses become a shared, contested resource.
  - Extend the long-run simulation (section 3, item 2) with 3–4 scripted players working together.
- **MP6. Scale content to four players.** Systems: quests, jobs, property, resource nodes,
  wildlife. pp.74–76.
  > "MUD1, however, is scaled just right for the number of players it attracts." (p.75)

  - Four players use up content four times as fast. Quests come from ~70 villagers' needs; there
    are a fixed number of job posts and plots for sale, and finite deposits and game animals.
  - Measure each of these per player in a simulated 4-player run.
  - Decide whether supply scales with the number of players (via in-world sources only) or stays
    fixed, which makes scarcity part of co-op play (*decision*).
  - The overhunting risk (section 3, item 3) multiplies by four.

### MEDIUM

- **MP7. Only send a guest what the character could know.** Systems: stealth, theft, lockpicking,
  night, chests. pp.150–151.
  > "no items of data are sent to the client that convey any information beyond what the player's
  > character is entitled to know." (pp.150–151)

  - Guest builds will hold whatever is synced to them: NPC inventories, chest contents, guard
    routes. Either don't send hidden data, or "give that information to them officially and be sure
    it's never of much use" (p.151).
  - Night darkness drawn on the guest's device is not concealment. UO players beat it by turning up
    gamma (p.150). Base stealth and detection on the host's light level, not on what the guest
    sees.
- **MP8. Keep all players' needs simulated, wherever they are.** Systems: NPC AI, overworld
  generation, performance. pp.136–140.
  - With players spread across the endless overworld, there are several active regions at once.
    AI load comes from active mobiles (p.139). Proximity activation breaks causality (p.140).
  - Decide how many active overworld regions a mid-range *phone host* can run. Consider world
    design that keeps players near each other, as Dark Age of Camelot's realms did:
    > "Players of EQ notice how the sub-servers take responsibility for zones, but players of DAoC
    > don't. Why not? Because of the latter game's world design." (p.138)
  - If the village and overworld are separate areas, animals and bandits that can't cross the
    boundary change tactics (p.137). That matters more when two players are on opposite sides.
- **MP9. Design for the weakest platform.** Systems: input, UI, performance. pp.41, 128.
  > "how this affects the design of the world itself depends on the nature of the lowest common
  > denominator of those platforms" (p.41)

  - Android and PC players in one world: every interaction must work by touch, and the host
    budget must fit a phone.
  - Keep one protocol for all platforms. Clients "will all present the same interface, so the
    virtual world neither knows nor cares what operating system they're running under" (p.128).
- **MP10. Settle who may change what in the host's world (*decision*).** Systems: property,
  construction, theft, felling, building. pp.74, 80–82.
  > "Whose world is it?" (p.74)

  - Decide what a guest may permanently change on the host's map: fell trees, build, buy land,
    steal from the host's household or from other players' chests.
  - Decide whether one player's crimes bring fines and guard attention for everyone.
  - Bartle's grid ties how many people may change the world to how much of it persists (p.80).
    Write the guest permissions down before building multiplayer.
- **MP11. Give players reasons to stick together.** Systems: production chains, households, quests.
  p.36.
  > "they continued to play because of the other people they had met there. EQ was constructed to
  > encourage players to form small groups" (p.36)

  - The game's production chains already create co-op roles: ore → smith → tools; logs → planks →
    carts; wheat → bread.
  - Possible additions: shared households, splitting quest rewards, and carts or deliveries
    between players' shops (*decision*).
- **MP12. Stop one play style from ruining the others' fun.** Systems: theft, economy, player
  shops. p.72.
  > "checks and balances within the virtual world itself to ensure that no one playing style can
  > come to overwhelm the others." (p.72)

  A thief or monopolist trader can spoil a builder's or farmer's game. Decide whether players can
  steal from or undercut each other, and with what in-world counterweights (guards, reputation,
  local pricing). This is the multiplayer edge of section 3, item 6 (*decision*).
- **MP13. Keep a shared event log and host backups for disputes.** Systems: logging, saves.
  pp.153–154.
  > "If possible, log everything." (p.153)
  > "an incomplete ability to recover damaged data is incompetent." (p.154)

  - Disputes arrive with more people: "who emptied my chest", "lag killed my character"
    (permadeath). Bartle's log settled exactly the lag-death claims (p.153).
  - Keep a host-side, player-visible record of thefts, trades, deaths and causes.
  - Keep the rotating backups from section 3, item 8, so the host can roll back griefing or an
    exploit.

### LOW

- **MP14. Limit how fast any one player's commands are processed.** Systems: networking, input.
  pp.148–149. A scripted guest client could fire commands faster than a person ("30 seconds after
  having started play ... arms full of vicious weapons", p.148). The host should cap actions per
  second for each player.
- **MP15. Make names unique within a world.** System: characters/heirs. pp.152–153. Two players
  with the same name let one pass as the other (the "name problem"). Enforce unique character and
  family names per world, which also helps NPC dialogue and the log.
- **MP16. Don't give one player all the heroic parts.** System: quests. p.56.
  > "Lone heroes or heroines don't translate well into virtual worlds." (p.56)

  The game already avoids a chosen-one story. Keep villager quests claimable by any player, with
  reservation (`quests` already holds reserved rewards) and no exclusive "hero" arcs.
- **MP17. Test multiplayer early with outside players.** System: process. pp.121, 123. Beta "as
  early as possible" to find bugs and exploits (p.123), and use outside testers (p.121). Run a
  2-player LAN prototype on the host-authoritative core before investing in multiplayer content.

### Still not applicable with co-op

The following stay out because of the no-server, 3–4-player scale:

- business models;
- player-base metrics;
- live-team and customer-service staffing;
- shards, user database, front ends, server clusters and load balancing;
- out-of-world builder privileges;
- people writing their own servers (the host *is* a player, and is trusted by the people who join).
