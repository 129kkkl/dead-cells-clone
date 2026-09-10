extends SceneTree
## Headless smoke test: load menu, start run, simulate a few frames.

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
	var menu = load("res://scenes/ui/main_menu.tscn")
	if menu == null:
		printerr("SMOKE_FAIL menu")
		quit(1)
		return
	var menu_inst = menu.instantiate()
	root.add_child(menu_inst)
	await process_frame
	await process_frame
	print("SMOKE_MENU_OK")

	gs.start_new_run(12345)
	var level = load("res://scenes/level/level.tscn")
	if level == null:
		printerr("SMOKE_FAIL level")
		quit(1)
		return
	menu_inst.queue_free()
	await process_frame
	var level_inst = level.instantiate()
	root.add_child(level_inst)
	for i in 30:
		await physics_frame
		await process_frame
	print("SMOKE_LEVEL_OK frames=30")
	print("PLAYER_HP=", gs.hp, " SEED=", gs.run_seed)
	print("ENEMIES=", root.get_tree().get_nodes_in_group("enemies").size())
	print("PLAYER=", root.get_tree().get_first_node_in_group("player") != null)
	sm.save_game(1)
	print("SMOKE_SAVE_OK")
	var ok = sm.load_game(1)
	print("SMOKE_LOAD=", ok)
	print("SMOKE_PASS")
	quit(0)
