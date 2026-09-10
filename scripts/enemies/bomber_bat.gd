extends EnemyBase
## Suicide bat — dives and explodes.

func _init() -> void:
	enemy_id = "bomber_bat"
	display_name = "自杀蝙蝠"
	max_hp = 12
	damage = 22
	move_speed = 160.0
	aggro_range = 300.0
	attack_range = 28.0
	attack_cooldown = 3.0
	attack_windup = 0.55
	flying = true

var exploding := false

func _build_visual() -> void:
	var body := ColorRect.new()
	body.size = Vector2(16, 14)
	body.position = Vector2(-8, -7)
	body.color = Color(0.7, 0.2, 0.15)
	add_child(body)
	var glow := ColorRect.new()
	glow.size = Vector2(6, 6)
	glow.position = Vector2(-3, -4)
	glow.color = Color(1.0, 0.7, 0.2)
	add_child(glow)

func _chase(delta: float) -> void:
	var target = player.global_position + Vector2(0, -12)
	velocity = (target - global_position).normalized() * move_speed * 1.3

func _perform_attack() -> void:
	exploding = true
	_explode()

func _explode() -> void:
	EventBus.camera_trauma.emit(0.5)
	if player and is_instance_valid(player) and not player.dead:
		var dist = global_position.distance_to(player.global_position)
		if dist < 70.0:
			if player.has_method("is_parrying") and player.is_parrying():
				_on_parried()
				return
			var dir = signf(player.global_position.x - global_position.x)
			player.receive_hit(damage, dir if dir != 0 else 1.0)
	_die()
