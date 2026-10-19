---
name: asset-integration-pipeline
description: My Medieval Life's asset pipeline. Use whenever asset packs, sprites, sheets, tilesets, animations, textures or other art arrive or are needed (a new zip, .7z or .rar, a folder, a file in private-assets/, or "use the X pack", "add horses", "find a cart sprite"), and whenever work touches game/assets, tools/import_game_assets.py, AnimalSprite or other sprite drawing. Discovers what a pack holds, records licences and decisions in the asset registry, scales art to the 16 px world, imports it with provenance, wires it into gameplay systems, validates and tests it. Owner directive 2026-10-19 (CLAUDE.md "Asset integration policy").
---

# Asset integration pipeline

The owner supplies asset packs so they are used. Work out what a pack holds, decide where it strengthens the
game, scale it, import it, connect it to real systems, and verify. Do not ask the owner to pick sprites,
re-approve packs or re-explain licences already recorded. Follow CLAUDE.md (sections 3, 4, 6, 8 and the
asset integration policy).

## 0. Start here (every time)

```sh
python3 tools/assets/scan_packs.py           # registry up to date; prints packs and image counts
python3 tools/assets/check_assets.py          # 0 problems before you start
```

Read `docs/assets/ASSET_REGISTRY.md` for the pack: what was decided, what is imported, and its open
opportunities. Read `docs/assets/ASSET_SCALING_STANDARD.md` for sizes.

## 1. A new pack arrives

1. **Store it without changing a byte.**
   - Archives the tools read (`.zip`, folders): put them in the repository root, or in `private-assets/` when the pack's terms forbid redistributing the files (CLAUDE.md section 3; never in the public repository then).
   - `.7z`: extract with `py7zr` (`pip install py7zr`; run it with `python3 -P` from another directory).
   - `.rar`: extract with `unar` (`apt-get install unar`).
   - Extract into a folder of the same name, byte for byte, and say so in the notes. Before using a `.rar` copy, compare its files' checksums with any `.zip` copy (one Forgotten Memories `.rar` file was truncated).
2. **Record it:**
   - add a `NOTES` / `FOLDER_NOTES` / `LOOSE_NOTES` entry in `tools/build_manifest.py` (licence label and description), then run `python3 tools/build_manifest.py`;
   - add an entry in `docs/assets/packs.json` with creator, sources, storage, licence, permissions, categories, status, scale and opportunities;
   - add a credits entry in `game/data/credits.json` (every pack, whatever its licence);
   - re-run `scan_packs.py`.
3. **Licences:**
   - take the terms from the pack's own files (`scan_packs` lists every licence or readme file) or from the page the owner supplied;
   - record them once in `packs.json` and `ASSET_MANIFEST.md`;
   - a pack that may not be redistributed stays in `private-assets/`, and only the imported game files are committed, with provenance;
   - raise a licensing question only for a specific restriction that blocks the intended use, once, with a solution;
   - never re-ask about a pack already recorded.

## 2. Discover what is in it (don't stop at filenames)

```sh
python3 tools/assets/sheets.py grid    <source> <member>     # frame size, frames per row, content bounds
python3 tools/assets/sheets.py objects <source> <member>     # separate sprites of a gridless atlas
python3 tools/assets/sheets.py contact <source> <member> out/x.png --zoom 6   # pixel-grid copy to look at
```

- For a pack of one-row strips, use `sheets.common_strip_width(images)`: one strip alone is ambiguous.
- **Look at every sheet's contact image** (Read the PNG). Name what each frame or object is: crops and their stages, tools, furniture, containers, doors, fences, water, carts, animals, food, effects.
- Write the useful findings into the pack's `opportunities` in `packs.json`, and anything not used, with the reason, into `decision`.

## 3. Decide where it goes (gameplay first)

Ask, for each useful asset:
- Which existing system does it strengthen?
- Does it complete a production chain, give a resource a source, or give NPCs and the player something to do?
- Does it improve feedback?

Prefer strengthening existing systems over new mechanics. A new mechanic must fit the world rules (`docs/MEDIEVAL_LIVING_WORLD_SYSTEM_DESIGN.md`, the manifest) and the owner's decisions; the CLAUDE.md section 11 owner-authorisation list still applies. Integration counts only when a system uses the art, not when files are copied.

## 4. Scale and import

1. Follow `docs/assets/ASSET_SCALING_STANDARD.md`: one pixel density, 1:1 where the art matches, integer reductions (`sheets.scale_sheet(img, cw, ch, 1/3, "box")`) where it is drawn larger.
2. Add the import to `tools/import_game_assets.py`, which records source, member, transform and sha256 in `game/assets/PROVENANCE.json`. Never copy art into `game/assets` by hand: `check_assets.py` rejects it.
3. Run `python3 tools/import_game_assets.py`, then `godot --headless --path game --import` for new files.

## 5. Wire it in

- **Data first:** `balance.json` (species, skins, `skin_art` for a pack with another layout), `items.json`, `recipes.json`, `resources.json` for anything harvestable (then `python3 tools/check_resources.py --write`).
- **Drawing:** `AnimalSprite` (`ROWS` for side-view sheets), `ActorSprite`, map tiles (`village.json` atlases) or a sprite from `_tile_texture`.
- **Collision:** per cell, on the base only. Keep paths open (scaling standard section 3).
- **Systems:** add or update the `INT-###` entry in `docs/SYSTEM_INTERACTION_MANIFEST.md` (`python3 tools/check_interactions.py --write`).

## 6. Verify

- `python3 tools/assets/check_assets.py`: 0 problems.
- A Godot test for the behaviour, and the full suites before pushing (CLAUDE.md section 5).
- A screenshot, looked at, of the art in the world beside a person.
- `python3 tools/assets/scan_packs.py`: update the pack's `status` and `used_for` in `packs.json` and re-scan.
- `python3 -m unittest discover -s tests` (includes `tests/test_asset_pipeline.py`).

Record what was not verified (real devices). Push to staging as usual.

## 7. Keep it going

- Every pack in the registry with `status` planned or partial keeps an `opportunities` list.
- When the current task is done, take the next opportunity that fits `docs/DEVELOPMENT_PLAN.md`.
- New packs enter at step 1 without being asked.
