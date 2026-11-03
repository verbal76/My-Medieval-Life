class_name Paving
extends RefCounted
## B25R1-011 (owner 2026-11-03: "We should be able to upgrade sections of road with stone by clicking on it and having the
## materials"; and stone roads "need materials to fix"): the player paves a dirt road or trail cell with stone, or repairs a
## damaged stone one. Paving mode is turned on from the Build menu; then a tap or click on a road cell walks up to it and
## works it (a timed action, like any work: cancelled by moving), taking RoadWear.PAVE_STONE stone from the pack to pave
## (REPAIR_STONE to repair). "Pave here" in the Build menu works the cell underfoot (keys and the pad). A cell that is not a
## road, a sound stone one, the village's own streets or a pack without the stone is refused with the reason. The stone is
## used up (counted used_stone, the goods ledger's drain) and the cell becomes stone road (RoadWear.pave), which never fades.

const SECS := 4.0               # seconds of work a cell
const REACH := 1.7              # tiles: a cell this close is worked from where the player stands

var active := false
var target := Vector2i(-1048576, 0)


func toggle(m) -> void:
	active = not active
	target = Vector2i(-1048576, 0)
	m.ui.message("Paving: tap a dirt road or a trail to pave it with %d stone, or damaged stone to repair it with %d. Build > Stop paving ends it." % [RoadWear.PAVE_STONE, RoadWear.REPAIR_STONE] if active else "You stop paving.", 6.0)


## Why the player cannot work `cell` now, or "" (and the stone it takes: `need`).
func refusal(m, cell: Vector2i) -> String:
	if m.guest_world:
		return "Paving is not possible in a shared world yet."
	if m.world.player_level != 0:
		return "Come up to the surface first."
	var job := RoadWear.work_for(m.world.map.overworld, cell)
	if str(job.why) != "":
		return str(job.why)
	if m.world.player.inv.count("stone") < int(job.stone):
		return "You need %d stone to %s that (you have %d)." % [int(job.stone), str(job.mode), m.world.player.inv.count("stone")]
	return ""


## A tap or click in paving mode: true when it was taken (a road cell: worked or walked to; anything else: refused).
func tap(m, cell: Vector2i) -> bool:
	if not active:
		return false
	var why := refusal(m, cell)
	if why != "":
		m.ui.message(why, 4.0)
		return true
	if m.world.player.pos.distance_to(Vector2(cell) + Vector2(0.5, 0.5)) <= REACH:
		start(m, cell)
	else:
		target = cell
		m.move_to = Vector2(cell) + Vector2(0.5, 0.5)
	return true


## Each frame of play: a cell walked up to is worked on arrival; a walk that ended short of it gives it up.
func step(m) -> void:
	if target.x == -1048576 or m.move_to != Vector2.INF:
		return
	var cell := target
	target = Vector2i(-1048576, 0)
	if m.world.player.pos.distance_to(Vector2(cell) + Vector2(0.5, 0.5)) <= REACH + 0.5:
		start(m, cell)
	else:
		m.ui.message("You could not reach that stretch of road.", 4.0)


## Pave here (the Build menu): the cell underfoot.
func here(m) -> void:
	var cell := Vector2i(m.world.player.pos.floor())
	var why := refusal(m, cell)
	if why != "":
		m.ui.message(why, 4.0)
		return
	start(m, cell)


func start(m, cell: Vector2i) -> void:
	var mode := str(RoadWear.work_for(m.world.map.overworld, cell).mode)
	m.start_action("Paving" if mode == "pave" else "Repairing the road", SECS, func(): done(m, cell), "swing", "hammer")


## The work done: the stone is used up and the cell paved (or repaired). Checked again: the pack may have changed.
func done(m, cell: Vector2i) -> void:
	var why := refusal(m, cell)
	if why != "":
		m.ui.message(why, 4.0)
		return
	var w: World = m.world
	var job := RoadWear.work_for(w.map.overworld, cell)
	w.player.inv.remove("stone", int(job.stone))
	w.stat("used_stone", float(job.stone))
	w.stat("road_paved_by_player" if str(job.mode) == "pave" else "road_repaired_by_player")
	if str(job.mode) == "pave":
		RoadWear.pave(w.map.overworld, cell)
		m.ui.message("You lay %d stone: this stretch is stone road now." % int(job.stone), 4.0)
	else:
		RoadWear.repair(w.map.overworld, cell)
		m.ui.message("You reset the broken stones with %d stone." % int(job.stone), 4.0)
