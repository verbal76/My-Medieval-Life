class_name Employment
extends RefCounted
## Permanent employment: one framework across the professions that have real work systems.
## EMP-PERM-01 (owner B18-DP-01, 2026-10-23) started it with the player's miner; B25-BIZ-D2 and B25-BIZ-D4 (owner, 2026-11-01,
## docs/directives/2026-11-01_business_ownership_employment_final_decisions.md; specification
## docs/expansion20/BUSINESS_OWNERSHIP.md sections 3 and 5) make it general: "A profession determines what work someone
## performs. Employment determines whom they work for and how they are compensated."
##
## A record {npc, employer, role, wage, since, paid_day, owed, account?}: the employer is a player ("player", "player:<pid>")
## or a villager business ("venture:<building id>", Ventures). It lasts from day to day until the employer dismisses the
## employee, the employee resigns (_resign), the wage cannot be paid, or either side is gone. Distinct from a day's building
## helper (Construction.hire), a counter attendant (Business.hire, itself a permanent wage employment of a premises, left as
## it is), a contract (CON-01/02) and an independent craftsperson working a venture's benches with leave (a venture's hands).
##
## The work (WORK): each role is done by the work behaviour the game already has for it; nothing is invented.
##   mine   the village's seams (World.nearest_seam, NPCBrain.seam_steps, World.work_mine)       -> owed, carried to the store
##   chop   the nearest grown tree (World.nearest_tree, World.fell, World.work_felled)            -> owed, carried to the store
##   farm   the employer's farmland (FarmPlots.plan_hired: harvest, sow, clear, plough)          -> the employer's store
##   build  the employer's building site (Construction.plan_helper, an unpaid day contract)      -> the site
##   craft  a player employer: the real recipe (World.work_craft) at a station the employer holds, the materials taken from
##          the employer's store as the work is done and the goods put back (BusinessWorks' rule); a villager business: the
##          trade's own working day (NPCBrain._plan_job) at the business's stations, its materials bought and its goods sold
##          with the business's money (Ventures: budget, fund, on_sale)
## What an employee makes belongs to the employer; what they carry of it is counted in `owed` and handed over (_hand_over).
## Wage: market_wage, the labour market's own reading (never below the manor's posted day wage), paid each dawn from the
## employer's account (a player's purse, or the till of a premises the player names in `account`; a venture's till), the
## first on hiring. An unpaid wage ends the employment: a business cannot keep people it cannot pay (WDR-022: no rescue).
## Who may be employed: an adult of a household, free of other obligations, without a trade of their own (Construction
## .HIRABLE) or of the role's own trade, willing (JudgmentLive.work_refusal). Their job becomes the role's (NPCBrain._change_job;
## skills and experience are kept), and the morning labour market leaves them where they are (NPCBrain.seek_work).
## Verbs employ / dismiss go through World.mirror and NetActions.VERBS (host validation).
## Saved under the optional key "employment" {list: [...]} (older saves: none; a record without a wage keeps the old 10).

const WORK := {"miner": "mine", "woodcutter": "chop", "farmer": "farm", "builder": "build",
	"smith": "craft", "carpenter": "craft", "tanner": "craft", "cook": "craft", "stonecutter": "craft"}
const ROLES := ["miner", "woodcutter", "farmer", "builder", "smith", "carpenter", "tanner", "cook", "stonecutter"]
const ROLE_JOB := {"builder": "laborer"}     # a role whose trade is named otherwise
const ORES := ["iron_ore", "coal", "copper_ore", "stone", "gold_ore"]

var w: World
var list: Array = []


func _init(world: World) -> void:
	w = world


static func cfg() -> Dictionary:
	return GameData.b("employment")


## The wage of a record saved without one (EMP-PERM-01's provisional 10; kept for older saves only).
static func wage() -> int:
	return int(cfg().get("wage", 10))


static func job_for(role: String) -> String:
	return str(ROLE_JOB.get(role, role))


static func behaviour(role: String) -> String:
	return str(WORK.get(role, ""))


func is_empty() -> bool:
	return list.is_empty()


func record_of(n: NPC) -> Dictionary:
	if n == null:
		return {}
	for r in list:
		if int(r.npc) == n.id:
			return r
	return {}


func is_employed(n: NPC) -> bool:
	return not record_of(n).is_empty()


## The employees of `ref` (a player or a "venture:" reference), in hiring order.
func of_employer(ref: String) -> Array:
	return list.filter(func(r: Dictionary) -> bool: return str(r.employer) == ref)


# ---------------------------------------------------------------- the wage ------------------------
## B25-BIZ-D4: the day's wage the labour market sets for `role` now: a skilled trade's place pay (NPCBrain.skilled_place:
## its earnings shared among one more worker), else the trade's average earnings over the last five days among those with a
## record of them; never below the manor's posted day wage (NPCBrain.manor_hand_wage, which hiring competition raises).
func market_wage(role: String) -> int:
	var job := job_for(role)
	var pay := 0.0
	if NPCBrain.SKILLED.has(job):
		pay = float(w.brain.skilled_place(job).pay)
	else:
		var sum := 0.0
		var k := 0
		for o: NPC in w.npcs:
			if o.alive and o.role == "adult" and o.job == job and o.income_days.size() >= 3:
				sum += o.avg_income(5)
				k += 1
		pay = sum / k if k > 0 else 0.0
	return maxi(int(w.brain.manor_hand_wage()), ceili(pay))


## The wage `n` asks for `role`: the market wage, or, with the Living Economy's negotiated wages on, what they bargain for
## from it (EconMarket.wage_bargain, the rule of the manor's jobs and building helpers).
func asking(n: NPC, role: String) -> int:
	var base := market_wage(role)
	if n == null or w.economy == null or not w.economy.market.drive or not bool(w.economy.market.p("negotiated_wages", false)):
		return base
	return w.economy.market.wage_bargain(base, World.npc_ref(n.id))


# ---------------------------------------------------------------- who may be employed ------------
## What else `n` is bound to now ("" nothing): employment cannot silently override another obligation.
func obligation(n: NPC) -> String:
	if is_employed(n):
		return "%s works for %s already." % [n.name, "you" if w.is_acting_ref(str(record_of(n).employer)) else "someone"]
	if n.job == "manor_hand" and not w.manor_work.job_of("npc:%d" % n.id).is_empty():
		return "%s is doing a job for the manor." % n.name
	var c: Dictionary = w.construction.contract_of(n)
	if not c.is_empty() and not bool(c.get("employment", false)):
		return "%s is hired for building work today." % n.name
	if w.business.is_attendant(n):
		return "%s minds a counter already." % n.name
	if not w.contracts.open_of(World.npc_ref(n.id), "seller").is_empty():
		return "%s has a contract to finish." % n.name
	if not w.ventures.kept_by(n).is_empty():
		return "%s keeps a business of their own." % n.name
	return ""


## Why `employer` (the acting player when "") cannot employ `n` in `role`, "" when they can (the terms are asked in employ).
func refusal(n: NPC, role := "miner", employer := "") -> String:
	if employer == "":
		employer = w.acting_ref()
	if not WORK.has(role):
		return "There is no such work to offer."
	if n == null or not n.alive or n.role != "adult" or n.household < 0:
		return "They cannot work for you."
	if not (n.job in Construction.HIRABLE or n.job == job_for(role)):
		return "%s has work of their own." % n.name
	var ob := obligation(n)
	if ob != "":
		return ob
	if employer.begins_with("venture:"):
		var b: Dictionary = w.ventures.by_ref(employer)
		if b.is_empty() or str(b.venture.trade) != role:
			return "The business has no such work."
		return ""
	var how := behaviour(role)
	if w.construction.store_of(employer) == null:
		return "You need a home with a chest to keep what they make."
	if how == "farm" and w.farm_plots.plots_of(employer).is_empty():
		return "You hold no farmland for them to work."
	if how == "craft" and employer_stations(employer, role).is_empty():
		return "You hold no %s for them to work at." % " or ".join(NPCBrain.TRADE_STATIONS.get(role, []))
	return ""


## The recipes a crafter of `role` can be set to make for `employer`: those of the trade made at a station the employer holds,
## in id order (the catalogue weapons are made to order, never by an employee's routine).
func makes(role: String, employer := "") -> Array:
	if employer == "":
		employer = w.acting_ref()
	var kinds := {}
	for st in employer_stations(employer, role):
		kinds[str(w.stations[st].type)] = true
	var out := []
	var ids: Array = GameData.recipes.keys()
	ids.sort()
	for r in ids:
		if kinds.has(str(GameData.recipes[r].station)) and not GameData.is_catalogue_recipe(r):
			out.append(r)
	return out


func make_refusal(role: String, make: String) -> String:
	if make == "":
		return "Choose what they are to make."
	if not makes(role).has(make):
		return "Your stations do not make that."
	return ""


## The acting player tells their crafter `n` what to make from now on. "" when done.
func set_make(n: NPC, make: String, actor: PlayerState = null) -> String:
	if w.mirrors():
		return w.mirror("employment.set_make", set_make.bind(n, make), [n, make])
	if actor != null and actor != w.player:
		return w.as_actor(actor, set_make.bind(n, make))
	var rec := record_of(n)
	if rec.is_empty() or not w.is_acting_ref(str(rec.employer)) or behaviour(str(rec.role)) != "craft":
		return "%s does not make things for you." % (n.name if n != null else "They")
	var why := make_refusal(str(rec.role), make)
	if why != "":
		return why
	rec.make = make
	n.plan.clear()
	return ""


## The stations of the trade `role` in buildings `employer` holds, in id order.
func employer_stations(employer: String, role: String) -> Array:
	var kinds: Array = NPCBrain.TRADE_STATIONS.get(job_for(role), [])
	var out := []
	var ids: Array = w.stations.keys()
	ids.sort()
	for id in ids:
		var st: Dictionary = w.stations[id]
		var b: Dictionary = w.buildings.get(str(st.get("building", "")), {})
		if kinds.has(str(st.type)) and not b.is_empty() and w.holds(employer, b):
			out.append(id)
	return out


# ---------------------------------------------------------------- taking on and letting go -------
## The acting player employs `n` as `role` for `pay` coins a day (-1: what they ask), paid from their purse or from the till of
## their premises `account` (a stall's or shop's id). A crafter is told what to make (`make`, a recipe of their trade the
## employer's stations make; set_make changes it), so the employer's materials are used only for what the employer chose.
## "" when done, else why not.
func employ(n: NPC, role := "miner", pay := -1, account := "", make := "", actor: PlayerState = null) -> String:
	# MP C (World.mirror): a guest's verb goes to the host
	if w.mirrors():
		return w.mirror("employment.employ", employ.bind(n, role, pay, account, make), [n, role, pay, account, make])
	if actor != null and actor != w.player:
		return w.as_actor(actor, employ.bind(n, role, pay, account, make))
	var why := refusal(n, role)
	if why == "" and behaviour(role) == "craft":
		why = make_refusal(role, make)
	if why != "":
		return why
	if account != "" and not w.business.is_mine(w.business.record(account)):
		return "That is not your premises."
	var ask := asking(n, role)
	var wg := ask if pay < 0 else pay
	if wg < ask:
		return "%s wants at least %d coins a day for that work." % [n.name, ask]
	if w.judgment != null:
		why = JudgmentLive.work_refusal(w, n, w.acting_id(), wg)      # the villager's own yes (PROS-19)
	if why != "":
		return why
	var rec := {"npc": n.id, "employer": w.acting_ref(), "role": role, "wage": wg, "since": w.day(), "paid_day": -1, "owed": {}}
	if account != "":
		rec.account = account
	if make != "":
		rec.make = make
	if _funds(rec) < wg:
		return "You need %d coins for the first day's wage." % wg
	_start(rec, n, "%s %s" % [w.player.name, w.player.family])
	return ""


## B25-BIZ-D2: a villager business (`employer` "venture:<id>") takes `n` on as `role` for `pay` coins a day. "" when done.
func hire_for(employer: String, n: NPC, role: String, pay: int) -> String:
	var why := refusal(n, role, employer)
	if why != "":
		return why
	var b: Dictionary = w.ventures.by_ref(employer)
	if pay < asking(n, role):
		return "%s wants more." % n.name
	why = JudgmentLive.work_refusal(w, n, int(b.venture.keeper), pay) if w.judgment != null else ""
	if why != "":
		return why
	var rec := {"npc": n.id, "employer": employer, "role": role, "wage": pay, "since": w.day(), "paid_day": -1, "owed": {}}
	if _funds(rec) < pay:
		return "The business cannot pay the wage."
	w.permit(b, World.npc_ref(n.id), true)               # the keeper's leave at the business's stations
	_start(rec, n, w.property.describe(b))
	var sts: Array = w.ventures.trade_stations(b, role)
	if not sts.is_empty():
		n.workplace = str(sts[0])
	return ""


func _start(rec: Dictionary, n: NPC, by: String) -> void:
	list.append(rec)
	var job := job_for(str(rec.role))
	var left := n.job
	var left_place := n.workplace
	if n.job != job:
		w.brain._change_job(n, job, "employed by %s" % by)
		w.brain._post_left(n, left, left_place)
	_pay(rec, n)
	n.plan.clear()
	w.stat("employees_hired")
	w.stat("employees_hired_" + str(rec.role))
	w.note("%s employs %s %s as a %s for %d coins a day." % [World.cap(by), n.name, n.family, str(rec.role), int(rec.wage)])


## The acting player lets their employee `n` go. They keep their wages, their tools and their trade; what they still carry of
## the employer's goods is handed over first when the employer's store can take it, else it stays in their hands as theirs.
func dismiss(n: NPC, actor: PlayerState = null) -> String:
	if w.mirrors():
		return w.mirror("employment.dismiss", dismiss.bind(n), [n])
	if actor != null and actor != w.player:
		return w.as_actor(actor, dismiss.bind(n))
	var rec := record_of(n)
	if rec.is_empty() or not w.is_acting_ref(str(rec.employer)):
		return "%s does not work for you." % (n.name if n != null else "They")
	end(rec, "you let them go")
	return ""


## The employment ends (dismissal, resignation, an unpaid wage, the business closing or changing hands).
func end(rec: Dictionary, why: String) -> void:
	if not list.has(rec):
		return
	var n := w.npc(int(rec.npc))
	if n != null and n.alive:
		_hand_over(rec, n)
		var b: Dictionary = w.ventures.by_ref(str(rec.employer))
		if not b.is_empty():
			w.permit(b, World.npc_ref(n.id), false)
			if w.stations.has(n.workplace) and str(w.stations[n.workplace].get("building", "")) == str(b.id):
				n.workplace = w.ventures._other_station(n, n.job)
		var c: Dictionary = w.construction.contract_of(n)
		if bool(c.get("employment", false)):
			w.construction.end_contract(c, why)
		n.plan.clear()
		w.note("%s %s no longer works for %s: %s." % [n.name, n.family, _employer_name(str(rec.employer)), why])
	list.erase(rec)
	w.stat("employees_left")


func _employer_name(ref: String) -> String:
	var b: Dictionary = w.ventures.by_ref(ref)
	if ref.begins_with("venture:"):
		return w.property.describe(b) if not b.is_empty() else "the business"
	return w.ref_name(ref)


# ---------------------------------------------------------------- the money ----------------------
## The coins the employer's account holds for wages: a venture's till, a premises' till, a player's purse.
func _funds(rec: Dictionary) -> int:
	var ref := str(rec.employer)
	if ref.begins_with("venture:"):
		return BusinessMoney.venture_till_of(w.ventures.by_ref(ref))
	if str(rec.get("account", "")) != "":
		return int(w.business.record(str(rec.account)).get("till", 0))
	var pl: PlayerState = w.player_for(ref)
	return pl.coins if pl != null else 0


## The day's wage from the employer's account to the employee (earned, so it is their income): coins move, none is made.
func _pay(rec: Dictionary, n: NPC) -> bool:
	var amount := int(rec.wage)
	if amount <= 0:
		rec.paid_day = w.day()
		return true
	if _funds(rec) < amount:
		return false
	var ref := str(rec.employer)
	if ref.begins_with("venture:"):
		if not w.business.money.pay_out(w.ventures.by_ref(ref), "venture", n, amount, "wage"):
			return false
	elif str(rec.get("account", "")) != "":
		var s: Dictionary = w.business.record(str(rec.account))
		s.till = int(s.till) - amount
		n.coins += amount
		w.business._cost(s, "wages", amount)
	else:
		w.player_for(ref).coins -= amount
		n.coins += amount
	n.earned += amount
	rec.paid_day = w.day()
	w.stat("employment_wages", amount)
	return true


## Each dawn: an employee who died, an employer gone (a player gone, a business closed), a store or a premises gone, an
## employee who leaves of their own accord or an unpaid wage ends the employment; the rest are paid for the new day.
func daily() -> void:
	for rec in list.duplicate():
		var n := w.npc(int(rec.npc))
		if n == null or not n.alive:
			list.erase(rec)
			w.stat("employees_left")
			continue
		var ref := str(rec.employer)
		if ref.begins_with("venture:"):
			if w.ventures.by_ref(ref).is_empty():
				end(rec, "the business closed")
				continue
		else:
			var pl: PlayerState = w.player_for(ref)
			if pl == null or not pl.alive:
				end(rec, "the employer is gone")
				continue
			if w.construction.store_of(ref) == null:
				end(rec, "the employer has no home to bring the work to")
				continue
			if str(rec.get("account", "")) != "" and not w.as_actor(pl, w.business.is_mine.bind(w.business.record(str(rec.account)))):
				end(rec, "the premises paying the wage is gone")
				continue
		var why := _resign(rec, n)
		if why != "":
			end(rec, why)
			w.stat("employees_resigned")
			continue
		if int(rec.paid_day) >= w.day():
			continue
		if not _pay(rec, n):
			end(rec, "the wage could not be paid")
			w.stat("employees_unpaid")


## Whether `n` leaves of their own accord this morning ("" stays): on their own weekly morning, when their wage has fallen
## below resign_below of what their trade's market pays now (better-paid work is to be had elsewhere). A villager who keeps
## a business of their own has left (Ventures: founding or buying one ends their employment).
func _resign(rec: Dictionary, n: NPC) -> String:
	if not w.ventures.kept_by(n).is_empty():
		return "they run a business of their own now"
	if (w.day() + JudgmentMath.hash_ints([w.seed, n.id, 8123]) % 7) % 7 != 0 or int(rec.since) >= w.day():
		return ""
	if float(rec.wage) < float(market_wage(str(rec.role))) * float(cfg().get("resign_below", 0.75)):
		return "they found better-paid work"
	return ""


# ---------------------------------------------------------------- the work ----------------------
## The units of the employer's goods `n` carries now (what they made or bought for them and still hold).
func carried(rec: Dictionary, n: NPC) -> int:
	var k := 0
	for id in rec.owed:
		k += mini(int(rec.owed[id]), n.inv.count(str(id)))
	return k


## The employee's next steps in the working day (NPCBrain._decide), false when `n` is not employed or works the trade's own
## day for a business (NPCBrain._plan_job, at the business's stations).
func plan(n: NPC) -> bool:
	var rec := record_of(n)
	if rec.is_empty() or str(rec.employer).begins_with("venture:"):
		return false
	var name := w.ref_name(str(rec.employer))
	var held := carried(rec, n)
	var late := w.hour() >= NPCBrain.WORK_END - 1.0
	var how := behaviour(str(rec.role))
	var load := int(GameData.b("carry_logs")) if how == "chop" else int(GameData.b("carry_ore"))
	if held > 0 and (held >= load or late or how in ["farm", "build", "craft"]):
		n.doing = "bringing the work to %s" % name
		n.plan = [w.brain.go(w.construction._store_cell(str(rec.employer))), w.brain.doit("emp_deliver")]
		return true
	match how:
		"mine":
			return _plan_mine(n, rec, name, late)
		"chop":
			return _plan_chop(n, rec, name, late)
		"farm":
			for p in w.farm_plots.plots_of(str(rec.employer)):
				if w.farm_plots.plan_hired(n, p):
					n.doing = "working %s's farmland" % name
					return true
		"build":
			if _plan_build(n, rec):
				return true
		"craft":
			if not late and _plan_craft(n, rec, name):
				return true
	return _wait(n, rec, name)


func _wait(n: NPC, rec: Dictionary, name: String) -> bool:
	n.doing = "waiting for work from %s" % name
	n.plan = [w.brain.go(w.brain.wander_cell(w.construction._store_cell(str(rec.employer)), 3)), w.brain.work(60, "", {}, "idle")]
	return true


func _plan_mine(n: NPC, rec: Dictionary, name: String, late: bool) -> bool:
	if not n.inv.has("pickaxe"):
		return w.brain._get_tool(n, "pickaxe")
	var ores := ORES.filter(func(o: String) -> bool: return w.brain._can_mine(n, o))
	var d: Dictionary = w.nearest_seam(n, ores) if not late else {}
	if d.is_empty():
		return _wait(n, rec, name)
	n.doing = "mining %s for %s" % [GameData.item_name(d.ore).to_lower(), name]
	n.plan = w.brain.seam_steps(n, d, "emp_mine", {})
	return true


func _plan_chop(n: NPC, rec: Dictionary, name: String, late: bool) -> bool:
	if not n.inv.has("axe"):
		return w.brain._get_tool(n, "axe")
	var t: Dictionary = w.nearest_tree(n.cell(), 70.0) if not late else {}
	if t.is_empty():
		return _wait(n, rec, name)
	t.claimed = n.id
	var at := Vector2i(t.x, t.y)
	n.doing = "felling a tree for %s" % name
	var mins := CapabilityHook.work_time(float(GameData.b("chop_minutes")), "forestry", Skills.value(n, "woodcutting", "chop_time", 1.0), n)
	n.plan = [w.brain.go(w.brain.beside(at, n.cell())), w.brain.work(mins, "emp_chop", {"x": t.x, "y": t.y}, "work", at)]
	return true


## A builder carries the employer's materials to the employer's own unfinished site through the helper's work
## (Construction.plan_helper): a day contract with no wage of its own (the employment pays) and no budget (they fetch from the
## employer's store; buying is the employer's decision). It ends with the day, as every helper's does.
func _plan_build(n: NPC, rec: Dictionary) -> bool:
	var ref := str(rec.employer)
	for p in w.plots:
		if not p.site.is_empty() and not p.site.get("done", false) and str(p.site.get("owner", "")) == ref:
			if w.construction.contract_of(n).is_empty():
				w.construction.contracts.append({"worker": n.id, "employer": ref, "site": str(p.id), "day": w.day(), "wage": 0,
					"budget": 0, "spent": 0, "load": Inventory.new(), "employment": true})
			return w.construction.plan_helper(n)
	return false


## A crafter for a player: the recipe the employer chose (`make`), when they have the skill and tool for it, at a free station
## the employer holds, with the inputs in the employer's store.
func _plan_craft(n: NPC, rec: Dictionary, name: String) -> bool:
	var store: Inventory = w.construction.store_of(str(rec.employer))
	if store == null or not GameData.recipes.has(str(rec.get("make", ""))):
		return false
	var sts := employer_stations(str(rec.employer), str(rec.role))
	for r in [str(rec.make)]:
		var rd: Dictionary = GameData.recipes[r]
		if GameData.is_catalogue_recipe(r) or not w.brain._can_make(n, r) or not store.has_all(rd["in"]):
			continue
		var st := _free_station(n, sts, str(rd.station))
		if st == "":
			continue
		var mins := CapabilityHook.work_time(float(rd.minutes), CapabilityHook.recipe_industry(r), Skills.value(n, str(rd.skill), "craft_time", 1.0), n)
		w.stations[st].users[n.id] = w.minutes + w.map.data.w + mins + 60.0
		n.doing = "making %s for %s" % [str(r).replace("_", " "), name]
		n.plan = [w.brain.go(w.station_use(st)), w.brain.work(mins, "emp_craft", {"recipe": r, "station": st}, "work", w.brain._station_at(st))]
		return true
	return false


func _free_station(n: NPC, sts: Array, kind: String) -> String:
	for id in sts:
		var st: Dictionary = w.stations[id]
		if str(st.type) != kind:
			continue
		var users: Dictionary = st.users
		for u in users.keys():
			var o := w.npc(int(u))
			if float(users[u]) < w.minutes or o == null or not o.alive or not o.plan.any(func(p): return str(p.get("args", {}).get("station", "")) == id):
				users.erase(u)
		if users.has(n.id) or users.size() + w.players_at(st) < int(st.get("capacity", 1)):
			return id
	return ""


## NPCBrain.act "emp_mine": the swing; what comes out is owed to the employer.
func act_mine(n: NPC, a: Dictionary) -> bool:
	var rec := record_of(n)
	if rec.is_empty():
		return false
	var d := w.deposit_at(Vector2i(int(a.x), int(a.y)), int(a.get("level", 0)))
	if d.is_empty():
		return false
	var r := w.work_mine(n, d, n.inv)
	if str(r.result) != "ok":
		return false
	rec.owed[str(r.ore)] = int(rec.owed.get(str(r.ore), 0)) + int(r.n)
	w.stat("employment_mined", int(r.n))
	if r.broke:
		w.note("%s %s's pickaxe broke." % [n.name, n.family])
	return true


## NPCBrain.act "emp_chop": the tree felled by the woodcutter's rule; the logs are owed to the employer.
func act_chop(n: NPC, a: Dictionary) -> bool:
	var rec := record_of(n)
	var t := w.tree_at(Vector2i(int(a.x), int(a.y)))
	t.erase("claimed")
	if rec.is_empty():
		return false
	var logs := w.fell(t, int(Skills.value(n, "woodcutting", "log_bonus")))
	if logs <= 0:
		return false
	var before := n.inv.count("log")
	if w.work_felled(n, logs, n.inv).broke:
		w.note("%s %s's axe broke." % [n.name, n.family])
	var got := n.inv.count("log") - before
	if got > 0:
		rec.owed["log"] = int(rec.owed.get("log", 0)) + got
		w.stat("employment_felled", got)
	return true


## NPCBrain.act "emp_craft": the real recipe at the employer's station: the inputs leave the employer's store only now (the
## recipe's rule through World.work_craft), the goods and any material a practised hand saved go back into it; what the
## store has no room for stays in the employee's hands, owed to the employer.
func act_craft(n: NPC, a: Dictionary) -> bool:
	w.brain.release_station(n, str(a.get("station", "")))
	var rec := record_of(n)
	var r := str(a.get("recipe", ""))
	var store: Inventory = w.construction.store_of(str(rec.get("employer", ""))) if not rec.is_empty() else null
	if store == null or not GameData.recipes.has(r) or not store.has_all(GameData.recipes[r]["in"]):
		return false
	var bench := Inventory.new()
	for id in GameData.recipes[r]["in"]:
		w.transfer(store, bench, str(id), int(GameData.recipes[r]["in"][id]))
	var res := w.work_craft(n, r, bench)
	for id in bench.ids():
		var k := bench.count(id)
		var put := 0
		while put < k and w.transfer(bench, store, id, 1):
			put += 1
		if k - put > 0:
			w.transfer(bench, n.inv, id, k - put)
			rec.owed[id] = int(rec.owed.get(id, 0)) + (k - put)
	if str(res.result) != "ok":
		return false
	w.stat("employment_crafted")
	return true


## NPCBrain.act "emp_deliver": at the employer's door, what they carry of the employer's goods goes into the employer's store.
func act_deliver(n: NPC) -> bool:
	var rec := record_of(n)
	if rec.is_empty():
		return false
	return _hand_over(rec, n) > 0


## What `n` carries of the employer's goods goes to the employer: a player's store; a business's keeper (the business's goods
## again), else its household's store. Nothing is owed that they no longer hold.
func _hand_over(rec: Dictionary, n: NPC) -> int:
	var ref := str(rec.employer)
	var to: Inventory = null
	var keeper: NPC = null
	var b: Dictionary = w.ventures.by_ref(ref)
	if ref.begins_with("venture:"):
		if not b.is_empty():
			keeper = w.npc(int(b.venture.keeper))
			if keeper != null and keeper.alive and keeper != n:
				to = keeper.inv
			else:
				keeper = null
				to = w.construction.store_of(World.hh_ref(int(b.venture.household)))
	else:
		to = w.construction.store_of(ref)
	if to == null:
		return 0
	var moved := 0
	var ids: Array = (rec.owed as Dictionary).keys()
	ids.sort()
	for id in ids:
		var k := mini(int(rec.owed[id]), n.inv.count(str(id)))
		var put := 0
		while put < k and w.transfer(n.inv, to, str(id), 1):     # a unit at a time: the store takes what it has room for
			put += 1
		moved += put
		if put > 0 and keeper != null:
			var g: Dictionary = b.venture.get("goods", {})
			g[str(id)] = int(g.get(str(id), 0)) + put
			b.venture.goods = g
		var left := mini(int(rec.owed[id]) - put, n.inv.count(str(id)))
		if left <= 0:
			rec.owed.erase(id)
		else:
			rec.owed[id] = left
	if moved > 0:
		w.stat("employment_delivered", moved)
	return moved


## FarmPlots: the store a farm hand's work on plot `p` goes to: their employer's, when `p` is the employer's farmland (null
## otherwise).
func farm_store(n: NPC, p: Dictionary) -> Inventory:
	return w.construction.store_of(str(record_of(n).employer)) if works_plot(n, p) else null


## Whether `n` is employed as a farm hand by the holder of farmland `p`.
func works_plot(n: NPC, p: Dictionary) -> bool:
	var rec := record_of(n)
	return not rec.is_empty() and behaviour(str(rec.role)) == "farm" and not str(rec.employer).begins_with("venture:") and w.holds(str(rec.employer), p)


# ---------------------------------------------------------------- saving ------------------------
func to_dict() -> Dictionary:
	return {"list": list.duplicate(true)}


func load_dict(d: Dictionary) -> void:
	list = []
	for r in d.get("list", []):
		if r is Dictionary:
			var rec: Dictionary = (r as Dictionary).duplicate(true)
			rec.npc = int(rec.npc)
			rec.paid_day = int(rec.get("paid_day", -1))
			rec.since = int(rec.get("since", 0))
			rec.wage = int(rec.get("wage", wage()))
			rec.role = str(rec.get("role", "miner"))
			var owed := {}
			for id in rec.get("owed", {}):
				owed[str(id)] = int(rec.owed[id])
			rec.owed = owed
			list.append(rec)
