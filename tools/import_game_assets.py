"""Copy the art the Godot game needs out of the asset archives, recording provenance.

CLAUDE.md section 3: art enters the engine project only through a documented import step that
records each file's source archive and path. This is that step. It writes:

    game/assets/tiles/punyworld-tiles.png            PUNY-WORLD-PAID_v1.zip (Tiled atlas)
    game/assets/tiles/punyworld-overworld-tiles.png  PUNY_WORLD_v1.zip (free overworld atlas)
    game/assets/characters/villager_NN.png           PUNY CHARACTERS (TDSM) generated with
    game/assets/characters/bandit_NN.png             tools/puny_chargen.py, fixed seeds
    game/assets/characters/player_NN.png
    game/assets/characters/guard_NN.png
    game/assets/icons/<item>.png                     16x16 Survival RPG Icons.zip, one icon per item
    game/assets/PROVENANCE.json                      source, path and transformation of every file

Character sheets are 29 x 8 frames of 32 px: rows are the 8 directions (S, SE, E, NE, N, NW, W,
SW), columns as listed in tools/puny_chargen.py ANIMS.

Usage:
    python3 tools/import_game_assets.py
"""
import hashlib
import json
import random

from assetzip import AssetZip, REPO
import puny_chargen
import puny_world_terrain as pwt

OUT = REPO / "game" / "assets"
VILLAGERS, BANDITS, PLAYERS, GUARDS = 48, 6, 4, 6
ICON_ZIP = "16x16 Survival RPG Icons.zip"
# item id -> icon file in the survival pack (variant numbers chosen for the metal or colour)
ICONS = {
    "copper_ore": "Metal/Metal-Ore-01", "iron_ore": "Metal/Metal-Ore-02", "gold_ore": "Metal/Metal-Ore-08",
    "coal": "Stone/Coal-01", "stone": "Stone/Rock-Chunk-01", "log": "Wood/Wood-Log-01",
    "plank": "Wood/Wooden-Planks-01", "wheat": "Plants & Alchemy/Herb-Bundle-01",
    "pottage": "Metal/Metal-Pot-01", "roast_meat": "Food/Steak-01", "ale": "Liquid/Brew-01",
    "meat": "Food/Meat-01", "hide": "Textile/Deer-Pelt-07", "leather": "Textile/Leather-Fabric-07",
    "iron_bar": "Metal/Metal-Ingot-02", "copper_bar": "Metal/Metal-Ingot-01", "gold_bar": "Metal/Metal-Ingot-08",
    "pickaxe": "Tools/Pickaxe-02", "axe": "Tools/Axe-02", "iron_sword": "Tools/Sword-02",
    "copper_sword": "Tools/Sword-01", "leather_armor": "Armour/Leather-Jacket-08",
    "iron_armor": "Armour/Metal-Chestplate-02", "coins": "Metal/Metail-Coins-08",
    "hammer": "Tools/Hammer-02", "fireball": "Tools/Magic-Staff-05",
}
# Medieval-village look: natural skin tones (rows 0-6 of the skin ramp), no horns, and headwear
# from a short list per kind (None = bare head).
HATS = {
    "villager": [None] * 7 + ["villager-straw-hat", "rogue-hood", "ranger-hat", "hunter-hat", "traveller-straw-hat"],
    "player": [None, "villager-straw-hat", "ranger-hat"],
    "bandit": ["thief-bandana", "assassin-bandana", "rogue-hood"],
    "guard": ["soldier-helm", "knight-helm", "novice-helm"],
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    prov = []

    def record(dest, source, member, how):
        prov.append({"file": str(dest.relative_to(REPO / "game")), "source": source, "member": member,
                     "transform": how, "sha256": sha(dest)})

    tiles = OUT / "tiles"
    tiles.mkdir(parents=True, exist_ok=True)
    paid = AssetZip("PUNY-WORLD-PAID_v1.zip")
    member = "PUNY-WORLD-PAID_v1/Tiled/punyworld-tiles.png"
    (tiles / "punyworld-tiles.png").write_bytes(paid.read(member))
    record(tiles / "punyworld-tiles.png", "PUNY-WORLD-PAID_v1.zip", member, "copied unchanged")
    free_img = pwt.load(AssetZip(pwt.ZIP))[0]
    free_img.save(tiles / "punyworld-overworld-tiles.png")
    record(tiles / "punyworld-overworld-tiles.png", pwt.ZIP, "image of " + pwt.TSX, "decoded and re-saved as PNG")

    chars = OUT / "characters"
    chars.mkdir(parents=True, exist_ok=True)
    style = puny_chargen.Style()
    zip_name = "PUNY_CHARACTERS_v2.1_tdsm-2026.zip"
    groups = (("villager", VILLAGERS, 1000), ("bandit", BANDITS, 2000), ("player", PLAYERS, 3000),
              ("guard", GUARDS, 4000))
    for kind, count, seed0 in groups:
        for i in range(count):
            rng = random.Random(seed0 + i)
            recipe = style.random_recipe(rng, {"ears-&-horns": 1.0})
            recipe["picks"]["race"] = "human"
            recipe["picks"]["headwear"] = rng.choice(HATS[kind])
            recipe["swatches"]["skin"] = rng.randrange(7)
            img = style.render(recipe)
            dest = chars / f"{kind}_{i:02d}.png"
            img.save(dest)
            record(dest, zip_name, "assets/* layers per recipe",
                   f"tools/puny_chargen.py recipe seed {seed0 + i}, human, natural skin, headwear per kind: "
                   + json.dumps(recipe["picks"], sort_keys=True))
    icons = OUT / "icons"
    icons.mkdir(parents=True, exist_ok=True)
    iz = AssetZip(ICON_ZIP)
    for item, rel in sorted(ICONS.items()):
        member = f"16x16 Survival RPG Icons/{rel}.png"
        dest = icons / f"{item}.png"
        dest.write_bytes(iz.read(member))
        record(dest, ICON_ZIP, member, "copied unchanged")
    (OUT / "PROVENANCE.json").write_text(json.dumps({"format": "mml-provenance/1", "files": prov}, indent=1) + "\n")
    print(f"imported {len(prov)} files into game/assets")


if __name__ == "__main__":
    main()
