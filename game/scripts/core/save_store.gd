class_name SaveStore
extends RefCounted
## Safe save files (CLAUDE.md §7: never silently drop saved data; refuse what cannot be read and keep it).
##
## Writing: the new save goes to "<path>.tmp", is flushed, checked for write errors and read back
## byte for byte; only then does the current save become "<path>.bak" and the temp file take its
## place. At every moment one complete, readable save exists on disk, so a crash or a full disk
## mid-save leaves the previous save (or its backup) intact.
##
## Reading: a save is "ok", "missing", "unreadable" (not a save: damaged, truncated, not JSON),
## "newer" (written by a later version than this build reads) or "older" (written before MIN_VERSION:
## by a version whose world this build cannot place it in). A save that is not "ok" is never
## written over: `preserve` renames it, bytes unchanged, to "<name>.<state>-<time>.json" first.

const TMP := ".tmp"
const BAK := ".bak"
## The oldest save version this build reads. Build 8 laid the village out anew (tools/build_village.py
## generator v6: every building, road, tree and deposit has a new place; owner decision 2026-10-19, older
## saves are disposable): saves from before it are refused and kept on disk, never migrated.
const MIN_VERSION := 14

## Test hook: the step at which the file system pretends to fail ("open", "write", "verify",
## "backup", "replace" in `write_text`; "preserve"); "" in the game.
static var fail_at := ""


## What is at `path`: {state, data (the parsed save when "ok"), version, reason (plain words)}.
## Versions below `min_version` (MIN_VERSION in the game; the tests of this class pass 0) are "older".
static func inspect(path: String, max_version: int, min_version := MIN_VERSION) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"state": "missing", "reason": "there is no save file"}
	var text := FileAccess.get_file_as_string(path)
	if text == "" and FileAccess.get_open_error() != OK:
		return {"state": "unreadable", "reason": "the file could not be opened (%s)" % error_string(FileAccess.get_open_error())}
	return inspect_text(text, max_version, min_version)


## The same for save data already read (an imported file, SaveTransfer).
static func inspect_text(text: String, max_version: int, min_version := MIN_VERSION) -> Dictionary:
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		return {"state": "unreadable", "reason": "the file is damaged or incomplete (not valid save data)"}
	var d: Dictionary = json.data
	var v := int(d.get("save_version", 0))
	if v < 1:
		return {"state": "unreadable", "reason": "the file has no save version, so it is not a save this game wrote"}
	if v > max_version:
		return {"state": "newer", "version": v, "reason": "it was made by a newer version of the game (save version %d; this build reads up to %d)" % [v, max_version]}
	if v < min_version:
		return {"state": "older", "version": v, "reason": "it was made by an older version of the game, before the village was rebuilt (save version %d; this build reads %d to %d)" % [v, min_version, max_version]}
	return {"state": "ok", "data": d, "version": v}


## Write `text` as the save at `path`, keeping the previous good save as "<path>.bak".
## Returns {ok: bool, reason: String}; on failure the files at `path` and "<path>.bak" are as before.
static func write_text(path: String, text: String) -> Dictionary:
	var tmp := path + TMP
	var dir := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null or fail_at == "open":
		return _fail("the save file could not be created (%s)" % (error_string(FileAccess.get_open_error()) if f == null else "test"), tmp)
	f.store_string(text)
	f.flush()
	var err := f.get_error()
	f.close()
	if err != OK or fail_at == "write":
		return _fail("writing the save failed (%s), perhaps the device is full" % (error_string(err) if err != OK else "test"), tmp)
	if FileAccess.get_file_as_string(tmp) != text or fail_at == "verify":
		return _fail("the written save did not read back correctly", tmp)
	var old_bak := path + BAK + ".old"
	if FileAccess.file_exists(path):
		# the current save becomes the backup, but only a readable one: anything else was preserved already
		if not _is_json_dict(path):
			return _fail("the existing save file is not a readable save and was not replaced", tmp)
		if FileAccess.file_exists(old_bak):
			DirAccess.remove_absolute(_abs(old_bak))
		if FileAccess.file_exists(path + BAK) and DirAccess.rename_absolute(_abs(path + BAK), _abs(old_bak)) != OK:
			return _fail("the old backup could not be set aside", tmp)
		if DirAccess.rename_absolute(_abs(path), _abs(path + BAK)) != OK or fail_at == "backup":
			_restore(path, old_bak)
			return _fail("the previous save could not be kept as a backup", tmp)
	if DirAccess.rename_absolute(_abs(tmp), _abs(path)) != OK or fail_at == "replace":
		if FileAccess.file_exists(path) and FileAccess.file_exists(path + BAK):
			DirAccess.remove_absolute(_abs(path))         # only the test hook gets here with the new file in place
		_restore(path, old_bak)
		return _fail("the new save could not be put in place", tmp)
	if FileAccess.file_exists(old_bak):
		DirAccess.remove_absolute(_abs(old_bak))
	return {"ok": true, "reason": ""}


## Move a save that cannot be used out of the way, unchanged, so nothing writes over it.
## Returns the new path, or "" if it could not be moved (then nothing may save to `path`).
static func preserve(path: String, state: String) -> String:
	if not FileAccess.file_exists(path) or fail_at == "preserve":
		return ""
	var stem := path.get_basename()
	var kept := "%s.%s-%d.json" % [stem, state, int(Time.get_unix_time_from_system())]
	var n := 1
	while FileAccess.file_exists(kept):
		n += 1
		kept = "%s.%s-%d-%d.json" % [stem, state, int(Time.get_unix_time_from_system()), n]
	if DirAccess.rename_absolute(_abs(path), _abs(kept)) != OK:
		return ""
	return kept


## A save or a backup a player could continue from (the title screen's Continue).
static func any_exists(path: String) -> bool:
	return FileAccess.file_exists(path) or FileAccess.file_exists(path + BAK)


## Undo a half-done swap: the backup goes back to being the save, the set-aside backup to the backup.
static func _restore(path: String, old_bak: String) -> void:
	if not FileAccess.file_exists(path) and FileAccess.file_exists(path + BAK):
		DirAccess.rename_absolute(_abs(path + BAK), _abs(path))
	if not FileAccess.file_exists(path + BAK) and FileAccess.file_exists(old_bak):
		DirAccess.rename_absolute(_abs(old_bak), _abs(path + BAK))


static func _is_json_dict(path: String) -> bool:
	return JSON.parse_string(FileAccess.get_file_as_string(path)) is Dictionary


static func _fail(reason: String, tmp: String) -> Dictionary:
	if FileAccess.file_exists(tmp):
		DirAccess.remove_absolute(_abs(tmp))
	return {"ok": false, "reason": reason}


static func _abs(path: String) -> String:
	return ProjectSettings.globalize_path(path)
