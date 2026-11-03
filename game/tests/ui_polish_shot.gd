extends SceneTree
## B25R1-008 (owner directive 2026-11-03, section 7, scenario I): the character creation and origin screens in the real
## game scene, saved as screenshots so their look is checked by eye. Needs a display (not --headless). Desktop and the
## owner's phone (landscape 2400 x 1080, the phone layout):
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 --path game \
##       --script res://tests/ui_polish_shot.gd -- OUT_DIR desktop
##   xvfb-run -a -s "-screen 0 2400x1080x24" godot --rendering-driver opengl3 --resolution 2400x1080 --path game \
##       --script res://tests/ui_polish_shot.gd -- OUT_DIR phone
## Writes OUT_DIR/<size>_creation.png (a random look), _creation_fantasy (a green elf), _creation_hair, _creation_face,
## _creation_clothes (its other pages), _creation_skeleton (posed for a sword swing), _creation_cyclops_face, _origin,
## _play (the HUD back after Begin) and _pause_dimmed (a window over play: the HUD and the world dimmed).

var main
var out := "/tmp"
var size := "desktop"
var frames := 0
var step := 0
const FANTASY := {"picks": {"race": "human", "hair": "f4", "facial-hair": "", "eyelashes": "f2", "clothes": "tunic",
	"shoes": "leather-boots", "ears-&-horns": "elven-ears", "jaw": ""},
	"swatches": {"skin": 8, "hair": 4, "facial_hair": 4, "eyes": 5, "clothes": 0, "tunic": 3, "leather_shoes": 0}}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.size() > 1:
		size = args[1]
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	main.save_path = "user://test_saves/ui_polish_shot/save1.json"
	main.settings.phone = size == "phone"
	main.settings.apply(self)
	main.view_scale = main.settings.layout_height() / 720.0
	main.ui.set_scheme("touch" if size == "phone" else "kbm")
	main.ui.fit_safe_area()
	main.ui.show_creation({"name": "Ada", "family": "Thorne", "sex": "female", "appearance": {}})
	process_frame.connect(_tick)


func _shot(name: String) -> void:
	var img := root.get_texture().get_image()
	var path := "%s/%s_%s.png" % [out, size, name]
	img.save_png(path)
	print("saved ", path, " ", img.get_size())


func _tick() -> void:
	frames += 1
	if frames < 30:
		return
	frames = 0
	match step:
		0:
			_shot("creation")
			main.ui.show_creation({"name": "Ada", "family": "Thorne", "sex": "female", "appearance": FANTASY})
		1:
			_shot("creation_fantasy")
			_tab("Hair")
		2:
			_shot("creation_hair")
			_tab("Face")
		3:
			_shot("creation_face")
			_tab("Clothes")
		4:
			_shot("creation_clothes")
			var bones: Dictionary = FANTASY.duplicate(true)
			bones.picks.race = "skeleton"
			bones.picks["ears-&-horns"] = "skeleton-big-horns"
			bones.swatches["skeleton"] = 2
			main.ui.creation_tab = "body"
			main.ui.show_creation({"name": "Ada", "family": "Thorne", "sex": "female", "appearance": bones})
			var pose: Button = main.ui.panel_body.find_child("Pose", true, false)
			pose.pressed.emit()
			pose.pressed.emit()          # walking -> standing -> sword swing
		5:
			_shot("creation_skeleton")
			main.ui.creation_tab = "face"
			var one: Dictionary = FANTASY.duplicate(true)
			one.picks.race = "cyclops"
			main.ui.show_creation({"name": "Ada", "family": "Thorne", "sex": "male", "appearance": one})
		6:
			_shot("creation_cyclops_face")
			main.ui.creation_tab = "body"
			main.new_game({"name": "Ada", "family": "Thorne", "sex": "female", "appearance": FANTASY})
		7:
			_shot("origin")
			main.ui.hide_all()
			main.resume_after_origin()
		8:
			_shot("play")
			main.ui.show_pause()
		9:
			print("dimmer shown: ", main.ui.dimmer.visible, ", HUD shown: ", main.ui.hud.visible)
			_shot("pause_dimmed")
			quit(0)
	step += 1


func _tab(t: String) -> void:
	var b: Button = main.ui.panel_body.find_child("Tab " + t, true, false)
	b.pressed.emit()
