class_name EconomyFoundation
extends RefCounted
## Expansion 20 (Living Economy), LE-01: the single attach point of the foundation records (EconActor resolver,
## EconReservations, EconEvents). World calls attach() twice only: at the end of setup() and in load_dict(). With
## game/data/economy.json "enabled": false (the shipped state) attach() returns null: nothing is constructed, no
## save key is written, and no live code path references these classes. A test can switch it on with set_override().
## Format "mml-economy/1": see docs/expansion20/LE01_DATA_CONTRACTS.md and LE01_IMPLEMENTATION.md.
##
## LE-01 model (needs, offers, knowledge, contract links) is built here too. Two live calls reach it, each guarded by
## `World.economy != null` so they cost nothing and do nothing while disabled: World.trade -> on_trade (after the sale:
## an event, what the two parties learned by dealing, their needs marked for re-derivation) and World._new_day -> dawn
## (offers, reservations and contract links expire or follow their contracts; contract terms learned; dirty needs
## re-derived within a budget). The model OBSERVES: it moves no coin or good, draws no random number, writes no game
## state outside its own records, and nothing in live play reads it to decide.
##
## LE-02 market (EconMarket, docs/expansion20/LE02_IMPLEMENTATION.md): built with the model; it ACTS only with economy.json
## "market": {"drive": true} (absent: false, so the LE-01 observers stay observers). Then two more guarded live calls reach it:
## Relations.share -> on_encounter (two villagers spend an hour together: they see each other's offers and may bargain, settled
## by World.trade) and JudgmentStore._meet_now -> on_meeting (the gossip's meetings: prices genuinely learned pass by word of
## mouth); and dawn() runs the market's dawn after the model's (reviews, bids from needs, asks, direct dialogue that opens CON-01
## contracts, renegotiation on a contract's last day).

const KEY := "economy"
const PATH := "res://data/economy.json"
static var _override := {}
static var _cfg := {}


var actors: EconActor
var reservations: EconReservations
var events: EconEvents
var needs: EconNeeds
var offers: EconOffers
var knowledge: EconKnowledge
var contract_links: EconContractLinks
var market: EconMarket
var claims: EconClaims            # LE-03: the one validation of what an actor may part with (World.trade and the village paths)
var rentals: EconRentals          # LE05-RENTAL: tools lent against a deposit (acts only with market.drive and market.rental)
var repairs: EconRepairs          # LE-05 paid repair: a smith mends another's tool for coins (acts only with market.drive and market.paid_repair)
var route_risk: EconRouteRisk     # LE-05 route risk: losses on the road by route (a record only; priced with market.drive and market.route_risk)
var contract_cursor := 0          # the highest CON-01 contract id whose terms the two parties have been told (knowledge "contract")


static func config() -> Dictionary:
	if not _override.is_empty():
		return _override
	return file_config()


## The installed settings (game/data/economy.json), whatever a test override says.
static func file_config() -> Dictionary:
	if _cfg.is_empty():
		var f := FileAccess.open(PATH, FileAccess.READ)
		_cfg = JSON.parse_string(f.get_as_text()) if f != null else {"enabled": false}
		if not _cfg is Dictionary:
			_cfg = {"enabled": false}
	return _cfg


## Tests only: replace the file's settings (e.g. {"enabled": true}); {} restores the file.
static func set_override(cfg: Dictionary) -> void:
	_override = cfg


## Tests only: the installed settings with the switch off, so a test of the economy-off path tests it whatever the
## installed switch says (LE-07: the shipped default is the one thing that changes on activation).
static func off_config() -> Dictionary:
	var c: Dictionary = file_config().duplicate(true)
	c.enabled = false
	return c


static func enabled() -> bool:
	return bool(config().get("enabled", false))


## null when disabled. `saved` is World's "economy" save key (absent: empty records).
static func attach(world: World, saved := {}) -> EconomyFoundation:
	if not enabled():
		return null
	var cfg := config()
	var f := EconomyFoundation.new()
	f.actors = EconActor.new(world)
	f.events = EconEvents.new(cfg.get("events", {}))
	f.reservations = EconReservations.new(f.actors, cfg.get("reservations", {}))
	f.reservations.events = f.events
	f.actors.reservations = f.reservations
	f.needs = EconNeeds.new(f.actors, cfg.get("needs", {}))
	f.offers = EconOffers.new(f.reservations, cfg.get("offers", {}))
	f.offers.events = f.events
	var kcfg: Dictionary = (cfg.get("knowledge", {}) as Dictionary).duplicate()
	kcfg["min_reliability"] = (cfg.get("market", {}) as Dictionary).get("min_reliability", 0.25)     # LE-06: the market's action threshold
	f.knowledge = EconKnowledge.new(f.actors, kcfg)
	f.offers.knowledge = f.knowledge
	f.contract_links = EconContractLinks.new(f.reservations)
	f.reservations.load_dict(saved.get("reservations", {}))
	f.events.load_dict(saved.get("events", {}))
	f.needs.load_dict(saved.get("needs", {}))
	f.offers.load_dict(saved.get("offers", {}))
	f.knowledge.load_dict(saved.get("knowledge", {}))
	f.contract_links.load_dict(saved.get("contracts", {}))
	f.contract_cursor = int(saved.get("contract_cursor", 0))
	f.market = EconMarket.new(f, world, cfg.get("market", {}))
	f.market.load_dict(saved.get("market", {}))
	f.claims = EconClaims.new(f)
	f.claims.load_dict(saved.get("claims", {}))
	f.rentals = EconRentals.new(f, world, cfg.get("market", {}))
	f.rentals.load_dict(saved.get("rentals", {}))
	f.repairs = EconRepairs.new(f, world, cfg.get("market", {}))
	f.repairs.load_dict(saved.get("repairs", {}))
	f.route_risk = EconRouteRisk.new(cfg.get("market", {}))
	f.route_risk.load_dict(saved.get("route_risk", {}))
	return f


func is_empty() -> bool:
	return reservations.is_empty() and events.is_empty() and needs.is_empty() and offers.is_empty() and knowledge.is_empty() \
			and contract_links.is_empty() and contract_cursor == 0 and market.is_empty() and claims.is_empty() and rentals.is_empty() \
			and repairs.is_empty() and route_risk.is_empty()


## World.trade, after a completed sale (observed only). Both parties learn of each other by the dealing; an event is noted;
## the parties and their households are marked for their needs to be derived again.
func on_trade(buyer: Object, seller: Object, item: String, qty: int, total: int) -> void:
	var b := Contracts.ref_of(buyer)
	var s := Contracts.ref_of(seller)
	var w := actors.w
	var each := int(total / qty) if qty > 0 else 0
	# the till the proceeds go into (a storefront's or a trade counter's, BusinessMoney.after_trade, which runs after this):
	# named in the event so the model can follow the coins to the till and its owner (LE-01 till ownership)
	var till := w.business.money.till_ref_for(seller) if w.business != null else ""
	events.record_at(w.day(), int(fmod(w.minutes, World.DAY)), "trade", b, s, item, qty, total, ("till:" + till) if till != "" else "")
	if till != "":
		needs.mark(actors.controller(till))
	knowledge.learn(b, s, item, EconKnowledge.SELLS, each, "dealing")
	knowledge.learn(s, b, item, EconKnowledge.BUYS, each, "dealing")
	for r in [b, s]:
		needs.mark(r)
		needs.mark(actors.household_of(r))


## World._new_day (observed only): offers, then reservations, expire; links follow their contracts; new contracts' terms are
## learned by their two parties; dirty needs are re-derived within the budget.
func dawn(day: int) -> void:
	offers.expire_due(day)
	reservations.expire_due(day)
	knowledge.forget_unusable(day)     # LE-06: entries past the age any decision could still act on (bounded save)
	claims.reconcile_all()        # LE-03: offers whose backing went by an outflow nobody refuses (tax, eating, crafting) are cut
	contract_links.sweep()
	var cs: Contracts = actors.w.contracts
	if cs != null:
		var top := contract_cursor
		for c in cs.list:
			var id := int(c.id)
			if id <= contract_cursor:
				continue
			top = maxi(top, id)
			if str(c.get("kind", "goods")) == "service":
				continue
			knowledge.learn(str(c.buyer), str(c.seller), str(c.item), EconKnowledge.SELLS, int(c.price_each), "contract")
			knowledge.learn(str(c.seller), str(c.buyer), str(c.item), EconKnowledge.BUYS, int(c.price_each), "contract")
			for r in [str(c.buyer), str(c.seller)]:
				needs.mark(r)
		contract_cursor = top
	needs.refresh()
	route_risk.dawn(day)          # LE-05 route risk: days that left the window are dropped
	market.dawn(day)
	if rentals.active():
		rentals.dawn(day)             # LE05-RENTAL: fees billed, tools given back at the term's end, missing ones settled
	if repairs.active() or not repairs.records.is_empty():
		repairs.dawn(day)            # LE-05 paid repair: overdue orders refunded, today's candidates weigh an order


## Relations.share (LE-02): villagers `a` and `b` spent an hour together. Nothing unless the market drives.
func on_encounter(a: int, b: int) -> void:
	market.on_encounter(a, b)


## JudgmentStore._meet_now (LE-02, OD-LE-10): a gossip meeting between `a` and `b`. Nothing unless the market drives.
func on_meeting(a: int, b: int) -> void:
	market.on_meeting(a, b)


## {} when there is nothing to save (World then writes no key).
func to_dict() -> Dictionary:
	var d := {}
	if not reservations.is_empty():
		d["reservations"] = reservations.to_dict()
	var e := events.to_dict()
	if not events.is_empty() and not e.is_empty():
		d["events"] = e
	if not needs.is_empty():
		d["needs"] = needs.to_dict()
	if not offers.is_empty():
		d["offers"] = offers.to_dict()
	if not knowledge.is_empty():
		d["knowledge"] = knowledge.to_dict()
	if not contract_links.is_empty():
		d["contracts"] = contract_links.to_dict()
	if contract_cursor != 0:
		d["contract_cursor"] = contract_cursor
	if not market.is_empty():
		d["market"] = market.to_dict()
	if not claims.is_empty():
		d["claims"] = claims.to_dict()
	if not rentals.is_empty():
		d["rentals"] = rentals.to_dict()
	if not repairs.is_empty():
		d["repairs"] = repairs.to_dict()
	if not route_risk.is_empty():
		d["route_risk"] = route_risk.to_dict()
	return d


# ---------------------------------------------------------------- activation (X20-ACTIVATION-AUTHORITY) ------------------
## Owner 2026-10-31 (docs/directives/2026-10-31_doc_recon_review_decisions.md s.2): "Prepare the activation mechanism and validation
## evidence, but wait for my explicit authorization before enabling it in the normal game." The switch is economy.json "enabled"
## (shipped false); this section is the mechanism and its checks only, never a decision to enable (docs/expansion20/ACTIVATION.md).
##   New game, switch on: attach() builds empty records; the model derives needs from the world as it is.
##   Existing save without an "economy" section (every save_version 23 save written with the switch off), switch on: the same as a
##     new game from that day, attach(world, {}): nothing to migrate, nothing dropped or rewritten, no save_version change.
##   Save with a section, switch off: the section is PARKED (World.economy_foreign, D2): written back unchanged, never acted on; the
##     coins its open rentals and paid-repair orders hold in escrow stay counted (parked_coins, World.total_coins), so the ledger is
##     exact. A rented tool stays with its renter; nothing acts on the records until the switch is on again.
##   Switch on again: attach() reads the parked section; open rentals and orders resume where they stood.

## The coins a saved (or parked) "economy" section holds in escrow: open rentals' deposits and open paid-repair orders.
static func parked_coins(saved: Dictionary) -> int:
	if saved.is_empty():
		return 0
	var k := 0
	for r in (saved.get("rentals", {}) as Dictionary).get("records", []):
		if str(r.get("state", "")) == EconRentals.OPEN:
			k += int(r.get("deposit", 0))
	return k + EconRepairs.saved_escrow(saved.get("repairs", {}))


## The state of the switch for `world` (the activation checklist, the LE-07 gates): {enabled, attached, parked, parked_coins,
## open_rentals, open_repairs, flags}. Read only.
static func activation_state(world: World) -> Dictionary:
	var m: Dictionary = config().get("market", {})
	var f: EconomyFoundation = world.economy
	return {"enabled": enabled(), "attached": f != null, "parked": f == null and not world.economy_foreign.is_empty(),
		"parked_coins": parked_coins(world.economy_foreign) if f == null else 0,
		"open_rentals": f.rentals.open_records().size() if f != null else 0,
		"open_repairs": f.repairs.open_records().size() if f != null else 0,
		"flags": {"drive": bool(m.get("drive", false)), "rental": bool(m.get("rental", false)), "paid_repair": bool(m.get("paid_repair", false)),
			"negotiated_wages": bool(m.get("negotiated_wages", false)), "services": bool(m.get("services", false)),
			"route_risk": bool(m.get("route_risk", false))}}
