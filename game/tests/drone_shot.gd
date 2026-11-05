extends SceneTree
## A "drone" view: the real game camera flown over the whole settlement network in a grid of shots, stitched into one
## top-down image of the play area (the village, every settlement, the roads and the countryside between). Needs a display:
##   xvfb-run -a godot --rendering-driver opengl3 --resolution 1280x720 --path game --script res://tests/drone_shot.gd -- OUT.png [PX_PER_TILE] [MARGIN]
## PX_PER_TILE (default 4) is the stitched image's scale; MARGIN (default 40 tiles) the countryside shown round the network.
## Prints each settlement's name and its place in the image (for labels).
## B25R1-018: an optional fourth argument X,Y,W,H (tiles, the village frame) shoots that area instead (a close view of a place,
## or the whole region), e.g.  -- out/higham.png 8 0 -40,720,120,100
## Optional named arguments after those: raw=DIR saves every shot as taken (10 px a tile, DIR/shot_NNNN.png) with DIR/shots.json
## (each shot's top-left tile), for a full-resolution mosaic, crops and seam checks; hour=H sets the clock to that hour of day 0
## (default 12, noon) before the first shot; cam=PX the camera's pixels a tile while shooting (default 10; 48 the game's zoom); from=N starts at shot N (resuming an interrupted raw flight).
## Deterministic: the world (seed 1, new_game's) is paused for the whole flight, so nothing moves or grows between shots; the
## camera is set free of the player, who stands far outside the area (no roof lifts, canopy fades or doors open round them);
## each shot waits until every chunk round it and its trees are built (OverworldView/TreeView queues empty), then a few frames more.

var SHOT_PX_PER_TILE := 10.0            # the camera while shooting: 128 x 72 tiles a 1280x720 shot, inside the loaded chunks
                                        # (cam=PX sets it: cam=48 is the game's own zoom, 3 x 16 px; a close look at the art as played)
var main
var out := "/tmp/drone.png"
var ppt := 4
var margin := 40
var area := Rect2i()
var fixed := Rect2i()
var shots: Array = []
var img: Image
var i := 0
var wait := 0
var ready_frames := 0
var raw_dir := ""
var hour := 12.0
var raw_index: Array = []
const MIN_WAIT := 12                   # frames a shot always waits (the camera's move drawn)
const SETTLE := 6                      # frames after the chunk and tree queues are empty
const MAX_WAIT := 600                  # a shot that never settles is taken anyway, and said so


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var pos: Array = []
	for a: String in args:
		if a.begins_with("raw="):
			raw_dir = a.substr(4)
		elif a.begins_with("from="):
			i = int(a.substr(5))              # resume an interrupted flight at this shot (raw shots before it already saved)
		elif a.begins_with("cam="):
			SHOT_PX_PER_TILE = float(a.substr(4))
		elif a.begins_with("hour="):
			hour = float(a.substr(5))
		else:
			pos.append(a)
	if pos.size() > 3:
		var p: PackedStringArray = str(pos[3]).split(",")
		fixed = Rect2i(int(p[0]), int(p[1]), int(p[2]), int(p[3]))
	if pos.size() > 0:
		out = str(pos[0])
	if pos.size() > 1:
		ppt = int(pos[1])
	if pos.size() > 2:
		margin = int(pos[2])
	if raw_dir != "":
		DirAccess.make_dir_recursive_absolute(raw_dir)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://test_saves/drone_shot"))
	main.save_path = "user://test_saves/drone_shot/save1.json"
	main.new_game()
	var w: World = main.world
	var o: Overworld = w.map.overworld
	area = RegionMapPanel.settlement_network(w).grow(margin) if fixed.size == Vector2i.ZERO else fixed
	var view := Vector2(root.get_visible_rect().size) / SHOT_PX_PER_TILE      # tiles a shot covers
	var step := Vector2i(int(view.x) - 4, int(view.y) - 4)
	for y in range(area.position.y + step.y / 2, area.end.y + step.y / 2, step.y):
		for x in range(area.position.x + step.x / 2, area.end.x + step.x / 2, step.x):
			shots.append(Vector2(x, y))
	img = Image.create(area.size.x * ppt, area.size.y * ppt, false, Image.FORMAT_RGB8)
	img.fill(Color(0.1, 0.1, 0.1))
	for st in o.sites:
		var c: Vector2i = st.center
		print("SITE ", st.name, " (", st.kind, ") at ", (c.x - area.position.x) * ppt, " ", (c.y - area.position.y) * ppt)
		print("SITETILE ", JSON.stringify({"name": st.name, "kind": st.kind, "center": [c.x, c.y], "rect": [st.rect.position.x, st.rect.position.y, st.rect.size.x, st.rect.size.y]}))
	var vc := o.village.get_center()
	print("SITE ", "Village", " (home) at ", (vc.x - area.position.x) * ppt, " ", (vc.y - area.position.y) * ppt)
	print("SITETILE ", JSON.stringify({"name": "Village", "kind": "home", "center": [vc.x, vc.y], "rect": [o.village.position.x, o.village.position.y, o.village.size.x, o.village.size.y]}))
	print("AREA ", area, " shots ", shots.size(), " image ", img.get_size())
	main.paused = true                        # the world stands still for the whole flight
	w.minutes = floorf(w.minutes / 1440.0) * 1440.0 + hour * 60.0
	print("TIME day ", int(w.minutes / 1440.0), " hour ", hour, " minutes ", w.minutes, " seed ", w.seed, " gen ", Overworld.GEN_VERSION)
	w.player.pos = Vector2(area.position) - Vector2(4000, 4000)      # far from every shot
	main.cam_free = true
	main.camera.position_smoothing_enabled = false
	main.camera.zoom = Vector2.ONE * SHOT_PX_PER_TILE / float(main.T)
	process_frame.connect(_step)


func _hide_ui() -> void:
	main.ui.hide_all()
	for n in main.ui.get_children():
		if n is CanvasItem:
			n.visible = false
	if main.ui is CanvasLayer:
		main.ui.visible = false


func _step() -> void:
	if i >= shots.size():
		process_frame.disconnect(_step)
		if raw_dir != "":
			var f := FileAccess.open(raw_dir.path_join("shots.json"), FileAccess.WRITE)
			f.store_string(JSON.stringify({"area": [area.position.x, area.position.y, area.size.x, area.size.y],
				"px_per_tile": SHOT_PX_PER_TILE, "shots": raw_index}, " "))
			f.close()
		img.save_png(out)
		print("saved ", out, " ", img.get_size())
		quit(0)
		return
	var w: World = main.world
	var c: Vector2 = shots[i]
	if wait == 0:
		main.camera.zoom = Vector2.ONE * SHOT_PX_PER_TILE / float(main.T)
		main.cam_at = c * main.T                # the chunks load round the camera (OverworldView.follow)
		main.camera.position = c * main.T
		ready_frames = 0
		_hide_ui()
	if main.player_sprite != null:
		main.player_sprite.visible = false     # the drone films the land, not the player standing in every shot
	if main.player_mark != null:
		main.player_mark.visible = false
	wait += 1
	var ov: OverworldView = main.ow_view
	var built: bool = ov._center == Overworld.chunk_of(Vector2i(floori(c.x), floori(c.y))) and ov._pending.is_empty() and main.tree_view._queue.is_empty()
	ready_frames = ready_frames + 1 if built else 0
	if (wait < MIN_WAIT or ready_frames < SETTLE) and wait < MAX_WAIT:
		return
	if ready_frames < SETTLE:
		print("UNSETTLED shot ", i, " at ", c)
	var wait_was := wait
	wait = 0
	var shot := root.get_texture().get_image()
	shot.convert(Image.FORMAT_RGB8)
	var centre: Vector2 = main.camera.get_screen_center_position() / float(main.T)
	var size_t := Vector2(shot.get_size()) / SHOT_PX_PER_TILE
	var top_left := centre - size_t / 2.0
	if raw_dir != "":
		var name := "shot_%04d.png" % i
		shot.save_png(raw_dir.path_join(name))
		raw_index.append({"file": name, "centre": [c.x, c.y], "top_left": [top_left.x, top_left.y], "size": [shot.get_width(), shot.get_height()]})
		print("SHOT ", i, "/", shots.size(), " ", c, " frames ", wait_was)
	var scale := float(ppt) / SHOT_PX_PER_TILE
	shot.resize(int(shot.get_width() * scale), int(shot.get_height() * scale), Image.INTERPOLATE_LANCZOS)
	var dst := Vector2i(((top_left - Vector2(area.position)) * ppt).round())
	img.blit_rect(shot, Rect2i(Vector2i.ZERO, shot.get_size()), dst)
	i += 1
