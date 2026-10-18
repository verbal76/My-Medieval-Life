extends SceneTree
## Debug: write an overview PNG of the overworld (one pixel per tile) and time chunk generation.
##   godot --headless --path game --script res://tests/ow_map.gd -- OUT.png [seed] [x0 y0 w h]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "/tmp/ow.png"
	var sd := int(args[1]) if args.size() > 1 else 1
	var x0 := int(args[2]) if args.size() > 2 else -400
	var y0 := int(args[3]) if args.size() > 3 else -400
	var w := int(args[4]) if args.size() > 4 else 960
	var h := int(args[5]) if args.size() > 5 else 900
	var m := VillageMap.load_default()
	var t0 := Time.get_ticks_msec()
	var o := Overworld.create(sd, m)
	print("create ", Time.get_ticks_msec() - t0, " ms, gates ", o.gates.size())
	t0 = Time.get_ticks_msec()
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	var cs := Overworld.chunk_of(Vector2i(x0, y0))
	var ce := Overworld.chunk_of(Vector2i(x0 + w, y0 + h))
	var n := 0
	for cy in range(cs.y, ce.y + 1):
		for cx in range(cs.x, ce.x + 1):
			var ch := o.get_chunk(Vector2i(cx, cy))
			n += 1
			for y in Overworld.CHUNK:
				for x in Overworld.CHUNK:
					var wx := cx * 32 + x - x0
					var wy := cy * 32 + y - y0
					if wx < 0 or wy < 0 or wx >= w or wy >= h:
						continue
					var c := y * 32 + x
					var col := Color(0.55, 0.75, 0.35)
					if ch.ground[c] < 0:
						col = Color(0.9, 0.2, 0.2)
					elif ch.path[c] >= 0:
						col = Color(0.85, 0.7, 0.4)
					elif ch.solid[c] == 1 and ch.kind[c] == 255 and ch.deco[c] < 0:
						col = Color(0.35, 0.33, 0.33)
					elif ch.solid[c] == 1 and ch.deco[c] >= 0:
						col = Color(0.6, 0.6, 0.6)
					elif ch.kind[c] != 255:
						col = Color(0.1, 0.4, 0.15)
					img.set_pixel(wx, wy, col)
	print("generated ", n, " chunks in ", Time.get_ticks_msec() - t0, " ms = ", (Time.get_ticks_msec() - t0) / maxi(1, n), " ms each")
	img.save_png(out)
	quit()
