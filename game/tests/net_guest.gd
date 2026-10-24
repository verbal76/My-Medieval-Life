extends SceneTree
## Multiplayer A2 test guest (from the MP-01 prototype) in its own Godot process: joins a host with a given identity key and writes what
## happened (welcomed or the refusal code) to user://test_net/<out>. Args after "--":
## port key name password out_file dir.

var main
var a: PackedStringArray
var t := 0.0


func _init() -> void:
	a = OS.get_cmdline_user_args()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = str(a[5]) + "guest_unused.json"
	process_frame.connect(func():
		main.net.join("127.0.0.1", int(a[0]), str(a[1]), str(a[2]), str(a[3])), CONNECT_ONE_SHOT)


func _process(delta: float) -> bool:
	t += delta
	var done: bool = main.guest_world or main.net.refusal != "" or t > 45.0
	if done:
		var f := FileAccess.open(str(a[5]) + str(a[4]), FileAccess.WRITE)
		f.store_string(JSON.stringify({"welcomed": main.guest_world, "refusal": main.net.refusal}))
		f.close()
		main.net.leave()
		quit(0)
	return false
