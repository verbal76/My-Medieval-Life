extends SceneTree
## PROSPECTIVE (Expansion 18, X18-Q12-POST): opens the courier contract window in the real game scene and saves a
## screenshot, so the window is looked at before it is called done. Needs a display (not --headless):
##   xvfb-run -a godot --rendering-driver opengl3 --path game --script res://tests/courier_window_shot.gd -- OUT.png [review]
## With "review", the window shows the assembled delivery instruction (as after pressing "Review the delivery").

var main
var out := "/tmp/courier_window.png"
var with_review := false
var frames := 0
var win: CourierWindow


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	with_review = args.has("review")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	main.save_path = "user://test_saves/courier_shot/save1.json"
	main.new_game()
	var w: World = main.world
	var cs := CourierService.new(w)
	var keeper: NPC = null
	var friend: NPC = null
	var merchant: NPC = null
	for n: NPC in w.npcs:
		if not n.alive:
			continue
		if keeper == null and w.construction.can_hire(n) == "":
			keeper = n
		elif friend == null and n.role == "adult" and n.job == "farmer":
			friend = n
		elif merchant == null and w.brain.buy_role(n) == "merchant_goods":
			merchant = n
	keeper.inv.add("plank", 3)                       # fixture: the keeper's planks for a booth stall
	var free := ""
	for sid in w.stalls:
		if str(w.stalls[sid].get("tenant", "")) == "":
			free = sid
	print("booth: ", cs.open_booth("npc:%d" % keeper.id, free))
	var east := SettlementLedger.make({"id": "eastmarch", "name": "Eastmarch", "pos": [900, 0], "coins": 300})
	cs.open_region_booth(east)
	cs.links = TradeRoutes.table([SettlementLedger.make({"id": "village"}), east], [["village", "eastmarch", 900, {"road": 1.0}]])
	cs.add_route(str(cs.booth_of("village").id), str(cs.booth_of("eastmarch").id), -1.0, 2)
	w.relations.tie(Life.PLAYER_ID, friend.id).days_known = 3          # fixture: someone the player knows
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
