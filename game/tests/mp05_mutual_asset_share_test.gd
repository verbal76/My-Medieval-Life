extends SceneTree
## MP-05: server strangers, reciprocal consent, cumulative tiers,
## property/cart authorization, revocation, save and network sync.
var checks := 0
var failures := 0
func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		failures += 1

func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 8805)
	var guest := PlayerState.new()
	guest.name = "Gwen"
	guest.family = "Trade"
	guest.sex = "female"
	guest.born = w.player.born
	Identity.register_player(w, guest)
	w.give_start_kit(guest)
	guest.net_key = "a".repeat(32)
	w.add_guest(guest)
	guest.pos = w.player.pos
	var ref: String = w.player_ref(guest)
	check(w.asset_share_tier(ref) == 0,"MP-05: strangers share nothing by default")
	check(w.asset_share_tier(World.PLAYER, ref) == 0,"MP-05: default is mutual non-sharing")
	var plot: Dictionary = w.plots[0]
	w.start_site(plot, "house", World.PLAYER)
	for id in plot.site.need.duplicate():
		w.player.inv.add(id, int(plot.site.need[id]))
	w.deliver(plot, w.player.inv, World.PLAYER)
	var house: Dictionary = w.buildings[str(plot.building)]
	w.property.set_home(str(house.id))
	var u: Dictionary = w.chests.units_in(str(house.id))[0]
	check(str(w.as_actor(guest,w.chests.info.bind(u)).access) == "foreign","MP-05: guest sees host chest as foreign before agreement")
	check(w.player_offer("asset_share", guest.pid, "", 1) == "","MP-05: player can propose tier 1")
	check(w.asset_share_tier(ref) == 0,"MP-05: proposal alone grants no access")
	var oid: int = int(w.offers.back().id)
	check(str(w.as_actor(guest,w.player_answer.bind(oid,true))) == "","MP-05: recipient explicitly accepts")
	check(w.asset_share_tier(ref) == 1 and w.asset_share_tier(World.PLAYER,ref) == 1,"MP-05: tier 1 exactly reciprocal")
	guest.inv.add("log", 2)
	check(str(w.as_actor(guest,w.chests.store.bind(u,"log",1))) == "","MP-05: tier 1 grants raw material storage")
	guest.inv.add("axe", 1)
	check(str(w.as_actor(guest,w.chests.store.bind(u,"axe",1))) != "","MP-05: tier 1 does not share tools")
	check(w.player_offer("asset_share", guest.pid, "", 2) == "","MP-05: propose higher tier")
	check(str(w.as_actor(guest,w.player_answer.bind(int(w.offers.back().id),true))) == "","MP-05: tier 2 accepted")
	guest.inv.add("bread",1)
	check(str(w.as_actor(guest,w.chests.store.bind(u,"bread",1))) == "","MP-05: tier 2 shares finished food")
	check(str(w.as_actor(guest,w.chests.store.bind(u,"axe",1))) != "","MP-05: tier 2 still excludes tools")
	check(w.player_offer("asset_share", guest.pid, "", 3) == "","MP-05: propose tier 3")
	check(str(w.as_actor(guest,w.player_answer.bind(int(w.offers.back().id),true))) == "","MP-05: tier 3 accepted")
	check(str(w.as_actor(guest,w.chests.store.bind(u,"axe",1))) == "","MP-05: tier 3 permits tools")
	var cart := {"owner": World.PLAYER}
	check(w.carts.may_use(cart,ref) and w.asset_share_tier(ref) == 3,"MP-05: tier 3 allows mutual property/cart use")
	check(w.to_dict().get("asset_shares",{}) == w.asset_shares,"MP-05: current reciprocal agreement serialized")
	var payload := {"asset_shares": w.asset_shares.duplicate(true)}
	var mirror := World.new()
	mirror.setup(VillageMap.load_default(), 8805)
	NetSync.adopt(mirror,payload)
	check(mirror.asset_share_tier(ref,World.PLAYER) == 3,"MP-05: guest-facing section adopts sharing level")
	var real_cart: Dictionary = w.carts.place(World.PLAYER, w.player.pos)
	check(w.carts.hitch(real_cart, ref) == "","MP-05: at tier 3 the partner may pull the other's cart")
	check(str(w.as_actor(guest,w.asset_share_revoke.bind(w.player.pid))) == "","MP-05: either member may revoke without second approval")
	check(w.asset_share_tier(ref) == 0 and w.asset_share_tier(World.PLAYER,ref) == 0,"MP-05: revocation clears both directions")
	check(str(w.as_actor(guest,w.chests.info.bind(u)).access) == "foreign","MP-05: former partner loses chest permissions immediately")
	w.carts.update(0.1)
	check(str(real_cart.puller) == "" and str(real_cart.owner) == World.PLAYER,"MP-05: after revocation the former partner lets go of the cart, which stays its owner's")
	print("%d checks, %d failures" % [checks,failures])
	quit(1 if failures>0 else 0)
