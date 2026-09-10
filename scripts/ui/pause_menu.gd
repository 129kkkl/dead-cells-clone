extends CanvasLayer

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Root/Resume.pressed.connect(_resume)
	$Root/SaveQuit.pressed.connect(func():
		SaveManager.save_game()
		get_tree().paused = false
		Engine.time_scale = 1.0
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
		)
	$Root/QuitDesktop.pressed.connect(func():
		SaveManager.save_game()
		get_tree().quit()
		)

func _resume() -> void:
	visible = false
	get_tree().paused = false
	Engine.time_scale = 1.0

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause"):
		_resume()
		get_viewport().set_input_as_handled()
