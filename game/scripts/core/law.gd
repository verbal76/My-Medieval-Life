class_name Law
extends RefCounted
## LAW-SKILL (owner Q18-14, 2026-10-23, docs/directives/2026-10-23_owner_answers_q18_14_16.md): the Law skill, one of the
## shared skills (PAR-01: the player and every villager climb the same curve, skills.json "law"). It starts at 0 for
## everyone (no one is given a legal history), and it is raised two ways, with the numbers in couriers.json "law":
##   - by doing: a notary courier witnesses a signature (witness_xp) and carries a formal document home (carry_xp);
##     FormalAgreements calls `witnessed` and `carried` (X18-Q13, the courier-notary path);
##   - by being taught: the reeve teaches the law up to a level (`teach`, one lesson a game day a pupil). The clergy do not
##     exist yet: couriers.json law.teachers already lists "clergy" with a higher ceiling, and `teacher_cap` reads it by the
##     teacher's job, so a clergy job that is added later teaches with no change here (agent decision, docs/DECISIONS.md).
## A courier qualifies as a notary when their Law reaches couriers.json notary (CourierService.cfg().notary), not before.
## The lessons given a day are kept in World.law_lessons (saved, optional key "law_lessons").


static func cfg() -> Dictionary:
	return CourierService.cfg().law


## The person a courier reference names: the player ("player") or a villager ("npc:<id>"); null when neither.
static func person(w: World, ref: String):
	if w == null:
		return null
	if ref == World.PLAYER:
		return w.player
	if ref.begins_with("npc:"):
		return w.npc(int(ref.trim_prefix("npc:")))
	return null


## Adds Law experience to the person `ref`; returns the new level when it went up, else 0.
static func award(w: World, ref: String, xp: int) -> int:
	var who = person(w, ref)
	if who == null or xp <= 0:
		return 0
	var up := Skills.gain(who, "law", xp)
	if up > 0 and ref == World.PLAYER:
		w.player_leveled.emit("law", up)
	return up


## A notary witnessed a signature given before them.
static func witnessed(w: World, notary: String) -> void:
	award(w, notary, int(cfg().witness_xp))


## A notary brought a formal document home.
static func carried(w: World, notary: String) -> void:
	award(w, notary, int(cfg().carry_xp))


## Whether the person is qualified to notarise: their Law reaches the notary level.
static func qualified(w: World, ref: String) -> bool:
	var who = person(w, ref)
	if who == null or not bool(who.alive):
		return false
	return Skills.level(who, str(CourierService.cfg().notary.skill)) >= int(CourierService.cfg().notary.min_level)


## The highest Law level this villager teaches (0: they do not teach it): by their job, couriers.json law.teachers.
static func teacher_cap(teacher: NPC) -> int:
	if teacher == null or not teacher.alive or not teacher.role in ["adult", "elder"]:
		return 0
	return int((cfg().teachers as Dictionary).get(teacher.job, 0))


## Whether the teaching of Law is offered by this villager at all.
static func teaches(teacher: NPC) -> bool:
	return teacher_cap(teacher) > 0


## A lesson: `teacher` (the reeve today) teaches the person `pupil_ref` ("player" or "npc:<id>"). {ok, text, up}; nothing
## changes when it is refused (above the teacher's ceiling, or already taught today).
static func teach(w: World, pupil_ref: String, teacher: NPC) -> Dictionary:
	var who = person(w, pupil_ref)
	var cap := teacher_cap(teacher)
	if who == null or cap <= 0:
		return {"ok": false, "text": "%s has no law to teach." % (teacher.name if teacher != null else "No one"), "up": 0}
	if Skills.level(who, "law") >= cap:
		return {"ok": false, "text": "I have taught you all of the law that I know. You will have to learn the rest by carrying documents, or from someone who knows more.", "up": 0}
	var day := w.day()
	var rec: Array = w.law_lessons.get(pupil_ref, [-1, 0])
	if int(rec[0]) == day and int(rec[1]) >= int(cfg().lessons_per_day):
		return {"ok": false, "text": "We have done enough law for one day. Come back tomorrow.", "up": 0}
	w.law_lessons[pupil_ref] = [day, (int(rec[1]) + 1) if int(rec[0]) == day else 1]
	var up := award(w, pupil_ref, mini(int(cfg().lesson_xp), Skills.xp_for_level(cap) - int(who.skills.get("law", 0))))
	var text := "%s teaches you how a bargain is written, witnessed and kept." % teacher.name
	if up > 0:
		text += " Your Law is now level %d." % up
	return {"ok": true, "text": text, "up": up}
