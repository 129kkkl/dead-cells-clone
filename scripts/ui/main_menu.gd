extends Control
## Chinese main menu — no fake buttons.

@onready var main_panel: VBoxContainer = $Center/MainPanel
@onready var start_panel: VBoxContainer = $Center/StartPanel
@onready var slots_panel: VBoxContainer = $Center/SlotsPanel
@onready var settings_panel: VBoxContainer = $Center/SettingsPanel
@onready var seed_label: Label = $Center/SettingsPanel/SeedLabel

func _ready() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	_show_panel(main_panel)
	$Center/MainPanel/StartBtn.pressed.connect(func(): _show_panel(start_panel))
	$Center/MainPanel/SettingsBtn.pressed.connect(_open_settings)
	$Center/MainPanel/QuitBtn.pressed.connect(func(): get_tree().quit())
	$Center/StartPanel/ContinueBtn.pressed.connect(_on_continue)
	$Center/StartPanel/RestartBtn.pressed.connect(func(): _show_panel(slots_panel))
	$Center/StartPanel/DailyBtn.pressed.connect(_on_daily)
	$Center/StartPanel/BackBtn1.pressed.connect(func(): _show_panel(main_panel))
	$Center/SlotsPanel/BackBtn2.pressed.connect(func(): _show_panel(start_panel))
	$Center/SlotsPanel/Slot1.pressed.connect(func(): _new_run(1))
	$Center/SlotsPanel/Slot2.pressed.connect(func(): _new_run(2))
	$Center/SlotsPanel/Slot3.pressed.connect(func(): _new_run(3))
	$Center/SettingsPanel/Fullscreen.toggled.connect(_on_fullscreen)
	$Center/SettingsPanel/BackBtn3.pressed.connect(func(): _show_panel(main_panel))
	$Center/SettingsPanel/SeedCopy.pressed.connect(func():
		DisplayServer.clipboard_set(str(GameState.settings.get("seed", 0)))
		)
	_update_continue_state()
	_update_slot_labels()

func _show_panel(p: Control) -> void:
	for c in [main_panel, start_panel, slots_panel, settings_panel]:
		c.visible = c == p

func _update_continue_state() -> void:
	var any := false
	for i in GameState.MAX_SLOTS:
		if SaveManager.has_save(i + 1):
			any = true
			break
	$Center/StartPanel/ContinueBtn.disabled = not any

func _update_slot_labels() -> void:
	for i in GameState.MAX_SLOTS:
		var slot: int = i + 1
		var btn: Button = [$Center/SlotsPanel/Slot1, $Center/SlotsPanel/Slot2, $Center/SlotsPanel/Slot3][i]
		if SaveManager.has_save(slot):
			btn.text = "存档 %d（有进度）" % slot
		else:
			btn.text = "存档 %d（新游戏）" % slot

func _on_continue() -> void:
	for i in GameState.MAX_SLOTS:
		if SaveManager.has_save(i + 1):
			if SaveManager.load_game(i + 1):
				if GameState.in_run:
					get_tree().change_scene_to_file("res://scenes/level/level.tscn")
					return
				# meta-only save: start fresh run keeping unlocks
				var seed_v = GameState.settings.get("seed", 0)
				GameState.start_new_run(seed_v)
				get_tree().change_scene_to_file("res://scenes/level/level.tscn")
				return

func _new_run(slot: int) -> void:
	GameState.current_slot = slot
	if SaveManager.has_save(slot):
		SaveManager.load_game(slot)
	GameState.start_new_run(randi() % 1_000_000_000)
	SaveManager.save_game(slot)
	get_tree().change_scene_to_file("res://scenes/level/level.tscn")

func _on_daily() -> void:
	var dt: Dictionary = Time.get_date_dict_from_system()
	var seed_v: int = int(dt.get("year", 2026)) * 10000 + int(dt.get("month", 1)) * 100 + int(dt.get("day", 1))
	GameState.current_slot = 1
	GameState.start_new_run(seed_v)
	get_tree().change_scene_to_file("res://scenes/level/level.tscn")

func _open_settings() -> void:
	_show_panel(settings_panel)
	seed_label.text = "当前种子：%s" % str(GameState.settings.get("seed", 0))
	$Center/SettingsPanel/Fullscreen.button_pressed = GameState.settings.get("fullscreen", false)

func _on_fullscreen(on: bool) -> void:
	GameState.settings["fullscreen"] = on
	GameState._apply_display_settings()
	SaveManager.save_settings()
