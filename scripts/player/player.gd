extends CharacterBody2D
## Player controller: move / jump / roll i-frames / melee / parry / bow / skill.

const SPEED := 220.0
const JUMP_VELOCITY := -430.0
const GRAVITY := 1200.0
const ROLL_SPEED := 420.0
const ROLL_TIME := 0.22
const ROLL_IFRAME := 0.28
const ATTACK_IFRAME := 0.0
const HITSTOP := 0.05

@onready var anim: AnimatedSprite2D = $Anim
@onready var hurtbox: Area2D = $Hurtbox
@onready var attack_origin: Marker2D = $AttackOrigin
@onready var muzzle: Marker2D = $Muzzle
@onready var shield_visual: Node2D = $ShieldVisual

var facing := 1
var rolling := false
var roll_timer := 0.0
var iframe_timer := 0.0
var attack_timer := 0.0
var attack_queued := false
var combo_index := 0
var combo_window := 0.0
var parry_timer := 0.0
var dead := false
var invuln_debug := false
var last_roll_dir := 1

signal attacked(hit_info: Dictionary)
signal parried(pos: Vector2)

func _ready() -> void:
	add_to_group("player")
	EventBus.player_health_changed.connect(_on_hp)
	_ensure_sprites()
	_update_weapon_visual()

func _ensure_sprites() -> void:
	if anim == null:
		return
	if anim.sprite_frames == null:
		anim.sprite_frames = SpriteFrames.new()
	var sf: SpriteFrames = anim.sprite_frames
	for anim_name in ["idle", "run", "jump", "roll"]:
		if not sf.has_animation(anim_name):
			sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, 8.0)
		sf.set_animation_loop(anim_name, true)
		while sf.get_frame_count(anim_name) > 0:
			sf.remove_frame(anim_name, 0)
		sf.add_frame(anim_name, _make_player_frame(anim_name, 0))
		sf.add_frame(anim_name, _make_player_frame(anim_name, 1))
	anim.play("idle")

func _make_player_frame(anim_name: String, frame: int) -> ImageTexture:
	var img := Image.create(24, 40, false, Image.FORMAT_RGBA8)
	for y in range(12, 38):
		for x in range(6, 18):
			img.set_pixel(x, y, Color(0.15, 0.55, 0.55))
	for y in range(4, 14):
		for x in range(8, 16):
			img.set_pixel(x, y, Color(0.92, 0.78, 0.62))
	for y in range(2, 8):
		for x in range(7, 17):
			img.set_pixel(x, y, Color(0.1, 0.35, 0.4))
	var lift := 2 if (frame == 1 and (anim_name == "run" or anim_name == "roll")) else 0
	for x in range(8, 12):
		img.set_pixel(x, clampi(38 - lift, 0, 39), Color(0.12, 0.12, 0.16))
		img.set_pixel(x, clampi(39 - lift, 0, 39), Color(0.12, 0.12, 0.16))
	for x in range(13, 17):
		var lift2 := 0 if lift > 0 else 1
		img.set_pixel(x, clampi(38 - lift2, 0, 39), Color(0.12, 0.12, 0.16))
		img.set_pixel(x, clampi(39 - lift2, 0, 39), Color(0.12, 0.12, 0.16))
	img.set_pixel(14, 8, Color(0.1, 0.1, 0.1))
	if anim_name == "roll":
		img.fill_rect(Rect2i(4, 18, 16, 18), Color(0.15, 0.55, 0.55))
	return ImageTexture.create_from_image(img)

func _physics_process(delta: float) -> void:
	if dead:
		return
	iframe_timer = maxf(iframe_timer - delta, 0.0)
	attack_timer = maxf(attack_timer - delta, 0.0)
	parry_timer = maxf(parry_timer - delta, 0.0)
	combo_window = maxf(combo_window - delta, 0.0)
	if combo_window <= 0.0:
		combo_index = 0

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if rolling:
		roll_timer -= delta
		velocity.x = last_roll_dir * ROLL_SPEED
		if roll_timer <= 0.0:
			rolling = false
		move_and_slide()
		_animate()
		return

	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0 and attack_timer <= 0.05:
		facing = 1 if dir > 0 else -1
		velocity.x = dir * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED * 10.0 * delta)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		EventBus.camera_trauma.emit(0.15)

	if Input.is_action_just_pressed("roll") and not rolling:
		_start_roll(dir)

	if Input.is_action_just_pressed("attack_primary"):
		_try_primary()

	if Input.is_action_just_pressed("attack_secondary"):
		_try_secondary()

	if Input.is_action_just_pressed("skill_1"):
		_try_skill(0)

	if Input.is_action_just_pressed("skill_2"):
		_try_skill(1)

	if Input.is_action_just_pressed("swap_weapon"):
		_swap_secondary()
	if Input.is_action_just_pressed("swap_primary"):
		_swap_primary()

	move_and_slide()
	_animate()
	shield_visual.visible = parry_timer > 0.0
	scale.x = facing

func _swap_primary() -> void:
	var options: Array[String] = ["rusty_sword"]
	if GameState.unlocked_blueprints.get("double_dagger", false):
		options.append("double_dagger")
	if GameState.unlocked_blueprints.get("assassin_dagger", false):
		options.append("assassin_dagger")
	if options.size() < 2:
		EventBus.toast.emit("没有可切换的主武器")
		return
	var cur: String = GameState.weapons[0]
	var idx := options.find(cur)
	if idx < 0:
		idx = 0
	var nxt: String = options[(idx + 1) % options.size()]
	GameState.weapons[0] = nxt
	combo_index = 0
	EventBus.weapon_changed.emit(0, nxt)
	EventBus.toast.emit("主武器：%s" % WeaponDB.weapon(nxt).get("name", nxt))

func _swap_secondary() -> void:
	var options: Array[String] = ["wooden_shield"]
	if GameState.unlocked_blueprints.get("beginner_bow", true):
		options.append("beginner_bow")
	if GameState.unlocked_blueprints.get("ice_bow", false):
		options.append("ice_bow")
	if options.size() < 2:
		EventBus.toast.emit("没有可切换的副武器")
		return
	var cur: String = GameState.weapons[1]
	var idx := options.find(cur)
	if idx < 0:
		idx = 0
	var nxt: String = options[(idx + 1) % options.size()]
	GameState.weapons[1] = nxt
	EventBus.weapon_changed.emit(1, nxt)
	EventBus.toast.emit("副武器：%s" % WeaponDB.weapon(nxt).get("name", nxt))

func _animate() -> void:
	if anim == null or anim.sprite_frames == null:
		return
	if rolling:
		if anim.sprite_frames.has_animation("roll"):
			anim.play("roll")
		return
	if not is_on_floor():
		anim.play("jump" if anim.sprite_frames.has_animation("jump") else "idle")
	elif absf(velocity.x) > 10:
		anim.play("run" if anim.sprite_frames.has_animation("run") else "idle")
	else:
		anim.play("idle")

func _start_roll(dir: float) -> void:
	rolling = true
	roll_timer = ROLL_TIME
	iframe_timer = maxf(iframe_timer, ROLL_IFRAME)
	last_roll_dir = facing if dir == 0.0 else (1 if dir > 0 else -1)
	attack_timer = 0.0
	parry_timer = 0.0
	EventBus.camera_trauma.emit(0.2)
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("roll"):
		anim.play("roll")

func _try_primary() -> void:
	if rolling or attack_timer > 0.0:
		if attack_timer > 0.0:
			attack_queued = true
		return
	var wid: String = GameState.weapons[0]
	var data := WeaponDB.weapon(wid)
	if data["type"] == "melee":
		_do_melee(wid, data)
	elif data["type"] == "ranged":
		_do_ranged(wid, data)
	elif data["type"] == "shield":
		_do_parry(data)

func _try_secondary() -> void:
	if rolling:
		return
	var wid: String = GameState.weapons[1]
	var data := WeaponDB.weapon(wid)
	if data["type"] == "shield":
		if parry_timer <= 0.0:
			_do_parry(data)
	elif data["type"] == "ranged":
		if attack_timer <= 0.0:
			_do_ranged(wid, data)
	elif data["type"] == "melee":
		if attack_timer <= 0.0:
			_do_melee(wid, data)

func _do_melee(wid: String, data: Dictionary) -> void:
	var combo: Array = data.get("combo", [data.get("damage", 10)])
	if combo_index >= combo.size():
		combo_index = 0
	var dmg: int = combo[combo_index]
	combo_index += 1
	combo_window = 0.55
	attack_timer = float(data.get("cooldown", 0.3))
	var info := {
		"damage": dmg,
		"position": attack_origin.global_position,
		"facing": facing,
		"range": data.get("range", Vector2(48, 28)),
		"knockback": 180.0,
		"type": "melee",
		"crit_from_behind": data.get("crit_from_behind", false),
	}
	attacked.emit(info)
	EventBus.hitstop_requested.emit(HITSTOP)
	EventBus.camera_trauma.emit(0.12)
	_spawn_slash()
	if attack_queued:
		attack_queued = false
		# allow soft cancel into next combo after a short delay
		attack_timer = minf(attack_timer, 0.12)

func _do_ranged(wid: String, data: Dictionary) -> void:
	attack_timer = float(data.get("cooldown", 0.5))
	var info := {
		"damage": data.get("damage", 10),
		"position": muzzle.global_position,
		"facing": facing,
		"speed": data.get("projectile_speed", 700),
		"freeze": data.get("freeze", false),
		"type": "ranged",
		"weapon": wid,
	}
	attacked.emit(info)
	EventBus.camera_trauma.emit(0.08)

func _do_parry(data: Dictionary) -> void:
	parry_timer = float(data.get("parry_window", 0.25))
	attack_timer = float(data.get("cooldown", 0.4))
	# brief block iframe as well
	iframe_timer = maxf(iframe_timer, parry_timer * 0.6)
	EventBus.toast.emit("招架！")

func _try_skill(slot: int) -> void:
	if slot < 0 or slot >= GameState.skills.size():
		return
	var sid: String = GameState.skills[slot]
	if sid.is_empty() or GameState.skill_cd[slot] > 0.0:
		return
	var data := WeaponDB.skill(sid)
	if data.is_empty():
		return
	GameState.skill_cd[slot] = float(data.get("cooldown", 6.0))
	GameState.skill_cd_max[slot] = GameState.skill_cd[slot]
	var info := {
		"damage": data.get("damage", 15),
		"position": muzzle.global_position,
		"facing": facing,
		"radius": data.get("radius", 64),
		"burn": data.get("burn", false),
		"type": "skill",
		"skill": sid,
	}
	attacked.emit(info)
	EventBus.skill_cooldown_changed.emit(slot, 1.0)

func process_skill_cooldowns(delta: float) -> void:
	for i in GameState.skill_cd.size():
		if GameState.skill_cd[i] > 0.0:
			GameState.skill_cd[i] = maxf(GameState.skill_cd[i] - delta, 0.0)
			var ratio := 0.0
			if GameState.skill_cd_max[i] > 0.0:
				ratio = GameState.skill_cd[i] / GameState.skill_cd_max[i]
			EventBus.skill_cooldown_changed.emit(i, ratio)

func is_parrying() -> bool:
	return parry_timer > 0.0

func has_iframe() -> bool:
	return iframe_timer > 0.0 or invuln_debug

func receive_hit(amount: int, from_dir: float) -> void:
	if dead or has_iframe():
		return
	iframe_timer = 0.4
	velocity.x = from_dir * 280.0
	velocity.y = minf(velocity.y, -120.0)
	GameState.take_damage(amount)
	EventBus.camera_trauma.emit(0.45)
	_flash()
	if GameState.hp <= 0:
		die()

func _flash() -> void:
	var tw := create_tween()
	modulate = Color(1, 0.4, 0.4)
	tw.tween_property(self, "modulate", Color.WHITE, 0.18)

func die() -> void:
	if dead:
		return
	dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	EventBus.player_died.emit()

func _on_hp(_c: int, _m: int) -> void:
	pass

func _update_weapon_visual() -> void:
	pass

func _spawn_slash() -> void:
	var slash := Line2D.new()
	slash.width = 4.0
	slash.default_color = Color(1, 0.95, 0.7, 0.9)
	var dir := facing
	var pts := PackedVector2Array([
		Vector2(dir * 10, -18),
		Vector2(dir * 36, -8),
		Vector2(dir * 48, 8),
	])
	slash.points = pts
	add_child(slash)
	var tw := create_tween()
	tw.tween_property(slash, "modulate:a", 0.0, 0.12)
	tw.tween_callback(slash.queue_free)
