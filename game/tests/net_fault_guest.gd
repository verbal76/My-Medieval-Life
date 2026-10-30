extends SceneTree
## Multiplayer Batch D test guest (net_fault_test.gd): the real game joining a host and staying, so the test can kill it, freeze it
## or let it reconnect. Writes <dir><out> every 0.2 s: {welcomed, pid, guest_world, reconnecting, reconnects, refusal}.
## Args after "--": port key name password out_file dir.

var main
var a: PackedStringArray
var t := 0.0


func _init() -> void:
	a = OS.get_cmdline_user_args()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = str(a[5]) + "fault_guest_unused.json"
	process_frame.connect(func():
		main.net.join("127.0.0.1", int(a[0]), str(a[1]), str(a[2]), str(a[3])), CONNECT_ONE_SHOT)


func _process(delta: float) -> bool:
	t += delta
	if t < 0.2:
		return false
	t = 0.0
	var net: NetSession = main.net
	var f := FileAccess.open(str(a[5]) + str(a[4]), FileAccess.WRITE)
	f.store_string(JSON.stringify({"welcomed": main.guest_world, "pid": net.my_pid, "guest_world": main.guest_world,
		"reconnecting": net.reconnecting, "reconnects": net.reconnects, "refusal": net.refusal, "os_pid": OS.get_process_id()}))
	f.close()
	return false
