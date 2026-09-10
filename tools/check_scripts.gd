extends SceneTree

func _init() -> void:
	var s = load("res://scripts/level/level_generator.gd")
	print("LG=", s)
	if s:
		var d = s.generate(12345)
		print("ROOMS=", d["rooms"].size(), " START=", d["start_coord"], " EXIT=", d["exit_coord"])
	var lg2 = load("res://scripts/level/level.gd")
	print("LEVEL_SCRIPT=", lg2)
	var p = load("res://scripts/player/player.gd")
	print("PLAYER_SCRIPT=", p)
	print("CHECK_DONE")
	quit(0)
