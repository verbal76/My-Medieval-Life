# Extraction schema: The Well at the World's End

Each research batch covers a run of whole chapters and produces one JSON file,
`research/extraction/batch_NN.json`. Every claim must cite paragraph ids from
`research/corpus/novel.json`, with a short **verbatim** quote. `tools/lore/validate_extraction.py`
rejects any quote that is not an exact substring of the cited paragraph.

## Principles

- **Read every paragraph in context.** Batches are read in full, not keyword-searched. A passing
  phrase ("a little to the north of the wood", "three days' ride", "the ford below the town") is as
  important as a named city.
- **Never invent.** No coordinates, distances, directions, prices or relationships beyond what the
  text says. If you infer, mark the claim `CANON-INFERRED` and say why. If it's unclear, add an
  `unresolved` record.
- **Speaker matters.** Note whether a claim is narration, dialogue (and by whom), a tale or rumour,
  or a written source, such as the book in the Castle of Abundance. Rumours and boasts are not facts
  about the world.
- **Time matters.** Titles, rulers and possessions change during the story. Give each fact the
  chapter it holds from, and use `when` for anything time-bound.
- **Unnamed places count.** A ford, a hill, an inn, a hermitage or a wayside cross gets a
  descriptive name, e.g. `"(unnamed) ford of the river below Higham"`, with `"unnamed": true`.
- **Quotes:** 4–40 words copied exactly from the paragraph, with punctuation and spacing preserved
  (some paragraphs contain double spaces after full stops; copy them).

## File layout

```jsonc
{
  "batch": "batch_03",
  "chapters": ["BONE-C17", "BONE-C18"],          // every chapter in the batch
  "ledger": [                                     // one entry per chapter, required
    {"chapter": "BONE-C17", "paragraphs_total": 31, "all_paragraphs_read": true,
     "summary": "2-4 sentences: what happens, where, who",
     "geography_notes": "what this chapter adds to the map, or 'none'",
     "open_questions": ["..."]}
  ],
  "entities":  [ ... ],
  "relations": [ ... ],
  "spatial":   [ ... ],
  "travel":    [ ... ],
  "facts":     [ ... ],
  "events":    [ ... ],
  "unresolved":[ ... ],
  "opportunities": [ ... ]
}
```

A `ref` is `{"p": "BONE-C17-P004", "q": "exact quote from that paragraph"}`. `refs` is a list of
them, at least one.

### entities

Everything that could become a record: people, groups, places, features, polities, buildings,
items, creatures, supernatural beings or forces, offices, occupations, commodities, currencies,
customs, books or texts.

```jsonc
{"name": "Burg of the Four Friths", "aliases": ["the Burg"],
 "type": "place",            // person | group | polity | place | feature | building | item | creature |
                             // supernatural | office | occupation | commodity | currency | custom | text
 "subtype": "walled city",   // free text, specific
 "unnamed": false,
 "summary": "faithful description from the text",
 "attributes": {"ruler": "...", "population_hint": "...", "anything": "..."},   // optional, all from the text
 "refs": [ref, ...]}
```

People: include family, rank, occupation, allegiance, home, possessions and fate, as the text gives
them. Incidental people count too (the hostler, the carline, the monk at the gate). If a name could
be two different people, keep them separate and add an `unresolved` record.

### relations (non-spatial)

```jsonc
{"a": "King Peter", "rel": "parent_of", "b": "Ralph",
 // ruler_of | lord_of | vassal_of | serves | employs | parent_of | child_of | sibling_of | spouse_of |
 // betrothed_to | lover_of | kin_of | friend_of | enemy_of | allied_with | at_war_with | member_of |
 // leader_of | lives_in | born_in | owns | holds_land_of | trades_with | trades_in | produces |
 // worships | teaches | captive_of | slave_of | freed_by | killed_by | other
 "detail": "free text", "when": "BONE-C1 onward", "classification": "CANON", "confidence": "high",
 "refs": [ref]}
```

### spatial: the map constraints (highest priority)

```jsonc
{"a": "Want-way", "rel": "distance_from", "b": "High House of Upmeads",
 // north_of | south_of | east_of | west_of | (use 'direction' for NE etc.) | near | adjacent_to |
 // beyond | between | within | contains | borders | upstream_of | downstream_of | across_from |
 // on_route | route_next | distance_from | visible_from | overlooks | leads_to | flows_from | flows_into |
 // crossing_of | at_foot_of | surrounds | higher_than | other
 "direction": "",               // only if stated, e.g. "north", "toward the sunrise"
 "distance_text": "four furlongs", "travel_time_text": "", "travel_mode": "",
 "terrain_text": "meadows at the end of the upland tillage",
 "context": "narration",        // narration | dialogue:<speaker> | tale | rumour | written
 "certainty": "fixed",          // fixed = stated plainly; constrained = partial evidence;
                                // flexible = established but placement unclear
 "classification": "CANON", "confidence": "high", "note": "", "refs": [ref]}
```

Record every directional phrase, distance, travel time, visibility, containment, river course,
road, crossing, border, march and "beyond". When the text gives only a sequence ("they came to X,
and after that to Y"), use `route_next` and don't invent a direction.

### travel: journeys as they happen

```jsonc
{"travellers": ["Ralph", "Roger"], "from": "Burg of the Four Friths", "to": "Castle of Abundance",
 "via": ["Wood Perilous"], "mode": "horse", "direction_text": "", "duration_text": "two days",
 "start_time_text": "dawn", "end_time_text": "sunset", "terrain_text": "", "chapter": "BONE-C16",
 "refs": [ref]}
```

### facts

Everything about how the world works.

```jsonc
{"category": "economy",
 // politics | law | economy | price | trade | occupation | craft | agriculture | military | weapons |
 // magic | religion | medicine | learning | society | custom | family | food | clothing |
 // architecture | household | transport | ecology | climate | language | history | other
 "subject": "Burg of the Four Friths", "statement": "faithful paraphrase",
 "classification": "CANON",        // CANON | CANON-INFERRED (never GAME EXPANSION here)
 "confidence": "high", "context": "narration", "when": "", "note": "", "refs": [ref]}
```

Prices, coins, wages, tolls, gifts of value, ransom and slave prices go in `price` with the exact
amount wording. Magic: record what happens, who does it, how it's described, and whether the text
presents it as real, rumoured, believed or doubted.

### events

```jsonc
{"label": "The drawing of the straws", "chapter": "BONE-C1",
 "layer": "main",              // main | backstory | legend | prophecy | rumour | epilogue
 "time_text": "a hot afternoon of June", "participants": [], "places": [],
 "summary": "", "consequences": "", "refs": [ref]}
```

### unresolved

```jsonc
{"kind": "location", // location | identity | contradiction | missing_measure | ambiguity | document_error
 "question": "...", "refs": [ref]}
```

`document_error`: the two research documents in `research/sources/` list some places that don't
exist in the novel (e.g. "Long River", "Sundering Flood"). Note any error you notice in their
framing; you don't need to read them.

### opportunities: game ideas, never canon

```jsonc
{"idea": "Weapon licences sealed by the Burg as a law/economy mechanic", "system": "economy",
 "basis_refs": [ref]}
```
