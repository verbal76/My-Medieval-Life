# The Well - AUTHORITATIVE BUILD SPECIFICATION

Spec version 1 (Initial Build) - generated 2026-10-17 by Game Designer. This file supersedes earlier versions; earlier versions are preserved in the Game Designer project history and must not be re-derived from memory.

<!-- GAME-DESIGNER-LIFECYCLE: PROTOTYPE -->

## OWNER-INTENT RECONCILIATION — corrected interpretation (2026-10-17)

This section corrects *interpretations*, not the owner's verbatim interview responses. When generated shorthand, templates, exclusions, or other project files conflict with these clarifications, do not treat those as owner-approved decisions. Preserve the original interview text for traceability. Ask the owner before committing irreversible implementation choices.

- **Game identity:** A living medieval-world RPG/life simulation, not a conventional quest hub or roguelite. The player participates in a persistent society whose people, resources, money, households and production exist independently of player proximity.
- **Multiplayer:** The intended design includes Minecraft-like player-hosted worlds, potentially small groups of friends. The host owns the world/save; joining players' characters, possessions and progress are associated with that world. When the host closes the game, the world simulation pauses and resumes from saved state. This is **not** a permanent single-player-only game. Whether networking must ship in the first playable milestone is **UNRESOLVED**; avoid architectural choices that foreclose host-authoritative multiplayer, and ask before implementing networking.
- **Death:** Character death is permanent, but the *world does not reset*. The player may continue as a son or daughter in the same family/world. Exact inheritance, descendants' availability, and what skills transfer remain **UNRESOLVED**. Do not implement 'death ends the run; keep permanent rewards' as a roguelite reset.
- **NPCs and economy:** Persistent NPC identities, households, employment, skills, inventories, money, routines, needs, relationships and mortality. Resource production, transport, sales and consumption must conserve ownership and quantities; no arbitrary restocking or duplicated resources. Killing/robbing a worker has lasting economic and social consequences. Near NPCs use detailed simulation; distant NPCs use consistent abstract simulation.
- **Production:** Interdependent gathering, forestry, mining, farming, livestock, food, textile, fuel, metallurgy, toolmaking, building, logistics and commerce. Players and NPCs operate under comparable production and ownership rules. Exact recipes, rates and counts remain design work, not permission to invent a finished system.
- **Presentation:** 2.5D / three-quarter view with eight-direction animated character sprites; avoid flattening this to pure top-down.
- **First milestone:** Demonstrate a coherent end-to-end economy (e.g., miner → smith → merchant/household, with player interaction) before scaling to the owner's requested playable village of roughly 100 NPCs. The small proof loop is an engineering checkpoint, **not** a substitute for the desired village scope.
- **World generation:** Procedural world generation is **UNRESOLVED**, not a confirmed prohibition or requirement. Procedural art/asset generation is a different question. Do not force either decision.
- **Updates:** The owner's answer for *The Well* was fully automatic updates; preserve that project-specific decision while respecting platform and distribution limits and owner-controlled publication.
- **Unsupported additions:** Bosses, a mandatory ending, renewable resource respawn timers, and other genre-template mechanics are **PROPOSED/UNCONFIRMED**, not binding requirements unless supported by a specific owner decision. Finite ore deposits and resource conservation must not be undermined by arbitrary respawning.
- **Evidence and confidence:** Distinguish explicitly confirmed, inferred, proposed, and unresolved requirements. Do not turn speech fragments or illustrative examples into binding specifications. Resolve cross-document contradictions before coding.

## 0a. Lifecycle and handoff (read this first)

- Game Designer is a temporary design-and-prototyping tool. It generated this file and the master prompt to get a **playable proof of concept** built. After handoff it has no role, and it does not need to be present.
- **Phase** is the marker at the top of this file: `PROTOTYPE` means the prototype is being built; `OWNER_DIRECTED` means the owner now decides everything about the game.
- **Handoff happens when ANY of these is true:** the owner accepts the prototype; the owner says they are starting production or post-prototype work; or, after a playable prototype has been delivered, the owner gives an explicit instruction that goes beyond the prototype scope (new mechanics, enemies, worlds, characters, platforms, visuals, architecture changes).
- **These are NOT handoff triggers:** a question, a hypothetical ("what if we added enemies?"), brainstorming, a proposed or discussed feature, or a request to explain something. Only an explicit directive or a clearly established move to post-prototype work changes the phase. If it is unclear, ask one short question ("Are we moving past the prototype?") and change nothing until the owner answers.
- **On handoff, without asking and without Game Designer:** change the marker to `OWNER_DIRECTED`, append a dated entry to `docs/HANDOFF.md` (trigger, what was delivered), and carry on with the owner's request.
- **What expires at handoff:** every item tagged `[prototype-only]`, the prototype scope controls, all designer recommendations and provisional assumptions, and the master prompt's prototype workflow. The original specification becomes historical reference. Never cite an expired limitation to obstruct something the owner has asked for.
- **What survives:** constraints the owner set themselves (until they change them), technical documentation (architecture, build, update system, asset provenance), and genuine external constraints (security, licensing, platform and store rules, saved-data compatibility).
- **Before handoff:** an explicit owner instruction still outranks any scope control here; a scope control means 'not required for this prototype', never 'forbidden'. A question from the owner is a question: answer it, and do not implement until they instruct.
- **New conversation?** Read the marker. `PROTOTYPE`: continue or finish the prototype from this file. `OWNER_DIRECTED`: follow the owner's current instructions and use this file as project context only.

**How to read this file.** Part A is what the owner stated or decided (authoritative while it stands). Part B holds designer recommendations the owner accepted, and Part C holds implementation guidance and designer assumptions: both are provisional and carry no authority after handoff. Part D lists open and delegated matters. Part E lists constraints the owner set; they bind until the owner changes them. Future possibilities are listed in section 16 and are never prohibited.

## 0. Authority and how to use this file

This file is the authoritative specification for **The Well**. Read it completely before making decisions. Preserve the owner's intent over convenience. If repository reality conflicts with this document, investigate, preserve recoverable working state, and take the safest path that satisfies this specification. Never silently reduce scope to a prototype, toy, mockup or gray-box. Where this file is explicit, follow it; where it is silent on a non-creative engineering detail, make the best reversible decision and record it in `docs/DECISIONS.md`.

The owner is Kevin. Creative and product decisions belong to the owner; engineering decisions belong to you.

# PART A - OWNER REQUIREMENTS (authoritative: implement exactly; nothing in Part B or C may contradict this)

## A0. Hot Attic Games platform policy (standing rules for every project; they apply here without further discussion)

**Android Target API 36 is REQUIRED (Hot Attic Games standing policy; it is not negotiable per project).**

- Set targetSdk and compileSdk to 36 (or the engine/toolchain's equivalent settings) and install Android SDK Platform 36.
- Select a mutually compatible set for API 36: Android SDK and build-tools, Android Gradle Plugin, Gradle, JDK, AndroidX and other dependencies, and the engine/toolchain's Android components (export templates, Gradle integration, NDK where used). Research the current compatible versions instead of assuming them, and record the chosen set and its sources in `docs/DECISIONS.md`.
- Never keep an older Android target because a dependency, project template or default uses it. Never resolve a dependency conflict by pinning older dependencies solely to preserve an obsolete target; upgrade the toolchain and dependencies to a combination that supports API 36.
- If a specific dependency genuinely cannot support API 36, report that exact incompatibility and the nearest compatible alternative to the owner. Do not silently lower the target.
- Verify the built artifact (for example `aapt2 dump badging` shows targetSdkVersion '36') and record it in `docs/VERIFICATION.md`.

**Over-the-air updates are a FUNCTIONAL REQUIREMENT (owner decision). What must be updateable, how automatic it is and how it is delivered per platform are in section 9; the Hot Attic Games Mote OTA implementation is the reference architecture where it fits.**

- The requirement comes first, the mechanism second: deliver the update behavior described in section 9 (content, automation, timing, save protection) on each platform and distribution channel. Mote is the reference for how, not a reason to narrow what the owner asked to be updateable. Never reduce the requirement to data-only updates unless the owner chose that.
- Inspect and follow the actual Mote OTA implementation (its repository or reference material) wherever you can access it, rather than substituting a generic framework OTA solution. Do not use Expo EAS Update, CodePush, credentials embedded in the application, or another hosted OTA product by default.
- Carry forward, wherever technically applicable: a native shell/runtime boundary; classification of every change as OTA-safe or native-change; a runtime compatibility identity/fingerprint against which incompatible updates are rejected; a channel/update pointer for discovery; downloadable update artifacts; integrity and signature verification before use; staging before application; safe application and restart behavior; rollback and recovery protections; protection against broken or repeated update loops; owner-controlled publication; exact-source release discipline (a published update names the exact source it was built from).
- OTA compatibility does NOT mean every future change can be delivered over the air. Native, runtime or toolchain changes still require a new native build whenever the compatibility check says so.
- Nothing is published without the owner's explicit authorization; no publication happens as a side effect of ordinary pushes or builds. No secrets or signing credentials are ever embedded in the application or committed.
- If Mote is genuinely incompatible with this project's technology stack: (1) identify the specific incompatibility, (2) preserve as many Mote safety and release properties as technically possible, (3) report the deviation, and (4) obtain the owner's approval before adopting a materially different OTA architecture. Never substitute another OTA provider silently.

## A1. Owner vision - the original concept, in their own words

<!--verbatim-->
> I want to make an RPG but it's going to be made out of little mini characters and it's going to be like a top-down pixel map, but the characters aren't going to be top down. They're going to be kind of at an angle. You'll get the idea anyways. It's going to be a massive open world. It's going to have taverns houses castles dungeons caves the whole nine yards. It's going to have class progression, system jobs, whole nine yards. Everything that a modern RPG has. I don't want it to be as expansive as Skyrim. As far as quests and stories I want NPCs all have backstores but I want the game to to not be one of the ones where like you don't spawn the NPC at The tavern until you go into the tavern. I want the NPCs all to have lives and jobs so they're all going to do their own things. Think of all the characters and like the children of the Nile games. But I also want crafting and once you have to go out and craft things, don't you have to go source materials? You might have to mind your own materials hunting. It's going to be a. It's going to be everything you can think of. It's almost going to be like a life simulator
<!--/verbatim-->

## A2. Owner requirements

- I want to make an RPG but it's going to be made out of little mini characters and it's going to be like a top-down pixel map, but the characters aren't going to be top down.
- They're going to be kind of at an angle.
- You'll get the idea anyways.
- It's going to be a massive open world.
- It's going to have taverns houses castles dungeons caves the whole nine yards.
- It's going to have class progression, system jobs, whole nine yards.
- Everything that a modern RPG has.
- I don't want it to be as expansive as Skyrim. [contextual statement; not an automatic feature exclusion]
- As far as quests and stories I want NPCs all have backstores but I want the game to to not be one of the ones where like you don't spawn the NPC at The tavern until you go into the tavern. [contextual statement; not an automatic feature exclusion]
- I want the NPCs all to have lives and jobs so they're all going to do their own things.
- Think of all the characters and like the children of the Nile games.
- But I also want crafting and once you have to go out and craft things, don't you have to go source materials? [contextual statement; not an automatic feature exclusion]
- You might have to mind your own materials hunting. [only a possibility the owner mentioned, NOT a requirement: "You might have to mind your own materials hunting"]
- It's going to be everything you can think of.
- It's almost going to be like a life simulator
- The game is an RPG
- The game features little mini characters
- The game is a massive open world
- The game includes taverns, houses, castles, dungeons, and caves
- The game has class progression and system jobs
- It will have eight directional Sprite characters with animated Sprite sheets and it'll be almost isometric so it'll be you're looking at it top down with the the buildings that you won't just see the top of the building.
- You'll see a little bit of the side and the edge.
- I don't know what that's called [contextual statement; not an automatic feature exclusion]
- Find an iron deposit.
- I forge a sword out of the iron and then I go on a quest and I start defeating bandits and random enemies.
- And on the way I meet an NPC who gives me the power of fireballs
- Explore find something neat.
- Do something with it.
- Be able to do something different.
- I like a mix of an tech and research tree and new abilities and equipment
- The lore of this game is going to be based off of the well at the end of the world book.
- I have a complete geographical locations MD file and a entire lore file already in the repository
- I want a small playable village.
- I want all the different NPCs markets, stalls, minerals, all the resources.
- I want the skill tree laid out and I want a starter character and I want to progress all the way through to collecting everything I need to make a weapon armor and build a house

- **Genre:** Survival / crafting, RPG, Simulation / management / idle
- **World / level structure:** Large connected/open map
- **2D or 3D:** 2.5D (owner said: "2.5D")
- **Intended audience:** A general audience (owner said: "A general audience")
- **Expected game length:** Endless (owner said: "Endless")
- **Multiplayer:** Host-owned persistent world; first-milestone networking scope unresolved
- **Target platforms:** Android, Windows PC, Linux, Steam Deck (handheld PC) (owner said: "Android, Windows PC, Linux, Steam Deck (handheld PC)")
- **First platform to build and test:** Android (owner said: "Android")
- **Intended feeling:** I want them to feel like they're accomplishing something like they're building towards a better character and a bigger, better story (owner said: "I want them to feel like they're accomplishing something like they're building towards a better character and a bigger, better story")
- **Core gameplay loop:** Explore find something neat. Do something with it. Be able to do something different. Explore (owner said: "Explore find something neat. Do something with it. Be able to do something different. Explore")
- **Movement and camera feel:** Smooth and responsive (owner said: "Smooth and responsive")
- **Combat style:** Aim and shoot in real time, Melee and combos, Abilities on cooldowns (owner said: "Aim and shoot in real time, Melee and combos, Abilities on cooldowns")
- **Characters / classes:** One hero (owner said: "Your main character is the hero")
- **Progression:** New abilities and equipment (owner said: "New abilities and equipment")
- **Economy and resources:** The world operates as a fully simulated medieval production economy. Resources include natural materials such as wood, ore, stone, crops, livestock, and wildlife, along with processed materials, manufactured goods, and currency.

NPCs and players harvest, refine, craft, transport, buy, sell, and consume resources. Every NPC has a profession, inventory, income, expenses, and daily needs. Goods and money physically change ownership through transactions rather than appearing from nowhere.

Resources are consumed through food, fuel, construction, crafting, equipment wear, and household upkeep. Supply and demand influence prices, employment, and trade.

The economy operates independently of the player, with persistent NPC lives and organic consequences from player actions. The world simulation pauses when the host closes the game and resumes when reopened.
- **Simulation / building systems:** Citizens and economy: Citizens are persistent people with names, homes, jobs, inventories and real money. They work, travel, buy and sell without the player, and robbing or killing them has lasting consequences. Goods really move: ore is mined from finite deposits, carried to a smith, and turned into iron and then tools. Production needs workers, tools, fuel and materials, and takes time. Nothing appears from nowhere.

Simulation speed: Near the players, NPCs are fully simulated; far away, they are simulated in simplified scheduled steps, and nothing duplicates when they switch between the two. The world clock stops when the host closes the game.

Building:
- Players can build a house and live in it. You can only build on land you own or rent, and buildings snap to a grid.
- You choose what to build and place it. A wooden-frame construction site appears with a sign (e.g. "Building: House") and a progress bar showing the materials still needed (e.g. 40 logs, 20 planks, 10 stone).
- Building takes materials only, with no extra build time. You add resources to the site, and materials are really used up.
- Friends in multiplayer and hired NPCs can also deliver materials, but the owner keeps the building.
- The building does not visibly grow in stages. When the last required material is delivered, the frame is replaced by the finished building.
- A half-finished site can be cancelled, and everything put in is returned.
- NPCs build the same way under the same rules.
- You start by building houses, then workshops (forge, loom), farms and storage.
- Your house is where you sleep, store belongings and respawn, and it is part of your household.
- Damage, repair, fire and selling buildings will be decided later.

Not decided yet: exact production rates, population size and game-time speed. Start small: one village, one mine, one smith, one food seller.
- **Difficulty and failure:** Character permadeath with descendant succession; no world/run reset; inheritance details unresolved
- **Art style:** Pixel art (owner said: "Pixel art")
- **Budget:** A small budget if it clearly helps (owner said: "A small budget if it clearly helps")
- **Over-the-air updates:** Yes - over-the-air updates (Mote architecture) (owner said: "Yes - over-the-air updates (Mote architecture)")
- **What must be updateable after install:** Text and translations, Levels and level data, Scenes, 3D models, Textures and images, Audio and music, Menus and interface, Scripts, Gameplay logic, Engine behavior, Native code
- **How automatic updates are:** Fully automatic (owner said: "Fully automatic")
- **How test builds reach you:** GitHub pre-release with the file attached
- **Game name:** The Well (owner said: "The Well")

## A3. Owner corrections (these supersede anything earlier; do NOT implement withdrawn items)

- **Combat:** Yes [corrected by the owner]

## A4. Must-not-change constraints

These are binding and are listed in full in Part E. Do not reinterpret, 'improve' or normalise them.

## A5. First playable build scope

I want a small playable village. I want all the different NPCs markets, stalls, minerals, all the resources. I want the skill tree laid out and I want a starter character and I want to progress all the way through to collecting everything I need to make a weapon armor and build a house

Objective: a complete, genuinely playable first version (the default; the owner did not ask for a prototype).

## A6. Completion criteria

- The first build is done when: I need a fully playable entire village. The village should have maybe 100 NPCs. I should be able to use every part of the game crafting mineral collection interactions, buying stuff from vendors the whole 9 yd

## A7. Asset policy and owner-supplied assets

Asset sources in priority order: 1) appropriately licensed free assets (CC0/public domain; verify every license); 2) for whatever remains uncovered, original/procedural work created by the builder. For characters: the owner-supplied asset material then original/procedural work created by the builder. The owner did not say what to use for the gaps; that part is Bob's default and can be changed.

Asset policy: **free/CC0 assets, then original work, cat.characters=supplied>original, gaps=default** (chosen by the owner).

**OWNER-SUPPLIED ASSET PACKS.** The owner will give you asset packs together with the master prompt. They are the FIRST choice for every asset need: inspect them before choosing anything else (files, formats, scale, rigs and animations, bundled licenses), use their real contents, and create missing animations for the supplied player character where technically reasonable. Do not replace them with external or generated assets. Only gaps the packs cannot cover follow the gap policy in section 8.

- **Game icon:** none supplied; create an original one.
- **Studio logo / splash:** intentionally omitted.
- **Game splash / title image:** none supplied; create an original one.

## A8. Informed overrides and acknowledged risks

None.

- Acknowledged risk - This build would be extremely large: Compact scope with complexity 9. Expect a very large, multi-window effort; strongly consider a smaller tier or deliberate phased releases.

# PART B - ACCEPTED RECOMMENDATIONS (provisional: designer suggestions the owner accepted or delegated; keep them during the prototype unless there is a good reason; no authority after handoff)

- **Survival and crafting:** Core survival needs (health plus one or two meters), tiered tools and stations, recipes in data files, a hotbar+inventory UI with search/filter, and resource nodes governed by finite deposits, replenishment where ecologically appropriate, and conservation rules. - Covers the systems that are most often left undefined.
- **Story:** Full story with dialogue - Matches what this kind of game needs.

# PART C - IMPLEMENTATION GUIDANCE (provisional: how to build the prototype; designer assumptions, not owner requirements; no authority after handoff)

Where anything in this part appears to conflict with Part A, Part A wins.

### Engineering decisions Bob made so the owner did not have to (change any of them for a good reason)

- **Core fantasy:** It's going to be made out of little mini characters and it's going to be like a top-down pixel map, but the characters aren't going to be top down. They're going to be kind of at an angle.
- **Saving:** Autosave with Continue
- **Tutorial / onboarding:** Dedicated interactive tutorial
- **Effects and game feel:** Moderate
- **Audio and music:** Music and sound effects
- **Menus and settings:** Main menu, Pause menu, Volume controls, Graphics quality, Controls, Accessibility, Reset/erase save data, Credits and licenses
- **Accessibility:** Text size options, Colorblind-safe palette / modes, Reduced motion / screen shake off, Subtitles / captions, Vibration/haptics control, Large touch targets, Difficulty assists, Remappable controls
- **Network use:** Fully offline
- **Versioning:** Semantic version + incrementing build code
- **Distribution:** Just me / sideload
- **Phone orientation:** Landscape
- **Enemies and bosses:** A roster of distinct enemy archetypes (chaser, ranged, swarm, tank, elite) with telegraphed attacks, plus bosses with phase-based patterns. Names and designs are original and fit the world and tone described in Part A.
- **Controls:** Touch, Keyboard and mouse, Gamepad
- **Touch control scheme:** Pan and pinch-zoom camera with tap to act
- **HUD and UI style:** Clean readable HUD showing only essential state (health, XP/progress, active abilities), large touch-friendly targets, consistent iconography, and a pause menu reachable at all times.
- **Performance target:** 60 fps
- **Engine / framework:** Godot Engine 4.x
- **Build pipeline:** GitHub Actions builds the artifact
- **Testing and validation:** Deterministic unit tests for rules/data; automated build on every checkpoint; headless smoke playtest. Seeded world generation validity; scripted agent gathers, crafts a tool tier, survives N in-game days; save/load round trip. Quest state machine tests; scripted agent completes first quest chain; save/load round trip mid-quest. Headless economy simulation over N hours matches analytic bounds; save/load round trip. Persistence round-trip and migration tests. Lint/static analysis where the toolchain supports it.
- **Scope:** Go with your recommendation
- **Remappable controls:** Full remapping
- **Package / app ID:** com.hotatticgames.thewell

### Anti-slop acceptance criteria (what does NOT count as satisfying this design)

- Disconnected levels or a menu of stages does not satisfy a connected open map; regions must connect and be traversable without a level-select.
- A flat or empty cave with a few randomly placed stock props does not satisfy the visual target. The cave must read as a specific place: layered foreground and background, distinct landmarks, consistent lighting and scale, and detail across the whole traversable space.
- A default capsule, an unchanged engine mannequin or a coloured rectangle does not satisfy character presentation. Each playable character needs a distinct silhouette, readable animation states (idle, move, act, hurt, defeated as relevant) and a recognisable identity.
- Enemies that stand still or cannot hurt the player, or attacks with no feedback (hit flash, sound, knockback or equivalent), do not satisfy combat.
- A death with no consequence, a recovery that can soft-lock, or a restart that leaves stale state does not satisfy the failure-and-recovery design.
- Progression that changes only a hidden number the player cannot feel does not satisfy progression; each step must visibly change what the player can do or how they play.
- A HUD too small to read on a phone, or touch controls that cover critical play, do not satisfy the controls and presentation requirements.
- Substituting a different visual style does not satisfy the chosen art direction (pixel art): a voxel look is not smooth low-poly, pixel art or generic stylized 3D, and the reverse. Technical convenience is not a reason to change the style without the owner's approval.
- Engine-default, placeholder-looking or visually incoherent output does not satisfy the visual target: smaller and polished beats larger and unfinished.

## 2. Vision and non-negotiables

The owner's concept is quoted verbatim in section A1.

**Core fantasy:** It's going to be made out of little mini characters and it's going to be like a top-down pixel map, but the characters aren't going to be top down. They're going to be kind of at an angle.

**Intended player feeling:** I want them to feel like they're accomplishing something like they're building towards a better character and a bigger, better story

**Genre:** Survival / crafting + RPG + Simulation / management / idle. **Dimension:** 2.5D.  **Perspective:** Top-down.

### Non-negotiables

- The first build is a genuinely playable, complete game - the full intended core loop with real visuals, input, audio (if specified), menus, settings, saves, win/failure/progression - not a prototype.
- No unfinished-work markers, placeholder gameplay or stubbed systems ship in the first build. Anything deferred is listed in section 16 and nowhere else.
- Everything in this file is implemented, validated by automation, repaired and polished before asking the owner to playtest.
- No secrets (API keys, tokens, signing keys, passwords) are ever committed.
- All external assets satisfy the license policy in section 8 and are logged with provenance.

## 3. Player experience

- **Core loop:** Explore find something neat. Do something with it. Be able to do something different. Explore
- **World/level structure:** Large connected/open map
- **Difficulty and failure:** Character permadeath with descendant succession; no world/run reset; inheritance details unresolved
- **Tutorial/onboarding:** Dedicated interactive tutorial
- **Story:** Full story with dialogue
- **Movement and camera feel:** Smooth and responsive

## 4. Gameplay and system requirements

Every system the owner specified or accepted below is required in the first build and must be reachable and exercised during normal play. Genre checklist items apply wherever they fit this game's actual design; if one does not fit, adapt or omit it and note why in `docs/DECISIONS.md` (Part A always wins).

### Specified design (who decided each item is in Parts A and B)

- **Combat:** Aim and shoot in real time, Melee and combos, Abilities on cooldowns
- **Enemies and bosses:** A roster of distinct enemy archetypes (chaser, ranged, swarm, tank, elite) with telegraphed attacks, plus bosses with phase-based patterns. Names and designs are original and fit the world and tone described in Part A.
- **Characters:** One hero
- **Progression:** New abilities and equipment
- **Economy:** The world operates as a fully simulated medieval production economy. Resources include natural materials such as wood, ore, stone, crops, livestock, and wildlife, along with processed materials, manufactured goods, and currency.

NPCs and players harvest, refine, craft, transport, buy, sell, and consume resources. Every NPC has a profession, inventory, income, expenses, and daily needs. Goods and money physically change ownership through transactions rather than appearing from nowhere.

Resources are consumed through food, fuel, construction, crafting, equipment wear, and household upkeep. Supply and demand influence prices, employment, and trade.

The economy operates independently of the player, with persistent NPC lives and organic consequences from player actions. The world simulation pauses when the host closes the game and resumes when reopened.
- **Survival and crafting:** Core survival needs (health plus one or two meters), tiered tools and stations, recipes in data files, a hotbar+inventory UI with search/filter, and resource nodes governed by finite deposits, replenishment where ecologically appropriate, and conservation rules.
- **Simulation/building:** Citizens and economy: Citizens are persistent people with names, homes, jobs, inventories and real money. They work, travel, buy and sell without the player, and robbing or killing them has lasting consequences. Goods really move: ore is mined from finite deposits, carried to a smith, and turned into iron and then tools. Production needs workers, tools, fuel and materials, and takes time. Nothing appears from nowhere.

Simulation speed: Near the players, NPCs are fully simulated; far away, they are simulated in simplified scheduled steps, and nothing duplicates when they switch between the two. The world clock stops when the host closes the game.

Building:
- Players can build a house and live in it. You can only build on land you own or rent, and buildings snap to a grid.
- You choose what to build and place it. A wooden-frame construction site appears with a sign (e.g. "Building: House") and a progress bar showing the materials still needed (e.g. 40 logs, 20 planks, 10 stone).
- Building takes materials only, with no extra build time. You add resources to the site, and materials are really used up.
- Friends in multiplayer and hired NPCs can also deliver materials, but the owner keeps the building.
- The building does not visibly grow in stages. When the last required material is delivered, the frame is replaced by the finished building.
- A half-finished site can be cancelled, and everything put in is returned.
- NPCs build the same way under the same rules.
- You start by building houses, then workshops (forge, loom), farms and storage.
- Your house is where you sleep, store belongings and respawn, and it is part of your household.
- Damage, repair, fire and selling buildings will be decided later.

Not decided yet: exact production rates, population size and game-time speed. Start small: one village, one mine, one smith, one food seller.

### Required systems (genre completeness checklist - adapt each item to this game's real design)

- **Survival needs** (Survival): Hunger/thirst/health/temperature (as designed) with tuned rates and failure consequences.
- **Resource gathering and respawn** (Survival): Node types, tools, yields, respawn timers/regeneration.
- **Crafting system and UX** (Survival): Recipe tables, stations, queueing, discoverability.
- **Inventory** (Survival): Slots/weight, stacks, hotbar, drop/pickup, storage containers.
- **World generation and persistence** (Survival): Seeded world, chunk persistence, save format.
- **Threats and combat** (Survival): Hostile creatures/hazards, day-night or difficulty pacing.
- **Goal and progression** (Survival): Tech/tool tiers and a defined end goal or sandbox rule.
- **Character stats and progression** (RPG): Stats, levels, skill/talent structure, formulas.
- **Combat system** (RPG): Real-time rules, abilities, damage formulas.
- **Inventory and equipment** (RPG): Item types, rarity, equip slots, vendors.
- **Quests and dialogue** (RPG): Quest state machine, dialogue UI, journal.
- **World and content** (RPG): Zones, NPCs, enemies, bosses, a defined ending.
- **Save/load** (RPG): Multiple slots or autosave with quest/world state versioning.
- **Economy model** (Simulation): Currencies, generators, costs formulas; balance spreadsheet.
- **Progression and prestige/unlocks** (Simulation): Milestones and long-term goals.
- **Time handling** (Simulation): Offline progress/tick rules if applicable; pause semantics.

### Cross-cutting systems that must exist

- Pause behavior: the game can be paused/backgrounded at any time without loss or exploit; resuming restores exact state.
- Death/failure/restart: defined flow from failure to retry or menu with no dead ends or soft-locks.
- Save/load: Autosave with Continue. See section 11.
- Main loop must never reach an unwinnable or stuck state; automated tests assert this where feasible.
- Inventory: stacking, capacity, drop/pickup, full-inventory handling, sorting/filtering; no item can be lost silently.
- Resource regeneration/respawn and sinks are defined in data and balanced by headless simulation.

## 5. Content scope (recommended sizing)

Scope tier: **Compact** (recommended: Compact). Design complexity score 9 (genre systems, dimension, procedural content, platform count). Claude plan/usage preference supports this tier as a durable multi-checkpoint build.

These counts are Game Designer's UPPER-BOUND EFFORT HEURISTICS, not owner requirements, unless the owner stated numbers in Part A. Do not pad content to reach them. Map each unit onto this game's real structure (for example depth zones instead of levels in a descent game) and size content so the intended loop is complete and replayable. Author content as data (tables/resources), validated by automated checks; no content slot may be an empty stub.

- Gatherable resources: **12**
- Recipes: **30**
- Biomes: **2**
- Creature types: **6**
- Boss / goal encounters: **1**
- Zones: **4**
- Quests: **12**

## 6. Controls, camera and orientation

- Input methods: Touch, Keyboard and mouse, Gamepad
- Touch scheme: Pan and pinch-zoom camera with tap to act. Touch targets at least 48dp; controls must not obscure critical play; layout adapts to both thumbs and to phone/tablet.
- Remapping: Full remapping
- Orientation: Landscape; layouts must handle notches, cutouts, safe areas and aspect ratios from 16:9 to 21:9 (and tablets).
- Camera and movement feel follow section 3 and must be tunable from a single data file.

## 7. Art, audio and interface direction

- Art direction: Pixel art
- Effects/game feel: Moderate (all screen shake/flash effects respect the reduced-motion setting)
- Audio: Music and sound effects
- HUD/UI: Clean readable HUD showing only essential state (health, XP/progress, active abilities), large touch-friendly targets, consistent iconography, and a pause menu reachable at all times.
- Menus and settings: Main menu, Pause menu, Volume controls, Graphics quality, Controls, Accessibility, Reset/erase save data, Credits and licenses

## 8. Assets, provenance and branding

Supplied material is used first for the needs it covers (see A7). The rules below apply to every GAP asset and to anything external that is added; the supplied packs themselves are the owner's responsibility, but still log them in `ASSETS.md`.

License policy: **free/CC0 assets, then original work, cat.characters=supplied>original, gaps=default**. 'Free to download' is not a license. For every external asset: verify the license on the asset's own page, save a copy of the license text under `assets/licenses/`, and add an entry to `ASSETS.md` with file, source URL, creator, license, and download date. The in-game credits screen lists all of them. Do not scrape or redistribute assets against a site's terms.

If no coherent, appropriately licensed set exists for a need, build the original procedural replacement described below. Never leave an asset need unresolved or as a placeholder.

### Character and creature sprites

Player characters/heroes and all enemies and bosses in the content scope, with the animation states the gameplay needs (idle/move/attack/hit/death as relevant).

- Resolution: use the owner-supplied asset packs (inspect them first)
- Candidate sources: Owner-supplied asset packs delivered with the master prompt
- License: Owner-supplied (the owner confirms the right to use them); gap assets per the strategy
- Instructions: INSPECT THE SUPPLIED PACKS FIRST: list their files, formats, scale, rigs/animations and any license or readme, and use suitable contents for this need (suitable, not necessarily everything). Where they do not cover this need, in order: original/procedural work (Draw sprites from code: palette-constrained shape/pixel generators producing spritesheets at build time, with deterministic seeds and per-state animation frames.).

### Environment tiles, backgrounds and props

Everything needed to render the world structure chosen for this game.

- Resolution: use a CC0/public-domain set from external sources
- Candidate sources: Kenney (https://kenney.nl/assets); OpenGameArt.org (CC0-filtered) (https://opengameart.org); itch.io (CC0-tagged assets) (https://itch.io/game-assets/assets-cc0)
- License: CC0 1.0 / public domain
- Instructions: Choose ONE visually coherent set (consistency over variety). If no coherent clean-license set covers this need: original/procedural work (Generate tiles procedurally from a fixed palette with edge-matching rules; bake into an atlas.).

### UI kit (panels, buttons, bars, icons)

All menus, HUD elements, settings, and icon sets referenced by the spec.

- Resolution: use a CC0/public-domain set from external sources
- Candidate sources: Kenney (https://kenney.nl/assets); OpenGameArt.org (CC0-filtered) (https://opengameart.org); itch.io (CC0-tagged assets) (https://itch.io/game-assets/assets-cc0)
- License: CC0 1.0 / public domain
- Instructions: Choose ONE visually coherent set (consistency over variety). If no coherent clean-license set covers this need: original/procedural work (Build the UI from engine-native drawing primitives (rounded rects, gradients, icons drawn as vectors) with a shared theme.).

### Visual effects

Hit effects, pickups, death, ambient particles.

- Resolution: use a CC0/public-domain set from external sources
- Candidate sources: Kenney (https://kenney.nl/assets)
- License: CC0 1.0 / public domain
- Instructions: Choose ONE visually coherent set (consistency over variety). If no coherent clean-license set covers this need: original/procedural work (Use engine particle systems and shaders with a shared small palette.).

### Fonts

At least one readable UI font and one display font; must satisfy the license policy.

- Resolution: use a CC0/public-domain set from external sources
- Candidate sources: Kenney (https://kenney.nl/assets)
- License: CC0 1.0 / public domain
- Instructions: Choose ONE visually coherent set (consistency over variety). If no coherent clean-license set covers this need: original/procedural work (Use a CC0 font from a blanket-CC0 source, or generate a bitmap font from code.).

### Sound effects

UI, gameplay actions, impacts, pickups, alerts.

- Resolution: use a CC0/public-domain set from external sources
- Candidate sources: Kenney (https://kenney.nl/assets); OpenGameArt.org (CC0-filtered) (https://opengameart.org); itch.io (CC0-tagged assets) (https://itch.io/game-assets/assets-cc0); Freesound (CC0-filtered) (https://freesound.org)
- License: CC0 1.0 / public domain
- Instructions: Choose ONE visually coherent set (consistency over variety). If no coherent clean-license set covers this need: original/procedural work (Synthesize effects with a small sfxr-style synthesizer (waveform, envelope, filter) rendered at build time with seeded parameters per effect.).

### Music tracks

Menu track plus gameplay track(s) matching the mood; loopable.

- Resolution: use a CC0/public-domain set from external sources
- Candidate sources: Kenney (https://kenney.nl/assets); OpenGameArt.org (CC0-filtered) (https://opengameart.org); itch.io (CC0-tagged assets) (https://itch.io/game-assets/assets-cc0); Freesound (CC0-filtered) (https://freesound.org)
- License: CC0 1.0 / public domain
- Instructions: Choose ONE visually coherent set (consistency over variety). If no coherent clean-license set covers this need: original/procedural work (Synthesize loopable music from a small procedural sequencer (scales, chord progressions, simple instruments) rendered at build time.).

### Game branding and identity

- **Game/app icon:** create an original asset in keeping with the art direction and the game's identity.
- **Studio/developer splash:** intentionally omitted by the owner; do not create one.
- **Game splash / title screen:** create an original asset in keeping with the art direction and the game's identity.

Derive all required platform sizes, formats, adaptive-icon foreground/background and safe-zone variants automatically from the master artwork (for Android: mipmap densities, adaptive icon layers with the monochrome layer, Play Store 512px icon; splash via the platform splash API plus an in-game splash screen). Keep the master file untouched.

## 9. Architecture, toolchain and platforms

- Engine/framework: **Godot Engine 4.x** (GDScript (optionally C#)). License: MIT.
- Why: Free MIT-licensed engine with excellent 2D and capable 3D; scenes and scripts are text files an agent can author; light enough for phones.
- Known caveats to design around: 3D scale and tooling are below Unity/Unreal; iOS export requires a Mac with Xcode; Android export needs JDK, Android SDK and export templates; web export has threading/size constraints.
- Headless validation: godot --headless with GUT or gdUnit4 for logic tests; headless scripted scene runs for smoke playtests; export presets for CI.
- Build artifacts: Android APK/AAB via export preset (debug keystore for installable test builds); Windows/Linux/web via export templates.

Verified toolchain facts (captured with sources by Game Designer; re-verify only if a build fails because of them):

- Godot stable: latest stable release tag 4.7.2-stable (https://api.github.com/repos/godotengine/godot/releases/latest)

- Target platforms: Android, Windows PC, Linux, Steam Deck (handheld PC)
- Performance target: 60 fps
- Network policy: Offline play supported; host-authoritative multiplayer is an intended capability. Networking delivery phase is unresolved and must be confirmed with the owner.

### Platform priority and architecture

- **Android is built and tested first.** The other selected platforms (Windows PC, Linux, Steam Deck (handheld PC)) are retained as architectural targets: do not choose a stack or write code that rules them out.
- Architecture: ONE shared gameplay core (rules, simulation, data, content) plus a thin integration layer per platform (input, windowing, audio output, storage, packaging, updates). Platform code never contains gameplay rules.
- Windows builds are produced on a Windows machine or a Windows CI runner.
- No distribution channel has been chosen for Android; I assumed sideload / own distribution. A different channel could change what can be updated.
- No distribution channel has been chosen for Windows PC; I assumed standalone distribution. A different channel could change what can be updated.
- No distribution channel has been chosen for Linux; I assumed standalone distribution. A different channel could change what can be updated.

### Multiplayer

- Host-owned multiplayer is part of the intended design; whether networking ships in the first milestone is unresolved. Preserve host-authoritative multiplayer compatibility and ask the owner before implementing networking.

### Why this stack (requirements it was chosen against)

- Platforms: Android, Windows PC, Linux, Steam Deck (handheld PC); built and tested first: Android.
- Presentation: 2.5D, art direction pixel_art.
- Multiplayer: host-owned world intended; initial networking milestone unresolved. Offline single-player play should remain possible.
- Updates after install: text and translations, levels and level data, scenes, 3D models, textures and images, audio and music, menus and interface, scripts, gameplay logic, engine behavior, native code; distribution personal sideload.
- Chosen: Godot Engine 4.x (Free MIT-licensed engine with excellent 2D and capable 3D; scenes and scripts are text files an agent can author; light enough for phones.)
- Closest viable alternative: libGDX (Code-only framework: everything is source an agent can write, test with JUnit and build with Gradle; excellent Android fit; very good 2D, basic 3D.) It also reaches every selected platform. Not chosen because it fits this project's requirements less well: Updating gameplay code after install needs an added scripting layer. Known caveats: No visual editor; iOS (MobiVM) and web (GWT/TeaVM) backends need extra care; you assemble more engine pieces yourself.

### Over-the-air updates (owner requirement; Hot Attic Games Mote is the reference architecture where it fits, see A0)

- Must be updateable after install: text and translations, levels and level data, scenes, 3D models, textures and images, audio and music, menus and interface, scripts, gameplay logic, engine behavior, native code.
- Behavior: Fully automatic: check at launch, download in the background (never interrupting active play), apply at a safe moment such as a menu or session boundary, and restart automatically when needed. Active sessions and saves are protected; the player sees only a brief status.
- Includes EXECUTABLE updates (scripts and gameplay logic). Build the game so its logic lives in scripts or data that the app's own interpreter loads at runtime, from the very first milestone; do not defer this. Native code and engine behavior always ship as a new package.
- Least intrusive means minimal player effort, not hidden updates: tell the player when an update is downloaded or applied.
- Android (sideload / own distribution, assumed: no channel chosen yet): Native shell plus a signed, compatibility-checked, updatable application layer (the Mote model); gameplay code can be updated this way. Technical capability: Android can load an updated, signed application layer. Distribution policy: No store policy applies to sideloaded or self-distributed builds. Choosing Google Play later would restrict downloaded code.
- Windows PC (standalone distribution, assumed: no channel chosen yet): A signed self-updater with the same compatibility, staging and rollback rules; gameplay code can ship in update packages. Technical capability: Desktop apps can replace their own files and restart. Distribution policy: No store policy applies to standalone distribution.
- Linux (standalone distribution, assumed: no channel chosen yet): A signed self-updater with the same compatibility, staging and rollback rules; gameplay code can ship in update packages. Technical capability: Desktop apps can replace their own files and restart. Distribution policy: No store policy applies to standalone distribution.
- Steam Deck (handheld PC) (web): Updates are new deployments of versioned static files; no separate OTA machinery. Technical capability: A web build is redeployed. Distribution policy: No store policy.
- **Requested updates that CANNOT be fully satisfied as asked** (a distribution-policy limit, not a technical one; do not silently downgrade them, build the closest compliant mechanism and tell the owner). Per platform:
- Cannot be fully satisfied: Native code and engine behavior cannot be updated over the air on any platform: those changes ship as a new APK, installer or store update.
- Always needs a new package: native, runtime or toolchain changes (engine upgrade, new native plugins, new permissions, target SDK or OS-requirement bumps); anything that changes the runtime compatibility identity/fingerprint.
- Do not promise unrestricted dynamic code loading where a store forbids it; re-verify current store policy before implementing. Do not copy another project's OTA implementation: follow the reference where it fits and record deviations in `docs/DECISIONS.md`.

Hosting and cost: static files on free hosting such as GitHub Releases or Pages; no server of your own, no accounts, no analytics, and no device identifiers or personal data in update requests. Permissions: INTERNET only. Record the update-pipeline tests (bad signature rejected, corrupt artifact rejected, incompatible fingerprint rejected, interrupted download handled, rollback works, offline start works, saves survive an update, no repeated update loop) in `docs/VERIFICATION.md`.

### Repository layout and rules

- Keep game logic separate from rendering/engine glue so rules, simulation and data validation are unit-testable headlessly.
- All balance/content numbers live in data files, never scattered in code.
- Docs: `docs/DECISIONS.md` (engineering decisions), `docs/ARCHITECTURE.md`, `HANDOFF.md` (current state for the next context), `ASSETS.md` (provenance).
- Commit at every stable, tested checkpoint with a clear message; never leave `main` unbuildable. Never force-push or rewrite history on shared branches.

### Build pipeline

Use GitHub Actions to build the installable artifact on every push to the working branch and on tags, and upload it as a downloadable workflow artifact. Claude writes and maintains the workflow, reads the run results, and repairs failures until green. Godot: pin the engine version, check export templates in, commit export presets, and run headless imports/tests with the pinned binary; Android needs JDK, Android SDK and a debug keystore for installable test builds.

## 10. Performance requirements

- Hold the target frame rate (60 fps) on the minimum hardware in normal play, with graceful quality degradation instead of stutter.
- Set and enforce a documented maximum on-screen entity count; use object pooling and avoid per-frame allocations.
- Simulation runs at a fixed timestep with a documented per-tick budget and a stress test at the maximum supported scale.
- Cold start under 4 seconds on minimum hardware to the main menu; no ANRs; memory stays within a documented ceiling; battery-friendly background behavior.

## 11. Persistence and save requirements

- Save model: Autosave with Continue.
- Saves are versioned with explicit migrations and tested with fixture saves from every previous version.
- Writes are atomic (write temp then rename); corrupt saves are detected, backed up and recovered from without crashing.
- The app can be killed at any moment on a phone; autosave on pause/background and at safe points.
- Settings persist separately from game saves. A 'reset data' option exists if listed in the menus.

## 12. Accessibility

Implement and test each of the following; all must be reachable from the settings screen and apply immediately:

- Text size: at least 3 steps (100/130/160%) applied to all text, with layouts that reflow without clipping.
- Colorblind safety: never convey information by color alone; provide shape/pattern/icon redundancy and a palette option verified against deuteranopia/protanopia/tritanopia simulations.
- Reduced motion: disables screen shake, flashes, heavy parallax and camera sway.
- Subtitles/captions for all speech and meaningful audio cues, with size and background options.
- Vibration/haptics: global on/off and intensity control.
- Large touch targets: minimum 48dp, 56dp for primary actions, adequate spacing.
- Difficulty assists: adjustable game speed, jump forgiveness and similar (and damage or aim assist where the game has combat), changeable at any time without penalty.
- Fully remappable keyboard/gamepad controls with conflict detection and reset to defaults.

## 13. Testing and validation

Deterministic unit tests for rules/data; automated build on every checkpoint; headless smoke playtest. Seeded world generation validity; scripted agent gathers, crafts a tool tier, survives N in-game days; save/load round trip. Quest state machine tests; scripted agent completes first quest chain; save/load round trip mid-quest. Headless economy simulation over N hours matches analytic bounds; save/load round trip. Persistence round-trip and migration tests. Lint/static analysis where the toolchain supports it.

### Validation ladder (run in this order; repair failures before proceeding)

- Static checks: lint/format/type checks for the chosen toolchain.
- Unit tests for all rules, simulations, data validation (content tables complete, references resolve, no negative or infinite values).
- Persistence tests: save/load round trip, corrupt save recovery, migration from fixtures.
- Headless smoke playtest(s): Seeded world generation validity; scripted agent gathers, crafts a tool tier, survives N in-game days; save/load round trip. Quest state machine tests; scripted agent completes first quest chain; save/load round trip mid-quest. Headless economy simulation over N hours matches analytic bounds; save/load round trip.
- Build the real artifact for every target platform in CI and confirm it installs/launches (emulator or headless where available). Report only what you actually ran.
- UI inspection: capture screenshots of every screen at phone and tablet aspect ratios and review them for clipping, overlap and unreadable text.

### Verify before finishing (game-specific - actually play these paths)

- Launch the real build on Android, Windows PC, Linux, Steam Deck (handheld PC) from a cold start and reach live gameplay with no errors.
- Exercise movement: every movement action the design describes. Confirm the camera never clips or hides the player, collision holds (no falling through the world, no sticking), and the feel matches the owner's description.
- Travel between every region in the first build; confirm connections work in both directions.
- Play every playable character or mode from its start through its own completion path; confirm they genuinely differ as designed.
- Fight every enemy type in the first build: deal damage, take damage, defeat them, and confirm feedback (hit reaction, sound, effects). Fight any boss or set-piece encounter the design includes.
- Exercise every resource, crafting, build or trade interaction in the first build end to end.
- Fail on purpose: confirm the failure-and-recovery behaviour (character permadeath, descendant succession, and unchanged persistent world) works, restores a correct state and cannot soft-lock.
- Earn at least one progression step and confirm its effect is felt in play.
- Pause and resume (and on a phone, background and return); if saving exists, save, kill the app, relaunch and load.
- Confirm the built Android artifact targets API 36 (compileSdk and targetSdk 36) and record the compatible toolchain set you chose.
- Exercise the Mote-style update pipeline: a valid update is verified, staged and applied only after a safe restart; an incompatible-fingerprint, tampered or corrupt update is rejected with the app still starting on its current build; rollback works; a broken update cannot loop; the app starts and plays offline.
- Steam Deck: play the whole game with the controller only (every menu and prompt reachable without mouse or keyboard), at 1280x800 with readable text and no clipped UI, open the on-screen keyboard where text entry exists, suspend and resume mid-play, and confirm saves survive. Say plainly that this makes the game Steam Deck compatible in practice; Valve's official 'Verified' badge is a separate review.
- Touch and mobile: verify touch controls respond at representative phone sizes, text stays readable, audio stops and resumes with the app lifecycle, and frame rate stays steady without overheating on a mid-range device. Physical-device results must come from a physical device.
- Confirm the owner-supplied asset packs are actually used in the build (list which pack feeds which asset need in ASSETS.md) and nothing supplied was silently replaced.
- Reach the completion state defined for the first build, then restart cleanly.
- Capture representative gameplay screenshots (or video) on the real build where tooling permits, inspect them for bad composition, camera clipping, unreadable HUD, placeholder assets, empty environments, scale problems, broken materials, visual obstruction, poor character readability, weak lighting and unfinished geometry, repair what you find, and inspect again.
- Verify audio by listening to or measuring actual playback (a file existing is not proof), and verify that saved progress survives closing and reopening the game.
- Classify every piece of evidence: static inspection, unit test, simulation, production rendering (the real renderer, camera, assets and animation system), desktop runtime, or physical device. Never claim physical-device verification without a physical device, and never present a diagnostic render as production gameplay.
- Report honestly what you could and could not test. Successful compilation, an editor screenshot, a tool handshake, or unit tests alone are NOT gameplay verification.

### Definition of done for the first build

I need a fully playable entire village. The village should have maybe 100 NPCs. I should be able to use every part of the game crafting mineral collection interactions, buying stuff from vendors the whole 9 yd

### Deliverable contract

- A working game project with source, assets and any editable sources committed to the repository.
- The installable/runnable build for Android, Windows PC, Linux, Steam Deck (handheld PC), with its location reported.
- A README with exact install/launch instructions and controls, and `docs/VERIFICATION.md` listing what was actually exercised, what was not, and known remaining issues.
- Android: the studio splash (Hot Attic Games, or the owner-supplied logo above) then the game's own title screen, a current target SDK, 16 KB page-size compatibility where native code is used, GitHub Actions producing the artifact, coherent versioning, release artifact naming, and rollback-safe update behaviour where over-the-air updates are used.

## 14. Packaging, identity and release

- Display name: **The Well**
- Application/package ID: `com.hotatticgames.thewell` (never change after first release)
- Versioning: Semantic version + incrementing build code; the CI sets the build code from the run number.
- Distribution: Just me / sideload
- Request only the permissions the game actually needs and document each in `docs/DECISIONS.md`.

## 15. Execution plan and resource rules

Resource estimate: **Extreme**. Compact scope with complexity 9. Expect a very large, multi-window effort; strongly consider a smaller tier or deliberate phased releases.

Claude environment expectation: Claude Max 20x; usage style: Conservative - share my allowance with other projects.

### Phases

- Phase 0 - Foundations: toolchain pinned and verified, repository layout, CI pipeline producing an installable artifact, data schemas, test harness.
- Phase 1 - Complete core loop: the full intended core loop playable end to end with real (not placeholder) visuals, input and feedback.
- Phase 2 - Systems: every required system from this spec implemented and integrated (progression, saves, UI, settings, win/loss).
- Phase 3 - Content: author the content volume in the Scope section using data-driven tables; validate with automated checks.
- Phase 4 - Polish: audio, VFX/game feel, accessibility, performance tuning, onboarding.
- Phase 5 - Release candidate: full validation, repair pass, final build artifact, handoff for human playtesting.
- Between phases: refresh HANDOFF.md and stop cleanly if the usage window is nearly spent; resume from the checkpoint.

### Resource discipline

- Keep one authoritative CLAUDE.md; record decisions in files, not chat.
- Work in durable phases with a committed checkpoint and HANDOFF.md at the end of each.
- Run targeted tests while iterating; run the full suite and a full build only at phase gates.
- Use subagents only when their value clearly exceeds their cost; avoid parallel swarms.
- Prefer data-driven content tables so large content volume is cheap to add and test.
- Do not research settled questions repeatedly; persist findings in `docs/DECISIONS.md`.
- Do not sacrifice product quality merely to save tokens; do shrink process overhead instead.
- Do not ask the owner anything already answered in this file. Escalate only genuine creative decisions not covered here, credentials/permissions only the owner can supply, or verified blockers with no engineering alternative.

## 16. Explicit exclusions, prototype scope and future possibilities

### Not required for this prototype

Everything below is temporary prototype scope. 'Not required' never means 'forbidden': after handoff, or on any explicit owner instruction, any of it can be built.

- [prototype-only] Not required for this prototype: finished builds for Windows PC, Linux, Steam Deck (handheld PC) (they remain design targets).

- Future possibilities the owner may direct at any time: new mechanics, enemies, worlds, characters, modes, platforms, visual changes and architecture changes. None is excluded by this document.

## 18. Handoff package, milestones and operating policies

The full handoff package is in `docs/`: GAME_DESIGN.md, REQUIREMENTS_LEDGER.md (every requirement with status and evidence), EXCLUSIONS.md, ARCHITECTURE_DECISIONS.md, TECH_STACK.md, ASSET_PLAN.md, BUILD_AND_RELEASE.md, TEST_PLAN.md, GAMEPLAY_INVARIANTS.md, MILESTONES.md, COMPLETION_CRITERIA.md, OWNER_AUTHORIZATION.md, FAILURE_ESCALATION.md and PROGRESS_REPORTING.md. Keep the ledger current; it is how the owner sees what is really done.

### Milestones (a playable build comes early; the plan ends at the finished game)

- **M1 Foundation and first playable build:** An installable build on Android (the primary platform) that the owner can try, where the core verb works with the real renderer, real camera and real input. It may be incomplete but must say honestly what works.
- **M2 Complete core gameplay loop:** The core loop plays from start to finish, including failure and restart, with real controls and feedback.
- **M3 Required mechanics and systems:** Every mechanic and system in Part A of CLAUDE.md is implemented and wired into the loop. Nothing is only a button or a menu entry.
- **M4 Complete content and end-to-end playthrough:** All content the approved scope and game length call for exists, and the whole game can be played from the first moment to the completion condition.
- **M5 Polish, performance and regression testing:** Visuals, audio and feel are polished to the approved identity; performance targets are met; protected gameplay is guarded by regression checks.
- **M6 Release readiness:** Signed, versioned builds for every selected platform, update pipeline verified if requested, documentation complete, and a handoff report. Nothing is published without the owner's authorization.

### Protecting the game's identity and feel

- Once the owner approves a playable baseline, the characteristics recorded in `docs/GAMEPLAY_INVARIANTS.md` are protected.
- Repairs are narrowly scoped: if one animation is wrong, fix that animation. Do not change jumping, climbing, physics, the camera or character geometry without a demonstrated need and the owner's approval.
- Every protected system has a regression check; run it before and after any change that could touch it, and do not alter protected timing or input response for performance reasons.

### When a repair keeps failing

- Keep a failure history in `docs/FAILURE_LOG.md`: the defect, what was tried, the expected and actual result, and why the check did or did not catch it.
- After TWO failed attempts at the same defect: stop repeating the same fix. Review what earlier attempts changed, compare expected with actual results, work out why the earlier checks did not detect the problem, find the root cause, and choose a different diagnostic strategy.
- After THREE failed attempts: write an escalation report (what was tried, what the evidence shows, the leading hypotheses, the options) and stop for the owner before another expensive repair cycle.
- Prefer small, measurable fixes. Do not rerun an identical test or build without a reason, and avoid unnecessary full rebuilds and endless rendering loops.
- Track repeated build failures and wasted builds in the failure log. Do not weaken, skip or delete a test to make it pass; repair the cause.
- Ship playable builds over impressive but unverified reports.

### Who may authorize what

- Local build: allowed without asking.
- Build-system (CI) artifact: allowed when the build system is part of the approved plan; keep builds to what the work needs.
- GitHub test release (pre-release with files attached): only when the owner chose that delivery method; it is publicly downloadable if the repository is public.
- Over-the-air update publication: only on the owner's explicit authorization, separate from ordinary builds and from store releases.
- Google Play, Steam and Apple App Store publication: only on the owner's explicit authorization, and each is separate.
- Merging into the main branch, deleting history, or changing signing identity or package identifiers: only on explicit authorization. Preserve the signing identity and package identifiers.
- Never publish automatically, and never treat one kind of release as permission for another.

### How to report progress

- Write reports a non-programmer understands: what works now, what changed, what remains, what needs the owner's approval, what can be tested now, and whether the current build is playable. Example: "Your character can now run, jump and climb. The Android test build is ready."
- Keep technical detail (commits, checks, logs) in an optional section for those who want it.
- Never invent completion percentages or delivery dates. Never call a feature complete without evidence of the kind the ledger names.
- State the evidence class for every claim: static inspection, unit test, simulation, production rendering, desktop runtime, or physical device. Do not claim physical-device verification without a physical device.

# PART D - UNRESOLVED AND DELEGATED DECISIONS

None unresolved. Every build-critical decision is resolved by the owner, delegated, or left to implementation discretion above.

Delegated to Bob's recommendation (recorded in Part B): Survival and crafting, Story.

The owner's plain-English design review was approved.


# PART E - MUST NOT CHANGE (owner-set constraints: do not reinterpret or 'improve' them while the owner keeps them; the owner can change any of them at any time)

Stated by the owner:

- It should not reinterpret that the game itself is alive and we're interacting with a simulation

Implied by the owner's own decisions:

- The world is one connected open map; never convert it into discrete levels.
- Asset policy: free/CC0 assets, then original work (with exceptions for characters) (chosen by the owner).

## 17. Human-only steps

Only these steps genuinely need the owner. Do everything else autonomously.

- Install and playtest the first build on a real device and report back what feels wrong (text, voice, screenshots or video).

## Audit notes at generation time

The Game Designer audit reported the following when this version was generated. Treat blocking items as owner-visible risks and resolve or work around them.

- [WARNING] Android target API is very short; the spec will be more reliable with a fuller description.
- [WARNING] Intended feeling contains vague wording ("something like") that may cause incorrect improvisation.
- [WARNING] Movement and camera feel is very short; the spec will be more reliable with a fuller description.
