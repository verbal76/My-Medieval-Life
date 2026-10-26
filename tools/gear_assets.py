"""Import the art of the Build 22 armour and weapon catalogue (ARMOR-CATALOG-01, WEAPON-CATALOG-01, ARMOR-MATERIALS-01).

The asset pipeline (.claude/skills/asset-integration-pipeline, CLAUDE.md section 3): art enters the game only through an
import step that records its source. Run by tools/import_game_assets.py (after the character style is written); writes:

    icons/<item>.png      the item icons, 16 x 16 cells cut 1:1 from
                          16x16 Armour RPG Icons.zip (breastplates.png, headgear.png: body armour and headgear), and
                          16x16 Weapons RPG Icons.zip (the master weapons sheet, one per metal: every cell is one weapon of
                          game/data/weapon_catalogue.json, at the cell its "icon" names);
                          the boar tusk: 16x16 Survival RPG Icons.zip Food/Bone-02 (the white bone; the packs have no tusk),
                          copied unchanged; the antler: Wood/Sticks-03 (a forked branch) tinted pale horn 45%.
    characters/layers/clothes/<item>.png, characters/layers/headwear/<item>.png
                          the colourway each piece draws while worn: PUNY_CHARACTERS_v2.1.zip's shipped Individual
                          Spritesheets (928 x 256, the same 29 x 8 frames of 32 px as the TDSM layers), copied unchanged, drawn
                          without recolouring (no ramps) by CharacterLook in the clothes or headwear slot of the draw order.
    game/data/character_style.json gains those layers and their "worn_layers" entries (item -> layer, option).

Every file is recorded in game/assets/PROVENANCE.json.
"""
import io
import json
import zipfile

from PIL import Image

from assetzip import REPO

OUT = REPO / "game" / "assets"
ARMOUR_ZIP = "16x16 Armour RPG Icons.zip"
WEAPON_ZIP = "16x16 Weapons RPG Icons.zip"
SURVIVAL_ZIP = "16x16 Survival RPG Icons.zip"
PUNY_V21 = "PUNY_CHARACTERS_v2.1.zip"
V21_DIR = "PUNY_CHARACTERS_v2.1/PUNY CHARACTERS/Individual Spritesheets/"
MATERIAL_ICONS = {"boar_tusk": ("Food/Bone-02", None), "antler": ("Wood/Sticks-03", (214, 196, 160))}

# armour item -> (sheet, column, row) in the Armour RPG Icons pack
GEAR_ICONS = {
    "bronze_armor": ("breastplates", 0, 0),
    "steel_armor": ("breastplates", 0, 23),
    "gold_armor": ("breastplates", 2, 22),
    "viking_karl_armor": ("breastplates", 7, 8),
    "viking_warrior_armor": ("breastplates", 8, 9),
    "viking_jarl_armor": ("breastplates", 8, 18),
    "mongol_cherbi_armor": ("breastplates", 24, 3),
    "mongol_kheshig_armor": ("breastplates", 24, 8),
    "mongol_noyon_armor": ("breastplates", 23, 0),
    "mongol_khaan_armor": ("breastplates", 24, 18),
    "samurai_armor_lime": ("breastplates", 23, 3),
    "samurai_armor_purple": ("breastplates", 23, 33),
    "ronin_robe_blue": ("breastplates", 28, 23),
    "yabusame_robe_blue": ("breastplates", 29, 23),
    "ronin_robe_red": ("breastplates", 28, 13),
    "yabusame_robe_red": ("breastplates", 29, 13),
    "ninja_garb": ("breastplates", 22, 28),
    "traveller_robe": ("breastplates", 28, 18),
    "french_hunter_coat": ("breastplates", 28, 33),
    "musketeer_coat_purple": ("breastplates", 29, 34),
    "musketeer_coat_red": ("breastplates", 29, 15),
    "grunt_helm": ("headgear", 8, 6),
    "scout_helm": ("headgear", 8, 7),
    "knight_helm": ("headgear", 2, 6),
    "soldier_bronze_helm_red": ("headgear", 0, 2),
    "soldier_bronze_helm_blue": ("headgear", 1, 0),
    "soldier_iron_helm_red": ("headgear", 0, 8),
    "soldier_iron_helm_blue": ("headgear", 1, 6),
    "soldier_steel_helm_red": ("headgear", 0, 32),
    "soldier_steel_helm_blue": ("headgear", 1, 30),
    "soldier_gold_helm_red": ("headgear", 0, 26),
    "soldier_gold_helm_blue": ("headgear", 1, 24),
    "dark_knight_helm": ("headgear", 10, 36),
    "dragon_knight_helm": ("headgear", 13, 18),
    "paladin_helm": ("headgear", 18, 30),
    "viking_karl_helm": ("headgear", 10, 6),
    "viking_warrior_helm_red": ("headgear", 11, 19),
    "viking_warrior_helm_yellow": ("headgear", 11, 25),
    "valkyrie_helm": ("headgear", 4, 8),
    "viking_jarl_helm": ("headgear", 10, 24),
    "mongol_cherbi_helm": ("headgear", 6, 42),
    "mongol_kheshig_helm": ("headgear", 6, 6),
    "mongol_noyon_helm": ("headgear", 6, 0),
    "mongol_khaan_helm": ("headgear", 6, 24),
    "samurai_helm": ("headgear", 14, 18),
    "daimyo_helm": ("headgear", 14, 24),
    "shogun_helm_green": ("headgear", 14, 12),
    "shogun_helm_purple": ("headgear", 14, 42),
    "musketeer_hat_purple": ("headgear", 26, 42),
    "musketeer_hat_red": ("headgear", 26, 18),
    "hunter_hat_blue": ("headgear", 26, 30),
    "hunter_hat_indigo": ("headgear", 26, 44),
    "hunter_hat_red": ("headgear", 26, 20),
    "mage_hat_cyan": ("headgear", 27, 24),
    "mage_hat_red": ("headgear", 27, 18),
    "mage_hat_yellow": ("headgear", 27, 36),
    "high_mage_hat_cyan": ("headgear", 29, 25),
    "high_mage_hat_red": ("headgear", 29, 19),
    "high_mage_hat_yellow": ("headgear", 29, 37),
    "esper_hat_blue": ("headgear", 28, 30),
    "esper_hat_red": ("headgear", 28, 18),
    "esper_hood_cyan": ("headgear", 22, 24),
    "esper_hood_red": ("headgear", 22, 18),
    "sorcerer_hood_cyan": ("headgear", 21, 29),
    "sorcerer_hood_red": ("headgear", 21, 23),
    "villager_straw_hat": ("headgear", 24, 12),
    "traveller_straw_hat": ("headgear", 25, 12),
    "traveller_straw_hat_cyan": ("headgear", 24, 24),
    "ronin_straw_hat_blue": ("headgear", 24, 30),
    "ronin_straw_hat_red": ("headgear", 24, 18),
    "yabusame_straw_hat_blue": ("headgear", 25, 31),
    "yabusame_straw_hat_red": ("headgear", 25, 19),
    "ninja_bandana_black": ("headgear", 21, 9),
    "ninja_bandana_blue": ("headgear", 23, 34),
    "ninja_bandana_red": ("headgear", 23, 22),
    "archer_hat_cyan": ("headgear", 25, 26),
    "archer_hat_green": ("headgear", 25, 0),
    "archer_hat_yellow": ("headgear", 25, 38),
    "ranger_hat_cyan": ("headgear", 24, 26),
    "ranger_hat_green": ("headgear", 24, 2),
    "ranger_hat_yellow": ("headgear", 24, 38),
    "rogue_hat": ("headgear", 26, 0),
    "assassin_bandana_black": ("headgear", 22, 8),
    "assassin_bandana_green": ("headgear", 24, 4),
    "assassin_bandana_red": ("headgear", 24, 22),
    "thief_bandana_green": ("headgear", 25, 4),
    "thief_bandana_lime": ("headgear", 25, 16),
    "thief_bandana_red": ("headgear", 25, 22),
    "stalker_hood_black": ("headgear", 21, 8),
    "stalker_hood_purple": ("headgear", 21, 42),
    "stalker_hood_red": ("headgear", 21, 18),
}
GEAR_WORN = {
    "bronze_armor": ("clothes", "Layer 2 - Clothes/Armour Body/BronzeArmour.png"),
    "steel_armor": ("clothes", "Layer 2 - Clothes/Armour Body/SteelArmour.png"),
    "gold_armor": ("clothes", "Layer 2 - Clothes/Armour Body/GoldArmour.png"),
    "viking_karl_armor": ("clothes", "Layer 2 - Clothes/Viking Body/KarlBody.png"),
    "viking_warrior_armor": ("clothes", "Layer 2 - Clothes/Viking Body/WarriorBody.png"),
    "viking_jarl_armor": ("clothes", "Layer 2 - Clothes/Viking Body/JarlBody.png"),
    "mongol_cherbi_armor": ("clothes", "Layer 2 - Clothes/Mongol Body/Cherbi.png"),
    "mongol_kheshig_armor": ("clothes", "Layer 2 - Clothes/Mongol Body/Kheshig.png"),
    "mongol_noyon_armor": ("clothes", "Layer 2 - Clothes/Mongol Body/Noyon.png"),
    "mongol_khaan_armor": ("clothes", "Layer 2 - Clothes/Mongol Body/Khaan.png"),
    "samurai_armor_lime": ("clothes", "Layer 2 - Clothes/Japanese Body/SamuraiLime.png"),
    "samurai_armor_purple": ("clothes", "Layer 2 - Clothes/Japanese Body/SamuraiPurple.png"),
    "ronin_robe_blue": ("clothes", "Layer 2 - Clothes/Japanese Body/RoninBlue.png"),
    "yabusame_robe_blue": ("clothes", "Layer 2 - Clothes/Japanese Body/YabusameBlue.png"),
    "ronin_robe_red": ("clothes", "Layer 2 - Clothes/Japanese Body/RoninRed.png"),
    "yabusame_robe_red": ("clothes", "Layer 2 - Clothes/Japanese Body/YabusameRed.png"),
    "ninja_garb": ("clothes", "Layer 2 - Clothes/Japanese Body/NinjaBlack.png"),
    "traveller_robe": ("clothes", "Layer 2 - Clothes/Japanese Body/TravellerCyan.png"),
    "french_hunter_coat": ("clothes", "Layer 2 - Clothes/French Body/HunterIndigo.png"),
    "musketeer_coat_purple": ("clothes", "Layer 2 - Clothes/French Body/MusketeerPurple.png"),
    "musketeer_coat_red": ("clothes", "Layer 2 - Clothes/French Body/MusketeerRed.png"),
    "grunt_helm": ("headwear", "Layer 6 - Headgears/Basic Melee/GruntHelm.png"),
    "scout_helm": ("headwear", "Layer 6 - Headgears/Basic Melee/ScoutHelmGreen.png"),
    "knight_helm": ("headwear", "Layer 6 - Headgears/Basic Melee/KnightHelm.png"),
    "soldier_bronze_helm_red": ("headwear", "Layer 6 - Headgears/Basic Melee/SoldierBronzeHelmRed.png"),
    "soldier_bronze_helm_blue": ("headwear", "Layer 6 - Headgears/Basic Melee/SoldierBronzeHelmBlue.png"),
    "soldier_iron_helm_red": ("headwear", "Layer 6 - Headgears/Basic Melee/SoldierIronHelmRed.png"),
    "soldier_iron_helm_blue": ("headwear", "Layer 6 - Headgears/Basic Melee/SoldierIronHelmBlue.png"),
    "soldier_steel_helm_red": ("headwear", "Layer 6 - Headgears/Basic Melee/SoldierSteelHelmRed.png"),
    "soldier_steel_helm_blue": ("headwear", "Layer 6 - Headgears/Basic Melee/SoldierSteelHelmBlue.png"),
    "soldier_gold_helm_red": ("headwear", "Layer 6 - Headgears/Basic Melee/SoldierGoldHelmRed.png"),
    "soldier_gold_helm_blue": ("headwear", "Layer 6 - Headgears/Basic Melee/SoldierGoldHelmBlue.png"),
    "dark_knight_helm": ("headwear", "Layer 6 - Headgears/Basic Melee/DarkKnightHelm.png"),
    "dragon_knight_helm": ("headwear", "Layer 6 - Headgears/Basic Melee/DragonKnightHelm.png"),
    "paladin_helm": ("headwear", "Layer 6 - Headgears/Basic Melee/PaladinHelmCyan.png"),
    "viking_karl_helm": ("headwear", "Layer 6 - Headgears/Viking/KarlHelm.png"),
    "viking_warrior_helm_red": ("headwear", "Layer 6 - Headgears/Viking/WarriorHelmRed.png"),
    "viking_warrior_helm_yellow": ("headwear", "Layer 6 - Headgears/Viking/WarriorHelmYellow.png"),
    "valkyrie_helm": ("headwear", "Layer 6 - Headgears/Viking/ValkyrieHelm.png"),
    "viking_jarl_helm": ("headwear", "Layer 6 - Headgears/Viking/JarlHelm.png"),
    "mongol_cherbi_helm": ("headwear", "Layer 6 - Headgears/Mongol/CherbiHelm.png"),
    "mongol_kheshig_helm": ("headwear", "Layer 6 - Headgears/Mongol/KheshigHelm.png"),
    "mongol_noyon_helm": ("headwear", "Layer 6 - Headgears/Mongol/NoyonHelm.png"),
    "mongol_khaan_helm": ("headwear", "Layer 6 - Headgears/Mongol/KhaanHelm.png"),
    "samurai_helm": ("headwear", "Layer 6 - Headgears/Japanese/SamuraiHelm.png"),
    "daimyo_helm": ("headwear", "Layer 6 - Headgears/Japanese/DaimyoHelm.png"),
    "shogun_helm_green": ("headwear", "Layer 6 - Headgears/Japanese/ShogunHelmGreen.png"),
    "shogun_helm_purple": ("headwear", "Layer 6 - Headgears/Japanese/ShogunHelmPurple.png"),
    "musketeer_hat_purple": ("headwear", "Layer 6 - Headgears/French/MusketeerHatPurple.png"),
    "musketeer_hat_red": ("headwear", "Layer 6 - Headgears/French/MusketeerHatRed.png"),
    "hunter_hat_blue": ("headwear", "Layer 6 - Headgears/Basic Range/HunterHatBlue.png"),
    "hunter_hat_indigo": ("headwear", "Layer 6 - Headgears/Basic Range/HunterHatIndigo.png"),
    "hunter_hat_red": ("headwear", "Layer 6 - Headgears/Basic Range/HunterHatRed.png"),
    "mage_hat_cyan": ("headwear", "Layer 6 - Headgears/Basic Mage/MageHatCyan.png"),
    "mage_hat_red": ("headwear", "Layer 6 - Headgears/Basic Mage/MageHatRed.png"),
    "mage_hat_yellow": ("headwear", "Layer 6 - Headgears/Basic Mage/MageHatYellow.png"),
    "high_mage_hat_cyan": ("headwear", "Layer 6 - Headgears/Basic Mage/HighMageHatCyan.png"),
    "high_mage_hat_red": ("headwear", "Layer 6 - Headgears/Basic Mage/HighMageHatRed.png"),
    "high_mage_hat_yellow": ("headwear", "Layer 6 - Headgears/Basic Mage/HighMageHatYellow.png"),
    "esper_hat_blue": ("headwear", "Layer 6 - Headgears/Basic Mage/EsperHatBlue.png"),
    "esper_hat_red": ("headwear", "Layer 6 - Headgears/Basic Mage/EsperHatRed.png"),
    "esper_hood_cyan": ("headwear", "Layer 6 - Headgears/Basic Mage/EsperHoodCyan.png"),
    "esper_hood_red": ("headwear", "Layer 6 - Headgears/Basic Mage/EsperHoodRed.png"),
    "sorcerer_hood_cyan": ("headwear", "Layer 6 - Headgears/Basic Mage/SorcererHoodCyan.png"),
    "sorcerer_hood_red": ("headwear", "Layer 6 - Headgears/Basic Mage/SorcererHoodRed.png"),
    "villager_straw_hat": ("headwear", "Layer 6 - Headgears/Japanese/VillagerStrawhat.png"),
    "traveller_straw_hat": ("headwear", "Layer 6 - Headgears/Japanese/TravellerStrawhat.png"),
    "traveller_straw_hat_cyan": ("headwear", "Layer 6 - Headgears/Japanese/TravellerStrawhatCyan.png"),
    "ronin_straw_hat_blue": ("headwear", "Layer 6 - Headgears/Japanese/RoninStrawhatBlue.png"),
    "ronin_straw_hat_red": ("headwear", "Layer 6 - Headgears/Japanese/RoninStrawhatRed.png"),
    "yabusame_straw_hat_blue": ("headwear", "Layer 6 - Headgears/Japanese/YabusameStrawhatBlue.png"),
    "yabusame_straw_hat_red": ("headwear", "Layer 6 - Headgears/Japanese/YabusameStrawhatRed.png"),
    "ninja_bandana_black": ("headwear", "Layer 6 - Headgears/Japanese/NinjaBandanaBlack.png"),
    "ninja_bandana_blue": ("headwear", "Layer 6 - Headgears/Japanese/NinjaBandanaBlue.png"),
    "ninja_bandana_red": ("headwear", "Layer 6 - Headgears/Japanese/NinjaBandanaRed.png"),
    "archer_hat_cyan": ("headwear", "Layer 6 - Headgears/Basic Range/ArcherHatCyan.png"),
    "archer_hat_green": ("headwear", "Layer 6 - Headgears/Basic Range/ArcherHatGreen.png"),
    "archer_hat_yellow": ("headwear", "Layer 6 - Headgears/Basic Range/ArcherHatYellow.png"),
    "ranger_hat_cyan": ("headwear", "Layer 6 - Headgears/Basic Range/RangerHatCyan.png"),
    "ranger_hat_green": ("headwear", "Layer 6 - Headgears/Basic Range/RangerHatGreen.png"),
    "ranger_hat_yellow": ("headwear", "Layer 6 - Headgears/Basic Range/RangerHatYellow.png"),
    "rogue_hat": ("headwear", "Layer 6 - Headgears/Basic Range/RougueHatGreen.png"),
    "assassin_bandana_black": ("headwear", "Layer 6 - Headgears/Basic Assasin/AssasinBandanaBlack.png"),
    "assassin_bandana_green": ("headwear", "Layer 6 - Headgears/Basic Assasin/AssasinBandanaGreen.png"),
    "assassin_bandana_red": ("headwear", "Layer 6 - Headgears/Basic Assasin/AssasinBandanaRed.png"),
    "thief_bandana_green": ("headwear", "Layer 6 - Headgears/Basic Assasin/ThiefBandanaGreen.png"),
    "thief_bandana_lime": ("headwear", "Layer 6 - Headgears/Basic Assasin/ThiefBandanaLime.png"),
    "thief_bandana_red": ("headwear", "Layer 6 - Headgears/Basic Assasin/ThiefBandanaRed.png"),
    "stalker_hood_black": ("headwear", "Layer 6 - Headgears/Basic Assasin/StalkerHoodBlack.png"),
    "stalker_hood_purple": ("headwear", "Layer 6 - Headgears/Basic Assasin/StalkerHoodPurple.png"),
    "stalker_hood_red": ("headwear", "Layer 6 - Headgears/Basic Assasin/StalkerHoodRed.png"),
}

def _tint(img, rgb, amount):
    out = img.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a:
                px[x, y] = (int(r + (rgb[0] - r) * amount), int(g + (rgb[1] - g) * amount), int(b + (rgb[2] - b) * amount), a)
    return out


def import_into(prov, record):
    """Write the icons and worn layers, record them, and add the layers to game/data/character_style.json."""
    icons = OUT / "icons"
    icons.mkdir(parents=True, exist_ok=True)
    az = zipfile.ZipFile(REPO / ARMOUR_ZIP)
    sheets = {s: Image.open(io.BytesIO(az.read(f"16x16 Armour RPG Icons/{s}.png"))).convert("RGBA")
              for s in ("breastplates", "headgear")}
    for item, (sheet, col, row) in sorted(GEAR_ICONS.items()):
        dest = icons / f"{item}.png"
        sheets[sheet].crop((col * 16, row * 16, col * 16 + 16, row * 16 + 16)).save(dest)
        record(dest, ARMOUR_ZIP, f"16x16 Armour RPG Icons/{sheet}.png", f"16 px cell column {col}, row {row}, cut out 1:1")
    wz = zipfile.ZipFile(REPO / WEAPON_ZIP)
    catalogue = json.loads((REPO / "game" / "data" / "weapon_catalogue.json").read_text())["items"]
    wsheets = {}
    for item, it in sorted(catalogue.items()):
        name, col, row = it["icon"]
        member = "16x16 Weapons RPG Icons/" + name
        if name not in wsheets:
            wsheets[name] = Image.open(io.BytesIO(wz.read(member))).convert("RGBA")
        dest = icons / f"{item}.png"
        wsheets[name].crop((col * 16, row * 16, col * 16 + 16, row * 16 + 16)).save(dest)
        record(dest, WEAPON_ZIP, member, f"16 px cell column {col}, row {row}, cut out 1:1")
    sz = zipfile.ZipFile(REPO / SURVIVAL_ZIP)
    for item, (rel, tint) in sorted(MATERIAL_ICONS.items()):
        member = f"16x16 Survival RPG Icons/{rel}.png"
        dest = icons / f"{item}.png"
        img = Image.open(io.BytesIO(sz.read(member))).convert("RGBA")
        if tint:
            _tint(img, tint, 0.45).save(dest)
            record(dest, SURVIVAL_ZIP, member, "tinted pale horn 45% (an antler; the packs have none)")
        else:
            dest.write_bytes(sz.read(member))
            record(dest, SURVIVAL_ZIP, member, "copied unchanged (stands in for a boar tusk; the packs have none)")
    pz = zipfile.ZipFile(REPO / PUNY_V21)
    style_path = REPO / "game" / "data" / "character_style.json"
    style = json.loads(style_path.read_text())
    for item, (layer, rel) in sorted(GEAR_WORN.items()):
        member = V21_DIR + rel
        dest = OUT / "characters" / "layers" / layer / f"{item}.png"
        dest.parent.mkdir(parents=True, exist_ok=True)
        img = Image.open(io.BytesIO(pz.read(member)))
        if img.size == (28 * 32, 256):
            # the pack ships RangerHatCyan one hurt frame short (28 frames; its frames from 19 on are the others' 20 on):
            # its frame 19 is repeated, so every frame lands in its column (found by comparing it with RangerHatGreen)
            img = img.convert("RGBA")
            out = Image.new("RGBA", (29 * 32, 256))
            out.paste(img.crop((0, 0, 20 * 32, 256)), (0, 0))
            out.paste(img.crop((19 * 32, 0, 28 * 32, 256)), (20 * 32, 0))
            out.save(dest)
            record(dest, PUNY_V21, member, "frame 19 (the first hurt frame) repeated to make the pack's 29 frames (the shipped sheet "
                   "has 28); no recolouring")
        else:
            dest.write_bytes(pz.read(member))
            record(dest, PUNY_V21, member, "copied unchanged (the colourway the item draws while worn; no recolouring)")
        style["layers"].setdefault(layer, {})[item] = {"sheet": "res://" + str(dest.relative_to(REPO / "game")), "ramps": []}
        style["worn_layers"][item] = {"layer": layer, "option": item}
    style_path.write_text(json.dumps(style, indent=1) + "\n")


def main():
    """Run this step alone: write its files and replace their records in game/assets/PROVENANCE.json."""
    import hashlib
    path = OUT / "PROVENANCE.json"
    doc = json.loads(path.read_text())
    mine = []

    def record(dest, source, member, how):
        mine.append({"file": str(dest.relative_to(REPO / "game")), "source": source, "member": member, "transform": how,
                     "sha256": hashlib.sha256(dest.read_bytes()).hexdigest()})

    import_into(doc["files"], record)
    files = {m["file"] for m in mine}
    doc["files"] = [f for f in doc["files"] if f["file"] not in files] + mine
    path.write_text(json.dumps(doc, indent=1) + "\n")
    print(f"imported {len(mine)} gear files")


if __name__ == "__main__":
    main()
