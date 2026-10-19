class_name FitWindow
extends RefCounted
## Fitting out a room of the player's (PL1-10 stage 3): the pieces that can be put in (a shop counter, shelves,
## stock chests, and the oven, stove, workbench, forge and anvil that already exist), what each takes from the
## pack, the pieces already there with a way to take them up, and what the room has become. "Place" hands over
## to the placing bar (Main.begin_fit: the ghost, the arrow keys, the stick, a tap). The rules are in Fitting.

const COLD := Color8(255, 178, 140)
const GOLD := Color8(255, 217, 128)


static func show(ui: GameUI, bid: String) -> void:
	var w: World = ui.main.world
	var b: Dictionary = w.buildings.get(bid, {})
	var fit: Fitting = w.fitting
	var why := fit.fit_refusal(b)
	ui._open("fitout", "Fit out this room  ·  %s" % w.property.describe(b) if why == "" else "Fit out")
	if why != "":
		ui._label(why, 17, COLD)
		ui._button("Close", ui.hide_all)
		return
	ui._label(fit.summary(b), 17, GOLD)
	ui._label("Put equipment where it makes sense: it takes up a tile, and nothing may shut off a door, a bed or part of the room. The materials come from your pack and come back if you take a piece up.", 15)
	if fit.count(b, "counter") > 0:
		var sh: Dictionary = b.get("shop", {})
		if sh.is_empty():
			var no := w.business.open_refusal(b)
			ui._label("The counter is ready. A shop pays a licence of %d coins a day to the manor." % int(GameData.b("shop_licence_day")), 16)
			ui._button("Open the shop (licence %d coins a day)" % int(GameData.b("shop_licence_day")), func():
				var r := w.business.open_shop(b)
				ui.message(r if r != "" else "Your shop is open.")
				if r == "":
					StallWindow.show(ui, bid)
				else:
					show(ui, bid), no == "")
			if no != "":
				ui._label(no, 15, COLD)
		else:
			ui._button("Go to the shop's books and stock", func(): StallWindow.show(ui, bid))
	ui._label("Equipment:", 20, Color(1, 0.85, 0.5))
	for kind in Fitting.KINDS:
		var k: String = kind
		var have := fit.count(b, k)
		var h := HBoxContainer.new()
		var l := Label.new()
		l.text = "%s  (%s)  —  %s%s" % [World.cap(Fitting.NAMES[k]), Fitting.cost_text(k), Fitting.PURPOSE[k],
			("   [%d of %d placed]" % [have, Fitting.limit(k)]) if Fitting.limit(k) > 1 else ("   [placed]" if have > 0 else "   [in the stamp]" if fit.station_kinds(b).has(k) else "")]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		var can := true
		var reason := ""
		if have >= Fitting.limit(k) or (Fitting.STATIONS.has(k) and fit.station_kinds(b).has(k)):
			can = false
			reason = "Already there"
		else:
			var c := Fitting.cost(k)
			for id in c:
				if w.player.inv.count(id) < int(c[id]):
					can = false
					reason = "Need %s" % Fitting.cost_text(k)
		var btn := Button.new()
		btn.text = "Place" if can else reason
		btn.disabled = not can
		btn.custom_minimum_size = Vector2(150, 48)
		btn.pressed.connect(func(): ui.main.begin_fit(bid, k))
		h.add_child(btn)
		ui.panel_body.add_child(h)
	var placed := fit.list(b)
	if not placed.is_empty():
		ui._label("In the room:", 20, Color(1, 0.85, 0.5))
	for e in placed:
		var k: String = str(e.kind)
		var h := HBoxContainer.new()
		var l := Label.new()
		l.text = "%s at (%d, %d)" % [World.cap(Fitting.NAMES[k]), int(e.at[0]), int(e.at[1])]
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		var tb := Button.new()
		tb.text = "Take up"
		tb.custom_minimum_size = Vector2(120, 48)
		tb.pressed.connect(func():
			var r := fit.remove(b, k)
			ui.message(r if r != "" else "%s taken up; the materials are back in your pack." % World.cap(Fitting.NAMES[k]))
			show(ui, bid))
		h.add_child(tb)
		ui.panel_body.add_child(h)
	ui._button("Done", ui.hide_all)
	_to_top.call_deferred(ui)


static func _to_top(ui: GameUI) -> void:
	var scroller := ui.panel_body.get_parent() as ScrollContainer
	if scroller != null and ui.panel_kind == "fitout":
		scroller.scroll_vertical = 0
