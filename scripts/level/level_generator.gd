class_name LevelGenerator
## 4x4 room grid. Path only moves to adjacent cells (N/S/E/W).
## Each room stores explicit door openings used by the builder.

const GRID := 4
const ROOM_W := 480
const ROOM_H := 320

static func generate(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var path: Array = []
	var start_x := rng.randi_range(0, GRID - 1)
	var cur := Vector2i(start_x, 0)
	path.append(cur)

	while cur.y < GRID - 1:
		var options: Array = []
		options.append(Vector2i(cur.x, cur.y + 1))
		if cur.x > 0:
			options.append(Vector2i(cur.x - 1, cur.y))
		if cur.x < GRID - 1:
			options.append(Vector2i(cur.x + 1, cur.y))
		# prefer going down, occasionally drift sideways
		var next: Vector2i
		if rng.randf() < 0.7:
			next = Vector2i(cur.x, cur.y + 1)
		else:
			var side: Array = []
			if cur.x > 0:
				side.append(Vector2i(cur.x - 1, cur.y))
			if cur.x < GRID - 1:
				side.append(Vector2i(cur.x + 1, cur.y))
			if side.is_empty():
				next = Vector2i(cur.x, cur.y + 1)
			else:
				next = side[rng.randi_range(0, side.size() - 1)]
		if next in path:
			next = Vector2i(cur.x, cur.y + 1)
		path.append(next)
		cur = next

	var doors := {}
	for y in GRID:
		for x in GRID:
			doors[Vector2i(x, y)] = {"left": false, "right": false, "up": false, "down": false}

	for i in range(path.size() - 1):
		var a: Vector2i = path[i]
		var b: Vector2i = path[i + 1]
		if b.y == a.y + 1 and b.x == a.x:
			doors[a]["down"] = true
			doors[b]["up"] = true
		elif b.y == a.y - 1 and b.x == a.x:
			doors[a]["up"] = true
			doors[b]["down"] = true
		elif b.x == a.x + 1 and b.y == a.y:
			doors[a]["right"] = true
			doors[b]["left"] = true
		elif b.x == a.x - 1 and b.y == a.y:
			doors[a]["left"] = true
			doors[b]["right"] = true

	# side rooms adjacent to path: optional left-right openings if both open
	var on_path := {}
	for p in path:
		on_path[p] = true

	var rooms := []
	for y in GRID:
		for x in GRID:
			var coord := Vector2i(x, y)
			var is_path: bool = on_path.has(coord)
			var d: Dictionary = doors[coord]
			var t := 0
			if is_path:
				if d["down"] and d["up"]:
					t = 1
				elif d["down"]:
					t = 2
				elif d["up"]:
					t = 3
				else:
					t = 1
			elif rng.randf() < 0.35:
				t = 1
				# connect horizontally only if neighbor is also non-path filler
				if x > 0 and rng.randf() < 0.5:
					d["left"] = true
				if x < GRID - 1 and rng.randf() < 0.5:
					d["right"] = true

			var enemy_count := 0
			if is_path:
				enemy_count = 2 + rng.randi_range(0, 2)
				if y >= 2:
					enemy_count += 1
			elif t != 0:
				enemy_count = 1 + rng.randi_range(0, 1)
			var enemies := []
			for i in enemy_count:
				enemies.append(_pick_enemy(rng, y))
			var torches := []
			for i in rng.randi_range(1, 3):
				torches.append(Vector2(rng.randf_range(60, ROOM_W - 60), rng.randf_range(40, ROOM_H - 80)))
			rooms.append({
				"coord": coord,
				"type": t,
				"on_path": is_path,
				"enemies": enemies,
				"torches": torches,
				"origin": Vector2(x * ROOM_W, y * ROOM_H),
				"cells": rng.randi_range(1, 3) if is_path else (1 if t != 0 else 0),
				"doors": d,
			})

	# mirror door flags so both sides agree
	for room in rooms:
		var c: Vector2i = room["coord"]
		var d: Dictionary = room["doors"]
		if d["right"] and c.x + 1 < GRID:
			_doors_at(rooms, Vector2i(c.x + 1, c.y))["left"] = true
		if d["left"] and c.x - 1 >= 0:
			_doors_at(rooms, Vector2i(c.x - 1, c.y))["right"] = true
		if d["down"] and c.y + 1 < GRID:
			_doors_at(rooms, Vector2i(c.x, c.y + 1))["up"] = true
		if d["up"] and c.y - 1 >= 0:
			_doors_at(rooms, Vector2i(c.x, c.y - 1))["down"] = true

	return {
		"seed": seed_value,
		"rooms": rooms,
		"path": path,
		"start_coord": path[0],
		"exit_coord": path[path.size() - 1],
		"room_w": ROOM_W,
		"room_h": ROOM_H,
		"grid": GRID,
	}

static func _doors_at(rooms: Array, coord: Vector2i) -> Dictionary:
	for room in rooms:
		if room["coord"] == coord:
			return room["doors"]
	return {}

static func _pick_enemy(rng: RandomNumberGenerator, row: int) -> String:
	var pool := ["zombie", "zombie", "bat"]
	if row >= 1:
		pool.append("grenadier")
	if row >= 2:
		pool.append("bomber_bat")
		pool.append("bat")
	return pool[rng.randi_range(0, pool.size() - 1)]
