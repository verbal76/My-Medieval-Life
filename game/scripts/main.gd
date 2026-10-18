extends Node2D
## Game scene: owns the World (simulation), draws it, runs the player's controls and actions.
## Everything the player does goes through the same World rules as the NPCs.

const T := 16
const SAVE_PATH := "user://save1.json"
const PREVIOUS_SUFFIX := ".previous.json"   # the last game, kept when the player starts a new one

var map: VillageMap
var world: World
var view: MapView
var actors: Node2D
var above: Node2D
const MARKER_Z := 20                 # markers draw over roofs and canopies (their layers are z 10 in `above`)
var canopy: CanopyFade         # fades the tree canopy the player walks behind
var roofs: RoofFade            # fades the roof of the building the player is in (or behind)
var blankets := {}             # bed tile -> its blanket (AtlasTexture), drawn over a sleeper
var camera: Camera2D
var ui: GameUI
var sprites := {}              # npc id -> ActorSprite
var animal_sprites := {}       # animal id -> AnimalSprite
var player_sprite: ActorSprite
var loot_nodes: Array = []
var projectiles: Array = []    # {node, pos, dir, left}
var target := {}               # current interaction target
var action := {}               # {label, left, total, done: Callable}
var paused := true             # the title screen starts paused
var running := false
var move_to: Vector2 = Vector2.INF   # tap-to-move destination (tiles)
var walk_path := PackedVector2Array()  # the route to move_to, cell by cell (the villagers' pathfinder)
var walk_i := 0
var walk_goal := Vector2i(-1, -1)      # the cell walk_path leads to
var walk_stuck := 0.0                  # seconds without progress along the route
var talk_to: NPC = null                # a tapped villager the player walks up to, to talk
var reach_to := Vector2.INF            # a tapped shop counter, stall or container the player walks up to, to use
var touch_points := {}
var pinch_start := 0.0
var zoom_start := 3.0
var pinch_mid := Vector2.ZERO          # the midpoint of two touches: moving it pans the camera
var multi_touch := false               # two fingers were down: lifting them is not a tap
var cam_free := false                  # looking around: the camera stays at cam_at instead of following the player
var cam_at := Vector2.ZERO             # where the camera looks while cam_free (pixels)
var site_bars := {}                    # plot id -> the progress bar over its building frame
var follow_at := Vector2.ZERO          # where the camera looks while following the player (pixels)
# The player walks freely inside a box this fraction of the view in the middle of the screen; the
# camera moves only when they push against its edge (owner: a camera dead zone)
const DEAD_ZONE := Vector2(0.4, 0.35)
var mid_drag := false                  # the middle mouse button is held: mouse motion pans
const PAN_SPEED := 700.0               # screen pixels a second the right stick pans at full tilt
var autosave_hour := -1
var save_path := SAVE_PATH             # tests point this elsewhere so they never touch a player's save
var save_blocked := ""                 # why saving is off this session ("" = saving allowed): see continue_game
var save_failing := false
var trigger_held := {}                 # LT / RT pressed past the threshold (one step per press)
var inside_hold := ""                  # the building the player was last inside (see _sync_sprites)              # the last save failed: say so once, not at every autosave
var shot_path := ""
var shot_frames := 0
var shot_warp := Vector2.INF
var shot_advance := 0.0
var shot_zoom := 0.0
var shot_panel := ""
var view_scale := 1.0          # phones draw the interface larger; the camera zoom makes up for it
var walking := false           # the player moved this frame (resource prompts wait until they stop)
## Gather mode (B7-012, owner 2026-10-18): the Gather button; a tap (or Use) on a resource walks to it
## and gathers it, cycle after cycle by the usual actions, until it runs out or something stops it.
var gather_mode := false
var gather := {}               # what is being gathered: {def, ref, continuous, hp, tries, cycles}; {} for nothing
var gather_warned = null       # the field whose owner the player was warned of: a second tap takes it anyway
var gather_mark: Line2D        # the outline round the chosen resource
var attack_mode := false       # toggled by the Attack button: a tap on a person or animal targets it
var chase: Object = null       # the NPC or Animal marked with the sword: the player walks to it to strike
var strike_pending := false    # strike the target once in reach (a tap on it, or arriving at it)
var target_marker: Sprite2D    # the sword shown over the target
var settings := GameSettings.new()
var scheme := "kbm"            # the controls in use, from the last input: touch | gamepad | kbm
var blood_layer: Node2D        # blood where someone was slain, under the actors
var dying := {}                # npc id -> seconds left of the death flicker
var fading: Array = []         # [sprite, seconds left]: killed animals flickering out
var bubble_layer: CanvasLayer  # speech bubbles over villagers' heads, in screen space
var bubbles := {}              # npc id -> SpeechBubble (at most one each)
var diamonds := {}             # npc id -> the quest marker sprite over a quest giver
var placing := {}              # choosing where to build: {kind, at: the footprint's top-left cell}
var ghost: PlacementGhost      # the footprint shown while placing
var place_step := 0.0          # seconds until a held stick or key moves the footprint again
const FLICKER := 1.2           # seconds a body flickers before it disappears
const BLOOD_FADE := 90.0       # seconds blood takes to fade away


func _ready() -> void:
	_setup_input()
	GameData.ensure()
	# the interface is laid out for the screen (larger on a phone) and the camera zoom makes up for it
	settings.load_file()
	settings.apply(get_tree())
	view_scale = settings.layout_height() / 720.0
	scheme = "touch" if settings.phone else "kbm"
	ui = GameUI.new()
	add_child(ui)
	ui.build(self)
	ui.set_scheme(scheme)
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if i + 1 >= args.size():
			continue
		match args[i]:
			"--screenshot":
				shot_path = args[i + 1]
			"--warp":
				var xy: PackedStringArray = args[i + 1].split(",")
				shot_warp = Vector2(float(xy[0]), float(xy[1]))
			"--advance":
				shot_advance = float(args[i + 1])
			"--zoom":
				shot_zoom = float(args[i + 1])
			"--panel":
				shot_panel = args[i + 1]
			"--safe", "--cutout":
				# a pretend phone display (window pixels x,y,w,h), to look at the HUD around a camera hole
				var r: PackedStringArray = args[i + 1].split(",")
				var rect := Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
				if args[i] == "--safe":
					ui.test_safe = rect
				else:
					ui.test_cutouts.append(rect)
				ui.fit_safe_area()
	if shot_path != "":
		new_game()
		ui.hide_all()
		# fast-forward the simulation (game minutes) for screenshots of the living village
		var steps := int(shot_advance / float(GameData.b("game_minutes_per_second")) / 0.5)
		for k in steps:
			world.player.hunger = 100.0          # the camera's stand-in does not starve while it waits
			world.update(0.5)
		if shot_warp != Vector2.INF:
			world.player.pos = shot_warp
			follow_at = _in_view(shot_warp * T)
		if shot_zoom > 0.0:
			camera.zoom = Vector2(shot_zoom, shot_zoom) * view_scale
		camera.position_smoothing_enabled = false
		match shot_panel:
			"skills":
				ui.show_skills()
			"inventory":
				# a pack with something in most tabs, and the new gear worn
				var kit := {"log": 6, "plank": 12, "iron_ore": 3, "coal": 4, "wheat": 9, "pottage": 2, "leather": 2,
					"leather_cap": 1, "copper_ring": 1, "amulet": 1, "iron_bar": 2, "apple": 3}
				for id in kit:
					world.player.inv.add(id, kit[id])
				for id in ["rusty_sword", "rusty_pickaxe", "leather_cap", "copper_ring", "amulet"]:
					world.player_equip(id)
				ui.show_inventory()
				ui.inventory_window().choose("copper_ring")
			"title":
				ui.show_title(false)
			"creation":
				ui.show_creation({"name": "Ada", "family": "Thorne", "sex": "female"})
			"origin":
				ui.show_origin()
			"settings":
				ui.show_settings(ui.hide_all)
			"controls", "controls_pad":
				if shot_panel == "controls_pad":
					ui.set_scheme("gamepad")
				ui.show_controls(ui.hide_all)
			"journal":
				ui.show_journal(-1)
			"journal_quests":
				ui.show_journal(-1, true)
			"inventory_bare":
				# a new character's pack: the empty gear slots show their glyphs (B7-013)
				for slot in PlayerState.GEAR:
					world.player.set(slot, "")
				ui.toggle_inventory()
			"journal_resources", "journal_resources_list":
				ui.show_resources()
				if shot_panel == "journal_resources_list":
					# scrolled down to the list of nodes
					var scroll: ScrollContainer = ui.panel_body.get_parent()
					(func(): scroll.scroll_vertical = int(650 * view_scale)).call_deferred()
			"journal_resource_detail", "journal_resource_chain":
				ui.show_resources("tree")        # a tree's logs: their uses and what they become
				if shot_panel == "journal_resource_chain":
					# scrolled to the end: what a log becomes
					var scroll: ScrollContainer = ui.panel_body.get_parent()
					(func(): scroll.scroll_vertical = 100000).call_deferred()
			"journal_resource_item":
				ui.show_resources("tree", "plank")
			"gather":
				# Gather mode on, an iron seam chosen and being mined (B7-012)
				gather_button()
				var near := {}
				for d in world.deposits:
					if d.ore == "iron_ore" and (near.is_empty() or Vector2(d.x, d.y).distance_to(world.player.pos) < Vector2(near.x, near.y).distance_to(world.player.pos)):
						near = d
				var at := Vector2i(int(near.x), int(near.y))
				world.player.pos = Vector2(world.brain.beside(at, at + Vector2i(0, 1))) + Vector2(0.5, 0.5)
				follow_at = _in_view(world.player.pos * T)
				select_resource(ResourceNodes.node_at(world, at, true), true)
				for k in 4:
					_player_step(0.05)
				ui.toast_t = 0.01
			"opening":
				_start(true)                     # a new game's first message (where paid work is)
			"manor_offer":
				# the reeve's day of work for the manor (the answer to "Any work for me?")
				var reeve: NPC = world.npc(world.reeve_id)
				world.treasury = maxi(world.treasury, 3000)
				# the manor's evening business has bought repair materials: they wait to be carried
				for c: NPC in world.npcs:
					if c.job == "carpenter":
						c.inv.add("plank", 20)
				world.last_reeve_day = -1
				world.brain.reeve_day()
				reeve.pos = world.player.pos + Vector2(1.0, 0)
				reeve.plan = [world.brain.work(600, "", {}, "idle")]
				ui.show_talk(reeve)
				_press(ui.panel_body, "Any work for me?")
			"map", "map_home":
				if shot_panel == "map_home":
					world.player.home = "b11"          # a house to show the home marker
				ui.show_map()
			"panned":
				ui.set_scheme("touch")
				pan_camera(Vector2(-420, -260) * view_scale)
			"marker":
				attack_mode = true
				ui.set_attack_mode(true)
				ui.set_scheme("touch")
				for n: NPC in world.near(world.player.pos, 8.0):
					chase = n
					break
			"site":
				# a building site part-way: the frame, its progress bar and the build window
				var pl: Dictionary = world.plots[0]
				world.player.coins += int(pl.price)
				world.buy_plot(pl)
				world.start_site(pl)
				world.player.inv.add("plank", 30)
				world.player.inv.add("stone", 8)
				world.deliver(pl, world.player.inv)
				world.player.pos = Vector2(float(pl.door[0]) + 0.5, float(pl.door[1]) + 1.5)
				follow_at = _in_view(world.player.pos * T)
				ui.show_build(pl)
			"site_world":
				var pl: Dictionary = world.plots[0]
				world.player.coins += int(pl.price)
				world.buy_plot(pl)
				world.start_site(pl)
				world.player.inv.add("plank", 30)
				world.deliver(pl, world.player.inv)
				world.player.pos = Vector2(float(pl.door[0]) + 2.5, float(pl.door[1]) + 1.5)
				follow_at = _in_view(world.player.pos * T)
			"sleeper":
				for n: NPC in world.npcs:
					if n.alive and n.role == "adult":
						n.anim = "sleep"
						ui.show_sleeper(n)
						break
			"quest_home":
				# a quest giver inside their house (its roof on): the marker hangs over the door
				for n: NPC in world.npcs:
					if n.alive and n.role == "adult" and world.buildings.has(n.home) and world.buildings[n.home].type == "house" \
							and world.building_door(n.home).x > 20 and world.building_door(n.home).x < 100:
						world.quests.offers[n.id] = "food_for_the_family"
						n.pos = Vector2(world.home_cell(n, "bed")) + Vector2(0.5, 0.5)
						n.plan = [world.brain.work(600, "", {}, "sleep")]
						n.anim = "sleep"
						world.player.pos = Vector2(world.building_door(n.home)) + Vector2(2.5, 3.0)
						break
			"blood":
				_on_bled(world.player.pos + Vector2(1.5, 0))
				ui.prompt("Talk to Mabel Reed")
				ui.message("You take 3 coins and 1 items.")
			"talk":
				ui.show_talk(world.npcs[2])
			"talk_home":
				ui.show_talk(world.npcs[2])
				ui._talk_view(world.npcs[2], Dialogue.home(world, world.npcs[2]))
			"bubble":
				for n: NPC in world.near(world.player.pos, 8.0):
					if n.role != "bandit":
						say(n, Dialogue.brush_off(world, n))
						break
			"trade":
				for n: NPC in world.npcs:
					if n.job == "smith":
						ui.show_trade(n)
						break
			"craft":
				ui.show_craft(world.stations_of("anvil")[0])
			"shop", "counter":
				# a tavern keeper at the counter: the shop window, or (counter) the prompt in front of it
				var k := world.tavern_keeper()
				k.pos = world.shop_post(k)
				k.plan = [world.brain.work(600, "", {}, "idle")]
				if shot_panel == "shop":
					ui.show_trade(k)
				else:
					world.player.pos = k.pos + Vector2(0, 1.2)
					player_sprite.face(Vector2(0, -1))
					follow_at = _in_view(world.player.pos * T)
					ui.toast_t = 0.01                   # the opening message would hide the prompt
			"table", "table_taken":
				# beside a tavern table with food on it, facing it: the theft prompt
				for c in world.containers:
					if c.kind == "table" and c.inv.total() > 0 and int(c.y) == 43:
						var cell := Vector2i(int(c.x), int(c.y))
						var by: Vector2i = world.brain.beside(cell, cell + Vector2i(0, 1))
						world.player.pos = Vector2(by) + Vector2(0.5, 0.5)
						player_sprite.face(Vector2(cell) - Vector2(by))
						follow_at = _in_view(world.player.pos * T)
						ui.toast_t = 0.01
						if shot_panel == "table_taken":
							_find_target()
							interact()          # the dish goes into the pack and the table shows bare
						break
			"hire_ask", "hire_offer":
				# a farmer at harvest: the talk window with "Any work for me?", or (hire_offer) the answer
				for n: NPC in world.npcs:
					var f: Dictionary = world.quests.field_of(n) if n.alive and n.job == "farmer" else {}
					if f.is_empty():
						continue
					world.set_field(f, "ripe")
					f.crop = int(GameData.b("field_yield"))
					n.coins = maxi(n.coins, 20)
					n.pos = world.player.pos + Vector2(1.0, 0)
					n.plan = [world.brain.work(600, "", {}, "idle")]
					ui.show_talk(n)
					if shot_panel == "hire_offer":
						_press(ui.panel_body, "Any work for me?")
					break
			"skill_marker", "skill_done":
				# the tanner's skill quest: the scroll over the giver, or (skill_done) handing in the hides
				for n: NPC in world.npcs:
					if n.alive and n.job == "tanner":
						world.quests.offers[n.id] = "the_tanners_craft"
						n.pos = world.player.pos + Vector2(1.5, 0)
						n.plan = [world.brain.work(600, "", {}, "idle")]
						if shot_panel == "skill_done":
							world.quests.accept(n)
							world.player.inv.add("hide", 2)
							ui.show_talk(n)
							_press(ui.panel_body, "Here you are")
						break
			"interior":
				# the map alone (inside a building: its roof faded), no messages over it
				ui.toast_t = 0.01
				ui.log_box.visible = false
			"pickpocket":
				var v: NPC = world.npcs[20]
				v.pos = world.player.pos + Vector2(1.0, 0)
				v.plan = [world.brain.work(600, "", {}, "idle")]
				ui.show_talk(v)
			"place", "place_bad", "place_deal", "workshop", "workshop_in", "hire":
				# property phase 2: placing a smithy in the north-east wood (its trees felled), red
				# over a house; the deal for the ground; the finished smithy outside and inside; a
				# villager out of work offering to carry
				var c: Construction = world.construction
				var house: Dictionary = world.plots[0]
				world.player.coins = 500
				world.buy_plot(house)
				world.start_site(house)
				for id in GameData.b("house_cost"):
					world.player.inv.add(id, int(GameData.b("house_cost")[id]))
				world.deliver(house, world.player.inv)
				var spot := Rect2i(Vector2i(72, 15), c.footprint("smithy"))
				for t in world.trees:
					if t.state == "grown" and (spot.grow(1).has_point(Vector2i(int(t.x), int(t.y))) or Vector2i(int(t.x), int(t.y)) == c.door_step("smithy", spot)):
						world.fell(t, 0)
				world.player.pos = Vector2(spot.position + Vector2i(4, 12)) + Vector2(0.5, 0.5)
				follow_at = _in_view(world.player.pos * T)
				if shot_panel in ["place", "place_bad", "place_deal"]:
					begin_placement("smithy")
					move_ghost_to(spot.get_center() if shot_panel != "place_bad" else spot.get_center() + Vector2i(-11, 0))
					if shot_panel == "place_bad":
						move_ghost_to(Vector2i(int(world.buildings["b5"].x) + 4, int(world.buildings["b5"].y) + 3))
					if shot_panel == "place_deal":
						confirm_placement()
				elif shot_panel == "hire":
					c.place("smithy", spot, World.PLAYER)
					for n: NPC in world.npcs:
						if n.alive and n.role == "adult" and n.job in ["miner", "laborer", "woodcutter"]:
							n.job = ""
							n.pos = world.player.pos + Vector2(1.0, 0)
							n.plan = [world.brain.work(600, "", {}, "idle")]
							ui.show_talk(n)
							_press(ui.panel_body, "Hire to carry building materials")
							break
				else:
					var ws := c.place("smithy", spot, World.PLAYER)
					var bag := Inventory.new()
					for id in ws.site.need:
						bag.add(id, int(ws.site.need[id]))
					world.deliver(ws, bag, World.PLAYER)
					if shot_panel == "workshop_in":
						world.player.pos = Vector2(world.station_use("ws_workshop_%s_anvil" % ws.id)) + Vector2(0.5, 0.5)
						player_sprite.face(Vector2(-1, 0))
					else:
						world.player.pos = Vector2(world.building_door("workshop_" + str(ws.id))) + Vector2(1.5, 1.5)
					follow_at = _in_view((Vector2(spot.position) + Vector2(spot.size) / 2.0) * T)
					ui.toast_t = 0.01
				shot_frames = -40                  # the roof needs a moment to fade
			"npc_house":
				# a crowded household splits; its founder buys ground, hires help and builds by the
				# player's rules; two days later the family's new house stands and they live there
				var w := world
				var h := w.household_in("b5")
				var src := w.household_in("b10")
				for m in (w.households[src].members as Array).duplicate():
					var o: NPC = w.npc(int(m))
					if o.role == "child" and (w.households[h].members as Array).size() < 6:
						(w.households[src].members as Array).erase(o.id)
						(w.households[h].members as Array).append(o.id)
						o.household = h
						o.home = "b5"
				w.party(World.hh_ref(h)).coins += 500
				w.construction.daily()
				var nh: Dictionary = w.households.back()
				var site: Dictionary = w.plot(str(nh.get("build", "")))
				for k in int(3 * 1440 / (float(GameData.b("game_minutes_per_second")) * 0.5)):
					w.player.hunger = 100.0
					w.update(0.5)
					if site.site.get("done", false) and w.hour() > 9.0:
						break
				world.player.pos = Vector2(int(site.door[0]) + 2.5, int(site.door[1]) + 2.5)
				follow_at = _in_view(world.player.pos * T)
				ui.toast_t = 0.01
				print("npc house: ", w.property.describe(site), " done=", site.site.get("done", false), " home=", nh.home, " members=", nh.members)
			"land", "deal", "land_talk":
				# the manor's land office: a family that died out left b7 empty; the player owns plot0
				# with a house on it and leases plot1; (deal) the empty house's own offer at its door;
				# (land_talk) the reeve's talk with its "Land and houses" choice
				for m in world.households[world.household_in("b7")].members:
					world.kill(world.npc(int(m)), "fever")
				world.player.coins = 400
				var pl: Dictionary = world.plots[0]
				world.buy_plot(pl)
				world.start_site(pl)
				world.player.inv.add("plank", 30)
				world.player.inv.add("stone", 20)
				world.player.inv.add("log", 10)
				world.deliver(pl, world.player.inv)
				world.property.lease(world.plots[1], World.PLAYER)
				var reeve := world.npc(world.reeve_id)
				reeve.pos = world.player.pos + Vector2(1.0, 0)
				reeve.plan = [world.brain.work(600, "", {}, "idle")]
				if shot_panel == "land":
					ui.show_land(reeve)
				elif shot_panel == "land_talk":
					ui.show_talk(reeve)
				else:
					ui.show_deal(world.buildings["b7"])
		return
	ui.show_title(can_continue())


## There is a save or a backup to continue from.
func can_continue() -> bool:
	return SaveStore.any_exists(save_path)


func _setup_input() -> void:
	var keys := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN], "interact": [KEY_E, KEY_ENTER], "attack": [KEY_SPACE, KEY_J],
		"fireball": [KEY_F, KEY_K], "inventory": [KEY_I, KEY_TAB], "skills": [KEY_L], "journal": [KEY_B], "pause": [KEY_ESCAPE, KEY_P],
		"zoom_in": [KEY_EQUAL, KEY_KP_ADD], "zoom_out": [KEY_MINUS, KEY_KP_SUBTRACT],
		"map": [KEY_M], "recenter": [KEY_C], "build": [KEY_H], "gather": [KEY_G],
	}
	var pads := {"interact": JOY_BUTTON_A, "attack": JOY_BUTTON_X, "fireball": JOY_BUTTON_Y,
		"inventory": JOY_BUTTON_BACK, "pause": JOY_BUTTON_START, "skills": JOY_BUTTON_RIGHT_SHOULDER,
		"map": JOY_BUTTON_LEFT_SHOULDER, "recenter": JOY_BUTTON_RIGHT_STICK, "gather": JOY_BUTTON_DPAD_DOWN}
	for a in keys:
		if not InputMap.has_action(a):
			InputMap.add_action(a)
		for k in keys[a]:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(a, e)
		if pads.has(a):
			var j := InputEventJoypadButton.new()
			j.button_index = pads[a]
			InputMap.action_add_event(a, j)
	for pair in [["move_left", JOY_AXIS_LEFT_X, -1.0], ["move_right", JOY_AXIS_LEFT_X, 1.0],
			["move_up", JOY_AXIS_LEFT_Y, -1.0], ["move_down", JOY_AXIS_LEFT_Y, 1.0],
			["look_left", JOY_AXIS_RIGHT_X, -1.0], ["look_right", JOY_AXIS_RIGHT_X, 1.0],
			["look_up", JOY_AXIS_RIGHT_Y, -1.0], ["look_down", JOY_AXIS_RIGHT_Y, 1.0]]:
		if not InputMap.has_action(pair[0]):
			InputMap.add_action(pair[0])
		var m := InputEventJoypadMotion.new()
		m.axis = pair[1]
		m.axis_value = pair[2]
		InputMap.action_add_event(pair[0], m)
	# in windows the pad's A presses the focused button and B closes (Godot 4.7's ui_accept and
	# ui_cancel have no pad buttons by default)
	for pair in [["ui_accept", JOY_BUTTON_A], ["ui_cancel", JOY_BUTTON_B]]:
		var j := InputEventJoypadButton.new()
		j.button_index = pair[1]
		if not InputMap.action_has_event(pair[0], j):
			InputMap.action_add_event(pair[0], j)


# ---------------------------------------------------------------- starting -------------------
## A new world with the character from character creation (name, family, sex, look, sprite); with
## no spec (tests, screenshots) the default character.
func new_game(spec := {}) -> void:
	if not spec.is_empty():
		_keep_previous_game()
	_clear_world()
	map = VillageMap.load_default()
	world = World.new()
	world.setup(map, 1)
	var p := world.player
	if not spec.is_empty():
		p.name = spec.name
		p.family = spec.family
		p.sex = spec.sex
		p.look = spec.look
		p.sprite = spec.sprite
		p.heir_sprite = spec.sprite
	_build_scene()
	if spec.is_empty():
		_start(true)
	else:
		paused = true
		running = true
		ui.show_origin()


func resume_after_origin() -> void:
	_start(true)
	save_game(false)


## Continue from the save. A save that cannot be used (damaged, or from a newer version) is never
## written over: it is moved aside unchanged first, then the backup is loaded if it can be, else a
## new game starts. If it cannot even be moved aside, saving stays off this session to protect it.
func continue_game() -> void:
	var r := SaveStore.inspect(save_path, World.SAVE_VERSION)
	if r.state == "ok":
		_load_save(r.data)
		return
	var note := ""
	if r.state != "missing":
		var kept := SaveStore.preserve(save_path, r.state)
		if kept == "":
			save_blocked = "the save that could not be read could not be moved aside, so saving is off this session to protect it"
			note = "Your save could not be read: %s. It was left unchanged, and saving is off this session to protect it." % r.reason
		else:
			note = "Your save could not be read: %s. It was kept unchanged as %s." % [r.reason, kept.get_file()]
	var bak_path := save_path + SaveStore.BAK
	var b := SaveStore.inspect(bak_path, World.SAVE_VERSION)
	if b.state == "ok":
		_load_save(b.data)
		ui.message((note + " " if note != "" else "") + "The previous save (its backup) was loaded instead.", 12.0)
		return
	if b.state != "missing" and SaveStore.preserve(bak_path, b.state) == "":
		save_blocked = "the backup save could not be read or moved aside, so saving is off this session to protect it"
	new_game()
	ui.message((note if note != "" else "No save could be loaded.") + " A new game was started.", 12.0)


func _load_save(d: Dictionary) -> void:
	_clear_world()
	map = VillageMap.load_default()
	world = World.new()
	world.load_dict(map, d)
	_build_scene()
	_apply_world_changes()
	_start()


## `fresh`: a new game, which also says where paid work is (owner, 2026-10-18: guidance, no tutorial).
func _start(fresh := false) -> void:
	paused = false
	running = true
	autosave_hour = int(world.minutes / 60.0)
	ui.hide_all()
	if fresh:
		ui.message("%s %s, %s. %s" % [world.player.name, world.player.family, world.clock_text(), GameUI.OPENING_HINT], 8.0)
	else:
		ui.message("%s %s, %s. Explore the village: talk to people, work, trade, build." % [world.player.name, world.player.family, world.clock_text()])


func _clear_world() -> void:
	if world:
		world.dispose()
	chase = null
	talk_to = null
	reach_to = Vector2.INF
	placing = {}
	diamonds.clear()                # their nodes go with the scene
	site_bars.clear()
	move_to = Vector2.INF
	walk_goal = Vector2i(-1, -1)
	strike_pending = false
	gather = {}
	gather_warned = null
	gather_mark = null              # its node goes with the scene
	if gather_mode:
		gather_mode = false
		ui.set_gather_mode(false)
	if cam_free:
		recenter()
	if attack_mode:
		attack_mode = false
		ui.set_attack_mode(false)
	for c in get_children():
		if c != ui:
			c.queue_free()
	sprites.clear()
	animal_sprites.clear()
	bubbles.clear()
	loot_nodes.clear()
	projectiles.clear()


func _build_scene() -> void:
	view = MapView.new()
	add_child(view)
	blood_layer = Node2D.new()
	add_child(blood_layer)
	actors = Node2D.new()
	actors.y_sort_enabled = true
	add_child(actors)
	above = Node2D.new()
	above.z_index = 10
	add_child(above)
	target_marker = Sprite2D.new()
	target_marker.texture = load("res://assets/icons/iron_sword.png")
	target_marker.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	target_marker.rotation = PI * 1.25           # the icon's blade points up-left: turn it to point down
	target_marker.scale = Vector2(1.5, 1.5)
	target_marker.visible = false
	target_marker.z_index = MARKER_Z
	above.add_child(target_marker)
	ghost = PlacementGhost.new()
	ghost.visible = false
	ghost.z_index = MARKER_Z
	above.add_child(ghost)
	view.build(map, above)
	bubble_layer = CanvasLayer.new()
	bubble_layer.layer = 5               # over the map, under the interface (layer 20)
	add_child(bubble_layer)
	canopy = CanopyFade.new()
	above.add_child(canopy)
	canopy.setup(view, map.data.tiles.get("canopy", []))
	roofs = RoofFade.new()
	above.add_child(roofs)
	roofs.setup(view, map.data.get("roof_layers", []))
	for n: NPC in world.npcs:
		var s := ActorSprite.new()
		s.setup(n.sprite)
		actors.add_child(s)
		sprites[n.id] = s
	player_sprite = ActorSprite.new()
	player_sprite.setup(world.player.sprite)
	actors.add_child(player_sprite)
	camera = Camera2D.new()
	camera.zoom = Vector2(3, 3) * view_scale
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 10.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = map.w * T
	camera.limit_bottom = map.h * T
	add_child(camera)
	camera.make_current()
	follow_at = _in_view(world.player.pos * T)
	camera.position = follow_at
	world.tile_changed.connect(_on_tile_changed)
	world.bled.connect(_on_bled)
	dying.clear()
	fading.clear()
	for n: NPC in world.npcs:
		if not n.alive:
			dying[n.id] = 0.0          # long dead: no flicker after loading
	world.event.connect(func(t): ui.log_line(t))
	world.building_added.connect(_on_building_added)
	world.show_tables()                  # the tavern's tables show only the food that is on them


func _apply_world_changes() -> void:
	for t in world.trees:
		if t.state != "grown":
			# a stump, a sapling, or nothing where a stump was grubbed up to build (Property.claim)
			_on_tile_changed(Vector2i(t.x, t.y), "below", int(t.trunk) if t.state == "stump" else (-1 if t.state == "cleared" else int(map.data.tiles.sapling)))
			_on_tile_changed(Vector2i(t.x, t.y - 1), "above", -1)
			_on_tile_changed(Vector2i(t.x, t.y), "above", -1)
	for d in world.deposits:
		if int(d.amount) <= 0:
			_on_tile_changed(Vector2i(d.x, d.y), "below", map.data.tiles.depleted_rock)
	for f in world.fields:
		world._field_tiles(f)
	for p in world.plots:
		if not p.site.is_empty() and not p.site.done:
			_on_tile_changed(world._frame_cell(p), "below", map.data.tiles.frame)
	var ids: Array = world.buildings.keys()
	ids.sort()
	for id in ids:
		if World.is_built(world.buildings[id]):
			_on_building_added(world.buildings[id])


func _on_tile_changed(cell: Vector2i, kind: String, value: int) -> void:
	# a kind is a layer, or a layer by its own name (a tavern table's dish: World.show_tables)
	var layer_name: String = {"below": "below0", "above": "above0", "field": "path1", "path": "path0"}.get(kind, kind)
	var layer := view.layer(layer_name)
	if layer:
		if layer_name.begins_with("above"):
			canopy.restore_all()          # a faded canopy's tiles go back first, so the change sticks
			roofs.restore_all()
		view.set_tile(layer, cell, value)


func _on_building_added(b: Dictionary) -> void:
	canopy.restore_all()
	roofs.restore_all()
	var stamp: Dictionary = world.stamp_of(b)          # a house's or a workshop's
	for lname in stamp.layers:
		var layer := view.layer(lname)
		if layer == null:
			continue
		var cells: Array = stamp.layers[lname]
		for j in int(stamp.h):
			for i in int(stamp.w):
				var v := int(cells[j * int(stamp.w) + i])
				if v >= 0:
					view.set_tile(layer, Vector2i(int(b.x) + i, int(b.y) + j), v)


# ---------------------------------------------------------------- frame ----------------------
func _process(delta: float) -> void:
	if world == null:
		return
	if shot_path != "":
		_screenshot_step(delta)
	if not placing.is_empty():
		_placing_step(delta)
	if not paused and world.player.alive:
		world.update(delta)
		_player_step(delta)
		_projectiles_step(delta)
		_look_step(delta)
		var h := int(world.minutes / 60.0)
		if h != autosave_hour:
			autosave_hour = h
			save_game(false)
	if running and not world.player.alive and not ui.is_open("death"):
		ui.show_death()
	_sync_sprites()
	_sync_gather_mark()
	ui.update_hud()


## Someone inside a building whose roof is on (the player is not under it) is under that roof: not
## drawn, not tapped, their marker over the door. Inside the building the player is in, they show.
func _covered(n: NPC) -> bool:
	var at := world.place_of(n.pos)
	return at != "" and at != world.place_of(world.player.pos) and not (world.interiors[at].roof as Array).is_empty()


## The blanket of a bed tile: the part of it away from the pillow, drawn over whoever lies in it.
func _blanket(tile: int, head: String) -> Texture2D:
	if tile < 0 or tile % 100000 == 593:
		return null                    # a straw pallet: no blanket
	var key := "%d%s" % [tile, head]
	if not blankets.has(key):
		var t := tile % 100000
		var a := tile / 100000
		var tex := AtlasTexture.new()
		tex.atlas = view.sources[a].texture
		var o := Vector2(t % view.columns[a], t / view.columns[a]) * T
		tex.region = {"left": Rect2(o + Vector2(8, 0), Vector2(8, 16)), "right": Rect2(o, Vector2(8, 16))}.get(head, Rect2(o + Vector2(0, 8), Vector2(16, 8)))
		blankets[key] = tex
	return blankets[key]


## Draw a villager asleep in their own bed (at its use cell, World.home_spot) lying in it.
func _show_sleeper(n: NPC, s: ActorSprite) -> bool:
	if not world.asleep(n):
		return false
	var bed := world.home_spot(n, "bed")
	if bed.is_empty() or n.cell() != Vector2i(int(bed.use[0]), int(bed.use[1])):
		return false
	var head := str(bed.get("head", "left"))
	s.lie((Vector2(int(bed.at[0]), int(bed.at[1])) + Vector2(0.5, 0.5)) * T, head, _blanket(int(bed.get("tile", -1)), head))
	return true


func _sync_sprites() -> void:
	var cam := camera.get_screen_center_position() / T
	for n: NPC in world.npcs:
		var s: ActorSprite = sprites[n.id]
		var near := n.pos.distance_to(cam) < 30.0
		if not n.alive:
			# the body falls, flickers and is gone
			var left: float = dying.get(n.id, FLICKER) - get_process_delta_time()
			dying[n.id] = left
			s.visible = left > 0.0 and near and not _covered(n) and int(left * 12.0) % 2 == 0
			s.stand()
			if s.visible:
				s.position = n.pos * T
				if s.anim != "death":
					s.play("death", true)
			continue
		s.visible = near and not _covered(n)
		if not s.visible:
			continue
		if _show_sleeper(n, s):
			continue
		s.stand()
		s.position = n.pos * T
		s.face(n.facing)
		s.play(n.anim if n.anim != "sleep" else "idle")
	var p := world.player
	player_sprite.position = p.pos * T
	canopy.update(p.pos, get_process_delta_time())
	var inside := world.place_of(p.pos)
	if inside != "" and (world.interiors[inside].roof as Array).is_empty():
		inside = ""
	# still inside while within the building's outline, on a cell its interior missed (a back room,
	# a courtyard cell): otherwise the roof flicks between lifted and eaves-faded (Build 8 report)
	if inside == "" and inside_hold != "" and world.buildings.has(inside_hold):
		var hb: Dictionary = world.buildings[inside_hold]
		if Rect2(float(hb.x), float(hb.y), float(hb.w), float(hb.h)).has_point(p.pos):
			inside = inside_hold
	inside_hold = inside
	# behind the eaves a roof fades only when it would hide the player: over their feet and head both
	var under := world.roof_over(p.pos)
	if under != "" and world.roof_over(p.pos + Vector2(0, -1)) != under:
		under = ""
	roofs.follow(inside, world.interiors[inside].roof if inside != "" else [], under,
			world.interiors[under].roof if under != "" else [], get_process_delta_time())
	if not p.alive:
		if player_sprite.anim != "death":
			player_sprite.play("death", true)
	camera.position = cam_at if cam_free else _follow(p.pos * T)
	target_marker.visible = chase != null and chase.alive
	if target_marker.visible:
		var bob := sin(Time.get_ticks_msec() / 150.0) * 1.5
		target_marker.position = chase.pos * T + Vector2(0, -42 + bob)
	_sync_animals()
	_sync_loot()
	_sync_bubbles()
	_sync_diamonds()
	_sync_sites()


## Bubbles follow their speaker, fade out, and go when the time is up or the speaker is gone.
## A marker over everyone with a quest for the player: a pennant for a story quest, else what the
## quest is about (scroll, wheat, iron, crossed swords, log, axe). Owner's scheme, 2026-10-18.
func _sync_diamonds() -> void:
	var cam := camera.get_screen_center_position() / T
	var bob := sin(Time.get_ticks_msec() / 220.0) * 1.5
	var shown := {}
	var at_door := {}                  # door cell -> markers already placed there
	for n: NPC in world.npcs:
		var kind: String = world.quests.marker(n) if n.alive else ""
		if kind == "":
			continue
		var covered := _covered(n)
		var inside := world.place_of(n.pos)
		var at := Vector2(world.building_door(inside)) if covered else n.pos
		if at.distance_to(cam) > 30.0:
			continue
		shown[n.id] = true
		var d: Sprite2D = diamonds.get(n.id)
		if d == null:
			d = Sprite2D.new()
			d.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			d.z_index = MARKER_Z
			above.add_child(d)
			diamonds[n.id] = d
		d.texture = load("res://assets/markers/%s.png" % kind)
		if covered:
			# inside a building whose roof is on: the marker hangs over its door instead, side by
			# side if more than one inside has a quest
			var door := world.building_door(inside)
			var k: int = at_door.get(door, 0)
			at_door[door] = k + 1
			d.position = (Vector2(door) + Vector2(0.5, 0.0)) * T + Vector2(k * 20.0, -26 + bob)
		else:
			d.position = n.pos * T + Vector2(0, -48 + bob)
	for id in diamonds.keys():
		if not shown.has(id):
			diamonds[id].queue_free()
			diamonds.erase(id)


## A progress bar over each unfinished building frame (owner rule: a frame site with a progress bar).
func _sync_sites() -> void:
	for pl in world.plots:
		var building: bool = not pl.site.is_empty() and not pl.site.get("done", false)
		var bar: ProgressBar = site_bars.get(pl.id)
		if bar == null and building:
			bar = ProgressBar.new()
			bar.show_percentage = false
			bar.size = Vector2(28, 5)
			bar.z_index = MARKER_Z
			var back := StyleBoxFlat.new()
			back.bg_color = Color(0.17, 0.11, 0.07, 0.9)
			var fill := StyleBoxFlat.new()
			fill.bg_color = Color(0.47, 0.72, 0.29)
			bar.add_theme_stylebox_override("background", back)
			bar.add_theme_stylebox_override("fill", fill)
			above.add_child(bar)
			site_bars[pl.id] = bar
		if bar:
			bar.visible = building
			bar.value = world.site_progress(pl) * 100.0
			bar.position = (Vector2(world._frame_cell(pl)) + Vector2(0.5, 0)) * T + Vector2(-14, -14)


func _sync_bubbles() -> void:
	var xf := get_canvas_transform()
	for id in bubbles.keys():
		var b: SpeechBubble = bubbles[id]
		var n := world.npc(id)
		if not b.tick(get_process_delta_time()) or n == null or not n.alive or _covered(n):
			b.queue_free()
			bubbles.erase(id)
			continue
		b.point_at(xf * (n.pos * T + Vector2(0, -30)))


## A villager calls out a line in a bubble over their head.
func say(n: NPC, text: String) -> void:
	var b: SpeechBubble = bubbles.get(n.id)
	if b:
		b.say(text)
		return
	b = SpeechBubble.new()
	b.setup(n.id, text, 20)
	bubble_layer.add_child(b)
	bubbles[n.id] = b
	b.point_at(get_canvas_transform() * (n.pos * T + Vector2(0, -30)))


## The player speaks to a villager: someone busy (walking somewhere, working, fighting) calls out a
## line and carries on; anyone else stops for a conversation.
func approach(n: NPC) -> void:
	# a sleeper (owner rule: sleeping is not immunity): wake them, pick their pocket, or leave them
	if world.asleep(n):
		ui.show_sleeper(n)
		return
	# a quest giver always stops to talk (owner: "unless they're a quest giver")
	# (and so does a villager with paid work to offer the player: agent proposal)
	var quest_business := world.quests.diamond(n) or not world.quests.active_from(n).is_empty() or not world.quests.hire_offer(n).is_empty()
	# a shopkeeper at their counter or stall always serves: their shop opens (Talk is in it)
	if world.at_post(n) and not quest_business:
		ui.show_trade(n)
		return
	if n.role != "bandit" and Dialogue.busy(n) and not quest_business:
		say(n, Dialogue.brush_off(world, n))
	else:
		ui.show_talk(n)


func _sync_animals() -> void:
	var cam := camera.get_screen_center_position() / T
	var seen := {}
	for a: Animal in world.fauna.animals:
		seen[a.id] = true
		var s: AnimalSprite = animal_sprites.get(a.id)
		if s == null:
			s = AnimalSprite.new()
			s.setup(a)
			actors.add_child(s)
			animal_sprites[a.id] = s
		s.visible = a.pos.distance_to(cam) < 30.0
		if s.visible:
			s.position = a.pos * T
			s.show_state(a, world.minutes, get_process_delta_time())
	for id in animal_sprites.keys():
		if not seen.has(id):
			fading.append([animal_sprites[id], FLICKER])
			animal_sprites.erase(id)
	for f in fading.duplicate():
		f[1] -= get_process_delta_time()
		if f[1] <= 0.0:
			f[0].queue_free()
			fading.erase(f)
		else:
			f[0].visible = int(f[1] * 12.0) % 2 == 0


## A pool of blood where someone or something was slain; it fades away over BLOOD_FADE seconds.
func _on_bled(pos: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = load("res://assets/fx/blood_%d.png" % (randi() % 8))     # looks only: not the world's RNG
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.position = (pos + Vector2(0, 0.25)) * T
	s.rotation = float(randi() % 4) * PI / 2.0
	s.modulate.a = 0.9
	blood_layer.add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "modulate:a", 0.0, BLOOD_FADE).set_ease(Tween.EASE_IN)
	tw.tween_callback(s.queue_free)


func _sync_loot() -> void:
	while loot_nodes.size() < world.loot.size():
		var tr := TextureRect.new()
		tr.texture = load("res://assets/icons/coins.png")
		var holder := Node2D.new()
		holder.add_child(tr)
		tr.position = Vector2(-8, -12)
		actors.add_child(holder)
		loot_nodes.append(holder)
	while loot_nodes.size() > world.loot.size():
		loot_nodes.pop_back().queue_free()
	for i in world.loot.size():
		loot_nodes[i].position = world.loot[i].pos * T


# ---------------------------------------------------------------- player ---------------------
func _player_step(delta: float) -> void:
	var p := world.player
	if not action.is_empty():
		action.left -= delta
		player_sprite.play("work")
		if action.left <= 0.0:
			var done: Callable = action.done
			action = {}
			done.call()
		return
	if ui.modal():
		player_sprite.play("idle")
		return
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if v.length() > 0.1 and not gather.is_empty():
		stop_gather("You stop gathering.")          # walking away stops it; Gather mode stays on
	if v.length() > 0.1:
		chase = null
		talk_to = null
		reach_to = Vector2.INF
		if cam_free:
			recenter()                    # walking with keys or the stick brings the view back
	_gather_step()
	_chase_step()
	_talk_step()
	_reach_step()
	if v.length() > 0.1:
		move_to = Vector2.INF
	elif move_to != Vector2.INF:
		v = _route_step(delta)
	walking = v.length() > 0.1
	if v.length() > 0.1:
		var speed := float(GameData.b("player_tiles_per_second"))
		var step := v.normalized() * minf(v.length(), 1.0) * speed * delta
		var before := p.pos
		var moved_x := _try_move(Vector2(step.x, 0))
		var moved_y := _try_move(Vector2(0, step.y))
		if not moved_y and absf(v.y) > absf(v.x):
			_slide_to_gap(Vector2(0, step.y))
		elif not moved_x and absf(v.x) > absf(v.y):
			_slide_to_gap(Vector2(step.x, 0))
		walk_stuck = walk_stuck + delta if p.pos.distance_to(before) < step.length() * 0.3 else 0.0
		player_sprite.face(v)
		player_sprite.play("walk")
	elif player_sprite.anim == "walk":
		player_sprite.play("idle")
	_find_target()
	if Input.is_action_just_pressed("interact"):
		interact()
	if Input.is_action_just_pressed("attack"):
		attack()
	if Input.is_action_just_pressed("fireball"):
		fireball()
	if Input.is_action_just_pressed("inventory"):
		ui.toggle_inventory()
	if Input.is_action_just_pressed("skills"):
		ui.toggle_skills()
	if Input.is_action_just_pressed("journal"):
		ui.show_journal(-1)
	if Input.is_action_just_pressed("build"):
		ui.show_build_menu()
	if Input.is_action_just_pressed("gather"):
		gather_button()


## The direction to walk this frame towards move_to, around walls and trees: the route comes
## from the map's pathfinder and is found again when the goal moves to another cell or the player
## gets stuck. Arriving (or finding no way) clears move_to.
func _route_step(_delta: float) -> Vector2:
	var p := world.player
	var goal := Vector2i(floori(move_to.x), floori(move_to.y))
	if goal != walk_goal or walk_stuck > 0.5:
		walk_goal = goal
		walk_stuck = 0.0
		walk_path = map.find_path(Vector2i(floori(p.pos.x), floori(p.pos.y)), goal)
		walk_i = 1                       # the first point is the cell the player stands in
		if walk_path.is_empty():
			move_to = Vector2.INF
			walk_goal = Vector2i(-1, -1)
			return Vector2.ZERO
	# the last stretch goes to the exact point; before it, to the centre of each cell on the way
	var target := move_to if walk_i >= walk_path.size() - 1 else walk_path[walk_i] + Vector2(0.5, 0.5)
	if map.is_solid(goal) and walk_i >= walk_path.size() - 1:
		target = walk_path[walk_path.size() - 1] + Vector2(0.5, 0.5)
	var d := target - p.pos
	if d.length() < 0.15:
		if walk_i >= walk_path.size() - 1:
			move_to = Vector2.INF
			walk_goal = Vector2i(-1, -1)
			return Vector2.ZERO
		walk_i += 1
		return _route_step(_delta)
	return d.normalized()


## Walk up to a tapped villager, following as they move, and talk once beside them.
func _talk_step() -> void:
	if talk_to == null:
		return
	if not talk_to.alive or _covered(talk_to) or talk_to.pos.distance_to(world.player.pos) > 25.0:
		talk_to = null
		move_to = Vector2.INF
		return
	var d := talk_to.pos - world.player.pos
	if d.length() > 1.3:
		move_to = talk_to.pos
		return
	move_to = Vector2.INF
	player_sprite.face(d)
	var who := talk_to
	talk_to = null
	approach(who)


## Walk up to a tapped counter, stall or container and use it once beside it.
func _reach_step() -> void:
	if reach_to == Vector2.INF:
		return
	var d := reach_to - world.player.pos
	if d.length() > 1.7:
		if move_to == Vector2.INF:
			reach_to = Vector2.INF            # the walk ended short of it (no way there)
		return
	move_to = Vector2.INF
	player_sprite.face(d)
	reach_to = Vector2.INF
	_find_target()
	if not target.is_empty():
		interact()


const BODY := [Vector2(-0.38, -0.15), Vector2(0.38, -0.15), Vector2(-0.38, 0.2), Vector2(0.38, 0.2)]   # the player's feet, about as wide as the sprite (tiles; Build 8: walls overlapped the sprite)


## How many corners of the player's feet, standing at `at`, are on a blocked cell.
func _blocked_corners(at: Vector2) -> int:
	var n := 0
	for c in BODY:
		var q: Vector2 = at + c
		if map.is_solid(Vector2i(floori(q.x), floori(q.y))):
			n += 1
	return n


## Move by `step` if the feet fit there. Feet already on something solid (a tree that grew back
## under them, a building finished around them) may move wherever they overlap no more than now,
## so the player can always walk out (Build 8 report: trapped between trees).
func _try_move(step: Vector2) -> bool:
	var p := world.player
	var np := p.pos + step
	var now := _blocked_corners(p.pos)
	var after := _blocked_corners(np)
	if after == 0 or (now > 0 and after <= now):
		p.pos = np
		return true
	return false


## Pushing into a wall beside an opening (a doorway, the gap between two trees): when the feet would
## fit through less than about half a tile to the side, slide toward it, as most games do, instead of
## needing the stick lined up to a fifth of a tile (Build 8 report: trapped just inside a door).
func _slide_to_gap(step: Vector2) -> void:
	var p := world.player
	var side := Vector2(0, 1) if step.x != 0.0 else Vector2(1, 0)
	var base: float = p.pos.y if step.x != 0.0 else p.pos.x
	var best := INF
	for k in [-1, 0, 1]:
		var off: float = floorf(base) + 0.5 + k - base
		if absf(off) > 0.55 or absf(off) < 0.001 or absf(off) >= absf(best):
			continue
		var at := p.pos + side * off
		if _blocked_corners(at) == 0 and _blocked_corners(at + step) == 0:
			best = off
	if best != INF:
		_try_move(side * signf(best) * minf(absf(best), step.length()))


func facing_vec() -> Vector2:
	var a := float(player_sprite.dir) * TAU / 8.0
	return Vector2(sin(a), cos(a))


func _find_target() -> void:
	var p := world.player
	var probe := p.pos + facing_vec() * 0.9
	var best := {}
	var bd := 1.5
	for n: NPC in world.present(p.pos, 2.5):
		var d := n.pos.distance_to(probe)
		if d < bd:
			bd = d
			if world.asleep(n):
				best = {"kind": "npc", "npc": n, "label": "%s is asleep" % _who(n)}
			elif world.at_post(n):
				best = {"kind": "shop", "npc": n, "label": "Trade with %s (%s)" % [n.name, world.shop_name(n)]}
			else:
				best = {"kind": "npc", "npc": n, "label": "Talk to %s" % _who(n)}
	for c in world.containers:
		var at := Vector2(int(c.x) + 0.5, int(c.y) + 0.5)
		if at.distance_to(p.pos) > 2.2:
			continue
		var d := at.distance_to(probe)
		if d < bd:
			bd = d
			best = _container_target(c)
	for post in _shop_posts():
		for at: Vector2 in post.cells:
			if at.distance_to(p.pos) > 2.2:
				continue
			var d := at.distance_to(probe)
			if d < bd:
				bd = d
				best = _shop_target(post)
	for i in world.loot.size():
		var d: float = world.loot[i].pos.distance_to(probe)
		if d < bd:
			bd = d
			var from: String = world.loot[i].from
			best = {"kind": "loot", "i": i, "label": ("Take what is left of %s" % from) if from.begins_with("the ") else ("Search %s's belongings" % from)}
	for a: Animal in world.fauna.near(probe, 1.2):
		var d := a.pos.distance_to(probe)
		if d < bd:
			bd = d
			var what := "%s (%s%s)" % [a.label().to_lower(), "young, " if not a.adult(world.minutes) else "", "male" if a.sex == "m" else "female"]
			best = {"kind": "animal", "animal": a, "label": ("A " if a.wild() else "The keeper's ") + what + (": attack to hunt it" if a.wild() else "")}
	var c := Vector2i(floori(probe.x), floori(probe.y))
	if best.is_empty():
		for dc in [Vector2i.ZERO, Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1)]:
			var cell: Vector2i = c + dc
			var dep := world.deposit_at(cell)
			if not dep.is_empty() and int(dep.amount) > 0:
				best = {"kind": "deposit", "dep": dep, "label": ("Mine %s (%d left)" % [GameData.item_name(dep.ore).to_lower(), int(dep.amount)]) if p.tool_of("pickaxe") != ""
						else "%s seam: requires a pickaxe (the smith sells them)" % GameData.item_name(dep.ore)}
				break
			var tr := world.tree_at(cell)
			if not tr.is_empty() and tr.state == "grown":
				best = {"kind": "tree", "tree": tr, "label": "Fell this tree" if p.tool_of("axe") != "" else "A tree: requires an axe (the smith sells them)"}
				break
			for f in world.fields:
				if f.state == "ripe" and Rect2i(int(f.x), int(f.y), int(f.w), int(f.h)).has_point(cell):
					var whose := ""
					for fo: NPC in world.field_workers(f):
						whose = "%s %s's" % [fo.name, fo.family]
						break
					best = {"kind": "field", "field": f, "label": "Harvest wheat (%d left)%s" % [int(f.get("crop", 0)), ("  —  " + whose + " field: taking it is theft") if whose != "" else ""]}
					break
			if not best.is_empty():
				break
	if best.is_empty():
		for id in world.stations:
			var st: Dictionary = world.stations[id]
			var u := Vector2(int(st.use[0]) + 0.5, int(st.use[1]) + 0.5)
			if u.distance_to(p.pos) < 1.2 and st.type in ["forge", "anvil", "workbench", "sawhorse", "stove", "oven"]:
				var no := world.station_refusal(id)
				best = {"kind": "station", "id": id, "label": ("Use the %s" % st.type) if no == "" else "The %s: %s" % [st.type, no]}
		for pl in world.plots:
			var r := Rect2(Vector2(pl.x, pl.y), Vector2(pl.w, pl.h + 1))
			if r.has_point(p.pos) and best.is_empty() and world.place_of(p.pos) == "":
				var lab := "%s, for sale (%d coins, or %d a week)" % [World.cap(world.property.describe(pl)), world.property.price_of(pl), world.property.rent_of(pl)]
				if world.holds(World.PLAYER, pl):
					var site: Dictionary = pl.site
					lab = "Your ground: build here" if site.is_empty() else ("Your building site: %s, %d%% done" % [Construction.kind_name(str(site.get("kind", "house"))), roundi(world.site_progress(pl) * 100.0)] if not site.get("done", false) else World.cap(world.property.describe(pl)))
				elif not world.property.for_sale(pl):
					lab = World.cap(world.property.describe(pl))
				best = {"kind": "plot", "plot": pl, "label": lab}
		for id in world.fauna.pens:
			var pen: Dictionary = world.fauna.pens[id]
			var fa := Vector2(int(pen.feed_at[0]) + 0.5, int(pen.feed_at[1]) + 0.5)
			if fa.distance_to(p.pos) < 1.3:
				best = {"kind": "pen", "pen": pen, "label": "%s pen: %d hungry, trough %d wheat (they eat about %d a day). Feed them" % [GameData.b("animals")[pen.kind].name, world.fauna.hungry(pen), int(pen.trough), world.fauna.daily_need(pen)]}
		# a house the family holds but does not live in, or one the manor offers: its door
		for id in world.buildings:
			var b: Dictionary = world.buildings[id]
			if str(id) == p.home or not world.property.is_home(b) or (Vector2(world.building_door(id)) + Vector2(0.5, 0.5)).distance_to(p.pos) >= 1.3:
				continue
			var mine := world.holds(World.PLAYER, b)
			if mine or world.property.for_sale(b):
				best = {"kind": "property", "thing": b, "label": ("%s, yours: make it your home" % World.cap(world.property.describe(b))) if mine
						else ("%s, empty, the manor's: buy (%d) or lease (%d a week)" % [World.cap(world.property.describe(b)), world.property.price_of(b), world.property.rent_of(b)])}
		# a workshop's door: whose it is, and (its holder) who else may use it
		for id in world.buildings:
			var b: Dictionary = world.buildings[id]
			if str(b.type) == "workshop" and (Vector2(world.building_door(id)) + Vector2(0.5, 0.5)).distance_to(p.pos) < 1.3:
				best = {"kind": "workshop", "thing": b, "label": World.cap(world.property.describe(b)) + (": who may use it" if world.holds(World.PLAYER, b) else "")}
		if p.home != "" and world.buildings.has(p.home):
			var door := Vector2(world.building_door(p.home)) + Vector2(0.5, 0.5)
			if door.distance_to(p.pos) < 1.3:
				best = {"kind": "home", "label": "Your house: rest, store things"}
			elif world.place_of(p.pos) == p.home:
				# inside: the bed rests, the chest is the family's store
				for sp in world.interiors[p.home].spots:
					var at := Vector2(int(sp.at[0]), int(sp.at[1])) + Vector2(0.5, 0.5)
					if at.distance_to(probe) < 0.9 and sp.kind == "bed":
						best = {"kind": "rest", "label": "Your bed: rest until morning"}
					elif at.distance_to(probe) < 0.9 and sp.kind == "chest":
						best = {"kind": "home", "label": "Your chest: store things, rest"}
	# the next step of the player's work for the manor, where it is done
	var mw: ManorWork = world.manor_work
	var mj := mw.job_of("player")
	if not mj.is_empty() and (best.is_empty() or not best.kind in ["npc", "shop"]):
		var at := Vector2(mw.step_cell(mj)) + Vector2(0.5, 0.5)
		if at.distance_to(p.pos) < 1.6:
			best = {"kind": "manor_job", "label": _manor_label(mj)}
	target = best
	# a seam, tree, field or animal is offered when the player stops by it, not flashed while walking past
	var passing: bool = walking and target.get("kind", "") in ["deposit", "tree", "field", "animal"]
	if not gather.is_empty():
		ui.prompt(gather_status())     # gathering: what is going on, not what Use would do
	else:
		ui.prompt("" if passing else target.get("label", ""))


## What the next step of a manor job says at its place.
func _manor_label(j: Dictionary) -> String:
	var mw: ManorWork = world.manor_work
	match mw.step(j):
		"take":
			return "Collect the manor's goods: %s" % mw.describe(j).trim_prefix("Carry ").get_slice(" from ", 0) if j.kind == "haul" else "Collect a load of materials for mending"
		"put":
			if j.kind == "quarry":
				return "Bring %d stone to the works yard (you have %d)" % [int(j.qty), world.player.inv.count("stone")]
			return "Put the manor's goods in %s" % mw.dest_name(j.to)
		"mend":
			return "Mend %s (%d hours)" % [str(j.get("place", "the road")), roundi(float(ManorWork.cfg("mend_minutes")) / 60.0)]
	return ""


## The counters and stalls the player can buy at: {id, stall, cells (tile centres to use)}.
func _shop_posts() -> Array:
	var out := []
	for id in world.stations_of("tavern_counter"):
		var st: Dictionary = world.stations[id]
		out.append({"id": id, "stall": false, "cells": [Vector2(int(st.use[0]) + 0.5, int(st.use[1]) + 0.5), Vector2(int(st.at[0]) + 0.5, int(st.at[1]) + 0.5)]})
	var ids := world.stalls.keys()
	ids.sort()
	for id in ids:
		var s: Dictionary = world.stalls[id]
		out.append({"id": id, "stall": true, "cells": [Vector2(int(s.x) + 0.5, int(s.y) + 0.5)]})
	return out


## A counter or stall: buy from its keeper when they are at it; a stall left alone is its
## merchant's goods, there for the taking (theft).
func _shop_target(post: Dictionary) -> Dictionary:
	var keeper := world.shopkeeper_at(post.id)
	if keeper:
		return {"kind": "shop", "npc": keeper, "label": "Trade with %s (%s)" % [keeper.name, world.shop_name(keeper)]}
	if post.stall:
		var s: Dictionary = world.stalls[post.id]
		return _container_target({"id": post.id, "kind": "stall", "x": int(s.x), "y": int(s.y), "at": post.id})
	return {"kind": "info", "label": "The tavern counter: nobody is serving", "text": "Nobody is serving at the counter now."}


## What using a container does, said in its prompt: "Take pottage (the tavern's) — theft".
func _container_target(c: Dictionary) -> Dictionary:
	var id := world.container_pick(c)
	var whose := world.container_whose(c)
	if id == "":
		return {"kind": "info", "label": "Empty %s (%s)" % [c.kind, whose], "text": "There is nothing in the %s." % c.kind}
	return {"kind": "container", "c": c, "label": "Take %s (%s) — theft" % [GameData.item_name(id).to_lower(), whose]}


## The centre of the counter, stall or container at a map position, or INF.
func _usable_at(wpos: Vector2) -> Vector2:
	var cell := Vector2i(floori(wpos.x), floori(wpos.y))
	var at := Vector2(cell) + Vector2(0.5, 0.5)
	for c in world.containers:
		if int(c.x) == cell.x and int(c.y) == cell.y:
			return at
	for post in _shop_posts():
		for a: Vector2 in post.cells:
			if a.is_equal_approx(at):
				return at
	return Vector2.INF


## Pick the pocket of the villager in the conversation (the talk window's choice).
func pickpocket(n: NPC) -> void:
	ui.hide_all()
	var r: Dictionary = world.pickpocket(n)
	_xp("stealth", 8 if r.ok else 2)
	if not r.ok:
		say(n, "Thief! Get your hand out of my purse!")
	ui.message(r.text)


func _who(n: NPC) -> String:
	if n.role == "bandit":
		return n.name
	return Dialogue.full_name(n)          # "Old Lorekeeper", not "Old Lorekeeper Lorekeeper"


func interact() -> void:
	if target.is_empty():
		return
	# in Gather mode, Use (keys, pad, the touch button) on a resource in front chooses it to gather
	if gather_mode and target.kind in ["deposit", "tree", "field"]:
		var cell: Vector2i = _target_cell(target)
		var hit := ResourceNodes.node_at(world, cell, true)
		if not hit.is_empty():
			select_resource(hit, true)
			return
	_use()


func _target_cell(t: Dictionary) -> Vector2i:
	match str(t.kind):
		"deposit":
			return Vector2i(int(t.dep.x), int(t.dep.y))
		"tree":
			return Vector2i(int(t.tree.x), int(t.tree.y))
		"field":
			return Vector2i(int(t.field.x), int(t.field.y))
	return Vector2i.ZERO


## Do what the current target offers, once (Use; and each cycle of gathering).
func _use() -> void:
	var p := world.player
	match target.kind:
		"npc":
			approach(target.npc)
		"shop":
			ui.show_trade(target.npc)
		"info":
			ui.message(target.text)
		"container":
			var c: Dictionary = target.c
			var place := world.container_place(c)
			var got := world.player_take(c)
			if got == "full":
				ui.message("Your pack is full.")
			elif got == "":
				ui.message("There is nothing to take.")
			else:
				var seen := int(p.crimes[-1].witnesses) if not p.crimes.is_empty() else 0
				if seen == 0:
					_xp("stealth", 3)
				var said := "You take 1 %s from %s. %s" % [GameData.item_name(got).to_lower(), place,
						"Nobody saw." if seen == 0 else ("%d %s saw you!" % [seen, "person" if seen == 1 else "people"])]
				ui.message(said + ((" " + world.last_guard) if world.last_guard != "" else ""))
		"loot":
			var l: Dictionary = world.loot[target.i]
			var taken: int = l.inv.total()
			for id in l.inv.ids():
				var n: int = l.inv.count(id)
				if p.inv.add(id, n):
					l.inv.remove(id, n)
			taken -= l.inv.total()
			p.coins += int(l.coins)
			ui.message("You take %d coins and %d items." % [int(l.coins), taken])
			l.coins = 0
			if l.inv.total() == 0:
				world.loot.remove_at(target.i)
		"deposit":
			var dep: Dictionary = target.dep
			var pick := p.tool_of("pickaxe")
			if pick == "":
				ui.message("Requires a pickaxe. The smith sells them.")
				return
			if dep.ore == "gold_ore" and p.level("mining") < 3:
				ui.message("Gold needs Mining level 3.")
				return
			var secs := float(GameData.b("mine_minutes")) / float(GameData.b("game_minutes_per_second")) * 0.6 / float(GameData.item(pick).get("speed", 1.0))
			start_action("Mining", secs, func():
				var ore := world.mine_unit(dep)
				if ore == "":
					ui.message("The seam is worked out.")
					return
				var n := 1
				if p.level("mining") >= 2 and world.rng.randf() < 0.25:
					var extra := world.mine_unit(dep)
					if extra != "":
						n += 1
				if not p.inv.add(ore, n):
					ui.message("Your pack is full.")
				if p.inv.wear(pick, 1 if p.level("mining") < 4 or world.rng.randf() < 0.5 else 0):
					ui.message("Your %s broke." % GameData.item_name(pick).to_lower())
					if p.tool == pick:
						p.tool = ""
				ui.message("Mined %d %s." % [n, GameData.item_name(ore).to_lower()])
				_xp("mining", 8 * n))
		"tree":
			var axe := p.tool_of("axe")
			if axe == "":
				ui.message("Requires an axe. The smith sells them.")
				return
			var secs := float(GameData.b("chop_minutes")) / float(GameData.b("game_minutes_per_second")) * 0.5 / float(GameData.item(axe).get("speed", 1.0))
			if p.level("woodcutting") >= 3:
				secs *= 0.7
			var tr: Dictionary = target.tree
			start_action("Felling", secs, func():
				var logs := world.fell(tr, 1 if p.level("woodcutting") >= 2 else 0)
				if logs > 0:
					if not p.inv.add("log", logs):
						ui.message("Your pack is full.")
					p.inv.wear(axe, 3)
					ui.message("Felled the tree: %d logs." % logs)
					_xp("woodcutting", 12))
		"station":
			ui.show_craft(target.id)
		"field":
			var f: Dictionary = target.field
			start_action("Harvesting", 2.5, func():
				var got := world.player_harvest(f)
				ui.message("You gather %d wheat." % got if got > 0 else "Nothing left to harvest."))
		"pen":
			var put := world.fauna.feed(target.pen, p.inv, 5)
			ui.message("You put %d wheat in the trough." % put if put > 0 else "You have no wheat to feed them.")
		"animal":
			ui.message("Attack (Space) to hunt it." if target.animal.wild() else "These belong to the keeper. Killing them is theft.")
		"plot":
			ui.show_build(target.plot)
		"workshop":
			ui.show_workshop(target.thing)
		"property":
			ui.show_deal(target.thing)
		"home":
			ui.show_home()
		"rest":
			rest()
		"manor_job":
			var mw: ManorWork = world.manor_work
			var mj := mw.job_of("player")
			if mj.is_empty():
				return
			var pay := int(mj.reserved)
			var finish := func(ok: bool) -> void:
				if not ok:
					ui.message("You need %d stone for the manor: mine it at the stone seams." % int(mj.qty) if mj.kind == "quarry" else "There is nothing here to take.")
				elif mw.job_of("player").is_empty():
					ui.message("Work for the manor done. The manor pays you %d coins." % pay)
				else:
					ui.message("You take the manor's goods. %s" % ui._manor_next(mj))
			if mw.step(mj) == "mend":
				var secs := float(ManorWork.cfg("mend_minutes")) / float(GameData.b("game_minutes_per_second")) * 0.6
				start_action("Mending", secs, func(): finish.call(mw.do_step(mj, "player", p.inv)))
			else:
				finish.call(mw.do_step(mj, "player", p.inv))


func start_action(label: String, secs: float, done: Callable) -> void:
	action = {"label": label, "left": secs, "total": secs, "done": done}
	move_to = Vector2.INF


func _xp(skill: String, n: int) -> void:
	var up := world.player.gain(skill, n)
	if up > 0:
		var s: Dictionary = GameData.skills[skill]
		var unlock: String = s.unlocks.get(str(up), "")
		ui.message("%s is now level %d!%s" % [s.name, up, (" Unlocked: " + unlock) if unlock != "" else ""])


## Craft a recipe at a station (called from the craft panel). Same recipe data as the NPCs.
## `station`: the station worked at (the craft window's); without one, the one of the recipe's kind the
## player stands at. A workshop not theirs needs leave, and a villager working at a station the player
## does not hold is waited for (World.station_refusal); the player's work takes the station meanwhile.
func craft(recipe: String, station := "") -> void:
	var r: Dictionary = GameData.recipes[recipe]
	var p := world.player
	if station == "":
		for id in world.stations_of(str(r.station)):
			if (Vector2(world.station_use(id)) + Vector2(0.5, 0.5)).distance_to(p.pos) < 2.0:
				station = id
	if station != "":
		var no := world.station_refusal(station)
		if no != "":
			ui.message(no)
			return
	if p.level(r.skill) < int(r.level):
		ui.message("Needs %s level %d." % [GameData.skills[r.skill].name, int(r.level)])
		return
	if not p.inv.has_all(r.in):
		ui.message("You do not have the materials.")
		return
	var secs := float(r.minutes) / float(GameData.b("game_minutes_per_second")) * 0.5
	if station != "":
		world.reserve_for_player(station, secs * float(GameData.b("game_minutes_per_second")) + 1.0)
	ui.hide_all()
	start_action("Crafting", secs, func():
		if not p.inv.remove_all(r.in):
			return
		for id in r.out:
			p.inv.add(id, int(r.out[id]))
		_xp(r.skill, int(r.xp))
		ui.message("Made %s." % ", ".join(r.out.keys().map(func(k): return GameData.item_name(k)))))


# ---------------------------------------------------------------- combat ---------------------
## A swing of the weapon at whatever is in front; with `only`, it can hit nobody else.
func attack(only: Object = null) -> void:
	var p := world.player
	if p.attack_cd > 0.0 or not action.is_empty():
		return
	p.attack_cd = 0.6
	player_sprite.play("sword", true)
	var probe := p.pos + facing_vec() * 0.8
	for n: NPC in world.present(probe, 1.1):
		if only == null or only == n:
			_hit(n, p.damage())
			_xp("combat", 4)
			return
	for a: Animal in world.fauna.near(probe, 1.1):
		if only == null or only == a:
			_hit_animal(a, p.damage())
			return


## The touch Attack button: fight a foe within reach (a bandit, someone fighting you, or game);
## with none, wait for a tap on who or what to attack. Villagers are only attacked by choice.
func attack_button() -> void:
	attack_mode = not attack_mode
	if attack_mode and gather_mode:
		gather_button()                # Attack and Gather exclude each other
	if not attack_mode:
		chase = null
		strike_pending = false
	ui.set_attack_mode(attack_mode)
	ui.message("Attack mode: tap who or what to attack. Tap Attack again to stop." if attack_mode else "Attack mode off.")


## Mark a person or animal with the sword and strike it: the player walks over if needed. Each
## further tap (or right-click) on it is another strike; picking someone else moves the sword.
func strike(who: Object) -> void:
	chase = who
	strike_pending = true


## The person or animal drawn at a map position (sprites stand above their feet), or null.
func _creature_at(wpos: Vector2) -> Object:
	var at := wpos + Vector2(0, 0.4)
	var best: Object = null
	var bd := 0.9
	for n: NPC in world.present(at, bd):
		if not _covered(n) and n.pos.distance_to(at) < bd:
			bd = n.pos.distance_to(at)
			best = n
	for a: Animal in world.fauna.near(at, bd):
		if a.pos.distance_to(at) < bd:
			bd = a.pos.distance_to(at)
			best = a
	return best


## Follow the marked target, and strike when a strike is pending and it is in reach. The mark is
## dropped when it falls, hides indoors or gets away.
func _chase_step() -> void:
	if chase == null:
		return
	var p := world.player
	if not chase.alive or (chase is NPC and _covered(chase)) or chase.pos.distance_to(p.pos) > 12.0:
		chase = null
		strike_pending = false
		move_to = Vector2.INF
		return
	var d: Vector2 = chase.pos - p.pos
	if d.length() > 1.0:
		move_to = chase.pos
		return
	move_to = Vector2.INF
	if strike_pending and p.attack_cd <= 0.0 and action.is_empty():
		player_sprite.face(d)
		attack(chase)
		strike_pending = false


## Hunting: a wild animal killed by the player leaves its meat (and hide) where it fell. Killing
## livestock is theft from its keeper, a crime like attacking a villager.
func _hit_animal(a: Animal, dmg: float) -> void:
	var before := a.hp
	a.hp -= dmg
	_hit_fx(animal_sprites.get(a.id), before, a.hp, dmg)
	_xp("combat", 2)
	if a.hp > 0.0:
		return
	var keeper: NPC = null
	if not a.wild():
		keeper = world.pen_keeper(world.fauna.pens[a.area])
	var what := a.label().to_lower()
	var bag: Inventory = world.fauna.kill(a)
	world.loot.append({"pos": a.pos, "inv": bag, "coins": 0, "from": "the " + what})
	if keeper != null:
		_crime(keeper, "%s killed my %s" % [world.player.name, what])
		world.note("%s %s killed one of %s %s's animals." % [world.player.name, world.player.family, keeper.name, keeper.family])


func _hit(n: NPC, dmg: float) -> void:
	var dealt := maxf(0.5, dmg - n.armor * 0.5)
	n.hp -= dealt
	_hit_fx(sprites.get(n.id), n.max_hp, n.hp, dealt)
	# the blow wakes a sleeper and the noise wakes those near, who then see it (owner rule)
	world.wake_near(n.pos, float(GameData.b("sleep_wake_radius")))
	if n.role != "bandit":
		_crime(n)
	elif n.target == -1:
		n.target = -2
	if n.hp <= 0.0:
		world.kill(n, "slain by %s %s" % [world.player.name, world.player.family])


## A blow that landed (Build 8 report: no sign of damage): the target flashes red, the damage floats
## up from its head for a moment, and a health bar over it shows what is left for a few seconds.
## `top`: full health (a villager's max_hp; an animal's health when first hit).
func _hit_fx(sprite: Node2D, top: float, hp: float, dmg: float) -> void:
	if sprite == null or not is_instance_valid(sprite):
		return
	top = maxf(float(sprite.get_meta("full_hp", top)), top)
	sprite.set_meta("full_hp", top)
	sprite.modulate = Color(1.0, 0.35, 0.35)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.25)
	var num := Label.new()
	num.text = str(int(ceilf(dmg)))
	num.add_theme_font_size_override("font_size", 10)
	num.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	num.add_theme_color_override("font_outline_color", Color.BLACK)
	num.add_theme_constant_override("outline_size", 3)
	num.position = sprite.position + Vector2(-6, -34)
	num.z_index = 50
	actors.add_child(num)
	var tw := create_tween().set_parallel()
	tw.tween_property(num, "position:y", num.position.y - 14.0, 0.8)
	tw.tween_property(num, "modulate:a", 0.0, 0.8)
	tw.chain().tween_callback(num.queue_free)
	var bar: Node2D = sprite.get_node_or_null("HpBar")
	if bar == null:
		bar = Node2D.new()
		bar.name = "HpBar"
		bar.z_index = 40
		bar.position = Vector2(-8, -24)
		var back := ColorRect.new()
		back.name = "Back"
		back.size = Vector2(16, 2)
		back.color = Color(0.15, 0.1, 0.08)
		bar.add_child(back)
		var fill := ColorRect.new()
		fill.name = "Fill"
		fill.size = Vector2(16, 2)
		fill.color = Color(0.85, 0.15, 0.15)
		bar.add_child(fill)
		sprite.add_child(bar)
	(bar.get_node("Fill") as ColorRect).size.x = 16.0 * clampf(hp / top, 0.0, 1.0)
	bar.visible = true
	bar.set_meta("until", Time.get_ticks_msec() + 3000)
	get_tree().create_timer(3.1).timeout.connect(func():
		if is_instance_valid(bar) and Time.get_ticks_msec() >= int(bar.get_meta("until", 0)):
			bar.visible = false)


## Attacking a villager is a crime: guards who see it and adults who are hit fight back.
## `memory` is what the victim remembers (by default that the player attacked them).
func _crime(victim: NPC, memory := "") -> void:
	victim.remember(memory if memory != "" else "attacked by %s" % world.player.name)
	if victim.role == "adult":
		victim.target = -2
	for g: NPC in world.near(victim.pos, 15.0):
		if g.job == "guard":
			g.target = -2
	world.note("%s %s attacked %s %s." % [world.player.name, world.player.family, victim.name, victim.family])


func fireball() -> void:
	var p := world.player
	if not p.spells.get("fireball", false):
		ui.message("You do not know any spells. The Sage in the hut north of the tavern teaches them.")
		return
	var cd := float(GameData.b("fireball_cooldown"))
	if p.level("magic") >= 2:
		cd = 4.0
	if p.fireball_cd > 0.0 or p.stamina < float(GameData.b("fireball_stamina")):
		return
	p.fireball_cd = cd
	p.stamina -= float(GameData.b("fireball_stamina"))
	player_sprite.play("throw", true)
	var node := Sprite2D.new()
	node.texture = load("res://assets/icons/fireball.png")
	node.z_index = 5
	actors.add_child(node)
	projectiles.append({"node": node, "pos": p.pos + facing_vec() * 0.6, "dir": facing_vec(), "left": 8.0})
	_xp("magic", 6)


func _projectiles_step(delta: float) -> void:
	for pr in projectiles.duplicate():
		var step: Vector2 = pr.dir * 9.0 * delta
		pr.pos += step
		pr.left -= step.length()
		pr.node.position = pr.pos * T
		pr.node.rotation += delta * 12.0
		var hit := false
		var dmg := 14.0 * (1.5 if world.player.level("magic") >= 3 else 1.0)
		for n: NPC in world.present(pr.pos, 0.6):
			_hit(n, dmg)
			hit = true
			break
		if not hit:
			for a: Animal in world.fauna.near(pr.pos, 0.6):
				_hit_animal(a, dmg)
				hit = true
				break
		if hit or pr.left <= 0.0 or map.is_solid(Vector2i(floori(pr.pos.x), floori(pr.pos.y))):
			pr.node.queue_free()
			projectiles.erase(pr)


# ---------------------------------------------------------------- placing a building ----------
## Choose where to build (owner rule: free placement anywhere legal). The footprint follows the mouse,
## moves a tile at a time with the arrow keys, WASD, the d-pad or the left stick, and goes where a
## finger taps; green where it may go, red with the reason where it may not (Construction.can_place:
## the land office's check, the house-first rule, a reachable door). Place (E, Enter, the pad's A, a
## click on the footprint, or the Place button) opens the deal for the ground; Esc, the pad's B or
## Cancel stops. The game waits meanwhile.
func begin_placement(kind: String) -> void:
	ui.hide_all()
	var size := world.construction.footprint(kind)
	var front := world.player.pos + facing_vec() * (size.y / 2.0 + 1.0)
	placing = {"kind": kind, "at": Vector2i(floori(front.x) - size.x / 2, floori(front.y) - size.y / 2)}
	paused = true
	move_to = Vector2.INF
	ui.show_placing(true)
	_update_ghost()


## Back to choosing after the deal window (Choose another place).
func resume_placement() -> void:
	ui.hide_all()
	paused = true
	ui.show_placing(true)
	_update_ghost()


func end_placement() -> void:
	placing = {}
	ghost.visible = false
	ui.show_placing(false)
	recenter()
	if not ui.modal():
		paused = false


func place_rect() -> Rect2i:
	return Rect2i(placing.at, world.construction.footprint(placing.kind))


## Why the footprint cannot go where it is, "" if it can.
func place_refusal() -> String:
	return world.construction.can_place(placing.kind, place_rect(), World.PLAYER)


func _update_ghost() -> void:
	var r := place_rect()
	var why := place_refusal()
	ghost.show_at(r, world.construction.door_step(placing.kind, r) - Vector2i(0, 1), why == "")
	var t: Dictionary = world.construction.ground_terms(r)
	var name := Construction.kind_name(placing.kind)
	ui.placing_text(("%s here: the ground %s, %d coins or %d a week." % [World.cap(name), world.where(r), int(t.price), int(t.rent)]) if why == ""
			else "%s cannot go here: %s." % [World.cap(name), why], why == "")
	# the view follows the footprint, which sits in the upper middle, clear of the placing bar
	var view := get_viewport().get_visible_rect().size / camera.zoom / T
	look_at_tile(Vector2(r.position) + Vector2(r.size) / 2.0 + Vector2(0, view.y * 0.16))


## Put the footprint's middle on a cell.
func move_ghost_to(cell: Vector2i) -> void:
	var size := world.construction.footprint(placing.kind)
	var at := cell - size / 2
	at.x = clampi(at.x, 0, map.w - size.x)
	at.y = clampi(at.y, 0, map.h - size.y)
	if at != placing.at:
		placing.at = at
		_update_ghost()


func move_ghost(d: Vector2i) -> void:
	var size := world.construction.footprint(placing.kind)
	move_ghost_to(Vector2i(placing.at) + d + size / 2)


## Place: the deal for the ground, when the footprint may go there.
func confirm_placement() -> void:
	var why := place_refusal()
	if why != "":
		ui.message("You cannot build here: %s." % why)
		return
	ui.show_placing(false)
	ghost.visible = true
	ui.show_place_deal(placing.kind, place_rect())


## A held stick, d-pad or arrow key moves the footprint a tile at a time.
func _placing_step(delta: float) -> void:
	if ui.modal():
		return
	place_step = maxf(0.0, place_step - delta)
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down", 0.4)
	if v == Vector2.ZERO:
		place_step = 0.0
		return
	if place_step > 0.0:
		return
	place_step = 0.14
	move_ghost(Vector2i(roundi(v.x), roundi(v.y)))


## Input while placing; returns true when it was handled.
func _placing_input(e: InputEvent) -> bool:
	if placing.is_empty() or ui.modal():
		return false
	if e is InputEventMouseMotion and e.device != InputEvent.DEVICE_ID_EMULATION and not mid_drag and touch_points.is_empty():
		move_ghost_to(_cell_at(e.position))
		return true
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed and e.device != InputEvent.DEVICE_ID_EMULATION:
		if ui.blocks(e.position):
			return false
		var cell := _cell_at(e.position)
		if place_rect().has_point(cell):
			confirm_placement()
		else:
			move_ghost_to(cell)
		return true
	if e is InputEventScreenTouch and not e.pressed and touch_points.size() <= 1 and not multi_touch:
		if not ui.blocks(e.position):
			move_ghost_to(_cell_at(e.position))       # a tap moves the footprint; Place confirms
	if e.is_action_pressed("interact") or (e is InputEventKey and e.is_action_pressed("ui_accept")) or (e is InputEventJoypadButton and e.is_action_pressed("ui_accept")):
		confirm_placement()
		return true
	if e.is_action_pressed("pause") or e.is_action_pressed("ui_cancel"):
		end_placement()
		ui.message("Building put off.")
		return true
	return false


func _cell_at(screen_pos: Vector2) -> Vector2i:
	var wp := (get_canvas_transform().affine_inverse() * screen_pos) / T
	return Vector2i(floori(wp.x), floori(wp.y))


# ---------------------------------------------------------------- touch ----------------------
func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventJoypadMotion and (e.axis == JOY_AXIS_TRIGGER_LEFT or e.axis == JOY_AXIS_TRIGGER_RIGHT):
		var down: bool = e.axis_value > 0.6
		if down and not trigger_held.get(e.axis, false) and ui.modal():
			ui.cycle_focus(1 if e.axis == JOY_AXIS_TRIGGER_RIGHT else -1)
		trigger_held[e.axis] = down
		return
	if world == null:
		return
	if _placing_input(e):
		return
	if e is InputEventScreenTouch:
		if e.pressed:
			touch_points[e.index] = e.position
			if touch_points.size() == 2:
				multi_touch = true
				pinch_start = touch_points.values()[0].distance_to(touch_points.values()[1])
				zoom_start = camera.zoom.x
				pinch_mid = (touch_points.values()[0] + touch_points.values()[1]) / 2.0
		else:
			# a lift is a tap only for a finger that went down on the map, alone
			var mine := touch_points.erase(e.index)
			if touch_points.is_empty():
				if mine and not multi_touch and not ui.modal():
					_tap(e.position)
				multi_touch = false
	elif e is InputEventScreenDrag:
		if not touch_points.has(e.index):
			return
		touch_points[e.index] = e.position
		if touch_points.size() == 2 and pinch_start > 0.0:
			# two fingers: their distance zooms, their midpoint drags the view
			var d: float = touch_points.values()[0].distance_to(touch_points.values()[1])
			_set_zoom(zoom_start * d / pinch_start)
			var mid: Vector2 = (touch_points.values()[0] + touch_points.values()[1]) / 2.0
			if not ui.modal() and running:
				pan_camera(pinch_mid - mid)
			pinch_mid = mid
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_MIDDLE:
		mid_drag = e.pressed and not ui.modal()
	elif e is InputEventMouseMotion and mid_drag:
		pan_camera(-e.relative)
	elif e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(camera.zoom.x * 1.1)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(camera.zoom.x / 1.1)
		elif e.button_index == MOUSE_BUTTON_LEFT and e.device != InputEvent.DEVICE_ID_EMULATION and not ui.modal():
			_tap(e.position)
		elif e.button_index == MOUSE_BUTTON_RIGHT and not ui.modal() and not paused:
			# right-click: strike whoever is under the pointer, without attack mode
			var who := _creature_at((get_canvas_transform().affine_inverse() * e.position) / T)
			if who != null:
				strike(who)
	if e is InputEventJoypadButton and e.is_action_pressed("ui_cancel") and ui.modal() and not ui.panel_kind in ["title", "creation", "origin", "death"]:
		ui.hide_all()
	if e.is_action_pressed("zoom_in"):
		_set_zoom(camera.zoom.x * 1.2)
	if e.is_action_pressed("zoom_out"):
		_set_zoom(camera.zoom.x / 1.2)
	if e.is_action_pressed("pause"):
		if ui.modal():
			ui.hide_all()
		elif running:
			ui.show_pause()
	if e.is_action_pressed("map"):
		ui.toggle_map()
	if e.is_action_pressed("recenter") and not ui.modal():
		recenter()


# ---------------------------------------------------------------- looking around -------------
## Move the view by a screen distance (a two-finger or middle-button drag, the right stick): the
## camera stops following the player until recentred. Kept over the map.
func pan_camera(screen_delta: Vector2) -> void:
	if world == null or screen_delta == Vector2.ZERO:
		return
	if not cam_free:
		cam_at = camera.get_screen_center_position()
	look_at_tile((cam_at + screen_delta / camera.zoom) / T)


## Where the camera looks while following the player at `at` (pixels): it stays put while the
## player is inside the dead zone and is pushed along by its edge, never past the map's edges.
func _follow(at: Vector2) -> Vector2:
	var box := get_viewport().get_visible_rect().size / camera.zoom * DEAD_ZONE / 2.0
	for k in 2:
		follow_at[k] = clampf(follow_at[k], at[k] - box[k], at[k] + box[k])
	follow_at = _in_view(follow_at)
	return follow_at


## A camera position (pixels) moved just enough that the view stays over the map.
func _in_view(at: Vector2) -> Vector2:
	var half := get_viewport().get_visible_rect().size / camera.zoom / 2.0
	var world_px := Vector2(map.w, map.h) * T
	for k in 2:
		at[k] = clampf(at[k], half[k], world_px[k] - half[k]) if world_px[k] > half[k] * 2.0 else world_px[k] / 2.0
	return at


## Look at a spot on the map (a tile position), without moving the player.
func look_at_tile(tile: Vector2) -> void:
	cam_at = _in_view(tile * T)
	if not cam_free:
		cam_free = true
		camera.position_smoothing_enabled = false        # the view sticks to the fingers
		ui.show_recenter(true)


## Follow the player again; the camera glides back.
func recenter() -> void:
	cam_free = false
	if world and camera:
		follow_at = _in_view(world.player.pos * T)
	if camera:
		camera.position_smoothing_enabled = shot_path == ""
	ui.show_recenter(false)


## The right stick looks around.
func _look_step(delta: float) -> void:
	if ui.modal():
		return
	var look := Input.get_vector("look_left", "look_right", "look_up", "look_down", 0.2)
	if look != Vector2.ZERO:
		pan_camera(look * PAN_SPEED * delta)


## Which controls are in use, from the latest input: the HUD follows (touch buttons, prompts).
func _input(e: InputEvent) -> void:
	var s := scheme
	if e is InputEventScreenTouch or e is InputEventScreenDrag:
		s = "touch"
	elif e is InputEventJoypadButton or (e is InputEventJoypadMotion and absf(e.axis_value) > 0.5):
		s = "gamepad"
	elif e is InputEventKey and get_viewport().gui_get_focus_owner() is LineEdit:
		pass                          # typing into a text box (a phone's on-screen keyboard sends keys too)
	elif e is InputEventKey or (e is InputEventMouseButton and e.device != InputEvent.DEVICE_ID_EMULATION) \
			or (e is InputEventMouseMotion and e.device != InputEvent.DEVICE_ID_EMULATION and e.relative.length() > 3.0):
		s = "kbm"
	if s != scheme:
		scheme = s
		ui.set_scheme(s)


## A changed interface size: relayout, and keep the map the same size on screen.
func apply_settings() -> void:
	settings.apply(get_tree())
	var vs := settings.layout_height() / 720.0
	if camera:
		camera.zoom *= vs / view_scale
	view_scale = vs
	settings.save_file()
	ui.set_scheme(scheme)


func _set_zoom(z: float) -> void:
	z = clampf(z, 1.5 * view_scale, 6.0 * view_scale)
	camera.zoom = Vector2(z, z)


## Tap or click: on something next to the player, act on it; elsewhere, walk there.
func _tap(screen_pos: Vector2) -> void:
	if world == null or paused:
		return
	if ui.blocks(screen_pos):
		return
	var wpos := (get_canvas_transform().affine_inverse() * screen_pos) / T
	if gather_mode:
		var hit := _resource_tap(wpos)
		if hit.is_empty():
			ui.message("Nothing to gather there: tap a seam, a tree, a ripe field or game.")
		else:
			select_resource(hit, true)
		return
	if attack_mode:
		var who := _creature_at(wpos)
		if who != null:
			strike(who)
			return
		chase = null                  # open ground: walk there, still in attack mode
		strike_pending = false
		move_to = wpos
		return
	chase = null
	talk_to = null
	reach_to = Vector2.INF
	var tapped := _creature_at(wpos)
	if tapped is NPC and tapped.role != "bandit":
		talk_to = tapped                  # walk up to them (following if they move) and talk
		return
	# a seam, a tree or a field: walk to it and use it once (B7-011; Gather mode keeps going)
	var res := _resource_tap(wpos)
	if not res.is_empty() and str(res.def.match.kind) != "animal":
		select_resource(res, false)
		return
	var use := _usable_at(wpos)
	if use != Vector2.INF:
		reach_to = use                    # a counter, stall or container: walk up to it and use it
		if use.distance_to(world.player.pos) > 1.7:
			move_to = use
		return
	if wpos.distance_to(world.player.pos) < 1.8:
		player_sprite.face(wpos - world.player.pos)
		_find_target()
		if not target.is_empty():
			interact()
			return
	move_to = wpos


# ---------------------------------------------------------------- saving ---------------------
## Save safely (SaveStore): written aside, verified, then swapped in, the previous save kept as the
## backup. Returns whether it saved; a failure leaves the last save unchanged and says why.
func save_game(show := true) -> bool:
	if world == null or not world.player.alive:
		return false
	if save_blocked != "":
		if show:
			ui.message("Not saved: %s." % save_blocked, 8.0)
		return false
	var r := SaveStore.write_text(save_path, JSON.stringify(world.to_dict(), "", true, true))          # full precision: times and positions reload exactly
	if not r.ok:
		if show or not save_failing:
			ui.message("Could not save: %s. Your last save is unchanged." % r.reason, 8.0)
		save_failing = true
		return false
	save_failing = false
	if show:
		ui.message("Saved.")
	return true


## Starting a new game over an existing one keeps the old game aside as "save1.previous.json"
## (replacing the one kept before) instead of letting the new game overwrite it; a save that cannot
## be read is moved aside unchanged, as when continuing.
func _keep_previous_game() -> void:
	var prev := save_path.get_basename() + PREVIOUS_SUFFIX
	var r := SaveStore.inspect(save_path, World.SAVE_VERSION)
	if r.state != "ok" and r.state != "missing":
		if SaveStore.preserve(save_path, r.state) == "":
			save_blocked = "an old save that could not be read could not be moved aside, so saving is off this session to protect it"
		return
	var src := save_path if r.state == "ok" else save_path + SaveStore.BAK
	if SaveStore.inspect(src, World.SAVE_VERSION).state != "ok":
		return
	if FileAccess.file_exists(prev):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(prev))
	DirAccess.rename_absolute(ProjectSettings.globalize_path(src), ProjectSettings.globalize_path(prev))


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		# Android's Back: closes an open window (the map, the pack...); otherwise saves and quits as before
		if ui and ui.modal() and ui.close_btn.visible:
			ui.hide_all()
			return
		if running:
			save_game(false)
		get_tree().quit()
		return
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if running:
			save_game(false)


func continue_as_heir() -> void:
	world.continue_as_heir()
	player_sprite.setup(world.player.sprite)
	player_sprite.play("idle")
	ui.hide_all()
	save_game(false)


## Sleep at home until morning: the world keeps running (same rules), just quickly.
func rest() -> void:
	var p := world.player
	var h := world.hour()
	var until := 6.0 if h < 6.0 else 30.0
	var mins := (until - h) * 60.0 if h >= 18.0 or h < 6.0 else 120.0
	var steps := int(mins / float(GameData.b("game_minutes_per_second")) / 0.5)
	for i in steps:
		world.update(0.5)
	p.hp = p.hp_cap()
	p.stamina = p.stamina_cap()
	ui.message("You rest. It is now %s." % world.clock_text())
	save_game(false)


# ---------------------------------------------------------------- screenshots ----------------
## Press the button with this caption under `root` (screenshots of a conversation's next step).
func _press(root: Node, caption: String) -> bool:
	for c in root.find_children("*", "Button", true, false):
		if (c as Button).text == caption:
			(c as Button).pressed.emit()
			return true
	return false


func _screenshot_step(_delta: float) -> void:
	shot_frames += 1
	if shot_frames == 30:
		if OS.get_environment("MML_SHOT_DEBUG") != "":
			for id in diamonds:
				var nn: NPC = world.npc(int(id))
				print("marker ", id, " ", nn.name, " inside=", world.place_of(nn.pos), " home=", nn.home, " at ", diamonds[id].position / T, " npc ", nn.pos, " cam ", camera.get_screen_center_position() / T)
		var img := get_viewport().get_texture().get_image()
		img.save_png(shot_path)
		print("screenshot saved to ", shot_path)
		get_tree().quit()


# ---------------------------------------------------------------- gathering ------------------
## The Gather button (B7-012): on, a tap chooses a resource to gather until it runs out; off stops
## gathering and walking to it. Gather and Attack exclude each other.
func gather_button() -> void:
	gather_mode = not gather_mode
	if gather_mode and attack_mode:
		attack_button()
	if not gather_mode:
		stop_gather("")
	ui.set_gather_mode(gather_mode)
	ui.message("Gather: tap a seam, a tree, a ripe field or game; you gather it until it runs out. Tap Gather again to stop."
			if gather_mode else "Gather off.")


## The resource drawn at a map position: an animal by its sprite, else the seam, tree (trunk or
## canopy) or field at that cell exactly (ResourceNodes, the one definition of what can be gathered).
func _resource_tap(wpos: Vector2) -> Dictionary:
	var who := _creature_at(wpos)
	if who is Animal:
		var d := ResourceNodes.def_for("animal", (who as Animal).species)
		return {} if d.is_empty() else {"def": d, "ref": who}
	if who != null:
		return {}
	return ResourceNodes.node_at(world, Vector2i(floori(wpos.x), floori(wpos.y)), true)


## Choose a resource: say why not if it cannot be gathered (no tool, worked out, not ripe, the keeper's),
## warn once before taking someone's field, then walk to it and gather (`continuous`: until it runs
## out; else once).
func select_resource(hit: Dictionary, continuous: bool) -> void:
	var d: Dictionary = hit.def
	var why := ResourceNodes.can_harvest(world, d, hit.ref)
	if why != "":
		stop_gather("")
		ui.message(why)
		return
	var note := ResourceNodes.theft_note(world, d, hit.ref)
	var hired: bool = str(d.match.kind) == "field" and not world.quests.hired_on(hit.ref).is_empty()
	if note != "" and not hired and gather_warned != hit.ref:
		gather_warned = hit.ref
		ui.message("%s. Tap it again to take it anyway." % World.cap(note))
		return
	stop_gather("")
	talk_to = null
	reach_to = Vector2.INF
	gather = {"def": d, "ref": hit.ref, "continuous": continuous, "hp": world.player.hp, "tries": 0, "cycles": 0}
	if str(d.get("action", "")) == "attack":
		strike(hit.ref)                # game is hunted with the weapon, as in attack mode


## Stop gathering (and walking to it); `why` is said if not "".
func stop_gather(why: String) -> void:
	if gather.is_empty():
		return
	if str(gather.def.get("action", "")) == "attack" and chase == gather.ref:
		chase = null
		strike_pending = false
	gather = {}
	move_to = Vector2.INF
	if why != "":
		ui.message(why)


## Each frame: walk to the chosen resource, then gather it a cycle at a time through the usual action
## (its time, tool wear, yield, depletion, theft and inventory rules), until it runs out, the pack is
## full, the tool is gone, the player is hurt, or (a single use) after one cycle.
func _gather_step() -> void:
	if gather.is_empty() or not action.is_empty():
		return
	var p := world.player
	var d: Dictionary = gather.def
	var ref = gather.ref
	if p.hp < float(gather.hp) - 0.01:
		stop_gather("You stop gathering: something is hurting you.")
		return
	gather.hp = p.hp
	if int(gather.cycles) > 0 and not gather.continuous:
		stop_gather("")
		return
	var why := ResourceNodes.can_harvest(world, d, ref)
	if why != "" or ResourceNodes.remaining(world, d, ref) <= 0:
		stop_gather(why if why != "" else "Nothing is left here.")
		return
	if str(d.get("action", "")) == "attack":
		if chase != ref:
			chase = ref
		strike_pending = true          # keep striking until it falls
		return
	for id in ResourceNodes.products(d):
		if not p.inv.can_add(id):
			stop_gather("Your pack is full.")
			return
	var stand := _gather_stand(d, ref)
	if p.pos.distance_to(stand) > 0.6:
		if move_to == Vector2.INF:
			gather.tries = int(gather.tries) + 1
			if int(gather.tries) > 3:
				stop_gather("You can't reach it from here.")
				return
			move_to = stand
		return
	move_to = Vector2.INF
	gather.tries = 0
	var at := Vector2(ResourceNodes.cell_of(world, d, ref)) + Vector2(0.5, 0.5)
	if str(d.match.kind) == "field":
		at = p.pos + Vector2(0, -0.1)
	player_sprite.face(at - p.pos)
	target = _gather_target(d, ref)
	gather.cycles = int(gather.cycles) + 1
	_use()


## Where to stand to gather: beside a seam or a tree's trunk (the free cell nearest the player), on
## the nearest cell of a field.
func _gather_stand(d: Dictionary, ref) -> Vector2:
	var p := world.player
	if str(d.match.kind) == "field":
		var r := Rect2(Vector2(int(ref.x), int(ref.y)), Vector2(int(ref.w), int(ref.h)))
		var c := Vector2(clampf(p.pos.x, r.position.x + 0.5, r.end.x - 0.5), clampf(p.pos.y, r.position.y + 0.5, r.end.y - 0.5))
		return Vector2(floori(c.x), floori(c.y)) + Vector2(0.5, 0.5)
	var cell := ResourceNodes.cell_of(world, d, ref)
	return Vector2(world.brain.beside(cell, Vector2i(floori(p.pos.x), floori(p.pos.y)))) + Vector2(0.5, 0.5)


func _gather_target(d: Dictionary, ref) -> Dictionary:
	match str(d.match.kind):
		"deposit":
			return {"kind": "deposit", "dep": ref, "label": ""}
		"tree":
			return {"kind": "tree", "tree": ref, "label": ""}
		"field":
			return {"kind": "field", "field": ref, "label": ""}
	return {}


## What the HUD says while gathering: walking to it, or the action and what is left.
func gather_status() -> String:
	if gather.is_empty():
		return ""
	var d: Dictionary = gather.def
	var left := ResourceNodes.remaining(world, d, gather.ref)
	if not action.is_empty() or str(d.get("action", "")) == "attack" and chase == gather.ref:
		return "%s the %s  ·  %d left" % [str(d.get("verb", "Gathering")), str(d.get("name", "")).to_lower(), left]
	return "Walking to the %s" % str(d.get("name", "")).to_lower()


## The outline round the chosen resource (a field: its edge).
func _sync_gather_mark() -> void:
	if gather_mark == null:
		gather_mark = Line2D.new()
		gather_mark.width = 2.0
		gather_mark.default_color = Color(1.0, 0.85, 0.3, 0.95)
		gather_mark.z_index = MARKER_Z
		add_child(gather_mark)
	gather_mark.visible = not gather.is_empty()
	if gather.is_empty():
		return
	var d: Dictionary = gather.def
	var r := Rect2()
	match str(d.match.kind):
		"field":
			r = Rect2(Vector2(int(gather.ref.x), int(gather.ref.y)), Vector2(int(gather.ref.w), int(gather.ref.h)))
		"tree":
			r = Rect2(Vector2(int(gather.ref.x), int(gather.ref.y) - 1), Vector2(1, 2))
		"animal":
			r = Rect2((gather.ref as Animal).pos - Vector2(0.5, 0.9), Vector2(1, 1))
		_:
			r = Rect2(Vector2(ResourceNodes.cell_of(world, d, gather.ref)), Vector2(1, 1))
	gather_mark.points = PackedVector2Array([r.position * T, Vector2(r.end.x, r.position.y) * T, r.end * T,
			Vector2(r.position.x, r.end.y) * T, r.position * T])
