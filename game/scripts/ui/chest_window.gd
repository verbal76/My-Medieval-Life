class_name ChestWindow
extends RefCounted
## PL2-002: the storage window for a chest, crate or barrel (a Chests unit). Your own: store from the
## pack and take back, with the quantity control (PL2-012) and Take All / Store All, and a lock button.
## Someone else's: its goods listed with Take marked as theft; a locked one shows the lock, the chance
## and a Pick button instead. Built from GameUI's own widgets so it looks and moves like the house window.

var ui: GameUI


func _init(game_ui: GameUI) -> void:
	ui = game_ui


func show(uid: String, pick := {}, focus := {}) -> void:
	var w: World = ui.main.world
	var u: Dictionary = w.chests.unit(uid)
	if u.is_empty():
		ui.hide_all()
		return
	var i: Dictionary = w.chests.info(u)
	var own: bool = i.access == "own"
	var title := "%s %s" % [String(i.whose).capitalize() if own else String(i.whose), u.get("look", u.kind)]     # GP-TARGET-ART-MATCH
	ui._open("chest", title)
	if i.access == "decor":
		ui._label(w.chests.cannot_open(u), 20)
		return
	var lk: Dictionary = w.chests.lock_of(u)
	if not own:
		ui._label("Not yours. Taking from it is theft: whoever is in the room sees it.", 18, Color(1, 0.7, 0.55))
	if lk.locked and not own:
		var why: String = w.chests.cannot_pick(u)
		ui._label("It is locked (lock level %d). Chance to pick it: %d%%. It takes about %d minutes. Lockpicks: %d. A failed try may snap the pick, and a noisy try can be seen." % [
			lk.level, roundi(w.chests.pick_chance(u) * 100.0), roundi(w.chests.pick_minutes(u)), w.player.inv.count("lockpick")], 18)
		var b: Button = ui._button("Pick the lock", func(): ui.main.pick_lock(uid), why == "")
		if why != "":
			ui._label(why, 16, Color(1, 0.7, 0.55))
		else:
			b.grab_focus.call_deferred()
		return
	if own:
		lock_button(u, func(): show(uid))
	if not pick.is_empty():
		_picker(u, pick)
	var rows := {}
	var items: Array = w.chests.goods(u)
	ui._label("Inside:", 20, Color(1, 0.85, 0.5))
	if items.is_empty():
		ui._label("Empty.", 18)
	elif own:
		rows["@take_all"] = ui._button("Take all", func(): _move_all(uid, true), true)
	for id in items:
		var iid: String = id
		rows["chest:" + iid] = ui._item_row(id, i.store.count(id), "", "Take" if own else "Take (theft)", func():
			show(uid, {"id": iid, "from": "chest"}))
	if own:
		ui._label("Your pack:", 20, Color(1, 0.85, 0.5))
		if not ui._home_storable().is_empty():
			rows["@store_all"] = ui._button("Store all", func(): _move_all(uid, false), true)
		for id in w.player.inv.ids():
			var iid: String = id
			rows["pack:" + iid] = ui._item_row(id, w.player.inv.count(id), "", "Store", func():
				show(uid, {"id": iid, "from": "pack"}))
	if not focus.is_empty() and ui.scheme != "touch":
		ui._home_focus(rows, focus)


## Lock / unlock button for your own chest (a padlock is used up the first time).
func lock_button(u: Dictionary, again: Callable) -> void:
	var w: World = ui.main.world
	var lk: Dictionary = w.chests.lock_of(u)
	if int(lk.level) > 0:
		ui._button("Unlock the chest (your key)" if lk.locked else "Lock the chest (your key)", func():
			w.chests.set_own_lock(u, not lk.locked)
			again.call())
	else:
		var has: bool = w.player.inv.has("padlock")
		ui._button("Fit a padlock (%d in your pack)" % w.player.inv.count("padlock"), func():
			var err: String = w.chests.set_own_lock(u, true)
			if err != "":
				ui.message(err)
			again.call(), has)


func _move_all(uid: String, taking: bool) -> void:
	var w: World = ui.main.world
	var u: Dictionary = w.chests.unit(uid)
	var i: Dictionary = w.chests.info(u)
	var left := 0
	var ids: Array = w.chests.goods(u) if taking else ui._home_storable()
	for id in ids:
		var n: int = i.store.count(id) if taking else w.player.inv.count(id)
		var err: String = ""
		if taking:
			var r: Dictionary = w.chests.take(u, id, n)
			err = "" if r.ok else r.text
		else:
			err = w.chests.store(u, id, n)
		if err != "":
			left += 1
	if left > 0:
		ui.message("%d kinds would not fit." % left)
	show(uid, {}, {"key": "@take_all" if taking else "@store_all", "idx": 0})


func _picker(u: Dictionary, pick: Dictionary) -> void:
	var w: World = ui.main.world
	var i: Dictionary = w.chests.info(u)
	var p := w.player
	var id: String = pick.id
	var taking: bool = pick.from == "chest"
	var src: Inventory = i.store if taking else p.inv
	var dst: Inventory = p.inv if taking else i.store
	var have := src.count(id)
	var mx := have if dst.can_add(id) else 0
	var qp := QuantityPicker.new().setup(("Take " if taking else "Store ") + GameData.item_name(id),
		"%d in the %s  ·  %d in the %s" % [have, "chest" if taking else "pack", dst.count(id), "pack" if taking else "chest"],
		mx, "Take" if taking else "Store", -1, p.inv.full_text(id) if taking else "The chest is full.")
	var key := ("chest:" if taking else "pack:") + id
	qp.cancelled.connect(func(): show(u.id, {}, {"key": key, "idx": src.ids().find(id)}))
	qp.confirmed.connect(func(q: int):
		var idx := src.ids().find(id)
		if taking:
			var r: Dictionary = w.chests.take(u, id, q)
			ui.message(r.text)
		else:
			var err: String = w.chests.store(u, id, q)
			if err != "":
				ui.message(err)
		show(u.id, {}, {"key": key, "idx": idx}))
	ui.panel_body.add_child(qp)
	ui.panel_body.move_child(qp, 1)
	if ui.scheme != "touch":
		qp.focus_default.call_deferred()
