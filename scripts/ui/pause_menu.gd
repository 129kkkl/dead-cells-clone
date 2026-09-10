extends CanvasLayer

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Root/Resume.pressed.connect(func():
		visible = false
		get_tree().paused = false
		)
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
