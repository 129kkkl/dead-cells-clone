extends EnemyBase
## Bat — flying dive.

func _init() -> void:
	enemy_id = "bat"
	display_name = "蝙蝠"
	max_hp = 22
	damage = 10
	move_speed = 130.0
	aggro_range = 280.0
	attack_range = 22.0
	attack_cooldown = 1.1
	attack_windup = 0.25
	flying = true

func _build_visual() -> void:
	var body := ColorRect.new()
	body.size = Vector2(18, 12)
	body.position = Vector2(-9, -6)
	body.color = Color(0.25, 0.18, 0.35)
	add_child(body)
	var wing_l := ColorRect.new()
	wing_l.size = Vector2(14, 6)
	wing_l.position = Vector2(-22, -10)
	wing_l.color = Color(0.35, 0.22, 0.45)
	add_child(wing_l)
	var wing_r := ColorRect.new()
	wing_r.size = Vector2(14, 6)
	wing_r.position = Vector2(8, -10)
	wing_r.color = Color(0.35, 0.22, 0.45)
	add_child(wing_r)

func _chase(delta: float) -> void:
	var target = player.global_position + Vector2(0, -24)
	velocity = (target - global_position).normalized() * move_speed * 1.15
