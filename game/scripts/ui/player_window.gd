class_name PlayerWindow
extends RefCounted
## MP-INTERACT-01 (owner, 2026-10-27; docs/expansion20/MP_INTERACT_AUDIT.md): the window for one other player, opened by choosing
## them in the world (Use, Talk, a tap or a click on their character, Next to reach them) on every platform, and the list of the
## players in the session with what they asked (the pause menu's Players, or Use with nothing else in reach).
##
## Named and compact (GameUI.compact), never pausing the shared world (MP-D3), usable by touch, mouse, keys and pad. It offers only
## what the approved systems define, each a consent request the other player answers (World.player_offer / player_answer, MP-D8):
##   Talk      a short message (World.SAY_MAX characters), or one of a few ready phrases a pad can send without a keyboard;
##   Give      goods from the pack (gift, MP-D8);
##   Sell      goods from the pack for a price in coins (World.trade on acceptance);
##   Contract  ask them to supply goods: quantity, price each, days (CON-01's record and rules, Contracts.open_between);
##   Partner   ask them to be partners (MP-D8; MP-PLAYER-FAMILY), when Life's rules allow it.
## What they asked of this player is answered here (Accept, Decline; Counter offers back on their terms), and the open contracts
## between the two are delivered or ended here. Nothing a player writes reaches a villager.

const GOLD := Color8(255, 217, 128)
const COLD := Color8(255, 178, 140)
const WIDTH := 540.0
const PHRASES := ["Hello!", "Follow me.", "Wait here.", "Thank you!", "Shall we trade?"]
## The offer that answers each offer on other terms (Counter): a sale with a bid, an order with an offer to supply, and back.
const COUNTER := {"sell": "buy", "buy": "sell", "contract": "supply", "supply": "contract"}


static func _row(ui: GameUI) -> HFlowContainer:
	var row := HFlowContainer.new()
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 6)
	ui.panel_body.add_child(row)
	return row


## Whether `q` stands beside the local player, on its level (World.OFFER_REACH: offering and accepting need it).
static func beside(ui: GameUI, q: PlayerState) -> bool:
	var me: PlayerState = ui.main.world.player
	return q != null and q.map_level == me.map_level and q.pos.distance_to(me.pos) <= World.OFFER_REACH


## The window for player `pid`. `view`: "" the menu, "talk", "give", "sell", "contract"; `form` the terms being drawn up.
static func show(ui: GameUI, pid: int, view := "", form := {}) -> void:
	var w: World = ui.main.world
	var q: PlayerState = w.player_by_pid(pid)
	if q == null or q == w.player:
		show_list(ui)
		return
	ui._open("player", "%s (player)" % q.name, false)
	match view:
		"talk":
			_talk(ui, q)
		"give", "sell":
			_goods(ui, q, view)
		"contract":
			_contract(ui, q, form)
		"terms":
			_terms(ui, q, form)
		_:
			_menu(ui, q)
	ui.compact(WIDTH)


static func _menu(ui: GameUI, q: PlayerState) -> void:
	var w: World = ui.main.world
	var me := w.player
	var pid := q.pid
	var near := beside(ui, q)
	if not near:
		ui._label("Stand beside %s to offer or accept anything." % q.name, 15, COLD)
	_requests(ui, (w.messages_to(me) + w.offers_to(me)).filter(func(o): return str(o["from"]) == w.player_ref(q)), func(): show(ui, pid))
	for o in w.offers_from(me):
		if str(o.to) == w.player_ref(q) and not str(o.kind) in ["say", "note"]:
			ui._label("You offered %s: %s (waiting for an answer)." % [q.name, w.offer_text(o)], 15)
	for c in w.contracts_with_player(q):
		_contract_row(ui, q, c)
	var row := _row(ui)
	var talk := ui._button("Talk", func(): show(ui, pid, "talk"), true, row)
	talk.name = "PlayerTalk"
	ui._button("Give", func(): show(ui, pid, "give"), near, row).name = "PlayerGive"
	ui._button("Sell", func(): show(ui, pid, "sell"), near, row).name = "PlayerSell"
	ui._button("Contract", func(): show(ui, pid, "contract"), near, row).name = "PlayerContract"
	if w.players_partner_refusal(me, q) == "":
		ui._button("Ask to be partners", func():
			var why := w.player_offer("partner", pid)
			ui.message(why if why != "" else "You ask %s to be your partner. They must agree." % q.name, 4.0, "" if why != "" else "family")
			show(ui, pid), near, row).name = "PlayerPartner"
	var row2 := _row(ui)
	ui._button("All players", func(): show_list(ui), true, row2)
	ui._button("Close", ui.hide_all, true, row2).name = "PlayerClose"


## Rows for offers and messages made to the local player: each with its answer buttons. `back` redraws the window after an answer.
static func _requests(ui: GameUI, list: Array, back: Callable) -> void:
	var w: World = ui.main.world
	for o in list:
		if str(o.kind) == "note":
			continue                              # an answer to an offer: told in the message and kept in the journal, not listed here
		var oid := int(o.id)
		var from: PlayerState = w.player_of_ref(str(o["from"]))
		var who := from.name if from != null else "Someone"
		if str(o.kind) == "say":
			ui._label("%s: \"%s\"" % [who, str(o.get("text", ""))], 16, GOLD)
			ui._button("Put away", func():
				w.player_answer(oid, false)
				back.call(), true, _row(ui)).name = "OfferOk%d" % oid
			continue
		ui._label("%s offers you %s." % [who, w.offer_text(o)], 16, GOLD)
		var row := _row(ui)
		ui._button("Accept", func():
			var why := w.player_answer(oid, true)
			ui.message(why if why != "" else ("You accept." if ui.main.guest_world else "Done."), 4.0)
			back.call(), true, row).name = "OfferAccept%d" % oid
		ui._button("Decline", func():
			w.player_answer(oid, false)
			back.call(), true, row).name = "OfferDecline%d" % oid
		if COUNTER.has(str(o.kind)) and from != null:
			var fpid := from.pid
			var counter := {"item": str(o.item), "qty": int(o.qty), "price": int(o.get("price", 1)), "days": int(o.get("days", 3)),
				"kind": COUNTER[str(o.kind)], "counter": oid}
			ui._button("Counter", func(): show(ui, fpid, "terms", counter), true, row).name = "OfferCounter%d" % oid


## An open contract between the two: what it is, and Deliver (the seller, beside the buyer) or End (either).
static func _contract_row(ui: GameUI, q: PlayerState, c: Dictionary) -> void:
	var w: World = ui.main.world
	var item := GameData.item_name(str(c.item)).to_lower()
	var cid := int(c.id)
	var pid := q.pid
	var row: HFlowContainer
	if w.is_acting_ref(c.seller):
		var have := mini(w.player.inv.count(str(c.item)), Contracts.left(c))
		ui._label("You supply %s: %d of %d %s at %d each, by the end of day %d." % [q.name, int(c.delivered), int(c.qty), item, int(c.price_each), int(c.deadline_day) + 1], 15)
		row = _row(ui)
		ui._button("Deliver %d" % have, func():
			var gave := w.player_contract_deliver(cid, have)
			ui.message(("You hand over %d %s and are paid %d coins." % [gave, item, gave * int(c.price_each)]) if gave > 0 else "Nothing handed over: stand beside %s, with the goods." % q.name, 4.0, "contract" if gave > 0 else "")
			show(ui, pid), have > 0 and beside(ui, q), row).name = "ContractDeliver%d" % cid
	else:
		ui._label("%s supplies you: %d of %d %s at %d each, by the end of day %d; %d coins set aside." % [q.name, int(c.delivered), int(c.qty), item, int(c.price_each), int(c.deadline_day) + 1, int(c.reserved)], 15)
		row = _row(ui)
	ui._button("End it", func():
		var why: String = w.contracts.cancel(c, w.acting_ref())
		ui.message(why if why != "" else "The contract is ended: what was delivered is paid, the rest of the coins go back.", 4.0, "" if why != "" else "contract")
		show(ui, pid), true, row).name = "ContractEnd%d" % cid


## Talk: a short message, typed or a ready phrase (a pad needs no keyboard). It is shown to them and kept in both journals.
static func _talk(ui: GameUI, q: PlayerState) -> void:
	var w: World = ui.main.world
	var pid := q.pid
	ui.panel_back = func(): show(ui, pid)
	ui._label("Say something to %s. Only %s reads it." % [q.name, q.name], 15)
	var send := func(text: String) -> void:
		var why := w.player_offer("say", pid, "", 0, null, 0, 0, text)
		if why == "":
			ui.message("You say to %s: \"%s\"" % [q.name, World.clean_say(text)], 4.0, "player")
			show(ui, pid)
		else:
			ui.message(why)
	var row := _row(ui)
	for ph in PHRASES:
		var t: String = ph
		ui._button(t, func(): send.call(t), true, row)
	var edit := LineEdit.new()
	edit.name = "PlayerSay"
	edit.max_length = World.SAY_MAX
	edit.placeholder_text = "Write a message (up to %d letters)" % World.SAY_MAX
	edit.custom_minimum_size = Vector2(0, 48)
	edit.text_submitted.connect(func(t): send.call(t))
	ui.panel_body.add_child(edit)
	var row2 := _row(ui)
	ui._button("Send", func(): send.call(edit.text), true, row2).name = "PlayerSend"
	ui._button("Back", func(): show(ui, pid), true, row2)


## Give or Sell: the goods in the pack (what is worn stays), then how many (and, to sell, the price).
static func _goods(ui: GameUI, q: PlayerState, view: String) -> void:
	var w: World = ui.main.world
	var me := w.player
	var pid := q.pid
	ui.panel_back = func(): show(ui, pid)
	ui._label(("Give %s something from your pack. They must accept it." if view == "give" else "Sell %s something from your pack for a price. They must accept, and pay.") % q.name, 15)
	var ids: Array = me.inv.ids()
	ids.sort()
	var grid := GridContainer.new()
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	ui.panel_body.add_child(grid)
	var spare := func(id: String) -> int:
		var worn := 0
		for slot in PlayerState.GEAR:
			if str(me.get(slot)) == id:
				worn += 1
		return me.inv.count(id) - worn
	var shown := ids.filter(func(i): return spare.call(i) > 0)
	grid.columns = ui._fit_columns(shown.map(func(i): return "%s x%d" % [GameData.item_name(i), me.inv.count(i)]), 2)
	if shown.is_empty():
		ui._label("Your pack holds nothing to spare.", 15, COLD)
	for id in shown:
		var iid: String = id
		var b := ui._button("%s x%d" % [GameData.item_name(iid), spare.call(iid)], func():
			if view == "give":
				_gift_qty(ui, q, iid, spare.call(iid))
			else:
				show(ui, pid, "terms", {"kind": "sell", "item": iid, "qty": 1, "price": maxi(1, GameData.value(iid))}), true, grid)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui._button("Back", func(): show(ui, pid))


static func _gift_qty(ui: GameUI, q: PlayerState, id: String, n: int) -> void:
	var w: World = ui.main.world
	var pid := q.pid
	var give := func(k: int) -> void:
		var why := w.player_offer("gift", pid, id, k)
		ui.message(why if why != "" else "You offer %d %s to %s. They must accept." % [k, GameData.item_name(id).to_lower(), q.name], 4.0, "" if why != "" else "trade")
		show(ui, pid)
	if n <= 1:
		give.call(1)
		return
	var qp := QuantityPicker.new().setup("Give %s" % GameData.item_name(id).to_lower(), "You have %d to spare." % n, n, "Offer", -1, "")
	qp.cancelled.connect(func(): show(ui, pid, "give"))
	qp.confirmed.connect(func(k: int): give.call(k))
	ui.panel_body.add_child(qp)
	ui.panel_body.move_child(qp, 0)
	if ui.scheme != "touch":
		qp.focus_default.call_deferred()


## Contract: the goods to ask them for (any goods: what a player can come by is theirs to judge), then the terms.
static func _contract(ui: GameUI, q: PlayerState, _form: Dictionary) -> void:
	var pid := q.pid
	ui.panel_back = func(): show(ui, pid)
	ui._label("Ask %s to supply goods: you set how many, the price each and the days. Your coins are set aside when they agree, and paid as the goods come." % q.name, 15)
	var ids := GameData.items.keys().filter(func(i): return GameData.value(i) > 0)
	ids.sort_custom(func(a, b): return GameData.item_name(a) < GameData.item_name(b))
	var grid := GridContainer.new()
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	ui.panel_body.add_child(grid)
	grid.columns = ui._fit_columns(ids.map(func(i): return GameData.item_name(i)), 3)
	for id in ids:
		var iid: String = id
		var b := ui._button(GameData.item_name(iid), func():
			show(ui, pid, "terms", {"kind": "contract", "item": iid, "qty": 5, "price": maxi(1, GameData.value(iid)), "days": 3}), true, grid)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui._button("Back", func(): show(ui, pid))


## The terms of a sale or a contract on one page: steppers for the quantity, the price (in all for a sale, each for a contract) and,
## for a contract, the days; the sentence it makes; Send. A counter (form.counter) declines their offer and sends these terms back.
static func _terms(ui: GameUI, q: PlayerState, form: Dictionary) -> void:
	var w: World = ui.main.world
	var me := w.player
	var pid := q.pid
	var kind := str(form.kind)
	var item := str(form.item)
	var name := GameData.item_name(item).to_lower()
	var redraw := func(f: Dictionary) -> void: show(ui, pid, "terms", f)
	ui.panel_back = func(): show(ui, pid, "sell" if kind == "sell" and not form.has("counter") else ("contract" if kind == "contract" and not form.has("counter") else ""))
	var qty_hi := maxi(1, me.inv.count(item)) if kind == "sell" else 999
	var each := kind in ["contract", "supply"]
	_stepper(ui, "How many", int(form.qty), 1, qty_hi, form, "qty", redraw)
	_stepper(ui, "Price each (coins)" if each else "Price in all (coins)", int(form.price), 1, World.PRICE_MAX, form, "price", redraw)
	if each:
		_stepper(ui, "Days to deliver", int(form.days), 1, int(Contracts.cfg().max_days), form, "days", redraw)
	var qty := int(form.qty)
	var price := int(form.price)
	var by_day := w.day() + int(form.get("days", 0))
	var sentence := ""
	match kind:
		"sell":
			sentence = "You sell %d %s to %s for %d coins." % [qty, name, q.name, price]
		"buy":
			sentence = "You buy %d %s from %s for %d coins." % [qty, name, q.name, price]
		"contract":
			sentence = "%s supplies you %d %s at %d each (%d coins, set aside when they agree) by the end of day %d." % [q.name, qty, name, price, qty * price, by_day]
		"supply":
			sentence = "You supply %s with %d %s at %d each (%d coins) by the end of day %d." % [q.name, qty, name, price, qty * price, by_day]
	var sl := ui._label(sentence, 18, GOLD)
	sl.name = "TermsSummary"
	var row := _row(ui)
	var send := ui._button("Counter with these terms" if form.has("counter") else "Send to %s" % q.name, func():
		if form.has("counter"):
			w.player_answer(int(form.counter), false)
		var why := w.player_offer(kind, pid, item, qty, null, price, int(form.get("days", 0)))
		ui.message(why if why != "" else "Sent to %s: %s They must accept." % [q.name, sentence], 4.0,
				"" if why != "" else ("contract" if each else "trade"))
		show(ui, pid), beside(ui, q), row)
	send.name = "TermsSend"
	ui._button("Back", ui.panel_back, true, row)
	if ui.scheme != "touch":
		send.grab_focus.call_deferred()


## One term with large - and + buttons (by one and by ten): the number between them.
static func _stepper(ui: GameUI, label: String, value: int, lo: int, hi: int, form: Dictionary, key: String, redraw: Callable) -> void:
	var row := _row(ui)
	var l := Label.new()
	l.text = "%s: %d" % [label, value]
	l.name = "Term_" + key
	l.custom_minimum_size = Vector2(200, 0)
	l.add_theme_font_size_override("font_size", 16)
	row.add_child(l)
	for step in [-10, -1, 1, 10]:
		var st: int = step
		var b := ui._button(("%+d" % st), func():
			var f: Dictionary = form.duplicate()
			f[key] = clampi(value + st, lo, hi)
			redraw.call(f), (value + st >= lo) if st < 0 else (value + st <= hi or value < hi), row)
		b.custom_minimum_size = Vector2(56, 48)
		b.name = "Step_%s_%s" % [key, ("m" if st < 0 else "p") + str(absi(st))]


## The players in the session and what they asked of this one: each player by name (their window), and every request to answer.
static func show_list(ui: GameUI) -> void:
	var w: World = ui.main.world
	var me := w.player
	ui._open("players", "Players", false)
	var others: Array = ui.main.other_players()
	if others.is_empty():
		ui._label("No other player is in this world now.", 15)
	var row := _row(ui)
	for q: PlayerState in others:
		var pid := q.pid
		ui._button("%s%s" % [q.name, "" if beside(ui, q) else " (away from you)"], func(): show(ui, pid), true, row).name = "PlayerList%d" % pid
	_requests(ui, w.messages_to(me) + w.offers_to(me), func(): show_list(ui))
	ui._button("Close", ui.hide_all)
	ui.compact(WIDTH)
