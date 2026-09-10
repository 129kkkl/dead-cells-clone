extends EnemyBase
## Grenadier — throws bombs, backs away if close.

const ProjectileScript := preload("res://scripts/combat/projectile.gd")

func _init() -> void:
	enemy_id = "grenadier"
	display_name = "掷弹兵"
	max_hp = 38
	damage = 16
	move_speed = 55.0
	aggro_range = 320.0
	attack_range = 220.0
	attack_cooldown = 2.2
	attack_windup = 0.55
	flying = false

func _build_visual() -> void:
	var body := ColorRect.new()
	body.size = Vector2(24, 34)
	body.position = Vector2(-12, -34)
	body.color = Color(0.55, 0.35, 0.25)
	add_child(body)
	var head := ColorRect.new()
	head.size = Vector2(14, 12)
	head.position = Vector2(-7, -48)
	head.color = Color(0.7, 0.55, 0.4)
	add_child(head)
	var bomb := ColorRect.new()
	bomb.size = Vector2(8, 8)
	bomb.position = Vector2(10, -24)
	bomb.color = Color(0.15, 0.15, 0.15)
	add_child(bomb)

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if freeze_timer > 0.0:
		freeze_timer -= delta
		velocity = Vector2.ZERO
		modulate = Color(0.55, 0.8, 1.0)
		move_and_slide()
		return
	attack_cd_timer = maxf(attack_cd_timer - delta, 0.0)
	hurt_timer = maxf(hurt_timer - delta, 0.0)
	velocity.y += 1200.0 * delta

	if player == null or not is_instance_valid(player) or player.dead:
		_patrol(delta)
		move_and_slide()
		return

	var dist := global_position.distance_to(player.global_position)
	var to_player := player.global_position - global_position
	face = 1 if to_player.x > 0 else -1

	if state == State.ATTACK:
		velocity.x = 0.0
		windup_timer -= delta
		if windup_timer <= 0.0:
			_do_attack()
	elif dist < 70.0:
		# retreat
		velocity.x = -face * move_speed * 1.4
		state = State.CHASE
	elif dist < aggro_range:
		state = State.CHASE
		if dist <= attack_range and attack_cd_timer <= 0.0:
			_start_windup()
		else:
			velocity.x = face * move_speed * 0.5
	else:
		_patrol(delta)

	move_and_slide()

func _perform_attack() -> void:
	if player == null or not is_instance_valid(player):
		return
	var p := ProjectileScript.new()
	p.from_player = false
	p.damage = damage
	p.velocity = Vector2(face * 280, -220)
	p.global_position = global_position + Vector2(face * 16, -20)
	get_parent().add_child(p)
