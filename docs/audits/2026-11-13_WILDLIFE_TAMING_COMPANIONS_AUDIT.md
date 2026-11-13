# Wildlife taming and animal companions (PET-01, Expansion 26): status audit, 2026-11-13

Owner brief: docs/directives/2026-11-13_wildlife_taming_companions_audit.md. Read-only audit; nothing implemented.

## Status
Owner-approved design (2026-10-23), placed in Expansion 26 (Creatures and Heroes), **design only, implementation not
authorized** (register `builds.26.implementation_authorized: false`; owner 2026-10-24 "Keep … Creatures & Heroes in
design-only status until specifically authorized"; owner 2026-10-30 "Do not begin Expansions 22–27"). **No code on any
branch**: no tame, trust, pet, companion or follower code (the only "Companion" in code is the multiplayer friend menu).

## Records
- PET-01 (approved, NOT STARTED, build 26): taming foxes, wolves, rabbits with liked food; a few feedings tame it and it
  follows; marker over an animal already tried; husbandry makes it quicker. Acceptance only "build placement and open
  questions answered"; no functional criteria yet. Source docs/directives/2026-10-23_animal_domestication_idea.md.
- EXP-26 umbrella (PET-01, MON-01, B14-09, FR-01, CREATURE-OWN, E26-OD-01..09).
- Open decisions (no owner answer): E26-OD-01 foxes pets only or companions too; E26-OD-07 companion combat numbers;
  E26-OD-08 pets/guard dogs in village defence; E26-OD-09 whether 26-A/B may start before Expansion 25. OD-02..06 are monsters.
- CREATURE-OWN / ROAD-Q3 (owner 2026-10-24): Expansion 26 owns creature behaviour; "Do not duplicate creature behavior systems".
- Design: docs/design/EXPANSION26_CREATURES_AND_HEROES.md (sections 2.1-2.3 owner design written up; sections 3-4
  architecture and phases 26-A taming and pets, 26-B pens and companions are agent proposals; section 5 open questions);
  docs/expansions/EXPANSION_26.md ("Implemented: Nothing"). The owner's original Creatures & Heroes packet is listed in
  docs/expansions/MISSING_SOURCES.md (the owner holds it).

## Species (owner sources)
- Taming: foxes, wolves, rabbits ("big pets like foxes and wolves and bunnies"; "rabbits easiest, foxes more, wolves most;
  … a master can tame a rabbit on the first feeding, a wolf takes at least two").
- Companions: fox and wolf ("pick a pet fox or a pet wolf as a companion and they should follow you on missions and defend
  and Hunt things for you", docs/directives/2026-10-23_monsters_bounties_companions_idea.md).
- Pen uses: rabbits for meat and pelts; wolves become guard dogs; sell tame young; just pets. No dog species exists
  ("guard dogs" are pen-bred wolves). Boar, deer, bear, bird: not eligible in any source.
- An agent note "foxes pets only" is unconfirmed and conflicts with the companion wording (E26-OD-01).

## Pieces
All missing: offer-food action, trust/feeding count, tried marker, tame state and owner, following the player, pen
kinds for fox/wolf/rabbit, tame young and their sale, journeys/missions, defending and hunting for the player, villager
reactions and villager tamers, save fields, UI, wiki.

## Reusable systems (wt-hunt 3ba8d22)
Animal record and additive save (animal.gd to_dict/from_dict; fauna.gd ~1010-1046); trough feeding and hunger
(fauna.gd 208-260, 558-587); Husbandry skill (data/skills.json, World.player_feed_pen world.gd ~3579-3587); NPC lead-at-heel
(Wilds.leading/lead_step/led_home wilds.gd ~782-820, `led` saved); player pens and pen owner (farming.gd build_pen,
buy_animal, buy_horse); animal fight and bite (fauna.gd 366-449); player striking animals (World.player_hit_animal).

## Conflicts a tame animal would meet (mostly inferred from code)
- Threat rules: on wip/b25-animal-boar-livestock `Fauna.active_threat` counts any angry wild wolf or bear (and a charging
  boar); a tame wolf fighting for the player would be treated as a beast by household heads; `Fauna.defence_kill` would
  score killing someone's tame wolf as a defence.
- `_hunt_people`: a hungry tame wolf could attack its own owner or a lone villager.
- Struck-animal flight and charge (hunt AI, boar) and shying from people (fox 4.0, rabbit 3.5 tiles): a follower would flee its owner.
- NPC hunters skip foxes and wolves (`game: false`) but take rabbits: a tame rabbit would be hunted.
- Predation and fox raids: a tame fox would raid chicken pens; a tame wolf would hunt livestock or game in its area.
- Wood counts, woods_cap, keep floors and WR-01 refuge targets count every animal in a wood.
- Country animals released when the player is far away would erase a tame one.
None of these blocks the current boar or hunt-AI work; they are rules Expansion 26 must exempt tame animals from.

## Gaps not recorded as decisions (do not invent)
Liked food per species; how fast an unfed pet turns wild; companions during off-map journeys; how a tame wolf fits the
active-threat, defence-kill and hunter rules.

## Remaining work (not authorized)
1. Owner: authorize Expansion 26 (or 26-A/B early, E26-OD-09), approve the packet, answer E26-OD-01/07/08 and the gaps;
   then PET-01 acceptance criteria and child records.
2. Tameness on Animal (tries, tame, owner, last fed), additive save, seeded odds by species and Husbandry.
3. Offer-food action (and multiplayer guest), real items consumed, Husbandry XP.
4. Tried marker (view/animal_sprite.gd).
5. Following: extend the lead-at-heel to player owners; exempt followers from shying, refuge, wood-count and country release.
6. Pens for fox, wolf, rabbit; tame young; going wild; sale of young.
7. Companions (fox, wolf): defend, hunt, can be hurt; exclude tame animals from active_threat, defence_kill, _hunt_people,
   raids on the owner's stock and nearest_game.
8. Villager reactions and villager tamers. 9. Journeys and missions. 10. Wiki pages and INT entry. 11. Tests and device playtest.
