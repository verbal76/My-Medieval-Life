extends SceneTree
## A "drone" view: the real game camera flown over the whole settlement network in a grid of shots, stitched into one
## top-down image of the play area (the village, every settlement, the roads and the countryside between). Needs a display:
##   xvfb-run -a godot --rendering-driver opengl3 --resolution 1280x720 --path game --script res://tests/drone_shot.gd -- OUT.png [PX_PER_TILE] [MARGIN]
## PX_PER_TILE (default 4) is the stitched image's scale; MARGIN (default 40 tiles) the countryside shown round the network.
## Prints each settlement's name and its place in the image (for labels).
## B25R1-018: an optional fourth argument X,Y,W,H (tiles, the village frame) shoots that area instead (a close view of a place,
## or the whole region), e.g.  -- out/higham.png 8 0 -40,720,120,100

const SHOT_PX_PER_TILE := 10.0          # the camera while shooting: 128 x 72 tiles a 1280x720 shot, inside the loaded chunks
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


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.size() > 1:
		ppt = int(args[1])
	if args.size() > 2:
		margin = int(args[2])
	if args.size() > 3:
		var p := args[3].split(",")
		fixed = Rect2i(int(p[0]), int(p[1]), int(p[2]), int(p[3]))
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
	var vc := o.village.get_center()
	print("SITE ", "Village", " (home) at ", (vc.x - area.position.x) * ppt, " ", (vc.y - area.position.y) * ppt)
	print("AREA ", area, " shots ", shots.size(), " image ", img.get_size())
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
		img.save_png(out)
		print("saved ", out, " ", img.get_size())
		quit(0)
		return
	var w: World = main.world
	var c: Vector2 = shots[i]
	if wait == 0:
		w.player.pos = c                      # the chunks load round the player and the camera
		main.camera.zoom = Vector2.ONE * SHOT_PX_PER_TILE / float(main.T)
		main.follow_at = c * main.T
		main.camera.position = c * main.T
		_hide_ui()
	if main.player_sprite != null:
		main.player_sprite.visible = false     # the drone films the land, not the player standing in every shot
	if main.player_mark != null:
		main.player_mark.visible = false
	wait += 1
	if wait < 45:
		return
	wait = 0
	var shot := root.get_texture().get_image()
	shot.convert(Image.FORMAT_RGB8)
	var centre: Vector2 = main.camera.get_screen_center_position() / float(main.T)
	var size_t := Vector2(shot.get_size()) / SHOT_PX_PER_TILE
	var top_left := centre - size_t / 2.0
	var scale := float(ppt) / SHOT_PX_PER_TILE
	shot.resize(int(shot.get_width() * scale), int(shot.get_height() * scale), Image.INTERPOLATE_LANCZOS)
	var dst := Vector2i(((top_left - Vector2(area.position)) * ppt).round())
	img.blit_rect(shot, Rect2i(Vector2i.ZERO, shot.get_size()), dst)
	i += 1
