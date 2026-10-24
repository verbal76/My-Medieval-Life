extends SceneTree
## GP-BANDIT-CAMP-ART (owner directive 2026-10-24, docs/directives/2026-10-24_build21_campfire_asset.md), in the real game scene:
## the bandit camp's fire is the owner's animated campfire (SMStudios): 24 frames of 32 x 32 that loop at 150 ms, drawn with
## nearest filtering among the characters (y-sorted), the bottom of its logs on its ground point in the camp's solid fire cell;
## a character south of it is drawn in front, one north of it behind. The camp's old tiles are gone (the transparent 5958 and
## the pieces of other objects) and it has a whole crate and barrel; SMStudios is credited with its page and licence.
##   godot --headless --path game --script res://tests/campfire_test.gd

var main
var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL " + what)


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = "user://test_saves/campfire_test/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	main.new_game()
	var map: VillageMap = main.map
	var fire: Sprite2D = main.campfire
	var fc: Array = map.data.spawns.get("campfire", [])
	check(fire != null and fc.size() == 2, "the camp has its campfire sprite (spawns.campfire %s)" % str(fc))
	if fire == null:
		_end()
		return
	var cell := Vector2i(int(fc[0]), int(fc[1]))
	var tex := fire.texture
	check(fire.hframes == 24 and fire.vframes == 1 and tex.get_width() == 24 * 32 and tex.get_height() == 32, "24 frames of 32 x 32 in one row (%dx%d)" % [tex.get_width(), tex.get_height()])
	check(fire.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and fire.scale == Vector2.ONE, "nearest filtering, drawn 1:1 (no smoothing, no stretch)")
	var vis := tex.get_image().get_used_rect()
	check(vis.size.y <= 24 and vis.size.x <= 24 * 32, "the fire is about a tile and a half high beside one-tile characters (frames' used height %d px)" % vis.size.y)
	check(fire.get_parent() == main.actors and main.actors.y_sort_enabled, "drawn among the characters, y-sorted")
	# it plays and loops: frame = ticks / 150 ms mod 24
	var seen := {}
	var end := Time.get_ticks_msec() + 900
	while Time.get_ticks_msec() < end:
		await process_frame
		seen[fire.frame] = true
	check(seen.size() >= 4, "it plays (%d frames seen in 0.9 s)" % seen.size())
	check(main.CAMPFIRE_FRAMES == 24 and main.CAMPFIRE_MS == 150 and fire.frame < 24, "it loops over its 24 frames at 150 ms (the art's own timing)")
	# grounded: the lowest opaque row of the art lies on the ground point, which is inside the fire's (solid) cell
	var img := tex.get_image()
	var lowest := -1
	for y in 32:
		for x in 32:
			if img.get_pixel(x, y).a > 0.5:
				lowest = maxi(lowest, y)
	var bottom := fire.position.y + fire.offset.y + (lowest + 1) - 16.0       # centred frame
	check(absf(bottom - fire.position.y) <= 1.0, "the bottom of the logs is on the ground point (%.1f vs %.1f)" % [bottom, fire.position.y])
	check(Vector2i((fire.position / main.T).floor()) == cell and map.is_solid(cell), "the ground point is in the camp's fire cell %s, which is solid" % str(cell))
	var camp: Vector2i = main.world.bandit_camp
	check(camp == cell + Vector2i(0, 1), "the bandits gather just south of it (%s)" % str(camp))
	# front and behind: a character's feet south of the fire sort after it, north of it before
	var south: Vector2 = (Vector2(cell) + Vector2(0.5, 1.5)) * main.T
	var north: Vector2 = (Vector2(cell) + Vector2(0.5, -0.4)) * main.T
	check(south.y > fire.position.y and north.y < fire.position.y, "someone south of it is drawn in front, north of it behind")
	# the camp's old tiles are gone; a whole crate and barrel stand there
	var vals := []
	for l in map.data.layers:
		if str(l.name).begins_with("below"):
			for dy in range(-2, 4):
				for dx in range(-3, 4):
					var v := int(l.data[(cell.y + dy) * map.w + cell.x + dx])
					if v >= 0:
						vals.append(v % 100000)
	check(not vals.has(5958) and not vals.has(3500) and not vals.has(3502) and vals.has(797) and vals.has(358),
		"the camp: no campfire tile or pieces of other objects; a crate and a barrel (%s)" % str(vals))
	check((map.data.animated as Dictionary).is_empty(), "no animated map tile is left for the old fire")
	# credited
	var cr: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/credits.json"))
	var sm: Array = (cr.packs as Array).filter(func(p): return str(p.creator) == "SMStudios")
	check(sm.size() == 1 and str(sm[0].licence) == "CC BY 4.0" and str(sm[0].url) == "https://simon-develop.itch.io/" and str(sm[0].licence_url) == "https://creativecommons.org/licenses/by/4.0/"
		and str(sm[0].packs).contains("1/10"), "SMStudios credited: the campfire, its page, CC BY 4.0 and the change made")
	main.ui.show_credits()
	var links: Array = main.ui.panel_body.find_children("*", "LinkButton", true, false)
	check(links.any(func(l): return (l as LinkButton).uri == "https://simon-develop.itch.io/"), "the credits page links the creator's page")
	_end()


func _end() -> void:
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
