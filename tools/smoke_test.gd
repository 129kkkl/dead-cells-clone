extends SceneTree
## Headless smoke test: menu, level gen, doors, enemies, save/load.

func _gs():
	return root.get_node("GameState")

func _sm():
	return root.get_node("SaveManager")

func _init() -> void:
	print("SMOKE_START")
	await process_frame
	await process_frame
	var gs = _gs()
	var sm = _sm()
	if gs == null or sm == null:
		printerr("SMOKE_FAIL autoload missing")
		quit(1)
		return

	# generator connectivity
	var lg = load("res://scripts/level/level_generator.gd")
	var data = lg.generate(12345)
	var path = data["path"]
	print("PATH_LEN=", path.size(), " START=", data["start_coord"], " EXIT=", data["exit_coord"])
	if path.size() < 2:
		printerr("SMOKE_FAIL path too short")
		quit(1)
		return
	# all consecutive path cells must be adjacent
	var adjacent_ok := true
	for i in range(path.size() - 1):
		var a: Vector2i = path[i]
		var b: Vector2i = path[i + 1]
		var manhattan = abs(a.x - b.x) + abs(a.y - b.y)
		if manhattan != 1:
			adjacent_ok = false
			printerr("SMOKE_FAIL non-adjacent ", a, "->", b)
	print("ADJACENT_OK=", adjacent_ok)
	if not adjacent_ok:
		quit(1)
		return

	# doors on path edges
	var doors_ok := true
	for i in range(path.size() - 1):
		var a: Vector2i = path[i]
		var b: Vector2i = path[i + 1]
		var da = null
		var db = null
		for room in data["rooms"]:
			if room["coord"] == a:
				da = room["doors"]
			if room["coord"] == b:
				db = room["doors"]
		if b.x == a.x and b.y == a.y + 1:
			if not da["down"] or not db["up"]:
				doors_ok = false
				printerr("SMOKE_FAIL missing vertical door ", a, b)
		if b.x == a.x + 1 and b.y == a.y:
			if not da["right"] or not db["left"]:
				doors_ok = false
				printerr("SMOKE_FAIL missing horizontal door ", a, b)
		if b.x == a.x - 1 and b.y == a.y:
			if not da["left"] or not db["right"]:
				doors_ok = false
				printerr("SMOKE_FAIL missing horizontal door ", a, b)
	print("DOORS_OK=", doors_ok)
	if not doors_ok:
		quit(1)
		return

	gs.start_new_run(12345)
	var menu = load("res://scenes/ui/main_menu.tscn")
	var menu_inst = menu.instantiate()
	root.add_child(menu_inst)
	await process_frame
	print("SMOKE_MENU_OK")
	menu_inst.queue_free()
	await process_frame

	var level = load("res://scenes/level/level.tscn")
	var level_inst = level.instantiate()
	root.add_child(level_inst)
	for i in 30:
		await physics_frame
		await process_frame
	print("SMOKE_LEVEL_OK")
	print("ENEMIES=", root.get_tree().get_nodes_in_group("enemies").size())
	print("PLAYER=", root.get_tree().get_first_node_in_group("player") != null)
	print("STATIC_BODIES=", root.get_tree().get_nodes_in_group("").size())
	# count static bodies under world
	var static_count := 0
	for n in level_inst.get_node("World").get_children():
		if n is StaticBody2D:
			static_count += 1
	print("WORLD_STATIC=", static_count)
	sm.save_game(1)
	print("SMOKE_SAVE_OK")
	print("SMOKE_LOAD=", sm.load_game(1))
	print("SMOKE_PASS")
	quit(0)
