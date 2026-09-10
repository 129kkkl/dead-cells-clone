class_name EnemyBase
extends CharacterBody2D

enum State { IDLE, PATROL, CHASE, ATTACK, HURT, DEAD }

@export var enemy_id := "zombie"
@export var display_name := "僵尸"
@export var max_hp := 40
@export var damage := 12
@export var move_speed := 70.0
@export var aggro_range := 220.0
@export var attack_range := 36.0
@export var attack_cooldown := 1.2
@export var attack_windup := 0.35
@export var flying := false
@export var gravity_scale := 1.0

var hp := 0
var state: int = State.IDLE
var player: Node2D = null
var face := -1
var attack_cd_timer := 0.0
var windup_timer := 0.0
var hurt_timer := 0.0
var freeze_timer := 0.0
var elite := false
var alert_mark: Label
var patrol_dir := 1
var patrol_timer := 0.0

func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	collision_layer = 2
	collision_mask = 1
	_ensure_collision()
	player = get_tree().get_first_node_in_group("player")
	_build_visual()
	_build_alert()

func _ensure_collision() -> void:
	for c in get_children():
		if c is CollisionShape2D:
			return
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	if flying:
		shape.size = Vector2(20, 16)
		cs.position = Vector2(0, -6)
	else:
		shape.size = Vector2(22, 36)
		cs.position = Vector2(0, -18)
	cs.shape = shape
	add_child(cs)

func _build_visual() -> void:
	pass

func _build_alert() -> void:
	alert_mark = Label.new()
	alert_mark.text = "!"
	alert_mark.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	alert_mark.add_theme_font_size_override("font_size", 28)
	alert_mark.position = Vector2(-8, -48)
	alert_mark.visible = false
	add_child(alert_mark)

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if freeze_timer > 0.0:
		freeze_timer -= delta
		velocity = Vector2.ZERO
		modulate = Color(0.55, 0.8, 1.0)
		move_and_slide()
		return
	else:
		modulate = modulate.lerp(Color.WHITE, 0.2)

	attack_cd_timer = maxf(attack_cd_timer - delta, 0.0)
	hurt_timer = maxf(hurt_timer - delta, 0.0)

	if not flying:
		velocity.y += 1200.0 * gravity_scale * delta
	else:
		velocity.y = move_toward(velocity.y, 0.0, 400 * delta)

	if player == null or not is_instance_valid(player) or player.dead:
		_patrol(delta)
		move_and_slide()
		return

	var dist := global_position.distance_to(player.global_position)
	var to_player := player.global_position - global_position
	face = 1 if to_player.x > 0 else -1

	match state:
		State.IDLE, State.PATROL:
			if dist < aggro_range:
				state = State.CHASE
				alert_mark.visible = false
			else:
				_patrol(delta)
		State.CHASE:
			if dist <= attack_range and attack_cd_timer <= 0.0:
				_start_windup()
			elif dist > aggro_range * 1.4:
				state = State.PATROL
			else:
				_chase(delta)
		State.ATTACK:
			velocity.x = 0.0
			windup_timer -= delta
			if windup_timer <= 0.0:
				_do_attack()
		State.HURT:
			velocity.x = move_toward(velocity.x, 0.0, 800 * delta)
			if hurt_timer <= 0.0:
				state = State.CHASE

	move_and_slide()

func _patrol(delta: float) -> void:
	patrol_timer -= delta
	if patrol_timer <= 0.0:
		patrol_timer = randf_range(1.0, 2.5)
		patrol_dir *= -1
	if flying:
		velocity.x = patrol_dir * move_speed * 0.4
		velocity.y = sin(Time.get_ticks_msec() / 400.0) * 20.0
	else:
		velocity.x = patrol_dir * move_speed * 0.35

func _chase(delta: float) -> void:
	if flying:
		var target = player.global_position + Vector2(0, -20)
		velocity = (target - global_position).normalized() * move_speed
	else:
		velocity.x = face * move_speed
		if not is_on_floor():
			velocity.x *= 0.8

func _start_windup() -> void:
	state = State.ATTACK
	windup_timer = attack_windup
	alert_mark.visible = true
	_on_windup_start()

func _on_windup_start() -> void:
	pass

func _do_attack() -> void:
	alert_mark.visible = false
	attack_cd_timer = attack_cooldown
	state = State.CHASE
	_perform_attack()

func _perform_attack() -> void:
	if player and is_instance_valid(player) and not player.dead:
		var dist = global_position.distance_to(player.global_position)
		if dist <= attack_range + 12.0:
			if player.has_method("is_parrying") and player.is_parrying():
				_on_parried()
				return
			var dir = signf(player.global_position.x - global_position.x)
			player.receive_hit(damage, dir if dir != 0 else -face)

func _on_parried() -> void:
	state = State.HURT
	hurt_timer = 0.8
	velocity.x = -face * 200.0
	EventBus.toast.emit("招架成功！")

func take_hit(amount: int, dir: float, knockback: float = 160.0, freeze: bool = false) -> void:
	if state == State.DEAD:
		return
	hp -= amount
	if freeze:
		freeze_timer = 1.2
	velocity.x = dir * knockback
	if not flying:
		velocity.y = minf(velocity.y, -100.0)
	if hp <= 0:
		_die()
	else:
		state = State.HURT
		hurt_timer = 0.15
	_flash_white()

func _flash_white() -> void:
	modulate = Color(2.5, 2.5, 2.5)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.12)

func _die() -> void:
	state = State.DEAD
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	EventBus.enemy_killed.emit(enemy_id, global_position)
	GameState.killed_this_level += 1
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)
