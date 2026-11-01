class_name Employment
extends RefCounted
## EMP-PERM-01 (owner B18-DP-01, 2026-10-23: "A player must be able to offer an NPC ongoing employment through the existing
## job-offer and wage systems"; design docs/expansion20/BUSINESS_FOUNDING.md section 5): permanent employment by the player.
## Distinct from a day's building helper (Construction.hire), a counter attendant (Business.hire) and a contract (CON-01/02):
## the employee keeps the role from day to day until dismissed, the wage fails, or either side is gone.
##
## Role "miner": in the working day the employee mines the village's seams they may work (World.nearest_seam; NPCBrain
## _can_mine) with their own pickaxe (bought with their own coins when they have none, NPCBrain._get_tool), by the one swing
## rule (World.work_mine: the seam's finite ore, Mining xp, tool wear). What they mine while employed is the employer's: it is
## counted in the record (`owed`) and carried, a load (carry_ore) at a time and before the working day ends, to the employer's
## store (Construction.store_of: the player's family chest at home), moved by World.transfer. Nothing is made: the ore leaves
## the seam into the employee's hands and their hands into the chest.
## Wage: employment.wage coins a day, the first paid on hiring and then each dawn, from the employer's purse to the employee
## (earned, so it is their income): coins move, none is made. An unpaid wage ends the employment.
## Who may be employed: an adult with no trade of their own (Construction.HIRABLE) or a miner, not minding a counter, not
## hired for building today, not employed already, willing (JudgmentLive.work_refusal, as an attendant). Their job becomes
## miner (NPCBrain._change_job), and the morning labour market leaves them where they are (NPCBrain.seek_work).
## Verbs employ / dismiss go through World.mirror and NetActions.VERBS (host validation) like the business verbs.
## Saved under the optional key "employment" {list: [{npc, employer, role, wage, since, paid_day, owed}]} (older saves: none).

const ROLES := ["miner"]
const ORES := ["iron_ore", "coal", "copper_ore", "stone", "gold_ore"]

var w: World
var list: Array = []


func _init(world: World) -> void:
	w = world


static func wage() -> int:
	return int((GameData.b("employment") as Dictionary).get("wage", 10))


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


## The employees of `ref` (a player reference), in hiring order.
func of_employer(ref: String) -> Array:
	return list.filter(func(r: Dictionary) -> bool: return str(r.employer) == ref)


## Why the acting player cannot employ `n` in `role`, "" when they can.
func refusal(n: NPC, role := "miner") -> String:
	if not ROLES.has(role):
		return "There is no such work to offer."
	if n == null or not n.alive or n.role != "adult" or n.household < 0:
		return "They cannot work for you."
	if is_employed(n):
		return "%s works for %s already." % [n.name, "you" if w.is_acting_ref(str(record_of(n).employer)) else "someone"]
	if not (n.job in Construction.HIRABLE or n.job == "miner"):
		return "%s has work of their own." % n.name
	if n.job == "manor_hand" and not w.manor_work.job_of("npc:%d" % n.id).is_empty():
		return "%s is doing a job for the manor." % n.name
	if not w.construction.contract_of(n).is_empty():
		return "%s is hired for building work today." % n.name
	if w.business.is_attendant(n):
		return "%s minds a counter already." % n.name
	if w.construction.store_of(w.acting_ref()) == null:
		return "You need a home with a chest to keep what they mine."
	if w.player.coins < wage():
		return "You need %d coins for the first day's wage." % wage()
	return ""


## Employ `n` as the acting player's permanent `role`. "" when done, else why not.
func employ(n: NPC, role := "miner", actor: PlayerState = null) -> String:
	# MP C (World.mirror): a guest's verb goes to the host
	if w.mirrors():
		return w.mirror("employment.employ", employ.bind(n, role), [n, role])
	if actor != null and actor != w.player:
		return w.as_actor(actor, employ.bind(n, role))
	var why := refusal(n, role)
	if why == "" and w.judgment != null:
		why = JudgmentLive.work_refusal(w, n, w.acting_id(), wage())   # PROSPECTIVE (PROS-19): the villager may decline
	if why != "":
		return why
	var rec := {"npc": n.id, "employer": w.acting_ref(), "role": role, "wage": wage(), "since": w.day(), "paid_day": -1, "owed": {}}
	list.append(rec)
	var left := n.job
	var left_place := n.workplace
	if n.job != role:
		w.brain._change_job(n, role, "employed by %s %s" % [w.player.name, w.player.family])
		w.brain._post_left(n, left, left_place)
	_pay(rec, n, w.player)
	n.plan.clear()
	w.stat("employees_hired")
	w.note("%s %s employs %s %s as a %s for %d coins a day." % [w.player.name, w.player.family, n.name, n.family, role, wage()])
	return ""


## The acting player lets their employee `n` go. They keep their wages, their tools and their trade; what they still carry of
## the employer's ore is delivered first when the employer's chest can take it, else it stays in their hands as theirs (Q4).
func dismiss(n: NPC, actor: PlayerState = null) -> String:
	if w.mirrors():
		return w.mirror("employment.dismiss", dismiss.bind(n), [n])
	if actor != null and actor != w.player:
		return w.as_actor(actor, dismiss.bind(n))
	var rec := record_of(n)
	if rec.is_empty() or not w.is_acting_ref(str(rec.employer)):
		return "%s does not work for you." % (n.name if n != null else "They")
	_end(rec, "you let them go")
	return ""


func _end(rec: Dictionary, why: String) -> void:
	var n := w.npc(int(rec.npc))
	if n != null and n.alive:
		_hand_over(rec, n)
		n.plan.clear()
		w.note("%s %s no longer works for %s: %s." % [n.name, n.family, w.ref_name(str(rec.employer)), why])
	list.erase(rec)
	w.stat("employees_left")


func _pay(rec: Dictionary, n: NPC, pl: PlayerState) -> void:
	var amount := int(rec.wage)
	pl.coins -= amount
	n.coins += amount
	n.earned += amount
	rec.paid_day = w.day()
	w.stat("employment_wages", amount)


## Each dawn: an employee who died, an employer gone, a home store gone or an unpaid wage ends the employment; the rest are
## paid for the new day.
func daily() -> void:
	for rec in list.duplicate():
		var n := w.npc(int(rec.npc))
		var pl: PlayerState = w.player_for(str(rec.employer))
		if n == null or not n.alive:
			list.erase(rec)
			w.stat("employees_left")
			continue
		if pl == null or not pl.alive:
			_end(rec, "the employer is gone")
			continue
		if w.construction.store_of(str(rec.employer)) == null:
			_end(rec, "the employer has no home to bring the ore to")
			continue
		if int(rec.paid_day) >= w.day():
			continue
		if pl.coins < int(rec.wage):
			_end(rec, "the wage could not be paid")
			w.stat("employees_unpaid")
			continue
		_pay(rec, n, pl)


# ---------------------------------------------------------------- the work ----------------------
## The units of the employer's ore `n` carries now (what they mined for them and still hold).
func carried(rec: Dictionary, n: NPC) -> int:
	var k := 0
	for id in rec.owed:
		k += mini(int(rec.owed[id]), n.inv.count(str(id)))
	return k


## The employee's next steps in the working day (NPCBrain._decide), false when `n` is not employed.
func plan(n: NPC) -> bool:
	var rec := record_of(n)
	if rec.is_empty():
		return false
	var name := w.ref_name(str(rec.employer))
	var held := carried(rec, n)
	var late := w.hour() >= NPCBrain.WORK_END - 1.0
	if held > 0 and (held >= int(GameData.b("carry_ore")) or late):
		n.doing = "bringing ore to %s" % name
		n.plan = [w.brain.go(w.construction._store_cell(str(rec.employer))), w.brain.doit("emp_deliver")]
		return true
	if not n.inv.has("pickaxe"):
		return w.brain._get_tool(n, "pickaxe")
	var ores := ORES.filter(func(o: String) -> bool: return w.brain._can_mine(n, o))
	var d: Dictionary = w.nearest_seam(n, ores) if not late else {}
	if d.is_empty():
		n.doing = "waiting for work from %s" % name
		n.plan = [w.brain.go(w.brain.wander_cell(w.construction._store_cell(str(rec.employer)), 3)), w.brain.work(60, "", {}, "idle")]
		return true
	n.doing = "mining %s for %s" % [GameData.item_name(d.ore).to_lower(), name]
	n.plan = w.brain.seam_steps(n, d, "emp_mine", {})
	return true


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


## NPCBrain.act "emp_deliver": at the employer's door, what they carry of the employer's ore goes into the employer's store.
func act_deliver(n: NPC) -> bool:
	var rec := record_of(n)
	if rec.is_empty():
		return false
	return _hand_over(rec, n) > 0


func _hand_over(rec: Dictionary, n: NPC) -> int:
	var store: Inventory = w.construction.store_of(str(rec.employer))
	if store == null:
		return 0
	var moved := 0
	var ids: Array = (rec.owed as Dictionary).keys()
	ids.sort()
	for id in ids:
		var k := mini(int(rec.owed[id]), n.inv.count(str(id)))
		var put := 0
		while put < k and w.transfer(n.inv, store, str(id), 1):     # a unit at a time: the chest takes what it has room for
			put += 1
		moved += put
		var left := mini(int(rec.owed[id]) - put, n.inv.count(str(id)))     # nothing is owed that they no longer hold
		if left <= 0:
			rec.owed.erase(id)
		else:
			rec.owed[id] = left
	if moved > 0:
		w.stat("employment_delivered", moved)
	return moved


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
			rec.wage = int(rec.get("wage", wage()))
			var owed := {}
			for id in rec.get("owed", {}):
				owed[str(id)] = int(rec.owed[id])
			rec.owed = owed
			list.append(rec)
