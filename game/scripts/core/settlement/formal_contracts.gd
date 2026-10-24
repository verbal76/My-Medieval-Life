class_name FormalAgreements
extends RefCounted
## PROSPECTIVE (Expansion 18, X18-Q13; PROS-18): signatures, by the owner's decision of 2026-10-21 (Q18-13; docs/directives/
## 2026-10-21_expansion18_capability_simulations_contracts.md section 4 on staging):
##   - ordinary small agreements need no notarisation or signature: binding when agreed;
##   - formal commercial contracts and ownership transfers need every party's signature;
##   - parties meeting face to face may sign without a notary (both present, within face_to_face_tiles, the same place);
##   - when they cannot meet, a courier with legal skill acts as notary: it carries the document physically from one party
##     to the other for signing and brings it back; nothing is signed remotely or instantly.
## The notary's qualification is the Law skill (owner Q18-14, LAW-SKILL; Law.qualified; couriers.json notary: law at a
## provisional level). A notary gains Law by witnessing the signatures and carrying the document home (Law.witnessed, carried).
## An agreement records who holds the document; a signature needs the signer where the document is.
## LIVE (X18-Q13, Build 18): a delivery that asks for a payment above the small-agreement line (CourierService.is_formal) is a
## formal commercial contract; its special delivery is the notary's journey (`CourierService.book_special`), and the records live in
## CourierService.agreements (saved with the courier service). `sign_before_notary` and `bring_home` are the live steps; the
## fee, timing and travel are the delivery's own. CON-01's formal contracts are signed face to face only (contracts.gd,
## `face_to_face`): they are all between people of the village, who can meet.

var couriers: CourierService
var w
var list: Array = []
var next_id := 1


func _init(service: CourierService) -> void:
	couriers = service
	w = service.w


static func cfg() -> Dictionary:
	return CourierService.cfg().contracts


## "small" (binding without signatures) or "formal" (needs every signature): ownership transfers are always formal;
## commercial contracts are formal above small_value (UNAPPROVED provisional threshold).
static func classify(kind: String, value: int) -> String:
	if kind == "ownership":
		return "formal"
	return "formal" if value > int(cfg().small_value) else "small"


func draft(kind: String, parties: Array, value: int, terms := {}) -> Dictionary:
	var cls := classify(kind, value)
	var a := {"id": next_id, "kind": kind, "class": cls, "parties": parties.duplicate(), "value": value, "terms": terms.duplicate(),
		"signatures": {}, "holder": str(parties[0]), "state": "binding" if cls == "small" else "unsigned", "notary": "",
		"fee": 0, "held_at": "", "due": -1.0, "back": -1.0, "history": []}
	next_id += 1
	list.append(a)
	a.history.append([_day(), "drafted (%s)" % cls])
	return a


func _day() -> float:
	return float(w.minutes) / World.DAY if w != null else 0.0


func _pos(ref: String):
	if World.is_player_ref(ref):
		return w.player.pos
	var n = couriers._npc(ref)
	return n.pos if n != null else null


## Whether two parties stand together: alive, the same place, within face_to_face_tiles.
func together(a: String, b: String) -> bool:
	if not couriers.alive(a) or not couriers.alive(b) or couriers.place_of(a) != couriers.place_of(b):
		return false
	var pa = _pos(a)
	var pb = _pos(b)
	if pa == null or pb == null:
		return false
	return (pa as Vector2).distance_to(pb) <= float(cfg().face_to_face_tiles)


## Both parties sign together, face to face. "" when done, else why not.
func sign_face_to_face(a: Dictionary, x: String, y: String) -> String:
	if str(a.class) == "small":
		return "A small agreement needs no signatures."
	if not together(x, y):
		return "You must meet face to face to sign (or send the document with a notary)."
	if str(a.holder) != x and str(a.holder) != y:
		return "The document is not here."
	for who in [x, y]:
		if not (a.parties as Array).has(who):
			return "%s is not a party to it." % who
		a.signatures[who] = _day()
	a.history.append([_day(), "signed face to face"])
	_check_done(a)
	return ""


## A party signs the document it holds (or that a notary holds before it). Remote signing is refused.
func sign(a: Dictionary, who: String) -> String:
	if str(a.class) == "small":
		return "A small agreement needs no signatures."
	if not (a.parties as Array).has(who):
		return "Not a party to it."
	if str(a.holder) != who:
		return "The document is not here: it cannot be signed from afar."
	a.signatures[who] = _day()
	a.history.append([_day(), "%s signed" % who])
	_check_done(a)
	return ""


func notary_qualified(ref: String) -> bool:
	return Law.qualified(w, ref)


## Send the document with a notary courier from `from` (who signs before the notary as it leaves) to `to` in another
## place: it travels there, `to` signs or refuses before the notary, and it travels back. The notarial fee (couriers.json)
## is held at the sender's booth and paid to the notary when the document is back. "" when sent, else why not.
func send_with_notary(a: Dictionary, notary: String, from: String, to: String) -> String:
	if str(a.class) == "small":
		return "A small agreement needs no notary."
	if not notary_qualified(notary):
		return "That courier does not know enough law to notarise (Law %d)." % int(CourierService.cfg().notary.min_level)
	if str(a.holder) != from:
		return "You do not hold the document."
	if not couriers.alive(to):
		return "They cannot be found."
	var b := couriers.booth_of(couriers.place_of(from))
	var fee := int(CourierService.cfg().special.notary_fee)
	if b.is_empty() or couriers.coins_of(from) < fee:
		return "You cannot pay the notary's fee (%d coins) at a booth." % fee
	if not a.signatures.has(from):
		a.signatures[from] = _day()                 # signed before the notary as it leaves
		Law.witnessed(w, notary)
	couriers.add_coins(from, -fee)
	b.escrow = int(b.escrow) + fee
	a.fee = fee
	a.held_at = b.id
	a.notary = notary
	a.holder = notary
	a.home = from
	a.at = couriers.place_of(from)
	a.to = to
	a.arrived = false
	var days := couriers.journey_days(couriers.place_of(from), couriers.place_of(to))
	a.due = _day() + days
	a.back = a.due + days
	a.state = "with_notary"
	a.history.append([_day(), "sent with the notary %s" % notary])
	return ""


## Advance notarised documents to `day`: the notary arrives (the counterparty signs, or refuses when `refuse` is set on
## the agreement), then returns and hands the document back.
func tick(day: float) -> void:
	for a in list:
		if not str(a.state) in ["with_notary", "rejected_returning"]:
			continue
		if not couriers.alive(str(a.notary)):
			interrupt(a, "the notary did not come back")
			continue
		if not bool(a.get("arrived", false)) and day >= float(a.due):
			a.arrived = true
			a.at = couriers.place_of(str(a.to))
			if bool(a.get("refuse", false)) or not couriers.alive(str(a.to)):
				a.state = "rejected_returning"
				a.history.append([day, "%s would not sign" % str(a.to)])
			else:
				a.signatures[str(a.to)] = day
				Law.witnessed(w, str(a.notary))
				a.history.append([day, "%s signed before the notary" % str(a.to)])
		if bool(a.get("arrived", false)) and day >= float(a.back):
			_return(a, day)


func _return(a: Dictionary, day: float) -> void:
	var hb := couriers.booth(str(a.held_at))
	hb.escrow = int(hb.escrow) - int(a.fee)
	couriers.add_coins(str(a.notary), int(a.fee))   # the notary did the work: paid, whatever the answer
	Law.carried(w, str(a.notary))
	a.holder = str(a.home)
	a.at = couriers.place_of(str(a.home))
	if str(a.state) == "rejected_returning":
		a.state = "rejected"
	else:
		a.state = "unsigned"
		_check_done(a)
	a.history.append([day, "the document is back"])


## The journey stops: the document is lost with the notary; the agreement is incomplete; the held fee goes back.
func interrupt(a: Dictionary, why: String) -> void:
	if not str(a.state) in ["with_notary", "rejected_returning"]:
		return
	var hb := couriers.booth(str(a.held_at))
	hb.escrow = int(hb.escrow) - int(a.fee)
	couriers.add_coins(str(a.get("home", a.parties[0])), int(a.fee))
	a.state = "interrupted"
	a.holder = ""
	a.history.append([_day(), "interrupted: " + why])


func _check_done(a: Dictionary) -> void:
	for p in a.parties:
		if not a.signatures.has(p):
			return
	if str(a.holder) in a.parties:
		a.state = "signed"


## The counterparty signs before the notary who stands in front of them (the live path): only while the notary holds the document and
## has arrived, so there is no remote signing. The notary gains Law by witnessing. "" when done.
func sign_before_notary(a: Dictionary, who: String, notary: String, day: float) -> String:
	if str(a.class) == "small":
		return "A small agreement needs no signatures."
	if str(a.notary) != notary or str(a.holder) != notary:
		return "The notary does not hold the document."
	if not (a.parties as Array).has(who):
		return "Not a party to it."
	a.signatures[who] = day
	a.history.append([day, "%s signed before the notary" % who])
	Law.witnessed(w, notary)
	return ""


## The notary hands the document back to the sender: signed by every party it is binding, else it is rejected.
func bring_home(a: Dictionary, sender: String, day: float) -> void:
	a.holder = sender
	if str(a.state) == "rejected_returning":
		a.state = "rejected"
	else:
		a.state = "unsigned"
		_check_done(a)
	a.history.append([day, "the document is back (%s)" % str(a.state)])


func binding(a: Dictionary) -> bool:
	return str(a.state) in ["binding", "signed"]
