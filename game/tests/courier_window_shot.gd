extends SceneTree
## PROSPECTIVE (Expansion 18, X18-Q12-POST): opens the courier contract window in the real game scene and saves a
## screenshot, so the window is looked at before it is called done. Needs a display (not --headless):
##   xvfb-run -a godot --rendering-driver opengl3 --path game --script res://tests/courier_window_shot.gd -- OUT.png [review] [formal]
## With "review", the window shows the assembled delivery instruction (as after pressing "Review the delivery").

var main
var out := "/tmp/courier_window.png"
var with_review := false
var args_formal := false
var frames := 0
var win: CourierWindow


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	with_review = args.has("review")
	args_formal = args.has("formal")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	main.save_path = "user://test_saves/courier_shot/save1.json"
	main.new_game()
	var w: World = main.world
	var cs := w.couriers                              # the live service: the village's booth, the settlements' booths and the routes
	var friend: NPC = null
	var merchant: NPC = null
	for n: NPC in w.npcs:
		if not n.alive:
			continue
		if friend == null and n.role == "adult" and n.job == "farmer":
			friend = n
		elif merchant == null and w.brain.buy_role(n) == "merchant_goods":
			merchant = n
	var keeper: NPC = w.npc(int(str(cs.booth_of("village").keeper).trim_prefix("npc:")))
	keeper.skills["law"] = Skills.xp_for_level(int(CourierService.cfg().notary.min_level))      # fixture: a keeper with the legal standing
	w.relations.tie(Life.PLAYER_ID, friend.id).days_known = 3          # fixture: someone the player knows
	w.note_settlement_trade(w.player, w.regions.by_id["wulstead"])    # a past dealing with Wulstead's trader
	w.player.coins += 50
	w.player.inv.add("plank", 12)
	w.player.inv.add("wheat", 20)
	w.relations.note_trade(Life.PLAYER_ID, merchant.id, 0)          # fixture: a past purchase at the goods merchant's stall
	win = CourierWindow.new(main.ui, cs)
	win.choice.kind = 1
	win.choice.item = maxi(0, w.player.inv.ids().find("plank"))
	win.choice.qty = 6
	win.choice.collect = true
	win.choice.pay_amount = 12
	win.choice.offer = 10
	win.booth_id = str(cs.booth_of("village").id)
	win.choice.recipient = cs.known_recipients("player").map(func(e): return e.ref).find("region:wulstead/trader")
	if with_review and args_formal:
		win.choice.pay_amount = 90
	if with_review:
		var o := win.order()
		var why := cs.refusal(o)
		win.review = why if why != "" else cs.describe(o)
	win.show()
	process_frame.connect(_wait)


func _wait() -> void:
	frames += 1
	if frames < 20:
		return
	process_frame.disconnect(_wait)
	var img := root.get_texture().get_image()
	img.save_png(out)
	print("saved ", out, " ", img.get_size())
	quit(0)
