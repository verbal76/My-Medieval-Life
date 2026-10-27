class_name NetSync
extends RefCounted
## Multiplayer Batch C (docs/multiplayer/BATCH_C.md, "The guest's copy of the world"): the host keeps each guest's copy of the shared
## world in step, section by section of the save. The host never sends a section the guest already has: it hashes each section of
## World.to_dict and sends those whose hash changed since it last sent them to that guest, at once after applying a request of that
## guest and then every SYNC_SECONDS. The guest adopts each section into the world it shows, in place (adopt): the same objects stay
## (the views hold them), the records take the host's values. The guest's copy is never simulated and never saved; what it shows of
## the shared world is the host's. Villagers' places, facing and animation come in the faster snapshots (NetSession.s_npcs) and are
## kept; the other players' records are their public ones (NetSession.public_player); the guest's own character comes whole
## (NetSession.s_self, Main.adopt_own_state).

const SYNC_SECONDS := 3.0
## The villagers' records change every moment (hunger, plans) and are the largest section: on the timer they go every NPCS_EVERY-th
## time only; after a guest's own request they go at once (a trade, a gift, a blow changes a villager it then shows).
const NPCS_EVERY := 5
## The sections a guest's copy takes from the host. Not here: the map and its generator data (the same seed on both), the
## other players' private records, the overworld, the settlements and couriers' books, the judgment store (read by villagers
## only, on the host), identity and the clock (s_npcs). Build 21: "fauna", the animals' records (health, hunger, which pen or
## wood) and the pens (trough, keeper, tenant, products, the players' own pens); the animals' places, facing and animation come
## in the faster snapshots (NetSession.s_animals), their births and deaths at once (NetSession.s_fauna_life).
const KEYS := ["buildings", "stalls", "plots", "fields", "households", "loot", "containers", "trees", "plants", "deposits", "boulders",
	"treasury", "granary", "vacancies", "wage_offers", "manor_orders", "coin_sources", "log", "carts", "relations", "credit", "justice",
	"contracts", "quest_offers", "feast", "farm", "farm_plots", "chapel", "chests", "manor_work", "npcs", "player_offers", "fauna"]
## The sections sent on the timer only every NPCS_EVERY-th time (their live parts come in the snapshots); at once after a request.
const SLOW := ["npcs", "fauna"]
## NPC fields the snapshots carry, so a section update leaves them as the snapshots have them.
const NPC_LIVE := ["pos", "facing", "anim"]


## Host: {key: hash} of the sections of `d` (a World.to_dict).
static func digest(d: Dictionary) -> Dictionary:
	var out := {}
	for k in KEYS:
		if d.has(k):
			out[k] = hash(JSON.stringify(d[k], "", true))
	return out


## Host: the sections of `d` whose hash differs from `sent` (updated to the new hashes). {} when nothing changed.
static func changed(d: Dictionary, sent: Dictionary, skip: Array = []) -> Dictionary:
	var now := digest(d)
	var out := {}
	for k in now:
		if skip.has(k):
			continue
		if int(sent.get(k, 0)) != int(now[k]):
			out[k] = d[k]
			sent[k] = now[k]
	for k in sent.keys():
		if not now.has(k):
			out[k] = null                             # an optional section that emptied (credit, justice, offers): the copy empties it too
			sent.erase(k)
	return out


## Guest: take the host's sections into the world shown here, in place. JSON round trip first, as a save is read.
static func adopt(w: World, sections: Dictionary) -> void:
	var d: Dictionary = JSON.parse_string(JSON.stringify(sections))
	for k in d.keys():
		if d[k] == null:
			d[k] = {}                                 # an optional section the host no longer writes: empty
	for k in d:
		match k:
			"buildings":
				var was := {}
				for id in w.buildings:
					was[id] = World.is_built(w.buildings[id])
				w.buildings = d.buildings
				var ids: Array = w.buildings.keys()
				ids.sort()
				for id in ids:
					if World.is_built(w.buildings[id]) and not bool(was.get(id, false)):
						w.building_added.emit(w.buildings[id])
			"stalls":
				w.stalls = d.stalls
			"plots":
				w.plots = d.plots
			"fields":
				w.fields = d.fields
				for f in w.fields:
					w._field_tiles(f)
			"households":
				w.households.clear()
				for h in d.households:
					var c: Dictionary = h.duplicate(true)
					c.pantry = Inventory.from_dict(h.pantry)
					w.households.append(c)
			"loot":
				w.loot.clear()
				for l in d.loot:
					w.loot.append({"pos": Vector2(l.pos[0], l.pos[1]), "inv": Inventory.from_dict(l.inv), "coins": int(l.coins), "from": l.from, "t": float(l.get("t", w.minutes))})
					if int(l.get("level", 0)) != 0:
						w.loot[w.loot.size() - 1].level = int(l.level)
			"containers":
				for s in d.containers:
					var c: Dictionary = w.container(str(s.id))
					if not c.is_empty() and c.kind == "table":
						c.inv = Inventory.from_dict(s.get("inv", {}))
						c.keeper = int(s.get("keeper", -1))
			"trees":
				for st in d.trees:
					var t: Dictionary = w.tree_at(Vector2i(int(st.x), int(st.y)))
					if t.is_empty() or int(t.x) != int(st.x) or int(t.y) != int(st.y):
						continue
					var moved := str(t.get("state", "")) != str(st.get("state", "")) or str(t.get("species", "")) != str(st.get("species", ""))
					for f in st:
						if not f in ["x", "y", "trunk", "top", "bottom"]:
							t[f] = st[f]
					if moved:
						w.tree_changed.emit(t)
			"plants":
				for sp in d.plants:
					var pl: Dictionary = w.plant_at(Vector2i(int(sp.x), int(sp.y)))
					if pl.is_empty():
						continue
					var was_ripe := str(pl.state) == "ripe"
					pl.state = str(sp.state)
					pl.regrow = float(sp.regrow)
					if was_ripe != (str(pl.state) == "ripe"):
						w.tile_changed.emit(Vector2i(int(pl.x), int(pl.y)), World.PLANT_LAYER, int(pl.tile) if str(pl.state) == "ripe" else -1)
			"deposits":
				for sd in d.deposits:
					var dp: Dictionary = w.deposit_at(Vector2i(int(sd.x), int(sd.y)), int(sd.get("level", 0)))
					if not dp.is_empty():
						dp.amount = int(sd.amount)
			"boulders":
				for sb in d.boulders:
					for b in w.boulders:
						if int(b.x) == int(sb[0]) and int(b.y) == int(sb[1]):
							b.amount = int(sb[2])
			"treasury":
				w.treasury = int(d.treasury)
			"granary":
				w.granary = Inventory.from_dict(d.granary)
			"vacancies":
				w.vacancies = d.vacancies
			"wage_offers":
				w.wage_offers = d.wage_offers
			"manor_orders":
				w.manor_orders = d.manor_orders
			"coin_sources":
				w.coin_sources = int(d.coin_sources)
			"log":
				w.log_lines = d.log
			"carts":
				w.carts.load_dict(d.carts)
			"relations":
				w.relations.load_dict(d.relations)
			"credit":
				w.credit.load_dict(d.credit)
			"justice":
				w.justice.load_dict(d.justice)
			"contracts":
				w.contracts.load_dict(d.contracts)
			"quest_offers":
				w.quests.load_dict(d.quest_offers)
			"feast":
				w.feast.load_dict(d.feast)
			"farm":
				w.farm.load_dict(d.farm)
			"farm_plots":
				w.farm_plots.load_dict(d.farm_plots)
			"chapel":
				if not (d.chapel as Dictionary).is_empty():
					w.chapel.load_dict(d.chapel)
			"chests":
				w.chests.load_dict(d.chests)
			"manor_work":
				w.manor_work.load_dict(d.manor_work)
			"npcs":
				_adopt_npcs(w, d.npcs)
			"fauna":
				if not (d.fauna as Dictionary).is_empty():
					adopt_fauna(w, d.fauna)
			"player_offers":
				w.offers = []
				for o in (d.player_offers as Dictionary).get("list", []):
					w.offers.append(World.offer_from_dict(o))


static var _npc_props: Array = []


## Villagers in place: each existing NPC object takes the host's record but keeps its place, facing and animation (the snapshots'); a
## villager the guest has not seen yet (a birth, a newcomer) is added (Main gives it a sprite when it is first seen).
static func _adopt_npcs(w: World, list: Array) -> void:
	if _npc_props.is_empty():
		for pr in NPC.new().get_property_list():
			if int(pr.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE and not str(pr.name) in NPC_LIVE:
				_npc_props.append(str(pr.name))
	for nd in list:
		var fresh := NPC.from_dict(nd)
		var n: NPC = w.by_id.get(fresh.id)
		if n == null:
			w.npcs.append(fresh)
			w.by_id[fresh.id] = fresh
			continue
		for k in _npc_props:
			n.set(k, fresh.get(k))


## Build 21: the host's animals and pens in place (the same Animal objects stay: the sprites hold them). An animal near the local
## player keeps the place, facing and animation the snapshots gave it (NetSession.s_animals); one farther off takes the host's
## place. An animal the host has and this copy lacks is added (a birth, a spawn), one the host no longer has is removed (a death,
## a sale, a despawn); a guest never simulates them (the guest's World.update never runs).
static func adopt_fauna(w: World, d: Dictionary) -> void:
	var f: Fauna = w.fauna
	f.next_id = int(d.get("next_id", f.next_id))
	for rec in d.get("player_pens", []):
		var id := str(rec.id)
		if f.pens.has(id):
			(f.pens[id] as Dictionary).merge(rec, true)
		else:
			f.pens[id] = rec.duplicate(true)
	var ps: Dictionary = d.get("pens", {})
	for id in ps:
		if f.pens.has(id):
			var pen: Dictionary = f.pens[id]
			pen.trough = int(ps[id].trough)
			pen.owner = str(ps[id].get("owner", pen.get("owner", "manor")))
			pen.tenant = str(ps[id].get("tenant", pen.get("tenant", "")))
			pen["products"] = (ps[id].get("products", {}) as Dictionary).duplicate()
	var host := {}
	for ad in d.get("animals", []):
		host[int(ad.id)] = ad
	for a: Animal in f.animals.duplicate():
		if not host.has(a.id):
			f.remove(a)
	var near := NetProtocol.NPC_RANGE
	for aid in host:
		var fresh := Animal.from_dict(host[aid])
		var a := f.by_id(aid)
		if a == null:
			add_animal(w, fresh)
			continue
		for k in ["species", "skin", "sex", "born", "area", "alive", "hp", "hunger", "next_birth", "next_product", "dest", "settle_by", "origin"]:
			a.set(k, fresh.get(k))
		if a.pos.distance_to(w.player.pos) > near:
			a.pos = fresh.pos                         # out of the snapshots' reach: the host's place, standing
			a.moving = false


## An animal the host made, put in this copy's list in id order (Fauna keeps its animals ordered by id).
static func add_animal(w: World, a: Animal) -> void:
	if w.fauna.by_id(a.id) != null:
		return
	w.fauna.animals.append(a)
	if w.fauna.animals.size() > 1 and (w.fauna.animals[-2] as Animal).id > a.id:
		w.fauna.animals.sort_custom(func(x: Animal, y: Animal): return x.id < y.id)
