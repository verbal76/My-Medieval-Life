class_name CreditWindow
extends RefCounted
## TRADE-CREDIT: the credit and barter page of the trade window (opened from show_trade). Debts between you and this
## villager with a Repay button for what you owe; what they will sell on credit (one unit at a time, at the ask),
## and barter: pick what you want, then what you give for it; what a villager has asked of you (accept or refuse); and
## what you offer them, on credit or by barter, of what they can use. The rules are in Credit; this only asks.

const GOLD := Color8(255, 217, 128)
const DIM := Color(0.8, 0.78, 0.7)


## `want` "" shows the page; an item id shows the pick of goods to give for one of it.
static func show(ui, n: NPC, want := "", offer := "") -> void:
	var w: World = ui.main.world
	var p := w.player
	var cr: Credit = w.credit
	ui._open("trade", "Credit and barter with %s %s  ·  you have %d coins" % [n.name, n.family, p.coins])
	var me := Credit.ref_of(p)
	var them := Credit.ref_of(n)
	if want != "":
		_barter_pick(ui, n, want)
		return
	if offer != "":
		_offer_pick(ui, n, offer)
		return
	for r in cr.request_for(n.id):
		var rid: int = r.id
		var item := GameData.item_name(str(r.item)).to_lower()
		ui._label(("%s asks you for %d %s and offers %d %s in barter." % [n.name, int(r.qty), item, int(r.give_qty), GameData.item_name(str(r.give)).to_lower()]) if str(r.mode) == "barter" \
				else "%s asks you for %d %s on credit: %d coins, repaid by day %d." % [n.name, int(r.qty), item, int(r.value), w.day() + int(Credit.cfg().days)], 16, GOLD)
		ui._button("Accept", func():
			ui.message(str(cr.answer_request(rid, true).text), 4.0, "money")
			show(ui, n))
		ui._button("Refuse", func():
			ui.message(str(cr.answer_request(rid, false).text), 4.0, "money")
			show(ui, n))
	var any := false
	for d in cr.debts_of(them, me):
		any = true
		var id: int = d.id
		var late: bool = str(d.state) == Credit.DEFAULTED
		ui._label("You owe %s %d coins for %d %s, %s." % [n.name, int(d.value), int(d.qty), GameData.item_name(str(d.item)).to_lower(),
				("overdue since day %d: until it is paid they will sell you nothing on credit" % int(d.due)) if late else "due by day %d" % int(d.due)], 16, Color(1, 0.7, 0.55) if late else GOLD)
		ui._button("Repay %d coins" % int(d.value), func():
			if cr.repay(id, true):
				ui.message("You repay %d coins." % int(d.value), 4.0, "money")
			show(ui, n), p.coins >= int(d.value))
	for d in cr.debts_of(me, them):
		any = true
		ui._label("%s owes you %d coins for %d %s, due by day %d." % [n.name, int(d.value), int(d.qty), GameData.item_name(str(d.item)).to_lower(), int(d.due)], 16, DIM)
	if not any:
		ui._label("No debts between you.", 15, DIM)
	var sale: Array = w.brain.for_sale(n).filter(func(i): return cr.available(n, i) > 0)
	var why := cr.credit_refusal(n, p, 1)
	ui._label("On credit:", 20, Color(1, 0.85, 0.5))
	ui._label("Trust: %d (they lend from %d). Up to %d coins at once, due in %d days, no interest; they are repaid in coins." % [roundi(cr.trust(them, me)), roundi(Credit.trust_needed()), int(Credit.cfg().limit), int(Credit.cfg().days)], 14, DIM)
	if why != "" and not why.begins_with("No credit"):
		ui._label(why, 15, Color(1, 0.7, 0.55))
	for id in sale:
		var price: int = cr.ask_prices(n, p, id, 1)[0]
		var gid: String = id
		var no := cr.credit_refusal(n, p, price)
		ui._item_row(id, n.inv.count(id), "%d coins, pay by day %d%s" % [price, w.day() + int(Credit.cfg().days), "" if no == "" else "  ·  " + no], "Buy 1",
			func():
				var r: Dictionary = cr.sell_on_credit(n, p, gid, 1, price)
				ui.message(str(r.text))
				show(ui, n), no == "" and p.inv.can_add(id))
	ui._label("By barter (goods for goods, at both sides' prices):", 20, Color(1, 0.85, 0.5))
	for id in sale:
		var gid2: String = id
		ui._item_row(id, n.inv.count(id), "asks %d coins' worth" % int(cr.ask_prices(n, p, id, 1)[0]), "Barter", func(): show(ui, n, gid2), p.inv.can_add(id))
	ui._label("Your offer to %s:" % n.name, 20, Color(1, 0.85, 0.5))
	var mine: Array = p.inv.ids().filter(func(i): return cr.spare(p, i) > 0 and cr.accepts(n, i))
	if mine.is_empty():
		ui._label("%s has no use for anything you can spare." % n.name, 15, DIM)
	for id in mine:
		var oid: String = id
		var oprice: int = cr.ask_prices(p, n, id, 1)[0]
		var lend := cr.credit_refusal(p, n, oprice)
		ui._item_row(id, p.inv.count(id), "%d coins, due by day %d%s" % [oprice, w.day() + int(Credit.cfg().days), "" if lend == "" else "  ·  " + lend], "Lend 1",
			func():
				ui.message(str(cr.sell_on_credit(p, n, oid, 1, oprice).text), 4.0, "money")
				show(ui, n), lend == "")
		ui._item_row(id, p.inv.count(id), "swap for their goods", "Barter", func(): show(ui, n, "", oid))
	ui._button("Back to trading", func(): ui.show_trade(n))


static func _barter_pick(ui, n: NPC, want: String) -> void:
	var w: World = ui.main.world
	var p := w.player
	var cr: Credit = w.credit
	ui._label("To get 1 %s from %s, give:" % [GameData.item_name(want).to_lower(), n.name], 20, Color(1, 0.85, 0.5))
	var shown := false
	for give in p.inv.ids():
		if give == want or cr.spare(p, give) < 1:
			continue
		var q := cr.barter_quote(n, p, want, 1, give)
		if not bool(q.ok) and not cr.accepts(n, give):
			continue
		shown = true
		var gid: String = give
		ui._item_row(give, p.inv.count(give), ("%d for it (they value it at %d coins)" % [int(q.give_qty), int(q.offered)]) if bool(q.ok) else str(q.why), "Swap",
			func():
				var r: Dictionary = cr.barter(n, p, want, 1, gid)
				ui.message(str(r.text))
				show(ui, n), bool(q.ok))
	if not shown:
		ui._label("%s has no use for anything you can spare." % n.name, 15, DIM)
	ui._button("Back", func(): show(ui, n))


## The player offers 1 `offer` by barter: what the villager gives for it.
static func _offer_pick(ui, n: NPC, offer: String) -> void:
	var w: World = ui.main.world
	var p := w.player
	var cr: Credit = w.credit
	ui._label("To swap 1 %s with %s, take:" % [GameData.item_name(offer).to_lower(), n.name], 20, Color(1, 0.85, 0.5))
	var shown := false
	for give in n.inv.ids():
		if give == offer or cr.spare(n, give) < 1:
			continue
		var q := cr.barter_quote(p, n, offer, 1, give)
		shown = true
		var gid: String = give
		ui._item_row(give, n.inv.count(give), ("%d of it (you ask %d coins' worth)" % [int(q.give_qty), int(q.ask)]) if bool(q.ok) else str(q.why), "Swap",
			func():
				ui.message(str(cr.barter(p, n, offer, 1, gid).text), 4.0, "trade")
				show(ui, n), bool(q.ok))
	if not shown:
		ui._label("%s has nothing to spare." % n.name, 15, DIM)
	ui._button("Back", func(): show(ui, n))
