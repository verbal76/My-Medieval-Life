extends SceneTree
## MP-04 — independent, focused host-authority regression.
## Audited base: fe7d8f88bf5df77ce7e6ea601d6abc62eed13122.
## A malicious client may submit any whitelisted verb; normal GUI behavior is not sufficient.
## Run: godot --headless --path game --script res://tests/mp04_cart_gateway_test.gd

var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if ok:
		print("ok   " + label)
	else:
		failures += 1
		printerr("FAIL: " + label)

func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 4004)
	var guest := PlayerState.new()
	guest.name = "MP04"
	guest.family = "Test"
	guest.sex = "female"
	guest.born = w.player.born
	Identity.register_player(w, guest)
	w.give_start_kit(guest)
	guest.pos = w.player.pos + Vector2(3, 0)
	guest.net_key = "f".repeat(32)
	w.add_guest(guest)

	# A crafted, host-side verb request must NOT materialize a cart without a cart item.
	# Test the actual authoritative decoder, not merely the normal UI wrapper.
	var before_carts := w.carts.carts.size()
	var before_items := guest.inv.count("handcart")
	var crafted := NetActions.apply_verb(w, guest, "carts.place", [w.player_ref(guest), guest.pos, "handcart", 0])
	check(not bool(crafted.get("ok", false)), "MP-04: direct carts.place guest verb is rejected by host")
	check(w.carts.carts.size() == before_carts, "MP-04: crafted verb creates no cart")
	check(guest.inv.count("handcart") == before_items, "MP-04: crafted verb changes no player cart items")

	# Normal placement is still allowed through the validated player wrapper and spends one cart.
	guest.inv.add("handcart", 1)
	var before_normal_items := guest.inv.count("handcart")
	var before_normal_carts := w.carts.carts.size()
	var normal := NetActions.apply_verb(w, guest, "player_set_down_cart", [guest.pos])
	check(bool(normal.get("ok", false)), "MP-04: validated player_set_down_cart remains available")
	check(w.carts.carts.size() == before_normal_carts + 1, "MP-04: validated placement creates exactly one cart")
	check(guest.inv.count("handcart") == before_normal_items - 1, "MP-04: validated placement consumes one handcart")
	w.dispose()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
