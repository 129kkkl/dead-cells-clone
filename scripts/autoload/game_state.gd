extends Node
## Permanent meta progress + current run state.

const MAX_SLOTS := 3
const BASE_MAX_HP := 100
const STARTING_CELLS := 0
const STARTING_GOLD := 50

# Permanent (saved)
var unlocked_blueprints: Dictionary = {
	"rusty_sword": true,
	"wooden_shield": true,
	"beginner_bow": true,
}
var bank_cells: int = 0
var permanent_gold_cap_level: int = 0
var boss_cells: int = 0
var baby_mode: bool = false
var settings: Dictionary = {
	"fullscreen": false,
	"volume": 0.8,
	"seed": 0,
}

# Current run (not all saved mid-run)
var run_seed: int = 0
var run_cells: int = 0
var run_gold: int = 0
var hp: int = BASE_MAX_HP
var max_hp: int = BASE_MAX_HP
var weapons: Array[String] = ["rusty_sword", "beginner_bow"]
var skills: Array[String] = ["ice_grenade", ""]
var skill_cd: Array[float] = [0.0, 0.0]
var skill_cd_max: Array[float] = [6.0, 0.0]
var current_slot: int = 1
var in_run: bool = false
var current_level_index: int = 0
var killed_this_level: int = 0

func _enter_tree() -> void:
	_setup_input_map()
	_apply_display_settings()

func gold_cap() -> int:
	return 500 + permanent_gold_cap_level * 500

func start_new_run(seed_value: int = 0) -> void:
	if seed_value == 0:
		seed_value = randi() % 1_000_000_000
	run_seed = seed_value
	settings["seed"] = run_seed
	run_cells = 0
	run_gold = STARTING_GOLD
	if run_gold > gold_cap():
		run_gold = gold_cap()
	hp = BASE_MAX_HP
	max_hp = BASE_MAX_HP
	weapons = ["rusty_sword", "wooden_shield"]
	if unlocked_blueprints.get("ice_bow", false):
		# bow goes into secondary via swap; shield remains default K
		pass
	skills = ["ice_grenade", ""]
	skill_cd = [0.0, 0.0]
	skill_cd_max = [6.0, 0.0]
	in_run = true
	current_level_index = 0
	killed_this_level = 0
	EventBus.run_started.emit(run_seed)

func continue_run() -> void:
	in_run = true

func reset_run_state_after_death() -> void:
	run_cells = 0
	run_gold = 0
	hp = 0
	in_run = false
	killed_this_level = 0

func add_cells(n: int) -> void:
	run_cells += n
	EventBus.cells_changed.emit(run_cells)

func add_gold(n: int) -> void:
	run_gold = clampi(run_gold + n, 0, gold_cap())
	EventBus.gold_changed.emit(run_gold)

func spend_cells(n: int) -> bool:
	if run_cells < n:
		return false
	run_cells -= n
	EventBus.cells_changed.emit(run_cells)
	return true

func spend_any_cells(n: int) -> bool:
	## Prefer run cells, then bank.
	if run_cells + bank_cells < n:
		return false
	var from_run := mini(run_cells, n)
	run_cells -= from_run
	var rest := n - from_run
	bank_cells -= rest
	EventBus.cells_changed.emit(run_cells)
	return true

func take_damage(amount: int) -> void:
	hp = maxi(hp - amount, 0)
	EventBus.player_health_changed.emit(hp, max_hp)
	# death side-effect is owned by Player.die()

func heal(amount: int) -> void:
	hp = mini(hp + amount, max_hp)
	EventBus.player_health_changed.emit(hp, max_hp)

func _setup_input_map() -> void:
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("jump", [KEY_SPACE])
	_add_key_action("roll", [KEY_SHIFT, KEY_L])
	_add_key_action("attack_primary", [KEY_J])
	_add_key_action("attack_secondary", [KEY_K])
	_add_key_action("skill_1", [KEY_U])
	_add_key_action("skill_2", [KEY_I])
	_add_key_action("interact", [KEY_E])
	_add_key_action("open_map", [KEY_TAB])
	_add_key_action("pause", [KEY_ESCAPE])
	_add_key_action("swap_weapon", [KEY_Q])
	_add_key_action("swap_primary", [KEY_R])

func _add_key_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)

func _apply_display_settings() -> void:
	if settings.get("fullscreen", false):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
