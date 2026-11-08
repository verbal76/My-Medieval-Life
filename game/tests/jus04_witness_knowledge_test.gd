extends SceneTree
## JUS-04 owner rule (2026-11-08): learning about a crime is required before a witness's
## relatives or friends develop their own opinion. Direct victim-kin harm is unchanged.
## Run: godot --headless --path game --script res://tests/jus04_witness_knowledge_test.gd
var checks := 0
var failures := 0

func check(ok: bool, description: String) -> void:
	checks += 1
	if ok:
		print("ok   " + description)
	else:
		failures += 1
		printerr("FAIL: " + description)

func _init() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 14504)
	var witness: NPC = null
	var relative: NPC = null
	for n: NPC in w.npcs:
		if n.role == "adult" and n.alive:
			if witness == null:
				witness = n
			elif relative == null and n.id != witness.id:
				relative = n
			# No unrelated person is an eyewitness merely by spawn position.
		n.pos = w.player.pos + Vector2(500.0 + float(n.id), 500.0)
	check(witness != null and relative != null, "two living adults available")
	if witness == null or relative == null:
		w.dispose()
		quit(1)
		return
	# Artificial family link solely to isolate the witness's kin propagation path.
	relative.mother = witness.id
	witness.pos = w.player.pos + Vector2(1.0, 0.0)
	relative.pos = w.player.pos + Vector2(250.0, 0.0)
	check(Life.kin(relative.id, relative.mother, relative.father, witness.id, witness.mother, witness.father),
		"the nonwitness is actual family of the witness")
	var who := w.acting_id()
	# Regard cannot fall below zero; establish meaningful prior positive
	# relationships so the penalty is observable rather than clamped away.
	w.relations.tie(who, witness.id).regard = 60.0
	w.relations.tie(who, relative.id).regard = 60.0
	var witness_before := float(w.relations.peek(who, witness.id).regard)
	var relative_before := float(w.relations.peek(who, relative.id).regard)
	var saw := w.witness("theft", "bread", null, {}, null, "steal bread")
	check(saw == 1, "only the nearby person witnessed the crime")
	check(float(w.relations.peek(who, witness.id).regard) < witness_before,
		"direct eyewitness loses regard for the offender")
	check(is_equal_approx(float(w.relations.peek(who, relative.id).regard), relative_before),
		"distant eyewitness relative does not gain automatic criminal knowledge/penalty")
	# Preserve the separate established direct-victim-and-family harm rule.
	w.relations.harmed(witness, float(Relations.cfg().victim_harm))
	check(float(w.relations.peek(who, relative.id).regard) < relative_before,
		"actual victim harm still reaches their family by existing rule")
	w.dispose()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
