class_name Projectile
extends Area2D

var velocity := Vector2.RIGHT * 700
var damage := 10
var from_player := true
var freeze := false
var life := 2.0
var knockback := 120.0

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1 | 2 | 8
	body_entered.connect(_on_body)
	area_entered.connect(_on_area)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6.0
	shape.shape = circle
	add_child(shape)
	var vis := Line2D.new()
	vis.width = 3.0
	vis.default_color = Color(0.9, 0.85, 0.55) if not freeze else Color(0.6, 0.9, 1.0)
	vis.points = PackedVector2Array([Vector2(-8, 0), Vector2(8, 0)])
	add_child(vis)

func _physics_process(delta: float) -> void:
	position += velocity * delta
	life -= delta
	if life <= 0.0:
		queue_free()

func _on_body(body: Node) -> void:
	if from_player and body.is_in_group("enemies"):
		if body.has_method("take_hit"):
			body.take_hit(damage, signf(velocity.x), knockback, freeze)
		queue_free()
	elif body is StaticBody2D or body is TileMapLayer:
		queue_free()
	elif not from_player and body.is_in_group("player"):
		if body.has_method("receive_hit"):
			body.receive_hit(damage, signf(velocity.x))
		queue_free()

func _on_area(area: Area2D) -> void:
	if from_player and area.get_parent().is_in_group("enemies"):
		var e = area.get_parent()
		if e.has_method("take_hit"):
			e.take_hit(damage, signf(velocity.x), knockback, freeze)
		queue_free()
