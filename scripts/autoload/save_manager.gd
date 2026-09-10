extends Node
## Multi-slot JSON save system.

const SAVE_DIR := "user://saves"
const SAVE_VERSION := 1

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, slot]

func save_game(slot: int = -1) -> void:
	if slot < 0:
		slot = GameState.current_slot
	GameState.current_slot = slot
	var data := {
		"version": SAVE_VERSION,
		"unlocked_blueprints": GameState.unlocked_blueprints.duplicate(),
		"bank_cells": GameState.bank_cells,
		"permanent_gold_cap_level": GameState.permanent_gold_cap_level,
		"boss_cells": GameState.boss_cells,
		"baby_mode": GameState.baby_mode,
		"settings": GameState.settings.duplicate(),
		"run": {
			"seed": GameState.run_seed,
			"cells": GameState.run_cells,
			"gold": GameState.run_gold,
			"hp": GameState.hp,
			"max_hp": GameState.max_hp,
			"weapons": GameState.weapons.duplicate(),
			"skills": GameState.skills.duplicate(),
			"in_run": GameState.in_run,
			"level_index": GameState.current_level_index,
		} if GameState.in_run else null,
		"saved_at": Time.get_datetime_string_from_system(),
	}
	var f := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if f == null:
		push_error("无法写入存档: %s" % slot_path(slot))
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	EventBus.save_completed.emit(slot)

func load_game(slot: int) -> bool:
	if not FileAccess.file_exists(slot_path(slot)):
		return false
	var f := FileAccess.open(slot_path(slot), FileAccess.READ)
	if f == null:
		return false
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var data: Dictionary = parsed
	GameState.current_slot = slot
	GameState.unlocked_blueprints = data.get("unlocked_blueprints", GameState.unlocked_blueprints)
	GameState.bank_cells = int(data.get("bank_cells", 0))
	GameState.permanent_gold_cap_level = int(data.get("permanent_gold_cap_level", 0))
	GameState.boss_cells = int(data.get("boss_cells", 0))
	GameState.baby_mode = bool(data.get("baby_mode", false))
	var st = data.get("settings")
	if typeof(st) == TYPE_DICTIONARY:
		for k in st.keys():
			GameState.settings[k] = st[k]
	var run = data.get("run")
	if typeof(run) == TYPE_DICTIONARY:
		GameState.run_seed = int(run.get("seed", 0))
		GameState.run_cells = int(run.get("cells", 0))
		GameState.run_gold = int(run.get("gold", 0))
		GameState.hp = int(run.get("hp", GameState.BASE_MAX_HP))
		GameState.max_hp = int(run.get("max_hp", GameState.BASE_MAX_HP))
		GameState.weapons = Array(run.get("weapons", ["rusty_sword", "beginner_bow"]), TYPE_STRING, "", null)
		GameState.skills = Array(run.get("skills", ["ice_grenade", ""]), TYPE_STRING, "", null)
		GameState.in_run = bool(run.get("in_run", false))
		GameState.current_level_index = int(run.get("level_index", 0))
	else:
		GameState.in_run = false
	GameState._apply_display_settings()
	return true

func has_save(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))

func delete_save(slot: int) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(slot_path(slot))

func save_settings() -> void:
	save_game(GameState.current_slot)

func deposit_run_cells_to_bank() -> void:
	GameState.bank_cells += GameState.run_cells
	GameState.run_cells = 0
	EventBus.cells_changed.emit(0)
	save_game()
