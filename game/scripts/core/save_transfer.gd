class_name SaveTransfer
extends RefCounted
## Save continuity across separate builds and installs (owner directive 2026-10-20, register SAVE-00..09;
## docs/release/SAVE_CONTINUITY.md). Android keeps an app's own storage (user://) only while the app is
## installed, and test builds signed with different keys cannot update each other, so a save is carried
## from one install to the next as a file the player chooses: exported to a place they pick (Documents,
## Downloads, a cloud folder), and imported again after reinstalling. On Android the place is chosen with
## the system file picker (Storage Access Framework, built into Godot 4.7's Android runtime: FilePicker,
## SAFData); on Windows and Linux with the native file dialog (or Godot's own). The game never asks for
## access to the whole of storage.
##
## Import is careful (requirements 3-8, 13, 15): the file is read and checked; an unreadable file, one from
## a newer build, or one from before MIN_VERSION is refused and left untouched; the original is first
## copied, byte for byte, into user://save_backups/; then it is migrated to the current schema in memory
## (World.load_dict reads every supported older version and to_dict writes the current one; MIGRATIONS
## holds any step that must run on the raw data first) and validated (the world reloads from the result,
## its people, households, buildings, seed and identity agree with the original, and a second round trip
## changes nothing). Only then does it become the save, through SaveStore.write_text's atomic swap; a save
## already there is copied into user://save_backups/ first. Any failure leaves every file as it was.
## Sections of a save this build does not know are carried through unchanged (UNKNOWN_KEY), and nothing
## older than MIN_VERSION is claimed to load.

const BACKUP_DIR := "user://save_backups/"
const FILE_FILTER := "*.json;My Medieval Life save;application/json"

## Raw-data steps that must run before World.load_dict, keyed by the version they upgrade from (to the
## next). Empty while every supported version (MIN_VERSION 14 to World.SAVE_VERSION) is read directly by
## World.load_dict; a change that load_dict cannot absorb adds a step here and a fixture test.
const MIGRATIONS := {}

## Test hook: "migrate" or "validate" pretends that step failed; "" in the game.
static var fail_at := ""


## The current save's text, ready to export: refused unless it is a readable save of this build's range.
static func read_save(path: String) -> Dictionary:
	var r := SaveStore.inspect(path, World.SAVE_VERSION)
	if r.state != "ok":
		return {"ok": false, "reason": "there is no save to copy yet" if r.state == "missing" else "the save cannot be copied: %s" % r.reason}
	return {"ok": true, "text": FileAccess.get_file_as_string(path), "data": r.data}


## Copy the save at `path` to `target` (a path, or an Android content URI from the file picker) and read
## it back. The save itself is never touched.
static func export_save(path: String, target: String) -> Dictionary:
	var s := read_save(path)
	if not s.ok:
		return s
	var f := FileAccess.open(target, FileAccess.WRITE)
	if f == null:
		return {"ok": false, "reason": "the chosen file could not be written (%s)" % error_string(FileAccess.get_open_error())}
	f.store_string(s.text)
	f.flush()
	var err := f.get_error()
	f.close()
	if err != OK:
		return {"ok": false, "reason": "writing the copy failed (%s)" % error_string(err)}
	var back := FileAccess.open(target, FileAccess.READ)
	if back == null or back.get_as_text() != s.text:
		return {"ok": false, "reason": "the copy did not read back correctly; your save in the game is unchanged"}
	return {"ok": true, "reason": "", "info": describe(s.data)}


## Import the save at `source` as the game's save at `path` (see the class notes). Returns {ok, reason,
## info: describe(), backup: where the original was copied, replaced: where an existing save was copied}.
static func import_save(source: String, path: String, map: VillageMap) -> Dictionary:
	var f := FileAccess.open(source, FileAccess.READ)
	if f == null:
		return {"ok": false, "reason": "the file could not be opened (%s)" % error_string(FileAccess.get_open_error())}
	var text := f.get_as_text()
	f.close()
	var r := SaveStore.inspect_text(text, World.SAVE_VERSION)
	if r.state != "ok":
		return {"ok": false, "reason": "that file cannot be used: %s. Nothing was changed." % r.reason}
	var src: Dictionary = r.data
	var id := str(src.get("meta", {}).get("save_id", "unknown"))
	var stamp := int(Time.get_unix_time_from_system())
	var backup := "%simport-%s-%d.json" % [BACKUP_DIR, id, stamp]
	var b := SaveStore.write_text(backup, text)
	if not b.ok:
		return {"ok": false, "reason": "the imported file could not be backed up first (%s), so nothing was changed" % b.reason}
	var m := migrate(src, map)
	if not m.ok:
		return {"ok": false, "reason": "the save could not be brought up to date (%s). Nothing was changed; a copy is kept as %s." % [m.reason, backup.get_file()]}
	var out_text: String = JSON.stringify(m.data, "", true, true)
	var replaced := ""
	if FileAccess.file_exists(path):
		var old := FileAccess.get_file_as_string(path)
		var old_id := str(SaveStore.inspect_text(old, 1 << 30, 0).get("data", {}).get("meta", {}).get("save_id", "unknown"))
		replaced = "%sreplaced-%s-%d.json" % [BACKUP_DIR, old_id, stamp]
		var k := SaveStore.write_text(replaced, old)
		if not k.ok:
			return {"ok": false, "reason": "your current save could not be kept aside first (%s), so nothing was changed" % k.reason}
	var w := SaveStore.write_text(path, out_text)
	if not w.ok:
		return {"ok": false, "reason": "the imported save could not be put in place (%s); your current save is unchanged" % w.reason}
	return {"ok": true, "reason": "", "info": describe(m.data), "from_version": int(src.save_version), "backup": backup, "replaced": replaced}


## Bring save data up to the current schema and check it (requirements 4, 6): MIGRATIONS on the raw data,
## then World.load_dict and to_dict; unknown sections carried over. {ok, data, reason}.
static func migrate(src: Dictionary, map: VillageMap) -> Dictionary:
	var d: Dictionary = src.duplicate(true)
	var v := int(d.save_version)
	while v < World.SAVE_VERSION:
		if MIGRATIONS.has(v):
			d = (MIGRATIONS[v] as Callable).call(d)
		v += 1
		d.save_version = v
	if fail_at == "migrate":
		return {"ok": false, "reason": "test"}
	var w := World.new()
	w.load_dict(map, d)
	var out := w.to_dict()
	w.dispose()
	out["meta"] = (src.get("meta", {}) as Dictionary).duplicate(true)
	for k in src:
		if not out.has(k):
			out[k] = src[k]                     # a section this build does not know: kept unchanged
	var why := validate(src, out, map)
	if why != "":
		return {"ok": false, "reason": why}
	return {"ok": true, "data": out}


## Why `out` is not a faithful current-schema copy of `src`, or "".
static func validate(src: Dictionary, out: Dictionary, map: VillageMap) -> String:
	if fail_at == "validate":
		return "test"
	if int(out.get("save_version", 0)) != World.SAVE_VERSION:
		return "the result has the wrong save version"
	if int(out.get("seed", -1)) != int(src.get("seed", -2)):
		return "the world's seed changed"
	if str(out.get("meta", {}).get("save_id", "")) != str(src.get("meta", {}).get("save_id", "")):
		return "the save's identity changed"
	for k in ["npcs", "households"]:
		if (out.get(k, []) as Array).size() != (src.get(k, []) as Array).size():
			return "the number of %s changed" % k
	for b in (src.get("buildings", {}) as Dictionary):
		if not (out.get("buildings", {}) as Dictionary).has(b):
			return "a building went missing (%s)" % b
	if str(out.get("player", {}).get("name", "")) != str(src.get("player", {}).get("name", "")):
		return "the character changed"
	var w := World.new()
	w.load_dict(map, JSON.parse_string(JSON.stringify(out, "", true, true)))
	var again := w.to_dict()
	w.dispose()
	for k in again:
		if JSON.stringify(again[k], "", true, true) != JSON.stringify(out[k], "", true, true):
			return "the result does not reload the same (%s)" % k
	return ""


## A line for the player: whose world, how far in, when saved.
static func describe(d: Dictionary) -> String:
	var p: Dictionary = d.get("player", {})
	var day := int(float(d.get("minutes", 0.0)) / 1440.0) + 1
	var meta: Dictionary = d.get("meta", {})
	var when := Time.get_datetime_string_from_unix_time(int(meta.get("saved_at", 0)), true) if meta.has("saved_at") else "unknown"
	return "%s %s, day %d (saved %s)" % [str(p.get("name", "?")), str(p.get("family", "")), day, when]


## A file name for an export: the character, the day and the date.
static func suggested_name(d: Dictionary) -> String:
	var p: Dictionary = d.get("player", {})
	var day := int(float(d.get("minutes", 0.0)) / 1440.0) + 1
	var date := Time.get_date_string_from_system().replace("-", "")
	return "MyMedievalLife-%s-day%d-%s.json" % [str(p.get("name", "save")).replace(" ", ""), day, date]
