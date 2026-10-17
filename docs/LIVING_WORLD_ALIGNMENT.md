# Living world design: alignment review

Review of `docs/MEDIEVAL_LIVING_WORLD_SYSTEM_DESIGN.md` (v0.1, supplied by the owner on
2026-10-17) against the repository, as its §18 asks: what exists, what is proposal, where it agrees
or conflicts with earlier documents, and what the owner needs to decide. **No code was written.**
That document says it is design intent, not an implementation order. Implementation is also
blocked by Gate A (engine and platform) in `docs/DEVELOPMENT_PLAN.md`.

## 1. What exists today

| Living-world module (doc §13) | In the repository | Notes |
|---|---|---|
| Catalogs (resources, items, recipes, skills, professions, workstations) | None | Item icons exist as art only (`ASSET_MANIFEST.md`) |
| Inventory and ownership | None | |
| Production | None | |
| World resources (deposits, geography) | **Partly**: `tools/puny_terrain.py` and related generate terrain, rivers, roads, bridges and settlement *sites*; `research/registries/worldgen_constraints.json` holds the literary geography | No deposits, soils or resource layers yet |
| Economy | None in code. Canon evidence is catalogued in `docs/world/E_ECONOMY.md` | |
| NPC agency | None | |
| Logistics | Roads exist in generated maps | No routes, carts or shipments |
| Social and legal | None in code. Canon law profiles by place in `docs/world/I_GAME_SYSTEMS.md` #5 | |
| Simulation scheduler | None. Proposed rings in `docs/world/H_WORLD_GENERATOR_SPEC.md` §7 | |
| Persistence and network | Proposal only: `docs/ARCHITECTURE.md` §3.7 (save v1 = seed + player + changes) | Too small for a living economy (§3 below) |
| Presentation | Animation and building data (`data/`), no engine | |

Everything the document describes is therefore **proposal**, apart from the items listed in §2.

## 2. Recorded as owner direction

The document's "Established design intent" (its §2) is recorded in `docs/DECISIONS.md` and
`docs/GAME_DESIGN.md` (Confirmed item 12):

- A robust, interdependent resource and production economy, where resources and currency actually
  move.
- Persistent NPC lives, occupations, inventories and finances, with persistent consequences when
  NPCs are robbed or killed.
- Productive and criminal paths, not only combat.
- Host-owned worlds that pause when closed (already Confirmed 10).

Its "Proposals requiring decisions" (§2) and "Questions for future design reviews" (§17) stay
**open**. `GAME_DESIGN.md` U20 points to them rather than copying them.

## 3. Agreement and tension with earlier documents

| Topic | Earlier document | Living-world doc | Resolution |
|---|---|---|---|
| Simulation levels | H §7 rings: Active / Near / Far / Stopped | §11 tiers: Detailed / Abstract / Dormant | Same idea. Adopt the doc's tier names; H's "Near" and "Far" are two schedules inside "Abstract". H §7 now says so. |
| Saves | ARCHITECTURE §3.7: seed, player and `world_changes` only | §12: persistent NPCs, items, containers, jobs, shipments, offers, contracts | The v1 save layout cannot hold this. A world save must store entity state, as H §6 already proposes for the atlas. ARCHITECTURE §3.7 needs a revision once the engine is chosen. |
| Determinism | CLAUDE.md §6: same inputs, same output | Not mentioned | Simulation ticks should also use seeded RNGs and ordered processing, so tests and golden scenarios replay exactly. Recommended, not yet a rule. |
| Households and inheritance | I_GAME_SYSTEMS #1 rates them P1 | §8: births, aging and inheritance are expansion, not before the economy is stable | Follow the doc. #1 in I is narrowed to households and status; generational systems wait. |
| First playable | DEVELOPMENT_PLAN M1–M2: movement, collision, save; no mechanics | §14: economy vertical slice | The slice is a candidate **M3**, after Gate A and owner approval of the mechanics. |
| Platform | ARCHITECTURE §2 leans Android | §17 Q10 mentions **Steam Deck** | A hint that desktop or handheld PC matters. U1 is still open; not treated as a decision. |
| Crime and thralldom | J-S1 (how to depict thralldom) | §10: theft, robbery and murder allowed "where appropriate to the game's rating" | Rating and content policy is a new owner question (U21). |
| Magic | MAGIC_RESEARCH: a learnable discipline | Not mentioned | Compatible. Practitioners fit the doc's profession, recipe-knowledge and teacher model (§7). |
| Economy numbers | E_ECONOMY: the novel gives no prices or exchange rates | §9: bounded price model; conservation question open | Compatible. All prices and rates will be GAME EXPANSION. |

## 4. Fit with the Morris canon (industries)

Evidence for the doc's industry families (§4) in *The Well at the World's End*. Quotes are in
`research/registries/facts.json`. "None found" means the reading recorded nothing. It does
**not** mean the novel forbids it.

| Industry | Canon evidence | Where |
|---|---|---|
| Animal husbandry, textiles | down fleeces bought by Clement; "Upmeads cannot raise such wool" (BONE-C3); shepherds of the Downs; Wheat-wearer women weave figured silk (BONE-C14); Ursula's needlework and furs (BTHREE-C11); the cloth trade of Higham's clothiers and webbers | the Downs, Higham, the Burg |
| Agriculture | vineyards, orchards and cornfields south of Higham (BONE-C7); wine, oil, wheat, cattle and sheep in the eastern lands (BTWO-C19); meal, fleeces and herds gathered from the Dale of the Tower (BTWO-C39) | Higham-land, the eastern lands |
| Metallurgy and mining | metals and gems mined from the eastern mountains (BTWO-C19); the armourer's shop of St. Loy (BONE-C12); Clement the Black "handy in the smithy" (BONE-C1); tinsmiths and coppersmiths (BONE-C6). No iron mine in the western lands is recorded. | the eastern mountains, the Burg, Higham |
| Leatherworking | shoe-smiths, glovers, horners (BONE-C6); jacks over leather (BONE-C9) | Higham |
| Masonry and carpentry | masons enlarging the Burg's master church (BFOUR-C18); timber frame-houses and a growing market in the Dale of the Tower (BFOUR-C3); Whitwall's new church and walls | the Burg, Whitwall, the Dale |
| Rope and cordage | Roger "of the Rope-walk" | the Burg |
| Food and brewing | island wine at Wulstead (BONE-C4); feasting and guesting throughout | |
| Gathering | fowlers and peat-cutters in the waste (BFOUR-C7) | Utterbol's lands |
| Trade and transport | chapmen's armed caravans, safe-conducts, tolls to the Dry Tree's Bailiff (BTWO-C14), licences, markets at Higham and Whitwall, imports of Babylon silk, island spices and cloth sealed by great cities (BTWO-C14) | everywhere |
| Forestry and charcoal, fishing, herbalism, ceramics | none found | open to GAME EXPANSION |

**Implication for the §14 vertical slice.** The miner→smith loop works anywhere as GAME EXPANSION.
An iron deposit in the original starting county is an **Original** feature and contradicts no
canon. The best canon-grounded alternative is a **wool loop**: down sheep → fleece → cloth → a
chapman buyer. It uses the novel's own Downs and Clement's trade. The slice stays as the owner wrote
it unless the owner prefers the wool variant (U20).

## 5. New owner questions

Added to `docs/GAME_DESIGN.md`:

- **U20 Living-economy decisions**: the doc's §2 proposals and §17 questions, including the slice
  variant (iron or wool).
- **U21 Content rating and crime depiction**: theft, murder, banditry, and thralldom (with J-S1).

## 6. Recommended next steps (once Gate A opens)

1. Revise ARCHITECTURE §3.7 into a world-state save (entity families from doc §12), with the
   conservation and transition tests of doc §12 and §14 as acceptance tests.
2. Plan M3 as the doc's Phase A + B: catalogs, inventory, ownership, time, transactions, and then
   one end-to-end loop in the original county. Keep it headless-testable (doc §13).
3. Keep catalogs data-driven JSON with `format` fields (CLAUDE.md §4), validated at load. Tag
   canon-derived goods with registry ids, so lore and economy stay linked.
