# Build decisions (first playable, The Well build test)

Implementation choices made while building the Godot prototype in `game/` where the Game Designer
export and the owner's decisions left a gap. Each one is an **agent proposal** until the owner
approves it; owner decisions live in `docs/DECISIONS.md`. Tunable numbers are in
`game/data/balance.json`, so changing one needs no code.

## Village and people

| Decision | Why |
|---|---|
| 100 villagers in 23 households, plus 6 bandits, with jobs from `game/scripts/core/population.gd` (`JOBS`, 26 children, 18 elders) | The owner's target of 100 NPCs. The job mix is chosen to keep food, tools and coin moving |
| The map is a fixed 120 x 90 tile village built from Shade's sample maps (`tools/build_village.py`) | A hand-made village first; world generation comes later |
| NPCs near the player update every frame, the rest every 0.5 s with the same rules | 100 NPCs at phone frame rates |
| Coins only enter through the merchant caravan; the reeve taxes, pays for repairs and gives relief; guards are paid | Bob's spec wants a closed economy; something has to stop money pooling in one place |
| Households share a food "tab": anyone without coin can eat on the richest member's money | Children and elders have no income |
| Traders keep 15 coins (`trader_cash_floor`) instead of spending everything on stock | A smith and a merchant spent their last coins on stock and their household starved |
| Miners mine only ore someone will buy | A miner starved holding unsellable stone and coal |
| Pottage instead of bread; there is no mill | No mill art; one cooking chain is enough to test the economy |
| NPCs craft at stations regardless of their skill level; skill levels gate only the player | Keeps 100 NPCs simple |

## Player

| Decision | Why |
|---|---|
| Permadeath: the heir keeps the house, the chest and half of each skill's XP; what the dead carried stays where they fell | Bob's spec has permadeath with family continuation but no rule for what passes on |
| Building: buy a plot from the reeve, a wooden frame appears, deliver 30 planks, 20 stone and 10 logs, and the house stands | The owner's rules (frame, materials only, no extra build time) |
| Attacking a villager, or killing a keeper's animal, is a crime: guards nearby and the victim respond | Bob's spec has crime but no penalty system yet |

## Animals (owner rule: a fed pair breeds, babies are half scale, animals become meat)

| Decision | Why |
|---|---|
| Four fenced pens below the market (cows, pigs, sheep, chickens), each kept by one farmer | Livestock needs a place and an owner; Cozy Farm fences fit the art |
| Wild boar (Puny Monsters) and rabbits (Cozy Farm) in the two northern forests | The packs have no deer; boar and rabbit are the game animals available |
| Hunger works like the villagers' (owner rule): it falls 3 points an hour. Below 55 an animal eats: livestock takes its `feed` of wheat from the trough (cow 2, others 1) and walks to the trough by the gate; wild animals graze, one animal per 15 open cells of their wood. At zero hunger an animal loses 10% of its health an hour and dies, about a day and a half after its last meal | The owner: "if you don't feed the humans they die... you get to feed the animals or they die as well". Keepers and the player feed the pens (owner answer) |
| Breeding: a well-fed adult female (hunger 40 or more) gives birth when a well-fed adult male of her kind shares the area. Litter, time between births and growing age per kind (`balance.json` "animals"). Pens and woods have caps | The owner's rule, with numbers that keep herds stable over 10-day tests |
| Babies are drawn at half scale until `grow_days`, then full scale; a baby gives half the meat and no hide | The owner's rule |
| Keepers feed the pen from their wheat, the household's store, or feed they buy. Whoever harvests a keeper's field carries 4 days of feed to the pen first. Keepers slaughter surplus when the pen is nearly full, and cull beyond the breeding stock only when no feed can be had for the next morning | The wheat went to whichever farmer harvested, and pens starved |
| Hunters hunt real animals and never take a kind below 2 adults per wood. Bandits poach near their camp. The player hunts with the sword or a fireball and takes the carcass (meat, hide) | Replaces the old invisible "deer count" |
| Saves from before hunger load with every animal full. Old saves (`save_version` 1) load: the deer count is dropped, and pens and woods are stocked as in a new game | CLAUDE.md section 7 |
| Puny Monsters boar frames 0-3 are used as the walk cycle | **Uncertain**: the sheet has no frame notes |

## Known gaps

- **The economy collapses in runs longer than 10 days.** From about day 12, villagers in some
  households starve while the village as a whole has food and coins. This happens on the committed
  build without animals too (85 of 100 alive on day 20; 82 with animals). Money stops reaching
  some households. Not yet fixed.
- The player cannot own livestock, harvest fields, or hire helpers to deliver building materials.
- No eggs, milk or wool (the owner asked only for meat).
- No aging, no births of people, no audio, no Android build.
