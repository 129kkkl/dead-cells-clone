extends CanvasLayer
## Collector between levels: spend run cells on blueprints / gold cap, then continue.

const BLUEPRINT_ORDER := ["ice_bow", "double_dagger", "assassin_dagger"]

@onready var list: VBoxContainer = $Root/Scroll/List
@onready var cells_label: Label = $Root/Cells
@onready var bank_label: Label = $Root/Bank

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Root/Continue.pressed.connect(_continue)
	$Root/Deposit.pressed.connect(_deposit)

func open() -> void:
	visible = true
	get_tree().paused = true
	_refresh()

func _refresh() -> void:
	cells_label.text = "本轮细胞：%d" % GameState.run_cells
	bank_label.text = "收藏家银行：%d" % GameState.bank_cells
	for c in list.get_children():
		c.queue_free()
	for id in BLUEPRINT_ORDER:
		var data: Dictionary = WeaponDB.WEAPONS[id]
		var unlocked: bool = GameState.unlocked_blueprints.get(id, false)
		var row := HBoxContainer.new()
		var lab := Label.new()
		lab.text = "%s — %s（%d 细胞）" % [data["name"], data["desc"], data["cost"]]
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lab)
		var btn := Button.new()
		if unlocked:
			btn.text = "已解锁"
			btn.disabled = true
		else:
			btn.text = "解锁"
			btn.pressed.connect(func(): _unlock(id, data["cost"], btn))
		row.add_child(btn)
		list.add_child(row)
	# permanent gold cap
	var cap_row := HBoxContainer.new()
	var cap_lab := Label.new()
	var next_cost := 15 + GameState.permanent_gold_cap_level * 15
	cap_lab.text = "永久金币上限升级（当前 %d → %d，%d 细胞）" % [
		GameState.gold_cap(), GameState.gold_cap() + 500, next_cost
	]
	cap_lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cap_row.add_child(cap_lab)
	var cap_btn := Button.new()
	cap_btn.text = "投资"
	cap_btn.pressed.connect(func(): _buy_cap(next_cost, cap_btn))
	cap_row.add_child(cap_btn)
	list.add_child(cap_row)

func _unlock(id: String, cost: int, btn: Button) -> void:
	if GameState.spend_cells(cost):
		GameState.unlocked_blueprints[id] = true
		btn.text = "已解锁"
		btn.disabled = true
		cells_label.text = "本轮细胞：%d" % GameState.run_cells
		EventBus.toast.emit("解锁 %s" % WeaponDB.WEAPONS[id]["name"])
		SaveManager.save_game()
	else:
		EventBus.toast.emit("细胞不足")

func _buy_cap(cost: int, btn: Button) -> void:
	if GameState.spend_cells(cost):
		GameState.permanent_gold_cap_level += 1
		btn.disabled = true
		cells_label.text = "本轮细胞：%d" % GameState.run_cells
		SaveManager.save_game()
		_refresh()
	else:
		EventBus.toast.emit("细胞不足")

func _deposit() -> void:
	SaveManager.deposit_run_cells_to_bank()
	_refresh()

func _continue() -> void:
	# bank remaining run cells into permanent bank automatically for fairness
	if GameState.run_cells > 0:
		SaveManager.deposit_run_cells_to_bank()
	GameState.current_level_index += 1
	# new seed variation for next loop while keeping meta
	var next_seed: int = GameState.run_seed + 1 + GameState.current_level_index
	GameState.run_seed = next_seed
	GameState.settings["seed"] = next_seed
	GameState.hp = mini(GameState.hp + 30, GameState.max_hp)
	SaveManager.save_game()
	get_tree().paused = false
	Engine.time_scale = 1.0
	# reload level with new seed
	get_tree().reload_current_scene()
