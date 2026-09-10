extends SceneTree
## Capture screenshots of menu and gameplay using the viewport.

var shots_dir := "user://shots"

func _ready_dir() -> void:
	DirAccess.make_dir_recursive_absolute(shots_dir)

func _save_shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = root.get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [shots_dir, name]
	img.save_png(path)
	print("SHOT=", path, " size=", img.get_size())

func _init() -> void:
	print("CAPTURE_START")
	_ready_dir()
	# render with actual display if possible
	await process_frame
	await process_frame

	var menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	for i in 10:
		await process_frame
	await _save_shot("01_main_menu")

	var gs = root.get_node("GameState")
	gs.start_new_run(12345)
	menu.queue_free()
	await process_frame
	var level = load("res://scenes/level/level.tscn").instantiate()
	root.add_child(level)
	for i in 40:
		await physics_frame
		await process_frame
	await _save_shot("02_gameplay")
	print("CAPTURE_DONE")
	quit(0)
