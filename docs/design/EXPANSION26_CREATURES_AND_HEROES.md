# Expansion 26: Creatures and Heroes

**My Medieval Life — expansion packet (design specification, implementation plan and audit), 2026-10-23**

Register: PET-01, MON-01, with the long-approved B14-09 (skeletons) and FR-01 (lizards and spiders) (Build 26). Status:
**design approved in parts by the owner; no code until the owner approves this packet.** Build 19 is the priority; nothing
here delays it. Founding principle (World Design Rule 022): *a village is allowed to fail, the simulation is not.*

Builds on Expansion 25, Weather, Seasons and Disasters (`EXPANSION25_WEATHER_SEASONS_DISASTERS.md`): rivers and banks (the
crab, Buwaya), winter (the yeti), building damage and repair (monster attacks), warnings and emergency response (village
defence).

---

## 1. What exists today (audit)

| Area | Fact |
|---|---|
| Wild animals | foxes, wolves, rabbits, boars, deer, bears and birds roam, graze, hunt and breed (MiniFolks animals, Build 14) |
| Husbandry | a husbandry skill exists (with farming, hunting, combat and others) |
| Pens | the player can fence a pen on their own cleared ground, one kind of animal per pen; animals are fed at the trough, breed when well fed, give eggs, milk and wool; villagers keep pens too |
| Combat | the player and guards fight; wolves and bears attack; bandits rob; the family-protection rule (Build 19) puts parents between danger and their children |
| Skeletons | approved long ago (B14-09: in caves and uncleared woods, guarding by day, roaming at night, 3-day respawn, bones and rusty gear); **never built** |
| Lizards and spiders | approved (FR-01); recorded as blocked for lack of art, **wrongly**: the art was supplied |
| Monster art in the repository, unused | `Skeletons_Free_Pack.zip` (sword skeleton); `MiniWorldSprites.zip` Monsters: GiantCrab, five dragons, minotaur, orcs and goblins, demons, necromancer, skeleton soldier, slimes, yeti, wendigo, mammoth; `PUNY_MYTH-CREATURES-RPGMAKER_v1.zip`: Buwaya (a crocodile-like creature) and other myth creatures; `PunyMonsters.zip`: two spiders, panther, wolf, rat, dog |
| Prestige and opinion | Expansion 19 judgment, trust, gossip, family reputation and personality (Build 19) carry how villagers see the player |
| Bounties | none; the reeve already posts manor work and pays from the treasury |

## 2. The owner's approved design

### 2.1 Taming and pets
- With an animal's **liked food in hand** the player gets an action to try taming a **fox, wolf or rabbit**.
- A few feedings tame it: **rabbits easiest, foxes more, wolves most**; about **three feedings unskilled, one or two with
  husbandry**; a master can tame a rabbit at the first feeding, a wolf takes at least two.
- An animal already tried shows a **marker** over its head so the player can keep trying.
- A tame animal **follows**, **waits at home** when told, and **must be fed** or slowly turns wild again.
- **Villagers react** (a pet wolf near the chickens worries farmers; children love rabbits), and **villagers with husbandry
  tame pets too**.

### 2.2 Pens and tame breeding
- A tame animal follows the player **into their pen**, where a prompt makes it **stay**.
- **Young born in the pen are tame.**
- Penned **rabbits** give meat and pelts; pen-bred **wolves** grow into **guard dogs** that bark at bandits near home;
  **tame young** (rabbits, fox kits, wolf pups) can be **sold** to villagers who want a pet; **foxes** are kept as pets
  (agent reading of the owner's answers, to confirm).

### 2.3 Companions
The player can pick a **pet fox or wolf as a companion**: it follows on missions, **defends** the player against wild
animals and bandits, **hunts** for the player, and can be hurt or killed.

### 2.4 Monsters
- **Skeletons** underground and in the uncleared woods; **spiders** in the caves.
- **Bosses:** a **giant crab** by the new river; **Buwaya**, the crocodile-like "lizard", in the marshes and on the banks; a
  **minotaur** in the hills; a **yeti** that comes down in winter; a **necromancer** in the caves who raises the skeletons;
  **dragons**, the rarest and deadliest.

### 2.5 Village defence
Rarely, a monster attacks the village. **Guards go first; then able adults form a line** with whatever they hold
(pitchforks, axes, swords), each deciding by courage, family duty and personality. The family-protection rule keeps
parents between the danger and their children; elders and children shelter indoors.

### 2.6 Bounties, heroes, hunters and monster goods
- **Bounty coin:** the reeve posts bounties paid from the treasury; the player or a villager hunter claims one with proof
  (a pelt, a claw).
- **Heroes:** defending the town or killing a boss makes the player one of the town's heroes: villagers admire and trust
  them more, and the stories spread (Expansion 19 gossip).
- **Monster goods:** rare goods only monsters give (for example crab shell, Buwaya hide, yeti fur, bone dust), sold to
  craftsmen for special armour, tools and medicine.
- **Villager hunters:** brave villagers can take up monster hunting as a trade and compete with the player for bounties.
- **Everything moves emotions:** how villagers see the player, how safe they feel, how they see themselves as protectors.

## 3. How it works (proposed architecture)

- **Tameness** as a per-animal record (tries, liked food, owner, tame, hunger): tries and results by a seeded hash with the
  husbandry level, so the same world gives the same outcome; the marker reads the record.
- **Pets in pens** reuse the pen system (feeding, breeding, products); tame young inherit tameness; selling uses the
  existing trade (coins move, none appear).
- **Companion** as a following actor with the existing animal combat and hunting behaviour pointed at the player's targets.
- **Monsters** as new kinds of creature on the existing wildlife and combat code, with lairs (caves, woods, banks, hills),
  day and night behaviour, respawn rules and loot; bosses as single named creatures with their own lair and rarity.
- **Village attack** as an emergency event (shared with Expansion 25's disaster response): the alarm, guards' response,
  villagers' line decisions through the Expansion 19 decision engine and the family rule, damage to buildings through the
  Expansion 25 building condition.
- **Bounties** posted by the reeve like manor work, escrowed from the treasury (coins set aside, paid on proof, returned if
  withdrawn), so no money appears from nowhere.
- **Monster goods** as items and recipes in the existing data (`items.json`, `recipes.json`, `resources.json`), sold through
  the existing markets.
- **Villager hunters** as a job the existing job system offers, with the brain choosing hunts by courage, skill and gain.
- **Heroes** through the Expansion 19 judgment events (a defence or a boss kill is a good deed, witnessed and gossiped);
  no separate fame score.
- **Art** through the asset pipeline (scaled to the 16 px world, imported with provenance, credited).
- **Wiki:** pages for taming, pets, companions, monsters, bounties and village defence.

## 4. Implementation plan (phases, each tested and committed before the next)

| Phase | Content | Needs from 25 |
|---|---|---|
| **26-A Taming and pets** | taming, markers, husbandry odds, follow, stay, feeding, going wild; villagers' reactions; villager tamers | none |
| **26-B Pens and companions** | pens for tame animals, tame young, rabbits' meat and pelts, guard dogs, selling young; fox and wolf companions that defend and hunt | none |
| **26-C Monsters** | skeletons (B14-09 as approved) and spiders in caves and woods; monster goods and recipes | none |
| **26-D Bosses** | crab, Buwaya, minotaur, yeti, necromancer, dragons, each in its lair with its own rarity | rivers and banks, winter |
| **26-E Village defence and heroes** | rare attacks, alarm, guards then volunteers, family protection, damage and repair, hero stories | building condition, emergency response |
| **26-F Bounties and hunters** | reeve's bounties with escrow and proof, villager monster hunters, the monster goods market | none |
| **26-G Gate** | wiki, phone performance, saves, determinism, bounded long runs | |

Phases A to C and F do not need Expansion 25, so they could start earlier if the owner wishes.

## 5. Questions still open (with recommendations)

| Id | Question | Recommendation |
|---|---|---|
| E26-OD-01 | Foxes: pets only, or also companions? | companions too (as the owner's companion answer says); only their pen use is pets-only |
| E26-OD-02 | Monster respawn | skeletons as approved (3 days); spiders like skeletons; a killed boss does not return for at least a game year, and some (the dragon) never in the same lair |
| E26-OD-03 | How often a monster attacks the village | about once in several game years, more when lairs are near and the guard is weak; never more than one at a time |
| E26-OD-04 | Bounties when the treasury is empty | no bounty is posted without the coins; villagers may pool coins for one (Expansion 20 lending later) |
| E26-OD-05 | Bounty prices | set by the reeve from the danger and the treasury, within a band the owner approves (proposal: 20-60 coins for monsters, 150-400 for bosses) |
| E26-OD-06 | Monster goods recipes | one special item per boss (crab-shell shield, Buwaya-hide armour, yeti-fur cloak, minotaur-horn tool, necromancer's bone-dust medicine, dragon scale armour), plus bones and rusty gear from skeletons |
| E26-OD-07 | Companion combat numbers | a wolf about as strong as a wild wolf, a fox weaker but quicker; both heal with rest and food |
| E26-OD-08 | Can villagers' pets or guard dogs fight in village defence? | yes, guard dogs join the guards' line |
| E26-OD-09 | When to build it | after Expansion 25 (phases A to C and F could come sooner if wanted) |

## 6. Risks
- **Combat balance:** bosses must be dangerous but beatable by a prepared village; measured, not tuned to good results.
- **Performance:** creatures counted in the existing wildlife budget; bosses are single creatures.
- **Economy:** bounties and goods must keep conservation (escrow, real items).
- **Saves:** new optional sections (tameness, monsters, bounties); old saves load without them.

---

## Appendix: the owner's words (verbatim)

### Owner idea, 2026-10-23: taming small wild animals as pets


And smaller animals that can be domesticated should be able to be big pets like foxes and wolves and bunnies. You should be able to go up to them and you should see an option if you're holding the food that they like to hit a to attempt to. Domesticate, if you give this if you give an animal food a few times, you'll be able to domesticate it and they'll follow you. If you've given food to an animal already and it didn't take and they didn't domesticate there should be a little marker above their head so we know which ones you've already tried so you can keep trying
And if you're skilled at husbandry, you should have a better chance of domestication earlier and a better percentage of it happening earlier if you have no skills, it might take three food gifts to domesticate an animal. But if you have skills and husbandry, it might only take one or two the higher the level is

## Owner answers (same day, in the session)

- Placement: **"Small add-on after Build 19 (Recommended)"**: its own record, built after Build 19 ships and before the
  bigger expansions; reuses the foxes, wolves and rabbits in the game and the husbandry skill; does not delay Build 19.
- What a pet does (several chosen): **"Follows and stays (Recommended)"** (follows, waits at home when told, must be fed
  or slowly goes wild again); **"Wolf defends you"** (a tamed wolf or fox fights wild animals and bandits that attack the
  player; it can be hurt or killed); **"Villagers react"** (villagers notice: a pet wolf near the chickens worries farmers,
  children love rabbits, through Expansion 19 opinions); **"Villagers tame too"** (villagers with husbandry skill can also
  tame pets).
- Odds: **"By animal (Recommended)"**: rabbits easiest, foxes more, wolves most; husbandry shortens all; a master can tame
  a rabbit on the first feeding, a wolf takes at least two.

## Owner addition (same day, in the session; verbatim, spoken)

If a husbandry skilled is not exist, we should be exist. You should be able to have animal pens built where you can domesticate animals take them into the pen cuz they follow you and if you're in the pen and they follow you into the pen which they should you should get a pop-up to have him stay there and then you can have him stay inside the pen like the villagers already have pens and then any offspring they have should automatically be domesticated

(Facts: the husbandry skill already exists; players already fence their own pens, one kind of animal per pen.)

Owner answer, what penned tamed animals are for (several chosen): **"Rabbits for meat and pelts (Recommended)"**,
**"Wolves become guard dogs"** (pen-bred pups grow up tame and bark at bandits near home), **"Sell tame young"** (rabbits,
fox kits, wolf pups sold to villagers who want a pet), **"Just pets"**. Agent reading of the combination (to confirm in the
design note): foxes are kept as pets only; rabbits also for meat and pelts; wolves also as guard dogs; tame young of any of
them can be sold.

### Owner idea, 2026-10-23: companions, monsters, village defence, bounties and monster goods


You should be able to pick a pet fox or a pet wolf as a companion and they should follow you on missions and defend and Hunt things for you
Also early on I put in Sprite sheets for skeletons to attack underground and in the woods. I haven't heard anything about them yet. I also put in a few boss monsters including lizards, some crab monster thing and a boss monster and I haven't seen those used in the forests or the hills at all and they should also attack The villages every now and then which would be rare but the villagers would have to band together attack. The guards would go first then the villagers would form like a picket line and try to defend the town
If you help defend the town you can become one of the heroes of the Town and there should be bounties on these monsters. So like if those monsters are in the woods you should be able to pick up a bounty to go kill them and bring their pelts back and this would build your prestige
See what I mean. I'm really getting into this now. I'm starting to feel this in all of this weather and pets and disasters and monsters and bounties and pelts and everything. This should all play into people's emotions and how they view you and how they think of themselves for protection. Hell maybe even some of the villagers decide they want to be a hunter and they want to go out and hunt these animals. There should be a market for the specialty goods that only come from these monsters

## Facts found when it was recorded

- Skeletons (B14-09, owner-approved, not started) and lizards and spiders as enemies (FR-01, recorded as blocked on "no
  lizard or spider pack supplied") are in the register; neither was built.
- The art is in the repository and unused: `Skeletons_Free_Pack.zip` (sword skeleton), `MiniWorldSprites.zip` Monsters
  (GiantCrab, dragons, minotaur, orcs and goblins, demons, necromancer and skeleton soldier, slimes, yeti, wendigo,
  mammoth), `PUNY_MYTH-CREATURES-RPGMAKER_v1.zip` (Buwaya, a crocodile-like creature, and other myth creatures),
  `PunyMonsters.zip` (two spiders, panther, wolf, rat). FR-01's blocker was wrong: spiders and a crocodile-like creature
  were supplied.

## Owner answers (same day, in the session)

- Build: **"Merge with weather (25)"**: one "Wild World" expansion: weather, disasters, monsters, pets and bounties
  together, designed as one.
- Bosses (all chosen): **"Crab and Buwaya (Recommended)"** (a giant crab by the new river; Buwaya, the crocodile-like
  "lizard", in the marshes and banks), **"Minotaur and yeti"** (a minotaur in the hills; a yeti that comes down in winter),
  **"Necromancer"** (in the caves, raising the skeletons), **"Dragons"** (the rarest, deadliest boss).
- Defence: **"Guards, then volunteers (Recommended)"**: guards first; able adults form a line with what they hold, each
  deciding by courage, family duty and personality; the family-protection rule keeps parents between danger and children;
  elders and children shelter indoors.
- Rewards (all chosen): **"Bounty coin"** (the reeve posts bounties from the treasury, claimed with proof such as a pelt
  or claw), **"Prestige and hero status"** (defending the town or killing a boss makes the player a hero; admiration,
  trust and stories through Expansion 19), **"Monster goods market"** (rare goods only monsters give, sold to craftsmen
  for special armour, tools and medicine), **"Villager hunters"** (brave villagers take up monster hunting as a trade and
  compete for bounties).
