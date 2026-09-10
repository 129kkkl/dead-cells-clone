class_name LevelGenerator
## 4x4 room grid: critical path from row 0 to row 3, then fill side rooms.
## Room types: 0 side, 1 left-right, 2 left-right-down, 3 left-right-up

const GRID := 4
const ROOM_W := 480
const ROOM_H := 320

static func generate(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var types := []
	types.resize(GRID)
	for y in GRID:
		types[y] = []
		types[y].resize(GRID)
		for x in GRID:
			types[y][x] = 0

	var path: Array = []
	var start_x := rng.randi_range(0, GRID - 1)
	path.append(Vector2i(start_x, 0))
	types[0][start_x] = 1

	# walk down to last row
	while path[path.size() - 1].y < GRID - 1:
		var cur: Vector2i = path[path.size() - 1]
		var next_x := cur.x
		if rng.randf() < 0.55:
			var step := 1 if rng.randf() < 0.5 else -1
			var nx := clampi(cur.x + step, 0, GRID - 1)
			next_x = nx
		var next := Vector2i(next_x, cur.y + 1)
		path.append(next)

	# set path room types by connections
	for i in path.size():
		var p: Vector2i = path[i]
		var has_down: bool = i < path.size() - 1 and path[i + 1].y == p.y + 1
		var has_up: bool = i > 0 and path[i - 1].y == p.y - 1
		if has_down and has_up:
			types[p.y][p.x] = 1
		elif has_down:
			types[p.y][p.x] = 2
		else:
			types[p.y][p.x] = 3

	# fill some non-path rooms
	for y in GRID:
		for x in GRID:
			if types[y][x] == 0 and rng.randf() < 0.45:
				types[y][x] = 1

	var rooms := []
	for y in GRID:
		for x in GRID:
			var t: int = types[y][x]
			var is_path := false
			for p in path:
				if p.x == x and p.y == y:
					is_path = true
					break
			var enemy_count := 0
			if is_path:
				enemy_count = 2 + rng.randi_range(0, 2)
				if y >= 2:
					enemy_count += 1
			elif t != 0:
				enemy_count = 1 + rng.randi_range(0, 2)
			else:
				enemy_count = 0
			var enemies := []
			for i in enemy_count:
				enemies.append(_pick_enemy(rng, y))
			var torches := []
			for i in rng.randi_range(1, 3):
				torches.append(Vector2(rng.randf_range(60, ROOM_W - 60), rng.randf_range(40, ROOM_H - 80)))
			rooms.append({
				"coord": Vector2i(x, y),
				"type": t,
				"on_path": is_path,
				"enemies": enemies,
				"torches": torches,
				"origin": Vector2(x * ROOM_W, y * ROOM_H),
				"cells": rng.randi_range(1, 3) if is_path else (1 if t != 0 else 0),
			})

	var start_coord: Vector2i = path[0]
	var exit_coord: Vector2i = path[path.size() - 1]
	return {
		"seed": seed_value,
		"rooms": rooms,
		"path": path,
		"start_coord": start_coord,
		"exit_coord": exit_coord,
		"room_w": ROOM_W,
		"room_h": ROOM_H,
		"grid": GRID,
	}

static func _pick_enemy(rng: RandomNumberGenerator, row: int) -> String:
	var pool := ["zombie", "zombie", "bat"]
	if row >= 1:
		pool.append("grenadier")
	if row >= 2:
		pool.append("bomber_bat")
		pool.append("bat")
	return pool[rng.randi_range(0, pool.size() - 1)]

static func room_world_rect(room: Dictionary, room_w: int, room_h: int) -> Rect2:
	return Rect2(room["origin"], Vector2(room_w, room_h))
