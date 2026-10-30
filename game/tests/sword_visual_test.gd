extends SceneTree
## GP-SWORD-VIS (owner, 2026-10-27: "IF MY CHARACTER IS USING A WEAPON, I WANT TO SEE THE ACTUAL WEAPON BEING USED"). Drives
## the real game scene: the start kit's sword wielded through the Pack's path is carried in the hand in all eight
## directions, swung as a slash (attached at the hand, pointing the way the striker faces as the blow lands, in front of or
## behind the body by the facing), plays through while walking and returns to the carried pose; bare hands draw no sword;
## the blow lands on the strike's striking frame; villagers' and other players' blows are strikes with what they carry,
## timed to their blows. View only: damage, reach and timing numbers are untouched. Run headless:
##   godot --headless --path game --script res://tests/sword_visual_test.gd

var main
var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = "user://test_saves/sword_visual_test/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	main.new_game()
	main.paused = true
	test_icons()
	test_bare_hands()
	test_carried_and_swung()
	test_walking_keeps_the_blow()
	test_timing()
	test_npcs()
	test_remote()
	print("sword_visual_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## The facing of direction index `d` on screen (0 = south).
func facing(d: int) -> Vector2:
	var a := float(d) * TAU / 8.0
	return Vector2(sin(a), cos(a))


## Where an icon's blade points on screen (its head, ActorSprite.ICON_HEAD in the image, through the icon's transform).
func blade(icon: Sprite2D) -> Vector2:
	var head := Vector2.from_angle(deg_to_rad(ActorSprite.ICON_HEAD))
	return icon.transform.basis_xform(head).normalized()


func step_sprite(s: ActorSprite, dt: float) -> void:
	s._process(dt)


func test_icons() -> void:
	var missing := []
	var n := 0
	for id in GameData.items:
		if str(GameData.item(str(id)).get("type", "")) == "weapon":
			n += 1
			if not ResourceLoader.exists("res://assets/icons/%s.png" % id):
				missing.append(id)
	check(n > 1900 and missing.is_empty(), "every weapon (%d) has the icon it is drawn with %s" % [n, missing.slice(0, 5)])


func test_bare_hands() -> void:
	var p: PlayerState = main.world.player
	var s: ActorSprite = main.player_sprite
	check(p.inv.has("rusty_sword") and p.weapon == "", "the start kit's sword comes in the pack, not in the hand")
	main._process(0.0)
	check(s.weapon_item == "", "so no sword is drawn")
	main.swing = Combat.new()
	main.attack()
	check(s.anim == "swing" and s.striking and s.tool_item == "", "a blow bare-handed is a strike with nothing in hand (not the sheet's own small sword)")
	step_sprite(s, 0.2)
	check(s.tool_icon == null or not s.tool_icon.visible, "and no weapon is drawn in it")
	check(main.bare_hint_said, "the game says once that the sword is in the pack, not in the hand")
	main.swing = Combat.new()
	step_sprite(s, 1.0)


func test_carried_and_swung() -> void:
	var p: PlayerState = main.world.player
	var s: ActorSprite = main.player_sprite
	check(main.world.player_equip("rusty_sword") and p.weapon == "rusty_sword", "wielded from the Pack (World.player_equip)")
	main._process(0.0)
	check(s.weapon_item == "rusty_sword", "the sword in hand is the one drawn")
	var carried := 0
	for d in 8:
		for a in ["idle", "walk"]:
			s.dir = d
			s.play(a)
			step_sprite(s, 0.05)
			if s.weapon_icon.visible and s.weapon_icon.texture != null and s.weapon_icon.position.length() <= 6.0:
				carried += 1
	check(carried == 16, "carried at the hand standing and walking in all eight directions (%d of 16)" % carried)
	var at_hand := 0
	var aimed := 0
	var layered := 0
	var back := 0
	var notes := []
	for d in 8:
		s.dir = d
		main.swing = Combat.new()
		main.attack()
		check(d > 0 or (s.striking and s.tool_item == "rusty_sword"), "a blow strikes with the sword in hand")
		for f in 3:
			s.t = float(f) * 0.16 + 0.01
			step_sprite(s, 0.0)
			var ic: Sprite2D = s.tool_icon
			if ic.visible and ic.texture != null and not s.weapon_icon.visible and absf(ic.position.x) <= 4.0 and ic.position.y >= -6.0 and ic.position.y <= -1.0:
				at_hand += 1
			if f == ActorSprite.STRIKE_FRAME:
				var dot := blade(ic).dot(facing(d))
				if dot >= cos(deg_to_rad(50.0)):
					aimed += 1
				else:
					notes.append("dir %d points %s (%.2f)" % [d, blade(ic), dot])
				if ic.show_behind_parent == (d in [3, 4, 5]):
					layered += 1
		s.t = 0.6
		step_sprite(s, 0.05)
		if s.anim == "idle" and not s.striking and not s.tool_icon.visible and s.weapon_icon.visible:
			back += 1
	check(at_hand == 24, "every frame of the swing in every direction draws the sword at the hand (%d of 24)" % at_hand)
	check(aimed == 8, "as the blow lands the blade points the way the striker faces, in all eight directions %s" % [notes])
	check(layered == 8, "facing away the blade ahead is drawn behind the body, otherwise in front (%d of 8)" % layered)
	check(back == 8, "after the blow the sword is carried again (%d of 8)" % back)
	main.swing = Combat.new()


func test_walking_keeps_the_blow() -> void:
	var s: ActorSprite = main.player_sprite
	main.paused = false
	main.swing = Combat.new()
	main.action = {}
	s.play("idle")
	s.dir = 2
	main.attack()
	Input.action_press("move_right")
	for i in 5:
		main._player_step(0.02)
		step_sprite(s, 0.02)
	var mid: bool = s.striking and s.anim == "swing" and s.tool_icon.visible
	for i in 30:
		main._player_step(0.02)
		step_sprite(s, 0.02)
	Input.action_release("move_right")
	check(mid, "a blow begun plays through while walking (it used to be cut off by the walk)")
	check(not s.striking and s.anim == "walk", "and the walk goes on after it")
	main._player_step(0.02)
	main.paused = true
	main.swing = Combat.new()


func test_timing() -> void:
	var s: ActorSprite = main.player_sprite
	check(is_equal_approx(ActorSprite.strike_lead(), float(Combat.cfg().windup)), "the striking frame comes when the blow lands (%.2f s after the press, Combat windup %.2f s)" % [ActorSprite.strike_lead(), float(Combat.cfg().windup)])
	var striking_cols: Array = ActorSprite.ANIMS.swing[0]
	var ok := 0
	for dt in [1.0 / 60.0, 1.0 / 30.0, 0.05]:
		main.swing = Combat.new()
		s.dir = 0
		main.attack()
		var col := -1
		for i in 60:
			var phase: String = main.swing.phase
			main._swing_step(dt)              # the game's frame: main first, then its sprites
			step_sprite(s, dt)
			if phase == "windup" and main.swing.phase == "recovery":
				col = s.frame % 29
				break
		if col == int(striking_cols[ActorSprite.STRIKE_FRAME]):
			ok += 1
		else:
			print("     dt %.3f: the blow landed on sheet column %d" % [dt, col])
	check(ok == 3, "the blow lands on the strike's striking frame at 60, 30 and 20 frames a second (%d of 3)" % ok)
	main.swing = Combat.new()
	step_sprite(s, 1.0)


func test_npcs() -> void:
	var w: World = main.world
	var g: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.job == "guard":
			g = n
			break
	check(g != null and ActorSprite.npc_weapon(g) != "", "a guard carries a weapon")
	var s := ActorSprite.new()
	main.actors.add_child(s)
	s.setup_texture(load("res://assets/characters/villager_00.png"))
	s.wield(ActorSprite.npc_weapon(g))
	g.anim = "sword"
	g.attack_cd = 0.6
	s.set_meta("cd", 0.7)
	check(main._npc_strike_view(g, s, "sword") and not s.striking and s.anim == "idle", "between blows the fighter holds the weapon ready")
	step_sprite(s, 0.0)
	check(s.weapon_icon.visible, "carried, drawn")
	g.attack_cd = 0.1
	main._npc_strike_view(g, s, "sword")
	check(s.striking and s.tool_item == s.weapon_item, "a blow a frame away: the strike begins with the weapon in hand")
	var lead := ActorSprite.strike_lead()
	var cd := 0.1
	var col_at_blow := -1
	for i in 20:
		cd -= 0.02
		step_sprite(s, 0.02)
		if cd <= 0.0:
			col_at_blow = s.frame % 29
			break
	check(col_at_blow == int(ActorSprite.ANIMS.swing[0][ActorSprite.STRIKE_FRAME]), "and its striking frame is drawn as the blow lands (column %d)" % col_at_blow)
	g.attack_cd = 1.0                      # the brain struck and began again
	main._npc_strike_view(g, s, "sword")
	check(s.striking, "the strike under way plays through")
	step_sprite(s, 1.0)
	g.attack_cd = 0.6
	main._npc_strike_view(g, s, "sword")
	step_sprite(s, 0.0)
	check(not s.striking and s.weapon_icon.visible and not s.tool_icon.visible, "then the weapon is carried again")
	g.attack_cd = 1.0                      # a blow seen with no strike before it (a fight's first)
	main._npc_strike_view(g, s, "sword")
	step_sprite(s, 0.0)
	check(s.striking and s.frame % 29 == int(ActorSprite.ANIMS.swing[0][ActorSprite.STRIKE_FRAME]), "a blow seen without a wind-up is drawn from its striking frame")
	var v: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.job != "guard" and n.role != "bandit" and ActorSprite.npc_weapon(n) == "":
			v = n
			break
	var vs := ActorSprite.new()
	main.actors.add_child(vs)
	vs.setup_texture(load("res://assets/characters/villager_00.png"))
	v.anim = "sword"
	v.attack_cd = 0.0
	vs.wield(ActorSprite.npc_weapon(v))
	main._npc_strike_view(v, vs, "sword")
	check(vs.striking and vs.tool_item == "", "a villager with no weapon strikes bare-handed (%s)" % v.name)
	v.anim = "idle"
	# review 2026-10-30: a fighter coming into view mid-fight draws no blow that did not happen
	var hs := ActorSprite.new()
	main.actors.add_child(hs)
	hs.setup_texture(load("res://assets/characters/villager_00.png"))
	hs.wield(ActorSprite.npc_weapon(g))
	g.anim = "sword"
	g.attack_cd = 0.8
	main._npc_strike_view(g, hs, "sword")
	check(not hs.striking, "a fighter first seen mid-fight (the next blow 0.8 s away) is not shown striking")
	hs.set_meta("cd", 0.1)
	hs.set_meta("cd_frame", Engine.get_process_frames() - 50)      # last seen long ago, then out of view
	main._npc_strike_view(g, hs, "sword")
	check(not hs.striking, "nor one seen again after being out of view")
	# review 2026-10-30: another player's one blow stays "sword" in several snapshots and is drawn once
	var ps := ActorSprite.new()
	main.actors.add_child(ps)
	ps.setup_texture(load("res://assets/characters/villager_00.png"))
	ps.wield(ActorSprite.npc_weapon(g))
	main._net_anim_view(ps, "idle")
	main._net_anim_view(ps, "sword")
	check(ps.striking, "another player's blow starts a strike")
	step_sprite(ps, 1.0)
	check(not ps.striking, "which plays through and ends")
	main._net_anim_view(ps, "sword")
	check(not ps.striking, "the same blow still in a later snapshot is not drawn again")
	main._net_anim_view(ps, "idle")
	main._net_anim_view(ps, "sword")
	check(ps.striking, "and the next blow is")
	hs.queue_free()
	ps.queue_free()
	s.queue_free()
	vs.queue_free()


func test_remote() -> void:
	var s := ActorSprite.new()
	main.actors.add_child(s)
	s.setup_texture(load("res://assets/characters/villager_00.png"))
	s.wield("iron_sword")
	s.play("sword")                        # another player's blow, as the network sends it
	check(s.striking and s.anim == "swing" and s.tool_item == "iron_sword", "another player's blow is a strike with the sword they hold")
	step_sprite(s, 0.1)
	s.play("sword")
	check(s.t > 0.05, "repeated snapshots of the same blow do not restart it")
	step_sprite(s, 1.0)
	check(not s.striking and s.weapon_icon.visible, "and it ends back at their side")
	s.queue_free()
