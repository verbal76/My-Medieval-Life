> **HISTORICAL LITERARY RESEARCH — NOT BINDING GAME CANON OR DESIGN (owner, 2026-10-27).** William Morris source research is retained as literary evidence and possible inspiration, not the specification for the already developed My Medieval Life. Names, geography, maps, history, political systems, magic and novel events do not become required game content without new, explicit owner approval. Consult the current register and directives. Research text below is preserved for provenance.

# World knowledge base: *The Well at the World's End*

The research foundation for *My Medieval Life*'s world, built from a complete, chapter-by-chapter
reading of William Morris's novel (1896). Every canonical claim is traceable to a paragraph of the
novel and a verbatim quote.

## Deliverables

| | Document | Kind |
|---|---|---|
| A | [Encyclopedia](A_ENCYCLOPEDIA.md): people, groups, beings, items, texts, customs | generated |
| B | [Gazetteer](B_GAZETTEER.md): every place and feature, with all map constraints and certainty | generated |
| C | [Relationship graph](C_RELATIONSHIPS.md), plus `research/registries/graph.json`; the spatial graph is `research/registries/worldgen_constraints.json` | generated |
| D | [Political and faction atlas](D_POLITICAL_ATLAS.md): by region and by era | hand-written |
| E | [Economy and material culture](E_ECONOMY.md) | generated |
| F | [Timeline](F_TIMELINE.md): main story, backstory, legend, prophecy, rumour, epilogue | generated |
| G | [Starting county candidates](G_STARTING_COUNTY_CANDIDATES.md), **not finalised** | hand-written |
| H | [World generator specification](H_WORLD_GENERATOR_SPEC.md) | hand-written |
| I | [Game-system register](I_GAME_SYSTEMS.md) and [raw opportunity notes](I2_OPPORTUNITY_NOTES.md) | hand-written / generated |
| J | [Open decisions, contradictions, gaps and errata](J_OPEN_DECISIONS.md) and the [unresolved register](J2_UNRESOLVED_REGISTER.md) | hand-written / generated |
| | [Magic research register](MAGIC_RESEARCH.md): Morris's supernatural material, kept apart from the learnable-magic proposal | hand-written |
| | [Registry checks](../../research/registries/CHECKS.md): coverage, quote verification, contradictions, Gutenberg exclusion | generated |

## Classifications

- **CANON**: stated in the novel (narration, or a character's words recorded as such).
- **CANON-INFERRED (INF)**: a reasonable reading the text supports but does not state.
- **GAME EXPANSION**: our design. Never attributed to Morris.
- **UNRESOLVED**: contradictory, ambiguous or missing; see J.

Geographic certainty: **fixed**, **constrained**, **flexible**, **unplaced**, and **Original**
for game-made places.

## Pipeline

```
research/sources/pg169.txt ──build_novel.py──► research/corpus/novel.json (paragraph ids; Gutenberg excluded)
read_chapters.py → hand-written notes (research/extraction/notes/<chapter>.txt)
   ──compile_notes.py──► research/extraction/chapters/*.json   (every quote verified)
   ──build_registries.py + merges.json──► research/registries/*.json, CHECKS.md
   ──build_constraints.py──► research/registries/worldgen_constraints.json
   ──render_world_docs.py──► docs/world/{A,B,C,E,F,I2,J2}
```

To correct anything, edit the chapter note (or `merges.json` for identity decisions) and rebuild:

```sh
python3 tools/lore/compile_notes.py <CHAPTER-ID>
python3 tools/lore/build_registries.py && python3 tools/lore/build_constraints.py && python3 tools/lore/render_world_docs.py
python3 -m unittest discover -s tests
```
