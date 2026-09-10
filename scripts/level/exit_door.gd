extends Area2D
## Exit door → collector / next.

signal used

var open := true
var label: Label

func _ready() -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, 64)
	shape.shape = rect
	add_child(shape)
	var vis := ColorRect.new()
	vis.size = Vector2(36, 64)
	vis.position = Vector2(-18, -64)
	vis.color = Color(0.35, 0.25, 0.45)
	add_child(vis)
	label = Label.new()
	label.text = "出口\n[E]"
	label.add_theme_font_size_override("font_size", 14)
	label.position = Vector2(-28, -100)
	label.modulate = Color(1, 0.9, 0.6)
	add_child(label)

func _unhandled_input(event: InputEvent) -> void:
	if not open:
		return
	if event.is_action_pressed("interact"):
		var player := get_tree().get_first_node_in_group("player")
		if player and is_instance_valid(player):
			if global_position.distance_to(player.global_position) < 48.0:
				used.emit()
