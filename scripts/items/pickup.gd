extends Area2D
## Cell / gold pickup.

var kind := "cell"
var value := 1
var collected := false
var magnet_speed := 0.0

func setup(k: String, v: int) -> void:
	kind = k
	value = v

func _ready() -> void:
	monitoring = true
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 10.0
	shape.shape = c
	add_child(shape)
	var vis := ColorRect.new()
	if kind == "cell":
		vis.color = Color(0.95, 0.3, 0.55)
		vis.size = Vector2(8, 10)
	else:
		vis.color = Color(0.95, 0.8, 0.25)
		vis.size = Vector2(8, 8)
	vis.position = -vis.size / 2.0
	add_child(vis)
	body_entered.connect(_on_body)
	# bob
	var tw := create_tween().set_loops()
	tw.tween_property(vis, "position:y", vis.position.y - 3.0, 0.4).from(vis.position.y)
	tw.tween_property(vis, "position:y", vis.position.y, 0.4)

func _physics_process(delta: float) -> void:
	if collected:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var d := global_position.distance_to(player.global_position)
		if d < 90.0:
			magnet_speed = lerpf(magnet_speed, 280.0, 8.0 * delta)
			global_position = global_position.move_toward(player.global_position, magnet_speed * delta)

func _on_body(body: Node) -> void:
	if collected:
		return
	if body.is_in_group("player"):
		collected = true
		if kind == "cell":
			GameState.add_cells(value)
		else:
			GameState.add_gold(value)
		queue_free()
