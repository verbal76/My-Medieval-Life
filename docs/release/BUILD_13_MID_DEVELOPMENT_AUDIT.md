# Build 13: mid-development audit, assets and release forecast

Owner's audit request of 2026-10-19 ("Build 13 comprehensive development, asset and release forecast audit").
Audited on `staging/my-medieval-life` at `2caca5a`, plus the ledger rows added in the same commit as this report.
This is an audit, not a release: nothing was built, published or merged, and development carries on.

## How this report names the builds

The brief calls the current work "Build 13 under development". The repository shows something slightly different, and this report follows the repository:

- **Build 12** is the private test release from `f8b4a98` (2026-10-19 08:10 UTC; `docs/release/BUILD_12_PACKET.md`).
- **Build 13 is already built.** It is a private draft release from `4e76f72` (13:27 UTC; `docs/release/BUILD_13_PACKET.md`), approved by the owner, holding the Build 12 audit fixes, the four economy rules and the four remaining audit items.
- **The work since then is labelled B14** in the task list and ledger (`docs/DEVELOPMENT_LEDGER.md`, rows B14-01 to B14-12). Your newest requests (storefronts, carts, pricing, forest animals, skeletons, the new asset packs, cliffs) belong to it.

So "what has the current cycle done" has two parts, kept apart everywhere below:

| Part | Commits | What it is |
|---|---|---|
| **Build 13 (shipped privately)** | `f8b4a98..4e76f72` (16 commits) | Build 12 audit fixes, economy rules, the livestock chain, three control fixes |
| **Since Build 13 (next release, unreleased)** | `4e76f72..2caca5a` (8 commits) | Harvest-or-talk, home production, storefronts, carts, local prices, forest animals |

Where the brief says "the Build 13 release", this report reads it as **the next release built from the current work**. Its number is the owner's choice (14 would follow); this report calls it "the next release".

## Executive scorecard

Counting rules:
- One feature counts once: a ledger row or a task, never also its sub-parts.
- "Integrated" means drawn or used in a playable scene and covered by a test.
- An asset pack counts once, however many files it came in.
- The window is from Build 12 (`f8b4a98`) to `2caca5a`.

| Measure | Count | Note |
|---|---|---|
| New asset packs discovered | **5** (in 9 files) | MiniFolks Forest Animals (2 × .7z), Skeletons Free Pack (.zip), Forgotten Memories (.zip + .rar), Animal Farm Project (WIP .zip + 1.0 .rar), Craftpix Free Plants for Farm (.zip). The brief's "about ten" counts files, not packs. Nothing else in the upload folder or the repository is new since Build 12 |
| New packs with assets in gameplay | **1** | MiniFolks: 8 sheets imported and drawn |
| New packs present but not used | **4** | Skeletons (public repo); Forgotten Memories, Animal Farm and Craftpix (private-assets) |
| Existing mechanics strengthened | **11** | Listed in section 6 |
| Genuinely new mechanics | **6** | Harvest-or-talk choice, home production and self-treatment, storefronts, cart parts and handcarts, local-availability pricing, the predator–prey food chain |
| Build 12 defects corrected | **5 audit defects + 4 economy rules + 4 audit items** | B13-01 to B13-14, all VERIFIED (two of them headless only) |
| Verified tasks | **20** | B13-01 to B13-14 (14) and B14-01 to B14-05 and B14-08 (6) |
| Workstreams in progress | **0** | Nothing is mid-implementation. The last one (forest animals) closed at `2caca5a` |
| Planned tasks not started | **7** | B14-06, 07, 09, 10, 11, 12 and B13-15's owner step. The Google sign-in (PL1-11) is deferred, not counted |
| Known blockers | **2** | Android signing secrets (owner); the Animal Farm 1.0 `.rar` cannot be read here (owner can re-send as .zip) |
| Items likely to ship in the next release | **7** | Section 12 A |
| Items at risk | **3** | Section 12 B |
| Items unlikely or deferred | **5** | Section 12 C |

## 1. Executive summary

**Build 13 did what its audit asked.** Every Build 12 audit defect, the four economy rules and the four remaining audit items are fixed and covered by tests:
- retirement vacancies;
- gold ore;
- medicine text;
- shop attendants;
- the CI gap;
- funds, unit pricing, seed, theft value;
- the livestock chain, Back on quantity, touch sprint, station occupancy.

Build 13 was built privately from one commit. The Android stable key is still missing, so testers must uninstall between builds.

**The current work deepens the village economy.** Since Build 13:
- **Households produce:** they forage, brew medicine and treat their own wounds.
- **Households trade from their own doorstep:** houses gain storefronts.
- **A cart chain exists:** carts have a real production chain (wheel, axle, ironwork, handcart), though carts cannot yet be used.
- **Prices respond to nearby competition.**
- **The woods are alive:** deer, wolves, foxes, bears and birds feed themselves, hunt each other, raid the hen pens and fight back.

Each is wired into existing systems (pantries, coins, stations, pens, the hunter) rather than standing alone.

**The new asset packs are mostly still on the shelf.**
- **In use:** only MiniFolks (forest animals) is in the game.
- **On the shelf:** the skeleton pack (your next task after carts), Forgotten Memories (waterfalls, fences, cliff ramps), Animal Farm (the horse) and the Craftpix plants. They are stored and credited, waiting for their tasks.
- **Two of your hopes are not in these packs:** Forgotten Memories has no cart, wagon, wheelbarrow or horse, and the skeleton download has only the sword skeleton.

**Risks:** the next big step (carts in play) is the largest piece of work left. Several packs are drawn at 32 px against the game's 16 px grid. Nothing has been played on a real phone, Windows PC or controller.

## 2. Build 12 versus now

| Area | Build 12 (`f8b4a98`) | Build 13 (`4e76f72`) | Now (`2caca5a`) |
|---|---|---|---|
| Villagers' health | Only the player bought medicine; villagers had no way to heal | Same | Hurt villagers use household medicine, or buy it from the Apothecary or a storefront |
| Household production | Cook pottage at home | Same | Also forage flowers and berries and brew poultices at the hearth |
| Selling | Merchants' stalls, the tavern, the player's stall and shops (licence and rent) | Merchants never buy without money; bulk prices per unit | Plus household storefronts (no rent, no licence), run by villagers or the player |
| Prices | Seller's own stock only | Unit by unit in bulk | Also nearby competition: many sellers lower it, a lone seller asks the scarcity price |
| Livestock goods | Pens existed; little use of eggs, milk, wool | Full chain: cheese, egg bread, cloth, bandages, tavern suppers | Same, plus foxes raid the hen pens at night |
| Woods | Boar and rabbits, hunted down to a sex-blind floor | Same | Deer, wolves, foxes, bears and birds; predators hunt; a breeding pair always remains |
| Carts | None | None | Parts and handcarts are made and traded; no use yet |
| Controls | — | Back closes only the quantity control; touch Run | A harvests and Y / T talks when a villager stands at the resource |
| Stations | Player and villager could share | Villagers wait while the player works one | Same |
| Gold | No source | One gold seam (generator v7) | Same |

## 3. Git and integration status

**Branches and history**
- Staging HEAD is `2caca5a`, plus this report's commit.
- `main` is at `3858b27`, untouched since 2026-10-18. Merging needs the owner.
- The only open PR is [verbal76/My-Medieval-Life#1](https://github.com/verbal76/My-Medieval-Life/pull/1), a draft from 2026-10-18 for the original prototype branch. It is not the integration route; staging is.
- The 11 `wip/*` branches all date from 2026-10-18, before Build 12. They are preserved snapshots of agents' work from earlier runs, since integrated by other commits. None holds unintegrated work from this cycle.

**Agents**
- No subagent is running now.
- Every item since Build 12 was done by the lead agent in this session, one task at a time, each pushed when its tests passed.

**CI on staging** (`.github/workflows/tests.yml`)

| Run | Commit | Result |
|---|---|---|
| 41 | `60a365b` | success |
| 42 | `b94dc22` | success |
| 43 | `a9c6db0` | success |
| 44 | `d01376c` | success |
| 45 | `75093bf` | success |
| 46 | `2caca5a` | queued when this was written |

Locally, every suite passed on `2caca5a` (section 11).

**Commits since Build 13** (`4e76f72..2caca5a`)

| Commit | What |
|---|---|
| `fa69227` | Build 13 packet |
| `5eeddee` | CLAUDE.md: signing secrets not set |
| `60a365b` | Harvest or talk |
| `b94dc22` | Home production and healing |
| `a9c6db0` | Storefronts |
| `d01376c` | Cart parts and handcarts |
| `75093bf` | Local-availability pricing |
| `2caca5a` | Forest animals, waypoint fix, new packs stored and credited |

**Build 13 commits** (`f8b4a98..4e76f72`): `8d5193a`, `fa269d9`, `108c04a`, `3d922f1`, `9fb459f`, `8ad0b15`, `fe555e7`, `97aea61`, `07d1170`, `2e22084`, `d4103ae`, `a29b877`, `0570f14`, `e6ba579`, `ccec9c8` and `4e76f72`.

## 4. New asset-pack inventory

"Present" means stored in the repository or in `private-assets/`. "Integrated" means drawn in play.

| Pack | Source and licence (as supplied) | Contents | Formats and size | Where stored | Imported | In play |
|---|---|---|---|---|---|---|
| **MiniFolks – Forest Animals** | LYASeeK, itch.io, name your own price. "Use as you like, don't resell"; credit appreciated | 8 side-view animals: bear, boar, two deer, fox, wolf, bunny, bird; idle, walk, jump, attack, hit, death (roar and howl); with and without outline | 16 PNG sheets (32 px frames, the bird 16 px), 8 .aseprite; 2 × .7z, 68 kB | `MiniFolks Forest Animals/` (public), extracted byte for byte (the tools read zips only) | 8 outlined sheets → `game/assets/animals/mini_*.png`, unchanged, with provenance | **Yes**: deer (stag and doe sheets), wolf, fox, bear and bird as new species; boar and bunny as extra skins |
| **Pixel Art Skeletons (free)** | MonoPixelArt, itch.io, name your own price. No licence file; terms per the page you sent | **Only the sword skeleton** (white and yellow, with and without swoosh VFX): idle, walk, attack ×2, hurt, die strips. The page's axe and shield skeletons are not in the free download | 24 PNG, 96 kB zip | `Skeletons_Free_Pack.zip` (public, root) | No | No: B14-09, after the carts |
| **Forgotten Memories 32x32 tileset** v1.0 | Immunity, itch.io, name your own price. Edit and use commercially; **no repackaging, redistribution or resale** | Grass and dirt terrain, stone-edged ramps and cliff steps, fences (4 styles), animated water and waterfalls (6 frames), trees in colour variants, stumps, rocks, bushes. **No cart, wagon, wheelbarrow or horse** (all five sheets looked at) | 5 PNG sheets (2048², 1024² ×3, 560×640); zip 537 kB plus a .rar of the same release | `private-assets/` (git-ignored) | No | No |
| **Animal Farm Project Sprite Pack** | Single Head Games, itch.io, bought by the owner 2026-10-19 ($4). Free for commercial use, may modify, **no redistribution or resale of the originals** | Top-down farm animals, 4 directions, about 96 px, walk and eating frames: calf, cow, bull, hen, chick, pig, sheep, **horse**, ram, rooster | WIP .zip 118 kB (readable); 1.0 .rar 281 kB (**cannot be read here**: no unrar tool) | `private-assets/` | No | No |
| **Free Pixel Art Plants for Farm** | Craftpix.net (free); `license.txt` links to craftpix.net/file-licenses (redistribution not allowed) | `Plants.png`: crops, vines, bushes, flowers, mushrooms in growth stages; fruit and palm trees from sapling to fruiting. `Supplies.png`: produce, seed bags, crates. PSD sources, coupon | 2 PNG + 2 PSD; zip 844 kB | `private-assets/` | No | No |

**Not verified, not installed:** nothing else was supplied in this cycle. The upload folder holds only older packs and these five. "Designing Virtual Worlds" is not in the repository or the uploads (section 9).

**Compatibility**
- **Scale:** MiniFolks (32 px frames) fits as is: animals read about one to two tiles long (screenshot looked at). Forgotten Memories and Craftpix are 32 px tiles and sprites on a 16 px grid: they need halving (detail lost) or drawing at double size (out of step with the terrain). Animal Farm (about 96 px) is far larger than the Cozy Farm livestock (16 to 24 px). **Each needs a scale decision before import.**
- **Formats:** two archives are .7z and two are .rar. The .7z packs were extracted once into the repository. The .rar files can only be read if re-sent as .zip; the Forgotten Memories .zip seems to hold the same release as its .rar.
- **Duplicates:** the MiniFolks boar and bunny overlap the Puny boar and Cozy rabbit already used. They are added as extra skins, not replacements. No byte-identical duplicates were found (the manifest's dedupe ran).
- **Credits:** all five are on the credits page (`game/data/credits.json`); run_tests checks every pack is credited.
- **Licences:** recorded per pack in `ASSET_MANIFEST.md` from the pages you provided. The three no-redistribution packs follow the private-asset workflow (CLAUDE.md section 3): only imported game files will be committed, with provenance.

## 5. Asset utilisation and gameplay value

| Pack | What it gives the player now | Interactive or decorative | Best use of what exists (not new mechanics for their own sake) |
|---|---|---|---|
| MiniFolks | Living woods: deer you can see, hunt and lose to wolves; foxes taking hens; a bear that fights back | Interactive: targets, hunting yields, the food chain, attacks on people. Collision: animals keep to their wood's cells. Saves: species saved; old saves seeded once. Unused rows: the jump, the second attack, the roar and the howl | The howl and roar could signal a hungry predator nearby (player feedback, no new mechanic) |
| Skeletons | Nothing yet | — | Planned as the guarding enemy of B14-09 (owner answers recorded) |
| Forgotten Memories | Nothing yet | — | **Strongest fit:** its stone ramps and cliff steps for B14-07 (carved steps), and its fences for the pens and fields that exist now. Waterfalls are decoration until the overworld has rivers on its plateaus |
| Animal Farm | Nothing yet | — | **The horse:** a draught animal for the plough (the wiki's "no horses or oxen" gap) and later the cart. The rooster and bull could become skins of the existing chickens and cows instead of new species |
| Craftpix | Nothing yet | — | Growth-stage art for the **existing** crops (wheat, carrot, potato, herb). Produce crates as storefront and stall displays (the storefront counter is a weak stand-in). Fruit trees fit the existing tree lifecycle (chopping included, as you asked) and would give apples a source (apples have none now: `resources.json` exception) |

**Visually present but not interactive:** none. Every new drawn asset is interactive.
**Interactive but with stand-in art:** the storefront counter (a stall table and crate), the four cart-part icons, and the handcart icon (a plank slab). These are on the sprite list for you (B14-12).

## 6. Existing mechanics strengthened

Each row separates what existed in Build 12 from what changed, and gives the evidence.

| System | Before (Build 12) | Changed (Build 13 → now) | Status | Player notices | Connections | Verification |
|---|---|---|---|---|---|---|
| NPC needs and decisions | Eat, sleep, work, evening errands | B14: evening work at home (forage, brew), self-treatment, keeping a storefront, building one, getting a cart | Implemented | Villagers gathering flowers, tending counters, walking to buy medicine | Plants, pantry, coins, stations, carpenter and smith | home_test (79), 8- and 12-day runs, coins conserved |
| Households | Pantry, firewood, home cooking | B14: medicine and berries in store, storefronts on the household's house, a household cart | Implemented | Families visibly better or worse off | Property (holds), Business, Fauna (berries) | home_test |
| Livestock and production | Pens, keepers, slaughter | B13: eggs, milk and wool collected and sold, cheese and egg bread, cloth and bandages. B14: foxes raid at night | Implemented | Bread and cheese in shops; the odd lost hen | Cook, tanner, sage, tavern, wildlife | farming_test::test_village_chain; wildlife_test::test_fox_raid |
| Markets and pricing | Stock-based price per seller | B13: no purchase without money; unit-by-unit bulk. B14: local-availability pricing; the stall ceiling ignores the buyer and the stall weighed | Implemented | Cheaper goods where several sell; dear lone items; your own stall lowers neighbours' prices | Business ceiling, storefronts, carts | business_test (155), home_test::test_local_pricing |
| Merchant finances | Merchants could take goods on credit-like trades | B13: funds rule | Implemented | Merchants refuse what they cannot pay for | Caravan, stalls | business_test, run_tests |
| Professions and chains | Smith tools; carpenter planks | B13: tanner cloth and bandages, cook cheese and bread. B14: carpenter wheels and handcarts; smith axles and ironwork | Implemented | New goods at the carpenter and smith | Households (carts), pricing | home_test::test_cart_parts |
| Crafting | 33 recipes | B14: +4 (cart wheel, axle, ironwork, handcart), shared by player and villagers | Implemented | New recipes at the sawhorse, anvil and workbench | resources.json, wiki recipe pages | check_resources (0 problems), home_test |
| Housing and property | Build, buy, lease; workshops; shops in rooms | B14: a storefront counter by a held house's door | Implemented | Build one at your door; villagers build theirs | Business, map collision, save | home_test::test_player_storefront (incl. save/load); screenshot looked at |
| Resource harvesting and scarcity | Wild plants picked by the player only; hunter's sex-blind floor | B14: villagers pick the same plants (shared scarcity); nobody takes a wood's last male or female; the hunter leaves predators a margin | Implemented | Bare bushes where villagers foraged; game that recovers | Fauna, home production | home_test, wildlife_test::test_predation, test_days |
| Stations | Shared freely | B13: villagers wait while the player works, give way after 45 min | Implemented | No villager standing in your anvil | All crafting | world_test::_station_conflict |
| Controls and interaction | Talk took priority over a resource | B13: Back on quantity, touch Run. B14: A harvests, Y / T talks; storefront choices after the door's own | Implemented | Can mine beside a villager | All targets | start_test (485 steps) |
| In-game wiki | Pages per system | Updated for each change (home work, storefronts, carts, pricing, each new animal's diet and danger) | Implemented | Accurate pages | — | wiki_test (links resolve) |

**Not changed this cycle** (Build 12 features carried forward, not counted as new): families, ageing, retirement and inheritance (apart from the B13 vacancy fix), locks and theft (apart from B13 theft value), crime and guards, construction and furniture, long-run save format (`SAVE_VERSION` 14 unchanged; the new data is additive).

## 7. Genuinely new mechanics

| Mechanic | Purpose | Player interaction | Depends on | Status | Readiness |
|---|---|---|---|---|---|
| Harvest-or-talk (B14-01) | A villager at a resource never blocks harvesting | A harvests; Y / T / tap talks | Target list, prompts | VERIFIED (headless) | Ready; needs a controller check |
| Home production and self-treatment (B14-02) | Households make and use their own food and medicine | You see it; shared plants | Plants, pantry, hearths, Apothecary | VERIFIED | Ready |
| House storefronts (B14-03) | Households sell surplus from home | Build and run your own; buy at villagers' | Property, Business, collision, saves | VERIFIED | Ready; counter art is a stand-in |
| Cart parts and handcarts (B14-04) | A real multi-trade production chain | Craft or buy parts; buy or assemble a cart | Carpenter, smith, workbench, pricing | VERIFIED | Ready as goods; **no use until B14-06** |
| Local-availability pricing (B14-05) | Prices reflect nearby competition | Trade dearer or cheaper; flood a market | All selling | VERIFIED | Ready; numbers provisional |
| Predator–prey food chain (B14-08) | Woods run themselves | Watch, hunt, defend yourself, lose hens | Fauna, pens, plants, combat, saves | VERIFIED (20-day run) | Ready; tuning provisional (predators run near starvation) |

These are not new mechanics:
- **Visual and content:** the MiniFolks skins on boar and rabbit, and the new icons.
- **Fix:** the waypoint fix (`2caca5a`).
- **Balance:** the storefront coin threshold.

## 8. Agent workstreams

No subagent is active. Earlier `wip/*` agent snapshots predate Build 12 and are not open work. Everything below is the lead agent's queue.

| ID | Task | Status | Done | Remaining | Dependencies | Tests needed | Blockers |
|---|---|---|---|---|---|---|---|
| B14-06 | Carts in play: pulled storage (slower walking), parking at home or a hub, hubs and deliveries, use by owner, family or hired help only, mine-cart stand-in art | PLANNED (owner-approved, next) | Carts exist as goods | All of it | B14-04 | Movement, storage, ownership, save, NPC delivery runs | None |
| B14-07 | Carved steps (pickaxe, Mining), wooden stairs (planks, nails, Carpentry, a mallet), walkways between raised edges | PLANNED (owner answers recorded) | — | All | Overworld cliffs (`overworld.gd`), recipes | Pathing onto plateaus, save of built steps | Scale of the Forgotten Memories ramps if used |
| B14-09 | Skeletons guarding caves (new cave mouths in cliffs) and dense outer forest; guard by day, roam at night; 3-day respawn; coins and rusty gear | PLANNED (owner answers recorded) | Pack stored and credited | All | Overworld generation (a version bump: save handling per CLAUDE.md section 6) | Combat, spawning, respawn, determinism | Only the sword skeleton exists, so the axe and shield variants need the paid pack |
| B14-10 | Craftpix plants: crop stages, produce, crates, fruit trees chopped like the others | PLANNED (questions first) | Stored, credited | All | Scale decision | Farming, tree lifecycle | 32 px vs 16 px |
| B14-11 | Animal Farm: the horse and farm animals | PLANNED (questions first) | WIP zip stored | All | How horses are used (plough, cart, riding) | — | 1.0 is .rar |
| B14-12 | Sprite list with pixel-grid copies for Aseprite | PLANNED | — | All | — | Looked at | None |
| B13-15 | Android stable test key | BLOCKED (owner) | Checked missing | Owner adds 3 secrets | — | A signed release run | Owner action |
| PL1-11 | Google Drive cloud saves | DEFERRED | — | — | Owner's OAuth app | — | Owner setup (not a blocker) |

## 9. Build 12 audit corrections

All checked against the code at `2caca5a`. No regressions found.

| Item | Fix | Evidence | Still holds now |
|---|---|---|---|
| Retirement vacancies | `3d922f1` | run_tests vacancy checks | Yes |
| Apothecary and medicine text | `9fb459f` | start_test effects text | Yes |
| CI coverage and always-true tests | `fe555e7` | tests.yml; health_jobs_test | Yes; CI also gained home_test and wildlife_test |
| Shop attendants hired away | `8ad0b15` | business_test | Yes |
| Merchant affordability | `07d1170` | business_test | Yes |
| Sequential bulk pricing | `07d1170` | `World.player_quote` tests | Yes; now with local supply in each unit's price |
| Seed supply | `07d1170` | farming_test | Yes |
| Theft by items and value | `07d1170` | run_tests | Yes |
| Gold ore | `97aea61` | world_test | Yes |
| UI text and documents | `2e22084` | wiki_test, text checks | Yes |
| Eggs, milk and wool | `a29b877` | farming_test::test_village_chain | Yes; fox raids now take some hens (bounded by keep) |
| Controller quantity cancel | `0570f14` | start_test (headless) | Yes; not on a real pad |
| Touch sprint | `0570f14` | start_test (headless) | Yes; not on a phone |
| Player and NPC station conflicts | `e6ba579` | world_test::_station_conflict | Yes |

**Partial:** none of the code fixes. The Android stable key is still the owner's step.

## 10. Economy and interlocking systems

| Check | Verdict | Evidence |
|---|---|---|
| Resources have identifiable sources | Yes, with one known gap: apples have no source (recorded exception; Craftpix fruit trees could fill it) | `tools/check_resources.py`: 24 nodes, 0 problems |
| Production consumes real inputs | Yes: cart parts, poultices, storefront materials, all from inventories | home_test |
| Households and businesses use real inventories | Yes: pantry, packs, shop stock | home_test, business_test |
| Purchases need real money | Yes: every new purchase goes through `World.trade` / `buy_from` | Coins conserved in the 8-, 12- and 20-day runs |
| Producers have customers | Mostly. **Handcarts have customers but no use** until B14-06 (recorded exception in `resources.json`) | `resources.json` exceptions |
| Prices respond to conditions | Yes: own stock, unit by unit, and now nearby supply | test_local_pricing |
| Professions depend on one another | Yes: carpenter ↔ smith (cart parts); households ↔ carpenter and smith (storefronts, carts); sage ↔ storefronts (medicine competition) | INT-142 to INT-144 |
| Scarcity changes behaviour | Yes: shared wild plants, predators held by prey numbers, hunters leaving a margin | wildlife_test |
| Goods have destinations | Yes, except handcarts (above) and feathers (sold to the goods merchant, no recipe) | resources.json |
| Businesses can succeed or fail | Storefronts depend on household surplus. Failure (closing for lack of trade) is not modelled for villager storefronts; they simply have nothing to sell | Gap, noted |
| The player follows the same rules | Yes: the same recipes, prices, storefront cost and station rules. One difference: villagers have no skill levels for crafting, while the player needs the level; all four cart recipes are level 1 | recipes.json |

**Interlocking Systems Manifest** (`docs/SYSTEM_INTERACTION_MANIFEST.md`):
- **Size:** 136 interactions at Build 12, 139 at Build 13, 145 now.
- **New entries:** INT-140 (harvest or talk), INT-141 (home production), INT-142 (storefronts), INT-143 (cart parts), INT-144 (local pricing), INT-145 (the food chain).
- **Validation:** `tools/check_interactions.py` reports 0 problems.
- **Undocumented dependency:** the waypoint fix in `main.gd::_route_step` changes no interaction, so it needs no entry.

**World rules:**
- No document is called "World Design Rules". The permanent rules live in `CLAUDE.md`, `docs/MEDIEVAL_LIVING_WORLD_SYSTEM_DESIGN.md` and the compliance table in `docs/LIVING_WORLD_ALIGNMENT.md`. The new work follows them: real sources, real money, the same rules for the player, nothing from nowhere.
- `LIVING_WORLD_ALIGNMENT.md` has no B14 compliance rows yet. That is a documentation gap to fill at release time.

**Designing Virtual Worlds** (Bartle): **not in the repository and not uploaded.** No document cites it, so it has not been incorporated into planning. If you want it used, a summary of its economy chapters or the file itself would be needed.

**Exploits and gaps found**
- **Flooding with your own stock.** Your stall stock lowers villagers' prices nearby. You could stock a stall to drive a rival's price down, then buy from the rival. The gain is bounded by `local_supply.cap` (at most half the value), and the stall ceiling leaves your own stall out of its own comparison. Low risk; worth watching.
- **Storefront progress is coin-driven only.** "Industrious" means having 150 coins of their own.
- **Thin margins in the woods.** Predators sit close to starvation in 20-day runs: 5 wolves and 5 foxes starved, while the predator populations survived. Fine for now, provisional.

## 11. Testing and platform readiness

**Automated, all on `2caca5a`, all 0 failures:**

| Suite | Build 13 | Now |
|---|---|---|
| run_tests | 3,515 | 3,524 |
| start_test | 478 steps | 485 steps |
| business_test | 154 | 155 |
| home_test (new) | — | 79 |
| wildlife_test (new) | — | 50 |
| world_test | 116 | 116 |
| farming_test | 155 | 155 |
| play_test | 37 | 37 |
| aging_test | 101 | 101 |
| chests_test | 72 | 72 |
| overworld_test | 101 | 101 |
| tree_test | 45 | 45 |
| property_test | 62 | 62 |
| health_jobs_test | 37 | 37 |
| wiki_test, skills_test, furniture_test | pass | pass |
| Python unit tests | OK | OK |

`check_resources.py` and `check_interactions.py` both report 0 problems.

**Changed tests:**
- business_test restock: the stall is now priced at the local market, and a check was added that a dearer stall loses the sale. This is the new rule, not a weakening.
- start_test bandit and tanner steps: positions are now chosen independently of the random seed.
- run_tests credits: the MiniFolks folder joins the checked folders.

No test was removed or skipped.

**Untested or weakly tested:**
- Real devices: none.
- The MiniFolks bunny and bird animation rows are uncertain (recorded in BUILD_DECISIONS).
- Villager storefronts have no "fails" path to test.

**Saves:**
- `SAVE_VERSION` 14 is unchanged; storefronts, carts as items and `fauna.seeded` are additive.
- Older saves gain the new animals once (wildlife_test::test_save).
- Build 13 saves load.

**Performance:**
- Local pricing loops over villagers once per price check. Measured: home_test 73 s → 78 s (about 7%).
- Wildlife adds work only for animals near the player, plus an hourly roll.
- No device profiling.

**Platforms:**
- Android: the throwaway signing key is still in use (B13-15). The 32 px packs would add memory if imported unscaled.
- Windows and Linux: no new issues found; only the Build 13 Linux title screen was seen, under a virtual display.
- Steam Deck: untested.
- Controller and touch: headless input simulation only.

## 12. Forecast for the next release

**A. Expected to ship** (verified and integrated):

| Item | Status | Remaining | Risk | Confidence | Why |
|---|---|---|---|---|---|
| Harvest or talk | VERIFIED headless | A controller check | Low | HIGH | Tested, small |
| Home production and healing | VERIFIED | None | Low | HIGH | Multi-day runs |
| Storefronts | VERIFIED | Better counter art (optional) | Low | HIGH | Save/load tested |
| Cart parts and handcarts (as goods) | VERIFIED | — | Low | HIGH | Tested; their use is B14-06 |
| Local pricing | VERIFIED | Tuning | Low | HIGH | Tested both ways |
| Forest animals | VERIFIED | Tuning | Medium | HIGH | 20-day run; balance provisional |
| Waypoint overshoot fix | VERIFIED | — | Low | HIGH | start_test |

**B. Possible but at risk:**

| Item | Status | Remaining | Dependencies | Risk | Confidence | Why |
|---|---|---|---|---|---|---|
| Carts in play (B14-06) | PLANNED, next | Everything: pulling, storage, parking, hubs, deliveries, ownership, saves | B14-04 | High (largest piece) | MEDIUM | Next in your order, but large. Without it, carts are goods with no use |
| Cliff steps, stairs, walkways (B14-07) | PLANNED | All, plus a scale choice for ramp art | Overworld | Medium | MEDIUM | Bounded, design answered |
| Skeletons (B14-09) | PLANNED | All, including generated cave mouths | Overworld generator bump, combat | Medium-high | MEDIUM | Answers in hand; generator change needs care with saves |

**C. Unlikely or deferred:**

| Item | Why | Confidence it slips |
|---|---|---|
| Craftpix crops, produce, crates, fruit trees (B14-10) | Questions and a scale decision first; touches farming and trees | MEDIUM |
| Animal Farm horse and animals (B14-11) | Use of horses undecided; 1.0 unreadable | HIGH |
| Forgotten Memories waterfalls and fences | No task yet; 32 px | HIGH |
| Google Drive saves (PL1-11) | Deferred pending owner OAuth | HIGH (deferred) |
| Stable Android signing | Owner's secrets | Depends on owner |

No dates or percentages are given: the evidence does not support them.

## 13. Risks and blockers

1. **Carts in play is large.** It touches movement, inventory, ownership, saves and NPC routing at once. It is the riskiest remaining item and blocks the carts' purpose.
2. **Scale mismatch.** Four of the five new packs are 32 to 96 px against a 16 px game. Importing without a rule risks a patchwork look.
3. **No device testing.** Touch, pad and phone performance are verified headless only.
4. **Android signing** is still a throwaway key: every build is an uninstall, and the tester loses their save.
5. **Tuning debt:** wildlife, storefront and pricing numbers are provisional agent proposals; predators run close to starvation.
6. **Scope growth:** six asset-driven features arrived during one cycle. Each is reasonable, but together they push carts and cliffs back.

## 14. Recommended priorities

- **Finish first:** carts in play (B14-06). It completes the storefront → cart → market loop you described, and turns three finished systems into one.
- **Then:** the cliff access (B14-07), using the Forgotten Memories ramps if the scale works. It fixes a real playtest problem.
- **Prefer strengthening over adding:**
  - Craftpix growth stages for existing crops and crates for existing storefronts.
  - The Animal Farm rooster and bull as skins.
  - The horse first as a plough animal (an existing gap) before anything new.
- **Decide the scale rule once** (halve, or keep 32 px for large objects only) before importing the 32 px packs.
- **Hold back:** the waterfalls (decorative until rivers reach plateaus) and new crop species beyond the existing four.

**Five accomplishments**
1. All Build 12 audit findings fixed and verified.
2. Households now produce, heal and sell for themselves.
3. Prices respond to nearby competition.
4. A real cross-trade production chain (carts).
5. Self-sustaining woods with predators.

**Five opportunities**
1. Carts in play.
2. Horses as draught animals.
3. Crop growth art.
4. Crates and produce on storefronts.
5. Apples from fruit trees.

**Five technical risks**
1. Cart movement and saves.
2. The overworld generator change for caves.
3. Scale and memory on Android.
4. Untested devices.
5. Provisional balance.

**Most underused new assets:** Forgotten Memories (the ramps and fences have obvious uses); Craftpix crop stages and crates.

**Most emergent systems:** the food chain (wolves, deer, hunters, hens); local pricing combined with storefronts; household medicine combined with storefront competition with the Apothecary.

## 15. Feature-by-feature ledger

The authoritative ledger is `docs/DEVELOPMENT_LEDGER.md`: rows B13-01 to B13-15 and B14-01 to B14-12. The B14 rows were added with this report; they were owed and were missing.

| ID | Item | Status | Evidence |
|---|---|---|---|
| B13-01 – B13-14 | Build 12 corrections, economy rules, livestock, controls, stations | VERIFIED (12 and 13 headless) | Commits in section 9 |
| B13-15 | Android stable key | BLOCKED (owner) | BUILD_13_PACKET.md |
| B14-01 | Harvest or talk | VERIFIED (headless) | `60a365b` |
| B14-02 | Home production and healing | VERIFIED | `b94dc22` |
| B14-03 | Storefronts | VERIFIED | `a9c6db0`, `d01376c` |
| B14-04 | Cart parts and handcarts | VERIFIED | `d01376c` |
| B14-05 | Local pricing | VERIFIED | `75093bf` |
| B14-06 | Carts in play | PLANNED | — |
| B14-07 | Cliff steps, stairs, walkways | PLANNED | — |
| B14-08 | Forest animals | VERIFIED | `2caca5a` |
| B14-09 | Skeletons | PLANNED | — |
| B14-10 | Craftpix plants | PLANNED | — |
| B14-11 | Animal Farm | PLANNED | — |
| B14-12 | Sprite list with pixel grids | PLANNED | — |
| PL1-11 | Cloud saves | DEFERRED | Owner OAuth |

## 16. Evidence and limitations

**Evidence**
- Git history: `f8b4a98..2caca5a`.
- CI runs 39 to 46 of `tests.yml` (run 46 queued at writing).
- Local test runs on `2caca5a`.
- `docs/DEVELOPMENT_LEDGER.md`, `docs/DECISIONS.md` and `docs/SYSTEM_INTERACTION_MANIFEST.md`.
- `game/data/resources.json` with `tools/check_resources.py`.
- `ASSET_MANIFEST.md`, `game/data/credits.json` and `game/assets/PROVENANCE.json`.
- The pack archives themselves, opened, and their sheets looked at.
- The screenshots looked at: storefront, woods.
- The pack pages you sent.

**Limitations**
- No device or controller testing.
- The .rar files were not opened.
- Pack licences come from the pages you supplied, not from licence files, except Craftpix (a link only).
- No live subagent status exists, because none ran.
- Balance numbers are untested beyond 20 game days.

## What will actually feel different when I play the next release?

**Already working (verified):**
- You can mine or pick flowers right next to a villager; Y (or T) talks to them instead.
- Villagers pick flowers and berries in the evening. Bushes they strip are bare for you too, until they regrow.
- Hurt villagers patch themselves up with poultices, or walk to the Apothecary or a neighbour's storefront to buy one.
- Some houses grow a little counter by the door, where a family member sells spare poultices and berries in the evening. You can build one at a house you own: 6 planks and an iron bar, no rent.
- The carpenter sells cart wheels and the odd handcart; the smith sells axles and ironwork. You can make all four yourself.
- Prices differ around the village: cheaper where several people sell the same thing, dear where only one does. Selling a lot of something yourself pulls the price down.
- The woods have deer (stags with antlers), foxes, wolves, birds and a pair of bears in the west wood. Wolves chase deer, and foxes sometimes take a hen from the pens at night. Hit a wolf or a bear and it fights back. A starving one may come for you if you are alone in its wood.
- Walking to a tapped target no longer gets stuck shuffling on the spot.

**Expected but not built yet:**
- Pulling a handcart, parking it, and cart hubs.
- Climbing onto plateaus.
- Skeletons at cave mouths.

**Probably later:**
- The new crop art, crates, fruit trees and the horse.
