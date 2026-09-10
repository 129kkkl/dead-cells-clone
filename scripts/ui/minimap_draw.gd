extends Control
## Minimap painter.

var data: Dictionary = {}

func _draw() -> void:
	var hud = get_parent().get_parent()
	if hud and hud.has_method("get") and hud.get("_map_data") != null:
		data = hud._map_data
	if data.is_empty():
		return
	var gw: int = data.get("grid", 4)
	var cell := 36.0
	var origin := Vector2(40, 40)
	for room in data.get("rooms", []):
		var c: Vector2i = room["coord"]
		var explored: bool = room.get("on_path", false) or room.get("type", 0) != 0
		if not explored:
			continue
		var col := Color(0.25, 0.22, 0.3)
		if room.get("on_path", false):
			col = Color(0.55, 0.4, 0.25)
		if c == data.get("start_coord"):
			col = Color(0.3, 0.7, 0.4)
		if c == data.get("exit_coord"):
			col = Color(0.85, 0.55, 0.2)
		draw_rect(Rect2(origin + Vector2(c.x * cell, c.y * cell), Vector2(cell - 4, cell - 4)), col)
	# player
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var rw: float = data.get("room_w", 480)
		var rh: float = data.get("room_h", 320)
		var px = int(player.global_position.x / rw)
		var py = int(player.global_position.y / rh)
		draw_rect(Rect2(origin + Vector2(px * cell, py * cell), Vector2(cell - 4, cell - 4)), Color(0.9, 0.9, 0.3))
