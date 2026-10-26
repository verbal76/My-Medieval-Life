extends SceneTree
## GP-STALL-RENT-WRONG-PITCH (owner, 2026-10-26: "When ever I rent a booth, it never gives me the one I clicked on and rented. It
## says I already have one and gives me a different booth."): in the real game scene, renting from a pitch's window rents that
## pitch, not the first free one; the window then shows it as the player's own, with no "You already rent a stall."; the first
## free pitch stays free; renting a pitch that is not free is refused and changes nothing; the old call without a pitch still
## rents the first free one; a guest (MP C, World.as_actor) renting a chosen pitch gets that pitch.
##   godot --headless --path game --script res://tests/stall_rent_pitch_test.gd

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
	main.save_path = "user://test_saves/stall_rent_pitch_test/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _texts(n: Node, out: Array) -> Array:
	if n is Label:
		out.append((n as Label).text)
	elif n is Button:
		out.append((n as Button).text)
	for c in n.get_children():
		_texts(c, out)
	return out


func _button(n: Node, prefix: String) -> Button:
	if n is Button and (n as Button).text.begins_with(prefix):
		return n
	for c in n.get_children():
		var b := _button(c, prefix)
		if b != null:
			return b
	return null


func _tenants(w: World) -> Dictionary:
	var out := {}
	for id in w.business.sorted_ids():
		out[str(id)] = w.tenant_of(w.stalls[id])
	return out


func _free(w: World) -> Array:
	return w.business.sorted_ids().filter(func(id): return w.business.is_free_pitch(w.stalls[id]))


func _run() -> void:
	main.new_game()
	var w: World = main.world
	var biz: Business = w.business
	var ui: GameUI = main.ui
	var p := w.player
	p.coins = 200
	var free := _free(w)
	check(free.size() >= 2, "the market has at least two free pitches (%d)" % free.size())
	var first := str(free[0])
	var chosen := str(free[free.size() - 1])
	check(chosen != first, "the chosen pitch (%s) is not the first free one (%s)" % [chosen, first])
	# refused attempts first: each changes no stall, no coin
	var before := _tenants(w)
	var merchant := ""
	for id in biz.sorted_ids():
		if not Business.is_pitch(w.stalls[id]) and w.tenant_of(w.stalls[id]) != "":
			merchant = str(id)
			break
	var total := w.total_coins()
	check(merchant != "" and biz.rent(w.stalls[merchant]) != "" and _tenants(w) == before and p.coins == 200, "renting an occupied merchant's stall (%s) is refused and changes nothing" % merchant)
	p.coins = Business.rent_day() - 1
	check(biz.rent(w.stalls[chosen]) != "" and _tenants(w) == before and p.coins == Business.rent_day() - 1, "without the day's rent the chosen pitch is refused and nothing changes (atomic)")
	p.coins = 200
	check(w.total_coins() == total, "no coins moved by the refusals")
	var coins := p.coins
	var treasury := w.treasury
	StallWindow.show(ui, chosen)
	check(ui.panel_kind == "stall" and not _texts(ui.panel_body, []).has("You already rent a stall."), "the chosen pitch's window offers it for rent, with no refusal")
	var rent_btn := _button(ui.panel_body, "Rent it for")
	check(rent_btn != null and not rent_btn.disabled, "its Rent button is enabled")
	if rent_btn != null:
		rent_btn.pressed.emit()
	await process_frame
	check(w.tenant_of(w.stalls[chosen]) == World.PLAYER, "the chosen pitch is the player's (tenant %s)" % w.tenant_of(w.stalls[chosen]))
	check(w.tenant_of(w.stalls[first]) == "", "the first free pitch is still free")
	var after := _tenants(w)
	var changed := after.keys().filter(func(k): return after[k] != before[k])
	check(changed == [chosen], "no other stall's tenant changed (changed: %s)" % str(changed))
	check(w.total_coins() == total, "coins are conserved by the rent")
	check(str(biz.mine().get("id", "")) == chosen, "the player's stall is the chosen pitch")
	check(p.coins == coins - Business.rent_day() and w.treasury == treasury + Business.rent_day(), "the first day's rent paid once, purse to treasury")
	var shown := _texts(ui.panel_body, [])
	check(ui.panel_kind == "stall" and ui.title_label.text.to_lower().begins_with("your market stall"), "the window now shows the pitch as the player's own (%s)" % ui.title_label.text)
	check(not shown.has("You already rent a stall.") and not ui.toast.text.contains("already"), "no 'You already rent a stall' message (toast: %s)" % ui.toast.text)
	ui.hide_all()
	# a pitch that is not free is refused and changes nothing
	biz.close(biz.mine())
	var npc_pitch := ""
	for id in biz.sorted_ids():
		if biz.is_free_pitch(w.stalls[id]) and str(id) != chosen:
			npc_pitch = str(id)
	w.set_tenant(w.stalls[npc_pitch], "npc:1")
	coins = p.coins
	check(biz.rent(w.stalls[npc_pitch]) != "" and w.tenant_of(w.stalls[npc_pitch]) == "npc:1" and p.coins == coins and biz.mine().is_empty(), "renting a pitch someone else holds is refused and changes nothing")
	check(biz.rent_refusal(w.stalls[npc_pitch]) == "That pitch is not free to rent.", "the window says why")
	w.set_tenant(w.stalls[npc_pitch], "")
	# the old call without a pitch (the screenshot scenes) still rents the first free one
	var expect := str(_free(w)[0])
	check(biz.rent() == "" and str(biz.mine().get("id", "")) == expect, "rent() with no pitch rents the first free pitch, as before (%s)" % expect)
	check(biz.rent(w.stalls[chosen]) == "You already rent a stall.", "one stall at a time")
	biz.close(biz.mine())
	# a guest renting a chosen pitch (MP C: the host applies the guest's verb as the guest)
	var g := PlayerState.new()
	g.name = "Gwen"
	g.family = "Fairlight"
	g.sex = "female"
	g.born = w.player.born
	Identity.register_player(w, g)
	w.give_start_kit(g)
	g.net_key = "ab".repeat(32)
	w.add_guest(g)
	g.coins = 200
	var gfree := _free(w)
	var pick := str(gfree[gfree.size() - 1])
	g.pos = w.business.use_cell(w.stalls[pick])
	var r = biz.rent(w.stalls[pick], g)
	check(str(r) == "" and w.tenant_of(w.stalls[pick]) == w.player_ref(g), "a guest renting a chosen pitch gets that pitch (%s, tenant %s)" % [pick, w.tenant_of(w.stalls[pick])])
	check(w.tenant_of(w.stalls[str(gfree[0])]) == "", "and the first free pitch stays free")
	var enc: Variant = NetActions.enc(w, w.stalls[pick])
	check(enc is Dictionary and not (enc as Dictionary).is_empty(), "the pitch can be named to the host (the guest's mirrored verb carries it)")
	print("\nstall_rent_pitch_test: %d checks, %d failures" % [checks, failures])
	main.queue_free()
	quit(1 if failures > 0 else 0)

