extends Node2D
## Builds the prison level from LevelGenerator output and runs the run loop.

const PickupScript := preload("res://scripts/items/pickup.gd")
const ExitDoorScript := preload("res://scripts/level/exit_door.gd")
const ProjectileScript := preload("res://scripts/combat/projectile.gd")
const PlayerScene := preload("res://scenes/player/player.tscn")

const ENEMY_SCRIPTS := {
	"zombie": "res://scripts/enemies/zombie.gd",
	"bat": "res://scripts/enemies/bat.gd",
	"grenadier": "res://scripts/enemies/grenadier.gd",
	"bomber_bat": "res://scripts/enemies/bomber_bat.gd",
}

@onready var world: Node2D = $World
@onready var ysort: Node2D = $World/YSort
@onready var fx: Node2D = $World/FX
@onready var camera: Camera2D = $Camera
@onready var hud: CanvasLayer = $HUD
@onready var pause_ui: CanvasLayer = $PauseUI
@onready var death_ui: CanvasLayer = $DeathUI
@onready var collector_ui: CanvasLayer = $CollectorUI

var level_data: Dictionary
var player: CharacterBody2D
var trauma := 0.0
var hitstop := 0.0
var exit_door: Area2D

func _ready() -> void:
	EventBus.camera_trauma.connect(func(a: float): trauma = minf(trauma + a, 1.0))
	EventBus.hitstop_requested.connect(func(d: float): hitstop = maxf(hitstop, d))
	EventBus.player_died.connect(_on_player_died)

	if not GameState.in_run:
		GameState.start_new_run(GameState.settings.get("seed", 0))

	level_data = LevelGenerator.generate(GameState.run_seed)
	_build_geometry()
	_spawn_torches()
	_spawn_enemies_and_loot()
	_spawn_player()
	_spawn_exit()
	_show_biome_title()
	EventBus.biome_title.emit("被囚者牢房")
	SaveManager.save_game()

func _build_geometry() -> void:
	var gw: int = level_data["grid"]
	var rw: int = level_data["room_w"]
	var rh: int = level_data["room_h"]
	# outer boundary + simple floors/platforms per room
	for room in level_data["rooms"]:
		if room["type"] == 0 and not room["on_path"]:
			# empty filler — still solid walls so you don't fall into void if you wander
			continue
		var origin: Vector2 = room["origin"]
		_floor_block(origin + Vector2(0, rh - 24), Vector2(rw, 24))
		_wall_block(origin + Vector2(-16, 0), Vector2(16, rh))
		_wall_block(origin + Vector2(rw, 0), Vector2(16, rh))
		# interior platforms
		var rng := RandomNumberGenerator.new()
		rng.seed = GameState.run_seed + origin.x * 31 + origin.y * 17
		for i in rng.randi_range(1, 3):
			var px := origin.x + rng.randf_range(60, rw - 140)
			var py := origin.y + rng.randf_range(rh * 0.35, rh * 0.7)
			_floor_block(Vector2(px, py), Vector2(rng.randf_range(70, 120), 16))
		# ceiling
		_wall_block(origin + Vector2(0, -16), Vector2(rw, 16))

	# full outer boundary of the map
	var total_w := gw * rw
	var total_h := gw * rh
	_wall_block(Vector2(-40, -40), Vector2(total_w + 80, 40))
	_wall_block(Vector2(-40, total_h), Vector2(total_w + 80, 80))
	_wall_block(Vector2(-40, 0), Vector2(40, total_h))
	_wall_block(Vector2(total_w, 0), Vector2(40, total_h))

	# decorative stone tiles
	for room in level_data["rooms"]:
		if room["type"] == 0 and not room["on_path"]:
			continue
		var origin: Vector2 = room["origin"]
		for tx in range(12):
			for ty in range(6):
				if randf() < 0.35:
					var brick := ColorRect.new()
					brick.size = Vector2(40, 18)
					brick.position = origin + Vector2(tx * 40, ty * 28 + 8)
					brick.color = Color(0.22, 0.18, 0.24).lerp(Color(0.3, 0.25, 0.32), randf())
					brick.z_index = -5
					world.add_child(brick)

func _floor_block(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos + size * 0.5
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	var vis := ColorRect.new()
	vis.size = size
	vis.position = -size * 0.5
	vis.color = Color(0.28, 0.24, 0.3)
	body.add_child(vis)
	var top := ColorRect.new()
	top.size = Vector2(size.x, 4)
	top.position = Vector2(-size.x * 0.5, -size.y * 0.5)
	top.color = Color(0.42, 0.36, 0.4)
	body.add_child(top)
	world.add_child(body)

func _wall_block(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos + size * 0.5
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	var vis := ColorRect.new()
	vis.size = size
	vis.position = -size * 0.5
	vis.color = Color(0.18, 0.15, 0.2)
	body.add_child(vis)
	world.add_child(body)

func _spawn_torches() -> void:
	for room in level_data["rooms"]:
		if room["type"] == 0 and not room["on_path"]:
			continue
		var origin: Vector2 = room["origin"]
		for t: Vector2 in room["torches"]:
			var torch := Node2D.new()
			torch.position = origin + t
			var stick := ColorRect.new()
			stick.size = Vector2(4, 16)
			stick.position = Vector2(-2, 0)
			stick.color = Color(0.35, 0.25, 0.15)
			torch.add_child(stick)
			var flame := ColorRect.new()
			flame.size = Vector2(8, 10)
			flame.position = Vector2(-4, -12)
			flame.color = Color(1.0, 0.65, 0.2)
			torch.add_child(flame)
			var light := PointLight2D.new()
			var tex := _make_light_texture()
			light.texture = tex
			light.texture_scale = 3.2
			light.energy = 1.35
			light.color = Color(1.0, 0.75, 0.45)
			torch.add_child(light)
			# flicker
			var tw := create_tween().set_loops()
			tw.tween_property(light, "energy", 1.0, 0.15)
			tw.tween_property(light, "energy", 1.5, 0.12)
			tw.tween_property(flame, "scale", Vector2(1.1, 1.25), 0.1)
			tw.tween_property(flame, "scale", Vector2.ONE, 0.1)
			world.add_child(torch)

func _make_light_texture() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var d := Vector2(x - 32, y - 32).length() / 32.0
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = a * a
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)

func _spawn_enemies_and_loot() -> void:
	var pickup_script = PickupScript
	for room in level_data["rooms"]:
		if room["type"] == 0 and not room["on_path"]:
			continue
		var origin: Vector2 = room["origin"]
		var rw: int = level_data["room_w"]
		var rh: int = level_data["room_h"]
		for eid: String in room["enemies"]:
			var script = load(ENEMY_SCRIPTS[eid])
			var e = script.new()
			e.position = origin + Vector2(randf_range(80, rw - 80), rh - 50)
			ysort.add_child(e)
		for i in room["cells"]:
			var p = pickup_script.new()
			p.setup("cell", 1)
			p.position = origin + Vector2(randf_range(60, rw - 60), rh - 40)
			ysort.add_child(p)
		for i in randi_range(0, 2):
			var g = pickup_script.new()
			g.setup("gold", randi_range(5, 15))
			g.position = origin + Vector2(randf_range(60, rw - 60), rh - 40)
			ysort.add_child(g)

func _spawn_player() -> void:
	var scene := load("res://scenes/player/player.tscn")
	if scene:
		player = scene.instantiate()
	else:
		player = CharacterBody2D.new()
		player.set_script(load("res://scripts/player/player.gd"))
	var start: Vector2i = level_data["start_coord"]
	var origin := Vector2(start.x * level_data["room_w"], start.y * level_data["room_h"])
	player.position = origin + Vector2(level_data["room_w"] * 0.5, level_data["room_h"] - 80)
	ysort.add_child(player)
	player.attacked.connect(_on_player_attacked)
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0

func _spawn_exit() -> void:
	exit_door = ExitDoorScript.new()
	var exit: Vector2i = level_data["exit_coord"]
	var origin := Vector2(exit.x * level_data["room_w"], exit.y * level_data["room_h"])
	exit_door.position = origin + Vector2(level_data["room_w"] * 0.75, level_data["room_h"] - 24)
	exit_door.used.connect(_on_exit_used)
	ysort.add_child(exit_door)

func _on_player_attacked(info: Dictionary) -> void:
	match info.get("type"):
		"melee":
			_melee_hit(info)
		"ranged":
			var p := ProjectileScript.new()
			p.from_player = true
			p.damage = info["damage"]
			p.freeze = info.get("freeze", false)
			p.velocity = Vector2(info["facing"] * info["speed"], 0)
			p.global_position = info["position"]
			fx.add_child(p)
		"skill":
			_skill_blast(info)

func _melee_hit(info: Dictionary) -> void:
	var origin: Vector2 = info["position"]
	var facing: int = info["facing"]
	var rng: Vector2 = info["range"]
	var box := Rect2(origin + Vector2(facing * 8 - rng.x * 0.5, -rng.y * 0.75), Vector2(rng.x, rng.y))
	for e in ysort.get_children():
		if e.is_in_group("enemies") and e.has_method("take_hit"):
			if box.has_point(e.global_position + Vector2(0, -12)) or box.grow(10).has_point(e.global_position):
				e.take_hit(info["damage"], facing, info.get("knockback", 160.0), false)
				_blood(e.global_position)
				break

func _skill_blast(info: Dictionary) -> void:
	var pos: Vector2 = info["position"] + Vector2(info["facing"] * 40, 0)
	var radius: float = info.get("radius", 64.0)
	for e in ysort.get_children():
		if e.is_in_group("enemies") and e.has_method("take_hit"):
			if e.global_position.distance_to(pos) < radius:
				e.take_hit(info["damage"], info["facing"], 140.0, not info.get("burn", false))
				_blood(e.global_position)
	# visual ring
	var ring := ColorRect.new()
	ring.size = Vector2(radius, radius)
	ring.position = pos - Vector2(radius, radius) * 0.5
	ring.color = Color(0.6, 0.85, 1.0, 0.35)
	fx.add_child(ring)
	var tw := create_tween()
	tw.tween_property(ring, "modulate:a", 0.0, 0.25)
	tw.tween_callback(ring.queue_free)
	EventBus.camera_trauma.emit(0.35)

func _blood(pos: Vector2) -> void:
	for i in 6:
		var p := ColorRect.new()
		p.size = Vector2(3, 3)
		p.color = Color(0.7, 0.1, 0.12)
		p.position = pos + Vector2(randf_range(-8, 8), randf_range(-16, 0))
		fx.add_child(p)
		var vel := Vector2(randf_range(-80, 80), randf_range(-120, -20))
		var tw := create_tween()
		var target := p.position + vel * 0.25 + Vector2(0, 80)
		tw.tween_property(p, "position", target, 0.25)
		tw.tween_callback(p.queue_free)

func _process(delta: float) -> void:
	# hitstop
	if hitstop > 0.0:
		hitstop -= delta
		Engine.time_scale = 0.05
	else:
		Engine.time_scale = move_toward(Engine.time_scale, 1.0, 0.2)

	trauma = maxf(trauma - delta * 1.8, 0.0)
	if player and is_instance_valid(player):
		camera.global_position = player.global_position
		var shake := trauma * trauma
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 14.0 * shake
		player.process_skill_cooldowns(delta)

func _on_player_died() -> void:
	Engine.time_scale = 1.0
	death_ui.visible = true
	get_tree().paused = false
	if death_ui.has_method("show_death"):
		death_ui.show_death()

func _on_exit_used() -> void:
	EventBus.level_exited.emit()
	Engine.time_scale = 1.0
	collector_ui.visible = true
	if collector_ui.has_method("open"):
		collector_ui.open()

func _show_biome_title() -> void:
	if hud.has_method("flash_biome"):
		hud.flash_biome("被囚者牢房")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if collector_ui.visible or death_ui.visible:
			return
		pause_ui.visible = not pause_ui.visible
		get_tree().paused = pause_ui.visible
	if event.is_action_pressed("open_map") and hud.has_method("toggle_map"):
		hud.toggle_map(level_data)
