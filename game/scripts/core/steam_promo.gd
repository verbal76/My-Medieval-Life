class_name SteamPromo
extends RefCounted
## DEMO-01 (owner 2026-11-03): the Steam promotional button's destination, label and opening, from one place (game/data/steam.json).
## Until the owner supplies the game's store page (app_id or store_url), it goes to the Steam store's front page and says
## "Coming Soon on Steam"; with one set, it goes there and says "Wishlist on Steam". Opening uses the platform's own external URL
## handling (OS.shell_open: the browser or the Steam client on Windows and Linux, an intent on Android); a failure is reported to the
## caller, never fatal. Nothing here touches the world, the save or the demo's clock.

const PATH := "res://data/steam.json"

static var _cfg := {}
static var opener := Callable()          # tests: (url) -> int (an Error); empty: OS.shell_open


static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var j = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_cfg = j if j is Dictionary else {}
	return _cfg


## Tests: use this configuration instead of the file ({} reads the file again).
static func set_override(c: Dictionary) -> void:
	_cfg = c.duplicate(true)


## Whether the game's own store page is configured (an app id or a store URL).
static func has_page() -> bool:
	return str(cfg().get("app_id", "")).strip_edges() != "" or str(cfg().get("store_url", "")).strip_edges() != ""


static func url() -> String:
	var c := cfg()
	var direct := str(c.get("store_url", "")).strip_edges()
	if direct != "":
		return direct
	var id := str(c.get("app_id", "")).strip_edges()
	if id != "":
		return "https://store.steampowered.com/app/%s/" % id
	return str(c.get("generic_url", "https://store.steampowered.com/"))


static func label() -> String:
	return str(cfg().get("label_wishlist" if has_page() else "label_coming", "Wishlist on Steam" if has_page() else "Coming Soon on Steam"))


static func note() -> String:
	return str(cfg().get("note_wishlist" if has_page() else "note_coming", ""))


## Open the destination: "" when the platform took it, else why not (shown to the player; nothing else happens).
static func open() -> String:
	var u := url()
	if not (u.begins_with("https://") or u.begins_with("steam://")):
		return "The Steam link is not set up correctly."
	var err: int = opener.call(u) if opener.is_valid() else OS.shell_open(u)
	return "" if err == OK else "The Steam page could not be opened here. You can find it at %s" % u
