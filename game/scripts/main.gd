extends Node2D
## Game scene: owns the World (simulation), draws it, runs the player's controls and actions.
## Everything the player does goes through the same World rules as the NPCs.

const T := 16
const SAVE_PATH := "user://save1.json"
const PREVIOUS_SUFFIX := ".previous.json"   # the last game, kept when the player starts a new one

var map: VillageMap
var world: World
var view: MapView
var ow_view: OverworldView     # the world outside the village (chunks round the camera)
var actors: Node2D
var above: Node2D
const MARKER_Z := 20                 # markers draw over roofs and canopies (their layers are z 10 in `above`)
var canopy: CanopyFade         # fades the tile canopies the player walks behind (the trees are TreeView's sprites)
var tree_view: TreeView        # every tree as a sprite, in `actors` so characters walk behind them
var roofs: RoofFade            # fades the roof of the building the player is in (or behind)
var blankets := {}             # bed tile -> its blanket (AtlasTexture), drawn over a sleeper
var camera: Camera2D
var ui: GameUI
var sprites := {}              # npc id -> ActorSprite
var animal_sprites := {}       # animal id -> AnimalSprite
var cart_sprites := {}         # cart id -> Sprite2D (B14: the mine cart stands in for the handcart)
var player_sprite: ActorSprite
var loot_nodes: Array = []
var projectiles: Array = []    # {node, pos, dir, left}
var target := {}               # current interaction target
var action := {}               # {label, left, total, done: Callable, anim, tool}
var furn := {}                 # PL2-013: the player on furniture: {kind: "sit" | "lie", spot, stand (tiles: the cell to get up to)}
var gain_log: Array = []       # [item id, text] of the recent gain lines (_gain)
var sprinting := false         # B8-027: running (LT toggles on a pad; Shift held, or toggled, on a keyboard)
var save_meta := {}            # PL1-11: the save's identity for portable and cloud saves (_save_meta)
var save_extra := {}           # sections of a loaded save this build does not know, written back unchanged (SAVE-08)
var talk_alt := {}             # a villager beside the resource the player faces: Y (pad), T (keys) or a tap talks to them while A works the resource
var target_options: Array = [] # B8-014: everything the player could use here, nearest first; target is one of them
var tab_cycled := -1           # the frame Tab chose another target (it is the Pack's key too, then it does not open it)
var sprint_latched := false    # touch Run (Build 13): sprint whenever walking until Run is pressed again or stamina runs out
var sprint_spent := false      # stamina ran out while Shift was held: release it to sprint again
var target_pref := ""          # the key (_target_key) of the option the player cycled to
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
var house_signs := {}                  # building id -> its family-name sign (Label), made when first near
var inside_hold := ""                  # the building the player was last inside (see _sync_sprites)              # the last save failed: say so once, not at every autosave
var shot_path := ""
var shot_frames := 0
var shot_warp := Vector2.INF
var shot_advance := 0.0
var shot_zoom := 0.0
var shot_panel := ""
var shot_field_state := ""
var shot_pick := 0.0
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
var swing := Combat.new()      # the sword swing: windup, blow, recovery and one buffered press (CQ-01)
var target_marker: Sprite2D    # the sword shown over the target
var settings := GameSettings.new()
var scheme := "kbm"            # the controls in use, from the last input: touch | gamepad | kbm
var blood_layer: Node2D        # blood where someone was slain, under the actors
var dying := {}                # npc id -> seconds left of the death flicker
var fading: Array = []         # [sprite, seconds left]: killed animals flickering out
var bubble_layer: CanvasLayer  # speech bubbles over villagers' heads, in screen space
var bubbles := {}              # npc id -> SpeechBubble (at most one each)
var stars := {}                # npc id -> the gold star over the employer the player has taken a job from and is owed pay by (PL1-09)
var diamonds := {}             # npc id -> the quest marker sprite over a quest giver
var placing := {}              # choosing where to build: {kind, at: the footprint's top-left cell}
var ghost: PlacementGhost      # the footprint shown while placing
var place_step := 0.0          # seconds until a held stick or key moves the footprint again
var level_views := {}          # MIN-A: LevelMap id -> LevelView (the levels below the surface)
var level_alpha := 0.0         # MIN-A: how far the level below is faded in (the surface is faded out by as much)
var level_shown := 0           # MIN-A: the level whose view is showing or fading (0: none)
var portal_goal := {}          # MIN-A: a tapped portal: the end whose stand the player walks to, to go through
var portal_said := -1          # MIN-A: the frame a refused crossing last said why (once a push, not every frame)
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
	# a controller connected to a phone (or already there at start) hides the touch buttons and uses the
	# pad's controls; unplugged, the phone goes back to touch (owner, 2026-10-19)
	Input.joy_connection_changed.connect(_on_joy_connection)
	if settings.phone and not _real_pads().is_empty():
		_on_joy_connection(_real_pads()[0], true)
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
			"--pick":
				shot_pick = float(args[i + 1])          # pick every wild plant within this many tiles of the warp point (screenshots)
			"--field-state":
				shot_field_state = args[i + 1]          # tilled | growing | ripe: every field in that state
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
		if shot_field_state != "":
			for f in world.fields:
				world.set_field(f, shot_field_state)
		if shot_warp != Vector2.INF:
			world.player.pos = shot_warp
			follow_at = _in_view(shot_warp * T)
			if shot_pick > 0.0:
				var r := int(ceil(shot_pick))
				for dy in range(-r, r + 1):
					for dx in range(-r, r + 1):
						world.pick_plant(world.plant_at(Vector2i(floori(shot_warp.x) + dx, floori(shot_warp.y) + dy)))
		if shot_zoom > 0.0:
			camera.zoom = Vector2(shot_zoom, shot_zoom) * view_scale
		camera.position_smoothing_enabled = false
		match shot_panel:
			"underground":
				# MIN-A: the player walks into the adit; the gallery shows and the surface is faded out
				world.player.pos = Vector2(world.underground.portals[0].ends[0].stand) + Vector2(0.5, 0.5)
				world.player_through(Vector2.UP)
				if shot_warp != Vector2.INF:
					world.player.pos = shot_warp
				_sync_levels(0.0)
				follow_at = _in_view(world.player.pos * T)
			"gain":
				ui.gain("+2 red berries", "red_berries")
				ui.gain("+1 Iron ore", "iron_ore")
				ui.gain("Tool worn")
				(func(): for tw in get_tree().get_processed_tweens(): tw.kill()).call_deferred()    # keep the lines up for the picture
			"apothecary":
				# PL1-04: the sage's shop (the normal trade window)
				var sage := world.npc(world.sage_id)
				ui.show_trade(sage)
			"farm_tilled", "farm_growing", "farm_pen":
				_farm_shot(shot_panel)                  # PL2-015: a cleared and tilled field, growing crops, a pen with animals
			"small_room", "small_room_inside":
				_room_shot(shot_panel == "small_room_inside")   # HOUSE-10: the small room built against b_v1_house
			"employer_star":
				# PL1-09: the smith who set the player a job wears the star, wherever the smith walks
				for n: NPC in world.npcs:
					if n.job == "smith" and n.alive:
						n.inv.remove("iron_ore", n.inv.count("iron_ore"))
						n.coins = 200
						world.quests.offers[n.id] = "ore_for_the_forge"
						world.quests.accept(n)
						world.player.pos = n.pos + Vector2(2, 2)
						follow_at = _in_view(world.player.pos * T)
						break
			"stove_window":
				ui.show_craft(world.stations_of("stove")[0])
			"hud_low", "prompt":
				# B8-013/019: a low-food, low-health HUD, with the contextual prompt and a hint toast
				world.player.hunger = 12.0
				world.player.hp = 9.0
				world.player.stamina = 20.0
				ui.update_hud()
				ui.prompt("Fell this tree")
				ui.message("Gather: tap a seam, a tree, a ripe field, a flower, a berry bush or game; you gather it until it runs out. Tap Gather again to stop.", 60.0)
			"choice":
				# a villager standing by a workstation: the prompt offers both
				for id in world.stations:
					if world.stations[id].type in ["forge", "anvil", "workbench", "sawhorse", "stove", "oven"]:
						var st: Dictionary = world.stations[id]
						world.player.pos = Vector2(int(st.use[0]) + 0.5, int(st.use[1]) + 0.5)
						player_sprite.face(Vector2(0, 1))
						follow_at = _in_view(world.player.pos * T)
						world.npcs[2].pos = world.player.pos + facing_vec() * 0.9
						world.npcs[2].anim = "idle"
						break
				_find_target()
			"mine_swing_0","mine_swing_1", "mine_swing_2", "chop_swing_0", "chop_swing_1", "chop_swing_2":
				# mid-swing, frozen at one frame of the swing, with the pickaxe or the axe in hand
				_swing_panel(shot_panel.begins_with("mine"), int(shot_panel.right(1)))
			"skills":
				ui.show_skills()
			"inventory", "inventory_pad", "inventory_tab":
				# a pack with something in most tabs, and the new gear worn
				var kit := {"log": 6, "plank": 12, "iron_ore": 3, "coal": 4, "wheat": 9, "pottage": 2, "leather": 2,
					"leather_cap": 1, "copper_ring": 1, "amulet": 1, "iron_bar": 2, "apple": 3}
				for id in kit:
					world.player.inv.add(id, kit[id])
				for id in ["rusty_sword", "rusty_pickaxe", "leather_cap", "copper_ring", "amulet"]:
					world.player_equip(id)
				if shot_panel != "inventory":
					ui.set_scheme("gamepad")
				ui.show_inventory()
				ui.inventory_window().choose("copper_ring")
				if shot_panel == "inventory_pad":
					ui.inventory_window().gear_buttons["weapon"].grab_focus()
				elif shot_panel == "inventory_tab":
					ui.inventory_window().tab_buttons[2].grab_focus()
			"title":
				ui.show_title(false)
			"creation":
				ui.show_creation({"name": "Ada", "family": "Thorne", "sex": "female"})
			"origin":
				ui.show_origin()
			"settings", "settings_display", "settings_interface", "settings_controls", "settings_wiki":
				ui.show_settings(ui.hide_all, shot_panel.trim_prefix("settings_") if shot_panel.begins_with("settings_") else "audio")
			"wiki_search", "wiki_item", "wiki_guide", "wiki_recipe":
				ui.show_settings(ui.hide_all, "wiki")
				match shot_panel:
					"wiki_search":
						ui.wiki_win.search_for("plank")
					"wiki_item":
						ui.wiki_win.goto("item:pickaxe")
					"wiki_guide":
						ui.wiki_win.goto("guide:heal")
					"wiki_recipe":
						ui.wiki_win.goto("recipe:forge_pickaxe")
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
			"credits":
				ui.show_credits()
			"trees":
				_trees_panel()
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
			"family_meal", "family_meal_before":
				# PL1-07: the manor's family at their chairs (the "before" picture: standing at the table cell)
				for n: NPC in world.npcs:
					if n.alive and n.home == "b_manor":
						var chair := world.home_spot(n, "chair")
						if shot_panel == "family_meal" and not chair.is_empty():
							n.pos = _cell_centre(chair.use)
							n.anim = "sit"
							n.plan = [world.brain.work(600, "", {}, "sit")]
							n.work_left = 600.0
						else:
							n.pos = Vector2(world.home_cell(n, "table")) + Vector2(0.5, 0.5)
							n.anim = "idle"
							n.plan = [world.brain.work(600, "", {}, "idle")]
							n.work_left = 600.0
			"player_sit", "player_bed":
				# PL2-013: the player in a house of their own, seated on a chair or lying in the bed
				player_sprite.setup("res://assets/characters/player_m3_basic.png")          # a made character (the stand-in has a plume and a shield)
				var hid := "b10"
				world.player.home = hid
				for sp in world.interiors[hid].spots:
					if shot_panel == "player_sit" and sp.kind == "chair":
						world.player.pos = _cell_centre(sp.use)
						sit_down(sp)
						break
					if shot_panel == "player_bed" and sp.kind == "bed":
						world.player.pos = _cell_centre(sp.use)
						rest()
						action.left = 600.0
						break
				follow_at = _in_view(world.player.pos * T)
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
			"trade_qty":
				# PL1-03: the quantity control, buying 3 of 8 affordable
				var tk := world.tavern_keeper()
				tk.inv.add("pottage", 12)
				world.player.coins = 17
				ui.show_trade(tk, {"id": "pottage", "mode": "buy", "price": 2})
				(ui.panel_body.get_node("QuantityPicker") as QuantityPicker).set_qty(3)
			"storage_focus":
				# PL2-012: a long chest list with focus on a row far down
				for id in GameData.items.keys().slice(0, 40):
					world.player.chest.add(id, 2)
				ui.show_home()
				(func():
					var btns: Array = ui.panel_body.find_children("*", "Button", true, false).filter(func(b): return b.text == "Take")
					(btns[22] as Button).grab_focus()).call_deferred()
			"talk_news":
				var tn: NPC = world.npcs[2]
				world.note("Walter Reed sold two logs to the carpenter")
				ui.show_talk(tn)
				ui._talk_view(tn, Dialogue.news(world, tn))
			"craft":
				ui.show_craft(world.stations_of("anvil")[0])
			"stall", "stall_pick":
				# the player's rented market stall (PL1-10), stocked, with a sale made
				world.player.coins = 60
				world.player.inv.add("plank", 8)
				world.player.inv.add("iron_ore", 5)
				world.player.inv.add("pickaxe", 1)
				world.player.inv.add("log", 4)
				world.business.rent()
				var st: Dictionary = world.business.mine()
				world.business.list_item(st, "plank", 6)
				world.business.list_item(st, "iron_ore", 5)
				world.business.list_item(st, "pickaxe", 1)
				world.business.set_price(st, "plank", 4)
				world.player.pos = world.business.use_cell(st) + Vector2(0, 1)
				var smith: NPC = world.npcs.filter(func(n): return n.job == "smith")[0]
				smith.coins = 200
				world.business.sell(st, smith, "iron_ore", 2, GameData.value("iron_ore"))
				ui.show_stall(str(st.id), {"id": "plank", "mode": "price"} if shot_panel == "stall_pick" else {})
			"bizshop", "bizshop_window", "bizfit", "bizplace", "bizlarge":
				_business_scene(shot_panel)
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
			"farm_place", "farm_place_bad", "farm_deal", "farm_fenced":
				_farm_plot_shot(shot_panel)             # FARM-09: marking out farmland, its price, the deal, the fence
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
							n.work_left = 600.0
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
			"property", "property_after", "property_in", "property_menu", "property_place":
				# PL2-008/014: a leased plot with a house, then a carpenter's shop added beside it
				var pc: Construction = world.construction
				var pl: Dictionary = world.plots[0]
				world.player.coins = 2000
				world.property.lease(pl, World.PLAYER)
				world.start_site(pl, "house", World.PLAYER)
				for id in pl.site.need.duplicate():
					world.player.inv.add(id, int(pl.site.need[id]))
				world.deliver(pl, world.player.inv, World.PLAYER)
				for t in world.trees:
					if Rect2i(int(pl.x) - 22, int(pl.y) - 22, 53, 53).has_point(Vector2i(int(t.x), int(t.y))) and t.state == "grown":
						world.fell(t, 0)
				var slot := pc.find_module_slot("carpentry", pl, World.PLAYER)
				if shot_panel == "property_place":
					begin_placement("carpentry", "plot0")
				elif shot_panel != "property":
					var mp := pc.place("carpentry", slot, World.PLAYER, false, pl)
					for id in mp.site.need.duplicate():
						world.player.inv.add(id, int(mp.site.need[id]))
					world.deliver(mp, world.player.inv, World.PLAYER)
				world.player.pos = Vector2(int(pl.x) + 4, int(pl.y) + 12) + Vector2(0.5, 0.5)
				if shot_panel == "property_in":
					world.player.pos = Vector2(world.station_use("ws_workshop_%s_workbench" % pl.id.replace("plot0", "parcel0"))) + Vector2(0.5, 0.5)
				follow_at = _in_view(Vector2(int(pl.x) - 4, int(pl.y) + 5) * T)
				if shot_panel == "property_menu":
					ui.show_build(pl)
				else:
					ui.toast_t = 0.01
					if shot_panel != "property_place":
						ui.log_box.visible = false
				shot_frames = -40
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
		"sprint": [KEY_SHIFT], "cancel": [], "next_target": [KEY_Q], "prev_target": [], "talk": [KEY_T],
	}
	var pads := {"interact": JOY_BUTTON_A, "attack": JOY_BUTTON_X, "fireball": JOY_BUTTON_Y,
		"inventory": JOY_BUTTON_BACK, "pause": JOY_BUTTON_START, "skills": JOY_BUTTON_RIGHT_SHOULDER,
		"map": JOY_BUTTON_LEFT_SHOULDER, "recenter": JOY_BUTTON_RIGHT_STICK, "gather": JOY_BUTTON_DPAD_DOWN,
		"next_target": JOY_BUTTON_DPAD_RIGHT, "prev_target": JOY_BUTTON_DPAD_LEFT,
		"journal": JOY_BUTTON_DPAD_UP, "build": JOY_BUTTON_LEFT_STICK,          # FR-04
		"cancel": JOY_BUTTON_B}
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
	save_meta = {}
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
	_show_plants()                            # SEED-03: berry bushes out of season are bare from the start
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
	for dated in SaveStore.dated_backups(save_path):          # an earlier day's save (DVW-A2), newest first
		var o := SaveStore.inspect(dated, World.SAVE_VERSION)
		if o.state == "ok":
			_load_save(o.data)
			ui.message((note + " " if note != "" else "") + "The save of %s was loaded instead." % str(dated).get_file().get_basename().get_slice(SaveStore.DATED, 1), 12.0)
			return
	new_game()
	ui.message((note if note != "" else "No save could be loaded.") + " A new game was started.", 12.0)


func _load_save(d: Dictionary) -> void:
	save_meta = d.get("meta", {}).duplicate()
	_clear_world()
	map = VillageMap.load_default()
	world = World.new()
	world.load_dict(map, d)
	save_extra = {}
	var known := world.to_dict()
	for k in d:
		if k != "meta" and not known.has(k):
			save_extra[k] = d[k]
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
	furn = {}
	if world:
		world.dispose()
	for sg in house_signs.values():
		if is_instance_valid(sg):
			sg.queue_free()
	house_signs.clear()
	swing.cancel()
	chase = null
	talk_to = null
	reach_to = Vector2.INF
	placing = {}
	diamonds.clear()                # their nodes go with the scene
	stars.clear()
	site_bars.clear()
	move_to = Vector2.INF
	walk_goal = Vector2i(-1, -1)
	strike_pending = false
	action = {}
	sprinting = false
	sprint_latched = false
	target_options = []
	target_pref = ""
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


const CHILD_SCALE := 0.5               # a child's sprite, of an adult's
const SIGN_RANGE := 14.0               # tiles: house signs show when the player is this near


## A small wooden sign by each house's door with the family's name (Build 8 request: "so you know
## who's who"), shown when the player is near; the name follows whoever lives there now.
func _sync_signs(at: Vector2) -> void:
	for id in world.buildings:
		var b: Dictionary = world.buildings[id]
		if not str(b.get("type", "")) in ["house", "player_house"]:
			continue
		var door := Vector2(float(b.door[0]) + 0.5, float(b.door[1]) + 0.5)
		var sign: Label = house_signs.get(id)
		var near := door.distance_to(at) < SIGN_RANGE
		var fam := world.home_family(str(id)) if near else ""
		if fam == "":
			if sign != null:
				sign.visible = false
			continue
		if sign == null:
			sign = Label.new()
			sign.add_theme_font_size_override("font_size", 7)
			sign.add_theme_color_override("font_color", Color(0.98, 0.93, 0.82))
			var st := StyleBoxFlat.new()
			st.bg_color = Color(0.43, 0.29, 0.17)
			st.border_color = Color(0.25, 0.16, 0.09)
			st.set_border_width_all(1)
			st.set_content_margin_all(1)
			sign.add_theme_stylebox_override("normal", st)
			sign.z_index = 30
			actors.add_child(sign)
			house_signs[id] = sign
		sign.text = fam
		sign.visible = true
		sign.position = door * T + Vector2(-sign.get_minimum_size().x / 2.0, 2.0)


func _build_scene() -> void:
	view = MapView.new()
	add_child(view)
	ow_view = OverworldView.new()                # under the characters, beside the village's own layers
	add_child(ow_view)
	blood_layer = Node2D.new()
	add_child(blood_layer)
	var clues := ClueView.new()                   # MIN-C: prospecting stains on the ground, under the characters
	blood_layer.add_child(clues)
	clues.setup(world.prospecting, T)
	actors = Node2D.new()
	actors.y_sort_enabled = true
	add_child(actors)
	tree_view = TreeView.new()
	actors.add_child(tree_view)
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
	view.build(map, above, actors)             # overlay tiles of solid cells are drawn among the characters (B8-025)
	_draw_village_exits()
	tree_view.setup(world)
	_replace_tree_tiles()
	ow_view.setup(view, map.overworld, int(GameData.b("overworld_chunk_radius")))
	ow_view.tree_sink = tree_view
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
	add_child(camera)                            # no limits: the world goes on past the village
	camera.make_current()
	follow_at = _in_view(world.player.pos * T)
	camera.position = follow_at
	ow_view.follow(world.player.pos, world.player.pos, 0.0, 6)      # the nearest chunks at once, the rest over the next frames
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
	_build_levels()


## The village map draws its trees as tiles; the game draws them as sprites (TreeView). Take the tree
## tiles out of the layers: every tree of the model (World.trees, the map's edge woodland included) from
## the tiles it was made from. Collision is the map's, set by each tree's stage.
func _replace_tree_tiles() -> void:
	var lays := []
	for lay in map.data.layers:
		var n := str(lay.name)
		if n.begins_with("below") or n.begins_with("above"):
			lays.append([n, lay.data])
	var blank := func(cell: Vector2i, value: int) -> void:
		if cell.y < 0 or value < 0:
			return
		for l in lays:
			if int(l[1][cell.y * map.w + cell.x]) == value:
				view.set_tile(view.layer(l[0]), cell, -1)
	for t in world.trees:
		if t.get("planted", false):
			continue
		var cell := Vector2i(int(t.x), int(t.y))
		blank.call(cell, int(t.trunk))
		blank.call(cell + Vector2i.UP, int(t.top))
		blank.call(cell, int(t.bottom))


## Screenshot panel "trees": a meadow outside the village's west exit with every species at every growth
## stage in rows (sapling, young, growing, mature, stump) and two mature trees with axe blows in them.
func _trees_panel() -> void:
	var o := map.overworld
	var out: Vector2i = map.exits()[3].out
	var species: Array = Trees.art().variants.keys()
	var stages := ["sapling", "young", "growing", "grown", "stump"]
	var origin := Vector2i(-1000, -1000)
	for dx in range(-200, -8, 3):
		for dy in range(-60, 60, 3):
			var c := out + Vector2i(dx, dy)
			var ok := true
			for i in 5:
				for j in 5:
					if ok and o.plant_refusal(c + Vector2i(j * 5, i * 8)) != "":
						ok = false
			if ok and origin.x < -999:
				origin = c
	if origin.x < -999:
		origin = out + Vector2i(-40, 0)
	world.player.pos = Vector2(origin + Vector2i(14, 18)) + Vector2(0.5, 0.5)
	follow_at = _in_view(world.player.pos * T)
	ow_view.follow(world.player.pos, world.player.pos, 0.0, -1)
	var backdrop := ColorRect.new()                          # a plain meadow under the rows
	backdrop.color = Color(0.53, 0.67, 0.3)
	backdrop.position = Vector2(origin - Vector2i(4, 4)) * T
	backdrop.size = Vector2(40, 52) * T
	add_child(backdrop)
	move_child(backdrop, actors.get_index())
	for cy in range(origin.y - 3, origin.y + 44):              # the meadow: the generated trees there are cleared
		for cx in range(origin.x - 3, origin.x + 34):
			var base := o.base_tree(Vector2i(cx, cy))
			if not base.is_empty():
				base.state = "cleared"
				o.changes[Vector2i(cx, cy)] = base
				tree_view.refresh(base)
	var now := world.minutes
	for i in species.size():
		for j in stages.size():
			var cell := origin + Vector2i(j * 5, i * 8)
			var t := o.plant(cell, str(species[i]), now)
			t.state = stages[j]
			t.born = now - 10.0 - {"sapling": 0.0, "young": Trees.stage_minutes("sapling"), "growing": Trees.stage_minutes("sapling") + Trees.stage_minutes("young")}.get(stages[j], 0.0)
			if stages[j] == "stump":
				t.regrow = world.day() + 3.0
			tree_view.refresh(t)
	var hurt := o.plant(origin + Vector2i(27, 0), "oak_summer", now)
	hurt.state = "grown"
	tree_view.refresh(hurt)
	world.chop_tree(hurt, -1, 0)
	world.chop_tree(hurt, -1, 0)
	var hurt2 := o.plant(origin + Vector2i(27, 8), "pine_summer", now)
	hurt2.state = "grown"
	tree_view.refresh(hurt2)
	for k in 3:
		world.chop_tree(hurt2, 1, 0)
	ui.toast_t = 0.01


## The wild plants as the world has them: picked, bare out of season, young or grubbed up are not drawn; a ripe
## plant grown from a cutting or seed (SEED-02) is drawn, as it is not map data.
func _show_plants() -> void:
	for pl in world.plants:
		if pl.state != "ripe":
			_on_tile_changed(Vector2i(pl.x, pl.y), World.PLANT_LAYER, -1)
		elif pl.get("planted", false):
			_on_tile_changed(Vector2i(pl.x, pl.y), World.PLANT_LAYER, int(pl.tile))


func _apply_world_changes() -> void:
	for d in world.deposits:
		if int(d.amount) <= 0 and World.level_of(d) == 0:       # a level's seams are drawn by its LevelView (MIN-A)
			_on_tile_changed(Vector2i(d.x, d.y), "below", map.data.tiles.depleted_rock)
	world.sync_boulders()                    # boulders already broken up (B8-026)
	for b in world.boulders:                 # the small ones are drawn small (PL1-06)
		var bc := Vector2i(int(b.x), int(b.y))
		if int(b.amount) > 0 and ResourceNodes.boulder_small(bc):
			var rock := int(map.data.tiles.ore.stone)
			for lay in map.data.layers:
				if str(lay.name).begins_with("below") and int(lay.data[bc.y * map.w + bc.x]) == rock:
					view.set_tile(view.layer(str(lay.name)), bc, MapView.SMALL_BOULDER_TILE)
	for f in world.fields:
		world._field_tiles(f)
	world.farm.show_all()                     # the player's field and pens (PL2-015)
	world.farm_plots.show_all()               # family farmland: fences and the households' fields (FARM-02/03)
	_show_plants()
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
	if not map.in_village(cell):
		ow_view.apply_change(cell, kind, value)          # a tree felled or regrown outside the village
		return
	var layer := view.layer(layer_name)
	if layer:
		if layer_name.begins_with("above"):
			canopy.restore_all()          # a faded canopy's tiles go back first, so the change sticks
			roofs.restore_all()
		view.set_tile(layer, cell, value)


## Where the village's roads leave it, the dirt path continues over the grass to the map edge, where
## the overworld's road takes it up (VillageMap.exits). Only drawn: the grass is walkable already.
## The road cell's own tile is chosen again with the trail as a neighbour, so the two join.
func _draw_village_exits() -> void:
	var path := view.layer("path0")
	var dirt: Array = map.overworld.tiles.dirt_path
	var road := {}
	for c in map.data.road:
		road[Vector2i(int(c[0]), int(c[1]))] = true
	for e in map.exits():
		var trail: Array = e.trail
		for i in trail.size():
			var c: Vector2i = trail[i]
			var bits := 0
			if i == 0:
				if view.tile_value(path, c) < 0:
					continue                # the village's art there is not a path tile: leave it
				for k in 4:
					if road.has(c + (VillageMap.SIDES[k] as Vector2i)):
						bits |= 1 << k      # the road's own neighbours (the trail runs on over grass)
			elif view.tile_value(path, c) >= 0:
				continue                    # something drawn there already: keep it
			for k in 4:
				var step: Vector2i = VillageMap.SIDES[k]
				if (i > 0 and trail[i - 1] == c + step) or (i < trail.size() - 1 and trail[i + 1] == c + step) \
						or (i == trail.size() - 1 and e.out == c + step):
					bits |= 1 << k
			var opts: Array = dirt[bits if bits != 0 else 10]
			view.set_tile(path, c, opts[(c.x * 7 + c.y * 13) % opts.size()])


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
	var fit_layer := view.layer(Fitting.LAYER)       # the equipment the player placed in the room (PL1-10 stage 3)
	if fit_layer != null:
		for e in world.fitting.list(b):
			view.set_tile(fit_layer, world.fitting.cell_of(e), int(Fitting.ART[str(e.kind)]))


# ---------------------------------------------------------------- frame ----------------------
func _process(delta: float) -> void:
	if world == null:
		return
	if shot_path != "":
		_screenshot_step(delta)
	if not placing.is_empty():
		_placing_step(delta)
	if not action.is_empty() and (ui.modal() or not world.player.alive):
		cancel_action("")          # a window opened (the Pack, a menu) or the player fell: the work stops, nothing is awarded
	if not paused and world.player.alive:
		world.update(delta)
		save_meta["play_seconds"] = float(save_meta.get("play_seconds", 0.0)) + delta
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
	_sync_levels(delta)
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


## Draw a villager eating at home seated on their own chair (PL1-07; World.home_spot kind "chair"): they
## walked to the chair's use cell and the anim is "sit". Anyone not on it stands as before.
func _show_sitter(n: NPC, s: ActorSprite) -> bool:
	if n.anim != "sit":
		return false
	var chair := world.home_spot(n, "chair")
	if chair.is_empty() or n.cell() != Vector2i(int(chair.use[0]), int(chair.use[1])):
		return false
	s.sit(_cell_centre(chair.at) * T, Furniture.face_dir(chair))
	return true


func _sync_sprites() -> void:
	var cam := camera.get_screen_center_position() / T
	for id in sprites.keys():                      # a child who became the player (Life.make_heir) leaves the people
		if not world.by_id.has(id):
			sprites[id].queue_free()
			sprites.erase(id)
	for n: NPC in world.npcs:
		var s: ActorSprite = sprites.get(n.id)
		if s == null:                               # a newcomer (NPCBrain succession) gets a sprite when first seen
			s = ActorSprite.new()
			s.setup(n.sprite)
			actors.add_child(s)
			sprites[n.id] = s
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
		# children are drawn at half an adult's size, full size once grown (owner, 2026-10-18); the
		# feet are the sprite's origin, so they stay on the ground
		s.scale = Vector2.ONE * Life.npc_scale(n, world.minutes)       # child 0.5, adolescent 0.75 (balance.json "life"; B8-029)
		s.visible = near and not _covered(n) and not world.in_loft(n)     # asleep in the loft: up there, unseen
		if not s.visible:
			continue
		if _show_sleeper(n, s) or _show_sitter(n, s):
			continue
		s.stand()
		s.position = n.pos * T
		s.face(n.facing)
		var look: Array = world.brain.work_look(n) if n.anim == "work" else [n.anim, ""]
		if s.tool_item != look[1]:
			s.hold(look[1])
		s.play(look[0] if look[0] != "sleep" else "idle")
	var p := world.player
	player_sprite.position = p.pos * T
	_sync_player_pose()
	_sync_signs(p.pos)
	canopy.update(p.pos, get_process_delta_time())
	tree_view.update(p.pos, get_process_delta_time())
	ow_view.follow(camera.get_screen_center_position() / T, p.pos, get_process_delta_time())
	var rf := RoofFade.probe(world, p.pos, inside_hold)         # which roof lifts (B8-018: roofs never return indoors)
	inside_hold = rf.inside
	roofs.follow(rf.inside, rf.inside_roof, rf.under, rf.under_roof, get_process_delta_time())
	if not p.alive:
		if player_sprite.anim != "death":
			player_sprite.play("death", true)
	camera.position = cam_at if cam_free else _follow(p.pos * T)
	target_marker.visible = chase != null and chase.alive
	if target_marker.visible:
		var bob := sin(Time.get_ticks_msec() / 150.0) * 1.5
		target_marker.position = chase.pos * T + Vector2(0, -42 + bob)
	_sync_animals()
	_sync_carts()
	_sync_loot()
	_sync_bubbles()
	_sync_diamonds()
	_sync_stars()
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


## PL1-09: a bright gold star over each employer the player has taken a job from and not yet been
## paid by (World.quests.employer). It follows them, hangs over the door when they are indoors under a
## roof, and goes only when the job is completed and paid.
func _sync_stars() -> void:
	var cam := camera.get_screen_center_position() / T
	var bob := sin(Time.get_ticks_msec() / 260.0) * 1.5
	var shown := {}
	for n: NPC in world.npcs:
		if not world.quests.employer(n):
			continue
		var covered := _covered(n)
		var inside := world.place_of(n.pos)
		var at := Vector2(world.building_door(inside)) if covered else n.pos
		if at.distance_to(cam) > 30.0:
			continue
		shown[n.id] = true
		var s: Sprite2D = stars.get(n.id)
		if s == null:
			s = Sprite2D.new()
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.z_index = MARKER_Z + 1
			s.texture = load("res://assets/markers/star.png")
			s.name = "EmployerStar"
			above.add_child(s)
			stars[n.id] = s
		var raised: float = 16.0 if world.quests.marker(n) != "" else 0.0
		if covered:
			s.position = (Vector2(world.building_door(inside)) + Vector2(0.5, 0.0)) * T + Vector2(0, -26 + bob - raised)
		else:
			s.position = n.pos * T + Vector2(0, -48 + bob - raised)
	for id in stars.keys():
		if not shown.has(id):
			stars[id].queue_free()
			stars.erase(id)


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


## B14: each cart drawn with the mine cart tile (a stand-in until the owner's own art).
func _sync_carts() -> void:
	var seen := {}
	for c in world.carts.carts:
		seen[int(c.id)] = true
		var s: Sprite2D = cart_sprites.get(int(c.id))
		if s == null:
			s = Sprite2D.new()
			s.texture = _tile_texture(CART_TILE)
			s.offset = Vector2(0, -T / 2.0 + 2.0)
			actors.add_child(s)
			cart_sprites[int(c.id)] = s
		s.position = (c.pos as Vector2) * T
		s.flip_h = (c.facing as Vector2).x < 0.0
	for id in cart_sprites.keys():
		if not seen.has(id):
			cart_sprites[id].queue_free()
			cart_sprites.erase(id)


const CART_TILE := 3009          # the mine cart on its rail (tools/build_village.py MINE_CART, atlas 0)


## One tile of the map's atlases as a texture (tile = atlas * 100000 + index).
func _tile_texture(tile: int) -> Texture2D:
	var a := tile / 100000
	var t := tile % 100000
	var tex := AtlasTexture.new()
	tex.atlas = view.sources[a].texture
	tex.region = Rect2(Vector2(t % view.columns[a], t / view.columns[a]) * T, Vector2(T, T))
	return tex


func _sync_animals() -> void:
	var cam := camera.get_screen_center_position() / T
	var seen := {}
	for a: Animal in world.fauna.animals:
		seen[a.id] = true
		var s: AnimalSprite = animal_sprites.get(a.id)
		if s == null:
			s = AnimalSprite.new()
			s.setup(a, world.minutes)
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


## What a pile holds, for its prompt: "4 meat, 1 hide" ("" when it holds only coins or nothing).
func _loot_text(l: Dictionary) -> String:
	var parts := []
	for id in l.inv.ids():
		parts.append("%d %s" % [l.inv.count(id), GameData.item_name(id).to_lower()])
	return ", ".join(parts)


## The icon a pile is drawn with: its first item (meat from a carcass), coins if it holds only coins.
func _loot_icon(l: Dictionary) -> Texture2D:
	var ids: Array = l.inv.ids()
	var path := "res://assets/icons/%s.png" % (str(ids[0]) if not ids.is_empty() else "coins")
	return load(path) if ResourceLoader.exists(path) else load("res://assets/icons/coins.png")


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
		var rect := loot_nodes[i].get_child(0) as TextureRect
		var icon := _loot_icon(world.loot[i])
		if rect.texture != icon:
			rect.texture = icon


# ---------------------------------------------------------------- player ---------------------
func _player_step(delta: float) -> void:
	var p := world.player
	_swing_step(delta)
	if not action.is_empty():
		_menu_keys()                      # the Pack and the other windows open mid-action: that stops it (B8-010)
		if ui.modal():
			cancel_action("")
			return
		if Input.is_action_just_pressed("cancel"):
			cancel_action("You stop.")   # B (and Esc, right-click, a tap) stop the work at once (B8-011)
			return
		sprinting = false
		action.left -= delta
		if action.left <= 0.0:
			var done: Callable = action.done
			world.release_player_station(str(action.get("station", "")))
			action = {}
			done.call()                  # may begin the next blow of a felling
			if action.is_empty():
				_rest_anim()             # one cycle: collected, then back to idle (B8-006)
		return
	if ui.modal():
		player_sprite.play("idle")
		return
	if furn.get("kind", "") == "sit":
		_seated_step()                    # PL2-013: any input stands the player up
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
		var speed := float(GameData.b("player_tiles_per_second")) * _sprint_step(delta) \
				* (Carts.pull_speed() if not world.carts.pulled_by(World.PLAYER).is_empty() else 1.0)     # B14: a cart is slower going
		var step := v.normalized() * minf(v.length(), 1.0) * speed * delta
		var before := p.pos
		var moved_x := _try_move(Vector2(step.x, 0))
		var moved_y := _try_move(Vector2(0, step.y))
		if not moved_y and absf(v.y) > absf(v.x):
			_slide_to_gap(Vector2(0, step.y))
		elif not moved_x and absf(v.x) > absf(v.y):
			_slide_to_gap(Vector2(step.x, 0))
		walk_stuck = walk_stuck + delta if p.pos.distance_to(before) < step.length() * 0.3 else 0.0
		_through_portal(v)
		player_sprite.face(v)
		player_sprite.play("walk")
		player_sprite.speed_scale = _sprint_scale()
	else:
		sprinting = false
		if player_sprite.anim in ["walk", "swing", "gather", "work"]:
			_rest_anim()
		_through_portal(Vector2.ZERO)        # MIN-A: a tapped adit, reached
	_find_target()
	if Input.is_action_just_pressed("interact"):
		interact()
	if Input.is_action_just_pressed("attack"):
		attack()
	if not talk_alt.is_empty() and (Input.is_action_just_pressed("talk") or (Input.is_action_just_pressed("fireball") and scheme == "gamepad")):
		talk_to_alt()                     # Y on a pad talks instead of casting while a villager is offered
	elif Input.is_action_just_pressed("fireball"):
		fireball()
	_menu_keys()
	if Input.is_action_just_pressed("gather"):
		gather_button()


## The window keys (Pack, Skills, Journal, Build): they work while walking and while working.
func _menu_keys() -> void:
	if Input.is_action_just_pressed("inventory") and tab_cycled != Engine.get_process_frames():
		ui.toggle_inventory()
	if Input.is_action_just_pressed("skills"):
		ui.toggle_skills()
	if Input.is_action_just_pressed("journal"):
		ui.show_journal(-1)
	if Input.is_action_just_pressed("build"):
		ui.show_build_menu()


## Back to standing: the swing or gathering animation ends and the held tool is put away.
func _rest_anim() -> void:
	player_sprite.hold("")
	player_sprite.speed_scale = 1.0
	player_sprite.play("idle")


## Stop the work now (B, Esc, a tap, a window opening): the action's result is dropped, so nothing is
## awarded, the swing ends, Gather mode's walk to the resource is given up and movement is the player's again.
func cancel_action(why := "") -> void:
	var had := not action.is_empty() or not gather.is_empty()
	if furn.get("kind", "") == "lie":
		stand_up()                         # woken: up beside the bed, the rest cut short
	if not action.is_empty():
		world.release_player_station(str(action.get("station", "")))
	action = {}
	stop_gather("")
	chase = null
	strike_pending = false
	move_to = Vector2.INF
	_rest_anim()
	if had and why != "":
		ui.message(why)


## Sprint (B8-027): on a pad LT toggles it (toggle_sprint), on a keyboard Shift held sprints, or toggles
## when the balance's sprint_toggle is on. It needs stamina and ends when that is gone; the speed
## multiplier is returned and the cost taken (net of the regeneration the world just added).
func _sprint_step(delta: float) -> float:
	var p := world.player
	if sprint_latched and not sprinting and p.stamina >= float(GameData.b("sprint_min_stamina")):
		sprinting = true
	if not bool(GameData.b("sprint_toggle")):
		if Input.is_action_pressed("sprint"):
			if not sprinting and not sprint_spent and p.stamina >= float(GameData.b("sprint_min_stamina")):
				sprinting = true
		else:
			sprint_spent = false
			if Input.is_action_just_released("sprint"):
				sprinting = false
	if not sprinting:
		return 1.0
	p.stamina = maxf(0.0, p.stamina - (float(GameData.b("sprint_stamina_per_sec")) + float(GameData.b("player_stamina_regen_per_second"))) * delta)
	if p.stamina <= 0.0:
		sprinting = false            # out of breath: back to walking until Shift is let go and pressed again
		sprint_spent = true
		if sprint_latched:
			sprint_latched = false
			ui.set_sprint_mode(false)
		return 1.0
	return float(GameData.b("sprint_speed"))


## Sprint on or off (LT; Shift when sprint_toggle is on). It cannot start without some stamina.
func toggle_sprint() -> void:
	if sprinting:
		sprinting = false
	elif world.player.stamina >= float(GameData.b("sprint_min_stamina")) and action.is_empty():
		sprinting = true


## The touch Run button (Build 13): latches sprint on, so pressing it while standing and then tapping a
## destination runs there; the same speed and stamina cost as LT and Shift. Pressed again, or out of
## stamina, it is off. It cannot latch without sprint_min_stamina.
func toggle_run_latch() -> void:
	if sprint_latched:
		sprint_latched = false
		sprinting = false
	elif world.player.stamina >= float(GameData.b("sprint_min_stamina")):
		sprint_latched = true
	ui.set_sprint_mode(sprint_latched)


func _sprint_scale() -> float:
	return float(GameData.b("sprint_speed")) if sprinting else 1.0


## The direction to walk this frame towards move_to, around walls and trees: the route comes
## from the map's pathfinder and is found again when the goal moves to another cell or the player
## gets stuck. Arriving (or finding no way) clears move_to.
func _route_step(_delta: float) -> Vector2:
	var p := world.player
	var goal := Vector2i(floori(move_to.x), floori(move_to.y))
	if goal != walk_goal or walk_stuck > 0.5:
		walk_goal = goal
		walk_stuck = 0.0
		var here := Vector2i(floori(p.pos.x), floori(p.pos.y))
		walk_path = world.path_for_player(here, goal)            # the level the player is on (MIN-A)
		if walk_path.is_empty() and world.player_level == 0 and not (map.in_village(here) and map.in_village(goal)):
			walk_path = PackedVector2Array([Vector2(here), Vector2(goal)])      # too far or no way found: straight there, sliding along what is in the way
		walk_i = 1                       # the first point is the cell the player stands in
		if walk_path.is_empty():
			move_to = Vector2.INF
			walk_goal = Vector2i(-1, -1)
			return Vector2.ZERO
	# the last stretch goes to the exact point; before it, to the centre of each cell on the way
	var target := move_to if walk_i >= walk_path.size() - 1 else walk_path[walk_i] + Vector2(0.5, 0.5)
	if world.solid_for_player(goal) and walk_i >= walk_path.size() - 1:
		target = walk_path[walk_path.size() - 1] + Vector2(0.5, 0.5)
	var d := target - p.pos
	# a waypoint is reached within 0.15 tiles, or within most of a frame's step: a long frame (a slow
	# phone, a test's 0.1 s step) would otherwise overshoot it to and fro for ever
	if d.length() < maxf(0.15, float(GameData.b("player_tiles_per_second")) * _sprint_scale() * _delta * 0.6):
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
	if not talk_to.alive or _covered(talk_to) or talk_to.pos.distance_to(world.player.pos) > 25.0 or talk_to.depth != world.player_level:     # MIN-A: not through rock
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
		if world.solid_for_player(Vector2i(floori(q.x), floori(q.y))):     # the level the player is on (MIN-A)
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


## Everything the player could use from here goes in `target_options` (B8-014): the people, containers,
## counters, loot and animals nearest the probe first, then the seam, tree, plant or field in front, then
## the station, plot, pen, door, bed or manor step at their feet. `target` is the one the player chose
## with cycle_target (else the first), and the prompt names it, and the next, when there are several.
func _find_target() -> void:
	if world.player_level != 0:
		_find_target_below()               # MIN-A: below the surface only what is on the player's level
		return
	var p := world.player
	var probe := p.pos + facing_vec() * 0.9
	var near: Array = []        # [distance to the probe, order, target]
	for n: NPC in world.present(p.pos, 2.5):
		var d := n.pos.distance_to(probe)
		if d < 1.5 and world.reaches(p.pos, n.pos):
			if world.asleep(n):
				near.append([d, near.size(), {"kind": "npc", "npc": n, "label": "%s is asleep" % _who(n)}])
			elif world.at_post(n):
				near.append([d, near.size(), {"kind": "shop", "npc": n, "label": "Trade with %s (%s)" % [n.name, world.shop_name(n)]}])
			else:
				near.append([d, near.size(), {"kind": "npc", "npc": n, "label": "Talk to %s" % _who(n)}])
	for c in world.containers:
		var at := Vector2(int(c.x) + 0.5, int(c.y) + 0.5)
		if at.distance_to(p.pos) > 2.2:
			continue
		var d := at.distance_to(probe)
		if d < 1.5 and world.reaches(p.pos, at):
			near.append([d, near.size(), _container_target(c)])
	for post in _shop_posts():
		for at: Vector2 in post.cells:
			if at.distance_to(p.pos) > 2.2:
				continue
			var d := at.distance_to(probe)
			if d < 1.5 and world.reaches(p.pos, at):
				near.append([d, near.size(), _shop_target(post)])
	for i in world.loot.size():
		if World.level_of(world.loot[i]) != 0:
			continue                       # left below the surface (MIN-A)
		var d: float = world.loot[i].pos.distance_to(probe)
		if (d < 1.5 or world.loot[i].pos.distance_to(p.pos) < 1.2) and world.reaches(p.pos, world.loot[i].pos):       # underfoot counts too (PL2-004)
			var from: String = world.loot[i].from
			var what := _loot_text(world.loot[i])
			near.append([minf(d, 1.4), near.size(), {"kind": "loot", "i": i, "label": ("Take %s from %s" % [what, from]) if from.begins_with("the ") and what != "" else ("Take what is left of %s" % from) if from.begins_with("the ") else ("Search %s's belongings" % from)}])
	for a: Animal in world.fauna.near(probe, 1.2):
		var d := a.pos.distance_to(probe)
		if d < 1.5 and world.reaches(p.pos, a.pos):
			var what := "%s (%s%s)" % [a.label().to_lower(), "young, " if not a.adult(world.minutes) else "", "male" if a.sex == "m" else "female"]
			var mine: bool = not a.wild() and world.fauna.pens.has(a.area) and world.fauna.pens[a.area].get("player", false)
			near.append([d, near.size(), {"kind": "animal", "animal": a, "label": ("A " if a.wild() else ("Your " if mine else "The keeper's ")) + what + (": attack to hunt it" if a.wild() else "")}])
	near.sort_custom(func(x, y): return x[0] < y[0] or (x[0] == y[0] and x[1] < y[1]))
	var cands: Array = near.map(func(x): return x[2])
	var c := Vector2i(floori(probe.x), floori(probe.y))
	var front := {}
	var farm_more: Array = []          # PL2-015: the other farm choices at the cell (more seeds), and the till choice
	var farm_low: Array = []
	for dc in [Vector2i.ZERO, Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1)]:
		var cell: Vector2i = c + dc
		if not world.reaches(p.pos, Vector2(cell) + Vector2(0.5, 0.5)):
			continue                       # across a wall or the inside/outside boundary (PL2-011)
		for ft in world.farm.targets_at(cell, p, dc == Vector2i.ZERO):
			if ft.get("low", false):
				farm_low.append(ft)
			elif front.is_empty():
				front = ft
			else:
				farm_more.append(ft)
		if not front.is_empty():
			break
		var dep := world.deposit_at(cell)
		if not dep.is_empty() and int(dep.amount) > 0:
			front = {"kind": "deposit", "dep": dep, "label": ("Mine %s (%d left)" % [GameData.item_name(dep.ore).to_lower(), int(dep.amount)]) if p.tool_of("pickaxe") != ""
					else ("A boulder" if dep.get("boulder", false) else "%s seam" % GameData.item_name(dep.ore)) + ": requires a pickaxe (the smith sells them)"}
			break
		var tr := world.tree_at(cell)
		if not tr.is_empty() and Trees.fruit_ripe(tr, world.day(), world.season()):     # B14: pick the fruit first; fell it after
			var fit: String = str(Trees.fruit_cfg(str(tr.species)).item)
			front = {"kind": "fruit", "tree": tr, "label": "Pick %s" % GameData.item_name(fit).to_lower() + ("s" if not GameData.item_name(fit).ends_with("s") else "")}
			break
		if not tr.is_empty() and tr.state != "cleared":
			var lab: String
			if tr.state == "grown":
				lab = "Fell this tree" if p.tool_of("axe") != "" else "A tree: requires an axe (the smith sells them)"
			else:
				lab = "%s: %s" % [Trees.describe(str(tr.state)), Trees.hint(str(tr.state))]
			front = {"kind": "tree", "tree": tr, "label": lab}
			break
		var pl := world.plant_at(cell)
		if not pl.is_empty() and pl.state == "ripe":
			var pdef := ResourceNodes.def_for("plant", str(pl.kind))
			front = {"kind": "plant", "plant": pl, "label": "Pick " + ", ".join(ResourceNodes.products(pdef).keys().map(func(k): return GameData.item_name(k).to_lower()))}
			break
		for f in world.fields:
			if f.state == "ripe" and Rect2i(int(f.x), int(f.y), int(f.w), int(f.h)).has_point(cell):
				var whose := ""
				for fo: NPC in world.field_workers(f):
					whose = "%s %s's" % [fo.name, fo.family]
					break
				front = {"kind": "field", "field": f, "label": "Harvest wheat (%d left)%s" % [int(f.get("crop", 0)), ("  —  " + whose + " field: taking it is theft") if whose != "" else ""]}
				break
		if not front.is_empty():
			break
	if not front.is_empty():
		cands.append(front)
		cands.append_array(farm_more)
	# at the player's feet (the last of these was the only one offered before B8-014: it comes first)
	var here: Array = []
	here.append_array(_fit_targets(world.place_of(p.pos)))
	here.append_array(_prospect_targets(cands))           # MIN-C: a clue's ground underfoot, a smith who can assay
	# B14 carts: the one you pull can be let go anywhere; a cart beside you can be pulled (yours) or opened
	var pulling: Dictionary = world.carts.pulled_by(World.PLAYER)
	if not pulling.is_empty():
		here.append({"kind": "cart_park", "id": int(pulling.id), "label": "Let go of your cart"})
		if (pulling.pos as Vector2).distance_to(p.pos) < 1.6:
			here.append({"kind": "chest", "id": "cart:%d" % int(pulling.id), "label": "Open your cart: store things"})
	else:
		var cart: Dictionary = world.carts.near(p.pos, 1.3)
		if not cart.is_empty():
			if world.carts.may_use(cart, World.PLAYER):
				here.append({"kind": "cart_pull", "id": int(cart.id), "label": "Pull your cart (%s)" % world.carts.condition(cart)})     # DVW-B4: its wear
			here.append(_chest_target(world.chests.unit("cart:%d" % int(cart.id))))
	for id in world.stations:
		var st: Dictionary = world.stations[id]
		var u := Vector2(int(st.use[0]) + 0.5, int(st.use[1]) + 0.5)
		if u.distance_to(p.pos) < 1.2 and st.type in ["forge", "anvil", "workbench", "sawhorse", "stove", "oven"]:
			var no := world.station_refusal(id)
			here.append({"kind": "station", "id": id, "label": ("Use Stove" if st.type == "stove" else "Use the %s" % st.type) if no == "" else "The %s: %s" % [st.type, no]})
	for pl in world.plots:
		var r := Rect2(Vector2(pl.x, pl.y), Vector2(pl.w, pl.h + 1))
		if r.has_point(p.pos) and cands.is_empty() and here.is_empty() and world.place_of(p.pos) == "":
			var lab := "%s, for sale (%d coins, or %d a week)" % [World.cap(world.property.describe(pl)), world.property.price_of(pl), world.property.rent_of(pl)]
			if world.holds(World.PLAYER, pl):
				var site: Dictionary = pl.site
				lab = "Your ground: build here" if site.is_empty() else ("Your building site: %s, %d%% done" % [Construction.kind_name(str(site.get("kind", "house"))), roundi(world.site_progress(pl) * 100.0)] if not site.get("done", false) else World.cap(world.property.describe(pl)))
			elif not world.property.for_sale(pl):
				lab = World.cap(world.property.describe(pl))
			here.append({"kind": "plot", "plot": pl, "label": lab})
	for id in world.fauna.pens:
		var pen: Dictionary = world.fauna.pens[id]
		var fa := Vector2(int(pen.feed_at[0]) + 0.5, int(pen.feed_at[1]) + 0.5)
		if fa.distance_to(p.pos) < 1.3:
			here.append({"kind": "pen", "pen": pen, "label": "%s pen: %d hungry, trough %d wheat (they eat about %d a day). Feed them" % [GameData.b("animals")[pen.kind].name, world.fauna.hungry(pen), int(pen.trough), world.fauna.daily_need(pen)]})
			if pen.get("player", false):                          # PL2-015: eggs, milk and wool wait in your own pen
				var waiting: Dictionary = world.farm.products_in(pen)
				if not waiting.is_empty():
					here.append({"kind": "pen_collect", "pen": pen, "label": "Collect " + ", ".join(waiting.keys().map(func(k): return "%d %s" % [int(waiting[k]), GameData.item_name(k).to_lower()]))})
			elif not world.farm.pen_with_room(str(pen.kind)).is_empty():       # ... and the keeper sells stock to a pen of yours
				for sx in ["f", "m"]:
					var spare := world.farm.spare_animal(pen, sx)
					var lab := "The keeper has no %s %s to spare" % ["female" if sx == "f" else "male", str(GameData.b("animals")[pen.kind].one).to_lower()]
					if spare != null:
						lab = "Buy a %s%s %s from the keeper (%d coins)" % ["young " if not spare.adult(world.minutes) else "", "female" if sx == "f" else "male", spare.label().to_lower(), world.farm.animal_price(spare)]
					here.append({"kind": "pen_buy", "pen": pen, "sex": sx, "id": "buy_" + sx, "label": lab})
	# a house the family holds but does not live in, or one the manor offers: its door
	for id in world.buildings:
		var b: Dictionary = world.buildings[id]
		if str(id) == p.home or not world.property.is_home(b) or (Vector2(world.building_door(id)) + Vector2(0.5, 0.5)).distance_to(p.pos) >= 1.3:
			continue
		var mine := world.holds(World.PLAYER, b)
		if mine or world.property.for_sale(b):
			here.append({"kind": "property", "thing": b, "label": ("%s, yours: make it your home" % World.cap(world.property.describe(b))) if mine
					else ("%s, empty, the manor's: buy (%d) or lease (%d a week)" % [World.cap(world.property.describe(b)), world.property.price_of(b), world.property.rent_of(b)])})
	# B14: a house the player holds: build a storefront by its door, or manage / reopen the one it has
	# (offered after the door's own choices: the house's own use stays the default)
	var fronts: Array = []
	for id in world.buildings:
		var b: Dictionary = world.buildings[id]
		if not world.holds(World.PLAYER, b) or not str(b.get("type", "")) in ["house", "player_house"]:
			continue
		if b.has("front"):
			var f: Dictionary = b.front
			var near_front := false
			for at in [Vector2(int(f.x) + 0.5, int(f.y) + 0.5), Vector2(int(f.x) + 1.5, int(f.y) + 0.5), Vector2(int(f.use[0]) + 0.5, int(f.use[1]) + 0.5)]:
				if at.distance_to(p.pos) < 1.3:
					near_front = true
			if near_front:
				fronts.append({"kind": "stall", "id": str(id), "label": "Manage your storefront"} if b.has("shop")
						else {"kind": "front_open", "id": str(id), "label": "Open your storefront"})
		elif (Vector2(world.building_door(id)) + Vector2(0.5, 0.5)).distance_to(p.pos) < 1.3:
			var why := world.business.storefront_refusal(b)
			var cost := Business.storefront_cost()
			fronts.append({"kind": "front_build", "id": str(id), "label": ("Build a storefront by the door (%s)" % ", ".join(cost.keys().map(func(k): return "%d %s" % [int(cost[k]), GameData.item_name(k).to_lower()]))) if why == "" else "A storefront here: " + why.trim_suffix(".")})
	# a workshop's door: whose it is, and (its holder) who else may use it
	for id in world.buildings:
		var b: Dictionary = world.buildings[id]
		if str(b.type) == "workshop" and (Vector2(world.building_door(id)) + Vector2(0.5, 0.5)).distance_to(p.pos) < 1.3:
			here.append({"kind": "workshop", "thing": b, "label": World.cap(world.property.describe(b)) + (": who may use it" if world.holds(World.PLAYER, b) else "")})
	if p.home != "" and world.buildings.has(p.home):
		var door := Vector2(world.building_door(p.home)) + Vector2(0.5, 0.5)
		if door.distance_to(p.pos) < 1.3:
			here.append({"kind": "home", "label": "Your house: rest, store things"})
		elif world.property.rooms_of(p.home).has(world.place_of(p.pos)):
			# inside the house or a living quarters / storeroom added to it: the bed rests, the chest is the family's store
			for sp in world.interiors[world.place_of(p.pos)].spots:
				var at := Vector2(int(sp.at[0]), int(sp.at[1])) + Vector2(0.5, 0.5)
				if at.distance_to(probe) < 0.9 and sp.kind == "bed":
					here.append({"kind": "rest", "label": "Your bed: rest until morning"})
				elif at.distance_to(probe) < 0.9 and sp.kind == "chest":
					here.append({"kind": "home", "label": "Your chest: store things, rest"})
	# PL2-002: other chests in the building the player stands in (the family chest is handled above)
	var inside := world.place_of(p.pos)
	if inside != "" and inside != p.home:
		for cu in world.chests.units_in(inside):
			if cu.at.distance_to(probe) < 0.9:
				here.append(_chest_target(cu))
	# the player's own furniture by spot kind (Furniture.options): chairs to sit on, the home oven, the food table
	here.append_array(Furniture.options(world, world.place_of(p.pos), probe))
	here = fronts + here
	here.reverse()
	cands.append_array(here)
	var stall_build := _stall_build_target()          # STALL-01: offered last, only with the planks in the pack
	if not stall_build.is_empty():
		cands.append(stall_build)
	if not farm_low.is_empty():                          # tilling: the plough in hand makes it the first choice, else the last
		if p.tool != "" and GameData.item(p.tool).get("tool", "") == "plough":
			cands.push_front(farm_low[0])
		else:
			cands.append(farm_low[0])
	# the next step of the player's work for the manor, where it is done
	var mw: ManorWork = world.manor_work
	var mj := mw.job_of("player")
	if not mj.is_empty():
		var at := Vector2(mw.step_cell(mj)) + Vector2(0.5, 0.5)
		if at.distance_to(p.pos) < 1.6:
			var job := {"kind": "manor_job", "label": _manor_label(mj)}
			if cands.is_empty() or not str(cands[0].kind) in ["npc", "shop"]:
				cands.push_front(job)
			else:
				cands.append(job)
	# a villager by the seam, tree or plant in front (often working it too) no longer takes the default:
	# A works the resource and Y / T talks to them (owner, Build 13 playtest)
	talk_alt = {}
	if not front.is_empty() and not cands.is_empty() and str(cands[0].kind) in ["npc", "shop"]:
		talk_alt = cands[0]
		cands.erase(front)
		cands.push_front(front)
	# taking what is not yours is never the default choice: it is offered last (Q / Tab reaches it)
	var lawful := cands.filter(func(c): return not str(c.get("label", "")).contains("theft"))
	cands = lawful + cands.filter(func(c): return str(c.get("label", "")).contains("theft"))
	target_options = cands
	var pick := 0
	for i in cands.size():
		if _target_key(cands[i]) == target_pref:
			pick = i
			break
	if target_pref != "" and (cands.is_empty() or _target_key(cands[pick]) != target_pref):
		target_pref = ""
	target = cands[pick] if not cands.is_empty() else {}
	# a seam, tree, field or animal is offered when the player stops by it, not flashed while walking past
	var passing: bool = walking and target.get("kind", "") in ["deposit", "tree", "field", "plant", "animal", "farm"]
	if not gather.is_empty():
		ui.prompt("")     # gathering: the outline and the progress bar show it; the middle stays clear
	else:
		var text: String = "" if passing else target.get("label", "")
		if text != "" and not talk_alt.is_empty() and _target_key(target) != _target_key(talk_alt):
			text += "\n%s: %s" % [{"kbm": "T", "gamepad": "Y", "touch": "Tap them"}.get(scheme, "T"), talk_alt.get("label", "")]
		elif text != "" and cands.size() > 1:
			text += "\n" + _next_hint(cands[(pick + 1) % cands.size()], pick)
		ui.prompt(text)


## Which thing a target is, stable from frame to frame (what the labels' counts change is not part of it).
func _target_key(t: Dictionary) -> String:
	var k := str(t.get("kind", ""))
	for f in ["npc", "animal", "id", "i", "c", "dep", "tree", "plant", "field", "plot", "pen", "thing"]:
		if t.has(f):
			var v = t[f]
			if v is Object:
				k += ":" + str(v.get_instance_id())
			elif v is Dictionary:
				k += ":%s,%s,%s" % [v.get("x", v.get("id", "")), v.get("y", ""), v.get("name", "")]
			else:
				k += ":" + str(v)
	return k


## The prompt's second line: what the next choice is and how to reach it.
func _next_hint(next: Dictionary, at: int) -> String:
	var keys := {"kbm": "Q / Tab", "gamepad": "D-pad left / right", "touch": "tap it"}
	var l: String = next.get("label", "")
	return "%s: next - %s (%d of %d)" % [keys.get(scheme, "Q / Tab"), l.get_slice(":", 0).get_slice(" (", 0), at + 1, target_options.size()]


## Choose the next (1) or previous (-1) of the things on offer (Q or Tab, the D-pad: LB and RB keep the
## map and skills). Use (A, E, a tap) always does the chosen one; B stays Cancel.
func cycle_target(dir: int) -> void:
	if target_options.size() < 2:
		return
	var at := 0
	for i in target_options.size():
		if _target_key(target_options[i]) == _target_key(target):
			at = i
	at = posmod(at + dir, target_options.size())
	target_pref = _target_key(target_options[at])
	target = target_options[at]
	_find_target()


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
		"sample":
			return "Take a rock sample for the manor's survey (%d of %d)" % [int(j.taken) + 1, int(j.qty)]
		"assay":
			return "Have the survey's samples assayed here (%d coins each)" % int(Prospecting.cfg().assay.fee)
		"report":
			return "Tell the manor what the survey's samples showed"
		"dig":
			return "Dig the manor's trial pit here (%d hours)" % roundi(float(Discovery.cfg().trial.minutes) / 60.0)
	return ""


## The counters and stalls the player can buy at: {id, stall, cells (tile centres to use)}.
func _shop_posts() -> Array:
	var out := []
	for id in world.stations_of("tavern_counter"):
		var st: Dictionary = world.stations[id]
		out.append({"id": id, "stall": false, "cells": [Vector2(int(st.use[0]) + 0.5, int(st.use[1]) + 0.5), Vector2(int(st.at[0]) + 0.5, int(st.at[1]) + 0.5)]})
	for id in world.counters.all():                   # skilled trades' counters (CTR-01)
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
	if world.counters.is_counter(post.id):
		var on_way := world.counters.server(post.id)
		if on_way != null:
			return {"kind": "info", "label": "%s is coming to %s" % [on_way.name, world.counters.counter_name(post.id)], "text": "%s %s is on the way." % [on_way.name, on_way.family]}
		return {"kind": "summon", "id": post.id, "label": "Ring for service at %s" % world.counters.counter_name(post.id)}
	if post.stall:
		var s: Dictionary = world.stalls[post.id]
		if Stalls.is_built(s):
			return _built_stall_target(s)
		if Business.is_pitch(s):
			var mine := world.tenant_of(s) == World.PLAYER
			if not mine and world.tenant_of(s) != "":
				return {"kind": "info", "label": "An open market pitch", "text": "Nobody keeps this pitch."}
			return {"kind": "stall", "id": post.id, "label": "Manage your market stall" if mine else "Rent this market pitch (%d coins a day)" % Business.rent_day()}
		return _container_target({"id": post.id, "kind": "stall", "x": int(s.x), "y": int(s.y), "at": post.id})
	return {"kind": "info", "label": "The tavern counter: nobody is serving", "text": "Nobody is serving at the counter now."}


## A market stall someone built (STALL-01): the player's own is managed (stock, OPEN / CLOSE, settlement); another's
## shows whose it is and what it holds.
func _built_stall_target(s: Dictionary) -> Dictionary:
	if world.holds(World.PLAYER, s):
		return {"kind": "stall", "id": str(s.id), "label": "Manage your market stall (%s)" % ("open" if world.business.stalls.is_open(s) else "closed")}
	return {"kind": "stall", "id": str(s.id), "label": "%s's market stall" % world.ref_name(world.holder_of(s), true)}


## Build a market stall on the ground in front (STALL-01, owner Q10: three planks from the pack): offered while the
## player carries the planks, stands outdoors and the ground in front is a legal site. {} otherwise.
func _stall_build_target() -> Dictionary:
	var p := world.player
	if not p.inv.has_all(Stalls.cost()) or world.place_of(p.pos) != "" or facing_vec().y > -0.5:
		return {}                       # facing up: the awning goes in front, the player stands where buyers will
	var c := Vector2i((p.pos + facing_vec() * 0.9).floor())
	if world.business.stalls.site_refusal(c, World.PLAYER) != "":
		return {}
	var need := Stalls.cost()
	return {"kind": "stall_build", "c": c, "label": "Build a market stall here (%s)" % ", ".join(need.keys().map(func(k): return "%d %s" % [int(need[k]), GameData.item_name(k).to_lower()]))}


## In a room of the player's: its shop counter (open or manage the shop) and fitting the room out (PL1-10 stage 3).
func _fit_targets(place: String) -> Array:
	var out := []
	var b: Dictionary = world.buildings.get(place, {})
	if b.is_empty() or world.fitting.fit_refusal(b) != "":
		return out
	out.append({"kind": "fitout", "id": place, "label": "Fit out this room (counter, shelves, equipment)"})
	var e := world.fitting.entry(b, "counter")
	if not e.is_empty() and Vector2(int(e.use[0]) + 0.5, int(e.use[1]) + 0.5).distance_to(world.player.pos) < 1.4:
		out.append({"kind": "stall", "id": place, "label": "Manage your shop" if b.has("shop") else "Open a shop here (%d coins a day)" % int(GameData.b("shop_licence_day"))})
	return out


## What using a container does, said in its prompt: "Take pottage (the tavern's) — theft".
func _container_target(c: Dictionary) -> Dictionary:
	if c.kind == "crate" or c.kind == "barrel":
		var cu := world.chests.unit_of_container(c)
		if world.chests.info(cu).access != "decor":
			return _chest_target(cu)
	var id := world.container_pick(c)
	var whose := world.container_whose(c)
	if id == "":
		return {"kind": "info", "label": "Empty %s (%s)" % [c.kind, whose], "text": "There is nothing in the %s." % c.kind}
	return {"kind": "container", "c": c, "label": "Take %s (%s) — theft" % [GameData.item_name(id).to_lower(), whose]}


## A chest, crate or barrel (PL2-002): yours to fill, or someone else's (theft, perhaps locked).
func _chest_target(u: Dictionary) -> Dictionary:
	var i: Dictionary = world.chests.info(u)
	if i.access == "decor":
		return {"kind": "info", "label": "A chest for show", "text": world.chests.cannot_open(u)}
	var what := "%s %s" % [i.whose, u.kind]
	if i.access == "own":
		return {"kind": "chest", "id": u.id, "label": "Open %s: store things" % what}
	if world.chests.is_locked(u):
		return {"kind": "chest", "id": u.id, "label": "Locked %s: pick the lock (theft)" % what}
	return {"kind": "chest", "id": u.id, "label": "Open %s (theft)" % what}


## Pick a locked chest's lock (PL2-002): takes game time, may snap the pick, and may be seen.
func pick_lock(uid: String) -> void:
	var u := world.chests.unit(uid)
	var why := world.chests.cannot_pick(u)
	if why != "":
		ui.message(why)
		return
	var secs := world.chests.pick_minutes(u) / float(GameData.b("game_minutes_per_second"))
	ui.hide_all()
	start_action("Picking the lock", secs, func():
		var r: Dictionary = world.chests.attempt(u)
		_xp("stealth", 4 if r.result == "open" else 1)
		ui.message(r.text, 6.0)
		if r.result == "open":
			ui.show_chest(uid))


## The centre of the counter, stall or container at a map position, or INF.
## The pile of loot drawn at a map position (within 0.8 tile), or INF.
func _loot_at(wpos: Vector2) -> Vector2:
	for l in world.loot:
		if l.pos.distance_to(wpos) < 0.8 and World.level_of(l) == world.player_level:
			return l.pos
	return Vector2.INF


func _usable_at(wpos: Vector2) -> Vector2:
	var cell := Vector2i(floori(wpos.x), floori(wpos.y))
	var at := Vector2(cell) + Vector2(0.5, 0.5)
	for c in world.containers:
		if int(c.x) == cell.x and int(c.y) == cell.y:
			return at
	for cu in world.chests.units_in(world.place_of(wpos)):
		if Vector2i(cu.at) == cell:
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


## Y / T beside a resource: talk to the villager offered with it (talk_alt), leaving A on the resource.
func talk_to_alt() -> void:
	if talk_alt.is_empty():
		return
	target = talk_alt
	interact()


func interact() -> void:
	if target.is_empty():
		return
	# in Gather mode, Use (keys, pad, the touch button) on a resource in front chooses it to gather
	if gather_mode and target.kind in ["deposit", "tree", "field", "plant"]:
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
		"tree", "fruit":
			return Vector2i(int(t.tree.x), int(t.tree.y))
		"field":
			return Vector2i(int(t.field.x), int(t.field.y))
		"plant":
			return Vector2i(int(t.plant.x), int(t.plant.y))
	return Vector2i.ZERO


## A gain line in the corner with the item's icon (the pack's item id): the one place gains go through.
## The last few are kept in gain_log (item id, text) for the tests.
func _gain(text: String, item := "") -> void:
	gain_log.append([item, text])
	if gain_log.size() > 40:
		gain_log.pop_front()
	ui.gain(text, item)


## Do what the current target offers, once (Use; and each cycle of gathering).
func _use() -> void:
	var p := world.player
	if str(target.get("kind", "")) in ["deposit", "tree", "plant", "loot", "fruit"]:
		var tp: Vector2 = world.loot[target.i].pos if target.kind == "loot" and target.i < world.loot.size() else Vector2(_target_cell(target)) + Vector2(0.5, 0.5)
		if not world.reaches(p.pos, tp):
			stop_gather("")
			ui.message("A wall is in the way.")
			return
	match target.kind:
		"npc":
			approach(target.npc)
		"shop":
			ui.show_trade(target.npc)
		"stall":
			ui.show_stall(str(target.id))
		"front_build":
			var why := world.business.build_storefront(world.buildings[str(target.id)])
			ui.message(why if why != "" else "Your storefront stands by the door. List goods at its counter.")
		"stall_build":
			var why := world.construction.build_stall(World.PLAYER, target.c, p.inv)
			ui.message(why if why != "" else "Your market stall stands. Put goods in it and open it; it sells while you are away.")
		"front_open":
			var why := world.business.open_front(world.buildings[str(target.id)])
			ui.message(why if why != "" else "Your storefront is open.")
		"cart_pull":
			var why := world.carts.hitch(world.carts.by_id(int(target.id)), World.PLAYER)
			ui.message(why if why != "" else "You take hold of the cart. It follows you, slower going.")
		"cart_park":
			world.carts.park(world.carts.by_id(int(target.id)))
			ui.message("You let go of the cart." + (" It stands at %s." % world.carts.stop_at(p.pos).name if not world.carts.stop_at(p.pos).is_empty() else ""))
		"fitout":
			ui.show_fitout(str(target.id))
		"summon":
			ui.message(world.counters.summon(str(target.id)).text)
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
			var taken := 0
			for id in l.inv.ids():
				var n: int = l.inv.count(id)
				if p.inv.add(id, n):
					l.inv.remove(id, n)
					taken += n
					_gain("+%d %s" % [n, GameData.item_name(id)], id)
			if int(l.coins) > 0:
				_gain("+%d coins" % int(l.coins), "coins")
			elif taken == 0:
				ui.message("Your pack is full." if l.inv.total() > 0 else "There is nothing left.")
			elif l.inv.total() > 0:
				ui.message("Your pack is full: some is left behind.")
			p.coins += int(l.coins)
			l.coins = 0
			if l.inv.total() == 0:
				world.loot.remove_at(target.i)
		"sample":
			_sample(target.clue, target.cell)
		"assay":
			_assay(target.npc)
		"trial_dig":
			_trial_dig(target.clue, target.cell, str(target.tool))
		"deposit":
			var dep: Dictionary = target.dep
			var mp := world.player_mine_plan(dep)                     # the rules are in core (DVW-A12 R1)
			if not mp.ok:
				ui.message(str(mp.why))
				return
			var pick: String = mp.tool
			start_action("Mining", float(mp.secs), func():
				var r := world.player_mine(dep, pick)                  # the same swing as a miner's (PAR-01)
				if r.result == "out":
					ui.message("The seam is worked out.")
					return
				if r.result == "gold":
					ui.message("Gold needs Mining level 3.")
					return
				if r.full:
					ui.message("Your pack is full: the ore is left at your feet.")
				else:
					_gain("+%d %s" % [int(r.n), GameData.item_name(str(r.ore))], str(r.ore))
				if r.broke:
					ui.message("Your %s broke." % GameData.item_name(pick).to_lower())
				_level_up("mining", int(r.up)), "swing", pick)
		"tree":
			var tr: Dictionary = target.tree
			var fp := world.player_fell_plan(tr)                      # the rules are in core (DVW-A12 R2)
			if not fp.ok:
				ui.message(str(fp.why))
				return
			_chop(tr, str(fp.tool), float(fp.secs))
		"station":
			ui.show_craft(target.id)
		"field":
			var f: Dictionary = target.field
			start_action("Harvesting", 2.5, func():
				var got := world.player_harvest(f)
				if got > 0:
					_gain("+%d %s" % [got, GameData.item_name("wheat")], "wheat")
				else:
					ui.message("Nothing left to harvest."))
		"fruit":
			var ftree: Dictionary = target.tree
			var fitem: String = str(Trees.fruit_cfg(str(ftree.species)).item)
			if not p.inv.can_add(fitem):
				ui.message("Your pack is full.")
				return
			start_action("Picking", 1.5, func():
				var got := world.pick_fruit(ftree)
				for id in got:
					p.inv.add(id, int(got[id]))
					_gain("+%d %s" % [int(got[id]), GameData.item_name(id)], id)
				if got.is_empty():
					ui.message("Nothing left to pick."))
		"plant":
			var pl: Dictionary = target.plant
			var pdef := ResourceNodes.def_for("plant", str(pl.kind))
			for id in ResourceNodes.products(pdef):
				if not p.inv.can_add(id):
					ui.message("Your pack is full.")
					return
			start_action("Picking", 1.2, func():
				var got := world.pick_plant(pl)
				for id in got:
					p.inv.add(id, int(got[id]))
				if got.is_empty():
					ui.message("Nothing left to pick.")
				else:
					var cut := world.propagation_drop(pl)        # SEED-02: a cutting or seed by its chance, as for villagers
					for id in cut:
						if world.player_gain(id, int(cut[id])) > 0:
							got[id] = int(cut[id])
				for k in got:
					_gain("+%d %s" % [int(got[k]), GameData.item_name(k)], k))
		"pen":
			var put := world.fauna.feed(target.pen, p.inv, 5)
			ui.message("You put %d wheat in the trough." % put if put > 0 else "You have no wheat to feed them.")
		"animal":
			var own: bool = not target.animal.wild() and world.fauna.pens.has(target.animal.area) and world.fauna.pens[target.animal.area].get("player", false)
			ui.message("Attack (Space) to hunt it." if target.animal.wild() else ("It is yours: feed it at the pen's gate. Attack (Space) to slaughter it for meat." if own else "These belong to the keeper. Killing them is theft."))
		"farm":
			var fp: Dictionary = world.farm.plan(target, p)
			if not fp.ok:
				ui.message(str(fp.why))
				return
			player_sprite.face(Vector2(target.cell) + Vector2(0.5, 0.5) - p.pos)
			start_action(str(fp.label), float(fp.secs), func():
				var r: Dictionary = fp.run.call()
				for id in r.items:
					_gain("+%d %s" % [int(r.items[id]), GameData.item_name(id)], id)
				if str(r.text) != "":
					ui.message(str(r.text)), str(fp.anim), str(fp.tool))
		"pen_collect":
			var got: Dictionary = world.farm.collect(target.pen, p)
			if got.is_empty():
				ui.message("Your pack is full.")
			for id in got:
				_gain("+%d %s" % [int(got[id]), GameData.item_name(id)], id)
		"pen_buy":
			var no: String = world.farm.buy_animal(target.pen, str(target.sex), p)
			ui.message(no if no != "" else "You buy it and walk it into your pen.")
		"plot":
			ui.show_build(target.plot)
		"workshop":
			ui.show_workshop(target.thing)
		"property":
			ui.show_deal(target.thing)
		"home":
			ui.show_home()
		"chest":
			ui.show_chest(target.id)
		"rest":
			rest()
		"sit":
			sit_down(target.spot)
		"manor_job":
			var mw: ManorWork = world.manor_work
			var mj := mw.job_of("player")
			if mj.is_empty():
				return
			var pay := int(mj.reserved)
			var finish := func(ok: bool) -> void:
				if not ok:
					ui.message("You need %d stone for the manor: mine it at the stone seams." % int(mj.qty) if mj.kind == "quarry"
							else (mw.last_refusal if mj.kind in ["survey", "trial"] and mw.last_refusal != "" else "There is nothing here to take."))
				elif mw.job_of("player").is_empty():
					var found := ""
					if mj.kind == "trial":
						found = " The pit strikes ore: a new seam is opened." if mj.get("found", false) else " The pit finds no ore."
					ui.message("Work for the manor done.%s The manor pays you %d coins." % [found, pay])
				elif mj.kind == "survey":
					ui.message(ui._manor_next(mj))
				else:
					ui.message("You take the manor's goods. %s" % ui._manor_next(mj))
			mw.last_refusal = ""
			var step := mw.step(mj)
			if step == "mend":
				var secs := float(ManorWork.cfg("mend_minutes")) / float(GameData.b("game_minutes_per_second")) * 0.6
				start_action("Mending", secs, func(): finish.call(mw.do_step(mj, "player", p.inv)), "swing", "hammer")
			elif step == "sample":
				start_action("Sampling", Prospecting.player_secs(), func(): finish.call(mw.do_step(mj, "player", p.inv)), "swing", "hammer")
			elif step == "dig":
				start_action("Digging a trial pit", Discovery.player_secs(), func(): finish.call(mw.do_step(mj, "player", p.inv)), "swing", "pickaxe")
			else:
				finish.call(mw.do_step(mj, "player", p.inv))


## MIN-C: what prospecting offers here: the ground of a clue's search area underfoot (sample it with a prospector's
## kit, or what the stain is without one), and a smith in `cands` who could assay a rock sample the player carries.
## The rules are Prospecting's (the same as a prospector's); this only offers them.
func _prospect_targets(cands: Array) -> Array:
	var out := []
	var pr: Prospecting = world.prospecting
	if pr == null or world.player_level != 0:
		return out
	var p := world.player
	var cell := Vector2i(floori(p.pos.x), floori(p.pos.y))
	var c := pr.area_at(cell)
	if not c.is_empty():
		var key := "%s@%d,%d" % [c.id, cell.x, cell.y]
		if not p.inv.has(Prospecting.KIT):
			out.append({"kind": "info", "id": key, "text": pr.sample_refusal(p, c, cell),
					"label": "%s near here: a prospector's kit could sample it" % World.cap(pr.stain(c))})
		elif pr.samples_left(c) > 0:
			out.append({"kind": "sample", "id": key, "clue": c, "cell": cell,
					"label": "Take a rock sample here (%s nearby; %d samples left round it)" % [pr.stain(c), pr.samples_left(c)]})
	# MIN-D: a trial pit on clear ground of a clue's area in front of the player, with a pickaxe (Discovery.trial_dig)
	var ahead := Vector2i((p.pos + facing_vec() * 1.0).floor())
	var ca := pr.area_at(ahead)
	var pick := p.tool_of("pickaxe")
	if not ca.is_empty() and pick != "" and world.discovery.ground_refusal(ca, ahead) == "":
		out.append({"kind": "trial_dig", "id": "%s@%d,%d" % [ca.id, ahead.x, ahead.y], "clue": ca, "cell": ahead, "tool": pick,
				"label": "Dig a trial pit here (%s nearby; %d hours; %d pits left round it)" % [pr.stain(ca), roundi(float(Discovery.cfg().trial.minutes) / 60.0), world.discovery.trials_left(ca)]})
	if p.inv.has(Prospecting.ITEM):
		for t in cands:
			if str(t.get("kind", "")) in ["npc", "shop"] and (t.npc as NPC).job == "smith" and not world.asleep(t.npc):
				out.append({"kind": "assay", "npc": t.npc, "label": "Ask %s to assay a rock sample (%d coins)" % [(t.npc as NPC).name, int(Prospecting.cfg().assay.fee)]})
	return out


## MIN-C: take a rock sample from the ground underfoot, timed as a mining swing (Prospecting.take_sample: the kit
## wears, the sample and its origin go to the pack, Mining xp).
func _sample(c: Dictionary, cell: Vector2i) -> void:
	var p := world.player
	var why := world.prospecting.sample_refusal(p, c, cell)
	if why != "":
		ui.message(why)
		return
	start_action("Sampling", Prospecting.player_secs(), func():
		var r := world.prospecting.take_sample(p, c, cell)
		if r.result != "ok":
			ui.message(str(r.why))
			return
		_gain("+1 %s" % GameData.item_name(Prospecting.ITEM), Prospecting.ITEM)
		if r.broke:
			ui.message("Your prospector's kit is worn out.")
		_level_up("mining", int(r.up)), "swing", "hammer")


## MIN-D: dig a trial pit on the cell ahead, timed as a mining swing (Discovery.trial_dig: the pickaxe wears, Mining
## xp; within reach of the clue's body a seam is opened there, else nothing is found).
func _trial_dig(c: Dictionary, cell: Vector2i, tool: String) -> void:
	var p := world.player
	var why := world.discovery.trial_refusal(p, c, cell, tool)
	if why != "":
		ui.message(why)
		return
	start_action("Digging a trial pit", Discovery.player_secs(), func():
		var r := world.discovery.trial_dig(p, c, cell, tool)
		if r.result != "ok":
			ui.message(str(r.why))
			return
		if (r.found as Dictionary).is_empty():
			ui.message("The trial pit finds no ore.")
		else:
			ui.message("The trial pit strikes %s: a new seam is opened." % GameData.item_name(str(r.found.ore)).to_lower())
		if r.broke:
			ui.message("Your pickaxe broke.")
		_level_up("mining", int(r.up)), "swing", "pickaxe")


## MIN-C: smith `n` assays the oldest rock sample the player carries (Prospecting.assay: the fee, the coal, the forge
## for the assay's time); the player waits beside the forge for the reading.
func _assay(n: NPC) -> void:
	var r := world.prospecting.assay(world.player, n)
	if r.result != "ok":
		ui.message(str(r.why))
		return
	var rec: Dictionary = r.record
	var c := world.prospecting.clue(str(rec.clue))
	var said := "%s assays your sample from %s %s: %s." % [n.name, world.prospecting.stain(c), world.prospecting.place(c),
			world.prospecting.reading_text(rec)]
	start_action("Waiting for the assay", float(Prospecting.cfg().assay.minutes) / float(GameData.b("game_minutes_per_second")) * 0.6,
			func(): ui.message(said), "gather")


## Fell a mature tree blow by blow: each blow is a short action that cuts the tree (its cut marks, chips
## and leaves show it), and the last one brings it down. `secs` is the whole felling's time.
func _chop(tr: Dictionary, axe: String, secs: float) -> void:
	var p := world.player
	var chops := int(Trees.cfg().chops)
	var cell := Vector2i(int(tr.x), int(tr.y))
	var side := -1 if p.pos.x < float(cell.x) + 0.5 else 1
	player_sprite.face(Vector2(cell) + Vector2(0.5, 0.5) - p.pos)
	start_action("Chopping %d/%d" % [world.tree_hits(cell) + 1, chops], secs / float(chops), func():
		var r := world.player_chop(tr, side, axe)          # the same felling as a woodcutter's (PAR-01, DVW-A12 R2)
		if r.result == "gone":
			return                                       # someone else felled it meanwhile
		if r.result == "blow":
			_chop(tr, axe, secs)
			return
		if r.full:
			ui.message("Your pack is full: the logs are left at your feet.")
		else:
			_gain("+%d %s" % [int(r.logs), GameData.item_name("log")], "log")      # a short line in the corner, not a banner
		for id in r.saplings:
			_gain("+%d %s" % [int(r.saplings[id]), GameData.item_name(id)], id)
		if r.broke:
			ui.message("Your %s broke." % GameData.item_name(axe).to_lower())
		_level_up("woodcutting", int(r.up)), "swing", axe)


## Plant a sapling from the pack (the pack window's Plant button) on the free grass in front of the player.
## B14: set the handcart from the pack down in front of you; it becomes a cart in the world.
func set_down_cart() -> void:
	var p := world.player
	if not p.inv.has("handcart"):
		return
	var at := p.pos + facing_vec()
	if map.is_solid_world(Vector2i(floori(at.x), floori(at.y))):
		at = p.pos
	p.inv.remove("handcart", 1)
	world.carts.place(World.PLAYER, at)
	ui.message("You set the handcart down. Use it to pull it, or open it to load it.")


func plant_sapling(item: String) -> void:
	if World.propagates(item) != "":
		plant_cutting(item)
		return
	var p := world.player
	var cell := Vector2i((p.pos + facing_vec() * 1.0).floor())
	var why := world.plant_refusal(cell)
	ui.hide_all()
	if why != "":
		ui.message(why)
		return
	player_sprite.face(Vector2(cell) + Vector2(0.5, 0.5) - p.pos)
	start_action("Planting", float(Trees.cfg().plant_seconds), func():
		if not p.inv.has(item) or world.plant_refusal(cell) != "":
			ui.message("It cannot be planted there now.")
			return
		var t := world.plant_tree(cell, item)
		if not t.is_empty():
			p.inv.remove(item, 1)
			world.stat("used_" + item)               # the sapling is used up (SEED-02: the ledger counts it)
			ui.message("You plant the %s. It will grow into a tree in a few days." % GameData.item_name(item).to_lower().replace(" sapling", " sapling"))
	)


## SEED-02: plant a berry cutting or wild flower seed from the pack (the pack window's Plant button) on the free grass
## in front of the player, by the sapling rule; it is used up and a young plant grows there (World.plant_bush).
func plant_cutting(item: String) -> void:
	var p := world.player
	var cell := Vector2i((p.pos + facing_vec() * 1.0).floor())
	var why := world.plant_bush_refusal(cell, item)
	ui.hide_all()
	if why != "":
		ui.message(why)
		return
	player_sprite.face(Vector2(cell) + Vector2(0.5, 0.5) - p.pos)
	start_action("Planting", float(Trees.cfg().plant_seconds), func():
		var pl := world.plant_bush(cell, item, p.inv)
		if pl.is_empty():
			ui.message("It cannot be planted there now.")
			return
		ui.message("You plant the %s. It will bear in about %d days, in its season." % [GameData.item_name(item).to_lower(), maxi(1, int(pl.regrow) - world.day())])
	)


## Begin a timed piece of work: `anim` is "swing" (with `tool`, the item held in the hand: the pickaxe
## for mining, the axe for felling) or "gather" (picking, harvesting, planting); it plays until the work ends
## or is cancelled (cancel_action), then the player is back to idle.
func start_action(label: String, secs: float, done: Callable, anim := "gather", tool := "") -> void:
	action = {"label": label, "left": secs, "total": secs, "done": done, "anim": anim, "tool": tool}
	move_to = Vector2.INF
	sprinting = false
	player_sprite.hold(tool)
	player_sprite.play(anim)


func _xp(skill: String, n: int) -> void:
	_level_up(skill, world.player.gain(skill, n))


## The banner for a new level (`up` 0: none).
func _level_up(skill: String, up: int) -> void:
	if up > 0:
		var s: Dictionary = GameData.skills[skill]
		var unlock := Skills.tier_text(skill, up)
		ui.message("%s is now level %d!%s" % [s.name, up, (" Unlocked: " + unlock) if unlock != "" else ""])


## Craft a recipe at a station (called from the craft panel). Same recipe data as the NPCs.
## `station`: the station worked at (the craft window's); without one, the one of the recipe's kind the
## player stands at. A workshop not theirs needs leave, and a villager working at a station the player
## does not hold is waited for (World.station_refusal); the player's work takes the station meanwhile.
func craft(recipe: String, station := "") -> void:
	var r: Dictionary = GameData.recipes[recipe]
	var cp := world.player_craft_begin(recipe, station)          # the rules are in core (DVW-A12 R3)
	if not cp.ok:
		ui.message(str(cp.why))
		return
	station = str(cp.station)
	ui.hide_all()
	start_action("Crafting", float(cp.secs), func():
		var res := world.player_craft(recipe)                   # the same as a villager's (PAR-01, PAR-04)
		if res.result != "ok":
			return
		_level_up(str(r.skill), int(res.up))
		ui.message("Made %s." % ", ".join(r.out.keys().map(func(k): return GameData.item_name(k)))),
			"swing" if str(r.station) in ["forge", "anvil", "workbench", "sawhorse"] else "gather", "hammer" if str(r.station) in ["forge", "anvil", "workbench", "sawhorse"] else "")
	if station != "" and not action.is_empty():
		action["station"] = station          # released the moment the work ends or is cut short (Build 13)


# ---------------------------------------------------------------- combat ---------------------
## A press of Attack: a swing of the weapon at whatever is in front; with `only`, it can hit nobody else.
## A press while swinging is kept for the next swing when the swing is nearly over (Combat, CQ-01).
## Returns "start", "queued" or "ignored".
func attack(only: Object = null) -> String:
	if not action.is_empty():
		return "ignored"
	if world.player_level != 0:
		ui.message("Nothing to fight here.")      # MIN-A: nobody but the player goes below yet
		return "ignored"
	var r := swing.press(swing_time(), only)
	if r == "start":
		_swing_begins()
	return r


## Seconds one swing takes: windup, blow and recovery (the Combat tier makes it shorter).
func swing_time() -> float:
	return float(Combat.cfg().swing_time) * Skills.value(world.player, "combat", "attack_time", 1.0)


func _swing_begins() -> void:
	sprinting = false                  # no sprint while attacking
	if swing.only != null and swing.only.alive:
		player_sprite.face(swing.only.pos - world.player.pos)
	player_sprite.play("sword", true)  # the press shows at once; the blow lands on the slash frame


func _swing_step(delta: float) -> void:
	match swing.step(delta, swing_time()):
		"blow":
			_blow()
		"start":
			_swing_begins()


## The blow of a swing, on the slash frame: one target, once (Combat.target).
func _blow() -> void:
	var p := world.player
	var who: Object = Combat.target(world, p.pos, facing_vec(), swing.only)
	if who is NPC:
		swing.hits += 1
		var hp0: float = who.hp
		var h := world.player_melee_npc(who)          # the strike, the harm, the crime and the xp are core's (DVW-A12 R7-R9)
		if h.crit:
			ui.message("A telling blow!")
		_hit_fx(sprites.get(who.id), who.max_hp, hp0 - float(h.dealt), float(h.dealt))
		_level_up("combat", int(h.up))
	elif who is Animal:
		swing.hits += 1
		var s := world.player_strike()
		if s.crit:
			ui.message("A telling blow!")
		_hit_animal(who, float(s.dmg))


## The touch Attack button: fight a foe within reach (a bandit, someone fighting you, or game);
## with none, wait for a tap on who or what to attack. Villagers are only attacked by choice.
func attack_button() -> void:
	var foe := _foe_in_reach()
	if foe != null:                    # a foe in reach: the button swings at it (CQ-01), the mode stays as it is
		player_sprite.face(foe.pos - world.player.pos)
		attack(foe)
		return
	attack_mode = not attack_mode
	if attack_mode and gather_mode:
		gather_button()                # Attack and Gather exclude each other
	if not attack_mode:
		chase = null
		strike_pending = false
	ui.set_attack_mode(attack_mode)
	ui.message("Attack mode: tap who or what to attack. Tap Attack again to stop." if attack_mode else "Attack mode off.")


## The nearest foe (a bandit, anyone fighting the player) or wild game within sword reach in any direction,
## with a clear line, or null.
func _foe_in_reach() -> Object:
	var p := world.player
	var best: Object = null
	var bd := INF
	for n: NPC in world.present(p.pos, float(Combat.cfg().reach)):
		if n.alive and Combat.foe(n) and not _covered(n) and Combat.in_reach(world, p.pos, n.pos - p.pos, n.pos) and p.pos.distance_to(n.pos) < bd:
			bd = p.pos.distance_to(n.pos)
			best = n
	for a: Animal in world.fauna.near(p.pos, float(Combat.cfg().reach)):
		if a.alive and a.wild() and Combat.in_reach(world, p.pos, a.pos - p.pos, a.pos) and p.pos.distance_to(a.pos) < bd:
			bd = p.pos.distance_to(a.pos)
			best = a
	return best


## Mark a person or animal with the sword and strike it: the player walks over if needed. Each
## further tap (or right-click) on it is another strike; picking someone else moves the sword.
func strike(who: Object) -> void:
	if who is NPC and (who as NPC).depth != world.player_level:
		return                             # MIN-A: rock lies between them
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
	# strike from sword reach; when walking in, stop a little inside it so a step back by the target does not miss
	var reach := float(Combat.cfg().reach) - (0.2 if move_to != Vector2.INF else 0.0)
	if d.length() > reach or not Combat.clear_line(world, p.pos, chase.pos):
		move_to = chase.pos
		return
	move_to = Vector2.INF
	if strike_pending and action.is_empty():
		player_sprite.face(d)
		if attack(chase) != "ignored":
			strike_pending = false


## Hunting: a wild animal killed by the player leaves its meat (and hide) where it fell. Killing
## livestock is theft from its keeper, a crime like attacking a villager.
func _hit_animal(a: Animal, dmg: float) -> void:
	var before := a.hp
	a.hp -= dmg
	_hit_fx(animal_sprites.get(a.id), before, a.hp, dmg)
	if a.hp > 0.0:
		world.fauna.provoke(a, "player")            # a wolf or a bear fights back (B14)
		return
	_xp("combat", Skills.kill_xp(a.species, world.player.damage()))     # per kill, as a villager's (FSE-B12)
	var keeper: NPC = null
	if not a.wild():
		keeper = world.pen_keeper(world.fauna.pens[a.area])
	var what := a.label().to_lower()
	var beast := a.wild() and bool(a.spec().get("people", false))
	world.stat(("hunted_" if a.wild() else "slaughtered_") + a.species)     # FSE-B10: the wildlife ledger, as for villagers
	var bag: Inventory = world.fauna.kill(a)
	if beast:
		world.relations.defended(a.pos)        # a wolf or a bear put down near people (CRT-10)
	if bag.total() > 0:
		world.loot.append({"pos": a.pos, "inv": bag, "coins": 0, "from": "the " + what, "t": world.minutes})
	if keeper != null:                         # theft from the keeper, known the way a theft is (World.witness, PAR-05)
		var saw := world.near(world.player.pos, float(GameData.b("witness_radius"))).has(keeper)
		world.witness("livestock", "%s's %s" % [keeper.name, what], keeper, {}, null, "kill %s %s's %s" % [keeper.name, keeper.family, what])
		keeper.remember(("%s killed my %s" % [world.player.name, what]) if saw else ("found my %s dead" % what))
		if saw and keeper.role == "adult" and keeper.target == -1:
			keeper.target = -2                # a keeper who sees it comes after the player
		if world.last_guard != "":
			ui.message(world.last_guard)
		world.note("%s %s killed one of %s %s's animals." % [world.player.name, world.player.family, keeper.name, keeper.family])


## A blow of the player's (a spell's) of `dmg` lands on villager `n`: the rules are core's (World.player_hit_npc,
## DVW-A12 R8); the blow is shown here.
func _hit(n: NPC, dmg: float) -> void:
	var hp0 := n.hp
	var h := world.player_hit_npc(n, dmg)
	_hit_fx(sprites.get(n.id), n.max_hp, hp0 - float(h.dealt), float(h.dealt))


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


func fireball() -> void:
	var p := world.player
	if world.player_level != 0:
		ui.message("Nothing to fight here.")      # MIN-A: nobody but the player goes below yet
		return
	if not p.spells.get("fireball", false):
		ui.message("You do not know any spells. The Sage in the hut north of the tavern teaches them.")
		return
	var cd := Skills.value(p, "magic", "fireball_cooldown", float(GameData.b("fireball_cooldown")))
	var cost := float(GameData.b("fireball_stamina")) * Skills.value(p, "magic", "fireball_stamina", 1.0)
	if p.fireball_cd > 0.0 or p.stamina < cost:
		return
	p.fireball_cd = cd
	p.stamina -= cost
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
		var dmg := 14.0 * Skills.value(world.player, "magic", "fireball_damage", 1.0)
		for n: NPC in world.present(pr.pos, 0.6):
			_hit(n, dmg)
			hit = true
			break
		if not hit:
			for a: Animal in world.fauna.near(pr.pos, 0.6):
				_hit_animal(a, dmg)
				hit = true
				break
		if hit:
			_xp("magic", 6)                    # a spell that lands teaches more than one that is cast
		if hit or pr.left <= 0.0 or map.is_solid_world(Vector2i(floori(pr.pos.x), floori(pr.pos.y))):
			pr.node.queue_free()
			projectiles.erase(pr)


# ---------------------------------------------------------------- placing a building ----------
## Choose where to build (owner rule: free placement anywhere legal). The footprint follows the mouse,
## moves a tile at a time with the arrow keys, WASD, the d-pad or the left stick, and goes where a
## finger taps; green where it may go, red with the reason where it may not (Construction.can_place:
## the land office's check, the house-first rule, a reachable door). Place (E, Enter, the pad's A, a
## click on the footprint, or the Place button) opens the deal for the ground; Esc, the pad's B or
## Cancel stops. The game waits meanwhile.
func begin_placement(kind: String, anchor := "") -> void:
	ui.hide_all()
	var size := world.construction.footprint(kind)
	var front := world.player.pos + facing_vec() * (size.y / 2.0 + 1.0)
	placing = {"kind": kind, "at": Vector2i(floori(front.x) - size.x / 2, floori(front.y) - size.y / 2), "anchor": anchor}
	if anchor != "":                 # a module goes against the property: start at the nearest legal place
		var slot := world.construction.find_module_slot(kind, world.plot(anchor), World.PLAYER)
		if slot.size != Vector2i.ZERO:
			placing.at = slot.position
	paused = true
	move_to = Vector2.INF
	ui.show_placing(true)
	_update_ghost()


## Screenshot scene for PL1-10 stages 3-4: a house of the player's fitted out as a bakery shop, stocked, with an
## attendant at the counter (bizshop), the shop window (bizshop_window), the fit-out window (bizfit), the placing bar
## (bizplace), or the larger stall's window (bizlarge).
func _business_scene(mode: String) -> void:
	if mode == "bizlarge":
		world.player.coins = 200
		world.player.inv.add("plank", 8)
		world.business.rent()
		var st: Dictionary = world.business.mine()
		world.business.upgrade(st)
		world.business.list_item(st, "plank", 6)
		world.business.set_display(st, "plank")
		world.player.pos = world.business.use_cell(st) + Vector2(0, 1)
		ui.show_stall(str(st.id))
		return
	var house: Dictionary = world.plots[0]
	world.player.coins = 600
	world.buy_plot(house)
	world.start_site(house)
	for id in GameData.b("house_cost"):
		world.player.inv.add(id, int(GameData.b("house_cost")[id]))
	world.deliver(house, world.player.inv)
	var near := Rect2i(int(house.x) - 14, int(house.y) - 14, int(house.w) + 28, int(house.h) + 28)
	for t in world.trees:
		if t.state == "grown" and near.has_point(Vector2i(int(t.x), int(t.y))):
			world.fell(t, 0)
	var c0: Construction = world.construction
	var room: Dictionary = c0.place("storage", c0.find_module_slot("storage", house, World.PLAYER), World.PLAYER, false, house)
	for id in room.site.need.duplicate():
		world.player.inv.add(id, int(room.site.need[id]))
	world.deliver(room, world.player.inv)
	var b: Dictionary = world.property.building_on(room)
	var f: Fitting = world.fitting
	var cells: Array = f.floor_set(b).keys()
	cells.sort_custom(func(m: Vector2i, n: Vector2i): return m.y > n.y or (m.y == n.y and m.x < n.x))
	for kind in ["counter", "shelves", "shelves", "stock_chest", "oven"]:
		var c := Fitting.cost(kind)
		for id in c:
			world.player.inv.add(id, int(c[id]))
		for cell: Vector2i in cells:
			if f.why_not(b, kind, cell) == "":
				f.place(b, kind, cell)
				break
	world.business.open_shop(b)
	var sh: Dictionary = b.shop
	world.player.inv.add("bread", 6)
	world.player.inv.add("plank", 8)
	world.player.inv.add("iron_ore", 5)
	world.business.list_item(sh, "bread", 4)
	world.business.list_item(sh, "plank", 8)
	world.business.store_item(sh, "iron_ore", 5)
	var att: NPC = world.business.candidates()[0]
	world.business.hire(sh, att)
	att.pos = world.business.use_cell(sh)
	att.anim = "idle"
	att.plan = [world.brain.work(600, "", {}, "idle")]
	var door := Vector2(int(b.door[0]) + 0.5, int(b.door[1]) - 0.5)
	world.player.pos = door
	follow_at = _in_view(world.player.pos * T)
	if mode == "bizshop_window":
		ui.show_stall(str(b.id))
	elif mode == "bizfit":
		ui.show_fitout(str(b.id))
	elif mode == "bizplace":
		for id in Fitting.cost("workbench"):
			world.player.inv.add(id, int(Fitting.cost("workbench")[id]))
		begin_fit(str(b.id), "workbench")


## Choose where a piece of equipment goes in a room of the player's (PL1-10 stage 3): the same ghost, bar and
## controls as placing a building, one tile big. Starts on the free cell in front of the player.
func begin_fit(bid: String, kind: String) -> void:
	ui.hide_all()
	var b: Dictionary = world.buildings.get(bid, {})
	var front := world.player.pos + facing_vec()
	var at := Vector2i(floori(front.x), floori(front.y))
	if b.is_empty() or world.fitting.why_not(b, kind, at) != "":
		var cells: Array = world.fitting.floor_set(b).keys()
		cells.sort_custom(func(m: Vector2i, n: Vector2i): return m.y < n.y or (m.y == n.y and m.x < n.x))
		for c: Vector2i in cells:
			if world.fitting.why_not(b, kind, c) == "":
				at = c
				break
	placing = {"fit": kind, "building": bid, "at": at}
	paused = true
	move_to = Vector2.INF
	ui.show_placing(true)
	_update_ghost()


## Back to choosing after the deal window (Choose another place).
func resume_placement() -> void:
	ui.hide_all()
	paused = true
	ui.show_placing(true)
	if placing.has("farm"):
		ui.show_farm_price(true)
	_update_ghost()


func end_placement() -> void:
	placing = {}
	ghost.visible = false
	ui.show_placing(false)
	ui.show_farm_price(false)
	recenter()
	if not ui.modal():
		paused = false


func place_rect() -> Rect2i:
	if placing.has("farm"):
		return FarmPlots.rect_between(placing.a, placing.b)
	if placing.has("fit"):
		return Rect2i(placing.at, Vector2i.ONE)
	return Rect2i(placing.at, world.construction.footprint(placing.kind))


## Why the footprint cannot go where it is, "" if it can.
func place_refusal() -> String:
	if placing.has("farm"):
		return world.farm_plots.refusal(place_rect()) if placing.set else ""
	if placing.has("fit"):
		return world.fitting.why_not(world.buildings.get(str(placing.building), {}), str(placing.fit), placing.at)
	return world.construction.can_place(placing.kind, place_rect(), World.PLAYER, world.plot(str(placing.get("anchor", ""))))


func _update_ghost() -> void:
	var r := place_rect()
	var why := place_refusal()
	if placing.has("farm"):
		_update_farm_ghost(r, why)
		return
	if placing.has("fit"):
		ghost.show_at(r, Vector2i(-1, -1), why == "")
		var nm: String = Fitting.NAMES[placing.fit]
		ui.placing_text(("A %s here (%s)." % [nm, Fitting.cost_text(str(placing.fit))]) if why == "" else "A %s cannot go here: %s." % [nm, why], why == "")
		look_at_tile(Vector2(r.position) + Vector2(0.5, 0.5))
		return
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
	if placing.has("farm"):
		_move_farm_corner(cell)
		return
	var size := Vector2i.ONE if placing.has("fit") else world.construction.footprint(placing.kind)
	var at := cell - size / 2
	at.x = clampi(at.x, 0, map.w - size.x)
	at.y = clampi(at.y, 0, map.h - size.y)
	if at != placing.at:
		placing.at = at
		_update_ghost()


func move_ghost(d: Vector2i) -> void:
	if placing.has("farm"):
		_move_farm_corner(Vector2i(placing.b if placing.set else placing.a) + d)
		return
	var size := Vector2i.ONE if placing.has("fit") else world.construction.footprint(placing.kind)
	move_ghost_to(Vector2i(placing.at) + d + size / 2)


## Place: the deal for the ground, when the footprint may go there.
func confirm_placement() -> void:
	if placing.has("farm"):
		_confirm_farm()
		return
	if placing.has("fit"):
		var bid: String = placing.building
		var fwhy: String = world.fitting.place(world.buildings.get(bid, {}), str(placing.fit), placing.at)
		if fwhy != "":
			ui.message("You cannot put it here: %s." % fwhy)
			_update_ghost()
			return
		ui.message("%s fitted." % World.cap(Fitting.NAMES[placing.fit]))
		end_placement()
		ui.show_fitout(bid)
		return
	var why := place_refusal()
	if why != "":
		ui.message("You cannot build here: %s." % why)
		return
	ui.show_placing(false)
	ghost.visible = true
	ui.show_place_deal(placing.kind, place_rect(), str(placing.get("anchor", "")))


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
	if placing.has("farm"):
		return _farm_input(e)
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


# ---------------------------------------------------------------- placing farmland (FARM-09) ----
## Mark out farmland (owner Q11, 2026-10-21): the house-plot placing flow with an adjustable rectangle. First the
## green corner marker follows the pointer, the stick or the arrow keys; a press (a click, a finger down, E / A)
## sets the first corner; then dragging (the finger or the held mouse button, or the stick) moves the opposite
## corner and the rectangle grows or shrinks with it, green where the land office would let it, red with the
## reason where not. The lease (a week) and the price to buy, from the rectangle's area by the land office's
## rules (FarmPlots.terms), stand large in the middle of the screen and change as it moves. Place (E, Enter, A,
## a click inside the rectangle, or the Place button) opens the deal: lease, buy (each refused without the
## coins), choose again or cancel. Esc or B goes back to the first corner, then stops.
func begin_farm_placement() -> void:
	ui.hide_all()
	var front := world.player.pos + facing_vec() * 3.0
	var c := Vector2i(floori(front.x), floori(front.y))
	placing = {"farm": true, "a": c, "b": c, "set": false, "open": false}
	paused = true
	move_to = Vector2.INF
	ui.show_placing(true)
	ui.show_farm_price(true)
	_update_ghost()


func _move_farm_corner(cell: Vector2i) -> void:
	cell = Vector2i(clampi(cell.x, 0, map.w - 1), clampi(cell.y, 0, map.h - 1))
	if placing.set:
		if cell == placing.b:
			return
		placing.b = cell
	else:
		if cell == placing.a:
			return
		placing.a = cell
		placing.b = cell
	_update_ghost()


## The first corner goes down at `cell`; the opposite corner follows until it is set.
func _farm_first_corner(cell: Vector2i) -> void:
	placing.a = cell
	placing.b = cell
	placing.set = true
	placing.open = true
	_update_ghost()


func _update_farm_ghost(r: Rect2i, why: String) -> void:
	if not placing.set:
		ghost.show_at(r, Vector2i(-1, -1), true)
		ui.placing_text("Farmland: put the first corner where the plot should begin.", true)
		ui.farm_price_text("Choose the first corner", true)
		_farm_keep_in_view(r.position)
		return
	var t: Dictionary = world.farm_plots.terms(r)
	var gate: Vector2i = world.farm_plots.gate_for(r) if why == "" else Vector2i(-1, -1)
	ghost.show_at(r, gate, why == "")
	var fence: Dictionary = world.farm_plots.fence_cost({"x": r.position.x, "y": r.position.y, "w": r.size.x, "h": r.size.y, "farm": {}})
	ui.farm_price_text("%d x %d  (%d cells)\nLease: %d coins a week\nBuy: %d coins" % [r.size.x, r.size.y, r.size.x * r.size.y, int(t.rent), int(t.price)], why == "")
	ui.placing_text(("Farmland %s: its fence and gate will take %d planks and %d stone. You have %d coins." % [world.where(r), int(fence.plank), int(fence.stone), world.player.coins])
			if why == "" else "Farmland cannot go here: %s." % why, why == "")
	_farm_keep_in_view(Vector2i(placing.b))


## The view moves only when the corner being moved nears the screen's edge (the stick or the keys walking it
## away), so a finger or the mouse dragging the corner is never chased by the map moving under it.
func _farm_keep_in_view(cell: Vector2i) -> void:
	var at := get_canvas_transform() * ((Vector2(cell) + Vector2(0.5, 0.5)) * T)
	if not get_viewport().get_visible_rect().grow(-96.0).has_point(at):
		look_at_tile(Vector2(cell) + Vector2(0.5, 0.5))


## Screenshot scenes for FARM-09: a 6x5 rectangle being marked out near the start (farm_place), one dragged over a
## house (farm_place_bad), the deal window (farm_deal), and a leased plot fenced (farm_fenced).
func _farm_plot_shot(mode: String) -> void:
	world.player.coins = 60
	var sp = map.data.spawns.player
	var r: Rect2i = world.farm_plots.find_ground(Vector2i(6, 5), Vector2i(int(sp[0]), int(sp[1])), 0)
	world.player.pos = Vector2(r.position + Vector2i(2, -1)) + Vector2(0.5, 0.5)
	follow_at = _in_view(world.player.pos * T)
	if mode == "farm_fenced":
		var p: Dictionary = world.farm_plots.claim(r, World.PLAYER, true)
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				var o: Dictionary = world.farm.obstacle(Vector2i(x, y))
				if not o.is_empty() and o.kind == "plant":
					world.farm.clear_plant(o.ref)
		world.player.inv.add("plank", 6)
		world.player.inv.add("stone", 2)
		world.farm_plots.build_fence(p, World.PLAYER, [world.player.inv])
		world.player.stamina = 1000.0
		for x in range(r.position.x + 1, r.end.x - 1):
			world.farm.till(Vector2i(x, r.position.y + 1), world.player)
		_apply_world_changes()
		return
	begin_farm_placement()
	_move_farm_corner(r.position)
	_farm_first_corner(r.position)
	if mode == "farm_place_bad":
		_move_farm_corner(Vector2i(int(world.buildings["b5"].x) + 2, int(world.buildings["b5"].y) + 2))
	else:
		_move_farm_corner(r.end - Vector2i.ONE)
	placing.open = false
	if mode == "farm_deal":
		_confirm_farm()


## Place: set the first corner, or open the deal for a valid rectangle.
func _confirm_farm() -> void:
	if not placing.set:
		_farm_first_corner(placing.a)
		return
	placing.open = false
	var why := place_refusal()
	if why != "":
		ui.message("You cannot have farmland here: %s." % why)
		return
	ui.show_placing(false)
	ui.show_farm_price(false)
	ghost.visible = true
	ui.show_farm_deal(place_rect())


## Input while marking out farmland; true when handled. Two fingers still pan and zoom (the press and the drag
## are left to the touch bookkeeping when more than one finger is down).
func _farm_input(e: InputEvent) -> bool:
	if e is InputEventMouseMotion and e.device != InputEvent.DEVICE_ID_EMULATION and not mid_drag and touch_points.is_empty():
		if not placing.set or placing.open or (e.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_move_farm_corner(_cell_at(e.position))
		return true
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.device != InputEvent.DEVICE_ID_EMULATION:
		if ui.blocks(e.position):
			return false
		var cell := _cell_at(e.position)
		if e.pressed:
			if placing.set and placing.open:
				_move_farm_corner(cell)
				placing.open = false          # a second click sets the opposite corner
			elif placing.set and place_rect().has_point(cell) and place_rect().size != Vector2i.ONE:
				_confirm_farm()               # a click on the rectangle places it, as a building's footprint
			else:
				_farm_first_corner(cell)
		elif placing.set and placing.open and cell != Vector2i(placing.a):
			_move_farm_corner(cell)
			placing.open = false              # released after a drag: the opposite corner is set
		return true
	if e is InputEventScreenTouch:
		if not e.pressed:
			placing.open = false              # the finger lifted: the opposite corner stays where it was dragged
		elif touch_points.is_empty() and not multi_touch and not ui.blocks(e.position):
			_farm_first_corner(_cell_at(e.position))      # a finger down: the first corner; dragging moves the other
		return false                          # the touch bookkeeping still sees it (pinch and pan)
	if e is InputEventScreenDrag and touch_points.size() <= 1 and not multi_touch and placing.set:
		_move_farm_corner(_cell_at(e.position))
		return true
	if e.is_action_pressed("interact") or (e is InputEventKey and e.is_action_pressed("ui_accept")) or (e is InputEventJoypadButton and e.is_action_pressed("ui_accept")):
		_confirm_farm()
		return true
	if e.is_action_pressed("pause") or e.is_action_pressed("ui_cancel"):
		if placing.set:
			placing.set = false
			placing.open = false
			placing.b = placing.a
			_update_ghost()
		else:
			end_placement()
			ui.message("Farmland put off.")
		return true
	return false


func _cell_at(screen_pos: Vector2) -> Vector2i:
	var wp := (get_canvas_transform().affine_inverse() * screen_pos) / T
	return Vector2i(floori(wp.x), floori(wp.y))


# ---------------------------------------------------------------- touch ----------------------
func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventJoypadMotion and (e.axis == JOY_AXIS_TRIGGER_LEFT or e.axis == JOY_AXIS_TRIGGER_RIGHT):
		var down: bool = e.axis_value > 0.6
		if down and not trigger_held.get(e.axis, false):
			if ui.modal():
				ui.cycle_focus(1 if e.axis == JOY_AXIS_TRIGGER_RIGHT else -1)    # in a window: step through its buttons
			elif e.axis == JOY_AXIS_TRIGGER_LEFT and world != null and running:
				toggle_sprint()                                                  # in play: LT turns sprint on or off (B8-027)
		trigger_held[e.axis] = down
		return
	if world == null:
		return
	if _placing_input(e):
		return
	# B8-011: B (pad), Esc (keyboard) and a right-click (mouse) stop harvesting at once; a tap does (touch, in _tap)
	if running and not ui.modal() and (not action.is_empty() or not gather.is_empty()):
		if e.is_action_pressed("cancel") or e.is_action_pressed("pause") \
				or (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT):
			cancel_action("You stop.")
			get_viewport().set_input_as_handled()
			return
	if not ui.modal() and running and action.is_empty():
		if e.is_action_pressed("next_target"):
			cycle_target(1)
		elif e.is_action_pressed("prev_target"):
			cycle_target(-1)
		elif e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_TAB and target_options.size() > 1:
			tab_cycled = Engine.get_process_frames()       # Tab is the Pack's key too: with a choice to make it chooses
			cycle_target(1)
		elif e.is_action_pressed("sprint") and bool(GameData.b("sprint_toggle")):
			toggle_sprint()
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
	if e is InputEventJoypadButton and e.is_action_pressed("ui_cancel") and ui.modal() and not ui.panel_kind in ["title", "origin", "death"]:
		ui.go_back()
	if e.is_action_pressed("zoom_in"):
		_set_zoom(camera.zoom.x * 1.2)
	if e.is_action_pressed("zoom_out"):
		_set_zoom(camera.zoom.x / 1.2)
	if e.is_action_pressed("pause"):
		if ui.modal():
			ui.go_back()
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


## A camera position (pixels) the view may take. The world goes on past the village in every
## direction (the overworld), so there is nothing to keep it over.
func _in_view(at: Vector2) -> Vector2:
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


## A controller was connected or disconnected: switch to its controls, or back to touch on a phone.
func _on_joy_connection(device: int, connected: bool) -> void:
	if connected and not is_pad(Input.get_joy_name(device)):
		return                            # a phone's fingerprint reader or keyboard, not a controller
	var s := scheme
	if connected:
		s = "gamepad"
	elif _real_pads().is_empty() and scheme == "gamepad":
		s = "touch" if settings.phone else "kbm"
	if s != scheme:
		scheme = s
		ui.set_scheme(s)
		ui.message("Controller connected: touch buttons hidden." if connected else "Controller disconnected.", 4.0)


## Many Android phones report their fingerprint reader (and some keyboards and styluses) as a joypad: those
## never count as a controller, so they cannot hide the touch buttons. An unnamed device counts.
const NOT_PADS := ["fpc", "fingerprint", "goodix", "uinput", "gf_input", "keyboard", "touch", "mouse", "stylus", "pen"]


static func is_pad(joy_name: String) -> bool:
	var n := joy_name.to_lower()
	for w in NOT_PADS:
		if n.contains(w):
			return false
	return true


## The connected devices that are real controllers.
func _real_pads() -> Array:
	return Input.get_connected_joypads().filter(func(d): return is_pad(Input.get_joy_name(d)))


## Which controls are in use, from the latest input: the HUD follows (touch buttons, prompts).
func _input(e: InputEvent) -> void:
	var s := scheme
	if e is InputEventScreenTouch or e is InputEventScreenDrag:
		s = "touch"
	elif (e is InputEventJoypadButton or (e is InputEventJoypadMotion and absf(e.axis_value) > 0.5)) and is_pad(Input.get_joy_name(e.device)):
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
	if furn.get("kind", "") == "sit":
		stand_up()                     # a tap stands the seated player up (PL2-013)
		return
	if not action.is_empty():
		cancel_action("You stop.")     # a tap while working stops it (B8-011)
		return
	var wpos := (get_canvas_transform().affine_inverse() * screen_pos) / T
	if _tap_portal(wpos) or _tap_below(wpos):
		return                            # MIN-A: the adit tapped, or a tap below the surface
	var pile := _loot_at(wpos)
	if pile != Vector2.INF and _creature_at(wpos) == null:
		# a tapped pile (a carcass, a dropped bag): walk up to it and take it, in any mode (PL2-004)
		chase = null
		talk_to = null
		stop_gather("")
		reach_to = pile
		move_to = pile if pile.distance_to(world.player.pos) > 1.2 else Vector2.INF
		if move_to == Vector2.INF:
			_reach_step()
		return
	if gather_mode:
		var hit := _resource_tap(wpos)
		if hit.is_empty():
			_gain("Nothing to gather there")
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
	var d := world.to_dict()
	d["meta"] = _save_meta()
	for k in save_extra:
		if not d.has(k):
			d[k] = save_extra[k]
	var r := SaveStore.write_text(save_path, JSON.stringify(d, "", true, true), true)          # full precision: times and positions reload exactly
	if not r.ok:
		if show or not save_failing:
			ui.message("Could not save: %s. Your last save is unchanged." % r.reason, 8.0)
		save_failing = true
		return false
	save_failing = false
	_update_linked_copy()
	if show:
		ui.message("Saved.")
	return true


## Export a copy of the save to `target` (a file the player chose; SAVE-05). A running game saves first.
func export_save_to(target: String) -> Dictionary:
	if running and world != null:
		save_game(false)
	return SaveTransfer.export_save(save_path, target)


## Import the save file at `source` as this game's save (SaveTransfer.import_save: backed up, migrated,
## validated, then swapped in atomically; the save it replaces is kept in user://save_backups/), then
## continue it. Nothing changes on failure.
func import_save_from(source: String) -> Dictionary:
	if running and world != null:
		save_game(false)
	var r := SaveTransfer.import_save(source, save_path, VillageMap.load_default())
	if r.ok:
		save_blocked = ""
		running = false
		continue_game()
	return r


## The copy of the save kept up to date outside the game (SAVE-05): a file the player chose once with the
## file picker; every save also writes it. A failure says so once and leaves the save itself as it is.
var linked_copy_failed := false


func _update_linked_copy() -> void:
	if settings.save_copy == "":
		return
	var r := SaveTransfer.export_save(save_path, settings.save_copy)
	if not r.ok and not linked_copy_failed:
		ui.message("Your save is fine, but its copy outside the game could not be updated: %s. Choose the copy again in Settings, Saves." % r.reason, 10.0)
	linked_copy_failed = not r.ok


## What identifies a save apart from the world (PL1-11, portable saves; SAVE-02): a world id made once per
## new game and kept through every save of it, copy and import, independent of build numbers; when it was
## made and last saved, play time, the device that saved it, and the builds it has been played in. A cloud copy is compared by these (same world? which is newer? longer played?) and
## nothing in the save depends on the device: paths are user:// and the world regenerates from its seed.
func _save_meta() -> Dictionary:
	if not save_meta.has("save_id"):
		save_meta["save_id"] = Marshalls.raw_to_base64(Crypto.new().generate_random_bytes(12)).replace("/", "_").replace("+", "-")
		save_meta["created"] = int(Time.get_unix_time_from_system())
	save_meta["saved_at"] = int(Time.get_unix_time_from_system())
	save_meta["play_seconds"] = int(float(save_meta.get("play_seconds", 0.0)))
	save_meta["platform"] = OS.get_name()
	var build := str(ProjectSettings.get_setting("application/config/version", ""))
	if build == "":
		build = "dev"                                 # a development run (release.yml stamps the build number)
	save_meta["build"] = build
	var builds: Array = save_meta.get("builds", [])
	if builds.is_empty() or str(builds[-1]) != build:
		builds.append(build)                          # the builds this world has been played in (SAVE-02)
	save_meta["builds"] = builds.slice(maxi(0, builds.size() - 20))
	save_meta["character"] = world.player.name
	return save_meta.duplicate()


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
## Rest (the bed, the chest, the house door). Inside the player's own home with a bed, they lie in it for
## the night and wake beside it (PL2-013); anywhere else it is the plain rest.
func rest() -> void:
	var bed := _own_bed()
	if bed.is_empty() or not furn.is_empty():
		_rest_now()
		return
	lie_down(bed)


## The bed spot of the player's own home nearest to them, {} when they are not inside it or it has none.
func _own_bed() -> Dictionary:
	var p := world.player
	if p.home == "" or world.place_of(p.pos) != p.home or not world.interiors.has(p.home):
		return {}
	var best := {}
	var bd := INF
	for sp in world.interiors[p.home].spots:
		if sp.kind == "bed":
			var d := (Vector2(int(sp.at[0]), int(sp.at[1])) + Vector2(0.5, 0.5)).distance_to(p.pos)
			if d < bd:
				bd = d
				best = sp
	return best


func _cell_centre(c: Array) -> Vector2:
	return Vector2(int(c[0]), int(c[1])) + Vector2(0.5, 0.5)


## Lie in the bed: the player is drawn on it (ActorSprite.lie) while the rest runs, then wakes at its side.
func lie_down(bed: Dictionary) -> void:
	var p := world.player
	furn = {"kind": "lie", "spot": bed, "stand": _cell_centre(bed.use)}
	p.pos = _cell_centre(bed.at)
	start_action("Sleeping", 3.0, func():
		stand_up()
		_rest_now(), "idle")


## Sit on a chair (spot kind "chair", Furniture): the player is drawn seated on it until any input.
func sit_down(spot: Dictionary) -> void:
	if not furn.is_empty():
		return
	var p := world.player
	furn = {"kind": "sit", "spot": spot, "stand": _cell_centre(spot.use)}
	p.pos = _cell_centre(spot.at)
	move_to = Vector2.INF
	reach_to = Vector2.INF
	chase = null
	talk_to = null
	sprinting = false
	player_sprite.play("idle")
	ui.message("You sit down. Move or press anything to stand up.")


## Up again, beside the furniture (the cell it is used from).
func stand_up() -> void:
	if furn.is_empty():
		return
	world.player.pos = furn.stand
	furn = {}
	player_sprite.stand()


## Seated: a movement, an action key, a stick or a button stands the player up (a tap does in _tap).
func _seated_step() -> void:
	var woke := Input.get_vector("move_left", "move_right", "move_up", "move_down").length() > 0.1
	for a in InputMap.get_actions():
		if not str(a).begins_with("ui_") and Input.is_action_just_pressed(a):
			woke = true
	if woke:
		stand_up()
		return
	ui.prompt("Seated: move or press anything to stand up")


## Draw the player seated or lying while on furniture.
func _sync_player_pose() -> void:
	var p := world.player
	if furn.is_empty() or not p.alive:
		player_sprite.stand()
		return
	var sp: Dictionary = furn.spot
	var at := _cell_centre(sp.at) * T
	if furn.kind == "sit":
		player_sprite.sit(at, Furniture.face_dir(sp))
	else:
		var head := str(sp.get("head", "left"))
		player_sprite.lie(at, head, _blanket(int(sp.get("tile", -1)), head))


func _rest_now() -> void:
	var p := world.player
	var h := world.hour()
	var until := 6.0 if h < 6.0 else 30.0
	var night := h >= 18.0 or h < 6.0
	var mins := (until - h) * 60.0 if night else float(GameData.b("rest").day_minutes)
	var steps := int(mins / float(GameData.b("game_minutes_per_second")) / 0.5)
	for i in steps:
		world.update(0.5)
	world.rest_recover(p, mins, night)        # the one recovery model (PAR-03)
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


## Screenshot helper: the player beside a seam (or a mature tree), the tool in hand, the work begun,
## the swing held at `frame` (0-2).
func _swing_panel(mining: bool, frame: int) -> void:
	var p := world.player
	var dep := world.nearest_deposit(Vector2i(p.pos), ["stone", "iron_ore", "coal"])
	var cell := Vector2i(int(dep.x), int(dep.y)) if mining else Vector2i.ZERO
	if not mining:
		for tr in world.trees:
			if tr.state == "grown":
				cell = Vector2i(int(tr.x), int(tr.y))
				break
	var tool_id := "rusty_pickaxe" if mining else "axe"
	p.inv.add(tool_id, 1)
	p.tool = tool_id
	var c: Vector2i = world.brain.beside(cell, cell + Vector2i(0, 1))
	p.pos = Vector2(c) + Vector2(0.5, 0.5)
	follow_at = _in_view(p.pos * T)
	player_sprite.face(Vector2(cell) + Vector2(0.5, 0.5) - p.pos)
	_find_target()
	_use()
	player_sprite.speed_scale = 0.0
	player_sprite.t = float(frame) * 0.16 + 0.01


## HOUSE-10 screenshots: the household of b_v1_house adds the small room beside its house (placed and supplied
## with the calls the game uses); one of the family lies in its bed; the player stands at its door or inside.
func _room_shot(inside: bool) -> void:
	var c := world.construction
	for hh in world.households:
		if str(hh.home) != "b_v1_house":
			continue
		var ref := World.hh_ref(int(hh.id))
		var house: Dictionary = world.buildings["b_v1_house"]
		world.property.survey_under(house)
		var p := c.place("room", c.find_module_slot("room", house, ref), ref, false, house)
		if p.is_empty():
			print("room shot: refused (%s)" % c.why)
			return
		var bag := Inventory.new()
		for id in p.site.need:
			bag.add(str(id), int(p.site.need[id]))
		world.deliver(p, bag)
		var room: Dictionary = world.property.building_on(p)
		var sp: Dictionary = world.interiors[str(room.id)].spots[1]
		var sleeper: NPC = world.npc(int(hh.members[0]))
		sleeper.pos = Vector2(int(sp.at[0]) + int(room.x), int(sp.at[1]) + int(room.y)) + Vector2(0.5, 0.5)
		sleeper.anim = "sleep"
		var door := world.building_door(str(room.id))
		world.player.pos = Vector2(door) + (Vector2(0.5, -0.5) if inside else Vector2(1.5, 1.5))
		follow_at = _in_view(world.player.pos * T)
		camera.position = follow_at
		return


## PL2-015 screenshots: the player holds a piece of open ground near the start and has worked it with the same
## calls the game uses (till, sow, grow by the clock, fence a pen, buy stock). `kind`: farm_tilled (an L-shaped
## field of tilled soil), farm_growing (the field sown with four crops, some ripe) or farm_pen (two pens with
## animals beside the field).
func _farm_shot(kind: String) -> void:
	var p := world.player
	p.coins = 3000
	var rect := world.construction.find_ground("house", Vector2i(floori(p.pos.x), floori(p.pos.y)), World.PLAYER)
	var pl: Dictionary = world.property.claim(rect, World.PLAYER, false)
	if pl.is_empty():
		print("farm shot: no ground (%s)" % world.property.why)
		return
	p.inv.add("plough")
	for s in ["wheat_seed", "carrot_seed", "potato_seed", "herb_seed"]:
		p.inv.add(s, 40)
	p.inv.add("plank", 60)
	var crops := ["wheat", "carrot", "potato", "herb"]
	for j in range(1, 7):
		for i in range(1, 8):
			if i > 4 and j > 3:
				continue                                   # an L shape
			p.stamina = 100.0
			var c := Vector2i(int(pl.x) + i, int(pl.y) + j)
			world.farm.till(c, p)
			if kind != "farm_tilled":
				world.farm.sow(c, crops[(j - 1) % crops.size()], p)
	if kind != "farm_tilled":
		for h in 30:                                       # about a day and a half of spring: the quick crops ripen
			world.minutes += 60.0
			world.farm.hour()
		world.farm.show_all()
	var last := pl
	if kind == "farm_pen":
		for k in ["chicken", "sheep"]:                    # each pen on a parcel of its own beside the field
			var next: Dictionary = world.property.claim(world.construction.find_ground("house", Vector2i(int(last.x) + 4, int(last.y) + 5), World.PLAYER), World.PLAYER, false)
			if next.is_empty():
				print("farm shot: no ground for the %s pen" % k)
				continue
			last = next
			var r := Rect2i(Vector2i(int(next.x) + 1, int(next.y) + 2), Vector2i(Farming.cfg().pens[k][0], Farming.cfg().pens[k][1]))
			var pen: Dictionary = world.farm.build_pen(k, r, p)
			if pen.is_empty():
				print("farm shot: %s pen refused: %s" % [k, world.farm.pen_why])
				continue
			for i in 3:
				var a: Animal = world.fauna.spawn(pen.id, k, "f" if i != 1 else "m", null)
				a.born = world.minutes - 6.0 * 1440.0
			pen.trough = 6
			pen.products = {"egg": 2} if k == "chicken" else {"wool": 1}
	p.pos = Vector2(float(pl.x) + 4.5, float(pl.y) + float(pl.h) + 0.5)
	var mid := (Vector2(float(pl.x), float(pl.y)) + Vector2(float(last.x), float(last.y))) / 2.0 + Vector2(4.5, 5.0)
	follow_at = _in_view(mid * T)
	camera.position = follow_at


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
	ui.message("Gather: tap a seam, a tree, a ripe field, a flower, a berry bush or game; you gather it until it runs out. Tap Gather again to stop."
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
	var hp := Vector2(ResourceNodes.cell_of(world, d, hit.ref)) + Vector2(0.5, 0.5)
	if world.place_of(world.player.pos) != world.place_of(hp) and not world.reaches(world.player.pos, hp):
		stop_gather("")
		ui.message("A wall is in the way.")          # inside to outside or the reverse (PL2-011)
		return
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
	if str(d.match.kind) in ["field", "plant"]:
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
	if str(d.match.kind) == "plant":
		return Vector2(cell) + Vector2(0.5, 0.5)          # plants are walked on: pick them standing there
	return Vector2(world.brain.beside(cell, Vector2i(floori(p.pos.x), floori(p.pos.y)), world.player_level)) + Vector2(0.5, 0.5)


func _gather_target(d: Dictionary, ref) -> Dictionary:
	match str(d.match.kind):
		"deposit":
			return {"kind": "deposit", "dep": ref, "label": ""}
		"tree":
			return {"kind": "tree", "tree": ref, "label": ""}
		"field":
			return {"kind": "field", "field": ref, "label": ""}
		"plant":
			return {"kind": "plant", "plant": ref, "label": ""}
	return {}


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


# ---------------------------------------------------------------- underground (MIN-A) --------
## One LevelView per level map (docs/build17/MIN_A_ARCHITECTURE.md), between the surface's tiles and the characters,
## hidden until the player goes below. A seam below that is worked out is redrawn on its level.
func _build_levels() -> void:
	level_views.clear()
	level_alpha = 1.0 if world.player_level != 0 else 0.0
	level_shown = world.player_level
	if world.underground == null:
		return
	for lm: LevelMap in world.underground.maps:
		var lv := LevelView.new()
		lv.name = "level_" + lm.id
		add_child(lv)
		move_child(lv, ow_view.get_index() + 1)
		lv.setup_level(view, world, lm, world.underground.specs[lm.id])
		lv.visible = false
		level_views[lm.id] = lv
	world.level_tile_changed.connect(_on_level_tile_changed)
	_sync_levels(0.0)


func _on_level_tile_changed(level: int, cell: Vector2i, value: int) -> void:
	var lm := world.underground.map_at(level, cell)
	if lm != null and level_views.has(lm.id):
		level_views[lm.id].set_seam(cell, value)


## The player crosses a portal when walking into its door from its stand (`v` the way they move), or when a tapped
## portal's stand is reached (`v` zero). The route, the target and gathering stop: the other side is another map.
func _through_portal(v: Vector2) -> void:
	if v.length() < 0.1:
		if portal_goal.is_empty() or move_to != Vector2.INF:
			return
		var e := portal_goal
		portal_goal = {}
		if int(e.level) != world.player_level or Vector2i(floori(world.player.pos.x), floori(world.player.pos.y)) != e.stand:
			return
		v = Vector2(e.door - e.stand)
	var r := world.player_through(v)
	if r.is_empty():
		return
	if r.has("refused"):
		if Engine.get_process_frames() - portal_said > 90:
			ui.message(str(r.refused))
		portal_said = Engine.get_process_frames()
		return
	move_to = Vector2.INF
	walk_goal = Vector2i(-1, -1)
	walk_path = PackedVector2Array()
	portal_goal = {}
	chase = null
	talk_to = null
	reach_to = Vector2.INF
	target = {}
	if not gather.is_empty():
		stop_gather("")
	if cam_free:
		recenter()


## A tap on a portal's door (the adit's mouth from either side): walk to its stand and go through. True if it was.
func _tap_portal(wpos: Vector2) -> bool:
	if world.underground == null:
		return false
	var e := world.underground.portal_door(world.player_level, Vector2i(floori(wpos.x), floori(wpos.y)))
	if e.is_empty():
		return false
	chase = null
	talk_to = null
	reach_to = Vector2.INF
	portal_goal = e
	move_to = Vector2(e.stand) + Vector2(0.5, 0.5)
	return true


## A tap below the surface: a pile on the player's level is walked to and taken, a seam beside the player is worked,
## anywhere else is walked to. Nobody else is below yet, so there is no one to talk to or strike. True below.
func _tap_below(wpos: Vector2) -> bool:
	if world.player_level == 0:
		return false
	chase = null
	talk_to = null
	reach_to = Vector2.INF
	portal_goal = {}
	if gather_mode:
		var hit := ResourceNodes.node_at(world, Vector2i(floori(wpos.x), floori(wpos.y)), true)     # the level's seams
		if hit.is_empty():
			_gain("Nothing to gather there")
		else:
			select_resource(hit, true)
		return true
	var pile := _loot_at(wpos)
	if pile != Vector2.INF:
		reach_to = pile
		move_to = pile if pile.distance_to(world.player.pos) > 1.2 else Vector2.INF
		if move_to == Vector2.INF:
			_reach_step()
		return true
	var who := world.present(wpos, 0.8)          # a villager working below (World.present sees the tapped point's level)
	if not who.is_empty() and (who[0] as NPC).depth == world.player_level:
		talk_to = who[0]                         # walk up to them and talk
		return true
	if wpos.distance_to(world.player.pos) < 1.8:
		player_sprite.face(wpos - world.player.pos)
		_find_target()
		if not target.is_empty():
			interact()
			return true
	move_to = wpos
	return true


## The target list below the surface: piles and seams on the player's level only (the same seam target as above
## ground, so Use mines it by World.work_mine, PAR-01).
func _find_target_below() -> void:
	var p := world.player
	var probe := p.pos + facing_vec() * 0.9
	var cands: Array = []
	for n: NPC in world.present(p.pos, 2.5):        # villagers working on this level (World.present: one level)
		if n.pos.distance_to(probe) < 1.5:
			cands.append({"kind": "npc", "npc": n, "label": ("%s is asleep" % _who(n)) if world.asleep(n) else "Talk to %s" % _who(n)})
	for i in world.loot.size():
		var l: Dictionary = world.loot[i]
		if World.level_of(l) != world.player_level:
			continue
		if l.pos.distance_to(probe) < 1.5 or l.pos.distance_to(p.pos) < 1.2:
			var from: String = l.from
			var what := _loot_text(l)
			cands.append({"kind": "loot", "i": i, "label": ("Take %s from %s" % [what, from]) if from.begins_with("the ") and what != "" else ("Take what is left of %s" % from) if from.begins_with("the ") else ("Search %s's belongings" % from)})
	var c := Vector2i(floori(probe.x), floori(probe.y))
	for dc in [Vector2i.ZERO, Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1)]:
		var dep := world.deposit_at(c + dc, world.player_level)
		if not dep.is_empty() and int(dep.amount) > 0:
			cands.push_front({"kind": "deposit", "dep": dep, "label": ("Mine %s (%d left)" % [GameData.item_name(dep.ore).to_lower(), int(dep.amount)]) if p.tool_of("pickaxe") != ""
					else "%s seam" % GameData.item_name(dep.ore) + ": requires a pickaxe (the smith sells them)"})
			break
	talk_alt = {}
	target_options = cands
	target = cands[0] if not cands.is_empty() else {}
	var passing: bool = walking and target.get("kind", "") == "deposit"
	ui.prompt("" if passing or not gather.is_empty() else str(target.get("label", "")))


## Fade between the surface and the level below over RoofFade.FADE_TIME, as a roof lifts: the level's view in, and
## the surface's tiles, trees, roofs, markers and everyone on it out (the player never fades). Piles show on their
## own level only.
func _sync_levels(delta: float) -> void:
	if level_views.is_empty():
		return
	if world.player_level != 0:
		level_shown = world.player_level
	var goal := 1.0 if world.player_level != 0 else 0.0
	var was := level_alpha
	level_alpha = move_toward(level_alpha, goal, delta / RoofFade.FADE_TIME) if delta > 0.0 else goal
	for lv: LevelView in level_views.values():
		lv.visible = level_alpha > 0.0 and lv.level_map.level == level_shown
		lv.modulate.a = level_alpha
		if lv.visible:
			lv.follow(world.player.pos)
	for i in loot_nodes.size():
		if i < world.loot.size():
			loot_nodes[i].visible = World.level_of(world.loot[i]) == world.player_level
	# villagers show on their own level: those on the surface fade with it, those below with the level shown
	var surf := 1.0 - level_alpha
	for n: NPC in world.npcs:
		var s: ActorSprite = sprites.get(n.id)
		if s != null:
			s.modulate.a = surf if n.depth == 0 else (level_alpha if n.depth == level_shown else 0.0)
		var b = bubbles.get(n.id)
		if b != null and is_instance_valid(b):
			b.visible = n.depth == world.player_level
	if level_alpha == 0.0 and was == 0.0:
		return
	var fade: Array = [view, ow_view, above, blood_layer, tree_view]
	fade.append_array(view.sorted_of.values())
	fade.append_array(animal_sprites.values())
	fade.append_array(cart_sprites.values())
	fade.append_array(house_signs.values())
	for node in fade:
		if is_instance_valid(node):
			(node as CanvasItem).modulate.a = surf
