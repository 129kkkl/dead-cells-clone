extends CanvasLayer
## In-game HUD: HP, gold, cells, weapons, skills, minimap, biome title.

@onready var hp_bar: ProgressBar = $Root/HPBar
@onready var hp_fill: ColorRect = $Root/HPFill
@onready var hp_label: Label = $Root/HPLabel
@onready var gold_label: Label = $Root/Gold
@onready var cell_label: Label = $Root/Cells
@onready var w1: Label = $Root/Slots/W1
@onready var w2: Label = $Root/Slots/W2
@onready var s1: Label = $Root/Slots/S1
@onready var s2: Label = $Root/Slots/S2
@onready var biome: Label = $Root/Biome
@onready var toast: Label = $Root/Toast
@onready var map_panel: Control = $Root/Map
@onready var map_draw: Control = $Root/Map/Draw
@onready var seed_label: Label = $Root/Seed
@onready var attr_label: Label = $Root/Attrs

var _map_data: Dictionary = {}
var _toast_tw: Tween

func _ready() -> void:
	EventBus.player_health_changed.connect(_on_hp)
	EventBus.cells_changed.connect(func(c: int): cell_label.text = "细胞 %d" % c)
	EventBus.gold_changed.connect(func(g: int): gold_label.text = "金币 %d" % g)
	EventBus.toast.connect(_show_toast)
	EventBus.skill_cooldown_changed.connect(_on_cd)
	EventBus.biome_title.connect(flash_biome)
	EventBus.weapon_changed.connect(func(_s, _id): _refresh_equipment())
	map_panel.visible = false
	if map_draw and map_draw.get_script() == null:
		map_draw.set_script(load("res://scripts/ui/minimap_draw.gd"))
	_refresh_equipment()
	_on_hp(GameState.hp, GameState.max_hp)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.1, 0.14)
	hp_bar.add_theme_stylebox_override("background", sb)
	var fill_sb := StyleBoxFlat.new()
	fill_sb.bg_color = Color(0.12, 0.1, 0.14)
	hp_bar.add_theme_stylebox_override("fill", fill_sb)
	cell_label.text = "细胞 %d" % GameState.run_cells
	gold_label.text = "金币 %d" % GameState.run_gold
	seed_label.text = "种子 %d" % GameState.run_seed

func _refresh_equipment() -> void:
	var w1d := WeaponDB.weapon(GameState.weapons[0])
	var w2d := WeaponDB.weapon(GameState.weapons[1])
	w1.text = "[J] %s" % w1d.get("name", "?")
	w2.text = "[K] %s" % w2d.get("name", "?")
	var s1d := WeaponDB.skill(GameState.skills[0])
	s1.text = "[U] %s" % (s1d.get("name", "空") if not s1d.is_empty() else "空")
	var s2d := WeaponDB.skill(GameState.skills[1]) if not GameState.skills[1].is_empty() else {}
	s2.text = "[I] %s" % (s2d.get("name", "空") if not s2d.is_empty() else "空")
	attr_label.text = "残酷 1  战术 1  生存 1"

func _on_hp(c: int, m: int) -> void:
	hp_bar.max_value = m
	hp_bar.value = c
	hp_label.text = "HP %d/%d" % [c, m]
	if hp_fill:
		var ratio := 0.0 if m <= 0 else float(c) / float(m)
		hp_fill.size.x = hp_bar.size.x * ratio
		hp_fill.visible = ratio > 0.0

func _on_cd(slot: int, ratio: float) -> void:
	var lab: Label = s1 if slot == 0 else s2
	if ratio <= 0.0:
		_refresh_equipment()
	else:
		var base = "[U] " if slot == 0 else "[I] "
		var name = WeaponDB.skill(GameState.skills[slot]).get("name", "")
		lab.text = "%s%s (%.1f)" % [base, name, GameState.skill_cd[slot]]

func flash_biome(name: String) -> void:
	biome.text = name
	biome.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(biome, "modulate:a", 1.0, 0.3)
	tw.tween_interval(1.6)
	tw.tween_property(biome, "modulate:a", 0.0, 0.5)

func _show_toast(text: String) -> void:
	toast.text = text
	toast.modulate.a = 1.0
	if _toast_tw and _toast_tw.is_valid():
		_toast_tw.kill()
	_toast_tw = create_tween()
	_toast_tw.tween_interval(0.8)
	_toast_tw.tween_property(toast, "modulate:a", 0.0, 0.3)

func toggle_map(data: Dictionary = {}) -> void:
	if not data.is_empty():
		_map_data = data
	map_panel.visible = not map_panel.visible
	if map_panel.visible:
		map_draw.queue_redraw()

func _process(_d: float) -> void:
	if map_panel.visible:
		map_draw.queue_redraw()
