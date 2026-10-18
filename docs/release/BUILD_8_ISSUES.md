# Build 8 issue register

The owner's reports from testing Build 8 (Windows with an Xbox controller), 2026-10-18. Severity:
S1 blocks play, S2 major, S3 moderate, S4 minor. "Fixed (staging)" means fixed and tested on
`staging/my-medieval-life`, waiting for the next authorized build; nothing here was checked on a device.

| Id | Kind | Sev | Report | Status |
|---|---|---|---|---|
| B8-001 | Bug | S2 | The controller cannot reach Wear or Drop in the Pack | Fixed (staging) `013aaa8`: choosing an item moves focus to its first action |
| B8-002 | Bug | S1 | Trapped just inside a door | Fixed (staging) `013aaa8`: corner sliding into openings; a test checks every building's doors are reachable |
| B8-003 | Bug | S1 | Trapped between trees | Fixed (staging) `013aaa8`: the player can always walk out of a blocked cell; trees never regrow under someone |
| B8-004 | Bug | S3 | The sage's hut could only be entered diagonally (door one cell off) | Fixed (staging) `013aaa8` (village generator v4) |
| B8-005 | Usability | S3 | The hunger bar's icon looked like the coin bag | Fixed (staging) `013aaa8`: a meat glyph. Not yet looked at in a screenshot |
| B8-006 | Usability | S3 | Raw meat: where can it be cooked? | Partly: item details now name the recipe and place (roast meat at the oven, The Well House). Open: a campfire is a new mechanic and needs owner approval |
| B8-007 | Bug | S3 | The player and villagers visibly overlap house edges | Open. Collision checks only the feet (0.6 tiles wide) while the sprite is about a tile wide |
| B8-008 | Enhancement | S4 | A sign with the family's name at each house | Open (owner request) |
| B8-009 | Bug | S3 | The Trading skill never gains experience, so its levels cannot be reached | Open (found while answering the skills question) |
| B8-010 | Question | — | Pickpocketing children is allowed | Owner to decide |
| B8-011 | Design | — | The map ends at a hard border; the world should be large, with this village one spot in it | Open: the world-scale work in `docs/DESIGN_GAP_ASSESSMENT.md`; needs owner approval of scale |
| B8-012 | Usability | S2 | No feedback when hitting someone: needs a hit flicker, a health bar over the head, and a floating damage number | Open (owner request) |
| B8-013 | Bug | S2 | Attacking a cow said killing an animal is theft, but showed no damage or effect | Open. Investigate whether the hit landed (range, target choice) and add the B8-012 feedback |
| B8-014 | Usability | S2 | The controller should cycle through all active buttons | Open. B8-001 fixed the Pack; other windows need the same check, with a shoulder-button or D-pad cycle |
| B8-015 | Enhancement | S3 | Flowers should be pickable for crafting, and walkable when not picked | Fixed on staging after Build 8 (INT-070): flowers are walkable, picked for the `flower` item, regrow, and brew into a herbal tonic at the stove |
| B8-016 | Enhancement | S3 | Berry bushes (blue and red) should be pickable, and walkable | Fixed on staging after Build 8 (INT-070): berry bushes are walkable and picked for food that regrows |

Still open from Build 7: the economy defects B7-014 to B7-017 (an agent is working on them), B7-006,
B7-008, B7-009.
