# Save continuity across test builds (SAVE-00..09)

**Owner directive:** 2026-10-20 (`docs/directives/2026-10-20_two_decisions_three_expansions.md`, Part I, Decision 2).

**Goal:** uninstall an old test build, install a new one, reconnect to the existing save and keep playing the same world.

The permanent Android signing key is deferred. Until it exists, every test build is signed with a different throwaway key, so a new APK cannot update the old one. It must be installed fresh, and Android deletes the old install's private storage on uninstall.

## 1. The save architecture as it was (requirement 1)

**Where the save lives:** `user://save1.json` (`main.gd::SAVE_PATH`).
- On Android `user://` is the app's private storage. It is deleted when the app is uninstalled and cannot be reached by another install.
- On PC it is the user data folder, which survives reinstalls.

**Format:** one JSON object from `World.to_dict()`, written at full float precision. It has:
- `save_version` (the schema; currently 14) and `format` `"mml-save/14"`;
- the world's seed and every section of state, including NPCs, households, buildings, trees, deposits, fauna, relations and the player;
- a `meta` block with the world's identity:
  - `save_id`: random, made once per new game and kept for ever;
  - `created`, `saved_at`, `play_seconds`, `platform`, `character`.

**Safety (`save_store.gd`), already in place:**
- **Writing:** to `save1.json.tmp`, flushed and read back. Only then does the old save become `save1.json.bak` and the new file take its place. A crash or full disk at any moment leaves a complete save.
- **Reading:** a save is classed ok, missing, unreadable, newer (from a later build) or older (below `MIN_VERSION` 14).
- **Unusable saves:** never written over. They are renamed aside unchanged (`save1.unreadable-<time>.json`), and the backup is loaded if it can be.
- **New game over an old one:** the old game is kept as `save1.previous.json`.

**Migration:**
- `World.load_dict` reads every version from 14 up, filling in sections added later: relations, refuges, carts and so on.
- Older code paths for versions 1–13 remain, but `SaveStore.MIN_VERSION` refuses those saves. The owner ruled them disposable when the village was rebuilt (Build 8, generator v6).
- Run-time tests exist for older fixture formats: `run_tests.gd`, versions 4 and 5 property migrations.

**Gaps against the directive before this work:**
- no way to move a save out of the app or into a new install;
- no record of which builds a world was played in;
- import-time backup, validation and adoption did not exist;
- sections unknown to the build were dropped on the next save.

## 2. The approach

**Approach:** a file the player chooses, through the platform's own picker. There is no custom Android plugin.

**Investigation:** Godot 4.7.2's Android runtime (`godot-lib`, checked in the export template) already includes:
- `org.godotengine.godot.io.FilePicker`, using `ACTION_OPEN_DOCUMENT`, `ACTION_CREATE_DOCUMENT` and `ACTION_OPEN_DOCUMENT_TREE`;
- persistable URI permissions;
- `SAFData`, through which `FileAccess` reads and writes the `content://` URIs the picker returns.

A `FileDialog` with `use_native_dialog = true` therefore opens the Android system picker, and the game reads or writes the chosen document through ordinary `FileAccess`. This is the Storage Access Framework. It needs no storage permission and no broad filesystem access (requirement 10). On Windows and Linux the same dialog is the native file dialog, or Godot's own where there is none (requirement 11).

**What the player does (Settings → Saves):**
- **Copy my save to a file:** the system picker creates a file wherever the player chooses (Documents, Downloads, a cloud-synced folder). The current save is written there and read back. The save in the game is never touched.
- **Keep a copy up to date:** the same, and from then on every save also rewrites that file (`main.gd::_update_linked_copy`). If writing the copy fails, the game says so once; the save itself is unaffected.
- **Import a save file:** the system picker opens a file and the game imports it (below), then continues that world.

**Import (`save_transfer.gd::import_save`):** requirements 3–8, 13 and 15.
1. Read the chosen file. It is never written to.
2. Check it (`SaveStore.inspect_text`). A damaged, newer or too old (below `MIN_VERSION`) file is refused, nothing changes, and the player is told why.
3. **Back up the original** byte for byte to `user://save_backups/import-<save_id>-<time>.json`. If that fails, stop.
4. **Migrate in memory:**
   - first any raw-data steps in `MIGRATIONS` (empty while load_dict reads every supported version);
   - then `World.load_dict` and `to_dict` bring it to the current schema;
   - `meta` and sections the build does not know are carried through unchanged.
5. **Validate**, and stop on any failure:
   - same seed, same `save_id`, same character;
   - the same number of people and households;
   - every building still present;
   - the result reloads and saves again identically.
6. Copy any save already in the game to `user://save_backups/replaced-<save_id>-<time>.json`. If that fails, stop.
7. Put the migrated save in place with `SaveStore.write_text` (temp file, read back, atomic swap, `.bak` kept). An interruption at any point leaves the previous save whole.
8. Continue the imported world.

**Identity (requirement 2):**
- `meta.save_id` identifies the world independently of builds and copies.
- `meta.build` and `meta.builds` record the build that wrote it and the builds it has passed through. `release.yml` stamps `application/config/version` as `0.1.<n>-test`.

**Unknown data (requirement 13):**
- When a save is loaded, sections this build does not know are kept (`main.gd::save_extra`) and written back unchanged.
- An import carries them too.
- Backward compatibility (an old build reading a newer save) is not claimed: a newer save is refused, and the file is left as it is.

## 3. Real platform limits

- **Android drops the permission on uninstall.** It revokes access to files an app was given on uninstall, so a new install cannot find the old copy by itself. After reinstalling, the player opens Settings → Saves → Import and picks the file once. This is a platform rule; the game does not promise automatic reconnection.
- **A linked copy is a copy.** If the device dies mid-write, the copy may be incomplete while the save inside the game stays whole. The next save rewrites the copy.
- **Cloud folders depend on the cloud app.** A copy in a cloud folder (Google Drive and the like) syncs only if that app offers it as a document location in the picker.
- **Not yet checked on a real phone.** The picker and content-URI path are Godot's own and covered by its runtime. In this repository they are tested on PC paths only. The phone check is in the device queue (SAVE-05 playtest).

## 4. Tests (requirement 12)

**`game/tests/save_transfer_test.gd`** (in CI) checks that:
- a copy is written and reads back;
- an import into a fresh install keeps the world identity and build history;
- terrain (trees, overworld changes), resources (deposits, boulders, plants, fields), NPCs, households, relationships, buildings, plots, inventories (player, chests, carts, containers, stalls), fauna, farm, treasury, granary, construction and manor work all come through with the same values;
- the source file is never changed;
- the original is backed up byte for byte;
- an existing save is kept aside before it is replaced;
- damaged, newer and too-old files are refused with nothing changed;
- a failed migration, a failed validation or an interrupted swap leaves the save untouched;
- validation catches a lost person;
- unknown sections are carried through.

**`game/tests/start_test.gd`** checks that:
- saves record their build history;
- unknown sections survive a load and save in the real game;
- the Saves tab offers copy, import and keep-a-copy;
- a linked copy is updated on every save;
- importing continues the world.

## 5. Recovery instructions (requirement 14)

**Copies the game keeps, in its storage folder** (`user://`: on PC `~/.local/share/godot/app_userdata/My Medieval Life/` on Linux, `%APPDATA%\Godot\app_userdata\My Medieval Life\` on Windows; on Android, inside the app until uninstalled):
- `save1.json`: the save.
- `save1.json.bak`: the save before the last one.
- `save1.previous.json`: the game before the last New game.
- `save1.<state>-<time>.json`: saves that could not be read, kept unchanged.
- `save_backups/import-*.json`: every file imported, as it was.
- `save_backups/replaced-*.json`: every save an import replaced.

**Copies outside the game:** the files you chose with Copy my save or Keep a copy up to date. These are the ones that survive uninstalling on Android.

**To recover:**
- On Android: open Settings → Saves → Import a save file and pick the copy.
- On PC: either import a backup the same way, or close the game and copy the backup over `save1.json`.

The game checks any save it loads and refuses one it cannot use without changing it.

**Independent copy:** keep at least one exported copy outside the device (a cloud folder, or a computer) before uninstalling a test build.
