class_name GameSettings
extends RefCounted
## The player's settings, kept apart from the save game in user://settings.cfg: volumes, display
## mode, window size, VSync, frame cap, interface size and when to show the touch buttons.
## apply() sets them on the running game; it is called at start and after every change.

const PATH := "user://settings.cfg"
const SIZES := [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160)]
# The interface is laid out at this many pixels high and scaled to the screen: fewer = larger.
const LAYOUT_HEIGHT := {"desktop": 720.0, "phone": 450.0}
const UI_SIZES := {"small": 1.2, "normal": 1.0, "large": 0.8}
const FPS_CAPS := [0, 30, 60, 120]

var master := 1.0
var music := 0.8
var sfx := 1.0
var display := "windowed"          # windowed | fullscreen | borderless
var window_size := Vector2i.ZERO   # ZERO: the largest size that fits the screen
var vsync := true
var max_fps := 0                   # 0 = no cap
var ui_size := "normal"            # small | normal | large
var touch_buttons := "auto"        # auto (when touch is in use) | always | never
var phone := false                 # a phone or tablet: no windows, a larger interface
var save_copy := ""                # SAVE-05: a file outside the game kept up to date with the save ("" none)


func _init() -> void:
	phone = OS.has_feature("mobile") or "--phone" in OS.get_cmdline_user_args()


func load_file(path := PATH) -> void:
	var cf := ConfigFile.new()
	if cf.load(path) != OK:
		return
	master = clampf(float(cf.get_value("audio", "master", master)), 0.0, 1.0)
	music = clampf(float(cf.get_value("audio", "music", music)), 0.0, 1.0)
	sfx = clampf(float(cf.get_value("audio", "sfx", sfx)), 0.0, 1.0)
	var d: String = str(cf.get_value("display", "mode", display))
	display = d if d in ["windowed", "fullscreen", "borderless"] else "windowed"
	window_size = cf.get_value("display", "window_size", window_size)
	vsync = bool(cf.get_value("display", "vsync", vsync))
	max_fps = int(cf.get_value("display", "max_fps", max_fps))
	var u: String = str(cf.get_value("interface", "size", ui_size))
	ui_size = u if UI_SIZES.has(u) else "normal"
	var t: String = str(cf.get_value("interface", "touch_buttons", touch_buttons))
	touch_buttons = t if t in ["auto", "always", "never"] else "auto"
	save_copy = str(cf.get_value("saves", "copy", save_copy))


func save_file(path := PATH) -> void:
	var cf := ConfigFile.new()
	cf.set_value("audio", "master", master)
	cf.set_value("audio", "music", music)
	cf.set_value("audio", "sfx", sfx)
	cf.set_value("display", "mode", display)
	cf.set_value("display", "window_size", window_size)
	cf.set_value("display", "vsync", vsync)
	cf.set_value("display", "max_fps", max_fps)
	cf.set_value("interface", "size", ui_size)
	cf.set_value("interface", "touch_buttons", touch_buttons)
	cf.set_value("saves", "copy", save_copy)
	cf.save(path)


## The height the interface is laid out at; the camera zoom is scaled by layout_height() / 720.
func layout_height() -> float:
	return LAYOUT_HEIGHT["phone" if phone else "desktop"] * float(UI_SIZES[ui_size])


## Window sizes that fit on this screen, smallest first (always at least the smallest).
func sizes_that_fit() -> Array:
	var screen := DisplayServer.screen_get_size()
	var out := SIZES.filter(func(s: Vector2i): return s.x <= screen.x and s.y <= screen.y)
	return out if not out.is_empty() else [SIZES[0]]


func apply(tree: SceneTree) -> void:
	_buses()
	for bus in [["Master", master], ["Music", music], ["SFX", sfx]]:
		var i := AudioServer.get_bus_index(bus[0])
		AudioServer.set_bus_volume_db(i, linear_to_db(maxf(float(bus[1]), 0.0001)))
		AudioServer.set_bus_mute(i, float(bus[1]) <= 0.0)
	Engine.max_fps = max_fps
	var h := layout_height()
	tree.root.content_scale_size = Vector2i(int(h * 16.0 / 9.0), int(h))
	if phone or DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	match display:
		"fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		"borderless":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			var fits := sizes_that_fit()
			var size: Vector2i = window_size if window_size in fits else fits[-1] if fits.size() < 3 else fits[-2]
			DisplayServer.window_set_size(size)
			var screen := DisplayServer.screen_get_size()
			DisplayServer.window_set_position(DisplayServer.screen_get_position() + (screen - size) / 2)


## Music and SFX buses under Master, created once (the game has no sounds yet; they will play on these).
func _buses() -> void:
	for name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(name) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, name)
			AudioServer.set_bus_send(i, "Master")
