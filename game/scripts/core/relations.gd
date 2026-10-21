class_name Relations
extends RefCounted
## Friendship, courting and marriage between people (owner, 2026-10-19: CRT-01..07,
## docs/directives/2026-10-19_courtship_friendship.md). Every pair of people has at most one tie:
##   regard      how well they think of each other (help and gifts raise it) -> befriending
##   attraction  how drawn they are (traditional gifts, time together) -> courting -> a proposal
## The player's tie with a villager is the villager's view of the player. Villagers court each other by
## the same rules (CRT-04), which replaces the old random pairing. Gifts move real goods from the giver to
## the receiver; nothing is made or lost. Every number is in balance.json "relations" (agent proposals,
## provisional).
##
## How ties grow (owner, CRT-08..10: shared experiences start relationships; closeness over time weighs most;
## nothing can be rushed by pressing buttons). Each channel adds regard, and attraction between people who
## may court; every channel has its own limit a day and attraction from all of them together is capped a day
## (attraction_daily_cap), so a relationship needs many days, not one long session:
##   closeness   the player's minutes near a villager, measured as they play (the one whose name is up, the
##               nearest, counts close.focus_factor); villagers' hours near each other (hour): working side
##               by side most, then an evening's company, then simply being about the same place
##   talk        a conversation adds a little, less each time that day (talk_first, talk_more, talk_decay)
##   gifts       once a day; favourites count more (below)
##   help        a request done; defending them (a bandit or a wild beast killed near them, once a day)
##   harm        a crime they see or suffer lowers both
## Days known (days_known: separate days with real contact) gate the stages: court_min_days to court,
## marry_min_days (and propose_min_days of courting) to marry. Ties cool without contact. Villagers only
## court someone they have come to know (interest_at), and a single villager with coins or goods to spare
## seeks that person out and buys gifts (CRT-11, NPCBrain).
##
## Gift tastes (owner: "nothing so weird we need to play guessing games"): food, flowers, ale, clothes
## and jewellery always help; a villager's favourites are what their trade uses (FAVOURITES) and what they
## need now (food when hungry, medicine when hurt), and count favourite_factor times as much.

## What each trade is glad of: what it works with or most enjoys after work. Obvious on purpose.
const FAVOURITES := {
	"miner": ["pickaxe", "ale", "roast_meat"], "laborer": ["bread", "ale", "pottage"], "woodcutter": ["axe", "bread"],
	"carpenter": ["plank", "hammer"], "smith": ["coal", "iron_ore", "iron_bar"], "tanner": ["hide", "rabbit_pelt"],
	"farmer": ["wheat_seed", "carrot_seed", "potato_seed", "plough"], "cook": ["meat", "egg", "milk", "cheese"],
	"tavernkeeper": ["wheat", "apple"], "hunter": ["leather", "roast_meat", "iron_sword"], "merchant": ["copper_ring", "gold_ring", "wool_cloth"],
	"guard": ["iron_helmet", "leather_armor", "iron_sword"], "reeve": ["plain_clothes", "amulet"], "sage": ["flower", "herb_seed"],
}
const MEDICINE := ["linen_bandage", "herbal_poultice", "healing_tonic", "strong_healing_tonic"]

var w
var ties := {}          # "a:b" (a < b; the player is Life.PLAYER_ID) -> tie (see _blank)
var interests := {}     # villager id -> the id of the one they are courting (CRT-04)
var killings := 0       # villagers the player has slain (CRT-12: no one marries a killer lightly)


func _init(world) -> void:
	w = world


static func cfg() -> Dictionary:
	return GameData.b("relations")


static func key(a: int, b: int) -> String:
	return "%d:%d" % [mini(a, b), maxi(a, b)]


static func _blank() -> Dictionary:
	return {"regard": 0.0, "attraction": 0.0, "stage": "", "since": -1, "friends": false, "gift_day": -1, "last": -1, "recent": [],
		"shared_day": -1, "shared_today": 0.0, "talks_today": 0, "hour_key": -1, "days_known": 0, "contact_day": -1,
		"att_day": -1, "att_today": 0.0, "reg_today": 0.0, "near_day": -1, "near_min": 0.0, "near_reg": 0.0, "defend_day": -1,
		"refused": false}


## How well two people click (fixed per pair and world, so the same seed gives the same village): most pairs
## little, a few a great deal (chemistry_min + chemistry_span * u^2). Time together builds attraction in
## proportion; gifts do not depend on it (owner: traditional gifts still get you there).
func chemistry(a: int, b: int) -> float:
	var c := cfg()
	var h := (mini(a, b) * 92821 + maxi(a, b) * 68917 + int(w.seed) * 7919) % 10007
	var u := float(absi(h)) / 10006.0
	return float(c.chemistry_min) + float(c.chemistry_span) * u * u


## The tie between two people (made on first use).
func tie(a: int, b: int) -> Dictionary:
	var k := key(a, b)
	if not ties.has(k):
		ties[k] = _blank()
	return ties[k]


## The tie if there is one, else an empty one that is not stored.
func peek(a: int, b: int) -> Dictionary:
	return ties.get(key(a, b), _blank())


func friends(a: int, b: int) -> bool:
	return bool(peek(a, b).friends)


func player_friend(n: NPC) -> bool:
	return n != null and friends(Life.PLAYER_ID, n.id)


# ---------------------------------------------------------------- gifts ----------------------
## The kind of gift an item makes: food, flower, drink, clothes, jewellery, medicine, useful, or "" (not a gift).
static func gift_kind(id: String) -> String:
	if id == "flower":
		return "flower"
	if id == "ale":
		return "drink"
	if id == "rotten_apple":
		return ""
	var t := str(GameData.item(id).get("type", ""))
	match t:
		"food":
			return "food"
		"armor", "head":
			return "clothes"
		"ring", "amulet":
			return "jewellery"
		"medicine":
			return "medicine"
		"":
			return ""
	return "useful"


## What this villager would most like now: their trade's favourites and what they need (CRT-05).
func favourites(n: NPC) -> Array:
	var out: Array = (FAVOURITES.get(n.job, []) as Array).duplicate()
	if n.hunger < float(GameData.b("eat_below")) or (n.household >= 0 and w.brain.household_food_days(n.household) < 1.0):
		for id in ["bread", "pottage", "roast_meat", "cheese", "apple"]:
			if not out.has(id):
				out.append(id)
	if n.hp < n.max_hp * 0.6:
		for id in MEDICINE:
			if not out.has(id):
				out.append(id)
	return out


## Why a favourite is one, in a few words (the gift list says it: no guessing games).
func favourite_reason(n: NPC, id: String) -> String:
	if (FAVOURITES.get(n.job, []) as Array).has(id):
		return "useful to a %s" % n.job
	if MEDICINE.has(id):
		return "they are hurt"
	return "they are hungry"


## What a gift of `id` from `giver` would do for the tie: {attraction, regard}. Attraction only between
## people who could court (eligible); a second gift the same day does nothing; a gift repeated from the
## last few counts repeat_factor.
func gift_effect(giver: int, n: NPC, id: String) -> Dictionary:
	var c := cfg()
	var kind := gift_kind(id)
	if kind == "":
		return {"attraction": 0.0, "regard": 0.0}
	var t := peek(giver, n.id)
	if int(t.gift_day) == w.day() and giver != n.id:
		return {"attraction": 0.0, "regard": 0.0}
	var fav := favourites(n).has(id)
	var att := float((c.gift_attraction as Dictionary).get(kind, 0.0))
	var reg := float(c.gift_regard) if kind != "useful" or fav else float(c.gift_regard) * 0.5
	if fav:
		att = maxf(att, float(c.gift_attraction.food)) * float(c.favourite_factor)
		reg *= float(c.favourite_factor)
	if (t.recent as Array).has(id):
		att *= float(c.repeat_factor)
		reg *= float(c.repeat_factor)
	if not can_court(giver, n.id):
		att = 0.0
	return {"attraction": att, "regard": reg}


## Give one `id` from `giver` (the player or a villager) to villager `n`. Returns what they say; the goods
## move from the giver's pack to the receiver's (refused when they have no room).
func give(giver: int, n: NPC, id: String) -> String:
	var from: Inventory = w.player.inv if giver == Life.PLAYER_ID else w.npc(giver).inv
	if not from.has(id):
		return ""
	if not n.inv.can_add(id):
		return "I've no room to carry that, but thank you."
	var e := gift_effect(giver, n, id)
	from.remove(id)
	n.inv.add(id)
	if giver == Life.PLAYER_ID:
		w.player.unmark(id, n.id, 1)
	var t := tie(giver, n.id)
	var first_today: bool = int(t.gift_day) != w.day()
	t.gift_day = w.day()
	t.last = w.day()
	(t.recent as Array).append(id)
	while (t.recent as Array).size() > 3:
		(t.recent as Array).pop_front()
	_raise(t, float(e.regard), float(e.attraction))
	w.stat("gifts_given")
	if not first_today:
		return "Another? You're kind, but you've given me something already today."
	if float(e.attraction) >= float(cfg().gift_attraction.food) * float(cfg().favourite_factor):
		return "Oh! Just what I needed. You remembered."
	if float(e.attraction) > 0.0:
		return "For me? That's lovely of you."
	return "Thank you, that's good of you." if float(e.regard) > 0.0 else "I don't know what to do with this."


## Help given (a quest done, work carried, a favour): regard rises.
func helped(helper: int, n: NPC, amount := -1.0) -> void:
	if n == null or not n.alive:
		return
	var t := tie(helper, n.id)
	t.last = w.day()
	_raise(t, float(cfg().help_regard) if amount < 0.0 else amount, 0.0)


## Add to a tie, within the day's limits (regard_daily_cap, attraction_daily_cap; losses are never capped).
## Any gain is contact: the first of a day counts a day known, unless `touch` is false (a few minutes
## nearby are not yet a day's acquaintance: _presence touches once close.known_minutes have passed).
func _raise(t: Dictionary, regard: float, attraction: float, touch := true) -> void:
	var c := cfg()
	var d: int = w.day()
	if int(t.att_day) != d:
		t.att_day = d
		t.att_today = 0.0
		t.reg_today = 0.0
	if regard > 0.0:
		regard = minf(regard, maxf(0.0, float(c.regard_daily_cap) - float(t.reg_today)))
		t.reg_today = float(t.reg_today) + regard
	if attraction > 0.0:
		attraction = minf(attraction, maxf(0.0, float(c.attraction_daily_cap) - float(t.att_today)))
		t.att_today = float(t.att_today) + attraction
	t.regard = clampf(float(t.regard) + regard, 0.0, 100.0)
	t.attraction = clampf(float(t.attraction) + attraction, 0.0, 100.0)
	if touch and (regard > 0.0 or attraction > 0.0):
		_touch(t)


## Real contact today: the first counts one more day known.
func _touch(t: Dictionary) -> void:
	var d: int = w.day()
	t.last = d
	if int(t.contact_day) != d:
		t.contact_day = d
		t.days_known = int(t.days_known) + 1


## Harm the player did a villager or that they saw (CRT-10): regard and attraction fall.
## Harm done to someone reaches those close to them (CRT-12: "stole from their friends or family"): their kin
## (parents, children, siblings, partner) lose kin_harm_share of it, their friends friend_harm_share.
func harmed(n: NPC, amount: float, spread := true) -> void:
	if n == null or n.role == "bandit":
		return
	if n.alive:
		_raise(tie(Life.PLAYER_ID, n.id), -amount, -amount * 0.5, false)
	if not spread:
		return
	var c := cfg()
	for o: NPC in w.npcs:
		if o == n or not o.alive or o.role == "bandit":
			continue
		var share := 0.0
		if o.partner == n.id or Life.kin(o.id, o.mother, o.father, n.id, n.mother, n.father):
			share = float(c.kin_harm_share)
		elif friends(o.id, n.id):
			share = float(c.friend_harm_share)
		if share > 0.0:
			_raise(tie(Life.PLAYER_ID, o.id), -amount * share, -amount * share * 0.5, false)


## The player slew a villager (World.kill): their family and friends turn hard against the player
## (kill_harm through harmed), and it is never forgotten (killings).
func slain_by_player(n: NPC) -> void:
	if n.role == "bandit":
		return
	killings += 1
	harmed(n, float(cfg().kill_harm))


## How the village sees the player (CRT-12): crimes seen in the last notoriety_days, and every villager slain
## counts killing_weight.
func notoriety() -> int:
	var c := cfg()
	var n := killings * int(c.killing_weight)
	for cr in w.player.crimes:
		if int(cr.get("witnesses", 0)) > 0 and w.day() - int(cr.get("day", 0)) <= int(c.notoriety_days):
			n += 1
	return n


## Some people do not mean to marry (unwilling_percent of villagers; fixed per person and world).
func willing(n: NPC) -> bool:
	return (n.id * 7919 + int(w.seed) * 31) % 100 >= int(cfg().unwilling_percent)


## The strongest attraction anyone else courting `n` holds (a rival suitor), else 0.
func rival(n: NPC, suitor: int) -> float:
	var best := 0.0
	for k in ties:
		var t: Dictionary = ties[k]
		if str(t.stage) != "courting":
			continue
		var ids: PackedStringArray = str(k).split(":")
		var x := int(ids[0])
		var y := int(ids[1])
		if (x == n.id and y != suitor) or (y == n.id and x != suitor):
			best = maxf(best, float(t.attraction))
	return best


## Why `n` will not marry `suitor` whatever the courting (CRT-12), or "": they do not mean to marry; the
## suitor is a known killer or criminal (notoriety); they do not think well enough of them (marry_regard;
## harm to them, their family or friends lowers it); someone else courting them is dearer to them.
func refusal(suitor: int, n: NPC) -> String:
	var c := cfg()
	if not willing(n):
		return "I'm fond of you, but I don't mean to marry. Not now, maybe not ever."
	var t := peek(suitor, n.id)
	if suitor == Life.PLAYER_ID:
		if killings > 0:
			return "Marry you? You have killed people of this village. No."
		if notoriety() >= int(c.notoriety_refuse):
			return "Everyone knows what you've been doing. I won't marry a thief."
	if float(t.regard) < float(c.marry_regard):
		return "I don't think well enough of you for that."
	var other := rival(n, suitor)
	if other > float(t.attraction):
		return "I'm sorry. There's someone else I care for more."
	return ""


## The player killed a bandit or a dangerous beast near villagers: those within witness_radius who saw it
## think better of them (once a day each, defend_regard).
func defended(at: Vector2) -> void:
	for n: NPC in w.near(at, float(GameData.b("witness_radius"))):
		if n.role == "bandit" or w.asleep(n):
			continue
		var t := tie(Life.PLAYER_ID, n.id)
		if int(t.defend_day) == w.day():
			continue
		t.defend_day = w.day()
		_raise(t, float(cfg().defend_regard), float(cfg().defend_regard) * 0.3 if can_court(Life.PLAYER_ID, n.id) else 0.0)


# ---------------------------------------------------------------- the player's closeness ------
var _near_acc := 0.0


## As the game runs (World._update_player): every close.sample_minutes the villagers within close.tiles of the
## player (and in the same place) share that time with them; the nearest, whose name is up to talk to,
## counts close.focus_factor.
func player_tick(gm: float) -> void:
	var cl: Dictionary = cfg().close
	_near_acc += gm
	if _near_acc < float(cl.sample_minutes):
		return
	var mins := _near_acc
	_near_acc = 0.0
	var p = w.player
	if not p.alive:
		return
	var best: NPC = null
	var people: Array = []
	for n: NPC in w.near(p.pos, float(cl.tiles)):
		if n.role == "bandit" or w.asleep(n):
			continue
		people.append(n)
		if best == null or n.pos.distance_to(p.pos) < best.pos.distance_to(p.pos):
			best = n
	for n: NPC in people:
		_presence(n, mins, float(cl.focus_factor) if n == best else 1.0)


## `mins` minutes near the player (counting `weight` times: the nearest): close.regard_per_hour and attraction_per_hour, at most
## close.daily_regard a day from closeness; after close.known_minutes in a day the day counts as known.
func _presence(n: NPC, mins: float, weight := 1.0) -> void:
	var cl: Dictionary = cfg().close
	var t := tie(Life.PLAYER_ID, n.id)
	var d: int = w.day()
	if int(t.near_day) != d:
		t.near_day = d
		t.near_min = 0.0
		t.near_reg = 0.0
	var before := float(t.near_min)
	t.near_min = before + mins
	var full := float(cl.regard_per_hour) * mins * weight / 60.0
	var reg := minf(full, maxf(0.0, float(cl.daily_regard) - float(t.near_reg)))
	t.near_reg = float(t.near_reg) + reg
	var att := float(cl.attraction_per_hour) * mins * weight / 60.0 * chemistry(Life.PLAYER_ID, n.id) if can_court(Life.PLAYER_ID, n.id) else 0.0
	_raise(t, reg, att, false)
	if before < float(cl.known_minutes) and float(t.near_min) >= float(cl.known_minutes):
		_touch(t)


# ---------------------------------------------------------------- befriending ----------------
## The player may befriend a villager once help and gifts have raised their regard (CRT-02): no proposal.
func can_befriend(n: NPC) -> bool:
	return n.role != "bandit" and n.role != "child" and not friends(Life.PLAYER_ID, n.id) and float(peek(Life.PLAYER_ID, n.id).regard) >= float(cfg().befriend_at)


func befriend(a: int, b: int) -> void:
	var t := tie(a, b)
	t.friends = true
	t.last = w.day()
	w.stat("friendships")


# ---------------------------------------------------------------- courting -------------------
## Two people who may court: humans of courting age, not kin, neither with a partner elsewhere, either
## sex (owner: "they have to be human for now").
func can_court(a: int, b: int) -> bool:
	if a == b:
		return false
	var pa = Life.parent_of(w, a)
	var pb = Life.parent_of(w, b)
	if pa == null or pb == null or not pa.alive or not pb.alive:
		return false
	for p in [pa, pb]:
		if p is NPC and p.role != "adult":
			return false
		var age := Life.age_years(p.born, w.minutes)
		if age < float(Life.cfg().partner_min_age):
			return false
	if Life.kin(a, pa.mother, pa.father, b, pb.mother, pb.father):
		return false
	for pair in [[pa, b], [pb, a]]:
		var p = pair[0]
		if p.partner >= 0 or p.partner == Life.PLAYER_ID:
			if int(p.partner) != int(pair[1]):
				return false
	return true


## The stage of the player's tie with a villager: "", "courting" or "partners".
func stage(a: int, b: int) -> String:
	var pa = Life.parent_of(w, a)
	if pa != null and int(pa.partner) == b:
		return "partners"
	return str(peek(a, b).stage)


## The player (or a villager) asks to court: accepted once attraction reaches court_at and they have known each
## other on court_min_days separate days.
func ask_court(a: int, n: NPC) -> String:
	var t := tie(a, n.id)
	if not can_court(a, n.id):
		return "That's not for us."
	if a == Life.PLAYER_ID and (killings > 0 or notoriety() >= int(cfg().notoriety_refuse)):
		return "Walk out with you? After what you've done? No."
	if float(t.attraction) < float(cfg().court_at) or int(t.days_known) < int(cfg().court_min_days):
		_raise(t, 0.0, -float(cfg().too_soon_penalty) * 0.5, false)
		return "Court me? We hardly know each other yet."
	t.stage = "courting"
	t.since = w.day()
	t.last = w.day()
	w.stat("courtships")
	return ""


## A proposal (CRT-01): accepted when courting long enough (propose_min_days), known on marry_min_days separate
## days, with attraction at propose_at; asked too early it is declined and cools things a little.
func propose(a: int, n: NPC) -> String:
	var t := tie(a, n.id)
	if str(t.stage) != "courting" or not can_court(a, n.id):
		return "We aren't courting."
	var why := refusal(a, n)
	if why != "":
		w.stat("proposals_refused")
		if not willing(n) or rival(n, a) > float(t.attraction):
			t.stage = ""                              # it ends here: they will not have this suitor
			t.refused = true
		return why
	var days: int = w.day() - int(t.since)
	if float(t.attraction) < float(cfg().propose_at) or days < int(cfg().propose_min_days) or int(t.days_known) < int(cfg().marry_min_days):
		_raise(t, 0.0, -float(cfg().too_soon_penalty), false)
		w.stat("proposals_declined")
		return "It's too soon. Ask me again when we know each other better."
	t.stage = ""
	w.stat("proposals_accepted")
	if a == Life.PLAYER_ID:
		return Life.partner_player(w, n)
	var o: NPC = w.npc(a)
	var together := Life._move_in(w, o, n)
	Life._link_partners(o, n)
	w.stat("partnerships")
	if not together:
		w.stat("partners_apart")
	w.note("%s %s and %s %s are to be partners%s." % [o.name, o.family, n.name, n.family,
			"" if together else ", though they have no room to live together yet"])
	return ""


# ---------------------------------------------------------------- shared experiences ---------
## Every hour (World._on_hour): people awake within shared.near_tiles of each other share the hour: at work
## (both working, the same trade or workplace) work_*, in the evening social_*, otherwise met_*; at most
## shared.daily_cap regard a pair a day. (The player's closeness is measured continuously: player_tick.) Villagers
## who come to think well enough of each other (befriend_at) become friends on their own.
func hour(h: int) -> void:
	var sh: Dictionary = cfg().shared
	var r := float(sh.near_tiles)
	var cell := maxf(1.0, r)
	var grid := {}
	var people: Array = []
	for n: NPC in w.npcs:
		if n.alive and n.role != "bandit" and n.role != "child" and not w.asleep(n):
			people.append(n)
			var c := Vector2i(floori(n.pos.x / cell), floori(n.pos.y / cell))
			if not grid.has(c):
				grid[c] = []
			grid[c].append(n)
	var working := float(h) >= NPCBrain.WORK_START and float(h) < NPCBrain.WORK_END
	var evening := float(h) >= NPCBrain.WORK_END and float(h) < NPCBrain.SLEEP
	for n: NPC in people:
		var c := Vector2i(floori(n.pos.x / cell), floori(n.pos.y / cell))
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				for o: NPC in grid.get(c + Vector2i(dx, dy), []):
					if o.id <= n.id or n.pos.distance_to(o.pos) > r or o.depth != n.depth:     # MIN-A: not through rock
						continue
					var kind := "met"
					if working and n.job != "" and (n.job == o.job or (n.workplace != "" and n.workplace == o.workplace)):
						kind = "work"
					elif evening:
						kind = "social"
					share(n.id, o.id, kind)


## One shared hour between two people (kind work, social or met), counted once per pair an hour. Regard is
## shared.<kind>_regard (the hour nearby is the unit: met_regard 1), at most shared.daily_cap a day; attraction,
## between people who may court, shared.<kind>_attraction times their chemistry (within attraction_daily_cap).
func share(a: int, b: int, kind: String) -> void:
	var sh: Dictionary = cfg().shared
	var t := tie(a, b)
	var hk := int(w.minutes / 60.0)
	if int(t.get("hour_key", -1)) == hk:
		return
	t.hour_key = hk
	var d: int = w.day()
	if int(t.get("shared_day", -1)) != d:
		t.shared_day = d
		t.shared_today = 0.0
		t.talks_today = 0
	var reg := minf(float(sh.get(kind + "_regard", 0.0)), maxf(0.0, float(sh.daily_cap) - float(t.shared_today)))
	t.shared_today = float(t.shared_today) + reg
	t.last = d
	var att := float(sh.get(kind + "_attraction", 0.0)) * chemistry(a, b) if can_court(a, b) else 0.0
	if str(t.stage) == "courting":
		att *= float(sh.courting_factor)              # time together while courting counts for more
	if reg <= 0.0 and att <= 0.0:
		return
	_raise(t, reg, att)
	_befriend_if_close(a, b, t)


func _befriend_if_close(a: int, b: int, t: Dictionary) -> void:
	if a != Life.PLAYER_ID and not bool(t.friends) and float(t.regard) >= float(cfg().befriend_at):
		befriend(a, b)                                  # villagers befriend each other on their own


## The player talked with a villager (CRT-09/10): closeness itself is measured as they stand there
## (player_tick); the conversation adds talk_first the first time that day, talk_more the next and talk_decay
## as much again each time after, so pressing the button over and over adds almost nothing.
func talked(n: NPC) -> void:
	var sh: Dictionary = cfg().shared
	var t := tie(Life.PLAYER_ID, n.id)
	if int(t.get("shared_day", -1)) != w.day():
		t.shared_day = w.day()
		t.shared_today = 0.0
		t.talks_today = 0
	var k := int(t.get("talks_today", 0))
	var reg := float(sh.talk_first) if k == 0 else float(sh.talk_more) * pow(float(sh.talk_decay), k - 1)
	t.talks_today = k + 1
	_raise(t, reg, reg * float(sh.talk_attraction_share) if can_court(Life.PLAYER_ID, n.id) else 0.0)


# ---------------------------------------------------------------- every dawn -----------------
## Ties cool a little without contact; villagers court (CRT-04).
func dawn() -> void:
	var c := cfg()
	var d: int = w.day()
	for k in ties.keys():
		var t: Dictionary = ties[k]
		if int(t.last) < d - 1:
			_raise(t, -float(c.decay_per_day) * 0.5, -float(c.decay_per_day))
	_villagers_court()


## Each unpartnered adult courts one person: takes an interest (npc_court_chance a day) in the one they are
## most drawn to of those they have come to know (attraction at least interest_at; at most partner_max_gap
## years apart; may court), then each day gives them a gift they have (a favourite first, else a
## traditional one) or spends time with them; asks to court at court_at and proposes when it would be accepted.
func _villagers_court() -> void:
	var c := cfg()
	var lo := float(Life.cfg().partner_min_age)
	var hi := float(Life.cfg().partner_max_age)
	var singles: Array = []
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.partner < 0 and n.partner != Life.PLAYER_ID:
			var a := Life.npc_age(w, n)
			if a >= lo and a <= hi:
				singles.append(n)
	for n: NPC in singles:
		if n.partner >= 0:
			continue                                   # paired earlier this dawn
		var target: NPC = w.npc(int(interests.get(n.id, -1))) if interests.has(n.id) else null
		if target != null and not (target.alive and can_court(n.id, target.id)):
			interests.erase(n.id)
			target = null
		if target == null:
			if not willing(n) or w.rng.randf() >= float(c.npc_court_chance):
				continue
			# only someone they have come to know: the strongest attraction of those they may court (CRT-08)
			var best: NPC = null
			var best_a := float(c.interest_at)
			var gap := float(Life.cfg().partner_max_gap)
			for o: NPC in singles:
				if o == n or o.partner >= 0 or not can_court(n.id, o.id):
					continue
				var tt := peek(n.id, o.id)
				var a := float(tt.attraction)
				if not bool(tt.get("refused", false)) and int(tt.days_known) >= int(c.interest_days) and a >= best_a and absf(Life.npc_age(w, n) - Life.npc_age(w, o)) <= gap and (best == null or a > best_a):
					best = o
					best_a = a
			if best == null:
				continue
			interests[n.id] = best.id
			target = best
		var t := tie(n.id, target.id)
		var gift := _gift_from(n, target)
		if gift != "":
			give(n.id, target, gift)                 # time together is counted as it happens (hour)
		if str(t.stage) == "" and float(t.attraction) >= float(c.court_at):
			ask_court(n.id, target)
		elif str(t.stage) == "courting" and float(t.attraction) >= float(c.propose_at) and w.day() - int(t.since) >= int(c.propose_min_days):
			if propose(n.id, target) == "":
				interests.erase(n.id)
				interests.erase(target.id)
			elif str(t.stage) == "":
				interests.erase(n.id)                  # refused for good: they look elsewhere


## A gift a villager has to give: one of the other's favourites, else a traditional gift, else "".
func _gift_from(n: NPC, to: NPC) -> String:
	for id in favourites(to):
		if n.inv.has(id):
			return id
	for id in ["flower", "ale", "apple", "bread", "red_berries", "blueberries"]:
		if n.inv.has(id):
			return id
	return ""


# ---------------------------------------------------------------- saving ---------------------
func to_dict() -> Dictionary:
	var ks: Array = ties.keys()
	ks.sort()
	var out := {}
	for k in ks:
		out[k] = (ties[k] as Dictionary).duplicate(true)
	var ins := {}
	for k in interests:
		ins[str(k)] = int(interests[k])
	return {"ties": out, "interests": ins, "killings": killings}


func load_dict(d: Dictionary) -> void:
	ties.clear()
	interests.clear()
	var ts: Dictionary = d.get("ties", {})
	for k in ts:
		var t := _blank()
		for f in ts[k]:
			t[f] = ts[k][f]
		t.regard = float(t.regard)
		t.attraction = float(t.attraction)
		t.since = int(t.since)
		t.gift_day = int(t.gift_day)
		t.last = int(t.last)
		t.friends = bool(t.friends)
		t.refused = bool(t.refused)
		t.shared_day = int(t.shared_day)
		t.shared_today = float(t.shared_today)
		for f in ["talks_today", "hour_key", "days_known", "contact_day", "att_day", "near_day", "defend_day"]:
			t[f] = int(t[f])
		for f in ["att_today", "reg_today", "near_min", "near_reg"]:
			t[f] = float(t[f])
		ties[str(k)] = t
	killings = int(d.get("killings", 0))
	var ins: Dictionary = d.get("interests", {})
	for k in ins:
		interests[int(k)] = int(ins[k])
