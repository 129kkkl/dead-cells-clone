extends CanvasLayer

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Root/Retry.pressed.connect(func():
		Engine.time_scale = 1.0
		get_tree().paused = false
		if GameState.baby_mode:
			GameState.hp = GameState.max_hp
			GameState.in_run = true
			GameState.killed_this_level = 0
			get_tree().reload_current_scene()
		else:
			GameState.reset_run_state_after_death()
			SaveManager.save_game()
			get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
		)
	$Root/Menu.pressed.connect(func():
		Engine.time_scale = 1.0
		get_tree().paused = false
		GameState.reset_run_state_after_death()
		SaveManager.save_game()
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
		)
	$Root/BabyToggle.toggled.connect(func(on: bool):
		GameState.baby_mode = on
		SaveManager.save_settings()
		)

func show_death() -> void:
	visible = true
	$Root/BabyToggle.button_pressed = GameState.baby_mode
	$Root/Stats.text = "本层击杀 %d　细胞 %d　金币 %d" % [
		GameState.killed_this_level, GameState.run_cells, GameState.run_gold
	]
