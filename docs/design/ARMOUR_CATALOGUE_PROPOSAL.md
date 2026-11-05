> STATUS (2026-10-31, DOC-RECON-01): SUPERSEDED IN PART — the catalogue is implemented (ARMOR-CATALOG-01); owner D16 answer B (2026-10-27) and the 2026-10-28 ruling keep the categories, items and visuals, while numbers, buffs and materials stay PROVISIONAL (ARMOR-CATALOG-D1). Current status: docs/expansions/STANDALONE_SYSTEMS.md section 9.

# Armour catalogue: proposal for the owner (ARMOR-CATALOG-01)

Agent proposal, 2026-10-26. **Nothing here is approved until the owner says so** (ARMOR-01: classes and values are approved
before they are assigned). Source art: Shade's Puny Characters pack (body armour, helmets, cultural outfits), drawn through the
ARMOR-01 equipment-to-picture link. Existing mechanics used: recipes (`recipes.json`), the armourer's stock, and the worn-gear
bonus (`items.json` `bonus`, already used by rings and the amulet for +health and +stamina).

## 1. Four classes

| Class | What it is | How you get it | Price | Buffs |
|---|---|---|---|---|
| Common | plain metal and leather | made at the anvil or workbench, or bought from the armourer | materials plus the smith's work, as today | none |
| Fine | better metals | same, higher Smithing level | higher | none, more armour |
| Cultural | Viking, Mongol, Japanese, French pieces | **commissioned** at the armourer: you bring the special materials and pay for the work | about 2x a Common piece of the same protection, plus the materials | small or none |
| Rare | the striking pieces (gold, knight lines, Jarl, Khaan, Shogun, Daimyo, Dragon Knight, Dark Knight, Paladin) | commissioned only, Smithing level 4 | highest | one or two buffs |

## 2. Buffs (worn, never stacked from the same item twice)

| Buff | Mechanic | Proposed size |
|---|---|---|
| +health | existing `max_hp` bonus | +5 (one piece), +10 (a rare full set) |
| +stamina | existing `max_stamina` bonus | +5 or +10 |
| +fireball damage | **new** `fire_damage` bonus added to the fireball's damage | +2 (helm) or +4 (body), rare mage-looking pieces |
| +armour | existing armour value | per class |

## 3. Materials

Existing: iron bar, copper bar, gold bar, leather, hide, wool cloth, fine cloth, feather.
**Missing, needed for the pack's art:** steel (for steel armour and helms), bronze (needs tin, which has no ore in the world),
silk (Japanese pieces), fur (Viking and Mongol pieces). Options for each, owner's choice:

- A. Add the material properly: a source and a recipe (steel = iron bar + coal at the forge; tin as a new seam; silk and fur as
  goods the traders bring). Most faithful, most work, changes the economy's material web.
- B. Use existing materials only for Build 22 (bronze from copper bar; steel from extra iron and coal; fur from hide; silk from
  fine cloth) and name the special materials later.

Recommendation: **B for Build 22** (everything usable now, no new economy goods), with A recorded for Expansion 20.

## 4. Example values (the rest follow the same rules)

| Item | Class | Slot | Armour | Materials (and commission) | Price | Buff |
|---|---|---|---|---|---|---|
| Leather armour (exists) | Common | body | 3 | 4 leather | 30 | none |
| Iron armour (exists) | Common | body | 6 | 5 iron bar, 2 leather | 80 | none |
| Bronze armour | Common | body | 5 | 5 copper bar, 2 leather | 65 | none |
| Steel armour | Fine | body | 8 | 6 iron bar, 3 coal, 2 leather | 140 | none |
| Gold armour | Rare | body | 6 | 4 gold bar, 2 iron bar, 2 leather | 300 | +10 health |
| Soldier helm (iron, steel, bronze, gold; red or blue) | Common/Fine | head | 2 to 3 | 2 bars of its metal, 1 leather | 36 to 70 | gold: +5 health |
| Knight / Paladin / Dragon Knight / Dark Knight helm | Rare | head | 3 | 3 iron bar, 1 gold bar, 1 leather | 120 to 160 | +5 health or +2 fireball |
| Viking Karl / Warrior body | Cultural | body | 5 | 3 iron bar, 4 hide, 2 wool cloth; commission 40 | 140 | none |
| Viking Jarl body and helm | Rare | body, head | 6, 3 | as Karl plus 2 gold bar; commission 80 | 260, 150 | +10 health |
| Mongol Cherbi / Kheshig / Noyon | Cultural | body | 4 | 4 leather, 2 copper bar, 2 wool cloth; commission 40 | 120 | +5 stamina |
| Mongol Khaan body and helm | Rare | body, head | 5, 3 | as Noyon plus 2 gold bar; commission 80 | 240, 140 | +10 stamina |
| Japanese Samurai / Ronin / Yabusame | Cultural | body | 5 | 3 iron bar, 3 fine cloth; commission 50 | 150 | none |
| Japanese Shogun / Daimyo helm | Rare | head | 3 | 2 iron bar, 1 gold bar, 2 fine cloth; commission 60 | 160 | +4 fireball |
| French Musketeer / Hunter body and hat | Cultural | body, head | 3, 1 | 3 fine cloth, 2 leather, 2 feather; commission 40 | 110, 50 | +5 stamina |
| Mage, esper and sorcerer hats and hoods | Rare (cloth) | head | 0 | 2 fine cloth, 1 gold bar; commission 50 | 120 | +2 to +4 fireball |

Plain clothes, tunics and the non-armour hats (straw hats, bandanas, archer and ranger hats) would be sold by the tailor as clothing,
no armour value, no buffs, so the full pack becomes wearable.

## 5. Questions for the owner

1. Approve the four classes and the buff list (including the new fireball-damage buff)?
2. Materials: option B for Build 22 (recommended) or A?
3. Approve the example values, with the rest set by the same rules (and listed in the wiki), or change any?
4. Should the cloth headgear (mage hats, bandanas, straw hats) be included, sold by the tailor?
