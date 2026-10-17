# J. Open decisions, contradictions and research gaps

Part 1 lists the decisions that need the owner. Each has options and a recommendation, and nothing
here is decided. Part 2 lists the novel's contradictions that need a design ruling. Part 3
covers what the research has not done. Part 4 corrects the two supplied research documents. The
full list of 147 unresolved evidence records (16 answered later in the novel) is
`J2_UNRESOLVED_REGISTER.md`.

## Part 1. Decisions for the owner

### World and history

| ID | Decision | Options | Recommendation |
|---|---|---|---|
| J-D1 | **Era the game is set in** (D §2) | E1 before Ralph's quest. E2 the homecoming war. E3 Ralph's reign, a few years after the homecoming. E4 generations later, with Ralph and Ursula dead and the tale itself old history. | **E3 or E4.** Both keep the novel as the world's history (Directive §15) and avoid the player re-living Ralph's story. E3 keeps the canonical cast alive as NPCs. E4 gives the most freedom. E1 and E2 put the player beside the "chosen" hero. |
| J-D2 | **Starting county location** | G: C1 west of Upmeads, C2 east road, C3 Down-foot vale, C4 west of the Wood Perilous, C5 Whitwall plain | C1 or C4 (G gives the reasons) |
| J-D3 | **County's political status** | an independent lordship; a lordship under King Peter or Ralph of Upmeads; an abbey holding of Higham; a march between powers | Depends on J-D2. An independent lordship with ties to a canonical neighbour keeps the most freedom. |
| J-D4 | **Naming unnamed canonical figures** (the Abbot of Higham, the King of Cheaping Knowe, the bishop-baron and others) | keep them as titles; give them invented names marked GAME EXPANSION | Keep titles in canonical text; allow invented names only in game-facing data with an `expansion` flag |
| J-D5 | **Original places inside canonical regions** (more villages in Upmeads, more towns near Whitwall) | allowed anywhere that breaks no hard constraint; only outside named polities | Allowed where they break no hard constraint and do not change a named polity's described character (e.g. Upmeads has no city, castle or abbey) |

### Geography and generation (H)

| ID | Decision | Options | Recommendation |
|---|---|---|---|
| J-G1 | Map scale | S1 true scale, S2 compressed, S3 hybrid | S3 hybrid, decided after a prototype |
| J-G2 | Unit conversions and direction tolerance | H §4 defaults (league = 3 miles, a day's ride = 25–40 miles, ±60° compass tolerance) | accept as defaults, tune by testing |
| J-G3 | Store the world atlas in the save | stored (stable worlds) or regenerated (smaller saves) | **stored** (CLAUDE.md §7) |
| J-G4 | **Visual direction and existing assets** | The owner's directive sets 2D/2.5D isometric with 8-direction sprites. `docs/GAME_DESIGN.md` P2 had proposed top-down orthogonal because the repository's terrain and building tiles are drawn orthogonal. | Isometric is now the working requirement. Decide whether the current packs are used as-is (for prototyping), re-projected, or replaced for isometric terrain. This affects the asset pipeline, not the world data. |
| J-G5 | Geography beyond the text's edges (north of the bishop-baron, south of the "good town", the far east past Sarras) | leave unexplorable; generate original lands | generate original lands, labelled Original |

### Magic (MAGIC_RESEARCH)

| ID | Decision |
|---|---|
| J-M1 | Energy or capacity source for magic |
| J-M2 | Whether Morris-style lore (foresight, sendings, semblance, beast-craft) is learnable, and how far |
| J-M3 | Whether the Well is reachable in play and what drinking does mechanically. Recommendation: rare and late, never a progression requirement. |
| J-M4 | Legal and religious risk for practitioners by region (the text shows sorcery trials) |

### Content and systems

| ID | Decision |
|---|---|
| J-S1 | Thralldom is central to the Burg, Utterbol, Cheaping Knowe and the thrall markets. How much of it the game depicts, and how. |
| J-S2 | Which P1 systems in I are in the first playable scope |
| J-S3 | Reputation in multiplayer: shared by the party, or per player |

## Part 2. Contradictions in the novel that need a ruling

These are in the text itself. The generator and writers need one reading each. The proposed
rulings are GAME EXPANSION choices, and the novel's wording stays recorded as written.

| Contradiction | Evidence | Proposed ruling |
|---|---|---|
| The Dry Tree on the "hither" or "further" side of the Wall of the World | BTWO-C14 vs BTWO-C16; narration places it beyond the Great Mountains (BTHREE-C18) | Follow the narrated journey: beyond the Great Mountains |
| The sun "sets beyond them" over the sea at the World's End after an eastward journey | BTHREE-C20 | The ness juts so the sea lies west of the point as well as east; or treat it as Morris's poetry. The generator keeps the Ocean Sea to the east overall. |
| The epilogue calls the Lord of Utterbol "Bull Nosy" | BFOUR-C32 vs BFOUR-C3 | Document error: Bull Shockhead |
| Five leafless-tree prisoners (BONE-C8) or four (BONE-C12, C15) | | Four were held for hanging and freed by the lady, who says she freed four of her people (BONE-C22). The fifth is unaccounted for. |
| Agatha's "Burnt Rock" and "Red Rock" | BTHREE-C1 | Her own lie; no place |
| Sunhome or Sunway for the Knight of the Sun's home | BONE-C22 vs BONE-C24 | One place, Sunway; Sunhome is an alias |
| Twenty-three or twenty-two Garton spearmen | BFOUR-C23 vs C24 | One man lost or left; no ruling needed |
| "Nearly two years" without news, against a story that seems shorter | BFOUR-C26 | Treat the quest as about two years long |
| The Westland Barons and the Banded Barons | BFOUR-C21, C19 | One league |
| The "Eastland wood" where Ralph and Ursula met | BFOUR-C32 | An epithet for the Wood Perilous region |
| Whose tale is true about Hampton and the Burg (each side calls the other robbers) | BONE-C9 to C11 | Both are partial; present them as rival claims |

## Part 3. Research gaps and remaining verification

Done: all 119 chapters (2,412 body paragraphs) read in context, one chapter at a time. Every
extracted claim has a quote, checked as an exact substring by script (0 failures). Gutenberg
material is excluded by recorded line boundaries (0 leaks). Registries are merged with stable
ids, and the generated documents are tested.

Not done, or limits:

1. **Citation coverage is 1,102 of 2,412 body paragraphs (46%).** Every paragraph was read, but
   only these gave a record. Uncited paragraphs are mostly dialogue and description already
   captured. A second pass over uncited paragraphs (`research/registries/checks.json`, list
   `chapters_below_50pct_cited`) could add minor details: flora, food, clothing, household goods.
2. **Material culture is thin** compared with politics and magic: 11 food, 5 clothing,
   8 household and 9 weapons facts. A targeted second pass is recommended before item design.
3. **82 implicit entities** (named in a relation or journey only) have no description of their
   own.
4. **3 duplicate candidates** await review (CHECKS.md). All other identity links are in
   `merges.json`.
5. **Unplaced places**: 106 place-like entities have no spatial statement. The generator places
   them by association (H §3.1).
6. **No second reader.** The extraction was a single reading, so errors of judgement (wrong
   classification, a missed statement) are possible. Corrections go in the chapter notes and are
   rebuilt by script.
7. **Ralph's journey times** are not fully reconciled into one calendar (Timeline F lists the
   time words as written).

## Part 4. Errata: the supplied research documents

The two documents in `research/sources/` are high-recall keyword indexes, as they say themselves.
Checked against the novel (`research/corpus/gazetteer_audit.json`, `document_audit.json`):

| Document claim | Finding | Correction |
|---|---|---|
| "2,415 source paragraphs" | The tale has 2,412 body paragraphs. The documents also index three chapter-title lines (BTWO-C7, C13, C19 P001). | 2,412 body paragraphs plus 119 titles |
| Seed gazetteer entries **Long River**, **Sundering Flood**, **City of the Five Crafts**, **Wood of Evil**, **Castle of the Quest** | Not in this novel (0 occurrences) | Remove. They are not canon here; *The Sundering Flood* is the title of a different Morris romance. |
| **Sea of Molten Rocks**, **Thirsty Desert**, **Red Pavilion**, **Wood Under the Mountain(s)**, **Down Country** reported with 0 or few hits | They are Morris's chapter-title names; the body text uses other wording ("rock-sea", "the waste") | Canon, as chapter-title names |
| **Cheaping-Town** as a separate town | Chapter title BONE-C3 for Wulstead | Same place as Wulstead |
| **Dry Tree** typed "landmark / settlement" | It is a tree (a landmark beyond the Great Mountains), a badge, and the name of a fellowship. It is not a settlement. | Landmark and fellowship |
| **Four Friths** as a "regional landscape" | Only part of the name "Burg of the Four Friths" | Not a separate place |
| **Utterbol** typed "city" | A lordship and its House; no city is described | Lordship and House |
| Common nouns (Wilderness, Waste, River, Bridge, Mountain, White Horse, Swan, Wells) in the gazetteer | Not names | Resolved into specific named or unnamed features in the gazetteer (B) |
| "St. John's by the Bridge" 0 hits (curly apostrophe) vs 1 hit | Apostrophe variant | One place, BONE-C1 |
| Category membership in the lore extraction | Keyword hits, as the document warns | Superseded by the paragraph-cited registries |

No paragraph text in the documents differs from the novel except the three title lines (document
audit: 2,362 exact matches of 2,365 compared).
