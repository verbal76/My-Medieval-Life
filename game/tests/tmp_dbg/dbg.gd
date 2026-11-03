extends SceneTree
func _init():
	var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/b24_save_v23_single.json"))
	var wo := World.new()
	wo.load_dict(VillageMap.load_default(), old)
	print("err=", wo.load_error, " bh=", wo.wilds.band_household(), " claims=", wo.homesteads.claims.map(func(c): return [c.id, c.get("path",""), c.owner]), " counts=", wo.wilds.counts)
	var h = wo.wilds.band_household()
	print(wo.households[h].get("homestead"), " ", wo.wilds.band_claim().get("id"))
	quit()
