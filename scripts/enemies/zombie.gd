extends EnemyBase
## Zombie — ground chase, three-hit combo telegraph.

func _init() -> void:
	enemy_id = "zombie"
	display_name = "僵尸"
	max_hp = 45
	damage = 12
	move_speed = 78.0
	aggro_range = 240.0
	attack_range = 40.0
	attack_cooldown = 1.35
	attack_windup = 0.4
	flying = false

func _build_visual() -> void:
	var body := ColorRect.new()
	body.size = Vector2(22, 36)
	body.position = Vector2(-11, -36)
	body.color = Color(0.35, 0.55, 0.32)
	add_child(body)
	var head := ColorRect.new()
	head.size = Vector2(16, 14)
	head.position = Vector2(-8, -50)
	head.color = Color(0.45, 0.65, 0.4)
	add_child(head)
	var eye := ColorRect.new()
	eye.size = Vector2(4, 4)
	eye.position = Vector2(-2, -46)
	eye.color = Color(0.9, 0.2, 0.15)
	add_child(eye)
